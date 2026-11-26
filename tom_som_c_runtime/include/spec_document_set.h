/* spec_document_set — a project's specification documents read side by side,
 * one per root, and the validation of the set (`tom_specs_model_rules.md`
 * §9.7): the places a Phase 3 document shares with the Solution Blueprint
 * agree, element by element and value by value, and the links that cross two
 * documents hold.
 *
 * The documents are never assembled into one: each keeps its own registry,
 * and every finding names the document a place is in. `spec_sync_report`
 * writes nothing; `spec_rename_id` renames an id in every document at once.
 *
 * A port of `tom_som_dart_runtime/lib/src/spec_document_set.dart` (and the Go
 * `spec_document_set.go` / Rust `spec_document_set.rs`). The comparison
 * internals `spec_backfill` and `spec_prefill` read are private
 * (`src/spec_document_set_internal.h`).
 *
 * Ownership: the set owns a copy of every document it is given; every struct
 * owns its strings; release with its `*_free` (safe on a zeroed struct). The
 * `*_to_json` functions return owned JSON text. */
#ifndef SPEC_DOCUMENT_SET_H
#define SPEC_DOCUMENT_SET_H

#include <stddef.h>

#include "som_util.h"
#include "spec_document.h"
#include "spec_model.h"
#include "spec_validator.h"

/* ---- the vocabulary of the set ------------------------------------------- */

/* What a finding of the set reports, in the order the report sorts by (the
 * corpus compares the names). */
typedef enum {
  /* Both documents hold the shared place, and the values differ. */
  SPEC_SYNC_CODE_SHARED_VALUE_DIFFERS = 0,
  /* The Phase 3 document fills a shared place the Blueprint leaves empty. */
  SPEC_SYNC_CODE_SHARED_VALUE_MISSING,
  /* The Blueprint fills a shared place the Phase 3 document leaves empty; the
   * Phase 3 document emptied it, so `backfill` clears it. */
  SPEC_SYNC_CODE_SHARED_VALUE_ONLY_IN_BLUEPRINT,
  /* An element of an `equal` list (or an id of an `equal` reference field) is
   * only in the Phase 3 document. */
  SPEC_SYNC_CODE_SHARED_ELEMENT_MISSING,
  /* An element (or id) is only in the Blueprint, under `equal` or `subset`;
   * `backfill` removes it. */
  SPEC_SYNC_CODE_SHARED_ELEMENT_ONLY_IN_BLUEPRINT,
  /* Under `subset`, an element (or id) only in the Phase 3 document: it may be
   * added to the Blueprint, and is not carried in. */
  SPEC_SYNC_CODE_SHARED_ELEMENT_MAY_BE_ADDED,
  /* A `@SummaryOf(document:)` whose summary and detail sit in two documents
   * does not hold. */
  SPEC_SYNC_CODE_CROSS_SUMMARY_MISMATCH,
  /* An `inverseOf` whose two ends sit in two documents is one-sided. */
  SPEC_SYNC_CODE_CROSS_INVERSE_MISSING,
  /* A value holding pending change marks, listed for the user. */
  SPEC_SYNC_CODE_PENDING_REVIEW,
  /* A change `deriveFields` would write in a document under review that
   * cannot be marked exactly. */
  SPEC_SYNC_CODE_UNMARKABLE
} SpecSyncCode;

#define SPEC_SYNC_CODE_COUNT 10

/* The code's name as the corpus writes it (`sharedValueDiffers`, ...). */
const char *spec_sync_code_name(SpecSyncCode code);
/* The code named `name`: 1 and `*out`, or 0 for an unknown name. */
int spec_sync_code_from_name(const char *name, SpecSyncCode *out);

