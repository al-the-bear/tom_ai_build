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

    test('§8.6: no duplicate @SectionId strings across ProjectDefinition tree', () {
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
        // ~1082 coverage gaps remain across multiple PD files after CS-02.
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

    test('§8.6: every @Document class has at least one @DetailedIn entry in PD tree', () {
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

    test('outliner validates BusinessSystemInteractions root without errors', () {
      // BSI is a smoke-test root known to be clean of §6.1 ContentType issues.
      final result = validateModel(classes, 'BusinessSystemInteractions');
      expect(result.errors, isEmpty, reason: result.errors.join('\n'));
    });
  });

  // ---------------------------------------------------------------------------
  // Unit tests with small synthetic models
  // ---------------------------------------------------------------------------

  group('unit: @SectionId uniqueness check', () {
    test('detects duplicate @SectionId across two sibling classes', () {
      final classes = {
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [
            _field('alpha', 'Alpha'),
            _field('beta', 'Beta'),
          ],
        ),
        'Alpha': _cls('Alpha', [AnnotationData('SectionId', {'id': 'PD00-DUP'})]),
        'Beta': _cls('Beta', [AnnotationData('SectionId', {'id': 'PD00-DUP'})]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any((e) => e.contains('§8.6 @SectionId uniqueness')),
        isTrue,
        reason: 'Expected a uniqueness error for "PD00-DUP"',
      );
    });

    test('passes when all @SectionIds are distinct', () {
      final classes = {
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [
            _field('alpha', 'Alpha'),
            _field('beta', 'Beta'),
          ],
        ),
        'Alpha': _cls('Alpha', [AnnotationData('SectionId', {'id': 'PD00-AAA'})]),
        'Beta': _cls('Beta', [AnnotationData('SectionId', {'id': 'PD00-BBB'})]),
      };
      final result = validateStructuralInvariants(classes);
      final dupeErrors = result.errors.where((e) => e.contains('uniqueness')).toList();
      expect(dupeErrors, isEmpty);
    });
  });

  group('unit: @SectionId coverage check', () {
    test('warns when a reachable class has no @SectionId and no @SectionIdPattern coverage', () {
      final classes = {
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('container', 'Container')],
        ),
        'Container': _cls(
          'Container',
          [AnnotationData('SectionId', {'id': 'PD00-CON'})],
          [
            _listField('items', 'ListItem', [
              AnnotationData('SectionIdPattern', {'pattern': 'PD00-CON-xx'}),
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('container', 'Container')],
        ),
        'Container': _cls(
          'Container',
          [AnnotationData('SectionId', {'id': 'PD00-CON'})],
          [
            // List field with NO @SectionIdPattern and no @Reference.
            _listField('items', 'ListItem'),
          ],
        ),
        'ListItem': _cls('ListItem', [AnnotationData('SectionId', {'id': 'PD00-ITM'})]),
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('container', 'Container')],
        ),
        'Container': _cls(
          'Container',
          [AnnotationData('SectionId', {'id': 'PD00-CON'})],
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('container', 'Container')],
        ),
        'Container': _cls(
          'Container',
          [AnnotationData('SectionId', {'id': 'PD00-CON'})],
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
          'ProjectDefinition': _cls(
            'ProjectDefinition',
            [AnnotationData('SectionId', {'id': 'PD00'})],
            [_field('scope', 'Scope')],
          ),
          'Scope': _cls(
            'Scope',
            [AnnotationData('SectionId', {'id': 'PD00-SCO'})],
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('a', 'AHolder'), _field('b', 'BHolder')],
        ),
        'AHolder': _cls(
          'AHolder',
          [AnnotationData('SectionId', {'id': 'PD00-AH'})],
          [
            _listField('xs', 'Alpha', [
              AnnotationData('SectionId', {'id': 'SHARED-XS-LST'}),
              AnnotationData('SectionIdPattern', {'pattern': 'SHARED-XS-xxx'}),
            ]),
          ],
        ),
        'BHolder': _cls(
          'BHolder',
          [AnnotationData('SectionId', {'id': 'PD00-BH'})],
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('h', 'Holder')],
        ),
        'Holder': _cls(
          'Holder',
          [AnnotationData('SectionId', {'id': 'PD00-H'})],
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('sec', 'SecClass')],
        ),
        'SecClass': _cls('SecClass', [
          AnnotationData('SectionId', {'id': 'PD00-SEC'}),
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'}),
           AnnotationData('MapsTo', {'documentClass': 'DocA'})],
          [_field('sec', 'SecClass')],
        ),
        'SecClass': _cls('SecClass', [
          AnnotationData('SectionId', {'id': 'PD00-SEC'}),
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('seed', 'SeedClass')],
        ),
        'SeedClass': _cls('SeedClass', [
          AnnotationData('SectionId', {'id': 'PD00-SEED'}),
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('seed', 'SeedClass')],
        ),
        'SeedClass': _cls('SeedClass', [
          AnnotationData('SectionId', {'id': 'PD00-SEED'}),
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
        'ProjectDefinition': _cls(
          'ProjectDefinition',
          [AnnotationData('SectionId', {'id': 'PD00'})],
          [_field('seed', 'SeedClass')],
        ),
        'SeedClass': _cls('SeedClass', [
          AnnotationData('SectionId', {'id': 'PD00-SEED'}),
          AnnotationData('MapsTo', {'documentClass': 'DocA'}), // ancestor has @MapsTo
        ], [
          _field('child', 'ChildClass'),
        ]),
        'ChildClass': _cls('ChildClass', [
          AnnotationData('SectionId', {'id': 'PD00-SEED-CHD'}),
          AnnotationData('DetailedIn', {'documentClass': 'DocA'}),
        ]),
      };
      final result = validateStructuralInvariants(classes);
      final ancestorErrors =
          result.errors.where((e) => e.contains('§8.6 @DetailedIn ancestor check')).toList();
      expect(ancestorErrors, isEmpty);
    });
  });
}
