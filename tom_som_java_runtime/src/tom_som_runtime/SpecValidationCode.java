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
  MULTIPLE_REFERENCES("multipleReferences"),
  /**
   * A comment block or a question block sits inside a form field's value —
   * between or below the form's fields — instead of in the form's preamble
   * (SOM §11.9.4).
   */
  ANNOTATION_MISPLACED("annotationMisplaced"),
  /**
   * An annotation does not follow the notation (SOM §11.9.5): an unclosed or
   * nested inline mark, a substitution without {@code ~>}, a comment id that is
   * not {@code C-<n>}, a question header that is not
   * {@code **❓ <ID> — <topic>:**}, or a question or answer inside a comment
   * block.
   */
  ANNOTATION_MALFORMED("annotationMalformed"),
  /**
   * A comment id or a question id is used twice in one document
   * (SOM §11.9.5).
   */
  DUPLICATE_ANNOTATION_ID("duplicateAnnotationId"),
  /**
   * A section's {@code units} (SOM §11.2) names an id no generation-unit entry
   * of the document declares.
   */
  UNKNOWN_UNIT("unknownUnit"),
  /**
   * A section carries {@code units}, but neither its class nor any class
   * reachable beneath it routes anything to CodeSpecs ({@code @CodeSpecKind}),
   * so the units would place nothing.
   */
  UNITS_UNROUTED("unitsUnrouted"),
  /** Two generation-unit entries declare one {@code unitId}; reported at the second. */
  DUPLICATE_UNIT_ID("duplicateUnitId"),
  /**
   * A generation-unit entry names neither a {@code deploymentTarget} nor a
   * {@code component}, so it builds nothing.
   */
  UNIT_BUILDS_NOTHING("unitBuildsNothing"),
  /**
   * A generation-unit mapping's {@code area} is not an area code ({@code CE-}
   * followed by capital letters).
   */
  UNIT_AREA_MALFORMED("unitAreaMalformed"),
  /**
   * A generation-unit emitter names no standard emitter
   * ({@link SpecGenerationUnits#SPEC_STANDARD_EMITTERS}: {@code openapi},
   * {@code jsonschema}, {@code icu}, {@code asyncapi}, {@code markdown}).
   */
  UNIT_EMITTER_UNKNOWN("unitEmitterUnknown"),

  // The link checks of one document (SpecLinkValidator#validateLinks,
  // tom_specs_model_rules.md §9.7). A stored derived value its sources do not
  // give is reported as derivedValueMismatch above.

  /** A {@code @DerivedFrom.lookup} finds no row for its key, or more than one. */
  DERIVED_LOOKUP_MISS("derivedLookupMiss"),
  /**
   * Two link rows beneath one element name the same id with the same type (the
   * values {@code @ExtractsLinks} sets); reported at the second.
   */
  DUPLICATE_LINK_ROW("duplicateLinkRow"),
  /**
   * A link names an entry whose other end ({@code inverseOf}) does not name it
   * back, or a symmetric row has no counterpart on the entry it names. An end
   * whose registry the document does not hold is skipped.
   */
  INVERSE_MISSING("inverseMissing"),
  /**
   * An id named in an {@code @ExtractsLinks} text has no row. An id that has a
   * row of any type is a reference to it and is not reported.
   */
  EXTRACTED_LINK_MISSING("extractedLinkMissing"),
  /**
   * A generated row (its {@code @ExtractsLinks} {@code set} values match) names
   * an id the text no longer names.
   */
  EXTRACTED_LINK_STALE("extractedLinkStale"),
  /** A summary row ({@code @SummaryOf}) names no element of its detail list. */
  SUMMARY_NOT_IN_DETAIL("summaryNotInDetail"),
  /** Under {@code relation: equal}, a detail element no summary row names. */
  DETAIL_NOT_IN_SUMMARY("detailNotInSummary"),
  /** Two summary rows name one detail element; reported at the second. */
  SUMMARY_DUPLICATE("summaryDuplicate"),
  /**
   * A {@code @SameAs} copy holds a value its holder does not (or lacks one it
   * holds): the two positions of the section were edited apart.
   */
  SAME_AS_MISMATCH("sameAsMismatch"),
  /**
   * A value a link check reads holds pending change marks. It is read with every
   * mark rejected (the reviewed state) and listed for the user.
   */
  LINK_VALUE_PENDING("linkValuePending"),
  /**
   * A change {@code deriveFields} would write in a document under review that
   * cannot be marked exactly (a difference inside fenced code, SOM §11.9.3); it
   * is left as it was, for the agent.
   */
  UNMARKABLE("unmarkable");

  public final String value;

  SpecValidationCode(String value) {
    this.value = value;
  }
}
