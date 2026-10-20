package tom_som_runtime;

/** The five CriticMarkup inline marks (SOM §11.9.3). */
public enum SpecMarkKind {
  /** {@code {>> comment <<}}. */
  COMMENT("comment"),
  /** {@code {== text ==}}, optionally followed by {@code {>> comment <<}}. */
  HIGHLIGHT("highlight"),
  /** {@code {++ added ++}}. */
  INSERTION("insertion"),
  /** {@code {-- removed --}}. */
  DELETION("deletion"),
  /** {@code {~~ old ~> new ~~}}. */
  SUBSTITUTION("substitution");

  /** The wire name. */
  public final String value;

  SpecMarkKind(String value) {
    this.value = value;
  }
}
