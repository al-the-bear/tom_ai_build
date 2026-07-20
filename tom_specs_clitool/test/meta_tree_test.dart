/// DR2 — canonical language-neutral metadata tree extraction.
///
/// Unit tests exercise the slot mapping on a synthetic model (a known class's
/// full annotation set round-trips); end-to-end tests build the tree for all
/// 13 document roots of the real `tom_specs_model` and assert that *every*
/// annotation on every reachable class/field is represented on its node —
/// either in a dedicated slot or in the lossless `extra` list.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

// ---------------------------------------------------------------------------
// Synthetic model helpers
// ---------------------------------------------------------------------------

ModelClass _cls(
  String name, {
  List<AnnotationData> annotations = const [],
  List<ModelField> fields = const [],
  String docComment = '',
}) =>
    ModelClass(
      name: name,
      annotations: annotations,
      fields: fields,
      docComment: docComment,
    );

void main() {
  group('MetaTreeBuilder unit (synthetic model)', () {
    test('DR2-U1: full annotation set of a known class round-trips into slots '
        '[2026-07-07]', () {
      final classes = <String, ModelClass>{
        'Root': _cls(
          'Root',
          docComment: 'Root class doc.',
          annotations: [
            AnnotationData('Document', {
              'name': 'Demo Document',
              'description': 'A demo.',
              'basedOn': ['D00SolutionBlueprint'],
            }),
            AnnotationData('SectionId', {'id': 'DEMO'}),
            AnnotationData('ContentHelp', {'guidance': 'Fill the demo.'}),
            AnnotationData('Comment', {'text': 'Seeds → QAP'}),
            AnnotationData('MapsTo', {'documentClass': 'InformationModel'}),
            AnnotationData(
                'DetailedIn', {'documentClass': 'D06InformationModel'}),
            // No dedicated slot — must land in `extra`.
            AnnotationData('StandardReferences', {
              'standards': ['ISO 25010'],
            }),
          ],
          fields: [
            ModelField(
              name: 'intro',
              typeName: 'Intro',
              docComment: 'Member doc wins.',
              annotations: [
                AnnotationData('SerializationOrder', {'order': 0}),
                // Field-level @SectionId overrides the target class's.
                AnnotationData('SectionId', {'id': 'INSC2'}),
                AnnotationData('Unused'),
              ],
            ),
            ModelField(
              name: 'summary',
              typeName: 'String?',
              annotations: [
                AnnotationData('SerializationOrder', {'order': 1}),
                AnnotationData('SectionId', {'id': 'SUMM'}),
                AnnotationData(
                    'ContentType', {'type': 'text', 'description': 'Prose'}),
                AnnotationData('TextRequired'),
              ],
            ),
          ],
        ),
        'Intro': _cls(
          'Intro',
          docComment: 'Intro class doc.',
          annotations: [
            AnnotationData('SectionId', {'id': 'INSC'}),
            AnnotationData('ContentHelp', {'guidance': 'Class-level help.'}),
          ],
        ),
      };

      final root = MetaTreeBuilder(classes).build('Root');

      // Root node: class-level slots.
      expect(root.className, 'Root');
      expect(root.memberName, isNull);
      expect(root.sectionId, 'DEMO');
      expect(root.document, isNotNull);
      expect(root.document!.name, 'Demo Document');
      expect(root.document!.description, 'A demo.');
      expect(root.document!.basedOn, ['D00SolutionBlueprint']);
      expect(root.contentHelp, 'Fill the demo.');
      expect(root.comment, 'Seeds → QAP');
      expect(root.mapsTo, 'InformationModel');
      expect(root.detailedIn, 'D06InformationModel');
      expect(root.docComment, 'Root class doc.');
      expect(root.extra.map((e) => e.name), ['StandardReferences']);
      expect(root.extra.single.arguments['standards'], ['ISO 25010']);

      // Complex child: field-level @SectionId wins; class slots merged in.
      final intro = root.children[0];
      expect(intro.memberName, 'intro');
      expect(intro.className, 'Intro');
      expect(intro.kind, MetaNodeKind.complex);
      expect(intro.sectionId, 'INSC2', reason: 'field-level overrides class');
      expect(intro.serializationOrder, 0);
      expect(intro.unused, isTrue);
      expect(intro.contentHelp, 'Class-level help.');
      expect(intro.docComment, 'Member doc wins.');
      expect(intro.classDocComment, 'Intro class doc.');

      // Content child: @ContentType slot + unslotted @TextRequired → extra.
      final summary = root.children[1];
      expect(summary.kind, MetaNodeKind.content);
      expect(summary.sectionId, 'SUMM');
      expect(summary.contentType, isNotNull);
      expect(summary.contentType!.type, 'text');
      expect(summary.contentType!.description, 'Prose');
      expect(summary.extra.map((e) => e.name), ['TextRequired']);
    });

    test('DR2-U2: form fields round-trip with hints and order [2026-07-07]',
        () {
      final classes = <String, ModelClass>{
        'Root': _cls('Root', fields: [
          ModelField(
            name: 'documentControl',
            typeName: 'String?',
            annotations: [AnnotationData('Form')],
            formFields: [
              FormFieldInfo(
                  name: 'version', typeName: 'String', hint: 'e.g. 1.0'),
              FormFieldInfo(name: 'approvedBy', typeName: 'String'),
              FormFieldInfo(name: 'reviewCount', typeName: 'int'),
            ],
          ),
        ]),
      };

      final node = MetaTreeBuilder(classes).build('Root').children.single;
      expect(node.kind, MetaNodeKind.form);
      expect(node.form, isNotNull);
      final fields = node.form!.fields;
      expect(fields.map((f) => f.name), ['version', 'approvedBy', 'reviewCount']);
      expect(fields.map((f) => f.order), [0, 1, 2]);
      expect(fields[0].hint, 'e.g. 1.0');
      expect(fields[1].hint, isNull);
      expect(fields[2].typeName, 'int');
    });

    test('DR2-U3: list fields carry @SectionIdPattern/@Min and expand the '
        'element subtree [2026-07-07]', () {
      final classes = <String, ModelClass>{
        'Root': _cls('Root', fields: [
          ModelField(
            name: 'entries',
            typeName: 'List<GoalEntry>',
            isList: true,
            listElementTypeName: 'GoalEntry',
            listElementIsComplex: true,
            annotations: [
              AnnotationData('SectionIdPattern', {'pattern': 'GOAL-ITEM-xxx'}),
              AnnotationData('Min', {'count': 1}),
            ],
          ),
        ]),
        'GoalEntry': _cls('GoalEntry', fields: [
          ModelField(name: 'content', typeName: 'String?'),
        ]),
      };

      final node = MetaTreeBuilder(classes).build('Root').children.single;
      expect(node.kind, MetaNodeKind.list);
      expect(node.sectionIdPattern, 'GOAL-ITEM-xxx');
      expect(node.min, 1);
      expect(node.typeName, 'List<GoalEntry>');
      expect(node.elementNode, isNotNull);
      expect(node.elementNode!.className, 'GoalEntry');
      expect(node.elementNode!.children.single.kind, MetaNodeKind.content);
    });

    test('DR2-U4: children follow @SerializationOrder, declaration order as '
        'fallback [2026-07-07]', () {
      final classes = <String, ModelClass>{
        'Root': _cls('Root', fields: [
          ModelField(name: 'b', typeName: 'String?', annotations: [
            AnnotationData('SerializationOrder', {'order': 1}),
          ]),
          ModelField(name: 'a', typeName: 'String?', annotations: [
            AnnotationData('SerializationOrder', {'order': 0}),
          ]),
          ModelField(name: 'c', typeName: 'String?'),
        ]),
      };

      final root = MetaTreeBuilder(classes).build('Root');
      expect(root.children.map((c) => c.memberName), ['a', 'b', 'c']);
    });

    test('DR2-U5: recursion is cut with a reference node [2026-07-07]', () {
      final classes = <String, ModelClass>{
        'Node': _cls(
          'Node',
          annotations: [
            AnnotationData('SectionId', {'id': 'NODE'}),
          ],
          fields: [
            ModelField(name: 'child', typeName: 'Node'),
          ],
        ),
      };

      final root = MetaTreeBuilder(classes).build('Node');
      final child = root.children.single;
      expect(child.className, 'Node');
      expect(child.recursive, isTrue);
      expect(child.children, isEmpty);
      // Slots still populated on the reference node.
      expect(child.sectionId, 'NODE');
    });
  });

  group('end-to-end: real tom_specs_model DR2 metadata completeness', () {
    final modelPath = p.normalize(
      p.join(Directory.current.path, '..', 'tom_specs_model'),
    );

    late Map<String, ModelClass> classes;
    late Map<String, MetaNode> roots;

    setUpAll(() async {
      final driver = createAnalysisDriver(modelPath);
      final reader = ModelReader(driver);
      await reader.analyzePackage(p.join(modelPath, 'lib'));
      classes = reader.classes;
      roots = MetaTreeBuilder(classes, enums: reader.enums)
          .buildAllDocumentRoots();
    });

    test('DR2-E1: all 14 document roots build a tree [2026-07-07]', () {
      expect(roots, hasLength(14));
      expect(roots.keys, contains('D00SolutionBlueprint'));
      final sbp = roots['D00SolutionBlueprint']!;
      expect(sbp.sectionId, 'SBP');
      expect(sbp.document, isNotNull);
      expect(sbp.document!.name, 'Solution Blueprint');
      expect(sbp.children, isNotEmpty);
    });

    test(
        'DR2-E2: every annotation on every reachable class/field is '
        'represented on its node (all 14 roots) [2026-07-07]', () {
      final problems = <String>[];

      void check(MetaNode node, {ModelField? sourceField, String path = ''}) {
        final here = '$path/${node.memberName ?? node.className}';
        final cls = classes[node.className];

        // For list nodes, `className` is the *element* class; its class-level
        // annotations live on the elementNode (checked below), not here.
        final expected = <String>{
          if (node.kind != MetaNodeKind.list)
            ...?cls?.annotations.map((a) => a.name),
          ...?sourceField?.annotations.map((a) => a.name),
        };
        final represented = _representedAnnotationNames(node);
        for (final name in expected) {
          if (!represented.contains(name)) {
            problems.add('$here: @$name not represented');
          }
        }

        if (cls != null && !node.recursive) {
          for (final child in node.children) {
            ModelField? field;
            for (final f in cls.fields) {
              if (f.name == child.memberName) {
                field = f;
                break;
              }
            }
            if (field == null) {
              problems.add('$here: child ${child.memberName} has no '
                  'source field on ${cls.name}');
              continue;
            }
            check(child, sourceField: field, path: here);
          }
        }
        if (node.elementNode != null) {
          check(node.elementNode!, path: here);
        }
      }

      for (final entry in roots.entries) {
        check(entry.value, path: entry.key);
      }

      expect(problems, isEmpty,
          reason:
              '${problems.length} gaps:\n${problems.take(40).join('\n')}');
    });

    test(
        'DR2-E3: doc comments and member names round-trip on a known node '
        '[2026-07-07]', () {
      final sbp = roots['D00SolutionBlueprint']!;
      // Every child of the SBP root corresponds to a declared field name.
      final sbpClass = classes['D00SolutionBlueprint']!;
      final fieldNames = sbpClass.fields.map((f) => f.name).toSet();
      for (final child in sbp.children) {
        expect(fieldNames, contains(child.memberName));
      }
      // At least one node in the tree carries a doc comment.
      expect(
        sbp.walk().any((n) => (n.docComment ?? '').isNotEmpty),
        isTrue,
      );
    });
  });
}

/// The annotation names a node represents: dedicated slots that are populated
/// plus the lossless `extra` names.
Set<String> _representedAnnotationNames(MetaNode node) => {
      if (node.sectionId != null) 'SectionId',
      if (node.sectionIdPattern != null) 'SectionIdPattern',
      if (node.serializationOrder != null) 'SerializationOrder',
      if (node.min != null) 'Min',
      if (node.unused) 'Unused',
      if (node.contentType != null) 'ContentType',
      if (node.contentHelp != null) 'ContentHelp',
      if (node.headline != null) 'Headline',
      if (node.comment != null) 'Comment',
      if (node.form != null) 'Form',
      if (node.document != null) 'Document',
      if (node.mapsTo != null) 'MapsTo',
      if (node.detailedIn != null) 'DetailedIn',
      ...node.extra.map((e) => e.name),
    };
