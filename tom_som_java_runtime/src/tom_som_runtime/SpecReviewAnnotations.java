package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.nio.charset.StandardCharsets;
import java.util.Set;
import java.util.function.Function;
import java.util.function.IntUnaryOperator;
import java.util.regex.Pattern;

/**
 * The review annotations of a document (SOM §11.9) — comment blocks, question blocks and
 * CriticMarkup inline marks in its content and form-field values — and the operations that edit
 * them in place. A faithful port of {@code tom_som_dart_runtime/lib/src/spec_review_annotations.dart}.
 *
 * <p>Every edit is byte-stable outside the annotation it touches. Positions are <b>0-based line
 * numbers within the value</b>, never character offsets. Values are visited in a fixed order —
 * content paths sorted, then form paths sorted with their field names sorted — so "document order"
 * is the same in every runtime.
 */
public final class SpecReviewAnnotations {
  /** The document. */
  public final SpecDocument doc;

  /**
   * The document's id or name, written in front of a comment id cited outside the document
   * ({@code SBP} → {@code SBP C-12}); null for bare ids.
   */
  public final String qualifier;

  /** Wraps {@code doc} with no qualifier. */
  public SpecReviewAnnotations(SpecDocument doc) {
    this(doc, null);
  }

  /** Wraps {@code doc}; {@code qualifier} may be null. */
  public SpecReviewAnnotations(SpecDocument doc, String qualifier) {
    this.doc = doc;
    this.qualifier = qualifier;
  }

  // -------------------------------------------------------------------------
  // Text level: one value.
  // -------------------------------------------------------------------------

  private static final String ARROW = "⬆";
  private static final String VS16 = "️";
  private static final String QUESTION_OPEN = "**❓";
  private static final String COMBINED_OPENER = "**❓ Open questions on these fields**";
  private static final String ANSWER_LABEL = "**Answer:**";
  private static final String EM_DASH_SEP = " — ";
  private static final String STAR = "★";

  private static final Pattern COMMENT_NUMBER = Pattern.compile("[1-9][0-9]*");
  private static final Pattern QUESTION_ID = Pattern.compile("[A-Z][A-Z0-9]*-[0-9]+");

  private static final List<String> OPENERS = Arrays.asList("{>>", "{==", "{++", "{--", "{~~");
  private static final Map<String, String> CLOSERS = new LinkedHashMap<>();

  static {
    CLOSERS.put("{>>", "<<}");
    CLOSERS.put("{==", "==}");
    CLOSERS.put("{++", "++}");
    CLOSERS.put("{--", "--}");
    CLOSERS.put("{~~", "~~}");
  }

  /** One parsed block of a value (lines [start, end] inclusive). */
  private static final class Block {
    final int start;
    final int end;
    final SpecReviewAnnotationKind kind;
    List<Question> questions = new ArrayList<>();
    boolean combined;

    Block(int start, int end, SpecReviewAnnotationKind kind) {
      this.start = start;
      this.end = end;
      this.kind = kind;
    }
  }

  /** One question region inside a question block. */
  private static final class Question {
    final int header;
    final int regionEnd;
    final Integer answerLine;
    final String id;
    final String topic;
    final boolean starred;
    final String text;
    final String answer;

    Question(
        int header,
        int regionEnd,
        Integer answerLine,
        String id,
        String topic,
        boolean starred,
        String text,
        String answer) {
      this.header = header;
      this.regionEnd = regionEnd;
      this.answerLine = answerLine;
      this.id = id;
      this.topic = topic;
      this.starred = starred;
      this.text = text;
      this.answer = answer;
    }
  }

  /** One parsed comment block. */
  private static final class Comment {
    final Block block;
    final String id;
    final String author;
    final String text;
    final String context;
    final String headerPrefix;
    final int markerEnd;

    Comment(
        Block block,
        String id,
        String author,
        String text,
        String context,
        String headerPrefix,
        int markerEnd) {
      this.block = block;
      this.id = id;
      this.author = author;
      this.text = text;
      this.context = context;
      this.headerPrefix = headerPrefix;
      this.markerEnd = markerEnd;
    }
  }

  /** One parsed mark; start/end are UTF-16 offsets into the value (never exported). */
  private static final class Mark {
    final int start;
    final int end;
    final int line;
    final SpecMarkKind kind;
    final String text;
    final String newText;
    final String comment;

    Mark(int start, int end, int line, SpecMarkKind kind, String text, String newText, String comment) {
      this.start = start;
      this.end = end;
      this.line = line;
      this.kind = kind;
      this.text = text;
      this.newText = newText;
      this.comment = comment;
    }
  }

  /** The parsed header of a question. */
  private static final class Header {
    final String id;
    final String topic;
    final boolean starred;
    final String rest;

    Header(String id, String topic, boolean starred, String rest) {
      this.id = id;
      this.topic = topic;
      this.starred = starred;
      this.rest = rest;
    }
  }

  /** Everything one value holds. */
  private static final class Parsed {
    final List<String> lines;
    final boolean[] code;
    final List<Block> blocks = new ArrayList<>();
    final List<Comment> comments = new ArrayList<>();
    final List<Mark> marks = new ArrayList<>();
    final List<String> malformed = new ArrayList<>();

    /** Malformed inline marks as (value line, issue code): unclosed, nested, noArrow. */
    final List<Object[]> markIssues = new ArrayList<>();

    Parsed(List<String> lines, boolean[] code) {
      this.lines = lines;
      this.code = code;
    }
  }

  /** Dart's {@code String.trim} whitespace set, so "trimmed" means the same here. */
  private static boolean isWs(char c) {
    switch (c) {
      case '\t':
      case '\n':
      case '\u000b':
      case '\u000c':
      case '\r':
      case ' ':
      case '\u0085':
      case ' ':
      case ' ':
      case ' ':
      case ' ':
      case ' ':
      case ' ':
      case '　':
      case '﻿':
        return true;
      default:
        return c >= ' ' && c <= ' ';
    }
  }

  private static String trim(String s) {
    int a = 0;
    int b = s.length();
    while (a < b && isWs(s.charAt(a))) {
      a++;
    }
    while (b > a && isWs(s.charAt(b - 1))) {
      b--;
    }
    return s.substring(a, b);
  }

  private static String trimRight(String s) {
    int b = s.length();
    while (b > 0 && isWs(s.charAt(b - 1))) {
      b--;
    }
    return s.substring(0, b);
  }

