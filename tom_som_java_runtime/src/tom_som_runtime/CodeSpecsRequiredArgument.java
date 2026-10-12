package tom_som_runtime;

import java.util.Map;

/**
 * One A4 obligation ({@code codespecs_prompt.md} §4.4): a required {@code Cs*}
 * marker argument and the stored SOM field it derives from.
 */
public final class CodeSpecsRequiredArgument {
  /** The area whose extract makes the obligation apply. */
  public final String area;

  /** The marker, {@code @CsTable}. */
  public final String marker;

  /** The required argument, {@code table}. */
  public final String argument;

  /** The SOM field the argument derives from. */
  public final CodeSpecsFieldRef field;

  /**
   * When set, the value must also equal a value the run carries here — the
   * {@code domainEnum} → {@code DMENE} case of §4.4. {@code null} otherwise.
   */
  public final CodeSpecsFieldRef resolvesTo;

  /**
   * When set, an instance is held to the row only if it carries this field with
   * the value {@link #whenEquals} — the obligation sits on a {@code @Case}.
   */
  public final CodeSpecsFieldRef when;

  /** The value {@link #when} must hold; {@code null} without {@link #when}. */
  public final String whenEquals;

  public CodeSpecsRequiredArgument(
      String area,
      String marker,
      String argument,
      CodeSpecsFieldRef field,
      CodeSpecsFieldRef resolvesTo,
      CodeSpecsFieldRef when,
      String whenEquals) {
    this.area = area;
    this.marker = marker;
    this.argument = argument;
    this.field = field;
    this.resolvesTo = resolvesTo;
    this.when = when;
    this.whenEquals = whenEquals;
  }

  /** Reads one row of the catalogue's {@code gate.requiredArguments}. */
  @SuppressWarnings("unchecked")
  public static CodeSpecsRequiredArgument fromJson(Map<String, Object> j) {
    String label = CodeSpecsFieldRef.rowLabel(j, new String[] {"marker", "argument", "area"});
    Object resolves = j.get("resolvesTo");
    Object rawWhen = j.get("when");
    Map<String, Object> when = rawWhen instanceof Map ? (Map<String, Object>) rawWhen : null;
    return new CodeSpecsRequiredArgument(
        CodeSpecsFieldRef.requiredString(j, "area", label),
        CodeSpecsFieldRef.requiredString(j, "marker", label),
        CodeSpecsFieldRef.requiredString(j, "argument", label),
        CodeSpecsFieldRef.fromJson(j),
        resolves instanceof Map
            ? CodeSpecsFieldRef.fromJson((Map<String, Object>) resolves)
            : null,
        when == null ? null : CodeSpecsFieldRef.fromJson(when),
        when == null ? null : CodeSpecsFieldRef.requiredString(when, "equals", label));
  }

  /** The source field's class. */
  public String className() {
    return field.className;
  }

  /** The source field's member. */
  public String member() {
    return field.member;
  }

  /** The source field's form field. */
  public String formField() {
    return field.formField;
  }

  /** The source field, as findings name it. */
  public String source() {
    return field.source();
  }
}
