package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** One row of the impact walk ({@link SpecImpactWalk#specImpactWalk}). */
public final class SpecImpactRow {
  /** The document path; a template's subtree has {@code *} for the item segment. */
  public final String path;

  /** The section-id chain, outer first, joined by {@code " > "} (a list item by its stored id). */
  public final String chain;

  public final SpecImpactRowKind kind;

  /** The model class; for a list, its element class ({@code ""} for a list of scalars). */
  public final String className;

  /** Nesting below the root (the root is 0). */
  public final int depth;

  /** Whether the document holds anything at or below the path ({@code hasValuesUnder}). */
  public final boolean filled;

  /** Stored values at or below the path: content leaves plus form-field values. */
  public final int values;

  /** A list's item count; {@code null} for every other row. */
  public final Integer items;

  /**
   * The CodeSpecs routing verdict ({@link CodeSpecsRoutingVerdict#value}): of the
   * class (a class row), of the element class (a list of classes), or of the
   * field, else its enclosing class (a list of scalars). Below a
   * {@code feedsProcess} section, that section's routing.
   */
  public final String routing;

  /** The routing's values verbatim ({@code CodeSpecPart} / {@code FollowUpProcess} / {@code NoArtifactReason} names). */
  public final List<String> routingValues;

  /** Where the routing marker is declared ({@code Class} or {@code Class.field}); {@code ""} when none. */
  public final String routingDeclaredAt;

  public SpecImpactRow(
      String path,
      String chain,
      SpecImpactRowKind kind,
      String className,
      int depth,
      boolean filled,
      int values,
      Integer items,
      CodeSpecsRouting routing) {
    this.path = path;
    this.chain = chain;
    this.kind = kind;
    this.className = className;
    this.depth = depth;
    this.filled = filled;
    this.values = values;
    this.items = items;
    this.routing = routing.verdict.value;
    this.routingValues = routing.values;
    this.routingDeclaredAt = routing.declaredAt;
  }

  /** The row as JSON, keys as in every runtime. */
  public Map<String, Object> toJson() {
    Map<String, Object> o = new LinkedHashMap<>();
    o.put("path", path);
    o.put("chain", chain);
    o.put("kind", kind.value);
    o.put("className", className);
    o.put("depth", Integer.valueOf(depth));
    o.put("filled", Boolean.valueOf(filled));
    o.put("values", Integer.valueOf(values));
    o.put("items", items);
    o.put("routing", routing);
    o.put("routingValues", new ArrayList<Object>(routingValues));
    o.put("routingDeclaredAt", routingDeclaredAt);
    return o;
  }
}
