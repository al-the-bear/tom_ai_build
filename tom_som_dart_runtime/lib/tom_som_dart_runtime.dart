/// TomSpecs Specification Object Model — generic Dart runtime.
///
/// The language-independent, hand-written runtime shared by every generated
/// typed `tom_som_dart_v0` facade and the TomSpecs editor:
///
///   * [SomMetaNode] / [SomMetaTree] — the canonical SOM §7.1 metadata tree
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
///   * [SpecChip] / [SpecRowExtras] / [kRenderedAnnotations] — the theme-free
///     *display semantics* of the model's annotations: which markers a row
///     carries, what each says, and when one must be suppressed. Shared so the
///     editor and the reviewer cannot disagree about what a marker means while
///     each renders it in its own idiom;
///   * [SpecEditor] — the generic, meta-validated modification API (YRD7):
///     typed value/form-field access (via the shared `somParse*`/`somFormat*`
///     boundary helpers), headline/id editing, list-item and clear-section
///     operations — the layer the generated typed facades are a thin veneer
///     over;
///   * [SpecQueryEngine] / [SpecQueryCursor] — the lexical/structural grep-like
///     query facility (find by text/pattern, kind, class, id/path,
///     `@MapsTo`/`@DetailedIn`, state) with lazy, edit-stable cursor iteration;
///   * [SomTextPattern] — the portable pattern subset the `text` dimension
///     matches with, transcribed into all nine runtimes rather than delegated
///     to each language's regex engine, so `matchSpans` is identical by
///     construction (two runtimes have no regex to delegate to at all);
///   * [validateDocument] — checks a document's values against the model;
///   * [DocSpecsDocument] / [DocSpecsSchema] / [DocSpecsValidator] — the
///     consolidated SOM §14 DocSpecs module: schema-free markdown parse,
///     validation against a generated `*.docspecs-schema.yaml` with a
///     structured [DocSpecsViolation] list, and [bindDocSpecsMarkdown] onto
///     the SOM metadata tree;
///   * [SpecNodeCreator] / [checkAddNode] — the meta-model-validated node
///     creation gate (allowed child kind / section-id pattern / cardinality),
///     so a document only ever grows in model-permitted ways;
///   * [SomNode] / [SomList] / [SomScalar] / [checkSomModelVersion] /
///     [somEditabilityFor] / [SomEditability] — the hand-written support the
///     generated `tom_som_dart_v0` typed facade extends (editing layer +
///     instantiation-time version check + its non-throwing editability query);
///   * [CodeSpecsExtractor] / [CodeSpecsExtract] / [CodeSpecsAreaCatalog] — the
///     machine half of TomSpecs Phase 4: routes a filled document by
///     `@CodeSpecKind` into one bounded, cited extract per CodeSpecs area. It
///     copies and indexes; it never summarises, rephrases or names anything,
///     so every scalar it emits occurs character-for-character in its source.
///
/// Pure Dart, no Flutter dependency.
library;

export 'src/docspecs_validator.dart';
export 'src/spec_annotation_display.dart';
export 'src/spec_codespecs_extract.dart';
export 'src/som_facade.dart';
export 'src/spec_document.dart';
export 'src/spec_document_markdown.dart';
export 'src/spec_document_yaml.dart';
export 'src/spec_editor.dart';
export 'src/spec_meta.dart';
export 'src/spec_meta_bridge.dart';
export 'src/spec_meta_diff.dart';
export 'src/spec_model.dart';
export 'src/spec_node_creation.dart';
export 'src/spec_paths.dart';
export 'src/spec_query.dart';
export 'src/spec_section_id.dart';
export 'src/spec_reflection.dart';
export 'src/spec_serialization_order.dart';
export 'src/spec_text_pattern.dart';
export 'src/spec_typed_values.dart';
export 'src/spec_validator.dart';
