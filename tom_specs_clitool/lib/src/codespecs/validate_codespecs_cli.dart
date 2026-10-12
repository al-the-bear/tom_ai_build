/// The `validate_codespecs` command, as a function the entry point and the
/// tests both call.
///
/// Three outputs from one binary:
///
/// * the text report (default) — every violation on stderr naming its check
///   number and defining section, the summary on stdout;
/// * `--json` — one JSON document on stdout ([kCodeSpecsReportFormat]), for a
///   tool that would otherwise scrape the text;
/// * `--backlinks` — the back-link index ([kCodeSpecsBacklinksFormat]): every
///   declaration of the trio with its `@CodeSpec` id and source tokens and its
///   `@DocSpec` tokens, the input for tracing generated code to spec values.
///   It needs only the trio and runs no check.
///
/// Exit codes are the same in every mode: `0` clean, `1` at least one
/// violation, `2` bad usage. The reader parses source text only — no analysis
/// context, no SDK, no package resolution — so the command compiles with
/// `dart compile exe` into a standalone binary.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'codespecs_validator.dart';
import 'cs_checks.dart';
import 'cs_extract.dart';
import 'cs_model.dart';
import 'cs_reader.dart';

/// The `format` of the `--json` report. Bumped only on a breaking change.
const String kCodeSpecsReportFormat = 'codespecs-validation';

/// The `formatVersion` of the `--json` report.
const int kCodeSpecsReportFormatVersion = 1;

/// The `format` of the `--backlinks` index.
const String kCodeSpecsBacklinksFormat = 'codespecs-backlinks';

/// The `formatVersion` of the `--backlinks` index.
const int kCodeSpecsBacklinksFormatVersion = 1;

/// Bad usage: reported on stderr, exit 2.
class _UsageError implements Exception {
  final String message;
  final bool showUsage;
  const _UsageError(this.message, {this.showUsage = false});
}

/// The option set — exposed so the README correspondence test reads it.
ArgParser validateCodespecsParser() => ArgParser()
  ..addOption(
    'shared',
    help: 'Path to the generated <app>_codespec_shared package.',
  )
  ..addOption(
    'client',
    help: 'Path to the generated <app>_codespec_client package.',
  )
  ..addOption(
    'server',
    help: 'Path to the generated <app>_codespec_server package.',
  )
  ..addOption(
    'migrations',
    help:
        'Directory of CE-MG migration artifacts (*.sql), for check 13. '
        'Omitted: the check has nothing to converge and reports nothing.',
  )
  ..addOption(
    'extracts',
    help:
        'Directory of per-area extracts (*.extract.yaml), for the comment '
        'checks (32, 33, 34) and the transfer checks (35, 36). Give the '
        "run's whole extract tree or none: a partial one understates what "
        'the trio was supposed to carry, and check 35 would pass a gap it '
        'could not see. A legitimate partial pass is recorded, not '
        'truncated: a gate.verdicts.yaml beside the extracts '
        '(codespecs_prompt.md §6.3) scopes the obligation set to the '
        'sufficient areas. Omitted: all five report nothing.',
  )
  ..addOption(
    'cs-vocabulary',
    help:
        "Path to tom_code_specs' vocabulary source (file or directory), "
        'for the mirrored-catalogue check (9). No catalogue currently has a '
        'tom_core counterpart, so the check has an empty pair table and this '
        'reports nothing until one is added.',
  )
  ..addOption(
    'core-source',
    help:
        'Path to the tom_core source (file or directory) holding the '
        'mirrored counterparts, for the mirrored-catalogue check (9). Same '
        'empty-pair-table caveat as --cs-vocabulary.',
  )
  ..addOption(
    'regenerated-shared',
    help:
        'Path to a second generation run\'s shared package, for the '
        'determinism check (31). All three or none.',
  )
  ..addOption(
    'regenerated-client',
    help:
        'Path to a second generation run\'s client package, for the '
        'determinism check (31). All three or none.',
  )
  ..addOption(
    'regenerated-server',
    help:
        'Path to a second generation run\'s server package, for the '
        'determinism check (31). All three or none.',
  )
  ..addFlag(
    'json',
    help:
        'Write one JSON report to stdout instead of the text report '
        '(format `$kCodeSpecsReportFormat`, version '
        '$kCodeSpecsReportFormatVersion). Exit codes are unchanged.',
    negatable: false,
  )
  ..addFlag(
    'backlinks',
    help:
        'Write the back-link index of the trio as JSON to stdout (format '
        '`$kCodeSpecsBacklinksFormat`) and run no check. Needs only '
        '--shared, --client and --server.',
    negatable: false,
  )
  ..addFlag(
    'help',
    abbr: 'h',
    help: 'Show usage information.',
    negatable: false,
  );

