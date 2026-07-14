package tom_som_runtime;

/**
 * One position of the generated <b>dot-notation / ID-tree access surfaces</b>
 * (DR1 §4): an absolute document {@link #path} bound to the {@link #tree} it
 * belongs to — a faithful port of {@code spec_meta.dart} / {@code spec_meta.ts}.
 *
 * <p>The generated facades (DR8) emit one accessor class per model class whose
 * getters return further {@code SomMetaRef}s. Every accessor exposes at least
 * {@link #path} and {@link #meta} (the {@link SomMetaNode} at that position).
 * This base class is the leaf accessor itself (content/scalar/enum/form
 * positions).
 */
public class SomMetaRef {
  /** The metadata tree of the document root this position belongs to. */
  public final SomMetaTree tree;

  /** The absolute document path of this position (§4 path grammar). */
  public final String path;

  public SomMetaRef(SomMetaTree tree, String path) {
    this.tree = tree;
    this.path = path;
  }

  /**
   * The metadata node at {@link #path}.
   *
   * @throws IllegalStateException when the path resolves to no node — only
   *     possible past a recursive re-entry, where the generated chain has
   *     ended and the metadata tree carries no further nodes (DR1 §4.1 cycle
   *     rule).
   */
  public SomMetaNode meta() {
    SomMetaNode node = tree.byPath(path);
    if (node == null) {
      throw new IllegalStateException(
          "no metadata node at \"" + path + "\" — the position lies beyond "
              + "a recursive re-entry; use the dynamic tree lookups instead");
    }
    return node;
  }
}
