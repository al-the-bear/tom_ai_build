'use strict';

/**
 * SOM §11.2 `units`: the generation units a section goes to. Kept exactly as
 * `codeSpec` is — a sparse store by section path, the Markdown heading key
 * `units="a,b"` after `codeSpec`, the YAML key `units` after `codeSpec`, the
 * facade's `$units`, the snapshot's `units` map — and checked by the instance
 * tier's phase 8. Port of the Dart runtime's `test/spec_units_test.dart`
 * (minus the cases on members this port does not have: `captureState` /
 * `restoreState` and a path normalizer), plus the extract cases of its
 * `spec_codespecs_extract_test.dart`.
 */

const { test, describe } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const {
  SpecDocument,
  SpecModel,
  SpecDocumentMarkdown,
  yamlEncode,
  SpecYamlFormatException,
  SomNode,
  buildSomMetaTree,
  mergeReviews,
  validateDocument,
  CodeSpecsAreaCatalog,
  CodeSpecsExtractor,
  parseCodeSpecsExtractYaml,
} = require('../tom_som_runtime/index.js');

const _CORPUS = path.join(__dirname, '..', '..', 'tom_som_conformance', 'corpus');

/** The shared corpus model: the demo root with the register `DEMO/DLV-LST`. */
function corpusModel() {
  return SpecModel.fromJson(
    JSON.parse(fs.readFileSync(path.join(_CORPUS, 'model.meta.json'), 'utf8')),
  );
}

/** A register declaring `u_a` and `u_b`, both building something. */
function register() {
  const d = new SpecDocument();
  const a = d.addListItem('DEMO/DLV-LST');
  d.setFormField(`${a}/content`, 'unitId', 'u_a');
  d.setFormField(`${a}/content`, 'component', 'ARCM-COMP-A');
  const b = d.addListItem('DEMO/DLV-LST');
  d.setFormField(`${b}/content`, 'unitId', 'u_b');
  d.setFormField(`${b}/content`, 'deploymentTarget', 'DEPTAR-DEPL-B');
  return d;
}

describe('the store', () => {
  test('units / setUnits / unitsPaths; empty clears', () => {
    const d = new SpecDocument();
    assert.strictEqual(d.units('DEMO/TTL'), null);
    d.setUnits('DEMO/TTL', 'u_a,u_b');
    assert.strictEqual(d.units('DEMO/TTL'), 'u_a,u_b');
    assert.deepStrictEqual(Array.from(d.unitsPaths), ['DEMO/TTL']);
    assert.strictEqual(d.isEmpty, false);
    assert.strictEqual(d.hasValuesUnder('DEMO'), true);
    d.setUnits('DEMO/TTL', '');
    assert.strictEqual(d.units('DEMO/TTL'), null);
    assert.deepStrictEqual(Array.from(d.unitsPaths), []);
    assert.strictEqual(d.isEmpty, true);
  });

  test('the snapshot carries `units` beside `codeSpecs`, sorted', () => {
    const d = new SpecDocument();
    d.setCodeSpec('DEMO/TTL', 'A');
    d.setUnits('DEMO/TTL', 'u_b');
    d.setUnits('DEMO/SUM', 'u_a');
    const json = d.toJson();
    assert.deepStrictEqual(Object.keys(json), ['codeSpecs', 'units']);
    assert.deepStrictEqual(Object.keys(json.units), ['DEMO/SUM', 'DEMO/TTL']);
    const back = new SpecDocument();
    back.loadJson(JSON.parse(JSON.stringify(json)));
    assert.deepStrictEqual(back.toJson(), json);
    // No units, no key.
    assert.strictEqual('units' in new SpecDocument().toJson(), false);
  });

  test('removeValuesUnder clears units under the prefix', () => {
    const d = new SpecDocument();
    d.setUnits('DEMO/notes', 'u_a');
    d.setUnits('DEMO/notes/NOTE-BDY', 'u_b');
    d.setUnits('DEMO/TTL', 'u_a');
    d.removeValuesUnder('DEMO/notes');
    assert.deepStrictEqual(Array.from(d.unitsPaths), ['DEMO/TTL']);
  });

  test('units move with their list item', () => {
    const model = corpusModel();
    const d = new SpecDocument();
    const first = d.addListItem('DEMO/items');
    const second = d.addListItem('DEMO/items');
    d.setContent(`${first}/label`, 'one');
    d.setContent(`${second}/label`, 'two');
    d.setUnits(second, 'u_a');
    d.moveListItem(model, second, 0);
    assert.strictEqual(d.units('DEMO/items-1'), 'u_a');
    assert.strictEqual(d.units('DEMO/items-2'), null);
  });
});

