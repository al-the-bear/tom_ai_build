'use strict';

/**
 * Unit tests for the structural `canHaveContent` predicate (SOM §21) — the
 * JavaScript port of the Dart `SomNode.canHaveContent` runtime tests.
 *
 * `canHaveContent` answers, at the **type** level, "does this section type
 * declare the standard `content` text leaf?" — i.e. "can this section hold body
 * text?" — without ever probing `.content` or the document. The `SomNode` base
 * defaults to `false`; a content-bearing section overrides it to `true`. It is
 * deliberately distinct from the two **state** predicates `hasContent(path)`
 * ("value present now?") and `isEmpty` ("subtree empty now?").
 *
 * The element facades below are minimal stand-ins shaped exactly like the
 * emitter output: a content-bearing class adds a typed `content` accessor and
 * overrides `canHaveContent` to `true`; a container-only class overrides nothing
 * and inherits the `false` default.
 */

const { test } = require('node:test');
const assert = require('node:assert');

const { SpecDocument, SomNode, SomScalar } = require('../tom_som_runtime/index.js');

/** A content-bearing section facade (mirrors a generated class such as `Goals`). */
class ContentItem extends SomNode {
  get content() {
    return this.doc.content(`${this.path}/content`) || '';
  }

  set content(v) {
    this.doc.setContent(`${this.path}/content`, v);
  }

  // A content-bearing section overrides the structural default (SOM §21).
  get canHaveContent() {
    return true;
  }
}

/**
 * A container-only section facade: it holds only child sections, no `content`
 * leaf, so it does **not** override `SomNode.canHaveContent` and inherits the
 * `false` default (mirrors a generated class such as `SystemsToReplace`).
 */
class Container extends SomNode {
  get child() {
    return new ContentItem(this.doc, `${this.path}/child`);
  }
}

test('the SomNode base defaults canHaveContent to false (container-only)', () => {
  const doc = new SpecDocument();
  assert.strictEqual(new Container(doc, 'PD00').canHaveContent, false);
});

test('a content-bearing section overrides canHaveContent to true', () => {
  const doc = new SpecDocument();
  assert.strictEqual(
    new ContentItem(doc, 'PD00/METR-ITEM-AB1').canHaveContent,
    true,
  );
});

test('a scalar list item inherits the container-only false default', () => {
  const doc = new SpecDocument();
  assert.strictEqual(new SomScalar(doc, 'PD00/tags-1').canHaveContent, false);
});

test('canHaveContent is structural, not state — independent of any stored value', () => {
  const doc = new SpecDocument();
  const container = new Container(doc, 'PD00');
  const item = new ContentItem(doc, 'PD00/METR-ITEM-AB1');
  // Empty vs filled makes no difference to the schema-level answer.
  assert.strictEqual(container.canHaveContent, false);
  assert.strictEqual(item.canHaveContent, true);
  item.content = 'filled';
  assert.strictEqual(item.canHaveContent, true);
  assert.strictEqual(container.canHaveContent, false);
});
