package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** A folder the caller passed for tests or code, and whether it exists ({@link SpecImpactLevel}). */
public final class SpecImpactFolder {
  public final String path;
  public final boolean present;

  public SpecImpactFolder(String path, boolean present) {
    this.path = path;
    this.present = present;
  }

  public Map<String, Object> toJson() {
    Map<String, Object> o = new LinkedHashMap<>();
    o.put("path", path);
    o.put("present", Boolean.valueOf(present));
    return o;
  }
}
