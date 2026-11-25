"""The merge back (SOM §11.10; the reading view's part *Stripped renditions
and the merge back*): an edited readable rendition merged onto the document of
record, every piece the strip removed put back.

The port of ``tom_som_typescript_runtime``'s ``spec_document_merge.ts``
(itself the port of ``spec_document_merge.dart``), following the Java port
``SpecStripMerge``; ``strip_merge_cases.json`` holds all ports to the same
results.

**Offsets are UTF-16 code units**, as in every other runtime. The merge works
on the values as strings of UTF-16 code units (one Python character per unit,
the form the strip's plan uses) and hands out ordinary strings again; a
placed piece's ``at`` counts UTF-16 units of the merged value.
"""

from __future__ import annotations

import copy as copy_module
import json
import os
import subprocess
from typing import Any, Callable, Optional

from .docspecs_validator import DocSpecsDocument
from .spec_document import SpecDocument
from .spec_document_markdown import SpecDocumentMarkdown
from .spec_document_strip import (
    SpecDocumentStrip,
    SpecReadableHeader,
    SpecReadableSource,
    SpecStripOptions,
    SpecStripPiece,
    SpecStripUsageError,
    SpecStripValueRef,
    _DEL,
    _INS,
    _KEEP,
    _Op,
    _blank,
    _diff,
    _find_marks,
    _from_utf16_string,
    _lines,
    _myers,
    _utf16_string,
)
from .spec_notation import NotationElement, NotationFindingCode, _js_trim, scan_notation
from .spec_review_annotations import annotation_issues_text

_ROLE_WHOLE = 0
_ROLE_OPENER = 1
_ROLE_CLOSER = 2
_ROLE_BOTH = 3


def spec_strip_merge_label(ref: SpecStripValueRef) -> str:
    """The name of a value in a merge report."""
    if ref.headline:
        return f"{ref.path} (headline)"
    if ref.field is not None:
        return f"{ref.path} / {ref.field}"
    return ref.path


def _visible(s: str) -> str:
    """*s* in guillemets, its line breaks shown."""
    return "«" + s.replace("\n", "⏎") + "»"


# ---------------------------------------------------------------------------
# The result types.


class SpecStripMergePlaced:
    """A piece put back after an edited run rather than between unchanged
    neighbours (SOM §11.10): an author confirms or moves it (``PLACED <value>
    — check``)."""

    def __init__(self, piece: SpecStripPiece, at: int) -> None:
        self.piece = piece
        #: The offset (UTF-16) in the merged value the piece's text starts at.
        self.at = at

    def to_json(self) -> dict[str, Any]:
        return {"at": self.at, "removed": self.piece.removed}

    def __repr__(self) -> str:
        return f"SpecStripMergePlaced({self.to_json()!r})"


class SpecStripMergeConflict:
    """Why a value, or the whole merge, cannot be merged (SOM §11.10). The
    codes are ``crossesBoundary``, ``sentenceRemoved``, ``stripTextEdited``,
    ``unplaceable``, ``notation``, ``annotations``, ``changedBothSides``,
    ``notStrippedBack`` and ``newFinding``."""

    def __init__(
        self,
        code: str,
        message: str,
        ref: Optional[SpecStripValueRef] = None,
        piece: Optional[SpecStripPiece] = None,
        excerpt_o: str = "",
        excerpt_b: str = "",
        excerpt_e: str = "",
    ) -> None:
        self.code = code
        self.message = message
        #: The value the conflict is about, or ``None``.
        self.ref = ref
        #: The piece that could not be put back, or ``None``.
        self.piece = piece
        #: The excerpts of the original, the stripped baseline and the edited
        #: text.
        self.excerpt_o = excerpt_o
        self.excerpt_b = excerpt_b
        self.excerpt_e = excerpt_e

    def about(self, value: SpecStripValueRef) -> "SpecStripMergeConflict":
        """The conflict about value *value*."""
        return SpecStripMergeConflict(
            self.code,
            self.message,
            value,
            self.piece,
            self.excerpt_o,
            self.excerpt_b,
            self.excerpt_e,
        )

    @property
    def report_lines(self) -> list[str]:
        """``CONFLICT <value> — <reason>``, then the three excerpts and the
        piece."""
        label = "(document)" if self.ref is None else spec_strip_merge_label(self.ref)
        out = [f"CONFLICT {label} — {self.message}"]
        if self.piece is not None or self.excerpt_b != "":
            out.append(f"  O: {self.excerpt_o}")
            out.append(f"  B: {self.excerpt_b}")
            out.append(f"  E: {self.excerpt_e}")
        if self.piece is not None:
            out.append(f"  piece: {_visible(self.piece.removed)}")
        return out

    def to_json(self) -> dict[str, Any]:
        out: dict[str, Any] = {"code": self.code}
        if self.ref is not None:
            out["value"] = self.ref.to_json()
        if self.piece is not None:
            out["removed"] = self.piece.removed
        return out

    def __repr__(self) -> str:
        return f"SpecStripMergeConflict({self.to_json()!r})"


