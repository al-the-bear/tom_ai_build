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
/// Required for classes with a `String? content` field that are not *Section
/// types. For *Section classes, the description comes from the doc-comment on
/// the field in the class that uses the section variable.
class ContentType {
  final String type;
  final String description;

  const ContentType(this.type, [this.description = '']);
}
