'use strict';

/**
 * Model-aware member ordering for YAML serialization (AA1 criterion 7) — a
 * faithful port of `tom_som_dart_runtime/lib/src/spec_serialization_order.dart`
 * (and `spec_serialization_order.py`).
 *
 * A {@link SpecDocument} is a flat, path-keyed store; the native YAML codec
 * normally emits keys alphabetically for clean diffs. Criterion 7 instead
 * requires each class's members to be emitted in the order declared by their
 * `@SerializationOrder` annotation (the SOM source declaration order).
 *
 * This helper turns a path into an **ordinal tuple** — the `@SerializationOrder`
 * of each field crossed on the way down (plus the numeric sequence for a list
 * item), mirroring the walk {@link SpecReflection#resolve} performs. Comparing
 * those tuples lexicographically reproduces a depth-first, member-order
 * traversal: siblings of one class sort by their declared order, and the
 * recursion carries that ordering down the tree. Form fields (which are
 * sub-keys, not path segments) are ordered by their position in the owning
 * `@Form`'s field list.
 *
 * Unannotated members sort after annotated ones (fallback ordinal), then by
 * path/name, so ordering is always total and deterministic.
 */

const { SpecFieldKind } = require('./spec_model');
const { specPathSegments, splitListItemSegment } = require('./spec_paths');
const { SpecReflection } = require('./spec_reflection');

/**
 * Ordinal used for members without a `@SerializationOrder`, so they sort after
 * every annotated member while staying stable relative to each other.
 */
const _UNORDERED_FALLBACK = 1 << 30;

class SpecSerializationOrder {
  /** @param {import('./spec_model').SpecModel} model */
  constructor(model) {
    this._refl = new SpecReflection(model);
  }

  /**
   * The ordinal tuple for `path`: one entry per field crossed (its
   * `@SerializationOrder`, or {@link _UNORDERED_FALLBACK}), with a trailing
   * entry for a list item's numeric sequence. A path that does not resolve
   * yields an empty tuple (it then sorts by its string form only).
   *
   * @param {string} path
   * @returns {number[]}
   */
  orderKey(path) {
    const segs = specPathSegments(path);
    if (segs.length === 0 || segs[0] === '') {
      return [];
    }
    const root = this._refl.rootForSegment(segs[0]);
    if (root === null) {
      return [];
    }

    const key = [];
    let curClass = this._refl.classNamed(root.type);
    for (let i = 1; i < segs.length; i++) {
      const cls = curClass;
      if (cls === null) {
        break;
      }
      const seg = segs[i];

      const field = this._matchField(cls, seg);
      if (field !== null) {
        key.push(field.serializationOrder !== null ? field.serializationOrder : _UNORDERED_FALLBACK);
        if (field.kind === SpecFieldKind.COMPLEX || field.kind === SpecFieldKind.SECTION) {
          curClass = this._refl.classNamed(field.type);
          continue;
        }
        break; // list container / leaf / form terminates the descent
      }

      // A list item segment: `<base>-<seq>`.
      const split = splitListItemSegment(seg);
      if (split === null) {
        break;
      }
      const listField = this._matchField(cls, split.base);
      if (listField === null || listField.kind !== SpecFieldKind.LIST) {
        break;
      }
      key.push(
        listField.serializationOrder !== null ? listField.serializationOrder : _UNORDERED_FALLBACK,
      );
      key.push(split.seq);
      if (listField.elementIsComplex) {
        curClass = this._refl.classNamed(listField.elementType);
        continue;
      }
      break; // scalar list item is a leaf
    }
    return key;
  }

  /**
   * Orders `paths` by their {@link orderKey} (lexicographically), breaking ties
   * by the path string so the result is a total, stable order.
   *
   * @param {Iterable<string>} paths
   * @returns {string[]}
   */
  orderPaths(paths) {
    const items = Array.from(paths);
    const keys = new Map();
    for (const p of items) {
      keys.set(p, this.orderKey(p));
    }
    items.sort((a, b) => _compareKeys(keys.get(a), a, keys.get(b), b));
    return items;
  }

  /**
   * Orders the form-field names `fieldNames` of the `@Form` at `formPath` by
   * their declared position in the form's field list; names not found in the
   * model sort after, alphabetically.
   *
   * @param {string} formPath
   * @param {Iterable<string>} fieldNames
   * @returns {string[]}
   */
  orderFormFields(formPath, fieldNames) {
    const resolution = this._refl.resolve(formPath);
    const field = resolution !== null ? resolution.field : null;
    const positions = new Map();
    if (field !== null) {
      field.formFields.forEach((ff, i) => {
        positions.set(ff.name, i);
      });
    }
    const names = Array.from(fieldNames);
    names.sort((a, b) => {
      const pa = positions.has(a) ? positions.get(a) : _UNORDERED_FALLBACK;
      const pb = positions.has(b) ? positions.get(b) : _UNORDERED_FALLBACK;
      if (pa !== pb) {
        return pa - pb;
      }
      return a < b ? -1 : a > b ? 1 : 0;
    });
    return names;
  }

  _matchField(cls, segment) {
    for (const f of cls.fields) {
      if (this._refl.fieldSegment(f) === segment) {
        return f;
      }
    }
    return null;
  }
}

/**
 * Reproduces the Dart `_compareKeys` / Python `_CompareKey` total order:
 * shorter/equal-prefix tuples order by length, then ties break on the path
 * string.
 *
 * @param {number[]} a
 * @param {string} aPath
 * @param {number[]} b
 * @param {string} bPath
 * @returns {number}
 */
function _compareKeys(a, aPath, b, bPath) {
  const n = Math.min(a.length, b.length);
  for (let i = 0; i < n; i++) {
    if (a[i] !== b[i]) {
      return a[i] < b[i] ? -1 : 1;
    }
  }
  if (a.length !== b.length) {
    return a.length < b.length ? -1 : 1;
  }
  return aPath < bPath ? -1 : aPath > bPath ? 1 : 0;
}

module.exports = {
  SpecSerializationOrder,
};
