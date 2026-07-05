package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Generic YAML codec for the native {@code *.docspecs.yaml} document format — a
 * faithful port of {@code spec_document_yaml.dart} / {@code spec_document_yaml.py}.
 *
 * <p>A header comment, {@code version:} (the on-disk format version), an optional
 * {@code modelVersion:} stamp (the authoring object-model {@code major.minor}),
 * then the {@code document:} pass — the live object-model values, sorted by full
 * section path. <b>All text values are written as literal block scalars
 * ({@code |2-})</b> so multi-line content round-trips verbatim. The emitter is
 * <b>self-verifying</b>: it re-parses each block it produces (via the hand-rolled
 * {@link Yaml}) and falls back to a JSON-quoted scalar for any value a clean block
 * can't represent.
 */
public final class SpecDocumentYaml {
  private SpecDocumentYaml() {}

  /** The on-disk format version (independent of the model-version stamp). */
  public static final int FORMAT_VERSION = 1;

  // --- scalar building ----------------------------------------------------

  private static String yamlKey(String key) {
    return Json.encodeString(key);
  }

  private static int trailingNewlines(String value) {
    int n = 0;
    int i = value.length();
    while (i > 0 && value.charAt(i - 1) == '\n') {
      n++;
      i--;
    }
    return n;
  }

  /**
   * Builds a literal block scalar ({@code |2<chomp>}) with body at relative
   * indent 2, or {@code null} when chomping can't reproduce the value's trailing
   * newlines (two or more) — those fall back to JSON quoting.
   */
  private static String literalBlock(String value) {
    int trailing = trailingNewlines(value);
    String chomp;
    String core;
    if (trailing == 0) {
      chomp = "-";
      core = value;
    } else if (trailing == 1) {
      chomp = "";
      core = value.substring(0, value.length() - 1);
    } else {
      return null;
    }
    StringBuilder parts = new StringBuilder("|2").append(chomp);
    for (String line : splitLines(core)) {
      parts.append("\n");
      if (!line.isEmpty()) {
        parts.append("  ").append(line);
      }
    }
    return parts.toString();
  }

  /** Whether re-parsing {@code _v: <block>} yields exactly {@code value}. */
  private static boolean roundTrips(String block, String value) {
    try {
      Object parsed = Yaml.parse("_v: " + block + "\n");
      if (parsed instanceof Map) {
        Object v = ((Map<?, ?>) parsed).get("_v");
        return value.equals(v);
      }
      return false;
    } catch (RuntimeException e) {
      return false;
    }
  }

  /**
   * The scalar representation of {@code value}: a literal block at relative
   * indent 2 when that round-trips, else a JSON-quoted scalar.
   */
  private static String scalar(String value) {
    String block = literalBlock(value);
    if (block != null && roundTrips(block, value)) {
      return block;
    }
    return Json.encodeString(value);
  }

  // --- buffer / writers ---------------------------------------------------

