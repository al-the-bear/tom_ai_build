package tom_som_runtime;

/**
 * A pattern that is not in the {@link SomTextPattern} grammar — a faithful port
 * of {@code SomPatternError} in {@code spec_text_pattern.dart}.
 *
 * <p>Raised at <i>compile</i> time rather than silently matching nothing, so a
 * caller that mistyped a pattern learns that instead of reading an empty result
 * as "no hits". Unchecked, like every other caller-error signal in this runtime
 * ({@link SpecSectionIdCollision}, {@link SpecYamlFormatException}): the nine
 * ports must agree on <i>that</i> a bad pattern fails, and Java is the only one
 * of them with a checked-exception concept to add on top.
 *
 * <p>{@link #getMessage()} says what is wrong with the pattern.
 */
public final class SomPatternError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  /** The offending pattern source. */
  public final String pattern;

  public SomPatternError(String pattern, String message) {
    super(message);
    this.pattern = pattern;
  }

  @Override
  public String toString() {
    return "SomPatternError(\"" + pattern + "\"): " + getMessage();
  }
}
