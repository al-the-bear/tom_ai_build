package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

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
   * The gap lines of an insufficient area, in the order Stage B found them;
   * empty for every other verdict, and for an insufficient area recorded before
   * its gaps were.
   */
  public final List<CodeSpecsGateGap> gaps;

  /**
   * Creates an entry. Shape is checked by {@link CodeSpecsGateRecord}, which is
   * the only thing that reads or writes entries.
   */
  public CodeSpecsGateEntry(
      String area, CodeSpecsGateVerdict verdict, String resolution, String note) {
    this(area, verdict, resolution, note, List.of());
  }

  /** As the four-argument constructor, with the area's gap lines. */
  public CodeSpecsGateEntry(
      String area,
      CodeSpecsGateVerdict verdict,
      String resolution,
      String note,
      List<CodeSpecsGateGap> gaps) {
    this.area = area;
    this.verdict = verdict;
    this.resolution = resolution;
    this.note = note;
    this.gaps =
        gaps == null
            ? List.of()
            : Collections.unmodifiableList(new ArrayList<>(gaps));
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
