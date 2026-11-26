package tom_som_runtime;

/**
 * Why a place or a filter does not parse or does not resolve
 * ({@code tom_specs_model_rules.md} §9.7); the corpus compares {@link #value}.
 */
public enum SpecPlaceProblem {
  /** The text is not a place (or not a filter) of the grammar. */
  MALFORMED("malformed"),
  /** The anchor path resolves to no section of the model. */
  ANCHOR_UNRESOLVED("anchorUnresolved"),
  /** The place is {@code ./}-scoped, but no list element lies at or above the anchor. */
  NOT_SCOPED("notScoped"),
  /** No section with the place's id (and {@code /} path) lies in the scope. */
  UNRESOLVED("unresolved"),
  /** The place's id is reached at more than one position in the scope. */
  AMBIGUOUS("ambiguous"),
  /** The named field is no form field of the section. */
  NO_SUCH_FIELD("noSuchField"),
  /** {@code .@content} names a section that holds no content value. */
  NO_CONTENT("noContent"),
  /** {@code .@sectionId} names a section that is no list element. */
  NOT_LIST_ELEMENT("notListElement"),
  /** A slot starting with {@code @} other than {@code @headline}, {@code @content}, {@code @sectionId}. */
  RESERVED_SLOT("reservedSlot");

  public final String value;

  SpecPlaceProblem(String value) {
    this.value = value;
  }
}
