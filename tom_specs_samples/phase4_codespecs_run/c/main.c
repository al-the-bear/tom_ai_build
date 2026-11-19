/* TomSpecs sample — a Phase 4 CodeSpecs run, as far as the C runtime goes.
 *
 * The C port of `../bin/phase4_codespecs_run.dart`. Phase 4 has four stages,
 * and the C runtime carries the first two:
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
 * Build and run (from this folder; see README.md):  make && ./build/sample
 *
 * MEMORY OWNERSHIP, as the runtime headers state it and this file follows it:
 * a `CodeSpecsGate` BORROWS its model, document, catalogue and schema; a
 * `CodeSpecsGateReport` OWNS its findings and extracts (release with
 * `spec_codespecs_gate_report_free`), and the extracts borrow their areas from
 * the catalogue, so the catalogue must outlive the report. Every `char *`
 * result (`spec_codespecs_extract_file_stem`, `_to_yaml`, `_to_markdown`, a
 * `char **err`) is OWNED and freed with `free`. Facade values and `SomList`
 * views borrow the document and own their paths (`*_free`). The sample runs
 * clean under AddressSanitizer and a leak checker (`tool/validate.sh`).
 */
#include "tom_som_c_v0.h"
#include "tom_som_c_v0_meta.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#ifndef TOMSPECS_CHECKOUT
#define TOMSPECS_CHECKOUT "../../.."
#endif

/* The one `@Document` root this run extracts from (codespecs_prompt.md §5). */
static const char *const K_ROOT = "D00SolutionBlueprint";

/* The creation date section-id generation is pinned to (1 January), so the
 * ids (and with them `expected_output.txt`) do not change with the calendar. */
static const long long K_AUTHORED_MONTH = 1, K_AUTHORED_DAY = 1;

/* What every gate run takes: the model, the schema and the area catalogue. */
typedef struct {
  SpecModel *model;
  DocSpecsSchema *schema;
  CodeSpecsAreaCatalog catalog;
} Inputs;

/* ---- helpers --------------------------------------------------------------- */

static char *read_checkout(const char *relative) {
  size_t len = strlen(TOMSPECS_CHECKOUT) + 1 + strlen(relative) + 1;
  char *path = malloc(len);
  snprintf(path, len, "%s/%s", TOMSPECS_CHECKOUT, relative);
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    fprintf(stderr, "cannot read %s\n", path);
    exit(1);
  }
  free(path);
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  fseek(f, 0, SEEK_SET);
  char *buf = malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  fclose(f);
  buf[got] = '\0';
  return buf;
}

static void write_file(const char *path, const char *text) {
  FILE *f = fopen(path, "wb");
  if (f == NULL) {
    fprintf(stderr, "cannot write %s\n", path);
    exit(1);
  }
  fputs(text, f);
  fclose(f);
}

static void rule(const char *title) {
  for (int i = 0; i < 72; i++) putchar('=');
  printf("\n%s\n", title);
  for (int i = 0; i < 72; i++) putchar('=');
  printf("\n");
}

/* Prints `value`, cut to 41 code points and `...` when longer than 44. */
static void print_short(const char *value) {
  size_t cps = 0;
  for (const char *p = value; *p; p++) {
    if (((unsigned char)*p & 0xC0) != 0x80) cps++;
  }
  if (cps <= 44) {
    fputs(value, stdout);
    return;
  }
  size_t n = 0, i = 0;
  for (; value[i] != '\0'; i++) {
    if (((unsigned char)value[i] & 0xC0) != 0x80) {
      if (n == 41) break;
      n++;
    }
  }
  printf("%.*s...", (int)i, value);
}

/* ---- the specification — the one the Dart sample authors ------------------ */

/* An attribute: headline, column, description and physical type. */
static void attribute(SpecDocument *doc, SomList *list, const char *headline, const char *column,
                      const char *description, const char *physical) {
  char *path = som_list_add_on(list, K_AUTHORED_MONTH, K_AUTHORED_DAY);
  DataAttributeEntry a;
  data_attribute_entry_init(&a, doc, path);
  som_node_set_headline(&a.node, headline);
  DataAttributeEntryIdentityForm identity = data_attribute_entry_identity(&a);
  data_attribute_entry_identity_form_set_column_name(&identity, column);
  data_attribute_entry_identity_form_set_description(&identity, description);
  DataAttributeEntryDataTypeSpecForm type = data_attribute_entry_data_type_spec(&a);
  data_attribute_entry_data_type_spec_form_set_physical_type(&type, physical);
  data_attribute_entry_data_type_spec_form_free(&type);
  data_attribute_entry_identity_form_free(&identity);
  data_attribute_entry_free(&a);
  free(path);
}

