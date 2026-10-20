package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One extracted answer entry (SOM §11.9.7). */
public final class SpecAnswerEntry {
  /** What it is. */
  public final SpecAnswerKind kind;

  /**
   * The question or comment id ({@code BQ-81}, {@code C-12}), or {@code M-<n>} for a mark; null
   * for a comment without an id.
   */
  public final String id;

  /** The section-id chain of the rendition heading the entry sits under ({@code SBP > INSC}). */
  public final String section;

  /** The 1-based line in the document's Markdown rendition. */
  public final int line;

  /** The document path of the value holding the entry. */
  public final String path;

  /** The form field holding it, or null for content. */
  public final String field;

  /** A question's topic. */
  public final String topic;

  /** Whether a question is part of a combined form block. */
  public final boolean combined;

  /** A question's text, a comment's text, or a mark's markup. */
  public final String text;

  /** A question's answer (empty when open). */
  public final String answer;

  /** A comment's author. */
  public final String author;

  /** A mark's kind. */
  public final SpecMarkKind markKind;

  /** A mark's text when rejected. */
  public final String oldText;

  /** A mark's text when accepted. */
  public final String newText;

  /** A mark's comment. */
  public final String comment;

  public SpecAnswerEntry(
      SpecAnswerKind kind,
      String id,
      String section,
      int line,
      String path,
      String field,
      String topic,
      boolean combined,
      String text,
      String answer,
      String author,
      SpecMarkKind markKind,
      String oldText,
      String newText,
      String comment) {
    this.kind = kind;
    this.id = id;
    this.section = section;
    this.line = line;
    this.path = path;
    this.field = field;
    this.topic = topic;
    this.combined = combined;
    this.text = text == null ? "" : text;
    this.answer = answer == null ? "" : answer;
    this.author = author;
    this.markKind = markKind;
    this.oldText = oldText;
    this.newText = newText;
    this.comment = comment;
  }

  /** The canonical JSON form ({@code null} written explicitly). */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("kind", kind.value);
    out.put("id", id);
    out.put("section", section);
    out.put("line", line);
    out.put("path", path);
    out.put("field", field);
    out.put("topic", topic);
    out.put("combined", combined);
    out.put("text", text);
    out.put("answer", answer);
    out.put("author", author);
    out.put("markKind", markKind == null ? null : markKind.value);
    out.put("oldText", oldText);
    out.put("newText", newText);
    out.put("comment", comment);
    return out;
  }
}
