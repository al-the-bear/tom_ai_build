package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One finding of a {@link SpecDocumentSet} ({@link SpecDocumentSet#syncReport}). */
public final class SpecSyncFinding {
  /** What it reports. */
  public final SpecSyncCode code;
  /**
   * The pair's section id (the summary's or link's class for a cross check,
   * empty for a pending value outside every pair).
   */
  public final String pair;
  /** The Blueprint side (for a cross check, the side holding the link). */
  public final SpecSyncPlace blueprint;
  /** The Phase 3 side (for a cross check, the other end). */
  public final SpecSyncPlace detail;
  /** Which side holds the value. */
  public final SpecSyncHolder holder;
  /** How it is resolved. */
  public final SpecSyncResolution resolution;
  /**
   * Prose for the agent, in the canonical form: every runtime writes the same
   * sentence (the conformance corpus compares it).
   */
  public final String message;

  public SpecSyncFinding(
      SpecSyncCode code,
      String pair,
      SpecSyncPlace blueprint,
      SpecSyncPlace detail,
      SpecSyncHolder holder,
      SpecSyncResolution resolution,
      String message) {
    this.code = code;
    this.pair = pair;
    this.blueprint = blueprint;
    this.detail = detail;
    this.holder = holder;
    this.resolution = resolution;
    this.message = message;
  }

  /** Whether it is reported only, not a finding. */
  public boolean isInfo() {
    return resolution == SpecSyncResolution.INFO;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("code", code.value);
    out.put("pair", pair);
    out.put("blueprint", blueprint.toJson());
    out.put("detail", detail.toJson());
    out.put("holder", holder.value);
    out.put("resolution", resolution.value);
    out.put("message", message);
    out.put("info", isInfo());
    return out;
  }
}
