package tom_som_runtime;

/** One thing a Stage-A check found wrong. */
public final class CodeSpecsGateFinding {
  /** The check that found it. */
  public final CodeSpecsGateCheck check;

  /**
   * What kind of finding — the DocSpecs rule (A1), the validation code (A2),
   * {@code unrouted} / {@code root} (A3), {@code missingSource} /
   * {@code unresolvedReference} (A4), {@code missingCarrier} (A5).
   */
  public final String code;

  /**
   * Where: a section id or document path (A1–A4), or the carrier
   * {@code Class.member[.formField]} (A5).
   */
  public final String location;

  /** One sentence a user acts on. */
  public final String message;

  public CodeSpecsGateFinding(
      CodeSpecsGateCheck check, String code, String location, String message) {
    this.check = check;
    this.code = code;
    this.location = location;
    this.message = message;
  }

  @Override
  public String toString() {
    return check.label() + " " + code + " " + location + ": " + message;
  }
}
