"""Consolidated DocSpecs parsing + validation (SOM §14) — a faithful port of
``tom_som_dart_runtime/lib/src/docspecs_validator.dart``. The Dart violation
messages are the golden reference; this port produces the same
``rule`` / ``section_id`` / ``line`` triples.

Three capabilities, one module:

 1. **Parse** — :meth:`DocSpecsDocument.parse` reads any DocSpecs ``*.md``
    *schema-free* into a generic section tree (:class:`DocSpecsSection`).
    Fenced code blocks shield their lines from heading detection
    (:class:`MarkdownFenceTracker`, the exact semantics of the
    :class:`SpecDocumentMarkdown` codec).
 2. **Validate** — :meth:`DocSpecsValidator.validate` checks a parsed
    document against a :class:`DocSpecsSchema` and returns a structured
    :class:`DocSpecsViolation` list. Validation **never fails fast**.
 3. **Bind** — :func:`bind_docspecs_markdown` maps the same markdown onto the
    SOM metadata tree, delegating to :meth:`SpecDocumentMarkdown.parse`.

Anything outside the SOM §14 schema scope is ignored on load and named in
:attr:`DocSpecsSchema.warnings` — nothing is silently dropped.
"""

from __future__ import annotations

import re
from enum import Enum
from typing import Any, Callable, Optional

import yaml

from .spec_document import SpecDocument
from .spec_document_markdown import (
    MarkdownFenceTracker,
    SpecDocumentMarkdown,
    SpecMarkdownResult,
)
from .spec_model import SpecModel
from .spec_notation import scan_notation


class DocSpecsViolationRule(Enum):
    """The SOM §14 violation rule vocabulary — identical across all nine
    runtimes (values are the Dart enum names)."""

    UNKNOWN_SECTION = "unknownSection"
    MISSING_REQUIRED_SECTION = "missingRequiredSection"
    ID_PATTERN_MISMATCH = "idPatternMismatch"
    TOO_FEW_ITEMS = "tooFewItems"
    TOO_MANY_ITEMS = "tooManyItems"
    MISSING_REQUIRED_FIELD = "missingRequiredField"
    FIELD_PATTERN_MISMATCH = "fieldPatternMismatch"
    TEXT_REQUIRED = "textRequired"
    TEXT_LENGTH_OUT = "textLengthOut"
    FORMAT_MISMATCH = "formatMismatch"
    MALFORMED_HEADING = "malformedHeading"
    SECTION_OUT_OF_ORDER = "sectionOutOfOrder"
    DUPLICATE_ID_PATH = "duplicateIdPath"
    # The reading notation's findings (DocSpecs specification, RN-10),
    # reported by scan_notation per value: a section's own body, and in a
    # TomSpecs rendition each form field's value apart.
    UNCLOSED_DIV = "unclosedDiv"
    STRAY_CLOSING_FENCE = "strayClosingFence"
    UNCLOSED_SPAN = "unclosedSpan"
    DIV_WITHOUT_KIND = "divWithoutKind"
    UNKNOWN_KIND = "unknownKind"
    MARK_ACROSS_NOTATION = "markAcrossNotation"
    ANNOTATION_INSIDE_DIV = "annotationInsideDiv"
    DIV_INSIDE_ANNOTATION = "divInsideAnnotation"
    REJECTED_BLOCK = "rejectedBlock"
    # The reading view's list bodies and tables (DocSpecs specification,
    # Findings in list bodies and tables): a form, section or record table
    # without a matching delimiter row, a row of another cell count, a field
    # given twice (the first kept), a refs / records div beside other text or
    # item headings, a records div holding no table or one whose first column
    # is not Id, an unclosed refs / records fence.
    MALFORMED_BLOCK = "malformedBlock"
    # A form-table row or a record-table column naming no field of its form.
    UNKNOWN_FIELD = "unknownField"


class DocSpecsViolation:
    """One structured violation (SOM §14): the rule, the offending section id
    (when one exists), the bound runtime path (when resolvable), the 1-based
    source line, and a human-readable message."""

    def __init__(
        self,
        *,
        rule: DocSpecsViolationRule,
        line: int,
        message: str,
        section_id: Optional[str] = None,
        path: Optional[str] = None,
    ) -> None:
        self.rule = rule
        self.section_id = section_id
        self.path = path
        self.line = line
        self.message = message

    def __str__(self) -> str:
        sid = f" [{self.section_id}]" if self.section_id is not None else ""
        p = f" ({self.path})" if self.path is not None else ""
        return f"line {self.line}: {self.rule.value}{sid}{p} — {self.message}"

    def __repr__(self) -> str:  # pragma: no cover - debugging aid
        return f"DocSpecsViolation({self!s})"


# ---------------------------------------------------------------------------
# 1. Generic (schema-free) markdown parse
# ---------------------------------------------------------------------------


class DocSpecsSection:
    """One section of a schema-free DocSpecs parse: its id (``None`` for a
    malformed heading), heading title, markdown level, 1-based heading line,
    accumulated body lines (each with its own source line =
    ``body_start_line + index``), and nested children."""

    def __init__(
        self, *, id: Optional[str], title: str, level: int, line: int
    ) -> None:
        self.id = id
        self.title = title
        self.level = level
        self.line = line
        #: The raw body lines directly under this heading (before any child
        #: heading), in source order.
        self.body_lines: list[str] = []
        self.children: list["DocSpecsSection"] = []

    @property
    def body_start_line(self) -> int:
        """The source line of the first body line (heading line + 1)."""
        return self.line + 1

    @property
    def text(self) -> str:
        """The trimmed body text (leading/trailing blank lines removed)."""
        start = 0
        end = len(self.body_lines)
        while start < end and not self.body_lines[start].strip():
            start += 1
        while end > start and not self.body_lines[end - 1].strip():
            end -= 1
        return "\n".join(self.body_lines[start:end])


def _decode_entities(text: str) -> str:
    """A styled-div heading's inner text with its three entities decoded."""
    return text.replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")


def _is_own_anchor(anchor: str, id: Optional[str]) -> bool:
    """Whether *anchor* is the own anchor of a section with *id*: *id* itself,
    or a qualified form ``<A>/…/<id>`` whose segments are all non-empty
    (Section Anchors)."""
    if anchor == id:
        return True
    if id is None or not anchor.endswith("/" + id):
        return False
    return all(segment for segment in anchor.split("/"))


