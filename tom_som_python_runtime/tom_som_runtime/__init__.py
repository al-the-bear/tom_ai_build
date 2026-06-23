"""``tom_som_runtime`` — the Python port of the generic TomSpecs object-model
runtime (`tom_som_dart_runtime`).

This is the value-free, generated-code-free half of the multi-platform spec
model: a meta-data loader (:class:`SpecModel`), a reflection/resolution surface
(:class:`SpecReflection`), a sparse in-memory document (:class:`SpecDocument`),
a validator, and the YAML/Markdown codecs. It is validated against the shared
language-agnostic conformance corpus in ``tom_som_conformance/corpus``.
"""

from __future__ import annotations

from .som_facade import (
    SomList,
    SomNode,
    SomScalar,
    SomVersionError,
    check_som_model_version,
)
from .spec_document import SpecDocument
from .spec_document_markdown import (
    SpecDocumentMarkdown,
    SpecMarkdownRejectReason,
    SpecMarkdownRejection,
    SpecMarkdownResult,
)
from .spec_document_yaml import (
    FORMAT_VERSION,
    SpecYamlContents,
    decode as yaml_decode,
    encode as yaml_encode,
)
from .spec_model import (
    FormFieldSpec,
    SpecAnnotation,
    SpecClass,
    SpecField,
    SpecFieldKind,
    SpecModel,
    SpecRoot,
)
from .spec_paths import (
    SPEC_PATH_SEPARATOR,
    ListItemSegment,
    list_item_path,
    spec_path_join,
    spec_path_segments,
    split_list_item_segment,
)
from .spec_reflection import (
    SpecNodeKind,
    SpecReflection,
    SpecResolution,
)
from .spec_validator import (
    SpecValidationCode,
    SpecValidationError,
    validate_document,
)

__all__ = [
    "FORMAT_VERSION",
    "FormFieldSpec",
    "ListItemSegment",
    "SPEC_PATH_SEPARATOR",
    "SomList",
    "SomNode",
    "SomScalar",
    "SomVersionError",
    "SpecAnnotation",
    "SpecClass",
    "SpecDocument",
    "SpecDocumentMarkdown",
    "SpecField",
    "SpecFieldKind",
    "SpecMarkdownRejectReason",
    "SpecMarkdownRejection",
    "SpecMarkdownResult",
    "SpecModel",
    "SpecNodeKind",
    "SpecReflection",
    "SpecResolution",
    "SpecRoot",
    "SpecValidationCode",
    "SpecValidationError",
    "SpecYamlContents",
    "check_som_model_version",
    "list_item_path",
    "spec_path_join",
    "spec_path_segments",
    "split_list_item_segment",
    "validate_document",
    "yaml_decode",
    "yaml_encode",
]
