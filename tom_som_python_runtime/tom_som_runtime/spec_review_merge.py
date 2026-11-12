"""Merging the reviewed copies of a team review (SOM §11.9.9) into one
document in the team notation of §11.9.8: who proposed, voted for and
answered what, and where two members changed the same passage differently.

:func:`merge_reviews` merges a SOM document (:class:`SpecDocument`, by model
path, list items matched by section id) or a plain annotated Markdown file (a
``str``, by heading path). Both share one engine that works value by value;
only the way values are found, and the SOM-only structure and revision entry,
differ.

The engine is built on the review-annotation building blocks: the paragraph
split and the mark decisions of :class:`SpecReviewAnnotations`,
:func:`mark_change_text` for edits written as plain text, the
individual-answer rules of ``set_answer``, and the list-item id generation of
:func:`generate_list_item_section_id`.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field as dc_field
from typing import Any, Callable, Generic, Optional, TypeVar

from .spec_document import SpecDocument
from .spec_document_markdown import MarkdownFenceTracker
from .spec_model import FormFieldSpec, SpecClass, SpecField, SpecFieldKind, SpecModel
from .spec_paths import spec_parent_path
from .spec_reflection import SpecNodeKind, SpecReflection
from .spec_review_annotations import (
    ReviewMark,
    ReviewPiece,
    SpecConflictAlternative,
    SpecMarkKind,
    SpecMarkVote,
    SpecQuestionDraft,
    SpecReviewAnnotationKind,
    SpecVote,
    apply_inline_marks_text,
    decide_review_marks,
    format_comment_block,
    format_conflict_block,
    format_question_block,
    mark_change_text,
    review_marks,
    review_pieces,
    review_team_answer_times,
    review_team_answers,
    set_individual_answer_text,
    transplant_edits,
    with_attribution,
)
from .spec_section_id import effective_list_item_section_id, generate_list_item_section_id

D = TypeVar("D", SpecDocument, str)


# ---------------------------------------------------------------------------
# Inputs, report and result.
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class SpecReviewMember:
    """A member of a review team (SOM §11.9.8)."""

    #: The member id: lowercase letters, digits and ``_``.
    member_id: str
    #: The name a tool shows for the member.
    display_name: str
    #: The member's role in the team; may be empty.
    role: str

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecReviewMember":
        """Reads a member from its corpus JSON form."""
        return SpecReviewMember(
            member_id=str(j["memberId"]),
            display_name=str(j.get("displayName") or ""),
            role=str(j.get("role") or ""),
        )


@dataclass(frozen=True)
class SpecReviewedCopy(Generic[D]):
    """One returned copy: its reviewer and the copy's document — a
    :class:`SpecDocument` or a Markdown ``str``."""

    member_id: str
    display_name: str
    role: str
    #: The reviewed copy.
    document: D


@dataclass(frozen=True)
class SpecReviewMergeOptions:
    """The options of :func:`merge_reviews`."""

    #: The members the round started with, in team order; a copy of anybody
    #: else is a guest's.
    team: tuple[SpecReviewMember, ...]
    #: The round's date (ISO 8601): the revision entry's date, and the date
    #: of every generated list-item id.
    date: str
    #: The revision entry's author.
    author: str
    #: The id prefix of the questions the merge writes.
    question_prefix: str = "RQ"
    #: The model of a SOM document; required when merging
    #: :class:`SpecDocument` s.
    model: Optional[SpecModel] = None


class SpecReviewMergeError(Exception):
    """Raised when a copy's structure does not fit the base; nothing is
    merged."""

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message

    def __str__(self) -> str:
        return f"SpecReviewMergeError: {self.message}"


@dataclass(frozen=True)
class SpecMergeReviewer:
    """A reviewer as the report lists it."""

    member_id: str
    display_name: str
    role: str
    #: Whether the reviewer was not in the team the round started with.
    guest: bool

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "memberId": self.member_id,
            "displayName": self.display_name,
            "role": self.role,
            "guest": self.guest,
        }


@dataclass(frozen=True)
class SpecMergeConflict:
    """A conflict block the merge wrote."""

    #: The conflict id, ``X-<n>``.
    id: str
    #: The value's path (a structural conflict: the item's).
    path: str
    #: The form field, or ``None``.
    field: Optional[str]
    #: The unit's index among the value's text paragraphs; ``None`` for a
    #: whole value or a structural conflict.
    paragraph: Optional[int]
    #: Every member named in the block's alternatives.
    members: tuple[str, ...]

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "id": self.id,
            "path": self.path,
            "field": self.field,
            "paragraph": self.paragraph,
            "members": list(self.members),
        }


@dataclass(frozen=True)
class SpecMergeVotes:
    """A base mark left with votes."""

    path: str
    field: Optional[str]
    #: The mark as merged, its token carrying the votes.
    markup: str
    #: The votes, in round order after any the base already held.
    votes: tuple[SpecMarkVote, ...]

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "path": self.path,
            "field": self.field,
            "markup": self.markup,
            "votes": [v.to_json() for v in self.votes],
        }


@dataclass(frozen=True)
class SpecMergeUnanimous:
    """A base mark every copy decided the same way, applied or dropped."""

    path: str
    field: Optional[str]
    #: The mark as the base wrote it.
    markup: str
    #: How every copy decided it.
    decision: SpecVote
    #: The text the decision left.
    result: str

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "path": self.path,
            "field": self.field,
            "markup": self.markup,
            "decision": self.decision.value,
            "result": self.result,
        }


@dataclass(frozen=True)
class SpecMergeAnswers:
    """A base question the copies answered."""

    question_id: str
    #: The members whose answers were written, in round order.
    members: tuple[str, ...]

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"questionId": self.question_id, "members": list(self.members)}


@dataclass(frozen=True)
class SpecMergeComment:
    """A new comment."""

    #: The comment's merged id, ``C-<n>``.
    id: str
    #: Its author: as written, else the member whose copy held it.
    author: str
    path: str
    field: Optional[str]

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"id": self.id, "author": self.author, "path": self.path, "field": self.field}


@dataclass(frozen=True)
class SpecMergeAddition:
    """An item a copy added."""

    #: The item's path in the merged document.
    path: str
    #: The members who added it alike.
    members: tuple[str, ...]

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"path": self.path, "members": list(self.members)}


@dataclass(frozen=True)
class SpecMergeGuestQuestion:
    """The question proposing a guest for the next round's team."""

    id: str
    member_id: str
    #: Where it was written; ``None`` when the document has no place for it.
    path: Optional[str]

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"id": self.id, "memberId": self.member_id, "path": self.path}


@dataclass(frozen=True)
class SpecMergeRevision:
    """The draft revision entry the merge appended."""

    #: The entry's item path.
    path: str
    #: The draft version, the next minor of the header's.
    version: str

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"path": self.path, "version": self.version}


