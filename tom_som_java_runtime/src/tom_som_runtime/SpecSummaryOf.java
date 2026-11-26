package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * {@code @SummaryOf} on a member, or the {@code summaryOf:} qualifier of a form
 * field: the annotated list or reference field summarises a detailed list
 * ({@code tom_specs_model_rules.md} §9.7).
 */
public final class SpecSummaryOf {
  /** The detailed list, {@code <LIST-ID>} (a {@code /} path where needed). */
  public final String detail;
  /** The root class name of the document holding {@link #detail}; {@code null}: this one. */
  public final String document;
  /**
   * The summary element's field naming its detail element; {@code null}: the
   * summary element carries the detail element's own section id.
   */
  public final String match;
  /** {@code equal}, {@code subset} (the default) or {@code superset}. */
  public final String relation;
  /** Summary place → detail place for every value the summary repeats, in the meta's order. */
  public final Map<String, String> repeats;
  /** The annotation's free-text note, {@code null} when it carries none. */
  public final String note;

  public SpecSummaryOf(
      String detail,
      String document,
      String match,
      String relation,
      Map<String, String> repeats,
      String note) {
    this.detail = detail;
    this.document = document;
    this.match = match;
    this.relation = relation;
    this.repeats = repeats;
    this.note = note;
  }

  static SpecSummaryOf from(LinkArguments a) {
    return new SpecSummaryOf(
        a.str("detail", ""),
        a.optString("document"),
        a.optString("match"),
        SpecAnnotations.stripEnumPrefix(a.str("relation", "subset")),
        a.stringMap("repeats"),
        a.optString("note"));
  }

  /** Reads the arguments of a {@code SummaryOf} (annotation or qualifier). */
  public static SpecSummaryOf fromArguments(Map<String, Object> arguments) {
    return from(new LinkArguments(arguments));
  }

  /** The canonical JSON form, absent parts left out. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("detail", detail);
    if (document != null) {
      out.put("document", document);
    }
    if (match != null) {
      out.put("match", match);
    }
    out.put("relation", relation);
    out.put("repeats", LinkArguments.stringMapJson(repeats));
    if (note != null) {
      out.put("note", note);
    }
    return out;
  }
}
