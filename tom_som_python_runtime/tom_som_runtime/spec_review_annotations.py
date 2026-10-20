"""Review annotations in content values (SOM §11.9): comment blocks, question
blocks and CriticMarkup inline marks — a faithful port of
`tom_som_dart_runtime/lib/src/spec_review_annotations.dart`.

An annotation is text inside a content value or a form-field value. This
module reads it out of that text and edits it in place, and every edit is
byte-stable outside the annotation it touches. The notation itself is
``som_multiplatform_spec_model.md`` §11.9.

Positions are **0-based line numbers within the value**, never character
offsets: the nine runtimes count characters in different units, and a line
number is the same in all of them.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field as dc_field
from enum import Enum
from typing import Any, Callable, Optional

from .spec_document import SpecDocument
from .spec_validator import SpecValidationCode, SpecValidationError


class SpecReviewAnnotationKind(Enum):
    """The three kinds of annotation (SOM §11.9)."""

    #: A reviewer's comment block, ``> ⬆️ **C-12** (Alexis): …``.
    COMMENT = "comment"
    #: One question of a question block, ``> **❓ BQ-81 — topic:** …``.
    QUESTION = "question"
    #: A CriticMarkup inline mark.
    MARK = "mark"


class SpecMarkKind(Enum):
    """The five CriticMarkup inline marks (SOM §11.9.3)."""

    #: ``{>> comment <<}``.
    COMMENT = "comment"
    #: ``{== text ==}``, optionally followed by ``{>> comment <<}``.
    HIGHLIGHT = "highlight"
    #: ``{++ added ++}``.
    INSERTION = "insertion"
    #: ``{-- removed --}``.
    DELETION = "deletion"
    #: ``{~~ old ~> new ~~}``.
    SUBSTITUTION = "substitution"


@dataclass(frozen=True)
class SpecReviewAnnotation:
    """One annotation, located by the value that holds it."""

    #: The kind.
    kind: SpecReviewAnnotationKind
    #: The document path of the value: a content path, or a form path when
    #: :attr:`field` is set.
    path: str
    #: The 0-based line within the value where the annotation starts (a
    #: question: its header line).
    line: int
    #: The form field whose value holds the annotation; ``None`` for content.
    field: Optional[str] = None
    #: The comment id (``C-12``) or question id (``BQ-81``); ``None`` for a
    #: comment without an id and for a mark.
    id: Optional[str] = None
    #: A comment's id with the document qualifier in front (``SBP C-12``).
    qualified_id: Optional[str] = None
    #: A comment's author; ``None`` when none is written.
    author: Optional[str] = None
    #: A comment's text, a question's text (options included), or a mark's
    #: text (a substitution's old text; empty for a comment mark).
    text: str = ""
    #: A comment's context: the paragraph before the block, verbatim.
    context: str = ""
    #: A question's topic (in a combined block: the field it asks about).
    topic: Optional[str] = None
    #: Whether a question carries ``★`` before its topic.
    starred: bool = False
    #: Whether a question is part of a combined block.
    combined: bool = False
    #: A question's answer, trimmed; empty when open.
    answer: str = ""
    #: A mark's kind.
    mark_kind: Optional[SpecMarkKind] = None
    #: A substitution's new text.
    new_text: Optional[str] = None
    #: The comment of a comment mark, or of a highlight followed by one.
    comment: Optional[str] = None

    @property
    def open(self) -> bool:
        """Whether a question is still open (no answer written)."""
        return self.kind is SpecReviewAnnotationKind.QUESTION and self.answer == ""

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form the conformance corpus pins."""
        if self.kind is SpecReviewAnnotationKind.COMMENT:
            return {
                "kind": "comment",
                "path": self.path,
                "field": self.field,
                "line": self.line,
                "id": self.id,
                "qualifiedId": self.qualified_id,
                "author": self.author,
                "text": self.text,
                "context": self.context,
            }
        if self.kind is SpecReviewAnnotationKind.QUESTION:
            return {
                "kind": "question",
                "path": self.path,
                "field": self.field,
                "line": self.line,
                "id": self.id,
                "topic": self.topic,
                "starred": self.starred,
                "combined": self.combined,
                "text": self.text,
                "answer": self.answer,
                "open": self.open,
            }
        assert self.mark_kind is not None
        return {
            "kind": "mark",
            "path": self.path,
            "field": self.field,
            "line": self.line,
            "markKind": self.mark_kind.value,
            "text": self.text,
            "newText": self.new_text,
            "comment": self.comment,
        }


@dataclass(frozen=True)
class SpecReviewAnnotationCounts:
    """The counts a report needs (SOM §11.9)."""

    questions: int = 0
    open_questions: int = 0
    answered_questions: int = 0
    comments: int = 0
    marks: int = 0

    def to_json(self) -> dict[str, int]:
        """The canonical JSON form."""
        return {
            "questions": self.questions,
            "openQuestions": self.open_questions,
            "answeredQuestions": self.answered_questions,
            "comments": self.comments,
            "marks": self.marks,
        }


@dataclass(frozen=True)
class SpecQuestionDraft:
    """A question to insert (SOM §11.9.2)."""

    #: The question id (``BQ-90``).
    id: str
    #: The topic.
    topic: str
    #: The question text; may span lines.
    text: str
    #: Option lines, written as ``- <option>``.
    options: tuple[str, ...] = ()
    #: The recommendation, or empty.
    recommendation: str = ""
    #: The working assumption, or empty.
    assumption: str = ""
    #: Whether the question carries ``★``.
    starred: bool = False

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecQuestionDraft":
        """Reads a draft from its corpus JSON form."""
        return SpecQuestionDraft(
            id=str(j["id"]),
            topic=str(j["topic"]),
            text=str(j["text"]),
            options=tuple(str(o) for o in (j.get("options") or [])),
            recommendation=j.get("recommendation") or "",
            assumption=j.get("assumption") or "",
            starred=bool(j.get("starred") or False),
        )


class SpecMarkDecision(Enum):
    """What to do with one inline mark (SOM §11.9.3)."""

    #: Take the change: an insertion's text, nothing for a deletion, a
    #: substitution's new text.
    ACCEPT = "accept"
    #: Undo the change: nothing for an insertion, a deletion's text, a
    #: substitution's old text.
    REJECT = "reject"
    #: Keep the mark as written.
    LEAVE = "leave"


