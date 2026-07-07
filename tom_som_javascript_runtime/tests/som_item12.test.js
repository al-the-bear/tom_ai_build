'use strict';

/**
 * Unit tests for the item-12 conveniences — the JavaScript port of the Dart
 * `SpecModel.rootByType (item 12)` and `SpecDocument.toMarkdown (item 12)`
 * groups (`spec_model_test.dart`, `spec_document_markdown_test.dart`).
 *
 *   * {@link SpecModel.rootByType} — the root whose `.type` matches, or a
 *     TypeError (the argument-error class) naming the missing type and the ones
 *     that exist.
 *   * {@link SpecDocument.toMarkdown} — one-call render: explicit `rootType`,
 *     or the single populated root as the default (with a plain Error when the
 *     default is ambiguous — zero or more than one populated root).
 *
 * The CS12-D3 error-class split is asserted directly: a bad `rootType` argument
 * is a `TypeError`, while an ambiguous document state is a plain `Error` that is
 * *not* a `TypeError`.
 */

const { test } = require('node:test');
const assert = require('node:assert');

const {
  SpecModel,
  SpecDocument,
  SpecDocumentMarkdown,
} = require('../tom_som_runtime/index.js');

/** A two-root model with empty class graphs (rootByType needs only the roots). */
function twoRootModel() {
  return SpecModel.fromJson({
    roots: [
      { type: 'Alpha', title: 'Alpha Doc', sectionId: 'A00' },
      { type: 'Beta', title: 'Beta Doc', sectionId: 'B00' },
    ],
    classes: {},
  });
}

/** A single-root model with a content leaf, mirroring the Dart markdown fixture. */
function demoModel() {
  return SpecModel.fromJson({
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
        ],
      },
    },
  });
}

/** A demo document with one populated content leaf under the DemoDoc root. */
function populatedDemo() {
  const doc = new SpecDocument();
  doc.setContent('D00/D00-OVR', 'An overview paragraph.\nWith two lines.');
  return doc;
}

// --- SpecModel.rootByType (item 12) ---------------------------------------

test('rootByType returns the root whose type matches', () => {
  const model = twoRootModel();
  assert.strictEqual(model.rootByType('Alpha').title, 'Alpha Doc');
  assert.strictEqual(model.rootByType('Beta').sectionId, 'B00');
});

test('rootByType throws naming the missing and available types', () => {
  const model = twoRootModel();
  assert.throws(
    () => model.rootByType('Gamma'),
    (err) =>
      err instanceof TypeError &&
      err.message.includes('Gamma') &&
      err.message.includes('Alpha') &&
      err.message.includes('Beta'),
  );
});

// --- SpecDocument.toMarkdown (item 12) ------------------------------------

test('toMarkdown matches the explicit codec output for an explicit rootType', () => {
  const model = demoModel();
  const doc = populatedDemo();
  const oneLiner = doc.toMarkdown(model, 'DemoDoc');
  const explicit = new SpecDocumentMarkdown(model, doc).exportRoot(
    model.rootByType('DemoDoc'),
  );
  assert.strictEqual(oneLiner, explicit);
});

test('toMarkdown defaults to the single populated root when rootType is omitted', () => {
  const model = demoModel();
  const doc = populatedDemo();
  assert.strictEqual(doc.toMarkdown(model), doc.toMarkdown(model, 'DemoDoc'));
});

test('toMarkdown throws when no root is populated', () => {
  const model = demoModel();
  assert.throws(
    () => new SpecDocument().toMarkdown(model),
    (err) =>
      err instanceof Error &&
      !(err instanceof TypeError) &&
      err.message.includes('no populated root'),
  );
});

test('toMarkdown throws naming the candidates when more than one root is populated', () => {
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
  assert.throws(
    () => doc.toMarkdown(model),
    (err) =>
      err instanceof Error &&
      !(err instanceof TypeError) &&
      err.message.includes('Alpha') &&
      err.message.includes('Beta'),
  );
});
