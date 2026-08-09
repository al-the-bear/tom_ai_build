/* spec_query — lexical/structural query + lazy cursor over a live SpecDocument
 * (`llm_and_d4rt_tools.md` §6, `som_multiplatform_spec_model.md` §15), a
 * faithful port of the Dart `spec_query.dart`.
 *
 * This is the **grep-like** facility the downstream scripting layer and the
 * editor's search tools reuse. It is **embedding-free** — exact substring or
 * `SomTextPattern` match plus structural filters — so it is always current and
 * needs no model calls.
 *
 * A `SpecQuery` composes (AND-combined) over five dimensions:
 *   - **text** — substring or `SomTextPattern` over content + form-field values
 *     and over a node's headline, stored or doc-comment (optionally
 *     case-insensitive);
 *   - **kind** — one or more node kinds (`SPEC_NODE_KIND_*`);
 *   - **class** — the model class a node *is* (by class name);
 *   - **id / path** — exact `@SectionId`, `@SectionId` prefix, path glob, or a
 *     `@MapsTo` / `@DetailedIn` target on the node's class;
 *   - **state** — empty / non-empty (the structural "empty = no value" test).
 *
 * `spec_query_engine_query` returns a `SpecQueryCursor` the caller iterates
 * lazily (next / take / count). The cursor captures the **structural** candidate
 * set when it is created, then **re-validates each path against the live
 * document on every step** — so a result whose list-item ancestor was removed
 * after the cursor was made is silently skipped (stable against concurrent
 * edits).
 *
 * ## "Unset" versus "set to the zero value"
 *
 * Every dimension of a `SpecQuery` is optional, and an absent dimension must
 * *not* collapse into a default that happens to match. The C representation
 * therefore uses:
 *   - a **NULL pointer** for the optional strings and for `kinds` — so `""` and
 *     an empty kind list stay meaningful "set to empty" values;
 *   - the package's paired `has_*` flag for `state`, which is an enum whose
 *     zero value (`SPEC_STATE_EMPTY`) is a real filter.
 * `spec_query_init` clears a query to all-unset; an all-unset query matches
 * every node in the document's structural closure.
 *
 * Ownership: the engine and the cursor **borrow** the model and document (both
 * must outlive them). A cursor owns its captured candidate paths and its
 * compiled pattern — release it with `spec_query_cursor_free`. A cursor also
 * copies the `SpecQuery` struct by value, but the strings it points at stay
 * borrowed, so they must outlive the cursor too. Every returned
 * `SpecQueryMatch` / `SpecNodeProjection` owns its strings; free with the
 * matching `*_free`.
 */
#ifndef SPEC_QUERY_H
#define SPEC_QUERY_H

#include "spec_document.h"
#include "spec_model.h"
#include "spec_reflection.h"
#include "spec_text_pattern.h"

/* Whether a node currently holds a value, used by the `state` dimension. */
typedef enum {
  /* The node (and everything beneath it) holds no value. */
  SPEC_STATE_EMPTY = 0,
  /* The node holds at least one value at or beneath its path. */
  SPEC_STATE_NON_EMPTY = 1,
} SpecStateFilter;

/* Parses `"empty"` / `"nonEmpty"` into `*out`. Returns 1 on success. */
int spec_state_filter_parse(const char *name, SpecStateFilter *out);
/* The name of `s` (`"empty"` / `"nonEmpty"`), a static literal. */
const char *spec_state_filter_name(SpecStateFilter s);

/* ---- node projection (tier-1 index source) ------------------------------- */

/* A flat, value-bearing projection of one document node — everything the tier-1
 * structural/lexical index needs to index a section **without re-walking the
 * model itself**.
 *
 * Optional strings are `""` when absent, the package-wide stand-in for the
 * other ports' `null`. */
typedef struct {
  char *path;                   /* the globally-unique section-id path */
  const char *kind;             /* static SPEC_NODE_KIND_* literal */
  char *class_id;               /* the class the node *is*; "" for leaves/lists */
  char *section_id;             /* field/class/root `@SectionId`; "" when none */
  char *maps_to;                /* `@MapsTo` on the node's class; "" when none */
  char *detailed_in;            /* `@DetailedIn` on the class; "" when none */
  char *headline;               /* stored headline else doc comment; "" if none */
  SomStrList searchable_strings; /* stored values, then the headline */
  int has_value;                /* the `state` facet (empty vs non-empty) */
} SpecNodeProjection;

void spec_node_projection_free(SpecNodeProjection *p);

typedef struct {
  SpecNodeProjection *items;
  size_t len;
  size_t cap;
} SpecNodeProjectionList;

void spec_node_projection_list_init(SpecNodeProjectionList *l);
void spec_node_projection_list_free(SpecNodeProjectionList *l);

/* ---- query match --------------------------------------------------------- */

/* One node matched by a `SpecQuery` (the cursor record). */
typedef struct {
  char *path;
  const char *kind;         /* static SPEC_NODE_KIND_* literal */
  char *class_id;           /* "" for value leaves and list containers */
  char *headline;           /* "" when neither stored nor documented */
  char *snippet;            /* the value/headline the pattern hit; "" when the
                             * query carried no `text` dimension */
  SpecMatchSpanList spans;  /* spans within `snippet`; empty for non-text queries */
} SpecQueryMatch;

void spec_query_match_free(SpecQueryMatch *m);

typedef struct {
  SpecQueryMatch *items;
  size_t len;
  size_t cap;
} SpecQueryMatchList;

