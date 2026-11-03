/// The documentation-build gate: does `dart doc` build each governed package
/// without a word, and does every link in its doc-comment prose land in a
/// package the writer chose?
///
/// ## Why this exists
///
/// A dartdoc reference that does not resolve renders as literal brackets.
/// There is no error at the writing end and nothing looks wrong at the reading
/// end: the reader sees `[SomeType]` as text, follows nothing, and has no way
/// to know a link was intended. The only thing in the toolchain that says so
/// is `dart doc` itself, and left unrun the count drifts — each one a single
/// bracketed word inside a comment that reads perfectly.
///
/// **Every warning counts**, not only unresolved references: a build that is
/// allowed to say one thing is a build nobody reads.
///
/// ## A silent build is necessary, not sufficient
///
/// `dart doc` resolves a reference by walking outward until something answers,
/// and an answer is not a warning: a `[hash]` meant for a record field once
/// bound to a transitive dependency's deprecated `hash` library and rendered a
/// live link with zero warnings. So the rendered prose is read before the HTML
/// is deleted ([strayDoclinks]): a link in doc-comment text — not in a
/// signature, which states the code's own claim — into a package that is
/// neither the writing package, the SDK, a direct dependency nor re-exported by
/// one ([allowedDoclinkPackages]) is a fault. A package whose pages render no
/// doc prose at all is refused as not measured rather than passed.
///
/// The design is `tom_ai/core`'s `tool/check_dartdoc_build.py` and
/// `tool/dartdoc_links.py`, carried here so that each repository holds its own
/// checks.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Where the manifest of governed packages lives, clitool-relative.
const String dartdocBuildSetPath = 'tool/dartdoc_build_set.yaml';

/// The packages whose documentation build must be silent,
/// container-root-relative.
class DartdocBuildSet {
  /// The package paths, in manifest order.
  final List<String> packages;

  /// A set of [packages].
  const DartdocBuildSet(this.packages);

  /// Reads the manifest's `packages:` list.
  factory DartdocBuildSet.parse(String yaml) {
    final doc = loadYaml(yaml) as YamlMap;
    return DartdocBuildSet([
      for (final item in doc['packages'] as YamlList) item as String,
    ]);
  }
}

/// What one package's documentation build said.
class DartdocBuildReport {
  /// The package directory, as given.
  final String package;

  /// `dart doc`'s exit status.
  final int exitCode;

  /// Each warning as the log renders it: the message and, when the log gives
  /// one, the location.
  final List<String> warnings;

  /// Warnings by `dart doc`'s own verdict line — counted from the verdict
  /// rather than from [warnings], so a warning shape the parser does not read
  /// is still counted.
  final int warningCount;

  /// Errors by `dart doc`'s verdict line.
  final int errorCount;

  /// Doc-prose links into packages the writer did not choose.
  final List<String> strayLinks;

  /// Doc-prose blocks read from the rendered pages; zero means the link scan
  /// judged nothing.
  final int proseBlocks;

  /// The full `dart doc` output.
  final String log;

  /// A report of one build.
  const DartdocBuildReport({
    required this.package,
    required this.exitCode,
    required this.warnings,
    required this.warningCount,
    required this.errorCount,
    required this.strayLinks,
    required this.proseBlocks,
    required this.log,
  });

  /// Faults: every warning, error and stray link.
  int get faults => warningCount + errorCount + strayLinks.length;

  /// Whether the build failed without saying why in a verdict line.
  bool get failedSilently =>
      exitCode != 0 && warningCount == 0 && errorCount == 0;
}

final _warning = RegExp(r'^\s*warning:\s*(.+)$');
final _location = RegExp(r'^\s+from\s+(.+?):\s*\(file://(.+?)\)\s*$');
final _verdict = RegExp(r'^Found (\d+) warnings? and (\d+) errors?\.');

/// Builds the documentation of the package at [packageDir] into a directory
/// under [scratchDir], reads it, deletes it, and reports.
Future<DartdocBuildReport> buildDartdoc({
  required String packageDir,
  required String scratchDir,
}) async {
  final package = p.normalize(p.absolute(packageDir));
  final output = Directory(p.join(scratchDir, p.basename(package)));
  if (output.existsSync()) output.deleteSync(recursive: true);
  output.createSync(recursive: true);
  try {
    final done = await Process.run('dart', [
      'doc',
      '--output',
      output.path,
    ], workingDirectory: package);
    final log = '${done.stdout}${done.stderr}';
    final lines = const LineSplitter().convert(log);
    final warnings = <String>[];
    var warningCount = 0;
    var errorCount = 0;
    for (var i = 0; i < lines.length; i++) {
      final verdict = _verdict.firstMatch(lines[i]);
      if (verdict != null) {
        warningCount += int.parse(verdict.group(1)!);
        errorCount += int.parse(verdict.group(2)!);
      }
      final warning = _warning.firstMatch(lines[i]);
      if (warning == null) continue;
      final place = i + 1 < lines.length
          ? _location.firstMatch(lines[i + 1])
          : null;
      final where = place == null
          ? ''
          : '  ${p.relative(place.group(2)!, from: package)}  '
                '(${place.group(1)})';
      warnings.add('${warning.group(1)}$where');
    }
    final scan = strayDoclinks(output.path, allowedDoclinkPackages(package));
    return DartdocBuildReport(
      package: packageDir,
      exitCode: done.exitCode,
      warnings: warnings,
      warningCount: warningCount,
      errorCount: errorCount,
      strayLinks: scan.stray,
      proseBlocks: scan.blocks,
      log: log,
    );
  } finally {
    if (output.existsSync()) output.deleteSync(recursive: true);
  }
}

