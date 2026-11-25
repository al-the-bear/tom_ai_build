package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * An edit a merge refuses (SOM §11.10). The codes are {@code sectionAdded},
 * {@code sectionRemoved}, {@code sectionMoved}, {@code listItems}, {@code
 * codeSpec}, {@code units}, {@code rejected}, {@code stale} and {@code strip}.
 */
public final class SpecStripMergeRefusal {
  public final String code;
  /** The path the refusal is about; empty for the whole document. */
  public final String path;

  public final String message;

  public SpecStripMergeRefusal(String code, String path, String message) {
    this.code = code;
    this.path = path;
    this.message = message;
  }

  /** {@code REFUSED <path> — <reason>}. */
  public String reportLine() {
    return "REFUSED " + (path.isEmpty() ? "(document)" : path) + " — " + message;
  }

  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("code", code);
    out.put("path", path);
    return out;
  }
}