class DocSpecsDocument:
    """A schema-free DocSpecs markdown parse: the declared schema header (if
    any), the top-level sections, and the parse-time violations (malformed
    headings). Validation against a schema is a separate step —
    :meth:`DocSpecsValidator.validate` — which folds these violations into
    its result. A styled-div heading ``<div class="heading<N>">`` with
    N ≥ 7 is a heading of level N; a ``heading<N>`` div with N ≤ 6 is
    content."""

    _DOCSPEC_HEADER = re.compile(r"^<!--\s*docspec:\s*(\S+)\s*-->\s*$")
    _STYLED_DIV = re.compile(r'^<div class="heading([0-9]+)"[^>]*>(.*)</div>$')
    _ANCHOR = re.compile(r'^<a id="([^"]*)"></a>\s*')

    def __init__(self) -> None:
        #: The ``<!-- docspec: schema-id/version -->`` declaration, if present.
        self.declared_schema: Optional[str] = None
        #: Top-level (usually one: the document root) sections in source order.
        self.sections: list[DocSpecsSection] = []
        #: Parse-time violations: ``malformedHeading`` for each heading
        #: without a ``<!--[SECTION-ID]-->`` comment.
        self.violations: list[DocSpecsViolation] = []

    @staticmethod
    def parse(text: str) -> "DocSpecsDocument":
        """Parses *text* into the generic section tree. Any markdown is
        accepted; structural problems surface as violations, never as
        exceptions."""
        doc = DocSpecsDocument()
        fence = MarkdownFenceTracker()
        stack: list[DocSpecsSection] = []
        lines = text.split("\n")
        for i, raw in enumerate(lines):
            line_no = i + 1
            trimmed = raw.rstrip()
            if not fence.in_fence:
                if not stack and doc.declared_schema is None:
                    d = DocSpecsDocument._DOCSPEC_HEADER.match(trimmed)
                    if d is not None:
                        doc.declared_schema = d.group(1)
                        continue
                h = SpecDocumentMarkdown.heading_line.match(trimmed)
                div = (
                    None
                    if h is not None
                    else DocSpecsDocument._STYLED_DIV.fullmatch(trimmed)
                )
                div_level = int(div.group(1)) if div is not None else 0
                if h is not None or div_level >= 7:
                    if h is not None:
                        level = len(h.group(1))
                        rest = h.group(2).strip()
                    else:
                        assert div is not None
                        level = div_level
                        rest = _decode_entities(div.group(2)).strip()
                    c = SpecDocumentMarkdown.headline_comment.match(rest)
                    title = rest
                    if c is not None:
                        # group(2) is the optional key=value region
                        # (codespecs_mapping.md §9.2 codeSpec); the title is
                        # group(3), without the section's own anchor (Section
                        # Anchors). For a bare heading with no comment, the
                        # whole rest is the title.
                        title = (
                            DocSpecsDocument.strip_own_anchor(
                                c.group(3).strip(), c.group(1)
                            )
                            or rest
                        )
                    section = DocSpecsSection(
                        id=c.group(1) if c is not None else None,
                        title=title,
                        level=level,
                        line=line_no,
                    )
                    if c is None:
                        doc.violations.append(
                            DocSpecsViolation(
                                rule=DocSpecsViolationRule.MALFORMED_HEADING,
                                line=line_no,
                                message=(
                                    f'heading "{rest}" carries no '
                                    "<!--[SECTION-ID]--> headline comment"
                                ),
                            )
                        )
                    while stack and stack[-1].level >= level:
                        stack.pop()
                    (stack[-1].children if stack else doc.sections).append(
                        section
                    )
                    stack.append(section)
                    continue
            if stack:
                stack[-1].body_lines.append(raw)
            fence.feed(raw)
        return doc

    @staticmethod
    def strip_own_anchor(text: str, id: Optional[str]) -> str:
        """*text* with a leading anchor ``<a id="ID"></a>`` removed when it is
        the section's own (Section Anchors): its id is *id*, or the qualified
        form ``<A>/…/<id>`` a heading below a list item carries. Any other
        anchor is ordinary text and stays."""
        m = DocSpecsDocument._ANCHOR.match(text)
        if m is not None and _is_own_anchor(m.group(1), id):
            return text[m.end() :]
        return text

    @property
    def all_sections(self) -> list[DocSpecsSection]:
        """Every section of the document, depth-first in source order (each
        section before its children)."""
        out: list[DocSpecsSection] = []

        def walk(sections: list[DocSpecsSection]) -> None:
            for s in sections:
                out.append(s)
                walk(s.children)

        walk(self.sections)
        return out

    @staticmethod
    def replace_section_body(text: str, section_id: str, body: str) -> str:
        """Returns *text* with the body of the section whose id is
        *section_id* replaced by *body*; every other byte is kept.

        The body is the section's **own** region: the lines after its heading
        up to its first child heading, or the next heading of any level. The
        heading line (with its ``<!--[ID]-->`` comment) and the subsections
        are untouched. The region is found by the same fence-aware
        :meth:`parse`, so a ``#`` line inside a fenced block is never taken
        for a heading.

        The new region is a blank line, *body* with its leading and trailing
        blank lines removed, and a blank line; an empty *body* leaves a single
        blank line. Raises :class:`ValueError` when *section_id* names no
        section or more than one, and when *body* would change the document's
        structure: a heading outside a fenced block, or a fence it opens and
        never closes."""
        matches = [
            s
            for s in DocSpecsDocument.parse(text).all_sections
            if s.id == section_id
        ]
        if not matches:
            raise ValueError(f'sectionId "{section_id}" names no section')
        if len(matches) > 1:
            raise ValueError(
                f'sectionId "{section_id}" names {len(matches)} sections '
                f"(lines {', '.join(str(s.line) for s in matches)})"
            )

        body_lines = body.split("\n")
        while body_lines and not body_lines[0].strip():
            body_lines = body_lines[1:]
        while body_lines and not body_lines[-1].strip():
            body_lines = body_lines[:-1]
        fence = MarkdownFenceTracker()
        for line in body_lines:
            if not fence.in_fence and SpecDocumentMarkdown.heading_line.match(
                line.rstrip()
            ):
                raise ValueError(
                    f'body contains a heading outside a fenced block: "{line}"'
                )
            fence.feed(line)
        if fence.in_fence:
            raise ValueError("body leaves a fenced block open")

        section = matches[0]
        lines = text.split("\n")
        start = section.line  # 0-based index of the first body line
        end = start + len(section.body_lines)
        region = ["", *body_lines, ""] if body_lines else [""]
        return "\n".join(lines[:start] + region + lines[end:])


# ---------------------------------------------------------------------------
# 2. Schema loading
# ---------------------------------------------------------------------------


def doc_specs_id_transform(id: str) -> str:
    """The DocSpecs id transform used for prefix matching: every run of
    non-alphanumeric characters becomes ``_``."""
    return re.sub(r"[^a-zA-Z0-9_]+", "_", id)


class DocSpecsPatternCheck:
    """A ``pattern-check`` / ``pattern-check-id`` rule: the regex pattern plus
    the authored error message."""

    def __init__(
        self, *, pattern: str, error_message: Optional[str] = None
    ) -> None:
        self.pattern = pattern
        self.error_message = error_message

    def matches(self, value: str) -> bool:
        # Dart hasMatch = unanchored search.
        return re.search(self.pattern, value) is not None


class DocSpecsSubsectionRule:
    """One subsection slot of a section-type: ``min-count`` (default 0) and
    ``max-count`` (``None`` = infinite)."""

    def __init__(self, *, min_count: int, max_count: Optional[int]) -> None:
        self.min_count = min_count
        self.max_count = max_count


class DocSpecsSectionType:
    """One ``section-types:`` entry of a DocSpecs schema."""

    def __init__(
        self,
        *,
        name: str,
        prefix: str,
        pattern_check_id: Optional[DocSpecsPatternCheck] = None,
        subsection_types: Optional[dict[str, DocSpecsSubsectionRule]] = None,
        format: Optional[str] = None,
        text_required: bool = False,
        min_text_length: Optional[int] = None,
        max_text_length: Optional[int] = None,
        description: Optional[str] = None,
        validation_prompt: Optional[str] = None,
    ) -> None:
        self.name = name
        #: The id prefix (in transformed grammar) a heading id must start
        #: with to resolve to this type.
        self.prefix = prefix
        self.pattern_check_id = pattern_check_id
        #: Allowed child section-type names → cardinality.
        self.subsection_types: dict[str, DocSpecsSubsectionRule] = (
            subsection_types if subsection_types is not None else {}
        )
        #: A form-type name (``*-form``) or a raw content format
        #: (``code``, ``mermaid``).
        self.format = format
        self.text_required = text_required
        self.min_text_length = min_text_length
        self.max_text_length = max_text_length
        self.description = description
        #: Carried as data (SOM §14) — not interpreted by this validator.
        self.validation_prompt = validation_prompt


