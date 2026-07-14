/* Tests for the consolidated DocSpecs parsing + validation module (DR1 §6,
 * DR7 / DR20) — a 1:1 port of
 * `tom_som_go_runtime/tests/docspecs_validator_test.go` (itself a port of the
 * TypeScript / Python / Dart reference suite): the generic schema-free parse,
 * schema loading (with warnings for unsupported features), the structured
 * violation list, and the DR7 acceptance criterion — the DR6-emitted Solution
 * Blueprint sample validates cleanly against the DR3-generated
 * `solution-blueprint` schema.
 *
 * Check names byte-match the Go suite. Exit status is the number of failed
 * checks (0 = green).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "docspecs_validator.h"
#include "som_util.h"
#include "spec_document.h"
#include "spec_document_markdown.h"
#include "spec_document_yaml.h"
#include "spec_meta.h"
#include "spec_meta_bridge.h"
#include "spec_model.h"
#include "yaml.h"

/* dvSiblings is the ai_build folder holding the sibling runtime packages. The
 * unit binaries run from the C package root, so the Go suite's "../.." (from
 * tom_som_go_runtime/tests) maps to "..". */
#define DV_SIBLINGS ".."

/* ---- checker ------------------------------------------------------------- */

static int g_checks = 0;
static int g_failures = 0;

/* mdCheck — the Go harness helper. `detail` may be NULL. */
static void mdCheck(const char *name, int cond, const char *detail) {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  if (detail != NULL && detail[0] != '\0')
    fprintf(stderr, "FAIL %s: %s\n", name, detail);
  else
    fprintf(stderr, "FAIL %s\n", name);
}

static void fatal(const char *what, char *err) {
  fprintf(stderr, "fatal: %s: %s\n", what, err != NULL ? err : "(no message)");
  free(err);
  exit(2);
}

/* ---- small string helpers ------------------------------------------------ */

/* Replaces the first occurrence of `old` in `src` with `rep`. Owned result. */
static char *str_replace_first(const char *src, const char *old,
                               const char *rep) {
  const char *at = strstr(src, old);
  if (at == NULL) return som_strdup(src);
  size_t pre = (size_t)(at - src);
  size_t oldn = strlen(old);
  size_t repn = strlen(rep);
  size_t tail = strlen(at + oldn);
  char *out = (char *)malloc(pre + repn + tail + 1);
  memcpy(out, src, pre);
  memcpy(out + pre, rep, repn);
  memcpy(out + pre + repn, at + oldn, tail);
  out[pre + repn + tail] = '\0';
  return out;
}

/* Concatenates two strings. Owned result. */
static char *cat2(const char *a, const char *b) {
  char *out = (char *)malloc(strlen(a) + strlen(b) + 1);
  strcpy(out, a);
  strcat(out, b);
  return out;
}

static int str_eq(const char *a, const char *b) {
  return a != NULL && b != NULL && strcmp(a, b) == 0;
}

static int contains(const char *hay, const char *needle) {
  return hay != NULL && strstr(hay, needle) != NULL;
}

/* Reads a whole file into an owned NUL-terminated buffer, or exits. */
static char *read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    fprintf(stderr, "read %s: cannot open\n", path);
    exit(2);
  }
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  fseek(f, 0, SEEK_SET);
  if (n < 0) {
    fclose(f);
    fprintf(stderr, "read %s: ftell failed\n", path);
    exit(2);
  }
  char *buf = (char *)malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  fclose(f);
  buf[got] = '\0';
  return buf;
}

/* ---- fixtures ------------------------------------------------------------ */

