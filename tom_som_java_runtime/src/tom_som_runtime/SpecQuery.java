package tom_som_runtime;

import java.util.Set;

/**
 * An AND-combined lexical/structural query ({@code llm_and_d4rt_tools.md} §6).
 * Every supplied dimension must hold for a node to match; an all-{@code null}
 * query matches every node in the document's structural closure.
 *
 * <p>Eleven optional dimensions, carried as nullable fields on one constructor —
 * the same plain-value-object idiom {@link SpecField} and {@link FormFieldSpec}
 * use for their optional-heavy shapes. {@link #SpecQuery()} builds the
 * everything-matches query (Dart's {@code const SpecQuery()}).
 */
public final class SpecQuery {
  /**
   * Substring (or {@link #regex} pattern) to find in content + form values and
   * the headline.
   */
  public final String text;

  /**
   * Treat {@link #text} as a {@link SomTextPattern} — the portable pattern subset
   * ({@code .}, {@code *}, {@code +}, {@code ?}, {@code […]}, {@code ^},
   * {@code $}) — instead of a literal substring. Named {@code regex} because that
   * is what a caller reaches for it expecting; the grammar is deliberately
   * narrower than a full regex, and {@link SomPatternError} says so rather than
   * silently reinterpreting.
   */
  public final boolean regex;

  /** Match {@link #text} case-insensitively. */
  public final boolean caseInsensitive;

  /** The node kinds to include (any-of); {@code null} admits every kind. */
  public final Set<SpecNodeKind> kinds;

  /** The model class name a node must <i>be</i> ({@link SpecResolution#targetClass}). */
  public final String className;

  /** The node's {@code @SectionId} must equal this exactly. */
  public final String sectionIdExact;

  /** The node's {@code @SectionId} must start with this prefix. */
  public final String sectionIdPrefix;

  /**
   * A glob over the node's path ({@code *} matches within one segment,
   * {@code **} across segments).
   */
  public final String pathGlob;

  /** The node's class must carry {@code @MapsTo(<this>)}. */
  public final String mapsTo;

  /** The node's class must carry {@code @DetailedIn(<this>)}. */
  public final String detailedIn;

  /** The node's value-presence state must match this. */
  public final SpecStateFilter state;

  /** The query with every dimension unset — matches the whole structural closure. */
  public SpecQuery() {
    this(null, false, false, null, null, null, null, null, null, null, null);
  }

  public SpecQuery(
      String text,
      boolean regex,
      boolean caseInsensitive,
      Set<SpecNodeKind> kinds,
      String className,
      String sectionIdExact,
      String sectionIdPrefix,
      String pathGlob,
      String mapsTo,
      String detailedIn,
      SpecStateFilter state) {
    this.text = text;
    this.regex = regex;
    this.caseInsensitive = caseInsensitive;
    this.kinds = kinds;
    this.className = className;
    this.sectionIdExact = sectionIdExact;
    this.sectionIdPrefix = sectionIdPrefix;
    this.pathGlob = pathGlob;
    this.mapsTo = mapsTo;
    this.detailedIn = detailedIn;
    this.state = state;
  }
}
