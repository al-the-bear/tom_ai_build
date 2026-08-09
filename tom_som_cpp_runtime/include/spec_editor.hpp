/* spec_editor — the generic, meta-model-driven modification API (YRD7), an
 * idiomatic-C++ port of the Dart `spec_editor` library.
 *
 * SpecEditor lets a consumer walk any document's meta tree and
 * create/modify/delete sections, list items, headlines, ids, content and
 * **typed** form fields *without a generated facade*: every operation resolves
 * its path against the SpecModel first (SpecReflection::resolve) and converts
 * values at the store boundary through the same `spec_typed_values` helpers the
 * generated accessors call — so a typed facade is provably a thin layer over
 * exactly this API.
 *
 * Typed contract (mirrored by all nine runtimes):
 *   - `int` / `double` / `num` / `bool` values are native on both sides;
 *   - enum values travel as validated **constant-name strings** at this generic
 *     layer (`high`), because the generic API has no generated enum types —
 *     only the facade layer converts to native constants;
 *   - a null SomValue (or the empty string) clears a value (D4);
 *   - reads are forgiving (unparsable stored text reads as no value), writes are
 *     strict (std::invalid_argument for a wrong type or an out-of-domain enum
 *     name).
 *
 * Ownership: the editor borrows both the document it edits and the model behind
 * its reflection; both must outlive it.
 */
#ifndef SPEC_EDITOR_HPP
#define SPEC_EDITOR_HPP

#include <optional>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"
#include "spec_reflection.hpp"
#include "spec_typed_values.hpp"

namespace som {

/* Generic, typed, meta-validated editing over a SpecDocument. */
class SpecEditor {
 public:
  /* Builds the editor over an existing reflection surface. */
  SpecEditor(SpecDocument& document, const SpecReflection& reflection)
      : document_(document), reflection_(reflection) {}

  /* Convenience: builds the editor for `document` over `model`. */
  SpecEditor(SpecDocument& document, const SpecModel& model)
      : document_(document), reflection_(model) {}

  /* The document being edited (the sparse value stores). */
  SpecDocument& document() const { return document_; }
  /* The value-free meta-model queries the editor validates against. */
  const SpecReflection& reflection() const { return reflection_; }

  // --- resolution ----------------------------------------------------------

  /* Resolves `path` against the meta-model, throwing std::invalid_argument for
   * a dangling path — the strict companion to SpecReflection::resolve. */
  SpecResolution resolve(const std::string& path) const;

  // --- value leaves (content / scalar / enum / scalar list item) -----------

  /* The typed value at the value leaf `path`, or a null SomValue when unset.
   *
   * The kind follows the model: `int`/`double`/`num`/`bool` scalars return the
   * parsed native value, enum leaves the validated constant name, everything
   * else the raw string. Throws std::invalid_argument when `path` is not a
   * value leaf. */
  SomValue value(const std::string& path) const;

  /* Sets the value leaf at `path` to `v`, converting at the store boundary.
   *
   * A null SomValue clears. For typed scalars `v` must be the native kind (or a
   * string, taken verbatim); for enum leaves `v` must be one of the field's
   * constant names. Throws std::invalid_argument for a non-leaf path, a wrong
   * value kind, or an out-of-domain enum name. */
  void setValue(const std::string& path, const SomValue& v);

  // --- headlines (YRD3) ----------------------------------------------------

  /* The stored headline at `path`, or no value when the section renders its
   * effective default title. */
  std::optional<std::string> headline(const std::string& path) const;

  /* Sets the stored headline at `path`; an empty value returns the section to
   * its default title. */
  void setHeadline(const std::string& path, const std::string& value);

  // --- typed form fields ---------------------------------------------------

  /* The typed value of form `field` at the `@Form` section `path`, or a null
   * SomValue when unset.
   *
   * Reads the form store and parses per the declared field type (enum fields
   * return the validated constant name). Throws std::invalid_argument for a
   * non-form path or an unknown field name. */
  SomValue formValue(const std::string& path, const std::string& field) const;

  /* Sets form `field` at the `@Form` section `path` to the typed value `v` (a
   * null SomValue clears), converting through the shared boundary helpers.
   *
   * Throws std::invalid_argument for a wrong value kind or an out-of-domain
   * enum name. */
  void setFormValue(const std::string& path, const std::string& field,
                    const SomValue& v);

  /* The form-field specs of the `@Form` section at `path`, in declaration
   * order — the meta a generic editor UI renders from. Throws
   * std::invalid_argument for a non-form path. */
  std::vector<FormFieldSpec> formFields(const std::string& path) const;

  // --- structural operations ------------------------------------------------

  /* Appends a new item to the list at `listPath` and returns its stable item
   * path.
   *
   * When the list field carries a `@SectionIdPattern` and no explicit
   * `sectionId` is given, a fresh id is generated from the pattern
   * (specGenerateListItemSectionId) dated `month`/`day` — both defaulting to
   * today. The month/day pair rather than a date type is deliberate: the shared
   * id generator is language-neutral and takes exactly that. An explicit
   * `sectionId` is uniqueness-checked against the list's other items (throwing
   * SomSectionIdError on a clash). Throws std::invalid_argument when `listPath`
   * is not a list. */
  std::string addListItem(const std::string& listPath,
                          const std::string& sectionId = "",
                          std::optional<long long> month = std::nullopt,
                          std::optional<long long> day = std::nullopt);

  /* Removes the list item at `itemPath` with every value beneath it. Returns
   * true when an item was found and removed. */
  bool removeListItem(const std::string& itemPath);

  /* Clears every value at `path` and beneath it — content, form entries, nested
   * list items, stored headlines and ids — returning the subtree to the
   * untouched "empty = no value" state (D4). The node itself remains
   * addressable (structure lives in the model, not the document). Throws
   * std::invalid_argument for a dangling path. */
  void clearSection(const std::string& path);

 private:
  SpecDocument& document_;    // borrowed; the document this editor edits
  SpecReflection reflection_;  // borrows the model; value-free

  /* Resolves `path` and asserts it is a value leaf. */
  SpecResolution valueLeaf(const std::string& path) const;
  /* Resolves `path` as a `@Form` section and returns its field named `field`
   * (a copy — the model outlives the call, but a value keeps the caller free of
   * the borrow). */
  FormFieldSpec formFieldSpec(const std::string& path,
                              const std::string& field) const;

  /* Formats `v` for the store per the leaf's declared type; strings pass
   * through verbatim (the plain-text serialization is authoritative).
   *
   * `typeName` overrides the field's declared type (the form-field path, whose
   * type lives on the FormFieldSpec rather than the SpecField); `where` names
   * the position in the error message. */
  std::string format(const SomValue& v, const std::string& kind,
                     const SpecField* field, const std::string& path,
                     const std::string& typeName = "",
                     const std::string& where = "") const;
};

}  // namespace som

#endif  // SPEC_EDITOR_HPP
