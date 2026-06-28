/**
 * Behavioural test for the **actually-committed** generated TypeScript typed
 * model.
 *
 * Unlike the runtime's facade golden test — which compiles the small emitter
 * fixture — this suite requires the real, full `tom_som_typescript_v0` module
 * (3000+ classes) against the generic `tom_som_typescript_runtime` and proves
 * the typed facade is a faithful editing surface over the shared document
 * (spec §3):
 *
 *   * the real module compiles + loads cleanly against the runtime;
 *   * the `ProjectDefinition` root is anchored at the `PD` segment;
 *   * a content leaf round-trips typed → generic and generic → typed;
 *   * a nested complex section derives its path under the root;
 *   * the generated model-version accessor returns `0.0`;
 *   * the instantiation-time version check (§2.2) accepts an editable stamp and
 *     rejects a newer-minor / cross-major stamp.
 *
 * Build with `tsc` then run `node dist/tests/som_v0_generated_test.js`; exit
 * code 0 == all green. The runtime resolves through the bare specifier
 * `tom_som_typescript_runtime` (wired by the `file:` dependency in
 * `package.json`), so the test is portable across checkouts.
 */

import { SpecDocument, SomVersionError } from 'tom_som_typescript_runtime';
import { ProjectDefinition } from '../tom_som_typescript_v0';

let _passed = 0;
const _failed: string[] = [];

function check(name: string, condition: boolean, detail?: string): void {
  if (condition) {
    _passed += 1;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

function testRootAndParity(): void {
  const doc = new SpecDocument();
  const pd = new ProjectDefinition(doc);

  check('root.segment', pd.path === 'PD', pd.path);

  // Typed write → generic read.
  pd.content = 'A clear vision';
  check(
    'content.typed->generic',
    doc.content('PD/content') === 'A clear vision',
    String(doc.content('PD/content')),
  );

  // Generic write → typed read.
  doc.setContent('PD/content', 'Revised vision');
  check('content.generic->typed', pd.content === 'Revised vision', pd.content);

  // Unset leaf reads as empty string.
  check(
    'content.unset-empty',
    new ProjectDefinition(new SpecDocument()).content === '',
  );

  // Nested complex section path derivation. The TS emitter preserves the
  // model's camelCase accessor names.
  check(
    'nested.path',
    pd.currentStateAnalysis.path === 'PD/currentStateAnalysis',
    pd.currentStateAnalysis.path,
  );

  // A generic value under the nested typed node is addressable via the expected
  // literal path (proves typed path == generic path).
  const headerPath = pd.header.path;
  doc.setContent(`${headerPath}/probe`, 'x');
  check('nested.typed-path==generic', doc.content('PD/header/probe') === 'x');
}

function testModelVersion(): void {
  check(
    'version.classattr',
    ProjectDefinition.MODEL_VERSION === '0.0',
    ProjectDefinition.MODEL_VERSION,
  );
  const pd = new ProjectDefinition(new SpecDocument());
  check('version.accessor', pd.objectModelVersion === '0.0', pd.objectModelVersion);
}

function testVersionCheck(): void {
  // New / equal-stamp document → accepted.
  try {
    new ProjectDefinition(new SpecDocument());
    new ProjectDefinition(new SpecDocument(), '0.0');
    check('version.editable', true);
  } catch (e) {
    check('version.editable', false, String(e));
  }

  // Newer minor → rejected.
  try {
    new ProjectDefinition(new SpecDocument(), '0.1');
    check('version.newer-rejected', false, 'expected SomVersionError');
  } catch (e) {
    check('version.newer-rejected', e instanceof SomVersionError, String(e));
  }

  // Different major → rejected.
  try {
    new ProjectDefinition(new SpecDocument(), '1.0');
    check('version.cross-major-rejected', false, 'expected SomVersionError');
  } catch (e) {
    check('version.cross-major-rejected', e instanceof SomVersionError, String(e));
  }
}

function main(): number {
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