class DocSpecsFormField:
    """One field of a ``form-types:`` entry."""

    def __init__(
        self,
        *,
        name: str,
        required: bool = False,
        description: Optional[str] = None,
        pattern_check: Optional[DocSpecsPatternCheck] = None,
    ) -> None:
        self.name = name
        self.required = required
        self.description = description
        self.pattern_check = pattern_check


class DocSpecsFormType:
    """One ``form-types:`` entry: an ordered field list."""

    def __init__(self, *, name: str, fields: list[DocSpecsFormField]) -> None:
        self.name = name
        self.fields = fields


class DocSpecsDocumentSection:
    """One ``document: sections:`` slot: the backing section-type, whether
    the slot is optional, and its ``position`` — ``relative`` (the default:
    in the order of ``document: sections:``) or ``any`` (anywhere among the
    root's children; the order check leaves it out)."""

    #: The ``position`` values a document section may take.
    POSITIONS = ("relative", "any")

    def __init__(
        self, *, section_type: str, optional: bool, position: str = "relative"
    ) -> None:
        self.section_type = section_type
        self.optional = optional
        self.position = position

    @property
    def any_position(self) -> bool:
        """Whether the section may stand anywhere among the root's children."""
        return self.position == "any"


def _is_int(value: Any) -> bool:
    """Dart ``is int`` — Python ``bool`` is a subclass of ``int``, guard it."""
    return isinstance(value, int) and not isinstance(value, bool)


class DocSpecsSchema:
    """A loaded ``*.docspecs-schema.yaml`` (the schema-generator output format , SOM §13): the
    ``title-format``, the ordered section-types (file order — descending
    prefix length in generated schemas, so first-startsWith-match is
    longest-prefix resolution), the form-types, and the document sections.
    Schema features outside the SOM §14 scope are ignored on load and named in
    :attr:`warnings`."""

    _SECTION_TYPE_KEYS = {
        "prefix",
        "pattern-check-id",
        "subsection-types",
        "format",
        "text-required",
        "min-text-length",
        "max-text-length",
        "description",
        "validation-prompt",
    }

    def __init__(self) -> None:
        self.title_format: Optional[str] = None
        #: Section types in file order; resolution takes the **first** type
        #: whose prefix is a prefix of the transformed id.
        self.section_types: list[DocSpecsSectionType] = []
        self.section_types_by_name: dict[str, DocSpecsSectionType] = {}
        self.form_types: dict[str, DocSpecsFormType] = {}
        self.document_sections: dict[str, DocSpecsDocumentSection] = {}
        #: Every schema feature encountered but not interpreted, named
        #: (nothing is silently dropped).
        self.warnings: list[str] = []

    @property
    def root_section_id(self) -> Optional[str]:
        """The root section id demanded by ``title-format``, when derivable."""
        tf = self.title_format
        if tf is None:
            return None
        m = re.search(r"<!--\[([^\]]+)\]-->", tf)
        return m.group(1) if m is not None else None

    @staticmethod
    def from_yaml_text(text: str) -> "DocSpecsSchema":
        """Loads a schema from its YAML *text*. Malformed YAML raises;
        unsupported features are collected into :attr:`warnings` instead."""
        schema = DocSpecsSchema()
        root = yaml.safe_load(text)
        if not isinstance(root, dict):
            raise ValueError("docspecs schema must be a YAML map")
        for key, value in root.items():
            k = str(key)
            if k == "title-format":
                schema.title_format = str(value)
            elif k == "section-types":
                DocSpecsSchema._load_section_types(schema, value)
            elif k == "form-types":
                DocSpecsSchema._load_form_types(schema, value)
            elif k == "document":
                DocSpecsSchema._load_document(schema, value)
            elif k in ("schema", "version", "name", "description"):
                pass  # informational headers — accepted, no semantics here.
            else:
                schema.warnings.append(
                    f'unsupported top-level schema key "{k}" ignored'
                )
        return schema

    @staticmethod
    def _pattern_check(node: Any) -> Optional[DocSpecsPatternCheck]:
        if node is None:
            return None
        if isinstance(node, dict):
            em = node.get("error-message")
            return DocSpecsPatternCheck(
                pattern=str(node.get("pattern")),
                error_message=None if em is None else str(em),
            )
        return DocSpecsPatternCheck(pattern=str(node))

    @staticmethod
    def _load_section_types(schema: "DocSpecsSchema", node: Any) -> None:
        if not isinstance(node, dict):
            return
        for entry_key, st in node.items():
            name = str(entry_key)
            if not isinstance(st, dict):
                continue
            subs: dict[str, DocSpecsSubsectionRule] = {}
            subs_node = st.get("subsection-types")
            if isinstance(subs_node, dict):
                for s_key, rule in subs_node.items():
                    min_v = rule.get("min-count") if isinstance(rule, dict) else None
                    max_v = rule.get("max-count") if isinstance(rule, dict) else None
                    subs[str(s_key)] = DocSpecsSubsectionRule(
                        min_count=min_v if _is_int(min_v) else 0,
                        # 'infinite' or absent → None
                        max_count=max_v if _is_int(max_v) else None,
                    )
            for key in st.keys():
                if str(key) not in DocSpecsSchema._SECTION_TYPE_KEYS:
                    schema.warnings.append(
                        f'unsupported key "{key}" on section-type '
                        f'"{name}" ignored'
                    )
            prefix = st.get("prefix")
            if prefix is None:
                prefix = doc_specs_id_transform(name.upper())
            fmt = st.get("format")
            min_tl = st.get("min-text-length")
            max_tl = st.get("max-text-length")
            desc = st.get("description")
            vp = st.get("validation-prompt")
            type_ = DocSpecsSectionType(
                name=name,
                prefix=str(prefix),
                pattern_check_id=DocSpecsSchema._pattern_check(
                    st.get("pattern-check-id")
                ),
                subsection_types=subs,
                format=None if fmt is None else str(fmt),
                text_required=st.get("text-required") is True,
                min_text_length=min_tl if _is_int(min_tl) else None,
                max_text_length=max_tl if _is_int(max_tl) else None,
                description=None if desc is None else str(desc),
                validation_prompt=None if vp is None else str(vp),
            )
            schema.section_types.append(type_)
            schema.section_types_by_name[name] = type_

    @staticmethod
    def _load_form_types(schema: "DocSpecsSchema", node: Any) -> None:
        if not isinstance(node, dict):
            return
        for entry_key, ft in node.items():
            name = str(entry_key)
            if not isinstance(ft, dict):
                continue
            for key in ft.keys():
                if str(key) != "fields":
                    schema.warnings.append(
                        f'unsupported key "{key}" on form-type '
                        f'"{name}" ignored'
                    )
            fields: list[DocSpecsFormField] = []
            fields_node = ft.get("fields")
            if isinstance(fields_node, list):
                for f in fields_node:
                    if not isinstance(f, dict):
                        continue
                    desc = f.get("description")
                    fields.append(
                        DocSpecsFormField(
                            name=str(f.get("fieldname")),
                            required=f.get("required") is True,
                            description=None if desc is None else str(desc),
                            pattern_check=DocSpecsSchema._pattern_check(
                                f.get("pattern-check")
                            ),
                        )
                    )
            schema.form_types[name] = DocSpecsFormType(
                name=name, fields=fields
            )

    @staticmethod
    def _load_document(schema: "DocSpecsSchema", node: Any) -> None:
        if not isinstance(node, dict):
            return
        for key, value in node.items():
            k = str(key)
            if k == "sections":
                if not isinstance(value, dict):
                    continue
                for s_key, v in value.items():
                    position = "relative"
                    if isinstance(v, dict):
                        st = v.get("section-type")
                        section_type = str(st if st is not None else s_key)
                        optional = v.get("optional") is True
                        p = v.get("position")
                        if p is not None:
                            position = str(p)
                            if position not in DocSpecsDocumentSection.POSITIONS:
                                raise ValueError(
                                    f'document section "{s_key}": position '
                                    f'"{position}" is not one of relative, any'
                                )
                    else:
                        section_type = str(s_key)
                        optional = False
                    schema.document_sections[str(s_key)] = (
                        DocSpecsDocumentSection(
                            section_type=section_type,
                            optional=optional,
                            position=position,
                        )
                    )
            elif k not in ("name", "description"):
                schema.warnings.append(
                    f'unsupported document key "{k}" ignored'
                )

    def resolve_section_type(self, id: str) -> Optional[DocSpecsSectionType]:
        """Resolves a heading *id* to its section-type: the first type (file
        order) whose prefix prefixes the transformed id."""
        transformed = doc_specs_id_transform(id)
        for t in self.section_types:
            if transformed.startswith(t.prefix):
                return t
        return None


