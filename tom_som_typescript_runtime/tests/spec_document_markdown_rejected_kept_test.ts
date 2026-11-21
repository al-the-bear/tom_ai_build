#!/usr/bin/env node
/**
 * Rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): an import
 * accepting rejections keeps each rejected block as a `rejected` div in the
 * text of the section it stood in (else its parent), at its place. The kept
 * document re-exports and re-imports without a rejection and to the same
 * document, and the validator reports each div as `rejectedBlock`. A port of
 * `tom_som_dart_runtime/test/spec_document_markdown_rejected_kept_test.dart`;
 * the single cases are pinned in the conformance corpus
 * (`markdown_apply_cases.json`).
 *
 * Build with `tsc`, then run
 * `node dist/tests/spec_document_markdown_rejected_kept_test.js`.
 * Exit code 0 == all green.
 */

import * as fs from 'fs';
import * as path from 'path';

import {
  DocSpecsSchema,
  DocSpecsViolationRule,
  SpecDocument,
  SpecDocumentMarkdown,
  SpecMarkdownResult,
  SpecModel,
  validateSpecDocument,
} from '../src/index';

const _CORPUS = path.normalize(
  path.join(path.dirname(path.dirname(__dirname)), '..', 'tom_som_conformance', 'corpus'),
);

let _passed = 0;
const _failed: string[] = [];

