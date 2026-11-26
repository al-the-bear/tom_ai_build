package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** A finding {@link SpecBackfill#backfill} left, with the reason. */
public final class SpecBackfillLeft {
  /** {@link #reason}: the Blueprint holds the value: the agent corrects the Phase 3 document. */
  public static final String HELD_HERE = "heldHere";
  /** {@link #reason}: under {@code subset}, not carried in. */
  public static final String MAY_BE_ADDED = "mayBeAdded";

  public final SpecSyncFinding finding;
  /** {@link #HELD_HERE}, {@link #MAY_BE_ADDED}, or the finding's resolution ({@code agent}, {@code info}). */
  public final String reason;

  public SpecBackfillLeft(SpecSyncFinding finding, String reason) {
    this.finding = finding;
    this.reason = reason;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("finding", finding.toJson());
    out.put("reason", reason);
    return out;
  }
}