/* How a finding of the set is resolved. */
typedef enum {
  /* `backfill` resolves it, writing the Blueprint. */
  SPEC_SYNC_RESOLUTION_BACKFILL = 0,
  /* `deriveFields` resolves it. */
  SPEC_SYNC_RESOLUTION_DERIVE_FIELDS,
  /* The agent decides (or asks the user). */
  SPEC_SYNC_RESOLUTION_AGENT,
  /* Reported, not a finding: it does not hold up a gate. */
  SPEC_SYNC_RESOLUTION_INFO
} SpecSyncResolution;

#define SPEC_SYNC_RESOLUTION_COUNT 4

const char *spec_sync_resolution_name(SpecSyncResolution r);

/* Which document holds a shared place's value. */
typedef enum {
  /* The Phase 3 document (the default). */
  SPEC_SYNC_HOLDER_DETAIL = 0,
  /* The Blueprint (`@SyncedWith(heldHere:)`). */
  SPEC_SYNC_HOLDER_BLUEPRINT
} SpecSyncHolder;

const char *spec_sync_holder_name(SpecSyncHolder h);

/* Why a document set cannot be built. */
typedef enum {
  /* Two documents populate one root. */
  SPEC_DOCUMENT_SET_REFUSAL_SAME_ROOT = 0,
  /* A document populates no root. */
  SPEC_DOCUMENT_SET_REFUSAL_NO_ROOT,
  /* A document populates two roots. */
  SPEC_DOCUMENT_SET_REFUSAL_TWO_ROOTS,
  /* A document is the CodeSpecs projection, which is no specification. */
  SPEC_DOCUMENT_SET_REFUSAL_PROJECTION,
  /* Fragments of one root overlap. */
  SPEC_DOCUMENT_SET_REFUSAL_OVERLAP,
  /* A synced class's positions in the Blueprint and its document cannot be
   * paired (invariant `SHARED-ANCHOR`). */
  SPEC_DOCUMENT_SET_REFUSAL_UNPAIRABLE
} SpecDocumentSetRefusal;

/* The refusal's name as the corpus writes it (`sameRoot`, `noRoot`,
 * `twoRoots`, `projection`, `overlap`, `unpairable`). */
const char *spec_document_set_refusal_name(SpecDocumentSetRefusal r);

/* A document set that cannot be built, with the documents it names. */
typedef struct {
  SpecDocumentSetRefusal refusal;
  /* The documents (or fragments) concerned, in the order given. */
  SomStrList documents;
  /* The prose for the reader. */
  char *message;
  /* For SPEC_DOCUMENT_SET_REFUSAL_UNPAIRABLE, the class; "" else. */
  char *class_name;
} SpecDocumentSetError;

void spec_document_set_error_init(SpecDocumentSetError *e);
void spec_document_set_error_free(SpecDocumentSetError *e);
/* The canonical JSON form the corpus compares (no message). */
char *spec_document_set_error_to_json(const SpecDocumentSetError *e);
/* `SpecDocumentSetError(<refusal>): <message>`. Owned. */
char *spec_document_set_error_display(const SpecDocumentSetError *e);

/* Why `spec_document_set_load` cannot load its files. */
typedef enum {
  SPEC_DOCUMENT_SET_LOAD_OK = 0,
  /* A file cannot be read. */
  SPEC_DOCUMENT_SET_LOAD_READ,
  /* A YAML file does not decode. */
  SPEC_DOCUMENT_SET_LOAD_DECODE,
  /* The documents do not make a set (`set` holds why). */
  SPEC_DOCUMENT_SET_LOAD_SET
} SpecDocumentSetLoadErrorKind;

typedef struct {
  SpecDocumentSetLoadErrorKind kind;
  char *file;    /* READ / DECODE: the file */
  char *message; /* READ / DECODE: why */
  SpecDocumentSetError set; /* SET */
} SpecDocumentSetLoadError;

void spec_document_set_load_error_init(SpecDocumentSetLoadError *e);
void spec_document_set_load_error_free(SpecDocumentSetLoadError *e);

