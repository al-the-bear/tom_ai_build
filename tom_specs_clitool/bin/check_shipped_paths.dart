/// Reports every path literal in a shipped script that resolves nowhere inside
/// its own package, and exits non-zero when there is one.
///
/// The gate over `lib/src/shipped_script_paths.dart`, which explains the defect
/// and why both resolution bases are checked.
/// `test/shipped_script_paths_test.dart` runs the same scan over the real
/// packages in the default `dart test` run; this is the command a person runs
/// to see the list.
///
/// Exit codes: `0` every literal resolves, `1` at least one does not, `2` the
/// check could not run.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The publishable Dart packages of the quest, relative to the container root.
///
/// Enumerated rather than discovered: the membership rule is "publishes to
/// pub.dev", which is a property of a pubspec rather than of a directory, and
/// a list that is wrong is visible in a way a silent walk is not.
const List<String> defaultPackages = [
  'tom_ai/ai_build/tom_som_dart_v0',
  'tom_ai/ai_build/tom_som_dart_runtime',
  'tom_ai/ai_build/tom_specs_core',
  'tom_ai/ai_build/tom_specs_model',
  'tom_ai/ai_build/tom_specs_clitool',
  'tom_ai/ai_build/tom_code_specs',
  'tom_ai/ai_build/tom_doc_scanner',
  'tom_ai/ai_build/tom_doc_specs',
  'tom_ai/core/tom_core_codespecs',
];

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addMultiOption(
      'package',
      help:
          'Package root to scan, relative to the container root. Repeatable. '
          'Defaults to the publishable set.',
    )
    ..addOption(
      'container-root',
      help:
          'Workspace container root. Default: three levels above this package.',
    )
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'List every scan.')
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
    stdout.writeln('Usage: dart run bin/check_shipped_paths.dart [options]\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final packageRoot = p.normalize(Directory.current.path);
  final containerRoot = p.normalize(
    results.option('container-root') ?? p.join(packageRoot, '..', '..', '..'),
  );
  final packages = results.multiOption('package').isEmpty
      ? defaultPackages
      : results.multiOption('package');

  final findings = <String, List<EscapingPath>>{};
  var scanned = 0;
  for (final rel in packages) {
    final dir = Directory(p.join(containerRoot, rel));
    if (!dir.existsSync()) {
      stderr.writeln('check_shipped_paths: package not found: ${dir.path}');
      exit(2);
    }
    scanned++;
    final escaping = findEscapingPaths(dir);
    if (escaping.isNotEmpty) findings[rel] = escaping;
    if (results.flag('verbose')) {
      stdout.writeln('  $rel: ${escaping.length} finding(s)');
    }
  }

  if (findings.isEmpty) {
    stdout.writeln(
      'check_shipped_paths: $scanned package(s), every path literal in a '
      'shipped script resolves inside its package',
    );
    exit(0);
  }

  final total = findings.values.fold<int>(0, (a, b) => a + b.length);
  stderr.writeln(
    'check_shipped_paths: $total path literal(s) in shipped scripts resolve '
    'nowhere inside their package',
  );
  for (final entry in findings.entries) {
    stderr.writeln('  ${entry.key}');
    for (final f in entry.value) {
      stderr.writeln('    ${f.describe()}');
    }
  }
  stderr.writeln(
    '\nA shipped script is what a consumer runs first. From a hosted install\n'
    'these paths name files that are not there, and nothing says so until the\n'
    'script is run. Either ship the data the script needs inside the package,\n'
    'or take the script out of the archive with a `.pubignore` entry if it is\n'
    'a workspace tool rather than a consumer one.',
  );
  exit(1);
}
