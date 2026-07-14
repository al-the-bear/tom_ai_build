package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/**
 * One heading-delimited section of a schema-free DocSpecs document parse — a
 * faithful port of the Go {@code DocSpecsSection}.
 */
public final class DocSpecsSection {
  /** The headline-comment section id, {@code null} for a malformed heading. */
  public final String id;

  public final String title;
  public final int level;
  /** 1-based line number of the heading line. */
  public final int line;

  /** The raw body lines between this heading and the next. */
  public final List<String> bodyLines = new ArrayList<>();

  public final List<DocSpecsSection> children = new ArrayList<>();

  public DocSpecsSection(String id, String title, int level, int line) {
    this.id = id;
    this.title = title;
    this.level = level;
    this.line = line;
  }

  /** The 1-based line number of the first body line. */
  public int bodyStartLine() {
    return line + 1;
  }

  /** The body text with leading/trailing blank lines trimmed. */
  public String text() {
    int start = 0;
    int end = bodyLines.size();
    while (start < end && bodyLines.get(start).trim().isEmpty()) {
      start++;
    }
    while (end > start && bodyLines.get(end - 1).trim().isEmpty()) {
      end--;
    }
    return String.join("\n", bodyLines.subList(start, end));
  }
}