void spec_query_match_list_init(SpecQueryMatchList *l);
void spec_query_match_list_free(SpecQueryMatchList *l);

/* ---- the query ----------------------------------------------------------- */

/* An AND-combined lexical/structural query. Every *set* dimension must hold for
 * a node to match; an all-unset query matches every node in the document's
 * structural closure. */
typedef struct {
  /* Substring (or `regex` pattern) to find in content + form values and the
   * headline. NULL = unset. */
  const char *text;
  /* Treat `text` as a `SomTextPattern` — the portable pattern subset — instead
   * of a literal substring. Named `regex` because that is what a caller reaches
   * for it expecting; the grammar is deliberately narrower than a full regex,
   * and `SomPatternError` says so rather than silently reinterpreting. */
  int regex;
  /* Match `text` case-insensitively. */
  int case_insensitive;
  /* The node kinds to include (any-of), as `SPEC_NODE_KIND_*` names. NULL
   * admits every kind; borrowed, must outlive the cursor. */
  const SomStrList *kinds;
  /* The model class name a node must *be*. NULL = unset. */
  const char *class_name;
  /* The node's `@SectionId` must equal this exactly. NULL = unset. */
  const char *section_id_exact;
  /* The node's `@SectionId` must start with this prefix. NULL = unset. */
  const char *section_id_prefix;
  /* A glob over the node's path (`*` matches within one segment, `**` across
   * segments). NULL = unset. */
  const char *path_glob;
  /* The node's class must carry `@MapsTo(<this>)`. NULL = unset. */
  const char *maps_to;
  /* The node's class must carry `@DetailedIn(<this>)`. NULL = unset. */
  const char *detailed_in;
  /* The node's value-presence state must match `state`; 0 = unset. */
  int has_state;
  SpecStateFilter state;
} SpecQuery;

/* Clears `*q` to the all-unset query. */
void spec_query_init(SpecQuery *q);

/* ---- engine + cursor ----------------------------------------------------- */

/* Runs queries over a (model, document) pair, producing cursors. Borrows both. */
typedef struct {
  const SpecModel *model;
  const SpecDocument *document;
  SpecReflection reflection;
} SpecQueryEngine;

SpecQueryEngine spec_query_engine_make(const SpecModel *model,
                                       const SpecDocument *document);

/* A lazy, forward-only cursor over the nodes matching a `SpecQuery`.
 *
 * The cursor holds the structural candidate paths captured when it was created;
 * each step re-validates the path against the **live** document and re-applies
 * the value-dependent filters, so concurrent edits never surface stale or
 * newly-mismatching results. It is forward-only: next / take consume matches;
 * count peeks the remaining matches without consuming. Treat the fields as
 * private. */
typedef struct {
  const SpecQueryEngine *engine; /* borrowed */
  SpecQuery query;               /* copied; its strings stay borrowed */
  SomTextPattern pattern;        /* owned; valid only when `has_pattern` */
  int has_pattern;
  SomStrList candidate_paths;    /* owned */
  size_t position;
} SpecQueryCursor;

/* Builds a cursor over the nodes matching `*q`. The structural candidate set is
 * computed now (document order); value-dependent filters and path liveness are
 * re-checked as the cursor advances.
 *
 * Returns 0 (filling `*err` when non-NULL, leaving `*out` untouched) when
 * `q->regex` is set and `q->text` is not in the portable subset. The pattern is
 * compiled **here**, not on first use, for two reasons: a malformed pattern is
 * the caller's mistake and should surface at the call that made it, and a
 * cursor that happens to visit no candidate would otherwise swallow the error
 * entirely. */
int spec_query_engine_query(const SpecQueryEngine *e, const SpecQuery *q,
                            SpecQueryCursor *out, SomPatternError *err);

/* Releases a cursor's owned state. Safe on a zeroed struct. */
void spec_query_cursor_free(SpecQueryCursor *c);

/* The next matching node: returns 1 and fills `*out` (free with
 * `spec_query_match_free`), or 0 when the cursor is exhausted. Skips candidates
 * whose path went stale or no longer satisfies the live filters. */
int spec_query_cursor_next(SpecQueryCursor *c, SpecQueryMatch *out);

/* Up to `n` further matches (fewer when the cursor is exhausted first),
 * appended to `out` (initialised by the caller). */
void spec_query_cursor_take(SpecQueryCursor *c, size_t n,
                            SpecQueryMatchList *out);

/* Every remaining match, draining the cursor, appended to `out`. */
void spec_query_cursor_to_list(SpecQueryCursor *c, SpecQueryMatchList *out);

/* How many matches remain from the current position, without consuming any.
 * Re-validates each remaining candidate against the live document, so the count
 * reflects the document as it is *now*. */
size_t spec_query_cursor_count(const SpecQueryCursor *c);

/* ---- flat node projection ------------------------------------------------ */

/* Projects every indexable node of the live document (the structural closure)
 * in document order into `out` (initialised by the callee, freed with
 * `spec_node_projection_list_free`). Reuses the same walk and value extraction
 * the query uses, so the index built from these projections and the live search
 * agree on what a node is and what text it carries. */
void spec_query_engine_project_nodes(const SpecQueryEngine *e,
                                     SpecNodeProjectionList *out);

/* Projects the single node at `path`: returns 1 and fills `*out`, or 0 when the
 * path no longer resolves against the model. Used for the index's incremental
 * refresh: a caller re-projects only the changed section paths. */
int spec_query_engine_project_node(const SpecQueryEngine *e, const char *path,
                                   SpecNodeProjection *out);

#endif /* SPEC_QUERY_H */
