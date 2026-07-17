"""Bridge from the meta-JSON class graph (:class:`SpecModel`) to the canonical
metadata tree (:class:`SomMetaTree`, DR1 §3.1) — a faithful port of
`tom_som_dart_runtime/lib/src/spec_meta_bridge.dart`.

The generated facades (DR8) emit populated :class:`SomMetaTree` s directly;
every consumer that only has the exported spec-model meta-data (the
conformance harness, tooling) builds its tree here. The expansion follows the
same walk :meth:`SpecReflection.resolve` performs — crucially, a node's
:attr:`SomMetaNode.section_id` is the **field-level** id exactly as exported
(``field.section_id``), so the tree's path grammar stays byte-compatible with
the paths a :class:`SpecDocument` is keyed by. (DR1 §2.2's "field id, else
target-class id" resolution is applied at *export* time by the model exporter
/ DR8 generator, not re-derived here.)

Recursive class references become terminal re-entry nodes
(:attr:`SomMetaNode.recursive`), mirroring how the generated chains terminate.
"""

from __future__ import annotations

from typing import Optional

from .spec_meta import (
    SomContentTypeMeta,
    SomDocMeta,
    SomFormFieldMeta,
    SomFormMeta,
    SomMetaExtra,
    SomMetaKind,
    SomMetaNode,
    SomMetaTree,
    SomSecondLevelId,
)
from .spec_model import (
    SpecAnnotation,
    SpecClass,
    SpecField,
    SpecFieldKind,
    SpecModel,
)

#: Annotation names that have a dedicated :class:`SomMetaNode` slot; everything
#: else is captured losslessly into :attr:`SomMetaNode.extra`.
_SLOTTED_ANNOTATIONS = {
    "SectionId",
    "SectionIdPattern",
    "SerializationOrder",
    "Min",
    "Unused",
    "ContentType",
    "ContentHelp",
    "Headline",
    "Comment",
    "Form",
    "Document",
    "MapsTo",
    "DetailedIn",
    "SecondLevelSectionId",
}


def build_som_meta_tree(
    model: SpecModel, root_type: Optional[str] = None
) -> SomMetaTree:
    """Builds the wired :class:`SomMetaTree` for one document root of *model*.

    When *root_type* is omitted the model's first root is used; otherwise the
    root is looked up via :meth:`SpecModel.root_by_type` (raising
    :class:`ValueError` for an unknown type). Children are ordered by
    ``@SerializationOrder`` (annotated members first, then declaration order),
    which is the sibling emission order of the hierarchical YAML format (DR1
    §2.3)."""
    if root_type is None and model.roots:
        root = model.roots[0]
    else:
        root = model.root_by_type(root_type or "")
    cls = model.class_named(root.type)
    root_node = SomMetaNode(
        class_name=root.type,
        section_id=root.section_id or (cls.section_id if cls else None),
        class_section_id=cls.section_id if cls else None,
        kind=SomMetaKind.SECTION,
        type_name=root.type,
        headline=cls.headline if cls else None,
        doc_comment=root.doc or (cls.doc if cls else None),
        class_doc_comment=cls.doc if cls else None,
        maps_to=cls.maps_to if cls else None,
        detailed_in=cls.detailed_in if cls else None,
        document=SomDocMeta(
            name=root.title,
            description=root.description or "",
            based_on=_based_on(cls),
        ),
        second_level_ids=_second_level_ids(cls.annotations if cls else []),
        extra=_extras(cls.annotations if cls else []),
        children=[] if cls is None else _child_nodes(model, cls, {root.type}),
    )
    return SomMetaTree(root_node)


def _based_on(cls: Optional[SpecClass]) -> list[str]:
    ann = cls.annotation("Document") if cls else None
    raw = ann.argument("basedOn") if ann else None
    if isinstance(raw, list):
        return [str(e) for e in raw]
    return []


def _child_nodes(
    model: SpecModel, cls: SpecClass, stack: set[str]
) -> list[SomMetaNode]:
    fallback = 1 << 30
    indexed = sorted(
        enumerate(cls.fields),
        key=lambda e: (
            e[1].serialization_order
            if e[1].serialization_order is not None
            else fallback,
            e[0],
        ),
    )
    return [_field_node(model, cls, f, stack) for _, f in indexed]


