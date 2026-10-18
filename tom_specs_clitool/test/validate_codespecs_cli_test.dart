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

void main() {
  final extracts = [
    '--extracts',
    p.join(_sample, 'build', 'codespecs_extracts'),
  ];

  group('--json', () {
    test('a clean trio: one versioned document, exit 0', () async {
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
      expect((json['checks'] as List).length, 41);
      expect(
        [for (final n in json['notRun'] as List) ...(n['checks'] as List)],
        containsAll([9, 13, 31, 40, 41]),
        reason: 'an unrun check is named, never read as a pass',
      );
    });

    test('a violation carries check, title, file, line, token, area', () async {
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
      final (code, out, err) = await _run([..._trio(_sample), ...extracts]);
      expect(code, 0, reason: err);
      expect(out.trim().split('\n').last, 'codespecs: 41 checks passed');
    });
  });

  group('--cs-vocabulary', () {
    final vocabulary = p.normalize(
      p.absolute('../tom_code_specs/lib/src/annotations/vocabulary.dart'),
    );

    test('runs checks 40 and 41 against the hook catalogue', () async {
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
      final exe = p.absolute(p.join('.dart_tool', 'exe', 'validate_codespecs'));
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
}
