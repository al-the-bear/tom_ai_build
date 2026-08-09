"""The **portable text-pattern subset** the ``text`` dimension of a spec query
matches with (``som_multiplatform_spec_model.md`` §9) — a faithful port of
``tom_som_dart_runtime/lib/src/spec_text_pattern.dart``.

Why this exists rather than each language's own regex
-----------------------------------------------------

The query surface reports ``match_spans`` — offsets into the matched string —
and those spans are part of the nine-language contract. Delegating to each
language's regex engine (here: :mod:`re`) would make that contract unkeepable
twice over:

  * **Two runtimes have no regex to delegate to.** ``tom_som_rust_runtime`` is
    std-only by charter and ``tom_som_c_runtime`` is dependency-free; both would
    need a hand-rolled matcher regardless. Native-regex-elsewhere therefore does
    not remove the work, it only makes there be *two* implementations of the
    same semantics instead of one.
  * **The engines disagree where it matters.** Go's ``regexp`` is RE2
    (leftmost-longest for alternation), Dart/JS/Java/Python backtrack
    (leftmost-first); case folding is Unicode-aware in some and not others. A
    corpus could pin only the intersection, leaving every port's behaviour
    *outside* the corpus silently divergent.

So the matcher is one algorithm, transcribed into all nine runtimes. Equal spans
follow from equal code rather than from a hope about two libraries. **This module
must therefore never import** :mod:`re`.

The grammar
-----------

.. code-block:: text

    pattern   := term*
    term      := atom quantifier?
    quantifier:= '*' | '+' | '?'          (greedy; no lazy forms)
    atom      := '.'                       any character
               | '^'                       start-of-text anchor
               | '$'                       end-of-text anchor
               | '[' '^'? item* ']'        character class
               | '\\' PUNCT                the literal PUNCT (non-alphanumeric)
               | CHAR                      itself
    item      := CHAR | CHAR '-' CHAR      a member or an inclusive range

Deliberately **absent**: alternation, groups, backreferences, lazy quantifiers,
and the ``\\d``/``\\w``/``\\s`` shorthands. Each is either a source of
cross-engine disagreement or needs machinery (capture state, Unicode class
tables) that nine hand-written ports should not each be carrying.

Absent constructs are handled two different ways, and the line between them is
whether a literal reading is plausible:

  * ``(``, ``)``, ``|``, ``{``, ``}`` are **ordinary literals**. Text genuinely
    contains parentheses, so a pattern matching them must stay writable.
  * ``\\`` + an ASCII letter or digit is **a compile error**. That is precisely
    where ``\\d`` ``\\w`` ``\\s`` ``\\b`` ``\\n`` ``\\1`` live, and none has a
    literal reading anyone wants — treating ``slip\\w+`` as "slip then one or
    more ``w``" would match nothing while reporting no error.

Anchors bind to the whole text, never to a line: the values being searched are
section values, and a multiline mode would be a second dialect to agree on.

Matching semantics
------------------

Greedy backtracking, leftmost match wins. :meth:`SomTextPattern.all_matches`
scans start offsets left to right; a match of length ``L > 0`` resumes the scan
at its end, an empty match advances one character — the same non-overlapping
rule Dart's ``RegExp.allMatches`` uses, stated here so the other eight do not
have to infer it.

Case-insensitive matching folds **ASCII only** (``A``–``Z`` ↔ ``a``–``z``). Full
Unicode case folding differs between the nine languages' standard libraries and
would reintroduce exactly the divergence this module removes.

Offsets are **UTF-16 code units**, as in the Dart reference. A Python string is
a sequence of code points, so this port converts explicitly (:func:`utf16_units`)
rather than iterating characters: the two indexings agree throughout the Basic
Multilingual Plane and diverge above it, which is exactly the kind of difference
that passes every ASCII test and is wrong in production.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Callable, NoReturn


def utf16_units(text: str) -> list[int]:
    """*text* as a list of UTF-16 code units.

    Match offsets are UTF-16 code units in every runtime, because that is what
    the reference (Dart) indexes by and the offsets are part of the contract.
    A Python string is a sequence of *code points*, so the two agree throughout
    the BMP and part company above it: in ``"\U0001D11E-x"`` the ``x`` sits at
    code unit 3 but at code point 2. Iterating the string directly would
    therefore pass every ASCII case and silently report the wrong offset for
    any text containing an astral character — so the conversion is explicit
    here rather than left to ``ord`` per character.

    The same rule makes ``.`` match one code *unit*: against a lone surrogate
    pair it matches twice, once per half.
    """
    units: list[int] = []
    for ch in text:
        cp = ord(ch)
        if cp > 0xFFFF:
            cp -= 0x10000
            units.append(0xD800 + (cp >> 10))
            units.append(0xDC00 + (cp & 0x3FF))
        else:
            units.append(cp)
    return units


@dataclass(frozen=True)
class SpecMatchSpan:
    """A ``[start, end)`` half-open span within a matched string — the offsets a
    pattern hit, surfaced on :attr:`SpecQueryMatch.match_spans`."""

    #: Inclusive start offset into the matched string.
    start: int
    #: Exclusive end offset into the matched string.
    end: int

    def __str__(self) -> str:
        return f"SpecMatchSpan({self.start}, {self.end})"


class SomPatternError(Exception):
    """A pattern that is not in the :class:`SomTextPattern` grammar.

    Raised at *compile* time rather than silently matching nothing, so a caller
    that mistyped a pattern learns that instead of reading an empty result as
    "no hits".
    """

    def __init__(self, pattern: str, message: str) -> None:
        super().__init__(f'SomPatternError("{pattern}"): {message}')
        #: The offending pattern source.
        self.pattern = pattern
        #: What is wrong with it.
        self.message = message


class _AtomKind(Enum):
    """What a single :class:`_Term` matches."""

    LITERAL = "literal"
    ANY = "any"
    START_ANCHOR = "startAnchor"
    END_ANCHOR = "endAnchor"
    CHAR_CLASS = "charClass"


class _Repeat(Enum):
    """How many times a :class:`_Term`'s atom may repeat."""

    ONE = "one"
    ZERO_OR_ONE = "zeroOrOne"
    ZERO_OR_MORE = "zeroOrMore"
    ONE_OR_MORE = "oneOrMore"


