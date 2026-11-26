/* The rendition's navigation and generated parts in the conformance suite
 * (`link_rendition_cases.json`, SOM §11.2, §11.11, §11.12), included by
 * tests/conformance.c after conformance_document_set.h: each case's document
 * rendered with file stem `links`, the rendition (its markers deleted or
 * edited where the case says) handed to the parser, and the rendition of what
 * it staged; then the schema tier over the real model
 * (`uam_requirements_cut.json`). A port of the Rust runner's
 * `conformance_rendition/mod.rs` (the Go runner's
 * `conformance_rendition_test.go`).
 *
 * Uses the helpers of conformance.c, conformance_links.h and
 * conformance_document_set.h (check, read_json, json_canon, put_json_str,
 * doc_from_state, ds_*). */

/* ---- rendering ------------------------------------------------------------------- */

/* `doc` rendered as its root's rendition: the first root of `model` it holds
 * a value under. Owned; NULL with `*err` (owned) on failure. */
static char *rn_rendition_of(const SpecModel *model, const SpecDocument *doc,
                             const char *file_stem, int markers, int generated,
                             char **err) {
  const SpecRoot *root = NULL;
  for (size_t i = 0; i < model->roots_len && root == NULL; i++) {
    const SpecRoot *r = &model->roots[i];
    const char *seg = r->section_id[0] != '\0' ? r->section_id : r->type;
    if (spec_document_has_values_under(doc, seg)) root = r;
  }
  if (root == NULL) {
    *err = som_strdup("no root holds a value");
    return NULL;
  }
  SpecMarkdownExportOptions o;
  memset(&o, 0, sizeof(o));
  o.file_stem = file_stem;
  o.no_linked_markers = !markers;
  o.no_generated_parts = !generated;
  SpecMarkdownRendition r;
  if (!spec_markdown_export_root_with_options(model, doc, root, &o, &r, err)) {
    if (*err == NULL) *err = som_strdup("the document does not render");
    return NULL;
  }
  char *md = r.markdown;
  r.markdown = NULL;
  spec_markdown_rendition_free(&r);
  return md;
}

/* `^\[.*\]\{\.linked\}$`: a marker line. */
static int rn_is_marker_line(const char *line, size_t len) {
  static const char tail[] = "]{.linked}";
  size_t tl = sizeof(tail) - 1;
  return len > 0 && line[0] == '[' && len >= tl &&
         memcmp(line + len - tl, tail, tl) == 0;
}

/* `text` split on '\n' (`*out` initialised by the callee). */
static void rn_lines(const char *text, SomStrList *out) {
  som_strlist_init(out);
  const char *p = text;
  for (;;) {
    const char *nl = strchr(p, '\n');
    if (nl == NULL) {
      som_strlist_push_copy(out, p);
      return;
    }
    som_strlist_push(out, som_strdup_n(p, (size_t)(nl - p)));
    p = nl + 1;
  }
}

/* `markdown` with its `linked` marker paragraphs removed. Owned. */
static char *rn_without_markers(const char *markdown) {
  SomStrList lines;
  rn_lines(markdown, &lines);
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  for (size_t i = 0; i < lines.len; i++) {
    const char *l = lines.items[i];
    if (rn_is_marker_line(l, strlen(l))) {
      if (i + 1 < lines.len && lines.items[i + 1][0] == '\0') i++;
      continue;
    }
    if (!first) som_buf_putc(&b, '\n');
    som_buf_puts(&b, l);
    first = 0;
  }
  som_strlist_free(&lines);
  return som_buf_take(&b);
}

/* `s` with the first `from` replaced by `to`. Owned. */
static char *rn_replace_first(const char *s, const char *from, const char *to) {
  const char *at = strstr(s, from);
  SomBuf b;
  som_buf_init(&b);
  som_buf_putn(&b, s, (size_t)(at - s));
  som_buf_puts(&b, to);
  som_buf_puts(&b, at + strlen(from));
  return som_buf_take(&b);
}