/// A link into a hosted package's API pages.
final _packageLink = RegExp(
  r'<a\b[^>]*href="https://pub\.dev/documentation/([A-Za-z0-9_]+)/[^"]*"'
  r'[^>]*>(.*?)</a>',
  dotAll: true,
);

/// The two places dartdoc renders doc-comment prose.
final _proseBlock = RegExp(
  r'<section class="desc markdown">(.*?)</section>|<dd\b[^>]*>(.*?)</dd>',
  dotAll: true,
);

/// `export 'package:<name>/...'`: the re-export a dependency makes on its
/// consumers' behalf.
final _export = RegExp(
  r'''^\s*export\s+['"]package:([A-Za-z0-9_]+)/''',
  multiLine: true,
);

final _tag = RegExp(r'<[^>]+>');

/// The packages a doc comment of the package at [packageDir] may link into:
/// the package itself, its direct dependencies, and — transitively — every
/// package one of those re-exports from its `lib/`, because a reader of the
/// barrel can name those types without importing anything else.
Set<String> allowedDoclinkPackages(String packageDir) {
  final roots = _packageRoots(packageDir);
  final allowed = <String>{p.basename(packageDir)};
  final pending = _directDependencies(packageDir).toList()..sort();
  while (pending.isNotEmpty) {
    final name = pending.removeLast();
    if (!allowed.add(name)) continue;
    final root = roots[name];
    final lib = root == null ? null : Directory(p.join(root, 'lib'));
    if (lib == null || !lib.existsSync()) continue;
    for (final source in lib.listSync(recursive: true).whereType<File>()) {
      if (!source.path.endsWith('.dart')) continue;
      final String text;
      try {
        text = source.readAsStringSync();
      } on FileSystemException {
        continue;
      }
      for (final m in _export.allMatches(text)) {
        if (!allowed.contains(m.group(1))) pending.add(m.group(1)!);
      }
    }
  }
  return allowed;
}

/// `(stray, blocks, links)` over the rendered pages under [outputDir]: each
/// doc-prose link outside [allowed] as `<page>: [text] -> <package>`, once per
/// (page, text, package); and the prose blocks and package links read, so a
/// caller can refuse a vacuous pass.
({List<String> stray, int blocks, int links}) strayDoclinks(
  String outputDir,
  Set<String> allowed,
) {
  var blocks = 0;
  var links = 0;
  final found = <String>{};
  final pages =
      Directory(outputDir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.html'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final page in pages) {
    final html = page.readAsStringSync();
    for (final block in _proseBlock.allMatches(html)) {
      blocks++;
      final prose = block.group(1) ?? block.group(2) ?? '';
      for (final link in _packageLink.allMatches(prose)) {
        links++;
        final target = link.group(1)!;
        if (allowed.contains(target)) continue;
        final text = link.group(2)!.replaceAll(_tag, '').trim();
        found.add(
          '${p.relative(page.path, from: outputDir)}: [$text] -> $target',
        );
      }
    }
  }
  return (stray: found.toList()..sort(), blocks: blocks, links: links);
}

Map<String, String> _packageRoots(String packageDir) {
  final config = File(p.join(packageDir, '.dart_tool', 'package_config.json'));
  final roots = <String, String>{};
  if (!config.existsSync()) return roots;
  final data = jsonDecode(config.readAsStringSync()) as Map<String, Object?>;
  for (final entry in data['packages']! as List<Object?>) {
    final map = entry! as Map<String, Object?>;
    final uri = Uri.parse(map['rootUri']! as String);
    roots[map['name']! as String] = uri.hasScheme
        ? p.fromUri(uri)
        : p.normalize(p.join(config.parent.path, p.fromUri(uri)));
  }
  return roots;
}

Set<String> _directDependencies(String packageDir) {
  final pubspec =
      loadYaml(File(p.join(packageDir, 'pubspec.yaml')).readAsStringSync())
          as YamlMap;
  final deps = pubspec['dependencies'];
  return deps is YamlMap ? {for (final k in deps.keys) k as String} : {};
}