@dataclass(frozen=True)
class SpecMarkEntry:
    """One inline mark as :meth:`SpecReviewAnnotations.list_marks` reports it."""

    #: ``M-<n>``: the mark's 1-based position among all marks of the
    #: document, in document order. Stable for one
    #: :meth:`SpecReviewAnnotations.revision`.
    id: str
    #: The value's path.
    path: str
    #: The form field, or ``None`` for content.
    field: Optional[str]
    #: The 0-based line within the value where the mark opens.
    line: int
    #: The mark's kind.
    mark_kind: SpecMarkKind
    #: The text after rejecting the mark.
    old_text: str
    #: The text after accepting the mark.
    new_text: str
    #: A comment mark's or a commented highlight's comment.
    comment: Optional[str]
    #: The mark as written.
    markup: str
    #: The paragraph holding the mark, verbatim — for display.
    context: str

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form the conformance corpus pins."""
        return {
            "id": self.id,
            "path": self.path,
            "field": self.field,
            "line": self.line,
            "markKind": self.mark_kind.value,
            "oldText": self.old_text,
            "newText": self.new_text,
            "comment": self.comment,
            "markup": self.markup,
            "context": self.context,
        }


@dataclass(frozen=True)
class SpecMarkOutcome:
    """What was done to one mark."""

    #: The mark's id at the revision the operation ran on.
    id: str
    #: The value's path.
    path: str
    #: The form field, or ``None`` for content.
    field: Optional[str]
    #: The 0-based line within the value where the mark opened.
    line: int
    #: The mark's kind.
    mark_kind: SpecMarkKind
    #: Accepted or rejected.
    decision: SpecMarkDecision
    #: The mark as written.
    markup: str
    #: The text that replaced it.
    result: str

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "id": self.id,
            "path": self.path,
            "field": self.field,
            "line": self.line,
            "markKind": self.mark_kind.value,
            "decision": self.decision.value,
            "markup": self.markup,
            "result": self.result,
        }


@dataclass(frozen=True)
class SpecMarkIssue:
    """A mark the scanner could not read; it is left as written."""

    #: The value's path.
    path: str
    #: The form field, or ``None`` for content.
    field: Optional[str]
    #: The 0-based line within the value.
    line: int
    #: ``unclosed``, ``nested`` or ``noArrow``.
    issue: str

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "path": self.path,
            "field": self.field,
            "line": self.line,
            "issue": self.issue,
        }


@dataclass(frozen=True)
class SpecMarkReport:
    """The report of a mark operation, for the decision log."""

    #: What was done, in document order.
    applied: tuple[SpecMarkOutcome, ...] = ()
    #: Malformed marks in scope, left as written.
    malformed: tuple[SpecMarkIssue, ...] = ()

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "applied": [a.to_json() for a in self.applied],
            "malformed": [m.to_json() for m in self.malformed],
        }


class SpecReviewAnnotationError(Exception):
    """Raised when an operation names an annotation, value or paragraph that
    does not exist. Raised before anything is changed."""

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message

    def __str__(self) -> str:
        return f"SpecReviewAnnotationError: {self.message}"


# ---------------------------------------------------------------------------
# Text level: one value.
# ---------------------------------------------------------------------------

_ARROW = "⬆"
_VS16 = "️"
_QUESTION_OPEN = "**❓"
_COMBINED_OPENER = "**❓ Open questions on these fields**"
_ANSWER_LABEL = "**Answer:**"
_EM_DASH_SEP = " — "
_STAR = "★"

_COMMENT_ID = re.compile(r"[1-9][0-9]*")
_QUESTION_ID = re.compile(r"[A-Z][A-Z0-9]*-[0-9]+")

# Dart's `String.trim` whitespace set, so "trimmed" means the same here.
_WS = frozenset(
    "\t\n\u000b\u000c\r \u0085  "
    "           "
    "    　﻿"
)


def _trim(s: str) -> str:
    a, b = 0, len(s)
    while a < b and s[a] in _WS:
        a += 1
    while b > a and s[b - 1] in _WS:
        b -= 1
    return s[a:b]


def _trim_right(s: str) -> str:
    b = len(s)
    while b > 0 and s[b - 1] in _WS:
        b -= 1
    return s[:b]


@dataclass(eq=False)
class _Block:
    """One parsed block of a value (lines [start, end] inclusive)."""

    start: int
    end: int
    kind: SpecReviewAnnotationKind
    questions: list["_Question"] = dc_field(default_factory=list)
    combined: bool = False


@dataclass
class _Question:
    header: int  # value line of the header
    region_end: int  # last value line of the region (inclusive)
    answer_line: Optional[int]  # value line of `**Answer:**`, or None
    id: str
    topic: str
    starred: bool
    text: str
    answer: str


@dataclass
class _Comment:
    block: _Block
    id: Optional[str]
    author: Optional[str]
    text: str
    context: str
    #: The first line up to where the text starts (kept by an edit).
    header_prefix: str
    #: Where an id is inserted into the first line.
    marker_end: int


@dataclass
class _Mark:
    """One parsed mark; start/end are offsets into the value (Python code
    points — never exported)."""

    start: int
    end: int
    line: int
    kind: SpecMarkKind
    text: str
    new_text: Optional[str]
    comment: Optional[str]


class _Parsed:
    def __init__(self, lines: list[str], code: list[bool]) -> None:
        self.lines = lines
        self.code = code
        self.blocks: list[_Block] = []
        self.comments: list[_Comment] = []
        self.marks: list[_Mark] = []
        self.malformed: list[str] = []
        #: Malformed inline marks as (value line, issue code): ``unclosed``,
        #: ``nested``, ``noArrow``.
        self.mark_issues: list[tuple[int, str]] = []


def _lstrip(s: str) -> str:
    i = 0
    while i < len(s) and s[i] in (" ", "\t"):
        i += 1
    return s[i:]


def _is_blank(s: str) -> bool:
    return _trim(s) == ""


def _code_lines(lines: list[str]) -> list[bool]:
    """The fenced-code flag of every line."""
    code = [False] * len(lines)
    fence_char: Optional[str] = None
    fence_len = 0
    for i, line in enumerate(lines):
        t = _lstrip(line)
        if fence_char is None:
            c = t[0] if t else ""
            if c in ("`", "~"):
                n = 0
                while n < len(t) and t[n] == c:
                    n += 1
                if n >= 3:
                    fence_char = c
                    fence_len = n
                    code[i] = True
        else:
            code[i] = True
            n = 0
            while n < len(t) and t[n] == fence_char:
                n += 1
            if n >= fence_len and _trim(t[n:]) == "":
                fence_char = None
    return code


def _is_quote_line(line: str) -> bool:
    return _lstrip(line).startswith(">")


def _inner(line: str) -> str:
    """The line inside the quote: after ``>`` and one following space."""
    s = _lstrip(line)[1:]
    if s.startswith(" "):
        s = s[1:]
    return s


def _parse(value: str) -> _Parsed:
    lines = value.split("\n")
    code = _code_lines(lines)
    p = _Parsed(lines, code)

    i = 0
    while i < len(lines):
        if code[i] or not _is_quote_line(lines[i]):
            i += 1
            continue
        s = i
        while i + 1 < len(lines) and not code[i + 1] and _is_quote_line(lines[i + 1]):
            i += 1
        e = i
        first = _inner(lines[s])
        if first.startswith(_ARROW):
            b = _Block(s, e, SpecReviewAnnotationKind.COMMENT)
            p.blocks.append(b)
            p.comments.append(_parse_comment(p, b))
        elif first.startswith(_QUESTION_OPEN):
            b = _Block(s, e, SpecReviewAnnotationKind.QUESTION)
            p.blocks.append(b)
            _parse_questions(p, b)
        i = e + 1

    _parse_marks(p)
    return p


def _context(p: _Parsed, block_start: int) -> str:
    k = block_start - 1
    while k >= 0 and (_is_blank(p.lines[k]) or _is_quote_line(p.lines[k])):
        k -= 1
    if k < 0:
        return ""
    end = k
    while k - 1 >= 0 and not _is_blank(p.lines[k - 1]) and not _is_quote_line(p.lines[k - 1]):
        k -= 1
    return "\n".join(p.lines[k:end + 1])


def _parse_comment(p: _Parsed, b: _Block) -> _Comment:
    raw0 = p.lines[b.start]
    rest = _inner(raw0)[len(_ARROW):]
    if rest.startswith(_VS16):
        rest = rest[len(_VS16):]
    marker_end = len(raw0) - len(rest)
    rest = _lstrip(rest)
    cid: Optional[str] = None
    if rest.startswith("**C-"):
        close = rest.find("**", 4)
        if close >= 0:
            n = rest[4:close]
            if _COMMENT_ID.fullmatch(n):
                cid = f"C-{n}"
            else:
                p.malformed.append(
                    f'line {b.start}: comment id "C-{n}" is not C-<number> '
                    "(SOM §11.9.1)"
                )
            rest = _lstrip(rest[close + 2:])
    author: Optional[str] = None
    if rest.startswith("("):
        close = rest.find(")")
        if close > 0:
            author = rest[1:close]
            rest = rest[close + 1:]
            if rest.startswith(":"):
                rest = rest[1:]
            rest = _lstrip(rest)
    elif rest.startswith(":"):
        rest = _lstrip(rest[1:])
    header_prefix = raw0[: len(raw0) - len(rest)]
    text_lines = [rest]
    for k in range(b.start + 1, b.end + 1):
        inner = _inner(p.lines[k])
        t = _lstrip(inner)
        if t.startswith(_QUESTION_OPEN) or t.startswith(_ANSWER_LABEL):
            p.malformed.append(
                f"line {k}: a comment block holds a question or an answer; the "
                "question goes into its own block after the comment (SOM §11.9.1)"
            )
        text_lines.append(inner)
    return _Comment(
        b,
        cid,
        author,
        _trim("\n".join(text_lines)),
        _context(p, b.start),
        header_prefix,
        marker_end,
    )


def _parse_header(inner: str) -> Optional[tuple[str, str, bool, str]]:
    """Parses a question header's remainder after ``**❓ ``; ``None`` when
    malformed. Answers (id, topic, starred, rest)."""
    h = inner[len(_QUESTION_OPEN) + 1:]
    sep = h.find(_EM_DASH_SEP)
    if sep <= 0:
        return None
    qid = h[:sep]
    if not _QUESTION_ID.fullmatch(qid):
        return None
    t = h[sep + len(_EM_DASH_SEP):]
    starred = False
    if t.startswith(_STAR + " "):
        starred = True
        t = t[len(_STAR) + 1:]
    close = t.find(":**")
    if close < 0:
        return None
    topic = t[:close]
    rest = t[close + 3:]
    if rest.startswith(" "):
        rest = rest[1:]
    return (qid, topic, starred, rest)


def _parse_questions(p: _Parsed, b: _Block) -> None:
    inner = [_inner(p.lines[k]) for k in range(b.start, b.end + 1)]
    b.combined = inner[0].startswith(_COMBINED_OPENER)
    headers: dict[int, tuple[str, str, bool, str]] = {}
    for k, text in enumerate(inner):
        if not text.startswith(_QUESTION_OPEN + " "):
            continue
        if text.startswith(_COMBINED_OPENER):
            continue
        h = _parse_header(text)
        if h is None:
            p.malformed.append(
                f"line {b.start + k}: question header is not "
                '"**❓ <ID> — <topic>:**" (SOM §11.9.2)'
            )
            continue
        headers[k] = h
    keys = list(headers.keys())
    out: list[_Question] = []
    for q, k in enumerate(keys):
        qid, topic, starred, rest = headers[k]
        region_end = keys[q + 1] - 1 if q + 1 < len(keys) else len(inner) - 1
        answer: Optional[int] = None
        for m in range(k + 1, region_end + 1):
            if inner[m].startswith(_ANSWER_LABEL):
                answer = m
                break
        text_end = region_end if answer is None else answer - 1
        text = _trim("\n".join([rest, *inner[k + 1:text_end + 1]]))
        answer_text = ""
        if answer is not None:
            answer_text = _trim(
                "\n".join(
                    [inner[answer][len(_ANSWER_LABEL):], *inner[answer + 1:region_end + 1]]
                )
            )
        out.append(
            _Question(
                b.start + k,
                b.start + region_end,
                None if answer is None else b.start + answer,
                qid,
                topic,
                starred,
                text,
                answer_text,
            )
        )
    b.questions = out


_OPENERS = ("{>>", "{==", "{++", "{--", "{~~")
_CLOSERS = {
    "{>>": "<<}",
    "{==": "==}",
    "{++": "++}",
    "{--": "--}",
    "{~~": "~~}",
}


def _has_opener(s: str) -> bool:
    return any(o in s for o in _OPENERS)


def _paragraph_end(text: str, start: int) -> int:
    """The offset of the first blank line's preceding ``\\n`` after *start*
    (the paragraph end), or the text length."""
    i = text.find("\n", start)
    while i >= 0:
        nxt = text.find("\n", i + 1)
        line = text[i + 1:(len(text) if nxt < 0 else nxt)]
        if _trim(line) == "":
            return i
        i = nxt
    return len(text)


def _parse_marks(p: _Parsed) -> None:
    line_start: list[int] = []
    off = 0
    for line in p.lines:
        line_start.append(off)
        off += len(line) + 1
    value = "\n".join(p.lines)

    def line_of(offset: int) -> int:
        lo = 0
        for k, s in enumerate(line_start):
            if s <= offset:
                lo = k
        return lo

    k = 0
    n = len(p.lines)
    while k < n:
        if p.code[k]:
            k += 1
            continue
        seg_start_line = k
        while k < n and not p.code[k]:
            k += 1
        seg_start = line_start[seg_start_line]
        seg_end = line_start[k - 1] + len(p.lines[k - 1])
        _scan_segment(p, value[seg_start:seg_end], seg_start, line_of)


def _scan_segment(p: _Parsed, seg: str, base: int, line_of: Callable[[int], int]) -> None:
    i = 0
    length = len(seg)
    while i < length:
        c = seg[i]
        if c == "`":
            n = 0
            while i + n < length and seg[i + n] == "`":
                n += 1
            j = i + n
            close_at = -1
            while j < length:
                if seg[j] == "`":
                    m = 0
                    while j + m < length and seg[j + m] == "`":
                        m += 1
                    if m == n:
                        close_at = j
                        break
                    j += m
                else:
                    j += 1
            i = i + n if close_at < 0 else close_at + n
            continue
        if c != "{" or i + 3 > length:
            i += 1
            continue
        opener = seg[i:i + 3]
        if opener not in _OPENERS:
            i += 1
            continue
        closer = _CLOSERS[opener]
        close = seg.find(closer, i + 3)
        pend = _paragraph_end(seg, i)
        line = line_of(base + i)
        if close < 0 or close > pend:
            p.malformed.append(
                f'line {line}: inline mark "{opener}" is not closed in its paragraph '
                "(SOM §11.9.3)"
            )
            p.mark_issues.append((line, "unclosed"))
            i += 3
            continue
        inner = seg[i + 3:close]
        if _has_opener(inner):
            p.malformed.append(f"line {line}: inline marks do not nest (SOM §11.9.3)")
            p.mark_issues.append((line, "nested"))
            i = close + 3
            continue
        end = close + 3
        if opener == "{>>":
            p.marks.append(
                _Mark(base + i, base + end, line, SpecMarkKind.COMMENT, "", None, _trim(inner))
            )
        elif opener == "{==":
            comment: Optional[str] = None
            if seg.startswith("{>>", end):
                c2 = seg.find("<<}", end + 3)
                if c2 >= 0 and c2 <= _paragraph_end(seg, end):
                    ci = seg[end + 3:c2]
                    if not _has_opener(ci):
                        comment = _trim(ci)
                        end = c2 + 3
            p.marks.append(
                _Mark(base + i, base + end, line, SpecMarkKind.HIGHLIGHT, _trim(inner), None, comment)
            )
        elif opener == "{++":
            p.marks.append(
                _Mark(base + i, base + end, line, SpecMarkKind.INSERTION, _trim(inner), None, None)
            )
        elif opener == "{--":
            p.marks.append(
                _Mark(base + i, base + end, line, SpecMarkKind.DELETION, _trim(inner), None, None)
            )
        else:  # {~~
            arrow = inner.find("~>")
            if arrow < 0:
                p.malformed.append(
                    f'line {line}: a substitution has no "~>" (SOM §11.9.3)'
                )
                p.mark_issues.append((line, "noArrow"))
                i = end
                continue
            p.marks.append(
                _Mark(
                    base + i,
                    base + end,
                    line,
                    SpecMarkKind.SUBSTITUTION,
                    _trim(inner[:arrow]),
                    _trim(inner[arrow + 2:]),
                    None,
                )
            )
        i = end


def _annotations_of(
    p: _Parsed, path: str, field: Optional[str], qualifier: Optional[str]
) -> list[SpecReviewAnnotation]:
    """The annotations of one value, in order: by line, blocks before marks,
    then scan order."""
    out: list[tuple[int, int, int, SpecReviewAnnotation]] = []
    seq = 0
    for b in p.blocks:
        if b.kind is SpecReviewAnnotationKind.COMMENT:
            c = next(c for c in p.comments if c.block is b)
            out.append((
                b.start,
                0,
                seq,
                SpecReviewAnnotation(
                    kind=SpecReviewAnnotationKind.COMMENT,
                    path=path,
                    field=field,
                    line=b.start,
                    id=c.id,
                    qualified_id=(
                        f"{qualifier} {c.id}" if qualifier is not None and c.id is not None else None
                    ),
                    author=c.author,
                    text=c.text,
                    context=c.context,
                ),
            ))
            seq += 1
        else:
            for q in b.questions:
                out.append((
                    q.header,
                    0,
                    seq,
                    SpecReviewAnnotation(
                        kind=SpecReviewAnnotationKind.QUESTION,
                        path=path,
                        field=field,
                        line=q.header,
                        id=q.id,
                        topic=q.topic,
                        starred=q.starred,
                        combined=b.combined,
                        text=q.text,
                        answer=q.answer,
                    ),
                ))
                seq += 1
    for m in p.marks:
        out.append((
            m.line,
            1,
            seq,
            SpecReviewAnnotation(
                kind=SpecReviewAnnotationKind.MARK,
                path=path,
                field=field,
                line=m.line,
                mark_kind=m.kind,
                text=m.text,
                new_text=m.new_text,
                comment=m.comment,
            ),
        ))
        seq += 1
    out.sort(key=lambda e: (e[0], e[1], e[2]))
    return [e[3] for e in out]


def _paragraphs(lines: list[str], code: list[bool]) -> list[tuple[int, int]]:
    """The paragraphs of a value as (first line, last line), blank-separated
    and fence-aware."""
    out: list[tuple[int, int]] = []
    k = 0
    while k < len(lines):
        if _is_blank(lines[k]) and not code[k]:
            k += 1
            continue
        s = k
        while k + 1 < len(lines) and not (_is_blank(lines[k + 1]) and not code[k + 1]):
            k += 1
        out.append((s, k))
        k += 1
    return out


def _insert_after_line(value: str, end: int, block: list[str]) -> str:
    """Inserts *block* after value line *end* (-1: at the start), one blank
    line on each side."""
    if value == "":
        return "\n".join(block)
    lines = value.split("\n")
    before = lines[: end + 1]
    rest = lines[end + 1:]
    out = list(before)
    if before:
        out.append("")
    out.extend(block)
    if rest:
        if not _is_blank(rest[0]):
            out.append("")
        out.extend(rest)
    return "\n".join(out)


def _remove_lines(value: str, s: int, e: int) -> str:
    """Removes value lines [s, e] and one adjacent blank line."""
    lines = value.split("\n")
    start, to = s, e
    if to + 1 < len(lines) and _is_blank(lines[to + 1]):
        to += 1
    elif start - 1 >= 0 and _is_blank(lines[start - 1]):
        start -= 1
    del lines[start:to + 1]
    out = "\n".join(lines)
    return "" if _trim(out) == "" else out


def _quoted(lines: list[str]) -> list[str]:
    return [">" if line == "" else f"> {line}" for line in lines]


def format_comment_block(id: str, text: str, author: Optional[str] = None) -> list[str]:
    """The lines of a comment block."""
    t = text.split("\n")
    head = f"> {_ARROW}{_VS16} **{id}**"
    if author:
        head += f" ({author}):"
    if t[0] != "":
        head += f" {t[0]}"
    return [head, *_quoted(t[1:])]


def format_question_block(q: SpecQuestionDraft) -> list[str]:
    """The lines of a question block."""
    t = q.text.split("\n")
    star = f"{_STAR} " if q.starred else ""
    lines = [
        f"> {_QUESTION_OPEN} {q.id}{_EM_DASH_SEP}{star}{q.topic}:** {t[0]}",
        *_quoted(t[1:]),
        *[f"> - {o}" for o in q.options],
    ]
    if q.recommendation or q.assumption:
        lines.append(">")
        if q.recommendation:
            lines.append(f"> *Recommendation:* {q.recommendation}")
        if q.assumption:
            lines.append(f"> *Working assumption until answered:* {q.assumption}")
    lines.append(">")
    lines.append(f"> {_ANSWER_LABEL}")
    return lines


def _word_char_at(s: str, i: int) -> bool:
    """Letters and digits (any script); punctuation and spaces are not."""
    if i < 0 or i >= len(s):
        return False
    c = s[i]
    return c.lower() != c.upper() or ("0" <= c <= "9")


def _word_char(s: str) -> bool:
    return s != "" and _word_char_at(s, len(s) - 1)


def _is_space(c: str) -> bool:
    return c == " " or c == "\t"


def _trim_end_spaces(s: str) -> str:
    k = len(s)
    while k > 0 and _is_space(s[k - 1]):
        k -= 1
    return s[:k]


def _trim_start_spaces(s: str) -> str:
    k = 0
    while k < len(s) and _is_space(s[k]):
        k += 1
    return s[k:]


def _replace_mark(value: str, m: _Mark, replacement: str) -> str:
    """Applies a mark's replacement with the whitespace rules of SOM §11.9.3:
    never join two words, never leave a double space or a space before
    punctuation, and a mark that was a whole line leaves no blank line."""
    before = value[: m.start]
    after = value[m.end:]
    if replacement == "":
        tb = _trim_end_spaces(before)
        ta = _trim_start_spaces(after)
        line_start = tb == "" or tb.endswith("\n")
        line_end = ta == "" or ta.startswith("\n")
        if line_start and line_end:
            # The mark was the whole line: the line goes, and with it one of
            # the newlines around it; a blank line left doubled is merged.
            before = tb
            after = ta
            if after.startswith("\n"):
                after = after[1:]
            elif before.endswith("\n"):
                before = before[:-1]
            if (before == "" or before.endswith("\n\n")) and after.startswith("\n"):
                after = after[1:]
            if after == "":
                before = before.rstrip("\n")
            return before + after
        if before != "" and _is_space(before[-1]):
            if after != "" and _is_space(after[0]):
                after = _trim_start_spaces(after)
            elif after == "" or after.startswith("\n") or after[0] in ".,;:!?)]}":
                before = _trim_end_spaces(before)
        elif (before == "" or before.endswith("\n")) and after != "" and _is_space(after[0]):
            after = _trim_start_spaces(after)
        return before + after
    # Never join two words: a mark written flush against a word keeps a space
    # on that side.
    if _word_char(before) and _word_char_at(replacement, 0):
        replacement = " " + replacement
    if _word_char_at(replacement, len(replacement) - 1) and after != "" and _word_char_at(after, 0):
        replacement = replacement + " "
    return before + replacement + after


def _mark_replacement(m: _Mark, accept: bool) -> str:
    if m.kind is SpecMarkKind.INSERTION:
        return m.text if accept else ""
    if m.kind is SpecMarkKind.DELETION:
        return "" if accept else m.text
    if m.kind is SpecMarkKind.SUBSTITUTION:
        assert m.new_text is not None
        return m.new_text if accept else m.text
    if m.kind is SpecMarkKind.HIGHLIGHT:
        return m.text
    return ""


def apply_inline_marks_text(value: str, accept: bool) -> str:
    """*value* with every inline mark accepted (*accept*) or rejected, and
    every highlight and comment mark removed, by the rules of SOM §11.9.3.
    Marks in code and malformed marks stay as written."""
    v = value
    for m in reversed(_parse(v).marks):
        v = _replace_mark(v, m, _mark_replacement(m, accept))
    return v


def strip_annotations_text(value: str) -> str:
    """*value* without any comment block, question block or inline mark
    (every mark accepted). Plain quotes and code stay."""
    v = value
    # Blocks, from the last up, so earlier line numbers stay valid.
    while True:
        p = _parse(v)
        if not p.blocks:
            break
        b = p.blocks[-1]
        v = _remove_lines(v, b.start, b.end)
    while True:
        p = _parse(v)
        if not p.marks:
            break
        m = p.marks[-1]
        v = _replace_mark(v, m, _mark_replacement(m, True))
    return v


# ---------------------------------------------------------------------------
# Document level.
# ---------------------------------------------------------------------------


class SpecReviewAnnotations:
    """The annotations of a document, and the operations that edit them
    (SOM §11.9). Values are visited in a fixed order — content paths sorted,
    then form paths sorted with their field names sorted — so "document order"
    is the same in every runtime."""

    def __init__(self, doc: SpecDocument, qualifier: Optional[str] = None) -> None:
        #: The document.
        self.doc = doc
        #: The document's id or name, written in front of a comment id cited
        #: outside the document (``SBP`` → ``SBP C-12``); ``None`` for bare ids.
        self.qualifier = qualifier

    def _values(self) -> list[tuple[str, Optional[str], str]]:
        out: list[tuple[str, Optional[str], str]] = []
        for path in sorted(self.doc.content_paths):
            out.append((path, None, self.doc.content(path) or ""))
        for path in sorted(self.doc.form_paths):
            for f in sorted(self.doc.form_field_names(path)):
                out.append((path, f, self.doc.form_field(path, f) or ""))
        return out

    def _get(self, path: str, field: Optional[str]) -> str:
        v = self.doc.content(path) if field is None else self.doc.form_field(path, field)
        return v or ""

    def _set(self, path: str, field: Optional[str], value: str) -> None:
        if field is None:
            self.doc.set_content(path, value)
        else:
            self.doc.set_form_field(path, field, value)

    def list(self) -> list[SpecReviewAnnotation]:
        """Every annotation, in document order."""
        out: list[SpecReviewAnnotation] = []
        for path, field, text in self._values():
            out.extend(_annotations_of(_parse(text), path, field, self.qualifier))
        return out

    def counts(self) -> SpecReviewAnnotationCounts:
        """The counts a report needs."""
        q = open_ = c = m = 0
        for a in self.list():
            if a.kind is SpecReviewAnnotationKind.QUESTION:
                q += 1
                if a.open:
                    open_ += 1
            elif a.kind is SpecReviewAnnotationKind.COMMENT:
                c += 1
            else:
                m += 1
        return SpecReviewAnnotationCounts(
            questions=q,
            open_questions=open_,
            answered_questions=q - open_,
            comments=c,
            marks=m,
        )

    def _highest_comment_number(self) -> int:
        high = 0
        for a in self.list():
            if a.kind is SpecReviewAnnotationKind.COMMENT and a.id is not None:
                n = int(a.id[2:])
                if n > high:
                    high = n
        return high

    def next_comment_id(self, floor: int = 0) -> str:
        """The id the next comment gets: ``C-<n>``, n = the highest number in
        the document (or *floor*, when higher) plus one. Writes nothing."""
        high = self._highest_comment_number()
        return f"C-{max(high, floor) + 1}"

    def assign_comment_ids(self, floor: int = 0) -> list[str]:
        """Gives every comment without an id the next one, in document order,
        and returns the ids assigned. Nothing else changes."""
        nxt = max(self._highest_comment_number(), floor) + 1
        assigned: list[str] = []
        for path, field, text in self._values():
            p = _parse(text)
            bare = [c for c in p.comments if c.id is None]
            if not bare:
                continue
            lines = text.split("\n")
            for c in bare:
                cid = f"C-{nxt}"
                nxt += 1
                assigned.append(cid)
                raw = lines[c.block.start]
                at = c.marker_end
                if at < len(raw) and raw[at] == " ":
                    lines[c.block.start] = f"{raw[:at + 1]}**{cid}** {raw[at + 1:]}"
                elif at >= len(raw):
                    lines[c.block.start] = f"{raw} **{cid}**"
                else:
                    lines[c.block.start] = f"{raw[:at]} **{cid}** {raw[at:]}"
            self._set(path, field, "\n".join(lines))
        return assigned

    def insert_comment(
        self,
        path: str,
        after_paragraph: int,
        text: str,
        field: Optional[str] = None,
        author: Optional[str] = None,
        id: Optional[str] = None,
    ) -> str:
        """Inserts a comment block after paragraph *after_paragraph* (0-based;
        -1: at the start) of the value at *path* / *field*, and returns its id
        — *id* when given, else the next free one."""
        cid = id if id is not None else self.next_comment_id()
        value = self._get(path, field)
        end = self._paragraph_last_line(value, after_paragraph)
        self._set(
            path,
            field,
            _insert_after_line(value, end, format_comment_block(cid, text, author)),
        )
        return cid

    def insert_question(
        self,
        path: str,
        after_paragraph: int,
        question: SpecQuestionDraft,
        field: Optional[str] = None,
    ) -> None:
        """Inserts a question block after paragraph *after_paragraph* (0-based;
        -1: at the start) of the value at *path* / *field*."""
        value = self._get(path, field)
        end = self._paragraph_last_line(value, after_paragraph)
        self._set(path, field, _insert_after_line(value, end, format_question_block(question)))

    def insert_question_after_comment(self, comment_id: str, question: SpecQuestionDraft) -> None:
        """Inserts a question block directly after the comment *comment_id*."""
        path, field, text, c = self._find_comment(comment_id)
        self._set(
            path,
            field,
            _insert_after_line(text, c.block.end, format_question_block(question)),
        )

    def set_answer(self, question_id: str, answer: str) -> None:
        """Writes *answer* after the question's ``**Answer:**`` (empty: reopens
        it)."""
        path, field, text, _b, q = self._find_question(question_id)
        lines = text.split("\n")
        a = answer.split("\n")
        if answer == "":
            written = [f"> {_ANSWER_LABEL}"]
        else:
            written = [f"> {_ANSWER_LABEL} {a[0]}", *_quoted(a[1:])]
        # The answer runs to the region's last non-empty line.
        last = q.region_end
        while last > q.header and _trim(_inner(lines[last])) == "":
            last -= 1
        if q.answer_line is not None:
            start = q.answer_line
            to = start if last < start else last
            lines[start:to + 1] = written
        else:
            lines[last + 1:last + 1] = [">", *written]
        self._set(path, field, "\n".join(lines))

    def edit_comment(self, comment_id: str, text: str) -> None:
        """Replaces a comment's text; its marker, id and author stay as
        written."""
        path, field, value, c = self._find_comment(comment_id)
        lines = value.split("\n")
        t = text.split("\n")
        block = [_trim_right(f"{c.header_prefix}{t[0]}"), *_quoted(t[1:])]
        lines[c.block.start:c.block.end + 1] = block
        self._set(path, field, "\n".join(lines))

    def resolve(self, id: str) -> None:
        """Removes one comment or question by id (a qualified comment id,
        ``SBP C-12``, is accepted). A question of a combined block takes only
        its own lines; the block goes when its last question does."""
        bare = id.split(" ")[-1] if " " in id else id
        if bare.startswith("C-"):
            path, field, value, c = self._find_comment(bare)
            self._set(path, field, _remove_lines(value, c.block.start, c.block.end))
            return
        path, field, value, b, q = self._find_question(bare)
        if len(b.questions) == 1:
            self._set(path, field, _remove_lines(value, b.start, b.end))
            return
        lines = value.split("\n")
        del lines[q.header:q.region_end + 1]
        # A last question leaves the separator `>` lines of the one before it.
        end = b.end - (q.region_end - q.header + 1)
        while end > b.start and _trim(_inner(lines[end])) == "":
            del lines[end]
            end -= 1
        self._set(path, field, "\n".join(lines))

    def apply_mark(
        self,
        path: str,
        index: int,
        field: Optional[str] = None,
        accept: bool = True,
    ) -> None:
        """Accepts (*accept*) or rejects the inline mark *index* (0-based among
        the marks of the value at *path* / *field*)."""
        value = self._get(path, field)
        marks = _parse(value).marks
        if index < 0 or index >= len(marks):
            where = path if field is None else f"{path} / {field}"
            raise SpecReviewAnnotationError(f"no inline mark {index} at {where}")
        m = marks[index]
        self._set(path, field, _replace_mark(value, m, _mark_replacement(m, accept)))

    def revision(self) -> str:
        """The revision the mark ids are stable for: FNV-1a 64-bit over the
        UTF-8 of every value in document order (path, NUL, field or empty,
        NUL, text, NUL), as 16 lower-case hex digits. Any change to a value
        changes it."""
        mask = 0xFFFFFFFFFFFFFFFF
        prime = 0x100000001B3
        h = 0xCBF29CE484222325

        def add(s: str) -> None:
            nonlocal h
            for b in s.encode("utf-8", "surrogatepass"):
                h = ((h ^ b) * prime) & mask
            h = (h * prime) & mask

        for path, field, text in self._values():
            add(path)
            add(field or "")
            add(text)
        return format(h, "016x")

    @staticmethod
    def _under(path: str, under: Optional[str]) -> bool:
        return under is None or path == under or path.startswith(under + "/")

    def list_marks(self, path: Optional[str] = None) -> "list[SpecMarkEntry]":
        """Every inline mark of the document, or of the subtree at *path*, in
        document order."""
        out: list[SpecMarkEntry] = []
        n = 0
        for vpath, field, text in self._values():
            p = _parse(text)
            paras = _paragraphs(p.lines, p.code)
            for m in p.marks:
                n += 1
                id = f"M-{n}"
                if not self._under(vpath, path):
                    continue
                para = next(
                    (r for r in paras if r[0] <= m.line <= r[1]), (m.line, m.line)
                )
                out.append(
                    SpecMarkEntry(
                        id=id,
                        path=vpath,
                        field=field,
                        line=m.line,
                        mark_kind=m.kind,
                        old_text=_mark_replacement(m, False),
                        new_text=_mark_replacement(m, True),
                        comment=m.comment,
                        markup=text[m.start:m.end],
                        context="\n".join(p.lines[para[0]:para[1] + 1]),
                    )
                )
        return out

    def _apply_marks(
        self,
        decide: Callable[[str], Optional[SpecMarkDecision]],
        under: Optional[str] = None,
    ) -> SpecMarkReport:
        """Applies *decide* to every mark in the subtree *under* (``None``:
        the whole document), one write per value."""
        applied: list[SpecMarkOutcome] = []
        issues: list[SpecMarkIssue] = []
        n = 0
        for path, field, text in self._values():
            p = _parse(text)
            ids = []
            for _ in p.marks:
                n += 1
                ids.append(f"M-{n}")
            if not self._under(path, under):
                continue
            for line, code in p.mark_issues:
                issues.append(SpecMarkIssue(path=path, field=field, line=line, issue=code))
            v = text
            outcomes: list[SpecMarkOutcome] = []
            for k in range(len(p.marks) - 1, -1, -1):
                d = decide(ids[k])
                if d is None or d is SpecMarkDecision.LEAVE:
                    continue
                m = p.marks[k]
                repl = _mark_replacement(m, d is SpecMarkDecision.ACCEPT)
                outcomes.insert(
                    0,
                    SpecMarkOutcome(
                        id=ids[k],
                        path=path,
                        field=field,
                        line=m.line,
                        mark_kind=m.kind,
                        decision=d,
                        markup=text[m.start:m.end],
                        result=repl,
                    ),
                )
                v = _replace_mark(v, m, repl)
            if v != text:
                self._set(path, field, v)
            applied.extend(outcomes)
        return SpecMarkReport(applied=tuple(applied), malformed=tuple(issues))

    def decide_marks(
        self, decisions: "dict[str, SpecMarkDecision]", revision: str
    ) -> SpecMarkReport:
        """Applies one decision per named mark in one write. Refused — nothing
        changes — when the document is no longer at *revision*, or when a
        decision names a mark that does not exist. Marks not named, and marks
        decided ``LEAVE``, stay."""
        current = self.revision()
        if revision != current:
            raise SpecReviewAnnotationError(
                f"the document changed since revision {revision} (now {current}); "
                "list the marks again"
            )
        known = {m.id for m in self.list_marks()}
        for id in decisions:
            if id not in known:
                raise SpecReviewAnnotationError(f"no inline mark {id} in the document")
        return self._apply_marks(lambda id: decisions.get(id))

    def accept_all_marks(self, path: Optional[str] = None) -> SpecMarkReport:
        """Accepts every inline mark under *path* (``None``: the whole
        document)."""
        return self._apply_marks(lambda _: SpecMarkDecision.ACCEPT, under=path)

    def reject_all_marks(self, path: Optional[str] = None) -> SpecMarkReport:
        """Rejects every inline mark under *path* (``None``: the whole
        document)."""
        return self._apply_marks(lambda _: SpecMarkDecision.REJECT, under=path)

    def remove_all_annotations(self) -> SpecMarkReport:
        """Removes every annotation and writes the result back: every inline
        mark accepted, every comment and question block removed. Malformed
        marks stay and are reported."""
        report = self.accept_all_marks()
        for path, field, text in self._values():
            v = text
            while True:
                p = _parse(v)
                if not p.blocks:
                    break
                b = p.blocks[-1]
                v = _remove_lines(v, b.start, b.end)
            if v != text:
                self._set(path, field, v)
        return report

    def set_marked(self, path: str, text: str, field: Optional[str] = None) -> "SpecMarkedChange":
        """Writes *text* at *path* / *field* as a marked change against the
        value there now (SOM §11.9.3). A value that already holds change marks
        is compared from its original — every mark rejected — so a second edit
        of the same passage updates its mark instead of nesting one."""
        current = self._get(path, field)
        base = apply_inline_marks_text(current, accept=False)
        result = mark_change_text(base, text)
        self._set(path, field, result.text)
        return result

    def mark_against(self, path: str, earlier: str, field: Optional[str] = None) -> "SpecMarkedChange":
        """Marks the value at *path* / *field* as a change against *earlier*,
        an earlier version of it."""
        result = mark_change_text(earlier, self._get(path, field))
        self._set(path, field, result.text)
        return result

    def stripped(self) -> SpecDocument:
        """A copy of the document without any annotation, for reading. The
        document itself is unchanged."""
        copy = SpecDocument()
        copy.load_json(self.doc.to_json())
        for path, field, text in self._values():
            clean = strip_annotations_text(text)
            if clean == text:
                continue
            if field is None:
                copy.set_content(path, clean)
            else:
                copy.set_form_field(path, field, clean)
        return copy

    def _paragraph_last_line(self, value: str, after_paragraph: int) -> int:
        if after_paragraph < 0:
            return -1
        lines = value.split("\n")
        paras = _paragraphs(lines, _code_lines(lines))
        if value == "" or after_paragraph >= len(paras):
            have = 0 if value == "" else len(paras)
            raise SpecReviewAnnotationError(
                f"the value has {have} paragraph(s); there is no paragraph {after_paragraph}"
            )
        return paras[after_paragraph][1]

    def _find_comment(self, id: str) -> tuple[str, Optional[str], str, _Comment]:
        for path, field, text in self._values():
            for c in _parse(text).comments:
                if c.id == id:
                    return path, field, text, c
        raise SpecReviewAnnotationError(f"no comment {id} in the document")

    def _find_question(
        self, id: str
    ) -> tuple[str, Optional[str], str, _Block, _Question]:
        for path, field, text in self._values():
            p = _parse(text)
            for b in p.blocks:
                for q in b.questions:
                    if q.id == id:
                        return path, field, text, b, q
        raise SpecReviewAnnotationError(f"no question {id} in the document")

    def validate(self) -> list[SpecValidationError]:
        """The instance-tier findings on annotations (SOM §11.9.5), ordered by
        path."""
        errors: list[SpecValidationError] = []
        seen: set[str] = set()
        for path, field, text in self._values():
            p = _parse(text)
            where = path if field is None else f"{path} / {field}"
            for m in p.malformed:
                errors.append(
                    SpecValidationError(
                        path=path,
                        code=SpecValidationCode.ANNOTATION_MALFORMED,
                        message=f"{where}, {m}",
                    )
                )
            if field is not None:
                for b in p.blocks:
                    errors.append(
                        SpecValidationError(
                            path=path,
                            code=SpecValidationCode.ANNOTATION_MISPLACED,
                            message=(
                                f"{where}, line {b.start}: a {b.kind.value} block sits in a "
                                "form field value; it belongs in the form's preamble, "
                                "above the first field (SOM §11.9.4)"
                            ),
                        )
                    )
            ids = [c.id for c in p.comments if c.id is not None]
            for b in p.blocks:
                ids.extend(q.id for q in b.questions)
            for i in ids:
                if i in seen:
                    errors.append(
                        SpecValidationError(
                            path=path,
                            code=SpecValidationCode.DUPLICATE_ANNOTATION_ID,
                            message=f"{where}: {i} is used more than once in the document",
                        )
                    )
                else:
                    seen.add(i)
        # sorted() is stable: equal paths keep their finding order.
        return sorted(errors, key=lambda e: e.path)


# ---------------------------------------------------------------------------
# Writing changes as inline marks (SOM §11.9.3, annot5).
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class SpecMarkedChange:
    """A value written as a marked change."""

    #: The value with every difference marked.
    text: str
    #: Whether accepting the marks gives exactly the new value and rejecting
    #: them exactly the old one. False when a difference cannot be marked — a
    #: change inside fenced code, or text that holds mark delimiters — and the
    #: new value was written unmarked instead.
    exact: bool

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"text": self.text, "exact": self.exact}


@dataclass(frozen=True)
class _Tok:
    """One token of a value: a run of whitespace, a word (a run of
    non-whitespace with inline code spans kept whole) or a fenced code block
    (its lines)."""

    text: str
    space: bool


def _is_ws(c: str) -> bool:
    return c == " " or c == "\t" or c == "\n"


def _tokens(value: str) -> list[_Tok]:
    out: list[_Tok] = []

    def add(t: str, space: bool) -> None:
        if t == "":
            return
        if space and out and out[-1].space:
            out[-1] = _Tok(out[-1].text + t, True)
        else:
            out.append(_Tok(t, space))

    def words(s: str) -> None:
        i = 0
        while i < len(s):
            if _is_ws(s[i]):
                st = i
                while i < len(s) and _is_ws(s[i]):
                    i += 1
                add(s[st:i], True)
                continue
            st = i
            while i < len(s) and not _is_ws(s[i]):
                if s[i] == "`":
                    n = 0
                    while i + n < len(s) and s[i + n] == "`":
                        n += 1
                    # The matching run of exactly n backticks ends the span.
                    j = i + n
                    close = -1
                    while j < len(s):
                        if s[j] == "`":
                            m = 0
                            while j + m < len(s) and s[j + m] == "`":
                                m += 1
                            if m == n:
                                close = j
                                break
                            j += m
                        else:
                            j += 1
                    i = i + n if close < 0 else close + n
                    continue
                i += 1
            add(s[st:i], False)

    lines = value.split("\n")
    code = _code_lines(lines)
    k = 0
    while k < len(lines):
        if k > 0:
            add("\n", True)
        st = k
        is_code = code[k]
        while k + 1 < len(lines) and code[k + 1] == is_code:
            k += 1
        run = "\n".join(lines[st:k + 1])
        if is_code:
            add(run, False)
        else:
            words(run)
        k += 1
    return out


def _diff(a: list[_Tok], b: list[_Tok]) -> list[tuple[int, _Tok]]:
    """The diff of two token lists as ops: 0 keep, 1 delete (old), 2 insert
    (new), with their tokens. LCS over token text; ties prefer the
    deletion."""
    n, m = len(a), len(b)
    l = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n - 1, -1, -1):
        for j in range(m - 1, -1, -1):
            if a[i].text == b[j].text:
                l[i][j] = l[i + 1][j + 1] + 1
            else:
                l[i][j] = l[i + 1][j] if l[i + 1][j] >= l[i][j + 1] else l[i][j + 1]
    ops: list[tuple[int, _Tok]] = []
    i = j = 0
    while i < n or j < m:
        if i < n and j < m and a[i].text == b[j].text:
            ops.append((0, a[i]))
            i += 1
            j += 1
        elif j >= m or (i < n and l[i + 1][j] >= l[i][j + 1]):
            ops.append((1, a[i]))
            i += 1
        else:
            ops.append((2, b[j]))
            j += 1
    return ops


def _trim_ws(s: str) -> str:
    """*s* with its leading and trailing whitespace removed (spaces, tabs,
    newlines)."""
    a, b = 0, len(s)
    while a < b and _is_ws(s[a]):
        a += 1
    while b > a and _is_ws(s[b - 1]):
        b -= 1
    return s[a:b]


def _trim_left(s: str) -> str:
    a = 0
    while a < len(s) and s[a] in _WS:
        a += 1
    return s[a:]


def _markup(o: str, n: str) -> str:
    """The markup for one region whose old text is *o* and new text is *n*
    (both trimmed, not both empty)."""
    if o == "":
        return f"{{++ {n} ++}}"
    if n == "":
        return f"{{-- {o} --}}"
    return f"{{~~ {o} ~> {n} ~~}}"


def _emit_region(
    ops: list[tuple[int, _Tok]],
    r0: int,
    r1: int,
    old_before: str,
    new_before: str,
    old_after: str,
    new_after: str,
) -> Optional[str]:
    """The marked emission for the region [r0, r1) of *ops*, with the old and
    the new text around it, or ``None`` when no mark round-trips there."""
    o: list[str] = []
    nn: list[str] = []
    for k in range(r0, r1):
        kind, t = ops[k]
        if kind != 2:
            o.append(t.text)
        if kind != 1:
            nn.append(t.text)
    os_, ns = "".join(o), "".join(nn)
    # Whitespace the two sides share at the edges stays outside the mark.
    lead = 0
    while (lead < len(os_) and lead < len(ns) and os_[lead] == ns[lead]
           and _is_ws(os_[lead])):
        lead += 1
    trail = 0
    while (trail < len(os_) - lead and trail < len(ns) - lead
           and os_[len(os_) - 1 - trail] == ns[len(ns) - 1 - trail]
           and _is_ws(os_[len(os_) - 1 - trail])):
        trail += 1
    oi = os_[lead:len(os_) - trail]
    ni = ns[lead:len(ns) - trail]
    # The mark's content is trimmed when read, so it must already be trimmed;
    # the whitespace still differing is placed outside, on the side whose text
    # keeps it, and the tidy rules then have to restore the other side.
    ot, nt = _trim_ws(oi), _trim_ws(ni)
    if ot == "" and nt == "":
        return None
    pre = os_[:lead]
    post = os_[len(os_) - trail:]

    def lead_ws(x: str) -> str:
        return x[:len(x) - len(_trim_left(x))]

    def trail_ws(x: str) -> str:
        return x[len(_trim_right(x)):]

    candidates = [
        (lead_ws(ni), trail_ws(ni)),
        (lead_ws(oi), trail_ws(oi)),
        ("", ""),
        (lead_ws(ni), ""),
        ("", trail_ws(ni)),
    ]
    mk = _markup(ot, nt)
    for wl, wr in candidates:
        emission = f"{pre}{wl}{mk}{wr}{post}"
        acc = apply_inline_marks_text(f"{new_before}{emission}{new_after}", accept=True)
        rej = apply_inline_marks_text(f"{old_before}{emission}{old_after}", accept=False)
        if acc == f"{new_before}{ns}{new_after}" and rej == f"{old_before}{os_}{old_after}":
            return emission
    return None


def _mark_tokens(o: str, n: str, ob: str, nb: str, oa: str, na: str) -> Optional[str]:
    """Marks the token-level differences of *o* → *n*, where the text before
    them is *ob* (old) / *nb* (new) and after them *oa* / *na*. ``None`` when
    the marks do not round-trip."""
    ops = _diff(_tokens(o), _tokens(n))
    runs: list[tuple[int, int]] = []
    k = 0
    while k < len(ops):
        if ops[k][0] == 0:
            k += 1
            continue
        s = k
        while k < len(ops) and ops[k][0] != 0:
            k += 1
        runs.append((s, k))
    # Changes separated by at most two unchanged words are one mark.
    merged: list[tuple[int, int]] = []
    for r in runs:
        if merged:
            words = 0
            for q in range(merged[-1][1], r[0]):
                if not ops[q][1].space:
                    words += 1
            if words <= 2:
                merged[-1] = (merged[-1][0], r[1])
                continue
        merged.append(r)
    runs = merged

    def side(frm: int, to: int, skip: int) -> str:
        return "".join(ops[q][1].text for q in range(frm, to) if ops[q][0] != skip)

    # Left to right; a region that does not round-trip grows by one token on
    # each side and is tried again.
    out: list[str] = []
    end = len(ops)
    pos = 0
    ri = 0
    while ri < len(runs):
        r0, r1 = runs[ri]
        if r0 < pos:
            r0 = pos
        while True:
            emission = _emit_region(
                ops, r0, r1,
                ob + side(0, r0, 2),
                nb + side(0, r0, 1),
                side(r1, end, 2) + oa,
                side(r1, end, 1) + na,
            )
            if emission is not None or (r0 <= pos and r1 >= end):
                break
            if r0 > pos:
                r0 -= 1
            if r1 < end:
                r1 += 1
        if emission is None:
            return None
        out.append(side(pos, r0, 1))
        out.append(emission)
        pos = r1
        while ri + 1 < len(runs) and runs[ri + 1][1] <= pos:
            ri += 1
        ri += 1
    out.append(side(pos, end, 1))
    text = "".join(out)
    if (apply_inline_marks_text(f"{nb}{text}{na}", accept=True) != f"{nb}{n}{na}"
            or apply_inline_marks_text(f"{ob}{text}{oa}", accept=False) != f"{ob}{o}{oa}"):
        return None
    return text


def _line_mark(line: str, d: str) -> str:
    """A whole line marked as inserted (``++``) or deleted (``--``): its
    indentation stays outside the mark; a blank line stays blank."""
    body = _trim_left(line)
    if _trim(body) == "":
        return line
    indent = line[:len(line) - len(body)]
    return f"{indent}{{{d} {_trim_right(body)} {d}}}"


def mark_change_text(old_value: str, new_value: str) -> SpecMarkedChange:
    """*new_value* with its differences from *old_value* marked, so that
    accepting every mark gives exactly *new_value* and rejecting every mark
    exactly *old_value* (SOM §11.9.3). The diff runs by line, then by word
    inside a changed run of lines; words are never split, changes separated by
    at most two unchanged words are one mark, and nothing inside code is
    marked."""
    if old_value == new_value:
        return SpecMarkedChange(new_value, exact=True)
    ol, nl = old_value.split("\n"), new_value.split("\n")
    oc, nc = _code_lines(ol), _code_lines(nl)
    lops = _diff([_Tok(x, False) for x in ol], [_Tok(x, False) for x in nl])
    out: list[str] = []
    exact = True
    oi = ni = k = 0

    def join(ls: list[str]) -> str:
        return "\n".join(ls)

    def blank(x: str) -> bool:
        return _trim(x) == ""

    while k < len(lops):
        if lops[k][0] == 0:
            out.append(nl[ni])
            oi += 1
            ni += 1
            k += 1
            continue
        d0, n0 = oi, ni
        while k < len(lops) and lops[k][0] != 0:
            if lops[k][0] == 1:
                oi += 1
            else:
                ni += 1
            k += 1
        dele, ins = ol[d0:oi], nl[n0:ni]
        ob, oa = ol[:d0], ol[oi:]
        nb, na = nl[:n0], nl[ni:]
        emitted: Optional[list[str]] = None
        in_code = any(oc[d0:oi]) or any(nc[n0:ni])
        if not in_code:
            candidates: list[list[str]] = []
            if dele and ins:
                t = _mark_tokens(
                    join(dele),
                    join(ins),
                    f"{join(ob)}\n" if ob else "",
                    f"{join(nb)}\n" if nb else "",
                    f"\n{join(oa)}" if oa else "",
                    f"\n{join(na)}" if na else "",
                )
                if t is not None:
                    candidates.append(t.split("\n"))
            dm = [_line_mark(x, "--") for x in dele]
            im = [_line_mark(x, "++") for x in ins]
            candidates.append([*dm, *im])
            candidates.append([*(x for x in dm if not blank(x)), *im])
            candidates.append([*dm, *(x for x in im if not blank(x))])
            candidates.append([*(x for x in dm if not blank(x)),
                               *(x for x in im if not blank(x))])
            for e in candidates:
                if (apply_inline_marks_text(join([*nb, *e, *na]), accept=True) == new_value
                        and apply_inline_marks_text(join([*ob, *e, *oa]), accept=False)
                        == old_value):
                    emitted = e
                    break
        if emitted is None:
            exact = False
            out.extend(ins)
        else:
            out.extend(emitted)
    text = join(out)
    if exact and (apply_inline_marks_text(text, accept=True) != new_value
                  or apply_inline_marks_text(text, accept=False) != old_value):
        return SpecMarkedChange(new_value, exact=False)
    return SpecMarkedChange(text, exact=exact)
