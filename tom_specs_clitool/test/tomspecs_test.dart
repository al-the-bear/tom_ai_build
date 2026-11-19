/// The `tomspecs` binary (`bin/tomspecs.dart`): the TSB-7 command table, the
/// help and the version, several commands per call stopping at the first
/// failure with its own exit code (TSB-5), usage errors, and how a command's
/// options and positionals reach the tool it replaces.
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/src/version.versioner.dart';

import '../bin/tomspecs.dart';

/// The command names of the TSB-7 table
/// (`decisions/tsimp1a_clitool_on_tom_build_base.md`), in its order, with the
/// commands added since in their place: `spec-impact-walk` (the change mode's
/// impact walk) after `spec-validate`, `spec-fill-frem` (FREM from git)
/// after `spec-coverage`.
const _tsb7 = [
  'spec-validate',
  'spec-impact-walk',
  'spec-render',
  'spec-import-answers',
  'spec-accept-marks',
  'spec-required-fields',
  'spec-question-register',
  'spec-feature-register',
  'spec-idea-coverage',
  'spec-authorization',
  'spec-coverage',
  'spec-fill-frem',
  'spec-answers',
  'codespecs-validate',
  'codespecs-areas',
  'ir-from-codespecs',
  'ir-map',
  'ir-emit',
  'ir-export',
  'som-generate',
  'som-parity',
  'model-outline',
  'model-json',
  'model-spec-ops',
  'model-stamp-order',
  'schema-docspecs',
  'schema-docspecs-yaml',
  'app-registry-tests',
  'editor-summaries',
  'editor-build',
  'gate-format',
  'gate-api-signatures',
  'gate-dartdoc',
  'gate-doc-coverage',
  'gate-oe-citations',
  'gate-section-citations',
  'gate-todo-citations',
  'gate-release-closure',
  'gate-release-drift',
  'gate-shipped-paths',
  'gate-spec-tree-duplication',
];

Future<(int, String, String)> _run(
  List<String> args, {
  Map<String, Future<int> Function(List<String>)>? overrides,
}) async {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = await runTomspecs(
    args,
    out: out,
    err: err,
    runOverrides: overrides,
  );
  return (code, '$out', '$err');
}

