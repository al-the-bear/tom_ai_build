package tom_som_runtime;

import java.util.List;

/**
 * The outcome of {@link SpecDocument#fromMarkdown}: the loaded document plus the
 * parse report it came from.
 */
public final class SpecMarkdownImport {
  /** The document holding every value the parse accepted. */
  public final SpecDocument document;

  /** The parse report, rejections included. */
  public final SpecMarkdownResult result;

  /** Both are set by the import that produced them. */
  public SpecMarkdownImport(SpecDocument document, SpecMarkdownResult result) {
    this.document = document;
    this.result = result;
  }

  /**
   * The blocks the parse rejected, in source order; they are not in
   * {@link #document}.
   */
  public List<SpecMarkdownRejection> rejections() {
    return result.rejections;
  }
}
