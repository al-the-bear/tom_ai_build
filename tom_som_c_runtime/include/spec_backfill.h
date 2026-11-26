/* spec_backfill — `spec_backfill`: the accepted end state of the Phase 3
 * documents, carried into the Blueprint (DP-part-operations-2). A port of
 * `tom_som_dart_runtime/lib/src/spec_backfill.dart` (and the Go
 * `spec_backfill.go` / Rust `spec_backfill.rs`); it reads the comparison
 * internals of the document set.
 *
 * Ownership: every struct owns its strings; release with its `*_free`. The
 * `*_to_json` functions return owned JSON text. */
#ifndef SPEC_BACKFILL_H
#define SPEC_BACKFILL_H

#include <stddef.h>

#include "spec_document_set.h"

/* Why `spec_backfill` refuses a set. */
typedef enum {
  /* A document holds an inline mark or an annotation block. */
  SPEC_BACKFILL_ERROR_SET_HAS_MARKS = 0,
  /* The set has no Blueprint. */
  SPEC_BACKFILL_ERROR_NO_BLUEPRINT
} SpecBackfillErrorCode;

/* `setHasMarks`, `noBlueprint`. */
const char *spec_backfill_error_code_name(SpecBackfillErrorCode code);

/* The kind of a SpecBackfillChange. */
typedef enum {
  /* A value written or cleared. */
  SPEC_BACKFILL_CHANGE_VALUE = 0,
  /* An element added. */
  SPEC_BACKFILL_CHANGE_ELEMENT_ADDED,
  /* An element removed. */
  SPEC_BACKFILL_CHANGE_ELEMENT_REMOVED,
  /* The history entry. */
  SPEC_BACKFILL_CHANGE_REVISION,
  /* A derived place rewritten. */
  SPEC_BACKFILL_CHANGE_DERIVED
} SpecBackfillChangeKind;

/* `value`, `elementAdded`, `elementRemoved`, `revision`, `derived`. */
const char *spec_backfill_change_kind_name(SpecBackfillChangeKind kind);

/* Why `spec_backfill` left a finding. */
typedef enum {
  /* The Blueprint holds the value: the agent corrects the Phase 3 document. */
  SPEC_BACKFILL_LEFT_HELD_HERE = 0,
  /* Under `subset`, not carried in. */
  SPEC_BACKFILL_LEFT_MAY_BE_ADDED,
  /* The finding's own resolution (`agent`, `info`). */
  SPEC_BACKFILL_LEFT_RESOLUTION
} SpecBackfillLeftReasonKind;

typedef struct {
  SpecBackfillLeftReasonKind kind;
  /* For SPEC_BACKFILL_LEFT_RESOLUTION, the resolution. */
  SpecSyncResolution resolution;
} SpecBackfillLeftReason;

/* `heldHere`, `mayBeAdded`, or the resolution's name. */
const char *spec_backfill_left_reason_name(SpecBackfillLeftReason reason);

/* Why `spec_backfill` refuses a set. */
typedef struct {
  SpecBackfillErrorCode code;
  /* The places holding marks, in document order. */
  SpecSyncPlace *places;
  size_t places_len;
  char *message;
} SpecBackfillError;

void spec_backfill_error_init(SpecBackfillError *e);
void spec_backfill_error_free(SpecBackfillError *e);
/* `{code, places}` (no message). Owned. */
char *spec_backfill_error_to_json(const SpecBackfillError *e);
/* `SpecBackfillError(<code>): <message>`. Owned. */
char *spec_backfill_error_display(const SpecBackfillError *e);

/* One place `spec_backfill` wrote in the Blueprint. */
typedef struct {
  /* The pair the change belongs to; empty for the revision entry and the
   * derived places written after it. */
  char *pair;
  SpecBackfillChangeKind kind;
  /* The value's path, or the element's. */
  char *path;
  /* The form field (SPEC_HEADLINE_FIELD for a headline), "" for content and
   * elements. */
  char *field;
  /* The value before (for an element, its id before). */
  char *old_value;
  /* The value after (for an element, its id after). */
  char *new_value;
} SpecBackfillChange;

void spec_backfill_change_free(SpecBackfillChange *c);
char *spec_backfill_change_to_json(const SpecBackfillChange *c);

/* A finding `spec_backfill` left, with the reason. */
typedef struct {
  SpecSyncFinding finding;
  SpecBackfillLeftReason reason;
} SpecBackfillLeft;

/* What `spec_backfill` did. */
typedef struct {
  /* The Blueprint written: the set's own (as the set now holds it), or the
   * copy a dry run wrote. Owned. */
  SpecDocument blueprint;
  /* Every place written, in the order written. */
  SpecBackfillChange *changes;
  size_t changes_len;
  size_t changes_cap;
  /* Every finding in scope it did not resolve, with the reason. */
  SpecBackfillLeft *left;
  size_t left_len;
} SpecBackfillResult;

void spec_backfill_result_free(SpecBackfillResult *r);
/* `{changes, left, blueprint}`, the Blueprint as its stores. Owned. */
char *spec_backfill_result_to_json(const SpecBackfillResult *r);

/* The options of `spec_backfill` (a zeroed struct: every pair, written, the
 * default author and today's date). */
typedef struct {
  /* Non-NULL: keeps those pairs (by section id) only. Borrowed. */
  const SomStrList *pairs;
  /* Non-empty: keeps the findings at or below this Blueprint path. */
  const char *path;
  /* Writes a copy of the Blueprint; the set's own is left alone. */
  int dry_run;
  /* The revision entry's author; NULL or "" for `backfill`. */
  const char *author;
  /* The revision entry's date; NULL or "" for today (UTC). */
  const char *date;
} SpecBackfillOptions;

/* Carries the end state of the Phase 3 documents into the Blueprint, as plain
 * values: for every shared place whose holder is the Phase 3 document, the
 * holder's value — a differing or missing value written, a value the Phase 3
 * document emptied cleared, an element only in the Phase 3 document added
 * (with its stored section id, after its nearest preceding neighbour the
 * Blueprint holds, or first), an element only in the Blueprint removed.
 *
 * It leaves `detailOnly` places, a `heldHere` place the documents disagree
 * on, an element that under `subset` may be added, and every finding across
 * two documents: each is listed in `left` with the reason. It refuses a set
 * holding any inline mark or annotation block (`setHasMarks`, the places
 * named) and a set without a Blueprint (`noBlueprint`): 0, `*err` filled
 * (when non-NULL). It writes only the Blueprint; when it changed anything it
 * adds one entry to the Blueprint's revision history (the `RVENT` list)
 * naming the pairs, and rewrites the Blueprint's derived places
 * (`spec_derive_fields`, plain). A second run right after the first writes
 * nothing. `*out` initialised by the callee in every case. */
int spec_backfill(SpecDocumentSet *set, const SpecBackfillOptions *options,
                  SpecBackfillResult *out, SpecBackfillError *err);

/* The version after `v`: its last number raised by one (`1.2` -> `1.3`), `1`
 * when it is empty, `<v>.1` when it holds no number. Owned. */
char *spec_backfill_bump(const char *v);

#endif /* SPEC_BACKFILL_H */
