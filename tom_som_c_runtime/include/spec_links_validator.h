/* spec_links_validator — the link checks of one document
 * (`tom_specs_model_rules.md` §9.7): `spec_validate_links` holds a document's
 * values to the link annotations of the model — derived values to their
 * sources, summaries to their detail lists, each end of a link to the other,
 * the ids named in a text to the link rows, and a `@SameAs` copy to its
 * holder. A port of `tom_som_dart_runtime/lib/src/spec_links_validator.dart`
 * (and the Go `spec_links_validator.go` / Rust `spec_links_validator.rs`).
 *
 * Values are read in their reviewed state: a value holding pending change
 * marks is read with every mark rejected, and listed as `linkValuePending`. A
 * `@SummaryOf` naming another document is skipped here; the document set
 * checks it.
 *
 * Beside each finding the checker collects the `SpecLinkFix` `deriveFields`
 * would write for it, with the order an `addRow` writes its values in and the
 * order of a derived list's tuple places.
 *
 * Ownership: every struct owns its strings; release with its `*_free`. */
#ifndef SPEC_LINKS_VALIDATOR_H
#define SPEC_LINKS_VALIDATOR_H

#include "som_util.h"
#include "spec_document.h"
#include "spec_model.h"
#include "spec_place.h"
#include "spec_reflection.h"
#include "spec_validator.h"

/* Runs the link checks of `doc` against `model`; the findings, sorted by path,
 * then by code (declaration order), then by message, into `out` (initialised
 * by the callee; release with `spec_validation_errors_free`). */
void spec_validate_links(const SpecModel *model, const SpecDocument *doc,
                         SpecValidationErrors *out);

/* Every concrete path of `pattern` in `doc`: each `<list>-*` segment expanded
 * over the document's items. `*out` initialised by the callee. */
void spec_expand_pattern(const SpecDocument *doc, const char *pattern,
                         SomStrList *out);

/* `place` resolved under `anchor`; 0 (out untouched) when it does not
 * parse or resolve. */
int spec_resolve_place_at(const SpecReflection *refl, const char *place,
                          const char *anchor, SpecPlaceResolution *out);

/* `place` resolved for a link annotated at `anchor`, as the link checks and
 * the rendition's `linked` marker (SOM §11.11) read it: a `./` place beneath
 * the nearest list element of `anchor`; any other place inside `anchor`'s
 * subtree when it is there, else anywhere beneath the document root `root` —
 * a bare id wherever it is reached once, a `/` path from the section its first
 * segment names, through the first item `doc` holds of a list there (`doc`
 * NULL: such a path does not resolve). 0 when it does not resolve. */
int spec_resolve_link_place(const SpecReflection *refl, const SpecDocument *doc,
                            const char *place, const char *root,
                            const char *anchor, SpecPlaceResolution *out);

/* The comma-separated ids of `value`, trimmed, empty ones dropped. `*out`
 * initialised by the callee. */
void spec_link_ids(const char *value, SomStrList *out);

/* The field a resolved value place names for a write: the form field, the
 * headline's reserved field (SPEC_HEADLINE_FIELD), or NULL for content.
 * Borrowed. */
const char *spec_link_field_of(const SpecPlaceResolution *r);

/* ---- SpecLinkFix ----------------------------------------------------------- */

/* The kinds of SpecLinkFix (static literals). */
#define SPEC_LINK_FIX_SET "set"
#define SPEC_LINK_FIX_APPEND "append"
#define SPEC_LINK_FIX_ADD_ROW "addRow"
#define SPEC_LINK_FIX_REMOVE_ROW "removeRow"
#define SPEC_LINK_FIX_LIST "list"
#define SPEC_LINK_FIX_COPY "copy"

/* What `deriveFields` would write for one link finding.
 *
 * Kinds: `set` (the value at `path` / `field`, `field` NULL: content),
 * `append` (add `value` to the ids of the reference field), `addRow` (add a
 * row to the list at `path`: `<member>#<field>` -> value in `values`, in the
 * order they are written), `removeRow` (the row at `path`; `empty`: it holds
 * no value already), `list` (make the list at `path` hold one element per
 * tuple of `tuples`, each in `tuple_keys` order), `copy` (write the copy at
 * `path` from `holder`). */
typedef struct {
  int step;
  const char *kind; /* a SPEC_LINK_FIX_* literal */
  char *path;
  char *field; /* NULL: content (or unused) */
  char *value;
  SpecStringPairs values; /* addRow: in written order */
  SpecStringPairs *tuples; /* list: one per wanted element */
  size_t tuples_len;
  SomStrList tuple_keys; /* list: the target places, in the derivation's order */
  char *holder;
  int empty;
} SpecLinkFix;

void spec_link_fix_free(SpecLinkFix *f);
/* The fix as JSON, unset parts left out (for comparing runtimes). Owned. */
char *spec_link_fix_to_json(const SpecLinkFix *f);

typedef struct {
  SpecLinkFix *items;
  size_t len;
  size_t cap;
} SpecLinkFixes;

/* ---- SpecLinkValidator ------------------------------------------------------ */

typedef struct SpecLinkValidatorCache SpecLinkValidatorCache;

/* The link checker of one document: `spec_validate_links` runs it,
 * `deriveFields` reads its fixes and value readers. */
typedef struct {
  /* What `deriveFields` would write for each finding, collected beside it. */
  SpecLinkFixes fixes;
  /* The findings, in the order they were found. */
  SpecValidationErrors errors;
  /* The effective section id per list item path (writable by
   * `deriveFields`). */
  SomMap item_ids;
  /* Reads values with their pending marks accepted (the proposal), as
   * `deriveFields` does in a document under review, instead of the reviewed
   * state; no value is then listed as pending. */
  int read_proposed;
  const SpecModel *model;   /* borrowed */
  const SpecDocument *doc;  /* borrowed */
  SpecReflection refl;
  SpecLinkValidatorCache *cache; /* owned, private */
} SpecLinkValidator;

void spec_link_validator_init(SpecLinkValidator *v, const SpecModel *model,
                              const SpecDocument *doc, int read_proposed);
void spec_link_validator_free(SpecLinkValidator *v);
/* Runs every link check. */
void spec_link_validator_run(SpecLinkValidator *v);
/* Records one finding, once. */
void spec_link_validator_report(SpecLinkValidator *v, const char *code,
                                const char *path, const char *message);

/* The value readers (each owned; "" when there is none). */
char *spec_link_validator_form_value(SpecLinkValidator *v, const char *path,
                                     const char *field);
char *spec_link_validator_content_value(SpecLinkValidator *v,
                                        const char *path);
char *spec_link_validator_headline_value(SpecLinkValidator *v,
                                         const char *path);
/* The effective section id of the list item at `item_path`. Owned. */
char *spec_link_validator_item_id(SpecLinkValidator *v, const char *item_path);
/* Whether `path` is a complex list item. */
int spec_link_validator_is_item(SpecLinkValidator *v, const char *path);
/* The value a resolved place holds at its concrete `path`. Owned. */
char *spec_link_validator_value(SpecLinkValidator *v,
                                const SpecPlaceResolution *r,
                                const char *path);
/* The value of `place` resolved under the concrete `anchor`. Owned. */
char *spec_link_validator_place_value(SpecLinkValidator *v, const char *place,
                                      const char *anchor);
/* Whether anything beneath `path` holds a value (marks included). */
int spec_link_validator_holds_value(SpecLinkValidator *v, const char *path);

#endif /* SPEC_LINKS_VALIDATOR_H */
