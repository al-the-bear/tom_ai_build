import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  final refl = SpecReflection(fixtureModel());

  group('enumeration', () {
    test('roots and classes', () {
      expect(refl.roots.map((r) => r.type), <String>['ProjectDefinition']);
      expect(
        refl.classes.map((c) => c.name).toSet(),
        <String>{'ProjectDefinition', 'Risk', 'CurrentSituation'},
      );
    });

    test('fields and annotations of a class', () {
      expect(
        refl.fieldsOf('ProjectDefinition').map((f) => f.name),
        <String>['vision', 'owner', 'risks', 'tags', 'situation'],
      );
      expect(
        refl.annotationsOf('ProjectDefinition').map((a) => a.name),
        containsAll(<String>['Document', 'SectionId']),
      );
      expect(
        refl.fieldAnnotations('ProjectDefinition', 'risks').single.name,
        'Min',
      );
    });
  });

  group('resolve by path', () {
    test('bare root', () {
      final res = refl.resolve('PD00')!;
      expect(res.kind, SpecNodeKind.root);
      expect(res.targetClass!.name, 'ProjectDefinition');
    });

    test('content leaf', () {
      final res = refl.resolve('PD00/vision')!;
      expect(res.kind, SpecNodeKind.content);
      expect(res.isValueLeaf, isTrue);
      expect(res.field!.name, 'vision');
    });

    test('form section', () {
      final res = refl.resolve('PD00/owner')!;
      expect(res.kind, SpecNodeKind.form);
      expect(res.field!.formFields, hasLength(2));
    });

    test('list container', () {
      final res = refl.resolve('PD00/risks')!;
      expect(res.kind, SpecNodeKind.list);
    });

    test('complex list item descends into the element class', () {
      final res = refl.resolve('PD00/risks-1')!;
      expect(res.kind, SpecNodeKind.listItemComplex);
      expect(res.targetClass!.name, 'Risk');
    });

    test('field inside a list item', () {
      final res = refl.resolve('PD00/risks-2/title')!;
      expect(res.kind, SpecNodeKind.content);
      expect(res.field!.name, 'title');
    });

    test('enum inside a list item', () {
      final res = refl.resolve('PD00/risks-1/prob')!;
      expect(res.kind, SpecNodeKind.enumValue);
    });

    test('scalar list item', () {
      final res = refl.resolve('PD00/tags-1')!;
      expect(res.kind, SpecNodeKind.listItemScalar);
      expect(res.isValueLeaf, isTrue);
    });

    test('complex field collapses into its class', () {
      final res = refl.resolve('PD00/situation/summary')!;
      expect(res.kind, SpecNodeKind.content);
      expect(res.field!.name, 'summary');
    });

    test('unknown root, unknown field, and over-deep leaf are unresolvable',
        () {
      expect(refl.resolve('NOPE'), isNull);
      expect(refl.resolve('PD00/missing'), isNull);
      expect(refl.resolve('PD00/vision/extra'), isNull);
      // A list path needs a `-<seq>` to descend.
      expect(refl.resolve('PD00/risks/title'), isNull);
    });
  });
}
