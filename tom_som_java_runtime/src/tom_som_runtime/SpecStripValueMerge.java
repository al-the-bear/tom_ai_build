package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** The result of {@link SpecStripMerge#mergeStrippedValue} (SOM §11.10). */
public final class SpecStripValueMerge {
  /** The merged value; {@code null} when there are conflicts. */
  public final String text;
  /** How many pieces were put back. */
  public final int restored;
  /** The pieces put back after an edited run, for an author to check. */
  public final List<SpecStripMergePlaced> placed;

  public final List<SpecStripMergeConflict> conflicts;

  public SpecStripValueMerge(
      String text,
      int restored,
      List<SpecStripMergePlaced> placed,
      List<SpecStripMergeConflict> conflicts) {
    this.text = text;
    this.restored = restored;
    this.placed = placed;
    this.conflicts = conflicts;
  }

  /** Whether the value merged. */
  public boolean ok() {
    return conflicts.isEmpty();
  }

  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("text", text);
    out.put("restored", restored);
    List<Object> p = new ArrayList<>();
    for (SpecStripMergePlaced x : placed) {
      p.add(x.toJson());
    }
    out.put("placed", p);
    List<Object> c = new ArrayList<>();
    for (SpecStripMergeConflict x : conflicts) {
      c.add(x.toJson());
    }
    out.put("conflicts", c);
    return out;
  }
}
