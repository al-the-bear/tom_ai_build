"""The reading notation's scanner: one call per text value, returning the
value's fenced divs, bracketed spans and citation shapes with their kind,
attributes, source ranges and nesting, and the findings the DocSpecs
specification lists for the notation (*Reading Notation*, RN-1 … RN-13).

The Python port of ``tom_som_typescript_runtime``'s ``spec_notation.ts``
(itself the port of ``tom_som_dart_runtime``'s ``spec_notation.dart``): the
same grammar, the same elements and findings, the same offsets; all run
``tom_som_conformance/corpus/notation_cases.json``.

- a **fenced div** is a line of at least three colons, indented up to three
  spaces, then attribute braces (``::: {.provenance}``) or a bare kind word
  (``::: aside``); it closes at a line of at least three colons and nothing
  else, and a closing fence closes the innermost open div;
- a **bracketed span** is ``[text]`` followed immediately by attribute braces,
  inside one paragraph;
- a **citation shape** is ``(-> ids)`` (kind ``trace``), ``(<- source)`` or
  ``(<~ source)`` (kind ``provenance``);
- fenced code and code spans are literal, and so are ``\\:::`` and ``]\\{.``.

An unknown kind passes through as an element like any other.

**Offsets are UTF-16 code units**, as in every other runtime: a Python string
indexes by code point, so the scanner works on code points and converts each
offset it reports (``start``, ``end``, ``content_start``, ``content_end``,
``offset``) to UTF-16 code units. :meth:`NotationElement.to_json` slices the
text by those UTF-16 offsets.
"""

from __future__ import annotations

import re
from enum import Enum
from typing import Any, Optional

__all__ = [
    "NotationElement",
    "NotationFinding",
    "NotationFindingCode",
    "NotationScan",
    "notation_severity",
    "registered_notation_kinds",
    "scan_notation",
]

#: The kinds the notation registers (RN-5); any other kind passes through.
registered_notation_kinds: frozenset[str] = frozenset(
    {
        "provenance",
        "trace",
        "editorial",
        "aside",
        "linked",
        "derived",
        "refs",
        "records",
        "rejected",
    }
)


class NotationFindingCode(Enum):
    """The notation's findings (RN-10); each value is the rule's name in the
    DocSpecs validator."""

    UNCLOSED_DIV = "unclosedDiv"
    STRAY_CLOSING_FENCE = "strayClosingFence"
    UNCLOSED_SPAN = "unclosedSpan"
    DIV_WITHOUT_KIND = "divWithoutKind"
    UNKNOWN_KIND = "unknownKind"
    MARK_ACROSS_NOTATION = "markAcrossNotation"
    ANNOTATION_INSIDE_DIV = "annotationInsideDiv"
    DIV_INSIDE_ANNOTATION = "divInsideAnnotation"
    REJECTED_BLOCK = "rejectedBlock"


_CODE_ORDER = list(NotationFindingCode)
_TYPE_ORDER = ["div", "span", "citation"]


def notation_severity(code: NotationFindingCode) -> str:
    """The severity of *code*: an unknown kind is a ``warning``, the rest
    ``error``\\ s."""
    return "warning" if code is NotationFindingCode.UNKNOWN_KIND else "error"


def _utf16_slice(text: str, start: int, end: int) -> str:
    """``text`` between the UTF-16 offsets *start* and *end*."""
    return (
        text.encode("utf-16-le", "surrogatepass")[start * 2 : end * 2]
        .decode("utf-16-le", "surrogatepass")
    )


