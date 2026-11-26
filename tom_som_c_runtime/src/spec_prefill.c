/* spec_prefill — see include/spec_prefill.h. A port of the Rust
 * `spec_prefill.rs`. */
#include "spec_prefill.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_document_set_internal.h"
#include "spec_links_validator.h"

static char *scat(const char *first, ...) {
  SomBuf b;
  som_buf_init(&b);
  va_list ap;
  va_start(ap, first);
  for (const char *s = first; s != NULL; s = va_arg(ap, const char *)) {
    som_buf_puts(&b, s);
  }
  va_end(ap);
  return som_buf_take(&b);
}

static const char *or_empty(const char *s) { return s != NULL ? s : ""; }

static int has_text(const char *s) { return s != NULL && s[0] != '\0'; }

static int beneath_path(const char *path, const char *root) {
  size_t n = strlen(root);
  return strncmp(path, root, n) == 0 && path[n] == '/';
}

static void jstr(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s != NULL ? s : "");
  som_buf_puts(b, q);
  free(q);
}

static void jstrs(SomBuf *b, const SomStrList *l) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    jstr(b, l->items[i]);
  }
  som_buf_putc(b, ']');
}

const char *spec_prefill_error_code_name(SpecPrefillErrorCode code) {
  return code == SPEC_PREFILL_ERROR_UNKNOWN_ROOT ? "unknownRoot" : "noBlueprint";
}

void spec_prefill_error_init(SpecPrefillError *e) {
  e->code = SPEC_PREFILL_ERROR_NO_BLUEPRINT;
  e->message = NULL;
}

void spec_prefill_error_free(SpecPrefillError *e) {
  free(e->message);
  spec_prefill_error_init(e);
}

char *spec_prefill_error_display(const SpecPrefillError *e) {
  return scat("SpecPrefillError(", spec_prefill_error_code_name(e->code), "): ",
              or_empty(e->message), NULL);
}

void spec_prefill_result_free(SpecPrefillResult *r) {
  spec_document_free(&r->document);
  free(r->name);
  som_strlist_free(&r->filled_pairs);
  som_strlist_free(&r->skipped_pairs);
  spec_derive_result_free(&r->derived);
  spec_validation_errors_free(&r->findings);
  memset(r, 0, sizeof(*r));
}

char *spec_prefill_result_to_json(const SpecPrefillResult *r) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"name\":");
  jstr(&b, r->name);
  som_buf_puts(&b, ",\"created\":");
  som_buf_puts(&b, r->created ? "true" : "false");
  som_buf_puts(&b, ",\"filledPairs\":");
  jstrs(&b, &r->filled_pairs);
  som_buf_puts(&b, ",\"skippedPairs\":");
  jstrs(&b, &r->skipped_pairs);
  som_buf_puts(&b, ",\"derived\":{\"changes\":[");
  for (size_t i = 0; i < r->derived.changes_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    char *c = spec_derive_change_to_json(&r->derived.changes[i]);
    som_buf_puts(&b, c);
    free(c);
  }
  som_buf_puts(&b, "],\"unresolved\":");
  char *u = spec_validation_errors_json(&r->derived.unresolved);
  som_buf_puts(&b, u);
  free(u);
  som_buf_puts(&b, "},\"findings\":");
  char *f = spec_validation_errors_json(&r->findings);
  som_buf_puts(&b, f);
  free(f);
  som_buf_puts(&b, ",\"document\":");
  char *d = spec_document_stores_json(&r->document);
  som_buf_puts(&b, d);
  free(d);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* The concrete detail anchor of `pattern` in `doc` for a Blueprint anchor
 * whose list items carry `ids` (`a/b`, in order): each `<list>-*` taken as the
 * item of that id, created with it when missing (and listed in `created`).
 * Owned. */
