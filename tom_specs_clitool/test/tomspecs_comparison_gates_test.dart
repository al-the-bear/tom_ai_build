/// The `tomspecs` gate-* commands against the gate tools they replace
/// (tsbin6): for each of the 11 gates, the old tool and the command check the
/// current tree and must give the same report (stdout, stderr) and exit code
/// (`support/tomspecs_compare.dart`). And one call running three gates gives
/// the three single runs' verdicts.
///
/// The gates read the tree and write nothing. The formatting gate and the
/// dartdoc gate are narrowed to keep the default suite short — a two-package
/// manifest, and `--package tom_specs_core` — since their full sets cost
/// minutes each, twice; the other nine check their whole default sets.
///
/// Temporary: tsbin8 removes these tests with the old tools.
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../bin/check_api_signatures.dart' as check_api_signatures;
import '../bin/check_dartdoc_build.dart' as check_dartdoc_build;
import '../bin/check_doc_coverage.dart' as check_doc_coverage;
import '../bin/check_format.dart' as check_format;
import '../bin/check_oe_citations.dart' as check_oe_citations;
import '../bin/check_release_closure.dart' as check_release_closure;
import '../bin/check_release_drift.dart' as check_release_drift;
import '../bin/check_section_citations.dart' as check_section_citations;
import '../bin/check_shipped_paths.dart' as check_shipped_paths;
import '../bin/check_spec_tree_duplication.dart' as check_spec_tree_duplication;
import '../bin/check_todo_citations.dart' as check_todo_citations;
import '../bin/tomspecs.dart' show runTomspecs, tomspecsCommands;
import 'support/tomspecs_compare.dart';

final _container = p.normalize(
  p.join(Directory.current.path, '..', '..', '..'),
);

/// One comparison: `:[command]` with `args(work)` against [old] with the same
/// arguments.
class _Case {
  final String command;
  final String label;
  final Future<int> Function(List<String>) old;
  final List<String> Function(String work) args;
  final void Function(Directory work)? prepare;

  const _Case(this.command, this.label, this.old, this.args, {this.prepare});
}

/// A formatting manifest of two packages, in `<work>/format_set.yaml`.
void _prepareFormatSet(Directory work) {
  File(p.join(work.path, 'format_set.yaml')).writeAsStringSync(
    'directories:\n'
    '  - lib\n'
    '  - bin\n'
    '  - test\n'
    'exclude-suffixes:\n'
    '  - .b.dart\n'
    'packages:\n'
    '  - tom_ai/ai_build/tom_specs_core\n'
    '  - tom_ai/ai_build/tom_doc_scanner\n',
  );
}

final _cases = <_Case>[
  _Case(
    'gate-format',
    'two packages',
    check_format.runCheckFormat,
    (w) => [
      '--manifest',
      p.join(w, 'format_set.yaml'),
      '--container-root',
      _container,
    ],
    prepare: _prepareFormatSet,
  ),
  _Case(
    'gate-api-signatures',
    'the governed summaries',
    check_api_signatures.runCheckApiSignatures,
    (w) => [],
  ),
  _Case(
    'gate-dartdoc',
    'tom_specs_core',
    check_dartdoc_build.runCheckDartdocBuild,
    (w) => ['--package', 'tom_ai/ai_build/tom_specs_core'],
  ),
  _Case(
    'gate-doc-coverage',
    'the manifest',
    check_doc_coverage.runCheckDocCoverage,
    (w) => [],
  ),
  _Case(
    'gate-oe-citations',
    'the register and the editor',
    check_oe_citations.runCheckOeCitations,
    (w) => [],
  ),
  _Case(
    'gate-section-citations',
    'the doc set',
    check_section_citations.runCheckSectionCitations,
    (w) => [],
  ),
  _Case(
    'gate-todo-citations',
    'the doc set',
    check_todo_citations.runCheckTodoCitations,
    (w) => [],
  ),
  _Case(
    'gate-release-closure',
    'the release set',
    check_release_closure.runCheckReleaseClosure,
    (w) => [],
  ),
  _Case(
    'gate-release-closure',
    'the release set, --verbose',
    check_release_closure.runCheckReleaseClosure,
    (w) => ['--verbose'],
  ),
  _Case(
    'gate-release-drift',
    'the release set',
    check_release_drift.runCheckReleaseDrift,
    (w) => [],
  ),
  _Case(
    'gate-shipped-paths',
    'the publishable packages',
    check_shipped_paths.runCheckShippedPaths,
    (w) => [],
  ),
  _Case(
    'gate-spec-tree-duplication',
    'against the baseline',
    check_spec_tree_duplication.runCheckSpecTreeDuplication,
    (w) => [],
  ),
];

void main() {
  final commands = <String>{};

  for (final c in _cases) {
    commands.add(c.command);
    test('CMPGATE: :${c.command} — ${c.label}', () async {
      final work = Directory(
        p.join(Directory.systemTemp.path, 'tomspecs_cmpgate_${c.command}'),
      );
      addTearDown(() {
        if (work.existsSync()) work.deleteSync(recursive: true);
      });
      final args = c.args(work.path);
      final (old, command) = await runBoth(
        work: work,
        old: c.old,
        oldArgs: args,
        command: c.command,
        commandArgs: args,
        prepare: c.prepare,
      );
      expect(
        old.stdout.isNotEmpty || old.stderr.isNotEmpty,
        isTrue,
        reason: ':${c.command} (${c.label}) reported nothing',
      );
      expectSameRun(old, command, reason: ':${c.command} (${c.label})');
      if (Platform.environment['TOMSPECS_CMP_VERBOSE'] == '1') {
        print(
          'CMPSUMMARY :${c.command} (${c.label}): exit ${old.exitCode}, '
          '${old.stdout.length} chars out, ${old.stderr.length} err',
        );
      }
    }, timeout: const Timeout(Duration(minutes: 15)));
  }

  test('CMPGATE: every gate-* command is compared', () {
    expect(commands, {
      for (final c in tomspecsCommands)
        if (c.name.startsWith('gate-')) c.name,
    });
    expect(commands, hasLength(11));
  });

  test(
    'CMPGATE: one call of three gates gives the single runs\' verdicts',
    () async {
      const gates = [
        'gate-release-closure',
        'gate-release-drift',
        'gate-section-citations',
      ];
      final singles = <(int, String, String)>[
        for (final g in gates) await captureIo(() => runTomspecs([':$g'])),
      ];
      final (code, out, err) = await captureIo(
        () => runTomspecs([for (final g in gates) ':$g']),
      );
      // The run stops at the first failing gate with its code; on a green tree
      // every gate runs and the run is green.
      final firstFailing = singles.indexWhere((s) => s.$1 != 0);
      final ran = firstFailing < 0
          ? singles
          : singles.sublist(0, firstFailing + 1);
      expect(code, firstFailing < 0 ? 0 : singles[firstFailing].$1);
      expect(out, [for (final s in ran) s.$2].join());
      expect(err, [for (final s in ran) s.$3].join());
      for (final s in singles) {
        expect(s.$2, isNotEmpty);
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
