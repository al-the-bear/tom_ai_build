package tom_som_runtime;

/**
 * The outcome of the SOM §4.2 version check, as a value a read-only viewer can
 * branch on instead of catching {@link SomVersionError} (SOM §21).
 *
 * <p>It is the non-throwing companion to
 * {@link SomFacade#checkModelVersion(String, String)}: the constructor throws on
 * any value other than {@link #EDITABLE}, while
 * {@link SomFacade#somEditabilityFor(String, String)} returns the same
 * classification without throwing so a consumer can decide <em>open for edit</em>
 * vs <em>open read-only</em> up front.
 */
public enum SomEditability {
  /**
   * The object model may edit the document in place — a {@code null}/empty stamp
   * (a brand-new document) or a same-major, minor-{@code ≤} stamp.
   */
  EDITABLE,

  /**
   * The document was authored under a <b>different major</b> version; it may be
   * read/converted but never edited in place.
   */
  READ_ONLY_CROSS_MAJOR,

  /**
   * The document is same-major but a <b>newer minor</b> than the object model;
   * an older model must not edit a newer document.
   */
  REJECTED_NEWER_MINOR,

  /**
   * One of the two versions is not a valid {@code major.minor} string — usually
   * the document stamp, but a malformed <em>generated</em> version lands here
   * too. One outcome with two causes; the refusal message thrown by
   * {@link SomFacade#checkModelVersion(String, String)} is where they separate.
   */
  INVALID_VERSION,
}
