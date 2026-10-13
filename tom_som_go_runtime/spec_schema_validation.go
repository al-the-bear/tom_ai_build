// The DocSpecs schema tier over a SOM document, with each finding bound to the
// document path it is about.
//
// DocSpecsValidator judges Markdown and knows nothing of the document it came
// from, so its findings name a section id and a rendition line. A section id
// repeats across a document — every functional requirement has a `FRED` form —
// so the id alone does not say which node to fix. The renderer is the one
// place that knows which node each heading came from
// (SpecDocumentMarkdown.ExportRootWithMap); ValidateSpecDocument renders,
// validates, and fills DocSpecsViolation.Path from that map.

package somruntime

// ValidateSpecDocument renders document (root rootType, else — when rootType
// is "" — its single populated root), validates the rendition against schema,
// and returns every finding with Path set to the document path of the section
// its line belongs to. A Path the validator already set is kept.
//
// A finding about a missing child names the **parent** — the section whose
// heading its line points at — exactly as its SectionID does. Returns the
// render error (ToMarkdownWithMap) when the document cannot be rendered.
func ValidateSpecDocument(
	model *SpecModel,
	document *SpecDocument,
	schema *DocSpecsSchema,
	rootType string,
) ([]*DocSpecsViolation, error) {
	rendition, err := document.ToMarkdownWithMap(model, rootType)
	if err != nil {
		return nil, err
	}
	found := NewDocSpecsValidator(schema).ValidateMarkdown(rendition.Markdown)
	out := make([]*DocSpecsViolation, 0, len(found))
	for _, v := range found {
		path := v.Path
		if path == "" {
			path, _ = rendition.PathAtLine(v.Line)
		}
		out = append(out, &DocSpecsViolation{
			Rule:      v.Rule,
			Line:      v.Line,
			Message:   v.Message,
			SectionID: v.SectionID,
			Path:      path,
		})
	}
	return out, nil
}
