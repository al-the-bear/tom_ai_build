/// `validate_codespecs` as a tool reads it: the `--json` report, the
/// `--backlinks` index, and the compiled standalone binary.
///
/// The subject is the Phase-4 sample's emitted trio and extracts, which the
/// sample's `tool/validate.sh` already holds clean in text form; a seeded copy
/// with one renamed back-link token supplies the violation case.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

final String _sample = p.normalize(
  p.absolute('../tom_specs_samples/phase4_codespecs_run'),
);

List<String> _trio(String root) => [
  '--shared',
  p.join(root, 'codespec', 'shared'),
  '--client',
  p.join(root, 'codespec', 'client'),
  '--server',
  p.join(root, 'codespec', 'server'),
];

Future<(int, String, String)> _run(List<String> args) async {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = await runValidateCodespecs(args, out: out, err: err);
  return (code, '$out', '$err');
}

/// Whether the sample's extracts are missing, and if so marks the test skipped
/// with the reason. The extracts are the sample's stage-2 output, written by
/// running it (`tom_specs_samples/phase4_codespecs_run`, `dart run`) and not
/// committed (its `.gitignore`): a fresh checkout has none until the sample
/// has run there, and that is the host's state, not the validator's.
bool _extractsMissing(String dir) {
  if (Directory(dir).existsSync()) return false;
  markTestSkipped(
    '$dir does not exist: run the sample first '
    '(cd tom_specs_samples/phase4_codespecs_run && dart run)',
  );
  return true;
}

