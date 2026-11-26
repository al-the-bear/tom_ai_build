"""Places and filters of the link vocabulary (`tom_specs_model_rules.md` §9.7):
the grammar every link annotation names places in, parsed once and resolved
under an anchor through :class:`SpecReflection` — a port of
`tom_som_dart_runtime/lib/src/spec_place.dart`.

* A **place** names a section, a list, a form field, a heading, a content
  value or a registry id: ``FRED.description``, ``FRE.@headline``,
  ``FRE-REQU-LST``, ``./RQDEP``, ``FRE/REQDEP/RQDEP.description``,
  ``<SECTIONID>.@content``, ``<SECTIONID>.@sectionId`` (:class:`SpecPlace`).
* A **filter** selects entries by one of their form values: ``<SECTIONID>``,
  ``./<SECTIONID>``, ``<SECTIONID>.<field>=<value>`` with ``|`` between
  alternatives (``FRE.priority=must|should``) (:class:`SpecPlaceFilter`).
  ``countOf`` and every ``where:`` read it.

Resolution is value-free, like :class:`SpecReflection`: it says where in a
document the place is stored, with every list item below the anchor written
``<list>-*``, and never reads a value.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Iterable, Optional

from .spec_model import FormFieldSpec, SpecClass, SpecField, SpecFieldKind
from .spec_paths import spec_path_segments
from .spec_reflection import SpecNodeKind, SpecReflection


class SpecPlaceKind:
    """What a resolved place is (the corpus compares the string values)."""

    #: A section (a class's own node or a complex member), whole.
    SECTION = "section"
    #: A ``-LST`` list container.
    LIST = "list"
    #: A form member, every field of it.
    FORM = "form"
    #: One field of a form.
    FORM_FIELD = "formField"
    #: The stored headline of a section (``.@headline``).
    HEADLINE = "headline"
    #: The content value of a section (``.@content``, or a content member).
    CONTENT = "content"
    #: The stored section id of a list element (``.@sectionId``).
    SECTION_ID = "sectionId"


class SpecPlaceProblem:
    """Why a place or a filter does not parse or does not resolve."""

    #: The text is not a place (or not a filter) of the grammar.
    MALFORMED = "malformed"
    #: The anchor path resolves to no section of the model.
    ANCHOR_UNRESOLVED = "anchorUnresolved"
    #: The place is ``./``-scoped, but no list element lies at or above the
    #: anchor.
    NOT_SCOPED = "notScoped"
    #: No section with the place's id (and ``/`` path) lies in the scope.
    UNRESOLVED = "unresolved"
    #: The place's id is reached at more than one position in the scope.
    AMBIGUOUS = "ambiguous"
    #: The named field is no form field of the section.
    NO_SUCH_FIELD = "noSuchField"
    #: ``.@content`` names a section that holds no content value.
    NO_CONTENT = "noContent"
    #: ``.@sectionId`` names a section that is no list element.
    NOT_LIST_ELEMENT = "notListElement"
    #: A slot starting with ``@`` other than ``@headline``, ``@content``,
    #: ``@sectionId``.
    RESERVED_SLOT = "reservedSlot"


class SpecPlaceException(Exception):
    """A place or filter that does not parse or resolve, with the reason."""

    def __init__(self, problem: str, text: str, message: str) -> None:
        super().__init__(message)
        #: What went wrong; the corpus compares this, never the message.
        self.problem = problem
        #: The place or filter as written.
        self.text = text
        #: The prose for the reader.
        self.message = message

    def __str__(self) -> str:
        return f'SpecPlaceException({self.problem}): "{self.text}" {self.message}'


_SEGMENT = re.compile(r"[A-Za-z0-9][A-Za-z0-9-]*")
_SLOT = re.compile(r"@?[A-Za-z_][A-Za-z0-9_]*")
_FIELD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


@dataclass(frozen=True)
class SpecPlace:
    """A place as written: ``./`` scope, ``/`` segments, section id and
    slot."""

    #: The text it was parsed from.
    text: str
    #: Whether it is written ``./…``: resolved beneath the nearest list element
    #: at or above the anchor.
    scoped: bool
    #: The section ids written before the last ``/``, which the path to the
    #: place holds in this order.
    prefix: tuple[str, ...]
    #: The section id the place names.
    section_id: str
    #: The part after the dot: a form field name, ``@headline``, ``@content``,
    #: ``@sectionId``; ``None`` for the section, list or form itself.
    slot: Optional[str] = None

    @staticmethod
    def parse(text: str) -> "SpecPlace":
        """Parses *text*; raises a :class:`SpecPlaceException` (``malformed``)
        when it is not a place."""
        place = SpecPlace.try_parse(text)
        if place is None:
            raise SpecPlaceException(
                SpecPlaceProblem.MALFORMED,
                text,
                "is not a place (`<SECTIONID>[.<field>|.@headline|.@content|"
                ".@sectionId]`, optionally `./`-scoped or a `/` path)",
            )
        return place

    @staticmethod
    def try_parse(text: str) -> Optional["SpecPlace"]:
        """Parses *text*, or returns ``None`` when it is not a place."""
        scoped = text.startswith("./")
        body = text[2:] if scoped else text
        if body == "":
            return None
        segments = body.split("/")
        last = segments.pop()
        dot = last.find(".")
        id_ = last if dot < 0 else last[:dot]
        slot = None if dot < 0 else last[dot + 1:]
        if not _SEGMENT.fullmatch(id_) or any(
            not _SEGMENT.fullmatch(s) for s in segments
        ):
            return None
        if slot is not None and not _SLOT.fullmatch(slot):
            return None
        return SpecPlace(
            text=text,
            scoped=scoped,
            prefix=tuple(segments),
            section_id=id_,
            slot=slot,
        )

    def to_json(self) -> dict[str, Any]:
        """The parsed parts, for the corpus."""
        out: dict[str, Any] = {
            "scoped": self.scoped,
            "prefix": list(self.prefix),
            "sectionId": self.section_id,
        }
        if self.slot is not None:
            out["slot"] = self.slot
        return out

    def resolve(self, refl: SpecReflection, anchor: str) -> "SpecPlaceResolution":
        """Resolves the place under *anchor*, a document path of a section (a
        root, a complex or section member, or a list item). Raises a
        :class:`SpecPlaceException` when it does not resolve.

        The place is looked for in the subtree of the anchor's class — beneath
        the nearest list element at or above the anchor when it is
        ``./``-scoped — among the positions whose section id is
        :attr:`section_id` and whose path holds the :attr:`prefix` ids in order
        (only ``-LST`` containers and the scope's own id may lie between them).
        More than one such position is ``ambiguous``."""
        scope = _scope_of(refl, anchor, self.scoped, self.text)
        candidates = [
            p
            for p in _positions(refl, scope)
            if p.node.id == self.section_id
            and _path_matches(p.ids[:-1], self.prefix)
        ]
        if not candidates:
            raise SpecPlaceException(
                SpecPlaceProblem.UNRESOLVED,
                self.text,
                f"resolves to no section beneath {scope.path}",
            )
        by_path: dict[str, _Position] = {}
        for p in candidates:
            by_path[p.node.path] = p
        if len(by_path) > 1:
            raise SpecPlaceException(
                SpecPlaceProblem.AMBIGUOUS,
                self.text,
                f"is ambiguous: {self.section_id} is reached at "
                f"{', '.join(sorted(by_path))} — write it as a `/` path",
            )
        return self._with_slot(next(iter(by_path.values())))

    def _with_slot(self, p: "_Position") -> "SpecPlaceResolution":
        n = p.node

        def result(
            kind: str, path: str, form_field: Optional[FormFieldSpec] = None
        ) -> SpecPlaceResolution:
            return SpecPlaceResolution(
                place=self,
                kind=kind,
                path=path,
                class_name=n.class_name,
                section_ids=p.ids,
                form_field=form_field,
            )

        slot = self.slot
        if slot is None:
            if n.shape == "list":
                return result(SpecPlaceKind.LIST, n.path)
            if n.shape == "form":
                return result(SpecPlaceKind.FORM, n.path)
            if n.shape == "content":
                return result(SpecPlaceKind.CONTENT, n.path)
            return result(SpecPlaceKind.SECTION, n.path)
        if slot == "@headline":
            return result(SpecPlaceKind.HEADLINE, n.path)
        if slot == "@content":
            if n.content_path is None:
                raise SpecPlaceException(
                    SpecPlaceProblem.NO_CONTENT,
                    self.text,
                    f"names @content of {self.section_id}, which holds no "
                    "content value",
                )
            return result(SpecPlaceKind.CONTENT, n.content_path)
        if slot == "@sectionId":
            if not n.is_list_element:
                raise SpecPlaceException(
                    SpecPlaceProblem.NOT_LIST_ELEMENT,
                    self.text,
                    f"names @sectionId of {self.section_id}, which is no list "
                    "element",
                )
            return result(SpecPlaceKind.SECTION_ID, n.path)
        if slot.startswith("@"):
            raise SpecPlaceException(
                SpecPlaceProblem.RESERVED_SLOT,
                self.text,
                f'names the slot {slot} — "@" is reserved for @headline, '
                "@content and @sectionId",
            )
        ff = next((f for f in n.form_fields if f.name == slot), None)
        if ff is None or n.form_path is None:
            raise SpecPlaceException(
                SpecPlaceProblem.NO_SUCH_FIELD,
                self.text,
                f"names {self.section_id}.{slot}, which is no form field",
            )
        return result(SpecPlaceKind.FORM_FIELD, n.form_path, ff)

    def __str__(self) -> str:
        return self.text


@dataclass(frozen=True)
class SpecPlaceResolution:
    """Where a place is stored in a document."""

    #: The place resolved.
    place: SpecPlace
    #: What the place is (a :class:`SpecPlaceKind` value).
    kind: str
    #: The document path the value lives at, with every list item beneath the
    #: anchor written ``<list>-*``: the section (or list item) for a section, a
    #: headline or a section id; the list for a list; the form for a form or a
    #: form field; the content leaf for a content value.
    path: str
    #: The class of the section the place sits on (for a member, its owner).
    class_name: str
    #: The section ids on the way from the scope to the place, the place's own
    #: last.
    section_ids: tuple[str, ...]
    #: For :attr:`SpecPlaceKind.FORM_FIELD`, the field.
    form_field: Optional[FormFieldSpec] = None

    @property
    def field(self) -> Optional[str]:
        """The form field name for :attr:`SpecPlaceKind.FORM_FIELD`, else
        ``None``."""
        return self.form_field.name if self.form_field is not None else None

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form the corpus compares."""
        out: dict[str, Any] = {"kind": self.kind, "path": self.path}
        if self.field is not None:
            out["field"] = self.field
        return out


@dataclass(frozen=True)
class SpecPlaceFilter:
    """An entry filter: ``<SECTIONID>``, ``./<SECTIONID>`` or
    ``<SECTIONID>.<field>=<value>[|<value>…]``, optionally ``./``-scoped.

    It selects the entries (list elements of the class with that section id)
    one of whose own forms holds one of :attr:`values` in :attr:`field`;
    without a field every entry. ``countOf`` counts the entries it selects, a
    ``where:`` keeps the elements or rows it selects."""

    #: The text it was parsed from.
    text: str
    #: Whether it is written ``./…``: only the entries beneath the nearest list
    #: element (for ``countOf``: beneath the section holding the form).
    scoped: bool
    #: The section id of the entries.
    section_id: str
    #: The form field compared, or ``None`` for every entry.
    field: Optional[str] = None
    #: The values accepted, in written order; empty exactly when :attr:`field`
    #: is ``None``.
    values: tuple[str, ...] = ()

    @staticmethod
    def parse(text: str) -> "SpecPlaceFilter":
        """Parses *text*; raises a :class:`SpecPlaceException`
        (``malformed``) when it is not a filter."""
        f = SpecPlaceFilter.try_parse(text)
        if f is None:
            raise SpecPlaceException(
                SpecPlaceProblem.MALFORMED,
                text,
                "is not a filter (`<SECTIONID>[.<field>=<value>[|<value>…]]`, "
                "optionally `./`-scoped)",
            )
        return f

    @staticmethod
    def try_parse(text: str) -> Optional["SpecPlaceFilter"]:
        """Parses *text*, or returns ``None`` when it is not a filter."""
        scoped = text.startswith("./")
        body = text[2:] if scoped else text
        dot = body.find(".")
        id_ = body if dot < 0 else body[:dot]
        if not _SEGMENT.fullmatch(id_):
            return None
        if dot < 0:
            return SpecPlaceFilter(text=text, scoped=scoped, section_id=id_)
        eq = body.find("=", dot)
        if eq < 0:
            return None
        name = body[dot + 1:eq]
        if not _FIELD.fullmatch(name):
            return None
        values = body[eq + 1:].split("|")
        if any(v == "" for v in values):
            return None
        return SpecPlaceFilter(
            text=text,
            scoped=scoped,
            section_id=id_,
            field=name,
            values=tuple(values),
        )

    def matches(self, stored: Iterable[str]) -> bool:
        """Whether an entry whose :attr:`field` holds *stored* (trimmed
        values, as many as its forms hold) is selected."""
        if self.field is None:
            return True
        return any(v.strip() in self.values for v in stored)

    @property
    def place(self) -> SpecPlace:
        """The place of the entries: :attr:`section_id`, scoped as the filter
        is."""
        return SpecPlace(
            text=f"./{self.section_id}" if self.scoped else self.section_id,
            scoped=self.scoped,
            prefix=(),
            section_id=self.section_id,
        )

    def resolve(self, refl: SpecReflection, anchor: str) -> SpecPlaceResolution:
        """Resolves the entries under *anchor* as :meth:`SpecPlace.resolve`
        does, and checks that :attr:`field` is a field of one of the entry's
        own forms (a form member of the entry, or its content form). Raises a
        :class:`SpecPlaceException` when it does not resolve."""
        try:
            r = self.place.resolve(refl, anchor)
        except SpecPlaceException as e:
            raise SpecPlaceException(e.problem, self.text, e.message) from None
        name = self.field
        if name is not None:
            cls = refl.class_named(r.class_name)
            own: list[FormFieldSpec] = []
            if r.kind == SpecPlaceKind.SECTION and cls is not None:
                for f in cls.fields:
                    if f.kind == SpecFieldKind.FORM:
                        own.extend(f.form_fields)
            if not any(f.name == name for f in own):
                raise SpecPlaceException(
                    SpecPlaceProblem.NO_SUCH_FIELD,
                    self.text,
                    f"names {self.section_id}.{name}, which no form of "
                    f"{self.section_id} holds",
                )
        return r

    def to_json(self) -> dict[str, Any]:
        """The parsed parts, for the corpus."""
        out: dict[str, Any] = {"scoped": self.scoped, "sectionId": self.section_id}
        if self.field is not None:
            out["field"] = self.field
            out["values"] = list(self.values)
        return out

    def __str__(self) -> str:
        return self.text


@dataclass(frozen=True)
class SpecSameAsBinding:
    """A ``@SameAs`` copy at one position of a document root, with its
    holder."""

    #: The root the positions are in.
    root: str
    #: The class both positions hold.
    class_name: str
    #: The copy's document path (list items written ``<list>-*``).
    copy_path: str
    #: The copy's section-id path from the root.
    copy_section_ids: tuple[str, ...]
    #: The holder's document path, or ``None`` when :attr:`problem` is set.
    holder_path: Optional[str] = None
    #: The holder's section-id path from the root, or ``None``.
    holder_section_ids: Optional[tuple[str, ...]] = None
    #: Why no single holder was found: ``unresolved`` (no position fits) or
    #: ``ambiguous`` (several do); ``None`` when :attr:`holder_path` is set.
    problem: Optional[str] = None

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form the corpus compares."""
        out: dict[str, Any] = {
            "root": self.root,
            "className": self.class_name,
            "copy": self.copy_path,
        }
        if self.holder_path is not None:
            out["holder"] = self.holder_path
        if self.problem is not None:
            out["problem"] = self.problem
        return out


def spec_same_as_bindings(
    refl: SpecReflection, root_type: str
) -> list[SpecSameAsBinding]:
    """Every ``@SameAs`` copy the document root *root_type* reaches, each with
    its holder (`tom_specs_model_rules.md` §9.7, invariant ``SAME-AS``): among
    the positions of the copy's class in the root that are no copy themselves,
    the one whose section-id path ends with ``holder``, or — without
    ``holder`` — the one there is. In position order."""
    root = next((r for r in refl.model.roots if r.type == root_type), None)
    cls = refl.class_named(root_type)
    if root is None or cls is None:
        return []
    scope = _Scope(path=refl.root_segment(root), cls=cls, is_list_element=False)
    sections = [
        p for p in _positions(refl, scope) if p.node.shape == "section" and p.node.own_node
    ]
    out: list[SpecSameAsBinding] = []
    for copy in sections:
        same_as = copy.member.same_as if copy.member is not None else None
        if same_as is None:
            continue
        type_ = copy.node.class_name
        holder_tail = same_as.holder.split("/") if same_as.holder is not None else None
        holders = [
            p
            for p in sections
            if p.node.class_name == type_
            and (p.member is None or p.member.same_as is None)
            and (holder_tail is None or _ends_with(p.ids, holder_tail))
        ]
        single = holders[0] if len(holders) == 1 else None
        out.append(
            SpecSameAsBinding(
                root=root_type,
                class_name=type_,
                copy_path=copy.node.path,
                copy_section_ids=copy.ids,
                holder_path=single.node.path if single is not None else None,
                holder_section_ids=single.ids if single is not None else None,
                problem=(
                    SpecPlaceProblem.UNRESOLVED
                    if not holders
                    else SpecPlaceProblem.AMBIGUOUS
                    if len(holders) > 1
                    else None
                ),
            )
        )
    return out


@dataclass(frozen=True)
class SpecSectionPosition:
    """One position of a section in a document root: a class reached there
    (its own node), or a member of a class that carries a section id of its
    own."""

    #: The document path, list items written ``<list>-*``.
    path: str
    #: The class reached (:attr:`member` ``None``), or the class the member
    #: belongs to.
    class_name: str
    #: The section ids from the root to here, this position's own last.
    section_ids: tuple[str, ...]
    #: Whether this is a member position (a form, list, content or section
    #: member with its own section id) rather than a class reached.
    is_member: bool
    #: For a class position, the member it is reached through (``None`` at
    #: the root); for a member position, the member itself.
    member: Optional[SpecField] = None


def spec_section_positions(
    refl: SpecReflection, root_type: str
) -> list[SpecSectionPosition]:
    """Every section position of the document root *root_type*, in walk
    order: a class reached again on its own path is not descended into, and a
    ``@Reference`` member's target is not walked."""
    root = next((r for r in refl.model.roots if r.type == root_type), None)
    cls = refl.class_named(root_type)
    if root is None or cls is None:
        return []
    scope = _Scope(path=refl.root_segment(root), cls=cls, is_list_element=False)
    return [
        SpecSectionPosition(
            path=p.node.path,
            class_name=p.node.class_name,
            section_ids=p.ids,
            member=p.member,
            is_member=not p.node.own_node,
        )
        for p in _positions(refl, scope)
    ]


# ---------------------------------------------------------------------------
# The positions of a subtree
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class _Scope:
    path: str
    cls: SpecClass
    is_list_element: bool


@dataclass(frozen=True)
class _Node:
    id: str
    path: str
    class_name: str
    shape: str
    own_node: bool
    form_fields: list[FormFieldSpec] = field(default_factory=list)
    form_path: Optional[str] = None
    content_path: Optional[str] = None
    is_list_element: bool = False


@dataclass(frozen=True)
class _Position:
    node: _Node
    ids: tuple[str, ...]
    member: Optional[SpecField]


def _scope_of(
    refl: SpecReflection, anchor: str, scoped: bool, text: str
) -> _Scope:
    segs = spec_path_segments(anchor)
    for n in range(len(segs), 0, -1):
        path = "/".join(segs[:n])
        r = refl.resolve(path)
        if n == len(segs) and (r is None or r.target_class is None):
            raise SpecPlaceException(
                SpecPlaceProblem.ANCHOR_UNRESOLVED,
                text,
                f"has the anchor {anchor}, which resolves to no section",
            )
        is_item = r is not None and r.kind == SpecNodeKind.LIST_ITEM_COMPLEX
        if not scoped or is_item:
            # As in Dart (`r!.targetClass!`): an ancestor that resolves to no
            # class cannot be a scope.
            if r is None or r.target_class is None:
                raise TypeError(f"no class at {path}")
            return _Scope(path=path, cls=r.target_class, is_list_element=is_item)
    raise SpecPlaceException(
        SpecPlaceProblem.NOT_SCOPED,
        text,
        f"is `./`-scoped, but no list element lies at or above {anchor}",
    )


def _positions(refl: SpecReflection, scope: _Scope) -> list[_Position]:
    """Every addressable position beneath (and including) *scope*, in model
    order. A class reached again on its own path is not descended into, and a
    ``@Reference`` member is a place whose target is not walked."""
    out: list[_Position] = []

    def walk(
        cls: SpecClass,
        path: str,
        ids: tuple[str, ...],
        is_item: bool,
        via: Optional[SpecField],
        on_path: set[str],
    ) -> None:
        if cls.name in on_path:
            return
        on_path.add(cls.name)
        content = cls.field_named("content")
        here = ids
        own_id = cls.section_id
        if own_id:
            here = ids + (own_id,)
            content_seg = None if content is None else refl.field_segment(content)
            content_is_form = content is not None and content.kind == SpecFieldKind.FORM
            content_is_content = (
                content is not None and content.kind == SpecFieldKind.CONTENT
            )
            out.append(
                _Position(
                    node=_Node(
                        id=own_id,
                        path=path,
                        class_name=cls.name,
                        shape="section",
                        own_node=True,
                        form_fields=content.form_fields if content_is_form and content else [],
                        form_path=f"{path}/{content_seg}" if content_is_form else None,
                        content_path=(
                            f"{path}/{content_seg}" if content_is_content else None
                        ),
                        is_list_element=is_item,
                    ),
                    ids=here,
                    member=via,
                )
            )
        for f in cls.fields:
            seg = refl.field_segment(f)
            member_path = f"{path}/{seg}"
            sid = f.section_id
            below = here
            if f.name != "content" and sid:
                below = here + (sid,)
                if f.kind == SpecFieldKind.LIST:
                    shape = "list"
                elif f.kind == SpecFieldKind.FORM:
                    shape = "form"
                elif f.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
                    shape = "section"
                else:
                    shape = "content"
                is_form = f.kind == SpecFieldKind.FORM
                out.append(
                    _Position(
                        node=_Node(
                            id=sid,
                            path=member_path,
                            class_name=cls.name,
                            shape=shape,
                            own_node=False,
                            form_fields=f.form_fields if is_form else [],
                            form_path=member_path if is_form else None,
                            content_path=member_path if shape == "content" else None,
                            is_list_element=False,
                        ),
                        ids=below,
                        member=f,
                    )
                )
            if f.has_annotation("Reference"):
                continue
            if f.kind == SpecFieldKind.LIST and f.element_is_complex:
                el = refl.class_named(f.element_type)
                if el is not None:
                    walk(el, f"{member_path}-*", below, True, f, on_path)
            elif f.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
                child = refl.class_named(
                    f.type.replace("?", "") if f.type is not None else None
                )
                if child is not None:
                    walk(child, member_path, below, False, f, on_path)
        on_path.discard(cls.name)

    walk(scope.cls, scope.path, (), scope.is_list_element, None, set())
    return out


def _path_matches(path: tuple[str, ...], segments: tuple[str, ...]) -> bool:
    """Whether the ``/`` *segments* lead to a position whose ancestors are
    *path*: they name every section on the way, leaving out only ``-LST``
    containers and the scope's own id. No segments: any position."""
    if not segments:
        return True

    def from_(start: int) -> bool:
        j = 0
        for i in range(start, len(path)):
            if j < len(segments) and path[i] == segments[j]:
                j += 1
            elif not path[i].endswith("-LST"):
                return False
        return j == len(segments)

    return from_(0) or (len(path) > 0 and from_(1))


def _ends_with(path: tuple[str, ...], tail: list[str]) -> bool:
    """Whether *path* ends with exactly the ids of *tail*, as the static
    validator's ``SAME-AS`` reads a holder."""
    if len(path) < len(tail):
        return False
    return list(path[len(path) - len(tail):]) == tail