@dataclass
class SpecReviewMergeReport:
    """The merge report (SOM §11.9.9), every list in merged document order."""

    reviewers: list[SpecMergeReviewer] = dc_field(default_factory=list)
    conflicts: list[SpecMergeConflict] = dc_field(default_factory=list)
    votes: list[SpecMergeVotes] = dc_field(default_factory=list)
    unanimous: list[SpecMergeUnanimous] = dc_field(default_factory=list)
    answers: list[SpecMergeAnswers] = dc_field(default_factory=list)
    comments: list[SpecMergeComment] = dc_field(default_factory=list)
    additions: list[SpecMergeAddition] = dc_field(default_factory=list)
    guest_questions: list[SpecMergeGuestQuestion] = dc_field(default_factory=list)
    revision: Optional[SpecMergeRevision] = None

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form the conformance corpus pins."""
        return {
            "reviewers": [r.to_json() for r in self.reviewers],
            "conflicts": [c.to_json() for c in self.conflicts],
            "votes": [v.to_json() for v in self.votes],
            "unanimous": [u.to_json() for u in self.unanimous],
            "answers": [a.to_json() for a in self.answers],
            "comments": [c.to_json() for c in self.comments],
            "additions": [a.to_json() for a in self.additions],
            "guestQuestions": [g.to_json() for g in self.guest_questions],
            "revision": None if self.revision is None else self.revision.to_json(),
        }


@dataclass(frozen=True)
class SpecReviewMergeResult(Generic[D]):
    """The merged document and its report."""

    #: The merged document, of the base's type.
    merged: D
    #: What the merge did.
    report: SpecReviewMergeReport


def merge_reviews(
    base: D,
    copies: list[SpecReviewedCopy[D]],
    options: SpecReviewMergeOptions,
) -> SpecReviewMergeResult[D]:
    """Merges the reviewed *copies* of *base* (SOM §11.9.9). *base* is a
    :class:`SpecDocument` (merged by model path; needs
    :attr:`SpecReviewMergeOptions.model`) or a Markdown ``str`` (merged by
    heading path). Neither the base nor a copy is written. A copy whose
    structure does not fit the base is refused with
    :class:`SpecReviewMergeError`."""
    if isinstance(base, str):
        return _merge_markdown(base, copies, options)  # type: ignore[arg-type,return-value]
    if options.model is None:
        raise SpecReviewMergeError("merging a SOM document needs options.model")
    return _merge_som(base, copies, options, options.model)  # type: ignore[arg-type,return-value]


# ---------------------------------------------------------------------------
# The engine: one value at a time.
# ---------------------------------------------------------------------------

#: Ids the merge writes before it can number them: renumbered in merged
#: document order at the end.
_PLACEHOLDER = re.compile("\u0001([CX])([0-9]+)\u0001")


@dataclass
class _MergeValue:
    """One value to merge, located in the merged document."""

    path: str
    field: Optional[str]
    base: str
    #: Per copy, in round order; ``None`` when the copy holds no such value
    #: (it removed the item).
    copies: list[Optional[str]]
    #: A typed leaf (number, bool, enum, code): never marked, any change is a
    #: conflict.
    typed: bool
    #: Where a conflict about a form field or a typed leaf goes; ``None`` for
    #: a content value.
    conflict_home: Optional[str]


@dataclass
class _UnitReading:
    """What one copy did to one unit (SOM §11.9.9, steps 1–4)."""

    changed: bool
    #: The reviewer's text.
    t: str
    #: The change as it is written into the merged document.
    written: str
    #: The copy's votes, by the index of the base unit's mark (True: accept).
    votes: dict[int, bool]


def _unchanged(b: str, votes: Optional[dict[int, bool]] = None) -> _UnitReading:
    """A copy that did not change the unit, with its votes."""
    return _UnitReading(False, b, b, votes or {})


@dataclass
class _ChangeGroup:
    """The readings that made one change: the same text ``t``, in order of
    first appearance."""

    text: str
    members: list[str]
    first: _UnitReading

    def alternative(self, k: int) -> SpecConflictAlternative:
        return SpecConflictAlternative(chr(0x61 + k), tuple(self.members), self.text)


class _MergeContext:
    """The state one merge carries from value to value."""

    def __init__(
        self,
        copies: list[Any],
        base_comment_ids: set[str],
        base_question_ids: set[str],
    ) -> None:
        self.report = SpecReviewMergeReport()
        #: Blocks to append to the end of a content value, by its key.
        self.appends: dict[str, list[str]] = {}
        self.members = [c.member_id for c in copies]
        self.base_comment_ids = base_comment_ids
        self.base_question_ids = base_question_ids
        self._next_placeholder = 0
        #: Placeholder → report entry, filled in when the ids are numbered.
        self.pending_conflicts: dict[str, SpecMergeConflict] = {}
        self.pending_comments: dict[str, SpecMergeComment] = {}

    def placeholder(self, kind: str) -> str:
        self._next_placeholder += 1
        return f"\u0001{kind}{self._next_placeholder}\u0001"

    def append(self, key: str, block: str) -> None:
        self.appends.setdefault(key, []).append(block)

    def conflict(
        self,
        topic: str,
        text: str,
        base: str,
        groups: list[_ChangeGroup],
        path: str,
        field: Optional[str],
        paragraph: Optional[int],
    ) -> str:
        """Writes a conflict block with a placeholder id and records it for
        the report."""
        cid = self.placeholder("X")
        self.pending_conflicts[cid] = SpecMergeConflict(
            id=cid,
            path=path,
            field=field,
            paragraph=paragraph,
            members=tuple(m for g in groups for m in g.members),
        )
        return "\n".join(
            format_conflict_block(
                id=cid,
                topic=topic,
                text=text,
                base=base,
                alternatives=[g.alternative(k) for k, g in enumerate(groups)],
            )
        )


def _change_groups(
    readings: list[Optional[_UnitReading]], members: list[str]
) -> list[_ChangeGroup]:
    """Groups the changed readings by their text ``t``, in order of first
    appearance."""
    groups: list[_ChangeGroup] = []
    for k, r in enumerate(readings):
        if r is None or not r.changed:
            continue
        g = next((x for x in groups if x.text == r.t), None)
        if g is None:
            groups.append(_ChangeGroup(r.t, [members[k]], r))
        else:
            g.members.append(members[k])
    return groups


T = TypeVar("T")


def _lcs_pairs(a: list[T], b: list[T], same: Callable[[T, T], bool]) -> dict[int, int]:
    """The longest-common-subsequence pairing of two lists under *same*:
    index in *a* → index in *b*. Ties skip in *a* first, as every runtime
    does."""
    n, m = len(a), len(b)
    l = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n - 1, -1, -1):
        for j in range(m - 1, -1, -1):
            l[i][j] = l[i + 1][j + 1] + 1 if same(a[i], b[j]) else max(l[i + 1][j], l[i][j + 1])
    out: dict[int, int] = {}
    i = j = 0
    while i < n and j < m:
        if same(a[i], b[j]):
            out[i] = j
            i += 1
            j += 1
        elif l[i + 1][j] >= l[i][j + 1]:
            i += 1
        else:
            j += 1
    return out


def _align_marks(a: list[ReviewMark], b: list[ReviewMark]) -> dict[int, int]:
    """Aligns two mark lists by their markup (longest common subsequence):
    index in *a* → index in *b*."""
    return _lcs_pairs(a, b, lambda x, y: x.markup == y.markup)


#: The most base marks a unit may have that a copy no longer holds as
#: written: the combinations of step 2 grow as 2^n. Beyond it the copy's unit
#: is read as an edit (step 4), so every runtime gives up at the same point.
_MAX_DECIDED_MARKS = 16


def _find_votes(
    b: str, marks: list[ReviewMark], left: set[int], target: str
) -> Optional[dict[int, bool]]:
    """The first combination of decisions on *b*'s marks (step 2) whose
    result is *target*, or ``None``. Each mark takes leave, accept, reject in
    that order, the first mark varying slowest. A mark the copy still holds
    as written can only have been left, and a mark it no longer holds cannot
    have been, so only the others vary — the same first combination, found
    without trying the rest."""
    free = [i for i in range(len(marks)) if i not in left]
    if len(free) > _MAX_DECIDED_MARKS:
        return None
    for combo in range(1 << len(free)):
        # Bit set: reject; the first mark is the most significant bit.
        decisions = {
            mark: ((combo >> (len(free) - 1 - k)) & 1) == 0 for k, mark in enumerate(free)
        }
        if decide_review_marks(b, decisions) == target:
            return decisions
    return None


def _read_as_edit(b: str, c: str) -> _UnitReading:
    """Step 4: the copy edited text that holds base marks; it casts no
    votes."""
    t = apply_inline_marks_text(c, accept=True)
    return _UnitReading(
        t != b, t, mark_change_text(apply_inline_marks_text(b, accept=False), t).text, {}
    )


def _read_unit(b: str, c: str) -> _UnitReading:
    """What copy unit *c* did to base unit *b* (SOM §11.9.9, steps 1–4)."""
    if c == b:
        return _unchanged(b)
    base_marks = review_marks(b)
    copy_marks = review_marks(c)
    kept = _align_marks(copy_marks, base_marks)
    # 1. Own marks: the copy's marks that are not the base's.
    own = [i for i in range(len(copy_marks)) if i not in kept]
    # 2. Votes: the decisions on the base marks that give c with its own
    # marks rejected.
    c_prime = decide_review_marks(c, {i: False for i in own})
    votes = _find_votes(b, base_marks, set(kept.values()), c_prime)
    if votes is None:
        return _read_as_edit(b, c)
    if not own:
        return _unchanged(b, votes)
    # 3. Change: the own marks, carried over to the base text where marks
    # were voted on.
    own_accepted = decide_review_marks(c, {i: True for i in own})
    written = c if not votes else transplant_edits(c_prime, c, b)
    t = own_accepted if not votes else transplant_edits(c_prime, own_accepted, b)
    if written is None or t is None:
        return _read_as_edit(b, c)
    return _UnitReading(t != b, t, written, votes)


def _attribute(written: str, base_marks: list[ReviewMark], members: list[str]) -> str:
    """*written* with every mark that is not one of the base's attributed to
    *members*."""
    marks = review_marks(written)
    base = _align_marks(marks, base_marks)
    out = written
    for k in range(len(marks) - 1, -1, -1):
        if k not in base:
            out = with_attribution(out, marks[k], members, marks[k].votes)
    return out


def _is_change(m: ReviewMark) -> bool:
    """Whether a mark is a change, which alone takes votes."""
    return m.kind in (SpecMarkKind.INSERTION, SpecMarkKind.DELETION, SpecMarkKind.SUBSTITUTION)


def _apply_votes(
    text: str,
    base_marks: list[ReviewMark],
    readings: list[Optional[_UnitReading]],
    v: _MergeValue,
    ctx: _MergeContext,
) -> str:
    """*text* with the copies' votes on the base marks it holds: a base mark
    every copy decided the same way is applied (accept) or dropped (reject);
    any other voted change mark gets the votes in its token, ``agent`` as
    author when it had no token. A highlight or comment mark takes no votes
    and stays."""
    marks = review_marks(text)
    base = _align_marks(marks, base_marks)
    taking = sum(1 for r in readings if r is not None)
    votes: list[SpecMergeVotes] = []
    unanimous: list[SpecMergeUnanimous] = []
    out = text
    for k in range(len(marks) - 1, -1, -1):
        b = base.get(k)
        if b is None:
            continue
        cast: list[SpecMarkVote] = []
        for i, r in enumerate(readings):
            d = None if r is None else r.votes.get(b)
            if d is not None:
                vote = SpecVote.ACCEPT if d else SpecVote.REJECT
                cast.append(SpecMarkVote(ctx.members[i], vote))
        if not cast:
            continue
        m = marks[k]
        if len(cast) == taking and all(x.vote is cast[0].vote for x in cast):
            accept = cast[0].vote is SpecVote.ACCEPT
            out = decide_review_marks(out, {k: accept})
            unanimous.insert(
                0,
                SpecMergeUnanimous(
                    path=v.path,
                    field=v.field,
                    markup=base_marks[b].markup,
                    decision=cast[0].vote,
                    result=base_marks[b].accepted if accept else base_marks[b].rejected,
                ),
            )
            continue
        if not _is_change(m):
            continue
        authors = m.authors if m.has_token else ("agent",)
        merged = [x for x in m.votes if not any(y.member == x.member for y in cast)] + cast
        out = with_attribution(out, m, authors, merged)
        votes.insert(
            0,
            SpecMergeVotes(
                path=v.path, field=v.field, markup=review_marks(out)[k].markup, votes=tuple(merged)
            ),
        )
    ctx.report.votes.extend(votes)
    ctx.report.unanimous.extend(unanimous)
    return out


def _merge_unit(
    b: str,
    units: list[Optional[str]],
    paragraph: Optional[int],
    v: _MergeValue,
    ctx: _MergeContext,
) -> tuple[str, Optional[str]]:
    """One unit merged, as (text, conflict block or ``None``): the base text
    with votes when no copy changed it, the one change attributed to every
    member who made it, or the base text and a conflict block when the copies
    changed it differently."""
    readings = [None if c is None else _read_unit(b, c) for c in units]
    groups = _change_groups(readings, ctx.members)
    base_marks = review_marks(b)
    text = b
    if len(groups) == 1:
        text = _attribute(groups[0].first.written, base_marks, groups[0].members)
    text = _apply_votes(text, base_marks, readings, v, ctx)
    if len(groups) < 2:
        return text, None
    where = v.path if v.field is None else f"{v.path} {v.field}"
    conflict = ctx.conflict(
        topic="Conflicting changes",
        text=where if paragraph is None else f"{where}, paragraph {paragraph}",
        base=b,
        groups=groups,
        path=v.path,
        field=v.field,
        paragraph=paragraph,
    )
    return text, conflict


def _merge_typed(v: _MergeValue, ctx: _MergeContext) -> str:
    """A typed leaf: it cannot hold a mark, so a change by any copy is a
    ``Value changed`` conflict at the leaf's home, the base value kept."""
    readings = [None if c is None else _UnitReading(c != v.base, c, c, {}) for c in v.copies]
    groups = _change_groups(readings, ctx.members)
    if groups and v.conflict_home is not None:
        ctx.append(
            v.conflict_home,
            ctx.conflict(
                topic="Value changed",
                text=v.path if v.field is None else f"{v.path} {v.field}",
                base=v.base,
                groups=groups,
                path=v.path,
                field=v.field,
                paragraph=None,
            ),
        )
    return v.base


