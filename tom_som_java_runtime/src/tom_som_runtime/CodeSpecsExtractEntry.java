package tom_som_runtime;

/**
 * One extract entry: a single value the specification document stores, with
 * everything needed to trace it back ({@code codespecs_mapping.md} §1.1.1,
 * "Entry").
 */
public final class CodeSpecsExtractEntry {
  /** The {@code CE-*} code of the area this entry was collected for. */
  public final String areaCode;

  /**
   * The section id of the leaf the value sits on ({@code @SectionId}, else the
   * model field name).
   */
  public final String sectionId;

  /**
   * The enclosing section instance's headline, copy-only like {@link #value}:
   * the document's <b>stored</b> headline for the class node the leaf sits
   * under (YRD3), else the class's {@code @Headline} type default (YRD4), else
   * {@code null}. Gives naming rule N1 a real source — never a derivation.
   */
  public final String headline;

  /** The document path of the leaf — the source location. */
  public final String path;

  /** The model class declaring the leaf. */
  public final String className;

  /** The model field name of the leaf. */
  public final String fieldName;

  /**
   * The form-field name when the value is one field of a {@code @Form} section;
   * {@code null} for a content, enum, scalar or scalar-list leaf.
   */
  public final String formField;

  /** The {@code CodeSpecPart.*} value that routed this entry here, verbatim. */
  public final String routedBy;

  /**
   * Where that {@code @CodeSpecKind} was declared — the class name, or
   * {@code Class.field} for a field-level override.
   */
  public final String routedAt;

  /** The {@code @CodeSpecKind} {@code note}, verbatim; {@code null} when it carries none. */
  public final String routingNote;

  /** The stored value, <b>verbatim</b>. Never assembled, reformatted or trimmed. */
  public final String value;

  public CodeSpecsExtractEntry(
      String areaCode,
      String sectionId,
      String headline,
      String path,
      String className,
      String fieldName,
      String formField,
      String routedBy,
      String routedAt,
      String routingNote,
      String value) {
    this.areaCode = areaCode;
    this.sectionId = sectionId;
    this.headline = headline;
    this.path = path;
    this.className = className;
    this.fieldName = fieldName;
    this.formField = formField;
    this.routedBy = routedBy;
    this.routedAt = routedAt;
    this.routingNote = routingNote;
    this.value = value;
  }

  @Override
  public String toString() {
    return "CodeSpecsExtractEntry(" + areaCode + ", " + path + ")";
  }
}
