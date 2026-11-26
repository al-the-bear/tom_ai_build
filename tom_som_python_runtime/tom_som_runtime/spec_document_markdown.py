"""DocSpecs-conform Markdown codec for a TomSpecs document (SOM §11) — a
faithful port of ``tom_som_dart_runtime/lib/src/spec_document_markdown.dart``.

The generated/authored ``*.md`` **is a genuine DocSpecs document**: line 1 is
the ``<!-- docspec: <schema-id>/<version> -->`` declaration, every populated
section is one markdown heading whose machine-readable identity is the DocSpecs
headline comment ``<!--[SECTION-ID]-->`` and whose text is the section's
**stored headline** when one exists, else the human-readable Title-Case member
name (YRD3: md is a full-fidelity format — stored headlines round-trip).
Content values are **normal markdown text** under their heading (no fences);
every heading carries its section id as an HTML anchor, qualified below a list
item and in a ``@SameAs`` copy (SOM §11.2). ``@Form`` sections are written in
the reading-view layout (see below); a list emits its ``-LST`` **container
heading** (the id the generated schema
keys its container type by), with the numbered items one level deeper, each
carrying the item's **stored section id** when one exists (an AA1 date-lettered
generated id or a criterion-5 override), else the anonymous positional id — the
``@SectionIdPattern`` resolved with the 1-based position (``GOAL-ITEM-xxx`` →
``GOAL-ITEM-1``), else ``<member>-<pos>`` for a pattern-less list. The container
carries no content of its own. On parse, anonymous positional ids recover list
membership and order from position; stored ids are kept as stored ids
(``som_multiplatform_spec_model.md`` §11.5).
Id-less members are **transparent** (mirroring the schema generator , SOM §13):
a transparent value member's text or form block is the owner's body region,
emitted without a heading and bound at its own path; a transparent
section/complex member never heads — its id-bearing descendants hoist to the
owner's child level (paths keep the transparent segments). Section/complex
headings without a field-level ``@SectionId`` carry the target class's
``@SectionId``.

Escaping (SOM §11.3): a content line starting with ``#`` at column 0 is emitted
as ``\\#`` (and a leading ``\\#``… run gains one more backslash), except inside
fenced code blocks, which shield their lines verbatim. Blank lines inside a
value are kept as written; parse trims each value of leading/trailing blank
lines only.

Reading view (SOM §11.4, §11.5): the emitter writes the reading view's table
layout — form tables ``| TomSpecField | Value |``, record tables in a
``::: {.records}`` div, reference lines in a ``::: {.refs}`` div, section
tables ``| Section | TomSpecField | Value |`` and an anchor ``<a id="ID">`` in
every heading; a value no table cell holds (a ``multiParagraph`` field,
several paragraphs, a block) is a ``Field:`` paragraph, a wrapped
one-paragraph value one cell (rule 13). The parser reads that layout and the
older layout of ``Field:`` lines alike, and reports a block that breaks it as
``unknownField`` or ``malformedBlock``. A value line shaped like a layout table
header is written with one escape space, which the parser removes.

Navigation and generated parts (SOM §11.11, §11.12): a markable heading is
followed by its ``linked`` marker (``Also in``, ``Summary of``, ``Summarised
in``, ``Derived from``, ``Extracted from``, ``Copy of``, ``Copied to``;
``spec_document_markdown_linked.py``), a summary row's ``Id`` cell links the
detail element it names, and the requirement views open their sections with
a generated table in a ``derived`` block
(``spec_document_markdown_generated.py``). The options ``linked_markers`` and
``generated_parts`` turn them off; the parser removes both, and an empty value
under a generated block is no missing value.

The codec is free of any UI: it reads from / resolves against a
:class:`SpecModel` (through the :func:`build_som_meta_tree` metadata tree) and
a :class:`SpecDocument`. :meth:`SpecDocumentMarkdown.parse` does **not** mutate
the document — it returns staged values keyed exactly like
:meth:`SpecDocument.to_json` plus a rejection report; :meth:`SpecDocument.apply_markdown_result` applies them.
Anything that cannot be mapped — an unknown section id, a child heading under a
value leaf, orphaned text — is collected into
:attr:`SpecMarkdownResult.rejections` rather than dropped (SOM §11.7); an
import accepting rejections keeps each rejected block as a ``rejected`` div in
the text of the section it stood in, else its parent
(:attr:`SpecMarkdownResult.kept_content`, DocSpecs RN-11).
"""

from __future__ import annotations

import bisect
import re
from dataclasses import dataclass, field as dataclass_field
from enum import Enum
from typing import Any, Callable, Optional

from .spec_document import SpecDocument
from .spec_meta import SomMetaKind, SomMetaNode, SomMetaTree
from .spec_meta_bridge import build_som_meta_tree
from .spec_model import SpecModel, SpecRoot
from .spec_section_id import effective_list_item_section_id
from .spec_document_markdown_generated import (
    K_DERIVED_PLACEHOLDER,
    Generated as _Generated,
    derived_fence_close,
    opens_derived,
    resolve_derived_placeholders,
)
from .spec_document_markdown_linked import (
    ANCHOR_CONTAINER as _ANCHOR_CONTAINER,
    ANCHOR_COPY as _ANCHOR_COPY,
    ANCHOR_ITEM as _ANCHOR_ITEM,
    ANCHOR_PLAIN as _ANCHOR_PLAIN,
    K_LINKED_PLACEHOLDER,
    Navigation as _Navigation,
    is_linked_paragraph,
    qualify_anchor as _qualify_anchor,
    resolve_linked_placeholders,
)

# The whitespace JavaScript's `\s` and `trim()` know, which the reference
# codecs decide by (Python's own `\s` and `str.strip` know more).
_JS_WS_CHARS = (
    "\t\n\x0b\f\r          "
    "        　﻿"
)
_WS = (
    "[\\t\\n\\x0b\\f\\r \\u00a0\\u1680\\u2000-\\u200a\\u2028\\u2029"
    "\\u202f\\u205f\\u3000\\ufeff]"
)
# A section id as a reference holds it: upper-case segments joined by `-`.
_ID_SHAPE = re.compile(r"[A-Z][A-Z0-9]*(-[A-Z0-9]+)*")
# A one-line value that Markdown reads as a block: a list item, a block quote
# (review comment and question blocks among them), a fence or a fenced div. A
# table needs two lines, so it is caught by the line break.
_BLOCK_START = re.compile(
    "^" + _WS + "*([-*+]" + _WS + "|[0-9]+[.)]" + _WS + "|>|```|~~~|:::)"
)
# A line that is a block of its own, or would make the line above one, beyond
# _BLOCK_START: a table row, an ATX heading, a setext underline or a thematic
# break, an HTML block.
_WRAPPED_LINE_BLOCK = re.compile(
    "^(?:\\||#{1,6}(?:" + _WS + "|\\Z)|=+\\Z|(?:[-*_]" + _WS + "*){3,}\\Z|<)"
)


def _trim_ws(s: str) -> str:
    """*s* without the leading and trailing whitespace the reference codecs
    trim."""
    return s.strip(_JS_WS_CHARS)


def _under(sorted_keys: list[str], prefix: str) -> list[str]:
    """The keys of *sorted_keys* at or below *prefix*: a binary search to the
    first key not before it, then the run sharing it as a prefix, so a large
    document is not scanned once per list item."""
    out: list[str] = []
    i = bisect.bisect_left(sorted_keys, prefix)
    n = len(prefix)
    while i < len(sorted_keys) and sorted_keys[i].startswith(prefix):
        k = sorted_keys[i]
        if len(k) == n or k[n] == "/":
            out.append(k)
        i += 1
    return out


class SpecMarkdownRejectReason(Enum):
    """Why an imported Markdown block was rejected (SOM §11.7 rejection
    protocol)."""

    #: The heading's section id does not resolve against the schema tree at
    #: its nesting position.
    UNKNOWN_SECTION = "unknownSection"
    #: A structurally impossible combination — e.g. a child heading nested
    #: under a value-leaf (content/scalar/enum) section.
    KIND_MISMATCH = "kindMismatch"
    #: Body text with no owning value slot — text before the document root
    #: heading.
    ORPHAN_CONTENT = "orphanContent"
    #: A value-leaf section heading with an empty body.
    MISSING_VALUE = "missingValue"
    #: A heading line without a parseable ``<!--[id]-->`` headline comment.
    MALFORMED_HEADING = "malformedHeading"
    #: A form-table row, a section-table row or a records column names no
    #: field the form declares (SOM §11.4, §11.5).
    UNKNOWN_FIELD = "unknownField"
    #: A block that breaks the layout grammar: a table without its delimiter
    #: row or with a row of another cell count, a field given twice, a
    #: ``refs`` / ``records`` div beside other text or item headings or not
    #: holding what it should, an unclosed ``refs`` / ``records`` fence. The
    #: message says which.
    MALFORMED_BLOCK = "malformedBlock"


@dataclass
class SpecMarkdownRejection:
    """One rejected block in a Markdown import (SOM §11.7). Reported, never
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
    """The outcome of parsing a Markdown document (SOM §11.7): the staged values
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
    #: Stored codeSpec mappings (codespecs_mapping.md §9.2): path → the
    #comma-joined list of : CodeSpecs code locations parsed from the
    #``codeSpec="…"`` key in the : heading comment. Staged whenever present
    #(codeSpec has no effective : default).
    code_specs: dict[str, str] = dataclass_field(default_factory=dict)
    #: Stored generation units (SOM §11.2): path → the comma-joined list of
    #: generation-unit ids parsed from the ``units="…"`` key in the heading
    #: comment. Staged whenever present (absent means the default).
    units: dict[str, str] = dataclass_field(default_factory=dict)
    #: Every rejected block, in source order.
    rejections: list[SpecMarkdownRejection] = dataclass_field(
        default_factory=list
    )
    #: The root segment(s) the import covers (the first segment of each
    #: accepted path) — the scope a full-overwrite apply purges before writing.
    root_prefixes: set[str] = dataclass_field(default_factory=set)
    #: The rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): for
    #: every path whose text a rejected block stood in, the value with each
    #: such block written as a ``rejected`` div at its place. An apply that
    #: accepts rejections (:meth:`SpecDocument.apply_markdown_result` with
    #: ``allow_rejections=True``) writes these over :attr:`content`, so
    #: nothing written is lost; an empty value removes the path's text. Empty
    #: for a clean parse.
    kept_content: dict[str, str] = dataclass_field(default_factory=dict)
    #: The readable header line of a stripped rendition (SOM §11.1), when the
    #: text carried one before its root heading; the parser skipped it.
    readable_header: Optional[str] = None

    @property
    def is_clean(self) -> bool:
        """Whether the parse was clean (no rejections)."""
        return not self.rejections

    @property
    def applied_count(self) -> int:
        """The number of leaf values successfully parsed (content + form
        fields)."""
        return len(self.content) + sum(len(m) for m in self.forms.values())


@dataclass
class SpecMarkdownImport:
    """A Markdown document loaded by :meth:`SpecDocument.from_markdown`: the
    document holding every accepted value, plus the parse report. Both are set
    by the import that produced them."""

    #: The document holding every value the parse accepted.
    document: SpecDocument
    #: The parse report, rejections included.
    result: SpecMarkdownResult

    @property
    def rejections(self) -> list[SpecMarkdownRejection]:
        """The blocks the parse rejected, in source order; each is kept in
        :attr:`document` as a ``rejected`` div for review (SOM §11.7)."""
        return self.result.rejections


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

    def write(self, text: str) -> None:
        """Appends *text* verbatim — no trailing newline. Used to splice an
        already-terminated buffer (a form's field block) into its owner."""
        self._parts.append(text)

    def __str__(self) -> str:
        return "".join(self._parts)


