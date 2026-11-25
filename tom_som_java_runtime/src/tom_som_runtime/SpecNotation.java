package tom_som_runtime;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The reading notation's scanner: one call per text value, returning the
 * value's fenced divs, bracketed spans and citation shapes with their kind,
 * attributes, source ranges and nesting, and the findings the DocSpecs
 * specification lists for the notation (<em>Reading Notation</em>, RN-1 …
 * RN-13).
 *
 * <p>The Java port of {@code tom_som_typescript_runtime}'s {@code
 * spec_notation.ts} (itself the port of {@code tom_som_dart_runtime}'s {@code
 * spec_notation.dart}): the same grammar, the same elements and findings, the
 * same UTF-16 offsets (a Java {@code String} index is one); all run {@code
 * tom_som_conformance/corpus/notation_cases.json}.
 *
 * <ul>
 *   <li>a <b>fenced div</b> is a line of at least three colons, indented up to
 *       three spaces, then attribute braces ({@code ::: {.provenance}}) or a
 *       bare kind word ({@code ::: aside}); it closes at a line of at least
 *       three colons and nothing else, and a closing fence closes the innermost
 *       open div;
 *   <li>a <b>bracketed span</b> is {@code [text]} followed immediately by
 *       attribute braces, inside one paragraph;
 *   <li>a <b>citation shape</b> is {@code (-> ids)} (kind {@code trace}),
 *       {@code (<- source)} or {@code (<~ source)} (kind {@code provenance});
 *   <li>fenced code and code spans are literal, and so are {@code \:::} and
 *       {@code ]\{.}.
 * </ul>
 *
 * <p>An unknown kind passes through as an element like any other. The patterns
 * follow the JavaScript regular expressions of the references: {@code .} does
 * not match {@code \r}, {@code  } or {@code  }, and whitespace is
 * ECMAScript's.
 */
public final class SpecNotation {
  private SpecNotation() {}

  /** The kinds the notation registers (RN-5); any other kind passes through. */
  public static final Set<String> registeredNotationKinds =
      Collections.unmodifiableSet(
          new LinkedHashSet<>(
              Arrays.asList(
                  "provenance",
                  "trace",
                  "editorial",
                  "aside",
                  "linked",
                  "derived",
                  "refs",
                  "records",
                  "rejected")));

  /** The severity of {@code code}: an unknown kind is a {@code "warning"}, the rest {@code "error"}s. */
  public static String notationSeverity(NotationFindingCode code) {
    return code == NotationFindingCode.UNKNOWN_KIND ? "warning" : "error";
  }

  /**
   * Scans one text value for the reading notation. {@code tomSpecs} says the
   * value belongs to a TomSpecs rendition: only then are a div without a class
   * and an unregistered kind reported (RN-10).
   */
  public static NotationScan scanNotation(String text, boolean tomSpecs) {
    return new Scanner(text, tomSpecs).scan();
  }

  /** {@link #scanNotation(String, boolean)} outside a TomSpecs rendition. */
  public static NotationScan scanNotation(String text) {
    return scanNotation(text, false);
  }

  // --- Patterns (ECMAScript semantics) --------------------------------------

  /** ECMAScript's {@code \s}. */
  private static final String WS =
      "\\t\\n\\u000B\\f\\r \\u00A0\\u1680\\u2000-\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000\\uFEFF";
  /** ECMAScript's {@code .}. */
  private static final String DOT = "[^\\n\\r\\u2028\\u2029]";

