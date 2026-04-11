/// Marks a class as a document root in the specification model.
///
/// Applied to top-level classes that represent complete document types
/// (e.g., ProjectDefinition, TechnicalRequirements). Provides metadata
/// about the document's identity and its relationship to other documents.
///
/// Example:
/// ```dart
/// @Document(
///   name: 'Project Definition',
///   description: 'Comprehensive specification document covering all aspects '
///       'of the system from current state through implementation.',
///   basedOn: [TomSystemRequest, TomRequirementsPortfolio],
/// )
/// class ProjectDefinition { ... }
/// ```
class Document {
  /// Display name of the document (e.g., 'Project Definition').
  final String name;

  /// Description of the document's purpose and scope.
  final String description;

  /// List of document types this document is derived from or based on.
  /// These represent upstream artifacts that feed into this document.
  final List<Type>? basedOn;

  const Document({
    required this.name,
    required this.description,
    this.basedOn,
  });
}
