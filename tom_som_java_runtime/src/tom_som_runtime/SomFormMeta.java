package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/**
 * The form metadata of a {@code @Form} node (DR1 §3.1 FormMeta) — a faithful
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

  /** The title-role field (YRD6), or {@code null} when the form declares none. */
  public SomFormFieldMeta titleField() {
    for (SomFormFieldMeta field : fields) {
      if ("title".equals(field.role)) {
        return field;
      }
    }
    return null;
  }

  /** The id-role field (YRD6), or {@code null} when the form declares none. */
  public SomFormFieldMeta idField() {
    for (SomFormFieldMeta field : fields) {
      if ("id".equals(field.role)) {
        return field;
      }
    }
    return null;
  }
}
