package tom_som_runtime;

/** One area's recorded verdict in the gate record. */
public final class CodeSpecsGateEntry {
  /**
   * The one resolution a gate record may carry: an insufficient area the user
   * decided to leave out.
   */
  public static final String DESCOPED = "descoped";

  /** The area's {@code CE-*} code. */
  public final String area;

  /** The verdict. */
  public final CodeSpecsGateVerdict verdict;

  /** {@code descoped}, on an insufficient area only; otherwise {@code null}. */
  public final String resolution;

  /** A free-text note — why the verdict was taken. Never read as data. */
  public final String note;

  /**
   * Creates an entry. Shape is checked by {@link CodeSpecsGateRecord}, which is
   * the only thing that reads or writes entries.
   */
  public CodeSpecsGateEntry(
      String area, CodeSpecsGateVerdict verdict, String resolution, String note) {
    this.area = area;
    this.verdict = verdict;
    this.resolution = resolution;
    this.note = note;
  }

  public CodeSpecsGateEntry(String area, CodeSpecsGateVerdict verdict) {
    this(area, verdict, null, null);
  }

  /** Whether this is an insufficient area resolved by descoping. */
  public boolean descoped() {
    return DESCOPED.equals(resolution);
  }

  @Override
  public String toString() {
    return "CodeSpecsGateEntry(" + area + ", " + verdict.word + ")";
  }
}