/* Fixture schema (hand-written in the exact DR3 generator output shape). */
static const char *dvSchemaYaml =
    "title-format: \"# <!--[D00]--> Demo Document\"\n"
    "section-types:\n"
    "  goal-item:\n"
    "    prefix: GOAL_ITEM_\n"
    "    pattern-check-id:\n"
    "      pattern: \"^GOAL-ITEM-[0-9]+$\"\n"
    "      error-message: IDs of this section must match GOAL-ITEM-xxx\n"
    "  d00-ovr:\n"
    "    prefix: D00_OVR\n"
    "    text-required: true\n"
    "  d00-hdr:\n"
    "    prefix: D00_HDR\n"
    "    format: header-form\n"
    "  gsum:\n"
    "    prefix: GSUM\n"
    "  diag:\n"
    "    prefix: DIAG\n"
    "    format: mermaid\n"
    "  goals:\n"
    "    prefix: GOALS\n"
    "    subsection-types:\n"
    "      goal-item:\n"
    "        min-count: 1\n"
    "        max-count: infinite\n"
    "      gsum:\n"
    "        max-count: 1\n"
    "form-types:\n"
    "  header-form:\n"
    "    fields:\n"
    "      - fieldname: author\n"
    "        required: true\n"
    "      - fieldname: reviewer\n"
    "        pattern-check:\n"
    "          pattern: \"^[A-Z]\"\n"
    "          error-message: Reviewer must start with an uppercase letter\n"
    "document:\n"
    "  sections:\n"
    "    d00-ovr:\n"
    "      section-type: d00-ovr\n"
    "    d00-hdr:\n"
    "      section-type: d00-hdr\n"
    "      optional: true\n"
    "    goals:\n"
    "      section-type: goals\n"
    "      optional: true\n"
    "    diag:\n"
    "      section-type: diag\n"
    "      optional: true\n";

static const char *dvValidDoc =
    "<!-- docspec: demo-document/1.0 -->\n"
    "# <!--[D00]--> Demo Document\n"
    "\n"
    "Intro text.\n"
    "\n"
    "## <!--[D00-OVR]--> Overview\n"
    "\n"
    "Some overview text.\n"
    "\n"
    "## <!--[D00-HDR]--> Header\n"
    "\n"
    "Author: Alice\n"
    "Reviewer: Bob\n"
    "\n"
    "## <!--[GOALS]--> Goals\n"
    "\n"
    "### <!--[GOAL-ITEM-1]--> Goal 1\n"
    "\n"
    "First goal.\n"
    "\n"
    "### <!--[GOAL-ITEM-2]--> Goal 2\n"
    "\n"
    "Second goal.\n";

/* ---- shared derived helpers ---------------------------------------------- */

/* dvSchema — loads the fixture schema or fatally aborts. */
static DocSpecsSchema *dvSchema(void) {
  DocSpecsSchema *schema = NULL;
  char *err = NULL;
  if (!docspecs_schema_from_yaml_text(dvSchemaYaml, &schema, &err))
    fatal("DocSpecsSchemaFromYamlText", err);
  return schema;
}

/* dvValidate — schema-load + validate `md`, writing findings to `out`. */
static void dvValidate(const char *md, DocSpecsViolationList *out) {
  DocSpecsSchema *schema = dvSchema();
  DocSpecsValidator val = docspecs_validator_new(schema);
  docspecs_validator_validate_markdown(&val, md, out);
  docspecs_schema_free(schema);
}

/* dvDetail — the `; `-joined violation strings. Owned result. */
static char *dvDetail(const DocSpecsViolationList *v) {
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < v->len; ++i) {
    if (i > 0) som_buf_puts(&b, "; ");
    char *s = docspecs_violation_string(&v->items[i]);
    som_buf_puts(&b, s);
    free(s);
  }
  return som_buf_take(&b);
}

/* dvChildIDs — the `,`-joined child ids of `s`. Owned result. */
static char *dvChildIDs(const DocSpecsSection *s) {
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < s->children_len; ++i) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, s->children[i]->id);
  }
  return som_buf_take(&b);
}

/* Owned decimal string for a `len(...)` detail. */
static char *itoa_owned(long long v) { return som_format_i64(v); }

/* --- DocSpecsDocument parse (generic, schema-free) ------------------------ */

