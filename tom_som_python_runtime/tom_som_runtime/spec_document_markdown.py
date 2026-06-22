"""Generic, meta-data-driven Markdown codec for a TomSpecs document — a faithful
port of `tom_som_dart_runtime/lib/src/spec_document_markdown.dart`.

A ``<!-- docspec: -->`` header, then one heading per **populated** section
(sparse, in schema order), with each section's machine-readable **section path**
as the first token of its heading so import maps back unambiguously. Leaf values
live in **fenced code blocks** whose fence is widened past any backtick run in
the value, so embedded code bodies round-trip **verbatim**. Form fields are
introduced by a ``<!-- field: name -->`` anchor; list items appear as nested
``…-N`` sections, so list membership is recovered from the paths alone on import.

:meth:`SpecDocumentMarkdown.parse` does **not** mutate the document — it returns
staged values keyed exactly like :meth:`SpecDocument.to_json` plus a rejection
report; the caller applies them.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field as dataclass_field
from enum import Enum
from typing import Any, Iterable, Optional

from .spec_document import SpecDocument
from .spec_model import SpecClass, SpecField, SpecFieldKind, SpecModel, SpecRoot
from .spec_reflection import SpecNodeKind, SpecReflection

_HEADING_RE = re.compile(r"^(#{1,6})\s+(\S+)")
_FIELD_ANCHOR_RE = re.compile(r"^<!--\s*field:\s*(\S+)\s*-->$")
_FENCE_OPEN_RE = re.compile(r"^(`{3,})")
_ITEM_SEG_RE = re.compile(r"^(.+)-(\d+)$")


class SpecMarkdownRejectReason(Enum):
    """Why an imported Markdown block was rejected."""

    UNKNOWN_SECTION = "unknownSection"
    KIND_MISMATCH = "kindMismatch"
    ORPHAN_BLOCK = "orphanBlock"
    MISSING_VALUE = "missingValue"
    MALFORMED_HEADING = "malformedHeading"


@dataclass
class SpecMarkdownRejection:
    """One rejected block in a Markdown import. Reported, never silently
    dropped."""

    line: int
    reason: SpecMarkdownRejectReason
    message: str
    anchor: Optional[str] = None

    def __str__(self) -> str:
        anchor = f" ({self.anchor})" if self.anchor is not None else ""
        return f"line {self.line}: {self.reason.value}{anchor} — {self.message}"


@dataclass
class SpecMarkdownResult:
    """The outcome of parsing a Markdown document: the staged values plus every
    rejected block. The values are keyed exactly like :meth:`SpecDocument.to_json`."""

    content: dict[str, str] = dataclass_field(default_factory=dict)
    forms: dict[str, dict[str, str]] = dataclass_field(default_factory=dict)
    lists: dict[str, dict[str, Any]] = dataclass_field(default_factory=dict)
    rejections: list[SpecMarkdownRejection] = dataclass_field(default_factory=list)
    root_prefixes: set[str] = dataclass_field(default_factory=set)

    @property
    def is_clean(self) -> bool:
        return not self.rejections

    @property
    def applied_count(self) -> int:
        return len(self.content) + sum(len(m) for m in self.forms.values())


class _Pending:
    """A pending value target between a section/field anchor and its fenced
    block."""

    def __init__(self, line: int, path: str, field: Optional[str]) -> None:
        self.line = line
        self.path = path
        self.field = field
        self.filled = False

    @property
    def anchor(self) -> str:
        return f"{self.path} :: {self.field}" if self.field is not None else self.path


def _fence(value: str, info: str = "") -> str:
    """A fenced code block holding *value* verbatim. The fence is one backtick
    longer than the longest backtick run in *value* (min 3)."""
    max_run = 0
    run = 0
    for ch in value:
        if ch == "`":
            run += 1
            if run > max_run:
                max_run = run
        else:
            run = 0
    n = max_run + 1 if (max_run + 1) >= 3 else 3
    f = "`" * n
    parts = [f"{f}{info}\n"]
    for line in value.split("\n"):
        parts.append(f"{line}\n")
    parts.append(f)
    return "".join(parts)


class _Buffer:
    def __init__(self) -> None:
        self._parts: list[str] = []

    def writeln(self, text: str = "") -> None:
        self._parts.append(text)
        self._parts.append("\n")

    def __str__(self) -> str:
        return "".join(self._parts)


def _heading(b: _Buffer, depth: int, path: str, name: str) -> None:
    hashes = "#" * (6 if depth > 6 else depth)
    b.writeln(f"{hashes} {path} — {name}")


class SpecDocumentMarkdown:
    """Codec binding a :class:`SpecModel` and a concrete :class:`SpecDocument` to
    the Markdown import/export format."""

    def __init__(self, model: SpecModel, document: SpecDocument) -> None:
        self.model = model
        self.document = document
        self._reflection = SpecReflection(model)

    def _root_seg(self, r: SpecRoot) -> str:
        return self._reflection.root_segment(r)

    def _field_seg(self, f: SpecField) -> str:
        return self._reflection.field_segment(f)

    # --- Export -------------------------------------------------------------

    def export_root(self, root: SpecRoot) -> str:
        """Renders the populated subtree of *root* as a schema-conformant
        Markdown document with a ``<!-- docspec: -->`` header."""
        b = _Buffer()
        seg = self._root_seg(root)
        b.writeln(f"<!-- docspec: {seg.lower()}/1 -->")
        b.writeln(f"# {seg} — {root.title}")
        cls = self.model.class_named(root.type)
        if root.description is not None and root.description.strip() != "":
            b.writeln()
            b.writeln(root.description.strip())
        if cls is not None:
            self._export_class(b, cls, seg, 2, {root.type})
        return str(b)

    def _export_class(
        self,
        b: _Buffer,
        cls: SpecClass,
        base_path: str,
        depth: int,
        seen_types: set[str],
    ) -> None:
        for field in cls.fields:
            path = f"{base_path}/{self._field_seg(field)}"
            if not self.document.has_values_under(path):
                continue
            kind = field.kind
            if kind in (
                SpecFieldKind.CONTENT,
                SpecFieldKind.SCALAR,
                SpecFieldKind.ENUM,
            ):
                value = self.document.content(path)
                if value is None:
                    continue
                _heading(b, depth, path, field.name)
                b.writeln(_fence(value, info=field.content_type or ""))
                b.writeln()
            elif kind == SpecFieldKind.FORM:
                _heading(b, depth, path, field.name)
                for ff in field.form_fields:
                    value = self.document.form_field(path, ff.name)
                    if value is None:
                        continue
                    b.writeln(f"<!-- field: {ff.name} -->")
                    b.writeln(_fence(value))
                    b.writeln()
            elif kind == SpecFieldKind.LIST:
                elem = self.model.class_named(field.element_type)
                recursive = (
                    field.element_type is not None
                    and field.element_type in seen_types
                )
                _heading(b, depth, path, field.name)
                b.writeln()
                if elem is None or recursive:
                    continue
                next_seen = seen_types | {field.element_type}
                for item_path in self.document.list_items(path):
                    _heading(b, depth + 1, item_path, field.element_type or "item")
                    b.writeln()
                    self._export_class(b, elem, item_path, depth + 2, next_seen)
            elif kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
                nested = self.model.class_named(field.type)
                recursive = field.type is not None and field.type in seen_types
                if nested is None or recursive:
                    continue
                _heading(b, depth, path, field.name)
                b.writeln()
                self._export_class(
                    b, nested, path, depth + 1, seen_types | {field.type}
                )

    # --- Import -------------------------------------------------------------

    def parse(self, text: str) -> SpecMarkdownResult:
        """Parses *text* into staged values + a rejection report, **without**
        mutating the document."""
        lines = text.split("\n")
        content: dict[str, str] = {}
        forms: dict[str, dict[str, str]] = {}
        rejections: list[SpecMarkdownRejection] = []
        root_prefixes: set[str] = set()

        pending: Optional[_Pending] = None

        def flush_missing() -> None:
            nonlocal pending
            if pending is not None and not pending.filled:
                rejections.append(
                    SpecMarkdownRejection(
                        line=pending.line,
                        reason=SpecMarkdownRejectReason.MISSING_VALUE,
                        anchor=pending.anchor,
                        message="no fenced value followed this anchor",
                    )
                )
            pending = None

        i = 0
        current_kind: Optional[SpecNodeKind] = None
        current_path: Optional[str] = None
        while i < len(lines):
            raw = lines[i]
            line_no = i + 1
            trimmed = raw.rstrip()

            # Heading.
            heading = _heading_path(trimmed)
            if heading is not None:
                flush_missing()
                path = heading
                node = self._reflection.resolve(path)
                if node is None:
                    rejections.append(
                        SpecMarkdownRejection(
                            line=line_no,
                            reason=SpecMarkdownRejectReason.UNKNOWN_SECTION,
                            anchor=path,
                            message="section path does not resolve against the model",
                        )
                    )
                    current_kind = None
                    current_path = None
                    i += 1
                    continue
                current_kind = node.kind
                current_path = path
                root_prefixes.add(path.split("/")[0])
                if node.is_value_leaf:
                    pending = _Pending(line_no, path, None)
                i += 1
                continue

            # Form-field anchor.
            field_name = _field_anchor(trimmed)
            if field_name is not None:
                flush_missing()
                if current_path is None or current_kind != SpecNodeKind.FORM:
                    rejections.append(
                        SpecMarkdownRejection(
                            line=line_no,
                            reason=SpecMarkdownRejectReason.KIND_MISMATCH,
                            anchor=field_name,
                            message="form-field anchor outside a `@Form` section",
                        )
                    )
                    i += 1
                    continue
                pending = _Pending(line_no, current_path, field_name)
                i += 1
                continue

            # Fence opener.
            fence_len = _fence_open(trimmed)
            if fence_len is not None:
                body: list[str] = []
                j = i + 1
                closer = "`" * fence_len
                while j < len(lines) and lines[j].rstrip() != closer:
                    body.append(lines[j])
                    j += 1
                value = "\n".join(body)
                if pending is None:
                    rejections.append(
                        SpecMarkdownRejection(
                            line=line_no,
                            reason=SpecMarkdownRejectReason.ORPHAN_BLOCK,
                            message="fenced value with no owning section or field",
                        )
                    )
                elif pending.field is not None:
                    forms.setdefault(pending.path, {})[pending.field] = value
                    pending.filled = True
                else:
                    content[pending.path] = value
                    pending.filled = True
                pending = None
                i = j + 1 if j < len(lines) else j
                continue

            i += 1
        flush_missing()

        lists = self._reconstruct_lists(content.keys(), forms.keys())
        return SpecMarkdownResult(
            content=content,
            forms=forms,
            lists=lists,
            rejections=rejections,
            root_prefixes=root_prefixes,
        )

    def _reconstruct_lists(
        self, content_keys: Iterable[str], form_keys: Iterable[str]
    ) -> dict[str, dict[str, Any]]:
        """Recovers list membership from the leaf paths: any ``<base>-<n>``
        segment whose ``<base>`` ancestor resolves to a list field denotes item
        ``<n>`` of that list."""
        items: dict[str, list[str]] = {}
        seq: dict[str, int] = {}

        def scan(path: str) -> None:
            segs = path.split("/")
            prefix = segs[0]
            for k in range(1, len(segs)):
                seg = segs[k]
                m = _ITEM_SEG_RE.match(seg)
                if m is not None:
                    list_path = f"{prefix}/{m.group(1)}"
                    item_path = f"{prefix}/{seg}"
                    node = self._reflection.resolve(list_path)
                    if node is not None and node.kind == SpecNodeKind.LIST:
                        bucket = items.setdefault(list_path, [])
                        if item_path not in bucket:
                            bucket.append(item_path)
                        n = int(m.group(2))
                        if n > seq.get(list_path, 0):
                            seq[list_path] = n
                prefix = f"{prefix}/{seg}"

        for p in content_keys:
            scan(p)
        for p in form_keys:
            scan(p)
        return {
            key: {"seq": seq.get(key, len(value)), "items": value}
            for key, value in items.items()
        }


def _heading_path(line: str) -> Optional[str]:
    """The section path of a heading line (``#{1,6} <path> …``), or ``None``."""
    m = _HEADING_RE.match(line)
    return m.group(2) if m else None


def _field_anchor(line: str) -> Optional[str]:
    """The field name of a ``<!-- field: name -->`` anchor line, or ``None``."""
    m = _FIELD_ANCHOR_RE.match(line.strip())
    return m.group(1) if m else None


def _fence_open(line: str) -> Optional[int]:
    """The fence length of a fence-opener line (3+ backticks), or ``None``."""
    m = _FENCE_OPEN_RE.match(line)
    return len(m.group(1)) if m else None
