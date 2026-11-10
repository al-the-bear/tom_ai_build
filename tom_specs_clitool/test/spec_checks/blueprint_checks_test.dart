// Tests of the Blueprint checks: the authorization cross-check, the coverage
// measurement and the question-register check.
//
// The groups on the real Blueprint read tom_uam's from the workspace (and skip
// when it, or its check data in `<spec-root>/checks/`, is absent). The
// coverage group on the real model reads the ai_build checkout named by
// AI_BUILD (default: this repository).
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/spec_checks.dart';

const _dir = '$_ws/tom_uam/tom_specs/phase2_solution_blueprint';
const _checks = '$_ws/tom_uam/tom_specs/checks';

/// The workspace root, from the package folder `dart test` runs in
/// (tom_ai/ai_build/tom_specs_clitool).
const _ws = '../../..';

final _blueprint = File('$_dir/tom_uam.sbp.docspecs.yaml');

/// Whether tom_uam's real data is here: the Blueprint and its `checks/`
/// folder. A checkout of tom_uam from before its check data moved to
/// `checks/` has the one without the other; that is the host's state, so the
/// real-data tests skip there as they do when tom_uam is absent.
final bool _hasRealData =
    _blueprint.existsSync() && Directory(_checks).existsSync();

/// The skip reason when [_hasRealData] is false.
const String _noRealData =
    "tom_uam's Blueprint or its tom_specs/checks/ is not in this checkout "
    '(run from the workspace root, on a current tom_uam)';

String _read(String path) => File(path).readAsStringSync();

/// tom_uam's question-index conventions, as its `checks/question_register.yaml`
/// states them; the BCK-3 fixtures are written in them.
final _register = QuestionRegisterConfig.parse('''
prefixes: [BQ, PR]
groups:
  - {key: first, label: "BQ-01 to BQ-77", prefix: BQ, to: 77}
  - {key: doc, label: "BQ-78 to BQ-{max}", prefix: BQ, from: 78}
  - {key: pr, label: "PR-01 to PR-10", prefix: PR}
statuses:
  - {key: open, label: open, waiting: true}
  - {key: implemented, label: implemented on WA, waiting: true}
  - {key: answered, label: answered}
  - {key: obsolete, label: obsolete}
  - {key: duplicate, label: duplicate}
''');

/// Replaces [from] once in [text], failing the test when it is not there once.
String _once(String text, String from, String to) {
  expect(from.allMatches(text).length, 1, reason: 'expected once: $from');
  return text.replaceFirst(from, to);
}