/* A class kept in sync between the Blueprint and a Phase 3 document: its
 * position in each root. */
typedef struct {
  /* The class carrying `@SyncedWith` / `@DetailedIn`. */
  char *class_name;
  /* Its section id: the name of the pair in findings and filters. */
  char *section_id;
  /* The anchor in the Blueprint root (list items written `<list>-*`). */
  char *blueprint_anchor;
  /* The anchor in the Phase 3 root. */
  char *detail_anchor;
  /* The Phase 3 root's class name. */
  char *detail_root;
  /* The class's `@SyncedWith`; `has_sync` 0 when only `@DetailedIn` is
   * declared. */
  int has_sync;
  SpecSync sync;
} SpecSyncPair;

void spec_sync_pair_free(SpecSyncPair *p);
/* `{pair, className, blueprint, detail, detailRoot}`. Owned. */
char *spec_sync_pair_to_json(const SpecSyncPair *p);

/* ---- the set --------------------------------------------------------------- */

/* A document of the set, or a fragment given to it: a name and a document,
 * both borrowed for the call. */
typedef struct {
  const char *name;
  const SpecDocument *document;
} SpecNamedDocument;

/* One document the set holds. */
typedef struct {
  char *name;           /* the file name the tools use */
  char *root;           /* its root's class name */
  SpecDocument *document; /* owned heap document */
} SpecDocumentSetEntry;

/* A project's specification documents, one per root, read side by side. */
typedef struct {
  /* The model the set is read with (borrowed). */
  const SpecModel *model;
  /* The Blueprint's root class name: the root the others are `basedOn`; ""
   * when the model names none. */
  char *blueprint_root;
  /* The documents, in the order they were given. */
  SpecDocumentSetEntry *entries;
  size_t entries_len;
  size_t entries_cap;
  /* The anchor pairs, in the Blueprint's walk order. */
  SpecSyncPair *pairs;
  size_t pairs_len;
} SpecDocumentSet;

/* A set of `documents` (each copied), named by the file name the tools use.
 * Each document populates exactly one root; two documents of one root, a
 * document with no populated root or with two, and the CodeSpecs projection
 * are refused, as is a model whose synced positions cannot be paired: 0, with
 * `*err` filled (when non-NULL) and `*out` left empty (owning nothing, so
 * freeing it is a no-op). 1 on success. */
int spec_document_set_new(const SpecModel *model,
                          const SpecNamedDocument *documents, size_t len,
                          SpecDocumentSet *out, SpecDocumentSetError *err);

/* A set from documents and fragments: those of one root are fragments of one
 * document, assembled in the order given (overlaps refused), the document
 * named by its first fragment's name. */
int spec_document_set_from_fragments(const SpecModel *model,
                                     const SpecNamedDocument *fragments,
                                     size_t len, SpecDocumentSet *out,
                                     SpecDocumentSetError *err);

/* Loads YAML or SOM Markdown files; files of one root are fragments and are
 * assembled first (refusing overlaps). Each document is named by its first
 * file's name. 0 with `*err` filled when a file cannot be read or decoded or
 * the documents make no set. */
int spec_document_set_load(const SpecModel *model, const char *const *files,
                           size_t len, SpecDocumentSet *out,
                           SpecDocumentSetLoadError *err);

void spec_document_set_free(SpecDocumentSet *set);

/* The Blueprint document, or NULL. */
const SpecDocument *spec_document_set_blueprint(const SpecDocumentSet *set);
/* The document of `root_type` (a type name or a section id), or NULL. */
const SpecDocument *spec_document_set_document(const SpecDocumentSet *set,
                                               const char *root_type);
/* The name of the document of `root_type` (a type name or a section id), NULL
 * when the set has none. Borrowed. */
const char *spec_document_set_name_of(const SpecDocumentSet *set,
                                      const char *root_type);
