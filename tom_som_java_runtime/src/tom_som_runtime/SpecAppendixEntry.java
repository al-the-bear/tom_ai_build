package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One entry of a stripped rendition's appendix <em>Notes</em> (SOM §11.10). */
public final class SpecAppendixEntry {
  public final int number;
  public final String kind;
  public final String text;
  /** The value the entry was moved out of; {@code null} for the strip of one value. */
  public final SpecStripValueRef value;

  public SpecAppendixEntry(int number, String kind, String text) {
    this(number, kind, text, null);
  }

  public SpecAppendixEntry(int number, String kind, String text, SpecStripValueRef value) {
    this.number = number;
    this.kind = kind;
    this.text = text;
    this.value = value;
  }

  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("number", number);
    out.put("kind", kind);
    out.put("text", text);
    if (value != null) {
      out.put("value", value.toJson());
    }
    return out;
  }
}