class SpecStripValueMerge:
    """The result of :func:`merge_stripped_value` (SOM §11.10)."""

    def __init__(
        self,
        text: Optional[str],
        restored: int,
        placed: list[SpecStripMergePlaced],
        conflicts: list[SpecStripMergeConflict],
    ) -> None:
        #: The merged value; ``None`` when there are conflicts.
        self.text = text
        #: How many pieces were put back.
        self.restored = restored
        #: The pieces put back after an edited run, for an author to check.
        self.placed = placed
        self.conflicts = conflicts

    @property
    def ok(self) -> bool:
        """Whether the value merged."""
        return not self.conflicts

    def to_json(self) -> dict[str, Any]:
        return {
            "text": self.text,
            "restored": self.restored,
            "placed": [p.to_json() for p in self.placed],
            "conflicts": [c.to_json() for c in self.conflicts],
        }

    def __repr__(self) -> str:
        return f"SpecStripValueMerge({self.to_json()!r})"


class SpecStripMergedValue:
    """One value a document merge changed (SOM §11.10)."""

    def __init__(
        self,
        ref: SpecStripValueRef,
        text: str,
        restored: int,
        placed: list[SpecStripMergePlaced],
    ) -> None:
        self.ref = ref
        #: The merged value written into the document of record.
        self.text = text
        #: How many pieces were put back.
        self.restored = restored
        #: The pieces put back after an edited run, for an author to check.
        self.placed = placed

    def __repr__(self) -> str:
        return f"SpecStripMergedValue({self.ref.label!r}, {self.text!r})"


class SpecStripMergeRefusal:
    """An edit a merge refuses (SOM §11.10). The codes are ``sectionAdded``,
    ``sectionRemoved``, ``sectionMoved``, ``listItems``, ``codeSpec``,
    ``units``, ``rejected``, ``stale`` and ``strip``."""

    def __init__(self, code: str, path: str, message: str) -> None:
        self.code = code
        #: The path the refusal is about; empty for the whole document.
        self.path = path
        self.message = message

    @property
    def report_line(self) -> str:
        """``REFUSED <path> — <reason>``."""
        return f"REFUSED {self.path or '(document)'} — {self.message}"

    def to_json(self) -> dict[str, Any]:
        return {"code": self.code, "path": self.path}

    def __repr__(self) -> str:
        return f"SpecStripMergeRefusal({self.report_line!r})"


class SpecStripMergeResult:
    """The result of :meth:`SpecStripMerge.merge` (SOM §11.10)."""

    def __init__(
        self,
        document: Optional[SpecDocument],
        options: SpecStripOptions,
        stale: bool,
        merged: list[SpecStripMergedValue],
        conflicts: list[SpecStripMergeConflict],
        refusals: list[SpecStripMergeRefusal],
    ) -> None:
        #: The merged document; ``None`` when nothing may be written.
        self.document = document
        #: The switches the rendition was stripped with.
        self.options = options
        #: Whether the merge was three-way from the original at the export.
        self.stale = stale
        self.merged = merged
        self.conflicts = conflicts
        self.refusals = refusals

    @property
    def ok(self) -> bool:
        """Whether the merge has neither conflicts nor refusals."""
        return not self.conflicts and not self.refusals

    @property
    def exit_code(self) -> int:
        """``0`` merged or nothing to merge, ``1`` conflicts or refusals."""
        return 0 if self.ok else 1

    @property
    def report(self) -> list[str]:
        """The report: a line per merged value and placed piece, the
        conflicts, the refusals."""
        out: list[str] = []
        for m in self.merged:
            label = spec_strip_merge_label(m.ref)
            out.append(f"MERGED {label} — {m.restored} pieces put back")
            for _ in m.placed:
                out.append(f"PLACED {label} — check")
        for c in self.conflicts:
            out.extend(c.report_lines)
        for r in self.refusals:
            out.append(r.report_line)
        return out


# ---------------------------------------------------------------------------
# One value's merge.


class _Put:
    """Text to write into the edited value at ``at``."""

    __slots__ = ("at", "order", "text", "replace", "normalize", "before", "after")

    def __init__(
        self,
        at: int,
        order: int,
        text: str,
        replace: int = 0,
        normalize: bool = False,
        before: int = 2,
        after: int = 2,
    ) -> None:
        self.at = at
        self.order = order
        self.text = text
        self.replace = replace
        self.normalize = normalize
        self.before = before
        self.after = after


def _excerpt(s: str, at: int) -> str:
    """Thirty UTF-16 units of *s* (a UTF-16 code-unit string) either side of
    *at*, made visible."""
    a = max(0, min(at, len(s)) - 30)
    z = max(a, min(len(s), at + 30))
    return _visible(_from_utf16_string(s[a:z]))


def _conflict(
    code: str, message: str, p: SpecStripPiece, o: str, b: str, e: str, e_at: int
) -> SpecStripMergeConflict:
    return SpecStripMergeConflict(
        code, message, None, p, _excerpt(o, p.origin), _excerpt(b, p.anchor), _excerpt(e, e_at)
    )


def _distance(breaks: int, edge: bool) -> int:
    return 2 if edge else min(2, max(1, breaks))


