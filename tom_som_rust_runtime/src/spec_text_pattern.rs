//! `spec_text_pattern` — the **portable text-pattern subset** the `text`
//! dimension of a spec query matches with (SOM §9), a faithful port of the Dart
//! `spec_text_pattern.dart`.
//!
//! ## Why this exists rather than each language's own regex
//!
//! The query surface reports `match_spans` — offsets into the matched string —
//! and those spans are part of the nine-language contract. Delegating to each
//! language's regex engine would make that contract unkeepable twice over:
//!
//!   * **Two runtimes have no regex to delegate to.** *This* crate is std-only
//!     by charter and `tom_som_c_runtime` is dependency-free; both would need a
//!     hand-rolled matcher regardless. Native-regex-elsewhere therefore does not
//!     remove the work, it only makes there be *two* implementations of the same
//!     semantics instead of one.
//!   * **The engines disagree where it matters.** Go's `regexp` is RE2
//!     (leftmost-longest for alternation), Dart/JS/Java/Python backtrack
//!     (leftmost-first); case folding is Unicode-aware in some and not others.
//!     A corpus could pin only the intersection, leaving every port's behaviour
//!     *outside* the corpus silently divergent.
//!
//! So the matcher is one algorithm, transcribed into all nine runtimes. Equal
//! spans follow from equal code rather than from a hope about two libraries.
//!
//! ## The grammar
//!
//! ```text
//! pattern   := term*
//! term      := atom quantifier?
//! quantifier:= '*' | '+' | '?'          (greedy; no lazy forms)
//! atom      := '.'                       any character
//!            | '^'                       start-of-text anchor
//!            | '$'                       end-of-text anchor
//!            | '[' '^'? item* ']'        character class
//!            | '\' PUNCT                 the literal PUNCT (non-alphanumeric)
//!            | CHAR                      itself
//! item      := CHAR | CHAR '-' CHAR      a member or an inclusive range
//! ```
//!
//! Deliberately **absent**: alternation, groups, backreferences, lazy
//! quantifiers, and the `\d`/`\w`/`\s` shorthands. Each is either a source of
//! cross-engine disagreement or needs machinery (capture state, Unicode class
//! tables) that nine hand-written ports should not each be carrying.
//!
//! Absent constructs are handled two different ways, and the line between them
//! is whether a literal reading is plausible:
//!
//!   * `(`, `)`, `|`, `{`, `}` are **ordinary literals**. Text genuinely
//!     contains parentheses, so a pattern matching them must stay writable.
//!   * `\` + an ASCII letter or digit is **a compile error**. That is precisely
//!     where `\d` `\w` `\s` `\b` `\n` `\1` live, and none has a literal reading
//!     anyone wants — treating `slip\w+` as "slip then one or more `w`" would
//!     match nothing while reporting no error.
//!
//! Anchors bind to the whole text, never to a line: the values being searched
//! are section values, and a multiline mode would be a second dialect to agree
//! on.
//!
//! ## Matching semantics
//!
//! Greedy backtracking, leftmost match wins. [`SomTextPattern::all_matches`]
//! scans start offsets left to right; a match of length `L > 0` resumes the scan
//! at its end, an empty match advances one character — the same non-overlapping
//! rule Dart's `RegExp.allMatches` uses, stated here so the other eight do not
//! have to infer it.
//!
//! Case-insensitive matching folds **ASCII only** (`A`–`Z` ↔ `a`–`z`). Full
//! Unicode case folding differs between the nine languages' standard libraries
//! and would reintroduce exactly the divergence this module removes.
//!
//! ## Offsets are UTF-16 code units
//!
//! The reference matches over Dart's `String.codeUnits`, so a span is a pair of
//! **UTF-16 code-unit** offsets and the committed corpus spans are in those
//! units. Rust's `str` is UTF-8 and its `char`s are scalar values, so neither
//! byte nor `char` indexing reproduces them once the text leaves ASCII (the
//! corpus fixture deliberately carries `spec §1.2`). Every entry point therefore
//! converts through [`str::encode_utf16`] and the matcher works on `&[u16]`.
//!
//! Rust has no exceptions, so the compile step returns `Result<_,
//! SomPatternError>` where the Dart reference throws — the crate's error idiom
//! (see [`spec_editor`](crate::spec_editor)).

/// A `[start, end)` half-open span within a matched string — the UTF-16
/// code-unit offsets a pattern hit, surfaced on
/// [`SpecQueryMatch::match_spans`](crate::spec_query::SpecQueryMatch).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SpecMatchSpan {
    /// Inclusive start offset into the matched string.
    pub start: usize,
    /// Exclusive end offset into the matched string.
    pub end: usize,
}

impl SpecMatchSpan {
    /// Builds a span from its two offsets.
    pub fn new(start: usize, end: usize) -> SpecMatchSpan {
        SpecMatchSpan { start, end }
    }
}

