package tom_som_runtime;

import java.util.List;

/**
 * A flat, value-bearing projection of one document node — everything the tier-1
 * structural/lexical index ({@code llm_and_d4rt_tools.md} §9.2) needs to index a
 * section <b>without re-walking the model itself</b>: its path, kind, class, the
 * structural facets (section id, {@code @MapsTo} / {@code @DetailedIn}), the
 * headline, the searchable strings (stored values + headline), and whether it
 * currently holds a value.
 *
 * <p>Produced by {@link SpecQueryEngine#projectNodes} /
 * {@link SpecQueryEngine#projectNode}, which reuse the same structural-closure
 * walk and value extraction the live query uses — so the index and the live
 * {@code llm_and_d4rt_tools.md} §6 search agree on what a node is and what text
 * it carries — with no model (LLM) calls.
 */
public final class SpecNodeProjection {
  /** The globally-unique section-id path the node lives at. */
  public final String path;

  /** What kind of node the path lands on. */
  public final SpecNodeKind kind;

  /** The model class the node <i>is</i> ({@code null} for value leaves and list containers). */
  public final String classId;

  /** The node's {@code @SectionId} (field, class, or root), {@code null} when none. */
  public final String sectionId;

  /** The {@code @MapsTo} target on the node's class, {@code null} when none. */
  public final String mapsTo;

  /** The {@code @DetailedIn} target on the node's class, {@code null} when none. */
  public final String detailedIn;

  /**
   * The node's headline — the stored one when the author set it, else the model's
   * doc comment. {@code null} when neither exists.
   */
  public final String headline;

  /**
   * The strings a text search indexes for this node: stored values (content,
   * scalar item, every form-field value) followed by the headline. Empty for a
   * container node that carries no direct value and has no headline.
   */
  public final List<String> searchableStrings;

  /**
   * Whether the node (or anything beneath it) currently holds a value — the
   * {@code state} facet (empty vs non-empty).
   */
  public final boolean hasValue;

  public SpecNodeProjection(
      String path,
      SpecNodeKind kind,
      String classId,
      String sectionId,
      String mapsTo,
      String detailedIn,
      String headline,
      List<String> searchableStrings,
      boolean hasValue) {
    this.path = path;
    this.kind = kind;
    this.classId = classId;
    this.sectionId = sectionId;
    this.mapsTo = mapsTo;
    this.detailedIn = detailedIn;
    this.headline = headline;
    this.searchableStrings = searchableStrings;
    this.hasValue = hasValue;
  }

  @Override
  public String toString() {
    return "SpecNodeProjection(" + path + ", " + kind.value + ")";
  }
}
