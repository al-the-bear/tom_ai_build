'use strict';

/**
 * `tom_som_runtime` — the JavaScript port of the generic TomSpecs object-model
 * runtime (`tom_som_dart_runtime`).
 *
 * This is the value-free, generated-code-free half of the multi-platform spec
 * model: a meta-data loader ({@link SpecModel}), a reflection/resolution surface
 * ({@link SpecReflection}), a sparse in-memory document ({@link SpecDocument}), a
 * validator, and the YAML/Markdown codecs. It has **zero external dependencies**
 * (Node built-ins only) and is validated against the shared language-agnostic
 * conformance corpus in `tom_som_conformance/corpus`.
 */

const { SpecDocument } = require('./spec_document');
const {
  SpecFieldKind,
  parseFieldKind,
  SpecAnnotation,
  FormFieldSpec,
  SpecField,
  SpecClass,
  SpecRoot,
  SpecModel,
} = require('./spec_model');
const {
  SPEC_PATH_SEPARATOR,
  specPathJoin,
  specPathSegments,
  listItemPath,
  splitListItemSegment,
} = require('./spec_paths');
const {
  SpecNodeKind,
  SpecResolution,
  SpecReflection,
} = require('./spec_reflection');
const {
  SpecValidationCode,
  SpecValidationError,
  validateDocument,
} = require('./spec_validator');
const {
  SomNode,
  SomScalar,
  SomList,
  SomVersionError,
  checkSomModelVersion,
} = require('./som_facade');
const {
  FORMAT_VERSION,
  SpecYamlContents,
  encode: yamlEncode,
  decode: yamlDecode,
} = require('./spec_document_yaml');
const {
  SpecMarkdownRejectReason,
  SpecMarkdownRejection,
  SpecMarkdownResult,
  SpecDocumentMarkdown,
} = require('./spec_document_markdown');

module.exports = {
  // paths
  SPEC_PATH_SEPARATOR,
  specPathJoin,
  specPathSegments,
  listItemPath,
  splitListItemSegment,
  // model
  SpecFieldKind,
  parseFieldKind,
  SpecAnnotation,
  FormFieldSpec,
  SpecField,
  SpecClass,
  SpecRoot,
  SpecModel,
  // reflection
  SpecNodeKind,
  SpecResolution,
  SpecReflection,
  // document
  SpecDocument,
  // validator
  SpecValidationCode,
  SpecValidationError,
  validateDocument,
  // facade
  SomNode,
  SomScalar,
  SomList,
  SomVersionError,
  checkSomModelVersion,
  // yaml codec
  FORMAT_VERSION,
  SpecYamlContents,
  yamlEncode,
  yamlDecode,
  // markdown codec
  SpecMarkdownRejectReason,
  SpecMarkdownRejection,
  SpecMarkdownResult,
  SpecDocumentMarkdown,
};
