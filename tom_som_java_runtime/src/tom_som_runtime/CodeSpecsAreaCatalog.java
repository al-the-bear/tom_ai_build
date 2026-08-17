package tom_som_runtime;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Deque;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * The machine-readable form of {@code codespecs_mapping.md} §4.1 + §4.4.3 +
 * §4.4.6.
 *
 * <p>Authored once, read by all nine runtimes. It is an input rather than a
 * baked table because the catalogue is the mapping document's content: a copy
 * per runtime would be nine things to keep current, and the one thing this quest
 * has learned three times is that a vocabulary duplicated nine ways can be wrong
 * in agreement.
 */
public final class CodeSpecsAreaCatalog {
  /** Where the catalogue was transcribed from, for the extract header. */
  public final String source;

  /** The §4.4.3 slices, in emission order. */
  public final List<CodeSpecsSlice> slices;

  /**
   * The §4.1 areas, in catalogue order. Catalogue order is the tie-break §4.4.6
   * rule 2 uses, so it is load-bearing rather than cosmetic.
   */
  public final List<CodeSpecsArea> areas;

  public CodeSpecsAreaCatalog(
      String source, List<CodeSpecsSlice> slices, List<CodeSpecsArea> areas) {
    this.source = source;
    this.slices = slices;
    this.areas = areas;
  }

  @SuppressWarnings("unchecked")
  public static CodeSpecsAreaCatalog fromJson(Map<String, Object> j) {
    List<CodeSpecsSlice> slices = new ArrayList<>();
    Object rawSlices = j.get("slices");
    if (rawSlices instanceof List) {
      for (Object e : (List<Object>) rawSlices) {
        slices.add(CodeSpecsSlice.fromJson((Map<String, Object>) e));
      }
    }
    List<CodeSpecsArea> areas = new ArrayList<>();
    Object rawAreas = j.get("areas");
    if (rawAreas instanceof List) {
      for (Object e : (List<Object>) rawAreas) {
        areas.add(CodeSpecsArea.fromJson((Map<String, Object>) e));
      }
    }
    return new CodeSpecsAreaCatalog(
        stringOr(j.get("source")),
        Collections.unmodifiableList(slices),
        Collections.unmodifiableList(areas));
  }

  /** The active areas, in catalogue order — one extract each. */
  public List<CodeSpecsArea> activeAreas() {
    List<CodeSpecsArea> out = new ArrayList<>();
    for (CodeSpecsArea a : areas) {
      if (a.active) {
        out.add(a);
      }
    }
    return out;
  }

  /** The area with this {@code CE-*} code, or {@code null}. */
  public CodeSpecsArea byCode(String code) {
    for (CodeSpecsArea a : areas) {
      if (a.code.equals(code)) {
        return a;
      }
    }
    return null;
  }

  /**
   * The area a {@code @CodeSpecKind} value names, or {@code null}. Accepts both
   * the bare value ({@code form}) and the qualified one
   * ({@code CodeSpecPart.form}), because the meta carries the qualified spelling
   * and callers reach for the bare one.
   */
  public CodeSpecsArea byPart(String value) {
    String prefix = "CodeSpecPart.";
    String bare = value.startsWith(prefix) ? value.substring(prefix.length()) : value;
    for (CodeSpecsArea a : areas) {
      if (a.part.equals(bare)) {
        return a;
      }
    }
    return null;
  }

  /** The slice numbered {@code number}, or {@code null}. */
  public CodeSpecsSlice sliceNumbered(int number) {
    for (CodeSpecsSlice s : slices) {
      if (s.number == number) {
        return s;
      }
    }
    return null;
  }

  /**
   * The §4.2 projects {@code area}'s code lands in, in slice order.
   *
   * <p>Derived from the area's slices rather than authored on the area: §4.4.3
   * already fixes one project per slice, so a per-area project column would be a
   * second place for the same fact to be stated — and the areas that would need
   * it are exactly the locus-split ones, where getting it wrong is easiest.
   */
  public List<String> projectsFor(CodeSpecsArea area) {
    List<String> out = new ArrayList<>();
    for (Integer n : area.slices) {
      CodeSpecsSlice slice = sliceNumbered(n);
      String project = slice == null ? null : slice.project;
      if (project == null || project.isEmpty() || out.contains(project)) {
        continue;
      }
      out.add(project);
    }
    return out;
  }

  /**
   * The area codes {@code area} may cite — every other active area whose emission
   * units sit in a slice {@code area}'s slices reach, following §4.4.3's edges
   * transitively. Within-slice citation is legal, so an area's own slices are
   * part of the reachable set; the area itself is excluded.
   *
   * <p>Derived rather than authored: a hand-kept per-area citation list is a
   * second source of truth for something the slice graph already decides.
   */
  public List<String> citableAreaCodes(CodeSpecsArea area) {
    Set<Integer> reachable = new LinkedHashSet<>();
    Deque<Integer> stack = new ArrayDeque<>(area.slices);
    while (!stack.isEmpty()) {
      Integer n = stack.removeLast();
      if (!reachable.add(n)) {
        continue;
      }
      CodeSpecsSlice slice = sliceNumbered(n);
      if (slice == null) {
        continue;
      }
      stack.addAll(slice.cites);
    }
    List<String> out = new ArrayList<>();
    for (CodeSpecsArea a : areas) {
      if (!a.active || a.code.equals(area.code)) {
        continue;
      }
      for (Integer s : a.slices) {
        if (reachable.contains(s)) {
          out.add(a.code);
          break;
        }
      }
    }
    return out;
  }

  // --- shared JSON coercion -------------------------------------------------
  //
  // The catalogue is this module's only JSON door, so the coercions its three
  // value types share are stated here rather than repeated per type.

  /** A JSON string, or {@code ""} when the key is absent. */
  static String stringOr(Object raw) {
    return raw == null ? "" : raw.toString();
  }

  @SuppressWarnings("unchecked")
  static List<String> stringList(Object raw) {
    List<String> out = new ArrayList<>();
    if (raw instanceof List) {
      for (Object e : (List<Object>) raw) {
        out.add(e == null ? "" : e.toString());
      }
    }
    return Collections.unmodifiableList(out);
  }

  @SuppressWarnings("unchecked")
  static List<Integer> intList(Object raw) {
    List<Integer> out = new ArrayList<>();
    if (raw instanceof List) {
      for (Object e : (List<Object>) raw) {
        out.add(e instanceof Number ? ((Number) e).intValue() : 0);
      }
    }
    return Collections.unmodifiableList(out);
  }
}
