#!/usr/bin/env node
/**
 * SOM §11.2 `units`: the generation units a section goes to. Kept exactly as
 * `codeSpec` is — a sparse store by section path, the Markdown heading key
 * `units="a,b"` after `codeSpec`, the YAML key `units` after `codeSpec`, the
 * facade's `$units`, the snapshot's `units` map — and checked by the instance
 * tier's phase 8. A port of `tom_som_dart_runtime/test/spec_units_test.dart`
 * (the cases this runtime has the surface for: it has no path normalizer and
 * no state capture) plus the units cases of the Dart extract tests.
 *
 * Build with `tsc`, then run `node dist/tests/spec_units_test.js`.
 * Exit code 0 == all green.
 */

import * as fs from 'fs';
import * as path from 'path';

import {
  CodeSpecsAreaCatalog,
  CodeSpecsExtractor,
  SomNode,
  SpecDocument,
  SpecDocumentMarkdown,
  SpecModel,
  SpecYamlFormatException,
  buildSomMetaTree,
  mergeReviews,
  parseCodeSpecsExtractYaml,
  specDefaultUnits,
  specGenerationUnits,
  validateDocument,
  yamlEncode,
} from '../src/index';

let _passed = 0;
const _failed: string[] = [];

function _check(name: string, ok: boolean, detail = ''): void {
  if (ok) {
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

function _throws(name: string, fn: () => unknown, contains = ''): void {
  try {
    fn();
    _check(name, false, 'did not throw');
  } catch (e) {
    _check(
      name,
      e instanceof SpecYamlFormatException && e.message.includes(contains),
      String(e),
    );
  }
}

const _CORPUS = path.normalize(
  path.join(__dirname, '..', '..', '..', 'tom_som_conformance', 'corpus'),
);

function _corpusJson(name: string): any {
  return JSON.parse(fs.readFileSync(path.join(_CORPUS, name), 'utf8'));
}

/**
 * The shared corpus model: the demo root with the generation-unit register
 * `DEMO/DLV-LST` (`Deliverable`, `DeliverableRoute`).
 */
const model = SpecModel.fromJson(_corpusJson('model.meta.json'));
const tree = buildSomMetaTree(model);

/** A register declaring `u_a` and `u_b`, both building something. */
function _register(): SpecDocument {
  const d = new SpecDocument();
  const a = d.addListItem('DEMO/DLV-LST');
  d.setFormField(`${a}/content`, 'unitId', 'u_a');
  d.setFormField(`${a}/content`, 'component', 'ARCM-COMP-A');
  const b = d.addListItem('DEMO/DLV-LST');
  d.setFormField(`${b}/content`, 'unitId', 'u_b');
  d.setFormField(`${b}/content`, 'deploymentTarget', 'DEPTAR-DEPL-B');
  return d;
}

function _enc(d: SpecDocument): string {
  return yamlEncode(d, tree, '1.0');
}

// --- the store ---------------------------------------------------------------

function testStore(): void {
  const d = new SpecDocument();
  _eq('store.absent', d.units('DEMO/TTL'), null);
  d.setUnits('DEMO/TTL', 'u_a,u_b');
  _eq('store.set', d.units('DEMO/TTL'), 'u_a,u_b');
  _eq('store.paths', Array.from(d.unitsPaths), ['DEMO/TTL']);
  _eq('store.notEmpty', d.isEmpty, false);
  _eq('store.hasValuesUnder', d.hasValuesUnder('DEMO'), true);
  d.setUnits('DEMO/TTL', '');
  _eq('store.cleared', d.units('DEMO/TTL'), null);
  _eq('store.clearedPaths', Array.from(d.unitsPaths), []);
  _eq('store.emptyAgain', d.isEmpty, true);
}

function testSnapshot(): void {
  const d = new SpecDocument();
  d.setCodeSpec('DEMO/TTL', 'A');
  d.setUnits('DEMO/TTL', 'u_b');
  d.setUnits('DEMO/SUM', 'u_a');
  const json = d.toJson();
  _eq('snapshot.keys', Object.keys(json), ['codeSpecs', 'units']);
  _eq('snapshot.sorted', Object.keys(json.units || {}), ['DEMO/SUM', 'DEMO/TTL']);
  const back = new SpecDocument();
  back.loadJson(JSON.parse(JSON.stringify(json)));
  _eq('snapshot.roundTrip', back.toJson(), json);
  _eq('snapshot.noUnitsNoKey', 'units' in new SpecDocument().toJson(), false);
  const skip = new SpecDocument();
  skip.loadJson({ units: { 'DEMO/TTL': '', 'DEMO/SUM': 'u_a' } });
  _eq('snapshot.loadSkipsEmpty', Array.from(skip.unitsPaths), ['DEMO/SUM']);
}

function testPurge(): void {
  const d = new SpecDocument();
  d.setUnits('DEMO/notes', 'u_a');
  d.setUnits('DEMO/notes/NOTE-BDY', 'u_b');
  d.setUnits('DEMO/TTL', 'u_a');
  d.removeValuesUnder('DEMO/notes');
  _eq('purge.removeValuesUnder', Array.from(d.unitsPaths), ['DEMO/TTL']);

  const r = new SpecDocument();
  const item = r.addListItem('DEMO/items');
  r.setUnits(`${item}/label`, 'u_a');
  r.setUnits(item, 'u_b');
  r.removeListItem(item);
  _eq('purge.removeListItem', Array.from(r.unitsPaths), []);
}

function testMove(): void {
  const d = new SpecDocument();
  const first = d.addListItem('DEMO/items');
  const second = d.addListItem('DEMO/items');
  d.setContent(`${first}/label`, 'one');
  d.setContent(`${second}/label`, 'two');
  d.setUnits(second, 'u_a');
  d.moveListItem(model, second, 0);
  _eq('move.units.moved', d.units('DEMO/items-1'), 'u_a');
  _eq('move.units.left', d.units('DEMO/items-2'), null);
}

// --- the facade --------------------------------------------------------------

function testFacade(): void {
  const d = new SpecDocument();
  const node = new SomNode(d, 'DEMO/TTL');
  _eq('facade.absent', node.$units, null);
  node.$units = 'u_a';
  _eq('facade.write', d.units('DEMO/TTL'), 'u_a');
  _eq('facade.read', node.$units, 'u_a');
  node.$units = null;
  _eq('facade.nullClears', node.$units, null);
  node.$units = 'u_b';
  node.$units = '';
  _eq('facade.emptyClears', Array.from(d.unitsPaths), []);
}

// --- Markdown ----------------------------------------------------------------

function testMarkdown(): void {
  const d = new SpecDocument();
  d.setContent('DEMO/TTL', 'Hello');
  d.setCodeSpec('DEMO/TTL', 'DemoTitle');
  d.setUnits('DEMO/TTL', 'u_a,u_b');
  d.setContent('DEMO/SUM', 'Sum');
  d.setUnits('DEMO/SUM', 'u_a');
  const md = d.toMarkdown(model);
  _check(
    'md.emit.afterCodeSpec',
    md.includes(
      '## <!--[TTL] codeSpec="DemoTitle" units="u_a,u_b"--> Document Title\n',
    ),
    md,
  );
  _check('md.emit.alone', md.includes('## <!--[SUM] units="u_a"--> Summary\n'), md);

  const text =
    '# <!--[DEMO] units=u_root--> Demo Document\n\n' +
    '## <!--[TTL] codeSpec="DemoTitle" units="u_a,u_b"--> Title\n\n' +
    'Hello\n\n' +
    "## <!--[SUM] units='u_c'--> Summary\n\n" +
    'Sum\n\n' +
    '## <!--[CNT] codeSpec="units=no"--> Count\n\n' +
    '3\n';
  const result = new SpecDocumentMarkdown(model, new SpecDocument()).parse(text);
  _eq('md.parse.clean', result.rejections.length, 0);
  _eq('md.parse.units', result.units, {
    DEMO: 'u_root',
    'DEMO/TTL': 'u_a,u_b',
    'DEMO/SUM': 'u_c',
  });
  _eq('md.parse.codeSpec', result.codeSpecs['DEMO/TTL'], 'DemoTitle');
  // A `units=` inside a quoted codeSpec value is not the key.
  _eq('md.parse.quotedNotKey', result.codeSpecs['DEMO/CNT'], 'units=no');
  _eq('md.unitsOf.trim', SpecDocumentMarkdown.unitsOf(' units=" a,b "'), 'a,b');
  _eq('md.unitsOf.none', SpecDocumentMarkdown.unitsOf(' codeSpec="x"'), '');

  const r = _register();
  r.setContent('DEMO/TTL', 'Hello');
  r.setCodeSpec('DEMO/TTL', 'DemoTitle');
  r.setUnits('DEMO/TTL', 'u_a');
  r.setContent('DEMO/notes/NOTE-BDY', 'Body');
  r.setUnits('DEMO/notes', 'u_a,u_b');
  const rmd = r.toMarkdown(model);
  const back = SpecDocument.fromMarkdown(rmd, model).document;
  _eq('md.roundTrip.TTL', back.units('DEMO/TTL'), 'u_a');
  _eq('md.roundTrip.notes', back.units('DEMO/notes'), 'u_a,u_b');
  _check('md.roundTrip.bytes', back.toMarkdown(model) === rmd);
}

// --- YAML --------------------------------------------------------------------

function testYaml(): void {
  const d = new SpecDocument();
  d.setContent('DEMO/TTL', 'Hello');
  d.setHeadline('DEMO/TTL', 'Title');
  d.setCodeSpec('DEMO/TTL', 'DemoTitle');
  d.setUnits('DEMO/TTL', 'u_a');
  d.setContent('DEMO/CNT', '3');
  d.setUnits('DEMO/CNT', 'u_b');
  d.setContent('DEMO/notes/NOTE-BDY', 'Body');
  d.setUnits('DEMO/notes', 'u_a,u_b');
  const yaml = _enc(d);
  _check(
    'yaml.scalarPromotion',
    yaml.includes(
      '    TTL title:\n' +
        '      headline: |2-\n        Title\n' +
        '      codeSpec: |2-\n        DemoTitle\n' +
        '      units: |2-\n        u_a\n' +
        '      content: |2-\n        Hello\n',
    ),
    yaml,
  );
  // A non-text scalar keeps its plain content inside the mapping.
  _check(
    'yaml.plainContent',
    yaml.includes('    CNT count:\n      units: |2-\n        u_b\n      content: 3\n'),
    yaml,
  );
  _check(
    'yaml.section',
    yaml.includes('    NOTE notes:\n      units: |2-\n        u_a,u_b\n'),
    yaml,
  );
  const back = SpecDocument.fromYaml(yaml, tree);
  _eq('yaml.decode', back.toJson(), d.toJson());
  _check('yaml.reencode', _enc(back) === yaml);

  // Units on a form, a list container and a list item.
  const r = _register();
  r.setFormField('DEMO/DET', 'owner', 'Bob');
  r.setUnits('DEMO/DET', 'u_a');
  r.setUnits('DEMO/DLV-LST', 'u_b');
  r.setUnits('DEMO/DLV-LST-1', 'u_a');
  const tagItem = r.addListItem('DEMO/META/tags');
  r.setContent(tagItem, 'on');
  r.setUnits(tagItem, 'u_b');
  const ryaml = _enc(r);
  const rback = SpecDocument.fromYaml(ryaml, tree);
  _eq('yaml.formListItem.decode', rback.toJson(), r.toJson());
  _check('yaml.formListItem.reencode', _enc(rback) === ryaml);

  // A list item may not be keyed `units`.
  const k = new SpecDocument();
  k.addListItem('DEMO/DLV-LST', 'units');
  _throws('yaml.itemKeyedUnits', () => _enc(k));
}

function testYamlCollisionGuards(): void {
  const clash = SpecModel.fromJson({
    modelVersion: 1,
    roots: [{ type: 'R', title: 'R', sectionId: 'R' }],
    classes: {
      R: {
        name: 'R',
        sectionId: 'R',
        fields: [
          { name: 'units', kind: 'content' },
          {
            name: 'shape',
            kind: 'form',
            sectionId: 'SHP',
            formFields: [{ name: 'units', label: 'Units', type: 'String' }],
          },
        ],
      },
    },
  });
  const clashTree = buildSomMetaTree(clash);
  const a = new SpecDocument();
  a.setUnits('R', 'u_a');
  _throws(
    'yaml.guard.child',
    () => yamlEncode(a, clashTree, '1.0'),
    'also serializes as key `units`',
  );
  const b = new SpecDocument();
  b.setFormField('R/SHP', 'units', '3');
  b.setUnits('R/SHP', 'u_a');
  _throws(
    'yaml.guard.formField',
    () => yamlEncode(b, clashTree, '1.0'),
    'field literally named `units`',
  );
  // A stored value the tree cannot place is a leftover naming `units`.
  const c = new SpecDocument();
  c.setUnits('R/NOWHERE', 'u_a');
  _throws('yaml.leftover', () => yamlEncode(c, clashTree, '1.0'), 'units at `R/NOWHERE`');
  // The scalar promotion names `units` among the allowed keys.
  _throws(
    'yaml.decode.scalarKeys',
    () =>
      SpecDocument.fromYaml(
        'version: 2\ndocument:\n  DEMO Demo:\n    TTL title:\n      bogus: x\n',
        tree,
      ),
    '`headline`/`codeSpec`/`units`/`content`',
  );
}

// --- apply, assembly, merge --------------------------------------------------

function testApplyMarkdown(): void {
  const d = new SpecDocument();
  d.setUnits('DEMO/TTL', 'stale');
  d.setUnits('DEMO/SUM', 'stale');
  d.setUnits('OTHER/kept', 'kept');
  const md =
    '# <!--[DEMO]--> Demo Document\n\n' +
    '## <!--[TTL] units="u_a"--> Document Title\n\nHello\n';
  d.applyMarkdownResult(new SpecDocumentMarkdown(model, new SpecDocument()).parse(md));
  _eq('apply.units', d.toJson().units, { 'DEMO/TTL': 'u_a', 'OTHER/kept': 'kept' });
}

function testAssembly(): void {
  const a = new SpecDocument();
  a.setUnits('DEMO/TTL', 'u_a');
  const b = new SpecDocument();
  b.setUnits('DEMO/SUM', 'u_b');
  const ok = SpecDocument.assemble([
    ['a', a],
    ['b', b],
  ]);
  _eq('assembly.ok', ok.ok, true);
  _eq('assembly.units', ok.document === null ? null : ok.document.units('DEMO/SUM'), 'u_b');
  const c = new SpecDocument();
  c.setUnits('DEMO/TTL', 'u_b');
  const clash = SpecDocument.assemble([
    ['a', a],
    ['c', c],
  ]);
  _eq('assembly.refused', clash.ok, false);
  _eq(
    'assembly.overlap',
    clash.overlaps.map((o) => [o.store, o.path]),
    [['units', 'DEMO/TTL']],
  );
}

function testReviewMerge(): void {
  const base = new SpecDocument();
  const first = base.addListItem('DEMO/items');
  base.setContent(`${first}/label`, 'one');
  const copy = new SpecDocument();
  copy.loadJson(base.toJson());
  const added = copy.addListItem('DEMO/items');
  copy.setContent(`${added}/label`, 'two');
  copy.setUnits(added, 'u_a');
  const member = { memberId: 'alice', displayName: 'Alice', role: '' };
  const result = mergeReviews(base, [{ ...member, document: copy }], {
    team: [member],
    date: '2026-11-12',
    author: 'alice',
    model,
  });
  const merged = result.merged;
  const items = merged.listItems('DEMO/items');
  _eq('merge.items', items.length, 2);
  _eq('merge.units', merged.units(items[items.length - 1]), 'u_a');
}

// --- validation phase 8 ------------------------------------------------------

function _findings(d: SpecDocument): Array<[string, string, string]> {
  return validateDocument(model, d).map(
    (e) => [e.path, e.code, e.message] as [string, string, string],
  );
}

function testValidation(): void {
  const clean = _register();
  clean.setUnits('DEMO/TTL', 'u_a');
  clean.setUnits('DEMO/REG', 'u_a,u_b');
  _eq('phase8.clean', _findings(clean), []);

  const unknown = _register();
  unknown.setUnits('DEMO/TTL', 'u_x, u_a ,u_y');
  _eq('phase8.unknownUnit', _findings(unknown), [
    ['DEMO/TTL', 'unknownUnit', 'units names "u_x", which no generation unit declares'],
    ['DEMO/TTL', 'unknownUnit', 'units names "u_y", which no generation unit declares'],
  ]);

  const unrouted = _register();
  unrouted.setUnits('DEMO/META', 'u_a');
  unrouted.setUnits('DEMO/META/tags', 'u_a');
  unrouted.setUnits('DEMO/control', 'u_a');
  unrouted.setUnits('DEMO/DLV-LST-1', 'u_a');
  // Routed: a field of a routed class, a list of a routed element.
  unrouted.setUnits('DEMO/PRI', 'u_a');
  unrouted.setUnits('DEMO/CARD-LST', 'u_a');
  const message = 'units is set on a section that routes nothing to CodeSpecs';
  _eq('phase8.unitsUnrouted', _findings(unrouted), [
    ['DEMO/DLV-LST-1', 'unitsUnrouted', message],
    ['DEMO/META', 'unitsUnrouted', message],
    ['DEMO/META/tags', 'unitsUnrouted', message],
    ['DEMO/control', 'unitsUnrouted', message],
  ]);

  const reg = _register();
  const dup = reg.addListItem('DEMO/DLV-LST');
  reg.setFormField(`${dup}/content`, 'unitId', 'u_a');
  reg.setFormField(`${dup}/content`, 'kind', 'server');
  // An item with no value at all is absence, not a finding.
  reg.addListItem('DEMO/DLV-LST');
  for (const area of ['CE-DB', 'ce-db', 'CE-', 'CE-D1']) {
    const route = reg.addListItem('DEMO/DLV-LST-1/DLR-LST');
    reg.setFormField(`${route}/content`, 'area', area);
    reg.setFormField(`${route}/content`, 'mapping', 'dart-tom');
  }
  _eq('phase8.register', _findings(reg), [
    [
      'DEMO/DLV-LST-1/DLR-LST-2',
      'unitAreaMalformed',
      'mapping area "ce-db" is not an area code (CE-…)',
    ],
    [
      'DEMO/DLV-LST-1/DLR-LST-3',
      'unitAreaMalformed',
      'mapping area "CE-" is not an area code (CE-…)',
    ],
    [
      'DEMO/DLV-LST-1/DLR-LST-4',
      'unitAreaMalformed',
      'mapping area "CE-D1" is not an area code (CE-…)',
    ],
    ['DEMO/DLV-LST-3', 'duplicateUnitId', 'generation unit "u_a" is declared twice'],
    [
      'DEMO/DLV-LST-3',
      'unitBuildsNothing',
      'generation unit "u_a" builds neither a deploymentTarget nor a component',
    ],
  ]);

  const order = _register();
  order.setUnits('DEMO/TTL', 'u_x');
  order.setContent('DEMO/SUM', '> ⬆️ **C-1** a\n\n> ⬆️ **C-1** b');
  _eq(
    'phase8.order',
    validateDocument(model, order).map((e) => e.code),
    ['unknownUnit', 'duplicateAnnotationId'],
  );
}

// --- the extract -------------------------------------------------------------

function _extractor(d: SpecDocument): CodeSpecsExtractor {
  const catalog = CodeSpecsAreaCatalog.fromJson(
    _corpusJson('codespecs_extract_cases.json').catalog,
  );
  return new CodeSpecsExtractor(model, d, catalog);
}

function _extractDocument(): SpecDocument {
  const d = new SpecDocument();
  d.setContent('DEMO/TTL', 'Hello');
  d.setContent('DEMO/SUM', 'Sum');
  d.setContent('DEMO/notes/NOTE-BDY', 'Body');
  const card = d.addListItem('DEMO/CARD-LST');
  d.setFormField(`${card}/content`, 'note', 'a card');
  return d;
}

function testExtract(): void {
  const plain = _extractor(_extractDocument()).extractAll();
  const all = plain.flatMap((x) => x.entries);
  _check('extract.none.nonEmpty', all.length > 0);
  _check('extract.none.empty', all.every((e) => e.units.length === 0));

  const d = _extractDocument();
  d.setUnits('DEMO', 'app_client');
  d.setUnits('DEMO/notes', 'app_server, app_shared');
  d.setUnits('DEMO/TTL', 'app_client,app_server');
  const extracts = _extractor(d).extractAll();
  const byPath = new Map<string, string[]>();
  for (const x of extracts) {
    for (const e of x.entries) byPath.set(e.path, e.units);
  }
  // Inherited from the root.
  _eq('extract.inherited', byPath.get('DEMO/SUM'), ['app_client']);
  // The entry's own path wins over every ancestor.
  _eq('extract.own', byPath.get('DEMO/TTL'), ['app_client', 'app_server']);
  // From the nearest ancestor, split at its commas and trimmed.
  _eq('extract.nearest', byPath.get('DEMO/notes/NOTE-BDY'), ['app_server', 'app_shared']);
  // Through a list item from the root.
  _eq('extract.listItem', byPath.get(`DEMO/CARD-LST-1/content`), ['app_client']);

  const only = _extractDocument();
  only.setUnits('DEMO/TTL', 'app_client,app_server');
  const fm = _extractor(only)
    .extractAll()
    .find((x) => x.area.code === 'CE-FM');
  _check('extract.fm.found', fm !== undefined);
  if (fm === undefined) return;
  const yaml = fm.toYaml();
  _check(
    'extract.yaml.afterRoutingNote',
    yaml.includes(
      '      routingNote: "the demo capture screen and its view state"\n' +
        '      units: ["app_client", "app_server"]\n' +
        '      value: "Hello"\n',
    ),
    yaml,
  );
  _eq('extract.yaml.onlyWhereSet', yaml.split('units:').length - 1, 1);
  _check(
    'extract.md.afterRoutedBy',
    fm
      .toMarkdown()
      .includes(
        '- routed by: `CodeSpecPart.form` declared on `Demo`\n' +
          '- units: `app_client`, `app_server`\n',
      ),
    fm.toMarkdown(),
  );
  const back = parseCodeSpecsExtractYaml(yaml);
  _eq(
    'extract.read.units',
    back.entries.find((e) => e.path === 'DEMO/TTL')?.units,
    ['app_client', 'app_server'],
  );
  _check(
    'extract.read.absentEmpty',
    back.entries.filter((e) => e.path !== 'DEMO/TTL').every((e) => e.units.length === 0),
  );
  _check('extract.read.reencode', back.toYaml() === yaml);
}

// --- the register (specGenerationUnits) --------------------------------------

function testRegister(): void {
  // Units in register order, each with its own mappings.
  const d = _register();
  d.setFormField('DEMO/DLV-LST-1/content', 'kind', 'client');
  for (const [unit, area, mapping] of [
    ['DEMO/DLV-LST-1', 'CE-NV', 'dart-tom'],
    ['DEMO/DLV-LST-1', 'CE-TX', ' ts-react '],
    ['DEMO/DLV-LST-2', 'CE-NV', 'dart-tom'],
  ]) {
    const r = d.addListItem(`${unit}/DLR-LST`);
    d.setFormField(`${r}/content`, 'area', area);
    d.setFormField(`${r}/content`, 'mapping', mapping);
  }
  const units = specGenerationUnits(model, d);
  _eq('register.ids', units.map((u) => u.unitId), ['u_a', 'u_b']);
  _eq('register.kind', units[0].kind, 'client');
  _eq('register.path', units[0].path, 'DEMO/DLV-LST-1');
  _eq(
    'register.mappings',
    units[0].mappings.map((m) => [m.area, m.mapping]),
    [
      ['CE-NV', 'dart-tom'],
      ['CE-TX', 'ts-react'],
    ],
  );
  _eq('register.mappingFor', units[0].mappingFor('CE-TX'), 'ts-react');
  _eq('register.mappingFor.none', units[units.length - 1].mappingFor('CE-TX'), null);
  _eq('register.default.both', specDefaultUnits(units, 'CE-NV'), ['u_a', 'u_b']);
  _eq('register.default.one', specDefaultUnits(units, 'CE-TX'), ['u_a']);
  _eq('register.default.none', specDefaultUnits(units, 'CE-DB'), []);

  // A unit without an id, and a second unit of one id, are left out.
  const left = _register();
  left.addListItem('DEMO/DLV-LST');
  const dup = left.addListItem('DEMO/DLV-LST');
  left.setFormField(`${dup}/content`, 'unitId', 'u_a');
  _eq(
    'register.leftOut',
    specGenerationUnits(model, left).map((u) => u.unitId),
    ['u_a', 'u_b'],
  );

  // A document without a register declares none.
  _eq('register.none', specGenerationUnits(model, new SpecDocument()), []);
}

function main(): number {
  testStore();
  testSnapshot();
  testPurge();
  testMove();
  testFacade();
  testMarkdown();
  testYaml();
  testYamlCollisionGuards();
  testApplyMarkdown();
  testAssembly();
  testReviewMerge();
  testValidation();
  testExtract();
  testRegister();
  if (_failed.length > 0) {
    console.log(`FAIL: ${_failed.length}/${_passed + _failed.length} checks failed`);
    for (const f of _failed) console.log(`  - ${f}`);
    return 1;
  }
  console.log(`OK: ${_passed} checks passed`);
  return 0;
}

process.exit(main());
