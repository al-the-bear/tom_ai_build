package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/**
 * The DocSpecs schema tier over a SOM document, with each finding bound to the
 * document path it is about (SOM §14).
 *
 * <p>{@link DocSpecsValidator} judges Markdown and knows nothing of the
 * document it came from, so its findings name a section id and a rendition
 * line. A section id repeats across a document — every functional requirement
 * has a {@code FRED} form — so the id alone does not say which node to fix. The
 * renderer is the one place that knows which node each heading came from
 * ({@link SpecDocumentMarkdown#exportRootWithMap}); this entry point renders,
 * validates, and fills {@link DocSpecsViolation#path} from that map.
 */
public final class SpecSchemaValidation {
  private SpecSchemaValidation() {}

  /**
   * Renders {@code document} (root {@code rootType}, else its single populated
   * root), validates the rendition against {@code schema}, and returns every
   * finding with {@link DocSpecsViolation#path} set to the document path of the
   * section its line belongs to (an already-set path is kept).
   *
   * <p>A finding about a missing child names the <b>parent</b> — the section
   * whose heading its line points at — exactly as its {@code sectionId} does.
   */
  public static List<DocSpecsViolation> validateSpecDocument(
      SpecModel model, SpecDocument document, DocSpecsSchema schema, String rootType) {
    SpecMarkdownRendition rendition = document.toMarkdownWithMap(model, rootType);
    List<DocSpecsViolation> out = new ArrayList<>();
    for (DocSpecsViolation v : new DocSpecsValidator(schema).validateMarkdown(rendition.markdown)) {
      out.add(new DocSpecsViolation(
          v.rule,
          v.line,
          v.message,
          v.sectionId,
          v.path != null ? v.path : rendition.pathAtLine(v.line)));
    }
    return out;
  }
}
