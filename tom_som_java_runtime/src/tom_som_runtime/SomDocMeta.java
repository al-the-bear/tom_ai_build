package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/**
 * The {@code @Document} metadata carried by a document root (SOM §7.1 DocMeta)
 * — a faithful port of {@code spec_meta.dart} / {@code spec_meta.ts}.
 */
public final class SomDocMeta {
  /** The document's display name ({@code "Solution Blueprint"}). */
  public final String name;

  /** The document's description. */
  public final String description;

  /** Class names of the documents this one is based on ({@code @Document.basedOn}). */
  public final List<String> basedOn;

  public SomDocMeta(String name, String description, List<String> basedOn) {
    this.name = name;
    this.description = description;
    this.basedOn = basedOn != null ? basedOn : new ArrayList<>();
  }
}
