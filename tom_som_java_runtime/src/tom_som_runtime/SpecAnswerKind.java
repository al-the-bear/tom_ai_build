package tom_som_runtime;

/** What an extracted answer entry is (SOM §11.9.7). */
public enum SpecAnswerKind {
  /** A question with an answer. */
  ANSWERED("answered"),
  /** A question without an answer. */
  OPEN("open"),
  /** A comment block. */
  COMMENT("comment"),
  /** An inline mark. */
  MARK("mark");

  /** The wire name. */
  public final String value;

  SpecAnswerKind(String value) {
    this.value = value;
  }
}
