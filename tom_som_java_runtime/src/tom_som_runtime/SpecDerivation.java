package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * {@code @DerivedFrom} on a member, or the {@code derivedFrom:} qualifier of a
 * form field: the value is derived from other places
 * ({@code tom_specs_model_rules.md} §9.7).
 */
public final class SpecDerivation {
  /** {@code copy}, {@code rows} or {@code lookup} (the {@code DerivationKind} constant name). */
  public final String kind;
  /** For copy, the place copied; for rows / lookup, the rows read. */
  public final String source;
  /** For rows, which rows count (the {@link SpecPlaceFilter} grammar); {@code null} for all. */
  public final String where;
  /** For rows / lookup, the row places collected. */
  public final List<String> take;
  /** For rows / lookup, the row field compared with this element's {@link #by}; {@code null}. */
  public final String key;
  /** For rows / lookup, this element's field holding the key; {@code null} for none. */
  public final String by;
  /** For a list member, target element place ← row place, in the meta's order. */
  public final Map<String, String> map;
  /** The annotation's free-text note, {@code null} when it carries none. */
  public final String note;

  public SpecDerivation(
      String kind,
      String source,
      String where,
      List<String> take,
      String key,
      String by,
      Map<String, String> map,
      String note) {
    this.kind = kind;
    this.source = source;
    this.where = where;
    this.take = take;
    this.key = key;
    this.by = by;
    this.map = map;
    this.note = note;
  }

  static SpecDerivation from(LinkArguments a) {
    return new SpecDerivation(
        SpecAnnotations.stripEnumPrefix(a.str("kind", "copy")),
        a.str("source", ""),
        a.optString("where"),
        a.stringList("take"),
        a.optString("key"),
        a.optString("by"),
        a.stringMap("map"),
        a.optString("note"));
  }

  /** Reads the arguments of a {@code DerivedFrom} (annotation or qualifier). */
  public static SpecDerivation fromArguments(Map<String, Object> arguments) {
    return from(new LinkArguments(arguments));
  }

  /** The canonical JSON form, absent parts left out. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("kind", kind);
    out.put("source", source);
    if (where != null) {
      out.put("where", where);
    }
    out.put("take", LinkArguments.stringsJson(take));
    if (key != null) {
      out.put("key", key);
    }
    if (by != null) {
      out.put("by", by);
    }
    out.put("map", LinkArguments.stringMapJson(map));
    if (note != null) {
      out.put("note", note);
    }
    return out;
  }
}
