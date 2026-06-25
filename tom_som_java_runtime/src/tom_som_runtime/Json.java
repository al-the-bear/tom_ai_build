package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * A minimal, dependency-free JSON reader (and a small writer) — the Java
 * runtime ships with no external libraries (no Gson/Jackson), so the
 * conformance corpus ({@code model.meta.json}, {@code state.json}, …) is parsed
 * by this hand-rolled recursive-descent parser.
 *
 * <p>The value model mirrors the Python/Dart ports: JSON objects become
 * {@link LinkedHashMap}{@code <String,Object>} (insertion-ordered), arrays
 * become {@link ArrayList}{@code <Object>}, strings become {@link String},
 * integers become {@link Integer} (the corpus holds only small ints — this keeps
 * structural {@code equals()} between a parsed document and a re-serialised one
 * type-stable), non-integral numbers become {@link Double}, and {@code
 * true}/{@code false}/{@code null} map to {@link Boolean}/{@code null}.
 */
public final class Json {
  private final String src;
  private int pos;

  private Json(String src) {
    this.src = src;
  }

  /** Parses {@code text} into the Object value model. */
  public static Object parse(String text) {
    Json j = new Json(text);
    j.skipWhitespace();
    Object value = j.readValue();
    j.skipWhitespace();
    if (j.pos != j.src.length()) {
      throw new IllegalArgumentException(
          "trailing content at offset " + j.pos);
    }
    return value;
  }

  @SuppressWarnings("unchecked")
  public static Map<String, Object> parseObject(String text) {
    Object v = parse(text);
    if (!(v instanceof Map)) {
      throw new IllegalArgumentException("expected a JSON object");
    }
    return (Map<String, Object>) v;
  }

  private Object readValue() {
    char c = peek();
    switch (c) {
      case '{':
        return readObject();
      case '[':
        return readArray();
      case '"':
        return readString();
      case 't':
      case 'f':
        return readBool();
      case 'n':
        return readNull();
      default:
        return readNumber();
    }
  }

  private Map<String, Object> readObject() {
    expect('{');
    Map<String, Object> out = new LinkedHashMap<>();
    skipWhitespace();
    if (peek() == '}') {
      pos++;
      return out;
    }
    while (true) {
      skipWhitespace();
      String key = readString();
      skipWhitespace();
      expect(':');
      skipWhitespace();
      out.put(key, readValue());
      skipWhitespace();
      char c = next();
      if (c == '}') {
        return out;
      }
      if (c != ',') {
        throw err("expected ',' or '}'");
      }
    }
  }

  private List<Object> readArray() {
    expect('[');
    List<Object> out = new ArrayList<>();
    skipWhitespace();
    if (peek() == ']') {
      pos++;
      return out;
    }
    while (true) {
      skipWhitespace();
      out.add(readValue());
      skipWhitespace();
      char c = next();
      if (c == ']') {
        return out;
      }
      if (c != ',') {
        throw err("expected ',' or ']'");
      }
    }
  }

  private String readString() {
    expect('"');
    StringBuilder sb = new StringBuilder();
    while (true) {
      char c = next();
      if (c == '"') {
        return sb.toString();
      }
      if (c == '\\') {
        char e = next();
        switch (e) {
          case '"':
            sb.append('"');
            break;
          case '\\':
            sb.append('\\');
            break;
          case '/':
            sb.append('/');
            break;
          case 'b':
            sb.append('\b');
            break;
          case 'f':
            sb.append('\f');
            break;
          case 'n':
            sb.append('\n');
            break;
          case 'r':
            sb.append('\r');
            break;
          case 't':
            sb.append('\t');
            break;
          case 'u':
            String hex = src.substring(pos, pos + 4);
            pos += 4;
            sb.append((char) Integer.parseInt(hex, 16));
            break;
          default:
            throw err("invalid escape \\" + e);
        }
      } else {
        sb.append(c);
      }
    }
  }

  private Object readNumber() {
    int start = pos;
    boolean isDouble = false;
    while (pos < src.length()) {
      char c = src.charAt(pos);
      if (c == '-' || c == '+' || (c >= '0' && c <= '9')) {
        pos++;
      } else if (c == '.' || c == 'e' || c == 'E') {
        isDouble = true;
        pos++;
      } else {
        break;
      }
    }
    String token = src.substring(start, pos);
    if (token.isEmpty()) {
      throw err("expected a number");
    }
    if (isDouble) {
      return Double.parseDouble(token);
    }
    try {
      return Integer.valueOf(Integer.parseInt(token));
    } catch (NumberFormatException e) {
      return Long.valueOf(Long.parseLong(token));
    }
  }