impl std::fmt::Display for SpecMatchSpan {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SpecMatchSpan({}, {})", self.start, self.end)
    }
}

/// A pattern that is not in the [`SomTextPattern`] grammar.
///
/// Reported at *compile* time rather than silently matching nothing, so a caller
/// that mistyped a pattern learns that instead of reading an empty result as
/// "no hits".
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SomPatternError {
    /// The offending pattern source.
    pub pattern: String,
    /// What is wrong with it.
    pub message: String,
}

impl std::fmt::Display for SomPatternError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SomPatternError(\"{}\"): {}", self.pattern, self.message)
    }
}

impl std::error::Error for SomPatternError {}

/// What a single [`Term`] matches.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum AtomKind {
    Literal,
    Any,
    StartAnchor,
    EndAnchor,
    CharClass,
}

/// How many times a [`Term`]'s atom may repeat.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Repeat {
    One,
    ZeroOrOne,
    ZeroOrMore,
    OneOrMore,
}

/// One inclusive `[lo, hi]` code-unit range inside a character class.
#[derive(Debug, Clone, Copy)]
struct Range {
    lo: u16,
    hi: u16,
}

/// One compiled atom plus its quantifier.
#[derive(Debug, Clone)]
struct Term {
    kind: AtomKind,
    /// The code unit for [`AtomKind::Literal`].
    literal: u16,
    /// The ranges for [`AtomKind::CharClass`].
    ranges: Vec<Range>,
    /// Whether an [`AtomKind::CharClass`] is negated (`[^…]`).
    negated: bool,
    repeat: Repeat,
}

impl Term {
    fn atom(kind: AtomKind) -> Term {
        Term {
            kind,
            literal: 0,
            ranges: Vec::new(),
            negated: false,
            repeat: Repeat::One,
        }
    }

    fn literal(unit: u16) -> Term {
        Term {
            literal: unit,
            ..Term::atom(AtomKind::Literal)
        }
    }

    /// Whether an anchor can carry a quantifier — it cannot; `^*` is meaningless
    /// and is far more likely to be a typo than an intent.
    fn is_anchor(&self) -> bool {
        self.kind == AtomKind::StartAnchor || self.kind == AtomKind::EndAnchor
    }
}

/// A compiled pattern over the portable subset described in the module comment.
/// Compile once with [`SomTextPattern::compile`] (or [`SomTextPattern::literal`]
/// for a plain substring) and match with [`SomTextPattern::all_matches`].
#[derive(Debug, Clone)]
pub struct SomTextPattern {
    terms: Vec<Term>,
    case_insensitive: bool,
}

impl SomTextPattern {
    /// A pattern matching `text` as a plain, uninterpreted substring — every
    /// character is a literal, including `.` `*` `[` and the rest.
    pub fn literal(text: &str, case_insensitive: bool) -> SomTextPattern {
        SomTextPattern {
            terms: text.encode_utf16().map(Term::literal).collect(),
            case_insensitive,
        }
    }

    /// Compiles `source` against the subset grammar.
    ///
    /// Returns [`SomPatternError`] when `source` is not in the grammar: an
    /// unterminated or reversed character class, a trailing `\`, an escape of an
    /// ASCII letter or digit, or a quantifier with nothing to quantify.
    pub fn compile(source: &str, case_insensitive: bool) -> Result<SomTextPattern, SomPatternError> {
        let units: Vec<u16> = source.encode_utf16().collect();
        let bad = |why: String| SomPatternError {
            pattern: source.to_string(),
            message: why,
        };
        let mut terms: Vec<Term> = Vec::new();

        let mut i = 0usize;
        while i < units.len() {
            let ch = units[i];
            let mut term = match ch {
                K_DOT => {
                    i += 1;
                    Term::atom(AtomKind::Any)
                }
                K_CARET => {
                    i += 1;
                    Term::atom(AtomKind::StartAnchor)
                }
                K_DOLLAR => {
                    i += 1;
                    Term::atom(AtomKind::EndAnchor)
                }
                K_BACKSLASH => {
                    if i + 1 >= units.len() {
                        return Err(bad("pattern ends with a dangling escape".to_string()));
                    }
                    reject_class_escape(units[i + 1]).map_err(&bad)?;
                    let t = Term::literal(units[i + 1]);
                    i += 2;
                    t
                }
                K_OPEN_BRACKET => {
                    let (t, next) = parse_class(&units, i).map_err(&bad)?;
                    i = next;
                    t
                }
                K_STAR | K_PLUS | K_QUESTION => {
                    return Err(bad(format!(
                        "quantifier \"{}\" at offset {} has nothing to repeat",
                        unit_str(ch),
                        i
                    )));
                }
                other => {
                    i += 1;
                    Term::literal(other)
                }
            };

            if i < units.len() {
                let repeat = match units[i] {
                    K_STAR => Repeat::ZeroOrMore,
                    K_PLUS => Repeat::OneOrMore,
                    K_QUESTION => Repeat::ZeroOrOne,
                    _ => Repeat::One,
                };
                if repeat != Repeat::One {
                    if term.is_anchor() {
                        // The Dart reference names the *atom* character here
                        // (`ch`), not the quantifier — kept verbatim.
                        return Err(bad(format!(
                            "anchor \"{}\" at offset {} cannot carry a quantifier",
                            unit_str(ch),
                            i
                        )));
                    }
                    term.repeat = repeat;
                    i += 1;
                }
            }
            terms.push(term);
        }
        Ok(SomTextPattern {
            terms,
            case_insensitive,
        })
    }

