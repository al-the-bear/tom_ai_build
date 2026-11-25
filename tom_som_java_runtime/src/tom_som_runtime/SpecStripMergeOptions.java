package tom_som_runtime;

import java.util.Map;
import java.util.function.Function;

/**
 * The options of {@link SpecStripMerge#merge} (SOM §11.10). Only the model is
 * required; every other option is {@code null} until set, and each setter
 * returns the options for chaining.
 */
public final class SpecStripMergeOptions {
  public final SpecModel model;
  /** The DocSpecs schema: adds the schema tier to the checks. */
  public DocSpecsSchema schema;
  /** The root to export, else the single populated one. */
  public String rootType;
  /** Switches given beside the readable header; they must agree with it. */
  public SpecStripOptions options;
  /** The revision of the original now; one differing from the header's makes it stale. */
  public String currentRevision;
  /** The original as it was at the export, given by hand. */
  public SpecDocument base;
  /** The base of a stale original from the header's source (its commit); may answer {@code null}. */
  public Function<SpecReadableSource, SpecDocument> loadBase;
  /** The files references to other roots link to. */
  public String fileStem;

  public Map<String, String> documentFiles;

  public SpecStripMergeOptions(SpecModel model) {
    this.model = model;
  }

  public SpecStripMergeOptions schema(DocSpecsSchema value) {
    this.schema = value;
    return this;
  }

  public SpecStripMergeOptions rootType(String value) {
    this.rootType = value;
    return this;
  }

  public SpecStripMergeOptions options(SpecStripOptions value) {
    this.options = value;
    return this;
  }

  public SpecStripMergeOptions currentRevision(String value) {
    this.currentRevision = value;
    return this;
  }

  public SpecStripMergeOptions base(SpecDocument value) {
    this.base = value;
    return this;
  }

  public SpecStripMergeOptions loadBase(Function<SpecReadableSource, SpecDocument> value) {
    this.loadBase = value;
    return this;
  }

  public SpecStripMergeOptions fileStem(String value) {
    this.fileStem = value;
    return this;
  }

  public SpecStripMergeOptions documentFiles(Map<String, String> value) {
    this.documentFiles = value;
    return this;
  }
}
