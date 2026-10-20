package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** A value written as a marked change (SOM §11.9.3). */
public final class SpecMarkedChange {
  /** The value with every difference marked. */
  public final String text;

  /**
   * Whether accepting the marks gives exactly the new value and rejecting them exactly the old one.
   * False when a difference cannot be marked — a change inside fenced code, or text that holds mark
   * delimiters — and the new value was written unmarked instead.
   */
  public final boolean exact;

  /** Creates a result. */
  public SpecMarkedChange(String text, boolean exact) {
    this.text = text;
    this.exact = exact;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("text", text);
    out.put("exact", exact);
    return out;
  }
}
