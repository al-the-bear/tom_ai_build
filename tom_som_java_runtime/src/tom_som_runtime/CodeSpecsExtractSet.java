package tom_som_runtime;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractMap;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/** Every extract one run produced, read back and scoped by its gate record. */
public final class CodeSpecsExtractSet {
  /**
   * The in-scope extracts. With a gate record: the areas it marks
   * {@code sufficient}, in the record's order. Without: every extract, in
   * source order.
   */
  public final List<CodeSpecsExtract> extracts;

  /** The file each in-scope extract was read from, parallel to {@link #extracts}. */
  public final List<String> sources;

  /** The areas the gate record excluded — empty without a record. */
  public final List<CodeSpecsExcludedArea> excluded;

  /** The gate record, when one was among the sources; otherwise {@code null}. */
  public final CodeSpecsGateRecord gate;

  private CodeSpecsExtractSet(
      List<CodeSpecsExtract> extracts,
      List<String> sources,
      List<CodeSpecsExcludedArea> excluded,
      CodeSpecsGateRecord gate) {
    this.extracts = Collections.unmodifiableList(extracts);
    this.sources = Collections.unmodifiableList(sources);
    this.excluded = Collections.unmodifiableList(excluded);
    this.gate = gate;
  }

  /** As {@link #fromFiles(List)}, over a map's entries in its iteration order. */
  public static CodeSpecsExtractSet fromFiles(Map<String, String> files) {
    return fromFiles(new ArrayList<Map.Entry<String, String>>(files.entrySet()));
  }

  /**
   * Reads {@code files} — an ordered sequence of (file name, text) — into a
   * scoped set.
   *
   * <p>The file whose basename is {@link CodeSpecsGateRecord#FILE_NAME} is the
   * gate record; every other file is an extract. The area code comes from the
   * file's content, never its name. With a record, an area is in scope
   * <b>iff</b> its verdict is {@code sufficient}, and:
   *
   * <ul>
   *   <li>the record must carry a verdict for every extract supplied — a scope
   *       silent about an area would let a skipped area read as a passed one;
   *   <li>a {@code not applicable} area whose extract has entries is an error —
   *       a routed value is evidence the area applies
   *       ({@code codespecs_prompt.md} §6.4);
   *   <li>an {@code insufficient} area without {@code resolution: descoped} is
   *       an error — the run may not have continued past it
   *       ({@code codespecs_prompt.md} §6.2).
   * </ul>
   *
   * <p>Two extracts for one area, or two gate records, are errors.
   */
  public static CodeSpecsExtractSet fromFiles(List<? extends Map.Entry<String, String>> files) {
    String gateName = null;
    String gateText = null;
    List<CodeSpecsExtract> extracts = new ArrayList<>();
    List<String> sources = new ArrayList<>();
    for (Map.Entry<String, String> entry : files) {
      String key = entry.getKey();
      String basename = key.substring(key.lastIndexOf('/') + 1);
      if (basename.equals(CodeSpecsGateRecord.FILE_NAME)) {
        if (gateName != null) {
          throw new CodeSpecsRecordError(
              "both " + gateName + " and " + key + " are gate records — the scope "
                  + "must have one author");
        }
        gateName = key;
        gateText = entry.getValue();
        continue;
      }
      CodeSpecsExtract x = CodeSpecsExtract.fromYaml(entry.getValue(), key);
      int earlier = indexOfArea(extracts, x.area.code);
      if (earlier >= 0) {
        throw new CodeSpecsRecordError(
            sources.get(earlier) + " and " + key + " are both extracts for " + x.area.code);
      }
      extracts.add(x);
      sources.add(key);
    }
    if (gateName == null) {
      return new CodeSpecsExtractSet(
          extracts, sources, new ArrayList<CodeSpecsExcludedArea>(), null);
    }
    CodeSpecsGateRecord gate = CodeSpecsGateRecord.fromYaml(gateText, gateName);
    for (int i = 0; i < extracts.size(); i++) {
      if (gate.verdictFor(extracts.get(i).area.code) == null) {
        throw new CodeSpecsRecordError(
            gateName + " carries no verdict for " + extracts.get(i).area.code
                + " (" + sources.get(i) + ") — the gate record must be total over the supplied "
                + "extracts");
      }
    }
    List<CodeSpecsExtract> inScope = new ArrayList<>();
    List<String> inScopeSources = new ArrayList<>();
    List<CodeSpecsExcludedArea> excluded = new ArrayList<>();
    for (CodeSpecsGateEntry v : gate.verdicts) {
      int i = indexOfArea(extracts, v.area);
      CodeSpecsExtract x = i < 0 ? null : extracts.get(i);
      String src = i < 0 ? "" : sources.get(i);
      int count = x == null ? 0 : x.entries.size();
      switch (v.verdict) {
        case SUFFICIENT:
          if (x != null) {
            inScope.add(x);
            inScopeSources.add(src);
          }
          break;
        case NOT_APPLICABLE:
          if (count > 0) {
            throw new CodeSpecsRecordError(
                gateName + " marks " + v.area + " `not applicable`, but " + src + " carries "
                    + count + " routed entr" + (count == 1 ? "y" : "ies") + " — a routed value is "
                    + "evidence the area applies (codespecs_prompt.md §6.4)");
          }
          excluded.add(new CodeSpecsExcludedArea(v.area, v.verdict, false, count, src));
          break;
        case INSUFFICIENT:
          if (!v.descoped()) {
            throw new CodeSpecsRecordError(
                gateName + " marks " + v.area + " `insufficient` without `resolution: "
                    + "descoped` — codespecs_prompt.md §6.2 says the run does not "
                    + "continue past an unresolved insufficient area; recording the "
                    + "descope is what legitimizes a partial pass");
          }
          excluded.add(new CodeSpecsExcludedArea(v.area, v.verdict, true, count, src));
          break;
        default:
          throw new IllegalStateException(String.valueOf(v.verdict));
      }
    }
    return new CodeSpecsExtractSet(inScope, inScopeSources, excluded, gate);
  }

