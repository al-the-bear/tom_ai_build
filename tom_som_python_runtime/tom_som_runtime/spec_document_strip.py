"""Stripped renditions (SOM §11.10; the reading view's part *Stripped
renditions and the merge back*): a copy of a value with the secondary prose of
named kinds dropped, unmarked or moved to an appendix.

The kinds are the four the reading notation registers as secondary
(``provenance``, ``trace``, ``editorial``, ``aside``, DocSpecs RN-5),
``linked``, the navigation marker (SOM §11.11), and ``derived``, the generated
parts (SOM §11.12) — both removed by ``drop`` and ``unmark`` alike, the
rendition then writing none —, and ``comments``, the review annotations
(SOM §11.9). A citation shape counts as a span of its kind. ``refs``,
``records`` and ``rejected`` are never secondary: no name drops or unmarks
them (RN-11).

This module holds the strip of one value (:func:`strip_notation_text`), the
strip of a whole document (:meth:`SpecDocumentStrip.strip`: every value, the
emptying rule, the list items left empty removed, the appendix numbered
through the rendition, the ``.readable.md`` and its check) and the readable
header (:class:`SpecReadableHeader`); the port of ``spec_document_strip.ts`` /
``spec_document_strip.dart``, which ``strip_cases.json`` holds to the same
results. Dropping or unmarking ``linked`` / ``derived`` also turns the
rendition's markers and generated parts off
(:attr:`SpecStripOptions.writes_no_linked_markers`,
:attr:`SpecStripOptions.writes_no_generated_parts`).

**Offsets are UTF-16 code units**, as in every other runtime: a piece's
``anchor`` and ``origin`` count UTF-16 units. The plan therefore works on the
value as a string of UTF-16 code units (:func:`_utf16_string`, one Python
character per unit, a supplementary character as its two surrogates) — the
indexing the notation scanner's offsets and the TypeScript reference use —
and turns every text it hands out back into an ordinary string
(:func:`_from_utf16_string`).
"""

from __future__ import annotations

import copy as copy_module
import re
from array import array
from dataclasses import dataclass
from typing import Any, Callable, Iterable, Optional

from .docspecs_validator import DocSpecsDocument, DocSpecsValidator
from .spec_document import SpecDocument
from .spec_document_markdown import MarkdownFenceTracker, SpecDocumentMarkdown
from .spec_notation import (
    NotationElement,
    NotationFinding,
    NotationFindingCode,
    _WS_RE,
    _js_trim,
    scan_notation,
)
from .spec_review_annotations import count_annotations_text, strip_annotations_text
from .spec_schema_validation import validate_spec_document
from .spec_validator import validate_document

#: The kind names a strip takes, in report and header order.
spec_strip_kind_names: tuple[str, ...] = (
    "provenance",
    "trace",
    "editorial",
    "aside",
    "linked",
    "derived",
    "comments",
)

#: The notation kinds a strip can drop, unmark or move to the appendix.
spec_strip_notation_kinds: tuple[str, ...] = (
    "provenance",
    "trace",
    "editorial",
    "aside",
)


class SpecStripUsageError(Exception):
    """A strip asked for something it cannot do; the message says which."""

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message

    def __str__(self) -> str:
        return self.message


class SpecStripOptions:
    """What a strip does with each kind. :meth:`from_names` is the checked
    form; the constructor takes the sets as they are."""

    def __init__(
        self,
        drop: Optional[Iterable[str]] = None,
        unmark: Optional[Iterable[str]] = None,
        appendix: Optional[Iterable[str]] = None,
        appendix_references: bool = False,
        heading_divs: bool = False,
    ) -> None:
        #: The kinds removed with their content.
        self.drop: set[str] = set(drop or ())
        #: The kinds whose markers go and whose content stays.
        self.unmark: set[str] = set(unmark or ())
        #: The kinds moved, with their content, into the appendix *Notes*.
        self.appendix: set[str] = set(appendix or ())
        #: Whether each moved element leaves a link ``[n]`` to its entry.
        self.appendix_references: bool = appendix_references is True
        #: Whether sections deeper than level 6 are styled-div headings.
        self.heading_divs: bool = heading_divs is True

    @property
    def writes_no_linked_markers(self) -> bool:
        """Whether the rendition leaves the ``linked`` markers out
        (SOM §11.11): ``linked`` dropped or unmarked."""
        return "linked" in self.drop or "linked" in self.unmark

    @property
    def writes_no_generated_parts(self) -> bool:
        """Whether the rendition leaves the generated parts out (SOM §11.12):
        ``derived`` dropped or unmarked."""
        return "derived" in self.drop or "derived" in self.unmark

    @staticmethod
    def from_names(
        drop: Optional[Iterable[str]] = None,
        unmark: Optional[Iterable[str]] = None,
        appendix: Optional[Iterable[str]] = None,
        appendix_references: bool = False,
        heading_divs: bool = False,
    ) -> "SpecStripOptions":
        """The options from the names a user gives, each item possibly
        comma-joined. ``all`` stands for every kind the list can hold that no
        other list names explicitly. Raises :class:`SpecStripUsageError` for
        an unknown name, a name in two lists, ``comments`` to unmark or move,
        ``linked`` / ``derived`` to move, and appendix references without an
        appendix."""

        def names(items: Optional[Iterable[str]]) -> list[str]:
            out: list[str] = []
            for item in items or ():
                for n in item.split(","):
                    if n.strip() != "":
                        out.append(n.strip())
            return out

        lists: dict[str, list[str]] = {
            "drop": names(drop),
            "unmark": names(unmark),
            "appendix": names(appendix),
        }
        known = [*spec_strip_kind_names, "all"]
        for key, items in lists.items():
            for n in items:
                if n not in known:
                    raise SpecStripUsageError(
                        f'unknown kind name "{n}" in {key}; known names: '
                        f"{', '.join(known)}"
                    )
        keys = list(lists)
        for i in range(len(keys)):
            for j in range(i + 1, len(keys)):
                for n in lists[keys[i]]:
                    if n in lists[keys[j]]:
                        raise SpecStripUsageError(
                            f'kind name "{n}" is in both {keys[i]} and {keys[j]}'
                        )
        if "comments" in lists["unmark"]:
            raise SpecStripUsageError(
                "comments cannot be unmarked: a review annotation has no reading "
                "without its markers; drop it or leave it"
            )
        if "comments" in lists["appendix"]:
            raise SpecStripUsageError(
                "comments cannot be moved to the appendix; drop them or leave them"
            )
        for k in ("linked", "derived"):
            if k in lists["appendix"]:
                raise SpecStripUsageError(
                    f"{k} cannot be moved to the appendix: the renderer writes it "
                    "from the document; drop it or leave it"
                )
        explicit = {n for items in lists.values() for n in items if n != "all"}

        def expand(key: str, every: Iterable[str]) -> set[str]:
            out: set[str] = set()
            for n in lists[key]:
                if n == "all":
                    out.update(k for k in every if k not in explicit)
                else:
                    out.add(n)
            return out

        appendix_kinds = expand("appendix", spec_strip_notation_kinds)
        if appendix_references is True and not appendix_kinds:
            raise SpecStripUsageError(
                "appendix references need an appendix: name its kinds"
            )
        return SpecStripOptions(
            drop=expand("drop", spec_strip_kind_names),
            unmark=expand("unmark", [*spec_strip_notation_kinds, "linked", "derived"]),
            appendix=appendix_kinds,
            appendix_references=appendix_references is True,
            heading_divs=heading_divs is True,
        )

    @property
    def keeping(self) -> "SpecStripOptions":
        """The options of the emptying rule: what would go is unmarked
        instead."""
        unmark = set(self.unmark) | set(self.appendix)
        unmark.update(k for k in self.drop if k != "comments")
        return SpecStripOptions(
            drop={"comments"} if "comments" in self.drop else set(),
            unmark=unmark,
            heading_divs=self.heading_divs,
        )

    @property
    def in_entry(self) -> "SpecStripOptions":
        """The options an appendix entry's own content is stripped with
        (internal)."""
        drop = set(self.drop)
        drop.discard("comments")
        return SpecStripOptions(drop=drop, unmark=set(self.unmark) | set(self.appendix))

    @staticmethod
    def ordered(names: Iterable[str]) -> list[str]:
        """*names* in the canonical order of :data:`spec_strip_kind_names`."""
        s = set(names)
        return [k for k in spec_strip_kind_names if k in s]

    def to_json(self) -> dict[str, Any]:
        return {
            "drop": SpecStripOptions.ordered(self.drop),
            "unmark": SpecStripOptions.ordered(self.unmark),
            "appendix": SpecStripOptions.ordered(self.appendix),
            "appendixReferences": self.appendix_references,
            "headingDivs": self.heading_divs,
        }

    def __repr__(self) -> str:
        return f"SpecStripOptions({self.to_json()!r})"


