/* spec_prefill — `spec_prefill`: a Phase 3 document started from the
 * Blueprint (BP-8). A port of `tom_som_dart_runtime/lib/src/spec_prefill.dart`
 * (and the Go `spec_prefill.go` / Rust `spec_prefill.rs`); it reads the
 * comparison internals of the document set.
 *
 * Ownership: every struct owns its strings; release with its `*_free`. The
 * `*_to_json` functions return owned JSON text. */
#ifndef SPEC_PREFILL_H
#define SPEC_PREFILL_H

#include "spec_derive_fields.h"
#include "spec_document_set.h"

/* Why `spec_prefill` refuses. */
typedef enum {
  /* The set holds no Blueprint. */
  SPEC_PREFILL_ERROR_NO_BLUEPRINT = 0,
  /* The root names no root of the model, or the Blueprint's own. */
  SPEC_PREFILL_ERROR_UNKNOWN_ROOT
} SpecPrefillErrorCode;

/* `noBlueprint`, `unknownRoot`. */
const char *spec_prefill_error_code_name(SpecPrefillErrorCode code);

typedef struct {
  SpecPrefillErrorCode code;
  char *message;
} SpecPrefillError;

void spec_prefill_error_init(SpecPrefillError *e);
void spec_prefill_error_free(SpecPrefillError *e);
/* `SpecPrefillError(<code>): <message>`. Owned. */
char *spec_prefill_error_display(const SpecPrefillError *e);

/* What `spec_prefill` did. */
typedef struct {
  /* The document filled, as the set now holds it (unless nothing was
   * created: then the empty document the set did not take). Owned. */
  SpecDocument document;
  /* Its name in the set. */
  char *name;
  /* Whether it was created by this call. */
  int created;
  /* The pairs it filled, by section id, in the Blueprint's order. */
  SomStrList filled_pairs;
  /* The pairs it left because their anchor already holds a value. */
  SomStrList skipped_pairs;
  /* The `spec_derive_fields` run (plain) on the document after the copy. */
  SpecDeriveResult derived;
  /* The document's findings after it (`validate_document`, then
   * `spec_validate_links`): the agent's work list. */
  SpecValidationErrors findings;
} SpecPrefillResult;

void spec_prefill_result_free(SpecPrefillResult *r);
/* `{name, created, filledPairs, skippedPairs, derived: {changes, unresolved},
 * findings, document}`. Owned. */
char *spec_prefill_result_to_json(const SpecPrefillResult *r);

/* The options of `spec_prefill` (a zeroed struct: the default name, every
 * pair). */
typedef struct {
  /* The name a document created is given; NULL or "" for the root's type
   * name. */
  const char *name;
  /* Non-NULL: keeps those pairs (by section id) only. Borrowed. */
  const SomStrList *pairs;
} SpecPrefillOptions;

/* Fills the pairs of `root_type` (a root's type name or section id) that hold
 * nothing yet from the Blueprint, once, at the start of a Phase 3 document:
 * every value, element (with its stored section id) and headline beneath each
 * pair's Blueprint anchor, outside `detailOnly`, copied as plain values.
 * Derived places are not copied; they are derived in the document
 * (`spec_derive_fields`, plain) after the copy.
 *
 * A pair whose anchor already holds any value is skipped, not merged, so a
 * second run writes nothing. When the set has no document of the root, it is
 * created as `options->name` (default: the root's type name) and added to the
 * set once it holds a value. Refused (0, `*err` filled when non-NULL) without
 * a Blueprint (`noBlueprint`) or for a root that is no Phase 3 root of the
 * model (`unknownRoot`). `*out` initialised by the callee in every case. */
int spec_prefill(SpecDocumentSet *set, const char *root_type,
                 const SpecPrefillOptions *options, SpecPrefillResult *out,
                 SpecPrefillError *err);

#endif /* SPEC_PREFILL_H */
