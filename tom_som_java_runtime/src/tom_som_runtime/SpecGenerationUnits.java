package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * The generation-unit register of a document (SOM §11.2): the units Phase 4
 * writes code into, each with the mapper of every area it holds — a port of
 * {@code spec_generation_units.dart}.
 *
 * <p>The register is recognised by its annotations, never by class name,
 * exactly as validation phase 8 recognises it: a <b>unit</b> is a list item
 * whose class carries {@code @NoArtifact(generation)} and declares the form
 * field {@code unitId}; a <b>mapping</b> is such a list item declaring the form
 * field {@code area}, and belongs to the nearest unit whose path is a prefix of
 * its own.
 */
public final class SpecGenerationUnits {
  private SpecGenerationUnits() {}

  private record UnitDecl(String id, String kind, String path) {}

  private record MappingDecl(String path, String area, String mapping) {}

  /**
   * The generation units {@code doc} declares, in register order: sorted
   * list-path order, each list's items in their stored order — the order
   * validation phase 8 visits them in. A unit without a {@code unitId} is left
   * out; a second unit with an id already seen is left out too (phase 8 reports
   * it as {@code duplicateUnitId}). A document without a register declares none.
   */
  public static List<SpecGenerationUnit> specGenerationUnits(SpecModel model, SpecDocument doc) {
    SpecReflection refl = new SpecReflection(model);
    List<UnitDecl> units = new ArrayList<>();
    List<MappingDecl> mappings = new ArrayList<>();
    List<String> listPaths = new ArrayList<>(doc.listPaths());
    Collections.sort(listPaths);
    for (String listPath : listPaths) {
      for (String item : doc.listItems(listPath)) {
        SpecResolution res = refl.resolve(item);
        SpecClass cls = res == null ? null : res.targetClass;
        if (cls == null) {
          continue;
        }
        NoArtifactLink noArtifact = cls.noArtifact();
        if (noArtifact == null || !"generation".equals(noArtifact.reason)) {
          continue;
        }
        SpecField unitForm = SpecValidator.formDeclaring(cls, "unitId");
        if (unitForm != null) {
          String formPath = SpecPaths.join(item, refl.fieldSegment(unitForm));
          String id = SpecValidator.trimmedFormValue(doc, formPath, "unitId");
          if (!id.isEmpty()) {
            units.add(new UnitDecl(
                id, SpecValidator.trimmedFormValue(doc, formPath, "kind"), item));
          }
        }
        SpecField areaForm = SpecValidator.formDeclaring(cls, "area");
        if (areaForm != null) {
          String formPath = SpecPaths.join(item, refl.fieldSegment(areaForm));
          String area = SpecValidator.trimmedFormValue(doc, formPath, "area");
          if (!area.isEmpty()) {
            mappings.add(new MappingDecl(
                item, area, SpecValidator.trimmedFormValue(doc, formPath, "mapping")));
          }
        }
      }
    }

    Set<String> seen = new HashSet<>();
    List<SpecGenerationUnit> out = new ArrayList<>();
    for (UnitDecl u : units) {
      if (!seen.add(u.id())) {
        continue;
      }
      List<SpecGenerationUnitMapping> own = new ArrayList<>();
      for (MappingDecl m : mappings) {
        if (u.path().equals(owner(m.path(), units))) {
          own.add(new SpecGenerationUnitMapping(m.area(), m.mapping()));
        }
      }
      out.add(new SpecGenerationUnit(u.id(), u.kind(), u.path(), own));
    }
    return out;
  }

  /**
   * The units of {@code units} whose mappings hold {@code areaCode}, in
   * register order — the default destination of a section routed to that area
   * (SOM §11.2).
   */
  public static List<String> specDefaultUnits(List<SpecGenerationUnit> units, String areaCode) {
    List<String> out = new ArrayList<>();
    for (SpecGenerationUnit u : units) {
      if (u.maps(areaCode)) {
        out.add(u.unitId);
      }
    }
    return out;
  }

  /**
   * The path of the unit a mapping at {@code mappingPath} belongs to: the
   * longest unit path that is a proper prefix of it, or {@code null}.
   */
  private static String owner(String mappingPath, List<UnitDecl> units) {
    String best = null;
    for (UnitDecl u : units) {
      if (mappingPath.startsWith(u.path() + "/")
          && (best == null || u.path().length() > best.length())) {
        best = u.path();
      }
    }
    return best;
  }
}
