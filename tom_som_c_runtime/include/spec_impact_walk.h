/* spec_impact_walk — the impact walk, the starting table of a change's impact
 * evaluation (the change mode of the `tom_specs` process, Phase 0 step
 * `impact`). A faithful port of the TypeScript `spec_impact_walk.ts` (and the
 * Dart `spec_impact_walk.dart`).
 *
 * For a specification it lists **every** section of **every** document root of
 * the model, filled or not, and roots the project never created as well: each
 * row with its section-id chain, its model class, whether it holds values, and
 * its CodeSpecs routing. The change analyst gives each row a verdict
 * (*affected*, *needed*, *unaffected*); a table built from the model rather
 * than from the document is what makes "nothing the SOM covers is missed"
 * checkable. Beside it, `spec_impact_level` records how far the project has
 * come (documents, extracts, IR, tests, code).
 *
 * Rows: one per class node (the root, each `complex` / `section` field, each
 * list item) and one per list (with its item count). An empty list of a class
 * element gets one **template** row `<list>/ *` (no space) with the element's
 * subtree below it, so a section a new item would need shows its routing too.
 * Value leaves (content, form fields) are counted in their row, not rows of
 * their own. A class already on the branch is not entered again (the model is
 * a graph), exactly as the CodeSpecs routing walk cuts recursion. Below a
 * `@FollowUpKind` section every row carries that routing: the whole subtree is
 * delivered by the process, as the CodeSpecs extractor treats it.
 *
 * Pure: it reads a model and documents and writes nothing. Pinned by
 * `tom_som_conformance/corpus/impact_walk_cases.json`.
 *
 * Ownership: every result type owns all of its strings and arrays —
 * `SpecImpactWalk` (release with `spec_impact_walk_free`), `SpecImpactLevel`
 * (`spec_impact_level_free`), `SpecImpactFolderList` built by the caller
 * (`spec_impact_folder_list_free`). The model and documents passed in are
 * borrowed and only read; the results keep no pointer into them. Every
 * `char *` a function returns is owned by the caller (`free`); every
 * `SomStrList` it writes is initialised by the callee and owned by the caller
 * (`som_strlist_free`).
 */
#ifndef SPEC_IMPACT_WALK_H
#define SPEC_IMPACT_WALK_H

#include <stddef.h>

#include "som_util.h"
#include "spec_codespecs_extract.h"
#include "spec_document.h"
#include "spec_model.h"

/* ---- the walk ------------------------------------------------------------ */

/* What a row of the walk stands for. */
typedef enum {
  /* The document root. */
  SPEC_IMPACT_ROW_ROOT = 0,
  /* A `complex` field's class node. */
  SPEC_IMPACT_ROW_COMPLEX = 1,
  /* A `section` field's class node. */
  SPEC_IMPACT_ROW_SECTION = 2,
  /* A list field (its items are rows of their own). */
  SPEC_IMPACT_ROW_LIST = 3,
  /* One item of a list of class elements. */
  SPEC_IMPACT_ROW_ITEM = 4,
  /* The element class of an empty list, at `<list>/ *` (no space): what a
   * new item holds. */
  SPEC_IMPACT_ROW_TEMPLATE = 5,
} SpecImpactRowKind;

/* The kind's name as every port spells it (`"root"`, `"complex"`, `"section"`,
 * `"list"`, `"item"`, `"template"`), a static literal. */
const char *spec_impact_row_kind_name(SpecImpactRowKind kind);

/* One row of the impact walk. Owns its strings. */
typedef struct {
  /* The document path; a template's subtree has `*` for the item segment. */
  char *path;
  /* The section-id chain, outer first, joined by ` > ` (a list item by its
   * stored id). */
  char *chain;
  SpecImpactRowKind kind;
  /* The model class; for a list, its element class ("" for a list of
   * scalars). */
  char *class_name;
  /* Nesting below the root (the root is 0). */
  long long depth;
  /* Whether the document holds anything at or below the path
   * (`spec_document_has_values_under`); 0 for template rows. */
  int filled;
  /* Stored values at or below the path: content leaves plus form-field
   * values. */
  long long values;
  /* A list's item count (`has_items` 1); `has_items` is 0 for every other
   * row (the TS `null`). */
  int has_items;
  long long items;
  /* The CodeSpecs routing verdict: of the class (a class row), of the element
   * class (a list of classes), or of the field, else its enclosing class (a
   * list of scalars). Below a `feedsProcess` section, that section's routing.
   * `spec_codespecs_verdict_name` spells it. */
  CodeSpecsRoutingVerdict routing;
  /* The routing's values verbatim (`CodeSpecPart` / `FollowUpProcess` /
   * `NoArtifactReason` names). Owned. */
  SomStrList routing_values;
  /* Where the routing marker is declared (`Class` or `Class.field`); "" when
   * none. */
  char *routing_declared_at;
} SpecImpactRow;

/* The walk of one document root. Owns its strings and rows. */
typedef struct {
  /* The root's model type, e.g. `D00SolutionBlueprint`. */
  char *type;
  /* The root's section id (its first path segment). */
  char *section_id;
  /* Whether the specification has this document; an absent root is walked
   * over an empty document. */
  int present;
  SpecImpactRow *rows;
  size_t rows_len;
  size_t rows_cap;
} SpecImpactRootWalk;

/* The walk of every document root of a model, in model order. A zeroed walk
 * is empty. Owns its roots. */