  private Boolean readBool() {
    if (src.startsWith("true", pos)) {
      pos += 4;
      return Boolean.TRUE;
    }
    if (src.startsWith("false", pos)) {
      pos += 5;
      return Boolean.FALSE;
    }
    throw err("expected a boolean");
  }

  private Object readNull() {
    if (src.startsWith("null", pos)) {
      pos += 4;
      return null;
    }
    throw err("expected null");
  }

  private void skipWhitespace() {
    while (pos < src.length()) {
      char c = src.charAt(pos);
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        pos++;
      } else {
        break;
      }
    }
  }

  private char peek() {
    if (pos >= src.length()) {
      throw err("unexpected end of input");
    }
    return src.charAt(pos);
  }

  private char next() {
    if (pos >= src.length()) {
      throw err("unexpected end of input");
    }
    return src.charAt(pos++);
  }

  private void expect(char c) {
    char actual = next();
    if (actual != c) {
      throw err("expected '" + c + "' but got '" + actual + "'");
    }
  }

  private IllegalArgumentException err(String message) {
    return new IllegalArgumentException(message + " at offset " + pos);
  }

  // --- Writer -------------------------------------------------------------

  /** Serialises {@code value} to a compact JSON string (sorted object keys). */
  public static String write(Object value) {
    StringBuilder sb = new StringBuilder();
    writeValue(sb, value, false, 0);
    return sb.toString();
  }

  /** Serialises {@code value} to a 2-space-indented JSON string (sorted keys). */
  public static String writePretty(Object value) {
    StringBuilder sb = new StringBuilder();
    writeValue(sb, value, true, 0);
    return sb.toString();
  }

  @SuppressWarnings("unchecked")
  private static void writeValue(
      StringBuilder sb, Object value, boolean pretty, int depth) {
    if (value == null) {
      sb.append("null");
    } else if (value instanceof Map) {
      writeMap(sb, (Map<String, Object>) value, pretty, depth);
    } else if (value instanceof List) {
      writeList(sb, (List<Object>) value, pretty, depth);
    } else if (value instanceof String) {
      writeString(sb, (String) value);
    } else if (value instanceof Boolean || value instanceof Number) {
      sb.append(value.toString());
    } else {
      writeString(sb, value.toString());
    }
  }

  private static void writeMap(
      StringBuilder sb, Map<String, Object> map, boolean pretty, int depth) {
    if (map.isEmpty()) {
      sb.append("{}");
      return;
    }
    List<String> keys = new ArrayList<>(map.keySet());
    java.util.Collections.sort(keys);
    sb.append('{');
    boolean first = true;
    for (String key : keys) {
      if (!first) {
        sb.append(',');
      }
      first = false;
      newlineIndent(sb, pretty, depth + 1);
      writeString(sb, key);
      sb.append(pretty ? ": " : ":");
      writeValue(sb, map.get(key), pretty, depth + 1);
    }
    newlineIndent(sb, pretty, depth);
    sb.append('}');
  }

  private static void writeList(
      StringBuilder sb, List<Object> list, boolean pretty, int depth) {
    if (list.isEmpty()) {
      sb.append("[]");
      return;
    }
    sb.append('[');
    boolean first = true;
    for (Object e : list) {
      if (!first) {
        sb.append(',');
      }
      first = false;
      newlineIndent(sb, pretty, depth + 1);
      writeValue(sb, e, pretty, depth + 1);
    }
    newlineIndent(sb, pretty, depth);
    sb.append(']');
  }

  private static void newlineIndent(StringBuilder sb, boolean pretty, int depth) {
    if (!pretty) {
      return;
    }
    sb.append('\n');
    for (int i = 0; i < depth; i++) {
      sb.append("  ");
    }
  }

  /** Writes {@code s} as a JSON double-quoted string (matches Python json). */
  static void writeString(StringBuilder sb, String s) {
    sb.append('"');
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      switch (c) {
        case '"':
          sb.append("\\\"");
          break;
        case '\\':
          sb.append("\\\\");
          break;
        case '\n':
          sb.append("\\n");
          break;
        case '\r':
          sb.append("\\r");
          break;
        case '\t':
          sb.append("\\t");
          break;
        case '\b':
          sb.append("\\b");
          break;
        case '\f':
          sb.append("\\f");
          break;
        default:
          if (c < 0x20) {
            sb.append(String.format("\\u%04x", (int) c));
          } else {
            sb.append(c);
          }
      }
    }
    sb.append('"');
  }

  /** The JSON string literal for {@code s} (matches {@code json.dumps}). */
  static String encodeString(String s) {
    StringBuilder sb = new StringBuilder();
    writeString(sb, s);
    return sb.toString();
  }
}
