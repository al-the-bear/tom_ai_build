#!/usr/bin/env node
/**
 * The table layout of the Markdown emitter (SOM §11.4, §11.5): form tables
 * between `Field:` paragraphs, reference lines, record tables and section
 * tables, each all or nothing with its fallback, and the anchor every heading
 * carries. A port of `tom_som_dart_runtime/test/
 * spec_document_markdown_form_tables_test.dart` (FT1–FT8) and
 * `spec_document_markdown_list_tables_test.dart` (RL, RT, ST, FL); the whole
 * layout is pinned by the conformance golden `expected.tables.md`.
 *
 * Build with `tsc`, then run `node dist/tests/spec_document_markdown_tables_test.js`.
 * Exit code 0 == all green.
 */

import {
  SpecDocument,
  SpecDocumentMarkdown,
  SpecModel,
} from '../src/index';

let _passed = 0;
const _failed: string[] = [];

function _check(name: string, condition: boolean, detail = ''): void {
  if (condition) {
    _passed++;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

function _equal(name: string, got: string, want: string): void {
  _check(name, got === want, `\n--- got\n${got}\n--- want\n${want}`);
}

/** The body below the heading carrying `id`, up to the next heading. */
function _body(markdown: string, id: string): string {
  const lines = markdown.split('\n');
  const start = lines.findIndex((l) => l.includes(`<!--[${id}]`));
  let end = -1;
  for (let i = start + 1; i < lines.length; i++) {
    if (lines[i].startsWith('#')) {
      end = i;
      break;
    }
  }
  return lines
    .slice(start + 1, end < 0 ? lines.length : end)
    .join('\n')
    .trim();
}

// --- form tables (FT) ---------------------------------------------------------

/**
 * One form with fields in declaration order: two short ones, a flagged one, a
 * code field, two more short ones; and a list of items.
 */
const _formModelJson = {
  roots: [{ type: 'Doc', title: 'Trial Document', sectionId: 'TRI' }],
  classes: {
    Doc: {
      name: 'Doc',
      sectionId: 'TRI',
      fields: [
        {
          name: 'entity',
          kind: 'form',
          sectionId: 'TRI-ENT',
          formFields: [
            { name: 'entityName', label: 'Entity Name', type: 'String' },
            { name: 'tableName', label: 'Table Name', type: 'String' },
            {
              name: 'rationale',
              label: 'Rationale',
              type: 'String',
              multiParagraph: true,
            },
            { name: 'pattern', label: 'Pattern', type: 'String', code: true },
            { name: 'description', label: 'Description', type: 'String' },
            { name: 'owner', label: 'Owner', type: 'String' },
          ],
        },
        {
          name: 'items',
          kind: 'list',
          elementType: 'Item',
          elementIsComplex: true,
          sectionId: 'TRI-ITM-LST',
          sectionIdPattern: 'TRI-ITM-xxx',
        },
      ],
    },
    Item: {
      name: 'Item',
      fields: [{ name: 'label', kind: 'content', sectionId: 'TRI-LBL' }],
    },
  },
};

const _FORM = 'TRI/TRI-ENT';

function _renderForm(doc: SpecDocument): string {
  const model = SpecModel.fromJson(_formModelJson);
  return new SpecDocumentMarkdown(model, doc).exportRoot(model.roots[0]);
}

function testFormTables(): void {
  {
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'entityName', 'Customer');
    doc.setFormField(_FORM, 'tableName', 'customers');
    doc.setFormField(
      _FORM,
      'description',
      'A party that places orders.  \nIt may hold several accounts.',
    );
    doc.setFormField(_FORM, 'owner', 'Sales');
    _equal(
      'FT1 table – text – table',
      _body(_renderForm(doc), 'TRI-ENT'),
      '| TomSpecField | Value |\n| --- | --- |\n' +
        '| EntityName | Customer |\n| TableName | customers |\n\n' +
        'Description: A party that places orders.  \n' +
        'It may hold several accounts.\n\n' +
        '| TomSpecField | Value |\n| --- | --- |\n| Owner | Sales |',
    );
  }
  {
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'entityName', 'Customer');
    doc.setFormField(
      _FORM,
      'description',
      'A party that places orders.\nIt may hold several accounts.',
    );
    doc.setFormField(_FORM, 'owner', 'Sales');
    _equal(
      'FT1b a wrapped paragraph is one row, joined',
      _body(_renderForm(doc), 'TRI-ENT'),
      '| TomSpecField | Value |\n| --- | --- |\n' +
        '| EntityName | Customer |\n' +
        '| Description | A party that places orders. It may hold several accounts. |\n' +
        '| Owner | Sales |',
    );
  }
  for (const value of [
    'Orders:\n- one\n- two',
    'A quote\n> follows',
    'A title\n===',
    'Hard  \nbreak',
    'Hard\\\nbreak',
    ' indented\nline',
    'A row\n| a | b |',
  ]) {
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'description', value);
    doc.setFormField(_FORM, 'owner', 'Sales');
    const body = _body(_renderForm(doc), 'TRI-ENT');
    _check(`FT1c stays a paragraph: ${JSON.stringify(value)}`, body.includes('Description: '), body);
  }
  {
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'entityName', 'Customer');
    doc.setFormField(_FORM, 'rationale', 'One short line.');
    doc.setFormField(_FORM, 'owner', 'Sales');
    _equal(
      'FT2 multiParagraph is a paragraph',
      _body(_renderForm(doc), 'TRI-ENT'),
      '| TomSpecField | Value |\n| --- | --- |\n| EntityName | Customer |\n\n' +
        'Rationale: One short line.\n\n' +
        '| TomSpecField | Value |\n| --- | --- |\n| Owner | Sales |',
    );
  }
  {
    const long = new Array(400).fill('word').join(' ');
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'description', long);
    _equal(
      'FT3 no length limit',
      _body(_renderForm(doc), 'TRI-ENT'),
      `| TomSpecField | Value |\n| --- | --- |\n| Description | ${long} |`,
    );
  }
  {
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'entityName', 'A | B');
    doc.setFormField(_FORM, 'pattern', '^(a|b)$');
    _equal(
      'FT4 escapes and code spans',
      _body(_renderForm(doc), 'TRI-ENT'),
      '| TomSpecField | Value |\n| --- | --- |\n' +
        '| EntityName | A \\| B |\n| Pattern | `^(a\\|b)$` |',
    );
  }
  {
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'entityName', 'already \\| escaped');
    doc.setFormField(_FORM, 'tableName', 'has <!-- a comment -->');
    doc.setFormField(_FORM, 'description', '- a one-line list');
    doc.setFormField(_FORM, 'owner', 'Sales');
    const body = _body(_renderForm(doc), 'TRI-ENT');
    _check('FT5 escaped pipe', body.includes('EntityName: already \\| escaped'), body);
    _check('FT5 comment', body.includes('TableName: has <!-- a comment -->'), body);
    _check('FT5 block', body.includes('Description: - a one-line list'), body);
    _check('FT5 table after', body.endsWith('| Owner | Sales |'), body);
  }
  {
    const doc = new SpecDocument();
    doc.setContent(
      _FORM,
      'The fields at a glance:\n\n' +
        '| TomSpecField | Value |\n| --- | --- |\n| Colour | red |\n\n' +
        '| Field | Value |\n| --- | --- |\n| Owner | Finance |',
    );
    doc.setFormField(_FORM, 'owner', 'Sales');
    const body = _body(_renderForm(doc), 'TRI-ENT');
    const lines = body.split('\n');
    _equal('FT6 header escaped', lines[2], ' | TomSpecField | Value |');
    _equal('FT6 other header kept', lines[6], '| Field | Value |');
    _check('FT6 table after', body.endsWith('| Owner | Sales |'), body);
  }
  {
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'owner', 'Sales');
    const item = doc.addListItem('TRI/TRI-ITM-LST');
    doc.setContent(`${item}/TRI-LBL`, 'First');
    doc.setCodeSpec(_FORM, 'CsEntity');
    const md = _renderForm(doc);
    _check('FT7 root anchor', md.includes('# <!--[TRI]--> <a id="TRI"></a> Trial Document'), md);
    _check(
      'FT7 anchor after keys',
      md.includes('## <!--[TRI-ENT] codeSpec="CsEntity"--> <a id="TRI-ENT"></a> '),
      md,
    );
    _check('FT7 list anchor', md.includes('## <!--[TRI-ITM-LST]--> <a id="TRI-ITM-LST"></a> '), md);
    _check('FT7 item anchor', md.includes('### <!--[TRI-ITM-1]--> <a id="TRI-ITM-1"></a> '), md);
  }
  {
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'entityName', 'Customer');
    doc.setFormField(_FORM, 'owner', 'Sales');
    const md = _renderForm(doc);
    const table =
      '| TomSpecField | Value |\n| --- | --- |\n' +
      '| EntityName | Customer |\n| Owner | Sales |';
    _equal('FT8 table', _body(md, 'TRI-ENT'), table);
    const codec = new SpecDocumentMarkdown(
      SpecModel.fromJson(_formModelJson),
      new SpecDocument(),
    );
    const fromTables = codec.parse(md);
    const fromFields = codec.parse(
      md.replace(table, 'EntityName: Customer\n\nOwner: Sales'),
    );
    _check('FT8 tables clean', fromTables.rejections.length === 0);
    _check('FT8 fields clean', fromFields.rejections.length === 0);
    _equal(
      'FT8 same forms',
      JSON.stringify(fromFields.forms),
      JSON.stringify(fromTables.forms),
    );
    _equal(
      'FT8 values',
      JSON.stringify(fromTables.forms[_FORM]),
      JSON.stringify({ entityName: 'Customer', owner: 'Sales' }),
    );
  }
  {
    // PT5: a wrapped one-paragraph value is written in its cell joined; the
    // parse keeps the joined line (SOM §11.4), emit(parse(emit(doc))) is
    // byte-identical, and the older Field:-line layout keeps the line breaks.
    const doc = new SpecDocument();
    doc.setFormField(_FORM, 'entityName', 'Customer');
    doc.setFormField(_FORM, 'owner', 'Sales,\nwith Support on weekends');
    const md = _renderForm(doc);
    const codec = new SpecDocumentMarkdown(
      SpecModel.fromJson(_formModelJson),
      new SpecDocument(),
    );
    const parsed = codec.parse(md);
    _check('PT5 clean', parsed.rejections.length === 0);
    _equal(
      'PT5 joined value',
      JSON.stringify(parsed.forms[_FORM]),
      JSON.stringify({ entityName: 'Customer', owner: 'Sales, with Support on weekends' }),
    );
    const again = new SpecDocument();
    again.setFormField(_FORM, 'entityName', 'Customer');
    again.setFormField(_FORM, 'owner', parsed.forms[_FORM]['owner']);
    _equal('PT5 byte-identical', _renderForm(again), md);
    const older = codec.parse(
      md.replace(
        '| TomSpecField | Value |\n| --- | --- |\n' +
          '| EntityName | Customer |\n| Owner | Sales, with Support on weekends |',
        'EntityName: Customer\n\nOwner: Sales,\nwith Support on weekends',
      ),
    );
    _equal(
      'PT5 older layout keeps the line break',
      JSON.stringify(older.forms[_FORM]),
      JSON.stringify({ entityName: 'Customer', owner: 'Sales,\nwith Support on weekends' }),
    );
  }
}

