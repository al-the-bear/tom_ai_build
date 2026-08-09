/**
 * `tom_som_typescript_runtime` — the TypeScript port of the generic TomSpecs
 * object-model runtime (`tom_som_dart_runtime`).
 *
 * This is the value-free, generated-code-free half of the multi-platform spec
 * model: a meta-data loader ({@link SpecModel}), a reflection/resolution surface
 * ({@link SpecReflection}), a sparse in-memory document ({@link SpecDocument}), a
 * validator, and the YAML/Markdown codecs. It has **zero external runtime
 * dependencies** (Node built-ins only; `typescript` is a dev dependency) and is
 * validated against the shared language-agnostic conformance corpus in
 * `tom_som_conformance/corpus`.
 *
 * Re-exports the whole public surface so consumers (including the generated
 * `tom_som_typescript_v0`) import everything from `tom_som_typescript_runtime`.
 */

// paths
export {
  SPEC_PATH_SEPARATOR,
  specPathJoin,
  specPathSegments,
  specParentPath,
  listItemPath,
  splitListItemSegment,
} from './spec_paths';
export type { ListItemSegment } from './spec_paths';

// model
export {
  SpecFieldKind,
  parseFieldKind,
  SpecAnnotation,
  FormFieldSpec,
  SpecField,
  SpecClass,
  SpecRoot,
  SpecModel,
  SpecModelStampCheck,
  MILLIS_PER_DAY,
  DEFAULT_MAX_SNAPSHOT_AGE_MS,
  parseStampTimestamp,
  somModelVersionString,
} from './spec_model';
export type { SpecFieldKindValue } from './spec_model';

// reflection
export { SpecNodeKind, SpecResolution, SpecReflection } from './spec_reflection';
export type { SpecNodeKindValue } from './spec_reflection';

// document
export { SpecDocument } from './spec_document';
export type { DocumentJson, ListJson } from './spec_document';

// section-id derivation (AA1 criteria 3–6)
export {
  K_SECTION_ID_SLOT,
  effectiveListItemSectionId,
  encodeTwoLetterDate,
  sectionIdPatternPrefix,
  SpecSectionIdCollision,
  generateListItemSectionId,
} from './spec_section_id';

// serialization order (AA1 criterion 7)
export { SpecSerializationOrder } from './spec_serialization_order';

// typed-value store boundary (YRD7)
export {
  somParseInt,
  somFormatInt,
  somParseDouble,
  somFormatDouble,
  somParseNum,
  somFormatNum,
  somParseBool,
  somFormatBool,
  somParseEnumName,
  somFormatEnumName,
} from './spec_typed_values';

// generic modification API (YRD7)
export { SpecEditor } from './spec_editor';
export type { SomValue } from './spec_editor';

// validator
export {
  SpecValidationCode,
  SpecValidationError,
  validateDocument,
} from './spec_validator';
export type { SpecValidationCodeValue } from './spec_validator';

// facade
export {
  SomNode,
  SomScalar,
  SomList,
  SomVersionError,
  SomEditability,
  somEditabilityFor,
  checkSomModelVersion,
} from './som_facade';

// metadata core (SOM §7)
export {
  SomMetaKind,
  SomContentTypeMeta,
  SomFormFieldMeta,
  SomFormMeta,
  SomDocMeta,
  SomMetaExtra,
  SomMetaNode,
  SomMetaTree,
  SomMetaRef,
  SomListMetaRef,
} from './spec_meta';
export type {
  SomMetaKindValue,
  SomFormFieldMetaInit,
  SomDocMetaInit,
  SomMetaNodeInit,
  SomMetaRefFactory,
} from './spec_meta';

// meta bridge (spec-model → SomMetaTree)
export { buildSomMetaTree } from './spec_meta_bridge';

// meta diff (agreement oracle: generated trees vs bridge-built trees)
export { somMetaNodeDiff } from './spec_meta_diff';

// yaml codec (hierarchical v2, SOM §12)
export {
  FORMAT_VERSION,
  SpecYamlFormatException,
  SpecYamlContents,
  nodeKey,
  yamlKey,
  plainKey,
  dedupEmptyLines,
  writeScalar,
  writeHeader,
  encode as yamlEncode,
  decode as yamlDecode,
} from './spec_document_yaml';

// markdown codec (DocSpecs-conform, SOM §11)
export {
  SpecMarkdownRejectReason,
  SpecMarkdownRejection,
  SpecMarkdownResult,
  MarkdownFenceTracker,
  SpecDocumentMarkdown,
} from './spec_document_markdown';
export type { SpecMarkdownRejectReasonValue } from './spec_document_markdown';

// docspecs validation (SOM §14)
export {
  DocSpecsViolationRule,
  DocSpecsViolation,
  DocSpecsSection,
  DocSpecsDocument,
  docSpecsIdTransform,
  DocSpecsPatternCheck,
  DocSpecsSubsectionRule,
  DocSpecsSectionType,
  DocSpecsFormField,
  DocSpecsFormType,
  DocSpecsDocumentSection,
  DocSpecsSchema,
  DocSpecsValidator,
  bindDocspecsMarkdown,
} from './docspecs_validator';
export type {
  DocSpecsViolationRuleValue,
  DocSpecsSectionTypeInit,
  DocSpecsFormFieldInit,
} from './docspecs_validator';
