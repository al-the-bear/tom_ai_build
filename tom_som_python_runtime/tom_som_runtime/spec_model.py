"""In-memory representation of the exported TomSpecs class graph (the
spec-model meta-data file) — a faithful port of
`tom_som_dart_runtime/lib/src/spec_model.dart`.

The model is a *class graph*, not an expanded tree: each class appears once and
field ``elementType`` / ``type`` references are followed on demand by a
traversal. This is the "reflection" surface — it describes any document's
structure, independent of the values a concrete document holds.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Optional


class SpecFieldKind(Enum):
    """The render kind of a field, mirroring the exporter's classification."""

    LIST = "list"
    FORM = "form"
    SECTION = "section"
    CONTENT = "content"
    ENUM = "enum"
    COMPLEX = "complex"
    SCALAR = "scalar"

    @staticmethod
    def parse(raw: str) -> "SpecFieldKind":
        for kind in SpecFieldKind:
            if kind.value == raw:
                return kind
        return SpecFieldKind.SCALAR


@dataclass(frozen=True)
class SpecAnnotation:
    """A single annotation captured losslessly from the model source (spec
    §3.1): its name and the resolved argument map."""

    name: str
    arguments: dict[str, Any] = field(default_factory=dict)

    def argument(self, key: str) -> Any:
        return self.arguments.get(key)

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecAnnotation":
        return SpecAnnotation(
            name=j["name"],
            arguments=dict(j.get("arguments") or {}),
        )

    @staticmethod
    def list_from_json(raw: Any) -> list["SpecAnnotation"]:
        if not isinstance(raw, list):
            return []
        return [SpecAnnotation.from_json(e) for e in raw]


@dataclass(frozen=True)
class FormFieldSpec:
    """A single form field within a ``@Form`` content section."""

    name: str
    label: str
    type: str = "String"
    hint: Optional[str] = None
    required: bool = False

    @staticmethod
    def from_json(j: dict[str, Any]) -> "FormFieldSpec":
        return FormFieldSpec(
            name=j["name"],
            label=j.get("label") or j["name"],
            type=j.get("type") or "String",
            hint=j.get("hint"),
            required=bool(j.get("required") or False),
        )


@dataclass(frozen=True)
class SpecField:
    """A single field of a :class:`SpecClass`."""

    name: str
    kind: SpecFieldKind
    doc: Optional[str] = None
    help: Optional[str] = None
    section_id: Optional[str] = None
    section_id_pattern: Optional[str] = None
    element_type: Optional[str] = None
    element_is_complex: bool = False
    min: Optional[int] = None
    content_type: Optional[str] = None
    section_type: Optional[str] = None
    enum_type: Optional[str] = None
    enum_values: list[str] = field(default_factory=list)
    type: Optional[str] = None
    serialization_order: Optional[int] = None
    form_fields: list[FormFieldSpec] = field(default_factory=list)
    annotations: list[SpecAnnotation] = field(default_factory=list)

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecField":
        raw_order = j.get("serializationOrder")
        return SpecField(
            name=j["name"],
            kind=SpecFieldKind.parse(j["kind"]),
            doc=j.get("doc"),
            help=j.get("help"),
            section_id=j.get("sectionId"),
            section_id_pattern=j.get("sectionIdPattern"),
            element_type=j.get("elementType"),
            element_is_complex=bool(j.get("elementIsComplex") or False),
            min=j.get("min"),
            content_type=j.get("contentType"),
            section_type=j.get("sectionType"),
            enum_type=j.get("enumType"),
            enum_values=[str(e) for e in (j.get("enumValues") or [])],
            type=j.get("type"),
            serialization_order=int(raw_order) if raw_order is not None else None,
            form_fields=[
                FormFieldSpec.from_json(e) for e in (j.get("formFields") or [])
            ],
            annotations=SpecAnnotation.list_from_json(j.get("annotations")),
        )

    @property
    def is_expandable(self) -> bool:
        """Whether expanding this field reveals further tree nodes."""
        return self.kind in (SpecFieldKind.LIST, SpecFieldKind.COMPLEX)

    def annotation(self, name: str) -> Optional[SpecAnnotation]:
        for a in self.annotations:
            if a.name == name:
                return a
        return None


@dataclass(frozen=True)
class SpecClass:
    """A model class with its fields."""

    name: str
    section_id: Optional[str] = None
    doc: Optional[str] = None
    help: Optional[str] = None
    maps_to: Optional[str] = None
    detailed_in: Optional[str] = None
    fields: list[SpecField] = field(default_factory=list)
    annotations: list[SpecAnnotation] = field(default_factory=list)

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecClass":
        return SpecClass(
            name=j["name"],
            section_id=j.get("sectionId"),
            doc=j.get("doc"),
            help=j.get("help"),
            maps_to=j.get("mapsTo"),
            detailed_in=j.get("detailedIn"),
            fields=[SpecField.from_json(e) for e in j["fields"]],
            annotations=SpecAnnotation.list_from_json(j.get("annotations")),
        )

    def field_named(self, name: str) -> Optional[SpecField]:
        for f in self.fields:
            if f.name == name:
                return f
        return None

    def annotation(self, name: str) -> Optional[SpecAnnotation]:
        for a in self.annotations:
            if a.name == name:
                return a
        return None


@dataclass(frozen=True)
class SpecRoot:
    """A document root (a class carrying ``@Document``)."""

    type: str
    title: str
    section_id: Optional[str] = None
    description: Optional[str] = None
    doc: Optional[str] = None

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecRoot":
        return SpecRoot(
            type=j["type"],
            title=j["title"],
            section_id=j.get("sectionId"),
            description=j.get("description"),
            doc=j.get("doc"),
        )


@dataclass(frozen=True)
class SpecModel:
    """The complete exported model."""

    roots: list[SpecRoot]
    classes: dict[str, SpecClass]
    model_version: int = 0
    model_version_label: Optional[str] = None

    def class_named(self, name: Optional[str]) -> Optional[SpecClass]:
        if name is None:
            return None
        return self.classes.get(name)

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecModel":
        classes = {
            name: SpecClass.from_json(value)
            for name, value in j["classes"].items()
        }
        roots = [SpecRoot.from_json(e) for e in j["roots"]]
        label = j.get("modelVersionLabel")
        return SpecModel(
            roots=roots,
            classes=classes,
            model_version=int(j.get("modelVersion") or 0),
            model_version_label=label if label else None,
        )
