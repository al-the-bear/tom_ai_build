"""The answers of a review round, extracted for a step folder (SOM §11.9.7).

A port of `tom_som_dart_runtime/lib/src/spec_answers.dart`.

A step of the TomSpecs process starts by collecting what the reviewer wrote
into the document — answers to the agent's questions, comments, and
optionally the questions still open and the inline marks — into the step
folder's ``answers.md``. The annotations stay in the document; this reads them
through :meth:`SpecReviewAnnotations.list` and never writes.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field as dc_field
from enum import Enum
from typing import Any, Optional

from .spec_document import SpecDocument
from .spec_document_markdown import SpecDocumentMarkdown
from .spec_model import SpecModel
from .spec_review_annotations import (
    SpecMarkKind,
    SpecReviewAnnotationKind,
    SpecReviewAnnotations,
    _trim,
)


class SpecAnswerKind(Enum):
    """What an extracted entry is."""

    #: A question with an answer.
    ANSWERED = "answered"
    #: A question without an answer.
    OPEN = "open"
    #: A comment block.
    COMMENT = "comment"
    #: An inline mark.
    MARK = "mark"


@dataclass(frozen=True)
class SpecAnswerEntry:
    """One extracted entry."""

    #: What it is.
    kind: SpecAnswerKind
    #: The section-id chain of the rendition heading the entry sits under
    #: (``SBP > INSC > SYSUM``).
    section: str
    #: The 1-based line in the document's Markdown rendition.
    line: int
    #: The document path of the value holding the entry.
    path: str
    #: The question or comment id (``BQ-81``, ``C-12``), or ``M-<n>`` for a
    #: mark; ``None`` for a comment without an id.
    id: Optional[str] = None
    #: The form field holding it, or ``None`` for content.
    field: Optional[str] = None
    #: A question's topic.
    topic: Optional[str] = None
    #: Whether a question is part of a combined form block.
    combined: bool = False
    #: A question's text, a comment's text, or a mark's markup.
    text: str = ""
    #: A question's answer (empty when open).
    answer: str = ""
    #: A comment's author.
    author: Optional[str] = None
    #: A mark's kind.
    mark_kind: Optional[SpecMarkKind] = None
    #: A mark's text when rejected.
    old_text: Optional[str] = None
    #: A mark's text when accepted.
    new_text: Optional[str] = None
    #: A mark's comment.
    comment: Optional[str] = None

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "kind": self.kind.value,
            "id": self.id,
            "section": self.section,
            "line": self.line,
            "path": self.path,
            "field": self.field,
            "topic": self.topic,
            "combined": self.combined,
            "text": self.text,
            "answer": self.answer,
            "author": self.author,
            "markKind": None if self.mark_kind is None else self.mark_kind.value,
            "oldText": self.old_text,
            "newText": self.new_text,
            "comment": self.comment,
        }


@dataclass(frozen=True)
class SpecAnswerCounts:
    """The counts a step's closing item reports."""

    #: Questions with an answer.
    answered: int = 0
    #: Questions without one.
    open: int = 0
    #: Comment blocks.
    comments: int = 0
    #: Inline marks.
    marks: int = 0

    def __add__(self, o: "SpecAnswerCounts") -> "SpecAnswerCounts":
        return SpecAnswerCounts(
            answered=self.answered + o.answered,
            open=self.open + o.open,
            comments=self.comments + o.comments,
            marks=self.marks + o.marks,
        )

    def to_json(self) -> dict[str, int]:
        """The canonical JSON form."""
        return {
            "answered": self.answered,
            "open": self.open,
            "comments": self.comments,
            "marks": self.marks,
        }


@dataclass(frozen=True)
class SpecAnswerExtract:
    """The extraction of one document."""

    #: The document's label in ``answers.md`` (e.g. ``tom_uam.sbp``).
    label: str
    #: The document root's section id, written in front of a comment id
    #: (``SBP C-12``).
    qualifier: str
    #: Every entry, in document order.
    entries: list[SpecAnswerEntry] = dc_field(default_factory=list)

    @property
    def counts(self) -> SpecAnswerCounts:
        """The counts over :attr:`entries`."""
        a = o = c = m = 0
        for e in self.entries:
            if e.kind is SpecAnswerKind.ANSWERED:
                a += 1
            elif e.kind is SpecAnswerKind.OPEN:
                o += 1
            elif e.kind is SpecAnswerKind.COMMENT:
                c += 1
            else:
                m += 1
        return SpecAnswerCounts(answered=a, open=o, comments=c, marks=m)

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "label": self.label,
            "qualifier": self.qualifier,
            "entries": [e.to_json() for e in self.entries],
            "counts": self.counts.to_json(),
        }


