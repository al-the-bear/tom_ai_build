#!/usr/bin/env node
/**
 * TomSpecs sample — author a Solution Blueprint end to end (JavaScript).
 *
 * The JavaScript port of `../bin/author_solution_blueprint.dart`: the same six
 * steps, the same document, the same output (`../expected_output.txt`).
 *
 * Run (from this folder; see README.md):  npm install && node index.js
 *
 * Six steps, in the order a real authoring task takes them:
 *
 *   1. open a fresh document and a typed root
 *   2. author a small but coherent Solution Blueprint
 *   3. serialise both renditions — yaml (SOM §12) and markdown (SOM §11)
 *   4. round-trip the yaml back through the one-call typed loader and prove
 *      the reload is equal to what was written
 *   5. validate on the instance tier
 *   6. break one rule deliberately and read the diagnostic
 *
 * This sample is the NARRATIVE. The individual access styles each have their
 * own focused example in the facade package (`tom_som_javascript_v0/examples/`),
 * and this does not re-explain them.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const {
  SpecDocument,
  SpecModel,
  validateDocument,
  yamlEncode,
} = require('tom_som_javascript_runtime');
const {
  D00SolutionBlueprint,
  d00SolutionBlueprintMetaTree,
} = require('tom_som_javascript_v0');

function main() {
  const outDir = 'build';
  fs.mkdirSync(outDir, { recursive: true });

  // -------------------------------------------------------------- step 1
  // A typed root over a fresh, empty document. Constructing the root also
  // runs the instantiation-time model-version check (SOM §4.2): an unstamped
  // document is editable, a document from a newer model is refused.
  const doc = new SpecDocument();
  const sbp = new D00SolutionBlueprint(doc);

  console.log('1. A typed root over an empty document');
  console.log(`   object model version : ${sbp.objectModelVersion}`);
  console.log(`   root path            : ${sbp.path}`);
  console.log('');

  // -------------------------------------------------------------- step 2
  // Author. Every write below goes through a NAMED accessor — no string
  // paths — and lands in the same path-keyed store the generic API reads.
  console.log('2. Authoring, printing each section id as it is written');

  sbp.content = 'Unify three legacy order systems behind one customer record.';
  wrote(sbp.path, 'the blueprint itself');

  const intro = sbp.introductionAndScope;
  intro.content = 'Replace per-region order intake with a single pipeline.';
  wrote(intro.path, 'introduction and scope');

  const landscape = sbp.currentLandscape;
  landscape.content =
    'Three systems, no shared customer record, manual reconciliation.';
  wrote(landscape.path, 'the current landscape');

  // A list section. `add()` appends an item and returns it typed.
  const metrics = landscape.operationalMetrics;
  metrics.add().content = 'Average order turnaround: 4.2 days.';
  metrics.add().content = 'Manual reconciliation: about 12 hours a week.';
  wrote(metrics.listPath, `${metrics.length} operational metrics`);

  console.log('');

  // -------------------------------------------------------------- step 3
  // Both renditions of the same document. They are two encodings of one
  // store, not two documents — which is why step 4 can round-trip either.
  //
  // `toMarkdown` and the validator both need a whole SpecModel: the facade
  // ships it as `meta/spec_model.meta.json` (its `./meta` export).
  const model = SpecModel.fromJson(require('tom_som_javascript_v0/meta'));

  const yaml = yamlEncode(doc, d00SolutionBlueprintMetaTree, model.modelVersionString);
  const markdown = doc.toMarkdown(model, 'D00SolutionBlueprint');

  fs.writeFileSync(path.join(outDir, 'blueprint.tomspecs.yaml'), yaml);
  fs.writeFileSync(path.join(outDir, 'blueprint.tomspecs.md'), markdown);

  console.log('3. Serialised both renditions into build/');
  console.log(`   blueprint.tomspecs.yaml : ${lines(yaml)} lines  (SOM §12)`);
  console.log(`   blueprint.tomspecs.md   : ${lines(markdown)} lines  (SOM §11)`);
  console.log('');

  // -------------------------------------------------------------- step 4
  // The one-call typed loader: decode, apply the document's own authoring
  // stamp, and hand back a typed root. Re-encoding the reload and comparing
  // the two strings is the actual proof — comparing field by field would only
  // prove the fields somebody thought to compare.
  const reloaded = D00SolutionBlueprint.loadFile(
    path.join(outDir, 'blueprint.tomspecs.yaml'),
  );
  const reYaml = yamlEncode(
    reloaded.doc,
    d00SolutionBlueprintMetaTree,
    model.modelVersionString,
  );

  console.log('4. Round-tripped the yaml through D00SolutionBlueprint.loadFile');
  console.log(`   reload equals original  : ${reYaml === yaml}`);
  console.log(
    '   a value read back typed : ' +
      `"${reloaded.currentLandscape.operationalMetrics.at(0).content}"`,
  );
  console.log('');

  // -------------------------------------------------------------- step 5
  const errors = validateDocument(model, doc);
  console.log('5. Instance-tier validation');
  console.log(`   violations              : ${errors.length}`);
  console.log('');

  // -------------------------------------------------------------- step 6
  // What a violation looks like. Writing to a path the model does not declare
  // is the clearest break to stage: the store accepts it — it is a plain
  // path-keyed map — and the validator is what notices.
  const broken = SpecDocument.fromYaml(yaml, d00SolutionBlueprintMetaTree);
  broken.setContent('SBP/noSuchSection/content', 'not part of the model');

  const brokenErrors = validateDocument(model, broken);
  console.log('6. The same document with one rule deliberately broken');
  console.log(`   violations              : ${brokenErrors.length}`);
  for (const e of brokenErrors) {
    console.log(`   ${e.code}: ${e.path}`);
    console.log(`     ${e.message}`);
  }
  console.log('');
  console.log('Done. The two renditions are in build/.');
}

/**
 * Prints the section id a write landed under. The ids are the document's
 * addressing system — the same tokens appear in the yaml keys and in the
 * markdown `<!--[ID]-->` comments — so the sample shows them rather than
 * describing them.
 */
function wrote(p, what) {
  console.log(`   ${p.padEnd(46)} ${what}`);
}

function lines(s) {
  return s.trimEnd().split('\n').length;
}

main();