def _merge_field(v: _MergeValue, ctx: _MergeContext) -> str:
    """A form-field value: always one unit; its conflict goes to the end of
    the form's preamble."""
    text, conflict = _merge_unit(v.base, v.copies, None, v, ctx)
    if conflict is not None and v.conflict_home is not None:
        ctx.append(v.conflict_home, conflict)
    return text


def _is_new_block(piece: ReviewPiece, ctx: _MergeContext) -> bool:
    """Whether a copy's block is new: a comment whose id the base lacks, a
    question block with no base question."""
    if piece.kind is SpecReviewAnnotationKind.COMMENT:
        return piece.id is None or piece.id not in ctx.base_comment_ids
    if piece.kind is SpecReviewAnnotationKind.QUESTION:
        return bool(piece.question_ids) and all(
            i not in ctx.base_question_ids for i in piece.question_ids
        )
    return False


def _anchors(pieces: list[ReviewPiece], whole: bool) -> list[int]:
    """The anchor of each block of a value: the index of the text paragraph
    it follows (-1: before every one). In whole-value mode every block that
    follows text follows the one unit."""
    texts = -1
    out: list[int] = []
    for p in pieces:
        if p.is_text:
            texts += 1
            out.append(texts)
        else:
            out.append(min(texts, 0) if whole else texts)
    return out


def _texts_of(pieces: list[ReviewPiece]) -> list[str]:
    return [p.text for p in pieces if p.is_text]


