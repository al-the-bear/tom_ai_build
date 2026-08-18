"""The Phase-4 **specification extract generator** — the machine half of
CodeSpecs production (`codespecs_mapping.md` §1.1.1) — a faithful port of
``tom_som_dart_runtime/lib/src/spec_codespecs_extract.dart``.

Phase 4 runs in two passes. This surface is the first: for each CodeSpecs area
it collects everything in a filled specification document that ``@CodeSpecKind``
routes to that area, **verbatim and with provenance**, so the second pass — an
authoring agent, one prompt per authoring step — writes against a bounded
extract rather than against a 652-section document.

The boundary between the two passes is a rule, not a preference. This generator
may **copy and index**; it may not summarise, rephrase, compose a sentence out
of field values, or choose a name — the prohibitions of
`codespecs_derivation_contract.md` §2.8 **C1**, which bind the extract generator
word for word. The consequence is checkable rather than trusted: every
:attr:`CodeSpecsExtractEntry.value` is a string the document stores, byte for
byte, and the conformance corpus asserts it.

Three things follow from that and shape the API:

  * **Routing is by the three verdicts** (`codespecs_mapping.md` §8.3) — a class
    carries ``@CodeSpecKind`` (feeds code), sits under a ``@FollowUpKind`` root
    (feeds a non-generation process), or carries ``@NoArtifact`` (feeds
    nothing). The trio is exhaustive by construction, so a class carrying none
    of them is not "skipped": it is a :class:`CodeSpecsExtractError`, the
    ``ROUTE-TOTAL`` invariant (`tom_specs_model_rules.md` §10.2) failing loudly
    at the one place that depends on it.
  * **``@CodeSpecKind`` is list-valued** (§9.1), and extracts are **not**
    deduplicated across areas: a section feeding three areas appears, whole, in
    three extracts. Each area's prompt must be self-sufficient.
  * **Every entry carries its provenance** — section id, class, field, the
    routing marker that put it here and where that marker was declared — so the
    ``@DocSpec``/``DocRef`` back-links (§9.3) can be written from the extract
    alone.

The area catalogue (:class:`CodeSpecsAreaCatalog`) is an **input**, not a table
baked into the runtime: it is the machine-readable form of
`codespecs_mapping.md` §4.1 (the parts catalogue), §4.4.3 (the emission slices)
and §4.4.6 (the authoring steps), authored once and read by all nine runtimes.
Carrying it beside the content is what stops an agent having to open the mapping
document to find out what ``CE-FM`` means.
"""

from __future__ import annotations

from dataclasses import dataclass, field as dataclass_field
from enum import Enum
from typing import Any, Optional

from .spec_document import SpecDocument
from .spec_model import SpecClass, SpecField, SpecFieldKind, SpecModel, SpecRoot
from .spec_paths import spec_path_join
from .spec_reflection import SpecReflection

#: The version of the emitted extract artifact's on-disk shape. Bumped when the
#: YAML or Markdown layout changes in a way a reader could notice.
K_CODE_SPECS_EXTRACT_FORMAT = 1

#: The annotation names of the three routing verdicts (`codespecs_mapping.md`
#: §8.3). All three ride the generic annotation bag in every SOM runtime (§8.4),
#: so they are read by name rather than through a meta slot.
K_CODE_SPEC_KIND_ANNOTATION = "CodeSpecKind"

#: See :data:`K_CODE_SPEC_KIND_ANNOTATION`.
K_FOLLOW_UP_KIND_ANNOTATION = "FollowUpKind"

#: See :data:`K_CODE_SPEC_KIND_ANNOTATION`.
K_NO_ARTIFACT_ANNOTATION = "NoArtifact"


class CodeSpecsRoutingVerdict(Enum):
    """Which of the three `codespecs_mapping.md` §8.3 verdicts a class
    carries."""

    #: ``@CodeSpecKind(List<CodeSpecPart>)`` — the section's content is shown to
    #: every named area's extract.
    FEEDS_CODE = "feedsCode"
    #: ``@FollowUpKind(List<FollowUpProcess>)`` — the section is delivered by a
    #: non-generation process. The whole subtree is excluded from every extract.
    FEEDS_PROCESS = "feedsProcess"
    #: ``@NoArtifact(NoArtifactReason)`` — the section deliberately produces no
    #: downstream artifact. Its own leaves contribute nothing; its children are
    #: still routed individually (that is what ``container`` means).
    FEEDS_NOTHING = "feedsNothing"
    #: A ``@Document`` root carrying no verdict. Structurally exempt from
    #: ``ROUTE-TOTAL``: a root is the document, not a section of it.
    DOCUMENT_ROOT = "documentRoot"
    #: No verdict, and not a ``@Document`` root — a ``ROUTE-TOTAL`` violation,
    #: and the reason :meth:`CodeSpecsExtractor.extract_all` raises.
    UNROUTED = "unrouted"