  private static List<String> splitLines(String value) {
    return new ArrayList<>(Arrays.asList(value.split("\n", -1)));
  }

  private static String lstrip(String s) {
    int i = 0;
    while (i < s.length() && (s.charAt(i) == ' ' || s.charAt(i) == '\t')) {
      i++;
    }
    return s.substring(i);
  }

  private static boolean isBlank(String s) {
    return trim(s).isEmpty();
  }

  /** The fenced-code flag of every line. */
  private static boolean[] codeLines(List<String> lines) {
    boolean[] code = new boolean[lines.size()];
    char fenceChar = 0;
    int fenceLen = 0;
    for (int i = 0; i < lines.size(); i++) {
      String t = lstrip(lines.get(i));
      if (fenceChar == 0) {
        char c = t.isEmpty() ? 0 : t.charAt(0);
        if (c == '`' || c == '~') {
          int n = 0;
          while (n < t.length() && t.charAt(n) == c) {
            n++;
          }
          if (n >= 3) {
            fenceChar = c;
            fenceLen = n;
            code[i] = true;
          }
        }
      } else {
        code[i] = true;
        int n = 0;
        while (n < t.length() && t.charAt(n) == fenceChar) {
          n++;
        }
        if (n >= fenceLen && trim(t.substring(n)).isEmpty()) {
          fenceChar = 0;
        }
      }
    }
    return code;
  }

  private static boolean isQuoteLine(String line) {
    return lstrip(line).startsWith(">");
  }

  /** The line inside the quote: after {@code >} and one following space. */
  private static String inner(String line) {
    String s = lstrip(line).substring(1);
    if (s.startsWith(" ")) {
      s = s.substring(1);
    }
    return s;
  }

  private static Parsed parse(String value) {
    List<String> lines = splitLines(value);
    boolean[] code = codeLines(lines);
    Parsed p = new Parsed(lines, code);

    int i = 0;
    while (i < lines.size()) {
      if (code[i] || !isQuoteLine(lines.get(i))) {
        i++;
        continue;
      }
      int s = i;
      while (i + 1 < lines.size() && !code[i + 1] && isQuoteLine(lines.get(i + 1))) {
        i++;
      }
      int e = i;
      String first = inner(lines.get(s));
      if (first.startsWith(ARROW)) {
        Block b = new Block(s, e, SpecReviewAnnotationKind.COMMENT);
        p.blocks.add(b);
        p.comments.add(parseComment(p, b));
      } else if (first.startsWith(QUESTION_OPEN)) {
        Block b = new Block(s, e, SpecReviewAnnotationKind.QUESTION);
        p.blocks.add(b);
        parseQuestions(p, b);
      }
      i = e + 1;
    }

    parseMarks(p);
    return p;
  }

  private static String context(Parsed p, int blockStart) {
    int k = blockStart - 1;
    while (k >= 0 && (isBlank(p.lines.get(k)) || isQuoteLine(p.lines.get(k)))) {
      k--;
    }
    if (k < 0) {
      return "";
    }
    int end = k;
    while (k - 1 >= 0 && !isBlank(p.lines.get(k - 1)) && !isQuoteLine(p.lines.get(k - 1))) {
      k--;
    }
    return String.join("\n", p.lines.subList(k, end + 1));
  }

  private static Comment parseComment(Parsed p, Block b) {
    String raw0 = p.lines.get(b.start);
    String rest = inner(raw0).substring(ARROW.length());
    if (rest.startsWith(VS16)) {
      rest = rest.substring(VS16.length());
    }
    int markerEnd = raw0.length() - rest.length();
    rest = lstrip(rest);
    String id = null;
    if (rest.startsWith("**C-")) {
      int close = rest.indexOf("**", 4);
      if (close >= 0) {
        String n = rest.substring(4, close);
        if (COMMENT_NUMBER.matcher(n).matches()) {
          id = "C-" + n;
        } else {
          p.malformed.add(
              "line " + b.start + ": comment id \"C-" + n + "\" is not C-<number> (SOM §11.9.1)");
        }
        rest = lstrip(rest.substring(close + 2));
      }
    }
    String author = null;
    if (rest.startsWith("(")) {
      int close = rest.indexOf(')');
      if (close > 0) {
        author = rest.substring(1, close);
        rest = rest.substring(close + 1);
        if (rest.startsWith(":")) {
          rest = rest.substring(1);
        }
        rest = lstrip(rest);
      }
    } else if (rest.startsWith(":")) {
      rest = lstrip(rest.substring(1));
    }
    String headerPrefix = raw0.substring(0, raw0.length() - rest.length());
    List<String> textLines = new ArrayList<>();
    textLines.add(rest);
    for (int k = b.start + 1; k <= b.end; k++) {
      String in = inner(p.lines.get(k));
      String t = lstrip(in);
      if (t.startsWith(QUESTION_OPEN) || t.startsWith(ANSWER_LABEL)) {
        p.malformed.add(
            "line "
                + k
                + ": a comment block holds a question or an answer; the question goes into its"
                + " own block after the comment (SOM §11.9.1)");
      }
      textLines.add(in);
    }
    return new Comment(
        b,
        id,
        author,
        trim(String.join("\n", textLines)),
        context(p, b.start),
        headerPrefix,
        markerEnd);
  }

  /** Parses a question header's remainder after {@code **❓ }; null when malformed. */
  private static Header parseHeader(String in) {
    String h = in.substring(QUESTION_OPEN.length() + 1);
    int sep = h.indexOf(EM_DASH_SEP);
    if (sep <= 0) {
      return null;
    }
    String id = h.substring(0, sep);
    if (!QUESTION_ID.matcher(id).matches()) {
      return null;
    }
    String t = h.substring(sep + EM_DASH_SEP.length());
    boolean starred = false;
    if (t.startsWith(STAR + " ")) {
      starred = true;
      t = t.substring(STAR.length() + 1);
    }
    int close = t.indexOf(":**");
    if (close < 0) {
      return null;
    }
    String topic = t.substring(0, close);
    String rest = t.substring(close + 3);
    if (rest.startsWith(" ")) {
      rest = rest.substring(1);
    }
    return new Header(id, topic, starred, rest);
  }

