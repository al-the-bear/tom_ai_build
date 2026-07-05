"""Model-aware member ordering for YAML serialization (AA1 criterion 7) — a
faithful port of `tom_som_dart_runtime/lib/src/spec_serialization_order.dart`.

A :class:`SpecDocument` is a flat, path-keyed store; the native YAML codec
normally emits keys alphabetically for clean diffs. Criterion 7 instead requires
each class's members to be emitted in the order declared by their
``@SerializationOrder`` annotation (the SOM source declaration order).

This helper turns a path into an **ordinal tuple** — the ``@SerializationOrder``
of each field crossed on the way down (plus the numeric sequence for a list
item), mirroring the walk :meth:`SpecReflection.resolve` performs. Comparing
those tuples lexicographically reproduces a depth-first, member-order traversal:
siblings of one class sort by their declared order, and the recursion carries
that ordering down the tree. Form fields (which are sub-keys, not path segments)
are ordered by their position in the owning ``@Form``'s field list.

Unannotated members sort after annotated ones (fallback ordinal), then by
path/name, so ordering is always total and deterministic.
"""

from __future__ import annotations

from typing import Iterable, List, Optional

from .spec_model import SpecClass, SpecField, SpecFieldKind, SpecModel
from .spec_paths import spec_path_segments, split_list_item_segment
from .spec_reflection import SpecReflection

#: Ordinal used for members without a ``@SerializationOrder``, so they sort after
#: every annotated member while staying stable relative to each other.
_UNORDERED_FALLBACK = 1 << 30


class SpecSerializationOrder:
    """Computes ``@SerializationOrder``-based orderings over a
    :class:`SpecModel`."""

    def __init__(self, model: SpecModel) -> None:
        self._refl = SpecReflection(model)

    def order_key(self, path: str) -> List[int]:
        """The ordinal tuple for *path*: one entry per field crossed (its
        ``@SerializationOrder``, or :data:`_UNORDERED_FALLBACK`), with a trailing
        entry for a list item's numeric sequence. A path that does not resolve
        yields an empty tuple (it then sorts by its string form only)."""
        segs = spec_path_segments(path)
        if not segs or segs[0] == "":
            return []
        root = self._refl.root_for_segment(segs[0])
        if root is None:
            return []

        key: List[int] = []
        cur_class: Optional[SpecClass] = self._refl.class_named(root.type)
        for i in range(1, len(segs)):
            cls = cur_class
            if cls is None:
                break
            seg = segs[i]

            field = self._match_field(cls, seg)
            if field is not None:
                key.append(
                    field.serialization_order
                    if field.serialization_order is not None
                    else _UNORDERED_FALLBACK
                )
                if field.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
                    cur_class = self._refl.class_named(field.type)
                    continue
                break  # list container / leaf / form terminates the descent

            # A list item segment: `<base>-<seq>`.
            split = split_list_item_segment(seg)
            if split is None:
                break
            list_field = self._match_field(cls, split.base)
            if list_field is None or list_field.kind != SpecFieldKind.LIST:
                break
            key.append(
                list_field.serialization_order
                if list_field.serialization_order is not None
                else _UNORDERED_FALLBACK
            )
            key.append(split.seq)
            if list_field.element_is_complex:
                cur_class = self._refl.class_named(list_field.element_type)
                continue
            break  # scalar list item is a leaf
        return key

    def order_paths(self, paths: Iterable[str]) -> List[str]:
        """Orders *paths* by their :meth:`order_key` (lexicographically),
        breaking ties by the path string so the result is a total, stable
        order."""
        items = list(paths)
        keys = {p: self.order_key(p) for p in items}
        items.sort(key=lambda p: (_CompareKey(keys[p], p)))
        return items

    def order_form_fields(
        self, form_path: str, field_names: Iterable[str]
    ) -> List[str]:
        """Orders the form-field names *field_names* of the ``@Form`` at
        *form_path* by their declared position in the form's field list; names
        not found in the model sort after, alphabetically."""
        resolution = self._refl.resolve(form_path)
        field = resolution.field if resolution is not None else None
        positions: dict[str, int] = {}
        if field is not None:
            for i, ff in enumerate(field.form_fields):
                positions[ff.name] = i
        names = list(field_names)
        names.sort(
            key=lambda n: (positions.get(n, _UNORDERED_FALLBACK), n)
        )
        return names

    def _match_field(self, cls: SpecClass, segment: str) -> Optional[SpecField]:
        for f in cls.fields:
            if self._refl.field_segment(f) == segment:
                return f
        return None


class _CompareKey:
    """A sort key wrapping the (ordinal-tuple, path-string) comparison so
    :meth:`SpecSerializationOrder.order_paths` reproduces the Dart
    ``_compareKeys`` total order: shorter/equal-prefix tuples order by length,
    then ties break on the path string."""

    __slots__ = ("_key", "_path")

    def __init__(self, key: List[int], path: str) -> None:
        self._key = key
        self._path = path

    def __lt__(self, other: "_CompareKey") -> bool:
        a, b = self._key, other._key
        n = min(len(a), len(b))
        for i in range(n):
            if a[i] != b[i]:
                return a[i] < b[i]
        if len(a) != len(b):
            return len(a) < len(b)
        return self._path < other._path
