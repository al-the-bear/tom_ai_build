// Cross-language golden-log generator for TypeScript (roadmap item 7b).
//
// Mirror of `tom_som_dart_v0/tool/golden_log.dart` — see that file for the
// canonical format. Loads the shared sample and emits a byte-identical reading
// of essentially every section through both the generic string-path API and the
// typed facade, asserting typed == generic before writing.
//
// Compiled by `npm run build` to `dist/tool/golden_log.js`; run with
//   node dist/tool/golden_log.js [samplePath] [outputPath]

import * as fs from 'fs';
import * as path from 'path';
import {
  DocSpecsSchema,
  DocSpecsValidator,
  SomMetaKind,
  SomMetaKindValue,
  SomMetaNode,
  SomMetaRef,
  SomNode,
  SpecDocument,
} from 'tom_som_typescript_runtime';
import {
  D00SolutionBlueprint,
  SBP,
  d00SolutionBlueprint,
  d00SolutionBlueprintMetaTree,
} from '../tom_som_typescript_v0';

// __dirname at runtime is dist/tool; the project root is two levels up.
const PROJECT = path.resolve(__dirname, '..', '..');
const DEFAULT_SAMPLE = path.resolve(
  PROJECT, '..', 'tom_som_conformance', 'samples',
  'meridian_order_management.docspecs.yaml');
const DEFAULT_OUTPUT = path.resolve(
  PROJECT, '..', 'tom_som_conformance', 'golden', 'typescript.log');
const DEFAULT_SCHEMA = path.resolve(
  PROJECT, 'schemas', 'solution-blueprint',
  'solution-blueprint.1.0.docspecs-schema.yaml');
const DEFAULT_SAMPLE_MD = path.resolve(
  PROJECT, '..', 'tom_som_conformance', 'samples',
  'meridian_order_management.md');

// Map the node's native kind value to the canonical Dart enum spelling, so the
// emitted `M` lines are byte-identical across languages. Most TS kind values
// already equal the Dart spelling; ENUM_VALUE ('enum') is the exception.
function kindName(kind: SomMetaKindValue): string {
  switch (kind) {
    case SomMetaKind.LIST:
      return 'list';
    case SomMetaKind.FORM:
      return 'form';
    case SomMetaKind.SECTION:
      return 'section';
    case SomMetaKind.CONTENT:
      return 'content';
    case SomMetaKind.ENUM_VALUE:
      return 'enumValue';
    case SomMetaKind.COMPLEX:
      return 'complex';
    case SomMetaKind.SCALAR:
      return 'scalar';
    default:
      throw new Error('unknown kind: ' + String(kind));
  }
}

function esc(s: string): string {
  return String(s)
    .replace(/\\/g, '\\\\')
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/\t/g, '\\t');
}

