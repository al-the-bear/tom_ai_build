package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** The counts a step's closing item reports (SOM §11.9.7). */
public final class SpecAnswerCounts {
  /** Questions with an answer. */
  public final int answered;

  /** Questions without one. */
  public final int open;

  /** Comment blocks. */
  public final int comments;

  /** Inline marks. */
  public final int marks;

  /** All zero. */
  public SpecAnswerCounts() {
    this(0, 0, 0, 0);
  }

  public SpecAnswerCounts(int answered, int open, int comments, int marks) {
    this.answered = answered;
    this.open = open;
    this.comments = comments;
    this.marks = marks;
  }

  /** The sum of two counts. */
  public SpecAnswerCounts plus(SpecAnswerCounts o) {
    return new SpecAnswerCounts(
        answered + o.answered, open + o.open, comments + o.comments, marks + o.marks);
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("answered", answered);
    out.put("open", open);
    out.put("comments", comments);
    out.put("marks", marks);
    return out;
  }
}
