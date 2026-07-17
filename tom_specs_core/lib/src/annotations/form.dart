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

/// The structural role a form field can play within its owning section
/// (YRD6, decision (d) of `headline_id_storage_decisions.md`).
///
/// A role field is a *view* onto the section's structural storage — its value
/// IS the section headline ([title]) or the stored section id ([id]). There is
/// one storage slot with two access paths, never a duplicated value: the field
/// is not stored in the form-value store, serialization emits the value once
/// (as the heading text / id comment), and parsing restores the field view
/// from the heading.
enum FieldRole {
  /// The field's value is identical with the owning section's headline.
  title,

  /// The field's value is identical with the owning section's stored section
  /// id. Only valid on the class-level `@Form` of a list-element class whose
  /// owning list carries `@SectionIdPattern`; writes are subject to that
  /// pattern's uniqueness validation.
  id,
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

  /// Optional hint text providing guidance on valid values, formats, or
  /// allowed options. Used by AI assistants and UI tools to help users
  /// fill in the field correctly.
  final String? hint;

  /// The structural role of this field (YRD6). A role field is a view onto
  /// the owning section's headline ([FieldRole.title]) or stored section id
  /// ([FieldRole.id]) — one storage slot, two views. `null` for ordinary
  /// form-value fields. Role fields must be `String`-typed; at most one
  /// title-role and one id-role field per form.
  final FieldRole? role;

  /// Optional predefined initial content for the field (YRD6, decision (d):
  /// "the marker can additionally predefine the field's initial content").
  /// Meta-only, like `@Headline`: tooling/editors use it as the prefill
  /// value; the runtime does not write it automatically.
  final String? initial;

  const Field(
    this.name,
    this.type,
    this.description, {
    this.required = false,
    this.hint,
    this.role,
    this.initial,
  });

  /// A title-role field: its value is identical with the owning section's
  /// headline.
  const Field.title(
    this.name,
    this.description, {
    this.required = false,
    this.hint,
    this.initial,
  })  : type = String,
        role = FieldRole.title;

  /// An id-role field: its value is identical with the owning section's
  /// stored section id (list items only; `@SectionIdPattern` uniqueness
  /// validation applies on write).
  const Field.id(
    this.name,
    this.description, {
    this.required = false,
    this.hint,
    this.initial,
  })  : type = String,
        role = FieldRole.id;
}
