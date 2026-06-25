package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** A single field of a {@link SpecClass}. */
public final class SpecField {
  public final String name;
  public final SpecFieldKind kind;
  public final String doc;
  public final String help;
  public final String sectionId;
  public final String sectionIdPattern;
  public final String elementType;
  public final boolean elementIsComplex;
  public final Integer min;
  public final String contentType;
  public final String sectionType;
  public final String enumType;
  public final List<String> enumValues;
  public final String type;
  public final List<FormFieldSpec> formFields;
  public final List<SpecAnnotation> annotations;

  public SpecField(
      String name,
      SpecFieldKind kind,
      String doc,
      String help,
      String sectionId,
      String sectionIdPattern,
      String elementType,
      boolean elementIsComplex,
      Integer min,
      String contentType,
      String sectionType,
      String enumType,
      List<String> enumValues,
      String type,
      List<FormFieldSpec> formFields,
      List<SpecAnnotation> annotations) {
    this.name = name;
    this.kind = kind;
    this.doc = doc;
    this.help = help;
    this.sectionId = sectionId;
    this.sectionIdPattern = sectionIdPattern;
    this.elementType = elementType;
    this.elementIsComplex = elementIsComplex;
    this.min = min;
    this.contentType = contentType;
    this.sectionType = sectionType;
    this.enumType = enumType;
    this.enumValues = enumValues;
    this.type = type;
    this.formFields = formFields;
    this.annotations = annotations;
  }

  @SuppressWarnings("unchecked")
  public static SpecField fromJson(Map<String, Object> j) {
    List<String> enumValues = new ArrayList<>();
    Object rawEnum = j.get("enumValues");
    if (rawEnum instanceof List) {
      for (Object e : (List<Object>) rawEnum) {
        enumValues.add(e == null ? "" : e.toString());
      }
    }
    List<FormFieldSpec> formFields = new ArrayList<>();
    Object rawForm = j.get("formFields");
    if (rawForm instanceof List) {
      for (Object e : (List<Object>) rawForm) {
        formFields.add(FormFieldSpec.fromJson((Map<String, Object>) e));
      }
    }
    Object min = j.get("min");
    return new SpecField(
        (String) j.get("name"),
        SpecFieldKind.parse((String) j.get("kind")),
        (String) j.get("doc"),
        (String) j.get("help"),
        (String) j.get("sectionId"),
        (String) j.get("sectionIdPattern"),
        (String) j.get("elementType"),
        Boolean.TRUE.equals(j.get("elementIsComplex")),
        min instanceof Number ? ((Number) min).intValue() : null,
        (String) j.get("contentType"),
        (String) j.get("sectionType"),
        (String) j.get("enumType"),
        enumValues,
        (String) j.get("type"),
        formFields,
        SpecAnnotation.listFromJson(j.get("annotations")));
  }

  /** Whether expanding this field reveals further tree nodes. */
  public boolean isExpandable() {
    return kind == SpecFieldKind.LIST || kind == SpecFieldKind.COMPLEX;
  }

  public SpecAnnotation annotation(String name) {
    for (SpecAnnotation a : annotations) {
      if (a.name.equals(name)) {
        return a;
      }
    }
    return null;
  }
}
