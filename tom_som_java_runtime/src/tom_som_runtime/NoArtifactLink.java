package tom_som_runtime;

/**
 * The third routing verdict: {@code @NoArtifact(NoArtifactReason, {note})} — the
 * section feeds neither a CodeSpecs part nor a follow-up process
 * ({@code codespecs_mapping.md} §8.3).
 *
 * <p>Single-valued where {@link KindLink} is a list, and the asymmetry is the
 * point: a section can feed several parts or several processes at once, but it
 * is unrouted for exactly one reason. That reason is what makes the absence of
 * the other two markers readable as a decision rather than an omission, which is
 * what {@code tom_specs_model_rules.md} §10.2 invariant {@code ROUTE-TOTAL}
 * checks.
 */
public final class NoArtifactLink {
  /**
   * The {@code NoArtifactReason} code name with its type prefix stripped —
   * {@code container}, not {@code NoArtifactReason.container}. One of
   * {@code container}, {@code overview}, {@code view}.
   */
  public final String reason;

  /**
   * The annotation's free-text {@code note}. On an {@code overview} this
   * customarily names the routed section that states the material normatively.
   */
  public final String note;

  public NoArtifactLink(String reason, String note) {
    this.reason = reason;
    this.note = note;
  }

  /** Reads the verdict out of {@code annotation}. */
  public static NoArtifactLink fromAnnotation(SpecAnnotation annotation) {
    Object reason = annotation.argument("reason");
    return new NoArtifactLink(
        SpecAnnotations.stripEnumPrefix(reason == null ? "container" : reason.toString()),
        (String) annotation.argument("note"));
  }
}
