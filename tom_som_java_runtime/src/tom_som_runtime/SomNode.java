package tom_som_runtime;

/**
 * The base class every generated typed facade class extends — a faithful port of
 * {@code som_facade.dart} / {@code som_facade.py}.
 *
 * <p>It binds a facade instance to the {@link SpecDocument} it edits and the
 * {@code path} it lives at (the globally-unique section path). The generated
 * subclass adds typed field accessors that delegate to {@code doc} at paths
 * derived from {@code path}.
 */
public class SomNode {
  public final SpecDocument doc;
  public final String path;

  public SomNode(SpecDocument doc, String path) {
    this.doc = doc;
    this.path = path;
  }

  /**
   * This node's section id when it is a list item (AA1 criterion 1 read), or
   * {@code null} for non-list nodes (roots, complex/section children — their id
   * is the fixed {@code @SectionId} already embedded in {@link #path}).
   *
   * <p>Named {@code $sectionId} — a name the Java emitter never produces for a
   * model-field accessor ({@code _acc} only keyword-sanitizes with a trailing
   * underscore, never a {@code $} prefix) — so this structural accessor can never
   * collide with a typed field a generated subclass emits (the Java equivalent
   * of the Dart {@code $sectionId} / Python {@code spec_section_id}
   * collision-proofing).
   */
  public String $sectionId() {
    return doc.itemSectionId(path);
  }

  /**
   * Overrides this list item's section id (AA1 criterion 5): an arbitrary suffix,
   * validated unique within the owning list. Raises
   * {@link SpecSectionIdCollision} on a duplicate, or
   * {@link IllegalArgumentException} if this node is not a live list item. A
   * {@code null} id is ignored.
   */
  public void $sectionId(String id) {
    if (id != null) {
      doc.setItemSectionId(path, id);
    }
  }
}