  private static final Pattern DIV_OPEN =
      Pattern.compile(
          " {0,3}:{3,}[ \\t]*(?:\\{(" + DOT + "*)\\}|([A-Za-z][A-Za-z0-9_-]*))[ \\t]*");
  private static final Pattern DIV_CLOSE = Pattern.compile(" {0,3}:{3,}[ \\t]*");
  private static final Pattern CODE_FENCE_OPEN =
      Pattern.compile(" {0,3}(`{3,}|~{3,})(" + DOT + "*)");
  private static final Pattern QUOTE_LINE = Pattern.compile(" {0,3}>");
  private static final Pattern ANNOTATION_START =
      Pattern.compile(" {0,3}> ?(?:⬆|\\*\\*❓|⚖)");
  private static final Pattern QUOTED_DIV_OPEN =
      Pattern.compile(
          " {0,3}>[ \\t]?( {0,3}:{3,}[ \\t]*(?:\\{"
              + DOT
              + "*\\}|[A-Za-z][A-Za-z0-9_-]*)[ \\t]*)");
  private static final Pattern ATTRIBUTE_TOKEN =
      Pattern.compile(
          "\\.([^"
              + WS
              + ".#}=\"']+)|#([^"
              + WS
              + ".#}=\"']+)|([A-Za-z_][A-Za-z0-9_:.-]*)=(\"[^\"]*\"|'[^']*'|[^"
              + WS
              + "}]+)");

  private static final String ASCII_PUNCTUATION = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~";
  private static final String[] MARK_OPENERS = {"{++", "{--", "{~~", "{==", "{>>"};
  private static final Map<String, String> MARK_CLOSERS = new HashMap<>();
  private static final Map<String, String> CITATION_KINDS = new HashMap<>();
  private static final List<String> TYPE_ORDER = Arrays.asList("div", "span", "citation");

  static {
    MARK_CLOSERS.put("{++", "++}");
    MARK_CLOSERS.put("{--", "--}");
    MARK_CLOSERS.put("{~~", "~~}");
    MARK_CLOSERS.put("{==", "==}");
    MARK_CLOSERS.put("{>>", "<<}");
    CITATION_KINDS.put("->", "trace");
    CITATION_KINDS.put("<-", "provenance");
    CITATION_KINDS.put("<~", "provenance");
  }

