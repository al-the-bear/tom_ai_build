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

    test('§8.6: every @Document class has at least one @DetailedIn entry in SBP tree', () {
      final result = validateStructuralInvariants(classes);
      final detailCountWarnings = result.warnings
          .where((w) => w.contains('§8.6 detail-count'))
          .toList();
      expect(detailCountWarnings, isEmpty, reason: detailCountWarnings.join('\n'));
    });

    test('§8.6: section ids resolve identically from every @Document root '
        '(dsa4 root-independence)', () {
      final result = validateStructuralInvariants(classes);
      final rootIdErrors = result.errors
          .where((e) => e.contains('§8.6 root-independent id'))
          .toList();
      // Every class must have a single id-resolution mode: a class-level
      // @SectionId XOR being a @SectionIdPattern list element. A class mixing
      // both resolves to different ids depending on the traversal root.
      expect(rootIdErrors, isEmpty, reason: rootIdErrors.join('\n'));
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

    test('outliner validates IntegrationInterfaceSpecification root '
        'without non-field-shape errors', () {
      // IIS is a smoke-test root known to be clean of §6.1 ContentType issues.
      // The §6.1 field-shape rules (YRB1) DO fire here — D07 projects SBP
      // sections that still carry un-ided inline sub-section String fields
      // (the YRB5 id-sweep backlog). Those are enforced by the dedicated
      // field-shape count test below; this smoke test asserts the root is
      // otherwise structurally clean, so filter the known backlog out.
      final result = validateModel(classes, 'D07IntegrationInterfaceSpecification');
      final otherErrors = result.errors
          .where((e) => !e.contains('§6.1 field-shape'))
          .toList();
      expect(otherErrors, isEmpty, reason: otherErrors.join('\n'));
    });

    test(
      '§6.1 field-shape (YRB1/YRB5): the inline sub-section id sweep is '
      'complete — zero reachable non-"content" String fields lack a '
      'field-level @SectionId',
      () {
        // Walk the whole model from the canonical container so every reachable
        // class is checked, then count the rule-1 offenders: descriptively
        // named String / `@Form`-on-String fields (shape (3)) that lack a
        // field-level @SectionId. YRB1 ENFORCED the rule (added the error + this
        // guard); YRB5 then FIXED the model — every offender now carries a
        // globally-unique `<PARENT_CLASS_SECTIONID>-<FIELD_MNEMONIC>` id.
        //
        // History: the backlog started at 177 reachable String offenders (a
        // by-kind census of spec_model.json reported 185, over-counting by 8 —
        // 7 `TextSection?` @Form sub-sections whose class owns the id, and 1
        // orphan-class field unreachable from the container). YRB3 folded the 11
        // String-typed `@Reference` fields into the sweep (→ 166 remaining), and
        // YRB5 stamped the last 166. The sweep is now complete → 0.
        final result = validateModel(classes, 'DocSpecsProject');
        final missingId = result.errors
            .where((e) => e.contains('§6.1 field-shape') &&
                e.contains('must carry a field-level @SectionId'))
            .toList();
        expect(missingId, isEmpty,
            reason: 'YRB5 cleared the inline sub-section id backlog; expected '
                '0 un-ided String fields, got ${missingId.length}:\n'
                '${missingId.join('\n')}');
      },
    );

    test(
      '§6.1 field-shape (YRB1/YRC1): no field misuses the reserved name '
      '"content" for a non-String value',
      () {
        // The reserved-name rule flags any `content` field that is not a plain
        // String value. YRC1 fixed the last offender —
        // ResponsiveBehavior.content (a complex sub-section named `content`) was
        // renamed to `contentReflow` — so the sweep is now complete: zero
        // reserved-name violations across the whole model.
        final result = validateModel(classes, 'DocSpecsProject');
        final reserved = result.errors
            .where((e) => e.contains('§6.1 field-shape') &&
                e.contains('reserved field name'))
            .toList();
        expect(reserved, isEmpty, reason: reserved.join('\n'));
      },
    );

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

    test(
      'SD-2: every instance member carries a 0-based contiguous '
      '@SerializationOrder ordinal',
      () {
        final problems = <String>[];
        classes.forEach((name, cls) {
          if (cls.fields.isEmpty) return;
          final orders = <int>[];
          for (final f in cls.fields) {
            final o = f.serializationOrder;
            if (o == null) {
              problems.add('$name.${f.name}: missing @SerializationOrder');
            } else {
              orders.add(o);
            }
          }
          orders.sort();
          final expected = [for (var i = 0; i < cls.fields.length; i++) i];
          if (orders.join(',') != expected.join(',')) {
            problems.add('$name: ordinals {${orders.join(',')}} '
                '!= {${expected.join(',')}}');
          }
        });
        // The SD-2 stamping script must cover every member of every spec-model
        // class with a unique, contiguous, 0-based ordinal in source order.
        expect(problems, isEmpty, reason: problems.take(20).join('\n'));
      },
    );
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

  group('unit: root-independent section-id resolution (dsa4)', () {
    test('errors when a class is reached both as a @SectionIdPattern list '
        'element AND as a standalone complex section (mixed resolution mode)',
        () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [
            // Reached as a list element → addressed by the instance pattern.
            _listField('items', 'Item', [
              AnnotationData('SectionId', {'id': 'ITEM-ITEMS-LST'}),
              AnnotationData('SectionIdPattern', {'pattern': 'ITEM-ITEMS-xxx'}),
            ]),
            // ...and also reached as a standalone complex section → addressed
            // by its own class-level @SectionId. The two modes resolve to
            // different ids depending on the traversal root.
            _field('featuredItem', 'Item'),
          ],
        ),
        'Item': _cls('Item', [AnnotationData('SectionId', {'id': 'ITEM'})]),
      };
      final result = validateStructuralInvariants(classes);
      expect(
        result.errors.any((e) => e.contains('§8.6 root-independent id')),
        isTrue,
        reason: result.errors.join('\n'),
      );
    });

    test('passes when a class carries @SectionId and is only ever a '
        '@SectionIdPattern list element (the -LST prefix source is by design)',
        () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [
            _listField('items', 'Item', [
              AnnotationData('SectionId', {'id': 'ITEM-ITEMS-LST'}),
              AnnotationData('SectionIdPattern', {'pattern': 'ITEM-ITEMS-xxx'}),
            ]),
          ],
        ),
        // Element class carries @SectionId — this is the `<E>` prefix source
        // for the list container/pattern ids (ITEM → ITEM-ITEMS-LST/-xxx), not
        // a conflict, because it is never reached as a standalone section.
        'Item': _cls('Item', [AnnotationData('SectionId', {'id': 'ITEM'})]),
      };
      final result = validateStructuralInvariants(classes);
      final rootIdErrors =
          result.errors.where((e) => e.contains('§8.6 root-independent id')).toList();
      expect(rootIdErrors, isEmpty, reason: rootIdErrors.join('\n'));
    });

    test('passes when a class with @SectionId is only ever a standalone '
        'complex section (never a list element)', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('overview', 'Overview')],
        ),
        'Overview': _cls('Overview', [AnnotationData('SectionId', {'id': 'OVW'})]),
      };
      final result = validateStructuralInvariants(classes);
      final rootIdErrors =
          result.errors.where((e) => e.contains('§8.6 root-independent id')).toList();
      expect(rootIdErrors, isEmpty, reason: rootIdErrors.join('\n'));
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

  group('unit: §6.1 canonical field shapes (YRB1)', () {
    // Field-shape errors carry the '§6.1 field-shape' prefix. Synthetic models
    // deliberately omit D00SolutionBlueprint so the §8.6 invariants stay a
    // no-op and only the field-shape rules under test can fire.
    List<String> shapeErrors(Map<String, ModelClass> classes, String root) =>
        validateModel(classes, root)
            .errors
            .where((e) => e.contains('§6.1 field-shape'))
            .toList();

    ModelField idField(String name, String typeName,
            [List<AnnotationData> extra = const []]) =>
        _field(name, typeName, [
          AnnotationData('SectionId', {'id': 'SEC-${name.toUpperCase()}'}),
          ...extra,
        ]);

    test('errors when a non-"content" String field lacks a field-level @SectionId',
        () {
      final classes = {
        'Sec': _cls('Sec', [AnnotationData('SectionId', {'id': 'SEC'})], [
          _field('purpose', 'String'), // shape (3) but MISSING the id
        ]),
      };
      final errs = shapeErrors(classes, 'Sec');
      expect(
        errs.any((e) =>
            e.contains('Sec.purpose') &&
            e.contains('must carry a field-level @SectionId')),
        isTrue,
        reason: errs.join('\n'),
      );
    });

    test('passes when a non-"content" String field carries a field-level @SectionId',
        () {
      final classes = {
        'Sec': _cls('Sec', [AnnotationData('SectionId', {'id': 'SEC'})], [
          idField('purpose', 'String'), // shape (3), id present
        ]),
      };
      expect(shapeErrors(classes, 'Sec'), isEmpty);
    });

    test('passes for the reserved "content" String field without an id (shape 1)',
        () {
      final classes = {
        'Sec': _cls('Sec', [AnnotationData('SectionId', {'id': 'SEC'})], [
          _field('content', 'String'),
        ]),
      };
      expect(shapeErrors(classes, 'Sec'), isEmpty);
    });

    test('passes for a "content" String field with @Form (shape 2)', () {
      final classes = {
        'Sec': _cls('Sec', [AnnotationData('SectionId', {'id': 'SEC'})], [
          _field('content', 'String', [AnnotationData('Form', {})]),
        ]),
      };
      expect(shapeErrors(classes, 'Sec'), isEmpty);
    });

    test('errors when "content" is a complex (non-String) field (reserved name)',
        () {
      final classes = {
        'Sec': _cls('Sec', [AnnotationData('SectionId', {'id': 'SEC'})], [
          _field('content', 'ChildSection'), // reserved name misused
        ]),
        'ChildSection':
            _cls('ChildSection', [AnnotationData('SectionId', {'id': 'SEC-CHD'})]),
      };
      final errs = shapeErrors(classes, 'Sec');
      expect(
        errs.any((e) =>
            e.contains('Sec.content') && e.contains('reserved field name')),
        isTrue,
        reason: errs.join('\n'),
      );
    });

    test('errors when the reserved "content" field carries a field-level @SectionId',
        () {
      final classes = {
        'Sec': _cls('Sec', [AnnotationData('SectionId', {'id': 'SEC'})], [
          _field('content', 'String',
              [AnnotationData('SectionId', {'id': 'SEC-CONTENT'})]),
        ]),
      };
      final errs = shapeErrors(classes, 'Sec');
      expect(
        errs.any((e) =>
            e.contains('Sec.content') && e.contains('must not carry')),
        isTrue,
        reason: errs.join('\n'),
      );
    });

    test('the field-shape rule does not fire for a non-String int scalar '
        '(that is the separate scalar rule)', () {
      final classes = {
        'Sec': _cls('Sec', [AnnotationData('SectionId', {'id': 'SEC'})], [
          _field('count', 'int'),
        ]),
      };
      // No field-shape error (isString is false) …
      expect(shapeErrors(classes, 'Sec'), isEmpty);
      // … but the pre-existing non-String primitive rule still rejects it.
      final all = validateModel(classes, 'Sec').errors;
      expect(all.any((e) => e.contains('Sec.count') && e.contains('not allowed')),
          isTrue, reason: all.join('\n'));
    });

    test('passes for an enum field without a field-level @SectionId (boundary)',
        () {
      final classes = {
        'Sec': _cls('Sec', [AnnotationData('SectionId', {'id': 'SEC'})], [
          ModelField(
            name: 'status',
            typeName: 'Status',
            isEnum: true,
            enumValues: const ['open', 'closed'],
          ),
        ]),
      };
      expect(shapeErrors(classes, 'Sec'), isEmpty);
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
  // SD-2: @SerializationOrder ordinal flows onto every member node. The reader
  // exposes it as ModelField.serializationOrder; the exporter surfaces it as a
  // curated `serializationOrder` key.
  // ---------------------------------------------------------------------------
  group('unit: ModelJsonExporter @SerializationOrder (SD-2)', () {
    test('ModelField.serializationOrder reads the ordinal from the annotation',
        () {
      final f = _field('header', 'DocumentHeader',
          [AnnotationData('SerializationOrder', {'order': 3})]);
      expect(f.serializationOrder, 3);
      expect(_field('bare', 'String').serializationOrder, isNull);
    });

    test('serializationOrder surfaces on member nodes; omitted when absent', () {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', [AnnotationData('SectionId', {'id': 'DC00'})], [
          _field('content', 'String',
              [AnnotationData('SerializationOrder', {'order': 0})]),
          _field('header', 'DocumentHeader',
              [AnnotationData('SerializationOrder', {'order': 1})]),
          _field('unstamped', 'String'),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final fields = ((json['classes'] as Map)['Doc'] as Map)['fields'] as List;
      final byName = {
        for (final f in fields.cast<Map>()) f['name'] as String: f,
      };
      expect(byName['content']!['serializationOrder'], 0);
      expect(byName['header']!['serializationOrder'], 1);
      expect(byName['unstamped']!.containsKey('serializationOrder'), isFalse);
      expect(() => jsonEncode(json), returnsNormally);
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

  // ---------------------------------------------------------------------------
  // §6.1c collapsible-wrapper detection (TSMA4–TSMA5). The validator warns when
  // a single-subsection wrapper with vacuous content adds a redundant hierarchy
  // level (single complex referrer, one subsection field, bare `content`). The
  // TSMA5 keep-a-level exemptions — form-bearing, meaningful-content
  // (@ContentHelp / @StandardReferences / non-Form @ContentType), and
  // shared/multi-referrer wrappers — must NOT be flagged.
  // ---------------------------------------------------------------------------
  group('unit: §6.1c collapsible-wrapper detection (TSMA4–TSMA5)', () {
    // Collapsible-wrapper detection lives in the §8.6 structural pass, so a
    // D00SolutionBlueprint root must reach the candidate. The root references
    // the wrapper; the wrapper carries exactly one subsection + bare content.
    List<String> collapsibleWarnings(Map<String, ModelClass> classes) =>
        validateStructuralInvariants(classes)
            .warnings
            .where((w) => w.contains('§6.1c collapsible-wrapper'))
            .toList();

    // A leaf section the wrapper's single subsection points at.
    ModelClass innerSection() =>
        _cls('Inner', [AnnotationData('SectionId', {'id': 'INR'})], [
          _field('content', 'String'),
        ]);

    Map<String, ModelClass> modelWithWrapper(ModelClass wrapper) => {
          'D00SolutionBlueprint': _cls(
            'D00SolutionBlueprint',
            [AnnotationData('SectionId', {'id': 'TST'})],
            [_field('wrapper', 'Wrapper')],
          ),
          'Wrapper': wrapper,
          'Inner': innerSection(),
        };

    test('flags a collapsible single-subsection wrapper with bare content', () {
      final classes = modelWithWrapper(
        _cls('Wrapper', [AnnotationData('SectionId', {'id': 'WRP'})], [
          _field('content', 'String'),
          _field('inner', 'Inner'),
        ]),
      );
      final warns = collapsibleWarnings(classes);
      expect(warns, hasLength(1), reason: warns.join('\n'));
      expect(warns.single, contains('Wrapper'));
      expect(warns.single, contains('D00SolutionBlueprint.wrapper'));
      expect(warns.single, contains('complex:Inner'));
    });

    test('flags a collapsible wrapper with a list subsection and no content', () {
      final classes = modelWithWrapper(
        _cls('Wrapper', [AnnotationData('SectionId', {'id': 'WRP'})], [
          _listField('inner', 'Inner',
              [AnnotationData('SectionIdPattern', {'pattern': 'WRP-{n}'})]),
        ]),
      );
      final warns = collapsibleWarnings(classes);
      expect(warns, hasLength(1), reason: warns.join('\n'));
      expect(warns.single, contains('list<Inner>'));
    });

    test('does NOT flag a form-bearing wrapper (keep-a-level, TSMA5)', () {
      final classes = modelWithWrapper(
        _cls('Wrapper',
            [AnnotationData('SectionId', {'id': 'WRP'}), AnnotationData('Form', {})],
            [
              _field('content', 'String'),
              _field('inner', 'Inner'),
            ]),
      );
      expect(collapsibleWarnings(classes), isEmpty);
    });

    test('does NOT flag a wrapper whose content carries @ContentHelp '
        '(meaningful content, TSMA5)', () {
      final classes = modelWithWrapper(
        _cls('Wrapper', [AnnotationData('SectionId', {'id': 'WRP'})], [
          _field('content', 'String',
              [AnnotationData('ContentHelp', {'guidance': 'distinct concept'})]),
          _field('inner', 'Inner'),
        ]),
      );
      expect(collapsibleWarnings(classes), isEmpty);
    });

    test('does NOT flag a wrapper whose content carries @StandardReferences '
        '(meaningful content, TSMA5)', () {
      final classes = modelWithWrapper(
        _cls('Wrapper', [AnnotationData('SectionId', {'id': 'WRP'})], [
          _field('content', 'String', [
            AnnotationData('StandardReferences', {
              'standards': ['ISO/IEC 25010:2023 §4.2'],
              'connotation': 'documents the section as a distinct concept',
            }),
          ]),
          _field('inner', 'Inner'),
        ]),
      );
      expect(collapsibleWarnings(classes), isEmpty);
    });

    test('does NOT flag a wrapper whose content carries a non-Form @ContentType '
        '(meaningful content, TSMA5)', () {
      final classes = modelWithWrapper(
        _cls('Wrapper', [AnnotationData('SectionId', {'id': 'WRP'})], [
          _field('content', 'String',
              [AnnotationData('ContentType', {'type': 'mermaid'})]),
          _field('inner', 'Inner'),
        ]),
      );
      expect(collapsibleWarnings(classes), isEmpty);
    });

    test('does NOT flag a shared wrapper reached by >1 parent field '
        '(shared substructure, TSMA5/TSMA3 rule)', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [
            _field('first', 'Wrapper'),
            _field('second', 'Wrapper'),
          ],
        ),
        'Wrapper': _cls('Wrapper', [AnnotationData('SectionId', {'id': 'WRP'})], [
          _field('content', 'String'),
          _field('inner', 'Inner'),
        ]),
        'Inner': innerSection(),
      };
      expect(collapsibleWarnings(classes), isEmpty);
    });

    test('does NOT flag a wrapper with a named scalar besides content '
        '(independent meaning, TSMA5)', () {
      final classes = modelWithWrapper(
        _cls('Wrapper', [AnnotationData('SectionId', {'id': 'WRP'})], [
          _field('content', 'String'),
          _field('label', 'String'),
          _field('inner', 'Inner'),
        ]),
      );
      expect(collapsibleWarnings(classes), isEmpty);
    });

    test('does NOT flag a class with two subsections (not a single-subsection '
        'wrapper)', () {
      final classes = {
        'D00SolutionBlueprint': _cls(
          'D00SolutionBlueprint',
          [AnnotationData('SectionId', {'id': 'TST'})],
          [_field('wrapper', 'Wrapper')],
        ),
        'Wrapper': _cls('Wrapper', [AnnotationData('SectionId', {'id': 'WRP'})], [
          _field('inner', 'Inner'),
          _field('other', 'Other'),
        ]),
        'Inner': innerSection(),
        'Other': _cls('Other', [AnnotationData('SectionId', {'id': 'OTH'})], [
          _field('content', 'String'),
        ]),
      };
      expect(collapsibleWarnings(classes), isEmpty);
    });
  });

  group('end-to-end: real tom_specs_model §6.1c collapsible-wrapper steady state',
      () {
    test('the post-TSMA4 model emits zero collapsible-wrapper warnings', () async {
      final driver = createAnalysisDriver(modelPath);
      final reader = ModelReader(driver);
      await reader.analyzePackage(p.join(modelPath, 'lib'));
      final result = validateStructuralInvariants(reader.classes);
      final collapsible = result.warnings
          .where((w) => w.contains('§6.1c collapsible-wrapper'))
          .toList();
      // TSMA4 collapsed every meaning-free wrapper; the census (tsma4_census.dart)
      // now reports 0 COLLAPSIBLE. TSMA5's kept wrappers (form-bearing /
      // meaningful-content / shared) are exempt, so the validator flags none.
      expect(collapsible, isEmpty, reason: collapsible.join('\n'));
    });
  });

  group('unit: YRD5 DocSpecsSection base type', () {
    ModelField sectionField(String name,
            [List<AnnotationData> annotations = const []]) =>
        ModelField(
          name: name,
          typeName: 'DocSpecsSection?',
          isNullable: true,
          isContentSection: true,
          annotations: annotations,
        );

    ModelField sectionListField(String name,
            [List<AnnotationData> annotations = const []]) =>
        ModelField(
          name: name,
          typeName: 'List<DocSpecsSection>',
          isList: true,
          listElementTypeName: 'DocSpecsSection',
          listElementIsComplex: false,
          listElementIsContentSection: true,
          annotations: annotations,
        );

    test('classifyField treats DocSpecsSection members as content', () {
      expect(MetaTreeBuilder.classifyField(sectionField('summary')),
          MetaNodeKind.content);
      expect(MetaTreeBuilder.classifyField(sectionListField('notes')),
          MetaNodeKind.list);
    });

    test('metaTypeName normalizes to the pre-YRD5 String shapes', () {
      final single = sectionField('summary');
      expect(single.metaTypeName, 'String?');
      expect(single.isContentLike, isTrue);
      expect(single.isLeaf, isTrue);
      expect(single.isComplex, isFalse);
      final list = sectionListField('notes');
      expect(list.metaTypeName, 'List<String>');
      expect(list.metaListElementTypeName, 'String');
    });

    test('ModelJsonExporter exports DocSpecsSection members byte-compatibly',
        () {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', [
          AnnotationData('SectionId', {'id': 'DC00'}),
        ], [
          sectionField('summary', [
            AnnotationData('SectionId', {'id': 'DC00-SUM'}),
          ]),
          sectionListField('notes', [
            AnnotationData('SectionId', {'id': 'DC00-NTS-LST'}),
            AnnotationData('SectionIdPattern', {'pattern': 'DC00-NTS-xxx'}),
          ]),
        ]),
      };
      final json = ModelJsonExporter(classes).export();
      final doc = (json['classes'] as Map)['Doc'] as Map;
      final fields = (doc['fields'] as List).cast<Map>();
      final byName = {for (final f in fields) f['name'] as String: f};
      expect(byName['summary']!['kind'], 'content');
      expect(byName['summary']!.containsKey('type'), isFalse,
          reason: 'content fields must not leak the DocSpecsSection type name');
      expect(byName['notes']!['kind'], 'list');
      expect(byName['notes']!['elementType'], 'String');
      expect(byName['notes']!['elementIsComplex'], false);
    });

    test('§6.1: a non-"content" DocSpecsSection member requires @SectionId',
        () {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', [
          AnnotationData('SectionId', {'id': 'DC00'}),
        ], [
          sectionField('summary'), // deliberately missing @SectionId
        ]),
      };
      final result = validateModel(classes, 'Doc');
      expect(
        result.errors.any((e) =>
            e.contains('§6.1 field-shape') && e.contains('Doc.summary')),
        isTrue,
        reason: result.errors.join('\n'),
      );
    });

    test('§6.1: List<DocSpecsSection> is the inline content list shape', () {
      ModelClass docWith(ModelField field) => _cls('Doc', [
            AnnotationData('SectionId', {'id': 'DC00'}),
          ], [
            field
          ]);
      // Without the annotated pair → error (same rule as List<String>).
      final bare = validateModel(
          {'Doc': docWith(sectionListField('notes'))}, 'Doc');
      expect(
        bare.errors.any(
            (e) => e.contains('Doc.notes') && e.contains('not allowed')),
        isTrue,
        reason: bare.errors.join('\n'),
      );
      // With @SectionId + @SectionIdPattern → accepted.
      final annotated = validateModel({
        'Doc': docWith(sectionListField('notes', [
          AnnotationData('SectionId', {'id': 'DC00-NTS-LST'}),
          AnnotationData('SectionIdPattern', {'pattern': 'DC00-NTS-xxx'}),
        ])),
      }, 'Doc');
      expect(
        annotated.errors
            .where((e) => e.contains('Doc.notes') && e.contains('not allowed')),
        isEmpty,
        reason: annotated.errors.join('\n'),
      );
    });

    test('YRD5 extends-invariant activates once any class extends the base',
        () {
      ModelClass cls(String name, String id, List<ModelField> fields,
              {bool extendsBase = false}) =>
          ModelClass(
            name: name,
            annotations: [
              AnnotationData('SectionId', {'id': id})
            ],
            fields: fields,
            extendsDocSpecsSection: extendsBase,
          );

      // Inactive: no class extends DocSpecsSection → no YRD5 errors.
      final legacy = validateModel({
        'Doc': cls('Doc', 'DC00', [_field('child', 'Child')]),
        'Child': cls('Child', 'DC00-CHD', const []),
      }, 'Doc');
      expect(legacy.errors.where((e) => e.contains('YRD5')), isEmpty);

      // Active: one class extends, the other does not → error for the other.
      final mixed = validateModel({
        'Doc':
            cls('Doc', 'DC00', [_field('child', 'Child')], extendsBase: true),
        'Child': cls('Child', 'DC00-CHD', const []),
      }, 'Doc');
      expect(
        mixed.errors.any(
            (e) => e.contains('YRD5') && e.contains('Child')),
        isTrue,
        reason: mixed.errors.join('\n'),
      );

      // Fully adopted → no YRD5 errors.
      final adopted = validateModel({
        'Doc':
            cls('Doc', 'DC00', [_field('child', 'Child')], extendsBase: true),
        'Child': cls('Child', 'DC00-CHD', const [], extendsBase: true),
      }, 'Doc');
      expect(adopted.errors.where((e) => e.contains('YRD5')), isEmpty);
    });

    test('SpecOpsGenerator slots DocSpecsSection members as child nodes', () {
      final classes = <String, ModelClass>{
        'Doc': _cls('Doc', [
          AnnotationData('SectionId', {'id': 'DC00'}),
        ], [
          ModelField(name: 'content', typeName: 'String?', isNullable: true),
          sectionField('summary', [
            AnnotationData('SectionId', {'id': 'DC00-SUM'}),
          ]),
          sectionListField('notes', [
            AnnotationData('SectionId', {'id': 'DC00-NTS-LST'}),
            AnnotationData('SectionIdPattern', {'pattern': 'DC00-NTS-xxx'}),
          ]),
        ]),
      };
      final code = SpecOpsGenerator(classes).generate();
      // The base type itself is registered as a content leaf.
      expect(code, contains('SpecRegistry.register(DocSpecsSection,'));
      // Single member → SpecSlot.node with the real Dart cast.
      expect(code,
          contains('n.summary = v as DocSpecsSection?'));
      // List member → SpecSlot.list with the real element cast.
      expect(code, contains('n.notes = v.cast<DocSpecsSection>()'));
      // The canonical content String stays the yaml scalar.
      expect(code, contains('yamlScalar: (o) => (o as Doc).content'));
    });
  });
}