@dataclass(frozen=True)
class _Range:
    """One inclusive ``[lo, hi]`` code-point range inside a character class."""

    lo: int
    hi: int


@dataclass(frozen=True)
class _Term:
    """One compiled atom plus its quantifier."""

    kind: _AtomKind
    #: The code point for :attr:`_AtomKind.LITERAL`.
    literal: int = 0
    #: The ranges for :attr:`_AtomKind.CHAR_CLASS`.
    ranges: tuple[_Range, ...] = ()
    #: Whether a :attr:`_AtomKind.CHAR_CLASS` is negated (``[^…]``).
    negated: bool = False
    repeat: _Repeat = _Repeat.ONE

    def with_repeat(self, r: _Repeat) -> "_Term":
        return _Term(
            kind=self.kind,
            literal=self.literal,
            ranges=self.ranges,
            negated=self.negated,
            repeat=r,
        )

    @property
    def is_anchor(self) -> bool:
        """Whether an anchor can carry a quantifier — it cannot; ``^*`` is
        meaningless and is far more likely to be a typo than an intent."""
        return self.kind in (_AtomKind.START_ANCHOR, _AtomKind.END_ANCHOR)


# --- compilation helpers ----------------------------------------------------

_K_DOT = 0x2E  # .
_K_CARET = 0x5E  # ^
_K_DOLLAR = 0x24  # $
_K_BACKSLASH = 0x5C  # \
_K_OPEN_BRACKET = 0x5B  # [
_K_CLOSE_BRACKET = 0x5D  # ]
_K_STAR = 0x2A  # *
_K_PLUS = 0x2B  # +
_K_QUESTION = 0x3F  # ?
_K_DASH = 0x2D  # -
_K_UPPER_A = 0x41
_K_UPPER_Z = 0x5A
_K_LOWER_A = 0x61
_K_LOWER_Z = 0x7A
_K_ZERO = 0x30
_K_NINE = 0x39


def _to_lower_ascii(unit: int) -> int:
    return unit + 0x20 if _K_UPPER_A <= unit <= _K_UPPER_Z else unit


def _swap_case(unit: int) -> int:
    if _K_UPPER_A <= unit <= _K_UPPER_Z:
        return unit + 0x20
    if _K_LOWER_A <= unit <= _K_LOWER_Z:
        return unit - 0x20
    return unit


