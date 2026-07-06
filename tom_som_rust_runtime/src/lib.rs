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

pub mod json;
pub mod som_facade;
pub mod spec_document;
pub mod spec_document_markdown;
pub mod spec_document_yaml;
pub mod spec_model;
pub mod spec_paths;
pub mod spec_reflection;
pub mod spec_section_id;
pub mod spec_serialization_order;
pub mod spec_validator;
pub mod yaml;

// Flat re-exports so consumers (and the generated `tom_som_rust_v0`) can `use
// tom_som_rust_runtime::SpecDocument;` without naming the module — the Rust
// analogue of the Go package's flat surface.
pub use json::Json;
pub use som_facade::{
    check_som_model_version, doc_ref, DocRef, SomList, SomNode, SomScalar, SomVersionError,
};
pub use spec_document::{DocumentJson, ListJson, SpecDocument};
pub use spec_document_markdown::{
    SpecDocumentMarkdown, SpecMarkdownRejection, SpecMarkdownResult,
};
pub use spec_document_yaml::{
    decode_yaml, encode_yaml, encode_yaml_ordered, js_json_string, SpecYamlContents, FORMAT_VERSION,
};
pub use spec_model::{
    parse_field_kind, FormFieldSpec, SpecAnnotation, SpecClass, SpecField, SpecModel, SpecRoot,
};
pub use spec_paths::{
    list_item_path, spec_path_join, spec_path_segments, split_list_item_segment, ListItemSegment,
};
pub use spec_reflection::{SpecReflection, SpecResolution};
pub use spec_section_id::{
    encode_two_letter_date, generate_list_item_section_id, is_collision, section_id_pattern_prefix,
    today_month_day, SpecSectionIdCollision, SpecSectionIdError,
};
pub use spec_serialization_order::{SpecSerializationOrder, SERIALIZATION_UNORDERED_FALLBACK};
pub use spec_validator::{validate_document, SpecValidationError};
