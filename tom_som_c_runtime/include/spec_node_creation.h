/* spec_node_creation — meta-model-validated node creation for a live
 * SpecDocument (llm_and_d4rt_tools.md §5 "constrained node creation"), a
 * faithful port of the Dart `spec_node_creation.dart`.
 *
 * Every node a script or tool adds passes through this single gate, so the
 * document can only grow in ways the SpecModel permits for the parent. The
 * rules are the `tom_specs_model_rules.md` §10.2 *structural* rules — but read
 * from the model meta-data the runtime already carries (`SpecField.kind`,
 * `SpecField.section_id_pattern`), **not** from the analyzer-backed authoring
 * validator in `tom_specs_clitool`. The clitool validates the *authored model
 * graph*; this validates a *document mutation against that model*.
 *
 * `spec_check_add_node` is the single, value-aware rule-check entry point
 * (exported for reuse by editors and the engine); `spec_node_creator_add`
 * applies it and performs the mutation only when it reports OK, so an illegal
 * add never touches the tree.
 *
 * Error idiom: the gate has no exceptions to raise, so it fills a caller-owned
 * `SpecCreationError` whose `SPEC_CREATION_OK` code is the C stand-in for the
 * Dart `null` return — the same OK-sentinel shape `SpecSectionIdError` uses.
 * `spec_node_creator_add` returns 1/0 alongside it, matching the rest of the
 * runtime's fallible calls.
 *
 * Ownership: a creator borrows its model and document; both must outlive it. It
 * owns nothing, so there is no `spec_node_creator_free`. A `SpecCreationError`
 * owns its strings (`spec_creation_error_free`), and the path written to
 * `*out_path` is owned by the caller (`free`).
 */
#ifndef SPEC_NODE_CREATION_H
#define SPEC_NODE_CREATION_H

#include "spec_document.h"
#include "spec_model.h"
#include "spec_reflection.h"

/* Why an attempted node creation is illegal against the model. */
typedef enum {
  /* The add is legal — the Dart port's `null`. */
  SPEC_CREATION_OK = 0,
  /* The parent path does not resolve to a node that can own named children (it
   * is dangling, a leaf, or a list — lists grow through their own field, not by
   * adding children to the list node). */
  SPEC_CREATION_NOT_A_CONTAINER = 1,
  /* The requested child segment names no field on the parent's class. */
  SPEC_CREATION_UNKNOWN_CHILD = 2,
  /* A caller-proposed list-item id does not keep the prefix mandated by the
   * list's `@SectionIdPattern` (AA1 criterion 3/5: an override replaces the
   * suffix, the pattern prefix stays). */
  SPEC_CREATION_PATTERN_MISMATCH = 3,
  /* A caller-proposed list-item id collides with another item's section id in
   * the same list (AA1 criterion 5: ids within a list must be unique). */
  SPEC_CREATION_DUPLICATE_SECTION_ID = 4,
  /* A single-valued (non-list) child already holds a value — only one is
   * allowed. */
  SPEC_CREATION_CARDINALITY_EXCEEDED = 5,
} SpecCreationCode;

/* The code's name as the other eight ports spell it (`"notAContainer"`, …), a
 * static literal; `""` for `SPEC_CREATION_OK`. */
const char *spec_creation_code_name(SpecCreationCode code);

/* Every rejection code, in declaration order (`SPEC_CREATION_OK` excluded — it
 * is not a rejection) — lets a conformance replay assert that a table exercises
 * the whole set rather than a convenient subset. */
#define SPEC_CREATION_ALL_CODES_COUNT 5
extern const SpecCreationCode SPEC_CREATION_ALL_CODES[SPEC_CREATION_ALL_CODES_COUNT];

/* A rejected node-creation attempt. Owns its strings; initialise with
 * `spec_creation_error_init` and release with `spec_creation_error_free`. */
typedef struct {
  SpecCreationCode code;
  char *parent_path;   /* the parent path the add was attempted under */
  char *child_segment; /* the child section segment that was requested */
  char *message;       /* a human-readable explanation */
} SpecCreationError;

/* Resets `*e` to OK with all fields NULL (does not free — free first if the
 * struct already owns strings). */
void spec_creation_error_init(SpecCreationError *e);
/* Frees the owned strings of `*e` and resets it to OK/NULL. Safe when OK. */
void spec_creation_error_free(SpecCreationError *e);
/* Reports whether `e` records a legal add. */
int spec_creation_error_is_ok(const SpecCreationError *e);
/* `SpecCreationError(<code>) under "<parent>" → "<child>": <message>` — the
 * Dart `toString`. Owned result. */
char *spec_creation_error_string(const SpecCreationError *e);

/* Validates adding child `child_segment` under `parent_path` against `model`,
 * consulting `document` for cardinality. Writes `SPEC_CREATION_OK` to `*out`
 * when the add is legal, otherwise the first rule it breaks. `item_id` is the
 * caller-proposed list-item id (NULL when none).
 *
 * Performs **no mutation**; it is the shared rule-check `spec_node_creator_add`
 * (and any editor) calls before touching the tree. `*out` is initialised by the
 * callee; the caller releases it with `spec_creation_error_free`. */
void spec_check_add_node(const SpecModel *model, const SpecDocument *document,
                         const char *parent_path, const char *child_segment,
                         const char *item_id, SpecCreationError *out);

/* Applies `spec_check_add_node` and performs the constrained mutation. Holds
 * the (model, document) pair so callers add children by parent path and child
 * segment without re-supplying the context each time. */
typedef struct {
  const SpecModel *model;
  SpecDocument *document; /* borrowed */
} SpecNodeCreator;

SpecNodeCreator spec_node_creator_make(const SpecModel *model,
                                       SpecDocument *document);

/* Adds child `child_segment` under `parent_path` and writes the new node's path
 * (owned; caller frees) to `*out_path`.
 *
 * For a list field this appends a fresh item (`…/<segment>-<seq>`), assigning
 * its **section id** (AA1 criteria 3–5): `item_id` if given (override),
 * otherwise one generated from the field's `@SectionIdPattern` using
 * `month`/`day` for the two-letter-date component — pass a non-positive
 * `month` or `day` for today, the same idiom `spec_editor_add_list_item` uses.
 * Lists with no pattern (scalar lists) get no section id. For a single-valued
 * field the child path is returned without mutating the sparse store (the
 * caller then sets its value).
 *
 * Returns 1 on success. Returns 0 — leaving the document untouched — when the
 * add violates a structural rule, filling `*err` when `err` is non-NULL. */
int spec_node_creator_add(SpecNodeCreator *c, const char *parent_path,
                          const char *child_segment, const char *item_id,
                          long long month, long long day, char **out_path,
                          SpecCreationError *err);

#endif /* SPEC_NODE_CREATION_H */
