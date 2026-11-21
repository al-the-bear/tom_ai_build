// The form layout of the Markdown emitter (SOM §11.4): form tables between
// `Field:` paragraphs, and an HTML anchor on every heading. The whole layout
// is pinned by the conformance export golden (`expected.tables.md`); the parse
// of it and of the older `Field:`-line layout is
// spec_document_markdown_parse_tables_test.dart.

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// One form with fields in declaration order: two short ones, a flagged one,
/// a code field, two more short ones; and a list of items.
Map<String, dynamic> _modelJson() => {
  'roots': [
    {'type': 'Doc', 'title': 'Trial Document', 'sectionId': 'TRI'},
  ],
  'classes': {
    'Doc': {
      'name': 'Doc',
      'sectionId': 'TRI',
      'fields': [
        {
          'name': 'entity',
          'kind': 'form',
          'sectionId': 'TRI-ENT',
          'formFields': [
            {'name': 'entityName', 'label': 'Entity Name', 'type': 'String'},
            {'name': 'tableName', 'label': 'Table Name', 'type': 'String'},
            {
              'name': 'rationale',
              'label': 'Rationale',
              'type': 'String',
              'multiParagraph': true,
            },
            {
              'name': 'pattern',
              'label': 'Pattern',
              'type': 'String',
              'code': true,
            },
            {'name': 'description', 'label': 'Description', 'type': 'String'},
            {'name': 'owner', 'label': 'Owner', 'type': 'String'},
          ],
        },
        {
          'name': 'items',
          'kind': 'list',
          'elementType': 'Item',
          'elementIsComplex': true,
          'sectionId': 'TRI-ITM-LST',
          'sectionIdPattern': 'TRI-ITM-xxx',
        },
      ],
    },
    'Item': {
      'name': 'Item',
      'fields': [
        {'name': 'label', 'kind': 'content', 'sectionId': 'TRI-LBL'},
      ],
    },
  },
};

const String _form = 'TRI/TRI-ENT';

String _render(SpecDocument doc) {
  final model = SpecModel.fromJson(_modelJson());
  return SpecDocumentMarkdown(model, doc).exportRoot(model.roots.single);
}

/// The form section's body: the lines after its heading up to the next one.
String _formBody(String markdown) {
  final lines = markdown.split('\n');
  final start = lines.indexWhere((l) => l.contains('<!--[TRI-ENT]-->'));
  final end = lines.indexWhere((l) => l.startsWith('#'), start + 1);
  return lines
      .sublist(start + 1, end < 0 ? lines.length : end)
      .join('\n')
      .trim();
}

