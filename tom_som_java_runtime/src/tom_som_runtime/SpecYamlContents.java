package tom_som_runtime;

import java.util.Map;

/**
 * The decoded passes of a {@code *.docspecs.yaml} file: the {@code document:}
 * pass as a populated {@link SpecDocument}, the {@code review:} pass as a raw
 * mapping (the runtime is review-agnostic), and the optional authoring
 * model-version stamp — a faithful port of {@code spec_document_yaml.dart} /
 * {@code spec_document_yaml.ts}.
 */
public final class SpecYamlContents {
  /**
   * The {@code document:} pass, loaded into a live document (its
   * {@link SpecDocument#modelVersion} is already set from the file stamp).
   */
  public final SpecDocument document;

  /**
   * The {@code review:} pass exactly as parsed (empty when absent). The
   * runtime does not interpret it; the editor maps it onto its own review
   * entries.
   */
  public final Map<String, Object> review;

  /**
   * The authoring object-model version ({@code major.minor}) this document was
   * last written against, or {@code null} for an unstamped/hand-written file.
   * Distinct from {@link SpecDocumentYaml#FORMAT_VERSION} (the on-disk format
   * version).
   */
  public final String modelVersion;

  public SpecYamlContents(
      SpecDocument document, Map<String, Object> review, String modelVersion) {
    this.document = document;
    this.review = review;
    this.modelVersion = modelVersion;
  }
}
