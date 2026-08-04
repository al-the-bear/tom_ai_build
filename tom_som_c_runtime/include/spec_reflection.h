/* spec_reflection — generic, value-free traversal of a SpecModel class graph (the
 * "reflection" surface), a faithful port of the Rust `spec_reflection.rs`.
 *
 * It answers two kinds of question about a model: enumeration (what roots,
 * classes, fields and annotations exist) and resolution (which model node a
 * concrete document path addresses). It holds no document values.
 *
 * Ownership: unlike the Rust port (which clones the matched root/field/class into
 * the resolution), the C `SpecResolution` holds *borrowed* pointers into the
 * model — the model must outlive any resolution derived from it. Only `path` is
 * owned; free it with `spec_resolution_free`.
 */
#ifndef SPEC_REFLECTION_H
#define SPEC_REFLECTION_H

#include "spec_model.h"

/* Node kinds — what a resolved path lands on in the model. Static literals. */
#define SPEC_NODE_KIND_ROOT "root"
#define SPEC_NODE_KIND_COMPLEX "complex"
#define SPEC_NODE_KIND_SECTION "section"
#define SPEC_NODE_KIND_LIST "list"
#define SPEC_NODE_KIND_LIST_ITEM_COMPLEX "listItemComplex"
#define SPEC_NODE_KIND_LIST_ITEM_SCALAR "listItemScalar"
#define SPEC_NODE_KIND_FORM "form"
#define SPEC_NODE_KIND_CONTENT "content"
#define SPEC_NODE_KIND_ENUM_VALUE "enumValue"
#define SPEC_NODE_KIND_SCALAR "scalar"

typedef struct {
  char *path;                    /* owned */
  const char *kind;              /* static literal (one of SPEC_NODE_KIND_*) */
  const SpecRoot *root;          /* borrowed from model (or NULL) */
  const SpecField *field;        /* borrowed from model (or NULL) */
  const SpecClass *target_class; /* borrowed from model (or NULL) */
} SpecResolution;

/* Frees the owned members of a resolution (currently `path`). */
void spec_resolution_free(SpecResolution *r);

/* Reports whether a single string value is stored directly at this node (a
 * content, enum, scalar leaf, or a scalar list item). */
int spec_resolution_is_value_leaf(const SpecResolution *r);

/* The reflection surface is a thin, borrowing wrapper over a model. */
typedef struct {
  const SpecModel *model;
} SpecReflection;

SpecReflection spec_reflection_make(const SpecModel *model);

/* Section segment of a root / field (sectionId when set, else type / name). */
const char *spec_reflection_root_segment(const SpecRoot *root);
const char *spec_reflection_field_segment(const SpecField *field);

/* Returns the root whose segment matches `segment`, or NULL. */
const SpecRoot *spec_reflection_root_for_segment(const SpecReflection *r,
                                                 const char *segment);

/* Writes into `*out` every class name reachable from `type_name` by following
 * class-bearing fields — `complex`/`section` fields through their `type`,
 * complex list fields through their `element_type` — including `type_name`
 * itself.
 *
 * This is the model's notion of **document scope**. A document rooted at a given
 * `@Document` class can only ever hold sections of the classes that root
 * reaches, so a class outside the set is not merely *unpopulated* in such a
 * document — it is absent from it by construction. Any consumer that has to tell
 * "the author did not write this" from "this document could not hold it in the
 * first place" needs exactly this set.
 *
 * A name that resolves to no class contributes nothing and is not itself
 * included: an unresolved reference is not evidence of a reachable class.
 *
 * `*out` is initialised by the callee; free it with `som_strlist_free`. */
void spec_reflection_reachable_class_names(const SpecReflection *r,
                                           const char *type_name,
                                           SomStrList *out);

/* Resolves a document path to the model node it addresses. Returns 1 and fills
 * `*out` on success (caller frees with `spec_resolution_free`); returns 0 when
 * the path does not describe a reachable node (and leaves `*out` untouched). */
int spec_reflection_resolve(const SpecReflection *r, const char *path,
                            SpecResolution *out);

#endif /* SPEC_REFLECTION_H */
