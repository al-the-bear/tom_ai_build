#!/usr/bin/env node
/**
 * TomSpecs sample — a Phase 4 CodeSpecs run, as far as the JavaScript runtime
 * goes.
 *
 * The JavaScript port of `../bin/phase4_codespecs_run.dart`. Phase 4 has four
 * stages, and the JavaScript runtime carries the first two:
 *
 *   stage 1  the starting prompt's quality gate   [MECHANICAL]  here
 *   stage 2  the extract generator                [MECHANICAL]  here
 *   stage 3  the authoring agent                  [JUDGMENT]    the IR, Dart tools
 *   stage 4  validating the emitted trio          [MECHANICAL]  Dart tools
 *
 * Stages 3 and 4 run on the Dart tools (`tomspecs :ir-map`,
 * `tomspecs :codespecs-validate`); the Dart sample shows them. This port runs
 * the same specification through the gate and the extract generator, and its
 * extracts are the ones the Dart sample writes (`CodeSpecsExtract` is in all
 * nine runtimes, byte for byte the same).
 *
 * Run (from this folder; see README.md):  npm install && node index.js
 */
'use strict';

const fs = require('fs');
const path = require('path');

const {
  CodeSpecsAreaCatalog,
  CodeSpecsGate,
  CodeSpecsGateCheck,
  SpecDocument,
  SpecModel,
} = require('tom_som_javascript_runtime');
const { D00SolutionBlueprint } = require('tom_som_javascript_v0');
const { somDocSpecsSchema } = require('tom_som_javascript_v0/schemas');

/** The one `@Document` root this run extracts from (codespecs_prompt.md §5). */
const K_ROOT = 'D00SolutionBlueprint';

/**
 * The creation date section-id generation is pinned to, so the ids (and with
 * them `expected_output.txt`) do not change with the calendar.
 */
const K_AUTHORED_ON = new Date(Date.UTC(2026, 0, 1));

/**
 * The 27-area catalogue (codespecs_mapping.md §4.1 + §4.4.3 + §4.4.6). The
 * Dart package `tom_specs_model` ships it with an accessor; the JavaScript
 * runtime has none, so the sample reads it from the checkout.
 */
const CATALOG = path.resolve(
  __dirname, '..', '..', '..', 'tom_specs_model', 'generated-doc', 'codespecs',
  'codespecs_areas.json',
);

function main() {
  const inputs = {
    model: SpecModel.fromJson(require('tom_som_javascript_v0/meta')),
    schema: somDocSpecsSchema('solution-blueprint'),
    catalog: CodeSpecsAreaCatalog.fromJson(JSON.parse(fs.readFileSync(CATALOG, 'utf8'))),
  };

  rule('A Phase 4 CodeSpecs run, stage by stage');
  print('Every step is marked [MECHANICAL] or [JUDGMENT].');
  print('');

  const extracts = variantA(inputs);
  variantB(inputs);

  print('');
  print(`Extracts written to build/codespecs_extracts/ (${extracts.length * 2} files).`);
}

// ---------------------------------------------------------------------------
// Variant A — a document that passes, taken as far as the extracts.
// ---------------------------------------------------------------------------

function variantA(inputs) {
  const doc = new SpecDocument();
  authorSpecification(new D00SolutionBlueprint(doc), true);

  rule('Variant A — a sufficient specification');
  print('0. The document under Phase 4                 [input]');
  print('   a Solution Blueprint whose information model holds 2 entities');
  print('   and 4 stored attributes; every other section is unwritten.');
  print('');

  const gate = runGate(inputs, doc);
  if (!gate.passed) {
    console.error('variant A was supposed to pass the gate');
    for (const f of gate.findings) console.error(`  ${f}`);
    process.exit(1);
  }
  print('   gate verdict             : PASS — the run may begin');
  print('');

  const extracts = gate.extracts;
  stage2(extracts);
  stages3and4();
  return extracts;
}

// ---------------------------------------------------------------------------
// Variant B — the same document with one required field cleared.
// ---------------------------------------------------------------------------

