package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One side of a {@link SpecSyncFinding}: where the place is and what it holds. */
public final class SpecSyncPlace {
  /** The document's name, {@code null} when the set has none for this side. */
  public final String document;
  /** The root's section id ({@code ""} with no document). */
  public final String root;
  /**
   * The document path (for a place the document does not hold, the nearest path
   * it does: the list an element would be added to).
   */
  public final String path;
  /** The form field ({@code @headline} for a headline), {@code null} for none. */
  public final String field;
  /** The value (read with pending marks rejected), {@code null} when absent. */
  public final String value;
  /** Whether the value holds pending change marks. */
  public final boolean pendingMarks;

  public SpecSyncPlace(
      String document, String root, String path, String field, String value, boolean pendingMarks) {
    this.document = document;
    this.root = root;
    this.path = path;
    this.field = field;
    this.value = value;
    this.pendingMarks = pendingMarks;
  }

  /** The value, {@code ""} when absent. */
  public String valueOr() {
    return value == null ? "" : value;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("document", document);
    out.put("root", root);
    out.put("path", path);
    if (field != null) {
      out.put("field", field);
    }
    if (value != null) {
      out.put("value", value);
    }
    out.put("pendingMarks", pendingMarks);
    return out;
  }
}
