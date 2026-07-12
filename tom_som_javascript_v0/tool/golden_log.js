// Cross-language golden-log generator for JavaScript (roadmap item 7b).
//
// Mirror of `tom_som_dart_v0/tool/golden_log.dart` — see that file for the
// canonical format. Loads the shared sample and emits a byte-identical reading
// of essentially every section through both the generic string-path API and the
// typed facade, asserting typed == generic before writing.
//
// Usage: node tool/golden_log.js [samplePath] [outputPath]

'use strict';

const fs = require('fs');
const path = require('path');

const _PROJECT = path.dirname(__dirname); // tom_som_javascript_v0
const _runtimePath = path.resolve(
  _PROJECT,
  require(path.join(_PROJECT, 'package.json')).tomSom.runtimePath,
);
const { SpecDocument } = require(_runtimePath);
const m = require(path.join(_PROJECT, 'tom_som_javascript_v0.js'));

const DEFAULT_SAMPLE = path.resolve(
  _PROJECT, '..', 'tom_som_conformance', 'samples',
  'meridian_order_management.docspecs.yaml');
const DEFAULT_OUTPUT = path.resolve(
  _PROJECT, '..', 'tom_som_conformance', 'golden', 'javascript.log');

function esc(s) {
  return String(s)
    .replace(/\\/g, '\\\\')
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/\t/g, '\\t');
}

function main() {
  const sample = process.argv[2] || DEFAULT_SAMPLE;
  const output = process.argv[3] || DEFAULT_OUTPUT;

  const doc = SpecDocument.fromFile(sample, m.d00SolutionBlueprintMetaTree);
  const sbp = m.D00SolutionBlueprint.loadFile(sample);

  const out = [];
  out.push('# TomSpecs SOM golden log — canonical cross-language reading.');
  out.push('# All nine per-language generators must emit byte-identical output.');
  out.push('FORMAT\t1');
  out.push('MODELVERSION\t' + esc(doc.modelVersion || ''));

  // Generic: content leaves, sorted by path.
  out.push('SECTION\tgeneric-content');
  for (const p of Array.from(doc.contentPaths).sort()) {
    out.push('C\t' + p + '\t' + esc(doc.content(p) || ''));
  }

  // Generic: form sections + fields, sorted by path then field.
  out.push('SECTION\tgeneric-forms');
  for (const p of Array.from(doc.formPaths).sort()) {
    for (const f of Array.from(doc.formFieldNames(p)).sort()) {
      out.push('F\t' + p + '\t' + f + '\t' + esc(doc.formField(p, f) || ''));
    }
  }

  // Generic: list containers + item paths (document order).
  out.push('SECTION\tgeneric-lists');
  for (const p of Array.from(doc.listPaths).sort()) {
    const items = doc.listItems(p);
    out.push('L\t' + p + '\t' + items.length);
    for (const item of items) {
      out.push('I\t' + item);
    }
  }

  // Typed: curated traversal that must agree with the generic reads.
  out.push('SECTION\ttyped');

  function typedContent(nodePath, value) {
    const leaf = nodePath + '/content';
    const generic = doc.content(leaf) || '';
    if (value !== generic) {
      process.stderr.write('TYPED MISMATCH at ' + leaf + '\n');
      process.exit(2);
    }
    out.push('T\t' + leaf + '\t' + esc(value));
  }

  typedContent(sbp.path, sbp.content);
  typedContent(sbp.documentControl.path, sbp.documentControl.content);
  typedContent(sbp.introductionAndScope.path, sbp.introductionAndScope.content);
  typedContent(sbp.glossaryAndAbbreviations.path, sbp.glossaryAndAbbreviations.content);
  typedContent(sbp.stakeholdersAndGovernance.path, sbp.stakeholdersAndGovernance.content);
  typedContent(sbp.currentLandscape.path, sbp.currentLandscape.content);
  typedContent(sbp.assumptionsConstraintsDependencies.path,
    sbp.assumptionsConstraintsDependencies.content);
  typedContent(sbp.targetOperatingModelConcept.path,
    sbp.targetOperatingModelConcept.content);
  typedContent(sbp.informationAndDataModel.path, sbp.informationAndDataModel.content);
  typedContent(sbp.requirements.path, sbp.requirements.content);
  typedContent(sbp.solutionArchitectureAndTechnology.path,
    sbp.solutionArchitectureAndTechnology.content);
  typedContent(sbp.securityAndAccessModel.path, sbp.securityAndAccessModel.content);
  typedContent(sbp.experienceAndInterfaceDesign.path,
    sbp.experienceAndInterfaceDesign.content);
  typedContent(sbp.qualityAndAcceptanceModel.path, sbp.qualityAndAcceptanceModel.content);
  typedContent(sbp.deliveryTransitionAndRollout.path,
    sbp.deliveryTransitionAndRollout.content);

  typedContent(sbp.introductionAndScope.goals.path,
    sbp.introductionAndScope.goals.content);

  const metrics = sbp.currentLandscape.operationalMetrics;
  const metricItemPaths = doc.listItems(metrics.listPath);
  if (metrics.length !== metricItemPaths.length) {
    process.stderr.write('TYPED LIST LENGTH MISMATCH at ' + metrics.listPath + '\n');
    process.exit(2);
  }
  out.push('TL\t' + metrics.listPath + '\t' + metrics.length);
  for (let i = 0; i < metrics.length; i++) {
    const elem = metrics.at(i);
    const leaf = elem.path + '/content';
    const generic = doc.content(leaf) || '';
    if (elem.content !== generic) {
      process.stderr.write('TYPED LIST ITEM MISMATCH at ' + leaf + '\n');
      process.exit(2);
    }
    out.push('TI\t' + leaf + '\t' + esc(elem.content));
  }

  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, out.join('\n') + '\n');
  process.stdout.write('wrote ' + out.length + ' lines to ' + output + '\n');
}

main();
