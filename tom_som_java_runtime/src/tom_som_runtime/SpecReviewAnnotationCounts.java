package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** The counts a review report needs (SOM §11.9). */
public final class SpecReviewAnnotationCounts {
  /** Every question. */
  public final int questions;

  /** Questions without an answer. */
  public final int openQuestions;

  /** Questions with an answer. */
  public final int answeredQuestions;

  /** Comment blocks. */
  public final int comments;

  /** Inline marks. */
  public final int marks;

  public SpecReviewAnnotationCounts(
      int questions, int openQuestions, int answeredQuestions, int comments, int marks) {
    this.questions = questions;
    this.openQuestions = openQuestions;
    this.answeredQuestions = answeredQuestions;
    this.comments = comments;
    this.marks = marks;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("questions", questions);
    out.put("openQuestions", openQuestions);
    out.put("answeredQuestions", answeredQuestions);
    out.put("comments", comments);
    out.put("marks", marks);
    return out;
  }
}
