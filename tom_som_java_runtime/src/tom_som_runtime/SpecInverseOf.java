package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * The {@code inverseOf:} qualifier of a reference form field: the other ends of
 * the link ({@code tom_specs_model_rules.md} §9.7).
 */
public final class SpecInverseOf {
  /** The other ends, {@code <FORMSECTIONID>.<field>}; {@code ["@self"]} for the symmetric form. */
  public final List<String> fields;
  /** Only values (or rows) matching this filter have an inverse; {@code null} for all. */
  public final String where;

  public SpecInverseOf(List<String> fields, String where) {
    this.fields = fields;
    this.where = where;
  }

  static SpecInverseOf from(LinkArguments a) {
    return new SpecInverseOf(a.stringList("fields"), a.optString("where"));
  }

  /** Reads the {@code inverseOf} key of a {@code formFields[]} entry. */
  public static SpecInverseOf fromArguments(Map<String, Object> arguments) {
    return from(new LinkArguments(arguments));
  }

  /** Whether the link is stored on both entries in the same field ({@code InverseOf.symmetric}). */
  public boolean symmetric() {
    return fields.size() == 1 && "@self".equals(fields.get(0));
  }

  /** The canonical JSON form, an absent {@code where} left out. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("fields", LinkArguments.stringsJson(fields));
    if (where != null) {
      out.put("where", where);
    }
    return out;
  }
}
