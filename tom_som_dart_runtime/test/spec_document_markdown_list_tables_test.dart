// The reading-view trial layout, part 2 (`formLayout: SpecFormLayout.tables`):
// reference lines, record tables and section tables, each all-or-nothing with
// its fallback, and the anchors they carry. Emit only.

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// Three roots: `REQ` (requirements: a reference list, a records list, a list
/// of attributes), `INF` (information: the entities, and a reference list
/// within the same document), and `ALL`, a projection reaching both.
Map<String, dynamic> _modelJson() => {
  'roots': [
    {'type': 'Req', 'title': 'Requirements', 'sectionId': 'REQ'},
    {'type': 'Inf', 'title': 'Information', 'sectionId': 'INF'},
    {'type': 'All', 'title': 'All', 'sectionId': 'ALL'},
  ],
  'classes': {
    'Req': {
      'name': 'Req',
      'sectionId': 'REQ',
      'fields': [
        _list('entities', 'EntityRef', 'REFE-ENTI-LST', 'REFE-ENTI-xxx'),
        _list('rules', 'Rule', 'RULE-LST', 'RULE-xxx'),
        _list('attributes', 'Attribute', 'ATTR-LST', 'ATTR-xxx'),
      ],
    },
    'Inf': {
      'name': 'Inf',
      'sectionId': 'INF',
      'fields': [
        _list('entities', 'Entity', 'ENT-LST', 'ENT-xxx'),
        _list('related', 'EntityRef', 'REFE-ENTI-LST', 'REFE-ENTI-xxx'),
      ],
    },
    'All': {
      'name': 'All',
      'sectionId': 'ALL',
      'fields': [
        {'name': 'req', 'kind': 'complex', 'type': 'Req', 'sectionId': 'REQ'},
        {'name': 'inf', 'kind': 'complex', 'type': 'Inf', 'sectionId': 'INF'},
      ],
    },
    'Entity': {
      'name': 'Entity',
      'sectionId': 'ENT',
      'fields': [
        _form('content', null, [_f('name')]),
      ],
    },
    'EntityRef': {
      'name': 'EntityRef',
      'sectionId': 'REFE',
      'fields': [
        _form('content', null, [_f('crud')]),
        {
          ..._form('relatedEntity', 'REFE-RELA-REF', [
            {
              ..._f('ref'),
              'refersTo': ['ENT.@sectionId'],
            },
          ]),
          'annotations': [
            {'name': 'Reference'},
          ],
        },
      ],
    },
    'Rule': {
      'name': 'Rule',
      'sectionId': 'RULE',
      'fields': [
        _form('content', null, [_f('statement'), _f('source'), _f('owner')]),
      ],
    },
    'Attribute': {
      'name': 'Attribute',
      'sectionId': 'ATTR',
      'fields': [
        _form('identity', 'ATTR-IDEN', [_f('columnName'), _f('description')]),
        _form('dataType', 'ATTR-DATA', [_f('dataType')]),
        _list('constraints', 'Constraint', 'ATTR-CONS-LST', 'ATTR-CONS-xxx'),
        {'name': 'notes', 'kind': 'content', 'sectionId': 'ATTR-NOTE'},
      ],
    },
    'Constraint': {
      'name': 'Constraint',
      'sectionId': 'ATTR-CONS',
      'fields': [
        _form('content', null, [_f('mandatory'), _f('unique')]),
      ],
    },
  },
};

Map<String, dynamic> _f(String name) => {
  'name': name,
  'label': name,
  'type': 'String',
};

Map<String, dynamic> _form(
  String name,
  String? sectionId,
  List<Map<String, dynamic>> fields,
) => {
  'name': name,
  'kind': 'form',
  'sectionId': ?sectionId,
  'formFields': fields,
};

Map<String, dynamic> _list(
  String name,
  String element,
  String sectionId,
  String pattern,
) => {
  'name': name,
  'kind': 'list',
  'elementType': element,
  'elementIsComplex': true,
  'sectionId': sectionId,
  'sectionIdPattern': pattern,
};

final SpecModel _model = SpecModel.fromJson(_modelJson());

String _render(
  SpecDocument doc,
  String rootType, {
  SpecFormLayout layout = SpecFormLayout.tables,
  String? stem = 'demo',
  Map<String, String> files = const {},
}) => SpecDocumentMarkdown(
  _model,
  doc,
  formLayout: layout,
  fileStem: stem,
  documentFiles: files,
).exportRoot(_model.roots.firstWhere((r) => r.type == rootType));

