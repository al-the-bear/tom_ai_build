#!/usr/bin/env node
'use strict';

/**
 * Sample (c) — REFLECTION / meta-information access (plan item #14, spec §3.1).
 *
 * HAND-AUTHORED — preserved across `generate_som` runs.
 *
 * Demonstrates the value-free "reflection" surface: load the exported meta-data
 * (`meta/spec_model.meta.json`, the lossless class graph) into a `SpecModel`
 * and query its shape with `SpecReflection` — enumerate roots and fields, and
 * resolve a concrete document *path* to the model node it lands on. No document
 * values are involved; this answers "what CAN the model hold?", not "what does a
 * given document hold?".
 *
 * Run from this package:  node examples/c_reflection_metadata.js
 */

const fs = require('fs');
const path = require('path');

const _PROJECT = path.dirname(__dirname); // tom_som_javascript_v0

const _runtimePath = path.resolve(
  _PROJECT,
  require(path.join(_PROJECT, 'package.json')).tomSom.runtimePath,
);
const { SpecModel, SpecReflection } = require(_runtimePath);

function main() {
  // The meta-data shipped in this package, relative to this script, so the
  // sample runs from any working directory.
  const metaPath = path.join(_PROJECT, 'meta', 'spec_model.meta.json');
  const model = SpecModel.fromJson(
    JSON.parse(fs.readFileSync(metaPath, 'utf-8')),
  );
  const reflection = new SpecReflection(model);

  console.log(
    `Model version: ${model.modelVersion} ` +
      `(${model.modelVersionLabel || 'unstamped'})`,
  );
  const roots = reflection.roots;
  console.log(`Roots: ${roots.length}, classes: ${reflection.classes.length}\n`);

  // Enumerate the document roots by their addressable segment.
  console.log('Document roots:');
  for (const root of roots) {
    console.log(`  ${reflection.rootSegment(root).padEnd(4)} ${root.title}`);
  }

  // Inspect the fields of the D00SolutionBlueprint root class.
  const pdRoot = reflection.rootForSegment('SBP');
  const pdFields = reflection.fieldsOf(pdRoot.type);
  console.log(`\nFirst fields of ${pdRoot.type} (${pdFields.length} total):`);
  for (const field of pdFields.slice(0, 6)) {
    let extra = '';
    if (field.type != null) {
      extra += `  type=${field.type}`;
    }
    if (field.elementType != null) {
      extra += `  elem=${field.elementType}`;
    }
    console.log(`  ${field.name.padEnd(24)} kind=${field.kind}${extra}`);
  }

  // Resolve concrete document paths to model nodes (value-free).
  console.log('\nPath resolution:');
  for (const p of [
    'SBP',
    'SBP/content',
    'SBP/currentLandscape',
    'SBP/currentLandscape/CUOPME-OPER-LST',
  ]) {
    const res = reflection.resolve(p);
    if (res == null) {
      console.log(`  ${p}  ->  (unresolved)`);
      continue;
    }
    const cls = res.targetClass ? `  class=${res.targetClass.name}` : '';
    console.log(
      `  ${p.padEnd(40)} -> kind=${res.kind}${cls}` +
        `  value_leaf=${res.isValueLeaf}`,
    );
  }
  return 0;
}

if (require.main === module) {
  process.exit(main());
}