static char *rn_doc_canon(const SpecDocument *d) {
  DocumentJson j;
  spec_document_to_json(d, &j);
  char *out = document_json_to_canonical_json(&j);
  document_json_free(&j);
  return out;
}

/* One rendition case, as the Dart test's `renditionCase` computes it: the
 * result as JSON text (owned), or NULL with `*err` (owned). */
static char *rn_rendition_case(const SpecModel *model, const SomJson *cc,
                               char **err) {
  DocumentJson state;
  document_json_from_json(som_json_get(cc, "state"), &state);
  SpecDocument doc;
  doc_from_state(&doc, &state);
  document_json_free(&state);
  const SomJson *lm = som_json_get(cc, "linkedMarkers");
  const SomJson *gp = som_json_get(cc, "generatedParts");
  int markers = !(lm != NULL && lm->type == SOM_JSON_BOOL && !lm->as.boolean);
  int generated = !(gp != NULL && gp->type == SOM_JSON_BOOL && !gp->as.boolean);
  char *markdown = rn_rendition_of(model, &doc, "links", markers, generated, err);
  if (markdown == NULL) {
    spec_document_free(&doc);
    return NULL;
  }
  char *given = som_strdup(markdown);
  if (som_json_bool_or(cc, "dropMarkers")) {
    char *x = rn_without_markers(given);
    free(given);
    given = x;
  }
  const SomJson *edits = som_json_get(cc, "edits");
  for (size_t i = 0; i < som_json_array_len(edits); i++) {
    const SomJson *pair = som_json_array_at(edits, i);
    const char *from = som_json_as_str(som_json_array_at(pair, 0));
    const char *to = som_json_as_str(som_json_array_at(pair, 1));
    if (from == NULL || to == NULL || strstr(given, from) == NULL) {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, som_json_str_or(cc, "name"));
      som_buf_puts(&b, ": the rendition has no ");
      put_json_str(&b, from != NULL ? from : "");
      *err = som_buf_take(&b);
      free(given);
      free(markdown);
      spec_document_free(&doc);
      return NULL;
    }
    char *x = rn_replace_first(given, from, to);
    free(given);
    given = x;
  }
  SpecMarkdownImport imp;
  spec_document_from_markdown(given, model, &imp);
  SomBuf out;
  som_buf_init(&out);
  som_buf_puts(&out, "{\"markdown\":");
  put_json_str(&out, markdown);
  if (strcmp(given, markdown) != 0) {
    som_buf_puts(&out, ",\"given\":");
    put_json_str(&out, given);
  }
  som_buf_puts(&out, ",\"rejections\":[");
  for (size_t i = 0; i < imp.result.rejections_len; i++) {
    if (i > 0) som_buf_putc(&out, ',');
    put_json_str(&out, imp.result.rejections[i].reason);
  }
  char *a = rn_doc_canon(imp.document);
  char *b2 = rn_doc_canon(&doc);
  som_buf_puts(&out, "],\"parseMatches\":");
  som_buf_puts(&out, strcmp(a, b2) == 0 ? "true" : "false");
  free(a);
  free(b2);
  char *reemit = rn_rendition_of(model, imp.document, "links", markers,
                                 generated, err);
  spec_markdown_import_free(&imp);
  free(given);
  spec_document_free(&doc);
  if (reemit == NULL) {
    som_buf_free(&out);
    free(markdown);
    return NULL;
  }
  som_buf_puts(&out, ",\"reemitMatches\":");
  som_buf_puts(&out, strcmp(reemit, markdown) == 0 ? "true" : "false");
  som_buf_putc(&out, '}');
  free(reemit);
  free(markdown);
  return som_buf_take(&out);
}

/* ---- the intent matchers ----------------------------------------------------------- */