def _merge_content(v: _MergeValue, ctx: _MergeContext) -> str:
    """A content value: split into text paragraphs and annotation blocks,
    merged unit by unit, the copies' new comments and questions placed after
    the unit they followed. A copy whose text-paragraph count differs from
    the base's makes the whole text one unit, for every copy."""
    base_pieces = review_pieces(v.base)
    copy_pieces = [None if c is None else review_pieces(c) for c in v.copies]
    base_texts = _texts_of(base_pieces)
    whole = any(ps is not None and len(_texts_of(ps)) != len(base_texts) for ps in copy_pieces)

    def units_of(ps: list[ReviewPiece]) -> list[str]:
        return ["\n\n".join(_texts_of(ps))] if whole else _texts_of(ps)

    base_units = units_of(base_pieces)
    copy_units = [None if ps is None else units_of(ps) for ps in copy_pieces]

    # Blocks by anchor: the base's first, then each copy's new ones in round
    # order.
    after: dict[int, list[str]] = {}
    base_anchors = _anchors(base_pieces, whole)
    for k, p in enumerate(base_pieces):
        if not p.is_text:
            after.setdefault(base_anchors[k], []).append(p.text)
    for i, ps in enumerate(copy_pieces):
        if ps is None:
            continue
        anchors = _anchors(ps, False)
        for k, p in enumerate(ps):
            if p.is_text or not _is_new_block(p, ctx):
                continue
            anchor = len(base_units) - 1 if whole else anchors[k]
            after.setdefault(anchor, []).append(_new_block(p, ctx.members[i], v, ctx))

    out = list(after.get(-1, []))
    for u, b in enumerate(base_units):
        units = [None if cs is None else cs[u] for cs in copy_units]
        text, conflict = _merge_unit(b, units, None if whole else u, v, ctx)
        if text != "":
            out.append(text)
        if conflict is not None:
            out.append(conflict)
        out.extend(after.get(u, []))
    return "\n\n".join(out)


def _new_block(p: ReviewPiece, member: str, v: _MergeValue, ctx: _MergeContext) -> str:
    """A copy's new block as merged: a comment renumbered and attributed, a
    question as written."""
    if p.kind is not SpecReviewAnnotationKind.COMMENT:
        return p.text
    cid = ctx.placeholder("C")
    author = p.author if p.author is not None else member
    ctx.pending_comments[cid] = SpecMergeComment(id=cid, author=author, path=v.path, field=v.field)
    return "\n".join(format_comment_block(cid, p.comment_text, author, p.changed_at))


def _merge_value(v: _MergeValue, ctx: _MergeContext) -> str:
    """One value merged; the base text when no copy differs from it."""
    if all(c is None or c == v.base for c in v.copies):
        return v.base
    if v.typed:
        return _merge_typed(v, ctx)
    if v.field is not None:
        return _merge_field(v, ctx)
    return _merge_content(v, ctx)


# ---------------------------------------------------------------------------
# Shared phases over the merged texts.
# ---------------------------------------------------------------------------


class _Texts:
    """The merged document's values, by key, in merged document order."""

    def keys(self) -> list[str]:
        raise NotImplementedError

    def get(self, key: str) -> str:
        raise NotImplementedError

    def set(self, key: str, value: str) -> None:
        raise NotImplementedError


def _append_block(value: str, block: str) -> str:
    """Appends *block* to the end of *value*, one blank line between them."""
    return block if value == "" else f"{value}\n\n{block}"


def _apply_appends(texts: _Texts, ctx: _MergeContext) -> None:
    """Appends the collected blocks (field and structural conflicts) to the
    end of their values."""
    for key, blocks in ctx.appends.items():
        value = texts.get(key)
        texts.set(key, "\n\n".join([*([value] if value != "" else []), *blocks]))


def _highest_id(texts: list[str], prefix: str, kinds: set[SpecReviewAnnotationKind]) -> int:
    """The highest ``<prefix>-<n>`` of the texts' annotations of the given
    kinds."""
    high = 0
    for t in texts:
        for p in review_pieces(t):
            if p.kind not in kinds:
                continue
            ids = p.question_ids if p.kind is SpecReviewAnnotationKind.QUESTION else (p.id,)
            for i in ids:
                if i is None or not i.startswith(f"{prefix}-"):
                    continue
                m = re.match(r"[0-9]+", i[len(prefix) + 1:])
                if m is not None and int(m.group(0)) > high:
                    high = int(m.group(0))
    return high


def _number_ids(texts: _Texts, base_texts: list[str], ctx: _MergeContext) -> None:
    """Numbers the new comments and conflicts in merged document order, above
    the base's highest ``C-<n>`` and ``X-<n>``, and fills their report
    entries in."""
    nxt = {
        "C": _highest_id(base_texts, "C", {SpecReviewAnnotationKind.COMMENT}),
        "X": _highest_id(base_texts, "X", {SpecReviewAnnotationKind.CONFLICT}),
    }

    def number(m: re.Match[str]) -> str:
        kind = m.group(1)
        nxt[kind] += 1
        cid = f"{kind}-{nxt[kind]}"
        if kind == "C":
            c = ctx.pending_comments[m.group(0)]
            ctx.report.comments.append(
                SpecMergeComment(id=cid, author=c.author, path=c.path, field=c.field)
            )
        else:
            x = ctx.pending_conflicts[m.group(0)]
            ctx.report.conflicts.append(
                SpecMergeConflict(
                    id=cid, path=x.path, field=x.field, paragraph=x.paragraph, members=x.members
                )
            )
        return cid

    for key in texts.keys():
        value = texts.get(key)
        if "\u0001" in value:
            texts.set(key, _PLACEHOLDER.sub(number, value))


def _team_answers(texts: list[str]) -> dict[str, str]:
    """The team answers of every question of *texts*, by id (the first, when
    an id repeats)."""
    out: dict[str, str] = {}
    for t in texts:
        for k, a in review_team_answers(t).items():
            out.setdefault(k, a)
    return out


def _team_answer_times(texts: list[str]) -> dict[str, Optional[str]]:
    """The times of the team answers of *texts*, by id (the first, when an
    id repeats; SOM §11.9.10)."""
    out: dict[str, Optional[str]] = {}
    for t in texts:
        for k, a in review_team_answer_times(t).items():
            out.setdefault(k, a)
    return out


def _merge_answers(
    texts: _Texts, base_texts: list[str], copy_texts: list[list[str]], ctx: _MergeContext
) -> None:
    """Writes each copy's team answer to a base question, where it differs
    from the base's, as that member's individual answer (copies in round
    order), with the copy's answer time (SOM §11.9.10)."""
    copy_answers = [_team_answers(ts) for ts in copy_texts]
    copy_times = [_team_answer_times(ts) for ts in copy_texts]
    for qid, base_answer in _team_answers(base_texts).items():
        members: list[str] = []
        for i, answers in enumerate(copy_answers):
            a = answers.get(qid)
            if a is None or a == base_answer or a == "":
                continue
            for key in texts.keys():
                written = set_individual_answer_text(
                    texts.get(key), qid, ctx.members[i], a, copy_times[i].get(qid)
                )
                if written is None:
                    continue
                texts.set(key, written)
                members.append(ctx.members[i])
                break
        if members:
            ctx.report.answers.append(SpecMergeAnswers(question_id=qid, members=tuple(members)))


def _guest_question(qid: str, g: Any) -> str:
    """The question proposing guest *g* for the next round's team."""
    who = f"{g.display_name}, {g.role}" if g.role else g.display_name
    return "\n".join(
        format_question_block(
            SpecQuestionDraft(
                id=qid,
                topic=f"Guest {g.member_id}",
                text=f"add {g.member_id} ({who}) to the review team?",
                options=("(a) yes, from the next round on", "(b) no, this round only"),
                recommended="a",
            )
        )
    )


