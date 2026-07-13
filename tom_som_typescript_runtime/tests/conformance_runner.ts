#!/usr/bin/env node
/**
 * Shared-corpus conformance runner for the TypeScript generic runtime.
 *
 * Loads the language-agnostic conformance corpus produced from the Dart reference
 * (`tom_som_conformance/corpus`) and asserts the TypeScript port reproduces every
 * golden byte-for-byte and matches every behavioural case:
 *
 *   * model meta-data loads (root + class structure);
 *   * `state.json` loads and re-serialises identically;
 *   * YAML encode == `expected.docspecs.yaml` (byte-for-byte, hierarchical v2
 *     via the SomMetaTree built from the model meta-data);
 *   * YAML decode → memory → encode is byte-stable + preserves the stamp and
 *     lands the same memory as `state.json`;
 *   * reflection resolution cases;
 *   * validation cases;
 *   * the imperative operations script.
 *
 * Build with `tsc`, then run `node dist/tests/conformance_runner.js`. Exit code
 * 0 == all green.
 */

import * as fs from 'fs';
import * as path from 'path';

import {
  SomMetaTree,
  SpecDocument,
  SpecDocumentMarkdown,
  SpecModel,
  buildSomMetaTree,
  SpecReflection,
  SpecSectionIdCollision,
  SpecSerializationOrder,
  encodeTwoLetterDate,
  generateListItemSectionId,
  validateDocument,
  yamlDecode,
  yamlEncode,
} from '../src/index';

const _HERE = __dirname; // dist/tests
const _PKG_ROOT = path.dirname(path.dirname(_HERE)); // tom_som_typescript_runtime
const _CORPUS = path.normalize(
  path.join(_PKG_ROOT, '..', 'tom_som_conformance', 'corpus'),
);

const _MODEL_VERSION = '1.0';

let _passed = 0;
const _failed: string[] = [];