# ---------------------------------------------------------------------------
# 3. Validation
# ---------------------------------------------------------------------------


class DocSpecsValidator:
    """Validates a schema-free :class:`DocSpecsDocument` against a
    :class:`DocSpecsSchema` (SOM §14). Stateless per document;
    :meth:`validate` always returns the complete violation list (never
    fail-fast); a document is valid iff it is empty.

    It reads the reading view beside the ``Field:`` layout (DocSpecs
    specification, List Bodies): form tables, ``refs`` lines and ``records``
    tables as a list's virtual items, section tables at their rows, and the
    styled-div headings :class:`DocSpecsDocument` parses."""

    _FIELD_LABEL = re.compile(r"^([A-Za-z][A-Za-z0-9_]*): ?(.*)$")

    def __init__(self, schema: DocSpecsSchema, tom_specs: bool = False) -> None:
        self.schema = schema
        #: The documents are TomSpecs renditions: the reading notation is then
        #: scanned value by value (a form field's value apart from the next),
        #: and a div without a class and an unregistered kind are reported too.
        self.tom_specs = tom_specs is True

    def validate_markdown(self, markdown: str) -> list[DocSpecsViolation]:
        """Convenience: parse + validate in one call."""
        return self.validate(DocSpecsDocument.parse(markdown))

    def validate(self, doc: DocSpecsDocument) -> list[DocSpecsViolation]:
        v: list[DocSpecsViolation] = list(doc.violations)
        if not doc.sections:
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.FORMAT_MISMATCH,
                    line=1,
                    message="document has no root heading",
                )
            )
            return v
        root_id = self.schema.root_section_id
        root = doc.sections[0]
        if root_id is not None and root.id != root_id:
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.FORMAT_MISMATCH,
                    section_id=root.id,
                    line=root.line,
                    message=(
                        f'root heading id "{root.id}" does not match the '
                        f'schema title-format id "{root_id}"'
                    ),
                )
            )
        for extra in doc.sections[1:]:
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.UNKNOWN_SECTION,
                    section_id=extra.id,
                    line=extra.line,
                    message="unexpected additional top-level section",
                )
            )
        self._validate_document_sections(_Node.of(root), v)
        self._validate_notation(doc, v)
        self._validate_id_paths(doc.sections, v)
        return v

    def _validate_notation(
        self, doc: DocSpecsDocument, v: list[DocSpecsViolation]
    ) -> None:
        """The reading notation of every section's own body: one value per
        section, and in a TomSpecs rendition one per form field of a
        form-formatted section (its preamble included)."""
        for section in doc.all_sections:
            for first, lines in self._notation_values(section):
                scan = scan_notation("\n".join(lines), tom_specs=self.tom_specs)
                for f in scan.findings:
                    v.append(
                        DocSpecsViolation(
                            rule=DocSpecsViolationRule(f.code.value),
                            section_id=section.id,
                            line=section.body_start_line + first + f.line - 1,
                            message=f.message,
                        )
                    )

    def _notation_values(
        self, section: DocSpecsSection
    ) -> list[tuple[int, list[str]]]:
        """The values of *section*'s own body as (index of the first line,
        lines)."""
        body = section.body_lines
        type_ = (
            self.schema.resolve_section_type(section.id)
            if self.tom_specs and section.id is not None
            else None
        )
        form = (
            self.schema.form_types.get(type_.format)
            if type_ is not None and type_.format is not None
            else None
        )
        if form is None:
            return [(0, body)]
        labels = {f.name.lower() for f in form.fields}
        values: list[tuple[int, list[str]]] = []
        fence = MarkdownFenceTracker()
        first = 0
        for i, line in enumerate(body):
            if not fence.in_fence and i > first:
                m = DocSpecsValidator._FIELD_LABEL.match(line)
                if m is not None and m.group(1).lower() in labels:
                    values.append((first, body[first:i]))
                    first = i
            fence.feed(line)
        values.append((first, body[first:]))
        return values

    def _validate_id_paths(
        self, sections: list[DocSpecsSection], v: list[DocSpecsViolation]
    ) -> None:
        """Every section's id path (the ids from the root down to it) is
        unique: a section whose id repeats an earlier sibling's is a
        ``duplicateIdPath``. Its descendants repeat paths only through it and
        are not reported again. Sections without an id are skipped (already
        ``malformedHeading``). Depth-first, source order."""
        seen: set[str] = set()
        for s in sections:
            if s.id is not None:
                if s.id in seen:
                    v.append(
                        DocSpecsViolation(
                            rule=DocSpecsViolationRule.DUPLICATE_ID_PATH,
                            section_id=s.id,
                            line=s.line,
                            message=(
                                f'section id "{s.id}" repeats a sibling\'s id, '
                                "so its id path is not unique"
                            ),
                        )
                    )
                    continue
                seen.add(s.id)
            self._validate_id_paths(s.children, v)

    def _validate_document_sections(
        self, root: "_Node", v: list[DocSpecsViolation]
    ) -> None:
        """Root children must occupy ``document: sections:`` slots, in their
        order (a ``position: any`` slot's type stands anywhere); required
        slots must be present. A section table in the root's body rebuilds
        root children as virtual sections first."""
        slots = list(self.schema.document_sections.values())
        slot_types = {s.section_type for s in slots}
        anywhere = {s.section_type for s in slots if s.any_position}
        order = [None if s.any_position else s.section_type for s in slots]
        self._expand_section_tables(root, lambda t: t.name in slot_types, v)
        last_index = -1
        counts: dict[str, int] = {}
        for child in root.children:
            type_ = self._resolve_child(child, v)
            if type_ is None:
                continue
            if type_.name not in slot_types:
                v.append(
                    DocSpecsViolation(
                        rule=DocSpecsViolationRule.UNKNOWN_SECTION,
                        section_id=child.id,
                        line=child.line,
                        message=(
                            f'section-type "{type_.name}" is not a top-level '
                            "document section"
                        ),
                    )
                )
                continue
            if type_.name not in anywhere:
                last_index = self._check_order(
                    child, type_.name, order, last_index, v
                )
            counts[type_.name] = counts.get(type_.name, 0) + 1
            self._validate_section(child, type_, v)
        for slot_key, slot in self.schema.document_sections.items():
            if not slot.optional and counts.get(slot.section_type, 0) == 0:
                v.append(
                    DocSpecsViolation(
                        rule=DocSpecsViolationRule.MISSING_REQUIRED_SECTION,
                        section_id=slot_key,
                        line=root.line,
                        message=(
                            f'required document section "{slot_key}" '
                            f'(type "{slot.section_type}") is missing'
                        ),
                    )
                )

    @staticmethod
    def _check_order(
        child: "_Node",
        type_name: str,
        order: list[Optional[str]],
        last_index: int,
        v: list[DocSpecsViolation],
    ) -> int:
        """The order check of one root child: its slot is the first of its
        type at or after the last slot taken, else the first of its type
        anywhere; a slot before the last one taken is ``sectionOutOfOrder``.
        Answers the last slot taken afterwards."""
        index = -1
        for i in range(max(last_index, 0), len(order)):
            if order[i] == type_name:
                index = i
                break
        if index == -1 and type_name in order:
            index = order.index(type_name)
        if index == -1:
            return last_index
        if index < last_index:
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.SECTION_OUT_OF_ORDER,
                    section_id=child.id,
                    line=child.line,
                    message=(
                        f'section "{child.id}" (type "{type_name}") stands '
                        "out of the order of the document sections"
                    ),
                )
            )
            return last_index
        return index

    def _resolve_child(
        self, child: "_Node", v: list[DocSpecsViolation]
    ) -> Optional[DocSpecsSectionType]:
        if child.type is not None:
            return child.type  # a virtual list item: the schema's type.
        id = child.id
        if id is None:
            return None  # already reported as malformedHeading.
        type_ = self.schema.resolve_section_type(id)
        if type_ is None:
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.UNKNOWN_SECTION,
                    section_id=id,
                    line=child.line,
                    message=(
                        f'section id "{id}" resolves to no section-type of '
                        "the schema"
                    ),
                )
            )
        return type_

    def _validate_section(
        self,
        section: "_Node",
        type_: DocSpecsSectionType,
        v: list[DocSpecsViolation],
    ) -> None:
        id = section.id
        pc = type_.pattern_check_id
        if pc is not None and id is not None and not pc.matches(id):
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.ID_PATTERN_MISMATCH,
                    section_id=id,
                    line=section.line,
                    message=pc.error_message
                    or (
                        f'section id "{id}" does not match pattern '
                        f'"{pc.pattern}"'
                    ),
                )
            )

        # List bodies and section tables become virtual sections before
        # anything is counted or checked (DocSpecs specification, List Bodies).
        self._expand_section_tables(
            section, lambda t: t.name in type_.subsection_types, v
        )
        self._expand_list_body(section, type_, v)
        self._validate_text(section, type_, v)
        self._validate_format(section, type_, v)

        # Children: membership + cardinality against subsection-types.
        counts: dict[str, int] = {}
        for child in section.children:
            child_type = self._resolve_child(child, v)
            if child_type is None:
                continue
            if child_type.name not in type_.subsection_types:
                v.append(
                    DocSpecsViolation(
                        rule=DocSpecsViolationRule.UNKNOWN_SECTION,
                        section_id=child.id,
                        line=child.line,
                        message=(
                            f'section-type "{child_type.name}" is not an '
                            f'allowed subsection of "{type_.name}"'
                        ),
                    )
                )
                continue
            counts[child_type.name] = counts.get(child_type.name, 0) + 1
            self._validate_section(child, child_type, v)
        for sub_key, sub in type_.subsection_types.items():
            count = counts.get(sub_key, 0)
            if count < sub.min_count:
                if count == 0:
                    v.append(
                        DocSpecsViolation(
                            rule=DocSpecsViolationRule.MISSING_REQUIRED_SECTION,
                            section_id=id,
                            line=section.line,
                            message=(
                                f'required subsection "{sub_key}" of '
                                f'"{type_.name}" is missing'
                            ),
                        )
                    )
                else:
                    v.append(
                        DocSpecsViolation(
                            rule=DocSpecsViolationRule.TOO_FEW_ITEMS,
                            section_id=id,
                            line=section.line,
                            message=(
                                f'subsection "{sub_key}" occurs {count} '
                                f"time(s), minimum is {sub.min_count}"
                            ),
                        )
                    )
            max_ = sub.max_count
            if max_ is not None and count > max_:
                v.append(
                    DocSpecsViolation(
                        rule=DocSpecsViolationRule.TOO_MANY_ITEMS,
                        section_id=id,
                        line=section.line,
                        message=(
                            f'subsection "{sub_key}" occurs {count} time(s), '
                            f"maximum is {max_}"
                        ),
                    )
                )

    def _validate_text(
        self,
        section: "_Node",
        type_: DocSpecsSectionType,
        v: list[DocSpecsViolation],
    ) -> None:
        # Form-formatted sections carry field lines, not free text.
        if type_.format is not None and type_.format in self.schema.form_types:
            return
        # A list body or section table already read is blanked in the body,
        # so a container written with one counts as empty
        # (`max-text-length: 0`); the rendition's marker and generated block
        # are no text either. An empty body passes the length bounds: only
        # `text-required` asks for text.
        text = _without_generated_text(section.text)
        if type_.text_required and not text:
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.TEXT_REQUIRED,
                    section_id=section.id,
                    line=section.line,
                    message="section requires body text but has none",
                )
            )
            return
        if not text:
            return
        min_ = type_.min_text_length
        max_ = type_.max_text_length
        if (min_ is not None and len(text) < min_) or (
            max_ is not None and len(text) > max_
        ):
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.TEXT_LENGTH_OUT,
                    section_id=section.id,
                    line=section.line,
                    message=(
                        f"body text length {len(text)} is outside "
                        f"[{min_ if min_ is not None else 0}, "
                        f"{max_ if max_ is not None else '∞'}]"
                    ),
                )
            )

    def _validate_format(
        self,
        section: "_Node",
        type_: DocSpecsSectionType,
        v: list[DocSpecsViolation],
    ) -> None:
        format_ = type_.format
        # Values a section table or list body gave a section the schema
        # declares no form for are virtual body lines, counted in its text
        # (_Node.text).
        if not format_:
            return
        form = self.schema.form_types.get(format_)
        if form is not None:
            self._validate_form(section, form, v)
            return
        # A non-form format (`code`, `mermaid`, …) demands a fenced block.
        fence = MarkdownFenceTracker()
        saw_fence = False
        for line in section.body:
            fence.feed(line)
            if fence.in_fence:
                saw_fence = True
        if not saw_fence:
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.FORMAT_MISMATCH,
                    section_id=section.id,
                    line=section.line,
                    message=(
                        f'section format "{format_}" demands a fenced code '
                        "block, but the body contains none"
                    ),
                )
            )

    def _validate_form(
        self,
        section: "_Node",
        form: DocSpecsFormType,
        v: list[DocSpecsViolation],
    ) -> None:
        """Parses the section body in the DocSpecs plain-text form format
        (``FieldName: value``, case-insensitive labels, continuation lines)
        and its form tables (``TomSpecField | Value``), takes the values a
        section table or list body gave the section, and checks required
        fields and field pattern-checks. A field given twice keeps its first
        occurrence and reports the second (``malformedBlock``): a ``Field:``
        label counts as given even with an empty value, a row only with a
        value. A row naming no field is ``unknownField``. Text before the
        first recognised label is tolerated here (the binding parse reports
        it)."""
        by_lower = {f.name.lower(): f for f in form.fields}
        # Every occurrence of a field, from a `Field:` label or a row.
        occurrences: list[_FieldValue] = []
        fence = MarkdownFenceTracker()
        body = section.body
        start_line = section.body_start_line
        current: Optional[str] = None
        current_line = 0
        current_lines: list[str] = []

        def flush() -> None:
            if current is not None:
                occurrences.append(
                    _FieldValue(
                        current,
                        "\n".join(current_lines).strip(),
                        current_line,
                        True,
                    )
                )

        i = 0
        while i < len(body):
            line = body[i]
            if not fence.in_fence:
                header = SpecDocumentMarkdown.layout_table_header.match(line)
                if header is not None and header.group(1) is None:
                    # A form table ends the open field; its rows are fields.
                    flush()
                    current = None
                    table = _read_table(body, i, start_line, section.id, v)
                    for row in table.rows:
                        occurrences.append(
                            _FieldValue(
                                row.cells[0],
                                _cell_value(row.cells[1]),
                                start_line + row.index,
                                False,
                            )
                        )
                    i = table.end
                    continue
                m = DocSpecsValidator._FIELD_LABEL.match(line)
                field = (
                    by_lower.get(m.group(1).lower()) if m is not None else None
                )
                if field is not None:
                    assert m is not None
                    flush()
                    current = field.name
                    current_line = start_line + i
                    current_lines = [m.group(2)]
                    fence.feed(line)
                    i += 1
                    continue
            if current is not None:
                current_lines.append(line)
            fence.feed(line)
            i += 1
        flush()
        occurrences.extend(section.values)
        # Source order decides which occurrence is the first; values from a
        # parent's section table stand above the section's own body. The sort
        # is stable, so occurrences of one line keep their order.
        occurrences.sort(key=lambda o: o.line)

        values: dict[str, str] = {}
        field_lines: dict[str, int] = {}
        given: set[str] = set()
        for o in occurrences:
            field = by_lower.get(o.label.lower())
            if field is None:
                v.append(
                    DocSpecsViolation(
                        rule=DocSpecsViolationRule.UNKNOWN_FIELD,
                        section_id=section.id,
                        line=o.line,
                        message=(
                            f'row "{o.label}" names no field of "{form.name}"'
                        ),
                    )
                )
                continue
            if not o.from_label and not o.value:
                continue
            if field.name in given:
                v.append(
                    DocSpecsViolation(
                        rule=DocSpecsViolationRule.MALFORMED_BLOCK,
                        section_id=section.id,
                        line=o.line,
                        message=f'field "{field.name}" given twice',
                    )
                )
                continue
            given.add(field.name)
            field_lines[field.name] = o.line
            if o.value:
                values[field.name] = o.value

        for field in form.fields:
            value = values.get(field.name, "")
            if field.required and not value:
                v.append(
                    DocSpecsViolation(
                        rule=DocSpecsViolationRule.MISSING_REQUIRED_FIELD,
                        section_id=section.id,
                        line=section.line,
                        message=(
                            f'required form field "{field.name}" of '
                            f'"{form.name}" is missing'
                        ),
                    )
                )
                continue
            pc = field.pattern_check
            if value and pc is not None and not pc.matches(value):
                v.append(
                    DocSpecsViolation(
                        rule=DocSpecsViolationRule.FIELD_PATTERN_MISMATCH,
                        section_id=section.id,
                        line=field_lines.get(field.name, section.line),
                        message=pc.error_message
                        or (
                            f'form field "{field.name}" does not match '
                            f'pattern "{pc.pattern}"'
                        ),
                    )
                )

    # --- Tables and list bodies (DocSpecs specification, List Bodies) -------

    def _expand_section_tables(
        self,
        node: "_Node",
        allowed: Callable[[DocSpecsSectionType], bool],
        v: list[DocSpecsViolation],
    ) -> None:
        """Reads every section table of *node*'s body (header
        ``Section | TomSpecField | Value``): each row's ``Section`` cell names
        a child — by its id relative to *node*, a list item as
        ``<LIST> / <ITEM>``, an empty cell the row above's — and its
        ``TomSpecField`` / ``Value`` cells become that child's form values. A
        child without a heading becomes a virtual section; one whose id
        resolves to no type *allowed* under *node* is ``unknownSection`` at the
        row, and its rows are skipped. The table's lines are blanked."""
        body = node.body
        fence = MarkdownFenceTracker()
        first_line = node.body_start_line
        i = 0
        while i < len(body):
            line = body[i]
            h = (
                None
                if fence.in_fence
                else SpecDocumentMarkdown.layout_table_header.match(line)
            )
            if h is None or h.group(1) is None:
                fence.feed(line)
                i += 1
                continue
            table = _read_table(body, i, first_line, node.id, v)
            target: Optional[_Node] = None
            skip = False
            for row in table.rows:
                at = first_line + row.index
                cell = _cell_id(row.cells[0])
                if cell:
                    target = self._section_table_target(node, cell, allowed, at)
                    skip = target is None
                    if target is None:
                        v.append(
                            DocSpecsViolation(
                                rule=DocSpecsViolationRule.UNKNOWN_SECTION,
                                section_id=cell,
                                line=at,
                                message=(
                                    "section-table row names no child section "
                                    f'of "{node.id}"'
                                ),
                            )
                        )
                        continue
                elif skip:
                    continue  # the rejected child's further rows
                elif target is None:
                    v.append(
                        DocSpecsViolation(
                            rule=DocSpecsViolationRule.UNKNOWN_SECTION,
                            section_id=node.id,
                            line=at,
                            message="section-table row names no section",
                        )
                    )
                    continue
                target.values.append(
                    _FieldValue(row.cells[1], _cell_value(row.cells[2]), at, False)
                )
            for k in range(i, table.end):
                body[k] = ""
            i = table.end

    def _section_table_target(
        self,
        node: "_Node",
        cell: str,
        allowed: Callable[[DocSpecsSectionType], bool],
        line: int,
    ) -> Optional["_Node"]:
        """The child a section-table ``Section`` cell names under *node*: a
        child section by its id, or ``<LIST> / <ITEM>`` — an item of a child
        list. A child or item without a heading is created as a virtual
        section when its id resolves to a type allowed where it stands;
        ``None`` otherwise."""
        parts = _CELL_PART_SEPARATOR.split(cell)
        if len(parts) > 2:
            return None
        first = self._table_child(node, parts[0], allowed, line)
        if len(parts) == 1 or first is None:
            return first
        list_type = (
            first.type
            if first.type is not None
            else self.schema.resolve_section_type(parts[0])
        )
        if list_type is None:
            return None
        return self._table_child(
            first, parts[1], lambda t: t.name in list_type.subsection_types, line
        )

    def _table_child(
        self,
        parent: "_Node",
        id: str,
        ok: Callable[[DocSpecsSectionType], bool],
        line: int,
    ) -> Optional["_Node"]:
        """The child of *parent* with *id*, created virtual when *ok* allows
        its type."""
        for c in parent.children:
            if c.id == id:
                return c
        t = self.schema.resolve_section_type(id)
        if t is None or not ok(t):
            return None
        created = _Node(id, line, [], None)
        parent.children.append(created)
        return created

    def _expand_list_body(
        self,
        node: "_Node",
        type_: DocSpecsSectionType,
        v: list[DocSpecsViolation],
    ) -> None:
        """A list container's body: one ``refs`` div (a reference line) or one
        ``records`` div (a record table) stands for its items when the
        container has no item heading; the items become virtual sections of
        the container's one subsection type, and the div's lines are
        blanked."""
        body = node.body
        fence = MarkdownFenceTracker()
        for i, line in enumerate(body):
            open_ = None if fence.in_fence else _LIST_DIV_OPEN.fullmatch(line)
            if open_ is None:
                fence.feed(line)
                continue
            kind = open_.group(1) or open_.group(2)
            at = node.body_start_line + i
            close = -1
            for k in range(i + 1, len(body)):
                if _DIV_CLOSE.fullmatch(body[k]):
                    close = k
                    break
            if close < 0:
                # Its lines stay text.
                _malformed(node, at, f"unclosed {kind} fence", v)
                return
            lead = _generated_lead(body)
            beside_text = any(
                (k < i or k > close) and body[k].strip()
                for k in range(lead, len(body))
            )
            has_items = bool(node.children)
            inner = body[i + 1 : close]
            for k in range(i, close + 1):
                body[k] = ""
            if beside_text or has_items:
                what = "item headings" if has_items else "other text"
                _malformed(
                    node,
                    at,
                    f"a {kind} div beside {what} in a list container",
                    v,
                )
                return
            item_type = (
                self.schema.section_types_by_name.get(
                    next(iter(type_.subsection_types))
                )
                if len(type_.subsection_types) == 1
                else None
            )
            if item_type is None:
                _malformed(
                    node,
                    at,
                    f"a {kind} div in a section that is not a list container",
                    v,
                )
                return
            if kind == "refs":
                self._refs_items(node, item_type, inner, at)
            else:
                self._record_items(node, item_type, inner, at, v)
            return

    def _form_of(
        self, t: Optional[DocSpecsSectionType]
    ) -> Optional[DocSpecsFormType]:
        if t is None or t.format is None:
            return None
        return self.schema.form_types.get(t.format)

    def _refs_form(
        self, item_type: DocSpecsSectionType
    ) -> Optional[tuple[DocSpecsFormType, Optional[DocSpecsSectionType]]]:
        """The one-field form a ``refs`` item of *item_type* holds its
        reference in, with the virtual child type holding it: the type's own
        form, else the form of its one subsection type that has one (the
        item's virtual child then carries the value); ``None`` when the schema
        gives none. A record table reads the type's own form only
        (:meth:`_record_items`)."""
        own = self._form_of(item_type)
        if own is not None and len(own.fields) == 1:
            return own, None
        found: Optional[
            tuple[DocSpecsFormType, Optional[DocSpecsSectionType]]
        ] = None
        for name in item_type.subsection_types:
            sub = self.schema.section_types_by_name.get(name)
            f = self._form_of(sub)
            if f is not None and len(f.fields) == 1:
                if found is not None:
                    return None  # more than one candidate
                found = (f, sub)
        return found

    def _refs_items(
        self,
        node: "_Node",
        item_type: DocSpecsSectionType,
        inner: list[str],
        at: int,
    ) -> None:
        """A ``refs`` div: its text split on commas and whitespace into ids, a
        link counting as its link text; item <n> gets the positional id (the
        container's id with ``-LST`` replaced by ``-<n>``, else ``<id>-<n>``)
        and the virtual body line ``<Label>: <id>``. Without a one-field form
        in the schema the reference is the item's virtual body line; nothing
        in the schema checks it further."""
        target = self._refs_form(item_type)
        container = node.id or ""
        stem = container[:-4] if container.endswith("-LST") else container
        n = 0
        for token in _REF_SEPARATOR.split(" ".join(inner)):
            if not token:
                continue
            n += 1
            m = _LINK_TEXT.search(token)
            id = m.group(1) if m is not None else token
            holder = _add_item(
                node,
                item_type,
                target[1] if target is not None else None,
                f"{stem}-{n}",
                at,
            )
            label = target[0].fields[0].name if target is not None else ""
            holder.values.append(_FieldValue(label, id, at, False))

    def _record_items(
        self,
        node: "_Node",
        item_type: DocSpecsSectionType,
        inner: list[str],
        at: int,
        v: list[DocSpecsViolation],
    ) -> None:
        """A ``records`` div: one table, ``Id`` first, ``Title`` optionally
        second, then field names of the item's form; each row one virtual
        item in row order."""
        start = next((k for k, line in enumerate(inner) if line.strip()), -1)
        if start < 0 or not _TABLE_LINE.match(inner[start]):
            _malformed(node, at, "a records div holding no table", v)
            return
        header = _row_cells(inner[start])
        if header[0] != "Id":
            _malformed(node, at, "a records table whose first column is not Id", v)
            return
        # The item type's own form decides the columns; an item type the
        # schema gives no form of its own takes its columns as virtual body
        # lines unchecked. A record's cells are the item's own body lines
        # (DocSpecs specification, The record table): unlike a `refs`
        # reference they never go to a child's form.
        own = self._form_of(item_type)
        first_column = 2 if len(header) > 1 and header[1] == "Title" else 1
        columns: list[str] = []
        for label in header[first_column:]:
            name: Optional[str] = label if own is None else None
            if own is not None:
                for f in own.fields:
                    if f.name.lower() == label.lower():
                        name = f.name
                        break
            if name is None:
                v.append(
                    DocSpecsViolation(
                        rule=DocSpecsViolationRule.UNKNOWN_FIELD,
                        section_id=node.id,
                        line=at + 1 + start,
                        message=(
                            f'records column "{label}" names no field of the '
                            "items"
                        ),
                    )
                )
                return
            columns.append(name)
        table = _read_table(inner, start, at + 1, node.id, v)
        for row in table.rows:
            line = at + 1 + row.index
            holder = _add_item(node, item_type, None, _cell_id(row.cells[0]), line)
            for c, column in enumerate(columns):
                value = _cell_value(row.cells[first_column + c])
                if value:
                    holder.values.append(_FieldValue(column, value, line, False))


