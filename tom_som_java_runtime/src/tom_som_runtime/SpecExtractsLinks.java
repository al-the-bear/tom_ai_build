package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * {@code @ExtractsLinks} on a list of link rows: ids named in text get rows
 * ({@code tom_specs_model_rules.md} §9.7). A member may carry it more than once.
 */
public final class SpecExtractsLinks {
  /** The text places searched for ids. */
  public final List<String> from;
  /** The row's {@code refersTo} field receiving a found id. */
  public final String ref;
  /** The values every generated row gets, in the meta's order. */
  public final Map<String, String> set;
  /** {@code generate} (the default) or {@code warn} (the {@code ExtractMode} constant name). */
  public final String mode;
  /** The annotation's free-text note, {@code null} when it carries none. */
  public final String note;

  public SpecExtractsLinks(
      List<String> from, String ref, Map<String, String> set, String mode, String note) {
    this.from = from;
    this.ref = ref;
    this.set = set;
    this.mode = mode;
    this.note = note;
  }

  /** Reads one {@code ExtractsLinks} annotation. */
  public static SpecExtractsLinks fromAnnotation(SpecAnnotation annotation) {
    LinkArguments a = LinkArguments.of(annotation);
    return new SpecExtractsLinks(
        a.stringList("from"),
        a.str("ref", ""),
        a.stringMap("set"),
        SpecAnnotations.stripEnumPrefix(a.str("mode", "generate")),
        a.optString("note"));
  }

  /** The canonical JSON form, an absent note left out. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("from", LinkArguments.stringsJson(from));
    out.put("ref", ref);
    out.put("set", LinkArguments.stringMapJson(set));
    out.put("mode", mode);
    if (note != null) {
      out.put("note", note);
    }
    return out;
  }
}
