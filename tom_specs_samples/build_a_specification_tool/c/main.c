/* TomSpecs sample — building tooling ON a specification (C).
 *
 * The C port of `../bin/build_a_specification_tool.dart`: the same five steps
 * over the same fixture. Its output differs from the Dart sample where the
 * Dart text names a Dart-only surface, and where C names an API differently;
 * `expected_output.txt` here records the C output, and README.md says where it
 * differs.
 *
 * Build and run (from this folder; see README.md):  make && ./build/sample
 *
 * For the reader who is not authoring specifications but writing programs that
 * read them: an editor, a linter, a report, an importer, a migration. That
 * reader needs four things, and this sample walks them in the order they are
 * needed:
 *
 *   1. REFLECTION   — what the model CAN hold, read from the metadata tree
 *   2. GENERIC      — what a document DOES hold, with no compile-time
 *                     knowledge of its shape
 *   3. SCHEMA       — the generated schema, where it comes from and what it is
 *   4. VALIDATION   — the two runtime tiers, and the third that is not here
 *   5. A TOOL       — a completeness report built on all four
 *
 * MEMORY OWNERSHIP, as the runtime headers state it and this file follows it:
 * the reflection lookups (`spec_reflection_*`) BORROW from the model and live
 * as long as it does; `SomStrList` results are filled by the callee and freed
 * with `som_strlist_free`; `const char *` document reads BORROW until the
 * document is next mutated; `char *` results are OWNED and freed with `free`;
 * a `SpecResolution` is released with `spec_resolution_free`, a schema with
 * `docspecs_schema_free`, violations with `docspecs_violation_list_free`,
 * validation errors with `spec_validation_errors_free`. The sample runs clean
 * under AddressSanitizer and a leak checker (`tool/validate.sh`).
 */
#include "tom_som_c_v0.h"
#include "tom_som_c_v0_meta.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef TOMSPECS_CHECKOUT
#define TOMSPECS_CHECKOUT "../../.."
#endif

/* The document root this sample inspects. */
static const char *const K_ROOT = "D00SolutionBlueprint";
/* That root's addressable segment — the first element of every path in it. */
static const char *const K_ROOT_SEGMENT = "SBP";
/* The creation date section-id generation is pinned to (1 January): an
 * unpinned run would emit different ids every day. */
static const long long K_AUTHORED_MONTH = 1, K_AUTHORED_DAY = 1;
/* The report's title column width; titles are clipped, never wrapped. */
#define K_TITLE_WIDTH 38
static const long long DAY_SECONDS = 24 * 3600;

/* ---- small helpers -------------------------------------------------------- */

static char *read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    fprintf(stderr, "cannot read %s\n", path);
    exit(1);
  }
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  fseek(f, 0, SEEK_SET);
  char *buf = malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  fclose(f);
  buf[got] = '\0';
  return buf;
}

static void section(int n, const char *title) {
  printf("\n");
  for (int i = 0; i < 74; i++) putchar('=');
  printf("\n%d. %s\n", n, title);
  for (int i = 0; i < 74; i++) putchar('=');
  printf("\n");
}

/* The number of UTF-8 code points in s[0..len). */
static size_t utf8_len(const char *s, size_t len) {
  size_t n = 0;
  for (size_t i = 0; i < len; i++) {
    if (((unsigned char)s[i] & 0xC0) != 0x80) n++;
  }
  return n;
}

/* The byte offset of code point `cp` in s (or strlen(s)). */
static size_t utf8_offset(const char *s, size_t cp) {
  size_t i = 0, n = 0;
  while (s[i] != '\0') {
    if (((unsigned char)s[i] & 0xC0) != 0x80) {
      if (n == cp) return i;
      n++;
    }
    i++;
  }
  return i;
}

/* Prints `s` padded with spaces to `width` code points. */
static void print_padded(const char *s, size_t width) {
  fputs(s, stdout);
  for (size_t n = utf8_len(s, strlen(s)); n < width; n++) putchar(' ');
}

/* `s` with newlines flattened, clipped to `width` code points with an
 * ellipsis. Owned. */
static char *clip(const char *s, size_t width) {
  char *flat = strdup(s != NULL ? s : "");
  for (char *p = flat; *p; p++) {
    if (*p == '\n') *p = ' ';
  }
  if (utf8_len(flat, strlen(flat)) <= width) return flat;
  size_t cut = utf8_offset(flat, width - 1);
  char *out = malloc(cut + 4);
  memcpy(out, flat, cut);
  memcpy(out + cut, "\xE2\x80\xA6", 4); /* … */
  free(flat);
  return out;
}

