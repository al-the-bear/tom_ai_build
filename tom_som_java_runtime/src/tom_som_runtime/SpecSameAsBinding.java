package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** A {@code @SameAs} copy at one position of a document root, with its holder. */
public final class SpecSameAsBinding {
  /** The root the positions are in. */
  public final String root;
  /** The class both positions hold. */
  public final String className;
  /** The copy's document path (list items written {@code <list>-*}). */
  public final String copyPath;
  /** The copy's section-id path from the root. */
  public final List<String> copySectionIds;
  /** The holder's document path, {@code null} when {@link #problem} is set. */
  public final String holderPath;
  /** The holder's section-id path from the root, {@code null} when {@link #problem} is set. */
  public final List<String> holderSectionIds;
  /**
   * Why no single holder was found: {@link SpecPlaceProblem#UNRESOLVED} (no
   * position fits) or {@link SpecPlaceProblem#AMBIGUOUS} (several do);
   * {@code null} when {@link #holderPath} is set.
   */
  public final SpecPlaceProblem problem;

  public SpecSameAsBinding(
      String root,
      String className,
      String copyPath,
      List<String> copySectionIds,
      String holderPath,
      List<String> holderSectionIds,
      SpecPlaceProblem problem) {
    this.root = root;
    this.className = className;
    this.copyPath = copyPath;
    this.copySectionIds = copySectionIds;
    this.holderPath = holderPath;
    this.holderSectionIds = holderSectionIds;
    this.problem = problem;
  }

  /** The canonical JSON form the corpus compares. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("root", root);
    out.put("className", className);
    out.put("copy", copyPath);
    if (holderPath != null) {
      out.put("holder", holderPath);
    }
    if (problem != null) {
      out.put("problem", problem.value);
    }
    return out;
  }
}