@dataclass(frozen=True)
class CodeSpecsRouting:
    """The verdict recorded for one class node of the walked document, with the
    provenance of the marker that decided it."""

    #: The document path of the node the verdict was computed for.
    path: str
    #: The model class at :attr:`path`.
    class_name: str
    #: Which verdict the class carries.
    verdict: CodeSpecsRoutingVerdict
    #: The verdict's payload, verbatim from the annotation: the
    #: ``CodeSpecPart.*`` values for
    #: :attr:`CodeSpecsRoutingVerdict.FEEDS_CODE`, the ``FollowUpProcess.*``
    #: values for :attr:`CodeSpecsRoutingVerdict.FEEDS_PROCESS`, the single
    #: ``NoArtifactReason.*`` for
    #: :attr:`CodeSpecsRoutingVerdict.FEEDS_NOTHING`, and empty for the two
    #: verdicts that have no marker.
    values: list[str] = dataclass_field(default_factory=list)
    #: The marker's optional ``note``, verbatim; ``None`` when it carries none.
    note: Optional[str] = None
    #: Where the marker was declared — the class name, or ``Class.field`` when a
    #: field-level ``@CodeSpecKind`` overrode its class. Empty when there is no
    #: marker.
    declared_at: str = ""


@dataclass(frozen=True)
class CodeSpecsExtractEntry:
    """One extract entry: a single value the specification document stores, with
    everything needed to trace it back (`codespecs_mapping.md` §1.1.1,
    "Entry")."""

    #: The ``CE-*`` code of the area this entry was collected for.
    area_code: str
    #: The section id of the leaf the value sits on (``@SectionId``, else the
    #: model field name).
    section_id: str
    #: The document path of the leaf — the source location.
    path: str
    #: The model class declaring the leaf.
    class_name: str
    #: The model field name of the leaf.
    field_name: str
    #: The ``CodeSpecPart.*`` value that routed this entry here, verbatim.
    routed_by: str
    #: Where that ``@CodeSpecKind`` was declared — the class name, or
    #: ``Class.field`` for a field-level override.
    routed_at: str
    #: The stored value, **verbatim**. Never assembled, reformatted or trimmed.
    value: str
    #: The form-field name when the value is one field of a ``@Form`` section;
    #: ``None`` for a content, enum, scalar or scalar-list leaf.
    form_field: Optional[str] = None
    #: The ``@CodeSpecKind`` ``note``, verbatim; ``None`` when it carries none.
    routing_note: Optional[str] = None


@dataclass(frozen=True)
class CodeSpecsSlice:
    """One emission slice of `codespecs_mapping.md` §4.4.3."""

    #: The slice's number, 1–7.
    number: int
    #: The slice's name as §4.4.3 gives it.
    title: str = ""
    #: The §4.2 project the slice emits into.
    project: str = ""
    #: The slices this one may cite — §4.4.3's across-slice edges. Transitively
    #: closed by :meth:`CodeSpecsAreaCatalog.citable_area_codes`.
    cites: list[int] = dataclass_field(default_factory=list)

    @staticmethod
    def from_json(j: dict[str, Any]) -> "CodeSpecsSlice":
        return CodeSpecsSlice(
            number=int(j["number"]),
            title=j.get("title") or "",
            project=j.get("project") or "",
            cites=_int_list(j.get("cites")),
        )


