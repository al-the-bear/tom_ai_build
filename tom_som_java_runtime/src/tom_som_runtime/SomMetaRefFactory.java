package tom_som_runtime;

/**
 * The factory a {@link SomListMetaRef} uses to build the accessor for an item
 * position: {@code (tree, path) -> ref}, where {@code ref} is the element
 * class's generated accessor — a faithful port of {@code spec_meta.dart} /
 * {@code spec_meta.ts}.
 */
@FunctionalInterface
public interface SomMetaRefFactory<T> {
  T create(SomMetaTree tree, String path);
}