class NotationElement:
    """One element of the notation: a div, a span or a citation."""

    def __init__(
        self,
        *,
        type: str,
        kind: Optional[str],
        classes: list[str],
        id: Optional[str],
        attributes: dict[str, str],
        shape: Optional[str],
        start: int,
        end: int,
        content_start: int,
        content_end: int,
        line: int,
        end_line: int,
        closed: bool,
    ) -> None:
        #: ``div``, ``span`` or ``citation``.
        self.type = type
        #: The first class; ``trace`` / ``provenance`` for a citation;
        #: ``None`` without a class.
        self.kind = kind
        #: Every class, the kind first.
        self.classes = classes
        #: The ``#id`` of the attributes (not a section id).
        self.id = id
        #: The ``key="value"`` pairs, in their order.
        self.attributes = attributes
        #: A citation's arrow: ``->``, ``<-`` or ``<~``; ``None`` otherwise.
        self.shape = shape
        #: The UTF-16 offset of the first character.
        self.start = start
        #: The UTF-16 offset after the last character.
        self.end = end
        #: The UTF-16 offset of the content.
        self.content_start = content_start
        #: The UTF-16 offset after the content.
        self.content_end = content_end
        #: The 1-based line of :attr:`start`.
        self.line = line
        #: The 1-based line of the last character.
        self.end_line = end_line
        #: ``False`` for a div without a closing fence.
        self.closed = closed
        #: The elements nested in this one, in source order.
        self.children: list[NotationElement] = []

    @property
    def is_registered(self) -> bool:
        """Whether the kind is registered."""
        return self.kind is not None and self.kind in registered_notation_kinds

    def to_json(self, text: str) -> dict[str, Any]:
        """The element as the conformance corpus writes it."""
        return {
            "type": self.type,
            "kind": self.kind,
            "classes": list(self.classes),
            "id": self.id,
            "attributes": dict(self.attributes),
            "shape": self.shape,
            "start": self.start,
            "end": self.end,
            "line": self.line,
            "endLine": self.end_line,
            "closed": self.closed,
            "source": _utf16_slice(text, self.start, self.end),
            "content": _utf16_slice(text, self.content_start, self.content_end),
            "children": [c.to_json(text) for c in self.children],
        }


class NotationFinding:
    """One finding of the scan."""

    def __init__(
        self, code: NotationFindingCode, offset: int, line: int, message: str
    ) -> None:
        #: One of the :class:`NotationFindingCode` values.
        self.code = code
        #: The UTF-16 offset it stands at.
        self.offset = offset
        #: Its 1-based line.
        self.line = line
        self.message = message

    @property
    def severity(self) -> str:
        """The severity of the code."""
        return notation_severity(self.code)

    def to_json(self) -> dict[str, Any]:
        """The finding as the conformance corpus writes it."""
        return {"code": self.code.value, "severity": self.severity, "line": self.line}

    def __str__(self) -> str:
        return f"line {self.line}: {self.code.value} — {self.message}"


class NotationScan:
    """The result of :func:`scan_notation`."""

    def __init__(
        self,
        text: str,
        elements: list[NotationElement],
        findings: list[NotationFinding],
    ) -> None:
        self.text = text
        #: The elements not nested in another, in source order.
        self.elements = elements
        #: The findings, by offset.
        self.findings = findings

    @property
    def all(self) -> list[NotationElement]:
        """Every element, depth-first in source order."""
        out: list[NotationElement] = []

        def walk(elements: list[NotationElement]) -> None:
            for e in elements:
                out.append(e)
                walk(e.children)

        walk(self.elements)
        return out

    @property
    def has_errors(self) -> bool:
        """Whether a finding of severity ``error`` is present."""
        return any(f.severity == "error" for f in self.findings)


# The JavaScript whitespace class (``\s`` and ``String.prototype.trim``), which
# the Dart and TypeScript scanners use; Python's own differs (``\x1c``-``\x1f``
# and ``\x85`` in, ``﻿`` out).
_WS = "\t\n\x0b\x0c\r    -     　﻿"
_WS_RE = re.compile(f"[{_WS}]")
# JavaScript's ``.``: anything but a line terminator.
_DOT = "[^\n\r  ]"

_DIV_OPEN = re.compile(
    rf"^ {{0,3}}:{{3,}}[ \t]*(?:\{{({_DOT}*)\}}|([A-Za-z][A-Za-z0-9_-]*))[ \t]*\Z"
)
_DIV_CLOSE = re.compile(r"^ {0,3}:{3,}[ \t]*\Z")
_CODE_FENCE_OPEN = re.compile(rf"^ {{0,3}}(`{{3,}}|~{{3,}})({_DOT}*)\Z")
_QUOTE_LINE = re.compile(r"^ {0,3}>")
_ANNOTATION_START = re.compile("^ {0,3}> ?(?:⬆|\\*\\*❓|⚖)")
_QUOTED_DIV_OPEN = re.compile(
    rf"^ {{0,3}}>[ \t]?( {{0,3}}:{{3,}}[ \t]*(?:\{{{_DOT}*\}}|[A-Za-z][A-Za-z0-9_-]*)[ \t]*)\Z"
)
_ATTRIBUTE_TOKEN = re.compile(
    rf"\.([^{_WS}.#}}=\"']+)|#([^{_WS}.#}}=\"']+)"
    rf"|([A-Za-z_][A-Za-z0-9_:.-]*)=(\"[^\"]*\"|'[^']*'|[^{_WS}}}]+)"
)
_ASCII_PUNCTUATION = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
_MARK_OPENERS = ["{++", "{--", "{~~", "{==", "{>>"]
_MARK_CLOSERS = {
    "{++": "++}",
    "{--": "--}",
    "{~~": "~~}",
    "{==": "==}",
    "{>>": "<<}",
}
_CITATION_KINDS = {
    "->": "trace",
    "<-": "provenance",
    "<~": "provenance",
}


