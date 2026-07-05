package tom_som_runtime;

/**
 * Raised when a section id would collide with another id in the same list
 * (AA1 criterion 5: overriding an id must keep every id in the list unique) — a
 * faithful port of {@code SpecSectionIdCollision} in {@code spec_section_id.dart}
 * / {@code spec_section_id.py}.
 */
public final class SpecSectionIdCollision extends RuntimeException {
  private static final long serialVersionUID = 1L;
  public final String id;
  public final String listPath;

  public SpecSectionIdCollision(String id, String listPath) {
    super(
        "section id \""
            + id
            + "\" is already used in list \""
            + listPath
            + "\"; section ids within a list must be unique.");
    this.id = id;
    this.listPath = listPath;
  }
}
