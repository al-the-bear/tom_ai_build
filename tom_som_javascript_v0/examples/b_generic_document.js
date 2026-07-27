#!/usr/bin/env node
'use strict';

/**
 * Sample (b) — GENERIC in-memory document access (som_multiplatform_spec_model.md §6).
 *
 * HAND-AUTHORED — preserved across `generate_som` runs.
 *
 * Demonstrates editing the *same* document shape as sample (a) using ONLY the
 * generic `tom_som_runtime` — string paths, no generated typed classes. This is
 * the language-independent core: a sparse, path-keyed store plus the list and
 * serialization helpers. Anything the typed facade can express is expressible
 * here; the typed facade just makes it type-safe and discoverable.
 *
 * Run from this package:  node examples/b_generic_document.js
 */

const path = require('path');

const _PROJECT = path.dirname(__dirname); // tom_som_javascript_v0

const _runtimePath = path.resolve(
  _PROJECT,
  require(path.join(_PROJECT, 'package.json')).tomSom.runtimePath,
);
const { SpecDocument, yamlEncode } = require(_runtimePath);
// The generated module also re-exports the per-root metadata trees (DR8/DR15);
// the generic YAML codec needs the document's tree to render hierarchy.
const m = require(path.join(_PROJECT, 'tom_som_javascript_v0.js'));

/** A `JSON.stringify` replacer that emits object keys in sorted order so the
 * dump is deterministic regardless of insertion order. */
function _sortedKeysReplacer(_key, value) {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return Object.keys(value)
      .sort()
      .reduce((acc, k) => {
        acc[k] = value[k];
        return acc;
      }, {});
  }
  return value;
}

function main() {
  const doc = new SpecDocument();

  // Content leaves are addressed by their full path from the root segment.
  doc.setContent(
    'SBP/content',
    'A platform that unifies our fragmented order systems.',
  );
  doc.setContent(
    'SBP/currentLandscape/content',
    'Three legacy systems with no shared customer record.',
  );

  // A list: append items (each call returns the new item's path), then set a
  // content leaf under each. The list path mirrors the typed facade's
  // `operationalMetrics` accessor.
  const listPath = 'SBP/currentLandscape/CUOPME-OPER-LST';
  const item0 = doc.addListItem(listPath);
  doc.setContent(`${item0}/content`, 'Average order turnaround: 4.2 days.');
  const item1 = doc.addListItem(listPath);
  doc.setContent(`${item1}/content`, 'Manual reconciliation: ~12 hours / week.');

  // Read back generically.
  console.log(`SBP/content = ${doc.content('SBP/content')}`);
  console.log(`list item count = ${doc.listItemCount(listPath)}`);
  for (const itemPath of doc.listItems(listPath)) {
    console.log(`  ${itemPath}/content = ${doc.content(`${itemPath}/content`)}`);
  }

  // The whole document serializes losslessly to JSON … (keys sorted for a
  // stable, deterministic dump, matching the Dart/Python counterparts).
  console.log('\nDocument JSON:');
  console.log(JSON.stringify(doc.toJson(), _sortedKeysReplacer, 2));

  // … and to the canonical hierarchical YAML wire format (stamped with the
  // model version). The v2 codec is meta-driven (DR8/DR15): it takes the
  // document's SomMetaTree, obtained here from the generated facade.
  console.log('\nDocument YAML:');
  console.log(yamlEncode(doc, m.d00SolutionBlueprintMetaTree, '1.0'));
  return 0;
}

if (require.main === module) {
  process.exit(main());
}
