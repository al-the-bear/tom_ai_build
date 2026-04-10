/// Declares a field as a reference to data owned elsewhere in the model tree.
///
/// Applied to singular or list fields whose Dart type is the referenced
/// section class. The outliner shows the reference but does not recurse into
/// the referenced tree. The schema generator validates cross-references.
///
/// [description] is a human-readable label for the reference.
class Reference {
  final String description;

  const Reference(this.description);
}
