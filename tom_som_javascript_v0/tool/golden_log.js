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
const { SpecDocument, DocSpecsSchema, DocSpecsValidator } = require(_runtimePath);
const m = require(path.join(_PROJECT, 'tom_som_javascript_v0.js'));

const DEFAULT_SAMPLE = path.resolve(
  _PROJECT, '..', 'tom_som_conformance', 'samples',
  'meridian_order_management.docspecs.yaml');
const DEFAULT_SAMPLE_MD = path.resolve(
  _PROJECT, '..', 'tom_som_conformance', 'samples',
  'meridian_order_management.md');
const DEFAULT_SCHEMA = path.resolve(
  _PROJECT, 'schemas', 'solution-blueprint',
  'solution-blueprint.1.0.docspecs-schema.yaml');
const DEFAULT_OUTPUT = path.resolve(
  _PROJECT, '..', 'tom_som_conformance', 'golden', 'javascript.log');

// Maps a native meta-node `kind` to the canonical DART enum spelling, so the
// emitted `M` lines are byte-identical across languages. In the JS port the
// kind is already the lowercase DART spelling, but the explicit map keeps the
// contract correct for all seven kinds regardless of native naming.
const _KIND_MAP = {
  list: 'list',
  form: 'form',
  section: 'section',
  content: 'content',
  enumValue: 'enumValue',
  complex: 'complex',
  scalar: 'scalar',
};

function kindName(kind) {
  const mapped = _KIND_MAP[kind];
  if (mapped === undefined) {
    process.stderr.write('UNKNOWN META KIND ' + kind + '\n');
    process.exit(3);
  }
  return mapped;
}

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
  out.push('FORMAT\t3');
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
  // FORMAT 3: each item with a *stored* section id additionally emits an
  // `ID` line (item path + stored id); items without one emit no `ID` line.
  out.push('SECTION\tgeneric-lists');
  for (const p of Array.from(doc.listPaths).sort()) {
    const items = doc.listItems(p);
    out.push('L\t' + p + '\t' + items.length);
    for (const item of items) {
      out.push('I\t' + item);
      const itemId = doc.itemSectionId(item);
      if (itemId !== null) {
        out.push('ID\t' + item + '\t' + esc(itemId));
      }
    }
  }

  // Generic: every stored headline, sorted by path (FORMAT 3, YRD3).
  out.push('SECTION\tgeneric-headlines');
  for (const p of Array.from(doc.headlinePaths).sort()) {
    out.push('H\t' + p + '\t' + esc(doc.headline(p) || ''));
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

  // --- Meta (FORMAT 2): the generated metadata tree read three ways. ---
  const metaTree = m.d00SolutionBlueprintMetaTree;

  out.push('SECTION\tmeta');
  function metaNode(nodePath) {
    const n = metaTree.byPath(nodePath);
    if (n == null) {
      process.stderr.write('META MISSING at ' + nodePath + '\n');
      process.exit(3);
    }
    out.push(
      'M\t' + nodePath + '\t' + kindName(n.kind) + '\t' +
        esc(n.sectionId || '') + '\t' + esc(n.contentHelp || '') + '\t' +
        esc(n.comment || '') + '\t' + esc(n.docComment || ''),
    );
  }

  metaNode('SBP');
  metaNode('SBP/documentControl');
  metaNode('SBP/documentControl/RVHST-REVS-LST');
  metaNode('SBP/introductionAndScope');
  metaNode('SBP/introductionAndScope/goals');
  metaNode('SBP/introductionAndScope/goals/content');
  metaNode('SBP/currentLandscape');
  metaNode('SBP/currentLandscape/CUOPME-OPER-LST');
  metaNode('SBP/requirements');
  metaNode('SBP/requirements/content');

  out.push('SECTION\tmeta-nav');
  function metaNav(ref, expectedPath) {
    if (ref.path !== expectedPath) {
      process.stderr.write(
        'META NAV PATH at ' + ref.path + ' expected ' + expectedPath + '\n',
      );
      process.exit(3);
    }
    const byPath = metaTree.byPath(expectedPath);
    if (byPath == null || ref.meta !== byPath) {
      process.stderr.write('META NAV NODE mismatch at ' + expectedPath + '\n');
      process.exit(3);
    }
    out.push('N\t' + expectedPath);
  }

  metaNav(m.d00SolutionBlueprint, 'SBP');
  metaNav(m.d00SolutionBlueprint.documentControl, 'SBP/documentControl');
  metaNav(m.d00SolutionBlueprint.introductionAndScope, 'SBP/introductionAndScope');
  metaNav(m.d00SolutionBlueprint.introductionAndScope.goals,
    'SBP/introductionAndScope/goals');
  metaNav(m.d00SolutionBlueprint.introductionAndScope.goals.content,
    'SBP/introductionAndScope/goals/content');
  metaNav(m.d00SolutionBlueprint.currentLandscape, 'SBP/currentLandscape');
  metaNav(m.d00SolutionBlueprint.requirements, 'SBP/requirements');
  metaNav(m.d00SolutionBlueprint.requirements.content, 'SBP/requirements/content');

  out.push('SECTION\tmeta-id');
  function metaId(idRef, navRef) {
    if (idRef.path !== navRef.path || idRef.meta !== navRef.meta) {
      process.stderr.write(
        'META ID mismatch at ' + idRef.path + ' vs ' + navRef.path + '\n',
      );
      process.exit(3);
    }
    out.push('D\t' + idRef.path);
  }

  metaId(m.SBP, m.d00SolutionBlueprint);
  metaId(m.SBP.RVHST_REVS_LST,
    m.d00SolutionBlueprint.documentControl.revisionHistory);
  metaId(m.SBP.RVHST_REVS_LST.item(0),
    m.d00SolutionBlueprint.documentControl.revisionHistory.item(0));

  out.push('SECTION\tdocspecs');
  const schema = DocSpecsSchema.fromYamlText(
    fs.readFileSync(DEFAULT_SCHEMA, 'utf8'),
  );
  const sampleMd = fs.readFileSync(DEFAULT_SAMPLE_MD, 'utf8');
  const violations = new DocSpecsValidator(schema).validateMarkdown(sampleMd);
  out.push('DS\troot\t' + esc(schema.rootSectionId || ''));
  out.push('DS\twarnings\t' + schema.warnings.length);
  out.push('DS\tviolations\t' + violations.length);
  for (const v of violations) {
    out.push('DV\t' + v.rule.name + '\t' + esc(v.sectionId || '') + '\t' + v.line);
  }

  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, out.join('\n') + '\n');
  process.stdout.write('wrote ' + out.length + ' lines to ' + output + '\n');
}

main();
