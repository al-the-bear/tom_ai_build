package tom_som_runtime;

/**
 * A scalar list item — a bare string value held in the document's content store
 * at its own item {@code path}. Used as the element facade for non-complex
 * ({@code String}/scalar) lists.
 */
public final class SomScalar extends SomNode {
  public SomScalar(SpecDocument doc, String path) {
    super(doc, path);
  }

  /** The string value at this item's path ({@code ""} when unset). */
  public String getValue() {
    String v = doc.content(path);
    return v == null ? "" : v;
  }

  /** Sets the string value (an empty string clears it, per {@link SpecDocument}). */
  public void setValue(String v) {
    doc.setContent(path, v);
  }
}
