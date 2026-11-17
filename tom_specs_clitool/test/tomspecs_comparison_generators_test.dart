/// The `tomspecs` som-*, model-*, schema-*, app-* and editor-* commands
/// against the tools they replace (tsbin5): for each of the 11 commands, the
/// old tool and the command run on the same inputs, writing into a work folder
/// in the system temp folder, and must give the same stdout, stderr, written
/// files and exit code (`support/tomspecs_compare.dart`).
///
/// `:editor-build` is compared where it can be without touching the
/// repository: its refusals before step 1 (step 1 bumps the model's build
/// number, step 3 writes the editor's committed assets). Its generator steps
/// are the commands `:model-spec-ops`, `:model-json` and `:schema-docspecs`,
/// compared here on their own.
///
/// Temporary: tsbin8 removes these tests with the old tools.
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart'
    show runGenerateRegistryTests;

import '../bin/build.dart' as build;
import '../bin/check_som_parity.dart' as check_som_parity;
import '../bin/docspecs_schema.dart' as docspecs_schema;
import '../bin/docspecs_yaml_schema.dart' as docspecs_yaml_schema;
import '../bin/generate_som.dart' as generate_som;
import '../bin/model_json.dart' as model_json;
import '../bin/outliner.dart' as outliner;
import '../bin/spec_ops.dart' as spec_ops;
import '../bin/stamp_serialization_order.dart' as stamp_serialization_order;
import '../bin/summaries.dart' as summaries;
import '../bin/tomspecs.dart' show tomspecsCommands;
import 'support/tomspecs_compare.dart';

final _clitool = Directory.current.path;
String _abs(String rel) => p.normalize(p.join(_clitool, rel));

final _model = _abs('../tom_specs_model');
final _core = _abs('../tom_specs_core');
final _meridianYaml = _abs(
  '../tom_som_dart_v0/documents/meridian_order_management.docspecs.yaml',
);

/// One comparison: `:[command]` with `args(work)` against [old] with the same
/// arguments, in a work folder [prepare] fills.
class _Case {
  final String command;
  final String label;
  final Future<int> Function(List<String>) old;
  final List<String> Function(String work) args;
  final void Function(Directory work)? prepare;

  /// Text that differs between two runs by design (a wall-clock stamp),
  /// replaced in stdout and every file before they are compared.
  final RegExp? volatile;

  const _Case(
    this.command,
    this.label,
    this.old,
    this.args, {
    this.prepare,
    this.volatile,
  });
}

/// [run] with every match of [volatile] replaced by `<volatile>`.
ToolRun _steady(ToolRun run, RegExp? volatile) {
  if (volatile == null) return run;
  String fix(String text) => text.replaceAll(volatile, '<volatile>');
  return ToolRun(run.exitCode, fix(run.stdout), fix(run.stderr), {
    for (final MapEntry(key: name, value: text) in run.files.entries)
      name: fix(text),
  });
}

/// A SOM config that writes the Dart facade only, into `<work>/som`.
void _prepareSomConfig(Directory work) {
  File(p.join(work.path, 'tom_som.yaml')).writeAsStringSync(
    'tom-spec-object-model:\n'
    '  version-label: v0\n'
    '  output-base: ${p.join(work.path, 'som')}\n'
    '  languages:\n'
    '    - dart\n',
  );
}

final _cases = <_Case>[
  _Case(
    'som-generate',
    'the Dart facade into the work folder',
    generate_som.runGenerateSom,
    (w) => ['--config', p.join(w, 'tom_som.yaml')],
    prepare: _prepareSomConfig,
  ),
  _Case(
    'som-parity',
    'the committed planes',
    check_som_parity.runCheckSomParity,
    (w) => [],
  ),
  _Case(
    'model-outline',
    'the information model',
    outliner.runOutliner,
    (w) => [
      '--package',
      _model,
      '--root-type',
      'D03InformationModel',
      '--output',
      p.join(w, 'outline.md'),
    ],
  ),
  _Case(
    'model-outline',
    'the compact blueprint',
    outliner.runOutliner,
    (w) => [
      '--package',
      _model,
      '--root-type',
      'D00SolutionBlueprint',
      '--stop-at-detailed-in',
      '--output',
      p.join(w, 'compact.md'),
    ],
  ),
  _Case(
    'model-json',
    'the model graph',
    model_json.runModelJson,
    (w) => ['--package', _model, '--output', p.join(w, 'spec_model.json')],
    // Without a --target the export is stamped with the time it was made.
    volatile: RegExp(r'"generatedAt": "[^"]*"'),
  ),
  _Case(
    'model-spec-ops',
    'the registry',
    spec_ops.runSpecOps,
    (w) => ['--package', _model, '--output', p.join(w, 'spec_ops.g.dart')],
  ),
  _Case(
    'model-stamp-order',
    'the model, --dry-run',
    stamp_serialization_order.runStampSerializationOrder,
    (w) => ['--package', _model, '--dry-run'],
  ),
  _Case(
    'schema-docspecs',
    'the model roots',
    docspecs_schema.runDocspecsSchema,
    (w) => ['--package', _model, '--out-dir', p.join(w, 'schemas')],
  ),
  _Case(
    'schema-docspecs-yaml',
    'the on-disk YAML schema',
    docspecs_yaml_schema.runDocspecsYamlSchema,
    (w) => ['--out-dir', w],
  ),
  _Case(
    'app-registry-tests',
    'Meridian',
    runGenerateRegistryTests,
    (w) => [_meridianYaml, '--out', p.join(w, 'tests')],
  ),
  _Case(
    'app-registry-tests',
    'Meridian, --check against nothing written',
    runGenerateRegistryTests,
    (w) => [_meridianYaml, '--out', p.join(w, 'tests'), '--check'],
  ),
  _Case(
    'editor-summaries',
    'tom_specs_core',
    summaries.runSummaries,
    (w) => ['--package', _core, '--out-dir', w],
  ),
  _Case(
    'editor-build',
    'an unsupported --os (refused before step 1)',
    build.runBuild,
    (w) => ['--os', 'beos'],
  ),
  _Case(
    'editor-build',
    'a missing --editor (refused before step 1)',
    build.runBuild,
    (w) => ['--os', 'linux', '--editor', p.join(w, 'no_editor')],
  ),
];

void main() {
  final commands = <String>{};

  for (final c in _cases) {
    commands.add(c.command);
    test('CMPG: :${c.command} — ${c.label}', () async {
      final work = Directory(
        p.join(Directory.systemTemp.path, 'tomspecs_cmpg_${c.command}'),
      );
      addTearDown(() {
        if (work.existsSync()) work.deleteSync(recursive: true);
      });
      final args = c.args(work.path);
      final (oldRun, commandRun) = await runBoth(
        work: work,
        old: c.old,
        oldArgs: args,
        command: c.command,
        commandArgs: args,
        prepare: c.prepare,
      );
      final old = _steady(oldRun, c.volatile);
      final command = _steady(commandRun, c.volatile);
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
    }, timeout: const Timeout(Duration(minutes: 10)));
  }

  test('CMPG: every som-*, model-*, schema-*, app-* and editor-* command '
      'is compared', () {
    const groups = ['som-', 'model-', 'schema-', 'app-', 'editor-'];
    expect(commands, {
      for (final c in tomspecsCommands)
        if (groups.any(c.name.startsWith)) c.name,
    });
    expect(commands, hasLength(11));
  });
}
