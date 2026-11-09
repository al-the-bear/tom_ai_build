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
import java.util.Objects;
import java.nio.charset.StandardCharsets;
import java.util.Set;
import java.util.function.BiFunction;
import java.util.function.IntUnaryOperator;
import java.util.function.Supplier;
import java.time.OffsetDateTime;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The review annotations of a document (SOM §11.9) — comment blocks, question blocks and
 * CriticMarkup inline marks in its content and form-field values — and the operations that edit
 * them in place. A faithful port of {@code tom_som_dart_runtime/lib/src/spec_review_annotations.dart};
 * the team-review notation (SOM §11.9.8) and the merge's text-level building blocks follow {@code
 * tom_som_typescript_runtime/src/spec_review_annotations.ts}.
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

  /**
   * The clock the write operations take a change time from when no {@code at} is passed (SOM
   * §11.9.10); null: the system clock in the writer's offset.
   */
  public final Supplier<String> clock;

  /** Wraps {@code doc}; {@code qualifier} may be null. */
  public SpecReviewAnnotations(SpecDocument doc, String qualifier) {
    this(doc, qualifier, null);
  }

  /**
   * Wraps {@code doc}; {@code qualifier} and {@code clock} may be null. {@code clock} fixes the
   * change time the writes record (the conformance drivers pass a fixed one).
   */
  public SpecReviewAnnotations(SpecDocument doc, String qualifier, Supplier<String> clock) {
    this.doc = doc;
    this.qualifier = qualifier;
    this.clock = clock;
  }

  /** The change time a write records: {@code at} normalized, else the clock's. */
  private String time(String at) {
    if (at != null) {
      return normalizeReviewTime(at);
    }
    return clock != null ? clock.get() : systemReviewTime();
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
  private static final String SCALES = "⚖";
  private static final String DECISION_LABEL = "**Decision:**";
  private static final String UNRESOLVED_PREFIX = "open:";

  /** The start of an individual answer line, {@code **Answer (alice, bob):**} (SOM §11.9.8). */
  private static final Pattern INDIVIDUAL_ANSWER =
      Pattern.compile("^\\*\\*Answer \\(([^)]*)\\):\\*\\*");

  /** A member id (SOM §11.9.8): lowercase letters, digits and {@code _}. */
  private static final Pattern MEMBER_ID = Pattern.compile("[a-z0-9_]+");

  private static final Pattern COMMENT_NUMBER = Pattern.compile("[1-9][0-9]*");
  private static final Pattern QUESTION_ID = Pattern.compile("[A-Z][A-Z0-9]*-[0-9]+");

  /**
   * A question header's id with its optional change time (SOM §11.9.2, §11.9.10): {@code BQ-81} or
   * {@code BQ-81 (2026-11-07T14:05+01:00)}.
   */
  private static final Pattern HEADER_ID =
      Pattern.compile("([A-Z][A-Z0-9]*-[0-9]+)(?: \\(([^)]*)\\))?");

  private static final List<String> OPENERS = Arrays.asList("{>>", "{==", "{++", "{--", "{~~");
  private static final Map<String, String> CLOSERS = new LinkedHashMap<>();

  static {
    CLOSERS.put("{>>", "<<}");
    CLOSERS.put("{==", "==}");
    CLOSERS.put("{++", "++}");
    CLOSERS.put("{--", "--}");
    CLOSERS.put("{~~", "~~}");
  }

  /** Whether {@code s} is a member id (SOM §11.9.8): lowercase letters, digits and {@code _}. */
  public static boolean isReviewMemberId(String s) {
    return MEMBER_ID.matcher(s).matches();
  }

  /**
   * A change time as annotations write it (SOM §11.9.10): minutes with the writer's UTC offset,
   * {@code 2026-11-07T14:05+01:00} or {@code 2026-11-07T13:05Z}.
   */
  private static final Pattern REVIEW_TIME =
      Pattern.compile("[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(?:Z|[+-][0-9]{2}:[0-9]{2})");

  /**
   * An ISO 8601 time a caller may pass as {@code at}: minutes, optional seconds and fraction, and
   * an offset or {@code Z}.
   */
  private static final Pattern REVIEW_TIME_IN =
      Pattern.compile(
          "([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2})(?::[0-9]{2}(?:\\.[0-9]+)?)?"
              + "(Z|[+-][0-9]{2}:[0-9]{2})");

  /** Whether {@code s} is a change time of the form SOM §11.9.10 fixes. */
  public static boolean isReviewTime(String s) {
    return REVIEW_TIME.matcher(s).matches();
  }

  /**
   * {@code at} as a change time (SOM §11.9.10): seconds and fractions cut, the offset kept as
   * given. Throws {@link SpecReviewAnnotationError} for any other shape.
   */
  public static String normalizeReviewTime(String at) {
    Matcher m = REVIEW_TIME_IN.matcher(trim(at));
    if (!m.matches()) {
      throw new SpecReviewAnnotationError(
          "\""
              + at
              + "\" is not an ISO 8601 time with an offset or Z (e.g. 2026-11-07T14:05+01:00)");
    }
    return m.group(1) + m.group(2);
  }

  /** The system clock's time as a change time in its local offset. */
  public static String systemReviewTime() {
    return systemReviewTime(OffsetDateTime.now());
  }

  /** {@code now} as a change time in its offset. */
  public static String systemReviewTime(OffsetDateTime now) {
    int secs = now.getOffset().getTotalSeconds();
    String sign = secs < 0 ? "-" : "+";
    int mins = Math.abs(secs) / 60;
    return String.format(
        Locale.ROOT,
        "%04d-%02d-%02dT%02d:%02d%s%02d:%02d",
        now.getYear(),
        now.getMonthValue(),
        now.getDayOfMonth(),
        now.getHour(),
        now.getMinute(),
        sign,
        mins / 60,
        mins % 60);
  }

  /** Comma-separated parts with a trailing change time taken off (SOM §11.9.10). */
  private static final class TimeSplit {
    final List<String> parts;
    final String time;

    TimeSplit(List<String> parts, String time) {
      this.parts = parts;
      this.time = time;
    }
  }

  /**
   * {@code parts} (a header's or an answer's comma-separated parts) split into the parts before a
   * trailing change time and the time (SOM §11.9.10).
   */
  private static TimeSplit splitTime(List<String> parts) {
    if (!parts.isEmpty() && isReviewTime(trim(parts.get(parts.size() - 1)))) {
      return new TimeSplit(
          parts.subList(0, parts.size() - 1), trim(parts.get(parts.size() - 1)));
    }
    return new TimeSplit(parts, null);
  }

  /** {@code s} split on commas, empty parts kept. */
  private static List<String> commaParts(String s) {
    return Arrays.asList(s.split(",", -1));
  }

  /** Whether an answer or a decision begins with {@code open:} (SOM §11.9.8). */
  static boolean isUnresolved(String answer) {
    return answer.startsWith(UNRESOLVED_PREFIX);
  }

  /** A conflict decision's letter: {@code a}…, {@code base}, or null (rewritten text or none). */
  static String decisionLetter(String decision) {
    String t = trimLeft(decision);
    if (t.startsWith("(base)") || t.startsWith("**(base)**")) {
      return "base";
    }
    return isUnresolved(t) ? null : leadingLetter(t);
  }

  /** Whether {@code s} starts with an individual answer label, {@code **Answer (…):**}. */
  private static boolean isIndividualAnswer(String s) {
    return INDIVIDUAL_ANSWER.matcher(s).find();
  }

  /** One parsed block of a value (lines [start, end] inclusive). */
  private static final class Block {
    final int start;
    final int end;
    final SpecReviewAnnotationKind kind;
    List<Question> questions = new ArrayList<>();
    boolean combined;
    /** The parsed comment of a comment block, else null. */
    Comment comment;
    /** The parsed conflict of a conflict block, else null. */
    Conflict conflict;

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
    final List<SpecQuestionOption> options;
    final String recommended;
    final List<IndividualAnswer> answers;
    /** The time in the header (SOM §11.9.10), or null. */
    final String changedAt;
    /** The time of the team answer (SOM §11.9.10), or null. */
    final String answerChangedAt;

    Question(
        int header,
        int regionEnd,
        Integer answerLine,
        String id,
        String topic,
        boolean starred,
        String text,
        String answer,
        List<SpecQuestionOption> options,
        String recommended,
        List<IndividualAnswer> answers,
        String changedAt,
        String answerChangedAt) {
      this.header = header;
      this.regionEnd = regionEnd;
      this.answerLine = answerLine;
      this.id = id;
      this.topic = topic;
      this.starred = starred;
      this.text = text;
      this.answer = answer;
      this.options = options;
      this.recommended = recommended;
      this.answers = answers;
      this.changedAt = changedAt;
      this.answerChangedAt = answerChangedAt;
    }
  }

  /** One {@code **Answer (<ids>):**} entry of a question (SOM §11.9.8). */
  private static final class IndividualAnswer {
    /** Value line of the {@code **Answer (…):**} line. */
    final int line;
    /** Last value line of the entry with text (inclusive). */
    final int end;
    final List<String> members;
    final String answer;
    final String changedAt;

    IndividualAnswer(int line, int end, List<String> members, String answer, String changedAt) {
      this.line = line;
      this.end = end;
      this.members = members;
      this.answer = answer;
      this.changedAt = changedAt;
    }
  }

  /** One parsed conflict block (SOM §11.9.8). */
  private static final class Conflict {
    final Block block;
    /** Null when the header is malformed: the block is then not listed. */
    final String id;
    final String topic;
    final String text;
    /** The {@code (base)} text, or null when the block has none. */
    String base;
    final List<SpecConflictAlternative> alternatives = new ArrayList<>();
    String decision = "";

    Conflict(Block block, String id, String topic, String text) {
      this.block = block;
      this.id = id;
      this.topic = topic;
      this.text = text;
    }
  }

  private static boolean isLetter(char c) {
    return c >= 'a' && c <= 'z';
  }

  /** A question's options and its recommended letter (null for none). */
  private static final class ParsedOptions {
    final List<SpecQuestionOption> options;
    final String recommended;

    ParsedOptions(List<SpecQuestionOption> options, String recommended) {
      this.options = options;
      this.recommended = recommended;
    }
  }

  /**
   * The options of a question and its recommended letter (SOM §11.9.2): one option per line, {@code
   * - (a) …}, the recommended one bold, {@code - **(b)** …}. The recommended letter is the first
   * bold option's; else the first option's whose text says "recommended"; else the letter a {@code
   * *Recommendation:*} line names; else none.
   */
  private static ParsedOptions parseOptions(List<String> lines) {
    List<SpecQuestionOption> options = new ArrayList<>();
    String letter = null;
    String text = null;
    boolean bold = false;
    for (String l : lines) {
      if (l.startsWith("- ")) {
        String r = l.substring(2);
        if (r.length() >= 7
            && r.startsWith("**(")
            && isLetter(r.charAt(3))
            && r.substring(4, 7).equals(")**")) {
          if (letter != null) {
            options.add(new SpecQuestionOption(letter, trim(text), bold));
          }
          letter = r.substring(3, 4);
          text = r.substring(7);
          bold = true;
          continue;
        }
        if (r.length() >= 3 && r.charAt(0) == '(' && isLetter(r.charAt(1)) && r.charAt(2) == ')') {
          if (letter != null) {
            options.add(new SpecQuestionOption(letter, trim(text), bold));
          }
          letter = r.substring(1, 2);
          text = r.substring(3);
          bold = false;
          continue;
        }
      }
      if (letter != null && l.startsWith(" ") && !trim(l).isEmpty()) {
        text = trim(text) + " " + trim(l);
        continue;
      }
      if (letter != null) {
        options.add(new SpecQuestionOption(letter, trim(text), bold));
      }
      letter = null;
    }
    if (letter != null) {
      options.add(new SpecQuestionOption(letter, trim(text), bold));
    }
    for (SpecQuestionOption o : options) {
      if (o.bold) {
        return new ParsedOptions(options, o.letter);
      }
    }
    for (SpecQuestionOption o : options) {
      if (o.text.toLowerCase(Locale.ROOT).contains("recommended")) {
        return new ParsedOptions(options, o.letter);
      }
    }
    final String label = "*Recommendation:*";
    for (String l : lines) {
      int i = l.indexOf(label);
      if (i < 0) {
        continue;
      }
      String x = leadingLetter(l.substring(i + label.length()));
      if (x != null) {
        return new ParsedOptions(options, x);
      }
    }
    return new ParsedOptions(options, null);
  }

  /** The letter of a leading {@code (x)} or {@code **(x)**} in {@code s} (spaces skipped). */
  static String leadingLetter(String s) {
    int a = 0;
    while (a < s.length() && isWs(s.charAt(a))) {
      a++;
    }
    String t = s.substring(a);
    if (t.startsWith("**")) {
      t = t.substring(2);
    }
    if (t.length() >= 3 && t.charAt(0) == '(' && isLetter(t.charAt(1)) && t.charAt(2) == ')') {
      return t.substring(1, 2);
    }
    return null;
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

    /** The first line up to where the author's parentheses (or the text) start. */
    final String beforeAuthor;

    /** When the comment was last changed (SOM §11.9.10), or null. */
    final String changedAt;

    Comment(
        Block block,
        String id,
        String author,
        String text,
        String context,
        String headerPrefix,
        int markerEnd,
        String beforeAuthor,
        String changedAt) {
      this.block = block;
      this.id = id;
      this.author = author;
      this.text = text;
      this.context = context;
      this.headerPrefix = headerPrefix;
      this.markerEnd = markerEnd;
      this.beforeAuthor = beforeAuthor;
      this.changedAt = changedAt;
    }
  }

  /**
   * One parsed mark; start/end are UTF-16 offsets into the value. {@code end} lies after the
   * attribution token when the mark has one (SOM §11.9.8), {@code bodyEnd} always right after the
   * mark itself, so the token can be rewritten in place.
   */
  private static final class Mark {
    final int start;
    int end;
    final int bodyEnd;
    final int line;
    final SpecMarkKind kind;
    final String text;
    final String newText;
    final String comment;
    List<String> authors = Collections.emptyList();
    List<SpecMarkVote> votes = Collections.emptyList();

    /** A comment mark's quote of a change (SOM §11.9.3), or null. */
    Quote quote;

    /** The index (among the value's marks) of the change this change comment is attached to. */
    Integer changeIndex;

    /** The index of this change's attached comment, or null. */
    Integer commentIndex;

    /** The time in the mark's attribution token (SOM §11.9.10), or null. */
    String changedAt;

    /**
     * Whether whitespace was written inside the delimiters at the leading / trailing edge of
     * {@code text} and of {@code newText} (SOM §11.9.3, edge spaces).
     */
    boolean textLead;

    boolean textTrail;
    boolean newLead;
    boolean newTrail;

    Mark(int start, int end, int line, SpecMarkKind kind, String text, String newText, String comment) {
      this.start = start;
      this.end = end;
      this.bodyEnd = end;
      this.line = line;
      this.kind = kind;
      this.text = text;
      this.newText = newText;
      this.comment = comment;
    }
  }

  /** The quote a change comment opens with (SOM §11.9.3); offsets are into the value. */
  private static final class Quote {
    final SpecMarkKind kind;
    final String oldText;
    final String newText;

    /** {@code accepted}, {@code rejected}, or null while the change is open. */
    final String outcome;

    /** Right after the quote's closing delimiter. */
    final int delimEnd;

    /** Right after the quote's {@code ]}. */
    final int end;

    /** The comment: the text after the quote, trimmed. */
    final String comment;

    Quote(
        SpecMarkKind kind,
        String oldText,
        String newText,
        String outcome,
        int delimEnd,
        int end,
        String comment) {
      this.kind = kind;
      this.oldText = oldText;
      this.newText = newText;
      this.outcome = outcome;
      this.delimEnd = delimEnd;
      this.end = end;
      this.comment = comment;
    }

    Map<String, Object> toJson() {
      Map<String, Object> out = new LinkedHashMap<>();
      out.put("kind", kind.value);
      out.put("oldText", oldText);
      out.put("newText", newText);
      out.put("outcome", outcome);
      return out;
    }
  }

  private static SpecMarkKind quoteKind(String d) {
    switch (d) {
      case "++":
        return SpecMarkKind.INSERTION;
      case "--":
        return SpecMarkKind.DELETION;
      case "~~":
        return SpecMarkKind.SUBSTITUTION;
      default:
        return null;
    }
  }

  private static boolean isBlankChar(char c) {
    return c == ' ' || c == '\t';
  }

  /**
   * Reads the quote at the start of a comment mark's inner text {@code s}, whose first character is
   * at value offset {@code at}: a {@link Quote}, null when {@code s} opens no quote, or the issue
   * ({@code unclosed}, {@code noArrow}) of one that is malformed.
   */
  private static Object readQuote(String s, int at) {
    int a = 0;
    while (a < s.length() && " \t\r\n".indexOf(s.charAt(a)) >= 0) {
      a++;
    }
    if (a + 3 > s.length() || s.charAt(a) != '[') {
      return null;
    }
    String d = s.substring(a + 1, a + 3);
    SpecMarkKind kind = quoteKind(d);
    if (kind == null) {
      return null;
    }
    int j = s.indexOf(d, a + 3);
    while (j >= 0) {
      int t = j + 2;
      while (t < s.length() && isBlankChar(s.charAt(t))) {
        t++;
      }
      String outcome = null;
      int close = -1;
      if (t < s.length() && s.charAt(t) == ']') {
        close = t;
      } else if (t < s.length() && s.charAt(t) == '|') {
        t++;
        while (t < s.length() && isBlankChar(s.charAt(t))) {
          t++;
        }
        for (String w : new String[] {"accepted", "rejected"}) {
          if (!s.startsWith(w, t)) {
            continue;
          }
          int u = t + w.length();
          while (u < s.length() && isBlankChar(s.charAt(u))) {
            u++;
          }
          if (u < s.length() && s.charAt(u) == ']') {
            outcome = w;
            close = u;
          }
          break;
        }
      }
      if (close >= 0) {
        String body = s.substring(a + 3, j);
        String oldText = "";
        String newText = "";
        switch (kind) {
          case INSERTION:
            newText = trim(body);
            break;
          case DELETION:
            oldText = trim(body);
            break;
          default:
            {
              int arrow = body.indexOf("~>");
              if (arrow < 0) {
                return "noArrow";
              }
              oldText = trim(body.substring(0, arrow));
              newText = trim(body.substring(arrow + 2));
            }
        }
        return new Quote(
            kind,
            oldText,
            newText,
            outcome,
            at + j + 2,
            at + close + 1,
            trim(s.substring(close + 1)));
      }
      j = s.indexOf(d, j + 1);
    }
    return "unclosed";
  }

  /**
   * Links each change comment to the change written directly before it whose kind and texts it
   * quotes (SOM §11.9.3).
   */
  private static void attachChangeComments(List<Mark> marks) {
    for (int k = 1; k < marks.size(); k++) {
      Quote q = marks.get(k).quote;
      Mark c = marks.get(k - 1);
      if (q == null || q.outcome != null || !isChangeMark(c.kind)) {
        continue;
      }
      if (c.end != marks.get(k).start || c.kind != q.kind) {
        continue;
      }
      if (!markReplacement(c, false).equals(q.oldText)
          || !markReplacement(c, true).equals(q.newText)) {
        continue;
      }
      marks.get(k).changeIndex = k - 1;
      c.commentIndex = k;
    }
  }

  /** The parsed header of a question. */
  private static final class Header {
    final String id;
    final String topic;
    final boolean starred;
    final String rest;
    /** The time in the header (SOM §11.9.10), or null. */
    final String changedAt;

    Header(String id, String topic, boolean starred, String rest, String changedAt) {
      this.id = id;
      this.topic = topic;
      this.starred = starred;
      this.rest = rest;
      this.changedAt = changedAt;
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

  static String trim(String s) {
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
    String t = lstrip(line);
    String s = t.isEmpty() ? "" : t.substring(1);
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
        b.comment = parseComment(p, b);
        p.comments.add(b.comment);
      } else if (first.startsWith(QUESTION_OPEN)) {
        Block b = new Block(s, e, SpecReviewAnnotationKind.QUESTION);
        p.blocks.add(b);
        parseQuestions(p, b);
      } else if (first.startsWith(SCALES)) {
        Block b = new Block(s, e, SpecReviewAnnotationKind.CONFLICT);
        p.blocks.add(b);
        b.conflict = parseConflict(p, b);
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
    String changedAt = null;
    String beforeAuthor = raw0.substring(0, raw0.length() - rest.length());
    if (rest.startsWith("(")) {
      int close = rest.indexOf(')');
      if (close > 0) {
        TimeSplit split = splitTime(commaParts(rest.substring(1, close)));
        changedAt = split.time;
        String a = trim(String.join(",", split.parts));
        author = split.time == null ? rest.substring(1, close) : (a.isEmpty() ? null : a);
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
      if (t.startsWith(QUESTION_OPEN) || t.startsWith(ANSWER_LABEL) || isIndividualAnswer(t)) {
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
        markerEnd,
        beforeAuthor,
        changedAt);
  }

  /** Parses a question header's remainder after {@code **❓ }; null when malformed. */
  private static Header parseHeader(String in) {
    String h = in.substring(QUESTION_OPEN.length() + 1);
    int sep = h.indexOf(EM_DASH_SEP);
    if (sep <= 0) {
      return null;
    }
    Matcher idMatch = HEADER_ID.matcher(h.substring(0, sep));
    if (!idMatch.matches()) {
      return null;
    }
    String id = idMatch.group(1);
    String changedAt = idMatch.group(2);
    if (changedAt != null && !isReviewTime(changedAt)) {
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
    return new Header(id, topic, starred, rest, changedAt);
  }

  /**
   * The time of a team answer line {@code **Answer (<time>):**} (SOM §11.9.10), or null when
   * {@code line} is no such line.
   */
  private static String teamAnswerTime(String line) {
    Matcher m = INDIVIDUAL_ANSWER.matcher(line);
    if (!m.find()) {
      return null;
    }
    String t = trim(m.group(1));
    return isReviewTime(t) ? t : null;
  }

  /**
   * The length of a team answer's label on {@code line} ({@code **Answer:**} or {@code **Answer
   * (<time>):**}), or null when {@code line} does not start with one.
   */
  private static Integer teamAnswerLabelLength(String line) {
    if (line.startsWith(ANSWER_LABEL)) {
      return ANSWER_LABEL.length();
    }
    if (teamAnswerTime(line) == null) {
      return null;
    }
    Matcher m = INDIVIDUAL_ANSWER.matcher(line);
    m.find();
    return m.group(0).length();
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
                + ": question header is not \"**❓ <ID> — <topic>:**\" or"
                + " \"**❓ <ID> (<time>) — <topic>:**\" (SOM §11.9.2)");
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
      // Every `**Answer` line of the region: the individual ones and the team's.
      List<Integer> answerLines = new ArrayList<>();
      for (int m = k + 1; m <= regionEnd; m++) {
        if (in.get(m).startsWith(ANSWER_LABEL) || isIndividualAnswer(in.get(m))) {
          answerLines.add(m);
        }
      }
      // The question's text ends before its first answer line of either kind.
      int textEnd = answerLines.isEmpty() ? regionEnd : answerLines.get(0) - 1;
      ParsedOptions po =
          parseOptions(
              textEnd >= k + 1 ? in.subList(k + 1, textEnd + 1) : Collections.emptyList());
      List<String> textParts = new ArrayList<>();
      textParts.add(h.rest);
      if (textEnd >= k + 1) {
        textParts.addAll(in.subList(k + 1, textEnd + 1));
      }
      String text = trim(String.join("\n", textParts));
      Integer answer = null;
      List<IndividualAnswer> individual = new ArrayList<>();
      Set<String> answered = new HashSet<>();
      for (int m : answerLines) {
        if (teamAnswerLabelLength(in.get(m)) != null) {
          if (answer == null) {
            answer = m;
          }
          continue;
        }
        Matcher match = INDIVIDUAL_ANSWER.matcher(in.get(m));
        match.find();
        TimeSplit memberParts = splitTime(commaParts(match.group(1)));
        List<String> members = new ArrayList<>();
        for (String x : memberParts.parts) {
          members.add(trim(x));
        }
        for (String member : members) {
          if (answered.contains(member)) {
            p.malformed.add(
                "line "
                    + (b.start + m)
                    + ": "
                    + member
                    + " already answered "
                    + h.id
                    + "; a member answers a question at most once (SOM §11.9.8)");
          }
          answered.add(member);
        }
        int end = answerEnd(answerLines, m, regionEnd);
        while (end > m && trim(in.get(end)).isEmpty()) {
          end--;
        }
        individual.add(
            new IndividualAnswer(
                b.start + m,
                b.start + end,
                members,
                answerText(in, answerLines, m, match.group(0).length(), regionEnd),
                memberParts.time));
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
              answer == null
                  ? ""
                  : answerText(
                      in, answerLines, answer, teamAnswerLabelLength(in.get(answer)), regionEnd),
              po.options,
              po.recommended,
              individual,
              h.changedAt,
              answer == null ? null : teamAnswerTime(in.get(answer))));
    }
    b.questions = list;
  }

  /**
   * The last line of the answer at {@code m}: an answer runs to the next {@code **Answer} line or
   * the end of the region.
   */
  private static int answerEnd(List<Integer> answerLines, int m, int regionEnd) {
    for (int x : answerLines) {
      if (x > m) {
        return x - 1;
      }
    }
    return regionEnd;
  }

  /** The text of the answer at line {@code m}, after its label of {@code label} chars, trimmed. */
  private static String answerText(
      List<String> in, List<Integer> answerLines, int m, int label, int regionEnd) {
    List<String> parts = new ArrayList<>();
    parts.add(in.get(m).substring(label));
    int end = answerEnd(answerLines, m, regionEnd);
    if (end >= m + 1) {
      parts.addAll(in.subList(m + 1, end + 1));
    }
    return trim(String.join("\n", parts));
  }

  /** {@code - (base) …}: the base line of a conflict block. */
  private static final Pattern CONFLICT_BASE = Pattern.compile("- \\(base\\)(?: (.*))?");

  /** {@code - (a) **alice, bob:** …}: a lettered alternative. */
  private static final Pattern CONFLICT_ALTERNATIVE =
      Pattern.compile("- \\(([a-z])\\)(?: \\*\\*([^*]*):\\*\\*)?(?: (.*))?");

  /** The header after the marker: {@code **X-<n> — <topic>:** <text>}. */
  private static final Pattern CONFLICT_HEADER =
      Pattern.compile("\\*\\*(X-[1-9][0-9]*) — (.+?):\\*\\*(?: (.*))?");

  /** The entry of a conflict block being read: the base (letter null) or an alternative. */
  private static final class OpenEntry {
    final String letter;
    final List<String> members;
    final List<String> lines = new ArrayList<>();

    OpenEntry(String letter, List<String> members, String first) {
      this.letter = letter;
      this.members = members;
      lines.add(first);
    }
  }

  private static void closeEntry(Conflict c, OpenEntry open) {
    if (open == null) {
      return;
    }
    String text = trim(String.join("\n", open.lines));
    if (open.letter == null) {
      c.base = text;
    } else {
      c.alternatives.add(new SpecConflictAlternative(open.letter, open.members, text));
    }
  }

  /**
   * A conflict block (SOM §11.9.8): the header, the {@code (base)} line and the lettered
   * alternatives — each continuing on lines indented under it, its line breaks kept — then {@code
   * **Decision:**}. A malformed header leaves the block unlisted; a missing base line or
   * alternative is a finding.
   */
  private static Conflict parseConflict(Parsed p, Block b) {
    List<String> in = new ArrayList<>();
    for (int k = b.start; k <= b.end; k++) {
      in.add(inner(p.lines.get(k)));
    }
    String rest = in.get(0).substring(SCALES.length());
    if (rest.startsWith(VS16)) {
      rest = rest.substring(VS16.length());
    }
    Matcher header = CONFLICT_HEADER.matcher(trimLeft(rest));
    boolean ok = header.matches();
    Conflict c =
        new Conflict(
            b,
            ok ? header.group(1) : null,
            ok ? header.group(2) : "",
            ok && header.group(3) != null ? trim(header.group(3)) : "");
    if (!ok) {
      p.malformed.add(
          "line "
              + b.start
              + ": conflict header is not \"⚖️ **X-<n> — <topic>:**\" (SOM §11.9.8)");
    }
    int decisionLine = in.size();
    for (int k = 1; k < in.size(); k++) {
      if (in.get(k).startsWith(DECISION_LABEL)) {
        decisionLine = k;
        break;
      }
    }
    OpenEntry open = null;
    for (int k = 1; k < decisionLine; k++) {
      String l = in.get(k);
      Matcher base = CONFLICT_BASE.matcher(l);
      Matcher alt = CONFLICT_ALTERNATIVE.matcher(l);
      if (base.matches()) {
        closeEntry(c, open);
        open = new OpenEntry(null, new ArrayList<>(), base.group(1) == null ? "" : base.group(1));
      } else if (alt.matches()) {
        closeEntry(c, open);
        List<String> members = new ArrayList<>();
        if (alt.group(2) != null) {
          for (String x : alt.group(2).split(",", -1)) {
            String t = trim(x);
            if (!t.isEmpty()) {
              members.add(t);
            }
          }
        }
        open = new OpenEntry(alt.group(1), members, alt.group(3) == null ? "" : alt.group(3));
      } else if (open != null && l.startsWith(" ")) {
        open.lines.add(l.startsWith("  ") ? l.substring(2) : lstrip(l));
      } else {
        closeEntry(c, open);
        open = null;
      }
    }
    closeEntry(c, open);
    if (decisionLine < in.size()) {
      List<String> parts = new ArrayList<>();
      parts.add(in.get(decisionLine).substring(DECISION_LABEL.length()));
      parts.addAll(in.subList(decisionLine + 1, in.size()));
      c.decision = trim(String.join("\n", parts));
    }
    if (ok && c.base == null) {
      p.malformed.add(
          "line " + b.start + ": conflict " + c.id + " has no \"(base)\" line (SOM §11.9.8)");
    }
    if (ok && c.alternatives.isEmpty()) {
      p.malformed.add(
          "line " + b.start + ": conflict " + c.id + " has no lettered alternative (SOM §11.9.8)");
    }
    return c;
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
    attachChangeComments(p.marks);
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
      if (c == '{' && seg.startsWith("{@", i)) {
        // A token that no mark precedes directly (a mark's own token is read with the mark,
        // below).
        int line = lineOf.applyAsInt(base + i);
        p.malformed.add(
            "line "
                + line
                + ": an attribution token \"{@\" does not follow a mark directly (SOM §11.9.8)");
        int close = seg.indexOf('}', i + 2);
        i = close < 0 ? i + 2 : close + 1;
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
      int before = p.marks.size();
      switch (opener) {
        case "{>>":
          {
            Mark cm = new Mark(base + i, base + end, line, SpecMarkKind.COMMENT, "", null, trim(in));
            Object q = readQuote(in, base + i + 3);
            if (q instanceof Quote) {
              cm.quote = (Quote) q;
            } else if ("unclosed".equals(q)) {
              p.malformed.add(
                  "line "
                      + line
                      + ": the quote of a change comment is not closed; it is read as a plain"
                      + " comment (SOM §11.9.3)");
            } else if ("noArrow".equals(q)) {
              p.malformed.add(
                  "line "
                      + line
                      + ": the quote of a change comment has no \"~>\"; it is read as a plain"
                      + " comment (SOM §11.9.3)");
            }
            p.marks.add(cm);
            break;
          }
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
          {
            Mark mk =
                new Mark(base + i, base + end, line, SpecMarkKind.INSERTION, trim(in), null, null);
            mk.textLead = wsEdge(in, true);
            mk.textTrail = wsEdge(in, false);
            p.marks.add(mk);
            break;
          }
        case "{--":
          {
            Mark mk =
                new Mark(base + i, base + end, line, SpecMarkKind.DELETION, trim(in), null, null);
            mk.textLead = wsEdge(in, true);
            mk.textTrail = wsEdge(in, false);
            p.marks.add(mk);
            break;
          }
        default:
          {
            int arrow = in.indexOf("~>");
            if (arrow < 0) {
              p.malformed.add("line " + line + ": a substitution has no \"~>\" (SOM §11.9.3)");
              p.markIssues.add(new Object[] {line, "noArrow"});
              i = end;
              continue;
            }
            String oldRaw = in.substring(0, arrow);
            String newRaw = in.substring(arrow + 2);
            Mark mk =
                new Mark(
                    base + i,
                    base + end,
                    line,
                    SpecMarkKind.SUBSTITUTION,
                    trim(oldRaw),
                    trim(newRaw),
                    null);
            mk.textLead = wsEdge(oldRaw, true);
            mk.textTrail = wsEdge(oldRaw, false);
            mk.newLead = wsEdge(newRaw, true);
            mk.newTrail = wsEdge(newRaw, false);
            p.marks.add(mk);
            break;
          }
      }
      if (p.marks.size() > before && seg.startsWith("{@", end)) {
        end = attachToken(p, seg, end, base, p.marks.get(p.marks.size() - 1));
      }
      i = end;
    }
  }

  /**
   * Reads the attribution token {@code {@…}} at {@code at} (SOM §11.9.8) into {@code m}, which it
   * directly follows, and returns the segment offset after it. The token is part of the mark — its
   * markup, its decision — so {@code m.end} moves past it. A token that breaks the grammar is still
   * part of the mark (it goes with the mark on a decision) and is a finding; its members are then
   * not listed.
   */
  private static int attachToken(Parsed p, String seg, int at, int base, Mark m) {
    int lineEnd = seg.indexOf('\n', at);
    int close = seg.indexOf('}', at + 2);
    if (close < 0 || (lineEnd >= 0 && close > lineEnd)) {
      p.malformed.add("line " + m.line + ": attribution token \"{@\" is not closed (SOM §11.9.8)");
      return at;
    }
    TokenRead read = readToken(seg.substring(at + 2, close), m.kind);
    m.changedAt = read.time;
    if (read.error != null) {
      p.malformed.add("line " + m.line + ": attribution token " + read.error + " (SOM §11.9.8)");
    } else {
      m.authors = read.authors;
      m.votes = read.votes;
    }
    m.end = base + close + 1;
    return close + 1;
  }

  /** Whether a mark kind is a change, which alone takes votes (SOM §11.9.8). */
  static boolean isChangeMark(SpecMarkKind kind) {
    return kind == SpecMarkKind.INSERTION
        || kind == SpecMarkKind.DELETION
        || kind == SpecMarkKind.SUBSTITUTION;
  }

  /** The members a token names, or the reason it breaks the grammar. */
  private static final class TokenRead {
    final List<String> authors;
    final List<SpecMarkVote> votes;
    final String error;

    /** The token's change time (SOM §11.9.10), or null. */
    String time;

    TokenRead(List<String> authors, List<SpecMarkVote> votes, String error) {
      this.authors = authors;
      this.votes = votes;
      this.error = error;
    }

    static TokenRead refused(String error) {
      return new TokenRead(null, null, error);
    }
  }

  /** A run of whitespace as JavaScript's {@code \s} reads it, for the token grammar. */
  private static final Pattern WS_RUN =
      Pattern.compile("[\\s\\u00a0\\u1680\\u2000-\\u200a\\u2028\\u2029\\u202f\\u205f\\u3000\\ufeff]+");

  private static final Pattern COMMA_WS =
      Pattern.compile(",[\\s\\u00a0\\u1680\\u2000-\\u200a\\u2028\\u2029\\u202f\\u205f\\u3000\\ufeff]+");

  /**
   * The members of a token's inside, {@code <authors>[ <votes>][ <time>]}, or the reason it breaks
   * the grammar of SOM §11.9.8; its change time (SOM §11.9.10) in {@code time} either way.
   */
  private static TokenRead readToken(String inside, SpecMarkKind kind) {
    List<String> words = new ArrayList<>();
    for (String w : WS_RUN.split(trim(COMMA_WS.matcher(inside).replaceAll(",")), -1)) {
      if (!w.isEmpty()) {
        words.add(w);
      }
    }
    if (words.isEmpty()) {
      return TokenRead.refused("is empty");
    }
    String time = null;
    if (isReviewTime(words.get(words.size() - 1))) {
      time = words.remove(words.size() - 1);
    }
    TokenRead read = readMembers(words, kind);
    read.time = time;
    return read;
  }

  /**
   * The authors and votes of a token's words (its time taken off), or the reason they break the
   * grammar of SOM §11.9.8.
   */
  private static TokenRead readMembers(List<String> words, SpecMarkKind kind) {
    if (words.isEmpty()) {
      return new TokenRead(new ArrayList<>(), new ArrayList<>(), null);
    }
    List<String> authors = new ArrayList<>();
    List<SpecMarkVote> votes = new ArrayList<>();
    int k = 0;
    if (!words.get(0).startsWith("+") && !words.get(0).startsWith("-")) {
      authors.addAll(Arrays.asList(words.get(0).split(",", -1)));
      k = 1;
    }
    for (; k < words.size(); k++) {
      String w = words.get(k);
      if (!w.startsWith("+") && !w.startsWith("-")) {
        return TokenRead.refused("has \"" + w + "\" where a vote belongs");
      }
      votes.add(
          new SpecMarkVote(
              w.substring(1), w.startsWith("+") ? SpecMarkDecision.ACCEPT : SpecMarkDecision.REJECT));
    }
    Set<String> seen = new HashSet<>();
    List<String> ids = new ArrayList<>(authors);
    for (SpecMarkVote v : votes) {
      ids.add(v.member);
    }
    for (String id : ids) {
      if (!MEMBER_ID.matcher(id).matches()) {
        return TokenRead.refused("names \"" + id + "\", which is not a member id");
      }
      if (!seen.add(id)) {
        return TokenRead.refused("names " + id + " twice, or as author and voter");
      }
    }
    if (!votes.isEmpty() && !isChangeMark(kind)) {
      return TokenRead.refused(
          "carries votes on a " + kind.value + " mark, which takes authors only");
    }
    return new TokenRead(authors, votes, null);
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
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    c.changedAt)));
      } else if (b.kind == SpecReviewAnnotationKind.CONFLICT) {
        Conflict c = b.conflict;
        if (c.id == null) {
          continue;
        }
        out.add(
            new Ordered(
                b.start,
                0,
                seq++,
                new SpecReviewAnnotation(
                    SpecReviewAnnotationKind.CONFLICT,
                    path,
                    field,
                    b.start,
                    c.id,
                    qualifier != null ? qualifier + " " + c.id : null,
                    null,
                    c.text,
                    "",
                    c.topic,
                    false,
                    false,
                    c.decision,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    c.base == null ? "" : c.base,
                    c.alternatives)));
      } else {
        for (Question q : b.questions) {
          List<SpecIndividualAnswer> answers = new ArrayList<>();
          for (IndividualAnswer a : q.answers) {
            answers.add(new SpecIndividualAnswer(a.members, a.answer, a.changedAt));
          }
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
                      q.options,
                      q.recommended,
                      null,
                      null,
                      null,
                      null,
                      null,
                      answers,
                      null,
                      null,
                      q.changedAt,
                      q.answerChangedAt)));
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
                  null,
                  null,
                  m.kind,
                  m.newText,
                  m.comment,
                  m.authors,
                  m.votes,
                  null,
                  null,
                  null,
                  m.changedAt)));
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
    return formatCommentBlock(id, text, author, null);
  }

  /**
   * The lines of a comment block; {@code changedAt} goes into the header's parentheses after the
   * author (SOM §11.9.10).
   */
  public static List<String> formatCommentBlock(
      String id, String text, String author, String changedAt) {
    List<String> t = splitLines(text);
    StringBuilder head = new StringBuilder("> " + ARROW + VS16 + " **" + id + "**");
    String who = authorAndTime(author, changedAt);
    if (who != null) {
      head.append(" (").append(who).append("):");
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
    return formatQuestionBlock(q, null);
  }

  /**
   * The lines of a question block; {@code changedAt} (null: none) is written after the id (SOM
   * §11.9.10).
   */
  public static List<String> formatQuestionBlock(SpecQuestionDraft q, String changedAt) {
    List<String> t = splitLines(q.text);
    List<String> lines = new ArrayList<>();
    lines.add(
        "> "
            + QUESTION_OPEN
            + " "
            + (changedAt == null ? q.id : q.id + " (" + changedAt + ")")
            + EM_DASH_SEP
            + (q.starred ? STAR + " " : "")
            + q.topic
            + ":** "
            + t.get(0));
    lines.addAll(quoted(t.subList(1, t.size())));
    for (String o : q.options) {
      if (q.recommended != null && o.startsWith("(" + q.recommended + ")")) {
        lines.add("> - **(" + q.recommended + ")**" + o.substring(3));
      } else {
        lines.add("> - " + o);
      }
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
   * keep an edge space written inside a change mark after punctuation and before a word, never
   * leave a double space or a space before punctuation, and a mark that was a whole line leaves no
   * blank line. The mark is removed rather than decided.
   */
  private static String replaceMark(String value, Mark m, String replacement0) {
    return replaceMark(value, m, replacement0, null);
  }

  /**
   * As {@link #replaceMark(String, Mark, String)}; {@code accept} names the decision the
   * replacement comes from, null when the mark is removed rather than decided.
   */
  private static String replaceMark(String value, Mark m, String replacement0, Boolean accept) {
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
            || CLOSING_PUNCTUATION.indexOf(after.charAt(0)) >= 0) {
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
    // on that side. An edge space written inside a change mark, beside the
    // text the decision keeps, is kept after punctuation and before a word or
    // an opening bracket.
    boolean[] edges = accept == null ? new boolean[] {false, false} : keptEdges(m, accept);
    boolean lead = edges[0];
    boolean trail = edges[1];
    if ((wordChar(before) && wordCharAt(replacement, 0))
        || (lead
            && !before.isEmpty()
            && CLOSING_PUNCTUATION.indexOf(before.charAt(before.length() - 1)) >= 0)) {
      replacement = " " + replacement;
    }
    if (!after.isEmpty()
        && ((wordCharAt(replacement, replacement.length() - 1) && wordCharAt(after, 0))
            || (trail && (wordCharAt(after, 0) || "([".indexOf(after.charAt(0)) >= 0)))) {
      replacement = replacement + " ";
    }
    return before + replacement + after;
  }

  /**
   * The punctuation no space is left before, and after which an edge space is kept (SOM §11.9.3).
   */
  private static final String CLOSING_PUNCTUATION = ".,;:!?)]}";

  /**
   * Whether {@code raw}, a mark's text as written between its delimiters, begins ({@code leading})
   * or ends with whitespace.
   */
  private static boolean wsEdge(String raw, boolean leading) {
    return !raw.isEmpty() && isWs(raw.charAt(leading ? 0 : raw.length() - 1));
  }

  /**
   * The edge spaces written beside the text {@code accept} keeps of {@code m}: the leading and the
   * trailing one.
   */
  private static boolean[] keptEdges(Mark m, boolean accept) {
    if (m.kind == SpecMarkKind.INSERTION && accept) {
      return new boolean[] {m.textLead, m.textTrail};
    }
    if (m.kind == SpecMarkKind.DELETION && !accept) {
      return new boolean[] {m.textLead, m.textTrail};
    }
    if (m.kind == SpecMarkKind.SUBSTITUTION) {
      return accept
          ? new boolean[] {m.newLead, m.newTrail}
          : new boolean[] {m.textLead, m.textTrail};
    }
    return new boolean[] {false, false};
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
      v = replaceMark(v, m, markReplacement(m, accept), accept);
    }
    return v;
  }

  /**
   * {@code value} with every inline mark accepted ({@code accept}) or rejected, as accept all /
   * reject all write it (SOM §11.9.3): change comments stay, an attached one records the outcome;
   * every other highlight and comment mark is removed. Marks in code and malformed marks stay as
   * written.
   */
  public static String decideAllMarksText(String value, boolean accept) {
    List<Mark> marks = parse(value).marks;
    String v = value;
    for (int k = marks.size() - 1; k >= 0; k--) {
      if (marks.get(k).quote != null) {
        continue;
      }
      v = decideMark(v, marks, k, accept);
    }
    return v;
  }

  /**
   * {@code value} with the mark {@code k} of {@code marks} decided; a change's attached comment
   * records the outcome (SOM §11.9.3).
   */
  private static String decideMark(String value, List<Mark> marks, int k, boolean accept) {
    Mark m = marks.get(k);
    String v = value;
    Integer ci = m.commentIndex;
    if (ci != null) {
      v = recordOutcome(v, marks.get(ci).quote, accept);
    }
    return replaceMark(v, m, markReplacement(m, accept), accept);
  }

  /**
   * {@code value} with the outcome written into the quote {@code q}: everything from its closing
   * delimiter to its {@code ]} becomes {@code " | accepted]"} or {@code " | rejected]"}.
   */
  private static String recordOutcome(String value, Quote q, boolean accept) {
    return value.substring(0, q.delimEnd)
        + " | "
        + (accept ? "accepted" : "rejected")
        + "]"
        + value.substring(q.end);
  }

  private static final Pattern BLANK_LINE_IN = Pattern.compile("\\n[ \\t\\r]*\\n");

  /**
   * The trimmed {@code text} of an inline comment, refused when it is empty or holds a mark
   * delimiter or a blank line.
   */
  private static String checkInlineComment(String text) {
    String t = trim(text);
    if (t.isEmpty()) {
      throw new SpecReviewAnnotationError("a comment needs text");
    }
    boolean delimiter = t.contains("<<}");
    for (String o : OPENERS) {
      delimiter = delimiter || t.contains(o);
    }
    if (delimiter || BLANK_LINE_IN.matcher(t).find()) {
      throw new SpecReviewAnnotationError(
          "a comment cannot hold a mark delimiter or a blank line");
    }
    return t;
  }

  /** The whitespace of the change-comment anchors (SOM §11.9.3). */
  private static boolean isAnchorSpace(char c) {
    return c == ' ' || c == '\t' || c == '\r' || c == '\n';
  }

  private static int nonSpaceCount(String s) {
    int n = 0;
    for (int i = 0; i < s.length(); i++) {
      if (!isAnchorSpace(s.charAt(i))) {
        n++;
      }
    }
    return n;
  }

  /** Where {@code k} non-whitespace characters of {@code r} (with its marks {@code rm}) pass. */
  private static int anchorPlace(String r, List<Mark> rm, int k) {
    if (k == 0) {
      return 0;
    }
    int n = 0;
    int i = 0;
    int mi = 0;
    while (i < r.length()) {
      if (mi < rm.size() && rm.get(mi).start == i) {
        Mark m = rm.get(mi++);
        n += m.kind == SpecMarkKind.INSERTION ? 0 : nonSpaceCount(m.text);
        i = m.end;
        if (n >= k) {
          return i;
        }
        continue;
      }
      if (!isAnchorSpace(r.charAt(i))) {
        n++;
      }
      i++;
      if (n >= k) {
        return i;
      }
    }
    return r.length();
  }

  /**
   * {@code after} (a value just written as marks) with an attribution token on every change mark it
   * lacks one on (SOM §11.9.10): the token of the same change in {@code before} (same kind, old and
   * new text; each used once, in order) when {@code before} held it, else a new one with {@code
   * author} and {@code time}.
   */
  private static String stampMarks(String before, String after, String author, String time) {
    List<String> oldKeys = new ArrayList<>();
    List<String> oldTokens = new ArrayList<>();
    for (Mark m : parse(before).marks) {
      if (isChangeMark(m.kind)) {
        oldKeys.add(stampKey(m));
        oldTokens.add(before.substring(m.bodyEnd, m.end));
      }
    }
    boolean[] used = new boolean[oldKeys.size()];
    List<String> authors = new ArrayList<>();
    if (author != null) {
      authors.add(author);
    }
    String fresh = formatAttributionToken(authors, Collections.emptyList(), time);
    List<Integer> insertAt = new ArrayList<>();
    List<String> insertToken = new ArrayList<>();
    for (Mark m : parse(after).marks) {
      if (!isChangeMark(m.kind) || m.end > m.bodyEnd) {
        continue;
      }
      String k = stampKey(m);
      String token = fresh;
      for (int i = 0; i < oldKeys.size(); i++) {
        if (!used[i] && oldKeys.get(i).equals(k)) {
          used[i] = true;
          token = oldTokens.get(i);
          break;
        }
      }
      if (!token.isEmpty()) {
        insertAt.add(m.bodyEnd);
        insertToken.add(token);
      }
    }
    String v = after;
    for (int i = insertAt.size() - 1; i >= 0; i--) {
      int at = insertAt.get(i);
      v = v.substring(0, at) + insertToken.get(i) + v.substring(at);
    }
    return v;
  }

  /** A change mark's identity for {@link #stampMarks}: kind, old text and new text. */
  private static String stampKey(Mark m) {
    return m.kind.value
        + "\u0000"
        + markReplacement(m, false)
        + "\u0000"
        + markReplacement(m, true);
  }

  /**
   * {@code setMarked} with the value's change comments kept (SOM §11.9.3): taken out of the
   * original, then written back where their anchor falls.
   */
  private static SpecMarkedChange markKeepingChangeComments(String current, String text) {
    // 1. The original: every mark rejected except the change comments.
    String original = current;
    List<Mark> marks = parse(current).marks;
    for (int k = marks.size() - 1; k >= 0; k--) {
      if (marks.get(k).quote != null) {
        continue;
      }
      original =
          replaceMark(original, marks.get(k), markReplacement(marks.get(k), false), false);
    }
    // 2. Each change comment's markup, anchor and leading space.
    List<Mark> kept = new ArrayList<>();
    for (Mark m : parse(original).marks) {
      if (m.quote != null) {
        kept.add(m);
      }
    }
    List<String> markups = new ArrayList<>();
    List<Integer> counts = new ArrayList<>();
    List<Boolean> spaces = new ArrayList<>();
    int counted = 0;
    int from = 0;
    for (Mark m : kept) {
      counted += nonSpaceCount(original.substring(from, m.start));
      from = m.end;
      markups.add(original.substring(m.start, m.end));
      counts.add(counted);
      spaces.add(m.start > 0 && isBlankChar(original.charAt(m.start - 1)));
    }
    // 3. Removed, compared.
    String base = original;
    for (int k = kept.size() - 1; k >= 0; k--) {
      base = replaceMark(base, kept.get(k), "");
    }
    SpecMarkedChange result = markChangeText(base, text);
    if (kept.isEmpty()) {
      return result;
    }
    // 4. Written back where k non-whitespace characters have passed.
    String r = result.text;
    List<Mark> rm = parse(r).marks;
    int[] at = new int[kept.size()];
    for (int j = 0; j < kept.size(); j++) {
      at[j] = anchorPlace(r, rm, counts.get(j));
    }
    String out = r;
    for (int j = kept.size() - 1; j >= 0; j--) {
      out =
          out.substring(0, at[j])
              + (spaces.get(j) ? " " : "")
              + markups.get(j)
              + out.substring(at[j]);
    }
    return new SpecMarkedChange(out, result.exact);
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
      v = replaceMark(v, m, markReplacement(m, true), true);
    }
    return v;
  }

  // -------------------------------------------------------------------------
  // Team reviews (SOM §11.9.8): individual answers and applying conflicts.
  // -------------------------------------------------------------------------

  /** Whether an answer carries anything beyond an option letter (SOM §11.9.8). */
  private static boolean isCommentedAnswer(String answer, List<SpecQuestionOption> options) {
    String letter = leadingLetter(answer);
    if (letter == null) {
      return true;
    }
    String t = trimLeft(answer);
    boolean bold = t.startsWith("**(") && t.length() >= 7 && t.substring(4, 7).equals(")**");
    int from = bold ? 7 : t.startsWith("**") ? 2 + 3 : 3;
    String rest = trim(from <= t.length() ? t.substring(from) : "");
    if (rest.isEmpty()) {
      return false;
    }
    for (SpecQuestionOption o : options) {
      if (o.letter.equals(letter)) {
        return !rest.equals(o.text);
      }
    }
    return true;
  }

  /** The lines of one individual-answer entry. */
  /**
   * A comment header's parentheses: the author and the change time, either alone, or null when
   * there is neither (SOM §11.9.10).
   */
  private static String authorAndTime(String author, String changedAt) {
    String a = author != null && !author.isEmpty() ? author : null;
    if (a == null) {
      return changedAt;
    }
    return changedAt == null ? a : a + ", " + changedAt;
  }

  private static List<String> individualAnswerLines(
      List<String> members, String answer, String changedAt) {
    List<String> a = splitLines(answer);
    List<String> who = new ArrayList<>(members);
    if (changedAt != null) {
      who.add(changedAt);
    }
    List<String> out = new ArrayList<>();
    out.add(trimRight("> **Answer (" + String.join(", ", who) + "):** " + a.get(0)));
    out.addAll(quoted(a.subList(1, a.size())));
    return out;
  }

  /** One entry while an individual answer is set: its members, answer and kept lines. */
  private static final class AnswerEntry {
    final List<String> members;
    final String answer;
    /** The entry's lines as written; null once it changed and is written anew. */
    List<String> lines;
    final String changedAt;

    AnswerEntry(List<String> members, String answer, List<String> lines, String changedAt) {
      this.members = members;
      this.answer = answer;
      this.lines = lines;
      this.changedAt = changedAt;
    }
  }

  /**
   * {@code value} with member {@code member}'s individual answer to question {@code q} set to
   * {@code answer} (SOM §11.9.8): the member leaves the line it was on (a line left empty goes); a
   * non-empty answer that is not commented joins the line whose answer is identical and not
   * commented, at its end, and otherwise gets a new line after the last individual answer. The
   * first individual answer opens the run before the team's {@code **Answer:**}, with a {@code >}
   * line between run and team answer, and a run left empty takes that line with it. Entries left
   * alone keep their bytes.
   */
  private static String setIndividualAnswer(
      String value, Question q, String member, String answer, String changedAt) {
    List<String> lines = splitLines(value);
    List<AnswerEntry> entries = new ArrayList<>();
    for (IndividualAnswer a : q.answers) {
      entries.add(
          new AnswerEntry(
              new ArrayList<>(a.members),
              a.answer,
              new ArrayList<>(lines.subList(a.line, a.end + 1)),
              a.changedAt));
    }
    for (AnswerEntry e : entries) {
      if (e.members.remove(member)) {
        e.lines = null;
      }
    }
    List<AnswerEntry> kept = new ArrayList<>();
    for (AnswerEntry e : entries) {
      if (!e.members.isEmpty()) {
        kept.add(e);
      }
    }
    String text = trim(answer);
    if (!text.isEmpty()) {
      AnswerEntry join = null;
      if (!isCommentedAnswer(text, q.options)) {
        for (AnswerEntry e : kept) {
          if (e.answer.equals(text)
              && Objects.equals(e.changedAt, changedAt)
              && !isCommentedAnswer(e.answer, q.options)) {
            join = e;
            break;
          }
        }
      }
      if (join != null) {
        join.members.add(member);
        join.lines = null;
      } else {
        List<String> members = new ArrayList<>();
        members.add(member);
        kept.add(new AnswerEntry(members, text, null, changedAt));
      }
    }
    List<String> run = new ArrayList<>();
    for (AnswerEntry e : kept) {
      run.addAll(
          e.lines != null ? e.lines : individualAnswerLines(e.members, e.answer, e.changedAt));
    }
    if (!q.answers.isEmpty()) {
      int from = q.answers.get(0).line;
      int to = q.answers.get(q.answers.size() - 1).end;
      // A run left empty takes its separating `>` line with it.
      if (run.isEmpty() && to + 1 < lines.size() && trim(inner(lines.get(to + 1))).isEmpty()) {
        to++;
      }
      List<String> range = lines.subList(from, to + 1);
      range.clear();
      range.addAll(run);
    } else if (!run.isEmpty()) {
      if (q.answerLine != null) {
        List<String> insert = new ArrayList<>(run);
        insert.add(">");
        lines.addAll(q.answerLine, insert);
      } else {
        int last = q.regionEnd;
        while (last > q.header && trim(inner(lines.get(last))).isEmpty()) {
          last--;
        }
        List<String> insert = new ArrayList<>();
        insert.add(">");
        insert.addAll(run);
        lines.addAll(last + 1, insert);
      }
    }
    return String.join("\n", lines);
  }

  /**
   * Topics of the structural conflicts a merge writes (SOM §11.9.9); their decisions are not
   * text.
   */
  private static final Set<String> STRUCTURAL_TOPICS =
      new HashSet<>(Arrays.asList("Item removed", "Item moved", "Headline changed"));

  /** A decided conflict, as {@code removeAllAnnotations} found it before any change. */
  private static final class DecidedConflict {
    final String path;
    final String field;
    /** The block's position among the value's conflict blocks. */
    final int index;
    final String id;
    final int line;
    final String decision;

    DecidedConflict(String path, String field, int index, String id, int line, String decision) {
      this.path = path;
      this.field = field;
      this.index = index;
      this.id = id;
      this.line = line;
      this.decision = decision;
    }
  }

  /** The text a conflict's decision chooses: the base, an alternative, or the rewritten text. */
  private static String chosenText(Conflict c) {
    String letter = decisionLetter(c.decision);
    if ("base".equals(letter)) {
      return c.base == null ? "" : c.base;
    }
    if (letter != null) {
      for (SpecConflictAlternative a : c.alternatives) {
        if (a.letter.equals(letter)) {
          return a.text;
        }
      }
    }
    return c.decision;
  }

  private static boolean isBlockStart(Parsed p, int line) {
    for (Block b : p.blocks) {
      if (b.start == line) {
        return true;
      }
    }
    return false;
  }

  /** The text paragraphs (no annotation block) of a parsed value, as {first, last} lines. */
  private static List<int[]> textParagraphs(Parsed p) {
    List<int[]> out = new ArrayList<>();
    for (int[] r : paragraphs(p.lines, p.code)) {
      if (!isBlockStart(p, r[0])) {
        out.add(r);
      }
    }
    return out;
  }

  /** {@code value} with the lines [s, e] replaced by {@code text}. */
  private static String replaceLines(String value, int s, int e, String text) {
    List<String> lines = splitLines(value);
    List<String> range = lines.subList(s, e + 1);
    range.clear();
    range.addAll(splitLines(text));
    return String.join("\n", lines);
  }

  /**
   * {@code value} with the text paragraph directly before block {@code b} (annotation blocks
   * between them skipped) replaced by {@code text}; with none, {@code text} goes before the block.
   */
  private static String replaceParagraphBefore(String value, Block b, String text) {
    int[] last = null;
    for (int[] r : textParagraphs(parse(value))) {
      if (r[1] < b.start) {
        last = r;
      }
    }
    if (last == null) {
      return insertAfterLine(value, b.start - 1, splitLines(text));
    }
    return replaceLines(value, last[0], last[1], text);
  }

  /**
   * {@code value} with the run of text paragraphs directly before block {@code b} — a whole-value
   * unit (SOM §11.9.9) — replaced by {@code text}.
   */
  private static String replaceTextRun(String value, Block b, String text) {
    Parsed p = parse(value);
    List<int[]> paras = new ArrayList<>();
    for (int[] r : paragraphs(p.lines, p.code)) {
      if (r[1] < b.start) {
        paras.add(r);
      }
    }
    int k = paras.size();
    while (k > 0 && !isBlockStart(p, paras.get(k - 1)[0])) {
      k--;
    }
    if (k == paras.size()) {
      return insertAfterLine(value, b.start - 1, splitLines(text));
    }
    return replaceLines(value, paras.get(k)[0], paras.get(paras.size() - 1)[1], text);
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
    int unresolved = 0;
    int c = 0;
    int m = 0;
    int x = 0;
    int openX = 0;
    for (SpecReviewAnnotation a : list()) {
      switch (a.kind) {
        case QUESTION:
          q++;
          if (a.open()) {
            open++;
          }
          if (a.unresolved()) {
            unresolved++;
          }
          break;
        case COMMENT:
          c++;
          break;
        case CONFLICT:
          x++;
          if (a.open()) {
            openX++;
          }
          break;
        case MARK:
          m++;
          break;
      }
    }
    return new SpecReviewAnnotationCounts(q, open, q - open, c, m, unresolved, x, openX);
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
    return insertComment(path, field, afterParagraph, text, author, id, null);
  }

  /**
   * {@link #insertComment(String, String, int, String, String, String)} whose header records the
   * change time {@code at}, else the clock's (SOM §11.9.10); {@code at} may be null.
   */
  public String insertComment(
      String path,
      String field,
      int afterParagraph,
      String text,
      String author,
      String id,
      String at) {
    String time = time(at);
    String cid = id != null ? id : nextCommentId();
    String value = get(path, field);
    int end = paragraphLastLine(value, afterParagraph);
    set(path, field, insertAfterLine(value, end, formatCommentBlock(cid, text, author, time)));
    return cid;
  }

  /**
   * Inserts a question block after paragraph {@code afterParagraph} (0-based; -1: at the start) of
   * the value at {@code path} / {@code field} (null for content); its header carries the clock's
   * time (SOM §11.9.10).
   */
  public void insertQuestion(
      String path, String field, int afterParagraph, SpecQuestionDraft question) {
    insertQuestion(path, field, afterParagraph, question, null);
  }

  /**
   * {@link #insertQuestion(String, String, int, SpecQuestionDraft)} whose header carries the time
   * {@code at}, else the clock's (SOM §11.9.10); {@code at} may be null.
   */
  public void insertQuestion(
      String path, String field, int afterParagraph, SpecQuestionDraft question, String at) {
    String time = time(at);
    String value = get(path, field);
    int end = paragraphLastLine(value, afterParagraph);
    set(path, field, insertAfterLine(value, end, formatQuestionBlock(question, time)));
  }

  /**
   * Inserts a question block directly after the comment {@code commentId}; its header carries the
   * clock's time (SOM §11.9.10).
   */
  public void insertQuestionAfterComment(String commentId, SpecQuestionDraft question) {
    insertQuestionAfterComment(commentId, question, null);
  }

  /**
   * {@link #insertQuestionAfterComment(String, SpecQuestionDraft)} whose header carries the time
   * {@code at}, else the clock's (SOM §11.9.10); {@code at} may be null.
   */
  public void insertQuestionAfterComment(String commentId, SpecQuestionDraft question, String at) {
    String time = time(at);
    FoundComment f = findComment(commentId);
    set(
        f.value.path,
        f.value.field,
        insertAfterLine(
            f.value.text, f.comment.block.end, formatQuestionBlock(question, time)));
  }

  /**
   * Writes {@code answer} as the question's team answer, {@code **Answer (<time>):**} with the
   * clock's time (SOM §11.9.10); empty reopens it as {@code **Answer:**}.
   */
  public void setAnswer(String questionId, String answer) {
    setAnswer(questionId, answer, null);
  }

  /**
   * Writes {@code answer} as the question's team answer, {@code **Answer (<time>):**} with the
   * clock's time (SOM §11.9.10); empty reopens it as {@code **Answer:**}. With an
   * {@code author}, writes that member's individual answer instead, grouped and placed by the rules
   * of SOM §11.9.8 (empty: only takes the member out); an author that is not a member id is
   * refused. {@code author} may be null.
   */
  public void setAnswer(String questionId, String answer, String author) {
    setAnswer(questionId, answer, author, null);
  }

  /**
   * {@link #setAnswer(String, String, String)} whose team or individual answer records the change
   * time {@code at}, else the clock's (SOM §11.9.10); {@code at} may be null.
   */
  public void setAnswer(String questionId, String answer, String author, String at) {
    if (author != null && !isReviewMemberId(author)) {
      throw new SpecReviewAnnotationError(
          "\"" + author + "\" is not a member id (lowercase letters, digits and _)");
    }
    FoundQuestion f = findQuestion(questionId);
    Question q = f.question;
    if (author != null) {
      String time = trim(answer).isEmpty() ? null : time(at);
      set(
          f.value.path,
          f.value.field,
          setIndividualAnswer(f.value.text, q, author, answer, time));
      return;
    }
    List<String> lines = splitLines(f.value.text);
    List<String> a = splitLines(answer);
    List<String> written = new ArrayList<>();
    if (answer.isEmpty()) {
      written.add("> " + ANSWER_LABEL);
    } else {
      written.add("> **Answer (" + time(at) + "):** " + a.get(0));
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
    editComment(commentId, text, null);
  }

  /**
   * Replaces a comment's text; its marker, id and author stay as written, the change time becomes
   * {@code at}, else the clock's (SOM §11.9.10). {@code at} may be null.
   */
  public void editComment(String commentId, String text, String at) {
    String time = time(at);
    FoundComment f = findComment(commentId);
    Comment c = f.comment;
    List<String> lines = splitLines(f.value.text);
    List<String> t = splitLines(text);
    List<String> block = new ArrayList<>();
    String who = authorAndTime(c.author, time);
    block.add(trimRight(trimRight(c.beforeAuthor) + " (" + who + "): " + t.get(0)));
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
    set(path, field, decideMark(value, marks, index, accept));
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
      int first = n + 1;
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
                m.quote != null ? m.quote.comment : m.comment,
                v.text.substring(m.start, m.end),
                String.join("\n", p.lines.subList(para[0], para[1] + 1)),
                m.authors,
                m.votes,
                m.quote == null ? null : m.quote.toJson(),
                m.commentIndex == null ? null : "M-" + (first + m.commentIndex),
                m.changeIndex == null ? null : "M-" + (first + m.changeIndex),
                m.changedAt));
      }
    }
    return out;
  }

  /**
   * Applies {@code decide} to every mark in the subtree {@code underPath} (null: the whole
   * document), one write per value.
   */
  private SpecMarkReport applyMarks(
      BiFunction<String, Mark, SpecMarkDecision> decide, String underPath) {
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
      SpecMarkDecision[] decided = new SpecMarkDecision[p.marks.size()];
      for (int k = 0; k < p.marks.size(); k++) {
        decided[k] = decide.apply(ids.get(k), p.marks.get(k));
      }
      for (int k = p.marks.size() - 1; k >= 0; k--) {
        if (!isDecided(decided[k])) {
          continue;
        }
        SpecMarkDecision d = decided[k];
        Mark m = p.marks.get(k);
        String repl = markReplacement(m, d == SpecMarkDecision.ACCEPT);
        Integer ci = m.commentIndex;
        if (ci != null && !isDecided(decided[ci])) {
          v = recordOutcome(v, p.marks.get(ci).quote, d == SpecMarkDecision.ACCEPT);
        }
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
        v = replaceMark(v, m, repl, d == SpecMarkDecision.ACCEPT);
      }
      if (!v.equals(val.text)) {
        set(val.path, val.field, v);
      }
      applied.addAll(outcomes);
    }
    return new SpecMarkReport(applied, issues);
  }

  private static boolean isDecided(SpecMarkDecision d) {
    return d != null && d != SpecMarkDecision.LEAVE;
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
    return applyMarks((id, m) -> decisions.get(id), null);
  }

  /** Accepts every inline mark of the document. */
  public SpecMarkReport acceptAllMarks() {
    return acceptAllMarks(null);
  }

  /**
   * Accepts every inline mark under {@code path} (null: the whole document), except change
   * comments, which stay (SOM §11.9.3).
   */
  public SpecMarkReport acceptAllMarks(String path) {
    return applyMarks((id, m) -> m.quote == null ? SpecMarkDecision.ACCEPT : null, path);
  }

  /** Rejects every inline mark of the document. */
  public SpecMarkReport rejectAllMarks() {
    return rejectAllMarks(null);
  }

  /**
   * Rejects every inline mark under {@code path} (null: the whole document), except change
   * comments, which stay (SOM §11.9.3).
   */
  public SpecMarkReport rejectAllMarks(String path) {
    return applyMarks((id, m) -> m.quote == null ? SpecMarkDecision.REJECT : null, path);
  }

  /** A mark found by its id, with its value. */
  private static final class FoundMark {
    final Value value;
    final Parsed parsed;
    final int index;

    FoundMark(Value value, Parsed parsed, int index) {
      this.value = value;
      this.parsed = parsed;
      this.index = index;
    }
  }

  /**
   * The mark {@code M-<n>} {@code markId} with its value, refused when the document is no longer at
   * {@code revision} (when given) or holds no such mark.
   */
  private FoundMark findMark(String markId, String revision) {
    if (revision != null) {
      String current = revision();
      if (!revision.equals(current)) {
        throw new SpecReviewAnnotationError(
            "the document changed since revision "
                + revision
                + " (now "
                + current
                + "); list the marks again");
      }
    }
    int n = 0;
    for (Value v : values()) {
      Parsed p = parse(v.text);
      for (int k = 0; k < p.marks.size(); k++) {
        if (("M-" + (++n)).equals(markId)) {
          return new FoundMark(v, p, k);
        }
      }
    }
    throw new SpecReviewAnnotationError("no inline mark " + markId + " in the document");
  }

  /** {@link #commentChange(String, String, String, String)} without an author or revision. */
  public String commentChange(String markId, String text) {
    return commentChange(markId, text, null, null);
  }

  /**
   * Writes a change comment (SOM §11.9.3) directly after the change mark {@code markId}, its quote
   * written from the mark and {@code text} after it, with an attribution token {@code {@author}}
   * when {@code author} is given (null: none), and returns the new comment's id. Refused — nothing
   * changes — for an unknown id, a stale {@code revision} (null: not checked), a mark that is not a
   * change or already has an attached comment, a change its quote cannot hold, a {@code text} that
   * is empty or holds a mark delimiter or a blank line, and an {@code author} that is not a member
   * id.
   */
  public String commentChange(String markId, String text, String author, String revision) {
    return commentChange(markId, text, author, revision, null);
  }

  /**
   * {@link #commentChange(String, String, String, String)} whose token records the change time
   * {@code at}, else the clock's (SOM §11.9.10); {@code at} may be null.
   */
  public String commentChange(
      String markId, String text, String author, String revision, String at) {
    String time = time(at);
    FoundMark f = findMark(markId, revision);
    Mark m = f.parsed.marks.get(f.index);
    String value = f.value.text;
    if (!isChangeMark(m.kind)) {
      throw new SpecReviewAnnotationError(
          markId + " is a " + m.kind.value + " mark, not a change");
    }
    if (m.commentIndex != null) {
      throw new SpecReviewAnnotationError(markId + " already has a comment; edit it instead");
    }
    String comment = checkInlineComment(text);
    if (author != null && !isReviewMemberId(author)) {
      throw new SpecReviewAnnotationError("\"" + author + "\" is not a member id");
    }
    String d;
    switch (m.kind) {
      case INSERTION:
        d = "++";
        break;
      case DELETION:
        d = "--";
        break;
      default:
        d = "~~";
    }
    String body = m.kind == SpecMarkKind.SUBSTITUTION ? m.text + " ~> " + m.newText : m.text;
    if (body.contains(d + "]") || body.contains("<<}")) {
      throw new SpecReviewAnnotationError(
          markId + " holds \"" + d + "]\" or \"<<}\", which its quote cannot hold");
    }
    String markup =
        "{>> [" + d + " " + body + " " + d + "] " + comment + " <<}"
            + formatAttributionToken(
                author == null ? Collections.emptyList() : Collections.singletonList(author),
                Collections.emptyList(),
                time);
    set(
        f.value.path,
        f.value.field,
        value.substring(0, m.end) + markup + value.substring(m.end));
    return "M-" + (Integer.parseInt(markId.substring(2)) + 1);
  }

  /** {@link #editMarkComment(String, String, String)} without a revision check. */
  public void editMarkComment(String markId, String text) {
    editMarkComment(markId, text, null);
  }

  /**
   * Replaces the comment of the comment mark, change comment or commented highlight {@code markId}
   * with {@code text} (SOM §11.9.3). A change comment keeps its quote as written, and the
   * attribution token stays. Refused — nothing changes — for an unknown id, a stale {@code
   * revision} (null: not checked), a mark that holds no comment, and a {@code text} that is empty
   * or holds a mark delimiter or a blank line.
   */
  public void editMarkComment(String markId, String text, String revision) {
    editMarkComment(markId, text, revision, null);
  }

  /**
   * {@link #editMarkComment(String, String, String)} whose token's change time becomes {@code at},
   * else the clock's (SOM §11.9.10); authors and votes stay. {@code at} may be null.
   */
  public void editMarkComment(String markId, String text, String revision, String at) {
    String time = time(at);
    FoundMark f = findMark(markId, revision);
    Mark m = f.parsed.marks.get(f.index);
    String value = f.value.text;
    String comment = checkInlineComment(text);
    String markup;
    if (m.kind == SpecMarkKind.COMMENT) {
      Quote q = m.quote;
      int open = m.start + 3;
      markup =
          q == null
              ? "{>> " + comment + " <<}"
              : "{>> " + trimLeft(value.substring(open, q.end)) + " " + comment + " <<}";
    } else if (m.kind == SpecMarkKind.HIGHLIGHT && m.comment != null) {
      markup = "{== " + m.text + " ==}{>> " + comment + " <<}";
    } else {
      throw new SpecReviewAnnotationError(markId + " holds no comment");
    }
    String token = formatAttributionToken(m.authors, m.votes, time);
    set(
        f.value.path,
        f.value.field,
        value.substring(0, m.start) + markup + token + value.substring(m.end));
  }

  /**
   * Removes every annotation and writes the result back: every inline mark accepted, every
   * conflict's decision applied (SOM §11.9.8), every comment, question and conflict block removed.
   * Malformed marks stay and are reported. Refused — nothing changes — while a conflict is open,
   * unresolved ({@code open:}), malformed, or decided for a letter it has no alternative for.
   */
  public SpecMarkReport removeAllAnnotations() {
    List<DecidedConflict> decided = decidedConflicts();
    SpecMarkReport marks = applyMarks((id, m) -> SpecMarkDecision.ACCEPT, null);
    List<SpecConflictOutcome> outcomes = new ArrayList<>();
    for (Value val : values()) {
      String v = val.text;
      List<DecidedConflict> here = new ArrayList<>();
      for (DecidedConflict d : decided) {
        if (d.path.equals(val.path) && Objects.equals(d.field, val.field)) {
          here.add(d);
        }
      }
      if (!here.isEmpty()) {
        v = applyConflicts(val.path, val.field, v, here, outcomes);
      }
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
    return new SpecMarkReport(marks.applied, marks.malformed, outcomes);
  }

  /**
   * Every conflict block of the document with the line it opens on, in document order — or the
   * refusal of {@code removeAllAnnotations} when one of them cannot be applied.
   */
  private List<DecidedConflict> decidedConflicts() {
    List<DecidedConflict> out = new ArrayList<>();
    for (Value val : values()) {
      Parsed p = parse(val.text);
      int index = 0;
      for (Block b : p.blocks) {
        if (b.kind != SpecReviewAnnotationKind.CONFLICT) {
          continue;
        }
        Conflict c = b.conflict;
        String where =
            val.path + (val.field == null ? "" : " / " + val.field) + ", line " + b.start;
        if (c.id == null || c.base == null || c.alternatives.isEmpty()) {
          throw new SpecReviewAnnotationError(
              where + ": a malformed conflict block cannot be applied");
        }
        if (c.decision.isEmpty() || isUnresolved(c.decision)) {
          throw new SpecReviewAnnotationError(
              where
                  + ": conflict "
                  + c.id
                  + " is "
                  + (c.decision.isEmpty() ? "open" : "unresolved")
                  + "; decide it before removing the annotations");
        }
        String letter = decisionLetter(c.decision);
        if (letter != null && !letter.equals("base") && !hasAlternative(c, letter)) {
          throw new SpecReviewAnnotationError(
              where + ": conflict " + c.id + " has no alternative (" + letter + ")");
        }
        out.add(new DecidedConflict(val.path, val.field, index++, c.id, b.start, c.decision));
      }
    }
    return out;
  }

  private static boolean hasAlternative(Conflict c, String letter) {
    for (SpecConflictAlternative a : c.alternatives) {
      if (a.letter.equals(letter)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Applies the decided conflicts of one value (marks already accepted), from the last block up so
   * earlier line numbers stay valid, and records each. Where the chosen text goes follows the
   * conflict's text (SOM §11.9.8, "Applying"): a form field, another value, this value's text
   * paragraphs, or — the default — the text paragraph directly before the block.
   */
  private String applyConflicts(
      String path,
      String field,
      String value,
      List<DecidedConflict> decided,
      List<SpecConflictOutcome> outcomes) {
    String v = value;
    List<SpecConflictOutcome> recorded = new ArrayList<>();
    List<Block> conflicts = new ArrayList<>();
    for (Block b : parse(v).blocks) {
      if (b.kind == SpecReviewAnnotationKind.CONFLICT) {
        conflicts.add(b);
      }
    }
    for (int k = conflicts.size() - 1; k >= 0; k--) {
      DecidedConflict d = null;
      for (DecidedConflict x : decided) {
        if (x.index == k) {
          d = x;
          break;
        }
      }
      Conflict c = conflicts.get(k).conflict;
      String result = chosenText(c);
      recorded.add(0, new SpecConflictOutcome(d.id, path, field, d.line, d.decision, result));
      v = applyConflict(path, field, v, c, result);
    }
    outcomes.addAll(recorded);
    return v;
  }

  private static final Pattern FIELD_TARGET = Pattern.compile("(\\S+) (\\S+)");
  private static final Pattern VALUE_TARGET = Pattern.compile("[^\\s,]+/[^\\s,]+");

  private String applyConflict(String path, String field, String value, Conflict c, String result) {
    if (STRUCTURAL_TOPICS.contains(c.topic)) {
      return value;
    }
    Matcher target = FIELD_TARGET.matcher(c.text);
    if (target.matches() && doc.formField(target.group(1), target.group(2)) != null) {
      doc.setFormField(target.group(1), target.group(2), result);
      return value;
    }
    if (field == null && c.text.equals(path)) {
      return replaceTextRun(value, c.block, result);
    }
    if (VALUE_TARGET.matcher(c.text).matches() && !c.text.equals(path)) {
      doc.setContent(c.text, result);
      return value;
    }
    return replaceParagraphBefore(value, c.block, result);
  }

  /**
   * Writes {@code text} at {@code path} / {@code field} (null for content) as a marked change
   * against the value there now (SOM §11.9.3). A value that already holds change marks is compared
   * from its original — every mark rejected — so a second edit of the same passage updates its mark
   * instead of nesting one.
   */
  public SpecMarkedChange setMarked(String path, String field, String text) {
    return setMarked(path, field, text, null, null);
  }

  /**
   * {@link #setMarked(String, String, String)} with every change mark carrying a token (SOM
   * §11.9.10): an unchanged mark keeps its own, a new one gets {@code author} and {@code at} (else
   * the clock's time). {@code author} and {@code at} may be null.
   */
  public SpecMarkedChange setMarked(
      String path, String field, String text, String author, String at) {
    checkAuthor(author);
    String time = time(at);
    String current = get(path, field);
    SpecMarkedChange result = markKeepingChangeComments(current, text);
    SpecMarkedChange stamped =
        new SpecMarkedChange(stampMarks(current, result.text, author, time), result.exact);
    set(path, field, stamped.text);
    return stamped;
  }

  private static void checkAuthor(String author) {
    if (author != null && !isReviewMemberId(author)) {
      throw new SpecReviewAnnotationError(
          "\"" + author + "\" is not a member id (lowercase letters, digits and _)");
    }
  }

  /**
   * Marks the value at {@code path} / {@code field} (null for content) as a change against {@code
   * earlier}, an earlier version of it.
   */
  public SpecMarkedChange markAgainst(String path, String field, String earlier) {
    return markAgainst(path, field, earlier, null, null);
  }

  /**
   * {@link #markAgainst(String, String, String)} with its change marks stamped as {@link
   * #setMarked(String, String, String, String, String)} stamps them.
   */
  public SpecMarkedChange markAgainst(
      String path, String field, String earlier, String author, String at) {
    checkAuthor(author);
    String time = time(at);
    String current = get(path, field);
    SpecMarkedChange result = markChangeText(earlier, current);
    SpecMarkedChange stamped =
        new SpecMarkedChange(stampMarks(current, result.text, author, time), result.exact);
    set(path, field, stamped.text);
    return stamped;
  }

  /**
   * The paragraphs of the value at {@code path} / {@code field} (null for the content), in order —
   * the units {@code afterParagraph} of {@link #insertComment} and {@code insertQuestion} counts.
   *
   * @throws SpecReviewAnnotationError when the document holds no such value
   */
  public List<SpecParagraph> paragraphs(String path, String field) {
    String value = field == null ? doc.content(path) : doc.formField(path, field);
    if (value == null) {
      throw new SpecReviewAnnotationError(
          "no value at " + path + (field == null ? "" : " / " + field));
    }
    Parsed p = parse(value);
    List<int[]> paras = paragraphs(p.lines, p.code);
    List<SpecParagraph> out = new ArrayList<>();
    for (int i = 0; i < paras.size(); i++) {
      int s = paras.get(i)[0];
      int e = paras.get(i)[1];
      String annotation = null;
      for (Block b : p.blocks) {
        if (b.start == s) {
          annotation = b.kind.value;
          break;
        }
      }
      out.add(new SpecParagraph(i, s, e, String.join("\n", p.lines.subList(s, e + 1)), annotation));
    }
    return out;
  }

  /** The paragraphs of the content value at {@code path}. */
  public List<SpecParagraph> paragraphs(String path) {
    return paragraphs(path, null);
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
        if (b.conflict != null && b.conflict.id != null) {
          ids.add(b.conflict.id);
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

  // -------------------------------------------------------------------------
  // Writing changes as inline marks (SOM §11.9.3, annot5).
  // -------------------------------------------------------------------------

  /**
   * One token of a value: a run of whitespace, a word (a run of non-whitespace with inline code
   * spans kept whole) or a fenced code block (its lines).
   */
  private static final class Tok {
    final String text;
    final boolean space;

    Tok(String text, boolean space) {
      this.text = text;
      this.space = space;
    }
  }

  /** One diff op: 0 keep, 1 delete (old), 2 insert (new). */
  private static final class Op {
    final int kind;
    final Tok tok;

    Op(int kind, Tok tok) {
      this.kind = kind;
      this.tok = tok;
    }
  }

  /** Space, tab or newline. */
  private static boolean isMarkWs(char c) {
    return c == ' ' || c == '\t' || c == '\n';
  }

  private static void addTok(List<Tok> out, String t, boolean space) {
    if (t.isEmpty()) {
      return;
    }
    if (space && !out.isEmpty() && out.get(out.size() - 1).space) {
      out.set(out.size() - 1, new Tok(out.get(out.size() - 1).text + t, true));
    } else {
      out.add(new Tok(t, space));
    }
  }

  private static void addWords(List<Tok> out, String s) {
    int i = 0;
    int len = s.length();
    while (i < len) {
      if (isMarkWs(s.charAt(i))) {
        int st = i;
        while (i < len && isMarkWs(s.charAt(i))) {
          i++;
        }
        addTok(out, s.substring(st, i), true);
        continue;
      }
      int st = i;
      while (i < len && !isMarkWs(s.charAt(i))) {
        if (s.charAt(i) == '`') {
          int n = 0;
          while (i + n < len && s.charAt(i + n) == '`') {
            n++;
          }
          // The matching run of exactly n backticks ends the span.
          int j = i + n;
          int close = -1;
          while (j < len) {
            if (s.charAt(j) == '`') {
              int m = 0;
              while (j + m < len && s.charAt(j + m) == '`') {
                m++;
              }
              if (m == n) {
                close = j;
                break;
              }
              j += m;
            } else {
              j++;
            }
          }
          i = close < 0 ? i + n : close + n;
          continue;
        }
        i++;
      }
      addTok(out, s.substring(st, i), false);
    }
  }

  private static List<Tok> tokens(String value) {
    List<Tok> out = new ArrayList<>();
    List<String> lines = splitLines(value);
    boolean[] code = codeLines(lines);
    int k = 0;
    while (k < lines.size()) {
      if (k > 0) {
        addTok(out, "\n", true);
      }
      int st = k;
      boolean isCode = code[k];
      while (k + 1 < lines.size() && code[k + 1] == isCode) {
        k++;
      }
      String run = String.join("\n", lines.subList(st, k + 1));
      if (isCode) {
        addTok(out, run, false);
      } else {
        addWords(out, run);
      }
      k++;
    }
    return out;
  }

  /** The diff of two token lists. LCS over token text; ties prefer the deletion. */
  private static List<Op> diff(List<Tok> a, List<Tok> b) {
    int n = a.size();
    int m = b.size();
    int[][] l = new int[n + 1][m + 1];
    for (int i = n - 1; i >= 0; i--) {
      for (int j = m - 1; j >= 0; j--) {
        l[i][j] =
            a.get(i).text.equals(b.get(j).text)
                ? l[i + 1][j + 1] + 1
                : (l[i + 1][j] >= l[i][j + 1] ? l[i + 1][j] : l[i][j + 1]);
      }
    }
    List<Op> ops = new ArrayList<>();
    int i = 0;
    int j = 0;
    while (i < n || j < m) {
      if (i < n && j < m && a.get(i).text.equals(b.get(j).text)) {
        ops.add(new Op(0, a.get(i)));
        i++;
        j++;
      } else if (j >= m || (i < n && l[i + 1][j] >= l[i][j + 1])) {
        ops.add(new Op(1, a.get(i)));
        i++;
      } else {
        ops.add(new Op(2, b.get(j)));
        j++;
      }
    }
    return ops;
  }

  /** {@code s} with its leading and trailing spaces, tabs and newlines removed. */
  private static String trimMarkWs(String s) {
    int a = 0;
    int b = s.length();
    while (a < b && isMarkWs(s.charAt(a))) {
      a++;
    }
    while (b > a && isMarkWs(s.charAt(b - 1))) {
      b--;
    }
    return s.substring(a, b);
  }

  private static String trimLeft(String s) {
    int a = 0;
    while (a < s.length() && isWs(s.charAt(a))) {
      a++;
    }
    return s.substring(a);
  }

  private static String leadWs(String x) {
    return x.substring(0, x.length() - trimLeft(x).length());
  }

  private static String trailWs(String x) {
    return x.substring(trimRight(x).length());
  }

  /** The markup for one region whose old text is {@code o} and new text is {@code n}. */
  private static String markup(String o, String n) {
    if (o.isEmpty()) {
      return "{++ " + n + " ++}";
    }
    if (n.isEmpty()) {
      return "{-- " + o + " --}";
    }
    return "{~~ " + o + " ~> " + n + " ~~}";
  }

  /**
   * The marked emission for the region [r0, r1) of {@code ops}, with the old and the new text
   * around it, or null when no mark round-trips there.
   */
  private static String emitRegion(
      List<Op> ops,
      int r0,
      int r1,
      String oldBefore,
      String newBefore,
      String oldAfter,
      String newAfter) {
    StringBuilder o = new StringBuilder();
    StringBuilder n = new StringBuilder();
    for (int k = r0; k < r1; k++) {
      Op op = ops.get(k);
      if (op.kind != 2) {
        o.append(op.tok.text);
      }
      if (op.kind != 1) {
        n.append(op.tok.text);
      }
    }
    String os = o.toString();
    String ns = n.toString();
    // Whitespace the two sides share at the edges stays outside the mark.
    int lead = 0;
    while (lead < os.length()
        && lead < ns.length()
        && os.charAt(lead) == ns.charAt(lead)
        && isMarkWs(os.charAt(lead))) {
      lead++;
    }
    int trail = 0;
    while (trail < os.length() - lead
        && trail < ns.length() - lead
        && os.charAt(os.length() - 1 - trail) == ns.charAt(ns.length() - 1 - trail)
        && isMarkWs(os.charAt(os.length() - 1 - trail))) {
      trail++;
    }
    String oi = os.substring(lead, os.length() - trail);
    String ni = ns.substring(lead, ns.length() - trail);
    // The mark's content is trimmed when read, so it must already be trimmed; the whitespace still
    // differing is placed outside, and the tidy rules then have to restore the other side.
    String ot = trimMarkWs(oi);
    String nt = trimMarkWs(ni);
    if (ot.isEmpty() && nt.isEmpty()) {
      return null;
    }
    String pre = os.substring(0, lead);
    String post = os.substring(os.length() - trail);
    String mk = markup(ot, nt);
    String[][] candidates = {
      {leadWs(ni), trailWs(ni)},
      {leadWs(oi), trailWs(oi)},
      {"", ""},
      {leadWs(ni), ""},
      {"", trailWs(ni)},
    };
    for (String[] c : candidates) {
      String emission = pre + c[0] + mk + c[1] + post;
      String acc = applyInlineMarksText(newBefore + emission + newAfter, true);
      String rej = applyInlineMarksText(oldBefore + emission + oldAfter, false);
      if (acc.equals(newBefore + ns + newAfter) && rej.equals(oldBefore + os + oldAfter)) {
        return emission;
      }
    }
    return null;
  }

  private static String side(List<Op> ops, int from, int to, int skip) {
    StringBuilder b = new StringBuilder();
    for (int q = from; q < to; q++) {
      if (ops.get(q).kind != skip) {
        b.append(ops.get(q).tok.text);
      }
    }
    return b.toString();
  }

  /**
   * Marks the token-level differences of {@code o} → {@code n}, where the text before them is
   * {@code ob} (old) / {@code nb} (new) and after them {@code oa} / {@code na}. Null when the marks
   * do not round-trip.
   */
  private static String markTokens(
      String o, String n, String ob, String nb, String oa, String na) {
    List<Op> ops = diff(tokens(o), tokens(n));
    int end = ops.size();
    List<int[]> runs = new ArrayList<>();
    int k = 0;
    while (k < end) {
      if (ops.get(k).kind == 0) {
        k++;
        continue;
      }
      int s = k;
      while (k < end && ops.get(k).kind != 0) {
        k++;
      }
      runs.add(new int[] {s, k});
    }
    // Changes separated by at most two unchanged words are one mark.
    List<int[]> merged = new ArrayList<>();
    for (int[] r : runs) {
      if (!merged.isEmpty()) {
        int[] last = merged.get(merged.size() - 1);
        int words = 0;
        for (int q = last[1]; q < r[0]; q++) {
          if (!ops.get(q).tok.space) {
            words++;
          }
        }
        if (words <= 2) {
          merged.set(merged.size() - 1, new int[] {last[0], r[1]});
          continue;
        }
      }
      merged.add(r);
    }
    runs = merged;

    // Left to right; a region that does not round-trip grows by one token on each side and is
    // tried again.
    StringBuilder out = new StringBuilder();
    int pos = 0;
    for (int ri = 0; ri < runs.size(); ri++) {
      int r0 = runs.get(ri)[0];
      int r1 = runs.get(ri)[1];
      if (r0 < pos) {
        r0 = pos;
      }
      String emission;
      while (true) {
        emission =
            emitRegion(
                ops,
                r0,
                r1,
                ob + side(ops, 0, r0, 2),
                nb + side(ops, 0, r0, 1),
                side(ops, r1, end, 2) + oa,
                side(ops, r1, end, 1) + na);
        if (emission != null || (r0 <= pos && r1 >= end)) {
          break;
        }
        if (r0 > pos) {
          r0--;
        }
        if (r1 < end) {
          r1++;
        }
      }
      if (emission == null) {
        return null;
      }
      out.append(side(ops, pos, r0, 1)).append(emission);
      pos = r1;
      while (ri + 1 < runs.size() && runs.get(ri + 1)[1] <= pos) {
        ri++;
      }
    }
    out.append(side(ops, pos, end, 1));
    String text = out.toString();
    if (!applyInlineMarksText(nb + text + na, true).equals(nb + n + na)
        || !applyInlineMarksText(ob + text + oa, false).equals(ob + o + oa)) {
      return null;
    }
    return text;
  }

  /**
   * A whole line marked as inserted ({@code ++}) or deleted ({@code --}): its indentation stays
   * outside the mark; a blank line stays blank.
   */
  private static String lineMark(String line, String d) {
    String body = trimLeft(line);
    if (trim(body).isEmpty()) {
      return line;
    }
    String indent = line.substring(0, line.length() - body.length());
    return indent + "{" + d + " " + trimRight(body) + " " + d + "}";
  }

  private static List<String> nonBlank(List<String> ls) {
    List<String> out = new ArrayList<>();
    for (String l : ls) {
      if (!trim(l).isEmpty()) {
        out.add(l);
      }
    }
    return out;
  }

  private static List<String> concat(List<String> a, List<String> b) {
    List<String> out = new ArrayList<>(a);
    out.addAll(b);
    return out;
  }

  private static List<String> concat(List<String> a, List<String> b, List<String> c) {
    List<String> out = concat(a, b);
    out.addAll(c);
    return out;
  }

  /**
   * {@code newValue} with its differences from {@code oldValue} marked, so that accepting every mark
   * gives exactly {@code newValue} and rejecting every mark exactly {@code oldValue} (SOM §11.9.3).
   * The diff runs by line, then by word inside a changed run of lines; words are never split,
   * changes separated by at most two unchanged words are one mark, and nothing inside code is
   * marked.
   */
  public static SpecMarkedChange markChangeText(String oldValue, String newValue) {
    if (oldValue.equals(newValue)) {
      return new SpecMarkedChange(newValue, true);
    }
    List<String> ol = splitLines(oldValue);
    List<String> nl = splitLines(newValue);
    boolean[] oc = codeLines(ol);
    boolean[] nc = codeLines(nl);
    List<Tok> ot = new ArrayList<>();
    for (String l : ol) {
      ot.add(new Tok(l, false));
    }
    List<Tok> nt = new ArrayList<>();
    for (String l : nl) {
      nt.add(new Tok(l, false));
    }
    List<Op> lops = diff(ot, nt);
    List<String> out = new ArrayList<>();
    boolean exact = true;
    int oi = 0;
    int ni = 0;
    int k = 0;
    while (k < lops.size()) {
      if (lops.get(k).kind == 0) {
        out.add(nl.get(ni));
        oi++;
        ni++;
        k++;
        continue;
      }
      int d0 = oi;
      int n0 = ni;
      while (k < lops.size() && lops.get(k).kind != 0) {
        if (lops.get(k).kind == 1) {
          oi++;
        } else {
          ni++;
        }
        k++;
      }
      List<String> del = ol.subList(d0, oi);
      List<String> ins = nl.subList(n0, ni);
      List<String> ob = ol.subList(0, d0);
      List<String> oa = ol.subList(oi, ol.size());
      List<String> nb = nl.subList(0, n0);
      List<String> na = nl.subList(ni, nl.size());
      List<String> emitted = null;
      boolean inCode = false;
      for (int q = d0; q < oi; q++) {
        inCode |= oc[q];
      }
      for (int q = n0; q < ni; q++) {
        inCode |= nc[q];
      }
      if (!inCode) {
        List<List<String>> candidates = new ArrayList<>();
        if (!del.isEmpty() && !ins.isEmpty()) {
          String t =
              markTokens(
                  String.join("\n", del),
                  String.join("\n", ins),
                  ob.isEmpty() ? "" : String.join("\n", ob) + "\n",
                  nb.isEmpty() ? "" : String.join("\n", nb) + "\n",
                  oa.isEmpty() ? "" : "\n" + String.join("\n", oa),
                  na.isEmpty() ? "" : "\n" + String.join("\n", na));
          if (t != null) {
            candidates.add(splitLines(t));
          }
        }
        List<String> dm = new ArrayList<>();
        for (String l : del) {
          dm.add(lineMark(l, "--"));
        }
        List<String> im = new ArrayList<>();
        for (String l : ins) {
          im.add(lineMark(l, "++"));
        }
        candidates.add(concat(dm, im));
        candidates.add(concat(nonBlank(dm), im));
        candidates.add(concat(dm, nonBlank(im)));
        candidates.add(concat(nonBlank(dm), nonBlank(im)));
        for (List<String> e : candidates) {
          if (applyInlineMarksText(String.join("\n", concat(nb, e, na)), true).equals(newValue)
              && applyInlineMarksText(String.join("\n", concat(ob, e, oa)), false)
                  .equals(oldValue)) {
            emitted = e;
            break;
          }
        }
      }
      if (emitted == null) {
        exact = false;
        out.addAll(ins);
      } else {
        out.addAll(emitted);
      }
    }
    String text = String.join("\n", out);
    if (exact
        && (!applyInlineMarksText(text, true).equals(newValue)
            || !applyInlineMarksText(text, false).equals(oldValue))) {
      return new SpecMarkedChange(newValue, false);
    }
    return new SpecMarkedChange(text, exact);
  }

  // -------------------------------------------------------------------------
  // Text-level building blocks of the merge (SOM §11.9.9). Package-private: for
  // SpecReviewMerge only.
  // -------------------------------------------------------------------------

  /** One paragraph of a value as the merge sees it: text, or an annotation block. */
  static final class ReviewPiece {
    /** {@code text}, or the kind value of the annotation block the paragraph opens with. */
    final String kind;
    /** The paragraph's lines, verbatim. */
    final String text;
    /** A comment's id (null without one), a conflict's id (null when malformed). */
    final String id;
    /** A comment's author, null without one. */
    final String author;
    /** A comment's text. */
    final String commentText;
    /** The ids of a question block's questions. */
    final List<String> questionIds;

    /** A comment's change time (SOM §11.9.10), null without one. */
    final String changedAt;

    ReviewPiece(
        String kind,
        String text,
        String id,
        String author,
        String commentText,
        List<String> questionIds) {
      this(kind, text, id, author, commentText, questionIds, null);
    }

    ReviewPiece(
        String kind,
        String text,
        String id,
        String author,
        String commentText,
        List<String> questionIds,
        String changedAt) {
      this.kind = kind;
      this.text = text;
      this.id = id;
      this.author = author;
      this.commentText = commentText;
      this.questionIds = questionIds;
      this.changedAt = changedAt;
    }

    boolean isText() {
      return kind.equals("text");
    }
  }

  /** The paragraphs of {@code value} (SOM §11.9.1), each classified. */
  static List<ReviewPiece> reviewPieces(String value) {
    List<ReviewPiece> out = new ArrayList<>();
    if (value.isEmpty()) {
      return out;
    }
    Parsed p = parse(value);
    for (int[] r : paragraphs(p.lines, p.code)) {
      Block b = null;
      for (Block x : p.blocks) {
        if (x.start == r[0]) {
          b = x;
          break;
        }
      }
      String text = String.join("\n", p.lines.subList(r[0], r[1] + 1));
      if (b == null) {
        out.add(new ReviewPiece("text", text, null, null, "", new ArrayList<>()));
        continue;
      }
      List<String> questionIds = new ArrayList<>();
      for (Question q : b.questions) {
        questionIds.add(q.id);
      }
      String id =
          b.comment != null ? b.comment.id : b.conflict != null ? b.conflict.id : null;
      out.add(
          new ReviewPiece(
              b.kind.value,
              text,
              id,
              b.comment == null ? null : b.comment.author,
              b.comment == null ? "" : b.comment.text,
              questionIds,
              b.comment == null ? null : b.comment.changedAt));
    }
    return out;
  }

  /** One inline mark of a value, with what its decisions leave. */
  static final class ReviewMark {
    final int start;
    final int end;
    final int bodyEnd;
    final SpecMarkKind kind;
    /** The mark as written, its attribution token included. */
    final String markup;
    final List<String> authors;
    final List<SpecMarkVote> votes;
    /** The text accepting it leaves. */
    final String accepted;
    /** The text rejecting it leaves. */
    final String rejected;

    /** Its token's change time (SOM §11.9.10), or null. */
    final String changedAt;

    ReviewMark(String value, Mark m) {
      this.start = m.start;
      this.end = m.end;
      this.bodyEnd = m.bodyEnd;
      this.kind = m.kind;
      this.markup = value.substring(m.start, m.end);
      this.authors = m.authors;
      this.votes = m.votes;
      this.accepted = markReplacement(m, true);
      this.rejected = markReplacement(m, false);
      this.changedAt = m.changedAt;
    }

    /** Whether the mark carries an attribution token. */
    boolean hasToken() {
      return end > bodyEnd;
    }
  }

  /** The inline marks of {@code value}, in order (marks in code are not marks). */
  static List<ReviewMark> reviewMarks(String value) {
    List<ReviewMark> out = new ArrayList<>();
    for (Mark m : parse(value).marks) {
      out.add(new ReviewMark(value, m));
    }
    return out;
  }

  /**
   * {@code value} with the marks {@code decisions} names (by index into {@link #reviewMarks})
   * accepted ({@code true}) or rejected, by the whitespace rules of SOM §11.9.3.
   */
  static String decideReviewMarks(String value, Map<Integer, Boolean> decisions) {
    List<Mark> marks = parse(value).marks;
    String v = value;
    for (int k = marks.size() - 1; k >= 0; k--) {
      Boolean accept = decisions.get(k);
      if (accept == null) {
        continue;
      }
      v = replaceMark(v, marks.get(k), markReplacement(marks.get(k), accept), accept);
    }
    return v;
  }

  /** The attribution token for {@code authors} and {@code votes}, {@code {@agent +alice -bob}}. */
  static String formatAttributionToken(List<String> authors, List<SpecMarkVote> votes) {
    return formatAttributionToken(authors, votes, null);
  }

  /**
   * The attribution token for {@code authors}, {@code votes} and {@code changedAt}, {@code {@agent
   * +alice -bob 2026-11-07T14:05+01:00}} (SOM §11.9.8, §11.9.10); empty when there is nothing to
   * write.
   */
  static String formatAttributionToken(
      List<String> authors, List<SpecMarkVote> votes, String changedAt) {
    List<String> parts = new ArrayList<>();
    if (!authors.isEmpty()) {
      parts.add(String.join(",", authors));
    }
    for (SpecMarkVote x : votes) {
      parts.add((x.accepts() ? "+" : "-") + x.member);
    }
    if (changedAt != null) {
      parts.add(changedAt);
    }
    return parts.isEmpty() ? "" : "{@" + String.join(" ", parts) + "}";
  }

  /** {@code value} with mark {@code m}'s token replaced by one for {@code authors} and {@code votes}. */
  static String withAttribution(
      String value, ReviewMark m, List<String> authors, List<SpecMarkVote> votes) {
    return value.substring(0, m.bodyEnd)
        + formatAttributionToken(authors, votes, m.changedAt)
        + value.substring(m.end);
  }

  /** The team answer of every question of {@code value}, by id, in order. */
  static Map<String, String> reviewTeamAnswers(String value) {
    Map<String, String> out = new LinkedHashMap<>();
    for (Block b : parse(value).blocks) {
      for (Question q : b.questions) {
        out.putIfAbsent(q.id, q.answer);
      }
    }
    return out;
  }

  /**
   * The time of every question's team answer in {@code value}, by id (SOM §11.9.10): the first
   * question with that id; null for an answer written without one.
   */
  static Map<String, String> reviewTeamAnswerTimes(String value) {
    Map<String, String> out = new LinkedHashMap<>();
    for (Block b : parse(value).blocks) {
      for (Question q : b.questions) {
        if (!out.containsKey(q.id)) {
          out.put(q.id, q.answerChangedAt);
        }
      }
    }
    return out;
  }

  /**
   * {@code value} with {@code member}'s individual answer to question {@code questionId} set, as
   * {@code setAnswer} with an author does; null when the value holds no such question.
   */
  static String setIndividualAnswerText(
      String value, String questionId, String member, String answer) {
    return setIndividualAnswerText(value, questionId, member, answer, null);
  }

  /**
   * {@link #setIndividualAnswerText(String, String, String, String)} whose new entry records the
   * change time {@code changedAt} (null: none).
   */
  static String setIndividualAnswerText(
      String value, String questionId, String member, String answer, String changedAt) {
    for (Block b : parse(value).blocks) {
      for (Question q : b.questions) {
        if (q.id.equals(questionId)) {
          return setIndividualAnswer(value, q, member, answer, changedAt);
        }
      }
    }
    return null;
  }

  /** The lines of a conflict's text: the first after its prefix, the rest indented under it. */
  private static List<String> alternativeLines(String prefix, String text) {
    List<String> t = splitLines(text);
    List<String> out = new ArrayList<>();
    out.add(trimRight("> - " + prefix + " " + t.get(0)));
    for (String l : t.subList(1, t.size())) {
      out.add(">   " + l);
    }
    return out;
  }

  /**
   * The lines of a conflict block (SOM §11.9.8): the header, the {@code (base)} line, one lettered
   * alternative per entry naming its members, and an empty {@code **Decision:**}. A text's further
   * lines are indented under it, so a reader gets them back with their line breaks.
   */
  public static List<String> formatConflictBlock(
      String id,
      String topic,
      String text,
      String base,
      List<SpecConflictAlternative> alternatives) {
    List<String> out = new ArrayList<>();
    out.add(trimRight("> " + SCALES + VS16 + " **" + id + EM_DASH_SEP + topic + ":** " + text));
    out.addAll(alternativeLines("(base)", base));
    for (SpecConflictAlternative a : alternatives) {
      out.addAll(
          alternativeLines("(" + a.letter + ") **" + String.join(", ", a.members) + ":**", a.text));
    }
    out.add(">");
    out.add("> " + DECISION_LABEL);
    return out;
  }

  /**
   * Carries the edits {@code x} → {@code y} over to {@code b}, a text equal to {@code x} except
   * where marks of {@code b} were decided in {@code x} (SOM §11.9.9, step 3): every edit lands in
   * {@code b} at the place {@code x} and {@code b} agree on. Null when an edit touches or borders a
   * place where they differ — the edit overlaps a decided mark. Both diffs are the token diffs of
   * {@code markChangeText}.
   */
  static String transplantEdits(String x, String y, String b) {
    List<Tok> xt = tokens(x);
    List<Tok> bt = tokens(b);
    // Where each token of x is in b (-1: x and b differ there).
    int[] toB = new int[xt.size()];
    Arrays.fill(toB, -1);
    int i = 0;
    int j = 0;
    for (Op op : diff(xt, bt)) {
      if (op.kind == 0) {
        toB[i++] = j++;
      } else if (op.kind == 1) {
        i++;
      } else {
        j++;
      }
    }
    // The edits x → y as {first x token, end x token} and the inserted text.
    List<int[]> hunks = new ArrayList<>();
    List<String> inserts = new ArrayList<>();
    i = 0;
    int[] open = null;
    StringBuilder ins = null;
    for (Op op : diff(xt, tokens(y))) {
      if (op.kind == 0) {
        if (open != null) {
          hunks.add(open);
          inserts.add(ins.toString());
        }
        open = null;
        i++;
        continue;
      }
      if (open == null) {
        open = new int[] {i, i};
        ins = new StringBuilder();
      }
      if (op.kind == 1) {
        open[1] = ++i;
      } else {
        ins.append(op.tok.text);
      }
    }
    if (open != null) {
      hunks.add(open);
      inserts.add(ins.toString());
    }
    List<String> out = new ArrayList<>();
    for (Tok t : bt) {
      out.add(t.text);
    }
    for (int h = hunks.size() - 1; h >= 0; h--) {
      int[] at = landing(toB, hunks.get(h)[0], hunks.get(h)[1], bt.size());
      if (at == null) {
        return null;
      }
      List<String> range = out.subList(at[0], at[1]);
      range.clear();
      range.add(inserts.get(h));
    }
    return String.join("", out);
  }

  /**
   * The b-token range an x-token range [x0, x1) lands on, or null when it is not one.
   *
   * <p>A replaced range lands where its tokens are in b, which must be contiguous there; its
   * neighbours are not consulted, because the token diff may align a neighbouring space with
   * another space of b (beside a decided mark) without the range touching that mark. A pure
   * insertion ({@code x0 == x1}) has no tokens of its own, so both neighbours must sit next to each
   * other in b.
   */
  private static int[] landing(int[] toB, int x0, int x1, int bLength) {
    for (int k = x0; k < x1; k++) {
      if (toB[k] < 0 || (k > x0 && toB[k] != toB[k - 1] + 1)) {
        return null;
      }
    }
    if (x1 > x0) {
      return new int[] {toB[x0], toB[x1 - 1] + 1};
    }
    // The neighbours must sit next to the insertion point in b too.
    int left = x0 == 0 ? -1 : toB[x0 - 1];
    int right = x1 == toB.length ? bLength : toB[x1];
    if ((x0 > 0 && left < 0) || (x1 < toB.length && right < 0)) {
      return null;
    }
    if (left + 1 != right) {
      return null;
    }
    return new int[] {left + 1, left + 1};
  }
}
