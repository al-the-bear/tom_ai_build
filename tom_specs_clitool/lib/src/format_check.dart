/// The formatting gate: is every governed package's Dart what `dart format`
/// would write?
///
/// ## Why this exists
///
/// Dart 3.7 replaced the formatter's short style with the tall one. The
/// checked-in source was short-style, the toolchain became tall-style, and
/// **seven of the ten quest packages stopped conforming** — about 242 files —
/// without anything going red. The cost was not cosmetic. `dart format` was
/// unusable as a gate, so nothing caught genuinely mis-formatted new code; and
/// any file touched for another reason invited an incidental reformat that
/// buried the real change in the diff. Several commits in this quest carry a
/// line saying so, because leaving the files alone was the only way to keep a
/// change reviewable.
///
/// ## Which formatter
///
/// The check runs the `dart_style` linked into this package ([DartFormat]), in
/// each file's package language version as `dart format` takes it — never
/// `dart format` as a process, so the `tomspecs` binary needs no Dart SDK to
/// run it. The formatter is pinned to exactly the version of the workspace
/// SDK's own (`test/dart_style_pin_test.dart` fails when the SDK moves past
/// it): a gate asserting a different style from the command developers run
/// would be worse than no gate, failing work that is correct and passing work
/// that is not, and the pin is what keeps the two the same.
///
/// ## What it does not do
///
/// It does not format. A gate that repaired what it found would make the diff
/// it exists to protect — and would do it on someone else's branch, at a moment
/// they did not choose. `dart format` is the repair; this only reports.
///
/// ## Why it enumerates files rather than walking whole directories
///
/// One file in the governed set must be excluded: `tom_spec_engine/lib/src/bridges/som_v0_bridges.b.dart` is
/// **973,181 lines** of generated D4rt bridge, and formatting it takes five
/// minutes — against four seconds for every other governed package combined. A
/// gate that cost five minutes would not survive in the default test run, and a
/// generated file nobody reads is the wrong thing to spend it on. So the check
/// lists the files itself and drops the excluded ones before formatting the
/// rest.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'dart_format.dart';
import 'package_resolution.dart';

/// The manifest of packages the formatter governs, and the source directories
/// checked inside each.
class FormatSet {
  /// Package directories, container-root-relative.
  final List<String> packages;

  /// Source directory names checked inside each package.
  ///
  /// A package that lacks one is not an error: `tom_specs_core` has no `bin/`,
  /// and a manifest that demanded one would describe a shape rather than a
  /// rule.
  final List<String> directories;

  /// Creates a manifest.
  const FormatSet({
    required this.packages,
    required this.directories,
    this.excludeSuffixes = const [],
  });

  /// Reads `tool/format_set.yaml`.
  factory FormatSet.load(String path) {
    final doc = loadYaml(File(path).readAsStringSync()) as YamlMap;
    final exclude = doc['exclude-suffixes'] as YamlList?;
    return FormatSet(
      packages: [for (final e in doc['packages'] as YamlList) e as String],
      directories: [
        for (final e in doc['directories'] as YamlList) e as String,
      ],
      excludeSuffixes: [for (final e in exclude ?? const []) e as String],
    );
  }

  /// File-name suffixes the gate does not govern.
  ///
  /// Generated output whose emitter is not obliged to format. Kept as suffixes
  /// rather than paths so a second bridge file is excluded the day it is
  /// generated, not the day someone lists it.
  final List<String> excludeSuffixes;

