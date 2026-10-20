package tom_som_runtime;

/** The three kinds of review annotation (SOM §11.9). */
public enum SpecReviewAnnotationKind {
  /** A reviewer's comment block, {@code > ⬆️ **C-12** (Alexis): …}. */
  COMMENT("comment"),
  /** One question of a question block, {@code > **❓ BQ-81 — topic:** …}. */
  QUESTION("question"),
  /** A CriticMarkup inline mark. */
  MARK("mark");

  /** The wire name ({@code comment}, {@code question}, {@code mark}). */
  public final String value;

  SpecReviewAnnotationKind(String value) {
    this.value = value;
  }
}
