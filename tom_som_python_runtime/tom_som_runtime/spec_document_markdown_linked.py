"""Navigation between linked places of a rendition (SOM §11.2 qualified
anchors, SOM §11.11 the ``linked`` marker) — a port of
``tom_som_javascript_runtime/tom_som_runtime/spec_document_markdown_linked.js``
(itself a port of the TypeScript and Dart runtimes'
``spec_document_markdown_linked``).

Both are written from the model and the document's own values, and nothing of
either is stored: the parser removes the anchors and the marker.

Internal to :class:`~tom_som_runtime.spec_document_markdown.SpecDocumentMarkdown`.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Any, Optional

from .spec_links_validator import (
    spec_expand_pattern,
    spec_resolve_link_place,
    spec_resolve_place_at,
)
from .spec_meta import SomMetaKind, SomMetaNode, SomMetaTree
from .spec_model import SpecRoot, SpecSummaryOf, SpecSync
from .spec_notation import scan_notation
from .spec_paths import split_list_item_segment
from .spec_place import SpecPlaceFilter, spec_same_as_bindings
from .spec_reflection import SpecReflection
from .spec_section_id import effective_list_item_section_id

if TYPE_CHECKING:  # pragma: no cover
    from .spec_document import SpecDocument
    from .spec_document_markdown import SpecDocumentMarkdown

#: Written by the emitter where a markable place has no entry: replaced by
#: ``[]{.linked}`` when the value written after it begins with a ``linked``
#: span, else removed with its blank line (SOM §11.11).
K_LINKED_PLACEHOLDER = "\u0000linked\u0000"

# The roles a heading plays for its anchor's qualification (SOM §11.2).
ANCHOR_PLAIN = "plain"
ANCHOR_CONTAINER = "container"
ANCHOR_ITEM = "item"
ANCHOR_COPY = "copy"


def qualify_anchor(
    scope: Optional[list[str]], section: Optional[str], id: str, role: str
) -> tuple[str, Optional[list[str]]]:
    """The anchor of a heading *id* and the scope its descendants are
    qualified with (SOM §11.2): below a list item, and below a ``@SameAs``
    copy, a heading's anchor is the ``/``-joined ids from the outermost item
    (or from the copy's nearest enclosing section) down to it, list
    containers left out of the descendants' anchors. *scope* is the parent's
    scope, *section* the id of the nearest heading above that is no list
    container."""
    with_id: list[str] = []
    if scope is not None:
        with_id.extend(scope)
    elif role == ANCHOR_COPY and section is not None:
        with_id.append(section)
    with_id.append(id)
    if role == ANCHOR_COPY:
        return "/".join(with_id), with_id
    joined = id if scope is None else "/".join(with_id)
    if role == ANCHOR_CONTAINER:
        return joined, scope
    if role == ANCHOR_ITEM:
        return joined, with_id
    return joined, (None if scope is None else with_id)


@dataclass
class _Walk:
    """A path walked through a tree: the anchor and id of the heading it
    ends at, that heading's path, the path as a pattern (items ``<list>-*``),
    the items' ids on the way and the node reached (``None``: not reached)."""

    anchor: str
    heading_id: str
    heading_path: str
    pattern: str
    item_ids: list[str]
    node: Optional[SomMetaNode]


@dataclass
class _Side:
    """One side of a ``@SyncedWith`` pair: its anchor here, the other root,
    the anchor there, whether this side holds the values, the sync."""

    mine: str
    other: SpecRoot
    theirs: str
    holder: bool
    sync: SpecSync


def cut_pattern(path: str) -> str:
    """*path* cut before its first ``<list>-*`` segment, that list's path."""
    i = path.find("-*")
    return path if i < 0 else path[:i]


def _list_pattern_of(item_pattern: str) -> str:
    """An item pattern's list pattern (``a/L-*`` → ``a/L``)."""
    return item_pattern[:-2] if item_pattern.endswith("-*") else item_pattern


def _add_unique(out: list[str], v: str) -> None:
    if v not in out:
        out.append(v)


class Navigation:
    """One root's navigation: anchors, markable places and marker entries."""

    def __init__(self, codec: "SpecDocumentMarkdown", root: SpecRoot) -> None:
        self.codec = codec
        self.root = root
        self.refl = SpecReflection(codec.model)
        self.tree: SomMetaTree = codec._tree_for(root.type)
        self._walks: dict[str, _Walk] = {}
        self._sides: Optional[list[_Side]] = None
        self._same_as: Optional[list[Any]] = None
        self._detail_lists: Optional[dict[str, list[str]]] = None
        self._markable: dict[str, bool] = {}
        self._summary_links: Optional[dict[str, list[str]]] = None

    @property
    def model(self) -> Any:
        return self.codec.model

    @property
    def doc(self) -> "SpecDocument":
        return self.codec.document

    @property
    def root_seg(self) -> str:
        return self.refl.root_segment(self.root)

    # --- anchors -------------------------------------------------------------

    def is_copy(self, node: SomMetaNode) -> bool:
        """Whether *node* is a ``@SameAs`` copy (its member carries the
        annotation)."""
        return self.codec._is_copy_node(node)

    def item_id(
        self, d: Optional["SpecDocument"], list_node: SomMetaNode, item_path: str
    ) -> str:
        """The heading id of the item at *item_path* of *list_node* in *d*,
        as the emitter writes it."""
        slash = item_path.rfind("/")
        split = split_list_item_segment(item_path[slash + 1:])
        list_path = item_path[: slash + 1] + split.base
        pos = 0
        if d is not None:
            items = d.list_items(list_path)
            pos = items.index(item_path) + 1 if item_path in items else 0
        codec_cls = type(self.codec)
        return effective_list_item_section_id(
            stored_id=None if d is None else d.item_section_id(item_path),
            pattern=codec_cls._item_pattern_of(list_node),
            position=split.seq if pos == 0 else pos,
            fallback_stem=codec_cls._member_stem_of(list_node),
        )

    def walk(
        self,
        path: str,
        *,
        in_tree: Optional[SomMetaTree] = None,
        d: Optional["SpecDocument"] = None,
        ids: Optional[list[str]] = None,
    ) -> _Walk:
        """Walks *path* (concrete, or a pattern whose ``<list>-*`` segments
        take *ids* in order) through *in_tree*, the items' ids read from
        *d*."""
        t = in_tree if in_tree is not None else self.tree
        ids = ids or []
        cacheable = in_tree is None and not ids and d is self.doc
        if cacheable:
            hit = self._walks.get(path)
            if hit is not None:
                return hit
        codec = self.codec
        queue = list(ids)
        segs = path.split("/")
        node: SomMetaNode = t.root
        cur = segs[0]
        pattern = segs[0]
        anchor = node.segment
        heading_id = node.segment
        heading_path = cur
        scope: Optional[list[str]] = None
        section: Optional[str] = node.segment
        item_ids: list[str] = []
        reached: Optional[SomMetaNode] = node
        for i in range(1, len(segs)):
            seg = segs[i]
            child = node.child_by_segment(seg)
            if child is not None:
                cur = f"{cur}/{seg}"
                pattern = f"{pattern}/{seg}"
                node = child
                reached = child
                if codec._is_transparent_section(child) or codec._is_transparent_value(
                    child
                ):
                    continue
                id = codec._heading_id_of(child)
                container = child.kind == SomMetaKind.LIST
                role = (
                    ANCHOR_CONTAINER
                    if container
                    else (ANCHOR_COPY if self.is_copy(child) else ANCHOR_PLAIN)
                )
                anchor, scope = qualify_anchor(scope, section, id, role)
                heading_id = id
                heading_path = cur
                if not container:
                    section = id
                continue
            star = seg.endswith("-*")
            if star:
                base: Optional[str] = seg[:-2]
            else:
                split = split_list_item_segment(seg)
                base = None if split is None else split.base
            list_node = None if base is None else node.child_by_segment(base)
            if list_node is None or list_node.kind != SomMetaKind.LIST:
                reached = None
                break
            item_path = f"{cur}/{seg}"
            if star:
                id = queue.pop(0) if queue else ""
            else:
                id = self.item_id(d, list_node, item_path)
            item_ids.append(id)
            anchor, scope = qualify_anchor(scope, section, id, ANCHOR_ITEM)
            heading_id = id
            section = id
            cur = item_path
            heading_path = item_path
            pattern = f"{pattern}/{base}-*"
            element = list_node.element_node
            node = element if element is not None else list_node
            reached = node
            if element is None and i < len(segs) - 1:
                reached = None
                break
        w = _Walk(anchor, heading_id, heading_path, pattern, item_ids, reached)
        if cacheable:
            self._walks[path] = w
        return w

    def anchor_of(self, path: str) -> str:
        """The anchor of the heading *path* names in this document."""
        return self.walk(path, d=self.doc).anchor

    # --- the model's links, per root -----------------------------------------

    @property
    def sides(self) -> list[_Side]:
        """Every ``@SyncedWith`` pair this root is a side of."""
        if self._sides is not None:
            return self._sides
        out: list[_Side] = []
        self._sides = out
        bp, pairs = self.codec._sync_pairs
        if bp is None:
            return out

        def root_of(type_: str) -> Optional[SpecRoot]:
            return next((r for r in self.model.roots if r.type == type_), None)

        for p in pairs:
            sync = p.sync
            if sync is None:
                continue
            if self.root.type == bp:
                other = root_of(p.detail_root)
                if other is None:
                    continue
                out.append(
                    _Side(p.blueprint_anchor, other, p.detail_anchor, False, sync)
                )
            elif self.root.type == p.detail_root:
                other = root_of(bp)
                if other is None:
                    continue
                out.append(
                    _Side(p.detail_anchor, other, p.blueprint_anchor, True, sync)
                )
        return out

    @property
    def same_as(self) -> list[Any]:
        """The ``@SameAs`` copies of this root with their holders."""
        if self._same_as is None:
            self._same_as = spec_same_as_bindings(self.refl, self.root.type)
        return self._same_as

    def _under_copy(self, pattern: str) -> bool:
        return any(
            pattern == b.copy_path or pattern.startswith(f"{b.copy_path}/")
            for b in self.same_as
        )

    def shared_list_side(
        self, list_pattern: str, concrete_list: str
    ) -> Optional[_Side]:
        """The side whose shared list *list_pattern* is: the innermost pair
        anchor holding it, when the list lies directly beneath it (not below
        an item of it), outside a copy and outside the pair's ``detailOnly``
        places."""
        if self._under_copy(list_pattern):
            return None
        best: Optional[_Side] = None
        for s in self.sides:
            if not list_pattern.startswith(f"{s.mine}/"):
                continue
            if best is None or len(s.mine) > len(best.mine):
                best = s
        if best is None:
            return None
        rel = list_pattern[len(best.mine) + 1:]
        if "-*" in rel:
            return None
        # The anchor's concrete path: the list's as long as the anchor is.
        depth = len(best.mine.split("/"))
        anchor = "/".join(concrete_list.split("/")[:depth])
        for place in best.sync.detail_only:
            r = spec_resolve_place_at(self.refl, place, anchor)
            if r is None:
                continue
            p = self.walk(r.path, d=self.doc).pattern
            if list_pattern == p or list_pattern.startswith(f"{p}/"):
                return None
        return best

    def summary_of_list(self, list_path: str) -> Optional[SpecSummaryOf]:
        """The ``@SummaryOf`` of the list member at *list_path*, if any."""
        r = self.refl.resolve(list_path)
        if r is None or r.field is None:
            return None
        return r.field.summary_of

    def _same_document(self, s: SpecSummaryOf) -> bool:
        """Whether a summary names its detail elements in this document."""
        return s.document is None or s.document == self.root.type

    @property
    def detail_lists(self) -> dict[str, list[str]]:
        """Detail-list pattern → the summary lists (patterns) of this
        document naming its elements."""
        if self._detail_lists is not None:
            return self._detail_lists
        out: dict[str, list[str]] = {}
        for n in self.tree.all_nodes:
            np = n.path
            if n.kind != SomMetaKind.LIST or np is None:
                continue
            s = self.summary_of_list(np)
            if s is None or not self._same_document(s):
                continue
            owner = np[: np.rfind("/")]
            r = spec_resolve_link_place(self.refl, None, s.detail, self.root_seg, owner)
            if r is None:
                continue
            key = self.walk(cut_pattern(r.path), d=self.doc).pattern
            out.setdefault(key, []).append(np)
        self._detail_lists = out
        return out

    # --- markable places (structural: the parser and the emitter agree) -----

    def markable(self, path: str) -> bool:
        """Whether the heading at *path* carries one of the links of
        SOM §11.11: a ``@SyncedWith`` anchor or an element of one of its
        shared lists, an element of a summary list or of a detail list a
        summary of this document names, a heading holding a derived value, a
        list of link rows extracted from text, a ``@SameAs`` copy or its
        holder."""
        v = self._markable.get(path)
        if v is None:
            v = self._compute_markable(path)
            self._markable[path] = v
        return v

    def _compute_markable(self, path: str) -> bool:
        w = self.walk(path, d=self.doc)
        node = w.node
        if node is None or w.heading_path != path:
            return False
        pattern = w.pattern
        if any(s.mine == pattern for s in self.sides):
            return True
        item = self.item_parts(path)
        if item is not None:
            list_pattern = _list_pattern_of(pattern)
            if self.shared_list_side(list_pattern, item[0]) is not None:
                return True
            if self.summary_of_list(item[0]) is not None:
                return True
            if list_pattern in self.detail_lists:
                return True
        if self._derived_sources(path, node, probe=True):
            return True
        if node.kind == SomMetaKind.LIST and self._extract_from(path):
            return True
        if any(b.copy_path == pattern or b.holder_path == pattern for b in self.same_as):
            return True
        return False

    def item_parts(self, path: str) -> Optional[tuple[str, str]]:
        """For an item path, (its list's path, its segment); ``None``
        otherwise."""
        slash = path.rfind("/")
        if slash < 0:
            return None
        seg = path[slash + 1:]
        split = split_list_item_segment(seg)
        if split is None:
            return None
        parent = path[:slash]
        node = self.tree.by_path(parent)
        if node is not None and node.child_by_segment(seg) is not None:
            return None
        list_path = f"{parent}/{split.base}"
        list_node = self.tree.by_path(list_path)
        if list_node is None or list_node.kind != SomMetaKind.LIST:
            return None
        return list_path, seg

    # --- the marker ------------------------------------------------------------

    def _link(self, id: str, anchor: str, other: Optional[SpecRoot] = None) -> str:
        """A link to *anchor* in *other* (``None``: this document), its text
        *id* prefixed by the other root's id."""
        if other is None:
            return f"[{id}](#{anchor})"
        file = self.codec._file_of_root(other)
        name = other.section_id if other.section_id is not None else other.type
        return f"[{name} {id}]({file}#{anchor})"

    def entries(self, path: str, section_table: bool = False) -> list[str]:
        """The marker's entries at the heading *path*, in the order of
        SOM §11.11; empty when *path* is not markable or carries no link this
        time. *section_table*: the heading's children are written as a
        section table."""
        if not self.markable(path):
            return []
        w = self.walk(path, d=self.doc)
        node = w.node
        assert node is not None
        pattern = w.pattern
        out: list[str] = []

        # Also in (@SyncedWith).
        def note(s: _Side) -> str:
            held = "held here" if s.holder else "held there"
            if not s.sync.held_here:
                return held
            return f"{held} except {', '.join(s.sync.held_here)}"

        for s in self.sides:
            if s.mine != pattern:
                continue
            there = self.walk(
                s.theirs, in_tree=self.codec._tree_for(s.other.type), ids=w.item_ids
            )
            out.append(
                f"Also in {self._link(w.heading_id, there.anchor, s.other)}, {note(s)}"
            )
        item = self.item_parts(path)
        if item is not None:
            list_pattern = _list_pattern_of(pattern)
            side = self.shared_list_side(list_pattern, item[0])
            if side is not None:
                rel = list_pattern[len(side.mine):]
                there = self.walk(
                    f"{side.theirs}{rel}-*",
                    in_tree=self.codec._tree_for(side.other.type),
                    ids=w.item_ids,
                )
                out.append(
                    f"Also in {self._link(w.heading_id, there.anchor, side.other)}, "
                    f"{note(side)}"
                )

            # Summary of (@SummaryOf on the list).
            summary = self.summary_of_list(item[0])
            if summary is not None:
                links = [
                    self._link(id, anchor, other)
                    for id, anchor, other in self.summary_targets(
                        path, item[0], w.heading_id, summary
                    )
                ]
                if links:
                    out.append(f"Summary of {', '.join(links)}")

            # Summarised in: the summary elements of this document naming it.
            named = self.summary_links.get(f"{item[0]}#{w.heading_id}")
            if named is not None:
                out.append(f"Summarised in {', '.join(named)}")

        # Derived from.
        derived = self._derived_sources(path, node, section_table=section_table)
        if derived:
            dlinks: list[str] = []
            fields: list[str] = []
            for link, field in derived:
                if link is not None:
                    _add_unique(dlinks, link)
                if field is not None:
                    _add_unique(fields, field)
            if dlinks:
                out.append(
                    f"Derived from {', '.join(dlinks)}"
                    + ("" if not fields else f": {', '.join(fields)}")
                )

        # Extracted from (@ExtractsLinks, generate).
        if node.kind == SomMetaKind.LIST:
            frm = self._extract_from(path)
            if frm:
                out.append(f"Extracted from {', '.join(frm)}")

        # Copy of / Copied to (@SameAs).
        for b in self.same_as:
            if b.copy_path != pattern or b.holder_path is None:
                continue
            h = self.walk(b.holder_path, d=self.doc, ids=w.item_ids)
            out.append(f"Copy of {self._link(h.heading_id, h.anchor)}, edit it there")
        copies = [b for b in self.same_as if b.holder_path == pattern]
        if copies:
            parts = []
            for b in copies:
                c = self.walk(b.copy_path, d=self.doc, ids=w.item_ids)
                parts.append(self._link(c.heading_id, c.anchor))
            out.append(f"Copied to {', '.join(parts)}")
        return out

    @property
    def summary_links(self) -> dict[str, list[str]]:
        """``<detail list path>#<element id>`` → the links to the summary
        elements of this document naming that element, in document order."""
        if self._summary_links is not None:
            return self._summary_links
        out: dict[str, list[str]] = {}
        summaries: list[str] = []
        for lists in self.detail_lists.values():
            for lst in lists:
                _add_unique(summaries, lst)
        doc = self.doc
        for summary_list in summaries:
            for concrete in spec_expand_pattern(doc, summary_list):
                s = self.summary_of_list(concrete)
                if s is None:
                    continue
                owner = concrete[: concrete.rfind("/")]
                r = spec_resolve_link_place(self.refl, doc, s.detail, self.root_seg, owner)
                if r is None:
                    continue
                detail = cut_pattern(r.path)
                for e in doc.list_items(concrete):
                    ew = self.walk(e, d=doc)
                    for id in self._summary_ids(e, s, ew.heading_id):
                        links = out.setdefault(f"{detail}#{id}", [])
                        _add_unique(links, self._link(ew.heading_id, ew.anchor))
        self._summary_links = out
        return out

    def _summary_ids(self, element: str, s: SpecSummaryOf, own_id: str) -> list[str]:
        """The ids summary element *element* names: its ``match`` field's
        ids, else its own *own_id*."""
        match = s.match
        if match is None:
            return [own_id]
        r = spec_resolve_place_at(self.refl, match, element)
        if r is None or r.field is None:
            return []
        raw = self.doc.form_field(r.path, r.field)
        if raw is None:
            return []
        return [i for i in (_js_trim(x) for x in raw.split(",")) if i != ""]

    def summary_targets(
        self, element: str, list_path: str, own_id: str, s: SpecSummaryOf
    ) -> list[tuple[str, str, Optional[SpecRoot]]]:
        """The detail elements summary element *element* of *list_path*
        names: each id, its anchor and the other root it is in (``None``:
        this document)."""
        ids = self._summary_ids(element, s, own_id)
        if not ids:
            return []
        owner = list_path[: list_path.rfind("/")]
        if self._same_document(s):
            r = spec_resolve_link_place(self.refl, self.doc, s.detail, self.root_seg, owner)
            if r is None:
                return []
            lst = cut_pattern(r.path)
            return [
                (id, self.walk(f"{lst}-*", d=self.doc, ids=[id]).anchor, None)
                for id in ids
            ]
        other = next((r for r in self.model.roots if r.type == s.document), None)
        if other is None:
            return []
        other_seg = self.refl.root_segment(other)
        r = spec_resolve_link_place(self.refl, None, s.detail, other_seg, other_seg)
        out: list[tuple[str, str, Optional[SpecRoot]]] = []
        for id in ids:
            if r is None or "-*" in r.path:
                anchor = id
            else:
                anchor = self.walk(
                    f"{r.path}-*", in_tree=self.codec._tree_for(other.type), ids=[id]
                ).anchor
            out.append((id, anchor, other))
        return out

    def summary_id_cell(self, item: str, list_path: str, id: str) -> Optional[str]:
        """The ``Id`` cell of a records row standing for summary element
        *item* of *list_path* whose ``@SummaryOf`` has no ``match``
        (SOM §11.5, §11.11): its anchor, then its id as a link to the detail
        element it names. ``None`` when the list is no such summary."""
        s = self.summary_of_list(list_path)
        if s is None or s.match is not None:
            return None
        targets = self.summary_targets(item, list_path, id, s)
        if not targets:
            return None
        if len(targets) != 1:
            raise RuntimeError("Bad state: Too many elements")
        _, anchor, other = targets[0]
        href = (
            f"#{anchor}"
            if other is None
            else f"{self.codec._file_of_root(other)}#{anchor}"
        )
        return f'<a id="{self.anchor_of(item)}"></a>[{id}]({href})'

    def _derived_sources(
        self,
        path: str,
        node: SomMetaNode,
        *,
        probe: bool = False,
        section_table: bool = False,
    ) -> list[tuple[Optional[str], Optional[str]]]:
        """The derived values at the heading *path*: (a link to a source, or
        ``None``; the derived field's name, or ``None`` for a derived
        section) per source. *probe*: answer whether there is any,
        structurally (no links built)."""
        doc = self.doc
        codec = self.codec
        out: list[tuple[Optional[str], Optional[str]]] = []

        def link_to(target: str) -> str:
            t = self.walk(cut_pattern(target), d=doc)
            return self._link(t.heading_id, t.anchor)

        def source(place: str, owner: str) -> Optional[str]:
            if probe:
                return None
            r = spec_resolve_link_place(self.refl, doc, place, self.root_seg, owner)
            return None if r is None else link_to(r.path)

        def form(form_path: str, prefix: Optional[str]) -> None:
            owner = form_path[: form_path.rfind("/")]
            res = self.refl.resolve(form_path)
            spec = res.field if res is not None else None
            ffs = spec.form_fields if spec is not None else []
            for ff in ffs:
                name = ff.name if prefix is None else f"{prefix}.{ff.name}"
                d = ff.derived_from
                if d is not None:
                    out.append((source(d.source, owner), name))
                for t in ff.count_of:
                    f = SpecPlaceFilter.try_parse(t)
                    if f is None:
                        continue
                    out.append(
                        (source(f"./{f.section_id}" if f.scoped else f.section_id, owner), name)
                    )
                for operand in ff.product_of:
                    dot = operand.find(".")
                    out.append(
                        (
                            None
                            if probe
                            else link_to(
                                form_path if dot < 0 else f"{owner}/{operand[:dot]}"
                            ),
                            name,
                        )
                    )
                if ff.rank_of is not None:
                    item = self.item_parts(owner)
                    out.append(
                        (
                            None if probe else link_to(item[0] if item is not None else form_path),
                            name,
                        )
                    )

        # A member carrying `@DerivedFrom`: `name` for one written in its
        # owner's body (no heading of its own), None for the heading itself.
        def member(member_path: str, name: Optional[str]) -> None:
            res = self.refl.resolve(member_path)
            d = res.field.derived_from if res is not None and res.field is not None else None
            if d is None:
                return
            owner = member_path[: member_path.rfind("/")]
            out.append((source(d.source, owner), name))

        is_item = self.item_parts(path) is not None
        if node.kind == SomMetaKind.FORM:
            form(path, None)
        if not is_item and "/" in path:
            member(path, None)
        if node.kind in (SomMetaKind.SECTION, SomMetaKind.COMPLEX) or is_item:
            for slot, rel in codec._body_slots(node):
                slot_path = f"{path}/{rel}"
                if slot.kind == SomMetaKind.FORM:
                    form(slot_path, None)
                else:
                    member(slot_path, slot.member_name or slot.segment)
            if section_table or probe:
                for child, rel in codec._effective_children(node):
                    if child.kind != SomMetaKind.FORM:
                        continue
                    if probe or doc.has_values_under(f"{path}/{rel}"):
                        form(f"{path}/{rel}", codec._heading_id_of(child))
        return out

    def _extract_from(self, path: str) -> list[str]:
        """The ``Extracted from`` links of the link-row list at *path*: the
        text places of its ``@ExtractsLinks`` in ``generate`` mode."""
        res = self.refl.resolve(path)
        f = res.field if res is not None else None
        if f is None:
            return []
        owner = path[: path.rfind("/")]
        out: list[str] = []
        for e in f.extracts_links:
            if e.mode != "generate":
                continue
            for place in e.from_:
                r = spec_resolve_link_place(self.refl, self.doc, place, self.root_seg, owner)
                if r is None:
                    continue
                t = self.walk(cut_pattern(r.path), d=self.doc)
                _add_unique(out, self._link(t.heading_id, t.anchor))
        return out


def _utf16_len(text: str) -> int:
    return len(text.encode("utf-16-le")) // 2


# The whitespace JavaScript's `trim()` knows, which the reference decides by
# (Python's own `str.strip` knows more).
_JS_WS_CHARS = (
    "\t\n\x0b\f\r \u00a0\u1680\u2000\u2001\u2002\u2003\u2004\u2005"
    "\u2006\u2007\u2008\u2009\u200a\u2028\u2029\u202f\u205f\u3000\ufeff"
)


def _js_trim(s: str) -> str:
    return s.strip(_JS_WS_CHARS)


def is_linked_paragraph(paragraph: str) -> bool:
    """Whether *paragraph* is exactly one span of kind ``linked``."""
    text = _js_trim(paragraph)
    if not text.startswith("[") or not text.endswith("{.linked}"):
        return False
    scan = scan_notation(text)
    if len(scan.elements) != 1:
        return False
    e = scan.elements[0]
    return (
        e.type == "span"
        and e.kind == "linked"
        and e.start == 0
        and e.end == _utf16_len(text)
    )


def resolve_linked_placeholders(markdown: str) -> str:
    """*markdown* with every placeholder resolved: ``[]{.linked}`` where the
    paragraph after it is a ``linked`` span, else removed with its blank
    line."""
    if K_LINKED_PLACEHOLDER not in markdown:
        return markdown
    lines = markdown.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        if lines[i] != K_LINKED_PLACEHOLDER:
            out.append(lines[i])
            i += 1
            continue
        # The placeholder, its blank line, then the paragraph that follows.
        k = i + 1
        while k < len(lines) and _js_trim(lines[k]) == "":
            k += 1
        para: list[str] = []
        j = k
        while j < len(lines) and _js_trim(lines[j]) != "":
            para.append(lines[j])
            j += 1
        if para and is_linked_paragraph("\n".join(para)):
            out.append("[]{.linked}")
            i += 1
        else:
            i += 2  # the blank line after the placeholder goes with it
    return "\n".join(out)