def _reject_class_escape(escaped: int, bad: Callable[[str], NoReturn]) -> None:
    """Rejects ``\\`` followed by an ASCII letter or digit.

    Every character-class shorthand other dialects define — ``\\d`` ``\\w``
    ``\\s`` ``\\b`` ``\\n`` ``\\1`` — lives in exactly this space, and none of
    them has a literal reading anyone intends: nobody writes ``\\w`` meaning the
    letter ``w``. Accepting them as literals would make ``slip\\w+`` quietly mean
    "slip, then one or more ``w``", which matches nothing and reports no error.
    Escapes of *non*-alphanumerics stay legal, so ``\\.`` ``\\[`` ``\\(`` still
    write those characters literally.
    """
    is_alpha = (_K_UPPER_A <= escaped <= _K_UPPER_Z) or (
        _K_LOWER_A <= escaped <= _K_LOWER_Z
    )
    is_digit = _K_ZERO <= escaped <= _K_NINE
    if not is_alpha and not is_digit:
        return
    bad(
        f'escape "\\{chr(escaped)}" is outside the portable subset — it has no '
        f'character-class shorthands, and reading it as a literal '
        f'"{chr(escaped)}" would not be what was meant'
    )


def _parse_class(
    units: list[int], open_at: int, bad: Callable[[str], NoReturn]
) -> tuple[_Term, int]:
    """Parses the character class starting at ``units[open_at]`` (which is
    ``[``), returning the compiled term and the offset just past its ``]``."""
    i = open_at + 1
    negated = False
    if i < len(units) and units[i] == _K_CARET:
        negated = True
        i += 1
    ranges: list[_Range] = []
    # A `]` immediately after `[` (or `[^`) is a literal `]`, the POSIX rule —
    # adopted because the alternative is an empty class, which can never match
    # and is therefore never what was meant.
    first = True
    while i < len(units) and (units[i] != _K_CLOSE_BRACKET or first):
        first = False
        lo = units[i]
        if lo == _K_BACKSLASH:
            if i + 1 >= len(units):
                bad("dangling escape inside a character class")
            _reject_class_escape(units[i + 1], bad)
            lo = units[i + 1]
            i += 2
        else:
            i += 1
        # `-` is a range only between two members; trailing `-` is a literal.
        if (
            i + 1 < len(units)
            and units[i] == _K_DASH
            and units[i + 1] != _K_CLOSE_BRACKET
        ):
            hi = units[i + 1]
            step = 2
            if hi == _K_BACKSLASH:
                if i + 2 >= len(units):
                    bad("dangling escape inside a character class")
                _reject_class_escape(units[i + 2], bad)
                hi = units[i + 2]
                step = 3
            if hi < lo:
                bad(
                    f'character class range "{chr(lo)}-{chr(hi)}" runs backwards'
                )
            ranges.append(_Range(lo, hi))
            i += step
        else:
            ranges.append(_Range(lo, lo))
    if i >= len(units):
        bad(f"character class opened at {open_at} is never closed")
    return (
        _Term(kind=_AtomKind.CHAR_CLASS, ranges=tuple(ranges), negated=negated),
        i + 1,
    )