  private static void parseQuestions(Parsed p, Block b) {
    List<String> in = new ArrayList<>();
    for (int k = b.start; k <= b.end; k++) {
      in.add(inner(p.lines.get(k)));
    }
    b.combined = in.get(0).startsWith(COMBINED_OPENER);
    List<Integer> keys = new ArrayList<>();
    Map<Integer, Header> headers = new LinkedHashMap<>();
    for (int k = 0; k < in.size(); k++) {
      if (!in.get(k).startsWith(QUESTION_OPEN + " ")) {
        continue;
      }
      if (in.get(k).startsWith(COMBINED_OPENER)) {
        continue;
      }
      Header h = parseHeader(in.get(k));
      if (h == null) {
        p.malformed.add(
            "line "
                + (b.start + k)
                + ": question header is not \"**❓ <ID> — <topic>:**\" (SOM §11.9.2)");
        continue;
      }
      keys.add(k);
      headers.put(k, h);
    }
    List<Question> list = new ArrayList<>();
    for (int q = 0; q < keys.size(); q++) {
      int k = keys.get(q);
      Header h = headers.get(k);
      int regionEnd = q + 1 < keys.size() ? keys.get(q + 1) - 1 : in.size() - 1;
      Integer answer = null;
      for (int m = k + 1; m <= regionEnd; m++) {
        if (in.get(m).startsWith(ANSWER_LABEL)) {
          answer = m;
          break;
        }
      }
      int textEnd = answer == null ? regionEnd : answer - 1;
      List<String> textParts = new ArrayList<>();
      textParts.add(h.rest);
      if (textEnd >= k + 1) {
        textParts.addAll(in.subList(k + 1, textEnd + 1));
      }
      String text = trim(String.join("\n", textParts));
      String answerText = "";
      if (answer != null) {
        List<String> parts = new ArrayList<>();
        parts.add(in.get(answer).substring(ANSWER_LABEL.length()));
        if (regionEnd >= answer + 1) {
          parts.addAll(in.subList(answer + 1, regionEnd + 1));
        }
        answerText = trim(String.join("\n", parts));
      }
      list.add(
          new Question(
              b.start + k,
              b.start + regionEnd,
              answer == null ? null : b.start + answer,
              h.id,
              h.topic,
              h.starred,
              text,
              answerText));
    }
    b.questions = list;
  }

  private static boolean hasOpener(String s) {
    for (String o : OPENERS) {
      if (s.contains(o)) {
        return true;
      }
    }
    return false;
  }

  /** The offset of the {@code \n} before the first blank line after {@code from}, or the length. */
  private static int paragraphEnd(String text, int from) {
    int i = text.indexOf('\n', from);
    while (i >= 0) {
      int next = text.indexOf('\n', i + 1);
      String line = text.substring(i + 1, next < 0 ? text.length() : next);
      if (trim(line).isEmpty()) {
        return i;
      }
      i = next;
    }
    return text.length();
  }

  private static void parseMarks(Parsed p) {
    int[] lineStart = new int[p.lines.size()];
    int off = 0;
    for (int k = 0; k < p.lines.size(); k++) {
      lineStart[k] = off;
      off += p.lines.get(k).length() + 1;
    }
    String value = String.join("\n", p.lines);
    IntUnaryOperator lineOf =
        offset -> {
          int lo = 0;
          for (int k = 0; k < lineStart.length; k++) {
            if (lineStart[k] <= offset) {
              lo = k;
            }
          }
          return lo;
        };

    int k = 0;
    int n = p.lines.size();
    while (k < n) {
      if (p.code[k]) {
        k++;
        continue;
      }
      int segStartLine = k;
      while (k < n && !p.code[k]) {
        k++;
      }
      int segStart = lineStart[segStartLine];
      int segEnd = lineStart[k - 1] + p.lines.get(k - 1).length();
      scanSegment(p, value.substring(segStart, segEnd), segStart, lineOf);
    }
  }

  private static void scanSegment(Parsed p, String seg, int base, IntUnaryOperator lineOf) {
    int i = 0;
    int len = seg.length();
    while (i < len) {
      char c = seg.charAt(i);
      if (c == '`') {
        int n = 0;
        while (i + n < len && seg.charAt(i + n) == '`') {
          n++;
        }
        int j = i + n;
        int closeAt = -1;
        while (j < len) {
          if (seg.charAt(j) == '`') {
            int m = 0;
            while (j + m < len && seg.charAt(j + m) == '`') {
              m++;
            }
            if (m == n) {
              closeAt = j;
              break;
            }
            j += m;
          } else {
            j++;
          }
        }
        i = closeAt < 0 ? i + n : closeAt + n;
        continue;
      }
      if (c != '{' || i + 3 > len) {
        i++;
        continue;
      }
      String opener = seg.substring(i, i + 3);
      if (!OPENERS.contains(opener)) {
        i++;
        continue;
      }
      String closer = CLOSERS.get(opener);
      int close = seg.indexOf(closer, i + 3);
      int pend = paragraphEnd(seg, i);
      int line = lineOf.applyAsInt(base + i);
      if (close < 0 || close > pend) {
        p.malformed.add(
            "line "
                + line
                + ": inline mark \""
                + opener
                + "\" is not closed in its paragraph (SOM §11.9.3)");
        p.markIssues.add(new Object[] {line, "unclosed"});
        i += 3;
        continue;
      }
      String in = seg.substring(i + 3, close);
      if (hasOpener(in)) {
        p.malformed.add("line " + line + ": inline marks do not nest (SOM §11.9.3)");
        p.markIssues.add(new Object[] {line, "nested"});
        i = close + 3;
        continue;
      }
      int end = close + 3;
      switch (opener) {
        case "{>>":
          p.marks.add(new Mark(base + i, base + end, line, SpecMarkKind.COMMENT, "", null, trim(in)));
          break;
        case "{==":
          {
            String comment = null;
            if (seg.startsWith("{>>", end)) {
              int c2 = seg.indexOf("<<}", end + 3);
              if (c2 >= 0 && c2 <= paragraphEnd(seg, end)) {
                String ci = seg.substring(end + 3, c2);
                if (!hasOpener(ci)) {
                  comment = trim(ci);
                  end = c2 + 3;
                }
              }
            }
            p.marks.add(
                new Mark(base + i, base + end, line, SpecMarkKind.HIGHLIGHT, trim(in), null, comment));
            break;
          }
        case "{++":
          p.marks.add(
              new Mark(base + i, base + end, line, SpecMarkKind.INSERTION, trim(in), null, null));
          break;
        case "{--":
          p.marks.add(
              new Mark(base + i, base + end, line, SpecMarkKind.DELETION, trim(in), null, null));
          break;
        default:
          {
            int arrow = in.indexOf("~>");
            if (arrow < 0) {
              p.malformed.add("line " + line + ": a substitution has no \"~>\" (SOM §11.9.3)");
              p.markIssues.add(new Object[] {line, "noArrow"});
              i = end;
              continue;
            }
            p.marks.add(
                new Mark(
                    base + i,
                    base + end,
                    line,
                    SpecMarkKind.SUBSTITUTION,
                    trim(in.substring(0, arrow)),
                    trim(in.substring(arrow + 2)),
                    null));
            break;
          }
      }
      i = end;
    }
  }

