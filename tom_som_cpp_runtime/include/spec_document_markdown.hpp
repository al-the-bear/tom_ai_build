/* spec_document_markdown — generic, meta-data-driven Markdown codec for a
 * TomSpecs document, an idiomatic-C++ port of the C `spec_document_markdown`
 * module (the §4.1 DocScanner + generic meta-data markdown<->memory route).
 *
 * A `<!-- docspec: -->` header, then one heading per populated section (sparse,
 * in schema order), with each section's machine-readable section path as the
 * first token of its heading. Leaf values live in fenced code blocks whose fence
 * is widened past any backtick run in the value. Form fields are introduced by a
 * `<!-- field: name -->` anchor; list items appear as nested `…-N` sections.
 *
 * `markdownParse` does not mutate the document — it returns staged values keyed
 * exactly like DocumentJson plus a rejection report; the caller applies them.
 */
#ifndef SPEC_DOCUMENT_MARKDOWN_HPP
#define SPEC_DOCUMENT_MARKDOWN_HPP

#include <cstddef>
#include <set>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"

namespace som {

inline constexpr const char* kSpecMarkdownRejectUnknownSection =
    "unknownSection";
inline constexpr const char* kSpecMarkdownRejectKindMismatch = "kindMismatch";
inline constexpr const char* kSpecMarkdownRejectOrphanBlock = "orphanBlock";
inline constexpr const char* kSpecMarkdownRejectMissingValue = "missingValue";
inline constexpr const char* kSpecMarkdownRejectMalformedHeading =
    "malformedHeading";

struct SpecMarkdownRejection {
  std::size_t line = 0;
  std::string reason;   // one of the reject literals
  std::string message;
  std::string anchor;

  /* Renders as `line N: reason (anchor) — message`. */
  std::string display() const;
};

struct SpecMarkdownResult {
  DocumentJson staged;  // content/forms staged values; lists reconstructed
  std::vector<SpecMarkdownRejection> rejections;
  std::set<std::string> rootPrefixes;  // byte-sorted set of root segments seen

  /* Reports whether no block was rejected. */
  bool isClean() const { return rejections.empty(); }

  /* The staged values as a DocumentJson (load via SpecDocument::loadJson). */
  const DocumentJson& document() const { return staged; }
};

/* Renders the populated subtree of `root` as Markdown with a docspec header. */
std::string markdownExportRoot(const SpecModel& model,
                               const SpecDocument& document,
                               const SpecRoot& root);

/* Parses `text` into staged values + a rejection report. */
SpecMarkdownResult markdownParse(const SpecModel& model, const std::string& text);

}  // namespace som

#endif  // SPEC_DOCUMENT_MARKDOWN_HPP
