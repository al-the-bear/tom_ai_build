/* som_facade — runtime support for the generated typed object model, an
 * idiomatic-C++ port of the C `som_facade` module.
 *
 * The generated classes are a thin editing facade over the generic
 * `SpecDocument`: every typed accessor reads or writes the path-keyed memory
 * representation directly, so a mutation through the typed surface is immediately
 * visible through the generic path and vice-versa.
 *
 * The one document is shared by **borrowed reference** (`SpecDocument&`). Every
 * facade node holds that reference plus the globally-unique section path it
 * lives at (owned). The document must outlive every facade bound to it.
 *
 * This is the idiomatic-C++ form the `som_cpp_emitter` generated code depends on
 * — it is NOT a 1:1 of the C accessor-function signatures.
 */
#ifndef SOM_FACADE_HPP
#define SOM_FACADE_HPP

#include <cstddef>
#include <exception>
#include <string>
#include <vector>

#include "spec_document.hpp"

namespace som {

/* ---- SomNode — the base every generated facade class derives from ------- */

class SomNode {
 public:
  SomNode(SpecDocument& doc, std::string path)
      : doc_(doc), path_(std::move(path)) {}

  /* Virtual so a derived facade destroys cleanly through a SomNode reference —
   * required now that the class carries virtual behaviour (canHaveContent). */
  virtual ~SomNode() = default;

  SpecDocument& doc() const { return doc_; }
  const std::string& path() const { return path_; }

  /* The document section id assigned to this node, or "" when none. Meaningful
   * for a list item; "" for ordinary fixed-id sections. */
  std::string sectionId() const { return doc_.itemSectionId(path_); }

  /* True iff this section holds no value at its path or nested beneath it —
   * the typed-facade fill check, delegating to the generic hasValuesUnder so
   * both surfaces agree (SOM §21). Inherited by every generated section. */
  bool isEmpty() const { return !doc_.hasValuesUnder(path_); }

  /* Whether this TYPE declares the standard `content` text leaf — "*can* this
   * node hold body text?" answered structurally, at the type level, WITHOUT
   * probing the document (SOM §21). This is the base default: a type that
   * declares no `content` leaf — a `SomList` field view, for instance —
   * inherits this `false`; every generated *section* class overrides it to
   * `true`, since `tom_specs_model_rules.md` §10.2 requires `content: String?`
   * on all of them, pure containers included. `virtual` so the per-type answer
   * resolves polymorphically through a `SomNode` reference.
   *
   * It is deliberately distinct from the two STATE predicates: the generic
   * SpecDocument::hasContent answers "is a value present at this leaf *now*?"
   * and isEmpty() answers "is this subtree empty *now*?". canHaveContent never
   * looks at the document — it describes the model, not the data.
   *
   * It is also distinct from the AUTHORING statement `@Unused()`, which marks a
   * `content` member the model expects to stay empty
   * (`tom_specs_model_rules.md` §5.6). Those sections still report `true` — the
   * slot is declared and writable, and prose is possible even where it is not
   * expected. A consumer wanting "is prose expected here?" reads the content
   * node's `unused` flag in the metadata instead. */
  virtual bool canHaveContent() const { return false; }

  /* Overrides this node's section id (criterion 5). An empty id is a no-op.
   * Throws SomSectionIdError on a uniqueness collision or a non-live item. */
  void setSectionId(const std::string& id) {
    if (id.empty()) {
      return;
    }
    doc_.setItemSectionId(path_, id);
  }

  /* The stored headline override at this node's path, or "" when the section
   * renders its derived default title (YRD3). */
  std::string headline() const { return doc_.headline(path_); }

  /* Stores a headline override for this node; an empty value clears it back to
   * the derived default (YRD3). */
  void setHeadline(const std::string& value) {
    doc_.setHeadline(path_, value);
  }

  /* This section's CodeSpecs forward link (codespecs_mapping.md §9.2) as the
   * comma-joined list of code locations, or "" when the section carries no
   * mapping — sparse exactly like the stored headline. */
  std::string codeSpec() const { return doc_.codeSpec(path_); }

  /* Stores this section's CodeSpecs forward link (codespecs_mapping.md §9.2); an empty value clears
   * it, returning the section to "no code mapping". */
  void setCodeSpec(const std::string& value) {
    doc_.setCodeSpec(path_, value);
  }

 private:
  SpecDocument& doc_;  // borrowed; the document this node edits
  std::string path_;   // owned; the node's globally-unique section path
};

/* ---- SomList — a typed view over a list field --------------------------- */

class SomList : public SomNode {
 public:
  SomList(SpecDocument& doc, std::string path)
      : SomNode(doc, std::move(path)), pattern_() {}

  /* Constructor carrying the list field's `@SectionIdPattern` (empty when the
   * field has none). The generated source passes it so add() can derive a
   * section id for each new item (criteria 3–6). */
  SomList(SpecDocument& doc, std::string path, std::string pattern)
      : SomNode(doc, std::move(path)), pattern_(std::move(pattern)) {}

  /* Number of items in the list. */
  std::size_t length() const { return doc().listItemCount(path()); }

  /* Item path at `index`, or "" when out of range. */
  std::string itemPathAt(std::size_t index) const {
    const std::vector<std::string>* items = doc().listItemsPtr(path());
    if (items == nullptr || index >= items->size()) {
      return "";
    }
    return (*items)[index];
  }

  /* Every item path, in order. */
  std::vector<std::string> itemPaths() const { return doc().listItems(path()); }

