package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * A class kept in sync between the Blueprint and a Phase 3 document: its
 * position in each root.
 */
public final class SpecSyncPair {
  /** The class carrying {@code @SyncedWith} / {@code @DetailedIn}. */
  public final String className;
  /** Its section id: the name of the pair in findings and filters. */
  public final String sectionId;
  /** The anchor in the Blueprint root (list items written {@code <list>-*}). */
  public final String blueprintAnchor;
  /** The anchor in the Phase 3 root. */
  public final String detailAnchor;
  /** The Phase 3 root's class name. */
  public final String detailRoot;
  /** The class's {@code @SyncedWith}, or {@code null} when only {@code @DetailedIn} is declared. */
  public final SpecSync sync;

  public SpecSyncPair(
      String className,
      String sectionId,
      String blueprintAnchor,
      String detailAnchor,
      String detailRoot,
      SpecSync sync) {
    this.className = className;
    this.sectionId = sectionId;
    this.blueprintAnchor = blueprintAnchor;
    this.detailAnchor = detailAnchor;
    this.detailRoot = detailRoot;
    this.sync = sync;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("pair", sectionId);
    out.put("className", className);
    out.put("blueprint", blueprintAnchor);
    out.put("detail", detailAnchor);
    out.put("detailRoot", detailRoot);
    return out;
  }
}