  /** One sortable entry of {@link #annotationsOf}. */
  private static final class Ordered {
    final int line;
    final int rank;
    final int seq;
    final SpecReviewAnnotation annotation;

    Ordered(int line, int rank, int seq, SpecReviewAnnotation annotation) {
      this.line = line;
      this.rank = rank;
      this.seq = seq;
      this.annotation = annotation;
    }
  }

  /** The annotations of one value, in order: by line, blocks before marks, then scan order. */
  private static List<SpecReviewAnnotation> annotationsOf(
      Parsed p, String path, String field, String qualifier) {
    List<Ordered> out = new ArrayList<>();
    int seq = 0;
    for (Block b : p.blocks) {
      if (b.kind == SpecReviewAnnotationKind.COMMENT) {
        Comment c = null;
        for (Comment x : p.comments) {
          if (x.block == b) {
            c = x;
            break;
          }
        }
        out.add(
            new Ordered(
                b.start,
                0,
                seq++,
                new SpecReviewAnnotation(
                    SpecReviewAnnotationKind.COMMENT,
                    path,
                    field,
                    b.start,
                    c.id,
                    qualifier != null && c.id != null ? qualifier + " " + c.id : null,
                    c.author,
                    c.text,
                    c.context,
                    null,
                    false,
                    false,
                    "",
                    null,
                    null,
                    null)));
      } else {
        for (Question q : b.questions) {
          out.add(
              new Ordered(
                  q.header,
                  0,
                  seq++,
                  new SpecReviewAnnotation(
                      SpecReviewAnnotationKind.QUESTION,
                      path,
                      field,
                      q.header,
                      q.id,
                      null,
                      null,
                      q.text,
                      "",
                      q.topic,
                      q.starred,
                      b.combined,
                      q.answer,
                      null,
                      null,
                      null)));
        }
      }
    }
    for (Mark m : p.marks) {
      out.add(
          new Ordered(
              m.line,
              1,
              seq++,
              new SpecReviewAnnotation(
                  SpecReviewAnnotationKind.MARK,
                  path,
                  field,
                  m.line,
                  null,
                  null,
                  null,
                  m.text,
                  "",
                  null,
                  false,
                  false,
                  "",
                  m.kind,
                  m.newText,
                  m.comment)));
    }
    out.sort(
        Comparator.comparingInt((Ordered o) -> o.line)
            .thenComparingInt(o -> o.rank)
            .thenComparingInt(o -> o.seq));
    List<SpecReviewAnnotation> result = new ArrayList<>();
    for (Ordered o : out) {
      result.add(o.annotation);
    }
    return result;
  }

  /** The paragraphs of a value as {first line, last line}, blank-separated and fence-aware. */
  private static List<int[]> paragraphs(List<String> lines, boolean[] code) {
    List<int[]> out = new ArrayList<>();
    int k = 0;
    while (k < lines.size()) {
      if (isBlank(lines.get(k)) && !code[k]) {
        k++;
        continue;
      }
      int s = k;
      while (k + 1 < lines.size() && !(isBlank(lines.get(k + 1)) && !code[k + 1])) {
        k++;
      }
      out.add(new int[] {s, k});
      k++;
    }
    return out;
  }

  /** Inserts {@code block} after value line {@code end} (-1: at the start), one blank line on each side. */
  private static String insertAfterLine(String value, int end, List<String> block) {
    if (value.isEmpty()) {
      return String.join("\n", block);
    }
    List<String> lines = splitLines(value);
    List<String> before = lines.subList(0, end + 1);
    List<String> rest = lines.subList(end + 1, lines.size());
    List<String> out = new ArrayList<>(before);
    if (!before.isEmpty()) {
      out.add("");
    }
    out.addAll(block);
    if (!rest.isEmpty()) {
      if (!isBlank(rest.get(0))) {
        out.add("");
      }
      out.addAll(rest);
    }
    return String.join("\n", out);
  }

  /** Removes value lines [s, e] and one adjacent blank line. */
  private static String removeLines(String value, int s, int e) {
    List<String> lines = splitLines(value);
    int from = s;
    int to = e;
    if (to + 1 < lines.size() && isBlank(lines.get(to + 1))) {
      to++;
    } else if (from - 1 >= 0 && isBlank(lines.get(from - 1))) {
      from--;
    }
    lines.subList(from, to + 1).clear();
    String out = String.join("\n", lines);
    return trim(out).isEmpty() ? "" : out;
  }

  private static List<String> quoted(List<String> lines) {
    List<String> out = new ArrayList<>();
    for (String l : lines) {
      out.add(l.isEmpty() ? ">" : "> " + l);
    }
    return out;
  }

  /** The lines of a comment block; {@code author} may be null. */
  public static List<String> formatCommentBlock(String id, String text, String author) {
    List<String> t = splitLines(text);
    StringBuilder head = new StringBuilder("> " + ARROW + VS16 + " **" + id + "**");
    if (author != null && !author.isEmpty()) {
      head.append(" (").append(author).append("):");
    }
    if (!t.get(0).isEmpty()) {
      head.append(' ').append(t.get(0));
    }
    List<String> out = new ArrayList<>();
    out.add(head.toString());
    out.addAll(quoted(t.subList(1, t.size())));
    return out;
  }