@dataclass(frozen=True)
class CodeSpecsArea:
    """One row of the `codespecs_mapping.md` §4.1 parts catalogue, plus the
    §4.4.3 slice and §4.4.6 authoring steps that place it. This is the
    **per-area context** an extract carries beside its content."""

    #: The permanent registry key — ``CE-FM``, ``CE-API``. Never reused, never
    #: renamed, and the extract file's name.
    code: str
    #: The ``CodeSpecPart`` value, camelCase and **without** the enum prefix
    #: (``form``, ``serverApi``).
    part: str
    #: The §4.1 canonical id — the PascalCase noun (``Form``, ``ServerApi``).
    canonical_id: str = ""
    #: The ``Cs*`` annotation names of the §4.1 row.
    annotations: list[str] = dataclass_field(default_factory=list)
    #: The §4.1 "Built on" cell, verbatim.
    built_on: str = ""
    #: Where the area's spec-authorable attribute surface is stated — a §5.x
    #: citation.
    attribute_surface: str = ""
    #: The §4.4.3 slice(s) the area's emission units sit in. More than one when
    #: the area is split by locus.
    slices: list[int] = dataclass_field(default_factory=list)
    #: The §4.4.6 authoring step(s) that write the area.
    authoring_steps: list[int] = dataclass_field(default_factory=list)
    #: Whether the part is active. A deferred part (§4.3) holds a reserved
    #: ``CodeSpecPart`` value but has no generated surface, so it gets no
    #: extract.
    active: bool = True

    @staticmethod
    def from_json(j: dict[str, Any]) -> "CodeSpecsArea":
        raw_active = j.get("active")
        return CodeSpecsArea(
            code=j["code"],
            part=j["part"],
            canonical_id=j.get("canonicalId") or "",
            annotations=_string_list(j.get("annotations")),
            built_on=j.get("builtOn") or "",
            attribute_surface=j.get("attributeSurface") or "",
            slices=_int_list(j.get("slices")),
            authoring_steps=_int_list(j.get("authoringSteps")),
            active=True if raw_active is None else bool(raw_active),
        )

    @property
    def kind_value(self) -> str:
        """The fully-qualified ``@CodeSpecKind`` value — ``CodeSpecPart.form``."""
        return f"CodeSpecPart.{self.part}"


@dataclass(frozen=True)
class CodeSpecsAreaCatalog:
    """The machine-readable form of `codespecs_mapping.md` §4.1 + §4.4.3 +
    §4.4.6.

    Authored once, read by all nine runtimes. It is an input rather than a baked
    table because the catalogue is the mapping document's content: a copy per
    runtime would be nine things to keep current, and the one thing this quest
    has learned three times is that a vocabulary duplicated nine ways can be
    wrong in agreement."""

    #: Where the catalogue was transcribed from, for the extract header.
    source: str = ""
    #: The §4.4.3 slices, in emission order.
    slices: list[CodeSpecsSlice] = dataclass_field(default_factory=list)
    #: The §4.1 areas, in catalogue order. Catalogue order is the tie-break
    #: §4.4.6 rule 2 uses, so it is load-bearing rather than cosmetic.
    areas: list[CodeSpecsArea] = dataclass_field(default_factory=list)

    @staticmethod
    def from_json(j: dict[str, Any]) -> "CodeSpecsAreaCatalog":
        return CodeSpecsAreaCatalog(
            source=j.get("source") or "",
            slices=[CodeSpecsSlice.from_json(e) for e in (j.get("slices") or [])],
            areas=[CodeSpecsArea.from_json(e) for e in (j.get("areas") or [])],
        )

    @property
    def active_areas(self) -> list[CodeSpecsArea]:
        """The active areas, in catalogue order — one extract each."""
        return [a for a in self.areas if a.active]

    def by_code(self, code: str) -> Optional[CodeSpecsArea]:
        """The area with this ``CE-*`` code, or ``None``."""
        for a in self.areas:
            if a.code == code:
                return a
        return None

    def by_part(self, value: str) -> Optional[CodeSpecsArea]:
        """The area a ``@CodeSpecKind`` value names, or ``None``. Accepts both
        the bare value (``form``) and the qualified one (``CodeSpecPart.form``),
        because the meta carries the qualified spelling and callers reach for
        the bare one."""
        prefix = "CodeSpecPart."
        bare = value[len(prefix) :] if value.startswith(prefix) else value
        for a in self.areas:
            if a.part == bare:
                return a
        return None

    def slice_numbered(self, number: int) -> Optional[CodeSpecsSlice]:
        """The slice numbered *number*, or ``None``."""
        for s in self.slices:
            if s.number == number:
                return s
        return None

    def projects_for(self, area: CodeSpecsArea) -> list[str]:
        """The §4.2 projects *area*'s code lands in, in slice order.

        Derived from the area's slices rather than authored on the area: §4.4.3
        already fixes one project per slice, so a per-area project column would
        be a second place for the same fact to be stated — and the areas that
        would need it are exactly the locus-split ones, where getting it wrong
        is easiest."""
        out: list[str] = []
        for n in area.slices:
            s = self.slice_numbered(n)
            project = None if s is None else s.project
            if not project or project in out:
                continue
            out.append(project)
        return out

    def citable_area_codes(self, area: CodeSpecsArea) -> list[str]:
        """The area codes *area* may cite — every other active area whose
        emission units sit in a slice *area*'s slices reach, following §4.4.3's
        edges transitively. Within-slice citation is legal, so an area's own
        slices are part of the reachable set; the area itself is excluded.

        Derived rather than authored: a hand-kept per-area citation list is a
        second source of truth for something the slice graph already
        decides."""
        reachable: set[int] = set()
        stack = list(area.slices)
        while stack:
            n = stack.pop()
            if n in reachable:
                continue
            reachable.add(n)
            s = self.slice_numbered(n)
            if s is None:
                continue
            stack.extend(s.cites)
        out: list[str] = []
        for a in self.areas:
            if not a.active or a.code == area.code:
                continue
            for s_number in a.slices:
                if s_number in reachable:
                    out.append(a.code)
                    break
        return out


