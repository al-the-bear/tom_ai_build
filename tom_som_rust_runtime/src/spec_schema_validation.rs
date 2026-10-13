//! The DocSpecs schema tier over a SOM document, with each finding bound to
//! the document path it is about.
//!
//! [`DocSpecsValidator`] judges Markdown and knows nothing of the document it
//! came from, so its findings name a section id and a rendition line. A
//! section id repeats across a document — every functional requirement has a
//! `FRED` form — so the id alone does not say which node to fix. The renderer
//! is the one place that knows which node each heading came from
//! ([`SpecDocumentMarkdown::export_root_with_map`](crate::SpecDocumentMarkdown::export_root_with_map));
//! [`validate_spec_document`] renders, validates, and fills
//! [`DocSpecsViolation::path`] from that map.

use crate::docspecs_validator::{DocSpecsSchema, DocSpecsValidator, DocSpecsViolation};
use crate::spec_document::SpecDocument;
use crate::spec_model::SpecModel;

/// Renders `document` (root `root_type`, else its single populated root),
/// validates the rendition against `schema`, and returns every finding with
/// [`DocSpecsViolation::path`] set to the document path of the section its
/// line belongs to. A path the validator already set is kept.
///
/// A finding about a missing child names the **parent** — the section whose
/// heading its line points at — exactly as its `section_id` does. Returns the
/// render error ([`SpecDocument::to_markdown_with_map`]) when the document
/// cannot be rendered.
pub fn validate_spec_document(
    model: &SpecModel,
    document: &SpecDocument,
    schema: &DocSpecsSchema,
    root_type: Option<&str>,
) -> Result<Vec<DocSpecsViolation>, String> {
    let rendition = document.to_markdown_with_map(model, root_type)?;
    let found = DocSpecsValidator::new(schema.clone()).validate_markdown(&rendition.markdown);
    Ok(found
        .into_iter()
        .map(|mut v| {
            if v.path.is_empty() {
                v.path = rendition.path_at_line(v.line).unwrap_or("").to_string();
            }
            v
        })
        .collect())
}