class SpecReadableSource:
    """The source a readable rendition was made from, for its header."""

    def __init__(
        self,
        file: str,
        revision: Optional[str] = None,
        commit: Optional[str] = None,
        dirty: bool = False,
    ) -> None:
        #: The source document's file.
        self.file = file
        #: Its revision, or ``None``.
        self.revision = revision
        #: The commit it was read at, or ``None``.
        self.commit = commit
        #: Whether the file differed from that commit.
        self.dirty = dirty is True

    def __repr__(self) -> str:
        return (
            f"SpecReadableSource({self.file!r}, revision={self.revision!r}, "
            f"commit={self.commit!r}, dirty={self.dirty!r})"
        )


_READABLE_HEADER = re.compile(r"^<!--\s*readable:(.*)-->$")


class SpecReadableHeader:
    """The readable header line of a stripped rendition (SOM §11.1):
    ``<!-- readable: drop=…; unmark=…; appendix=…; appendix-references;
    headings=divs; of=<file>@<revision>; commit=<sha>[+dirty] -->``. Parts
    that do not apply are left out; :meth:`format` and :meth:`parse` are
    inverse."""

    def __init__(
        self, options: SpecStripOptions, source: Optional[SpecReadableSource] = None
    ) -> None:
        self.options = options
        self.source = source

    def format(self) -> str:
        """The header line."""
        o = self.options
        s = self.source
        parts: list[str] = []
        if o.drop:
            parts.append(f"drop={','.join(SpecStripOptions.ordered(o.drop))}")
        if o.unmark:
            parts.append(f"unmark={','.join(SpecStripOptions.ordered(o.unmark))}")
        if o.appendix:
            parts.append(f"appendix={','.join(SpecStripOptions.ordered(o.appendix))}")
        if o.appendix_references:
            parts.append("appendix-references")
        if o.heading_divs:
            parts.append("headings=divs")
        if s is not None:
            rev = f"@{s.revision}" if s.revision is not None else ""
            parts.append(f"of={s.file}{rev}")
            if s.commit is not None:
                parts.append(f"commit={s.commit}{'+dirty' if s.dirty else ''}")
        if not parts:
            return "<!-- readable: -->"
        return f"<!-- readable: {'; '.join(parts)} -->"

    @staticmethod
    def parse(line: str) -> Optional["SpecReadableHeader"]:
        """*line* read as a readable header, or ``None``."""
        m = _READABLE_HEADER.match(_js_trim(line))
        if m is None:
            return None
        drop: list[str] = []
        unmark: list[str] = []
        appendix: list[str] = []
        refs = False
        divs = False
        file: Optional[str] = None
        revision: Optional[str] = None
        commit: Optional[str] = None
        dirty = False
        for raw in m.group(1).split(";"):
            part = _js_trim(raw)
            if part == "":
                continue
            eq = part.find("=")
            key = part if eq < 0 else part[:eq]
            value = "" if eq < 0 else part[eq + 1 :]
            if key == "drop":
                drop.append(value)
            elif key == "unmark":
                unmark.append(value)
            elif key == "appendix":
                appendix.append(value)
            elif key == "appendix-references" and eq < 0:
                refs = True
            elif key == "headings" and value == "divs":
                divs = True
            elif key == "of":
                at = value.rfind("@")
                file = value if at < 0 else value[:at]
                revision = None if at < 0 else value[at + 1 :]
            elif key == "commit":
                dirty = value.endswith("+dirty")
                commit = value[: len(value) - 6] if dirty else value
            else:
                return None
        if file is None and commit is not None:
            return None
        try:
            options = SpecStripOptions.from_names(
                drop=drop,
                unmark=unmark,
                appendix=appendix,
                appendix_references=refs,
                heading_divs=divs,
            )
        except SpecStripUsageError:
            return None
        return SpecReadableHeader(
            options,
            None if file is None else SpecReadableSource(file, revision, commit, dirty),
        )

    def __repr__(self) -> str:
        return f"SpecReadableHeader({self.format()!r})"


class SpecStripPiece:
    """One piece a strip removed from a value, anchored in the stripped text.
    Offsets are UTF-16 code units."""

    def __init__(
        self, anchor: int, origin: int, removed: str, inserted: str, labels: list[str]
    ) -> None:
        #: The offset in the stripped text the piece stands at.
        self.anchor = anchor
        #: The offset in the original text the piece starts at.
        self.origin = origin
        #: The original text the piece removed.
        self.removed = removed
        #: The text the stripped value holds in its place.
        self.inserted = inserted
        #: What removed it, sorted.
        self.labels = labels

    def to_json(self) -> dict[str, Any]:
        return {
            "anchor": self.anchor,
            "origin": self.origin,
            "removed": self.removed,
            "inserted": self.inserted,
            "labels": list(self.labels),
        }

    def __repr__(self) -> str:
        return f"SpecStripPiece({self.to_json()!r})"


class SpecAppendixEntry:
    """One entry of a stripped rendition's appendix *Notes*. ``value`` is the
    value it came from when a document is stripped (``None`` for the strip of
    one value)."""

    def __init__(self, number: int, kind: str, text: str, value: Any = None) -> None:
        self.number = number
        self.kind = kind
        self.text = text
        self.value = value

    def to_json(self) -> dict[str, Any]:
        out: dict[str, Any] = {"number": self.number, "kind": self.kind, "text": self.text}
        if self.value is not None:
            out["value"] = self.value.to_json()
        return out

    def __repr__(self) -> str:
        return f"SpecAppendixEntry({self.to_json()!r})"