def _add_guests(
    texts: _Texts,
    base_texts: list[str],
    copies: list[Any],
    options: SpecReviewMergeOptions,
    home: Optional[tuple[str, str]],
    ctx: _MergeContext,
) -> None:
    """Lists the reviewers and writes one question per guest to the end of
    the value at *home* (key, path; ``None``: the report only), numbered
    above the base's highest question id with the prefix."""
    team = {m.member_id for m in options.team}
    prefix = options.question_prefix
    n = _highest_id(base_texts, prefix, {SpecReviewAnnotationKind.QUESTION})
    for c in copies:
        guest = c.member_id not in team
        ctx.report.reviewers.append(
            SpecMergeReviewer(
                member_id=c.member_id, display_name=c.display_name, role=c.role, guest=guest
            )
        )
        if not guest:
            continue
        n += 1
        qid = f"{prefix}-{n}"
        ctx.report.guest_questions.append(
            SpecMergeGuestQuestion(
                id=qid, member_id=c.member_id, path=None if home is None else home[1]
            )
        )
        if home is None:
            continue
        texts.set(home[0], _append_block(texts.get(home[0]), _guest_question(qid, c)))


def _block_ids(texts: list[str]) -> tuple[set[str], set[str]]:
    """The ids of the comments and of the questions of *texts*."""
    comments: set[str] = set()
    questions: set[str] = set()
    for t in texts:
        for p in review_pieces(t):
            if p.kind is SpecReviewAnnotationKind.COMMENT and p.id is not None:
                comments.add(p.id)
            questions.update(p.question_ids)
    return comments, questions


def _merge_texts(
    values: list[_MergeValue],
    key_of: Callable[[_MergeValue], str],
    texts: _Texts,
    base_texts: list[str],
    copy_texts: list[list[str]],
    copies: list[Any],
    options: SpecReviewMergeOptions,
    home: Optional[tuple[str, str]],
    ctx: _MergeContext,
) -> None:
    """The phases after the structure, shared by both formats."""
    for v in values:
        merged = _merge_value(v, ctx)
        if merged != v.base:
            texts.set(key_of(v), merged)
    _apply_appends(texts, ctx)
    _number_ids(texts, base_texts, ctx)
    _merge_answers(texts, base_texts, copy_texts, ctx)
    _add_guests(texts, base_texts, copies, options, home, ctx)


# ---------------------------------------------------------------------------
# Plain Markdown: values by heading path.
# ---------------------------------------------------------------------------


@dataclass
class _MarkdownSplit:
    """A Markdown file cut at its headings: body ``i`` follows heading
    ``i - 1`` (body 0 precedes them all)."""

    headings: list[str] = dc_field(default_factory=list)
    #: The heading path of each body, its heading texts joined by `` > ``
    #: (body 0: empty).
    paths: list[str] = dc_field(default_factory=lambda: [""])
    bodies: list[list[str]] = dc_field(default_factory=lambda: [[]])


_HEADING = re.compile(r"(#{1,6})(?:[ \t]+(.*?))?[ \t]*")


def _split_markdown(text: str) -> _MarkdownSplit:
    out = _MarkdownSplit()
    fence = MarkdownFenceTracker()
    stack: list[tuple[int, str]] = []
    for line in text.split("\n"):
        was_fenced = fence.in_fence
        fence.feed(line)
        h = None if was_fenced or fence.in_fence else _HEADING.fullmatch(line)
        if h is None:
            out.bodies[-1].append(line)
            continue
        level = len(h.group(1))
        while stack and stack[-1][0] >= level:
            stack.pop()
        stack.append((level, h.group(2) or ""))
        out.headings.append(line)
        out.paths.append(" > ".join(s[1] for s in stack))
        out.bodies.append([])
    return out


def _body_parts(lines: list[str]) -> tuple[int, int, str]:
    """A body's blank lines before and after its value, and the value:
    (lead, trail, value)."""
    lead = 0
    while lead < len(lines) and lines[lead].strip() == "":
        lead += 1
    if lead == len(lines):
        return lead, 0, ""
    trail = 0
    while lines[len(lines) - 1 - trail].strip() == "":
        trail += 1
    return lead, trail, "\n".join(lines[lead:len(lines) - trail])


def _body_lines(lines: list[str], value: str, after_heading: bool) -> list[str]:
    """The body lines for a new value, keeping the body's blank lines around
    it."""
    lead, trail, current = _body_parts(lines)
    if value == current:
        return lines
    if value == "":
        return lines[:lead]
    if current == "":
        return [*([""] if after_heading else []), *value.split("\n"), *([""] if lines else [])]
    return [*lines[:lead], *value.split("\n"), *lines[len(lines) - trail:]]


class _MarkdownTexts(_Texts):
    """The Markdown bodies as :class:`_Texts`, keyed by their index."""

    def __init__(self, merged: list[str]) -> None:
        self.merged = merged

    def keys(self) -> list[str]:
        return [str(k) for k in range(len(self.merged))]

    def get(self, key: str) -> str:
        return self.merged[int(key)]

    def set(self, key: str, value: str) -> None:
        self.merged[int(key)] = value


def _merge_markdown(
    base: str, copies: list[SpecReviewedCopy[str]], options: SpecReviewMergeOptions
) -> SpecReviewMergeResult[str]:
    b = _split_markdown(base)
    cs = [_split_markdown(c.document) for c in copies]
    for i, c in enumerate(cs):
        if len(c.headings) != len(b.headings) or any(
            h.strip() != b.headings[k].strip() for k, h in enumerate(c.headings)
        ):
            raise SpecReviewMergeError(
                f"the copy of {copies[i].member_id} has other headings than the base"
            )
    base_texts = [_body_parts(lines)[2] for lines in b.bodies]
    copy_texts = [[_body_parts(lines)[2] for lines in c.bodies] for c in cs]
    texts = _MarkdownTexts(list(base_texts))
    comment_ids, question_ids = _block_ids(base_texts)
    ctx = _MergeContext(copies, comment_ids, question_ids)
    values = [
        _MergeValue(
            path=b.paths[k],
            field=None,
            base=t,
            copies=[ct[k] for ct in copy_texts],
            typed=False,
            conflict_home=None,
        )
        for k, t in enumerate(base_texts)
    ]
    index = {id(v): k for k, v in enumerate(values)}
    first = 1 if b.headings else 0
    _merge_texts(
        values,
        lambda v: str(index[id(v)]),
        texts,
        base_texts,
        copy_texts,
        copies,
        options,
        (str(first), b.paths[first]),
        ctx,
    )
    lines: list[str] = []
    for k, body in enumerate(b.bodies):
        if k > 0:
            lines.append(b.headings[k - 1])
        lines.extend(_body_lines(body, texts.merged[k], k > 0))
    return SpecReviewMergeResult("\n".join(lines), ctx.report)


# ---------------------------------------------------------------------------
# SOM documents: values by model path, list items by section id.
# ---------------------------------------------------------------------------


class _CanonicalPaths:
    """A document's paths with every list item named by its section id
    instead of its position (``DEMO/CARD-LST#CARD-BETA/content``), so the
    same item has the same name in the base, in every copy and in the merged
    document."""

    def __init__(self, doc: SpecDocument, refl: SpecReflection) -> None:
        self.doc = doc
        self._list_of: dict[str, str] = {}
        self._ids: dict[str, str] = {}
        self._by_canonical: dict[str, str] = {}
        self._memo: dict[str, str] = {}
        for lst in doc.list_paths:
            res = refl.resolve(lst)
            f = None if res is None else res.field
            for k, item in enumerate(doc.list_items(lst)):
                self._list_of[item] = lst
                self._ids[item] = effective_list_item_section_id(
                    doc.item_section_id(item),
                    None if f is None else f.section_id_pattern,
                    k + 1,
                    lst if f is None else f.name,
                )
        for item in list(self._list_of):
            self._by_canonical[self.of(item)] = item

    def items(self, lst: str) -> list[str]:
        """The item paths of the list at *lst*, in order."""
        return list(self.doc.list_items(lst))

    def id_of(self, item: str) -> str:
        """The section id an item is matched by."""
        return self._ids[item]

    def of(self, path: str) -> str:
        """The canonical form of *path*."""
        memo = self._memo.get(path)
        if memo is not None:
            return memo
        segs = path.split("/")
        out = path
        for k in range(len(segs), 0, -1):
            prefix = "/".join(segs[:k])
            lst = self._list_of.get(prefix)
            if lst is None:
                continue
            rest = "/".join(segs[k:])
            out = f"{self.of(lst)}#{self.id_of(prefix)}{'/' + rest if rest else ''}"
            break
        self._memo[path] = out
        return out

    def path_of(self, canonical: str) -> Optional[str]:
        """The document's path for a canonical path, or ``None`` when the
        document lacks one of its items."""
        segs = canonical.split("/")
        for k in range(len(segs), 0, -1):
            item = self._by_canonical.get("/".join(segs[:k]))
            if item is None:
                continue
            rest = "/".join(segs[k:])
            return f"{item}{'/' + rest if rest else ''}"
        return None if "#" in canonical else canonical


