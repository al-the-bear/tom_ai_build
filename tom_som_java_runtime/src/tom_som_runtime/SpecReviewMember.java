package tom_som_runtime;

/** A member of a review team (SOM §11.9.8): who reviews a copy in a team review. */
public final class SpecReviewMember {
  /** The member id: lowercase letters, digits and {@code _}. */
  public final String memberId;

  /** The name a tool shows. */
  public final String displayName;

  /** The member's role in the review, e.g. {@code Developer}. */
  public final String role;

  public SpecReviewMember(String memberId, String displayName, String role) {
    this.memberId = memberId;
    this.displayName = displayName == null ? "" : displayName;
    this.role = role == null ? "" : role;
  }
}
