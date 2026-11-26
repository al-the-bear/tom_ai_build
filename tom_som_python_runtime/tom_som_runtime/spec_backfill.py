"""``backfill``: the accepted end state of the Phase 3 documents, carried into
the Blueprint (DP-part-operations-2).

A port of `tom_som_dart_runtime/lib/src/spec_backfill.dart` (a ``part of``
``spec_document_set.dart`` there); it reads the comparison internals
:class:`SpecSetCheck` the set module exposes.
"""

from __future__ import annotations

import datetime as _dt
import functools
import re
from dataclasses import dataclass
from typing import Any, Iterable, Optional

from .spec_derive_fields import derive_fields
from .spec_document import SpecDocument
from .spec_document_set import (
    SpecDocumentSet,
    SpecSetCheck,
    SpecSetFound,
    SpecSyncCode,
    SpecSyncFinding,
    SpecSyncHolder,
    SpecSyncPlace,
    SpecSyncResolution,
    spec_sync_code_index,
)
from .spec_model import SpecFieldKind
from .spec_place import spec_section_positions
from .spec_review_annotations import K_SPEC_HEADLINE_FIELD, SpecReviewAnnotations
from .spec_section_id import effective_list_item_section_id


class SpecBackfillError(Exception):
    """Why :func:`backfill` refuses a set."""

    def __init__(self, code: str, places: list[SpecSyncPlace], message: str) -> None:
        super().__init__(message)
        #: ``setHasMarks``: a document holds an inline mark or an annotation
        #: block; ``noBlueprint``: the set has no Blueprint.
        self.code = code
        #: The places holding them, in document order.
        self.places = places
        #: The message.
        self.message = message

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form (no message)."""
        return {"code": self.code, "places": [p.to_json() for p in self.places]}

    def __str__(self) -> str:
        return f"SpecBackfillError({self.code}): {self.message}"


@dataclass(frozen=True)
class SpecBackfillChange:
    """One place :func:`backfill` wrote in the Blueprint."""

    #: The pair the change belongs to; empty for the revision entry and the
    #: derived places written after it.
    pair: str
    #: ``value`` (a value written or cleared), ``elementAdded``,
    #: ``elementRemoved``, ``revision`` (the history entry), ``derived`` (a
    #: derived place rewritten).
    kind: str
    #: The value's path, or the element's.
    path: str
    #: The form field (:data:`K_SPEC_HEADLINE_FIELD` for a headline), or
    #: ``None``.
    field: Optional[str] = None
    #: The value before (for an element, its id before).
    old_value: str = ""
    #: The value after (for an element, its id after).
    new_value: str = ""

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        out: dict[str, Any] = {"pair": self.pair, "kind": self.kind, "path": self.path}
        if self.field is not None:
            out["field"] = self.field
        out["old"] = self.old_value
        out["new"] = self.new_value
        return out


@dataclass(frozen=True)
class SpecBackfillLeft:
    """A finding :func:`backfill` left, with the reason."""

    #: The finding.
    finding: SpecSyncFinding
    #: ``heldHere`` (the Blueprint holds the value: the agent corrects the
    #: Phase 3 document), ``mayBeAdded`` (under ``subset``, not carried in),
    #: or the finding's resolution (``agent``, ``info``).
    reason: str

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {"finding": self.finding.to_json(), "reason": self.reason}


@dataclass(frozen=True)
class SpecBackfillResult:
    """What :func:`backfill` did."""

    #: The Blueprint written: the set's own, or its copy on a dry run.
    blueprint: SpecDocument
    #: Every place written, in the order written.
    changes: list[SpecBackfillChange]
    #: Every finding in scope it did not resolve, with the reason.
    left: list[SpecBackfillLeft]

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form (the Blueprint as its stores)."""
        return {
            "changes": [c.to_json() for c in self.changes],
            "left": [lf.to_json() for lf in self.left],
            "blueprint": self.blueprint.to_json(),
        }


def _cmp(a: Any, b: Any) -> int:
    return -1 if a < b else (1 if a > b else 0)


