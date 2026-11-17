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

/// Runs `check_format` with [arguments] and returns its exit code, without ending
/// the process (the `tomspecs` command calls it).
Future<int> runCheckFormat(List<String> arguments) async {
  _exitCode = 0;
  try {
    _mainCheckFormat(arguments);
  } on ToolExit catch (e) {
    return e.code;
  }
  return _exitCode;
}

int _exitCode = 0;

Future<void> main(List<String> arguments) async =>
    exit(await runCheckFormat(arguments));

/// The options of `check_format` (also the `tomspecs` command's).
ArgParser checkFormatParser() => ArgParser()
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

void _mainCheckFormat(List<String> arguments) {
  final parser = checkFormatParser();

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stderr.writeln(parser.usage);
    throw ToolExit(2);
  }
  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/check_format.dart [options]\n');
    stdout.writeln(parser.usage);
    throw ToolExit(0);
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
    throw ToolExit(2);
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
  for (final package in report.unresolvedPackages) {
    stdout.writeln('  NOT RESOLVED     $package  (run `dart pub get` there)');
  }
  stdout.writeln(report.summary);

  if (report.unavailable != null) throw ToolExit(2);
  if (!report.isClean) {
    stdout.writeln('Repair with: dart format <path>  (or the package root)');
    throw ToolExit(1);
  }
}
