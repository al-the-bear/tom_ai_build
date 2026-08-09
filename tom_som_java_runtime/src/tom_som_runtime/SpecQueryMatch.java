package tom_som_runtime;

import java.util.List;

/**
 * One node matched by a {@link SpecQuery} (the {@code llm_and_d4rt_tools.md} §6
 * cursor record).
 */
public final class SpecQueryMatch {
  /** The globally-unique section-ID path the node lives at. */
  public final String path;

  /** What kind of node the path lands on. */
  public final SpecNodeKind kind;

  /** The model class the node <i>is</i> ({@code null} for value leaves and list containers). */
  public final String classId;

  /**
   * The node's headline — stored if the author set one, else the model's doc
   * comment ({@code null} when neither exists).
   */
  public final String headline;

  /**
   * The matched text, when the query carried a {@code text} dimension
   * ({@code null} otherwise) — the value/headline that the pattern hit.
   */
  public final String snippet;

  /**
   * The spans within {@link #snippet} the {@code text} pattern matched (empty for
   * non-text queries).
   */
  public final List<SpecMatchSpan> matchSpans;

  public SpecQueryMatch(
      String path,
      SpecNodeKind kind,
      String classId,
      String headline,
      String snippet,
      List<SpecMatchSpan> matchSpans) {
    this.path = path;
    this.kind = kind;
    this.classId = classId;
    this.headline = headline;
    this.snippet = snippet;
    this.matchSpans = matchSpans;
  }

  @Override
  public String toString() {
    return "SpecQueryMatch(" + path + ", " + kind.value + ")";
  }
}
