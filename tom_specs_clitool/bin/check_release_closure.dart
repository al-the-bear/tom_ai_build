/// Checks that the release-1 package set is dependency-closed: no member
/// reaches, directly or transitively, a workspace package outside the set
/// other than an approved published crossing — and never one of the excluded
/// packages (engine / editor / reviewer / brain / assistant / d4rt), however
/// routed. See lib/src/release_closure.dart for the rules and
/// tool/release_set.yaml for the committed set.
///
/// Exits non-zero on any violation, naming the offending edge.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/src/release_closure.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'manifest',
      help: 'Release-set manifest. Default: tool/release_set.yaml.',
    )
    ..addOption(
      'container-root',
      help: 'Workspace container root. Default: derived from this script '
          '(clitool/../../..).',
    )
    ..addFlag('verbose',
        abbr: 'v',
        help: 'List every walked package and approved crossing.',
        negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage information.',
        negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    exit(2);
  }

  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/check_release_closure.dart [options]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final clitoolRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final containerRoot = p.normalize(p.absolute(
      results.option('container-root') ??
          p.join(clitoolRoot, '..', '..', '..')));
  final manifestPath = p.normalize(p.absolute(results.option('manifest') ??
      p.join(clitoolRoot, 'tool', 'release_set.yaml')));

  final ReleaseManifest manifest;
  try {
    manifest = ReleaseManifest.load(manifestPath);
  } on FormatException catch (e) {
    stderr.writeln('check_release_closure error: ${e.message}');
    exit(2);
  }

  final report =
      checkReleaseClosure(manifest: manifest, containerRoot: containerRoot);

  if (results.flag('verbose')) {
    for (final entry in manifest.releaseSet.entries) {
      stdout.writeln('  member   ${entry.key} (${entry.value})');
    }
    for (final entry in manifest.allow.entries) {
      stdout.writeln('  approved ${entry.key} — ${entry.value.reason}');
    }
  }

  stdout.writeln(
      'Walked ${report.packagesWalked} release package(s) and '
      '${report.approvedCrossings} approved crossing(s); '
      '${report.edgesChecked} dependency edge(s) classified, '
      '${manifest.sourceOnly.length} source-only member(s) checked.');
  final byKind = <ClosureViolationKind, int>{};
  for (final v in report.violations) {
    byKind[v.kind] = (byKind[v.kind] ?? 0) + 1;
  }
  for (final kind in ClosureViolationKind.values) {
    stdout.writeln('  ${kind.name.padRight(20)} ${byKind[kind] ?? 0}');
  }

  if (!report.isClosed) {
    stderr.writeln('check_release_closure: '
        '${report.violations.length} violation(s):');
    for (final violation in report.violations) {
      stderr.writeln('  ${violation.describe()}');
    }
    exit(1);
  }

  stdout.writeln('OK — the release set is closed: every edge stays inside '
      'the set, crosses at an approved published package, or lands on '
      'third-party pub.');
}
