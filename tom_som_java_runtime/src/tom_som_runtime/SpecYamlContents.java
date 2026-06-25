package tom_som_runtime;

import java.util.Map;

/**
 * The decoded passes of a {@code *.docspecs.yaml} file: the {@code document:}
 * pass as a {@link SpecDocument#loadJson}-shaped map, the {@code review:} pass as
 * a raw map (the runtime is review-agnostic), and the optional authoring
 * model-version stamp.
 */
public final class SpecYamlContents {
  public final Map<String, Object> document;
  public final Map<String, Object> review;
  public final String modelVersion;

  public SpecYamlContents(
      Map<String, Object> document, Map<String, Object> review, String modelVersion) {
    this.document = document;
    this.review = review;
    this.modelVersion = modelVersion;
  }
}
