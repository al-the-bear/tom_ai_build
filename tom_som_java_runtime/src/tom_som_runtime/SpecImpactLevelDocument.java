package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One document root in {@link SpecImpactLevel#documents}: whether the specification has it. */
public final class SpecImpactLevelDocument {
  public final String type;
  public final String sectionId;
  public final boolean present;

  public SpecImpactLevelDocument(String type, String sectionId, boolean present) {
    this.type = type;
    this.sectionId = sectionId;
    this.present = present;
  }

  public Map<String, Object> toJson() {
    Map<String, Object> o = new LinkedHashMap<>();
    o.put("type", type);
    o.put("sectionId", sectionId);
    o.put("present", Boolean.valueOf(present));
    return o;
  }
}
