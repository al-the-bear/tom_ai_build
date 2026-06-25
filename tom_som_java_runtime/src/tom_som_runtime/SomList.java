package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/**
 * A typed view over a list field, layered over the document's list store.
 *
 * <p>Items are addressed by their stable item paths
 * ({@link SpecDocument#listItems}); each is wrapped in an element facade {@code T}
 * by {@code factory}. The wrapper holds no items itself — every operation reads
 * through the live document, so it always reflects the current state.
 */
public final class SomList<T> {
  public final SpecDocument doc;
  public final String listPath;
  private final SomElementFactory<T> factory;

  public SomList(SpecDocument doc, String listPath, SomElementFactory<T> factory) {
    this.doc = doc;
    this.listPath = listPath;
    this.factory = factory;
  }

  /** The number of items currently in the list. */
  public int length() {
    return doc.listItemCount(listPath);
  }

  /** The element facades for every item, in order. */
  public List<T> items() {
    List<T> out = new ArrayList<>();
    for (String p : doc.listItems(listPath)) {
      out.add(factory.create(doc, p));
    }
    return out;
  }

  /** The element facade for the item at {@code index}. */
  public T get(int index) {
    return factory.create(doc, doc.listItems(listPath).get(index));
  }

  /** Appends a new item and returns its element facade. */
  public T add() {
    return factory.create(doc, doc.addListItem(listPath));
  }

  /** Removes the item at {@code index} and every value nested beneath it. */
  public void removeAt(int index) {
    doc.removeListItem(doc.listItems(listPath).get(index));
  }
}
