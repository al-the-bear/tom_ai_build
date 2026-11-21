#!/usr/bin/env node
/**
 * The merge back (SOM §11.10): properties over the strip corpus, beside the
 * cases of `strip_merge_cases.json`. A port of
 * `tom_som_dart_runtime/test/spec_document_merge_test.dart`.
 *
 * Build with `tsc`, then run `node dist/tests/spec_document_merge_test.js`.
 * Exit code 0 == all green.
 */

import * as fs from 'fs';
import * as path from 'path';

import {
  SpecStripMerge,
  SpecStripOptions,
  SpecStripValueRef,
  mergeStrippedValue,
  specStripMergeLabel,
  stripNotationText,
} from '../src/index';

let _passed = 0;
const _failed: string[] = [];

function _check(name: string, condition: boolean, detail = ''): void {
  if (condition) {
    _passed++;
  } else {
    _failed.push(detail ? `${name}: ${detail}` : name);
  }
}

const _PKG_ROOT = path.resolve(__dirname, '..', '..');

function _options(c: any): SpecStripOptions {
  return SpecStripOptions.fromNames({
    drop: c.drop ?? [],
    unmark: c.unmark ?? [],
    appendix: c.appendix ?? [],
    appendixReferences: c.appendixReferences === true,
    headingDivs: c.headingDivs === true,
  });
}

function testOverStripCases(): void {
  const table = JSON.parse(
    fs.readFileSync(
      path.join(_PKG_ROOT, '..', 'tom_som_conformance', 'corpus', 'strip_cases.json'),
      'utf8',
    ),
  );
  for (const c of table.cases) {
    const o = c.text as string;
    const s = stripNotationText(o, _options(c));
    if (s.refused) continue;
    const same = mergeStrippedValue(o, s.text, s.text, s.pieces);
    _check(`unchanged[${c.name}]`, same.text === o && same.restored === s.pieces.length && same.placed.length === 0);
    const e = s.text === '' ? 'An added paragraph.' : `${s.text}\n\nAn added paragraph.`;
    const r = mergeStrippedValue(o, s.text, e, s.pieces);
    _check(
      `addedParagraph[${c.name}]`,
      r.ok && stripNotationText(r.text as string, _options(c)).text === e,
      JSON.stringify(r.toJson()),
    );
  }
}

function testValues(): void {
  const trace = SpecStripOptions.fromNames({ drop: ['trace'] });
  const o = 'Keep this. Gone here (-> C1). Tail.';
  const s = stripNotationText(o, trace);
  const r = mergeStrippedValue(o, s.text, 'Keep this. Tail.', s.pieces);
  _check('conflict.ok', !r.ok && r.text === null);
  const lines = r.conflicts[0].about(new SpecStripValueRef('DEMO/SUM')).reportLines;
  const want = [
    'CONFLICT DEMO/SUM — the edit removed the whole sentence holding the piece',
    '  O: «Keep this. Gone here (-> C1). Tail.»',
    '  B: «Keep this. Gone here. Tail.»',
    '  E: «Keep this. Tail.»',
    '  piece: « (-> C1)»',
  ];
  _check('conflict.reportLines', JSON.stringify(lines) === JSON.stringify(want), JSON.stringify(lines));

  const o2 = 'Alpha (-> A1). Beta [aside]{.aside} gamma (-> B2).';
  const opts = SpecStripOptions.fromNames({ drop: ['trace', 'aside'] });
  const s2 = stripNotationText(o2, opts);
  const e2 = s2.text.replace('Alpha', 'First');
  const r2 = mergeStrippedValue(o2, s2.text, e2, s2.pieces);
  _check(
    'several pieces',
    r2.text === 'First (-> A1). Beta [aside]{.aside} gamma (-> B2).' &&
      r2.restored === 3 &&
      stripNotationText(r2.text, opts).text === e2,
    JSON.stringify(r2.toJson()),
  );
}

function testDocumentHelpers(): void {
  _check('label', specStripMergeLabel(new SpecStripValueRef('A/B')) === 'A/B');
  _check('label.field', specStripMergeLabel(new SpecStripValueRef('A/B', 'f')) === 'A/B / f');
  _check(
    'label.headline',
    specStripMergeLabel(new SpecStripValueRef('A/B', null, true)) === 'A/B (headline)',
  );
  const self = path.join(_PKG_ROOT, 'package.json');
  const text = SpecStripMerge.gitShowFile('HEAD', self);
  _check('gitShowFile', text !== null && text.includes('"name": "tom_som_typescript_runtime"'));
  _check('gitShowFile.unknown', SpecStripMerge.gitShowFile('HEAD', `${self}x`) === null);
}

testOverStripCases();
testValues();
testDocumentHelpers();

if (_failed.length > 0) {
  console.log(`FAIL: ${_failed.length}/${_passed + _failed.length} checks failed`);
  for (const f of _failed) console.log(`  - ${f}`);
  process.exit(1);
}
console.log(`OK: ${_passed} checks passed`);