/* A key: headline, type, columns, description and (when given) generation. */
static void key(SpecDocument *doc, SomList *list, const char *headline, const char *type, const char *columns,
                const char *description, const char *generation) {
  char *path = som_list_add_on(list, K_AUTHORED_MONTH, K_AUTHORED_DAY);
  KeyAttributeEntry k;
  key_attribute_entry_init(&k, doc, path);
  som_node_set_headline(&k.node, headline);
  KeyAttributeEntryContentForm content = key_attribute_entry_content(&k);
  key_attribute_entry_content_form_set_key_type(&content, type);
  key_attribute_entry_content_form_set_key_columns(&content, columns);
  key_attribute_entry_content_form_set_description(&content, description);
  key_attribute_entry_content_form_free(&content);
  if (generation != NULL) {
    KeyAttributeEntryGenerationForm gen = key_attribute_entry_generation(&k);
    key_attribute_entry_generation_form_set_generation_strategy(&gen, generation);
    key_attribute_entry_generation_form_free(&gen);
  }
  key_attribute_entry_free(&k);
  free(path);
}

/* An entity: its identity and classification, returned bound (caller frees). */
static void entity(SpecDocument *doc, SomList *entities, DataEntityEntry *out, const char *headline,
                   const char *content, const char *name, const char *table, const char *alias,
                   const char *description, const char *category, const char *aggregate_root) {
  char *path = som_list_add_on(entities, K_AUTHORED_MONTH, K_AUTHORED_DAY);
  data_entity_entry_init(out, doc, path);
  free(path);
  som_node_set_headline(&out->node, headline);
  data_entity_entry_set_content(out, content);
  DataEntityEntryIdentityForm identity = data_entity_entry_identity(out);
  data_entity_entry_identity_form_set_entity_name(&identity, name);
  data_entity_entry_identity_form_set_table_name(&identity, table);
  data_entity_entry_identity_form_set_entity_alias(&identity, alias);
  data_entity_entry_identity_form_set_description(&identity, description);
  data_entity_entry_identity_form_free(&identity);
  DataEntityEntryClassificationForm classification = data_entity_entry_classification(out);
  data_entity_entry_classification_form_set_category(&classification, category);
  data_entity_entry_classification_form_set_bounded_context(&classification, "Ordering");
  if (aggregate_root != NULL) {
    data_entity_entry_classification_form_set_aggregate_root(&classification, aggregate_root);
  }
  data_entity_entry_classification_form_free(&classification);
}

/* Two entities, four attributes and their keys: one area populated and the
 * rest empty. `aggregate_roots` false clears the one required field variant B
 * removes — `DAENT-CLAS.aggregateRoot` — and nothing else. */
