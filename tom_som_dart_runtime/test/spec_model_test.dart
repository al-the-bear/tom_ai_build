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

    test('an enum field carries its Dart enum type name and values', () {
      final prob =
          fixtureModel().classNamed('Risk')!.fieldNamed('probability')!;
      expect(prob.kind, SpecFieldKind.enumValue);
      expect(prob.enumType, 'Probability');
      expect(prob.enumValues, <String>['low', 'medium', 'high']);
    });
  });

  group('model version string (§2.1)', () {
    test('somModelVersionString takes major.minor from the label', () {
      expect(somModelVersionString(1, '1.0.0+7.1f49ac3'), '1.0');
      // A genuine authoring minor in the stamp is preserved, not flattened.
      expect(somModelVersionString(2, '2.3.1+5.deadbee'), '2.3');
      // Build metadata after `+` is ignored.
      expect(somModelVersionString(3, '3.4.0'), '3.4');
    });

    test('somModelVersionString falls back to <major>.0 when unstamped', () {
      expect(somModelVersionString(1, null), '1.0');
      expect(somModelVersionString(4, ''), '4.0');
      // A malformed label (no numeric minor) also falls back to the counter.
      expect(somModelVersionString(2, 'weird'), '2.0');
    });

    test('SpecModel.modelVersionString reports the stamped major.minor', () {
      // The fixture is stamped 0.7.0+7.abc1234.
      expect(fixtureModel().modelVersionString, '0.7');
    });

    test('SpecModel.modelVersionString falls back for an unstamped model', () {
      final model = SpecModel.fromJson(
          <String, dynamic>{'roots': <dynamic>[], 'classes': <String, dynamic>{}});
      expect(model.modelVersionString, '0.0');
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

  group('SpecModel.rootByType (item 12)', () {
    SpecModel twoRootModel() => SpecModel.fromJson(<String, dynamic>{
          'roots': <dynamic>[
            {'type': 'Alpha', 'title': 'Alpha Doc', 'sectionId': 'A00'},
            {'type': 'Beta', 'title': 'Beta Doc', 'sectionId': 'B00'},
          ],
          'classes': <String, dynamic>{},
        });

    test('returns the root whose type matches', () {
      final model = twoRootModel();
      expect(model.rootByType('Alpha').title, 'Alpha Doc');
      expect(model.rootByType('Beta').sectionId, 'B00');
    });

    test('throws ArgumentError naming the missing and available types', () {
      final model = twoRootModel();
      expect(
        () => model.rootByType('Gamma'),
        throwsA(isA<ArgumentError>()
            .having((e) => e.message, 'message', contains('Alpha'))
            .having((e) => e.message, 'message', contains('Beta'))),
      );
    });
  });
}
