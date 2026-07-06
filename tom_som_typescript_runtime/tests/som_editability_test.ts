#!/usr/bin/env node
/**
 * Unit tests for the non-throwing §2.2 editability classifier
 * ({@link somEditabilityFor}) and its throwing companion
 * ({@link checkSomModelVersion}) — a faithful port of the Dart reference cases in
 * `tom_som_dart_runtime` (§ item 8).
 *
 * Build with `tsc`, then run `node dist/tests/som_editability_test.js`. Exit code
 * 0 == all green.
 */

import {
  SomEditability,
  SomVersionError,
  checkSomModelVersion,
  somEditabilityFor,
} from '../src/index';

let _passed = 0;
const _failed: string[] = [];

function _check(name: string, condition: boolean, detail = ''): void {
  if (condition) {
    _passed += 1;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

function _eq(name: string, actual: unknown, expected: unknown): void {
  _check(name, actual === expected, `expected ${String(expected)}, got ${String(actual)}`);
}

function _throws(name: string, fn: () => void): void {
  try {
    fn();
    _check(name, false, 'expected a throw, none occurred');
  } catch (e) {
    _check(name, e instanceof SomVersionError, `expected SomVersionError, got ${String(e)}`);
  }
}

function _noThrow(name: string, fn: () => void): void {
  try {
    fn();
    _check(name, true);
  } catch (e) {
    _check(name, false, `unexpected throw: ${String(e)}`);
  }
}

// --- somEditabilityFor: null / empty document version → editable ------------
_eq('null doc → editable', somEditabilityFor('1.0', null), SomEditability.editable);
_eq('undefined doc → editable', somEditabilityFor('1.0', undefined), SomEditability.editable);
_eq('empty doc → editable', somEditabilityFor('1.0', ''), SomEditability.editable);

// --- same major, minor <= generated → editable ------------------------------
_eq('same version → editable', somEditabilityFor('1.2', '1.2'), SomEditability.editable);
_eq('older minor → editable', somEditabilityFor('1.5', '1.2'), SomEditability.editable);
_eq('minor 0 doc → editable', somEditabilityFor('1.3', '1.0'), SomEditability.editable);

// --- same major, newer minor → rejectedNewerMinor ---------------------------
_eq('newer minor → rejectedNewerMinor', somEditabilityFor('1.2', '1.5'), SomEditability.rejectedNewerMinor);

// --- different major → readOnlyCrossMajor -----------------------------------
_eq('higher major → readOnlyCrossMajor', somEditabilityFor('1.0', '2.0'), SomEditability.readOnlyCrossMajor);
_eq('lower major → readOnlyCrossMajor', somEditabilityFor('2.0', '1.9'), SomEditability.readOnlyCrossMajor);

// --- unparseable document stamp → invalidVersion ----------------------------
_eq('garbage doc → invalidVersion', somEditabilityFor('1.0', 'not-a-version'), SomEditability.invalidVersion);
_eq('single-part doc → invalidVersion', somEditabilityFor('1.0', '1'), SomEditability.invalidVersion);
_eq('three-part doc → invalidVersion', somEditabilityFor('1.0', '1.0.0'), SomEditability.invalidVersion);
_eq('non-numeric doc → invalidVersion', somEditabilityFor('1.0', 'a.b'), SomEditability.invalidVersion);

// --- checkSomModelVersion delegates to the classifier -----------------------
_noThrow('check: null → no throw', () => checkSomModelVersion('1.0', null));
_noThrow('check: editable → no throw', () => checkSomModelVersion('1.5', '1.2'));
_throws('check: cross-major throws', () => checkSomModelVersion('1.0', '2.0'));
_throws('check: newer minor throws', () => checkSomModelVersion('1.2', '1.5'));
_throws('check: invalid throws', () => checkSomModelVersion('1.0', 'not-a-version'));

// checkSomModelVersion throws the SAME per-case messages as the Dart reference.
try {
  checkSomModelVersion('1.0', '2.0');
} catch (e) {
  _check(
    'check: cross-major message',
    e instanceof SomVersionError && e.message.includes('cross-major documents are read-only'),
    `got ${String(e)}`,
  );
}
try {
  checkSomModelVersion('1.2', '1.5');
} catch (e) {
  _check(
    'check: newer-minor message',
    e instanceof SomVersionError && e.message.includes('an older object model cannot edit a newer'),
    `got ${String(e)}`,
  );
}
try {
  checkSomModelVersion('1.0', 'bogus');
} catch (e) {
  _check(
    'check: invalid message',
    e instanceof SomVersionError && e.message.includes('is not a valid major.minor'),
    `got ${String(e)}`,
  );
}

// --- report -----------------------------------------------------------------
if (_failed.length === 0) {
  console.log(`som_editability_test: all ${_passed} checks passed.`);
  process.exit(0);
} else {
  console.error(`som_editability_test: ${_failed.length} FAILED (of ${_passed + _failed.length}):`);
  for (const f of _failed) {
    console.error(`  - ${f}`);
  }
  process.exit(1);
}
