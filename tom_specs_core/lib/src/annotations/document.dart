/// Marks a class as a document root in the specification model.
///
/// Applied to top-level classes that represent complete document types
/// (e.g., D00SolutionBlueprint, D03InformationModel). Provides metadata
/// about the document's identity and its relationship to other documents.
///
/// Example:
/// ```dart
/// @Document(
///   name: 'Information Model',
///   description: 'The system\'s entities, their attributes and the '
///       'relationships between them.',
///   basedOn: [D00SolutionBlueprint],
/// )
/// class D03InformationModel { ... }
/// ```
class Document {
  /// Display name of the document (e.g., 'Information Model').
  final String name;

  /// Description of the document's purpose and scope.
  final String description;

  /// List of document types this document is derived from or based on.
  /// These represent upstream artifacts that feed into this document.
  final List<Type>? basedOn;

  /// Declares the annotated class as a document root.
  ///
  /// [name] and [description] are required because they are what the editor
  /// and the generated schemas show an author when they open the document;
  /// [basedOn] is omitted by a root that projects no other document.
  const Document({required this.name, required this.description, this.basedOn});
}