  /// Every governed `.dart` file that exists on disk, absolute, sorted.
  ///
  /// [missingPackages] collects manifest entries with no directory at all —
  /// a moved or renamed package, which would otherwise shrink the gate's
  /// subject in silence.
  ///
  /// [unresolvedPackages] collects packages that exist but were never resolved
  /// (no `.dart_tool/package_config.json` in the package or above it): without
  /// one, `dart format` formats at the newest language version rather than the
  /// package's, and reports files as unformatted that are not. Their files are
  /// left out, and the package is named instead.
  List<String> resolveFiles(
    String containerRoot, {
    List<String>? missingPackages,
    List<String>? unresolvedPackages,
  }) {
    final out = <String>[];
    for (final package in packages) {
      final root = p.join(containerRoot, package);
      if (!Directory(root).existsSync()) {
        missingPackages?.add(package);
        continue;
      }
      if (unresolvedPackages != null &&
          !isResolvedPackage(root, containerRoot)) {
        unresolvedPackages.add(package);
        continue;
      }
      for (final dir in directories) {
        final source = Directory(p.join(root, dir));
        if (!source.existsSync()) continue;
        for (final entity in source.listSync(recursive: true)) {
          if (entity is! File) continue;
          final path = entity.path;
          if (p.extension(path) != '.dart') continue;
          if (p.split(p.relative(path, from: root)).contains('.dart_tool')) {
            continue;
          }
          if (excludeSuffixes.any(path.endsWith)) continue;
          out.add(path);
        }
      }
    }
    out.sort();
    return out;
  }
}

/// What the formatter would change, and what got in the way of asking.
class FormatReport {
  /// Files `dart format` would rewrite, container-root-relative, sorted.
  final List<String> unformatted;

  /// Manifest packages that are not on disk.
  final List<String> missingPackages;

  /// Manifest packages on disk but never resolved (`dart pub get` not run),
  /// whose files were not checked.
  final List<String> unresolvedPackages;

  /// Why the check could not run at all, or `null` when it did.
  ///
  /// Separate from an empty [unformatted] on purpose: "the formatter found
  /// nothing" and "the formatter never ran" are the same value and opposite
  /// facts, and conflating them is how a gate reports a pass it never earned.
  final String? unavailable;

  /// Creates a report.
  const FormatReport({
    required this.unformatted,
    this.missingPackages = const [],
    this.unresolvedPackages = const [],
    this.unavailable,
  });

  /// Whether every governed file is already formatted.
  bool get isClean =>
      unavailable == null &&
      unformatted.isEmpty &&
      missingPackages.isEmpty &&
      unresolvedPackages.isEmpty;

  /// A one-line summary for a CLI.
  String get summary {
    if (unavailable != null) return 'formatting: NOT CHECKED — $unavailable';
    if (isClean) return 'formatting: clean';
    final parts = <String>[
      if (unformatted.isNotEmpty) '${unformatted.length} unformatted file(s)',
      if (missingPackages.isNotEmpty)
        '${missingPackages.length} manifest package(s) missing',
      if (unresolvedPackages.isNotEmpty)
        '${unresolvedPackages.length} package(s) not resolved '
            '(run `dart pub get` there)',
    ];
    return 'formatting: ${parts.join(', ')}';
  }
}

/// Checks every governed file of [set] under [containerRoot] against the
/// formatter ([DartFormat]): a file whose text the formatter would change is
/// reported; nothing is written.
FormatReport checkFormatting({
  required String containerRoot,
  required FormatSet set,
}) {
  final missing = <String>[];
  final unresolved = <String>[];
  final files = set.resolveFiles(
    containerRoot,
    missingPackages: missing,
    unresolvedPackages: unresolved,
  );
  if (files.isEmpty) {
    return FormatReport(
      unformatted: const [],
      missingPackages: missing,
      unresolvedPackages: unresolved,
      unavailable: unresolved.isEmpty
          ? 'no manifest package has a governed Dart file on disk'
          : 'no resolved package to check — ${unresolved.length} package(s) '
                'not resolved (run `dart pub get` there): '
                '${unresolved.join(', ')}',
    );
  }

  final format = DartFormat();
  final unformatted = <String>[];
  for (final path in files) {
    try {
      if (format.isFormatted(path)) continue;
    } on DartFormatFailure catch (e) {
      // A file that does not parse is the formatter failing. Reporting that
      // as "clean" would hide a broken file behind a green gate.
      return FormatReport(
        unformatted: const [],
        missingPackages: missing,
        unresolvedPackages: unresolved,
        unavailable: '$e',
      );
    }
    unformatted.add(
      p.relative(p.absolute(path), from: containerRoot).replaceAll(r'\', '/'),
    );
  }
  unformatted.sort();

  return FormatReport(
    unformatted: unformatted,
    missingPackages: missing,
    unresolvedPackages: unresolved,
  );
}
