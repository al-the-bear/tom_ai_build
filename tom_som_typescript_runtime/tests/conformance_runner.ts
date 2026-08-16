#!/usr/bin/env node
/**
 * Shared-corpus conformance runner for the TypeScript generic runtime.
 *
 * Loads the language-agnostic conformance corpus produced from the Dart reference
 * (`tom_som_conformance/corpus`) and asserts the TypeScript port reproduces every
 * golden byte-for-byte and matches every behavioural case:
 *
 *   * model meta-data loads (root + class structure);
 *   * the generation stamp decodes and reaches the shared staleness verdict;
 *   * the SOM §4.2/§21 editability classification and its refusal messages;
 *   * `state.json` loads and re-serialises identically;
 *   * YAML encode == `expected.docspecs.yaml` (byte-for-byte, hierarchical v2
 *     via the SomMetaTree built from the model meta-data);
 *   * YAML decode → memory → encode is byte-stable + preserves the stamp and
 *     lands the same memory as `state.json`;
 *   * reflection resolution cases;
 *   * validation cases;
 *   * the imperative operations script;
 *   * the YRD7 generic editor script (typed values, enum domains, structure);
 *   * the SOM §14 DocSpecs tier (schema load + one violation case per rule);
 *   * the SOM §9 query tier: the portable pattern subset (match spans +
 *     compile rejections), the query match lists and their counts, the full
 *     projection walk, a scripted cursor session that survives a mid-iteration
 *     edit, and both node-creation tables (stateless gate + ordered script).
 *
 * Build with `tsc`, then run `node dist/tests/conformance_runner.js`. Exit code
 * 0 == all green.
 */

import * as fs from 'fs';
import * as path from 'path';

import {
  DEFAULT_MAX_SNAPSHOT_AGE_MS,
  DocSpecsSchema,
  DocSpecsValidator,
  DocSpecsViolationRule,
  MILLIS_PER_DAY,
  SomEditability,
  SomMetaTree,
  SomPatternError,
  SomTextPattern,
  SomVersionError,
  SpecCreationCode,
  SpecCreationError,
  SpecDocument,
  SpecDocumentMarkdown,
  SpecEditor,
  SpecModel,
  SpecNodeCreator,
  SpecNodeKind,
  SpecQuery,
  SpecQueryCursor,
  SpecQueryEngine,
  SpecQueryMatch,
  SpecStateFilter,
  buildSomMetaTree,
  checkAddNode,
  checkSomModelVersion,
  somEditabilityFor,
  SpecReflection,
  SpecSectionIdCollision,
  SpecSerializationOrder,
  encodeTwoLetterDate,
  generateListItemSectionId,
  validateDocument,
  yamlDecode,
  yamlEncode,
} from '../src/index';
import type { SpecNodeKindValue, SpecStateFilterValue } from '../src/index';

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
  _check('model.classCount', model.classes.size === 12, String(model.classes.size));
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
        'ratio',
        'score',
        'details',
        'items',
        'refs',
        'cards',
        'meta',
        'control',
        'notes',
        'registry',
      ]),
      String(names),
    );
  }
}

/**
 * The generation stamp: the five keys the exporter writes, and the staleness
 * verdict every runtime must reach from the same input.
 */
