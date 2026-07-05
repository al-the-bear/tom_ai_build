/// TomSpecs Specification Object Model — generic Dart runtime.
///
/// The language-independent, hand-written runtime shared by every generated
/// typed `tom_som_dart_v0` facade and the TomSpecs editor:
///
///   * [SpecDocument] / [SpecDocumentState] — the sparse, path-keyed in-memory
///     representation of a concrete document and its undo snapshots;
///   * [SpecModel] and friends ([SpecRoot], [SpecClass], [SpecField],
///     [SpecAnnotation], [FormFieldSpec], [SpecFieldKind]) — the meta-model
///     ("reflection") loaded from the exported spec-model meta-data;
///   * [SpecReflection] — value-free enumeration and path resolution over a
///     [SpecModel];
///   * [SpecQueryEngine] / [SpecQueryCursor] — the lexical/structural grep-like
///     query facility (find by text/regex, kind, class, id/path,
///     `@MapsTo`/`@DetailedIn`, state) with lazy, edit-stable cursor iteration;
///   * [validateDocument] — checks a document's values against the model;
///   * [SpecNodeCreator] / [checkAddNode] — the meta-model-validated node
///     creation gate (allowed child kind / section-id pattern / cardinality),
///     so a document only ever grows in model-permitted ways;
///   * [SomNode] / [SomList] / [SomScalar] / [checkSomModelVersion] — the
///     hand-written support the generated `tom_som_dart_v0` typed facade
///     extends (editing layer + instantiation-time version check).
///
/// Pure Dart, no Flutter dependency.
library;

export 'src/som_facade.dart';
export 'src/spec_document.dart';
export 'src/spec_document_markdown.dart';
export 'src/spec_document_yaml.dart';
export 'src/spec_model.dart';
export 'src/spec_node_creation.dart';
export 'src/spec_paths.dart';
export 'src/spec_query.dart';
export 'src/spec_section_id.dart';
export 'src/spec_reflection.dart';
export 'src/spec_serialization_order.dart';
export 'src/spec_validator.dart';
