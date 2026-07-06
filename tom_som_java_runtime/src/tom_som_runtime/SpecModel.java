package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * The complete exported model — a <i>class graph</i>, not an expanded tree: each
 * class appears once and field {@code elementType}/{@code type} references are
 * followed on demand by a traversal.
 */
public final class SpecModel {
  public final List<SpecRoot> roots;
  public final Map<String, SpecClass> classes;
  public final int modelVersion;
  public final String modelVersionLabel;

  public SpecModel(
      List<SpecRoot> roots,
      Map<String, SpecClass> classes,
      int modelVersion,
      String modelVersionLabel) {
    this.roots = roots;
    this.classes = classes;
    this.modelVersion = modelVersion;
    this.modelVersionLabel = modelVersionLabel;
  }

  public SpecClass classNamed(String name) {
    if (name == null) {
      return null;
    }
    return classes.get(name);
  }

  /**
   * The document root whose {@link SpecRoot#type} equals {@code type} (SOM
   * § item 12).
   *
   * <p>Replaces the recurring {@code roots.firstWhere((r) => r.type == …)}
   * boilerplate. Throws {@link IllegalArgumentException} when no root carries
   * that type — with a message that names the missing type and the ones that do
   * exist.
   */
  public SpecRoot rootByType(String type) {
    for (SpecRoot r : roots) {
      if (r.type.equals(type)) {
        return r;
      }
    }
    List<String> available = new ArrayList<>();
    for (SpecRoot r : roots) {
      available.add(r.type);
    }
    throw new IllegalArgumentException(
        "no document root with type \"" + type + "\" (have: "
            + String.join(", ", available) + ")");
  }

  @SuppressWarnings("unchecked")
  public static SpecModel fromJson(Map<String, Object> j) {
    Map<String, SpecClass> classes = new LinkedHashMap<>();
    Object rawClasses = j.get("classes");
    if (rawClasses instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawClasses).entrySet()) {
        classes.put(e.getKey(), SpecClass.fromJson((Map<String, Object>) e.getValue()));
      }
    }
    List<SpecRoot> roots = new ArrayList<>();
    Object rawRoots = j.get("roots");
    if (rawRoots instanceof List) {
      for (Object e : (List<Object>) rawRoots) {
        roots.add(SpecRoot.fromJson((Map<String, Object>) e));
      }
    }
    Object version = j.get("modelVersion");
    Object label = j.get("modelVersionLabel");
    String labelStr = (label == null || label.toString().isEmpty()) ? null : label.toString();
    return new SpecModel(
        roots,
        classes,
        version instanceof Number ? ((Number) version).intValue() : 0,
        labelStr);
  }
}
