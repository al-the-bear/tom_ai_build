package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/**
 * The annotation lookups shared by the two model nodes that carry annotations —
 * {@link SpecClass} and {@link SpecField}.
 *
 * <p>The Dart reference states these once as the {@code AnnotatedSpecNode}
 * mixin. Java has no mixin, and this runtime's model types are plain final
 * data-carriers rather than an inheritance hierarchy, so the shared behaviour
 * lives here as static helpers over the annotation list and is reached through
 * one-line accessors on each node type. Either way it is <b>one</b> definition,
 * which is the point: two readers of the same annotations would be two chances
 * to disagree.
 *
 * <p>The three routing markers of {@code codespecs_mapping.md} §8.3 all ride the
 * generic annotation bag (§8.4) rather than a dedicated meta slot, so they are
 * looked up by name. Their argument names differ per annotation —
 * {@code @CodeSpecKind} lists its codes under {@code kinds},
 * {@code @FollowUpKind} under {@code processes}, {@code @NoArtifact} carries its
 * single code under {@code reason} — and all three strip the enum prefix from
 * their values.
 */
public final class SpecAnnotations {
  private SpecAnnotations() {}

  /** The annotation named {@code name}, or {@code null} when absent. */
  public static SpecAnnotation named(List<SpecAnnotation> annotations, String name) {
    for (SpecAnnotation a : annotations) {
      if (a.name.equals(name)) {
        return a;
      }
    }
    return null;
  }

  /**
   * Every annotation named {@code name}, in source order — empty when absent.
   *
   * <p>Distinct from {@link #named} because some annotations are <i>repeatable</i>:
   * {@code @Case} is applied once per discriminator value, so a single field can
   * carry several. Reading only the first would silently drop the rest.
   */
  public static List<SpecAnnotation> allNamed(List<SpecAnnotation> annotations, String name) {
    List<SpecAnnotation> out = new ArrayList<>();
    for (SpecAnnotation a : annotations) {
      if (a.name.equals(name)) {
        out.add(a);
      }
    }
    return out;
  }

  /**
   * Whether the annotation named {@code name} is present. For markers that carry
   * no arguments, presence <i>is</i> the whole statement.
   */
  public static boolean has(List<SpecAnnotation> annotations, String name) {
    return named(annotations, name) != null;
  }

  /**
   * The {@code @CodeSpecKind} link, or {@code null} when the node carries no such
   * annotation. See {@link KindLink} for why absent and empty differ.
   */
  public static KindLink codeSpecKind(List<SpecAnnotation> annotations) {
    return link(annotations, "CodeSpecKind", "kinds");
  }

  /**
   * The {@code @FollowUpKind} link, or {@code null} when the node carries no such
   * annotation — which downstream process(es) this subtree feeds instead of
   * becoming CodeSpecs code ({@code codespecs_mapping.md} §8.3).
   */
  public static KindLink followUpKind(List<SpecAnnotation> annotations) {
    return link(annotations, "FollowUpKind", "processes");
  }

  /**
   * The {@code @NoArtifact} verdict, or {@code null} when the node carries no
   * such annotation — the recorded decision that the section produces nothing
   * downstream ({@code codespecs_mapping.md} §8.3).
   */
  public static NoArtifactLink noArtifact(List<SpecAnnotation> annotations) {
    SpecAnnotation a = named(annotations, "NoArtifact");
    return a == null ? null : NoArtifactLink.fromAnnotation(a);
  }

  /**
   * {@code CodeSpecPart.validation} → {@code validation}. A name already given
   * bare is returned unchanged, so readers do not depend on how the exporter
   * chose to spell the enum constant. Splitting on the last dot rather than a
   * fixed prefix keeps this working for any code enum the model adds.
   */
  public static String stripEnumPrefix(String raw) {
    int dot = raw.lastIndexOf('.');
    return dot < 0 ? raw : raw.substring(dot + 1);
  }

  private static KindLink link(
      List<SpecAnnotation> annotations, String name, String listArgument) {
    SpecAnnotation a = named(annotations, name);
    return a == null ? null : KindLink.fromAnnotation(a, listArgument);
  }
}