static void TestDocspecsParseTree(void) {
  DocSpecsDocument *doc = docspecs_parse_document(dvValidDoc);
  mdCheck("parse.declaredSchema", str_eq(doc->declared_schema, "demo-document/1.0"),
          doc->declared_schema);
  char *det = dvDetail(&doc->violations);
  mdCheck("parse.noViolations", doc->violations.len == 0, det);
  free(det);
  char *n = itoa_owned((long long)doc->sections_len);
  mdCheck("parse.oneRoot", doc->sections_len == 1, n);
  free(n);
  const DocSpecsSection *root = doc->sections[0];
  mdCheck("parse.root.id", str_eq(root->id, "D00"), root->id);
  mdCheck("parse.root.title", str_eq(root->title, "Demo Document"), root->title);
  char *lvl = itoa_owned((long long)root->level);
  mdCheck("parse.root.level", root->level == 1, lvl);
  free(lvl);
  char *rtext = docspecs_section_text(root);
  mdCheck("parse.root.text", str_eq(rtext, "Intro text."), rtext);
  free(rtext);
  char *cids = dvChildIDs(root);
  mdCheck("parse.root.children", str_eq(cids, "D00-OVR,D00-HDR,GOALS"), cids);
  free(cids);
  const DocSpecsSection *goals = root->children[root->children_len - 1];
  char *gids = dvChildIDs(goals);
  mdCheck("parse.goals.children", str_eq(gids, "GOAL-ITEM-1,GOAL-ITEM-2"), gids);
  free(gids);
  char *g1 = docspecs_section_text(goals->children[0]);
  mdCheck("parse.goal1.text", str_eq(g1, "First goal."), g1);
  free(g1);
  docspecs_document_free(doc);
}

static void TestDocspecsParseFenceShield(void) {
  DocSpecsDocument *doc = docspecs_parse_document(
      "# <!--[D00]--> Demo Document\n"
      "\n"
      "```md\n"
      "## <!--[NOT-A-SECTION]--> shielded\n"
      "```\n");
  mdCheck("parse.fence.noChildren", doc->sections[0]->children_len == 0, NULL);
  char *txt = docspecs_section_text(doc->sections[0]);
  mdCheck("parse.fence.bodyKept", contains(txt, "NOT-A-SECTION"), NULL);
  free(txt);
  docspecs_document_free(doc);
}

static void TestDocspecsParseMalformedHeading(void) {
  DocSpecsDocument *doc = docspecs_parse_document(
      "# <!--[D00]--> Demo Document\n"
      "\n"
      "## Plain Heading\n");
  char *det = dvDetail(&doc->violations);
  mdCheck("parse.malformed.count", doc->violations.len == 1, det);
  free(det);
  if (doc->violations.len > 0) {
    const DocSpecsViolation *v = &doc->violations.items[0];
    char *vs = docspecs_violation_string(v);
    mdCheck("parse.malformed.rule",
            str_eq(v->rule, DOCSPECS_RULE_MALFORMED_HEADING), vs);
    free(vs);
    char *ln = itoa_owned((long long)v->line);
    mdCheck("parse.malformed.line", v->line == 3, ln);
    free(ln);
  }
  docspecs_document_free(doc);
}

/* --- DocSpecsSchemaFromYamlText ------------------------------------------- */