/* `\[Also in \[[^\]]+\]\([^)]+\), held <where>`. */
static int rn_has_also_in(const char *md, const char *held) {
  static const char start[] = "[Also in [";
  char want[64];
  snprintf(want, sizeof(want), "), held %s", held);
  for (const char *p = strstr(md, start); p != NULL; p = strstr(p + 1, start)) {
    const char *rest = p + sizeof(start) - 1;
    const char *j = strchr(rest, ']');
    if (j == NULL || j == rest || strncmp(j, "](", 2) != 0) continue;
    const char *after = j + 2;
    const char *k = strchr(after, ')');
    if (k == NULL || k == after) continue;
    if (strncmp(k, want, strlen(want)) == 0) return 1;
  }
  return 0;
}

static int rn_is_word(char ch) {
  return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ||
         (ch >= '0' && ch <= '9') || ch == '_';
}

/* `\w+, \w+` at the start of `s`. */
static int rn_two_words(const char *s) {
  size_t a = 0;
  while (rn_is_word(s[a])) a++;
  return a > 0 && s[a] == ',' && s[a + 1] == ' ' && rn_is_word(s[a + 2]);
}

/* `Derived from (\[[^\]]+\]\([^)]+\)(,)?)+: \w+, \w+`. */
static int rn_has_derived_two_fields(const char *md) {
  static const char start[] = "Derived from ";
  for (const char *s = strstr(md, start); s != NULL; s = strstr(s + 1, start)) {
    const char *p = s + sizeof(start) - 1;
    while (*p == '[') {
      const char *j = strchr(p + 1, ']');
      if (j == NULL || j == p + 1 || strncmp(j, "](", 2) != 0) break;
      const char *k = strchr(j + 2, ')');
      if (k == NULL || k == j + 2) break;
      p = k + 1;
      if (strncmp(p, ": ", 2) == 0 && rn_two_words(p + 2)) return 1;
      if (*p == ',') {
        p++;
        if (strncmp(p, ": ", 2) == 0 && rn_two_words(p + 2)) return 1;
      }
    }
  }
  return 0;
}

/* `(?m)^#+ <!--\[LNK-REF\]--> <a id="REQ-EXPORT/LNK-1/LNK-REF"></a> `. */
static int rn_has_qualified_three(const char *md) {
  static const char want[] =
      " <!--[LNK-REF]--> <a id=\"REQ-EXPORT/LNK-1/LNK-REF\"></a> ";
  SomStrList lines;
  rn_lines(md, &lines);
  int found = 0;
  for (size_t i = 0; i < lines.len && !found; i++) {
    const char *l = lines.items[i];
    size_t h = 0;
    while (l[h] == '#') h++;
    found = h > 0 && strncmp(l + h, want, sizeof(want) - 1) == 0;
  }
  som_strlist_free(&lines);
  return found;
}

/* `(?m)^## <!--\[REQCOV\]--> <a id="REQCOV"></a> [^\n]*\n\n(\[[^\n]*\]\{\.linked\}\n\n)?::: \{\.derived `. */
static int rn_has_generated_first(const char *md) {
  static const char head[] = "## <!--[REQCOV]--> <a id=\"REQCOV\"></a> ";
  static const char derived[] = "::: {.derived ";
  SomStrList l;
  rn_lines(md, &l);
  int found = 0;
  for (size_t i = 0; i < l.len && !found; i++) {
    if (strncmp(l.items[i], head, sizeof(head) - 1) != 0) continue;
    if (i + 1 >= l.len || l.items[i + 1][0] != '\0') continue;
    if (i + 2 < l.len &&
        strncmp(l.items[i + 2], derived, sizeof(derived) - 1) == 0) {
      found = 1;
    } else if (i + 4 < l.len &&
               rn_is_marker_line(l.items[i + 2], strlen(l.items[i + 2])) &&
               l.items[i + 3][0] == '\0' &&
               strncmp(l.items[i + 4], derived, sizeof(derived) - 1) == 0) {
      found = 1;
    }
  }
  som_strlist_free(&l);
  return found;
}

