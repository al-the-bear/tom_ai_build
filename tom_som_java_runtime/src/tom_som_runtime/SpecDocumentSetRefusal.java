package tom_som_runtime;

/** Why a {@link SpecDocumentSet} cannot be built; the corpus compares {@link #value}. */
public enum SpecDocumentSetRefusal {
  /** Two documents populate one root. */
  SAME_ROOT("sameRoot"),
  /** A document populates no root. */
  NO_ROOT("noRoot"),
  /** A document populates two roots. */
  TWO_ROOTS("twoRoots"),
  /** A document is the CodeSpecs projection, which is no specification. */
  PROJECTION("projection"),
  /** Fragments of one root overlap. */
  OVERLAP("overlap"),
  /**
   * A synced class's positions in the Blueprint and its document cannot be
   * paired (invariant {@code SHARED-ANCHOR}).
   */
  UNPAIRABLE("unpairable");

  public final String value;

  SpecDocumentSetRefusal(String value) {
    this.value = value;
  }
}
