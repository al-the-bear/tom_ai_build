/**
 * The **portable text-pattern subset** the `text` dimension of a spec query
 * matches with (`som_multiplatform_spec_model.md` §9) — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_text_pattern.dart`.
 *
 * ## Why this exists rather than each language's own regex
 *
 * The query surface reports `matchSpans` — offsets into the matched string —
 * and those spans are part of the nine-language contract. Delegating to each
 * language's regex engine would make that contract unkeepable twice over:
 *
 *   * **Two runtimes have no regex to delegate to.** `tom_som_rust_runtime` is
 *     std-only by charter and `tom_som_c_runtime` is dependency-free; both
 *     would need a hand-rolled matcher regardless. Native-regex-elsewhere
 *     therefore does not remove the work, it only makes there be *two*
 *     implementations of the same semantics instead of one.
 *   * **The engines disagree where it matters.** Go's `regexp` is RE2
 *     (leftmost-longest for alternation), Dart/JS/Java/Python backtrack
 *     (leftmost-first); case folding is Unicode-aware in some and not others.
 *     A corpus could pin only the intersection, leaving every port's behaviour
 *     *outside* the corpus silently divergent.
 *
 * So the matcher is one algorithm, transcribed into all nine runtimes. Equal
 * spans follow from equal code rather than from a hope about two libraries.
 * That is also why this module uses no `RegExp`: the whole point is that the
 * platform engine is *not* consulted.
 *
 * ## The grammar
 *
 * ```text
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
 * ```
 *
 * Deliberately **absent**: alternation, groups, backreferences, lazy
 * quantifiers, and the `\d`/`\w`/`\s` shorthands. Each is either a source of
 * cross-engine disagreement or needs machinery (capture state, Unicode class
 * tables) that nine hand-written ports should not each be carrying.
 *
 * Absent constructs are handled two different ways, and the line between them
 * is whether a literal reading is plausible:
 *
 *   * `(`, `)`, `|`, `{`, `}` are **ordinary literals**. Text genuinely
 *     contains parentheses, so a pattern matching them must stay writable.
 *   * `\` + an ASCII letter or digit is **a compile error**. That is precisely
 *     where `\d` `\w` `\s` `\b` `\n` `\1` live, and none has a literal reading
 *     anyone wants — treating `slip\w+` as "slip then one or more `w`" would
 *     match nothing while reporting no error.
 *
 * Anchors bind to the whole text, never to a line: the values being searched
 * are section values, and a multiline mode would be a second dialect to agree
 * on.
 *
 * ## Matching semantics
 *
 * Greedy backtracking, leftmost match wins. {@link SomTextPattern.allMatches}
 * scans start offsets left to right; a match of length `L > 0` resumes the scan
 * at its end, an empty match advances one character — the same non-overlapping
 * rule Dart's `RegExp.allMatches` uses, stated here so the other eight do not
 * have to infer it.
 *
 * Offsets are **UTF-16 code units**, exactly as in Dart: a TypeScript string is
 * a UTF-16 sequence too, so `charCodeAt` / `.length` are the faithful
 * equivalents of Dart's `codeUnits`.
 *
 * Case-insensitive matching folds **ASCII only** (`A`–`Z` ↔ `a`–`z`). Full
 * Unicode case folding differs between the nine languages' standard libraries
 * and would reintroduce exactly the divergence this module removes.
 */

/**
 * A `[start, end)` half-open span within a matched string — the offsets a
 * pattern hit, surfaced on `SpecQueryMatch.matchSpans`.
 */
export class SpecMatchSpan {
  /** Inclusive start offset into the matched string. */
  readonly start: number;

  /** Exclusive end offset into the matched string. */
  readonly end: number;

  constructor(start: number, end: number) {
    this.start = start;
    this.end = end;
  }

  /** Value equality — Dart's `operator ==`, which TypeScript has no syntax for. */
  equals(other: SpecMatchSpan): boolean {
    return other.start === this.start && other.end === this.end;
  }

