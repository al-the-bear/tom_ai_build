package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Where a {@link SpecPlace} is stored in a document. */
public final class SpecPlaceResolution {
  /** The place resolved. */
  public final SpecPlace place;
  /** What the place is. */
  public final SpecPlaceKind kind;
  /**
   * The document path the value lives at, with every list item beneath the
   * anchor written {@code <list>-*}: the section (or list item) for a section, a
   * headline or a section id; the list for a list; the form for a form or a form
   * field; the content leaf for a content value.
   */
  public final String path;
  /** The class of the section the place sits on (for a member, its owner). */
  public final String className;
  /** The section ids on the way from the scope to the place, the place's own last. */
  public final List<String> sectionIds;
  /** For {@link SpecPlaceKind#FORM_FIELD}, the field; {@code null} otherwise. */
  public final FormFieldSpec formField;

  public SpecPlaceResolution(
      SpecPlace place,
      SpecPlaceKind kind,
      String path,
      String className,
      List<String> sectionIds,
      FormFieldSpec formField) {
    this.place = place;
    this.kind = kind;
    this.path = path;
    this.className = className;
    this.sectionIds = sectionIds;
    this.formField = formField;
  }

  /** The form field name for {@link SpecPlaceKind#FORM_FIELD}, else {@code null}. */
  public String field() {
    return formField == null ? null : formField.name;
  }

  /** The canonical JSON form the corpus compares. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("kind", kind.value);
    out.put("path", path);
    if (formField != null) {
      out.put("field", formField.name);
    }
    return out;
  }
}