void main() {
  test('TS1: the commands are the TSB-7 table, in its order', () {
    expect([for (final c in tomspecsCommands) c.name], _tsb7);
    expect([for (final c in tomspecsTool.commands) c.name], _tsb7);
  });

  test('TS2: --help lists every command', () async {
    final (code, out, _) = await _run(['--help']);
    expect(code, 0);
    for (final name in _tsb7) {
      expect(out, contains(':$name'), reason: name);
    }
  });

  test('TS3: --version prints the versioner stamp', () async {
    final (code, out, _) = await _run(['--version']);
    expect(code, 0);
    expect(
      out,
      startsWith('tomspecs ${TomSpecsClitoolVersionInfo.versionMedium}'),
    );
    expect(TomSpecsClitoolVersionInfo.version, isNotEmpty);
  });

  test('TS4: a command\'s help shows its options', () async {
    final (code, out, _) = await _run([':ir-export', '--help']);
    expect(code, 0);
    expect(out, contains('--format'));
    expect(out, contains('One of: json'));
    expect(out, isNot(contains('--mapper')));
  });

  group('TS5: several commands in one call (TSB-5)', () {
    test(
      'a real failing command stops the run with its own exit code',
      () async {
        final ran = <String>[];
        final missing = p.join(
          Directory.current.path,
          'no_such_format_set.yaml',
        );
        final (code, _, _) = await _run(
          [':gate-format', '--manifest', missing, ':gate-section-citations'],
          overrides: {
            'gate-section-citations': (a) async {
              ran.add('gate-section-citations');
              return 0;
            },
          },
        );
        expect(code, 2); // gate-format: manifest not found
        expect(ran, isEmpty);
      },
    );

    for (final failing in [1, 2, 3]) {
      test(
        'exit $failing: the commands before run, the ones after do not',
        () async {
          final ran = <String>[];
          Future<int> Function(List<String>) record(String name, int code) =>
              (a) async {
                ran.add(name);
                return code;
              };
          final (code, _, _) = await _run(
            [':gate-format', ':spec-render', 'doc.yaml', ':gate-release-drift'],
            overrides: {
              'gate-format': record('gate-format', 0),
              'spec-render': record('spec-render', failing),
              'gate-release-drift': record('gate-release-drift', 0),
            },
          );
          expect(code, failing);
          expect(ran, ['gate-format', 'spec-render']);
        },
      );
    }

    test('all clean: every command runs, exit 0', () async {
      final ran = <String>[];
      final (code, _, _) = await _run(
        [':gate-format', ':gate-release-drift'],
        overrides: {
          for (final n in ['gate-format', 'gate-release-drift'])
            n: (a) async {
              ran.add(n);
              return 0;
            },
        },
      );
      expect(code, 0);
      expect(ran, ['gate-format', 'gate-release-drift']);
    });
  });

  group('TS6: usage errors exit 2 on stderr and run nothing', () {
    test('an option the command does not declare', () async {
      final ran = <String>[];
      final (code, out, err) = await _run(
        [':ir-export', '--mapper', 'dart-tom'],
        overrides: {
          'ir-export': (a) async {
            ran.add('ir-export');
            return 0;
          },
        },
      );
      expect(code, 2);
      expect(err, contains('`:ir-export` has no option `--mapper`'));
      expect(out, isEmpty);
      expect(ran, isEmpty);
    });

    test('a value outside the allowed ones, an unknown command', () async {
      final (bad, _, badErr) = await _run([':ir-export', '--format', 'yaml']);
      expect(bad, 2);
      expect(badErr, contains('takes one of json'));
      final (unknown, _, unknownErr) = await _run([':no-such-command']);
      expect(unknown, 2);
      expect(unknownErr, contains('Unknown command'));
    });
  });

  group('TS7: the arguments a command hands its tool', () {
    Future<List<String>> argumentsOf(List<String> args) async {
      List<String>? seen;
      final name = args.first.substring(1);
      final (code, _, err) = await _run(
        args,
        overrides: {
          name: (a) async {
            seen = a;
            return 0;
          },
        },
      );
      expect(code, 0, reason: err);
      return seen!;
    }

    test(
      ':ir-* commands: the IR operation first, then the options and positionals',
      () async {
        expect(
          await argumentsOf([
            ':ir-export',
            '--format',
            'json',
            '--ir',
            'i',
            '--out',
            'o',
          ]),
          ['export', '--out', 'o', '--ir', 'i', '--format', 'json'],
        );
      },
    );

    test(
      ':spec-* checks: --spec-root before the check, its options after',
      () async {
        expect(
          await argumentsOf([
            ':spec-coverage',
            '--tsv',
            't.tsv',
            '--spec-root',
            'r',
            'sample.yaml',
            'doc.yaml',
          ]),
          [
            '--spec-root',
            'r',
            'coverage',
            '--tsv',
            't.tsv',
            'sample.yaml',
            'doc.yaml',
          ],
        );
        expect(
          await argumentsOf([
            ':spec-import-answers',
            '--dry-run',
            'd.yaml',
            'd.md',
          ]),
          ['import-answers', '--dry-run', 'd.yaml', 'd.md'],
        );
      },
    );

    test('a flag, a repeated option, and a value equal to the tool default '
        'left to the tool', () async {
      final args = await argumentsOf([
        ':codespecs-validate',
        '--shared',
        's',
        '--json',
      ]);
      expect(args, containsAllInOrder(['--shared', 's', '--json']));
      expect(args.where((a) => a.startsWith('--no-')), isEmpty);
    });
  });
}