static void TestDocspecsSchemaLoading(void) {
  DocSpecsSchema *schema = dvSchema();
  char *warnj = som_strlist_join(&schema->warnings, "; ");
  mdCheck("schema.noWarnings", schema->warnings.len == 0, warnj);
  free(warnj);
  char *rsi = docspecs_schema_root_section_id(schema);
  mdCheck("schema.rootSectionId", str_eq(rsi, "D00"), rsi);
  free(rsi);
  const DocSpecsSectionType *goalItem =
      docspecs_schema_section_type_by_name(schema, "goal-item");
  mdCheck("schema.goalItem.present", goalItem != NULL, NULL);
  if (goalItem != NULL) {
    mdCheck("schema.goalItem.prefix", str_eq(goalItem->prefix, "GOAL_ITEM_"),
            goalItem->prefix);
    mdCheck("schema.goalItem.pattern",
            goalItem->pattern_check != NULL &&
                str_eq(goalItem->pattern_check->pattern, "^GOAL-ITEM-[0-9]+$"),
            goalItem->pattern_check ? goalItem->pattern_check->pattern : "<nil>");
  }
  const DocSpecsSectionType *goals =
      docspecs_schema_section_type_by_name(schema, "goals");
  const DocSpecsSubsectionRule *goalSub =
      docspecs_section_type_subsection(goals, "goal-item");
  mdCheck("schema.goals.min", goalSub != NULL && goalSub->min_count == 1, NULL);
  mdCheck("schema.goals.maxInfinite", goalSub != NULL && goalSub->has_max == 0,
          NULL);
  const DocSpecsSubsectionRule *gsumSub =
      docspecs_section_type_subsection(goals, "gsum");
  mdCheck("schema.gsum.max1",
          gsumSub != NULL && gsumSub->has_max && gsumSub->max_count == 1, NULL);
  const DocSpecsFormType *form = docspecs_schema_form_type(schema, "header-form");
  SomBuf fb;
  som_buf_init(&fb);
  for (size_t i = 0; form != NULL && i < form->fields_len; ++i) {
    if (i > 0) som_buf_putc(&fb, ',');
    som_buf_puts(&fb, form->fields[i].name);
  }
  char *fieldNames = som_buf_take(&fb);
  mdCheck("schema.form.fields", str_eq(fieldNames, "author,reviewer"),
          fieldNames);
  free(fieldNames);
  mdCheck("schema.form.authorRequired",
          form != NULL && form->fields_len > 0 && form->fields[0].required, NULL);
  const DocSpecsDocumentSection *ovr =
      docspecs_schema_document_section(schema, "d00-ovr");
  mdCheck("schema.doc.ovrRequired", ovr != NULL && !ovr->optional, NULL);
  const DocSpecsDocumentSection *hdr =
      docspecs_schema_document_section(schema, "d00-hdr");
  mdCheck("schema.doc.hdrOptional", hdr != NULL && hdr->optional, NULL);
  docspecs_schema_free(schema);
}

/* The resolved section-type name for `id`, or "<nil>". Borrowed. */
static const char *resolve_name(const DocSpecsSchema *schema, const char *id) {
  const DocSpecsSectionType *st =
      docspecs_schema_resolve_section_type(schema, id);
  return st == NULL ? "<nil>" : st->name;
}

static void TestDocspecsSchemaResolution(void) {
  DocSpecsSchema *schema = dvSchema();
  mdCheck("resolve.goalItem",
          str_eq(resolve_name(schema, "GOAL-ITEM-7"), "goal-item"),
          resolve_name(schema, "GOAL-ITEM-7"));
  mdCheck("resolve.goals", str_eq(resolve_name(schema, "GOALS"), "goals"),
          resolve_name(schema, "GOALS"));
  mdCheck("resolve.ovr", str_eq(resolve_name(schema, "D00-OVR"), "d00-ovr"),
          resolve_name(schema, "D00-OVR"));
  mdCheck("resolve.none", str_eq(resolve_name(schema, "NOPE-1"), "<nil>"),
          resolve_name(schema, "NOPE-1"));
  docspecs_schema_free(schema);
}

static void TestDocspecsSchemaWarnings(void) {
  DocSpecsSchema *schema = NULL;
  char *err = NULL;
  if (!docspecs_schema_from_yaml_text(
          "title-format: \"# <!--[D00]--> Demo\"\n"
          "generators:\n"
          "  something: true\n"
          "section-types:\n"
          "  d00-ovr:\n"
          "    prefix: D00_OVR\n"
          "    database-schema:\n"
          "      table: t\n"
          "document:\n"
          "  sections:\n"
          "    d00-ovr:\n"
          "      section-type: d00-ovr\n"
          "  custom-tag: x\n",
          &schema, &err))
    fatal("DocSpecsSchemaFromYamlText", err);
  char *warnj = som_strlist_join(&schema->warnings, "; ");
  char *cnt = itoa_owned((long long)schema->warnings.len);
  mdCheck("warnings.count", schema->warnings.len == 3, warnj);
  free(cnt);
  char *joined = som_strlist_join(&schema->warnings, "\n");
  mdCheck("warnings.generators", contains(joined, "generators"), joined);
  mdCheck("warnings.databaseSchema", contains(joined, "database-schema"), joined);
  mdCheck("warnings.customTag", contains(joined, "custom-tag"), joined);
  mdCheck("warnings.stillLoads",
          docspecs_schema_section_type_by_name(schema, "d00-ovr") != NULL, NULL);
  free(warnj);
  free(joined);
  docspecs_schema_free(schema);
}

