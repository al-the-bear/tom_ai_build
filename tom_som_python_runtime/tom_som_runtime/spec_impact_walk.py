"""The impact walk — the starting table of a change's impact evaluation (the
change mode of the ``tom_specs`` process, Phase 0 step ``impact``).

For a specification it lists **every** section of **every** document root of
the model, filled or not, and roots the project never created as well: each
row with its section-id chain, its model class, whether it holds values, and
its CodeSpecs routing. The change analyst gives each row a verdict
(*affected*, *needed*, *unaffected*); a table built from the model rather than
from the document is what makes "nothing the SOM covers is missed" checkable.
Beside it, :func:`spec_impact_level` records how far the project has come
(documents, extracts, IR, tests, code).

Rows: one per class node (the root, each ``complex`` / ``section`` field, each
list item) and one per list (with its item count). An empty list of a class
element gets one **template** row ``<list>/*`` with the element's subtree below
it, so a section a new item would need shows its routing too. Value leaves
(content, form fields) are counted in their row, not rows of their own. A
class already on the branch is not entered again (the model is a graph),
exactly as the CodeSpecs routing walk cuts recursion. Below a
``@FollowUpKind`` section every row carries that routing: the whole subtree is
delivered by the process, as the CodeSpecs extractor treats it.

Pure: it reads a model and documents and writes nothing. A port of
``spec_impact_walk.ts`` in ``tom_som_typescript_runtime``; pinned by
``tom_som_conformance/corpus/impact_walk_cases.json``.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any, Callable, Mapping, Optional

from .spec_codespecs_extract import (
    CodeSpecsRouting,
    CodeSpecsRoutingVerdict,
    code_specs_class_routing,
    code_specs_field_routing,
)
from .spec_document import SpecDocument
from .spec_model import SpecClass, SpecField, SpecFieldKind, SpecModel, SpecRoot
from .spec_paths import spec_path_join
from .spec_reflection import SpecReflection


class SpecImpactRowKind:
    """What a row of the walk stands for."""

    #: The document root.
    ROOT = "root"
    #: A ``complex`` field's class node.
    COMPLEX = "complex"
    #: A ``section`` field's class node.
    SECTION = "section"
    #: A list field (its items are rows of their own).
    LIST = "list"
    #: One item of a list of class elements.
    ITEM = "item"
    #: The element class of an empty list, at ``<list>/*``: what a new item holds.
    TEMPLATE = "template"


@dataclass
class SpecImpactRow:
    """One row of the impact walk."""

    #: The document path; a template's subtree has ``*`` for the item segment.
    path: str
    #: The section-id chain, outer first, joined by `` > `` (a list item by its
    #: stored id).
    chain: str
    #: A :class:`SpecImpactRowKind` value.
    kind: str
    #: The model class; for a list, its element class (``''`` for a list of
    #: scalars).
    class_name: str
    #: Nesting below the root (the root is 0).
    depth: int
    #: Whether the document holds anything at or below the path.
    filled: bool
    #: Stored values at or below the path: content leaves plus form-field values.
    values: int
    #: A list's item count; ``None`` for every other row.
    items: Optional[int]
    #: The CodeSpecs routing verdict (``feedsCode``, ``feedsProcess``,
    #: ``feedsNothing``, ``documentRoot``, ``unrouted``).
    routing: str
    #: The routing's values verbatim.
    routing_values: list[str]
    #: Where the routing marker is declared (``Class`` or ``Class.field``);
    #: ``''`` when none.
    routing_declared_at: str

    def to_json(self) -> dict[str, Any]:
        return {
            "path": self.path,
            "chain": self.chain,
            "kind": self.kind,
            "className": self.class_name,
            "depth": self.depth,
            "filled": self.filled,
            "values": self.values,
            "items": self.items,
            "routing": self.routing,
            "routingValues": list(self.routing_values),
            "routingDeclaredAt": self.routing_declared_at,
        }


@dataclass
class SpecImpactRootWalk:
    """The walk of one document root."""

    #: The root's model type, e.g. ``D00SolutionBlueprint``.
    type: str
    #: The root's section id (its first path segment).
    section_id: str
    #: Whether the specification has this document; an absent root is walked
    #: over an empty document.
    present: bool
    rows: list[SpecImpactRow]

    def to_json(self) -> dict[str, Any]:
        return {
            "type": self.type,
            "sectionId": self.section_id,
            "present": self.present,
            "rows": [r.to_json() for r in self.rows],
        }


def spec_impact_walk(
    model: SpecModel, documents: Mapping[str, SpecDocument]
) -> list[SpecImpactRootWalk]:
    """Walks every document root of *model*, in model order: a root present in
    *documents* (keyed by root type) over its document, any other over an
    empty one. A document keyed by a type the model has no root for is
    refused."""
    for type_ in documents:
        if all(r.type != type_ for r in model.roots):
            raise ValueError(
                f"spec_impact_walk: the model has no document root {type_}"
            )
    reflection = SpecReflection(model)
    out: list[SpecImpactRootWalk] = []
    for root in model.roots:
        doc = documents.get(root.type)
        walker = _ImpactWalker(
            model, reflection, doc if doc is not None else SpecDocument()
        )
        out.append(
            SpecImpactRootWalk(
                type=root.type,
                section_id=reflection.root_segment(root),
                present=doc is not None,
                rows=walker.walk_root(root),
            )
        )
    return out


def _row(
    *,
    path: str,
    chain: str,
    kind: str,
    class_name: str,
    depth: int,
    filled: bool,
    values: int,
    items: Optional[int],
    routing: CodeSpecsRouting,
) -> SpecImpactRow:
    return SpecImpactRow(
        path=path,
        chain=chain,
        kind=kind,
        class_name=class_name,
        depth=depth,
        filled=filled,
        values=values,
        items=items,
        routing=routing.verdict.value,
        routing_values=list(routing.values),
        routing_declared_at=routing.declared_at,
    )


class _ImpactWalker:
    def __init__(
        self, model: SpecModel, reflection: SpecReflection, doc: SpecDocument
    ) -> None:
        self._model = model
        self._reflection = reflection
        self._doc = doc
        self.rows: list[SpecImpactRow] = []
        #: Stored values per path prefix (a value counts at its own path and
        #: every ancestor).
        self._counts: dict[str, int] = {}
        for path in doc.content_paths:
            if doc.content(path) is not None:
                self._count(path)
        for path in doc.form_paths:
            for name in doc.form_field_names(path):
                if doc.form_field(path, name) is not None:
                    self._count(path)

    def _count(self, path: str) -> None:
        """Adds one value at *path* to the path and each of its prefixes ending
        before ``/`` or ``-``."""
        counts = self._counts
        counts[path] = counts.get(path, 0) + 1
        for i in range(len(path) - 1, 0, -1):
            if path[i] in "/-":
                p = path[:i]
                counts[p] = counts.get(p, 0) + 1

    def _values_at(self, path: str) -> int:
        return self._counts.get(path, 0)

    def walk_root(self, root: SpecRoot) -> list[SpecImpactRow]:
        cls = self._model.class_named(root.type)
        if cls is None:
            return self.rows
        segment = self._reflection.root_segment(root)
        self._class_node(
            SpecImpactRowKind.ROOT, segment, segment, cls, 0, {cls.name}, None
        )
        return self.rows

    def _class_node(
        self,
        kind: str,
        path: str,
        chain: str,
        cls: SpecClass,
        depth: int,
        ancestors: set[str],
        process: Optional[CodeSpecsRouting],
    ) -> None:
        template = "*" in path
        routing = process if process is not None else code_specs_class_routing(cls, path)
        below = (
            routing
            if routing.verdict is CodeSpecsRoutingVerdict.FEEDS_PROCESS
            else None
        )
        self.rows.append(
            _row(
                path=path,
                chain=chain,
                kind=kind,
                class_name=cls.name,
                depth=depth,
                filled=not template and self._doc.has_values_under(path),
                values=0 if template else self._values_at(path),
                items=None,
                routing=routing,
            )
        )
        for field in cls.fields:
            segment = self._reflection.field_segment(field)
            field_path = spec_path_join(path, segment)
            field_chain = f"{chain} > {segment}"
            if field.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
                child = self._enter(field.type, ancestors)
                if child is not None:
                    child_kind = (
                        SpecImpactRowKind.COMPLEX
                        if field.kind is SpecFieldKind.COMPLEX
                        else SpecImpactRowKind.SECTION
                    )
                    self._class_node(
                        child_kind,
                        field_path,
                        field_chain,
                        child,
                        depth + 1,
                        ancestors | {child.name},
                        below,
                    )
            elif field.kind is SpecFieldKind.LIST:
                self._list(
                    cls, field, field_path, field_chain, depth + 1, ancestors, below
                )
            # else: a value leaf, counted in this row

    def _list(
        self,
        owner: SpecClass,
        field: SpecField,
        path: str,
        chain: str,
        depth: int,
        ancestors: set[str],
        process: Optional[CodeSpecsRouting],
    ) -> None:
        template = "*" in path
        items = [] if template else self._doc.list_items(path)
        element = (
            self._model.class_named(field.element_type)
            if field.element_is_complex
            else None
        )
        if process is not None:
            routing = process
        elif element is not None:
            routing = code_specs_class_routing(element, path)
        else:
            routing = code_specs_field_routing(
                owner, field
            ) or code_specs_class_routing(owner, path)
        self.rows.append(
            _row(
                path=path,
                chain=chain,
                kind=SpecImpactRowKind.LIST,
                class_name=element.name if element is not None else "",
                depth=depth,
                filled=not template and self._doc.has_values_under(path),
                values=0 if template else self._values_at(path),
                items=len(items),
                routing=routing,
            )
        )
        if element is None or element.name in ancestors:
            return
        nxt = ancestors | {element.name}
        if not items:
            self._class_node(
                SpecImpactRowKind.TEMPLATE,
                f"{path}/*",
                f"{chain} > *",
                element,
                depth + 1,
                nxt,
                process,
            )
            return
        for item_path in items:
            stored = self._doc.item_section_id(item_path)
            item_id = (
                stored if stored is not None else item_path[item_path.rfind("/") + 1:]
            )
            self._class_node(
                SpecImpactRowKind.ITEM,
                item_path,
                f"{chain} > {item_id}",
                element,
                depth + 1,
                nxt,
                process,
            )

    def _enter(
        self, type_: Optional[str], ancestors: set[str]
    ) -> Optional[SpecClass]:
        if type_ is None or type_ in ancestors:
            return None
        return self._model.class_named(type_)


# --- the project's level -----------------------------------------------------


@dataclass
class SpecImpactFolder:
    """A folder the caller passed for tests or code, and whether it exists."""

    path: str
    present: bool

    def to_json(self) -> dict[str, Any]:
        return {"path": self.path, "present": self.present}


@dataclass
class SpecImpactLevel:
    """How far the project has come (impact_evaluation.md § Level)."""

    #: Every document root: ``{type, sectionId, present}``.
    documents: list[dict[str, Any]]
    #: ``phase1_project_idea/`` holds a Markdown file.
    project_idea: bool
    #: ``CE-*.extract.yaml`` files in ``generated-doc/codespecs_extracts/``.
    extracts: int
    #: ``generated-doc/codespecs_extracts/gate.verdicts.yaml`` exists.
    gate_record: bool
    #: ``*.ir.yaml`` files in ``irspecs/``.
    ir: int
    #: Gate checklists and reports under ``gates/`` and
    #: ``quality/evidence/gates/``.
    gates: list[str]
    #: The test folders the caller passed; ``None``: none given.
    tests: Optional[list[SpecImpactFolder]]
    #: The code folders the caller passed; ``None``: none given.
    code: Optional[list[SpecImpactFolder]]
    #: The phases (1–6) the project has reached.
    phases_reached: list[int]
    #: The phases (1–6) it has not, which a change leaves out.
    phases_left_out: list[int]

    def to_json(self) -> dict[str, Any]:
        def folders(f: Optional[list[SpecImpactFolder]]) -> Any:
            return None if f is None else [x.to_json() for x in f]

        return {
            "documents": [dict(d) for d in self.documents],
            "projectIdea": self.project_idea,
            "extracts": self.extracts,
            "gateRecord": self.gate_record,
            "ir": self.ir,
            "gates": list(self.gates),
            "tests": folders(self.tests),
            "code": folders(self.code),
            "phasesReached": list(self.phases_reached),
            "phasesLeftOut": list(self.phases_left_out),
        }


def _normalise(listing: list[str]) -> list[str]:
    out = []
    for p in listing:
        f = p.replace("\\", "/")
        if f.startswith("./"):
            f = f[2:]
        out.append(f)
    return out


_PROJECT_IDEA = re.compile(r"^phase1_[^/]*/[^/]+\.md$")
_EXTRACT = re.compile(r"^generated-doc/codespecs_extracts/CE-[^/]+\.extract\.yaml$")
_IR = re.compile(r"^irspecs/[^/]+\.ir\.yaml$")
_GATE_CHECKLIST = re.compile(r"^gates/G[^/]*\.checklist\.yaml$")
_GATE_REPORT = re.compile(r"^quality/evidence/gates/[^/]+\.md$")
_DOCUMENT_FILE = re.compile(r"^phase[^/]*/[^/]+\.tomspecs\.yaml$")


def _matches(pattern: re.Pattern[str], text: str) -> bool:
    # Python's `$` also matches before a trailing newline (JS's does not):
    # fullmatch keeps the patterns' meaning identical to the TS ones.
    return pattern.fullmatch(text) is not None


def spec_impact_level(
    model: SpecModel,
    walk: list[SpecImpactRootWalk],
    listing: list[str],
    tests: Optional[list[SpecImpactFolder]],
    code: Optional[list[SpecImpactFolder]],
) -> SpecImpactLevel:
    """The project's level from the walk and a listing of the spec root (paths
    relative to it, ``/``-separated). Phase 2 is reached when the root with
    section id ``SBP`` is present, Phase 3 when any other root is that is not
    a generation input, Phase 4 when extracts or IR exist, Phases 5 and 6 when
    a test or code folder the caller passed exists. Phases 7–8 (acceptance,
    deployment) are not visible on disk and are not reported."""
    files = _normalise(listing)
    documents = [
        {"type": r.type, "sectionId": r.section_id, "present": r.present}
        for r in walk
    ]
    project_idea = any(_matches(_PROJECT_IDEA, f) for f in files)
    extracts = sum(1 for f in files if _matches(_EXTRACT, f))
    gate_record = "generated-doc/codespecs_extracts/gate.verdicts.yaml" in files
    ir = sum(1 for f in files if _matches(_IR, f))
    gates = sorted(
        f
        for f in files
        if _matches(_GATE_CHECKLIST, f) or _matches(_GATE_REPORT, f)
    )

    def present(test: Callable[[SpecRoot], bool]) -> bool:
        for w in walk:
            root = next((r for r in model.roots if r.type == w.type), None)
            if w.present and root is not None and test(root):
                return True
        return False

    reached: list[int] = []
    if project_idea:
        reached.append(1)
    if present(lambda r: r.section_id == "SBP"):
        reached.append(2)
    if present(lambda r: r.section_id != "SBP" and not model.is_generation_input(r)):
        reached.append(3)
    if extracts > 0 or ir > 0:
        reached.append(4)
    if tests is not None and any(t.present for t in tests):
        reached.append(5)
    if code is not None and any(c.present for c in code):
        reached.append(6)
    return SpecImpactLevel(
        documents=documents,
        project_idea=project_idea,
        extracts=extracts,
        gate_record=gate_record,
        ir=ir,
        gates=gates,
        tests=tests,
        code=code,
        phases_reached=reached,
        phases_left_out=[p for p in range(1, 7) if p not in reached],
    )


def spec_impact_document_files(listing: list[str]) -> list[str]:
    """The specification's current documents in a listing of the spec root:
    the ``*.tomspecs.yaml`` files directly in a ``phase*`` folder. The
    numbered step folders below hold round copies and are not the
    specification."""
    return sorted(f for f in _normalise(listing) if _matches(_DOCUMENT_FILE, f))


# --- the Markdown table ------------------------------------------------------


def _cell(text: str) -> str:
    return text.replace("|", "\\|")


def spec_impact_walk_markdown(
    walk: list[SpecImpactRootWalk], level: Optional[SpecImpactLevel]
) -> str:
    """The walk as Markdown, for a round folder's ``walk/`` (one table per
    root, then § Level): the table the change analyst gives verdicts to."""
    out: list[str] = ["# Impact walk", ""]
    out.extend(
        [
            "Every section of every document root, filled or not: the section-id "
            "chain, the model class, whether it holds values, and its CodeSpecs "
            "routing. A list counts its items; an empty list of sections shows "
            "what a new item holds at `<list>/*`.",
            "",
        ]
    )
    for root in walk:
        filled = sum(1 for r in root.rows if r.filled)
        out.extend(
            [
                f"## {root.section_id} — {root.type}"
                f"{'' if root.present else ' (absent)'}",
                "",
                f"{len(root.rows)} rows, {filled} holding values.",
                "",
                "| Section-id chain | Path | Kind | Class | Values | Items | Routing |",
                "| --- | --- | --- | --- | --- | --- | --- |",
            ]
        )
        for r in root.rows:
            routing = (
                f"{r.routing}: {', '.join(r.routing_values)}"
                if r.routing_values
                else r.routing
            )
            values = str(r.values) if r.filled else "—"
            items = str(r.items) if r.items is not None else ""
            out.append(
                f"| {_cell(r.chain)} | `{_cell(r.path)}` | {r.kind} | "
                f"{_cell(r.class_name)} | {values} | {items} | {_cell(routing)} |"
            )
        out.append("")
    if level is not None:

        def yes(b: bool) -> str:
            return "yes" if b else "no"

        def folders(f: Optional[list[SpecImpactFolder]]) -> str:
            if f is None:
                return "not given"
            if not f:
                return "none"
            return ", ".join(
                f"`{x.path}` ({'present' if x.present else 'absent'})" for x in f
            )

        present = ", ".join(
            d["sectionId"] for d in level.documents if d["present"]
        )
        absent = ", ".join(
            d["sectionId"] for d in level.documents if not d["present"]
        )
        gates = (
            ", ".join(f"`{g}`" for g in level.gates) if level.gates else "none"
        )
        reached = ", ".join(str(p) for p in level.phases_reached)
        left_out = ", ".join(str(p) for p in level.phases_left_out)
        out.extend(["## Level", ""])
        out.extend(
            [
                f"- Documents present: {present or 'none'}",
                f"- Documents absent: {absent or 'none'}",
                f"- Project Idea: {yes(level.project_idea)}",
                f"- CodeSpecs extracts: {level.extracts}; gate record: "
                f"{yes(level.gate_record)}",
                f"- IR Specs: {level.ir}",
                f"- Gates: {gates}",
                f"- Tests: {folders(level.tests)}",
                f"- Code: {folders(level.code)}",
                f"- Phases reached: {reached or 'none'}; left out by a change: "
                f"{left_out or 'none'} (Phases 7–8 are not visible on disk)",
                "",
            ]
        )
    return "\n".join(out)