  private static void writeScalar(StringBuilder b, int keyIndent, String key, String value) {
    StringBuilder padBuilder = new StringBuilder();
    for (int i = 0; i < keyIndent; i++) {
      padBuilder.append(' ');
    }
    String pad = padBuilder.toString();
    String repr = scalar(value);
    String[] lines = repr.split("\n", -1);
    b.append(pad).append(yamlKey(key)).append(": ").append(lines[0]).append('\n');
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].isEmpty()) {
        b.append('\n');
      } else {
        b.append(pad).append(lines[i]).append('\n');
      }
    }
  }

  private static List<String> sortedStringKeys(Map<?, ?> m) {
    List<String> keys = keyStrings(m);
    Collections.sort(keys);
    return keys;
  }

  private static List<String> keyStrings(Map<?, ?> m) {
    List<String> keys = new ArrayList<>();
    for (Object k : m.keySet()) {
      keys.add(String.valueOf(k));
    }
    return keys;
  }

  private static void writeHeader(StringBuilder b, String modelVersion) {
    b.append("# TomSpecs document (*.docspecs.yaml).\n");
    b.append("# `document:` holds the object-model values, sorted by section id; text\n");
    b.append(
        "# values use block scalars so multi-line content round-trips verbatim (\u00A715.1).\n");
    b.append("version: ").append(FORMAT_VERSION).append('\n');
    if (modelVersion != null && !modelVersion.isEmpty()) {
      b.append("modelVersion: ").append(Json.encodeString(modelVersion)).append('\n');
    }
  }

  private static List<String> orderedKeys(Map<?, ?> m, SpecSerializationOrder order) {
    if (order == null) {
      return sortedStringKeys(m);
    }
    List<String> keys = new ArrayList<>();
    for (Object k : m.keySet()) {
      keys.add(String.valueOf(k));
    }
    return order.orderPaths(keys);
  }

  @SuppressWarnings("unchecked")
  private static void writeDocumentPass(
      StringBuilder b, Map<String, Object> doc, SpecSerializationOrder order) {
    Object content = doc.get("content");
    Object forms = doc.get("forms");
    Object lists = doc.get("lists");
    if (content == null && forms == null && lists == null) {
      b.append("document: {}\n");
      return;
    }
    b.append("document:\n");

    if (content instanceof Map && !((Map<?, ?>) content).isEmpty()) {
      Map<String, Object> cm = (Map<String, Object>) content;
      b.append("  content:\n");
      for (String k : orderedKeys(cm, order)) {
        writeScalar(b, 4, k, String.valueOf(cm.get(k)));
      }
    }

    if (forms instanceof Map && !((Map<?, ?>) forms).isEmpty()) {
      Map<String, Object> fm = (Map<String, Object>) forms;
      b.append("  forms:\n");
      for (String k : orderedKeys(fm, order)) {
        Object fields = fm.get(k);
        if (!(fields instanceof Map) || ((Map<?, ?>) fields).isEmpty()) {
          continue;
        }
        Map<String, Object> fields2 = (Map<String, Object>) fields;
        b.append("    ").append(yamlKey(k)).append(":\n");
        List<String> fieldKeys =
            order == null
                ? sortedStringKeys(fields2)
                : order.orderFormFields(k, keyStrings(fields2));
        for (String f : fieldKeys) {
          writeScalar(b, 6, f, String.valueOf(fields2.get(f)));
        }
      }
    }

    if (lists instanceof Map && !((Map<?, ?>) lists).isEmpty()) {
      Map<String, Object> lm = (Map<String, Object>) lists;
      b.append("  lists:\n");
      for (String k : orderedKeys(lm, order)) {
        Object specObj = lm.get(k);
        if (!(specObj instanceof Map)) {
          continue;
        }
        Map<String, Object> spec = (Map<String, Object>) specObj;
        b.append("    ").append(yamlKey(k)).append(":\n");
        Object seq = spec.get("seq");
        int seqVal = (seq instanceof Number) ? ((Number) seq).intValue() : 0;
        b.append("      seq: ").append(seqVal).append('\n');
        Object items = spec.get("items");
        if (items instanceof List && !((List<?>) items).isEmpty()) {
          b.append("      items:\n");
          for (Object it : (List<Object>) items) {
            b.append("        - ").append(yamlKey(String.valueOf(it))).append('\n');
          }
        } else {
          b.append("      items: []\n");
        }
      }
    }
  }

  // --- public API ---------------------------------------------------------

  /**
   * Serializes {@code document} to a header + {@code version:} (+
   * {@code modelVersion:}) + {@code document:} pass. Keys stay alphabetical (the
   * diff-stable default the editor relies on).
   */
  public static String encode(SpecDocument document, String modelVersion) {
    return encode(document, modelVersion, null);
  }

  /**
   * Serializes {@code document} with optional {@code @SerializationOrder}-based
   * member ordering (AA1 criterion 7). When {@code order} is supplied, members
   * are emitted in declaration order; otherwise keys stay alphabetical (the
   * diff-stable default).
   */
  public static String encode(
      SpecDocument document, String modelVersion, SpecSerializationOrder order) {
    StringBuilder b = new StringBuilder();
    writeHeader(b, modelVersion);
    writeDocumentPass(b, document.toJson(), order);
    return b.toString();
  }

  /**
   * Parses a {@code *.docspecs.yaml} document into its passes. A missing pass
   * decodes as empty rather than failing.
   */
  @SuppressWarnings("unchecked")
  public static SpecYamlContents decode(String yamlText) {
    Object root = yamlText.trim().isEmpty() ? null : Yaml.parse(yamlText);
    Object doc = (root instanceof Map) ? ((Map<String, Object>) root).get("document") : null;
    Object rev = (root instanceof Map) ? ((Map<String, Object>) root).get("review") : null;
    Object stamp = (root instanceof Map) ? ((Map<String, Object>) root).get("modelVersion") : null;
    String stampStr =
        (stamp != null && !String.valueOf(stamp).isEmpty()) ? String.valueOf(stamp) : null;
    return new SpecYamlContents(
        (doc instanceof Map) ? (Map<String, Object>) doc : new LinkedHashMap<>(),
        (rev instanceof Map) ? (Map<String, Object>) rev : new LinkedHashMap<>(),
        stampStr);
  }

  private static List<String> splitLines(String value) {
    List<String> out = new ArrayList<>();
    int start = 0;
    for (int i = 0; i < value.length(); i++) {
      if (value.charAt(i) == '\n') {
        out.add(value.substring(start, i));
        start = i + 1;
      }
    }
    out.add(value.substring(start));
    return out;
  }
}
