package tom_som_runtime;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The answers of a review round, extracted for a step folder (SOM §11.9.7).
 *
 * <p>A step of the TomSpecs process starts by collecting what the reviewer wrote into the document
 * — answers to the agent's questions, comments, and optionally the questions still open and the
 * inline marks — into the step folder's {@code answers.md}. The annotations stay in the document;
 * this reads them through {@link SpecReviewAnnotations#list} and never writes.
 */
public final class SpecAnswers {
  private SpecAnswers() {}

  private static final Pattern HEADING = Pattern.compile("^(#+) <!--\\[([^\\]]+)\\]-->");

  /** {@link #extractAnswers(SpecModel, SpecDocument, String, String)} over the whole document. */
  public static SpecAnswerExtract extractAnswers(SpecModel model, SpecDocument doc, String label) {
    return extractAnswers(model, doc, label, null);
  }

  /**
   * Extracts the annotations of {@code doc} (or of the subtree at {@code path}) with their place in
   * the document's Markdown rendition under {@code model}, in rendition order (by line).
   */
  public static SpecAnswerExtract extractAnswers(
      SpecModel model, SpecDocument doc, String label, String path) {
    SpecRoot root = model.roots.get(0);
    for (SpecRoot r : model.roots) {
      if (doc.hasValuesUnder(r.sectionId != null ? r.sectionId : r.type)) {
        root = r;
        break;
      }
    }
    String qualifier = root.sectionId != null ? root.sectionId : root.type;
    SpecMarkdownRendition rendition = new SpecDocumentMarkdown(model, doc).exportRootWithMap(root);
    String[] lines = rendition.markdown.split("\n", -1);

    // The section-id chain of every heading line (1-based).
    Map<Integer, String> chains = new HashMap<>();
    Deque<Object[]> stack = new ArrayDeque<>();
    for (int i = 0; i < lines.length; i++) {
      Matcher m = HEADING.matcher(lines[i]);
      if (!m.find()) {
        continue;
      }
      int level = m.group(1).length();
      while (!stack.isEmpty() && (Integer) stack.peekLast()[0] >= level) {
        stack.removeLast();
      }
      stack.addLast(new Object[] {level, m.group(2)});
      StringBuilder chain = new StringBuilder();
      for (Iterator<Object[]> it = stack.iterator(); it.hasNext(); ) {
        chain.append((String) it.next()[1]);
        if (it.hasNext()) {
          chain.append(" > ");
        }
      }
      chains.put(i + 1, chain.toString());
    }

    List<Integer> headingKeys = new ArrayList<>(rendition.headingPaths.keySet());
    headingKeys.sort(null);
    Set<Integer> claimed = new HashSet<>();

    Locator loc =
        new Locator() {
          // The heading line of a value: the heading whose path is the longest prefix of the
          // value's path (on equal length, the first).
          int headingLine(String valuePath) {
            int best = 0;
            int bestLen = -1;
            for (int l : headingKeys) {
              String hp = rendition.headingPaths.get(l);
              if ((valuePath.equals(hp) || valuePath.startsWith(hp + "/"))
                  && hp.length() > bestLen) {
                best = l;
                bestLen = hp.length();
              }
            }
            return best;
          }

          @Override
          String chainAt(int line) {
            for (int l = line; l >= 1; l--) {
              String c = chains.get(l);
              if (c != null) {
                return c;
              }
            }
            return qualifier;
          }

          // The first unclaimed line after the value's heading whose trimmed text is the
          // annotation's first line. A form field's first line renders behind its label
          // (`Owner: …`, the field name with its first letter upper-cased).
          @Override
          int locate(String valuePath, String field, int valueLine, String firstLine) {
            int h = headingLine(valuePath);
            String want = SpecReviewAnnotations.trim(firstLine);
            String labelled =
                field == null || valueLine != 0
                    ? null
                    : SpecReviewAnnotations.trim(
                        field.substring(0, 1).toUpperCase(Locale.ROOT)
                            + field.substring(1)
                            + ": "
                            + want);
            for (int i = h; i < lines.length; i++) {
              int l = i + 1;
              if (l <= h || claimed.contains(l)) {
                continue;
              }
              String t = SpecReviewAnnotations.trim(lines[i]);
              if (t.equals(want) || (labelled != null && t.equals(labelled))) {
                claimed.add(l);
                return l;
              }
            }
            return h == 0 ? 1 : h;
          }
        };

    SpecReviewAnnotations api = new SpecReviewAnnotations(doc);
    // `list()` and `listMarks()` give the marks in the same order.
    List<SpecMarkEntry> marks = api.listMarks();
    int markIndex = 0;
    List<SpecAnswerEntry> entries = new ArrayList<>();
    for (SpecReviewAnnotation a : api.list()) {
      // Every mark consumes its listing entry, in scope or not, so the ids of the marks in a
      // subtree stay their document-wide `M-<n>`.
      SpecMarkEntry m = a.kind == SpecReviewAnnotationKind.MARK ? marks.get(markIndex++) : null;
      if (path != null && !a.path.equals(path) && !a.path.startsWith(path + "/")) {
        continue;
      }
      String value = a.field == null ? doc.content(a.path) : doc.formField(a.path, a.field);
      if (value == null) {
        value = "";
      }
      String first = value.split("\n", -1)[a.line];
      switch (a.kind) {
        case QUESTION:
          {
            int line = loc.locate(a.path, a.field, a.line, first);
            entries.add(
                new SpecAnswerEntry(
                    a.open() ? SpecAnswerKind.OPEN : SpecAnswerKind.ANSWERED,
                    a.id,
                    loc.chainAt(line),
                    line,
                    a.path,
                    a.field,
                    a.topic,
                    a.combined,
                    a.text,
                    a.answer,
                    null,
                    null,
                    null,
                    null,
                    null));
            break;
          }
        case COMMENT:
          {
            int line = loc.locate(a.path, a.field, a.line, first);
            entries.add(
                new SpecAnswerEntry(
                    SpecAnswerKind.COMMENT,
                    a.id,
                    loc.chainAt(line),
                    line,
                    a.path,
                    a.field,
                    null,
                    false,
                    a.text,
                    "",
                    a.author,
                    null,
                    null,
                    null,
                    null));
            break;
          }
        case MARK:
          {
            int line = loc.locate(a.path, a.field, a.line, first);
            // A line holding several marks is found once; later marks on it share the line.
            claimed.remove(line);
            entries.add(
                new SpecAnswerEntry(
                    SpecAnswerKind.MARK,
                    m.id,
                    loc.chainAt(line),
                    line,
                    a.path,
                    a.field,
                    null,
                    false,
                    m.markup,
                    "",
                    null,
                    a.markKind,
                    m.oldText,
                    m.newText,
                    a.comment));
            break;
          }
      }
    }
    // Rendition order: by line; entries on one line keep their order (List.sort is stable).
    entries.sort((x, y) -> Integer.compare(x.line, y.line));
    return new SpecAnswerExtract(label, qualifier, entries);
  }

  private abstract static class Locator {
    abstract String chainAt(int line);

    abstract int locate(String valuePath, String field, int valueLine, String firstLine);
  }

  /** {@link #renderAnswers(List, SpecAnswerRenderOptions)} with the default options. */
  public static String renderAnswers(List<SpecAnswerExtract> extracts) {
    return renderAnswers(extracts, new SpecAnswerRenderOptions());
  }

  /**
   * Renders {@code extracts} as a step folder's {@code answers.md}: deterministic, grouped per
   * document in the order given, entries in document order.
   */
  public static String renderAnswers(
      List<SpecAnswerExtract> extracts, SpecAnswerRenderOptions options) {
    SpecAnswerCounts total = new SpecAnswerCounts();
    for (SpecAnswerExtract x : extracts) {
      total = total.plus(x.counts());
    }
    List<String> out = new ArrayList<>();
    out.add("# " + options.title);
    out.add("");
    out.add(countLine(total, options));
    for (SpecAnswerExtract x : extracts) {
      out.add("");
      out.add("## " + x.label);
      out.add("");
      out.add(countLine(x.counts(), options));
      section(out, x, "Answered questions", SpecAnswerKind.ANSWERED);
      section(out, x, "Comments", SpecAnswerKind.COMMENT);
      if (options.includeOpen) {
        section(out, x, "Open questions", SpecAnswerKind.OPEN);
      }
      if (options.includeMarks) {
        section(out, x, "Inline marks", SpecAnswerKind.MARK);
      }
    }
    return String.join("\n", out) + "\n";
  }

  private static void section(
      List<String> out, SpecAnswerExtract x, String heading, SpecAnswerKind kind) {
    List<SpecAnswerEntry> es = new ArrayList<>();
    for (SpecAnswerEntry e : x.entries) {
      if (e.kind == kind) {
        es.add(e);
      }
    }
    out.add("");
    out.add("### " + heading);
    if (es.isEmpty()) {
      out.add("");
      out.add("None.");
      return;
    }
    for (SpecAnswerEntry e : es) {
      out.add("");
      out.add("#### " + entryHeading(x, e));
      out.add("");
      out.add(item("Section", "`" + e.section + "`"));
      out.add(item("Line", Integer.toString(e.line)));
      if (e.field != null) {
        out.add(item("Field", "`" + e.field + "`"));
      }
      switch (kind) {
        case ANSWERED:
        case OPEN:
          out.add(item("Question", e.text));
          if (kind == SpecAnswerKind.ANSWERED) {
            out.add(item("Answer", e.answer));
          }
          break;
        case COMMENT:
          if (e.author != null) {
            out.add(item("Author", e.author));
          }
          out.add(item("Comment", e.text));
          break;
        case MARK:
          out.add(item("Markup", "`" + e.text + "`"));
          out.add(item("Old", e.oldText == null ? "" : e.oldText));
          out.add(item("New", e.newText == null ? "" : e.newText));
          if (e.comment != null) {
            out.add(item("Note", e.comment));
          }
          break;
      }
    }
  }

  /** A labelled value: {@code - **Label:** first line}, further lines indented two spaces. */
  private static String item(String label, String value) {
    String[] ls = value.split("\n", -1);
    StringBuilder b = new StringBuilder("- **").append(label).append(":**");
    if (!ls[0].isEmpty()) {
      b.append(' ').append(ls[0]);
    }
    for (int i = 1; i < ls.length; i++) {
      b.append(ls[i].isEmpty() ? "\n" : "\n  " + ls[i]);
    }
    return b.toString();
  }

  private static String plural(int n) {
    return n == 1 ? "" : "s";
  }

  private static String countLine(SpecAnswerCounts c, SpecAnswerRenderOptions o) {
    List<String> parts = new ArrayList<>();
    parts.add(c.answered + " answered question" + plural(c.answered));
    parts.add(c.open + " open question" + plural(c.open));
    parts.add(c.comments + " comment" + plural(c.comments));
    if (o.includeMarks) {
      parts.add(c.marks + " inline mark" + plural(c.marks));
    }
    return String.join(", ", parts) + ".";
  }

  private static String entryHeading(SpecAnswerExtract x, SpecAnswerEntry e) {
    switch (e.kind) {
      case ANSWERED:
      case OPEN:
        return e.id + " — " + e.topic;
      case COMMENT:
        return e.id == null ? "Comment without id (line " + e.line + ")" : x.qualifier + " " + e.id;
      case MARK:
      default:
        return e.id + " — " + e.markKind.value;
    }
  }
}
