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
/* A form field whose model type is an enum holding a token the enum does not
 * declare. The typed read is forgiving (an unknown token reads as absent), and
 * a document is loaded far more often than it is written through a setter, so
 * without this the value is simply dropped. An EMPTY value is absence, not a
 * bad value, and is not reported. */
#define SPEC_VALIDATION_CODE_ENUM_VALUE_UNKNOWN "enumValueUnknown"
/* A form field that states a count (`Field.countOf`) holding a number that is
 * not the number of entries the document holds, or no whole number at all
 * (vsctsa43). A total kept by hand drifts from the list it describes the first
 * time the list changes and the total does not. */
#define SPEC_VALIDATION_CODE_COUNT_MISMATCH "countMismatch"
/* A typed field (`int`, `double`, `num` or `bool`) — a form field or a scalar
 * leaf — holding text its type cannot read (`lots` in an `int`). The typed read
 * refuses such text rather than answering none, and the setters refuse to
 * store it, but a document edited by hand or by another tool can still carry
 * it; this is where it is reported. Empty text is absence, not a bad value,
 * and is not reported. A `countOf` form field is left to countMismatch, a
 * `productOf` / `rankOf` one to derivedValueMismatch. */
#define SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH "valueTypeMismatch"
/* A form field whose value is derived from other fields — a product
 * (`Field.productOf`) or a rank by a sibling field (`Field.rankOf`) — holding
 * a value the fields it is derived from do not give, or no number at all
 * (uamtc10). A risk score kept by hand drifts the first time probability or
 * impact changes and the score does not. A `productOf` / `rankOf` form field
 * is not reported as valueTypeMismatch. */
#define SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH "derivedValueMismatch"
/* A form the document holds whose model-declared required field
 * (`formFields[].required`) is absent or empty after trimming (uamtc16). One
 * finding per required field, at the form path, in declared order. Checked on
 * every form the document holds — class-level `content` forms and member
 * forms, in list items or not — so an absent form is absence, not an
 * incomplete one. */
#define SPEC_VALIDATION_CODE_MISSING_REQUIRED_FIELD "missingRequiredField"

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
 * `@OneOf` case instances, then `refersTo` references, then `countOf` stated
 * counts, then `productOf` / `rankOf` derived values (one group); each group
 * sorted by path. An empty list means the document is valid. */
void validate_document(const SpecModel *model, const SpecDocument *doc,
                       SpecValidationErrors *out);

void spec_validation_errors_free(SpecValidationErrors *errs);

#endif /* SPEC_VALIDATOR_H */