function main(): void {
  const sample = process.argv[2] || DEFAULT_SAMPLE;
  const output = process.argv[3] || DEFAULT_OUTPUT;

  const doc = SpecDocument.fromFile(sample, d00SolutionBlueprintMetaTree);
  const sbp = D00SolutionBlueprint.loadFile(sample);

  const out: string[] = [];
  out.push('# TomSpecs SOM golden log — canonical cross-language reading.');
  out.push('# All nine per-language generators must emit byte-identical output.');
  out.push('FORMAT\t8');
  out.push('MODELVERSION\t' + esc(doc.modelVersion || ''));

  out.push('SECTION\tgeneric-content');
  for (const p of Array.from(doc.contentPaths).sort()) {
    out.push('C\t' + p + '\t' + esc(doc.content(p) || ''));
  }

  out.push('SECTION\tgeneric-forms');
  for (const p of Array.from(doc.formPaths).sort()) {
    for (const f of Array.from(doc.formFieldNames(p)).sort()) {
      out.push('F\t' + p + '\t' + f + '\t' + esc(doc.formField(p, f) || ''));
    }
  }

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

  // Generic: every stored codeSpec, sorted by path (FORMAT 8, codespecs_mapping.md §9.2 mirror of headline).
  out.push('SECTION\tgeneric-codespecs');
  for (const p of Array.from(doc.codeSpecPaths).sort()) {
    out.push('CS\t' + p + '\t' + esc(doc.codeSpec(p) || ''));
  }

  // Typed cross-check of the same two mappings through the facade's structural
  // `$codeSpec` accessor (codespecs_mapping.md §9.2). Emits nothing: the values are already in the
  // `CS` lines above, so a duplicate line would add no information — what this
  // adds is the assertion that the typed accessor reads the same store the
  // generic API does. A divergence aborts the generator.
  const typedCodeSpec = (node: SomNode): void => {
    const typed = node.$codeSpec || '';
    const generic = doc.codeSpec(node.path) || '';
    if (typed !== generic) {
      process.stderr.write('CODESPEC MISMATCH at ' + node.path
        + ': typed="' + typed + '" generic="' + generic + '"\n');
      process.exit(2);
    }
  };

  const typedFrs = sbp.introductionAndScope.requirements.functionalRequirements;
  typedCodeSpec(typedFrs);
  typedCodeSpec(typedFrs.requirements.at(0));

  out.push('SECTION\ttyped');

  const typedContent = (nodePath: string, value: string): void => {
    const leaf = nodePath + '/content';
    const generic = doc.content(leaf) || '';
    if (value !== generic) {
      process.stderr.write('TYPED MISMATCH at ' + leaf + '\n');
      process.exit(2);
    }
    out.push('T\t' + leaf + '\t' + esc(value));
  };

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

  // --- Typed non-String form fields (FORMAT 7, YRD7): native int/bool/enum
  // members read through the typed facade and asserted against the generic
  // form store, canonicalised through the SAME boundary rules the facade
  // setters used to write them (int -> String, bool -> "true"/"false", enum ->
  // constant name). The emitted value is the raw stored string, so the lines
  // are byte-identical across languages regardless of native value types. ---
  out.push('SECTION\ttyped-form');
  const somFormatInt = (v: number | null): string => (v === null ? '' : String(v));
  const somFormatBool = (v: boolean | null): string =>
    (v === null ? '' : (v ? 'true' : 'false'));
  const typedForm = (formPath: string, field: string, canonical: string): void => {
    const generic = doc.formField(formPath, field) || '';
    if ((canonical || '') !== generic) {
      process.stderr.write('TYPED FORM MISMATCH at ' + formPath + '.' + field +
        ': typed="' + (canonical || '') + '" generic="' + generic + '"\n');
      process.exit(2);
    }
    out.push('TF\t' + formPath + '\t' + field + '\t' + esc(generic));
  };

  const actorOverview = sbp.targetOperatingModelConcept
    .processStepsAndActorInteractions.actorOverview.overview;
  typedForm(actorOverview.path, 'totalActorCount',
    somFormatInt(actorOverview.totalActorCount));
  typedForm(actorOverview.path, 'humanActorCount',
    somFormatInt(actorOverview.humanActorCount));
  typedForm(actorOverview.path, 'systemActorCount',
    somFormatInt(actorOverview.systemActorCount));
  typedForm(actorOverview.path, 'externalActorCount',
    somFormatInt(actorOverview.externalActorCount));

  const accessibilityOverview =
    sbp.experienceAndInterfaceDesign.designFollowUp.accessibility
      .accessibilityOverviewContent;
  typedForm(accessibilityOverview.path, 'accessibilityStatement',
    somFormatBool(accessibilityOverview.accessibilityStatement));

  const coverage =
    sbp.qualityAndAcceptanceModel.iso25010Coverage.characteristics;
  out.push('TL\t' + coverage.listPath + '\t' + coverage.length);
  for (let i = 0; i < coverage.length; i++) {
    const cform = coverage.at(i).content;
    typedForm(cform.path, 'characteristic', cform.characteristic || '');
  }

  // --- Meta (FORMAT 2): the generated metadata tree read three ways. ---
  const metaTree = d00SolutionBlueprintMetaTree;

  out.push('SECTION\tmeta');
  const metaNode = (nodePath: string): void => {
    const n = metaTree.byPath(nodePath);
    if (n === null) {
      process.stderr.write('META MISSING at ' + nodePath + '\n');
      process.exit(3);
    }
    out.push(
      'M\t' + nodePath + '\t' + kindName(n.kind) + '\t' +
      esc(n.sectionId || '') + '\t' + esc(n.contentHelp || '') + '\t' +
      esc(n.comment || '') + '\t' + esc(n.docComment || '') + '\t' +
      esc(n.headline || ''),
    );
  };

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

  // --- Meta form fields (FORMAT 7, YRD7): a list-element content form read
  // through the metadata tree — one MF line per field (declaration order) with
  // type/required plus the enumValues column (comma-joined constant names,
  // empty for non-enum fields). Emitted for the FRE requirement form (no
  // enums) and the ISO 25010 coverage form (an enum-typed field). All values
  // are model-derived. ---
  out.push('SECTION\tmeta-form');
  const metaForm = (listPath: string): void => {
    const listNode = metaTree.byPath(listPath);
    const element = listNode !== null ? listNode.elementNode : null;
    let contentNode: SomMetaNode | null = null;
    for (const child of element !== null ? element.children : []) {
      if (child.memberName === 'content') {
        contentNode = child;
      }
    }
    const form = contentNode !== null ? contentNode.form : null;
    if (form === null) {
      process.stderr.write(
        'META FORM MISSING at ' + listPath + ' element content\n');
      process.exit(3);
    }
    // Element subtrees have no static document path; use an ASCII marker
    // segment so the log path stays ASCII (mirrored verbatim per language).
    const formPath = listPath + '/#element/content';
    for (const f of form.fields) {
      out.push('MF\t' + formPath + '\t' + esc(f.name) + '\t' +
        esc(f.typeName) + '\t' + (f.required ? 1 : 0) + '\t' +
        esc((f.enumValues || []).join(',')));
    }
  };

  metaForm(
    'SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST');
  metaForm('SBP/qualityAndAcceptanceModel/iso25010Coverage/I25CV-CHAR-LST');

  out.push('SECTION\tmeta-nav');
  const metaNav = (ref: SomMetaRef, expectedPath: string): void => {
    if (ref.path !== expectedPath) {
      process.stderr.write(
        'META NAV PATH at ' + ref.path + ' expected ' + expectedPath + '\n');
      process.exit(3);
    }
    const byPath = metaTree.byPath(expectedPath);
    if (byPath === null || ref.meta !== byPath) {
      process.stderr.write('META NAV NODE mismatch at ' + expectedPath + '\n');
      process.exit(3);
    }
    out.push('N\t' + expectedPath);
  };

  metaNav(d00SolutionBlueprint, 'SBP');
  metaNav(d00SolutionBlueprint.documentControl, 'SBP/documentControl');
  metaNav(d00SolutionBlueprint.introductionAndScope, 'SBP/introductionAndScope');
  metaNav(d00SolutionBlueprint.introductionAndScope.goals,
    'SBP/introductionAndScope/goals');
  metaNav(d00SolutionBlueprint.introductionAndScope.goals.content,
    'SBP/introductionAndScope/goals/content');
  metaNav(d00SolutionBlueprint.currentLandscape, 'SBP/currentLandscape');
  metaNav(d00SolutionBlueprint.requirements, 'SBP/requirements');
  metaNav(d00SolutionBlueprint.requirements.content, 'SBP/requirements/content');

  out.push('SECTION\tmeta-id');
  const metaId = (idRef: SomMetaRef, navRef: SomMetaRef): void => {
    if (idRef.path !== navRef.path || idRef.meta !== navRef.meta) {
      process.stderr.write(
        'META ID mismatch at ' + idRef.path + ' vs ' + navRef.path + '\n');
      process.exit(3);
    }
    out.push('D\t' + idRef.path);
  };

  metaId(SBP, d00SolutionBlueprint);
  metaId(SBP.RVHST_REVS_LST,
    d00SolutionBlueprint.documentControl.revisionHistory);
  metaId(SBP.RVHST_REVS_LST.item(0),
    d00SolutionBlueprint.documentControl.revisionHistory.item(0));

  out.push('SECTION\tdocspecs');
  const schema = DocSpecsSchema.fromYamlText(
    fs.readFileSync(DEFAULT_SCHEMA, 'utf8'));
  const sampleMd = fs.readFileSync(DEFAULT_SAMPLE_MD, 'utf8');
  const violations = new DocSpecsValidator(schema).validateMarkdown(sampleMd);
  out.push('DS\troot\t' + esc(schema.rootSectionId || ''));
  out.push('DS\twarnings\t' + schema.warnings.length);
  out.push('DS\tviolations\t' + violations.length);
  for (const v of violations) {
    out.push('DV\t' + v.rule + '\t' + esc(v.sectionId || '') + '\t' + v.line);
  }

  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, out.join('\n') + '\n');
  process.stdout.write('wrote ' + out.length + ' lines to ' + output + '\n');
}

main();
