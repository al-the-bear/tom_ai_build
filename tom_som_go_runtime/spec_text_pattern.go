package somruntime

// spec_text_pattern.go — the **portable text-pattern subset** the `text`
// dimension of a spec query matches with (`som_multiplatform_spec_model.md`
// §9), a faithful port of `tom_som_dart_runtime/lib/src/spec_text_pattern.dart`.
//
// # Why this exists rather than each language's own regex
//
// The query surface reports match spans — offsets into the matched string — and
// those spans are part of the nine-language contract. Delegating to each
// language's regex engine would make that contract unkeepable twice over:
//
//   - **Two runtimes have no regex to delegate to.** `tom_som_rust_runtime` is
//     std-only by charter and `tom_som_c_runtime` is dependency-free; both would
//     need a hand-rolled matcher regardless. Native-regex-elsewhere therefore
//     does not remove the work, it only makes there be *two* implementations of
//     the same semantics instead of one.
//   - **The engines disagree where it matters.** Go's own `regexp` is RE2
//     (leftmost-**longest** for alternation and repetition), while Dart / JS /
//     Java / Python backtrack (leftmost-**first**); case folding is
//     Unicode-aware in some and not others. A corpus could pin only the
//     intersection, leaving every port's behaviour *outside* the corpus silently
//     divergent.
//
// That second point is why this file does not import `regexp` even though Go
// has one in its standard library: RE2 would return different spans for the
// same pattern, and the spans are the contract. The matcher below is the Dart
// backtracking algorithm transcribed literally — equal spans follow from equal
// code rather than from a hope about two libraries.
//
// # Offsets are UTF-16 code units, not Go bytes or runes
//
// The reference matches over `String.codeUnits`, i.e. UTF-16 code units, and the
// committed spans are in those units. Indexing Go's `[]byte` (UTF-8) or `[]rune`
// (code points) would agree with Dart only for ASCII and diverge on the first
// non-ASCII character — and the corpus deliberately contains one (`spec §1.2`,
// where `§` is one UTF-16 unit but two UTF-8 bytes). So every string that takes
// part in matching is converted to `[]uint16` first (utf16Units), and all
// offsets are indices into that slice.
//
// # The grammar
//
//	pattern   := term*
//	term      := atom quantifier?
//	quantifier:= '*' | '+' | '?'          (greedy; no lazy forms)
//	atom      := '.'                       any character
//	           | '^'                       start-of-text anchor
//	           | '$'                       end-of-text anchor
//	           | '[' '^'? item* ']'        character class
//	           | '\' PUNCT                 the literal PUNCT (non-alphanumeric)
//	           | CHAR                      itself
//	item      := CHAR | CHAR '-' CHAR      a member or an inclusive range
//
// Deliberately **absent**: alternation, groups, backreferences, lazy
// quantifiers, and the `\d`/`\w`/`\s` shorthands. Each is either a source of
// cross-engine disagreement or needs machinery (capture state, Unicode class
// tables) that nine hand-written ports should not each be carrying.
//
// Absent constructs are handled two different ways, and the line between them is
// whether a literal reading is plausible:
//
//   - `(`, `)`, `|`, `{`, `}` are **ordinary literals**. Text genuinely contains
//     parentheses, so a pattern matching them must stay writable.
//   - `\` + an ASCII letter or digit is **a compile error**. That is precisely
//     where `\d` `\w` `\s` `\b` `\n` `\1` live, and none has a literal reading
//     anyone wants — treating `slip\w+` as "slip then one or more `w`" would
//     match nothing while reporting no error.
//
// Anchors bind to the whole text, never to a line: the values being searched are
// section values, and a multiline mode would be a second dialect to agree on.
//
// # Matching semantics
//
// Greedy backtracking, leftmost match wins. AllMatches scans start offsets left
// to right; a match of length `L > 0` resumes the scan at its end, an empty match
// advances one code unit — the same non-overlapping rule Dart's
// `RegExp.allMatches` uses, stated here so the other eight do not have to infer
// it.
//
// Case-insensitive matching folds **ASCII only** (`A`–`Z` ↔ `a`–`z`). Full
// Unicode case folding differs between the nine languages' standard libraries
// and would reintroduce exactly the divergence this module removes.

import "unicode/utf16"

// SpecMatchSpan is a `[start, end)` half-open span within a matched string — the
// offsets a pattern hit, surfaced on SpecQueryMatch.MatchSpans.
//
// Both offsets are **UTF-16 code-unit** indices (see the file comment), not Go
// byte offsets.
type SpecMatchSpan struct {
	// Start is the inclusive start offset into the matched string.
	Start int
	// End is the exclusive end offset into the matched string.
	End int
}