static void print_clipped(const char *s, size_t width) {
  char *c = clip(s, width);
  fputs(c, stdout);
  free(c);
}

static long pct(long written, long offered) {
  return lround(100.0 * (double)written / (double)offered);
}

/* A field kind by the name the Dart enum gives it (`enum` is `enumValue`). */
static const char *kind_name(const char *kind) {
  return strcmp(kind, SPEC_FIELD_KIND_ENUM) == 0 ? "enumValue" : kind;
}

static void print_opt(int has, long long value) {
  if (has) printf("%lld", value);
  else printf("null");
}

/* ---- the fixture ---------------------------------------------------------- */

/* Writes the small, deliberately incomplete document this run inspects — the
 * same one the Dart sample writes. */
static void author_fixture(SpecDocument *doc) {
  D00SolutionBlueprint sbp;
  if (d00_solution_blueprint_new(&sbp, doc, "", NULL) != 0) {
    fprintf(stderr, "failed to create the typed root\n");
    exit(1);
  }
  d00_solution_blueprint_set_content(&sbp, "A platform that unifies our fragmented order systems.");

  IntroductionAndScope intro = d00_solution_blueprint_introduction_and_scope(&sbp);
  introduction_and_scope_set_content(&intro, "Replace three regional order desks with one intake service.");
  introduction_and_scope_free(&intro);

  CurrentLandscape landscape = d00_solution_blueprint_current_landscape(&sbp);
  current_landscape_set_content(&landscape, "Three legacy systems with no shared customer record.");
  SomList metrics = current_landscape_operational_metrics(&landscape);
  free(som_list_add_content_on(&metrics, "Average order turnaround: 4.2 days.", K_AUTHORED_MONTH, K_AUTHORED_DAY));
  free(som_list_add_content_on(&metrics, "Manual reconciliation: ~12 hours per week.", K_AUTHORED_MONTH,
                               K_AUTHORED_DAY));
  som_list_free(&metrics);
  current_landscape_free(&landscape);

  InformationAndDataModel idm = d00_solution_blueprint_information_and_data_model(&sbp);
  DataModel data_model = information_and_data_model_data_model(&idm);
  SomList entities = data_model_entities(&data_model);
  char *customer_path = som_list_add_on(&entities, K_AUTHORED_MONTH, K_AUTHORED_DAY);
  DataEntityEntry customer;
  data_entity_entry_init(&customer, doc, customer_path);
  som_node_set_headline(&customer.node, "Customer");
  DataEntityEntryIdentityForm identity = data_entity_entry_identity(&customer);
  data_entity_entry_identity_form_set_entity_name(&identity, "Customer");
  data_entity_entry_identity_form_set_table_name(&identity, "customers");
  data_entity_entry_identity_form_set_description(&identity, "A party that places orders.");
  /* `category` is written and `aggregateRoot` is not, and `aggregateRoot` is
   * REQUIRED — so the schema tier has one real violation to report in step 4. */
  DataEntityEntryClassificationForm classification = data_entity_entry_classification(&customer);
  data_entity_entry_classification_form_set_category(&classification, "MasterData");

  data_entity_entry_classification_form_free(&classification);
  data_entity_entry_identity_form_free(&identity);
  data_entity_entry_free(&customer);
  free(customer_path);
  som_list_free(&entities);
  data_model_free(&data_model);
  information_and_data_model_free(&idm);
  d00_solution_blueprint_free(&sbp);
}

/* ---- 1. Reflection -------------------------------------------------------- */

