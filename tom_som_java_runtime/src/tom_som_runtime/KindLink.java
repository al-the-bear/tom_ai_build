package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * A list-valued taxonomy annotation: a set of enum codes plus an optional
 * explanatory note.
 *
 * <p>The model states where a subtree is headed with two such annotations, which
 * share this shape exactly — {@code @CodeSpecKind(List<CodeSpecPart>, {note})}
 * names the CodeSpecs part(s) a section type must be realised as
 * ({@code codespecs_mapping.md} §9.1/§9.5), and
 * {@code @FollowUpKind(List<FollowUpProcess>, {note})} names the downstream
 * <i>process(es)</i> a non-code subtree feeds ({@code codespecs_mapping.md}
 * §8.3). One reader serves both; which annotation a link came from is expressed
 * by which accessor produced it.
 *
 * <p>Obtaining a link at all means the annotation is present. That matters: a
 * node with no link has not been classified yet, whereas a link with empty
 * {@link #kinds} is a recorded decision that the section belongs to no member of
 * that taxonomy. The two are different statements, so they are different values
 * rather than one nullable list.
 */
public final class KindLink {
  /**
   * The enum code names with their type prefix stripped — {@code validation},
   * not {@code CodeSpecPart.validation}; {@code doc}, not
   * {@code FollowUpProcess.doc}.
   *
   * <p>Both annotations are list-valued because one section can be realised as
   * several parts, or feed several processes; consumers must handle all of them,
   * not just the first.
   */
  public final List<String> kinds;

  /** The annotation's free-text {@code note}, explaining the classification. */
  public final String note;

  public KindLink(List<String> kinds, String note) {
    this.kinds = kinds;
    this.note = note;
  }

  /**
   * Reads a link out of {@code annotation}, taking the code list from the
   * argument named {@code listArgument} — {@code kinds} for
   * {@code @CodeSpecKind}, {@code processes} for {@code @FollowUpKind}.
   */
  @SuppressWarnings("unchecked")
  public static KindLink fromAnnotation(SpecAnnotation annotation, String listArgument) {
    Object raw = annotation.argument(listArgument);
    List<String> kinds = new ArrayList<>();
    if (raw instanceof List) {
      for (Object k : (List<Object>) raw) {
        if (k != null) {
          kinds.add(SpecAnnotations.stripEnumPrefix(k.toString()));
        }
      }
    }
    return new KindLink(
        Collections.unmodifiableList(kinds), (String) annotation.argument("note"));
  }
}