/// The body below the heading carrying [id], up to the next heading.
String _body(String markdown, String id) {
  final lines = markdown.split('\n');
  final start = lines.indexWhere((l) => l.contains('<!--[$id]'));
  final end = lines.indexWhere((l) => l.startsWith('#'), start + 1);
  return lines
      .sublist(start + 1, end < 0 ? lines.length : end)
      .join('\n')
      .trim();
}

void addRefs(SpecDocument doc, String list, List<String> ids) {
  for (final id in ids) {
    final item = doc.addListItem(list);
    doc.setFormField('$item/REFE-RELA-REF', 'ref', id);
  }
}

void main() {
  group('reference lines', () {
    test('RL1: a list of single references is one refs div of links into '
        'the document that holds the targets', () {
      final doc = SpecDocument();
      addRefs(doc, 'REQ/REFE-ENTI-LST', ['ENT-CUSTOMER', 'ENT-ORDER']);
      final md = _render(doc, 'Req');
      expect(
        _body(md, 'REFE-ENTI-LST'),
        '::: {.refs}\n'
        '[ENT-CUSTOMER](demo.inf.tomspecs.md#ENT-CUSTOMER), '
        '[ENT-ORDER](demo.inf.tomspecs.md#ENT-ORDER)\n'
        ':::',
      );
      expect(md, isNot(contains('REFE-ENTI-1')), reason: 'no item headings');
    });

    test('RL2: within the same document a link is #ID', () {
      final doc = SpecDocument();
      addRefs(doc, 'INF/REFE-ENTI-LST', ['ENT-CUSTOMER']);
      expect(
        _body(_render(doc, 'Inf'), 'REFE-ENTI-LST'),
        '::: {.refs}\n[ENT-CUSTOMER](#ENT-CUSTOMER)\n:::',
      );
    });

    test('RL3: a mapped root and a missing stem name the file', () {
      final doc = SpecDocument();
      addRefs(doc, 'REQ/REFE-ENTI-LST', ['ENT-CUSTOMER']);
      expect(
        _body(_render(doc, 'Req', files: {'INF': 'model.md'}), 'REFE-ENTI-LST'),
        contains('[ENT-CUSTOMER](model.md#ENT-CUSTOMER)'),
      );
      expect(
        _body(_render(doc, 'Req', stem: null), 'REFE-ENTI-LST'),
        contains('[ENT-CUSTOMER](inf.tomspecs.md#ENT-CUSTOMER)'),
      );
    });

    test('RL4: one item with more than its reference falls back to items', () {
      final doc = SpecDocument();
      addRefs(doc, 'REQ/REFE-ENTI-LST', ['ENT-CUSTOMER', 'ENT-ORDER']);
      final second = doc.listItems('REQ/REFE-ENTI-LST')[1];
      doc.setFormField('$second/content', 'crud', 'read');
      final md = _render(doc, 'Req');
      expect(md, isNot(contains('::: {.refs}')));
      expect(md, contains('<!--[REFE-ENTI-1]--> <a id="REFE-ENTI-1"></a>'));
      expect(md, contains('<!--[REFE-ENTI-2]--> <a id="REFE-ENTI-2"></a>'));
    });
  });

  group('record tables', () {
    test('RT1: a list of single forms is one records table with Id anchors '
        'and one column per populated field', () {
      final doc = SpecDocument();
      final r1 = doc.addListItem('REQ/RULE-LST');
      doc
        ..setFormField('$r1/content', 'statement', 'A grant | ends')
        ..setFormField('$r1/content', 'source', 'C2.1');
      final r2 = doc.addListItem('REQ/RULE-LST');
      doc.setFormField('$r2/content', 'statement', 'Another rule');
      expect(
        _body(_render(doc, 'Req'), 'RULE-LST'),
        '::: {.records}\n'
        '| Id | Statement | Source |\n'
        '| --- | --- | --- |\n'
        '| <a id="RULE-1"></a>RULE-1 | A grant \\| ends | C2.1 |\n'
        '| <a id="RULE-2"></a>RULE-2 | Another rule |  |\n'
        ':::',
      );
    });

    test('RT2: a stored headline adds the Title column', () {
      final doc = SpecDocument();
      final r1 = doc.addListItem('REQ/RULE-LST');
      doc
        ..setFormField('$r1/content', 'statement', 'One')
        ..setHeadline(r1, 'First rule');
      final r2 = doc.addListItem('REQ/RULE-LST');
      doc.setFormField('$r2/content', 'statement', 'Two');
      expect(
        _body(_render(doc, 'Req'), 'RULE-LST'),
        '::: {.records}\n'
        '| Id | Title | Statement |\n'
        '| --- | --- | --- |\n'
        '| <a id="RULE-1"></a>RULE-1 | First rule | One |\n'
        '| <a id="RULE-2"></a>RULE-2 |  | Two |\n'
        ':::',
      );
    });

    test('RT3: one value that cannot be a cell falls back to items', () {
      final doc = SpecDocument();
      final r1 = doc.addListItem('REQ/RULE-LST');
      doc.setFormField('$r1/content', 'statement', 'One line');
      final r2 = doc.addListItem('REQ/RULE-LST');
      doc.setFormField('$r2/content', 'statement', 'Two\nlines');
      final md = _render(doc, 'Req');
      expect(md, isNot(contains('::: {.records}')));
      expect(md, contains('<!--[RULE-1]--> <a id="RULE-1"></a>'));
      expect(md, contains('Statement: Two\nlines'));
    });
  });

  group('section tables', () {
    test('ST1: an item whose children are single forms (and a list of form '
        'items) is one Section | TomSpecField | Value table with anchors', () {
      final doc = SpecDocument();
      final a = doc.addListItem('REQ/ATTR-LST');
      doc
        ..setFormField('$a/ATTR-IDEN', 'columnName', 'name')
        ..setFormField('$a/ATTR-IDEN', 'description', 'Display name.')
        ..setFormField('$a/ATTR-DATA', 'dataType', 'string');
      final c = doc.addListItem('$a/ATTR-CONS-LST');
      doc
        ..setFormField('$c/content', 'mandatory', 'Yes')
        ..setFormField('$c/content', 'unique', 'Per parent');
      final md = _render(doc, 'Req');
      expect(
        _body(md, 'ATTR-1'),
        '| Section | TomSpecField | Value |\n'
        '| --- | --- | --- |\n'
        '| <a id="ATTR-IDEN"></a>ATTR-IDEN | ColumnName | name |\n'
        '|  | Description | Display name. |\n'
        '| <a id="ATTR-DATA"></a>ATTR-DATA | DataType | string |\n'
        '| <a id="ATTR-CONS-1"></a>ATTR-CONS-LST / ATTR-CONS-1 | Mandatory | '
        'Yes |\n'
        '|  | Unique | Per parent |',
      );
      expect(md, isNot(contains('<!--[ATTR-IDEN]-->')));
    });

    test('ST2: a child that is not a single form writes every child with its '
        'heading', () {
      final doc = SpecDocument();
      final a = doc.addListItem('REQ/ATTR-LST');
      doc
        ..setFormField('$a/ATTR-IDEN', 'columnName', 'name')
        ..setContent('$a/ATTR-NOTE', 'A free note.');
      final md = _render(doc, 'Req');
      expect(md, isNot(contains('| Section | TomSpecField | Value |')));
      expect(md, contains('<!--[ATTR-IDEN]--> <a id="ATTR-IDEN"></a>'));
      expect(md, contains('<!--[ATTR-NOTE]--> <a id="ATTR-NOTE"></a>'));
    });

    test('ST3: a stored headline on a child keeps the headings', () {
      final doc = SpecDocument();
      final a = doc.addListItem('REQ/ATTR-LST');
      doc
        ..setFormField('$a/ATTR-IDEN', 'columnName', 'name')
        ..setHeadline('$a/ATTR-IDEN', 'The identity');
      final md = _render(doc, 'Req');
      expect(md, isNot(contains('| Section | TomSpecField | Value |')));
      expect(md, contains('The identity'));
    });
  });

  test('FL1: a refersTo value in a form table is written as a link', () {
    final doc = SpecDocument();
    final r = doc.addListItem('REQ/REFE-ENTI-LST');
    doc
      ..setFormField('$r/REFE-RELA-REF', 'ref', 'ENT-CUSTOMER')
      ..setFormField('$r/content', 'crud', 'read');
    final md = _render(doc, 'Req');
    expect(
      md,
      contains('| Ref | [ENT-CUSTOMER](demo.inf.tomspecs.md#ENT-CUSTOMER) |'),
    );
  });

  test('FL2: the fields default writes none of the list and section forms', () {
    final doc = SpecDocument();
    addRefs(doc, 'REQ/REFE-ENTI-LST', ['ENT-CUSTOMER']);
    final r1 = doc.addListItem('REQ/RULE-LST');
    doc.setFormField('$r1/content', 'statement', 'One');
    final md = _render(doc, 'Req', layout: SpecFormLayout.fields);
    expect(md, isNot(contains(':::')));
    expect(md, isNot(contains('<a id=')));
    expect(md, contains('Ref: ENT-CUSTOMER'));
    expect(md, contains('Statement: One'));
  });
}
