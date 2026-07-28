package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/**
 * The form metadata of a {@code @Form} node (SOM §7.1 FormMeta) — a faithful
 * port of {@code spec_meta.dart} / {@code spec_meta.ts}.
 */
public final class SomFormMeta {
  /** The form's fields, in declaration order. */
  public final List<SomFormFieldMeta> fields;

  public SomFormMeta(List<SomFormFieldMeta> fields) {
    this.fields = fields != null ? fields : new ArrayList<>();
  }

  /** The field named {@code name}, or {@code null} when absent. */
  public SomFormFieldMeta fieldNamed(String name) {
    for (SomFormFieldMeta field : fields) {
      if (field.name.equals(name)) {
        return field;
      }
    }
    return null;
  }
}