def _under(path: str, item: str) -> bool:
    """Whether canonical *path* is *item* or lies under it."""
    return path == item or path.startswith(item + "/")


def _under_any(path: str, items: Any) -> bool:
    return any(_under(path, a) for a in items)


def _check_structure(doc: SpecDocument, what: str, refl: SpecReflection) -> None:
    """A copy whose paths the model does not resolve does not fit the base."""
    paths = [
        *doc.content_paths,
        *doc.form_paths,
        *doc.headline_paths,
        *doc.code_spec_paths,
        *doc.units_paths,
        *(p for lst in doc.list_paths for p in [lst, *doc.list_items(lst)]),
    ]
    for p in paths:
        if refl.resolve(p) is None:
            raise SpecReviewMergeError(f"{what} holds {p}, a path the base model does not resolve")


def _copy_document(doc: SpecDocument) -> SpecDocument:
    out = SpecDocument()
    out.load_json(json.loads(json.dumps(doc.to_json())))
    return out


def _form_field(refl: SpecReflection, path: str, field: str) -> Optional[FormFieldSpec]:
    """The form field *field* of the form at *path*, or ``None``."""
    res = refl.resolve(path)
    if res is None or res.field is None:
        return None
    return next((x for x in res.field.form_fields if x.name == field), None)


def _is_text(refl: SpecReflection, path: str, field: Optional[str]) -> bool:
    """Whether the value at *path* / *field* is text, which can hold marks: a
    content value (a form's preamble included) or a String form field that is
    not code. Scalar and enum leaves, and typed or code fields, are not."""
    if field is not None:
        spec = _form_field(refl, path, field)
        return spec is None or (spec.type == "String" and not spec.code)
    res = refl.resolve(path)
    if res is None:
        return True
    if res.kind in (SpecNodeKind.SCALAR, SpecNodeKind.ENUM_VALUE):
        return False
    return res.kind is not SpecNodeKind.LIST_ITEM_SCALAR or (
        res.field is not None and res.field.element_type == "String"
    )


def _first_content_slot(refl: SpecReflection, path: str, deep: bool) -> Optional[str]:
    """The first node at or below *path* that holds content (a content leaf
    or a form's preamble), in model order."""
    res = refl.resolve(path)
    if res is None:
        return None
    if res.kind in (SpecNodeKind.CONTENT, SpecNodeKind.FORM):
        return path
    cls = res.target_class
    if cls is None:
        return None
    for f in cls.fields:
        child = f"{path}/{refl.field_segment(f)}"
        if f.kind in (SpecFieldKind.CONTENT, SpecFieldKind.FORM):
            return child
        if deep and f.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
            found = _first_content_slot(refl, child, True)
            if found is not None:
                return found
    return None


def _block_home(
    doc: SpecDocument, refl: SpecReflection, path: str, own_first: bool
) -> Optional[str]:
    """Where a block about the node at *path* goes (SOM §11.9.9,
    "Structure"): the first content value at or below it in document order;
    else the first node at or below it that can hold content; else its
    nearest ancestor's own."""
    if own_first:
        existing = sorted(p for p in doc.content_paths if _under(p, path))
        if existing:
            return existing[0]
        slot = _first_content_slot(refl, path, True)
        if slot is not None:
            return slot
    a = spec_parent_path(path)
    while a != "":
        if doc.content(a) is not None:
            return a
        slot = _first_content_slot(refl, a, False)
        if slot is not None:
            return slot
        parent = spec_parent_path(a)
        if parent == a:
            break
        a = parent
    return None


@dataclass
class _Structural:
    """One structural change the copies disagree with the base on."""

    #: The canonical path of the item (or section) concerned.
    node: str
    #: ``Item removed``, ``Item moved`` or ``Headline changed``.
    topic: str
    base: str
    groups: list[_ChangeGroup] = dc_field(default_factory=list)


def _add_structural(
    all_: list[_Structural], node: str, topic: str, base: str, text: str, member: str
) -> None:
    s = next((x for x in all_ if x.node == node and x.topic == topic), None)
    if s is None:
        s = _Structural(node, topic, base)
        all_.append(s)
    g = next((x for x in s.groups if x.text == text), None)
    if g is None:
        s.groups.append(_ChangeGroup(text, [member], _UnitReading(True, text, text, {})))
    else:
        g.members.append(member)


def _moved(order: list[str], ids: list[str]) -> list[str]:
    """The ids of *ids* that are not in their longest common subsequence with
    *order*, in the order of *ids*."""
    stay = {order[i] for i in _lcs_pairs(order, ids, lambda a, b: a == b)}
    return [i for i in ids if i not in stay]


_FENCE_OPEN = re.compile(r"\s*(```|~~~)")


def _as_insertion(value: str, members: list[str]) -> str:
    """*value* written as attributed insertions, one per text paragraph (an
    added item's text)."""
    token = f"{{@{','.join(members)}}}"
    return "\n\n".join(
        p.text
        if not p.is_text or _FENCE_OPEN.match(p.text)
        else f"{{++ {p.text.strip()} ++}}{token}"
        for p in review_pieces(value)
    )


def _copy_item(
    src: SpecDocument,
    from_: str,
    dst: SpecDocument,
    to: str,
    members: list[str],
    refl: SpecReflection,
) -> None:
    """Copies item *from_* of *src*, with everything under it, to item *to*
    of *dst*."""
    moved = {from_: to}

    def remap(p: str) -> str:
        segs = p.split("/")
        for k in range(len(segs), 0, -1):
            target = moved.get("/".join(segs[:k]))
            if target is not None:
                return "/".join([target, *segs[k:]])
        return p

    lists = sorted(
        (l for l in src.list_paths if _under(l, from_)), key=lambda l: len(l.split("/"))
    )
    canonical = _CanonicalPaths(src, refl)
    for lst in lists:
        for item in src.list_items(lst):
            moved[item] = dst.add_list_item(remap(lst), canonical.id_of(item))
    for p in [x for x in src.content_paths if _under(x, from_)]:
        value = src.content(p) or ""
        dst.set_content(
            remap(p), _as_insertion(value, members) if _is_text(refl, p, None) else value
        )
    for p in [x for x in src.form_paths if _under(x, from_)]:
        for f in src.form_field_names(p):
            value = src.form_field(p, f) or ""
            dst.set_form_field(
                remap(p), f, _as_insertion(value, members) if _is_text(refl, p, f) else value
            )
    for p in [x for x in src.headline_paths if _under(x, from_)]:
        dst.set_headline(remap(p), src.headline(p) or "")
    for p in [x for x in src.code_spec_paths if _under(x, from_)]:
        dst.set_code_spec(remap(p), src.code_spec(p) or "")
    for p in [x for x in src.units_paths if _under(x, from_)]:
        dst.set_units(remap(p), src.units(p) or "")


