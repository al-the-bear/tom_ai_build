package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** What {@link SpecReviewAnnotations#removeAllAnnotations} did with one conflict block (SOM §11.9.8). */
public final class SpecConflictOutcome {
  /** The conflict id, {@code X-<n>}. */
  public final String id;

  /** The value's path. */
  public final String path;

  /** The form field, or null for content. */
  public final String field;

  /** The 0-based line within the value where the block opened, before any change. */
  public final int line;

  /** The decision as written. */
  public final String decision;

  /** The text the decision chose. */
  public final String result;

  public SpecConflictOutcome(
      String id, String path, String field, int line, String decision, String result) {
    this.id = id;
    this.path = path;
    this.field = field;
    this.line = line;
    this.decision = decision;
    this.result = result;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("id", id);
    out.put("path", path);
    out.put("field", field);
    out.put("line", line);
    out.put("decision", decision);
    out.put("result", result);
    return out;
  }
}
