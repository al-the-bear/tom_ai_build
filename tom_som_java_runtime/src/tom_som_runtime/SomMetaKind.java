package tom_som_runtime;

/**
 * The structural kind of a metadata node, mirroring DR1 §3.1
 * ({@code list | form | section | content | enum | complex | scalar}) — a
 * faithful port of {@code spec_meta.dart} / {@code spec_meta.ts}.
 *
 * <p>The values are identical to the {@link SpecFieldKind} raw strings, so the
 * bridge maps them 1:1.
 */
public final class SomMetaKind {
  private SomMetaKind() {}

  /**
   * A {@code List<T>} field; items are addressed by {@code -<seq>} path
   * suffixes and described by {@link SomMetaNode#elementNode}.
   */
  public static final String LIST = "list";

  /** A {@code @Form} content section (its fields live in {@link SomMetaNode#form}). */
  public static final String FORM = "form";

  /** A field rendered as a section of its own. */
  public static final String SECTION = "section";

  /** A free-text (markdown) content leaf. */
  public static final String CONTENT = "content";

  /** An enum-valued leaf. */
  public static final String ENUM_VALUE = "enum";

  /**
   * A field typed by another model class (collapses into that class: the
   * node's children are the target class's fields).
   */
  public static final String COMPLEX = "complex";

  /** A plain scalar leaf (String/int/double/bool). */
  public static final String SCALAR = "scalar";
}
