#!/usr/bin/env node
/**
 * Tests for the DocSpecs-conform Markdown codec (`spec_document_markdown.ts`,
 * SOM §11) — a port of
 * `tom_som_javascript_runtime/tests/spec_document_markdown_test.js` (itself a
 * port of the Python/Dart reference suite).
 *
 * The generated `*.md` is a genuine DocSpecs document: line 1 is the
 * `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
 * section is a heading of the form `## <!--[SECTION-ID]--> Title`, content
 * sections are normal markdown text (no fences), `@Form` sections use the
 * plain-text `FieldName: value` format, and a list emits its `-LST` container
 * heading with the numbered items one level deeper.
 *
 * Build with `tsc`, then run `node dist/tests/spec_document_markdown_test.js`.
 * Exit code 0 == green.
 */

import {
  SpecDocument,
  SpecDocumentMarkdown,
  SpecMarkdownRejectReason,
  SpecMarkdownResult,
  SpecModel,
} from '../src/index';

let _passed = 0;
const _failed: string[] = [];

function _check(name: string, condition: boolean, detail = ''): void {
  if (condition) {
    _passed++;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

/**
 * A class graph covering content, enum, `@Form`, a complex sub-section and a
 * list of complex items, so the round-trip exercises every store.
 */
function _sampleJson(): any {
  return {
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
          {
            name: 'status',
            kind: 'enum',
            sectionId: 'D00-ST',
            enumValues: ['draft', 'final'],
          },
          {
            name: 'header',
            kind: 'form',
            sectionId: 'D00-HDR',
            formFields: [
              { name: 'author', label: 'Author', type: 'String' },
              { name: 'reviewer', label: 'Reviewer', type: 'String' },
            ],
          },
          { name: 'meta', kind: 'complex', type: 'DemoMeta', sectionId: 'D00-MET' },
          {
            name: 'items',
            kind: 'list',
            elementType: 'DemoItem',
            elementIsComplex: true,
            sectionId: 'D00-ITM',
          },
        ],
      },
      DemoMeta: {
        name: 'DemoMeta',
        sectionId: 'D00-MET',
        fields: [
          { name: 'note', kind: 'content', sectionId: 'D00-MET-NOTE' },
        ],
      },
      DemoItem: {
        name: 'DemoItem',
        fields: [
          { name: 'label', kind: 'content', sectionId: 'D01-LBL' },
          { name: 'body', kind: 'content', sectionId: 'D01-BODY' },
        ],
      },
    },
  };
}

// A d4rt-flutter body that is multi-line and embeds a run of three backticks
// mid-line — must pass through the plain-text body verbatim.
const _D4RT_BODY =
  'Column(\n' +
  '  children: [\n' +
  '    Text("hi"),\n' +
  '  ],\n' +
  ') // not a fence: ``` still inside the body';

// Content that exercises embedded markdown formatting: emphasis, a bullet
// list, a fenced code block containing heading-like lines, and a leading `#`
// line at column 0 (which the emitter escapes as `\#`).
const _RICH_MARKDOWN =
  'Intro with **bold** and *italic*.\n' +
  '\n' +
  '- first bullet\n' +
  '- second bullet\n' +
  '\n' +
  '```dart\n' +
  '# not a heading — shielded by the fence\n' +
  '## also shielded\n' +
  'void main() {}\n' +
  '```\n' +
  '\n' +
  '# looks like a heading at column 0\n' +
  'trailing paragraph';

function _model(): SpecModel {
  return SpecModel.fromJson(_sampleJson());
}

function _populated(): SpecDocument {
  const doc = new SpecDocument();
  doc.setContent('D00/D00-OVR', 'An overview paragraph.\nWith two lines.');
  doc.setContent('D00/D00-ST', 'final');
  doc.setFormField('D00/D00-HDR', 'author', 'Ada Lovelace');
  doc.setContent('D00/D00-MET/D00-MET-NOTE', 'A note.');
  const item = doc.addListItem('D00/D00-ITM');
  doc.setContent(`${item}/D01-LBL`, 'First item');
  doc.setContent(`${item}/D01-BODY`, _D4RT_BODY);
  const item2 = doc.addListItem('D00/D00-ITM');
  doc.setContent(`${item2}/D01-LBL`, 'Second item');
  return doc;
}

function _export(doc: SpecDocument): string {
  const model = _model();
  return new SpecDocumentMarkdown(model, doc).exportRoot(model.roots[0]);
}

