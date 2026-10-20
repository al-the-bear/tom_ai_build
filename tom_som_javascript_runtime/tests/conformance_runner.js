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
 *   * assembling one document from fragments (`assembly_cases.json`);
 *   * review annotations — listing and editing comment blocks, question
 *     blocks and inline marks (`annotation_cases.json`, SOM §11.9), and
 *     accepting / rejecting inline marks (`inline_mark_cases.json`);
 *   * moving a list item and re-keying the review pass (`list_move_cases.json`);
 *   * the imperative operations script;
 *   * the generic editor (YRD7) script;
 *   * the SOM §9 query tier — the portable text-pattern subset, the query /
 *     projection tables, the scripted cursor session, and the constrained
 *     node-creation gate (probe table + stateful script);
 *   * the Phase-4 CodeSpecs extract tier — routing verdicts, the per-area extract
 *     goldens (YAML + Markdown, byte-for-byte), the "copied, never composed"
 *     guard and the `ROUTE-TOTAL` error cases;
 *   * the SOM §14 DocSpecs tier (schema load + one violation case per rule),
 *     and findings bound to their document path (`docspecs_path_cases.json`).
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
  CodeSpecsGate,
  DEFAULT_MAX_SNAPSHOT_AGE_MS,
  DocSpecsDocument,
  DocSpecsSchema,
  DocSpecsValidator,
  DocSpecsViolationRule,
  SomEditability,
  SomPatternError,
  SomTextPattern,
  SomVersionError,
  CodeSpecsAreaCatalog,
  CodeSpecsExtract,
  CodeSpecsExtractError,
  CodeSpecsExtractSet,
  CodeSpecsExtractor,
  CodeSpecsGateEntry,
  CodeSpecsGateGap,
  CodeSpecsGateRecord,
  CodeSpecsGateVerdict,
  CodeSpecsRecordError,
  SpecCreationError,
  SpecDocument,
  SpecDocumentMarkdown,
  SpecEditor,
  SpecModel,
  SpecNodeCreator,
  SpecNodeKind,
  SpecQuery,
  SpecQueryEngine,
  SpecQuestionDraft,
  SpecReviewAnnotationError,
  SpecReviewAnnotations,
  applyInlineMarksText,
  buildSomMetaTree,
  checkAddNode,
  checkSomModelVersion,
  somEditabilityFor,
  staleReviewPaths,
  SpecReflection,
  SpecSectionIdCollision,
  SpecSerializationOrder,
  SpecStateFilter,
  SpecDocumentYaml,
  encodeTwoLetterDate,
  generateListItemSectionId,
  validateDocument,
  validateSpecDocument,
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
  _check('model.classCount', model.classes.size === 15, String(model.classes.size));
  const demo = model.classNamed('Demo');
  _check('model.Demo.found', demo !== null);
  if (demo !== null) {
    const names = demo.fields.map((f) => f.name);
    _check(
      'model.Demo.fields',
      _deepEqual(names, ['title', 'summary', 'priority', 'count', 'ratio', 'score', 'details', 'items', 'refs', 'cards', 'meta', 'control', 'notes', 'mixed', 'registry']),
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
  const imported = SpecDocument.fromMarkdown(golden, model);
  _check(
    'md.land.clean',
    imported.rejections.length === 0,
    imported.rejections.map((r) => String(r)).join('; '),
  );
  const landed = imported.document;
  _check(
    'md.land.memory',
    _deepEqual(landed.toJson(), canonical),
    _jsonMismatch(landed.toJson(), canonical),
  );
}

// One `markdown_apply_cases.json` case, run like Dart's `_runMarkdownApplyCase`:
// `fromMarkdown` loads into a fresh document; `apply` parses against `base` and
// applies as a full overwrite, `refused` when the apply throws.
function _runMarkdownApplyCase(model, c) {
  if (c.op === 'fromMarkdown') {
    const imported = SpecDocument.fromMarkdown(c.markdown, model);
    return {
      refused: false,
      rejectionCount: imported.rejections.length,
      document: imported.document.toJson(),
    };
  }
  const document = _documentFromState(c.base);
  const parsed = new SpecDocumentMarkdown(model, document).parse(c.markdown);
  let refused = false;
  try {
    document.applyMarkdownResult(parsed, c.allowRejections);
  } catch (_) {
    refused = true;
  }
  return {
    refused,
    rejectionCount: parsed.rejections.length,
    document: document.toJson(),
  };
}

// SOM §11.7 apply: `fromMarkdown` and `applyMarkdownResult` — full overwrite
// of the covered roots, other roots kept, rejections refused unless allowed.
function testMarkdownApply(model) {
  for (const c of _readJson('markdown_apply_cases.json').cases) {
    const got = _runMarkdownApplyCase(model, c);
    _check(`mdApply[${c.name}]`, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
  }
}

// One `assembly_cases.json` case, run like Dart's `_runAssemblyCase`: each
// fragment state loads into a fresh document, the fragments assemble in the
// given order, and the result is reported as plain data.
function _runAssemblyCase(c) {
  const fragments = new Map();
  for (const [name, state] of c.fragments) {
    fragments.set(name, _documentFromState(state));
  }
  const result = SpecDocument.assemble(fragments);
  return {
    ok: result.ok,
    document: result.document ? result.document.toJson() : null,
    overlaps: result.overlaps.map((o) => ({
      store: o.store,
      path: o.path,
      field: o.field,
      fragments: o.fragments.slice(),
      message: o.message,
    })),
  };
}

// Assembling one document from fragments: disjoint fragments merge (forms
// field by field), and any place two fragments both write is refused with
// every overlap reported in store order, then path order.
function testAssembly() {
  for (const c of _readJson('assembly_cases.json').cases) {
    const got = _runAssemblyCase(c);
    _check(`assembly[${c.name}]`, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
  }
}

function _mapToObject(m) {
  const out = {};
  for (const [k, v] of m) out[k] = v;
  return out;
}

// One `annotation_cases.json` case, run like Dart's `_runAnnotationCase`:
// every op runs in order on one document loaded from `state`; an op that
// raises the annotation error answers `{error: true}` and changes nothing.
function _runAnnotationCase(model, tree, c) {
  const doc = _documentFromState(JSON.parse(JSON.stringify(c.state)));
  const api = new SpecReviewAnnotations(doc, { qualifier: c.qualifier ?? null });
  const results = [];
  for (const op of c.ops) {
    try {
      results.push(_runAnnotationOp(model, tree, doc, api, op));
    } catch (e) {
      if (!(e instanceof SpecReviewAnnotationError)) throw e;
      results.push({ error: true });
    }
  }
  return { results, state: doc.toJson() };
}

function _runAnnotationOp(model, tree, doc, api, op) {
  switch (op.op) {
    case 'list':
      return api.list().map((a) => a.toJson());
    case 'counts':
      return api.counts().toJson();
    case 'nextId':
      return api.nextCommentId({ floor: op.floor ?? 0 });
    case 'assignIds':
      return api.assignCommentIds({ floor: op.floor ?? 0 });
    case 'insertComment':
      return api.insertComment({
        path: op.path,
        field: op.field ?? null,
        afterParagraph: op.afterParagraph,
        text: op.text,
        author: op.author ?? null,
        id: op.id ?? null,
      });
    case 'insertQuestion':
      api.insertQuestion({
        path: op.path,
        field: op.field ?? null,
        afterParagraph: op.afterParagraph,
        question: SpecQuestionDraft.fromJson(op.question),
      });
      return null;
    case 'insertQuestionAfterComment':
      api.insertQuestionAfterComment(op.commentId, SpecQuestionDraft.fromJson(op.question));
      return null;
    case 'setAnswer':
      api.setAnswer(op.id, op.answer);
      return null;
    case 'editComment':
      api.editComment(op.id, op.text);
      return null;
    case 'resolve':
      api.resolve(op.id);
      return null;
    case 'applyMark':
      api.applyMark({
        path: op.path,
        field: op.field ?? null,
        index: op.index,
        accept: op.accept ?? true,
      });
      return null;
    case 'strip':
      return api.stripped().toJson();
    case 'revision':
      return api.revision();
    case 'listMarks':
      return api.listMarks({ path: op.path ?? null }).map((m) => m.toJson());
    case 'decideMarks':
      return api
        .decideMarks(op.decisions, {
          revision: op.revision === '@current' ? api.revision() : op.revision,
        })
        .toJson();
    case 'acceptAll':
      return api.acceptAllMarks({ path: op.path ?? null }).toJson();
    case 'rejectAll':
      return api.rejectAllMarks({ path: op.path ?? null }).toJson();
    case 'removeAll':
      return api.removeAllAnnotations().toJson();
    case 'roundTrip': {
      const current = JSON.stringify(doc.toJson());
      const fromYaml = yamlDecode(yamlEncode(doc, tree, _MODEL_VERSION), tree).document;
      const md = new SpecDocumentMarkdown(model, doc).exportRoot(model.roots[0]);
      const fromMd = SpecDocument.fromMarkdown(md, model);
      return {
        yaml: JSON.stringify(fromYaml.toJson()) === current,
        markdown:
          fromMd.rejections.length === 0 &&
          JSON.stringify(fromMd.document.toJson()) === current,
      };
    }
    default:
      throw new Error(`unknown annotation op ${op.op}`);
  }
}

// Review annotations (SOM §11.9): the results of every op and the final state.
function testAnnotations(model, tree) {
  for (const c of _readJson('annotation_cases.json').cases) {
    const name = `annotation[${c.name}]`;
    try {
      const got = _runAnnotationCase(model, tree, c);
      _check(name, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
    } catch (e) {
      _check(name, false, `threw ${String(e)}`);
    }
  }
}

// Accepting and rejecting inline marks (SOM §11.9.3): the text table pins
// `applyInlineMarksText`, the scripted cases run like `annotation_cases.json`.
function testInlineMarks(model, tree) {
  const table = _readJson('inline_mark_cases.json');
  for (const c of table.textCases) {
    const name = `inlineMarkText[${c.name}]`;
    const acc = applyInlineMarksText(c.text, { accept: true });
    const rej = applyInlineMarksText(c.text, { accept: false });
    _check(
      name,
      acc === c.accept && rej === c.reject,
      `accept ${JSON.stringify(acc)} vs ${JSON.stringify(c.accept)}; ` +
        `reject ${JSON.stringify(rej)} vs ${JSON.stringify(c.reject)}`,
    );
  }
  for (const c of table.cases) {
    const name = `inlineMark[${c.name}]`;
    try {
      const got = _runAnnotationCase(model, tree, c);
      _check(name, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
    } catch (e) {
      _check(name, false, `threw ${String(e)}`);
    }
  }
}

// One `list_move_cases.json` case, run like Dart's `_runListMoveCase`: the
// state loads, the move runs, and the result (or the refusal's error word) is
// reported as plain data.
function _runListMoveCase(model, c) {
  const doc = _documentFromState(c.state);
  const move = c.move;
  try {
    const result = doc.moveListItem(
      model,
      move.itemPath,
      move.toIndex,
      move.toList === undefined ? null : move.toList,
    );
    return {
      ok: true,
      path: result.path,
      renamed: _mapToObject(result.renamed),
      pinnedIds: _mapToObject(result.pinnedIds),
      document: doc.toJson(),
    };
  } catch (e) {
    if (e instanceof SpecSectionIdCollision) return { ok: false, error: 'collision' };
    if (e instanceof RangeError) return { ok: false, error: 'range' };
    return { ok: false, error: 'argument' };
  }
}

// Moving a list item (vsctsa44): a path is a position, the section id is the
// identity — renumbering, values travelling with their item, anonymous ids
// pinned, the refusals; and the `review:` pass re-keyed by the move's result.
function testListMove(model) {
  const table = _readJson('list_move_cases.json');
  for (const c of table.cases) {
    const got = _runListMoveCase(model, c);
    _check(`listMove[${c.name}]`, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
  }
  for (const c of table.reviewCases) {
    const got = SpecDocumentYaml.rekeyReview(c.review, c.renamed);
    _check(`listMove.review[${c.name}]`, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
  }
}

// One `yaml_review_cases.json` case, run like Dart's `_runYamlReviewCase`:
// `roundTrip` re-encodes the decoded document with its decoded review pass;
// `stale` removes the named list items, then asks which review entries no
// longer resolve.
function _runYamlReviewCase(model, tree, c) {
  const contents = yamlDecode(c.yaml, tree);
  if (c.op === 'roundTrip') {
    return yamlEncode(contents.document, tree, contents.modelVersion, contents.review);
  }
  for (const item of c.removeItems) {
    contents.document.removeListItem(item);
  }
  return staleReviewPaths(model, contents.document, contents.review ?? {});
}

// The `review:` pass: written back sorted and byte-stable, and stale entries
// (unresolvable paths, removed list items) reported.
function testYamlReview(model, tree) {
  for (const c of _readJson('yaml_review_cases.json').cases) {
    const got = _runYamlReviewCase(model, tree, c);
    const ok = c.op === 'roundTrip' ? got === c.expect : _deepEqual(got, c.expect);
    const detail =
      c.op === 'roundTrip'
        ? _byteDiff(`yamlReview[${c.name}]`, String(got), c.expect)
        : _jsonMismatch(got, c.expect);
    _check(`yamlReview[${c.name}]`, ok, detail);
  }
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
    } else if (kind === 'setRawFormField') {
      // raw form write (bypasses the typed boundary)
      doc.setFormField(s.path, s.field, s.value);
    } else if (kind === 'valueUnreadable') {
      _check(
        `editor[${n}].valueUnreadable ${s.path}`,
        _throws(() => ed.value(s.path)),
        '',
      );
    } else if (kind === 'formValueUnreadable') {
      _check(
        `editor[${n}].formValueUnreadable ${s.path}#${s.field}`,
        _throws(() => ed.formValue(s.path, s.field)),
        '',
      );
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

/**
 * `docspecs_path_cases.json`: the renderer's heading map and
 * `validateSpecDocument` binding each finding to its document path (SOM §14).
 */
function testDocSpecsPath(model) {
  const table = _readJson('docspecs_path_cases.json');
  const schema = DocSpecsSchema.fromYamlText(table.schema);
  for (const c of table.cases) {
    const d = new SpecDocument();
    d.loadJson(c.state);
    const rendition = d.toMarkdownWithMap(model, c.rootType);
    const gotMap = {};
    for (const [line, p] of rendition.headingPaths) {
      gotMap[String(line)] = p;
    }
    _check(`docspecsPath[${c.name}].headingPaths`,
      _deepEqual(gotMap, c.headingPaths),
      `${JSON.stringify(gotMap)} != ${JSON.stringify(c.headingPaths)}`);
    const got = validateSpecDocument(model, d, schema, c.rootType).map((v) => ({
      rule: v.rule,
      line: v.line,
      sectionId: v.sectionId,
      path: v.path,
    }));
    _check(`docspecsPath[${c.name}].violations`, _deepEqual(got, c.violations),
      `${JSON.stringify(got)} != ${JSON.stringify(c.violations)}`);
  }
}

/**
 * Replays one `docspecs_replace_cases.json` case: `{error: true}` when
 * {@link DocSpecsDocument.replaceSectionBody} throws, else the rewritten text.
 */
function _runDocSpecsReplaceCase(c) {
  try {
    const text = DocSpecsDocument.replaceSectionBody(c.markdown, c.sectionId, c.body);
    return { error: false, text };
  } catch (_) {
    return { error: true };
  }
}

/** DocSpecs section-body replacement: error flag and exact rewritten text. */
function testDocSpecsReplace() {
  for (const c of _readJson('docspecs_replace_cases.json').cases) {
    const got = _runDocSpecsReplaceCase(c);
    const want = c.expect;
    const ok = got.error === want.error && (want.error || got.text === want.text);
    _check(`docspecsReplace[${c.name}]`, ok,
      `${JSON.stringify(got)} != ${JSON.stringify(want)}`);
  }
}

// ---------------------------------------------------------------------------
// SOM §9: spec_text_pattern / spec_query / spec_node_creation
// ---------------------------------------------------------------------------

/**
 * The corpus fixture document, built the way the Dart reference's
 * `_buildDocument()` builds it.
 *
 * Rebuilt rather than loaded from `state.json` on purpose: `toJson()` **sorts**
 * every store, so a reloaded document would hold `DEMO/DET` alphabetically and
 * a port that iterated the store would look right for the wrong reason. Form
 * fields are emitted in **model-declaration** order (SOM §9, "Form-field
 * order"), so the populate order below is deliberately neither declaration
 * order nor alphabetical — a port that follows its store picks a different
 * snippet and fails `projection_cases.json`. Ordering aside the two are the
 * same document — which {@link testFixtureDocument} asserts.
 *
 * @returns {SpecDocument}
 */
function _buildFixtureDocument() {
  const d = new SpecDocument();
  d.setContent('DEMO/TTL', 'Hello');
  d.setContent('DEMO/SUM', 'Line one\nLine two\n\nLine four');
  d.setContent('DEMO/PRI', 'high');
  d.setContent('DEMO/CNT', '3');
  // Scrambled on purpose — see the doc comment. Do not "tidy" into order.
  // YRD7: typed form-field values in their canonical plain-text store form.
  d.setFormField('DEMO/DET', 'priority', 'high');
  d.setFormField('DEMO/DET', 'weight', '2.5');
  d.setFormField('DEMO/DET', 'owner', 'Bob');
  d.setFormField('DEMO/DET', 'active', 'true');
  d.setFormField('DEMO/DET', 'estimate', '8');
  // SOM §11.4 rule 8: rendered as an inline code span, so the
  // `](` stays literal instead of becoming a markdown link.
  d.setFormField('DEMO/DET', 'pattern', '^[a-z0-9](-?[a-z0-9]){1,62}$');
  // A multi-line value ending in a markdown list (SOM §11.4 rule 2).
  d.setFormField(
    'DEMO/DET',
    'contact',
    'bob@example.com\n- on call: weekdays\n- backup: alice@example.com',
  );
  // The form preamble (SOM §11.4 rule 7): free text in the form's own content
  // slot, beside its fields. Line 2 is label-shaped AND shadows the declared
  // `owner` field, so the rule-3 escape has to hold on emit.
  d.setContent(
    'DEMO/DET',
    'Captured during the November review.\nOwner: this line is prose, not the field.',
  );
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
  // An item of a pattern list stores its id even when it equals the
  // positional default (`REF-2`, `CARD-2` below): the Markdown heading
  // carries that id and import stores it (SOM §11.6), so the YAML and the
  // Markdown route can only land in the same memory if the fixture does too.
  // Positional items stay covered by the pattern-less `items` and `tags`.
  d.setItemSectionId('DEMO/REF-LST-2', 'REF-2');
  // YRD3 fixtures: stored headlines + a stored (pattern-shaped, non-numeric)
  // item section id.
  d.setHeadline('DEMO/SUM', 'Executive Summary');
  d.setHeadline('DEMO/DET', 'Details & Contacts');
  d.setHeadline('DEMO/items', 'Work Items');
  d.setItemSectionId('DEMO/REF-LST-1', 'REF-SPEC');
  d.setHeadline('DEMO/REF-LST-1', 'Reference to the Spec');
  // Card 1 gets a stored item section id and headline; card 2 stores the
  // default id `CARD-2` and keeps the derived item title. The ordinary `note`
  // field lands in the form store.
  const c1 = d.addListItem('DEMO/CARD-LST');
  d.setItemSectionId(c1, 'CARD-ALPHA');
  d.setHeadline(c1, 'Alpha Card');
  d.setFormField(`${c1}/content`, 'note', 'first card');
  const c2 = d.addListItem('DEMO/CARD-LST', 'CARD-2');
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
  d.setContent('DEMO/notes/remarks', 'Wrapper-section text');
  // SOM §11.6 slot markers, §11.2 headline line breaks, §11.3 blank lines: a
  // two-line headline, a form preamble that is not the default target, a
  // narrative after a form field, a second content slot, a label-shaped
  // narrative line, two blank lines kept as written, and a second form whose
  // `Lead` label the first form shares.
  d.setHeadline('DEMO/MIX', 'Mixed\nslots');
  d.setContent('DEMO/MIX/content', '_Extrapolated._');
  d.setFormField('DEMO/MIX/content', 'lead', 'Ada');
  d.setFormField('DEMO/MIX/content', 'risk', 'low');
  d.setContent(
    'DEMO/MIX/narrative',
    'First narrative.\n\n\nAfter two blank lines.\nLead: label-shaped prose',
  );
  d.setContent('DEMO/MIX/tail', 'Tail text.');
  d.setFormField('DEMO/MIX/alt', 'lead', 'Bob');
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
 * The Phase-4 CodeSpecs extract generator: the routing verdicts, the per-area
 * extracts (including the YAML and Markdown goldens byte for byte), the two
 * standing guards — every value copied rather than composed, and a
 * `@FollowUpKind` subtree contributing nothing — and the `ROUTE-TOTAL` error
 * cases.
 *
 * @param {SpecModel} model
 * @param {SpecDocument} doc
 */
function testCodeSpecsExtract(model, doc) {
  const table = _readJson('codespecs_extract_cases.json');
  const extractor = new CodeSpecsExtractor({
    model,
    document: doc,
    catalog: CodeSpecsAreaCatalog.fromJson(table.catalog),
  });

  const routings = extractor.routings().map((r) => ({
    path: r.path,
    className: r.className,
    verdict: r.verdict,
    values: r.values,
    note: r.note,
    declaredAt: r.declaredAt,
  }));
  _check(
    'codespecs.routings',
    _deepEqual(routings, table.routings),
    _jsonMismatch(routings, table.routings),
  );

  // 1b. The §4.4.6 authoring-step table, read back from the catalogue — and
  // from the same catalogue with `steps` removed, which must load as an older
  // catalogue that carries no steps rather than fail.
  const stepsByArea = (c) => {
    const out = {};
    for (const area of c.areas) {
      out[area.code] = c.stepsFor(area).map((s) => s.number);
    }
    return out;
  };
  const stepCatalog = CodeSpecsAreaCatalog.fromJson(table.catalog);
  const legacyJson = { ...table.catalog };
  delete legacyJson.steps;
  const legacyCatalog = CodeSpecsAreaCatalog.fromJson(legacyJson);
  const gotStepCases = {
    steps: stepCatalog.steps.map((s) => ({
      number: s.number,
      title: s.title,
      slice: s.slice,
      placedBy: s.placedBy,
      areaCodes: s.areaCodes,
    })),
    stepsByArea: stepsByArea(stepCatalog),
    legacy: {
      steps: legacyCatalog.steps.length,
      areas: legacyCatalog.areas.length,
      stepsByArea: stepsByArea(legacyCatalog),
    },
  };
  _check(
    'codespecs.stepCases',
    _deepEqual(gotStepCases, table.stepCases),
    _jsonMismatch(gotStepCases, table.stepCases),
  );

  const extracts = extractor.extractAll().map((x) => ({
    area: x.area.code,
    canonicalId: x.area.canonicalId,
    part: x.area.kindValue,
    documentRoot: x.documentRoot,
    fileStem: x.fileStem,
    projects: x.projects,
    citableParts: x.citableParts,
    entries: x.entries.map((e) => ({
      sectionId: e.sectionId,
      headline: e.headline,
      instanceId: e.instanceId,
      path: e.path,
      className: e.className,
      fieldName: e.fieldName,
      formField: e.formField,
      routedBy: e.routedBy,
      routedAt: e.routedAt,
      routingNote: e.routingNote,
      value: e.value,
    })),
    yaml: x.toYaml(),
    markdown: x.toMarkdown(),
  }));
  _check(
    'codespecs.extracts',
    _deepEqual(extracts, table.extracts),
    _jsonMismatch(extracts, table.extracts),
  );
  // The goldens are strings, so name the first differing line rather than
  // dumping two whole artifacts when a port drifts on emission.
  for (let i = 0; i < Math.min(extracts.length, table.extracts.length); i++) {
    const area = table.extracts[i].area;
    _check(
      `codespecs.extract[${area}].yaml`,
      extracts[i].yaml === table.extracts[i].yaml,
      _byteDiff('yaml', extracts[i].yaml, table.extracts[i].yaml),
    );
    _check(
      `codespecs.extract[${area}].markdown`,
      extracts[i].markdown === table.extracts[i].markdown,
      _byteDiff('markdown', extracts[i].markdown, table.extracts[i].markdown),
    );
  }

  // The guard `codespecs_derivation_contract.md` §2.8 C1 rests on, carried in
  // the corpus rather than left to each port's own conscience: the generator may
  // copy and index, it may not compose. Membership, not substring — that is what
  // makes "verbatim" mean verbatim rather than "derived from".
  const state = _readJson('state.json');
  const stored = new Set(Object.values(state.content));
  for (const section of Object.values(state.forms)) {
    for (const v of Object.values(section)) {
      stored.add(v);
    }
  }
  _check('codespecs.stored.nonEmpty', stored.size > 0, String(stored.size));
  for (const x of table.extracts) {
    for (const e of x.entries) {
      _check(
        `codespecs.verbatim[${x.area} ${e.path}]`,
        stored.has(e.value),
        'was not copied from the document',
      );
    }
  }

  // `Control` is populated, and populated distinctively, so its absence cannot
  // be an accident of an empty section.
  const emitted = [];
  for (const x of table.extracts) {
    for (const e of x.entries) {
      emitted.push(e.value);
    }
  }
  for (const forbidden of ['Controlled summary', 'ctrl-owner', 'alice']) {
    // …the last of which is a @NoArtifact section's own leaf.
    _check(
      `codespecs.excluded[${forbidden}]`,
      !emitted.includes(forbidden),
      'reached an extract',
    );
  }

  for (const c of table.errorCases) {
    // The error case carries its own model and state rather than mutating the
    // shared fixture: `model.meta.json` is a VALID model by construction (§10.2
    // `ROUTE-TOTAL` holds over it), and a port in a language without cheap
    // structural editing should not have to break it to run this case. `state`
    // is the ordinary `state.json` shape, so every runtime already has the
    // loader.
    const errExtractor = new CodeSpecsExtractor({
      model: SpecModel.fromJson(c.model),
      document: _documentFromState(c.state),
      catalog: CodeSpecsAreaCatalog.fromJson(table.catalog),
    });
    const want = c.expect;
    let thrown = null;
    try {
      errExtractor.extractAll();
    } catch (err) {
      thrown = err;
    }
    _check(
      `codespecs.error[${c.name}].thrown`,
      thrown instanceof CodeSpecsExtractError,
      String(thrown),
    );
    if (thrown instanceof CodeSpecsExtractError) {
      _check(
        `codespecs.error[${c.name}].path`,
        thrown.path === want.path,
        `${thrown.path} != ${want.path}`,
      );
      _check(
        `codespecs.error[${c.name}].className`,
        thrown.className === want.className,
        `${thrown.className} != ${want.className}`,
      );
      _check(
        `codespecs.error[${c.name}].message`,
        thrown.message.includes(want.messageContains),
        thrown.message,
      );
    }
    // …and the diagnostic reports the same node instead of throwing.
    const verdicts = errExtractor
      .routings()
      .filter((r) => r.path === want.path)
      .map((r) => r.verdict);
    _check(
      `codespecs.error[${c.name}].routingVerdict`,
      _deepEqual(verdicts, [want.routingVerdict]),
      _jsonMismatch(verdicts, [want.routingVerdict]),
    );
  }

  // A malformed catalogue row (a slice, area or step missing a required field,
  // or carrying a string where a number belongs) must fail naming the row,
  // never load as NaN — every runtime pins the same message fragment, so the
  // row label is part of the contract.
  for (const c of table.catalogErrorCases) {
    const want = c.expect.messageContains;
    let thrown = null;
    try {
      CodeSpecsAreaCatalog.fromJson(c.catalog);
    } catch (err) {
      thrown = err;
    }
    _check(
      `codespecs.catalogError[${c.name}].thrown`,
      thrown instanceof Error,
      'did not throw',
    );
    if (thrown instanceof Error) {
      _check(
        `codespecs.catalogError[${c.name}].message`,
        thrown.message.includes(want),
        thrown.message,
      );
    }
  }

  // Root scoping (`codespecs_prompt.md` §5): the walk starts at ONE root. The
  // models here carry two, because over a single-root model "walks the named
  // root" and "walks every root" give the same answer.
  for (const c of table.rootCases) {
    const want = c.expect;
    const build = () =>
      new CodeSpecsExtractor({
        model: SpecModel.fromJson(c.model),
        document: _documentFromState(c.state),
        catalog: CodeSpecsAreaCatalog.fromJson(table.catalog),
        rootType: c.rootType === undefined ? null : c.rootType,
      });
    if (want.fails) {
      let thrown = null;
      try {
        build();
      } catch (err) {
        thrown = err;
      }
      _check(
        `codespecs.root[${c.name}].thrown`,
        thrown instanceof CodeSpecsExtractError,
        String(thrown),
      );
      if (thrown instanceof CodeSpecsExtractError) {
        _check(
          `codespecs.root[${c.name}].path`,
          thrown.path === want.path,
          `${thrown.path} != ${want.path}`,
        );
        _check(
          `codespecs.root[${c.name}].className`,
          thrown.className === want.className,
          `${thrown.className} != ${want.className}`,
        );
        _check(
          `codespecs.root[${c.name}].message`,
          thrown.message.includes(want.messageContains),
          thrown.message,
        );
      }
      continue;
    }
    const x = build();
    _check(
      `codespecs.root[${c.name}].root`,
      x.root.type === want.root,
      x.root.type,
    );
    // `routings` and `extractAll` walk the same resolved root, so the verdict
    // sequence is scoped too — that is what makes the bare `@Document` root of
    // case 2 the corpus's `documentRoot` producer.
    const rootVerdicts = x.routings().map((r) => r.verdict);
    _check(
      `codespecs.root[${c.name}].routingVerdicts`,
      _deepEqual(rootVerdicts, want.routingVerdicts),
      _jsonMismatch(rootVerdicts, want.routingVerdicts),
    );
    const gotExtracts = x.extractAll();
    _check(
      `codespecs.root[${c.name}].documentRoot`,
      gotExtracts[0].documentRoot === want.documentRoot,
      gotExtracts[0].documentRoot,
    );
    const paths = gotExtracts.flatMap((g) => g.entries.map((e) => e.path));
    _check(
      `codespecs.root[${c.name}].paths`,
      _deepEqual(paths, want.paths),
      _jsonMismatch(paths, want.paths),
    );
  }
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

/** The summary `_extractSummary` in the Dart reference's conformance test. */
function _extractSummary(x) {
  return {
    area: x.area.code,
    canonicalId: x.area.canonicalId,
    part: x.area.part,
    documentRoot: x.documentRoot,
    projects: x.projects,
    citableParts: x.citableParts,
    entryCount: x.entries.length,
    sectionIds: x.entries.map((e) => e.sectionId),
    values: x.entries.map((e) => e.value),
    classNames: x.entries.map((e) => e.className),
    headlines: x.entries.map((e) => e.headline),
  };
}

/** The summary `_gateSummary` in the Dart reference's conformance test. */
function _gateSummary(g) {
  return {
    verdicts: g.verdicts.map((v) => ({
      area: v.area,
      verdict: v.verdict.word,
      resolution: v.resolution,
      note: v.note,
      // Only when present, so a gap-less entry's summary is unchanged.
      ...(v.gaps.length > 0
        ? {
            gaps: v.gaps.map((g) => ({
              sectionId: g.sectionId,
              required: g.required,
              carrier: g.carrier,
            })),
          }
        : {}),
    })),
  };
}

/** The summary `_scopeSummary` in the Dart reference's conformance test. */
function _scopeSummary(set) {
  return {
    inScope: set.extracts.map((x) => x.area.code),
    sources: [...set.sources],
    hasGate: set.gate !== null,
    excluded: set.excluded.map((e) => ({
      area: e.area,
      verdict: e.verdict.word,
      descoped: e.descoped,
      entryCount: e.entryCount,
      source: e.source,
    })),
  };
}

function _gateEntry(v) {
  return new CodeSpecsGateEntry({
    area: v.area,
    verdict: CodeSpecsGateVerdict.parse(v.verdict),
    resolution: v.resolution != null ? v.resolution : null,
    note: v.note != null ? v.note : null,
    gaps: (v.gaps || []).map(
      (g) =>
        new CodeSpecsGateGap({
          sectionId: g.sectionId,
          required: g.required,
          carrier: g.carrier,
        }),
    ),
  });
}

/**
 * Runs `fn`, expecting a {@link CodeSpecsRecordError} whose message contains
 * `needle` (the corpus pins substrings of the Dart wording).
 */
function _recordErrorWith(name, fn, needle) {
  try {
    fn();
    _check(name, false, 'expected a CodeSpecsRecordError, but returned normally');
  } catch (e) {
    if (!(e instanceof CodeSpecsRecordError)) {
      _check(name, false, `expected a CodeSpecsRecordError, got ${String(e)}`);
      return;
    }
    _check(
      name,
      e.message.includes(needle),
      `'${e.message}' does not contain '${needle}'`,
    );
  }
}

/**
 * Reading back what a Phase-4 run wrote: the extract files (an exact round
 * trip of what the extractor emits) and the Stage-B gate record, alone and as
 * the scope of a set of extracts (`codespecs_record_cases.json`).
 */
function testCodeSpecsRecords() {
  const table = _readJson('codespecs_record_cases.json');
  const catalog = CodeSpecsAreaCatalog.fromJson(
    _readJson('codespecs_extract_cases.json').catalog,
  );

  for (const c of table.extractReads) {
    const name = `codespecs.record.extractRead[${c.source}]`;
    try {
      const x = CodeSpecsExtract.fromYaml(c.yaml, c.source);
      const got = _extractSummary(x);
      _check(name, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
      const yaml = x.toYaml();
      _check(`${name}.roundTrip`, yaml === c.yaml, _byteDiff(name, yaml, c.yaml));
    } catch (e) {
      _check(name, false, `threw ${String(e)}`);
    }
  }

  {
    const c = table.extractMinimal;
    const name = 'codespecs.record.extractMinimal';
    try {
      const got = _extractSummary(CodeSpecsExtract.fromYaml(c.yaml, c.source));
      _check(name, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
    } catch (e) {
      _check(name, false, `threw ${String(e)}`);
    }
  }

  for (const c of table.extractErrors) {
    _recordErrorWith(
      `codespecs.record.extractError[${c.name}]`,
      () => CodeSpecsExtract.fromYaml(c.yaml, c.source),
      c.messageContains,
    );
  }

  for (const c of table.gateRecords) {
    const name = `codespecs.record.gate[${c.name}]`;
    try {
      const g = CodeSpecsGateRecord.fromYaml(c.yaml);
      const got = _gateSummary(g);
      _check(name, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
      const yaml = g.toYaml();
      _check(`${name}.toYaml`, yaml === c.yaml, _byteDiff(name, yaml, c.yaml));
      g.checkAgainst(catalog);
      _check(`${name}.checkAgainst`, true);
    } catch (e) {
      _check(name, false, `threw ${String(e)}`);
    }
  }

  for (const c of table.gateWrites) {
    const name = `codespecs.record.gateWrite[${c.name}]`;
    try {
      let g = new CodeSpecsGateRecord(c.verdicts.map(_gateEntry));
      const yaml = g.toYaml();
      _check(name, yaml === c.yaml, _byteDiff(name, yaml, c.yaml));
      if (c.then != null) {
        g = g.withVerdict(_gateEntry(c.then));
        const thenYaml = g.toYaml();
        _check(
          `${name}.then`,
          thenYaml === c.thenYaml,
          _byteDiff(`${name}.then`, thenYaml, c.thenYaml),
        );
      }
    } catch (e) {
      _check(name, false, `threw ${String(e)}`);
    }
  }

  for (const c of table.gateErrors) {
    _recordErrorWith(
      `codespecs.record.gateError[${c.name}]`,
      () => {
        const g = CodeSpecsGateRecord.fromYaml(c.yaml);
        if (c.againstCatalog === true) {
          g.checkAgainst(catalog);
        }
      },
      c.messageContains,
    );
  }

  for (const c of table.scopeCases) {
    const name = `codespecs.record.scope[${c.name}]`;
    // A list of [name, text] pairs: the order is part of the contract.
    const files = c.files.map((f) => [f[0], f[1]]);
    if (c.expect.error !== undefined) {
      _recordErrorWith(
        name,
        () => CodeSpecsExtractSet.fromFiles(files),
        c.expect.error,
      );
      continue;
    }
    try {
      const set = CodeSpecsExtractSet.fromFiles(files);
      const got = _scopeSummary(set);
      _check(name, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
      // The same files as a Map read the same, in the same order.
      const viaMap = _scopeSummary(CodeSpecsExtractSet.fromFiles(new Map(files)));
      _check(`${name}.map`, _deepEqual(viaMap, c.expect), _jsonMismatch(viaMap, c.expect));
      // The lookups agree with the in-scope list.
      for (const x of set.extracts) {
        _check(`${name}.byArea[${x.area.code}]`, set.byArea(x.area.code) === x);
      }
      for (const e of set.excluded) {
        _check(`${name}.byArea[${e.area}] excluded`, set.byArea(e.area) === null);
      }
      if (set.extracts.length > 0 && set.extracts[0].entries.length > 0) {
        const first = set.extracts[0].entries[0];
        const bySection = set.entriesForSection(first.sectionId);
        const atPath = set.entriesAtPath(first.path);
        _check(
          `${name}.entriesForSection`,
          bySection.length > 0 &&
            bySection.every((e) => e.sectionId === first.sectionId) &&
            bySection[0] === first,
        );
        _check(
          `${name}.entriesAtPath`,
          atPath.length > 0 &&
            atPath.every((e) => e.path === first.path) &&
            atPath[0] === first,
        );
      }
    } catch (e) {
      _check(name, false, `threw ${String(e)}`);
    }
  }
}

/**
 * The Stage-A gate (`codespecs_prompt.md` §4, A1–A5) over every case of
 * `codespecs_gate_cases.json`. A case key that is **present** overrides the
 * table default — `schema: null` means no schema, `gate: null` a catalogue
 * without gate tables — so presence is tested with `in`, not with `!= null`.
 */
function testCodeSpecsGate(meta) {
  const table = _readJson('codespecs_gate_cases.json');
  for (const c of table.cases) {
    const name = `codespecs.gate[${c.name}]`;
    try {
      const catalogJson = { ...table.catalog };
      const gate = 'gate' in c ? c.gate : table.gate;
      if (gate !== null && gate !== undefined) {
        catalogJson.gate = gate;
      }
      const schemaYaml = 'schema' in c ? c.schema : table.schema;
      const model = SpecModel.fromJson(c.model != null ? c.model : meta);
      const report = new CodeSpecsGate({
        model,
        document: _documentFromState(c.state),
        catalog: CodeSpecsAreaCatalog.fromJson(catalogJson),
        schema: schemaYaml == null ? null : DocSpecsSchema.fromYamlText(schemaYaml),
      }).run();
      const got = {
        passed: report.passed,
        results: report.results.map((r) => ({
          check: r.check.label,
          ran: r.ran,
          notRunReason: r.notRunReason,
          findings: r.findings.map((f) => ({
            code: f.code,
            location: f.location,
            message: f.message,
          })),
        })),
      };
      _check(name, _deepEqual(got, c.expect), _jsonMismatch(got, c.expect));
    } catch (e) {
      _check(name, false, `threw ${String(e)}`);
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
  testYamlReview(model, tree);
  testMarkdownExport(model);
  testMarkdownRoundTrip(model);
  testMarkdownMemoryLanding(model);
  testMarkdownImportRejections(model);
  testMarkdownApply(model);
  testAssembly();
  testAnnotations(model, tree);
  testInlineMarks(model, tree);
  testListMove(model);
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
  testCodeSpecsExtract(model, fixture);
  testCodeSpecsRecords();
  testCodeSpecsGate(_readJson('model.meta.json'));
  testCursorScript(model);
  testNodeCreation(model);
  testNodeCreationScript(model);
  testDocSpecs();
  testDocSpecsPath(model);
  testDocSpecsReplace();

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
