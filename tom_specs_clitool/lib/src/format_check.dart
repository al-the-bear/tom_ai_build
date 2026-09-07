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
/// ## Why it shells out
///
/// The check runs the **installed `dart format`**, not `package:dart_style`
/// linked in. A pinned formatter package and the SDK's binary drift apart at
/// every SDK bump, and a gate that asserts a different style from the command
/// developers actually run is worse than no gate: it fails work that is
/// correct, and passes work that is not. One process for the whole manifest
/// keeps it to a single parse pass.
///
/// ## What it does not do
///
/// It does not format. A gate that repaired what it found would make the diff
/// it exists to protect — and would do it on someone else's branch, at a moment
/// they did not choose. `dart format` is the repair; this only reports.
///
/// ## Why it enumerates files rather than handing over directories
///
/// `dart format` has no exclude option, and one file in the governed set must
/// be excluded: `tom_spec_engine/lib/src/bridges/som_v0_bridges.b.dart` is
/// **973,181 lines** of generated D4rt bridge, and formatting it takes five
/// minutes — against four seconds for every other governed package combined. A
/// gate that cost five minutes would not survive in the default test run, and a
/// generated file nobody reads is the wrong thing to spend it on. So the check
/// lists the files itself and drops the excluded ones before handing the rest
/// over.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

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
  List<String> resolveFiles(
    String containerRoot, {
    List<String>? missingPackages,
  }) {
    final out = <String>[];
    for (final package in packages) {
      final root = p.join(containerRoot, package);
      if (!Directory(root).existsSync()) {
        missingPackages?.add(package);
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
    this.unavailable,
  });

  /// Whether every governed file is already formatted.
  bool get isClean =>
      unavailable == null && unformatted.isEmpty && missingPackages.isEmpty;

  /// A one-line summary for a CLI.
  String get summary {
    if (unavailable != null) return 'formatting: NOT CHECKED — $unavailable';
    if (isClean) return 'formatting: clean';
    final parts = <String>[
      if (unformatted.isNotEmpty) '${unformatted.length} unformatted file(s)',
      if (missingPackages.isNotEmpty)
        '${missingPackages.length} manifest package(s) missing',
    ];
    return 'formatting: ${parts.join(', ')}';
  }
}

/// Runs `dart format --output=none --set-exit-if-changed` over [set]'s
/// directories under [containerRoot].
///
/// One invocation for the whole manifest: the formatter's cost is dominated by
/// parsing, and ten processes would pay the VM's startup ten times to learn the
/// same thing.
FormatReport checkFormatting({
  required String containerRoot,
  required FormatSet set,
}) {
  final missing = <String>[];
  final files = set.resolveFiles(containerRoot, missingPackages: missing);
  if (files.isEmpty) {
    return FormatReport(
      unformatted: const [],
      missingPackages: missing,
      unavailable: 'no manifest package has a governed Dart file on disk',
    );
  }

  final ProcessResult result;
  try {
    result = Process.runSync(
      'dart',
      ['format', '--output=none', '--set-exit-if-changed', ...files],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  } on ProcessException catch (e) {
    return FormatReport(
      unformatted: const [],
      missingPackages: missing,
      unavailable: 'could not run `dart format` ($e)',
    );
  }

  // Exit 0 clean, 1 "would change", anything else is the formatter failing —
  // a parse error in a source file, say. Reporting that as "clean" would hide
  // a broken file behind a green gate.
  if (result.exitCode > 1) {
    return FormatReport(
      unformatted: const [],
      missingPackages: missing,
      unavailable:
          '`dart format` exited ${result.exitCode}: '
          '${(result.stderr as String).trim()}',
    );
  }

  final unformatted = <String>[];
  for (final line in (result.stdout as String).split('\n')) {
    if (!line.startsWith('Changed ')) continue;
    final path = line.substring('Changed '.length).trim();
    unformatted.add(
      p.relative(p.absolute(path), from: containerRoot).replaceAll(r'\', '/'),
    );
  }
  unformatted.sort();

  return FormatReport(unformatted: unformatted, missingPackages: missing);
}