@dataclass(frozen=True)
class CodeSpecsExtract:
    """One area's extract: the area's context plus every routed entry, in SOM
    document order."""

    #: The area this extract is for.
    area: CodeSpecsArea
    #: The section segment of the document root the entries were collected from.
    document_root: str
    #: The `codespecs_mapping.md` §4.1/§4.4.3 source the catalogue names.
    catalog_source: str = ""
    #: The area codes this area may cite (§4.4.3), for the agent's prompt.
    citable_parts: list[str] = dataclass_field(default_factory=list)
    #: The §4.2 projects the area's code lands in (§4.4.3, via the slices).
    projects: list[str] = dataclass_field(default_factory=list)
    #: The routed entries, in SOM document order.
    entries: list[CodeSpecsExtractEntry] = dataclass_field(default_factory=list)

    @property
    def file_stem(self) -> str:
        """The extract's file name stem — ``CE-FM.extract``."""
        return f"{self.area.code}.extract"

    def to_yaml(self) -> str:
        """The artifact of record (`codespecs_mapping.md` §1.1.1). Scalars are
        emitted as JSON strings, which are valid YAML 1.2 double-quoted scalars
        — so one escaping rule, identical in all nine runtimes, covers every
        value a specification can hold."""
        b = _Buffer()
        b.writeln(
            f"# {self.area.code}.extract.yaml — generated by "
            f"spec_codespecs_extract. Do not edit."
        )
        b.writeln("extract:")
        b.writeln(f"  formatVersion: {K_CODE_SPECS_EXTRACT_FORMAT}")
        b.writeln(f"  catalogSource: {_yaml_string(self.catalog_source)}")
        b.writeln("  area:")
        b.writeln(f"    code: {_yaml_string(self.area.code)}")
        b.writeln(f"    canonicalId: {_yaml_string(self.area.canonical_id)}")
        b.writeln(f"    part: {_yaml_string(self.area.kind_value)}")
        b.writeln(f"    annotations: {_yaml_string_list(self.area.annotations)}")
        b.writeln(f"    builtOn: {_yaml_string(self.area.built_on)}")
        b.writeln(
            f"    attributeSurface: {_yaml_string(self.area.attribute_surface)}"
        )
        b.writeln(f"    slices: {_yaml_int_list(self.area.slices)}")
        b.writeln(
            f"    authoringSteps: {_yaml_int_list(self.area.authoring_steps)}"
        )
        b.writeln(f"    projects: {_yaml_string_list(self.projects)}")
        b.writeln(f"    citableParts: {_yaml_string_list(self.citable_parts)}")
        b.writeln("  document:")
        b.writeln(f"    root: {_yaml_string(self.document_root)}")
        b.writeln(f"    entryCount: {len(self.entries)}")
        if not self.entries:
            b.writeln("  entries: []")
            return str(b)
        b.writeln("  entries:")
        for e in self.entries:
            b.writeln(f"    - sectionId: {_yaml_string(e.section_id)}")
            b.writeln(f"      path: {_yaml_string(e.path)}")
            b.writeln(f"      className: {_yaml_string(e.class_name)}")
            b.writeln(f"      fieldName: {_yaml_string(e.field_name)}")
            b.writeln(f"      formField: {_yaml_nullable_string(e.form_field)}")
            b.writeln(f"      routedBy: {_yaml_string(e.routed_by)}")
            b.writeln(f"      routedAt: {_yaml_string(e.routed_at)}")
            b.writeln(
                f"      routingNote: {_yaml_nullable_string(e.routing_note)}"
            )
            b.writeln(f"      value: {_yaml_string(e.value)}")
        return str(b)

    def to_markdown(self) -> str:
        """The rendered view. Regenerated from the YAML's own data — nothing
        reads the Markdown as input — and exists because the agent reads it far
        better than it reads YAML."""
        b = _Buffer()
        b.writeln(f"# {self.area.code} — {self.area.canonical_id}")
        b.writeln()
        b.writeln(
            f"Generated by `spec_codespecs_extract` from the specification "
            f"document rooted at `{self.document_root}`."
        )
        b.writeln(
            f"`{self.area.code}.extract.yaml` beside this file is the artifact "
            f"of record; this is a view of it."
        )
        b.writeln()
        b.writeln("## Area")
        b.writeln()
        b.writeln("| | |")
        b.writeln("|---|---|")
        b.writeln(f"| CE code | `{self.area.code}` |")
        b.writeln(f"| Canonical id | `{self.area.canonical_id}` |")
        b.writeln(f"| `@CodeSpecKind` value | `{self.area.kind_value}` |")
        b.writeln(f"| `Cs*` annotations | {_md_code_list(self.area.annotations)} |")
        b.writeln(f"| Built on | {_md_cell(self.area.built_on)} |")
        b.writeln(
            f"| Attribute surface | {_md_cell(self.area.attribute_surface)} |"
        )
        b.writeln(f"| Slice(s) | {_md_int_list(self.area.slices)} |")
        b.writeln(
            f"| Authoring step(s) | {_md_int_list(self.area.authoring_steps)} |"
        )
        b.writeln(f"| Project(s) | {_md_code_list(self.projects)} |")
        b.writeln(f"| May cite | {_md_code_list(self.citable_parts)} |")
        b.writeln(f"| Catalogue source | {_md_cell(self.catalog_source)} |")
        b.writeln()
        b.writeln(f"## Entries ({len(self.entries)})")
        b.writeln()
        if not self.entries:
            b.writeln(
                f"_No section of this document is routed to "
                f"`{self.area.kind_value}`._"
            )
            return str(b)
        n = 0
        for e in self.entries:
            n += 1
            member = (
                e.field_name
                if e.form_field is None
                else f"{e.field_name}.{e.form_field}"
            )
            b.writeln(f"### {n}. `{e.section_id}` — `{e.class_name}.{member}`")
            b.writeln()
            b.writeln(f"- path: `{e.path}`")
            b.writeln(f"- routed by: `{e.routed_by}` declared on `{e.routed_at}`")
            if e.routing_note is not None:
                b.writeln(f"- routing note: {_md_cell(e.routing_note)}")
            b.writeln()
            fence = _fence_for(e.value)
            b.writeln(f"{fence} text")
            b.writeln(e.value)
            b.writeln(fence)
            b.writeln()
        return str(b)


