/// Declares the minimum text length for a string field.
///
/// Applied to `String?` or `content` fields. The validator checks that the
/// text content has at least [length] characters.
class MinLength {
  /// The inclusive lower bound on the text, in characters.
  ///
  /// A section whose text must merely be present carries `@TextRequired`
  /// instead — this is for a floor an author has to reach, not for presence.
  final int length;

  /// Requires the annotated text field to hold at least [length] characters.
  const MinLength(this.length);
}
