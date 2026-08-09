/* spec_document — a sparse, live instance of a TomSpecs document, an idiomatic
 * C++ port of the C `spec_document` module.
 *
 * Three sparse stores cover the writable field kinds, all byte-sorted by key
 * (std::map<std::string,...> iterates in byte order for std::string keys, which
 * is exactly the strcmp ordering the C SomMap kept — the byte-stable codecs rely
 * on it):
 *   - content     — content/scalar leaves: path -> string value;
 *   - forms       — `@Form` sections: path -> (form-field name -> value);
 *   - listItems   — lists: list path -> ordered item paths.
 *
 * List item paths are `<listPath>-<seq>` where seq is a per-list monotonic
 * counter that never reuses a number.
 */
#ifndef SPEC_DOCUMENT_HPP
#define SPEC_DOCUMENT_HPP

#include <cstddef>
#include <map>
#include <optional>
#include <string>
#include <vector>

#include "som_json.hpp"

namespace som {

class SpecModel;    // fwd (spec_model.hpp), used by SpecDocument::toMarkdown
class SomMetaTree;  // fwd (spec_meta.hpp), used by SpecDocument::fromYaml

/* ---- DocumentJson — plain-data view for persistence --------------------- */

struct DocListEntry {
  long long seq = 0;
  std::vector<std::string> items;
  /* item path -> its assigned document section id (criteria 3–6). Emitted in
   * canonical JSON only when non-empty; not carried through YAML. */
  std::map<std::string, std::string> ids;
};

/* The byte-sorted std::maps give the deterministic iteration order the C port
 * achieved with sorted dynamic arrays. */
struct DocumentJson {
  std::map<std::string, std::string> content;             // path -> value
  std::map<std::string, std::map<std::string, std::string>> forms;  // path -> fields
  std::map<std::string, DocListEntry> lists;              // listPath -> entry
  /* path -> stored headline (YRD3). Emitted in canonical JSON only when
   * non-empty, after `lists`. */
  std::map<std::string, std::string> headlines;
  /* path -> stored codeSpec mapping (codespecs_mapping.md §9.2), the comma-joined list of code
   * locations. Byte-for-byte structural mirror of `headlines`: emitted in
   * canonical JSON only when non-empty, after `headlines`. */
  std::map<std::string, std::string> codeSpecs;

  bool empty() const {
    return content.empty() && forms.empty() && lists.empty() &&
           headlines.empty() && codeSpecs.empty();
  }
};

/* Builds a DocumentJson from a parsed `{content,forms,lists}` JSON value. */
DocumentJson documentJsonFromJson(const JsonRef& v);

/* Renders a deterministic canonical JSON string (byte-sorted keys, fixed field
 * order content/forms/lists, omitting empty stores). */
std::string documentJsonToCanonicalJson(const DocumentJson& d);

/* ---- SpecDocument — the live sparse document ---------------------------- */

class SpecDocument {
 public:
  SpecDocument() = default;

  /* The authoring object-model version (major.minor) this document was loaded
   * from, or "" for a brand-new / unstamped document. Retained here by fromYaml
   * so a consumer need not thread decodeYaml(...).modelVersion to the typed
   * facade by hand; the generated loadYaml / loadFile statics apply it
   * automatically. */
  std::string modelVersion;

  /* Loads a `*.docspecs.yaml` document in one call: decode the hierarchical v2
   * YAML against `tree` (the metadata tree of the document's root), populate
   * the sparse stores, and retain the parsed model version on the document (SOM
   * §21). Returns std::nullopt on a format error and, when `err` is
   * non-null, writes a message — nothing is silently dropped. */
  static std::optional<SpecDocument> fromYaml(const std::string& yaml,
                                              const SomMetaTree& tree,
                                              std::string* err);

  /* Loads a `*.docspecs.yaml` document from the file at `path` — the file
   * companion to fromYaml the generated loadFile static delegates to. Returns
   * std::nullopt (writing `*err`) when the file cannot be read or fails to
   * decode. */
  static std::optional<SpecDocument> fromFile(const std::string& path,
                                              const SomMetaTree& tree,
                                              std::string* err);

  /* Renders this document to Markdown in one call (SOM §21).
   *
   * Collapses the former markdownExportRoot(model, doc,
   * model.rootByType(...)) sequence. When `rootType` is non-empty, that root is
   * exported (via SpecModel::rootByType); when empty, the document's single
   * populated root is used — a root is populated when it has any value beneath
   * its segment (sectionId if present else type). Throws std::runtime_error
   * when the default is ambiguous — zero populated roots, or more than one —
   * so the caller names `rootType` explicitly. */
  std::string toMarkdown(const SpecModel& model,
                         const std::string& rootType = "") const;

  // content leaves
  std::string content(const std::string& path) const;  // "" when unset
  void setContent(const std::string& path,
                  const std::string& value);  // empty clears

  /* Distinguish "unset" from "set to empty": the C API returned a NULL pointer
   * for unset. The conformance harness needs that distinction (op[].content
   * checks val == NULL). content() returns "" for both; contentOpt() is the
   * NULL-aware accessor. */
  const std::string* contentOpt(const std::string& path) const;