/** Parses `md` into a fresh document via the staged-values report. */
function _reload(md: string): [SpecDocument, SpecMarkdownResult] {
  const target = new SpecDocument();
  const report = new SpecDocumentMarkdown(_model(), target).parse(md);
  target.loadJson({
    content: report.content,
    forms: report.forms,
    lists: report.lists,
    headlines: report.headlines,
    codeSpecs: report.codeSpecs,
  });
  return [target, report];
}

function _parse(md: string): SpecMarkdownResult {
  return new SpecDocumentMarkdown(_model(), new SpecDocument()).parse(md);
}

function _raises(fn: () => unknown, contains = ''): boolean {
  try {
    fn();
    return false;
  } catch (e: any) {
    return String(e.message || e).includes(contains);
  }
}

function _rejStr(report: SpecMarkdownResult): string {
  return report.rejections.map((r) => String(r)).join('; ');
}

function _shallowEqual(a: any, b: any): boolean {
  if (a == null || b == null) {
    return a === b;
  }
  const ka = Object.keys(a);
  const kb = Object.keys(b);
  return ka.length === kb.length && ka.every((k) => a[k] === b[k]);
}

// --- export — DocSpecs format (SOM §11) -------------------------------------

function testExportFormat(): void {
  const md = _export(_populated());
  const first = md.split('\n')[0];
  _check('export.docspec.prefix', first.startsWith('<!-- docspec: demo-document/'), first);
  _check('export.docspec.suffix', first.endsWith('-->'), first);

  _check('export.heading.root', md.includes('# <!--[D00]--> Demo Document'));
  _check('export.heading.overview', md.includes('## <!--[D00-OVR]--> Overview'));
  _check('export.heading.status', md.includes('## <!--[D00-ST]--> Status'));
  _check('export.heading.header', md.includes('## <!--[D00-HDR]--> Header'));
  _check('export.heading.meta', md.includes('## <!--[D00-MET]--> Meta'));
  _check('export.heading.note', md.includes('### <!--[D00-MET-NOTE]--> Note'));

  _check('export.content.plain', md.includes('An overview paragraph.\nWith two lines.'));
  _check(
    'export.content.noFence',
    !md.split('\n').some((l) => l.startsWith('```')),
  );
  _check('export.content.noFieldAnchor', !md.includes('<!-- field:'));
  _check('export.content.noPathHeading', !md.includes('D00/D00-OVR'));

  _check('export.form.sparse.author', md.includes('Author: Ada Lovelace'));
  _check('export.form.sparse.noReviewer', !md.includes('Reviewer'));

  // The list container heads (SOM §11.2): `D00-ITM` at the owner's child level,
  // its numbered items one level below it, item fields one deeper.
  _check('export.item.container', md.includes('## <!--[D00-ITM]--> Items'));
  _check('export.item.1', md.includes('### <!--[items-1]--> Demo Item 1'));
  _check('export.item.2', md.includes('### <!--[items-2]--> Demo Item 2'));
  _check('export.item.label', md.includes('#### <!--[D01-LBL]--> Label'));

  _check('export.noSchemaDescription', !md.includes('A demo document.'));
}

function testExportStoredItemId(): void {
  const doc = new SpecDocument();
  const item = doc.addListItem('D00/D00-ITM', 'D01-CUSTOM');
  doc.setContent(`${item}/D01-LBL`, 'Custom-id item');
  const md = _export(doc);
  // YRD3: a stored id IS the item's md heading id (positional only as
  // fallback), one level below the `-LST` container heading.
  _check('export.storedId.container', md.includes('## <!--[D00-ITM]--> Items'), md);
  _check('export.storedId.heading', md.includes('### <!--[D01-CUSTOM]--> Demo Item 1'), md);
  _check('export.storedId.noPositional', !md.includes('items-1'), md);
}

function testExportUntermFenceThrows(): void {
  const doc = new SpecDocument();
  doc.setContent('D00/D00-OVR', 'before\n```dart\nnever closed');
  _check('export.untermFence.raises', _raises(() => _export(doc), 'unterminated'));
}

// --- SpecDocument.toMarkdown (item 12) --------------------------------------

