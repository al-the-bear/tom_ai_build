package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * One {@code section-types} entry of a DocSpecs schema — a faithful port of
 * the Go {@code DocSpecsSectionType}. {@code null} stands in for Go's
 * {@code ""} on the optional string members; optional ints are
 * {@link Integer}. {@link #subsectionTypes} is a {@link LinkedHashMap}, so it
 * keeps the schema file order the other ports iterate.
 */
public final class DocSpecsSectionType {
  public final String name;
  public final String prefix;
  /** The section-id pattern check, {@code null} when none. */
  public final DocSpecsPatternCheck patternCheck;

  /** Subsection rules in schema file order. */
  public final Map<String, DocSpecsSubsectionRule> subsectionTypes;

  /** The body format, {@code null} when absent. */
  public final String format;

  public final boolean textRequired;
  public final Integer minTextLength;
  public final Integer maxTextLength;
  public final String description;
  public final String validationPrompt;

  public DocSpecsSectionType(
      String name,
      String prefix,
      DocSpecsPatternCheck patternCheck,
      Map<String, DocSpecsSubsectionRule> subsectionTypes,
      String format,
      boolean textRequired,
      Integer minTextLength,
      Integer maxTextLength,
      String description,
      String validationPrompt) {
    this.name = name;
    this.prefix = prefix;
    this.patternCheck = patternCheck;
    this.subsectionTypes = subsectionTypes;
    this.format = format;
    this.textRequired = textRequired;
    this.minTextLength = minTextLength;
    this.maxTextLength = maxTextLength;
    this.description = description;
    this.validationPrompt = validationPrompt;
  }
}