  /**
   * Reads a directory of extracts — {@code <CE-CODE>.extract.yaml} plus an
   * optional {@code gate.verdicts.yaml}; other files (the {@code .extract.md}
   * views) are ignored. Files are read in name order, so the set is the same on
   * every file system.
   */
  public static CodeSpecsExtractSet fromDirectory(String path) {
    Path dir = Paths.get(path);
    if (!Files.isDirectory(dir)) {
      throw new CodeSpecsRecordError("extract directory not found: " + path);
    }
    List<String> names = new ArrayList<>();
    try (DirectoryStream<Path> stream = Files.newDirectoryStream(dir)) {
      for (Path p : stream) {
        if (!Files.isRegularFile(p)) {
          continue;
        }
        String n = p.getFileName().toString();
        if (n.endsWith(CodeSpecsExtract.FILE_SUFFIX) || n.equals(CodeSpecsGateRecord.FILE_NAME)) {
          names.add(n);
        }
      }
    } catch (IOException e) {
      throw new CodeSpecsRecordError("extract directory not readable: " + path + ": " + e.getMessage());
    }
    Collections.sort(names);
    List<Map.Entry<String, String>> files = new ArrayList<>();
    for (String n : names) {
      try {
        files.add(
            new AbstractMap.SimpleImmutableEntry<>(
                n, new String(Files.readAllBytes(dir.resolve(n)), StandardCharsets.UTF_8)));
      } catch (IOException e) {
        throw new CodeSpecsRecordError(n + " is not readable: " + e.getMessage());
      }
    }
    return fromFiles(files);
  }

  /** The in-scope extract for {@code area}, or {@code null}. */
  public CodeSpecsExtract byArea(String area) {
    int i = indexOfArea(extracts, area);
    return i < 0 ? null : extracts.get(i);
  }

  /**
   * Every in-scope entry routed from {@code sectionId} — the back-link token a
   * {@code DocRef} names — across every area, in extract order.
   */
  public List<CodeSpecsExtractEntry> entriesForSection(String sectionId) {
    List<CodeSpecsExtractEntry> out = new ArrayList<>();
    for (CodeSpecsExtract x : extracts) {
      for (CodeSpecsExtractEntry e : x.entries) {
        if (e.sectionId.equals(sectionId)) {
          out.add(e);
        }
      }
    }
    return out;
  }

  /** Every in-scope entry read from document {@code path}, in extract order. */
  public List<CodeSpecsExtractEntry> entriesAtPath(String path) {
    List<CodeSpecsExtractEntry> out = new ArrayList<>();
    for (CodeSpecsExtract x : extracts) {
      for (CodeSpecsExtractEntry e : x.entries) {
        if (e.path.equals(path)) {
          out.add(e);
        }
      }
    }
    return out;
  }

  private static int indexOfArea(List<CodeSpecsExtract> extracts, String area) {
    for (int i = 0; i < extracts.size(); i++) {
      if (extracts.get(i).area.code.equals(area)) {
        return i;
      }
    }
    return -1;
  }
}