  toString(): string {
    return `SpecMatchSpan(${this.start}, ${this.end})`;
  }
}

/**
 * A pattern that is not in the {@link SomTextPattern} grammar.
 *
 * Raised at *compile* time rather than silently matching nothing, so a caller
 * that mistyped a pattern learns that instead of reading an empty result as
 * "no hits".
 */
export class SomPatternError extends Error {
  /** The offending pattern source. */
  pattern: string;

  constructor(pattern: string, message: string) {
    super(message);
    this.name = 'SomPatternError';
    this.pattern = pattern;
    // Restore the prototype chain across the ES5 `Error` boundary.
    Object.setPrototypeOf(this, SomPatternError.prototype);
  }

  toString(): string {
    return `SomPatternError("${this.pattern}"): ${this.message}`;
  }
}

/** What a single {@link _Term} matches. */
const _AtomKind = {
  LITERAL: 'literal',
  ANY: 'any',
  START_ANCHOR: 'startAnchor',
  END_ANCHOR: 'endAnchor',
  CHAR_CLASS: 'charClass',
} as const;

type _AtomKindValue = (typeof _AtomKind)[keyof typeof _AtomKind];

/** How many times a {@link _Term}'s atom may repeat. */
const _Repeat = {
  ONE: 'one',
  ZERO_OR_ONE: 'zeroOrOne',
  ZERO_OR_MORE: 'zeroOrMore',
  ONE_OR_MORE: 'oneOrMore',
} as const;

type _RepeatValue = (typeof _Repeat)[keyof typeof _Repeat];

/** One inclusive `[lo, hi]` code-unit range inside a character class. */
class _Range {
  readonly lo: number;
  readonly hi: number;

  constructor(lo: number, hi: number) {
    this.lo = lo;
    this.hi = hi;
  }
}

/** One compiled atom plus its quantifier. */
class _Term {
  readonly kind: _AtomKindValue;

  /** The code unit for {@link _AtomKind.LITERAL}. */
  readonly literal: number;

  /** The ranges for {@link _AtomKind.CHAR_CLASS}. */
  readonly ranges: _Range[];

  /** Whether a {@link _AtomKind.CHAR_CLASS} is negated (`[^…]`). */
  readonly negated: boolean;

  readonly repeat: _RepeatValue;

  constructor(props: {
    kind: _AtomKindValue;
    literal?: number;
    ranges?: _Range[];
    negated?: boolean;
    repeat?: _RepeatValue;
  }) {
    this.kind = props.kind;
    this.literal = props.literal !== undefined ? props.literal : 0;
    this.ranges = props.ranges !== undefined ? props.ranges : [];
    this.negated = props.negated !== undefined ? props.negated : false;
    this.repeat = props.repeat !== undefined ? props.repeat : _Repeat.ONE;
  }

  withRepeat(r: _RepeatValue): _Term {
    return new _Term({
      kind: this.kind,
      literal: this.literal,
      ranges: this.ranges,
      negated: this.negated,
      repeat: r,
    });
  }

  /**
   * Whether an anchor can carry a quantifier — it cannot; `^*` is meaningless
   * and is far more likely to be a typo than an intent.
   */
  get isAnchor(): boolean {
    return (
      this.kind === _AtomKind.START_ANCHOR || this.kind === _AtomKind.END_ANCHOR
    );
  }
}

/**
 * A compiled pattern over the portable subset described in the module comment.
 * Compile once with {@link SomTextPattern.compile} (or
 * {@link SomTextPattern.literal} for a plain substring) and match with
 * {@link SomTextPattern.allMatches}.
 */
export class SomTextPattern {
  private readonly _terms: _Term[];
  private readonly _caseInsensitive: boolean;

  private constructor(terms: _Term[], caseInsensitive: boolean) {
    this._terms = terms;
    this._caseInsensitive = caseInsensitive;
  }