/* Whether the rendition-case intent `token` holds in case `cc` (the Dart
 * test's `_renditionIntentHolds`); -1 for an unknown token. */
static int rn_intent_holds(const char *token, const SomJson *cc) {
  const SomJson *e = som_json_get(cc, "expect");
  const char *md = som_json_str_or(e, "markdown");
  const SomJson *pm = som_json_get(e, "parseMatches");
  const SomJson *rm = som_json_get(e, "reemitMatches");
  int parsed = pm != NULL && pm->type == SOM_JSON_BOOL && pm->as.boolean;
  int reemit = rm != NULL && rm->type == SOM_JSON_BOOL && rm->as.boolean;
  const char *given = som_json_as_str(som_json_get(e, "given"));
  int edited = given != NULL;
  if (given == NULL) given = "";
#define HAS(x) (strstr(md, (x)) != NULL)
  if (strcmp(token, "alsoInHeldThere") == 0) return rn_has_also_in(md, "there");
  if (strcmp(token, "alsoInHeldHere") == 0) return rn_has_also_in(md, "here");
  if (strcmp(token, "heldException") == 0) return HAS(" except REQ.owner");
  if (strcmp(token, "summaryOf") == 0) {
    return HAS("held there except REQ.owner; Summary of "
               "[REQ-EXPORT](#REQ-EXPORT)]{.linked}");
  }
  if (strcmp(token, "summarisedIn") == 0) return HAS("Summarised in [KEY-1](#KEY-1)");
  if (strcmp(token, "derivedTwoFields") == 0) return rn_has_derived_two_fields(md);
  if (strcmp(token, "extractedFrom") == 0) {
    return HAS("[Extracted from [REQD](#REQ-EXPORT/REQD)]{.linked}");
  }
  if (strcmp(token, "copyOf") == 0) {
    return HAS("[Copy of [CRIT](#CRIT), edit it there]{.linked}");
  }
  if (strcmp(token, "copiedTo") == 0) return HAS("Copied to [CRIT](#CSUM/CRIT)");
  if (strcmp(token, "copyAnchors") == 0) return HAS("<a id=\"CSUM/CRIT/CRIT-SPEED\"></a>");
  if (strcmp(token, "qualifiedThree") == 0) return rn_has_qualified_three(md);
  if (strcmp(token, "markerRestored") == 0) {
    return edited && strstr(given, "{.linked}") == NULL && parsed && reemit;
  }
  if (strcmp(token, "handEditDiscarded") == 0) {
    return edited && strstr(given, "Copy of [X]") != NULL && parsed && reemit;
  }
  if (strcmp(token, "emptyMarker") == 0) {
    return HAS("[]{.linked}\n\n[To be chosen") && parsed;
  }
  if (strcmp(token, "spanKept") == 0) {
    char *state = json_text(som_json_get(cc, "state"));
    int yes = strstr(state, "{.linked}") != NULL && parsed;
    free(state);
    return yes;
  }
  if (strcmp(token, "dangling") == 0) {
    return HAS("[Also in [BLU REQ-PRESETS](links.blu.tomspecs.md#REQ-PRESETS), "
               "held here");
  }
  if (strcmp(token, "generatedTrace") == 0) {
    return HAS("::: {.derived label=\"Generated from each requirement's "
               "traceability; edit it there\"}\n"
               "| Requirement | Use cases | Screens | Data entities | Tests |");
  }
  if (strcmp(token, "generatedCoverage") == 0) {
    static const char pre[] =
        "| Requirement | Covered | By |\n| --- | --- | --- |\n"
        "| [FRE-REQU-TENANT-LIFECYCLE](#FRE-REQU-TENANT-LIFECYCLE) | ";
    char yes[256], no[256];
    snprintf(yes, sizeof(yes), "%syes |", pre);
    snprintf(no, sizeof(no), "%sno |", pre);
    return HAS(yes) || HAS(no);
  }
  if (strcmp(token, "generatedRelationships") == 0) {
    return HAS("| Requirement | Dependency | Related requirement |");
  }
  if (strcmp(token, "generatedFirst") == 0) return rn_has_generated_first(md);
  if (strcmp(token, "generatedOverview") == 0) {
    return HAS("<!--[RO-TRAC]-->") && HAS("| Requirement | Use cases | Screens |");
  }
  if (strcmp(token, "generatedUseCases") == 0) {
    return HAS("| [INEN-INTE-UC-02](#INEN-INTE-UC-02) |  | "
               "[FRE-REQU-TENANT-FEATURES](");
  }
  if (strcmp(token, "generatedEditDiscarded") == 0) {
    return edited && strstr(given, "| Requirement | Covered |\n") != NULL &&
           parsed && reemit;
  }
  if (strcmp(token, "noGenerated") == 0) return !HAS("{.derived");
  if (strcmp(token, "emptyGenerated") == 0) {
    return HAS("::: {.derived}\n:::\n\n::: {.derived}\nTraced by hand.\n:::");
  }
  if (strcmp(token, "summaryRowLink") == 0) {
    return HAS("| <a id=\"TOP-BETA\"></a>[TOP-BETA](#TOP-BETA) |") &&
           HAS("| <a id=\"TOP-BETA\"></a>TOP-BETA |");
  }
  if (strcmp(token, "noMarkers") == 0) {
    return !HAS("{.linked}") && HAS("<a id=\"REQ-EXPORT/REQD\"></a>");
  }
  if (strcmp(token, "roundTrip") == 0) return !edited && parsed && reemit;
  if (strcmp(token, "clean") == 0) {
    const SomJson *r = som_json_get(e, "rejections");
    return r != NULL && r->type == SOM_JSON_ARRAY && som_json_array_len(r) == 0;
  }
#undef HAS
  return -1;
}