  static boolean isJsWhitespace(char c) {
    switch (c) {
      case '\t':
      case '\n':
      case '\u000B':
      case '\f':
      case '\r':
      case ' ':
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

  /** ECMAScript's {@code String.prototype.trimStart}. */
  private static String trimStart(String s) {
    int i = 0;
    while (i < s.length() && isJsWhitespace(s.charAt(i))) {
      i++;
    }
    return s.substring(i);
  }

  /** ECMAScript's {@code String.prototype.trim}. */
  static String jsTrim(String s) {
    int i = 0;
    int e = s.length();
    while (i < e && isJsWhitespace(s.charAt(i))) {
      i++;
    }
    while (e > i && isJsWhitespace(s.charAt(e - 1))) {
      e--;
    }
    return s.substring(i, e);
  }

  /** Whether ECMAScript's {@code trim()} of {@code s} is empty. */
  static boolean isBlank(String s) {
    for (int i = 0; i < s.length(); i++) {
      if (!isJsWhitespace(s.charAt(i))) {
        return false;
      }
    }
    return true;
  }

  private static String markOpenerAt(String text, int i) {
    for (String o : MARK_OPENERS) {
      if (text.startsWith(o, i)) {
        return o;
      }
    }
    return null;
  }

  /** The parsed attribute braces: classes, the id and the pairs. */
  private static final class Attributes {
    final List<String> classes;
    final String id;
    final Map<String, String> pairs;

    Attributes(List<String> classes, String id, Map<String, String> pairs) {
      this.classes = classes;
      this.id = id;
      this.pairs = pairs;
    }
  }

  private static Attributes parseAttributes(String inner) {
    List<String> classes = new ArrayList<>();
    String id = null;
    Map<String, String> pairs = new LinkedHashMap<>();
    Matcher m = ATTRIBUTE_TOKEN.matcher(inner);
    while (m.find()) {
      if (m.group(1) != null) {
        classes.add(m.group(1));
      } else if (m.group(2) != null) {
        if (id == null) {
          id = m.group(2);
        }
      } else {
        String value = m.group(4);
        if (value.length() >= 2
            && ((value.startsWith("\"") && value.endsWith("\""))
                || (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length() - 1);
        }
        pairs.put(m.group(3), value);
      }
    }
    return new Attributes(classes, id, pairs);
  }

  /** An open div while the blocks are scanned. */
  private static final class OpenDiv {
    final int start;
    final int contentStart;
    final int line;
    final Attributes attributes;

    OpenDiv(int start, int contentStart, int line, Attributes attributes) {
      this.start = start;
      this.contentStart = contentStart;
      this.line = line;
      this.attributes = attributes;
    }
  }

  private static final class Scanner {
    final String text;
    final boolean tomSpecs;
    final List<Integer> lineStarts = new ArrayList<>();
    final List<String> lines = new ArrayList<>();
    final List<NotationElement> elements = new ArrayList<>();
    final List<NotationFinding> findings = new ArrayList<>();

    // The paragraph region being collected by blocks(); null start: none.
    Integer regionStart;
    int regionEnd;

    Scanner(String text, boolean tomSpecs) {
      this.text = text;
      this.tomSpecs = tomSpecs;
      int offset = 0;
      for (String line : text.split("\n", -1)) {
        lineStarts.add(offset);
        lines.add(line);
        offset += line.length() + 1;
      }
    }

    int lineOf(int offset) {
      int lo = 0;
      int hi = lineStarts.size() - 1;
      while (lo < hi) {
        int mid = (lo + hi + 1) >> 1;
        if (lineStarts.get(mid) <= offset) {
          lo = mid;
        } else {
          hi = mid - 1;
        }
      }
      return lo + 1;
    }

    void find(NotationFindingCode code, int offset, String message) {
      findings.add(new NotationFinding(code, offset, lineOf(offset), message));
    }

    NotationScan scan() {
      blocks();
      kindFindings();
      List<NotationElement> sorted = new ArrayList<>(elements);
      sorted.sort(
          (a, b) -> {
            if (a.start != b.start) {
              return Integer.compare(a.start, b.start);
            }
            if (a.end != b.end) {
              return Integer.compare(b.end, a.end);
            }
            return Integer.compare(TYPE_ORDER.indexOf(a.type), TYPE_ORDER.indexOf(b.type));
          });
      List<NotationElement> roots = new ArrayList<>();
      Deque<NotationElement> stack = new ArrayDeque<>();
      for (NotationElement e : sorted) {
        while (!stack.isEmpty()
            && !(e.start >= stack.peek().start && e.end <= stack.peek().end)) {
          stack.pop();
        }
        (stack.isEmpty() ? roots : stack.peek().children).add(e);
        stack.push(e);
      }
      List<NotationFinding> ordered = new ArrayList<>(findings);
      ordered.sort(
          (a, b) ->
              a.offset != b.offset
                  ? Integer.compare(a.offset, b.offset)
                  : Integer.compare(a.code.ordinal(), b.code.ordinal()));
      return new NotationScan(text, roots, ordered);
    }

    // --- Blocks -------------------------------------------------------------

    private void endRegion() {
      if (regionStart != null) {
        inline(regionStart, regionEnd);
      }
      regionStart = null;
    }

    void blocks() {
      Deque<OpenDiv> open = new ArrayDeque<>();
      String codeFence = null;
      boolean inAnnotation = false;
      regionStart = null;
      regionEnd = 0;

      for (int i = 0; i < lines.size(); i++) {
        String line = lines.get(i);
        int start = lineStarts.get(i);
        int lineEnd = start + line.length();
        int next = i + 1 < lines.size() ? lineStarts.get(i + 1) : text.length();

        if (codeFence != null) {
          String t = trimStart(line);
          if (line.length() - t.length() <= 3
              && t.startsWith(codeFence)
              && isBlank(
                  t.substring(codeFence.length())
                      .replace(String.valueOf(codeFence.charAt(0)), ""))) {
            codeFence = null;
          }
          continue;
        }

        if (ANNOTATION_START.matcher(line).lookingAt()) {
          if (!inAnnotation && !open.isEmpty()) {
            find(
                NotationFindingCode.ANNOTATION_INSIDE_DIV,
                start,
                "a comment or question block stands inside a div");
          }
          inAnnotation = true;
        } else if (!QUOTE_LINE.matcher(line).lookingAt()) {
          inAnnotation = false;
        }
        if (inAnnotation) {
          if (QUOTED_DIV_OPEN.matcher(line).matches()) {
            find(
                NotationFindingCode.DIV_INSIDE_ANNOTATION,
                start,
                "a div stands inside a comment or question block");
          }
          if (regionStart == null) {
            regionStart = start;
          }
          regionEnd = lineEnd;
          continue;
        }

        Matcher code = CODE_FENCE_OPEN.matcher(line);
        if (code.matches() && !(code.group(1).startsWith("`") && code.group(2).contains("`"))) {
          endRegion();
          codeFence = code.group(1);
          continue;
        }

        Matcher divOpen = DIV_OPEN.matcher(line);
        if (divOpen.matches()) {
          endRegion();
          Attributes attributes =
              divOpen.group(1) != null
                  ? parseAttributes(divOpen.group(1))
                  : new Attributes(
                      new ArrayList<>(List.of(divOpen.group(2))), null, new LinkedHashMap<>());
          open.push(new OpenDiv(start, next, i + 1, attributes));
          continue;
        }

        if (DIV_CLOSE.matcher(line).matches()) {
          endRegion();
          OpenDiv d = open.poll();
          if (d == null) {
            find(
                NotationFindingCode.STRAY_CLOSING_FENCE,
                start,
                "a closing fence has no open div");
          } else {
            addDiv(d, lineEnd, start, true);
          }
          continue;
        }

        if (isBlank(line)) {
          endRegion();
          continue;
        }
        if (regionStart == null) {
          regionStart = start;
        }
        regionEnd = lineEnd;
      }
      endRegion();
      while (!open.isEmpty()) {
        OpenDiv d = open.pop();
        find(NotationFindingCode.UNCLOSED_DIV, d.start, "an opening fence has no closing fence");
        addDiv(d, text.length(), text.length(), false);
      }
    }

    void addDiv(OpenDiv d, int end, int contentEnd, boolean closed) {
      Attributes a = d.attributes;
      int contentStart = d.contentStart > contentEnd ? contentEnd : d.contentStart;
      elements.add(
          new NotationElement(
              "div",
              a.classes.isEmpty() ? null : a.classes.get(0),
              a.classes,
              a.id,
              a.pairs,
              null,
              d.start,
              end,
              contentStart,
              contentEnd,
              d.line,
              lineOf(end > d.start ? end - 1 : d.start),
              closed));
    }

    // --- Inline -------------------------------------------------------------

    void inline(int start, int end) {
      Map<Integer, Integer> literal = new HashMap<>();
      Set<Integer> escaped = new HashSet<>();
      for (int i = start; i < end; i++) {
        char c = text.charAt(i);
        if (c == '\\' && i + 1 < end && ASCII_PUNCTUATION.indexOf(text.charAt(i + 1)) >= 0) {
          escaped.add(i + 1);
          i++;
          continue;
        }
        if (c == '`') {
          int n = 0;
          while (i + n < end && text.charAt(i + n) == '`') {
            n++;
          }
          int close = closingBackticks(i + n, end, n);
          if (close >= 0) {
            literal.put(i, close + n);
            i = close + n - 1;
          } else {
            i += n - 1;
          }
        }
      }

      List<NotationElement> spans = new ArrayList<>();
      List<int[]> marks = new ArrayList<>();
      Deque<Integer> brackets = new ArrayDeque<>();
      int i = start;
      while (i < end) {
        Integer skip = literal.get(i);
        if (skip != null) {
          i = skip;
          continue;
        }
        char c = text.charAt(i);
        if (escaped.contains(i) || (c == '\\' && escaped.contains(i + 1))) {
          i++;
          continue;
        }
        if (c == '{') {
          String opener = markOpenerAt(text, i);
          if (opener != null) {
            String closer = MARK_CLOSERS.get(opener);
            int close = text.indexOf(closer, i + 3);
            if (close >= 0 && close + closer.length() <= end) {
              marks.add(new int[] {i, close + closer.length()});
            }
            i += 3;
            continue;
          }
        }
        if (c == '[') {
          brackets.push(i);
        } else if (c == ']' && !brackets.isEmpty()) {
          int openAt = brackets.pop();
          if (i + 1 < end
              && text.charAt(i + 1) == '{'
              && !escaped.contains(i + 1)
              && markOpenerAt(text, i + 1) == null) {
            int close = closingBrace(i + 2, end);
            if (close < 0) {
              find(
                  NotationFindingCode.UNCLOSED_SPAN,
                  i + 1,
                  "a span's attribute braces do not close on the paragraph");
            } else {
              Attributes a = parseAttributes(text.substring(i + 2, close));
              NotationElement span =
                  new NotationElement(
                      "span",
                      a.classes.isEmpty() ? null : a.classes.get(0),
                      a.classes,
                      a.id,
                      a.pairs,
                      null,
                      openAt,
                      close + 1,
                      openAt + 1,
                      i,
                      lineOf(openAt),
                      lineOf(close),
                      true);
              spans.add(span);
              elements.add(span);
              i = close + 1;
              continue;
            }
          }
        } else if (c == '(' && i + 3 < end && text.charAt(i + 3) == ' ') {
          String arrow = text.substring(i + 1, i + 3);
          String kind = CITATION_KINDS.get(arrow);
          if (kind != null) {
            int close = closingParenthesis(i + 4, end, literal);
            if (close > i + 4 && !isBlank(text.substring(i + 4, close))) {
              NotationElement citation =
                  new NotationElement(
                      "citation",
                      kind,
                      new ArrayList<>(List.of(kind)),
                      null,
                      new LinkedHashMap<>(),
                      arrow,
                      i,
                      close + 1,
                      i + 4,
                      close,
                      lineOf(i),
                      lineOf(close),
                      true);
              spans.add(citation);
              elements.add(citation);
              i += 4;
              continue;
            }
          }
        }
        i++;
      }

      for (int[] mark : marks) {
        int ms = mark[0];
        int me = mark[1];
        for (NotationElement e : spans) {
          boolean crosses =
              (ms < e.start && e.start < me && me < e.end)
                  || (e.start < ms && ms < e.end && e.end < me);
          if (crosses) {
            find(
                NotationFindingCode.MARK_ACROSS_NOTATION,
                ms,
                "an inline review mark crosses the boundary of a " + e.type);
            break;
          }
        }
      }
    }

    int closingBackticks(int from, int end, int n) {
      int i = from;
      while (i < end) {
        if (text.charAt(i) == '`') {
          int m = 0;
          while (i + m < end && text.charAt(i + m) == '`') {
            m++;
          }
          if (m == n) {
            return i;
          }
          i += m;
        } else {
          i++;
        }
      }
      return -1;
    }

    int closingBrace(int from, int end) {
      char quote = 0;
      for (int i = from; i < end; i++) {
        char c = text.charAt(i);
        if (quote != 0) {
          if (c == quote) {
            quote = 0;
          }
        } else if (c == '"' || c == '\'') {
          quote = c;
        } else if (c == '}') {
          return i;
        } else if (c == '{') {
          return -1;
        }
      }
      return -1;
    }

    int closingParenthesis(int from, int end, Map<Integer, Integer> literal) {
      int depth = 0;
      int i = from;
      while (i < end) {
        Integer skip = literal.get(i);
        if (skip != null) {
          i = skip;
          continue;
        }
        char c = text.charAt(i);
        if (c == '(') {
          depth++;
        } else if (c == ')') {
          if (depth == 0) {
            return i;
          }
          depth--;
        }
        i++;
      }
      return -1;
    }

    // --- Kinds --------------------------------------------------------------

    void kindFindings() {
      for (NotationElement e : new ArrayList<>(elements)) {
        if ("citation".equals(e.type)) {
          continue;
        }
        if ("div".equals(e.type) && "rejected".equals(e.kind)) {
          find(
              NotationFindingCode.REJECTED_BLOCK,
              e.start,
              "a rejected block waits for its resolution");
        }
        if (!tomSpecs) {
          continue;
        }
        if (e.kind == null) {
          if ("div".equals(e.type)) {
            find(
                NotationFindingCode.DIV_WITHOUT_KIND,
                e.start,
                "a div's attributes hold no class");
          }
        } else if (!e.isRegistered()) {
          find(
              NotationFindingCode.UNKNOWN_KIND,
              e.start,
              "the kind \"" + e.kind + "\" is not registered");
        }
      }
    }
  }
}