function testToMarkdown(): void {
  const model = _model();
  const doc = _populated();
  const oneLiner = doc.toMarkdown(model, 'DemoDoc');
  const explicit = new SpecDocumentMarkdown(model, doc).exportRoot(model.rootByType('DemoDoc'));
  _check('toMarkdown.explicitRoot', oneLiner === explicit);
  _check('toMarkdown.defaultRoot', doc.toMarkdown(model) === doc.toMarkdown(model, 'DemoDoc'));
  _check(
    'toMarkdown.emptyThrows',
    _raises(() => new SpecDocument().toMarkdown(model), 'no populated root'),
  );

  const twoModel = SpecModel.fromJson({
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
  const doc2 = new SpecDocument();
  doc2.setContent('A00/A00-OVR', 'a');
  doc2.setContent('B00/B00-OVR', 'b');
  _check('toMarkdown.twoRootsThrows.alpha', _raises(() => doc2.toMarkdown(twoModel), 'Alpha'));
  _check('toMarkdown.twoRootsThrows.beta', _raises(() => doc2.toMarkdown(twoModel), 'Beta'));
}

// --- round-trip ---------------------------------------------------------------

function testRoundTripValues(): void {
  const md = _export(_populated());
  const [target, report] = _reload(md);
  _check('roundTrip.clean', report.isClean, _rejStr(report));
  _check(
    'roundTrip.overview',
    target.content('D00/D00-OVR') === 'An overview paragraph.\nWith two lines.',
  );
  _check('roundTrip.status', target.content('D00/D00-ST') === 'final');
  _check('roundTrip.author', target.formField('D00/D00-HDR', 'author') === 'Ada Lovelace');
  _check('roundTrip.note', target.content('D00/D00-MET/D00-MET-NOTE') === 'A note.');
  const items = target.listItems('D00/D00-ITM');
  _check('roundTrip.itemCount', items.length === 2, String(items));
  if (items.length === 2) {
    _check('roundTrip.item1.label', target.content(`${items[0]}/D01-LBL`) === 'First item');
    // The embedded d4rt body survives verbatim, backticks and all.
    _check(
      'roundTrip.item1.body',
      target.content(`${items[0]}/D01-BODY`) === _D4RT_BODY,
      JSON.stringify(target.content(`${items[0]}/D01-BODY`)),
    );
    _check('roundTrip.item2.label', target.content(`${items[1]}/D01-LBL`) === 'Second item');
  }
}

function testRoundTripByteStable(): void {
  const md1 = _export(_populated());
  const [reloaded] = _reload(md1);
  const md2 = _export(reloaded);
  _check('roundTrip.byteStable', md2 === md1);
}

function testRoundTripRichMarkdown(): void {
  const doc = new SpecDocument();
  doc.setContent('D00/D00-OVR', _RICH_MARKDOWN);
  const md1 = _export(doc);
  // Fence-shielded heading-like lines are NOT escaped; the column-0 `#` line
  // outside the fence IS.
  _check('richMd.fenceShielded', md1.includes('\n# not a heading — shielded by the fence\n'));
  _check('richMd.escapedHeading', md1.includes('\n\\# looks like a heading at column 0\n'));

  const [reloaded, report] = _reload(md1);
  _check('richMd.clean', report.isClean, _rejStr(report));
  _check(
    'richMd.value',
    reloaded.content('D00/D00-OVR') === _RICH_MARKDOWN,
    JSON.stringify(reloaded.content('D00/D00-OVR')),
  );
  _check('richMd.byteStable', _export(reloaded) === md1);
}

function testRoundTripStoredItemId(): void {
  const doc = new SpecDocument();
  const item = doc.addListItem('D00/D00-ITM', 'D01-CUSTOM');
  doc.setContent(`${item}/D01-LBL`, 'Custom-id item');
  const md1 = _export(doc);
  // YRD3: a stored id round-trips through md as the item's heading id.
  _check('storedId.inMd', md1.includes('<!--[D01-CUSTOM]-->'), md1);
  const [reloaded, report] = _reload(md1);
  _check('storedId.clean', report.isClean, _rejStr(report));
  const items = reloaded.listItems('D00/D00-ITM');
  _check('storedId.itemCount', items.length === 1, String(items));
  if (items.length === 1) {
    _check(
      'storedId.sectionId',
      reloaded.itemSectionId(items[0]) === 'D01-CUSTOM',
      String(reloaded.itemSectionId(items[0])),
    );
    _check('storedId.label', reloaded.content(`${items[0]}/D01-LBL`) === 'Custom-id item');
  }
  _check('storedId.byteStable', _export(reloaded) === md1);
}

function testRoundTripLabelShapedContinuation(): void {
  const doc = new SpecDocument();
  doc.setFormField(
    'D00/D00-HDR',
    'author',
    'Ada Lovelace\nNote: also a mathematician\nplain line',
  );
  const md1 = _export(doc);
  // The label-shaped continuation is space-escaped on emit.
  _check('formCont.escaped', md1.includes('\n Note: also a mathematician\n'), md1);

  const [reloaded, report] = _reload(md1);
  _check('formCont.clean', report.isClean, _rejStr(report));
  _check(
    'formCont.value',
    reloaded.formField('D00/D00-HDR', 'author') ===
      'Ada Lovelace\nNote: also a mathematician\nplain line',
    JSON.stringify(reloaded.formField('D00/D00-HDR', 'author')),
  );
  _check('formCont.byteStable', _export(reloaded) === md1);
}

// --- parse-rejection protocol (SOM §11.7) -------------------------------------

function testRejectUnknownSection(): void {
  // The bogus heading is nested under `meta` (which has no list children);
  // directly under the root any unresolved id would be absorbed by the
  // single-list-child fallback as a stored-id item.
  const md =
    '<!-- docspec: demo-document/1.0 -->\n' +
    '# <!--[D00]--> Demo Document\n\n' +
    '## <!--[D00-OVR]--> Overview\n\n' +
    'kept\n\n' +
    '## <!--[D00-MET]--> Meta\n\n' +
    '### <!--[D00-NOPE]--> Bogus\n\n' +
    'dropped\n';
  const report = _parse(md);
  _check('reject.unknown.dirty', !report.isClean);
  _check(
    'reject.unknown.reason',
    report.rejections.some(
      (r) => r.anchor === 'D00-NOPE' && r.reason === SpecMarkdownRejectReason.UNKNOWN_SECTION,
    ),
    _rejStr(report),
  );
  _check('reject.unknown.siblingsKept', report.content['D00/D00-OVR'] === 'kept');
}

function testRejectMalformedHeading(): void {
  const md =
    '<!-- docspec: demo-document/1.0 -->\n' +
    '# <!--[D00]--> Demo Document\n\n' +
    '## Overview without an id comment\n\n' +
    'lost\n';
  const report = _parse(md);
  _check(
    'reject.malformed.reason',
    report.rejections.some((r) => r.reason === SpecMarkdownRejectReason.MALFORMED_HEADING),
    _rejStr(report),
  );
  _check(
    'reject.malformed.noContent',
    Object.keys(report.content).length === 0,
    JSON.stringify(report.content),
  );
}

function testRejectOrphanPreamble(): void {
  const md =
    'stray preamble text\n' +
    '# <!--[D00]--> Demo Document\n\n' +
    '## <!--[D00-OVR]--> Overview\n\n' +
    'kept\n';
  const report = _parse(md);
  _check(
    'reject.orphanPreamble.reason',
    report.rejections.some((r) => r.reason === SpecMarkdownRejectReason.ORPHAN_CONTENT),
    _rejStr(report),
  );
  _check('reject.orphanPreamble.kept', report.content['D00/D00-OVR'] === 'kept');
}

function testRejectOrphanFormProse(): void {
  const md =
    '# <!--[D00]--> Demo Document\n\n' +
    '## <!--[D00-HDR]--> Header\n\n' +
    'prose before any field label\n' +
    'Author: Ada Lovelace\n';
  const report = _parse(md);
  _check(
    'reject.orphanForm.reason',
    report.rejections.some((r) => r.reason === SpecMarkdownRejectReason.ORPHAN_CONTENT),
    _rejStr(report),
  );
  // The labelled field still parses.
  _check(
    'reject.orphanForm.fieldParsed',
    _shallowEqual(report.forms['D00/D00-HDR'], { author: 'Ada Lovelace' }),
    JSON.stringify(report.forms),
  );
}

function testRejectKindMismatch(): void {
  const md =
    '# <!--[D00]--> Demo Document\n\n' +
    '## <!--[D00-OVR]--> Overview\n\n' +
    'kept\n\n' +
    '### <!--[D00-MET-NOTE]--> Note\n\n' +
    'misplaced\n';
  const report = _parse(md);
  _check(
    'reject.kindMismatch.reason',
    report.rejections.some((r) => r.reason === SpecMarkdownRejectReason.KIND_MISMATCH),
    _rejStr(report),
  );
  _check('reject.kindMismatch.kept', report.content['D00/D00-OVR'] === 'kept');
}

function testRejectMissingValue(): void {
  const md =
    '# <!--[D00]--> Demo Document\n\n' +
    '## <!--[D00-OVR]--> Overview\n\n' +
    '## <!--[D00-ST]--> Status\n\n' +
    'final\n';
  const report = _parse(md);
  _check(
    'reject.missingValue.reason',
    report.rejections.some(
      (r) =>
        r.reason === SpecMarkdownRejectReason.MISSING_VALUE && r.anchor === 'D00/D00-OVR',
    ),
    _rejStr(report),
  );
  _check('reject.missingValue.statusKept', report.content['D00/D00-ST'] === 'final');
}

function testCaseInsensitiveLabels(): void {
  const md =
    '# <!--[D00]--> Demo Document\n\n' +
    '## <!--[D00-HDR]--> Header\n\n' +
    'author: lower-case label\n';
  const report = _parse(md);
  _check('labels.caseInsensitive.clean', report.isClean, _rejStr(report));
  _check(
    'labels.caseInsensitive.value',
    _shallowEqual(report.forms['D00/D00-HDR'], { author: 'lower-case label' }),
    JSON.stringify(report.forms),
  );
}

function testFenceShieldedHeadingsStayBody(): void {
  const md =
    '# <!--[D00]--> Demo Document\n\n' +
    '## <!--[D00-OVR]--> Overview\n\n' +
    '```\n' +
    '## <!--[D00-ST]--> not a real heading\n' +
    '```\n';
  const report = _parse(md);
  _check('fenceShield.clean', report.isClean, _rejStr(report));
  _check(
    'fenceShield.body',
    report.content['D00/D00-OVR'] === '```\n## <!--[D00-ST]--> not a real heading\n```',
    JSON.stringify(report.content['D00/D00-OVR']),
  );
  _check('fenceShield.noStatus', !('D00/D00-ST' in report.content));
}

// --- codespecs_mapping.md §9.2 codeSpec forward-link (csmc8)
// --------------------------------------

const _CODE_SPEC = 'CsOrder,CsOrder.total,CsOrderRepository';

function testCodeSpecRidesInHeadlineComment(): void {
  const doc = _populated();
  doc.setCodeSpec('D00/D00-OVR', _CODE_SPEC);
  const md = _export(doc);
  // The codeSpec is emitted as a `codeSpec="…"` key inside the same heading
  // comment as the section id, next to (before) the derived title.
  _check(
    'codeSpec.md.inHeading',
    md.includes(`## <!--[D00-OVR] codeSpec="${_CODE_SPEC}"--> Overview`),
    md,
  );
  // A sibling heading with no codeSpec is untouched — no key emitted.
  _check('codeSpec.md.siblingUntouched', md.includes('## <!--[D00-ST]--> Status'), md);
}

function testCodeSpecParsedBackOut(): void {
  const doc = _populated();
  doc.setCodeSpec('D00/D00-OVR', _CODE_SPEC);
  const md = _export(doc);
  const [reloaded, report] = _reload(md);
  _check('codeSpec.md.clean', report.isClean, _rejStr(report));
  _check('codeSpec.md.staged', report.codeSpecs['D00/D00-OVR'] === _CODE_SPEC,
    JSON.stringify(report.codeSpecs));
  _check(
    'codeSpec.md.restored',
    reloaded.codeSpec('D00/D00-OVR') === _CODE_SPEC,
    String(reloaded.codeSpec('D00/D00-OVR')),
  );
  // Sections without a codeSpec stay null.
  _check('codeSpec.md.siblingNull', reloaded.codeSpec('D00/D00-ST') === null);
}

function testCodeSpecAndHeadlineRoundTripByteStable(): void {
  const doc = _populated();
  doc.setCodeSpec('D00/D00-OVR', _CODE_SPEC);
  doc.setHeadline('D00/D00-OVR', 'Custom Overview');
  const md1 = _export(doc);
  const [reloaded] = _reload(md1);
  const md2 = _export(reloaded);
  _check('codeSpec.md.byteStable', md2 === md1, md2);
  _check('codeSpec.md.headlineKept', reloaded.headline('D00/D00-OVR') === 'Custom Overview');
  _check('codeSpec.md.codeSpecKept', reloaded.codeSpec('D00/D00-OVR') === _CODE_SPEC);
}

function main(): number {
  testExportFormat();
  testExportStoredItemId();
  testExportUntermFenceThrows();
  testToMarkdown();
  testRoundTripValues();
  testRoundTripByteStable();
  testRoundTripRichMarkdown();
  testRoundTripStoredItemId();
  testRoundTripLabelShapedContinuation();
  testRejectUnknownSection();
  testRejectMalformedHeading();
  testRejectOrphanPreamble();
  testRejectOrphanFormProse();
  testRejectKindMismatch();
  testRejectMissingValue();
  testCaseInsensitiveLabels();
  testFenceShieldedHeadingsStayBody();
  testCodeSpecRidesInHeadlineComment();
  testCodeSpecParsedBackOut();
  testCodeSpecAndHeadlineRoundTripByteStable();

  const total = _passed + _failed.length;
  if (_failed.length > 0) {
    process.stdout.write(`FAIL: ${_failed.length}/${total} checks failed\n`);
    for (const f of _failed) {
      process.stdout.write(`  - ${f}\n`);
    }
    return 1;
  }
  process.stdout.write(`OK: ${total} checks passed\n`);
  return 0;
}

process.exit(main());
