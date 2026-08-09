/// The **portable text-pattern subset** the `text` dimension of a spec query
/// matches with (`som_multiplatform_spec_model.md` §9).
///
/// ## Why this exists rather than each language's own regex
///
/// The query surface reports `matchSpans` — byte offsets into the matched
/// string — and those spans are part of the nine-language contract. Delegating
/// to each language's regex engine would make that contract unkeepable twice
/// over:
///
///   * **Two runtimes have no regex to delegate to.** `tom_som_rust_runtime` is
///     std-only by charter and `tom_som_c_runtime` is dependency-free; both
///     would need a hand-rolled matcher regardless. Native-regex-elsewhere
///     therefore does not remove the work, it only makes there be *two*
///     implementations of the same semantics instead of one.
///   * **The engines disagree where it matters.** Go's `regexp` is RE2
///     (leftmost-longest for alternation), Dart/JS/Java/Python backtrack
///     (leftmost-first); case folding is Unicode-aware in some and not others.
///     A corpus could pin only the intersection, leaving every port's behaviour
///     *outside* the corpus silently divergent.
///
/// So the matcher is one algorithm, transcribed into all nine runtimes. Equal
/// spans follow from equal code rather than from a hope about two libraries.
///
/// ## The grammar
///
/// ```text
/// pattern   := term*
/// term      := atom quantifier?
/// quantifier:= '*' | '+' | '?'          (greedy; no lazy forms)
/// atom      := '.'                       any character
///            | '^'                       start-of-text anchor
///            | '$'                       end-of-text anchor
///            | '[' '^'? item* ']'        character class
///            | '\' PUNCT                 the literal PUNCT (non-alphanumeric)
///            | CHAR                      itself
/// item      := CHAR | CHAR '-' CHAR      a member or an inclusive range
/// ```
///
/// Deliberately **absent**: alternation, groups, backreferences, lazy
/// quantifiers, and the `\d`/`\w`/`\s` shorthands. Each is either a source of
/// cross-engine disagreement or needs machinery (capture state, Unicode class
/// tables) that nine hand-written ports should not each be carrying.
///
/// Absent constructs are handled two different ways, and the line between them
/// is whether a literal reading is plausible:
///
///   * `(`, `)`, `|`, `{`, `}` are **ordinary literals**. Text genuinely
///     contains parentheses, so a pattern matching them must stay writable.
///   * `\` + an ASCII letter or digit is **a compile error**. That is precisely
///     where `\d` `\w` `\s` `\b` `\n` `\1` live, and none has a literal reading
///     anyone wants — treating `slip\w+` as "slip then one or more `w`" would
///     match nothing while reporting no error.
///
/// Anchors bind to the whole text, never to a line: the values being searched
/// are section values, and a multiline mode would be a second dialect to agree
/// on.
///
/// ## Matching semantics
///
/// Greedy backtracking, leftmost match wins. [allMatches] scans start offsets
/// left to right; a match of length `L > 0` resumes the scan at its end, an
/// empty match advances one character — the same non-overlapping rule Dart's
/// `RegExp.allMatches` uses, stated here so the other eight do not have to
/// infer it.
///
/// Case-insensitive matching folds **ASCII only** (`A`–`Z` ↔ `a`–`z`). Full
/// Unicode case folding differs between the nine languages' standard libraries
/// and would reintroduce exactly the divergence this module removes.
library;

/// A `[start, end)` half-open span within a matched string — the offsets a
/// pattern hit, surfaced on `SpecQueryMatch.matchSpans`.
class SpecMatchSpan {
  /// Inclusive start offset into the matched string.
  final int start;

  /// Exclusive end offset into the matched string.
  final int end;

  const SpecMatchSpan(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      other is SpecMatchSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SpecMatchSpan($start, $end)';
}

/// A pattern that is not in the [SomTextPattern] grammar.
///
/// Raised at *compile* time rather than silently matching nothing, so a caller
/// that mistyped a pattern learns that instead of reading an empty result as
/// "no hits".
class SomPatternError implements Exception {
  /// The offending pattern source.
  final String pattern;

  /// What is wrong with it.
  final String message;