function testStamp(model: SpecModel): void {
  // The shared model fixture carries the stamp, minus `containerRoot` (it is a
  // single synthetic document with no container class).
  _check(
    'stamp.meta.generatedAt',
    model.generatedAt !== null &&
      Math.trunc(model.generatedAt.getTime() / 1000) === 1784534400,
    String(model.generatedAt),
  );
  _check('stamp.meta.metaSchemaVersion', model.metaSchemaVersion === 1);
  _check('stamp.meta.classCount', model.classCount === model.classes.size);
  _check('stamp.meta.rootCount', model.rootCount === model.roots.length);
  _check('stamp.meta.containerRoot', model.containerRoot === null);

  const table = _readJson('stamp_cases.json');
  _check(
    'stamp.defaultMaxAgeDays',
    table.defaultMaxAgeDays === DEFAULT_MAX_SNAPSHOT_AGE_MS / MILLIS_PER_DAY,
  );
  for (const kase of table.cases) {
    const name: string = kase.name;
    const loaded = SpecModel.fromJson(kase.model);
    const want = kase.expect;
    const gotEpoch =
      loaded.generatedAt === null
        ? null
        : Math.trunc(loaded.generatedAt.getTime() / 1000);
    _check(
      `stamp[${name}].generatedAt`,
      gotEpoch === want.generatedAtEpochSeconds,
      `${gotEpoch} != ${want.generatedAtEpochSeconds}`,
    );
    const decoded: Array<[string, unknown]> = [
      ['metaSchemaVersion', loaded.metaSchemaVersion],
      ['classCount', loaded.classCount],
      ['rootCount', loaded.rootCount],
      ['containerRoot', loaded.containerRoot],
    ];
    for (const [key, got] of decoded) {
      _check(`stamp[${name}].${key}`, got === want[key], `${got} != ${want[key]}`);
    }
    _check(
      `stamp[${name}].actualClassCount`,
      loaded.classes.size === want.actualClassCount,
    );
    _check(
      `stamp[${name}].actualRootCount`,
      loaded.roots.length === want.actualRootCount,
    );

    const wc = kase.check;
    const check = loaded.checkStamp({
      maxAgeMs: wc.maxAgeDays * MILLIS_PER_DAY,
      now: new Date(wc.nowEpochSeconds * 1000),
    });
    const ageSeconds =
      check.ageMs === null ? null : Math.trunc(check.ageMs / 1000);
    _check(
      `stamp[${name}].ageSeconds`,
      ageSeconds === wc.ageSeconds,
      `${ageSeconds} != ${wc.ageSeconds}`,
    );
    const verdicts: Array<[string, boolean]> = [
      ['isAged', check.isAged],
      ['classCountDisagrees', check.classCountDisagrees],
      ['rootCountDisagrees', check.rootCountDisagrees],
      ['countsDisagree', check.countsDisagree],
      ['isStale', check.isStale],
    ];
    for (const [key, got] of verdicts) {
      _check(`stamp[${name}].${key}`, got === wc[key], `${got} != ${wc[key]}`);
    }
    _check(
      `stamp[${name}].warnings`,
      _deepEqual(check.warnings, wc.warnings),
      `${JSON.stringify(check.warnings)} != ${JSON.stringify(wc.warnings)}`,
    );
  }
}

/**
 * The SOM §4.2/§21 version contract: the classification and the refusal.
 *
 * Both halves matter. `somEditabilityFor` is the single definition of the rules
 * and `checkSomModelVersion` throws from it, so a port that classifies
 * differently also throws differently — and a port that classifies right but
 * throws out of the *classifier* has broken the one promise §21 makes about it.
 *
 * The corpus spells each outcome as the Dart constant name; the TypeScript
 * string enum uses the same camelCase spelling, so the token indexes it.
 */
function testEditability(): void {
  for (const kase of _readJson('editability_cases.json').cases) {
    const name: string = kase.name;
    const want = (SomEditability as Record<string, SomEditability>)[
      kase.editability as string
    ];
    const got = somEditabilityFor(kase.generated, kase.documentVersion);
    _check(
      `editability[${name}].classification`,
      got === want,
      `${got} != ${kase.editability}`,
    );

    let raised: string | null = null;
    try {
      checkSomModelVersion(kase.generated, kase.documentVersion);
    } catch (e) {
      if (!(e instanceof SomVersionError)) throw e;
      raised = e.message;
    }
    _check(
      `editability[${name}].rejects`,
      (raised !== null) === kase.rejects,
      `raised=${JSON.stringify(raised)}`,
    );
    _check(
      `editability[${name}].message`,
      raised === kase.message,
      `${JSON.stringify(raised)} != ${JSON.stringify(kase.message)}`,
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
    headlines: parsed.headlines,
  });
  _check(
    'md.parse.storedId',
    reDoc.itemSectionId('DEMO/REF-LST-1') === 'REF-SPEC',
    String(reDoc.itemSectionId('DEMO/REF-LST-1')),
  );
  _check(
    'md.parse.headline',
    reDoc.headline('DEMO/REF-LST-1') === 'Reference to the Spec',
    String(reDoc.headline('DEMO/REF-LST-1')),
  );
  const actual = new SpecDocumentMarkdown(model, reDoc).exportRoot(model.roots[0]);
  _check('md.parse.reexport', actual === golden, _byteDiff('md.parse.reexport', actual, golden));
}