def backfill(
    doc_set: SpecDocumentSet,
    pairs: Optional[Iterable[str]] = None,
    path: Optional[str] = None,
    dry_run: bool = False,
    author: Optional[str] = None,
    date: Optional[str] = None,
) -> SpecBackfillResult:
    """Carries the end state of the Phase 3 documents into the Blueprint, as
    plain values (DP-part-operations-2): for every shared place whose holder
    is the Phase 3 document, the holder's value — a differing or missing value
    written, a value the Phase 3 document emptied cleared, an element only in
    the Phase 3 document added (with its stored section id, after its nearest
    preceding neighbour the Blueprint holds, or first), an element only in the
    Blueprint removed (DP-part-operations-3).

    It leaves ``detailOnly`` places, a ``heldHere`` place the documents
    disagree on, an element that under ``subset`` may be added, and every
    finding across two documents: each is listed in
    :attr:`SpecBackfillResult.left` with the reason.

    It refuses a set holding any inline mark or annotation block
    (:class:`SpecBackfillError`, ``setHasMarks``, the places named). It writes
    only the Blueprint; when it changed anything it adds one entry to the
    Blueprint's revision history (the ``RVENT`` list) naming the pairs, by
    *author* on *date*, and rewrites the Blueprint's derived places
    (``derive_fields``, plain). *pairs* and *path* (a Blueprint path) scope
    it; *dry_run* writes a copy. A second run right after the first writes
    nothing."""
    scope = set(pairs) if pairs is not None else None
    bp_root = doc_set.blueprint_root
    bp_name = None if bp_root is None else doc_set.name_of(bp_root)
    if bp_name is None:
        raise SpecBackfillError("noBlueprint", [], "the set holds no Blueprint")
    refl = doc_set.refl

    # No review in progress.
    marked: list[SpecSyncPlace] = []
    for name in doc_set.names:
        doc = doc_set.get(name)
        assert doc is not None
        root_type = doc_set.root_of(name)
        root = next(refl.root_segment(r) for r in refl.model.roots if r.type == root_type)
        seen: set[str] = set()
        for a in SpecReviewAnnotations(doc).list():
            k = f"{a.path}#{a.field or ''}"
            if k in seen:
                continue
            seen.add(k)
            marked.append(SpecSyncPlace(document=name, root=root, path=a.path, field=a.field))
    if len(marked) > 0:
        raise SpecBackfillError(
            "setHasMarks",
            marked,
            f"the set holds {len(marked)} value(s) with inline marks or "
            "annotation blocks; backfill carries the end state of an accepted "
            "review, so decide them first",
        )

    bp_doc = doc_set.get(bp_name)
    assert bp_doc is not None
    if dry_run:
        target = SpecDocument()
        target.load_json(bp_doc.to_json())
    else:
        target = bp_doc
    c = SpecSetCheck(doc_set)
    index = 0
    for p in doc_set.pairs:
        if scope is None or p.section_id in scope:
            c.compare_pair(p, index)
        index += 1
    # The links across two documents are the agent's; they are listed as
    # left.
    c.cross_checks(scope, index)

    def compare(a: SpecSetFound, b: SpecSetFound) -> int:
        if a.order != b.order:
            return a.order - b.order
        k = _cmp(a.key, b.key)
        if k != 0:
            return k
        return spec_sync_code_index(a.finding.code) - spec_sync_code_index(b.finding.code)

    c.out.sort(key=functools.cmp_to_key(compare))

    def in_scope(f: SpecSyncFinding) -> bool:
        return path is None or f.blueprint.path == path or f.blueprint.path.startswith(f"{path}/")

    w = _Backfill(doc_set, target, bp_name)
    left: list[SpecBackfillLeft] = []
    apply: list[SpecSetFound] = []
    for o in c.out:
        f = o.finding
        if not in_scope(f):
            continue
        if f.resolution == SpecSyncResolution.BACKFILL:
            apply.append(o)
        else:
            if f.holder == SpecSyncHolder.BLUEPRINT:
                reason = "heldHere"
            elif f.code == SpecSyncCode.SHARED_ELEMENT_MAY_BE_ADDED:
                reason = "mayBeAdded"
            else:
                reason = f.resolution
            left.append(SpecBackfillLeft(f, reason))
    w.apply(apply)
    if len(w.changes) > 0:
        w.revision_entry(
            author if author is not None else "backfill",
            date if date is not None else _dt.date.today().isoformat(),
        )
        for d in derive_fields(doc_set.model, target, marked=False).changes:
            w.changes.append(
                SpecBackfillChange(
                    pair="",
                    kind="derived",
                    path=d.path,
                    field=d.field,
                    old_value=d.old_value,
                    new_value=d.new_value,
                )
            )
    return SpecBackfillResult(blueprint=target, changes=w.changes, left=left)