  const SomPatternError(this.pattern, this.message);

  @override
  String toString() => 'SomPatternError("$pattern"): $message';
}

/// What a single [_Term] matches.
enum _AtomKind { literal, any, startAnchor, endAnchor, charClass }

/// How many times a [_Term]'s atom may repeat.
enum _Repeat { one, zeroOrOne, zeroOrMore, oneOrMore }

/// One inclusive `[lo, hi]` code-unit range inside a character class.
class _Range {
  final int lo;
  final int hi;
  const _Range(this.lo, this.hi);
}

/// One compiled atom plus its quantifier.
class _Term {
  final _AtomKind kind;

  /// The code unit for [_AtomKind.literal].
  final int literal;

  /// The ranges for [_AtomKind.charClass].
  final List<_Range> ranges;

  /// Whether a [_AtomKind.charClass] is negated (`[^…]`).
  final bool negated;

  final _Repeat repeat;

  const _Term({
    required this.kind,
    this.literal = 0,
    this.ranges = const [],
    this.negated = false,
    this.repeat = _Repeat.one,
  });

  _Term withRepeat(_Repeat r) => _Term(
        kind: kind,
        literal: literal,
        ranges: ranges,
        negated: negated,
        repeat: r,
      );

  /// Whether an anchor can carry a quantifier — it cannot; `^*` is meaningless
  /// and is far more likely to be a typo than an intent.
  bool get isAnchor =>
      kind == _AtomKind.startAnchor || kind == _AtomKind.endAnchor;
}

/// A compiled pattern over the portable subset described in the library
/// comment. Compile once with [SomTextPattern.compile] (or
/// [SomTextPattern.literal] for a plain substring) and match with [allMatches].
class SomTextPattern {
  final List<_Term> _terms;
  final bool _caseInsensitive;

  const SomTextPattern._(this._terms, this._caseInsensitive);

  /// A pattern matching [text] as a plain, uninterpreted substring — every
  /// character is a literal, including `.` `*` `[` and the rest.
  factory SomTextPattern.literal(String text, {bool caseInsensitive = false}) =>
      SomTextPattern._(
        [
          for (final unit in text.codeUnits)
            _Term(kind: _AtomKind.literal, literal: unit),
        ],
        caseInsensitive,
      );

  /// Compiles [source] against the subset grammar.
  ///
  /// Throws [SomPatternError] when [source] is not in the grammar: an
  /// unterminated or reversed character class, a trailing `\`, or a quantifier
  /// with nothing to quantify.
  factory SomTextPattern.compile(String source,
      {bool caseInsensitive = false}) {
    final units = source.codeUnits;
    final terms = <_Term>[];

    Never bad(String why) => throw SomPatternError(source, why);

    var i = 0;
    while (i < units.length) {
      final ch = units[i];
      _Term term;
      switch (ch) {
        case _kDot:
          term = const _Term(kind: _AtomKind.any);
          i++;
        case _kCaret:
          term = const _Term(kind: _AtomKind.startAnchor);
          i++;
        case _kDollar:
          term = const _Term(kind: _AtomKind.endAnchor);
          i++;
        case _kBackslash:
          if (i + 1 >= units.length) {
            bad('pattern ends with a dangling escape');
          }
          _rejectClassEscape(units[i + 1], bad);
          term = _Term(kind: _AtomKind.literal, literal: units[i + 1]);
          i += 2;
        case _kOpenBracket:
          final parsed = _parseClass(units, i, bad);
          term = parsed.term;
          i = parsed.next;
        case _kStar:
        case _kPlus:
        case _kQuestion:
          bad('quantifier "${String.fromCharCode(ch)}" at offset $i has '
              'nothing to repeat');
        default:
          term = _Term(kind: _AtomKind.literal, literal: ch);
          i++;
      }

      if (i < units.length) {
        final repeat = switch (units[i]) {
          _kStar => _Repeat.zeroOrMore,
          _kPlus => _Repeat.oneOrMore,
          _kQuestion => _Repeat.zeroOrOne,
          _ => _Repeat.one,
        };
        if (repeat != _Repeat.one) {
          if (term.isAnchor) {
            bad('anchor "${String.fromCharCode(ch)}" at offset $i cannot '
                'carry a quantifier');
          }
          term = term.withRepeat(repeat);
          i++;
        }
      }
      terms.add(term);
    }
    return SomTextPattern._(terms, caseInsensitive);
  }