class SpecStripTextResult:
    """The result of stripping one value (:func:`strip_notation_text`)."""

    def __init__(
        self,
        text: str,
        pieces: list[SpecStripPiece],
        dropped: dict[str, int],
        unmarked: dict[str, int],
        appended: dict[str, int],
        marks_dropped: int,
        appendix: list[SpecAppendixEntry],
        findings: list[NotationFinding],
    ) -> None:
        self.text = text
        self.pieces = pieces
        self.dropped = dropped
        self.unmarked = unmarked
        self.appended = appended
        #: The review marks that went inside a dropped element.
        self.marks_dropped = marks_dropped
        self.appendix = appendix
        #: The error findings a refused value has.
        self.findings = findings

    @property
    def refused(self) -> bool:
        """Whether the value was refused for its findings."""
        return len(self.findings) > 0

    def to_json(self) -> dict[str, Any]:
        return {
            "text": self.text,
            "dropped": dict(self.dropped),
            "unmarked": dict(self.unmarked),
            "appended": dict(self.appended),
            "marksDropped": self.marks_dropped,
            "appendix": [e.to_json() for e in self.appendix],
            "pieces": [p.to_json() for p in self.pieces],
            "refused": [f.code.value for f in self.findings],
        }


def strip_notation_text(value: str, options: SpecStripOptions) -> SpecStripTextResult:
    """Strips one value with *options* (SOM §11.10): comments first, then the
    notation from the outside in, then the whitespace the removals leave.
    Appendix entries are numbered from 1. A value whose notation has an error
    finding (other than ``rejectedBlock``) is refused and returned
    unchanged."""
    return _Plan(value, options).finish(lambda i: i + 1)


# ---------------------------------------------------------------------------
# The strip of a whole document.


class SpecStripValueRef:
    """A value of a document: its content, a form field or its headline."""

    def __init__(self, path: str, field: Optional[str] = None, headline: bool = False) -> None:
        self.path = path
        self.field = field
        self.headline = headline is True

    def read(self, doc: SpecDocument) -> str:
        """The value in *doc* (``""`` when it holds none)."""
        if self.headline:
            v = doc.headline(self.path)
        elif self.field is not None:
            v = doc.form_field(self.path, self.field)
        else:
            v = doc.content(self.path)
        return v if v is not None else ""

    def write(self, doc: SpecDocument, value: str) -> None:
        """Sets the value in *doc*."""
        if self.headline:
            doc.set_headline(self.path, value)
        elif self.field is not None:
            doc.set_form_field(self.path, self.field, value)
        else:
            doc.set_content(self.path, value)

    @property
    def label(self) -> str:
        if self.headline:
            return f"{self.path} (headline)"
        if self.field is not None:
            return f"{self.path}/{self.field}"
        return self.path

    def to_json(self) -> dict[str, Any]:
        out: dict[str, Any] = {"path": self.path}
        if self.field is not None:
            out["field"] = self.field
        if self.headline:
            out["headline"] = True
        return out

    def __eq__(self, other: object) -> bool:
        return (
            isinstance(other, SpecStripValueRef)
            and other.path == self.path
            and other.field == self.field
            and other.headline == self.headline
        )

    def __hash__(self) -> int:
        return hash((self.path, self.field, self.headline))

    def __str__(self) -> str:
        return self.label

    def __repr__(self) -> str:
        return f"SpecStripValueRef({self.label!r})"


class SpecStrippedValue:
    """One value a strip changed, with what went."""

    def __init__(
        self,
        ref: SpecStripValueRef,
        original: str,
        stripped: str,
        pieces: list[SpecStripPiece],
    ) -> None:
        self.ref = ref
        self.original = original
        self.stripped = stripped
        self.pieces = pieces

    def __repr__(self) -> str:
        return f"SpecStrippedValue({self.ref.label!r}, {self.stripped!r})"


class SpecStripKept:
    """A value the emptying rule kept."""

    def __init__(self, ref: SpecStripValueRef, finding: str) -> None:
        self.ref = ref
        self.finding = finding

    def __str__(self) -> str:
        return f"KEPT (would empty a required value): {self.ref} — {self.finding}"

    def __repr__(self) -> str:
        return f"SpecStripKept({self.ref.label!r}, {self.finding!r})"


class SpecStripFinding:
    """A reason a stripped document is not valid."""

    def __init__(
        self, kind: str, message: str, ref: Optional[SpecStripValueRef] = None
    ) -> None:
        #: ``notation``, ``instance``, ``schema`` or ``parse``.
        self.kind = kind
        self.message = message
        self.ref = ref

    def __str__(self) -> str:
        at = f"{self.ref}: " if self.ref is not None else ""
        return f"{self.kind}: {at}{self.message}"

    def __repr__(self) -> str:
        return f"SpecStripFinding({self!s})"


class SpecStripResult:
    """The result of :meth:`SpecDocumentStrip.strip`."""

    def __init__(
        self,
        document: SpecDocument,
        values: list[SpecStrippedValue],
        kept: list[SpecStripKept],
        removed_items: list[str],
        appendix: list[SpecAppendixEntry],
        dropped: dict[str, int],
        unmarked: dict[str, int],
        appended: dict[str, int],
        marks_dropped: int,
        readable_header: str,
        readable: Optional[str],
        findings: list[SpecStripFinding],
    ) -> None:
        #: The stripped copy.
        self.document = document
        #: The values the strip changed.
        self.values = values
        #: The values the emptying rule kept.
        self.kept = kept
        #: The list items left empty and removed.
        self.removed_items = removed_items
        #: The appendix *Notes*, numbered through the rendition.
        self.appendix = appendix
        self.dropped = dropped
        self.unmarked = unmarked
        self.appended = appended
        #: The review marks that went inside a dropped element.
        self.marks_dropped = marks_dropped
        #: The readable header line.
        self.readable_header = readable_header
        #: The ``.readable.md`` (``None`` without a model).
        self.readable = readable
        #: Why the stripped document is not valid (empty when it is).
        self.findings = findings

    @property
    def ok(self) -> bool:
        """Whether the stripped document is valid and may be written."""
        return not self.findings

    @property
    def report(self) -> list[str]:
        """The report: what was dropped, unmarked, moved and kept per kind."""
        out: list[str] = []
        for k in spec_strip_kind_names:
            d = self.dropped.get(k, 0)
            u = self.unmarked.get(k, 0)
            a = self.appended.get(k, 0)
            if d + u + a > 0:
                out.append(f"{k}: {d} dropped, {u} unmarked, {a} moved")
        if self.marks_dropped > 0:
            out.append(f"review marks inside dropped elements: {self.marks_dropped}")
        for k in self.kept:
            out.append(str(k))
        return out


