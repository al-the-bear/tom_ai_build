import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

// ---------------------------------------------------------------------------
// Helpers for synthetic model construction
// ---------------------------------------------------------------------------

ModelClass _cls(
  String name,
  List<AnnotationData> annotations, [
  List<ModelField> fields = const [],
]) =>
    ModelClass(name: name, annotations: annotations, fields: fields);

ModelField _field(String name, String typeName, [List<AnnotationData> annotations = const []]) =>
    ModelField(name: name, typeName: typeName, annotations: annotations);

ModelField _listField(
  String name,
  String elementTypeName, [
  List<AnnotationData> annotations = const [],
]) =>
    ModelField(
      name: name,
      typeName: 'List<$elementTypeName>',
      isList: true,
      listElementTypeName: elementTypeName,
      listElementIsComplex: true,
      annotations: annotations,
    );

// ---------------------------------------------------------------------------
// End-to-end tests against the real tom_specs_model package
// ---------------------------------------------------------------------------

void main() {
  // tom_specs_model lives next to tom_specs_clitool in the same parent folder.
  // Directory.current == package root when running `dart test`.
  final modelPath = p.normalize(
    p.join(Directory.current.path, '..', 'tom_specs_model'),
  );

  group('end-to-end: real tom_specs_model §8.6 structural invariants', () {
    late Map<String, ModelClass> classes;

    setUpAll(() async {
      final driver = createAnalysisDriver(modelPath);
      final reader = ModelReader(driver);
      await reader.analyzePackage(p.join(modelPath, 'lib'));
      classes = reader.classes;
    });

    test('§8.6: no duplicate @SectionId strings across D00SolutionBlueprint tree', () {
      final result = validateStructuralInvariants(classes);
      final dupeErrors = result.errors
          .where((e) => e.contains('§8.6 @SectionId uniqueness'))
          .toList();
      expect(dupeErrors, isEmpty, reason: dupeErrors.join('\n'));
    });

    test(
      '§8.6: every reachable class has @SectionId (or is @SectionIdPattern-covered)',
      () {
        final result = validateStructuralInvariants(classes);
        final coverageWarnings = result.warnings
            .where((w) => w.contains('§8.6 @SectionId coverage'))
            .toList();
        // ~1082 coverage gaps remain across multiple SBP files after CS-02.
        // Bulk: technical_framework.dart (~929), user_interface_design.dart (~199),
        // system_overview.dart (~180), system_stage_plan.dart (~131), and others.
        // See completion_steps.tom_specs.md.
        expect(coverageWarnings, isEmpty, reason: coverageWarnings.join('\n'));
      },
    );

    test('§8.6: no duplicate @SectionIdPattern strings', () {
      final result = validateStructuralInvariants(classes);
      final patternErrors = result.errors
          .where((e) => e.contains('§8.6 @SectionIdPattern uniqueness'))
          .toList();
      expect(patternErrors, isEmpty, reason: patternErrors.join('\n'));
    });

    test('§8.6: every @DetailedIn(D) class has @MapsTo(D) on itself or an ancestor', () {
      final result = validateStructuralInvariants(classes);
      final ancestorErrors = result.errors
          .where((e) => e.contains('§8.6 @DetailedIn ancestor check'))
          .toList();
      expect(ancestorErrors, isEmpty, reason: ancestorErrors.join('\n'));
    });

    test('§8.6: @SecondLevelSectionId implies @DetailedIn on the same class', () {
      final result = validateStructuralInvariants(classes);
      final secondLevelErrors = result.errors
          .where((e) => e.contains('§8.6 @SecondLevelSectionId implies'))
          .toList();
      expect(secondLevelErrors, isEmpty, reason: secondLevelErrors.join('\n'));
    });

    test('§8.6: every @Document class has at least one @DetailedIn entry in SBP tree', () {
      final result = validateStructuralInvariants(classes);
      final detailCountWarnings = result.warnings
          .where((w) => w.contains('§8.6 detail-count'))
          .toList();
      expect(detailCountWarnings, isEmpty, reason: detailCountWarnings.join('\n'));
    });

    test(
      '§8.6: no reachable complex List<T> field lacks @SectionIdPattern '
      '(excluding @Reference)',
      () {
        final result = validateStructuralInvariants(classes);
        final listCoverageErrors = result.errors
            .where((e) => e.contains('§8.6 @SectionIdPattern list-coverage'))
            .toList();
        // Authoritative analyzer-based guard replacing missing_pattern_scan.py
        // (section_id_pattern_plan O6.1). Every repeated section (complex
        // List<T> field that is not @Reference) must carry a numbering pattern.
        expect(listCoverageErrors, isEmpty, reason: listCoverageErrors.join('\n'));
      },
    );

    test(
      '§8.6: list container IDs are per-class unique and pattern-paired '
      '(field-suffix scheme)',
      () {
        final result = validateStructuralInvariants(classes);
        final lstErrors = result.errors
            .where((e) =>
                e.contains('§8.6 @SectionId per-class uniqueness') ||
                e.contains('§8.6 @SectionId consistency') ||
                e.contains('§8.6 @SectionId/@SectionIdPattern pairing'))
            .toList();
        // Every list field carries `<E>-<FIELDSUFFIX>-LST` + matching pattern;
        // the field-name suffix makes sibling container IDs distinct, so the
        // same-class same-type collisions (e.g. in/out-of-scope processes) are
        // resolved. See field_suffix_list_id_plan.md.
        expect(lstErrors, isEmpty, reason: lstErrors.join('\n'));
      },
    );

    test('outliner validates IntegrationInterfaceSpecification root without errors', () {
      // IIS is a smoke-test root known to be clean of §6.1 ContentType issues.
      final result = validateModel(classes, 'D07IntegrationInterfaceSpecification');
      expect(result.errors, isEmpty, reason: result.errors.join('\n'));
    });

    test('T1: the canonical container is DocSpecsProject', () {
      expect(findContainerRoot(classes), 'DocSpecsProject');
    });

    test('T1: model JSON export surfaces the container as the tree root', () {
      final json = ModelJsonExporter(classes).export();
      expect(json['containerRoot'], 'DocSpecsProject');
      // The container is the tree root, not a navigator document.
      final roots = (json['roots'] as List).cast<Map>();
      expect(roots.any((r) => r['type'] == 'DocSpecsProject'), isFalse);
      // It is still present in the class graph the editor walks.
      expect((json['classes'] as Map).containsKey('DocSpecsProject'), isTrue);
    });

    test('T2: every projection root is a pure projection of the SBP tree', () {
      final result = validateStructuralInvariants(classes);
      final pureProjectionErrors = result.errors
          .where((e) => e.contains('§8.6 pure-projection'))
          .toList();
      // Each Phase 3 root aggregates Solution Blueprint sections only — no
      // projection-local content without a blueprint counterpart (N12).
      expect(pureProjectionErrors, isEmpty,
          reason: pureProjectionErrors.join('\n'));
    });
  });

  // ---------------------------------------------------------------------------
  // Unit tests with small synthetic models
  // ---------------------------------------------------------------------------

  group('unit: @SectionId uniqueness check', () {
    test('detects duplicate @SectionId across two sibling classes', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [
            _field('alpha', 'Alpha'),
            _field('beta', 'Beta'),
          ],
        ),
        'Alpha': _cls('Alpha', [AnnotationData('SectionId', {'id': 'TST-DUP'})]),
        'Beta': _cls('Beta', [AnnotationData('SectionId', {'id': 'TST-DUP'})]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any((e) => e.contains('§8.6 @SectionId uniqueness')),
        isTrue,
        reason: 'Expected a uniqueness error for "TST-DUP"',
      );
    });

    test('passes when all @SectionIds are distinct', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [
            _field('alpha', 'Alpha'),
            _field('beta', 'Beta'),
          ],
        ),
        'Alpha': _cls('Alpha', [AnnotationData('SectionId', {'id': 'TST-AAA'})]),
        'Beta': _cls('Beta', [AnnotationData('SectionId', {'id': 'TST-BBB'})]),
      };
      final result = validateStructuralInvariants(classes);
      final dupeErrors = result.errors.where((e) => e.contains('uniqueness')).toList();
      expect(dupeErrors, isEmpty);
    });

    test('detects a duplicate @SectionId on a single class', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('alpha', 'Alpha')],
        ),
        // Two class-level @SectionId annotations on one class (same id) —
        // mirrors the IDAUT/SCRDZ source-hygiene defect. `getAnnotation`
        // collapses these, so without the single-occurrence rule the
        // global-uniqueness check would not catch it.
        'Alpha': _cls('Alpha', [
          AnnotationData('SectionId', {'id': 'TST-DUP'}),
          AnnotationData('SectionId', {'id': 'TST-DUP'}),
        ]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any(
          (e) =>
              e.contains('§8.6 @SectionId single-occurrence') &&
              e.contains('Alpha'),
        ),
        isTrue,
        reason: 'Expected a single-occurrence error for class Alpha',
      );
    });

    test('passes when each class carries exactly one @SectionId', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('alpha', 'Alpha')],
        ),
        'Alpha': _cls('Alpha', [AnnotationData('SectionId', {'id': 'TST-AAA'})]),
      };
      final result = validateStructuralInvariants(classes);
      final singleOccErrors = result.errors
          .where((e) => e.contains('§8.6 @SectionId single-occurrence'))
          .toList();
      expect(singleOccErrors, isEmpty, reason: singleOccErrors.join('\n'));
    });
  });

  group('unit: @SectionId coverage check', () {
    test('warns when a reachable class has no @SectionId and no @SectionIdPattern coverage', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('noId', 'NoId')],
        ),
        'NoId': _cls('NoId', []), // deliberately missing @SectionId
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.warnings.any((w) => w.contains('§8.6 @SectionId coverage') && w.contains('NoId')),
        isTrue,
        reason: 'Expected a coverage warning for class NoId',
      );
    });

    test('does not warn for list-element types covered by @SectionIdPattern', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('container', 'Container')],
        ),
        'Container': _cls(
          'Container',
          [AnnotationData('SectionId', {'id': 'TST-CON'})],
          [
            _listField('items', 'ListItem', [
              AnnotationData('SectionIdPattern', {'pattern': 'TST-CON-xx'}),
            ]),
          ],
        ),
        'ListItem': _cls('ListItem', []), // exempt — covered by @SectionIdPattern
      };
      final result = validateStructuralInvariants(classes);
      final coverageWarnings = result.warnings
          .where((w) => w.contains('§8.6 @SectionId coverage'))
          .toList();
      expect(coverageWarnings, isEmpty);
    });
  });

  group('unit: @SectionIdPattern list-coverage check', () {
    test('errors when a complex List<T> field lacks @SectionIdPattern', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('container', 'Container')],
        ),
        'Container': _cls(
          'Container',
          [AnnotationData('SectionId', {'id': 'TST-CON'})],
          [
            // List field with NO @SectionIdPattern and no @Reference.
            _listField('items', 'ListItem'),
          ],
        ),
        'ListItem': _cls('ListItem', [AnnotationData('SectionId', {'id': 'TST-ITM'})]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any((e) =>
            e.contains('§8.6 @SectionIdPattern list-coverage') &&
            e.contains('Container.items')),
        isTrue,
        reason: 'Expected a list-coverage error for Container.items',
      );
    });

    test('passes when the complex List<T> field carries @SectionIdPattern', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('container', 'Container')],
        ),
        'Container': _cls(
          'Container',
          [AnnotationData('SectionId', {'id': 'TST-CON'})],
          [
            _listField('items', 'ListItem', [
              AnnotationData('SectionId', {'id': 'ITM-LST'}),
              AnnotationData('SectionIdPattern', {'pattern': 'ITM-xxx'}),
            ]),
          ],
        ),
        'ListItem': _cls('ListItem', [AnnotationData('SectionId', {'id': 'ITM'})]),
      };
      final result = validateStructuralInvariants(classes);
      final listCoverageErrors = result.errors
          .where((e) => e.contains('§8.6 @SectionIdPattern list-coverage'))
          .toList();
      expect(listCoverageErrors, isEmpty);
    });

    test('does not error for a @Reference list field without @SectionIdPattern', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('container', 'Container')],
        ),
        'Container': _cls(
          'Container',
          [AnnotationData('SectionId', {'id': 'TST-CON'})],
          [
            // @Reference list fields point at sections owned elsewhere —
            // they are exempt from the list-coverage requirement.
            _listField('refs', 'ListItem', [
              AnnotationData('Reference', {'label': 'Referenced Items'}),
            ]),
          ],
        ),
        'ListItem': _cls('ListItem', [AnnotationData('SectionId', {'id': 'ITM'})]),
      };
      final result = validateStructuralInvariants(classes);
      final listCoverageErrors = result.errors
          .where((e) => e.contains('§8.6 @SectionIdPattern list-coverage'))
          .toList();
      expect(listCoverageErrors, isEmpty);
    });
  });

  group('unit: list container-ID (-LST) checks', () {
    // Two sibling list fields of the same element type in one class, with the
    // field-name suffix distinguishing their container IDs — the valid case.
    Map<String, ModelClass> twoSiblingLists({
      required String idA,
      required String patA,
      required String idB,
      required String patB,
    }) =>
        {
          'D00SolutionBlueprint': _cls(
            'D00SolutionBlueprint',
            [AnnotationData('SectionId', {'id': 'TST'})],
            [_field('scope', 'Scope')],
          ),
          'Scope': _cls(
            'Scope',
            [AnnotationData('SectionId', {'id': 'TST-SCO'})],
            [
              _listField('inItems', 'Item', [
                AnnotationData('SectionId', {'id': idA}),
                AnnotationData('SectionIdPattern', {'pattern': patA}),
              ]),
              _listField('outItems', 'Item', [
                AnnotationData('SectionId', {'id': idB}),
                AnnotationData('SectionIdPattern', {'pattern': patB}),
              ]),
            ],
          ),
          'Item': _cls('Item', [AnnotationData('SectionId', {'id': 'ITM'})]),
        };

    test('passes when sibling lists carry distinct field-suffixed container IDs', () {
      final result = validateStructuralInvariants(twoSiblingLists(
        idA: 'ITM-INITEMS-LST',
        patA: 'ITM-INITEMS-xxx',
        idB: 'ITM-OUTITEMS-LST',
        patB: 'ITM-OUTITEMS-xxx',
      ));
      final lstErrors = result.errors
          .where((e) => e.contains('§8.6 @SectionId'))
          .toList();
      expect(lstErrors, isEmpty, reason: lstErrors.join('\n'));
    });

    test('errors when two sibling lists share a container ID (per-class uniqueness)', () {
      final result = validateStructuralInvariants(twoSiblingLists(
        idA: 'ITM-LST',
        patA: 'ITM-xxx',
        idB: 'ITM-LST',
        patB: 'ITM-xxx',
      ));
      expect(
        result.errors.any((e) =>
            e.contains('§8.6 @SectionId per-class uniqueness') &&
            e.contains('Scope.inItems') &&
            e.contains('Scope.outItems')),
        isTrue,
        reason: 'Expected a per-class uniqueness error for the shared ITM-LST',
      );
    });

    test('errors when one container ID maps to two element types (type-consistency)', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('a', 'AHolder'), _field('b', 'BHolder')],
        ),
        'AHolder': _cls(
          'AHolder',
          [AnnotationData('SectionId', {'id': 'TST-AH'})],
          [
            _listField('xs', 'Alpha', [
              AnnotationData('SectionId', {'id': 'SHARED-XS-LST'}),
              AnnotationData('SectionIdPattern', {'pattern': 'SHARED-XS-xxx'}),
            ]),
          ],
        ),
        'BHolder': _cls(
          'BHolder',
          [AnnotationData('SectionId', {'id': 'TST-BH'})],
          [
            _listField('xs', 'Beta', [
              AnnotationData('SectionId', {'id': 'SHARED-XS-LST'}),
              AnnotationData('SectionIdPattern', {'pattern': 'SHARED-XS-xxx'}),
            ]),
          ],
        ),
        'Alpha': _cls('Alpha', [AnnotationData('SectionId', {'id': 'ALP'})]),
        'Beta': _cls('Beta', [AnnotationData('SectionId', {'id': 'BET'})]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any((e) => e.contains('§8.6 @SectionId consistency')),
        isTrue,
        reason: 'Expected a consistency error for SHARED-XS-LST → Alpha/Beta',
      );
    });

    test('errors when @SectionIdPattern does not mirror the container ID (pairing)', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('h', 'Holder')],
        ),
        'Holder': _cls(
          'Holder',
          [AnnotationData('SectionId', {'id': 'TST-H'})],
          [
            _listField('items', 'Item', [
              AnnotationData('SectionId', {'id': 'ITM-ITEMS-LST'}),
              // Mismatched pattern — should be ITM-ITEMS-xxx.
              AnnotationData('SectionIdPattern', {'pattern': 'ITM-WRONG-xxx'}),
            ]),
          ],
        ),
        'Item': _cls('Item', [AnnotationData('SectionId', {'id': 'ITM'})]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any((e) =>
            e.contains('§8.6 @SectionId/@SectionIdPattern pairing') &&
            e.contains('Holder.items')),
        isTrue,
        reason: 'Expected a pairing error for Holder.items',
      );
    });
  });

  group('unit: @SecondLevelSectionId implies @DetailedIn', () {
    test('errors when @SecondLevelSectionId exists without matching @DetailedIn', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('sec', 'SecClass')],
        ),
        'SecClass': _cls('SecClass', [
          AnnotationData('SectionId', {'id': 'TST-SEC'}),
          // @SecondLevelSectionId(DocA, 'DA-SEC') but no @DetailedIn(DocA)!
          AnnotationData('SecondLevelSectionId', {'documentClass': 'DocA', 'id': 'DA-SEC'}),
        ]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any((e) => e.contains('§8.6 @SecondLevelSectionId implies')),
        isTrue,
      );
    });

    test('passes when @SecondLevelSectionId is accompanied by @DetailedIn', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'}),
           AnnotationData('MapsTo', {'documentClass': 'DocA'})],
          [_field('sec', 'SecClass')],
        ),
        'SecClass': _cls('SecClass', [
          AnnotationData('SectionId', {'id': 'TST-SEC'}),
          AnnotationData('DetailedIn', {'documentClass': 'DocA'}),
          AnnotationData('SecondLevelSectionId', {'documentClass': 'DocA', 'id': 'DA-SEC'}),
        ]),
      };
      final result = validateStructuralInvariants(classes);
      final secondLevelErrors =
          result.errors.where((e) => e.contains('§8.6 @SecondLevelSectionId implies')).toList();
      expect(secondLevelErrors, isEmpty);
    });
  });

  group('unit: @DetailedIn ancestor @MapsTo check', () {
    test('errors when @DetailedIn(D) has no @MapsTo(D) on self or ancestor', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('seed', 'SeedClass')],
        ),
        'SeedClass': _cls('SeedClass', [
          AnnotationData('SectionId', {'id': 'TST-SEED'}),
          // @DetailedIn(DocA) but NO @MapsTo(DocA) here or on any ancestor!
          AnnotationData('DetailedIn', {'documentClass': 'DocA'}),
        ]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any((e) => e.contains('§8.6 @DetailedIn ancestor check')),
        isTrue,
      );
    });

    test('passes when @MapsTo(D) is on the same class as @DetailedIn(D)', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('seed', 'SeedClass')],
        ),
        'SeedClass': _cls('SeedClass', [
          AnnotationData('SectionId', {'id': 'TST-SEED'}),
          AnnotationData('MapsTo', {'documentClass': 'DocA'}),
          AnnotationData('DetailedIn', {'documentClass': 'DocA'}),
        ]),
      };
      final result = validateStructuralInvariants(classes);
      final ancestorErrors =
          result.errors.where((e) => e.contains('§8.6 @DetailedIn ancestor check')).toList();
      expect(ancestorErrors, isEmpty);
    });

    test('passes when @MapsTo(D) is on an ancestor of the @DetailedIn(D) class', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('seed', 'SeedClass')],
        ),
        'SeedClass': _cls('SeedClass', [
          AnnotationData('SectionId', {'id': 'TST-SEED'}),
          AnnotationData('MapsTo', {'documentClass': 'DocA'}), // ancestor has @MapsTo
        ], [
          _field('child', 'ChildClass'),
        ]),
        'ChildClass': _cls('ChildClass', [
          AnnotationData('SectionId', {'id': 'TST-SEED-CHD'}),
          AnnotationData('DetailedIn', {'documentClass': 'DocA'}),
        ]),
      };
      final result = validateStructuralInvariants(classes);
      final ancestorErrors =
          result.errors.where((e) => e.contains('§8.6 @DetailedIn ancestor check')).toList();
      expect(ancestorErrors, isEmpty);
    });
  });

  group('unit: canonical container root (T1)', () {
    Map<String, ModelClass> modelWithContainer() => {
          'DocSpecsProject': _cls('DocSpecsProject', [], [
            _field('projectDefinition', 'D00SolutionBlueprint'),
            _field('businessProcesses', 'TargetOperatingModel'),
          ]),
          'D00SolutionBlueprint': _cls(
            'D00SolutionBlueprint',
            [AnnotationData('SectionId', {'id': 'TST'})],
            [_field('shared', 'SharedSection')],
          ),
          'SharedSection':
              _cls('SharedSection', [AnnotationData('SectionId', {'id': 'TST-SHR'})]),
          'TargetOperatingModel': _cls('TargetOperatingModel', [
            AnnotationData('Document', {'name': 'Target Operating Model'}),
            AnnotationData('SectionId', {'id': 'TOM'}),
          ], [
            _field('shared', 'SharedSection'),
          ]),
        };

    test('findContainerRoot detects the unannotated SBP-owning class', () {
      expect(findContainerRoot(modelWithContainer()), 'DocSpecsProject');
    });

    test('findContainerRoot returns null when no container is present', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('shared', 'SharedSection')],
        ),
        'SharedSection': _cls('SharedSection', []),
      };
      expect(findContainerRoot(classes), isNull);
    });

    test('the container is exempt from §6 content checks when it is the root', () {
      final result = validateModel(modelWithContainer(), 'DocSpecsProject');
      final containerWarnings = result.warnings
          .where((w) => w.contains('DocSpecsProject') && w.contains('content'))
          .toList();
      expect(containerWarnings, isEmpty, reason: containerWarnings.join('\n'));
    });

    test('export surfaces containerRoot and keeps it out of roots', () {
      final json = ModelJsonExporter(modelWithContainer()).export();
      expect(json['containerRoot'], 'DocSpecsProject');
      final roots = (json['roots'] as List).cast<Map>();
      expect(roots.any((r) => r['type'] == 'DocSpecsProject'), isFalse);
    });
  });

  group('unit: pure-projection invariant (T2)', () {
    test('errors when a projection root reaches a non-SBP (projection-local) type', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('shared', 'SharedSection')],
        ),
        'SharedSection':
            _cls('SharedSection', [AnnotationData('SectionId', {'id': 'TST-SHR'})]),
        'BizProc': _cls('BizProc', [
          AnnotationData('Document', {'name': 'Target Operating Model'}),
          AnnotationData('SectionId', {'id': 'TOM'}),
        ], [
          _field('shared', 'SharedSection'), // OK — has a SBP counterpart
          _field('local', 'ProjLocal'), // violation — no SBP counterpart
        ]),
        'ProjLocal':
            _cls('ProjLocal', [AnnotationData('SectionId', {'id': 'BP-LOC'})]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any((e) =>
            e.contains('§8.6 pure-projection') &&
            e.contains('BizProc') &&
            e.contains('ProjLocal')),
        isTrue,
        reason: 'Expected a pure-projection error for BizProc → ProjLocal',
      );
    });

    test('passes when a projection root reaches only SBP-reachable types', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('shared', 'SharedSection')],
        ),
        'SharedSection':
            _cls('SharedSection', [AnnotationData('SectionId', {'id': 'TST-SHR'})]),
        'BizProc': _cls('BizProc', [
          AnnotationData('Document', {'name': 'Target Operating Model'}),
          AnnotationData('SectionId', {'id': 'TOM'}),
        ], [
          _field('shared', 'SharedSection'),
        ]),
      };
      final result = validateStructuralInvariants(classes);
      final pureProjectionErrors = result.errors
          .where((e) => e.contains('§8.6 pure-projection'))
          .toList();
      expect(pureProjectionErrors, isEmpty);
    });
  });

  group('unit: ModelJsonExporter', () {
    test('emits roots from @Document classes, sorted by Dxx then title', () {
      // Roots carry a `Dxx` document-number prefix on their class name (never
      // on `@SectionId`). They must sort by that number (D00→D12), regardless
      // of `@Document(name:)` title. A root without a `Dxx` prefix sorts after
      // the numbered ones, alphabetically by title.
      final classes = <String, ModelClass>{
        'D02Zeta': _cls('D02Zeta', [
          AnnotationData('Document', {'name': 'Zeta Doc'}),
          AnnotationData('SectionId', {'id': 'ZD00'}),
        ]),
        'D00Alpha': _cls('D00Alpha', [
          AnnotationData('Document', {'name': 'Alpha Doc'}),
          AnnotationData('SectionId', {'id': 'AL00'}),
        ]),
        'Plain': _cls('Plain', [
          AnnotationData('Document', {'name': 'Plain Doc'}),
          AnnotationData('SectionId', {'id': 'PL00'}),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      expect(json['classCount'], 3);
      expect(json['rootCount'], 3);
      final roots = json['roots'] as List;
      // D00Alpha (0) → D02Zeta (2) → Plain (no Dxx, sorts last by title).
      expect(roots.map((r) => (r as Map)['title']),
          ['Alpha Doc', 'Zeta Doc', 'Plain Doc']);
      expect((roots.first as Map)['sectionId'], 'AL00');
    });

    test('classifies field kinds and carries kind-specific data', () {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', [
          AnnotationData('SectionId', {'id': 'DC00'}),
        ], [
          ModelField(name: 'intro', typeName: 'String'),
          ModelField(
            name: 'diagram',
            typeName: 'DiagramSection',
            isSectionType: true,
            sectionContentType: 'mermaid',
          ),
          ModelField(
            name: 'state',
            typeName: 'Status',
            isEnum: true,
            enumValues: const ['open', 'closed'],
          ),
          ModelField(name: 'count', typeName: 'int'),
          ModelField(name: 'child', typeName: 'ChildClass'),
          _listField('items', 'ItemEntry', [
            AnnotationData('Min', {'count': 2}),
          ]),
          ModelField(
            name: 'header',
            typeName: 'TextSection',
            formFields: [
              FormFieldInfo(
                name: 'title',
                typeName: 'String',
                description: 'Title',
                required: true,
                hint: 'short',
              ),
            ],
          ),
        ]),
        'ChildClass': _cls('ChildClass', [
          AnnotationData('SectionId', {'id': 'DC00-CHD'}),
        ]),
        'ItemEntry': _cls('ItemEntry', [
          AnnotationData('SectionId', {'id': 'DC01'}),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final doc = (json['classes'] as Map)['Doc'] as Map;
      final fields = (doc['fields'] as List).cast<Map>();
      final byName = {for (final f in fields) f['name'] as String: f};

      expect(byName['intro']!['kind'], 'content');
      expect(byName['diagram']!['kind'], 'section');
      expect(byName['diagram']!['contentType'], 'mermaid');
      expect(byName['state']!['kind'], 'enum');
      expect(byName['state']!['enumValues'], ['open', 'closed']);
      expect(byName['count']!['kind'], 'scalar');
      expect(byName['count']!['type'], 'int');
      expect(byName['child']!['kind'], 'complex');
      expect(byName['child']!['type'], 'ChildClass');
      expect(byName['items']!['kind'], 'list');
      expect(byName['items']!['elementType'], 'ItemEntry');
      expect(byName['items']!['elementIsComplex'], true);
      expect(byName['items']!['min'], 2);

      final form = byName['header']!;
      expect(form['kind'], 'form');
      final formFields = (form['formFields'] as List).cast<Map>();
      expect(formFields.single['name'], 'title');
      expect(formFields.single['label'], 'Title');
      expect(formFields.single['hint'], 'short');
      expect(formFields.single['required'], true);
    });

    test('an unstamped export reports modelVersion 0 and omits the label', () {
      final json = ModelJsonExporter(const <String, ModelClass>{}).export();
      expect(json['modelVersion'], 0);
      expect(json.containsKey('modelVersionLabel'), isFalse);
    });

    test('a stamped export carries the model version and label (B2/§17)', () {
      final json = ModelJsonExporter(
        const <String, ModelClass>{},
        modelVersion: 3,
        modelVersionLabel: '1.0.0+3.abc1234',
      ).export();
      expect(json['modelVersion'], 3);
      expect(json['modelVersionLabel'], '1.0.0+3.abc1234');
    });
  });

  // ---------------------------------------------------------------------------
  // Step 1 (multiplatform_spec_model_plan §A.1): lossless annotations[] export.
  // The exporter must carry EVERY annotation ModelReader captured — name + full
  // argument set — on both classes and fields, alongside the curated render
  // keys, so the generic runtime's meta-model loader (plan §B.3) is lossless.
  // ---------------------------------------------------------------------------
  group('unit: ModelJsonExporter lossless annotations[] (step 1)', () {
    test('emits a lossless annotations[] block on classes and fields', () {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', [
          AnnotationData('SectionId', {'id': 'DC00'}),
          AnnotationData('MapsTo', {'documentClass': 'InformationModel'}),
          AnnotationData('ContentHelp', {'guidance': 'help text'}),
        ], [
          ModelField(
            name: 'count',
            typeName: 'int',
            annotations: [
              AnnotationData('Min', {'count': 2}),
              AnnotationData('Max', {'value': 100}),
              AnnotationData('PatternCheck', {'pattern': r'\d+'}),
              AnnotationData('ContentType', {'type': 'number'}),
            ],
          ),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final doc = (json['classes'] as Map)['Doc'] as Map;

      // Class-level: every annotation present with its arguments intact.
      final classAnnos = (doc['annotations'] as List).cast<Map>();
      final classByName = {for (final a in classAnnos) a['name'] as String: a};
      expect(
        classByName.keys,
        containsAll(['SectionId', 'MapsTo', 'ContentHelp']),
      );
      expect((classByName['MapsTo']!['arguments'] as Map)['documentClass'],
          'InformationModel');
      expect((classByName['SectionId']!['arguments'] as Map)['id'], 'DC00');

      // Field-level: @Min/@Max/@PatternCheck/@ContentType round-trip in full.
      final field = (doc['fields'] as List)
          .cast<Map>()
          .firstWhere((f) => f['name'] == 'count');
      final fieldAnnos = (field['annotations'] as List).cast<Map>();
      final fieldByName = {for (final a in fieldAnnos) a['name'] as String: a};
      expect(
        fieldByName.keys,
        containsAll(['Min', 'Max', 'PatternCheck', 'ContentType']),
      );
      expect((fieldByName['Min']!['arguments'] as Map)['count'], 2);
      expect((fieldByName['Max']!['arguments'] as Map)['value'], 100);
      expect((fieldByName['PatternCheck']!['arguments'] as Map)['pattern'],
          r'\d+');
      expect((fieldByName['ContentType']!['arguments'] as Map)['type'],
          'number');

      // The whole export must stay JSON-serializable.
      expect(() => jsonEncode(json), returnsNormally);
    });

    test('the annotations[] block drops no annotation the reader captured', () {
      final classAnnos = [
        AnnotationData('SectionId', {'id': 'DC00'}),
        AnnotationData('Document', {'name': 'Doc'}),
        AnnotationData(
            'DetailedIn', {'documentClass': 'ArchitectureTechnologySpecification'}),
      ];
      final fieldAnnos = [
        AnnotationData('Min', {'count': 1}),
        AnnotationData('ContentType', {'type': 'text'}),
        AnnotationData('SectionId', {'id': 'DC00-F'}),
      ];
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', classAnnos, [
          ModelField(name: 'f', typeName: 'String', annotations: fieldAnnos),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final doc = (json['classes'] as Map)['Doc'] as Map;

      final exportedClassNames = (doc['annotations'] as List)
          .cast<Map>()
          .map((a) => a['name'])
          .toSet();
      expect(exportedClassNames, classAnnos.map((a) => a.name).toSet());

      final field = (doc['fields'] as List).cast<Map>().single;
      final exportedFieldNames = (field['annotations'] as List)
          .cast<Map>()
          .map((a) => a['name'])
          .toSet();
      expect(exportedFieldNames, fieldAnnos.map((a) => a.name).toSet());
    });

    test('preserves source declaration order of annotations (stable block)', () {
      final ordered = [
        AnnotationData('SectionId', {'id': 'DC00'}),
        AnnotationData('MapsTo', {'documentClass': 'D'}),
        AnnotationData('DetailedIn', {'documentClass': 'D'}),
      ];
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', ordered),
      };
      final json = ModelJsonExporter(classes).export();
      final doc = (json['classes'] as Map)['Doc'] as Map;
      final names = (doc['annotations'] as List)
          .cast<Map>()
          .map((a) => a['name'])
          .toList();
      expect(names, ['SectionId', 'MapsTo', 'DetailedIn']);
    });

    test('omits the annotations key for a class/field with no annotations', () {
      final classes = <String, ModelClass>{
        'Bare': _cls('Bare', const [], [
          ModelField(name: 'f', typeName: 'String'),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final bare = (json['classes'] as Map)['Bare'] as Map;
      expect(bare.containsKey('annotations'), isFalse);
      final field = (bare['fields'] as List).cast<Map>().single;
      expect(field.containsKey('annotations'), isFalse);
    });

    test('@Form field hints survive the export (formFields + annotations)', () {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', [AnnotationData('SectionId', {'id': 'DC00'})], [
          ModelField(
            name: 'header',
            typeName: 'TextSection',
            annotations: [AnnotationData('Form', {})],
            formFields: [
              FormFieldInfo(
                name: 'title',
                typeName: 'String',
                description: 'Title',
                required: true,
                hint: 'keep it short',
              ),
            ],
          ),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final doc = (json['classes'] as Map)['Doc'] as Map;
      final field = (doc['fields'] as List).cast<Map>().single;
      // Form hint round-trips via the curated formFields block …
      expect(field['kind'], 'form');
      final ff = (field['formFields'] as List).cast<Map>().single;
      expect(ff['hint'], 'keep it short');
      // … and the @Form annotation itself is present in the lossless block.
      final names =
          (field['annotations'] as List).cast<Map>().map((a) => a['name']);
      expect(names, contains('Form'));
    });
  });

  // ---------------------------------------------------------------------------
  // SD-1: @StandardReferences provenance flows into spec_model.json. The reader
  // captures it generically (arguments: standards[] + connotation), and the
  // exporter surfaces a curated `standardReferences` key beside the lossless
  // annotations block — mirroring the mapsTo / detailedIn projection.
  // ---------------------------------------------------------------------------
  group('unit: ModelJsonExporter @StandardReferences (SD-1)', () {
    test('curated standardReferences surfaces on a class', () {
      final classes = <String, ModelClass>{
        'QualityModel': _cls('QualityModel', [
          AnnotationData('SectionId', {'id': 'QM00'}),
          AnnotationData('StandardReferences', {
            'standards': ['ISO/IEC 25010:2023 §4.2 — Functional suitability'],
            'connotation': 'The quality characteristics the system is measured '
                'against.',
          }),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final cls = (json['classes'] as Map)['QualityModel'] as Map;

      final refs = cls['standardReferences'] as Map;
      expect((refs['standards'] as List).single,
          'ISO/IEC 25010:2023 §4.2 — Functional suitability');
      expect(refs['connotation'],
          'The quality characteristics the system is measured against.');

      // Still present (losslessly) in the generic annotations block.
      final annoNames =
          (cls['annotations'] as List).cast<Map>().map((a) => a['name']);
      expect(annoNames, contains('StandardReferences'));

      expect(() => jsonEncode(json), returnsNormally);
    });

    test('curated standardReferences surfaces on a field', () {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', [AnnotationData('SectionId', {'id': 'DC00'})], [
          ModelField(
            name: 'objective',
            typeName: 'String',
            annotations: [
              AnnotationData('StandardReferences', {
                'standards': ['IEEE 830-1998 §5.3 — Specific requirements'],
                'connotation': 'A single measurable objective.',
              }),
            ],
          ),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final doc = (json['classes'] as Map)['Doc'] as Map;
      final field = (doc['fields'] as List).cast<Map>().single;

      final refs = field['standardReferences'] as Map;
      expect((refs['standards'] as List).single,
          'IEEE 830-1998 §5.3 — Specific requirements');
      expect(refs['connotation'], 'A single measurable objective.');
    });

    test('omits standardReferences when the annotation is absent or empty', () {
      final classes = <String, ModelClass>{
        'Bare': _cls('Bare', [AnnotationData('SectionId', {'id': 'BR00'})], [
          ModelField(name: 'f', typeName: 'String'),
        ]),
        // Present but carrying no usable values → still omitted.
        'Empty': _cls('Empty', [
          AnnotationData('StandardReferences', {
            'standards': <Object?>[],
            'connotation': '',
          }),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final bare = (json['classes'] as Map)['Bare'] as Map;
      expect(bare.containsKey('standardReferences'), isFalse);
      final field = (bare['fields'] as List).cast<Map>().single;
      expect(field.containsKey('standardReferences'), isFalse);
      final empty = (json['classes'] as Map)['Empty'] as Map;
      expect(empty.containsKey('standardReferences'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Step 2 (multiplatform_spec_model_plan §A.2): meta-data schema + version
  // stamp. The exporter stamps the meta-data file with `metaSchemaVersion`
  // (the file's own on-disk schema version) beside `modelVersion` /
  // `modelVersionLabel`; `validateSpecModelMeta` rejects a meta-data map that
  // is missing required keys or carries an unreadable schema version.
  // ---------------------------------------------------------------------------
  group('unit: meta-data schema + version stamp (step 2)', () {
    Map<String, Object?> sampleMeta() {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', [
          AnnotationData('Document', {'name': 'Doc'}),
          AnnotationData('SectionId', {'id': 'DC00'}),
        ], [
          ModelField(name: 'content', typeName: 'String'),
        ]),
      };
      return ModelJsonExporter(
        classes,
        modelVersion: 7,
        modelVersionLabel: 'v0.7',
      ).export();
    }

    test('export() stamps the meta-data with metaSchemaVersion', () {
      final meta = sampleMeta();
      expect(meta['metaSchemaVersion'], specModelMetaSchemaVersion);
      expect(meta['metaSchemaVersion'], isA<int>());
      // The model-version stamp travels beside it untouched.
      expect(meta['modelVersion'], 7);
      expect(meta['modelVersionLabel'], 'v0.7');
    });

    test('validateSpecModelMeta accepts a freshly exported meta-data map', () {
      expect(validateSpecModelMeta(sampleMeta()), isEmpty);
    });

    test('validateSpecModelMeta rejects meta-data missing required keys', () {
      for (final key in const [
        'metaSchemaVersion',
        'modelVersion',
        'generatedAt',
        'classCount',
        'rootCount',
        'roots',
        'classes',
      ]) {
        final meta = sampleMeta()..remove(key);
        final errors = validateSpecModelMeta(meta);
        expect(errors, isNotEmpty,
            reason: 'removing "$key" must produce an error');
        expect(errors.join('\n'), contains(key),
            reason: 'the error must name the missing key "$key"');
      }
    });

    test('validateSpecModelMeta rejects a non-object root', () {
      expect(validateSpecModelMeta('not a map'), isNotEmpty);
      expect(validateSpecModelMeta(<Object?>[]), isNotEmpty);
    });

    test('validateSpecModelMeta rejects a meta-schema newer than supported', () {
      final meta = sampleMeta()
        ..['metaSchemaVersion'] = specModelMetaSchemaVersion + 1;
      final errors = validateSpecModelMeta(meta);
      expect(errors, isNotEmpty);
      expect(errors.join('\n'), contains('metaSchemaVersion'));
    });

    test('validateSpecModelMeta rejects wrong-typed required values', () {
      final meta = sampleMeta()..['classes'] = 'should be a map';
      expect(validateSpecModelMeta(meta), isNotEmpty);
      final meta2 = sampleMeta()..['roots'] = 'should be a list';
      expect(validateSpecModelMeta(meta2), isNotEmpty);
      final meta3 = sampleMeta()..['modelVersion'] = 'should be an int';
      expect(validateSpecModelMeta(meta3), isNotEmpty);
    });
  });

  group('unit: SpecOpsGenerator (OE-2)', () {
    test('emits an idempotent registry with the section content leaves', () {
      final src = SpecOpsGenerator(const <String, ModelClass>{}).generate();
      // Header: idempotent guard + the two model package imports.
      expect(src, contains('void registerSpecOps()'));
      expect(src, contains('if (_registered) return;'));
      expect(src,
          contains("import 'package:tom_specs_core/tom_specs_core.dart';"));
      expect(src,
          contains("import 'package:tom_specs_model/tom_specs_model.dart';"));
      // All ten tom_specs_core section content leaves are registered by hand.
      for (final leaf in const [
        'TextSection',
        'DiagramSection',
        'DartCodeSection',
        'DdlCodeSection',
      ]) {
        expect(src, contains('SpecRegistry.register($leaf, SpecClassOps('),
            reason: '$leaf content leaf must be registered');
      }
    });

    test('classifies child-node, list and scalar fields into slot/clone/scalar',
        () {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', const [], [
          _field('content', 'String'),
          _field('child', 'ChildClass'),
          ModelField(
            name: 'maybeChild',
            typeName: 'ChildClass?',
            isNullable: true,
          ),
          _listField('items', 'ItemEntry'),
          _field('intro', 'String'),
        ]),
        'ChildClass': _cls('ChildClass', const []),
        'ItemEntry': _cls('ItemEntry', const []),
      };
      final src = SpecOpsGenerator(classes).generate();

      // A single complex child → SpecSlot.node with a non-null cast.
      expect(
        src,
        contains("SpecSlot.node(() => n.child, "
            "(v) => n.child = v as ChildClass, label: 'child')"),
      );
      // A nullable complex child → nullable cast.
      expect(
        src,
        contains("SpecSlot.node(() => n.maybeChild, "
            "(v) => n.maybeChild = v as ChildClass?, label: 'maybeChild')"),
      );
      // A list-of-complex → SpecSlot.list with a narrowing .cast<Element>().
      expect(
        src,
        contains("SpecSlot.list(() => n.items, "
            "(v) => n.items = v.cast<ItemEntry>(), label: 'items')"),
      );
      // cloneShallow copies every field, including the scalars.
      expect(src, contains('..content = n.content'));
      expect(src, contains('..intro = n.intro'));
      // yamlScalar prefers the canonical `content` field.
      expect(src, contains('yamlScalar: (o) => (o as Doc).content,'));
    });

    test('omits yamlScalar for a multi-scalar class without a content field',
        () {
      final classes = <String, ModelClass>{
        'Multi': _cls('Multi', const [], [
          _field('alpha', 'String'),
          _field('beta', 'String'),
        ]),
      };
      final src = SpecOpsGenerator(classes).generate();
      // Two scalars, neither named `content` → no yamlScalar emitted (deferred
      // multi-scalar packing). cloneShallow still copies both.
      final multiBlock = src.substring(src.indexOf('register(Multi,'));
      expect(multiBlock, isNot(contains('yamlScalar:')));
      expect(src, contains('..alpha = n.alpha'));
      expect(src, contains('..beta = n.beta'));
    });

    test('skips the two hand-written SpecNode mixin leaves', () {
      final classes = <String, ModelClass>{
        'DocumentHeader': _cls('DocumentHeader', const []),
        'SectionMeta': _cls('SectionMeta', const []),
        'Other': _cls('Other', const []),
      };
      final src = SpecOpsGenerator(classes).generate();
      expect(src, contains('SpecRegistry.register(Other,'));
      expect(src, isNot(contains('SpecRegistry.register(DocumentHeader,')));
      expect(src, isNot(contains('SpecRegistry.register(SectionMeta,')));
    });
  });
}