  /// Every non-overlapping match in [text], left to right.
  List<SpecMatchSpan> allMatches(String text) {
    final units = text.codeUnits;
    final spans = <SpecMatchSpan>[];
    var start = 0;
    while (start <= units.length) {
      final end = _matchAt(units, 0, start);
      if (end < 0) {
        start++;
        continue;
      }
      spans.add(SpecMatchSpan(start, end));
      // Non-overlapping: resume past the match, but never stand still.
      start = end > start ? end : start + 1;
    }
    return spans;
  }

  /// Whether [text] contains at least one match.
  bool hasMatch(String text) => allMatches(text).isNotEmpty;

  /// Matches [_terms] from [termIndex] against [units] starting at [at],
  /// returning the end offset of the match or `-1`. Greedy with backtracking:
  /// a repeated atom consumes as much as it can, then gives back one character
  /// at a time until the remainder of the pattern fits.
  int _matchAt(List<int> units, int termIndex, int at) {
    if (termIndex == _terms.length) return at;
    final term = _terms[termIndex];

    switch (term.kind) {
      case _AtomKind.startAnchor:
        return at == 0 ? _matchAt(units, termIndex + 1, at) : -1;
      case _AtomKind.endAnchor:
        return at == units.length ? _matchAt(units, termIndex + 1, at) : -1;
      case _AtomKind.literal:
      case _AtomKind.any:
      case _AtomKind.charClass:
        break;
    }

    switch (term.repeat) {
      case _Repeat.one:
        if (at < units.length && _accepts(term, units[at])) {
          return _matchAt(units, termIndex + 1, at + 1);
        }
        return -1;
      case _Repeat.zeroOrOne:
        if (at < units.length && _accepts(term, units[at])) {
          final withOne = _matchAt(units, termIndex + 1, at + 1);
          if (withOne >= 0) return withOne;
        }
        return _matchAt(units, termIndex + 1, at);
      case _Repeat.zeroOrMore:
      case _Repeat.oneOrMore:
        final minimum = term.repeat == _Repeat.oneOrMore ? 1 : 0;
        var consumed = at;
        while (consumed < units.length && _accepts(term, units[consumed])) {
          consumed++;
        }
        while (consumed - at >= minimum) {
          final rest = _matchAt(units, termIndex + 1, consumed);
          if (rest >= 0) return rest;
          if (consumed == at) break;
          consumed--;
        }
        return -1;
    }
  }

  bool _accepts(_Term term, int unit) {
    switch (term.kind) {
      case _AtomKind.any:
        return true;
      case _AtomKind.literal:
        return _fold(unit) == _fold(term.literal);
      case _AtomKind.charClass:
        var inside = false;
        for (final r in term.ranges) {
          if (_inRange(r, unit)) {
            inside = true;
            break;
          }
        }
        return term.negated ? !inside : inside;
      case _AtomKind.startAnchor:
      case _AtomKind.endAnchor:
        return false;
    }
  }

  /// Whether [unit] falls in [r], honouring ASCII-only case folding: an
  /// insensitive `[a-z]` must also admit `Q`, which a single folded comparison
  /// of the code unit cannot express (folding `Q` to `q` would also make
  /// `[A-Z]` admit `q`, which is the same answer — but folding the *bounds*
  /// would break `[A-z]`). So both cases of the unit are tried against the raw
  /// range.
  bool _inRange(_Range r, int unit) {
    if (unit >= r.lo && unit <= r.hi) return true;
    if (!_caseInsensitive) return false;
    final swapped = _swapCase(unit);
    return swapped != unit && swapped >= r.lo && swapped <= r.hi;
  }

