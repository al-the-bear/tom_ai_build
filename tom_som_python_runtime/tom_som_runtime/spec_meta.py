"""The canonical SOM **metadata tree** — the runtime's DR1 §3.1 node types; a
faithful port of `tom_som_dart_runtime/lib/src/spec_meta.dart`.

One :class:`SomMetaTree` exists per document root. Its nodes carry *every*
`tom_specs_core` annotation the model source declares, plus the exact class and
member names, so the tree is the single language-neutral description of a
document's structure:

  * :class:`SomMetaNode` — one node per navigable model position (§3.1), with
    section id / pattern, kind, serialization order, ``@Min``, content type,
    help/comment/doc texts, form metadata, traceability links
    (``@MapsTo`` / ``@DetailedIn`` / ``@SecondLevelSectionId``) and the lossless
    ``extra`` annotation list;
  * :class:`SomMetaTree` — wires parent links and absolute paths (the §4 path
    grammar shared with ``spec_paths``) and provides the two dynamic lookups
    every runtime keeps: :meth:`SomMetaTree.by_id` and
    :meth:`SomMetaTree.by_path`.

The runtime only *defines* these types; the generated facades (DR8) emit the
populated tree as statically initialized objects, and tests build small
fixture trees by hand.
"""

from __future__ import annotations

import re
from enum import Enum
from typing import Callable, Generic, Optional, TypeVar

from .spec_paths import (
    list_item_path,
    spec_path_join,
    spec_path_segments,
    split_list_item_segment,
)


class SomMetaKind(Enum):
    """The structural kind of a metadata node, mirroring DR1 §3.1
    (``list | form | section | content | enum | complex | scalar``)."""

    #: A ``List[T]`` field; items are addressed by ``-<seq>`` path suffixes and
    #: described by :attr:`SomMetaNode.element_node`.
    LIST = "list"
    #: A ``@Form`` content section (its fields live in :attr:`SomMetaNode.form`).
    FORM = "form"
    #: A field rendered as a section of its own.
    SECTION = "section"
    #: A free-text (markdown) content leaf.
    CONTENT = "content"
    #: An enum-valued leaf.
    ENUM_VALUE = "enum"
    #: A field typed by another model class (collapses into that class: the
    #: node's children are the target class's fields).
    COMPLEX = "complex"
    #: A plain scalar leaf (``String``/``int``/``double``/``bool``).
    SCALAR = "scalar"


class SomContentTypeMeta:
    """The ``@ContentType(type, description)`` annotation captured on a node."""

    def __init__(self, type: str, description: str) -> None:
        #: The declared content type (e.g. ``code``, ``diagram``).
        self.type = type
        #: The human/AI-facing description of the expected content.
        self.description = description


class SomFormFieldMeta:
    """One field of a ``@Form`` section (DR1 §3.1 ``FormMeta.fields``)."""

    def __init__(
        self,
        name: str,
        type_name: str,
        order: int,
        description: Optional[str] = None,
        required: bool = False,
        hint: Optional[str] = None,
        enum_values: Optional[list[str]] = None,
    ) -> None:
        #: The exact model field name (``approvedBy``).
        self.name = name
        #: The Dart type name of the field (``String``, ``int``, …).
        self.type_name = type_name
        #: The display label / description, when the form declares one.
        self.description = description
        #: Whether the form marks the field as required.
        self.required = required
        #: The authoring hint (e.g. ``e.g. 1.0``), when present.
        self.hint = hint
        #: Declaration order within the form.
        self.order = order
        #: Enum constant names when ``type_name`` is a model enum (YRD7);
        #: empty for non-enum field types. The complete value domain of an
        #: enum-typed form field, so editors and the generic modification API
        #: can validate and convert without generated code.
        self.enum_values = list(enum_values) if enum_values else []


class SomFormMeta:
    """The form metadata of a ``@Form`` node (DR1 §3.1 ``FormMeta``)."""

    def __init__(self, fields: list[SomFormFieldMeta]) -> None:
        #: The form's fields in declaration order.
        self.fields = fields

    def field_named(self, name: str) -> Optional[SomFormFieldMeta]:
        """The field named *name*, or ``None`` when absent."""
        for f in self.fields:
            if f.name == name:
                return f
        return None


