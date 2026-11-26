"""``prefill``: a Phase 3 document started from the Blueprint (BP-8).

A port of `tom_som_dart_runtime/lib/src/spec_prefill.dart` (a ``part of``
``spec_document_set.dart`` there); it reads the comparison internals
:class:`SpecSetCheck` and :class:`SpecSetSide` the set module exposes.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable, Optional

from .spec_derive_fields import SpecDeriveResult, derive_fields
from .spec_document import SpecDocument
from .spec_document_set import SpecDocumentSet, SpecSetCheck, SpecSetSide
from .spec_links_validator import validate_links
from .spec_review_annotations import K_SPEC_HEADLINE_FIELD
from .spec_validator import SpecValidationError, validate_document


class SpecPrefillError(Exception):
    """Why :func:`prefill` refuses."""

    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        #: ``noBlueprint`` (the set holds no Blueprint) or ``unknownRoot`` (the
        #: root names no root of the model, or the Blueprint's own).
        self.code = code
        #: The message.
        self.message = message

    def __str__(self) -> str:
        return f"SpecPrefillError({self.code}): {self.message}"


def _err_json(e: SpecValidationError) -> dict[str, Any]:
    return {"path": e.path, "code": e.code.value, "message": e.message}


@dataclass(frozen=True)
class SpecPrefillResult:
    """What :func:`prefill` did."""

    #: The document filled: the set's own, or the one created.
    document: SpecDocument
    #: Its name in the set.
    name: str
    #: Whether it was created by this call.
    created: bool
    #: The pairs it filled, by section id, in the Blueprint's order.
    filled_pairs: list[str]
    #: The pairs it left because their anchor already holds a value.
    skipped_pairs: list[str]
    #: The ``derive_fields`` run (plain) on the document after the copy.
    derived: SpecDeriveResult
    #: The document's findings after it (``validate_document``, then
    #: ``validate_links``): the agent's work list.
    findings: list[SpecValidationError]

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "name": self.name,
            "created": self.created,
            "filledPairs": list(self.filled_pairs),
            "skippedPairs": list(self.skipped_pairs),
            "derived": {
                "changes": [c.to_json() for c in self.derived.changes],
                "unresolved": [_err_json(e) for e in self.derived.unresolved],
            },
            "findings": [_err_json(e) for e in self.findings],
            "document": self.document.to_json(),
        }


def prefill(
    doc_set: SpecDocumentSet,
    root_type: str,
    name: Optional[str] = None,
    pairs: Optional[Iterable[str]] = None,
) -> SpecPrefillResult:
    """Fills the pairs of *root_type* (a root's type name or section id) that
    hold nothing yet from the Blueprint, once, at the start of a Phase 3
    document (BP-8): every value, element (with its stored section id) and
    headline beneath each pair's Blueprint anchor, outside ``detailOnly``,
    copied as plain values. Derived places are not copied; they are derived in
    the document (``derive_fields``, plain) after the copy.

    A pair whose anchor already holds any value is skipped, not merged, so a
    second run writes nothing. The document's front matter is left empty for
    the agent. When the set has no document of the root, it is created as
    *name* (default: the root's type name) and added to the set once it holds
    a value. *pairs* keeps those pairs (by section id) only."""
    scope = set(pairs) if pairs is not None else None
    bp_root = doc_set.blueprint_root
    bp_name = None if bp_root is None else doc_set.name_of(bp_root)
    if bp_root is None or bp_name is None:
        raise SpecPrefillError("noBlueprint", "the set holds no Blueprint")
    root = next(
        (r for r in doc_set.model.roots if r.type == root_type or r.section_id == root_type),
        None,
    )
    if root is None or root.type == bp_root:
        raise SpecPrefillError("unknownRoot", f"{root_type} names no Phase 3 root of the model")
    existing = doc_set.name_of(root.type)
    if existing is not None:
        doc_name = existing
    else:
        doc_name = name if name is not None else root.type
    found = doc_set.get(existing) if existing is not None else None
    doc = found if found is not None else SpecDocument()
    bp = doc_set.get(bp_name)
    assert bp is not None
    c = SpecSetCheck(doc_set)

    filled: list[str] = []
    skipped: list[str] = []
    for pair in doc_set.pairs:
        if pair.detail_root != root.type:
            continue
        if scope is not None and pair.section_id not in scope:
            continue
        # Nested pairs are filled on their own (when they are this root's).
        nested: list[str] = []
        for other in doc_set.pairs:
            if other is not pair:
                nested.extend(c.expand(bp, other.blueprint_anchor))
        wrote = False
        held = False
        for ba in c.expand(bp, pair.blueprint_anchor):
            ids = c.anchor_key(bp, ba)
            created_items: list[str] = []
            da = _anchor_in(c, doc, pair.detail_anchor, ids, created_items)
            if doc.has_values_under(da) and len(created_items) == 0:
                held = True
                continue
            side = c.collect(
                bp_name, bp, bp_root, ba, pair, [p for p in nested if p.startswith(f"{ba}/")]
            )
            if _copy(c, bp, side, doc, da):
                wrote = True
            else:
                # Nothing to copy: the anchor items made for it go again.
                for item in reversed(created_items):
                    doc.remove_list_item(item)
        if wrote:
            filled.append(pair.section_id)
        if held and not wrote:
            skipped.append(pair.section_id)

    created = existing is None and doc.has_values_under(doc_set.refl.root_segment(root))
    if created:
        doc_set.put(doc_name, doc)
    derived = derive_fields(doc_set.model, doc, marked=False)
    return SpecPrefillResult(
        document=doc,
        name=doc_name,
        created=created,
        filled_pairs=filled,
        skipped_pairs=skipped,
        derived=derived,
        findings=validate_document(doc_set.model, doc) + validate_links(doc_set.model, doc),
    )


def _anchor_in(
    c: SpecSetCheck, doc: SpecDocument, pattern: str, ids: str, created: list[str]
) -> str:
    """The concrete detail anchor of *pattern* in *doc* for a Blueprint anchor
    whose list items carry *ids* (``a/b``, in order): each ``<list>-*`` taken
    as the item of that id, created with it when missing."""
    want = [] if ids == "" else ids.split("/")
    k = 0
    cur = ""
    for seg in pattern.split("/"):
        if not seg.endswith("-*"):
            cur = seg if cur == "" else f"{cur}/{seg}"
            continue
        lst = f"{cur}/{seg[:-2]}"
        id_ = ""
        if k < len(want):
            id_ = want[k]
            k += 1
        hit = next((i for i in doc.list_items(lst) if c.item_id(doc, i) == id_), None)
        if hit is not None:
            cur = hit
        else:
            cur = doc.add_list_item(lst, id_)
            created.append(cur)
    return cur


def _copy(
    c: SpecSetCheck, bp: SpecDocument, side: SpecSetSide, doc: SpecDocument, anchor: str
) -> bool:
    """Copies the Blueprint values of *side* beneath *anchor* of *doc*: list
    items first, in the Blueprint's order and with their section ids, then
    every value. Whether anything was written."""
    wrote = False
    mapped: dict[str, str] = {side.anchor: anchor}

    def into(bp_path: str) -> Optional[str]:
        best: Optional[str] = None
        for k in mapped:
            if (bp_path == k or bp_path.startswith(f"{k}/")) and (
                best is None or len(k) > len(best)
            ):
                best = k
        return None if best is None else f"{mapped[best]}{bp_path[len(best):]}"

    # Items, outer lists first, each list in the Blueprint's order.
    list_set: dict[str, None] = {}
    item_paths: set[str] = set()
    for item in side.items.values():
        item_paths.add(item)
        if item != side.anchor:
            list_set[item[: item.rfind("-")]] = None
    lists = sorted(list_set, key=len)
    for lst in lists:
        target = into(lst)
        if target is None:
            continue
        for item in bp.list_items(lst):
            if item not in item_paths:
                continue
            mapped[item] = doc.add_list_item(target, c.item_id(bp, item))
            wrote = True
    for v in side.values.values():
        if v.value == "":
            continue
        p = into(v.path)
        if p is None:
            continue
        if v.field == K_SPEC_HEADLINE_FIELD:
            doc.set_headline(p, v.value)
        elif v.field is None:
            doc.set_content(p, v.value)
        else:
            doc.set_form_field(p, v.field, v.value)
        wrote = True
    return wrote


__all__ = ["SpecPrefillError", "SpecPrefillResult", "prefill"]