class CodeSpecsExtractError(Exception):
    """Raised when the document cannot be extracted from at all.

    Two causes: a section routed nowhere — ``ROUTE-TOTAL``
    (`tom_specs_model_rules.md` §10.2) failing — and a walk root that cannot be
    resolved to exactly one (`codespecs_prompt.md` §5). Both are errors rather
    than skips: a section routed nowhere is a section the agent writing that
    area never sees, and a walk over the wrong root is every area empty. A
    silent omission at this boundary is indistinguishable from a specification
    that genuinely said nothing."""

    def __init__(self, message: str, path: str, class_name: str) -> None:
        super().__init__(f"CodeSpecsExtractError: {message} ({path}, {class_name})")
        #: What went wrong, in one sentence.
        self.message = message
        #: The document path of the offending node.
        self.path = path
        #: The model class at :attr:`path`.
        self.class_name = class_name


def _root_segment(root: SpecRoot) -> str:
    return root.section_id or root.type


def _resolve_root(
    model: SpecModel, document: SpecDocument, root_type: Optional[str]
) -> SpecRoot:
    """The one root :class:`CodeSpecsExtractor` walks — `codespecs_prompt.md`
    §5."""
    populated = [r for r in model.roots if document.has_values_under(_root_segment(r))]
    names = ", ".join(r.type for r in model.roots)
    if root_type:
        for r in model.roots:
            if r.type != root_type and _root_segment(r) != root_type:
                continue
            if populated and r not in populated:
                raise CodeSpecsExtractError(
                    message=f'root "{root_type}" holds no value in this '
                    f"document, but {', '.join(p.type for p in populated)} "
                    "does — every extract would come out empty "
                    "(codespecs_prompt.md §5)",
                    path=_root_segment(r),
                    class_name=r.type,
                )
            return r
        raise CodeSpecsExtractError(
            message="no document root with type or section id "
            f'"{root_type}" (have: {names})',
            path="",
            class_name=root_type,
        )
    if len(populated) == 1:
        return populated[0]
    if not populated:
        if len(model.roots) == 1:
            return model.roots[0]
        raise CodeSpecsExtractError(
            message="document has no populated root to extract from; pass "
            f"root_type to choose one (have: {names})",
            path="",
            class_name="",
        )
    raise CodeSpecsExtractError(
        message=f"document has {len(populated)} populated roots "
        f"({', '.join(r.type for r in populated)}); pass root_type to "
        "choose one",
        path="",
        class_name="",
    )


