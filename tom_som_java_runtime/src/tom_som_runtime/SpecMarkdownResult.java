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
  public final List<SpecMarkdownRejection> rejections = new ArrayList<>();
  public final Set<String> rootPrefixes = new LinkedHashSet<>();

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
    return out;
  }
}
