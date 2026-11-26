package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Why {@link SpecDocumentSet#renameId} refuses: the new id is already taken. */
public final class SpecRenameError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  /** The documents already holding the new id. */
  public final transient List<String> documents;

  public SpecRenameError(List<String> documents, String message) {
    super(message);
    this.documents = Collections.unmodifiableList(new ArrayList<>(documents));
  }

  @Override
  public String toString() {
    return "SpecRenameError: " + getMessage();
  }
}
