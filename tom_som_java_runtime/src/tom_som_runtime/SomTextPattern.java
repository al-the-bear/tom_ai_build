package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * The <b>portable text-pattern subset</b> the {@code text} dimension of a spec
 * query matches with ({@code som_multiplatform_spec_model.md} §9) — a faithful
 * port of {@code spec_text_pattern.dart}.
 *
 * <h2>Why this exists rather than {@code java.util.regex}</h2>
 *
 * <p>The query surface reports {@code matchSpans} — offsets into the matched
 * string — and those spans are part of the nine-language contract. Delegating to
 * each language's regex engine would make that contract unkeepable twice over:
 *
 * <ul>
 *   <li><b>Two runtimes have no regex to delegate to.</b> {@code
 *       tom_som_rust_runtime} is std-only by charter and {@code
 *       tom_som_c_runtime} is dependency-free; both would need a hand-rolled
 *       matcher regardless. Native-regex-elsewhere therefore does not remove the
 *       work, it only makes there be <i>two</i> implementations of the same
 *       semantics instead of one.
 *   <li><b>The engines disagree where it matters.</b> Go's {@code regexp} is RE2
 *       (leftmost-longest for alternation), Dart/JS/Java/Python backtrack
 *       (leftmost-first); case folding is Unicode-aware in some and not others.
 *       A corpus could pin only the intersection, leaving every port's behaviour
 *       <i>outside</i> the corpus silently divergent.
 * </ul>
 *
 * <p>So the matcher is one algorithm, transcribed into all nine runtimes. Equal
 * spans follow from equal code rather than from a hope about two libraries.
 *
 * <h2>The grammar</h2>
 *
 * <pre>{@code
 * pattern   := term*
 * term      := atom quantifier?
 * quantifier:= '*' | '+' | '?'          (greedy; no lazy forms)
 * atom      := '.'                       any character
 *            | '^'                       start-of-text anchor
 *            | '$'                       end-of-text anchor
 *            | '[' '^'? item* ']'        character class
 *            | '\' PUNCT                 the literal PUNCT (non-alphanumeric)
 *            | CHAR                      itself
 * item      := CHAR | CHAR '-' CHAR      a member or an inclusive range
 * }</pre>
 *
 * <p>Deliberately <b>absent</b>: alternation, groups, backreferences, lazy
 * quantifiers, and the {@code \d}/{@code \w}/{@code \s} shorthands. Each is
 * either a source of cross-engine disagreement or needs machinery (capture
 * state, Unicode class tables) that nine hand-written ports should not each be
 * carrying.
 *
 * <p>Absent constructs are handled two different ways, and the line between them
 * is whether a literal reading is plausible:
 *
 * <ul>
 *   <li>{@code (}, {@code )}, {@code |}, <code>{</code>, <code>}</code> are
 *       <b>ordinary literals</b>. Text genuinely contains parentheses, so a
 *       pattern matching them must stay writable.
 *   <li>{@code \} + an ASCII letter or digit is <b>a compile error</b>. That is
 *       precisely where {@code \d} {@code \w} {@code \s} {@code \b} {@code \n}
 *       {@code \1} live, and none has a literal reading anyone wants — treating
 *       {@code slip\w+} as "slip then one or more {@code w}" would match nothing
 *       while reporting no error.
 * </ul>
 *
 * <p>Anchors bind to the whole text, never to a line: the values being searched
 * are section values, and a multiline mode would be a second dialect to agree
 * on.
 *
 * <h2>Matching semantics</h2>
 *
 * <p>Greedy backtracking, leftmost match wins. {@link #allMatches} scans start
 * offsets left to right; a match of length {@code L > 0} resumes the scan at its
 * end, an empty match advances one character — the same non-overlapping rule
 * Dart's {@code RegExp.allMatches} uses, stated here so the other eight do not
 * have to infer it.
 *
 * <p>Matching walks <b>UTF-16 code units</b> ({@link String#charAt}), the same
 * unit Dart's {@code String.codeUnits} yields — not code points. A non-BMP
 * character is therefore two units to {@code .}, exactly as in the reference.
 *
 * <p>Case-insensitive matching folds <b>ASCII only</b> ({@code A}–{@code Z} ↔
 * {@code a}–{@code z}). Full Unicode case folding differs between the nine
 * languages' standard libraries and would reintroduce exactly the divergence
 * this module removes.
 */
public final class SomTextPattern {
  private static final char DOT = '.';
  private static final char CARET = '^';
  private static final char DOLLAR = '$';
  private static final char BACKSLASH = '\\';
  private static final char OPEN_BRACKET = '[';
  private static final char CLOSE_BRACKET = ']';
  private static final char STAR = '*';
  private static final char PLUS = '+';
  private static final char QUESTION = '?';
  private static final char DASH = '-';
  private static final char UPPER_A = 'A';
  private static final char UPPER_Z = 'Z';
  private static final char LOWER_A = 'a';
  private static final char LOWER_Z = 'z';
  private static final char ZERO = '0';
  private static final char NINE = '9';

  /** What a single {@link Term} matches. */
  private enum AtomKind {
    LITERAL,
    ANY,
    START_ANCHOR,
    END_ANCHOR,
    CHAR_CLASS
  }

  /** How many times a {@link Term}'s atom may repeat. */
  private enum Repeat {
    ONE,
    ZERO_OR_ONE,
    ZERO_OR_MORE,
    ONE_OR_MORE
  }

  /** One inclusive {@code [lo, hi]} code-unit range inside a character class. */
  private static final class Range {
    final char lo;
    final char hi;

    Range(char lo, char hi) {
      this.lo = lo;
      this.hi = hi;
    }
  }

  /** One compiled atom plus its quantifier. */
  private static final class Term {
    final AtomKind kind;

    /** The code unit for {@link AtomKind#LITERAL}. */
    final char literal;

    /** The ranges for {@link AtomKind#CHAR_CLASS}. */
    final List<Range> ranges;

    /** Whether a {@link AtomKind#CHAR_CLASS} is negated ({@code [^…]}). */
    final boolean negated;

    final Repeat repeat;

    Term(AtomKind kind, char literal, List<Range> ranges, boolean negated, Repeat repeat) {
      this.kind = kind;
      this.literal = literal;
      this.ranges = ranges;
      this.negated = negated;
      this.repeat = repeat;
    }

    Term withRepeat(Repeat r) {
      return new Term(kind, literal, ranges, negated, r);
    }

    /**
     * Whether an anchor can carry a quantifier — it cannot; {@code ^*} is
     * meaningless and is far more likely to be a typo than an intent.
     */
    boolean isAnchor() {
      return kind == AtomKind.START_ANCHOR || kind == AtomKind.END_ANCHOR;
    }
  }

  /** A parsed character class plus the offset just past its closing {@code ]}. */
  private static final class ParsedClass {
    final Term term;
    final int next;

    ParsedClass(Term term, int next) {
      this.term = term;
      this.next = next;
    }
  }

  private final List<Term> terms;
  private final boolean caseInsensitive;

  private SomTextPattern(List<Term> terms, boolean caseInsensitive) {
    this.terms = terms;
    this.caseInsensitive = caseInsensitive;
  }

  /**
   * A case-sensitive pattern matching {@code text} as a plain, uninterpreted
   * substring.
   */
  public static SomTextPattern literal(String text) {
    return literal(text, false);
  }

  /**
   * A pattern matching {@code text} as a plain, uninterpreted substring — every
   * character is a literal, including {@code .} {@code *} {@code [} and the rest.
   */
  public static SomTextPattern literal(String text, boolean caseInsensitive) {
    List<Term> terms = new ArrayList<>();
    for (int i = 0; i < text.length(); i++) {
      terms.add(new Term(AtomKind.LITERAL, text.charAt(i), emptyRanges(), false, Repeat.ONE));
    }
    return new SomTextPattern(terms, caseInsensitive);
  }

  /** Compiles {@code source} against the subset grammar, case-sensitively. */
  public static SomTextPattern compile(String source) {
    return compile(source, false);
  }

  /**
   * Compiles {@code source} against the subset grammar.
   *
   * <p>Throws {@link SomPatternError} when {@code source} is not in the grammar:
   * an unterminated or reversed character class, a trailing {@code \}, or a
   * quantifier with nothing to quantify.
   */
  public static SomTextPattern compile(String source, boolean caseInsensitive) {
    char[] units = source.toCharArray();
    List<Term> terms = new ArrayList<>();

    int i = 0;
    while (i < units.length) {
      char ch = units[i];
      Term term;
      switch (ch) {
        case DOT:
          term = new Term(AtomKind.ANY, '\0', emptyRanges(), false, Repeat.ONE);
          i++;
          break;
        case CARET:
          term = new Term(AtomKind.START_ANCHOR, '\0', emptyRanges(), false, Repeat.ONE);
          i++;
          break;
        case DOLLAR:
          term = new Term(AtomKind.END_ANCHOR, '\0', emptyRanges(), false, Repeat.ONE);
          i++;
          break;
        case BACKSLASH:
          if (i + 1 >= units.length) {
            throw bad(source, "pattern ends with a dangling escape");
          }
          rejectClassEscape(source, units[i + 1]);
          term = new Term(AtomKind.LITERAL, units[i + 1], emptyRanges(), false, Repeat.ONE);
          i += 2;
          break;
        case OPEN_BRACKET: {
          ParsedClass parsed = parseClass(source, units, i);
          term = parsed.term;
          i = parsed.next;
          break;
        }
        case STAR:
        case PLUS:
        case QUESTION:
          throw bad(
              source, "quantifier \"" + ch + "\" at offset " + i + " has nothing to repeat");
        default:
          term = new Term(AtomKind.LITERAL, ch, emptyRanges(), false, Repeat.ONE);
          i++;
          break;
      }

      if (i < units.length) {
        Repeat repeat = Repeat.ONE;
        switch (units[i]) {
          case STAR:
            repeat = Repeat.ZERO_OR_MORE;
            break;
          case PLUS:
            repeat = Repeat.ONE_OR_MORE;
            break;
          case QUESTION:
            repeat = Repeat.ZERO_OR_ONE;
            break;
          default:
            break;
        }
        if (repeat != Repeat.ONE) {
          if (term.isAnchor()) {
            throw bad(
                source,
                "anchor \"" + ch + "\" at offset " + i + " cannot carry a quantifier");
          }
          term = term.withRepeat(repeat);
          i++;
        }
      }
      terms.add(term);
    }
    return new SomTextPattern(terms, caseInsensitive);
  }

  /** Every non-overlapping match in {@code text}, left to right. */
  public List<SpecMatchSpan> allMatches(String text) {
    char[] units = text.toCharArray();
    List<SpecMatchSpan> spans = new ArrayList<>();
    int start = 0;
    while (start <= units.length) {
      int end = matchAt(units, 0, start);
      if (end < 0) {
        start++;
        continue;
      }
      spans.add(new SpecMatchSpan(start, end));
      // Non-overlapping: resume past the match, but never stand still.
      start = end > start ? end : start + 1;
    }
    return spans;
  }

  /** Whether {@code text} contains at least one match. */
  public boolean hasMatch(String text) {
    return !allMatches(text).isEmpty();
  }

  /**
   * Matches {@link #terms} from {@code termIndex} against {@code units} starting
   * at {@code at}, returning the end offset of the match or {@code -1}. Greedy
   * with backtracking: a repeated atom consumes as much as it can, then gives
   * back one character at a time until the remainder of the pattern fits.
   */
  private int matchAt(char[] units, int termIndex, int at) {
    if (termIndex == terms.size()) {
      return at;
    }
    Term term = terms.get(termIndex);

    switch (term.kind) {
      case START_ANCHOR:
        return at == 0 ? matchAt(units, termIndex + 1, at) : -1;
      case END_ANCHOR:
        return at == units.length ? matchAt(units, termIndex + 1, at) : -1;
      default:
        break; // literal / any / charClass fall through to the quantifier walk
    }

    switch (term.repeat) {
      case ONE:
        if (at < units.length && accepts(term, units[at])) {
          return matchAt(units, termIndex + 1, at + 1);
        }
        return -1;
      case ZERO_OR_ONE:
        if (at < units.length && accepts(term, units[at])) {
          int withOne = matchAt(units, termIndex + 1, at + 1);
          if (withOne >= 0) {
            return withOne;
          }
        }
        return matchAt(units, termIndex + 1, at);
      case ZERO_OR_MORE:
      case ONE_OR_MORE:
      default: {
        int minimum = term.repeat == Repeat.ONE_OR_MORE ? 1 : 0;
        int consumed = at;
        while (consumed < units.length && accepts(term, units[consumed])) {
          consumed++;
        }
        while (consumed - at >= minimum) {
          int rest = matchAt(units, termIndex + 1, consumed);
          if (rest >= 0) {
            return rest;
          }
          if (consumed == at) {
            break;
          }
          consumed--;
        }
        return -1;
      }
    }
  }

  private boolean accepts(Term term, char unit) {
    switch (term.kind) {
      case ANY:
        return true;
      case LITERAL:
        return fold(unit) == fold(term.literal);
      case CHAR_CLASS: {
        boolean inside = false;
        for (Range r : term.ranges) {
          if (inRange(r, unit)) {
            inside = true;
            break;
          }
        }
        return term.negated ? !inside : inside;
      }
      default:
        return false; // anchors consume nothing
    }
  }

  /**
   * Whether {@code unit} falls in {@code r}, honouring ASCII-only case folding:
   * an insensitive {@code [a-z]} must also admit {@code Q}, which a single folded
   * comparison of the code unit cannot express (folding {@code Q} to {@code q}
   * would also make {@code [A-Z]} admit {@code q}, which is the same answer — but
   * folding the <i>bounds</i> would break {@code [A-z]}). So both cases of the
   * unit are tried against the raw range.
   */
  private boolean inRange(Range r, char unit) {
    if (unit >= r.lo && unit <= r.hi) {
      return true;
    }
    if (!caseInsensitive) {
      return false;
    }
    char swapped = swapCase(unit);
    return swapped != unit && swapped >= r.lo && swapped <= r.hi;
  }

  private char fold(char unit) {
    return caseInsensitive ? toLowerAscii(unit) : unit;
  }

  // --- compilation helpers --------------------------------------------------

  private static List<Range> emptyRanges() {
    return Collections.emptyList();
  }

  private static SomPatternError bad(String source, String why) {
    return new SomPatternError(source, why);
  }

  private static char toLowerAscii(char unit) {
    return (unit >= UPPER_A && unit <= UPPER_Z) ? (char) (unit + 0x20) : unit;
  }

  private static char swapCase(char unit) {
    if (unit >= UPPER_A && unit <= UPPER_Z) {
      return (char) (unit + 0x20);
    }
    if (unit >= LOWER_A && unit <= LOWER_Z) {
      return (char) (unit - 0x20);
    }
    return unit;
  }

  /**
   * Rejects {@code \} followed by an ASCII letter or digit.
   *
   * <p>Every character class shorthand other dialects define — {@code \d}
   * {@code \w} {@code \s} {@code \b} {@code \n} {@code \1} — lives in exactly
   * this space, and none of them has a literal reading anyone intends: nobody
   * writes {@code \w} meaning the letter {@code w}. Accepting them as literals
   * would make {@code slip\w+} quietly mean "slip, then one or more {@code w}",
   * which matches nothing and reports no error. Escapes of <i>non</i>
   * -alphanumerics stay legal, so {@code \.} {@code \[} {@code \(} still write
   * those characters literally.
   */
  private static void rejectClassEscape(String source, char escaped) {
    boolean isAlpha =
        (escaped >= UPPER_A && escaped <= UPPER_Z) || (escaped >= LOWER_A && escaped <= LOWER_Z);
    boolean isDigit = escaped >= ZERO && escaped <= NINE;
    if (!isAlpha && !isDigit) {
      return;
    }
    throw bad(
        source,
        "escape \"\\"
            + escaped
            + "\" is outside the portable subset — it has no character-class shorthands, and "
            + "reading it as a literal \""
            + escaped
            + "\" would not be what was meant");
  }

  /** Parses the character class starting at {@code units[open]} (which is {@code [}). */
  private static ParsedClass parseClass(String source, char[] units, int open) {
    int i = open + 1;
    boolean negated = false;
    if (i < units.length && units[i] == CARET) {
      negated = true;
      i++;
    }
    List<Range> ranges = new ArrayList<>();
    // A `]` immediately after `[` (or `[^`) is a literal `]`, the POSIX rule —
    // adopted because the alternative is an empty class, which can never match
    // and is therefore never what was meant.
    boolean first = true;
    while (i < units.length && (units[i] != CLOSE_BRACKET || first)) {
      first = false;
      char lo = units[i];
      if (lo == BACKSLASH) {
        if (i + 1 >= units.length) {
          throw bad(source, "dangling escape inside a character class");
        }
        rejectClassEscape(source, units[i + 1]);
        lo = units[i + 1];
        i += 2;
      } else {
        i++;
      }
      // `-` is a range only between two members; trailing `-` is a literal.
      if (i + 1 < units.length && units[i] == DASH && units[i + 1] != CLOSE_BRACKET) {
        char hi = units[i + 1];
        int step = 2;
        if (hi == BACKSLASH) {
          if (i + 2 >= units.length) {
            throw bad(source, "dangling escape inside a character class");
          }
          rejectClassEscape(source, units[i + 2]);
          hi = units[i + 2];
          step = 3;
        }
        if (hi < lo) {
          throw bad(
              source, "character class range \"" + lo + "-" + hi + "\" runs backwards");
        }
        ranges.add(new Range(lo, hi));
        i += step;
      } else {
        ranges.add(new Range(lo, lo));
      }
    }
    if (i >= units.length) {
      throw bad(source, "character class opened at " + open + " is never closed");
    }
    return new ParsedClass(
        new Term(AtomKind.CHAR_CLASS, '\0', ranges, negated, Repeat.ONE), i + 1);
  }
}
