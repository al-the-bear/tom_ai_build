/* spec_schema_validation — the DocSpecs schema tier over a SOM document, with
 * each finding bound to the document path it is about (SOM §14).
 *
 * DocSpecsValidator judges Markdown and knows nothing of the document it came
 * from, so its findings name a section id and a rendition line. A section id
 * repeats across a document — every functional requirement has a `FRED` form
 * — so the id alone does not say which node to fix. The renderer is the one
 * place that knows which node each heading came from
 * (markdownExportRootWithMap); this entry point renders, validates, and fills
 * DocSpecsViolation::path from that map.
 */
#ifndef SPEC_SCHEMA_VALIDATION_HPP
#define SPEC_SCHEMA_VALIDATION_HPP

#include <string>
#include <vector>

#include "docspecs_validator.hpp"
#include "spec_document.hpp"
#include "spec_model.hpp"

namespace som {

/* Renders `document` (root `rootType`, else its single populated root),
 * validates the rendition against `schema`, and returns every finding with
 * `path` set to the document path of the section its line belongs to; a path
 * the validator already set is kept.
 *
 * A finding about a missing child names the **parent** — the section whose
 * heading its line points at — exactly as its `sectionId` does. Throws as
 * SpecDocument::toMarkdown does when the document cannot be rendered. */
std::vector<DocSpecsViolation> validateSpecDocument(
    const SpecModel& model, const SpecDocument& document,
    const DocSpecsSchema& schema, const std::string& rootType = "");

}  // namespace som

#endif  // SPEC_SCHEMA_VALIDATION_HPP
