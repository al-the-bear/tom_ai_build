/// Marks that the `content` text of a section must not be empty.
///
/// Applied to model classes. When present, the validator ensures the section
/// has non-empty text content between the heading and the next heading.
class TextRequired {
  const TextRequired();
}