  /**
   * A pattern matching `text` as a plain, uninterpreted substring — every
   * character is a literal, including `.` `*` `[` and the rest.
   */
  static literal(text: string, caseInsensitive = false): SomTextPattern {
    const terms: _Term[] = [];
    for (const unit of _codeUnits(text)) {
      terms.push(new _Term({ kind: _AtomKind.LITERAL, literal: unit }));
    }
    return new SomTextPattern(terms, caseInsensitive);
  }

  /**
   * Compiles `source` against the subset grammar.
   *
   * Throws {@link SomPatternError} when `source` is not in the grammar: an
   * unterminated or reversed character class, a trailing `\`, or a quantifier
   * with nothing to quantify.
   */
  static compile(source: string, caseInsensitive = false): SomTextPattern {
    const units = _codeUnits(source);
    const terms: _Term[] = [];

    // Annotated on the `const`, not just on the arrow: that is what makes
    // TypeScript treat a `bad(...)` call as unreachable-after, so the compiler
    // sees the same "this branch cannot continue" that Dart's `Never` gives.
    const bad: (why: string) => never = (why: string) => {
      throw new SomPatternError(source, why);
    };

    let i = 0;
    while (i < units.length) {
      const ch = units[i];
      let term: _Term;
      switch (ch) {
        case _K_DOT:
          term = new _Term({ kind: _AtomKind.ANY });
          i++;
          break;
        case _K_CARET:
          term = new _Term({ kind: _AtomKind.START_ANCHOR });
          i++;
          break;
        case _K_DOLLAR:
          term = new _Term({ kind: _AtomKind.END_ANCHOR });
          i++;
          break;
        case _K_BACKSLASH: {
          if (i + 1 >= units.length) {
            bad('pattern ends with a dangling escape');
          }
          _rejectClassEscape(units[i + 1], bad);
          term = new _Term({ kind: _AtomKind.LITERAL, literal: units[i + 1] });
          i += 2;
          break;
        }
        case _K_OPEN_BRACKET: {
          const parsed = _parseClass(units, i, bad);
          term = parsed.term;
          i = parsed.next;
          break;
        }
        case _K_STAR:
        case _K_PLUS:
        case _K_QUESTION:
          return bad(
            `quantifier "${String.fromCharCode(ch)}" at offset ${i} has ` +
              'nothing to repeat',
          );
        default:
          term = new _Term({ kind: _AtomKind.LITERAL, literal: ch });
          i++;
          break;
      }

      if (i < units.length) {
        let repeat: _RepeatValue;
        switch (units[i]) {
          case _K_STAR:
            repeat = _Repeat.ZERO_OR_MORE;
            break;
          case _K_PLUS:
            repeat = _Repeat.ONE_OR_MORE;
            break;
          case _K_QUESTION:
            repeat = _Repeat.ZERO_OR_ONE;
            break;
          default:
            repeat = _Repeat.ONE;
            break;
        }
        if (repeat !== _Repeat.ONE) {
          if (term.isAnchor) {
            // `ch` is the *atom's* character and `i` the quantifier's offset —
            // the Dart reference's wording, kept verbatim so the nine runtimes
            // report the same sentence.
            bad(
              `anchor "${String.fromCharCode(ch)}" at offset ${i} cannot ` +
                'carry a quantifier',
            );
          }
          term = term.withRepeat(repeat);
          i++;
        }
      }
      terms.push(term);
    }
    return new SomTextPattern(terms, caseInsensitive);
  }

  /** Every non-overlapping match in `text`, left to right. */
  allMatches(text: string): SpecMatchSpan[] {
    const units = _codeUnits(text);
    const spans: SpecMatchSpan[] = [];
    let start = 0;
    while (start <= units.length) {
      const end = this._matchAt(units, 0, start);
      if (end < 0) {
        start++;
        continue;
      }
      spans.push(new SpecMatchSpan(start, end));
      // Non-overlapping: resume past the match, but never stand still.
      start = end > start ? end : start + 1;
    }
    return spans;
  }

  /** Whether `text` contains at least one match. */
  hasMatch(text: string): boolean {
    return this.allMatches(text).length > 0;
  }

