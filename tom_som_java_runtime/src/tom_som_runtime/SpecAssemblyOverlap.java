package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * One place two or more fragments both write, reported by
 * {@link SpecDocument#assemble} — a port of {@code SpecAssemblyOverlap} in
 * {@code spec_document_assembly.dart}.
 */
public final class SpecAssemblyOverlap {
  /** The store: {@code content}, {@code forms}, {@code lists}, {@code headlines} or {@code codeSpecs}. */
  public final String store;

  /** The document path. */
  public final String path;

  /** The form field, for the {@code forms} store; {@code null} otherwise. */
  public final String field;

  /** The fragments that write it, in the order they were given. */
  public final List<String> fragments;

  /** Creates an overlap; {@code field} is null outside the {@code forms} store. */
  public SpecAssemblyOverlap(String store, String path, String field, List<String> fragments) {
    this.store = store;
    this.path = path;
    this.field = field;
    this.fragments = Collections.unmodifiableList(new ArrayList<>(fragments));
  }

  /** One sentence naming the place and every fragment that writes it. */
  public String message() {
    return (field == null ? path : path + " field `" + field + "`")
        + " ("
        + store
        + ") is written by "
        + String.join(" and ", fragments)
        + " — a place two fragments both write is an authoring conflict, not something"
        + " the assembly may resolve";
  }

  @Override
  public String toString() {
    return message();
  }
}
