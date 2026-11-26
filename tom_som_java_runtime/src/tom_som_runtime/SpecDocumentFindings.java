package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** One document's own findings in a {@link SpecSyncReport}. */
public final class SpecDocumentFindings {
  /** The document's name. */
  public final String name;
  /** Its findings ({@code validateDocument}, then {@code validateLinks}). */
  public final List<SpecValidationError> errors;

  public SpecDocumentFindings(String name, List<SpecValidationError> errors) {
    this.name = name;
    this.errors = Collections.unmodifiableList(new ArrayList<>(errors));
  }
}
