/// Reports every governed Dart file `dart format` would rewrite, and exits
/// non-zero when there is one.
///
/// The gate over `tool/format_set.yaml`. `test/format_test.dart` runs the same
/// check in the default `dart test` run; this is the command a person runs to
/// see the list.
///
/// It reports and never repairs: `dart format <path>` is the repair, and a gate
/// that rewrote files would edit someone's branch at a moment they did not
/// choose.
///
/// Exit codes: `0` clean, `1` something is unformatted or a manifest package is
/// missing, `2` the check could not run.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'manifest',
      help:
          'Path to the format set. Default: tool/format_set.yaml beside '
          'this package.',
    )
    ..addOption(
      'container-root',
      help:
          'Workspace container root. Default: three levels above this '
          'package.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stderr.writeln(parser.usage);
    exit(2);
  }
  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/check_format.dart [options]\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final packageRoot = p.normalize(Directory.current.path);
  final containerRoot = p.normalize(
    results.option('container-root') ?? p.join(packageRoot, '..', '..', '..'),
  );
  final manifestPath =
      results.option('manifest') ??
      p.join(packageRoot, 'tool', 'format_set.yaml');

  if (!File(manifestPath).existsSync()) {
    stderr.writeln('check_format: manifest not found: $manifestPath');
    exit(2);
  }

  final report = checkFormatting(
    containerRoot: containerRoot,
    set: FormatSet.load(manifestPath),
  );

  for (final path in report.unformatted) {
    stdout.writeln('  $path');
  }
  for (final package in report.missingPackages) {
    stdout.writeln('  MISSING PACKAGE  $package');
  }
  stdout.writeln(report.summary);

  if (report.unavailable != null) exit(2);
  if (!report.isClean) {
    stdout.writeln('Repair with: dart format <path>  (or the package root)');
    exit(1);
  }
}
