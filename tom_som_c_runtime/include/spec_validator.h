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
/* A reference form field (`refersTo`) not marked `multiple` whose value names
 * more than one id as a comma-separated list (uamtc17). One finding at the form
 * path; each id of the list is still resolved, so a dangling one is a
 * `danglingReference` as well. */
#define SPEC_VALIDATION_CODE_MULTIPLE_REFERENCES "multipleReferences"
/* A comment block or a question block sits inside a form field's value —
 * between or below the form's fields — instead of in the form's preamble
 * (SOM §11.9.4). */
#define SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED "annotationMisplaced"
/* An annotation does not follow the notation (SOM §11.9.5): an unclosed or
 * nested inline mark, a substitution without `~>`, a comment id that is not
 * `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, or a
 * question or answer inside a comment block. */
#define SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED "annotationMalformed"
/* A comment id or a question id is used twice in one document
 * (SOM §11.9.5). */
#define SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID "duplicateAnnotationId"
/* A section's `units` (SOM §11.2) names an id no generation-unit entry of the
 * document declares. */
#define SPEC_VALIDATION_CODE_UNKNOWN_UNIT "unknownUnit"
/* A section carries `units`, but neither its class nor any class reachable
 * beneath it routes anything to CodeSpecs (`@CodeSpecKind`), so the units
 * would place nothing. */
#define SPEC_VALIDATION_CODE_UNITS_UNROUTED "unitsUnrouted"
/* Two generation-unit entries declare one `unitId`; reported at the second. */
#define SPEC_VALIDATION_CODE_DUPLICATE_UNIT_ID "duplicateUnitId"
/* A generation-unit entry names neither a `deploymentTarget` nor a
 * `component`, so it builds nothing. */
#define SPEC_VALIDATION_CODE_UNIT_BUILDS_NOTHING "unitBuildsNothing"
/* A generation-unit mapping's `area` is not an area code (`CE-` followed by
 * capital letters). */
#define SPEC_VALIDATION_CODE_UNIT_AREA_MALFORMED "unitAreaMalformed"
/* A generation-unit emitter names no standard emitter
 * (`SPEC_STANDARD_EMITTERS`: `openapi`, `jsonschema`, `icu`, `asyncapi`, `markdown`). */
#define SPEC_VALIDATION_CODE_UNIT_EMITTER_UNKNOWN "unitEmitterUnknown"

/* The link checks of one document (`spec_validate_links`,
 * `tom_specs_model_rules.md` §9.7). A stored derived value its sources do not
 * give is reported as derivedValueMismatch above. */

/* A `@DerivedFrom.lookup` finds no row for its key, or more than one. */
#define SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS "derivedLookupMiss"
/* Two link rows beneath one element name the same id with the same type (the
 * values `@ExtractsLinks` sets); reported at the second. */
#define SPEC_VALIDATION_CODE_DUPLICATE_LINK_ROW "duplicateLinkRow"
/* A link names an entry whose other end (`inverseOf`) does not name it back,
 * or a symmetric row has no counterpart on the entry it names. An end whose
 * registry the document does not hold is skipped. */
#define SPEC_VALIDATION_CODE_INVERSE_MISSING "inverseMissing"
/* An id named in an `@ExtractsLinks` text has no row. An id that has a row of
 * any type is a reference to it and is not reported. */
#define SPEC_VALIDATION_CODE_EXTRACTED_LINK_MISSING "extractedLinkMissing"
/* A generated row (its `@ExtractsLinks` `set` values match) names an id the
 * text no longer names. */
#define SPEC_VALIDATION_CODE_EXTRACTED_LINK_STALE "extractedLinkStale"
/* A summary row (`@SummaryOf`) names no element of its detail list. */
#define SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL "summaryNotInDetail"
/* Under `relation: equal`, a detail element no summary row names. */
#define SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY "detailNotInSummary"
/* Two summary rows name one detail element; reported at the second. */
#define SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE "summaryDuplicate"
/* A `@SameAs` copy holds a value its holder does not (or lacks one it holds):
 * the two positions of the section were edited apart. */
#define SPEC_VALIDATION_CODE_SAME_AS_MISMATCH "sameAsMismatch"
/* A value a link check reads holds pending change marks. It is read with
 * every mark rejected (the reviewed state) and listed for the user. */
#define SPEC_VALIDATION_CODE_LINK_VALUE_PENDING "linkValuePending"
/* A change `deriveFields` would write in a document under review that cannot
 * be marked exactly (a difference inside fenced code, SOM §11.9.3); it is
 * left as it was, for the agent. */
#define SPEC_VALIDATION_CODE_UNMARKABLE "unmarkable"

/* Every SPEC_VALIDATION_CODE_* above, in declaration order — the enumerable
 * vocabulary Dart has from its enum, as DOCSPECS_ALL_RULES is for the §14
 * rules. A tool switches over it exhaustively instead of matching on message
 * text; tests/spec_validation_all_codes_test.c reads the defines above and
 * fails when one is missing here. */
#define SPEC_VALIDATION_ALL_CODES_COUNT 32
extern const char *const SPEC_VALIDATION_ALL_CODES[SPEC_VALIDATION_ALL_CODES_COUNT];

/* The declaration order of `code` (Dart's `SpecValidationCode.index`), which
 * sorted finding lists follow; -1 for a string that is no code. */
int spec_validation_code_index(const char *code);

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
 * counts, then `productOf` / `rankOf` derived values (one group), then the
 * generation units (SOM §11.2 `units`, phase 8: the register and every
 * section's `units`, one group), then the review annotations (SOM §11.9.5, `spec_review_annotations_validate`); each
 * group sorted by path. An empty list means the document is valid. */
void validate_document(const SpecModel *model, const SpecDocument *doc,
                       SpecValidationErrors *out);

void spec_validation_errors_free(SpecValidationErrors *errs);

/* Appends one finding (path, code and message copied). */
void spec_validation_errors_push(SpecValidationErrors *errs, const char *path,
                                 const char *code, const char *message);

/* One derived number `spec_derived_numbers` computes: the value the form
 * field `field` of the form at `path` should hold. Strings owned. */
typedef struct {
  char *path;
  char *field;
  char *value;
} SpecDerivedNumber;

typedef struct {
  SpecDerivedNumber *items;
  size_t len;
  size_t cap;
} SpecDerivedNumbers;

/* The value every derived number of `doc` should hold, by the rules the
 * instance tier checks (`countOf`, `productOf`, `rankOf`): one entry per form
 * field whose value is decidable, whether it is filled or not — the counts,
 * then the products, then the ranks (over the products just derived). With
 * `read_proposed`, values holding pending marks are read with the marks
 * accepted (the proposal `deriveFields` writes in a document under review),
 * else with them rejected. `*out` initialised by the callee. */
void spec_derived_numbers(const SpecModel *model, const SpecDocument *doc,
                          int read_proposed, SpecDerivedNumbers *out);
void spec_derived_numbers_free(SpecDerivedNumbers *n);

#endif /* SPEC_VALIDATOR_H */
