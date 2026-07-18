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
    SomEditability,
    SomList,
    SomNode,
    SomScalar,
    SomVersionError,
    check_som_model_version,
    som_editability_for,
)
from .docspecs_validator import (
    DocSpecsDocument,
    DocSpecsDocumentSection,
    DocSpecsFormField,
    DocSpecsFormType,
    DocSpecsPatternCheck,
    DocSpecsSchema,
    DocSpecsSection,
    DocSpecsSectionType,
    DocSpecsSubsectionRule,
    DocSpecsValidator,
    DocSpecsViolation,
    DocSpecsViolationRule,
    bind_docspecs_markdown,
    doc_specs_id_transform,
)
from .spec_document import SpecDocument
from .spec_section_id import (
    SpecSectionIdCollision,
    encode_two_letter_date,
    generate_list_item_section_id,
    section_id_pattern_prefix,
)
from .spec_serialization_order import SpecSerializationOrder
from .spec_document_markdown import (
    MarkdownFenceTracker,
    SpecDocumentMarkdown,
    SpecMarkdownRejectReason,
    SpecMarkdownRejection,
    SpecMarkdownResult,
)
from .spec_document_yaml import (
    FORMAT_VERSION,
    SpecYamlContents,
    SpecYamlFormatException,
    decode as yaml_decode,
    encode as yaml_encode,
)
from .spec_meta import (
    SomContentTypeMeta,
    SomDocMeta,
    SomFormFieldMeta,
    SomFormMeta,
    SomListMetaRef,
    SomMetaExtra,
    SomMetaKind,
    SomMetaNode,
    SomMetaRef,
    SomMetaTree,
)
from .spec_meta_bridge import build_som_meta_tree
from .spec_meta_diff import som_meta_node_diff
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
    spec_parent_path,
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
    "DocSpecsDocument",
    "DocSpecsDocumentSection",
    "DocSpecsFormField",
    "DocSpecsFormType",
    "DocSpecsPatternCheck",
    "DocSpecsSchema",
    "DocSpecsSection",
    "DocSpecsSectionType",
    "DocSpecsSubsectionRule",
    "DocSpecsValidator",
    "DocSpecsViolation",
    "DocSpecsViolationRule",
    "FORMAT_VERSION",
    "FormFieldSpec",
    "ListItemSegment",
    "MarkdownFenceTracker",
    "SPEC_PATH_SEPARATOR",
    "SomContentTypeMeta",
    "SomDocMeta",
    "SomEditability",
    "SomFormFieldMeta",
    "SomFormMeta",
    "SomList",
    "SomListMetaRef",
    "SomMetaExtra",
    "SomMetaKind",
    "SomMetaNode",
    "SomMetaRef",
    "SomMetaTree",
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
    "SpecSectionIdCollision",
    "SpecSerializationOrder",
    "SpecValidationCode",
    "SpecValidationError",
    "SpecYamlContents",
    "SpecYamlFormatException",
    "bind_docspecs_markdown",
    "build_som_meta_tree",
    "som_meta_node_diff",
    "check_som_model_version",
    "doc_specs_id_transform",
    "encode_two_letter_date",
    "generate_list_item_section_id",
    "list_item_path",
    "section_id_pattern_prefix",
    "som_editability_for",
    "spec_parent_path",
    "spec_path_join",
    "spec_path_segments",
    "split_list_item_segment",
    "validate_document",
    "yaml_decode",
    "yaml_encode",
]