/* ---- the tables ------------------------------------------------------------------- */

/* The sorted keys of a JSON object, joined by ','. Owned. */
static char *rn_sorted_keys(const SomJson *v) {
  SomStrList keys;
  som_strlist_init(&keys);
  if (v != NULL && v->type == SOM_JSON_OBJECT) {
    for (size_t i = 0; i < v->as.object.len; i++) {
      som_strlist_push_copy(&keys, v->as.object.members[i].key);
    }
  }
  qsort(keys.items, keys.len, sizeof(char *), typed_key_cmp);
  char *out = som_strlist_join(&keys, ",");
  som_strlist_free(&keys);
  return out;
}

/* Replays `link_rendition_cases.json`: each case's rendition, what the parser
 * makes of it and the rendition of that, against the expectation, and its
 * intent. */
static void test_link_rendition(Checker *c) {
  SomJson *table = read_json("link_rendition_cases.json");
  SpecModel *fixture = ds_table_model(table);
  const SomJson *cases = som_json_get(table, "cases");
  static const char *const keys[] = {"markdown", "given", "rejections",
                                     "parseMatches", "reemitMatches"};
  char tag[1024];
  for (size_t i = 0; i < som_json_array_len(cases); i++) {
    const SomJson *cc = som_json_array_at(cases, i);
    const char *name = som_json_str_or(cc, "name");
    SpecModel *inline_model = ds_model_from(som_json_get(cc, "inline"));
    const SpecModel *model = ds_model_of(fixture, inline_model, cc);
    char *err = NULL;
    char *got_text = rn_rendition_case(model, cc, &err);
    if (got_text == NULL) {
      snprintf(tag, sizeof(tag), "links.rendition[%s]", name);
      char detail[1200];
      snprintf(detail, sizeof(detail), "threw %s", err != NULL ? err : "");
      check(c, tag, 0, detail);
      free(err);
    } else {
      char *perr = NULL;
      SomJson *got = som_json_parse(got_text, &perr);
      free(perr);
      const SomJson *expect = som_json_get(cc, "expect");
      for (size_t k = 0; k < sizeof(keys) / sizeof(keys[0]); k++) {
        const SomJson *g = som_json_get(got, keys[k]);
        const SomJson *w = som_json_get(expect, keys[k]);
        int ok = (g == NULL && w == NULL) ||
                 (g != NULL && w != NULL && ds_json_eq(g, w));
        snprintf(tag, sizeof(tag), "links.rendition[%s].%s", name, keys[k]);
        if (ok) {
          check(c, tag, 1, "");
        } else {
          char *gs = g != NULL ? json_text(g) : som_strdup("null");
          char *ws = w != NULL ? json_text(w) : som_strdup("null");
          SomBuf d;
          som_buf_init(&d);
          som_buf_puts(&d, "got ");
          som_buf_puts(&d, gs);
          som_buf_puts(&d, " want ");
          som_buf_puts(&d, ws);
          char *detail = som_buf_take(&d);
          check(c, tag, 0, detail);
          free(detail);
          free(gs);
          free(ws);
        }
      }
      char *gk = rn_sorted_keys(got);
      char *ek = rn_sorted_keys(expect);
      snprintf(tag, sizeof(tag), "links.rendition[%s].keys", name);
      char detail[512];
      snprintf(detail, sizeof(detail), "%s vs %s", gk, ek);
      check(c, tag, strcmp(gk, ek) == 0, detail);
      free(gk);
      free(ek);
      som_json_free(got);
      free(got_text);
    }
    const SomJson *intent = som_json_get(cc, "intent");
    for (size_t k = 0; k < som_json_array_len(intent); k++) {
      const char *token = som_json_as_str(som_json_array_at(intent, k));
      if (token == NULL) continue;
      int holds = rn_intent_holds(token, cc);
      snprintf(tag, sizeof(tag), "links.rendition.intent[%s: %s]", name, token);
      check(c, tag, holds == 1, ds_intent_detail(holds));
    }
    if (inline_model != NULL) spec_model_free(inline_model);
  }
  spec_model_free(fixture);
  som_json_free(table);
}