class SpecDocumentStrip:
    """Stripping a whole document (SOM §11.10)."""

    @staticmethod
    def strip(
        document: SpecDocument,
        options: SpecStripOptions,
        *,
        model: Any = None,
        schema: Any = None,
        root_type: Optional[str] = None,
        file_stem: Optional[str] = None,
        document_files: Optional[dict[str, str]] = None,
        source: Optional[SpecReadableSource] = None,
    ) -> SpecStripResult:
        """Strips every value of *document* — content, form-field values,
        scalar list items and stored headlines — into a copy. Given a *model*
        it also applies the emptying rule, removes list items left empty,
        numbers the appendix through the rendition, renders the
        ``.readable.md`` (with the readable header made from *options* and
        *source*) and checks it; *schema* (a ``DocSpecsSchema``) adds the
        schema tier to that check."""
        refs = SpecDocumentStrip._value_refs(document)
        findings: list[SpecStripFinding] = []
        plans: dict[int, _Plan] = {}
        for index, ref in enumerate(refs):
            text = ref.read(document)
            if text == "":
                continue
            plan = _Plan(text, options)
            if plan.findings:
                for f in plan.findings:
                    findings.append(SpecStripFinding("notation", _finding_text(f), ref))
                continue
            if plan.changes():
                plans[index] = plan

        copy = SpecDocument()
        copy.load_json(copy_module.deepcopy(document.to_json()))
        provisional: dict[tuple[int, int], int] = {}
        nxt = 1
        for index in range(len(refs)):
            plan = plans.get(index)
            if plan is None:
                continue
            for i in range(len(plan.entries)):
                provisional[(index, i)] = nxt
                nxt += 1

        def apply(numbers: dict[tuple[int, int], int]) -> None:
            for index, plan in plans.items():
                refs[index].write(
                    copy, plan.finish(lambda i, index=index: numbers.get((index, i), 0)).text
                )

        apply(provisional)
        kept: list[SpecStripKept] = []
        base: dict[str, str] = (
            {}
            if model is None
            else SpecDocumentStrip._tier_findings(model, schema, root_type, document)
        )
        removed_items: list[str] = (
            []
            if model is None
            else SpecDocumentStrip._emptying_rule(
                model, schema, root_type, base, document, copy, refs, plans, kept, options
            )
        )

        # The appendix, numbered through the rendition.
        entries: list[tuple[int, int]] = []
        for index in range(len(refs)):
            plan = plans.get(index)
            if plan is None:
                continue
            for i in range(len(plan.entries)):
                entries.append((index, i))
        root = None
        if model is not None:
            try:
                root = copy.root_to_export(model, root_type)
            except Exception as e:  # noqa: BLE001 - reported as a finding
                findings.append(SpecStripFinding("parse", str(e)))
        titles: dict[str, str] = {}
        codec_args = {"file_stem": file_stem, "document_files": document_files}
        if entries and model is not None and root is not None:
            rendition = SpecDocumentMarkdown(model, copy, **codec_args).export_root_with_map(root)
            lines = rendition.markdown.split("\n")
            order: dict[str, int] = {}
            for line, path in rendition.heading_paths.items():
                order[path] = line
                titles[path] = SpecDocumentStrip._heading_title(lines[line - 1])

            def section_line(ref: SpecStripValueRef) -> int:
                best = 0
                best_length = -1
                for p, line in order.items():
                    if (ref.path == p or ref.path.startswith(f"{p}/")) and len(p) > best_length:
                        best = line
                        best_length = len(p)
                return best

            entries.sort(key=lambda e: (section_line(refs[e[0]]), e[0], e[1]))
        numbers = {e: k + 1 for k, e in enumerate(entries)}
        apply(numbers)

        values: list[SpecStrippedValue] = []
        appendix: list[SpecAppendixEntry] = []
        dropped: dict[str, int] = {}
        unmarked: dict[str, int] = {}
        appended: dict[str, int] = {}
        marks_dropped = 0

        def add(into: dict[str, int], frm: dict[str, int]) -> None:
            for k, v in frm.items():
                into[k] = into.get(k, 0) + v

        for index in range(len(refs)):
            plan = plans.get(index)
            if plan is None:
                continue
            r = plan.finish(lambda i, index=index: numbers.get((index, i), 0))
            values.append(SpecStrippedValue(refs[index], plan.o, r.text, r.pieces))
            add(dropped, r.dropped)
            add(unmarked, r.unmarked)
            add(appended, r.appended)
            marks_dropped += r.marks_dropped
            for e in r.appendix:
                appendix.append(SpecAppendixEntry(e.number, e.kind, e.text, refs[index]))
        appendix.sort(key=lambda e: e.number)

        header = SpecReadableHeader(options, source).format()
        readable: Optional[str] = None
        if model is not None and root is not None:
            rendition = SpecDocumentMarkdown(
                model,
                copy,
                **codec_args,
                heading_divs=options.heading_divs,
                readable_header=header,
                linked_markers=not options.writes_no_linked_markers,
                generated_parts=not options.writes_no_generated_parts,
            ).export_root_with_map(root)
            if not titles and appendix:
                lines = rendition.markdown.split("\n")
                for line, path in rendition.heading_paths.items():
                    titles[path] = SpecDocumentStrip._heading_title(lines[line - 1])
            readable = (
                rendition.markdown
                if not appendix
                else SpecDocumentStrip._with_appendix(
                    rendition.markdown, appendix, titles, options.appendix_references
                )
            )
            SpecDocumentStrip._check_output(
                model,
                schema,
                root,
                root_type,
                base,
                document,
                copy,
                readable,
                codec_args,
                findings,
            )
        return SpecStripResult(
            copy,
            values,
            kept,
            removed_items,
            appendix,
            dropped,
            unmarked,
            appended,
            marks_dropped,
            header,
            readable,
            findings,
        )

    @staticmethod
    def _value_refs(doc: SpecDocument) -> list[SpecStripValueRef]:
        out: list[SpecStripValueRef] = []
        for p in sorted(doc.headline_paths):
            out.append(SpecStripValueRef(p, None, True))
        for p in sorted(doc.content_paths):
            out.append(SpecStripValueRef(p))
        for p in sorted(doc.form_paths):
            for f in sorted(doc.form_field_names(p)):
                out.append(SpecStripValueRef(p, f))
        return out

    @staticmethod
    def _emptying_rule(
        model: Any,
        schema: Any,
        root_type: Optional[str],
        base: dict[str, str],
        document: SpecDocument,
        copy: SpecDocument,
        refs: list[SpecStripValueRef],
        plans: dict[int, "_Plan"],
        kept: list[SpecStripKept],
        options: SpecStripOptions,
    ) -> list[str]:
        """The emptying rule: a value whose strip would add a validity
        finding is unmarked instead (kept), a list item left without any
        value is removed unless that adds a finding. Answers the removed
        items."""
        kept_refs: set[int] = set()
        keep_items: set[str] = set()
        candidates = SpecDocumentStrip._items_above(copy, [refs[i] for i in plans])

        def emptied_items() -> list[str]:
            return [
                item
                for item in candidates
                if item not in keep_items
                and document.has_values_under(item)
                and not copy.has_values_under(item)
            ]

        def concerns(finding_path: str, path: str) -> bool:
            return (
                finding_path == ""
                or path == finding_path
                or path.startswith(f"{finding_path}/")
                or path.startswith(f"{finding_path}-")
                or finding_path.startswith(f"{path}/")
            )

        for _ in range(8):
            items = emptied_items()
            scratch = copy
            if items:
                scratch = SpecDocument()
                scratch.load_json(copy_module.deepcopy(copy.to_json()))
            for item in items:
                scratch.remove_list_item(item)
            now = SpecDocumentStrip._tier_findings(model, schema, root_type, scratch)
            added = {k: v for k, v in now.items() if k not in base}
            if not added:
                break
            emptied = [
                index
                for index in range(len(refs))
                if index in plans
                and index not in kept_refs
                and _js_trim(refs[index].read(copy)) == ""
            ]
            changed = False
            for key, finding_path in added.items():
                for item in items:
                    if concerns(finding_path, item) and item not in keep_items:
                        keep_items.add(item)
                        changed = True
                for index in emptied:
                    ref = refs[index]
                    if index in kept_refs or not concerns(finding_path, ref.path):
                        continue
                    kept_refs.add(index)
                    kept.append(SpecStripKept(ref, key))
                    keeping = _Plan(plans[index].o, options.keeping)
                    text = keeping.finish(lambda i: 0).text
                    if _js_trim(text) == "":
                        del plans[index]
                        ref.write(copy, ref.read(document))
                    else:
                        plans[index] = keeping
                        ref.write(copy, text)
                    changed = True
            if not changed:
                break
        items = emptied_items()
        for item in items:
            copy.remove_list_item(item)
        return items

    @staticmethod
    def _items_above(doc: SpecDocument, refs: list[SpecStripValueRef]) -> list[str]:
        """The list items at or above the paths of *refs*."""
        items: set[str] = set()
        for lst in doc.list_paths:
            items.update(doc.list_items(lst))
        out: set[str] = set()
        for ref in refs:
            p = ref.path
            if p in items:
                out.add(p)
            for i, c in enumerate(p):
                if c == "/" and p[:i] in items:
                    out.add(p[:i])
        return sorted(out)

    @staticmethod
    def _tier_findings(
        model: Any, schema: Any, root_type: Optional[str], doc: SpecDocument
    ) -> dict[str, str]:
        """The instance tier's and (with *schema*) the schema tier's findings
        of *doc*: key → the document path it concerns."""
        out: dict[str, str] = {}
        for e in validate_document(model, doc):
            out[f"instance {e.code.value} {e.path}: {e.message}"] = e.path
        if schema is not None:
            try:
                for v in validate_spec_document(model, doc, schema, root_type):
                    out[f"schema {v.rule.value} {v.section_id or ''}: {v.message}"] = (
                        v.path or ""
                    )
            except Exception:  # noqa: BLE001
                pass  # No single root to render: the schema tier cannot judge it.
        return out

    @staticmethod
    def _check_output(
        model: Any,
        schema: Any,
        root: Any,
        root_type: Optional[str],
        before: dict[str, str],
        document: SpecDocument,
        copy: SpecDocument,
        readable: str,
        codec_args: dict[str, Any],
        findings: list[SpecStripFinding],
    ) -> None:
        """The rendition reads back as the stripped copy, and the copy adds
        no validity finding to the original's."""
        parsed = SpecDocumentMarkdown(model, SpecDocument(), **codec_args).parse(readable)
        for r in parsed.rejections:
            findings.append(SpecStripFinding("parse", f"the rendition rejects: {r}"))
        prefix = root.section_id or root.type

        def in_root(p: str) -> bool:
            return p == prefix or p.startswith(f"{prefix}/")

        def compare(what: str, want: dict[str, str], got: dict[str, str]) -> None:
            for k in sorted(set(want) | set(got)):
                if not in_root(k) or want.get(k) == got.get(k):
                    continue
                # A wrapped paragraph written in a table cell reads back on
                # one line (SOM §11.4).
                w = want.get(k)
                g = got.get(k)
                if w is not None:
                    joined = SpecDocumentMarkdown.wrapped_paragraph_joined(w)
                    if joined is not None and joined == g:
                        continue
                g_text = "nothing" if g is None else f'"{g}"'
                w_text = "nothing" if w is None else f'"{w}"'
                findings.append(
                    SpecStripFinding("parse", f"{what} at {k} reads back as {g_text} instead of {w_text}")
                )

        want_content = {p: copy.content(p) for p in copy.content_paths}
        compare("content", want_content, dict(parsed.content))
        want_forms: dict[str, str] = {}
        for p in copy.form_paths:
            for f in copy.form_field_names(p):
                want_forms[f"{p}/{f}"] = copy.form_field(p, f)
        got_forms: dict[str, str] = {}
        for p, fields in parsed.forms.items():
            for f, v in fields.items():
                got_forms[f"{p}/{f}"] = v
        compare("the form field", want_forms, got_forms)
        for key in SpecDocumentStrip._tier_findings(model, schema, root_type, copy):
            if key not in before:
                findings.append(
                    SpecStripFinding("schema" if key.startswith("schema") else "instance", key)
                )
        if schema is not None:
            original = SpecDocumentMarkdown(model, document, **codec_args).export_root(root)

            def key_of(v: Any) -> str:
                return f"{v.rule.value} {v.section_id or ''}: {v.message}"

            validator = DocSpecsValidator(schema, tom_specs=True)
            had = {key_of(v) for v in validator.validate_markdown(original)}
            for v in validator.validate_markdown(readable):
                if key_of(v) not in had:
                    findings.append(
                        SpecStripFinding("schema", f"the rendition: line {v.line}: {key_of(v)}")
                    )

    @staticmethod
    def _heading_title(line: str) -> str:
        """The title a heading line (or styled-div heading) shows."""
        div = SpecDocumentMarkdown.heading_div(line)
        if div is not None:
            rest = div[1]
        else:
            h = SpecDocumentMarkdown.heading_line.match(line)
            rest = h.group(2) if h is not None else line
        c = SpecDocumentMarkdown.headline_comment.match(_js_trim(rest))
        title = _js_trim(rest) if c is None else _js_trim(c.group(3) or "")
        return DocSpecsDocument.strip_own_anchor(title, c.group(1) if c is not None else "")

    @staticmethod
    def _with_appendix(
        markdown: str,
        entries: list[SpecAppendixEntry],
        titles: dict[str, str],
        references: bool,
    ) -> str:
        """*markdown* followed by the appendix marker and the *Notes*, one
        ``###`` group per section."""

        def section_of(ref: SpecStripValueRef) -> tuple[str, str]:
            best = ""
            title = ref.path
            for p, t in titles.items():
                if (ref.path == p or ref.path.startswith(f"{p}/")) and len(p) > len(best):
                    best = p
                    title = t
            return (ref.path if best == "" else best), title

        b = [
            markdown.rstrip("\n"),
            f"\n\n{SpecDocumentMarkdown.appendix_marker}\n\n## Notes\n",
        ]
        section: Optional[str] = None
        for e in entries:
            path, title = ("", "") if e.value is None else section_of(e.value)
            if path != section:
                b.append(f"\n### {title}\n")
                section = path
            text = "\n".join(
                f"\\{line}" if line.startswith("#") else line for line in e.text.split("\n")
            )
            if references:
                b.append(
                    f'\n<a id="note-{e.number}"></a>**[{e.number}]** {text} '
                    f"[↩](#note-{e.number}-ref)\n"
                )
            else:
                b.append(f"\n**[{e.number}]** {text}\n")
        return "".join(b)


