#!/usr/bin/env node
/**
 * Stripped renditions (SOM §11.10): heading divs, the readable header, the
 * document strip's checks. A port of
 * `tom_som_dart_runtime/test/spec_document_strip_test.dart`; the per-value
 * rules are the conformance cases of `strip_cases.json`.
 *
 * Build with `tsc`, then run `node dist/tests/spec_document_strip_test.js`.
 * Exit code 0 == all green.
 */

import {
  SpecDocument,
  SpecDocumentMarkdown,
  SpecDocumentStrip,
  SpecModel,
  SpecReadableHeader,
  SpecReadableSource,
  SpecReviewAnnotations,
  SpecStripOptions,
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

function _eq(name: string, got: unknown, want: unknown): void {
  const g = JSON.stringify(got);
  const w = JSON.stringify(want);
  _check(name, g === w, `got ${g}, want ${w}`);
}

/** A model nine sections deep: `L<n>` holds content `T<n>` and section `L<n+1>`. */
function deepModel(): SpecModel {
  const classes: Record<string, unknown> = {};
  for (let n = 1; n <= 9; n++) {
    const fields: unknown[] = [
      { name: 'text', kind: 'content', sectionId: `T${n}`, contentType: 'text' },
    ];
    if (n < 9) {
      fields.push({ name: 'next', kind: 'complex', sectionId: `L${n + 1}`, type: `L${n + 1}` });
    }
    classes[`L${n}`] = {
      name: `L${n}`,
      sectionId: `L${n}`,
      ...(n === 1
        ? {
            annotations: [
              { name: 'Document', arguments: { title: 'Deep' } },
              { name: 'SectionId', arguments: { id: 'L1' } },
            ],
          }
        : {}),
      fields,
    };
  }
  return SpecModel.fromJson({
    modelVersion: 1,
    modelVersionLabel: '0.1.0+1',
    roots: [{ type: 'L1', title: 'Deep', sectionId: 'L1' }],
    classes,
  });
}

function pathTo(n: number, text = true): string {
  const parts: string[] = [];
  for (let k = 1; k <= n; k++) parts.push(`L${k}`);
  if (text) parts.push(`T${n}`);
  return parts.join('/');
}

const model = deepModel();
const root = model.rootByType('L1');

function deepDocument(): SpecDocument {
  const doc = new SpecDocument();
  for (let n = 1; n <= 9; n++) doc.setContent(pathTo(n), `Text ${n} [an aside]{.aside}.`);
  doc.setHeadline(pathTo(7, false), 'Seven & <more>\nsecond line');
  doc.setContent(
    pathTo(8),
    'Before.\n\n<div class="heading9" style="x">Not a heading</div>\n\n' +
      '\\<div class="heading7" style="x">Escaped once</div>',
  );
  return doc;
}

function testHeadingDivs(): void {
  const doc = deepDocument();
  const md = new SpecDocumentMarkdown(model, doc, { headingDivs: true }).exportRoot(root);
  const lines = md.split('\n');
  _check(
    'divs: no # heading deeper than 6',
    lines.filter((l) => l.startsWith('#')).every((l) => l.split(' ')[0].length <= 6),
  );
  _check(
    'divs: level 7 as a div, title escaped',
    lines.includes(
      '<div class="heading7" style="margin:1em 0 0.5em;padding-left:0.75em;font-weight:bold">' +
        '<!--[L7]--> <a id="L7"></a> Seven &amp; &lt;more&gt;<br>second line</div>',
    ),
  );
  _check(
    'divs: level 10 indent',
    lines.some((l) => l.startsWith('<div class="heading10"') && l.includes('padding-left:3em;')),
  );
  _check(
    'divs: a content div is escaped',
    lines.includes('\\<div class="heading9" style="x">Not a heading</div>'),
  );
  _check(
    'divs: an escaped content div gets one more backslash',
    lines.includes('\\\\<div class="heading7" style="x">Escaped once</div>'),
  );
  const back = SpecDocument.fromMarkdown(md, model);
  _eq('divs: no rejection', back.result.rejections.length, 0);
  _eq('divs: round trip', back.document.toJson(), doc.toJson());

  const plain = new SpecDocumentMarkdown(model, doc).exportRoot(root);
  _check('plain: no div heading', !plain.includes('\n<div class="heading7"'));
  _check('plain: ####### heading', plain.includes('####### <!--[L7]-->'));
  _eq('plain: round trip', SpecDocument.fromMarkdown(plain, model).document.toJson(), doc.toJson());

  _eq(
    'indent per level',
    [7, 8, 9, 10, 11, 12].map((d) => SpecDocumentMarkdown.headingDivIndent(d)),
    ['0.75', '1.5', '2.25', '3', '3.75', '4.5'],
  );
  _eq('heading6 is content', SpecDocumentMarkdown.headingDiv('<div class="heading6">x</div>'), null);
  _eq(
    'heading7 decoded',
    SpecDocumentMarkdown.headingDiv('<div class="heading7">a &amp;lt;</div>'),
    [7, 'a &lt;'],
  );
}

function testReadable(): void {
  const source = new SpecReadableSource('deep.tomspecs.yaml', 'r3', '8e1d2a7', true);
  const r = SpecDocumentStrip.strip(
    deepDocument(),
    SpecStripOptions.fromNames({ drop: ['aside'], headingDivs: true }),
    { model, source },
  );
  _eq('readable: no finding', r.findings.map((f) => `${f}`), []);
  _eq(
    'readable: header',
    r.readableHeader,
    '<!-- readable: drop=aside; headings=divs; of=deep.tomspecs.yaml@r3; commit=8e1d2a7+dirty -->',
  );
  const lines = r.readable!.split('\n');
  _check('readable: docspec first', lines[0].startsWith('<!-- docspec: '));
  _eq('readable: header second', lines[1], r.readableHeader);
  _check('readable: divs', r.readable!.includes('<div class="heading8"'));
  _check('readable: asides gone', !r.readable!.includes('{.aside}'));
  const parsed = new SpecDocumentMarkdown(model, new SpecDocument()).parse(r.readable!);
  _eq('readable: parsed header', parsed.readableHeader, r.readableHeader);
  const header = SpecReadableHeader.parse(parsed.readableHeader!)!;
  _eq('readable: header round trip', header.format(), r.readableHeader);
  _check('readable: header switches', header.options.drop.has('aside') && header.options.headingDivs);
  _check('readable: header dirty', header.source!.dirty);
  _eq(
    'readable: parses to the stripped document',
    SpecDocument.fromMarkdown(r.readable!, model).document.toJson(),
    r.document.toJson(),
  );

  const a = SpecDocumentStrip.strip(
    deepDocument(),
    SpecStripOptions.fromNames({ appendix: ['aside'], appendixReferences: true, headingDivs: true }),
    { model },
  );
  _eq('appendix: no finding', a.findings.map((f) => `${f}`), []);
  _eq('appendix: numbers', a.appendix.map((e) => e.number), [1, 2, 3, 4, 5, 6, 7, 8]);
  _eq(
    'appendix: values in order',
    a.appendix.map((e) => e.value!.path),
    [1, 2, 3, 4, 5, 6, 7, 9].map((n) => pathTo(n)),
  );
  const notes = a.readable!.split(`${SpecDocumentMarkdown.appendixMarker}\n`)[1];
  _check('appendix: Notes heading', notes.startsWith('\n## Notes\n'));
  _eq('appendix: one group per section', notes.split('### Text\n').length - 1, 8);
  _check(
    'appendix: entry with back link',
    notes.includes('<a id="note-1"></a>**[1]** an aside [↩](#note-1-ref)'),
  );
  _eq(
    'appendix: reference in place',
    a.document.content(pathTo(1)),
    'Text 1<a id="note-1-ref"></a>[\\[1\\]](#note-1).',
  );

  const bad = deepDocument();
  bad.setContent(pathTo(2), '::: {.aside}\nopen');
  const refused = SpecDocumentStrip.strip(bad, SpecStripOptions.fromNames({ drop: ['aside'] }), {
    model,
  });
  _check('refused: not ok', !refused.ok);
  _eq('refused: notation finding', refused.findings.map((f) => f.kind), ['notation']);
  _eq('refused: value unchanged', refused.document.content(pathTo(2)), '::: {.aside}\nopen');

  const bare = SpecDocumentStrip.strip(deepDocument(), SpecStripOptions.fromNames({ drop: ['all'] }));
  _eq('no model: no rendition', bare.readable, null);
  _eq('no model: stripped', bare.document.content(pathTo(1)), 'Text 1.');
  _eq('no model: counts', Object.fromEntries(bare.dropped), { aside: 8 });
}

function testStripped(): void {
  const doc = new SpecDocument();
  doc.setContent('L1/T1', 'Keep {++this++}.\n\n> ⬆️ **C-1** (Al): ok');
  doc.setHeadline('L1/L2', 'Two {--old--}');
  const s = new SpecReviewAnnotations(doc).stripped();
  _eq('stripped: content', s.content('L1/T1'), 'Keep this.');
  _eq('stripped: headline', s.headline('L1/L2'), 'Two');
}

function main(): number {
  testHeadingDivs();
  testReadable();
  testStripped();
  if (_failed.length > 0) {
    console.log(`FAIL: ${_failed.length}/${_passed + _failed.length} checks failed`);
    for (const f of _failed) console.log(`  - ${f}`);
    return 1;
  }
  console.log(`OK: ${_passed} checks passed`);
  return 0;
}

process.exit(main());