class CodeSpecsExtractor:
    """Produces one :class:`CodeSpecsExtract` per active area from a filled
    specification document.

    A Phase-4 run extracts from **one** specification document, so the walk has
    exactly one root (:attr:`root`, `codespecs_prompt.md` §5). The two ways to
    get that wrong are both closed here rather than left to the caller: the walk
    cannot union every ``@Document`` root, because there is no way to ask for
    that; and naming a root the document never populates — the
    ``D13CodeSpecsProjection`` mistake, whose ``CGP/…`` path space misses a
    blueprint's ``SBP/…`` values and yields every area silently empty — raises
    :class:`CodeSpecsExtractError` rather than returning an empty result."""

    def __init__(
        self,
        model: SpecModel,
        document: SpecDocument,
        catalog: CodeSpecsAreaCatalog,
        root_type: Optional[str] = None,
    ) -> None:
        """Binds an extractor to a model / document / catalogue triple.

        *root_type* names the specification document's own root, by type name or
        by section id. Omitted, it defaults to the document's single
        **populated** root — the root under which the document holds any value —
        falling back to the model's only root when the document is empty, so an
        unfilled single-root model still reaches the routing walk.

        Raises :class:`CodeSpecsExtractError` when the root cannot be resolved to
        exactly one: an unknown *root_type*, a *root_type* holding no value while
        another root does, more than one populated root, or an empty document
        over a multi-root model."""
        #: The model describing the document's structure and carrying the
        #: routing verdicts.
        self.model = model
        #: The filled specification document.
        self.document = document
        #: The area catalogue — `codespecs_mapping.md` §4.1/§4.4.3/§4.4.6.
        self.catalog = catalog
        #: The one `@Document` root this extractor walks. Resolved once, here,
        #: so `routings` and `extract_all` cannot disagree about what was
        #: walked.
        self.root = _resolve_root(model, document, root_type)
        self._reflection = SpecReflection(model)

    def routings(self) -> list[CodeSpecsRouting]:
        """The verdict of every class node the walk reaches, in document order.

        Computed by the same walk :meth:`extract_all` uses, so "what was routed
        where" and "what landed in which extract" cannot disagree. Unlike
        :meth:`extract_all` this does **not** raise on an unrouted class — it
        reports it, which is what a diagnostic is for."""
        out: list[CodeSpecsRouting] = []
        self._walk_all(routings=out, entries=None, strict=False)
        return out

    def extract_all(self) -> list[CodeSpecsExtract]:
        """One extract per active area, in catalogue order.

        Raises :class:`CodeSpecsExtractError` on the first class the walk
        reaches that carries none of the three verdicts."""
        entries: list[CodeSpecsExtractEntry] = []
        self._walk_all(routings=None, entries=entries, strict=True)
        root = self._reflection.root_segment(self.root)
        out: list[CodeSpecsExtract] = []
        for area in self.catalog.active_areas:
            out.append(
                CodeSpecsExtract(
                    area=area,
                    catalog_source=self.catalog.source,
                    document_root=root,
                    citable_parts=self.catalog.citable_area_codes(area),
                    projects=self.catalog.projects_for(area),
                    entries=[e for e in entries if e.area_code == area.code],
                )
            )
        return out

    def extract_for(self, area_code: str) -> Optional[CodeSpecsExtract]:
        """The single extract for *area_code*, or ``None`` when the catalogue
        holds no such active area."""
        for e in self.extract_all():
            if e.area.code == area_code:
                return e
        return None

    # --- the walk ------------------------------------------------------------

    def _walk_all(
        self,
        routings: Optional[list[CodeSpecsRouting]],
        entries: Optional[list[CodeSpecsExtractEntry]],
        strict: bool,
    ) -> None:
        self._walk(
            path=self._reflection.root_segment(self.root),
            cls=self.model.class_named(self.root.type),
            ancestor_types={self.root.type},
            routings=routings,
            entries=entries,
            strict=strict,
        )

    def _walk(
        self,
        path: str,
        cls: Optional[SpecClass],
        ancestor_types: set[str],
        routings: Optional[list[CodeSpecsRouting]],
        entries: Optional[list[CodeSpecsExtractEntry]],
        strict: bool,
    ) -> None:
        if cls is None:
            return
        routing = self._verdict_of(cls, path)
        if routings is not None:
            routings.append(routing)

        if routing.verdict is CodeSpecsRoutingVerdict.FEEDS_PROCESS:
            # the whole subtree is delivered by a non-generation process
            return
        if routing.verdict is CodeSpecsRoutingVerdict.UNROUTED and strict:
            raise CodeSpecsExtractError(
                message="section carries none of the three routing verdicts "
                "(@CodeSpecKind / @FollowUpKind / @NoArtifact) — "
                "tom_specs_model_rules.md §10.2 ROUTE-TOTAL",
                path=path,
                class_name=cls.name,
            )

        class_routing = (
            routing
            if routing.verdict is CodeSpecsRoutingVerdict.FEEDS_CODE
            else None
        )

        for f in cls.fields:
            field_path = spec_path_join(path, self._reflection.field_segment(f))
            field_routing = self._field_routing(cls, f) or class_routing

            if f.kind in (
                SpecFieldKind.CONTENT,
                SpecFieldKind.ENUM,
                SpecFieldKind.SCALAR,
            ):
                self._emit_value(
                    entries=entries,
                    routing=field_routing,
                    cls=cls,
                    field=f,
                    path=field_path,
                    form_field=None,
                    value=self.document.content(field_path),
                )
            elif f.kind is SpecFieldKind.FORM:
                for ff in f.form_fields:
                    self._emit_value(
                        entries=entries,
                        routing=field_routing,
                        cls=cls,
                        field=f,
                        path=field_path,
                        form_field=ff.name,
                        value=self.document.form_field(field_path, ff.name),
                    )
            elif f.kind is SpecFieldKind.LIST:
                for item_path in self.document.list_items(field_path):
                    if (
                        f.element_is_complex
                        and f.element_type is not None
                        and f.element_type not in ancestor_types
                    ):
                        self._walk(
                            path=item_path,
                            cls=self.model.class_named(f.element_type),
                            ancestor_types={*ancestor_types, f.element_type},
                            routings=routings,
                            entries=entries,
                            strict=strict,
                        )
                    else:
                        self._emit_value(
                            entries=entries,
                            routing=field_routing,
                            cls=cls,
                            field=f,
                            path=item_path,
                            form_field=None,
                            value=self.document.content(item_path),
                        )
            elif f.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
                if f.type is not None and f.type not in ancestor_types:
                    self._walk(
                        path=field_path,
                        cls=self.model.class_named(f.type),
                        ancestor_types={*ancestor_types, f.type},
                        routings=routings,
                        entries=entries,
                        strict=strict,
                    )

    def _emit_value(
        self,
        entries: Optional[list[CodeSpecsExtractEntry]],
        routing: Optional[CodeSpecsRouting],
        cls: SpecClass,
        field: SpecField,
        path: str,
        form_field: Optional[str],
        value: Optional[str],
    ) -> None:
        """Appends one entry **per area the routing names** — never
        deduplicated, because each area's prompt must be self-sufficient
        (§1.1.1)."""
        if entries is None or routing is None:
            return
        if not value:
            return
        for kind in routing.values:
            area = self.catalog.by_part(kind)
            if area is None or not area.active:
                continue
            entries.append(
                CodeSpecsExtractEntry(
                    area_code=area.code,
                    section_id=self._reflection.field_segment(field),
                    path=path,
                    class_name=cls.name,
                    field_name=field.name,
                    form_field=form_field,
                    routed_by=area.kind_value,
                    routed_at=routing.declared_at,
                    routing_note=routing.note,
                    value=value,
                )
            )

    # --- verdict resolution --------------------------------------------------

    def _verdict_of(self, cls: SpecClass, path: str) -> CodeSpecsRouting:
        """The verdict *cls* carries. The three markers are mutually exclusive
        (``KIND-EXCLUSIVE``), so the order they are tested in is a readability
        choice rather than a precedence rule.

        Read through the model's own :class:`AnnotatedSpecNode` accessors rather
        than off the raw annotation bag: they already know that
        ``@CodeSpecKind``'s list argument is ``kinds`` while ``@FollowUpKind``'s
        is ``processes``, and they strip the enum prefix, so the codes here are
        bare whatever spelling the meta chose. Two readers of the same
        annotations would be two chances to disagree."""
        code = cls.code_spec_kind
        if code is not None:
            return CodeSpecsRouting(
                path=path,
                class_name=cls.name,
                verdict=CodeSpecsRoutingVerdict.FEEDS_CODE,
                values=code.kinds,
                note=code.note,
                declared_at=cls.name,
            )
        follow_up = cls.follow_up_kind
        if follow_up is not None:
            return CodeSpecsRouting(
                path=path,
                class_name=cls.name,
                verdict=CodeSpecsRoutingVerdict.FEEDS_PROCESS,
                values=follow_up.kinds,
                note=follow_up.note,
                declared_at=cls.name,
            )
        none = cls.no_artifact
        if none is not None:
            return CodeSpecsRouting(
                path=path,
                class_name=cls.name,
                verdict=CodeSpecsRoutingVerdict.FEEDS_NOTHING,
                values=[none.reason],
                note=none.note,
                declared_at=cls.name,
            )
        if cls.has_annotation("Document"):
            return CodeSpecsRouting(
                path=path,
                class_name=cls.name,
                verdict=CodeSpecsRoutingVerdict.DOCUMENT_ROOT,
            )
        return CodeSpecsRouting(
            path=path,
            class_name=cls.name,
            verdict=CodeSpecsRoutingVerdict.UNROUTED,
        )

    def _field_routing(
        self, cls: SpecClass, field: SpecField
    ) -> Optional[CodeSpecsRouting]:
        """A field-level ``@CodeSpecKind``, which overrides its class's routing
        for that field alone; ``None`` when the field carries none."""
        code = field.code_spec_kind
        if code is None:
            return None
        return CodeSpecsRouting(
            path="",
            class_name=cls.name,
            verdict=CodeSpecsRoutingVerdict.FEEDS_CODE,
            values=code.kinds,
            note=code.note,
            declared_at=f"{cls.name}.{field.name}",
        )


