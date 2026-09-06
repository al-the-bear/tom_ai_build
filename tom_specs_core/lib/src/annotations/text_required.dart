/// Marks that the `content` text of a section must not be empty.
///
/// Applied to model classes. When present, the validator ensures the section
/// has non-empty text content between the heading and the next heading.
class TextRequired {
  /// Requires non-empty body text on the annotated section.
  ///
  /// Takes no arguments — a floor on the *length* of that text is
  /// `@MinLength`, which is a separate annotation because most sections want
  /// presence without a threshold.
  const TextRequired();
}
