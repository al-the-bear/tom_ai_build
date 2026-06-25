package tom_som_runtime;

import java.util.Map;

/** A document root (a class carrying {@code @Document}). */
public final class SpecRoot {
  public final String type;
  public final String title;
  public final String sectionId;
  public final String description;
  public final String doc;

  public SpecRoot(
      String type, String title, String sectionId, String description, String doc) {
    this.type = type;
    this.title = title;
    this.sectionId = sectionId;
    this.description = description;
    this.doc = doc;
  }

  public static SpecRoot fromJson(Map<String, Object> j) {
    return new SpecRoot(
        (String) j.get("type"),
        (String) j.get("title"),
        (String) j.get("sectionId"),
        (String) j.get("description"),
        (String) j.get("doc"));
  }
}
