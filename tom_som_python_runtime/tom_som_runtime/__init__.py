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
    K_SECTION_ID_SLOT,
    SpecSectionIdCollision,
    effective_list_item_section_id,
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
    DEFAULT_MAX_SNAPSHOT_AGE,
    FormFieldSpec,
    SpecAnnotation,
    SpecClass,
    SpecField,
    SpecFieldKind,
    SpecModel,
    SpecModelStampCheck,
    SpecRoot,
    parse_stamp_timestamp,
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
from .spec_editor import SpecEditor
from .spec_node_creation import (
    SpecCreationCode,
    SpecCreationError,
    SpecNodeCreator,
    check_add_node,
)
from .spec_query import (
    SpecNodeProjection,
    SpecQuery,
    SpecQueryCursor,
    SpecQueryEngine,
    SpecQueryMatch,
    SpecStateFilter,
)
from .spec_text_pattern import (
    SomPatternError,
    SomTextPattern,
    SpecMatchSpan,
)
from .spec_typed_values import (
    som_format_bool,
    som_format_double,
    som_format_enum_name,
    som_format_int,
    som_format_num,
    som_parse_bool,
    som_parse_double,
    som_parse_enum_name,
    som_parse_int,
    som_parse_num,
)
from .spec_validator import (
    SpecValidationCode,
    SpecValidationError,
    validate_document,
)

__all__ = [
    "DEFAULT_MAX_SNAPSHOT_AGE",
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
    "K_SECTION_ID_SLOT",
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
    "SomPatternError",
    "SomScalar",
    "SomTextPattern",
    "SomVersionError",
    "SpecAnnotation",
    "SpecClass",
    "SpecCreationCode",
    "SpecCreationError",
    "SpecDocument",
    "SpecDocumentMarkdown",
    "SpecEditor",
    "SpecField",
    "SpecFieldKind",
    "SpecMarkdownRejectReason",
    "SpecMarkdownRejection",
    "SpecMarkdownResult",
    "SpecMatchSpan",
    "SpecModel",
    "SpecModelStampCheck",
    "SpecNodeCreator",
    "SpecNodeKind",
    "SpecNodeProjection",
    "SpecQuery",
    "SpecQueryCursor",
    "SpecQueryEngine",
    "SpecQueryMatch",
    "SpecReflection",
    "SpecResolution",
    "SpecRoot",
    "SpecSectionIdCollision",
    "SpecSerializationOrder",
    "SpecStateFilter",
    "SpecValidationCode",
    "SpecValidationError",
    "SpecYamlContents",
    "SpecYamlFormatException",
    "bind_docspecs_markdown",
    "build_som_meta_tree",
    "som_meta_node_diff",
    "check_add_node",
    "check_som_model_version",
    "doc_specs_id_transform",
    "effective_list_item_section_id",
    "encode_two_letter_date",
    "generate_list_item_section_id",
    "list_item_path",
    "parse_stamp_timestamp",
    "section_id_pattern_prefix",
    "som_editability_for",
    "som_format_bool",
    "som_format_double",
    "som_format_enum_name",
    "som_format_int",
    "som_format_num",
    "som_parse_bool",
    "som_parse_double",
    "som_parse_enum_name",
    "som_parse_int",
    "som_parse_num",
    "spec_parent_path",
    "spec_path_join",
    "spec_path_segments",
    "split_list_item_segment",
    "validate_document",
    "yaml_decode",
    "yaml_encode",
]
