package tom_som_runtime;

import java.util.Map;

/**
 * A SOM field a gate table names: a class, one of its members, and the form
 * field when the value is one field of a {@code @Form} section.
 */
public final class CodeSpecsFieldRef {
  /** The model class. */
  public final String className;

  /** The member of {@link #className}. */
  public final String member;

  /** The form field of {@link #member}, or {@code null} for a whole-member value. */
  public final String formField;

  public CodeSpecsFieldRef(String className, String member, String formField) {
    this.className = className;
    this.member = member;
    this.formField = formField;
  }

  /**
   * Reads one reference; {@code className} and {@code member} are required and
   * throw an {@link IllegalArgumentException} naming the row when missing.
   */
  public static CodeSpecsFieldRef fromJson(Map<String, Object> j) {
    String label = rowLabel(j, new String[] {"className", "member"});
    Object ff = j.get("formField");
    return new CodeSpecsFieldRef(
        requiredString(j, "className", label),
        requiredString(j, "member", label),
        ff instanceof String ? (String) ff : null);
  }

  /** {@code Class.member} or {@code Class.member.formField} — how findings name it. */
  public String source() {
    return formField == null
        ? className + "." + member
        : className + "." + member + "." + formField;
  }

  @Override
  public String toString() {
    return "CodeSpecsFieldRef(" + source() + ")";
  }

  // --- shared row helpers for the gate tables --------------------------------

  /** The row's first non-empty identifying cell, for an error message. */
  static String rowLabel(Map<String, Object> j, String[] preferred) {
    for (String key : preferred) {
      Object v = j.get(key);
      if (v instanceof String && !((String) v).isEmpty()) {
        return key + " \"" + v + "\"";
      }
    }
    if (j.isEmpty()) {
      return "an empty row";
    }
    return "the row with keys [" + String.join(", ", j.keySet()) + "]";
  }

  /** A required non-empty string cell. */
  static String requiredString(Map<String, Object> j, String key, String owner) {
    Object v = j.get(key);
    if (v instanceof String && !((String) v).isEmpty()) {
      return (String) v;
    }
    throw new IllegalArgumentException(
        "CodeSpecs area catalogue: " + owner + " is missing a non-empty \"" + key
            + "\" (got " + (v == null ? "absent" : String.valueOf(v)) + ")");
  }
}
