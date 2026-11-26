package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One value {@link SpecDocumentSet#renameId} changed. */
public final class SpecRenameChange {
  /** {@link #kind} of a list item's section id. */
  public static final String SECTION_ID = "sectionId";
  /** {@link #kind} of a form field or content value. */
  public static final String VALUE = "value";

  /** The document's name. */
  public final String document;
  /** A list item (its section id) or the value's path. */
  public final String path;
  /** {@link #SECTION_ID} or {@link #VALUE}. */
  public final String kind;
  /** The value before. */
  public final String oldValue;
  /** The value after. */
  public final String newValue;
  /** The form field, {@code null} for none. */
  public final String field;

  public SpecRenameChange(
      String document, String path, String kind, String oldValue, String newValue, String field) {
    this.document = document;
    this.path = path;
    this.kind = kind;
    this.oldValue = oldValue;
    this.newValue = newValue;
    this.field = field;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("document", document);
    out.put("path", path);
    out.put("kind", kind);
    out.put("old", oldValue);
    out.put("new", newValue);
    if (field != null) {
      out.put("field", field);
    }
    return out;
  }
}
