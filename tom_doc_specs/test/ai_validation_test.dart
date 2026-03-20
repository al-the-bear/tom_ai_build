import 'package:test/test.dart';
import 'package:tom_doc_specs/src/models/schema/doc_spec_schema.dart';
import 'package:tom_doc_specs/src/models/schema/document_structure.dart';
import 'package:tom_doc_specs/src/models/schema/section_type_def.dart';
import 'package:tom_doc_specs/src/models/spec_doc.dart';
import 'package:tom_doc_specs/src/models/spec_section.dart';
import 'package:tom_doc_specs/src/validation/ai_validator.dart';
import 'package:tom_doc_specs/src/validation/validation_error.dart';
import 'package:tom_doc_specs/src/validation/validator.dart';

/// Mock AiValidator that records calls and returns configurable results.
class MockAiValidator implements AiValidator {
  final List<({String rawPrompt, String expandedPrompt, String sectionId})> calls = [];
  final Map<String, String?> results; // sectionId -> result

  MockAiValidator({this.results = const {}});

  @override
  Future<String?> validate({
    required String rawPrompt,
    required String expandedPrompt,
    required SpecSection section,
    required SpecDoc document,
    required SectionTypeDef? sectionTypeDef,
    required DocSpecSchema schema,
  }) async {
    calls.add((rawPrompt: rawPrompt, expandedPrompt: expandedPrompt, sectionId: section.id));
    return results[section.id];
  }
}

/// Mock AiValidator that throws an exception.
class FailingAiValidator implements AiValidator {
  @override
  Future<String?> validate({
    required String rawPrompt,
    required String expandedPrompt,
    required SpecSection section,
    required SpecDoc document,
    required SectionTypeDef? sectionTypeDef,
    required DocSpecSchema schema,
  }) async {
    throw Exception('Network timeout');
  }
}

