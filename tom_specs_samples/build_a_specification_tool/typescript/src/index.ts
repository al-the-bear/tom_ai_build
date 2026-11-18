/**
 * TomSpecs sample — building tooling ON a specification (TypeScript).
 *
 * The TypeScript port of `../bin/build_a_specification_tool.dart`: the same
 * five steps over the same fixture. Its output differs from the Dart sample in
 * the places where the Dart text names a Dart-only surface;
 * `expected_output.txt` here records the TypeScript output, and README.md says
 * where it differs.
 *
 * Run (from this folder; see README.md):  npm install && npm run build && npm start
 *
 * For the reader who is not authoring specifications but writing programs that
 * read them: an editor, a linter, a report, an importer, a migration. That
 * reader needs four things, and this sample walks them in the order they are
 * needed:
 *
 *   1. REFLECTION   — what the model CAN hold, read from the metadata tree
 *   2. GENERIC      — what a document DOES hold, with no compile-time knowledge
 *                     of its shape
 *   3. SCHEMA       — the generated schema, where it comes from and what it is
 *   4. VALIDATION   — the two runtime tiers, and the third that is not here
 *   5. A TOOL       — a completeness report built on all four
 *
 * The individual APIs are demonstrated one at a time in the facade's own
 * examples (`tom_som_typescript_v0/examples/`): `b_generic_document.ts` and
 * `c_reflection_metadata.ts`.
 */
import * as fs from 'fs';

import {
  DocSpecsSchema,
  DocSpecsValidator,
  DocSpecsViolationRule,
  SpecDocument,
  SpecField,
  SpecFieldKind,
  SpecModel,
  SpecReflection,
  SpecValidationCode,
  validateDocument,
} from 'tom_som_typescript_runtime';
import {
  D00SolutionBlueprint,
  d00SolutionBlueprint,
  d00SolutionBlueprintMetaTree,
} from 'tom_som_typescript_v0';
import { somDocSpecsSchema } from 'tom_som_typescript_v0/schemas';

/** The document root this sample inspects. */
const K_ROOT = 'D00SolutionBlueprint';

/** That root's addressable segment — the first element of every path in it. */
const K_ROOT_SEGMENT = 'SBP';

/**
 * The creation date section-id generation is pinned to. `SomList.add` derives
 * an item's id from the current date, so an unpinned run would emit different
 * ids every day and `expected_output.txt` would record the day it was taken
 * rather than the pipeline.
 */
const K_AUTHORED_ON = new Date(Date.UTC(2026, 0, 1));

/**
 * The report's title column width. Titles are clipped to it rather than
 * wrapped: a completeness report is scanned down its numbers, and a wrapped
 * title puts a row's two halves on different lines.
 */
const K_TITLE_WIDTH = 38;

function main(): void {
  const meta = JSON.parse(
    fs.readFileSync(require.resolve('tom_som_typescript_v0/meta'), 'utf-8'),
  );
  const model = SpecModel.fromJson(meta);
  const schema = somDocSpecsSchema('solution-blueprint');

  const doc = new SpecDocument();
  authorFixture(new D00SolutionBlueprint(doc));

  section(0, 'The document this run inspects');
  print('A Solution Blueprint with a handful of sections written and the');
  print('rest left blank — small enough that every number below can be');
  print('checked by reading `authorFixture` in this file.');
  print('');
  print(`  content leaves written : ${[...doc.contentPaths].length}`);
  print(`  form sections written  : ${[...doc.formPaths].length}`);
  print(`  lists with items       : ${[...doc.listPaths].length}`);

  reflectionStep(model, meta);
  genericAccess(model, doc);
  theSchema(schema);
  validation(model, schema, doc);
  theTool(model, schema, doc);
}

// ===========================================================================
// 1. Reflection — what the model CAN hold
// ===========================================================================

