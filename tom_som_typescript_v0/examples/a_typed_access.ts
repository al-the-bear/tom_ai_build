/**
 * Sample (a) — TYPED object-model access (som_multiplatform_spec_model.md §6).
 *
 * HAND-AUTHORED — preserved across `generate_som` runs (the generator only
 * rewrites the module, meta/, schemas/, package.json and tsconfig.json).
 *
 * Demonstrates editing a TomSpecs document through the generated *typed* facade
 * `tom_som_typescript_v0`: named accessors, nested-section navigation, and the
 * typed `SomList` collection. The typed facade is a thin editing surface over a
 * generic `SpecDocument` — every typed write lands in the same path-keyed store
 * the generic API (sample b) reads, which the closing lines prove.
 *
 * Build with `tsc` then run:  node dist/examples/a_typed_access.js
 *
 * Like the v0 module itself, the generic runtime is reached through the fixed
 * bare specifier `tom_som_typescript_runtime` (wired by the `file:` dependency
 * in this package's package.json), so the sample is portable across checkouts.
 */

import { SpecDocument } from 'tom_som_typescript_runtime';
import { D00SolutionBlueprint } from '../tom_som_typescript_v0';

function main(): number {
  // A typed root over a fresh, empty document. The constructor also runs the
  // §2.2 instantiation-time version check (an unstamped document is editable).
  const doc = new SpecDocument();
  const pd = new D00SolutionBlueprint(doc);

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
