#!/usr/bin/env node
'use strict';

/**
 * Behavioural test for the **actually-committed** generated JS typed model.
 *
 * Unlike the runtime's facade golden test — which loads the small emitter
 * fixture — this suite requires the real, full `tom_som_javascript_v0` module
 * (3000+ classes) against the generic `tom_som_runtime` and proves the typed
 * facade is a faithful editing surface over the shared document (SOM §6):
 *
 *   * the real module loads cleanly against the runtime;
 *   * the `D00SolutionBlueprint` root is anchored at the `PD` segment;
 *   * a content leaf round-trips typed -> generic and generic -> typed;
 *   * a nested complex section derives its path under the root;
 *   * the generated model-version accessor returns `1.0`;
 *   * the instantiation-time version check (SOM §4.2) accepts an editable stamp and
 *     rejects a newer-minor / cross-major stamp;
 *   * aligned absence semantics (SOM §21): a section reads `isEmpty` until a
 *     value is written under it, typed `isEmpty` agrees with the generic
 *     `hasValuesUnder`, and `hasContent` gives a generic leaf the typed
 *     `.content` answer;
 *   * one-call loading (SOM §21): `loadYaml` collapses decode → loadJson →
 *     version-threading, `loadFile` delegates to `loadYaml`, and
 *     `SpecDocument.fromYaml` retains (or nulls) the parsed model version.
 *   * the live-document conformance case (YRD8 / dsa9): the shared Meridian
 *     sample round-trips (content + lists), its markdown twin validates clean
 *     under the SBP schema, and byPath / nav / id node operations resolve to the
 *     same meta identity — the guarantees the JS golden generator emits, pinned
 *     as a committed guard because `golden/` is git-ignored.
 *
 * Run with `node tests/som_v0_generated_test.js`; exit code 0 == all green.
 * The runtime is located by the `tomSom.runtimePath` recorded in `package.json`
 * so the test is portable across checkouts.
 */

const fs = require('fs');
const path = require('path');

const _PROJECT = path.dirname(__dirname); // tom_som_javascript_v0

const _runtimePath = path.resolve(
  _PROJECT,
  require(path.join(_PROJECT, 'package.json')).tomSom.runtimePath,
);
const {
  SpecDocument,
  SomVersionError,
  SpecSectionIdCollision,
  SomMetaKind,
  DocSpecsSchema,
  DocSpecsValidator,
  yamlEncode,
} = require(_runtimePath);
const m = require(path.join(_PROJECT, 'tom_som_javascript_v0.js'));

let _passed = 0;
const _failed = [];

