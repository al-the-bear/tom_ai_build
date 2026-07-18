"""Structural comparison of two :class:`SomMetaNode` subtrees; a faithful
port of ``tom_som_dart_runtime/lib/src/spec_meta_diff.dart``.

:func:`som_meta_node_diff` is the agreement oracle for DR8: the generated
facades embed populated metadata trees as static code (DR1 §3.2), while
:func:`~tom_som_runtime.spec_meta_bridge.build_som_meta_tree` derives the same
tree from the exported meta-JSON at runtime — the two must be field-for-field
identical for every node. Tests compare them with this function, which returns
a human-readable description of the **first** difference found (with the
node's position), or ``None`` when the subtrees agree completely.
"""

from __future__ import annotations

from typing import Optional

from .spec_meta import (
    SomDocMeta,
    SomFormMeta,
    SomMetaExtra,
    SomMetaNode,
    SomSecondLevelId,
)


def som_meta_node_diff(
    a: SomMetaNode, b: SomMetaNode, at: str = "<root>"
) -> Optional[str]:
    """Compares the *a* and *b* subtrees field by field (annotations, names,
    kinds, form/document metadata, children and list element subtrees).

    Returns ``None`` when the subtrees are structurally identical, else a
    description of the first difference, prefixed with the position *at*
    (a ``/``-joined member-name chain, defaulting to the root marker)."""

    def diff(field: str, va: object, vb: object) -> Optional[str]:
        return None if va == vb else f"{at}: {field} differs — {va} != {vb}"

    checks = [
        lambda: diff("className", a.class_name, b.class_name),
        lambda: diff("memberName", a.member_name, b.member_name),
        lambda: diff("sectionId", a.section_id, b.section_id),
        lambda: diff(
            "sectionIdPattern", a.section_id_pattern, b.section_id_pattern
        ),
        lambda: diff("kind", a.kind, b.kind),
        lambda: diff("typeName", a.type_name, b.type_name),
        lambda: diff(
            "serializationOrder", a.serialization_order, b.serialization_order
        ),
        lambda: diff("min", a.min, b.min),
        lambda: diff("unused", a.unused, b.unused),
        lambda: diff(
            "contentType.type",
            a.content_type.type if a.content_type else None,
            b.content_type.type if b.content_type else None,
        ),
        lambda: diff(
            "contentType.description",
            a.content_type.description if a.content_type else None,
            b.content_type.description if b.content_type else None,
        ),
        lambda: diff("contentHelp", a.content_help, b.content_help),
        lambda: diff("headline", a.headline, b.headline),
        lambda: diff("comment", a.comment, b.comment),
        lambda: diff("docComment", a.doc_comment, b.doc_comment),
        lambda: diff(
            "classDocComment", a.class_doc_comment, b.class_doc_comment
        ),
        lambda: diff("mapsTo", a.maps_to, b.maps_to),
        lambda: diff("detailedIn", a.detailed_in, b.detailed_in),
        lambda: diff("recursive", a.recursive, b.recursive),
        lambda: _form_diff(at, a.form, b.form),
        lambda: _document_diff(at, a.document, b.document),
        lambda: _second_level_diff(at, a.second_level_ids, b.second_level_ids),
        lambda: _extra_diff(at, a.extra, b.extra),
    ]
    for check in checks:
        d = check()
        if d is not None:
            return d

    if len(a.children) != len(b.children):
        return (
            f"{at}: children count differs — "
            f"{len(a.children)} != {len(b.children)} "
            f"({[c.member_name for c in a.children]} vs "
            f"{[c.member_name for c in b.children]})"
        )
    for ca, cb in zip(a.children, b.children):
        d = som_meta_node_diff(
            ca, cb, at=f"{at}/{ca.member_name or ca.class_name}"
        )
        if d is not None:
            return d

    if (a.element_node is None) != (b.element_node is None):
        return (
            f"{at}: elementNode presence differs — "
            f"{a.element_node is not None} != {b.element_node is not None}"
        )
    if a.element_node is not None:
        return som_meta_node_diff(
            a.element_node, b.element_node, at=f"{at}/§element"
        )
    return None


def _form_diff(
    at: str, a: Optional[SomFormMeta], b: Optional[SomFormMeta]
) -> Optional[str]:
    if (a is None) != (b is None):
        return (
            f"{at}: form presence differs — {a is not None} != {b is not None}"
        )
    if a is None or b is None:
        return None
    if len(a.fields) != len(b.fields):
        return (
            f"{at}: form field count differs — "
            f"{len(a.fields)} != {len(b.fields)}"
        )
    for fa, fb in zip(a.fields, b.fields):
        if (
            fa.name != fb.name
            or fa.type_name != fb.type_name
            or fa.description != fb.description
            or fa.required != fb.required
            or fa.hint != fb.hint
            or fa.order != fb.order
        ):
            return f"{at}: form field {fa.name} differs"
    return None


def _document_diff(
    at: str, a: Optional[SomDocMeta], b: Optional[SomDocMeta]
) -> Optional[str]:
    if (a is None) != (b is None):
        return (
            f"{at}: document presence differs — "
            f"{a is not None} != {b is not None}"
        )
    if a is None or b is None:
        return None
    if a.name != b.name:
        return f"{at}: document.name differs — {a.name} != {b.name}"
    if a.description != b.description:
        return f"{at}: document.description differs"
    if a.based_on != b.based_on:
        return (
            f"{at}: document.basedOn differs — {a.based_on} != {b.based_on}"
        )
    return None


def _second_level_diff(
    at: str, a: list[SomSecondLevelId], b: list[SomSecondLevelId]
) -> Optional[str]:
    if len(a) != len(b):
        return (
            f"{at}: secondLevelIds count differs — {len(a)} != {len(b)}"
        )
    for i, (ea, eb) in enumerate(zip(a, b)):
        if ea.document_class != eb.document_class or ea.id != eb.id:
            return f"{at}: secondLevelIds[{i}] differs"
    return None


def _extra_diff(
    at: str, a: list[SomMetaExtra], b: list[SomMetaExtra]
) -> Optional[str]:
    if len(a) != len(b):
        return (
            f"{at}: extra annotation count differs — {len(a)} != {len(b)} "
            f"({[e.annotation for e in a]} vs {[e.annotation for e in b]})"
        )
    for ea, eb in zip(a, b):
        if ea.annotation != eb.annotation or ea.args != eb.args:
            return (
                f"{at}: extra annotation {ea.annotation} differs — "
                f"{ea.args} != {eb.args}"
            )
    return None