function reflectionStep(model: SpecModel, meta: { generatedAt?: string }): void {
  section(1, 'Reflection — what the model CAN hold');
  print('`SpecModel` is the exported class graph; `SpecReflection` is the');
  print('value-free query surface over it. No document is involved here.');
  print('');

  print('THE TWO VERSION STAMPS. They answer different questions and a tool');
  print('that checks one for the other will accept a file it cannot read:');
  print(`  modelVersion      = ${model.modelVersion}  — WHICH MODEL this snapshot describes`);
  print(
    `  metaSchemaVersion = ${model.metaSchemaVersion}  — the FILE FORMAT the snapshot itself is written in`,
  );
  print(`  modelVersionLabel = ${model.modelVersionLabel}`);
  // A JavaScript `Date` holds milliseconds; the stamp carries microseconds, so
  // the stamp is printed as the snapshot writes it.
  print(`  generatedAt       = ${meta.generatedAt}`);
  print('');
  print('A tool reads `metaSchemaVersion` to decide whether it can parse the');
  print('file at all, and `modelVersion` to decide whether the documents it');
  print('holds are the ones this model describes. `modelVersionLabel` is a');
  print('build label for humans — never branch on it.');
  print('');

  // A snapshot is a photograph. `checkStamp` compares what the exporter
  // DECLARED against what survived to the reader, and ages the file out. `now`
  // is derived from the model's own stamp so the printed age stays at exactly
  // the offset this sample means to demonstrate.
  const exportedAt = model.generatedAt || new Date(Date.UTC(2026, 0, 1));
  const stamp = model.checkStamp({
    now: new Date(exportedAt.getTime() + 3 * 24 * 3600 * 1000),
  });
  print('SNAPSHOT CHECK (`checkStamp`), against a fixed clock:');
  const ageDays = stamp.ageMs == null ? null : Math.floor(stamp.ageMs / (24 * 3600 * 1000));
  print(`  age                 : ${ageDays} days (aged: ${stamp.isAged})`);
  print(
    `  classes  declared/actual : ${stamp.declaredClassCount}/${stamp.actualClassCount}` +
      `  disagrees: ${stamp.classCountDisagrees}`,
  );
  print(
    `  roots    declared/actual : ${stamp.declaredRootCount}/${stamp.actualRootCount}` +
      `  disagrees: ${stamp.rootCountDisagrees}`,
  );
  print('  Declared-vs-actual is not redundant: the declared value is what');
  print('  the exporter recorded, the actual value is what survived to the');
  print('  reader, and a truncated file is exactly where they part.');
  print('');

  const reflection = new SpecReflection(model);
  print('SHAPE:');
  print(`  document roots : ${reflection.roots.length}`);
  print(`  classes        : ${reflection.classes.length}`);
  print(
    `  container root : ${model.containerRoot}` +
      ' — the one true tree root, which is not itself a document',
  );
  print('');

  const root = reflection.rootForSegment('SBP')!;
  const fields = reflection.fieldsOf(root.type);
  print(`FIELDS of ${root.type} (${fields.length} total, first 4):`);
  for (const f of fields.slice(0, 4)) {
    print(`  ${f.name.padEnd(24)} kind=${kindName(f.kind).padEnd(8)} ${f.type || ''}`);
  }
  print('');

  // A form's slots are on the field itself, not on a separate class — the
  // shape a tool must handle to render or fill one.
  const form = reflection
    .fieldsOf('DataEntityEntry')
    .find((f) => f.kind === SpecFieldKind.FORM)!;
  print(`FORM SLOTS of DataEntityEntry.${form.name} (section id ${form.sectionId}):`);
  for (const slot of form.formFields) {
    print(`  ${slot.name.padEnd(16)} ${slot.label}`);
  }
  print('');

  print("ANNOTATIONS the meta carries — the model's own metadata, exported");
  print('into the snapshot and therefore visible in ALL NINE language');
  print('runtimes, not just Dart:');
  for (const a of reflection.annotationsOf(root.type)) {
    const args = Object.keys(a.arguments || {}).join(', ');
    print(`  @${a.name}${args ? `(${args})` : ''}`);
  }
  // The display semantics of these annotations (`kRenderedAnnotations`) are in
  // the Dart runtime only: they are what the two Flutter apps share.
  print("  How each is displayed is the Dart runtime's (`kRenderedAnnotations`,");
  print('  shared by the two Flutter apps); the annotations themselves are');
  print('  data every runtime reads.');
  print('');

  print('PATH RESOLUTION — a document path to the model node it lands on:');
  for (const p of [
    'SBP',
    'SBP/content',
    'SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST',
    'SBP/informationAndDataModel/nosuchthing',
  ]) {
    const r = reflection.resolve(p);
    print(
      `  ${p.padEnd(50)} ` +
        (r === null ? '(unresolved)' : `kind=${r.kind}  leaf=${r.isValueLeaf}`),
    );
  }
}