def _item_signature(doc: SpecDocument, item: str) -> str:
    """Everything under an item, as one comparable value: copies adding the
    same item alike add it once. Paths are taken relative to the item,
    because the item's own path is a position."""
    j = doc.to_json()

    def pick(o: Any) -> list[list[Any]]:
        return [[k[len(item):], v] for k, v in (o or {}).items() if _under(k, item)]

    # Nested item paths start with the item's own path, which is a position:
    # cut it.
    own = json.dumps(item)[:-1]
    return '"'.join(
        json.dumps([pick(j.get(k)) for k in ("content", "forms", "headlines", "lists")]).split(own)
    )


@dataclass
class _AddGroup:
    """The copies adding one item alike."""

    copy: int
    anchor: Optional[str]
    members: list[str]
    signature: str


def _merge_structure(
    merged: SpecDocument,
    base: SpecDocument,
    copies: list[SpecReviewedCopy[SpecDocument]],
    refl: SpecReflection,
    model: SpecModel,
    ctx: _MergeContext,
) -> set[str]:
    """The structure phase: items the copies added are added (attributed to
    every copy that added them alike); items removed or moved, and changed
    headlines, become structural conflicts. Returns the canonical paths of
    the added items."""
    base_canon = _CanonicalPaths(base, refl)
    copy_canon = [_CanonicalPaths(c.document, refl) for c in copies]
    added: set[str] = set()
    structural: list[_Structural] = []
    additions: list[tuple[str, list[str]]] = []
    lists = {base_canon.of(l) for l in base.list_paths}
    for i, c in enumerate(copies):
        lists.update(copy_canon[i].of(l) for l in c.document.list_paths)
    for lst in sorted(lists, key=lambda a: (len(a.split("#")), a)):
        if _under_any(lst, added):
            continue
        base_path = base_canon.path_of(lst)
        if base_path is None:
            continue
        base_ids = [base_canon.id_of(p) for p in base_canon.items(base_path)]
        groups: dict[str, _AddGroup] = {}
        for i, c in enumerate(copies):
            copy_path = copy_canon[i].path_of(lst)
            if copy_path is None:
                continue
            items = copy_canon[i].items(copy_path)
            ids = [copy_canon[i].id_of(p) for p in items]
            member = c.member_id
            for k, iid in enumerate(ids):
                if iid in base_ids:
                    continue
                signature = _item_signature(c.document, items[k])
                g = groups.get(iid)
                if g is None:
                    anchor = next((x for x in reversed(ids[:k]) if x in base_ids), None)
                    groups[iid] = _AddGroup(i, anchor, [member], signature)
                elif g.signature == signature:
                    g.members.append(member)
            for iid in [x for x in base_ids if x not in ids]:
                _add_structural(
                    structural, f"{lst}#{iid}", "Item removed", "kept", "removed", member
                )
            kept_order = [x for x in base_ids if x in ids]
            kept_ids = [x for x in ids if x in base_ids]
            for iid in _moved(kept_order, kept_ids):
                _add_structural(
                    structural,
                    f"{lst}#{iid}",
                    "Item moved",
                    f"position {base_ids.index(iid) + 1}",
                    f"moved to position {ids.index(iid) + 1}",
                    member,
                )
        for iid, g in groups.items():
            merged_canon = _CanonicalPaths(merged, refl)
            list_path = merged_canon.path_of(lst)
            assert list_path is not None
            merged_ids = [merged_canon.id_of(p) for p in merged_canon.items(list_path)]
            at = 0 if g.anchor is None else merged_ids.index(g.anchor) + 1
            while at < len(merged_ids) and merged_ids[at] not in base_ids:
                at += 1
            item = merged.add_list_item(list_path, iid)
            if at < len(merged_ids):
                item = merged.move_list_item(model, item, at).path
            src_path = copy_canon[g.copy].path_of(f"{lst}#{iid}")
            assert src_path is not None
            _copy_item(copies[g.copy].document, src_path, merged, item, g.members, refl)
            added.add(f"{lst}#{iid}")
            additions.append((f"{lst}#{iid}", g.members))
    _headline_changes(base, base_canon, copies, copy_canon, added, structural)
    merged_canon = _CanonicalPaths(merged, refl)
    for node, members in additions:
        path = merged_canon.path_of(node)
        assert path is not None
        ctx.report.additions.append(SpecMergeAddition(path=path, members=tuple(members)))
    for s in structural:
        node = merged_canon.path_of(s.node)
        assert node is not None
        home = _block_home(merged, refl, node, True)
        block = ctx.conflict(
            topic=s.topic,
            text=node,
            base=s.base,
            groups=s.groups,
            path=node,
            field=None,
            paragraph=None,
        )
        if home is not None:
            ctx.append(_content_key(home), block)
    return added


def _headline_changes(
    base: SpecDocument,
    base_canon: _CanonicalPaths,
    copies: list[SpecReviewedCopy[SpecDocument]],
    copy_canon: list[_CanonicalPaths],
    added: set[str],
    structural: list[_Structural],
) -> None:
    """Every headline a copy changed (items it added aside) is a structural
    conflict."""
    nodes = {base_canon.of(p) for p in base.headline_paths}
    for i, c in enumerate(copies):
        nodes.update(copy_canon[i].of(p) for p in c.document.headline_paths)
    for node in sorted(nodes):
        if _under_any(node, added):
            continue
        base_path = base_canon.path_of(node)
        if base_path is None:
            continue
        was = base.headline(base_path) or ""
        for i, c in enumerate(copies):
            path = copy_canon[i].path_of(node)
            if path is None:
                continue
            now = c.document.headline(path) or ""
            if now != was:
                _add_structural(structural, node, "Headline changed", was, now, c.member_id)


def _content_key(path: str) -> str:
    """The key of a SOM content value: ``c\\0<path>``."""
    return f"c\u0000{path}"


def _field_key(path: str, field: str) -> str:
    """The key of a SOM form-field value: ``f\\0<path>\\0<field>``."""
    return f"f\u0000{path}\u0000{field}"


class _SomTexts(_Texts):
    """The SOM document's values as :class:`_Texts`, in document order
    (content sorted, then forms and fields sorted)."""

    def __init__(self, doc: SpecDocument) -> None:
        self.doc = doc

    def keys(self) -> list[str]:
        return [
            *(_content_key(p) for p in sorted(self.doc.content_paths)),
            *(
                _field_key(p, f)
                for p in sorted(self.doc.form_paths)
                for f in sorted(self.doc.form_field_names(p))
            ),
        ]

    def get(self, key: str) -> str:
        k = key.split("\u0000")
        v = self.doc.content(k[1]) if k[0] == "c" else self.doc.form_field(k[1], k[2])
        return v or ""

    def set(self, key: str, value: str) -> None:
        k = key.split("\u0000")
        if k[0] == "c":
            self.doc.set_content(k[1], value)
        else:
            self.doc.set_form_field(k[1], k[2], value)

    def values(self) -> list[str]:
        """Every value, in document order."""
        return [self.get(k) for k in self.keys()]


def _som_values(
    merged: SpecDocument,
    base: SpecDocument,
    copies: list[SpecReviewedCopy[SpecDocument]],
    added: set[str],
    refl: SpecReflection,
) -> list[_MergeValue]:
    """The values to merge: every value of the base and of the copies, items
    the copies added aside, located in the merged document; in its document
    order."""
    base_canon = _CanonicalPaths(base, refl)
    copy_canon = [_CanonicalPaths(c.document, refl) for c in copies]
    merged_canon = _CanonicalPaths(merged, refl)
    keys: dict[str, tuple[str, Optional[str]]] = {}

    def collect(doc: SpecDocument, canon: _CanonicalPaths) -> None:
        for p in doc.content_paths:
            keys[_content_key(canon.of(p))] = (canon.of(p), None)
        for p in doc.form_paths:
            for f in doc.form_field_names(p):
                keys[_field_key(canon.of(p), f)] = (canon.of(p), f)

    collect(base, base_canon)
    for i, c in enumerate(copies):
        collect(c.document, copy_canon[i])

    def read(doc: SpecDocument, path: str, field: Optional[str]) -> str:
        v = doc.content(path) if field is None else doc.form_field(path, field)
        return v or ""

    values: list[_MergeValue] = []
    for node, field in keys.values():
        if _under_any(node, added):
            continue
        base_path = base_canon.path_of(node)
        if base_path is None:
            continue
        path = merged_canon.path_of(node)
        assert path is not None
        text = _is_text(refl, path, field)
        home: Optional[str] = None
        if field is not None:
            home = _content_key(path)
        elif not text:
            h = _block_home(merged, refl, path, False)
            home = None if h is None else _content_key(h)
        copy_values: list[Optional[str]] = []
        for i, c in enumerate(copies):
            p = copy_canon[i].path_of(node)
            copy_values.append(None if p is None else read(c.document, p, field))
        values.append(
            _MergeValue(
                path=path,
                field=field,
                base=read(base, base_path, field),
                copies=copy_values,
                typed=not text,
                conflict_home=home,
            )
        )
    return sorted(values, key=lambda v: (0 if v.field is None else 1, v.path, v.field or ""))


