package tom_som_runtime;

/**
 * What a finding of a {@link SpecDocumentSet} reports ({@code tom_specs_model_rules.md}
 * §9.7), in the order the report sorts by; the corpus compares {@link #value}.
 */
public enum SpecSyncCode {
  /** Both documents hold the shared place, and the values differ. */
  SHARED_VALUE_DIFFERS("sharedValueDiffers"),
  /** The Phase 3 document fills a shared place the Blueprint leaves empty. */
  SHARED_VALUE_MISSING("sharedValueMissing"),
  /**
   * The Blueprint fills a shared place the Phase 3 document leaves empty; the
   * Phase 3 document emptied it, so {@code backfill} clears it.
   */
  SHARED_VALUE_ONLY_IN_BLUEPRINT("sharedValueOnlyInBlueprint"),
  /** An element of an {@code equal} list (or an id of an {@code equal} reference field) is only in the Phase 3 document. */
  SHARED_ELEMENT_MISSING("sharedElementMissing"),
  /** An element (or id) is only in the Blueprint, under {@code equal} or {@code subset}; {@code backfill} removes it. */
  SHARED_ELEMENT_ONLY_IN_BLUEPRINT("sharedElementOnlyInBlueprint"),
  /**
   * Under {@code subset}, an element (or id) only in the Phase 3 document: it
   * may be added to the Blueprint, and is not carried in.
   */
  SHARED_ELEMENT_MAY_BE_ADDED("sharedElementMayBeAdded"),
  /** A {@code @SummaryOf(document:)} whose summary and detail sit in two documents does not hold. */
  CROSS_SUMMARY_MISMATCH("crossSummaryMismatch"),
  /** An {@code inverseOf} whose two ends sit in two documents is one-sided. */
  CROSS_INVERSE_MISSING("crossInverseMissing"),
  /** A value holding pending change marks, listed for the user. */
  PENDING_REVIEW("pendingReview"),
  /** A change {@code deriveFields} would write in a document under review that cannot be marked exactly. */
  UNMARKABLE("unmarkable");

  public final String value;

  SpecSyncCode(String value) {
    this.value = value;
  }

  /** The code whose {@link #value} is {@code value}, {@code null} when none is. */
  public static SpecSyncCode of(String value) {
    for (SpecSyncCode c : values()) {
      if (c.value.equals(value)) {
        return c;
      }
    }
    return null;
  }

  /** The position of {@code value} in the declaration order, -1 when it is no code. */
  public static int indexOf(String value) {
    SpecSyncCode c = of(value);
    return c == null ? -1 : c.ordinal();
  }
}
