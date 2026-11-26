package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One place {@link SpecBackfill#backfill} wrote in the Blueprint. */
public final class SpecBackfillChange {
  /** {@link #kind}: a value written or cleared. */
  public static final String VALUE = "value";
  /** {@link #kind}: an element added. */
  public static final String ELEMENT_ADDED = "elementAdded";
  /** {@link #kind}: an element removed. */
  public static final String ELEMENT_REMOVED = "elementRemoved";
  /** {@link #kind}: the history entry. */
  public static final String REVISION = "revision";
  /** {@link #kind}: a derived place rewritten. */
  public static final String DERIVED = "derived";

  /** The pair the change belongs to; empty for the revision entry and the derived places written after it. */
  public final String pair;
  /** One of the kind constants. */
  public final String kind;
  /** The value's path, or the element's. */
  public final String path;
  /** The form field ({@code @headline} for a headline), {@code null} for content and elements. */
  public final String field;
  /** The value before (for an element, its id before). */
  public final String oldValue;
  /** The value after (for an element, its id after). */
  public final String newValue;

  public SpecBackfillChange(
      String pair, String kind, String path, String field, String oldValue, String newValue) {
    this.pair = pair;
    this.kind = kind;
    this.path = path;
    this.field = field;
    this.oldValue = oldValue;
    this.newValue = newValue;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("pair", pair);
    out.put("kind", kind);
    out.put("path", path);
    out.put("old", oldValue);
    out.put("new", newValue);
    if (field != null) {
      out.put("field", field);
    }
    return out;
  }
}
