/* spec_codespecs_gate — Stage A of `codespecs_prompt.md` §4 (see the header). */
#include "spec_codespecs_gate.h"

#include <stdlib.h>
#include <string.h>

#include "spec_document_markdown.h"
#include "spec_validator.h"

/* The Dart reference's not-run reasons, verbatim. */
static const char *const K_NO_SCHEMA = "no DocSpecs schema was supplied";
static const char *const K_NO_TABLES =
    "the catalogue carries no gate tables (written before "
    "`codespecs_prompt.md` §4.4/§4.5 were transcribed)";
static const char *const K_NO_EXTRACTS =
    "A3 did not complete, so there is no extraction run to read the used "
    "areas from";

const char *spec_codespecs_gate_check_label(CodeSpecsGateCheck check) {
  switch (check) {
  case CODESPECS_GATE_A1:
    return "A1";
  case CODESPECS_GATE_A2:
    return "A2";
  case CODESPECS_GATE_A3:
    return "A3";
  case CODESPECS_GATE_A4:
    return "A4";
  case CODESPECS_GATE_A5:
    return "A5";
  }
  return "";
}

char *spec_codespecs_gate_finding_string(const CodeSpecsGateFinding *f) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, spec_codespecs_gate_check_label(f->check));
  som_buf_putc(&b, ' ');
  som_buf_puts(&b, f->code);
  som_buf_putc(&b, ' ');
  som_buf_puts(&b, f->location);
  som_buf_puts(&b, ": ");
  som_buf_puts(&b, f->message);
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

int spec_codespecs_gate_check_result_passed(const CodeSpecsGateCheckResult *r) {
  return r->ran && r->findings_len == 0;
}

const CodeSpecsGateCheckResult *
spec_codespecs_gate_report_result(const CodeSpecsGateReport *r,
                                  CodeSpecsGateCheck check) {
  for (size_t i = 0; i < CODESPECS_GATE_CHECK_COUNT; i++) {
    if (r->results[i].check == check) {
      return &r->results[i];
    }
  }
  return NULL;
}

int spec_codespecs_gate_report_passed(const CodeSpecsGateReport *r) {
  for (size_t i = 0; i < CODESPECS_GATE_CHECK_COUNT; i++) {
    if (!spec_codespecs_gate_check_result_passed(&r->results[i])) {
      return 0;
    }
  }
  return 1;
}

size_t spec_codespecs_gate_report_finding_count(const CodeSpecsGateReport *r) {
  size_t n = 0;
  for (size_t i = 0; i < CODESPECS_GATE_CHECK_COUNT; i++) {
    n += r->results[i].findings_len;
  }
  return n;
}

const CodeSpecsGateFinding *
spec_codespecs_gate_report_finding_at(const CodeSpecsGateReport *r, size_t i) {
  for (size_t k = 0; k < CODESPECS_GATE_CHECK_COUNT; k++) {
    if (i < r->results[k].findings_len) {
      return &r->results[k].findings[i];
    }
    i -= r->results[k].findings_len;
  }
  return NULL;
}

static void result_free(CodeSpecsGateCheckResult *r) {
  for (size_t i = 0; i < r->findings_len; i++) {
    free(r->findings[i].code);
    free(r->findings[i].location);
    free(r->findings[i].message);
  }
  free(r->findings);
  r->findings = NULL;
  r->findings_len = 0;
  r->findings_cap = 0;
}

void spec_codespecs_gate_report_free(CodeSpecsGateReport *r) {
  if (r == NULL) {
    return;
  }
  for (size_t i = 0; i < CODESPECS_GATE_CHECK_COUNT; i++) {
    result_free(&r->results[i]);
  }
  spec_codespecs_extract_list_free(&r->extracts);
  memset(r, 0, sizeof(*r));
}

CodeSpecsGate spec_codespecs_gate_make(const SpecModel *model,
                                       const SpecDocument *document,
                                       const CodeSpecsAreaCatalog *catalog,
                                       const DocSpecsSchema *schema,
                                       const char *root_type) {
  CodeSpecsGate g;
  g.model = model;
  g.document = document;
  g.catalog = catalog;
  g.schema = schema;
  g.root_type = root_type;
  return g;
}

