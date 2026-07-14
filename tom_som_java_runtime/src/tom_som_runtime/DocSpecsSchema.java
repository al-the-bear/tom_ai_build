package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * A loaded {@code *.docspecs-schema.yaml} schema — a faithful port of the Go
 * {@code DocSpecsSchema} (DR7/DR14/DR17 parity chain). Unsupported keys are
 * collected as §7 warnings; loading never fails on extra keys.
 *
 * <p>Java conventions: {@code null} stands in for Go's {@code ""} on the
 * absent {@link #titleFormat}; the one throwing entry point
 * ({@link #fromYamlText}'s "must be a YAML map") throws
 * {@link IllegalStateException} where Go returns an error.
 * {@link #formTypes} / {@link #documentSections} are {@link LinkedHashMap}s,
 * so they keep the schema file order the other ports iterate.
 */
public final class DocSpecsSchema {
  private static final Pattern ID_TRANSFORM = Pattern.compile("[^a-zA-Z0-9_]+");
  private static final Pattern ROOT_ID = Pattern.compile("<!--\\[([^\\]]+)\\]-->");

  private static final Set<String> SECTION_TYPE_KEYS =
      Set.of(
          "prefix",
          "pattern-check-id",
          "subsection-types",
          "format",
          "text-required",
          "min-text-length",
          "max-text-length",
          "description",
          "validation-prompt");

  /** The schema's {@code title-format}, {@code null} when absent. */
  public String titleFormat;

  /** The section types in file order. */
  public final List<DocSpecsSectionType> sectionTypes = new ArrayList<>();

  public final Map<String, DocSpecsSectionType> sectionTypesByName = new LinkedHashMap<>();
  public final Map<String, DocSpecsFormType> formTypes = new LinkedHashMap<>();
  public final Map<String, DocSpecsDocumentSection> documentSections = new LinkedHashMap<>();

  /** §7 warnings for unsupported keys. */
  public final List<String> warnings = new ArrayList<>();

  private DocSpecsSchema() {}

  /**
   * The DocSpecs id transform: every run of non-alphanumeric/underscore
   * characters becomes a single {@code _}.
   */
  public static String idTransform(String id) {
    return ID_TRANSFORM.matcher(id).replaceAll("_");
  }

  /** The section id embedded in {@link #titleFormat}, {@code null} when none. */
  public String rootSectionId() {
    if (titleFormat == null || titleFormat.isEmpty()) {
      return null;
    }
    Matcher m = ROOT_ID.matcher(titleFormat);
    if (m.find()) {
      return m.group(1);
    }
    return null;
  }

  /**
   * Loads a schema from YAML text. Unknown keys warn; a non-map root throws
   * {@link IllegalStateException} (the other ports' throw / Go's error).
   */
  public static DocSpecsSchema fromYamlText(String text) {
    Object parsed = Yaml.parse(text);
    if (!(parsed instanceof Map)
        || (((Map<?, ?>) parsed).isEmpty()
            && !text.trim().isEmpty()
            && !text.contains(":"))) {
      throw new IllegalStateException("docspecs schema must be a YAML map");
    }
    @SuppressWarnings("unchecked")
    Map<String, Object> data = (Map<String, Object>) parsed;
    DocSpecsSchema schema = new DocSpecsSchema();
    for (Map.Entry<String, Object> entry : data.entrySet()) {
      String k = entry.getKey();
      Object v = entry.getValue();
      switch (k) {
        case "title-format":
          schema.titleFormat = str(v);
          break;
        case "section-types":
          schema.loadSectionTypes(v);
          break;
        case "form-types":
          schema.loadFormTypes(v);
          break;
        case "document":
          schema.loadDocument(v);
          break;
        case "schema":
        case "version":
        case "name":
        case "description":
          // informational keys — accepted, unused
          break;
        default:
          schema.warnings.add("unsupported top-level schema key \"" + k + "\" ignored");
      }
    }
    return schema;
  }

  /** Coerces a parsed yaml scalar to its string form ({@code null} for absent). */
  private static String str(Object v) {
    if (v instanceof String) {
      return (String) v;
    }
    if (v instanceof Integer) {
      return String.valueOf(v);
    }
    return null;
  }

  /** Accepts a plain-scalar {@code "true"} string — the bundled yaml parser
   * keeps plain booleans as strings, matching the other ports' behaviour. */
  private static boolean isTrue(Object v) {
    return "true".equals(v);
  }

  private static Integer asInt(Object v) {
    return v instanceof Integer ? (Integer) v : null;
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> asMap(Object v) {
    return v instanceof Map ? (Map<String, Object>) v : null;
  }

  private static DocSpecsPatternCheck patternCheck(Object node) {
    if (node == null) {
      return null;
    }
    Map<String, Object> m = asMap(node);
    if (m != null) {
      return new DocSpecsPatternCheck(str(m.get("pattern")), str(m.get("error-message")));
    }
    return new DocSpecsPatternCheck(str(node), null);
  }

  private void loadSectionTypes(Object node) {
    Map<String, Object> m = asMap(node);
    if (m == null) {
      return;
    }
    for (Map.Entry<String, Object> entry : m.entrySet()) {
      String name = entry.getKey();
      Map<String, Object> raw = asMap(entry.getValue());
      if (raw == null) {
        continue;
      }
      Map<String, DocSpecsSubsectionRule> subs = new LinkedHashMap<>();
      Map<String, Object> subNode = asMap(raw.get("subsection-types"));
      if (subNode != null) {
        for (Map.Entry<String, Object> subEntry : subNode.entrySet()) {
          int minCount = 0;
          Integer maxCount = null;
          Map<String, Object> subRaw = asMap(subEntry.getValue());
          if (subRaw != null) {
            Integer n = asInt(subRaw.get("min-count"));
            if (n != null) {
              minCount = n;
            }
            maxCount = asInt(subRaw.get("max-count"));
          }
          subs.put(subEntry.getKey(), new DocSpecsSubsectionRule(minCount, maxCount));
        }
      }
      for (String key : raw.keySet()) {
        if (!SECTION_TYPE_KEYS.contains(key)) {
          warnings.add("unsupported key \"" + key + "\" on section-type \"" + name + "\" ignored");
        }
      }
      String prefix = idTransform(name.toUpperCase());
      if (raw.containsKey("prefix")) {
        String p = str(raw.get("prefix"));
        prefix = p == null ? "" : p;
      }
      DocSpecsSectionType t =
          new DocSpecsSectionType(
              name,
              prefix,
              patternCheck(raw.get("pattern-check-id")),
              subs,
              str(raw.get("format")),
              isTrue(raw.get("text-required")),
              asInt(raw.get("min-text-length")),
              asInt(raw.get("max-text-length")),
              str(raw.get("description")),
              str(raw.get("validation-prompt")));
      sectionTypes.add(t);
      sectionTypesByName.put(name, t);
    }
  }

  private void loadFormTypes(Object node) {
    Map<String, Object> m = asMap(node);
    if (m == null) {
      return;
    }
    for (Map.Entry<String, Object> entry : m.entrySet()) {
      String name = entry.getKey();
      Map<String, Object> raw = asMap(entry.getValue());
      if (raw == null) {
        continue;
      }
      for (String key : raw.keySet()) {
        if (!key.equals("fields")) {
          warnings.add("unsupported key \"" + key + "\" on form-type \"" + name + "\" ignored");
        }
      }
      List<DocSpecsFormField> fields = new ArrayList<>();
      if (raw.get("fields") instanceof List) {
        for (Object f : (List<?>) raw.get("fields")) {
          Map<String, Object> fm = asMap(f);
          if (fm == null) {
            continue;
          }
          String fieldName = str(fm.get("fieldname"));
          fields.add(
              new DocSpecsFormField(
                  fieldName == null ? "" : fieldName,
                  isTrue(fm.get("required")),
                  str(fm.get("description")),
                  patternCheck(fm.get("pattern-check"))));
        }
      }
      formTypes.put(name, new DocSpecsFormType(name, fields));
    }
  }

  private void loadDocument(Object node) {
    Map<String, Object> m = asMap(node);
    if (m == null) {
      return;
    }
    for (Map.Entry<String, Object> entry : m.entrySet()) {
      String k = entry.getKey();
      Object v = entry.getValue();
      if (k.equals("sections")) {
        Map<String, Object> sections = asMap(v);
        if (sections == null) {
          continue;
        }
        for (Map.Entry<String, Object> sEntry : sections.entrySet()) {
          String sKey = sEntry.getKey();
          String sectionType = sKey;
          boolean optional = false;
          Map<String, Object> sRaw = asMap(sEntry.getValue());
          if (sRaw != null) {
            if (sRaw.containsKey("section-type")) {
              String st = str(sRaw.get("section-type"));
              sectionType = st == null ? "" : st;
            }
            optional = isTrue(sRaw.get("optional"));
          }
          documentSections.put(sKey, new DocSpecsDocumentSection(sectionType, optional));
        }
      } else if (!k.equals("name") && !k.equals("description")) {
        warnings.add("unsupported document key \"" + k + "\" ignored");
      }
    }
  }

  /**
   * Resolves a section id to its section-type by first-startsWith prefix match
   * over {@link #idTransform}'d ids; {@code null} when none matches.
   */
  public DocSpecsSectionType resolveSectionType(String id) {
    String transformed = idTransform(id);
    for (DocSpecsSectionType t : sectionTypes) {
      if (transformed.startsWith(t.prefix)) {
        return t;
      }
    }
    return null;
  }
}
