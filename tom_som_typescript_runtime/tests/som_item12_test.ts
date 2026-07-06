#!/usr/bin/env node
/**
 * Tests for the item-12 one-liners: {@link SpecModel.rootByType} and
 * {@link SpecDocument.toMarkdown} — the TypeScript port of the Dart reference
 * groups `SpecModel.rootByType (item 12)` (in `spec_model_test.dart`) and
 * `SpecDocument.toMarkdown (item 12)` (in `spec_document_markdown_test.dart`).
 *
 * Build with `tsc`, then run `node dist/tests/som_item12_test.js`.
 */

import {
  SpecDocument,
  SpecDocumentMarkdown,
  SpecModel,
} from '../src/index';

let _passed = 0;
const _failed: string[] = [];

function _eq(name: string, actual: unknown, expected: unknown): void {
  if (actual === expected) {
    _passed += 1;
  } else {
    _failed.push(`${name}: expected ${String(expected)}, got ${String(actual)}`);
  }
}

function _true(name: string, cond: boolean): void {
  if (cond) {
    _passed += 1;
  } else {
    _failed.push(`${name}: expected true`);
  }
}

/** Asserts `fn` throws an Error whose message contains every `needles` entry. */
function _throwsContaining(name: string, fn: () => unknown, needles: string[]): void {
  try {
    fn();
    _failed.push(`${name}: expected throw, but returned normally`);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const missing = needles.filter((n) => !msg.includes(n));
    if (missing.length === 0) {
      _passed += 1;
    } else {
      _failed.push(`${name}: message '${msg}' missing ${missing.join(', ')}`);
    }
  }
}

// --- fixtures (ported from the Dart tests) --------------------------------

function _twoRootModel(): SpecModel {
  return SpecModel.fromJson({
    roots: [
      { type: 'Alpha', title: 'Alpha Doc', sectionId: 'A00' },
      { type: 'Beta', title: 'Beta Doc', sectionId: 'B00' },
    ],
    classes: {},
  });
}

function _sampleJson(): any {
  return {
    roots: [
      {
        type: 'DemoDoc',
        title: 'Demo Document',
        sectionId: 'D00',
        description: 'A demo document.',
      },
    ],
    classes: {
      DemoDoc: {
        name: 'DemoDoc',
        sectionId: 'D00',
        fields: [
          { name: 'overview', kind: 'content', sectionId: 'D00-OVR' },
          {
            name: 'status',
            kind: 'enum',
            sectionId: 'D00-ST',
            enumValues: ['draft', 'final'],
          },
          {
            name: 'header',
            kind: 'form',
            sectionId: 'D00-HDR',
            formFields: [
              { name: 'author', label: 'Author', type: 'String' },
              { name: 'reviewer', label: 'Reviewer', type: 'String' },
            ],
          },
          { name: 'meta', kind: 'complex', type: 'DemoMeta', sectionId: 'D00-MET' },
          {
            name: 'items',
            kind: 'list',
            elementType: 'DemoItem',
            elementIsComplex: true,
            sectionId: 'D00-ITM',
          },
        ],
      },
      DemoMeta: {
        name: 'DemoMeta',
        sectionId: 'D00-MET',
        fields: [{ name: 'note', kind: 'content', sectionId: 'D00-MET-NOTE' }],
      },
      DemoItem: {
        name: 'DemoItem',
        fields: [
          { name: 'label', kind: 'content', sectionId: 'D01-LBL' },
          { name: 'body', kind: 'content', sectionId: 'D01-BODY' },
        ],
      },
    },
  };
}

function _model(): SpecModel {
  return SpecModel.fromJson(_sampleJson());
}

function _populated(): SpecDocument {
  const doc = new SpecDocument();
  doc.setContent('D00/D00-OVR', 'An overview paragraph.\nWith two lines.');
  doc.setContent('D00/D00-ST', 'final');
  doc.setFormField('D00/D00-HDR', 'author', 'Ada Lovelace');
  doc.setContent('D00/D00-MET/D00-MET-NOTE', 'A note.');
  const item = doc.addListItem('D00/D00-ITM');
  doc.setContent(`${item}/D01-LBL`, 'First item');
  doc.setContent(`${item}/D01-BODY`, 'a body');
  const item2 = doc.addListItem('D00/D00-ITM');
  doc.setContent(`${item2}/D01-LBL`, 'Second item');
  return doc;
}

// --- SpecModel.rootByType (item 12) ---------------------------------------

// returns the root whose type matches
{
  const model = _twoRootModel();
  _eq('rootByType: Alpha title', model.rootByType('Alpha').title, 'Alpha Doc');
  _eq('rootByType: Beta sectionId', model.rootByType('Beta').sectionId, 'B00');
}

// throws naming the missing and available types
{
  const model = _twoRootModel();
  _throwsContaining(
    'rootByType: throws naming types',
    () => model.rootByType('Gamma'),
    ['Gamma', 'Alpha', 'Beta'],
  );
}

// --- SpecDocument.toMarkdown (item 12) ------------------------------------

// matches the explicit codec output for an explicit rootType
{
  const model = _model();
  const doc = _populated();
  const oneLiner = doc.toMarkdown(model, 'DemoDoc');
  const explicit = new SpecDocumentMarkdown(model, doc).exportRoot(
    model.rootByType('DemoDoc'),
  );
  _eq('toMarkdown(rootType): matches explicit codec', oneLiner, explicit);
}

// defaults to the single populated root when rootType is omitted
{
  const model = _model();
  const doc = _populated();
  _eq(
    'toMarkdown(): defaults to single populated root',
    doc.toMarkdown(model),
    doc.toMarkdown(model, 'DemoDoc'),
  );
}

// throws when no root is populated
{
  const model = _model();
  _throwsContaining(
    'toMarkdown(): throws when no populated root',
    () => new SpecDocument().toMarkdown(model),
    ['no populated root'],
  );
}

// throws naming the candidates when more than one root is populated
{
  const model = SpecModel.fromJson({
    roots: [
      { type: 'Alpha', title: 'Alpha Doc', sectionId: 'A00' },
      { type: 'Beta', title: 'Beta Doc', sectionId: 'B00' },
    ],
    classes: {
      Alpha: {
        name: 'Alpha',
        sectionId: 'A00',
        fields: [{ name: 'overview', kind: 'content', sectionId: 'A00-OVR' }],
      },
      Beta: {
        name: 'Beta',
        sectionId: 'B00',
        fields: [{ name: 'overview', kind: 'content', sectionId: 'B00-OVR' }],
      },
    },
  });
  const doc = new SpecDocument();
  doc.setContent('A00/A00-OVR', 'a');
  doc.setContent('B00/B00-OVR', 'b');
  _throwsContaining(
    'toMarkdown(): throws naming populated candidates',
    () => doc.toMarkdown(model),
    ['Alpha', 'Beta'],
  );
  _true('toMarkdown(): two roots are populated', true);
}

if (_failed.length === 0) {
  console.log(`som_item12_test: all ${_passed} checks passed.`);
  process.exit(0);
} else {
  console.error(
    `som_item12_test: ${_failed.length} FAILED (of ${_passed + _failed.length}):`,
  );
  for (const f of _failed) {
    console.error(`  - ${f}`);
  }
  process.exit(1);
}