class SomDocMeta:
    """The ``@Document`` metadata carried by a document root (DR1 §3.1
    ``DocMeta``)."""

    def __init__(
        self,
        name: str,
        description: str,
        based_on: Optional[list[str]] = None,
    ) -> None:
        #: The document's display name (``Solution Blueprint``).
        self.name = name
        #: The document's description.
        self.description = description
        #: Class names of the documents this one is based on
        #: (``@Document.basedOn``).
        self.based_on = based_on if based_on is not None else []


class SomSecondLevelId:
    """One ``@SecondLevelSectionId(documentClass, id)`` entry (DR1 §3.1)."""

    def __init__(self, document_class: str, id: str) -> None:
        #: The document class the second-level id applies within.
        self.document_class = document_class
        #: The section id used in that document.
        self.id = id


class SomMetaExtra:
    """One annotation captured losslessly into the generic ``extra`` list —
    annotations the tree defines no dedicated slot for (DR1 §3.1 note), e.g.
    ``@Max``, ``@MinLength``, ``@PatternCheck``, ``@TextRequired``."""

    def __init__(self, annotation: str, args: Optional[dict] = None) -> None:
        #: The annotation's class name (``Max``, ``PatternCheck``, …).
        self.annotation = annotation
        #: The resolved constructor arguments (``{'count': 4}``).
        self.args = args if args is not None else {}


