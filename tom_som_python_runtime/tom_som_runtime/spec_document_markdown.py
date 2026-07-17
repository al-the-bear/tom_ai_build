"""DocSpecs-conform Markdown codec for a TomSpecs document (DR1 §1) — a
faithful port of ``tom_som_dart_runtime/lib/src/spec_document_markdown.dart``.

The generated/authored ``*.md`` **is a genuine DocSpecs document**: line 1 is
the ``<!-- docspec: <schema-id>/<version> -->`` declaration, every populated
section is one markdown heading whose machine-readable identity is the DocSpecs
headline comment ``<!--[SECTION-ID]-->`` and whose text is the section's
**stored headline** when one exists, else the human-readable Title-Case member
name (YRD3: md is a full-fidelity format — stored headlines round-trip).
Content values are **normal markdown text** under their heading (no fences, no
anchors); ``@Form`` sections use the DocSpecs plain-text ``FieldName: value``
format; a list emits its ``-LST`` **container heading** (the id the DR3 schema
keys its container type by), with the numbered items one level deeper, each
carrying the item's **stored section id** when one exists (an AA1 date-lettered
generated id or a criterion-5 override), else the anonymous positional id — the
``@SectionIdPattern`` resolved with the 1-based position (``GOAL-ITEM-xxx`` →
``GOAL-ITEM-1``), else ``<member>-<pos>`` for a pattern-less list. The container
carries no content of its own. On parse, anonymous positional ids recover list
membership and order from position; stored ids are kept as stored ids (YRD3,
superseding DRC5's yaml-only rule — see som_mapping.md §8.5).
Id-less members are **transparent** (mirroring the DR3 schema generator):
a transparent value member's text or form block is the owner's body region,
emitted without a heading and bound at its own path; a transparent
section/complex member never heads — its id-bearing descendants hoist to the
owner's child level (paths keep the transparent segments). Section/complex
headings without a field-level ``@SectionId`` carry the target class's
``@SectionId``.

Escaping (DR1 §1.3): a content line starting with ``#`` at column 0 is emitted
as ``\\#`` (and a leading ``\\#``… run gains one more backslash), except inside
fenced code blocks, which shield their lines verbatim. Consecutive blank lines
are collapsed to one on emit; parse trims each value of leading/trailing blank
lines and does not re-collapse.

The codec is free of any UI: it reads from / resolves against a
:class:`SpecModel` (through the :func:`build_som_meta_tree` metadata tree) and
a :class:`SpecDocument`. :meth:`SpecDocumentMarkdown.parse` does **not** mutate
the document — it returns staged values keyed exactly like
:meth:`SpecDocument.to_json` plus a rejection report; the caller applies them.
Anything that cannot be mapped — an unknown section id, a child heading under a
value leaf, orphaned text — is collected into
:attr:`SpecMarkdownResult.rejections` rather than dropped (DR1 §1.7).
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field as dataclass_field
from enum import Enum
from typing import Any, Optional

from .spec_document import SpecDocument
from .spec_meta import SomMetaKind, SomMetaNode, SomMetaTree
from .spec_meta_bridge import build_som_meta_tree
from .spec_model import SpecModel, SpecRoot


class SpecMarkdownRejectReason(Enum):
    """Why an imported Markdown block was rejected (DR1 §1.7 rejection
    protocol)."""

    #: The heading's section id does not resolve against the schema tree at
    #: its nesting position.
    UNKNOWN_SECTION = "unknownSection"
    #: A structurally impossible combination — e.g. a child heading nested
    #: under a value-leaf (content/scalar/enum) section.
    KIND_MISMATCH = "kindMismatch"
    #: Body text with no owning value slot — e.g. prose inside a ``@Form``
    #: section before the first ``FieldName:`` line.
    ORPHAN_CONTENT = "orphanContent"
    #: A value-leaf section heading with an empty body.
    MISSING_VALUE = "missingValue"
    #: A heading line without a parseable ``<!--[id]-->`` headline comment.
    MALFORMED_HEADING = "malformedHeading"
    #: A ``FieldName:`` form line for a title/id **role field** (YRD6): the
    #: field's value is the section heading / id comment and must never be
    #: duplicated as a form line.
    ROLE_FIELD_FORM_LINE = "roleFieldFormLine"


@dataclass
class SpecMarkdownRejection:
    """One rejected block in a Markdown import (DR1 §1.7). Reported, never
    silently dropped: each carries the source :attr:`line`, the offending
    :attr:`anchor` (section path or id), the :attr:`reason`, and a
    human-readable :attr:`message`."""

    line: int
    reason: SpecMarkdownRejectReason
    message: str
    anchor: Optional[str] = None

    def __str__(self) -> str:
        anchor = f" ({self.anchor})" if self.anchor is not None else ""
        return f"line {self.line}: {self.reason.value}{anchor} — {self.message}"


@dataclass
class SpecMarkdownResult:
    """The outcome of parsing a Markdown document (DR1 §1.7): the staged values
    plus every rejected block. The values are keyed exactly like
    :meth:`SpecDocument.to_json` so a caller can merge them into a live
    document as a full overwrite of the covered scope."""

    #: Content/scalar/enum leaf values (and section body text): path → value.
    content: dict[str, str] = dataclass_field(default_factory=dict)
    #: Form values: form path → (field name → value).
    forms: dict[str, dict[str, str]] = dataclass_field(default_factory=dict)
    #: List membership: list path → ``{seq, items, ids?}`` (the
    #: :meth:`SpecDocument.to_json` shape), recovered from the item headings.
    lists: dict[str, dict[str, Any]] = dataclass_field(default_factory=dict)
    #: Stored headlines (YRD3): path → heading text, staged only when the
    #: parsed heading text differs from the effective default title (keeping
    #: untouched documents byte-stable).
    headlines: dict[str, str] = dataclass_field(default_factory=dict)
    #: Every rejected block, in source order.
    rejections: list[SpecMarkdownRejection] = dataclass_field(
        default_factory=list
    )
    #: The root segment(s) the import covers (the first segment of each
    #: accepted path) — the scope a full-overwrite apply purges before writing.
    root_prefixes: set[str] = dataclass_field(default_factory=set)

    @property
    def is_clean(self) -> bool:
        """Whether the parse was clean (no rejections)."""
        return not self.rejections

    @property
    def applied_count(self) -> int:
        """The number of leaf values successfully parsed (content + form
        fields)."""
        return len(self.content) + sum(len(m) for m in self.forms.values())


class MarkdownFenceTracker:
    """Fence state machine (CommonMark-ish): a line whose first non-space run
    (up to 3 spaces indent) is 3+ backticks or tildes opens a fence; a matching
    same-character run at least as long closes it.

    Public so other markdown-processing modules (the DocSpecs validator's
    generic parser) share exactly the same fence semantics as this codec."""

    _OPEN = re.compile(r"^ {0,3}(`{3,}|~{3,})")

    def __init__(self) -> None:
        self._char: Optional[str] = None
        self._len = 0

    @property
    def in_fence(self) -> bool:
        return self._char is not None

    def feed(self, line: str) -> None:
        m = self._OPEN.match(line)
        if m is None:
            return
        run = m.group(1)
        if self._char is None:
            self._char = run[0]
            self._len = len(run)
        elif (
            run[0] == self._char
            and len(run) >= self._len
            and line.strip() == self._char * len(line.strip())
        ):
            self._char = None
            self._len = 0


class _Buffer:
    """A tiny StringBuffer with Dart-style ``writeln`` semantics."""

    def __init__(self) -> None:
        self._parts: list[str] = []

    def writeln(self, text: str = "") -> None:
        self._parts.append(text)
        self._parts.append("\n")

    def __str__(self) -> str:
        return "".join(self._parts)


class SpecDocumentMarkdown:
    """Codec binding a :class:`SpecModel` and a concrete :class:`SpecDocument`
    to the DocSpecs Markdown import/export format (DR1 §1)."""

    # Shared with the parser and the DocSpecs validator.
    heading_line = re.compile(r"^(#+)\s+(.*)$")
    headline_comment = re.compile(r"^<!--\[([^\]]+)\]-->\s*(.*)$")
    docspec_comment = re.compile(r"^<!--\s*docspec:.*-->\s*$")

    # A line the emitter must escape: an optional run of backslashes followed
    # by `#` at column 0 (the escape itself must survive the round-trip).
    _escapable = re.compile(r"^\\*#")

    # A line that would parse as a form-field label: `Word:` at column 0
    # (optionally already space-prefixed — each emit pass adds one more space).
    _label_shaped = re.compile(r"^ *[A-Za-z][A-Za-z0-9_]*:")

    def __init__(self, model: SpecModel, document: SpecDocument) -> None:
        self.model = model
        self.document = document
        # Metadata trees per root type, built lazily (DR8's generated facades
        # will hand these in directly; until then the bridge derives them).
        self._trees: dict[str, SomMetaTree] = {}

    def _tree_for(self, root_type: str) -> SomMetaTree:
        tree = self._trees.get(root_type)
        if tree is None:
            tree = build_som_meta_tree(self.model, root_type=root_type)
            self._trees[root_type] = tree
        return tree

    # --- Naming helpers (DR1 §1.2 / §1.5) ------------------------------------

    @staticmethod
    def title_case(name: str) -> str:
        """``introductionAndScope`` / ``DemoItem`` → ``Introduction And
        Scope`` / ``Demo Item``: a camel/Pascal-case identifier expanded into
        Title Case."""
        words: list[str] = []
        buf: list[str] = []
        for c in name:
            is_upper = c.upper() == c and c.lower() != c
            if is_upper and buf:
                words.append("".join(buf))
                buf = []
            buf.append(c)
        if buf:
            words.append("".join(buf))
        return " ".join(
            w if not w else w[0].upper() + w[1:] for w in words
        )

    @staticmethod
    def kebab_case(title: str) -> str:
        """``Demo Document`` → ``demo-document``: the DocSpecs schema id of a
        ``@Document`` name (DR1 §1.1)."""
        out = re.sub(r"[\s_]+", "-", title.strip())
        out = re.sub(r"[^A-Za-z0-9\-]", "", out)
        return out.lower()

    @staticmethod
    def item_title_stem(element_class_name: str) -> str:
        """The item heading title stem: Title-Case element class name with a
        trailing ``Entry`` dropped (DR1 §1.5, normative)."""
        stem = element_class_name
        if len(stem) > 5 and stem.endswith("Entry"):
            stem = stem[:-5]
        return SpecDocumentMarkdown.title_case(stem)

    @staticmethod
    def form_label(field_name: str) -> str:
        """The ``FieldName`` label written for a form field: the model field
        name with the first letter upper-cased (DR1 §1.4.1)."""
        if not field_name:
            return field_name
        return field_name[0].upper() + field_name[1:]

    # --- Export (DR1 §1.1–§1.6) ----------------------------------------------

    def _heading_id_of(self, node: SomMetaNode) -> str:
        """The section id written into (and matched from) a heading for *node*
        (DR1 §1.2/§1.6): the field-level ``@SectionId`` when present; for
        section/complex nodes whose field carries none, the target **class**'s
        ``@SectionId`` (the id the DR3 schema types are keyed by); else the
        path segment (the member name)."""
        if node.section_id is not None:
            return node.section_id
        if node.kind in (SomMetaKind.SECTION, SomMetaKind.COMPLEX):
            cls = self.model.class_named(node.class_name)
            if cls is not None and cls.section_id is not None:
                return cls.section_id
        return node.segment

    # --- Transparency (DR1 §1.2, mirroring the DR3 schema generator) ---------
    #
    # The DR3 `docspecs-schema` generator is normative: only **section-bearing**
    # nodes (those with a real `@SectionId`, field- or class-level) become
    # section types; id-less members are *transparent* — they are not sections
    # of their own. The markdown format mirrors that exactly:
    #
    #   * a transparent value member (content/scalar/enum/form without an id)
    #     is emitted headinglessly into its owner's *body region* (text, or a
    #     `FieldName: value` form block);
    #   * a transparent section/complex member gets no heading; its id-bearing
    #     descendants surface as the owner's direct child headings (the
    #     schema's "nearest section-bearing descendant" hoisting), with
    #     document paths still running through the transparent segments;
    #   * lists are never transparent — the `-LST` container always heads (its
    #     `@SectionId`, else the member segment) and its numbered items head one
    #     level deeper (pattern-numbered / `<member>-<pos>`).
    #
    # Principled canonicalisation losses (documented, accepted): multiple
    # transparent content members of one owner merge into the first on parse,
    # and a form-field label colliding across an owner's transparent forms
    # binds to the nearest form in slot order.

    def _is_transparent_section(self, n: SomMetaNode) -> bool:
        """A section/complex member with no field- or class-level
        ``@SectionId``: heading-less, its children hoist to the owner."""
        if n.kind not in (SomMetaKind.SECTION, SomMetaKind.COMPLEX):
            return False
        if n.section_id is not None:
            return False
        cls = self.model.class_named(n.class_name)
        return cls is None or cls.section_id is None

    @staticmethod
    def _is_transparent_value(n: SomMetaNode) -> bool:
        """A value member (content/scalar/enum/form) with no ``@SectionId``:
        emitted into the owner's body region instead of under an own
        heading."""
        return n.section_id is None and n.kind in (
            SomMetaKind.CONTENT,
            SomMetaKind.SCALAR,
            SomMetaKind.ENUM_VALUE,
            SomMetaKind.FORM,
        )

    def _body_slots(self, node: SomMetaNode) -> list[tuple[SomMetaNode, str]]:
        """The ordered *body slots* of *node*: every transparent value member
        and every transparent section (whose own path may carry body text),
        collected depth-first through transparent sections. These are the
        value positions that share the owner's heading body."""
        out: list[tuple[SomMetaNode, str]] = []

        def collect(n: SomMetaNode, prefix: str) -> None:
            for c in n.children:
                if c.recursive:
                    continue
                rel = c.segment if not prefix else f"{prefix}/{c.segment}"
                if self._is_transparent_value(c):
                    out.append((c, rel))
                elif self._is_transparent_section(c):
                    out.append((c, rel))
                    collect(c, rel)

        collect(node, "")
        return out

    def _effective_children(
        self, node: SomMetaNode
    ) -> list[tuple[SomMetaNode, str]]:
        """The ordered *effective children* of *node*: every section-bearing
        child and every list, hoisted through transparent sections — exactly
        the headings (and item-heading owners) the DR3 schema knows at this
        position. Each entry carries the relative path from *node* (which runs
        through the transparent segments)."""
        out: list[tuple[SomMetaNode, str]] = []

        def collect(n: SomMetaNode, prefix: str) -> None:
            for c in n.children:
                if c.recursive:
                    continue
                rel = c.segment if not prefix else f"{prefix}/{c.segment}"
                if self._is_transparent_value(c):
                    continue  # body region
                if self._is_transparent_section(c):
                    collect(c, rel)
                else:
                    out.append((c, rel))

        collect(node, "")
        return out

    def export_root(self, root: SpecRoot) -> str:
        """Renders the populated subtree of *root* as a DocSpecs-conform
        Markdown document. Raises :class:`ValueError` when a content value
        contains an unterminated fenced code block (which would shield the
        remainder of the document from heading detection and break the
        round-trip)."""
        tree = self._tree_for(root.type)
        node = tree.root
        b = _Buffer()
        b.writeln(
            f"<!-- docspec: {self.kebab_case(root.title)}/"
            f"{self.model.model_version_string} -->"
        )
        root_seg = node.segment
        self._write_heading(
            b,
            1,
            root_seg,
            self.document.headline(root_seg) or node.headline or root.title,
        )
        self._write_section_body(b, node, root_seg)
        self._write_children(b, node, root_seg, 2)
        return str(b)

    def _write_section_body(
        self, b: _Buffer, node: SomMetaNode, path: str
    ) -> None:
        """Writes the body region of a section heading: the section path's own
        content value plus every transparent body slot (id-less content text
        and form blocks, hoisted through transparent sections) in model
        order."""
        self._write_body(b, self.document.content(path), path)
        for slot, rel in self._body_slots(node):
            slot_path = f"{path}/{rel}"
            if slot.kind == SomMetaKind.FORM:
                if self._form_has_values(slot, slot_path):
                    self._write_form(b, slot, slot_path)
            else:
                self._write_body(b, self.document.content(slot_path), slot_path)

    def _write_children(
        self, b: _Buffer, node: SomMetaNode, base_path: str, depth: int
    ) -> None:
        for child, rel in self._effective_children(node):
            path = f"{base_path}/{rel}"
            if not self.document.has_values_under(path):
                continue
            kind = child.kind
            if kind in (
                SomMetaKind.CONTENT,
                SomMetaKind.SCALAR,
                SomMetaKind.ENUM_VALUE,
            ):
                value = self.document.content(path)
                if value is None:
                    continue
                self._write_heading(
                    b,
                    depth,
                    self._heading_id_of(child),
                    self.document.headline(path) or self._title_of(child),
                )
                self._write_body(b, value, path)
            elif kind == SomMetaKind.FORM:
                if not self._form_has_values(child, path):
                    continue
                self._write_heading(
                    b,
                    depth,
                    self._heading_id_of(child),
                    self.document.headline(path) or self._title_of(child),
                )
                self._write_form(b, child, path)
            elif kind in (SomMetaKind.SECTION, SomMetaKind.COMPLEX):
                self._write_heading(
                    b,
                    depth,
                    self._heading_id_of(child),
                    self.document.headline(path) or self._title_of(child),
                )
                self._write_section_body(b, child, path)
                self._write_children(b, child, path, depth + 1)
            elif kind == SomMetaKind.LIST:
                self._write_list_items(b, child, path, depth)

    def _write_list_items(
        self, b: _Buffer, node: SomMetaNode, list_path: str, depth: int
    ) -> None:
        """Emits list *node* as its ``-LST`` container heading (DR1 §1.2/§1.5)
        at *depth*, wrapping the numbered item headings one level deeper. The
        container is a real section — the id the DR3 schema keys its container
        type by — but carries **no content of its own** (schema content
        min/max-text-length 0). Item identity is the stored id when one
        exists, else positional (YRD3)."""
        items = self.document.list_items(list_path)
        if not items:
            return
        # The container heading: its id is the list's `-LST` `@SectionId` (else
        # the member segment for a pattern-less list); its title is the stored
        # headline, else the member name.
        self._write_heading(
            b,
            depth,
            self._heading_id_of(node),
            self.document.headline(list_path) or self._title_of(node),
        )
        # Item heading stem. Complex lists derive it from the element class name
        # (DR1 §1.5, `Entry` dropped). A scalar list (shape 6) has no element
        # class - its element ``type_name`` is literally ``String``, which would
        # render "String 1", "String 2". Derive the stem from the list FIELD
        # instead (its member name, Title-Cased like the container heading) so a
        # populated scalar list gets meaningful per-item headings (YRC5).
        stem = self._item_stem_of(node)
        element = node.element_node
        pattern = node.section_id_pattern or (
            element.section_id_pattern if element is not None else None
        )
        for i, item_path in enumerate(items):
            pos = i + 1
            # YRD3 (superseding DRC5): the heading id is the item's STORED
            # section id when one exists (an AA1 generated id or a criterion-5
            # override); only anonymous items fall back to the positional id —
            # the `@SectionIdPattern` resolved with the 1-based position
            # (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`), else `<member>-<pos>` for a
            # pattern-less list. On parse, numbered-pattern ids recover
            # membership and order from position; other pattern-shaped ids
            # parse back as stored ids. Items sit one level below the
            # container.
            stored = self.document.item_section_id(item_path)
            if stored is not None:
                item_id = stored
            elif pattern is not None:
                item_id = pattern.replace("xxx", str(pos))
            else:
                item_id = f"{node.member_name or node.segment}-{pos}"
            self._write_heading(
                b,
                depth + 1,
                item_id,
                self.document.headline(item_path) or f"{stem} {pos}",
            )
            if element is None:
                # Scalar list: the item's value is its body.
                self._write_body(
                    b, self.document.content(item_path) or "", item_path
                )
            else:
                self._write_section_body(b, element, item_path)
                if not element.recursive:
                    self._write_children(b, element, item_path, depth + 2)

    def _form_has_values(self, node: SomMetaNode, path: str) -> bool:
        fields = node.form.fields if node.form is not None else []
        for f in fields:
            if f.role is not None:
                continue  # YRD6: role values live in the heading.
            if self.document.form_field(path, f.name) is not None:
                return True
        return False

    def _write_form(self, b: _Buffer, node: SomMetaNode, path: str) -> None:
        fields = node.form.fields if node.form is not None else []
        for f in fields:
            # YRD6: a role field's value is emitted exactly once — as the
            # owning section's heading text / id comment — never as a form
            # line.
            if f.role is not None:
                continue
            value = self.document.form_field(path, f.name)
            if value is None:
                continue
            lines = self._prepare_value(value, path).split("\n")
            b.writeln(f"{self.form_label(f.name)}: {lines[0]}")
            for line in lines[1:]:
                # §1.4.3 generalised: any continuation line that could be
                # mistaken for a field-label line gains one leading space;
                # parse strips it.
                b.writeln(
                    f" {line}" if self._label_shaped.match(line) else line
                )
        b.writeln()

    @staticmethod
    def _write_heading(b: _Buffer, depth: int, id: str, title: str) -> None:
        """``## <!--[ID]--> Title`` at *depth*. DR1 §1.2 is normative —
        heading level = 1 + section depth, **uncapped**: deep models (the
        Solution Blueprint nests past markdown's native 6 levels) keep their
        structure; the parse grammar accepts ``#{7,}`` accordingly. Capping
        would silently flatten distinct nesting positions into siblings and
        break schema validation."""
        b.writeln(f"{'#' * depth} <!--[{id}]--> {title}")
        b.writeln()

    def _write_body(
        self, b: _Buffer, value: Optional[str], path: str
    ) -> None:
        """Writes *value* as a section body followed by a blank line; no-op
        for ``None``/blank values."""
        if value is None:
            return
        prepared = self._prepare_value(value, path)
        if not prepared:
            return
        b.writeln(prepared)
        b.writeln()

    def _prepare_value(self, value: str, path: str) -> str:
        """Emit-side value normalisation (DR1 §1.3): collapse 2+ blank lines
        to one, trim leading/trailing blank lines, escape heading-like lines
        outside fences. Raises :class:`ValueError` for an unterminated
        fence."""
        collapsed = re.sub(r"\n{3,}", "\n\n", value)
        collapsed = re.sub(r"^\n+", "", collapsed)
        collapsed = re.sub(r"\n+$", "", collapsed)
        fence = MarkdownFenceTracker()
        out: list[str] = []
        for line in collapsed.split("\n"):
            if fence.in_fence:
                out.append(line)  # §1.3.4: fences shield their lines.
            elif self._escapable.match(line):
                out.append(f"\\{line}")
            else:
                out.append(line)
            fence.feed(line)
        if fence.in_fence:
            raise ValueError(
                f'content at "{path}" contains an unterminated fenced code '
                "block; it cannot be represented in the DocSpecs markdown "
                "format"
            )
        return "\n".join(out)

    @staticmethod
    def _title_of(node: SomMetaNode) -> str:
        """The effective DEFAULT title of *node* (YRD4): the ``@Headline``
        default when authored, else the name derivation. The stored headline
        (checked by callers first) always wins over this."""
        return node.headline or SpecDocumentMarkdown.title_case(
            node.member_name or node.class_name
        )

    @staticmethod
    def _item_stem_of(node: SomMetaNode) -> str:
        """The effective default item-title stem of list *node* (YRD4): the
        element class's ``@Headline`` default when authored, else the DR1
        §1.5 derivation (element class name with ``Entry`` dropped; member
        name for scalar lists)."""
        element = node.element_node
        if element is not None:
            return element.headline or SpecDocumentMarkdown.item_title_stem(
                element.class_name
            )
        return SpecDocumentMarkdown.title_case(
            node.member_name or node.segment
        )

    # --- Import (DR1 §1.7) ----------------------------------------------------

    def parse(self, text: str) -> SpecMarkdownResult:
        """Parses *text* into staged values + a rejection report, **without**
        mutating the document. The caller applies the result as a full
        overwrite."""
        p = _Parser(self)
        p.run(text.split("\n"))
        return SpecMarkdownResult(
            content=p.content,
            forms=p.forms,
            lists=p.lists_json(),
            headlines=p.headlines,
            rejections=p.rejections,
            root_prefixes=p.root_prefixes,
        )