function check(name, condition, detail) {
  if (condition) {
    _passed += 1;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

function testRootAndParity() {
  const doc = new SpecDocument();
  const pd = new m.D00SolutionBlueprint(doc);

  check('root.segment', pd.path === 'SBP', pd.path);

  // Typed write -> generic read.
  pd.content = 'A clear vision';
  check(
    'content.typed->generic',
    doc.content('SBP/content') === 'A clear vision',
    String(doc.content('SBP/content')),
  );

  // Generic write -> typed read.
  doc.setContent('SBP/content', 'Revised vision');
  check('content.generic->typed', pd.content === 'Revised vision', pd.content);

  // Unset leaf reads as empty string.
  check(
    'content.unset-empty',
    new m.D00SolutionBlueprint(new SpecDocument()).content === '',
  );

  // Nested complex section path derivation. The JS emitter preserves the
  // model's camelCase accessor names.
  check(
    'nested.path',
    pd.currentLandscape.path === 'SBP/currentLandscape',
    pd.currentLandscape.path,
  );

  // A generic value under the nested typed node is addressable via the
  // expected literal path (proves typed path == generic path).
  const headerPath = pd.documentControl.path;
  doc.setContent(`${headerPath}/probe`, 'x');
  check('nested.typed-path==generic', doc.content('SBP/documentControl/probe') === 'x');
}

function testModelVersion() {
  check(
    'version.classattr',
    m.D00SolutionBlueprint.MODEL_VERSION === '1.0',
    m.D00SolutionBlueprint.MODEL_VERSION,
  );
  const pd = new m.D00SolutionBlueprint(new SpecDocument());
  check(
    'version.accessor',
    pd.objectModelVersion === '1.0',
    pd.objectModelVersion,
  );
}

function testVersionCheck() {
  // New / equal-stamp document → accepted.
  try {
    new m.D00SolutionBlueprint(new SpecDocument());
    new m.D00SolutionBlueprint(new SpecDocument(), '1.0');
    check('version.editable', true);
  } catch (e) {
    check('version.editable', false, String(e));
  }

  // Newer minor → rejected.
  try {
    new m.D00SolutionBlueprint(new SpecDocument(), '1.1');
    check('version.newer-rejected', false, 'expected SomVersionError');
  } catch (e) {
    check('version.newer-rejected', e instanceof SomVersionError, String(e));
  }

  // Different major → rejected.
  try {
    new m.D00SolutionBlueprint(new SpecDocument(), '2.0');
    check('version.cross-major-rejected', false, 'expected SomVersionError');
  } catch (e) {
    check(
      'version.cross-major-rejected',
      e instanceof SomVersionError,
      String(e),
    );
  }
}

// A fresh operationalMetrics list (a `@SectionIdPattern` list, CUOPME-OPER-xxx)
// anchored under the SBP root.
function freshLandscape() {
  return new m.D00SolutionBlueprint(new SpecDocument()).currentLandscape;
}

// month 3 → C, day 5 → E (JS months are 0-based, so March is 2).
const MAR5 = new Date(2026, 2, 5);

// Criteria 3–6: pattern-generated section ids, override + uniqueness, and the
// delete-renumbering rules, all through the real generated pattern list.
function testSectionIds() {
  // Criterion 3 + 4: generated id = prefix + two-letter-date + within-day number.
  {
    const csa = freshLandscape();
    const id1 = csa.operationalMetrics.add(null, MAR5).$sectionId;
    const id2 = csa.operationalMetrics.add(null, MAR5).$sectionId;
    check('sid.gen.first', id1 === 'CUOPME-OPER-CE1', id1);
    check('sid.gen.second', id2 === 'CUOPME-OPER-CE2', id2);
  }

  // Criterion 5: override to an arbitrary-but-unique suffix succeeds; a
  // duplicate raises SpecSectionIdCollision.
  {
    const csa = freshLandscape();
    csa.operationalMetrics.add(null, MAR5); // CUOPME-OPER-CE1
    const second = csa.operationalMetrics.add(null, MAR5);
    second.$sectionId = 'CUOPME-OPER-ZZ9';
    check(
      'sid.override.unique',
      csa.operationalMetrics.sectionIds.includes('CUOPME-OPER-ZZ9'),
      String(csa.operationalMetrics.sectionIds),
    );
    try {
      csa.operationalMetrics.at(0).$sectionId = 'CUOPME-OPER-ZZ9';
      check('sid.override.collision', false, 'expected SpecSectionIdCollision');
    } catch (e) {
      check('sid.override.collision', e instanceof SpecSectionIdCollision, String(e));
    }
    // Add-time override collision also raises.
    try {
      csa.operationalMetrics.add('CUOPME-OPER-ZZ9');
      check('sid.add.collision', false, 'expected SpecSectionIdCollision');
    } catch (e) {
      check('sid.add.collision', e instanceof SpecSectionIdCollision, String(e));
    }
  }

  // Criterion 6a: deleting a *middle* item does NOT renumber — a later same-day
  // add takes max+1, so numbering may stay non-consecutive.
  {
    const csa = freshLandscape();
    csa.operationalMetrics.add(null, MAR5); // CE1
    csa.operationalMetrics.add(null, MAR5); // CE2
    csa.operationalMetrics.add(null, MAR5); // CE3
    csa.operationalMetrics.removeAt(1); // remove CE2
    check(
      'sid.delete-middle.no-renumber',
      _arraysEqual(csa.operationalMetrics.sectionIds, ['CUOPME-OPER-CE1', 'CUOPME-OPER-CE3']),
      String(csa.operationalMetrics.sectionIds),
    );
    const next = csa.operationalMetrics.add(null, MAR5).$sectionId;
    check('sid.delete-middle.next', next === 'CUOPME-OPER-CE4', next);
  }

  // Criterion 6b: deleting the *last* item frees its number; a same-day add
  // reuses it.
  {
    const csa = freshLandscape();
    csa.operationalMetrics.add(null, MAR5); // CE1
    csa.operationalMetrics.add(null, MAR5); // CE2
    csa.operationalMetrics.add(null, MAR5); // CE3
    csa.operationalMetrics.removeAt(2); // remove last (CE3)
    const reused = csa.operationalMetrics.add(null, MAR5).$sectionId;
    check('sid.delete-last.reuse', reused === 'CUOPME-OPER-CE3', reused);
  }
}

// SOM §21: aligned absence semantics — mirrors the Dart reference suite.
function testAbsenceSemantics() {
  // 1. A section reads isEmpty until any value is written under it (subtree).
  {
    const doc = new SpecDocument();
    const sbp = new m.D00SolutionBlueprint(doc);
    check('absence.section.empty-initial', sbp.requirements.isEmpty === true);
    sbp.requirements.content = 'Some requirements';
    check('absence.section.filled', sbp.requirements.isEmpty === false);
    sbp.requirements.content = '';
    check('absence.section.emptied-again', sbp.requirements.isEmpty === true);
  }

  // 2. Typed isEmpty and generic hasValuesUnder agree.
  {
    const doc = new SpecDocument();
    const sbp = new m.D00SolutionBlueprint(doc);
    const p = sbp.requirements.path;
    check(
      'absence.isEmpty==!hasValuesUnder.initial',
      sbp.requirements.isEmpty === !doc.hasValuesUnder(p),
    );
    doc.setContent(`${p}/content`, 'x');
    check(
      'absence.isEmpty==!hasValuesUnder.filled',
      sbp.requirements.isEmpty === !doc.hasValuesUnder(p),
    );
    check('absence.isEmpty.now-false', sbp.requirements.isEmpty === false);
  }

  // 3. hasContent gives the generic leaf path the typed .content answer.
  {
    const doc = new SpecDocument();
    const sbp = new m.D00SolutionBlueprint(doc);
    const leaf = `${sbp.requirements.path}/content`;
    check('absence.typed-empty', sbp.requirements.content === '');
    check('absence.hasContent-false', doc.hasContent(leaf) === false);
    sbp.requirements.content = 'Filled';
    check(
      'absence.typed-nonempty==hasContent',
      (sbp.requirements.content !== '') === doc.hasContent(leaf),
    );
    check('absence.hasContent-true', doc.hasContent(leaf) === true);
  }
}

// SOM §21: one-call loading — mirrors the Dart reference suite. The suite runs
// from the project root, so the sample is reached via the sibling conformance
// project.
const _samplePath =
  '../tom_som_conformance/samples/meridian_order_management.docspecs.yaml';

function testOneCallLoading() {
  // 4. loadYaml collapses decode → loadJson → thread-version to one call.
  {
    const yaml = fs.readFileSync(_samplePath, 'utf8');

    // The former multi-step incantation: parse into a document, then construct
    // the typed root over it with the retained model version.
    const decoded = SpecDocument.fromYaml(yaml, m.d00SolutionBlueprintMetaTree);
    const manual = new m.D00SolutionBlueprint(decoded, decoded.modelVersion);

    // The one-call convenience.
    const oneCall = m.D00SolutionBlueprint.loadYaml(yaml);

    check(
      'load.yaml.modelVersion',
      oneCall.doc.modelVersion === decoded.modelVersion,
      oneCall.doc.modelVersion,
    );
    check('load.yaml.content', oneCall.content === manual.content);
    check(
      'load.yaml.nested-content',
      oneCall.introductionAndScope.goals.content ===
        manual.introductionAndScope.goals.content,
    );
    check(
      'load.yaml.list-length',
      oneCall.currentLandscape.operationalMetrics.length ===
        manual.currentLandscape.operationalMetrics.length,
    );
  }

  // 5. loadFile reads the file then delegates to loadYaml.
  {
    const fromFile = m.D00SolutionBlueprint.loadFile(_samplePath);
    const fromYaml = m.D00SolutionBlueprint.loadYaml(
      fs.readFileSync(_samplePath, 'utf8'),
    );
    check(
      'load.file.modelVersion',
      fromFile.doc.modelVersion === fromYaml.doc.modelVersion,
    );
    check('load.file.content', fromFile.content === fromYaml.content);
  }

  // 6. SpecDocument.fromYaml retains the parsed model version. The wire format
  // is hierarchical v2, so the fixture yaml is built via yamlEncode (mirrors
  // the Dart suite's buildV2Yaml helper).
  const buildV2Yaml = (modelVersion) => {
    const d = new SpecDocument();
    d.setContent('SBP/content', 'Hello');
    return yamlEncode(d, m.d00SolutionBlueprintMetaTree, modelVersion);
  };
  {
    const yaml = buildV2Yaml('1.0');
    const doc = SpecDocument.fromYaml(yaml, m.d00SolutionBlueprintMetaTree);
    check('load.fromYaml.modelVersion', doc.modelVersion === '1.0', doc.modelVersion);
    check(
      'load.fromYaml.content',
      doc.content('SBP/content') === 'Hello',
      doc.content('SBP/content'),
    );
  }

  // 7. A document with no modelVersion stamp loads with a null stamp.
  {
    const yaml = buildV2Yaml(null);
    const doc = SpecDocument.fromYaml(yaml, m.d00SolutionBlueprintMetaTree);
    check('load.no-stamp.null', doc.modelVersion === null, String(doc.modelVersion));
    try {
      m.D00SolutionBlueprint.loadYaml(yaml);
      check('load.no-stamp.editable', true);
    } catch (e) {
      check('load.no-stamp.editable', false, String(e));
    }
  }
}

// SOM §21: the structural `canHaveContent` predicate — mirrors the Dart
// reference suite. It answers "does this section TYPE declare the standard
// `content` text leaf?" at the type level, without probing `.content` or the
// document.
function testCanHaveContent() {
  const sbp = new m.D00SolutionBlueprint(new SpecDocument());

  // Goals declares the standard `content` leaf.
  check(
    'canHaveContent.content-bearing-true',
    sbp.introductionAndScope.goals.canHaveContent === true,
    String(sbp.introductionAndScope.goals.canHaveContent),
  );

  // SystemsToReplace holds only child sections — no `content` leaf.
  check(
    'canHaveContent.container-only-false',
    sbp.introductionAndScope.systemsToReplace.canHaveContent === false,
    String(sbp.introductionAndScope.systemsToReplace.canHaveContent),
  );

  // The document root itself has a content leaf.
  check(
    'canHaveContent.root-true',
    new m.D00SolutionBlueprint(new SpecDocument()).canHaveContent === true,
    String(new m.D00SolutionBlueprint(new SpecDocument()).canHaveContent),
  );

  // Structural, not state — independent of whether content is written.
  {
    const goals = sbp.introductionAndScope.goals;
    check('canHaveContent.structural.before', goals.canHaveContent === true);
    goals.content = 'Grow revenue';
    check('canHaveContent.structural.after', goals.canHaveContent === true);
    // A filled container-only sibling still reports false.
    check(
      'canHaveContent.structural.sibling-false',
      sbp.introductionAndScope.systemsToReplace.canHaveContent === false,
    );
  }
}

// Live-document conformance case durability (YRD8 / dsa9). The golden/ tree is
// git-ignored, so this committed guard pins the three live-document guarantees
// the JS golden generator emits over the shared Meridian sample — a regression
// fails `node tests/som_v0_generated_test.js`, not only a full nine-toolchain
// golden run. Mirrors the Dart (dsa7) and Python (dsa8) durability guards.
function testLiveDocumentCase() {
  const sample =
    '../tom_som_conformance/samples/meridian_order_management.docspecs.yaml';
  const sampleMd =
    '../tom_som_conformance/samples/meridian_order_management.md';
  const schemaPath =
    'schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml';
  const tree = m.d00SolutionBlueprintMetaTree;

  // 1) Round-trip: decode -> encode -> decode is stable over content + lists.
  const original = SpecDocument.fromFile(sample, tree);
  const reEncoded = yamlEncode(original, tree, original.modelVersion);
  const roundTripped = SpecDocument.fromYaml(reEncoded, tree);
  check(
    'live.roundtrip.version',
    roundTripped.modelVersion === original.modelVersion,
    String(roundTripped.modelVersion),
  );
  const origContent = Array.from(original.contentPaths).sort();
  const rtContent = Array.from(roundTripped.contentPaths).sort();
  check('live.roundtrip.content-paths', _arraysEqual(rtContent, origContent));
  check(
    'live.roundtrip.content-values',
    origContent.every((p) => roundTripped.content(p) === original.content(p)),
  );
  const origLists = Array.from(original.listPaths).sort();
  const rtLists = Array.from(roundTripped.listPaths).sort();
  check('live.roundtrip.list-paths', _arraysEqual(rtLists, origLists));
  check(
    'live.roundtrip.list-items',
    origLists.every((p) =>
      _arraysEqual(roundTripped.listItems(p), original.listItems(p))),
  );

  // 2) Validation: the markdown twin is clean under the SBP schema.
  const schema = DocSpecsSchema.fromYamlText(fs.readFileSync(schemaPath, 'utf8'));
  const violations = new DocSpecsValidator(schema).validateMarkdown(
    fs.readFileSync(sampleMd, 'utf8'),
  );
  check('live.validate.root', schema.rootSectionId === 'SBP', String(schema.rootSectionId));
  check('live.validate.no-warnings', schema.warnings.length === 0, String(schema.warnings.length));
  check('live.validate.no-violations', violations.length === 0, String(violations.length));

  // 3) Node operations: byPath / nav / id resolve to the same meta identity.
  const listByPath = tree.byPath('SBP/currentLandscape/CUOPME-OPER-LST');
  check('live.node.by-path', listByPath != null);
  check('live.node.kind-list', listByPath != null && listByPath.kind === SomMetaKind.LIST);
  const navRef = m.d00SolutionBlueprint.currentLandscape.operationalMetrics;
  check('live.node.nav-path', navRef.path === 'SBP/currentLandscape/CUOPME-OPER-LST', navRef.path);
  check('live.node.nav-identity', navRef.meta === listByPath);
  const idRef = m.SBP.RVENT_REVS_LST.item(0);
  const navItem = m.d00SolutionBlueprint.documentControl.revisionHistory.item(0);
  check('live.node.id-path', idRef.path === navItem.path, idRef.path);
  check('live.node.id-identity', idRef.meta === navItem.meta);
}

function _arraysEqual(a, b) {
  if (a.length !== b.length) {
    return false;
  }
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) {
      return false;
    }
  }
  return true;
}

function main() {
  testRootAndParity();
  testModelVersion();
  testVersionCheck();
  testSectionIds();
  testAbsenceSemantics();
  testOneCallLoading();
  testCanHaveContent();
  testLiveDocumentCase();

  const total = _passed + _failed.length;
  if (_failed.length > 0) {
    console.log(`FAIL: ${_failed.length}/${total} checks failed`);
    for (const f of _failed) {
      console.log(`  - ${f}`);
    }
    return 1;
  }
  console.log(`OK: ${total} checks passed`);
  return 0;
}

if (require.main === module) {
  process.exit(main());
}
