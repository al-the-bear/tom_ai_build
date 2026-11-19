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

  /**
   * The verdict {@code cls} carries, for the class node at {@code path}. The
   * three markers are mutually exclusive ({@code KIND-EXCLUSIVE}), so the order
   * they are tested in is a readability choice rather than a precedence rule.
   * Read through the model's own {@link SpecAnnotations} accessors, so the codes
   * are bare whatever spelling the meta chose. Shared by the extractor and the
   * impact walk ({@link SpecImpactWalk}).
   */
  public static CodeSpecsRouting codeSpecsClassRouting(SpecClass cls, String path) {
    KindLink code = cls.codeSpecKind();
    if (code != null) {
      return new CodeSpecsRouting(
          path, cls.name, CodeSpecsRoutingVerdict.FEEDS_CODE, code.kinds, code.note, cls.name);
    }
    KindLink followUp = cls.followUpKind();
    if (followUp != null) {
      return new CodeSpecsRouting(
          path,
          cls.name,
          CodeSpecsRoutingVerdict.FEEDS_PROCESS,
          followUp.kinds,
          followUp.note,
          cls.name);
    }
    NoArtifactLink none = cls.noArtifact();
    if (none != null) {
      return new CodeSpecsRouting(
          path,
          cls.name,
          CodeSpecsRoutingVerdict.FEEDS_NOTHING,
          Collections.singletonList(none.reason),
          none.note,
          cls.name);
    }
    if (cls.hasAnnotation("Document")) {
      return new CodeSpecsRouting(path, cls.name, CodeSpecsRoutingVerdict.DOCUMENT_ROOT);
    }
    return new CodeSpecsRouting(path, cls.name, CodeSpecsRoutingVerdict.UNROUTED);
  }

  /**
   * A field-level {@code @CodeSpecKind}, which overrides its class's routing for
   * that field alone; {@code null} when the field carries none.
   */
  public static CodeSpecsRouting codeSpecsFieldRouting(SpecClass cls, SpecField field) {
    KindLink code = field.codeSpecKind();
    if (code == null) {
      return null;
    }
    return new CodeSpecsRouting(
        "",
        cls.name,
        CodeSpecsRoutingVerdict.FEEDS_CODE,
        code.kinds,
        code.note,
        cls.name + "." + field.name);
  }

  @Override
  public String toString() {
    return "CodeSpecsRouting(" + path + ", " + className + ", " + verdict.value + ")";
  }
}