def _field_node(
    model: SpecModel, owner: SpecClass, field: SpecField, stack: set[str]
) -> SomMetaNode:
    kind = _KIND_OF[field.kind]
    target: Optional[SpecClass] = None
    recursive = False
    children: list[SomMetaNode] = []
    element_node: Optional[SomMetaNode] = None

    if field.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
        target = model.class_named(field.type)
        if target is not None:
            if target.name in stack:
                recursive = True
            else:
                stack.add(target.name)
                children = _child_nodes(model, target, stack)
                stack.remove(target.name)
    elif field.kind is SpecFieldKind.LIST and field.element_is_complex:
        element = model.class_named(field.element_type)
        if element is not None:
            element_children: list[SomMetaNode] = []
            element_recursive = False
            if element.name in stack:
                element_recursive = True
            else:
                stack.add(element.name)
                element_children = _child_nodes(model, element, stack)
                stack.remove(element.name)
            element_node = SomMetaNode(
                class_name=element.name,
                class_section_id=element.section_id,
                kind=SomMetaKind.COMPLEX,
                type_name=element.name,
                headline=element.headline,
                doc_comment=element.doc,
                class_doc_comment=element.doc,
                maps_to=element.maps_to,
                detailed_in=element.detailed_in,
                recursive=element_recursive,
                children=element_children,
            )

    content_type = None
    if field.content_type is not None:
        ct_ann = field.annotation("ContentType")
        content_type = SomContentTypeMeta(
            type=field.content_type,
            description=str(
                (ct_ann.argument("description") if ct_ann else None) or ""
            ),
        )

    comment_ann = field.annotation("Comment")
    comment_text = str(
        (comment_ann.argument("text") if comment_ann else None) or ""
    )

    form = None
    if field.kind is SpecFieldKind.FORM:
        form = SomFormMeta(
            fields=[
                SomFormFieldMeta(
                    name=ff.name,
                    type_name=ff.type,
                    description=ff.label,
                    required=ff.required,
                    hint=ff.hint,
                    role=ff.role,
                    initial=ff.initial,
                    order=i,
                )
                for i, ff in enumerate(field.form_fields)
            ]
        )

    return SomMetaNode(
        class_name=target.name if target else owner.name,
        member_name=field.name,
        section_id=field.section_id,
        class_section_id=target.section_id if target else None,
        section_id_pattern=field.section_id_pattern,
        kind=kind,
        type_name=field.type or field.element_type or field.enum_type
        or "String",
        serialization_order=field.serialization_order,
        min=field.min,
        unused=field.annotation("Unused") is not None,
        content_type=content_type,
        content_help=field.help,
        headline=field.headline
        if field.headline is not None
        else (target.headline if target else None),
        comment=comment_text if comment_text else None,
        doc_comment=field.doc or (target.doc if target else None),
        class_doc_comment=target.doc if target else None,
        form=form,
        maps_to=target.maps_to if target else None,
        detailed_in=target.detailed_in if target else None,
        second_level_ids=_second_level_ids(field.annotations),
        extra=_extras(field.annotations),
        recursive=recursive,
        children=children,
        element_node=element_node,
    )


_KIND_OF = {
    SpecFieldKind.LIST: SomMetaKind.LIST,
    SpecFieldKind.FORM: SomMetaKind.FORM,
    SpecFieldKind.SECTION: SomMetaKind.SECTION,
    SpecFieldKind.CONTENT: SomMetaKind.CONTENT,
    SpecFieldKind.ENUM: SomMetaKind.ENUM_VALUE,
    SpecFieldKind.COMPLEX: SomMetaKind.COMPLEX,
    SpecFieldKind.SCALAR: SomMetaKind.SCALAR,
}


def _second_level_ids(
    annotations: list[SpecAnnotation],
) -> list[SomSecondLevelId]:
    return [
        SomSecondLevelId(
            document_class=str(a.argument("documentClass") or ""),
            id=str(a.argument("id") or ""),
        )
        for a in annotations
        if a.name == "SecondLevelSectionId"
    ]


def _extras(annotations: list[SpecAnnotation]) -> list[SomMetaExtra]:
    return [
        SomMetaExtra(annotation=a.name, args=a.arguments)
        for a in annotations
        if a.name not in _SLOTTED_ANNOTATIONS
    ]