def _js_trim(s: str) -> str:
    """``String.prototype.trim``."""
    start = 0
    end = len(s)
    while start < end and _WS_RE.match(s[start]):
        start += 1
    while end > start and _WS_RE.match(s[end - 1]):
        end -= 1
    return s[start:end]


def _js_trim_left(s: str) -> str:
    start = 0
    while start < len(s) and _WS_RE.match(s[start]):
        start += 1
    return s[start:]


def scan_notation(text: str, tom_specs: bool = False) -> NotationScan:
    """Scans one text value for the reading notation. *tom_specs* says the
    value belongs to a TomSpecs rendition: only then are a div without a class
    and an unregistered kind reported (RN-10)."""
    return _Scanner(text, tom_specs is True).scan()


class _Attributes:
    def __init__(
        self, classes: list[str], id: Optional[str], pairs: dict[str, str]
    ) -> None:
        self.classes = classes
        self.id = id
        self.pairs = pairs


def _parse_attributes(inner: str) -> _Attributes:
    classes: list[str] = []
    id: Optional[str] = None
    pairs: dict[str, str] = {}
    for m in _ATTRIBUTE_TOKEN.finditer(inner):
        if m.group(1) is not None:
            classes.append(m.group(1))
        elif m.group(2) is not None:
            if id is None:
                id = m.group(2)
        else:
            value = m.group(4)
            if len(value) >= 2 and (
                (value.startswith('"') and value.endswith('"'))
                or (value.startswith("'") and value.endswith("'"))
            ):
                value = value[1:-1]
            pairs[m.group(3)] = value
    return _Attributes(classes, id, pairs)


class _OpenDiv:
    def __init__(
        self, start: int, content_start: int, line: int, attributes: _Attributes
    ) -> None:
        self.start = start
        self.content_start = content_start
        self.line = line
        self.attributes = attributes


