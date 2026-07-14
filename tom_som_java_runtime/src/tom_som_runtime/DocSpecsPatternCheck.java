package tom_som_runtime;

import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

/**
 * A regex pattern check with an optional custom error message — a faithful
 * port of the Go {@code DocSpecsPatternCheck}. {@code null} stands in for Go's
 * {@code ""} on the absent {@link #errorMessage}.
 */
public final class DocSpecsPatternCheck {
  public final String pattern;
  /** The custom error message, {@code null} when none. */
  public final String errorMessage;

  public DocSpecsPatternCheck(String pattern, String errorMessage) {
    this.pattern = pattern == null ? "" : pattern;
    this.errorMessage = errorMessage;
  }

  /**
   * Whether {@code value} matches the check's pattern (unanchored, like Go's
   * {@code MatchString}); {@code false} when the pattern does not compile.
   */
  public boolean matches(String value) {
    try {
      return Pattern.compile(pattern).matcher(value).find();
    } catch (PatternSyntaxException e) {
      return false;
    }
  }
}
