package tom_som_runtime;

/** Why an imported Markdown block was rejected. */
public enum SpecMarkdownRejectReason {
  UNKNOWN_SECTION("unknownSection"),
  KIND_MISMATCH("kindMismatch"),
  ORPHAN_CONTENT("orphanContent"),
  MISSING_VALUE("missingValue"),
  MALFORMED_HEADING("malformedHeading");

  public final String value;

  SpecMarkdownRejectReason(String value) {
    this.value = value;
  }
}