# ---------------------------------------------------------------------------
# 3b. The reading view's tables and list bodies (DocSpecs specification,
#     List Bodies): lines, cells and the walk's sections
# ---------------------------------------------------------------------------

# A line that starts a table row: `|` after up to three spaces.
_TABLE_LINE = re.compile(r"^ {0,3}\|")
_DELIMITER_CELL = re.compile(r"^:?-+:?$")
_LINK_CELL = re.compile(r"^\[[^\]]+\]\([^)]*\)(, \[[^\]]+\]\([^)]*\))*$")
_LINK_TEXT = re.compile(r"\[([^\]]+)\]\([^)]*\)")
_CELL_ANCHOR = re.compile(r'<a id="([^"]*)"></a>\s*')
_CELL_PART_SEPARATOR = re.compile(r"\s*/\s*")
_CELL_LINK = re.compile(r"\[([^\]]+)\]\([^)\s]*\)")
_LIST_DIV_OPEN = re.compile(
    r"^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$"
)
_DIV_CLOSE = re.compile(r"^:{3,}\s*$")
_REF_SEPARATOR = re.compile(r"[,\s]+")
_LINKED_PARAGRAPH = re.compile(r"^\[.*\]\{\.linked\}$")
_DERIVED_OPEN = re.compile(r"^ {0,3}(:{3,})[ \t]*\{\.derived(?=[\s}])")


