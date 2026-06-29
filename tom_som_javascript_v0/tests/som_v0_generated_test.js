#!/usr/bin/env node
'use strict';

/**
 * Behavioural test for the **actually-committed** generated JS typed model.
 *
 * Unlike the runtime's facade golden test — which loads the small emitter
 * fixture — this suite requires the real, full `tom_som_javascript_v0` module
 * (3000+ classes) against the generic `tom_som_runtime` and proves the typed
 * facade is a faithful editing surface over the shared document (spec §3):
 *
 *   * the real module loads cleanly against the runtime;
 *   * the `D00SolutionBlueprint` root is anchored at the `PD` segment;
 *   * a content leaf round-trips typed -> generic and generic -> typed;
 *   * a nested complex section derives its path under the root;
 *   * the generated model-version accessor returns `0.0`;
 *   * the instantiation-time version check (§2.2) accepts an editable stamp and
 *     rejects a newer-minor / cross-major stamp.
 *
 * Run with `node tests/som_v0_generated_test.js`; exit code 0 == all green.
 * The runtime is located by the `tomSom.runtimePath` recorded in `package.json`
 * so the test is portable across checkouts.
 */

const path = require('path');

const _PROJECT = path.dirname(__dirname); // tom_som_javascript_v0

const _runtimePath = path.resolve(
  _PROJECT,
  require(path.join(_PROJECT, 'package.json')).tomSom.runtimePath,
);
const { SpecDocument, SomVersionError } = require(_runtimePath);
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
    m.D00SolutionBlueprint.MODEL_VERSION === '0.0',
    m.D00SolutionBlueprint.MODEL_VERSION,
  );
  const pd = new m.D00SolutionBlueprint(new SpecDocument());
  check(
    'version.accessor',
    pd.objectModelVersion === '0.0',
    pd.objectModelVersion,
  );
}

function testVersionCheck() {
  // New / equal-stamp document → accepted.
  try {
    new m.D00SolutionBlueprint(new SpecDocument());
    new m.D00SolutionBlueprint(new SpecDocument(), '0.0');
    check('version.editable', true);
  } catch (e) {
    check('version.editable', false, String(e));
  }

  // Newer minor → rejected.
  try {
    new m.D00SolutionBlueprint(new SpecDocument(), '0.1');
    check('version.newer-rejected', false, 'expected SomVersionError');
  } catch (e) {
    check('version.newer-rejected', e instanceof SomVersionError, String(e));
  }

  // Different major → rejected.
  try {
    new m.D00SolutionBlueprint(new SpecDocument(), '1.0');
    check('version.cross-major-rejected', false, 'expected SomVersionError');
  } catch (e) {
    check(
      'version.cross-major-rejected',
      e instanceof SomVersionError,
      String(e),
    );
  }
}

function main() {
  testRootAndParity();
  testModelVersion();
  testVersionCheck();

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
