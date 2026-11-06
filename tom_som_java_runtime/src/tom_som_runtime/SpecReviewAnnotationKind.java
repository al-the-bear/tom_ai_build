package tom_som_runtime;

/**
 * The kinds of review annotation (SOM §11.9): the three of §11.9.1–11.9.3 and the conflict block
 * a team review adds (§11.9.8).
 */
public enum SpecReviewAnnotationKind {
  /** A reviewer's comment block, {@code > ⬆️ **C-12** (Alexis): …}. */
  COMMENT("comment"),
  /** One question of a question block, {@code > **❓ BQ-81 — topic:** …}. */
  QUESTION("question"),
  /** A CriticMarkup inline mark. */
  MARK("mark"),
  /** A conflict block, {@code > ⚖️ **X-3 — Conflicting changes:** …} (SOM §11.9.8). */
  CONFLICT("conflict");

  /** The wire name ({@code comment}, {@code question}, {@code mark}, {@code conflict}). */
  public final String value;

  SpecReviewAnnotationKind(String value) {
    this.value = value;
  }
}
