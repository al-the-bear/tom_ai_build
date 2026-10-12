package tom_som_runtime;

/** The five Stage-A checks of {@code codespecs_prompt.md} §4. */
public enum CodeSpecsGateCheck {
  /** The document is complete against its DocSpecs schema. */
  A1,

  /** The document's values are valid ({@code validateDocument}). */
  A2,

  /** Every section the walk reaches carries a routing verdict (ROUTE-TOTAL). */
  A3,

  /** Every required marker argument of a used area has a populated source. */
  A4,

  /** The model still offers every structured carrier. */
  A5;

  /** {@code A1} … {@code A5}, as {@code codespecs_prompt.md} §4 names them. */
  public String label() {
    return name();
  }
}
