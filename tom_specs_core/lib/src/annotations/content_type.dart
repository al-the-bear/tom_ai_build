/// Annotates the `content` field to declare the format of the content text.
///
/// Applied to `content` fields only.
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
  final String type;
  final String description;

  const ContentType(this.type, this.description);
}
