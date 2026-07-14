package tom_som_runtime;

/**
 * One {@code document.sections} slot of a DocSpecs schema — a faithful port of
 * the Go {@code DocSpecsDocumentSection}.
 */
public final class DocSpecsDocumentSection {
  public final String sectionType;
  public final boolean optional;

  public DocSpecsDocumentSection(String sectionType, boolean optional) {
    this.sectionType = sectionType;
    this.optional = optional;
  }
}
