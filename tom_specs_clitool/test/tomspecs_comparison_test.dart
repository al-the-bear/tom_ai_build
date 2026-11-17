/// The `tomspecs` spec-*, codespecs-* and ir-* commands against the tools they
/// replace (tsbin4): for each of the 17 commands, the old tool and the command
/// run on the same inputs (Meridian, the conformance samples, and Tom UAM's
/// specification where its project data is needed) and must give the same
/// stdout, stderr, written files and exit code (`support/tomspecs_compare.dart`).
///
/// Temporary: tsbin8 removes these tests with the old tools.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/src/spec_checks_cli.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

import '../bin/codespecs_areas.dart' as codespecs_areas;
import '../bin/tomspecs.dart' show tomspecsCommands;
import 'support/tomspecs_compare.dart';

final _clitool = Directory.current.path;
String _abs(String rel) => p.normalize(p.join(_clitool, rel));

final _meridianYaml = _abs(
  '../tom_som_dart_v0/documents/meridian_order_management.docspecs.yaml',
);
final _meridianMd = _abs(
  '../tom_som_dart_v0/documents/meridian_order_management.md',
);
final _trio = _abs('../tom_som_conformance/samples/meridian_codespecs');
final _areas = _abs(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);
final _exercise = _abs(
  '../tom_som_conformance/samples/exercise_full_model.docspecs.yaml',
);
final _uam = _abs('../../../tom_uam/tom_specs');
final _uamSbp = p.join(
  _uam,
  'phase2_solution_blueprint',
  'tom_uam.sbp.docspecs.yaml',
);
final _uamIndex = p.join(
  _uam,
  'phase2_solution_blueprint',
  'clarifications.sbp.md',
);
final _uamIdea = p.join(_uam, 'phase1_project_idea', 'project_idea.tom_uam.md');

List<String> _trioArgs() => [
  for (final locus in ['shared', 'client', 'server']) ...[
    '--$locus',
    p.join(_trio, 'meridian_codespec_$locus'),
  ],
];

Future<int> _specChecks(List<String> args) async => runSpecChecks(args);

/// One comparison: `:[command]` with `args(work)` against [old] with
/// [oldPrefix] + `args(work)`, in a work folder [prepare] fills.
class _Case {
  final String command;
  final String label;
  final Future<int> Function(List<String>) old;
  final List<String> oldPrefix;
  final List<String> Function(String work) args;
  final void Function(Directory work)? prepare;
  final bool needsUam;

  const _Case(
    this.command,
    this.label,
    this.old,
    this.args, {
    this.oldPrefix = const [],
    this.prepare,
    this.needsUam = false,
  });
}

/// Writes the Meridian IR into `<work>/ir`.
void _prepareIr(Directory work) {
  final index = IrAreaIndex(
    CodeSpecsAreaCatalog.fromJson(
      jsonDecode(File(_areas).readAsStringSync()) as Map<String, dynamic>,
    ),
  );
  CsLocusProject read(CsLocus locus) => readCsLocusProjectFromDirectory(
    locus: locus,
    packageName: 'meridian_codespec_${locus.name}',
    root: p.join(_trio, 'meridian_codespec_${locus.name}'),
  );
  final docs = irFromCsModel(
    shared: read(CsLocus.shared),
    client: read(CsLocus.client),
    server: read(CsLocus.server),
    areas: index,
  );
  final dir = Directory(p.join(work.path, 'ir'))..createSync();
  for (final d in docs) {
    File(
      p.join(dir.path, index.fileNameOf(d.area)),
    ).writeAsStringSync(writeIrYaml(d));
  }
}

void _copyMeridian(Directory work) {
  File(_meridianYaml).copySync(p.join(work.path, 'doc.docspecs.yaml'));
  File(_meridianMd).copySync(p.join(work.path, 'doc.md'));
}

