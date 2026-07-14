package tom_som_runtime;

/**
 * One field of a {@code form-types} entry — a faithful port of the Go
 * {@code DocSpecsFormField}.
 */
public final class DocSpecsFormField {
  public final String name;
  public final boolean required;
  /** The field description, {@code null} when absent. */
  public final String description;
  /** The field-value pattern check, {@code null} when none. */
  public final DocSpecsPatternCheck patternCheck;

  public DocSpecsFormField(
      String name, boolean required, String description, DocSpecsPatternCheck patternCheck) {
    this.name = name;
    this.required = required;
    this.description = description;
    this.patternCheck = patternCheck;
  }
}