/* ---- helpers ------------------------------------------------------------- */

/* Appends a finding; `code`, `location` and `message` become owned by `r`. */
static void add_finding(CodeSpecsGateCheckResult *r, char *code,
                        char *location, char *message) {
  if (r->findings_len == r->findings_cap) {
    r->findings_cap = r->findings_cap ? r->findings_cap * 2 : 4;
    r->findings = (CodeSpecsGateFinding *)realloc(
        r->findings, r->findings_cap * sizeof(CodeSpecsGateFinding));
  }
  CodeSpecsGateFinding *f = &r->findings[r->findings_len++];
  f->check = r->check;
  f->code = code;
  f->location = location;
  f->message = message;
}

static void not_run(CodeSpecsGateCheckResult *r, const char *reason) {
  r->ran = 0;
  r->not_run_reason = reason;
}

/* Both NULL, or both non-NULL and equal — `String?` equality. */
static int opt_eq(const char *a, const char *b) {
  if (a == NULL || b == NULL) {
    return a == b;
  }
  return strcmp(a, b) == 0;
}

/* Decodes one UTF-8 code point at `*s`, advancing it. Malformed bytes decode
 * to themselves, one byte at a time. */
static unsigned long next_code_point(const unsigned char **s) {
  const unsigned char *p = *s;
  unsigned long c = p[0];
  size_t n = 1;
  if (c >= 0xF0 && p[1] && p[2] && p[3]) {
    c = ((c & 0x07UL) << 18) | ((p[1] & 0x3FUL) << 12) |
        ((p[2] & 0x3FUL) << 6) | (p[3] & 0x3FUL);
    n = 4;
  } else if (c >= 0xE0 && p[1] && p[2]) {
    c = ((c & 0x0FUL) << 12) | ((p[1] & 0x3FUL) << 6) | (p[2] & 0x3FUL);
    n = 3;
  } else if (c >= 0xC0 && p[1]) {
    c = ((c & 0x1FUL) << 6) | (p[1] & 0x3FUL);
    n = 2;
  }
  *s = p + n;
  return c;
}

/* The whitespace Dart's `String.trim` removes. */
static int dart_is_space(unsigned long c) {
  return (c >= 0x09 && c <= 0x0D) || c == 0x20 || c == 0x85 || c == 0xA0 ||
         c == 0x1680 || (c >= 0x2000 && c <= 0x200A) || c == 0x2028 ||
         c == 0x2029 || c == 0x202F || c == 0x205F || c == 0x3000 ||
         c == 0xFEFF;
}

/* `value.trim().isEmpty`. */
static int is_blank(const char *value) {
  const unsigned char *p = (const unsigned char *)value;
  while (*p != '\0') {
    if (!dart_is_space(next_code_point(&p))) {
      return 0;
    }
  }
  return 1;
}

/* Everything before the last `/`, or "" when there is none. Owned. */
static char *parent_path(const char *path) {
  const char *slash = strrchr(path, '/');
  return slash == NULL ? som_strdup("") : som_strdup_n(path, (size_t)(slash - path));
}

/* ---- A1 ------------------------------------------------------------------ */