final _cases = <_Case>[
  // validate_spec
  _Case('spec-validate', 'Meridian', runValidateSpec, (w) => [_meridianYaml]),
  _Case(
    'spec-validate',
    'Meridian, --json and --markdown-out',
    runValidateSpec,
    (w) => ['--json', '--markdown-out', p.join(w, 'out.md'), _meridianYaml],
  ),
  // the nine spec_checks checks
  _Case(
    'spec-render',
    'Meridian with a rendition',
    _specChecks,
    (w) => [_meridianYaml, p.join(w, 'rendition.md')],
    oldPrefix: const ['validate'],
  ),
  _Case(
    'spec-import-answers',
    'a copy of Meridian, --dry-run',
    _specChecks,
    (w) => ['--dry-run', p.join(w, 'doc.docspecs.yaml'), p.join(w, 'doc.md')],
    oldPrefix: const ['import-answers'],
    prepare: _copyMeridian,
  ),
  _Case(
    'spec-accept-marks',
    'a copy of Meridian, --write',
    _specChecks,
    (w) => [p.join(w, 'doc.docspecs.yaml'), '--write'],
    oldPrefix: const ['accept-marks'],
    prepare: _copyMeridian,
  ),
  _Case(
    'spec-required-fields',
    'Meridian',
    _specChecks,
    (w) => [_meridianYaml],
    oldPrefix: const ['required-fields'],
  ),
  _Case(
    'spec-question-register',
    "Tom UAM's blueprint and question index",
    _specChecks,
    (w) => [_uamSbp, _uamIndex],
    oldPrefix: const ['question-register'],
    needsUam: true,
  ),
  _Case(
    'spec-feature-register',
    'Meridian',
    _specChecks,
    (w) => [_meridianYaml],
    oldPrefix: const ['feature-register'],
  ),
  _Case(
    'spec-idea-coverage',
    "Tom UAM's Project Idea and blueprint, --all",
    _specChecks,
    (w) => [_uamIdea, _uamSbp, '--all'],
    oldPrefix: const ['project-idea-coverage'],
    needsUam: true,
  ),
  _Case(
    'spec-authorization',
    "Tom UAM's blueprint",
    _specChecks,
    (w) => [_uamSbp],
    oldPrefix: const ['authorization'],
    needsUam: true,
  ),
  _Case(
    'spec-coverage',
    "the full-model sample and Meridian, Tom UAM's rows, --tsv",
    _specChecks,
    (w) => [_exercise, _meridianYaml, '--tsv', p.join(w, 'empty.tsv')],
    oldPrefix: const ['--spec-root', '__UAM__', 'coverage'],
    needsUam: true,
  ),
  // extract_answers
  _Case(
    'spec-answers',
    'Meridian, --open --marks --counts',
    runExtractAnswers,
    (w) => [
      '--output',
      p.join(w, 'answers.md'),
      '--open',
      '--marks',
      '--counts',
      _meridianMd,
    ],
  ),
  // validate_codespecs
  _Case(
    'codespecs-validate',
    'the Meridian trio',
    runValidateCodespecs,
    (w) => _trioArgs(),
  ),
  _Case(
    'codespecs-validate',
    'the Meridian trio, --json',
    runValidateCodespecs,
    (w) => [..._trioArgs(), '--json'],
  ),
  _Case(
    'codespecs-validate',
    'the Meridian trio, --backlinks',
    runValidateCodespecs,
    (w) => [..._trioArgs(), '--backlinks'],
  ),
  _Case(
    'codespecs-validate',
    'the Meridian IR',
    runValidateCodespecs,
    (w) => ['--ir', p.join(w, 'ir')],
    prepare: _prepareIr,
  ),
  // codespecs_areas
  _Case(
    'codespecs-areas',
    'the committed catalogue, --check',
    codespecs_areas.runCodespecsAreas,
    (w) => ['--check'],
  ),
  // irspecs
  _Case(
    'ir-from-codespecs',
    'the Meridian trio',
    runIrspecs,
    (w) => [..._trioArgs(), '--areas', _areas, '--out', p.join(w, 'ir')],
    oldPrefix: const ['from-codespecs'],
  ),
  _Case(
    'ir-map',
    'the Meridian IR through dart-tom',
    runIrspecs,
    (w) => [
      '--mapper',
      'dart-tom',
      '--ir',
      p.join(w, 'ir'),
      '--out',
      p.join(w, 'trio'),
    ],
    oldPrefix: const ['map'],
    prepare: _prepareIr,
  ),
  _Case(
    'ir-emit',
    'the Meridian IR as OpenAPI',
    runIrspecs,
    (w) => [
      '--standard',
      'openapi',
      '--ir',
      p.join(w, 'ir'),
      '--out',
      p.join(w, 'emit'),
    ],
    oldPrefix: const ['emit'],
    prepare: _prepareIr,
  ),
  _Case(
    'ir-emit',
    'the Meridian IR as Markdown, with the specification',
    runIrspecs,
    (w) => [
      '--standard',
      'markdown',
      '--ir',
      p.join(w, 'ir'),
      '--areas',
      _areas,
      '--spec',
      _meridianYaml,
      '--out',
      p.join(w, 'md'),
    ],
    oldPrefix: const ['emit'],
    prepare: _prepareIr,
  ),
  _Case(
    'ir-export',
    'the Meridian IR as JSON',
    runIrspecs,
    (w) => [
      '--format',
      'json',
      '--ir',
      p.join(w, 'ir'),
      '--out',
      p.join(w, 'json'),
    ],
    oldPrefix: const ['export'],
    prepare: _prepareIr,
  ),
  // a usage error the tool itself reports behaves alike too
  _Case(
    'ir-export',
    'a missing --out (usage error)',
    runIrspecs,
    (w) => ['--format', 'json', '--ir', p.join(w, 'ir')],
    oldPrefix: const ['export'],
    prepare: _prepareIr,
  ),
];

