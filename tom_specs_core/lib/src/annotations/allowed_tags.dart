/// Restricts the set of tags that may be applied to sections of this type.
///
/// Applied to model classes. Tags are string labels used for categorization
/// or filtering in the document schema.
class AllowedTags {
  /// The complete set of admissible tags.
  ///
  /// Closed — a tag outside the list is rejected rather than passed through,
  /// so a document cannot introduce a tag the model has not declared.
  final List<String> tags;

  /// Declares [tags] as the closed tag vocabulary of the annotated type.
  const AllowedTags(this.tags);
}
