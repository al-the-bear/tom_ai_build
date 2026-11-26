/* spec_model_links — the typed readers of the link vocabulary
 * (`tom_specs_model_rules.md` §9.7), a port of the link readers of
 * `tom_som_dart_runtime/lib/src/spec_model.dart` (and the Go
 * `spec_model_links.go` / Rust `spec_model_links.rs`).
 *
 * They are read from the lossless `annotations` block (member and class
 * annotations: `@SyncedWith`, `@SummaryOf`, `@DerivedFrom`, `@ExtractsLinks`,
 * `@SameAs`) or from the curated `formFields[]` keys (the `Field` qualifiers
 * `derivedFrom:`, `inverseOf:`, `summaryOf:`). They follow the kind links: an
 * enum constant is read with its type prefix stripped (`LinkRelation.subset`
 * -> `subset`), a key the reader does not know is ignored, and an absent key
 * takes the annotation's default — so a meta written before a key existed
 * loads unchanged.
 *
 * An optional string argument that is absent reads as NULL; the canonical JSON
 * forms leave it out. A string -> string argument (`repeats`, `map`, `set`)
 * keeps the order the meta writes it in, as the reference's maps do: it is a
 * `SpecStringPairs`, never a sorted map.
 *
 * This header holds the value types only (it is included by `spec_model.h`,
 * whose `FormFieldSpec` carries the qualifiers); the readers over a class's or
 * a field's annotations are declared in `spec_model.h`.
 *
 * Ownership: every struct owns its strings; release with its `*_free`
 * function (safe on a zeroed struct). The `*_to_json` functions return owned
 * JSON text. */
#ifndef SPEC_MODEL_LINKS_H
#define SPEC_MODEL_LINKS_H

#include <stddef.h>

#include "som_json.h"
#include "som_util.h"

/* ---- ordered string -> string pairs -------------------------------------- */

/* One entry of an ordered string -> string argument (`SummaryOf.repeats`,
 * `DerivedFrom.map`, `ExtractsLinks.set`). Both strings owned. */
typedef struct {
  char *key;
  char *value;
} SpecStringPair;

/* An ordered list of pairs, in the order the meta (or the writer) gave them. */
typedef struct {
  SpecStringPair *items;
  size_t len;
  size_t cap;
} SpecStringPairs;

void spec_string_pairs_init(SpecStringPairs *p);
void spec_string_pairs_free(SpecStringPairs *p);
/* Appends (key, value), copying both. */
void spec_string_pairs_push(SpecStringPairs *p, const char *key,
                            const char *value);
/* Sets `key` to `value`: a key already present keeps its position and takes
 * the new value, a new key is appended (the write order an `addRow` keeps). */
void spec_string_pairs_put(SpecStringPairs *p, const char *key,
                           const char *value);
/* The value of `key` (the last one written for a repeated key), or NULL. */
const char *spec_string_pairs_get(const SpecStringPairs *p, const char *key);
/* Copies `src` into `dst` (initialised by the callee). */
void spec_string_pairs_copy(SpecStringPairs *dst, const SpecStringPairs *src);
/* The pairs as a JSON object, in their order. Owned. */
char *spec_string_pairs_to_json(const SpecStringPairs *p);

/* ---- the link values ----------------------------------------------------- */

/* The relation of the elements of a list on two sides of a link, as the
 * annotated side reads it (`ListRelation`). */
typedef struct {
  /* The list or multi-valued reference field the relation is about. */
  char *place;
  /* `equal`, `subset` or `superset` (the `LinkRelation` constant name). */
  char *relation;
  /* The filter selecting the elements the relation applies to (the
   * SpecPlaceFilter grammar), NULL for all of them. */
  char *where;
} SpecListRelation;

void spec_list_relation_free(SpecListRelation *r);
char *spec_list_relation_to_json(const SpecListRelation *r);

/* `@SyncedWith(document, {detailOnly, heldHere, relations, note})`: the
 * annotated section is kept in sync with the section of the same id in
 * `document`. */
typedef struct {
  /* The other document's root class name. */
  char *document;
  /* The places only `document` carries. */
  SomStrList detail_only;
  /* The places whose value this document holds. */
  SomStrList held_here;
  /* The lists whose relation is not `equal`. */
  SpecListRelation *relations;
  size_t relations_len;
  /* The free-text note, NULL when absent. */
  char *note;
} SpecSync;

void spec_sync_free(SpecSync *s);
char *spec_sync_to_json(const SpecSync *s);

/* `@SummaryOf` on a member, or the `summaryOf:` qualifier of a form field: the
 * annotated list or reference field summarises a detailed list. */