// ===========================================================================
// 2. Generic access — what a document DOES hold
// ===========================================================================

function genericAccess(model: SpecModel, doc: SpecDocument): void {
  section(2, 'Generic access — what the document DOES hold');
  print('`SpecDocument` is a sparse, path-keyed store. A tool reads it');
  print("without knowing the document's shape, and asks the model what each");
  print('path means. That pairing is the whole of generic access.');
  print('');

  const reflection = new SpecReflection(model);
  print('EVERY written content leaf, resolved against the model:');
  for (const p of [...doc.contentPaths].sort()) {
    const r = reflection.resolve(p);
    print(`  ${p.padEnd(52)} ${r ? r.kind : '?'}`);
    print(`      ${clip(doc.content(p) || '', 66)}`);
  }
  print('');

  print('EVERY written form section, slot by slot:');
  for (const p of [...doc.formPaths].sort()) {
    print(`  ${p}`);
    for (const slot of [...doc.formFieldNames(p)].sort()) {
      print(`      ${slot.padEnd(16)} ${clip(doc.formField(p, slot) || '', 52)}`);
    }
  }
  print('');

  print("EVERY list, with its items' section ids:");
  for (const p of [...doc.listPaths].sort()) {
    print(`  ${p.padEnd(52)} ${doc.listItemCount(p)} item(s)`);
    for (const id of doc.listItemSectionIds(p)) {
      print(`      ${id}`);
    }
  }
  print('');

  print('WHERE PATHS COME FROM. A tool must never hard-code a path literal —');
  print('a literal is undiscoverable and rots silently when the model moves.');
  print('Two safe sources, both from the generated metadata module:');
  print('');
  print('  1. the generated metadata refs —');
  print('     d00SolutionBlueprint.informationAndDataModel.dataModel.path');
  print(`       = ${d00SolutionBlueprint.informationAndDataModel.dataModel.path}`);
  print('  2. the id-keyed metadata tree, for a path known only at runtime —');
  const node = d00SolutionBlueprintMetaTree.byId('DAENT-ENTI-LST');
  print("     d00SolutionBlueprintMetaTree.byId('DAENT-ENTI-LST')");
  print(`       = ${node ? node.path : null}`);
  print('');
  print('  The tree also goes the other way: byPath gives the node, and with');
  print('  it the class, kind and children a generic renderer needs.');
  const byPath = d00SolutionBlueprintMetaTree.byPath('SBP/informationAndDataModel/dataModel')!;
  print("     byPath('SBP/informationAndDataModel/dataModel')");
  print(
    `       class=${byPath.className} kind=${byPath.kind} children=${byPath.children.length}`,
  );
}

// ===========================================================================
// 3. The generated schema
// ===========================================================================

function theSchema(schema: DocSpecsSchema): void {
  section(3, 'The generated schema');
  print('Each of the 14 document roots has a schema GENERATED from the model');
  print('and SHIPPED as data inside the facade package, under');
  print('`schemas/<document>/<document>.1.0.docspecs-schema.yaml`. A tool');
  print('loads one; it never writes one, and never derives one itself.');
  print('');
  print('IT IS A DocSpecs SCHEMA, NOT JSON SCHEMA. It describes a *markdown*');
  print('document — headings, their ids, their formats, the form fields a');
  print('section carries and which of them are required. A tool reaching for');
  print('a JSON-Schema validator will not find one, because the artifact the');
  print('schema governs is not JSON.');
  print('');
  print(`  root section id : ${schema.rootSectionId}`);
  print(`  section types   : ${schema.sectionTypes.length}`);
  print('');
  print('  That count is large because a Solution Blueprint SEEDS the twelve');
  print("  Phase-3 documents: its own section classes ARE those documents'");
  print('  types, so its schema covers every section id they define. Step 5');
  print('  meets the same fact from the other side.');
  print('');
  print('  A section type resolves by ID PREFIX, which is how a generated id');
  print('  like `DAENT-ENTI-7` finds its type without the schema listing');
  print('  every instance:');
  for (const id of ['DAENT-IDEN', 'DAENT-ENTI-7', 'NOSUCH-1']) {
    const t = schema.resolveSectionType(id);
    print(
      `    ${id.padEnd(16)} -> ` +
        (t === null || t === undefined
          ? '(no type — a tool treats this as unknownSection)'
          : t.prefix),
    );
  }
}

