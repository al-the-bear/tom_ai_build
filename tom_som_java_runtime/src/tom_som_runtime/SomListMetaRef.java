package tom_som_runtime;

/**
 * The generated accessor for a <b>list</b> position (SOM §8): {@link #path}
 * is the list container path; {@link #item} returns the accessor for the
 * {@code seq}-th item position ({@code <path>-<seq>}), whose children are the
 * element class's accessors — a faithful port of {@code spec_meta.dart} /
 * {@code spec_meta.ts}.
 */
public final class SomListMetaRef<T> extends SomMetaRef {
  private final SomMetaRefFactory<T> element;

  /** Binds a list container position to its element accessor factory. */
  public SomListMetaRef(SomMetaTree tree, String path, SomMetaRefFactory<T> element) {
    super(tree, path);
    this.element = element;
  }

  /** The accessor at the item position {@code <path>-<seq>}. */
  public T item(int seq) {
    return element.create(tree, SpecPaths.listItemPath(path, seq));
  }

  /** The item position path {@code <path>-<seq>} itself. */
  public String itemPath(int seq) {
    return SpecPaths.listItemPath(path, seq);
  }
}