function _check(name: string, condition: boolean, detail = ''): void {
  if (condition) {
    _passed++;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

const model = SpecModel.fromJson(
  JSON.parse(fs.readFileSync(path.join(_CORPUS, 'model.meta.json'), 'utf8')),
);
const golden = fs.readFileSync(path.join(_CORPUS, 'expected.tables.md'), 'utf8');

function sub(from: string, to: string): string {
  if (!golden.includes(from)) throw new Error(`the golden has no "${from}"`);
  return golden.replace(from, to);
}

function parse(markdown: string): SpecMarkdownResult {
  return new SpecDocumentMarkdown(model, new SpecDocument()).parse(markdown);
}

function kept(markdown: string): SpecDocument {
  const doc = new SpecDocument();
  doc.applyMarkdownResult(parse(markdown), true);
  return doc;
}

const variants: Record<string, string> = {
  'unknown section': `${golden}\n## <!--[NOPE]--> Not A Section\n\nText with no home.\n`,
  'near-miss row': sub('| Owner | Bob |', '| Owner | Bob |\n| Ownr | Carol |'),
  'row given twice': sub('| Estimate | 8 |', '| Estimate | 8 |\n| Owner | Carol |'),
  'paragraph given twice': sub(
    '- backup: alice@example.com\n',
    '- backup: alice@example.com\nContact: carol@example.com\n- line\n',
  ),
  'table without delimiter': sub(
    '| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |',
    '| TomSpecField | Value |\n| Owner | Bob |',
  ),
  'records column': sub('| Id | Title | Note |', '| Id | Title | Nte |'),
  'records row': sub(
    '| <a id="CARD-2"></a>CARD-2 |  | second card |',
    '| <a id="CARD-2"></a>CARD-2 | second card |',
  ),
  'unclosed records fence': sub('| second card |\n:::\n', '| second card |\n'),
  'section-table row': sub(
    '| <a id="DLR-1"></a>DLR-LST / DLR-1 | Area | CE-NV |\n' +
      '|  | Mapping | dart-tom |\n\n### <!--[DLV-2]',
    '| <a id="DLR-1"></a>DLR-LS / DLR-1 | Area | CE-NV |\n' +
      '|  | Mapping | dart-tom |\n\n### <!--[DLV-2]',
  ),
  'orphan text': `Stray text.\n\n${golden}`,
  'child under a value leaf': sub(
    'high\n\n## <!--[CNT]-->',
    'high\n\n### <!--[X]--> Child\n\nchild text\n\n## <!--[CNT]-->',
  ),
  'nested unknown sections': `${golden}\n## <!--[NOPE]--> A\n\nA text\n\n### <!--[NOPE2]--> B\n\nB\n`,
};

function testEveryVariant(): void {
  _check('a clean parse keeps nothing', Object.keys(parse(golden).keptContent).length === 0);
  const schema = DocSpecsSchema.fromYamlText('title-format: "# <!--[DEMO]--> Demo"\n');
  for (const [name, markdown] of Object.entries(variants)) {
    const result = parse(markdown);
    _check(`${name}: rejected`, result.rejections.length > 0);
    const doc = kept(markdown);
    const values = Object.values(doc.toJson().content as Record<string, string>).join('\n');
    const divs = [
      ...values.matchAll(/^:{3,} \{\.rejected reason="(\w+)" line="(\d+)"/gm),
    ].map((m) => `${m[1]}@${m[2]}`);
    const want = result.rejections.map((r) => `${r.reason}@${r.line}`);
    _check(`${name}: every rejection kept`, JSON.stringify(divs) === JSON.stringify(want),
      `${JSON.stringify(divs)} != ${JSON.stringify(want)}`);

    const rendition = doc.toMarkdown(model, 'Demo');
    const again = parse(rendition);
    _check(`${name}: re-imports clean`, again.rejections.length === 0,
      again.rejections.map((r) => r.message).join('; '));
    const reloaded = new SpecDocument();
    reloaded.applyMarkdownResult(again);
    _check(`${name}: re-imports the same document`,
      JSON.stringify(reloaded.toJson()) === JSON.stringify(doc.toJson()));

    const reported = validateSpecDocument(model, doc, schema, 'Demo').filter(
      (v) => v.rule === DocSpecsViolationRule.REJECTED_BLOCK,
    );
    _check(`${name}: reported`, reported.length === result.rejections.length,
      `${reported.length} != ${result.rejections.length}`);
  }
}

function testRefused(): void {
  const doc = new SpecDocument();
  doc.loadJson({ content: { 'DEMO/TTL': 'base' } });
  let threw = false;
  try {
    doc.applyMarkdownResult(parse(variants['unknown section']));
  } catch (_) {
    threw = true;
  }
  _check('a refused import throws', threw);
  _check('a refused import never reads the kept blocks',
    JSON.stringify(doc.toJson().content) === JSON.stringify({ 'DEMO/TTL': 'base' }));
}

function testAttributes(): void {
  const row = kept(variants['near-miss row']).content('DEMO/DET') ?? '';
  _check('near-miss row names the field',
    row.includes('reason="unknownField" line="31" field="owner" '), row);
  const twice = kept(variants['row given twice']).content('DEMO/DET') ?? '';
  _check('a field given twice names the kept form',
    twice.includes('field="owner" kept="DEMO/DET" '), twice);
  const cell = kept(variants['section-table row']).content('DEMO/DLV-LST-1/content') ?? '';
  _check('a near-miss cell names the section', cell.includes('section="DLR-LST / DLR-1" '), cell);
  _check('the skipped continuation row is in the block', cell.includes('|  | Mapping | dart-tom |'));
}

function testParents(): void {
  const doc = kept(variants['unclosed records fence']);
  _check('the list container keeps no text', doc.content('DEMO/CARD-LST') === null);
  const root = doc.content('DEMO') ?? '';
  _check('the unclosed fence is escaped', root.includes('\n\\::: {.records}\n'), root);
  _check('the div closes', root.trimEnd().endsWith('\n:::'), root);
  const records = kept(variants['records column']).content('DEMO') ?? '';
  _check('a records div is kept in the parent',
    records.startsWith(':::: {.rejected reason="unknownField"'), records);
  _check('its own div stays inside', records.includes('\n::: {.records}\n'), records);
}

function testPlace(): void {
  const doc = kept(variants['paragraph given twice']);
  _check('the first value is kept',
    (doc.formField('DEMO/DET', 'contact') ?? '').startsWith('bob@example.com'));
  const want =
    'Captured during the November review.\n' +
    'Owner: this line is prose, not the field.\n\n' +
    '::: {.rejected reason="malformedBlock" line="35" field="contact" ' +
    'kept="DEMO/DET" label="field \'contact\' given twice"}\n' +
    'Contact: carol@example.com\n- line\n:::';
  const got = doc.content('DEMO/DET') ?? '';
  _check('a paragraph given twice is kept at its place', got === want,
    `\n--- got\n${got}\n--- want\n${want}`);
  const orphan = kept(variants['orphan text']).content('DEMO') ?? '';
  _check('orphan text starts the root',
    orphan.startsWith('::: {.rejected reason="orphanContent" line="1"'), orphan);
}

function main(): number {
  testEveryVariant();
  testRefused();
  testAttributes();
  testParents();
  testPlace();
  if (_failed.length > 0) {
    console.log(`FAIL: ${_failed.length}/${_passed + _failed.length} checks failed`);
    for (const f of _failed) console.log(`  - ${f}`);
    return 1;
  }
  console.log(`OK: ${_passed} checks passed`);
  return 0;
}

process.exit(main());
