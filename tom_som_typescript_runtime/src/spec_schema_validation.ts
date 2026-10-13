/**
 * The DocSpecs schema tier over a SOM document, with each finding bound to the
 * document path it is about (SOM §14).
 *
 * {@link DocSpecsValidator} judges Markdown and knows nothing of the document
 * it came from, so its findings name a section id and a rendition line. A
 * section id repeats across a document — every functional requirement has a
 * `FRED` form — so the id alone does not say which node to fix. The renderer
 * is the one place that knows which node each heading came from
 * ({@link SpecDocumentMarkdown.exportRootWithMap}); this entry point renders,
 * validates, and fills {@link DocSpecsViolation.path} from that map.
 */

import {
  DocSpecsSchema,
  DocSpecsValidator,
  DocSpecsViolation,
} from './docspecs_validator';
import type { SpecDocument } from './spec_document';
import type { SpecModel } from './spec_model';

/**
 * Renders `document` (root `rootType`, else its single populated root),
 * validates the rendition against `schema`, and returns every finding with
 * {@link DocSpecsViolation.path} set to the document path of the section its
 * line belongs to (an already-set path is kept).
 *
 * A finding about a missing child names the **parent** — the section whose
 * heading its line points at — exactly as its `sectionId` does.
 */
export function validateSpecDocument(
  model: SpecModel,
  document: SpecDocument,
  schema: DocSpecsSchema,
  rootType?: string,
): DocSpecsViolation[] {
  const rendition = document.toMarkdownWithMap(model, rootType);
  return new DocSpecsValidator(schema)
    .validateMarkdown(rendition.markdown)
    .map(
      (v) =>
        new DocSpecsViolation(
          v.rule,
          v.line,
          v.message,
          v.sectionId,
          v.path ?? rendition.pathAtLine(v.line),
        ),
    );
}