void main() {
  group('BCK-1: authorization cross-check', () {
    late String yaml;
    late String config;
    setUpAll(() {
      if (!_hasRealData) return;
      yaml = _blueprint.readAsStringSync();
      config = _read('$_checks/authorization_cross_check.yaml');
    });

    test('BCK-1.1: the Blueprint has no finding', () {
      if (!_hasRealData) {
        return markTestSkipped(_noRealData);
      }
      final r = crossCheckAuthorization(yaml, config);
      expect(r.findings.values.expand((l) => l), isEmpty);
      expect(r.operations, greaterThan(150));
      expect(r.screens, greaterThan(40));
    });

    test('BCK-1.2: a screen missing from "Called by" is reported (F)', () {
      if (!_hasRealData) {
        return markTestSkipped(_noRealData);
      }
      final broken = _once(
        yaml,
        '- **Called by:** UC-29, UC-30; screens `PRESETS`, `APPLICATION-DETAIL`',
        '- **Called by:** UC-29, UC-30; screens `PRESETS`',
      );
      final r = crossCheckAuthorization(broken, config);
      expect(
        r.findings['F called by'],
        contains(
          'updatePreset: screen APPLICATION-DETAIL calls it, "Called by" lacks it',
        ),
      );
    });

    test('BCK-1.5: text struck out by a review mark does not count (F)', () {
      if (!_hasRealData) {
        return markTestSkipped(_noRealData);
      }
      // A screen named only in the deleted part of a mark is not named; one in
      // the inserted or new part is.
      final marked = _once(
        yaml,
        '- **Called by:** UC-29, UC-30; screens `PRESETS`, `APPLICATION-DETAIL`',
        '- **Called by:** UC-29, UC-30; screens {~~`ROLES-GRANTS`~>`PRESETS`~~}'
            '{--, `AUDIT`--}{++, `APPLICATION-DETAIL`++}',
      );
      final r = crossCheckAuthorization(marked, config);
      expect(
        r.findings['F called by']!.where((f) => f.startsWith('updatePreset')),
        isEmpty,
      );
      final broken = _once(
        yaml,
        '- **Called by:** UC-29, UC-30; screens `PRESETS`, `APPLICATION-DETAIL`',
        '- **Called by:** UC-29, UC-30; screens `PRESETS`{--, `APPLICATION-DETAIL`--}',
      );
      expect(
        crossCheckAuthorization(broken, config).findings['F called by'],
        contains(
          'updatePreset: screen APPLICATION-DETAIL calls it, "Called by" lacks it',
        ),
      );
    });

    test(
      'BCK-1.3: a handler missing from the handler table is reported (A)',
      () {
        if (!_hasRealData) {
          return markTestSkipped(_noRealData);
        }
        final r = crossCheckAuthorization(
          yaml,
          config.replaceFirst('  testSupportCaller: [tester]\n', ''),
        );
        // Without its roles the handler's operations reach no role.
        expect(
          r.findings['A operations reachable']!.any(
            (f) => f.contains('no role reaches it'),
          ),
          isTrue,
        );
      },
    );

    test(
      'BCK-1.4: an action whose operation the screen cannot reach is reported (B)',
      () {
        if (!_hasRealData) {
          return markTestSkipped(_noRealData);
        }
        // setUpInstallation is reachable by the operations role only, which the
        // application screen does not admit.
        final broken = _once(
          yaml,
          'Makes one of the application\'s presets its guest preset through\n'
              '                          `updatePreset`',
          'Makes one of the application\'s presets its guest preset through\n'
              '                          `setUpInstallation`',
        );
        final r = crossCheckAuthorization(broken, config);
        expect(
          r.findings['B screen actions']!.single,
          startsWith('APPLICATION-DETAIL SCRAC-ITEM-GUEST: setUpInstallation'),
        );
      },
    );

    test('BCK-1.6: a key covers its sub-keys, not its parent (FR-26)', () {
      final model = RoleModel.parse(
        '''
platformOnlyKeys: []
roleKeys:
  parent-holder: [uam.users]
  child-holder: [uam.users.read]
handlerRoles: {}
actorRoles: {}
otherActorOperations: []
pendingQuestions: []
''',
        {'uam.users', 'uam.users.read'},
      );
      Access needs(String key) => Access('entitlement', [key], const [], '');
      expect(model.reach(needs('uam.users.read')), {
        'parent-holder',
        'child-holder',
      });
      expect(model.reach(needs('uam.users')), {'parent-holder'});
      // A key sharing a prefix but not the dotted path is not covered.
      expect(model.reach(needs('uam.usersx')), isEmpty);
    });
  });

  group('BCK-2: coverage measurement', () {
    const rows = '''
rows:
  - id: "A"
    label: "`A` part"
    prefixes: ["partA"]
''';
    const reasons = '''
rules:
  - pattern: "SEC2\$"
    class: "NA"
    reason: "nothing to say"
''';
    const sample = '''
document:
  X Root:
    PA partA:
      SEC1 first:
        field: x
      SEC2 second:
        field: x
      SEC3 third:
        field: x
      SEC4-LST items:
        SEC4:
          SEC5 inner:
            field: x
''';
    const meta = '{"classes": {}}';

    test('BCK-2.1: counts filled sections and classifies the empty ones', () {
      const blueprint = '''
document:
  X Root:
    PA partA:
      SEC1 first:
        field: written
      SEC2 second:
      SEC4-LST items:
        SEC4-A:
          SEC5 inner:
            field: written
''';
      final r = measureCoverage(
        sampleYaml: sample,
        metaJson: meta,
        blueprintYaml: blueprint,
        rowsYaml: rows,
        reasonsYaml: reasons,
      );
      // partA, first, second, third, items, inner: six block sections.
      expect(r.model['A'], 6);
      // partA, first, items and inner carry text; second is empty, third absent.
      expect(r.filled['A'], 4);
      final byPath = {for (final u in r.unfilled) u.fieldPath: u};
      expect(byPath['partA/second']!.cls, 'NA');
      expect(byPath['partA/second']!.state, 'present-empty');
      expect(byPath['partA/third']!.cls, 'U');
      expect(byPath['partA/third']!.state, 'absent');
      expect(r.eligible('A'), 6);
      expect(r.renderTsv().split('\n').first, startsWith('path\trow\tclass'));
    });

    test('BCK-2.3: a list item is named by its class id in the id path', () {
      const numberedSample = '''
document:
  X Root:
    PA partA:
      SEC4-ITEM-LST items:
        SEC4-ITEM-1:
          SEC5 inner:
            field: x
''';
      const rule = '''
rules:
  - pattern: "SEC4-ITEM-LST > SEC4 > SEC5\$"
    class: "NA"
    reason: "matched through the class id"
''';
      final r = measureCoverage(
        sampleYaml: numberedSample,
        metaJson: meta,
        blueprintYaml: 'document:\n  X Root:\n    PA partA:\n      field: x\n',
        rowsYaml: rows,
        reasonsYaml: rule,
      );
      final inner = r.unfilled.singleWhere(
        (u) => u.fieldPath == 'partA/items/inner',
      );
      expect(inner.idPath, 'PA > SEC4-ITEM-LST > SEC4 > SEC5');
      expect(inner.cls, 'NA');
    });

    test('BCK-2.2: the real Blueprint against the real model', () {
      final ab = Platform.environment['AI_BUILD'] ?? '..';
      final s = File(
        '$ab/tom_som_conformance/samples/exercise_full_model.docspecs.yaml',
      );
      final m = File('$ab/tom_som_dart_v0/meta/spec_model.meta.json');
      if (!_hasRealData || !s.existsSync() || !m.existsSync()) {
        return markTestSkipped(
          'needs the workspace root and an ai_build checkout',
        );
      }
      final r = measureCoverage(
        sampleYaml: s.readAsStringSync(),
        metaJson: m.readAsStringSync(),
        blueprintYaml: _blueprint.readAsStringSync(),
        rowsYaml: _read('$_checks/coverage_rows.yaml'),
        reasonsYaml: _read('$_checks/coverage_reasons.yaml'),
      );
      expect(r.rows, hasLength(22));
      // Every model section is either filled or listed as empty.
      expect(r.total(r.filled) + r.unfilled.length, r.total(r.model));
    });
  });

  group('BCK-3: question register', () {
    const blueprint = '''
            > **❓ BQ-80 — A topic:** what?
            > **Answer:**
            > **❓ BQ-81 — Another topic:** what, on a question text that is
            > long enough to wrap onto the next line?
            > **Answer:** b
''';
    String clar({
      String row81 = '| BQ-81 | ★ | `X` | Other. | open |  |',
      String counts = '| open | 0 | 2 | 0 | 2 | 1 |',
    }) =>
        '''
- **BQ-01 to BQ-81** are questions.

| Status | BQ-01 to BQ-77 | BQ-78 to BQ-81 | PR-01 to PR-10 | All | ★ |
|--------|------:|------:|------:|----:|--:|
$counts
| implemented on WA | 0 | 0 | 0 | 0 | 0 |
| answered | 0 | 0 | 0 | 0 | — |
| obsolete | 0 | 0 | 0 | 0 | — |
| duplicate | 0 | 0 | 0 | 0 | — |
| **all** | **0** | **2** | **0** | **2** | **1** |

2 questions and proposals wait for an answer, 1 of them marked ★;
2 blocks are in the Blueprint (pointer blocks of merged questions
included).

## Index

| BQ-80 |  | `X` | Topic. | open |  |
$row81

## Not in the Blueprint

| Id | Status | Reason |
|----|--------|--------|

## Toolchain findings
''';

    test('BCK-3.1: a consistent index has no finding; a wrapped question text '
        'counts', () {
      final r = checkQuestionRegister(blueprint, clar(), config: _register);
      expect(r.findings, isEmpty);
      expect(r.blocks, 2);
      expect(r.answeredNotApplied, ['BQ-81 (line 3)']);
    });

    test('BCK-3.2: a malformed row and a block without a row are reported', () {
      final r = checkQuestionRegister(
        blueprint,
        clar(row81: '| BQ-81 | ★ | `X` | Other. | open || note |'),
        config: _register,
      );
      expect(
        r.findings.any((f) => f.startsWith('malformed index row')),
        isTrue,
      );
      expect(
        r.findings,
        contains('BQ-81: block in the Blueprint, no index row'),
      );
    });

    test('BCK-3.3: an answered row whose block remains is reported', () {
      final r = checkQuestionRegister(
        blueprint,
        clar(row81: '| BQ-81 | ★ | `X` | Other. | answered | done |'),
        config: _register,
      );
      expect(
        r.findings.any(
          (f) => f.contains('its block is still in the Blueprint'),
        ),
        isTrue,
      );
    });

    test('BCK-3.4: stale counts are reported and rewritten', () {
      final stale = clar(counts: '| open | 0 | 5 | 0 | 5 | 1 |');
      final r = checkQuestionRegister(blueprint, stale, config: _register);
      expect(r.findings.single, startsWith('the status counts'));
      expect(r.rewritten, contains('| open | 0 | 2 | 0 | 2 | 1 |'));
      expect(
        checkQuestionRegister(
          blueprint,
          r.rewritten,
          config: _register,
        ).findings,
        isEmpty,
      );
    });

    test('BCK-3.6: a header wrapped before its `:**` is a finding', () {
      // The header must close on its first line (SOM §11.9.2); the runtime
      // does not read a wrapped one as a question, so the check says so
      // rather than counting one block less.
      final wrapped = blueprint.replaceFirst(
        'Another topic:** what, on a question text that is',
        'Another topic that is long enough to wrap onto the',
      );
      final r = checkQuestionRegister(wrapped, clar(), config: _register);
      expect(
        r.findings.any((f) => f.startsWith('malformed question block')),
        isTrue,
      );
      expect(r.blocks, 1);
    });

    test('BCK-3.5: the real index agrees with the real Blueprint', () {
      final clarFile = File('$_dir/clarifications.sbp.md');
      if (!_hasRealData || !clarFile.existsSync()) {
        return markTestSkipped(_noRealData);
      }
      final r = checkQuestionRegister(
        _blueprint.readAsStringSync(),
        clarFile.readAsStringSync(),
        config: QuestionRegisterConfig.parse(
          _read('$_checks/question_register.yaml'),
        ),
      );
      expect(r.findings, isEmpty);
    });
  });

  group('BCK-4: required fields', () {
    const meta = '''
{"classes": {
  "Root": {"fields": [
    {"name": "part", "kind": "complex", "type": "Part"}
  ]},
  "Part": {"fields": [
    {"name": "content", "kind": "form", "formFields": [
      {"name": "title", "type": "string", "required": true},
      {"name": "count", "type": "int"},
      {"name": "level", "type": "string", "enumValues": ["low", "high"]}
    ]},
    {"name": "items", "kind": "list", "elementIsComplex": true, "elementType": "Part"}
  ]}
}}''';

    test('BCK-4.1: a missing required field and wrong types are reported', () {
      const yaml = '''
document:
  X Root:
    P part:
      content:
        count: many
        level: medium
      P-LST items:
        P-1:
          content:
            title: An item
''';
      final r = checkRequiredFields(yaml, meta, rootClass: 'Root');
      expect(r.forms, 2);
      expect(r.missing, ['SBP/part/content: title']);
      expect(r.badTypes, hasLength(2));
    });

    test('BCK-4.2: the real Blueprint holds every required field', () {
      final ab = Platform.environment['AI_BUILD'] ?? '..';
      final m = File('$ab/tom_som_dart_v0/meta/spec_model.meta.json');
      if (!_hasRealData || !m.existsSync()) {
        return markTestSkipped(
          'needs the workspace root and an ai_build checkout',
        );
      }
      final r = checkRequiredFields(
        _blueprint.readAsStringSync(),
        m.readAsStringSync(),
      );
      expect(r.forms, greaterThan(20000));
      expect(r.missing, isEmpty);
      expect(r.badTypes, isEmpty);
    });
  });
}
