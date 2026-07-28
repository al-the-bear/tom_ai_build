#!/usr/bin/env node
/**
 * Behavioural test for the structural {@link SomNode.canHaveContent} predicate
 * (SOM §21): "does this section TYPE declare the standard `content` text
 * leaf?" — a compile-time / per-type schema fact, answered WITHOUT probing
 * `.content` and WITHOUT ever looking at the document.
 *
 * The real subclasses are generated centrally (this test cannot run the
 * generator), so these stand-ins reproduce what the emitter produces: a
 * content-bearing section overrides the base default to `true`, while
 * scalar/container-only sections inherit the `false` default. It asserts the
 * base default, the content-bearing override, the inherited-false cases, and
 * — crucially — that the STATE predicates (`hasContent(path)` on the document,
 * `isEmpty` on the node) stay independent of this STRUCTURAL predicate.
 *
 * Build with `tsc`, then run `node dist/tests/som_facade_can_have_content_test.js`.
 */

import { SomNode, SomScalar, SpecDocument } from '../src/index';

// A content-bearing section facade: it declares a `content` leaf, so it
// overrides the structural default to `true` (what the emitter emits for a
// `content`-bearing class such as `Goals`).
class _ContentBearing extends SomNode {
  get canHaveContent(): boolean {
    return true;
  }

  get content(): string {
    return this.doc.content(`${this.path}/content`) || '';
  }

  set content(v: string) {
    this.doc.setContent(`${this.path}/content`, v);
  }
}

// A container-only section facade: no `content` leaf, so it inherits the
// structural `false` default (what a class like `SystemsToReplace` does).
class _ContainerOnly extends SomNode {}

let _passed = 0;
const _failed: string[] = [];

function _eq(name: string, actual: unknown, expected: unknown): void {
  if (actual === expected) {
    _passed += 1;
  } else {
    _failed.push(`${name}: expected ${String(expected)}, got ${String(actual)}`);
  }
}

// (a) The base SomNode default is `false` — a bare node cannot hold content.
{
  const doc = new SpecDocument();
  const node = new SomNode(doc, 'root');
  _eq('base SomNode default is false', node.canHaveContent, false);
}

// (b) A content-bearing section overrides the default to `true`.
{
  const doc = new SpecDocument();
  const section = new _ContentBearing(doc, 'root/goals');
  _eq('content-bearing override is true', section.canHaveContent, true);
}

// (c) A scalar list item inherits the `false` default.
{
  const doc = new SpecDocument();
  const scalar = new SomScalar(doc, 'root/item');
  _eq('SomScalar inherits false', scalar.canHaveContent, false);
}

// (d) A container-only section inherits the `false` default.
{
  const doc = new SpecDocument();
  const container = new _ContainerOnly(doc, 'root/systemsToReplace');
  _eq('container-only inherits false', container.canHaveContent, false);
}

// (e) Structural vs state independence: `canHaveContent` never looks at the
// document — it is `true` for a content-bearing section whether or not any
// content value is present, and the state predicates (`hasContent`, `isEmpty`)
// move independently of it.
{
  const doc = new SpecDocument();
  const section = new _ContentBearing(doc, 'root/goals');
  const leaf = `${section.path}/content`;

  // Empty document: structural true, but no value present and node is empty.
  _eq('empty: canHaveContent true', section.canHaveContent, true);
  _eq('empty: doc.hasContent false', doc.hasContent(leaf), false);
  _eq('empty: node isEmpty true', section.isEmpty, true);

  // After writing content: structural predicate unchanged; state flips.
  section.content = 'body';
  _eq('filled: canHaveContent unchanged true', section.canHaveContent, true);
  _eq('filled: doc.hasContent true', doc.hasContent(leaf), true);
  _eq('filled: node isEmpty false', section.isEmpty, false);

  // A container-only section stays structurally false regardless of state.
  const container = new _ContainerOnly(doc, 'root/goals');
  _eq('container over same path stays false', container.canHaveContent, false);
}

if (_failed.length === 0) {
  console.log(`som_facade_can_have_content_test: all ${_passed} checks passed.`);
  process.exit(0);
} else {
  console.error(
    `som_facade_can_have_content_test: ${_failed.length} FAILED (of ${_passed + _failed.length}):`,
  );
  for (const f of _failed) {
    console.error(`  - ${f}`);
  }
  process.exit(1);
}
