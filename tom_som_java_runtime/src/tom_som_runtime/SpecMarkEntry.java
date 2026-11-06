package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
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

  /** The authors its attribution token names (SOM §11.9.8); empty without one. */
  public final List<String> authors;

  /** The votes its attribution token records; empty without one. */
  public final List<SpecMarkVote> votes;

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
    this(id, path, field, line, markKind, oldText, newText, comment, markup, context, null, null);
  }

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
      String context,
      List<String> authors,
      List<SpecMarkVote> votes) {
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
    this.authors =
        authors == null
            ? Collections.emptyList()
            : Collections.unmodifiableList(new ArrayList<>(authors));
    this.votes =
        votes == null ? Collections.emptyList() : Collections.unmodifiableList(new ArrayList<>(votes));
  }

  /** The canonical JSON form the older case files pin. */
  public Map<String, Object> toJson() {
    return toJson(false);
  }

  /**
   * The canonical JSON form; {@code team} adds {@code authors} and {@code votes}, the form {@code
   * team_annotation_cases.json} pins (SOM §11.9.8).
   */
  public Map<String, Object> toJson(boolean team) {
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
    if (team) {
      out.put("authors", new ArrayList<Object>(authors));
      List<Object> v = new ArrayList<>();
      for (SpecMarkVote x : votes) {
        v.add(x.toJson());
      }
      out.put("votes", v);
    }
    return out;
  }
}