def _finding_text(f: NotationFinding) -> str:
    return f"{f.code.value} (line {f.line}): {f.message}"


# ---------------------------------------------------------------------------
# UTF-16 code-unit strings.


def _utf16_string(s: str) -> str:
    """*s* as a string of UTF-16 code units: one character per unit, a
    supplementary character as its two surrogates."""
    if all(ord(c) < 0x10000 for c in s):
        return s
    units = array("H")
    units.frombytes(s.encode("utf-16-le", "surrogatepass"))
    return "".join(map(chr, units))


def _from_utf16_string(u: str) -> str:
    """The ordinary string of a UTF-16 code-unit string: surrogate pairs
    joined again."""
    if all(not 0xD800 <= ord(c) <= 0xDFFF for c in u):
        return u
    return u.encode("utf-16-le", "surrogatepass").decode("utf-16-le", "surrogatepass")


# ---------------------------------------------------------------------------
# One value's strip.


@dataclass
class _Insert:
    label: str
    text: Optional[str] = None
    entry: Optional[int] = None


@dataclass
class _Entry:
    """An appendix entry before it is numbered."""

    kind: str
    text: str


_KEEP = 0
_DEL = 1
_INS = 2


@dataclass
class _Op:
    """One step of an edit script over UTF-16 code units."""

    type: int
    char: str
    label: Optional[str]


