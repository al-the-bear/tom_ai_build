package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** One piece a strip removed from a value, anchored in the stripped text (SOM §11.10). */
public final class SpecStripPiece {
  /** The offset (UTF-16) in the stripped text the piece stands at. */
  public final int anchor;
  /** The offset (UTF-16) in the original text the piece starts at. */
  public final int origin;
  /** The original text the piece removed. */
  public final String removed;
  /** The text the stripped value holds in its place. */
  public final String inserted;
  /** What removed it, sorted. */
  public final List<String> labels;

  public SpecStripPiece(
      int anchor, int origin, String removed, String inserted, List<String> labels) {
    this.anchor = anchor;
    this.origin = origin;
    this.removed = removed;
    this.inserted = inserted;
    this.labels = labels;
  }

  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("anchor", anchor);
    out.put("origin", origin);
    out.put("removed", removed);
    out.put("inserted", inserted);
    out.put("labels", new ArrayList<Object>(labels));
    return out;
  }
}