void main() {
  group('AI Validation Integration', () {
    late DocSpecSchema schema;

    DocSpecSchema makeSchema({
      Map<String, SectionTypeDef>? sectionTypes,
    }) {
      return DocSpecSchema(
        id: 'test',
        version: '1.0',
        sectionTypes: sectionTypes ?? {},
        document: const DocumentStructure(sections: {}),
      );
    }

    SpecSection makeSection({
      String id = 'sec-001',
      String name = 'Section',
      String text = 'Content',
      String? type,
      int lineNumber = 10,
    }) {
      return SpecSection(
        index: 0,
        lineNumber: lineNumber,
        rawHeadline: name,
        name: name,
        id: id,
        text: text,
        type: type,
      );
    }

    SpecDoc makeDocument({
      required List<SpecSection> sections,
      String schemaId = 'test/1.0',
    }) {
      return SpecDoc(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Doc',
        name: 'Doc',
        id: 'doc',
        text: '',
        fields: {'schema': schemaId},
        filenameWithPath: 'test.md',
        loadTimestamp: '2025-01-01T00:00:00',
        filename: 'test.md',
        fullPath: '/test/test.md',
        workspacePath: 'test.md',
        project: '',
        projectPath: '',
        workspaceRoot: '/test',
        projectRoot: '',
        hierarchyDepth: 0,
        schemaId: schemaId,
        sections: sections,
      );
    }

    test('validateAsync invokes AiValidator for sections with validationPrompt', () async {
      schema = makeSchema(sectionTypes: {
        'requirement': SectionTypeDef(
          name: 'requirement',
          prefix: 'req',
          validationPrompt: r'Verify ${id} is complete.',
        ),
      });

      final section = makeSection(id: 'req-001', type: 'requirement');
      final doc = makeDocument(sections: [section]);

      final mockAi = MockAiValidator(results: {'req-001': null});
      final validator = DocSpecsValidator(schema: schema, aiValidator: mockAi);

      final errors = await validator.validateAsync(doc);

      expect(mockAi.calls, hasLength(1));
      expect(mockAi.calls.first.sectionId, 'req-001');
      expect(mockAi.calls.first.expandedPrompt, 'Verify req-001 is complete.');
      expect(
        errors.where((e) => e.category == ValidationErrorCategory.aiValidation),
        isEmpty,
      );
    });

    test('validateAsync reports AI validation failures', () async {
      schema = makeSchema(sectionTypes: {
        'requirement': SectionTypeDef(
          name: 'requirement',
          prefix: 'req',
          validationPrompt: r'Check ${id}.',
        ),
      });

      final section = makeSection(id: 'req-002', type: 'requirement');
      final doc = makeDocument(sections: [section]);

      final mockAi = MockAiValidator(results: {'req-002': 'Missing acceptance criteria'});
      final validator = DocSpecsValidator(schema: schema, aiValidator: mockAi);

      final errors = await validator.validateAsync(doc);

      final aiErrors = errors.where((e) => e.category == ValidationErrorCategory.aiValidation).toList();
      expect(aiErrors, hasLength(1));
      expect(aiErrors.first.message, contains('Missing acceptance criteria'));
      expect(aiErrors.first.sectionId, 'req-002');
    });

    test('validateAsync handles AI validator exceptions gracefully', () async {
      schema = makeSchema(sectionTypes: {
        'requirement': SectionTypeDef(
          name: 'requirement',
          prefix: 'req',
          validationPrompt: r'Check ${id}.',
        ),
      });

      final section = makeSection(id: 'req-003', type: 'requirement');
      final doc = makeDocument(sections: [section]);

      final validator = DocSpecsValidator(schema: schema, aiValidator: FailingAiValidator());

      final errors = await validator.validateAsync(doc);

      final aiErrors = errors.where((e) => e.category == ValidationErrorCategory.aiValidation).toList();
      expect(aiErrors, hasLength(1));
      expect(aiErrors.first.message, contains('AI validation failed'));
      expect(aiErrors.first.message, contains('Network timeout'));
    });

    test('validateAsync skips AI when no aiValidator is set', () async {
      schema = makeSchema(sectionTypes: {
        'requirement': SectionTypeDef(
          name: 'requirement',
          prefix: 'req',
          validationPrompt: r'Check ${id}.',
        ),
      });

      final section = makeSection(id: 'req-004', type: 'requirement');
      final doc = makeDocument(sections: [section]);

      final validator = DocSpecsValidator(schema: schema);

      final errors = await validator.validateAsync(doc);

      expect(
        errors.where((e) => e.category == ValidationErrorCategory.aiValidation),
        isEmpty,
      );
    });

    test('validateAsync skips sections without validationPrompt', () async {
      schema = makeSchema(sectionTypes: {
        'note': SectionTypeDef(
          name: 'note',
          prefix: 'note',
          // no validationPrompt
        ),
      });

      final section = makeSection(id: 'note-001', type: 'note');
      final doc = makeDocument(sections: [section]);

      final mockAi = MockAiValidator();
      final validator = DocSpecsValidator(schema: schema, aiValidator: mockAi);

      await validator.validateAsync(doc);

      expect(mockAi.calls, isEmpty);
    });

    test('sync validate never calls AI', () {
      schema = makeSchema(sectionTypes: {
        'requirement': SectionTypeDef(
          name: 'requirement',
          prefix: 'req',
          validationPrompt: r'Check ${id}.',
        ),
      });

      final section = makeSection(id: 'req-005', type: 'requirement');
      final doc = makeDocument(sections: [section]);

      final mockAi = MockAiValidator();
      final validator = DocSpecsValidator(schema: schema, aiValidator: mockAi);

      validator.validate(doc);

      expect(mockAi.calls, isEmpty);
    });

    test('SectionDef.validationPrompt overrides type validationPrompt', () async {
      // The type has a default prompt, but the document section def overrides it
      schema = DocSpecSchema(
        id: 'test',
        version: '1.0',
        sectionTypes: {
          'requirement': SectionTypeDef(
            name: 'requirement',
            prefix: 'req',
            validationPrompt: r'Type prompt for ${id}.',
          ),
        },
        document: DocumentStructure(sections: {
          'req-010': SectionDef(
            sectionType: 'requirement',
            validationPrompt: r'Override prompt for ${id}.',
          ),
        }),
      );

      final section = makeSection(id: 'req-010', type: 'requirement');
      final doc = makeDocument(sections: [section]);

      final mockAi = MockAiValidator(results: {'req-010': null});
      final validator = DocSpecsValidator(schema: schema, aiValidator: mockAi);

      await validator.validateAsync(doc);

      expect(mockAi.calls, hasLength(1));
      // Should use the SectionDef override, not the type's prompt
      expect(mockAi.calls.first.expandedPrompt, 'Override prompt for req-010.');
    });

    test('subsectionValidationPrompt validates all children', () async {
      schema = DocSpecSchema(
        id: 'test',
        version: '1.0',
        sectionTypes: {
          'container': SectionTypeDef(
            name: 'container',
            prefix: 'cont',
          ),
          'item': SectionTypeDef(
            name: 'item',
            prefix: 'item',
          ),
        },
        document: DocumentStructure(sections: {
          'cont-001': SectionDef(
            sectionType: 'container',
            subsectionValidationPrompt: r'Validate child ${id}.',
          ),
        }),
      );

      final child1 = makeSection(id: 'item-001', type: 'item');
      final child2 = makeSection(id: 'item-002', type: 'item');
      final parent = SpecSection(
        index: 0,
        lineNumber: 5,
        rawHeadline: 'Container',
        name: 'Container',
        id: 'cont-001',
        text: '',
        type: 'container',
        sections: [child1, child2],
      );
      final doc = makeDocument(sections: [parent]);

      final mockAi = MockAiValidator(results: {
        'item-001': null,
        'item-002': 'Missing description',
      });
      final validator = DocSpecsValidator(schema: schema, aiValidator: mockAi);

      final errors = await validator.validateAsync(doc);

      // Should have been called for both children
      final subsectionCalls = mockAi.calls
          .where((c) => c.sectionId == 'item-001' || c.sectionId == 'item-002')
          .toList();
      expect(subsectionCalls, hasLength(2));
      expect(subsectionCalls[0].expandedPrompt, 'Validate child item-001.');
      expect(subsectionCalls[1].expandedPrompt, 'Validate child item-002.');

      // One child failed AI validation
      final aiErrors = errors
          .where((e) => e.category == ValidationErrorCategory.aiValidation)
          .toList();
      expect(aiErrors, hasLength(1));
      expect(aiErrors.first.sectionId, 'item-002');
    });

    test('falls back to type validationPrompt when SectionDef has none', () async {
      schema = DocSpecSchema(
        id: 'test',
        version: '1.0',
        sectionTypes: {
          'requirement': SectionTypeDef(
            name: 'requirement',
            prefix: 'req',
            validationPrompt: r'Type prompt for ${id}.',
          ),
        },
        document: DocumentStructure(sections: {
          'req-020': SectionDef(
            sectionType: 'requirement',
            // No validationPrompt override — should fall back to type's
          ),
        }),
      );

      final section = makeSection(id: 'req-020', type: 'requirement');
      final doc = makeDocument(sections: [section]);

      final mockAi = MockAiValidator(results: {'req-020': null});
      final validator = DocSpecsValidator(schema: schema, aiValidator: mockAi);

      await validator.validateAsync(doc);

      expect(mockAi.calls, hasLength(1));
      expect(mockAi.calls.first.expandedPrompt, 'Type prompt for req-020.');
    });
  });
}