static char *anchor_in(SpecSetCheck *c, SpecDocument *doc, const char *pattern,
                       const char *ids, SomStrList *created) {
  SomStrList want;
  som_strlist_init(&want);
  if (ids[0] != '\0') {
    const char *p = ids;
    for (;;) {
      const char *slash = strchr(p, '/');
      if (slash == NULL) {
        som_strlist_push_copy(&want, p);
        break;
      }
      som_strlist_push(&want, som_strdup_n(p, (size_t)(slash - p)));
      p = slash + 1;
    }
  }
  size_t k = 0;
  char *cur = som_strdup("");
  const char *s = pattern;
  for (;;) {
    const char *slash = strchr(s, '/');
    size_t n = slash != NULL ? (size_t)(slash - s) : strlen(s);
    char *seg = som_strdup_n(s, n);
    size_t sl = strlen(seg);
    if (sl >= 2 && strcmp(seg + sl - 2, "-*") == 0) {
      char *base = som_strdup_n(seg, sl - 2);
      char *lst = scat(cur, "/", base, NULL);
      free(base);
      const char *id = k < want.len ? want.items[k++] : "";
      char *hit = NULL;
      const SomStrList *items = spec_document_list_items(doc, lst);
      for (size_t i = 0; items != NULL && i < items->len && hit == NULL; i++) {
        char *item_id = spec_set_check_item_id(c, doc, items->items[i]);
        if (strcmp(item_id, id) == 0) hit = som_strdup(items->items[i]);
        free(item_id);
      }
      free(cur);
      if (hit != NULL) {
        cur = hit;
      } else {
        cur = spec_set_add_item(doc, lst, id);
        som_strlist_push_copy(created, cur);
      }
      free(lst);
    } else {
      char *next = cur[0] == '\0' ? som_strdup(seg) : scat(cur, "/", seg, NULL);
      free(cur);
      cur = next;
    }
    free(seg);
    if (slash == NULL) break;
    s = slash + 1;
  }
  som_strlist_free(&want);
  return cur;
}

/* The mapping of `bp_path` among `from` -> `to`: the longest `from` it is or
 * lies beneath, its tail appended. Owned, NULL for none. */
static char *map_into(const SomStrList *from, const SomStrList *to,
                      const char *bp_path) {
  long best = -1;
  size_t best_len = 0;
  for (size_t i = 0; i < from->len; i++) {
    const char *f = from->items[i];
    if (strcmp(bp_path, f) != 0 && !beneath_path(bp_path, f)) continue;
    size_t n = strlen(f);
    if (best < 0 || n >= best_len) {
      best = (long)i;
      best_len = n;
    }
  }
  return best < 0 ? NULL : scat(to->items[best], bp_path + best_len, NULL);
}

/* Copies the Blueprint values of `side` beneath `anchor` of `doc`: list items
 * first, in the Blueprint's order and with their section ids, then every
 * value. Whether anything was written. */
