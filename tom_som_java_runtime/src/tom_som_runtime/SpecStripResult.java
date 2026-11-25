package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** The result of {@link SpecDocumentStrip#strip} (SOM §11.10). */
public final class SpecStripResult {
  /** The stripped copy; the document given is unchanged. */
  public final SpecDocument document;
  /** The values the strip changed, with what went. */
  public final List<SpecStrippedValue> values;
  /** The values the emptying rule kept. */
  public final List<SpecStripKept> kept;
  /** The list items left with nothing, removed from the copy. */
  public final List<String> removedItems;
  /** The appendix <em>Notes</em>, numbered through the rendition. */
  public final List<SpecAppendixEntry> appendix;
  /** The elements dropped, per kind. */
  public final Map<String, Integer> dropped;
  /** The elements unmarked, per kind. */
  public final Map<String, Integer> unmarked;
  /** The elements moved to the appendix, per kind. */
  public final Map<String, Integer> appended;
  /** The review marks that went inside a dropped element. */
  public final int marksDropped;
  /** The readable header line of the rendition. */
  public final String readableHeader;
  /** The {@code .readable.md}; {@code null} without a model or a root to export. */
  public final String readable;
  /** Why the stripped document is not valid; empty when it is. */
  public final List<SpecStripFinding> findings;

  public SpecStripResult(
      SpecDocument document,
      List<SpecStrippedValue> values,
      List<SpecStripKept> kept,
      List<String> removedItems,
      List<SpecAppendixEntry> appendix,
      Map<String, Integer> dropped,
      Map<String, Integer> unmarked,
      Map<String, Integer> appended,
      int marksDropped,
      String readableHeader,
      String readable,
      List<SpecStripFinding> findings) {
    this.document = document;
    this.values = values;
    this.kept = kept;
    this.removedItems = removedItems;
    this.appendix = appendix;
    this.dropped = dropped;
    this.unmarked = unmarked;
    this.appended = appended;
    this.marksDropped = marksDropped;
    this.readableHeader = readableHeader;
    this.readable = readable;
    this.findings = findings;
  }

  /** Whether the stripped document is valid and may be written. */
  public boolean ok() {
    return findings.isEmpty();
  }

  /** The report: what was dropped, unmarked, moved and kept per kind. */
  public List<String> report() {
    List<String> out = new ArrayList<>();
    for (String k : SpecDocumentStrip.specStripKindNames) {
      int d = dropped.getOrDefault(k, 0);
      int u = unmarked.getOrDefault(k, 0);
      int a = appended.getOrDefault(k, 0);
      if (d + u + a > 0) {
        out.add(k + ": " + d + " dropped, " + u + " unmarked, " + a + " moved");
      }
    }
    if (marksDropped > 0) {
      out.add("review marks inside dropped elements: " + marksDropped);
    }
    for (SpecStripKept k : kept) {
      out.add(k.toString());
    }
    return out;
  }
}