function variantB(inputs) {
  const doc = new SpecDocument();
  authorSpecification(new D00SolutionBlueprint(doc), false);

  rule('Variant B — the same document, one required field cleared');
  print('Both entities keep their `DAENT-CLAS` section and its `category`, and');
  print('both have `aggregateRoot` cleared. Nothing else changed.');
  print('');

  const gate = runGate(inputs, doc);
  if (gate.passed) {
    console.error('variant B was supposed to be rejected');
    process.exit(1);
  }
  print('   gate verdict             : REJECTED — the run may not begin');
  print('');
  print('   What the gate names, per finding:');
  for (const f of gate.findings) {
    print(`     ${f.check.label} ${f.code} [${f.location}] ${f.message}`);
  }
  print('');
  const a2 = gate.resultFor(CodeSpecsGateCheck.a2).findings.length;
  print(`   A2 moved too: ${a2} violations, against 0 for variant A. The`);
  print('   classification form still holds other values, so its empty');
  print('   required field is reported by both tiers. They part where a value');
  print('   is absent rather than empty: a missing required section is seen by');
  print('   A1 alone. That is why the gate runs both tiers and not either one');
  print('   (codespecs_prompt.md §4.1/§4.2 and its §10.1/§10.2 fixtures).');
  print('');
}

// ---------------------------------------------------------------------------
// Stage 1 — the mechanical gate (codespecs_prompt.md §4).
// ---------------------------------------------------------------------------

const TITLES = {
  a1: 'schema completeness  ',
  a2: 'instance-tier values ',
  a3: 'routing totality     ',
  a4: 'required arguments   ',
  a5: 'structured carriers  ',
};

/**
 * Runs the mechanical tier over `doc` and prints each check's verdict. All five
 * checks run as one gate and none stops the others; a check that could not run
 * says so, and the gate does not pass.
 */
function runGate(inputs, doc) {
  print("1. The starting prompt's quality gate        [MECHANICAL]");
  const report = new CodeSpecsGate({
    model: inputs.model,
    document: doc,
    catalog: inputs.catalog,
    schema: inputs.schema,
    rootType: K_ROOT,
  }).run();
  for (const r of report.results) {
    const verdict = !r.ran
      ? `NOT RUN — ${r.notRunReason}`
      : r.findings.length === 0
        ? 'pass — 0 findings'
        : `FAIL — ${r.findings.length} findings`;
    print(`   ${r.check.label} ${TITLES[r.check.name]}: ${verdict}`);
  }
  print(
    `   (A4 held ${inputs.catalog.requiredArguments.length} required-argument rows, ` +
      `A5 ${inputs.catalog.carriers.length} carriers, both from the catalogue's gate tables)`,
  );
  return report;
}

// ---------------------------------------------------------------------------
// Stage 2 — the extract generator.
// ---------------------------------------------------------------------------

function stage2(extracts) {
  print('2. The extract generator                      [MECHANICAL]');
  const populated = extracts.filter((e) => e.entries.length > 0);
  print(`   areas in the catalogue   : ${extracts.length}`);
  print(`   populated                : ${populated.length}`);
  for (const e of populated) {
    print(`     ${e.area.code.padEnd(6)} ${e.entries.length} entries  → ${e.projects.join(', ')}`);
  }
  print(`   empty                    : ${extracts.length - populated.length}`);
  print('   Most areas are empty because this document says nothing about');
  print('   screens, jobs, reports or migrations. An empty extract is a');
  print('   CANDIDATE for "not applicable" — never the verdict itself, which');
  print('   is a judgment and belongs to stage B (codespecs_prompt.md §6.4).');

  const out = path.join('build', 'codespecs_extracts');
  fs.mkdirSync(out, { recursive: true });
  for (const e of extracts) {
    fs.writeFileSync(path.join(out, `${e.fileStem}.yaml`), e.toYaml());
    fs.writeFileSync(path.join(out, `${e.fileStem}.md`), e.toMarkdown());
  }
  print('');

  const db = extracts.find((e) => e.area.code === 'CE-DB');
  print(`   Area ${db.area.code} — ${db.area.canonicalId}, the extract the`);
  print('   authoring agent reads in stage 3:');
  print(`   built on   : ${db.area.builtOn}`);
  print(`   may cite   : ${db.citableParts.join(', ')}`);
  print(`   entries carried to the agent (${db.entries.length}):`);
  for (const entry of db.entries) {
    print(`     ${entry.sectionId.padEnd(11)} ${entry.fieldName.padEnd(14)} ${short(entry.value)}`);
  }
  print('');
}

function stages3and4() {
  print('3. The authoring agent                        [JUDGMENT]');
  print('4. Validating the emitted trio                [MECHANICAL]');
  print('   Not in the JavaScript runtime. The authoring agent writes the IR');
  print('   from these extracts, and the Dart tools map and validate it');
  print('   (`tomspecs :ir-map`, `tomspecs :codespecs-validate`); the Dart');
  print('   sample in ../bin/ shows both stages on this same specification.');
  print('');
}