// --- list and section tables (RL, RT, ST, FL) -----------------------------------

function _f(name: string): Record<string, unknown> {
  return { name, label: name, type: 'String' };
}

function _form(
  name: string,
  sectionId: string | null,
  fields: Record<string, unknown>[],
): Record<string, unknown> {
  return {
    name,
    kind: 'form',
    ...(sectionId !== null ? { sectionId } : {}),
    formFields: fields,
  };
}

function _list(
  name: string,
  element: string,
  sectionId: string,
  pattern: string,
): Record<string, unknown> {
  return {
    name,
    kind: 'list',
    elementType: element,
    elementIsComplex: true,
    sectionId,
    sectionIdPattern: pattern,
  };
}

/**
 * Three roots: `REQ` (requirements: a reference list, a records list, a list
 * of attributes), `INF` (information: the entities, and a reference list
 * within the same document), and `ALL`, a projection reaching both.
 */
const _listModel = SpecModel.fromJson({
  roots: [
    { type: 'Req', title: 'Requirements', sectionId: 'REQ' },
    { type: 'Inf', title: 'Information', sectionId: 'INF' },
    { type: 'All', title: 'All', sectionId: 'ALL' },
  ],
  classes: {
    Req: {
      name: 'Req',
      sectionId: 'REQ',
      fields: [
        _list('entities', 'EntityRef', 'REFE-ENTI-LST', 'REFE-ENTI-xxx'),
        _list('rules', 'Rule', 'RULE-LST', 'RULE-xxx'),
        _list('attributes', 'Attribute', 'ATTR-LST', 'ATTR-xxx'),
      ],
    },
    Inf: {
      name: 'Inf',
      sectionId: 'INF',
      fields: [
        _list('entities', 'Entity', 'ENT-LST', 'ENT-xxx'),
        _list('related', 'EntityRef', 'REFE-ENTI-LST', 'REFE-ENTI-xxx'),
      ],
    },
    All: {
      name: 'All',
      sectionId: 'ALL',
      fields: [
        { name: 'req', kind: 'complex', type: 'Req', sectionId: 'REQ' },
        { name: 'inf', kind: 'complex', type: 'Inf', sectionId: 'INF' },
      ],
    },
    Entity: {
      name: 'Entity',
      sectionId: 'ENT',
      fields: [_form('content', null, [_f('name')])],
    },
    EntityRef: {
      name: 'EntityRef',
      sectionId: 'REFE',
      fields: [
        _form('content', null, [_f('crud')]),
        {
          ..._form('relatedEntity', 'REFE-RELA-REF', [
            { ..._f('ref'), refersTo: ['ENT.@sectionId'] },
          ]),
          annotations: [{ name: 'Reference' }],
        },
      ],
    },
    Rule: {
      name: 'Rule',
      sectionId: 'RULE',
      fields: [
        _form('content', null, [_f('statement'), _f('source'), _f('owner')]),
      ],
    },
    Attribute: {
      name: 'Attribute',
      sectionId: 'ATTR',
      fields: [
        _form('identity', 'ATTR-IDEN', [_f('columnName'), _f('description')]),
        _form('dataType', 'ATTR-DATA', [_f('dataType')]),
        _list('constraints', 'Constraint', 'ATTR-CONS-LST', 'ATTR-CONS-xxx'),
        { name: 'notes', kind: 'content', sectionId: 'ATTR-NOTE' },
      ],
    },
    Constraint: {
      name: 'Constraint',
      sectionId: 'ATTR-CONS',
      fields: [_form('content', null, [_f('mandatory'), _f('unique')])],
    },
  },
});

