#!/usr/bin/env node
'use strict';

/**
 * Shared-corpus conformance runner for the JavaScript generic runtime.
 *
 * Loads the language-agnostic conformance corpus produced from the Dart reference
 * (`tom_som_conformance/corpus`) and asserts the JavaScript port reproduces every
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
 *   * the generic editor (YRD7) script;
 *   * the SOM §9 query tier — the portable text-pattern subset, the query /
 *     projection tables, the scripted cursor session, and the constrained
 *     node-creation gate (probe table + stateful script);
 *   * the SOM §14 DocSpecs tier (schema load + one violation case per rule).
 *
 * Run with: `node tests/conformance_runner.js`. Exit code 0 == all green.
 */

const fs = require('fs');
const path = require('path');

const _HERE = __dirname;
const _PKG_ROOT = path.dirname(_HERE); // tom_som_javascript_runtime
const _CORPUS = path.normalize(
  path.join(_PKG_ROOT, '..', 'tom_som_conformance', 'corpus'),
);

const {
  DEFAULT_MAX_SNAPSHOT_AGE_MS,
  DocSpecsSchema,
  DocSpecsValidator,
  DocSpecsViolationRule,
  SomEditability,
  SomPatternError,
  SomTextPattern,
  SomVersionError,
  SpecCreationError,
  SpecDocument,
  SpecDocumentMarkdown,
  SpecEditor,
  SpecModel,
  SpecNodeCreator,
  SpecNodeKind,
  SpecQuery,
  SpecQueryEngine,
  buildSomMetaTree,
  checkAddNode,
  checkSomModelVersion,
  somEditabilityFor,
  SpecReflection,
  SpecSectionIdCollision,
  SpecSerializationOrder,
  SpecStateFilter,
  encodeTwoLetterDate,
  generateListItemSectionId,
  validateDocument,
  yamlDecode,
  yamlEncode,
} = require(path.join(_PKG_ROOT, 'tom_som_runtime', 'index.js'));

const _MODEL_VERSION = '1.0';

let _passed = 0;
const _failed = [];