/* --- DocSpecsValidator.Validate ------------------------------------------- */

static void TestDocspecsValidateValid(void) {
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(dvValidDoc, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.valid.empty", v.len == 0, det);
  free(det);
  docspecs_violation_list_free(&v);
}

static void TestDocspecsValidateMissingRequiredSection(void) {
  char *md = str_replace_first(
      dvValidDoc, "## <!--[D00-OVR]--> Overview\n\nSome overview text.\n\n", "");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.missingSection.count", v.len == 1, det);
  free(det);
  if (v.len > 0) {
    char *vs = docspecs_violation_string(&v.items[0]);
    mdCheck("validate.missingSection.rule",
            str_eq(v.items[0].rule, DOCSPECS_RULE_MISSING_REQUIRED_SECTION), vs);
    free(vs);
    mdCheck("validate.missingSection.id", str_eq(v.items[0].section_id, "d00-ovr"),
            v.items[0].section_id);
    mdCheck("validate.missingSection.msg", contains(v.items[0].message, "d00-ovr"),
            v.items[0].message);
  }
  docspecs_violation_list_free(&v);
  free(md);
}

static void TestDocspecsValidateIdPatternMismatch(void) {
  char *md = str_replace_first(dvValidDoc, "GOAL-ITEM-2", "GOAL-ITEM-B");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.idPattern.count", v.len == 1, det);
  free(det);
  if (v.len > 0) {
    char *vs = docspecs_violation_string(&v.items[0]);
    mdCheck("validate.idPattern.rule",
            str_eq(v.items[0].rule, DOCSPECS_RULE_ID_PATTERN_MISMATCH), vs);
    free(vs);
    mdCheck("validate.idPattern.id", str_eq(v.items[0].section_id, "GOAL-ITEM-B"),
            v.items[0].section_id);
    mdCheck("validate.idPattern.msg",
            str_eq(v.items[0].message,
                   "IDs of this section must match GOAL-ITEM-xxx"),
            v.items[0].message);
    char *ln = itoa_owned((long long)v.items[0].line);
    mdCheck("validate.idPattern.line", v.items[0].line == 21, ln);
    free(ln);
  }
  docspecs_violation_list_free(&v);
  free(md);
}

static void TestDocspecsValidateUnknownSection(void) {
  char *md = str_replace_first(dvValidDoc, "### <!--[GOAL-ITEM-2]--> Goal 2",
                               "### <!--[XYZ-2]--> Goal 2");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.unknown.count", v.len == 1, det);
  free(det);
  if (v.len > 0) {
    char *vs = docspecs_violation_string(&v.items[0]);
    mdCheck("validate.unknown.rule",
            str_eq(v.items[0].rule, DOCSPECS_RULE_UNKNOWN_SECTION), vs);
    free(vs);
    mdCheck("validate.unknown.id", str_eq(v.items[0].section_id, "XYZ-2"),
            v.items[0].section_id);
  }
  docspecs_violation_list_free(&v);
  free(md);
}

static void TestDocspecsValidateDisallowedPosition(void) {
  char *md = str_replace_first(dvValidDoc, "### <!--[GOAL-ITEM-2]--> Goal 2",
                               "### <!--[DIAG]--> Diagram");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.disallowed.count", v.len == 1, det);
  free(det);
  if (v.len > 0) {
    char *vs = docspecs_violation_string(&v.items[0]);
    mdCheck("validate.disallowed.rule",
            str_eq(v.items[0].rule, DOCSPECS_RULE_UNKNOWN_SECTION), vs);
    free(vs);
    mdCheck("validate.disallowed.msg",
            contains(v.items[0].message, "not an allowed subsection"),
            v.items[0].message);
  }
  docspecs_violation_list_free(&v);
  free(md);
}

static void TestDocspecsValidateMissingRequiredField(void) {
  char *md = str_replace_first(dvValidDoc, "Author: Alice\n", "");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.missingField.count", v.len == 1, det);
  free(det);
  if (v.len > 0) {
    char *vs = docspecs_violation_string(&v.items[0]);
    mdCheck("validate.missingField.rule",
            str_eq(v.items[0].rule, DOCSPECS_RULE_MISSING_REQUIRED_FIELD), vs);
    free(vs);
    mdCheck("validate.missingField.id", str_eq(v.items[0].section_id, "D00-HDR"),
            v.items[0].section_id);
    mdCheck("validate.missingField.msg", contains(v.items[0].message, "author"),
            v.items[0].message);
  }
  docspecs_violation_list_free(&v);
  free(md);
}

static void TestDocspecsValidateFieldPatternMismatch(void) {
  char *md = str_replace_first(dvValidDoc, "Reviewer: Bob", "Reviewer: bob");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.fieldPattern.count", v.len == 1, det);
  free(det);
  if (v.len > 0) {
    char *vs = docspecs_violation_string(&v.items[0]);
    mdCheck("validate.fieldPattern.rule",
            str_eq(v.items[0].rule, DOCSPECS_RULE_FIELD_PATTERN_MISMATCH), vs);
    free(vs);
    mdCheck("validate.fieldPattern.msg",
            str_eq(v.items[0].message,
                   "Reviewer must start with an uppercase letter"),
            v.items[0].message);
    char *ln = itoa_owned((long long)v.items[0].line);
    mdCheck("validate.fieldPattern.line", v.items[0].line == 13, ln);
    free(ln);
  }
  docspecs_violation_list_free(&v);
  free(md);
}

static void TestDocspecsValidateTextRequired(void) {
  char *md = str_replace_first(dvValidDoc, "Some overview text.\n\n", "");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.textRequired.count", v.len == 1, det);
  free(det);
  if (v.len > 0) {
    char *vs = docspecs_violation_string(&v.items[0]);
    mdCheck("validate.textRequired.rule",
            str_eq(v.items[0].rule, DOCSPECS_RULE_TEXT_REQUIRED), vs);
    free(vs);
    mdCheck("validate.textRequired.id", str_eq(v.items[0].section_id, "D00-OVR"),
            v.items[0].section_id);
  }
  docspecs_violation_list_free(&v);
  free(md);
}

static void TestDocspecsValidateTooManyItems(void) {
  char *md = cat2(dvValidDoc,
                  "\n"
                  "### <!--[GSUM]--> Summary\n\nOne.\n\n"
                  "### <!--[GSUM]--> Summary\n\nTwo.\n");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.tooMany.count", v.len == 1, det);
  free(det);
  if (v.len > 0) {
    char *vs = docspecs_violation_string(&v.items[0]);
    mdCheck("validate.tooMany.rule",
            str_eq(v.items[0].rule, DOCSPECS_RULE_TOO_MANY_ITEMS), vs);
    free(vs);
    mdCheck("validate.tooMany.msg", contains(v.items[0].message, "gsum"),
            v.items[0].message);
  }
  docspecs_violation_list_free(&v);
  free(md);
}

static void TestDocspecsValidateFormatMismatch(void) {
  char *md = cat2(dvValidDoc, "\n## <!--[DIAG]--> Diagram\n\nno fence here\n");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  char *det = dvDetail(&v);
  mdCheck("validate.format.count", v.len == 1, det);
  free(det);
  if (v.len > 0) {
    char *vs = docspecs_violation_string(&v.items[0]);
    mdCheck("validate.format.rule",
            str_eq(v.items[0].rule, DOCSPECS_RULE_FORMAT_MISMATCH), vs);
    free(vs);
  }
  docspecs_violation_list_free(&v);
  free(md);

  char *ok = cat2(dvValidDoc,
                  "\n## <!--[DIAG]--> Diagram\n\n```mermaid\ngraph TD;\n```\n");
  DocSpecsViolationList vOk;
  docspecs_violation_list_init(&vOk);
  dvValidate(ok, &vOk);
  char *detOk = dvDetail(&vOk);
  mdCheck("validate.format.fencedOk", vOk.len == 0, detOk);
  free(detOk);
  docspecs_violation_list_free(&vOk);
  free(ok);
}

static void TestDocspecsValidateRootMismatch(void) {
  char *md = str_replace_first(dvValidDoc, "# <!--[D00]-->", "# <!--[D99]-->");
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  int found = 0;
  for (size_t i = 0; i < v.len; ++i)
    if (str_eq(v.items[i].rule, DOCSPECS_RULE_FORMAT_MISMATCH)) found = 1;
  char *det = dvDetail(&v);
  mdCheck("validate.rootMismatch.rule", found, det);
  free(det);
  docspecs_violation_list_free(&v);
  free(md);
}

static int cmp_str(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

static void TestDocspecsValidateNeverFailFast(void) {
  char *m1 = str_replace_first(dvValidDoc, "Author: Alice\n", "");
  char *m2 = str_replace_first(m1, "Reviewer: Bob", "Reviewer: bob");
  char *md = str_replace_first(m2, "GOAL-ITEM-2", "GOAL-ITEM-B");
  free(m1);
  free(m2);
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  dvValidate(md, &v);
  /* de-dup rules seen, in first-seen order. */
  const char *got[16];
  size_t got_len = 0;
  for (size_t i = 0; i < v.len; ++i) {
    int seen = 0;
    for (size_t j = 0; j < got_len; ++j)
      if (str_eq(got[j], v.items[i].rule)) seen = 1;
    if (!seen && got_len < 16) got[got_len++] = v.items[i].rule;
  }
  qsort((void *)got, got_len, sizeof(got[0]), cmp_str);
  const char *want[] = {DOCSPECS_RULE_MISSING_REQUIRED_FIELD,
                        DOCSPECS_RULE_FIELD_PATTERN_MISMATCH,
                        DOCSPECS_RULE_ID_PATTERN_MISMATCH};
  size_t want_len = sizeof(want) / sizeof(want[0]);
  qsort((void *)want, want_len, sizeof(want[0]), cmp_str);
  int equal = got_len == want_len;
  for (size_t i = 0; equal && i < got_len; ++i)
    if (!str_eq(got[i], want[i])) equal = 0;
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < got_len; ++i) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, got[i]);
  }
  som_buf_puts(&b, " != ");
  for (size_t i = 0; i < want_len; ++i) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, want[i]);
  }
  char *detail = som_buf_take(&b);
  mdCheck("validate.neverFailFast", equal, detail);
  free(detail);
  docspecs_violation_list_free(&v);
  free(md);
}

