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

  /**
   * The stored headline of this section (YRD3), or {@code null} when it renders
   * its effective default title.
   *
   * <p>Named {@code $headline} for the same collision-proofing reason as
   * {@link #$sectionId()}: the emitter never produces a {@code $}-prefixed
   * accessor, so a typed field named {@code headline} cannot collide.
   */
  public String $headline() {
    return doc.headline(path);
  }

  /**
   * Sets this section's stored headline (YRD3). An empty value clears it,
   * returning the section to its default title. A {@code null} value is
   * ignored.
   */
  public void $headline(String value) {
    if (value != null) {
      doc.setHeadline(path, value);
    }
  }

  /**
   * True iff this section holds no value at its {@link #path} or nested beneath
   * it (SOM § item 5) — delegates to {@link SpecDocument#hasValuesUnder}.
   * Inherited by every generated section facade.
   */
  public boolean isEmpty() {
    return !doc.hasValuesUnder(path);
  }

  /**
   * Whether this section <b>type</b> declares the standard {@code content} text
   * leaf — i.e. whether the {@code content()} getter/setter exists on it
   * (SOM § item 10).
   *
   * <p>This is a <b>structural / schema</b> predicate: a compile-time constant of
   * the section's type, answering "<em>can</em> this section hold body text?"
   * without a compile-error probe of {@code content()}. Container-only sections
   * (e.g. {@code SystemsToReplace}, which has no {@code content} leaf) inherit
   * this {@code false} default; content-bearing sections (e.g. {@code Goals})
   * override it to {@code true}.
   *
   * <p>It is deliberately distinct from the two <b>state</b> predicates: the
   * generic {@link SpecDocument#hasContent} answers "is a value present at this
   * leaf <em>now</em>?" and {@link #isEmpty} answers "is this subtree empty
   * <em>now</em>?". {@code canHaveContent} never looks at the document — it
   * describes the model, not the data.
   */
  public boolean canHaveContent() {
    return false;
  }
}