void main() {
  final hasUam =
      File(_uamSbp).existsSync() &&
      Directory(p.join(_uam, 'checks')).existsSync();
  final commands = <String>{};

  for (final c in _cases) {
    commands.add(c.command);
    test('CMP: :${c.command} — ${c.label}', () async {
      if (c.needsUam && !hasUam) {
        markTestSkipped("Tom UAM's specification is not in this checkout");
        return;
      }
      final work = Directory(
        p.join(Directory.systemTemp.path, 'tomspecs_cmp_${c.command}'),
      );
      addTearDown(() {
        if (work.existsSync()) work.deleteSync(recursive: true);
      });
      final args = c.args(work.path);
      // spec-coverage's --spec-root goes before the check for the old tool.
      final prefix = [for (final a in c.oldPrefix) a == '__UAM__' ? _uam : a];
      final commandArgs = c.command == 'spec-coverage'
          ? [...args, '--spec-root', _uam]
          : args;
      final (old, command) = await runBoth(
        work: work,
        old: c.old,
        oldArgs: [...prefix, ...args],
        command: c.command,
        commandArgs: commandArgs,
        prepare: c.prepare,
      );
      // Not a vacuous comparison: the tool did something observable.
      expect(
        old.stdout.isNotEmpty || old.stderr.isNotEmpty || old.files.isNotEmpty,
        isTrue,
        reason: ':${c.command} (${c.label}) printed and wrote nothing',
      );
      expectSameRun(old, command, reason: ':${c.command} (${c.label})');
      if (Platform.environment['TOMSPECS_CMP_VERBOSE'] == '1') {
        print(
          'CMPSUMMARY :${c.command} (${c.label}): exit ${old.exitCode}, '
          '${old.stdout.length} chars out, ${old.stderr.length} err, '
          '${old.files.length} file(s)',
        );
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }

  test('CMP: every spec-*, codespecs-* and ir-* command is compared', () {
    expect(commands, {
      for (final c in tomspecsCommands)
        if (c.name.startsWith('spec-') ||
            c.name.startsWith('codespecs-') ||
            c.name.startsWith('ir-'))
          c.name,
    });
    expect(commands, hasLength(17));
  });

  test('CMP: a work folder outside the temp folder is refused', () async {
    await expectLater(
      runBoth(
        work: Directory.current,
        old: (a) async => 0,
        oldArgs: const [],
        command: 'ir-export',
        commandArgs: const [],
      ),
      throwsArgumentError,
    );
    expect(
      Directory(p.join(Directory.current.path, 'bin')).existsSync(),
      isTrue,
    );
  });
}