/// Runs the command over [arguments] and returns the exit code.
///
/// [out] and [err] default to the process streams; a test passes its own.
Future<int> runValidateCodespecs(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
}) async {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;
  final parser = validateCodespecsParser();
  try {
    final ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      throw _UsageError(e.message, showUsage: true);
    }
    if (results.flag('help')) {
      _printUsage(parser, stdoutSink);
      return 0;
    }
    final missing = [
      for (final name in ['shared', 'client', 'server'])
        if (results.option(name) == null) name,
    ];
    if (missing.isNotEmpty) {
      throw _UsageError(
        'the CodeSpecs trio is the pass\'s subject; missing required '
        'option(s): ${missing.map((n) => '--$n').join(', ')}.',
        showUsage: true,
      );
    }
    if (results.flag('json') && results.flag('backlinks')) {
      throw const _UsageError(
        '--json and --backlinks are two different documents; give one.',
      );
    }

    final shared = _project(CsLocus.shared, results.option('shared')!);
    final client = _project(CsLocus.client, results.option('client')!);
    final server = _project(CsLocus.server, results.option('server')!);

    if (results.flag('backlinks')) {
      stdoutSink.writeln(
        const JsonEncoder.withIndent('  ').convert(
          codeSpecsBacklinkIndex(
            [shared, client, server],
            inputs: {
              'shared': results.option('shared'),
              'client': results.option('client'),
              'server': results.option('server'),
            },
          ),
        ),
      );
      return 0;
    }

    final regeneration = _regeneration(results);
    final extracts = _extracts(results.option('extracts'));
    final migrations = _migrations(results.option('migrations'));
    final vocabulary = results.option('cs-vocabulary');
    final coreSource = results.option('core-source');
    final input = CodeSpecsValidationInput(
      shared: shared,
      client: client,
      server: server,
      migrations: migrations,
      enumMirrors: readCsEnumMirrors(
        csSources: _dartSources(vocabulary),
        coreSources: _dartSources(coreSource),
      ),
      regeneration: regeneration,
      extracts: extracts,
    );

    // Every check whose corroborating input is absent says so — in both
    // outputs. The trio is the pass's subject; four questions each need
    // something the trio cannot show, and for all four a silent pass would
    // read as a verified one.
    final notRun = <Map<String, Object?>>[
      if (migrations.isEmpty)
        {
          'checks': [13],
          'reason':
              'check 13 (migration convergence) not run — pass --migrations '
              "pointing at the run's CE-MG artifacts.",
        },
      if (vocabulary == null || coreSource == null)
        {
          'checks': [9],
          'reason':
              'check 9 (mirrored catalogues) not run — pass both '
              '--cs-vocabulary and --core-source; a catalogue neither side '
              'declares mirrors an empty one, which compares equal.',
        },
      if (regeneration == null)
        {
          'checks': [31],
          'reason':
              'check 31 (determinism) not run — pass '
              '--regenerated-shared/--regenerated-client/--regenerated-server '
              'pointing at a second generation run over the same model.',
        },
      if (extracts.isEmpty)
        {
          'checks': [19, 32, 33, 34, 35, 36],
          'reason':
              'check 19 (secret is declared), checks 32, 33 and 34 (comment '
              'source, template and fidelity) and checks 35 and 36 (extract '
              'coverage and back-link resolution) not run — pass --extracts '
              "pointing at the run's generated-doc/codespecs_extracts "
              'directory.',
        },
    ];
    final excluded = [
      for (final area in extracts.excluded)
        {
          'area': area.areaCode,
          'verdict': area.verdict.word,
          'descoped': area.descoped,
          'entryCount': area.entryCount,
          'source': area.source,
          'message':
              '${area.areaCode} excluded by gate.verdicts.yaml (verdict '
              '`${area.verdict.word}`'
              '${area.descoped ? ', resolution `descoped`' : ''}) — '
              '${area.entryCount == 0 ? 'no routed entries' : '${area.entryCount} '
                        'routed entr${area.entryCount == 1 ? 'y' : 'ies'} dropped '
                        'from the obligation set'}; checks 32–36 do not hold the '
              'trio to this area.',
        },
    ];

    final report = runCodeSpecsChecks(input);
    if (results.flag('json')) {
      stdoutSink.writeln(
        const JsonEncoder.withIndent('  ').convert(
          codeSpecsReportJson(
            report,
            inputs: {
              for (final name in [
                'shared',
                'client',
                'server',
                'extracts',
                'migrations',
                'cs-vocabulary',
                'core-source',
                'regenerated-shared',
                'regenerated-client',
                'regenerated-server',
              ])
                name: results.option(name),
            },
            notRun: notRun,
            excludedAreas: excluded,
          ),
        ),
      );
    } else {
      for (final n in notRun) {
        stdoutSink.writeln('codespecs: ${n['reason']}');
      }
      for (final e in excluded) {
        stdoutSink.writeln('codespecs: ${e['message']}');
      }
      for (final line in report.lines) {
        stderrSink.writeln(line);
      }
      stdoutSink.writeln(report.summary);
    }
    return report.passed ? 0 : 1;
  } on _UsageError catch (e) {
    stderrSink.writeln('Error: ${e.message}');
    if (e.showUsage) {
      stderrSink.writeln();
      _printUsage(parser, stderrSink);
    }
    return 2;
  }
}

