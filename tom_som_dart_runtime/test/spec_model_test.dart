import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  group('SpecModel.fromJson', () {
    test('decodes roots, classes, and the version stamp', () {
      final model = fixtureModel();
      expect(model.modelVersion, 7);
      expect(model.modelVersionLabel, '0.7.0+7.abc1234');
      expect(model.roots, hasLength(1));
      expect(model.roots.single.type, 'ProjectDefinition');
      expect(model.classNamed('ProjectDefinition'), isNotNull);
      expect(model.classNamed('Risk'), isNotNull);
      expect(model.classNamed('Missing'), isNull);
    });

    test('an unstamped export reports modelVersion 0 and null label', () {
      final model = SpecModel.fromJson(
          <String, dynamic>{'roots': <dynamic>[], 'classes': <String, dynamic>{}});
      expect(model.modelVersion, 0);
      expect(model.modelVersionLabel, isNull);
    });

    test('decodes field kinds and shape', () {
      final cls = fixtureModel().classNamed('ProjectDefinition')!;
      final risks = cls.fieldNamed('risks')!;
      expect(risks.kind, SpecFieldKind.list);
      expect(risks.elementType, 'Risk');
      expect(risks.elementIsComplex, isTrue);
      expect(risks.min, 2);
      expect(risks.isExpandable, isTrue);

      final owner = cls.fieldNamed('owner')!;
      expect(owner.kind, SpecFieldKind.form);
      expect(owner.formFields.map((f) => f.name), <String>['name', 'role']);

      final vision = cls.fieldNamed('vision')!;
      expect(vision.kind, SpecFieldKind.content);
      expect(vision.isExpandable, isFalse);
    });
  });

  group('SpecAnnotation', () {
    test('class-level annotations are captured losslessly', () {
      final cls = fixtureModel().classNamed('ProjectDefinition')!;
      final doc = cls.annotation('Document');
      expect(doc, isNotNull);
      expect(doc!.argument('title'), 'Project Definition');
      expect(cls.annotation('SectionId')!.argument('id'), 'PD00');
      expect(cls.annotation('Nope'), isNull);
    });

    test('field-level annotations are captured', () {
      final risks =
          fixtureModel().classNamed('ProjectDefinition')!.fieldNamed('risks')!;
      expect(risks.annotation('Min')!.argument('value'), 2);
    });
  });
}
