"""Review annotations in content values (SOM §11.9): comment blocks, question
blocks and CriticMarkup inline marks, and the team-review notation built on
them (§11.9.8): attribution tokens, individual answers, conflict blocks and
``open:`` answers — a faithful port of
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
from typing import Any, Callable, Optional, Sequence

from .spec_document import SpecDocument
from .spec_validator import SpecValidationCode, SpecValidationError


class SpecReviewAnnotationKind(Enum):
    """The kinds of annotation (SOM §11.9): the three of §11.9.1–11.9.3 and
    the conflict block a team review adds (§11.9.8)."""

    #: A reviewer's comment block, ``> ⬆️ **C-12** (Alexis): …``.
    COMMENT = "comment"
    #: One question of a question block, ``> **❓ BQ-81 — topic:** …``.
    QUESTION = "question"
    #: A CriticMarkup inline mark.
    MARK = "mark"
    #: A conflict block, ``> ⚖️ **X-3 — Conflicting changes:** …`` (SOM §11.9.8).
    CONFLICT = "conflict"


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
class SpecQuestionOption:
    """One option of a question (SOM §11.9.2): ``- (a) text``, or
    ``- **(b)** text`` for the recommended one."""

    #: The lowercase letter.
    letter: str
    #: The option's text, its continuation lines joined with one space.
    text: str
    #: Whether the option is written bold — the recommended one.
    bold: bool = False

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"letter": self.letter, "text": self.text, "bold": self.bold}


@dataclass(frozen=True)
class SpecParagraph:
    """One paragraph of a value (SOM §11.9.1, "Paragraphs"): a run of
    non-blank lines, where a blank line inside fenced code does not end the
    run. Its ``index`` is what ``after_paragraph`` of the inserts takes."""

    #: The 0-based position among the value's paragraphs.
    index: int
    #: The 0-based first line within the value.
    start_line: int
    #: The 0-based last line within the value (inclusive).
    end_line: int
    #: The paragraph's lines, verbatim, joined with ``\n``.
    text: str
    #: ``comment``, ``question`` or ``conflict`` when the paragraph opens
    #: with an annotation block of that kind, else None.
    annotation: Optional[str] = None

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "index": self.index,
            "startLine": self.start_line,
            "endLine": self.end_line,
            "text": self.text,
            "annotation": self.annotation,
        }


class SpecVote(Enum):
    """A reviewer's vote on a mark someone else proposed (SOM §11.9.8):
    ``+id`` accepts it, ``-id`` rejects it."""

    #: ``+<id>``: the reviewer takes the change.
    ACCEPT = "accept"
    #: ``-<id>``: the reviewer undoes the change.
    REJECT = "reject"


@dataclass(frozen=True)
class SpecMarkVote:
    """One reviewer's vote on a mark someone else proposed (SOM §11.9.8)."""

    #: The voter's member id.
    member: str
    #: ``ACCEPT`` (``+id``) or ``REJECT`` (``-id``).
    vote: SpecVote

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"member": self.member, "vote": self.vote.value}


@dataclass(frozen=True)
class SpecIndividualAnswer:
    """One line of individual answers, ``**Answer (alice, bob):** (a)``
    (SOM §11.9.8)."""

    #: The members who gave this answer, in the order written.
    members: tuple[str, ...]
    #: The answer, trimmed.
    answer: str

    @property
    def answer_letter(self) -> Optional[str]:
        """The letter the answer starts with (``(a)`` or ``**(a)**``), or
        ``None``."""
        return _leading_letter(self.answer)

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "members": list(self.members),
            "answer": self.answer,
            "answerLetter": self.answer_letter,
        }


