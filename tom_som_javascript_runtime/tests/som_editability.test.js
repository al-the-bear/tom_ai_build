'use strict';

/**
 * Unit tests for the non-throwing SOM §4.2 editability classifier (SOM §21) —
 * the JavaScript port of the Dart `somEditabilityFor` tests. Mirrors the Dart
 * cases: null/'' → editable; same-major older/equal → editable; newer minor →
 * rejected; different major → cross-major; unparseable → invalid; and it never
 * throws where `checkSomModelVersion` throws.
 *
 * Also a facade behavioural check for a root's static `editabilityFor(...)` — the
 * generated root facade cannot be regenerated here, so we stand up a minimal
 * subclass shaped exactly like the emitter output (extends `SomNode`, static
 * `MODEL_VERSION`, `editabilityFor` delegating to `somEditabilityFor`).
 */

const { test } = require('node:test');
const assert = require('node:assert');

const {
  SomEditability,
  somEditabilityFor,
  checkSomModelVersion,
  SomVersionError,
  SomNode,
} = require('../tom_som_runtime/index.js');

const GEN = '2.3';

test('null document version is editable (brand-new document)', () => {
  assert.strictEqual(somEditabilityFor(GEN, null), SomEditability.editable);
});

test('undefined document version is editable', () => {
  assert.strictEqual(somEditabilityFor(GEN, undefined), SomEditability.editable);
});

test('empty-string document version is editable', () => {
  assert.strictEqual(somEditabilityFor(GEN, ''), SomEditability.editable);
});

test('same major, older minor is editable', () => {
  assert.strictEqual(somEditabilityFor(GEN, '2.1'), SomEditability.editable);
});

test('same major, equal minor is editable', () => {
  assert.strictEqual(somEditabilityFor(GEN, '2.3'), SomEditability.editable);
});

test('same major, newer minor is rejected', () => {
  assert.strictEqual(
    somEditabilityFor(GEN, '2.4'),
    SomEditability.rejectedNewerMinor,
  );
});

test('different (lower) major is read-only cross-major', () => {
  assert.strictEqual(
    somEditabilityFor(GEN, '1.9'),
    SomEditability.readOnlyCrossMajor,
  );
});

test('different (higher) major is read-only cross-major', () => {
  assert.strictEqual(
    somEditabilityFor(GEN, '3.0'),
    SomEditability.readOnlyCrossMajor,
  );
});

test('unparseable stamp (missing minor) is invalidVersion', () => {
  assert.strictEqual(somEditabilityFor(GEN, '2'), SomEditability.invalidVersion);
});

test('unparseable stamp (non-numeric) is invalidVersion', () => {
  assert.strictEqual(
    somEditabilityFor(GEN, 'x.y'),
    SomEditability.invalidVersion,
  );
});

test('unparseable stamp (three parts) is invalidVersion', () => {
  assert.strictEqual(
    somEditabilityFor(GEN, '2.3.1'),
    SomEditability.invalidVersion,
  );
});

test('somEditabilityFor never throws where checkSomModelVersion throws', () => {
  for (const bad of ['2.4', '1.9', '3.0', '2', 'x.y', '2.3.1']) {
    // The classifier returns a value without throwing...
    assert.doesNotThrow(() => somEditabilityFor(GEN, bad));
    assert.notStrictEqual(somEditabilityFor(GEN, bad), SomEditability.editable);
    // ...for exactly the same inputs the throwing checker rejects.
    assert.throws(() => checkSomModelVersion(GEN, bad), SomVersionError);
  }
});

test('checkSomModelVersion stays silent exactly where classifier is editable', () => {
  for (const ok of [null, undefined, '', '2.1', '2.3']) {
    assert.strictEqual(somEditabilityFor(GEN, ok), SomEditability.editable);
    assert.doesNotThrow(() => checkSomModelVersion(GEN, ok));
  }
});

test('root facade static editabilityFor delegates to somEditabilityFor', () => {
  // Minimal stand-in for a generated root facade, shaped like the emitter output.
  class FakeRoot extends SomNode {
    static MODEL_VERSION = GEN;

    constructor(doc, documentVersion = null) {
      super(doc, 'root');
      checkSomModelVersion(FakeRoot.MODEL_VERSION, documentVersion);
    }

    static editabilityFor(documentVersion) {
      return somEditabilityFor(FakeRoot.MODEL_VERSION, documentVersion);
    }
  }

  assert.strictEqual(FakeRoot.editabilityFor(null), SomEditability.editable);
  assert.strictEqual(FakeRoot.editabilityFor('2.1'), SomEditability.editable);
  assert.strictEqual(
    FakeRoot.editabilityFor('2.4'),
    SomEditability.rejectedNewerMinor,
  );
  assert.strictEqual(
    FakeRoot.editabilityFor('1.0'),
    SomEditability.readOnlyCrossMajor,
  );
  assert.strictEqual(
    FakeRoot.editabilityFor('bad'),
    SomEditability.invalidVersion,
  );
  // editabilityFor never throws even where the constructor's check would.
  assert.doesNotThrow(() => FakeRoot.editabilityFor('2.4'));
});
