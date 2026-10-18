'use strict';

/**
 * `SpecDocument.hasValuesUnder` answers from a prefix index rather than a scan
 * of every stored key. The markdown emitter, the validator and the query
 * engine ask it once per model node, so a scan made rendering a large
 * specification quadratic.
 *
 * VI-1 holds the index to the scan it replaces, across every mutator, so a
 * mutation that forgets to drop the index fails here. VI-2 guards the
 * complexity itself. Port of the Dart runtime's value-index test.
 */

const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const { SpecDocument, SpecModel } = require('../tom_som_runtime/index.js');

const _CORPUS = path.join(__dirname, '..', '..', 'tom_som_conformance', 'corpus');

/**
 * The predicate the index must reproduce: a stored key equal to `query`, or
 * continuing it after a `/` or a `-`. (This port has no path normalizer.)
 */
function scan(doc, query) {
  const json = doc.toJson();
  for (const store of ['content', 'forms', 'lists', 'headlines', 'codeSpecs']) {
    for (const k of Object.keys(json[store] || {})) {
      if (k === query || k.startsWith(`${query}/`) || k.startsWith(`${query}-`)) {
        return true;
      }
    }
  }
  return false;
}

const PROBES = [
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

/** The fixed probes plus every stored key and every one of its prefixes. */
function probesFor(doc) {
  const out = new Set(PROBES);
  const json = doc.toJson();
  for (const store of ['content', 'forms', 'lists', 'headlines', 'codeSpecs']) {
    for (const k of Object.keys(json[store] || {})) {
      for (let i = 0; i <= k.length; i++) out.add(k.substring(0, i));
      out.add(`${k}/x`);
      out.add(`${k}-9`);
    }
  }
  return out;
}

function expectAgrees(doc, when) {
  for (const p of probesFor(doc)) {
    assert.strictEqual(doc.hasValuesUnder(p), scan(doc, p), `${when}: "${p}"`);
  }
}

test('VI-1: the index agrees with a full scan after every mutator', () => {
  const d = new SpecDocument();
  expectAgrees(d, 'empty');
  d.setContent('DEMO/TTL', 'Hello');
  expectAgrees(d, 'setContent');
  d.setHeadline('DEMO/SUM', 'Summary');
  expectAgrees(d, 'setHeadline');
  d.setCodeSpec('DEMO/DET', 'a.b');
  expectAgrees(d, 'setCodeSpec');
  d.setFormField('DEMO/CARD-LST-1/content', 'note', 'x');
  expectAgrees(d, 'setFormField');
  const item = d.addListItem('DEMO/items');
  d.setContent(`${item}/label`, 'First');
  d.addListItem('DEMO/items');
  expectAgrees(d, 'addListItem');
  d.setItemSectionId(item, 'ITEM-A');
  expectAgrees(d, 'setItemSectionId');
  d.setContent('DEMO/TTL', '');
  expectAgrees(d, 'setContent to empty');
  d.setHeadline('DEMO/SUM', '');
  expectAgrees(d, 'setHeadline to empty');
  d.setCodeSpec('DEMO/DET', '');
  expectAgrees(d, 'setCodeSpec to empty');
  d.setFormField('DEMO/CARD-LST-1/content', 'note', '');
  expectAgrees(d, 'setFormField to empty');
  d.removeListItem(item);
  expectAgrees(d, 'removeListItem');
  d.setHeadline('DEMO/SUM', 'Again');
  expectAgrees(d, 'setHeadline again');
  d.removeValuesUnder('DEMO/SUM');
  expectAgrees(d, 'removeValuesUnder');

  d.loadJson({
    content: { 'DEMO/REF-LST-1': 'spec' },
    lists: { 'DEMO/REF-LST': { seq: 1, items: ['DEMO/REF-LST-1'] } },
  });
  expectAgrees(d, 'loadJson');
  d.removeValuesUnder('DEMO');
  expectAgrees(d, 'removeValuesUnder root');
});

test('VI-1: the index agrees with a full scan after every list move case', () => {
  const read = (n) => JSON.parse(fs.readFileSync(path.join(_CORPUS, n), 'utf8'));
  const model = SpecModel.fromJson(read('model.meta.json'));
  let moved = 0;
  for (const c of read('list_move_cases.json').cases) {
    const d = new SpecDocument();
    d.loadJson(c.state);
    expectAgrees(d, `${c.name}: before move`);
    try {
      d.moveListItem(
        model,
        c.move.itemPath,
        c.move.toIndex,
        c.move.toList === undefined ? null : c.move.toList,
      );
      moved++;
    } catch (_) {
      // A refused move leaves the document as it was; still checked below.
    }
    expectAgrees(d, `${c.name}: after move`);
  }
  assert.ok(moved > 0, 'at least one corpus move succeeded');
});

test('VI-2: hasValuesUnder is not a scan of every stored key', () => {
  // 20,000 stored values and 20,000 queries. A per-query scan costs 4 * 10^8
  // key comparisons; the index answers in milliseconds. The bound is
  // generous, so only the complexity class can fail it.
  const n = 20000;
  const d = new SpecDocument();
  for (let i = 0; i < n; i++) {
    d.setContent(`ROOT/S${Math.floor(i / 100)}/F${i}`, `v${i}`);
  }
  const start = process.hrtime.bigint();
  let hits = 0;
  for (let i = 0; i < n; i++) {
    if (d.hasValuesUnder(`ROOT/S${Math.floor(i / 100)}/F${i}`)) hits++;
    if (d.hasValuesUnder(`ROOT/S${Math.floor(i / 100)}/G${i}`)) hits--;
  }
  const ms = Number(process.hrtime.bigint() - start) / 1e6;
  assert.strictEqual(hits, n);
  assert.ok(ms < 2000, `took ${ms} ms`);
});
