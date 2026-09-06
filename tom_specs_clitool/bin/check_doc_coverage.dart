import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Checks public-API dartdoc coverage against the committed manifest
/// (`tom_specs_documentation_standard.md` §5).
///
/// Exit 0 when every measured package is at or above its floor, no exempt or
/// excluded package carries a threshold, and every measured package enables
/// `public_member_api_docs`. Exit 1 otherwise, listing what to write.
///
/// `--report` measures without judging — the mode to run before seeding or
/// raising a floor. `--raise` winds each floor forward to what is measured
/// today, which is the only sanctioned way to change one: the manifest is a
/// ratchet, so a floor may rise and never fall.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'manifest',
      help:
          'Path to the manifest. Default: <clitool>/'
          '$docCoverageManifestPath.',
    )
    ..addOption(
      'root',
      help: 'Workspace container root. Default: derived from the clitool.',
    )
    ..addFlag(
      'report',
      negatable: false,
      help: 'Print measured coverage for every entry and exit 0.',
    )
    ..addFlag(
      'raise',
      negatable: false,
      help:
          'Wind every floor forward to the measured value and rewrite '
          'the manifest. Never lowers one.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final results = parser.parse(arguments);
  if (results['help'] as bool) {
    stdout.writeln('Usage: dart run bin/check_doc_coverage.dart [options]');
    stdout.writeln(parser.usage);
    return;
  }

  final clitoolRoot = _clitoolRoot();
  final containerRoot =
      (results['root'] as String?) ??
      p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  final manifestPath =
      (results['manifest'] as String?) ??
      p.join(clitoolRoot, docCoverageManifestPath);

  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('doc-coverage manifest not found: $manifestPath');
    exit(2);
  }
  final manifest = DocCoverageManifest.parse(manifestFile.readAsStringSync());

  final report = await checkDocCoverage(
    manifest: manifest,
    containerRoot: containerRoot,
  );

  if (results['raise'] as bool) {
    final raised = _raise(manifestFile, report);
    if (raised.isNotEmpty) {
      stdout.writeln('Raised: ${raised.join(', ')}');
      return;
    }
    // Distinguish the two ways nothing moved. A floor sitting ABOVE what is
    // measured is a regression the ratchet is deliberately refusing to record
    // — reporting that as "already up to date" would read as approval.
    final held = [
      for (final r in report.results)
        if (r.percent <
            (manifest.entries.firstWhere((e) => e.path == r.path).floor))
          '${r.path} measures ${r.percent}%, floor stays at '
              '${manifest.entries.firstWhere((e) => e.path == r.path).floor}%',
    ];
    if (held.isEmpty) {
      stdout.writeln(
        'No floor moved — every entry already records what it '
        'measures.',
      );
    } else {
      stdout.writeln('No floor moved. Held (the ratchet does not go down):');
      for (final h in held) {
        stdout.writeln('  $h');
      }
      exitCode = 1;
    }
    return;
  }

  for (final r in report.results) {
    stdout.writeln(
      '  ${r.percent.toString().padLeft(3)}%  '
      '${r.documented}/${r.total}  ${r.path}',
    );
  }

  if (results['report'] as bool) return;

  final slack = report.ratchetAvailable;
  if (slack.isNotEmpty) {
    stdout.writeln('\nRatchet available (run with --raise to record):');
    for (final r in slack) {
      stdout.writeln('  ${r.path} measures ${r.percent}%');
    }
  }

  if (report.isClean) {
    stdout.writeln('\nOK — every package is at or above its floor.');
    return;
  }
  stderr.writeln('\n${report.violations.length} violation(s):');
  for (final v in report.violations) {
    stderr.writeln('  $v');
  }
  exit(1);
}

/// Rewrites each `floor:` to the measured value, upward only.
///
/// Line-oriented rather than a YAML round-trip so the header — which carries
/// the rules the numbers mean nothing without — survives byte-for-byte.
List<String> _raise(File file, DocCoverageReport report) {
  final measured = {for (final r in report.results) r.path: r.percent};
  final lines = file.readAsLinesSync();
  final raised = <String>[];
  String? current;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final pkg = RegExp(r'^  ([A-Za-z0-9_/]+):\s*$').firstMatch(line);
    if (pkg != null) {
      current = pkg.group(1);
      continue;
    }
    final floor = RegExp(r'^(\s*floor:\s*)(\d+)(.*)$').firstMatch(line);
    if (floor == null || current == null) continue;
    final now = measured[current];
    final was = int.parse(floor.group(2)!);
    if (now == null || now <= was) continue;
    lines[i] = '${floor.group(1)}$now${floor.group(3)}';
    raised.add('$current $was% -> $now%');
  }
  if (raised.isNotEmpty) file.writeAsStringSync('${lines.join('\n')}\n');
  return raised;
}

/// The `tom_specs_clitool` root, from this script's own location.
String _clitoolRoot() {
  var dir = p.dirname(p.fromUri(Platform.script));
  while (dir != p.dirname(dir)) {
    if (File(p.join(dir, 'pubspec.yaml')).existsSync()) return dir;
    dir = p.dirname(dir);
  }
  return Directory.current.path;
}
