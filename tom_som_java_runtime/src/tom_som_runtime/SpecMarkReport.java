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

  public SpecMarkReport(List<SpecMarkOutcome> applied, List<SpecMarkIssue> malformed) {
    this.applied = Collections.unmodifiableList(new ArrayList<>(applied));
    this.malformed = Collections.unmodifiableList(new ArrayList<>(malformed));
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
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
    return out;
  }
}
