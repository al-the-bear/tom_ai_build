import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_specs/src/models/spec_doc.dart';
import 'package:tom_doc_specs/src/models/spec_section.dart';
import 'package:tom_doc_specs/src/schema/schema_loader.dart';
import 'package:tom_doc_specs/src/validation/validation_error.dart';
import 'package:tom_doc_specs/src/validation/validator.dart';

/// Resolves the path to test/fixtures from the test file location.
String _fixturesPath() {
  // Try standard test runner location first
  final candidates = [
    p.join(Directory.current.path, 'test', 'fixtures'),
    p.join(Directory.current.path, 'tom_doc_specs', 'test', 'fixtures'),
  ];
  for (final c in candidates) {
    if (Directory(c).existsSync()) return c;
  }
  throw StateError('Cannot find test/fixtures directory from ${Directory.current.path}');
}

void main() {
  late String fixturesPath;
  late String schemasPath;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  SpecSection sec({
    required String id,
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

  SpecDoc doc({
    required String schemaId,
    required List<SpecSection> sections,
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

  List<ValidationError> validate(String schemaFile, SpecDoc document) {
    final schema = SchemaLoader.loadSync(p.join(schemasPath, schemaFile));
    final validator = DocSpecsValidator(schema: schema);
    return validator.validate(document);
  }

  List<ValidationError> errorsOf(
    List<ValidationError> errors,
    ValidationErrorCategory cat,
  ) =>
      errors.where((e) => e.category == cat).toList();

  setUpAll(() {
    fixturesPath = _fixturesPath();
    schemasPath = p.join(fixturesPath, 'schemas');
  });

  // ===========================================================================
  // 1. MINIMAL schema — single required section (note/note)
  // ===========================================================================
  group('minimal schema', () {
    const sf = 'minimal.1.0.docspecs-schema.yaml';

    test('valid: overview present', () {
      final errors = validate(sf, doc(
        schemaId: 'minimal/1.0',
        sections: [sec(id: 'note-001', type: 'note', name: 'Overview')],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('error: overview missing', () {
      final errors = validate(sf, doc(
        schemaId: 'minimal/1.0',
        sections: [],
      ));
      final structErrors = errorsOf(errors, ValidationErrorCategory.structure);
      expect(structErrors, isNotEmpty);
      expect(structErrors.first.message, contains('overview'));
    });
  });

  // ===========================================================================
  // 2. ALL-OPTIONAL schema — all sections optional
  // ===========================================================================
  group('all-optional schema', () {
    const sf = 'all-optional.1.0.docspecs-schema.yaml';

    test('valid: empty document (all optional)', () {
      final errors = validate(sf, doc(
        schemaId: 'all-optional/1.0',
        sections: [],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('valid: all optional sections present', () {
      final errors = validate(sf, doc(
        schemaId: 'all-optional/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'Overview'),
          sec(id: 'det-001', type: 'detail', name: 'Details'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });
  });

  // ===========================================================================
  // 3. MULTI-SECTION schema — overview (note), requirements (req), config (opt)
  // ===========================================================================
  group('multi-section schema', () {
    const sf = 'multi-section.1.0.docspecs-schema.yaml';

    test('valid: all required present, optional omitted', () {
      final errors = validate(sf, doc(
        schemaId: 'multi-section/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'Overview'),
          sec(id: 'req-001', type: 'requirement', name: 'Requirements'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('valid: all sections present including optional', () {
      final errors = validate(sf, doc(
        schemaId: 'multi-section/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'Overview'),
          sec(id: 'req-001', type: 'requirement', name: 'Requirements'),
          sec(id: 'config-001', type: 'configuration', name: 'Configuration'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('error: missing overview', () {
      final errors = validate(sf, doc(
        schemaId: 'multi-section/1.0',
        sections: [
          sec(id: 'req-001', type: 'requirement', name: 'Requirements'),
        ],
      ));
      final structErrors = errorsOf(errors, ValidationErrorCategory.structure);
      expect(structErrors, isNotEmpty);
      expect(structErrors.any((e) => e.message.contains('overview')), isTrue);
    });

    test('error: missing both required sections', () {
      final errors = validate(sf, doc(
        schemaId: 'multi-section/1.0',
        sections: [
          sec(id: 'config-001', type: 'configuration', name: 'Configuration'),
        ],
      ));
      final structErrors = errorsOf(errors, ValidationErrorCategory.structure);
      expect(structErrors.length, greaterThanOrEqualTo(2));
    });

    test('error: duplicate section IDs', () {
      final errors = validate(sf, doc(
        schemaId: 'multi-section/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'Overview'),
          sec(id: 'note-001', type: 'note', name: 'Duplicate'),
          sec(id: 'req-001', type: 'requirement', name: 'Requirements'),
        ],
      ));
      final idErrors = errorsOf(errors, ValidationErrorCategory.sectionId);
      expect(idErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 4. COUNT-LIMITS schema — note (max 3), warning (max 1, optional)
  // ===========================================================================
  group('count-limits schema', () {
    const sf = 'count-limits.1.0.docspecs-schema.yaml';

    test('valid: within limits', () {
      final errors = validate(sf, doc(
        schemaId: 'count-limits/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'Note One'),
          sec(id: 'note-002', type: 'note', name: 'Note Two'),
          sec(id: 'note-003', type: 'note', name: 'Note Three'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isEmpty);
    });

    test('valid: multiple same type within limit', () {
      final errors = validate(sf, doc(
        schemaId: 'count-limits/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'Note One'),
          sec(id: 'note-002', type: 'note', name: 'Note Two'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isEmpty);
    });

    test('error: exceeds max count', () {
      final errors = validate(sf, doc(
        schemaId: 'count-limits/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'One'),
          sec(id: 'note-002', type: 'note', name: 'Two'),
          sec(id: 'note-003', type: 'note', name: 'Three'),
          sec(id: 'note-004', type: 'note', name: 'Four'),
        ],
      ));
      final countErrors = errorsOf(errors, ValidationErrorCategory.countLimit);
      expect(countErrors, isNotEmpty);
      expect(countErrors.first.message, contains('3'));
    });
  });

  // ===========================================================================
  // 5. NESTING-DEPTH schema — topic (max 2), flat (max 0)
  // ===========================================================================
  group('nesting-depth schema', () {
    const sf = 'nesting-depth.1.0.docspecs-schema.yaml';

    test('valid: within depth limit', () {
      final errors = validate(sf, doc(
        schemaId: 'nesting-depth/1.0',
        sections: [
          sec(
            id: 'top-001', type: 'topic', name: 'Topic',
            sections: [
              sec(
                id: 'top-002', type: 'topic', name: 'Sub-Topic',
                sections: [
                  sec(id: 'top-003', type: 'topic', name: 'Sub-Sub-Topic'),
                ],
              ),
            ],
          ),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.nestingDepth), isEmpty);
    });

    test('error: exceeds max depth', () {
      final errors = validate(sf, doc(
        schemaId: 'nesting-depth/1.0',
        sections: [
          sec(
            id: 'top-001', type: 'topic', name: 'Topic',
            sections: [
              sec(
                id: 'top-002', type: 'topic', name: 'L1',
                sections: [
                  sec(
                    id: 'top-003', type: 'topic', name: 'L2',
                    sections: [
                      sec(id: 'top-004', type: 'topic', name: 'L3'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ));
      final depthErrors = errorsOf(errors, ValidationErrorCategory.nestingDepth);
      expect(depthErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 6. SUBSECTION-COUNTS — parent(par) with detail(1-5), note(max 2)
  // ===========================================================================
  group('subsection-counts schema', () {
    const sf = 'subsection-counts.1.0.docspecs-schema.yaml';

    test('valid: subsection counts within range', () {
      final errors = validate(sf, doc(
        schemaId: 'subsection-counts/1.0',
        sections: [
          sec(
            id: 'par-001', type: 'parent', name: 'Parent',
            sections: [
              sec(id: 'det-001', type: 'detail', name: 'Detail'),
              sec(id: 'det-002', type: 'detail', name: 'Detail 2'),
              sec(id: 'note-001', type: 'note', name: 'Note'),
            ],
          ),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isEmpty);
    });

    test('error: below min subsection count', () {
      final errors = validate(sf, doc(
        schemaId: 'subsection-counts/1.0',
        sections: [
          sec(
            id: 'par-001', type: 'parent', name: 'Parent',
            sections: [],
          ),
        ],
      ));
      final countErrors = errorsOf(errors, ValidationErrorCategory.countLimit);
      expect(countErrors, isNotEmpty);
    });

    test('error: exceeds max subsection count', () {
      final errors = validate(sf, doc(
        schemaId: 'subsection-counts/1.0',
        sections: [
          sec(
            id: 'par-001', type: 'parent', name: 'Parent',
            sections: [
              sec(id: 'det-001', type: 'detail', name: 'D1'),
              sec(id: 'note-001', type: 'note', name: 'N1'),
              sec(id: 'note-002', type: 'note', name: 'N2'),
              sec(id: 'note-003', type: 'note', name: 'N3'),
            ],
          ),
        ],
      ));
      final countErrors = errorsOf(errors, ValidationErrorCategory.countLimit);
      expect(countErrors, isNotEmpty);
      expect(countErrors.any((e) => e.message.contains('note') || e.message.contains('2')), isTrue);
    });
  });

  // ===========================================================================
  // 7. PATTERN-CHECKS — requirement (req) with ID and text patterns
  // ===========================================================================
  group('pattern-checks schema', () {
    const sf = 'pattern-checks.1.0.docspecs-schema.yaml';

    test('valid: ID and text match patterns', () {
      final errors = validate(sf, doc(
        schemaId: 'pattern-checks/1.0',
        sections: [
          sec(id: 'REQ-001', type: 'requirement', name: 'Req',
              text: 'The system shall support login.'),
          sec(id: 'REQ-002', type: 'requirement', name: 'Req 2',
              text: 'Users must be able to reset passwords.'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.sectionId), isEmpty);
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isEmpty);
    });

    test('error: ID does not match pattern', () {
      final errors = validate(sf, doc(
        schemaId: 'pattern-checks/1.0',
        sections: [
          sec(id: 'req-wrong', type: 'requirement', name: 'Bad ID',
              text: 'The system shall do something.'),
        ],
      ));
      final idErrors = errorsOf(errors, ValidationErrorCategory.sectionId);
      expect(idErrors, isNotEmpty);
      expect(idErrors.first.message, contains('REQ-NNN'));
    });

    test('error: text does not match pattern', () {
      final errors = validate(sf, doc(
        schemaId: 'pattern-checks/1.0',
        sections: [
          sec(id: 'REQ-001', type: 'requirement', name: 'No keywords',
              text: 'This text has no required keywords at all.'),
        ],
      ));
      final textErrors = errorsOf(errors, ValidationErrorCategory.textContent);
      expect(textErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 8. TEXT-REQUIREMENTS — content (cont) text-required, min 10, max 500
  // ===========================================================================
  group('text-requirements schema', () {
    const sf = 'text-requirements.1.0.docspecs-schema.yaml';

    test('valid: text meets all requirements', () {
      final errors = validate(sf, doc(
        schemaId: 'text-requirements/1.0',
        sections: [
          sec(id: 'cont-001', type: 'content', name: 'Content',
              text: 'This is valid content with more than ten characters.'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isEmpty);
    });

    test('error: empty text (text-required)', () {
      final errors = validate(sf, doc(
        schemaId: 'text-requirements/1.0',
        sections: [
          sec(id: 'cont-001', type: 'content', name: 'Content', text: ''),
        ],
      ));
      final textErrors = errorsOf(errors, ValidationErrorCategory.textContent);
      expect(textErrors, isNotEmpty);
    });

    test('error: text too short (below min-text-length)', () {
      final errors = validate(sf, doc(
        schemaId: 'text-requirements/1.0',
        sections: [
          sec(id: 'cont-001', type: 'content', name: 'Content', text: 'Short'),
        ],
      ));
      final textErrors = errorsOf(errors, ValidationErrorCategory.textContent);
      expect(textErrors, isNotEmpty);
      expect(textErrors.any((e) => e.message.contains('10')), isTrue);
    });

    test('error: text too long (exceeds max-text-length)', () {
      final errors = validate(sf, doc(
        schemaId: 'text-requirements/1.0',
        sections: [
          sec(id: 'cont-001', type: 'content', name: 'Content',
              text: 'A' * 501),
        ],
      ));
      final textErrors = errorsOf(errors, ValidationErrorCategory.textContent);
      expect(textErrors, isNotEmpty);
      expect(textErrors.any((e) => e.message.contains('500')), isTrue);
    });
  });

  // ===========================================================================
  // 9. TAGS — task (task) with allowed: priority, status, assignee
  // ===========================================================================
  group('tags schema', () {
    const sf = 'tags.1.0.docspecs-schema.yaml';

    test('valid: all tags allowed', () {
      final errors = validate(sf, doc(
        schemaId: 'tags/1.0',
        sections: [
          sec(id: 'task-001', type: 'task', name: 'Task',
              tags: ['priority', 'status']),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.tags), isEmpty);
    });

    test('error: unknown tags', () {
      final errors = validate(sf, doc(
        schemaId: 'tags/1.0',
        sections: [
          sec(id: 'task-001', type: 'task', name: 'Task',
              tags: ['priority', 'unknown-tag', 'invalid']),
        ],
      ));
      final tagErrors = errorsOf(errors, ValidationErrorCategory.tags);
      expect(tagErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 10. FORMAT-CODEBLOCK — code-example (code) with format: dart
  // ===========================================================================
  group('format-codeblock schema', () {
    const sf = 'format-codeblock.1.0.docspecs-schema.yaml';

    test('valid: has dart code block', () {
      final errors = validate(sf, doc(
        schemaId: 'format-codeblock/1.0',
        sections: [
          sec(id: 'code-001', type: 'code-example', name: 'Example',
              format: 'dart',
              text: '```dart\nvoid main() {}\n```'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.format), isEmpty);
    });

    test('error: missing code block', () {
      final errors = validate(sf, doc(
        schemaId: 'format-codeblock/1.0',
        sections: [
          sec(id: 'code-001', type: 'code-example', name: 'Example',
              text: 'No code block here.'),
        ],
      ));
      final formatErrors = errorsOf(errors, ValidationErrorCategory.format);
      expect(formatErrors, isNotEmpty);
    });

    test('error: wrong language code block', () {
      final errors = validate(sf, doc(
        schemaId: 'format-codeblock/1.0',
        sections: [
          sec(id: 'code-001', type: 'code-example', name: 'Example',
              format: 'python',
              text: '```python\nprint("wrong")\n```'),
        ],
      ));
      final formatErrors = errorsOf(errors, ValidationErrorCategory.format);
      expect(formatErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 11. FORM-TYPES — entry (ent) format: contact-form
  //     fields: name (req), email (req, pattern), phone (opt)
  // ===========================================================================
  group('form-types schema', () {
    const sf = 'form-types.1.0.docspecs-schema.yaml';

    test('valid: all required form fields present', () {
      final errors = validate(sf, doc(
        schemaId: 'form-types/1.0',
        sections: [
          sec(id: 'ent-001', type: 'entry', name: 'Entry',
              format: 'contact-form',
              fields: {
                'name': 'John Doe',
                'email': 'john@example.com',
                'phone': '555-1234',
              }),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.format), isEmpty);
    });

    test('error: missing required form field', () {
      final errors = validate(sf, doc(
        schemaId: 'form-types/1.0',
        sections: [
          sec(id: 'ent-001', type: 'entry', name: 'Entry',
              format: 'contact-form',
              fields: {
                'name': 'John Doe',
                'phone': '555-1234',
              }),
        ],
      ));
      final formatErrors = errorsOf(errors, ValidationErrorCategory.format);
      expect(formatErrors, isNotEmpty);
      expect(formatErrors.any((e) =>
          e.message.toLowerCase().contains('email')), isTrue);
    });

    test('error: form field pattern mismatch', () {
      final errors = validate(sf, doc(
        schemaId: 'form-types/1.0',
        sections: [
          sec(id: 'ent-001', type: 'entry', name: 'Entry',
              format: 'contact-form',
              fields: {
                'name': 'John Doe',
                'email': 'not-an-email',
                'phone': '555-1234',
              }),
        ],
      ));
      final formatErrors = errorsOf(errors, ValidationErrorCategory.format);
      expect(formatErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 12. REQUIRED-FIELDS — record (rec) required: title, status, owner
  // ===========================================================================
  group('required-fields schema', () {
    const sf = 'required-fields.1.0.docspecs-schema.yaml';

    test('valid: all required fields present', () {
      final errors = validate(sf, doc(
        schemaId: 'required-fields/1.0',
        sections: [
          sec(id: 'rec-001', type: 'record', name: 'Record',
              fields: {
                'title': 'My Record',
                'status': 'Active',
                'owner': 'Team Lead',
              }),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.format), isEmpty);
    });

    test('error: missing required fields', () {
      final errors = validate(sf, doc(
        schemaId: 'required-fields/1.0',
        sections: [
          sec(id: 'rec-001', type: 'record', name: 'Record',
              fields: {'title': 'Incomplete'}),
        ],
      ));
      final formatErrors = errorsOf(errors, ValidationErrorCategory.format);
      expect(formatErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 13. FOR-EACH — items (item), registry (reg, for-each: items)
  // ===========================================================================
  group('for-each schema', () {
    const sf = 'for-each.1.0.docspecs-schema.yaml';

    test('valid: matching for-each keys', () {
      final errors = validate(sf, doc(
        schemaId: 'for-each/1.0',
        sections: [
          sec(id: 'item-001', type: 'item', name: 'Item A',
              fields: {'name': 'alpha'}),
          sec(id: 'item-002', type: 'item', name: 'Item B',
              fields: {'name': 'beta'}),
          sec(id: 'reg-001', type: 'registry-entry', name: 'Registry',
              sections: [
                sec(id: 'child-001', name: 'Child A',
                    fields: {'name': 'alpha'}),
                sec(id: 'child-002', name: 'Child B',
                    fields: {'name': 'beta'}),
              ]),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.forEach), isEmpty);
    });

    test('error: for-each key mismatch', () {
      final errors = validate(sf, doc(
        schemaId: 'for-each/1.0',
        sections: [
          sec(id: 'item-001', type: 'item', name: 'Item A',
              fields: {'name': 'alpha'}),
          sec(id: 'item-002', type: 'item', name: 'Item B',
              fields: {'name': 'beta'}),
          sec(id: 'item-003', type: 'item', name: 'Item C',
              fields: {'name': 'gamma'}),
          sec(id: 'reg-001', type: 'registry-entry', name: 'Registry',
              sections: [
                sec(id: 'child-001', name: 'Child A',
                    fields: {'name': 'alpha'}),
              ]),
        ],
      ));
      final forEachErrors = errorsOf(errors, ValidationErrorCategory.forEach);
      expect(forEachErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 14. SUBSECTION-POSITIONS — container (cont), summary (first), detail (last)
  // ===========================================================================
  group('subsection-positions schema', () {
    const sf = 'subsection-positions.1.0.docspecs-schema.yaml';

    test('valid: correct first and last positions', () {
      final errors = validate(sf, doc(
        schemaId: 'subsection-positions/1.0',
        sections: [
          sec(
            id: 'cont-001', type: 'container', name: 'Main',
            sections: [
              sec(id: 'sum-001', type: 'summary', name: 'Summary'),
              sec(id: 'cont-002', type: 'container', name: 'Middle'),
              sec(id: 'det-001', type: 'detail', name: 'Detail'),
            ],
          ),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('error: wrong first position', () {
      final errors = validate(sf, doc(
        schemaId: 'subsection-positions/1.0',
        sections: [
          sec(
            id: 'cont-001', type: 'container', name: 'Main',
            sections: [
              sec(id: 'det-001', type: 'detail', name: 'Detail'),
              sec(id: 'sum-001', type: 'summary', name: 'Summary'),
            ],
          ),
        ],
      ));
      final structErrors = errorsOf(errors, ValidationErrorCategory.structure);
      expect(structErrors, isNotEmpty);
    });

    test('error: wrong last position', () {
      final errors = validate(sf, doc(
        schemaId: 'subsection-positions/1.0',
        sections: [
          sec(
            id: 'cont-001', type: 'container', name: 'Main',
            sections: [
              sec(id: 'sum-001', type: 'summary', name: 'Summary'),
              sec(id: 'det-001', type: 'detail', name: 'Detail'),
              sec(id: 'cont-002', type: 'container', name: 'Extra'),
            ],
          ),
        ],
      ));
      final structErrors = errorsOf(errors, ValidationErrorCategory.structure);
      expect(structErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 15. SECTION-ORDER — introduction, body, conclusion
  // ===========================================================================
  group('section-order schema', () {
    const sf = 'section-order.1.0.docspecs-schema.yaml';

    test('valid: correct order', () {
      final errors = validate(sf, doc(
        schemaId: 'section-order/1.0',
        sections: [
          sec(id: 'intro-001', type: 'introduction', name: 'Introduction'),
          sec(id: 'body-001', type: 'body', name: 'Body'),
          sec(id: 'concl-001', type: 'conclusion', name: 'Conclusion'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('error: wrong order', () {
      final errors = validate(sf, doc(
        schemaId: 'section-order/1.0',
        sections: [
          sec(id: 'concl-001', type: 'conclusion', name: 'Conclusion'),
          sec(id: 'intro-001', type: 'introduction', name: 'Introduction'),
          sec(id: 'body-001', type: 'body', name: 'Body'),
        ],
      ));
      final structErrors = errorsOf(errors, ValidationErrorCategory.structure);
      expect(structErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 16. CHILD-TYPES — chapter (chap) requires paragraph (para, min 1)
  // ===========================================================================
  group('child-types schema', () {
    const sf = 'child-types.1.0.docspecs-schema.yaml';

    test('valid: chapter has required paragraph children', () {
      final errors = validate(sf, doc(
        schemaId: 'child-types/1.0',
        sections: [
          sec(
            id: 'chap-001', type: 'chapter', name: 'Chapter',
            sections: [
              sec(id: 'para-001', type: 'paragraph', name: 'Paragraph'),
            ],
          ),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.countLimit), isEmpty);
    });

    test('error: chapter missing required paragraph children', () {
      final errors = validate(sf, doc(
        schemaId: 'child-types/1.0',
        sections: [
          sec(
            id: 'chap-001', type: 'chapter', name: 'Chapter',
            sections: [],
          ),
        ],
      ));
      final countErrors = errorsOf(errors, ValidationErrorCategory.countLimit);
      expect(countErrors, isNotEmpty);
    });

    test('error: chapter has wrong child type', () {
      final errors = validate(sf, doc(
        schemaId: 'child-types/1.0',
        sections: [
          sec(
            id: 'chap-001', type: 'chapter', name: 'Chapter',
            sections: [
              sec(id: 'app-001', type: 'appendix', name: 'Appendix'),
            ],
          ),
        ],
      ));
      // Should have count error (no paragraphs) and possibly type error
      final countErrors = errorsOf(errors, ValidationErrorCategory.countLimit);
      expect(countErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 17. PREFIX-RESOLUTION — different prefixes resolving to types
  // ===========================================================================
  group('prefix-resolution schema', () {
    const sf = 'prefix-resolution.1.0.docspecs-schema.yaml';

    test('valid: IDs with correct prefixes resolve to types', () {
      final errors = validate(sf, doc(
        schemaId: 'prefix-resolution/1.0',
        sections: [
          sec(id: 'overview-001', type: 'overview', name: 'Overview'),
          sec(id: 'req-001', type: 'requirement', name: 'Requirements'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });

    test('error: section with unresolvable prefix', () {
      final errors = validate(sf, doc(
        schemaId: 'prefix-resolution/1.0',
        sections: [
          sec(id: 'overview-001', type: 'overview', name: 'Overview'),
          sec(id: 'req-001', type: 'requirement', name: 'Requirements'),
          sec(id: 'xyz-001', name: 'Unknown'),
        ],
      ));
      final typeErrors = errorsOf(errors, ValidationErrorCategory.sectionType);
      expect(typeErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 18. COMPREHENSIVE — many features combined
  // ===========================================================================
  group('comprehensive schema', () {
    const sf = 'comprehensive.1.0.docspecs-schema.yaml';

    test('valid: comprehensive document passes all checks', () {
      final errors = validate(sf, doc(
        schemaId: 'comprehensive/1.0',
        sections: [
          sec(id: 'overview-001', type: 'overview', name: 'Overview',
              text: 'This is a comprehensive overview of the project that meets the minimum length.'),
          sec(id: 'REQ-001', type: 'requirement', name: 'Requirement',
              text: 'The system shall provide authentication.',
              tags: ['priority', 'status'],
              fields: {'title': 'Auth', 'status': 'Active'}),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isEmpty);
      expect(errorsOf(errors, ValidationErrorCategory.tags), isEmpty);
    });

    test('error: overview text too short', () {
      final errors = validate(sf, doc(
        schemaId: 'comprehensive/1.0',
        sections: [
          sec(id: 'overview-001', type: 'overview', name: 'Overview',
              text: 'Too short.'),
          sec(id: 'REQ-001', type: 'requirement', name: 'Requirement',
              text: 'The system shall work.',
              tags: ['priority'],
              fields: {'title': 'X', 'status': 'Active'}),
        ],
      ));
      final textErrors = errorsOf(errors, ValidationErrorCategory.textContent);
      expect(textErrors, isNotEmpty);
    });

    test('error: requirement with invalid tags', () {
      final errors = validate(sf, doc(
        schemaId: 'comprehensive/1.0',
        sections: [
          sec(id: 'overview-001', type: 'overview', name: 'Overview',
              text: 'This is a comprehensive overview of the project that meets the minimum length.'),
          sec(id: 'REQ-001', type: 'requirement', name: 'Requirement',
              text: 'The system shall handle validations.',
              tags: ['priority', 'severity', 'unknown'],
              fields: {'title': 'Validation', 'status': 'Active'}),
        ],
      ));
      final tagErrors = errorsOf(errors, ValidationErrorCategory.tags);
      expect(tagErrors, isNotEmpty);
    });

    test('error: requirement with bad ID pattern', () {
      final errors = validate(sf, doc(
        schemaId: 'comprehensive/1.0',
        sections: [
          sec(id: 'overview-001', type: 'overview', name: 'Overview',
              text: 'This is a comprehensive overview of the project that meets the minimum length.'),
          sec(id: 'req-bad-id', type: 'requirement', name: 'Bad Req',
              text: 'The system shall do something.',
              tags: ['priority'],
              fields: {'title': 'X', 'status': 'Active'}),
        ],
      ));
      final idErrors = errorsOf(errors, ValidationErrorCategory.sectionId);
      expect(idErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 19. STRICT — title (5-100, max 1), body (50+, pattern), code (dart)
  // ===========================================================================
  group('strict schema', () {
    const sf = 'strict.1.0.docspecs-schema.yaml';

    test('valid: meets all strict requirements', () {
      final errors = validate(sf, doc(
        schemaId: 'strict/1.0',
        sections: [
          sec(id: 'title-001', type: 'title', name: 'Title',
              text: 'A Valid Title Here'),
          sec(id: 'body-001', type: 'body', name: 'Body',
              text: 'This is the body section with more than fifty characters. It Contains uppercase letters.'),
          sec(id: 'code-001', type: 'code', name: 'Code',
              format: 'dart',
              text: '```dart\nvoid main() {}\n```'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.textContent), isEmpty);
      expect(errorsOf(errors, ValidationErrorCategory.format), isEmpty);
    });

    test('error: title too short', () {
      final errors = validate(sf, doc(
        schemaId: 'strict/1.0',
        sections: [
          sec(id: 'title-001', type: 'title', name: 'Title', text: 'OK'),
          sec(id: 'body-001', type: 'body', name: 'Body',
              text: 'This is a valid body section with enough text and Uppercase letters present.'),
          sec(id: 'code-001', type: 'code', name: 'Code',
              format: 'dart',
              text: '```dart\nvoid main() {}\n```'),
        ],
      ));
      final textErrors = errorsOf(errors, ValidationErrorCategory.textContent);
      expect(textErrors, isNotEmpty);
    });

    test('error: body too short and missing uppercase', () {
      final errors = validate(sf, doc(
        schemaId: 'strict/1.0',
        sections: [
          sec(id: 'title-001', type: 'title', name: 'Title',
              text: 'A Valid Title'),
          sec(id: 'body-001', type: 'body', name: 'Body',
              text: 'short lowercase'),
          sec(id: 'code-001', type: 'code', name: 'Code',
              format: 'dart',
              text: '```dart\nvoid main() {}\n```'),
        ],
      ));
      final textErrors = errorsOf(errors, ValidationErrorCategory.textContent);
      expect(textErrors, isNotEmpty);
    });
  });

  // ===========================================================================
  // 20. EMPTY-DOCUMENT — no required sections
  // ===========================================================================
  group('empty-document schema', () {
    const sf = 'empty-document.1.0.docspecs-schema.yaml';

    test('valid: empty document with no sections required', () {
      final errors = validate(sf, doc(
        schemaId: 'empty-document/1.0',
        sections: [],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });
  });

  // ===========================================================================
  // 21. SCHEMA LOADING — verify schemas parse correctly
  // ===========================================================================
  group('schema loading from fixture files', () {
    test('all fixture schemas load without error', () {
      final dir = Directory(schemasPath);
      final yamlFiles = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList();

      expect(yamlFiles, isNotEmpty, reason: 'No schema files found');

      for (final file in yamlFiles) {
        expect(
          () => SchemaLoader.loadSync(file.path),
          returnsNormally,
          reason: 'Failed to load: ${p.basename(file.path)}',
        );
      }
    });

    test('each schema has correct id from filename', () {
      final dir = Directory(schemasPath);
      final yamlFiles = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList();

      for (final file in yamlFiles) {
        final schema = SchemaLoader.loadSync(file.path);
        final parsed = SchemaFilenameParser.parse(p.basename(file.path));
        expect(schema.id, equals(parsed!.id),
            reason: 'ID mismatch for ${p.basename(file.path)}');
        expect(schema.version, equals(parsed.version),
            reason: 'Version mismatch for ${p.basename(file.path)}');
      }
    });

    test('comprehensive schema has all expected section types', () {
      final schema = SchemaLoader.loadSync(
          p.join(schemasPath, 'comprehensive.1.0.docspecs-schema.yaml'));
      expect(schema.sectionTypes, contains('overview'));
      expect(schema.sectionTypes, contains('requirement'));
      expect(schema.sectionTypes, contains('detail'));
      expect(schema.sectionTypes, contains('contact'));
      expect(schema.formTypes, isNotNull);
      expect(schema.formTypes, contains('contact'));
    });

    test('form-types schema has correct field definitions', () {
      final schema = SchemaLoader.loadSync(
          p.join(schemasPath, 'form-types.1.0.docspecs-schema.yaml'));
      expect(schema.formTypes, isNotNull);
      final form = schema.formTypes!['contact'];
      expect(form, isNotNull);
      expect(form!.fields.length, equals(3));
      expect(form.fields.any((f) => f.fieldname == 'name' && f.required == true), isTrue);
      expect(form.fields.any((f) => f.fieldname == 'email' && f.required == true), isTrue);
      expect(form.fields.any((f) => f.fieldname == 'phone' && f.required == false), isTrue);
    });

    test('subsection-positions schema has declarations', () {
      final schema = SchemaLoader.loadSync(
          p.join(schemasPath, 'subsection-positions.1.0.docspecs-schema.yaml'));
      expect(schema.subsectionDeclarations, isNotNull);
      expect(schema.subsectionDeclarations!['main'], isNotNull);
      expect(schema.subsectionDeclarations!['main']!['summary']?.position, equals('first'));
      expect(schema.subsectionDeclarations!['main']!['detail']?.position, equals('last'));
    });
  });

  // ===========================================================================
  // 22. EDGE CASES
  // ===========================================================================
  group('edge cases', () {
    test('no schema declaration reports error', () {
      final sf = 'minimal.1.0.docspecs-schema.yaml';
      final schema = SchemaLoader.loadSync(p.join(schemasPath, sf));
      final validator = DocSpecsValidator(schema: schema);
      final document = SpecDoc(
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
        schemaId: '',
        sections: [],
      );
      final errors = validator.validate(document);
      final declErrors = errorsOf(errors, ValidationErrorCategory.schemaDeclaration);
      expect(declErrors, isNotEmpty);
    });

    test('unknown section type reports error', () {
      final sf = 'minimal.1.0.docspecs-schema.yaml';
      final errors = validate(sf, doc(
        schemaId: 'minimal/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'Overview'),
          sec(id: 'xyz-001', name: 'Unknown'),
        ],
      ));
      final typeErrors = errorsOf(errors, ValidationErrorCategory.sectionType);
      expect(typeErrors, isNotEmpty);
    });

    test('section with empty ID treated as unknown type', () {
      final sf = 'minimal.1.0.docspecs-schema.yaml';
      final errors = validate(sf, doc(
        schemaId: 'minimal/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'Overview'),
          sec(id: '', name: 'No Type'),
        ],
      ));
      final typeErrors = errorsOf(errors, ValidationErrorCategory.sectionType);
      expect(typeErrors, isNotEmpty);
    });

    test('valid document with only optional sections omitted', () {
      final sf = 'multi-section.1.0.docspecs-schema.yaml';
      final errors = validate(sf, doc(
        schemaId: 'multi-section/1.0',
        sections: [
          sec(id: 'note-001', type: 'note', name: 'Overview'),
          sec(id: 'req-001', type: 'requirement', name: 'Requirements'),
        ],
      ));
      expect(errorsOf(errors, ValidationErrorCategory.structure), isEmpty);
    });
  });

  // ===========================================================================
  // 23. VALIDATION-PROMPTS — verify prompts are preserved (not errors)
  // ===========================================================================
  group('validation-prompts schema', () {
    const sf = 'validation-prompts.1.0.docspecs-schema.yaml';

    test('schema preserves validation prompts', () {
      final schema = SchemaLoader.loadSync(p.join(schemasPath, sf));
      final reqDef = schema.document.sections['requirements'];
      expect(reqDef, isNotNull);
      expect(reqDef!.validationPrompt, isNotEmpty);
      expect(reqDef.subsectionValidationPrompt, isNotEmpty);
    });

    test('section type preserves validation prompt', () {
      final schema = SchemaLoader.loadSync(p.join(schemasPath, sf));
      final reqType = schema.sectionTypes['requirement'];
      expect(reqType, isNotNull);
      expect(reqType!.validationPrompt, isNotEmpty);
    });
  });

  // ===========================================================================
  // 24. CUSTOM-TAGS — verify custom tags are preserved
  // ===========================================================================
  group('custom-tags schema', () {
    const sf = 'custom-tags.1.0.docspecs-schema.yaml';

    test('schema preserves custom tags', () {
      final schema = SchemaLoader.loadSync(p.join(schemasPath, sf));
      expect(schema.customTags, contains('project-name'));
      expect(schema.customTags['project-name'], equals('TestProject'));
      expect(schema.customTags, contains('author'));
    });
  });

  // ===========================================================================
  // 25. ACCESS-KEYS — verify access key configuration
  // ===========================================================================
  group('access-keys schema', () {
    const sf = 'access-keys.1.0.docspecs-schema.yaml';

    test('schema preserves access keys', () {
      final schema = SchemaLoader.loadSync(p.join(schemasPath, sf));
      final overviewDef = schema.document.sections['project-overview'];
      expect(overviewDef, isNotNull);
      expect(overviewDef!.accessKey, equals('overview'));
    });
  });
}
