/// Declares the form fields for a section whose content is structured as
/// name-value pairs (one per line).
///
/// Applied to the `content` field of form section classes. Each [Field]
/// declares a named form value with its Dart type and a human-readable
/// description.
class Form {
  final List<Field> fields;

  const Form(this.fields);
}

/// A single form field declaration.
class Field {
  /// Field name as it appears in the document (camelCase; display name
  /// conversion is done by tooling).
  final String name;

  /// Dart type of the value. Use `String` for free text, `int`/`double` for
  /// numbers, an enum type for constrained choices.
  final Type type;

  /// Short description shown in outlines and documentation.
  final String description;

  /// Whether this field is required (non-empty).
  final bool required;

  const Field(this.name, this.type, this.description, {this.required = false});
}
