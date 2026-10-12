package tom_som_runtime;

/** One of {@code codespecs_prompt.md} §6.2's three per-area verdicts. */
public enum CodeSpecsGateVerdict {
  /** The extract carries every input the derivation contract requires. */
  SUFFICIENT("sufficient"),

  /**
   * The area does not apply — nothing was routed, with positive evidence of
   * absence ({@code codespecs_prompt.md} §6.4).
   */
  NOT_APPLICABLE("not applicable"),

  /**
   * The extract is missing required inputs; only a recorded descope lets a run
   * continue without the area.
   */
  INSUFFICIENT("insufficient");

  /** The verdict word exactly as {@code codespecs_prompt.md} §6.2 states it. */
  public final String word;

  CodeSpecsGateVerdict(String word) {
    this.word = word;
  }

  /** The verdict for {@code word}, or {@code null} for a word §6.2 does not know. */
  public static CodeSpecsGateVerdict parse(String word) {
    for (CodeSpecsGateVerdict v : values()) {
      if (v.word.equals(word)) {
        return v;
      }
    }
    return null;
  }
}
