/* spec_document_assembly — assembling one spec document from fragments written
 * in parallel, a port of the Dart reference `spec_document_assembly.dart`.
 *
 * A large document is often authored in parts — one group, or one agent, per
 * set of sections — each part a document of its own holding a subset of the
 * sections. References between parts can only be judged on the whole: the
 * instance tier resolves a `refersTo` against the document it is given, so a
 * part validated alone reports every reference into another part as dangling.
 * SpecDocument::assemble is the step that produces the whole.
 *
 * The merge is over the plain-data stores (SpecDocument::toJson), and it is
 * **refusing**: a value two fragments both write — a content path, a form
 * field, a list, a headline, a code-spec location — is an overlap, and an
 * assembly with any overlap yields no document. Choosing a winner would make
 * the result depend on fragment order, and two parts writing one place is an
 * authoring conflict the parts' authors have to settle.
 *
 *   - content / headlines / codeSpecs: one value per path; a path written by
 *     two or more fragments is an overlap.
 *   - forms: merged field by field — two fragments may fill different fields
 *     of one form; a (path, field) written by two or more is an overlap.
 *   - lists: a list path held by two or more fragments is an overlap (the
 *     whole list — seq, items, ids — comes from one fragment).
 *
 * Overlaps are reported in store order content, forms, lists, headlines,
 * codeSpecs, then by path (and field) byte-sorted, each naming its fragments
 * in the order they were given.
 */
#ifndef SPEC_DOCUMENT_ASSEMBLY_HPP
#define SPEC_DOCUMENT_ASSEMBLY_HPP

#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "spec_document.hpp"

namespace som {

/* One place two or more fragments both write. */
struct SpecAssemblyOverlap {
  /* The store: `content`, `forms`, `lists`, `headlines` or `codeSpecs`. */
  std::string store;
  /* The document path. */
  std::string path;
  /* The form field, for the `forms` store; std::nullopt otherwise. */
  std::optional<std::string> field;
  /* The fragments that write it, in the order they were given. */
  std::vector<std::string> fragments;

  /* One sentence naming the place and every fragment that writes it. */
  std::string message() const;
};

/* The result of SpecDocument::assemble. */
struct SpecDocumentAssembly {
  /* The assembled document; std::nullopt when there is any overlap. */
  std::optional<SpecDocument> document;
  /* Every overlap, in store order and then path order. */
  std::vector<SpecAssemblyOverlap> overlaps;

  /* Whether the fragments assembled. */
  bool ok() const { return overlaps.empty(); }
};

/* Merges `fragments` — an ordered sequence of name/document pairs — into one
 * document. See the file comment for the refusing rule. Equivalent to
 * SpecDocument::assemble. */
SpecDocumentAssembly assembleSpecDocuments(const SpecAssemblyFragments& fragments);

}  // namespace som

#endif  // SPEC_DOCUMENT_ASSEMBLY_HPP