// SomPatternError reports a pattern that is not in the SomTextPattern grammar.
//
// Returned at *compile* time rather than silently matching nothing, so a caller
// that mistyped a pattern learns that instead of reading an empty result as "no
// hits".
type SomPatternError struct {
	// Pattern is the offending pattern source.
	Pattern string
	// Message says what is wrong with it.
	Message string
}

// Error implements the error interface.
func (e *SomPatternError) Error() string {
	return "SomPatternError(\"" + e.Pattern + "\"): " + e.Message
}

// What a single compiled term matches.
const (
	atomLiteral = iota
	atomAny
	atomStartAnchor
	atomEndAnchor
	atomCharClass
)

// How many times a term's atom may repeat.
const (
	repeatOne = iota
	repeatZeroOrOne
	repeatZeroOrMore
	repeatOneOrMore
)

// patternRange is one inclusive `[lo, hi]` code-unit range inside a character
// class.
type patternRange struct {
	lo uint16
	hi uint16
}

// patternTerm is one compiled atom plus its quantifier.
type patternTerm struct {
	kind int
	// literal is the code unit for atomLiteral.
	literal uint16
	// ranges are the members for atomCharClass.
	ranges []patternRange
	// negated marks an atomCharClass written `[^…]`.
	negated bool
	repeat  int
}

// isAnchor reports whether this term is an anchor — anchors cannot carry a
// quantifier; `^*` is meaningless and is far more likely to be a typo than an
// intent.
func (t patternTerm) isAnchor() bool {
	return t.kind == atomStartAnchor || t.kind == atomEndAnchor
}

// SomTextPattern is a compiled pattern over the portable subset described in the
// file comment. Compile once with CompileSomTextPattern (or
// NewSomTextPatternLiteral for a plain substring) and match with AllMatches.
type SomTextPattern struct {
	terms           []patternTerm
	caseInsensitive bool
}

// NewSomTextPatternLiteral builds a pattern matching text as a plain,
// uninterpreted substring — every character is a literal, including `.` `*` `[`
// and the rest. It cannot fail, so unlike CompileSomTextPattern it returns no
// error.
func NewSomTextPatternLiteral(text string, caseInsensitive bool) *SomTextPattern {
	units := utf16Units(text)
	terms := make([]patternTerm, 0, len(units))
	for _, unit := range units {
		terms = append(terms, patternTerm{kind: atomLiteral, literal: unit})
	}
	return &SomTextPattern{terms: terms, caseInsensitive: caseInsensitive}
}

// CompileSomTextPattern compiles source against the subset grammar.
//
// It returns a *SomPatternError when source is not in the grammar: an
// unterminated or reversed character class, a trailing `\`, an escape of an
// ASCII letter or digit, or a quantifier with nothing to quantify.
func CompileSomTextPattern(source string, caseInsensitive bool) (*SomTextPattern, error) {
	units := utf16Units(source)
	var terms []patternTerm

	bad := func(why string) error { return &SomPatternError{Pattern: source, Message: why} }

	i := 0
	for i < len(units) {
		ch := units[i]
		var term patternTerm
		switch ch {
		case patDot:
			term = patternTerm{kind: atomAny}
			i++
		case patCaret:
			term = patternTerm{kind: atomStartAnchor}
			i++
		case patDollar:
			term = patternTerm{kind: atomEndAnchor}
			i++
		case patBackslash:
			if i+1 >= len(units) {
				return nil, bad("pattern ends with a dangling escape")
			}
			if err := rejectClassEscape(units[i+1], bad); err != nil {
				return nil, err
			}
			term = patternTerm{kind: atomLiteral, literal: units[i+1]}
			i += 2
		case patOpenBracket:
			parsed, next, err := parseCharClass(units, i, bad)
			if err != nil {
				return nil, err
			}
			term = parsed
			i = next
		case patStar, patPlus, patQuestion:
			return nil, bad("quantifier \"" + unitText(ch) + "\" at offset " + itoa(i) +
				" has nothing to repeat")
		default:
			term = patternTerm{kind: atomLiteral, literal: ch}
			i++
		}

		if i < len(units) {
			repeat := repeatOne
			switch units[i] {
			case patStar:
				repeat = repeatZeroOrMore
			case patPlus:
				repeat = repeatOneOrMore
			case patQuestion:
				repeat = repeatZeroOrOne
			}
			if repeat != repeatOne {
				if term.isAnchor() {
					return nil, bad("anchor \"" + unitText(ch) + "\" at offset " + itoa(i) +
						" cannot carry a quantifier")
				}
				term.repeat = repeat
				i++
			}
		}
		terms = append(terms, term)
	}
	return &SomTextPattern{terms: terms, caseInsensitive: caseInsensitive}, nil
}

