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

  SpecDocument& doc() const { return doc_; }
  const std::string& path() const { return path_; }

 private:
  SpecDocument& doc_;  // borrowed; the document this node edits
  std::string path_;   // owned; the node's globally-unique section path
};

/* ---- SomList — a typed view over a list field --------------------------- */

class SomList : public SomNode {
 public:
  SomList(SpecDocument& doc, std::string path)
      : SomNode(doc, std::move(path)) {}

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

  /* Appends a new item and returns its stable path. */
  std::string add() { return doc().addListItem(path()); }

  /* Removes the item at `index` and everything nested beneath it. */
  void removeAt(std::size_t index) {
    std::string p = itemPathAt(index);
    if (!p.empty()) {
      doc().removeListItem(p);
    }
  }
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

/* The instantiation-time check every generated root facade performs.
 * `generated` is the object model's own major.minor; `documentVersion` is the
 * document's recorded stamp ("" for a never-stamped document).
 *
 * Rules: empty stamp accepted; same major + doc-minor <= gen-minor editable;
 * doc-minor greater rejected; different major rejected. On rejection it THROWS
 * SomVersionError. */
void checkSomModelVersion(const std::string& generated,
                          const std::string& documentVersion);

}  // namespace som

#endif  // SOM_FACADE_HPP
