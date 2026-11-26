package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * The relation of the elements of a list on two sides of a link, as the
 * annotated side reads it ({@code ListRelation}, {@code tom_specs_model_rules.md}
 * §9.7).
 */
public final class SpecListRelation {
  /** The list or multi-valued reference field the relation is about. */
  public final String place;
  /** {@code equal}, {@code subset} or {@code superset} (the {@code LinkRelation} constant name). */
  public final String relation;
  /**
   * The filter selecting the elements the relation applies to (the
   * {@link SpecPlaceFilter} grammar), {@code null} for all of them.
   */
  public final String where;

  public SpecListRelation(String place, String relation, String where) {
    this.place = place;
    this.relation = relation;
    this.where = where;
  }

  static SpecListRelation from(LinkArguments a) {
    return new SpecListRelation(
        a.str("place", ""),
        SpecAnnotations.stripEnumPrefix(a.str("relation", "equal")),
        a.optString("where"));
  }

  /** The canonical JSON form, an absent {@code where} left out. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("place", place);
    out.put("relation", relation);
    if (where != null) {
      out.put("where", where);
    }
    return out;
  }
}
