package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * The Stage-B gate record, {@code gate.verdicts.yaml}
 * ({@code codespecs_prompt.md} §6.3).
 *
 * <p>Constructing one checks it: every area is a {@code CE-*} code named once,
 * and a {@code resolution:} appears only as {@code descoped} on an insufficient
 * area. So a record that exists is a record of the checked shape, whether it
 * was read or built to be written.
 */
public final class CodeSpecsGateRecord {
  /**
   * The file name of the gate record, written beside the extracts. Fixed so a
   * partial pass cannot hide its record under a name no reader looks for.
   */
  public static final String FILE_NAME = "gate.verdicts.yaml";

  /** The gate record {@code formatVersion} this runtime reads and writes. */
  public static final int FORMAT_VERSION = 1;

  private static final Pattern AREA_CODE = Pattern.compile("^CE-[A-Z]+$");

  private static final List<String> ENTRY_KEYS =
      List.of("area", "verdict", "resolution", "note");

  /** The verdicts, in the order they were recorded. */
  public final List<CodeSpecsGateEntry> verdicts;

  /**
   * Creates and checks a record; throws {@link CodeSpecsRecordError} on a shape
   * {@code codespecs_prompt.md} §6.3 does not allow.
   */
  public CodeSpecsGateRecord(List<CodeSpecsGateEntry> verdicts) {
    this(verdicts, FILE_NAME);
  }

  /** As {@link #CodeSpecsGateRecord(List)}; {@code source} names it in errors. */
  public CodeSpecsGateRecord(List<CodeSpecsGateEntry> verdicts, String source) {
    this.verdicts = Collections.unmodifiableList(new ArrayList<>(verdicts));
    check(source);
  }

  /** Parses {@code gate.verdicts.yaml}. */
  public static CodeSpecsGateRecord fromYaml(String text) {
    return fromYaml(text, FILE_NAME);
  }

  /** Parses {@code gate.verdicts.yaml}; {@code source} names the file in errors. */
  @SuppressWarnings("unchecked")
  public static CodeSpecsGateRecord fromYaml(String text, String source) {
    Map<String, Object> root = CodeSpecsRecordReader.rootMapping(text, source, "gate");
    for (String key : root.keySet()) {
      if (!key.equals("formatVersion") && !key.equals("verdicts")) {
        throw new CodeSpecsRecordError(
            source + " has an unknown key `gate." + key + "` — the record knows "
                + "`formatVersion` and `verdicts` only");
      }
    }
    Object version = root.get("formatVersion");
    if (!Integer.valueOf(FORMAT_VERSION).equals(version)) {
      throw new CodeSpecsRecordError(
          source + " declares gate record format " + version + "; this reader "
              + "understands " + FORMAT_VERSION + " only — reading it would "
              + "silently change the scope");
    }
    Object list = root.get("verdicts");
    if (!(list instanceof List)) {
      throw new CodeSpecsRecordError(source + " has no `verdicts:` list");
    }
    List<CodeSpecsGateEntry> entries = new ArrayList<>();
    for (Object rawObj : (List<Object>) list) {
      if (!(rawObj instanceof Map)) {
        throw new CodeSpecsRecordError(source + " has a verdict that is not a mapping");
      }
      Map<String, Object> raw = (Map<String, Object>) rawObj;
      for (String key : raw.keySet()) {
        if (!ENTRY_KEYS.contains(key)) {
          throw new CodeSpecsRecordError(
              source + " has an unknown key `" + key + "` in a verdict — an entry knows "
                  + "`area`, `verdict`, `resolution` and `note` only");
        }
      }
      String area = CodeSpecsRecordReader.str(raw.get("area"), source, "verdicts[].area");
      String word = CodeSpecsRecordReader.str(raw.get("verdict"), source, "verdicts[].verdict");
      CodeSpecsGateVerdict verdict = CodeSpecsGateVerdict.parse(word);
      if (verdict == null) {
        throw new CodeSpecsRecordError(
            source + " gives " + area + " the verdict `" + word + "` — codespecs_prompt.md "
                + "§6.2 knows `sufficient`, `not applicable` and `insufficient` only");
      }
      entries.add(
          new CodeSpecsGateEntry(
              area,
              verdict,
              CodeSpecsRecordReader.optStr(
                  raw.get("resolution"), source, "verdicts[].resolution"),
              CodeSpecsRecordReader.optStr(raw.get("note"), source, "verdicts[].note")));
    }
    return new CodeSpecsGateRecord(entries, source);
  }

