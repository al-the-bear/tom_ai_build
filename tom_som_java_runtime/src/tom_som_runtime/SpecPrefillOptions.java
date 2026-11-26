package tom_som_runtime;

import java.util.List;

/** The options of {@link SpecPrefill#prefill}. */
public final class SpecPrefillOptions {
  /** The name a document created is given, {@code null} for the root's type name. */
  public String name;
  /** Keeps those pairs (by section id) only; {@code null} for every pair. */
  public List<String> pairs;
}
