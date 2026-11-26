package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** A {@link SpecDocumentSet} that cannot be built, with the documents it names. */
public final class SpecDocumentSetError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  /** Why. */
  public final SpecDocumentSetRefusal refusal;
  /** The documents (or fragments) concerned, in the order given. */
  public final transient List<String> documents;
  /** For {@link SpecDocumentSetRefusal#UNPAIRABLE}, the class; {@code null} otherwise. */
  public final String className;

  public SpecDocumentSetError(
      SpecDocumentSetRefusal refusal, List<String> documents, String message, String className) {
    super(message);
    this.refusal = refusal;
    this.documents = Collections.unmodifiableList(new ArrayList<>(documents));
    this.className = className;
  }

  public SpecDocumentSetError(
      SpecDocumentSetRefusal refusal, List<String> documents, String message) {
    this(refusal, documents, message, null);
  }

  /** The canonical JSON form the corpus compares (no message). */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("refusal", refusal.value);
    out.put("documents", new ArrayList<Object>(documents));
    if (className != null) {
      out.put("className", className);
    }
    return out;
  }

  @Override
  public String toString() {
    return "SpecDocumentSetError(" + refusal.value + "): " + getMessage();
  }
}
