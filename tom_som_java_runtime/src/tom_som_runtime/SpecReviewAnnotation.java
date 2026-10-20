package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** One review annotation (SOM §11.9), located by the value that holds it. */
public final class SpecReviewAnnotation {
  /** The kind. */
  public final SpecReviewAnnotationKind kind;

  /** The document path of the value: a content path, or a form path when {@link #field} is set. */
  public final String path;

  /** The form field whose value holds the annotation; null for content. */
  public final String field;

  /** The 0-based line within the value where the annotation starts (a question: its header line). */
  public final int line;

  /** The comment id ({@code C-12}) or question id ({@code BQ-81}); null for a bare comment and a mark. */
  public final String id;

  /** A comment's id with the document qualifier in front ({@code SBP C-12}), else null. */
  public final String qualifiedId;

  /** A comment's author; null when none is written. */
  public final String author;

  /**
   * A comment's text, a question's text (options included), or a mark's text (the added, removed
   * or highlighted text; a substitution's old text; empty for a comment mark).
   */
  public final String text;

  /** A comment's context: the paragraph before the block, verbatim (empty at the value start). */
  public final String context;

  /** A question's topic (in a combined block: the field it asks about). */
  public final String topic;

  /** Whether a question carries {@code ★} before its topic. */
  public final boolean starred;

  /** Whether a question is part of a combined block. */
  public final boolean combined;

  /** A question's answer, trimmed; empty when open. */
  public final String answer;

  /** A question's options, in order (empty when it states none). */
  public final List<SpecQuestionOption> options;

  /**
   * A question's recommended letter: the bold option, else the option that says "recommended", else
   * the letter of a {@code *Recommendation:*} line; null for none.
   */
  public final String recommended;

  /** A mark's kind; null for a comment or question. */
  public final SpecMarkKind markKind;

  /** A substitution's new text. */
  public final String newText;

  /** The comment of a comment mark, or of a highlight followed by one. */
  public final String comment;

  SpecReviewAnnotation(
      SpecReviewAnnotationKind kind,
      String path,
      String field,
      int line,
      String id,
      String qualifiedId,
      String author,
      String text,
      String context,
      String topic,
      boolean starred,
      boolean combined,
      String answer,
      SpecMarkKind markKind,
      String newText,
      String comment) {
    this(kind, path, field, line, id, qualifiedId, author, text, context, topic, starred,
        combined, answer, null, null, markKind, newText, comment);
  }

  SpecReviewAnnotation(
      SpecReviewAnnotationKind kind,
      String path,
      String field,
      int line,
      String id,
      String qualifiedId,
      String author,
      String text,
      String context,
      String topic,
      boolean starred,
      boolean combined,
      String answer,
      List<SpecQuestionOption> options,
      String recommended,
      SpecMarkKind markKind,
      String newText,
      String comment) {
    this.kind = kind;
    this.path = path;
    this.field = field;
    this.line = line;
    this.id = id;
    this.qualifiedId = qualifiedId;
    this.author = author;
    this.text = text == null ? "" : text;
    this.context = context == null ? "" : context;
    this.topic = topic;
    this.starred = starred;
    this.combined = combined;
    this.answer = answer == null ? "" : answer;
    this.options =
        options == null
            ? Collections.emptyList()
            : Collections.unmodifiableList(new ArrayList<>(options));
    this.recommended = recommended;
    this.markKind = markKind;
    this.newText = newText;
    this.comment = comment;
  }

  /** Whether a question is still open (no answer written). */
  public boolean open() {
    return kind == SpecReviewAnnotationKind.QUESTION && answer.isEmpty();
  }

  /** The letter an answer starts with ({@code (b)} or {@code **(b)**}), or null. */
  public String answerLetter() {
    return kind == SpecReviewAnnotationKind.QUESTION
        ? SpecReviewAnnotations.leadingLetter(answer)
        : null;
  }

  /** The canonical JSON form the conformance corpus pins ({@code null} written explicitly). */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("kind", kind.value);
    out.put("path", path);
    out.put("field", field);
    out.put("line", line);
    switch (kind) {
      case COMMENT:
        out.put("id", id);
        out.put("qualifiedId", qualifiedId);
        out.put("author", author);
        out.put("text", text);
        out.put("context", context);
        break;
      case QUESTION:
        out.put("id", id);
        out.put("topic", topic);
        out.put("starred", starred);
        out.put("combined", combined);
        out.put("text", text);
        out.put("answer", answer);
        out.put("open", open());
        List<Object> opts = new ArrayList<>();
        for (SpecQuestionOption o : options) {
          opts.add(o.toJson());
        }
        out.put("options", opts);
        out.put("recommended", recommended);
        out.put("answerLetter", answerLetter());
        break;
      case MARK:
        out.put("markKind", markKind.value);
        out.put("text", text);
        out.put("newText", newText);
        out.put("comment", comment);
        break;
    }
    return out;
  }
}