_HEADING = re.compile(r"^(#+) <!--\[([^\]]+)\]-->")


def extract_answers(
    model: SpecModel,
    doc: SpecDocument,
    label: str,
    path: Optional[str] = None,
) -> SpecAnswerExtract:
    """Extracts the annotations of *doc* (or of the subtree at *path*) with
    their place in the document's Markdown rendition under *model*, in
    rendition order (by line)."""
    root = next(
        (
            r
            for r in model.roots
            if doc.has_values_under(r.section_id if r.section_id is not None else r.type)
        ),
        model.roots[0],
    )
    qualifier = root.section_id if root.section_id is not None else root.type
    rendition = SpecDocumentMarkdown(model, doc).export_root_with_map(root)
    lines = rendition.markdown.split("\n")

    # The section-id chain of every heading line (1-based).
    chains: dict[int, str] = {}
    stack: list[tuple[int, str]] = []
    for i, text in enumerate(lines):
        m = _HEADING.match(text)
        if m is None:
            continue
        level = len(m.group(1))
        while stack and stack[-1][0] >= level:
            stack.pop()
        stack.append((level, m.group(2)))
        chains[i + 1] = " > ".join(e[1] for e in stack)

    heading_keys = sorted(rendition.heading_paths)

    def heading_line(value_path: str) -> int:
        # The heading whose path is the longest prefix of the value's path
        # (on equal length, the first).
        best, best_len = 0, -1
        for ln in heading_keys:
            hp = rendition.heading_paths[ln]
            if (value_path == hp or value_path.startswith(hp + "/")) and len(hp) > best_len:
                best, best_len = ln, len(hp)
        return best

    def chain_at(line: int) -> str:
        for ln in range(line, 0, -1):
            c = chains.get(ln)
            if c is not None:
                return c
        return qualifier

    claimed: set[int] = set()

    def locate(value_path: str, field: Optional[str], value_line: int, first_line: str) -> int:
        # The first unclaimed line after the value's heading whose trimmed
        # text is the annotation's first line. A form field's first line
        # renders behind its label (`Owner: …`).
        h = heading_line(value_path)
        want = _trim(first_line)
        labelled = (
            None
            if field is None or value_line != 0
            else _trim(f"{field[0].upper()}{field[1:]}: {want}")
        )
        for i in range(h, len(lines)):
            ln = i + 1
            if ln <= h or ln in claimed:
                continue
            t = _trim(lines[i])
            if t == want or (labelled is not None and t == labelled):
                claimed.add(ln)
                return ln
        return 1 if h == 0 else h

    def in_scope(p: str) -> bool:
        return path is None or p == path or p.startswith(path + "/")

    api = SpecReviewAnnotations(doc)
    # `list()` and `list_marks()` give the marks in the same order.
    marks = api.list_marks()
    mark_index = 0
    entries: list[SpecAnswerEntry] = []
    for a in api.list():
        # Every mark consumes its listing entry, in scope or not, so the ids
        # of the marks in a subtree stay their document-wide `M-<n>`.
        mk = None
        if a.kind is SpecReviewAnnotationKind.MARK:
            mk = marks[mark_index]
            mark_index += 1
        if not in_scope(a.path):
            continue
        value = (
            doc.content(a.path) if a.field is None else doc.form_field(a.path, a.field)
        ) or ""
        first = value.split("\n")[a.line]
        if a.kind is SpecReviewAnnotationKind.QUESTION:
            line = locate(a.path, a.field, a.line, first)
            entries.append(
                SpecAnswerEntry(
                    kind=SpecAnswerKind.OPEN if a.open else SpecAnswerKind.ANSWERED,
                    id=a.id,
                    section=chain_at(line),
                    line=line,
                    path=a.path,
                    field=a.field,
                    topic=a.topic,
                    combined=a.combined,
                    text=a.text,
                    answer=a.answer,
                )
            )
        elif a.kind is SpecReviewAnnotationKind.COMMENT:
            line = locate(a.path, a.field, a.line, first)
            entries.append(
                SpecAnswerEntry(
                    kind=SpecAnswerKind.COMMENT,
                    id=a.id,
                    section=chain_at(line),
                    line=line,
                    path=a.path,
                    field=a.field,
                    text=a.text,
                    author=a.author,
                )
            )
        else:
            assert mk is not None
            line = locate(a.path, a.field, a.line, first)
            # A line holding several marks is found once; later marks on it
            # share the line.
            claimed.discard(line)
            entries.append(
                SpecAnswerEntry(
                    kind=SpecAnswerKind.MARK,
                    id=mk.id,
                    section=chain_at(line),
                    line=line,
                    path=a.path,
                    field=a.field,
                    text=mk.markup,
                    mark_kind=a.mark_kind,
                    old_text=mk.old_text,
                    new_text=mk.new_text,
                    comment=a.comment,
                )
            )
    # Rendition order: by line; entries on one line keep their order
    # (`sorted` is stable).
    return SpecAnswerExtract(
        label=label,
        qualifier=qualifier,
        entries=sorted(entries, key=lambda e: e.line),
    )