/* A file below the corpus folder, NULL when it cannot be read. Owned. */
static char *rn_read_file(const char *rel) {
  char path[4608];
  snprintf(path, sizeof(path), "%s/%s", g_corpus_dir, rel);
  FILE *f = fopen(path, "rb");
  if (f == NULL) return NULL;
  SomBuf b;
  som_buf_init(&b);
  char chunk[8192];
  size_t n;
  while ((n = fread(chunk, 1, sizeof(chunk), f)) > 0) som_buf_putn(&b, chunk, n);
  fclose(f);
  return som_buf_take(&b);
}

/* The schema-tier findings of `doc`'s rendition, `rule section` each, sorted
 * and joined by '\n'; NULL with `*err` on failure. `*md_out` takes the
 * rendition when non-NULL. */
static char *rn_findings(const SpecModel *model, const SpecDocument *doc,
                         const DocSpecsSchema *schema, int navigation,
                         char **md_out, char **err) {
  char *md = rn_rendition_of(model, doc, "", navigation, navigation, err);
  if (md == NULL) return NULL;
  DocSpecsValidator val = docspecs_validator_new_with(schema, 1);
  DocSpecsViolationList found;
  docspecs_violation_list_init(&found);
  docspecs_validator_validate_markdown(&val, md, &found);
  SomStrList keys;
  som_strlist_init(&keys);
  for (size_t i = 0; i < found.len; i++) {
    SomBuf k;
    som_buf_init(&k);
    som_buf_puts(&k, found.items[i].rule);
    som_buf_putc(&k, ' ');
    som_buf_puts(&k, found.items[i].section_id);
    som_strlist_push(&keys, som_buf_take(&k));
  }
  docspecs_violation_list_free(&found);
  qsort(keys.items, keys.len, sizeof(char *), typed_key_cmp);
  char *out = som_strlist_join(&keys, "\n");
  som_strlist_free(&keys);
  if (md_out != NULL) {
    *md_out = md;
  } else {
    free(md);
  }
  return out;
}