static void author_specification(SpecDocument *doc, int aggregate_roots) {
  D00SolutionBlueprint sbp;
  if (d00_solution_blueprint_new(&sbp, doc, "", NULL) != 0) {
    fprintf(stderr, "failed to create the typed root\n");
    exit(1);
  }
  d00_solution_blueprint_set_content(&sbp, "Order intake for a single region.");

  /* The bounded context CE-SU's required `boundedContext` argument resolves
   * against: an unauthored registry would make the reference dangle at A2. */
  SolutionArchitectureAndTechnology sat = d00_solution_blueprint_solution_architecture_and_technology(&sbp);
  TechnicalFrameworkConcept framework = solution_architecture_and_technology_technical_framework(&sat);
  SoftwareDesignRequirements design = technical_framework_concept_software_design(&framework);
  LayeringAndModuleStructure layering = software_design_requirements_layering_and_module_structure(&design);
  SomList contexts = layering_and_module_structure_bounded_contexts(&layering);
  char *ordering_path = som_list_add_on(&contexts, K_AUTHORED_MONTH, K_AUTHORED_DAY);
  BoundedContextEntry ordering;
  bounded_context_entry_init(&ordering, doc, ordering_path);
  som_node_set_headline(&ordering.node, "Ordering");
  BoundedContextEntryContentForm ordering_content = bounded_context_entry_content(&ordering);
  bounded_context_entry_content_form_set_context_name(&ordering_content, "Ordering");
  bounded_context_entry_content_form_set_domain_area(&ordering_content, "Order management");
  bounded_context_entry_content_form_free(&ordering_content);
  bounded_context_entry_free(&ordering);
  free(ordering_path);
  som_list_free(&contexts);
  layering_and_module_structure_free(&layering);
  software_design_requirements_free(&design);
  technical_framework_concept_free(&framework);
  solution_architecture_and_technology_free(&sat);

  InformationAndDataModel idm = d00_solution_blueprint_information_and_data_model(&sbp);
  DataModel data_model = information_and_data_model_data_model(&idm);
  SomList entities = data_model_entities(&data_model);

  DataEntityEntry customer;
  entity(doc, &entities, &customer, "Customer", "A party that places orders.", "Customer", "customers", "CUST",
         "A person or organisation that places orders.", "MasterData", aggregate_roots ? "Customer" : NULL);
  SomList customer_attributes = data_entity_entry_attributes(&customer);
  attribute(doc, &customer_attributes, "email", "email", "The address order confirmations are sent to.", "VARCHAR");
  attribute(doc, &customer_attributes, "displayName", "display_name", "The name the customer trades under.",
            "VARCHAR");
  /* A customer is identified by the address it trades under: a natural key. */
  SomList customer_keys = data_entity_entry_key_attributes(&customer);
  key(doc, &customer_keys, "pk_customers", "Natural", "email", "A customer is identified by its e-mail address.", NULL);
  som_list_free(&customer_keys);
  som_list_free(&customer_attributes);
  data_entity_entry_free(&customer);

  DataEntityEntry order;
  entity(doc, &entities, &order, "Order", "One accepted customer order.", "Order", "orders", "ORD",
         "A single order placed by a customer.", "TransactionData", aggregate_roots ? "Order" : NULL);
  SomList order_attributes = data_entity_entry_attributes(&order);
  attribute(doc, &order_attributes, "orderId", "order_id", "The identifier the order is filed under.", "UUID");
  SomList order_keys = data_entity_entry_key_attributes(&order);
  key(doc, &order_keys, "pk_orders", "Primary", "order_id", "The order identifier.", "UUID");
  attribute(doc, &order_attributes, "placedAt", "placed_at", "The moment the order was accepted.", "TIMESTAMP");
  som_list_free(&order_keys);
  som_list_free(&order_attributes);
  data_entity_entry_free(&order);

  som_list_free(&entities);
  data_model_free(&data_model);
  information_and_data_model_free(&idm);
  d00_solution_blueprint_free(&sbp);
}

/* ---- stage 1 — the mechanical gate (codespecs_prompt.md §4) ---------------- */

static const char *const TITLES[CODESPECS_GATE_CHECK_COUNT] = {
    "schema completeness  ", "instance-tier values ", "routing totality     ",
    "required arguments   ", "structured carriers  ",
};

/* Runs the mechanical tier over `doc` into `*report` (caller frees) and prints
 * each check's verdict. All five checks run as one gate and none stops the
 * others; a check that could not run says so, and the gate does not pass. */
static void run_gate(const Inputs *in, const SpecDocument *doc, CodeSpecsGateReport *report) {
  printf("1. The starting prompt's quality gate        [MECHANICAL]\n");
  CodeSpecsGate gate = spec_codespecs_gate_make(in->model, doc, &in->catalog, in->schema, K_ROOT);
  char *err = NULL;
  if (!spec_codespecs_gate_run(&gate, report, &err)) {
    fprintf(stderr, "gate: %s\n", err != NULL ? err : "?");
    free(err);
    exit(1);
  }
  for (int c = 0; c < CODESPECS_GATE_CHECK_COUNT; c++) {
    const CodeSpecsGateCheckResult *r = &report->results[c];
    printf("   %s %s: ", spec_codespecs_gate_check_label(r->check), TITLES[r->check]);
    if (!r->ran) {
      printf("NOT RUN — %s\n", r->not_run_reason);
    } else if (r->findings_len == 0) {
      printf("pass — 0 findings\n");
    } else {
      printf("FAIL — %zu findings\n", r->findings_len);
    }
  }
  printf("   (A4 held %zu required-argument rows, A5 %zu carriers, both from the catalogue's gate tables)\n",
         in->catalog.required_arguments_len, in->catalog.carriers_len);
}