// Markdown/YAML convergence: parsing `expected.md` and applying it must
// reproduce `state.json` (the YAML-route memory) exactly, proving both formats
// converge on one in-memory document (SOM §8).
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
    headlines: parsed.headlines,
  });
  _check(
    'md.land.memory',
    _deepEqual(landed.toJson(), canonical),
    _jsonMismatch(landed.toJson(), canonical),
  );
}

// The SOM §11.7 rejection protocol: nothing is silently dropped. Each case
// asserts both halves together — the full `(line, reason, anchor, message)`
// report *and* the document that still landed. A port that drops an unplaceable
// block fails the first; one that reports it and abandons the rest of the parse
// fails the second.
function testMarkdownImportRejections(model: SpecModel): void {
  for (const c of _readJson('markdown_import_cases.json').cases) {
    const parsed = new SpecDocumentMarkdown(model, new SpecDocument()).parse(c.markdown);
    const got = parsed.rejections.map((r) => ({
      line: r.line,
      reason: r.reason,
      anchor: r.anchor === undefined ? null : r.anchor,
      message: r.message,
    }));
    _check(
      `md.reject[${c.name}].report`,
      _deepEqual(got, c.rejections),
      _jsonMismatch(got, c.rejections),
    );
    const landed = new SpecDocument();
    landed.loadJson({
      content: parsed.content,
      forms: parsed.forms,
      lists: parsed.lists,
      headlines: parsed.headlines,
    });
    _check(
      `md.reject[${c.name}].landed`,
      _deepEqual(landed.toJson(), c.document),
      _jsonMismatch(landed.toJson(), c.document),
    );
  }
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

// SOM §21 one-line export: SpecModel.rootByType + SpecDocument.toMarkdown.
// Mirrors the Dart reference groups in spec_model_test.dart /
// spec_document_markdown_test.dart.
function testOneLineExport(model: SpecModel): void {
  const twoRoot = SpecModel.fromJson({
    roots: [
      { type: 'Alpha', title: 'Alpha Doc', sectionId: 'A00' },
      { type: 'Beta', title: 'Beta Doc', sectionId: 'B00' },
    ],
    classes: {},
  });

  // rootByType: returns the matching root.
  _check('oneLineExport.rootByType.match', twoRoot.rootByType('Alpha').title === 'Alpha Doc');
  _check('oneLineExport.rootByType.sectionId', twoRoot.rootByType('Beta').sectionId === 'B00');
  // rootByType: throws naming missing + available types.
  _throwsWith('oneLineExport.rootByType.throws', () => twoRoot.rootByType('Gamma'), ['Gamma', 'Alpha', 'Beta']);

  // toMarkdown(rootType) == explicit codec output on the corpus fixture.
  const doc = _documentFromState(_readJson('state.json'));
  const rootType = model.roots[0].type;
  const oneLiner = doc.toMarkdown(model, rootType);
  const explicit = new SpecDocumentMarkdown(model, doc).exportRoot(model.rootByType(rootType));
  _check('oneLineExport.toMarkdown.explicit', oneLiner === explicit, _byteDiff('oneLineExport.toMarkdown.explicit', oneLiner, explicit));
  // toMarkdown() defaults to the single populated root (corpus has one root).
  _check('oneLineExport.toMarkdown.default', doc.toMarkdown(model) === oneLiner);
  // toMarkdown() throws on an empty document (no populated root).
  _throwsWith('oneLineExport.toMarkdown.none', () => new SpecDocument().toMarkdown(model), ['no populated root']);

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
  _throwsWith('oneLineExport.toMarkdown.ambiguous', () => ambiguousDoc.toMarkdown(ambiguousModel), ['Alpha', 'Beta']);
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
    } else if (kind === 'setHeadline') {
      doc.setHeadline(op.path, op.value);
    } else if (kind === 'headline') {
      const expect = op.expect === undefined ? null : op.expect;
      _check(`op[${n}].headline`, doc.headline(op.path) === expect, String(doc.headline(op.path)));
    } else {
      _check(`op[${n}].unknown`, false, kind);
    }
  }
}

/** Asserts `fn` fails — the corpus's `*Throws` ops only require *that* it does. */
function _expectThrows(name: string, fn: () => unknown): void {
  try {
    fn();
  } catch {
    _check(name, true);
    return;
  }
  _check(name, false, 'expected an error, none thrown');
}

/**
 * YRD7: the generic, meta-validated modification API (SpecEditor) — typed
 * value/form-field round-trips through the shared boundary helpers, enum domain
 * validation, and structural create/clear ops.
 *
 * Replayed against the corpus model, so every language's generic editor runs
 * the identical script. The script is stateful and ordered: one document, start
 * to finish.
 */
