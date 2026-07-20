package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * A schema-free structural parse of a DocSpecs markdown document into a
 * heading tree (fence-aware, never fails) — a faithful port of the Go
 * {@code DocSpecsDocument} / {@code ParseDocSpecsDocument}.
 *
 * <p>Shares the exact heading/fence semantics of the
 * {@link SpecDocumentMarkdown} codec (same package-level patterns and
 * {@link MarkdownFenceTracker}).
 */
public final class DocSpecsDocument {
  private static final Pattern DOCSPEC_HEADER =
      Pattern.compile("^<!--\\s*docspec:\\s*(\\S+)\\s*-->\\s*$");
  private static final Pattern TRAILING_WS = Pattern.compile("\\s+$");

  /** The {@code <!-- docspec: … -->} declaration, {@code null} when absent. */
  public String declaredSchema;

  /** The top-level (root) sections. */
  public final List<DocSpecsSection> sections = new ArrayList<>();

  /** Structural findings from the parse. */
  public final List<DocSpecsViolation> violations = new ArrayList<>();

  private DocSpecsDocument() {}

  /**
   * Parses {@code text} into a heading tree. It never fails — structural
   * problems are recorded as violations.
   */
  public static DocSpecsDocument parse(String text) {
    DocSpecsDocument doc = new DocSpecsDocument();
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    List<DocSpecsSection> stack = new ArrayList<>();
    String[] lines = text.split("\n", -1);
    for (int idx = 0; idx < lines.length; idx++) {
      String raw = lines[idx];
      int lineNo = idx + 1;
      String line = TRAILING_WS.matcher(raw).replaceAll("");
      if (!fence.inFence()) {
        if (stack.isEmpty() && doc.declaredSchema == null) {
          Matcher h = DOCSPEC_HEADER.matcher(line);
          if (h.matches()) {
            doc.declaredSchema = h.group(1);
            fence.feed(raw);
            continue;
          }
        }
        Matcher m = SpecDocumentMarkdown.HEADING_LINE.matcher(line);
        if (m.matches()) {
          int level = m.group(1).length();
          String rest = m.group(2);
          DocSpecsSection section;
          Matcher c = SpecDocumentMarkdown.HEADLINE_COMMENT.matcher(rest);
          if (c.matches()) {
            String title = c.group(3).trim();
            if (title.isEmpty()) {
              title = rest;
            }
            section = new DocSpecsSection(c.group(1), title, level, lineNo);
          } else {
            doc.violations.add(
                new DocSpecsViolation(
                    DocSpecsViolation.RULE_MALFORMED_HEADING,
                    lineNo,
                    "heading \""
                        + rest
                        + "\" carries no <!--[SECTION-ID]--> headline comment"));
            section = new DocSpecsSection(null, rest, level, lineNo);
          }
          while (!stack.isEmpty() && stack.get(stack.size() - 1).level >= level) {
            stack.remove(stack.size() - 1);
          }
          if (!stack.isEmpty()) {
            stack.get(stack.size() - 1).children.add(section);
          } else {
            doc.sections.add(section);
          }
          stack.add(section);
          fence.feed(raw);
          continue;
        }
      }
      if (!stack.isEmpty()) {
        stack.get(stack.size() - 1).bodyLines.add(raw);
      }
      fence.feed(raw);
    }
    return doc;
  }
}