class _Scanner:
    """Works on code-point offsets; every offset it reports is converted to
    UTF-16 code units (:meth:`_u16`)."""

    def __init__(self, text: str, tom_specs: bool) -> None:
        self.text = text
        self.tom_specs = tom_specs
        self.line_starts: list[int] = []
        self.lines: list[str] = []
        self.elements: list[NotationElement] = []
        self.findings: list[NotationFinding] = []
        # The UTF-16 offset of every code-point offset 0 … len(text).
        self.u16: list[int] = [0] * (len(text) + 1)
        unit = 0
        for i, ch in enumerate(text):
            self.u16[i] = unit
            unit += 2 if ord(ch) > 0xFFFF else 1
        self.u16[len(text)] = unit
        offset = 0
        for line in text.split("\n"):
            self.line_starts.append(offset)
            self.lines.append(line)
            offset += len(line) + 1

    def _u16(self, offset: int) -> int:
        return self.u16[offset]

    def line_of(self, offset: int) -> int:
        lo = 0
        hi = len(self.line_starts) - 1
        while lo < hi:
            mid = (lo + hi + 1) >> 1
            if self.line_starts[mid] <= offset:
                lo = mid
            else:
                hi = mid - 1
        return lo + 1

    def find(self, code: NotationFindingCode, offset: int, message: str) -> None:
        self.findings.append(
            NotationFinding(code, self._u16(offset), self.line_of(offset), message)
        )

    def element(
        self,
        *,
        type: str,
        attributes: _Attributes,
        shape: Optional[str],
        start: int,
        end: int,
        content_start: int,
        content_end: int,
        line: int,
        end_line: int,
        closed: bool,
    ) -> NotationElement:
        a = attributes
        return NotationElement(
            type=type,
            kind=a.classes[0] if a.classes else None,
            classes=a.classes,
            id=a.id,
            attributes=a.pairs,
            shape=shape,
            start=self._u16(start),
            end=self._u16(end),
            content_start=self._u16(content_start),
            content_end=self._u16(content_end),
            line=line,
            end_line=end_line,
            closed=closed,
        )

    def scan(self) -> NotationScan:
        self.blocks()
        self.kind_findings()
        ordered = sorted(
            self.elements,
            key=lambda e: (e.start, -e.end, _TYPE_ORDER.index(e.type)),
        )
        roots: list[NotationElement] = []
        stack: list[NotationElement] = []
        for e in ordered:
            while stack and not (
                e.start >= stack[-1].start and e.end <= stack[-1].end
            ):
                stack.pop()
            (stack[-1].children if stack else roots).append(e)
            stack.append(e)
        findings = sorted(
            self.findings, key=lambda f: (f.offset, _CODE_ORDER.index(f.code))
        )
        return NotationScan(self.text, roots, findings)

    # --- Blocks -----------------------------------------------------------

    def blocks(self) -> None:
        text = self.text
        open_divs: list[_OpenDiv] = []
        code_fence: Optional[str] = None
        in_annotation = False
        region_start: Optional[int] = None
        region_end = 0

        def end_region() -> None:
            nonlocal region_start
            if region_start is not None:
                self.inline(region_start, region_end)
            region_start = None

        for i, line in enumerate(self.lines):
            start = self.line_starts[i]
            line_end = start + len(line)
            nxt = self.line_starts[i + 1] if i + 1 < len(self.lines) else len(text)

            if code_fence is not None:
                t = _js_trim_left(line)
                if (
                    len(line) - len(t) <= 3
                    and t.startswith(code_fence)
                    and _js_trim(t[len(code_fence) :].replace(code_fence[0], ""))
                    == ""
                ):
                    code_fence = None
                continue

            if _ANNOTATION_START.match(line):
                if not in_annotation and open_divs:
                    self.find(
                        NotationFindingCode.ANNOTATION_INSIDE_DIV,
                        start,
                        "a comment or question block stands inside a div",
                    )
                in_annotation = True
            elif not _QUOTE_LINE.match(line):
                in_annotation = False
            if in_annotation:
                if _QUOTED_DIV_OPEN.match(line):
                    self.find(
                        NotationFindingCode.DIV_INSIDE_ANNOTATION,
                        start,
                        "a div stands inside a comment or question block",
                    )
                if region_start is None:
                    region_start = start
                region_end = line_end
                continue

            code = _CODE_FENCE_OPEN.match(line)
            if code is not None and not (
                code.group(1).startswith("`") and "`" in code.group(2)
            ):
                end_region()
                code_fence = code.group(1)
                continue

            div_open = _DIV_OPEN.match(line)
            if div_open is not None:
                end_region()
                attributes = (
                    _parse_attributes(div_open.group(1))
                    if div_open.group(1) is not None
                    else _Attributes([div_open.group(2)], None, {})
                )
                open_divs.append(_OpenDiv(start, nxt, i + 1, attributes))
                continue

            if _DIV_CLOSE.match(line):
                end_region()
                if not open_divs:
                    self.find(
                        NotationFindingCode.STRAY_CLOSING_FENCE,
                        start,
                        "a closing fence has no open div",
                    )
                else:
                    self.add_div(open_divs.pop(), line_end, start, True)
                continue

            if _js_trim(line) == "":
                end_region()
                continue
            if region_start is None:
                region_start = start
            region_end = line_end
        end_region()
        while open_divs:
            d = open_divs.pop()
            self.find(
                NotationFindingCode.UNCLOSED_DIV,
                d.start,
                "an opening fence has no closing fence",
            )
            self.add_div(d, len(text), len(text), False)

    def add_div(self, d: _OpenDiv, end: int, content_end: int, closed: bool) -> None:
        content_start = content_end if d.content_start > content_end else d.content_start
        self.elements.append(
            self.element(
                type="div",
                attributes=d.attributes,
                shape=None,
                start=d.start,
                end=end,
                content_start=content_start,
                content_end=content_end,
                line=d.line,
                end_line=self.line_of(end - 1 if end > d.start else d.start),
                closed=closed,
            )
        )

    # --- Inline -----------------------------------------------------------

    def inline(self, start: int, end: int) -> None:
        text = self.text
        literal: dict[int, int] = {}
        escaped: set[int] = set()
        i = start
        while i < end:
            c = text[i]
            if c == "\\" and i + 1 < end and text[i + 1] in _ASCII_PUNCTUATION:
                escaped.add(i + 1)
                i += 2
                continue
            if c == "`":
                n = 0
                while i + n < end and text[i + n] == "`":
                    n += 1
                close = self.closing_backticks(i + n, end, n)
                if close >= 0:
                    literal[i] = close + n
                    i = close + n
                else:
                    i += n
                continue
            i += 1

        # (start, end) of every span and citation, in code points, beside the
        # element itself (whose offsets are UTF-16).
        spans: list[tuple[int, int, str]] = []
        marks: list[tuple[int, int]] = []
        brackets: list[int] = []
        i = start
        while i < end:
            skip = literal.get(i)
            if skip is not None:
                i = skip
                continue
            c = text[i]
            if i in escaped or (c == "\\" and (i + 1) in escaped):
                i += 1
                continue
            if c == "{":
                opener = next((o for o in _MARK_OPENERS if text.startswith(o, i)), None)
                if opener is not None:
                    closer = _MARK_CLOSERS[opener]
                    close = text.find(closer, i + 3)
                    if close >= 0 and close + len(closer) <= end:
                        marks.append((i, close + len(closer)))
                    i += 3
                    continue
            if c == "[":
                brackets.append(i)
            elif c == "]" and brackets:
                open_at = brackets.pop()
                if (
                    i + 1 < end
                    and text[i + 1] == "{"
                    and (i + 1) not in escaped
                    and not any(text.startswith(o, i + 1) for o in _MARK_OPENERS)
                ):
                    close = self.closing_brace(i + 2, end)
                    if close < 0:
                        self.find(
                            NotationFindingCode.UNCLOSED_SPAN,
                            i + 1,
                            "a span's attribute braces do not close on the paragraph",
                        )
                    else:
                        span = self.element(
                            type="span",
                            attributes=_parse_attributes(text[i + 2 : close]),
                            shape=None,
                            start=open_at,
                            end=close + 1,
                            content_start=open_at + 1,
                            content_end=i,
                            line=self.line_of(open_at),
                            end_line=self.line_of(close),
                            closed=True,
                        )
                        spans.append((open_at, close + 1, "span"))
                        self.elements.append(span)
                        i = close + 1
                        continue
            elif c == "(" and i + 3 < end and text[i + 3] == " ":
                arrow = text[i + 1 : i + 3]
                kind = _CITATION_KINDS.get(arrow)
                if kind is not None:
                    close = self.closing_parenthesis(i + 4, end, literal)
                    if close > i + 4 and _js_trim(text[i + 4 : close]) != "":
                        citation = self.element(
                            type="citation",
                            attributes=_Attributes([kind], None, {}),
                            shape=arrow,
                            start=i,
                            end=close + 1,
                            content_start=i + 4,
                            content_end=close,
                            line=self.line_of(i),
                            end_line=self.line_of(close),
                            closed=True,
                        )
                        spans.append((i, close + 1, "citation"))
                        self.elements.append(citation)
                        i += 4
                        continue
            i += 1

        for ms, me in marks:
            for es, ee, etype in spans:
                crosses = (ms < es < me < ee) or (es < ms < ee < me)
                if crosses:
                    self.find(
                        NotationFindingCode.MARK_ACROSS_NOTATION,
                        ms,
                        f"an inline review mark crosses the boundary of a {etype}",
                    )
                    break

    def closing_backticks(self, frm: int, end: int, n: int) -> int:
        text = self.text
        i = frm
        while i < end:
            if text[i] == "`":
                m = 0
                while i + m < end and text[i + m] == "`":
                    m += 1
                if m == n:
                    return i
                i += m
            else:
                i += 1
        return -1

    def closing_brace(self, frm: int, end: int) -> int:
        text = self.text
        quote: Optional[str] = None
        for i in range(frm, end):
            c = text[i]
            if quote is not None:
                if c == quote:
                    quote = None
            elif c in ('"', "'"):
                quote = c
            elif c == "}":
                return i
            elif c == "{":
                return -1
        return -1

    def closing_parenthesis(self, frm: int, end: int, literal: dict[int, int]) -> int:
        text = self.text
        depth = 0
        i = frm
        while i < end:
            skip = literal.get(i)
            if skip is not None:
                i = skip
                continue
            c = text[i]
            if c == "(":
                depth += 1
            elif c == ")":
                if depth == 0:
                    return i
                depth -= 1
            i += 1
        return -1

    # --- Kinds ------------------------------------------------------------

    def kind_findings(self) -> None:
        # Element offsets are UTF-16; a finding takes a code-point offset, so
        # the element's start is mapped back.
        back = {u: i for i, u in enumerate(self.u16)}
        for e in self.elements:
            if e.type == "citation":
                continue
            start = back[e.start]
            if e.type == "div" and e.kind == "rejected":
                self.find(
                    NotationFindingCode.REJECTED_BLOCK,
                    start,
                    "a rejected block waits for its resolution",
                )
            if not self.tom_specs:
                continue
            if e.kind is None:
                if e.type == "div":
                    self.find(
                        NotationFindingCode.DIV_WITHOUT_KIND,
                        start,
                        "a div's attributes hold no class",
                    )
            elif not e.is_registered:
                self.find(
                    NotationFindingCode.UNKNOWN_KIND,
                    start,
                    f'the kind "{e.kind}" is not registered',
                )