function testEditor(model: SpecModel): void {
  const doc = new SpecDocument();
  const ed = SpecEditor.forModel(doc, model);
  const script = _readJson('editor_cases.json');
  for (let n = 0; n < script.length; n++) {
    const s = script[n];
    const kind = s.op;
    if (kind === 'setValue') {
      ed.setValue(s.path, s.value);
    } else if (kind === 'value') {
      const got = ed.value(s.path);
      _check(`editor[${n}].value ${s.path}`, got === s.expect, String(got));
    } else if (kind === 'setValueThrows') {
      _expectThrows(`editor[${n}].setValueThrows ${s.path}`, () =>
        ed.setValue(s.path, s.value),
      );
    } else if (kind === 'valueThrows') {
      _expectThrows(`editor[${n}].valueThrows ${s.path}`, () =>
        ed.value(s.path),
      );
    } else if (kind === 'setContent') {
      // Raw store write: bypasses the typed boundary on purpose.
      doc.setContent(s.path, s.value);
    } else if (kind === 'rawContent') {
      const got = doc.content(s.path);
      _check(`editor[${n}].rawContent ${s.path}`, got === s.expect, String(got));
    } else if (kind === 'setFormValue') {
      ed.setFormValue(s.path, s.field, s.value);
    } else if (kind === 'formValue') {
      const got = ed.formValue(s.path, s.field);
      _check(
        `editor[${n}].formValue ${s.path}#${s.field}`,
        got === s.expect,
        String(got),
      );
    } else if (kind === 'setFormValueThrows') {
      _expectThrows(
        `editor[${n}].setFormValueThrows ${s.path}#${s.field}`,
        () => ed.setFormValue(s.path, s.field, s.value),
      );
    } else if (kind === 'formValueThrows') {
      _expectThrows(`editor[${n}].formValueThrows ${s.path}#${s.field}`, () =>
        ed.formValue(s.path, s.field),
      );
    } else if (kind === 'rawFormField') {
      const got = doc.formField(s.path, s.field);
      _check(
        `editor[${n}].rawFormField ${s.path}#${s.field}`,
        got === s.expect,
        String(got),
      );
    } else if (kind === 'formFieldNames') {
      const got = ed.formFields(s.path).map((f) => f.name);
      _check(
        `editor[${n}].formFieldNames ${s.path}`,
        _deepEqual(got, s.expect),
        String(got),
      );
    } else if (kind === 'formFieldNamesThrows') {
      _expectThrows(`editor[${n}].formFieldNamesThrows ${s.path}`, () =>
        ed.formFields(s.path),
      );
    } else if (kind === 'setHeadline') {
      ed.setHeadline(s.path, s.value);
    } else if (kind === 'headline') {
      const expect = s.expect === undefined ? null : s.expect;
      const got = ed.headline(s.path);
      _check(`editor[${n}].headline ${s.path}`, got === expect, String(got));
    } else if (kind === 'headlineThrows') {
      _expectThrows(`editor[${n}].headlineThrows ${s.path}`, () =>
        ed.headline(s.path),
      );
    } else if (kind === 'itemSectionId') {
      const got = doc.itemSectionId(s.itemPath);
      _check(
        `editor[${n}].itemSectionId ${s.itemPath}`,
        got === s.expect,
        String(got),
      );
    } else if (kind === 'addListItem') {
      const p = ed.addListItem(s.listPath, null, s.month, s.day);
      _check(`editor[${n}].addListItem ${s.listPath}`, p === s.expectPath, p);
      if (s.expectId !== undefined) {
        const gotId = doc.itemSectionId(p);
        _check(
          `editor[${n}].addListItem id ${s.listPath}`,
          gotId === s.expectId,
          String(gotId),
        );
      }
    } else if (kind === 'addListItemThrows') {
      _expectThrows(`editor[${n}].addListItemThrows ${s.listPath}`, () =>
        ed.addListItem(s.listPath, null, s.month, s.day),
      );
    } else if (kind === 'removeListItem') {
      _check(
        `editor[${n}].removeListItem ${s.itemPath}`,
        ed.removeListItem(s.itemPath) === s.expect,
      );
    } else if (kind === 'clearSection') {
      ed.clearSection(s.path);
    } else if (kind === 'clearSectionThrows') {
      _expectThrows(`editor[${n}].clearSectionThrows ${s.path}`, () =>
        ed.clearSection(s.path),
      );
    } else if (kind === 'hasValuesUnder') {
      _check(
        `editor[${n}].hasValuesUnder ${s.prefix}`,
        doc.hasValuesUnder(s.prefix) === s.expect,
      );
    } else {
      _check(`editor[${n}].unknown`, false, kind);
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

/**
 * The SOM §14 DocSpecs tier: one shared schema, one case per rule.
 *
 * The corpus carries the rule/sectionId/line triples the Dart reference
 * produces; matching them is what proves this port implements each rule at
 * all, rather than merely declaring its name.
 */
function testDocSpecs(): void {
  const schema = DocSpecsSchema.fromYamlText(_read('docspecs_schema.yaml'));
  _check('docspecs.schemaWarnings', schema.warnings.length === 0,
    String(schema.warnings));
  _check('docspecs.rootSectionId', schema.rootSectionId === 'D00');
  const validator = new DocSpecsValidator(schema);
  const covered = new Set<string>();
  for (const c of _readJson('docspecs_cases.json')) {
    const got = validator
      .validateMarkdown(c.markdown)
      .map((v) => [v.rule, v.sectionId, v.line]);
    const want = c.violations.map(
      (v: any) => [v.rule, v.sectionId, v.line],
    );
    _check(`docspecs[${c.name}]`, _deepEqual(got, want),
      `${JSON.stringify(got)} != ${JSON.stringify(want)}`);
    for (const v of c.violations) {
      covered.add(v.rule);
    }
  }
  const uncovered = Object.values(DocSpecsViolationRule)
    .filter((r) => !covered.has(r))
    .sort();
  _check('docspecs.ruleCoverage', uncovered.length === 0,
    `uncovered: ${uncovered}`);
}

// --- spec_text_pattern / spec_query / spec_node_creation (SOM §9) -----------

/**
 * The §9 fixture document, built imperatively — the port of the Dart
 * reference's `_buildDocument()`.
 *
 * It is **not** loaded from `state.json`, and that is the point: `toJson`
 * sorts every store, so a reloaded document would hold `DEMO/DET` in
 * alphabetical order and a port that iterated the store would look right for
 * the wrong reason. Form fields are emitted in **model-declaration** order
 * (SOM §9, "Form-field order"), so the populate order below is deliberately
 * neither declaration order nor alphabetical — a port that follows its store
 * picks a different snippet and fails `projection_cases.json`.
 * {@link testQueryFixtureMatchesState} pins that the rebuild is otherwise the
 * committed state.
 */
function _buildFixtureDocument(): SpecDocument {
  const d = new SpecDocument();
  d.setContent('DEMO/TTL', 'Hello');
  d.setContent('DEMO/SUM', 'Line one\nLine two\n\nLine four');
  d.setContent('DEMO/PRI', 'high');
  d.setContent('DEMO/CNT', '3');
  // Scrambled on purpose — see the doc comment. Do not "tidy" into order.
  d.setFormField('DEMO/DET', 'priority', 'high');
  d.setFormField('DEMO/DET', 'weight', '2.5');
  d.setFormField('DEMO/DET', 'owner', 'Bob');
  d.setFormField('DEMO/DET', 'active', 'true');
  d.setFormField('DEMO/DET', 'estimate', '8');
  d.setFormField('DEMO/DET', 'contact', 'bob@example.com');
  const i1 = d.addListItem('DEMO/items');
  d.setContent(`${i1}/label`, 'First');
  d.setContent(`${i1}/STS`, 'open');
  const i2 = d.addListItem('DEMO/items');
  d.setContent(`${i2}/label`, 'Second line A\nwith ```triple``` ticks');
  d.setContent(`${i2}/STS`, 'done');
  for (const ref of ['spec §1.2', 'ADR7']) {
    const r = d.addListItem('DEMO/REF-LST');
    d.setContent(r, ref);
  }
  d.setHeadline('DEMO/SUM', 'Executive Summary');
  d.setHeadline('DEMO/DET', 'Details & Contacts');
  d.setHeadline('DEMO/items', 'Work Items');
  d.setItemSectionId('DEMO/REF-LST-1', 'REF-SPEC');
  d.setHeadline('DEMO/REF-LST-1', 'Reference to the Spec');
  const c1 = d.addListItem('DEMO/CARD-LST');
  d.setItemSectionId(c1, 'CARD-ALPHA');
  d.setHeadline(c1, 'Alpha Card');
  d.setFormField(`${c1}/content`, 'note', 'first card');
  const c2 = d.addListItem('DEMO/CARD-LST');
  d.setFormField(`${c2}/content`, 'note', 'second card');
  d.setContent('DEMO/META/OWNR', 'alice');
  for (const tag of ['on', 'no', '1:30', 'plain']) {
    const t = d.addListItem('DEMO/META/tags');
    d.setContent(t, tag);
  }
  d.setContent('DEMO/control/CTRL-SUM', 'Controlled summary');
  d.setContent('DEMO/control/owner', 'ctrl-owner');
  // The `section`-kind member (`Notes`, class id `NOTE`, id-less field): a
  // section collapses into its target class exactly as a complex member does,
  // and keys on the target class's id when the field carries none.
  d.setContent('DEMO/notes/NOTE-BDY', 'Section-kind body');
  return d;
}

/**
 * The hand-built §9 fixture is the committed `state.json` — so the only thing
 * the imperative rebuild adds over `loadJson` is the form-field ordering it
 * exists to preserve.
 */
function testQueryFixtureMatchesState(): void {
  const got = _buildFixtureDocument().toJson();
  const want = _readJson('state.json');
  _check('query.fixture==state', _deepEqual(got, want), _jsonMismatch(got, want));
}

/**
 * The portable pattern subset: every committed match case reproduces its exact
 * spans, and every committed rejection is rejected at compile time.
 *
 * The spans are UTF-16 code-unit offsets, which is why this port may not reach
 * for `RegExp`: engines disagree (leftmost-longest vs backtracking, and case
 * folding), so the matcher is hand-rolled and the corpus pins the result.
 */
function testPatterns(): void {
  const cases = _readJson('pattern_cases.json');
  for (let n = 0; n < cases.length; n++) {
    const c = cases[n];
    const source: string = c.pattern;
    const ci: boolean = c.caseInsensitive === true;
    if (c.error === true) {
      let threw = false;
      try {
        SomTextPattern.compile(source);
      } catch (e) {
        threw = e instanceof SomPatternError;
      }
      _check(`pattern[${n}].rejects`, threw, `pattern "${source}" must be rejected`);
      continue;
    }
    const p = c.regex === true
      ? SomTextPattern.compile(source, ci)
      : SomTextPattern.literal(source, ci);
    const got = p.allMatches(c.text).map((s) => [s.start, s.end]);
    _check(
      `pattern[${n}].spans`,
      _deepEqual(got, c.spans),
      `pattern "${source}" over ${JSON.stringify(c.text)}: ${_jsonMismatch(got, c.spans)}`,
    );
  }

  // A table of matches alone would let a port accept everything; a table of
  // rejections alone would let one reject everything.
  _check(
    'pattern.table.hasRejections',
    cases.some((c: any) => c.error === true),
  );
  _check(
    'pattern.table.hasMatches',
    cases.some((c: any) => c.error !== true),
  );
}

/**
 * Rebuilds a {@link SpecQuery} from its corpus wire form.
 *
 * Every port needs this same decode, so its shape *is* part of the contract: an
 * absent key means "dimension unset", never a default that happens to match.
 * Kept beside the replay tests rather than in `src/` because it belongs to the
 * corpus format, not to the runtime API.
 */
function _queryFromJson(j: any): SpecQuery {
  const kindNames: string[] | null = j.kinds != null ? j.kinds : null;
  return new SpecQuery({
    text: j.text != null ? j.text : null,
    regex: j.regex === true,
    caseInsensitive: j.caseInsensitive === true,
    kinds:
      kindNames === null
        ? null
        : new Set(kindNames.map((k) => _nodeKindByName(k))),
    className: j.className != null ? j.className : null,
    sectionIdExact: j.sectionIdExact != null ? j.sectionIdExact : null,
    sectionIdPrefix: j.sectionIdPrefix != null ? j.sectionIdPrefix : null,
    pathGlob: j.pathGlob != null ? j.pathGlob : null,
    mapsTo: j.mapsTo != null ? j.mapsTo : null,
    detailedIn: j.detailedIn != null ? j.detailedIn : null,
    state: j.state != null ? _stateFilterByName(j.state) : null,
  });
}

/** The {@link SpecNodeKind} constant named `name`; throws for an unknown name
 * so a corpus typo fails loudly instead of silently widening the query. */
function _nodeKindByName(name: string): SpecNodeKindValue {
  for (const v of Object.values(SpecNodeKind)) {
    if (v === name) {
      return v;
    }
  }
  throw new Error(`unknown node kind '${name}' in query_cases.json`);
}

/** The {@link SpecStateFilter} constant named `name` (same loud-failure rule). */
function _stateFilterByName(name: string): SpecStateFilterValue {
  for (const v of Object.values(SpecStateFilter)) {
    if (v === name) {
      return v;
    }
  }
  throw new Error(`unknown state filter '${name}' in query_cases.json`);
}

/** The corpus wire form of one {@link SpecQueryMatch}. */
function _matchToJson(m: SpecQueryMatch): any {
  return {
    path: m.path,
    kind: m.kind,
    classId: m.classId,
    headline: m.headline,
    snippet: m.snippet,
    spans: m.matchSpans.map((s) => [s.start, s.end]),
  };
}

/** Every committed query reproduces its match list, in order. */
function testQuery(model: SpecModel, doc: SpecDocument): void {
  const engine = new SpecQueryEngine(model, doc);
  const cases = _readJson('query_cases.json');
  for (const c of cases) {
    const cursor = engine.query(_queryFromJson(c.query));
    const got = cursor.toList().map(_matchToJson);
    _check(
      `query[${c.name}]`,
      _deepEqual(got, c.matches),
      _jsonMismatch(got, c.matches),
    );
  }
}

/**
 * The same fact from the other side: a port that implements `toList` by
 * draining but `count` by returning the candidate count passes
 * {@link testQuery} and fails this one — so it is a separate pass over the
 * table with a fresh cursor per case.
 */
function testQueryCount(model: SpecModel, doc: SpecDocument): void {
  const engine = new SpecQueryEngine(model, doc);
  for (const c of _readJson('query_cases.json')) {
    const cursor = engine.query(_queryFromJson(c.query));
    _check(
      `query.count[${c.name}]`,
      cursor.count === c.matches.length,
      `${cursor.count} != ${c.matches.length}`,
    );
  }
}

/** The full `projectNodes()` structural walk, in document order. */
function testProjection(model: SpecModel, doc: SpecDocument): void {
  const engine = new SpecQueryEngine(model, doc);
  const got = Array.from(engine.projectNodes()).map((p) => ({
    path: p.path,
    kind: p.kind,
    classId: p.classId,
    sectionId: p.sectionId,
    mapsTo: p.mapsTo,
    detailedIn: p.detailedIn,
    headline: p.headline,
    searchableStrings: p.searchableStrings,
    hasValue: p.hasValue,
  }));
  const want = _readJson('projection_cases.json');
  _check('projection.walk', _deepEqual(got, want), _jsonMismatch(got, want));
}

/**
 * A scripted cursor session over its own document.
 *
 * The `removeListItem` step mutates the document *between* two cursor reads:
 * the cursor must skip the match whose list item no longer exists rather than
 * hand back a stale path, which is what makes it lazy-but-safe.
 */
function testCursorScript(model: SpecModel): void {
  const steps = _readJson('cursor_cases.json');
  const d = _buildFixtureDocument();
  const engine = new SpecQueryEngine(model, d);
  let cursor: SpecQueryCursor | null = null;
  for (let n = 0; n < steps.length; n++) {
    const s = steps[n];
    const kind = s.op;
    if (kind === 'open') {
      cursor = engine.query(_queryFromJson(s.query));
    } else if (kind === 'count') {
      _check(`cursor[${n}].count`, cursor!.count === s.expect, String(cursor!.count));
    } else if (kind === 'take') {
      const got = cursor!.take(s.n).map((m) => m.path);
      _check(`cursor[${n}].take`, _deepEqual(got, s.expect), _jsonMismatch(got, s.expect));
    } else if (kind === 'next') {
      const m = cursor!.next();
      const got = m !== null ? m.path : null;
      _check(`cursor[${n}].next`, got === s.expect, `${got} != ${s.expect}`);
    } else if (kind === 'toList') {
      const got = cursor!.toList().map((m) => m.path);
      _check(`cursor[${n}].toList`, _deepEqual(got, s.expect), _jsonMismatch(got, s.expect));
    } else if (kind === 'removeListItem') {
      d.removeListItem(s.itemPath);
    } else {
      _check(`cursor[${n}].unknown`, false, kind);
    }
  }
}

/**
 * The stateless `checkAddNode` gate: every probe runs against a **freshly
 * built** document, so the table is order-independent.
 *
 * The corpus deliberately carries no message text — the code is the contract,
 * the message is prose — so a rejection is checked by code plus the parent/child
 * it names.
 */
function testNodeCreationCases(model: SpecModel): void {
  const cases = _readJson('node_creation_cases.json');
  const covered = new Set<string>();
  for (const c of cases) {
    const d = _buildFixtureDocument();
    const err = checkAddNode(
      model,
      d,
      c.parentPath,
      c.childSegment,
      c.itemId !== undefined ? c.itemId : null,
    );
    _check(
      `nodeCreation[${c.name}].accepted`,
      (err === null) === c.accepted,
      err !== null ? err.toString() : 'accepted',
    );
    if (err !== null) {
      covered.add(err.code);
      _check(`nodeCreation[${c.name}].code`, err.code === c.code, err.code);
      _check(`nodeCreation[${c.name}].parentPath`, err.parentPath === c.parentPath);
      _check(`nodeCreation[${c.name}].childSegment`, err.childSegment === c.childSegment);
    }
  }
  const uncovered = Object.values(SpecCreationCode)
    .filter((code) => !covered.has(code))
    .sort();
  _check('nodeCreation.codeCoverage', uncovered.length === 0, `uncovered: ${uncovered}`);
}

/**
 * The sequential creation script against one document: each `add` returns the
 * next item path and lands the expected section id, each `addThrows` leaves the
 * document untouched, and the final `toJson()` pins the cumulative result.
 */
function testNodeCreationScript(model: SpecModel): void {
  const steps = _readJson('node_creation_script.json');
  const d = _buildFixtureDocument();
  const creator = new SpecNodeCreator(model, d);
  for (let n = 0; n < steps.length; n++) {
    const s = steps[n];
    const kind = s.op;
    const itemId = s.itemId !== undefined ? s.itemId : null;
    if (kind === 'add') {
      // Dart dates the add with `DateTime(2026, month, day)`; this port takes
      // the month/day pair directly (see SpecNodeCreator.add), so only the
      // fixed year 2026 is dropped — it never reaches the two-letter encoding.
      const p = creator.add(s.parentPath, s.childSegment, itemId, s.month, s.day);
      _check(`nodeScript[${n}].path`, p === s.expectPath, `${p} != ${s.expectPath}`);
      const gotId = d.itemSectionId(p);
      _check(`nodeScript[${n}].id`, gotId === s.expectId, `${gotId} != ${s.expectId}`);
    } else if (kind === 'addThrows') {
      let code: string | null = null;
      try {
        creator.add(s.parentPath, s.childSegment, itemId, 3, 4);
      } catch (e) {
        code = e instanceof SpecCreationError ? e.code : `<${e}>`;
      }
      _check(`nodeScript[${n}].throws`, code === s.expectCode, `${code} != ${s.expectCode}`);
    } else if (kind === 'finalState') {
      const got = d.toJson();
      _check(`nodeScript[${n}].finalState`, _deepEqual(got, s.expect), _jsonMismatch(got, s.expect));
    } else {
      _check(`nodeScript[${n}].unknown`, false, kind);
    }
  }
}

export function main(): number {
  if (!fs.existsSync(_CORPUS) || !fs.statSync(_CORPUS).isDirectory()) {
    process.stderr.write(`corpus not found at ${_CORPUS}\n`);
    return 2;
  }
  const model = _loadModel();
  const tree = buildSomMetaTree(model);
  testModelMeta(model);
  testStamp(model);
  testEditability();
  testStateRoundTrip();
  testYamlEncode(tree);
  testYamlDecodeRoundTrip(tree);
  testMarkdownExport(model);
  testMarkdownRoundTrip(model);
  testMarkdownMemoryLanding(model);
  testMarkdownImportRejections(model);
  testOneLineExport(model);
  testReflection(model);
  testValidation(model);
  testOperations();
  testEditor(model);
  testSectionId();
  testSerializationOrder();
  testDocSpecs();
  const queryDoc = _buildFixtureDocument();
  testQueryFixtureMatchesState();
  testPatterns();
  testQuery(model, queryDoc);
  testQueryCount(model, queryDoc);
  testProjection(model, queryDoc);
  testCursorScript(model);
  testNodeCreationCases(model);
  testNodeCreationScript(model);

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