/* ---- stage 2 — the extract generator ---------------------------------------- */

static void stage2(const CodeSpecsExtractList *extracts) {
  printf("2. The extract generator                      [MECHANICAL]\n");
  size_t populated = 0;
  for (size_t i = 0; i < extracts->len; i++) {
    if (extracts->items[i].entries_len > 0) populated++;
  }
  printf("   areas in the catalogue   : %zu\n", extracts->len);
  printf("   populated                : %zu\n", populated);
  for (size_t i = 0; i < extracts->len; i++) {
    const CodeSpecsExtract *e = &extracts->items[i];
    if (e->entries_len == 0) continue;
    printf("     %-6s %zu entries  → ", e->area->code, e->entries_len);
    for (size_t p = 0; p < e->projects.len; p++) printf("%s%s", p == 0 ? "" : ", ", e->projects.items[p]);
    printf("\n");
  }
  printf("   empty                    : %zu\n", extracts->len - populated);
  printf("   Most areas are empty because this document says nothing about\n");
  printf("   screens, jobs, reports or migrations. An empty extract is a\n");
  printf("   CANDIDATE for \"not applicable\" — never the verdict itself, which\n");
  printf("   is a judgment and belongs to stage B (codespecs_prompt.md §6.4).\n");

  mkdir("build", 0755);
  mkdir("build/codespecs_extracts", 0755);
  for (size_t i = 0; i < extracts->len; i++) {
    const CodeSpecsExtract *e = &extracts->items[i];
    char *stem = spec_codespecs_extract_file_stem(e);
    char *yaml = spec_codespecs_extract_to_yaml(e);
    char *md = spec_codespecs_extract_to_markdown(e);
    char path[512];
    snprintf(path, sizeof path, "build/codespecs_extracts/%s.yaml", stem);
    write_file(path, yaml);
    snprintf(path, sizeof path, "build/codespecs_extracts/%s.md", stem);
    write_file(path, md);
    free(md);
    free(yaml);
    free(stem);
  }
  printf("\n");

  const CodeSpecsExtract *db = NULL;
  for (size_t i = 0; i < extracts->len && db == NULL; i++) {
    if (strcmp(extracts->items[i].area->code, "CE-DB") == 0) db = &extracts->items[i];
  }
  printf("   Area %s — %s, the extract the\n", db->area->code, db->area->canonical_id);
  printf("   authoring agent reads in stage 3:\n");
  printf("   built on   : %s\n", db->area->built_on);
  printf("   may cite   : ");
  for (size_t p = 0; p < db->citable_parts.len; p++) {
    printf("%s%s", p == 0 ? "" : ", ", db->citable_parts.items[p]);
  }
  printf("\n");
  printf("   entries carried to the agent (%zu):\n", db->entries_len);
  for (size_t i = 0; i < db->entries_len; i++) {
    printf("     %-11s %-14s ", db->entries[i].section_id, db->entries[i].field_name);
    print_short(db->entries[i].value);
    printf("\n");
  }
  printf("\n");
}

static void stages3and4(void) {
  printf("3. The authoring agent                        [JUDGMENT]\n");
  printf("4. Validating the emitted trio                [MECHANICAL]\n");
  printf("   Not in the C runtime. The authoring agent writes the IR\n");
  printf("   from these extracts, and the Dart tools map and validate it\n");
  printf("   (`tomspecs :ir-map`, `tomspecs :codespecs-validate`); the Dart\n");
  printf("   sample in ../bin/ shows both stages on this same specification.\n");
  printf("\n");
}

/* ---- the two variants ------------------------------------------------------- */

/* Variant A — a document that passes, taken as far as the extracts. Returns
 * the number of extracts written. */
