package tom_som_runtime;

import java.util.List;
import java.util.Map;

/** One emission slice of {@code codespecs_mapping.md} §4.4.3. */
public final class CodeSpecsSlice {
  /** The slice's number, 1–7. */
  public final int number;

  /** The slice's name as §4.4.3 gives it. */
  public final String title;

  /** The §4.2 project the slice emits into. */
  public final String project;

  /**
   * The slices this one may cite — §4.4.3's across-slice edges. Transitively
   * closed by {@link CodeSpecsAreaCatalog#citableAreaCodes}.
   */
  public final List<Integer> cites;

  public CodeSpecsSlice(int number, String title, String project, List<Integer> cites) {
    this.number = number;
    this.title = title;
    this.project = project;
    this.cites = cites;
  }

  public static CodeSpecsSlice fromJson(Map<String, Object> j) {
    Object number = j.get("number");
    return new CodeSpecsSlice(
        number instanceof Number ? ((Number) number).intValue() : 0,
        CodeSpecsAreaCatalog.stringOr(j.get("title")),
        CodeSpecsAreaCatalog.stringOr(j.get("project")),
        CodeSpecsAreaCatalog.intList(j.get("cites")));
  }
}