static void reflection_step(const SpecModel *model, const SomJson *meta_json) {
  section(1, "Reflection — what the model CAN hold");
  printf("`SpecModel` is the exported class graph; `SpecReflection` is the\n");
  printf("value-free query surface over it. No document is involved here.\n\n");

  printf("THE TWO VERSION STAMPS. They answer different questions and a tool\n");
  printf("that checks one for the other will accept a file it cannot read:\n");
  printf("  modelVersion      = %lld  — WHICH MODEL this snapshot describes\n", model->model_version);
  printf("  metaSchemaVersion = ");
  print_opt(model->has_meta_schema_version, model->meta_schema_version);
  printf("  — the FILE FORMAT the snapshot itself is written in\n");
  printf("  modelVersionLabel = %s\n", model->model_version_label);
  /* `generated_at` holds epoch seconds; the stamp is printed as the snapshot
   * writes it. */
  printf("  generatedAt       = %s\n", som_json_str_or(meta_json, "generatedAt"));
  printf("\n");
  printf("A tool reads `metaSchemaVersion` to decide whether it can parse the\n");
  printf("file at all, and `modelVersion` to decide whether the documents it\n");
  printf("holds are the ones this model describes. `modelVersionLabel` is a\n");
  printf("build label for humans — never branch on it.\n\n");

  /* A snapshot is a photograph. `spec_model_check_stamp` compares what the
   * exporter DECLARED against what survived to the reader, and ages the file
   * out. `now` is derived from the model's own stamp so the printed age stays
   * at exactly the offset this sample means to demonstrate; the 30-day
   * threshold is the other runtimes' default. */
  long long exported_at = model->has_generated_at ? model->generated_at : 1767225600LL; /* 2026-01-01 */
  SpecModelStampCheck stamp = spec_model_check_stamp(model, 30 * DAY_SECONDS, exported_at + 3 * DAY_SECONDS);
  printf("SNAPSHOT CHECK (`spec_model_check_stamp`), against a fixed clock:\n");
  printf("  age                 : ");
  print_opt(stamp.has_age, stamp.age_seconds / DAY_SECONDS);
  printf(" days (aged: %s)\n", spec_stamp_check_is_aged(&stamp) ? "true" : "false");
  printf("  classes  declared/actual : ");
  print_opt(stamp.has_declared_class_count, stamp.declared_class_count);
  printf("/%lld  disagrees: %s\n", stamp.actual_class_count,
         spec_stamp_check_class_count_disagrees(&stamp) ? "true" : "false");
  printf("  roots    declared/actual : ");
  print_opt(stamp.has_declared_root_count, stamp.declared_root_count);
  printf("/%lld  disagrees: %s\n", stamp.actual_root_count,
         spec_stamp_check_root_count_disagrees(&stamp) ? "true" : "false");
  printf("  Declared-vs-actual is not redundant: the declared value is what\n");
  printf("  the exporter recorded, the actual value is what survived to the\n");
  printf("  reader, and a truncated file is exactly where they part.\n\n");

  SpecReflection reflection = spec_reflection_make(model);
  size_t roots_len = 0, classes_len = 0;
  spec_reflection_roots(&reflection, &roots_len);
  spec_reflection_classes(&reflection, &classes_len);
  printf("SHAPE:\n");
  printf("  document roots : %zu\n", roots_len);
  printf("  classes        : %zu\n", classes_len);
  printf("  container root : %s — the one true tree root, which is not itself a document\n\n",
         model->container_root);

  const SpecRoot *root = spec_reflection_root_for_segment(&reflection, "SBP");
  size_t fields_len = 0;
  const SpecField *fields = spec_reflection_fields_of(&reflection, root->type, &fields_len);
  printf("FIELDS of %s (%zu total, first 4):\n", root->type, fields_len);
  for (size_t i = 0; i < 4 && i < fields_len; i++) {
    printf("  %-24s kind=%-8s %s\n", fields[i].name, kind_name(fields[i].kind),
           fields[i].type != NULL ? fields[i].type : "");
  }
  printf("\n");

  /* A form's slots are on the field itself, not on a separate class — the
   * shape a tool must handle to render or fill one. */
  size_t entity_len = 0;
  const SpecField *entity_fields = spec_reflection_fields_of(&reflection, "DataEntityEntry", &entity_len);
  const SpecField *form = NULL;
  for (size_t i = 0; i < entity_len && form == NULL; i++) {
    if (strcmp(entity_fields[i].kind, SPEC_FIELD_KIND_FORM) == 0) form = &entity_fields[i];
  }
  printf("FORM SLOTS of DataEntityEntry.%s (section id %s):\n", form->name, form->section_id);
  for (size_t i = 0; i < form->form_fields_len; i++) {
    printf("  %-16s %s\n", form->form_fields[i].name, form->form_fields[i].label);
  }
  printf("\n");

  printf("ANNOTATIONS the meta carries — the model's own metadata, exported\n");
  printf("into the snapshot and therefore visible in ALL NINE language\n");
  printf("runtimes, not just Dart:\n");
  size_t ann_len = 0;
  const SpecAnnotation *anns = spec_reflection_annotations_of(&reflection, root->type, &ann_len);
  for (size_t i = 0; i < ann_len; i++) {
    printf("  @%s", anns[i].name);
    const SomJson *args = anns[i].arguments;
    if (args != NULL && args->type == SOM_JSON_OBJECT && args->as.object.len > 0) {
      printf("(");
      for (size_t k = 0; k < args->as.object.len; k++) {
        printf("%s%s", k == 0 ? "" : ", ", args->as.object.members[k].key);
      }
      printf(")");
    }
    printf("\n");
  }
  /* The display semantics of these annotations (`kRenderedAnnotations`) are
   * in the Dart runtime only: they are what the two Flutter apps share. */
  printf("  How each is displayed is the Dart runtime's (`kRenderedAnnotations`,\n");
  printf("  shared by the two Flutter apps); the annotations themselves are\n");
  printf("  data every runtime reads.\n\n");

  printf("PATH RESOLUTION — a document path to the model node it lands on:\n");
  const char *paths[] = {"SBP", "SBP/content", "SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST",
                         "SBP/informationAndDataModel/nosuchthing"};
  for (size_t i = 0; i < 4; i++) {
    SpecResolution r;
    printf("  %-50s ", paths[i]);
    if (spec_reflection_resolve(&reflection, paths[i], &r)) {
      printf("kind=%s  leaf=%s\n", r.kind, spec_resolution_is_value_leaf(&r) ? "true" : "false");
      spec_resolution_free(&r);
    } else {
      printf("(unresolved)\n");
    }
  }
}

