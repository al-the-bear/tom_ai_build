package tom_som_runtime;

import java.util.Map;

/** A single form field within a {@code @Form} content section. */
public final class FormFieldSpec {
  public final String name;
  public final String label;
  public final String type;
  public final String hint;
  public final boolean required;

  /**
   * Structural role of the field (YRD6): {@code "title"} (view onto the owning
   * section's headline), {@code "id"} (view onto the stored section id), or
   * {@code null} for an ordinary form-value field.
   */
  public final String role;

  /** Predefined initial content (YRD6, meta-only editor prefill), or {@code null}. */
  public final String initial;

  public FormFieldSpec(
      String name, String label, String type, String hint, boolean required) {
    this(name, label, type, hint, required, null, null);
  }

  public FormFieldSpec(
      String name, String label, String type, String hint, boolean required,
      String role, String initial) {
    this.name = name;
    this.label = label;
    this.type = type;
    this.hint = hint;
    this.required = required;
    this.role = role;
    this.initial = initial;
  }

  public static FormFieldSpec fromJson(Map<String, Object> j) {
    String name = (String) j.get("name");
    Object label = j.get("label");
    Object type = j.get("type");
    return new FormFieldSpec(
        name,
        label != null ? label.toString() : name,
        type != null ? type.toString() : "String",
        j.get("hint") != null ? j.get("hint").toString() : null,
        Boolean.TRUE.equals(j.get("required")),
        j.get("role") != null ? j.get("role").toString() : null,
        j.get("initial") != null ? j.get("initial").toString() : null);
  }
}
