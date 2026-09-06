/// Declares a field as a reference to data owned elsewhere in the model tree.
///
/// Applied to singular or list fields whose Dart type is the referenced
/// section class. The outliner shows the reference but does not recurse into
/// the referenced tree. The schema generator validates cross-references.
///
/// [description] is a human-readable label for the reference.
class Reference {
  /// A human-readable label for what is being pointed at.
  ///
  /// This is what the outline shows in place of the referenced subtree, which
  /// it declines to recurse into — so it is the reader's only description of
  /// the target at this point in the tree.
  final String description;

  /// Declares the annotated member as a reference rather than an owning link.
  const Reference(this.description);
}