def _notation_errors(s: str) -> int:
    return sum(
        1
        for f in scan_notation(s, tom_specs=True).findings
        if f.severity == "error" and f.code != NotationFindingCode.REJECTED_BLOCK
    )


def _is_blank(s: str) -> bool:
    return _js_trim(s) == ""


def merge_stripped_value(
    original: str, stripped: str, edited: str, pieces: list[SpecStripPiece]
) -> SpecStripValueMerge:
    """Merges the edited text *edited* of one value back onto its *original*
    (SOM §11.10): *stripped* is the original stripped and *pieces* what the
    strip removed, anchored in it. A piece goes back between its unchanged
    neighbours; next to an edit it is placed after the edited run (reported
    as placed) or, where that would be a guess — an edit across the boundary
    of an unmarked element (``crossesBoundary``), the whole sentence holding
    the piece removed (``sentenceRemoved``), the text the strip wrote edited
    (``stripTextEdited``), a block without a line to go back to
    (``unplaceable``) — it is a conflict, and so is a merged value with a
    notation error or a malformed annotation neither side had."""
    if edited == stripped:
        return SpecStripValueMerge(original, len(pieces), [], [])
    o = _utf16_string(original)
    b = _utf16_string(stripped)
    e = _utf16_string(edited)
    removed16 = [_utf16_string(p.removed) for p in pieces]
    inserted16 = [_utf16_string(p.inserted) for p in pieces]
    roles = _piece_roles(original, o, pieces, removed16)
    ops = _diff(b, e, "edit")
    emap = _EditMap(ops, len(b))
    # An opening marker is judged on the script whose whitespace edits trail
    # their run, a closing one on the script whose whitespace edits lead it.
    trailing = _EditMap(_slide(ops, False), len(b))
    leading = _EditMap(_slide(ops, True), len(b))
    lines: Optional[_LineEditMap] = None
    puts: list[_Put] = []
    placed_at: set[int] = set()
    conflicts: list[SpecStripMergeConflict] = []
    restored = 0
    for i, p in enumerate(pieces):
        inserted = inserted16[i]
        if inserted:
            at = emap.kept_range(p.anchor, p.anchor + len(inserted))
            if at < 0:
                conflicts.append(
                    _conflict(
                        "stripTextEdited",
                        "the text the strip wrote in place of a piece was edited",
                        p, o, b, e, emap.gap(p.anchor).start,
                    )
                )
                continue
            puts.append(_Put(at, i, removed16[i], len(inserted), False, 2, 2))
            restored += 1
            continue

        role = roles[i]
        g = p.anchor
        text = removed16[i]
        if role == _ROLE_WHOLE and "\n" in text:
            while g > 0 and b[g - 1] != "\n" and g < len(b) and text[0] == b[g]:
                text = text[1:] + text[0]
                g += 1
            if g == 0 or b[g - 1] == "\n" or g == len(b):
                if lines is None:
                    lines = _LineEditMap(b, e)
                k = _line_index(b, g)
                gap = lines.gap(k)
                if gap.unchanged:
                    puts.append(_Put(gap.start, i, text))
                    restored += 1
                    continue
                if not gap.left_edited:
                    at = gap.start
                elif not gap.right_edited:
                    at = gap.end
                else:
                    at = lines.paragraph_place(gap, k)
                if 0 < at < len(e) and e[at - 1] != "\n":
                    conflicts.append(
                        _conflict(
                            "unplaceable",
                            "the block has no line boundary to go back to",
                            p, o, b, e, at,
                        )
                    )
                    continue
                # The block keeps the distance it had from the text around it
                # in the original: a blank line, or none when it stood right
                # against a line.
                rem = removed16[i]
                core = p.origin + _leading_breaks(rem)
                core_end = p.origin + len(rem) - _trailing_breaks(rem)
                puts.append(
                    _Put(
                        at,
                        i,
                        text,
                        0,
                        True,
                        _distance(_trailing_breaks(o[:core]), core == 0),
                        _distance(_leading_breaks(o[core_end:]), core_end >= len(o)),
                    )
                )
                restored += 1
                continue
            g = p.anchor
            text = removed16[i]

        m = trailing if role == _ROLE_OPENER else leading if role == _ROLE_CLOSER else emap
        gap = m.gap(g)
        if gap.unchanged:
            puts.append(_Put(gap.start, i, text))
            restored += 1
            continue
        if _is_blank(text):
            continue  # normalised whitespace at an edit
        if role in (_ROLE_OPENER, _ROLE_CLOSER):
            if gap.left_edited and gap.right_edited:
                conflicts.append(
                    _conflict(
                        "crossesBoundary",
                        "an edit crosses the boundary of an unmarked element",
                        p, o, b, e, gap.start,
                    )
                )
                continue
            # The edit on the inner side of the marker goes inside the element.
            if role == _ROLE_OPENER:
                at = gap.start if not gap.left_edited else gap.end
            else:
                at = gap.end if not gap.right_edited else gap.start
            puts.append(_Put(at, i, text))
            restored += 1
        elif role == _ROLE_BOTH:
            conflicts.append(
                _conflict(
                    "crossesBoundary",
                    "an edit touches the boundary between two unmarked elements",
                    p, o, b, e, gap.start,
                )
            )
        else:
            if _sentence_removed(b, g, emap):
                conflicts.append(
                    _conflict(
                        "sentenceRemoved",
                        "the edit removed the whole sentence holding the piece",
                        p, o, b, e, gap.start,
                    )
                )
                continue
            puts.append(_Put(gap.end, i, text))
            placed_at.add(i)
            restored += 1
    if conflicts:
        return SpecStripValueMerge(None, 0, [], conflicts)

    puts.sort(key=lambda x: (x.at, x.order))
    out = ""
    placed: list[SpecStripMergePlaced] = []
    pos = 0
    for put in puts:
        if put.at < pos:
            conflicts.append(
                SpecStripMergeConflict(
                    "stripTextEdited",
                    "two pieces claim the same text",
                    None,
                    pieces[put.order],
                    "",
                    "",
                    "",
                )
            )
            continue
        out += e[pos : put.at]
        pos = put.at
        if put.normalize:
            s = _leading_breaks(put.text)
            z = len(put.text) - _trailing_breaks(put.text)
            core_text = put.text[s:z] if z > s else ""
            if out:
                out += "\n" * max(0, put.before - _trailing_breaks(out))
            if put.order in placed_at:
                placed.append(SpecStripMergePlaced(pieces[put.order], len(out)))
            out += core_text
            right = e[pos:]
            if right:
                out += "\n" * max(0, put.after - _leading_breaks(right))
        else:
            if put.order in placed_at:
                placed.append(SpecStripMergePlaced(pieces[put.order], len(out)))
            out += put.text
        pos += put.replace
    out += e[pos:]
    merged = _from_utf16_string(out)

    if _notation_errors(merged) > _notation_errors(edited) + _notation_errors(original):
        conflicts.append(
            SpecStripMergeConflict(
                "notation",
                "the merged value has a notation error neither the original nor the "
                "edited text has",
            )
        )
    if len(annotation_issues_text(merged)) > len(annotation_issues_text(edited)) + len(
        annotation_issues_text(original)
    ):
        conflicts.append(
            SpecStripMergeConflict(
                "annotations",
                "the merged value has a malformed review annotation neither the "
                "original nor the edited text has",
            )
        )
    if conflicts:
        return SpecStripValueMerge(None, 0, [], conflicts)
    return SpecStripValueMerge(merged, restored, placed, [])


