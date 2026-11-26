package tom_som_runtime;

/**
 * What a resolved {@link SpecPlace} is ({@code tom_specs_model_rules.md} §9.7);
 * the corpus compares {@link #value}.
 */
public enum SpecPlaceKind {
  /** A section (a class's own node or a complex member), whole. */
  SECTION("section"),
  /** A {@code -LST} list container. */
  LIST("list"),
  /** A form member, every field of it. */
  FORM("form"),
  /** One field of a form. */
  FORM_FIELD("formField"),
  /** The stored headline of a section ({@code .@headline}). */
  HEADLINE("headline"),
  /** The content value of a section ({@code .@content}, or a content member). */
  CONTENT("content"),
  /** The stored section id of a list element ({@code .@sectionId}). */
  SECTION_ID("sectionId");

  public final String value;

  SpecPlaceKind(String value) {
    this.value = value;
  }
}