/* --- BindDocspecsMarkdown -------------------------------------------------- */

static void TestDocspecsBindDocspecsMarkdown(void) {
  char *modelText =
      read_file(DV_SIBLINGS "/tom_som_conformance/corpus/model.meta.json");
  char *err = NULL;
  SpecModel *model = spec_model_from_json_str(modelText, &err);
  if (model == NULL) fatal("SpecModelFromJSON", err);
  char *mdText =
      read_file(DV_SIBLINGS "/tom_som_conformance/corpus/expected.md");
  SpecMarkdownResult result;
  docspecs_bind_markdown(model, mdText, &result);
  char *rej = NULL;
  {
    SomBuf b;
    som_buf_init(&b);
    for (size_t i = 0; i < result.rejections_len; ++i) {
      if (i > 0) som_buf_putc(&b, '\n');
      char *d = spec_markdown_rejection_display(&result.rejections[i]);
      som_buf_puts(&b, d);
      free(d);
    }
    rej = som_buf_take(&b);
  }
  mdCheck("bind.clean", spec_markdown_result_is_clean(&result), rej);
  char *ac = itoa_owned((long long)spec_markdown_result_applied_count(&result));
  mdCheck("bind.appliedCount", spec_markdown_result_applied_count(&result) > 0,
          ac);
  free(ac);
  free(rej);
  spec_markdown_result_free(&result);
  spec_model_free(model);
  free(modelText);
  free(mdText);
}