_LAST_NUMBER = re.compile(r"(\d+)(?!.*\d)")


class _Backfill:
    def __init__(self, doc_set: SpecDocumentSet, doc: SpecDocument, name: str) -> None:
        self.set = doc_set
        self.doc = doc
        self.name = name
        self.changes: list[SpecBackfillChange] = []
        self._pairs: set[str] = set()

    @property
    def refl(self) -> Any:
        return self.set.refl

    def _get(self, path: str, field: Optional[str]) -> str:
        if field == K_SPEC_HEADLINE_FIELD:
            v = self.doc.headline(path)
        elif field is None:
            v = self.doc.content(path)
        else:
            v = self.doc.form_field(path, field)
        return v if v is not None else ""

    def _set(self, path: str, field: Optional[str], value: str) -> None:
        if field == K_SPEC_HEADLINE_FIELD:
            self.doc.set_headline(path, value)
        elif field is None:
            self.doc.set_content(path, value)
        else:
            self.doc.set_form_field(path, field, value)

    def _write(self, pair: str, path: str, field: Optional[str], value: str) -> None:
        old = self._get(path, field)
        if old.strip() == value.strip():
            return
        self._set(path, field, value)
        self._pairs.add(pair)
        self.changes.append(
            SpecBackfillChange(
                pair=pair, kind="value", path=path, field=field, old_value=old, new_value=value
            )
        )

    def _id_of(self, item: str) -> str:
        return self._id_in(self.doc, item)

    def _id_in(self, doc: SpecDocument, item: str) -> str:
        stored = doc.item_section_id(item)
        if stored is not None:
            return stored
        lst = item[: item.rfind("-")]
        res = self.refl.resolve(lst)
        f = res.field if res is not None else None
        items = doc.list_items(lst)
        return effective_list_item_section_id(
            None,
            f.section_id_pattern if f is not None else None,
            (items.index(item) if item in items else -1) + 1,
            f.name if f is not None else lst.split("/")[-1],
        )

    @staticmethod
    def _rel(key: str) -> str:
        body = key[2:]
        hash_ = body.find("#")
        return body if hash_ < 0 else body[:hash_]

    def apply(self, found: list[SpecSetFound]) -> None:
        doc = self.doc
        # 1. Elements only in the Blueprint go, first.
        for o in found:
            if (
                o.finding.code != SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT
                or not o.key.startswith("i:")
            ):
                continue
            assert o.b is not None
            item = o.b.items.get(o.key[2:])
            if item is None or not doc.remove_list_item(item):
                continue
            self._pairs.add(o.finding.pair)
            self.changes.append(
                SpecBackfillChange(
                    pair=o.finding.pair,
                    kind="elementRemoved",
                    path=item,
                    old_value=o.finding.blueprint.value or "",
                )
            )

        # 2. Values, and the ids of reference fields.
        ids: dict[str, tuple[str, dict[str, None], dict[str, None]]] = {}

        def ids_of(key: str, pair: str) -> tuple[str, dict[str, None], dict[str, None]]:
            e = ids.get(key)
            if e is None:
                e = (pair, {}, {})
                ids[key] = e
            return e

        for o in found:
            f = o.finding
            if o.key.startswith("i:"):
                continue
            field = f.blueprint.field
            if f.code in (SpecSyncCode.SHARED_VALUE_DIFFERS, SpecSyncCode.SHARED_VALUE_MISSING):
                assert o.d is not None
                self._write(f.pair, f.blueprint.path, field, o.d.values[o.key].value)
            elif f.code == SpecSyncCode.SHARED_VALUE_ONLY_IN_BLUEPRINT:
                self._write(f.pair, f.blueprint.path, field, "")
            elif f.code == SpecSyncCode.SHARED_ELEMENT_MISSING:
                ids_of(f"{f.blueprint.path}#{field}", f.pair)[1][f.detail.value or ""] = None
            elif f.code == SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT:
                ids_of(f"{f.blueprint.path}#{field}", f.pair)[2][f.blueprint.value or ""] = None
        for key, (pair, add, drop) in ids.items():
            hash_ = key.rfind("#")
            p = key[:hash_]
            field = key[hash_ + 1:]
            now: list[str] = []
            for s in self._get(p, field).split(","):
                if s.strip() != "" and s.strip() not in drop:
                    now.append(s.strip())
            for x in add:
                if x not in now:
                    now.append(x)
            self._write(pair, p, field, ", ".join(now))

        # 3. Elements only in the Phase 3 document come in, each with every
        # value the pair shares beneath it, then take their place.
        added: list[tuple[str, str, list[str]]] = []
        for o in found:
            if o.finding.code != SpecSyncCode.SHARED_ELEMENT_MISSING or not o.key.startswith("i:"):
                continue
            d = o.d
            assert d is not None
            rel = o.key[2:]
            id_ = rel[rel.rfind("[") + 1: len(rel) - 1]
            lst = o.finding.blueprint.path
            detail_item = d.items[rel]
            item = doc.add_list_item(lst, id_)
            self._pairs.add(o.finding.pair)
            self.changes.append(
                SpecBackfillChange(pair=o.finding.pair, kind="elementAdded", path=item, new_value=id_)
            )
            # Nested elements first (shortest key first), then the values.
            mapped: dict[str, str] = {detail_item: item}
            nested = sorted((k for k in d.items if k.startswith(f"{rel}/")), key=len)
            for k in nested:
                d_path = d.items[k]
                parent: Optional[tuple[str, str]] = None
                for m in mapped.items():
                    if d_path.startswith(f"{m[0]}/") and (
                        parent is None or len(m[0]) > len(parent[0])
                    ):
                        parent = m
                if parent is None:
                    continue
                seg = d_path[len(parent[0]) + 1:]
                nested_id = k[k.rfind("[") + 1: len(k) - 1]
                mapped[d_path] = doc.add_list_item(
                    f"{parent[1]}/{seg[: seg.rfind('-')]}", nested_id
                )

            def into(d_path: str) -> Optional[str]:
                best: Optional[tuple[str, str]] = None
                for m in mapped.items():
                    if (d_path == m[0] or d_path.startswith(f"{m[0]}/")) and (
                        best is None or len(m[0]) > len(best[0])
                    ):
                        best = m
                return None if best is None else f"{best[1]}{d_path[len(best[0]):]}"

            for k, v in d.values.items():
                r = _Backfill._rel(k)
                if r != rel and not r.startswith(f"{rel}/"):
                    continue
                target = into(v.path)
                if target is None or v.value == "":
                    continue
                self._set(target, v.field, v.value)
            # The detail list's order, by id.
            detail_doc = self.set.get(o.finding.detail.document or "")
            assert detail_doc is not None
            detail_list = detail_item[: detail_item.rfind("-")]
            added.append(
                (
                    lst,
                    id_,
                    [self._id_in(detail_doc, it) for it in detail_doc.list_items(detail_list)],
                )
            )
        # Each list takes its new elements in one reorder: an element goes
        # after its nearest preceding neighbour (in the Phase 3 order) the
        # Blueprint holds, or first.
        by_list: dict[str, list[tuple[str, list[str]]]] = {}
        for lst, id_, order in added:
            by_list.setdefault(lst, []).append((id_, order))
        orders: dict[str, list[str]] = {}
        for lst, entries in by_list.items():
            new_ids = {a[0] for a in entries}
            items = doc.list_items(lst)
            order_now = [i for i in items if self._id_of(i) not in new_ids]
            for a_id, a_order in entries:
                item = next(i for i in items if self._id_of(i) == a_id)
                before = a_order[: a_order.index(a_id)] if a_id in a_order else a_order[:-1]
                at = 0
                for j in range(len(before) - 1, -1, -1):
                    k = next(
                        (n for n, x in enumerate(order_now) if self._id_of(x) == before[j]), -1
                    )
                    if k >= 0:
                        at = k + 1
                        break
                order_now.insert(at, item)
            orders[lst] = order_now
        self._reorder(orders)
        # Each added element is reported at the place it took.
        for i, ch in enumerate(self.changes):
            if ch.kind != "elementAdded":
                continue
            lst = ch.path[: ch.path.rfind("-")]
            now_path = next(
                (x for x in doc.list_items(lst) if self._id_of(x) == ch.new_value), None
            )
            if now_path is None or now_path == ch.path:
                continue
            self.changes[i] = SpecBackfillChange(
                pair=ch.pair, kind=ch.kind, path=now_path, new_value=ch.new_value
            )

    def _reorder(self, orders: dict[str, list[str]]) -> None:
        """Puts the items of each list in *orders* in the order given, in one
        pass over the document's stores: the lists renumbered ``<list>-1 …
        <list>-n``, every value beneath an item travelling with it, an
        anonymous item whose positional id would change keeping its old id (as
        ``move_list_item`` does). Inner lists go first, so an outer rename
        carries their new paths."""
        if len(orders) == 0:
            return
        doc = self.doc
        lists = sorted(orders.keys(), key=lambda a: -len(a.split("/")))
        ids: dict[str, str] = {}
        for lst in lists:
            for i in doc.list_items(lst):
                ids[i] = self._id_of(i)
        json = doc.to_json()

        def rename(key: str, mapping: dict[str, str]) -> str:
            for frm, to in mapping.items():
                if key == frm:
                    return to
                if key.startswith(f"{frm}/"):
                    return f"{to}{key[len(frm):]}"
            return key

        for lst in lists:
            order = orders[lst]
            list_json = json["lists"][lst]
            mapping: dict[str, str] = {}
            for i, it in enumerate(order):
                to = f"{lst}-{i + 1}"
                if it != to:
                    mapping[it] = to
            if len(mapping) == 0:
                continue
            stored_ids: dict[str, Any] = dict(list_json.get("ids") or {})
            original = doc.list_items(lst)
            for i, it in enumerate(order):
                pos = original.index(it) if it in original else -1
                if pos != i and it not in stored_ids:
                    stored_ids[it] = ids.get(it)
            for store in ("content", "forms", "headlines", "codeSpecs", "units"):
                m = json.get(store)
                if m is None:
                    continue
                json[store] = {rename(k, mapping): v for k, v in m.items()}
            new_lists: dict[str, Any] = {}
            for key, value in json["lists"].items():
                spec = dict(value)
                if key == lst:
                    spec["items"] = [rename(i, mapping) for i in order]
                    spec["ids"] = {rename(i, mapping): stored_ids.get(i) for i in order}
                else:
                    spec["items"] = [rename(i, mapping) for i in spec["items"]]
                    if isinstance(spec.get("ids"), dict):
                        spec["ids"] = {rename(k, mapping): v for k, v in spec["ids"].items()}
                new_lists[rename(key, mapping)] = spec
            json["lists"] = new_lists
        doc.load_json(json)

    def revision_entry(self, author: str, date: str) -> None:
        """One entry in the Blueprint's revision history naming the pairs."""
        doc = self.doc
        refl = self.refl
        root = self.set.blueprint_root
        lst: Optional[str] = None
        for p in spec_section_positions(refl, root):
            if not p.is_member or p.member is None or p.member.kind != SpecFieldKind.LIST:
                continue
            if "-*" in p.path:
                continue
            el = refl.class_named(p.member.element_type)
            if el is None or el.section_id != "RVENT":
                continue
            lst = p.path
            break
        if lst is None:
            return
        items = doc.list_items(lst)
        last = "" if len(items) == 0 else (doc.form_field(f"{items[-1]}/content", "version") or "")
        version = _Backfill._bump(last)
        item = doc.add_list_item(lst)
        names = list(
            dict.fromkeys(p.section_id for p in self.set.pairs if p.section_id in self._pairs)
        )
        summary = (
            f"Backfilled from {', '.join(n for n in self.set.names if n != self.name)}: "
            + ", ".join(names)
        )
        for f, v in (("version", version), ("date", date), ("author", author), ("summary", summary)):
            doc.set_form_field(f"{item}/content", f, v)
        self.changes.append(
            SpecBackfillChange(pair="", kind="revision", path=item, new_value=version)
        )

    @staticmethod
    def _bump(v: str) -> str:
        """The version after *v*: its last number raised by one (``1.2`` →
        ``1.3``), ``1`` when it holds none."""
        m = _LAST_NUMBER.search(v)
        if m is None:
            return "1" if v == "" else f"{v}.1"
        n = int(m.group(1)) + 1
        return f"{v[: m.start()]}{n}{v[m.end():]}"


__all__ = [
    "SpecBackfillError",
    "SpecBackfillChange",
    "SpecBackfillLeft",
    "SpecBackfillResult",
    "backfill",
]