static int run_a1(const CodeSpecsGate *g, CodeSpecsGateCheckResult *r,
                  char **err) {
  r->check = CODESPECS_GATE_A1;
  r->ran = 1;
  if (g->schema == NULL) {
    not_run(r, K_NO_SCHEMA);
    return 1;
  }
  char *markdown =
      spec_document_to_markdown(g->document, g->model, g->root_type, err);
  if (markdown == NULL) {
    return 0;
  }
  DocSpecsValidator val = docspecs_validator_new(g->schema);
  DocSpecsViolationList violations;
  docspecs_violation_list_init(&violations);
  docspecs_validator_validate_markdown(&val, markdown, &violations);
  free(markdown);
  for (size_t i = 0; i < violations.len; i++) {
    const DocSpecsViolation *v = &violations.items[i];
    /* "" is this runtime's spelling of the Dart `null` for both. */
    char *location;
    if (v->section_id != NULL && v->section_id[0] != '\0') {
      location = som_strdup(v->section_id);
    } else if (v->path != NULL && v->path[0] != '\0') {
      location = som_strdup(v->path);
    } else {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "line ");
      som_buf_puti(&b, v->line);
      location = som_buf_take(&b);
      som_buf_free(&b);
    }
    SomBuf m;
    som_buf_init(&m);
    som_buf_puts(&m, "line ");
    som_buf_puti(&m, v->line);
    som_buf_puts(&m, ": ");
    som_buf_puts(&m, v->message);
    char *message = som_buf_take(&m);
    som_buf_free(&m);
    add_finding(r, som_strdup(v->rule), location, message);
  }
  docspecs_violation_list_free(&violations);
  return 1;
}

/* ---- A2 ------------------------------------------------------------------ */

static void run_a2(const CodeSpecsGate *g, CodeSpecsGateCheckResult *r) {
  r->check = CODESPECS_GATE_A2;
  r->ran = 1;
  SpecValidationErrors errs;
  validate_document(g->model, g->document, &errs);
  for (size_t i = 0; i < errs.len; i++) {
    add_finding(r, som_strdup(errs.items[i].code),
                som_strdup(errs.items[i].path),
                som_strdup(errs.items[i].message));
  }
  spec_validation_errors_free(&errs);
}

/* ---- A3 ------------------------------------------------------------------ */

/* A3 collects **every** unrouted class over the non-strict walk, rather than
 * the first one the strict walk fails on; only when there is none does it run
 * the extraction itself, into `report->extracts`. */
static int run_a3(const CodeSpecsGate *g, CodeSpecsGateReport *report,
                  char **err) {
  CodeSpecsGateCheckResult *r = &report->results[CODESPECS_GATE_A3];
  r->check = CODESPECS_GATE_A3;
  r->ran = 1;
  CodeSpecsExtractError made;
  spec_codespecs_extract_error_init(&made);
  CodeSpecsExtractor ex = spec_codespecs_extractor_make(
      g->model, g->document, g->catalog, g->root_type, &made);
  if (!spec_codespecs_extract_error_is_ok(&made)) {
    add_finding(r, som_strdup("root"),
                som_strdup(made.path != NULL ? made.path : ""),
                som_strdup(made.message != NULL ? made.message : ""));
    spec_codespecs_extract_error_free(&made);
    return 1;
  }
  spec_codespecs_extract_error_free(&made);

  CodeSpecsRoutingList routings;
  spec_codespecs_extractor_routings(&ex, &routings);
  for (size_t i = 0; i < routings.len; i++) {
    const CodeSpecsRouting *rt = &routings.items[i];
    if (rt->verdict != CODESPECS_VERDICT_UNROUTED) {
      continue;
    }
    SomBuf m;
    som_buf_init(&m);
    som_buf_puts(&m, rt->class_name);
    som_buf_puts(&m, " carries no @CodeSpecKind, @FollowUpKind or "
                     "@NoArtifact — its content would reach no extract");
    char *message = som_buf_take(&m);
    som_buf_free(&m);
    add_finding(r, som_strdup("unrouted"), som_strdup(rt->path), message);
  }
  spec_codespecs_routing_list_free(&routings);
  if (r->findings_len > 0) {
    return 1;
  }

  CodeSpecsExtractError xerr;
  spec_codespecs_extract_error_init(&xerr);
  if (!spec_codespecs_extractor_extract_all(&ex, &report->extracts, &xerr)) {
    if (err != NULL) {
      *err = spec_codespecs_extract_error_string(&xerr);
    }
    spec_codespecs_extract_error_free(&xerr);
    return 0;
  }
  spec_codespecs_extract_error_free(&xerr);
  report->has_extracts = 1;
  return 1;
}

/* ---- A4 ------------------------------------------------------------------ */

