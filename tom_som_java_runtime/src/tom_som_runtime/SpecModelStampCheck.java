package tom_som_runtime;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

/**
 * The outcome of checking a loaded snapshot's generation stamp against its own
 * payload and against the clock — see {@link SpecModel#checkStamp}.
 *
 * <p>The two findings are independent and can both hold at once: {@link #isAged}
 * says the snapshot is probably behind the live model, while
 * {@link #countsDisagree} says the file no longer describes itself correctly.
 * Only the second is a defect in the file.
 */
public final class SpecModelStampCheck {
  /**
   * How long ago the snapshot was generated, or {@code null} when it carries no
   * {@code generatedAt} (an older export, or a hand-built model).
   */
  public final Duration age;
  /** The threshold {@link #age} was judged against. */
  public final Duration maxAge;
  /** The class count the stamp declares, or {@code null} when it declares none. */
  public final Integer declaredClassCount;
  /** The number of classes the payload actually carries. */
  public final int actualClassCount;
  /** The document-root count the stamp declares, or {@code null}. */
  public final Integer declaredRootCount;
  /** The number of document roots the payload actually carries. */
  public final int actualRootCount;

  public SpecModelStampCheck(
      Duration age,
      Duration maxAge,
      Integer declaredClassCount,
      int actualClassCount,
      Integer declaredRootCount,
      int actualRootCount) {
    this.age = age;
    this.maxAge = maxAge;
    this.declaredClassCount = declaredClassCount;
    this.actualClassCount = actualClassCount;
    this.declaredRootCount = declaredRootCount;
    this.actualRootCount = actualRootCount;
  }

  /**
   * Whether the snapshot is older than {@link #maxAge}. Always false when it
   * carries no {@code generatedAt} — an unknown age is not evidence of a stale
   * one.
   */
  public boolean isAged() {
    return age != null && age.compareTo(maxAge) > 0;
  }

  /**
   * Whether the declared and actual class counts differ.
   *
   * <p>An absent declaration is not a disagreement: older snapshots predate the
   * stamp keys, and reading absent as {@code 0} would make every one of them
   * look corrupt.
   */
  public boolean classCountDisagrees() {
    return declaredClassCount != null && declaredClassCount != actualClassCount;
  }

  /**
   * Whether the declared and actual root counts differ. Absent declarations are
   * ignored, as for {@link #classCountDisagrees}.
   */
  public boolean rootCountDisagrees() {
    return declaredRootCount != null && declaredRootCount != actualRootCount;
  }

  /**
   * Whether either declared size disagrees with the payload.
   *
   * <p>The exporter derives both counts <i>from</i> the payload it writes, so a
   * disagreement cannot arise from a normal export — it means the file was
   * edited or truncated afterwards.
   */
  public boolean countsDisagree() {
    return classCountDisagrees() || rootCountDisagrees();
  }

  /** Whether anything at all was found. */
  public boolean isStale() {
    return isAged() || countsDisagree();
  }

  /**
   * The findings as ready-to-display sentences, empty when there are none. The
   * wording is identical in all nine runtimes.
   */
  public List<String> warnings() {
    List<String> out = new ArrayList<>();
    if (isAged()) {
      out.add(
          "Snapshot is " + age.toDays() + " days old (threshold " + maxAge.toDays()
              + " days) — the model may have moved on since it was exported.");
    }
    if (classCountDisagrees()) {
      out.add(
          "Stamp declares " + declaredClassCount + " classes but the snapshot carries "
              + actualClassCount + " — it was edited after export.");
    }
    if (rootCountDisagrees()) {
      out.add(
          "Stamp declares " + declaredRootCount + " document roots but the snapshot carries "
              + actualRootCount + " — it was edited after export.");
    }
    return out;
  }
}
