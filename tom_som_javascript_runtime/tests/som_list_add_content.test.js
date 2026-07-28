'use strict';

/**
 * Behavioural tests for the SomList convenience members `addContent(...)` and
 * the `contents` getter (SOM §21 content-only list convenience) — the JS port
 * of the Dart `SomList.addContent` / `SomList.contents` tests.
 *
 * `addContent` appends an item using the *same* section-id logic as `add` and
 * writes the value to the nested `<item>/content` leaf; `contents` yields every
 * item's nested content leaf in order, coalescing a missing leaf to ''. Both
 * target the nested leaf, so scalar lists are out of scope.
 *
 * The element facade is a minimal content-only stand-in shaped like the emitter
 * output (extends `SomNode`, a typed `content` accessor delegating to `doc` at
 * the nested `<path>/content` leaf), mirroring the existing test fixtures.
 */

const { test } = require('node:test');
const assert = require('node:assert');

const { SpecDocument, SomNode, SomList } = require('../tom_som_runtime/index.js');

/** A content-only element facade: one typed `content` field at `<path>/content`. */
class ContentItem extends SomNode {
  get content() {
    return this.doc.content(`${this.path}/content`) || '';
  }

  set content(v) {
    this.doc.setContent(`${this.path}/content`, v);
  }
}

const factory = (doc, path) => new ContentItem(doc, path);

const LIST_PATH = 'root/items';
const PATTERN = 'DACEN-ITEM-xxx';

test('addContent appends an item and sets its nested content leaf', () => {
  const doc = new SpecDocument();
  const list = new SomList(doc, LIST_PATH, factory);

  const item = list.addContent('hello');

  // Visible via the returned typed handle...
  assert.strictEqual(item.content, 'hello');
  // ...and via the generic document at the nested <item>/content leaf.
  assert.strictEqual(doc.content(`${item.path}/content`), 'hello');
  assert.strictEqual(list.length, 1);
});

test('addContent honours the list section-id pattern', () => {
  const doc = new SpecDocument();
  const list = new SomList(doc, LIST_PATH, factory, PATTERN);
  const date = new Date(2026, 0, 1); // Jan 1 -> two-letter date "AA"

  const item = list.addContent('body', null, date);

  assert.strictEqual(item.$sectionId, 'DACEN-ITEM-AA1');
  assert.strictEqual(item.content, 'body');
});

test('addContent accepts a section-id override', () => {
  const doc = new SpecDocument();
  const list = new SomList(doc, LIST_PATH, factory, PATTERN);

  const item = list.addContent('body', 'DACEN-ITEM-CUSTOM');

  assert.strictEqual(item.$sectionId, 'DACEN-ITEM-CUSTOM');
  assert.strictEqual(item.content, 'body');
});

test('contents yields every item content leaf in order', () => {
  const doc = new SpecDocument();
  const list = new SomList(doc, LIST_PATH, factory);

  list.addContent('first');
  list.addContent('second');
  list.addContent('third');

  assert.deepStrictEqual(list.contents, ['first', 'second', 'third']);
});

test('contents coalesces a missing content leaf to empty string', () => {
  const doc = new SpecDocument();
  const list = new SomList(doc, LIST_PATH, factory);

  list.addContent('present');
  list.add(); // appended with no content leaf written

  assert.deepStrictEqual(list.contents, ['present', '']);
});
