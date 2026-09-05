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
          'Omitted: the check has nothing to converge and reports nothing.',
    )
    ..addOption(
      'extracts',
      help: 'Directory of per-area extracts (*.extract.yaml), for the comment '
          'checks (32, 33, 34) and the transfer checks (35, 36). Give the '
          "run's whole extract tree or none: a partial one understates what "
          'the trio was supposed to carry, and check 35 would pass a gap it '
          'could not see. Omitted: all five report nothing.',
    )
    ..addOption(
      'cs-vocabulary',
      help: "Path to tom_code_specs' vocabulary source (file or directory), "
          'for the mirrored-catalogue check (9). No catalogue currently has a '
          'tom_core counterpart, so the check has an empty pair table and this '
          'reports nothing until one is added.',
    )
    ..addOption(
      'core-source',
      help: 'Path to the tom_core source (file or directory) holding the '
          'mirrored counterparts, for the mirrored-catalogue check (9). Same '
          'empty-pair-table caveat as --cs-vocabulary.',
    )
    ..addOption(
      'regenerated-shared',
      help: 'Path to a second generation run\'s shared package, for the '
          'determinism check (31). All three or none.',
    )
    ..addOption(
      'regenerated-client',
      help: 'Path to a second generation run\'s client package, for the '
          'determinism check (31). All three or none.',
    )
    ..addOption(
      'regenerated-server',
      help: 'Path to a second generation run\'s server package, for the '
          'determinism check (31). All three or none.',
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

  final regeneration = _regeneration(results);
  final extracts = _extracts(results.option('extracts'));
  final migrations = _migrations(results.option('migrations'));
  final vocabulary = results.option('cs-vocabulary');
  final coreSource = results.option('core-source');
  final input = CodeSpecsValidationInput(
    shared: _project(CsLocus.shared, results.option('shared')!),
    client: _project(CsLocus.client, results.option('client')!),
    server: _project(CsLocus.server, results.option('server')!),
    migrations: migrations,
    enumMirrors: readCsEnumMirrors(
      csSources: _dartSources(vocabulary),
      coreSources: _dartSources(coreSource),
    ),
    regeneration: regeneration,
    extracts: extracts,
  );

  // Every check whose corroborating input is absent says so. The trio is the
  // pass's subject; four questions each need something the trio cannot show,
  // and for all four a silent pass would read as a verified one.
  if (migrations.isEmpty) {
    stdout.writeln(
      'codespecs: check 13 (migration convergence) not run — pass --migrations '
      "pointing at the run's CE-MG artifacts.",
    );
  }
  if (vocabulary == null || coreSource == null) {
    stdout.writeln(
      'codespecs: check 9 (mirrored catalogues) not run — pass both '
      '--cs-vocabulary and --core-source; a catalogue neither side declares '
      'mirrors an empty one, which compares equal.',
    );
  }
  if (regeneration == null) {
    stdout.writeln(
      'codespecs: check 31 (determinism) not run — pass '
      '--regenerated-shared/--regenerated-client/--regenerated-server pointing '
      'at a second generation run over the same model.',
    );
  }
  if (extracts.isEmpty) {
    stdout.writeln(
      'codespecs: check 19 (secret is declared), checks 32, 33 and 34 '
      '(comment source, template and fidelity) and checks 35 and 36 (extract '
      'coverage and back-link resolution) not run — pass --extracts pointing '
      'at the run\'s generated-doc/codespecs_extracts directory.',
    );
  }

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

/// The second run's trio, or `null` when the caller performed none.
///
/// All three or none: two runs of one project and one of another compare
/// nothing useful, and silently checking a third of the output would be worse
/// than checking none of it.
CodeSpecsRegeneration? _regeneration(ArgResults results) {
  final shared = results.option('regenerated-shared');
  final client = results.option('regenerated-client');
  final server = results.option('regenerated-server');
  final given = [shared, client, server].where((p) => p != null).length;
  if (given == 0) return null;
  if (given < 3) {
    stderr.writeln(
      'Error: --regenerated-shared, --regenerated-client and '
      '--regenerated-server are given together or not at all.',
    );
    exit(2);
  }
  return CodeSpecsRegeneration(
    shared: _project(CsLocus.shared, shared!),
    client: _project(CsLocus.client, client!),
    server: _project(CsLocus.server, server!),
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

/// The per-area extracts under [path] — the `<CE-CODE>.extract.yaml` artifacts
/// of record (`codespecs_mapping.md` §1.1.1).
///
/// The rendered `.md` views beside them are deliberately not read: they are a
/// view of the YAML, and reading a view as an input is how a rendering becomes
/// a second source of truth.
CsExtractSet _extracts(String? path) {
  if (path == null) return CsExtractSet.empty;
  final dir = Directory(p.normalize(p.absolute(path)));
  if (!dir.existsSync()) {
    stderr.writeln('Error: extracts directory not found: ${dir.path}');
    exit(2);
  }
  final sources = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.extract.yaml')) continue;
    sources[p.relative(entity.path, from: dir.path)] =
        entity.readAsStringSync();
  }
  try {
    return readCsExtracts(sources);
  } on CsExtractException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(2);
  }
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
    'Enforces the thirty-seven checks of codespecs_derivation_contract.md §6. '
    'Any violation fails: the exit code is 1 and every breach is written to '
    'stderr naming its check number and defining section.',
  );
  stdout.writeln();
  stdout.writeln(parser.usage);
}