function _check(name, condition, detail = '') {
  if (condition) {
    _passed += 1;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

function _read(name) {
  return fs.readFileSync(path.join(_CORPUS, name), 'utf8');
}

function _readJson(name) {
  return JSON.parse(_read(name));
}

function _byteDiff(label, actual, expected) {
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

function _deepEqual(a, b) {
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

function _jsonMismatch(actual, expected) {
  if (_deepEqual(actual, expected)) {
    return '';
  }
  return `got ${JSON.stringify(actual)} want ${JSON.stringify(expected)}`;
}

function _loadModel() {
  return SpecModel.fromJson(_readJson('model.meta.json'));
}

function _documentFromState(state) {
  const doc = new SpecDocument();
  doc.loadJson(state);
  return doc;
}

function testModelMeta(model) {
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
      _deepEqual(names, ['title', 'summary', 'priority', 'count', 'ratio', 'score', 'details', 'items', 'refs', 'cards', 'meta', 'control', 'notes', 'registry']),
      String(names),
    );
  }
}

/**
 * The generation stamp: the five keys the exporter writes, and the staleness
 * verdict every runtime must reach from the same input.
 *
 * @param {SpecModel} model
 */
function testStamp(model) {
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
    table.defaultMaxAgeDays === DEFAULT_MAX_SNAPSHOT_AGE_MS / 86400000,
  );
  for (const kase of table.cases) {
    const name = kase.name;
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
    for (const [key, got] of [
      ['metaSchemaVersion', loaded.metaSchemaVersion],
      ['classCount', loaded.classCount],
      ['rootCount', loaded.rootCount],
      ['containerRoot', loaded.containerRoot],
    ]) {
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
      maxAgeMs: wc.maxAgeDays * 86400000,
      now: new Date(wc.nowEpochSeconds * 1000),
    });
    const ageSeconds = check.ageMs === null ? null : Math.trunc(check.ageMs / 1000);
    _check(
      `stamp[${name}].ageSeconds`,
      ageSeconds === wc.ageSeconds,
      `${ageSeconds} != ${wc.ageSeconds}`,
    );
    for (const [key, got] of [
      ['isAged', check.isAged],
      ['classCountDisagrees', check.classCountDisagrees],
      ['rootCountDisagrees', check.rootCountDisagrees],
      ['countsDisagree', check.countsDisagree],
      ['isStale', check.isStale],
    ]) {
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
 * The corpus spells each outcome as the Dart constant name; JavaScript's
 * `SomEditability` values happen to use the same camelCase spelling, so the
 * token is compared directly.
 */
function testEditability() {
  for (const kase of _readJson('editability_cases.json').cases) {
    const name = kase.name;
    const got = somEditabilityFor(kase.generated, kase.documentVersion);
    _check(
      `editability[${name}].classification`,
      got === SomEditability[kase.editability],
      `${got} != ${kase.editability}`,
    );

    let raised = null;
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

function testStateRoundTrip() {
  const state = _readJson('state.json');
  const doc = _documentFromState(state);
  _check('state.toJson', _deepEqual(doc.toJson(), state), _jsonMismatch(doc.toJson(), state));
}

function testYamlEncode(tree) {
  const doc = _documentFromState(_readJson('state.json'));
  const expected = _read('expected.docspecs.yaml');
  const actual = yamlEncode(doc, tree, _MODEL_VERSION);
  _check('yaml.encode', actual === expected, _byteDiff('yaml.encode', actual, expected));
}

function testYamlDecodeRoundTrip(tree) {
  const expected = _read('expected.docspecs.yaml');
  const contents = yamlDecode(expected, tree);
  _check('yaml.decode.stamp', contents.modelVersion === _MODEL_VERSION, String(contents.modelVersion));
  _check(
    'yaml.decode.memory',
    _deepEqual(contents.document.toJson(), _readJson('state.json')),
    _jsonMismatch(contents.document.toJson(), _readJson('state.json')),
  );
  const actual = yamlEncode(contents.document, tree, contents.modelVersion || _MODEL_VERSION);
  _check('yaml.decode.reencode', actual === expected, _byteDiff('yaml.decode.reencode', actual, expected));
}

function testMarkdownExport(model) {
  const doc = _documentFromState(_readJson('state.json'));
  const expected = _read('expected.md');
  const actual = new SpecDocumentMarkdown(model, doc).exportRoot(model.roots[0]);
  _check('md.export', actual === expected, _byteDiff('md.export', actual, expected));
}

function testMarkdownRoundTrip(model) {
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
function testMarkdownMemoryLanding(model) {
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
function testMarkdownImportRejections(model) {
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

function testReflection(model) {
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
    _check(`reflect[${p}].target`, target === c.targetClass, `${target} != ${c.targetClass}`);
    _check(`reflect[${p}].leaf`, res.isValueLeaf === c.isValueLeaf, `${res.isValueLeaf} != ${c.isValueLeaf}`);
  }
}

function testValidation(model) {
  for (const c of _readJson('validation_cases.json')) {
    const name = c.name;
    const doc = _documentFromState(c.state);
    const errors = validateDocument(model, doc);
    const got = errors.map((e) => [e.path, e.code]);
    const want = c.errors.map((e) => [e.path, e.code]);
    _check(`validate[${name}]`, _deepEqual(got, want), `${JSON.stringify(got)} != ${JSON.stringify(want)}`);
  }
}

/** Whether `fn` throws at all (the corpus's `*Throws` ops only require that). */
function _throws(fn) {
  try {
    fn();
    return false;
  } catch {
    return true;
  }
}

/**
 * YRD7: the generic, meta-validated modification API (SpecEditor) — typed
 * value/form-field round-trips through the shared boundary helpers, enum domain
 * validation, and structural create/clear ops.
 *
 * Executed against the corpus model, so every language's generic editor replays
 * the identical script. The script is stateful and ordered: one document, start
 * to finish.
 *
 * @param {SpecModel} model
 */
function testEditor(model) {
  const doc = new SpecDocument();
  const ed = SpecEditor.forModel(doc, model);
  const cases = _readJson('editor_cases.json');
  for (let n = 0; n < cases.length; n++) {
    const s = cases[n];
    const kind = s.op;
    if (kind === 'setValue') {
      ed.setValue(s.path, s.value);
    } else if (kind === 'value') {
      const got = ed.value(s.path);
      _check(`editor[${n}].value ${s.path}`, got === s.expect, String(got));
    } else if (kind === 'valueThrows') {
      _check(
        `editor[${n}].valueThrows ${s.path}`,
        _throws(() => ed.value(s.path)),
        '',
      );
    } else if (kind === 'setValueThrows') {
      _check(
        `editor[${n}].setValueThrows ${s.path}`,
        _throws(() => ed.setValue(s.path, s.value)),
        '',
      );
    } else if (kind === 'setContent') {
      // raw store write (bypasses the typed boundary)
      doc.setContent(s.path, s.value);
    } else if (kind === 'rawContent') {
      const got = doc.content(s.path);
      _check(`editor[${n}].rawContent ${s.path}`, got === s.expect, String(got));
    } else if (kind === 'setFormValue') {
      ed.setFormValue(s.path, s.field, s.value);
    } else if (kind === 'formValue') {
      const got = ed.formValue(s.path, s.field);
      _check(`editor[${n}].formValue ${s.path}#${s.field}`, got === s.expect, String(got));
    } else if (kind === 'formValueThrows') {
      _check(
        `editor[${n}].formValueThrows ${s.path}#${s.field}`,
        _throws(() => ed.formValue(s.path, s.field)),
        '',
      );
    } else if (kind === 'setFormValueThrows') {
      _check(
        `editor[${n}].setFormValueThrows ${s.path}#${s.field}`,
        _throws(() => ed.setFormValue(s.path, s.field, s.value)),
        '',
      );
    } else if (kind === 'rawFormField') {
      const got = doc.formField(s.path, s.field);
      _check(`editor[${n}].rawFormField ${s.path}#${s.field}`, got === s.expect, String(got));
    } else if (kind === 'formFieldNames') {
      const got = ed.formFields(s.path).map((f) => f.name);
      _check(`editor[${n}].formFieldNames ${s.path}`, _deepEqual(got, s.expect), String(got));
    } else if (kind === 'formFieldNamesThrows') {
      _check(
        `editor[${n}].formFieldNamesThrows ${s.path}`,
        _throws(() => ed.formFields(s.path)),
        '',
      );
    } else if (kind === 'setHeadline') {
      ed.setHeadline(s.path, s.value);
    } else if (kind === 'headline') {
      const expect = s.expect === undefined ? null : s.expect;
      const got = ed.headline(s.path);
      _check(`editor[${n}].headline ${s.path}`, got === expect, String(got));
    } else if (kind === 'headlineThrows') {
      _check(
        `editor[${n}].headlineThrows ${s.path}`,
        _throws(() => ed.headline(s.path)),
        '',
      );
    } else if (kind === 'itemSectionId') {
      const got = doc.itemSectionId(s.itemPath);
      _check(`editor[${n}].itemSectionId ${s.itemPath}`, got === s.expect, String(got));
    } else if (kind === 'addListItem') {
      const p = ed.addListItem(s.listPath, { month: s.month, day: s.day });
      _check(`editor[${n}].addListItem ${s.listPath}`, p === s.expectPath, p);
      if (s.expectId !== undefined) {
        const got = doc.itemSectionId(p);
        _check(`editor[${n}].addListItem id ${s.listPath}`, got === s.expectId, String(got));
      }
    } else if (kind === 'addListItemThrows') {
      _check(
        `editor[${n}].addListItemThrows ${s.listPath}`,
        _throws(() => ed.addListItem(s.listPath, { month: s.month, day: s.day })),
        '',
      );
    } else if (kind === 'removeListItem') {
      _check(
        `editor[${n}].removeListItem ${s.itemPath}`,
        ed.removeListItem(s.itemPath) === s.expect,
      );
    } else if (kind === 'clearSection') {
      ed.clearSection(s.path);
    } else if (kind === 'clearSectionThrows') {
      _check(
        `editor[${n}].clearSectionThrows ${s.path}`,
        _throws(() => ed.clearSection(s.path)),
        '',
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

function testOperations() {
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
      _check(`op[${n}].listItems`, _deepEqual(doc.listItems(op.listPath), op.expect), String(doc.listItems(op.listPath)));
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

/** Whether `fn` throws {@link SpecSectionIdCollision} (criterion-5 guard). */
function _raisesCollision(fn) {
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
function testSectionId() {
  const cases = _readJson('section_id_cases.json');

  // Criterion 4: the two-letter day code.
  for (const c of cases.twoLetterDate) {
    const got = encodeTwoLetterDate(c.month, c.day);
    _check(`sectionId.twoLetterDate[${c.month}/${c.day}]`, got === c.expect, `${got} != ${c.expect}`);
  }

  // Criteria 3 & 6: generated id = prefix + day + (max-for-day + 1).
  for (const c of cases.generate) {
    const got = generateListItemSectionId(c.pattern, c.month, c.day, c.existing);
    _check(`sectionId.generate[${c.pattern}]`, got === c.expect, `${got} != ${c.expect}`);
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
        _check(`sectionId.op[${i}].addGen.id`, genId === s.expectId, `${genId} != ${s.expectId}`);
        const p = doc.addListItem(s.listPath, genId);
        _check(`sectionId.op[${i}].addGen.path`, p === s.expectPath, `${p} != ${s.expectPath}`);
        break;
      }
      case 'sectionIds': {
        const got = doc.listItemSectionIds(s.listPath);
        _check(`sectionId.op[${i}].sectionIds`, _deepEqual(got, s.expect), `${got} != ${s.expect}`);
        break;
      }
      case 'removeListItem': {
        const got = doc.removeListItem(s.itemPath);
        _check(`sectionId.op[${i}].removeListItem`, got === Boolean(s.expect), String(got));
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
function testSerializationOrder() {
  const c = _readJson('serialization_order_cases.json');
  const orderModel = SpecModel.fromJson(c.model);
  const order = new SpecSerializationOrder(orderModel);

  const gotPaths = order.orderPaths(c.contentPaths);
  _check('serialOrder.orderPaths', _deepEqual(gotPaths, c.expectedOrder), `${gotPaths} != ${c.expectedOrder}`);

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
function testDocSpecs() {
  const schema = DocSpecsSchema.fromYamlText(_read('docspecs_schema.yaml'));
  _check('docspecs.schemaWarnings', schema.warnings.length === 0,
    String(schema.warnings));
  _check('docspecs.rootSectionId', schema.rootSectionId === 'D00');
  const validator = new DocSpecsValidator(schema);
  const covered = new Set();
  for (const c of _readJson('docspecs_cases.json')) {
    const got = validator
      .validateMarkdown(c.markdown)
      .map((v) => [v.rule, v.sectionId, v.line]);
    const want = c.violations.map((v) => [v.rule, v.sectionId, v.line]);
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

// ---------------------------------------------------------------------------
// SOM §9: spec_text_pattern / spec_query / spec_node_creation
// ---------------------------------------------------------------------------

/**
 * The corpus fixture document, built the way the Dart reference's
 * `_buildDocument()` builds it.
 *
 * Rebuilt rather than loaded from `state.json` on purpose: `toJson()` **sorts**
 * every store, and the query surface's `searchableStrings` follow a form's
 * *insertion* order (`Bob`, `bob@example.com`, … for `DEMO/DET`). A document
 * loaded from the sorted golden would search the same values in a different
 * order and pick a different snippet, so `projection_cases.json` would not
 * reproduce. Ordering aside the two are the same document — which
 * {@link testFixtureDocument} asserts.
 *
 * @returns {SpecDocument}
 */
function _buildFixtureDocument() {
  const d = new SpecDocument();
  d.setContent('DEMO/TTL', 'Hello');
  d.setContent('DEMO/SUM', 'Line one\nLine two\n\nLine four');
  d.setContent('DEMO/PRI', 'high');
  d.setContent('DEMO/CNT', '3');
  d.setFormField('DEMO/DET', 'owner', 'Bob');
  d.setFormField('DEMO/DET', 'contact', 'bob@example.com');
  // YRD7: typed form-field values in their canonical plain-text store form.
  d.setFormField('DEMO/DET', 'estimate', '8');
  d.setFormField('DEMO/DET', 'weight', '2.5');
  d.setFormField('DEMO/DET', 'active', 'true');
  d.setFormField('DEMO/DET', 'priority', 'high');
  const i1 = d.addListItem('DEMO/items');
  d.setContent(`${i1}/label`, 'First');
  d.setContent(`${i1}/STS`, 'open');
  const i2 = d.addListItem('DEMO/items');
  d.setContent(`${i2}/label`, 'Second line A\nwith ```triple``` ticks');
  d.setContent(`${i2}/STS`, 'done');
  // A genuine `*-LST` list (id `REF-LST`, pattern `REF-xxx`).
  for (const ref of ['spec §1.2', 'ADR7']) {
    const r = d.addListItem('DEMO/REF-LST');
    d.setContent(r, ref);
  }
  // YRD3 fixtures: stored headlines + a stored (pattern-shaped, non-numeric)
  // item section id.
  d.setHeadline('DEMO/SUM', 'Executive Summary');
  d.setHeadline('DEMO/DET', 'Details & Contacts');
  d.setHeadline('DEMO/items', 'Work Items');
  d.setItemSectionId('DEMO/REF-LST-1', 'REF-SPEC');
  d.setHeadline('DEMO/REF-LST-1', 'Reference to the Spec');
  // Card 1 gets a stored item section id and headline; card 2 keeps both
  // defaults. The ordinary `note` field lands in the form store.
  const c1 = d.addListItem('DEMO/CARD-LST');
  d.setItemSectionId(c1, 'CARD-ALPHA');
  d.setHeadline(c1, 'Alpha Card');
  d.setFormField(`${c1}/content`, 'note', 'first card');
  const c2 = d.addListItem('DEMO/CARD-LST');
  d.setFormField(`${c2}/content`, 'note', 'second card');
  d.setContent('DEMO/META/OWNR', 'alice');
  // Scalar list exercising the YAML 1.1-special quoting rule (SOM §12.5).
  for (const tag of ['on', 'no', '1:30', 'plain']) {
    const t = d.addListItem('DEMO/META/tags');
    d.setContent(t, tag);
  }
  // A class-level-only section (`Control`, id `CTRL`).
  d.setContent('DEMO/control/CTRL-SUM', 'Controlled summary');
  d.setContent('DEMO/control/owner', 'ctrl-owner');
  // The `section`-kind member (`Notes`, class id `NOTE`, id-less field): a
  // section collapses into its target class exactly as a complex member does,
  // and keys on the target class's id when the field carries none.
  d.setContent('DEMO/notes/NOTE-BDY', 'Section-kind body');
  return d;
}

/** The rebuilt fixture must hold exactly the values `state.json` records. */
function testFixtureDocument() {
  const got = _buildFixtureDocument().toJson();
  const want = _readJson('state.json');
  _check('fixture.matchesState', _deepEqual(got, want), _jsonMismatch(got, want));
}

/**
 * Rebuilds a {@link SpecQuery} from its corpus wire form.
 *
 * Every port needs this same decode, so its shape *is* part of the contract: an
 * absent key means "dimension unset", never a default that happens to match.
 * Kept beside the replay tests rather than in `tom_som_runtime/` because it
 * belongs to the corpus format, not to the runtime API.
 *
 * @param {Object} j
 * @returns {SpecQuery}
 */
function _queryFromJson(j) {
  const opt = (key) => (Object.prototype.hasOwnProperty.call(j, key) ? j[key] : null);
  const kindNames = opt('kinds');
  let kinds = null;
  if (kindNames !== null) {
    const known = new Set(Object.values(SpecNodeKind));
    kinds = new Set();
    for (const k of kindNames) {
      if (!known.has(k)) {
        throw new Error(`unknown node kind "${k}" in query wire form`);
      }
      kinds.add(k);
    }
  }
  const stateName = opt('state');
  let state = null;
  if (stateName !== null) {
    if (!Object.values(SpecStateFilter).includes(stateName)) {
      throw new Error(`unknown state filter "${stateName}" in query wire form`);
    }
    state = stateName;
  }
  return new SpecQuery({
    text: opt('text'),
    regex: opt('regex') === null ? false : j.regex,
    caseInsensitive: opt('caseInsensitive') === null ? false : j.caseInsensitive,
    kinds,
    className: opt('className'),
    sectionIdExact: opt('sectionIdExact'),
    sectionIdPrefix: opt('sectionIdPrefix'),
    pathGlob: opt('pathGlob'),
    mapsTo: opt('mapsTo'),
    detailedIn: opt('detailedIn'),
    state,
  });
}

/**
 * The portable pattern subset (SOM §9): every committed match table plus every
 * committed compile rejection.
 *
 * `RegExp` is deliberately not used by the implementation — the spans are the
 * nine-language contract and the host engines disagree about them.
 */
function testPatterns() {
  const cases = _readJson('pattern_cases.json');
  for (const c of cases) {
    const source = c.pattern;
    if (c.error === true) {
      let rejected = false;
      try {
        SomTextPattern.compile(source);
      } catch (e) {
        rejected = e instanceof SomPatternError;
      }
      _check(`pattern[${source}].rejected`, rejected, 'must be rejected as SomPatternError');
      continue;
    }
    const ci = c.caseInsensitive === undefined ? false : c.caseInsensitive;
    const p = c.regex
      ? SomTextPattern.compile(source, { caseInsensitive: ci })
      : SomTextPattern.literal(source, { caseInsensitive: ci });
    const got = p.allMatches(c.text).map((s) => [s.start, s.end]);
    _check(
      `pattern[${source}] over "${c.text}"`,
      _deepEqual(got, c.spans),
      `${JSON.stringify(got)} != ${JSON.stringify(c.spans)}`,
    );
    // `hasMatch` is the same fact stated as a boolean; a port that special-cased
    // it would otherwise go unchecked.
    _check(`pattern[${source}].hasMatch`, p.hasMatch(c.text) === (c.spans.length > 0));
  }

  // A table of matches alone would let a port accept everything; a table of
  // rejections alone would let one reject everything.
  _check('pattern.table.hasRejections', cases.some((c) => c.error === true));
  _check('pattern.table.hasMatches', cases.some((c) => c.error !== true));
}

/**
 * The `spec_query` surface: each committed query reproduces its match list, in
 * order — and, separately, `count` agrees with that list's length (a port that
 * drains for `toList` but returns the raw candidate count for `count` passes the
 * first assertion and fails the second).
 *
 * @param {SpecModel} model
 * @param {SpecDocument} doc
 */
function testQueries(model, doc) {
  const engine = new SpecQueryEngine({ model, document: doc });
  for (const c of _readJson('query_cases.json')) {
    const got = engine
      .query(_queryFromJson(c.query))
      .toList()
      .map((m) => ({
        path: m.path,
        kind: m.kind,
        classId: m.classId,
        headline: m.headline,
        snippet: m.snippet,
        spans: m.matchSpans.map((s) => [s.start, s.end]),
      }));
    _check(
      `query[${c.name}]`,
      _deepEqual(got, c.matches),
      `${JSON.stringify(got)} != ${JSON.stringify(c.matches)}`,
    );
    const count = engine.query(_queryFromJson(c.query)).count;
    _check(
      `query[${c.name}].count`,
      count === c.matches.length,
      `${count} != ${c.matches.length}`,
    );
  }
}

/**
 * The flat `projectNodes()` walk in document order — the tier-1 index source.
 *
 * @param {SpecModel} model
 * @param {SpecDocument} doc
 */
function testProjection(model, doc) {
  const engine = new SpecQueryEngine({ model, document: doc });
  const got = [];
  for (const p of engine.projectNodes()) {
    got.push({
      path: p.path,
      kind: p.kind,
      classId: p.classId,
      sectionId: p.sectionId,
      mapsTo: p.mapsTo,
      detailedIn: p.detailedIn,
      headline: p.headline,
      searchableStrings: p.searchableStrings,
      hasValue: p.hasValue,
    });
  }
  const want = _readJson('projection_cases.json');
  _check('projection.walk', _deepEqual(got, want), _jsonMismatch(got, want));
}

/**
 * The scripted cursor session: laziness (`take`/`next`/`toList` consume,
 * `count` peeks) plus stability — an item removed *after* the cursor was opened
 * is skipped, not returned.
 *
 * @param {SpecModel} model
 */
function testCursorScript(model) {
  const d = _buildFixtureDocument();
  const engine = new SpecQueryEngine({ model, document: d });
  let cursor = null;
  const steps = _readJson('cursor_cases.json');
  for (let n = 0; n < steps.length; n++) {
    const s = steps[n];
    switch (s.op) {
      case 'open':
        cursor = engine.query(_queryFromJson(s.query));
        break;
      case 'count':
        _check(`cursor[${n}].count`, cursor.count === s.expect, `${cursor.count} != ${s.expect}`);
        break;
      case 'take': {
        const got = cursor.take(s.n).map((m) => m.path);
        _check(`cursor[${n}].take`, _deepEqual(got, s.expect), `${got} != ${s.expect}`);
        break;
      }
      case 'next': {
        const m = cursor.next();
        const got = m === null ? null : m.path;
        _check(`cursor[${n}].next`, got === s.expect, `${got} != ${s.expect}`);
        break;
      }
      case 'toList': {
        const got = cursor.toList().map((m) => m.path);
        _check(`cursor[${n}].toList`, _deepEqual(got, s.expect), `${got} != ${s.expect}`);
        break;
      }
      case 'removeListItem':
        d.removeListItem(s.itemPath);
        break;
      default:
        _check(`cursor[${n}].unknown`, false, s.op);
    }
  }
}

/**
 * The stateless `checkAddNode` probes — each against a **freshly built**
 * document, so they are order-independent. The corpus pins the
 * {@link SpecCreationCode} name, never the message: the code is the contract,
 * the message is prose, and pinning prose across nine languages would make
 * rewording a nine-package change.
 *
 * @param {SpecModel} model
 */
function testNodeCreation(model) {
  for (const c of _readJson('node_creation_cases.json')) {
    const d = _buildFixtureDocument();
    const itemId = c.itemId === undefined ? null : c.itemId;
    const err = checkAddNode(model, d, c.parentPath, c.childSegment, { itemId });
    _check(`nodeCreate[${c.name}].accepted`, (err === null) === c.accepted, String(err));
    if (err !== null) {
      _check(`nodeCreate[${c.name}].code`, err.code === c.code, `${err.code} != ${c.code}`);
      _check(`nodeCreate[${c.name}].parentPath`, err.parentPath === c.parentPath);
      _check(`nodeCreate[${c.name}].childSegment`, err.childSegment === c.childSegment);
    }
  }
}

/**
 * The stateful node-creation script: nine sequential steps against one
 * document, so each step sees what the previous produced (sequence numbers and
 * generated ids, which the stateless probes cannot exercise).
 *
 * @param {SpecModel} model
 */
function testNodeCreationScript(model) {
  const d = _buildFixtureDocument();
  const creator = new SpecNodeCreator(model, d);
  const steps = _readJson('node_creation_script.json');
  for (let n = 0; n < steps.length; n++) {
    const s = steps[n];
    const itemId = s.itemId === undefined ? null : s.itemId;
    switch (s.op) {
      case 'add': {
        const p = creator.add(s.parentPath, s.childSegment, {
          itemId,
          month: s.month,
          day: s.day,
        });
        _check(`nodeScript[${n}].add`, p === s.expectPath, `${p} != ${s.expectPath}`);
        const id = d.itemSectionId(p);
        _check(`nodeScript[${n}].addId`, id === s.expectId, `${id} != ${s.expectId}`);
        break;
      }
      case 'addThrows': {
        let code = null;
        try {
          // The reference dates every `addThrows` probe 2026-03-04; the add must
          // be rejected before the date is ever consulted.
          creator.add(s.parentPath, s.childSegment, { itemId, month: 3, day: 4 });
        } catch (e) {
          code = e instanceof SpecCreationError ? e.code : `<${e}>`;
        }
        _check(
          `nodeScript[${n}].addThrows`,
          code === s.expectCode,
          `${code} != ${s.expectCode}`,
        );
        break;
      }
      case 'finalState':
        _check(
          `nodeScript[${n}].finalState`,
          _deepEqual(d.toJson(), s.expect),
          _jsonMismatch(d.toJson(), s.expect),
        );
        break;
      default:
        _check(`nodeScript[${n}].unknown`, false, s.op);
    }
  }
}

function main() {
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
  testReflection(model);
  testValidation(model);
  testEditor(model);
  testOperations();
  testSectionId();
  testSerializationOrder();
  // SOM §9 query tier — over the rebuilt fixture (see `_buildFixtureDocument`).
  const fixture = _buildFixtureDocument();
  testFixtureDocument();
  testPatterns();
  testQueries(model, fixture);
  testProjection(model, fixture);
  testCursorScript(model);
  testNodeCreation(model);
  testNodeCreationScript(model);
  testDocSpecs();

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

module.exports = { main };
