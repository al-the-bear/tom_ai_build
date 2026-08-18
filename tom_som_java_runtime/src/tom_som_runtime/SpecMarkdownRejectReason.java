package tom_som_runtime;

/** Why an imported Markdown block was rejected. */
public enum SpecMarkdownRejectReason {
  UNKNOWN_SECTION("unknownSection"),
  KIND_MISMATCH("kindMismatch"),
  /**
   * Body text with no owning value slot: text before the document root
   * heading. (Text inside a {@code @Form} section before its first
   * {@code FieldName:} line is <b>not</b> orphaned — it is the form's preamble
   * and binds to the form's own content, SOM §11.4 rule 7.)
   */
  ORPHAN_CONTENT("orphanContent"),
  MISSING_VALUE("missingValue"),
  MALFORMED_HEADING("malformedHeading");

  public final String value;

  SpecMarkdownRejectReason(String value) {
    this.value = value;
  }
}
