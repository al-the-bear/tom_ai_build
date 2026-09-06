/// Provides a short inline comment that appears in the outliner output.
///
/// Applied to fields or classes.
///
/// In the outline, shown as `← (text)` aligned to column 50.
class Comment {
  /// The comment text, rendered verbatim.
  ///
  /// Keep it to one short line: the outliner aligns it to a fixed column and
  /// does not wrap, so a long text pushes the outline past a readable width.
  final String text;

  /// Attaches [text] to the annotated class or field as an outline comment.
  const Comment(this.text);
}
