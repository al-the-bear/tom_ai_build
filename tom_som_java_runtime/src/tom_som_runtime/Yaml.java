package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * A minimal, dependency-free YAML reader for the constrained
 * {@code *.docspecs.yaml} subset the {@link SpecDocumentYaml} codec emits — the
 * Java runtime ships with no external libraries (no SnakeYAML), so this
 * hand-rolled indentation parser stands in for {@code package:yaml} / PyYAML.
 *
 * <p>It supports exactly what the encoder produces (and what the self-verify
 * round-trip probe needs): block mappings, block sequences ({@code - item}),
 * literal block scalars ({@code |}, {@code |-}, {@code |2}, {@code |2-} …),
 * JSON-quoted flow scalars, plain integers, and the empty flow collections
 * {@code {}} / {@code []}. The value model matches {@link Json}:
 * {@link LinkedHashMap}, {@link ArrayList}, {@link String}, {@link Integer}
 * (a plain integer outside the {@code int} range stays its text) — or, in the
 * typed reading, the YAML 1.2 core-schema scalars of SOM §12.5 (see
 * {@link #parse(String, boolean)}).
 */
public final class Yaml {
  private final List<String> lines;
  private final boolean typed;
  private int idx;

  private Yaml(List<String> lines, boolean typed) {
    this.lines = lines;
    this.typed = typed;
  }

  /** Parses {@code text} into the Object value model (a mapping or sequence). */
  public static Object parse(String text) {
    return parse(text, false);
  }

  /**
   * Parses {@code text}; with {@code typed} set, a plain scalar is typed by the
   * YAML 1.2 core schema (SOM §12.5) — quoted and block scalars are always
   * strings:
   *
   * <ul>
   *   <li>null: {@code ~}, {@code null}, {@code Null}, {@code NULL}, and an
   *       empty value;
   *   <li>{@link Boolean}: {@code true|True|TRUE|false|False|FALSE};
   *   <li>int: {@code [-+]?[0-9]+}, {@code 0o[0-7]+}, {@code 0x[0-9a-fA-F]+} —
   *       an {@link Integer} when it fits, else a {@link Long}; a decimal
   *       outside the signed 64-bit range becomes a float;
   *   <li>float ({@link Double}):
   *       {@code [-+]?(.[0-9]+|[0-9]+(.[0-9]*)?)([eE][-+]?[0-9]+)?},
   *       {@code [-+]?.inf}, {@code .nan} (each in its three spellings);
   *   <li>a plain {@code [...]} is a JSON flow sequence; anything else a string.
   * </ul>
   *
   * That is what the uninterpreted {@code review:} pass needs to round-trip its
   * typed values. The document pass is read untyped.
   */
  public static Object parse(String text, boolean typed) {
    List<String> raw = splitLines(text);
    Yaml y = new Yaml(raw, typed);
    int first = y.nextSignificant(0);
    if (first == -1) {
      return new LinkedHashMap<String, Object>();
    }
    return y.parseNode(0);
  }

  @SuppressWarnings("unchecked")
  public static Map<String, Object> parseMap(String text) {
    Object v = parse(text);
    if (v instanceof Map) {
      return (Map<String, Object>) v;
    }
    return new LinkedHashMap<>();
  }

  private static List<String> splitLines(String text) {
    List<String> out = new ArrayList<>();
    int start = 0;
    for (int i = 0; i < text.length(); i++) {
      if (text.charAt(i) == '\n') {
        out.add(text.substring(start, i));
        start = i + 1;
      }
    }
    out.add(text.substring(start));
    return out;
  }

  private Object parseNode(int minIndent) {
    int i = nextSignificant(idx);
    if (i == -1) {
      return new LinkedHashMap<String, Object>();
    }
    String line = lines.get(i);
    int indent = leading(line);
    if (indent < minIndent) {
      return new LinkedHashMap<String, Object>();
    }
    String content = line.substring(indent);
    if (content.equals("-") || content.startsWith("- ")) {
      return parseSequence(indent);
    }
    return parseMapping(indent);
  }

  private Map<String, Object> parseMapping(int indent) {
    Map<String, Object> map = new LinkedHashMap<>();
    while (true) {
      int i = nextSignificant(idx);
      if (i == -1) {
        break;
      }
      String line = lines.get(i);
      int curIndent = leading(line);
      if (curIndent != indent) {
        break; // dedent → belongs to the parent; over-indent shouldn't occur.
      }
      idx = i + 1;
      String content = line.substring(indent);
      int colon = findColon(content);
      if (colon < 0) {
        continue; // not a mapping entry — tolerate and skip.
      }
      String key = parseScalarKey(content.substring(0, colon).trim());
      String rest = content.substring(colon + 1).trim();
      Object value;
      if (rest.isEmpty()) {
        value = parseNestedAfterKey(indent);
      } else if (rest.startsWith("|") || rest.startsWith(">")) {
        value = parseBlockScalar(rest, indent);
      } else {
        value = parseFlowScalar(rest);
      }
      map.put(key, value);
    }
    return map;
  }

  private List<Object> parseSequence(int indent) {
    List<Object> list = new ArrayList<>();
    while (true) {
      int i = nextSignificant(idx);
      if (i == -1) {
        break;
      }
      String line = lines.get(i);
      int curIndent = leading(line);
      if (curIndent != indent) {
        break;
      }
      String content = line.substring(indent);
      if (!content.equals("-") && !content.startsWith("- ")) {
        break;
      }
      idx = i + 1;
      String itemText = content.equals("-") ? "" : content.substring(2).trim();
      if (itemText.isEmpty()) {
        list.add(parseNestedAfterKey(indent));
      } else if (itemText.startsWith("|") || itemText.startsWith(">")) {
        list.add(parseBlockScalar(itemText, indent));
      } else {
        // A `- key: …` item is a mapping whose first entry sits on the dash
        // line; rewrite the dash as indentation and re-parse as a mapping.
        int colon = findColon(itemText);
        boolean isMapEntry =
            colon >= 0 && (colon == itemText.length() - 1 || itemText.charAt(colon + 1) == ' ');
        if (isMapEntry) {
          idx = i;
          lines.set(i, " ".repeat(indent + 2) + line.substring(indent + 2));
          list.add(parseMapping(indent + 2));
        } else {
          list.add(parseFlowScalar(itemText));
        }
      }
    }
    return list;
  }

  private Object parseNestedAfterKey(int parentIndent) {
    int i = nextSignificant(idx);
    if (i == -1) {
      return new LinkedHashMap<String, Object>();
    }
    int childIndent = leading(lines.get(i));
    if (childIndent <= parentIndent) {
      // An empty value: null in the YAML 1.2 core schema (the typed reading).
      return typed ? null : new LinkedHashMap<String, Object>();
    }
    return parseNode(childIndent);
  }

  private Object parseFlowScalar(String s) {
    String t = s.trim();
    if (t.equals("{}")) {
      return new LinkedHashMap<String, Object>();
    }
    if (t.equals("[]")) {
      return new ArrayList<Object>();
    }
    if (t.startsWith("\"")) {
      return Json.parse(t); // a JSON string literal is a valid YAML flow scalar.
    }
    if (typed) {
      return typedScalar(t);
    }
    if (isInteger(t)) {
      try {
        return Integer.valueOf(Integer.parseInt(t));
      } catch (NumberFormatException e) {
        return t; // beyond int: the untyped reading keeps the text.
      }
    }
    return t;
  }

  private static final java.util.regex.Pattern FLOAT_PATTERN =
      java.util.regex.Pattern.compile("^[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?$");

  private static final java.util.regex.Pattern DEC_PATTERN =
      java.util.regex.Pattern.compile("^[-+]?[0-9]+$");
  private static final java.util.regex.Pattern OCT_PATTERN =
      java.util.regex.Pattern.compile("^0o[0-7]+$");
  private static final java.util.regex.Pattern HEX_PATTERN =
      java.util.regex.Pattern.compile("^0x[0-9a-fA-F]+$");
  private static final java.math.BigInteger LONG_MIN =
      java.math.BigInteger.valueOf(Long.MIN_VALUE);
  private static final java.math.BigInteger LONG_MAX =
      java.math.BigInteger.valueOf(Long.MAX_VALUE);

  /**
   * An integer as an {@link Integer} when it fits, else a {@link Long}; beyond
   * the signed 64-bit range it becomes a float ({@link Double}).
   */
  private static Object intValue(java.math.BigInteger n) {
    if (n.compareTo(LONG_MIN) < 0 || n.compareTo(LONG_MAX) > 0) {
      return Double.valueOf(n.doubleValue());
    }
    long v = n.longValue();
    return v >= Integer.MIN_VALUE && v <= Integer.MAX_VALUE
        ? (Object) Integer.valueOf((int) v)
        : (Object) Long.valueOf(v);
  }

  /** The YAML 1.2 core-schema reading of the plain scalar {@code t} (SOM §12.5). */
  private static Object typedScalar(String t) {
    switch (t) {
      case "true":
      case "True":
      case "TRUE":
        return Boolean.TRUE;
      case "false":
      case "False":
      case "FALSE":
        return Boolean.FALSE;
      case "null":
      case "Null":
      case "NULL":
      case "~":
      case "":
        return null;
      case ".inf":
      case ".Inf":
      case ".INF":
      case "+.inf":
      case "+.Inf":
      case "+.INF":
        return Double.valueOf(Double.POSITIVE_INFINITY);
      case "-.inf":
      case "-.Inf":
      case "-.INF":
        return Double.valueOf(Double.NEGATIVE_INFINITY);
      case ".nan":
      case ".NaN":
      case ".NAN":
        return Double.valueOf(Double.NaN);
      default:
        break;
    }
    if (DEC_PATTERN.matcher(t).matches()) {
      return intValue(new java.math.BigInteger(t.startsWith("+") ? t.substring(1) : t));
    }
    if (OCT_PATTERN.matcher(t).matches()) {
      return intValue(new java.math.BigInteger(t.substring(2), 8));
    }
    if (HEX_PATTERN.matcher(t).matches()) {
      return intValue(new java.math.BigInteger(t.substring(2), 16));
    }
    if (FLOAT_PATTERN.matcher(t).matches()) {
      return Double.valueOf(Double.parseDouble(t));
    }
    if (t.startsWith("[") && t.endsWith("]")) {
      try {
        return Json.parse(t);
      } catch (RuntimeException e) {
        return t;
      }
    }
    return t;
  }

  /**
   * Parses a literal block scalar starting at {@code header} (e.g. {@code |2-})
   * whose body lines follow in {@link #lines}. {@code keyIndent} is the
   * indentation of the owning key/sequence line.
   */
  private String parseBlockScalar(String header, int keyIndent) {
    int p = 1; // skip the leading '|' (or '>').
    int explicitIndent = -1;
    int digitsStart = p;
    while (p < header.length() && Character.isDigit(header.charAt(p))) {
      p++;
    }
    if (p > digitsStart) {
      explicitIndent = Integer.parseInt(header.substring(digitsStart, p));
    }
    char chomp = ' ';
    while (p < header.length()) {
      char c = header.charAt(p);
      if (c == '-' || c == '+') {
        chomp = c;
      }
      p++;
    }

    // Collect the raw body: blank lines plus any line indented past the key.
    List<String> rawBody = new ArrayList<>();
    while (idx < lines.size()) {
      String l = lines.get(idx);
      if (l.trim().isEmpty()) {
        rawBody.add("");
        idx++;
        continue;
      }
      if (leading(l) <= keyIndent) {
        break;
      }
      rawBody.add(l);
      idx++;
    }
    // Drop trailing blank lines that actually belong to the following node.
    while (!rawBody.isEmpty() && rawBody.get(rawBody.size() - 1).isEmpty()) {
      rawBody.remove(rawBody.size() - 1);
    }

    int contentIndent;
    if (explicitIndent >= 0) {
      contentIndent = keyIndent + explicitIndent;
    } else {
      contentIndent = Integer.MAX_VALUE;
      for (String l : rawBody) {
        if (!l.isEmpty()) {
          contentIndent = Math.min(contentIndent, leading(l));
        }
      }
      if (contentIndent == Integer.MAX_VALUE) {
        contentIndent = keyIndent + 1;
      }
    }

    List<String> body = new ArrayList<>();
    for (String l : rawBody) {
      if (l.isEmpty()) {
        body.add("");
      } else {
        int strip = Math.min(contentIndent, l.length());
        body.add(l.substring(strip));
      }
    }

    String joined = String.join("\n", body);
    if (chomp == '-') {
      int end = joined.length();
      while (end > 0 && joined.charAt(end - 1) == '\n') {
        end--;
      }
      return joined.substring(0, end);
    }
    if (chomp == '+') {
      return joined;
    }
    // Clip (default): exactly one trailing newline when non-empty.
    int end = joined.length();
    while (end > 0 && joined.charAt(end - 1) == '\n') {
      end--;
    }
    String clipped = joined.substring(0, end);
    return clipped.isEmpty() ? "" : clipped + "\n";
  }

  // --- helpers ------------------------------------------------------------

  private int nextSignificant(int from) {
    for (int i = from; i < lines.size(); i++) {
      String l = lines.get(i);
      String t = l.trim();
      if (t.isEmpty() || t.startsWith("#")) {
        continue;
      }
      return i;
    }
    return -1;
  }

  private static int leading(String line) {
    int n = 0;
    while (n < line.length() && line.charAt(n) == ' ') {
      n++;
    }
    return n;
  }

  private static int findColon(String content) {
    if (content.startsWith("\"")) {
      int i = 1;
      while (i < content.length()) {
        char c = content.charAt(i);
        if (c == '\\') {
          i += 2;
          continue;
        }
        if (c == '"') {
          i++;
          break;
        }
        i++;
      }
      return content.indexOf(':', i);
    }
    return content.indexOf(':');
  }

  private static String parseScalarKey(String keyPart) {
    if (keyPart.startsWith("\"")) {
      Object v = Json.parse(keyPart);
      return v == null ? "" : v.toString();
    }
    return keyPart;
  }

  private static boolean isInteger(String s) {
    if (s.isEmpty()) {
      return false;
    }
    int i = 0;
    if (s.charAt(0) == '-' || s.charAt(0) == '+') {
      i = 1;
      if (s.length() == 1) {
        return false;
      }
    }
    for (; i < s.length(); i++) {
      if (!Character.isDigit(s.charAt(i))) {
        return false;
      }
    }
    return true;
  }
}