void main() {
  final extractsDir = p.join(_sample, 'build', 'codespecs_extracts');
  final extracts = ['--extracts', extractsDir];

  group('--json', () {
    test('a clean trio: one versioned document, exit 0', () async {
      if (_extractsMissing(extractsDir)) return;
      final (code, out, err) = await _run([
        ..._trio(_sample),
        ...extracts,
        '--json',
      ]);
      expect(code, 0, reason: err);
      expect(err, isEmpty, reason: 'nothing but the document is written');
      final json = jsonDecode(out) as Map<String, dynamic>;
      expect(json['format'], kCodeSpecsReportFormat);
      expect(json['formatVersion'], kCodeSpecsReportFormatVersion);
      expect(json['passed'], isTrue);
      expect(json['violations'], isEmpty);
      expect((json['checks'] as List).length, 44);
      expect(
        [for (final n in json['notRun'] as List) ...(n['checks'] as List)],
        containsAll([9, 13, 31, 40, 41]),
        reason: 'an unrun check is named, never read as a pass',
      );
    });

    test('a violation carries check, title, file, line, token, area', () async {
      if (_extractsMissing(extractsDir)) return;
      // A copy of the trio whose entity renames one back-link token: check 36
      // reports the stale token at the declaration, check 35 the real token
      // the trio no longer cites, with its area.
      final copy = Directory(p.join('.dart_tool', 'test_tmp', 'vsctsa40'));
      if (copy.existsSync()) copy.deleteSync(recursive: true);
      for (final f in Directory(
        p.join(_sample, 'codespec'),
      ).listSync(recursive: true).whereType<File>()) {
        final rel = p.relative(f.path, from: _sample);
        final target = File(p.join(copy.path, rel))
          ..createSync(recursive: true);
        target.writeAsStringSync(
          f.readAsStringSync().replaceAll("'DAATT-DATA'", "'DAATT-GONE'"),
        );
      }
      final (code, out, _) = await _run([
        ..._trio(copy.path),
        ...extracts,
        '--json',
      ]);
      expect(code, 1);
      final json = jsonDecode(out) as Map<String, dynamic>;
      expect(json['passed'], isFalse);
      final violations = (json['violations'] as List)
          .cast<Map<String, dynamic>>();
      final stale = violations.firstWhere((v) => v['check'] == 36);
      expect(stale['token'], 'DAATT-GONE');
      expect(stale['file'], 'lib/src/data_access/customer.dart');
      expect(stale['line'], isA<int>());
      expect(stale['severity'], 'error');
      expect(stale['checkTitle'], isNotEmpty);
      final uncited = violations.where(
        (v) => v['check'] == 35 && v['token'] == 'DAATT-DATA',
      );
      // One per area that routed the token: CE-DB, and CE-API through the
      // entity wire DTO.
      expect(uncited.map((v) => v['area']), contains('CE-DB'));
    });

    test('the text report is unchanged by the option', () async {
      if (_extractsMissing(extractsDir)) return;
      final (code, out, err) = await _run([..._trio(_sample), ...extracts]);
      expect(code, 0, reason: err);
      expect(out.trim().split('\n').last, 'codespecs: 44 checks passed');
    });
  });

  group('--cs-vocabulary', () {
    final vocabulary = p.normalize(
      p.absolute('../tom_code_specs/lib/src/annotations/vocabulary.dart'),
    );

    test('runs checks 40 and 41 against the hook catalogue', () async {
      if (_extractsMissing(extractsDir)) return;
      final (code, out, err) = await _run([
        ..._trio(_sample),
        ...extracts,
        '--cs-vocabulary',
        vocabulary,
        '--json',
      ]);
      expect(code, 0, reason: err);
      final json = jsonDecode(out) as Map<String, dynamic>;
      expect(json['passed'], isTrue);
      final unrun = [
        for (final n in json['notRun'] as List) ...(n['checks'] as List),
      ];
      expect(unrun, isNot(contains(40)));
      expect(unrun, isNot(contains(41)));
    });

    test('omitted, checks 40 and 41 are announced unrun', () async {
      if (_extractsMissing(extractsDir)) return;
      final (code, out, _) = await _run([..._trio(_sample), ...extracts]);
      expect(code, 0);
      expect(
        out,
        contains(
          'checks 40 and 41 (feature-hook completeness and reserved '
          'protocol paths) not run — pass --cs-vocabulary',
        ),
      );
    });

    test('a source without the catalogue says so', () async {
      final dir = Directory(p.join('.dart_tool', 'test_tmp', 'csvocab_empty'))
        ..createSync(recursive: true);
      File(p.join(dir.path, 'empty.dart')).writeAsStringSync('class A {}\n');
      final (code, out, _) = await _run([
        ..._trio(_sample),
        '--cs-vocabulary',
        dir.path,
      ]);
      expect(code, 0);
      expect(out, contains('declares neither csFeatureHooks'));
    });

    test('an unreadable catalogue row is bad usage, exit 2', () async {
      final dir = Directory(p.join('.dart_tool', 'test_tmp', 'csvocab_bad'))
        ..createSync(recursive: true);
      File(p.join(dir.path, 'vocabulary.dart')).writeAsStringSync('''
const csFeatureHooks = [
  CsFeatureHookSpec(CsProtocolFeature.scim2Server, 'scimStore'),
];
const csFeatureReservedPaths = {};
''');
      final (code, _, err) = await _run([
        ..._trio(_sample),
        '--cs-vocabulary',
        dir.path,
      ]);
      expect(code, 2);
      expect(err, contains('--cs-vocabulary: csFeatureHooks row'));
    });
  });

  group('--backlinks', () {
    test('one row per declaration with its tokens', () async {
      final (code, out, err) = await _run([..._trio(_sample), '--backlinks']);
      expect(code, 0, reason: err);
      final json = jsonDecode(out) as Map<String, dynamic>;
      expect(json['format'], kCodeSpecsBacklinksFormat);
      final rows = (json['declarations'] as List).cast<Map<String, dynamic>>();
      final customer = rows.firstWhere((r) => r['name'] == 'Customer');
      expect(customer['locus'], 'server');
      expect(customer['file'], 'lib/src/data_access/customer.dart');
      expect((customer['codeSpec'] as Map)['id'], 'dataAccess.Customer');
      expect(customer['tokens'], contains('DAENT-IDEN'));
      expect(
        (customer['docSpec'] as List).map((r) => (r as Map)['token']),
        contains('DAENT-IDEN'),
      );
    });
  });

  group('usage', () {
    test('a missing trio member is exit 2, naming it', () async {
      final (code, _, err) = await _run(['--shared', '.']);
      expect(code, 2);
      expect(err, contains('--client, --server'));
    });

    test('--json and --backlinks together are exit 2', () async {
      final (code, _, _) = await _run([
        ..._trio(_sample),
        '--json',
        '--backlinks',
      ]);
      expect(code, 2);
    });
  });

  test(
    'the compiled binary runs standalone over the sample trio',
    () async {
      if (_extractsMissing(extractsDir)) return;
      // `dart compile exe` does not create the output's folder, and a fresh
      // checkout has no `.dart_tool/exe/`; Windows runs only an `.exe`.
      final exeDir = Directory(p.absolute(p.join('.dart_tool', 'exe')))
        ..createSync(recursive: true);
      final exe = p.join(
        exeDir.path,
        Platform.isWindows ? 'validate_codespecs.exe' : 'validate_codespecs',
      );
      final compile = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'exe',
        'bin/validate_codespecs.dart',
        '-o',
        exe,
      ]);
      expect(compile.exitCode, 0, reason: '${compile.stderr}');
      // No Dart on PATH, no package config, a working directory with no
      // project in it: what the extension's bundled copy will meet.
      final run = await Process.run(
        exe,
        [..._trio(_sample), ...extracts, '--json'],
        workingDirectory: Directory.systemTemp.path,
        environment: {'PATH': '/usr/bin:/bin'},
        includeParentEnvironment: false,
      );
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect((jsonDecode('${run.stdout}') as Map)['passed'], isTrue);
      final links = await Process.run(
        exe,
        [..._trio(_sample), '--backlinks'],
        workingDirectory: Directory.systemTemp.path,
        environment: {'PATH': '/usr/bin:/bin'},
        includeParentEnvironment: false,
      );
      expect(links.exitCode, 0, reason: '${links.stderr}');
      expect(
        (jsonDecode('${links.stdout}') as Map)['declarations'],
        isNotEmpty,
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
    testOn: 'mac-os || linux',
  );

  group('--ir (irspecs_ir.md §7)', () {
    final areasJson = p.normalize(
      p.absolute(
        '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
      ),
    );
    final meridian = p.normalize(
      p.absolute('../tom_som_conformance/samples/meridian_codespecs'),
    );
    final trios = {
      'phase4_codespecs_run': [
        for (final l in ['shared', 'client', 'server'])
          p.join(_sample, 'codespec', l),
      ],
      'meridian_codespecs': [
        for (final l in ['shared', 'client', 'server'])
          p.join(meridian, 'meridian_codespec_$l'),
      ],
    };

    List<String> trioArgs(List<String> roots) => [
      '--shared',
      roots[0],
      '--client',
      roots[1],
      '--server',
      roots[2],
    ];

    /// The IR of [roots], written by `irspecs from-codespecs` into a folder of
    /// its own.
    Future<String> irOf(List<String> roots, String name) async {
      final dir = Directory(p.join('.dart_tool', 'test_tmp', 'irspecs5', name));
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      final code = await runIrspecs([
        'from-codespecs',
        ...trioArgs(roots),
        '--areas',
        areasJson,
        '--out',
        dir.path,
      ], out: StringBuffer());
      expect(code, 0);
      return dir.path;
    }

    /// The JSON report without its `inputs`, which name the paths given, and
    /// with each unrun check's reason reduced to the checks it names: the
    /// reason for check 31 names the option that would run it, which is
    /// `--regenerated-ir` for an IR and the three trio options otherwise.
    Map<String, dynamic> verdict(String out) {
      final json = (jsonDecode(out) as Map<String, dynamic>)..remove('inputs');
      if (json['notRun'] case final List<dynamic> notRun) {
        json['notRun'] = [for (final n in notRun) (n as Map)['checks']];
      }
      return json;
    }

    for (final MapEntry(key: name, value: roots) in trios.entries) {
      test('$name: the IR reports what the trio reports', () async {
        final ir = await irOf(roots, name);
        final (trioCode, trioOut, _) = await _run([
          ...trioArgs(roots),
          '--json',
        ]);
        final (irCode, irOut, irErr) = await _run(['--ir', ir, '--json']);
        expect(irCode, trioCode, reason: irErr);
        expect(verdict(irOut), verdict(trioOut));
        expect(irCode, 0);
      });

      test('$name: the back-link index is the same from the IR', () async {
        final ir = await irOf(roots, name);
        final (_, trioOut, _) = await _run([...trioArgs(roots), '--backlinks']);
        final (_, irOut, _) = await _run(['--ir', ir, '--backlinks']);
        expect(verdict(irOut), verdict(trioOut));
      });
    }

    test('phase4: with the extracts too', () async {
      if (_extractsMissing(extractsDir)) return;
      final roots = trios['phase4_codespecs_run']!;
      final ir = await irOf(roots, 'phase4_extracts');
      final (trioCode, trioOut, _) = await _run([
        ...trioArgs(roots),
        ...extracts,
        '--json',
      ]);
      final (irCode, irOut, _) = await _run([
        '--ir',
        ir,
        ...extracts,
        '--json',
      ]);
      expect(irCode, trioCode);
      expect(verdict(irOut), verdict(trioOut));
    });

    test('a violating trio fails the same way through its IR', () async {
      if (_extractsMissing(extractsDir)) return;
      final copy = Directory(p.join('.dart_tool', 'test_tmp', 'irspecs5_seed'));
      if (copy.existsSync()) copy.deleteSync(recursive: true);
      for (final f in Directory(
        p.join(_sample, 'codespec'),
      ).listSync(recursive: true).whereType<File>()) {
        File(p.join(copy.path, p.relative(f.path, from: _sample)))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            f.readAsStringSync().replaceAll("'DAATT-DATA'", "'DAATT-GONE'"),
          );
      }
      final roots = [
        for (final l in ['shared', 'client', 'server'])
          p.join(copy.path, 'codespec', l),
      ];
      final ir = await irOf(roots, 'seeded');
      final (trioCode, trioOut, _) = await _run([
        ...trioArgs(roots),
        ...extracts,
        '--json',
      ]);
      final (irCode, irOut, _) = await _run([
        '--ir',
        ir,
        ...extracts,
        '--json',
      ]);
      expect(trioCode, 1);
      expect(irCode, 1);
      expect(verdict(irOut), verdict(trioOut));
    });

    test('check 31 compares two IR runs record by record', () async {
      final roots = trios['meridian_codespecs']!;
      final ir = await irOf(roots, 'run1');
      final same = await irOf(roots, 'run2');
      final (sameCode, sameOut, _) = await _run([
        '--ir',
        ir,
        '--regenerated-ir',
        same,
        '--json',
      ]);
      expect(sameCode, 0);
      expect(
        (jsonDecode(sameOut)['notRun'] as List).expand(
          (n) => (n as Map)['checks'] as List,
        ),
        isNot(contains(31)),
      );
      // A second run that disagreed on one table name.
      final drifted = File(p.join(same, 'CE-DB.ir.yaml'));
      drifted.writeAsStringSync(
        drifted.readAsStringSync().replaceFirst(
          '"mom_customer"',
          '"mom_customers"',
        ),
      );
      final (code, out, _) = await _run([
        '--ir',
        ir,
        '--regenerated-ir',
        same,
        '--json',
      ]);
      expect(code, 1);
      final violations = (jsonDecode(out)['violations'] as List)
          .cast<Map<String, dynamic>>();
      expect(violations.map((v) => v['check']), [31]);
      expect(violations.single['message'], contains('customer.dart'));
    });

    test('--ir is given instead of the trio, never beside it', () async {
      final ir = await irOf(trios['meridian_codespecs']!, 'usage');
      expect((await _run(['--ir', ir, '--shared', ir])).$1, 2);
      expect((await _run([..._trio(_sample), '--regenerated-ir', ir])).$1, 2);
      expect((await _run(['--ir', ir, '--regenerated-shared', ir])).$1, 2);
      expect((await _run(['--ir', p.join(ir, 'missing')])).$1, 2);
    });
  });
}