class _FieldValue:
    """One value of a form field: from a ``Field:`` label, a table row or a
    list body."""

    __slots__ = ("label", "value", "line", "from_label")

    def __init__(self, label: str, value: str, line: int, from_label: bool) -> None:
        #: The field's label as written; empty for a reference no form names.
        self.label = label
        self.value = value
        self.line = line
        #: Whether a ``Field:`` label gave it (given even when empty).
        self.from_label = from_label


class _TableRow:
    """A body row of a table: its index in the lines read, and its cells."""

    __slots__ = ("index", "cells")

    def __init__(self, index: int, cells: list[str]) -> None:
        self.index = index
        self.cells = cells


class _Table:
    """A table as read: its header cells, its well-formed rows, the index
    after it."""

    __slots__ = ("header", "rows", "end")

    def __init__(self, header: list[str], end: int) -> None:
        self.header = header
        self.rows: list[_TableRow] = []
        self.end = end


class _Node:
    """A section as the validator walks it: a parsed :class:`DocSpecsSection`,
    or a virtual one rebuilt from a list body or a section table (the DocSpecs
    specification's List Bodies). The body is a copy, so blanking a table or
    div never touches the parsed document."""

    def __init__(
        self,
        id: Optional[str],
        line: int,
        body: list[str],
        type_: Optional[DocSpecsSectionType],
    ) -> None:
        self.id = id
        #: The heading's line, or the row's or div's line of a virtual section.
        self.line = line
        #: The own body lines; a list body or section table already read is
        #: blank.
        self.body = body
        #: The section-type of a virtual list item, given by the schema.
        self.type = type_
        self.children: list[_Node] = []
        #: Form values given by a table row or a list body.
        self.values: list[_FieldValue] = []

    @staticmethod
    def of(s: DocSpecsSection) -> "_Node":
        """The walk's view of a parsed section and its subtree."""
        n = _Node(s.id, s.line, list(s.body_lines), None)
        n.children = [_Node.of(c) for c in s.children]
        return n

    @property
    def body_start_line(self) -> int:
        return self.line + 1

    @property
    def text(self) -> str:
        """The trimmed body text, after the virtual body lines of
        :attr:`values` — the text the same section has in the fields layout,
        where a section without a form in the schema carries its values as
        ``FieldName:`` lines."""
        lines = [
            fv.value if not fv.label else f"{fv.label}: {fv.value}"
            for fv in self.values
        ]
        lines.extend(self.body)
        start = 0
        end = len(lines)
        while start < end and not lines[start].strip():
            start += 1
        while end > start and not lines[end - 1].strip():
            end -= 1
        return "\n".join(lines[start:end])