@dataclass(frozen=True)
class SpecConflictAlternative:
    """One lettered alternative of a conflict block, ``- (a) **alice:** text``
    (SOM §11.9.8)."""

    #: The lowercase letter.
    letter: str
    #: The members who made this change.
    members: tuple[str, ...]
    #: The alternative's text; its continuation lines kept as lines.
    text: str

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"letter": self.letter, "members": list(self.members), "text": self.text}


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
    #: A question's team answer, trimmed; empty when open. For a conflict,
    #: its decision.
    answer: str = ""
    #: A question's options, in order (empty when it states none).
    options: tuple[SpecQuestionOption, ...] = ()
    #: A question's recommended letter: the bold option, else the option that
    #: says "recommended", else the letter of a ``*Recommendation:*`` line.
    recommended: Optional[str] = None
    #: A mark's kind.
    mark_kind: Optional[SpecMarkKind] = None
    #: A substitution's new text.
    new_text: Optional[str] = None
    #: The comment of a comment mark, or of a highlight followed by one.
    comment: Optional[str] = None
    #: A mark's authors from its attribution token; empty without one.
    authors: tuple[str, ...] = ()
    #: A mark's votes from its attribution token; empty without one.
    votes: tuple[SpecMarkVote, ...] = ()
    #: A question's individual answers, in the order written.
    answers: tuple[SpecIndividualAnswer, ...] = ()
    #: A conflict's ``(base)`` text.
    base: str = ""
    #: A conflict's lettered alternatives.
    alternatives: tuple[SpecConflictAlternative, ...] = ()

    @property
    def open(self) -> bool:
        """Whether a question is still open (no team answer written), or a
        conflict (no decision written)."""
        return (
            self.kind in (SpecReviewAnnotationKind.QUESTION, SpecReviewAnnotationKind.CONFLICT)
            and self.answer == ""
        )

    @property
    def unresolved(self) -> bool:
        """Whether a question's team answer or a conflict's decision begins
        with ``open:`` — answered for a gate, but handed back (SOM §11.9.8)."""
        return _is_unresolved(self.answer)

    @property
    def answer_letter(self) -> Optional[str]:
        """The letter a question's team answer starts with (``(b)`` or
        ``**(b)**``), or ``None``; ``None`` too for an unresolved answer."""
        if self.kind is not SpecReviewAnnotationKind.QUESTION or self.unresolved:
            return None
        return _leading_letter(self.answer)

    @property
    def decision_letter(self) -> Optional[str]:
        """A conflict's decision letter: ``a``…, ``base``, or ``None`` for
        rewritten text or none."""
        if self.kind is not SpecReviewAnnotationKind.CONFLICT:
            return None
        return _decision_letter(self.answer)

    def to_json(self, team: bool = False) -> dict[str, Any]:
        """The canonical JSON form the conformance corpus pins. *team* adds
        the members of the team form ``team_annotation_cases.json`` pins (SOM
        §11.9.8): a mark's ``authors`` and ``votes``, a question's
        ``unresolved`` and ``answers``. Without it the form is the one of
        §11.9.1–11.9.7 the older case files pin."""
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
            out: dict[str, Any] = {
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
            if team:
                out["unresolved"] = self.unresolved
            out["options"] = [o.to_json() for o in self.options]
            out["recommended"] = self.recommended
            out["answerLetter"] = self.answer_letter
            if team:
                out["answers"] = [a.to_json() for a in self.answers]
            return out
        if self.kind is SpecReviewAnnotationKind.CONFLICT:
            return {
                "kind": "conflict",
                "path": self.path,
                "field": self.field,
                "line": self.line,
                "id": self.id,
                "qualifiedId": self.qualified_id,
                "topic": self.topic,
                "text": self.text,
                "base": self.base,
                "alternatives": [a.to_json() for a in self.alternatives],
                "decision": self.answer,
                "decisionLetter": self.decision_letter,
                "open": self.open,
                "unresolved": self.unresolved,
            }
        assert self.mark_kind is not None
        out = {
            "kind": "mark",
            "path": self.path,
            "field": self.field,
            "line": self.line,
            "markKind": self.mark_kind.value,
            "text": self.text,
            "newText": self.new_text,
            "comment": self.comment,
        }
        if team:
            out["authors"] = list(self.authors)
            out["votes"] = [v.to_json() for v in self.votes]
        return out


@dataclass(frozen=True)
class SpecReviewAnnotationCounts:
    """The counts a report needs (SOM §11.9)."""

    questions: int = 0
    open_questions: int = 0
    answered_questions: int = 0
    comments: int = 0
    marks: int = 0
    #: Questions whose team answer begins ``open:`` (also counted as answered).
    unresolved_questions: int = 0
    #: Conflict blocks.
    conflicts: int = 0
    #: Conflict blocks without a decision.
    open_conflicts: int = 0

    def to_json(self, team: bool = False) -> dict[str, int]:
        """The canonical JSON form; *team* adds the three team counts
        (SOM §11.9.8)."""
        out = {
            "questions": self.questions,
            "openQuestions": self.open_questions,
            "answeredQuestions": self.answered_questions,
            "comments": self.comments,
            "marks": self.marks,
        }
        if team:
            out["unresolvedQuestions"] = self.unresolved_questions
            out["conflicts"] = self.conflicts
            out["openConflicts"] = self.open_conflicts
        return out


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
    #: The recommended option's letter; that option is written bold.
    recommended: Optional[str] = None

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
            recommended=j.get("recommended"),
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
    #: The authors its attribution token names (SOM §11.9.8); empty without
    #: one.
    authors: tuple[str, ...] = ()
    #: The votes its attribution token records; empty without one.
    votes: tuple[SpecMarkVote, ...] = ()
    #: A change comment's quote (SOM §11.9.3): ``kind``, ``oldText``,
    #: ``newText`` and ``outcome``; ``None`` for any other mark. Its
    #: :attr:`comment` is the text after the quote.
    quoted_change: Optional[dict[str, Any]] = None
    #: A change's attached comment, by id; ``None`` without one.
    comment_id: Optional[str] = None
    #: The change an attached change comment is about, by id; ``None``
    #: otherwise.
    change_id: Optional[str] = None

    def to_json(self, team: bool = False) -> dict[str, Any]:
        """The canonical JSON form the conformance corpus pins; *team* adds
        the mark's ``authors`` and ``votes`` (SOM §11.9.8). ``quotedChange``,
        ``commentId`` and ``changeId`` appear only on the marks they
        describe."""
        out: dict[str, Any] = {
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
        if self.quoted_change is not None:
            out["quotedChange"] = dict(self.quoted_change)
        if self.comment_id is not None:
            out["commentId"] = self.comment_id
        if self.change_id is not None:
            out["changeId"] = self.change_id
        if team:
            out["authors"] = list(self.authors)
            out["votes"] = [v.to_json() for v in self.votes]
        return out


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
class SpecConflictOutcome:
    """What ``remove_all_annotations`` did with one conflict block
    (SOM §11.9.8)."""

    #: The conflict id, ``X-<n>``.
    id: str
    #: The value's path.
    path: str
    #: The form field, or ``None`` for content.
    field: Optional[str]
    #: The 0-based line within the value where the block opened.
    line: int
    #: The decision as written.
    decision: str
    #: The text the decision chose.
    result: str

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "id": self.id,
            "path": self.path,
            "field": self.field,
            "line": self.line,
            "decision": self.decision,
            "result": self.result,
        }


@dataclass(frozen=True)
class SpecMarkReport:
    """The report of a mark operation, for the decision log."""

    #: What was done, in document order.
    applied: tuple[SpecMarkOutcome, ...] = ()
    #: Malformed marks in scope, left as written.
    malformed: tuple[SpecMarkIssue, ...] = ()
    #: The conflicts ``remove_all_annotations`` applied, in document order;
    #: ``None`` for the mark operations, which do not touch conflicts.
    conflicts: Optional[tuple[SpecConflictOutcome, ...]] = None

    def to_json(self, team: bool = False) -> dict[str, Any]:
        """The canonical JSON form; *team* adds the applied ``conflicts`` of
        a removal (SOM §11.9.8)."""
        out: dict[str, Any] = {
            "applied": [a.to_json() for a in self.applied],
            "malformed": [m.to_json() for m in self.malformed],
        }
        if team and self.conflicts is not None:
            out["conflicts"] = [c.to_json() for c in self.conflicts]
        return out


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

_SCALES = "⚖"
_DECISION_LABEL = "**Decision:**"
_UNRESOLVED_PREFIX = "open:"

_COMMENT_ID = re.compile(r"[1-9][0-9]*")
_QUESTION_ID = re.compile(r"[A-Z][A-Z0-9]*-[0-9]+")
#: The start of an individual answer line, ``**Answer (alice, bob):**``.
_INDIVIDUAL_ANSWER = re.compile(r"\*\*Answer \(([^)]*)\):\*\*")
#: A member id (SOM §11.9.8): lowercase letters, digits and ``_``.
_MEMBER_ID = re.compile(r"[a-z0-9_]+")


def is_review_member_id(s: str) -> bool:
    """Whether *s* is a member id (SOM §11.9.8): lowercase letters, digits
    and ``_``."""
    return _MEMBER_ID.fullmatch(s) is not None


def _is_unresolved(answer: str) -> bool:
    return answer.startswith(_UNRESOLVED_PREFIX)


def _decision_letter(decision: str) -> Optional[str]:
    """A conflict decision's letter: ``a``…, ``base``, or ``None`` (rewritten
    text or none)."""
    t = _trim_left(decision)
    if t.startswith("(base)") or t.startswith("**(base)**"):
        return "base"
    return None if _is_unresolved(t) else _leading_letter(t)

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
    conflict: Optional["_Conflict"] = None


@dataclass
class _IndividualAnswer:
    """One ``**Answer (<ids>):**`` entry of a question (SOM §11.9.8)."""

    line: int  # value line of the `**Answer (…):**` line
    end: int  # last value line of the entry with text (inclusive)
    members: list[str]
    answer: str


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
    options: tuple[SpecQuestionOption, ...] = ()
    recommended: Optional[str] = None
    answers: list[_IndividualAnswer] = dc_field(default_factory=list)


@dataclass(eq=False)
class _Conflict:
    """One parsed conflict block (SOM §11.9.8)."""

    block: _Block
    #: ``None`` when the header is malformed: the block is then not listed.
    id: Optional[str]
    topic: str
    text: str
    #: The ``(base)`` text, or ``None`` when the block has none.
    base: Optional[str] = None
    alternatives: list[SpecConflictAlternative] = dc_field(default_factory=list)
    decision: str = ""


def _is_letter(c: str) -> bool:
    return len(c) == 1 and "a" <= c <= "z"


def _parse_options(
    lines: list[str],
) -> tuple[tuple[SpecQuestionOption, ...], Optional[str]]:
    """The options of a question and its recommended letter (SOM §11.9.2): one
    option per line, ``- (a) …``, the recommended one bold, ``- **(b)** …``.
    The recommended letter is the first bold option's; else the first
    option's whose text says "recommended"; else the letter a
    ``*Recommendation:*`` line names; else none."""
    options: list[SpecQuestionOption] = []
    letter: Optional[str] = None
    text = ""
    bold = False

    def close() -> None:
        nonlocal letter
        if letter is not None:
            options.append(SpecQuestionOption(letter, _trim(text), bold))
        letter = None

    for l in lines:
        if l.startswith("- "):
            r = l[2:]
            if (
                len(r) >= 7
                and r.startswith("**(")
                and _is_letter(r[3])
                and r[4:7] == ")**"
            ):
                close()
                letter, text, bold = r[3], r[7:], True
                continue
            if len(r) >= 3 and r[0] == "(" and _is_letter(r[1]) and r[2] == ")":
                close()
                letter, text, bold = r[1], r[3:], False
                continue
        if letter is not None and l.startswith(" ") and _trim(l) != "":
            text = f"{_trim(text)} {_trim(l)}"
            continue
        close()
    close()
    result = tuple(options)
    for o in options:
        if o.bold:
            return (result, o.letter)
    for o in options:
        if "recommended" in o.text.lower():
            return (result, o.letter)
    label = "*Recommendation:*"
    for l in lines:
        i = l.find(label)
        if i < 0:
            continue
        x = _leading_letter(l[i + len(label):])
        if x is not None:
            return (result, x)
    return (result, None)


def _leading_letter(s: str) -> Optional[str]:
    """The letter of a leading ``(x)`` or ``**(x)**`` in ``s`` (spaces
    skipped)."""
    a = 0
    while a < len(s) and s[a] in _WS:
        a += 1
    t = s[a:]
    if t.startswith("**"):
        t = t[2:]
    if len(t) >= 3 and t[0] == "(" and _is_letter(t[1]) and t[2] == ")":
        return t[1]
    return None


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
    points — never exported). ``end`` lies after the attribution token when
    the mark has one, ``body_end`` always right after the mark itself, so the
    token can be rewritten in place."""

    start: int
    end: int
    line: int
    kind: SpecMarkKind
    text: str
    new_text: Optional[str]
    comment: Optional[str]
    body_end: int = -1
    authors: tuple[str, ...] = ()
    votes: tuple[SpecMarkVote, ...] = ()
    #: A comment mark's quote of a change (SOM §11.9.3), or ``None``.
    quote: "Optional[_Quote]" = None
    #: The index (among the value's marks) of the change this change comment
    #: is attached to, or ``None``.
    change_index: Optional[int] = None
    #: The index of this change's attached comment, or ``None``.
    comment_index: Optional[int] = None

    def __post_init__(self) -> None:
        if self.body_end < 0:
            self.body_end = self.end


@dataclass(frozen=True)
class _Quote:
    """The quote a change comment opens with (SOM §11.9.3); offsets are into
    the value."""

    kind: SpecMarkKind
    old_text: str
    new_text: str
    #: ``accepted``, ``rejected``, or ``None`` while the change is open.
    outcome: Optional[str]
    #: Right after the quote's closing delimiter.
    delim_end: int
    #: Right after the quote's ``]``.
    end: int
    #: The comment: the text after the quote, trimmed.
    comment: str

    def to_json(self) -> dict[str, Any]:
        return {
            "kind": self.kind.value,
            "oldText": self.old_text,
            "newText": self.new_text,
            "outcome": self.outcome,
        }


_QUOTE_KINDS = {
    "++": SpecMarkKind.INSERTION,
    "--": SpecMarkKind.DELETION,
    "~~": SpecMarkKind.SUBSTITUTION,
}


def _read_quote(s: str, at: int) -> "_Quote | str | None":
    """Reads the quote at the start of a comment mark's inner text *s*, whose
    first character is at value offset *at*: the quote, ``None`` when *s*
    opens no quote, or the issue (``unclosed``, ``noArrow``) of one that is
    malformed."""
    a = 0
    while a < len(s) and s[a] in " \t\r\n":
        a += 1
    if a + 3 > len(s) or s[a] != "[":
        return None
    d = s[a + 1:a + 3]
    kind = _QUOTE_KINDS.get(d)
    if kind is None:
        return None
    j = s.find(d, a + 3)
    while j >= 0:
        t = j + 2
        while t < len(s) and _is_space(s[t]):
            t += 1
        outcome: Optional[str] = None
        close = -1
        if t < len(s) and s[t] == "]":
            close = t
        elif t < len(s) and s[t] == "|":
            t += 1
            while t < len(s) and _is_space(s[t]):
                t += 1
            for w in ("accepted", "rejected"):
                if not s.startswith(w, t):
                    continue
                u = t + len(w)
                while u < len(s) and _is_space(s[u]):
                    u += 1
                if u < len(s) and s[u] == "]":
                    outcome = w
                    close = u
                break
        if close >= 0:
            body = s[a + 3:j]
            old_text = ""
            new_text = ""
            if kind is SpecMarkKind.INSERTION:
                new_text = _trim(body)
            elif kind is SpecMarkKind.DELETION:
                old_text = _trim(body)
            else:
                arrow = body.find("~>")
                if arrow < 0:
                    return "noArrow"
                old_text = _trim(body[:arrow])
                new_text = _trim(body[arrow + 2:])
            return _Quote(
                kind,
                old_text,
                new_text,
                outcome,
                at + j + 2,
                at + close + 1,
                _trim(s[close + 1:]),
            )
        j = s.find(d, j + 1)
    return "unclosed"


def _attach_change_comments(marks: "list[_Mark]") -> None:
    """Links each change comment to the change written directly before it
    whose kind and texts it quotes (SOM §11.9.3)."""
    for k in range(1, len(marks)):
        q = marks[k].quote
        c = marks[k - 1]
        if q is None or q.outcome is not None or not _is_change_mark(c.kind):
            continue
        if c.end != marks[k].start or c.kind is not q.kind:
            continue
        if (
            _mark_replacement(c, False) != q.old_text
            or _mark_replacement(c, True) != q.new_text
        ):
            continue
        marks[k].change_index = k - 1
        c.comment_index = k


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
        elif first.startswith(_SCALES):
            b = _Block(s, e, SpecReviewAnnotationKind.CONFLICT)
            p.blocks.append(b)
            b.conflict = _parse_conflict(p, b)
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
        if (
            t.startswith(_QUESTION_OPEN)
            or t.startswith(_ANSWER_LABEL)
            or _INDIVIDUAL_ANSWER.match(t)
        ):
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
        # Every `**Answer` line of the region: the individual ones and the
        # team's.
        answer_lines = [
            m
            for m in range(k + 1, region_end + 1)
            if inner[m].startswith(_ANSWER_LABEL) or _INDIVIDUAL_ANSWER.match(inner[m])
        ]

        def answer_end(m: int) -> int:
            """An answer runs to the next ``**Answer`` line or the end of the
            region."""
            return next((x - 1 for x in answer_lines if x > m), region_end)

        def answer_text_at(m: int, label: int) -> str:
            return _trim("\n".join([inner[m][label:], *inner[m + 1:answer_end(m) + 1]]))

        # The question's text ends before its first answer line of either kind.
        text_end = answer_lines[0] - 1 if answer_lines else region_end
        options, recommended = _parse_options(inner[k + 1:text_end + 1])
        text = _trim("\n".join([rest, *inner[k + 1:text_end + 1]]))
        answer: Optional[int] = None
        individual: list[_IndividualAnswer] = []
        answered: set[str] = set()
        for m in answer_lines:
            if inner[m].startswith(_ANSWER_LABEL):
                if answer is None:
                    answer = m
                continue
            match = _INDIVIDUAL_ANSWER.match(inner[m])
            assert match is not None
            members = [_trim(x) for x in match.group(1).split(",")]
            for member in members:
                if member in answered:
                    p.malformed.append(
                        f"line {b.start + m}: {member} already answered {qid}; a member "
                        "answers a question at most once (SOM §11.9.8)"
                    )
                answered.add(member)
            end = answer_end(m)
            while end > m and _trim(inner[end]) == "":
                end -= 1
            individual.append(
                _IndividualAnswer(
                    b.start + m, b.start + end, members, answer_text_at(m, len(match.group(0)))
                )
            )
        answer_text = "" if answer is None else answer_text_at(answer, len(_ANSWER_LABEL))
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
                options,
                recommended,
                individual,
            )
        )
    b.questions = out


#: ``- (base) …``: the base line of a conflict block.
_CONFLICT_BASE = re.compile(r"- \(base\)(?: (.*))?")
#: ``- (a) **alice, bob:** …``: a lettered alternative.
_CONFLICT_ALTERNATIVE = re.compile(r"- \(([a-z])\)(?: \*\*([^*]*):\*\*)?(?: (.*))?")
#: The header after the marker: ``**X-<n> — <topic>:** <text>``.
_CONFLICT_HEADER = re.compile(r"\*\*(X-[1-9][0-9]*) — (.+?):\*\*(?: (.*))?")


def _parse_conflict(p: _Parsed, b: _Block) -> _Conflict:
    """A conflict block (SOM §11.9.8): the header, the ``(base)`` line and
    the lettered alternatives — each continuing on lines indented under it,
    its line breaks kept — then ``**Decision:**``. A malformed header leaves
    the block unlisted; a missing base line or alternative is a finding."""
    inner = [_inner(p.lines[k]) for k in range(b.start, b.end + 1)]
    rest = inner[0][len(_SCALES):]
    if rest.startswith(_VS16):
        rest = rest[len(_VS16):]
    header = _CONFLICT_HEADER.fullmatch(_trim_left(rest))
    c = _Conflict(
        b,
        None if header is None else header.group(1),
        "" if header is None else header.group(2),
        "" if header is None else _trim(header.group(3) or ""),
    )
    if header is None:
        p.malformed.append(
            f'line {b.start}: conflict header is not "⚖️ **X-<n> — <topic>:**" '
            "(SOM §11.9.8)"
        )
    decision_line = next(
        (k for k in range(1, len(inner)) if inner[k].startswith(_DECISION_LABEL)), len(inner)
    )
    # The open entry: (letter or None for the base, members, lines).
    open_: Optional[tuple[Optional[str], list[str], list[str]]] = None

    def close() -> None:
        nonlocal open_
        if open_ is None:
            return
        letter, members, lines = open_
        text = _trim("\n".join(lines))
        if letter is None:
            c.base = text
        else:
            c.alternatives.append(SpecConflictAlternative(letter, tuple(members), text))
        open_ = None

    for k in range(1, decision_line):
        line = inner[k]
        base = _CONFLICT_BASE.fullmatch(line)
        alt = _CONFLICT_ALTERNATIVE.fullmatch(line) if base is None else None
        if base is not None:
            close()
            open_ = (None, [], [base.group(1) or ""])
        elif alt is not None:
            close()
            members = [_trim(x) for x in (alt.group(2) or "").split(",") if _trim(x) != ""]
            open_ = (alt.group(1), members, [alt.group(3) or ""])
        elif open_ is not None and line.startswith(" "):
            open_[2].append(line[2:] if line.startswith("  ") else _lstrip(line))
        else:
            close()
    close()
    if decision_line < len(inner):
        c.decision = _trim(
            "\n".join([inner[decision_line][len(_DECISION_LABEL):], *inner[decision_line + 1:]])
        )
    if header is not None and c.base is None:
        p.malformed.append(f'line {b.start}: conflict {c.id} has no "(base)" line (SOM §11.9.8)')
    if header is not None and not c.alternatives:
        p.malformed.append(
            f"line {b.start}: conflict {c.id} has no lettered alternative (SOM §11.9.8)"
        )
    return c


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
    _attach_change_comments(p.marks)


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
        if c == "{" and seg.startswith("{@", i):
            # A token that no mark precedes directly (a mark's own token is
            # read with the mark, below).
            p.malformed.append(
                f'line {line_of(base + i)}: an attribution token "{{@" does not follow '
                "a mark directly (SOM §11.9.8)"
            )
            close = seg.find("}", i + 2)
            i = i + 2 if close < 0 else close + 1
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
        before = len(p.marks)
        if opener == "{>>":
            cm = _Mark(base + i, base + end, line, SpecMarkKind.COMMENT, "", None, _trim(inner))
            q = _read_quote(inner, base + i + 3)
            if isinstance(q, _Quote):
                cm.quote = q
            elif q == "unclosed":
                p.malformed.append(
                    f"line {line}: the quote of a change comment is not closed; "
                    "it is read as a plain comment (SOM §11.9.3)"
                )
            elif q == "noArrow":
                p.malformed.append(
                    f'line {line}: the quote of a change comment has no "~>"; '
                    "it is read as a plain comment (SOM §11.9.3)"
                )
            p.marks.append(cm)
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
        if len(p.marks) > before and seg.startswith("{@", end):
            end = _attach_token(p, seg, end, base, p.marks[-1])
        i = end


def _attach_token(p: _Parsed, seg: str, at: int, base: int, m: _Mark) -> int:
    """Reads the attribution token ``{@…}`` at *at* (SOM §11.9.8) into *m*,
    which it directly follows, and returns the segment offset after it. The
    token is part of the mark — its markup, its decision — so ``m.end``
    moves past it. A token that breaks the grammar is still part of the mark
    (it goes with the mark on a decision) and is a finding; its members are
    then not listed."""
    line_end = seg.find("\n", at)
    close = seg.find("}", at + 2)
    if close < 0 or (line_end >= 0 and close > line_end):
        p.malformed.append(f'line {m.line}: attribution token "{{@" is not closed (SOM §11.9.8)')
        return at
    reason, authors, votes = _read_token(seg[at + 2:close], m.kind)
    if reason is not None:
        p.malformed.append(f"line {m.line}: attribution token {reason} (SOM §11.9.8)")
    else:
        m.authors = authors
        m.votes = votes
    m.end = base + close + 1
    return close + 1


def _is_change_mark(kind: SpecMarkKind) -> bool:
    """Whether a mark kind is a change, which alone takes votes
    (SOM §11.9.8)."""
    return kind in (SpecMarkKind.INSERTION, SpecMarkKind.DELETION, SpecMarkKind.SUBSTITUTION)


def _read_token(
    inside: str, kind: SpecMarkKind
) -> tuple[Optional[str], tuple[str, ...], tuple[SpecMarkVote, ...]]:
    """The members of a token's inside, ``<authors>[ <votes>]``, or (as the
    first member) the reason it breaks the grammar of SOM §11.9.8."""
    words = [w for w in re.split(r"\s+", _trim(re.sub(r",\s+", ",", inside))) if w != ""]
    if not words:
        return ("is empty", (), ())
    authors: list[str] = []
    votes: list[SpecMarkVote] = []
    k = 0
    if not words[0].startswith("+") and not words[0].startswith("-"):
        authors.extend(words[0].split(","))
        k = 1
    for w in words[k:]:
        if not w.startswith("+") and not w.startswith("-"):
            return (f'has "{w}" where a vote belongs', (), ())
        vote = SpecVote.ACCEPT if w.startswith("+") else SpecVote.REJECT
        votes.append(SpecMarkVote(w[1:], vote))
    seen: set[str] = set()
    for i in [*authors, *(v.member for v in votes)]:
        if not is_review_member_id(i):
            return (f'names "{i}", which is not a member id', (), ())
        if i in seen:
            return (f"names {i} twice, or as author and voter", (), ())
        seen.add(i)
    if votes and not _is_change_mark(kind):
        return (f"carries votes on a {kind.value} mark, which takes authors only", (), ())
    return (None, tuple(authors), tuple(votes))


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
        elif b.kind is SpecReviewAnnotationKind.CONFLICT:
            x = b.conflict
            assert x is not None
            if x.id is None:
                continue
            out.append((
                b.start,
                0,
                seq,
                SpecReviewAnnotation(
                    kind=SpecReviewAnnotationKind.CONFLICT,
                    path=path,
                    field=field,
                    line=b.start,
                    id=x.id,
                    qualified_id=None if qualifier is None else f"{qualifier} {x.id}",
                    topic=x.topic,
                    text=x.text,
                    base=x.base or "",
                    alternatives=tuple(x.alternatives),
                    answer=x.decision,
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
                        options=q.options,
                        recommended=q.recommended,
                        answers=tuple(
                            SpecIndividualAnswer(tuple(a.members), a.answer) for a in q.answers
                        ),
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
                authors=m.authors,
                votes=m.votes,
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
        *[
            f"> - **({q.recommended})**{o[3:]}"
            if q.recommended is not None and o.startswith(f"({q.recommended})")
            else f"> - {o}"
            for o in q.options
        ],
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


def decide_all_marks_text(value: str, accept: bool) -> str:
    """*value* with every inline mark accepted (*accept*) or rejected, as
    accept all / reject all write it (SOM §11.9.3): change comments stay, an
    attached one records the outcome; every other highlight and comment mark
    is removed. Marks in code and malformed marks stay as written."""
    marks = _parse(value).marks
    v = value
    for k in range(len(marks) - 1, -1, -1):
        if marks[k].quote is not None:
            continue
        v = _decide_mark(v, marks, k, accept)
    return v


def _decide_mark(value: str, marks: "list[_Mark]", k: int, accept: bool) -> str:
    """*value* with the mark *k* of *marks* decided; a change's attached
    comment records the outcome (SOM §11.9.3)."""
    m = marks[k]
    v = value
    ci = m.comment_index
    if ci is not None:
        q = marks[ci].quote
        assert q is not None
        v = _record_outcome(v, q, accept)
    return _replace_mark(v, m, _mark_replacement(m, accept))


def _record_outcome(value: str, q: _Quote, accept: bool) -> str:
    """*value* with the outcome written into the quote *q*: everything from
    its closing delimiter to its ``]`` becomes `` | accepted]`` or
    `` | rejected]``."""
    return (
        value[:q.delim_end]
        + f" | {'accepted' if accept else 'rejected'}]"
        + value[q.end:]
    )


_BLANK_LINE_IN = re.compile(r"\n[ \t\r]*\n")


def _check_inline_comment(text: str) -> str:
    """The trimmed *text* of an inline comment, refused when it is empty or
    holds a mark delimiter or a blank line."""
    t = _trim(text)
    if t == "":
        raise SpecReviewAnnotationError("a comment needs text")
    if any(o in t for o in (*_OPENERS, "<<}")) or _BLANK_LINE_IN.search(t):
        raise SpecReviewAnnotationError(
            "a comment cannot hold a mark delimiter or a blank line"
        )
    return t


def _is_anchor_space(c: str) -> bool:
    """The whitespace of the change-comment anchors (SOM §11.9.3)."""
    return c in (" ", "\t", "\r", "\n")


def _non_space_count(s: str) -> int:
    return sum(1 for c in s if not _is_anchor_space(c))


def _mark_keeping_change_comments(current: str, text: str) -> "SpecMarkedChange":
    """``set_marked`` with the value's change comments kept (SOM §11.9.3):
    taken out of the original, then written back where their anchor
    falls."""
    # 1. The original: every mark rejected except the change comments.
    original = current
    marks = _parse(current).marks
    for k in range(len(marks) - 1, -1, -1):
        if marks[k].quote is not None:
            continue
        original = _replace_mark(original, marks[k], _mark_replacement(marks[k], False))
    # 2. Each change comment's markup, anchor and leading space.
    kept = [m for m in _parse(original).marks if m.quote is not None]
    anchors: list[tuple[str, int, bool]] = []
    counted = 0
    frm = 0
    for m in kept:
        counted += _non_space_count(original[frm:m.start])
        frm = m.end
        anchors.append(
            (
                original[m.start:m.end],
                counted,
                m.start > 0 and _is_space(original[m.start - 1]),
            )
        )
    # 3. Removed, compared.
    base = original
    for m in reversed(kept):
        base = _replace_mark(base, m, "")
    result = mark_change_text(base, text)
    if not anchors:
        return result
    # 4. Written back where k non-whitespace characters have passed.
    r = result.text
    rm = _parse(r).marks

    def place(k: int) -> int:
        if k == 0:
            return 0
        n = 0
        i = 0
        mi = 0
        while i < len(r):
            if mi < len(rm) and rm[mi].start == i:
                m = rm[mi]
                mi += 1
                n += 0 if m.kind is SpecMarkKind.INSERTION else _non_space_count(m.text)
                i = m.end
                if n >= k:
                    return i
                continue
            if not _is_anchor_space(r[i]):
                n += 1
            i += 1
            if n >= k:
                return i
        return len(r)

    at = [place(a[1]) for a in anchors]
    out = r
    for j in range(len(anchors) - 1, -1, -1):
        markup, _, space = anchors[j]
        out = out[:at[j]] + (" " if space else "") + markup + out[at[j]:]
    return SpecMarkedChange(out, exact=result.exact)


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
# Team reviews (SOM §11.9.8): individual answers and applying conflicts.
# ---------------------------------------------------------------------------


def _is_commented_answer(answer: str, options: tuple[SpecQuestionOption, ...]) -> bool:
    """Whether an answer carries anything beyond an option letter
    (SOM §11.9.8): such a commented answer always gets a line of its own."""
    letter = _leading_letter(answer)
    if letter is None:
        return True
    t = _trim_left(answer)
    bold = t.startswith("**(") and t[4:7] == ")**"
    rest = _trim(t[7 if bold else (5 if t.startswith("**") else 3):])
    if rest == "":
        return False
    option = next((o for o in options if o.letter == letter), None)
    return option is None or rest != option.text


def _individual_answer_lines(members: list[str], answer: str) -> list[str]:
    """The lines of one individual-answer entry."""
    a = answer.split("\n")
    return [_trim_right(f"> **Answer ({', '.join(members)}):** {a[0]}"), *_quoted(a[1:])]


@dataclass
class _AnswerEntry:
    """One individual-answer entry while :func:`_set_individual_answer`
    regroups them; *lines* are its bytes as written, ``None`` once it has to
    be written anew."""

    members: list[str]
    answer: str
    lines: Optional[list[str]]


def _set_individual_answer(value: str, q: _Question, member: str, answer: str) -> str:
    """*value* with member *member*'s individual answer to question *q* set
    to *answer* (SOM §11.9.8): the member leaves the line it was on (a line
    left empty goes); a non-empty answer that is not commented joins the line
    whose answer is identical and not commented, at its end, and otherwise
    gets a new line after the last individual answer. The first individual
    answer opens the run before the team's ``**Answer:**``, with a ``>`` line
    between run and team answer, and a run left empty takes that line with
    it. Entries left alone keep their bytes."""
    lines = value.split("\n")
    entries = [_AnswerEntry(list(a.members), a.answer, lines[a.line:a.end + 1]) for a in q.answers]
    for e in entries:
        if member in e.members:
            e.members.remove(member)
            e.lines = None
    kept = [e for e in entries if e.members]
    text = _trim(answer)
    if text != "":
        join = (
            None
            if _is_commented_answer(text, q.options)
            else next(
                (
                    e
                    for e in kept
                    if e.answer == text and not _is_commented_answer(e.answer, q.options)
                ),
                None,
            )
        )
        if join is not None:
            join.members.append(member)
            join.lines = None
        else:
            kept.append(_AnswerEntry([member], text, None))
    run: list[str] = []
    for e in kept:
        if e.lines is not None:
            run.extend(e.lines)
        else:
            run.extend(_individual_answer_lines(e.members, e.answer))
    if q.answers:
        start = q.answers[0].line
        to = q.answers[-1].end
        # A run left empty takes its separating `>` line with it.
        if not run and to + 1 < len(lines) and _trim(_inner(lines[to + 1])) == "":
            to += 1
        lines[start:to + 1] = run
    elif run:
        if q.answer_line is not None:
            lines[q.answer_line:q.answer_line] = [*run, ">"]
        else:
            last = q.region_end
            while last > q.header and _trim(_inner(lines[last])) == "":
                last -= 1
            lines[last + 1:last + 1] = [">", *run]
    return "\n".join(lines)


#: Topics of the structural conflicts a merge writes (SOM §11.9.9); their
#: decisions are not text.
_STRUCTURAL_TOPICS = frozenset({"Item removed", "Item moved", "Headline changed"})


@dataclass
class _DecidedConflict:
    """A decided conflict, as ``remove_all_annotations`` found it before any
    change."""

    path: str
    field: Optional[str]
    #: The block's position among the value's conflict blocks.
    index: int
    id: str
    line: int
    decision: str


def _chosen_text(c: _Conflict) -> str:
    """The text a conflict's decision chooses: the base, an alternative, or
    the rewritten text."""
    letter = _decision_letter(c.decision)
    if letter == "base":
        return c.base or ""
    if letter is not None:
        return next(a for a in c.alternatives if a.letter == letter).text
    return c.decision


def _text_paragraphs(p: _Parsed) -> list[tuple[int, int]]:
    """The text paragraphs (no annotation block) of a parsed value, as
    (first, last) lines."""
    starts = {b.start for b in p.blocks}
    return [r for r in _paragraphs(p.lines, p.code) if r[0] not in starts]


def _replace_lines(value: str, s: int, e: int, text: str) -> str:
    """*value* with the lines [s, e] replaced by *text*."""
    lines = value.split("\n")
    lines[s:e + 1] = text.split("\n")
    return "\n".join(lines)


def _replace_paragraph_before(value: str, b: _Block, text: str) -> str:
    """*value* with the text paragraph directly before block *b* (annotation
    blocks between them skipped) replaced by *text*; with none, *text* goes
    before the block."""
    before = [r for r in _text_paragraphs(_parse(value)) if r[1] < b.start]
    if not before:
        return _insert_after_line(value, b.start - 1, text.split("\n"))
    s, e = before[-1]
    return _replace_lines(value, s, e, text)


def _replace_text_run(value: str, b: _Block, text: str) -> str:
    """*value* with the run of text paragraphs directly before block *b* — a
    whole-value unit (SOM §11.9.9) — replaced by *text*."""
    p = _parse(value)
    paras = [r for r in _paragraphs(p.lines, p.code) if r[1] < b.start]
    starts = {x.start for x in p.blocks}
    k = len(paras)
    while k > 0 and paras[k - 1][0] not in starts:
        k -= 1
    run = paras[k:]
    if not run:
        return _insert_after_line(value, b.start - 1, text.split("\n"))
    return _replace_lines(value, run[0][0], run[-1][1], text)


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
        q = open_ = unresolved = c = m = x = open_x = 0
        for a in self.list():
            if a.kind is SpecReviewAnnotationKind.QUESTION:
                q += 1
                if a.open:
                    open_ += 1
                if a.unresolved:
                    unresolved += 1
            elif a.kind is SpecReviewAnnotationKind.COMMENT:
                c += 1
            elif a.kind is SpecReviewAnnotationKind.CONFLICT:
                x += 1
                if a.open:
                    open_x += 1
            else:
                m += 1
        return SpecReviewAnnotationCounts(
            questions=q,
            open_questions=open_,
            answered_questions=q - open_,
            comments=c,
            marks=m,
            unresolved_questions=unresolved,
            conflicts=x,
            open_conflicts=open_x,
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

    def set_answer(self, question_id: str, answer: str, author: Optional[str] = None) -> None:
        """Writes *answer* after the question's ``**Answer:**`` (empty: reopens
        it). With *author*, writes that member's individual answer instead,
        grouped and placed by the rules of SOM §11.9.8 (empty: only takes the
        member out); an author that is not a member id is refused."""
        if author is not None and not is_review_member_id(author):
            raise SpecReviewAnnotationError(
                f'"{author}" is not a member id (lowercase letters, digits and _)'
            )
        path, field, text, _b, q = self._find_question(question_id)
        if author is not None:
            self._set(path, field, _set_individual_answer(text, q, author, answer))
            return
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
        self._set(path, field, _decide_mark(value, marks, index, accept))

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
            first = n + 1
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
                        comment=m.quote.comment if m.quote is not None else m.comment,
                        markup=text[m.start:m.end],
                        context="\n".join(p.lines[para[0]:para[1] + 1]),
                        authors=m.authors,
                        votes=m.votes,
                        quoted_change=None if m.quote is None else m.quote.to_json(),
                        comment_id=(
                            None if m.comment_index is None
                            else f"M-{first + m.comment_index}"
                        ),
                        change_id=(
                            None if m.change_index is None
                            else f"M-{first + m.change_index}"
                        ),
                    )
                )
        return out

    def _apply_marks(
        self,
        decide: "Callable[[str, _Mark], Optional[SpecMarkDecision]]",
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
            decided = [decide(ids[k], p.marks[k]) for k in range(len(p.marks))]

            def is_decided(k: int) -> bool:
                return decided[k] is not None and decided[k] is not SpecMarkDecision.LEAVE

            for k in range(len(p.marks) - 1, -1, -1):
                if not is_decided(k):
                    continue
                d = decided[k]
                assert d is not None
                m = p.marks[k]
                repl = _mark_replacement(m, d is SpecMarkDecision.ACCEPT)
                ci = m.comment_index
                if ci is not None and not is_decided(ci):
                    q = p.marks[ci].quote
                    assert q is not None
                    v = _record_outcome(v, q, d is SpecMarkDecision.ACCEPT)
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
        return self._apply_marks(lambda id, _m: decisions.get(id))

    def accept_all_marks(self, path: Optional[str] = None) -> SpecMarkReport:
        """Accepts every inline mark under *path* (``None``: the whole
        document), except change comments, which stay (SOM §11.9.3)."""
        return self._apply_marks(
            lambda _id, m: SpecMarkDecision.ACCEPT if m.quote is None else None,
            under=path,
        )

    def reject_all_marks(self, path: Optional[str] = None) -> SpecMarkReport:
        """Rejects every inline mark under *path* (``None``: the whole
        document), except change comments, which stay (SOM §11.9.3)."""
        return self._apply_marks(
            lambda _id, m: SpecMarkDecision.REJECT if m.quote is None else None,
            under=path,
        )

    def _find_mark(
        self, mark_id: str, revision: Optional[str]
    ) -> "tuple[str, Optional[str], str, _Parsed, int]":
        """The mark ``M-<n>`` *mark_id* with its value, refused when the
        document is no longer at *revision* (when given) or holds no such
        mark."""
        if revision is not None:
            current = self.revision()
            if revision != current:
                raise SpecReviewAnnotationError(
                    f"the document changed since revision {revision} (now {current}); "
                    "list the marks again"
                )
        n = 0
        for path, field, text in self._values():
            p = _parse(text)
            for k in range(len(p.marks)):
                n += 1
                if f"M-{n}" == mark_id:
                    return path, field, text, p, k
        raise SpecReviewAnnotationError(f"no inline mark {mark_id} in the document")

    def comment_change(
        self,
        mark_id: str,
        text: str,
        author: Optional[str] = None,
        revision: Optional[str] = None,
    ) -> str:
        """Writes a change comment (SOM §11.9.3) directly after the change
        mark *mark_id*, its quote written from the mark and *text* after it,
        with an attribution token ``{@author}`` when *author* is given, and
        returns the new comment's id. Refused — nothing changes — for an
        unknown id, a stale *revision*, a mark that is not a change or already
        has an attached comment, a change its quote cannot hold, a *text* that
        is empty or holds a mark delimiter or a blank line, and an *author*
        that is not a member id."""
        path, field, value, p, k = self._find_mark(mark_id, revision)
        m = p.marks[k]
        if not _is_change_mark(m.kind):
            raise SpecReviewAnnotationError(
                f"{mark_id} is a {m.kind.value} mark, not a change"
            )
        if m.comment_index is not None:
            raise SpecReviewAnnotationError(
                f"{mark_id} already has a comment; edit it instead"
            )
        comment = _check_inline_comment(text)
        if author is not None and not is_review_member_id(author):
            raise SpecReviewAnnotationError(f'"{author}" is not a member id')
        if m.kind is SpecMarkKind.INSERTION:
            d = "++"
        elif m.kind is SpecMarkKind.DELETION:
            d = "--"
        else:
            d = "~~"
        body = f"{m.text} ~> {m.new_text}" if m.kind is SpecMarkKind.SUBSTITUTION else m.text
        if f"{d}]" in body or "<<}" in body:
            raise SpecReviewAnnotationError(
                f'{mark_id} holds "{d}]" or "<<}}", which its quote cannot hold'
            )
        markup = f"{{>> [{d} {body} {d}] {comment} <<}}" + (
            "" if author is None else f"{{@{author}}}"
        )
        self._set(path, field, value[:m.end] + markup + value[m.end:])
        return f"M-{int(mark_id[2:]) + 1}"

    def edit_mark_comment(
        self, mark_id: str, text: str, revision: Optional[str] = None
    ) -> None:
        """Replaces the comment of the comment mark, change comment or
        commented highlight *mark_id* with *text* (SOM §11.9.3). A change
        comment keeps its quote as written, and the attribution token stays.
        Refused — nothing changes — for an unknown id, a stale *revision*, a
        mark that holds no comment, and a *text* that is empty or holds a mark
        delimiter or a blank line."""
        path, field, value, p, k = self._find_mark(mark_id, revision)
        m = p.marks[k]
        comment = _check_inline_comment(text)
        if m.kind is SpecMarkKind.COMMENT:
            q = m.quote
            opn = m.start + 3
            markup = (
                f"{{>> {comment} <<}}"
                if q is None
                else f"{{>> {_trim_left(value[opn:q.end])} {comment} <<}}"
            )
        elif m.kind is SpecMarkKind.HIGHLIGHT and m.comment is not None:
            markup = f"{{== {m.text} ==}}{{>> {comment} <<}}"
        else:
            raise SpecReviewAnnotationError(f"{mark_id} holds no comment")
        self._set(path, field, value[:m.start] + markup + value[m.body_end:])

    def remove_all_annotations(self) -> SpecMarkReport:
        """Removes every annotation and writes the result back: every inline
        mark accepted, every conflict's decision applied (SOM §11.9.8), every
        comment, question and conflict block removed. Malformed marks stay and
        are reported. Refused — nothing changes — while a conflict is open,
        unresolved (``open:``), malformed, or decided for a letter it has no
        alternative for."""
        decided = self._decided_conflicts()
        marks = self._apply_marks(lambda _id, _m: SpecMarkDecision.ACCEPT)
        outcomes: list[SpecConflictOutcome] = []
        for path, field, text in self._values():
            v = text
            here = [d for d in decided if d.path == path and d.field == field]
            if here:
                v = self._apply_conflicts(path, field, v, here, outcomes)
            while True:
                p = _parse(v)
                if not p.blocks:
                    break
                b = p.blocks[-1]
                v = _remove_lines(v, b.start, b.end)
            if v != text:
                self._set(path, field, v)
        return SpecMarkReport(
            applied=marks.applied, malformed=marks.malformed, conflicts=tuple(outcomes)
        )

    def _decided_conflicts(self) -> list[_DecidedConflict]:
        """Every conflict block of the document with the line it opens on, in
        document order — or the refusal of :meth:`remove_all_annotations`
        when one of them cannot be applied."""
        out: list[_DecidedConflict] = []
        for path, field, text in self._values():
            index = 0
            for b in _parse(text).blocks:
                if b.kind is not SpecReviewAnnotationKind.CONFLICT:
                    continue
                c = b.conflict
                assert c is not None
                where = f"{path}{'' if field is None else f' / {field}'}, line {b.start}"
                if c.id is None or c.base is None or not c.alternatives:
                    raise SpecReviewAnnotationError(
                        f"{where}: a malformed conflict block cannot be applied"
                    )
                if c.decision == "" or _is_unresolved(c.decision):
                    state = "open" if c.decision == "" else "unresolved"
                    raise SpecReviewAnnotationError(
                        f"{where}: conflict {c.id} is {state}; decide it before removing "
                        "the annotations"
                    )
                letter = _decision_letter(c.decision)
                if (
                    letter is not None
                    and letter != "base"
                    and not any(a.letter == letter for a in c.alternatives)
                ):
                    raise SpecReviewAnnotationError(
                        f"{where}: conflict {c.id} has no alternative ({letter})"
                    )
                out.append(_DecidedConflict(path, field, index, c.id, b.start, c.decision))
                index += 1
        return out

    def _apply_conflicts(
        self,
        path: str,
        field: Optional[str],
        value: str,
        decided: list[_DecidedConflict],
        outcomes: list[SpecConflictOutcome],
    ) -> str:
        """Applies the decided conflicts of one value (marks already
        accepted), from the last block up so earlier line numbers stay valid,
        and records each. Where the chosen text goes follows the conflict's
        text (SOM §11.9.8, "Applying"): a form field, another value, this
        value's text paragraphs, or — the default — the text paragraph
        directly before the block."""
        v = value
        recorded: list[SpecConflictOutcome] = []
        conflicts = [
            b.conflict for b in _parse(v).blocks if b.kind is SpecReviewAnnotationKind.CONFLICT
        ]
        for k in range(len(conflicts) - 1, -1, -1):
            d = next(x for x in decided if x.index == k)
            c = conflicts[k]
            assert c is not None
            result = _chosen_text(c)
            recorded.insert(
                0,
                SpecConflictOutcome(
                    id=d.id,
                    path=path,
                    field=field,
                    line=d.line,
                    decision=d.decision,
                    result=result,
                ),
            )
            v = self._apply_conflict(path, field, v, c, result)
        outcomes.extend(recorded)
        return v

    def _apply_conflict(
        self, path: str, field: Optional[str], value: str, c: _Conflict, result: str
    ) -> str:
        if c.topic in _STRUCTURAL_TOPICS:
            return value
        target = re.fullmatch(r"(\S+) (\S+)", c.text)
        if target is not None and self.doc.form_field(*target.groups()) is not None:
            self.doc.set_form_field(target.group(1), target.group(2), result)
            return value
        if field is None and c.text == path:
            return _replace_text_run(value, c.block, result)
        if re.fullmatch(r"[^\s,]+/[^\s,]+", c.text) and c.text != path:
            self.doc.set_content(c.text, result)
            return value
        return _replace_paragraph_before(value, c.block, result)

    def set_marked(self, path: str, text: str, field: Optional[str] = None) -> "SpecMarkedChange":
        """Writes *text* at *path* / *field* as a marked change against the
        value there now (SOM §11.9.3). A value that already holds change marks
        is compared from its original — every mark rejected — so a second edit
        of the same passage updates its mark instead of nesting one."""
        result = _mark_keeping_change_comments(self._get(path, field), text)
        self._set(path, field, result.text)
        return result

    def mark_against(self, path: str, earlier: str, field: Optional[str] = None) -> "SpecMarkedChange":
        """Marks the value at *path* / *field* as a change against *earlier*,
        an earlier version of it."""
        result = mark_change_text(earlier, self._get(path, field))
        self._set(path, field, result.text)
        return result

    def paragraphs(self, path: str, field: Optional[str] = None) -> "list[SpecParagraph]":
        """The paragraphs of the value at ``path`` / ``field``, in order — the
        units ``after_paragraph`` of :meth:`insert_comment` and
        :meth:`insert_question` counts. Raises
        :class:`SpecReviewAnnotationError` when the document holds no such
        value."""
        value = self.doc.content(path) if field is None else self.doc.form_field(path, field)
        if value is None:
            where = path if field is None else f"{path} / {field}"
            raise SpecReviewAnnotationError(f"no value at {where}")
        p = _parse(value)
        out: list[SpecParagraph] = []
        for i, (s, e) in enumerate(_paragraphs(p.lines, p.code)):
            annotation = next((b.kind.value for b in p.blocks if b.start == s), None)
            out.append(
                SpecParagraph(
                    index=i,
                    start_line=s,
                    end_line=e,
                    text="\n".join(p.lines[s : e + 1]),
                    annotation=annotation,
                )
            )
        return out

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
                if b.conflict is not None and b.conflict.id is not None:
                    ids.append(b.conflict.id)
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


# ---------------------------------------------------------------------------
# Text-level building blocks of the merge (SOM §11.9.9). Internal: used by
# `spec_review_merge.py` only and not exported from the package.
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class ReviewPiece:
    """One paragraph of a value as the merge sees it: text, or an annotation
    block."""

    #: The annotation kind of the block the paragraph opens with; ``None``
    #: for a text paragraph.
    kind: Optional[SpecReviewAnnotationKind]
    #: The paragraph's lines, verbatim.
    text: str
    #: A comment's id (``None`` without one), a conflict's id (``None`` when
    #: malformed).
    id: Optional[str] = None
    #: A comment's author, ``None`` without one.
    author: Optional[str] = None
    #: A comment's text.
    comment_text: str = ""
    #: The ids of a question block's questions.
    question_ids: tuple[str, ...] = ()

    @property
    def is_text(self) -> bool:
        """Whether the paragraph is text, not an annotation block."""
        return self.kind is None


def review_pieces(value: str) -> list[ReviewPiece]:
    """The paragraphs of *value* (SOM §11.9.1), each classified."""
    if value == "":
        return []
    p = _parse(value)
    out: list[ReviewPiece] = []
    for s, e in _paragraphs(p.lines, p.code):
        b = next((x for x in p.blocks if x.start == s), None)
        comment = None if b is None else next((c for c in p.comments if c.block is b), None)
        conflict_id = None if b is None or b.conflict is None else b.conflict.id
        out.append(
            ReviewPiece(
                kind=None if b is None else b.kind,
                text="\n".join(p.lines[s:e + 1]),
                id=comment.id if comment is not None else conflict_id,
                author=None if comment is None else comment.author,
                comment_text="" if comment is None else comment.text,
                question_ids=() if b is None else tuple(q.id for q in b.questions),
            )
        )
    return out


@dataclass(frozen=True)
class ReviewMark:
    """One inline mark of a value, with what its decisions leave."""

    #: Where the mark starts in the value.
    start: int
    #: Where the mark ends, after its attribution token.
    end: int
    #: Where the mark itself ends, before its attribution token.
    body_end: int
    #: The mark's kind.
    kind: SpecMarkKind
    #: The mark as written, its attribution token included.
    markup: str
    #: Its token's authors.
    authors: tuple[str, ...]
    #: Its token's votes.
    votes: tuple[SpecMarkVote, ...]
    #: The text accepting it leaves.
    accepted: str
    #: The text rejecting it leaves.
    rejected: str

    @property
    def has_token(self) -> bool:
        """Whether the mark carries an attribution token."""
        return self.end > self.body_end


def review_marks(value: str) -> list[ReviewMark]:
    """The inline marks of *value*, in order (marks in code are not marks)."""
    return [
        ReviewMark(
            start=m.start,
            end=m.end,
            body_end=m.body_end,
            kind=m.kind,
            markup=value[m.start:m.end],
            authors=m.authors,
            votes=m.votes,
            accepted=_mark_replacement(m, True),
            rejected=_mark_replacement(m, False),
        )
        for m in _parse(value).marks
    ]


def decide_review_marks(value: str, decisions: dict[int, bool]) -> str:
    """*value* with the marks *decisions* names (by index into
    :func:`review_marks`) accepted (``True``) or rejected (``False``), by the
    whitespace rules of SOM §11.9.3."""
    marks = _parse(value).marks
    v = value
    for k in range(len(marks) - 1, -1, -1):
        accept = decisions.get(k)
        if accept is None:
            continue
        v = _replace_mark(v, marks[k], _mark_replacement(marks[k], accept))
    return v


def format_attribution_token(
    authors: Sequence[str], votes: Sequence[SpecMarkVote]
) -> str:
    """The attribution token for *authors* and *votes*,
    ``{@agent +alice -bob}``."""
    v = " ".join(f"{'+' if x.vote is SpecVote.ACCEPT else '-'}{x.member}" for x in votes)
    sep = " " if authors and v else ""
    return f"{{@{','.join(authors)}{sep}{v}}}"


def with_attribution(
    value: str,
    m: ReviewMark,
    authors: Sequence[str],
    votes: Sequence[SpecMarkVote],
) -> str:
    """*value* with mark *m*'s token replaced by one for *authors* and
    *votes*."""
    return value[: m.body_end] + format_attribution_token(authors, votes) + value[m.end:]


def review_team_answers(value: str) -> dict[str, str]:
    """The team answer of every question of *value*, by id (the first, when
    an id repeats)."""
    out: dict[str, str] = {}
    for b in _parse(value).blocks:
        for q in b.questions:
            out.setdefault(q.id, q.answer)
    return out


def set_individual_answer_text(
    value: str, question_id: str, member: str, answer: str
) -> Optional[str]:
    """*value* with *member*'s individual answer to question *question_id*
    set, as :meth:`SpecReviewAnnotations.set_answer` with an ``author`` does;
    ``None`` when the value holds no such question."""
    for b in _parse(value).blocks:
        for q in b.questions:
            if q.id == question_id:
                return _set_individual_answer(value, q, member, answer)
    return None


def _alternative_lines(prefix: str, text: str) -> list[str]:
    """The lines of a conflict's text: the first after its prefix, the rest
    indented under it."""
    t = text.split("\n")
    return [_trim_right(f"> - {prefix} {t[0]}"), *(f">   {line}" for line in t[1:])]


def format_conflict_block(
    id: str,
    topic: str,
    text: str,
    base: str,
    alternatives: list[SpecConflictAlternative],
) -> list[str]:
    """The lines of a conflict block (SOM §11.9.8): the header, the
    ``(base)`` line, one lettered alternative per entry naming its members,
    and an empty ``**Decision:**``. A text's further lines are indented under
    it, so a reader gets them back with their line breaks."""
    lines = [
        _trim_right(f"> {_SCALES}{_VS16} **{id}{_EM_DASH_SEP}{topic}:** {text}"),
        *_alternative_lines("(base)", base),
    ]
    for a in alternatives:
        lines.extend(_alternative_lines(f"({a.letter}) **{', '.join(a.members)}:**", a.text))
    lines.extend([">", f"> {_DECISION_LABEL}"])
    return lines


def transplant_edits(x: str, y: str, b: str) -> Optional[str]:
    """Carries the edits *x* → *y* over to *b*, a text equal to *x* except
    where marks of *b* were decided in *x* (SOM §11.9.9, step 3): every edit
    lands in *b* at the place *x* and *b* agree on. ``None`` when an edit
    touches or borders a place where they differ — the edit overlaps a
    decided mark. Both diffs are the token diffs of :func:`mark_change_text`."""
    xt = _tokens(x)
    bt = _tokens(b)
    # Where each token of x is in b (-1: x and b differ there).
    to_b = [-1] * len(xt)
    i = j = 0
    for kind, _t in _diff(xt, bt):
        if kind == 0:
            to_b[i] = j
            i += 1
            j += 1
        elif kind == 1:
            i += 1
        else:
            j += 1
    # The edits x → y as [first x token, end x token, inserted text].
    hunks: list[list[Any]] = []
    i = 0
    open_: Optional[list[Any]] = None
    for kind, t in _diff(xt, _tokens(y)):
        if kind == 0:
            if open_ is not None:
                hunks.append(open_)
            open_ = None
            i += 1
            continue
        if open_ is None:
            open_ = [i, i, ""]
        if kind == 1:
            i += 1
            open_[1] = i
        else:
            open_[2] += t.text
    if open_ is not None:
        hunks.append(open_)
    out = [t.text for t in bt]
    for x0, x1, ins in reversed(hunks):
        at = _landing(to_b, x0, x1, len(bt))
        if at is None:
            return None
        out[at[0]:at[1]] = [ins]
    return "".join(out)


def _landing(to_b: list[int], x0: int, x1: int, b_length: int) -> Optional[tuple[int, int]]:
    """The b-token range an x-token range [x0, x1) lands on, or ``None`` when
    it is not one.

    A replaced range lands where its tokens are in b, which must be
    contiguous there; its neighbours are not consulted, because the token
    diff may align a neighbouring space with another space of b (beside a
    decided mark) without the range touching that mark. A pure insertion
    (``x0 == x1``) has no tokens of its own, so both neighbours must sit next
    to each other in b."""
    for k in range(x0, x1):
        if to_b[k] < 0 or (k > x0 and to_b[k] != to_b[k - 1] + 1):
            return None
    if x1 > x0:
        return (to_b[x0], to_b[x1 - 1] + 1)
    # The neighbours must sit next to the insertion point in b too.
    left = -1 if x0 == 0 else to_b[x0 - 1]
    right = b_length if x1 == len(to_b) else to_b[x1]
    if (x0 > 0 and left < 0) or (x1 < len(to_b) and right < 0):
        return None
    if left + 1 != right:
        return None
    return (left + 1, left + 1)
