package tom_som_runtime;

/**
 * One {@code @SecondLevelSectionId(documentClass, id)} entry (DR1 §3.1) — a
 * faithful port of {@code spec_meta.dart} / {@code spec_meta.ts}.
 */
public final class SomSecondLevelId {
  /** The document class the second-level id applies within. */
  public final String documentClass;

  /** The section id used in that document. */
  public final String id;

  public SomSecondLevelId(String documentClass, String id) {
    this.documentClass = documentClass;
    this.id = id;
  }
}
