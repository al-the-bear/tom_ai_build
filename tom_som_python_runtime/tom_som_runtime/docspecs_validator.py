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
from typing import Any, Optional

import yaml

from .spec_document import SpecDocument
from .spec_document_markdown import (
    MarkdownFenceTracker,
    SpecDocumentMarkdown,
    SpecMarkdownResult,
)
from .spec_model import SpecModel


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


class DocSpecsDocument:
    """A schema-free DocSpecs markdown parse: the declared schema header (if
    any), the top-level sections, and the parse-time violations (malformed
    headings). Validation against a schema is a separate step —
    :meth:`DocSpecsValidator.validate` — which folds these violations into
    its result."""

    _DOCSPEC_HEADER = re.compile(r"^<!--\s*docspec:\s*(\S+)\s*-->\s*$")

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
                if h is not None:
                    level = len(h.group(1))
                    rest = h.group(2).strip()
                    c = SpecDocumentMarkdown.headline_comment.match(rest)
                    section = DocSpecsSection(
                        id=c.group(1) if c is not None else None,
                        # group(2) is the optional key=value region (§9.2
                        # codeSpec); the title is group(3). For a bare heading
                        # with no comment, the whole rest is the title.
                        title=c.group(3).strip() if c is not None else rest,
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
    """One ``document: sections:`` slot: the backing section-type and whether
    the slot is optional."""

    def __init__(self, *, section_type: str, optional: bool) -> None:
        self.section_type = section_type
        self.optional = optional


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
                    if isinstance(v, dict):
                        st = v.get("section-type")
                        section_type = str(st if st is not None else s_key)
                        optional = v.get("optional") is True
                    else:
                        section_type = str(s_key)
                        optional = False
                    schema.document_sections[str(s_key)] = (
                        DocSpecsDocumentSection(
                            section_type=section_type, optional=optional
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
    fail-fast); a document is valid iff it is empty."""

    _FIELD_LABEL = re.compile(r"^([A-Za-z][A-Za-z0-9_]*): ?(.*)$")

    def __init__(self, schema: DocSpecsSchema) -> None:
        self.schema = schema

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
        self._validate_document_sections(root, v)
        return v

    def _validate_document_sections(
        self, root: DocSpecsSection, v: list[DocSpecsViolation]
    ) -> None:
        """Root children must occupy ``document: sections:`` slots; required
        slots must be present."""
        counts: dict[str, int] = {}
        for child in root.children:
            type_ = self._resolve_child(child, v)
            if type_ is None:
                continue
            if not any(
                s.section_type == type_.name
                for s in self.schema.document_sections.values()
            ):
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

    def _resolve_child(
        self, child: DocSpecsSection, v: list[DocSpecsViolation]
    ) -> Optional[DocSpecsSectionType]:
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
        section: DocSpecsSection,
        type_: DocSpecsSectionType,
        v: list[DocSpecsViolation],
    ) -> None:
        id = section.id
        assert id is not None
        pc = type_.pattern_check_id
        if pc is not None and not pc.matches(id):
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
        section: DocSpecsSection,
        type_: DocSpecsSectionType,
        v: list[DocSpecsViolation],
    ) -> None:
        # Form-formatted sections carry field lines, not free text.
        if type_.format is not None and type_.format in self.schema.form_types:
            return
        text = section.text
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
        section: DocSpecsSection,
        type_: DocSpecsSectionType,
        v: list[DocSpecsViolation],
    ) -> None:
        format_ = type_.format
        if format_ is None:
            return
        form = self.schema.form_types.get(format_)
        if form is not None:
            self._validate_form(section, form, v)
            return
        # A non-form format (`code`, `mermaid`, …) demands a fenced block.
        fence = MarkdownFenceTracker()
        saw_fence = False
        for line in section.body_lines:
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
        section: DocSpecsSection,
        form: DocSpecsFormType,
        v: list[DocSpecsViolation],
    ) -> None:
        """Parses the section body in the DocSpecs plain-text form format
        (``FieldName: value``, case-insensitive labels, continuation lines)
        and checks required fields + field pattern-checks. Text before the
        first recognised label is tolerated here (the binding parse reports
        it)."""
        by_lower = {f.name.lower(): f for f in form.fields}
        values: dict[str, str] = {}
        field_lines: dict[str, int] = {}
        fence = MarkdownFenceTracker()
        current: Optional[str] = None
        current_lines: list[str] = []

        def flush() -> None:
            nonlocal current_lines
            field = current
            if field is None:
                return
            text = "\n".join(current_lines).strip()
            if text:
                values[field] = text
            current_lines = []

        for i, line in enumerate(section.body_lines):
            if not fence.in_fence:
                m = DocSpecsValidator._FIELD_LABEL.match(line)
                field = (
                    by_lower.get(m.group(1).lower()) if m is not None else None
                )
                if field is not None:
                    flush()
                    current = field.name
                    field_lines[field.name] = section.body_start_line + i
                    assert m is not None
                    current_lines = [m.group(2)]
                    fence.feed(line)
                    continue
            if current is not None:
                current_lines.append(line)
            fence.feed(line)
        flush()

        for field in form.fields:
            value = values.get(field.name)
            if field.required and (value is None or not value):
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
            if value is not None and pc is not None and not pc.matches(value):
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
