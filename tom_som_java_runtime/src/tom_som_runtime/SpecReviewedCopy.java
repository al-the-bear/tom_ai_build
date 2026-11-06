package tom_som_runtime;

/**
 * One returned copy of a team review (SOM §11.9.9): its reviewer and the copy's document — a
 * {@link SpecDocument}, or a plain Markdown {@link String}.
 *
 * @param <D> the document type, the base's
 */
public final class SpecReviewedCopy<D> {
  /** The reviewer who returned the copy. */
  public final SpecReviewMember member;

  /** The copy's document. */
  public final D document;

  public SpecReviewedCopy(SpecReviewMember member, D document) {
    this.member = member;
    this.document = document;
  }

  public SpecReviewedCopy(String memberId, String displayName, String role, D document) {
    this(new SpecReviewMember(memberId, displayName, role), document);
  }
}