/* Whether any entry of the run carries `value` at `target`. */
static int run_carries(const CodeSpecsExtractList *extracts,
                       const CodeSpecsFieldRef *target, const char *value) {
  for (size_t x = 0; x < extracts->len; x++) {
    const CodeSpecsExtract *ext = &extracts->items[x];
    for (size_t k = 0; k < ext->entries_len; k++) {
      const CodeSpecsExtractEntry *e = &ext->entries[k];
      if (strcmp(e->class_name, target->class_name) == 0 &&
          strcmp(e->field_name, target->member) == 0 &&
          opt_eq(e->form_field, target->form_field) &&
          strcmp(e->value, value) == 0) {
        return 1;
      }
    }
  }
  return 0;
}

/* A4 over the extraction run: for each obligation whose area's extract is
 * non-empty, every instance of the obligation's class that the extract carries
 * must carry the source value, populated (non-blank); a `resolves_to`
 * obligation's value must also equal a value the run carries at the target. */
static void run_a4(const CodeSpecsGate *g, const CodeSpecsExtractList *extracts,
                   CodeSpecsGateCheckResult *r) {
  r->check = CODESPECS_GATE_A4;
  r->ran = 1;
  const CodeSpecsAreaCatalog *cat = g->catalog;
  for (size_t oi = 0; oi < cat->required_arguments_len; oi++) {
    const CodeSpecsRequiredArgument *o = &cat->required_arguments[oi];
    const CodeSpecsExtract *extract = NULL;
    for (size_t x = 0; x < extracts->len; x++) {
      if (strcmp(extracts->items[x].area->code, o->area) == 0) {
        extract = &extracts->items[x];
        break;
      }
    }
    if (extract == NULL || extract->entries_len == 0) {
      continue;
    }
    /* The instances the extract carries of the obligation's class, in
     * document order, each with the populated source value it holds
     * (borrowed from the entry; NULL when none) and whether `when` holds. */
    SomStrList instances;
    som_strlist_init(&instances);
    const char **values =
        (const char **)calloc(extract->entries_len, sizeof(const char *));
    int *applies = (int *)calloc(extract->entries_len, sizeof(int));
    for (size_t k = 0; k < extract->entries_len; k++) {
      const CodeSpecsExtractEntry *e = &extract->entries[k];
      if (strcmp(e->class_name, o->field.class_name) != 0) {
        continue;
      }
      char *instance = parent_path(e->path);
      size_t at = instances.len;
      for (size_t i = 0; i < instances.len; i++) {
        if (strcmp(instances.items[i], instance) == 0) {
          at = i;
          break;
        }
      }
      if (at == instances.len) {
        som_strlist_push(&instances, instance);
      } else {
        free(instance);
      }
      if (o->when != NULL && strcmp(e->field_name, o->when->member) == 0 &&
          opt_eq(e->form_field, o->when->form_field) &&
          strcmp(e->value, o->when_equals) == 0) {
        applies[at] = 1;
      }
      if (strcmp(e->field_name, o->field.member) == 0 &&
          opt_eq(e->form_field, o->field.form_field) && !is_blank(e->value)) {
        values[at] = e->value;
      }
    }
    char *source = spec_codespecs_field_ref_source(&o->field);
    for (size_t i = 0; i < instances.len; i++) {
      if (o->when != NULL && !applies[i]) {
        continue;
      }
      const char *value = values[i];
      if (value == NULL) {
        SomBuf m;
        som_buf_init(&m);
        som_buf_puts(&m, o->marker);
        som_buf_putc(&m, '.');
        som_buf_puts(&m, o->argument);
        som_buf_puts(&m, " (");
        som_buf_puts(&m, o->area);
        som_buf_puts(&m, ") is required, and its source ");
        som_buf_puts(&m, source);
        som_buf_puts(&m, " is empty here");
        char *message = som_buf_take(&m);
        som_buf_free(&m);
        add_finding(r, som_strdup("missingSource"),
                    som_strdup(instances.items[i]), message);
        continue;
      }
      if (o->resolves_to == NULL) {
        continue;
      }
      if (!run_carries(extracts, o->resolves_to, value)) {
        char *target = spec_codespecs_field_ref_source(o->resolves_to);
        SomBuf m;
        som_buf_init(&m);
        som_buf_puts(&m, source);
        som_buf_puts(&m, " names `");
        som_buf_puts(&m, value);
        som_buf_puts(&m, "`, which no ");
        som_buf_puts(&m, target);
        som_buf_puts(&m, " in this document carries — ");
        som_buf_puts(&m, o->marker);
        som_buf_putc(&m, '.');
        som_buf_puts(&m, o->argument);
        som_buf_puts(&m, " (");
        som_buf_puts(&m, o->area);
        som_buf_puts(&m, ") has nothing to resolve against");
        char *message = som_buf_take(&m);
        som_buf_free(&m);
        free(target);
        add_finding(r, som_strdup("unresolvedReference"),
                    som_strdup(instances.items[i]), message);
      }
    }
    free(source);
    free(values);
    free(applies);
    som_strlist_free(&instances);
  }
}

