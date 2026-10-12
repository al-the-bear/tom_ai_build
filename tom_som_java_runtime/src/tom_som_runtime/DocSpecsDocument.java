package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
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

  /** Every section of the document, depth-first (all levels), in order. */
  public List<DocSpecsSection> allSections() {
    List<DocSpecsSection> out = new ArrayList<>();
    collect(sections, out);
    return out;
  }

  private static void collect(List<DocSpecsSection> list, List<DocSpecsSection> out) {
    for (DocSpecsSection s : list) {
      out.add(s);
      collect(s.children, out);
    }
  }

  /**
   * Returns {@code text} with the body of the section whose id is
   * {@code sectionId} replaced by {@code body}; every other byte is kept.
   *
   * <p>The body is the section's <b>own</b> region: the lines after its heading
   * up to its first child heading, or the next heading of any level. The
   * heading line (with its {@code <!--[ID]-->} comment) and the subsections are
   * untouched. The region is found by the same fence-aware {@link #parse}, so a
   * {@code #} line inside a fenced block is never taken for a heading.
   *
   * <p>The new region is a blank line, {@code body} with its leading and
   * trailing blank lines removed, and a blank line; an empty {@code body}
   * leaves a single blank line.
   *
   * @throws IllegalArgumentException when {@code sectionId} names no section or
   *     more than one, and when {@code body} would change the document's
   *     structure: a heading outside a fenced block, or a fence it opens and
   *     never closes
   */
  public static String replaceSectionBody(String text, String sectionId, String body) {
    List<DocSpecsSection> matches = new ArrayList<>();
    for (DocSpecsSection s : parse(text).allSections()) {
      if (sectionId.equals(s.id)) {
        matches.add(s);
      }
    }
    if (matches.isEmpty()) {
      throw new IllegalArgumentException("sectionId \"" + sectionId + "\" names no section");
    }
    if (matches.size() > 1) {
      List<String> lineNos = new ArrayList<>();
      for (DocSpecsSection s : matches) {
        lineNos.add(String.valueOf(s.line));
      }
      throw new IllegalArgumentException(
          "sectionId \""
              + sectionId
              + "\" names "
              + matches.size()
              + " sections (lines "
              + String.join(", ", lineNos)
              + ")");
    }

    List<String> bodyLines = new ArrayList<>(Arrays.asList(body.split("\n", -1)));
    while (!bodyLines.isEmpty() && bodyLines.get(0).strip().isEmpty()) {
      bodyLines.remove(0);
    }
    while (!bodyLines.isEmpty() && bodyLines.get(bodyLines.size() - 1).strip().isEmpty()) {
      bodyLines.remove(bodyLines.size() - 1);
    }
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    for (String line : bodyLines) {
      if (!fence.inFence()
          && SpecDocumentMarkdown.HEADING_LINE
              .matcher(TRAILING_WS.matcher(line).replaceAll(""))
              .matches()) {
        throw new IllegalArgumentException(
            "body contains a heading outside a fenced block: \"" + line + "\"");
      }
      fence.feed(line);
    }
    if (fence.inFence()) {
      throw new IllegalArgumentException("body leaves a fenced block open");
    }

    DocSpecsSection section = matches.get(0);
    List<String> lines = Arrays.asList(text.split("\n", -1));
    int start = section.line; // 0-based index of the first body line
    int end = start + section.bodyLines.size();
    List<String> out = new ArrayList<>(lines.subList(0, start));
    out.add("");
    if (!bodyLines.isEmpty()) {
      out.addAll(bodyLines);
      out.add("");
    }
    out.addAll(lines.subList(end, lines.size()));
    return String.join("\n", out);
  }
}
