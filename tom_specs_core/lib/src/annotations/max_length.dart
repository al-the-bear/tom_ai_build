/// Declares the maximum text length for a string field.
///
/// Applied to `String?` or `content` fields. The validator checks that the
/// text content does not exceed [length] characters.
class MaxLength {
  /// The inclusive upper bound on the text, in characters.
  final int length;

  /// Caps the annotated text field at [length] characters.
  const MaxLength(this.length);
}