  /**
   * Matches `_terms` from `termIndex` against `units` starting at `at`,
   * returning the end offset of the match or `-1`. Greedy with backtracking:
   * a repeated atom consumes as much as it can, then gives back one character
   * at a time until the remainder of the pattern fits.
   */
  private _matchAt(units: number[], termIndex: number, at: number): number {
    if (termIndex === this._terms.length) {
      return at;
    }
    const term = this._terms[termIndex];

    switch (term.kind) {
      case _AtomKind.START_ANCHOR:
        return at === 0 ? this._matchAt(units, termIndex + 1, at) : -1;
      case _AtomKind.END_ANCHOR:
        return at === units.length ? this._matchAt(units, termIndex + 1, at) : -1;
      default:
        break;
    }

    switch (term.repeat) {
      case _Repeat.ONE:
        if (at < units.length && this._accepts(term, units[at])) {
          return this._matchAt(units, termIndex + 1, at + 1);
        }
        return -1;
      case _Repeat.ZERO_OR_ONE: {
        if (at < units.length && this._accepts(term, units[at])) {
          const withOne = this._matchAt(units, termIndex + 1, at + 1);
          if (withOne >= 0) {
            return withOne;
          }
        }
        return this._matchAt(units, termIndex + 1, at);
      }
      default: {
        const minimum = term.repeat === _Repeat.ONE_OR_MORE ? 1 : 0;
        let consumed = at;
        while (consumed < units.length && this._accepts(term, units[consumed])) {
          consumed++;
        }
        while (consumed - at >= minimum) {
          const rest = this._matchAt(units, termIndex + 1, consumed);
          if (rest >= 0) {
            return rest;
          }
          if (consumed === at) {
            break;
          }
          consumed--;
        }
        return -1;
      }
    }
  }

