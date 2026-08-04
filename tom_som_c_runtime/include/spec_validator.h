/* spec_validator — validates a concrete SpecDocument's values against a SpecModel
 * via the SpecReflection resolver, a faithful port of the Rust `spec_validator.rs`.
 *
 * The check is over the values a document holds: every set path must resolve to a
 * node of a compatible kind, every form sub-key must name a real form field, and
 * every populated list must meet its `@Min` item count. Schema completeness
 * (mandatory-but-absent nodes) is a separate concern and is not reported here.
 *
 * Ownership: the returned list owns its errors; free with
 * `spec_validation_errors_free`.
 */
#ifndef SPEC_VALIDATOR_H
#define SPEC_VALIDATOR_H

#include "spec_document.h"
#include "spec_model.h"

#define SPEC_VALIDATION_CODE_DANGLING_PATH "danglingPath"
#define SPEC_VALIDATION_CODE_KIND_MISMATCH "kindMismatch"
#define SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD "unknownFormField"
#define SPEC_VALIDATION_CODE_MIN_ITEMS "minItems"
/* A populated `@Case` subsection the chosen `@OneOf` discriminator does not
 * select, or two selected-and-populated subsections in one container. */
#define SPEC_VALIDATION_CODE_ONE_OF_CASE_MISMATCH "oneOfCaseMismatch"
/* A `refersTo` form field naming an id no entry of its target registries
 * declares in this document. */
#define SPEC_VALIDATION_CODE_DANGLING_REFERENCE "danglingReference"

typedef struct {
  char *path;    /* owned */
  char *code;    /* owned (one of the SPEC_VALIDATION_CODE_* literals, copied) */
  char *message; /* owned */
} SpecValidationError;

typedef struct {
  SpecValidationError *items;
  size_t len;
  size_t cap;
} SpecValidationErrors;

/* Validates `doc` against `model`, writing problems into `out` (initialised by
 * the callee) in stable order: content paths, then forms, then lists, then
 * `@OneOf` case instances, then `refersTo` references; each group sorted by
 * path. An empty list means the document is valid. */
void validate_document(const SpecModel *model, const SpecDocument *doc,
                       SpecValidationErrors *out);

void spec_validation_errors_free(SpecValidationErrors *errs);

#endif /* SPEC_VALIDATOR_H */
