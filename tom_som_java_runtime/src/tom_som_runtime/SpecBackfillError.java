package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Why {@link SpecBackfill#backfill} refuses a set. */
public final class SpecBackfillError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  /** {@link #code}: a document holds an inline mark or an annotation block. */
  public static final String SET_HAS_MARKS = "setHasMarks";
  /** {@link #code}: the set has no Blueprint. */
  public static final String NO_BLUEPRINT = "noBlueprint";

  /** {@link #SET_HAS_MARKS} or {@link #NO_BLUEPRINT}. */
  public final String code;
  /** The places holding marks, in document order. */
  public final transient List<SpecSyncPlace> places;

  public SpecBackfillError(String code, List<SpecSyncPlace> places, String message) {
    super(message);
    this.code = code;
    this.places = Collections.unmodifiableList(new ArrayList<>(places));
  }

  /** The canonical JSON form (no message). */
  public Map<String, Object> toJson() {
    List<Object> ps = new ArrayList<>();
    for (SpecSyncPlace p : places) {
      ps.add(p.toJson());
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("code", code);
    out.put("places", ps);
    return out;
  }

  @Override
  public String toString() {
    return "SpecBackfillError(" + code + "): " + getMessage();
  }
}
