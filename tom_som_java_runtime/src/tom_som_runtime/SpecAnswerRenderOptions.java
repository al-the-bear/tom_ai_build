package tom_som_runtime;

/** What {@code answers.md} includes besides the answered questions and comments. */
public final class SpecAnswerRenderOptions {
  /** List the questions still open. */
  public final boolean includeOpen;

  /** List the inline marks. */
  public final boolean includeMarks;

  /** The file's title. */
  public final String title;

  /** The defaults: no open questions, no marks, title {@code Answers}. */
  public SpecAnswerRenderOptions() {
    this(false, false, "Answers");
  }

  public SpecAnswerRenderOptions(boolean includeOpen, boolean includeMarks, String title) {
    this.includeOpen = includeOpen;
    this.includeMarks = includeMarks;
    this.title = title == null ? "Answers" : title;
  }
}