static size_t variant_a(const Inputs *in) {
  SpecDocument doc;
  spec_document_init(&doc);
  author_specification(&doc, 1);

  rule("Variant A — a sufficient specification");
  printf("0. The document under Phase 4                 [input]\n");
  printf("   a Solution Blueprint whose information model holds 2 entities\n");
  printf("   and 4 stored attributes; every other section is unwritten.\n");
  printf("\n");

  CodeSpecsGateReport report;
  run_gate(in, &doc, &report);
  if (!spec_codespecs_gate_report_passed(&report)) {
    fprintf(stderr, "variant A was supposed to pass the gate\n");
    exit(1);
  }
  printf("   gate verdict             : PASS — the run may begin\n");
  printf("\n");

  /* A passed gate always carries its extracts. */
  stage2(&report.extracts);
  stages3and4();
  size_t count = report.extracts.len;
  spec_codespecs_gate_report_free(&report);
  spec_document_free(&doc);
  return count;
}

/* Variant B — the same document with one required field cleared. */
static void variant_b(const Inputs *in) {
  SpecDocument doc;
  spec_document_init(&doc);
  author_specification(&doc, 0);

  rule("Variant B — the same document, one required field cleared");
  printf("Both entities keep their `DAENT-CLAS` section and its `category`, and\n");
  printf("both have `aggregateRoot` cleared. Nothing else changed.\n");
  printf("\n");

  CodeSpecsGateReport report;
  run_gate(in, &doc, &report);
  if (spec_codespecs_gate_report_passed(&report)) {
    fprintf(stderr, "variant B was supposed to be rejected\n");
    exit(1);
  }
  printf("   gate verdict             : REJECTED — the run may not begin\n");
  printf("\n");
  printf("   What the gate names, per finding:\n");
  for (size_t i = 0; i < spec_codespecs_gate_report_finding_count(&report); i++) {
    const CodeSpecsGateFinding *f = spec_codespecs_gate_report_finding_at(&report, i);
    printf("     %s %s [%s] %s\n", spec_codespecs_gate_check_label(f->check), f->code, f->location, f->message);
  }
  printf("\n");
  size_t a2 = spec_codespecs_gate_report_result(&report, CODESPECS_GATE_A2)->findings_len;
  printf("   A2 moved too: %zu violations, against 0 for variant A. The\n", a2);
  printf("   classification form still holds other values, so its empty\n");
  printf("   required field is reported by both tiers. They part where a value\n");
  printf("   is absent rather than empty: a missing required section is seen by\n");
  printf("   A1 alone. That is why the gate runs both tiers and not either one\n");
  printf("   (codespecs_prompt.md §4.1/§4.2 and its §10.1/§10.2 fixtures).\n");
  printf("\n");
  spec_codespecs_gate_report_free(&report);
  spec_document_free(&doc);
}

int main(void) {
  Inputs in;
  char *err = NULL;

  char *meta = read_checkout("tom_som_c_v0/meta/spec_model.meta.json");
  in.model = spec_model_from_json_str(meta, &err);
  free(meta);
  if (in.model == NULL) {
    fprintf(stderr, "model: %s\n", err != NULL ? err : "?");
    free(err);
    return 1;
  }
  char *schema_text = read_checkout(
      "tom_som_c_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml");
  if (!docspecs_schema_from_yaml_text(schema_text, &in.schema, &err)) {
    fprintf(stderr, "schema: %s\n", err != NULL ? err : "?");
    free(err);
    return 1;
  }
  free(schema_text);
  char *catalog_text = read_checkout("tom_specs_model/generated-doc/codespecs/codespecs_areas.json");
  SomJson *catalog_json = som_json_parse(catalog_text, &err);
  free(catalog_text);
  if (catalog_json == NULL || !spec_codespecs_area_catalog_from_json(catalog_json, &in.catalog, &err)) {
    fprintf(stderr, "catalogue: %s\n", err != NULL ? err : "?");
    free(err);
    return 1;
  }
  som_json_free(catalog_json);

  rule("A Phase 4 CodeSpecs run, stage by stage");
  printf("Every step is marked [MECHANICAL] or [JUDGMENT].\n");
  printf("\n");

  size_t extracts = variant_a(&in);
  variant_b(&in);

  printf("\n");
  printf("Extracts written to build/codespecs_extracts/ (%zu files).\n", extracts * 2);

  spec_codespecs_area_catalog_free(&in.catalog);
  docspecs_schema_free(in.schema);
  spec_model_free(in.model);
  return 0;
}
