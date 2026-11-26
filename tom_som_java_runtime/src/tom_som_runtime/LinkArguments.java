package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * An argument object of a link annotation (or a {@code Field} qualifier) as the
 * typed link readers see it ({@code tom_specs_model_rules.md} §9.7) — the
 * reading rules of {@link KindLink}: an enum constant loses its type prefix, a
 * key the reader does not know is ignored, and an absent key takes the
 * annotation's default, so a meta written before a key existed loads
 * unchanged.
 *
 * <p>The decoded JSON objects are insertion-ordered ({@link Json}), so a string
 * → string argument ({@code repeats}, {@code map}, {@code set}) keeps the order
 * the meta writes it in, as the reference's maps do.
 */
final class LinkArguments {
  private final Map<String, Object> values;

  LinkArguments(Map<String, Object> values) {
    this.values = values == null ? Collections.emptyMap() : values;
  }

  /** The arguments of {@code annotation}. */
  static LinkArguments of(SpecAnnotation annotation) {
    return new LinkArguments(annotation.arguments);
  }

  /** {@code raw} read as an argument object, or {@code null} when it is none. */
  @SuppressWarnings("unchecked")
  static LinkArguments ofObject(Object raw) {
    return raw instanceof Map ? new LinkArguments((Map<String, Object>) raw) : null;
  }

  Object get(String key) {
    return values.get(key);
  }

  /** A string argument, {@code fallback} when absent (or JSON null). */
  String str(String key, String fallback) {
    Object v = values.get(key);
    return v == null ? fallback : jsonText(v);
  }

  /** An optional string argument: the string, or {@code null} for anything else. */
  String optString(String key) {
    Object v = values.get(key);
    return v instanceof String ? (String) v : null;
  }

  /** A JSON list read as strings, nulls dropped; anything else as empty. */
  List<String> stringList(String key) {
    List<String> out = new ArrayList<>();
    Object raw = values.get(key);
    if (raw instanceof List) {
      for (Object e : (List<?>) raw) {
        if (e != null) {
          out.add(jsonText(e));
        }
      }
    }
    return Collections.unmodifiableList(out);
  }

  /** A JSON object read as string → string, in the meta's order; anything else as empty. */
  Map<String, String> stringMap(String key) {
    Map<String, String> out = new LinkedHashMap<>();
    Object raw = values.get(key);
    if (raw instanceof Map) {
      for (Map.Entry<?, ?> e : ((Map<?, ?>) raw).entrySet()) {
        out.put(String.valueOf(e.getKey()), jsonText(e.getValue()));
      }
    }
    return Collections.unmodifiableMap(out);
  }

  /** A list argument's object entries (anything else skipped). */
  List<LinkArguments> objects(String key) {
    List<LinkArguments> out = new ArrayList<>();
    Object raw = values.get(key);
    if (raw instanceof List) {
      for (Object e : (List<?>) raw) {
        LinkArguments a = ofObject(e);
        if (a != null) {
          out.add(a);
        }
      }
    }
    return out;
  }

  /**
   * A JSON scalar as text, the way the reference writes it ({@code true}, not
   * {@code True}; {@code null}; a whole number without a fraction).
   */
  static String jsonText(Object v) {
    if (v == null) {
      return "null";
    }
    if (v instanceof String) {
      return (String) v;
    }
    if (v instanceof Boolean || v instanceof Integer || v instanceof Long) {
      return v.toString();
    }
    if (v instanceof Double) {
      double d = (Double) v;
      if (d == Math.rint(d) && d > -1e15 && d < 1e15) {
        return Long.toString((long) d);
      }
      return v.toString();
    }
    return Json.write(v);
  }

  /** A string list as a JSON list (never null). */
  static List<Object> stringsJson(List<String> ss) {
    return new ArrayList<Object>(ss);
  }

  /** A string → string map as a JSON object, in its order. */
  static Map<String, Object> stringMapJson(Map<String, String> m) {
    return new LinkedHashMap<String, Object>(m);
  }
}
