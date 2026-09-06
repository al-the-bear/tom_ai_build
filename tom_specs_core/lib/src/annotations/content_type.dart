/// Annotates the `content` field to declare the format of the content text.
///
/// **Must** be applied to a `String? content` field — never on a class.
///
/// When [type] is `'Form'` (the default), the class's other scalar fields
/// represent form fields within the content. When [type] is any other value
/// (e.g., `'DDL'`, `'SQL'`, `'Dart'`, `'ER-Diagram'`, `'Mermaid'`), the class
/// must not have other scalar fields — the content occupies the full text.
///
/// [description] explains what should be described in the content field.
/// For *Section classes, use: 'The description for the content is provided
/// by the doc-comment on the field declaration of this type'.
class ContentType {
  /// The content format — `'Form'` by default, otherwise a format name such as
  /// `'DDL'`, `'SQL'`, `'Dart'`, `'ER-Diagram'` or `'Mermaid'`.
  ///
  /// Any value other than `'Form'` claims the whole section body for the
  /// content, so the declaring class must then carry no other scalar fields.
  final String type;

  /// What an author is expected to write into the `content` field.
  ///
  /// This describes the *content*, not the section. On the `*Section` leaf
  /// classes it defers to the doc comment on the member that declares the
  /// section, because only the member knows what that particular section is
  /// for — the leaf class is reused across many of them.
  final String description;

  /// Declares the annotated `content` field as holding [type]-formatted text.
  const ContentType(this.type, this.description);
}
