package tom_som_runtime;

/**
 * One mapping of a generation unit (SOM §11.2): the area it holds and the
 * mapper that writes that area's code for it. See {@link SpecGenerationUnits}.
 */
public final class SpecGenerationUnitMapping {
  /** The area code, {@code CE-…}, as stored (trimmed). */
  public final String area;

  /** The mapper id, e.g. {@code dart-tom}, as stored (trimmed); empty when unset. */
  public final String mapping;

  /** Creates a mapping of {@code area} by {@code mapping}. */
  public SpecGenerationUnitMapping(String area, String mapping) {
    this.area = area;
    this.mapping = mapping;
  }
}
