package tom_som_runtime;

/**
 * The {@code @ContentType(type, description)} annotation captured on a node
 * (SOM §7.1) — a faithful port of {@code spec_meta.dart} / {@code spec_meta.ts}.
 */
public final class SomContentTypeMeta {
  /** The declared content type (e.g. {@code "code"}, {@code "diagram"}). */
  public final String type;

  /** The human/AI-facing description of the expected content, {@code ""} when none. */
  public final String description;

  public SomContentTypeMeta(String type, String description) {
    this.type = type;
    this.description = description;
  }
}
