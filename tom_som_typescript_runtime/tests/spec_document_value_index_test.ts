#!/usr/bin/env node
/**
 * `SpecDocument.hasValuesUnder` answers from a prefix index rather than a scan
 * of every stored key. The markdown emitter, the validator and the query
 * engine ask it once per model node, so a scan made rendering a large
 * specification quadratic.
 *
 * VI-1 holds the index to the scan it replaces, across every mutator, so a
 * mutation that forgets to drop the index fails here. VI-2 guards the
 * complexity itself. A port of the Dart reference's value-index tests.
 *
 * Build with `tsc`, then run `node dist/tests/spec_document_value_index_test.js`.
 * Exit code 0 == all green.
 */

import { SpecDocument, SpecModel } from '../src/index';

let _passed = 0;
const _failed: string[] = [];

function _check(name: string, ok: boolean, detail = ''): void {
  if (ok) {
    _passed++;
  } else {
    _failed.push(detail ? `${name}: ${detail}` : name);
  }
}

/**
 * The predicate the index must reproduce: a stored key equal to `query`, or
 * continuing it after a `/` or a `-`.
 */
function _scan(d: SpecDocument, query: string): boolean {
  const json = d.toJson() as Record<string, Record<string, unknown> | undefined>;
  for (const store of ['content', 'forms', 'lists', 'headlines', 'codeSpecs']) {
    for (const k of Object.keys(json[store] || {})) {
      if (k === query || k.startsWith(`${query}/`) || k.startsWith(`${query}-`)) {
        return true;
      }
    }
  }
  return false;
}

const _probes = [
  'DEMO',
  'DEMO/TTL',
  'DEMO/TT',
  'DEMO/SUM',
  'DEMO/DET',
  'DEMO/items',
  'DEMO/items-1',
  'DEMO/items-1/label',
  'DEMO/items-2',
  'DEMO/items-3',
  'DEMO/REF-LST',
  'DEMO/REF',
  'DEMO/CARD-LST-1',
  'OTHER',
  '',
];

function _expectAgrees(d: SpecDocument, when: string): void {
  for (const p of _probes) {
    const got = d.hasValuesUnder(p);
    const want = _scan(d, p);
    _check(`VI-1 ${when}: "${p}"`, got === want, `index ${got}, scan ${want}`);
  }
}

/** A minimal model with one list, so `moveListItem` can be exercised. */
const _model = SpecModel.fromJson({
  roots: [{ type: 'Demo', title: 'Demo', sectionId: 'DEMO' }],
  classes: {
    Demo: {
      name: 'Demo',
      sectionId: 'DEMO',
      fields: [
        { name: 'items', kind: 'list', elementType: 'Item', elementIsComplex: true },
      ],
    },
    Item: {
      name: 'Item',
      fields: [{ name: 'label', kind: 'content' }],
    },
  },
});

function testAgreesAfterEveryMutator(): void {
  const d = new SpecDocument();
  _expectAgrees(d, 'empty');
  d.setContent('DEMO/TTL', 'Hello');
  _expectAgrees(d, 'setContent');
  d.setHeadline('DEMO/SUM', 'Summary');
  _expectAgrees(d, 'setHeadline');
  d.setCodeSpec('DEMO/DET', 'a.b');
  _expectAgrees(d, 'setCodeSpec');
  d.setFormField('DEMO/CARD-LST-1/content', 'note', 'x');
  _expectAgrees(d, 'setFormField');
  const item = d.addListItem('DEMO/items');
  d.setContent(`${item}/label`, 'First');
  const second = d.addListItem('DEMO/items');
  _expectAgrees(d, 'addListItem');
  d.setItemSectionId(item, 'ITEM-A');
  _expectAgrees(d, 'setItemSectionId');
  d.moveListItem(_model, second, 0);
  _expectAgrees(d, 'moveListItem');
  d.setContent('DEMO/TTL', '');
  _expectAgrees(d, 'setContent to empty');
  d.setFormField('DEMO/CARD-LST-1/content', 'note', '');
  _expectAgrees(d, 'setFormField to empty');
  d.setHeadline('DEMO/SUM', '');
  d.setCodeSpec('DEMO/DET', '');
  _expectAgrees(d, 'setHeadline/setCodeSpec to empty');
  d.setHeadline('DEMO/SUM', 'Summary');
  d.removeListItem(d.listItems('DEMO/items')[0]);
  _expectAgrees(d, 'removeListItem');
  d.removeValuesUnder('DEMO/SUM');
  _expectAgrees(d, 'removeValuesUnder');

  d.loadJson({
    content: { 'DEMO/REF-LST-1': 'spec' },
    lists: { 'DEMO/REF-LST': { seq: 1, items: ['DEMO/REF-LST-1'] } },
  });
  _expectAgrees(d, 'loadJson');

  d.removeValuesUnder('DEMO/REF-LST');
  _expectAgrees(d, 'removeValuesUnder after loadJson');
}

function testIsNotAScan(): void {
  // 20,000 stored values and 20,000 queries. A per-query scan costs 4 * 10^8
  // key comparisons; the index answers in milliseconds. The bound is generous,
  // so only the complexity class can fail it.
  const n = 20000;
  const d = new SpecDocument();
  for (let i = 0; i < n; i++) {
    d.setContent(`ROOT/S${Math.floor(i / 100)}/F${i}`, `v${i}`);
  }
  const start = Date.now();
  let hits = 0;
  for (let i = 0; i < n; i++) {
    if (d.hasValuesUnder(`ROOT/S${Math.floor(i / 100)}/F${i}`)) hits++;
    if (d.hasValuesUnder(`ROOT/S${Math.floor(i / 100)}/G${i}`)) hits--;
  }
  const elapsed = Date.now() - start;
  _check('VI-2 hits', hits === n, `${hits} != ${n}`);
  _check('VI-2 under 2 s', elapsed < 2000, `${elapsed} ms`);
}

function main(): number {
  testAgreesAfterEveryMutator();
  testIsNotAScan();

  const total = _passed + _failed.length;
  if (_failed.length > 0) {
    console.log(`FAIL: ${_failed.length}/${total} checks failed`);
    for (const f of _failed) {
      console.log(`  - ${f}`);
    }
    return 1;
  }
  console.log(`OK: ${total} checks passed`);
  return 0;
}

process.exit(main());