/* ---- 2. Generic access ---------------------------------------------------- */

static void generic_access(const SpecModel *model, const SpecDocument *doc) {
  section(2, "Generic access — what the document DOES hold");
  printf("`SpecDocument` is a sparse, path-keyed store. A tool reads it\n");
  printf("without knowing the document's shape, and asks the model what each\n");
  printf("path means. That pairing is the whole of generic access.\n\n");

  SpecReflection reflection = spec_reflection_make(model);
  SomStrList paths;
  printf("EVERY written content leaf, resolved against the model:\n");
  spec_document_content_paths(doc, &paths); /* byte-sorted */
  for (size_t i = 0; i < paths.len; i++) {
    SpecResolution r;
    int ok = spec_reflection_resolve(&reflection, paths.items[i], &r);
    printf("  %-52s %s\n", paths.items[i], ok ? r.kind : "?");
    if (ok) spec_resolution_free(&r);
    printf("      ");
    print_clipped(spec_document_content(doc, paths.items[i]), 66);
    printf("\n");
  }
  som_strlist_free(&paths);
  printf("\n");

  printf("EVERY written form section, slot by slot:\n");
  spec_document_form_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    printf("  %s\n", paths.items[i]);
    SomStrList slots;
    spec_document_form_field_names(doc, paths.items[i], &slots);
    for (size_t k = 0; k < slots.len; k++) {
      printf("      %-16s ", slots.items[k]);
      print_clipped(spec_document_form_field(doc, paths.items[i], slots.items[k]), 52);
      printf("\n");
    }
    som_strlist_free(&slots);
  }
  som_strlist_free(&paths);
  printf("\n");

  printf("EVERY list, with its items' section ids:\n");
  spec_document_list_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    printf("  %-52s %zu item(s)\n", paths.items[i], spec_document_list_item_count(doc, paths.items[i]));
    SomStrList ids;
    spec_document_list_item_section_ids(doc, paths.items[i], &ids);
    for (size_t k = 0; k < ids.len; k++) printf("      %s\n", ids.items[k]);
    som_strlist_free(&ids);
  }
  som_strlist_free(&paths);
  printf("\n");

  const SomMetaTree *tree = d00_solution_blueprint_meta_tree();
  printf("WHERE PATHS COME FROM. A tool must never hard-code a path literal —\n");
  printf("a literal is undiscoverable and rots silently when the model moves.\n");
  printf("Two safe sources, both from the generated metadata module:\n\n");
  printf("  1. the generated metadata refs —\n");
  printf("     information_and_data_model_nav_data_model(d00_solution_blueprint_nav_information_and_data_model(…)).ref.path\n");
  som_nav_d00_solution_blueprint sbp_nav = d00_solution_blueprint_meta(tree);
  som_nav_information_and_data_model idm_nav = d00_solution_blueprint_nav_information_and_data_model(sbp_nav);
  som_nav_data_model dm_nav = information_and_data_model_nav_data_model(idm_nav);
  printf("       = %s\n", dm_nav.ref.path);
  som_meta_ref_free(&dm_nav.ref);
  som_meta_ref_free(&idm_nav.ref);
  som_meta_ref_free(&sbp_nav.ref);
  printf("  2. the id-keyed metadata tree, for a path known only at runtime —\n");
  printf("     som_meta_tree_by_id(tree, \"DAENT-ENTI-LST\")\n");
  const SomMetaNode *node = som_meta_tree_by_id(tree, "DAENT-ENTI-LST");
  const char *node_path = NULL;
  printf("       = %s\n", node != NULL && som_meta_node_path(node, &node_path, NULL) ? node_path : "NULL");
  printf("\n");
  printf("  The tree also goes the other way: som_meta_tree_by_path gives the\n");
  printf("  node, and with it the class, kind and children a generic renderer\n");
  printf("  needs.\n");
  const SomMetaNode *by_path = som_meta_tree_by_path(tree, "SBP/informationAndDataModel/dataModel");
  printf("     som_meta_tree_by_path(tree, \"SBP/informationAndDataModel/dataModel\")\n");
  printf("       class=%s kind=%s children=%zu\n", by_path->class_name, by_path->kind, by_path->children_len);
}

