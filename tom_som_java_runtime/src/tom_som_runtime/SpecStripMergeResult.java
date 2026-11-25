package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/** The result of {@link SpecStripMerge#merge} (SOM §11.10). */
public final class SpecStripMergeResult {
  /** The merged document; {@code null} when nothing may be written. */
  public final SpecDocument document;
  /** The switches the rendition was stripped with. */
  public final SpecStripOptions options;
  /** Whether the merge was three-way from the original at the export. */
  public final boolean stale;

  public final List<SpecStripMergedValue> merged;
  public final List<SpecStripMergeConflict> conflicts;
  public final List<SpecStripMergeRefusal> refusals;

  public SpecStripMergeResult(
      SpecDocument document,
      SpecStripOptions options,
      boolean stale,
      List<SpecStripMergedValue> merged,
      List<SpecStripMergeConflict> conflicts,
      List<SpecStripMergeRefusal> refusals) {
    this.document = document;
    this.options = options;
    this.stale = stale;
    this.merged = merged;
    this.conflicts = conflicts;
    this.refusals = refusals;
  }

  /** Whether the merge has neither conflicts nor refusals. */
  public boolean ok() {
    return conflicts.isEmpty() && refusals.isEmpty();
  }

  /** {@code 0} merged or nothing to merge, {@code 1} conflicts or refusals. */
  public int exitCode() {
    return ok() ? 0 : 1;
  }

  /** The report: a line per merged value and placed piece, the conflicts, the refusals. */
  public List<String> report() {
    List<String> out = new ArrayList<>();
    for (SpecStripMergedValue m : merged) {
      String label = SpecStripMerge.specStripMergeLabel(m.ref);
      out.add("MERGED " + label + " — " + m.restored + " pieces put back");
      for (int k = 0; k < m.placed.size(); k++) {
        out.add("PLACED " + label + " — check");
      }
    }
    for (SpecStripMergeConflict c : conflicts) {
      out.addAll(c.reportLines());
    }
    for (SpecStripMergeRefusal r : refusals) {
      out.add(r.reportLine());
    }
    return out;
  }
}
