// Tests of the Project Idea coverage (`tom_som_dart_runtime/lib/src/spec_checks/project_idea_coverage.dart`).
//
//   testkit :test --test-args="test/spec_checks/project_idea_coverage_test.dart"
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/spec_checks.dart';

const idea = '''
# Project Idea

### C1 Platform

- **C1.1** Tenants are isolated. (S1)
- **C1.2** A platform tenant
  holds platform administrators. (D-102)
- **C1.3** Tenant states. (D-101)

### C2 Items

- **C2.1** Items are shared. (D-303)
- **C2.2** Shares can be revoked. (D-303)

## 5 Non-functional expectations

| Id  | Expectation | Source |
| --- | ----------- | ------ |
| N-1 | Fast.       | D-22   |

### 6.2 Out of scope

| Item | Reason |
| ---- | ------ |
| Legacy migration | Nothing to migrate (D-188). |

## 7 Constraints

- **C-1 Framework.** tom_core.
- **C-2 Archive.** Tagged. (D-301)

## 11 Decision log

| Id    | Topic | Decision |
| ----- | ----- | -------- |
| D-22  | Speed | 200 ms. |
| D-101 | States | Four states. |
| D-102 | Platform | Reserved tenant. |
| D-188 | Migration | Seed data only. |
| D-256 | Archive | After Phase 4. |
| D-301 | Archive timing | Now (supersedes the timing of D-256). |
| D-303 | Items | Item authorization. |
| D-310 | Sessions | 24 h. Answers Blueprint question BQ-27. |
''';

String blueprint(String source) =>
    '''
version: 2
document:
  SBP D00SolutionBlueprint:
    INSC introductionAndScope:
      RO requirements:
        FR functional:
          FRE-REQU-LST requirements:
            FRE-REQU-TENANTS:
              FRES source:
                source: |2-
                  $source
            FRE-REQU-ITEMS:
              FRES source:
                source: |2-
                  Project Idea C2, D-303
        TR1 technical:
          TERQ-REQU-LST requirements:
            TERQ-REQU-SPEED:
              TRED details:
                source: |2-
                  Project Idea N-1, C-1
''';

Map<CoverageClass, List<String>> classes(ProjectIdeaCoverageReport r) => {
  for (final c in CoverageClass.values) c: [for (final e in r.of(c)) e.item.id],
};

void main() {
  test('PIC-1: the Project Idea ids are read in their four shapes', () {
    final p = parseProjectIdea(idea);
    expect(p.items.map((i) => i.id), [
      'C1.1', 'C1.2', 'C1.3', 'C2.1', 'C2.2', 'N-1', 'C-1', 'C-2', 'D-22',
      'D-101', 'D-102', 'D-188', 'D-256', 'D-301', 'D-303', 'D-310', //
    ]);
    expect(p['C1.2']!.text, contains('holds platform administrators'));
    expect(p['C1.2']!.area, 'C1');
    expect(p.outOfScopeText, contains('D-188'));
  });

  test('PIC-2: citations expand ranges and keep whole areas', () {
    expect(
      citations('Project Idea C1.1–C1.3, D-136–D-138, C-1–C-2, C18, BQ-7'),
      {
        'C1.1',
        'C1.2',
        'C1.3',
        'D-136',
        'D-137',
        'D-138',
        'C-1',
        'C-2',
        'C18',
        'BQ-7',
      },
    );
    expect(citations('D-01–D-03'), {'D-01', 'D-02', 'D-03'});
    expect(citations('RC-196, UC18, PRANTR-PREC-UC18'), isEmpty);
  });

  test(
    'PIC-3: the requirements of the four lists and their sources are read',
    () {
      final s = requirementSources(blueprint('Project Idea C1.1'));
      expect(s.keys, ['FRE-REQU-TENANTS', 'FRE-REQU-ITEMS', 'TERQ-REQU-SPEED']);
      expect(s['TERQ-REQU-SPEED'], contains('N-1'));
    },
  );

  test('PIC-4: each id ends in the first class that applies', () {
    final r = measureProjectIdeaCoverage(
      parseProjectIdea(idea),
      requirementSources(blueprint('Project Idea C1.1, C1.2, BQ-27')),
      exclusions: [CoverageExclusion('C-2', 'not in the Blueprint', 'D-301')],
    );
    final c = classes(r);
    expect(c[CoverageClass.covered], ['C1.1', 'C1.2', 'N-1', 'C-1', 'D-303']);
    expect(c[CoverageClass.area], ['C2.1', 'C2.2']);
    // D-22 is carried by N-1, D-102 by C1.2, D-310 answers BQ-27.
    expect(c[CoverageClass.via], ['D-22', 'D-102', 'D-310']);
    // C-2 by the list, D-188 by the out-of-scope table, D-256 superseded by D-301.
    expect(c[CoverageClass.excluded], ['C-2', 'D-188', 'D-256']);
    expect(c[CoverageClass.uncovered], ['C1.3', 'D-101', 'D-301']);
    expect(r.unknownExclusions, isEmpty);
  });

  test(
    'PIC-5: an exclusion naming an id the Project Idea lacks is reported',
    () {
      final r = measureProjectIdeaCoverage(
        parseProjectIdea(idea),
        {},
        exclusions: [CoverageExclusion('C9.9', 'x', 'y')],
      );
      expect(r.unknownExclusions, ['C9.9']);
    },
  );
}
