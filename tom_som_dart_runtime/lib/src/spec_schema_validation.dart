/// The DocSpecs schema tier over a SOM document, with each finding bound to
/// the document path it is about.
///
/// [DocSpecsValidator] judges Markdown and knows nothing of the document it
/// came from, so its findings name a section id and a rendition line. A
/// section id repeats across a document — every functional requirement has a
/// `FRED` form — so the id alone does not say which node to fix. The renderer
/// is the one place that knows which node each heading came from
/// ([SpecDocumentMarkdown.exportRootWithMap]); this entry point renders,
/// validates, and fills [DocSpecsViolation.path] from that map.
library;

import 'docspecs_validator.dart';
import 'spec_document.dart';
import 'spec_model.dart';

/// Renders [document] (root [rootType], else its single populated root),
/// validates the rendition against [schema], and returns every finding with
/// [DocSpecsViolation.path] set to the document path of the section its line
/// belongs to.
///
/// A finding about a missing child names the **parent** — the section whose
/// heading its line points at — exactly as its `sectionId` does.
List<DocSpecsViolation> validateSpecDocument(
  SpecModel model,
  SpecDocument document,
  DocSpecsSchema schema, {
  String? rootType,
}) {
  final rendition = document.toMarkdownWithMap(model, rootType: rootType);
  return [
    for (final v in DocSpecsValidator(
      schema,
    ).validateMarkdown(rendition.markdown))
      DocSpecsViolation(
        rule: v.rule,
        line: v.line,
        message: v.message,
        sectionId: v.sectionId,
        path: v.path ?? rendition.pathAtLine(v.line),
      ),
  ];
}
