import 'package:test/test.dart';
import 'package:tom_doc_specs/src/models/spec_doc.dart';
import 'package:tom_doc_specs/src/models/spec_section.dart';
import 'package:tom_doc_specs/src/validation/prompt_expander.dart';

void main() {
  group('PromptExpander', () {
    late PromptExpander expander;
    late SpecDoc document;

    SpecSection makeSection({
      String id = 'test-001',
      String name = 'Test Section',
      String text = 'Some text content.',
      String? type,
      List<String> tags = const [],
      int index = 0,
      int lineNumber = 10,
      Map<String, String> fields = const {},
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
      List<SpecSection>? sections,
    }) {
      return SpecDoc(
        index: 0,
        lineNumber: 1,
        rawHeadline: 'Document',
        name: 'Document',
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
        sections: sections,
      );
    }

    setUp(() {
      expander = PromptExpander();
    });

    test('expands \${id}', () {
      final section = makeSection(id: 'REQ-001');
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Section ${id}', section: section, document: document),
        'Section REQ-001',
      );
    });

    test('expands \${text}', () {
      final section = makeSection(text: 'Hello world');
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Content: ${text}', section: section, document: document),
        'Content: Hello world',
      );
    });

    test('expands \${index}', () {
      final section = makeSection(index: 3);
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Index: ${index}', section: section, document: document),
        'Index: 3',
      );
    });

    test('expands \${lineNumber}', () {
      final section = makeSection(lineNumber: 42);
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Line: ${lineNumber}', section: section, document: document),
        'Line: 42',
      );
    });

    test('expands \${type}', () {
      final section = makeSection(type: 'requirement');
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Type: ${type}', section: section, document: document),
        'Type: requirement',
      );
    });

    test('expands \${tags}', () {
      final section = makeSection(tags: ['urgent', 'api']);
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Tags: ${tags}', section: section, document: document),
        'Tags: urgent, api',
      );
    });

    test('expands \${fields}', () {
      final section = makeSection(fields: {'status': 'open'});
      document = makeDocument(sections: [section]);
      final result = expander.expand(r'Fields: ${fields}', section: section, document: document);
      expect(result, contains('"status":"open"'));
    });

    test('expands \${fields.fieldName}', () {
      final section = makeSection(fields: {'status': 'open', 'priority': 'high'});
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Status: ${fields.status}', section: section, document: document),
        'Status: open',
      );
    });

    test('expands \${text[fieldname]} for form fields', () {
      final section = makeSection(text: 'Method: POST\nPath: /api/users');
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Method: ${text[method]}', section: section, document: document),
        'Method: POST',
      );
    });

    test('expands \${text[]} for preamble', () {
      final section = makeSection(text: 'Preamble text here.\nField: value');
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Preamble: ${text[]}', section: section, document: document),
        'Preamble: Preamble text here.',
      );
    });

    test('expands multiple placeholders', () {
      final section = makeSection(id: 'REQ-001', lineNumber: 10, type: 'requirement');
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(
          r'Verify ${id} at line ${lineNumber} is of type ${type}.',
          section: section,
          document: document,
        ),
        'Verify REQ-001 at line 10 is of type requirement.',
      );
    });

    group('parent access', () {
      test('expands \${parent.id}', () {
        final child = makeSection(id: 'child-001', type: 'detail');
        final parent = makeSection(
          id: 'parent-001',
          type: 'component',
          sections: [child],
        );
        document = makeDocument(sections: [parent]);
        expect(
          expander.expand(r'Parent: ${parent.id}', section: child, document: document),
          'Parent: parent-001',
        );
      });

      test('expands \${parent.type}', () {
        final child = makeSection(id: 'child-001');
        final parent = makeSection(
          id: 'parent-001',
          type: 'component',
          sections: [child],
        );
        document = makeDocument(sections: [parent]);
        expect(
          expander.expand(r'Parent type: ${parent.type}', section: child, document: document),
          'Parent type: component',
        );
      });

      test('returns empty for parent when section is top-level', () {
        final section = makeSection(id: 'top-001');
        document = makeDocument(sections: [section]);
        expect(
          expander.expand(r'Parent: ${parent.id}', section: section, document: document),
          'Parent: ',
        );
      });
    });

    test('preserves unknown placeholders', () {
      final section = makeSection();
      document = makeDocument(sections: [section]);
      expect(
        expander.expand(r'Unknown: ${unknown}', section: section, document: document),
        r'Unknown: ${unknown}',
      );
    });
  });
}