// ---------------------------------------------------------------------------
// The specification — the one the Dart sample authors.
// ---------------------------------------------------------------------------

/**
 * Two entities, four attributes and their keys: one area populated and the
 * rest empty. `aggregateRoots` false clears the one required field variant B
 * removes — `DAENT-CLAS.aggregateRoot` — and nothing else.
 */
function authorSpecification(sbp, aggregateRoots) {
  sbp.content = 'Order intake for a single region.';

  // The bounded context CE-SU's required `boundedContext` argument resolves
  // against: an unauthored registry would make the reference dangle at A2.
  const ordering = sbp.solutionArchitectureAndTechnology.technicalFramework.softwareDesign
    .layeringAndModuleStructure.boundedContexts.add(null, K_AUTHORED_ON);
  ordering.$headline = 'Ordering';
  ordering.content.contextName = 'Ordering';
  ordering.content.domainArea = 'Order management';

  const entities = sbp.informationAndDataModel.dataModel.entities;

  const customer = entities.add(null, K_AUTHORED_ON);
  customer.$headline = 'Customer';
  customer.content = 'A party that places orders.';
  customer.identity.entityName = 'Customer';
  customer.identity.tableName = 'customers';
  customer.identity.entityAlias = 'CUST';
  customer.identity.description = 'A person or organisation that places orders.';
  customer.classification.category = 'MasterData';
  customer.classification.boundedContext = 'Ordering';
  if (aggregateRoots) customer.classification.aggregateRoot = 'Customer';

  const email = customer.attributes.add(null, K_AUTHORED_ON);
  email.$headline = 'email';
  email.identity.columnName = 'email';
  email.identity.description = 'The address order confirmations are sent to.';
  email.dataTypeSpec.physicalType = 'VARCHAR';

  const displayName = customer.attributes.add(null, K_AUTHORED_ON);
  displayName.$headline = 'displayName';
  displayName.identity.columnName = 'display_name';
  displayName.identity.description = 'The name the customer trades under.';
  displayName.dataTypeSpec.physicalType = 'VARCHAR';

  // A customer is identified by the address it trades under: a natural key.
  const customerKey = customer.keyAttributes.add(null, K_AUTHORED_ON);
  customerKey.$headline = 'pk_customers';
  customerKey.content.keyType = 'Natural';
  customerKey.content.keyColumns = 'email';
  customerKey.content.description = 'A customer is identified by its e-mail address.';

  const order = entities.add(null, K_AUTHORED_ON);
  order.$headline = 'Order';
  order.content = 'One accepted customer order.';
  order.identity.entityName = 'Order';
  order.identity.tableName = 'orders';
  order.identity.entityAlias = 'ORD';
  order.identity.description = 'A single order placed by a customer.';
  order.classification.category = 'TransactionData';
  order.classification.boundedContext = 'Ordering';
  if (aggregateRoots) order.classification.aggregateRoot = 'Order';

  const orderId = order.attributes.add(null, K_AUTHORED_ON);
  orderId.$headline = 'orderId';
  orderId.identity.columnName = 'order_id';
  orderId.identity.description = 'The identifier the order is filed under.';
  orderId.dataTypeSpec.physicalType = 'UUID';

  const orderKey = order.keyAttributes.add(null, K_AUTHORED_ON);
  orderKey.$headline = 'pk_orders';
  orderKey.content.keyType = 'Primary';
  orderKey.content.keyColumns = 'order_id';
  orderKey.content.description = 'The order identifier.';
  orderKey.generation.generationStrategy = 'UUID';

  const placedAt = order.attributes.add(null, K_AUTHORED_ON);
  placedAt.$headline = 'placedAt';
  placedAt.identity.columnName = 'placed_at';
  placedAt.identity.description = 'The moment the order was accepted.';
  placedAt.dataTypeSpec.physicalType = 'TIMESTAMP';
}

// ---------------------------------------------------------------------------
// Helpers.
// ---------------------------------------------------------------------------

function print(line) {
  console.log(line);
}

function short(value) {
  return value.length <= 44 ? value : `${value.substring(0, 41)}...`;
}

function rule(title) {
  print('='.repeat(72));
  print(title);
  print('='.repeat(72));
}

main();