  /** The lines of a question block. */
  public static List<String> formatQuestionBlock(SpecQuestionDraft q) {
    List<String> t = splitLines(q.text);
    List<String> lines = new ArrayList<>();
    lines.add(
        "> "
            + QUESTION_OPEN
            + " "
            + q.id
            + EM_DASH_SEP
            + (q.starred ? STAR + " " : "")
            + q.topic
            + ":** "
            + t.get(0));
    lines.addAll(quoted(t.subList(1, t.size())));
    for (String o : q.options) {
      lines.add("> - " + o);
    }
    if (!q.recommendation.isEmpty() || !q.assumption.isEmpty()) {
      lines.add(">");
      if (!q.recommendation.isEmpty()) {
        lines.add("> *Recommendation:* " + q.recommendation);
      }
      if (!q.assumption.isEmpty()) {
        lines.add("> *Working assumption until answered:* " + q.assumption);
      }
    }
    lines.add(">");
    lines.add("> " + ANSWER_LABEL);
    return lines;
  }

  /** Letters and digits (any script); punctuation and spaces are not. */
  private static boolean wordCharAt(String s, int i) {
    if (i < 0 || i >= s.length()) {
      return false;
    }
    char c = s.charAt(i);
    String cs = String.valueOf(c);
    return !cs.toLowerCase(Locale.ROOT).equals(cs.toUpperCase(Locale.ROOT))
        || (c >= '0' && c <= '9');
  }

  private static boolean wordChar(String s) {
    return !s.isEmpty() && wordCharAt(s, s.length() - 1);
  }

  private static boolean isSpace(char c) {
    return c == ' ' || c == '\t';
  }

  private static String trimEndSpaces(String s) {
    int k = s.length();
    while (k > 0 && isSpace(s.charAt(k - 1))) {
      k--;
    }
    return s.substring(0, k);
  }

  private static String trimStartSpaces(String s) {
    int k = 0;
    while (k < s.length() && isSpace(s.charAt(k))) {
      k++;
    }
    return s.substring(k);
  }

  /**
   * Applies a mark's replacement with the whitespace rules of SOM §11.9.3: never join two words,
   * never leave a double space or a space before punctuation, and a mark that was a whole line
   * leaves no blank line.
   */
  private static String replaceMark(String value, Mark m, String replacement0) {
    String replacement = replacement0;
    String before = value.substring(0, m.start);
    String after = value.substring(m.end);
    if (replacement.isEmpty()) {
      String tb = trimEndSpaces(before);
      String ta = trimStartSpaces(after);
      boolean lineStart = tb.isEmpty() || tb.endsWith("\n");
      boolean lineEnd = ta.isEmpty() || ta.startsWith("\n");
      if (lineStart && lineEnd) {
        // The mark was the whole line: the line goes, and with it one of the
        // newlines around it; a blank line left doubled is merged.
        before = tb;
        after = ta;
        if (after.startsWith("\n")) {
          after = after.substring(1);
        } else if (before.endsWith("\n")) {
          before = before.substring(0, before.length() - 1);
        }
        if ((before.isEmpty() || before.endsWith("\n\n")) && after.startsWith("\n")) {
          after = after.substring(1);
        }
        if (after.isEmpty()) {
          while (before.endsWith("\n")) {
            before = before.substring(0, before.length() - 1);
          }
        }
        return before + after;
      }
      if (!before.isEmpty() && isSpace(before.charAt(before.length() - 1))) {
        if (!after.isEmpty() && isSpace(after.charAt(0))) {
          after = trimStartSpaces(after);
        } else if (after.isEmpty()
            || after.startsWith("\n")
            || ".,;:!?)]}".indexOf(after.charAt(0)) >= 0) {
          before = trimEndSpaces(before);
        }
      } else if ((before.isEmpty() || before.endsWith("\n"))
          && !after.isEmpty()
          && isSpace(after.charAt(0))) {
        after = trimStartSpaces(after);
      }
      return before + after;
    }
    // Never join two words: a mark written flush against a word keeps a space
    // on that side.
    if (wordChar(before) && wordCharAt(replacement, 0)) {
      replacement = " " + replacement;
    }
    if (wordCharAt(replacement, replacement.length() - 1)
        && !after.isEmpty()
        && wordCharAt(after, 0)) {
      replacement = replacement + " ";
    }
    return before + replacement + after;
  }

  private static String markReplacement(Mark m, boolean accept) {
    switch (m.kind) {
      case INSERTION:
        return accept ? m.text : "";
      case DELETION:
        return accept ? "" : m.text;
      case SUBSTITUTION:
        return accept ? m.newText : m.text;
      case HIGHLIGHT:
        return m.text;
      default:
        return "";
    }
  }

  /**
   * {@code value} with every inline mark accepted ({@code accept}) or rejected, and every highlight
   * and comment mark removed, by the rules of SOM §11.9.3. Marks in code and malformed marks stay
   * as written.
   */
  public static String applyInlineMarksText(String value, boolean accept) {
    String v = value;
    List<Mark> marks = parse(v).marks;
    for (int k = marks.size() - 1; k >= 0; k--) {
      Mark m = marks.get(k);
      v = replaceMark(v, m, markReplacement(m, accept));
    }
    return v;
  }

  /**
   * {@code value} without any comment block, question block or inline mark (every mark accepted).
   * Plain quotes and code stay.
   */
  public static String stripAnnotationsText(String value) {
    String v = value;
    // Blocks, from the last up, so earlier line numbers stay valid.
    while (true) {
      Parsed p = parse(v);
      if (p.blocks.isEmpty()) {
        break;
      }
      Block b = p.blocks.get(p.blocks.size() - 1);
      v = removeLines(v, b.start, b.end);
    }
    while (true) {
      Parsed p = parse(v);
      if (p.marks.isEmpty()) {
        break;
      }
      Mark m = p.marks.get(p.marks.size() - 1);
      v = replaceMark(v, m, markReplacement(m, true));
    }
    return v;
  }

  // -------------------------------------------------------------------------
  // Document level.
  // -------------------------------------------------------------------------

  /** One value: its path, its field (null for content) and its text. */
  private static final class Value {
    final String path;
    final String field;
    final String text;

    Value(String path, String field, String text) {
      this.path = path;
      this.field = field;
      this.text = text;
    }
  }

  private static List<String> sorted(Set<String> keys) {
    List<String> out = new ArrayList<>(keys);
    Collections.sort(out);
    return out;
  }

