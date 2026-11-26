package tom_som_runtime;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * A document side of a {@link SpecSyncPair}: its subtree's values and items,
 * keyed by the path below the anchor with list items written by their section
 * id ({@code LIST[id]}).
 */
public final class SpecSetSide {
  public final String name;
  public final String root;
  public final String anchor;
  /** The values by key ({@code c:} content, {@code f:} form field, {@code h:} headline). */
  public final Map<String, SpecSetValue> values = new HashMap<>();
  /** Item key → item path, and the anchor's own key {@code ""}. */
  public final Map<String, String> items = new HashMap<>();
  /** The keys of {@link #items} in the order they were collected. */
  public final List<String> itemKeys = new ArrayList<>();

  public SpecSetSide(String name, String root, String anchor) {
    this.name = name;
    this.root = root;
    this.anchor = anchor;
  }

  void putItem(String key, String path) {
    if (!items.containsKey(key)) {
      itemKeys.add(key);
    }
    items.put(key, path);
  }
}
