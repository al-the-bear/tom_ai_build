/// TomSpecs Specification Object Model — generic Dart runtime.
///
/// The language-independent, hand-written runtime shared by every generated
/// typed `tom_som_dart_v0` facade and the TomSpecs editor:
///
///   * [SomMetaNode] / [SomMetaTree] — the canonical DR1 §3.1 metadata tree
///     (every annotation, exact class/member names) with the dynamic lookups
///     [SomMetaTree.byId] and [SomMetaTree.byPath]; generated facades emit
///     the populated tree, this runtime defines the types;
///   * [buildSomMetaTree] — the bridge that expands an exported [SpecModel]
///     class graph into a wired [SomMetaTree] (used until the generated
///     facades emit trees directly);
///   * [SpecDocument] / [SpecDocumentState] — the sparse, path-keyed in-memory
///     representation of a concrete document and its undo snapshots;
///   * [SpecDocumentYaml] — the hierarchical `*.docspecs.yaml` v2 codec (one
///     nested tree walked against the metadata tree; strict
///     [SpecYamlFormatException] load errors, no v1 compatibility);
///   * [SpecModel] and friends ([SpecRoot], [SpecClass], [SpecField],
///     [SpecAnnotation], [FormFieldSpec], [SpecFieldKind]) — the meta-model
///     ("reflection") loaded from the exported spec-model meta-data;
///   * [SpecReflection] — value-free enumeration and path resolution over a
///     [SpecModel];
///   * [SpecQueryEngine] / [SpecQueryCursor] — the lexical/structural grep-like
///     query facility (find by text/regex, kind, class, id/path,
///     `@MapsTo`/`@DetailedIn`, state) with lazy, edit-stable cursor iteration;
///   * [validateDocument] — checks a document's values against the model;
///   * [DocSpecsDocument] / [DocSpecsSchema] / [DocSpecsValidator] — the
///     consolidated DR1 §6 DocSpecs module: schema-free markdown parse,
///     validation against a DR3-generated `*.docspecs-schema.yaml` with a
///     structured [DocSpecsViolation] list, and [bindDocSpecsMarkdown] onto
///     the SOM metadata tree;
///   * [SpecNodeCreator] / [checkAddNode] — the meta-model-validated node
///     creation gate (allowed child kind / section-id pattern / cardinality),
///     so a document only ever grows in model-permitted ways;
///   * [SomNode] / [SomList] / [SomScalar] / [checkSomModelVersion] /
///     [somEditabilityFor] / [SomEditability] — the hand-written support the
///     generated `tom_som_dart_v0` typed facade extends (editing layer +
///     instantiation-time version check + its non-throwing editability query).
///
/// Pure Dart, no Flutter dependency.
library;

export 'src/docspecs_validator.dart';
export 'src/som_facade.dart';
export 'src/spec_document.dart';
export 'src/spec_document_markdown.dart';
export 'src/spec_document_yaml.dart';
export 'src/spec_meta.dart';
export 'src/spec_meta_bridge.dart';
export 'src/spec_model.dart';
export 'src/spec_node_creation.dart';
export 'src/spec_paths.dart';
export 'src/spec_query.dart';
export 'src/spec_section_id.dart';
export 'src/spec_reflection.dart';
export 'src/spec_serialization_order.dart';
export 'src/spec_validator.dart';
