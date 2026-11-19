package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** The impact walk of one document root ({@link SpecImpactWalk#specImpactWalk}). */
public final class SpecImpactRootWalk {
  /** The root's model type, e.g. {@code D00SolutionBlueprint}. */
  public final String type;

  /** The root's section id (its first path segment). */
  public final String sectionId;

  /** Whether the specification has this document; an absent root is walked over an empty document. */
  public final boolean present;

  public final List<SpecImpactRow> rows;

  public SpecImpactRootWalk(String type, String sectionId, boolean present, List<SpecImpactRow> rows) {
    this.type = type;
    this.sectionId = sectionId;
    this.present = present;
    this.rows = Collections.unmodifiableList(new ArrayList<>(rows));
  }

  /** The walk as JSON, keys as in every runtime. */
  public Map<String, Object> toJson() {
    Map<String, Object> o = new LinkedHashMap<>();
    o.put("type", type);
    o.put("sectionId", sectionId);
    o.put("present", Boolean.valueOf(present));
    List<Object> list = new ArrayList<>();
    for (SpecImpactRow r : rows) {
      list.add(r.toJson());
    }
    o.put("rows", list);
    return o;
  }
}
