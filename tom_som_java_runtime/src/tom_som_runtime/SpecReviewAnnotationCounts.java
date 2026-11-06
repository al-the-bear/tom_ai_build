package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** The counts a review report needs (SOM §11.9, the team counts of §11.9.8 included). */
public final class SpecReviewAnnotationCounts {
  /** Every question. */
  public final int questions;

  /** Questions without a team answer. */
  public final int openQuestions;

  /** Questions with a team answer. */
  public final int answeredQuestions;

  /** Comment blocks. */
  public final int comments;

  /** Inline marks. */
  public final int marks;

  /** Questions whose team answer begins {@code open:} (also counted as answered). */
  public final int unresolvedQuestions;

  /** Conflict blocks. */
  public final int conflicts;

  /** Conflict blocks without a decision. */
  public final int openConflicts;

  public SpecReviewAnnotationCounts(
      int questions, int openQuestions, int answeredQuestions, int comments, int marks) {
    this(questions, openQuestions, answeredQuestions, comments, marks, 0, 0, 0);
  }

  public SpecReviewAnnotationCounts(
      int questions,
      int openQuestions,
      int answeredQuestions,
      int comments,
      int marks,
      int unresolvedQuestions,
      int conflicts,
      int openConflicts) {
    this.questions = questions;
    this.openQuestions = openQuestions;
    this.answeredQuestions = answeredQuestions;
    this.comments = comments;
    this.marks = marks;
    this.unresolvedQuestions = unresolvedQuestions;
    this.conflicts = conflicts;
    this.openConflicts = openConflicts;
  }

  /** The canonical JSON form of the older case files (SOM §11.9.6). */
  public Map<String, Object> toJson() {
    return toJson(false);
  }

  /**
   * The canonical JSON form; {@code team} adds the three team counts, the form {@code
   * team_annotation_cases.json} pins (SOM §11.9.8).
   */
  public Map<String, Object> toJson(boolean team) {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("questions", questions);
    out.put("openQuestions", openQuestions);
    out.put("answeredQuestions", answeredQuestions);
    out.put("comments", comments);
    out.put("marks", marks);
    if (team) {
      out.put("unresolvedQuestions", unresolvedQuestions);
      out.put("conflicts", conflicts);
      out.put("openConflicts", openConflicts);
    }
    return out;
  }
}