static int copy_side(SpecSetCheck *c, const SpecDocument *bp,
                     const SpecSetSide *side, SpecDocument *doc,
                     const char *anchor) {
  int wrote = 0;
  SomStrList from, to;
  som_strlist_init(&from);
  som_strlist_init(&to);
  som_strlist_push_copy(&from, side->anchor);
  som_strlist_push_copy(&to, anchor);
  /* Items, outer lists first, each list in the Blueprint's order. */
  SomStrList lists;
  som_strlist_init(&lists);
  SomMap item_paths;
  som_map_init(&item_paths);
  for (size_t k = 0; k < side->item_keys.len; k++) {
    const char *item = som_map_get(&side->items, side->item_keys.items[k]);
    if (item == NULL) continue;
    som_map_set(&item_paths, item, "1");
    if (strcmp(item, side->anchor) != 0) {
      const char *dash = strrchr(item, '-');
      char *lst = dash != NULL ? som_strdup_n(item, (size_t)(dash - item))
                               : som_strdup(item);
      if (!som_strlist_contains(&lists, lst)) {
        som_strlist_push(&lists, lst);
      } else {
        free(lst);
      }
    }
  }
  for (size_t a = 1; a < lists.len; a++) {
    char *cur = lists.items[a];
    size_t b = a;
    while (b > 0 && strlen(lists.items[b - 1]) > strlen(cur)) {
      lists.items[b] = lists.items[b - 1];
      b--;
    }
    lists.items[b] = cur;
  }
  for (size_t l = 0; l < lists.len; l++) {
    char *target = map_into(&from, &to, lists.items[l]);
    if (target == NULL) continue;
    const SomStrList *items = spec_document_list_items(bp, lists.items[l]);
    for (size_t i = 0; items != NULL && i < items->len; i++) {
      const char *item = items->items[i];
      if (som_map_get(&item_paths, item) == NULL) continue;
      char *id = spec_set_check_item_id(c, bp, item);
      char *new_item = spec_set_add_item(doc, target, id);
      som_strlist_push_copy(&from, item);
      som_strlist_push(&to, new_item);
      free(id);
      wrote = 1;
    }
    free(target);
  }
  for (size_t i = 0; i < side->values_len; i++) {
    const SpecSetValue *v = &side->values[i];
    if (v->value[0] == '\0') continue;
    char *p = map_into(&from, &to, v->path);
    if (p == NULL) continue;
    spec_set_set_value(doc, p, v->field, v->value);
    free(p);
    wrote = 1;
  }
  som_map_free(&item_paths);
  som_strlist_free(&lists);
  som_strlist_free(&from);
  som_strlist_free(&to);
  return wrote;
}