/* The populated roots, in model order. `*out` initialised by the callee. */
void spec_document_set_roots(const SpecDocumentSet *set, SomStrList *out);
/* The document names, in model order of their roots. */
void spec_document_set_names(const SpecDocumentSet *set, SomStrList *out);
/* Every Phase 3 root a pair names with no document yet: its pairs are "not
 * started", reported as such and never as findings. */
void spec_document_set_missing_roots(const SpecDocumentSet *set,
                                     SomStrList *out);
/* Adds or replaces a document (copied; what `prefill` creates); refused like
 * the documents `spec_document_set_new` takes (0, `*err` filled). */
int spec_document_set_put(SpecDocumentSet *set, const char *name,
                          const SpecDocument *document,
                          SpecDocumentSetError *err);
/* The document named `name`, or NULL. */
const SpecDocument *spec_document_set_get(const SpecDocumentSet *set,
                                          const char *name);
/* The document named `name` to write, or NULL. */
SpecDocument *spec_document_set_get_mut(SpecDocumentSet *set,
                                        const char *name);
/* The root class name of the document named `name`, "" when the set has none
 * of that name. Borrowed. */
const char *spec_document_set_root_of(const SpecDocumentSet *set,
                                      const char *name);

/* ---- findings and the report ----------------------------------------------- */

/* One side of a finding: where the place is and what it holds. */
typedef struct {
  /* The document's name, NULL when the set has none for this side. */
  char *document;
  /* The root's section id. */
  char *root;
  /* The document path (for a place the document does not hold, the nearest
   * path it does: the list an element would be added to). */
  char *path;
  /* The form field, "" for none. */
  char *field;
  /* The value (read with pending marks rejected), NULL when absent. */
  char *value;
  /* Whether the value holds pending change marks. */
  int pending_marks;
} SpecSyncPlace;

void spec_sync_place_free(SpecSyncPlace *p);
void spec_sync_place_copy(SpecSyncPlace *dst, const SpecSyncPlace *src);
/* The value, "" when absent. Borrowed. */
const char *spec_sync_place_value_or(const SpecSyncPlace *p);
char *spec_sync_place_to_json(const SpecSyncPlace *p);

/* One finding of the set. */
typedef struct {
  SpecSyncCode code;
  /* The pair's section id (the summary's or link's class for a cross check,
   * empty for a pending value outside every pair). */
  char *pair;
  /* The Blueprint side (for a cross check, the side holding the link). */
  SpecSyncPlace blueprint;
  /* The Phase 3 side (for a cross check, the other end). */
  SpecSyncPlace detail;
  SpecSyncHolder holder;
  SpecSyncResolution resolution;
  /* Prose for the agent, in the canonical form every runtime writes. */
  char *message;
} SpecSyncFinding;

void spec_sync_finding_free(SpecSyncFinding *f);
void spec_sync_finding_copy(SpecSyncFinding *dst, const SpecSyncFinding *src);
/* Whether it is reported only, not a finding. */
int spec_sync_finding_is_info(const SpecSyncFinding *f);
char *spec_sync_finding_to_json(const SpecSyncFinding *f);

/* One document's own findings in a report. */
typedef struct {
  char *name;
  /* `validate_document`, then `spec_validate_links`. */
  SpecValidationErrors errors;
} SpecDocumentFindings;

/* The validation of a document set. */
typedef struct {
  /* The findings in pair and path order, `info` entries included. */
  SpecSyncFinding *findings;
  size_t findings_len;
  /* Each document's own findings, in the set's order. */
  SpecDocumentFindings *document_findings;
  size_t document_findings_len;
  /* The Phase 3 roots with no document yet. */
  SomStrList not_started;
  /* The pairs (by section id) whose Phase 3 document exists but holds nothing
   * beneath the pair's anchor: not started, like a missing document. */
  SomStrList not_started_pairs;
} SpecSyncReport;

