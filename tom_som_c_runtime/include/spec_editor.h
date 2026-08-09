/* spec_editor — the generic, meta-model-driven modification API (YRD7), a
 * faithful port of the Dart `spec_editor.dart` and the Python `spec_editor.py`.
 *
 * `SpecEditor` lets a consumer walk any document's meta tree and
 * create/modify/delete sections, list items, headlines, ids, content and
 * **typed** form fields *without a generated facade*: every operation resolves
 * its path against the `SpecModel` first (`spec_reflection_resolve`) and
 * converts values at the store boundary through the same `spec_typed_values`
 * helpers a generated accessor calls — so a typed facade is provably a thin
 * layer over exactly this API.
 *
 * Typed contract (mirrored by all nine runtimes):
 *   - `int` / `double` / `num` / `bool` values are native on both sides (they
 *     travel as a tagged `SomValue`, C having no dynamic `Object?`);
 *   - enum values travel as validated **constant-name strings** at this generic
 *     layer (`"high"`), because the generic API has no generated enum types —
 *     only the facade layer converts to native constants;
 *   - SOM_VALUE_NONE (or the empty string) clears a value (D4), which REMOVES
 *     the key rather than storing "";
 *   - reads are forgiving (unparsable stored text reads as SOM_VALUE_NONE),
 *     writes are strict (an error for a wrong value type or an out-of-domain
 *     enum name).
 *
 * Error idiom: every fallible operation returns 1 on success and 0 on failure,
 * writing an owned message to `*err` when `err` is non-NULL (the caller frees it
 * with `free`) — the `char **err` convention the rest of the runtime uses in
 * place of Dart's `ArgumentError`.
 *
 * Ownership: an editor borrows its document and model; both must outlive it. It
 * owns nothing, so there is no `spec_editor_free`.
 */
#ifndef SPEC_EDITOR_H
#define SPEC_EDITOR_H

#include "spec_document.h"
#include "spec_model.h"
#include "spec_reflection.h"
#include "spec_typed_values.h"

/* Generic, typed, meta-validated editing over a `SpecDocument`. */
typedef struct {
  SpecDocument *doc;         /* borrowed; the sparse value stores being edited */
  SpecReflection reflection; /* the value-free meta queries validated against */
} SpecEditor;

/* Builds the editor over an existing reflection surface. */
SpecEditor spec_editor_make(SpecDocument *doc, SpecReflection reflection);
/* Convenience: builds the editor for `doc` over `model`. */
SpecEditor spec_editor_for_model(SpecDocument *doc, const SpecModel *model);

/* ---- resolution ---------------------------------------------------------- */

/* Resolves `path` against the meta-model — the strict companion to
 * `spec_reflection_resolve`, failing for a dangling path. On success returns 1
 * and fills `*out` (free with `spec_resolution_free`); on failure returns 0 and
 * leaves `*out` untouched. */
int spec_editor_resolve(const SpecEditor *e, const char *path,
                        SpecResolution *out, char **err);

/* ---- value leaves (content / scalar / enum / scalar list item) ----------- */

/* The typed value at the value leaf `path`, written to `*out`
 * (SOM_VALUE_NONE when unset or unparsable). The kind follows the model:
 * int/double/num/bool scalars yield the parsed native value, an enum leaf the
 * validated constant name, everything else the raw string. Returns 0 when
 * `path` is dangling or is not a value leaf. The caller releases `*out` with
 * `som_value_free`. */
int spec_editor_value(const SpecEditor *e, const char *path, SomValue *out,
                      char **err);

/* Sets the value leaf at `path` to `v`, converting at the store boundary.
 *
 * SOM_VALUE_NONE (or a NULL `v`) clears. For a typed scalar `v` must be the
 * native kind — or a string, which is taken verbatim, the plain-text
 * serialization being authoritative; for an enum leaf `v` must be one of the
 * field's constant names. Returns 0 for a non-leaf path, a wrong value kind, or
 * an out-of-domain enum name. */
int spec_editor_set_value(SpecEditor *e, const char *path, const SomValue *v,
                          char **err);

/* ---- headlines (YRD3) ---------------------------------------------------- */

/* The stored headline at `path`, written to `*out` as a **borrowed** pointer
 * (NULL when the section renders its effective default title; valid until the
 * document is mutated). Returns 0 for a dangling path. */
int spec_editor_headline(const SpecEditor *e, const char *path,
                         const char **out, char **err);

/* Sets the stored headline at `path`; NULL/empty returns the section to its
 * default title. Returns 0 for a dangling path. */
int spec_editor_set_headline(SpecEditor *e, const char *path,
                             const char *value, char **err);

/* ---- typed form fields --------------------------------------------------- */

/* The typed value of form `field` at the `@Form` section `path`, written to
 * `*out` (SOM_VALUE_NONE when unset or unparsable). Returns 0 for a dangling
 * path, a non-form node, or an unknown field name. The caller releases `*out`
 * with `som_value_free`. */
int spec_editor_form_value(const SpecEditor *e, const char *path,
                           const char *field, SomValue *out, char **err);

/* Sets form `field` at the `@Form` section `path` to the typed value `v`
 * (SOM_VALUE_NONE / NULL clears), converting through the shared boundary
 * helpers. Returns 0 for a wrong value kind or an out-of-domain enum name. */
int spec_editor_set_form_value(SpecEditor *e, const char *path,
                               const char *field, const SomValue *v,
                               char **err);

/* The form-field specs of the `@Form` section at `path`, in declaration order —
 * the meta a generic editor UI renders from. On success returns 1 and writes a
 * **borrowed** array (into the model) plus its length; returns 0 for a dangling
 * path or a non-form node. Either out-parameter may be NULL. */
int spec_editor_form_fields(const SpecEditor *e, const char *path,
                            const FormFieldSpec **out, size_t *out_len,
                            char **err);

/* ---- structural operations ----------------------------------------------- */

/* Appends a new item to the list at `list_path` and writes its stable item path
 * (owned; caller frees) to `*out_item_path`.
 *
 * When the list field carries a `@SectionIdPattern` and `section_id` is NULL, a
 * fresh id is generated from the pattern (`spec_generate_list_item_section_id`)
 * dated `month`/`day` — pass a non-positive `month` or `day` for today. An
 * explicit `section_id` is uniqueness-checked against the list's other items.
 *
 * Takes the date as month/day integers rather than a date type because the
 * shared id helper is language-neutral and does the same. Returns 0 for a
 * dangling path or a non-list node (message in `*err`), and 0 on a section-id
 * collision (detail in `*id_err`, message in `*err`). Both `err` and `id_err`
 * may be NULL. */
int spec_editor_add_list_item(SpecEditor *e, const char *list_path,
                              const char *section_id, long long month,
                              long long day, char **out_item_path,
                              SpecSectionIdError *id_err, char **err);

/* Removes the list item at `item_path` with every value beneath it. Returns 1
 * when an item was found and removed. (Unvalidated against the model, exactly
 * like the Dart/Python ports: an unknown path is simply "nothing removed".) */
int spec_editor_remove_list_item(SpecEditor *e, const char *item_path);

/* Clears every value at `path` and beneath it — content, form entries, nested
 * list items, stored headlines and ids — returning the subtree to the untouched
 * "empty = no value" state (D4). The node itself remains addressable (structure
 * lives in the model, not the document). Returns 0 for a dangling path. */
int spec_editor_clear_section(SpecEditor *e, const char *path, char **err);

#endif /* SPEC_EDITOR_H */
