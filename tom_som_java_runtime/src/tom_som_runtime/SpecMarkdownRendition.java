package tom_som_runtime;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * A Markdown rendition of a document and the document path behind each of its
 * headings ({@link SpecDocumentMarkdown#exportRootWithMap}).
 */
public final class SpecMarkdownRendition {
  /** The rendered Markdown, identical to {@link SpecDocumentMarkdown#exportRoot}. */
  public final String markdown;

  /** Every heading line (1-based) and the document path it renders, in line order. */
  public final Map<Integer, String> headingPaths;

  /** The rendition and its heading map — 1-based line → document path. */
  public SpecMarkdownRendition(String markdown, Map<Integer, String> headingPaths) {
    this.markdown = markdown;
    this.headingPaths = Collections.unmodifiableMap(new LinkedHashMap<>(headingPaths));
  }

  /**
   * The document path of the section {@code line} belongs to: the path of the
   * heading on that line, else of the nearest heading above it. {@code null}
   * for a line before the first heading.
   */
  public String pathAtLine(int line) {
    for (int l = line; l >= 1; l--) {
      String p = headingPaths.get(l);
      if (p != null) {
        return p;
      }
    }
    return null;
  }
}