def _space(c: str) -> bool:
    return c == " " or c == "\t"


def _blank(c: str) -> bool:
    """``c.trim() === ''`` for one code unit."""
    return _WS_RE.match(c) is not None


def _count(m: dict[str, int], k: str) -> None:
    m[k] = m.get(k, 0) + 1


class _Plan:
    """The strip of one value, planned once and finished for any numbering.

    ``o`` is the value as given; ``t`` the value the notation strip works on
    (``o`` without its comments when they are dropped) as a UTF-16 code-unit
    string, the indexing of ``del_`` / ``ins`` and the scanner's offsets."""

    def __init__(self, o: str, options: SpecStripOptions) -> None:
        self.o = o
        self.options = options
        self.script1: Optional[list[_Op]] = None
        self.block_del: list[bool] = []
        self.ins: dict[int, list[_Insert]] = {}
        self.dropped: dict[str, int] = {}
        self.unmarked: dict[str, int] = {}
        self.appended: dict[str, int] = {}
        self.marks_dropped = 0
        self.entries: list[_Entry] = []
        self.findings: list[NotationFinding] = [
            f
            for f in scan_notation(o, tom_specs=True).findings
            if f.severity == "error" and f.code != NotationFindingCode.REJECTED_BLOCK
        ]
        if self.findings:
            self.t = _utf16_string(o)
            self.del_: list[Optional[str]] = [None] * len(self.t)
            return
        o16 = _utf16_string(o)
        if "comments" in options.drop:
            stripped = strip_annotations_text(o)
            self.t = _utf16_string(stripped)
            if stripped != o:
                self.dropped["comments"] = count_annotations_text(o)
                self.script1 = _diff(o16, self.t, "comments")
        else:
            stripped = o
            self.t = o16
        self.del_ = [None] * len(self.t)
        self.block_del = [False] * len(self.t)
        self._process(scan_notation(stripped, tom_specs=True).elements)
        if "comments" not in options.drop:
            self._marks()
        if any(d is not None for d in self.del_):
            self._normalise()

    def changes(self) -> bool:
        """Whether the strip changes the value."""
        return not self.findings and (
            self.script1 is not None
            or any(d is not None for d in self.del_)
            or len(self.ins) > 0
        )

    def _mark(self, s: int, e: int, label: str, block: bool = False) -> None:
        i = s
        n = len(self.t)
        while i < e and i < n:
            if self.del_[i] is None:
                self.del_[i] = label
            if block:
                self.block_del[i] = True
            i += 1

    def _insert(self, at: int, x: _Insert) -> None:
        self.ins.setdefault(at, []).append(x)

    def _process(self, elements: list[NotationElement]) -> None:
        t = self.t
        for e in elements:
            k = e.kind
            # A `linked` span (SOM §11.11) or a `derived` block (SOM §11.12)
            # is removed by `-drop:` and `-unmark:` alike: its text without
            # its markers would read back as content.
            if (
                e.is_registered
                and k in ("linked", "derived")
                and (k in self.options.drop or k in self.options.unmark)
            ):
                self._remove(e, f"{k}:drop", None)
                _count(self.dropped, k)
                continue
            secondary = e.is_registered and k is not None and k in spec_strip_notation_kinds
            if not secondary:
                self._process(e.children)
                continue
            assert k is not None
            if k in self.options.drop:
                self._remove(e, f"{k}:drop", None)
                _count(self.dropped, k)
                continue
            if k in self.options.appendix:
                if e.type == "citation":
                    content = t[e.start : e.end]
                else:
                    content = t[e.content_start : e.content_end].rstrip("\n")
                self.entries.append(
                    _Entry(
                        k,
                        strip_notation_text(
                            _from_utf16_string(content), self.options.in_entry
                        ).text,
                    )
                )
                self._remove(e, f"{k}:appendix", len(self.entries) - 1)
                _count(self.appended, k)
                continue
            if k in self.options.unmark:
                self._unmark(e, f"{k}:unmark")
                _count(self.unmarked, k)
            self._process(e.children)

    def _remove(self, e: NotationElement, label: str, entry: Optional[int]) -> None:
        t = self.t
        reference = entry is not None and self.options.appendix_references
        if e.type == "div":
            self._mark(e.start, e.end, label, True)
            if reference:
                self._insert(e.start, _Insert(label, entry=entry))
            return
        s = e.start
        if s > 0 and _space(t[s - 1]) and self.del_[s - 1] is None:
            self.del_[s - 1] = label
        elif (
            not reference
            and (s == 0 or t[s - 1] == "\n")
            and e.end < len(t)
            and _space(t[e.end])
        ):
            self.del_[e.end] = label
        self._mark(e.start, e.end, label)
        if reference:
            self._insert(e.start, _Insert(label, entry=entry))

    def _unmark(self, e: NotationElement, label: str) -> None:
        if e.type == "div":
            if e.content_start >= e.content_end:
                self._mark(e.start, e.end, label, True)
            else:
                self._mark(e.start, e.content_start, label, True)
                self._mark(e.content_end - 1, e.end, label, True)
        elif e.type == "span":
            self._mark(e.start, e.start + 1, label)
            self._mark(e.content_end, e.end, label)
        else:
            self._mark(e.start + 1, e.content_start, label)

    def _marks(self) -> None:
        for m in _find_marks(self.t):
            if self._all_deleted(m.start, m.end):
                self.marks_dropped += 1
                continue
            if m.sep < 0:
                if self._had_text(m.body_start, m.body_end) and not self._survives(
                    m.body_start, m.body_end
                ):
                    self._remove_mark(m)
                continue
            old_had = self._had_text(m.body_start, m.sep)
            new_had = self._had_text(m.sep + 2, m.body_end)
            old_left = self._survives(m.body_start, m.sep)
            new_left = self._survives(m.sep + 2, m.body_end)
            if not old_left and not new_left and (old_had or new_had):
                self._remove_mark(m)
            elif old_had and not old_left:
                self._convert(m, "++", m.body_start, m.sep + 2)
            elif new_had and not new_left:
                self._convert(m, "--", m.sep, m.body_end)

    def _remove_mark(self, m: "_MarkAt") -> None:
        t = self.t
        s = m.start
        if s > 0 and _space(t[s - 1]) and self.del_[s - 1] is None:
            self.del_[s - 1] = "mark"
        elif (s == 0 or t[s - 1] == "\n") and m.end < len(t) and _space(t[m.end]):
            self.del_[m.end] = "mark"
        self._mark(m.start, m.end, "mark")

    def _convert(self, m: "_MarkAt", delimiter: str, s: int, e: int) -> None:
        self._mark(m.start + 1, m.start + 3, "mark")
        self._insert(m.start + 3, _Insert("mark", text=delimiter))
        self._mark(s, e, "mark")
        self._mark(m.end - 3, m.end - 1, "mark")
        self._insert(m.end - 1, _Insert("mark", text=delimiter))

    def _all_deleted(self, s: int, e: int) -> bool:
        return all(self.del_[i] is not None for i in range(s, e))

    def _had_text(self, s: int, e: int) -> bool:
        return _js_trim(self.t[s:e]) != ""

    def _survives(self, s: int, e: int) -> bool:
        for i in range(s, e):
            if self.del_[i] is None and not _blank(self.t[i]):
                return True
        return False

    def _normalise(self) -> None:
        t = self.t
        del_ = self.del_
        starts = [0]
        for i, c in enumerate(t):
            if c == "\n":
                starts.append(i + 1)
        for li, s in enumerate(starts):
            e = starts[li + 1] - 1 if li + 1 < len(starts) else len(t)
            if _js_trim(t[s:e]) == "":
                continue
            touched = False
            survives = False
            all_block = True
            for i in range(s, e):
                if del_[i] is not None:
                    touched = True
                elif not _blank(t[i]):
                    survives = True
                if not self.block_del[i]:
                    all_block = False
            for i in range(s, e + 1):
                if i in self.ins:
                    survives = True
            if not touched or survives or all_block:
                continue
            self._mark(s, e, "whitespace")
            if e < len(t):
                if del_[e] is None:
                    del_[e] = "whitespace"
            elif s > 0:
                if del_[s - 1] is None:
                    del_[s - 1] = "whitespace"
        # Blank-line runs, read on the text as it now stands.
        kept: list[int] = []
        parts: list[str] = []
        for i in range(len(t) + 1):
            for x in self.ins.get(i, ()):
                s_ = x.text if x.text is not None else "x"  # a reference is never blank
                kept.extend([-1] * len(s_))
                parts.append(s_)
            if i < len(t) and del_[i] is None:
                kept.append(i)
                parts.append(t[i])
        b = "".join(parts)

        def solid(c: str) -> bool:
            return not _blank(c)

        first_solid = 0
        while first_solid < len(b) and not solid(b[first_solid]):
            first_solid += 1
        if first_solid == len(b):
            for i in kept:
                if i >= 0 and del_[i] is None:
                    del_[i] = "whitespace"
            return
        last_solid = len(b) - 1
        while not solid(b[last_solid]):
            last_solid -= 1
        lead = b.rfind("\n", 0, first_solid + 1)
        for k in range(lead + 1):
            if kept[k] >= 0 and del_[kept[k]] is None:
                del_[kept[k]] = "whitespace"
        trail = b.find("\n", last_solid)
        if trail >= 0:
            for k in range(trail, len(b)):
                if kept[k] >= 0 and del_[kept[k]] is None:
                    del_[kept[k]] = "whitespace"
        k = first_solid
        while k < last_solid:
            if solid(b[k]):
                k += 1
                continue
            run_start = k
            while not solid(b[k]):
                k += 1
            run_end = k
            breaks = [j for j in range(run_start, run_end) if b[j] == "\n"]
            if len(breaks) <= 2:
                continue
            frm = kept[run_start - 1]
            to = kept[run_end]
            at_removal = False
            if frm >= 0 and to >= 0:
                for i in range(frm + 1, to):
                    if del_[i] is not None and del_[i] != "whitespace":
                        at_removal = True
            else:
                at_removal = True
            if not at_removal:
                continue
            for j in range(breaks[0] + 1, breaks[-1]):
                if kept[j] >= 0 and del_[kept[j]] is None:
                    del_[kept[j]] = "whitespace"

    def finish(self, number: Callable[[int], int]) -> SpecStripTextResult:
        """The result, the appendix entries numbered by *number* (entry index
        → number)."""
        if self.findings:
            return SpecStripTextResult(self.o, [], {}, {}, {}, 0, [], list(self.findings))
        t = self.t

        def insert_text(x: _Insert) -> str:
            if x.text is not None:
                return x.text
            assert x.entry is not None
            n = number(x.entry)
            return f'<a id="note-{n}-ref"></a>[\\[{n}\\]](#note-{n})'

        script2: list[_Op] = []
        for i in range(len(t) + 1):
            for x in self.ins.get(i, ()):
                for ch in _utf16_string(insert_text(x)):
                    script2.append(_Op(_INS, ch, x.label))
            if i < len(t):
                d = self.del_[i]
                script2.append(_Op(_KEEP, t[i], None) if d is None else _Op(_DEL, t[i], d))
        ops = script2 if self.script1 is None else _compose(self.script1, script2)
        out: list[str] = []
        pieces: list[SpecStripPiece] = []
        o_pos = 0
        b_pos = 0
        i = 0
        while i < len(ops):
            if ops[i].type == _KEEP:
                out.append(ops[i].char)
                o_pos += 1
                b_pos += 1
                i += 1
                continue
            anchor = b_pos
            origin = o_pos
            removed: list[str] = []
            inserted: list[str] = []
            labels: set[str] = set()
            while i < len(ops) and ops[i].type != _KEEP:
                op = ops[i]
                if op.label is not None:
                    labels.add(op.label)
                if op.type == _DEL:
                    removed.append(op.char)
                    o_pos += 1
                else:
                    inserted.append(op.char)
                    out.append(op.char)
                    b_pos += 1
                i += 1
            pieces.append(
                SpecStripPiece(
                    anchor,
                    origin,
                    _from_utf16_string("".join(removed)),
                    _from_utf16_string("".join(inserted)),
                    sorted(labels),
                )
            )
        return SpecStripTextResult(
            _from_utf16_string("".join(out)),
            pieces,
            dict(self.dropped),
            dict(self.unmarked),
            dict(self.appended),
            self.marks_dropped,
            [SpecAppendixEntry(number(k), e.kind, e.text) for k, e in enumerate(self.entries)],
            [],
        )


