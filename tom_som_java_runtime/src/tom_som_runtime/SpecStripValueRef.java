package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** A value of a document (SOM §11.10): its content, a form field or its headline. */
public final class SpecStripValueRef {
  /** The document path of the value. */
  public final String path;
  /** The form field, or {@code null} for content or a headline. */
  public final String field;
  /** Whether the value is the stored headline at {@link #path}. */
  public final boolean headline;

  /** The content at {@code path}. */
  public SpecStripValueRef(String path) {
    this(path, null, false);
  }

  /** The form field {@code field} at {@code path}. */
  public SpecStripValueRef(String path, String field) {
    this(path, field, false);
  }

  public SpecStripValueRef(String path, String field, boolean headline) {
    this.path = path;
    this.field = field;
    this.headline = headline;
  }

  /** The value in {@code doc}; the empty string when it holds none. */
  public String read(SpecDocument doc) {
    String v =
        headline
            ? doc.headline(path)
            : field != null ? doc.formField(path, field) : doc.content(path);
    return v == null ? "" : v;
  }

  /** Writes {@code value} to the place in {@code doc}. */
  public void write(SpecDocument doc, String value) {
    if (headline) {
      doc.setHeadline(path, value);
    } else if (field != null) {
      doc.setFormField(path, field, value);
    } else {
      doc.setContent(path, value);
    }
  }

  /** The place as a report names it. */
  public String label() {
    return headline ? path + " (headline)" : field != null ? path + "/" + field : path;
  }

  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("path", path);
    if (field != null) {
      out.put("field", field);
    }
    if (headline) {
      out.put("headline", true);
    }
    return out;
  }

  @Override
  public String toString() {
    return label();
  }
}
