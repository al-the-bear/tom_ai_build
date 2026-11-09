// The three-tier validation of a TomSpecs document, shared by the
// `spec_checks validate` command and the answer import.
//
//   1. decode   — the hierarchical v2 YAML against the root's metadata tree:
//                 every key must sit where the model says;
//   2. schema   — the markdown rendition against the root's DocSpecs schema
//                 (completeness);
//   3. instance — `validateDocument`: field kinds, enum values, list minima,
//                 `refersTo` resolution (values).
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// What a document of one root is checked against: the model, the root's
/// metadata tree and type, and its DocSpecs schema. A generated facade
/// supplies them (`tom_som_dart_v0`: `somSpecModel`,
/// `d00SolutionBlueprintMetaTree`, `somDocSpecsSchema('solution-blueprint')`),
/// so the checks themselves need no facade.
class SpecRootDefinition {
  /// Bundles what the checks of one document root need.
  const SpecRootDefinition({
    required this.model,
    required this.tree,
    required this.rootType,
    required this.schema,
  });

  /// The object model the document belongs to.
  final SpecModel model;

  /// The metadata tree a document of this root decodes against.
  final SomMetaTree tree;

  /// The model root type, e.g. `D00SolutionBlueprint`.
  final String rootType;

  /// The DocSpecs schema the root's markdown rendition is held to.
  final DocSpecsSchema schema;

  /// Decodes a document of this root from its YAML text (tier 1).
  ///
  /// Throws [SpecYamlFormatException] when a key does not fit the model.
  SpecDocument decode(String yamlText) =>
      SpecDocumentYaml.decode(yamlText, tree).document;

  /// Renders the DocSpecs markdown rendition of a decoded document.
  ///
  /// Throws [SbpRenderException] when a value cannot be rendered; the runtime
  /// refuses such a value with an [ArgumentError].
  String render(SpecDocument doc) {
    try {
      return doc.toMarkdown(model, rootType: rootType);
    } on ArgumentError catch (e) {
      throw SbpRenderException('${e.message}');
    }
  }

  /// Runs tiers 2 and 3 on [doc]; [markdown] is its rendition when the caller
  /// already rendered it.
  SbpValidation validate(SpecDocument doc, {String? markdown}) {
    final rendition = markdown ?? render(doc);
    return SbpValidation(
      markdown: rendition,
      schemaFindings: DocSpecsValidator(schema).validateMarkdown(rendition),
      instanceFindings: validateDocument(model, doc),
    );
  }
}

/// A decoded document holds a value the DocSpecs markdown format cannot
/// represent (for example a content with an unterminated code fence), so no
/// rendition can be written.
class SbpRenderException implements Exception {
  /// Reports why the rendition failed: the runtime's [message].
  SbpRenderException(this.message);

  /// The runtime's reason, naming the value's path.
  final String message;

  @override
  String toString() => message;
}

/// The outcome of tiers 2 and 3 for one decoded document.
class SbpValidation {
  /// Bundles the [markdown] rendition the schema tier read with both
  /// finding lists.
  SbpValidation({
    required this.markdown,
    required this.schemaFindings,
    required this.instanceFindings,
  });

  /// The rendition the schema tier validated.
  final String markdown;

  /// Tier 2 findings (the rendition against the DocSpecs schema).
  final List<DocSpecsViolation> schemaFindings;

  /// Tier 3 findings (the document against the model).
  final List<SpecValidationError> instanceFindings;

  /// Whether both tiers are clean.
  bool get isClean => schemaFindings.isEmpty && instanceFindings.isEmpty;

  /// Every finding, one line each, then the two tier summaries: the format
  /// the `spec_checks validate` command prints.
  List<String> reportLines() => [
    for (final f in schemaFindings) 'SCHEMA   $f',
    for (final f in instanceFindings)
      'INSTANCE [${f.code.name}] ${f.path}: ${f.message}',
    'schema    ${schemaFindings.length} finding(s)',
    'instance  ${instanceFindings.length} finding(s)',
  ];
}
