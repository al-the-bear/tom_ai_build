#include "spec_schema_validation.hpp"

#include "spec_document_markdown.hpp"

namespace som {

std::vector<DocSpecsViolation> validateSpecDocument(
    const SpecModel& model, const SpecDocument& document,
    const DocSpecsSchema& schema, const std::string& rootType) {
  SpecMarkdownRendition rendition = document.toMarkdownWithMap(model, rootType);
  std::vector<DocSpecsViolation> out;
  DocSpecsValidator(schema).validateMarkdown(rendition.markdown, out);
  for (DocSpecsViolation& v : out) {
    if (!v.path.empty()) {
      continue;
    }
    if (const std::string* path = rendition.pathAtLine(v.line)) {
      v.path = *path;
    }
  }
  return out;
}

}  // namespace som