  private _accepts(term: _Term, unit: number): boolean {
    switch (term.kind) {
      case _AtomKind.ANY:
        return true;
      case _AtomKind.LITERAL:
        return this._fold(unit) === this._fold(term.literal);
      case _AtomKind.CHAR_CLASS: {
        let inside = false;
        for (const r of term.ranges) {
          if (this._inRange(r, unit)) {
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
   * Whether `unit` falls in `r`, honouring ASCII-only case folding: an
   * insensitive `[a-z]` must also admit `Q`, which a single folded comparison
   * of the code unit cannot express (folding `Q` to `q` would also make
   * `[A-Z]` admit `q`, which is the same answer — but folding the *bounds*
   * would break `[A-z]`). So both cases of the unit are tried against the raw
   * range.
   */
  private _inRange(r: _Range, unit: number): boolean {
    if (unit >= r.lo && unit <= r.hi) {
      return true;
    }
    if (!this._caseInsensitive) {
      return false;
    }
    const swapped = _swapCase(unit);
    return swapped !== unit && swapped >= r.lo && swapped <= r.hi;
  }

  private _fold(unit: number): number {
    return this._caseInsensitive ? _toLowerAscii(unit) : unit;
  }
}

// ---------------------------------------------------------------------------
// Compilation helpers
// ---------------------------------------------------------------------------

const _K_DOT = 0x2e; // .
const _K_CARET = 0x5e; // ^
const _K_DOLLAR = 0x24; // $
const _K_BACKSLASH = 0x5c; // \
const _K_OPEN_BRACKET = 0x5b; // [
const _K_CLOSE_BRACKET = 0x5d; // ]
const _K_STAR = 0x2a; // *
const _K_PLUS = 0x2b; // +
const _K_QUESTION = 0x3f; // ?
const _K_DASH = 0x2d; // -
const _K_UPPER_A = 0x41;
const _K_UPPER_Z = 0x5a;
const _K_LOWER_A = 0x61;
const _K_LOWER_Z = 0x7a;
const _K_ZERO = 0x30;
const _K_NINE = 0x39;

/**
 * The UTF-16 code units of `s` — the direct equivalent of Dart's
 * `String.codeUnits`, which the matcher indexes into.
 */
function _codeUnits(s: string): number[] {
  const out: number[] = [];
  for (let i = 0; i < s.length; i++) {
    out.push(s.charCodeAt(i));
  }
  return out;
}

function _toLowerAscii(unit: number): number {
  return unit >= _K_UPPER_A && unit <= _K_UPPER_Z ? unit + 0x20 : unit;
}

function _swapCase(unit: number): number {
  if (unit >= _K_UPPER_A && unit <= _K_UPPER_Z) {
    return unit + 0x20;
  }
  if (unit >= _K_LOWER_A && unit <= _K_LOWER_Z) {
    return unit - 0x20;
  }
  return unit;
}

/**
 * Rejects `\` followed by an ASCII letter or digit.
 *
 * Every character class shorthand other dialects define — `\d` `\w` `\s` `\b`
 * `\n` `\1` — lives in exactly this space, and none of them has a literal
 * reading anyone intends: nobody writes `\w` meaning the letter `w`. Accepting
 * them as literals would make `slip\w+` quietly mean "slip, then one or more
 * `w`", which matches nothing and reports no error. Escapes of
 * *non*-alphanumerics stay legal, so `\.` `\[` `\(` still write those
 * characters literally.
 */
function _rejectClassEscape(escaped: number, bad: (why: string) => never): void {
  const isAlpha =
    (escaped >= _K_UPPER_A && escaped <= _K_UPPER_Z) ||
    (escaped >= _K_LOWER_A && escaped <= _K_LOWER_Z);
  const isDigit = escaped >= _K_ZERO && escaped <= _K_NINE;
  if (!isAlpha && !isDigit) {
    return;
  }
  bad(
    `escape "\\${String.fromCharCode(escaped)}" is outside the portable ` +
      'subset — it has no character-class shorthands, and reading it as a ' +
      `literal "${String.fromCharCode(escaped)}" would not be what was meant`,
  );
}

/** Parses the character class starting at `units[open]` (which is `[`). */
function _parseClass(
  units: number[],
  open: number,
  bad: (why: string) => never,
): { term: _Term; next: number } {
  let i = open + 1;
  let negated = false;
  if (i < units.length && units[i] === _K_CARET) {
    negated = true;
    i++;
  }
  const ranges: _Range[] = [];
  // A `]` immediately after `[` (or `[^`) is a literal `]`, the POSIX rule —
  // adopted because the alternative is an empty class, which can never match
  // and is therefore never what was meant.
  let first = true;
  while (i < units.length && (units[i] !== _K_CLOSE_BRACKET || first)) {
    first = false;
    let lo = units[i];
    if (lo === _K_BACKSLASH) {
      if (i + 1 >= units.length) {
        bad('dangling escape inside a character class');
      }
      _rejectClassEscape(units[i + 1], bad);
      lo = units[i + 1];
      i += 2;
    } else {
      i++;
    }
    // `-` is a range only between two members; trailing `-` is a literal.
    if (
      i + 1 < units.length &&
      units[i] === _K_DASH &&
      units[i + 1] !== _K_CLOSE_BRACKET
    ) {
      let hi = units[i + 1];
      let step = 2;
      if (hi === _K_BACKSLASH) {
        if (i + 2 >= units.length) {
          bad('dangling escape inside a character class');
        }
        _rejectClassEscape(units[i + 2], bad);
        hi = units[i + 2];
        step = 3;
      }
      if (hi < lo) {
        bad(
          `character class range "${String.fromCharCode(lo)}-` +
            `${String.fromCharCode(hi)}" runs backwards`,
        );
      }
      ranges.push(new _Range(lo, hi));
      i += step;
    } else {
      ranges.push(new _Range(lo, lo));
    }
  }
  if (i >= units.length) {
    bad(`character class opened at ${open} is never closed`);
  }
  return {
    term: new _Term({ kind: _AtomKind.CHAR_CLASS, ranges, negated }),
    next: i + 1,
  };
}
