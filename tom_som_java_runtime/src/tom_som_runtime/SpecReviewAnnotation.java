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

  /** A question's team answer, trimmed; empty when open. For a conflict: its decision. */
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

  /** A mark's authors from its attribution token (SOM §11.9.8); empty without one. */
  public final List<String> authors;

  /** A mark's votes from its attribution token; empty without one. */
  public final List<SpecMarkVote> votes;

  /** A question's individual answers, in the order written (SOM §11.9.8). */
  public final List<SpecIndividualAnswer> answers;

  /** A conflict's {@code (base)} text; empty for the other kinds. */
  public final String base;

  /** A conflict's lettered alternatives; empty for the other kinds. */
  public final List<SpecConflictAlternative> alternatives;

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
    this(kind, path, field, line, id, qualifiedId, author, text, context, topic, starred,
        combined, answer, options, recommended, markKind, newText, comment, null, null, null,
        null, null);
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
      String comment,
      List<String> authors,
      List<SpecMarkVote> votes,
      List<SpecIndividualAnswer> answers,
      String base,
      List<SpecConflictAlternative> alternatives) {
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
    this.authors = frozen(authors);
    this.votes = frozen(votes);
    this.answers = frozen(answers);
    this.base = base == null ? "" : base;
    this.alternatives = frozen(alternatives);
  }

  private static <T> List<T> frozen(List<T> list) {
    return list == null
        ? Collections.emptyList()
        : Collections.unmodifiableList(new ArrayList<>(list));
  }

  /**
   * Whether a question is still open (no team answer written), or a conflict (no decision
   * written). For a conflict, {@link #answer} holds the decision.
   */
  public boolean open() {
    return (kind == SpecReviewAnnotationKind.QUESTION || kind == SpecReviewAnnotationKind.CONFLICT)
        && answer.isEmpty();
  }

  /**
   * Whether a question's team answer or a conflict's decision begins with {@code open:} —
   * answered for a gate, but handed back (SOM §11.9.8).
   */
  public boolean unresolved() {
    return SpecReviewAnnotations.isUnresolved(answer);
  }

  /**
   * The letter a question's team answer starts with ({@code (b)} or {@code **(b)**}), or null;
   * null too for an unresolved answer.
   */
  public String answerLetter() {
    return kind == SpecReviewAnnotationKind.QUESTION && !unresolved()
        ? SpecReviewAnnotations.leadingLetter(answer)
        : null;
  }

  /** A conflict's decision letter: {@code a}…, {@code base}, or null for rewritten text or none. */
  public String decisionLetter() {
    return kind == SpecReviewAnnotationKind.CONFLICT
        ? SpecReviewAnnotations.decisionLetter(answer)
        : null;
  }

  /** The canonical JSON form the older case files pin ({@code null} written explicitly). */
  public Map<String, Object> toJson() {
    return toJson(false);
  }

  /**
   * The canonical JSON form; {@code team} gives the extended form {@code
   * team_annotation_cases.json} pins (SOM §11.9.8): marks with {@code authors} and {@code votes},
   * questions with {@code unresolved} and {@code answers}. A conflict has one form.
   */
  public Map<String, Object> toJson(boolean team) {
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
        if (team) {
          out.put("unresolved", unresolved());
        }
        List<Object> opts = new ArrayList<>();
        for (SpecQuestionOption o : options) {
          opts.add(o.toJson());
        }
        out.put("options", opts);
        out.put("recommended", recommended);
        out.put("answerLetter", answerLetter());
        if (team) {
          List<Object> as = new ArrayList<>();
          for (SpecIndividualAnswer a : answers) {
            as.add(a.toJson());
          }
          out.put("answers", as);
        }
        break;
      case CONFLICT:
        {
          out.put("id", id);
          out.put("qualifiedId", qualifiedId);
          out.put("topic", topic);
          out.put("text", text);
          out.put("base", base);
          List<Object> alts = new ArrayList<>();
          for (SpecConflictAlternative a : alternatives) {
            alts.add(a.toJson());
          }
          out.put("alternatives", alts);
          out.put("decision", answer);
          out.put("decisionLetter", decisionLetter());
          out.put("open", open());
          out.put("unresolved", unresolved());
          break;
        }
      case MARK:
        out.put("markKind", markKind.value);
        out.put("text", text);
        out.put("newText", newText);
        out.put("comment", comment);
        if (team) {
          out.put("authors", new ArrayList<Object>(authors));
          List<Object> vs = new ArrayList<>();
          for (SpecMarkVote v : votes) {
            vs.add(v.toJson());
          }
          out.put("votes", vs);
        }
        break;
    }
    return out;
  }
}
