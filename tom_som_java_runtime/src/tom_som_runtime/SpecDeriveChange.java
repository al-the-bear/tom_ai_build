package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One place {@link SpecDeriveFields#deriveFields} wrote. */
public final class SpecDeriveChange {
  /** {@link #kind}: a value written. */
  public static final String VALUE = "value";
  /** {@link #kind}: a row added. */
  public static final String ROW_ADDED = "rowAdded";
  /** {@link #kind}: a row removed (under review: every value of it proposed for deletion). */
  public static final String ROW_REMOVED = "rowRemoved";

  /**
   * The step that wrote it: 1 (link ends and rows), 2 (derived values, repeats,
   * {@code @SameAs} copies), 3 (counts, products, ranks).
   */
  public final int step;
  /** {@link #VALUE}, {@link #ROW_ADDED} or {@link #ROW_REMOVED}. */
  public final String kind;
  /** The value's path, or the row's. */
  public final String path;
  /** The form field ({@code @headline} for a headline), {@code null} for content and rows. */
  public final String field;
  /** The value before (for a row, empty). */
  public final String oldValue;
  /** The value after (for a row, empty). */
  public final String newValue;

  public SpecDeriveChange(
      int step, String kind, String path, String field, String oldValue, String newValue) {
    this.step = step;
    this.kind = kind;
    this.path = path;
    this.field = field;
    this.oldValue = oldValue;
    this.newValue = newValue;
  }

  /** A row change ({@link #ROW_ADDED} / {@link #ROW_REMOVED}). */
  static SpecDeriveChange row(int step, String kind, String path) {
    return new SpecDeriveChange(step, kind, path, null, "", "");
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("step", step);
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
