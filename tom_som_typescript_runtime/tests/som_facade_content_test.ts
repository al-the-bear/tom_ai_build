#!/usr/bin/env node
/**
 * Behavioural test for the {@link SomList} content convenience (roadmap item 9):
 * the `addContent(...)` append-and-set helper plus the `contents` ordered read.
 *
 * The real element facades are generated centrally (this test cannot run the
 * generator), so this stand-in `_ContentItem` reproduces what an emitted
 * content-only item facade does: a `content` getter/setter over the item's
 * **nested `<path>/content` leaf** — the exact leaf `addContent`/`contents`
 * target. It asserts the append writes that leaf (visible through both the typed
 * handle and the generic document) and that `contents` yields it in order,
 * coalescing a missing leaf to `''`.
 *
 * Build with `tsc`, then run `node dist/tests/som_facade_content_test.js`.
 */

import { SomList, SomNode, SpecDocument } from '../src/index';

// A content-only element facade: its single field is the nested `<path>/content`
// leaf, mirroring what the emitter produces for a `content`-bearing item.
class _ContentItem extends SomNode {
  get content(): string {
    return this.doc.content(`${this.path}/content`) || '';
  }

  set content(v: string) {
    this.doc.setContent(`${this.path}/content`, v);
  }
}

function _list(doc: SpecDocument, pattern: string | null = null): SomList<_ContentItem> {
  return new SomList<_ContentItem>(
    doc,
    'root/items',
    (d, p) => new _ContentItem(d, p),
    pattern,
  );
}

let _passed = 0;
const _failed: string[] = [];

function _eq(name: string, actual: unknown, expected: unknown): void {
  if (actual === expected) {
    _passed += 1;
  } else {
    _failed.push(`${name}: expected ${String(expected)}, got ${String(actual)}`);
  }
}

// (a) addContent appends an item AND sets its content leaf — visible via the
// returned typed handle and via the generic document at `<path>/content`.
{
  const doc = new SpecDocument();
  const list = _list(doc);
  const item = list.addContent('hello');
  _eq('addContent: length is 1', list.length, 1);
  _eq('addContent: handle sees content', item.content, 'hello');
  _eq('addContent: generic doc sees leaf', doc.content(`${item.path}/content`), 'hello');
}

// (b) addContent honours the list's section-id pattern (like add).
{
  const doc = new SpecDocument();
  const list = _list(doc, 'ITEM-xxx');
  const item = list.addContent('a', null, new Date(2026, 0, 1));
  _eq('addContent(pattern): item got a section id', typeof item.$sectionId, 'string');
  _eq('addContent(pattern): section id non-empty', (item.$sectionId || '').length > 0, true);
  _eq('addContent(pattern): content still set', item.content, 'a');
}

// (c) addContent accepts a section-id override.
{
  const doc = new SpecDocument();
  const list = _list(doc, 'ITEM-xxx');
  const item = list.addContent('body', 'ITEM-042');
  _eq('addContent(override): section id honoured', item.$sectionId, 'ITEM-042');
  _eq('addContent(override): content set', item.content, 'body');
}

// (d) contents yields every item's content leaf in insertion order.
{
  const doc = new SpecDocument();
  const list = _list(doc);
  list.addContent('one');
  list.addContent('two');
  list.addContent('three');
  _eq('contents: ordered join', list.contents.join(','), 'one,two,three');
}

// (e) contents coalesces a missing/unset content leaf to ''.
{
  const doc = new SpecDocument();
  const list = _list(doc);
  list.addContent('filled');
  list.add(); // plain append, no content leaf written
  list.addContent('after');
  _eq('contents: missing leaf → empty string', list.contents.join('|'), 'filled||after');
}

if (_failed.length === 0) {
  console.log(`som_facade_content_test: all ${_passed} checks passed.`);
  process.exit(0);
} else {
  console.error(`som_facade_content_test: ${_failed.length} FAILED (of ${_passed + _failed.length}):`);
  for (const f of _failed) {
    console.error(`  - ${f}`);
  }
  process.exit(1);
}
