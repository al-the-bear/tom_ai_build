package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * One generation unit the document declares (SOM §11.2), read by
 * {@link SpecGenerationUnits#specGenerationUnits}.
 */
public final class SpecGenerationUnit {
  /** The unit's id — what a section's {@code units} names, usually the package name. */
  public final String unitId;

  /**
   * {@code client}, {@code server}, {@code shared} or {@code other}, as stored;
   * empty when unset.
   */
  public final String kind;

  /** The unit's list-item path in the document. */
  public final String path;

  /** The unit's mappings, in stored order. */
  public final List<SpecGenerationUnitMapping> mappings;

  /** Creates a unit. */
  public SpecGenerationUnit(
      String unitId, String kind, String path, List<SpecGenerationUnitMapping> mappings) {
    this.unitId = unitId;
    this.kind = kind;
    this.path = path;
    this.mappings = mappings == null
        ? Collections.emptyList()
        : Collections.unmodifiableList(new ArrayList<>(mappings));
  }

  /** Whether one of the unit's mappings holds {@code areaCode}. */
  public boolean maps(String areaCode) {
    for (SpecGenerationUnitMapping m : mappings) {
      if (m.area.equals(areaCode)) {
        return true;
      }
    }
    return false;
  }

  /** The mapper of {@code areaCode} — the first mapping that holds it — or {@code null}. */
  public String mappingFor(String areaCode) {
    for (SpecGenerationUnitMapping m : mappings) {
      if (m.area.equals(areaCode)) {
        return m.mapping;
      }
    }
    return null;
  }
}
