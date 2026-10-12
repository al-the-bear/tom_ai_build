package tom_som_runtime;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * The result of {@link SpecDocument#moveListItem} — a port of
 * {@code SpecListItemMove} in {@code spec_document.dart}.
 */
public final class SpecListItemMove {
  /** The moved item's path after the move. */
  public final String path;

  /**
   * Every item path the move changed, old → new: the moved item and each
   * sibling whose position moved. Values under a renamed item moved with it.
   */
  public final Map<String, String> renamed;

  /**
   * The items (by new path) that were anonymous and now store the id they had
   * by position, so their identity did not change with their position.
   */
  public final Map<String, String> pinnedIds;

  /** Creates a result; the maps are copied, in their iteration order. */
  public SpecListItemMove(
      String path, Map<String, String> renamed, Map<String, String> pinnedIds) {
    this.path = path;
    this.renamed = Collections.unmodifiableMap(new LinkedHashMap<>(renamed));
    this.pinnedIds = Collections.unmodifiableMap(new LinkedHashMap<>(pinnedIds));
  }
}