typedef struct {
  SpecImpactRootWalk *roots;
  size_t roots_len;
} SpecImpactWalk;

/* Frees everything `*w` owns and leaves it empty. Safe on a zeroed walk. */
void spec_impact_walk_free(SpecImpactWalk *w);

/* Walks every document root of `model`, in model order, into `*out`
 * (initialised by the callee): a root whose type is among `types` over the
 * matching document of `documents` (parallel arrays of `documents_len`
 * entries, both borrowed), any other over an empty document. Returns 1 on
 * success. A document keyed by a type the model has no root for is refused:
 * returns 0, leaves `*out` empty and, when `err` is non-NULL, writes an owned
 * message (`spec_impact_walk: the model has no document root <type>`). */
int spec_impact_walk(const SpecModel *model, const char *const *types,
                     const SpecDocument *const *documents, size_t documents_len,
                     SpecImpactWalk *out, char **err);

/* The walk as JSON text — an array of `{type, sectionId, present, rows}`, each
 * row `{path, chain, kind, className, depth, filled, values, items, routing,
 * routingValues, routingDeclaredAt}` (the TS `toJson`, keys in that order).
 * Owned result. */
char *spec_impact_walk_to_json(const SpecImpactWalk *w);

/* ---- the project's level -------------------------------------------------- */

/* A folder the caller passed for tests or code, and whether it exists. Owns
 * `path`. */
typedef struct {
  char *path;
  int present;
} SpecImpactFolder;

/* An owning list of folders. A zeroed list is empty. */
typedef struct {
  SpecImpactFolder *items;
  size_t len;
  size_t cap;
} SpecImpactFolderList;

void spec_impact_folder_list_init(SpecImpactFolderList *l);
/* Appends a copy of `path`. */
void spec_impact_folder_list_push(SpecImpactFolderList *l, const char *path,
                                  int present);
void spec_impact_folder_list_free(SpecImpactFolderList *l);

/* One document root of the level: whether the specification has it. Owns its
 * strings. */
typedef struct {
  char *type;
  char *section_id;
  int present;
} SpecImpactLevelDocument;

/* How far the project has come (impact_evaluation.md § Level). Owns
 * everything it holds. */
typedef struct {
  /* Every document root: whether the specification has it. */
  SpecImpactLevelDocument *documents;
  size_t documents_len;
  /* `phase1_project_idea/` holds a Markdown file. */
  int project_idea;
  /* `CE-*.extract.yaml` files in `generated-doc/codespecs_extracts/`. */
  long long extracts;
  /* `generated-doc/codespecs_extracts/gate.verdicts.yaml` exists. */
  int gate_record;
  /* `*.ir.yaml` files in `irspecs/`. */
  long long ir;
  /* Gate checklists and reports under `gates/` and
   * `quality/evidence/gates/`, sorted. */
  SomStrList gates;
  /* The test folders the caller passed; `has_tests` 0: none given (the TS
   * `null`). */
  int has_tests;
  SpecImpactFolderList tests;
  /* The code folders the caller passed; `has_code` 0: none given. */
  int has_code;
  SpecImpactFolderList code;
  /* The phases (1–6) the project has reached, ascending. */
  int phases_reached[6];
  size_t phases_reached_len;
  /* The phases (1–6) it has not, which a change leaves out (they run later
   * in initial mode), ascending. */
  int phases_left_out[6];
  size_t phases_left_out_len;
} SpecImpactLevel;

/* Frees everything `*l` owns and leaves it zeroed. */
void spec_impact_level_free(SpecImpactLevel *l);

/* The project's level from the walk and a listing of the spec root (paths
 * relative to it, `/`-separated; `\` is read as `/` and a leading `./` is
 * dropped), written into `*out` (initialised by the callee). `tests` / `code`
 * are the folders the caller passed (copied), NULL when none were given.
 * Phase 2 is reached when the root with section id `SBP` is present, Phase 3
 * when any other root is that is not a generation input, Phase 4 when
 * extracts or IR exist, Phases 5 and 6 when a test or code folder the caller
 * passed exists. Phases 7–8 (acceptance, deployment) are not visible on disk
 * and are not reported. */
void spec_impact_level(const SpecModel *model, const SpecImpactWalk *walk,
                       const SomStrList *listing,
                       const SpecImpactFolderList *tests,
                       const SpecImpactFolderList *code, SpecImpactLevel *out);

/* The level as JSON text — `{documents, projectIdea, extracts, gateRecord, ir,
 * gates, tests, code, phasesReached, phasesLeftOut}` (the TS `toJson`; `tests`
 * / `code` are `null` when none were given). Owned result. */
char *spec_impact_level_to_json(const SpecImpactLevel *l);

/* The specification's current documents in a listing of the spec root: the
 * `*.tomspecs.yaml` files directly in a `phase*` folder, sorted. The numbered
 * step folders below hold round copies and are not the specification. Writes
 * into `out` (initialised by the callee). */
void spec_impact_document_files(const SomStrList *listing, SomStrList *out);

/* ---- the Markdown table --------------------------------------------------- */

/* The walk as Markdown, for a round folder's `walk/` (one table per root,
 * then § Level when `level` is non-NULL): the table the change analyst gives
 * verdicts to. Owned result. */
char *spec_impact_walk_markdown(const SpecImpactWalk *walk,
                                const SpecImpactLevel *level);

#endif /* SPEC_IMPACT_WALK_H */