int spec_prefill(SpecDocumentSet *set, const char *root_type,
                 const SpecPrefillOptions *options, SpecPrefillResult *out,
                 SpecPrefillError *err) {
  memset(out, 0, sizeof(*out));
  spec_document_init(&out->document);
  som_strlist_init(&out->filled_pairs);
  som_strlist_init(&out->skipped_pairs);
  SpecPrefillOptions none;
  memset(&none, 0, sizeof(none));
  if (options == NULL) options = &none;
  const char *bp_root = set->blueprint_root;
  const char *bp_name_c = spec_document_set_name_of(set, bp_root);
  if (bp_name_c == NULL || bp_root[0] == '\0') {
    if (err != NULL) {
      spec_prefill_error_free(err);
      err->code = SPEC_PREFILL_ERROR_NO_BLUEPRINT;
      err->message = som_strdup("the set holds no Blueprint");
    }
    return 0;
  }
  const SpecRoot *root = NULL;
  for (size_t i = 0; i < set->model->roots_len && root == NULL; i++) {
    const SpecRoot *r = &set->model->roots[i];
    if (strcmp(r->type, or_empty(root_type)) == 0 ||
        strcmp(or_empty(r->section_id), or_empty(root_type)) == 0) {
      root = r;
    }
  }
  if (root == NULL || strcmp(root->type, bp_root) == 0) {
    if (err != NULL) {
      spec_prefill_error_free(err);
      err->code = SPEC_PREFILL_ERROR_UNKNOWN_ROOT;
      err->message = scat(or_empty(root_type), " names no Phase 3 root of the model",
                          NULL);
    }
    return 0;
  }
  char *bp_name = som_strdup(bp_name_c);
  const char *existing_c = spec_document_set_name_of(set, root->type);
  char *existing = existing_c != NULL ? som_strdup(existing_c) : NULL;
  char *doc_name = existing != NULL           ? som_strdup(existing)
                   : has_text(options->name) ? som_strdup(options->name)
                                             : som_strdup(root->type);
  SpecDocument *doc = &out->document;
  if (existing != NULL) {
    spec_document_free(doc);
    spec_document_copy(doc, spec_document_set_get(set, existing));
  }

  {
    const SpecDocument *bp = spec_document_set_get(set, bp_name);
    SpecSetCheck c;
    spec_set_check_init(&c, set);
    for (size_t pi = 0; pi < set->pairs_len; pi++) {
      const SpecSyncPair *pair = &set->pairs[pi];
      if (strcmp(pair->detail_root, root->type) != 0) continue;
      if (!spec_set_in_scope(options->pairs, pair->section_id)) continue;
      /* Nested pairs are filled on their own (when they are this root's). */
      SomStrList nested;
      som_strlist_init(&nested);
      for (size_t oi = 0; oi < set->pairs_len; oi++) {
        if (oi == pi) continue;
        SomStrList ex;
        spec_expand_pattern(bp, set->pairs[oi].blueprint_anchor, &ex);
        for (size_t k = 0; k < ex.len; k++) som_strlist_push_copy(&nested, ex.items[k]);
        som_strlist_free(&ex);
      }
      int wrote = 0, held = 0;
      SomStrList anchors;
      spec_expand_pattern(bp, pair->blueprint_anchor, &anchors);
      for (size_t ai = 0; ai < anchors.len; ai++) {
        const char *ba = anchors.items[ai];
        char *ids = spec_set_check_anchor_key(&c, bp, ba);
        SomStrList created;
        som_strlist_init(&created);
        char *da = anchor_in(&c, doc, pair->detail_anchor, ids, &created);
        free(ids);
        if (spec_document_has_values_under(doc, da) && created.len == 0) {
          held = 1;
          free(da);
          som_strlist_free(&created);
          continue;
        }
        SomStrList beneath;
        som_strlist_init(&beneath);
        for (size_t k = 0; k < nested.len; k++) {
          if (beneath_path(nested.items[k], ba)) som_strlist_push_copy(&beneath, nested.items[k]);
        }
        SpecSetSide *side =
            spec_set_check_collect(&c, bp_name, bp, bp_root, ba, pair, &beneath);
        if (copy_side(&c, bp, side, doc, da)) {
          wrote = 1;
        } else {
          /* Nothing to copy: the anchor items made for it go again. */
          for (size_t k = created.len; k > 0; k--) {
            spec_document_remove_list_item(doc, created.items[k - 1]);
          }
        }
        spec_set_side_release(side);
        som_strlist_free(&beneath);
        som_strlist_free(&created);
        free(da);
      }
      som_strlist_free(&anchors);
      som_strlist_free(&nested);
      if (wrote) som_strlist_push_copy(&out->filled_pairs, pair->section_id);
      if (held && !wrote) som_strlist_push_copy(&out->skipped_pairs, pair->section_id);
    }
    spec_set_check_free(&c);
  }

  out->created = existing == NULL &&
                 spec_document_has_values_under(doc, spec_reflection_root_segment(root));
  if (out->created) {
    SpecDocumentSetError serr;
    spec_document_set_error_init(&serr);
    if (!spec_document_set_put(set, doc_name, doc, &serr)) {
      /* The reference runtimes raise: a filled document of one root. */
      char *why = spec_document_set_error_display(&serr);
      fprintf(stderr, "spec_prefill: %s\n", why);
      free(why);
      spec_document_set_error_free(&serr);
      abort();
    }
    spec_document_set_error_free(&serr);
  }
  SpecDeriveOptions plain;
  memset(&plain, 0, sizeof(plain));
  spec_derive_fields(set->model, doc, &plain, &out->derived);
  if (existing != NULL || out->created) spec_document_set_replace(set, doc_name, doc);
  validate_document(set->model, doc, &out->findings);
  SpecValidationErrors links;
  spec_validate_links(set->model, doc, &links);
  for (size_t i = 0; i < links.len; i++) {
    spec_validation_errors_push(&out->findings, links.items[i].path,
                                links.items[i].code, links.items[i].message);
  }
  spec_validation_errors_free(&links);
  out->name = doc_name;
  free(existing);
  free(bp_name);
  return 1;
}
