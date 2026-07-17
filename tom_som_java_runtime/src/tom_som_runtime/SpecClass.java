package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** A model class with its fields. */
public final class SpecClass {
  public final String name;
  public final String sectionId;
  public final String doc;
  public final String help;

  /**
   * The class-level {@code @Headline(text)} default headline (YRD4), or
   * {@code null}. A field-level {@code @Headline} on the instantiating field
   * wins over this.
   */
  public final String headline;
  public final String mapsTo;
  public final String detailedIn;
  public final List<SpecField> fields;
  public final List<SpecAnnotation> annotations;

  public SpecClass(
      String name,
      String sectionId,
      String doc,
      String help,
      String headline,
      String mapsTo,
      String detailedIn,
      List<SpecField> fields,
      List<SpecAnnotation> annotations) {
    this.name = name;
    this.sectionId = sectionId;
    this.doc = doc;
    this.help = help;
    this.headline = headline;
    this.mapsTo = mapsTo;
    this.detailedIn = detailedIn;
    this.fields = fields;
    this.annotations = annotations;
  }

  @SuppressWarnings("unchecked")
  public static SpecClass fromJson(Map<String, Object> j) {
    List<SpecField> fields = new ArrayList<>();
    Object rawFields = j.get("fields");
    if (rawFields instanceof List) {
      for (Object e : (List<Object>) rawFields) {
        fields.add(SpecField.fromJson((Map<String, Object>) e));
      }
    }
    return new SpecClass(
        (String) j.get("name"),
        (String) j.get("sectionId"),
        (String) j.get("doc"),
        (String) j.get("help"),
        (String) j.get("headline"),
        (String) j.get("mapsTo"),
        (String) j.get("detailedIn"),
        fields,
        SpecAnnotation.listFromJson(j.get("annotations")));
  }

  public SpecField fieldNamed(String name) {
    for (SpecField f : fields) {
      if (f.name.equals(name)) {
        return f;
      }
    }
    return null;
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
