package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Reading back what a Phase-4 run wrote: the per-area extract files
 * ({@code codespecs_mapping.md} §1.1.1). {@link CodeSpecsExtract#fromYaml} is
 * the public entry point; {@link CodeSpecsGateRecord} shares the helpers.
 *
 * <p>Both readers <b>refuse</b> an unknown {@code formatVersion}: a later format
 * that moved a key would otherwise read as an extract with no entries, or a
 * scope with no verdicts, and a check with no input passes.
 *
 * <p>The runtime's own dependency-free {@link Yaml} reader (typed mode) does
 * the parsing. It reads a bare {@code key:} as an empty mapping rather than
 * null, so an empty mapping where a scalar or a list is expected reads as
 * absent.
 */
final class CodeSpecsRecordReader {
  private CodeSpecsRecordReader() {}

  /**
   * Parses one {@code <CE-CODE>.extract.yaml}. {@code source} names the file in
   * errors.
   *
   * <p>Only {@code extract.formatVersion} and {@code extract.area.code} are
   * required; any other absent key reads as empty ({@code ""} / an empty list /
   * {@code null} for the optional entry fields). A key that is present with the
   * wrong type is an error, and so is a {@code document.entryCount} that
   * disagrees with the entries.
   */
  @SuppressWarnings("unchecked")
  static CodeSpecsExtract parseExtract(String text, String source) {
    String name = source == null || source.isEmpty() ? "the extract" : source;
    Map<String, Object> root = rootMapping(text, name, "extract");
    Object version = root.get("formatVersion");
    if (!Integer.valueOf(CodeSpecsExtract.FORMAT_VERSION).equals(version)) {
      throw new CodeSpecsRecordError(
          name + " declares extract format " + version + "; this reader understands "
              + CodeSpecsExtract.FORMAT_VERSION
              + " only — reading it would silently drop entries");
    }
    Object areaNode = root.get("area");
    if (!(areaNode instanceof Map)) {
      throw new CodeSpecsRecordError(name + " has no `area:` mapping");
    }
    Map<String, Object> area = (Map<String, Object>) areaNode;
    String code = str(area.get("code"), name, "area.code");
    if (code.isEmpty()) {
      throw new CodeSpecsRecordError(name + " names no area code");
    }
    String part = str(area.get("part"), name, "area.part");
    if (part.startsWith("CodeSpecPart.")) {
      part = part.substring("CodeSpecPart.".length());
    }
    Object documentNode = absent(root.get("document")) ? null : root.get("document");
    if (documentNode != null && !(documentNode instanceof Map)) {
      throw new CodeSpecsRecordError(name + ": `document` must be a mapping");
    }
    Map<String, Object> document = (Map<String, Object>) documentNode;
    Object entriesNode = absent(root.get("entries")) ? null : root.get("entries");
    if (entriesNode != null && !(entriesNode instanceof List)) {
      throw new CodeSpecsRecordError(name + ": `entries` must be a list");
    }
    List<CodeSpecsExtractEntry> entries = new ArrayList<>();
    if (entriesNode != null) {
      for (Object raw : (List<Object>) entriesNode) {
        if (!(raw instanceof Map)) {
          throw new CodeSpecsRecordError(name + " has an entry that is not a mapping");
        }
        Map<String, Object> e = (Map<String, Object>) raw;
        entries.add(
            new CodeSpecsExtractEntry(
                code,
                str(e.get("sectionId"), name, "entries[].sectionId"),
                optStr(e.get("headline"), name, "entries[].headline"),
                optStr(e.get("instanceId"), name, "entries[].instanceId"),
                str(e.get("path"), name, "entries[].path"),
                str(e.get("className"), name, "entries[].className"),
                str(e.get("fieldName"), name, "entries[].fieldName"),
                optStr(e.get("formField"), name, "entries[].formField"),
                str(e.get("routedBy"), name, "entries[].routedBy"),
                str(e.get("routedAt"), name, "entries[].routedAt"),
                optStr(e.get("routingNote"), name, "entries[].routingNote"),
                str(e.get("value"), name, "entries[].value")));
      }
    }
    Object declared = document == null ? null : document.get("entryCount");
    if (declared != null && !Integer.valueOf(entries.size()).equals(declared)) {
      throw new CodeSpecsRecordError(
          name + " declares entryCount " + declared + " but carries " + entries.size()
              + " entries — a truncated extract must not read as a complete one");
    }
    return new CodeSpecsExtract(
        new CodeSpecsArea(
            code,
            str(area.get("canonicalId"), name, "area.canonicalId"),
            part,
            strList(area.get("annotations"), name, "area.annotations"),
            str(area.get("builtOn"), name, "area.builtOn"),
            str(area.get("attributeSurface"), name, "area.attributeSurface"),
            intList(area.get("slices"), name, "area.slices"),
            intList(area.get("authoringSteps"), name, "area.authoringSteps"),
            true),
        str(root.get("catalogSource"), name, "catalogSource"),
        str(document == null ? null : document.get("root"), name, "document.root"),
        strList(area.get("citableParts"), name, "area.citableParts"),
        strList(area.get("projects"), name, "area.projects"),
        Collections.unmodifiableList(entries));
  }

  // --- helpers --------------------------------------------------------------

  /** The mapping under the top-level {@code key} of {@code text}. */
  @SuppressWarnings("unchecked")
  static Map<String, Object> rootMapping(String text, String name, String key) {
    Object document;
    try {
      document = Yaml.parse(text, true);
    } catch (RuntimeException e) {
      throw new CodeSpecsRecordError(name + " is not valid YAML: " + e.getMessage());
    }
    if (!(document instanceof Map) || (((Map<String, Object>) document).isEmpty()
        && !hasContent(text))) {
      throw new CodeSpecsRecordError(name + " does not hold a YAML mapping");
    }
    Object root = ((Map<String, Object>) document).get(key);
    if (!(root instanceof Map)) {
      throw new CodeSpecsRecordError(name + " has no top-level `" + key + ":` mapping");
    }
    return (Map<String, Object>) root;
  }

  /** Whether {@code text} holds any line that is neither blank nor a comment. */
  private static boolean hasContent(String text) {
    for (String l : text.split("\n", -1)) {
      String t = l.trim();
      if (!t.isEmpty() && !t.startsWith("#")) {
        return true;
      }
    }
    return false;
  }

  /**
   * Whether {@code v} stands for an absent value: null, or the empty mapping
   * the {@link Yaml} reader yields for a bare {@code key:}.
   */
  static boolean absent(Object v) {
    return v == null || (v instanceof Map && ((Map<?, ?>) v).isEmpty());
  }

  static String str(Object v, String name, String key) {
    if (absent(v)) {
      return "";
    }
    if (v instanceof String) {
      return (String) v;
    }
    throw new CodeSpecsRecordError(name + ": `" + key + "` must be a string");
  }

  static String optStr(Object v, String name, String key) {
    if (absent(v)) {
      return null;
    }
    if (v instanceof String) {
      return (String) v;
    }
    throw new CodeSpecsRecordError(name + ": `" + key + "` must be a string or null");
  }

  private static List<String> strList(Object v, String name, String key) {
    if (absent(v)) {
      return Collections.emptyList();
    }
    if (!(v instanceof List)) {
      throw new CodeSpecsRecordError(name + ": `" + key + "` must be a list");
    }
    List<String> out = new ArrayList<>();
    for (Object e : (List<?>) v) {
      out.add(str(e, name, key));
    }
    return Collections.unmodifiableList(out);
  }

  private static List<Integer> intList(Object v, String name, String key) {
    if (absent(v)) {
      return Collections.emptyList();
    }
    if (!(v instanceof List)) {
      throw new CodeSpecsRecordError(name + ": `" + key + "` must be a list");
    }
    List<Integer> out = new ArrayList<>();
    for (Object e : (List<?>) v) {
      if (!(e instanceof Integer)) {
        throw new CodeSpecsRecordError(name + ": `" + key + "` must hold integers");
      }
      out.add((Integer) e);
    }
    return Collections.unmodifiableList(out);
  }
}
