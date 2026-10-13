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

  // --- shared row helpers for the catalogue's tables -------------------------
  //
  // Used by every catalogue row reader — slices, steps, areas and the gate
  // tables — so a malformed row fails with one message shape that names it.

  /**
   * Names a catalogue row for an error: {@code <key> "<value>"} for the first
   * {@code preferred} key the row carries as a non-empty string, else
   * {@code the row with keys [k1, k2]} (the row's own key order), else
   * {@code an empty row}.
   *
   * <p>Deliberately tolerant — it runs before the required-key checks, so it
   * must produce something for a row missing the very key that would identify
   * it.
   */
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

  /**
   * A required non-empty string cell; anything else throws an
   * {@link IllegalArgumentException} naming the row by {@code owner} (a
   * {@link #rowLabel}).
   */
  static String requiredString(Map<String, Object> j, String key, String owner) {
    Object v = j.get(key);
    if (v instanceof String && !((String) v).isEmpty()) {
      return (String) v;
    }
    throw new IllegalArgumentException(
        "CodeSpecs area catalogue: " + owner + " is missing a non-empty \"" + key
            + "\" (got " + describe(v) + ")");
  }

  /**
   * A required numeric cell, as an int. Only a JSON number passes — the string
   * {@code "2"} is rejected rather than coerced, and a missing cell fails
   * instead of reading 0. The {@link IllegalArgumentException} names the row by
   * {@code owner} (a {@link #rowLabel}).
   */
  static int requiredInt(Map<String, Object> j, String key, String owner) {
    Object v = j.get(key);
    if (v instanceof Number) {
      return ((Number) v).intValue();
    }
    throw new IllegalArgumentException(
        "CodeSpecs area catalogue: " + owner + " is missing a numeric \"" + key
            + "\" (got " + describe(v) + ")");
  }

  /**
   * Renders a rejected value for an error message: {@code absent} for a missing
   * key, else the value's type and its quoted text, so {@code "3"} and
   * {@code 3} are distinguishable.
   */
  static String describe(Object v) {
    return v == null
        ? "absent"
        : v.getClass().getSimpleName() + " " + CodeSpecsExtract.yamlString(String.valueOf(v));
  }
}
