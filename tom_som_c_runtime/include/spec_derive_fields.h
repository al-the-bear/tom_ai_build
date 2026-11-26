/* spec_derive_fields — `spec_derive_fields`: the derived places of one
 * document, written (`tom_specs_model_rules.md` §9.7). A port of
 * `tom_som_dart_runtime/lib/src/spec_derive_fields.dart` (and the Go
 * `spec_derive_fields.go` / Rust `spec_derive_fields.rs`); it applies the
 * `SpecLinkFix` entries `SpecLinkValidator` collects, in their recorded write
 * order.
 *
 * As in the reference runtimes, the checker reads the document while it is
 * written (it is bound to the document itself), so a write that reads values
 * back sees the writes before it and the caches the run collected.
 *
 * Ownership: every struct owns its strings; release with its `*_free`. The
 * `*_to_json` functions return owned JSON text. */
#ifndef SPEC_DERIVE_FIELDS_H
#define SPEC_DERIVE_FIELDS_H

#include <stddef.h>

#include "spec_document.h"
#include "spec_model.h"
#include "spec_validator.h"

/* The kind of a SpecDeriveChange. */
typedef enum {
  /* A value written. */
  SPEC_DERIVE_CHANGE_VALUE = 0,
  /* A row added. */
  SPEC_DERIVE_CHANGE_ROW_ADDED,
  /* A row removed (under review: every value of it proposed for deletion). */
  SPEC_DERIVE_CHANGE_ROW_REMOVED
} SpecDeriveChangeKind;

/* The kind's name as the corpus writes it (`value`, `rowAdded`,
 * `rowRemoved`). */
const char *spec_derive_change_kind_name(SpecDeriveChangeKind kind);

/* One place `spec_derive_fields` wrote. */
typedef struct {
  /* The step that wrote it: 1 (link ends and rows), 2 (derived values,
   * repeats, `@SameAs` copies), 3 (counts, products, ranks). */
  long long step;
  SpecDeriveChangeKind kind;
  /* The value's path, or the row's. */
  char *path;
  /* The form field (SPEC_HEADLINE_FIELD for a headline), "" for content and
   * rows. */
  char *field;
  /* The value before (for a row, empty). */
  char *old_value;
  /* The value after (for a row, empty). */
  char *new_value;
} SpecDeriveChange;

void spec_derive_change_free(SpecDeriveChange *c);
char *spec_derive_change_to_json(const SpecDeriveChange *c);

/* What `spec_derive_fields` did. */
typedef struct {
  /* The copy written on a dry run (owned heap document); NULL when the given
   * document was written in place. */
  SpecDocument *document;
  /* Every place written, in the order written. */
  SpecDeriveChange *changes;
  size_t changes_len;
  size_t changes_cap;
  /* What it could not write, with the code: `unmarkable` (a change it cannot
   * mark exactly in a document under review, left as it was),
   * `derivedLookupMiss` (a lookup without exactly one row). */
  SpecValidationErrors unresolved;
} SpecDeriveResult;

void spec_derive_result_free(SpecDeriveResult *r);
/* The document written: the copy of a dry run, else `given` (the document
 * `spec_derive_fields` wrote in place). */
const SpecDocument *spec_derive_result_written(const SpecDeriveResult *r,
                                               const SpecDocument *given);
/* `{changes, unresolved, document}`, the document written as its stores
 * (`given`: the document `spec_derive_fields` was called with). Owned. */
char *spec_derive_result_to_json(const SpecDeriveResult *r,
                                 const SpecDocument *given);

/* The options of `spec_derive_fields` (a zeroed struct: plain values, in
 * place). */
typedef struct {
  /* Writes every change as inline marks (SOM §11.9.3), for a document under
   * review, and reads values as proposed (pending marks accepted); 0 writes
   * plain values. The reference runtimes default it to true. */
  int marked;
  /* The review member the marks are attributed to; NULL or "" for none. */
  const char *author;
  /* The change time the marks record; NULL or "" for now. */
  const char *at;
  /* Works on a copy of the document. */
  int dry_run;
} SpecDeriveOptions;

/* Recomputes the derived places of `doc` in three steps, each reading the
 * result of the one before:
 *
 * 1. the missing `inverseOf` ends inside the document, the missing
 *    `@ExtractsLinks` rows in `generate` mode, and the stale generated rows
 *    removed (a link row left with no value at all goes too);
 * 2. `@DerivedFrom` values and lists, `@SummaryOf` `repeats`, and every
 *    `@SameAs` copy from its holder;
 * 3. `countOf`, `productOf` and `rankOf`.
 *
 * With `options->marked` every change is written as inline marks attributed
 * to `options->author` at `options->at`, and values are read as proposed; a
 * change it cannot mark exactly is left as it was and listed as `unmarkable`.
 * It never writes another document; a second run right after the first writes
 * nothing. `options->dry_run` works on a copy (the result's `document`) and
 * leaves `doc` alone. `*out` initialised by the callee. */
void spec_derive_fields(const SpecModel *model, SpecDocument *doc,
                        const SpecDeriveOptions *options,
                        SpecDeriveResult *out);

/* `spec_derive_fields` on a copy of `doc`, whatever `options->dry_run` says:
 * the copy is the result's `document`. */
void spec_derive_fields_dry_run(const SpecModel *model, const SpecDocument *doc,
                                const SpecDeriveOptions *options,
                                SpecDeriveResult *out);

#endif /* SPEC_DERIVE_FIELDS_H */