void main() {
  test('FT1: table – text – table, in declaration order', () {
    final doc = SpecDocument()
      ..setFormField(_form, 'entityName', 'Customer')
      ..setFormField(_form, 'tableName', 'customers')
      ..setFormField(
        _form,
        'description',
        'A party that places orders.\n'
            'It may hold several accounts.',
      )
      ..setFormField(_form, 'owner', 'Sales');
    expect(
      _formBody(_render(doc)),
      '| TomSpecField | Value |\n'
      '| --- | --- |\n'
      '| EntityName | Customer |\n'
      '| TableName | customers |\n'
      '\n'
      'Description: A party that places orders.\n'
      'It may hold several accounts.\n'
      '\n'
      '| TomSpecField | Value |\n'
      '| --- | --- |\n'
      '| Owner | Sales |',
    );
  });

  test('FT2: a multiParagraph field is a paragraph, even on one line', () {
    final doc = SpecDocument()
      ..setFormField(_form, 'entityName', 'Customer')
      ..setFormField(_form, 'rationale', 'One short line.')
      ..setFormField(_form, 'owner', 'Sales');
    expect(
      _formBody(_render(doc)),
      '| TomSpecField | Value |\n'
      '| --- | --- |\n'
      '| EntityName | Customer |\n'
      '\n'
      'Rationale: One short line.\n'
      '\n'
      '| TomSpecField | Value |\n'
      '| --- | --- |\n'
      '| Owner | Sales |',
    );
  });

  test('FT3: a long one-line value is a row (no length limit)', () {
    final long = List.filled(400, 'word').join(' ');
    final doc = SpecDocument()..setFormField(_form, 'description', long);
    expect(
      _formBody(_render(doc)),
      '| TomSpecField | Value |\n| --- | --- |\n| Description | $long |',
    );
  });

  test('FT4: a cell escapes | as \\|; a code value is its code span', () {
    final doc = SpecDocument()
      ..setFormField(_form, 'entityName', 'A | B')
      ..setFormField(_form, 'pattern', r'^(a|b)$');
    expect(
      _formBody(_render(doc)),
      '| TomSpecField | Value |\n'
      '| --- | --- |\n'
      '| EntityName | A \\| B |\n'
      '| Pattern | `^(a\\|b)\$` |',
    );
  });

  test('FT5: values that cannot be a cell are paragraphs at their place', () {
    final doc = SpecDocument()
      ..setFormField(_form, 'entityName', r'already \| escaped')
      ..setFormField(_form, 'tableName', 'has <!-- a comment -->')
      ..setFormField(_form, 'description', '- a one-line list')
      ..setFormField(_form, 'owner', 'Sales');
    final body = _formBody(_render(doc));
    expect(body, contains(r'EntityName: already \| escaped'));
    expect(body, contains('TableName: has <!-- a comment -->'));
    expect(body, contains('Description: - a one-line list'));
    expect(body, endsWith('| Owner | Sales |'));
  });

  test('FT6: a content line shaped like a layout table header is escaped', () {
    final doc = SpecDocument()
      ..setContent(
        _form,
        'The fields at a glance:\n\n'
        '| TomSpecField | Value |\n'
        '| --- | --- |\n'
        '| Colour | red |\n\n'
        '| Field | Value |\n'
        '| --- | --- |\n'
        '| Owner | Finance |',
      )
      ..setFormField(_form, 'owner', 'Sales');
    final body = _formBody(_render(doc));
    final lines = body.split('\n');
    // The header alone makes a table layout (DI-2), whatever its rows: escaped
    // with one space.
    expect(lines[2], ' | TomSpecField | Value |');
    // Any other header is content as written.
    expect(lines[6], '| Field | Value |');
    expect(body, endsWith('| Owner | Sales |'));
  });

  test('FT7: every heading carries its anchor after the id comment', () {
    final doc = SpecDocument()..setFormField(_form, 'owner', 'Sales');
    final item = doc.addListItem('TRI/TRI-ITM-LST');
    doc
      ..setContent('$item/TRI-LBL', 'First')
      ..setCodeSpec(_form, 'CsEntity');
    final md = _render(doc);
    expect(md, contains('# <!--[TRI]--> <a id="TRI"></a> Trial Document'));
    expect(
      md,
      contains('## <!--[TRI-ENT] codeSpec="CsEntity"--> <a id="TRI-ENT"></a> '),
    );
    expect(md, contains('## <!--[TRI-ITM-LST]--> <a id="TRI-ITM-LST"></a> '));
    expect(md, contains('### <!--[TRI-ITM-1]--> <a id="TRI-ITM-1"></a> '));
  });

  test('FT8: the Field: lines of the older layout parse to the values the '
      'table holds', () {
    final doc = SpecDocument()
      ..setFormField(_form, 'entityName', 'Customer')
      ..setFormField(_form, 'owner', 'Sales');
    final md = _render(doc);
    expect(
      _formBody(md),
      '| TomSpecField | Value |\n| --- | --- |\n'
      '| EntityName | Customer |\n| Owner | Sales |',
    );
    final model = SpecModel.fromJson(_modelJson());
    final codec = SpecDocumentMarkdown(model, SpecDocument());
    final fromTables = codec.parse(md);
    final fromFields = codec.parse(
      md.replaceFirst(
        '| TomSpecField | Value |\n| --- | --- |\n'
            '| EntityName | Customer |\n| Owner | Sales |',
        'EntityName: Customer\n\nOwner: Sales',
      ),
    );
    expect(fromTables.rejections, isEmpty);
    expect(fromFields.rejections, isEmpty);
    expect(fromFields.forms, fromTables.forms);
    expect(fromTables.forms[_form], {
      'entityName': 'Customer',
      'owner': 'Sales',
    });
  });
}
