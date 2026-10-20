package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One inline mark as {@link SpecReviewAnnotations#listMarks} reports it. */
public final class SpecMarkEntry {
  /**
   * {@code M-<n>}: the mark's 1-based position among all marks of the document, in document
   * order. Stable for one {@link SpecReviewAnnotations#revision}.
   */
  public final String id;

  /** The value's path. */
  public final String path;

  /** The form field, or null for content. */
  public final String field;

  /** The 0-based line within the value where the mark opens. */
  public final int line;

  /** The mark's kind. */
  public final SpecMarkKind markKind;

  /** The text after rejecting the mark. */
  public final String oldText;

  /** The text after accepting the mark. */
  public final String newText;

  /** A comment mark's or a commented highlight's comment; null when there is none. */
  public final String comment;

  /** The mark as written. */
  public final String markup;

  /** The paragraph holding the mark, verbatim — for display. */
  public final String context;

  public SpecMarkEntry(
      String id,
      String path,
      String field,
      int line,
      SpecMarkKind markKind,
      String oldText,
      String newText,
      String comment,
      String markup,
      String context) {
    this.id = id;
    this.path = path;
    this.field = field;
    this.line = line;
    this.markKind = markKind;
    this.oldText = oldText;
    this.newText = newText;
    this.comment = comment;
    this.markup = markup;
    this.context = context;
  }

  /** The canonical JSON form the conformance corpus pins. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("id", id);
    out.put("path", path);
    out.put("field", field);
    out.put("line", line);
    out.put("markKind", markKind.value);
    out.put("oldText", oldText);
    out.put("newText", newText);
    out.put("comment", comment);
    out.put("markup", markup);
    out.put("context", context);
    return out;
  }
}
