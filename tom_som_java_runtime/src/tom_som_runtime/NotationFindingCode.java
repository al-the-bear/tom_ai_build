package tom_som_runtime;

/**
 * The reading notation's findings (DocSpecs specification, Reading Notation
 * RN-10); each {@link #value} is the rule's name in the DocSpecs validator.
 * The Java port of {@code NotationFindingCode} in {@code spec_notation.dart} /
 * {@code spec_notation.ts}, in their order.
 */
public enum NotationFindingCode {
  /** An opening fence has no closing fence. */
  UNCLOSED_DIV("unclosedDiv"),
  /** A closing fence has no open div. */
  STRAY_CLOSING_FENCE("strayClosingFence"),
  /** A span's attribute braces do not close on the paragraph. */
  UNCLOSED_SPAN("unclosedSpan"),
  /** A div's attributes hold no class (TomSpecs renditions only). */
  DIV_WITHOUT_KIND("divWithoutKind"),
  /** A kind that is not registered (TomSpecs renditions only; a warning). */
  UNKNOWN_KIND("unknownKind"),
  /** An inline review mark crosses the boundary of a span or citation. */
  MARK_ACROSS_NOTATION("markAcrossNotation"),
  /** A comment or question block stands inside a div. */
  ANNOTATION_INSIDE_DIV("annotationInsideDiv"),
  /** A div stands inside a comment or question block. */
  DIV_INSIDE_ANNOTATION("divInsideAnnotation"),
  /** A {@code rejected} block waits for its resolution. */
  REJECTED_BLOCK("rejectedBlock");

  /** The wire name, the validator's rule name ({@code "unclosedDiv"}). */
  public final String value;

  NotationFindingCode(String value) {
    this.value = value;
  }

  /** The severity of this code: an unknown kind is a {@code "warning"}, the rest {@code "error"}s. */
  public String severity() {
    return SpecNotation.notationSeverity(this);
  }
}