  /* True iff a non-empty content leaf exists at EXACTLY `path` (leaf-exact; a
   * value nested beneath `path` does NOT count). Null-free companion to
   * content() — aligns the typed facade's fill check with the generic API
   * (SOM §21). */
  bool hasContent(const std::string& path) const;

  // form fields
  std::string formField(const std::string& path,
                        const std::string& fieldName) const;  // "" unset
  const std::string* formFieldOpt(const std::string& path,
                                  const std::string& fieldName) const;
  void setFormField(const std::string& path, const std::string& fieldName,
                    const std::string& value);

  // lists
  std::vector<std::string> listItems(const std::string& listPath) const;
  /* Borrowed pointer to the live item vector, or nullptr when none. */
  const std::vector<std::string>* listItemsPtr(const std::string& listPath) const;
  std::size_t listItemCount(const std::string& listPath) const;
  std::string addListItem(const std::string& listPath);  // returns new item path
  bool removeListItem(const std::string& itemPath);

  // section ids (criteria 3–6)
  /* Appends a new item to `listPath` carrying `sectionId`. Throws
   * SomSectionIdError (Collision) when `sectionId` is already used by another
   * item of the same list. Returns the new item's stable path. */
  std::string addListItemWithSectionId(const std::string& listPath,
                                       const std::string& sectionId);
  /* The document section id assigned to `itemPath`, or "" when none. */
  std::string itemSectionId(const std::string& itemPath) const;
  const std::string* itemSectionIdOpt(const std::string& itemPath) const;
  /* Sets `itemPath`'s section id. Throws SomSectionIdError: NotLiveItem when the
   * path is not a live list item; Collision when `id` is used by a sibling. */
  void setItemSectionId(const std::string& itemPath, const std::string& id);
  /* The section ids assigned to `listPath`'s items, in item order (items with no
   * assigned id are skipped). */
  std::vector<std::string> listItemSectionIds(const std::string& listPath) const;

  // stored headlines (YRD3)
  /* The stored headline at `path`, or "" when unset. */
  std::string headline(const std::string& path) const;
  /* NULL-aware companion: nullptr when no headline is stored at `path`. */
  const std::string* headlineOpt(const std::string& path) const;
  /* Stores a headline override at `path`; an empty value clears it. */
  void setHeadline(const std::string& path, const std::string& value);
  /* All paths carrying a stored headline, byte-sorted. */
  std::vector<std::string> headlinePaths() const;

  // stored codeSpec mappings (codespecs_mapping.md §9.2) — structural mirror of
  // stored headlines
  /* The stored codeSpec mapping at `path`, or "" when unset. */
  std::string codeSpec(const std::string& path) const;
  /* NULL-aware companion: nullptr when no codeSpec is stored at `path`. */
  const std::string* codeSpecOpt(const std::string& path) const;
  /* Stores a codeSpec mapping at `path`; an empty value clears it. */
  void setCodeSpec(const std::string& path, const std::string& value);
  /* All paths carrying a stored codeSpec mapping, byte-sorted. */
  std::vector<std::string> codeSpecPaths() const;

  bool isEmpty() const;
  bool hasValuesUnder(const std::string& prefix) const;

  /* Removes every value at `prefix` and beneath it — content leaves, form
   * entries, list items (with their nested values, assigned section ids and
   * sequence counters) and stored headlines — for every key that is `prefix`
   * itself or nested under it (`prefix/...` or `prefix-...`).
   *
   * The public face of the purge the removal paths already use internally; the
   * generic SpecEditor::clearSection is built on it, so "clear this subtree"
   * is one operation rather than a store-by-store walk at the call site. The
   * structure itself is untouched: it lives in the model, not the document, so
   * the node stays addressable and simply holds no value again (D4). */
  void removeValuesUnder(const std::string& prefix);

  // enumerations (all byte-sorted)
  std::vector<std::string> contentPaths() const;
  std::vector<std::string> formPaths() const;
  std::vector<std::string> listPaths() const;
  std::vector<std::string> formFieldNames(const std::string& path) const;

  // persistence
  DocumentJson toJson() const;
  void loadJson(const DocumentJson& j);

 private:
  std::map<std::string, std::string> content_;
  std::map<std::string, std::map<std::string, std::string>> forms_;
  std::map<std::string, std::vector<std::string>> listItems_;
  std::map<std::string, long long> listSeq_;
  std::map<std::string, std::string> itemSectionId_;  // item path -> section id
  std::map<std::string, std::string> headline_;       // path -> stored headline
  std::map<std::string, std::string> codeSpec_;       // path -> stored codeSpec

  void purgeUnder(const std::string& prefix);

  /* Returns the listItems_ key that owns `itemPath`, or "" when none does. */
  std::string owningListOf(const std::string& itemPath) const;
  /* Throws SomSectionIdError(Collision) when `id` is already used by an item of
   * `listPath` other than `exceptItemPath` (empty for none). */
  void assertSectionIdFree(const std::string& listPath, const std::string& id,
                           const std::string& exceptItemPath) const;
};

}  // namespace som

#endif  // SPEC_DOCUMENT_HPP
