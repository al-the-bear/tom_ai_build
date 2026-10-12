package tom_som_runtime;

import java.util.Map;

/**
 * One A5 carrier ({@code codespecs_prompt.md} §4.5): a structured field the
 * model must keep offering.
 */
public final class CodeSpecsCarrier {
  /** The field. */
  public final CodeSpecsFieldRef field;

  /** The document section that introduced it, for the finding. */
  public final String introducedBy;

  public CodeSpecsCarrier(CodeSpecsFieldRef field, String introducedBy) {
    this.field = field;
    this.introducedBy = introducedBy == null ? "" : introducedBy;
  }

  public CodeSpecsCarrier(CodeSpecsFieldRef field) {
    this(field, "");
  }

  /** Reads one row of the catalogue's {@code gate.carriers}. */
  public static CodeSpecsCarrier fromJson(Map<String, Object> j) {
    return new CodeSpecsCarrier(
        CodeSpecsFieldRef.fromJson(j), CodeSpecsAreaCatalog.stringOr(j.get("introducedBy")));
  }

  /** The carrier's class. */
  public String className() {
    return field.className;
  }

  /** The carrier's member. */
  public String member() {
    return field.member;
  }

  /** The carrier's form field. */
  public String formField() {
    return field.formField;
  }

  /** The carrier, as findings name it. */
  public String source() {
    return field.source();
  }
}