/* ---- 3. The generated schema ---------------------------------------------- */

static void the_schema(const DocSpecsSchema *schema) {
  section(3, "The generated schema");
  printf("Each of the 14 document roots has a schema GENERATED from the model\n");
  printf("and SHIPPED as data inside the facade package, under\n");
  printf("`schemas/<document>/<document>.1.0.docspecs-schema.yaml`. A tool\n");
  printf("loads one; it never writes one, and never derives one itself.\n\n");
  printf("IT IS A DocSpecs SCHEMA, NOT JSON SCHEMA. It describes a *markdown*\n");
  printf("document — headings, their ids, their formats, the form fields a\n");
  printf("section carries and which of them are required. A tool reaching for\n");
  printf("a JSON-Schema validator will not find one, because the artifact the\n");
  printf("schema governs is not JSON.\n\n");
  char *root_id = docspecs_schema_root_section_id(schema);
  printf("  root section id : %s\n", root_id);
  free(root_id);
  printf("  section types   : %zu\n\n", schema->section_types_len);
  printf("  That count is large because a Solution Blueprint SEEDS the twelve\n");
  printf("  Phase-3 documents: its own section classes ARE those documents'\n");
  printf("  types, so its schema covers every section id they define. Step 5\n");
  printf("  meets the same fact from the other side.\n\n");
  printf("  A section type resolves by ID PREFIX, which is how a generated id\n");
  printf("  like `DAENT-ENTI-7` finds its type without the schema listing\n");
  printf("  every instance:\n");
  const char *ids[] = {"DAENT-IDEN", "DAENT-ENTI-7", "NOSUCH-1"};
  for (size_t i = 0; i < 3; i++) {
    const DocSpecsSectionType *t = docspecs_schema_resolve_section_type(schema, ids[i]);
    printf("    %-16s -> %s\n", ids[i], t != NULL ? t->prefix : "(no type — a tool treats this as unknownSection)");
  }
}

/* ---- 4. Validation -------------------------------------------------------- */

/* The document tier's findings over `doc`'s rendition; caller frees `*out`. */
static void document_tier(const SpecModel *model, const DocSpecsSchema *schema, const SpecDocument *doc,
                          DocSpecsViolationList *out) {
  char *markdown = spec_document_to_markdown(doc, model, K_ROOT, NULL);
  DocSpecsValidator validator = docspecs_validator_new(schema);
  docspecs_violation_list_init(out);
  docspecs_validator_validate_markdown(&validator, markdown, out);
  free(markdown);
}

