/// Restricts the set of tags that may be applied to sections of this type.
///
/// Applied to model classes. Tags are string labels used for categorization
/// or filtering in the document schema.
class AllowedTags {
  final List<String> tags;

  const AllowedTags(this.tags);
}