def _compose(s1: list[_Op], s2: list[_Op]) -> list[_Op]:
    """Composes the scripts original → middle (*s1*) and middle → result
    (*s2*)."""
    out: list[_Op] = []
    j = 0
    n2 = len(s2)
    for a in s1:
        if a.type == _DEL:
            out.append(a)
            continue
        while j < n2 and s2[j].type == _INS:
            out.append(s2[j])
            j += 1
        b = s2[j]
        j += 1
        if a.type == _KEEP:
            out.append(a if b.type == _KEEP else _Op(_DEL, a.char, b.label))
        elif b.type == _KEEP:
            out.append(a)
    while j < n2 and s2[j].type == _INS:
        out.append(s2[j])
        j += 1
    return out


def _diff(a: str, b: str, label: str) -> list[_Op]:
    """An edit script from *a* to *b* (UTF-16 code-unit strings): Myers by
    line, then by word token."""
    out: list[_Op] = []

    def chars(type_: int, s: str) -> None:
        lab = None if type_ == _KEEP else label
        for ch in s:
            out.append(_Op(type_, ch, lab))

    deleted: list[str] = []
    inserted: list[str] = []

    def flush() -> None:
        if not deleted and not inserted:
            return
        for type_, token in _myers(_tokens("".join(deleted)), _tokens("".join(inserted))):
            chars(type_, token)
        deleted.clear()
        inserted.clear()

    for type_, line in _myers(_lines(a), _lines(b)):
        if type_ == _KEEP:
            flush()
            chars(_KEEP, line)
        elif type_ == _DEL:
            deleted.append(line)
        else:
            inserted.append(line)
    flush()
    return out


