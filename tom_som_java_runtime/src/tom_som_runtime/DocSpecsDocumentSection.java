package tom_som_runtime;

/**
 * One {@code document.sections} slot of a DocSpecs schema — a faithful port of
 * the Go {@code DocSpecsDocumentSection}: the backing section-type, whether the
 * slot is optional, and its {@code position} — {@code relative} (the default:
 * in the order of {@code document: sections:}) or {@code any} (anywhere among
 * the root's children; the order check leaves it out).
 */
public final class DocSpecsDocumentSection {
  /** The {@code position} values a document section may take. */
  public static final String POSITION_RELATIVE = "relative";

  public static final String POSITION_ANY = "any";

  public final String sectionType;
  public final boolean optional;
  public final String position;

  public DocSpecsDocumentSection(String sectionType, boolean optional) {
    this(sectionType, optional, POSITION_RELATIVE);
  }

  public DocSpecsDocumentSection(String sectionType, boolean optional, String position) {
    this.sectionType = sectionType;
    this.optional = optional;
    this.position = position;
  }

  /** Whether the section may stand anywhere among the root's children. */
  public boolean anyPosition() {
    return POSITION_ANY.equals(position);
  }
}
