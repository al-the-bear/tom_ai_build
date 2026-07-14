package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Generic YAML codec for the native {@code *.docspecs.yaml} document format —
 * <b>hierarchical format v2</b> (DR1 §2); a faithful port of
 * {@code spec_document_yaml.dart} / {@code spec_document_yaml.ts}.
 *
 * <p>One nested YAML tree whose indentation mirrors the document structure:
 * every model node becomes a mapping key ({@code <section-id> <member-name>},
 * DR1 §2.2), sections nest their children, list items appear under their
 * container keyed by their stored section id (or an anonymous positional
 * {@code <member>-<n>} key), a node's own body text uses the literal key
 * {@code content}, and form fields use their bare field names. The former flat
 * two-level path-map format ({@code document: {content: {"A/b": …}}}) is
 * <b>retired</b>; readers reject {@code version: 1} files with a clear error
 * (no compatibility path).
 *
 * <p>Text values are written as literal block scalars ({@code |2-}), with the
 * DR1 §2.4 escaping rules: the emitter is <b>self-verifying</b> (it re-parses
 * each scalar it produces via the hand-rolled {@link Yaml} reader — the runtime
 * ships no external YAML library — and falls back to a double-quoted
 * JSON-escaped flow scalar when the parse differs), and <b>runs of 2+
 * consecutive empty lines are collapsed to one</b> before serialization (a
 * deliberate, documented lossy normalization — round-trip guarantees are
 * stated "modulo empty-line dedup"). Non-text values ({@code int}/{@code
 * double}/{@code bool}, enum member names) are plain scalars when they
 * self-verify (§2.5). The JSON quoting ({@link Json#encodeString}) is
 * byte-for-byte identical to JavaScript's {@code JSON.stringify} so output is
 * stable across every language port.
 *
 * <p>Both {@link #encode} and {@link #decode} walk the {@link SomMetaTree} of
 * the document root: the file carries <b>no paths</b> — the runtime
 * reconstructs them by matching keys against the metadata tree, and a key that
 * matches nothing at its position is a structured load error
 * ({@link SpecYamlFormatException}; no silent skips). Symmetrically,
 * {@link #encode} throws when the document holds values the tree cannot place
 * (nothing is silently dropped).
 *
 * <p>The optional {@code review:} pass stays opaque to the runtime
 * ({@link #decode} returns it as a raw mapping for the editor to interpret).
 *
 * <p>Divergences shared with the hand-rolled parser (documented in the JS/TS
 * ports too): a bare {@code key:} parses as an empty mapping (which counts as
 * an empty scalar at scalar positions), and the parser never yields booleans,
 * so plain-scalar self-verification needs no bool canonicalisation.
 */
public final class SpecDocumentYaml {
  private SpecDocumentYaml() {}

  /**
   * The on-disk format version (independent of the model-version stamp).
   * Version 2 is the hierarchical tree format; version-1 flat files are
   * rejected on read.
   */
  public static final int FORMAT_VERSION = 2;

  // --- Shared scalar machinery (public for the editor's review writer) -----

  /**
   * The mapping key a metadata node writes (DR1 §2.2): its effective section
   * id, one space, then the exact member name (class name on the document
   * root); just the name when the node carries no id.
   */
  public static String nodeKey(SomMetaNode node) {
    String name = node.memberName;
    if (name == null || name.isEmpty()) {
      name = node.className;
    }
    if (node.sectionId == null || node.sectionId.isEmpty()) {
      return name;
    }
    return node.sectionId + " " + name;
  }

  /**
   * A safely-quoted mapping key. JSON strings are valid YAML flow scalars, so
   * this both quotes and escapes any path/field name unambiguously.
   */
  public static String yamlKey(String key) {
    return Json.encodeString(key);
  }

  private static final Pattern PLAIN_KEY_PATTERN =
      Pattern.compile("^[A-Za-z0-9_][A-Za-z0-9_. -]*[A-Za-z0-9_.\\-]$|^[A-Za-z0-9_]$");

  /**
   * {@code key} as a plain key when it is YAML-safe by construction (section
   * ids, member names, {@code <id> <name>} pairs), else a JSON-quoted one.
   */
  public static String plainKey(String key) {
    if (PLAIN_KEY_PATTERN.matcher(key).matches()) {
      return key;
    }
    return yamlKey(key);
  }

  private static final Pattern BLANK_RUNS = Pattern.compile("\n{3,}");

  /**
   * Collapses runs of two or more consecutive empty lines to a single empty
   * line (DR1 §2.4.3 — the deliberate lossy normalization applied to every
   * text value before serialization).
   */
  public static String dedupEmptyLines(String value) {
    return BLANK_RUNS.matcher(value).replaceAll("\n\n");
  }

  /**
   * The Dart-toString-compatible string of a parsed YAML scalar (the
   * hand-rolled parser yields String or Integer only, so no bool
   * canonicalisation is needed).
   */
  private static String parsedScalarStr(Object v) {
    if (v instanceof String) {
      return (String) v;
    }
    if (v instanceof Integer) {
      return String.valueOf(v);
    }
    if (v instanceof Boolean) {
      return ((Boolean) v) ? "true" : "false";
    }
    return "";
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
   * indent 2, or {@code null} when chomping can't reproduce the value's
   * trailing newlines (two or more) — those fall back to JSON quoting.
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
      parts.append('\n');
      if (!line.isEmpty()) {
        parts.append("  ").append(line);
      }
    }
    return parts.toString();
  }

  /**
   * Whether re-parsing {@code _v: <block>} yields exactly {@code value} (the
   * emitter's correctness guard).
   */
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
  private static String scalarRepr(String value) {
    String block = literalBlock(value);
    if (block != null && roundTrips(block, value)) {
      return block;
    }
    return Json.encodeString(value);
  }

  private static final Pattern YAML11_BOOL =
      Pattern.compile("^(y|Y|yes|Yes|YES|n|N|no|No|NO|on|On|ON|off|Off|OFF)$");
  private static final Pattern YAML11_SEXAGESIMAL_INT =
      Pattern.compile("^[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+$");
  private static final Pattern YAML11_SEXAGESIMAL_FLOAT =
      Pattern.compile("^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\\.[0-9_]*$");

  /**
   * Whether {@code value}'s text is a YAML 1.1 special that a 1.1 parser would
   * resolve to a non-string, so it must never be emitted as a plain scalar
   * (DR1 §2.5). Covers the 1.1-only boolean words and sexagesimal int/float
   * literals. Mirrors the Dart reference rule so every emitter's plain-scalar
   * decision is identical regardless of the local YAML library's schema.
   */
  private static boolean isYaml11Special(String value) {
    return YAML11_BOOL.matcher(value).matches()
        || YAML11_SEXAGESIMAL_INT.matcher(value).matches()
        || YAML11_SEXAGESIMAL_FLOAT.matcher(value).matches();
  }

  /**
   * A plain one-line scalar for a non-text value (int/double/bool/enum member
   * name, §2.5) when writing it plainly re-parses to exactly {@code value}
   * (string compare, matching the document's string-typed stores);
   * {@code null} otherwise. Values whose text is a YAML 1.1 special are forced
   * to the quoted/block path so cross-language round-trips stay identical.
   */
  private static String plainScalar(String value) {
    if (value.isEmpty() || value.indexOf('\n') >= 0) {
      return null;
    }
    if (isYaml11Special(value)) {
      return null;
    }
    Object parsed;
    try {
      parsed = Yaml.parse("_v: " + value + "\n");
    } catch (RuntimeException e) {
      return null;
    }
    if (!(parsed instanceof Map)) {
      return null;
    }
    Map<?, ?> m = (Map<?, ?>) parsed;
    if (!m.containsKey("_v")) {
      return null;
    }
    Object v = m.get("_v");
    if (v == null || v instanceof Map || v instanceof List) {
      return null;
    }
    if (!parsedScalarStr(v).equals(value)) {
      return null;
    }
    return value;
  }

  private static String pad(int n) {
    StringBuilder b = new StringBuilder(n);
    for (int i = 0; i < n; i++) {
      b.append(' ');
    }
    return b.toString();
  }

  private static void writeRendered(
      StringBuilder b, int keyIndent, String renderedKey, String repr) {
    String prefix = pad(keyIndent);
    String[] lines = repr.split("\n", -1);
    b.append(prefix).append(renderedKey).append(": ").append(lines[0]).append('\n');
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].isEmpty()) {
        b.append('\n');
      } else {
        b.append(prefix).append(lines[i]).append('\n');
      }
    }
  }

  /**
   * Writes {@code <indent><key>: <scalar>} where the scalar is a self-verified
   * block scalar (or a JSON-quoted fallback). Block body lines, which the
   * builder emits at a relative indent of 2, are re-indented past
   * {@code keyIndent}. (Kept as the shared helper the editor's review writer
   * uses in the other ports.)
   */
  public static void writeScalar(StringBuilder b, int keyIndent, String key, String value) {
    writeRendered(b, keyIndent, yamlKey(key), scalarRepr(value));
  }

  /**
   * Writes the file header comment + {@code version:} line, and the optional
   * {@code modelVersion:} stamp when {@code modelVersion} is non-empty.
   */
  private static void writeHeader(StringBuilder b, String modelVersion) {
    b.append("# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n");
    b.append("version: ").append(FORMAT_VERSION).append('\n');
    if (modelVersion != null && !modelVersion.isEmpty()) {
      b.append("modelVersion: ").append(Json.encodeString(modelVersion)).append('\n');
    }
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

  // --- Encode ---------------------------------------------------------------

  private static boolean isNumericOrBool(String typeName) {
    return "int".equals(typeName)
        || "double".equals(typeName)
        || "num".equals(typeName)
        || "bool".equals(typeName);
  }

  /**
   * Serializes {@code document} to a header + {@code version:} (+
   * {@code modelVersion:}) + hierarchical {@code document:} pass, walking
   * {@code tree} (the metadata tree of the document's root).
   *
   * <p>Sibling order is the tree's child order ({@code @SerializationOrder}),
   * list items follow their stored sequence; emission is sparse (only
   * populated subtrees appear). Throws {@link SpecYamlFormatException} when the
   * document holds values {@code tree} cannot place — nothing is silently
   * dropped.
   */
  public static String encode(SpecDocument document, SomMetaTree tree, String modelVersion) {
    StringBuilder b = new StringBuilder();
    writeHeader(b, modelVersion);
    new YamlEncoder(document).writeDocumentPass(b, tree);
    return b.toString();
  }

  /**
   * One encode run: walks the metadata tree, consuming values from snapshots of
   * the document's stores so anything left unconsumed at the end is a
   * structured error (nothing is silently dropped).
   */
  private static final class YamlEncoder {
    private final SpecDocument doc;
    private final Map<String, String> content = new LinkedHashMap<>();
    private final Map<String, Map<String, String>> forms = new LinkedHashMap<>();
    private final Set<String> lists = new HashSet<>();

    YamlEncoder(SpecDocument doc) {
      this.doc = doc;
      for (String p : doc.contentPaths()) {
        content.put(p, doc.content(p));
      }
      for (String p : doc.formPaths()) {
        Map<String, String> fields = new LinkedHashMap<>();
        for (String f : doc.formFieldNames(p)) {
          fields.put(f, doc.formField(p, f));
        }
        forms.put(p, fields);
      }
      for (String p : doc.listPaths()) {
        lists.add(p);
      }
    }

    void writeDocumentPass(StringBuilder b, SomMetaTree tree) {
      SomMetaNode root = tree.root;
      String body = mappingBody(root, root.segment(), 4);
      assertNothingLeft();
      if (body.isEmpty()) {
        b.append("document: {}\n");
        return;
      }
      b.append("document:\n");
      b.append("  ").append(plainKey(nodeKey(root))).append(":\n");
      b.append(body);
    }

    /**
     * The mapping body of {@code node} at {@code path} (root, a collapsed
     * section/complex field, or a list item's element), one line per populated
     * entry at {@code indent}. Empty when nothing under the node is populated.
     */
    private String mappingBody(SomMetaNode node, String path, int indent) {
      StringBuilder b = new StringBuilder();

      // The node's own body text — the literal `content` key (DR1 §2.2).
      if (content.containsKey(path)) {
        String own = content.remove(path);
        for (SomMetaNode c : node.children) {
          if (nodeKey(c).equals("content")) {
            throw new SpecYamlFormatException(
                "cannot emit body text at `" + path + "`: a child of "
                    + node.debugName() + " also serializes as key `content`");
          }
        }
        writeText(b, indent, "content", own);
      }

      for (SomMetaNode child : node.children) {
        String childPath = SpecPaths.join(path, child.segment());
        String key = nodeKey(child);
        switch (child.kind) {
          case SomMetaKind.CONTENT:
            if (content.containsKey(childPath)) {
              writeText(b, indent, key, content.remove(childPath));
            }
            break;
          case SomMetaKind.SCALAR:
          case SomMetaKind.ENUM_VALUE:
            if (content.containsKey(childPath)) {
              writeValue(b, indent, key, content.remove(childPath));
            }
            break;
          case SomMetaKind.FORM:
            writeForm(b, indent, key, child, childPath);
            break;
          case SomMetaKind.SECTION:
          case SomMetaKind.COMPLEX:
            String sub = mappingBody(child, childPath, indent + 2);
            if (!sub.isEmpty()) {
              b.append(pad(indent)).append(plainKey(key)).append(":\n");
              b.append(sub);
            }
            break;
          case SomMetaKind.LIST:
            writeList(b, indent, key, child, childPath);
            break;
          default:
            break;
        }
      }
      return b.toString();
    }

    private void writeForm(
        StringBuilder b, int indent, String key, SomMetaNode node, String path) {
      Map<String, String> fields = forms.remove(path);
      if (fields == null || fields.isEmpty()) {
        return;
      }
      SomFormMeta meta = node.form != null ? node.form : new SomFormMeta(null);
      for (String name : fields.keySet()) {
        if (meta.fieldNamed(name) == null) {
          throw new SpecYamlFormatException(
              "form `" + path + "` holds a field `" + name + "` unknown to the model");
        }
      }
      b.append(pad(indent)).append(plainKey(key)).append(":\n");
      for (SomFormFieldMeta f : meta.fields) {
        if (!fields.containsKey(f.name)) {
          continue;
        }
        String v = fields.get(f.name);
        if (isNumericOrBool(f.typeName)) {
          writeValue(b, indent + 2, f.name, v);
        } else {
          writeText(b, indent + 2, f.name, v);
        }
      }
    }

    private void writeList(
        StringBuilder b, int indent, String key, SomMetaNode node, String path) {
      lists.remove(path);
      List<String> items = doc.listItems(path);
      if (items.isEmpty()) {
        return;
      }
      b.append(pad(indent)).append(plainKey(key)).append(":\n");
      Set<String> used = new HashSet<>();
      int pos = 0;
      for (String itemPath : items) {
        pos++;
        String storedId = doc.itemSectionId(itemPath);
        boolean hasStored = storedId != null;
        String itemKey = hasStored ? storedId : node.memberName + "-" + pos;
        if (hasStored) {
          if (used.contains(itemKey)) {
            throw new SpecYamlFormatException(
                "duplicate list item key `" + itemKey + "` at `" + path + "`");
          }
          used.add(itemKey);
        } else {
          int bump = pos;
          while (used.contains(itemKey)) {
            bump++;
            itemKey = node.memberName + "-" + bump;
          }
          used.add(itemKey);
        }
        SomMetaNode element = node.elementNode;
        if (element == null) {
          // Scalar list: the item is a direct value.
          String v = "";
          if (content.containsKey(itemPath)) {
            v = content.remove(itemPath);
          }
          writeValue(b, indent + 2, itemKey, v);
        } else {
          String sub = mappingBody(element, itemPath, indent + 4);
          if (sub.isEmpty()) {
            b.append(pad(indent + 2)).append(plainKey(itemKey)).append(": {}\n");
          } else {
            b.append(pad(indent + 2)).append(plainKey(itemKey)).append(":\n");
            b.append(sub);
          }
        }
      }
    }

    /**
     * Writes a text value: empty-line dedup, then a self-verified block scalar
     * (or the JSON-quoted fallback).
     */
    private void writeText(StringBuilder b, int indent, String key, String value) {
      writeRendered(b, indent, plainKey(key), scalarRepr(dedupEmptyLines(value)));
    }

    /** Writes a non-text value (§2.5): plain when it self-verifies, else the text path. */
    private void writeValue(StringBuilder b, int indent, String key, String value) {
      String plain = plainScalar(value);
      if (plain != null) {
        b.append(pad(indent)).append(plainKey(key)).append(": ").append(plain).append('\n');
      } else {
        writeText(b, indent, key, value);
      }
    }

    private void assertNothingLeft() {
      List<String> leftovers = new ArrayList<>();
      for (String p : content.keySet()) {
        leftovers.add("content at `" + p + "`");
      }
      for (String p : forms.keySet()) {
        leftovers.add("form values at `" + p + "`");
      }
      for (String p : lists) {
        leftovers.add("list items at `" + p + "`");
      }
      if (leftovers.isEmpty()) {
        return;
      }
      Collections.sort(leftovers);
      throw new SpecYamlFormatException(
          "document holds values the metadata tree cannot place: "
              + String.join("; ", leftovers));
    }
  }

  // --- Decode ---------------------------------------------------------------

  /**
   * Parses a {@code *.docspecs.yaml} file into its passes, matching every
   * {@code document:} key against {@code tree}.
   *
   * <p>Throws a {@link SpecYamlFormatException} for a missing/unsupported
   * {@code version:} (version 1 is rejected explicitly — the flat format has
   * no compatibility path), for any key the metadata tree cannot place, and
   * for malformed value shapes. A missing/empty {@code document:} pass decodes
   * as an empty document.
   */
  @SuppressWarnings("unchecked")
  public static SpecYamlContents decode(String yamlText, SomMetaTree tree) {
    Object root = yamlText.trim().isEmpty() ? null : Yaml.parse(yamlText);
    if (!(root instanceof Map)) {
      throw new SpecYamlFormatException(
          "not a *.docspecs.yaml mapping (expected version/document keys)");
    }
    Map<String, Object> rootMap = (Map<String, Object>) root;
    boolean hasVersion = rootMap.containsKey("version");
    Object version = rootMap.get("version");
    if (!hasVersion || !parsedScalarStr(version).equals(String.valueOf(FORMAT_VERSION))) {
      if (!hasVersion) {
        throw new SpecYamlFormatException(
            "missing `version:` (expected version: " + FORMAT_VERSION + ")");
      }
      if (parsedScalarStr(version).equals("1")) {
        throw new SpecYamlFormatException(
            "format version 1 (flat path-map) is no longer supported; "
                + "re-save the document in the hierarchical v2 format");
      }
      throw new SpecYamlFormatException(
          "unsupported format version `" + versionRepr(version) + "` (expected "
              + FORMAT_VERSION + ")");
    }

    String stamp = null;
    if (rootMap.containsKey("modelVersion")) {
      String parsed = parsedScalarStr(rootMap.get("modelVersion"));
      stamp = parsed.isEmpty() ? null : parsed;
    }

    Object rawReview = rootMap.get("review");
    Map<String, Object> review =
        rawReview instanceof Map ? (Map<String, Object>) rawReview : new LinkedHashMap<>();

    SpecDocument document = new SpecDocument();
    document.setModelVersion(stamp);
    boolean hasDoc = rootMap.containsKey("document");
    Object docPass = rootMap.get("document");
    if (hasDoc && docPass != null && !(docPass instanceof Map)) {
      throw new SpecYamlFormatException("`document:` must be a mapping");
    }
    if (docPass instanceof Map && !((Map<?, ?>) docPass).isEmpty()) {
      Map<String, Object> docMap = (Map<String, Object>) docPass;
      String rootKey = nodeKey(tree.root);
      List<String> keys = new ArrayList<>(docMap.keySet());
      if (keys.size() != 1 || !keys.get(0).equals(rootKey)) {
        List<String> found = new ArrayList<>(keys.size());
        for (String k : keys) {
          found.add("`" + k + "`");
        }
        throw new SpecYamlFormatException(
            "expected the single document root key `" + rootKey + "`, found: "
                + String.join(", ", found));
      }
      Object body = docMap.get(keys.get(0));
      if (body != null) {
        if (!(body instanceof Map)) {
          throw new SpecYamlFormatException(
              "root `" + rootKey + "` must hold a mapping, not a scalar");
        }
        YamlDecoder d = new YamlDecoder(document);
        d.loadMapping(tree.root, tree.root.segment(), (Map<String, Object>) body);
      }
    }

    return new SpecYamlContents(document, review, stamp);
  }

  /**
   * The raw parsed {@code version:} value rendered for the
   * unsupported-version error message (mirroring JS/TS string interpolation,
   * where a non-scalar mapping renders as {@code "[object Object]"}).
   */
  private static String versionRepr(Object v) {
    if (v instanceof Map) {
      return "[object Object]";
    }
    return parsedScalarStr(v);
  }

  /**
   * One decode run: walks a parsed YAML mapping alongside the metadata tree
   * and populates {@code doc}. Any key that matches nothing at its position is
   * an error.
   */
  private static final class YamlDecoder {
    private final SpecDocument doc;

    YamlDecoder(SpecDocument doc) {
      this.doc = doc;
    }

    void loadMapping(SomMetaNode node, String path, Map<String, Object> body) {
      for (Map.Entry<String, Object> entry : body.entrySet()) {
        String key = entry.getKey();
        Object value = entry.getValue();
        SomMetaNode child = childByKey(node, key);
        if (child != null) {
          loadChild(child, SpecPaths.join(path, child.segment()), key, value);
          continue;
        }
        if (key.equals("content")) {
          doc.setContent(path, scalarOf(value, path + "/content"));
          continue;
        }
        throw new SpecYamlFormatException(
            "key `" + key + "` under `" + path + "` matches no member of "
                + node.debugName() + " (expected one of: "
                + String.join(", ", expectedKeys(node)) + ")");
      }
    }

    private static SomMetaNode childByKey(SomMetaNode node, String key) {
      for (SomMetaNode c : node.children) {
        if (nodeKey(c).equals(key)) {
          return c;
        }
      }
      return null;
    }

    private static List<String> expectedKeys(SomMetaNode node) {
      List<String> out = new ArrayList<>(node.children.size() + 1);
      for (SomMetaNode c : node.children) {
        out.add("`" + nodeKey(c) + "`");
      }
      out.add("`content`");
      return out;
    }

    @SuppressWarnings("unchecked")
    private void loadChild(SomMetaNode child, String path, String key, Object value) {
      switch (child.kind) {
        case SomMetaKind.CONTENT:
        case SomMetaKind.SCALAR:
        case SomMetaKind.ENUM_VALUE:
          doc.setContent(path, scalarOf(value, path));
          return;
        case SomMetaKind.FORM:
          if (!(value instanceof Map)) {
            throw new SpecYamlFormatException(
                "form `" + key + "` at `" + path + "` must hold a field mapping");
          }
          SomFormMeta meta = child.form != null ? child.form : new SomFormMeta(null);
          for (Map.Entry<String, Object> fe : ((Map<String, Object>) value).entrySet()) {
            String name = fe.getKey();
            if (meta.fieldNamed(name) == null) {
              throw new SpecYamlFormatException(
                  "form `" + path + "` has no field `" + name + "` in the model");
            }
            doc.setFormField(path, name, scalarOf(fe.getValue(), path + "." + name));
          }
          return;
        case SomMetaKind.SECTION:
        case SomMetaKind.COMPLEX:
          if (value == null) {
            return;
          }
          if (!(value instanceof Map)) {
            throw new SpecYamlFormatException(
                "section `" + key + "` at `" + path + "` must hold a mapping, "
                    + "not a scalar");
          }
          loadMapping(child, path, (Map<String, Object>) value);
          return;
        case SomMetaKind.LIST:
          if (value == null) {
            return;
          }
          if (!(value instanceof Map)) {
            throw new SpecYamlFormatException(
                "list `" + key + "` at `" + path + "` must hold an item mapping");
          }
          loadList(child, path, (Map<String, Object>) value);
          return;
        default:
          return;
      }
    }

    @SuppressWarnings("unchecked")
    private void loadList(SomMetaNode node, String path, Map<String, Object> items) {
      Pattern anonymous =
          Pattern.compile("^" + Pattern.quote(node.memberName) + "-[0-9]+$");
      for (Map.Entry<String, Object> entry : items.entrySet()) {
        String key = entry.getKey();
        Object value = entry.getValue();
        String itemPath =
            anonymous.matcher(key).matches()
                ? doc.addListItem(path)
                : doc.addListItem(path, key);
        SomMetaNode element = node.elementNode;
        if (element == null) {
          // Scalar list item: the value is the item itself. The hand-rolled
          // parser cannot distinguish a bare `key:` (null) from `key: {}`, so
          // an empty mapping counts as "no value" here (Python raises on an
          // explicit `{}`).
          if (value instanceof List) {
            throw new SpecYamlFormatException(
                "scalar list item `" + key + "` at `" + path + "` must hold a scalar");
          }
          if (value instanceof Map) {
            if (!((Map<?, ?>) value).isEmpty()) {
              throw new SpecYamlFormatException(
                  "scalar list item `" + key + "` at `" + path + "` must hold a scalar");
            }
            continue;
          }
          if (value != null) {
            doc.setContent(itemPath, parsedScalarStr(value));
          }
          continue;
        }
        if (value == null) {
          continue;
        }
        if (!(value instanceof Map)) {
          throw new SpecYamlFormatException(
              "list item `" + key + "` at `" + path + "` must hold a mapping "
                  + "(use `{}` for an empty item)");
        }
        loadMapping(element, itemPath, (Map<String, Object>) value);
      }
    }

    /**
     * Coerces a parsed leaf value to the document's string store. The
     * hand-rolled parser yields an empty mapping for a bare {@code key:}
     * (where a real YAML parser yields null), so an <i>empty</i> mapping
     * counts as the empty string; a populated mapping or a sequence is still a
     * structural error.
     */
    private static String scalarOf(Object value, String where) {
      if (value == null) {
        return "";
      }
      if (value instanceof List) {
        throw new SpecYamlFormatException("expected a scalar value at `" + where + "`");
      }
      if (value instanceof Map) {
        if (((Map<?, ?>) value).isEmpty()) {
          return "";
        }
        throw new SpecYamlFormatException("expected a scalar value at `" + where + "`");
      }
      return parsedScalarStr(value);
    }
  }
}
