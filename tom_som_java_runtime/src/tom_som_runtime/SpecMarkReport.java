package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** The report of an inline-mark operation, for the decision log. */
public final class SpecMarkReport {
  /** What was done, in document order. */
  public final List<SpecMarkOutcome> applied;

  /** Malformed marks in scope, left as written. */
  public final List<SpecMarkIssue> malformed;

  /**
   * The conflicts {@link SpecReviewAnnotations#removeAllAnnotations} applied, in document order
   * (SOM §11.9.8); null for the mark operations, which do not touch conflicts.
   */
  public final List<SpecConflictOutcome> conflicts;

  public SpecMarkReport(List<SpecMarkOutcome> applied, List<SpecMarkIssue> malformed) {
    this(applied, malformed, null);
  }

  public SpecMarkReport(
      List<SpecMarkOutcome> applied,
      List<SpecMarkIssue> malformed,
      List<SpecConflictOutcome> conflicts) {
    this.applied = Collections.unmodifiableList(new ArrayList<>(applied));
    this.malformed = Collections.unmodifiableList(new ArrayList<>(malformed));
    this.conflicts =
        conflicts == null ? null : Collections.unmodifiableList(new ArrayList<>(conflicts));
  }

  /** The canonical JSON form of the older case files. */
  public Map<String, Object> toJson() {
    return toJson(false);
  }

  /**
   * The canonical JSON form; {@code team} adds the applied {@code conflicts} of a removal, the
   * form {@code team_annotation_cases.json} pins (SOM §11.9.8).
   */
  public Map<String, Object> toJson(boolean team) {
    List<Object> a = new ArrayList<>();
    for (SpecMarkOutcome o : applied) {
      a.add(o.toJson());
    }
    List<Object> m = new ArrayList<>();
    for (SpecMarkIssue i : malformed) {
      m.add(i.toJson());
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("applied", a);
    out.put("malformed", m);
    if (team && conflicts != null) {
      List<Object> c = new ArrayList<>();
      for (SpecConflictOutcome o : conflicts) {
        c.add(o.toJson());
      }
      out.put("conflicts", c);
    }
    return out;
  }
}