def _malformed(
    node: _Node, line: int, message: str, v: list[DocSpecsViolation]
) -> None:
    v.append(
        DocSpecsViolation(
            rule=DocSpecsViolationRule.MALFORMED_BLOCK,
            section_id=node.id,
            line=line,
            message=message,
        )
    )


def _add_item(
    list_: _Node,
    item_type: DocSpecsSectionType,
    child_type: Optional[DocSpecsSectionType],
    id: str,
    line: int,
) -> _Node:
    """A virtual item of *item_type* with *id* at *line*, added to *list_*;
    returns the section its form values go to — the item itself, or its
    virtual child of *child_type* (id: the child type's name upper-cased)."""
    item = _Node(id, line, [], item_type)
    list_.children.append(item)
    if child_type is None:
        return item
    child = _Node(child_type.name.upper(), line, [], child_type)
    item.children.append(child)
    return child


def _read_table(
    lines: list[str],
    start: int,
    first_line: int,
    section_id: Optional[str],
    v: list[DocSpecsViolation],
) -> _Table:
    """Reads the table whose header is ``lines[start]``: the header cells,
    the body rows with their line indexes, and the index after the table;
    *first_line* is the 1-based document line of ``lines[0]``. A missing or
    mismatched delimiter row is a ``malformedBlock`` at the header and the
    table yields no rows; a row of another cell count is a ``malformedBlock``
    at that row and is left out."""
    end = start + 1
    while end < len(lines) and _TABLE_LINE.match(lines[end]):
        end += 1
    header = _row_cells(lines[start])
    delimiter = _row_cells(lines[start + 1]) if start + 1 < end else None
    delimiter_ok = delimiter is not None and all(
        _DELIMITER_CELL.fullmatch(c) for c in delimiter
    )
    table = _Table(header, end)
    if not delimiter_ok or delimiter is None or len(delimiter) != len(header):
        v.append(
            DocSpecsViolation(
                rule=DocSpecsViolationRule.MALFORMED_BLOCK,
                section_id=section_id,
                line=first_line + start,
                message=(
                    "table whose delimiter row does not match its header"
                    if delimiter_ok
                    else "table without its delimiter row"
                ),
            )
        )
        return table
    for i in range(start + 2, end):
        cells = _row_cells(lines[i])
        if len(cells) != len(header):
            v.append(
                DocSpecsViolation(
                    rule=DocSpecsViolationRule.MALFORMED_BLOCK,
                    section_id=section_id,
                    line=first_line + i,
                    message=(
                        f"table row with {len(cells)} cells, the header has "
                        f"{len(header)}"
                    ),
                )
            )
            continue
        table.rows.append(_TableRow(i, cells))
    return table


