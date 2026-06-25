package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * A single annotation captured losslessly from the model source (spec §3.1):
 * its name and the resolved argument map.
 */
public final class SpecAnnotation {
  public final String name;
  public final Map<String, Object> arguments;

  public SpecAnnotation(String name, Map<String, Object> arguments) {
    this.name = name;
    this.arguments = arguments;
  }

  public Object argument(String key) {
    return arguments.get(key);
  }

  @SuppressWarnings("unchecked")
  public static SpecAnnotation fromJson(Map<String, Object> j) {
    Object args = j.get("arguments");
    Map<String, Object> map =
        args instanceof Map ? new LinkedHashMap<>((Map<String, Object>) args)
                            : new LinkedHashMap<>();
    return new SpecAnnotation((String) j.get("name"), map);
  }

  @SuppressWarnings("unchecked")
  public static List<SpecAnnotation> listFromJson(Object raw) {
    List<SpecAnnotation> out = new ArrayList<>();
    if (raw instanceof List) {
      for (Object e : (List<Object>) raw) {
        out.add(fromJson((Map<String, Object>) e));
      }
    }
    return out;
  }
}