// AllMatches returns every non-overlapping match in text, left to right. The
// returned spans are UTF-16 code-unit offsets into text.
func (p *SomTextPattern) AllMatches(text string) []SpecMatchSpan {
	units := utf16Units(text)
	spans := []SpecMatchSpan{}
	start := 0
	for start <= len(units) {
		end := p.matchAt(units, 0, start)
		if end < 0 {
			start++
			continue
		}
		spans = append(spans, SpecMatchSpan{Start: start, End: end})
		// Non-overlapping: resume past the match, but never stand still.
		if end > start {
			start = end
		} else {
			start = start + 1
		}
	}
	return spans
}

// HasMatch reports whether text contains at least one match.
func (p *SomTextPattern) HasMatch(text string) bool {
	return len(p.AllMatches(text)) > 0
}

// matchAt matches p.terms from termIndex against units starting at `at`,
// returning the end offset of the match or -1. Greedy with backtracking: a
// repeated atom consumes as much as it can, then gives back one code unit at a
// time until the remainder of the pattern fits.
func (p *SomTextPattern) matchAt(units []uint16, termIndex, at int) int {
	if termIndex == len(p.terms) {
		return at
	}
	term := p.terms[termIndex]

	switch term.kind {
	case atomStartAnchor:
		if at == 0 {
			return p.matchAt(units, termIndex+1, at)
		}
		return -1
	case atomEndAnchor:
		if at == len(units) {
			return p.matchAt(units, termIndex+1, at)
		}
		return -1
	}

	switch term.repeat {
	case repeatOne:
		if at < len(units) && p.accepts(term, units[at]) {
			return p.matchAt(units, termIndex+1, at+1)
		}
		return -1
	case repeatZeroOrOne:
		if at < len(units) && p.accepts(term, units[at]) {
			if withOne := p.matchAt(units, termIndex+1, at+1); withOne >= 0 {
				return withOne
			}
		}
		return p.matchAt(units, termIndex+1, at)
	default: // repeatZeroOrMore / repeatOneOrMore
		minimum := 0
		if term.repeat == repeatOneOrMore {
			minimum = 1
		}
		consumed := at
		for consumed < len(units) && p.accepts(term, units[consumed]) {
			consumed++
		}
		for consumed-at >= minimum {
			if rest := p.matchAt(units, termIndex+1, consumed); rest >= 0 {
				return rest
			}
			if consumed == at {
				break
			}
			consumed--
		}
		return -1
	}
}

// accepts reports whether term admits a single code unit.
func (p *SomTextPattern) accepts(term patternTerm, unit uint16) bool {
	switch term.kind {
	case atomAny:
		return true
	case atomLiteral:
		return p.fold(unit) == p.fold(term.literal)
	case atomCharClass:
		inside := false
		for _, r := range term.ranges {
			if p.inRange(r, unit) {
				inside = true
				break
			}
		}
		if term.negated {
			return !inside
		}
		return inside
	}
	// Anchors consume nothing.
	return false
}

// inRange reports whether unit falls in r, honouring ASCII-only case folding: an
// insensitive `[a-z]` must also admit `Q`, which a single folded comparison of
// the code unit cannot express (folding `Q` to `q` would also make `[A-Z]` admit
// `q`, which is the same answer — but folding the *bounds* would break `[A-z]`).
// So both cases of the unit are tried against the raw range.
func (p *SomTextPattern) inRange(r patternRange, unit uint16) bool {
	if unit >= r.lo && unit <= r.hi {
		return true
	}
	if !p.caseInsensitive {
		return false
	}
	swapped := swapCaseASCII(unit)
	return swapped != unit && swapped >= r.lo && swapped <= r.hi
}

func (p *SomTextPattern) fold(unit uint16) uint16 {
	if p.caseInsensitive {
		return toLowerASCII(unit)
	}
	return unit
}

// ---------------------------------------------------------------------------
// Compilation helpers
// ---------------------------------------------------------------------------