function _render(
  doc: SpecDocument,
  rootType: string,
  stem: string | null = 'demo',
  files: Record<string, string> = {},
): string {
  return new SpecDocumentMarkdown(_listModel, doc, {
    fileStem: stem,
    documentFiles: files,
  }).exportRoot(_listModel.roots.find((r) => r.type === rootType)!);
}

function _addRefs(doc: SpecDocument, list: string, ids: string[]): void {
  for (const id of ids) {
    const item = doc.addListItem(list);
    doc.setFormField(`${item}/REFE-RELA-REF`, 'ref', id);
  }
}

function testReferenceLines(): void {
  {
    const doc = new SpecDocument();
    _addRefs(doc, 'REQ/REFE-ENTI-LST', ['ENT-CUSTOMER', 'ENT-ORDER']);
    const md = _render(doc, 'Req');
    _equal(
      'RL1 refs div',
      _body(md, 'REFE-ENTI-LST'),
      '::: {.refs}\n' +
        '[ENT-CUSTOMER](demo.inf.tomspecs.md#ENT-CUSTOMER), ' +
        '[ENT-ORDER](demo.inf.tomspecs.md#ENT-ORDER)\n:::',
    );
    _check('RL1 no item headings', !md.includes('REFE-ENTI-1'), md);
  }
  {
    const doc = new SpecDocument();
    _addRefs(doc, 'INF/REFE-ENTI-LST', ['ENT-CUSTOMER']);
    _equal(
      'RL2 same document',
      _body(_render(doc, 'Inf'), 'REFE-ENTI-LST'),
      '::: {.refs}\n[ENT-CUSTOMER](#ENT-CUSTOMER)\n:::',
    );
  }
  {
    const doc = new SpecDocument();
    _addRefs(doc, 'REQ/REFE-ENTI-LST', ['ENT-CUSTOMER']);
    const mapped = _body(_render(doc, 'Req', 'demo', { INF: 'model.md' }), 'REFE-ENTI-LST');
    _check('RL3 mapped file', mapped.includes('[ENT-CUSTOMER](model.md#ENT-CUSTOMER)'), mapped);
    const noStem = _body(_render(doc, 'Req', null), 'REFE-ENTI-LST');
    _check('RL3 no stem', noStem.includes('[ENT-CUSTOMER](inf.tomspecs.md#ENT-CUSTOMER)'), noStem);
  }
  {
    const doc = new SpecDocument();
    _addRefs(doc, 'REQ/REFE-ENTI-LST', ['ENT-CUSTOMER', 'ENT-ORDER']);
    const second = doc.listItems('REQ/REFE-ENTI-LST')[1];
    doc.setFormField(`${second}/content`, 'crud', 'read');
    const md = _render(doc, 'Req');
    _check('RL4 no refs div', !md.includes('::: {.refs}'), md);
    _check('RL4 item 1', md.includes('<!--[REFE-ENTI-1]--> <a id="REFE-ENTI-1"></a>'), md);
    _check('RL4 item 2', md.includes('<!--[REFE-ENTI-2]--> <a id="REFE-ENTI-2"></a>'), md);
  }
}