@dataclass(frozen=True)
class SpecAnswerRenderOptions:
    """What ``answers.md`` includes besides the answered questions and
    comments."""

    #: List the questions still open.
    include_open: bool = False
    #: List the inline marks.
    include_marks: bool = False
    #: The file's title.
    title: str = "Answers"


def _item(label: str, value: str) -> str:
    """A labelled value: ``- **Label:** first line``, further lines indented
    two spaces."""
    ls = value.split("\n")
    b = [f"- **{label}:**"]
    if ls[0]:
        b.append(f" {ls[0]}")
    for ln in ls[1:]:
        b.append("\n" if ln == "" else f"\n  {ln}")
    return "".join(b)


def _count_line(c: SpecAnswerCounts, o: SpecAnswerRenderOptions) -> str:
    def s(n: int) -> str:
        return "" if n == 1 else "s"

    parts = [
        f"{c.answered} answered question{s(c.answered)}",
        f"{c.open} open question{s(c.open)}",
        f"{c.comments} comment{s(c.comments)}",
    ]
    if o.include_marks:
        parts.append(f"{c.marks} inline mark{s(c.marks)}")
    return ", ".join(parts) + "."


def _entry_heading(x: SpecAnswerExtract, e: SpecAnswerEntry) -> str:
    if e.kind in (SpecAnswerKind.ANSWERED, SpecAnswerKind.OPEN):
        return f"{e.id} — {e.topic}"
    if e.kind is SpecAnswerKind.COMMENT:
        if e.id is None:
            return f"Comment without id (line {e.line})"
        return f"{x.qualifier} {e.id}"
    assert e.mark_kind is not None
    return f"{e.id} — {e.mark_kind.value}"


def render_answers(
    extracts: list[SpecAnswerExtract],
    options: SpecAnswerRenderOptions = SpecAnswerRenderOptions(),
) -> str:
    """Renders *extracts* as a step folder's ``answers.md``: deterministic,
    grouped per document in the order given, entries in document order."""
    total = SpecAnswerCounts()
    for x in extracts:
        total = total + x.counts
    out: list[str] = [f"# {options.title}", "", _count_line(total, options)]
    for x in extracts:
        out += ["", f"## {x.label}", "", _count_line(x.counts, options)]

        def section(heading: str, kind: SpecAnswerKind) -> None:
            es = [e for e in x.entries if e.kind is kind]
            out.extend(["", f"### {heading}"])
            if not es:
                out.extend(["", "None."])
                return
            for e in es:
                out.extend([
                    "",
                    f"#### {_entry_heading(x, e)}",
                    "",
                    _item("Section", f"`{e.section}`"),
                    _item("Line", str(e.line)),
                ])
                if e.field is not None:
                    out.append(_item("Field", f"`{e.field}`"))
                if kind in (SpecAnswerKind.ANSWERED, SpecAnswerKind.OPEN):
                    out.append(_item("Question", e.text))
                    if kind is SpecAnswerKind.ANSWERED:
                        out.append(_item("Answer", e.answer))
                elif kind is SpecAnswerKind.COMMENT:
                    if e.author is not None:
                        out.append(_item("Author", e.author))
                    out.append(_item("Comment", e.text))
                else:
                    out.append(_item("Markup", f"`{e.text}`"))
                    out.append(_item("Old", e.old_text or ""))
                    out.append(_item("New", e.new_text or ""))
                    if e.comment is not None:
                        out.append(_item("Note", e.comment))

        section("Answered questions", SpecAnswerKind.ANSWERED)
        section("Comments", SpecAnswerKind.COMMENT)
        if options.include_open:
            section("Open questions", SpecAnswerKind.OPEN)
        if options.include_marks:
            section("Inline marks", SpecAnswerKind.MARK)
    return "\n".join(out) + "\n"
