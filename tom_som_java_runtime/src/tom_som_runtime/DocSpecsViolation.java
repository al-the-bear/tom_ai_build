package tom_som_runtime;

/**
 * One DocSpecs validation finding — a faithful port of the Go
 * {@code DocSpecsViolation} (itself Dart-parity).
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
  public static final String RULE_SECTION_OUT_OF_ORDER = "sectionOutOfOrder";
  public static final String RULE_DUPLICATE_ID_PATH = "duplicateIdPath";
  // The reading notation's findings (DocSpecs specification, RN-10), reported
  // by SpecNotation.scanNotation per value: a section's own body, and in a
  // TomSpecs rendition each form field's value apart (NotationFindingCode).
  public static final String RULE_UNCLOSED_DIV = "unclosedDiv";
  public static final String RULE_STRAY_CLOSING_FENCE = "strayClosingFence";
  public static final String RULE_UNCLOSED_SPAN = "unclosedSpan";
  public static final String RULE_DIV_WITHOUT_KIND = "divWithoutKind";
  public static final String RULE_UNKNOWN_KIND = "unknownKind";
  public static final String RULE_MARK_ACROSS_NOTATION = "markAcrossNotation";
  public static final String RULE_ANNOTATION_INSIDE_DIV = "annotationInsideDiv";
  public static final String RULE_DIV_INSIDE_ANNOTATION = "divInsideAnnotation";
  public static final String RULE_REJECTED_BLOCK = "rejectedBlock";

  /**
   * The complete §14 vocabulary, in declaration order — the enumerable form of
   * what Dart gets for free from its enum. The conformance runner diffs it
   * against the rules the shared corpus exercises, so a rule added here without
   * a corpus case fails the suite instead of going unnoticed.
   */
  public static final String[] ALL_RULES = {
    RULE_UNKNOWN_SECTION,
    RULE_MISSING_REQUIRED_SECTION,
    RULE_ID_PATTERN_MISMATCH,
    RULE_TOO_FEW_ITEMS,
    RULE_TOO_MANY_ITEMS,
    RULE_MISSING_REQUIRED_FIELD,
    RULE_FIELD_PATTERN_MISMATCH,
    RULE_TEXT_REQUIRED,
    RULE_TEXT_LENGTH_OUT,
    RULE_FORMAT_MISMATCH,
    RULE_MALFORMED_HEADING,
    RULE_SECTION_OUT_OF_ORDER,
    RULE_DUPLICATE_ID_PATH,
    RULE_UNCLOSED_DIV,
    RULE_STRAY_CLOSING_FENCE,
    RULE_UNCLOSED_SPAN,
    RULE_DIV_WITHOUT_KIND,
    RULE_UNKNOWN_KIND,
    RULE_MARK_ACROSS_NOTATION,
    RULE_ANNOTATION_INSIDE_DIV,
    RULE_DIV_INSIDE_ANNOTATION,
    RULE_REJECTED_BLOCK,
  };

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
