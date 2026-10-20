package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** What was done to one inline mark. */
public final class SpecMarkOutcome {
  /** The mark's id at the revision the operation ran on. */
  public final String id;

  /** The value's path. */
  public final String path;

  /** The form field, or null for content. */
  public final String field;

  /** The 0-based line within the value where the mark opened. */
  public final int line;

  /** The mark's kind. */
  public final SpecMarkKind markKind;

  /** Accepted or rejected. */
  public final SpecMarkDecision decision;

  /** The mark as written. */
  public final String markup;

  /** The text that replaced it. */
  public final String result;

  public SpecMarkOutcome(
      String id,
      String path,
      String field,
      int line,
      SpecMarkKind markKind,
      SpecMarkDecision decision,
      String markup,
      String result) {
    this.id = id;
    this.path = path;
    this.field = field;
    this.line = line;
    this.markKind = markKind;
    this.decision = decision;
    this.markup = markup;
    this.result = result;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("id", id);
    out.put("path", path);
    out.put("field", field);
    out.put("line", line);
    out.put("markKind", markKind.value);
    out.put("decision", decision.value);
    out.put("markup", markup);
    out.put("result", result);
    return out;
  }
}