test('the facade reads and writes $units; null clears', () => {
  const d = new SpecDocument();
  const node = new SomNode(d, 'DEMO/TTL');
  assert.strictEqual(node.$units, null);
  node.$units = 'u_a';
  assert.strictEqual(d.units('DEMO/TTL'), 'u_a');
  assert.strictEqual(node.$units, 'u_a');
  node.$units = null;
  assert.strictEqual(node.$units, null);
  node.$units = 'u_b';
  node.$units = '';
  assert.deepStrictEqual(Array.from(d.unitsPaths), []);
});

describe('Markdown', () => {
  const model = corpusModel();

  test('emits units after codeSpec in the heading comment', () => {
    const d = new SpecDocument();
    d.setContent('DEMO/TTL', 'Hello');
    d.setCodeSpec('DEMO/TTL', 'DemoTitle');
    d.setUnits('DEMO/TTL', 'u_a,u_b');
    d.setContent('DEMO/SUM', 'Sum');
    d.setUnits('DEMO/SUM', 'u_a');
    const md = d.toMarkdown(model);
    assert.ok(
      md.includes(
        '## <!--[TTL] codeSpec="DemoTitle" units="u_a,u_b"--> Document Title\n',
      ),
      md,
    );
    assert.ok(md.includes('## <!--[SUM] units="u_a"--> Summary\n'), md);
  });

  test('parses units in every quoting, beside or without codeSpec', () => {
    const md =
      '# <!--[DEMO] units=u_root--> Demo Document\n\n' +
      '## <!--[TTL] codeSpec="DemoTitle" units="u_a,u_b"--> Title\n\n' +
      'Hello\n\n' +
      "## <!--[SUM] units='u_c'--> Summary\n\n" +
      'Sum\n\n' +
      '## <!--[CNT] codeSpec="units=no"--> Count\n\n' +
      '3\n';
    const result = new SpecDocumentMarkdown(model, new SpecDocument()).parse(md);
    assert.deepStrictEqual(result.rejections, []);
    assert.deepStrictEqual(result.units, {
      DEMO: 'u_root',
      'DEMO/TTL': 'u_a,u_b',
      'DEMO/SUM': 'u_c',
    });
    assert.strictEqual(result.codeSpecs['DEMO/TTL'], 'DemoTitle');
    // A `units=` inside a quoted codeSpec value is not the key.
    assert.strictEqual(result.codeSpecs['DEMO/CNT'], 'units=no');
  });

  test('unitsOf trims, and answers empty without the key', () => {
    assert.strictEqual(SpecDocumentMarkdown.unitsOf(' units=" a,b "'), 'a,b');
    assert.strictEqual(SpecDocumentMarkdown.unitsOf(' codeSpec="X"'), '');
    assert.strictEqual(SpecDocumentMarkdown.unitsOf(' xunits="a"'), '');
  });

  test('round-trips byte-stably through fromMarkdown', () => {
    const d = register();
    d.setContent('DEMO/TTL', 'Hello');
    d.setCodeSpec('DEMO/TTL', 'DemoTitle');
    d.setUnits('DEMO/TTL', 'u_a');
    d.setContent('DEMO/notes/NOTE-BDY', 'Body');
    d.setUnits('DEMO/notes', 'u_a,u_b');
    const md = d.toMarkdown(model);
    const back = SpecDocument.fromMarkdown(md, model).document;
    assert.strictEqual(back.units('DEMO/TTL'), 'u_a');
    assert.strictEqual(back.units('DEMO/notes'), 'u_a,u_b');
    assert.strictEqual(back.toMarkdown(model), md);
  });
});