def _lines(s: str) -> list[str]:
    """*s* split after each line break, the breaks kept."""
    out: list[str] = []
    i = 0
    while i < len(s):
        n = s.find("\n", i)
        e = len(s) if n < 0 else n + 1
        out.append(s[i:e])
        i = e
    return out


def _token_kind(c: int) -> int:
    if c in (0x20, 0x09, 0x0A, 0x0D):
        return 2
    if (
        0x30 <= c <= 0x39
        or 0x41 <= c <= 0x5A
        or 0x61 <= c <= 0x7A
        or c == 0x5F
        or c >= 0x80
    ):
        return 1
    return 0


def _tokens(s: str) -> list[str]:
    out: list[str] = []
    i = 0
    n = len(s)
    while i < n:
        k = _token_kind(ord(s[i]))
        j = i + 1
        if k != 0:
            while j < n and _token_kind(ord(s[j])) == k:
                j += 1
        out.append(s[i:j])
        i = j
    return out


def _myers(a: list[str], b: list[str]) -> list[tuple[int, str]]:
    """The shortest edit script from *a* to *b* (Myers), each step
    ``(type, item)``; past 2000 edits, everything deleted then inserted."""
    n = len(a)
    m = len(b)
    mx = n + m
    if mx == 0:
        return []
    cap = 2000
    off = mx + 1
    v = [0] * (2 * mx + 3)
    trace: list[list[int]] = []
    found = -1
    d = 0
    while d <= mx and d <= cap:
        if d > 0:
            trace.append(v[off - (d - 1) : off + d])
        k = -d
        while k <= d:
            if k == -d or (k != d and v[k - 1 + off] < v[k + 1 + off]):
                x = v[k + 1 + off]
            else:
                x = v[k - 1 + off] + 1
            y = x - k
            while x < n and y < m and a[x] == b[y]:
                x += 1
                y += 1
            v[k + off] = x
            if x >= n and y >= m:
                found = d
                break
            k += 2
        if found >= 0:
            break
        d += 1
    if found < 0:
        return [(_DEL, t) for t in a] + [(_INS, t) for t in b]
    rev: list[tuple[int, str]] = []
    x = n
    y = m
    for d in range(found, 0, -1):
        snap = trace[d - 1]

        def at(k: int, snap: list[int] = snap, d: int = d) -> int:
            return snap[k + d - 1]

        k = x - y
        prev_k = k + 1 if k == -d or (k != d and at(k - 1) < at(k + 1)) else k - 1
        prev_x = at(prev_k)
        prev_y = prev_x - prev_k
        while x > prev_x and y > prev_y:
            rev.append((_KEEP, a[x - 1]))
            x -= 1
            y -= 1
        if x == prev_x:
            rev.append((_INS, b[y - 1]))
        else:
            rev.append((_DEL, a[x - 1]))
        x = prev_x
        y = prev_y
    while x > 0 and y > 0:
        rev.append((_KEEP, a[x - 1]))
        x -= 1
        y -= 1
    rev.reverse()
    return rev


@dataclass
class _MarkAt:
    """An inline review mark in a value (UTF-16 offsets)."""

    start: int
    end: int
    body_start: int
    body_end: int
    sep: int


_MARK_CLOSE = {
    "{++": "++}",
    "{--": "--}",
    "{~~": "~~}",
    "{==": "==}",
    "{>>": "<<}",
}

_PARAGRAPH_END = re.compile(r"\n[ \t]*\n")


def _find_marks(t: str) -> list[_MarkAt]:
    """The inline review marks of *t* (a UTF-16 code-unit string) outside
    code: fenced blocks and backtick spans."""
    code = [False] * len(t)
    fence = MarkdownFenceTracker()
    s = 0
    for line in t.split("\n"):
        in_fence = fence.in_fence
        fence.feed(line)
        if in_fence or fence.in_fence:
            for i in range(s, s + len(line)):
                code[i] = True
        else:
            i = 0
            while i < len(line):
                if line[i] != "`":
                    i += 1
                    continue
                j = i
                while j < len(line) and line[j] == "`":
                    j += 1
                ticks = line[i:j]
                close = line.find(ticks, j)
                if close < 0:
                    i = j
                    continue
                for k in range(s + i, s + close + len(ticks)):
                    code[k] = True
                i = close + len(ticks)
        s += len(line) + 1
    out: list[_MarkAt] = []
    i = 0
    while i + 3 <= len(t):
        opener = t[i : i + 3]
        closer = _MARK_CLOSE.get(opener)
        if closer is None or code[i]:
            i += 1
            continue
        pe = _PARAGRAPH_END.search(t, i)
        limit = len(t) if pe is None else pe.start()
        close = t.find(closer, i + 3)
        if close < 0 or close + 3 > limit:
            i += 1
            continue
        sep = -1
        if opener == "{~~":
            sep = t.find("~>", i + 3)
            if sep < 0 or sep >= close:
                i += 1
                continue
        out.append(_MarkAt(i, close + 3, i + 3, close, sep))
        i = close + 3
    return out


__all__ = [
    "SpecAppendixEntry",
    "SpecStripOptions",
    "SpecStripPiece",
    "SpecStripTextResult",
    "SpecStripUsageError",
    "spec_strip_kind_names",
    "spec_strip_notation_kinds",
    "strip_notation_text",
]
