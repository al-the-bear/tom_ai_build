/// Declares the maximum text length for a string field.
///
/// Applied to `String?` or `content` fields. The validator checks that the
/// text content does not exceed [length] characters.
class MaxLength {
  final int length;

  const MaxLength(this.length);
}
