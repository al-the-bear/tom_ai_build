"""Meta-model-validated node creation for a live :class:`SpecDocument`
(llm_and_d4rt_tools.md §5 "constrained node creation") — a faithful port of
``tom_som_dart_runtime/lib/src/spec_node_creation.dart``.

Every node a script or tool adds passes through this single gate, so the
document can only grow in ways the :class:`SpecModel` permits for the parent.
The rules are the ``tom_specs_model_rules.md`` §10.2 *structural* rules — but
read from the model meta-data the runtime already carries
(:attr:`SpecField.kind`, :attr:`SpecField.section_id_pattern`,
:attr:`SpecField.min`), **not** from the analyzer-backed authoring validator in
``tom_specs_clitool``. The clitool validates the *authored model graph*; this
validates a *document mutation against that model*. They are different layers
and the runtime keeps its lean, ``yaml``-only dependency footprint.

:func:`check_add_node` is the single, value-aware rule-check entry point
(exported for reuse by editors and the engine); :meth:`SpecNodeCreator.add`
applies it and performs the mutation only when it returns ``None``, so an
illegal add never touches the tree.
"""

from __future__ import annotations

import datetime as _dt
from enum import Enum
from typing import Optional

from .spec_document import SpecDocument
from .spec_model import SpecClass, SpecField, SpecFieldKind, SpecModel
from .spec_paths import spec_path_join
from .spec_reflection import SpecReflection
from .spec_section_id import (
    generate_list_item_section_id,
    section_id_pattern_prefix,
)


class SpecCreationCode(Enum):
    """Why an attempted node creation is illegal against the model."""

    #: The parent path does not resolve to a node that can own named children
    #: (it is dangling, a leaf, or a list — lists grow through their own field,
    #: not by adding children to the list node).
    NOT_A_CONTAINER = "notAContainer"

    #: The requested child segment names no field on the parent's class.
    UNKNOWN_CHILD = "unknownChild"

    #: A caller-proposed list-item id does not keep the prefix mandated by the
    #: list's ``@SectionIdPattern`` (AA1 criterion 3/5: an override replaces the
    #: suffix, the pattern prefix stays).
    PATTERN_MISMATCH = "patternMismatch"

    #: A caller-proposed list-item id collides with another item's section id in
    #: the same list (AA1 criterion 5: section ids within a list must be
    #: unique).
    DUPLICATE_SECTION_ID = "duplicateSectionId"

    #: A single-valued (non-list) child already holds a value — only one is
    #: allowed.
    CARDINALITY_EXCEEDED = "cardinalityExceeded"


class SpecCreationError(Exception):
    """A rejected node-creation attempt. Raised by :meth:`SpecNodeCreator.add`
    and returned (rather than raised) by :func:`check_add_node`."""

    def __init__(
        self,
        parent_path: str,
        child_segment: str,
        code: SpecCreationCode,
        message: str,
    ) -> None:
        super().__init__(
            f"SpecCreationError({code.value}) under "
            f'"{parent_path}" → "{child_segment}": {message}'
        )
        #: The parent path the add was attempted under.
        self.parent_path = parent_path
        #: The child section segment that was requested.
        self.child_segment = child_segment
        #: Why the add is illegal.
        self.code = code
        #: A human-readable explanation.
        self.message = message