class SomTextPattern:
    """A compiled pattern over the portable subset described in the module
    docstring. Compile once with :meth:`compile` (or :meth:`literal` for a plain
    substring) and match with :meth:`all_matches`."""

    def __init__(self, terms: list[_Term], case_insensitive: bool) -> None:
        self._terms = terms
        self._case_insensitive = case_insensitive

    @classmethod
    def literal(cls, text: str, case_insensitive: bool = False) -> "SomTextPattern":
        """A pattern matching *text* as a plain, uninterpreted substring — every
        character is a literal, including ``.`` ``*`` ``[`` and the rest."""
        return cls(
            [_Term(kind=_AtomKind.LITERAL, literal=u) for u in utf16_units(text)],
            case_insensitive,
        )

    @classmethod
    def compile(cls, source: str, case_insensitive: bool = False) -> "SomTextPattern":
        """Compiles *source* against the subset grammar.

        Raises :class:`SomPatternError` when *source* is not in the grammar: an
        unterminated or reversed character class, a trailing ``\\``, or a
        quantifier with nothing to quantify.
        """
        units = utf16_units(source)
        terms: list[_Term] = []

        def bad(why: str) -> NoReturn:
            raise SomPatternError(source, why)

        i = 0
        while i < len(units):
            ch = units[i]
            if ch == _K_DOT:
                term = _Term(kind=_AtomKind.ANY)
                i += 1
            elif ch == _K_CARET:
                term = _Term(kind=_AtomKind.START_ANCHOR)
                i += 1
            elif ch == _K_DOLLAR:
                term = _Term(kind=_AtomKind.END_ANCHOR)
                i += 1
            elif ch == _K_BACKSLASH:
                if i + 1 >= len(units):
                    bad("pattern ends with a dangling escape")
                _reject_class_escape(units[i + 1], bad)
                term = _Term(kind=_AtomKind.LITERAL, literal=units[i + 1])
                i += 2
            elif ch == _K_OPEN_BRACKET:
                term, i = _parse_class(units, i, bad)
            elif ch in (_K_STAR, _K_PLUS, _K_QUESTION):
                bad(
                    f'quantifier "{chr(ch)}" at offset {i} has nothing to repeat'
                )
            else:
                term = _Term(kind=_AtomKind.LITERAL, literal=ch)
                i += 1

            if i < len(units):
                repeat = {
                    _K_STAR: _Repeat.ZERO_OR_MORE,
                    _K_PLUS: _Repeat.ONE_OR_MORE,
                    _K_QUESTION: _Repeat.ZERO_OR_ONE,
                }.get(units[i], _Repeat.ONE)
                if repeat != _Repeat.ONE:
                    if term.is_anchor:
                        bad(
                            f'anchor "{chr(ch)}" at offset {i} cannot carry a '
                            f"quantifier"
                        )
                    term = term.with_repeat(repeat)
                    i += 1
            terms.append(term)
        return cls(terms, case_insensitive)

    def all_matches(self, text: str) -> list[SpecMatchSpan]:
        """Every non-overlapping match in *text*, left to right."""
        units = utf16_units(text)
        spans: list[SpecMatchSpan] = []
        start = 0
        while start <= len(units):
            end = self._match_at(units, 0, start)
            if end < 0:
                start += 1
                continue
            spans.append(SpecMatchSpan(start, end))
            # Non-overlapping: resume past the match, but never stand still.
            start = end if end > start else start + 1
        return spans

    def has_match(self, text: str) -> bool:
        """Whether *text* contains at least one match."""
        return bool(self.all_matches(text))

    # --- matching -----------------------------------------------------------

    def _match_at(self, units: list[int], term_index: int, at: int) -> int:
        """Matches :attr:`_terms` from *term_index* against *units* starting at
        *at*, returning the end offset of the match or ``-1``. Greedy with
        backtracking: a repeated atom consumes as much as it can, then gives back
        one character at a time until the remainder of the pattern fits."""
        if term_index == len(self._terms):
            return at
        term = self._terms[term_index]

        if term.kind == _AtomKind.START_ANCHOR:
            return self._match_at(units, term_index + 1, at) if at == 0 else -1
        if term.kind == _AtomKind.END_ANCHOR:
            return (
                self._match_at(units, term_index + 1, at)
                if at == len(units)
                else -1
            )

        if term.repeat == _Repeat.ONE:
            if at < len(units) and self._accepts(term, units[at]):
                return self._match_at(units, term_index + 1, at + 1)
            return -1
        if term.repeat == _Repeat.ZERO_OR_ONE:
            if at < len(units) and self._accepts(term, units[at]):
                with_one = self._match_at(units, term_index + 1, at + 1)
                if with_one >= 0:
                    return with_one
            return self._match_at(units, term_index + 1, at)

        minimum = 1 if term.repeat == _Repeat.ONE_OR_MORE else 0
        consumed = at
        while consumed < len(units) and self._accepts(term, units[consumed]):
            consumed += 1
        while consumed - at >= minimum:
            rest = self._match_at(units, term_index + 1, consumed)
            if rest >= 0:
                return rest
            if consumed == at:
                break
            consumed -= 1
        return -1

    def _accepts(self, term: _Term, unit: int) -> bool:
        if term.kind == _AtomKind.ANY:
            return True
        if term.kind == _AtomKind.LITERAL:
            return self._fold(unit) == self._fold(term.literal)
        if term.kind == _AtomKind.CHAR_CLASS:
            inside = any(self._in_range(r, unit) for r in term.ranges)
            return not inside if term.negated else inside
        return False  # anchors accept no character

    def _in_range(self, r: _Range, unit: int) -> bool:
        """Whether *unit* falls in *r*, honouring ASCII-only case folding: an
        insensitive ``[a-z]`` must also admit ``Q``, which a single folded
        comparison of the code point cannot express (folding ``Q`` to ``q`` would
        also make ``[A-Z]`` admit ``q``, which is the same answer — but folding
        the *bounds* would break ``[A-z]``). So both cases of the unit are tried
        against the raw range."""
        if r.lo <= unit <= r.hi:
            return True
        if not self._case_insensitive:
            return False
        swapped = _swap_case(unit)
        return swapped != unit and r.lo <= swapped <= r.hi

    def _fold(self, unit: int) -> int:
        return _to_lower_ascii(unit) if self._case_insensitive else unit