  /** Every value, in document order. */
  private List<Value> values() {
    List<Value> out = new ArrayList<>();
    for (String path : sorted(doc.contentPaths())) {
      String v = doc.content(path);
      out.add(new Value(path, null, v == null ? "" : v));
    }
    for (String path : sorted(doc.formPaths())) {
      for (String f : sorted(doc.formFieldNames(path))) {
        String v = doc.formField(path, f);
        out.add(new Value(path, f, v == null ? "" : v));
      }
    }
    return out;
  }

  private String get(String path, String field) {
    String v = field == null ? doc.content(path) : doc.formField(path, field);
    return v == null ? "" : v;
  }

  private void set(String path, String field, String value) {
    if (field == null) {
      doc.setContent(path, value);
    } else {
      doc.setFormField(path, field, value);
    }
  }

  /** Every annotation, in document order. */
  public List<SpecReviewAnnotation> list() {
    List<SpecReviewAnnotation> out = new ArrayList<>();
    for (Value v : values()) {
      out.addAll(annotationsOf(parse(v.text), v.path, v.field, qualifier));
    }
    return out;
  }

  /** The counts a report needs. */
  public SpecReviewAnnotationCounts counts() {
    int q = 0;
    int open = 0;
    int c = 0;
    int m = 0;
    for (SpecReviewAnnotation a : list()) {
      switch (a.kind) {
        case QUESTION:
          q++;
          if (a.open()) {
            open++;
          }
          break;
        case COMMENT:
          c++;
          break;
        case MARK:
          m++;
          break;
      }
    }
    return new SpecReviewAnnotationCounts(q, open, q - open, c, m);
  }

  private int highestCommentNumber() {
    int high = 0;
    for (SpecReviewAnnotation a : list()) {
      if (a.kind == SpecReviewAnnotationKind.COMMENT && a.id != null) {
        int n = Integer.parseInt(a.id.substring(2));
        if (n > high) {
          high = n;
        }
      }
    }
    return high;
  }

  /** {@link #nextCommentId(int)} with floor 0. */
  public String nextCommentId() {
    return nextCommentId(0);
  }

  /**
   * The id the next comment gets: {@code C-<n>}, n = the highest number in the document (or
   * {@code floor}, when higher) plus one. Writes nothing.
   */
  public String nextCommentId(int floor) {
    int high = highestCommentNumber();
    return "C-" + (Math.max(high, floor) + 1);
  }

  /** {@link #assignCommentIds(int)} with floor 0. */
  public List<String> assignCommentIds() {
    return assignCommentIds(0);
  }

  /**
   * Gives every comment without an id the next one, in document order, and returns the ids
   * assigned. Nothing else changes.
   */
  public List<String> assignCommentIds(int floor) {
    int next = Math.max(highestCommentNumber(), floor) + 1;
    List<String> assigned = new ArrayList<>();
    for (Value v : values()) {
      Parsed p = parse(v.text);
      List<Comment> bare = new ArrayList<>();
      for (Comment c : p.comments) {
        if (c.id == null) {
          bare.add(c);
        }
      }
      if (bare.isEmpty()) {
        continue;
      }
      List<String> lines = splitLines(v.text);
      for (Comment c : bare) {
        String id = "C-" + next++;
        assigned.add(id);
        String raw = lines.get(c.block.start);
        int at = c.markerEnd;
        String line;
        if (at < raw.length() && raw.charAt(at) == ' ') {
          line = raw.substring(0, at + 1) + "**" + id + "** " + raw.substring(at + 1);
        } else if (at >= raw.length()) {
          line = raw + " **" + id + "**";
        } else {
          line = raw.substring(0, at) + " **" + id + "** " + raw.substring(at);
        }
        lines.set(c.block.start, line);
      }
      set(v.path, v.field, String.join("\n", lines));
    }
    return assigned;
  }

  /**
   * Inserts a comment block after paragraph {@code afterParagraph} (0-based; -1: at the start) of
   * the value at {@code path} / {@code field} (null for content), and returns its id — {@code id}
   * when given, else the next free one. {@code author} and {@code id} may be null.
   */
  public String insertComment(
      String path, String field, int afterParagraph, String text, String author, String id) {
    String cid = id != null ? id : nextCommentId();
    String value = get(path, field);
    int end = paragraphLastLine(value, afterParagraph);
    set(path, field, insertAfterLine(value, end, formatCommentBlock(cid, text, author)));
    return cid;
  }

  /**
   * Inserts a question block after paragraph {@code afterParagraph} (0-based; -1: at the start) of
   * the value at {@code path} / {@code field} (null for content).
   */
  public void insertQuestion(
      String path, String field, int afterParagraph, SpecQuestionDraft question) {
    String value = get(path, field);
    int end = paragraphLastLine(value, afterParagraph);
    set(path, field, insertAfterLine(value, end, formatQuestionBlock(question)));
  }

  /** Inserts a question block directly after the comment {@code commentId}. */
  public void insertQuestionAfterComment(String commentId, SpecQuestionDraft question) {
    FoundComment f = findComment(commentId);
    set(
        f.value.path,
        f.value.field,
        insertAfterLine(f.value.text, f.comment.block.end, formatQuestionBlock(question)));
  }

  /** Writes {@code answer} after the question's {@code **Answer:**} (empty: reopens it). */
  public void setAnswer(String questionId, String answer) {
    FoundQuestion f = findQuestion(questionId);
    Question q = f.question;
    List<String> lines = splitLines(f.value.text);
    List<String> a = splitLines(answer);
    List<String> written = new ArrayList<>();
    if (answer.isEmpty()) {
      written.add("> " + ANSWER_LABEL);
    } else {
      written.add("> " + ANSWER_LABEL + " " + a.get(0));
      written.addAll(quoted(a.subList(1, a.size())));
    }
    // The answer runs to the region's last non-empty line.
    int last = q.regionEnd;
    while (last > q.header && trim(inner(lines.get(last))).isEmpty()) {
      last--;
    }
    if (q.answerLine != null) {
      int from = q.answerLine;
      int to = last < from ? from : last;
      List<String> range = lines.subList(from, to + 1);
      range.clear();
      range.addAll(written);
    } else {
      List<String> insert = new ArrayList<>();
      insert.add(">");
      insert.addAll(written);
      lines.addAll(last + 1, insert);
    }
    set(f.value.path, f.value.field, String.join("\n", lines));
  }

