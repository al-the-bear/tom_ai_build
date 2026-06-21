import 'package:test/test.dart';
import 'package:tom_doc_specs/src/models/schema/doc_spec_schema.dart';
import 'package:tom_doc_specs/src/models/schema/document_structure.dart';
import 'package:tom_doc_specs/src/models/schema/section_type_def.dart';
import 'package:tom_doc_specs/src/models/spec_doc.dart';
import 'package:tom_doc_specs/src/models/spec_section.dart';
import 'package:tom_doc_specs/src/validation/validation_error.dart';
import 'package:tom_doc_specs/src/validation/validator.dart';

void main() {
  group('SectionTypeDef YAML round-trip', () {
    test('min-count-in-document survives toYaml/fromYaml', () {
      const def = SectionTypeDef(
        name: 'stage',
        prefix: 'stage',
        minCountInDocument: 1,
        maxCountInDocument: 5,
      );
      final yaml = def.toYaml();
      expect(yaml['min-count-in-document'], 1);
      expect(yaml['max-count-in-document'], 5);

      final back = SectionTypeDef.fromYaml('stage', yaml);
      expect(back.minCountInDocument, 1);
      expect(back.maxCountInDocument, 5);
    });

    test('min-count-in-document is omitted when unset', () {
      const def = SectionTypeDef(name: 'note', prefix: 'note');
      expect(def.toYaml().containsKey('min-count-in-document'), isFalse);
      expect(SectionTypeDef.fromYaml('note', def.toYaml()).minCountInDocument,
          isNull);
    });
  });

  group('DocSpecsValidator', () {
    DocSpecSchema makeSchema({
      Map<String, SectionTypeDef>? sectionTypes,
      DocumentStructure? document,
    }) {
      return DocSpecSchema(
        id: 'test',
        version: '1.0',
        sectionTypes: sectionTypes ?? {},
        document: document ?? const DocumentStructure(sections: {}),
      );
    }

    SpecSection makeSection({
      String id = 'sec-001',
      String name = 'Section',
      String text = 'Content',
      String? type,
      int lineNumber = 10,
      int index = 0,
      Map<String, String> fields = const {},
      List<String> tags = const [],
      List<SpecSection>? sections,
    }) {
      return SpecSection(
        index: index,
        lineNumber: lineNumber,
        rawHeadline: name,
        name: name,
        id: id,
        text: text,
        type: type,
        tags: tags,
        fields: fields,
        sections: sections,
      );
    }

    SpecDoc makeDocument({
      required List<SpecSection> sections,
      String schemaId = 'test/1.0',
      Map<String, String> fields = const {},
    }) {
      return SpecDoc(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Doc',
        name: 'Doc',
        id: 'doc',
        text: '',
        fields: {'schema': schemaId, ...fields},
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

    group('schema declaration', () {
      test('reports missing schema declaration', () {
        final schema = makeSchema();
        final doc = SpecDoc(
          index: 0,
          lineNumber: 1,
          rawHeadline: 'Doc',
          name: 'Doc',
          id: 'doc',
          text: '',
          fields: const {},
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
          sections: [],
        );

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.any((e) => e.category == ValidationErrorCategory.schemaDeclaration),
          isTrue,
        );
      });

      test('passes with valid schema declaration', () {
        final schema = makeSchema();
        final doc = makeDocument(sections: []);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.where((e) => e.category == ValidationErrorCategory.schemaDeclaration),
          isEmpty,
        );
      });
    });

    group('section types', () {
      test('reports unknown section type when no prefix matches', () {
        final schema = makeSchema(sectionTypes: {
          'requirement': SectionTypeDef(name: 'requirement', prefix: 'req'),
        });

        // Section with null type and an ID that doesn't match any prefix
        final doc = makeDocument(sections: [
          makeSection(id: 'unk-001', type: null),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.any((e) => e.category == ValidationErrorCategory.sectionType),
          isTrue,
        );
      });
    });

    group('unique IDs', () {
      test('reports duplicate section IDs', () {
        final schema = makeSchema();
        final doc = makeDocument(sections: [
          makeSection(id: 'dup-001', lineNumber: 10),
          makeSection(id: 'dup-001', lineNumber: 20, index: 1),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.any((e) => e.category == ValidationErrorCategory.sectionId),
          isTrue,
        );
      });
    });

    group('count limits', () {
      test('reports exceeding max count in document', () {
        final schema = makeSchema(sectionTypes: {
          'note': SectionTypeDef(name: 'note', prefix: 'note', maxCountInDocument: 1),
        });

        final doc = makeDocument(sections: [
          makeSection(id: 'note-001', type: 'note'),
          makeSection(id: 'note-002', type: 'note', index: 1),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.any((e) => e.category == ValidationErrorCategory.countLimit),
          isTrue,
        );
      });
    });

    group('text requirements', () {
      test('reports missing required text', () {
        final schema = makeSchema(sectionTypes: {
          'content': SectionTypeDef(name: 'content', prefix: 'cnt', textRequired: true),
        });

        final doc = makeDocument(sections: [
          makeSection(id: 'cnt-001', type: 'content', text: ''),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.any((e) => e.category == ValidationErrorCategory.textContent),
          isTrue,
        );
      });

      test('reports text below minimum length', () {
        final schema = makeSchema(sectionTypes: {
          'content': SectionTypeDef(name: 'content', prefix: 'cnt', minTextLength: 20),
        });

        final doc = makeDocument(sections: [
          makeSection(id: 'cnt-001', type: 'content', text: 'Short'),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.any((e) => e.category == ValidationErrorCategory.textContent),
          isTrue,
        );
      });
    });

    group('tags', () {
      test('reports invalid tags', () {
        final schema = makeSchema(sectionTypes: {
          'item': SectionTypeDef(
            name: 'item',
            prefix: 'item',
            allowedTags: ['urgent', 'low'],
          ),
        });

        final doc = makeDocument(sections: [
          makeSection(id: 'item-001', type: 'item', tags: ['invalid_tag']),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.any((e) => e.category == ValidationErrorCategory.tags),
          isTrue,
        );
      });

      test('passes with valid tags', () {
        final schema = makeSchema(sectionTypes: {
          'item': SectionTypeDef(
            name: 'item',
            prefix: 'item',
            allowedTags: ['urgent', 'low'],
          ),
        });

        final doc = makeDocument(sections: [
          makeSection(id: 'item-001', type: 'item', tags: ['urgent']),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.where((e) => e.category == ValidationErrorCategory.tags),
          isEmpty,
        );
      });
    });

    group('ID patterns', () {
      test('reports ID not matching pattern', () {
        final schema = makeSchema(sectionTypes: {
          'requirement': SectionTypeDef(
            name: 'requirement',
            prefix: 'req',
            patternCheckId: const PatternCheckDef(
              pattern: r'^REQ-\d{3}$',
              errorMessage: 'ID must match REQ-NNN',
            ),
          ),
        });

        final doc = makeDocument(sections: [
          makeSection(id: 'req-bad', type: 'requirement'),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.any((e) => e.category == ValidationErrorCategory.sectionId),
          isTrue,
        );
      });
    });

    group('required fields', () {
      test('reports missing required fields', () {
        final schema = makeSchema(sectionTypes: {
          'endpoint': SectionTypeDef(
            name: 'endpoint',
            prefix: 'ep',
            requiredFields: ['method', 'path'],
          ),
        });

        final doc = makeDocument(sections: [
          makeSection(
            id: 'ep-001',
            type: 'endpoint',
            text: 'Method: GET',
          ),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        // Should report 'path' as missing
        expect(
          errors.any((e) => e.message.toLowerCase().contains('path')),
          isTrue,
        );
      });
    });

    group('nesting depth', () {
      test('reports exceeding max nesting depth', () {
        final schema = makeSchema(sectionTypes: {
          'item': SectionTypeDef(
            name: 'item',
            prefix: 'item',
            maxSubsectionLevels: 0,
          ),
        });

        final child = makeSection(id: 'item-child', type: 'item');
        final doc = makeDocument(sections: [
          makeSection(id: 'item-parent', type: 'item', sections: [child]),
        ]);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        expect(
          errors.any((e) => e.category == ValidationErrorCategory.nestingDepth),
          isTrue,
        );
      });
    });

    group('empty document', () {
      test('validates empty document without errors (except schema)', () {
        final schema = makeSchema();
        final doc = makeDocument(sections: []);

        final validator = DocSpecsValidator(schema: schema);
        final errors = validator.validate(doc);

        // Only structural errors possible, no section-level errors
        expect(
          errors.where((e) =>
              e.category == ValidationErrorCategory.sectionType ||
              e.category == ValidationErrorCategory.sectionId ||
              e.category == ValidationErrorCategory.countLimit ||
              e.category == ValidationErrorCategory.nestingDepth ||
              e.category == ValidationErrorCategory.tags ||
              e.category == ValidationErrorCategory.textContent ||
              e.category == ValidationErrorCategory.format),
          isEmpty,
        );
      });
    });
  });

  group('SpecSection', () {
    test('getFormField extracts field from text', () {
      final section = SpecSection(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Test',
        name: 'Test',
        id: 'test-001',
        text: 'Method: POST\nPath: /api/users\nDescription: Create user',
      );

      expect(section.getFormField('method'), 'POST');
      expect(section.getFormField('path'), '/api/users');
      expect(section.getFormField('description'), 'Create user');
    });

    test('getFormField is case-insensitive', () {
      final section = SpecSection(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Test',
        name: 'Test',
        id: 'test-001',
        text: 'Method: POST',
      );

      expect(section.getFormField('METHOD'), 'POST');
      expect(section.getFormField('method'), 'POST');
    });

    test('preamble returns text before first field', () {
      final section = SpecSection(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Test',
        name: 'Test',
        id: 'test-001',
        text: 'This is the preamble.\nField: value',
      );

      expect(section.preamble, 'This is the preamble.');
    });

    test('getSubsectionsByType filters correctly', () {
      final section = SpecSection(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Parent',
        name: 'Parent',
        id: 'parent',
        text: '',
        sections: [
          SpecSection(
            index: 0,
            lineNumber: 5,
            rawHeadline: 'A',
            name: 'A',
            id: 'a',
            text: '',
            type: 'alpha',
          ),
          SpecSection(
            index: 1,
            lineNumber: 10,
            rawHeadline: 'B',
            name: 'B',
            id: 'b',
            text: '',
            type: 'beta',
          ),
          SpecSection(
            index: 2,
            lineNumber: 15,
            rawHeadline: 'C',
            name: 'C',
            id: 'c',
            text: '',
            type: 'alpha',
          ),
        ],
      );

      expect(section.getSubsectionsByType('alpha'), hasLength(2));
      expect(section.getSubsectionsByType('beta'), hasLength(1));
      expect(section.getSubsectionsByType('gamma'), isEmpty);
    });

    test('fromSection preserves base section data', () {
      final base = SpecSection(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Test',
        name: 'Test',
        id: 'test-001',
        text: 'Content',
        fields: {'key': 'value'},
      );

      final spec = SpecSection.fromSection(
        base,
        type: 'myType',
        tags: ['tag1', 'tag2'],
      );

      expect(spec.id, 'test-001');
      expect(spec.name, 'Test');
      expect(spec.text, 'Content');
      expect(spec.type, 'myType');
      expect(spec.tags, ['tag1', 'tag2']);
      expect(spec.fields['key'], 'value');
    });
  });

  group('SpecDoc', () {
    test('isValid returns true when no errors', () {
      final doc = SpecDoc(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Doc',
        name: 'Doc',
        id: 'doc',
        text: '',
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
        validationErrors: [],
      );

      expect(doc.isValid, isTrue);
    });

    test('isValid returns false when errors exist', () {
      final doc = SpecDoc(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Doc',
        name: 'Doc',
        id: 'doc',
        text: '',
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
        validationErrors: ['An error'],
      );

      expect(doc.isValid, isFalse);
    });

    test('fromDocument preserves document properties', () {
      final doc = SpecDoc(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Doc',
        name: 'Doc',
        id: 'doc',
        text: '',
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
        schemaId: 'my-schema/1.0',
        sections: [
          SpecSection(
            index: 0,
            lineNumber: 5,
            rawHeadline: 'Section',
            name: 'Section',
            id: 'sec-001',
            text: 'Content',
            type: 'requirement',
          ),
        ],
      );

      expect(doc.schemaId, 'my-schema/1.0');
      expect(doc.sections, hasLength(1));
    });
  });

  group('DocSpecSchema', () {
    test('creates with minimal parameters', () {
      final schema = DocSpecSchema(
        id: 'test',
        version: '1.0',
        sectionTypes: {},
        document: const DocumentStructure(sections: {}),
      );

      expect(schema.id, 'test');
      expect(schema.version, '1.0');
      expect(schema.sectionTypes, isEmpty);
    });

    test('stores section type definitions', () {
      final schema = DocSpecSchema(
        id: 'test',
        version: '1.0',
        sectionTypes: {
          'requirement': const SectionTypeDef(
            name: 'requirement',
            prefix: 'req',
            maxCountInDocument: 100,
          ),
        },
        document: const DocumentStructure(sections: {}),
      );

      expect(schema.sectionTypes.containsKey('requirement'), isTrue);
      expect(schema.sectionTypes['requirement']!.prefix, 'req');
      expect(schema.sectionTypes['requirement']!.maxCountInDocument, 100);
    });
  });

  group('ValidationError', () {
    test('toString with all fields', () {
      final error = ValidationError(
        message: 'Test error',
        lineNumber: 42,
        sectionId: 'sec-001',
        category: ValidationErrorCategory.general,
      );

      expect(error.toString(), contains('Line 42'));
      expect(error.toString(), contains('sec-001'));
      expect(error.toString(), contains('Test error'));
    });

    test('toString without line number', () {
      const error = ValidationError(
        message: 'Test error',
        sectionId: 'sec-001',
      );

      expect(error.toString(), contains('sec-001'));
      expect(error.toString(), contains('Test error'));
    });

    test('toString with only message', () {
      const error = ValidationError(
        message: 'Test error',
      );

      expect(error.toString(), 'Test error');
    });
  });
}
