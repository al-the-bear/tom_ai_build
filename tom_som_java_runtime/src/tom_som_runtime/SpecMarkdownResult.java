package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * The outcome of parsing a Markdown document: the staged values plus every
 * rejected block. The values are keyed exactly like {@link SpecDocument#toJson}.
 */
public final class SpecMarkdownResult {
  public final Map<String, String> content = new LinkedHashMap<>();
  public final Map<String, Map<String, String>> forms = new LinkedHashMap<>();
  public final Map<String, Object> lists = new LinkedHashMap<>();

  /**
   * Stored headlines staged from heading titles that differ from their
   * effective default (SOM §11.7) — path → headline.
   */
  public final Map<String, String> headlines = new LinkedHashMap<>();

  /**
   * Stored codeSpec mappings staged from the {@code codeSpec="…"} key in
   * heading comments (codespecs_mapping.md §9.2) — path → comma-joined code
   * locations. Staged whenever present (codeSpec has no effective default).
   */
  public final Map<String, String> codeSpecs = new LinkedHashMap<>();

  /**
   * Stored generation units (SOM §11.2) staged from the {@code units="…"} key
   * in heading comments — path → comma-joined generation-unit ids. Staged
   * whenever present (absent means the default).
   */
  public final Map<String, String> units = new LinkedHashMap<>();
  public final List<SpecMarkdownRejection> rejections = new ArrayList<>();
  public final Set<String> rootPrefixes = new LinkedHashSet<>();

  /**
   * The rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): for every
   * path whose text a rejected block stood in, the value with each such block
   * written as a {@code rejected} div at its place. An apply that accepts
   * rejections ({@link SpecDocument#applyMarkdownResult(SpecMarkdownResult,
   * boolean)} with {@code true}) writes these over {@link #content}, so nothing
   * written is lost; an empty value removes the path's text. Empty for a clean
   * parse.
   */
  public final Map<String, String> keptContent = new LinkedHashMap<>();

  /**
   * The readable header line of a stripped rendition (SOM §11.1), when the
   * text carried one before its root heading; the parser skipped it.
   * {@code null} when none.
   */
  public String readableHeader;

  public boolean isClean() {
    return rejections.isEmpty();
  }

  public int appliedCount() {
    int n = content.size();
    for (Map<String, String> m : forms.values()) {
      n += m.size();
    }
    return n;
  }

  /** A {@link SpecDocument#loadJson}-shaped view of the staged values. */
  public Map<String, Object> toLoadJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("content", content);
    out.put("forms", forms);
    out.put("lists", lists);
    out.put("headlines", headlines);
    out.put("codeSpecs", codeSpecs);
    out.put("units", units);
    return out;
  }
}
