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
  MALFORMED_HEADING("malformedHeading"),
  /**
   * A form-table row, a section-table row or a records column names no field
   * the form declares.
   */
  UNKNOWN_FIELD("unknownField"),
  /**
   * A block that breaks the layout grammar: a table without its delimiter row
   * or with a row of another cell count, a field given twice, a {@code refs} /
   * {@code records} div beside other text or item headings or not holding
   * what it should, an unclosed {@code refs} / {@code records} fence. The
   * message says which.
   */
  MALFORMED_BLOCK("malformedBlock");

  public final String value;

  SpecMarkdownRejectReason(String value) {
    this.value = value;
  }
}
