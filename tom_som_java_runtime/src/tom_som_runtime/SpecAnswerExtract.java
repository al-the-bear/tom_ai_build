package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** The answer extraction of one document (SOM §11.9.7). */
public final class SpecAnswerExtract {
  /** The document's label in {@code answers.md} (e.g. {@code tom_uam.sbp}). */
  public final String label;

  /** The document root's section id, written in front of a comment id ({@code SBP C-12}). */
  public final String qualifier;

  /** Every entry, in document order. */
  public final List<SpecAnswerEntry> entries;

  public SpecAnswerExtract(String label, String qualifier, List<SpecAnswerEntry> entries) {
    this.label = label;
    this.qualifier = qualifier;
    this.entries = Collections.unmodifiableList(new ArrayList<>(entries));
  }

  /** The counts over {@link #entries}. */
  public SpecAnswerCounts counts() {
    int a = 0;
    int o = 0;
    int c = 0;
    int m = 0;
    for (SpecAnswerEntry e : entries) {
      switch (e.kind) {
        case ANSWERED:
          a++;
          break;
        case OPEN:
          o++;
          break;
        case COMMENT:
          c++;
          break;
        case MARK:
          m++;
          break;
      }
    }
    return new SpecAnswerCounts(a, o, c, m);
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("label", label);
    out.put("qualifier", qualifier);
    List<Object> es = new ArrayList<>();
    for (SpecAnswerEntry e : entries) {
      es.add(e.toJson());
    }
    out.put("entries", es);
    out.put("counts", counts().toJson());
    return out;
  }
}
