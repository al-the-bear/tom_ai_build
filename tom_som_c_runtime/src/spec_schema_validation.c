/* spec_schema_validation — see include/spec_schema_validation.h. */

#include "spec_schema_validation.h"

#include <stdlib.h>

#include "som_util.h"
#include "spec_document_markdown.h"

int validate_spec_document(const SpecModel *model, const SpecDocument *document,
                           const DocSpecsSchema *schema, const char *root_type,
                           DocSpecsViolationList *out, char **err) {
  SpecMarkdownRendition rendition;
  if (!spec_document_to_markdown_with_map(document, model, root_type,
                                          &rendition, err)) {
    return 0;
  }
  DocSpecsValidator val = docspecs_validator_new(schema);
  size_t first = out->len;
  docspecs_validator_validate_markdown(&val, rendition.markdown, out);
  for (size_t i = first; i < out->len; i++) {
    DocSpecsViolation *v = &out->items[i];
    if (v->path[0] != '\0') {
      continue;
    }
    const char *path =
        spec_markdown_rendition_path_at_line(&rendition, v->line);
    if (path != NULL) {
      free(v->path);
      v->path = som_strdup(path);
    }
  }
  spec_markdown_rendition_free(&rendition);
  return 1;
}