  int _fold(int unit) => _caseInsensitive ? _toLowerAscii(unit) : unit;
}

// ---------------------------------------------------------------------------
// Compilation helpers
// ---------------------------------------------------------------------------

const int _kDot = 0x2E; // .
const int _kCaret = 0x5E; // ^
const int _kDollar = 0x24; // $
const int _kBackslash = 0x5C; // \
const int _kOpenBracket = 0x5B; // [
const int _kCloseBracket = 0x5D; // ]
const int _kStar = 0x2A; // *
const int _kPlus = 0x2B; // +
const int _kQuestion = 0x3F; // ?
const int _kDash = 0x2D; // -
const int _kUpperA = 0x41;
const int _kUpperZ = 0x5A;
const int _kLowerA = 0x61;
const int _kLowerZ = 0x7A;
const int _kZero = 0x30;
const int _kNine = 0x39;

int _toLowerAscii(int unit) =>
    (unit >= _kUpperA && unit <= _kUpperZ) ? unit + 0x20 : unit;

int _swapCase(int unit) {
  if (unit >= _kUpperA && unit <= _kUpperZ) return unit + 0x20;
  if (unit >= _kLowerA && unit <= _kLowerZ) return unit - 0x20;
  return unit;
}

/// Rejects `\` followed by an ASCII letter or digit.
///
/// Every character class shorthand other dialects define — `\d` `\w` `\s` `\b`
/// `\n` `\1` — lives in exactly this space, and none of them has a literal
/// reading anyone intends: nobody writes `\w` meaning the letter `w`. Accepting
/// them as literals would make `slip\w+` quietly mean "slip, then one or more
/// `w`", which matches nothing and reports no error. Escapes of
/// *non*-alphanumerics stay legal, so `\.` `\[` `\(` still write those
/// characters literally.
void _rejectClassEscape(int escaped, Never Function(String) bad) {
  final isAlpha = (escaped >= _kUpperA && escaped <= _kUpperZ) ||
      (escaped >= _kLowerA && escaped <= _kLowerZ);
  final isDigit = escaped >= _kZero && escaped <= _kNine;
  if (!isAlpha && !isDigit) return;
  bad('escape "\\${String.fromCharCode(escaped)}" is outside the portable '
      'subset — it has no character-class shorthands, and reading it as a '
      'literal "${String.fromCharCode(escaped)}" would not be what was meant');
}

/// Parses the character class starting at `units[open]` (which is `[`).
({_Term term, int next}) _parseClass(
  List<int> units,
  int open,
  Never Function(String) bad,
) {
  var i = open + 1;
  var negated = false;
  if (i < units.length && units[i] == _kCaret) {
    negated = true;
    i++;
  }
  final ranges = <_Range>[];
  // A `]` immediately after `[` (or `[^`) is a literal `]`, the POSIX rule —
  // adopted because the alternative is an empty class, which can never match
  // and is therefore never what was meant.
  var first = true;
  while (i < units.length && (units[i] != _kCloseBracket || first)) {
    first = false;
    var lo = units[i];
    if (lo == _kBackslash) {
      if (i + 1 >= units.length) bad('dangling escape inside a character class');
      _rejectClassEscape(units[i + 1], bad);
      lo = units[i + 1];
      i += 2;
    } else {
      i++;
    }
    // `-` is a range only between two members; trailing `-` is a literal.
    if (i + 1 < units.length &&
        units[i] == _kDash &&
        units[i + 1] != _kCloseBracket) {
      var hi = units[i + 1];
      var step = 2;
      if (hi == _kBackslash) {
        if (i + 2 >= units.length) {
          bad('dangling escape inside a character class');
        }
        _rejectClassEscape(units[i + 2], bad);
        hi = units[i + 2];
        step = 3;
      }
      if (hi < lo) {
        bad('character class range "${String.fromCharCode(lo)}-'
            '${String.fromCharCode(hi)}" runs backwards');
      }
      ranges.add(_Range(lo, hi));
      i += step;
    } else {
      ranges.add(_Range(lo, lo));
    }
  }
  if (i >= units.length) bad('character class opened at $open is never closed');
  return (
    term: _Term(
      kind: _AtomKind.charClass,
      ranges: ranges,
      negated: negated,
    ),
    next: i + 1,
  );
}
