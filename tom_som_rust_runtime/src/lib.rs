//! `tom_som_rust_runtime` — the Rust port of the generic TomSpecs object-model
//! runtime (`tom_som_dart_runtime`).
//!
//! It is the value-free, generated-code-free half of the multi-platform spec
//! model: a meta-data loader ([`SpecModel`]), a reflection/resolution surface
//! ([`SpecReflection`]), a sparse in-memory document ([`SpecDocument`]), a
//! validator, and the YAML/Markdown codecs. It has **zero external
//! dependencies** (Rust standard library only) and is validated against the
//! shared language-agnostic conformance corpus in `tom_som_conformance/corpus`.
//!
//! JSON parsing uses a hand-rolled, dependency-free parser ([`json`]); YAML uses
//! a hand-rolled reader ([`yaml`]). Byte-stable `*.docspecs.yaml` output requires
//! a custom [`spec_document_yaml::js_json_string`] that matches JavaScript's
//! `JSON.stringify` exactly — so output is identical across every language port.

pub mod docspecs_validator;
pub mod json;
pub mod som_facade;
pub mod spec_codespecs_extract;
pub mod spec_document;
pub mod spec_document_markdown;
pub mod spec_document_yaml;
pub mod spec_editor;
pub mod spec_meta;
pub mod spec_meta_bridge;
pub mod spec_meta_diff;
pub mod spec_model;
pub mod spec_node_creation;
pub mod spec_paths;
pub mod spec_query;
pub mod spec_reflection;
pub mod spec_section_id;
pub mod spec_serialization_order;
pub mod spec_text_pattern;
pub mod spec_typed_values;
pub mod spec_validator;
pub mod yaml;

// Flat re-exports so consumers (and the generated `tom_som_rust_v0`) can `use
// tom_som_rust_runtime::SpecDocument;` without naming the module — the Rust
// analogue of the Go package's flat surface.
pub use docspecs_validator::{
    bind_docspecs_markdown, docspecs_id_transform, parse_docspecs_document, DocSpecsDocument,
    DocSpecsDocumentSection, DocSpecsFormField, DocSpecsFormType, DocSpecsPatternCheck,
    DocSpecsSchema, DocSpecsSection, DocSpecsSectionType, DocSpecsSubsectionRule,
    DocSpecsValidator, DocSpecsViolation, DOCSPECS_ALL_RULES,
    DOCSPECS_RULE_FIELD_PATTERN_MISMATCH,
    DOCSPECS_RULE_FORMAT_MISMATCH, DOCSPECS_RULE_ID_PATTERN_MISMATCH,
    DOCSPECS_RULE_MALFORMED_HEADING, DOCSPECS_RULE_MISSING_REQUIRED_FIELD,
    DOCSPECS_RULE_MISSING_REQUIRED_SECTION, DOCSPECS_RULE_TEXT_LENGTH_OUT,
    DOCSPECS_RULE_TEXT_REQUIRED, DOCSPECS_RULE_TOO_FEW_ITEMS, DOCSPECS_RULE_TOO_MANY_ITEMS,
    DOCSPECS_RULE_UNKNOWN_SECTION,
};
pub use json::Json;
pub use som_facade::{
    check_som_model_version, doc_ref, som_editability_for, DocRef, SomEditability, SomList,
    SomNode, SomScalar, SomVersionError,
};
pub use spec_codespecs_extract::{
    CodeSpecsArea, CodeSpecsAreaCatalog, CodeSpecsExtract, CodeSpecsExtractEntry,
    CodeSpecsExtractError, CodeSpecsExtractor, CodeSpecsRouting, CodeSpecsRoutingVerdict,
    CodeSpecsSlice, CODE_SPECS_EXTRACT_FORMAT, CODE_SPEC_KIND_ANNOTATION,
    FOLLOW_UP_KIND_ANNOTATION, NO_ARTIFACT_ANNOTATION,
};
pub use spec_document::{DocumentJson, ListJson, SpecDocument};
pub use spec_document_markdown::{
    spec_markdown_form_label, spec_markdown_item_title_stem, spec_markdown_kebab_case,
    spec_markdown_title_case, MarkdownFenceTracker, SpecDocumentMarkdown, SpecMarkdownRejection,
    SpecMarkdownResult, SPEC_MARKDOWN_REJECT_KIND_MISMATCH, SPEC_MARKDOWN_REJECT_MALFORMED_HEADING,
    SPEC_MARKDOWN_REJECT_MISSING_VALUE, SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT,
    SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION,
};
pub use spec_document_yaml::{
    decode_yaml, dedup_empty_lines, encode_yaml, js_json_string, node_key, plain_key,
    SpecYamlContents, SpecYamlError, SpecYamlFormatException, FORMAT_VERSION,
};
pub use spec_editor::{SomValue, SpecEditor};
pub use spec_meta::{
    SomContentTypeMeta, SomDocMeta, SomFormFieldMeta, SomFormMeta, SomListMetaRef, SomMetaExtra,
    SomMetaNode, SomMetaRef, SomMetaTree, SOM_META_KIND_COMPLEX,
    SOM_META_KIND_CONTENT, SOM_META_KIND_ENUM_VALUE, SOM_META_KIND_FORM, SOM_META_KIND_LIST,
    SOM_META_KIND_SCALAR, SOM_META_KIND_SECTION,
};
pub use spec_meta_bridge::build_som_meta_tree;
pub use spec_meta_diff::som_meta_node_diff;
pub use spec_model::{
    annotation_named, code_spec_kind, follow_up_kind, no_artifact, parse_field_kind,
    parse_stamp_timestamp, som_model_version_string, strip_enum_prefix, FormFieldSpec, KindLink,
    NoArtifactLink, SpecAnnotation, SpecClass, SpecField, SpecModel, SpecModelStampCheck, SpecRoot,
    DEFAULT_MAX_SNAPSHOT_AGE_SECONDS, SECONDS_PER_DAY,
};
pub use spec_node_creation::{
    check_add_node, SpecCreationCode, SpecCreationError, SpecNodeCreator,
};
pub use spec_paths::{
    list_item_path, spec_parent_path, spec_path_join, spec_path_segments, split_list_item_segment,
    ListItemSegment,
};
pub use spec_query::{
    glob_matches, SpecNodeProjection, SpecQuery, SpecQueryCursor, SpecQueryEngine, SpecQueryMatch,
    SpecStateFilter,
};
pub use spec_reflection::{SpecReflection, SpecResolution};
pub use spec_section_id::{
    encode_two_letter_date, generate_list_item_section_id, is_collision, section_id_pattern_prefix,
    today_month_day, SpecSectionIdCollision, SpecSectionIdError,
};
pub use spec_serialization_order::{SpecSerializationOrder, SERIALIZATION_UNORDERED_FALLBACK};
pub use spec_text_pattern::{SomPatternError, SomTextPattern, SpecMatchSpan};
pub use spec_typed_values::{
    som_format_bool, som_format_double, som_format_enum_name, som_format_int, som_format_num,
    som_parse_bool, som_parse_double, som_parse_enum_name, som_parse_int, som_parse_num, SomNum,
};
pub use spec_validator::{validate_document, SpecValidationError};