    /// Every non-overlapping match in `text`, left to right, as UTF-16
    /// code-unit spans.
    pub fn all_matches(&self, text: &str) -> Vec<SpecMatchSpan> {
        let units: Vec<u16> = text.encode_utf16().collect();
        let mut spans: Vec<SpecMatchSpan> = Vec::new();
        let mut start = 0usize;
        while start <= units.len() {
            let end = match self.match_at(&units, 0, start) {
                Some(end) => end,
                None => {
                    start += 1;
                    continue;
                }
            };
            spans.push(SpecMatchSpan::new(start, end));
            // Non-overlapping: resume past the match, but never stand still.
            start = if end > start { end } else { start + 1 };
        }
        spans
    }

    /// Whether `text` contains at least one match.
    pub fn has_match(&self, text: &str) -> bool {
        !self.all_matches(text).is_empty()
    }

    /// Matches `self.terms` from `term_index` against `units` starting at `at`,
    /// returning the end offset of the match or `None` (the reference's `-1`).
    /// Greedy with backtracking: a repeated atom consumes as much as it can,
    /// then gives back one character at a time until the remainder of the
    /// pattern fits.
    ///
    /// Deliberately still recursive, so the algorithm stays recognisably the
    /// same across the nine ports; the recursion depth is bounded by the number
    /// of pattern terms, not by the length of the text.
    fn match_at(&self, units: &[u16], term_index: usize, at: usize) -> Option<usize> {
        if term_index == self.terms.len() {
            return Some(at);
        }
        let term = &self.terms[term_index];

        match term.kind {
            AtomKind::StartAnchor => {
                return if at == 0 {
                    self.match_at(units, term_index + 1, at)
                } else {
                    None
                };
            }
            AtomKind::EndAnchor => {
                return if at == units.len() {
                    self.match_at(units, term_index + 1, at)
                } else {
                    None
                };
            }
            AtomKind::Literal | AtomKind::Any | AtomKind::CharClass => {}
        }

        match term.repeat {
            Repeat::One => {
                if at < units.len() && self.accepts(term, units[at]) {
                    return self.match_at(units, term_index + 1, at + 1);
                }
                None
            }
            Repeat::ZeroOrOne => {
                if at < units.len() && self.accepts(term, units[at]) {
                    if let Some(with_one) = self.match_at(units, term_index + 1, at + 1) {
                        return Some(with_one);
                    }
                }
                self.match_at(units, term_index + 1, at)
            }
            Repeat::ZeroOrMore | Repeat::OneOrMore => {
                let minimum = if term.repeat == Repeat::OneOrMore { 1 } else { 0 };
                let mut consumed = at;
                while consumed < units.len() && self.accepts(term, units[consumed]) {
                    consumed += 1;
                }
                while consumed - at >= minimum {
                    if let Some(rest) = self.match_at(units, term_index + 1, consumed) {
                        return Some(rest);
                    }
                    if consumed == at {
                        break;
                    }
                    consumed -= 1;
                }
                None
            }
        }
    }

    fn accepts(&self, term: &Term, unit: u16) -> bool {
        match term.kind {
            AtomKind::Any => true,
            AtomKind::Literal => self.fold(unit) == self.fold(term.literal),
            AtomKind::CharClass => {
                let mut inside = false;
                for r in &term.ranges {
                    if self.in_range(r, unit) {
                        inside = true;
                        break;
                    }
                }
                if term.negated {
                    !inside
                } else {
                    inside
                }
            }
            AtomKind::StartAnchor | AtomKind::EndAnchor => false,
        }
    }

    /// Whether `unit` falls in `r`, honouring ASCII-only case folding: an
    /// insensitive `[a-z]` must also admit `Q`, which a single folded comparison
    /// of the code unit cannot express (folding `Q` to `q` would also make
    /// `[A-Z]` admit `q`, which is the same answer — but folding the *bounds*
    /// would break `[A-z]`). So both cases of the unit are tried against the raw
    /// range.
    fn in_range(&self, r: &Range, unit: u16) -> bool {
        if unit >= r.lo && unit <= r.hi {
            return true;
        }
        if !self.case_insensitive {
            return false;
        }
        let swapped = swap_case(unit);
        swapped != unit && swapped >= r.lo && swapped <= r.hi
    }

