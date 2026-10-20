package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * One paragraph of a value (SOM §11.9.1, "Paragraphs"): a run of non-blank lines, where a blank
 * line inside fenced code does not end the run. Its {@link #index} is what {@code afterParagraph}
 * of the inserts takes.
 */
public final class SpecParagraph {
  /** The 0-based position among the value's paragraphs. */
  public final int index;

  /** The 0-based first line within the value. */
  public final int startLine;

  /** The 0-based last line within the value (inclusive). */
  public final int endLine;

  /** The paragraph's lines, verbatim, joined with {@code \n}. */
  public final String text;

  /**
   * {@code comment} or {@code question} when the paragraph opens with an annotation block of that
   * kind, else null.
   */
  public final String annotation;

  /** Creates a paragraph. */
  public SpecParagraph(int index, int startLine, int endLine, String text, String annotation) {
    this.index = index;
    this.startLine = startLine;
    this.endLine = endLine;
    this.text = text;
    this.annotation = annotation;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("index", index);
    out.put("startLine", startLine);
    out.put("endLine", endLine);
    out.put("text", text);
    out.put("annotation", annotation);
    return out;
  }
}
