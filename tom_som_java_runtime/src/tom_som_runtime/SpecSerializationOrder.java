package tom_som_runtime;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Model-aware member ordering for YAML serialization (AA1 criterion 7) — a
 * faithful port of {@code spec_serialization_order.dart} /
 * {@code spec_serialization_order.py}.
 *
 * <p>A {@link SpecDocument} is a flat, path-keyed store; the native YAML codec
 * normally emits keys alphabetically for clean diffs. Criterion 7 instead
 * requires each class's members to be emitted in the order declared by their
 * {@code @SerializationOrder} annotation (the SOM source declaration order).
 *
 * <p>This helper turns a path into an <b>ordinal tuple</b> — the
 * {@code @SerializationOrder} of each field crossed on the way down (plus the
 * numeric sequence for a list item), mirroring the walk
 * {@link SpecReflection#resolve} performs. Comparing those tuples
 * lexicographically reproduces a depth-first, member-order traversal. Form fields
 * (which are sub-keys, not path segments) are ordered by their position in the
 * owning {@code @Form}'s field list.
 *
 * <p>Unannotated members sort after annotated ones (fallback ordinal), then by
 * path/name, so ordering is always total and deterministic.
 */
public final class SpecSerializationOrder {
  /**
   * Ordinal used for members without a {@code @SerializationOrder}, so they sort
   * after every annotated member while staying stable relative to each other.
   */
  private static final int UNORDERED_FALLBACK = 1 << 30;

  private final SpecReflection refl;

  public SpecSerializationOrder(SpecModel model) {
    this.refl = new SpecReflection(model);
  }

  /**
   * The ordinal tuple for {@code path}: one entry per field crossed (its
   * {@code @SerializationOrder}, or {@link #UNORDERED_FALLBACK}), with a trailing
   * entry for a list item's numeric sequence. A path that does not resolve yields
   * an empty tuple (it then sorts by its string form only).
   */
  public List<Integer> orderKey(String path) {
    List<Integer> key = new ArrayList<>();
    String[] segs = SpecPaths.segments(path);
    if (segs.length == 0 || segs[0].isEmpty()) {
      return key;
    }
    SpecRoot root = refl.rootForSegment(segs[0]);
    if (root == null) {
      return key;
    }
    SpecClass curClass = refl.classNamed(root.type);
    for (int i = 1; i < segs.length; i++) {
      SpecClass cls = curClass;
      if (cls == null) {
        break;
      }
      String seg = segs[i];

      SpecField field = matchField(cls, seg);
      if (field != null) {
        key.add(field.serializationOrder != null ? field.serializationOrder : UNORDERED_FALLBACK);
        if (field.kind == SpecFieldKind.COMPLEX || field.kind == SpecFieldKind.SECTION) {
          curClass = refl.classNamed(field.type);
          continue;
        }
        break; // list container / leaf / form terminates the descent
      }

      // A list item segment: `<base>-<seq>`.
      SpecPaths.ListItemSegment split = SpecPaths.splitListItemSegment(seg);
      if (split == null) {
        break;
      }
      SpecField listField = matchField(cls, split.base);
      if (listField == null || listField.kind != SpecFieldKind.LIST) {
        break;
      }
      key.add(
          listField.serializationOrder != null
              ? listField.serializationOrder
              : UNORDERED_FALLBACK);
      key.add(split.seq);
      if (listField.elementIsComplex) {
        curClass = refl.classNamed(listField.elementType);
        continue;
      }
      break; // scalar list item is a leaf
    }
    return key;
  }

  /**
   * Orders {@code paths} by their {@link #orderKey} (lexicographically), breaking
   * ties by the path string so the result is a total, stable order.
   */
  public List<String> orderPaths(Iterable<String> paths) {
    List<String> items = new ArrayList<>();
    Map<String, List<Integer>> keys = new HashMap<>();
    for (String p : paths) {
      items.add(p);
      keys.put(p, orderKey(p));
    }
    items.sort((a, b) -> compareKeys(keys.get(a), a, keys.get(b), b));
    return items;
  }

  /**
   * Orders the form-field names {@code fieldNames} of the {@code @Form} at
   * {@code formPath} by their declared position in the form's field list; names
   * not found in the model sort after, alphabetically.
   */
  public List<String> orderFormFields(String formPath, Iterable<String> fieldNames) {
    SpecResolution resolution = refl.resolve(formPath);
    SpecField field = resolution != null ? resolution.field : null;
    Map<String, Integer> positions = new HashMap<>();
    if (field != null) {
      for (int i = 0; i < field.formFields.size(); i++) {
        positions.put(field.formFields.get(i).name, i);
      }
    }
    List<String> names = new ArrayList<>();
    for (String n : fieldNames) {
      names.add(n);
    }
    names.sort(
        (a, b) -> {
          int pa = positions.getOrDefault(a, UNORDERED_FALLBACK);
          int pb = positions.getOrDefault(b, UNORDERED_FALLBACK);
          if (pa != pb) {
            return Integer.compare(pa, pb);
          }
          return a.compareTo(b);
        });
    return names;
  }

  private SpecField matchField(SpecClass cls, String segment) {
    for (SpecField f : cls.fields) {
      if (refl.fieldSegment(f).equals(segment)) {
        return f;
      }
    }
    return null;
  }

  /**
   * The total order over (ordinal-tuple, path-string) pairs: shorter/equal-prefix
   * tuples order by length, then ties break on the path string (mirrors the Dart
   * / Python {@code _compareKeys}).
   */
  private static int compareKeys(List<Integer> a, String pathA, List<Integer> b, String pathB) {
    int n = Math.min(a.size(), b.size());
    for (int i = 0; i < n; i++) {
      if (!a.get(i).equals(b.get(i))) {
        return Integer.compare(a.get(i), b.get(i));
      }
    }
    if (a.size() != b.size()) {
      return Integer.compare(a.size(), b.size());
    }
    return pathA.compareTo(pathB);
  }
}
