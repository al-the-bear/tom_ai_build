"""Generated parts of a rendition (SOM §11.12): tables the rendition derives
completely from the links of a document, written at the start of the section
they belong to as a ``derived`` block and read back as nothing — a port of
``tom_som_javascript_runtime/tom_som_runtime/spec_document_markdown_generated.js``
(itself a port of the TypeScript and Dart runtimes'
``spec_document_markdown_generated``).

Internal to :class:`~tom_som_runtime.spec_document_markdown.SpecDocumentMarkdown`.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Optional

from .spec_links_validator import spec_resolve_place_at
from .spec_meta import SomMetaKind, SomMetaNode
from .spec_document_markdown_linked import Navigation, _js_trim

if TYPE_CHECKING:  # pragma: no cover
    from .spec_document_markdown import SpecDocumentMarkdown

#: Written by the emitter at a generated place without a table: replaced by
#: an empty ``derived`` block when the value written after it begins with a
#: ``derived`` block, else removed with its blank line (SOM §11.12).
K_DERIVED_PLACEHOLDER = "\u0000derived\u0000"

#: The requirement classes whose elements are the rows of the requirement
#: views: every element ``INTR.relatedRequirements`` may name.
_REQUIREMENT_CLASSES = ("FRE", "TERQ", "SECRQ", "ORRQ")


@dataclass(frozen=True)
class _Column:
    """A column of a generated table: its header, the place its cells read
    (``None``: the row's id), whether it says only ``yes`` / ``no``."""

    header: str
    place: Optional[str] = None
    covered: bool = False


@dataclass(frozen=True)
class _Table:
    """A generated table: the section ids it opens, its label, the classes of
    its rows, the classes the row's id is taken from (empty: the row's own),
    its columns."""

    at: tuple[str, ...]
    label: str
    rows: tuple[str, ...]
    columns: tuple[_Column, ...]
    owner: tuple[str, ...] = field(default=())


#: The generated tables (SOM §11.12): the requirement views of
#: DP-part-model-links-5 / -11 (D1–D4) where the links hold a table.
_GENERATED_TABLES = (
    _Table(
        at=("RSP-TRAC", "RO-TRAC"),
        label="Generated from each requirement's traceability; edit it there",
        rows=_REQUIREMENT_CLASSES,
        columns=(
            _Column("Requirement"),
            _Column("Use cases", "RT-TRAC.relatedUseCases"),
            _Column("Screens", "RETRAR.relatedScreens"),
            _Column("Data entities", "RETRAR.relatedDataEntities"),
            _Column("Tests", "RETRAR.relatedTestCases"),
        ),
    ),
    _Table(
        at=("REQCOV",),
        label="Generated from each requirement's test cases; edit them there",
        rows=_REQUIREMENT_CLASSES,
        columns=(
            _Column("Requirement"),
            _Column("Covered", "RETRAR.relatedTestCases", covered=True),
            _Column("By", "RETRAR.relatedTestCases"),
        ),
    ),
    _Table(
        at=("RERE-REQU-LST",),
        label="Generated from each requirement's dependencies; edit them there",
        rows=("RQDEP",),
        owner=_REQUIREMENT_CLASSES,
        columns=(
            _Column("Requirement"),
            _Column("Dependency", "RQDEP.dependencyType"),
            _Column("Related requirement", "RQDEP-RELA-REF.ref"),
        ),
    ),
    _Table(
        at=("USCATR",),
        label="Generated from each use case's traceability; edit it there",
        rows=("INEN",),
        columns=(
            _Column("Use case"),
            _Column("Process", "INTR.relatedProcess"),
            _Column("Requirements", "INTR.relatedRequirements"),
            _Column("Tests", "INTR.relatedTestCases"),
        ),
    ),
)


def _generated_table_at(id: str) -> Optional[_Table]:
    """The generated table opening a heading with section id *id*, if any."""
    for t in _GENERATED_TABLES:
        if id in t.at:
            return t
    return None


class Generated:
    """One root's generated parts."""

    def __init__(self, nav: Navigation) -> None:
        self.nav = nav
        self._blocks: Optional[dict[str, list[str]]] = None
        self._items_cache: Optional[list[str]] = None

    @property
    def codec(self) -> "SpecDocumentMarkdown":
        return self.nav.codec

    @property
    def doc(self):  # noqa: ANN201 - SpecDocument
        return self.nav.doc

    def is_place(self, path: str) -> bool:
        """Whether the heading at *path* is a generated place (structural:
        its section id opens a generated table)."""
        node = self.nav.tree.by_path(path)
        if node is None or self.nav.walk(path, d=self.doc).heading_path != path:
            return False
        return _generated_table_at(self.codec._heading_id_of(node)) is not None

    @property
    def blocks(self) -> dict[str, list[str]]:
        """The blocks of this document, by heading path: only the places
        whose table has rows."""
        if self._blocks is not None:
            return self._blocks
        out: dict[str, list[str]] = {}
        codec = self.codec
        for n in self.nav.tree.all_nodes:
            path = n.path
            if path is None:
                continue
            if codec._is_transparent_section(n) or codec._is_transparent_value(n):
                continue
            table = _generated_table_at(codec._heading_id_of(n))
            if table is None:
                continue
            block = self._block(table)
            if block is not None:
                out[path] = block
        self._blocks = out
        return out

    def forces(self, path: str) -> bool:
        """Whether a generated block stands at or beneath *path*, so the
        heading is written even when the document holds no value there."""
        for p in self.blocks:
            if p == path or p.startswith(f"{path}/"):
                return True
        return False

    @property
    def _items(self) -> list[str]:
        """Every element of the document, in rendition order."""
        if self._items_cache is not None:
            return self._items_cache
        out: list[str] = []
        doc = self.doc
        codec = self.codec

        def walk(node: SomMetaNode, path: str) -> None:
            for child, rel in codec._effective_children(node):
                p = f"{path}/{rel}"
                if not doc.has_values_under(p):
                    continue
                if child.kind == SomMetaKind.LIST:
                    for item in doc.list_items(p):
                        out.append(item)
                        element = child.element_node
                        if element is not None and not element.recursive:
                            walk(element, item)
                elif child.kind in (SomMetaKind.SECTION, SomMetaKind.COMPLEX):
                    walk(child, p)

        walk(self.nav.tree.root, self.nav.root_seg)
        self._items_cache = out
        return out

    def _class_id(self, item: str) -> Optional[str]:
        r = self.nav.refl.resolve(item)
        if r is None or r.target_class is None:
            return None
        return r.target_class.section_id

    def _block(self, table: _Table) -> Optional[list[str]]:
        """The block lines of *table*, or ``None`` when it has no row."""
        rows: list[list[str]] = []
        doc = self.doc
        for item in self._items:
            class_id = self._class_id(item)
            if class_id is None or class_id not in table.rows:
                continue
            cells: list[str] = []
            for c in table.columns:
                if c.place is None:
                    cells.append(self._id_cell(self._row_owner(item, table)))
                    continue
                r = spec_resolve_place_at(self.nav.refl, c.place, item)
                fld = None if r is None else r.field
                raw: Optional[str] = None
                if r is not None and fld is not None:
                    v = doc.form_field(r.path, fld)
                    raw = None if v is None else _js_trim(v)
                value = None if raw is None or raw == "" else raw
                if c.covered:
                    cells.append("no" if value is None else "yes")
                    continue
                if value is None:
                    cells.append("")
                    continue
                assert r is not None
                meta = None
                form_node = self.nav.tree.by_path(r.path)
                if form_node is not None and form_node.form is not None:
                    meta = next(
                        (f for f in form_node.form.fields if f.name == fld), None
                    )
                cells.append(
                    value.replace("|", "\\|")
                    if meta is None
                    else self.codec._linked_cell_text(meta, value)
                )
            rows.append(cells)
        if not rows:
            return None
        return [
            f'::: {{.derived label="{table.label}"}}',
            "| " + " | ".join(c.header for c in table.columns) + " |",
            "| " + " | ".join("---" for _ in table.columns) + " |",
            *("| " + " | ".join(r) + " |" for r in rows),
            ":::",
        ]

    def _row_owner(self, item: str, table: _Table) -> Optional[str]:
        """The element a row names: itself, or its nearest owner of the
        table's ``owner``."""
        if not table.owner:
            return item
        p = item
        while "/" in p:
            p = p[: p.rfind("/")]
            if self.nav.item_parts(p) is not None:
                id = self._class_id(p)
                if id is not None and id in table.owner:
                    return p
        return None

    def _id_cell(self, item: Optional[str]) -> str:
        """A link to the element at *item* by its id and anchor."""
        if item is None:
            return ""
        w = self.nav.walk(item, d=self.doc)
        return f"[{w.heading_id}](#{w.anchor})"


_OPENS_DERIVED = re.compile(r"^ {0,3}:{3,}[ \t]*\{\.derived(?=[\s}])")
_DERIVED_FENCE = re.compile(r"^ {0,3}(:{3,})")


def opens_derived(line: str) -> bool:
    """Whether *line* opens a ``derived`` block."""
    return _OPENS_DERIVED.search(line) is not None


def derived_fence_close(line: str) -> "re.Pattern[str]":
    """The closing line pattern of the ``derived`` block *line* opens."""
    m = _DERIVED_FENCE.search(line)
    assert m is not None
    return re.compile(r"^ {0,3}:{" + str(len(m.group(1))) + r",}[ \t]*$")


def resolve_derived_placeholders(markdown: str) -> str:
    """*markdown* with every derived placeholder resolved: an empty
    ``derived`` block where the block after it opens a ``derived`` block,
    else removed with its blank line."""
    if K_DERIVED_PLACEHOLDER not in markdown:
        return markdown
    lines = markdown.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        if lines[i] != K_DERIVED_PLACEHOLDER:
            out.append(lines[i])
            i += 1
            continue
        k = i + 1
        while k < len(lines) and _js_trim(lines[k]) == "":
            k += 1
        if k < len(lines) and opens_derived(lines[k]):
            out.append("::: {.derived}")
            out.append(":::")
            i += 1
        else:
            i += 2  # the blank line after the placeholder goes with it
    return "\n".join(out)