def _class_field(cls: Optional[SpecClass], name: str, kind: SpecFieldKind) -> Optional[SpecField]:
    """The class field of *cls* named *name* with kind *kind*, or ``None``."""
    f = None if cls is None else cls.field_named(name)
    return f if f is not None and f.kind is kind else None


#: The model classes the revision entry is written with (``tom_specs_model``'s
#: document front matter).
_REVISION_ENTRY = "RevisionEntry"
_DOCUMENT_HEADER = "DocumentHeader"


def _next_minor(version: Optional[str]) -> str:
    """The next minor of a ``major.minor[.patch]`` version; ``0.1.0`` for
    anything else."""
    m = re.fullmatch(r"([0-9]+)\.([0-9]+)(\.[0-9]+)?", (version or "").strip())
    if m is None:
        return "0.1.0"
    minor = f"{m.group(1)}.{int(m.group(2)) + 1}"
    return minor if m.group(3) is None else f"{minor}.0"


def _month_day(date: str) -> tuple[int, int]:
    """The month and day of an ISO 8601 date."""
    m = re.match(r"[0-9]{4}-([0-9]{2})-([0-9]{2})", date)
    if m is None:
        raise SpecReviewMergeError(f'options.date "{date}" is not an ISO 8601 date')
    return int(m.group(1)), int(m.group(2))


def _add_generated_item(
    doc: SpecDocument, lst: str, field: SpecField, date: tuple[int, int]
) -> str:
    """Adds an item with a generated id to the list *field* at *lst*, and
    returns its path."""
    iid = generate_list_item_section_id(
        field.section_id_pattern or f"{field.name}-xxx",
        date[0],
        date[1],
        doc.list_item_section_ids(lst),
    )
    return doc.add_list_item(lst, iid)


def _add_reviewer_record(
    doc: SpecDocument,
    refl: SpecReflection,
    lst: str,
    field: SpecField,
    member: Any,
    guest: bool,
    date: tuple[int, int],
) -> None:
    """Writes one reviewer record into the list *field* at *lst*."""
    item = _add_generated_item(doc, lst, field, date)
    form = _class_field(refl.class_named(field.element_type), "content", SpecFieldKind.FORM)
    if form is None:
        return
    path = f"{item}/{refl.field_segment(form)}"
    doc.set_form_field(path, "memberId", member.member_id)
    doc.set_form_field(path, "displayName", member.display_name)
    doc.set_form_field(path, "role", member.role)
    if guest:
        doc.set_form_field(path, "guest", "true")


def _add_revision_entry(
    merged: SpecDocument,
    root: str,
    copies: list[Any],
    options: SpecReviewMergeOptions,
    refl: SpecReflection,
    ctx: _MergeContext,
) -> None:
    """Appends the draft revision entry when the root has a revision history:
    the next minor version, the date and author, the team the round started
    with and every reviewer who returned a copy, guests marked."""
    spec_root = refl.root_for_segment(root)
    root_class = refl.class_named(None if spec_root is None else spec_root.type)
    if root_class is None:
        return
    history = next(
        (
            f
            for f in root_class.fields
            if f.kind is SpecFieldKind.LIST and f.element_type == _REVISION_ENTRY
        ),
        None,
    )
    if history is None:
        return
    date = _month_day(options.date)
    header = next((f for f in root_class.fields if f.type == _DOCUMENT_HEADER), None)
    header_form = (
        None
        if header is None
        else _class_field(refl.class_named(_DOCUMENT_HEADER), "content", SpecFieldKind.FORM)
    )
    current = (
        merged.form_field(
            f"{root}/{refl.field_segment(header)}/{refl.field_segment(header_form)}", "version"
        )
        if header is not None and header_form is not None
        else None
    )
    version = _next_minor(current)
    item = _add_generated_item(merged, f"{root}/{refl.field_segment(history)}", history, date)
    entry = refl.class_named(_REVISION_ENTRY)
    form = _class_field(entry, "content", SpecFieldKind.FORM)
    if form is not None:
        path = f"{item}/{refl.field_segment(form)}"
        merged.set_form_field(path, "version", version)
        merged.set_form_field(path, "date", options.date)
        merged.set_form_field(path, "author", options.author)
    team = {m.member_id for m in options.team}
    records: list[tuple[str, list[Any], Callable[[str], bool]]] = [
        ("reviewTeam", list(options.team), lambda _id: False),
        ("reviewers", list(copies), lambda mid: mid not in team),
    ]
    for name, members, guest in records:
        lst = _class_field(entry, name, SpecFieldKind.LIST)
        if lst is None:
            continue
        for m in members:
            _add_reviewer_record(
                merged, refl, f"{item}/{refl.field_segment(lst)}", lst, m, guest(m.member_id), date
            )
    ctx.report.revision = SpecMergeRevision(path=item, version=version)


def _root_of(doc: SpecDocument, refl: SpecReflection) -> Optional[str]:
    """The root segment of a document: the first segment of its paths."""
    j = doc.to_json()
    for key in ("content", "forms", "lists", "headlines"):
        m = j.get(key)
        if m:
            return next(iter(m)).split("/")[0]
    roots = list(refl.roots)
    return refl.root_segment(roots[0]) if roots else None


def _merge_som(
    base: SpecDocument,
    copies: list[SpecReviewedCopy[SpecDocument]],
    options: SpecReviewMergeOptions,
    model: SpecModel,
) -> SpecReviewMergeResult[SpecDocument]:
    refl = SpecReflection(model)
    _check_structure(base, "the base", refl)
    for c in copies:
        _check_structure(c.document, f"the copy of {c.member_id}", refl)
    base_values = _SomTexts(base).values()
    copy_values = [_SomTexts(c.document).values() for c in copies]
    comment_ids, question_ids = _block_ids(base_values)
    ctx = _MergeContext(copies, comment_ids, question_ids)
    merged = _copy_document(base)
    added = _merge_structure(merged, base, copies, refl, model, ctx)
    values = _som_values(merged, base, copies, added, refl)
    root = _root_of(base, refl)
    spec_root = None if root is None else refl.root_for_segment(root)
    root_class = None if spec_root is None else refl.class_named(spec_root.type)
    root_content = _class_field(root_class, "content", SpecFieldKind.CONTENT)
    home_path = (
        f"{root}/{refl.field_segment(root_content)}"
        if root is not None and root_content is not None
        else None
    )
    _merge_texts(
        values,
        lambda v: _content_key(v.path) if v.field is None else _field_key(v.path, v.field),
        _SomTexts(merged),
        base_values,
        copy_values,
        copies,
        options,
        None if home_path is None else (_content_key(home_path), home_path),
        ctx,
    )
    if root is not None:
        _add_revision_entry(merged, root, copies, options, refl, ctx)
    return SpecReviewMergeResult(merged, ctx.report)

