package tom_som_runtime;

/**
 * One field of a {@code @Form} section (DR1 §3.1 FormMeta.fields) — a faithful
 * port of {@code spec_meta.dart} / {@code spec_meta.ts}.
 */
public final class SomFormFieldMeta {
  /** The exact model field name ({@code "approvedBy"}). */
  public final String name;

  /** The Dart type name of the field ({@code "String"}, {@code "int"}, …). */
  public final String typeName;

  /** The display label / description, {@code null} when the form declares none. */
  public final String description;

  /** Whether the form marks the field as required. */
  public final boolean required;

  /** The authoring hint (e.g. {@code "e.g. 1.0"}), {@code null} when absent. */
  public final String hint;

  /**
   * Structural role of the field (YRD6): {@code "title"} (the field is a view
   * onto the owning section's headline), {@code "id"} (view onto the stored
   * section id), or {@code null} for an ordinary form-value field. Role fields
   * are never stored in the form-value store; serialization emits their
   * value once — as the heading text / id comment.
   */
  public final String role;

  /** Predefined initial content (YRD6, meta-only editor prefill), or {@code null}. */
  public final String initial;

  /** The declaration order within the form. */
  public final int order;

  public SomFormFieldMeta(
      String name,
      String typeName,
      String description,
      boolean required,
      String hint,
      int order) {
    this(name, typeName, description, required, hint, null, null, order);
  }

  public SomFormFieldMeta(
      String name,
      String typeName,
      String description,
      boolean required,
      String hint,
      String role,
      String initial,
      int order) {
    this.name = name;
    this.typeName = typeName;
    this.description = description;
    this.required = required;
    this.hint = hint;
    this.role = role;
    this.initial = initial;
    this.order = order;
  }
}