class SpecDocumentMarkdown:
    """Codec binding a :class:`SpecModel` and a concrete :class:`SpecDocument`
    to the DocSpecs Markdown import/export format (SOM §11)."""

    # Shared with the parser and the DocSpecs validator.
    heading_line = re.compile(r"^(#+)\s+(.*)$")
    #: The heading HTML comment: ``<!--[ID]--> Title`` with an optional :
    #key=value region between the id bracket and the closing ``-->``
    #(codespecs_mapping.md §9.2 : ``codeSpec``). Group 1 = the section id, group
    #2 = the raw key=value : region (possibly empty), group 3 = the heading
    #title. The middle group : is ``[^>]*`` — safe because the region's only
    #values are quoted code : locations / identifiers, never a raw ``>``.
    headline_comment = re.compile(r"^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$")
    docspec_comment = re.compile(r"^<!--\s*docspec:.*-->\s*$")
    #: The readable header line of a stripped rendition (SOM §11.1).
    readable_comment = re.compile(r"^<!--\s*readable:.*-->$")
    #: The line a stripped rendition's appendix begins with (SOM §11.1):
    #: after a readable header, the parsers stop reading at it.
    appendix_marker = "<!-- readable-appendix -->"
    #: The fixed start of a styled-div heading's style, up to its indent.
    heading_div_style_start = "margin:1em 0 0.5em;padding-left:"
    #: A styled-div heading line (DocSpecs *Styled-div headings*): group 1 the
    #: level, group 2 the inner text. A level below 7 is content.
    heading_div_line = re.compile(r'^<div class="heading([0-9]+)"[^>]*>(.*)</div>$')
    #: Extracts the ``codeSpec="…"`` value from a heading-comment key=value :
    #region (codespecs_mapping.md §9.2), mirroring the tom_doc_scanner key=value
    #grammar.
    _code_spec_pattern = re.compile(
        r"""codeSpec=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))"""
    )
    #: Extracts the ``units="…"`` value from a heading-comment key=value region
    #: (SOM §11.2). The key must start the region or follow whitespace, so a
    #: ``units=`` inside a quoted codeSpec value is not read as the key.
    _units_pattern = re.compile(
        r"""(?:^|\s)units=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))"""
    )

    #: A line that reads as the header of a form table or a section table
    #: (SOM §11.4, §11.5): ``| TomSpecField | Value |`` or
    #: ``| Section | TomSpecField | Value |`` at column 0, any case; group 1 is
    #: ``Section`` for a section table. The header alone makes a table layout.
    layout_table_header = re.compile(
        r"^\|\s*(?:(Section)\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$",
        re.IGNORECASE,
    )

    # A line the emitter must escape: an optional run of backslashes followed
    # by `#` at column 0 (the escape itself must survive the round-trip).
    _escapable = re.compile(r"^\\*#")

    # A line that would parse as a form-field label: `Word:` at column 0
    # (optionally already space-prefixed — each emit pass adds one more space).
    _label_shaped = re.compile(r"^ *[A-Za-z][A-Za-z0-9_]*:")

    def __init__(
        self,
        model: SpecModel,
        document: SpecDocument,
        file_stem: Optional[str] = None,
        document_files: Optional[dict[str, str]] = None,
        *,
        heading_divs: bool = False,
        readable_header: Optional[str] = None,
        linked_markers: bool = True,
        generated_parts: bool = True,
    ) -> None:
        """Binds *model* and *document* to the codec; *file_stem* and
        *document_files* (either may be ``None``) name the files a reference
        to another document root links to. *heading_divs* and
        *readable_header* are the options of a stripped rendition
        (SOM §11.10). *linked_markers* (default true) writes the ``linked``
        marker after a markable heading (SOM §11.11); *generated_parts*
        (default true) writes the generated parts at their sections
        (SOM §11.12). A stripped rendition dropping ``linked`` / ``derived``
        turns them off; the parser removes both either way."""
        self.model = model
        self.document = document
        #: Whether every section deeper than level 6 is written as a
        #: styled-div heading (``<div class="heading<N>" style="…">…</div>``,
        #: SOM §11.2); the parser reads both forms whatever it says.
        self.heading_divs = heading_divs is True
        #: The readable header line of a stripped rendition, written after
        #: the ``docspec`` declaration (SOM §11.1), or ``None``; the parser
        #: skips it.
        self.readable_header = readable_header
        #: Whether the ``linked`` marker is written (SOM §11.11).
        self.linked_markers = linked_markers is not False
        #: Whether the generated parts are written (SOM §11.12).
        self.generated_parts = generated_parts is not False
        #: The stem of the files a reference to another document root links
        #: to (``<file_stem>.<root id in lower case>.tomspecs.md``), or
        #: ``None``.
        self.file_stem = file_stem
        #: The rendition file of a document root, keyed by its section id or
        #: type; a root it does not name takes the :attr:`file_stem` name.
        self.document_files: dict[str, str] = dict(document_files or {})
        # Metadata trees per root type, built lazily (the generated facades
        # will hand these in directly; until then the bridge derives them).
        self._trees: dict[str, SomMetaTree] = {}
        # The paths of the headings written by the current export, in order.
        self._heading_paths: list[str] = []
        # The document's keys of one kind, sorted once per export for _under.
        self._sorted_keys: dict[str, list[str]] = {}
        # The root the current export renders (the target of same-document
        # links).
        self._current_root: Optional[SpecRoot] = None
        # The navigation of the root the current export renders
        # (SOM §11.2, §11.11).
        self._nav: Optional[_Navigation] = None
        # The generated parts of the root the current export renders
        # (SOM §11.12).
        self._gen: Optional[_Generated] = None
        # The Blueprint's root and the model's anchor pairs (_sync_pairs).
        self._sync_pairs_cache: Optional[tuple[Optional[str], list[Any]]] = None
        # The class names each root reaches, for reference links.
        self._reach: dict[str, set[str]] = {}

    def _forced(self, path: str) -> bool:
        """Whether a generated part stands at or beneath *path* of the
        current export, which writes its heading even without a value."""
        return self._gen is not None and self._gen.forces(path)

    @property
    def _sync_pairs(self) -> tuple[Optional[str], list[Any]]:
        """The Blueprint's root and the model's anchor pairs, from the model
        alone; none when the model's synced positions cannot be paired."""
        if self._sync_pairs_cache is None:
            # Imported here: the document set reads documents, whose Markdown
            # import imports this module.
            from .spec_document_set import SpecDocumentSet, SpecDocumentSetError

            try:
                doc_set = SpecDocumentSet(self.model, [])
                self._sync_pairs_cache = (doc_set.blueprint_root, doc_set.pairs)
            except SpecDocumentSetError:
                self._sync_pairs_cache = (None, [])
        return self._sync_pairs_cache

    @staticmethod
    def heading_div_indent(depth: int) -> str:
        """A styled-div heading's indent at *depth*: ``(depth − 6) × 0.75``,
        written without a trailing ``.0`` (``0.75``, ``1.5``, ``3``)."""
        quarter = (depth - 6) * 3
        whole = quarter // 4
        rest = quarter % 4
        if rest == 0:
            return f"{whole}"
        if rest == 1:
            return f"{whole}.25"
        if rest == 2:
            return f"{whole}.5"
        return f"{whole}.75"

    @staticmethod
    def heading_div(line: str) -> Optional[tuple[int, str]]:
        """*line* read as a styled-div heading: its level (7 or more) and its
        inner text with ``&lt;``, ``&gt;`` and ``&amp;`` decoded, or
        ``None``."""
        m = SpecDocumentMarkdown.heading_div_line.match(line)
        if m is None:
            return None
        level = int(m.group(1))
        if level < 7:
            return None
        inner = m.group(2).replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
        return level, inner

    @staticmethod
    def escapable_div(line: str) -> bool:
        """Whether *line* would read as a styled-div heading after any run of
        backslashes (SOM §11.3): such a value line is written escaped, as a
        ``#`` line is."""
        k = 0
        while k < len(line) and line[k] == "\\":
            k += 1
        return SpecDocumentMarkdown.heading_div(line[k:].rstrip()) is not None

    def _sorted(self, kind: str, keys: Any) -> list[str]:
        found = self._sorted_keys.get(kind)
        if found is None:
            found = sorted(keys)
            self._sorted_keys[kind] = found
        return found

    @staticmethod
    def _item_pattern_of(node: SomMetaNode) -> Optional[str]:
        """The ``@SectionIdPattern`` the items of list *node* take their ids
        from, or ``None``."""
        pattern = node.section_id_pattern
        if not pattern and node.element_node is not None:
            pattern = node.element_node.section_id_pattern
        return pattern or None

    @staticmethod
    def _member_stem_of(node: SomMetaNode) -> str:
        """The stem of the positional ids of a pattern-less list: its member
        name, else its segment."""
        return node.member_name or node.segment

    def _tree_for(self, root_type: str) -> SomMetaTree:
        tree = self._trees.get(root_type)
        if tree is None:
            tree = build_som_meta_tree(self.model, root_type=root_type)
            self._trees[root_type] = tree
        return tree

    # --- Naming helpers (SOM §11.2 / §11.5) ------------------------------------

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
        ``@Document`` name (SOM §11.1)."""
        out = re.sub(r"[\s_]+", "-", title.strip())
        out = re.sub(r"[^A-Za-z0-9\-]", "", out)
        return out.lower()

    @staticmethod
    def item_title_stem(element_class_name: str) -> str:
        """The item heading title stem: Title-Case element class name with a
        trailing ``Entry`` dropped (SOM §11.5, normative)."""
        stem = element_class_name
        if len(stem) > 5 and stem.endswith("Entry"):
            stem = stem[:-5]
        return SpecDocumentMarkdown.title_case(stem)

    @staticmethod
    def form_label(field_name: str) -> str:
        """The ``FieldName`` label written for a form field: the model field
        name with the first letter upper-cased (SOM §11.4)."""
        if not field_name:
            return field_name
        return field_name[0].upper() + field_name[1:]

    @staticmethod
    def code_spec_of(region: str) -> str:
        """Extracts the ``codeSpec="…"`` value from a heading-comment key=value
        region (codespecs_mapping.md §9.2). Returns the empty string when the region carries no
        ``codeSpec`` key."""
        m = SpecDocumentMarkdown._code_spec_pattern.search(region)
        if m is None:
            return ""
        return (m.group(1) or m.group(2) or m.group(3) or "").strip()

    @staticmethod
    def units_of(region: str) -> str:
        """Extracts the ``units="…"`` value from a heading-comment key=value
        region (SOM §11.2): the same quoting rules as :meth:`code_spec_of` —
        double-quoted, single-quoted or bare. The key must start the region or
        follow whitespace, so a ``units=`` inside a quoted codeSpec value is not
        read as the key. Returns the empty string when the region carries no
        ``units`` key."""
        m = SpecDocumentMarkdown._units_pattern.search(region)
        if m is None:
            return ""
        return (m.group(1) or m.group(2) or m.group(3) or "").strip()

    # --- Export (SOM §11.1–§11.8) ----------------------------------------------

    def _heading_id_of(self, node: SomMetaNode) -> str:
        """The section id written into (and matched from) a heading for *node*
        (SOM §11.2/§11.8): the field-level ``@SectionId`` when present; for
        section/complex nodes whose field carries none, the target **class**'s
        ``@SectionId`` (the id the generated schema types are keyed by); else the
        path segment (the member name)."""
        if node.section_id is not None:
            return node.section_id
        # The class id is the node's class_section_id, as the YAML key uses —
        # never class_named(node.class_name): a wrapper section (TextSection,
        # ...) carries its OWNER's class name, and that lookup returned the
        # owner's id.
        if node.kind in (SomMetaKind.SECTION, SomMetaKind.COMPLEX):
            if node.class_section_id is not None:
                return node.class_section_id
        return node.segment

    # --- Transparency (SOM §11.2, mirroring the schema generator , SOM §13) ---------
    #
    # The `docspecs-schema` generator (SOM §13) is normative: only **section-bearing**
    # nodes (those with a real `@SectionId`, field- or class-level) become
    # section types; id-less members are *transparent* — they are not sections
    # of their own. The markdown format mirrors that exactly:
    #
    #   * a transparent value member (content/scalar/enum/form without an id)
    #     is emitted headinglessly into its owner's *body region* (text, or a
    #     form block of tables and `Field:` paragraphs);
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
        # class_section_id, not class_named(n.class_name): see _heading_id_of.
        # A wrapper section (TextSection, ...) has neither id, so it is
        # transparent (SOM §11.6).
        return n.class_section_id is None

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
        the headings (and item-heading owners) the generated schema knows at this
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
        Markdown document. Raises :class:`ValueError` on the two conditions
        this format cannot represent without losing the round-trip: a content
        value containing an unterminated fenced code block (which would shield
        the remainder of the document from heading detection), and a form
        holding a field the model does not declare (SOM §9,
        "Form-field order")."""
        return self.export_root_with_map(root).markdown

    #: A heading line as :meth:`_write_heading` writes it. Body text never
    #: matches: heading-like body lines are escaped (SOM §11.3) and fenced
    #: ones skipped.
    _emitted_heading = re.compile(
        r'^(?:#+ <!--\[|<div class="heading[0-9]+"[^>]*><!--\[)'
    )

    def export_root_with_map(self, root: SpecRoot) -> "SpecMarkdownRendition":
        """:meth:`export_root`, plus the document path behind every heading it
        wrote — the one place that knows which node a heading came from.

        A caller holding a rendition line (a DocSpecs schema finding, an
        editor cursor) resolves it through
        :meth:`SpecMarkdownRendition.path_at_line` instead of re-deriving the
        renderer's layout. Section ids repeat across a document, so the id
        alone does not say which node a line belongs to."""
        self._heading_paths = []
        markdown = self._export_root(root)
        heading_paths: dict[int, str] = {}
        fence = MarkdownFenceTracker()
        nxt = 0
        for i, line in enumerate(markdown.split("\n")):
            if nxt >= len(self._heading_paths):
                break
            if not fence.in_fence and self._emitted_heading.match(line):
                heading_paths[i + 1] = self._heading_paths[nxt]
                nxt += 1
            fence.feed(line)
        return SpecMarkdownRendition(markdown, heading_paths)

    def _export_root(self, root: SpecRoot) -> str:
        self._current_root = root
        self._nav = _Navigation(self, root)
        self._gen = _Generated(self._nav) if self.generated_parts else None
        self._sorted_keys.clear()
        tree = self._tree_for(root.type)
        node = tree.root
        b = _Buffer()
        b.writeln(
            f"<!-- docspec: {self.kebab_case(root.title)}/"
            f"{self.model.model_version_string} -->"
        )
        if self.readable_header is not None:
            b.writeln(self.readable_header)
        root_seg = node.segment
        self._write_heading(
            b,
            1,
            root_seg,
            self.document.headline(root_seg) or node.headline or root.title,
            path=root_seg,
            code_spec=self.document.code_spec(root_seg),
            units=self.document.units(root_seg),
        )
        self._write_section_body(b, node, root_seg)
        self._write_children(b, node, root_seg, 2)
        self._nav = None
        self._gen = None
        return resolve_linked_placeholders(resolve_derived_placeholders(str(b)))

    def _write_section_body(
        self, b: _Buffer, node: SomMetaNode, path: str
    ) -> None:
        """Writes the body region of a section heading: the section path's own
        content value plus every transparent body slot (id-less content text
        and form blocks, hoisted through transparent sections) in model
        order.

        A slot whose text the parser would otherwise bind elsewhere is
        preceded by a slot marker (SOM §11.6): text after anything already
        written, a form preamble that is not the region's default target, and
        a form whose labels another form of the region shares. A body the
        parser reads correctly without markers gets none, so such documents
        render as before."""
        slots = self._body_slots(node)
        if not slots:
            self._write_body(b, self.document.content(path), path)
            return
        form_slots = [s for s in slots if s[0].kind == SomMetaKind.FORM]
        has_forms = bool(form_slots)
        default_rel = self._default_body_rel(slots)
        written = False

        def marker(rel: str) -> None:
            b.writeln(f"<!-- slot: {rel} -->")
            b.writeln()

        def text(rel: str, value: Optional[str], value_path: str) -> None:
            nonlocal written
            if value is None:
                return
            prepared = self._prepare_value(value, value_path)
            if not prepared:
                return
            if written or rel != default_rel:
                marker(rel)
            for line in prepared.split("\n"):
                b.writeln(
                    f" {line}"
                    if has_forms and self._label_shaped.match(line)
                    else line
                )
            b.writeln()
            written = True

        def field_names(slot: SomMetaNode) -> set[str]:
            fields = slot.form.fields if slot.form is not None else []
            return {f.name.lower() for f in fields}

        text(".", self.document.content(path), path)
        for slot, rel in slots:
            slot_path = f"{path}/{rel}"
            if slot.kind != SomMetaKind.FORM:
                text(rel, self.document.content(slot_path), slot_path)
                continue
            if not self._form_has_values(slot, slot_path):
                continue
            preamble = self.document.content(slot_path)
            has_preamble = preamble is not None and bool(
                self._prepare_value(preamble, slot_path)
            )
            labels = field_names(slot)
            collides = any(
                o_rel != rel and bool(field_names(o) & labels)
                for o, o_rel in form_slots
            )
            needs_marker = (
                (written or rel != default_rel)
                if has_preamble
                else (collides and (written or form_slots[0][1] != rel))
            )
            if needs_marker:
                marker(rel)
            self._write_form(b, slot, slot_path)
            written = True

    @staticmethod
    def _default_body_rel(slots: list[tuple[SomMetaNode, str]]) -> str:
        """The body slot unmarked body text binds to on import (SOM §11.6):
        the first non-form slot; with none, the form on the ``content``
        member, else the first form; with no slot at all the owner itself
        (``.``)."""
        for slot, rel in slots:
            if slot.kind != SomMetaKind.FORM:
                return rel
        for _, rel in slots:
            if rel == "content":
                return rel
        return slots[0][1] if slots else "."

    def _is_copy_node(self, n: SomMetaNode) -> bool:
        """Whether *n* is a ``@SameAs`` copy (SOM §11.2): its anchor and its
        descendants' are qualified with the section above it."""
        parent = n._parent
        if not n.member_name or parent is None:
            return False
        cls = self.model.class_named(parent.class_name)
        f = cls.field_named(n.member_name) if cls is not None else None
        return f is not None and f.has_annotation("SameAs")

    def _item_form(
        self, element: SomMetaNode
    ) -> Optional[tuple[SomMetaNode, str]]:
        """The item class's own form (its class-level ``@Form``, a
        transparent body slot), or ``None`` when the class carries none or
        more than one."""
        found: Optional[tuple[SomMetaNode, str]] = None
        for s in self._body_slots(element):
            if s[0].kind == SomMetaKind.FORM:
                if found is not None:
                    return None
                found = s
        return found

    def _write_children(
        self, b: _Buffer, node: SomMetaNode, base_path: str, depth: int
    ) -> None:
        for child, rel in self._effective_children(node):
            path = f"{base_path}/{rel}"
            if not self.document.has_values_under(path) and not self._forced(path):
                continue
            kind = child.kind
            if kind in (
                SomMetaKind.CONTENT,
                SomMetaKind.SCALAR,
                SomMetaKind.ENUM_VALUE,
            ):
                value = self.document.content(path)
                if value is None and not self._forced(path):
                    continue
                self._write_heading(
                    b,
                    depth,
                    self._heading_id_of(child),
                    self.document.headline(path) or self._title_of(child),
                    path=path,
                    code_spec=self.document.code_spec(path),
                    units=self.document.units(path),
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
                    path=path,
                    code_spec=self.document.code_spec(path),
                    units=self.document.units(path),
                )
                self._write_form(b, child, path)
            elif kind in (SomMetaKind.SECTION, SomMetaKind.COMPLEX):
                self._write_heading(
                    b,
                    depth,
                    self._heading_id_of(child),
                    self.document.headline(path) or self._title_of(child),
                    path=path,
                    code_spec=self.document.code_spec(path),
                    units=self.document.units(path),
                    section_table=self._write_section_table(_Buffer(), child, path),
                )
                self._write_section_body(b, child, path)
                if not self._write_section_table(b, child, path):
                    self._write_children(b, child, path, depth + 1)
            elif kind == SomMetaKind.LIST:
                self._write_list_items(b, child, path, depth)

    def _write_list_items(
        self, b: _Buffer, node: SomMetaNode, list_path: str, depth: int
    ) -> None:
        """Emits list *node* as its ``-LST`` container heading (SOM §11.2/§11.5)
        at *depth*, wrapping the numbered item headings one level deeper. The
        container is a real section — the id the generated schema keys its container
        type by — but carries **no content of its own** (schema content
        min/max-text-length 0). Item identity is the stored id when one
        exists, else positional (YRD3)."""
        items = self.document.list_items(list_path)
        if not items and not self._forced(list_path):
            return
        # The container heading: its id is the list's `-LST` `@SectionId` (else
        # the member segment for a pattern-less list); its title is the stored
        # headline, else the member name.
        self._write_heading(
            b,
            depth,
            self._heading_id_of(node),
            self.document.headline(list_path) or self._title_of(node),
            path=list_path,
            code_spec=self.document.code_spec(list_path),
            units=self.document.units(list_path),
        )
        # Item heading stem. Complex lists derive it from the element class name
        # (SOM §11.5, `Entry` dropped). A scalar list (shape 6) has no element
        # class - its element ``type_name`` is literally ``String``, which would
        # render "String 1", "String 2". Derive the stem from the list FIELD
        # instead (its member name, Title-Cased like the container heading) so a
        # populated scalar list gets meaningful per-item headings (YRC5).
        stem = self._item_stem_of(node)
        element = node.element_node
        pattern = self._item_pattern_of(node)
        if self._write_reference_line(
            b, node, items, pattern
        ) or self._write_record_table(b, node, items, pattern):
            return
        for i, item_path in enumerate(items):
            pos = i + 1
            # YRD3: the heading id is the item's STORED
            # section id when one exists (an AA1 generated id or a criterion-5
            # override); only anonymous items fall back to the positional id —
            # the `@SectionIdPattern` resolved with the 1-based position
            # (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`), else `<member>-<pos>` for a
            # pattern-less list. On parse, numbered-pattern ids recover
            # membership and order from position; other pattern-shaped ids
            # parse back as stored ids. Items sit one level below the
            # container.
            item_id = effective_list_item_section_id(
                stored_id=self.document.item_section_id(item_path),
                pattern=pattern,
                position=pos,
                fallback_stem=self._member_stem_of(node),
            )
            self._write_heading(
                b,
                depth + 1,
                item_id,
                self.document.headline(item_path) or f"{stem} {pos}",
                path=item_path,
                code_spec=self.document.code_spec(item_path),
                units=self.document.units(item_path),
                section_table=element is not None
                and not element.recursive
                and self._write_section_table(_Buffer(), element, item_path),
            )
            if element is None:
                # Scalar list: the item's value is its body.
                self._write_body(
                    b, self.document.content(item_path) or "", item_path
                )
            else:
                self._write_section_body(b, element, item_path)
                if not element.recursive and not self._write_section_table(
                    b, element, item_path
                ):
                    self._write_children(b, element, item_path, depth + 2)

    # --- Reading view: reference lines, record tables, section tables -------

    def _has_keys(self, path: str) -> bool:
        return bool(self.document.code_spec(path)) or bool(
            self.document.units(path)
        )

    def _anchor_for(self, path: str, id: str) -> str:
        """The anchor of the heading or table row standing for *path*."""
        return self._nav.anchor_of(path) if self._nav is not None else id

    def _is_form_only_item(
        self,
        form: SomMetaNode,
        item_path: str,
        form_path: str,
        allow_headline: bool,
    ) -> bool:
        """Whether the item at *item_path* holds values only in its form at
        *form_path*, all of them table cells: no preamble, no other content,
        form or list, no ``codeSpec`` / ``units``, no headline other than the
        item's own when *allow_headline*."""
        doc = self.document
        if _under(self._sorted("content", doc.content_paths), item_path):
            return False
        if _under(self._sorted("lists", doc.list_paths), item_path):
            return False
        if _under(self._sorted("units", doc.units_paths), item_path):
            return False
        for k in _under(self._sorted("forms", doc.form_paths), item_path):
            if k != form_path:
                return False
        for h in _under(
            self._sorted("headlines", doc.headline_paths), item_path
        ):
            if not allow_headline or h != item_path:
                return False
        if self._has_keys(item_path) or self._has_keys(form_path):
            return False
        if self._undeclared_form_fields(form, form_path):
            return False
        any_value = False
        for f in _fields_of(form):
            value = doc.form_field(form_path, f.name)
            if value is None:
                continue
            if not self._is_cell_value(f, value):
                return False
            any_value = True
        return any_value

    def _write_reference_line(
        self,
        b: _Buffer,
        node: SomMetaNode,
        items: list[str],
        pattern: Optional[str],
    ) -> bool:
        """A list whose every item holds only one reference id becomes one
        ``refs`` div of links in list order. All or nothing; returns whether
        it was written."""
        element = node.element_node
        if element is None or element.recursive:
            return False
        ref: Optional[tuple[SomMetaNode, str]] = None
        for c, rel in self._effective_children(element):
            fields = _fields_of(c)
            if (
                c.kind != SomMetaKind.FORM
                or len(fields) != 1
                or not fields[0].refers_to
            ):
                continue
            if any(e.annotation == "Reference" for e in c.extra):
                ref = (c, rel)
                break
        if ref is None:
            return False
        ref_node, ref_rel = ref
        field = _fields_of(ref_node)[0]
        doc = self.document
        links: list[str] = []
        for i, item_path in enumerate(items):
            ref_path = f"{item_path}/{ref_rel}"
            stored = doc.item_section_id(item_path)
            positional = effective_list_item_section_id(
                stored_id=None,
                pattern=pattern,
                position=i + 1,
                fallback_stem=self._member_stem_of(node),
            )
            if stored is not None and stored != positional:
                return False
            if (
                _under(self._sorted("content", doc.content_paths), item_path)
                or _under(self._sorted("lists", doc.list_paths), item_path)
                or _under(self._sorted("units", doc.units_paths), item_path)
                or _under(
                    self._sorted("headlines", doc.headline_paths), item_path
                )
                or self._has_keys(item_path)
                or self._has_keys(ref_path)
            ):
                return False
            for k in _under(self._sorted("forms", doc.form_paths), item_path):
                if k != ref_path:
                    return False
            names = set(doc.form_field_names(ref_path))
            if names != {field.name}:
                return False
            raw = doc.form_field(ref_path, field.name)
            id = _trim_ws(raw or "")
            if not _ID_SHAPE.fullmatch(id):
                return False
            link = self._link(field, id)
            links.append(link if link is not None else id)
        b.writeln("::: {.refs}")
        b.writeln(", ".join(links))
        b.writeln(":::")
        b.writeln()
        return True

    def _write_record_table(
        self,
        b: _Buffer,
        node: SomMetaNode,
        items: list[str],
        pattern: Optional[str],
    ) -> bool:
        """A list whose every item is one form of table cells becomes a
        ``records`` div with one table: ``Id`` (with its anchor), ``Title``
        when any item has a stored headline, one column per declared field any
        item populates. All or nothing; returns whether it was written."""
        element = node.element_node
        if element is None or element.recursive:
            return False
        form_slot = self._item_form(element)
        if form_slot is None:
            return False
        form, rel = form_slot
        for item_path in items:
            if not self._is_form_only_item(
                form, item_path, f"{item_path}/{rel}", True
            ):
                return False
        doc = self.document
        columns = [
            f
            for f in _fields_of(form)
            if any(doc.form_field(f"{i}/{rel}", f.name) is not None for i in items)
        ]
        with_title = any(doc.headline(i) is not None for i in items)
        header = ["Id"]
        if with_title:
            header.append("Title")
        header.extend(self.form_label(f.name) for f in columns)
        b.writeln("::: {.records}")
        b.writeln("| " + " | ".join(header) + " |")
        b.writeln("| " + " | ".join(["---"] * len(header)) + " |")
        for i, item_path in enumerate(items):
            id = effective_list_item_section_id(
                stored_id=doc.item_section_id(item_path),
                pattern=pattern,
                position=i + 1,
                fallback_stem=self._member_stem_of(node),
            )
            # A summary naming its detail element by its own id links it from
            # the Id cell (SOM §11.5, §11.11).
            list_path = item_path[: item_path.rfind("-")]
            cell = (
                self._nav.summary_id_cell(item_path, list_path, id)
                if self._nav is not None
                else None
            )
            cells = [
                cell
                if cell is not None
                else f'<a id="{self._anchor_for(item_path, id)}"></a>{id}'
            ]
            if with_title:
                title = doc.headline(item_path) or ""
                cells.append(title.replace("\n", "<br>").replace("|", "\\|"))
            for f in columns:
                v = doc.form_field(f"{item_path}/{rel}", f.name)
                cells.append("" if v is None else self._linked_cell_text(f, v))
            b.writeln("| " + " | ".join(cells) + " |")
        b.writeln(":::")
        b.writeln()
        return True

    def _add_section_rows(
        self,
        rows: list[str],
        section_cell: str,
        form: SomMetaNode,
        form_path: str,
    ) -> None:
        first = True
        for f in _fields_of(form):
            value = self.document.form_field(form_path, f.name)
            if value is None:
                continue
            rows.append(
                f"| {section_cell if first else ''} | {self.form_label(f.name)}"
                f" | {self._linked_cell_text(f, value)} |"
            )
            first = False

    def _write_section_table(
        self, b: _Buffer, node: SomMetaNode, path: str
    ) -> bool:
        """A section whose populated children are all single forms of table
        cells with default headlines (or lists of such single-form items)
        becomes one ``| Section | TomSpecField | Value |`` table after its own
        body; the children's headings are not written. All or nothing;
        returns whether it was written."""
        doc = self.document
        rows: list[str] = []
        children = 0
        for child, rel in self._effective_children(node):
            child_path = f"{path}/{rel}"
            if not doc.has_values_under(child_path):
                continue
            children += 1
            child_id = self._heading_id_of(child)
            if child.kind == SomMetaKind.FORM:
                if not self._is_form_only_item(
                    child, child_path, child_path, False
                ):
                    return False
                self._add_section_rows(
                    rows,
                    f'<a id="{self._anchor_for(child_path, child_id)}"></a>'
                    f"{child_id}",
                    child,
                    child_path,
                )
            elif child.kind == SomMetaKind.LIST:
                element = child.element_node
                if element is None or element.recursive:
                    return False
                if doc.headline(child_path) is not None or self._has_keys(
                    child_path
                ):
                    return False
                form_slot = self._item_form(element)
                if form_slot is None:
                    return False
                slot_node, slot_rel = form_slot
                items = doc.list_items(child_path)
                pattern = self._item_pattern_of(child)
                for i, item_path in enumerate(items):
                    form_path = f"{item_path}/{slot_rel}"
                    if not self._is_form_only_item(
                        slot_node, item_path, form_path, False
                    ):
                        return False
                    item_id = effective_list_item_section_id(
                        stored_id=doc.item_section_id(item_path),
                        pattern=pattern,
                        position=i + 1,
                        fallback_stem=self._member_stem_of(child),
                    )
                    self._add_section_rows(
                        rows,
                        f'<a id="{self._anchor_for(item_path, item_id)}"></a>'
                        f"{child_id} / {item_id}",
                        slot_node,
                        form_path,
                    )
            else:
                return False
        if children == 0 or not rows:
            return False
        b.writeln("| Section | TomSpecField | Value |")
        b.writeln("| --- | --- | --- |")
        for row in rows:
            b.writeln(row)
        b.writeln()
        return True

    def _linked_cell_text(self, f: Any, value: str) -> str:
        """*value* as a table cell, every reference id of a ``refersTo`` field
        written as a link to its section."""
        if not f.refers_to or f.code:
            return self._cell_text(f, value)
        joined = self.wrapped_paragraph_joined(value)
        if joined is not None:
            value = joined
        links: list[str] = []
        for part in value.split(","):
            id = _trim_ws(part)
            if not _ID_SHAPE.fullmatch(id):
                return self._cell_text(f, value)
            link = self._link(f, id)
            if link is None:
                return self._cell_text(f, value)
            links.append(link)
        return ", ".join(links)

    def _link(self, f: Any, id: str) -> Optional[str]:
        """``[ID](<file>#ID)`` for a reference id of form field *f*,
        ``[ID](#ID)`` when the target lives in the document being rendered;
        ``None`` when no target of *f* names a section id
        (``<SECTIONID>.@sectionId``), which has no anchor."""
        class_ids = [
            t[: -len(".@sectionId")]
            for t in f.refers_to
            if t.endswith(".@sectionId")
        ]
        if not class_ids:
            return None
        for class_id in class_ids:
            class_name = self._class_by_section_id(class_id)
            if (
                class_name is not None
                and self._current_root is not None
                and class_name in self._reached_by(self._current_root)
            ):
                return f"[{id}](#{id})"
        file = self._file_for(self._class_by_section_id(class_ids[0]))
        return f"[{id}](#{id})" if file is None else f"[{id}]({file}#{id})"

    def _class_by_section_id(self, section_id: str) -> Optional[str]:
        for c in self.model.classes.values():
            if c.section_id == section_id:
                return c.name
        return None

    def _reached_by(self, root: SpecRoot) -> set[str]:
        """The class names the meta tree of *root* reaches."""
        names = self._reach.get(root.type)
        if names is None:
            names = set()
            stack = [self._tree_for(root.type).root]
            while stack:
                n = stack.pop()
                names.add(n.class_name)
                if n.recursive:
                    continue
                stack.extend(n.children)
                if n.element_node is not None:
                    stack.append(n.element_node)
            self._reach[root.type] = names
        return names

    def _file_for(self, class_name: Optional[str]) -> Optional[str]:
        """The rendition file of the root a reference to *class_name* points
        into: the root other than the current one that reaches the class, the
        most specific (fewest classes) first, so a detailed document wins over
        a projection such as the Solution Blueprint. The CodeSpecs projection
        is no document anyone renders, so it is never a target."""
        if class_name is None:
            return None
        current_type = (
            self._current_root.type if self._current_root is not None else None
        )
        best: Optional[SpecRoot] = None
        for r in self.model.roots:
            if r.type == current_type:
                continue
            cls = self.model.class_named(r.type)
            if cls is not None and cls.has_annotation("CodeSpecsProjection"):
                continue
            if class_name not in self._reached_by(r):
                continue
            if best is None or len(self._reached_by(r)) < len(
                self._reached_by(best)
            ):
                best = r
        return None if best is None else self._file_of_root(best)

    def _file_of_root(self, root: SpecRoot) -> str:
        """The rendition file of *root*: ``<file_stem>.<root id>.tomspecs.md``,
        or the name :attr:`document_files` gives it."""
        id = root.section_id if root.section_id is not None else root.type
        mapped = self.document_files.get(id)
        if mapped is None:
            mapped = self.document_files.get(root.type)
        if mapped is not None:
            return mapped
        name = f"{id.lower()}.tomspecs.md"
        return f"{self.file_stem}.{name}" if self.file_stem else name

    @classmethod
    def _is_cell_value(cls, f: Any, value: str) -> bool:
        """Whether *value* of form field *f* is written as a table row: not
        when the model flags the field ``multiParagraph``, nor when the value
        holds a line break other than the soft breaks of one wrapped paragraph
        (:meth:`wrapped_paragraph_joined`; a ``code`` value keeps every line
        break), is a block of Markdown, holds a backslash directly before
        ``|``, or holds ``<!--``. There is no length limit."""
        if f.multi_paragraph:
            return False
        if "\\|" in value or "<!--" in value:
            return False
        if "\n" in value and (
            f.code or cls.wrapped_paragraph_joined(value) is None
        ):
            return False
        return _BLOCK_START.match(value) is None

    @staticmethod
    def wrapped_paragraph_joined(value: str) -> Optional[str]:
        """*value* on one line when it is one paragraph wrapped over several
        lines — no blank line, and no line that Markdown reads as a block or a
        block's start (a list item, a quote, a fence, a fenced div, a table
        row, a heading, a setext underline or a thematic break), that ends in
        a hard break (a trailing backslash or spaces) or that starts with a
        space: its soft line breaks, which Markdown reads as spaces, become
        spaces (SOM §11.4 rule 13). ``None`` for any other value, a one-line
        value among them."""
        if "\n" not in value:
            return None
        lines = value.split("\n")
        for line in lines:
            if (
                not line
                or line != _trim_ws(line)
                or line.endswith("\\")
                or _BLOCK_START.match(line)
                or _WRAPPED_LINE_BLOCK.match(line)
            ):
                return None
        return " ".join(lines)

    @classmethod
    def _cell_text(cls, f: Any, value: str) -> str:
        """The table cell for *value*: a ``code: true`` value as its inline
        code span, every ``|`` written ``\\|``."""
        joined = cls.wrapped_paragraph_joined(value)
        if joined is not None:
            value = joined
        text = (
            cls._encode_code_span(value)
            if f.code and cls._is_inline_code(value)
            else value
        )
        return text.replace("|", "\\|")

    def _undeclared_form_fields(self, node: SomMetaNode, path: str) -> list:
        """The stored field names at form *path* that *node* does not declare,
        sorted (SOM §9, "Form-field order").

        The emit walk is meta-driven — it iterates the model's declared fields
        — so a stored field the model does not know is invisible to it and
        cannot be dropped *loudly*. Seeing it at all needs this deliberate
        reverse check: store keys minus meta keys, which is the check the yaml
        codec already has (SOM §12.8)."""
        fields = node.form.fields if node.form is not None else []
        declared = {f.name for f in fields}
        return sorted(
            n for n in self.document.form_field_names(path) if n not in declared
        )

    def _check_form_declared(self, node: SomMetaNode, path: str) -> None:
        """Raises when the form at *path* holds a field the model does not
        declare (SOM §9, "Form-field order" — md refuses, matching yaml).

        Emitting it is impossible: the DocSpecs markdown grammar has no
        spelling for a field outside the model, and omitting it would lose a
        stored value in a file that looks complete. On import a partial
        document is normal and the codec reports-and-skips (SOM §11.7); on
        export the document is complete and a lossy rendering is a trap, so the
        codec refuses instead."""
        undeclared = self._undeclared_form_fields(node, path)
        if not undeclared:
            return
        raise ValueError(
            f'form at "{path}" holds a field "{undeclared[0]}" unknown to the '
            "model; it cannot be represented in the DocSpecs markdown format"
        )

    def _form_has_values(self, node: SomMetaNode, path: str) -> bool:
        """Whether the ``@Form`` node at *path* has anything to emit: its
        preamble content (SOM §11.4 rule 7 — the DocSpecs ``${text[]}``
        region), or any populated field.

        An undeclared stored field counts too — not because it can be emitted,
        but so the section is still *visited* and :meth:`_write_form` refuses.
        Without it a form holding nothing but undeclared fields would vanish
        unseen, which is the silent drop this check exists to prevent."""
        if self.document.has_content(path):
            return True
        fields = node.form.fields if node.form is not None else []
        for f in fields:
            if self.document.form_field(path, f.name) is not None:
                return True
        return bool(self._undeclared_form_fields(node, path))

    def _write_form(self, b: _Buffer, node: SomMetaNode, path: str) -> None:
        """Writes a ``@Form`` section body (SOM §11.4): the preamble, then the
        declared fields in model order — each run of consecutive cell values
        one ``| TomSpecField | Value |`` table, each paragraph value a
        ``Field:`` group at its place (table – text – table). Groups are one
        blank line apart. A value line that would read as a table header is
        escaped by :meth:`_prepare_value`. Raises :class:`ValueError` when the
        form holds a field the model does not declare."""
        self._check_form_declared(node, path)
        groups: list[list[str]] = []
        table: Optional[list[str]] = None
        for f in _fields_of(node):
            value = self.document.form_field(path, f.name)
            if value is None:
                continue
            label = self.form_label(f.name)
            if self._is_cell_value(f, value):
                if table is None:
                    table = ["| TomSpecField | Value |", "| --- | --- |"]
                    groups.append(table)
                table.append(
                    f"| {label} | {self._linked_cell_text(f, value)} |"
                )
                continue
            table = None
            # SOM §11.4 rule 8: a single-line code value is written as an
            # inline code span, so markdown leaves it literal (`](` is not a
            # link).
            lines = (
                [self._encode_code_span(value)]
                if f.code and self._is_inline_code(value)
                else self._prepare_value(value, path).split("\n")
            )
            group = [f"{label}: {lines[0]}"]
            for line in lines[1:]:
                # Any continuation line that could be mistaken for a
                # field-label line gains one leading space; parse strips it.
                group.append(
                    f" {line}" if self._label_shaped.match(line) else line
                )
            groups.append(group)

        preamble = self.document.content(path)
        if preamble is not None:
            prepared = self._prepare_value(preamble, path)
            if prepared:
                # Every preamble line gets the same label-shaped escape a
                # continuation line gets: the parser reaches a field label
                # before it knows which text is preamble, so a `Word:` line at
                # column 0 would mis-split.
                for line in prepared.split("\n"):
                    b.writeln(
                        f" {line}" if self._label_shaped.match(line) else line
                    )
                if groups:
                    b.writeln()
        for i, group in enumerate(groups):
            if i > 0:
                b.writeln()
            for line in group:
                b.writeln(line)
        b.writeln()

    def _write_heading(
        self,
        b: _Buffer,
        depth: int,
        id: str,
        title: str,
        *,
        path: str,
        code_spec: Optional[str] = None,
        units: Optional[str] = None,
        section_table: bool = False,
    ) -> None:
        """``## <!--[ID]--> <a id="ID"></a> Title`` at *depth*. SOM §11.2 is
        normative —
        heading level = 1 + section depth, **uncapped**: deep models (the
        Solution Blueprint nests past markdown's native 6 levels) keep their
        structure; the parse grammar accepts ``#{7,}`` accordingly. Capping
        would silently flatten distinct nesting positions into siblings and
        break schema validation.

        When *code_spec* is non-empty it is emitted as a ``codeSpec="…"`` key
        inside the same headline comment (codespecs_mapping.md §9.2):
        ``## <!--[ID] codeSpec="A,B"--> Title``. When *units* is non-empty it
        follows as a second key, ``units="…"``, after ``codeSpec`` (SOM
        §11.2).

        The ``linked`` marker follows the heading (SOM §11.11), then a
        generated table opening its section (SOM §11.12). *section_table*:
        the heading's children are written as a section table."""
        self._heading_paths.append(path)
        nav = self._nav

        def derived() -> None:
            gen = self._gen
            if gen is None or not gen.is_place(path):
                return
            block = gen.blocks.get(path)
            if block is not None:
                for line in block:
                    b.writeln(line)
            else:
                b.writeln(K_DERIVED_PLACEHOLDER)
            b.writeln()

        def marker() -> None:
            if nav is None or not self.linked_markers:
                return
            entries = nav.entries(path, section_table)
            if entries:
                b.writeln(f"[{'; '.join(entries)}]{{.linked}}")
                b.writeln()
            elif nav.markable(path):
                b.writeln(K_LINKED_PLACEHOLDER)
                b.writeln()

        code = f' codeSpec="{code_spec}"' if code_spec else ""
        if units:
            code += f' units="{units}"'
        # A heading is one line: a stored headline's line breaks travel as
        # ``<br>``. The section id follows as an HTML anchor after the id
        # comment and its keys, so `#<ID>` links jump in every viewer; below a
        # list item or in a `@SameAs` copy the anchor is qualified (SOM §11.2).
        anchor = self._anchor_for(path, id)
        if self.heading_divs and depth > 6:
            # A styled-div heading (SOM §11.2, DocSpecs *Styled-div
            # headings*): one line, the title HTML-escaped, the indent
            # growing with the depth.
            escaped = (
                title.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\n", "<br>")
            )
            b.writeln(
                f'<div class="heading{depth}" style="{self.heading_div_style_start}'
                f'{self.heading_div_indent(depth)}em;font-weight:bold">'
                f'<!--[{id}]{code}--> <a id="{anchor}"></a> {escaped}</div>'
            )
            b.writeln()
            marker()
            derived()
            return
        b.writeln(
            f"{'#' * depth} <!--[{id}]{code}--> <a id=\"{anchor}\"></a> "
            f"{title.replace(chr(10), '<br>')}"
        )
        b.writeln()
        marker()
        derived()

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

    @staticmethod
    def _is_inline_code(value: str) -> bool:
        """Whether a code field's *value* is written as an inline code span:
        it is non-empty and on one line. A multi-line value keeps the prose
        rendering — a code span cannot cross a line break without markdown
        joining the lines."""
        return bool(value) and "\n" not in value

    @staticmethod
    def _encode_code_span(value: str) -> str:
        """*value* as a CommonMark inline code span: delimited by one backtick
        more than the longest backtick run inside it, and padded with one
        space on each side when it begins or ends with a backtick or a space —
        the padding CommonMark strips again, so the span's content is exactly
        *value*."""
        longest = max((len(m) for m in re.findall(r"`+", value)), default=0)
        fence = "`" * (longest + 1)
        pad = " " if re.search(r"^[` ]|[` ]$", value) else ""
        return f"{fence}{pad}{value}{pad}{fence}"

    def _prepare_value(self, value: str, path: str) -> str:
        """Emit-side value normalisation (SOM §11.3): trim leading/trailing
        blank lines, escape heading-like lines outside fences. Blank lines
        inside the value are kept. Raises :class:`ValueError` for an
        unterminated fence."""
        collapsed = re.sub(r"^\n+", "", value)
        collapsed = re.sub(r"\n+$", "", collapsed)
        fence = MarkdownFenceTracker()
        out: list[str] = []
        for line in collapsed.split("\n"):
            if fence.in_fence:
                out.append(line)  # SOM §11.3: fences shield their lines.
            elif self._escapable.match(line) or self.escapable_div(line):
                out.append(f"\\{line}")
            elif _TABLE_HEADER_SHAPED.match(line):
                out.append(f" {line}")  # a value line is never a layout table.
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
        element class's ``@Headline`` default when authored, else the SOM §11.5 derivation (element class name with ``Entry`` dropped; member
        name for scalar lists)."""
        element = node.element_node
        if element is not None:
            return element.headline or SpecDocumentMarkdown.item_title_stem(
                element.class_name
            )
        return SpecDocumentMarkdown.title_case(
            node.member_name or node.segment
        )

    # --- Import (SOM §11.7) ----------------------------------------------------

    def parse(self, text: str) -> SpecMarkdownResult:
        """Parses *text* into staged values + a rejection report, **without**
        mutating the document. :meth:`SpecDocument.apply_markdown_result` applies the result as a full
        overwrite."""
        p = _Parser(self)
        p.run(text.split("\n"))
        return SpecMarkdownResult(
            content=p.content,
            forms=p.forms,
            lists=p.lists_json(),
            headlines=p.headlines,
            code_specs=p.code_specs,
            units=p.units,
            rejections=p.rejections,
            root_prefixes=p.root_prefixes,
            kept_content=p.kept_content,
            readable_header=p.readable_header,
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
        # The scope this heading's descendants' anchors are qualified with,
        # and the id of the nearest heading at or above it that is no list
        # container (SOM §11.2, _qualify_anchor).
        self.anchor_scope: Optional[list[str]] = None
        self.anchor_section: Optional[str] = None
        # Whether its body opened with a generated block (SOM §11.12): the
        # heading stands for the block, so an empty value is no rejection.
        self.generated = False
        # Rejected blocks to keep in this frame's text (RN-11): the body index
        # they stand before, the block, and the end of the body lines it
        # replaces (the index itself when it replaces none).
        self.kept: list[_KeptMark] = []
        # For an ignored frame: the blocks of its ignored children, kept after
        # its own block wherever that lands.
        self.deferred: list[_KeptBlock] = []


_KEPT_DIV_OPEN = re.compile(
    r"^ {0,3}:{3,}[ \t]*(?:\{.*\}|[A-Za-z][A-Za-z0-9_-]*)[ \t]*\Z"
)
_KEPT_DIV_CLOSE = re.compile(r"^ {0,3}:{3,}[ \t]*\Z")
_KEPT_COLONS = re.compile(r"^ {0,3}(:{3,})")
_KEPT_FIRST_COLON = re.compile(r"^( {0,3}):")
_NEAR_MISS_SEPARATORS = re.compile(_WS + "|[_-]")


class _KeptBlock:
    """A rejected block an import that accepts rejections keeps for review
    (SOM §11.7, DocSpecs RN-11): the source lines it held and what its
    ``rejected`` div records for a resolution."""

    def __init__(
        self,
        rejection: SpecMarkdownRejection,
        lines: list[str],
        field: Optional[str] = None,
        section: Optional[str] = None,
        kept: Optional[str] = None,
    ) -> None:
        self.rejection = rejection
        #: The source lines of the block, as written.
        self.lines = lines
        #: The field given twice, or the declared field a near-miss label
        #: names.
        self.field = field
        #: The child section a near-miss section-table cell names.
        self.section = section
        #: For a field given twice: the path of the form holding the kept
        #: value.
        self.kept = kept

    def div(self) -> list[str]:
        """The block as a ``rejected`` div: ``reason``, ``line``, then
        ``field`` / ``section`` / ``kept`` where they apply, then ``label``
        (the report's message, its double quotes written as single ones). A
        fence the block does not close, or closes without opening, would pair
        with the div's own fences, so it is written escaped (``\\:::``,
        RN-9); the div's fences are longer than any fence inside it, for the
        eye (RN-7)."""
        inner = list(self.lines)
        while inner and not _trim_ws(inner[0]):
            inner.pop(0)
        while inner and not _trim_ws(inner[-1]):
            inner.pop()
        fence = MarkdownFenceTracker()
        open_: list[int] = []
        unpaired: set[int] = set()
        for k, line in enumerate(inner):
            if not fence.in_fence:
                if _KEPT_DIV_CLOSE.match(line):
                    if not open_:
                        unpaired.add(k)
                    else:
                        open_.pop()
                elif _KEPT_DIV_OPEN.match(line):
                    open_.append(k)
            fence.feed(line)
        unpaired.update(open_)
        longest = 0
        for k in range(len(inner)):
            if k in unpaired:
                inner[k] = _KEPT_FIRST_COLON.sub(r"\1\\:", inner[k], count=1)
                continue
            m = _KEPT_COLONS.match(inner[k])
            run = len(m.group(1)) if m is not None else 0
            if run > longest:
                longest = run
        colons = ":" * (longest + 1 if longest >= 3 else 3)

        def quoted(s: str) -> str:
            return s.replace('"', "'")

        r = self.rejection
        attributes = f'reason="{r.reason.value}" line="{r.line}"'
        if self.field is not None:
            attributes += f' field="{quoted(self.field)}"'
        if self.section is not None:
            attributes += f' section="{quoted(self.section)}"'
        if self.kept is not None:
            attributes += f' kept="{quoted(self.kept)}"'
        attributes += f' label="{quoted(r.message)}"'
        return [f"{colons} {{.rejected {attributes}}}", *inner, colons]


class _KeptMark:
    """A kept block's place in a frame's body: before :attr:`at`, replacing
    the lines up to :attr:`end`."""

    def __init__(self, at: int, block: _KeptBlock, end: int) -> None:
        self.at = at
        self.block = block
        self.end = end


def _merge_kept(
    part: list[str],
    ins: list[tuple[int, list[str]]],
    replaced: set[int],
) -> list[str]:
    """*part* with the divs of *ins* (``(position, div lines)``) written in at
    their positions, a blank line between a div and the text around it; the
    lines at *replaced* positions are left out (a div took their place)."""
    out: list[str] = []
    blank_due = False
    for k in range(len(part) + 1):
        for at, div in ins:
            if at != k:
                continue
            if out and _trim_ws(out[-1]):
                out.append("")
            out.extend(div)
            blank_due = True
        if k == len(part) or k in replaced:
            continue
        line = part[k]
        if blank_due and _trim_ws(line):
            out.append("")
        blank_due = False
        out.append(line)
    return out


class _Keeper:
    """Where the rejected blocks of one frame's body go (RN-11): each content
    line list of the frame and the divs written into it, by position."""

    def __init__(self, frame: _Frame) -> None:
        # Stable: blocks at one place keep their order.
        self._marks = sorted(frame.kept, key=lambda m: m.at)
        self._next = 0
        # Keyed by the line list itself (its identity), not by its lines.
        self._inserts: dict[int, list[tuple[int, list[str]]]] = {}

    def keep(self, into: list[str], b: _KeptBlock) -> None:
        """Writes *b* into *into* at its current end."""
        self._inserts.setdefault(id(into), []).append((len(into), b.div()))

    def drain(self, up_to: int, into: list[str]) -> None:
        """Writes the frame's blocks standing before body index *up_to* into
        *into*."""
        while (
            self._next < len(self._marks)
            and self._marks[self._next].at <= up_to
        ):
            self.keep(into, self._marks[self._next].block)
            self._next += 1

    def kept_value(self, parts: list[list[str]]) -> Optional[str]:
        """The value of *parts* with the kept divs written in, joined as the
        parts are; ``None`` when no part holds one."""
        if not any(id(part) in self._inserts for part in parts):
            return None
        values: list[str] = []
        for part in parts:
            ins = self._inserts.get(id(part))
            v = _Parser._restore_value(
                part if ins is None else _merge_kept(part, ins, set())
            )
            if v:
                values.append(v)
        return "\n\n".join(values)


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
#: A slot marker line (SOM §11.6): ``<!-- slot: <rel> -->``, ``<rel>`` a body
#: slot's path relative to its owner, or ``.`` for the owner itself.
_SLOT_MARKER = re.compile(r"^<!-- slot: (\S+) -->$")
_ESCAPED_HEADING = re.compile(r"^\\+#")

# Reading view (SOM §11.4, §11.5): a value line shaped like a layout table
# header is escaped with one space on emit, and loses it on parse.
_TABLE_HEADER_SHAPED = re.compile(
    r"^ *\|\s*(?:Section\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$",
    re.IGNORECASE,
)
_ESCAPED_TABLE_HEADER = re.compile(
    r"^ +\|\s*(?:Section\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$",
    re.IGNORECASE,
)
_LAYOUT_TABLE_HEADER = SpecDocumentMarkdown.layout_table_header
# A line that starts a table row: `|` after up to three spaces.
_TABLE_LINE = re.compile(r"^ {0,3}\|")
_DELIMITER_CELL = re.compile(r"^:?-+:?$")
_LINK_CELL = re.compile(
    r"^\[[^\]]+\]\([^)]*\)(, \[[^\]]+\]\([^)]*\))*$"
)
_LINK_TEXT = re.compile(r"\[([^\]]+)\]\([^)]*\)")
_LIST_DIV_OPEN = re.compile(
    r"^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$"
)
_DIV_CLOSE = re.compile(r"^:{3,}\s*$")
_CELL_ANCHOR = re.compile(r'^<a id="[^"]*"></a>\s*')
_CELL_LINK = re.compile(r"^\[([^\]]+)\]\([^)\s]*\)$")
_SECTION_CELL_SEP = re.compile(r"\s*/\s*")
_REF_SEP = re.compile(r"[,\s]+")

def _title_without_anchor(raw_title: str, id: str, anchor: str) -> str:
    """A heading title without the renderer's anchor — ``<a id="…"></a>``
    naming *id* or its qualified form *anchor* (SOM §11.2) — and with
    ``<br>`` read as a line break."""
    p = re.compile(
        '^<a id="(?:' + re.escape(id) + "|" + re.escape(anchor) + ')"></a>\\s*'
    )
    return p.sub("", raw_title, count=1).replace("<br>", "\n")


def _row_cells(line: str) -> list[str]:
    """The cells of a table row: split on every ``|`` not preceded by a
    backslash, the outer pipes dropped, each cell trimmed; ``\\|`` stays in
    the cell."""
    t = line.strip()
    if t.startswith("|"):
        t = t[1:]
    if t.endswith("|") and not t.endswith("\\|"):
        t = t[:-1]
    cells: list[str] = []
    b: list[str] = []
    i = 0
    while i < len(t):
        c = t[i]
        if c == "\\" and i + 1 < len(t) and t[i + 1] == "|":
            b.append("\\|")
            i += 2
            continue
        if c == "|":
            cells.append("".join(b).strip())
            b = []
        else:
            b.append(c)
        i += 1
    cells.append("".join(b).strip())
    return cells


def _cell_id(cell: str) -> str:
    """A cell's id with the renderer's anchor (``<a id="X"></a>X``) removed
    and a link the cell is read as its text (``[X](<file>#X)``, SOM §11.5)."""
    id = _CELL_ANCHOR.sub("", cell, count=1)
    m = _CELL_LINK.search(id)
    return m.group(1) if m is not None else id


def _fields_of(node: SomMetaNode) -> list:
    return list(node.form.fields) if node.form is not None else []


def _field_by_label(fields: list, label: str):
    lower = label.lower()
    for f in fields:
        if f.name.lower() == lower:
            return f
    return None


def _body_path_of(owner_path: str, rel: str) -> str:
    return owner_path if rel == "." else f"{owner_path}/{rel}"


class _TableRow:
    """One body row of a table: its line index and its cells."""

    def __init__(self, index: int, cells: list[str]) -> None:
        self.index = index
        self.cells = cells


class _Table:
    """A table as read: header cells, body rows, the index after the table."""

    def __init__(self, header: list[str], end: int) -> None:
        self.header = header
        self.rows: list[_TableRow] = []
        self.end = end


class _FieldRun:
    """The open ``Field:`` paragraph of a body region: its field, form and
    lines, and — for a field given twice — the held block that keeps the
    paragraph whole (RN-11)."""

    def __init__(self, parser: "_Parser", frame: _Frame, keeper: _Keeper) -> None:
        self._parser = parser
        self._frame = frame
        self._keeper = keeper
        self.field: Any = None
        self.form_path = ""
        self.discard = False
        self.lines: list[str] = []
        self._discarded: Optional[_KeptBlock] = None
        self._discard_start = 0

    def open(self, field: Any, form_path: str, i: int, first: str) -> None:
        """Opens *field* of the form at *form_path* at body index *i*."""
        p = self._parser
        self.field = field
        self.form_path = form_path
        self.discard = p._given_twice(
            form_path, field.name, p._body_line(self._frame, i)
        )
        if self.discard:
            self._discarded = p._pending.pop() if p._pending else None
            self._discard_start = i
        self.lines.append(first)

    def flush(self, at: int, into: list[str]) -> None:
        """Ends the open field at body index *at*: its value is stored, or —
        given twice — its paragraph kept in *into*."""
        if self.field is not None and not self.discard:
            self._parser._put_field(self.form_path, self.field, self.lines)
        if self.discard and self._discarded is not None:
            self._discarded.lines = list(
                self._frame.body[self._discard_start:at]
            )
            self._keeper.keep(into, self._discarded)
            self._discarded = None
        self.lines = []
        self.discard = False


class _Parser:
    def __init__(self, codec: SpecDocumentMarkdown) -> None:
        self.codec = codec
        self.content: dict[str, str] = {}
        self.forms: dict[str, dict[str, str]] = {}
        self.lists: dict[str, _ListState] = {}
        self.headlines: dict[str, str] = {}
        self.code_specs: dict[str, str] = {}
        self.units: dict[str, str] = {}
        self.rejections: list[SpecMarkdownRejection] = []
        self.root_prefixes: set[str] = set()
        self._stack: list[_Frame] = []
        self._fence = MarkdownFenceTracker()
        # The fields given so far per form path, for the given-twice rule.
        self._given: dict[str, set[str]] = {}
        # Rolling pointer into a body region's transparent form slots — labels
        # bind to the nearest form at or after the last hit (wrapping), so
        # repeated field names across an owner's transparent forms follow emit
        # order.
        self._current_form_idx = 0
        self.kept_content: dict[str, str] = {}
        # The readable header a stripped rendition carries (SOM §11.1).
        self.readable_header: Optional[str] = None
        # The source lines, for the text of a rejected block.
        self._source: list[str] = []
        # Blocks reported by _reject and not yet placed.
        self._pending: list[_KeptBlock] = []
        # Text before the root heading, kept at the start of the root's text.
        self._orphans: list[_KeptBlock] = []
        # The navigation of each root parsed, for its markable places.
        self._navs: dict[str, _Navigation] = {}

    # --- Rejected blocks kept for review (SOM §11.7, DocSpecs RN-11) ----------

    def _take_pending(self) -> list[_KeptBlock]:
        """The held blocks in source order, the hold emptied."""
        out = self._pending
        self._pending = []
        out.sort(key=lambda b: b.rejection.line)  # stable
        return out

    def _mark_pending(self, frame: _Frame, at: int, replace_end: int) -> None:
        """Places the held blocks before *frame*'s body index *at*, taking the
        place of the body lines up to *replace_end* (*at* itself: none)."""
        for b in self._take_pending():
            frame.kept.append(_KeptMark(at, b, replace_end))

    @staticmethod
    def _near_miss_norm(s: str) -> str:
        return _NEAR_MISS_SEPARATORS.sub("", s.lower())

    @classmethod
    def _near_miss(cls, label: str, names: list[str]) -> Optional[str]:
        """The declared name one edit (or only case and separators) away from
        *label*, when exactly one is: what a *Rename to* choice offers
        (RN-11)."""
        hits: list[str] = []
        for n in names:
            if (
                n != label
                and (
                    cls._near_miss_norm(n) == cls._near_miss_norm(label)
                    or cls._one_edit(n.lower(), label.lower())
                )
                and n not in hits
            ):
                hits.append(n)
        return hits[0] if len(hits) == 1 else None

    @staticmethod
    def _one_edit(a: str, b: str) -> bool:
        """Whether *a* becomes *b* by at most one insertion, deletion or
        substitution."""
        if abs(len(a) - len(b)) > 1:
            return False
        i = j = edits = 0
        while i < len(a) and j < len(b):
            if a[i] == b[j]:
                i += 1
                j += 1
                continue
            edits += 1
            if edits > 1:
                return False
            if len(a) > len(b):
                i += 1
            elif len(b) > len(a):
                j += 1
            else:
                i += 1
                j += 1
        return edits + (len(a) - i) + (len(b) - j) <= 1

    @staticmethod
    def _field_names(fields: list) -> list[str]:
        return [f.name for f in fields]

    @staticmethod
    def _kept_in_parent(node: Optional[SomMetaNode]) -> bool:
        """Whether a frame of *node* passes its rejected blocks to its parent:
        a list container, which holds no text, and a scalar or enum value,
        whose text is a typed value (RN-11)."""
        return node is not None and node.kind in (
            SomMetaKind.LIST, SomMetaKind.SCALAR, SomMetaKind.ENUM_VALUE
        )

    def _keep_ignored(self, frame: _Frame) -> None:
        """An ignored frame's heading and body, with its ignored children's
        blocks after it, go to the text of the nearest section above it that
        was read, after that section's own text (RN-11); with none above (an
        unknown root) nothing holds them and only the report remains."""
        own: Optional[SpecMarkdownRejection] = None
        for r in self.rejections:
            if r.line == frame.line:
                own = r
        blocks: list[_KeptBlock] = []
        if own is not None:
            blocks.append(
                _KeptBlock(own, [self._source[frame.line - 1], *frame.body])
            )
        blocks.extend(frame.deferred)
        if not self._stack or not blocks:
            return
        parent = self._stack[-1]
        if parent.ignored:
            parent.deferred.extend(blocks)
            return
        for b in blocks:
            parent.kept.append(_KeptMark(len(parent.body), b, len(parent.body)))

    def run(self, lines: list[str]) -> None:
        self._source = lines
        for i, raw in enumerate(lines):
            line_no = i + 1
            trimmed = raw.rstrip()

            if not self._fence.in_fence:
                if not self._stack and SpecDocumentMarkdown.docspec_comment.match(
                    trimmed
                ):
                    continue  # SOM §11.1 header — informational.
                if (
                    not self._stack
                    and self.readable_header is None
                    and SpecDocumentMarkdown.readable_comment.match(trimmed)
                ):
                    # SOM §11.1 readable header — skipped.
                    self.readable_header = trimmed
                    continue
                if (
                    self.readable_header is not None
                    and trimmed == SpecDocumentMarkdown.appendix_marker
                ):
                    break  # A stripped rendition's appendix is not the document.
                h = SpecDocumentMarkdown.heading_line.match(trimmed)
                if h is not None:
                    self._close_to(len(h.group(1)))
                    self._open_heading(len(h.group(1)), h.group(2), line_no)
                    continue
                div = SpecDocumentMarkdown.heading_div(trimmed)
                if div is not None:
                    self._close_to(div[0])
                    self._open_heading(div[0], div[1], line_no)
                    continue
            if self._stack:
                self._stack[-1].body.append(raw)
            elif trimmed:
                r = SpecMarkdownRejection(
                    line=line_no,
                    reason=SpecMarkdownRejectReason.ORPHAN_CONTENT,
                    message="text before the document root heading",
                )
                self.rejections.append(r)
                self._orphans.append(_KeptBlock(r, [raw]))
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
        code_spec = SpecDocumentMarkdown.code_spec_of(m.group(2))
        unit_ids = SpecDocumentMarkdown.units_of(m.group(2))
        # Reading view: an anchor equal to the section id after the id
        # comment, or to its qualified form (SOM §11.2), is the renderer's,
        # not part of the title.
        raw_title = m.group(3).strip()
        title = _title_without_anchor(raw_title, id, id)

        if not self._stack:
            self._open_root(level, id, title, code_spec, unit_ids, line_no)
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

        # 1. Under a `-LST` container frame (SOM §11.2), every child heading is
        #    one of that list's items — resolved positionally, not by the
        #    schema tree.
        if p_node.kind == SomMetaKind.LIST:
            anchor, scope = _qualify_anchor(
                parent.anchor_scope, parent.anchor_section, id, _ANCHOR_ITEM
            )
            self._open_item_heading(
                level,
                parent,
                p_node,
                id,
                _title_without_anchor(raw_title, id, anchor),
                code_spec,
                unit_ids,
                line_no,
            )
            last = self._stack[-1]
            last.anchor_scope = scope
            last.anchor_section = id
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
                container = c.kind == SomMetaKind.LIST
                role = (
                    _ANCHOR_CONTAINER
                    if container
                    else _ANCHOR_COPY
                    if self.codec._is_copy_node(c)
                    else _ANCHOR_PLAIN
                )
                anchor, scope = _qualify_anchor(
                    parent.anchor_scope, parent.anchor_section, id, role
                )
                title = _title_without_anchor(raw_title, id, anchor)
                # YRD3: stage the heading text as a stored headline only when
                # it differs from the effective default title
                # (byte-stability).
                if title and title != SpecDocumentMarkdown._title_of(c):
                    self.headlines[path] = title
                # codespecs_mapping.md §9.2: stage the codeSpec mapping whenever
                # present (no default).
                if code_spec:
                    self.code_specs[path] = code_spec
                # SOM §11.2: ``units`` is staged exactly like codeSpec.
                if unit_ids:
                    self.units[path] = unit_ids
                frame = _Frame(level=level, node=c, path=path, line=line_no)
                frame.anchor_scope = scope
                frame.anchor_section = parent.anchor_section if container else id
                self._stack.append(frame)
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
        code_spec: str,
        unit_ids: str,
        line_no: int,
    ) -> None:
        """Opens a list-item frame under a ``-LST`` container frame (SOM §11.2);
        the heading *id* is read by :meth:`_item_identity`."""
        n, stored_id = self._item_identity(list_node, id)
        self._open_item(
            level, container.path, list_node, n, stored_id, title, code_spec,
            unit_ids, line_no, True,
        )

    def _item_identity(
        self, list_node: SomMetaNode, id: str
    ) -> tuple[Optional[int], Optional[str]]:
        """How an item *id* of *list_node* is read, as a heading's, a records
        row's or a section-table row's: the item number it names (or ``None``
        for the next free one) and the id it stores (or ``None``). The
        ``<member>-<n>`` fallback id is positional and stores nothing; the
        ``@SectionIdPattern`` resolved with a number names item ``<n>`` and is
        stored, the section id being the item's identity and the path only its
        position (SOM §11.6); any other id is the next item, carrying it
        (YRD3)."""
        anon = re.match(
            "^"
            + re.escape(list_node.member_name or list_node.segment)
            + "-([0-9]+)$",
            id,
        )
        if anon is not None:
            return int(anon.group(1)), None
        element = list_node.element_node
        pattern = list_node.section_id_pattern or (
            element.section_id_pattern if element is not None else None
        )
        if pattern:
            parts = pattern.split("xxx")
            if len(parts) == 2:
                numbered = re.match(
                    "^" + re.escape(parts[0]) + "([0-9]+)"
                    + re.escape(parts[1]) + "$",
                    id,
                )
                if numbered is not None:
                    return int(numbered.group(1)), id
        return None, id

    def _open_root(
        self,
        level: int,
        id: str,
        title: str,
        code_spec: str,
        unit_ids: str,
        line_no: int,
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
                # codespecs_mapping.md §9.2: stage the root codeSpec mapping
                # whenever present.
                if code_spec:
                    self.code_specs[seg] = code_spec
                # SOM §11.2: ``units`` is staged exactly like codeSpec.
                if unit_ids:
                    self.units[seg] = unit_ids
                frame = _Frame(level=level, node=tree.root, path=seg,
                               line=line_no)
                frame.anchor_section = seg
                # Text before the root heading is kept at the start of its
                # text.
                for b in self._orphans:
                    frame.kept.append(_KeptMark(0, b, 0))
                self._orphans.clear()
                self._stack.append(frame)
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
        code_spec: str,
        unit_ids: str,
        line_no: int,
        push: bool,
    ) -> str:
        """Opens a list item, with its frame when *push* is set, and returns
        its path. *n* is the anonymous heading number (also the path number);
        ``None`` takes the next free number instead. The *title* is staged as
        a stored headline when it differs from the default item title
        ``<stem> <number>`` (YRD3)."""
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
        # codespecs_mapping.md §9.2: stage the item codeSpec mapping whenever
        # present.
        if code_spec:
            self.code_specs[item_path] = code_spec
        # SOM §11.2: ``units`` is staged exactly like codeSpec.
        if unit_ids:
            self.units[item_path] = unit_ids
        if push:
            self._stack.append(
                _Frame(
                    level=level,
                    node=list_node.element_node,
                    path=item_path,
                    line=line_no,
                )
            )
        return item_path

    def _nav_for(self, frame: _Frame) -> Optional[_Navigation]:
        """The navigation of the root *frame* lies in, for its markable
        places; one per root parsed."""
        seg = frame.path.split("/")[0]
        root = next(
            (
                r
                for r in self.codec.model.roots
                if (r.section_id if r.section_id is not None else r.type) == seg
            ),
            None,
        )
        if root is None:
            return None
        nav = self._navs.get(root.type)
        if nav is None:
            nav = _Navigation(self.codec, root)
            self._navs[root.type] = nav
        return nav

    def _strip_linked_marker(self, frame: _Frame) -> None:
        """Removes the ``linked`` marker (SOM §11.11): the first paragraph of
        the body of a markable heading when it is one ``linked`` span. Its
        lines are blanked, not removed, so the body indices kept blocks refer
        to hold."""
        nav = self._nav_for(frame)
        if nav is None or not nav.markable(frame.path):
            return
        body = frame.body
        k = 0
        while k < len(body) and _trim_ws(body[k]) == "":
            k += 1
        end = k
        while end < len(body) and _trim_ws(body[end]) != "":
            end += 1
        if end == k or not is_linked_paragraph("\n".join(body[k:end])):
            return
        for i in range(k, end):
            body[i] = ""

    def _strip_generated(self, frame: _Frame) -> None:
        """Removes a generated part (SOM §11.12): the first block of a
        generated place's body, after its marker, when it is a ``derived``
        block. Its lines are blanked, as the marker's are."""
        nav = self._nav_for(frame)
        if nav is None or not _Generated(nav).is_place(frame.path):
            return
        body = frame.body
        k = 0
        while k < len(body) and _trim_ws(body[k]) == "":
            k += 1
        if k >= len(body) or not opens_derived(body[k]):
            return
        close = derived_fence_close(body[k])
        end = k + 1
        while end < len(body) and close.search(body[end]) is None:
            end += 1
        if end >= len(body):
            return  # unclosed: the value's, reported there
        for i in range(k, end + 1):
            body[i] = ""
        frame.generated = True

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
            self._keep_ignored(frame)
            return
        node = frame.node
        # A scalar list item's frame has no node; it is markable all the same.
        self._strip_linked_marker(frame)
        self._strip_generated(frame)
        if node is not None and node.kind == SomMetaKind.FORM:
            self._finalize_form(frame, node, frame.path)
            return
        if node is not None and node.kind == SomMetaKind.LIST:
            self._finalize_list_body(frame, node)
        elif node is not None and node.kind in (
            SomMetaKind.SECTION, SomMetaKind.COMPLEX
        ):
            self._extract_section_tables(frame, node)
        slots = [] if node is None else self.codec._body_slots(node)
        if not slots:
            value = self._restore_value(frame.body)
            if frame.kept:
                replaced: set[int] = set()
                for mark in frame.kept:
                    replaced.update(range(mark.at, mark.end))
                parent = self._stack[-1] if self._stack else None
                if self._kept_in_parent(node) and parent is not None:
                    # A list container (no text of its own, SOM §11.5) or a
                    # typed value has no place for a block: its parent takes
                    # them, after its own text (RN-11); the lines they replace
                    # leave this frame's text.
                    own = self._restore_value(
                        _merge_kept(frame.body, [], replaced)
                    )
                    if own != value:
                        self.kept_content[frame.path] = own
                    for mark in frame.kept:
                        parent.kept.append(
                            _KeptMark(len(parent.body), mark.block,
                                      len(parent.body))
                        )
                else:
                    ins = [(mark.at, mark.block.div()) for mark in frame.kept]
                    kept = self._restore_value(
                        _merge_kept(frame.body, ins, replaced)
                    )
                    if kept:
                        self.kept_content[frame.path] = kept
            if value:
                self.content[frame.path] = value
            elif (
                node is not None
                and self._is_value_leaf(node.kind)
                and not frame.generated
            ):
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

    # --- Layout tables (SOM §11.4, §11.5) --------------------------------------

    @staticmethod
    def _body_line(frame: _Frame, i: int) -> int:
        """The 1-based source line of *frame*'s body line *i*."""
        return frame.line + 1 + i

    def _reject(
        self,
        line: int,
        reason: SpecMarkdownRejectReason,
        message: str,
        anchor: Optional[str],
        lines: Optional[list[str]] = None,
        field: Optional[str] = None,
        section: Optional[str] = None,
        kept: Optional[str] = None,
    ) -> _KeptBlock:
        """Reports a rejection and holds its block for an import that keeps
        rejected blocks (RN-11): *lines* are the source lines it held
        (``None``: its own line), *field* / *section* / *kept* what its div
        records for a resolution."""
        r = SpecMarkdownRejection(
            line=line, reason=reason, message=message, anchor=anchor
        )
        self.rejections.append(r)
        if lines is not None:
            held = list(lines)
        elif 1 <= line <= len(self._source):
            held = [self._source[line - 1]]
        else:
            held = []
        b = _KeptBlock(r, held, field, section, kept)
        self._pending.append(b)
        return b

    def _read_table(
        self,
        lines: list[str],
        start: int,
        line_of: Callable[[int], int],
        anchor: str,
    ) -> _Table:
        """Reads the table whose header is ``lines[start]``: the header cells,
        the body rows with their line indexes, and the index after the table;
        a broken delimiter row or a row of another cell count is a
        ``malformedBlock``."""
        end = start + 1
        while end < len(lines) and _TABLE_LINE.match(lines[end]):
            end += 1
        header = _row_cells(lines[start])
        delimiter = _row_cells(lines[start + 1]) if start + 1 < end else None
        is_delimiter = delimiter is not None and all(
            _DELIMITER_CELL.match(c) for c in delimiter
        )
        table = _Table(header, end)
        if not is_delimiter or len(delimiter or []) != len(header):
            self._reject(
                line_of(start),
                SpecMarkdownRejectReason.MALFORMED_BLOCK,
                "table without its delimiter row"
                if not is_delimiter
                else "table whose delimiter row does not match its header",
                anchor,
                lines[start:end],
            )
            return table
        for i in range(start + 2, end):
            cells = _row_cells(lines[i])
            if len(cells) != len(header):
                self._reject(
                    line_of(i),
                    SpecMarkdownRejectReason.MALFORMED_BLOCK,
                    f"table row with {len(cells)} cells, the header has "
                    f"{len(header)}",
                    anchor,
                    lines[i:i + 1],
                )
                continue
            table.rows.append(_TableRow(i, cells))
        return table

    @classmethod
    def _cell_value(cls, cell: str, f: Any) -> str:
        """A cell's value for field *f*: ``\\|`` unescaped, a reference
        field's links read as their link texts, a ``code`` field's code span
        decoded."""
        text = cell.replace("\\|", "|")
        if f.refers_to and not f.code and _LINK_CELL.search(text):
            return ", ".join(m.group(1) for m in _LINK_TEXT.finditer(text))
        return cls._decode_code_span(text) if f.code else text

    def _given_twice(self, form_path: str, field: str, line: int) -> bool:
        """Whether *field* of the form at *form_path* was given before;
        reports the repeat (``malformedBlock``, the first occurrence kept)
        when it was. The repeat's held block names the field and the form
        holding the kept value (RN-11)."""
        given = self._given.setdefault(form_path, set())
        if field not in given:
            given.add(field)
            return False
        self._reject(
            line,
            SpecMarkdownRejectReason.MALFORMED_BLOCK,
            f'field "{field}" given twice',
            form_path,
            None,
            field,
            None,
            form_path,
        )
        return True

    def _set_field(self, form_path: str, field: str, value: str) -> None:
        self.forms.setdefault(form_path, {})[field] = value

    def _stage_row(
        self,
        form_path: str,
        fields: list,
        label: str,
        cell: str,
        line: int,
    ) -> None:
        """Stages one row of a form table (or a section table)."""
        f = _field_by_label(fields, label)
        if f is None:
            self._reject(
                line,
                SpecMarkdownRejectReason.UNKNOWN_FIELD,
                f'row "{label}" names no field of this form',
                form_path,
                None,
                self._near_miss(label, self._field_names(fields)),
            )
            return
        value = self._cell_value(cell, f)
        if not value or self._given_twice(form_path, f.name, line):
            return
        self._set_field(form_path, f.name, value)

    def _extract_section_tables(self, frame: _Frame, node: SomMetaNode) -> None:
        """Reads and removes every section table of *frame*'s body (SOM
        §11.5)."""
        body = frame.body
        table_fence = MarkdownFenceTracker()
        i = 0
        while i < len(body):
            line = body[i]
            h = (
                None
                if table_fence.in_fence
                else _LAYOUT_TABLE_HEADER.match(line)
            )
            if h is None or h.group(1) is None:
                table_fence.feed(line)
                i += 1
                continue
            table = self._read_table(
                body, i, lambda k: self._body_line(frame, k), frame.path
            )
            target: Optional[tuple[str, list]] = None
            skip = False
            # The rejected section's block: its row and the rows continuing
            # it.
            skipped: Optional[_KeptBlock] = None
            for row in table.rows:
                row_line = self._body_line(frame, row.index)
                section = _cell_id(row.cells[0])
                if not section and skip:
                    if skipped is not None:
                        skipped.lines.append(body[row.index])
                    continue
                if section:
                    named = self._section_table_target(frame, node, section)
                    skip = named is None
                    if named is None:
                        skipped = self._reject(
                            row_line,
                            SpecMarkdownRejectReason.UNKNOWN_SECTION,
                            "section-table row names no child section of "
                            f'"{frame.path}"',
                            section,
                            body[row.index:row.index + 1],
                            None,
                            self._near_section(node, section),
                        )
                        continue
                    target = named
                elif target is None:
                    self._reject(
                        row_line,
                        SpecMarkdownRejectReason.UNKNOWN_SECTION,
                        "section-table row names no section",
                        frame.path,
                        body[row.index:row.index + 1],
                    )
                    continue
                self._stage_row(
                    target[0], target[1], row.cells[1], row.cells[2], row_line
                )
            for k in range(i, table.end):
                body[k] = ""
            # What the table rejected is kept where the table stood.
            self._mark_pending(frame, i, i)
            i = table.end

    def _near_section(self, node: SomMetaNode, section: str) -> Optional[str]:
        """The child a section-table ``Section`` cell naming none is a near
        miss of (RN-11): a child form section's id, or ``<LIST> / <ITEM>``
        with a near list id."""
        parts = _SECTION_CELL_SEP.split(section)
        if len(parts) not in (1, 2):
            return None
        kind = SomMetaKind.FORM if len(parts) == 1 else SomMetaKind.LIST
        ids: list[str] = []
        for child, _rel in self.codec._effective_children(node):
            if child.kind == kind:
                child_id = self.codec._heading_id_of(child)
                if child_id:
                    ids.append(child_id)
        if len(parts) == 1:
            return self._near_miss(section, ids)
        near_list = self._near_miss(parts[0], ids)
        return None if near_list is None else f"{near_list} / {parts[1]}"

    def _section_table_target(
        self, frame: _Frame, node: SomMetaNode, section: str
    ) -> Optional[tuple[str, list]]:
        """The form a section-table ``Section`` cell names under *node*: its
        path and its declared fields."""
        parts = _SECTION_CELL_SEP.split(section)
        for child, rel in self.codec._effective_children(node):
            child_id = self.codec._heading_id_of(child)
            if (
                len(parts) == 1
                and child.kind == SomMetaKind.FORM
                and child_id == section
            ):
                return f"{frame.path}/{rel}", _fields_of(child)
            if (
                len(parts) == 2
                and child.kind == SomMetaKind.LIST
                and child_id == parts[0]
            ):
                element = child.element_node
                form = (
                    self.codec._item_form(element)
                    if element is not None
                    else None
                )
                if form is None:
                    return None
                n, stored_id = self._item_identity(child, parts[1])
                list_path = f"{frame.path}/{rel}"
                state = self.lists.get(list_path)
                item_path: Optional[str] = None
                if state is not None:
                    for p in state.items:
                        item_id = state.ids.get(p)
                        if item_id is None:
                            item_id = p[len(list_path) + 1:]
                        if item_id == parts[1]:
                            item_path = p
                            break
                if item_path is None:
                    item_path = self._open_item(
                        0, list_path, child, n, stored_id, "", "", "",
                        frame.line, False,
                    )
                return f"{item_path}/{form[1]}", _fields_of(form[0])
        return None

    # --- List bodies: `refs` and `records` (SOM §11.5) --------------------------

    @staticmethod
    def _blank(body: list[str], start: int, stop: int) -> None:
        for k in range(start, stop + 1):
            body[k] = ""

    def _finalize_list_body(self, frame: _Frame, list_node: SomMetaNode) -> None:
        """A list container's body: one ``refs`` or ``records`` div stands for
        its items."""
        body = frame.body
        div_fence = MarkdownFenceTracker()
        for i, line in enumerate(body):
            opened = None if div_fence.in_fence else _LIST_DIV_OPEN.match(line)
            if opened is None:
                div_fence.feed(line)
                continue
            kind = opened.group(1) or opened.group(2)
            close = next(
                (k for k in range(i + 1, len(body)) if _DIV_CLOSE.match(body[k])),
                -1,
            )
            if close < 0:
                # The fence's lines read as text; kept, they are the rejected
                # div (the container's parent holds it, see _finalize).
                self._reject(
                    self._body_line(frame, i),
                    SpecMarkdownRejectReason.MALFORMED_BLOCK,
                    f"unclosed {kind} fence",
                    frame.path,
                    body[i:],
                )
                self._mark_pending(frame, i, len(body))
                return
            div_lines = body[i:close + 1]
            beside_text = any(
                (k < i or k > close) and body[k].strip()
                for k in range(len(body))
            )
            state = self.lists.get(frame.path)
            has_items = state is not None and bool(state.items)
            if beside_text or has_items:
                beside = "item headings" if has_items else "other text"
                self._reject(
                    self._body_line(frame, i),
                    SpecMarkdownRejectReason.MALFORMED_BLOCK,
                    f"a {kind} div beside {beside} in a list container",
                    frame.path,
                    div_lines,
                )
                self._blank(body, i, close)
                self._mark_pending(frame, close + 1, close + 1)
                return
            inner = body[i + 1:close]
            if kind == "refs":
                self._stage_reference_line(frame, list_node, inner, i, div_lines)
            else:
                self._stage_record_table(frame, list_node, inner, i, div_lines)
            self._blank(body, i, close)
            # What the div rejected is kept after it.
            self._mark_pending(frame, close + 1, close + 1)
            return

    @staticmethod
    def _is_reference_form(n: SomMetaNode) -> bool:
        if (
            n.kind != SomMetaKind.FORM
            or n.form is None
            or len(n.form.fields) != 1
            or not n.form.fields[0].refers_to
        ):
            return False
        return any(e.annotation == "Reference" for e in n.extra)

    def _reference_form(
        self, element: SomMetaNode
    ) -> Optional[tuple[SomMetaNode, str]]:
        """The reference form of *element*'s items (its one field is the
        reference)."""
        for s in self.codec._body_slots(element):
            if self._is_reference_form(s[0]):
                return s
        for c in self.codec._effective_children(element):
            if self._is_reference_form(c[0]):
                return c
        return None

    def _stage_reference_line(
        self,
        frame: _Frame,
        list_node: SomMetaNode,
        inner: list[str],
        at: int,
        div_lines: list[str],
    ) -> None:
        """A ``refs`` div: ids split on commas and whitespace, links read as
        their texts."""
        element = list_node.element_node
        ref = self._reference_form(element) if element is not None else None
        if ref is None:
            self._reject(
                self._body_line(frame, at),
                SpecMarkdownRejectReason.MALFORMED_BLOCK,
                "a refs div in a list whose items are not references",
                frame.path,
                div_lines,
            )
            return
        ids: list[str] = []
        for t in _REF_SEP.split(" ".join(inner)):
            if not t:
                continue
            m = _LINK_TEXT.search(t)
            ids.append(m.group(1) if m is not None else t)
        if not ids:
            self._reject(
                self._body_line(frame, at),
                SpecMarkdownRejectReason.MISSING_VALUE,
                "an empty refs div",
                frame.path,
                div_lines,
            )
            return
        pattern = list_node.section_id_pattern or element.section_id_pattern
        pattern = pattern or None
        member = list_node.member_name or list_node.segment
        field = ref[0].form.fields[0].name
        for n in range(1, len(ids) + 1):
            positional = effective_list_item_section_id(None, pattern, n, member)
            num, stored_id = self._item_identity(list_node, positional)
            item_path = self._open_item(
                0, frame.path, list_node, num, stored_id, "", "", "",
                frame.line, False,
            )
            self._set_field(_body_path_of(item_path, ref[1]), field, ids[n - 1])

    def _stage_record_table(
        self,
        frame: _Frame,
        list_node: SomMetaNode,
        inner: list[str],
        at: int,
        div_lines: list[str],
    ) -> None:
        """A ``records`` div: one table, ``Id`` first, ``Title`` optionally
        second."""

        def line_of(k: int) -> int:
            return self._body_line(frame, at + 1 + k)

        div_line = self._body_line(frame, at)
        start = next((k for k, l in enumerate(inner) if l.strip()), -1)
        if start < 0 or not _TABLE_LINE.match(inner[start]):
            self._reject(
                div_line,
                SpecMarkdownRejectReason.MALFORMED_BLOCK,
                "a records div holding no table",
                frame.path,
                div_lines,
            )
            return
        header = _row_cells(inner[start])
        if header[0] != "Id":
            self._reject(
                div_line,
                SpecMarkdownRejectReason.MALFORMED_BLOCK,
                "a records table whose first column is not Id",
                frame.path,
                div_lines,
            )
            return
        element = list_node.element_node
        form = self.codec._item_form(element) if element is not None else None
        if form is None:
            self._reject(
                div_line,
                SpecMarkdownRejectReason.MALFORMED_BLOCK,
                "a records div in a list whose items have no single form",
                frame.path,
                div_lines,
            )
            return
        fields = _fields_of(form[0])
        with_title = len(header) > 1 and header[1] == "Title"
        first = 2 if with_title else 1
        columns = []
        for label in header[first:]:
            f = _field_by_label(fields, label)
            if f is None:
                # The table is skipped whole, so the whole div is kept.
                self._reject(
                    line_of(start),
                    SpecMarkdownRejectReason.UNKNOWN_FIELD,
                    f'records column "{label}" names no field of the items',
                    frame.path,
                    div_lines,
                    self._near_miss(label, self._field_names(fields)),
                )
                return
            columns.append(f)
        table = self._read_table(inner, start, line_of, frame.path)
        stem = SpecDocumentMarkdown._item_stem_of(list_node)
        for row in table.rows:
            n, stored_id = self._item_identity(list_node, _cell_id(row.cells[0]))
            item_path = self._open_item(
                0, frame.path, list_node, n, stored_id, "", "", "",
                line_of(row.index), False,
            )
            if with_title:
                title = row.cells[1].replace("\\|", "|").replace("<br>", "\n")
                number = item_path[len(frame.path) + 1:]
                if title and title != f"{stem} {number}":
                    self.headlines[item_path] = title
            form_path = f"{item_path}/{form[1]}"
            for c, f in enumerate(columns):
                value = self._cell_value(row.cells[first + c], f)
                if value:
                    self._set_field(form_path, f.name, value)

    def _find_form_of(
        self, form_slots: list[tuple[SomMetaNode, str]], label: str
    ) -> int:
        """The index of the form slot declaring *label*: the nearest at or
        after the last hit, wrapping; -1 when none declares it."""
        for k in range(len(form_slots)):
            idx = (self._current_form_idx + k) % len(form_slots)
            if _field_by_label(_fields_of(form_slots[idx][0]), label) is not None:
                return idx
        return -1

    def _join_parts(self, parts: list[list[str]]) -> str:
        """The restored, non-empty text parts joined by one blank line."""
        return "\n\n".join(
            v for v in (self._restore_value(p) for p in parts) if v
        )

    def _put_field(self, form_path: str, field: Any, lines: list[str]) -> None:
        """Stores a field's restored value (unwrapping a code field's code
        span)."""
        restored = self._restore_value(lines)
        value = self._decode_code_span(restored) if field.code else restored
        if value:
            self._set_field(form_path, field.name, value)

    def _finalize_body_slots(
        self, frame: _Frame, slots: list[tuple[SomMetaNode, str]]
    ) -> None:
        """Binds a heading's body region against the owner's transparent body
        slots (SOM §11.6): ``FieldName:`` lines and form-table rows matching a
        transparent form's fields route to that form (nearest form in slot
        order, wrapping); a slot marker (``<!-- slot: <rel> -->``) sends the
        text after it to the named slot — a content slot, a form's preamble,
        or the owner itself (``.``) — and ends any open field. Unmarked text
        binds to the first content slot; with no content slot it is a form's
        **preamble** (SOM §11.4 rule 7) — the class-level ``@Form`` on the
        ``content`` member, else the first form — which is where the YAML
        codec keeps it; only an owner with no slot at all takes it on its own
        path. Rejected blocks are kept in the unlabelled text at their place
        (RN-11)."""
        form_slots = [s for s in slots if s[0].kind == SomMetaKind.FORM]
        default_rel = SpecDocumentMarkdown._default_body_rel(slots)

        fence = MarkdownFenceTracker()
        # Unlabelled text per target path, in the order the targets were
        # opened; a target opened twice gets its parts joined by a blank line.
        text_parts: dict[str, list[list[str]]] = {}
        content_lines: list[str] = []
        text_parts.setdefault(_body_path_of(frame.path, default_rel), []).append(
            content_lines
        )
        # Rejected blocks go to the unlabelled text at their place (RN-11); a
        # field given twice is kept whole, its label line and continuation.
        keeper = _Keeper(frame)
        run = _FieldRun(self, frame, keeper)

        self._current_form_idx = 0
        i = 0
        body = frame.body
        while i < len(body):
            line = body[i]
            keeper.drain(i, content_lines)
            if not fence.in_fence:
                mk = _SLOT_MARKER.match(line)
                if mk is not None:
                    rel = mk.group(1)
                    slot = (
                        None
                        if rel == "."
                        else next((s for s in slots if s[1] == rel), None)
                    )
                    if rel == "." or slot is not None:
                        run.flush(i, content_lines)
                        run.field = None
                        if slot is not None and slot[0].kind == SomMetaKind.FORM:
                            self._current_form_idx = form_slots.index(slot)
                        content_lines = []
                        text_parts.setdefault(
                            _body_path_of(frame.path, rel), []
                        ).append(content_lines)
                        i += 1
                        continue
                header = _LAYOUT_TABLE_HEADER.match(line)
                if header is not None and header.group(1) is None and form_slots:
                    # A form table ends the open field (SOM §11.4); its rows
                    # bind like `Field:` labels, each to the nearest form
                    # declaring it.
                    run.flush(i, content_lines)
                    run.field = None
                    table = self._read_table(
                        body, i, lambda k: self._body_line(frame, k), frame.path
                    )
                    for row in table.rows:
                        label = row.cells[0]
                        row_line = self._body_line(frame, row.index)
                        hit = self._find_form_of(form_slots, label)
                        if hit < 0:
                            names: list[str] = []
                            for s in form_slots:
                                names.extend(self._field_names(_fields_of(s[0])))
                            self._reject(
                                row_line,
                                SpecMarkdownRejectReason.UNKNOWN_FIELD,
                                f'row "{label}" names no field of this form',
                                frame.path,
                                body[row.index:row.index + 1],
                                self._near_miss(label, names),
                            )
                            continue
                        self._current_form_idx = hit
                        self._stage_row(
                            f"{frame.path}/{form_slots[hit][1]}",
                            _fields_of(form_slots[hit][0]),
                            label,
                            row.cells[1],
                            row_line,
                        )
                    # What the table rejected is kept where the table stood.
                    for b in self._take_pending():
                        keeper.keep(content_lines, b)
                    i = table.end
                    continue
                m = _FIELD_LABEL.match(line)
                if m is not None:
                    hit = self._find_form_of(form_slots, m.group(1))
                    if hit >= 0:
                        run.flush(i, content_lines)
                        self._current_form_idx = hit
                        run.open(
                            _field_by_label(
                                _fields_of(form_slots[hit][0]), m.group(1)
                            ),
                            f"{frame.path}/{form_slots[hit][1]}",
                            i,
                            m.group(2),
                        )
                        fence.feed(line)
                        i += 1
                        continue
            target = content_lines if run.field is None else run.lines
            # In a region with forms every label-shaped text line carries the
            # one escape space the emitter adds (SOM §11.4 rule 3); strip it.
            if (
                not fence.in_fence
                and form_slots
                and _CONTINUATION_LABEL.match(line)
            ):
                target.append(line[1:])
            else:
                target.append(line)
            fence.feed(line)
            i += 1
        run.flush(len(body), content_lines)
        keeper.drain(len(body), content_lines)
        for target_path, parts in text_parts.items():
            value = self._join_parts(parts)
            if value:
                self.content[target_path] = value
            kept = keeper.kept_value(parts)
            if kept:
                self.kept_content[target_path] = kept

    def _finalize_form(
        self, frame: _Frame, node: SomMetaNode, path: str
    ) -> None:
        """Parses an id-bearing ``@Form`` section's body: ``FieldName:``
        paragraphs and form-table rows bind to the named fields wherever they
        stand (SOM §11.4); the text that belongs to no field — before the
        first field, or after a table — is the form's preamble, its own
        content (rule 7). Rejected blocks are kept in the preamble at their
        place (RN-11)."""
        declared = _fields_of(node)
        fence = MarkdownFenceTracker()
        # The preamble's parts: the text before the first field, and text a
        # table interrupts; joined by one blank line.
        preamble_parts: list[list[str]] = [[]]
        keeper = _Keeper(frame)
        run = _FieldRun(self, frame, keeper)

        body = frame.body
        i = 0
        while i < len(body):
            line = body[i]
            keeper.drain(i, preamble_parts[-1])
            if not fence.in_fence:
                header = _LAYOUT_TABLE_HEADER.match(line)
                if header is not None and header.group(1) is None:
                    run.flush(i, preamble_parts[-1])
                    run.field = None
                    preamble_parts.append([])
                    table = self._read_table(
                        body, i, lambda k: self._body_line(frame, k), path
                    )
                    for row in table.rows:
                        self._stage_row(
                            path,
                            declared,
                            row.cells[0],
                            row.cells[1],
                            self._body_line(frame, row.index),
                        )
                    for b in self._take_pending():
                        keeper.keep(preamble_parts[-1], b)
                    i = table.end
                    continue
                m = _FIELD_LABEL.match(line)
                field = (
                    _field_by_label(declared, m.group(1))
                    if m is not None
                    else None
                )
                if field is not None and m is not None:
                    run.flush(i, preamble_parts[-1])
                    run.open(field, path, i, m.group(2))
                    fence.feed(line)
                    i += 1
                    continue
            # Continuation: strip the one escape space of a label-shaped line.
            target = preamble_parts[-1] if run.field is None else run.lines
            if not fence.in_fence and _CONTINUATION_LABEL.match(line):
                target.append(line[1:])
            else:
                target.append(line)
            fence.feed(line)
            i += 1
        run.flush(len(body), preamble_parts[-1])
        keeper.drain(len(body), preamble_parts[-1])
        value = self._join_parts(preamble_parts)
        if value:
            self.content[path] = value
        kept = keeper.kept_value(preamble_parts)
        if kept:
            self.kept_content[path] = kept

    @staticmethod
    def _decode_code_span(value: str) -> str:
        """The inverse of the emitter's code span (SOM §11.4 rule 8): a
        single-line *value* delimited by equal backtick runs loses them, and
        one padding space on each side when both are present. Anything else —
        a value written by hand without a span — is kept as written."""
        if "\n" in value:
            return value
        m = re.match(r"^(`+)([\s\S]*[^`])(`+)$", value)
        if m is None or len(m.group(1)) != len(m.group(3)):
            return value
        inner = m.group(2)
        if (
            len(inner) >= 2
            and inner.startswith(" ")
            and inner.endswith(" ")
            and inner.strip()
        ):
            return inner[1:-1]
        return inner

    @staticmethod
    def _restore_value(body: list[str]) -> str:
        """Parse-side value restoration (SOM §11.3): trim leading/trailing
        blank lines, unescape ``\\#``-escaped heading lines and strip the one
        escape space of a line shaped like a layout table header (SOM §11.4),
        outside fences."""
        fence = MarkdownFenceTracker()
        out: list[str] = []
        for line in body:
            if not fence.in_fence and (
                _ESCAPED_HEADING.match(line)
                or (line.startswith("\\") and SpecDocumentMarkdown.escapable_div(line))
            ):
                out.append(line[1:])
            elif not fence.in_fence and _ESCAPED_TABLE_HEADER.match(line):
                out.append(line[1:])  # the emitter's one escape space.
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


class SpecMarkdownRendition:
    """A Markdown rendition of a document and the document path behind each
    of its headings (:meth:`SpecDocumentMarkdown.export_root_with_map`)."""

    def __init__(self, markdown: str, heading_paths: dict[int, str]) -> None:
        #: The rendered Markdown, identical to
        #: :meth:`SpecDocumentMarkdown.export_root`.
        self.markdown = markdown
        #: Every heading line (1-based) and the document path it renders.
        self.heading_paths = heading_paths

    def path_at_line(self, line: int) -> Optional[str]:
        """The document path of the section *line* belongs to: the path of the
        heading on that line, else of the nearest heading above it. ``None``
        for a line before the first heading."""
        for ln in range(line, 0, -1):
            p = self.heading_paths.get(ln)
            if p is not None:
                return p
        return None