  /** Replaces a comment's text; its marker, id and author stay as written. */
  public void editComment(String commentId, String text) {
    FoundComment f = findComment(commentId);
    Comment c = f.comment;
    List<String> lines = splitLines(f.value.text);
    List<String> t = splitLines(text);
    List<String> block = new ArrayList<>();
    block.add(trimRight(c.headerPrefix + t.get(0)));
    block.addAll(quoted(t.subList(1, t.size())));
    List<String> range = lines.subList(c.block.start, c.block.end + 1);
    range.clear();
    range.addAll(block);
    set(f.value.path, f.value.field, String.join("\n", lines));
  }

  /**
   * Removes one comment or question by id (a qualified comment id, {@code SBP C-12}, is accepted).
   * A question of a combined block takes only its own lines; the block goes when its last question
   * does.
   */
  public void resolve(String id) {
    String bare = id.contains(" ") ? id.substring(id.lastIndexOf(' ') + 1) : id;
    if (bare.startsWith("C-")) {
      FoundComment f = findComment(bare);
      set(
          f.value.path,
          f.value.field,
          removeLines(f.value.text, f.comment.block.start, f.comment.block.end));
      return;
    }
    FoundQuestion f = findQuestion(bare);
    Block b = f.block;
    Question q = f.question;
    if (b.questions.size() == 1) {
      set(f.value.path, f.value.field, removeLines(f.value.text, b.start, b.end));
      return;
    }
    List<String> lines = splitLines(f.value.text);
    lines.subList(q.header, q.regionEnd + 1).clear();
    // A last question leaves the separator `>` lines of the one before it.
    int end = b.end - (q.regionEnd - q.header + 1);
    while (end > b.start && trim(inner(lines.get(end))).isEmpty()) {
      lines.remove(end);
      end--;
    }
    set(f.value.path, f.value.field, String.join("\n", lines));
  }

  /**
   * Accepts ({@code accept}) or rejects the inline mark {@code index} (0-based among the marks of
   * the value at {@code path} / {@code field}, null for content).
   */
  public void applyMark(String path, String field, int index, boolean accept) {
    String value = get(path, field);
    List<Mark> marks = parse(value).marks;
    if (index < 0 || index >= marks.size()) {
      throw new SpecReviewAnnotationError(
          "no inline mark " + index + " at " + path + (field == null ? "" : " / " + field));
    }
    Mark m = marks.get(index);
    set(path, field, replaceMark(value, m, markReplacement(m, accept)));
  }

  private static final long FNV_OFFSET = 0xcbf29ce484222325L;
  private static final long FNV_PRIME = 0x100000001b3L;

  private static long fnvAdd(long h0, String s) {
    long h = h0;
    for (byte b : s.getBytes(StandardCharsets.UTF_8)) {
      h = (h ^ (b & 0xff)) * FNV_PRIME;
    }
    return h * FNV_PRIME;
  }

  /**
   * The revision the mark ids are stable for: FNV-1a 64-bit over the UTF-8 of every value in
   * document order (path, NUL, field or empty, NUL, text, NUL), as 16 lower-case hex digits. Any
   * change to a value changes it.
   */
  public String revision() {
    long h = FNV_OFFSET;
    for (Value v : values()) {
      h = fnvAdd(h, v.path);
      h = fnvAdd(h, v.field == null ? "" : v.field);
      h = fnvAdd(h, v.text);
    }
    String hex = Long.toUnsignedString(h, 16);
    StringBuilder sb = new StringBuilder();
    for (int k = hex.length(); k < 16; k++) {
      sb.append('0');
    }
    return sb.append(hex).toString();
  }

  private static boolean under(String path, String under) {
    return under == null || path.equals(under) || path.startsWith(under + "/");
  }

  /** Every inline mark of the document, in document order. */
  public List<SpecMarkEntry> listMarks() {
    return listMarks(null);
  }

  /** Every inline mark of the subtree at {@code path} (null: the document), in document order. */
  public List<SpecMarkEntry> listMarks(String path) {
    List<SpecMarkEntry> out = new ArrayList<>();
    int n = 0;
    for (Value v : values()) {
      Parsed p = parse(v.text);
      List<int[]> paras = paragraphs(p.lines, p.code);
      for (Mark m : p.marks) {
        String id = "M-" + (++n);
        if (!under(v.path, path)) {
          continue;
        }
        int[] para = new int[] {m.line, m.line};
        for (int[] r : paras) {
          if (r[0] <= m.line && m.line <= r[1]) {
            para = r;
            break;
          }
        }
        out.add(
            new SpecMarkEntry(
                id,
                v.path,
                v.field,
                m.line,
                m.kind,
                markReplacement(m, false),
                markReplacement(m, true),
                m.comment,
                v.text.substring(m.start, m.end),
                String.join("\n", p.lines.subList(para[0], para[1] + 1))));
      }
    }
    return out;
  }

  /**
   * Applies {@code decide} to every mark in the subtree {@code underPath} (null: the whole
   * document), one write per value.
   */
  private SpecMarkReport applyMarks(Function<String, SpecMarkDecision> decide, String underPath) {
    List<SpecMarkOutcome> applied = new ArrayList<>();
    List<SpecMarkIssue> issues = new ArrayList<>();
    int n = 0;
    for (Value val : values()) {
      Parsed p = parse(val.text);
      List<String> ids = new ArrayList<>();
      for (int k = 0; k < p.marks.size(); k++) {
        ids.add("M-" + (++n));
      }
      if (!under(val.path, underPath)) {
        continue;
      }
      for (Object[] issue : p.markIssues) {
        issues.add(new SpecMarkIssue(val.path, val.field, (Integer) issue[0], (String) issue[1]));
      }
      String v = val.text;
      List<SpecMarkOutcome> outcomes = new ArrayList<>();
      for (int k = p.marks.size() - 1; k >= 0; k--) {
        SpecMarkDecision d = decide.apply(ids.get(k));
        if (d == null || d == SpecMarkDecision.LEAVE) {
          continue;
        }
        Mark m = p.marks.get(k);
        String repl = markReplacement(m, d == SpecMarkDecision.ACCEPT);
        outcomes.add(
            0,
            new SpecMarkOutcome(
                ids.get(k),
                val.path,
                val.field,
                m.line,
                m.kind,
                d,
                val.text.substring(m.start, m.end),
                repl));
        v = replaceMark(v, m, repl);
      }
      if (!v.equals(val.text)) {
        set(val.path, val.field, v);
      }
      applied.addAll(outcomes);
    }
    return new SpecMarkReport(applied, issues);
  }