void spec_sync_report_free(SpecSyncReport *r);
/* The findings per code, `info` entries included, indexed by the code. */
void spec_sync_report_counts_by_code(const SpecSyncReport *r,
                                     size_t counts[SPEC_SYNC_CODE_COUNT]);
/* The findings per resolution, indexed by the resolution. */
void spec_sync_report_counts_by_resolution(
    const SpecSyncReport *r, size_t counts[SPEC_SYNC_RESOLUTION_COUNT]);
/* Whether there is no finding other than `info`. */
int spec_sync_report_clean(const SpecSyncReport *r);
/* The counts as the canonical `[[code, count], ...]` form, codes without
 * findings left out. Owned. */
char *spec_sync_report_counts_by_code_json(const SpecSyncReport *r);
char *spec_sync_report_counts_by_resolution_json(const SpecSyncReport *r);
/* The canonical JSON form; every ordered value is a list. Owned. */
char *spec_sync_report_to_json(const SpecSyncReport *r);

/* The validation of `set`, with counts; `pairs` (non-NULL) keeps the findings
 * of those pairs (by section id) only. Writes nothing. `*out` initialised by
 * the callee. */
void spec_sync_report(const SpecDocumentSet *set, const SomStrList *pairs,
                      SpecSyncReport *out);

/* ---- the comparison helpers -------------------------------------------------- */

/* `raw` with every pending mark rejected, trimmed. Owned. */
char *spec_set_reviewed(const char *raw);
/* Whether `raw` holds pending change marks. */
int spec_set_is_pending(const char *raw);
/* Whether `a` and `b` are the same value of the field's type (`spec` NULL:
 * text). */
int spec_set_same_typed(const char *a, const char *b,
                        const FormFieldSpec *spec);
/* A value key (`c:` / `f:` / `h:` / `i:`) without its kind and field. Owned. */
char *spec_set_strip_kind(const char *key);

/* ---- the global rename ---------------------------------------------------------- */

/* Why `spec_rename_id` refuses. */
typedef struct {
  /* The documents already holding the new id. */
  SomStrList documents;
  char *message;
} SpecRenameError;

void spec_rename_error_init(SpecRenameError *e);
void spec_rename_error_free(SpecRenameError *e);
/* `SpecRenameError: <message>`. Owned. */
char *spec_rename_error_display(const SpecRenameError *e);

/* One value `spec_rename_id` changed. */
typedef struct {
  char *document;
  /* A list item (its section id) or the value's path. */
  char *path;
  /* `sectionId` or `value` (a form field or content); static. */
  const char *kind;
  char *old_value;
  char *new_value;
  /* The form field, "" for none. */
  char *field;
} SpecRenameChange;

typedef struct {
  SpecRenameChange *items;
  size_t len;
  size_t cap;
} SpecRenameChanges;

void spec_rename_changes_free(SpecRenameChanges *c);
char *spec_rename_change_to_json(const SpecRenameChange *c);

/* Renames the section id `from` to `to` in every document of `set` at once:
 * the list element carrying it, and every value naming it as a whole token
 * (no letter, digit or hyphen on either side). Refused (0, `*err` filled,
 * nothing changed) when an element of any document already carries `to`.
 * Returns 1 with the changes, in document and path order, in `*out`
 * (initialised by the callee in every case). */
int spec_rename_id(SpecDocumentSet *set, const char *from, const char *to,
                   SpecRenameChanges *out, SpecRenameError *err);

/* ---- small shared writers --------------------------------------------------- */

/* `errors` as `[{path, code, message}]`. Owned. */
char *spec_validation_errors_json(const SpecValidationErrors *errors);
/* The document's stores as canonical JSON (the shape the corpus compares).
 * Owned. */
char *spec_document_stores_json(const SpecDocument *doc);
/* `dst` (uninitialised) becomes a deep copy of `src`. */
void spec_document_copy(SpecDocument *dst, const SpecDocument *src);

#endif /* SPEC_DOCUMENT_SET_H */