describe('YAML', () => {
  const model = corpusModel();
  const tree = buildSomMetaTree(model);
  const enc = (d) => yamlEncode(d, tree, '1.0');

  test('writes units right after codeSpec, promoting a scalar', () => {
    const d = new SpecDocument();
    d.setContent('DEMO/TTL', 'Hello');
    d.setHeadline('DEMO/TTL', 'Title');
    d.setCodeSpec('DEMO/TTL', 'DemoTitle');
    d.setUnits('DEMO/TTL', 'u_a');
    d.setContent('DEMO/CNT', '3');
    d.setUnits('DEMO/CNT', 'u_b');
    d.setContent('DEMO/notes/NOTE-BDY', 'Body');
    d.setUnits('DEMO/notes', 'u_a,u_b');
    const yaml = enc(d);
    assert.ok(
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
    assert.ok(
      yaml.includes(
        '    CNT count:\n      units: |2-\n        u_b\n      content: 3\n',
      ),
      yaml,
    );
    assert.ok(
      yaml.includes('    NOTE notes:\n      units: |2-\n        u_a,u_b\n'),
      yaml,
    );
    const back = SpecDocument.fromYaml(yaml, tree);
    assert.deepStrictEqual(back.toJson(), d.toJson());
    assert.strictEqual(enc(back), yaml);
  });

  test('units on a form, a list container and a list item round-trip', () => {
    const d = register();
    d.setFormField('DEMO/DET', 'owner', 'Bob');
    d.setUnits('DEMO/DET', 'u_a');
    d.setUnits('DEMO/DLV-LST', 'u_b');
    d.setUnits('DEMO/DLV-LST-1', 'u_a');
    const tagItem = d.addListItem('DEMO/META/tags');
    d.setContent(tagItem, 'on');
    d.setUnits(tagItem, 'u_b');
    const yaml = enc(d);
    const back = SpecDocument.fromYaml(yaml, tree);
    assert.deepStrictEqual(back.toJson(), d.toJson());
    assert.strictEqual(enc(back), yaml);
  });

  test('a scalar mapping names `units` among the keys it may hold', () => {
    const d = new SpecDocument();
    d.setContent('DEMO/TTL', 'Hello');
    d.setUnits('DEMO/TTL', 'u_a');
    const yaml = enc(d).replace('      units:', '      unitz:');
    assert.throws(
      () => SpecDocument.fromYaml(yaml, tree),
      (e) =>
        e instanceof SpecYamlFormatException &&
        e.message.includes(
          '`headline`/`codeSpec`/`units`/`content` keys when written as a mapping',
        ),
    );
  });

  test('refuses units where a child or form field is named `units`', () => {
    const clash = SpecModel.fromJson({
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
    const encode = (d) => yamlEncode(d, clashTree, '1.0');
    const own = new SpecDocument();
    own.setUnits('R', 'u_a');
    assert.throws(
      () => encode(own),
      (e) =>
        e instanceof SpecYamlFormatException &&
        e.message.includes('also serializes as key `units`'),
    );
    const form = new SpecDocument();
    form.setFormField('R/SHP', 'units', '3');
    form.setUnits('R/SHP', 'u_a');
    assert.throws(
      () => encode(form),
      (e) =>
        e instanceof SpecYamlFormatException &&
        e.message.includes('field literally named `units`'),
    );
  });

  test('a list item may not be keyed `units`', () => {
    const d = new SpecDocument();
    d.addListItem('DEMO/DLV-LST', 'units');
    assert.throws(() => enc(d), SpecYamlFormatException);
  });

  test('a leftover units value is named', () => {
    const d = new SpecDocument();
    d.setUnits('DEMO/NOWHERE', 'u_a');
    assert.throws(
      () => enc(d),
      (e) =>
        e instanceof SpecYamlFormatException &&
        e.message.includes('units at `DEMO/NOWHERE`'),
    );
  });
});

test('applyMarkdownResult overwrites, clears and keeps units', () => {
  const model = corpusModel();
  const d = new SpecDocument();
  d.setUnits('DEMO/TTL', 'stale');
  d.setUnits('DEMO/SUM', 'stale');
  d.setUnits('OTHER/kept', 'kept');
  const md =
    '# <!--[DEMO]--> Demo Document\n\n' +
    '## <!--[TTL] units="u_a"--> Document Title\n\nHello\n';
  d.applyMarkdownResult(new SpecDocumentMarkdown(model, new SpecDocument()).parse(md));
  assert.deepStrictEqual(d.toJson().units, { 'DEMO/TTL': 'u_a', 'OTHER/kept': 'kept' });
});

test('assembly merges units and refuses two fragments writing one', () => {
  const a = new SpecDocument();
  a.setUnits('DEMO/TTL', 'u_a');
  const b = new SpecDocument();
  b.setUnits('DEMO/SUM', 'u_b');
  const ok = SpecDocument.assemble(new Map([['a', a], ['b', b]]));
  assert.strictEqual(ok.ok, true);
  assert.strictEqual(ok.document.units('DEMO/SUM'), 'u_b');
  const c = new SpecDocument();
  c.setUnits('DEMO/TTL', 'u_b');
  const clash = SpecDocument.assemble(new Map([['a', a], ['c', c]]));
  assert.strictEqual(clash.ok, false);
  assert.strictEqual(clash.overlaps.length, 1);
  assert.strictEqual(clash.overlaps[0].store, 'units');
  assert.strictEqual(clash.overlaps[0].path, 'DEMO/TTL');
});

test('a review merge carries the units of an item a copy added', () => {
  const model = corpusModel();
  const base = new SpecDocument();
  const first = base.addListItem('DEMO/items');
  base.setContent(`${first}/label`, 'one');
  const copy = new SpecDocument();
  copy.loadJson(base.toJson());
  const added = copy.addListItem('DEMO/items');
  copy.setContent(`${added}/label`, 'two');
  copy.setUnits(added, 'u_a');
  const result = mergeReviews(
    base,
    [{ memberId: 'alice', displayName: 'Alice', role: '', document: copy }],
    {
      team: [{ memberId: 'alice', displayName: 'Alice', role: '' }],
      date: '2026-11-12',
      author: 'alice',
      model,
    },
  );
  const items = result.merged.listItems('DEMO/items');
  assert.strictEqual(items.length, 2);
  assert.strictEqual(result.merged.units(items[items.length - 1]), 'u_a');
});

describe('validation phase 8', () => {
  const model = corpusModel();
  const check = (d) => validateDocument(model, d).map((e) => [e.path, e.code, e.message]);

  test('a declared unit on a routed section is clean', () => {
    const d = register();
    d.setUnits('DEMO/TTL', 'u_a');
    d.setUnits('DEMO/REG', 'u_a,u_b');
    assert.deepStrictEqual(check(d), []);
  });

  test('unknownUnit names each undeclared id, in the order written', () => {
    const d = register();
    d.setUnits('DEMO/TTL', 'u_x, u_a ,u_y');
    assert.deepStrictEqual(check(d), [
      ['DEMO/TTL', 'unknownUnit', 'units names "u_x", which no generation unit declares'],
      ['DEMO/TTL', 'unknownUnit', 'units names "u_y", which no generation unit declares'],
    ]);
  });

  test('unitsUnrouted: a class reaching no @CodeSpecKind', () => {
    const d = register();
    d.setUnits('DEMO/META', 'u_a');
    d.setUnits('DEMO/META/tags', 'u_a');
    d.setUnits('DEMO/control', 'u_a');
    d.setUnits('DEMO/DLV-LST-1', 'u_a');
    // Routed: a field of a routed class, a list of a routed element.
    d.setUnits('DEMO/PRI', 'u_a');
    d.setUnits('DEMO/CARD-LST', 'u_a');
    const message = 'units is set on a section that routes nothing to CodeSpecs';
    assert.deepStrictEqual(check(d), [
      ['DEMO/DLV-LST-1', 'unitsUnrouted', message],
      ['DEMO/META', 'unitsUnrouted', message],
      ['DEMO/META/tags', 'unitsUnrouted', message],
      ['DEMO/control', 'unitsUnrouted', message],
    ]);
  });

  test('the register: duplicate, builds nothing, malformed area', () => {
    const d = register();
    const dup = d.addListItem('DEMO/DLV-LST');
    d.setFormField(`${dup}/content`, 'unitId', 'u_a');
    d.setFormField(`${dup}/content`, 'kind', 'server');
    // An item with no value at all is absence, not a finding.
    d.addListItem('DEMO/DLV-LST');
    for (const area of ['CE-DB', 'ce-db', 'CE-', 'CE-D1']) {
      const route = d.addListItem('DEMO/DLV-LST-1/DLR-LST');
      d.setFormField(`${route}/content`, 'area', area);
      d.setFormField(`${route}/content`, 'mapping', 'dart-tom');
    }
    assert.deepStrictEqual(check(d), [
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
  });

  test('phase 8 follows the derived values and precedes annotations', () => {
    const d = register();
    d.setUnits('DEMO/TTL', 'u_x');
    d.setContent('DEMO/SUM', '> ⬆️ **C-1** a\n\n> ⬆️ **C-1** b');
    assert.deepStrictEqual(
      validateDocument(model, d).map((e) => e.code),
      ['unknownUnit', 'duplicateAnnotationId'],
    );
  });
});

describe('the CodeSpecs extract carries units', () => {
  const model = corpusModel();
  const table = JSON.parse(
    fs.readFileSync(path.join(_CORPUS, 'codespecs_extract_cases.json'), 'utf8'),
  );
  const extractAll = (document) =>
    new CodeSpecsExtractor({
      model,
      document,
      catalog: CodeSpecsAreaCatalog.fromJson(table.catalog),
    }).extractAll();
  const byPath = (document) => {
    const out = new Map();
    for (const x of extractAll(document)) {
      for (const e of x.entries) out.set(e.path, e);
    }
    return out;
  };

  test('the nearest stored units, own or inherited, split and trimmed', () => {
    const d = new SpecDocument();
    d.setContent('DEMO/TTL', 'Hello');
    d.setContent('DEMO/SUM', 'Sum');
    d.setContent('DEMO/notes/NOTE-BDY', 'Body');
    const item = d.addListItem('DEMO/items');
    d.setContent(`${item}/label`, 'First');
    d.setUnits('DEMO', 'app_client');
    d.setUnits('DEMO/SUM', 'app_shared');
    d.setUnits('DEMO/items', 'app_server, app_shared');
    const entries = byPath(d);
    // Inherited from the root.
    assert.deepStrictEqual(entries.get('DEMO/TTL').units, ['app_client']);
    // The entry's own path wins over every ancestor.
    assert.deepStrictEqual(entries.get('DEMO/SUM').units, ['app_shared']);
    // Through the list item from the nearest ancestor (the list container).
    assert.deepStrictEqual(entries.get(`${item}/label`).units, [
      'app_server',
      'app_shared',
    ]);
    assert.deepStrictEqual(entries.get('DEMO/notes/NOTE-BDY').units, ['app_client']);
  });

  test('an entry without units on its way carries none', () => {
    const d = new SpecDocument();
    d.setContent('DEMO/TTL', 'Hello');
    d.setContent('DEMO/SUM', 'Sum');
    const entries = extractAll(d).flatMap((x) => x.entries);
    assert.ok(entries.length > 0);
    assert.ok(entries.every((e) => e.units.length === 0));
  });

  test('writes units only where set, and reads them back', () => {
    const d = new SpecDocument();
    d.setContent('DEMO/TTL', 'Hello');
    d.setContent('DEMO/SUM', 'Sum');
    d.setUnits('DEMO/TTL', 'app_client,app_server');
    const extract = extractAll(d).find((x) => x.area.code === 'CE-FM');
    const yaml = extract.toYaml();
    assert.ok(
      yaml.includes(
        '      routingNote: "the demo capture screen and its view state"\n' +
          '      units: ["app_client", "app_server"]\n' +
          '      value: "Hello"\n',
      ),
      yaml,
    );
    assert.strictEqual(yaml.split('units:').length - 1, 1);
    assert.ok(
      extract
        .toMarkdown()
        .includes(
          '- routed by: `CodeSpecPart.form` declared on `Demo`\n' +
            '- units: `app_client`, `app_server`\n',
        ),
    );
    const back = parseCodeSpecsExtractYaml(yaml);
    assert.deepStrictEqual(
      back.entries.find((e) => e.path === 'DEMO/TTL').units,
      ['app_client', 'app_server'],
    );
    assert.ok(
      back.entries.filter((e) => e.path !== 'DEMO/TTL').every((e) => e.units.length === 0),
    );
    assert.strictEqual(back.toYaml(), yaml);
  });
});
