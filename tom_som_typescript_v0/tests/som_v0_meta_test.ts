/**
 * Agreement suite for the generated TypeScript metadata module
 * (`tom_som_typescript_v0_meta.ts`, SOM §7.2/§8) — the TS port of the Dart
 * facade's `test/generated_meta_test.dart` (and the JavaScript
 * `som_v0_meta_test.js`). Two guarantees over the *real* committed model:
 *
 *   1. EXHAUSTIVE TREE AGREEMENT — for every one of the document roots the
 *      generated static `SomMetaTree` is field-for-field identical (via
 *      `somMetaNodeDiff`) to the tree `buildSomMetaTree` derives from the
 *      committed `meta/spec_model.meta.json` at runtime. Since the emitter
 *      writes the dot-notation / ID-tree accessor paths from the same node
 *      walk, this also anchors every `.path` the accessors can produce.
 *   2. SURFACE AGREEMENT — the dot-notation entry points, the ID-tree entry
 *      points, and the dynamic `byPath` lookups all resolve to the *same*
 *      node instances for representative positions (root, nested section,
 *      content leaf, list, list element, hoisted id).
 *
 * Build with `tsc` then run `node dist/tests/som_v0_meta_test.js`; exit code
 * 0 == all green. The runtime resolves through the bare specifier
 * `tom_som_typescript_runtime` (wired by the `file:` dependency in
 * `package.json`), so the test is portable across checkouts.
 */

import * as fs from 'fs';
import * as path from 'path';

import {
  SomMetaRef,
  SomMetaTree,
  SpecModel,
  buildSomMetaTree,
  somMetaNodeDiff,
} from 'tom_som_typescript_runtime';
import * as m from '../tom_som_typescript_v0';

// Compiled to dist/tests/, so the project root is two levels up.
const _PROJECT = path.dirname(path.dirname(__dirname)); // tom_som_typescript_v0

let _passed = 0;
const _failed: string[] = [];

