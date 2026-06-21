import 'package:test/test.dart';
import 'package:tom_doc_specs/src/models/schema/doc_spec_schema.dart';
import 'package:tom_doc_specs/src/models/schema/document_structure.dart';
import 'package:tom_doc_specs/src/models/schema/form_type_def.dart';
import 'package:tom_doc_specs/src/models/schema/section_type_def.dart';
import 'package:tom_doc_specs/src/models/spec_doc.dart';
import 'package:tom_doc_specs/src/models/spec_section.dart';
import 'package:tom_doc_specs/src/validation/validation_error.dart';
import 'package:tom_doc_specs/src/validation/validator.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DocSpecSchema makeSchema({
    Map<String, SectionTypeDef>? sectionTypes,
    DocumentStructure? document,
    Map<String, FormTypeDef>? formTypes,
    Map<String, Map<String, SubsectionDef>>? subsectionDeclarations,
    Map<String, dynamic> customTags = const {},
  }) {
    return DocSpecSchema(
      id: 'test',
      version: '1.0',
      sectionTypes: sectionTypes ?? {},
      document: document ?? const DocumentStructure(sections: {}),
      formTypes: formTypes,
      subsectionDeclarations: subsectionDeclarations,
      customTags: customTags,
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
    String? format,
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
      format: format,
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

  List<ValidationError> errorsOf(
    List<ValidationError> errors,
    ValidationErrorCategory category,
  ) =>
      errors.where((e) => e.category == category).toList();

  // ---------------------------------------------------------------------------
  // 1. Document structure — required sections (type-based matching)
  // ---------------------------------------------------------------------------
  group('document structure - required sections', () {
    test('passes when all required sections are present by type', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'configuration': const SectionTypeDef(
              name: 'configuration', prefix: 'config'),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
          'configuration': const SectionDef(sectionType: 'configuration'),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'overview', type: 'overview'),
        makeSection(id: 'config-001', type: 'configuration', index: 1),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('reports missing required section when type not present', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'requirements-section': const SectionTypeDef(
              name: 'requirements-section', prefix: 'requirements'),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
          'requirements':
              const SectionDef(sectionType: 'requirements-section'),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'overview', type: 'overview'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      final structErrors = errorsOf(errors, ValidationErrorCategory.structure);
      expect(structErrors, hasLength(1));
      expect(structErrors.first.message,
          contains("Required section 'requirements'"));
    });

    test('does not report missing optional sections', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'glossary': const SectionTypeDef(name: 'glossary', prefix: 'gloss'),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
          'glossary':
              const SectionDef(sectionType: 'glossary', optional: true),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'overview', type: 'overview'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('reports all missing required sections on empty document', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'details': const SectionTypeDef(name: 'details', prefix: 'detail'),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
          'details': const SectionDef(sectionType: 'details'),
        }),
      );
      final doc = makeDocument(sections: []);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      final structErrors = errorsOf(errors, ValidationErrorCategory.structure);
      expect(structErrors, hasLength(2));
    });

    test('passes with prefix-based IDs that differ from schema keys', () {
      // This is the core bug fix test: section ID "config-001" matches
      // section type "configuration" via prefix "config"
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'configuration': const SectionTypeDef(
              name: 'configuration', prefix: 'config'),
          'requirements-section': const SectionTypeDef(
              name: 'requirements-section', prefix: 'requirements'),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
          'config': const SectionDef(sectionType: 'configuration'),
          'requirements':
              const SectionDef(sectionType: 'requirements-section'),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'overview', type: 'overview'),
        makeSection(
            id: 'config-001', type: 'configuration', index: 1, lineNumber: 20),
        makeSection(
            id: 'requirements-main',
            type: 'requirements-section',
            index: 2,
            lineNumber: 30),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Section order
  // ---------------------------------------------------------------------------
  group('document structure - section order', () {
    test('passes when sections are in correct order', () {
      final schema = makeSchema(
        sectionTypes: {
          'intro': const SectionTypeDef(name: 'intro', prefix: 'intro'),
          'body': const SectionTypeDef(name: 'body', prefix: 'body'),
          'conclusion':
              const SectionTypeDef(name: 'conclusion', prefix: 'conclusion'),
        },
        document: DocumentStructure(sections: {
          'introduction': const SectionDef(sectionType: 'intro'),
          'body': const SectionDef(sectionType: 'body'),
          'conclusion': const SectionDef(sectionType: 'conclusion'),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'intro-1', type: 'intro', lineNumber: 5),
        makeSection(id: 'body-main', type: 'body', index: 1, lineNumber: 15),
        makeSection(
            id: 'conclusion-1', type: 'conclusion', index: 2, lineNumber: 25),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('reports sections out of order', () {
      final schema = makeSchema(
        sectionTypes: {
          'intro': const SectionTypeDef(name: 'intro', prefix: 'intro'),
          'body': const SectionTypeDef(name: 'body', prefix: 'body'),
          'conclusion':
              const SectionTypeDef(name: 'conclusion', prefix: 'conclusion'),
        },
        document: DocumentStructure(sections: {
          'introduction': const SectionDef(sectionType: 'intro'),
          'body': const SectionDef(sectionType: 'body'),
          'conclusion': const SectionDef(sectionType: 'conclusion'),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(
            id: 'conclusion-1', type: 'conclusion', lineNumber: 5),
        makeSection(id: 'intro-1', type: 'intro', index: 1, lineNumber: 15),
        makeSection(id: 'body-main', type: 'body', index: 2, lineNumber: 25),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      final structErrors = errorsOf(errors, ValidationErrorCategory.structure);
      expect(structErrors.any((e) => e.message.contains('out of order')),
          isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Schema declaration
  // ---------------------------------------------------------------------------
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

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.schemaDeclaration),
        isNotEmpty,
      );
    });

    test('passes with valid schema declaration', () {
      final schema = makeSchema();
      final doc = makeDocument(sections: []);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.schemaDeclaration),
        isEmpty,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Section type resolution
  // ---------------------------------------------------------------------------
  group('section type resolution', () {
    test('reports unknown section type (null type)', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
        },
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'unknown-001', type: null),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.sectionType), isNotEmpty);
    });

    test('passes when all sections have valid types', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'note': const SectionTypeDef(name: 'note', prefix: 'note'),
        },
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'overview', type: 'overview'),
        makeSection(id: 'note-001', type: 'note', index: 1),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.sectionType), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Unique section IDs
  // ---------------------------------------------------------------------------
  group('unique section IDs', () {
    test('reports duplicate IDs', () {
      final schema = makeSchema();
      final doc = makeDocument(sections: [
        makeSection(id: 'dup-001', lineNumber: 10),
        makeSection(id: 'dup-001', lineNumber: 20, index: 1),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.sectionId), isNotEmpty);
    });

    test('passes with unique IDs', () {
      final schema = makeSchema();
      final doc = makeDocument(sections: [
        makeSection(id: 'sec-001', lineNumber: 10),
        makeSection(id: 'sec-002', lineNumber: 20, index: 1),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.sectionId), isEmpty);
    });

    test('reports duplicate IDs in nested sections', () {
      final schema = makeSchema();
      final doc = makeDocument(sections: [
        makeSection(
          id: 'parent',
          lineNumber: 5,
          sections: [
            makeSection(id: 'child-001', lineNumber: 10),
          ],
        ),
        makeSection(id: 'child-001', lineNumber: 20, index: 1),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.sectionId), isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Count limits (max-count-in-document)
  // ---------------------------------------------------------------------------
  group('count limits', () {
    test('reports exceeding max-count-in-document', () {
      final schema = makeSchema(sectionTypes: {
        'note': const SectionTypeDef(
            name: 'note', prefix: 'note', maxCountInDocument: 1),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'note-001', type: 'note'),
        makeSection(id: 'note-002', type: 'note', index: 1),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isNotEmpty);
    });

    test('passes when within max-count-in-document', () {
      final schema = makeSchema(sectionTypes: {
        'note': const SectionTypeDef(
            name: 'note', prefix: 'note', maxCountInDocument: 2),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'note-001', type: 'note'),
        makeSection(id: 'note-002', type: 'note', index: 1),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isEmpty);
    });

    test('reports below min-count-in-document', () {
      final schema = makeSchema(sectionTypes: {
        'note': const SectionTypeDef(
            name: 'note', prefix: 'note', minCountInDocument: 2),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'note-001', type: 'note'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isNotEmpty);
    });

    test('passes when within min-count-in-document', () {
      final schema = makeSchema(sectionTypes: {
        'note': const SectionTypeDef(
            name: 'note', prefix: 'note', minCountInDocument: 1),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'note-001', type: 'note'),
        makeSection(id: 'note-002', type: 'note', index: 1),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isEmpty);
    });

    test('reports exceeding subsection max-count', () {
      final schema = makeSchema(sectionTypes: {
        'project': SectionTypeDef(
          name: 'project',
          prefix: 'proj',
          subsectionTypes: {
            'note': const SubsectionConstraint(typeName: 'note', maxCount: 1),
          },
        ),
        'note': const SectionTypeDef(name: 'note', prefix: 'note'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'proj-main',
          type: 'project',
          sections: [
            makeSection(id: 'note-001', type: 'note', lineNumber: 15),
            makeSection(
                id: 'note-002', type: 'note', index: 1, lineNumber: 20),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isNotEmpty);
    });

    test('reports below subsection min-count', () {
      final schema = makeSchema(sectionTypes: {
        'project': SectionTypeDef(
          name: 'project',
          prefix: 'proj',
          subsectionTypes: {
            'requirement': const SubsectionConstraint(
                typeName: 'requirement', minCount: 2),
          },
        ),
        'requirement':
            const SectionTypeDef(name: 'requirement', prefix: 'req'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'proj-main',
          type: 'project',
          sections: [
            makeSection(id: 'req-001', type: 'requirement', lineNumber: 15),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isNotEmpty);
    });

    test('passes when subsection counts are within range', () {
      final schema = makeSchema(sectionTypes: {
        'project': SectionTypeDef(
          name: 'project',
          prefix: 'proj',
          subsectionTypes: {
            'requirement': const SubsectionConstraint(
                typeName: 'requirement', minCount: 1, maxCount: 3),
          },
        ),
        'requirement':
            const SectionTypeDef(name: 'requirement', prefix: 'req'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'proj-main',
          type: 'project',
          sections: [
            makeSection(id: 'req-001', type: 'requirement', lineNumber: 15),
            makeSection(
                id: 'req-002', type: 'requirement', index: 1, lineNumber: 20),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Nesting depth
  // ---------------------------------------------------------------------------
  group('nesting depth', () {
    test('reports exceeding max-subsection-levels of 0', () {
      final schema = makeSchema(sectionTypes: {
        'item': const SectionTypeDef(
            name: 'item', prefix: 'item', maxSubsectionLevels: 0),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'item-parent',
          type: 'item',
          sections: [
            makeSection(id: 'item-child', type: 'item'),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
          errorsOf(errors, ValidationErrorCategory.nestingDepth), isNotEmpty);
    });

    test('passes when nesting is within limits', () {
      final schema = makeSchema(sectionTypes: {
        'container': const SectionTypeDef(
            name: 'container', prefix: 'container', maxSubsectionLevels: 2),
        'item': const SectionTypeDef(name: 'item', prefix: 'item'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'container-1',
          type: 'container',
          sections: [
            makeSection(
              id: 'item-a',
              type: 'item',
              sections: [
                makeSection(id: 'item-nested', type: 'item'),
              ],
            ),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.nestingDepth), isEmpty);
    });

    test('reports exceeding max-subsection-levels of 1', () {
      final schema = makeSchema(sectionTypes: {
        'group': const SectionTypeDef(
            name: 'group', prefix: 'group', maxSubsectionLevels: 1),
        'item': const SectionTypeDef(name: 'item', prefix: 'item'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'group-1',
          type: 'group',
          sections: [
            makeSection(
              id: 'item-a',
              type: 'item',
              sections: [
                makeSection(id: 'item-deep', type: 'item'),
              ],
            ),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
          errorsOf(errors, ValidationErrorCategory.nestingDepth), isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 8. Tags
  // ---------------------------------------------------------------------------
  group('tags', () {
    test('reports invalid tags', () {
      final schema = makeSchema(sectionTypes: {
        'task': const SectionTypeDef(
          name: 'task',
          prefix: 'task',
          allowedTags: ['urgent', 'deferred', 'blocked'],
        ),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'task-001', type: 'task', tags: ['invalid_tag']),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.tags), isNotEmpty);
    });

    test('passes with valid tags', () {
      final schema = makeSchema(sectionTypes: {
        'task': const SectionTypeDef(
          name: 'task',
          prefix: 'task',
          allowedTags: ['urgent', 'deferred', 'blocked'],
        ),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'task-001', type: 'task', tags: ['urgent']),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.tags), isEmpty);
    });

    test('allows any tags when no allowed-tags defined', () {
      final schema = makeSchema(sectionTypes: {
        'note': const SectionTypeDef(name: 'note', prefix: 'note'),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'note-001', type: 'note', tags: ['anything', 'goes']),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.tags), isEmpty);
    });

    test('reports multiple invalid tags', () {
      final schema = makeSchema(sectionTypes: {
        'task': const SectionTypeDef(
          name: 'task',
          prefix: 'task',
          allowedTags: ['urgent'],
        ),
      });
      final doc = makeDocument(sections: [
        makeSection(
            id: 'task-001', type: 'task', tags: ['bad1', 'bad2', 'urgent']),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      final tagErrors = errorsOf(errors, ValidationErrorCategory.tags);
      expect(tagErrors, hasLength(2));
    });
  });

  // ---------------------------------------------------------------------------
  // 9. Text requirements
  // ---------------------------------------------------------------------------
  group('text requirements', () {
    test('reports missing required text', () {
      final schema = makeSchema(sectionTypes: {
        'content': const SectionTypeDef(
            name: 'content', prefix: 'cnt', textRequired: true),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'cnt-001', type: 'content', text: ''),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isNotEmpty);
    });

    test('passes when required text is present', () {
      final schema = makeSchema(sectionTypes: {
        'content': const SectionTypeDef(
            name: 'content', prefix: 'cnt', textRequired: true),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'cnt-001', type: 'content', text: 'Some text here'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isEmpty);
    });

    test('reports text below minimum length', () {
      final schema = makeSchema(sectionTypes: {
        'summary': const SectionTypeDef(
            name: 'summary', prefix: 'summary', minTextLength: 20),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'summary-1', type: 'summary', text: 'Short'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isNotEmpty);
    });

    test('reports text exceeding maximum length', () {
      final schema = makeSchema(sectionTypes: {
        'summary': const SectionTypeDef(
            name: 'summary', prefix: 'summary', maxTextLength: 10),
      });
      final doc = makeDocument(sections: [
        makeSection(
            id: 'summary-1',
            type: 'summary',
            text: 'This text is much longer than ten characters'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isNotEmpty);
    });

    test('passes when text length is within range', () {
      final schema = makeSchema(sectionTypes: {
        'summary': const SectionTypeDef(
            name: 'summary',
            prefix: 'summary',
            minTextLength: 5,
            maxTextLength: 50),
      });
      final doc = makeDocument(sections: [
        makeSection(
            id: 'summary-1', type: 'summary', text: 'This is a good length'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 10. ID patterns
  // ---------------------------------------------------------------------------
  group('ID patterns', () {
    test('reports ID not matching pattern', () {
      final schema = makeSchema(sectionTypes: {
        'requirement': SectionTypeDef(
          name: 'requirement',
          prefix: 'req',
          patternCheckId: const PatternCheckDef(
            pattern: r'^req-\d{3}$',
            errorMessage: 'ID must match req-NNN',
          ),
        ),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'req-bad', type: 'requirement'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.sectionId), isNotEmpty);
    });

    test('passes when ID matches pattern', () {
      final schema = makeSchema(sectionTypes: {
        'requirement': SectionTypeDef(
          name: 'requirement',
          prefix: 'req',
          patternCheckId: const PatternCheckDef(
            pattern: r'^req-\d{3}$',
            errorMessage: 'ID must match req-NNN',
          ),
        ),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'req-001', type: 'requirement'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.sectionId)
            .where((e) => e.message.contains('pattern')),
        isEmpty,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 11. Text patterns
  // ---------------------------------------------------------------------------
  group('text patterns', () {
    test('reports text not matching pattern', () {
      final schema = makeSchema(sectionTypes: {
        'task': SectionTypeDef(
          name: 'task',
          prefix: 'task',
          patternCheckText: const PatternCheckDef(
            pattern: r'^(must|should|shall)',
            errorMessage: 'Text must start with must/should/shall',
          ),
        ),
      });
      final doc = makeDocument(sections: [
        makeSection(
            id: 'task-001', type: 'task', text: 'This does not start right'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isNotEmpty);
    });

    test('passes when text matches pattern', () {
      final schema = makeSchema(sectionTypes: {
        'task': SectionTypeDef(
          name: 'task',
          prefix: 'task',
          patternCheckText: const PatternCheckDef(
            pattern: r'^(Must|Should|Shall)',
            errorMessage: 'Text must start with Must/Should/Shall',
          ),
        ),
      });
      final doc = makeDocument(sections: [
        makeSection(
            id: 'task-001', type: 'task', text: 'Must be implemented by Friday'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.textContent)
            .where((e) => e.message.contains('pattern')),
        isEmpty,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 12. Format - code blocks
  // ---------------------------------------------------------------------------
  group('format - code blocks', () {
    test('reports missing code block', () {
      final schema = makeSchema(sectionTypes: {
        'code-sample': const SectionTypeDef(
            name: 'code-sample', prefix: 'code', format: 'dart'),
      });
      final doc = makeDocument(sections: [
        makeSection(id: 'code-001', type: 'code-sample', text: 'No code here'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.format), isNotEmpty);
    });

    test('reports wrong code block language', () {
      final schema = makeSchema(sectionTypes: {
        'code-sample': const SectionTypeDef(
            name: 'code-sample', prefix: 'code', format: 'dart'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'code-001',
          type: 'code-sample',
          text: '```python\nprint("hello")\n```',
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.format), isNotEmpty);
    });

    test('passes with correct code block language', () {
      final schema = makeSchema(sectionTypes: {
        'code-sample': const SectionTypeDef(
            name: 'code-sample', prefix: 'code', format: 'dart'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'code-001',
          type: 'code-sample',
          text: '```dart\nvoid main() {}\n```',
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.format), isEmpty);
    });

    test('supports multiple allowed languages', () {
      final schema = makeSchema(sectionTypes: {
        'code-sample': const SectionTypeDef(
            name: 'code-sample', prefix: 'code', format: 'dart|yaml'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'code-001',
          type: 'code-sample',
          text: '```yaml\nkey: value\n```',
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.format), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 13. Format - forms
  // ---------------------------------------------------------------------------
  group('format - forms', () {
    test('reports missing required form fields', () {
      final schema = makeSchema(
        sectionTypes: {
          'endpoint': const SectionTypeDef(
              name: 'endpoint', prefix: 'ep', format: 'endpoint-form'),
        },
        formTypes: {
          'endpoint': FormTypeDef(name: 'endpoint', fields: [
            const FormFieldDef(fieldname: 'method', required: true),
            const FormFieldDef(fieldname: 'path', required: true),
          ]),
        },
      );
      final doc = makeDocument(sections: [
        makeSection(
          id: 'ep-001',
          type: 'endpoint',
          text: 'Method: GET',
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      final formatErrors = errorsOf(errors, ValidationErrorCategory.format);
      expect(formatErrors.any((e) => e.message.contains('path')), isTrue);
    });

    test('passes when all required form fields are present', () {
      final schema = makeSchema(
        sectionTypes: {
          'endpoint': const SectionTypeDef(
              name: 'endpoint', prefix: 'ep', format: 'endpoint-form'),
        },
        formTypes: {
          'endpoint': FormTypeDef(name: 'endpoint', fields: [
            const FormFieldDef(fieldname: 'method', required: true),
            const FormFieldDef(fieldname: 'path', required: true),
          ]),
        },
      );
      final doc = makeDocument(sections: [
        makeSection(
          id: 'ep-001',
          type: 'endpoint',
          text: 'Method: GET\nPath: /api/users',
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      final formatErrors = errorsOf(errors, ValidationErrorCategory.format);
      expect(formatErrors, isEmpty);
    });

    test('reports form field pattern mismatch', () {
      final schema = makeSchema(
        sectionTypes: {
          'endpoint': const SectionTypeDef(
              name: 'endpoint', prefix: 'ep', format: 'endpoint-form'),
        },
        formTypes: {
          'endpoint': FormTypeDef(name: 'endpoint', fields: [
            FormFieldDef(
              fieldname: 'method',
              required: true,
              patternCheck: const PatternCheckDef(
                pattern: r'^(GET|POST|PUT|DELETE)$',
                errorMessage: 'Invalid HTTP method',
              ),
            ),
          ]),
        },
      );
      final doc = makeDocument(sections: [
        makeSection(
          id: 'ep-001',
          type: 'endpoint',
          text: 'Method: INVALID',
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.format), isNotEmpty);
    });

    test('reports unknown form type', () {
      final schema = makeSchema(
        sectionTypes: {
          'endpoint': const SectionTypeDef(
              name: 'endpoint', prefix: 'ep', format: 'missing-form'),
        },
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'ep-001', type: 'endpoint', text: 'content'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.format), isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 14. Required fields
  // ---------------------------------------------------------------------------
  group('required fields', () {
    test('reports missing required fields', () {
      final schema = makeSchema(sectionTypes: {
        'endpoint': const SectionTypeDef(
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

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errors.any((e) => e.message.toLowerCase().contains('path')),
          isTrue);
    });

    test('passes when all required fields are present', () {
      final schema = makeSchema(sectionTypes: {
        'config': const SectionTypeDef(
          name: 'config',
          prefix: 'config',
          requiredFields: ['environment', 'version'],
        ),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'config-001',
          type: 'config',
          text: 'Some configuration content.',
          fields: {'environment': 'production', 'version': '2.0'},
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errors.where((e) =>
            e.message.contains('environment') || e.message.contains('version')),
        isEmpty,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 15. Child type enforcement (strict subsection-types)
  // ---------------------------------------------------------------------------
  group('child type enforcement', () {
    test('reports disallowed child types', () {
      final schema = makeSchema(sectionTypes: {
        'project': SectionTypeDef(
          name: 'project',
          prefix: 'proj',
          subsectionTypes: {
            'task': const SubsectionConstraint(typeName: 'task'),
          },
        ),
        'task': const SectionTypeDef(name: 'task', prefix: 'task'),
        'note': const SectionTypeDef(name: 'note', prefix: 'note'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'proj-main',
          type: 'project',
          sections: [
            makeSection(id: 'note-001', type: 'note', lineNumber: 15),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.sectionType), isNotEmpty);
    });

    test('passes with allowed child types only', () {
      final schema = makeSchema(sectionTypes: {
        'project': SectionTypeDef(
          name: 'project',
          prefix: 'proj',
          subsectionTypes: {
            'task': const SubsectionConstraint(typeName: 'task'),
            'milestone':
                const SubsectionConstraint(typeName: 'milestone'),
          },
        ),
        'task': const SectionTypeDef(name: 'task', prefix: 'task'),
        'milestone':
            const SectionTypeDef(name: 'milestone', prefix: 'milestone'),
      });
      final doc = makeDocument(sections: [
        makeSection(
          id: 'proj-main',
          type: 'project',
          sections: [
            makeSection(id: 'task-001', type: 'task', lineNumber: 15),
            makeSection(
                id: 'milestone-001',
                type: 'milestone',
                index: 1,
                lineNumber: 20),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.sectionType)
            .where((e) => e.message.contains('not allowed')),
        isEmpty,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 16. Document section type mismatch
  // ---------------------------------------------------------------------------
  group('document section type mismatch', () {
    test('does not report when types match', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'overview', type: 'overview'),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errors.where((e) =>
            e.category == ValidationErrorCategory.structure &&
            e.message.contains('has type')),
        isEmpty,
      );
    });

    test('handles sections with IDs differing from schema keys', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'configuration': const SectionTypeDef(
              name: 'configuration', prefix: 'config'),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
          'configuration': const SectionDef(sectionType: 'configuration'),
        }),
      );
      // Section ID "config-001" is not "configuration" but has type "configuration"
      final doc = makeDocument(sections: [
        makeSection(id: 'overview', type: 'overview'),
        makeSection(id: 'config-001', type: 'configuration', index: 1),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.structure)
            .where((e) => e.message.contains('has type')),
        isEmpty,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 17. For-each validation
  // ---------------------------------------------------------------------------
  group('for-each validation', () {
    test('reports missing subsection for registry entry', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'registry': const SectionTypeDef(name: 'registry', prefix: 'registry'),
          'component-def':
              const SectionTypeDef(name: 'component-def', prefix: 'comp'),
          'component-detail':
              const SectionTypeDef(name: 'component-detail', prefix: 'detail'),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
          'registry': const SectionDef(sectionType: 'registry'),
          'components': SectionDef(
            sectionType: 'component-detail',
            forEach: const ForEachDef(
              sectionType: 'component-def',
              key: 'name',
            ),
          ),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'overview', type: 'overview'),
        makeSection(
          id: 'registry-main',
          type: 'registry',
          index: 1,
          sections: [
            makeSection(
              id: 'comp-auth',
              type: 'component-def',
              fields: {'name': 'auth'},
            ),
            makeSection(
              id: 'comp-api',
              type: 'component-def',
              index: 1,
              fields: {'name': 'api'},
            ),
          ],
        ),
        makeSection(
          id: 'detail-section',
          type: 'component-detail',
          index: 2,
          sections: [
            // Only auth detail, missing api detail
            makeSection(
              id: 'detail-auth',
              type: 'component-detail',
              fields: {'name': 'auth'},
            ),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.forEach), isNotEmpty);
    });

    test('passes when all registry entries have subsections', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'registry': const SectionTypeDef(name: 'registry', prefix: 'registry'),
          'component-def':
              const SectionTypeDef(name: 'component-def', prefix: 'comp'),
          'component-detail':
              const SectionTypeDef(name: 'component-detail', prefix: 'detail'),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
          'registry': const SectionDef(sectionType: 'registry'),
          'components': SectionDef(
            sectionType: 'component-detail',
            forEach: const ForEachDef(
              sectionType: 'component-def',
              key: 'name',
            ),
          ),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'overview', type: 'overview'),
        makeSection(
          id: 'registry-main',
          type: 'registry',
          index: 1,
          sections: [
            makeSection(
              id: 'comp-auth',
              type: 'component-def',
              fields: {'name': 'auth'},
            ),
          ],
        ),
        makeSection(
          id: 'detail-section',
          type: 'component-detail',
          index: 2,
          sections: [
            makeSection(
              id: 'detail-auth',
              type: 'component-detail',
              fields: {'name': 'auth'},
            ),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.forEach), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 18. Subsection positions
  // ---------------------------------------------------------------------------
  group('subsection positions', () {
    test('reports missing required subsection', () {
      final schema = makeSchema(
        sectionTypes: {
          'container': const SectionTypeDef(
              name: 'container', prefix: 'container'),
          'header':
              const SectionTypeDef(name: 'header', prefix: 'header'),
        },
        document: DocumentStructure(sections: {
          'main': const SectionDef(sectionType: 'container'),
        }),
        subsectionDeclarations: {
          'main': {
            'header-sub': const SubsectionDef(
              sectionType: 'header',
              required: true,
              position: 'first',
            ),
          },
        },
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'container-1', type: 'container', sections: [
          // No header section
          makeSection(id: 'content-1', type: 'container'),
        ]),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.structure)
            .any((e) => e.message.contains("Required subsection")),
        isTrue,
      );
    });

    test('reports first-position violation', () {
      final schema = makeSchema(
        sectionTypes: {
          'container': const SectionTypeDef(
              name: 'container', prefix: 'container'),
          'header':
              const SectionTypeDef(name: 'header', prefix: 'header'),
          'content':
              const SectionTypeDef(name: 'content', prefix: 'content'),
        },
        document: DocumentStructure(sections: {
          'main': const SectionDef(sectionType: 'container'),
        }),
        subsectionDeclarations: {
          'main': {
            'header-sub': const SubsectionDef(
              sectionType: 'header',
              position: 'first',
            ),
          },
        },
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'container-1', type: 'container', sections: [
          makeSection(id: 'content-1', type: 'content', lineNumber: 5),
          makeSection(
              id: 'header-1', type: 'header', index: 1, lineNumber: 10),
        ]),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.structure)
            .any((e) => e.message.contains('must appear first')),
        isTrue,
      );
    });

    test('reports last-position violation', () {
      final schema = makeSchema(
        sectionTypes: {
          'container': const SectionTypeDef(
              name: 'container', prefix: 'container'),
          'footer':
              const SectionTypeDef(name: 'footer', prefix: 'footer'),
          'content':
              const SectionTypeDef(name: 'content', prefix: 'content'),
        },
        document: DocumentStructure(sections: {
          'main': const SectionDef(sectionType: 'container'),
        }),
        subsectionDeclarations: {
          'main': {
            'footer-sub': const SubsectionDef(
              sectionType: 'footer',
              position: 'last',
            ),
          },
        },
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'container-1', type: 'container', sections: [
          makeSection(id: 'footer-1', type: 'footer', lineNumber: 5),
          makeSection(
              id: 'content-1', type: 'content', index: 1, lineNumber: 10),
        ]),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.structure)
            .any((e) => e.message.contains('must appear last')),
        isTrue,
      );
    });

    test('reports non-contiguous relative-position violation', () {
      final schema = makeSchema(
        sectionTypes: {
          'container': const SectionTypeDef(
              name: 'container', prefix: 'container'),
          'sidebar':
              const SectionTypeDef(name: 'sidebar', prefix: 'sidebar'),
          'content':
              const SectionTypeDef(name: 'content', prefix: 'content'),
        },
        document: DocumentStructure(sections: {
          'main': const SectionDef(sectionType: 'container'),
        }),
        subsectionDeclarations: {
          'main': {
            'sidebar-sub': const SubsectionDef(
              sectionType: 'sidebar',
              position: 'relative',
            ),
          },
        },
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'container-1', type: 'container', sections: [
          makeSection(id: 'sidebar-1', type: 'sidebar', lineNumber: 5),
          makeSection(
              id: 'content-1', type: 'content', index: 1, lineNumber: 10),
          makeSection(
              id: 'sidebar-2', type: 'sidebar', index: 2, lineNumber: 15),
        ]),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.structure)
            .any((e) => e.message.contains('contiguous')),
        isTrue,
      );
    });

    test('passes with correct position constraints', () {
      final schema = makeSchema(
        sectionTypes: {
          'container': const SectionTypeDef(
              name: 'container', prefix: 'container'),
          'header':
              const SectionTypeDef(name: 'header', prefix: 'header'),
          'content':
              const SectionTypeDef(name: 'content', prefix: 'content'),
          'footer':
              const SectionTypeDef(name: 'footer', prefix: 'footer'),
        },
        document: DocumentStructure(sections: {
          'main': const SectionDef(sectionType: 'container'),
        }),
        subsectionDeclarations: {
          'main': {
            'header-sub': const SubsectionDef(
              sectionType: 'header',
              position: 'first',
            ),
            'footer-sub': const SubsectionDef(
              sectionType: 'footer',
              position: 'last',
            ),
          },
        },
      );
      final doc = makeDocument(sections: [
        makeSection(id: 'container-1', type: 'container', sections: [
          makeSection(id: 'header-1', type: 'header', lineNumber: 5),
          makeSection(
              id: 'content-1', type: 'content', index: 1, lineNumber: 10),
          makeSection(
              id: 'footer-1', type: 'footer', index: 2, lineNumber: 15),
        ]),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(
        errorsOf(errors, ValidationErrorCategory.structure)
            .where((e) =>
                e.message.contains('first') ||
                e.message.contains('last') ||
                e.message.contains('contiguous')),
        isEmpty,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 19. Comprehensive validation (all features combined)
  // ---------------------------------------------------------------------------
  group('comprehensive validation', () {
    test('valid document passes all checks', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(
            name: 'overview',
            prefix: 'overview',
            textRequired: true,
            minTextLength: 5,
          ),
          'requirements': const SectionTypeDef(
            name: 'requirements',
            prefix: 'req',
            maxCountInDocument: 1,
          ),
          'requirement': SectionTypeDef(
            name: 'requirement',
            prefix: 'requirement',
            textRequired: true,
            allowedTags: const ['must-have', 'nice-to-have'],
            patternCheckId: const PatternCheckDef(
              pattern: r'^requirement-\d+$',
              errorMessage: 'Must match requirement-N',
            ),
          ),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
          'requirements':
              const SectionDef(sectionType: 'requirements', optional: true),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(
          id: 'overview',
          type: 'overview',
          text: 'This is a good overview of the project',
        ),
        makeSection(
          id: 'req-main',
          type: 'requirements',
          index: 1,
          sections: [
            makeSection(
              id: 'requirement-1',
              type: 'requirement',
              text: 'Must support user authentication',
              tags: ['must-have'],
            ),
          ],
        ),
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      // Filter out section-type errors for sections not in sectionTypes
      // Only check for errors in sections we care about
      expect(
        errors.where((e) =>
            e.category != ValidationErrorCategory.sectionType),
        isEmpty,
      );
    });

    test('document with multiple errors reports all of them', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(
            name: 'overview',
            prefix: 'overview',
            textRequired: true,
          ),
          'task': const SectionTypeDef(
            name: 'task',
            prefix: 'task',
            allowedTags: ['urgent'],
            maxCountInDocument: 1,
          ),
        },
        document: DocumentStructure(sections: {
          'overview': const SectionDef(sectionType: 'overview'),
        }),
      );
      final doc = makeDocument(sections: [
        makeSection(
          id: 'overview',
          type: 'overview',
          text: '', // Missing required text
        ),
        makeSection(
          id: 'task-001',
          type: 'task',
          index: 1,
          tags: ['bad-tag'], // Invalid tag
        ),
        makeSection(
          id: 'task-002',
          type: 'task',
          index: 2,
          tags: ['urgent'],
        ),
        // Two tasks exceeds max-count-in-document: 1
      ]);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isNotEmpty);
      expect(errorsOf(errors, ValidationErrorCategory.tags), isNotEmpty);
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 20. Edge cases
  // ---------------------------------------------------------------------------
  group('edge cases', () {
    test('empty document with all optional sections passes', () {
      final schema = makeSchema(
        sectionTypes: {
          'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
          'details': const SectionTypeDef(name: 'details', prefix: 'detail'),
        },
        document: DocumentStructure(sections: {
          'overview':
              const SectionDef(sectionType: 'overview', optional: true),
          'details':
              const SectionDef(sectionType: 'details', optional: true),
        }),
      );
      final doc = makeDocument(sections: []);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('schema with no section types validates schema declaration only', () {
      final schema = makeSchema();
      final doc = makeDocument(sections: []);

      final errors = DocSpecsValidator(schema: schema).validate(doc);
      // Only potentially schema-related errors (no section-level checks)
      expect(
        errors.where((e) =>
            e.category == ValidationErrorCategory.countLimit ||
            e.category == ValidationErrorCategory.nestingDepth ||
            e.category == ValidationErrorCategory.tags ||
            e.category == ValidationErrorCategory.textContent ||
            e.category == ValidationErrorCategory.format),
        isEmpty,
      );
    });

    test('section with null sections list does not cause errors', () {
      final schema = makeSchema(sectionTypes: {
        'overview': const SectionTypeDef(name: 'overview', prefix: 'overview'),
      });
      final doc = makeDocument(sections: [
        SpecSection(
          index: 0,
          lineNumber: 5,
          rawHeadline: 'Overview',
          name: 'Overview',
          id: 'overview',
          text: 'Content',
          type: 'overview',
        ),
      ]);

      expect(() => DocSpecsValidator(schema: schema).validate(doc),
          returnsNormally);
    });
  });
}