/* ---- A5 ------------------------------------------------------------------ */

/* A5 against the model, not the document: each carrier's class, member and
 * form field must still exist. */
static void run_a5(const CodeSpecsGate *g, CodeSpecsGateCheckResult *r) {
  r->check = CODESPECS_GATE_A5;
  r->ran = 1;
  const CodeSpecsAreaCatalog *cat = g->catalog;
  for (size_t i = 0; i < cat->carriers_len; i++) {
    const CodeSpecsCarrier *c = &cat->carriers[i];
    const SpecClass *cls = spec_model_class_named(g->model, c->field.class_name);
    const SpecField *field =
        cls == NULL ? NULL : spec_class_field_named(cls, c->field.member);
    int present = field != NULL;
    if (present && c->field.form_field != NULL) {
      present = 0;
      for (size_t k = 0; k < field->form_fields_len; k++) {
        if (strcmp(field->form_fields[k].name, c->field.form_field) == 0) {
          present = 1;
          break;
        }
      }
    }
    if (present) {
      continue;
    }
    char *source = spec_codespecs_field_ref_source(&c->field);
    SomBuf m;
    som_buf_init(&m);
    som_buf_puts(&m, "the model no longer offers ");
    som_buf_puts(&m, source);
    som_buf_puts(&m, " (");
    som_buf_puts(&m, c->introduced_by);
    som_buf_puts(&m, ") — a project with that structured fact would have to "
                     "write prose again");
    char *message = som_buf_take(&m);
    som_buf_free(&m);
    add_finding(r, som_strdup("missingCarrier"), source, message);
  }
}

/* ---- run ----------------------------------------------------------------- */

int spec_codespecs_gate_run(const CodeSpecsGate *g, CodeSpecsGateReport *out,
                            char **err) {
  memset(out, 0, sizeof(*out));
  spec_codespecs_extract_list_init(&out->extracts);
  for (size_t i = 0; i < CODESPECS_GATE_CHECK_COUNT; i++) {
    out->results[i].check = (CodeSpecsGateCheck)i;
  }
  if (!run_a1(g, &out->results[CODESPECS_GATE_A1], err)) {
    spec_codespecs_gate_report_free(out);
    return 0;
  }
  run_a2(g, &out->results[CODESPECS_GATE_A2]);
  if (!run_a3(g, out, err)) {
    spec_codespecs_gate_report_free(out);
    return 0;
  }
  CodeSpecsGateCheckResult *a4 = &out->results[CODESPECS_GATE_A4];
  if (!g->catalog->has_gate_tables) {
    not_run(a4, K_NO_TABLES);
  } else if (!out->has_extracts) {
    not_run(a4, K_NO_EXTRACTS);
  } else {
    run_a4(g, &out->extracts, a4);
  }
  CodeSpecsGateCheckResult *a5 = &out->results[CODESPECS_GATE_A5];
  if (g->catalog->has_gate_tables) {
    run_a5(g, a5);
  } else {
    not_run(a5, K_NO_TABLES);
  }
  return 1;
}
