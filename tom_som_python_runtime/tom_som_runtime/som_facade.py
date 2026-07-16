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

import datetime as _dt
import enum
from typing import Callable, Generic, List, Optional, TypeVar, Union

from .spec_document import SpecDocument
from .spec_section_id import (
    SpecSectionIdCollision,
    generate_list_item_section_id,
)

_T = TypeVar("_T")

#: Anything carrying ``month``/``day`` — a :class:`datetime.date` or
#: :class:`datetime.datetime` — accepted for section-id date derivation.
_DateLike = Union[_dt.date, _dt.datetime]


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

    @property
    def is_empty(self) -> bool:
        """Whether this section holds no value at all — neither a
        content/scalar/enum leaf, a ``@Form`` entry, a child section, nor a list
        item — at its :attr:`path` or nested beneath it (§ item 5).

        The typed counterpart of the generic
        :meth:`SpecDocument.has_values_under`, so "is this section filled?"
        answers identically through the typed facade and the generic path (the
        typed ``content`` getter coalescing a missing value to ``''`` no longer
        disagrees with a generic ``None``). Emptiness is defined once, in
        :meth:`SpecDocument.has_values_under`.

        Named ``is_empty`` to match the proposed API; a model field literally
        named ``is_empty`` would collide with this property, but the spec model
        carries none."""
        return not self.doc.has_values_under(self.path)

    @property
    def can_have_content(self) -> bool:
        """Whether this section **type** declares the standard ``content`` text
        leaf — i.e. whether the ``content`` getter/setter exists on it (§ item
        10).

        This is a **structural / schema** predicate: a per-type constant of the
        section's type, answering "*can* this section hold body text?" without
        probing ``.content`` at runtime. Container-only sections (e.g.
        ``SystemsToReplace``, which has no ``content`` leaf) inherit this
        ``False`` default; content-bearing sections (e.g. ``Goals``) override it
        to ``True``.

        It is deliberately distinct from the two **state** predicates: the
        generic :meth:`SpecDocument.has_content` answers "is a value present at
        this leaf *now*?" and :attr:`is_empty` answers "is this subtree empty
        *now*?". ``can_have_content`` never looks at the document — it describes
        the model, not the data."""
        return False

    @property
    def spec_section_id(self) -> Optional[str]:
        """This node's section id when it is a list item (AA1 criterion 1 read),
        or ``None`` for non-list nodes (roots, complex/section children — their
        id is the fixed ``@SectionId`` already embedded in :attr:`path`).

        Named ``spec_section_id`` — a name the Python emitter never produces for
        a model field accessor — so this structural accessor can never collide
        with a typed field a generated subclass emits (mirrors the Dart
        ``$sectionId`` collision-proofing, AA-2 decision AB-D1)."""
        return self.doc.item_section_id(self.path)

    @spec_section_id.setter
    def spec_section_id(self, id: Optional[str]) -> None:
        """Overrides this list item's section id (AA1 criterion 5): an arbitrary
        suffix, validated unique within the owning list. Raises
        :class:`SpecSectionIdCollision` on a duplicate, or :class:`ValueError`
        if this node is not a live list item."""
        if id is None:
            return
        self.doc.set_item_section_id(self.path, id)

    @property
    def spec_headline(self) -> Optional[str]:
        """This section's **stored headline** (YRD3), or ``None`` when the
        section renders its effective default title (``@Headline`` default,
        else name derivation). Available on every node — fixed sections and
        list items alike — and ``spec_``-prefixed for the same
        collision-proofing as :attr:`spec_section_id` (mirrors the Dart
        ``$headline``)."""
        return self.doc.headline(self.path)

    @spec_headline.setter
    def spec_headline(self, value: Optional[str]) -> None:
        """Sets or clears this section's stored headline (YRD3). ``None`` or an
        empty string clears the store, returning the section to its default
        title."""
        self.doc.set_headline(self.path, value or "")


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
        pattern: Optional[str] = None,
    ) -> None:
        self.doc = doc
        self.list_path = list_path
        self._factory = factory
        #: The list field's ``@SectionIdPattern`` (e.g. ``DACEN-ITEM-xxx``), or
        #: ``None`` for a pattern-less (scalar) list. Drives section-id
        #: generation on :meth:`add` (AA1 criteria 3–5).
        self.pattern = pattern

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

    @property
    def section_ids(self) -> List[str]:
        """The section ids currently assigned within this list, in item
        order."""
        return self.doc.list_item_section_ids(self.list_path)

    def _add_item_path(
        self,
        section_id: Optional[str] = None,
        date: Optional[_DateLike] = None,
    ) -> str:
        """Appends a new item and returns its stable item path, applying the
        list's section-id logic (AA1 criteria 3–5).

        The single source of the append/section-id derivation shared by
        :meth:`add` and :meth:`add_content` (mirrors the Dart
        ``_addItemPath``): when the list has a :attr:`pattern`, *section_id* is
        used as an override (validated unique — raises
        :class:`SpecSectionIdCollision` on a collision), otherwise one is
        generated from the pattern using *date* (defaulting to today). A
        pattern-less list ignores both arguments."""
        if self.pattern is None:
            return self.doc.add_list_item(self.list_path)
        if section_id is not None:
            id = section_id
        else:
            when = date or _dt.date.today()
            id = generate_list_item_section_id(
                self.pattern,
                when.month,
                when.day,
                self.doc.list_item_section_ids(self.list_path),
            )
        return self.doc.add_list_item(self.list_path, section_id=id)

    def add(
        self,
        section_id: Optional[str] = None,
        date: Optional[_DateLike] = None,
    ) -> _T:
        """Appends a new item and returns its element facade.

        When the list has a :attr:`pattern`, the new item is assigned a section
        id (AA1 criteria 3–5): *section_id* if given (an override, validated
        unique — raises :class:`SpecSectionIdCollision` on a collision),
        otherwise one generated from the pattern using *date* (defaulting to
        today) for the two-letter-date component. A pattern-less list ignores
        both arguments."""
        return self._factory(
            self.doc, self._add_item_path(section_id=section_id, date=date)
        )

    def add_content(
        self,
        content: str,
        section_id: Optional[str] = None,
        date: Optional[_DateLike] = None,
    ) -> _T:
        """Appends a content-only item and sets its content leaf in one call,
        returning the new item's element facade (§ item 9).

        A convenience over :meth:`add`: it appends with the *same* section-id
        logic (*section_id* override / pattern generation / pattern-less — see
        :meth:`_add_item_path`) and writes *content* to the item's **nested**
        ``<item_path>/content`` leaf via :meth:`SpecDocument.set_content`.

        Targets the nested ``<item>/content`` leaf, not the item path itself, so
        it is meant for complex list elements that carry a ``content`` field.
        Scalar lists (whose value *is* the item path) are out of scope — use
        :attr:`SomScalar.value` for those."""
        item_path = self._add_item_path(section_id=section_id, date=date)
        self.doc.set_content(f"{item_path}/content", content)
        return self._factory(self.doc, item_path)

    @property
    def contents(self) -> List[str]:
        """An ordered, read-only view of every item's ``<item_path>/content``
        leaf, coalescing a missing leaf to ``''`` (§ item 9).

        Mirrors the element ``content`` getter's ``None`` → ``''`` coalescing so
        the list-level view agrees with reading each item individually. Reads
        the nested ``<item>/content`` leaf, so it is meant for complex list
        elements carrying a ``content`` field, not scalar lists."""
        return [
            self.doc.content(f"{p}/content") or ""
            for p in self.doc.list_items(self.list_path)
        ]

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