// ===========================================================================
// 4. Validation — the tiers
// ===========================================================================

function validation(model: SpecModel, schema: DocSpecsSchema, doc: SpecDocument): void {
  section(4, 'Validation — three tiers, two of them here');
  print('THIS IS THE DISTINCTION TOOLING AUTHORS MISS. A tool that wants one');
  print('tier and calls another gets nothing useful — not an error, just an');
  print('empty list that reads like a pass.');
  print('');
  print("  STATIC tier   — checks the MODEL'S OWN ANNOTATIONS: field-type");
  print('                  rules, @ContentType compatibility, cycles, the');
  print('                  §10.2 structural invariants. Runs ONCE at');
  print('                  generation time, in');
  print('                  `tom_specs_clitool/lib/src/validator.dart`, and is');
  print('                  deliberately NOT part of the nine-language runtime');
  print('                  surface. Not reachable from this sample, and that');
  print('                  is the point: by the time a document exists, this');
  print('                  tier has already run.');
  print("  INSTANCE tier — checks A DOCUMENT'S VALUES against the model:");
  print('                  `validateDocument` (SOM §9). In every runtime.');
  print('  DOCUMENT tier — checks a MARKDOWN RENDITION against the generated');
  print('                  schema: `DocSpecsValidator` (SOM §14).');
  print('');
  print('The two runtime tiers overlap and neither implies the other:');
  print('`validateDocument` reports a required field left empty in a form the');
  print('document holds, but not a required section that is absent; the');
  print('schema validator reports the absent section, but does not follow a');
  print('reference it sees filled. A tool that wants "is this document good?"');
  print('runs BOTH.');
  print('');

  const instance = validateDocument(model, doc);
  const document = new DocSpecsValidator(schema).validateMarkdown(doc.toMarkdown(model, K_ROOT));
  print('THE FIXTURE, both tiers:');
  print(`  instance tier : ${instance.length} error(s)`);
  print(`  document tier : ${document.length} violation(s)`);
  for (const v of document.slice(0, 4)) {
    print(`    line ${v.line}: ${v.rule} [${v.sectionId}] ${clip(v.message, 54)}`);
  }
  if (document.length > 4) {
    print(`    … and ${document.length - 4} more`);
  }
  print('');

  // A document broken on purpose, to show the instance tier firing where the
  // document tier cannot see anything wrong.
  const broken = new SpecDocument();
  authorFixture(new D00SolutionBlueprint(broken));
  broken.setContent('SBP/informationAndDataModel/nosuchsection/content', 'x');
  broken.setFormField(
    'SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAENT-IDEN',
    'notAField',
    'x',
  );
  print('A DELIBERATELY BROKEN COPY — one path the model does not have, one');
  print('form slot the form does not declare:');
  for (const e of validateDocument(model, broken)) {
    print(`  ${e.code.padEnd(20)} ${clip(e.path, 50)}`);
  }
  print('');

  print('THE CLOSED VERDICT SETS. Both are enums, so a tool switches over');
  print('them exhaustively rather than matching on message text:');
  const codes = Object.values(SpecValidationCode);
  print(`  SpecValidationCode  (${codes.length}): ${codes.join(', ')}`);
  const rules = Object.values(DocSpecsViolationRule);
  print(`  DocSpecsViolationRule (${rules.length}):`);
  for (let i = 0; i < rules.length; i += 4) {
    print(`    ${rules.slice(i, i + 4).join(', ')}`);
  }
}