/* The schema tier finds nothing in the markers and generated parts (the Dart
 * test's RNC5, real model): each document's findings with navigation equal
 * its findings without. */
static void test_rendition_schema_tier(Checker *c) {
  SomJson *table = read_json("uam_requirements_cut.json");
  DocumentJson st;
  SpecDocument rsp, sbp, isc;
  document_json_from_json(som_json_get(table, "rsp"), &st);
  doc_from_state(&rsp, &st);
  document_json_free(&st);
  document_json_from_json(som_json_get(table, "blueprint"), &st);
  doc_from_state(&sbp, &st);
  document_json_free(&st);
  spec_document_init(&isc);
  char *item = spec_document_add_list_item_with_section_id(
      &isc, "ISC/interactionCatalog/INEN-INTE-LST", "INEN-INTE-UC-01", NULL);
  if (item != NULL) {
    SomBuf fp;
    som_buf_init(&fp);
    som_buf_puts(&fp, item);
    som_buf_puts(&fp, "/INTR");
    char *form_path = som_buf_take(&fp);
    spec_document_set_form_field(&isc, form_path, "relatedRequirements",
                                 "FRE-REQU-TENANT-LIFECYCLE");
    free(form_path);
    free(item);
  }
  const SpecModel *model = ds_real_model();
  const SpecDocument *docs[3] = {&rsp, &sbp, &isc};
  static const char *const ids[3] = {"requirements-specification",
                                     "solution-blueprint",
                                     "interaction-scenarios"};
  char tag[512];
  for (int d = 0; d < 3; d++) {
    snprintf(tag, sizeof(tag), "links.rendition.schemaTier[%s]", ids[d]);
    char rel[512];
    snprintf(rel, sizeof(rel),
             "../../tom_som_dart_v0/schemas/%s/%s.1.0.docspecs-schema.yaml",
             ids[d], ids[d]);
    char *yaml = rn_read_file(rel);
    DocSpecsSchema *schema = NULL;
    char *serr = NULL;
    if (yaml == NULL || !docspecs_schema_from_yaml_text(yaml, &schema, &serr)) {
      char detail[1024];
      snprintf(detail, sizeof(detail), "threw %s",
               yaml == NULL ? "cannot read the schema" : (serr ? serr : ""));
      check(c, tag, 0, detail);
      free(serr);
      free(yaml);
      continue;
    }
    free(yaml);
    char *err = NULL;
    char *md = NULL;
    char *with = rn_findings(model, docs[d], schema, 1, &md, &err);
    char *without = with != NULL ? rn_findings(model, docs[d], schema, 0, NULL, &err)
                                 : NULL;
    if (with == NULL || without == NULL) {
      char detail[1024];
      snprintf(detail, sizeof(detail), "threw %s", err != NULL ? err : "");
      check(c, tag, 0, detail);
    } else {
      char dtag[600];
      snprintf(dtag, sizeof(dtag), "%s.derived", tag);
      check(c, dtag, strstr(md, "{.derived") != NULL, "");
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "got [");
      som_buf_puts(&b, with);
      som_buf_puts(&b, "] want [");
      som_buf_puts(&b, without);
      som_buf_puts(&b, "]");
      char *detail = som_buf_take(&b);
      check(c, tag, strcmp(with, without) == 0, detail);
      free(detail);
    }
    free(err);
    free(md);
    free(with);
    free(without);
    docspecs_schema_free(schema);
  }
  spec_document_free(&rsp);
  spec_document_free(&sbp);
  spec_document_free(&isc);
  som_json_free(table);
}
