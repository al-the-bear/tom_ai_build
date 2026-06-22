"""Generic, value-free traversal of a :class:`SpecModel` class graph (the
"reflection" surface) — a faithful port of
`tom_som_dart_runtime/lib/src/spec_reflection.dart`.

It answers two kinds of question about a model: **enumeration** (what roots,
classes, fields and annotations exist) and **resolution** (which model node a
concrete document *path* addresses). It holds no document values.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Iterable, Optional

from .spec_model import (
    SpecAnnotation,
    SpecClass,
    SpecField,
    SpecFieldKind,
    SpecModel,
    SpecRoot,
)
from .spec_paths import spec_path_segments, split_list_item_segment


class SpecNodeKind(Enum):
    """What a resolved path lands on in the model."""

    ROOT = "root"
    COMPLEX = "complex"
    SECTION = "section"
    LIST = "list"
    LIST_ITEM_COMPLEX = "listItemComplex"
    LIST_ITEM_SCALAR = "listItemScalar"
    FORM = "form"
    CONTENT = "content"
    ENUM_VALUE = "enumValue"
    SCALAR = "scalar"


@dataclass(frozen=True)
class SpecResolution:
    """The outcome of resolving a document path against a :class:`SpecModel`."""

    path: str
    kind: SpecNodeKind
    root: SpecRoot
    field: Optional[SpecField] = None
    target_class: Optional[SpecClass] = None

    @property
    def is_value_leaf(self) -> bool:
        """Whether a single string value is stored directly at this path (a
        content, enum, scalar leaf, or a scalar list item)."""
        return self.kind in (
            SpecNodeKind.CONTENT,
            SpecNodeKind.ENUM_VALUE,
            SpecNodeKind.SCALAR,
            SpecNodeKind.LIST_ITEM_SCALAR,
        )


_LEAF_KINDS = {
    SpecFieldKind.FORM: SpecNodeKind.FORM,
    SpecFieldKind.CONTENT: SpecNodeKind.CONTENT,
    SpecFieldKind.ENUM: SpecNodeKind.ENUM_VALUE,
    SpecFieldKind.SCALAR: SpecNodeKind.SCALAR,
}


class SpecReflection:
    """Read-only queries over a :class:`SpecModel`."""

    def __init__(self, model: SpecModel) -> None:
        self.model = model

    # --- enumeration --------------------------------------------------------

    @property
    def roots(self) -> Iterable[SpecRoot]:
        return self.model.roots

    @property
    def classes(self) -> Iterable[SpecClass]:
        return self.model.classes.values()

    def class_named(self, name: Optional[str]) -> Optional[SpecClass]:
        return self.model.class_named(name)

    def fields_of(self, class_name: str) -> list[SpecField]:
        cls = self.class_named(class_name)
        return cls.fields if cls else []

    def annotations_of(self, class_name: str) -> list[SpecAnnotation]:
        cls = self.class_named(class_name)
        return cls.annotations if cls else []

    def field_annotations(self, class_name: str, field_name: str) -> list[SpecAnnotation]:
        cls = self.class_named(class_name)
        if cls is None:
            return []
        f = cls.field_named(field_name)
        return f.annotations if f else []

    # --- resolution ---------------------------------------------------------

    def root_segment(self, root: SpecRoot) -> str:
        return root.section_id or root.type

    def field_segment(self, field: SpecField) -> str:
        return field.section_id or field.name

    def root_for_segment(self, segment: str) -> Optional[SpecRoot]:
        for r in self.model.roots:
            if self.root_segment(r) == segment:
                return r
        return None

    def _match_field(self, cls: SpecClass, segment: str) -> Optional[SpecField]:
        for f in cls.fields:
            if self.field_segment(f) == segment:
                return f
        return None

    def resolve(self, path: str) -> Optional[SpecResolution]:
        """Resolves a document *path* to the model node it addresses, or
        ``None`` when the path does not describe a reachable node."""
        segs = spec_path_segments(path)
        if not segs or segs[0] == "":
            return None

        root = self.root_for_segment(segs[0])
        if root is None:
            return None

        cur_class = self.class_named(root.type)
        if len(segs) == 1:
            return SpecResolution(
                path=path,
                kind=SpecNodeKind.ROOT,
                root=root,
                target_class=cur_class,
            )

        for i in range(1, len(segs)):
            cls = cur_class
            if cls is None:
                return None  # cannot descend into a non-class
            seg = segs[i]
            last = i == len(segs) - 1

            # Prefer an exact field-segment match; only then try a list-item
            # suffix, so a hyphenated @SectionId is never mis-read as an item.
            field = self._match_field(cls, seg)
            if field is not None:
                if field.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
                    cur_class = self.class_named(field.type)
                    if last:
                        return SpecResolution(
                            path=path,
                            kind=(
                                SpecNodeKind.COMPLEX
                                if field.kind == SpecFieldKind.COMPLEX
                                else SpecNodeKind.SECTION
                            ),
                            root=root,
                            field=field,
                            target_class=cur_class,
                        )
                    continue  # descend into the collapsed class
                if field.kind == SpecFieldKind.LIST:
                    return (
                        SpecResolution(
                            path=path,
                            kind=SpecNodeKind.LIST,
                            root=root,
                            field=field,
                        )
                        if last
                        else None  # a list path needs a -<seq> item suffix
                    )
                # form / content / enum / scalar leaves
                return (
                    SpecResolution(
                        path=path,
                        kind=_LEAF_KINDS[field.kind],
                        root=root,
                        field=field,
                    )
                    if last
                    else None  # a leaf cannot have further segments
                )

            split = split_list_item_segment(seg)
            if split is None:
                return None
            list_field = self._match_field(cls, split.base)
            if list_field is None or list_field.kind != SpecFieldKind.LIST:
                return None
            if list_field.element_is_complex:
                cur_class = self.class_named(list_field.element_type)
                if last:
                    return SpecResolution(
                        path=path,
                        kind=SpecNodeKind.LIST_ITEM_COMPLEX,
                        root=root,
                        field=list_field,
                        target_class=cur_class,
                    )
                continue
            # Scalar list item: a value leaf, so it must be the final segment.
            if last:
                return SpecResolution(
                    path=path,
                    kind=SpecNodeKind.LIST_ITEM_SCALAR,
                    root=root,
                    field=list_field,
                )
            return None
        return None