/* --- DR7 acceptance: DR6 sample vs DR3 schema ------------------------------ */

static void TestDocspecsDr7Acceptance(void) {
  char *metaText =
      read_file(DV_SIBLINGS "/tom_som_dart_v0/meta/spec_model.meta.json");
  char *err = NULL;
  SpecModel *model = spec_model_from_json_str(metaText, &err);
  if (model == NULL) fatal("SpecModelFromJSON", err);

  SomMetaTree *tree = som_build_meta_tree(model, "D00SolutionBlueprint", &err);
  if (tree == NULL) fatal("BuildSomMetaTree", err);

  const char *samplePath =
      DV_SIBLINGS
      "/tom_som_conformance/samples/meridian_order_management.docspecs.yaml";
  SpecDocument *document = spec_document_from_file(samplePath, tree, &err);
  if (document == NULL) fatal("FromFile", err);

  char *md = spec_document_to_markdown(document, model, "", &err);
  if (md == NULL) fatal("ToMarkdown", err);

  char *schemaText = read_file(
      DV_SIBLINGS "/tom_som_dart_v0/schemas/solution-blueprint/"
                  "solution-blueprint.1.0.docspecs-schema.yaml");
  DocSpecsSchema *schema = NULL;
  if (!docspecs_schema_from_yaml_text(schemaText, &schema, &err))
    fatal("DocSpecsSchemaFromYamlText", err);

  char *rsi = docspecs_schema_root_section_id(schema);
  mdCheck("dr7.rootSectionId", str_eq(rsi, "SBP"), rsi);
  free(rsi);

  DocSpecsValidator val = docspecs_validator_new(schema);
  DocSpecsViolationList v;
  docspecs_violation_list_init(&v);
  docspecs_validator_validate_markdown(&val, md, &v);
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < v.len && i < 20; ++i) {
    som_buf_putc(&b, '\n');
    char *s = docspecs_violation_string(&v.items[i]);
    som_buf_puts(&b, s);
    free(s);
  }
  char *detail = som_buf_take(&b);
  mdCheck("dr7.violationsEmpty", v.len == 0, detail);
  free(detail);

  docspecs_violation_list_free(&v);
  docspecs_schema_free(schema);
  free(schemaText);
  free(md);
  spec_document_free(document);
  som_meta_tree_free(tree);
  spec_model_free(model);
  free(metaText);
}

int main(void) {
  TestDocspecsParseTree();
  TestDocspecsParseFenceShield();
  TestDocspecsParseMalformedHeading();
  TestDocspecsSchemaLoading();
  TestDocspecsSchemaResolution();
  TestDocspecsSchemaWarnings();
  TestDocspecsValidateValid();
  TestDocspecsValidateMissingRequiredSection();
  TestDocspecsValidateIdPatternMismatch();
  TestDocspecsValidateUnknownSection();
  TestDocspecsValidateDisallowedPosition();
  TestDocspecsValidateMissingRequiredField();
  TestDocspecsValidateFieldPatternMismatch();
  TestDocspecsValidateTextRequired();
  TestDocspecsValidateTooManyItems();
  TestDocspecsValidateFormatMismatch();
  TestDocspecsValidateRootMismatch();
  TestDocspecsValidateNeverFailFast();
  TestDocspecsBindDocspecsMarkdown();
  TestDocspecsDr7Acceptance();

  fprintf(stderr, "docspecs_validator_test: %d checks, %d failures\n", g_checks,
          g_failures);
  return g_failures;
}