  private void check(String source) {
    Set<String> seen = new HashSet<>();
    for (CodeSpecsGateEntry e : verdicts) {
      if (e.area == null || e.area.isEmpty()) {
        throw new CodeSpecsRecordError(source + " has a verdict that names no area");
      }
      if (!AREA_CODE.matcher(e.area).matches()) {
        throw new CodeSpecsRecordError(
            source + " names the area `" + e.area + "`, which is not a CE-* code");
      }
      if (!seen.add(e.area)) {
        throw new CodeSpecsRecordError(
            source + " carries two verdicts for " + e.area + " — a scope with two "
                + "answers for one area is no scope");
      }
      if (e.resolution == null) {
        continue;
      }
      if (e.verdict != CodeSpecsGateVerdict.INSUFFICIENT) {
        throw new CodeSpecsRecordError(
            source + " gives " + e.area + " a `resolution:` on verdict "
                + "`" + e.verdict.word + "` — only an insufficient area has an L0 decision "
                + "to resolve");
      }
      if (!e.resolution.equals(CodeSpecsGateEntry.DESCOPED)) {
        throw new CodeSpecsRecordError(
            source + " gives " + e.area + " the resolution `" + e.resolution + "` — `descoped` "
                + "is the one resolution that admits a partial pass; any other "
                + "resolution means the area was completed and its verdict re-taken");
      }
    }
  }

  /** The entry for {@code area}, or {@code null} when the record says nothing about it. */
  public CodeSpecsGateEntry verdictFor(String area) {
    for (CodeSpecsGateEntry e : verdicts) {
      if (e.area.equals(area)) {
        return e;
      }
    }
    return null;
  }

  /**
   * Throws {@link CodeSpecsRecordError} when an area is not an active area of
   * {@code catalog} — a verdict for an area that does not exist scopes nothing.
   */
  public void checkAgainst(CodeSpecsAreaCatalog catalog) {
    checkAgainst(catalog, FILE_NAME);
  }

  /** As {@link #checkAgainst(CodeSpecsAreaCatalog)}; {@code source} names the record. */
  public void checkAgainst(CodeSpecsAreaCatalog catalog, String source) {
    for (CodeSpecsGateEntry e : verdicts) {
      CodeSpecsArea area = catalog.byCode(e.area);
      if (area == null || !area.active) {
        throw new CodeSpecsRecordError(
            source + " gives a verdict for " + e.area + ", which is not an active "
                + "area of the catalogue");
      }
    }
  }

  /**
   * A copy with {@code entry} recorded — replacing the area's earlier verdict in
   * place, or appended when the area had none.
   */
  public CodeSpecsGateRecord withVerdict(CodeSpecsGateEntry entry) {
    List<CodeSpecsGateEntry> out = new ArrayList<>();
    boolean replaced = false;
    for (CodeSpecsGateEntry e : verdicts) {
      if (e.area.equals(entry.area)) {
        out.add(entry);
        replaced = true;
      } else {
        out.add(e);
      }
    }
    if (!replaced) {
      out.add(entry);
    }
    return new CodeSpecsGateRecord(out);
  }

  /**
   * The record as {@code gate.verdicts.yaml}. Byte-stable: the same record
   * always writes the same text, and {@code fromYaml(r.toYaml()).toYaml()}
   * equals {@code r.toYaml()}.
   *
   * <p>{@code area} and {@code verdict} are written plain — both are from a
   * closed vocabulary the constructor checked — and a note as a double-quoted
   * scalar, the extract's one escaping rule.
   */
  public String toYaml() {
    StringBuilder b = new StringBuilder();
    b.append("gate:\n");
    b.append("  formatVersion: ").append(FORMAT_VERSION).append('\n');
    if (verdicts.isEmpty()) {
      b.append("  verdicts: []\n");
      return b.toString();
    }
    b.append("  verdicts:\n");
    for (CodeSpecsGateEntry e : verdicts) {
      b.append("    - area: ").append(e.area).append('\n');
      b.append("      verdict: ").append(e.verdict.word).append('\n');
      if (e.resolution != null) {
        b.append("      resolution: ").append(e.resolution).append('\n');
      }
      if (e.note != null) {
        b.append("      note: ").append(CodeSpecsExtract.yamlString(e.note)).append('\n');
      }
    }
    return b.toString();
  }
}
