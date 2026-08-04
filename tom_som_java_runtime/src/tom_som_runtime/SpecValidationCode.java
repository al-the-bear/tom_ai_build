package tom_som_runtime;

/** Why a single value in a document is invalid against the model. */
public enum SpecValidationCode {
  DANGLING_PATH("danglingPath"),
  KIND_MISMATCH("kindMismatch"),
  UNKNOWN_FORM_FIELD("unknownFormField"),
  MIN_ITEMS("minItems"),
  ONE_OF_CASE_MISMATCH("oneOfCaseMismatch"),
  DANGLING_REFERENCE("danglingReference");

  public final String value;

  SpecValidationCode(String value) {
    this.value = value;
  }
}