class SomMetaNode:
    """One node of the SOM metadata tree (DR1 §3.1 ``MetaNode``).

    A node describes one navigable position of a document root's structure:
    the document root itself, a field, or a list's element subtree. Class-level
    annotations attach to the node where the class is *instantiated*;
    field-level annotations attach to the node directly (field-level
    ``@SectionId`` wins over the target class's).

    Nodes are immutable value carriers; :class:`SomMetaTree` wires the parent
    links and absolute paths when the tree is constructed. A node instance
    belongs to at most one tree.
    """

    def __init__(
        self,
        class_name: str,
        kind: SomMetaKind,
        type_name: str,
        member_name: Optional[str] = None,
        section_id: Optional[str] = None,
        class_section_id: Optional[str] = None,
        section_id_pattern: Optional[str] = None,
        serialization_order: Optional[int] = None,
        min: Optional[int] = None,
        unused: bool = False,
        content_type: Optional[SomContentTypeMeta] = None,
        content_help: Optional[str] = None,
        headline: Optional[str] = None,
        comment: Optional[str] = None,
        doc_comment: Optional[str] = None,
        class_doc_comment: Optional[str] = None,
        form: Optional[SomFormMeta] = None,
        document: Optional[SomDocMeta] = None,
        maps_to: Optional[str] = None,
        detailed_in: Optional[str] = None,
        second_level_ids: Optional[list[SomSecondLevelId]] = None,
        extra: Optional[list[SomMetaExtra]] = None,
        recursive: bool = False,
        children: Optional[list["SomMetaNode"]] = None,
        element_node: Optional["SomMetaNode"] = None,
    ) -> None:
        #: The exact model class name this node is (for root/complex/section
        #: nodes: the instantiated class; for leaves: the declaring class of
        #: the field).
        self.class_name = class_name
        #: The exact field name in the parent class, or ``None`` on the
        #: document root and on list element subtrees.
        self.member_name = member_name
        #: The effective **field-level** ``@SectionId``. Kept field-level so the
        #: tree's path grammar (:attr:`segment`) stays byte-compatible with the
        #: document store; the target class's own id (for a section/complex node
        #: whose field carries no id) is carried separately in
        #: :attr:`class_section_id`.
        self.section_id = section_id
        #: The target class's own ``@SectionId`` (root/section/complex nodes),
        #: the DR1 §2.2 fallback for a display/mapping key when
        #: :attr:`section_id` is ``None``. Never enters :attr:`segment`.
        self.class_section_id = class_section_id
        #: The ``@SectionIdPattern`` on a list field (item ids), when any.
        self.section_id_pattern = section_id_pattern
        #: The structural kind of the node.
        self.kind = kind
        #: The Dart type name of the field/class (``String``, ``GoalEntry``, …).
        self.type_name = type_name
        #: ``@SerializationOrder(order)``, when annotated.
        self.serialization_order = serialization_order
        #: ``@Min(count)``, when annotated.
        self.min = min
        #: Whether ``@Unused`` is present on the node.
        self.unused = unused
        #: ``@ContentType``, when annotated.
        self.content_type = content_type
        #: ``@ContentHelp(guidance)``, when annotated.
        self.content_help = content_help
        #: The ``@Headline(text)`` predefined DEFAULT headline (YRD4;
        #: field-level wins over the target class's), when annotated.
        #:
        #: Render precedence: ``stored headline > this default > name
        #: derivation``. Editors prefill a new section's headline from this; a
        #: stored headline always wins and stays editable.
        self.headline = headline
        #: ``@Comment(text)``, when annotated.
        self.comment = comment
        #: The cleaned ``///`` doc comment (member wins over class), when any.
        self.doc_comment = doc_comment
        #: The instantiated class's own doc comment, when it differs from
        #: :attr:`doc_comment`.
        self.class_doc_comment = class_doc_comment
        #: Form metadata, for :attr:`SomMetaKind.FORM` nodes.
        self.form = form
        #: ``@Document`` metadata; non-``None`` only on the document root.
        self.document = document
        #: ``@MapsTo`` target class name, when annotated.
        self.maps_to = maps_to
        #: ``@DetailedIn`` target class name, when annotated.
        self.detailed_in = detailed_in
        #: ``@SecondLevelSectionId`` entries, when annotated.
        self.second_level_ids = (
            second_level_ids if second_level_ids is not None else []
        )
        #: Annotations without a dedicated slot, captured losslessly.
        self.extra = extra if extra is not None else []
        #: Whether this node is a recursive re-entry reference (a class already
        #: on the descent stack): ``kind == COMPLEX``, no children.
        self.recursive = recursive
        #: The child nodes, in ``@SerializationOrder`` order. For
        #: complex/section nodes these are the target class's fields (the class
        #: collapses onto the node); empty for leaves and recursive references.
        self.children = children if children is not None else []
        #: For :attr:`SomMetaKind.LIST` nodes: the element class subtree. Its
        #: children describe each item's structure; item positions have no
        #: static path (see :attr:`path`).
        self.element_node = element_node

        # --- tree wiring (set once by SomMetaTree) ---------------------------
        self._tree: Optional["SomMetaTree"] = None
        self._parent: Optional["SomMetaNode"] = None
        self._path: Optional[str] = None

    @property
    def tree(self) -> "SomMetaTree":
        """The tree this node belongs to.

        Raises :class:`RuntimeError` when the node has not been attached to a
        :class:`SomMetaTree` yet."""
        t = self._tree
        if t is None:
            raise RuntimeError(
                f"SomMetaNode({self.debug_name}) is not attached to a "
                "SomMetaTree"
            )
        return t

    @property
    def parent(self) -> Optional["SomMetaNode"]:
        """The parent node, or ``None`` on the document root. The parent of a
        list's :attr:`element_node` is the list node itself."""
        self.tree  # attachment guard
        return self._parent

    @property
    def path(self) -> Optional[str]:
        """The node's absolute document path per the §4 path grammar
        (``<rootSegment>/<segment>/…``), or ``None`` for nodes inside a list
        element subtree — their concrete paths depend on the item sequence
        (see :meth:`item_path` on the list node and
        :meth:`SomMetaTree.by_path`)."""
        self.tree  # attachment guard
        return self._path

    @property
    def segment(self) -> str:
        """The path segment this node contributes: the effective
        :attr:`section_id` when present, else the :attr:`member_name`, else
        the :attr:`class_name` (document root)."""
        return self.section_id or self.member_name or self.class_name

    def item_path(self, seq: int) -> str:
        """The path of the *seq*-th item of this list node (``<path>-<seq>``).

        Raises :class:`RuntimeError` when the node is not a list or has no
        static path."""
        if self.kind is not SomMetaKind.LIST:
            raise RuntimeError(
                f"item_path() requires a list node, {self.debug_name} is "
                f"{self.kind.value}"
            )
        p = self.path
        if p is None:
            raise RuntimeError(
                f"list {self.debug_name} sits inside a list element subtree "
                "and has no static path"
            )
        return list_item_path(p, seq)

    def child_by_member(self, name: str) -> Optional["SomMetaNode"]:
        """The direct child whose :attr:`member_name` equals *name*, or
        ``None``."""
        for c in self.children:
            if c.member_name == name:
                return c
        return None

    def child_by_segment(self, seg: str) -> Optional["SomMetaNode"]:
        """The direct child whose :attr:`segment` equals *seg*, or ``None``."""
        for c in self.children:
            if c.segment == seg:
                return c
        return None

    @property
    def debug_name(self) -> str:
        """A short identification for error messages."""
        if self.member_name is None:
            return self.class_name
        return f"{self.class_name}.{self.member_name}"


