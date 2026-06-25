package tom_som_runtime;

/** Builds an element facade for a list item at a given document path. */
@FunctionalInterface
public interface SomElementFactory<T> {
  T create(SpecDocument doc, String path);
}
