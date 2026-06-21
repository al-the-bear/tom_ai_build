import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Raised when a package directory has no resolved
/// `.dart_tool/package_config.json` (i.e. `pub get` has not been run there).
class SummaryConfigException implements Exception {
  SummaryConfigException(this.message);

  final String message;

  @override
  String toString() => 'SummaryConfigException: $message';
}

/// Reads a resolved `.dart_tool/package_config.json` and returns a map of
/// package-name → absolute package **root** directory (the directory that
/// contains `lib/`).
///
/// `rootUri`s in the config may be relative to the config file's own location,
/// so they are resolved against [packageConfigFile]'s URI and normalised to a
/// platform path. Used by the B1 summary generator (`bin/summaries.dart`) to
/// discover every package whose libraries must go into `packages.sum`.
Map<String, String> readPackageRoots(File packageConfigFile) {
  final config =
      jsonDecode(packageConfigFile.readAsStringSync()) as Map<String, dynamic>;
  final packageList = config['packages'] as List<dynamic>;
  final roots = <String, String>{};
  for (final pkg in packageList) {
    final pkgMap = pkg as Map<String, dynamic>;
    final name = pkgMap['name'] as String;
    final rootUri = pkgMap['rootUri'] as String;
    final resolved = Uri.parse(packageConfigFile.uri.toString())
        .resolve(rootUri.endsWith('/') ? rootUri : '$rootUri/');
    roots[name] = p.normalize(resolved.toFilePath());
  }
  return roots;
}

/// Merges the package roots resolved from each given package directory's
/// `.dart_tool/package_config.json` into a single name→root map.
///
/// This is what lets one `packages.sum` bundle cover the **union** of several
/// dependency closures — e.g. the editor's deps *and* `tom_flutter_ui` (whose
/// widgets the CodeSpecs phase's Dart-code fields reference) without the editor
/// having to depend on `tom_flutter_ui` directly (the bundle is loaded at
/// runtime, never compiled against). On a name collision the later directory
/// wins; within one workspace these are path deps resolving to the same root,
/// so collisions are benign.
///
/// Throws [SummaryConfigException] if any directory lacks a resolved config.
Map<String, String> mergePackageRootsForDirs(Iterable<String> packageDirs) {
  final merged = <String, String>{};
  for (final dir in packageDirs) {
    final configFile =
        File(p.join(dir, '.dart_tool', 'package_config.json'));
    if (!configFile.existsSync()) {
      throw SummaryConfigException(
          '${configFile.path} not found — run `flutter pub get` / '
          '`dart pub get` in $dir first.');
    }
    merged.addAll(readPackageRoots(configFile));
  }
  return merged;
}
