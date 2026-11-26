package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** What {@link SpecDeriveFields#deriveFields} did. */
public final class SpecDeriveResult {
  /** The document written: the one given, or its copy on a dry run. */
  public final SpecDocument document;
  /** Every place written, in the order written. */
  public final List<SpecDeriveChange> changes;
  /**
   * What it could not write, with the code: {@code unmarkable} (a change it
   * cannot mark exactly in a document under review, left as it was),
   * {@code derivedLookupMiss} (a lookup without exactly one row).
   */
  public final List<SpecValidationError> unresolved;

  public SpecDeriveResult(
      SpecDocument document, List<SpecDeriveChange> changes, List<SpecValidationError> unresolved) {
    this.document = document;
    this.changes = Collections.unmodifiableList(new ArrayList<>(changes));
    this.unresolved = Collections.unmodifiableList(new ArrayList<>(unresolved));
  }

  /** The changes as canonical JSON. */
  List<Object> changesJson() {
    List<Object> out = new ArrayList<>();
    for (SpecDeriveChange c : changes) {
      out.add(c.toJson());
    }
    return out;
  }

  /** The canonical JSON form (the document as its stores). */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("changes", changesJson());
    out.put("unresolved", SpecSyncReport.errorsJson(unresolved));
    out.put("document", document.toJson());
    return out;
  }
}
