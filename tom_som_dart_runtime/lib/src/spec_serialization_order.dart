/// Model-aware member ordering for YAML serialization (AA1 criterion 7).
///
/// A [SpecDocument] is a flat, path-keyed store; the native YAML codec normally
/// emits keys in alphabetical order for clean diffs. Criterion 7 instead
/// requires each class's members to be emitted in the order declared by their
/// `@SerializationOrder` annotation (the SOM source declaration order).
///
/// This helper turns a path into an **ordinal tuple** — the `@SerializationOrder`
/// of each field crossed on the way down (plus the numeric sequence for a list
/// item), mirroring the walk [SpecReflection.resolve] performs. Comparing those
/// tuples lexicographically reproduces a depth-first, member-order traversal:
/// siblings of one class sort by their declared order, and the recursion carries
/// that ordering down the tree. Form fields (which are sub-keys, not path
/// segments) are ordered by their position in the owning `@Form`'s field list.
///
/// Unannotated members sort after annotated ones (fallback ordinal), then by
/// path/name, so ordering is always total and deterministic.
library;

import 'spec_model.dart';
import 'spec_paths.dart';
import 'spec_reflection.dart';

/// Ordinal used for members without a `@SerializationOrder`, so they sort after
/// every annotated member while staying stable relative to each other.
const int _unorderedFallback = 1 << 30;

/// Computes `@SerializationOrder`-based orderings over a [SpecModel].
class SpecSerializationOrder {
  final SpecReflection _refl;

  SpecSerializationOrder(SpecModel model) : _refl = SpecReflection(model);

  /// The ordinal tuple for [path]: one entry per field crossed (its
  /// `@SerializationOrder`, or [_unorderedFallback]), with a trailing entry for
  /// a list item's numeric sequence. A path that does not resolve yields an
  /// empty tuple (it then sorts by its string form only).
  List<int> orderKey(String path) {
    final segs = specPathSegments(path);
    if (segs.isEmpty || segs.first.isEmpty) return const [];
    final root = _refl.rootForSegment(segs.first);
    if (root == null) return const [];

    final key = <int>[];
    SpecClass? curClass = _refl.classNamed(root.type);
    for (var i = 1; i < segs.length; i++) {
      final cls = curClass;
      if (cls == null) break;
      final seg = segs[i];

      final field = _matchField(cls, seg);
      if (field != null) {
        key.add(field.serializationOrder ?? _unorderedFallback);
        if (field.kind == SpecFieldKind.complex ||
            field.kind == SpecFieldKind.section) {
          curClass = _refl.classNamed(field.type);
          continue;
        }
        break; // list container / leaf / form terminates the descent
      }

      // A list item segment: `<base>-<seq>`.
      final split = splitListItemSegment(seg);
      if (split == null) break;
      final listField = _matchField(cls, split.base);
      if (listField == null || listField.kind != SpecFieldKind.list) break;
      key
        ..add(listField.serializationOrder ?? _unorderedFallback)
        ..add(split.seq);
      if (listField.elementIsComplex) {
        curClass = _refl.classNamed(listField.elementType);
        continue;
      }
      break; // scalar list item is a leaf
    }
    return key;
  }

  /// Orders [paths] by their [orderKey] (lexicographically), breaking ties by
  /// the path string so the result is a total, stable order.
  List<String> orderPaths(Iterable<String> paths) {
    final list = paths.toList();
    final keys = {for (final p in list) p: orderKey(p)};
    list.sort((a, b) => _compareKeys(keys[a]!, keys[b]!, a, b));
    return list;
  }

  /// Orders the form-field names [fieldNames] of the `@Form` at [formPath] by
  /// their declared position in the form's field list; names not found in the
  /// model sort after, alphabetically.
  List<String> orderFormFields(String formPath, Iterable<String> fieldNames) {
    final field = _refl.resolve(formPath)?.field;
    final positions = <String, int>{};
    if (field != null) {
      for (var i = 0; i < field.formFields.length; i++) {
        positions[field.formFields[i].name] = i;
      }
    }
    final list = fieldNames.toList();
    list.sort((a, b) {
      final pa = positions[a] ?? _unorderedFallback;
      final pb = positions[b] ?? _unorderedFallback;
      return pa != pb ? pa.compareTo(pb) : a.compareTo(b);
    });
    return list;
  }

  static int _compareKeys(List<int> a, List<int> b, String pa, String pb) {
    final n = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      if (a[i] != b[i]) return a[i].compareTo(b[i]);
    }
    if (a.length != b.length) return a.length.compareTo(b.length);
    return pa.compareTo(pb);
  }

  SpecField? _matchField(SpecClass cls, String segment) {
    for (final f in cls.fields) {
      if (_refl.fieldSegment(f) == segment) return f;
    }
    return null;
  }
}