def check_add_node(
    model: SpecModel,
    document: SpecDocument,
    parent_path: str,
    child_segment: str,
    item_id: Optional[str] = None,
) -> Optional[SpecCreationError]:
    """Validates adding child *child_segment* under *parent_path* against
    *model*, consulting *document* for cardinality. Returns ``None`` when the add
    is legal, otherwise the :class:`SpecCreationError` describing the first rule
    it breaks.

    This performs **no mutation**; it is the shared rule-check that
    :meth:`SpecNodeCreator.add` (and any editor) calls before touching the tree.
    """
    refl = SpecReflection(model)

    def err(code: SpecCreationCode, message: str) -> SpecCreationError:
        return SpecCreationError(
            parent_path=parent_path,
            child_segment=child_segment,
            code=code,
            message=message,
        )

    # 1. The parent must resolve to a class-bearing node (root / complex /
    #    section / complex list item). Leaves, lists and dangling paths cannot
    #    own named children.
    parent = refl.resolve(parent_path)
    if parent is None or parent.target_class is None:
        what = "does not resolve" if parent is None else f"is a {parent.kind.value}"
        return err(
            SpecCreationCode.NOT_A_CONTAINER,
            f"parent path {what} and cannot own child nodes",
        )
    parent_class = parent.target_class

    # 2. The child segment must name a declared field of the parent's class.
    f = _field_for_segment(parent_class, child_segment)
    if f is None:
        return err(
            SpecCreationCode.UNKNOWN_CHILD,
            f'"{child_segment}" is not a child of {parent_class.name}',
        )

    child_path = spec_path_join(parent_path, child_segment)

    if f.kind == SpecFieldKind.LIST:
        # 3. List item: validate a caller-proposed id. Lists have no upper
        #    bound, so there is no cardinality check. A missing id is generated
        #    later (criterion 3); an explicit override must keep the pattern
        #    prefix (criterion 3) and stay unique within the list (criterion 5).
        pattern = f.section_id_pattern
        if item_id is not None and pattern is not None:
            prefix = section_id_pattern_prefix(pattern)
            if not item_id.startswith(prefix):
                return err(
                    SpecCreationCode.PATTERN_MISMATCH,
                    f'item id "{item_id}" does not keep the pattern prefix '
                    f'"{prefix}"',
                )
            if item_id in document.list_item_section_ids(child_path):
                return err(
                    SpecCreationCode.DUPLICATE_SECTION_ID,
                    f'item id "{item_id}" is already used in list "{child_path}"',
                )
        return None

    # 4. Single-valued child (complex / section / form / content / enum /
    #    scalar): cardinality is exactly one, so reject if a value already
    #    exists at or beneath the child path.
    if document.has_values_under(child_path):
        return err(
            SpecCreationCode.CARDINALITY_EXCEEDED,
            f'a {f.kind.value} child already exists at "{child_path}"',
        )
    return None


class SpecNodeCreator:
    """Applies :func:`check_add_node` and performs the constrained mutation.

    Holds the *model*/*document* pair so callers add children by parent path and
    child segment without re-supplying the context each time."""

    def __init__(self, model: SpecModel, document: SpecDocument) -> None:
        self.model = model
        self.document = document

    def add(
        self,
        parent_path: str,
        child_segment: str,
        item_id: Optional[str] = None,
        month: Optional[int] = None,
        day: Optional[int] = None,
    ) -> str:
        """Adds child *child_segment* under *parent_path* and returns the new
        node's path.

        For a list field this appends a fresh item (``…/<segment>-<seq>``),
        assigning its **section id** (AA1 criteria 3–5): *item_id* if given
        (override), otherwise one generated from the field's
        ``@SectionIdPattern`` using *month*/*day* (defaulting to today) for the
        two-letter-date component. Lists with no pattern (scalar lists) get no
        section id. For a single-valued field it returns the child path without
        mutating the sparse store (the caller then sets its value).

        Raises :class:`SpecCreationError` — leaving the document untouched —
        when the add violates a structural rule (see :class:`SpecCreationCode`).
        """
        error = check_add_node(
            self.model, self.document, parent_path, child_segment, item_id=item_id
        )
        if error is not None:
            raise error

        child_path = spec_path_join(parent_path, child_segment)
        parent = SpecReflection(self.model).resolve(parent_path)
        assert parent is not None and parent.target_class is not None
        f = _field_for_segment(parent.target_class, child_segment)
        assert f is not None
        if f.kind == SpecFieldKind.LIST:
            pattern = f.section_id_pattern
            if pattern is None:
                return self.document.add_list_item(child_path)
            id_ = item_id
            if id_ is None:
                today = _dt.date.today()
                id_ = generate_list_item_section_id(
                    pattern,
                    today.month if month is None else month,
                    today.day if day is None else day,
                    self.document.list_item_section_ids(child_path),
                )
            return self.document.add_list_item(child_path, id_)
        return child_path


def _field_for_segment(cls: SpecClass, segment: str) -> Optional[SpecField]:
    """The field of *cls* whose section segment (``@SectionId`` or name) is
    *segment*, or ``None`` when the class declares no such child."""
    for f in cls.fields:
        if (f.section_id or f.name) == segment:
            return f
    return None
