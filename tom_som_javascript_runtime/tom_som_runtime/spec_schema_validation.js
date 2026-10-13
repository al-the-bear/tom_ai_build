'use strict';

/**
 * The DocSpecs schema tier over a SOM document, with each finding bound to the
 * document path it is about (SOM §14).
 *
 * {@link DocSpecsValidator} judges Markdown and knows nothing of the document
 * it came from, so its findings name a section id and a rendition line. A
 * section id repeats across a document — every functional requirement has a
 * `FRED` form — so the id alone does not say which node to fix. The renderer
 * is the one place that knows which node each heading came from
 * (`SpecDocumentMarkdown#exportRootWithMap`); this entry point renders,
 * validates, and fills `DocSpecsViolation#path` from that map.
 */

const { DocSpecsValidator, DocSpecsViolation } = require('./docspecs_validator');

/**
 * Renders `document` (root `rootType`, else its single populated root),
 * validates the rendition against `schema`, and returns every finding with
 * `path` set to the document path of the section its line belongs to (an
 * already-set path is kept).
 *
 * A finding about a missing child names the **parent** — the section whose
 * heading its line points at — exactly as its `sectionId` does.
 *
 * @param {import('./spec_model').SpecModel} model
 * @param {import('./spec_document').SpecDocument} document
 * @param {import('./docspecs_validator').DocSpecsSchema} schema
 * @param {string|null} [rootType]
 * @returns {DocSpecsViolation[]}
 */
function validateSpecDocument(model, document, schema, rootType = null) {
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
          v.path !== null && v.path !== undefined
            ? v.path
            : rendition.pathAtLine(v.line),
        ),
    );
}

module.exports = { validateSpecDocument };
