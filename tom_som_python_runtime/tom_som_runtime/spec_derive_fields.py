"""``derive_fields``: the derived places of one document, written
(`tom_specs_model_rules.md` §9.7). A port of
`tom_som_dart_runtime/lib/src/spec_derive_fields.dart`.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional

from .spec_document import SpecDocument
from .spec_links_validator import SpecLinkFix, SpecLinkValidator
from .spec_model import SpecModel
from .spec_review_annotations import (
    K_SPEC_HEADLINE_FIELD,
    SpecReviewAnnotations,
    apply_inline_marks_text,
    mark_change_text,
)
from .spec_validator import (
    SpecValidationCode,
    SpecValidationError,
    spec_derived_numbers,
)


@dataclass(frozen=True)
class SpecDeriveChange:
    """One place :func:`derive_fields` wrote."""

    #: The step that wrote it: 1 (link ends and rows), 2 (derived values,
    #: repeats, ``@SameAs`` copies), 3 (counts, products, ranks).
    step: int
    #: ``value`` (a value written), ``rowAdded``, ``rowRemoved``.
    kind: str
    #: The value's path, or the row's.
    path: str
    #: The form field (:data:`K_SPEC_HEADLINE_FIELD` for a headline), or
    #: ``None``.
    field: Optional[str] = None
    #: The value before (for a row, empty).
    old_value: str = ""
    #: The value after (for a row, empty).
    new_value: str = ""

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        out: dict[str, Any] = {"step": self.step, "kind": self.kind, "path": self.path}
        if self.field is not None:
            out["field"] = self.field
        out["old"] = self.old_value
        out["new"] = self.new_value
        return out


@dataclass(frozen=True)
class SpecDeriveResult:
    """What :func:`derive_fields` did."""

    #: The document written: the one given, or its copy on a dry run.
    document: SpecDocument
    #: Every place written, in the order written.
    changes: list[SpecDeriveChange]
    #: What it could not write, with the code: ``unmarkable`` (a change it
    #: cannot mark exactly in a document under review, left as it was),
    #: ``derivedLookupMiss`` (a lookup without exactly one row).
    unresolved: list[SpecValidationError]

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form (the document as its stores)."""
        return {
            "changes": [c.to_json() for c in self.changes],
            "unresolved": [
                {"path": e.path, "code": e.code.value, "message": e.message}
                for e in self.unresolved
            ],
            "document": self.document.to_json(),
        }


def derive_fields(
    model: SpecModel,
    doc: SpecDocument,
    marked: bool = True,
    author: Optional[str] = None,
    at: Optional[str] = None,
    dry_run: bool = False,
) -> SpecDeriveResult:
    """Recomputes the derived places of *doc* (`tom_specs_model_rules.md`
    §9.7) in three steps, each reading the result of the one before:

    1. the missing ``inverseOf`` ends inside the document, the missing
       ``@ExtractsLinks`` rows in ``generate`` mode, and the stale generated
       rows removed (a link row left with no value at all goes too);
    2. ``@DerivedFrom`` values and lists, ``@SummaryOf`` ``repeats``, and every
       ``@SameAs`` copy from its holder;
    3. ``countOf``, ``productOf`` and ``rankOf``.

    *marked* (default true; a document under review) writes every change as
    inline marks (SOM §11.9.3) attributed to *author* at *at*, and reads
    values as proposed (pending marks accepted). Without it values are written
    plain. A change it cannot mark exactly is left as it was and listed as
    ``unmarkable``. It never writes another document. A second run right
    after the first writes nothing. *dry_run* works on a copy."""
    target = doc
    if dry_run:
        target = SpecDocument()
        target.load_json(doc.to_json())
    d = _Deriver(model, target, marked, author, at)
    d.run()
    return SpecDeriveResult(document=target, changes=d.changes, unresolved=d.unresolved)


