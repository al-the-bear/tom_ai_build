package tom_som_runtime;

/**
 * One gap line of an insufficient area ({@code codespecs_prompt.md} §6.3): a
 * missing input, and the section field that should have carried it.
 *
 * <p>Stage C creates one L0 {@code csopen} todo per gap line, so two sections
 * missing the same field are two gaps — which is why the record carries them as
 * data rather than leaving them in the note.
 */
public final class CodeSpecsGateGap {
  /** The section whose content is missing the input. */
  public final String sectionId;

  /** What the derivation contract required, in one line. */
  public final String required;

  /** {@code <section-id>.<field>} — the field that should have carried it. */
  public final String carrier;

  /** Creates a gap. Shape is checked by {@link CodeSpecsGateRecord}. */
  public CodeSpecsGateGap(String sectionId, String required, String carrier) {
    this.sectionId = sectionId;
    this.required = required;
    this.carrier = carrier;
  }

  /** The gap as the §6.3 output line, without its indentation. */
  public String line() {
    return sectionId + " — " + required + " — should have been carried by " + carrier;
  }

  @Override
  public String toString() {
    return "CodeSpecsGateGap(" + line() + ")";
  }
}
