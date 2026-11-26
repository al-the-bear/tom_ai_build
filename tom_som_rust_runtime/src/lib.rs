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
//! a hand-rolled reader ([`yaml`]). Byte-stable `*.tomspecs.yaml` output requires
//! a custom [`spec_document_yaml::js_json_string`] that matches JavaScript's
//! `JSON.stringify` exactly — so output is identical across every language port.

pub mod docspecs_validator;
pub mod json;
pub mod som_facade;
pub mod spec_answers;
pub mod spec_backfill;
pub mod spec_codespecs_extract;
pub mod spec_codespecs_gate;
pub mod spec_codespecs_records;
pub mod spec_derive_fields;
pub mod spec_document;
pub mod spec_document_assembly;
pub mod spec_document_markdown;
pub mod spec_document_merge;
pub mod spec_document_set;
pub mod spec_document_strip;
pub mod spec_document_yaml;
pub mod spec_editor;
pub mod spec_generation_units;
pub mod spec_impact_walk;
pub mod spec_links_validator;
pub mod spec_meta;
pub mod spec_meta_bridge;
pub mod spec_meta_diff;
pub mod spec_model;
pub mod spec_model_links;
pub mod spec_node_creation;
pub mod spec_notation;
pub mod spec_paths;
pub mod spec_place;
pub mod spec_prefill;
pub mod spec_query;
pub mod spec_reflection;
pub mod spec_review_annotations;
pub mod spec_review_merge;
pub mod spec_schema_validation;
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
    DOCSPECS_RULE_DUPLICATE_ID_PATH, DOCSPECS_RULE_FIELD_PATTERN_MISMATCH,
    DOCSPECS_RULE_FORMAT_MISMATCH, DOCSPECS_RULE_ID_PATTERN_MISMATCH,
    DOCSPECS_RULE_MALFORMED_HEADING, DOCSPECS_RULE_MISSING_REQUIRED_FIELD,
    DOCSPECS_RULE_MISSING_REQUIRED_SECTION, DOCSPECS_RULE_SECTION_OUT_OF_ORDER,
    DOCSPECS_RULE_TEXT_LENGTH_OUT, DOCSPECS_RULE_TEXT_REQUIRED, DOCSPECS_RULE_TOO_FEW_ITEMS,
    DOCSPECS_RULE_TOO_MANY_ITEMS, DOCSPECS_RULE_UNKNOWN_SECTION,
    DOCSPECS_RULE_ANNOTATION_INSIDE_DIV, DOCSPECS_RULE_DIV_INSIDE_ANNOTATION,
    DOCSPECS_RULE_DIV_WITHOUT_KIND, DOCSPECS_RULE_MARK_ACROSS_NOTATION,
    DOCSPECS_RULE_MALFORMED_BLOCK, DOCSPECS_RULE_REJECTED_BLOCK, DOCSPECS_RULE_STRAY_CLOSING_FENCE,
    DOCSPECS_RULE_UNCLOSED_DIV, DOCSPECS_RULE_UNKNOWN_FIELD,
    DOCSPECS_RULE_UNCLOSED_SPAN, DOCSPECS_RULE_UNKNOWN_KIND,
};
pub use json::Json;
pub use som_facade::{
    check_som_model_version, doc_ref, som_editability_for, DocRef, SomEditability, SomList,
    SomNode, SomScalar, SomVersionError,
};
pub use spec_answers::{
    extract_answers, render_answers, SpecAnswerCounts, SpecAnswerEntry, SpecAnswerExtract,
    SpecAnswerKind, SpecAnswerRenderOptions,
};
pub use spec_backfill::{
    backfill, spec_backfill_bump, SpecBackfillChange, SpecBackfillChangeKind, SpecBackfillError,
    SpecBackfillErrorCode, SpecBackfillLeft, SpecBackfillLeftReason, SpecBackfillOptions,
    SpecBackfillResult,
};
pub use spec_codespecs_extract::{
    code_specs_class_routing, code_specs_field_routing, code_specs_yaml_string,
    CodeSpecsArea, CodeSpecsAreaCatalog, CodeSpecsCarrier, CodeSpecsExtract,
    CodeSpecsExtractEntry, CodeSpecsExtractError, CodeSpecsExtractor, CodeSpecsFieldRef,
    CodeSpecsRequiredArgument, CodeSpecsRouting, CodeSpecsRoutingVerdict, CodeSpecsSlice,
    CodeSpecsStep, CODE_SPECS_EXTRACT_FORMAT, CODE_SPEC_KIND_ANNOTATION,
    FOLLOW_UP_KIND_ANNOTATION, NO_ARTIFACT_ANNOTATION,
};
pub use spec_codespecs_gate::{
    CodeSpecsGate, CodeSpecsGateCheck, CodeSpecsGateCheckResult, CodeSpecsGateFinding,
    CodeSpecsGateReport,
};
pub use spec_codespecs_records::{
    parse_code_specs_extract_yaml, CodeSpecsExcludedArea, CodeSpecsExtractSet, CodeSpecsGateEntry,
    CodeSpecsGateGap, CodeSpecsGateRecord, CodeSpecsGateVerdict, CodeSpecsRecordError,
    CODE_SPECS_EXTRACT_FILE_SUFFIX, CODE_SPECS_GATE_DESCOPED, CODE_SPECS_GATE_RECORD_FILE,
    CODE_SPECS_GATE_RECORD_FORMAT,
};
pub use spec_derive_fields::{
    derive_fields, derive_fields_dry_run, SpecDeriveChange, SpecDeriveChangeKind,
    SpecDeriveOptions, SpecDeriveResult,
};
pub use spec_document::{
    DocumentJson, ListJson, SpecDocument, SpecListItemMove, SpecListMoveError,
};
pub use spec_document_assembly::{
    assemble_spec_documents, SpecAssemblyOverlap, SpecDocumentAssembly,
};
pub use spec_document_markdown::{
    markdown_escapable_div, markdown_heading_div, markdown_heading_div_indent,
    markdown_heading_title, markdown_is_readable_comment, SpecMarkdownExportOptions,
    SPEC_MARKDOWN_APPENDIX_MARKER,
    spec_markdown_form_label, spec_markdown_item_title_stem, spec_markdown_kebab_case,
    spec_markdown_title_case, MarkdownFenceTracker, SpecDocumentMarkdown, SpecMarkdownRejection,
    SpecMarkdownResult, SPEC_MARKDOWN_REJECT_KIND_MISMATCH, SPEC_MARKDOWN_REJECT_MALFORMED_HEADING,
    SpecMarkdownImport, SpecMarkdownRendition, SPEC_MARKDOWN_REJECT_MISSING_VALUE, SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT,
    SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK, SPEC_MARKDOWN_REJECT_UNKNOWN_FIELD,
    SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION,
};
pub use spec_document_merge::{
    merge_stripped_value, spec_strip_merge_label, SpecStripMerge, SpecStripMergeConflict,
    SpecStripMergeOptions, SpecStripMergePlaced, SpecStripMergeRefusal, SpecStripMergeResult,
    SpecStripMergedValue, SpecStripBaseLoader, SpecStripValueMerge,
};
pub use spec_document_set::{
    rename_id, spec_set_is_pending, spec_set_reviewed, spec_set_same_typed, spec_set_strip_kind,
    spec_sync_counts_json, sync_report, SpecDocumentFindings, SpecDocumentSet,
    SpecDocumentSetError, SpecDocumentSetLoadError, SpecDocumentSetRefusal, SpecRenameChange,
    SpecRenameError, SpecSetCheck, SpecSetFound, SpecSetSide, SpecSetValue, SpecSyncCode,
    SpecSyncFinding, SpecSyncHolder, SpecSyncPair, SpecSyncPlace, SpecSyncReport,
    SpecSyncResolution,
};
pub use spec_document_strip::{
    spec_strip_kind_names, spec_strip_notation_kinds, strip_notation_text, SpecAppendixEntry,
    SpecDocumentStrip, SpecDocumentStripOptions, SpecReadableHeader, SpecReadableSource,
    SpecStripFinding, SpecStripKept, SpecStripOptions, SpecStripPiece, SpecStripResult,
    SpecStripTextResult, SpecStripUsageError, SpecStripValueRef, SpecStrippedValue,
    SPEC_STRIP_KIND_NAMES, SPEC_STRIP_NOTATION_KINDS,
};
pub use spec_document_yaml::{
    format_yaml_float, review_scalar, write_header, write_scalar, yaml_key,
    decode_yaml, dedup_empty_lines, encode_yaml, encode_yaml_with_review, is_plain_yaml_scalar, js_json_string,
    node_key, plain_key, rekey_review, stale_review_paths, write_review_pass, SpecYamlContents,
    SpecYamlError, SpecYamlFormatException, FORMAT_VERSION,
};
pub use spec_editor::{SomValue, SpecEditor};
pub use spec_generation_units::{
    spec_default_units, spec_generation_units, SpecGenerationUnit, SpecGenerationUnitMapping,
    SPEC_STANDARD_EMITTERS,
};
pub use spec_impact_walk::{
    spec_impact_document_files, spec_impact_level, spec_impact_walk, spec_impact_walk_markdown,
    SpecImpactFolder, SpecImpactLevel, SpecImpactLevelDocument, SpecImpactRootWalk, SpecImpactRow,
    SpecImpactRowKind,
};
pub use spec_meta::{
    SomContentTypeMeta, SomDocMeta, SomFormFieldMeta, SomFormMeta, SomListMetaRef, SomMetaExtra,
    SomMetaNode, SomMetaRef, SomMetaTree, SOM_META_KIND_COMPLEX,
    SOM_META_KIND_CONTENT, SOM_META_KIND_ENUM_VALUE, SOM_META_KIND_FORM, SOM_META_KIND_LIST,
    SOM_META_KIND_SCALAR, SOM_META_KIND_SECTION,
};
pub use spec_meta_bridge::build_som_meta_tree;
pub use spec_meta_diff::{som_meta_node_diff, som_meta_node_diff_at};
pub use spec_model::{
    SPEC_FIELD_KIND_COMPLEX, SPEC_FIELD_KIND_CONTENT, SPEC_FIELD_KIND_ENUM, SPEC_FIELD_KIND_FORM,
    SPEC_FIELD_KIND_LIST, SPEC_FIELD_KIND_SCALAR, SPEC_FIELD_KIND_SECTION,
    annotation_named, code_spec_kind, follow_up_kind, no_artifact, parse_field_kind,
    parse_stamp_timestamp, som_model_version_string, strip_enum_prefix, FormFieldSpec, KindLink,
    NoArtifactLink, SpecAnnotation, SpecClass, SpecField, SpecModel, SpecModelStampCheck, SpecRoot,
    DEFAULT_MAX_SNAPSHOT_AGE_SECONDS, SECONDS_PER_DAY,
};
pub use spec_node_creation::{
    check_add_node, SpecCreationCode, SpecCreationError, SpecNodeCreator,
};
pub use spec_notation::{
    notation_severity, registered_notation_kinds, scan_notation, NotationElement,
    NotationFinding, NotationFindingCode, NotationScan, REGISTERED_NOTATION_KINDS,
};
pub use spec_paths::{
    SPEC_PATH_SEPARATOR,
    list_item_path, spec_parent_path, spec_path_join, spec_path_segments, split_list_item_segment,
    ListItemSegment,
};
pub use spec_query::{
    glob_matches, SpecNodeProjection, SpecQuery, SpecQueryCursor, SpecQueryEngine, SpecQueryMatch,
    SpecStateFilter,
};
pub use spec_reflection::{
    SpecReflection, SpecResolution, SPEC_NODE_KIND_COMPLEX, SPEC_NODE_KIND_CONTENT,
    SPEC_NODE_KIND_ENUM_VALUE, SPEC_NODE_KIND_FORM, SPEC_NODE_KIND_LIST,
    SPEC_NODE_KIND_LIST_ITEM_COMPLEX, SPEC_NODE_KIND_LIST_ITEM_SCALAR, SPEC_NODE_KIND_ROOT,
    SPEC_NODE_KIND_SCALAR, SPEC_NODE_KIND_SECTION,
};
pub use spec_links_validator::{
    spec_expand_pattern, spec_link_field_of, spec_link_ids, spec_resolve_link_place,
    spec_resolve_place_at, validate_links, SpecLinkFix, SpecLinkValidator, SpecSubtreeValue,
    SPEC_LINK_FIX_ADD_ROW, SPEC_LINK_FIX_APPEND, SPEC_LINK_FIX_COPY, SPEC_LINK_FIX_LIST,
    SPEC_LINK_FIX_REMOVE_ROW, SPEC_LINK_FIX_SET,
};
pub use spec_model_links::{
    annotations_named, spec_string_pair_value, SpecDerivation, SpecExtractsLinks, SpecInverseOf,
    SpecListRelation, SpecSameAs, SpecStringPair, SpecSummaryOf, SpecSync,
};
pub use spec_place::{
    spec_same_as_bindings, spec_section_positions, SpecPlace, SpecPlaceError, SpecPlaceFilter,
    SpecPlaceResolution, SpecSameAsBinding, SpecSectionPosition, SPEC_PLACE_KIND_CONTENT,
    SPEC_PLACE_KIND_FORM, SPEC_PLACE_KIND_FORM_FIELD, SPEC_PLACE_KIND_HEADLINE,
    SPEC_PLACE_KIND_LIST, SPEC_PLACE_KIND_SECTION, SPEC_PLACE_KIND_SECTION_ID,
    SPEC_PLACE_PROBLEM_AMBIGUOUS, SPEC_PLACE_PROBLEM_ANCHOR_UNRESOLVED,
    SPEC_PLACE_PROBLEM_MALFORMED, SPEC_PLACE_PROBLEM_NOT_LIST_ELEMENT,
    SPEC_PLACE_PROBLEM_NOT_SCOPED, SPEC_PLACE_PROBLEM_NO_CONTENT, SPEC_PLACE_PROBLEM_NO_SUCH_FIELD,
    SPEC_PLACE_PROBLEM_RESERVED_SLOT, SPEC_PLACE_PROBLEM_UNRESOLVED,
};
pub use spec_prefill::{
    prefill, SpecPrefillError, SpecPrefillErrorCode, SpecPrefillOptions, SpecPrefillResult,
};
pub use spec_review_annotations::{
    K_SPEC_HEADLINE_FIELD,
    annotation_issues_text, apply_inline_marks_text, count_annotations_text, decide_all_marks_text, format_comment_block,
    format_conflict_block,
    format_question_block, is_review_member_id, is_review_time, mark_change_text,
    normalize_review_time, strip_annotations_text, system_review_time, validate_review_annotations,
    SpecConflictAlternative, SpecConflictOutcome, SpecIndividualAnswer, SpecMarkDecision,
    SpecMarkEntry, SpecMarkIssue, SpecMarkKind, SpecMarkOutcome, SpecMarkReport, SpecMarkVote,
    SpecMarkedChange, SpecParagraph, SpecQuestionDraft, SpecQuestionOption, SpecReviewAnnotation,
    SpecReviewAnnotationCounts, SpecReviewAnnotationError, SpecReviewAnnotationKind,
    SpecReviewAnnotations, SpecReviewJsonOptions,
};
pub use spec_review_merge::{
    merge_reviews, merge_reviews_markdown, SpecMergeAddition, SpecMergeAnswers, SpecMergeComment,
    SpecMergeConflict, SpecMergeGuestQuestion, SpecMergeReviewer, SpecMergeRevision,
    SpecMergeUnanimous, SpecMergeVotes, SpecReviewMember, SpecReviewMergeError,
    SpecReviewMergeOptions, SpecReviewMergeReport, SpecReviewMergeResult, SpecReviewedCopy,
};
pub use spec_schema_validation::validate_spec_document;
pub use spec_section_id::{
    effective_list_item_section_id, K_SECTION_ID_SLOT,
    encode_two_letter_date, generate_list_item_section_id, is_collision, section_id_pattern_prefix,
    today_month_day, SpecSectionIdCollision, SpecSectionIdError,
};
pub use spec_serialization_order::{SpecSerializationOrder, SERIALIZATION_UNORDERED_FALLBACK};
pub use spec_text_pattern::{SomPatternError, SomTextPattern, SpecMatchSpan};
pub use spec_typed_values::{
    som_is_typed_field, som_typed_reading,
    som_format_bool, som_format_double, som_format_enum_name, som_format_int, som_format_num,
    som_parse_bool, som_parse_double, som_parse_enum_name, som_parse_int, som_parse_num,
    som_scalar_base, som_typed_text_readable, SomNum,
};
pub use spec_validator::{
    spec_derived_numbers, spec_validation_code_index, SpecDerivedNumber,
    SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS, SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY,
    SPEC_VALIDATION_CODE_DUPLICATE_LINK_ROW, SPEC_VALIDATION_CODE_EXTRACTED_LINK_MISSING,
    SPEC_VALIDATION_CODE_EXTRACTED_LINK_STALE, SPEC_VALIDATION_CODE_INVERSE_MISSING,
    SPEC_VALIDATION_CODE_LINK_VALUE_PENDING, SPEC_VALIDATION_CODE_SAME_AS_MISMATCH,
    SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE, SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL,
    SPEC_VALIDATION_CODE_UNMARKABLE,
    validate_document, SpecValidationError, SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED,
    SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED, SPEC_VALIDATION_CODE_COUNT_MISMATCH,
    SPEC_VALIDATION_ALL_CODES, SPEC_VALIDATION_CODE_DANGLING_PATH,
    SPEC_VALIDATION_CODE_DANGLING_REFERENCE,
    SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH, SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID,
    SPEC_VALIDATION_CODE_DUPLICATE_UNIT_ID, SPEC_VALIDATION_CODE_ENUM_VALUE_UNKNOWN,
    SPEC_VALIDATION_CODE_KIND_MISMATCH, SPEC_VALIDATION_CODE_MIN_ITEMS,
    SPEC_VALIDATION_CODE_MISSING_REQUIRED_FIELD, SPEC_VALIDATION_CODE_MULTIPLE_REFERENCES,
    SPEC_VALIDATION_CODE_ONE_OF_CASE_MISMATCH, SPEC_VALIDATION_CODE_UNITS_UNROUTED,
    SPEC_VALIDATION_CODE_UNIT_AREA_MALFORMED, SPEC_VALIDATION_CODE_UNIT_BUILDS_NOTHING,
    SPEC_VALIDATION_CODE_UNIT_EMITTER_UNKNOWN, SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD,
    SPEC_VALIDATION_CODE_UNKNOWN_UNIT, SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH,
};