// ===========================================================================
// 5. The tool
// ===========================================================================

function theTool(model: SpecModel, schema: DocSpecsSchema, doc: SpecDocument): void {
  section(5, 'A tool: the completeness report');
  print('Built on all four surfaces above, and it reports something NEITHER');
  print('validator can. The schema names what is REQUIRED and missing; an');
  print('optional section left blank is perfectly valid and no validator will');
  print('ever mention it. But "which parts of this specification has nobody');
  print('written yet?" is the question a specification author actually has,');
  print('and answering it means walking the model and asking the document.');
  print('');

  const report = specificationCoverage(model, doc, K_ROOT_SEGMENT);
  print(`  ${'SECTION'.padEnd(K_TITLE_WIDTH)} WRITTEN / OFFERED`);
  for (const row of report.rows) {
    const bar = row.offered === 0 ? '' : `${pct(row.written, row.offered)}%`.padStart(6);
    print(
      `  ${row.title.padEnd(K_TITLE_WIDTH)} ` +
        `${String(row.written).padStart(5)} / ${String(row.offered).padStart(5)}${bar}`,
    );
  }
  print(`  ${'-'.repeat(K_TITLE_WIDTH)} ${'-'.repeat(19)}`);
  print(
    `  ${'TOTAL'.padEnd(K_TITLE_WIDTH)} ` +
      `${String(report.written).padStart(5)} / ${String(report.offered).padStart(5)}` +
      `${`${pct(report.written, report.offered)}%`.padStart(6)}`,
  );
  print('');
  const largest = report.rows.reduce((a, b) => (b.offered > a.offered ? b : a));
  print(
    `  ${largest.title.split(' ')[0]} offers ${largest.offered} positions ` +
      'because a Solution Blueprint SEEDS',
  );
  print('  the twelve Phase-3 documents: its section classes ARE those');
  print("  documents' types, so the model surface under an SBP root includes");
  print('  everything it seeds. A tool that reports "0 %" against a number');
  print('  like that should say what the denominator is — which is why the');
  print('  report is per section and not one headline figure.');
  print('');
  print('  Required-and-missing, from the schema tier, for contrast:');
  const required = new DocSpecsValidator(schema)
    .validateMarkdown(doc.toMarkdown(model, K_ROOT))
    .filter((v) => v.rule === DocSpecsViolationRule.MISSING_REQUIRED_FIELD).length;
  print(`    ${required} missing required field(s) — the only gaps a validator`);
  print(`    will name, out of ${report.offered - report.written} unwritten positions.`);
  print('');
  print("That gap between the two numbers is the tool's reason to exist.");
}

/**
 * Walks `model` from `rootSegment` and counts, per top-level section, how many
 * content positions the model offers and how many `doc` has written.
 *
 * **Lists count as one position, not as their items.** A list the author left
 * empty offers exactly one thing to write — the first item — and a list with
 * forty items has not made the document forty times more complete.
 *
 * The walk is entirely generic: it knows no class or field name, so it works
 * unchanged against any of the fourteen document roots.
 */
interface CoverageRow {
  title: string;
  offered: number;
  written: number;
}

interface SpecificationCoverage {
  rows: CoverageRow[];
  offered: number;
  written: number;
}

function specificationCoverage(
  model: SpecModel,
  doc: SpecDocument,
  rootSegment: string,
): SpecificationCoverage {
  const reflection = new SpecReflection(model);
  const root = reflection.rootForSegment(rootSegment)!;
  const rows: CoverageRow[] = [];
  for (const field of reflection.fieldsOf(root.type)) {
    if (field.kind === SpecFieldKind.CONTENT) continue; // the root's own body
    const counter = { offered: 0, written: 0 };
    walk(reflection, doc, counter, field, `${rootSegment}/${reflection.fieldSegment(field)}`, new Set([root.type]));
    if (counter.offered === 0) continue;
    rows.push({ title: rowTitle(field), offered: counter.offered, written: counter.written });
  }
  return {
    rows,
    offered: rows.reduce((a, r) => a + r.offered, 0),
    written: rows.reduce((a, r) => a + r.written, 0),
  };
}

