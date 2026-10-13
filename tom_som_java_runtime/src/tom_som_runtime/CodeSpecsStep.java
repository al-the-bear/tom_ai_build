package tom_som_runtime;

import java.util.List;
import java.util.Map;

/**
 * One row of the {@code codespecs_mapping.md} §4.4.6 authoring-step table — the
 * unit Phase 4 is authored in, one {@code csgen} todo each.
 *
 * <p>The catalogue carries the table so a consumer planning Phase 4 step by step
 * reads it as data rather than parsing the mapping document's Markdown.
 */
public final class CodeSpecsStep {
  /**
   * The step's number, 1–31. The table is written in authoring order, so the
   * number is also the step's position in that order.
   */
  public final int number;

  /** The "Authoring step (emission unit)" cell, verbatim — Markdown included. */
  public final String title;

  /** The §4.4.3 slice the step's code is emitted in. */
  public final int slice;

  /**
   * The "Placed by" cell, verbatim: the catalogue position or edge that puts the
   * step where it is.
   */
  public final String placedBy;

  /**
   * The {@code CE-*} codes of the areas the step authors, in catalogue order —
   * the inverse of {@link CodeSpecsArea#authoringSteps}.
   */
  public final List<String> areaCodes;

  public CodeSpecsStep(
      int number, String title, int slice, String placedBy, List<String> areaCodes) {
    this.number = number;
    this.title = title;
    this.slice = slice;
    this.placedBy = placedBy;
    this.areaCodes = areaCodes;
  }

  /**
   * Reads one step. {@code number} and {@code slice} are required — a step with
   * no number cannot be placed, and one with no slice does not say which project
   * it lands in — so either one absent or non-numeric throws an
   * {@link IllegalArgumentException} naming the row by its {@code title} or
   * {@code placedBy}. The text cells fall back to empty.
   */
  public static CodeSpecsStep fromJson(Map<String, Object> j) {
    String label = CodeSpecsFieldRef.rowLabel(j, new String[] {"title", "placedBy"});
    return new CodeSpecsStep(
        CodeSpecsFieldRef.requiredInt(j, "number", label),
        CodeSpecsAreaCatalog.stringOr(j.get("title")),
        CodeSpecsFieldRef.requiredInt(j, "slice", label),
        CodeSpecsAreaCatalog.stringOr(j.get("placedBy")),
        CodeSpecsAreaCatalog.stringList(j.get("areaCodes")));
  }
}