static void validation(const SpecModel *model, const DocSpecsSchema *schema, const SpecDocument *doc) {
  section(4, "Validation — three tiers, two of them here");
  printf("THIS IS THE DISTINCTION TOOLING AUTHORS MISS. A tool that wants one\n");
  printf("tier and calls another gets nothing useful — not an error, just an\n");
  printf("empty list that reads like a pass.\n\n");
  printf("  STATIC tier   — checks the MODEL'S OWN ANNOTATIONS: field-type\n");
  printf("                  rules, @ContentType compatibility, cycles, the\n");
  printf("                  §10.2 structural invariants. Runs ONCE at\n");
  printf("                  generation time, in\n");
  printf("                  `tom_specs_clitool/lib/src/validator.dart`, and is\n");
  printf("                  deliberately NOT part of the nine-language runtime\n");
  printf("                  surface. Not reachable from this sample, and that\n");
  printf("                  is the point: by the time a document exists, this\n");
  printf("                  tier has already run.\n");
  printf("  INSTANCE tier — checks A DOCUMENT'S VALUES against the model:\n");
  printf("                  `validate_document` (SOM §9). In every runtime.\n");
  printf("  DOCUMENT tier — checks a MARKDOWN RENDITION against the generated\n");
  printf("                  schema: `DocSpecsValidator` (SOM §14).\n\n");
  printf("The two runtime tiers overlap and neither implies the other:\n");
  printf("`validate_document` reports a required field left empty in a form the\n");
  printf("document holds, but not a required section that is absent; the\n");
  printf("schema validator reports the absent section, but does not follow a\n");
  printf("reference it sees filled. A tool that wants \"is this document good?\"\n");
  printf("runs BOTH.\n\n");

  SpecValidationErrors instance;
  validate_document(model, doc, &instance);
  DocSpecsViolationList document;
  document_tier(model, schema, doc, &document);
  printf("THE FIXTURE, both tiers:\n");
  printf("  instance tier : %zu error(s)\n", instance.len);
  printf("  document tier : %zu violation(s)\n", document.len);
  for (size_t i = 0; i < document.len && i < 4; i++) {
    printf("    line %d: %s [%s] ", document.items[i].line, document.items[i].rule, document.items[i].section_id);
    print_clipped(document.items[i].message, 54);
    printf("\n");
  }
  if (document.len > 4) printf("    … and %zu more\n", document.len - 4);
  printf("\n");
  spec_validation_errors_free(&instance);
  docspecs_violation_list_free(&document);

  /* A document broken on purpose, to show the instance tier firing where the
   * document tier cannot see anything wrong. */
  SpecDocument broken;
  spec_document_init(&broken);
  author_fixture(&broken);
  spec_document_set_content(&broken, "SBP/informationAndDataModel/nosuchsection/content", "x");
  spec_document_set_form_field(&broken, "SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAENT-IDEN",
                               "notAField", "x");
  printf("A DELIBERATELY BROKEN COPY — one path the model does not have, one\n");
  printf("form slot the form does not declare:\n");
  SpecValidationErrors broken_errors;
  validate_document(model, &broken, &broken_errors);
  for (size_t i = 0; i < broken_errors.len; i++) {
    printf("  %-20s ", broken_errors.items[i].code);
    print_clipped(broken_errors.items[i].path, 50);
    printf("\n");
  }
  printf("\n");
  spec_validation_errors_free(&broken_errors);
  spec_document_free(&broken);

  printf("THE CLOSED VERDICT SETS. C has them as closed lists of string\n");
  printf("constants, so a tool switches over them exhaustively rather than\n");
  printf("matching on message text:\n");
  printf("  SPEC_VALIDATION_ALL_CODES (%d): ", SPEC_VALIDATION_ALL_CODES_COUNT);
  for (int i = 0; i < SPEC_VALIDATION_ALL_CODES_COUNT; i++) {
    printf("%s%s", i == 0 ? "" : ", ", SPEC_VALIDATION_ALL_CODES[i]);
  }
  printf("\n");
  printf("  DOCSPECS_ALL_RULES (%d):\n", DOCSPECS_ALL_RULES_COUNT);
  for (int i = 0; i < DOCSPECS_ALL_RULES_COUNT; i += 4) {
    printf("    ");
    for (int k = i; k < i + 4 && k < DOCSPECS_ALL_RULES_COUNT; k++) {
      printf("%s%s", k == i ? "" : ", ", DOCSPECS_ALL_RULES[k]);
    }
    printf("\n");
  }
}

/* ---- 5. The tool ---------------------------------------------------------- */

typedef struct {
  char *title; /* owned */
  long offered;
  long written;
} CoverageRow;

typedef struct {
  CoverageRow *rows;
  size_t len;
  long offered;
  long written;
} CoverageReport;

/* A section's title for the report — its model doc comment's first sentence,
 * falling back to the field name where the model carries no doc. Owned. */
static char *row_title(const SpecField *field) {
  const char *doc = field->doc != NULL ? field->doc : "";
  size_t n = strcspn(doc, "\n");
  char *text = strndup(doc, n);
  char *stop = strstr(text, ". ");
  if (stop != NULL) *stop = '\0';
  size_t len = strlen(text);
  while (len > 0 && text[len - 1] == '.') text[--len] = '\0';
  char *start = text;
  while (*start == ' ' || *start == '\t') start++;
  len = strlen(start);
  while (len > 0 && (start[len - 1] == ' ' || start[len - 1] == '\t')) start[--len] = '\0';
  char *title = len == 0 ? strdup(field->name) : clip(start, K_TITLE_WIDTH);
  free(text);
  return title;
}

/* `seen` holds the class names already on this branch, as a NULL-terminated
 * stack; the model is a graph, and a section type that can contain itself
 * would otherwise recurse forever. */