class SomMetaTree:
    """The metadata tree of one document root: parent/path wiring plus the two
    dynamic lookups (:meth:`by_id`, :meth:`by_path`) DR1 §4.3 requires every
    runtime to keep."""

    def __init__(self, root: SomMetaNode) -> None:
        """Wires *root*'s subtree: sets parent links, computes static paths,
        and indexes section ids.

        Raises :class:`ValueError` when *root* carries no ``@Document``
        metadata, and :class:`RuntimeError` when any node is already attached
        to another tree (nodes belong to exactly one tree)."""
        if root.document is None:
            raise ValueError(
                f"the tree root must carry @Document metadata "
                f"(SomMetaNode.document): {root.debug_name}"
            )
        #: The document root node (carries :attr:`SomMetaNode.document`).
        self.root = root
        self._by_id: dict[str, list[SomMetaNode]] = {}
        self._all_nodes: list[SomMetaNode] = []
        self._wire(root, parent=None, path=root.segment)

    def _wire(
        self,
        node: SomMetaNode,
        parent: Optional[SomMetaNode],
        path: Optional[str],
    ) -> None:
        if node._tree is not None:
            raise RuntimeError(
                f"SomMetaNode({node.debug_name}) is already attached to a "
                "SomMetaTree; nodes belong to exactly one tree"
            )
        node._tree = self
        node._parent = parent
        node._path = path
        self._all_nodes.append(node)
        id = node.section_id
        if id is not None:
            self._by_id.setdefault(id, []).append(node)
        for child in node.children:
            self._wire(child, parent=node, path=self._child_path(path, child))
        element = node.element_node
        if element is not None:
            # Item positions are dynamic (`<listPath>-<seq>`), so the element
            # subtree carries no static paths.
            self._wire(element, parent=node, path=None)

    @staticmethod
    def _child_path(
        parent_path: Optional[str], child: SomMetaNode
    ) -> Optional[str]:
        if parent_path is None:
            return None
        return spec_path_join(parent_path, child.segment)

    @property
    def all_nodes(self) -> list[SomMetaNode]:
        """Every node of the tree (document order; element subtrees follow
        their list node)."""
        return self._all_nodes

    # --- lookup by section id ------------------------------------------------

    def all_by_id(self, section_id: str) -> list[SomMetaNode]:
        """All nodes whose effective section id equals *section_id*, in
        document order. A shared class instantiated at several positions
        yields several nodes (ids resolve within their parent chain, DR1
        §1.2)."""
        return self._by_id.get(section_id, [])

    def by_id(self, section_id: str) -> Optional[SomMetaNode]:
        """The first node whose effective section id equals *section_id*.

        A *resolved list-item id* (a list's ``@SectionIdPattern`` with the
        ``xxx`` placeholder replaced by digits, e.g. ``GOAL-ITEM-3``) resolves
        to that list's element subtree. Returns ``None`` when nothing
        matches."""
        exact = self._by_id.get(section_id)
        if exact:
            return exact[0]
        for node in self._all_nodes:
            pattern = node.section_id_pattern
            if pattern is not None and _matches_pattern(pattern, section_id):
                return node.element_node or node
        return None

    # --- lookup by path ------------------------------------------------------

    def by_path(self, path: str) -> Optional[SomMetaNode]:
        """Resolves a document *path* (the §4 grammar: segments joined by
        ``/``, list items as ``-<seq>`` suffixes) to the metadata node it
        addresses, or ``None`` when the path does not describe a reachable
        position.

        A list-item segment (``<listSegment>-<seq>``) resolves to the list's
        element subtree; segments below it match the element class's fields.
        A list *container* path is only valid as the final segment (descending
        past a list requires an item suffix)."""
        segs = spec_path_segments(path)
        if not segs or segs[0] != self.root.segment:
            return None

        node = self.root
        for i in range(1, len(segs)):
            seg = segs[i]
            last = i == len(segs) - 1

            # Prefer an exact segment match; only then try a list-item suffix,
            # so a hyphenated @SectionId is never mis-read as an item.
            child = node.child_by_segment(seg)
            if child is not None:
                if child.kind is SomMetaKind.LIST and not last:
                    return None  # a list path needs a `-<seq>` item suffix
                if child.recursive and not last:
                    return None  # chains terminate at recursive re-entries
                node = child
                continue

            split = split_list_item_segment(seg)
            if split is None:
                return None
            list_node = node.child_by_segment(split.base)
            if list_node is None or list_node.kind is not SomMetaKind.LIST:
                return None
            element = list_node.element_node
            if element is None:
                # Scalar list without an element subtree: the item is a value
                # leaf.
                return list_node if last else None
            node = element
        return node