  /**
   * Applies one decision per named mark in one write. Refused — nothing changes — when the document
   * is no longer at {@code revision}, or when a decision names a mark that does not exist. Marks
   * not named, and marks decided {@code LEAVE}, stay.
   */
  public SpecMarkReport decideMarks(Map<String, SpecMarkDecision> decisions, String revision) {
    String current = revision();
    if (!revision.equals(current)) {
      throw new SpecReviewAnnotationError(
          "the document changed since revision "
              + revision
              + " (now "
              + current
              + "); list the marks again");
    }
    Set<String> known = new HashSet<>();
    for (SpecMarkEntry m : listMarks()) {
      known.add(m.id);
    }
    for (String id : decisions.keySet()) {
      if (!known.contains(id)) {
        throw new SpecReviewAnnotationError("no inline mark " + id + " in the document");
      }
    }
    return applyMarks(decisions::get, null);
  }

  /** Accepts every inline mark of the document. */
  public SpecMarkReport acceptAllMarks() {
    return acceptAllMarks(null);
  }

  /** Accepts every inline mark under {@code path} (null: the whole document). */
  public SpecMarkReport acceptAllMarks(String path) {
    return applyMarks(id -> SpecMarkDecision.ACCEPT, path);
  }

  /** Rejects every inline mark of the document. */
  public SpecMarkReport rejectAllMarks() {
    return rejectAllMarks(null);
  }

  /** Rejects every inline mark under {@code path} (null: the whole document). */
  public SpecMarkReport rejectAllMarks(String path) {
    return applyMarks(id -> SpecMarkDecision.REJECT, path);
  }

  /**
   * Removes every annotation and writes the result back: every inline mark accepted, every comment
   * and question block removed. Malformed marks stay and are reported.
   */
  public SpecMarkReport removeAllAnnotations() {
    SpecMarkReport report = acceptAllMarks();
    for (Value val : values()) {
      String v = val.text;
      while (true) {
        Parsed p = parse(v);
        if (p.blocks.isEmpty()) {
          break;
        }
        Block b = p.blocks.get(p.blocks.size() - 1);
        v = removeLines(v, b.start, b.end);
      }
      if (!v.equals(val.text)) {
        set(val.path, val.field, v);
      }
    }
    return report;
  }

  /** A copy of the document without any annotation, for reading. The document is unchanged. */
  public SpecDocument stripped() {
    SpecDocument copy = new SpecDocument();
    copy.loadJson(doc.toJson());
    for (Value v : values()) {
      String clean = stripAnnotationsText(v.text);
      if (clean.equals(v.text)) {
        continue;
      }
      if (v.field == null) {
        copy.setContent(v.path, clean);
      } else {
        copy.setFormField(v.path, v.field, clean);
      }
    }
    return copy;
  }

  private static int paragraphLastLine(String value, int afterParagraph) {
    if (afterParagraph < 0) {
      return -1;
    }
    List<String> lines = splitLines(value);
    List<int[]> paras = paragraphs(lines, codeLines(lines));
    if (value.isEmpty() || afterParagraph >= paras.size()) {
      throw new SpecReviewAnnotationError(
          "the value has "
              + (value.isEmpty() ? 0 : paras.size())
              + " paragraph(s); there is no paragraph "
              + afterParagraph);
    }
    return paras.get(afterParagraph)[1];
  }

  private static final class FoundComment {
    final Value value;
    final Comment comment;

    FoundComment(Value value, Comment comment) {
      this.value = value;
      this.comment = comment;
    }
  }

  private static final class FoundQuestion {
    final Value value;
    final Block block;
    final Question question;

    FoundQuestion(Value value, Block block, Question question) {
      this.value = value;
      this.block = block;
      this.question = question;
    }
  }

  private FoundComment findComment(String id) {
    for (Value v : values()) {
      for (Comment c : parse(v.text).comments) {
        if (id.equals(c.id)) {
          return new FoundComment(v, c);
        }
      }
    }
    throw new SpecReviewAnnotationError("no comment " + id + " in the document");
  }

  private FoundQuestion findQuestion(String id) {
    for (Value v : values()) {
      Parsed p = parse(v.text);
      for (Block b : p.blocks) {
        for (Question q : b.questions) {
          if (q.id.equals(id)) {
            return new FoundQuestion(v, b, q);
          }
        }
      }
    }
    throw new SpecReviewAnnotationError("no question " + id + " in the document");
  }

  /** The instance-tier findings on annotations (SOM §11.9.5), ordered by path. */
  public List<SpecValidationError> validate() {
    List<SpecValidationError> errors = new ArrayList<>();
    Set<String> seen = new HashSet<>();
    for (Value v : values()) {
      Parsed p = parse(v.text);
      String where = v.field == null ? v.path : v.path + " / " + v.field;
      for (String m : p.malformed) {
        errors.add(
            new SpecValidationError(
                v.path, SpecValidationCode.ANNOTATION_MALFORMED, where + ", " + m));
      }
      if (v.field != null) {
        for (Block b : p.blocks) {
          errors.add(
              new SpecValidationError(
                  v.path,
                  SpecValidationCode.ANNOTATION_MISPLACED,
                  where
                      + ", line "
                      + b.start
                      + ": a "
                      + b.kind.value
                      + " block sits in a form field value; it belongs in the form's preamble,"
                      + " above the first field (SOM §11.9.4)"));
        }
      }
      List<String> ids = new ArrayList<>();
      for (Comment c : p.comments) {
        if (c.id != null) {
          ids.add(c.id);
        }
      }
      for (Block b : p.blocks) {
        for (Question q : b.questions) {
          ids.add(q.id);
        }
      }
      for (String id : ids) {
        if (!seen.add(id)) {
          errors.add(
              new SpecValidationError(
                  v.path,
                  SpecValidationCode.DUPLICATE_ANNOTATION_ID,
                  where + ": " + id + " is used more than once in the document"));
        }
      }
    }
    // List.sort is stable: equal paths keep their finding order.
    errors.sort(Comparator.comparing((SpecValidationError e) -> e.path));
    return errors;
  }
}