function testRecordTables(): void {
  {
    const doc = new SpecDocument();
    const r1 = doc.addListItem('REQ/RULE-LST');
    doc.setFormField(`${r1}/content`, 'statement', 'A grant | ends');
    doc.setFormField(`${r1}/content`, 'source', 'C2.1');
    const r2 = doc.addListItem('REQ/RULE-LST');
    doc.setFormField(`${r2}/content`, 'statement', 'Another rule');
    _equal(
      'RT1 records table',
      _body(_render(doc, 'Req'), 'RULE-LST'),
      '::: {.records}\n| Id | Statement | Source |\n| --- | --- | --- |\n' +
        '| <a id="RULE-1"></a>RULE-1 | A grant \\| ends | C2.1 |\n' +
        '| <a id="RULE-2"></a>RULE-2 | Another rule |  |\n:::',
    );
  }
  {
    const doc = new SpecDocument();
    const r1 = doc.addListItem('REQ/RULE-LST');
    doc.setFormField(`${r1}/content`, 'statement', 'One');
    doc.setHeadline(r1, 'First rule');
    const r2 = doc.addListItem('REQ/RULE-LST');
    doc.setFormField(`${r2}/content`, 'statement', 'Two');
    _equal(
      'RT2 Title column',
      _body(_render(doc, 'Req'), 'RULE-LST'),
      '::: {.records}\n| Id | Title | Statement |\n| --- | --- | --- |\n' +
        '| <a id="RULE-1"></a>RULE-1 | First rule | One |\n' +
        '| <a id="RULE-2"></a>RULE-2 |  | Two |\n:::',
    );
  }
  {
    const doc = new SpecDocument();
    const r1 = doc.addListItem('REQ/RULE-LST');
    doc.setFormField(`${r1}/content`, 'statement', 'One line');
    const r2 = doc.addListItem('REQ/RULE-LST');
    doc.setFormField(`${r2}/content`, 'statement', 'Two\n- lines');
    const md = _render(doc, 'Req');
    _check('RT3 no records div', !md.includes('::: {.records}'), md);
    _check('RT3 item heading', md.includes('<!--[RULE-1]--> <a id="RULE-1"></a>'), md);
    _check('RT3 paragraph', md.includes('Statement: Two\n- lines'), md);
  }
  {
    const doc = new SpecDocument();
    const r1 = doc.addListItem('REQ/RULE-LST');
    doc.setFormField(`${r1}/content`, 'statement', 'One line');
    const r2 = doc.addListItem('REQ/RULE-LST');
    doc.setFormField(`${r2}/content`, 'statement', 'Two\nlines');
    const md = _render(doc, 'Req');
    _check(
      'RT3b a wrapped paragraph is a cell, joined',
      md.includes('| <a id="RULE-2"></a>RULE-2 | Two lines |'),
      md,
    );
  }
}

