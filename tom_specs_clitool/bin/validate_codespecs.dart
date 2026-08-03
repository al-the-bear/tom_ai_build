/// Runs the `codespecs_derivation_contract.md` §6 checks over a generated
/// CodeSpecs project trio and exits non-zero on any violation.
///
/// Exit codes: `0` clean, `1` at least one violation, `2` bad usage.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'shared',
      help: 'Path to the generated <app>_codespec_shared package.',
      mandatory: true,
    )
    ..addOption(
      'client',
      help: 'Path to the generated <app>_codespec_client package.',
      mandatory: true,
    )
    ..addOption(
      'server',
      help: 'Path to the generated <app>_codespec_server package.',
      mandatory: true,
    )
    ..addOption(
      'migrations',
      help: 'Directory of CE-MG migration artifacts (*.sql), for check 13. '
          'Omitted: the check has nothing to converge and passes.',
    )
    ..addOption(
      'cs-vocabulary',
      help: "Path to tom_code_specs' vocabulary source (file or directory), "
          'for the mirrored-catalogue check.',
    )
    ..addOption(
      'core-source',
      help: 'Path to the tom_core source (file or directory) holding the '
          'mirrored counterparts, for the mirrored-catalogue check.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information.',
      negatable: false,
    );

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln();
    _printUsage(parser);
    exit(2);
  }

  if (results.flag('help')) {
    _printUsage(parser);
    exit(0);
  }

  final input = CodeSpecsValidationInput(
    shared: _project(CsLocus.shared, results.option('shared')!),
    client: _project(CsLocus.client, results.option('client')!),
    server: _project(CsLocus.server, results.option('server')!),
    migrations: _migrations(results.option('migrations')),
    enumMirrors: readCsEnumMirrors(
      csSources: _dartSources(results.option('cs-vocabulary')),
      coreSources: _dartSources(results.option('core-source')),
    ),
  );

  final report = runCodeSpecsChecks(input);
  for (final line in report.lines) {
    stderr.writeln(line);
  }
  stdout.writeln(report.summary);
  exit(report.passed ? 0 : 1);
}

CsLocusProject _project(CsLocus locus, String path) {
  final root = p.normalize(p.absolute(path));
  if (!Directory(root).existsSync()) {
    stderr.writeln('Error: ${locus.label} package not found: $root');
    exit(2);
  }
  return readCsLocusProjectFromDirectory(
    locus: locus,
    packageName: p.basename(root),
    root: root,
  );
}

Map<String, String> _migrations(String? path) {
  if (path == null) return const {};
  final dir = Directory(p.normalize(p.absolute(path)));
  if (!dir.existsSync()) {
    stderr.writeln('Error: migrations directory not found: ${dir.path}');
    exit(2);
  }
  final out = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.toLowerCase().endsWith('.sql')) {
      out[p.relative(entity.path, from: dir.path)] = entity.readAsStringSync();
    }
  }
  return out;
}

/// Every Dart source under [path] — one file, or a tree.
List<String> _dartSources(String? path) {
  if (path == null) return const [];
  final resolved = p.normalize(p.absolute(path));
  final file = File(resolved);
  if (file.existsSync()) return [file.readAsStringSync()];
  final dir = Directory(resolved);
  if (!dir.existsSync()) {
    stderr.writeln('Error: source path not found: $resolved');
    exit(2);
  }
  return [
    for (final entity in dir.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.readAsStringSync(),
  ];
}

void _printUsage(ArgParser parser) {
  stdout.writeln(
    'Usage: dart run tom_specs_clitool:validate_codespecs '
    '--shared <dir> --client <dir> --server <dir> [options]',
  );
  stdout.writeln();
  stdout.writeln(
    'Enforces the twenty-two checks of codespecs_derivation_contract.md §6. '
    'Any violation fails: the exit code is 1 and every breach is written to '
    'stderr naming its check number and defining section.',
  );
  stdout.writeln();
  stdout.writeln(parser.usage);
}