def _skip_blank(lines: list[str], i: int) -> int:
    while i < len(lines) and not lines[i].strip():
        i += 1
    return i


def _generated_lead(lines: list[str]) -> int:
    """The number of leading lines of a section's *lines* that the rendition
    writes from the document and that hold no value: a paragraph that is one
    ``linked`` span (SOM §11.11), then a ``derived`` block (SOM §11.12), with
    the blank lines around them (DocSpecs RN-5, Not text)."""
    i = _skip_blank(lines, 0)
    end = i
    while end < len(lines) and lines[end].strip():
        end += 1
    para = " ".join(lines[i:end]).strip()
    if end > i and _LINKED_PARAGRAPH.fullmatch(para):
        i = _skip_blank(lines, end)
    open_ = _DERIVED_OPEN.match(lines[i]) if i < len(lines) else None
    if open_ is not None:
        close = re.compile(r"^ {0,3}:{%d,}[ \t]*$" % len(open_.group(1)))
        k = i + 1
        while k < len(lines) and not close.fullmatch(lines[k]):
            k += 1
        if k < len(lines):
            i = _skip_blank(lines, k + 1)
    return i


def _without_generated_text(text: str) -> str:
    """*text* without its :func:`_generated_lead`: what the text rules
    read."""
    lines = text.split("\n")
    return "\n".join(lines[_generated_lead(lines) :]).strip()


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


def _cell_value(cell: str) -> str:
    """A value cell's value: ``\\|`` unescaped, a cell of links read as their
    texts."""
    text = cell.replace("\\|", "|")
    if not _LINK_CELL.fullmatch(text):
        return text
    return ", ".join(m.group(1) for m in _LINK_TEXT.finditer(text))


def _cell_id(cell: str) -> str:
    """An ``Id`` or ``Section`` cell with its own anchors
    (``<a id="X"></a>X``) removed (Section Anchors): in a ``<LIST> / <ITEM>``
    cell each part's anchor, and one before the whole cell naming its item.
    Any other anchor stays. An id written as a link is read as its text (SOM
    §11.5)."""
    text = _CELL_LINK.sub(lambda m: m.group(1), cell)
    out: list[str] = []
    pos = 0
    for m in _CELL_ANCHOR.finditer(text):
        out.append(text[pos : m.start()])
        rest = _CELL_PART_SEPARATOR.split(text[m.end() :])
        own = _is_own_anchor(m.group(1), rest[0].strip()) or (
            m.start() == 0 and _is_own_anchor(m.group(1), rest[-1].strip())
        )
        if not own:
            out.append(m.group(0))
        pos = m.end()
    out.append(text[pos:])
    return "".join(out)




# ---------------------------------------------------------------------------
# 4. Binding onto the SOM metadata tree (SOM §14 capability 3)
# ---------------------------------------------------------------------------


def bind_docspecs_markdown(
    model: SpecModel, document: SpecDocument, text: str
) -> SpecMarkdownResult:
    """Binds a DocSpecs markdown *text* onto the SOM metadata tree of
    *model*, staging values against *document*'s path grammar — the SOM §11.7
    entry point, delegated to :meth:`SpecDocumentMarkdown.parse`."""
    return SpecDocumentMarkdown(model, document).parse(text)
