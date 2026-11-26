/* spec_document_set_internal — the comparison behind `spec_sync_report`, read
 * by `spec_backfill` and `spec_prefill` too (private to the library). A port
 * of the `SpecSetCheck` / `SpecSetSide` internals of the Rust
 * `spec_document_set.rs`. */
#ifndef SPEC_DOCUMENT_SET_INTERNAL_H
#define SPEC_DOCUMENT_SET_INTERNAL_H

#include "spec_document_set.h"
#include "spec_place.h"
#include "spec_reflection.h"

/* One value of a subtree, keyed for comparison. */
typedef struct {
  char *key; /* `c:` content, `f:` form field, `h:` headline */
  char *path;
  /* The form field (SPEC_HEADLINE_FIELD for a headline), "" for content. */
  char *field;
  char *value;
  int pending;
  const FormFieldSpec *spec; /* borrowed from the model, NULL for none */
} SpecSetValue;

/* A document side of a pair: its subtree's values and items, keyed by the
 * path below the anchor with list items written by their section id. Shared
 * by the findings that name it (reference counted). */
typedef struct {
  int refs;
  char *name;
  char *root;
  char *anchor;
  /* The values, sorted by key. */
  SpecSetValue *values;
  size_t values_len;
  size_t values_cap;
  /* Item key -> item path, and the anchor's own key "". */
  SomMap items;
  /* The keys of `items` in the order they were collected. */
  SomStrList item_keys;
} SpecSetSide;

/* Drops one reference (frees at zero); NULL is ignored. */
void spec_set_side_release(SpecSetSide *s);
/* The value of `key`, or NULL. */
const SpecSetValue *spec_set_side_value(const SpecSetSide *s, const char *key);

/* A finding with its sort keys (and, for a pair's finding, its two sides). */
typedef struct {
  size_t seq; /* the position it was added at (the sorts are stable) */
  size_t order;
  char *key;
  SpecSyncFinding finding;
  SpecSetSide *b; /* a reference, NULL for none */
  SpecSetSide *d;
} SpecSetFound;

typedef struct SpecSetCheckCache SpecSetCheckCache;

/* The comparison behind `spec_sync_report` (and `backfill`, `prefill`): one
 * per run, with its caches. */
typedef struct {
  const SpecDocumentSet *set; /* borrowed */
  SpecReflection refl;
  /* The findings collected so far. */
  SpecSetFound *out;
  size_t out_len;
  size_t out_cap;
  /* The pairs whose Phase 3 document exists but holds nothing beneath the
   * pair's anchor. */
  SomStrList not_started_pairs;
  SpecSetCheckCache *cache; /* owned */
} SpecSetCheck;

void spec_set_check_init(SpecSetCheck *c, const SpecDocumentSet *set);
void spec_set_check_free(SpecSetCheck *c);
/* Sorts `out` as the report lists it (by order, key, code, then value). */
void spec_set_check_sort_out(SpecSetCheck *c);
/* Sorts `out` by order, key and code only (what `backfill` applies in). */
void spec_set_check_sort_out_by_code(SpecSetCheck *c);
/* The effective section id of the list item at `item_path` in `doc` (cached
 * per document address). Owned. */
char *spec_set_check_item_id(SpecSetCheck *c, const SpecDocument *doc,
                             const char *item_path);
/* The key of an anchor itself among its siblings: the ids of the list items
 * on its path. Owned. */
char *spec_set_check_anchor_key(SpecSetCheck *c, const SpecDocument *doc,
                                const char *path);
/* The values beneath `anchor` in `doc`, with what the pair does not compare
 * left out. A new side (one reference). */
SpecSetSide *spec_set_check_collect(SpecSetCheck *c, const char *name,
                                    const SpecDocument *doc, const char *root,
                                    const char *anchor,
                                    const SpecSyncPair *pair,
                                    const SomStrList *nested);
/* Compares one pair, adding its findings at `order`. */
void spec_set_check_compare_pair(SpecSetCheck *c, const SpecSyncPair *pair,
                                 size_t order);
/* Adds the findings of the links across two documents at `order`; `pairs`
 * (non-NULL) keeps those of the classes with those section ids. */
void spec_set_check_cross_checks(SpecSetCheck *c, const SomStrList *pairs,
                                 size_t order);

/* The stored section id of the item at `item_path`, else the one its position
 * and the list's pattern give it. Owned. */
char *spec_set_effective_item_id(const SpecReflection *refl,
                                 const SpecDocument *doc,
                                 const char *item_path);

/* Replaces the document named `name` with a copy of `document`, without the
 * checks of `spec_document_set_put` (the writes of `backfill` and `prefill`,
 * which keep its root). */
void spec_document_set_replace(SpecDocumentSet *set, const char *name,
                               const SpecDocument *document);

/* Whether `name` is in `scope` (NULL: every pair). */
int spec_set_in_scope(const SomStrList *scope, const char *name);

/* The value at `path` / `field` of `doc` ("" content, SPEC_HEADLINE_FIELD a
 * headline), "" when unset. Borrowed. */
const char *spec_set_get_value(const SpecDocument *doc, const char *path,
                               const char *field);
/* Writes `value` at `path` / `field` of `doc` ("" clears it). */
void spec_set_set_value(SpecDocument *doc, const char *path, const char *field,
                        const char *value);
/* Appends an item to `lst` with the section id `id` (NULL: none). Owned. */
char *spec_set_add_item(SpecDocument *doc, const char *lst, const char *id);

#endif /* SPEC_DOCUMENT_SET_INTERNAL_H */
