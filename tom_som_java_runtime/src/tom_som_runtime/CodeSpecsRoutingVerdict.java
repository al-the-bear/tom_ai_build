package tom_som_runtime;

/**
 * Which of the three {@code codespecs_mapping.md} §8.3 verdicts a class carries.
 */
public enum CodeSpecsRoutingVerdict {
  /**
   * {@code @CodeSpecKind(List<CodeSpecPart>)} — the section's content is shown to
   * every named area's extract.
   */
  FEEDS_CODE("feedsCode"),

  /**
   * {@code @FollowUpKind(List<FollowUpProcess>)} — the section is delivered by a
   * non-generation process. The whole subtree is excluded from every extract.
   */
  FEEDS_PROCESS("feedsProcess"),

  /**
   * {@code @NoArtifact(NoArtifactReason)} — the section deliberately produces no
   * downstream artifact. Its own leaves contribute nothing; its children are
   * still routed individually (that is what {@code container} means).
   */
  FEEDS_NOTHING("feedsNothing"),

  /**
   * A {@code @Document} root carrying no verdict. Structurally exempt from
   * {@code ROUTE-TOTAL}: a root is the document, not a section of it.
   */
  DOCUMENT_ROOT("documentRoot"),

  /**
   * No verdict, and not a {@code @Document} root — a {@code ROUTE-TOTAL}
   * violation, and the reason {@link CodeSpecsExtractor#extractAll} throws.
   */
  UNROUTED("unrouted");

  /** The wire spelling, shared by all nine runtimes. */
  public final String value;

  CodeSpecsRoutingVerdict(String value) {
    this.value = value;
  }
}