function testSectionTables(): void {
  {
    const doc = new SpecDocument();
    const a = doc.addListItem('REQ/ATTR-LST');
    doc.setFormField(`${a}/ATTR-IDEN`, 'columnName', 'name');
    doc.setFormField(`${a}/ATTR-IDEN`, 'description', 'Display name.');
    doc.setFormField(`${a}/ATTR-DATA`, 'dataType', 'string');
    const c = doc.addListItem(`${a}/ATTR-CONS-LST`);
    doc.setFormField(`${c}/content`, 'mandatory', 'Yes');
    doc.setFormField(`${c}/content`, 'unique', 'Per parent');
    const md = _render(doc, 'Req');
    _equal(
      'ST1 section table',
      _body(md, 'ATTR-1'),
      '| Section | TomSpecField | Value |\n| --- | --- | --- |\n' +
        '| <a id="ATTR-1/ATTR-IDEN"></a>ATTR-IDEN | ColumnName | name |\n' +
        '|  | Description | Display name. |\n' +
        '| <a id="ATTR-1/ATTR-DATA"></a>ATTR-DATA | DataType | string |\n' +
        '| <a id="ATTR-1/ATTR-CONS-1"></a>ATTR-CONS-LST / ATTR-CONS-1 | Mandatory | Yes |\n' +
        '|  | Unique | Per parent |',
    );
    _check('ST1 no child headings', !md.includes('<!--[ATTR-IDEN]-->'), md);
  }
  {
    const doc = new SpecDocument();
    const a = doc.addListItem('REQ/ATTR-LST');
    doc.setFormField(`${a}/ATTR-IDEN`, 'columnName', 'name');
    doc.setContent(`${a}/ATTR-NOTE`, 'A free note.');
    const md = _render(doc, 'Req');
    _check('ST2 no section table', !md.includes('| Section | TomSpecField | Value |'), md);
    _check('ST2 form heading', md.includes('<!--[ATTR-IDEN]--> <a id="ATTR-1/ATTR-IDEN"></a>'), md);
    _check('ST2 note heading', md.includes('<!--[ATTR-NOTE]--> <a id="ATTR-1/ATTR-NOTE"></a>'), md);
  }
  {
    const doc = new SpecDocument();
    const a = doc.addListItem('REQ/ATTR-LST');
    doc.setFormField(`${a}/ATTR-IDEN`, 'columnName', 'name');
    doc.setHeadline(`${a}/ATTR-IDEN`, 'The identity');
    const md = _render(doc, 'Req');
    _check('ST3 no section table', !md.includes('| Section | TomSpecField | Value |'), md);
    _check('ST3 headline kept', md.includes('The identity'), md);
  }
  {
    const doc = new SpecDocument();
    const r = doc.addListItem('REQ/REFE-ENTI-LST');
    doc.setFormField(`${r}/REFE-RELA-REF`, 'ref', 'ENT-CUSTOMER');
    doc.setFormField(`${r}/content`, 'crud', 'read');
    const md = _render(doc, 'Req');
    _check(
      'FL1 refersTo value is a link',
      md.includes('| Ref | [ENT-CUSTOMER](demo.inf.tomspecs.md#ENT-CUSTOMER) |'),
      md,
    );
  }
}

function main(): number {
  testFormTables();
  testReferenceLines();
  testRecordTables();
  testSectionTables();
  if (_failed.length > 0) {
    console.log(`FAIL: ${_failed.length}/${_passed + _failed.length} checks failed`);
    for (const f of _failed) console.log(`  - ${f}`);
    return 1;
  }
  console.log(`OK: ${_passed} checks passed`);
  return 0;
}

process.exit(main());
