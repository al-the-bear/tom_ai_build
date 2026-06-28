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
#include <string>
#include <vector>

#include "som_json.hpp"

namespace som {

/* ---- DocumentJson — plain-data view for persistence --------------------- */

struct DocListEntry {
  long long seq = 0;
  std::vector<std::string> items;
};

/* The byte-sorted std::maps give the deterministic iteration order the C port
 * achieved with sorted dynamic arrays. */
struct DocumentJson {
  std::map<std::string, std::string> content;             // path -> value
  std::map<std::string, std::map<std::string, std::string>> forms;  // path -> fields
  std::map<std::string, DocListEntry> lists;              // listPath -> entry

  bool empty() const {
    return content.empty() && forms.empty() && lists.empty();
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

  // content leaves
  std::string content(const std::string& path) const;  // "" when unset
  void setContent(const std::string& path,
                  const std::string& value);  // empty clears

  /* Distinguish "unset" from "set to empty": the C API returned a NULL pointer
   * for unset. The conformance harness needs that distinction (op[].content
   * checks val == NULL). content() returns "" for both; contentOpt() is the
   * NULL-aware accessor. */
  const std::string* contentOpt(const std::string& path) const;

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

  bool isEmpty() const;
  bool hasValuesUnder(const std::string& prefix) const;

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

  void purgeUnder(const std::string& prefix);
};

}  // namespace som

#endif  // SPEC_DOCUMENT_HPP
