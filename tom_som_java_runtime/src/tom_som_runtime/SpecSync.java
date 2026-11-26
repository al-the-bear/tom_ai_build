package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * {@code @SyncedWith(document, {detailOnly, heldHere, relations, note})}: the
 * annotated section is kept in sync with the section of the same id in
 * {@link #document} ({@code tom_specs_model_rules.md} §9.7).
 */
public final class SpecSync {
  /** The other document's root class name. */
  public final String document;
  /** The places only {@link #document} carries. */
  public final List<String> detailOnly;
  /** The places whose value this document holds. */
  public final List<String> heldHere;
  /** The lists whose relation is not {@code equal}. */
  public final List<SpecListRelation> relations;
  /** The annotation's free-text note, {@code null} when it carries none. */
  public final String note;

  public SpecSync(
      String document,
      List<String> detailOnly,
      List<String> heldHere,
      List<SpecListRelation> relations,
      String note) {
    this.document = document;
    this.detailOnly = detailOnly;
    this.heldHere = heldHere;
    this.relations = relations;
    this.note = note;
  }

  /** Reads the sync out of a {@code @SyncedWith} annotation. */
  public static SpecSync fromAnnotation(SpecAnnotation annotation) {
    LinkArguments a = LinkArguments.of(annotation);
    List<SpecListRelation> relations = new ArrayList<>();
    for (LinkArguments r : a.objects("relations")) {
      relations.add(SpecListRelation.from(r));
    }
    return new SpecSync(
        a.str("document", ""),
        a.stringList("detailOnly"),
        a.stringList("heldHere"),
        Collections.unmodifiableList(relations),
        a.optString("note"));
  }

  /** The canonical JSON form, an absent note left out. */
  public Map<String, Object> toJson() {
    List<Object> rels = new ArrayList<>();
    for (SpecListRelation r : relations) {
      rels.add(r.toJson());
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("document", document);
    out.put("detailOnly", LinkArguments.stringsJson(detailOnly));
    out.put("heldHere", LinkArguments.stringsJson(heldHere));
    out.put("relations", rels);
    if (note != null) {
      out.put("note", note);
    }
    return out;
  }
}
