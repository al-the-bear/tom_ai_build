/// Where this package's files are, for the tools that read its committed
/// files (manifests, the sibling packages of `tom_ai/ai_build`).
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// The root folder of `tom_specs_clitool`, found in this order:
///
/// 1. through the package config (`package:tom_specs_clitool/` is its
///    `lib/`): right under `dart run`, `dart test` and the `tomspecs` binary
///    run with a package config;
/// 2. a compiled binary has no package config, so from the current directory:
///    the nearest folder at or above it whose `pubspec.yaml` names
///    `tom_specs_clitool`, or that holds `tom_ai/ai_build/tom_specs_clitool`
///    (the workspace container or any folder below `tom_ai/ai_build`);
/// 3. else the folder above the script's folder (`bin/..`), as the tools
///    have always taken it.
String clitoolPackageRoot() {
  final lib = Isolate.resolvePackageUriSync(
    Uri.parse('package:tom_specs_clitool/'),
  );
  if (lib != null && lib.scheme == 'file') {
    return p.normalize(p.dirname(p.fromUri(lib)));
  }
  final fromCwd = clitoolRootAbove(Directory.current.path);
  if (fromCwd != null) return fromCwd;
  return p.normalize(p.dirname(p.dirname(p.fromUri(Platform.script))));
}

/// The `tom_specs_clitool` root found from [start] upwards (step 2 of
/// [clitoolPackageRoot]), or null when none is.
String? clitoolRootAbove(String start) {
  for (var dir = p.normalize(p.absolute(start)); ; dir = p.dirname(dir)) {
    if (_isClitool(dir)) return dir;
    for (final below in [
      p.join(dir, 'tom_specs_clitool'),
      p.join(dir, 'tom_ai', 'ai_build', 'tom_specs_clitool'),
    ]) {
      if (_isClitool(below)) return below;
    }
    if (p.dirname(dir) == dir) return null;
  }
}

bool _isClitool(String dir) {
  final pubspec = File(p.join(dir, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return false;
  return RegExp(
    r'^name:\s*tom_specs_clitool\s*$',
    multiLine: true,
  ).hasMatch(pubspec.readAsStringSync());
}