    fn fold(&self, unit: u16) -> u16 {
        if self.case_insensitive {
            to_lower_ascii(unit)
        } else {
            unit
        }
    }
}

// ---------------------------------------------------------------------------
// Compilation helpers
// ---------------------------------------------------------------------------

const K_DOT: u16 = 0x2E; // .
const K_CARET: u16 = 0x5E; // ^
const K_DOLLAR: u16 = 0x24; // $
const K_BACKSLASH: u16 = 0x5C; // \
const K_OPEN_BRACKET: u16 = 0x5B; // [
const K_CLOSE_BRACKET: u16 = 0x5D; // ]
const K_STAR: u16 = 0x2A; // *
const K_PLUS: u16 = 0x2B; // +
const K_QUESTION: u16 = 0x3F; // ?
const K_DASH: u16 = 0x2D; // -
const K_UPPER_A: u16 = 0x41;
const K_UPPER_Z: u16 = 0x5A;
const K_LOWER_A: u16 = 0x61;
const K_LOWER_Z: u16 = 0x7A;
const K_ZERO: u16 = 0x30;
const K_NINE: u16 = 0x39;

fn to_lower_ascii(unit: u16) -> u16 {
    if (K_UPPER_A..=K_UPPER_Z).contains(&unit) {
        unit + 0x20
    } else {
        unit
    }
}

fn swap_case(unit: u16) -> u16 {
    if (K_UPPER_A..=K_UPPER_Z).contains(&unit) {
        return unit + 0x20;
    }
    if (K_LOWER_A..=K_LOWER_Z).contains(&unit) {
        return unit - 0x20;
    }
    unit
}

/// Renders one UTF-16 code unit for an error message (a lone surrogate becomes
/// the replacement character rather than panicking).
fn unit_str(unit: u16) -> String {
    String::from_utf16_lossy(&[unit])
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
fn reject_class_escape(escaped: u16) -> Result<(), String> {
    let is_alpha =
        (K_UPPER_A..=K_UPPER_Z).contains(&escaped) || (K_LOWER_A..=K_LOWER_Z).contains(&escaped);
    let is_digit = (K_ZERO..=K_NINE).contains(&escaped);
    if !is_alpha && !is_digit {
        return Ok(());
    }
    Err(format!(
        "escape \"\\{}\" is outside the portable subset — it has no \
character-class shorthands, and reading it as a literal \"{}\" would not be \
what was meant",
        unit_str(escaped),
        unit_str(escaped)
    ))
}

/// Parses the character class starting at `units[open]` (which is `[`),
/// returning the compiled term and the offset just past its `]`.
fn parse_class(units: &[u16], open: usize) -> Result<(Term, usize), String> {
    let mut i = open + 1;
    let mut negated = false;
    if i < units.len() && units[i] == K_CARET {
        negated = true;
        i += 1;
    }
    let mut ranges: Vec<Range> = Vec::new();
    // A `]` immediately after `[` (or `[^`) is a literal `]`, the POSIX rule —
    // adopted because the alternative is an empty class, which can never match
    // and is therefore never what was meant.
    let mut first = true;
    while i < units.len() && (units[i] != K_CLOSE_BRACKET || first) {
        first = false;
        let lo;
        if units[i] == K_BACKSLASH {
            if i + 1 >= units.len() {
                return Err("dangling escape inside a character class".to_string());
            }
            reject_class_escape(units[i + 1])?;
            lo = units[i + 1];
            i += 2;
        } else {
            lo = units[i];
            i += 1;
        }
        // `-` is a range only between two members; trailing `-` is a literal.
        if i + 1 < units.len() && units[i] == K_DASH && units[i + 1] != K_CLOSE_BRACKET {
            let mut hi = units[i + 1];
            let mut step = 2;
            if hi == K_BACKSLASH {
                if i + 2 >= units.len() {
                    return Err("dangling escape inside a character class".to_string());
                }
                reject_class_escape(units[i + 2])?;
                hi = units[i + 2];
                step = 3;
            }
            if hi < lo {
                return Err(format!(
                    "character class range \"{}-{}\" runs backwards",
                    unit_str(lo),
                    unit_str(hi)
                ));
            }
            ranges.push(Range { lo, hi });
            i += step;
        } else {
            ranges.push(Range { lo, hi: lo });
        }
    }
    if i >= units.len() {
        return Err(format!(
            "character class opened at {} is never closed",
            open
        ));
    }
    Ok((
        Term {
            ranges,
            negated,
            ..Term::atom(AtomKind::CharClass)
        },
        i + 1,
    ))
}