  /* The section ids assigned to this list's items, in item order. */
  std::vector<std::string> sectionIds() const {
    return doc().listItemSectionIds(path());
  }

  /* Appends a new item and returns its stable path. When the list has a
   * `@SectionIdPattern`, the item is assigned a generated section id for today's
   * date (criteria 3–4, 6); otherwise it is a plain append. */
  std::string add();

  /* Like add() but for an explicit (month, day) — deterministic, clock-free. */
  std::string addOn(long long month, long long day);

  /* Appends a new item carrying the explicit `sectionId` (criterion 5). Throws
   * SomSectionIdError (Collision) when the id is already used by a sibling.
   * Returns the new item's stable path. */
  std::string addWithId(const std::string& sectionId);

  /* Appends a content-only item and sets its nested `<item>/content` leaf in one
   * call, then returns the new item's stable path. Mirrors add(): when the list
   * has a `@SectionIdPattern` the item is assigned a generated section id for
   * today's date, otherwise it is a plain append. (Scalar lists are out of scope
   * — this targets the nested content leaf.) */
  std::string addContent(const std::string& content);

  /* Like addContent() but for an explicit (month, day) — deterministic,
   * clock-free (mirrors addOn()). */
  std::string addContentOn(const std::string& content, long long month,
                           long long day);

  /* Like addContent() but carrying the explicit `sectionId` (mirrors
   * addWithId()). Throws SomSectionIdError (Collision) on a sibling id clash. */
  std::string addContentWithId(const std::string& content,
                               const std::string& sectionId);

  /* An ordered, read-only view of every item's nested `<item>/content` leaf; a
   * missing leaf coalesces to "" (the runtime's absent-content value). */
  std::vector<std::string> contents() const;

  /* Removes the item at `index` and everything nested beneath it. */
  void removeAt(std::size_t index) {
    std::string p = itemPathAt(index);
    if (!p.empty()) {
      doc().removeListItem(p);
    }
  }

 private:
  std::string pattern_;

  /* Generates a section id from the pattern for `(month, day)` and appends an
   * item carrying it. The generated id is unique by construction. */
  std::string addGenerated(long long month, long long day);

  /* Shared append-and-derive-path helper backing both add()/addOn()/addWithId()
   * and their addContent* companions (Dart reference `_addItemPath`): a plain
   * append when the list has no pattern and no explicit id, otherwise an append
   * carrying the derived-or-explicit section id. Returns the new item's path. */
  std::string addItemPath(long long month, long long day);
  std::string addItemPathWithId(const std::string& sectionId);
};

/* ---- path join ---------------------------------------------------------- */

/* Joins `parent` with `segment` using the path separator (delegates to
 * specPathJoin). The generated source calls `som::joinPath(path(), "seg")`. */
std::string joinPath(const std::string& parent, const std::string& segment);

/* ---- model-version guard ------------------------------------------------ */

/* Thrown by checkSomModelVersion on a rejected model-version check. */
class SomVersionError : public std::exception {
 public:
  explicit SomVersionError(std::string message)
      : message_(std::move(message)) {}
  const char* what() const noexcept override { return message_.c_str(); }

 private:
  std::string message_;
};

/* The outcome of the SOM §4.2 version check, as a value a read-only viewer can
 * branch on instead of catching SomVersionError (SOM §21). It is the
 * non-throwing companion to checkSomModelVersion: the root constructor throws
 * on any value other than editable, while somEditabilityFor returns the same
 * classification without throwing so a consumer can decide *open for edit* vs
 * *open read-only* up front. */
enum class SomEditability {
  /* The object model may edit the document in place — an empty stamp (a
   * brand-new document) or a same-major, minor-<= stamp. */
  editable,
  /* The document was authored under a different major version; it may be
   * read/converted but never edited in place. */
  readOnlyCrossMajor,
  /* The document is same-major but a newer minor than the object model; an
   * older model must not edit a newer document. */
  rejectedNewerMinor,
  /* One of the two versions is not a valid major.minor string — usually the
   * document stamp, but a malformed *generated* version lands here too. One
   * outcome with two causes; the refusal message thrown by
   * checkSomModelVersion is where they separate. */
  invalidVersion,
};

/* Classifies a document's editability under the SOM §4.2 rules WITHOUT throwing
 * (SOM §21). `generated` is the object model's own major.minor; the empty
 * string is the absent-stamp sentinel (CS4-D2) for `documentVersion` — a
 * brand-new, never-stamped document — and classifies as editable.
 *
 * This is the single definition of the version rules; checkSomModelVersion
 * throws based on the value returned here, so the two never diverge.
 *
 * TOTAL: every input pair is classified, including an unparseable `generated`
 * (invalidVersion). Nothing is thrown out of this function. */
SomEditability somEditabilityFor(const std::string& generated,
                                 const std::string& documentVersion);

/* The instantiation-time check every generated root facade performs.
 * `generated` is the object model's own major.minor; `documentVersion` is the
 * document's recorded stamp ("" for a never-stamped document).
 *
 * Rules: empty stamp accepted; same major + doc-minor <= gen-minor editable;
 * doc-minor greater rejected; different major rejected. Delegates the
 * classification to somEditabilityFor; on any non-editable outcome it THROWS
 * SomVersionError with the per-case message. */
void checkSomModelVersion(const std::string& generated,
                          const std::string& documentVersion);

}  // namespace som

#endif  // SOM_FACADE_HPP
