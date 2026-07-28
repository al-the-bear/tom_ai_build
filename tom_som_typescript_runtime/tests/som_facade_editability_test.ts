#!/usr/bin/env node
/**
 * Behavioural test for the root facade's `static editabilityFor(...)` (SOM
 * §21).
 *
 * The real facade is generated centrally (this test cannot run the generator),
 * so this stand-in `_FakeRoot` reproduces *verbatim* what
 * `SomTypeScriptEmitter` emits on a root class — a `MODEL_VERSION`, a SOM §4.2
 * constructor check, and the new `static editabilityFor` delegating to
 * `somEditabilityFor(MODEL_VERSION, documentVersion)`. It asserts the emitted
 * shape classifies documents identically to the pure classifier.
 *
 * Build with `tsc`, then run `node dist/tests/som_facade_editability_test.js`.
 */

import {
  SomEditability,
  SomNode,
  SomVersionError,
  SpecDocument,
  checkSomModelVersion,
  somEditabilityFor,
} from '../src/index';

// Mirrors the emitter output for a root class at model version 1.2.
class _FakeRoot extends SomNode {
  static readonly MODEL_VERSION: string = '1.2';

  constructor(doc: SpecDocument, documentVersion: string | null = null) {
    super(doc, 'root');
    checkSomModelVersion(_FakeRoot.MODEL_VERSION, documentVersion);
  }

  static editabilityFor(documentVersion: string | null): SomEditability {
    return somEditabilityFor(_FakeRoot.MODEL_VERSION, documentVersion);
  }
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

// editabilityFor mirrors somEditabilityFor(MODEL_VERSION, ...) — no throw.
_eq('root: null → editable', _FakeRoot.editabilityFor(null), SomEditability.editable);
_eq('root: same → editable', _FakeRoot.editabilityFor('1.2'), SomEditability.editable);
_eq('root: older minor → editable', _FakeRoot.editabilityFor('1.0'), SomEditability.editable);
_eq('root: newer minor → rejectedNewerMinor', _FakeRoot.editabilityFor('1.5'), SomEditability.rejectedNewerMinor);
_eq('root: cross-major → readOnlyCrossMajor', _FakeRoot.editabilityFor('2.0'), SomEditability.readOnlyCrossMajor);
_eq('root: garbage → invalidVersion', _FakeRoot.editabilityFor('nope'), SomEditability.invalidVersion);

// The constructor still THROWS where editabilityFor reports non-editable.
const doc = new SpecDocument();
try {
  new _FakeRoot(doc, '2.0');
  _failed.push('root: constructor should throw on cross-major');
} catch (e) {
  if (e instanceof SomVersionError) {
    _passed += 1;
  } else {
    _failed.push(`root: constructor threw unexpected ${String(e)}`);
  }
}
// ...and does NOT throw where editabilityFor reports editable.
try {
  new _FakeRoot(doc, '1.0');
  _passed += 1;
} catch (e) {
  _failed.push(`root: constructor should not throw on editable, got ${String(e)}`);
}

if (_failed.length === 0) {
  console.log(`som_facade_editability_test: all ${_passed} checks passed.`);
  process.exit(0);
} else {
  console.error(`som_facade_editability_test: ${_failed.length} FAILED (of ${_passed + _failed.length}):`);
  for (const f of _failed) {
    console.error(`  - ${f}`);
  }
  process.exit(1);
}
