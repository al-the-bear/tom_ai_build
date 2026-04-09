/// Declares the minimum text length for a string field.
///
/// Applied to `String?` or `content` fields. The validator checks that the
/// text content has at least [length] characters.
class MinLength {
  final int length;

  const MinLength(this.length);
}
