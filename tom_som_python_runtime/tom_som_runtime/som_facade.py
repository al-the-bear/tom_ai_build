"""The hand-written runtime support for the generated typed object model
(``tom_som_python_v0``) — a faithful port of
``tom_som_dart_runtime/lib/src/som_facade.dart``.

The generated classes are a thin **editing facade** over the generic
:class:`SpecDocument`: every typed getter/setter reads or writes the path-keyed
memory representation directly, so a mutation made through the typed surface is
immediately visible through the generic path and vice-versa (§3 — the two access
paths share one document). These base types (:class:`SomNode`,
:class:`SomList`, :class:`SomScalar`) hold no state of their own beyond the
document and a path; the generated subclasses only add typed accessors.
"""

from __future__ import annotations

from typing import Callable, Generic, List, Optional, TypeVar

from .spec_document import SpecDocument

_T = TypeVar("_T")


class SomNode:
    """The base class every generated typed facade class extends.

    It binds a facade instance to the :class:`SpecDocument` it edits and the
    ``path`` it lives at (the globally-unique section path, per
    ``spec_paths``). The generated subclass adds typed field accessors that
    delegate to ``doc`` at paths derived from ``path``.
    """

    def __init__(self, doc: SpecDocument, path: str) -> None:
        self.doc = doc
        self.path = path


class SomScalar(SomNode):
    """A scalar list item — a bare string value held in the document's content
    store at its own item ``path``. Used as the element facade for non-complex
    (``str``/scalar) lists."""

    @property
    def value(self) -> str:
        """The string value at this item's path (``''`` when unset)."""
        return self.doc.content(self.path) or ""

    @value.setter
    def value(self, v: str) -> None:
        """Sets the string value (an empty string clears it, per
        :class:`SpecDocument`)."""
        self.doc.set_content(self.path, v)


class SomList(Generic[_T]):
    """A typed view over a list field, layered over the document's list store.

    Items are addressed by their stable item paths
    (:meth:`SpecDocument.list_items`); each is wrapped in an element facade
    ``T`` by ``factory``. The wrapper holds no items itself — every operation
    reads through the live document, so it always reflects the current state.
    """

    def __init__(
        self,
        doc: SpecDocument,
        list_path: str,
        factory: Callable[[SpecDocument, str], _T],
    ) -> None:
        self.doc = doc
        self.list_path = list_path
        self._factory = factory

    @property
    def length(self) -> int:
        """The number of items currently in the list."""
        return self.doc.list_item_count(self.list_path)

    def __len__(self) -> int:
        return self.length

    @property
    def items(self) -> List[_T]:
        """The element facades for every item, in order."""
        return [self._factory(self.doc, p) for p in self.doc.list_items(self.list_path)]

    def __getitem__(self, index: int) -> _T:
        """The element facade for the item at ``index``."""
        return self._factory(self.doc, self.doc.list_items(self.list_path)[index])

    def add(self) -> _T:
        """Appends a new item and returns its element facade."""
        return self._factory(self.doc, self.doc.add_list_item(self.list_path))

    def remove_at(self, index: int) -> None:
        """Removes the item at ``index`` and every value nested beneath it."""
        self.doc.remove_list_item(self.doc.list_items(self.list_path)[index])


class SomVersionError(Exception):
    """Raised when a generated object model is instantiated against a document
    whose authoring model version it must not edit (§2.2)."""

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message

    def __str__(self) -> str:  # pragma: no cover - mirrors Dart toString
        return f"SomVersionError: {self.message}"


class _SomVersion:
    """A parsed ``major.minor`` version pair."""

    def __init__(self, major: int, minor: int) -> None:
        self.major = major
        self.minor = minor

    @staticmethod
    def parse(raw: str) -> "_SomVersion":
        v = _SomVersion.try_parse(raw)
        if v is None:
            raise SomVersionError(f'"{raw}" is not a valid major.minor version')
        return v

    @staticmethod
    def try_parse(raw: str) -> Optional["_SomVersion"]:
        parts = raw.split(".")
        if len(parts) != 2:
            return None
        major = _try_int(parts[0])
        minor = _try_int(parts[1])
        if major is None or minor is None:
            return None
        return _SomVersion(major, minor)


def _try_int(raw: str) -> Optional[int]:
    try:
        return int(raw)
    except ValueError:
        return None


def check_som_model_version(generated: str, document_version: Optional[str]) -> None:
    """The instantiation-time version check every generated root facade performs
    (§2.2). ``generated`` is the object model's own ``major.minor`` version;
    ``document_version`` is the document's recorded authoring stamp
    (``None``/empty for a brand-new, never-stamped document).

    Rules:
      * a ``None``/empty document stamp is always accepted — a new document is
        stamped on first edit;
      * within the **same major** version, a document whose minor is **≤** the
        generated minor is editable (older or equal — upgraded on edit); a
        document whose minor is **greater** is rejected (an older model must not
        edit a newer document);
      * a **different major** version is always rejected (cross-major is
        read/convert only, never in-place edit).

    Raises :class:`SomVersionError` on any rejection or an unparseable stamp.
    """
    if not document_version:
        return
    gen = _SomVersion.parse(generated)
    doc = _SomVersion.try_parse(document_version)
    if doc is None:
        raise SomVersionError(
            f'document model version "{document_version}" is not a valid major.minor'
        )
    if doc.major != gen.major:
        raise SomVersionError(
            f"document major version {doc.major} differs from the object model "
            f"major version {gen.major}; cross-major documents are read-only"
        )
    if doc.minor > gen.minor:
        raise SomVersionError(
            f"document model version {document_version} is newer than the object "
            f"model version {generated}; an older object model cannot edit a newer "
            "document"
        )