static void walk(const SpecReflection *reflection, const SpecDocument *doc, long *offered, long *written,
                 const SpecField *field, const char *path, const char **seen, size_t seen_len) {
  const char *kind = field->kind;
  if (strcmp(kind, SPEC_FIELD_KIND_CONTENT) == 0 || strcmp(kind, SPEC_FIELD_KIND_SCALAR) == 0 ||
      strcmp(kind, SPEC_FIELD_KIND_ENUM) == 0) {
    (*offered)++;
    if (spec_document_has_content(doc, path)) (*written)++;
  } else if (strcmp(kind, SPEC_FIELD_KIND_FORM) == 0) {
    for (size_t i = 0; i < field->form_fields_len; i++) {
      (*offered)++;
      const char *v = spec_document_form_field(doc, path, field->form_fields[i].name);
      if (v != NULL && *v != '\0') (*written)++;
    }
  } else if (strcmp(kind, SPEC_FIELD_KIND_LIST) == 0) {
    (*offered)++;
    if (spec_document_list_item_count(doc, path) > 0) (*written)++;
  } else if (strcmp(kind, SPEC_FIELD_KIND_SECTION) == 0 || strcmp(kind, SPEC_FIELD_KIND_COMPLEX) == 0) {
    const char *type = field->type;
    if (type == NULL || *type == '\0') return;
    for (size_t i = 0; i < seen_len; i++) {
      if (strcmp(seen[i], type) == 0) return;
    }
    const char **next = malloc((seen_len + 1) * sizeof *next);
    memcpy(next, seen, seen_len * sizeof *next);
    next[seen_len] = type;
    size_t children_len = 0;
    const SpecField *children = spec_reflection_fields_of(reflection, type, &children_len);
    for (size_t i = 0; i < children_len; i++) {
      const char *segment = spec_reflection_field_segment(&children[i]);
      size_t len = strlen(path) + 1 + strlen(segment) + 1;
      char *child_path = malloc(len);
      snprintf(child_path, len, "%s/%s", path, segment);
      walk(reflection, doc, offered, written, &children[i], child_path, next, seen_len + 1);
      free(child_path);
    }
    free(next);
  }
}

/* Walks the model from `root_segment` and counts, per top-level section, how
 * many content positions the model offers and how many `doc` has written.
 *
 * Lists count as one position, not as their items: a list the author left
 * empty offers exactly one thing to write — the first item — and a list with
 * forty items has not made the document forty times more complete.
 *
 * The walk is entirely generic: it knows no class or field name, so it works
 * unchanged against any of the fourteen document roots. Free the rows'
 * titles and the rows array when done. */
static CoverageReport specification_coverage(const SpecModel *model, const SpecDocument *doc,
                                             const char *root_segment) {
  SpecReflection reflection = spec_reflection_make(model);
  const SpecRoot *root = spec_reflection_root_for_segment(&reflection, root_segment);
  size_t fields_len = 0;
  const SpecField *fields = spec_reflection_fields_of(&reflection, root->type, &fields_len);
  CoverageReport report = {calloc(fields_len, sizeof(CoverageRow)), 0, 0, 0};
  const char *seen[] = {root->type};
  for (size_t i = 0; i < fields_len; i++) {
    if (strcmp(fields[i].kind, SPEC_FIELD_KIND_CONTENT) == 0) continue; /* the root's own body */
    long offered = 0, written = 0;
    const char *segment = spec_reflection_field_segment(&fields[i]);
    size_t len = strlen(root_segment) + 1 + strlen(segment) + 1;
    char *path = malloc(len);
    snprintf(path, len, "%s/%s", root_segment, segment);
    walk(&reflection, doc, &offered, &written, &fields[i], path, seen, 1);
    free(path);
    if (offered == 0) continue;
    report.rows[report.len++] = (CoverageRow){row_title(&fields[i]), offered, written};
    report.offered += offered;
    report.written += written;
  }
  return report;
}