/// The `--json` report for [report]. Paths in `inputs` are echoed as given,
/// and violation files are package-relative, so a recorded report does not
/// name the machine it was produced on.
Map<String, Object?> codeSpecsReportJson(
  CodeSpecsValidationReport report, {
  Map<String, String?> inputs = const {},
  List<Map<String, Object?>> notRun = const [],
  List<Map<String, Object?>> excludedAreas = const [],
}) {
  final titles = {for (final c in report.checks) c.number: c.title};
  return {
    'format': kCodeSpecsReportFormat,
    'formatVersion': kCodeSpecsReportFormatVersion,
    'inputs': inputs,
    'passed': report.passed,
    'summary': report.summary,
    'checks': [
      for (final c in report.checks)
        {'number': c.number, 'definedIn': c.definedIn, 'title': c.title},
    ],
    'notRun': notRun,
    'excludedAreas': excludedAreas,
    'violations': [
      for (final v in report.violations)
        {
          'check': v.check,
          'checkTitle': titles[v.check],
          'definedIn': v.definedIn,
          // Every `codespecs_derivation_contract.md` §6 check rejects; the field exists so a later
          // advisory check does not need a format bump.
          'severity': 'error',
          'file': v.location?.file,
          'line': v.location?.line,
          'token': v.token,
          'area': v.area,
          'message': v.message,
        },
    ],
  };
}