/**
 * Adds every content position under `field` at `path`. `seen` carries the
 * class names already on this branch; the model is a graph, and a section type
 * that can contain itself would otherwise recurse forever.
 */
function walk(
  reflection: SpecReflection,
  doc: SpecDocument,
  counter: { offered: number; written: number },
  field: SpecField,
  path: string,
  seen: Set<string>,
): void {
  switch (field.kind) {
    case SpecFieldKind.CONTENT:
    case SpecFieldKind.SCALAR:
    case SpecFieldKind.ENUM:
      counter.offered++;
      if (doc.hasContent(path)) counter.written++;
      return;
    case SpecFieldKind.FORM:
      for (const slot of field.formFields) {
        counter.offered++;
        if (doc.formField(path, slot.name)) counter.written++;
      }
      return;
    case SpecFieldKind.LIST:
      counter.offered++;
      if (doc.listItemCount(path) > 0) counter.written++;
      return;
    case SpecFieldKind.SECTION:
    case SpecFieldKind.COMPLEX: {
      const type = field.type;
      if (!type || seen.has(type)) return;
      for (const child of reflection.fieldsOf(type)) {
        walk(reflection, doc, counter, child, `${path}/${reflection.fieldSegment(child)}`, new Set([...seen, type]));
      }
      return;
    }
    default:
      return;
  }
}

/**
 * A section's title for the report — its model doc comment's first sentence,
 * falling back to the field name where the model carries no doc.
 */
function rowTitle(field: SpecField): string {
  let text = ((field.doc || '').split('\n')[0] || '').trim();
  const stop = text.indexOf('. ');
  if (stop >= 0) text = text.substring(0, stop);
  while (text.endsWith('.')) text = text.substring(0, text.length - 1);
  text = text.trim();
  if (!text) return field.name;
  return text.length <= K_TITLE_WIDTH ? text : `${text.substring(0, K_TITLE_WIDTH - 1)}…`;
}

// ===========================================================================
// The fixture
// ===========================================================================

/**
 * Writes the small, deliberately incomplete document this run inspects — the
 * same one the Dart sample writes.
 */
function authorFixture(sbp: D00SolutionBlueprint): void {
  sbp.content = 'A platform that unifies our fragmented order systems.';
  sbp.introductionAndScope.content =
    'Replace three regional order desks with one intake service.';
  sbp.currentLandscape.content = 'Three legacy systems with no shared customer record.';

  const metrics = sbp.currentLandscape.operationalMetrics;
  metrics.addContent('Average order turnaround: 4.2 days.', null, K_AUTHORED_ON);
  metrics.addContent('Manual reconciliation: ~12 hours per week.', null, K_AUTHORED_ON);

  const customer = sbp.informationAndDataModel.dataModel.entities.add(null, K_AUTHORED_ON);
  customer.$headline = 'Customer';
  const identity = customer.identity;
  identity.entityName = 'Customer';
  identity.tableName = 'customers';
  identity.description = 'A party that places orders.';
  // `category` is written and `aggregateRoot` is not, and `aggregateRoot` is
  // REQUIRED — so the schema tier has one real violation to report in step 4.
  customer.classification.category = 'MasterData';
}

// ===========================================================================
// Small helpers
// ===========================================================================

function print(line: string): void {
  console.log(line);
}

function section(n: number, title: string): void {
  print('');
  print('='.repeat(74));
  print(`${n}. ${title}`);
  print('='.repeat(74));
}

function clip(s: string, width: number): string {
  const flat = s.replace(/\n/g, ' ');
  return flat.length <= width ? flat : `${flat.substring(0, width - 1)}…`;
}

function pct(written: number, offered: number): number {
  return Math.round((100 * written) / offered);
}

/** A field kind by the name the Dart enum gives it (`enum` is `enumValue`). */
function kindName(kind: string): string {
  return kind === SpecFieldKind.ENUM ? 'enumValue' : kind;
}

main();