static void the_tool(const SpecModel *model, const DocSpecsSchema *schema, const SpecDocument *doc) {
  section(5, "A tool: the completeness report");
  printf("Built on all four surfaces above, and it reports something NEITHER\n");
  printf("validator can. The schema names what is REQUIRED and missing; an\n");
  printf("optional section left blank is perfectly valid and no validator will\n");
  printf("ever mention it. But \"which parts of this specification has nobody\n");
  printf("written yet?\" is the question a specification author actually has,\n");
  printf("and answering it means walking the model and asking the document.\n\n");

  CoverageReport report = specification_coverage(model, doc, K_ROOT_SEGMENT);
  printf("  ");
  print_padded("SECTION", K_TITLE_WIDTH);
  printf(" WRITTEN / OFFERED\n");
  char pct_text[16];
  for (size_t i = 0; i < report.len; i++) {
    printf("  ");
    print_padded(report.rows[i].title, K_TITLE_WIDTH);
    printf(" %5ld / %5ld", report.rows[i].written, report.rows[i].offered);
    if (report.rows[i].offered != 0) {
      snprintf(pct_text, sizeof pct_text, "%ld%%", pct(report.rows[i].written, report.rows[i].offered));
      printf("%6s", pct_text);
    }
    printf("\n");
  }
  printf("  ");
  for (int i = 0; i < K_TITLE_WIDTH; i++) putchar('-');
  printf(" -------------------\n");
  snprintf(pct_text, sizeof pct_text, "%ld%%", pct(report.written, report.offered));
  printf("  ");
  print_padded("TOTAL", K_TITLE_WIDTH);
  printf(" %5ld / %5ld%6s\n\n", report.written, report.offered, pct_text);

  const CoverageRow *largest = &report.rows[0];
  for (size_t i = 1; i < report.len; i++) {
    if (report.rows[i].offered > largest->offered) largest = &report.rows[i];
  }
  printf("  %.*s offers %ld positions because a Solution Blueprint SEEDS\n", (int)strcspn(largest->title, " "),
         largest->title, largest->offered);
  printf("  the twelve Phase-3 documents: its section classes ARE those\n");
  printf("  documents' types, so the model surface under an SBP root includes\n");
  printf("  everything it seeds. A tool that reports \"0 %%\" against a number\n");
  printf("  like that should say what the denominator is — which is why the\n");
  printf("  report is per section and not one headline figure.\n\n");
  printf("  Required-and-missing, from the schema tier, for contrast:\n");
  DocSpecsViolationList document;
  document_tier(model, schema, doc, &document);
  size_t required = 0;
  for (size_t i = 0; i < document.len; i++) {
    if (strcmp(document.items[i].rule, DOCSPECS_RULE_MISSING_REQUIRED_FIELD) == 0) required++;
  }
  docspecs_violation_list_free(&document);
  printf("    %zu missing required field(s) — the only gaps a validator\n", required);
  printf("    will name, out of %ld unwritten positions.\n\n", report.offered - report.written);
  printf("That gap between the two numbers is the tool's reason to exist.\n");

  for (size_t i = 0; i < report.len; i++) free(report.rows[i].title);
  free(report.rows);
}

/* ---- main ----------------------------------------------------------------- */

int main(void) {
  char *meta_text = read_file(TOMSPECS_CHECKOUT "/tom_som_c_v0/meta/spec_model.meta.json");
  char *err = NULL;
  SomJson *meta_json = som_json_parse(meta_text, &err);
  SpecModel *model = meta_json != NULL ? spec_model_from_json_str(meta_text, &err) : NULL;
  free(meta_text);
  if (model == NULL) {
    fprintf(stderr, "model: %s\n", err != NULL ? err : "?");
    free(err);
    return 1;
  }
  char *schema_text = read_file(TOMSPECS_CHECKOUT
                                "/tom_som_c_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml");
  DocSpecsSchema *schema = NULL;
  if (!docspecs_schema_from_yaml_text(schema_text, &schema, &err)) {
    fprintf(stderr, "schema: %s\n", err != NULL ? err : "?");
    free(err);
    return 1;
  }
  free(schema_text);

  SpecDocument doc;
  spec_document_init(&doc);
  author_fixture(&doc);

  section(0, "The document this run inspects");
  printf("A Solution Blueprint with a handful of sections written and the\n");
  printf("rest left blank — small enough that every number below can be\n");
  printf("checked by reading `author_fixture` in this file.\n\n");
  SomStrList paths;
  spec_document_content_paths(&doc, &paths);
  printf("  content leaves written : %zu\n", paths.len);
  som_strlist_free(&paths);
  spec_document_form_paths(&doc, &paths);
  printf("  form sections written  : %zu\n", paths.len);
  som_strlist_free(&paths);
  spec_document_list_paths(&doc, &paths);
  printf("  lists with items       : %zu\n", paths.len);
  som_strlist_free(&paths);

  reflection_step(model, meta_json);
  generic_access(model, &doc);
  the_schema(schema);
  validation(model, schema, &doc);
  the_tool(model, schema, &doc);

  spec_document_free(&doc);
  docspecs_schema_free(schema);
  spec_model_free(model);
  som_json_free(meta_json);
  return 0;
}