class _Frame:
    """One open section during the parse: its heading level, resolved node
    (``None`` for an unresolvable/ignored section), path, and accumulated body
    lines."""

    def __init__(
        self,
        level: int,
        node: Optional[SomMetaNode],
        path: str,
        line: int,
        ignored: bool = False,
    ) -> None:
        self.level = level
        self.node = node
        self.path = path
        self.line = line
        self.ignored = ignored
        self.body: list[str] = []


class _ListState:
    """Per-list bookkeeping while parsing: ordered item paths, stored ids, and
    the highest item number handed out (drives both fresh numbers for
    stored-id items and the resulting ``seq``)."""

    def __init__(self) -> None:
        self.items: list[str] = []
        self.ids: dict[str, str] = {}
        self.max_n = 0


_FIELD_LABEL = re.compile(r"^([A-Za-z][A-Za-z0-9_]*): ?(.*)$")
_CONTINUATION_LABEL = re.compile(r"^ +[A-Za-z][A-Za-z0-9_]*:")
_ESCAPED_HEADING = re.compile(r"^\\+#")


class _Parser:
    def __init__(self, codec: SpecDocumentMarkdown) -> None:
        self.codec = codec
        self.content: dict[str, str] = {}
        self.forms: dict[str, dict[str, str]] = {}
        self.lists: dict[str, _ListState] = {}
        self.headlines: dict[str, str] = {}
        self.rejections: list[SpecMarkdownRejection] = []
        self.root_prefixes: set[str] = set()
        self._stack: list[_Frame] = []
        self._fence = MarkdownFenceTracker()
        # Rolling pointer into a body region's transparent form slots — labels
        # bind to the nearest form at or after the last hit (wrapping), so
        # repeated field names across an owner's transparent forms follow emit
        # order.
        self._current_form_idx = 0

    def run(self, lines: list[str]) -> None:
        for i, raw in enumerate(lines):
            line_no = i + 1
            trimmed = raw.rstrip()

            if not self._fence.in_fence:
                if not self._stack and SpecDocumentMarkdown.docspec_comment.match(
                    trimmed
                ):
                    continue  # §1.1 header — informational.
                h = SpecDocumentMarkdown.heading_line.match(trimmed)
                if h is not None:
                    self._close_to(len(h.group(1)))
                    self._open_heading(len(h.group(1)), h.group(2), line_no)
                    continue
            if self._stack:
                self._stack[-1].body.append(raw)
            elif trimmed:
                self.rejections.append(
                    SpecMarkdownRejection(
                        line=line_no,
                        reason=SpecMarkdownRejectReason.ORPHAN_CONTENT,
                        message="text before the document root heading",
                    )
                )
            self._fence.feed(raw)
        self._close_to(1)
        if self._stack:
            self._finalize(self._stack.pop())

    def _close_to(self, level: int) -> None:
        """Pops (and finalizes) every frame at *level* or deeper."""
        while self._stack and self._stack[-1].level >= level:
            self._finalize(self._stack.pop())

    def _open_heading(self, level: int, rest: str, line_no: int) -> None:
        m = SpecDocumentMarkdown.headline_comment.match(rest.strip())
        if m is None:
            self.rejections.append(
                SpecMarkdownRejection(
                    line=line_no,
                    reason=SpecMarkdownRejectReason.MALFORMED_HEADING,
                    anchor=rest.strip(),
                    message=(
                        "heading carries no <!--[SECTION-ID]--> headline "
                        "comment"
                    ),
                )
            )
            self._stack.append(
                _Frame(level=level, node=None, path="", line=line_no,
                       ignored=True)
            )
            return
        id = m.group(1)
        title = m.group(2).strip()

        if not self._stack:
            self._open_root(level, id, title, line_no)
            return

        parent = self._stack[-1]
        if parent.ignored:
            self.rejections.append(
                SpecMarkdownRejection(
                    line=line_no,
                    reason=SpecMarkdownRejectReason.UNKNOWN_SECTION,
                    anchor=id,
                    message="section nested under an unresolvable parent",
                )
            )
            self._stack.append(
                _Frame(level=level, node=None, path="", line=line_no,
                       ignored=True)
            )
            return
        p_node = parent.node
        if p_node is None or self._is_value_leaf(p_node.kind):
            self.rejections.append(
                SpecMarkdownRejection(
                    line=line_no,
                    reason=SpecMarkdownRejectReason.KIND_MISMATCH,
                    anchor=id,
                    message="child heading under a value-leaf or form section",
                )
            )
            self._stack.append(
                _Frame(level=level, node=None, path="", line=line_no,
                       ignored=True)
            )
            return

        # 1. Under a `-LST` container frame (DR1 §1.2), every child heading is
        #    one of that list's items — resolved positionally, not by the
        #    schema tree.
        if p_node.kind == SomMetaKind.LIST:
            self._open_item_heading(level, parent, p_node, id, title, line_no)
            return

        # 2. A regular (non-list) or list-**container** *effective* child —
        #    section-bearing children hoisted through transparent sections —
        #    whose heading id matches. A list heads its `-LST` container here;
        #    its items are resolved above once the container frame is open.
        #    Transparent value members never head, so they never match; the
        #    bound path runs through the transparent segments.
        effective = self.codec._effective_children(p_node)
        for c, rel in effective:
            if self.codec._heading_id_of(c) == id:
                path = f"{parent.path}/{rel}"
                # YRD3: stage the heading text as a stored headline only when
                # it differs from the effective default title
                # (byte-stability).
                if title and title != SpecDocumentMarkdown._title_of(c):
                    self.headlines[path] = title
                self._stack.append(
                    _Frame(level=level, node=c, path=path, line=line_no)
                )
                return

        self.rejections.append(
            SpecMarkdownRejection(
                line=line_no,
                reason=SpecMarkdownRejectReason.UNKNOWN_SECTION,
                anchor=id,
                message=(
                    "section id does not resolve against the schema tree at "
                    f'this position (under "{parent.path}")'
                ),
            )
        )
        self._stack.append(
            _Frame(level=level, node=None, path="", line=line_no, ignored=True)
        )

    def _open_item_heading(
        self,
        level: int,
        container: "_Frame",
        list_node: SomMetaNode,
        id: str,
        title: str,
        line_no: int,
    ) -> None:
        """Opens a list-item frame under a ``-LST`` container frame (DR1 §1.2).
        The heading *id* is matched positionally against the container's list:
        the ``<member>-<n>`` fallback id, the ``@SectionIdPattern`` resolved
        with a number (``GOAL-ITEM-3``, parses back as item ``<n>``), a
        pattern-shaped stored id, or — for any other id — an anonymous next
        item carrying the stored id."""
        list_path = container.path
        anon = re.match(
            "^"
            + re.escape(list_node.member_name or list_node.segment)
            + "-([0-9]+)$",
            id,
        )
        if anon is not None:
            self._open_item(
                level,
                list_path,
                list_node,
                int(anon.group(1)),
                None,
                title,
                line_no,
            )
            return
        element = list_node.element_node
        pattern = list_node.section_id_pattern or (
            element.section_id_pattern if element is not None else None
        )
        if pattern is not None:
            # Canonical anonymous id: the pattern with `xxx` as a number —
            # parses back as item <n>, NOT as a stored id (YRD3 round-trip,
            # §8.5).
            numbered_re = (
                "^"
                + "([0-9]+)".join(re.escape(p) for p in pattern.split("xxx"))
                + "$"
            )
            numbered = re.match(numbered_re, id)
            if numbered is not None and numbered.re.groups == 1:
                self._open_item(
                    level,
                    list_path,
                    list_node,
                    int(numbered.group(1)),
                    None,
                    title,
                    line_no,
                )
                return
            if self._pattern_matches(pattern, id):
                self._open_item(
                    level, list_path, list_node, None, id, title, line_no
                )
                return
        # Any other id under the container is an anonymous next item carrying
        # the stored id (YRD3: stored ids round-trip through md as well as
        # yaml).
        self._open_item(level, list_path, list_node, None, id, title, line_no)

    def _open_root(
        self, level: int, id: str, title: str, line_no: int
    ) -> None:
        for root in self.codec.model.roots:
            seg = root.section_id or root.type
            if seg == id:
                tree = self.codec._tree_for(root.type)
                self.root_prefixes.add(seg)
                # YRD3: stage a renamed root heading as a stored headline —
                # "renamed" relative to the effective default (YRD4:
                # `@Headline` default, else the `@Document` title).
                if title and title != (tree.root.headline or root.title):
                    self.headlines[seg] = title
                self._stack.append(
                    _Frame(level=level, node=tree.root, path=seg, line=line_no)
                )
                return
        known = ", ".join(
            r.section_id or r.type for r in self.codec.model.roots
        )
        self.rejections.append(
            SpecMarkdownRejection(
                line=line_no,
                reason=SpecMarkdownRejectReason.UNKNOWN_SECTION,
                anchor=id,
                message=(
                    f"no document root with this section id (known: {known})"
                ),
            )
        )
        self._stack.append(
            _Frame(level=level, node=None, path="", line=line_no, ignored=True)
        )

    def _open_item(
        self,
        level: int,
        list_path: str,
        list_node: SomMetaNode,
        n: Optional[int],
        stored_id: Optional[str],
        title: str,
        line_no: int,
    ) -> None:
        """Opens a list-item frame. *n* is the anonymous heading number (also
        the path number); a stored-id item gets the next free number instead.
        The heading *title* is staged as a stored headline when it differs
        from the default item title ``<stem> <number>`` (YRD3)."""
        state = self.lists.get(list_path)
        if state is None:
            state = _ListState()
            self.lists[list_path] = state
        number = n if n is not None else state.max_n + 1
        if number > state.max_n:
            state.max_n = number
        item_path = f"{list_path}-{number}"
        state.items.append(item_path)
        if stored_id is not None:
            state.ids[item_path] = stored_id
        stem = SpecDocumentMarkdown._item_stem_of(list_node)
        if title and title != f"{stem} {number}":
            self.headlines[item_path] = title
        self._stack.append(
            _Frame(
                level=level,
                node=list_node.element_node,
                path=item_path,
                line=line_no,
            )
        )

    @staticmethod
    def _pattern_matches(pattern: str, id: str) -> bool:
        """``GOAL-ITEM-xxx`` → ``^GOAL-ITEM-.+$`` — the ``@SectionIdPattern``
        wildcard."""
        regex = (
            "^" + ".+".join(re.escape(p) for p in pattern.split("xxx")) + "$"
        )
        return re.match(regex, id) is not None

    @staticmethod
    def _is_value_leaf(kind: SomMetaKind) -> bool:
        return kind in (
            SomMetaKind.CONTENT,
            SomMetaKind.SCALAR,
            SomMetaKind.ENUM_VALUE,
        )

    # --- Body finalisation ----------------------------------------------------

    def _finalize(self, frame: _Frame) -> None:
        if frame.ignored:
            return
        node = frame.node
        if node is not None and node.kind == SomMetaKind.FORM:
            self._finalize_form(frame, node, frame.path)
            return
        slots = [] if node is None else self.codec._body_slots(node)
        if not slots:
            value = self._restore_value(frame.body)
            if value:
                self.content[frame.path] = value
            elif node is not None and self._is_value_leaf(node.kind):
                self.rejections.append(
                    SpecMarkdownRejection(
                        line=frame.line,
                        reason=SpecMarkdownRejectReason.MISSING_VALUE,
                        anchor=frame.path,
                        message="no value text under this section heading",
                    )
                )
            return
        self._finalize_body_slots(frame, slots)

    def _finalize_body_slots(
        self, frame: _Frame, slots: list[tuple[SomMetaNode, str]]
    ) -> None:
        """Binds a heading's body region against the owner's transparent body
        slots (DR1 §1.2 transparency): ``FieldName:`` lines matching a
        transparent form's fields route to that form (nearest form in slot
        order, wrapping); all other text binds to the first non-form slot — or
        to the owner's own path when no such slot exists."""
        form_slots = [s for s in slots if s[0].kind == SomMetaKind.FORM]
        content_slots = [s for s in slots if s[0].kind != SomMetaKind.FORM]
        content_path = (
            f"{frame.path}/{content_slots[0][1]}"
            if content_slots
            else frame.path
        )

        if not form_slots:
            value = self._restore_value(frame.body)
            if value:
                self.content[content_path] = value
            return

        def find_field(
            label: str,
        ) -> Optional[tuple[int, "SomFormFieldMeta"]]:
            lower = label.lower()
            for k in range(len(form_slots)):
                idx = (self._current_form_idx + k) % len(form_slots)
                form = form_slots[idx][0].form
                fields = form.fields if form is not None else []
                for f in fields:
                    if f.name.lower() == lower:
                        return (idx, f)
            return None

        fence = MarkdownFenceTracker()
        current_field: Optional[str] = None
        current_form_path: Optional[str] = None
        dropping = False
        current_lines: list[str] = []
        content_lines: list[str] = []

        def flush() -> None:
            nonlocal current_lines
            if current_field is not None and current_form_path is not None:
                value = self._restore_value(current_lines)
                if value:
                    self.forms.setdefault(current_form_path, {})[
                        current_field
                    ] = value
            current_lines = []

        self._current_form_idx = 0
        for i, line in enumerate(frame.body):
            if not fence.in_fence:
                m = _FIELD_LABEL.match(line)
                if m is not None:
                    hit = find_field(m.group(1))
                    if hit is not None:
                        flush()
                        # YRD6: a title/id role field's value is the owning
                        # section's heading / id comment — a form line
                        # duplicating it is rejected, never stored
                        # (continuation lines are dropped with it).
                        if hit[1].role is not None:
                            self.rejections.append(
                                SpecMarkdownRejection(
                                    line=frame.line + i,
                                    reason=(
                                        SpecMarkdownRejectReason
                                        .ROLE_FIELD_FORM_LINE
                                    ),
                                    anchor=(
                                        f"{frame.path}/"
                                        f"{form_slots[hit[0]][1]}"
                                    ),
                                    message=(
                                        f"form field `{hit[1].name}` is a "
                                        "title/id role field — its value is "
                                        "the section heading, not a form "
                                        "line"
                                    ),
                                )
                            )
                            current_field = None
                            current_form_path = None
                            dropping = True
                            current_lines = []
                            fence.feed(line)
                            continue
                        self._current_form_idx = hit[0]
                        current_field = hit[1].name
                        current_form_path = (
                            f"{frame.path}/{form_slots[hit[0]][1]}"
                        )
                        current_lines = [m.group(2)]
                        dropping = False
                        fence.feed(line)
                        continue
            if dropping:
                fence.feed(line)
                continue
            target = content_lines if current_field is None else current_lines
            # Continuation: strip the one escape space of a label-shaped line.
            if (
                not fence.in_fence
                and current_field is not None
                and _CONTINUATION_LABEL.match(line)
            ):
                target.append(line[1:])
            else:
                target.append(line)
            fence.feed(line)
        flush()
        value = self._restore_value(content_lines)
        if value:
            self.content[content_path] = value

    def _finalize_form(
        self, frame: _Frame, node: SomMetaNode, path: str
    ) -> None:
        form = node.form
        fields = form.fields if form is not None else []
        fields_by_lower = {f.name.lower(): f.name for f in fields}
        # YRD6: role fields (title/id) are represented by the section heading /
        # id comment — a form line duplicating one is rejected, never stored.
        role_fields = {f.name for f in fields if f.role is not None}
        fence = MarkdownFenceTracker()
        current_field: Optional[str] = None
        dropping = False
        current_lines: list[str] = []

        def flush(line_no: int) -> None:
            nonlocal current_lines, dropping
            if current_field is not None:
                value = self._restore_value(current_lines)
                if value:
                    self.forms.setdefault(path, {})[current_field] = value
            elif not dropping and any(l.strip() for l in current_lines):
                self.rejections.append(
                    SpecMarkdownRejection(
                        line=line_no,
                        reason=SpecMarkdownRejectReason.ORPHAN_CONTENT,
                        anchor=path,
                        message=(
                            "text in a @Form section before the first field "
                            "label"
                        ),
                    )
                )
            dropping = False
            current_lines = []

        for i, line in enumerate(frame.body):
            if not fence.in_fence:
                m = _FIELD_LABEL.match(line)
                field_name = (
                    fields_by_lower.get(m.group(1).lower())
                    if m is not None
                    else None
                )
                if field_name is not None and m is not None:
                    flush(frame.line + i)
                    if field_name in role_fields:
                        self.rejections.append(
                            SpecMarkdownRejection(
                                line=frame.line + i,
                                reason=(
                                    SpecMarkdownRejectReason
                                    .ROLE_FIELD_FORM_LINE
                                ),
                                anchor=path,
                                message=(
                                    f"form field `{field_name}` is a "
                                    "title/id role field — its value is the "
                                    "section heading, not a form line"
                                ),
                            )
                        )
                        current_field = None
                        dropping = True
                        current_lines = []
                        fence.feed(line)
                        continue
                    current_field = field_name
                    current_lines = [m.group(2)]
                    fence.feed(line)
                    continue
            # Continuation: strip the one escape space of a label-shaped line.
            if not fence.in_fence and _CONTINUATION_LABEL.match(line):
                current_lines.append(line[1:])
            else:
                current_lines.append(line)
            fence.feed(line)
        flush(frame.line + len(frame.body))

    @staticmethod
    def _restore_value(body: list[str]) -> str:
        """Parse-side value restoration (DR1 §1.3): trim leading/trailing
        blank lines and unescape ``\\#``-escaped heading lines outside
        fences."""
        fence = MarkdownFenceTracker()
        out: list[str] = []
        for line in body:
            if not fence.in_fence and _ESCAPED_HEADING.match(line):
                out.append(line[1:])
            else:
                out.append(line)
            fence.feed(line)
        joined = "\n".join(out)
        joined = re.sub(r"^([ \t]*\n)+", "", joined)
        joined = re.sub(r"(\n[ \t]*)+$", "", joined)
        return joined

    def lists_json(self) -> dict[str, dict[str, Any]]:
        out: dict[str, dict[str, Any]] = {}
        for key, state in self.lists.items():
            entry: dict[str, Any] = {
                "seq": state.max_n,
                "items": list(state.items),
            }
            if state.ids:
                entry["ids"] = dict(state.ids)
            out[key] = entry
        return out
