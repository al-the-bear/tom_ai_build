/// Field classification at the source rather than at fifteen call sites.
///
/// `ModelField.isComplex` was a triple negation — not a leaf, not a list, not a
/// section — and `isLeaf` admitted only `String`, `String?` and enums. So an
/// `int`, `bool`, `num`, `double` or `DateTime` member fell through and
/// reported `isComplex == true`: the reader claimed a primitive was an
/// expandable class.
///
/// Three consumers guarded against that with their own primitive test before
/// consulting `isComplex`; roughly fifteen did not, and would have tried to
/// descend into an `int` member as though it named a class. It never fired
/// because `tom_specs_model` happens to declare no non-`String` primitive
/// section member — safety by accident, which is what these tests replace.
library;

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

ModelField _field(String name, String typeName, {bool isEnum = false}) =>
    ModelField(name: name, typeName: typeName, isEnum: isEnum);

void main() {
  group('ModelField primitive classification', () {
    test('a non-String primitive is not complex', () {
      for (final type in ['int', 'double', 'bool', 'num', 'DateTime']) {
        final field = _field('count', type);
        expect(
          field.isComplex,
          isFalse,
          reason:
              '$type reported as an expandable class; every unguarded '
              'consumer would try to descend into it',
        );
      }
    });

    test('a nullable non-String primitive is not complex either', () {
      for (final type in ['int?', 'double?', 'bool?', 'num?', 'DateTime?']) {
        expect(_field('count', type).isComplex, isFalse, reason: type);
      }
    });

    test('isPrimitive names the set once', () {
      for (final type in [
        'String',
        'String?',
        'int',
        'int?',
        'double',
        'bool',
        'num',
        'DateTime',
      ]) {
        expect(_field('x', type).isPrimitive, isTrue, reason: type);
      }
      for (final type in ['DocumentControl', 'Requirements', 'SomeClass?']) {
        expect(_field('x', type).isPrimitive, isFalse, reason: type);
      }
    });

    test('a class member is still complex', () {
      expect(_field('control', 'DocumentControl').isComplex, isTrue);
      expect(_field('control', 'DocumentControl?').isComplex, isTrue);
    });

    test('String and enum members are still leaves, not complex', () {
      expect(_field('content', 'String').isLeaf, isTrue);
      expect(_field('content', 'String').isComplex, isFalse);
      expect(_field('p', 'Priority', isEnum: true).isLeaf, isTrue);
      expect(_field('p', 'Priority', isEnum: true).isComplex, isFalse);
    });

    test(
      'a list is neither primitive-complex nor a leaf, whatever it holds',
      () {
        final list = ModelField(
          name: 'counts',
          typeName: 'List<int>',
          isList: true,
          listElementTypeName: 'int',
        );
        expect(list.isComplex, isFalse);
        expect(list.isLeaf, isFalse);
      },
    );
  });

  group('the classification reaches its consumers', () {
    test('MetaTreeBuilder classifies a non-String primitive as a scalar', () {
      // Already correct — it applied its own guard first. Pinned so the fix
      // below cannot change it.
      expect(
        MetaTreeBuilder.classifyField(_field('count', 'int')),
        MetaNodeKind.scalar,
      );
    });

    test('an int member classifies as a scalar without a caller-side guard', () {
      // The property the fix buys: a consumer that asks `isComplex` alone now
      // gets the right answer, so the fifteen unguarded call sites are correct
      // by construction rather than by luck.
      final field = _field('capacity', 'int');
      expect(field.isComplex, isFalse);
      expect(field.isPrimitive, isTrue);
    });
  });

  group('MetaNode keeps the two section ids apart (SOM §7.1)', () {
    // SOM §7.1: "A field-level `@SectionId` populates `sectionId`; the target
    // class's own `@SectionId` populates `classSectionId` — the two are **not
    // merged**. The path segment uses `sectionId` (else member name; never the
    // class fallback); the yaml/md key id prefers `sectionId` and falls back to
    // `classSectionId` for section/complex nodes."
    //
    // `_SlotCollector._first` searched the field annotations and then the class
    // ones, so a member with no id of its own inherited the class's into
    // `sectionId`. A consumer could not tell the two apart, and therefore could
    // not apply the path-segment rule at all.

    ModelClass root(List<ModelField> fields) => ModelClass(
      name: 'Root',
      annotations: [
        AnnotationData('Document', {'name': 'Demo', 'description': 'd'}),
        AnnotationData('SectionId', {'id': 'ROOT'}),
      ],
      fields: fields,
    );

    ModelClass target({String? classId}) => ModelClass(
      name: 'Target',
      annotations: [
        if (classId != null) AnnotationData('SectionId', {'id': classId}),
      ],
      fields: [ModelField(name: 'content', typeName: 'String')],
    );

    MetaNode childOf(Map<String, ModelClass> classes) =>
        MetaTreeBuilder(classes).build('Root').children.single;

    test('a member with no @SectionId does not inherit the class id', () {
      final node = childOf({
        'Root': root([ModelField(name: 'target', typeName: 'Target')]),
        'Target': target(classId: 'TGT'),
      });
      expect(
        node.sectionId,
        isNull,
        reason:
            'sectionId is field-level only; the path segment must fall '
            'back to the member name, never to the class id',
      );
      expect(node.classSectionId, 'TGT');
    });

    test('a member with its own @SectionId keeps it, and the class id too', () {
      final node = childOf({
        'Root': root([
          ModelField(
            name: 'target',
            typeName: 'Target',
            annotations: [
              AnnotationData('SectionId', {'id': 'FLD'}),
            ],
          ),
        ]),
        'Target': target(classId: 'TGT'),
      });
      expect(node.sectionId, 'FLD');
      expect(
        node.classSectionId,
        'TGT',
        reason: 'both are carried; a consumer chooses by rule, not by luck',
      );
    });

    test('keyId states the yaml/md rule once', () {
      final inherited = childOf({
        'Root': root([ModelField(name: 'target', typeName: 'Target')]),
        'Target': target(classId: 'TGT'),
      });
      expect(
        inherited.keyId,
        'TGT',
        reason: 'a transparent section keys on its class id',
      );
      expect(
        inherited.pathSegment,
        'target',
        reason: 'while pathing on its member name',
      );

      final own = childOf({
        'Root': root([
          ModelField(
            name: 'target',
            typeName: 'Target',
            annotations: [
              AnnotationData('SectionId', {'id': 'FLD'}),
            ],
          ),
        ]),
        'Target': target(classId: 'TGT'),
      });
      expect(own.keyId, 'FLD');
      expect(own.pathSegment, 'FLD');
    });

    test('a content node never takes the class fallback', () {
      // The key-id fallback is for section/complex nodes only. A content leaf
      // that inherited one would key on a section id it does not own.
      final node = childOf({
        'Root': root([ModelField(name: 'content', typeName: 'String')]),
      });
      expect(node.kind, MetaNodeKind.content);
      expect(node.classSectionId, isNull);
      expect(node.keyId, isNull);
    });
  });

  group('the consumers survive an int member', () {
    // The deliverable the todo asked for: the current safety is an accident of
    // what `tom_specs_model` happens to contain — zero non-`String` primitive
    // section members — so the first `int` anyone adds is what breaks the
    // validator and the outliner. These declare one and assert both cope.

    Map<String, ModelClass> modelWithIntMember() => {
      'Root': ModelClass(
        name: 'Root',
        annotations: [
          AnnotationData('Document', {'name': 'Demo', 'description': 'd'}),
          AnnotationData('SectionId', {'id': 'DEMO'}),
        ],
        fields: [
          ModelField(name: 'content', typeName: 'String'),
          ModelField(name: 'capacity', typeName: 'int'),
        ],
      ),
    };

    test('the validator reports the int rather than descending into it', () {
      final result = validateModel(modelWithIntMember(), 'Root');

      // `tom_specs_model_rules.md` §5.1 forbids a non-String primitive member outright, so the RIGHT
      // outcome is a named error. What must not happen is a crash, or the
      // member being resolved as a class named `int`.
      expect(
        result.errors.where((e) => e.contains('Root.capacity')),
        isNotEmpty,
        reason: 'the int member should be reported by name',
      );
      expect(
        result.errors.any((e) => e.contains('type "int" not allowed')),
        isTrue,
        reason:
            'and reported as the shape rule it breaks, not as a missing '
            'class',
      );
    });

    test('the outliner renders the int on the leaf line, not as a subtree', () {
      final outline = OutlineWriter(
        classes: modelWithIntMember(),
      ).generate('Root');

      // The failure was SILENT, not a crash, which is why it survived: with
      // `isComplex` true the outliner emitted
      //
      //     - content
      //     - capacity: `int`
      //
      // giving the member its own expandable-class line, empty because `int`
      // names no class in the registry. Correct is one leaf line:
      //
      //     - content, capacity
      expect(outline, contains('- content, capacity'));
      expect(
        outline,
        isNot(contains('- capacity:')),
        reason:
            'a line of its own means the outliner treated the int as an '
            'expandable class and found nothing to expand',
      );
    });

    test('the meta tree gives it a scalar node', () {
      final root = MetaTreeBuilder(modelWithIntMember()).build('Root');
      final capacity = root.children.firstWhere(
        (c) => c.memberName == 'capacity',
      );
      expect(capacity.kind, MetaNodeKind.scalar);
      expect(capacity.children, isEmpty);
    });
  });
}
