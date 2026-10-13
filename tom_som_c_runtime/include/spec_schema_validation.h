/* spec_schema_validation — the DocSpecs schema tier over a SOM document, with
 * each finding bound to the document path it is about (SOM §14).
 *
 * The DocSpecs validator judges Markdown and knows nothing of the document it
 * came from, so its findings name a section id and a rendition line. A section
 * id repeats across a document — every functional requirement has a `FRED`
 * form — so the id alone does not say which node to fix. The renderer is the
 * one place that knows which node each heading came from
 * (`spec_document_to_markdown_with_map`); this entry point renders, validates,
 * and fills `DocSpecsViolation.path` from that map.
 */
#ifndef SPEC_SCHEMA_VALIDATION_H
#define SPEC_SCHEMA_VALIDATION_H

#include "docspecs_validator.h"
#include "spec_document.h"
#include "spec_model.h"

/* Renders `document` (root `root_type` when non-NULL and non-empty, else its
 * single populated root), validates the rendition against `schema`, and
 * appends every finding to `*out` (init/free with docspecs_violation_list_*)
 * with `path` set to the document path of the section its line belongs to; a
 * path the validator already set is kept. A finding about a missing child
 * names the **parent** — the section whose heading its line points at —
 * exactly as its `section_id` does.
 *
 * Returns 1 on success; when the document cannot be rendered (unknown or
 * ambiguous root, an unrepresentable value) returns 0, appends nothing, and
 * writes an owned message to `*err` when non-NULL. */
int validate_spec_document(const SpecModel *model, const SpecDocument *document,
                           const DocSpecsSchema *schema, const char *root_type,
                           DocSpecsViolationList *out, char **err);

#endif /* SPEC_SCHEMA_VALIDATION_H */