typedef struct {
  /* The detailed list, `<LIST-ID>` (a `/` path where needed). */
  char *detail;
  /* The root class name of the document holding `detail`; NULL: this one. */
  char *document;
  /* The summary element's field naming its detail element; NULL: the summary
   * element carries the detail element's own section id. */
  char *match;
  /* `equal`, `subset` (the default) or `superset`. */
  char *relation;
  /* Summary place -> detail place for every value the summary repeats, in
   * the meta's order. */
  SpecStringPairs repeats;
  char *note;
} SpecSummaryOf;

void spec_summary_of_free(SpecSummaryOf *s);
char *spec_summary_of_to_json(const SpecSummaryOf *s);

/* `@DerivedFrom` on a member, or the `derivedFrom:` qualifier of a form field:
 * the value is derived from other places. */
typedef struct {
  /* `copy`, `rows` or `lookup` (the `DerivationKind` constant name). */
  char *kind;
  /* For copy, the place copied; for rows / lookup, the rows read. */
  char *source;
  /* For rows, which rows count (the SpecPlaceFilter grammar); NULL for all. */
  char *where;
  /* For rows / lookup, the row places collected. */
  SomStrList take;
  /* For rows / lookup, the row field compared with this element's `by`. */
  char *key;
  /* For rows / lookup, this element's field holding the key. */
  char *by;
  /* For a list member, target element place <- row place, in the meta's
   * order. */
  SpecStringPairs map;
  char *note;
} SpecDerivation;

void spec_derivation_free(SpecDerivation *d);
char *spec_derivation_to_json(const SpecDerivation *d);

/* The `inverseOf:` qualifier of a reference form field: the other ends of the
 * link. */
typedef struct {
  /* The other ends, `<FORMSECTIONID>.<field>`; `["@self"]` for the symmetric
   * form. */
  SomStrList fields;
  /* Only values (or rows) matching this filter have an inverse; NULL for
   * all. */
  char *where;
} SpecInverseOf;

void spec_inverse_of_free(SpecInverseOf *i);
/* Whether the link is stored on both entries in the same field
 * (`InverseOf.symmetric`). */
int spec_inverse_of_symmetric(const SpecInverseOf *i);
char *spec_inverse_of_to_json(const SpecInverseOf *i);

/* `@ExtractsLinks` on a list of link rows: ids named in text get rows. A
 * member may carry it more than once. */
typedef struct {
  /* The row's `refersTo` field receiving a found id. */
  char *ref;
  /* The text places searched for ids. */
  SomStrList from;
  /* The values every generated row gets, in the meta's order. */
  SpecStringPairs set;
  /* `generate` (the default) or `warn` (the `ExtractMode` constant name). */
  char *mode;
  char *note;
} SpecExtractsLinks;

void spec_extracts_links_free(SpecExtractsLinks *e);
char *spec_extracts_links_to_json(const SpecExtractsLinks *e);

/* Every `@ExtractsLinks` of one member, in source order. */
typedef struct {
  SpecExtractsLinks *items;
  size_t len;
} SpecExtractsLinksList;

void spec_extracts_links_list_free(SpecExtractsLinksList *l);

/* `@SameAs({holder, note})` on a section member: the member holds a copy of
 * the section the same document holds at another position, the holder. */
typedef struct {
  /* The holder's section-id path, its last ids as far as needed
   * (`ACPLN/ACRITL`); NULL: the one other position of the class. */
  char *holder;
  char *note;
} SpecSameAs;

void spec_same_as_free(SpecSameAs *s);
char *spec_same_as_to_json(const SpecSameAs *s);

/* ---- reading an argument object ------------------------------------------ */

/* The readers of one argument object (an annotation's `arguments`, or a
 * `formFields[]` qualifier object). `args` may be NULL (every key absent);
 * `*out` is filled in full (release with its free function). */
void spec_list_relation_from_arguments(const SomJson *args,
                                       SpecListRelation *out);
void spec_sync_from_arguments(const SomJson *args, SpecSync *out);
void spec_summary_of_from_arguments(const SomJson *args, SpecSummaryOf *out);
void spec_derivation_from_arguments(const SomJson *args, SpecDerivation *out);
void spec_inverse_of_from_arguments(const SomJson *args, SpecInverseOf *out);
void spec_extracts_links_from_arguments(const SomJson *args,
                                        SpecExtractsLinks *out);
void spec_same_as_from_arguments(const SomJson *args, SpecSameAs *out);

/* A JSON scalar as text, the way the reference writes it (`true`, `null`, a
 * whole number without a fraction); a list or object as compact JSON. Owned;
 * "null" for a NULL `v`. */
char *spec_link_json_text(const SomJson *v);

#endif /* SPEC_MODEL_LINKS_H */
