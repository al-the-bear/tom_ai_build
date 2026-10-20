package tom_som_runtime;

/** Why a single value in a document is invalid against the model. */
public enum SpecValidationCode {
  DANGLING_PATH("danglingPath"),
  KIND_MISMATCH("kindMismatch"),
  UNKNOWN_FORM_FIELD("unknownFormField"),
  MIN_ITEMS("minItems"),
  ONE_OF_CASE_MISMATCH("oneOfCaseMismatch"),
  DANGLING_REFERENCE("danglingReference"),
  /**
   * A form field whose model type is an enum holds a token the enum does not
   * declare. The typed read is forgiving (an unknown token answers null), and a
   * document is loaded far more often than it is written through a setter, so
   * without this the value is simply dropped. An <b>empty</b> value is absence,
   * not a bad value, and is not reported.
   */
  ENUM_VALUE_UNKNOWN("enumValueUnknown"),
  /**
   * A form field that states a count ({@code Field.countOf}) holds a number that
   * is not the number of entries the document holds, or no whole number at all
   * (vsctsa43). A total kept by hand drifts from the list it describes the first
   * time the list changes and the total does not.
   */
  COUNT_MISMATCH("countMismatch"),
  /**
   * A typed field ({@code int}, {@code double}, {@code num} or {@code bool}) — a
   * form field or a scalar leaf — holds text its type cannot read ({@code lots}
   * in an {@code int}). The typed read refuses such text rather than answering
   * null, and the setters refuse to store it, but a document edited by hand or
   * by another tool can still carry it; this is where it is reported. Empty text
   * is absence, not a bad value, and is not reported.
   */
  VALUE_TYPE_MISMATCH("valueTypeMismatch"),
  /**
   * A form field whose value is derived from other fields — a product
   * ({@code Field.productOf}) or a rank by a sibling field ({@code Field.rankOf})
   * — holds a value the fields it is derived from do not give, or no number at
   * all (uamtc10). A risk score kept by hand drifts the first time probability
   * or impact changes and the score does not.
   */
  DERIVED_VALUE_MISMATCH("derivedValueMismatch"),
  /**
   * A form the document holds leaves a {@code required} field empty (uamtc16).
   * Checked for every form instance that holds at least one field value — a
   * class-level form, a form declared on a section member, in a list item or
   * not — so an absent form is absence, not an incomplete one. The schema tier
   * checks class-level forms of the rendition only; this is the check that
   * reaches every form.
   */
  MISSING_REQUIRED_FIELD("missingRequiredField"),
  /**
   * A reference field that does not declare {@code multiple} holds a
   * comma-separated list of ids (uamtc17). A field meant for one reference must
   * not silently hold several; each id of the list is still resolved, so a
   * dangling one is a {@code danglingReference} as well.
   */
  MULTIPLE_REFERENCES("multipleReferences");

  public final String value;

  SpecValidationCode(String value) {
    this.value = value;
  }
}
