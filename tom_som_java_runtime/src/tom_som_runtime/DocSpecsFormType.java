package tom_som_runtime;

import java.util.List;

/**
 * One {@code form-types} entry of a DocSpecs schema — a faithful port of the
 * Go {@code DocSpecsFormType}.
 */
public final class DocSpecsFormType {
  public final String name;
  public final List<DocSpecsFormField> fields;

  public DocSpecsFormType(String name, List<DocSpecsFormField> fields) {
    this.name = name;
    this.fields = fields;
  }
}
