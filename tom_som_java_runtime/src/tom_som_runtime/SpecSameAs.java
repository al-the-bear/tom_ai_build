package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * {@code @SameAs({holder, note})} on a section member: the member holds a copy of
 * the section the same document holds at another position, the holder
 * ({@code tom_specs_model_rules.md} §9.7). {@link SpecPlace#sameAsBindings}
 * finds the holder per document.
 */
public final class SpecSameAs {
  /**
   * The holder's section-id path, its last ids as far as needed
   * ({@code ACPLN/ACRITL}); {@code null}: the one other position of the class.
   */
  public final String holder;
  /** The annotation's free-text note, {@code null} when it carries none. */
  public final String note;

  public SpecSameAs(String holder, String note) {
    this.holder = holder;
    this.note = note;
  }

  /** Reads the copy out of a {@code @SameAs} annotation. */
  public static SpecSameAs fromAnnotation(SpecAnnotation annotation) {
    LinkArguments a = LinkArguments.of(annotation);
    return new SpecSameAs(a.optString("holder"), a.optString("note"));
  }

  /** The canonical JSON form, absent parts left out. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    if (holder != null) {
      out.put("holder", holder);
    }
    if (note != null) {
      out.put("note", note);
    }
    return out;
  }
}