def _matches_pattern(pattern: str, id: str) -> bool:
    regex = (
        "^" + "[0-9]+".join(re.escape(p) for p in pattern.split("xxx")) + "$"
    )
    return re.match(regex, id) is not None


class SomMetaRef:
    """One position of the generated **dot-notation / ID-tree access
    surfaces** (DR1 §4): an absolute document :attr:`path` bound to the
    :attr:`tree` it belongs to.

    The generated facades (DR8) emit one accessor class per model class whose
    getters return further :class:`SomMetaRef` s. Every accessor exposes at
    least :attr:`path` and :attr:`meta` (the :class:`SomMetaNode` at that
    position). This base class is the leaf accessor itself
    (content/scalar/enum/form positions)."""

    def __init__(self, tree: SomMetaTree, path: str) -> None:
        #: The metadata tree of the document root this position belongs to.
        self.tree = tree
        #: The absolute document path of this position (§4 path grammar).
        self.path = path

    @property
    def meta(self) -> SomMetaNode:
        """The metadata node at :attr:`path`.

        Raises :class:`RuntimeError` when the path resolves to no node — only
        possible past a recursive re-entry, where the generated chain has
        ended and the metadata tree carries no further nodes (DR1 §4.1 cycle
        rule)."""
        node = self.tree.by_path(self.path)
        if node is None:
            raise RuntimeError(
                f'no metadata node at "{self.path}" — the position lies '
                "beyond a recursive re-entry; use the dynamic tree lookups "
                "instead"
            )
        return node


E = TypeVar("E")


class SomListMetaRef(SomMetaRef, Generic[E]):
    """The generated accessor for a **list** position (DR1 §4.1):
    :attr:`path` is the list container path; :meth:`item` returns the accessor
    for the *seq*-th item position (``<path>-<seq>``), whose children are the
    element class's accessors."""

    def __init__(
        self,
        tree: SomMetaTree,
        path: str,
        element: Callable[[SomMetaTree, str], E],
    ) -> None:
        super().__init__(tree, path)
        self._element = element

    def item(self, seq: int) -> E:
        """The accessor at the item position ``<path>-<seq>``."""
        return self._element(self.tree, list_item_path(self.path, seq))
