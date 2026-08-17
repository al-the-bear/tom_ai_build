package tom_som_runtime;

import java.util.Collections;
import java.util.List;

/**
 * The verdict recorded for one class node of the walked document, with the
 * provenance of the marker that decided it.
 */
public final class CodeSpecsRouting {
  /** The document path of the node the verdict was computed for. */
  public final String path;

  /** The model class at {@link #path}. */
  public final String className;

  /** Which verdict the class carries. */
  public final CodeSpecsRoutingVerdict verdict;

  /**
   * The verdict's payload, verbatim from the annotation: the
   * {@code CodeSpecPart.*} values for {@link CodeSpecsRoutingVerdict#FEEDS_CODE},
   * the {@code FollowUpProcess.*} values for
   * {@link CodeSpecsRoutingVerdict#FEEDS_PROCESS}, the single
   * {@code NoArtifactReason.*} for {@link CodeSpecsRoutingVerdict#FEEDS_NOTHING},
   * and empty for the two verdicts that have no marker.
   */
  public final List<String> values;

  /** The marker's optional {@code note}, verbatim; {@code null} when it carries none. */
  public final String note;

  /**
   * Where the marker was declared — the class name, or {@code Class.field} when a
   * field-level {@code @CodeSpecKind} overrode its class. Empty when there is no
   * marker.
   */
  public final String declaredAt;

  public CodeSpecsRouting(
      String path,
      String className,
      CodeSpecsRoutingVerdict verdict,
      List<String> values,
      String note,
      String declaredAt) {
    this.path = path;
    this.className = className;
    this.verdict = verdict;
    this.values = values == null ? Collections.<String>emptyList() : values;
    this.note = note;
    this.declaredAt = declaredAt == null ? "" : declaredAt;
  }

  /** A verdict with no marker — no payload, no note, declared nowhere. */
  public CodeSpecsRouting(String path, String className, CodeSpecsRoutingVerdict verdict) {
    this(path, className, verdict, Collections.<String>emptyList(), null, "");
  }

  @Override
  public String toString() {
    return "CodeSpecsRouting(" + path + ", " + className + ", " + verdict.value + ")";
  }
}