# ---------------------------------------------------------------------------
# A whole document's merge.


def _refused(
    opts: SpecStripOptions, r: list[SpecStripMergeRefusal], stale: bool
) -> SpecStripMergeResult:
    return SpecStripMergeResult(None, opts, stale, [], [], r)


def _refused_at(refusals: list[SpecStripMergeRefusal], path: str) -> bool:
    return any(r.path == path for r in refusals)


class SpecStripMerge:
    """Merging an edited stripped rendition back (SOM §11.10)."""

    @staticmethod
    def merge(
        original: SpecDocument,
        edited: str,
        *,
        model: Any,
        schema: Any = None,
        root_type: Optional[str] = None,
        options: Optional[SpecStripOptions] = None,
        current_revision: Optional[str] = None,
        base: Optional[SpecDocument] = None,
        load_base: Optional[Callable[[SpecReadableSource], Optional[SpecDocument]]] = None,
        file_stem: Optional[str] = None,
        document_files: Optional[dict[str, str]] = None,
    ) -> SpecStripMergeResult:
        """Merges *edited*, a ``.readable.md`` made from *original* and
        changed by a reader, back onto *original* (SOM §11.10).

        The switches come from the rendition's readable header, or from
        *options* (which must agree with a header); with neither, a
        :class:`SpecStripUsageError` is raised. The original is stale when a
        *base* is given or the header's revision differs from
        *current_revision*: the merge is then three-way, from the base given
        or from the header's commit through *load_base*, and refused
        (``stale``) without one. Structural edits — sections or list items
        added, removed or moved, a changed codeSpec or units — and a
        rendition with rejected blocks are refused; every other changed value
        is merged with :func:`merge_stripped_value`. The merged document is
        checked to change only the merged values, to strip back to the edited
        text and to add no finding; :attr:`SpecStripMergeResult.document` is
        ``None`` unless all of that holds. *original* is never changed."""
        codec_args = {"file_stem": file_stem, "document_files": document_files}
        parsed = SpecDocumentMarkdown(model, SpecDocument(), **codec_args).parse(edited)
        header_line = parsed.readable_header
        header = None if header_line is None else SpecReadableHeader.parse(header_line)
        if header_line is not None and header is None:
            raise SpecStripUsageError(f"the readable header cannot be read: {header_line}")
        if options is not None:
            if header is not None and _options_text(header.options) != _options_text(options):
                raise SpecStripUsageError(
                    f"the switches given ({_options_text(options)}) disagree with the "
                    f"readable header ({_options_text(header.options)})"
                )
            opts = options
        elif header is not None:
            opts = header.options
        else:
            raise SpecStripUsageError(
                "the rendition has no readable header: name the switches it was "
                "stripped with"
            )

        if parsed.rejections:
            return _refused(
                opts,
                [
                    SpecStripMergeRefusal("rejected", "", f"line {x.line}: {x.message}")
                    for x in parsed.rejections
                ],
                False,
            )

        source = None if header is None else header.source
        stale = base is not None or (
            source is not None
            and source.revision is not None
            and current_revision is not None
            and source.revision != current_revision
        )
        origin = original
        if stale:
            loaded = base
            if (
                loaded is None
                and source is not None
                and source.commit is not None
                and not source.dirty
                and load_base is not None
            ):
                loaded = load_base(source)
            if loaded is None:
                if source is None or source.commit is None:
                    why = "names no commit"
                elif source.dirty:
                    why = "names a dirty commit"
                else:
                    why = "names a commit that could not be read"
                then = "null" if source is None or source.revision is None else source.revision
                now = "null" if current_revision is None else current_revision
                return _refused(
                    opts,
                    [
                        SpecStripMergeRefusal(
                            "stale",
                            "",
                            f"the original moved since the export (revision {then} "
                            f"then, {now} now) and there is no base: the header {why}; "
                            "give the original as it was at the export",
                        )
                    ],
                    True,
                )
            origin = loaded

        strip = SpecDocumentStrip.strip(
            origin,
            opts,
            model=model,
            schema=schema,
            root_type=root_type,
            file_stem=file_stem,
            document_files=document_files,
        )
        if not strip.ok or strip.readable is None:
            r = [
                SpecStripMergeRefusal("strip", "" if f.ref is None else f.ref.label, str(f))
                for f in strip.findings
            ]
            if not r:
                r.append(SpecStripMergeRefusal("strip", "", "the base renders no rendition"))
            return _refused(opts, r, stale)
        b_doc = strip.document
        e_doc = SpecDocument()
        e_doc.apply_markdown_result(parsed)
        roots = list(parsed.root_prefixes)

        def in_root(p: str) -> bool:
            return any(p == r or p.startswith(f"{r}/") or p.startswith(f"{r}-") for r in roots)

        # Structural edits.
        refusals: list[SpecStripMergeRefusal] = []
        b_headings = _heading_paths(strip.readable)
        e_headings = _heading_paths(edited)
        if b_headings != e_headings:
            b_set = set(b_headings)
            e_set = set(e_headings)
            for p in e_headings:
                if p not in b_set:
                    refusals.append(SpecStripMergeRefusal("sectionAdded", p, "a section added"))
            for p in b_headings:
                if p not in e_set:
                    refusals.append(
                        SpecStripMergeRefusal("sectionRemoved", p, "a section removed")
                    )
            if not refusals:
                common = [p for p in e_headings if p in b_set]
                want = [p for p in b_headings if p in e_set]
                for i, p in enumerate(common):
                    if i >= len(want) or p != want[i]:
                        refusals.append(SpecStripMergeRefusal("sectionMoved", p, "a section moved"))
                        break
        b_lists = _lists_under(b_doc, in_root)
        e_lists = _lists_under(e_doc, in_root)
        for lst in sorted(set(b_lists) | set(e_lists)):
            if b_lists.get(lst) != e_lists.get(lst):
                refusals.append(
                    SpecStripMergeRefusal(
                        "listItems", lst, "list items added, removed, moved or renamed"
                    )
                )
        for code in ("codeSpec", "units"):
            is_code_spec = code == "codeSpec"
            if is_code_spec:
                every = set(b_doc.code_spec_paths) | set(e_doc.code_spec_paths)
            else:
                every = set(b_doc.units_paths) | set(e_doc.units_paths)
            for p in sorted(every):
                if not in_root(p):
                    continue
                was = b_doc.code_spec(p) if is_code_spec else b_doc.units(p)
                now_value = e_doc.code_spec(p) if is_code_spec else e_doc.units(p)
                if was != now_value:
                    refusals.append(SpecStripMergeRefusal(code, p, f"a changed {code}"))
        by_key: dict[str, SpecStripValueRef] = {}
        for d in (b_doc, e_doc):
            for r in SpecDocumentStrip._value_refs(d):
                if in_root(r.path):
                    by_key[_ref_key(r)] = r
        refs = sorted(
            by_key.values(),
            key=lambda x: (x.path, 0 if x.headline else 1, x.field or ""),
        )
        for ref in refs:
            if (
                ref.read(b_doc) == ""
                and ref.read(e_doc) != ""
                and not b_doc.has_values_under(ref.path)
                and not _refused_at(refusals, ref.path)
            ):
                refusals.append(
                    SpecStripMergeRefusal(
                        "sectionAdded",
                        ref.path,
                        "a value in a section the rendition does not show",
                    )
                )

        # The values.
        pieces = {_ref_key(v.ref): v.pieces for v in strip.values}
        merged: list[SpecStripMergedValue] = []
        conflicts: list[SpecStripMergeConflict] = []
        for ref in refs:
            b_text = ref.read(b_doc)
            e_text = ref.read(e_doc)
            # A wrapped paragraph written in a table cell reads back on one
            # line (SOM §11.4 rule 13): that alone is no edit.
            if b_text == e_text or e_text == SpecDocumentMarkdown.wrapped_paragraph_joined(
                b_text
            ):
                continue
            if _refused_at(refusals, ref.path):
                continue
            # A value whose section came or went with a refused edit is that
            # edit.
            if refusals and (
                not b_doc.has_values_under(ref.path) or not e_doc.has_values_under(ref.path)
            ):
                continue
            o = ref.read(origin)
            r = merge_stripped_value(o, b_text, e_text, pieces.get(_ref_key(ref), []))
            now = ref.read(original)
            if stale and now != o:
                # The edit is already in the moved original (the same
                # rendition merged before): nothing to do for this value.
                if r.ok and now == r.text:
                    continue
                b16 = _utf16_string(b_text)
                e16 = _utf16_string(e_text)
                o16 = _utf16_string(o)
                now16 = _utf16_string(now)
                at = _first_difference(b16, e16)
                conflicts.append(
                    SpecStripMergeConflict(
                        "changedBothSides",
                        "the value changed in the original since the export, and in "
                        "the rendition",
                        ref,
                        None,
                        _excerpt(now16, _first_difference(o16, now16)),
                        _excerpt(b16, at),
                        _excerpt(e16, at),
                    )
                )
                continue
            if not r.ok:
                for c in r.conflicts:
                    conflicts.append(c.about(ref))
                continue
            merged.append(SpecStripMergedValue(ref, r.text or "", r.restored, r.placed))
        if conflicts or refusals:
            return SpecStripMergeResult(None, opts, stale, merged, conflicts, refusals)

        # Write and verify.
        out = SpecDocument()
        out.load_json(copy_module.deepcopy(original.to_json()))
        expected: set[str] = set()
        for m in merged:
            if m.text != m.ref.read(original):
                expected.add(_ref_key(m.ref))
            m.ref.write(out, m.text)
        changed: set[str] = set()
        for d in (original, out):
            for r in SpecDocumentStrip._value_refs(d):
                if r.read(original) != r.read(out):
                    changed.add(_ref_key(r))
        if changed != expected:
            conflicts.append(
                SpecStripMergeConflict(
                    "newFinding", "the merged document changes other values than the merged ones"
                )
            )
        again = SpecDocumentStrip.strip(
            out,
            opts,
            model=model,
            schema=schema,
            root_type=root_type,
            file_stem=file_stem,
            document_files=document_files,
        )
        for m in merged:
            back = m.ref.read(again.document)
            want_text = m.ref.read(e_doc)
            if back != want_text:
                conflicts.append(
                    SpecStripMergeConflict(
                        "notStrippedBack",
                        "the merged value does not strip back to the edited text",
                        m.ref,
                        None,
                        _excerpt(_utf16_string(m.text), 0),
                        _excerpt(_utf16_string(back), 0),
                        _excerpt(_utf16_string(want_text), 0),
                    )
                )
        before = SpecDocumentStrip._tier_findings(model, schema, root_type, original)
        for k in SpecDocumentStrip._tier_findings(model, schema, root_type, out):
            if k not in before:
                conflicts.append(
                    SpecStripMergeConflict("newFinding", f"the merged document has a new finding: {k}")
                )
        return SpecStripMergeResult(
            out if not conflicts else None, opts, stale, merged, conflicts, []
        )

    @staticmethod
    def git_show_file(commit: Optional[str], file_path: str) -> Optional[str]:
        """The file at *file_path* as it was at *commit* (``git show
        <commit>:./<name>``, run in the file's folder), or ``None`` when git
        cannot give it. What a *load_base* reads the base of a stale original
        with. A commit starting with ``-`` is refused: it is never an option
        to git."""
        if not commit or commit.startswith("-"):
            return None
        path = os.path.abspath(file_path)
        folder = os.path.dirname(path)
        if not folder or not os.path.isdir(folder):
            return None
        try:
            done = subprocess.run(
                ["git", "show", f"{commit}:./{os.path.basename(path)}"],
                cwd=folder,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                check=False,
            )
        except (OSError, ValueError, subprocess.SubprocessError):
            return None
        if done.returncode != 0:
            return None
        return done.stdout.decode("utf-8", errors="replace")


