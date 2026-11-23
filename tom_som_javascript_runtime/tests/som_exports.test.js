'use strict';

/**
 * The package-root names TS `index.ts` has and this runtime once lacked or
 * spelled differently (runtime parity audit, `runtime_parity.md` § javascript):
 * `formatYamlFloat`, `MILLIS_PER_DAY` and the `K_CODE_SPECS_*` /
 * `K_CODE_SPEC_KIND_ANNOTATION` names beside the JS `K_CODESPECS_*` /
 * `K_CODESPEC_KIND_ANNOTATION` ones. The expected values are the TypeScript
 * runtime's for the same input.
 *
 * When the TypeScript runtime is built beside this package (a workspace
 * checkout), every name its `index.ts` exports is also checked to exist here.
 */

const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');

const R = require('../tom_som_runtime/index.js');

test('formatYamlFloat writes the canonical review-pass float, as TS', () => {
  const cases = [
    [3, '3.0'],
    [-0, '-0.0'],
    [0.1, '0.1'],
    [1e21, '1e+21'],
    [1e-7, '1e-7'],
    [NaN, '.nan'],
    [Infinity, '.inf'],
    [-Infinity, '-.inf'],
    [100000000000000000000, '100000000000000000000.0'],
  ];
  for (const [x, want] of cases) {
    assert.strictEqual(R.formatYamlFloat(x), want, String(x));
  }
  assert.strictEqual(R.formatYamlFloat, require('../tom_som_runtime/yaml.js').floatText);
});

test('MILLIS_PER_DAY is exported', () => {
  assert.strictEqual(R.MILLIS_PER_DAY, 86400000);
});

test('the TS constant names carry the JS constants\' values', () => {
  const pairs = [
    ['K_CODE_SPECS_EXTRACT_FORMAT', 'K_CODESPECS_EXTRACT_FORMAT', 3],
    ['K_CODE_SPEC_KIND_ANNOTATION', 'K_CODESPEC_KIND_ANNOTATION', 'CodeSpecKind'],
    ['K_CODE_SPECS_GATE_RECORD_FILE', 'K_CODESPECS_GATE_RECORD_FILE', 'gate.verdicts.yaml'],
    ['K_CODE_SPECS_GATE_RECORD_FORMAT', 'K_CODESPECS_GATE_RECORD_FORMAT', 1],
    ['K_CODE_SPECS_EXTRACT_FILE_SUFFIX', 'K_CODESPECS_EXTRACT_FILE_SUFFIX', '.extract.yaml'],
    ['K_CODE_SPECS_GATE_DESCOPED', 'K_CODESPECS_GATE_DESCOPED', 'descoped'],
  ];
  for (const [ts, js, value] of pairs) {
    assert.strictEqual(R[ts], value, ts);
    assert.strictEqual(R[js], value, js);
  }
});

test('every name TS index.ts exports exists here (workspace checkout only)', (t) => {
  const tsIndex = path.join(__dirname, '..', '..', 'tom_som_typescript_runtime', 'dist', 'src', 'index.js');
  if (!fs.existsSync(tsIndex)) {
    t.skip('tom_som_typescript_runtime is not built beside this package');
    return;
  }
  const missing = Object.keys(require(tsIndex))
    .filter((n) => !(n in R))
    .filter((n) => !PENDING_PARITY.has(n));
  assert.deepStrictEqual(missing, []);
});

/**
 * TS names this runtime does not have yet, each with the todo that ports it.
 * The reading notation's scanner (`spec_notation.ts`) and the strip of
 * stripped renditions (`spec_document_strip.ts`, SOM §11.10) with its merge
 * back (`spec_document_merge.ts`) are Dart and
 * TypeScript only until their ports: `tspubnondart50` (the scanner), `tspubnondart85`
 * and `tspubnondart92` (the strip) and `tspubnondart99` (the merge), listed in
 * `runtime_parity.md` § Reading view.
 */
const PENDING_PARITY = new Set([
  'registeredNotationKinds',
  'NotationFindingCode',
  'notationSeverity',
  'NotationElement',
  'NotationFinding',
  'NotationScan',
  'scanNotation',
  'countAnnotationsText',
  'specStripKindNames',
  'specStripNotationKinds',
  'SpecStripUsageError',
  'SpecStripOptions',
  'SpecReadableSource',
  'SpecReadableHeader',
  'SpecStripPiece',
  'SpecAppendixEntry',
  'SpecStripTextResult',
  'stripNotationText',
  'SpecStripValueRef',
  'SpecStrippedValue',
  'SpecStripKept',
  'SpecStripFinding',
  'SpecStripResult',
  'SpecDocumentStrip',
  // the merge back (spec_document_merge.ts, SOM §11.10)
  'annotationIssuesText',
  'SpecStripMergePlaced',
  'SpecStripMergeConflict',
  'SpecStripValueMerge',
  'specStripMergeLabel',
  'mergeStrippedValue',
  'SpecStripMergedValue',
  'SpecStripMergeRefusal',
  'SpecStripMergeResult',
  'SpecStripMerge',
]);

test('no pending-parity name is here already (the exception ends with its port)', () => {
  const present = [...PENDING_PARITY].filter((n) => n in R);
  assert.deepStrictEqual(present, []);
});
