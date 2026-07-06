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
 *   * the `D00SolutionBlueprint` root is anchored at the `PD` segment;
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

import {
  SpecDocument,
  SomVersionError,
  SpecSectionIdCollision,
} from 'tom_som_typescript_runtime';
import { D00SolutionBlueprint } from '../tom_som_typescript_v0';

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
  const pd = new D00SolutionBlueprint(doc);

  check('root.segment', pd.path === 'SBP', pd.path);

  // Typed write → generic read.
  pd.content = 'A clear vision';
  check(
    'content.typed->generic',
    doc.content('SBP/content') === 'A clear vision',
    String(doc.content('SBP/content')),
  );

  // Generic write → typed read.
  doc.setContent('SBP/content', 'Revised vision');
  check('content.generic->typed', pd.content === 'Revised vision', pd.content);

  // Unset leaf reads as empty string.
  check(
    'content.unset-empty',
    new D00SolutionBlueprint(new SpecDocument()).content === '',
  );

  // Nested complex section path derivation. The TS emitter preserves the
  // model's camelCase accessor names.
  check(
    'nested.path',
    pd.currentLandscape.path === 'SBP/currentLandscape',
    pd.currentLandscape.path,
  );

  // A generic value under the nested typed node is addressable via the expected
  // literal path (proves typed path == generic path).
  const headerPath = pd.documentControl.path;
  doc.setContent(`${headerPath}/probe`, 'x');
  check('nested.typed-path==generic', doc.content('SBP/documentControl/probe') === 'x');
}

function testModelVersion(): void {
  check(
    'version.classattr',
    D00SolutionBlueprint.MODEL_VERSION === '0.0',
    D00SolutionBlueprint.MODEL_VERSION,
  );
  const pd = new D00SolutionBlueprint(new SpecDocument());
  check('version.accessor', pd.objectModelVersion === '0.0', pd.objectModelVersion);
}

function testVersionCheck(): void {
  // New / equal-stamp document → accepted.
  try {
    new D00SolutionBlueprint(new SpecDocument());
    new D00SolutionBlueprint(new SpecDocument(), '0.0');
    check('version.editable', true);
  } catch (e) {
    check('version.editable', false, String(e));
  }

  // Newer minor → rejected.
  try {
    new D00SolutionBlueprint(new SpecDocument(), '0.1');
    check('version.newer-rejected', false, 'expected SomVersionError');
  } catch (e) {
    check('version.newer-rejected', e instanceof SomVersionError, String(e));
  }

  // Different major → rejected.
  try {
    new D00SolutionBlueprint(new SpecDocument(), '1.0');
    check('version.cross-major-rejected', false, 'expected SomVersionError');
  } catch (e) {
    check('version.cross-major-rejected', e instanceof SomVersionError, String(e));
  }
}

// A fresh operationalMetrics list (a `@SectionIdPattern` list, CUOPME-OPER-xxx)
// anchored under the SBP root.
function freshLandscape() {
  return new D00SolutionBlueprint(new SpecDocument()).currentLandscape;
}

// month 3 → C, day 5 → E (JS months are 0-based, so March is 2).
const MAR5 = new Date(2026, 2, 5);

// Criteria 3–6: pattern-generated section ids, override + uniqueness, and the
// delete-renumbering rules, all through the real generated pattern list.
function testSectionIds(): void {
  // Criterion 3 + 4: generated id = prefix + two-letter-date + within-day number.
  {
    const csa = freshLandscape();
    const id1 = csa.operationalMetrics.add(null, MAR5).$sectionId;
    const id2 = csa.operationalMetrics.add(null, MAR5).$sectionId;
    check('sid.gen.first', id1 === 'CUOPME-OPER-CE1', String(id1));
    check('sid.gen.second', id2 === 'CUOPME-OPER-CE2', String(id2));
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
      _arraysEqual(csa.operationalMetrics.sectionIds, [
        'CUOPME-OPER-CE1',
        'CUOPME-OPER-CE3',
      ]),
      String(csa.operationalMetrics.sectionIds),
    );
    const next = csa.operationalMetrics.add(null, MAR5).$sectionId;
    check('sid.delete-middle.next', next === 'CUOPME-OPER-CE4', String(next));
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
    check('sid.delete-last.reuse', reused === 'CUOPME-OPER-CE3', String(reused));
  }
}

function _arraysEqual(a: string[], b: string[]): boolean {
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

function main(): number {
  testRootAndParity();
  testModelVersion();
  testVersionCheck();
  testSectionIds();

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