def _options_text(o: SpecStripOptions) -> str:
    s = SpecReadableHeader(o).format()
    return _js_trim(s[len("<!-- readable:") : len(s) - 3])


def _ref_key(r: SpecStripValueRef) -> str:
    kind = "h" if r.headline else "f" if r.field is not None else "c"
    return f"{kind}\u0000{r.path}\u0000{r.field or ''}"


def _heading_paths(markdown: str) -> list[str]:
    """The section-id paths of *markdown*'s headings, in order."""
    out: list[str] = []

    def walk(sections: list[Any], prefix: str) -> None:
        for s in sections:
            sid = "?" if s.id is None else s.id
            p = sid if prefix == "" else f"{prefix}/{sid}"
            out.append(p)
            walk(s.children, p)

    walk(DocSpecsDocument.parse(markdown).sections, "")
    return out


def _lists_under(doc: SpecDocument, in_root: Callable[[str], bool]) -> dict[str, str]:
    """The lists of *doc* under the roots, each as its items and their ids."""
    out: dict[str, str] = {}
    lists = doc.to_json().get("lists")
    if isinstance(lists, dict):
        for k, v in lists.items():
            if in_root(str(k)) and isinstance(v, dict):
                out[str(k)] = (
                    json.dumps(v.get("items"), ensure_ascii=False)
                    + " "
                    + json.dumps(v.get("ids"), ensure_ascii=False)
                )
    return out


