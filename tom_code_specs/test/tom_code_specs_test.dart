import 'package:tom_code_specs/tom_code_specs.dart';
import 'package:test/test.dart';

void main() {
  group('CodeSpecsDocument', () {
    test('constructs with empty section lists and null prose', () {
      final doc = CodeSpecsDocument();
      expect(doc.content, isNull);
      expect(doc.tagline, isNull);
      expect(doc.inputs, isEmpty);
      expect(doc.produces, isEmpty);
      expect(doc.components, isEmpty);
      expect(doc.exitCriteria, isEmpty);
    });

    test('holds authored sections and components', () {
      final doc = CodeSpecsDocument()
        ..tagline = 'Skeletal application — compiles but does not execute'
        ..inputs.add(CodeSpecsInput()..content = 'All Phase 3 documents')
        ..components.add(CodeSpecsComponent()
          ..content = 'UI Elements — Flutter widgets — UP (UI Prototype)');
      expect(doc.tagline, contains('Skeletal'));
      expect(doc.inputs.single.content, 'All Phase 3 documents');
      expect(doc.components.single.content, contains('UI Elements'));
    });
  });

  group('ImplementationDocument', () {
    test('constructs with empty section lists and null prose', () {
      final doc = ImplementationDocument();
      expect(doc.content, isNull);
      expect(doc.tagline, isNull);
      expect(doc.inputs, isEmpty);
      expect(doc.produces, isEmpty);
      expect(doc.levels, isEmpty);
      expect(doc.exitCriteria, isEmpty);
    });

    test('holds ordered implementation levels', () {
      final doc = ImplementationDocument()
        ..levels.add(ImplementationLevel()
          ..content = 'Level 1 · Database Schema — no dependencies')
        ..levels.add(ImplementationLevel()
          ..content = 'Level 2 · Data Models — depends on the schema');
      expect(doc.levels, hasLength(2));
      expect(doc.levels.first.content, contains('Level 1'));
    });
  });
}