const (
	patDot          uint16 = 0x2E // .
	patCaret        uint16 = 0x5E // ^
	patDollar       uint16 = 0x24 // $
	patBackslash    uint16 = 0x5C // \
	patOpenBracket  uint16 = 0x5B // [
	patCloseBracket uint16 = 0x5D // ]
	patStar         uint16 = 0x2A // *
	patPlus         uint16 = 0x2B // +
	patQuestion     uint16 = 0x3F // ?
	patDash         uint16 = 0x2D // -
	patUpperA       uint16 = 0x41
	patUpperZ       uint16 = 0x5A
	patLowerA       uint16 = 0x61
	patLowerZ       uint16 = 0x7A
	patZero         uint16 = 0x30
	patNine         uint16 = 0x39
)

// utf16Units converts s to the UTF-16 code units Dart's `String.codeUnits`
// yields, which is the unit every offset in this file (and in the committed
// corpus spans) counts in.
func utf16Units(s string) []uint16 {
	return utf16.Encode([]rune(s))
}

// unitText renders a single code unit for an error message.
func unitText(unit uint16) string {
	return string(utf16.Decode([]uint16{unit}))
}

func toLowerASCII(unit uint16) uint16 {
	if unit >= patUpperA && unit <= patUpperZ {
		return unit + 0x20
	}
	return unit
}

func swapCaseASCII(unit uint16) uint16 {
	if unit >= patUpperA && unit <= patUpperZ {
		return unit + 0x20
	}
	if unit >= patLowerA && unit <= patLowerZ {
		return unit - 0x20
	}
	return unit
}

// rejectClassEscape rejects `\` followed by an ASCII letter or digit.
//
// Every character-class shorthand other dialects define — `\d` `\w` `\s` `\b`
// `\n` `\1` — lives in exactly this space, and none of them has a literal
// reading anyone intends: nobody writes `\w` meaning the letter `w`. Accepting
// them as literals would make `slip\w+` quietly mean "slip, then one or more
// `w`", which matches nothing and reports no error. Escapes of *non*-
// alphanumerics stay legal, so `\.` `\[` `\(` still write those characters
// literally.
func rejectClassEscape(escaped uint16, bad func(string) error) error {
	isAlpha := (escaped >= patUpperA && escaped <= patUpperZ) ||
		(escaped >= patLowerA && escaped <= patLowerZ)
	isDigit := escaped >= patZero && escaped <= patNine
	if !isAlpha && !isDigit {
		return nil
	}
	return bad("escape \"\\" + unitText(escaped) + "\" is outside the portable " +
		"subset — it has no character-class shorthands, and reading it as a " +
		"literal \"" + unitText(escaped) + "\" would not be what was meant")
}

// parseCharClass parses the character class starting at units[open] (which is
// `[`), returning the compiled term and the offset just past its `]`.
func parseCharClass(
	units []uint16, open int, bad func(string) error,
) (patternTerm, int, error) {
	i := open + 1
	negated := false
	if i < len(units) && units[i] == patCaret {
		negated = true
		i++
	}
	var ranges []patternRange
	// A `]` immediately after `[` (or `[^`) is a literal `]`, the POSIX rule —
	// adopted because the alternative is an empty class, which can never match
	// and is therefore never what was meant.
	first := true
	for i < len(units) && (units[i] != patCloseBracket || first) {
		first = false
		lo := units[i]
		if lo == patBackslash {
			if i+1 >= len(units) {
				return patternTerm{}, 0, bad("dangling escape inside a character class")
			}
			if err := rejectClassEscape(units[i+1], bad); err != nil {
				return patternTerm{}, 0, err
			}
			lo = units[i+1]
			i += 2
		} else {
			i++
		}
		// `-` is a range only between two members; trailing `-` is a literal.
		if i+1 < len(units) && units[i] == patDash && units[i+1] != patCloseBracket {
			hi := units[i+1]
			step := 2
			if hi == patBackslash {
				if i+2 >= len(units) {
					return patternTerm{}, 0, bad("dangling escape inside a character class")
				}
				if err := rejectClassEscape(units[i+2], bad); err != nil {
					return patternTerm{}, 0, err
				}
				hi = units[i+2]
				step = 3
			}
			if hi < lo {
				return patternTerm{}, 0, bad("character class range \"" + unitText(lo) + "-" +
					unitText(hi) + "\" runs backwards")
			}
			ranges = append(ranges, patternRange{lo: lo, hi: hi})
			i += step
		} else {
			ranges = append(ranges, patternRange{lo: lo, hi: lo})
		}
	}
	if i >= len(units) {
		return patternTerm{}, 0, bad("character class opened at " + itoa(open) + " is never closed")
	}
	return patternTerm{kind: atomCharClass, ranges: ranges, negated: negated}, i + 1, nil
}