# ---------------------------------------------------------------------------
# The roles of the pieces.


def _piece_roles(
    original: str, o: str, pieces: list[SpecStripPiece], removed16: list[str]
) -> list[int]:
    """What each piece is, read from the original *o* (a UTF-16 code-unit
    string; *original* the same as an ordinary string): the opening marker of
    an unmarked element, its closing marker, both (the closer of one and the
    opener of the next), or a whole removed run."""
    at = [-1] * len(o)
    for i, p in enumerate(pieces):
        k = p.origin
        end = min(p.origin + len(removed16[i]), len(o))
        while k < end:
            at[k] = i
            k += 1
    opener = [False] * len(pieces)
    closer = [False] * len(pieces)
    _walk_roles(scan_notation(original, tom_specs=True).elements, o, at, opener, closer)
    for m in _find_marks(o):
        _pair(
            o, at, opener, closer, m.start,
            m.sep + 2 if m.sep >= 0 else m.body_start, m.body_end, m.end,
        )
    roles: list[int] = []
    for i in range(len(pieces)):
        if opener[i] and closer[i]:
            roles.append(_ROLE_BOTH)
        elif opener[i]:
            roles.append(_ROLE_OPENER)
        elif closer[i]:
            roles.append(_ROLE_CLOSER)
        else:
            roles.append(_ROLE_WHOLE)
    return roles