class SomEditability(enum.Enum):
    """The outcome of the §2.2 version check, as a value a read-only viewer can
    branch on instead of catching :class:`SomVersionError` (§ item 8).

    It is the non-throwing companion to :func:`check_som_model_version`: the
    constructor throws on any value other than :attr:`EDITABLE`, while
    :func:`som_editability_for` returns the same classification without throwing
    so a consumer can decide *open for edit* vs *open read-only* up front.
    """

    #: The object model may edit the document in place — a ``None``/empty stamp
    #: (a brand-new document) or a same-major, minor-``≤`` stamp.
    EDITABLE = "editable"

    #: The document was authored under a **different major** version; it may be
    #: read/converted but never edited in place.
    READ_ONLY_CROSS_MAJOR = "read_only_cross_major"

    #: The document is same-major but a **newer minor** than the object model; an
    #: older model must not edit a newer document.
    REJECTED_NEWER_MINOR = "rejected_newer_minor"

    #: The document stamp is not a valid ``major.minor`` string.
    INVALID_VERSION = "invalid_version"


def som_editability_for(
    generated: str, document_version: Optional[str]
) -> SomEditability:
    """Classifies a document's editability under the §2.2 rules **without
    raising** (§ item 8). ``generated`` is the object model's own
    ``major.minor`` version; ``document_version`` is the document's recorded
    authoring stamp (``None``/empty for a brand-new, never-stamped document).

    This is the single definition of the version rules;
    :func:`check_som_model_version` raises based on the value returned here, so
    the two never diverge.
    """
    if not document_version:
        return SomEditability.EDITABLE
    gen = _SomVersion.parse(generated)
    doc = _SomVersion.try_parse(document_version)
    if doc is None:
        return SomEditability.INVALID_VERSION
    if doc.major != gen.major:
        return SomEditability.READ_ONLY_CROSS_MAJOR
    if doc.minor > gen.minor:
        return SomEditability.REJECTED_NEWER_MINOR
    return SomEditability.EDITABLE


def check_som_model_version(generated: str, document_version: Optional[str]) -> None:
    """The instantiation-time version check every generated root facade performs
    (§2.2). ``generated`` is the object model's own ``major.minor`` version;
    ``document_version`` is the document's recorded authoring stamp
    (``None``/empty for a brand-new, never-stamped document).

    Rules (see :func:`som_editability_for`, which this delegates to):
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
    editability = som_editability_for(generated, document_version)
    if editability is SomEditability.EDITABLE:
        return
    if editability is SomEditability.INVALID_VERSION:
        raise SomVersionError(
            f'document model version "{document_version}" is not a valid major.minor'
        )
    if editability is SomEditability.READ_ONLY_CROSS_MAJOR:
        gen = _SomVersion.parse(generated)
        doc = _SomVersion.parse(document_version)
        raise SomVersionError(
            f"document major version {doc.major} differs from the object model "
            f"major version {gen.major}; cross-major documents are read-only"
        )
    # SomEditability.REJECTED_NEWER_MINOR
    raise SomVersionError(
        f"document model version {document_version} is newer than the object "
        f"model version {generated}; an older object model cannot edit a newer "
        "document"
    )
