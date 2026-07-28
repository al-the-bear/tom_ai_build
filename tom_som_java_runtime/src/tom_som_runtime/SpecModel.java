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

  /**
   * The {@code major.minor} version string used in the DocSpecs markdown
   * declaration (Dart / Python parity — mirrors Python's
   * {@code SpecModel.model_version_string}).
   */
  public String modelVersionString() {
    return somModelVersionString(modelVersion, modelVersionLabel);
  }

  /**
   * Derives the {@code major.minor} DocSpecs version string from a model's
   * integer version and its optional free-form label (port of Python's
   * {@code som_model_version_string}).
   *
   * <p>When the label's {@code +}-stripped core has at least two dot-separated
   * integer components, those become {@code major.minor}; otherwise the result
   * is {@code <major>.0}.
   */
  public static String somModelVersionString(int major, String label) {
    if (label != null && !label.isEmpty()) {
      String core = label.split("\\+", 2)[0].trim();
      String[] parts = core.split("\\.", -1);
      if (parts.length >= 2) {
        String maj = parts[0].trim();
        String minor = parts[1].trim();
        if (isSignedDigits(maj) && isSignedDigits(minor)) {
          return Integer.parseInt(maj) + "." + Integer.parseInt(minor);
        }
      }
    }
    return major + ".0";
  }

  /** Whether {@code s} matches {@code /^[+-]?[0-9]+$/}. */
  private static boolean isSignedDigits(String s) {
    if (s.isEmpty()) {
      return false;
    }
    int i = (s.charAt(0) == '+' || s.charAt(0) == '-') ? 1 : 0;
    if (i == s.length()) {
      return false;
    }
    for (; i < s.length(); i++) {
      if (s.charAt(i) < '0' || s.charAt(i) > '9') {
        return false;
      }
    }
    return true;
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