def _first_piece(o: str, at: list[int], s: int, e: int) -> int:
    """The piece holding the first solid character of ``o[s:e]``, or -1."""
    k = max(0, s)
    while k < e and k < len(o):
        if not _blank(o[k]):
            return at[k]
        k += 1
    return -1


def _whole_piece(at: list[int], start: int, end: int) -> bool:
    """Whether ``[start, end)`` lies in one piece."""
    if not (start < end and 0 <= start < len(at) and at[start] >= 0):
        return False
    for k in range(start, end):
        if k >= len(at) or at[k] != at[start]:
            return False
    return True


def _pair(
    o: str,
    at: list[int],
    opener: list[bool],
    closer: list[bool],
    start: int,
    open_end: int,
    close_start: int,
    end: int,
) -> None:
    if _whole_piece(at, start, end):
        return
    po = _first_piece(o, at, start, open_end)
    pc = _first_piece(o, at, close_start, end)
    if po >= 0 and po != pc:
        opener[po] = True
    if pc >= 0 and pc != po:
        closer[pc] = True


def _walk_roles(
    elements: list[NotationElement],
    o: str,
    at: list[int],
    opener: list[bool],
    closer: list[bool],
) -> None:
    for e in elements:
        if e.type == "citation":
            if not _whole_piece(at, e.start, e.end):
                po = _first_piece(o, at, e.start + 1, e.content_start)
                if po >= 0:
                    opener[po] = True
        else:
            _pair(o, at, opener, closer, e.start, e.content_start, e.content_end, e.end)
        _walk_roles(e.children, o, at, opener, closer)


# ---------------------------------------------------------------------------
# Edit scripts indexed by baseline offset.


class _Gap:
    """Where a gap of the baseline lies in the edited text."""

    __slots__ = ("left_edited", "right_edited", "start", "end")

    def __init__(self, left_edited: bool, right_edited: bool, start: int, end: int) -> None:
        self.left_edited = left_edited
        self.right_edited = right_edited
        self.start = start
        self.end = end

    @property
    def unchanged(self) -> bool:
        return not self.left_edited and not self.right_edited and self.start == self.end


def _gap_at(p: int, first: bool, types: list[int], e_before: list[int]) -> _Gap:
    """The gap after *p* operations of a script whose types *types* gives."""
    n = len(types)
    left_edited = not first and types[p - 1] == _DEL
    r = p
    while r < n and types[r] == _INS:
        r += 1
    right_edited = r < n and types[r] == _DEL
    if not left_edited and r == p and not right_edited:
        return _Gap(False, False, e_before[p], e_before[p])
    s = p
    while s > 0 and types[s - 1] != _KEEP:
        s -= 1
    t = p
    while t < n and types[t] != _KEEP:
        t += 1
    return _Gap(left_edited, right_edited, e_before[s], e_before[t])


class _EditMap:
    """An edit script from a baseline to an edited text, indexed by baseline
    offset."""

    def __init__(self, ops: list[_Op], b_length: int) -> None:
        self.types = [op.type for op in ops]
        self.after = [0] * (b_length + 1)
        self.e_before = [0] * (len(ops) + 1)
        self.deleted = [False] * b_length
        g = 0
        for i, t in enumerate(self.types):
            self.e_before[i + 1] = self.e_before[i] + (0 if t == _DEL else 1)
            if t != _INS:
                if t == _DEL:
                    self.deleted[g] = True
                g += 1
                self.after[g] = i + 1

    def gap(self, g: int) -> _Gap:
        return _gap_at(self.after[g], g == 0, self.types, self.e_before)

    def kept_range(self, a: int, z: int) -> int:
        """The edited-text offset of baseline range ``[a, z)`` kept whole,
        else -1."""
        first = self.after[a + 1] - 1
        for k in range(a, z):
            i = self.after[k + 1] - 1
            if self.types[i] != _KEEP or i != first + (k - a):
                return -1
        return self.e_before[first]


