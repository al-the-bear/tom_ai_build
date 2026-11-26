package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** What {@link SpecBackfill#backfill} did. */
public final class SpecBackfillResult {
  /** The Blueprint written: the set's own, or its copy on a dry run. */
  public final SpecDocument blueprint;
  /** Every place written, in the order written. */
  public final List<SpecBackfillChange> changes;
  /** Every finding in scope it did not resolve, with the reason. */
  public final List<SpecBackfillLeft> left;

  public SpecBackfillResult(
      SpecDocument blueprint, List<SpecBackfillChange> changes, List<SpecBackfillLeft> left) {
    this.blueprint = blueprint;
    this.changes = Collections.unmodifiableList(new ArrayList<>(changes));
    this.left = Collections.unmodifiableList(new ArrayList<>(left));
  }

  /** The canonical JSON form (the Blueprint as its stores). */
  public Map<String, Object> toJson() {
    List<Object> cs = new ArrayList<>();
    for (SpecBackfillChange c : changes) {
      cs.add(c.toJson());
    }
    List<Object> ls = new ArrayList<>();
    for (SpecBackfillLeft l : left) {
      ls.add(l.toJson());
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("changes", cs);
    out.put("left", ls);
    out.put("blueprint", blueprint.toJson());
    return out;
  }
}
