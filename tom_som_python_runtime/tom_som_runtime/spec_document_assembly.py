"""Assembling one spec document from fragments written in parallel — a port of
`tom_som_dart_runtime/lib/src/spec_document_assembly.dart`.

A large document is often authored in parts — one group, or one agent, per set
of sections — each part a document of its own holding a subset of the sections.
References between parts can only be judged on the whole: the instance tier
resolves a ``refersTo`` against the document it is given, so a part validated
alone reports every reference into another part as dangling.
:meth:`SpecDocument.assemble` is the step that produces the whole.

The merge is over the plain-data stores (:meth:`SpecDocument.to_json`), and it
is **refusing**: a value two fragments both write — a content path, a form
field, a list, a headline, a code-spec location — is an overlap, and an
assembly with any overlap yields no document. Choosing a winner would make the
result depend on fragment order, and two parts writing one place is an
authoring conflict the parts' authors have to settle.
"""

from __future__ import annotations

from dataclasses import dataclass, field as dc_field
from typing import Any, Iterable, Mapping, Optional, Tuple, Union

from .spec_document import SpecDocument

__all__ = [
    "SpecAssemblyOverlap",
    "SpecDocumentAssembly",
    "assemble_spec_documents",
]


@dataclass(frozen=True)
class SpecAssemblyOverlap:
    """One place two or more fragments both write."""

    #: The store: ``content``, ``forms``, ``lists``, ``headlines`` or
    #: ``codeSpecs``.
    store: str
    #: The document path.
    path: str
    #: The fragments that write it, in the order they were given.
    fragments: Tuple[str, ...]
    #: The form field, for the ``forms`` store; ``None`` otherwise.
    field: Optional[str] = None

    @property
    def message(self) -> str:
        """One sentence naming the place and every fragment that writes it."""
        place = self.path if self.field is None else f"{self.path} field `{self.field}`"
        return (
            f"{place} ({self.store}) is written by "
            f"{' and '.join(self.fragments)} — a place two fragments both "
            "write is an authoring conflict, not something the assembly may "
            "resolve"
        )

    def __str__(self) -> str:
        return self.message


@dataclass(frozen=True)
class SpecDocumentAssembly:
    """The result of :meth:`SpecDocument.assemble`."""

    #: The assembled document; ``None`` when there is any overlap.
    document: Optional[SpecDocument] = None
    #: Every overlap, in store order and then path order.
    overlaps: Tuple[SpecAssemblyOverlap, ...] = dc_field(default_factory=tuple)

    @property
    def ok(self) -> bool:
        """Whether the fragments assembled."""
        return not self.overlaps


#: The stores whose entries are a single value at a path.
_PATH_STORES = ("content", "headlines", "codeSpecs")

#: The fixed order overlaps are reported in.
_STORE_ORDER = ("content", "forms", "lists", "headlines", "codeSpecs")


def _code_unit_key(s: str) -> bytes:
    # Dart sorts strings by UTF-16 code unit; big-endian UTF-16 bytes compare
    # the same way (Python's own str order is by code point).
    return s.encode("utf-16-be", "surrogatepass")


def assemble_spec_documents(
    fragments: Union[
        Mapping[str, SpecDocument], Iterable[Tuple[str, SpecDocument]]
    ],
) -> SpecDocumentAssembly:
    """Merges *fragments* — name → document, in order (a mapping or an ordered
    iterable of ``(name, document)`` pairs) — into one document. See the module
    docstring for the refusing rule."""
    pairs = list(fragments.items()) if isinstance(fragments, Mapping) else list(fragments)

    # store → key → writer fragments; key is the path, or ``path\0field``.
    writers: dict[str, dict[str, list[str]]] = {s: {} for s in _STORE_ORDER}
    merged: dict[str, dict[str, Any]] = {s: {} for s in _STORE_ORDER}

    for name, doc in pairs:
        json = doc.to_json()
        for store in _PATH_STORES:
            entries = json.get(store) or {}
            for path, value in entries.items():
                writers[store].setdefault(path, []).append(name)
                merged[store].setdefault(path, value)
        for path, fields in (json.get("forms") or {}).items():
            target = merged["forms"].setdefault(path, {})
            for f, value in fields.items():
                writers["forms"].setdefault(f"{path}\u0000{f}", []).append(name)
                target.setdefault(f, value)
        for path, spec in (json.get("lists") or {}).items():
            writers["lists"].setdefault(path, []).append(name)
            merged["lists"].setdefault(path, spec)

    overlaps: list[SpecAssemblyOverlap] = []
    for store in _STORE_ORDER:
        for key in sorted(writers[store], key=_code_unit_key):
            who = writers[store][key]
            if len(who) < 2:
                continue
            sep = key.find("\u0000")
            overlaps.append(
                SpecAssemblyOverlap(
                    store=store,
                    path=key if sep < 0 else key[:sep],
                    field=None if sep < 0 else key[sep + 1 :],
                    fragments=tuple(who),
                )
            )
    if overlaps:
        return SpecDocumentAssembly(overlaps=tuple(overlaps))
    document = SpecDocument()
    document.load_json({s: merged[s] for s in _STORE_ORDER if merged[s]})
    return SpecDocumentAssembly(document=document)