class _LineEditMap:
    """A line edit script from a baseline to an edited text."""

    def __init__(self, b: str, e: str) -> None:
        bl = _lines(b)
        self.ops = _myers(bl, _lines(e))
        self.types = [t for t, _ in self.ops]
        self.after = [0] * (len(bl) + 1)
        self.e_before = [0] * (len(self.ops) + 1)
        k = 0
        for i, (t, text) in enumerate(self.ops):
            self.e_before[i + 1] = self.e_before[i] + (0 if t == _DEL else len(text))
            if t != _INS:
                k += 1
                self.after[k] = i + 1

    def gap(self, k: int) -> _Gap:
        return _gap_at(self.after[k], k == 0, self.types, self.e_before)

    def paragraph_place(self, gap: _Gap, k: int) -> int:
        """Where a block between two edited runs goes: before the inserted
        paragraph that stands where the block's following paragraph stood,
        counted in paragraphs of the run."""
        types = self.types
        p = self.after[k]
        s = p
        while s > 0 and types[s - 1] != _KEEP:
            s -= 1
        before = 0
        blank = True
        for i in range(s, p):
            if types[i] != _DEL:
                continue
            is_blank = _is_blank(self.ops[i][1])
            if not is_blank and blank:
                before += 1
            blank = is_blank
        if before == 0:
            return gap.start
        count = 0
        blank = True
        i = s
        while i < len(types) and types[i] != _KEEP:
            if types[i] == _INS:
                is_blank = _is_blank(self.ops[i][1])
                if not is_blank and blank:
                    if count == before:
                        return self.e_before[i]
                    count += 1
                blank = is_blank
            i += 1
        return gap.end


def _slide(ops: list[_Op], leading: bool) -> list[_Op]:
    """*ops* with every lone run of deletions or insertions slid over equal
    whitespace: to the front of it (*leading*) or to its end."""
    out = list(ops)
    n = len(out)
    s = 0
    while s < n:
        if out[s].type == _KEEP:
            s += 1
            continue
        t = s
        while t < n and out[t].type == out[s].type:
            t += 1
        if t < n and out[t].type != _KEEP:
            while t < n and out[t].type != _KEEP:
                t += 1
            s = t
            continue
        type_ = out[s].type
        if leading:
            while (
                s > 0
                and out[s - 1].type == _KEEP
                and _blank(out[t - 1].char)
                and out[s - 1].char == out[t - 1].char
            ):
                out[t - 1] = _Op(_KEEP, out[t - 1].char, None)
                out[s - 1] = _Op(type_, out[s - 1].char, "edit")
                s -= 1
                t -= 1
        else:
            while (
                t < n
                and out[t].type == _KEEP
                and _blank(out[s].char)
                and out[s].char == out[t].char
            ):
                out[s] = _Op(_KEEP, out[s].char, None)
                out[t] = _Op(type_, out[t].char, "edit")
                s += 1
                t += 1
        s = t
    return out


def _line_index(b: str, g: int) -> int:
    k = b.count("\n", 0, g)
    if g == len(b) and b and not b.endswith("\n"):
        k += 1
    return k


def _sentence_ends(b: str, i: int) -> bool:
    return b[i] in ".!?" and (i + 1 >= len(b) or _blank(b[i + 1]))


def _sentence_removed(b: str, g: int, emap: _EditMap) -> bool:
    """Whether the edit deleted every solid character of the sentence around
    gap *g*."""
    s = g
    while s > 0 and b[s - 1] != "\n" and not (s - 1 < g - 1 and _sentence_ends(b, s - 1)):
        s -= 1
    e = g
    while e < len(b) and b[e] != "\n":
        if _sentence_ends(b, e):
            e += 1
            break
        e += 1
    found = False
    for i in range(s, e):
        if _blank(b[i]):
            continue
        found = True
        if not emap.deleted[i]:
            return False
    return found


def _trailing_breaks(s: str) -> int:
    return len(s) - len(s.rstrip("\n"))


def _leading_breaks(s: str) -> int:
    return len(s) - len(s.lstrip("\n"))


def _first_difference(a: str, b: str) -> int:
    """The first offset at which *a* and *b* differ (the shorter length when
    one is a prefix of the other)."""
    n = min(len(a), len(b))
    for i in range(n):
        if a[i] != b[i]:
            return i
    return n


__all__ = [
    "SpecStripMerge",
    "SpecStripMergeConflict",
    "SpecStripMergePlaced",
    "SpecStripMergeRefusal",
    "SpecStripMergeResult",
    "SpecStripMergedValue",
    "SpecStripValueMerge",
    "merge_stripped_value",
    "spec_strip_merge_label",
]
