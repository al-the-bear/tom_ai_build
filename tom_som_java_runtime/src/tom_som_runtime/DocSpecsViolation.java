package tom_som_runtime;

/**
 * One DocSpecs validation finding — a faithful port of the Go
 * {@code DocSpecsViolation} (itself Dart-parity, DR7/DR14/DR17).
 *
 * <p>Java conventions (mirroring the rest of this runtime): {@code null} stands
 * in for Go's {@code ""} on the optional {@link #sectionId} / {@link #path};
 * the rendered {@link #toString} output is byte-identical to the Go port's
 * {@code String()}.
 */
public final class DocSpecsViolation {
  // The vocabulary of validation violation rules (Dart-parity names).
  public static final String RULE_UNKNOWN_SECTION = "unknownSection";
  public static final String RULE_MISSING_REQUIRED_SECTION = "missingRequiredSection";
  public static final String RULE_ID_PATTERN_MISMATCH = "idPatternMismatch";
  public static final String RULE_TOO_FEW_ITEMS = "tooFewItems";
  public static final String RULE_TOO_MANY_ITEMS = "tooManyItems";
  public static final String RULE_MISSING_REQUIRED_FIELD = "missingRequiredField";
  public static final String RULE_FIELD_PATTERN_MISMATCH = "fieldPatternMismatch";
  public static final String RULE_TEXT_REQUIRED = "textRequired";
  public static final String RULE_TEXT_LENGTH_OUT = "textLengthOut";
  public static final String RULE_FORMAT_MISMATCH = "formatMismatch";
  public static final String RULE_MALFORMED_HEADING = "malformedHeading";

  public final String rule;
  public final int line;
  public final String message;
  /** The offending/expected section id, {@code null} when not applicable. */
  public final String sectionId;
  /** The document path of the finding, {@code null} when not applicable. */
  public final String path;

  public DocSpecsViolation(String rule, int line, String message) {
    this(rule, line, message, null, null);
  }

  public DocSpecsViolation(String rule, int line, String message, String sectionId) {
    this(rule, line, message, sectionId, null);
  }

  public DocSpecsViolation(
      String rule, int line, String message, String sectionId, String path) {
    this.rule = rule;
    this.line = line;
    this.message = message;
    this.sectionId = sectionId;
    this.path = path;
  }

  @Override
  public String toString() {
    String sid = sectionId != null && !sectionId.isEmpty() ? " [" + sectionId + "]" : "";
    String p = path != null && !path.isEmpty() ? " (" + path + ")" : "";
    return "line " + line + ": " + rule + sid + p + " — " + message;
  }
}