/// The back-link index over [projects]: one row per declaration, in project
/// then source order.
Map<String, Object?> codeSpecsBacklinkIndex(
  List<CsLocusProject> projects, {
  Map<String, String?> inputs = const {},
}) => {
  'format': kCodeSpecsBacklinksFormat,
  'formatVersion': kCodeSpecsBacklinksFormatVersion,
  'inputs': inputs,
  'declarations': [
    for (final project in projects)
      for (final d in project.declarations)
        {
          'locus': d.locus.label,
          'package': project.packageName,
          'name': d.name,
          'owner': d.owner,
          'path': d.path,
          'kind': d.kind.name,
          'file': d.location.file,
          'line': d.location.line,
          'markers': [for (final m in d.markers) m.name],
          'codeSpec': d.codeSpec == null
              ? null
              : {
                  'id': d.codeSpec!.id,
                  'source': d.codeSpec!.source,
                  'line': d.codeSpec!.location.line,
                },
          'docSpec': d.docSpec == null
              ? null
              : [
                  for (final r in d.docSpec!)
                    {'token': r.sectionId, 'description': r.description},
                ],
          'docSpecLine': d.docSpecLocation?.line,
          'tokens': csCitedSectionIdsOf(d).toList(),
        },
  ],
};

CsLocusProject _project(CsLocus locus, String path) {
  final root = p.normalize(p.absolute(path));
  if (!Directory(root).existsSync()) {
    throw _UsageError('${locus.label} package not found: $root');
  }
  return readCsLocusProjectFromDirectory(
    locus: locus,
    packageName: p.basename(root),
    root: root,
  );
}

/// The second run's trio, or `null` when the caller performed none. All three
/// or none: checking a third of a second run would be worse than none.
CodeSpecsRegeneration? _regeneration(ArgResults results) {
  final shared = results.option('regenerated-shared');
  final client = results.option('regenerated-client');
  final server = results.option('regenerated-server');
  final given = [shared, client, server].where((p) => p != null).length;
  if (given == 0) return null;
  if (given < 3) {
    throw const _UsageError(
      '--regenerated-shared, --regenerated-client and --regenerated-server '
      'are given together or not at all.',
    );
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
    throw _UsageError('migrations directory not found: ${dir.path}');
  }
  return {
    for (final entity in dir.listSync(recursive: true))
      if (entity is File && entity.path.toLowerCase().endsWith('.sql'))
        p.relative(entity.path, from: dir.path): entity.readAsStringSync(),
  };
}

/// The per-area extracts under [path] plus an optional gate record. The `.md`
/// views beside them are deliberately not read: a view read as input becomes
/// a second source of truth.
CsExtractSet _extracts(String? path) {
  if (path == null) return CsExtractSet.empty;
  final dir = Directory(p.normalize(p.absolute(path)));
  if (!dir.existsSync()) {
    throw _UsageError('extracts directory not found: ${dir.path}');
  }
  final sources = <String, String>{};
  final files = dir.listSync(recursive: true).whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final entity in files) {
    final isExtract = entity.path.endsWith('.extract.yaml');
    final isGate = p.basename(entity.path) == kCsGateRecordFile;
    if (!isExtract && !isGate) continue;
    sources[p.relative(entity.path, from: dir.path)] = entity
        .readAsStringSync();
  }
  try {
    return readCsExtracts(sources);
  } on CsExtractException catch (e) {
    throw _UsageError(e.message);
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
    throw _UsageError('source path not found: $resolved');
  }
  return [
    for (final entity in dir.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.readAsStringSync(),
  ];
}

void _printUsage(ArgParser parser, StringSink sink) {
  sink.writeln(
    'Usage: validate_codespecs --shared <dir> --client <dir> --server <dir> '
    '[options]',
  );
  sink.writeln();
  sink.writeln(
    'Enforces the thirty-seven checks of codespecs_derivation_contract.md §6. '
    'Any violation fails: the exit code is 1 and every breach is written to '
    'stderr naming its check number and defining section (or to the --json '
    'report). --backlinks writes the trio\'s back-link index instead.',
  );
  sink.writeln();
  sink.writeln(parser.usage);
}
