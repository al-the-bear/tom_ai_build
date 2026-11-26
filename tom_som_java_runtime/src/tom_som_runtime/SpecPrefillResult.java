package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** What {@link SpecPrefill#prefill} did. */
public final class SpecPrefillResult {
  /** The document filled: the set's own, or the one created. */
  public final SpecDocument document;
  /** Its name in the set. */
  public final String name;
  /** Whether it was created by this call. */
  public final boolean created;
  /** The pairs it filled, by section id, in the Blueprint's order. */
  public final List<String> filledPairs;
  /** The pairs it left because their anchor already holds a value. */
  public final List<String> skippedPairs;
  /** The {@code deriveFields} run (plain) on the document after the copy. */
  public final SpecDeriveResult derived;
  /** The document's findings after it ({@code validateDocument}, then {@code validateLinks}): the agent's work list. */
  public final List<SpecValidationError> findings;

  public SpecPrefillResult(
      SpecDocument document,
      String name,
      boolean created,
      List<String> filledPairs,
      List<String> skippedPairs,
      SpecDeriveResult derived,
      List<SpecValidationError> findings) {
    this.document = document;
    this.name = name;
    this.created = created;
    this.filledPairs = Collections.unmodifiableList(new ArrayList<>(filledPairs));
    this.skippedPairs = Collections.unmodifiableList(new ArrayList<>(skippedPairs));
    this.derived = derived;
    this.findings = Collections.unmodifiableList(new ArrayList<>(findings));
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> d = new LinkedHashMap<>();
    d.put("changes", derived.changesJson());
    d.put("unresolved", SpecSyncReport.errorsJson(derived.unresolved));
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("name", name);
    out.put("created", created);
    out.put("filledPairs", new ArrayList<Object>(filledPairs));
    out.put("skippedPairs", new ArrayList<Object>(skippedPairs));
    out.put("derived", d);
    out.put("findings", SpecSyncReport.errorsJson(findings));
    out.put("document", document.toJson());
    return out;
  }
}
