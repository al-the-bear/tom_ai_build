package tom_som_runtime;

import java.util.Map;

/**
 * The decoded passes of a {@code *.docspecs.yaml} file: the {@code document:}
 * pass as a populated {@link SpecDocument}, the {@code review:} pass as a raw
 * mapping (the runtime carries it uninterpreted and writes it back), and the optional authoring
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
   * The {@code review:} pass exactly as parsed: {@code null} when the file has
   * no {@code review:} key, an empty map for an explicit {@code review: {}} or
   * a bare {@code review:}, so passing it straight back to
   * {@link SpecDocumentYaml#encode} reproduces the file either way (SOM §12.1).
   * The runtime does not interpret it; the editor maps it onto its own review
   * entries. Its plain scalars are typed by the YAML 1.2 core schema
   * (SOM §12.5): null, {@link Boolean}, {@link Integer} or {@link Long} for an
   * int, {@link Double} for a float, else {@link String}.
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