function check(name: string, condition: boolean, detail?: string): void {
  if (condition) {
    _passed += 1;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

// Every generated per-root static tree, keyed by its root type.
const GENERATED_TREES: Record<string, SomMetaTree> = {
  D00SolutionBlueprint: m.d00SolutionBlueprintMetaTree,
  D01CurrentLandscapeAssessment: m.d01CurrentLandscapeAssessmentMetaTree,
  D02TargetOperatingModel: m.d02TargetOperatingModelMetaTree,
  D03InformationModel: m.d03InformationModelMetaTree,
  D04RequirementsSpecification: m.d04RequirementsSpecificationMetaTree,
  D05InteractionScenarios: m.d05InteractionScenariosMetaTree,
  D06ArchitectureTechnologySpecification:
    m.d06ArchitectureTechnologySpecificationMetaTree,
  D07IntegrationInterfaceSpecification:
    m.d07IntegrationInterfaceSpecificationMetaTree,
  D08SecurityAccessSpecification: m.d08SecurityAccessSpecificationMetaTree,
  D09ExperienceDesignSpecification: m.d09ExperienceDesignSpecificationMetaTree,
  D10QualityAcceptancePlan: m.d10QualityAcceptancePlanMetaTree,
  D11DeliveryRoadmap: m.d11DeliveryRoadmapMetaTree,
  D12TransitionRolloutPlan: m.d12TransitionRolloutPlanMetaTree,
  D13CodeSpecsProjection: m.d13CodeSpecsProjectionMetaTree,
};

function loadModel(): SpecModel {
  const metaPath = path.join(_PROJECT, 'meta', 'spec_model.meta.json');
  return SpecModel.fromJson(JSON.parse(fs.readFileSync(metaPath, 'utf8')));
}

function _setsEqual(a: Set<string>, b: Set<string>): boolean {
  if (a.size !== b.size) return false;
  for (const x of a) {
    if (!b.has(x)) return false;
  }
  return true;
}

function testGeneratedTreesAgreeWithBridge(model: SpecModel): void {
  check(
    'trees.covers-model-roots',
    _setsEqual(
      new Set(Object.keys(GENERATED_TREES)),
      new Set(model.roots.map((r) => r.type)),
    ),
    Object.keys(GENERATED_TREES).sort().join(','),
  );
  for (const [rootType, tree] of Object.entries(GENERATED_TREES)) {
    const bridge = buildSomMetaTree(model, rootType);
    const diff = somMetaNodeDiff(tree.root, bridge.root);
    check(`trees.agree.${rootType}`, diff === null, diff || '');
  }
}

function testDotNotationSurface(): void {
  check('dot.root', m.d00SolutionBlueprint.path === 'SBP');
  check(
    'dot.section',
    m.d00SolutionBlueprint.introductionAndScope.path ===
      'SBP/introductionAndScope',
  );
  check(
    'dot.leaf',
    m.d00SolutionBlueprint.requirements.content.path ===
      'SBP/requirements/content',
  );
  check(
    'dot.nested-leaf',
    m.d00SolutionBlueprint.introductionAndScope.goals.content.path ===
      'SBP/introductionAndScope/goals/content',
  );

  // .meta resolves to the same node byPath finds.
  const viaDot = m.d00SolutionBlueprint.introductionAndScope.meta;
  const viaPath = m.d00SolutionBlueprintMetaTree.byPath(
    'SBP/introductionAndScope',
  );
  check('dot.meta-is-byPath', viaDot === viaPath);
  check('dot.meta-member', viaDot.memberName === 'introductionAndScope');

  // List positions expose item() with element accessors.
  const revs = m.d00SolutionBlueprint.documentControl.revisionHistory;
  check(
    'dot.list',
    revs.path === 'SBP/documentControl/RVHST-REVS-LST',
    revs.path,
  );
  check(
    'dot.list-item',
    revs.item(3).path ===
      'SBP/documentControl/RVHST-REVS-LST-3',
    revs.item(3).path,
  );
  // The list node's metadata carries the section-id pattern.
  check('dot.list-pattern', revs.meta.sectionIdPattern !== null);

  // A second root has its own entry point and segment.
  check('dot.second-root', m.d01CurrentLandscapeAssessment.path !== 'SBP');
  check(
    'dot.second-root-meta',
    m.d01CurrentLandscapeAssessment.meta ===
      m.d01CurrentLandscapeAssessmentMetaTree.root,
  );
}

function testIdTreeSurface(): void {
  // The Id root shares the dot root position.
  check('id.root-path', m.SBP.path === m.d00SolutionBlueprint.path);
  check('id.root-meta', m.SBP.meta === m.d00SolutionBlueprint.meta);

  // A hoisted list id agrees with the dot-notation position. RVHST_REVS_LST
  // is hoisted onto the root Id class through the id-less
  // documentControl/revisionHistory members.
  const revs = m.d00SolutionBlueprint.documentControl.revisionHistory;
  check('id.hoisted-path', m.SBP.RVHST_REVS_LST.path === revs.path);
  check('id.hoisted-meta', m.SBP.RVHST_REVS_LST.meta === revs.meta);
  check(
    'id.hoisted-item',
    m.SBP.RVHST_REVS_LST.item(0).path === revs.item(0).path,
  );

  // Every root has a distinct Id entry point at its own segment.
  const idRoots: Record<string, SomMetaRef> = {
    D00SolutionBlueprint: m.SBP,
    D01CurrentLandscapeAssessment: m.CLA,
    D02TargetOperatingModel: m.TOM,
    D03InformationModel: m.IFM,
    D04RequirementsSpecification: m.RSP,
    D05InteractionScenarios: m.ISC,
    D06ArchitectureTechnologySpecification: m.ATS,
    D07IntegrationInterfaceSpecification: m.IIS,
    D08SecurityAccessSpecification: m.SAS,
    D09ExperienceDesignSpecification: m.XDS,
    D10QualityAcceptancePlan: m.QAP,
    D11DeliveryRoadmap: m.DRM,
    D12TransitionRolloutPlan: m.TRP,
    D13CodeSpecsProjection: m.CGP,
  };
  check(
    'id.roots-cover',
    _setsEqual(
      new Set(Object.keys(idRoots)),
      new Set(Object.keys(GENERATED_TREES)),
    ),
  );
  for (const [rootType, ref] of Object.entries(idRoots)) {
    const tree = GENERATED_TREES[rootType];
    check(
      `id.segment.${rootType}`,
      ref.path === tree.root.sectionId,
      `${ref.path} != ${tree.root.sectionId}`,
    );
    check(`id.meta.${rootType}`, ref.meta === tree.root);
  }
}

function main(): number {
  const model = loadModel();
  testGeneratedTreesAgreeWithBridge(model);
  testDotNotationSurface();
  testIdTreeSurface();

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