function _check(name: string, condition: boolean, detail = ''): void {
  if (condition) {
    _passed += 1;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

function _read(name: string): string {
  return fs.readFileSync(path.join(_CORPUS, name), 'utf8');
}

function _readJson(name: string): any {
  return JSON.parse(_read(name));
}

function _byteDiff(label: string, actual: string, expected: string): string {
  if (actual === expected) {
    return '';
  }
  const aLines = actual.split('\n');
  const eLines = expected.split('\n');
  const max = Math.max(aLines.length, eLines.length);
  for (let idx = 0; idx < max; idx++) {
    const a = idx < aLines.length ? aLines[idx] : '<EOF>';
    const e = idx < eLines.length ? eLines[idx] : '<EOF>';
    if (a !== e) {
      return `${label}: first diff at line ${idx + 1}: got ${JSON.stringify(a)} want ${JSON.stringify(e)}`;
    }
  }
  return `${label}: differ (len got ${actual.length} want ${expected.length})`;
}

function _deepEqual(a: any, b: any): boolean {
  if (a === b) {
    return true;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    if (a.length !== b.length) {
      return false;
    }
    for (let i = 0; i < a.length; i++) {
      if (!_deepEqual(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  if (a && b && typeof a === 'object' && typeof b === 'object') {
    const ak = Object.keys(a);
    const bk = Object.keys(b);
    if (ak.length !== bk.length) {
      return false;
    }
    for (const k of ak) {
      if (!Object.prototype.hasOwnProperty.call(b, k)) {
        return false;
      }
      if (!_deepEqual(a[k], b[k])) {
        return false;
      }
    }
    return true;
  }
  return false;
}

function _jsonMismatch(actual: any, expected: any): string {
  if (_deepEqual(actual, expected)) {
    return '';
  }
  return `got ${JSON.stringify(actual)} want ${JSON.stringify(expected)}`;
}

function _loadModel(): SpecModel {
  return SpecModel.fromJson(_readJson('model.meta.json'));
}

function _documentFromState(state: any): SpecDocument {
  const doc = new SpecDocument();
  doc.loadJson(state);
  return doc;
}

function testModelMeta(model: SpecModel): void {
  const root = model.roots[0];
  _check('model.root.sectionId', root.sectionId === 'DEMO', String(root.sectionId));
  _check('model.root.type', root.type === 'Demo', root.type);
  _check('model.classCount', model.classes.size === 3, String(model.classes.size));
  const demo = model.classNamed('Demo');
  _check('model.Demo.found', demo !== null);
  if (demo !== null) {
    const names = demo.fields.map((f) => f.name);
    _check(
      'model.Demo.fields',
      _deepEqual(names, [
        'title',
        'summary',
        'priority',
        'count',
        'details',
        'items',
        'meta',
      ]),
      String(names),
    );
  }
}

function testStateRoundTrip(): void {
  const state = _readJson('state.json');
  const doc = _documentFromState(state);
  _check(
    'state.toJson',
    _deepEqual(doc.toJson(), state),
    _jsonMismatch(doc.toJson(), state),
  );
}

function testYamlEncode(tree: SomMetaTree): void {
  const doc = _documentFromState(_readJson('state.json'));
  const expected = _read('expected.docspecs.yaml');
  const actual = yamlEncode(doc, tree, _MODEL_VERSION);
  _check('yaml.encode', actual === expected, _byteDiff('yaml.encode', actual, expected));
}

function testYamlDecodeRoundTrip(tree: SomMetaTree): void {
  const expected = _read('expected.docspecs.yaml');
  const contents = yamlDecode(expected, tree);
  _check(
    'yaml.decode.stamp',
    contents.modelVersion === _MODEL_VERSION,
    String(contents.modelVersion),
  );
  _check(
    'yaml.decode.memory',
    _deepEqual(contents.document.toJson(), _readJson('state.json')),
    _jsonMismatch(contents.document.toJson(), _readJson('state.json')),
  );
  const actual = yamlEncode(contents.document, tree, contents.modelVersion || _MODEL_VERSION);
  _check(
    'yaml.decode.reencode',
    actual === expected,
    _byteDiff('yaml.decode.reencode', actual, expected),
  );
}

function testMarkdownExport(model: SpecModel): void {
  const doc = _documentFromState(_readJson('state.json'));
  const expected = _read('expected.md');
  const actual = new SpecDocumentMarkdown(model, doc).exportRoot(model.roots[0]);
  _check('md.export', actual === expected, _byteDiff('md.export', actual, expected));
}

function testMarkdownRoundTrip(model: SpecModel): void {
  const golden = _read('expected.md');
  const doc = _documentFromState(_readJson('state.json'));
  const parsed = new SpecDocumentMarkdown(model, doc).parse(golden);
  _check(
    'md.parse.clean',
    parsed.rejections.length === 0,
    parsed.rejections.map((r) => String(r)).join('; '),
  );
  const reDoc = new SpecDocument();
  reDoc.loadJson({
    content: parsed.content,
    forms: parsed.forms,
    lists: parsed.lists,
  });
  const actual = new SpecDocumentMarkdown(model, reDoc).exportRoot(model.roots[0]);
  _check('md.parse.reexport', actual === golden, _byteDiff('md.parse.reexport', actual, golden));
}

// Plan item #9: parsing `expected.md` and applying it must reproduce
// `state.json` (the YAML-route memory) exactly, proving both formats converge
// on one in-memory document (§4.1).
function testMarkdownMemoryLanding(model: SpecModel): void {
  const golden = _read('expected.md');
  const canonical = _readJson('state.json');
  const doc = _documentFromState(canonical);
  const parsed = new SpecDocumentMarkdown(model, doc).parse(golden);
  _check(
    'md.land.clean',
    parsed.rejections.length === 0,
    parsed.rejections.map((r) => String(r)).join('; '),
  );
  const landed = new SpecDocument();
  landed.loadJson({
    content: parsed.content,
    forms: parsed.forms,
    lists: parsed.lists,
  });
  _check(
    'md.land.memory',
    _deepEqual(landed.toJson(), canonical),
    _jsonMismatch(landed.toJson(), canonical),
  );
}

function _throwsWith(name: string, fn: () => unknown, needles: string[]): void {
  try {
    fn();
    _check(name, false, 'expected throw, but returned normally');
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const missing = needles.filter((n) => !msg.includes(n));
    _check(name, missing.length === 0, missing.length ? `missing ${missing.join(', ')} in '${msg}'` : '');
  }
}

// Item-12 one-liners: SpecModel.rootByType + SpecDocument.toMarkdown. Mirrors the
// Dart reference groups in spec_model_test.dart / spec_document_markdown_test.dart.
function testItem12(model: SpecModel): void {
  const twoRoot = SpecModel.fromJson({
    roots: [
      { type: 'Alpha', title: 'Alpha Doc', sectionId: 'A00' },
      { type: 'Beta', title: 'Beta Doc', sectionId: 'B00' },
    ],
    classes: {},
  });

  // rootByType: returns the matching root.
  _check('item12.rootByType.match', twoRoot.rootByType('Alpha').title === 'Alpha Doc');
  _check('item12.rootByType.sectionId', twoRoot.rootByType('Beta').sectionId === 'B00');
  // rootByType: throws naming missing + available types.
  _throwsWith('item12.rootByType.throws', () => twoRoot.rootByType('Gamma'), ['Gamma', 'Alpha', 'Beta']);

  // toMarkdown(rootType) == explicit codec output on the corpus fixture.
  const doc = _documentFromState(_readJson('state.json'));
  const rootType = model.roots[0].type;
  const oneLiner = doc.toMarkdown(model, rootType);
  const explicit = new SpecDocumentMarkdown(model, doc).exportRoot(model.rootByType(rootType));
  _check('item12.toMarkdown.explicit', oneLiner === explicit, _byteDiff('item12.toMarkdown.explicit', oneLiner, explicit));
  // toMarkdown() defaults to the single populated root (corpus has one root).
  _check('item12.toMarkdown.default', doc.toMarkdown(model) === oneLiner);
  // toMarkdown() throws on an empty document (no populated root).
  _throwsWith('item12.toMarkdown.none', () => new SpecDocument().toMarkdown(model), ['no populated root']);

  // toMarkdown() throws naming candidates when >1 root is populated.
  const ambiguousModel = SpecModel.fromJson({
    roots: [
      { type: 'Alpha', title: 'Alpha Doc', sectionId: 'A00' },
      { type: 'Beta', title: 'Beta Doc', sectionId: 'B00' },
    ],
    classes: {
      Alpha: { name: 'Alpha', sectionId: 'A00', fields: [{ name: 'overview', kind: 'content', sectionId: 'A00-OVR' }] },
      Beta: { name: 'Beta', sectionId: 'B00', fields: [{ name: 'overview', kind: 'content', sectionId: 'B00-OVR' }] },
    },
  });
  const ambiguousDoc = new SpecDocument();
  ambiguousDoc.setContent('A00/A00-OVR', 'a');
  ambiguousDoc.setContent('B00/B00-OVR', 'b');
  _throwsWith('item12.toMarkdown.ambiguous', () => ambiguousDoc.toMarkdown(ambiguousModel), ['Alpha', 'Beta']);
}

function testReflection(model: SpecModel): void {
  const refl = new SpecReflection(model);
  for (const c of _readJson('reflection_cases.json')) {
    const p = c.path;
    const res = refl.resolve(p);
    if (!c.resolves) {
      _check(`reflect[${p}].none`, res === null, 'expected no resolution');
      continue;
    }
    if (res === null) {
      _check(`reflect[${p}].some`, false, 'expected resolution, got null');
      continue;
    }
    _check(`reflect[${p}].kind`, res.kind === c.kind, `${res.kind} != ${c.kind}`);
    const fieldName = res.field !== null ? res.field.name : null;
    _check(`reflect[${p}].field`, fieldName === c.field, `${fieldName} != ${c.field}`);
    const target = res.targetClass !== null ? res.targetClass.name : null;
    _check(
      `reflect[${p}].target`,
      target === c.targetClass,
      `${target} != ${c.targetClass}`,
    );
    _check(
      `reflect[${p}].leaf`,
      res.isValueLeaf === c.isValueLeaf,
      `${res.isValueLeaf} != ${c.isValueLeaf}`,
    );
  }
}

function testValidation(model: SpecModel): void {
  for (const c of _readJson('validation_cases.json')) {
    const name = c.name;
    const doc = _documentFromState(c.state);
    const errors = validateDocument(model, doc);
    const got = errors.map((e) => [e.path, e.code]);
    const want = c.errors.map((e: any) => [e.path, e.code]);
    _check(
      `validate[${name}]`,
      _deepEqual(got, want),
      `${JSON.stringify(got)} != ${JSON.stringify(want)}`,
    );
  }
}

function testOperations(): void {
  const doc = new SpecDocument();
  const cases = _readJson('operations_cases.json');
  for (let n = 0; n < cases.length; n++) {
    const op = cases[n];
    const kind = op.op;
    if (kind === 'isEmpty') {
      _check(`op[${n}].isEmpty`, doc.isEmpty === op.expect);
    } else if (kind === 'setContent') {
      doc.setContent(op.path, op.value);
    } else if (kind === 'content') {
      _check(`op[${n}].content`, doc.content(op.path) === op.expect, String(doc.content(op.path)));
    } else if (kind === 'setFormField') {
      doc.setFormField(op.path, op.field, op.value);
    } else if (kind === 'formField') {
      _check(`op[${n}].formField`, doc.formField(op.path, op.field) === op.expect);
    } else if (kind === 'addListItem') {
      _check(`op[${n}].addListItem`, doc.addListItem(op.listPath) === op.expect);
    } else if (kind === 'listItems') {
      _check(
        `op[${n}].listItems`,
        _deepEqual(doc.listItems(op.listPath), op.expect),
        String(doc.listItems(op.listPath)),
      );
    } else if (kind === 'listItemCount') {
      _check(`op[${n}].listItemCount`, doc.listItemCount(op.listPath) === op.expect);
    } else if (kind === 'hasValuesUnder') {
      _check(`op[${n}].hasValuesUnder`, doc.hasValuesUnder(op.prefix) === op.expect);
    } else if (kind === 'removeListItem') {
      _check(`op[${n}].removeListItem`, doc.removeListItem(op.itemPath) === op.expect);
    } else {
      _check(`op[${n}].unknown`, false, kind);
    }
  }
}

function _raisesCollision(fn: () => void): boolean {
  try {
    fn();
    return false;
  } catch (e) {
    return e instanceof SpecSectionIdCollision;
  }
}

/**
 * AA1 criteria 3–6: date encoding (criterion 4), generated ids with within-day
 * numbering (criteria 3 & 6), same-day reuse on last-item deletion, and
 * unique-id enforcement on override — replayed from the shared corpus so every
 * port reproduces the identical id semantics.
 */
function testSectionId(): void {
  const cases = _readJson('section_id_cases.json');

  // Criterion 4: the two-letter day code.
  for (const c of cases.twoLetterDate) {
    const got = encodeTwoLetterDate(c.month, c.day);
    _check(
      `sectionId.twoLetterDate[${c.month}/${c.day}]`,
      got === c.expect,
      `${got} != ${c.expect}`,
    );
  }

  // Criteria 3 & 6: generated id = prefix + day + (max-for-day + 1).
  for (const c of cases.generate) {
    const got = generateListItemSectionId(c.pattern, c.month, c.day, c.existing);
    _check(
      `sectionId.generate[${c.pattern}]`,
      got === c.expect,
      `${got} != ${c.expect}`,
    );
  }

  // Criteria 5 & 6 at the document level: override keeps ids unique, deleting
  // the last same-day item frees its number for reuse, deleting a middle one
  // never renumbers the rest.
  const doc = new SpecDocument();
  const docOps = cases.documentOps;
  for (let i = 0; i < docOps.length; i++) {
    const s = docOps[i];
    switch (s.op) {
      case 'addGen': {
        const genId = generateListItemSectionId(
          s.pattern,
          s.month,
          s.day,
          doc.listItemSectionIds(s.listPath),
        );
        _check(
          `sectionId.op[${i}].addGen.id`,
          genId === s.expectId,
          `${genId} != ${s.expectId}`,
        );
        const p = doc.addListItem(s.listPath, genId);
        _check(
          `sectionId.op[${i}].addGen.path`,
          p === s.expectPath,
          `${p} != ${s.expectPath}`,
        );
        break;
      }
      case 'sectionIds': {
        const got = doc.listItemSectionIds(s.listPath);
        _check(
          `sectionId.op[${i}].sectionIds`,
          _deepEqual(got, s.expect),
          `${got} != ${s.expect}`,
        );
        break;
      }
      case 'removeListItem': {
        const got = doc.removeListItem(s.itemPath);
        _check(
          `sectionId.op[${i}].removeListItem`,
          got === Boolean(s.expect),
          String(got),
        );
        break;
      }
      case 'override':
        doc.setItemSectionId(s.itemPath, s.id);
        break;
      case 'overrideThrows':
        _check(
          `sectionId.op[${i}].overrideThrows`,
          _raisesCollision(() => doc.setItemSectionId(s.itemPath, s.id)),
          '',
        );
        break;
      case 'addExplicitThrows':
        _check(
          `sectionId.op[${i}].addExplicitThrows`,
          _raisesCollision(() => doc.addListItem(s.listPath, s.id)),
          '',
        );
        break;
      default:
        _check(`sectionId.op[${i}].unknown`, false, s.op);
    }
  }
}

/** AA1 criterion 7: members serialize in `@SerializationOrder`, not alphabetical. */
function testSerializationOrder(): void {
  const c = _readJson('serialization_order_cases.json');
  const orderModel = SpecModel.fromJson(c.model);
  const order = new SpecSerializationOrder(orderModel);

  const gotPaths = order.orderPaths(c.contentPaths);
  _check(
    'serialOrder.orderPaths',
    _deepEqual(gotPaths, c.expectedOrder),
    `${gotPaths} != ${c.expectedOrder}`,
  );

  const gotFields = order.orderFormFields(c.formPath, c.formFields);
  _check(
    'serialOrder.orderFormFields',
    _deepEqual(gotFields, c.expectedFormOrder),
    `${gotFields} != ${c.expectedFormOrder}`,
  );
}

export function main(): number {
  if (!fs.existsSync(_CORPUS) || !fs.statSync(_CORPUS).isDirectory()) {
    process.stderr.write(`corpus not found at ${_CORPUS}\n`);
    return 2;
  }
  const model = _loadModel();
  const tree = buildSomMetaTree(model);
  testModelMeta(model);
  testStateRoundTrip();
  testYamlEncode(tree);
  testYamlDecodeRoundTrip(tree);
  testMarkdownExport(model);
  testMarkdownRoundTrip(model);
  testMarkdownMemoryLanding(model);
  testItem12(model);
  testReflection(model);
  testValidation(model);
  testOperations();
  testSectionId();
  testSerializationOrder();

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

if (require.main === module) {
  process.exit(main());
}