class _Deriver:
    def __init__(
        self,
        model: SpecModel,
        doc: SpecDocument,
        marked: bool,
        author: Optional[str],
        at: Optional[str],
    ) -> None:
        self.model = model
        self.doc = doc
        self.marked = marked
        self.author = author
        self.at = at
        self.changes: list[SpecDeriveChange] = []
        self.unresolved: list[SpecValidationError] = []
        self._unresolved_keys: set[str] = set()
        fixed = at
        self.api = SpecReviewAnnotations(
            doc, clock=None if fixed is None else (lambda: fixed)
        )

    def _check(self) -> SpecLinkValidator:
        return SpecLinkValidator(self.model, self.doc, read_proposed=self.marked).run()

    def run(self) -> None:
        # Step 1: link ends and rows. Removals first, so a row removed and a
        # row added for the same id do not cancel out.
        v = self._check()
        step1 = [f for f in v.fixes if f.step == 1]
        for f in step1:
            if f.kind == "removeRow":
                self._remove_row(1, f.path, f.empty)
        for f in step1:
            if f.kind != "removeRow":
                self._apply(f, v)

        # Step 2: derived values and lists, then (reading them) the repeats
        # and the copies; again until nothing moves, which DERIVE-ACYCLIC
        # bounds.
        for _ in range(4):
            v = self._check()
            before = len(self.changes)
            for f in [f for f in v.fixes if f.step == 2 and f.kind != "copy"]:
                self._apply(f, v)
            v = self._check()
            for f in [f for f in v.fixes if f.kind == "copy"]:
                self._apply(f, v)
            if len(self.changes) == before:
                break
        for e in v.errors:
            if e.code == SpecValidationCode.DERIVED_LOOKUP_MISS:
                self._add_unresolved(e)

        # Step 3: counts, products, ranks.
        for n in spec_derived_numbers(self.model, self.doc, read_proposed=self.marked):
            self._write(3, n.path, n.field, n.value)

    def _add_unresolved(self, e: SpecValidationError) -> None:
        key = f"{e.code.value} {e.path} {e.message}"
        if key not in self._unresolved_keys:
            self._unresolved_keys.add(key)
            self.unresolved.append(e)

    # --- the writes ---------------------------------------------------------

    def _get(self, path: str, field: Optional[str]) -> str:
        if field == K_SPEC_HEADLINE_FIELD:
            v = self.doc.headline(path)
        elif field is None:
            v = self.doc.content(path)
        else:
            v = self.doc.form_field(path, field)
        return v if v is not None else ""

    def _set_plain(self, path: str, field: Optional[str], value: str) -> None:
        if field == K_SPEC_HEADLINE_FIELD:
            self.doc.set_headline(path, value)
        elif field is None:
            self.doc.set_content(path, value)
        else:
            self.doc.set_form_field(path, field, value)

    def _write(self, step: int, path: str, field: Optional[str], value: str) -> None:
        """Writes *value* at *path* / *field*: plainly, or marked against the
        value there (compared from its original, so a change already proposed
        is not proposed again)."""
        current = self._get(path, field)
        if not self.marked:
            if current.strip() == value.strip():
                return
            self._set_plain(path, field, value)
        else:
            if apply_inline_marks_text(current, accept=True).strip() == value.strip():
                return
            original = apply_inline_marks_text(current, accept=False)
            if not mark_change_text(original, value).exact:
                what = "the content" if field is None else f'form field "{field}"'
                self._add_unresolved(
                    SpecValidationError(
                        path=path,
                        code=SpecValidationCode.UNMARKABLE,
                        message=f'{what} would become "{value}", a change that cannot '
                        "be marked exactly; it is left for the agent",
                    )
                )
                return
            self.api.set_marked(path, value, field=field, author=self.author, at=self.at)
        now = self._get(path, field)
        if now != current:
            self.changes.append(
                SpecDeriveChange(
                    step=step, kind="value", path=path, field=field,
                    old_value=current, new_value=now,
                )
            )

    def _add_row(
        self,
        step: int,
        lst: str,
        values: dict[str, str],
        section_id: Optional[str] = None,
    ) -> None:
        item = self.doc.add_list_item(lst, section_id)
        self.changes.append(SpecDeriveChange(step=step, kind="rowAdded", path=item))
        for k, value in values.items():
            hash_ = k.find("#")
            rel = k if hash_ < 0 else k[:hash_]
            field = None if hash_ < 0 else k[hash_ + 1:]
            self._write(step, f"{item}/{rel}", field, value)

    def _remove_row(self, step: int, row: str, empty: bool = False) -> None:
        if not self.marked or empty:
            if not self.doc.remove_list_item(row):
                return
            self.changes.append(SpecDeriveChange(step=step, kind="rowRemoved", path=row))
            return
        # Under review: every value of the row is proposed for deletion; once
        # accepted, the empty row goes with the next run.
        before = len(self.changes)

        def under(p: str) -> bool:
            return p == row or p.startswith(f"{row}/")

        for p in sorted(self.doc.content_paths):
            if under(p):
                self._write(step, p, None, "")
        for p in sorted(self.doc.form_paths):
            if not under(p):
                continue
            for f in sorted(self.doc.form_field_names(p)):
                self._write(step, p, f, "")
        if len(self.changes) > before:
            self.changes.insert(before, SpecDeriveChange(step=step, kind="rowRemoved", path=row))

    def _apply(self, f: SpecLinkFix, v: SpecLinkValidator) -> None:
        if f.kind == "set":
            self._write(f.step, f.path, f.field, f.value or "")
        elif f.kind == "append":
            ids = SpecLinkValidator.ids(v.form_value(f.path, f.field or ""))
            if f.value in ids:
                return
            self._write(f.step, f.path, f.field, ", ".join(ids + [f.value or ""]))
        elif f.kind == "addRow":
            self._add_row(f.step, f.path, f.values or {})
        elif f.kind == "removeRow":
            self._remove_row(f.step, f.path, f.empty)
        elif f.kind == "list":
            self._apply_list(f, v)
        elif f.kind == "copy":
            self._apply_copy(f.path, f.holder or "", v)

    def _apply_list(self, f: SpecLinkFix, v: SpecLinkValidator) -> None:
        """Makes the list hold one element per wanted tuple: elements matching
        no tuple removed, tuples matching no element added."""
        tuples = list(f.tuples or [])
        places = [] if len(tuples) == 0 else list(tuples[0].keys())

        def key(t: dict[str, str]) -> str:
            return " | ".join(t.get(p, "") for p in places)

        wanted = [key(t) for t in tuples]
        keep: list[str] = []
        for el in list(self.doc.list_items(f.path)):
            t = {p: v.place_value(p, el) for p in places}
            k = key(t)
            if k in wanted:
                wanted.remove(k)
                keep.append(k)
            else:
                self._remove_row(2, el)
        for t in tuples:
            k = key(t)
            if k in keep:
                keep.remove(k)
                continue
            values: dict[str, str] = {}
            probe = f"{f.path}-0"
            for p in places:
                r = v.at(p, probe)
                if r is None:
                    continue
                rel = r.path[len(probe) + 1:]
                values[rel if r.field is None else f"{rel}#{r.field}"] = t[p]
            self._add_row(2, f.path, values)

    def _apply_copy(self, copy: str, holder: str, v: SpecLinkValidator) -> None:
        """Writes the copy at *copy* from its *holder*: every value and
        element the holder has, in the copy, and nothing else."""
        theirs = v.subtree(holder)
        mine = v.subtree(copy)
        doc = self.doc

        def path_in(rel: str, create: bool) -> Optional[str]:
            cur = copy
            if rel == "":
                return cur
            for seg in rel.split("/"):
                bracket = seg.find("[")
                if bracket < 0:
                    cur = f"{cur}/{seg}"
                    continue
                lst = f"{cur}/{seg[:bracket]}"
                id_ = seg[bracket + 1: len(seg) - 1]
                found = next((i for i in doc.list_items(lst) if v.item_id(i) == id_), None)
                if found is not None:
                    cur = found
                elif not create:
                    return None
                else:
                    cur = doc.add_list_item(lst, id_)
                    v.item_ids[cur] = id_
                    self.changes.append(SpecDeriveChange(step=2, kind="rowAdded", path=cur))
            return cur

        def split(key: str) -> Optional[tuple[str, Optional[str]]]:
            kind = key[0]
            body = key[2:]
            if kind == "f":
                return body[: body.find("#")], body[body.find("#") + 1:]
            if kind == "c":
                return body, None
            if kind == "h":
                return body, K_SPEC_HEADLINE_FIELD
            return None

        # Elements the holder lacks go first, and nothing beneath them is
        # written.
        gone: list[str] = []
        for k in sorted(mine.keys()):
            if not k.startswith("i:") or k in theirs:
                continue
            rel = k[2:]
            if any(rel.startswith(f"{g}/") for g in gone):
                continue
            gone.append(rel)
            self._remove_row(2, mine[k][0])

        def beneath_gone(rel: str) -> bool:
            return any(rel == g or rel.startswith(f"{g}/") for g in gone)

        for k in sorted(theirs.keys()):
            if k.startswith("i:"):
                path_in(k[2:], True)
                continue
            s = split(k)
            if s is None:
                continue
            path = path_in(s[0], True)
            if path is None:
                continue
            self._write(2, path, s[1], theirs[k][1])
        for k in sorted(mine.keys()):
            if k in theirs or k.startswith("i:"):
                continue
            s = split(k)
            if s is None or beneath_gone(s[0]):
                continue
            path = path_in(s[0], False)
            if path is not None:
                self._write(2, path, s[1], "")


__all__ = ["SpecDeriveChange", "SpecDeriveResult", "derive_fields"]