# --- shared emission helpers ------------------------------------------------


class _Buffer:
    """A tiny StringBuffer with Dart-style ``writeln`` semantics."""

    def __init__(self) -> None:
        self._parts: list[str] = []

    def writeln(self, text: str = "") -> None:
        self._parts.append(text)
        self._parts.append("\n")

    def __str__(self) -> str:
        return "".join(self._parts)


def _string_list(raw: Any) -> list[str]:
    return [str(e) for e in raw] if isinstance(raw, list) else []


def _int_list(raw: Any) -> list[int]:
    return [int(e) for e in raw] if isinstance(raw, list) else []


def _yaml_string(value: str) -> str:
    """A JSON string literal, which is also a valid YAML 1.2 double-quoted
    scalar. Hand-written rather than delegated to ``json.dumps`` so the eight
    ports have one rule to transcribe rather than nine encoders to hope
    agree."""
    b = ['"']
    for ch in value:
        rune = ord(ch)
        if rune == 0x22:
            b.append('\\"')
        elif rune == 0x5C:
            b.append("\\\\")
        elif rune == 0x08:
            b.append("\\b")
        elif rune == 0x0C:
            b.append("\\f")
        elif rune == 0x0A:
            b.append("\\n")
        elif rune == 0x0D:
            b.append("\\r")
        elif rune == 0x09:
            b.append("\\t")
        elif rune < 0x20:
            b.append(f"\\u{rune:04x}")
        else:
            b.append(ch)
    b.append('"')
    return "".join(b)


def _yaml_nullable_string(value: Optional[str]) -> str:
    return "null" if value is None else _yaml_string(value)


def _yaml_string_list(values: list[str]) -> str:
    return f"[{', '.join(_yaml_string(v) for v in values)}]"


def _yaml_int_list(values: list[int]) -> str:
    return f"[{', '.join(str(v) for v in values)}]"


def _md_cell(value: str) -> str:
    """A markdown table cell: newlines folded to a space (a cell cannot hold
    one) and ``|`` escaped. Applied only to catalogue prose, never to a stored
    value — values go into fenced blocks, where they stay verbatim."""
    return value.replace("\n", " ").replace("|", "\\|")


def _md_code_list(values: list[str]) -> str:
    return "—" if not values else ", ".join(f"`{v}`" for v in values)


def _md_int_list(values: list[int]) -> str:
    return "—" if not values else ", ".join(str(v) for v in values)


def _fence_for(value: str) -> str:
    """The shortest backtick fence that cannot be closed by *value*'s own
    content."""
    longest = 0
    run = 0
    for ch in value:
        if ch == "`":
            run += 1
            if run > longest:
                longest = run
        else:
            run = 0
    width = longest + 1 if longest >= 3 else 3
    return "`" * width
