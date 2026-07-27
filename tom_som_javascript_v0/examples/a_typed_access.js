#!/usr/bin/env node
'use strict';

/**
 * Sample (a) — TYPED object-model access (som_multiplatform_spec_model.md §6).
 *
 * HAND-AUTHORED — preserved across `generate_som` runs (the generator only
 * rewrites the module, meta/, schemas/ and package.json).
 *
 * Demonstrates editing a TomSpecs document through the generated *typed* facade
 * `tom_som_javascript_v0`: named accessors, nested-section navigation, and the
 * typed `SomList` collection. The typed facade is a thin editing surface over a
 * generic `SpecDocument` — every typed write lands in the same path-keyed store
 * the generic API (sample b) reads, which the closing lines prove.
 *
 * Run from this package:  node examples/a_typed_access.js
 */

const path = require('path');

const _PROJECT = path.dirname(__dirname); // tom_som_javascript_v0

// The generic runtime is located through the `tomSom.runtimePath` recorded in
// this package's package.json, so the sample runs with no install from any cwd.
const _runtimePath = path.resolve(
  _PROJECT,
  require(path.join(_PROJECT, 'package.json')).tomSom.runtimePath,
);
const { SpecDocument } = require(_runtimePath);
const m = require(path.join(_PROJECT, 'tom_som_javascript_v0.js'));

function main() {
  // A typed root over a fresh, empty document. The constructor also runs the
  // §2.2 instantiation-time version check (an unstamped document is editable).
  const doc = new SpecDocument();
  const pd = new m.D00SolutionBlueprint(doc);

  console.log(`Model version of this typed facade: ${pd.objectModelVersion}`);
  console.log(`Root path: ${pd.path}\n`);

  // 1) A content leaf directly on the root.
  pd.content = 'A platform that unifies our fragmented order systems.';

  // 2) Navigate into a nested complex section and edit its own content leaf.
  const csa = pd.currentLandscape;
  csa.content = 'Three legacy systems with no shared customer record.';

  // 3) The typed collection API: append two list items and edit each.
  const metrics = csa.operationalMetrics;
  metrics.add().content = 'Average order turnaround: 4.2 days.';
  metrics.add().content = 'Manual reconciliation: ~12 hours / week.';

  // Read everything back through the typed accessors.
  console.log(`SBP.content              = ${pd.content}`);
  console.log(`SBP.currentLandscape = ${csa.content}`);
  console.log(`operationalMetrics.length = ${metrics.length}`);
  for (let i = 0; i < metrics.length; i++) {
    console.log(`  metric[${i}] = ${metrics.at(i).content}`);
  }

  // The typed path is the generic path: the same data is addressable through
  // the generic document API (this is exactly what sample (b) uses).
  console.log(
    `\nSame value via the generic path ` +
      `(doc.content("${csa.path}/content")):`,
  );
  console.log(`  ${doc.content(`${csa.path}/content`)}`);
  return 0;
}

if (require.main === module) {
  process.exit(main());
}
