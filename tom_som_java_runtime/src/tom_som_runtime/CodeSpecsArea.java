package tom_som_runtime;

import java.util.List;
import java.util.Map;

/**
 * One row of the {@code codespecs_mapping.md} §4.1 parts catalogue, plus the
 * §4.4.3 slice and §4.4.6 authoring steps that place it. This is the <b>per-area
 * context</b> an extract carries beside its content.
 */
public final class CodeSpecsArea {
  /**
   * The permanent registry key — {@code CE-FM}, {@code CE-API}. Never reused,
   * never renamed, and the extract file's name.
   */
  public final String code;

  /** The §4.1 canonical id — the PascalCase noun ({@code Form}, {@code ServerApi}). */
  public final String canonicalId;

  /**
   * The {@code CodeSpecPart} value, camelCase and <b>without</b> the enum prefix
   * ({@code form}, {@code serverApi}).
   */
  public final String part;

  /** The {@code Cs*} annotation names of the §4.1 row. */
  public final List<String> annotations;

  /** The §4.1 "Built on" cell, verbatim. */
  public final String builtOn;

  /**
   * Where the area's spec-authorable attribute surface is stated — a §5.x
   * citation.
   */
  public final String attributeSurface;

  /**
   * The §4.4.3 slice(s) the area's emission units sit in. More than one when the
   * area is split by locus.
   */
  public final List<Integer> slices;

  /** The §4.4.6 authoring step(s) that write the area. */
  public final List<Integer> authoringSteps;

  /**
   * Whether the part is active. A deferred part (§4.3) holds a reserved
   * {@code CodeSpecPart} value but has no generated surface, so it gets no
   * extract.
   */
  public final boolean active;

  public CodeSpecsArea(
      String code,
      String canonicalId,
      String part,
      List<String> annotations,
      String builtOn,
      String attributeSurface,
      List<Integer> slices,
      List<Integer> authoringSteps,
      boolean active) {
    this.code = code;
    this.canonicalId = canonicalId;
    this.part = part;
    this.annotations = annotations;
    this.builtOn = builtOn;
    this.attributeSurface = attributeSurface;
    this.slices = slices;
    this.authoringSteps = authoringSteps;
    this.active = active;
  }

  public static CodeSpecsArea fromJson(Map<String, Object> j) {
    Object active = j.get("active");
    return new CodeSpecsArea(
        (String) j.get("code"),
        CodeSpecsAreaCatalog.stringOr(j.get("canonicalId")),
        (String) j.get("part"),
        CodeSpecsAreaCatalog.stringList(j.get("annotations")),
        CodeSpecsAreaCatalog.stringOr(j.get("builtOn")),
        CodeSpecsAreaCatalog.stringOr(j.get("attributeSurface")),
        CodeSpecsAreaCatalog.intList(j.get("slices")),
        CodeSpecsAreaCatalog.intList(j.get("authoringSteps")),
        active == null || Boolean.TRUE.equals(active));
  }

  /** The fully-qualified {@code @CodeSpecKind} value — {@code CodeSpecPart.form}. */
  public String kindValue() {
    return "CodeSpecPart." + part;
  }

  @Override
  public String toString() {
    return "CodeSpecsArea(" + code + ")";
  }
}
