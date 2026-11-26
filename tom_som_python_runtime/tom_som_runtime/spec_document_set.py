"""A project's specification documents read side by side, one per root, and
the validation of the set (`tom_specs_model_rules.md` §9.7): the places a
Phase 3 document shares with the Solution Blueprint agree, element by element
and value by value, and the links that cross two documents hold.

The documents are never assembled into one: each keeps its own registry, and
every finding names the document a place is in. :func:`sync_report` writes
nothing; :func:`rename_id` renames an id in every document at once.

A port of `tom_som_dart_runtime/lib/src/spec_document_set.dart`. The
comparison internals (:class:`SpecSetCheck`, :class:`SpecSetSide`) are public
for :mod:`spec_backfill` and :mod:`spec_prefill`, which read them.
"""

from __future__ import annotations

import functools
import re
from dataclasses import dataclass, field
from typing import Any, Iterable, Optional

from .spec_derive_fields import derive_fields
from .spec_document import SpecDocument
from .spec_links_validator import validate_links
from .spec_meta_bridge import build_som_meta_tree
from .spec_model import FormFieldSpec, SpecClass, SpecFieldKind, SpecModel, SpecSync
from .spec_place import (
    SpecPlace,
    SpecPlaceException,
    SpecPlaceFilter,
    SpecPlaceKind,
    spec_same_as_bindings,
    spec_section_positions,
)
from .spec_reflection import SpecNodeKind, SpecReflection
from .spec_review_annotations import K_SPEC_HEADLINE_FIELD, apply_inline_marks_text
from .spec_section_id import K_SECTION_ID_SLOT, effective_list_item_section_id
from .spec_validator import (
    SpecValidationCode,
    SpecValidationError,
    validate_document,
)

# ---------------------------------------------------------------------------
# The vocabulary of the set
# ---------------------------------------------------------------------------


class SpecSyncCode:
    """What a finding of the set reports (in the order the report sorts by;
    the corpus compares the string values)."""

    #: Both documents hold the shared place, and the values differ.
    SHARED_VALUE_DIFFERS = "sharedValueDiffers"
    #: The Phase 3 document fills a shared place the Blueprint leaves empty.
    SHARED_VALUE_MISSING = "sharedValueMissing"
    #: The Blueprint fills a shared place the Phase 3 document leaves empty;
    #: the Phase 3 document emptied it, so ``backfill`` clears it.
    SHARED_VALUE_ONLY_IN_BLUEPRINT = "sharedValueOnlyInBlueprint"
    #: An element of an ``equal`` list (or an id of an ``equal`` reference
    #: field) is only in the Phase 3 document.
    SHARED_ELEMENT_MISSING = "sharedElementMissing"
    #: An element (or id) is only in the Blueprint, under ``equal`` or
    #: ``subset``; ``backfill`` removes it.
    SHARED_ELEMENT_ONLY_IN_BLUEPRINT = "sharedElementOnlyInBlueprint"
    #: Under ``subset``, an element (or id) only in the Phase 3 document: it
    #: may be added to the Blueprint, and is not carried in.
    SHARED_ELEMENT_MAY_BE_ADDED = "sharedElementMayBeAdded"
    #: A ``@SummaryOf(document:)`` whose summary and detail sit in two
    #: documents does not hold.
    CROSS_SUMMARY_MISMATCH = "crossSummaryMismatch"
    #: An ``inverseOf`` whose two ends sit in two documents is one-sided.
    CROSS_INVERSE_MISSING = "crossInverseMissing"
    #: A value holding pending change marks, listed for the user.
    PENDING_REVIEW = "pendingReview"
    #: A change ``derive_fields`` would write in a document under review that
    #: cannot be marked exactly.
    UNMARKABLE = "unmarkable"

    #: Every code, in declaration order.
    ALL = (
        SHARED_VALUE_DIFFERS,
        SHARED_VALUE_MISSING,
        SHARED_VALUE_ONLY_IN_BLUEPRINT,
        SHARED_ELEMENT_MISSING,
        SHARED_ELEMENT_ONLY_IN_BLUEPRINT,
        SHARED_ELEMENT_MAY_BE_ADDED,
        CROSS_SUMMARY_MISMATCH,
        CROSS_INVERSE_MISSING,
        PENDING_REVIEW,
        UNMARKABLE,
    )


def spec_sync_code_index(code: str) -> int:
    """The position of *code* in the declaration order (-1 when unknown)."""
    try:
        return SpecSyncCode.ALL.index(code)
    except ValueError:
        return -1


class SpecSyncResolution:
    """How a finding of the set is resolved."""

    #: ``backfill`` resolves it, writing the Blueprint.
    BACKFILL = "backfill"
    #: ``derive_fields`` resolves it.
    DERIVE_FIELDS = "deriveFields"
    #: The agent decides (or asks the user).
    AGENT = "agent"
    #: Reported, not a finding: it does not hold up a gate.
    INFO = "info"

    #: Every resolution, in declaration order.
    ALL = (BACKFILL, DERIVE_FIELDS, AGENT, INFO)


class SpecSyncHolder:
    """Which document holds a shared place's value."""

    #: The Phase 3 document (the default).
    DETAIL = "detail"
    #: The Blueprint (``@SyncedWith(heldHere:)``).
    BLUEPRINT = "blueprint"


class SpecDocumentSetRefusal:
    """Why a document set cannot be built."""

    #: Two documents populate one root.
    SAME_ROOT = "sameRoot"
    #: A document populates no root.
    NO_ROOT = "noRoot"
    #: A document populates two roots.
    TWO_ROOTS = "twoRoots"
    #: A document is the CodeSpecs projection, which is no specification.
    PROJECTION = "projection"
    #: Fragments of one root overlap.
    OVERLAP = "overlap"
    #: A synced class's positions in the Blueprint and its document cannot be
    #: paired (invariant ``SHARED-ANCHOR``).
    UNPAIRABLE = "unpairable"


class SpecDocumentSetError(Exception):
    """A document set that cannot be built, with the documents it names."""

    def __init__(
        self,
        refusal: str,
        documents: list[str],
        message: str,
        class_name: Optional[str] = None,
    ) -> None:
        super().__init__(message)
        #: Why (a :class:`SpecDocumentSetRefusal` value).
        self.refusal = refusal
        #: The documents (or fragments) concerned, in the order given.
        self.documents = documents
        #: The message.
        self.message = message
        #: For :attr:`SpecDocumentSetRefusal.UNPAIRABLE`, the class.
        self.class_name = class_name

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form the corpus compares (no message)."""
        out: dict[str, Any] = {"refusal": self.refusal, "documents": list(self.documents)}
        if self.class_name is not None:
            out["className"] = self.class_name
        return out

    def __str__(self) -> str:
        return f"SpecDocumentSetError({self.refusal}): {self.message}"


@dataclass(frozen=True, eq=False)
class SpecSyncPair:
    """A class kept in sync between the Blueprint and a Phase 3 document: its
    position in each root."""

    #: The class carrying ``@SyncedWith`` / ``@DetailedIn``.
    class_name: str
    #: Its section id: the name of the pair in findings and filters.
    section_id: str
    #: The anchor in the Blueprint root (list items written ``<list>-*``).
    blueprint_anchor: str
    #: The anchor in the Phase 3 root.
    detail_anchor: str
    #: The Phase 3 root's class name.
    detail_root: str
    #: The class's ``@SyncedWith``, or ``None`` when only ``@DetailedIn`` is
    #: declared.
    sync: Optional[SpecSync] = None

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "pair": self.section_id,
            "className": self.class_name,
            "blueprint": self.blueprint_anchor,
            "detail": self.detail_anchor,
            "detailRoot": self.detail_root,
        }


def _cmp(a: Any, b: Any) -> int:
    return -1 if a < b else (1 if a > b else 0)


def _file_name(path: str) -> str:
    return path.replace("\\", "/").split("/")[-1]


def _pairs_of(documents: Any) -> list[tuple[str, SpecDocument]]:
    """Name → document, as a mapping or ``(name, document)`` pairs."""
    if documents is None:
        return []
    if isinstance(documents, dict):
        return list(documents.items())
    return [(n, d) for n, d in documents]


# ---------------------------------------------------------------------------
# The set
# ---------------------------------------------------------------------------


class SpecDocumentSet:
    """A project's specification documents, one per root, read side by side."""

    def __init__(self, model: SpecModel, documents: Any = None) -> None:
        """*documents*: name (the file name the tools use) → document, as a
        mapping or ``(name, document)`` pairs. Each document populates exactly
        one root; two documents of one root, a document with no populated root
        or with two, and the CodeSpecs projection are refused with a
        :class:`SpecDocumentSetError` naming the documents, as is a model
        whose synced positions cannot be paired."""
        self._documents: dict[str, SpecDocument] = {}
        self._root_of: dict[str, str] = {}
        #: The model the set is read with.
        self.model = model
        #: The model's reflection.
        self.refl = SpecReflection(model)
        #: The Blueprint's root class name: the root the others are
        #: ``basedOn``.
        self.blueprint_root: Optional[str] = self._compute_blueprint_root()
        self._pairs: list[SpecSyncPair] = self._compute_pairs()
        for name, doc in _pairs_of(documents):
            self.put(name, doc)

    @staticmethod
    def load(model: SpecModel, files: Iterable[str]) -> "SpecDocumentSet":
        """Loads YAML or SOM Markdown files; files of one root are fragments
        and are assembled first (refusing overlaps). Each document is named by
        its first file's name."""
        trees: dict[str, Any] = {}
        fragments: dict[str, SpecDocument] = {}
        for file in files:
            with open(file, "r", encoding="utf-8") as fh:
                text = fh.read()
            if file.endswith(".md"):
                doc = SpecDocument.from_markdown(text, model).document
            else:
                # The root key `<SECTIONID> <Type>:` names the tree to decode
                # with.
                root = None
                for r in model.roots:
                    pattern = (
                        rf"^\s*{re.escape(r.section_id or '')} {re.escape(r.type)}:"
                    )
                    if re.search(pattern, text, re.MULTILINE):
                        root = r
                        break
                if root is None:
                    raise SpecDocumentSetError(
                        SpecDocumentSetRefusal.NO_ROOT,
                        [_file_name(file)],
                        f"{_file_name(file)} names no root of the model",
                    )
                tree = trees.get(root.type)
                if tree is None:
                    tree = build_som_meta_tree(model, root.type)
                    trees[root.type] = tree
                doc = SpecDocument.from_yaml(text, tree)
            fragments[_file_name(file)] = doc
        return SpecDocumentSet.from_fragments(model, fragments)

    @staticmethod
    def from_fragments(model: SpecModel, fragments: Any) -> "SpecDocumentSet":
        """Builds a set from documents and fragments: *fragments* maps a name
        to a document; those of one root are fragments of one document,
        assembled in the order given (overlaps refused), the document named by
        its first fragment's name."""
        refl = SpecReflection(model)
        by_root: dict[str, dict[str, SpecDocument]] = {}
        for name, doc in _pairs_of(fragments):
            roots = SpecDocumentSet._populated_roots(refl, doc)
            if len(roots) != 1:
                raise SpecDocumentSetError(
                    SpecDocumentSetRefusal.NO_ROOT
                    if len(roots) == 0
                    else SpecDocumentSetRefusal.TWO_ROOTS,
                    [name],
                    f"{name} populates "
                    f"{'no root' if len(roots) == 0 else ' and '.join(roots)}",
                )
            by_root.setdefault(roots[0], {})[name] = doc
        documents: dict[str, SpecDocument] = {}
        for group in by_root.values():
            if len(group) == 1:
                documents.update(group)
                continue
            assembly = SpecDocument.assemble(group)
            if not assembly.ok:
                names = list(group.keys())
                raise SpecDocumentSetError(
                    SpecDocumentSetRefusal.OVERLAP,
                    names,
                    f"the fragments {', '.join(names)} overlap",
                )
            documents[next(iter(group))] = assembly.document
        return SpecDocumentSet(model, documents)

    def _compute_blueprint_root(self) -> Optional[str]:
        targets: dict[str, None] = {}
        for r in self.model.roots:
            cls = self.refl.class_named(r.type)
            doc = cls.annotation("Document") if cls is not None else None
            based = doc.argument("basedOn") if doc is not None else None
            if isinstance(based, list):
                for e in based:
                    targets[f"{e}"] = None
        return next(iter(targets)) if len(targets) == 1 else None

    @property
    def blueprint(self) -> Optional[SpecDocument]:
        """The D00SolutionBlueprint document (the Blueprint), or ``None``."""
        return None if self.blueprint_root is None else self.document(self.blueprint_root)

    def document(self, root_type: str) -> Optional[SpecDocument]:
        """The document of *root_type* (a type name or a section id), or
        ``None``."""
        name = self.name_of(root_type)
        return None if name is None else self._documents.get(name)

    def name_of(self, root_type: Optional[str]) -> Optional[str]:
        """The name of the document of *root_type*, or ``None``."""
        t = self._type_of(root_type)
        for name, root in self._root_of.items():
            if root == t:
                return name
        return None

    def _type_of(self, root_type: Optional[str]) -> Optional[str]:
        for r in self.model.roots:
            if r.type == root_type or r.section_id == root_type:
                return r.type
        return None

    def _has_root(self, t: str) -> bool:
        return t in self._root_of.values()

    @property
    def roots(self) -> list[str]:
        """The populated roots, in model order."""
        return [r.type for r in self.model.roots if self._has_root(r.type)]

    @property
    def names(self) -> list[str]:
        """The document names, in model order of their roots."""
        return [self.name_of(r) for r in self.roots]  # type: ignore[misc]

    @property
    def missing_roots(self) -> list[str]:
        """Every Phase 3 root a pair names with no document yet: its pairs are
        "not started", reported as such and never as findings."""
        return [
            r.type
            for r in self.model.roots
            if any(p.detail_root == r.type for p in self._pairs)
            and not self._has_root(r.type)
        ]

    @property
    def pairs(self) -> list[SpecSyncPair]:
        """The anchor pairs, in the Blueprint's walk order."""
        return self._pairs

    def put(self, name: str, document: SpecDocument) -> None:
        """Adds or replaces a document (what ``prefill`` creates)."""
        roots = SpecDocumentSet._populated_roots(self.refl, document)
        if len(roots) == 0:
            raise SpecDocumentSetError(
                SpecDocumentSetRefusal.NO_ROOT, [name], f"{name} populates no root"
            )
        if len(roots) > 1:
            raise SpecDocumentSetError(
                SpecDocumentSetRefusal.TWO_ROOTS,
                [name],
                f"{name} populates {' and '.join(roots)}",
            )
        root = roots[0]
        cls = self.refl.class_named(root)
        if cls is not None and cls.is_code_specs_projection:
            raise SpecDocumentSetError(
                SpecDocumentSetRefusal.PROJECTION,
                [name],
                f"{name} is the CodeSpecs projection, which is no specification",
            )
        for other, r in self._root_of.items():
            if r == root and other != name:
                raise SpecDocumentSetError(
                    SpecDocumentSetRefusal.SAME_ROOT,
                    [other, name],
                    f"{other} and {name} both populate {root}",
                )
        self._documents[name] = document
        self._root_of[name] = root

    def get(self, name: str) -> Optional[SpecDocument]:
        """The document named *name* (Dart's ``operator []``)."""
        return self._documents.get(name)

    def __getitem__(self, name: str) -> Optional[SpecDocument]:
        return self._documents.get(name)

    def root_of(self, name: str) -> Optional[str]:
        """The root class name of the document named *name*."""
        return self._root_of.get(name)

    @staticmethod
    def _populated_roots(refl: SpecReflection, doc: SpecDocument) -> list[str]:
        segs: set[str] = set()
        for paths in (doc.content_paths, doc.form_paths, doc.list_paths, doc.headline_paths):
            for p in paths:
                slash = p.find("/")
                segs.add(p if slash < 0 else p[:slash])
        return [r.type for r in refl.model.roots if refl.root_segment(r) in segs]

    # -------------------------------------------------------------------------
    # The anchor pairs
    # -------------------------------------------------------------------------

    def _compute_pairs(self) -> list[SpecSyncPair]:
        bp = self.blueprint_root
        if bp is None:
            return []
        refl = self.refl
        positions: dict[str, list[Any]] = {}

        def at(root: str) -> list[Any]:
            hit = positions.get(root)
            if hit is None:
                every = spec_section_positions(refl, root)
                # A `@SameAs` copy is kept equal to its holder, never paired.
                copies = [
                    p.path
                    for p in every
                    if not p.is_member and p.member is not None and p.member.same_as is not None
                ]
                hit = [
                    p
                    for p in every
                    if not p.is_member
                    and not any(p.path == c or p.path.startswith(f"{c}/") for c in copies)
                ]
                positions[root] = hit
            return hit

        candidates: dict[str, str] = {}  # class -> target root
        for p in at(bp):
            cls = refl.class_named(p.class_name)
            sync = cls.synced_with if cls is not None else None
            target = (
                sync.document
                if sync is not None
                else (cls.detailed_in if cls is not None else None)
            )
            if target is None or target == bp:
                continue
            if refl.class_named(target) is None:
                continue
            if p.class_name not in candidates:
                candidates[p.class_name] = target

        out: list[SpecSyncPair] = []
        for class_name, target in candidates.items():
            mine = [p for p in at(bp) if p.class_name == class_name]
            theirs = [p for p in at(target) if p.class_name == class_name]
            if len(theirs) == 0:
                continue
            matched: list[tuple[Any, Any]] = []
            if len(mine) == 1 and len(theirs) == 1:
                matched.append((mine[0], theirs[0]))
            else:
                # Paired by the path below the nearest enclosing anchor.
                def key(p: Any, root: str) -> str:
                    outer = None
                    for q in at(root):
                        if q.path == p.path or not p.path.startswith(f"{q.path}/"):
                            continue
                        if q.class_name not in candidates:
                            continue
                        if outer is None or len(q.path) > len(outer.path):
                            outer = q
                    ids = (
                        list(p.section_ids)
                        if outer is None
                        else list(p.section_ids)[len(outer.section_ids):]
                    )
                    return f"{outer.class_name if outer is not None else ''}/{'/'.join(ids)}"

                by_key: dict[str, Any] = {}
                for p in theirs:
                    k = key(p, target)
                    if k in by_key:
                        self._unpairable(class_name)
                    by_key[k] = p
                for p in mine:
                    k = key(p, bp)
                    q = by_key.get(k)
                    if q is None:
                        self._unpairable(class_name)
                    by_key.pop(k, None)
                    matched.append((p, q))
                if len(by_key) > 0:
                    self._unpairable(class_name)
            cls = refl.class_named(class_name)
            assert cls is not None
            for b, d in matched:
                out.append(
                    SpecSyncPair(
                        class_name=class_name,
                        section_id=cls.section_id or class_name,
                        blueprint_anchor=b.path,
                        detail_anchor=d.path,
                        detail_root=target,
                        sync=cls.synced_with,
                    )
                )
        return out

    def _unpairable(self, class_name: str) -> None:
        raise SpecDocumentSetError(
            SpecDocumentSetRefusal.UNPAIRABLE,
            [],
            f"the positions of {class_name} in the Blueprint and its document "
            "cannot be paired (SHARED-ANCHOR)",
            class_name,
        )


# ---------------------------------------------------------------------------
# Findings and the report
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class SpecSyncPlace:
    """One side of a finding: where the place is and what it holds."""

    #: The document's name, or ``None`` when the set has none for this side.
    document: Optional[str]
    #: The root's section id.
    root: str
    #: The document path (for a place the document does not hold, the nearest
    #: path it does: the list an element would be added to).
    path: str
    #: The form field, or ``None``.
    field: Optional[str] = None
    #: The value (read with pending marks rejected), or ``None`` when absent.
    value: Optional[str] = None
    #: Whether the value holds pending change marks.
    pending_marks: bool = False

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        out: dict[str, Any] = {"document": self.document, "root": self.root, "path": self.path}
        if self.field is not None:
            out["field"] = self.field
        if self.value is not None:
            out["value"] = self.value
        out["pendingMarks"] = self.pending_marks
        return out


@dataclass(frozen=True)
class SpecSyncFinding:
    """One finding of the set."""

    #: What it reports (a :class:`SpecSyncCode` value).
    code: str
    #: The pair's section id (the summary's or link's class for a cross
    #: check, empty for a pending value outside every pair).
    pair: str
    #: The Blueprint side (for a cross check, the side holding the link).
    blueprint: SpecSyncPlace
    #: The Phase 3 side (for a cross check, the other end).
    detail: SpecSyncPlace
    #: Which side holds the value (a :class:`SpecSyncHolder` value).
    holder: str
    #: How it is resolved (a :class:`SpecSyncResolution` value).
    resolution: str
    #: Prose for the agent, in the canonical form: every runtime writes the
    #: same sentence (the conformance corpus compares it).
    message: str

    @property
    def is_info(self) -> bool:
        """Whether it is reported only, not a finding."""
        return self.resolution == SpecSyncResolution.INFO

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        return {
            "code": self.code,
            "pair": self.pair,
            "blueprint": self.blueprint.to_json(),
            "detail": self.detail.to_json(),
            "holder": self.holder,
            "resolution": self.resolution,
            "message": self.message,
            "info": self.is_info,
        }


@dataclass
class SpecSyncReport:
    """The validation of a document set."""

    #: The findings in pair and path order, ``info`` entries included.
    findings: list[SpecSyncFinding]
    #: Each document's own findings (``validate_document``, then
    #: ``validate_links``), by name, in the set's order.
    document_findings: dict[str, list[SpecValidationError]]
    #: The Phase 3 roots with no document yet.
    not_started: list[str]
    #: The pairs (by section id) whose Phase 3 document exists but holds
    #: nothing beneath the pair's anchor: not started, like a missing document.
    not_started_pairs: list[str] = field(default_factory=list)

    def counts_by_code(self) -> dict[str, int]:
        """Findings per code, ``info`` entries included, in code order."""
        out: dict[str, int] = {}
        for c in SpecSyncCode.ALL:
            n = sum(1 for f in self.findings if f.code == c)
            if n > 0:
                out[c] = n
        return out

    def counts_by_resolution(self) -> dict[str, int]:
        """Findings per resolution, in resolution order."""
        out: dict[str, int] = {}
        for r in SpecSyncResolution.ALL:
            n = sum(1 for f in self.findings if f.resolution == r)
            if n > 0:
                out[r] = n
        return out

    @property
    def clean(self) -> bool:
        """No finding other than ``info``."""
        return all(f.is_info for f in self.findings)

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form; every ordered value is a list."""
        return {
            "findings": [f.to_json() for f in self.findings],
            "documentFindings": [
                [
                    name,
                    [
                        {"path": x.path, "code": x.code.value, "message": x.message}
                        for x in errors
                    ],
                ]
                for name, errors in self.document_findings.items()
            ],
            "notStarted": list(self.not_started),
            "notStartedPairs": list(self.not_started_pairs),
            "countsByCode": [[k, v] for k, v in self.counts_by_code().items()],
            "countsByResolution": [[k, v] for k, v in self.counts_by_resolution().items()],
            "clean": self.clean,
        }


def sync_report(
    doc_set: SpecDocumentSet, pairs: Optional[Iterable[str]] = None
) -> SpecSyncReport:
    """The validation of *doc_set*, with counts; *pairs* keeps the findings of
    those pairs (by section id) only. Writes nothing."""
    scope = set(pairs) if pairs is not None else None
    c = SpecSetCheck(doc_set)
    index = 0
    for p in doc_set.pairs:
        if scope is None or p.section_id in scope:
            c.compare_pair(p, index)
        index += 1
    c.cross_checks(scope, index)
    if scope is None:
        c.pending_scan(index + 1)
        c.unmarkable_scan(index + 2)
    c.sort_out()
    document_findings: dict[str, list[SpecValidationError]] = {}
    for name in doc_set.names:
        doc = doc_set.get(name)
        assert doc is not None
        document_findings[name] = validate_document(doc_set.model, doc) + validate_links(
            doc_set.model, doc
        )
    return SpecSyncReport(
        findings=[o.finding for o in c.out],
        document_findings=document_findings,
        not_started=doc_set.missing_roots,
        not_started_pairs=c.not_started_pairs,
    )


# ---------------------------------------------------------------------------
# The comparison
# ---------------------------------------------------------------------------


@dataclass
class SpecSetFound:
    """A finding with its sort keys (and, for a pair's finding, its two
    sides)."""

    order: int
    key: str
    finding: SpecSyncFinding
    b: Optional["SpecSetSide"] = None
    d: Optional["SpecSetSide"] = None


@dataclass
class SpecSetValue:
    """One value of a subtree, keyed for comparison."""

    path: str
    field: Optional[str]
    value: str
    pending: bool
    spec: Optional[FormFieldSpec]


class SpecSetSide:
    """A document side of a pair: its subtree's values and items, keyed by
    the path below the anchor with list items written by their section id."""

    def __init__(self, name: str, root: str, anchor: str) -> None:
        self.name = name
        self.root = root
        self.anchor = anchor
        self.values: dict[str, SpecSetValue] = {}
        #: item key -> item path, and the anchor's own key ''.
        self.items: dict[str, str] = {}


@dataclass
class _Places:
    """The places a set of place texts stands for under an anchor."""

    prefixes: list[str]
    fields: set[str]
    headlines: set[str]


_FLOAT_TEXT = re.compile(r"^[+-]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?$", re.IGNORECASE)
_HEX_TEXT = re.compile(r"^[+-]?0x[0-9a-f]+$", re.IGNORECASE)
_SPECIAL_TEXT = re.compile(r"^[+-]?(Infinity|NaN)$")
_ITEM_ID_BRACKETS = re.compile(r"\[[^\]]*\]")


def _num_try_parse(text: str) -> Optional[float]:
    """Dart's ``num.tryParse``: decimal, hex, ``Infinity`` and ``NaN``."""
    t = text.strip()
    if _FLOAT_TEXT.match(t):
        return float(t)
    if _HEX_TEXT.match(t):
        neg = t.startswith("-")
        v = int(t.lstrip("+-"), 16)
        return float(-v if neg else v)
    if _SPECIAL_TEXT.match(t):
        return float(t.replace("Infinity", "inf"))
    return None


def _under_any(path: str, prefixes: Iterable[str]) -> bool:
    for p in prefixes:
        if path == p or path.startswith(f"{p}/"):
            return True
    return False


class SpecSetCheck:
    """The comparison behind :func:`sync_report` (and ``backfill``,
    ``prefill`` and :func:`rename_id`): one per run, with its caches."""

    def __init__(self, doc_set: SpecDocumentSet) -> None:
        self.set = doc_set
        self.refl = doc_set.refl
        self.out: list[SpecSetFound] = []
        #: The pairs whose Phase 3 document exists but holds nothing beneath
        #: the pair's anchor.
        self.not_started_pairs: list[str] = []
        self._item_ids: dict[int, dict[str, str]] = {}
        self._items: dict[str, bool] = {}
        self._forms: dict[int, dict[str, list[str]]] = {}
        self._registry_docs: dict[Optional[str], Optional[str]] = {}
        self._reach: dict[str, set[str]] = {}
        self._entries: dict[int, dict[str, dict[str, str]]] = {}
        self._same_as: dict[str, list[Any]] = {}

    def add(
        self,
        order: int,
        key: str,
        finding: SpecSyncFinding,
        b: Optional[SpecSetSide] = None,
        d: Optional[SpecSetSide] = None,
    ) -> None:
        self.out.append(SpecSetFound(order=order, key=key, finding=finding, b=b, d=d))

    def sort_out(self) -> None:
        """Sorts :attr:`out` as the report lists it."""

        def compare(a: SpecSetFound, b: SpecSetFound) -> int:
            if a.order != b.order:
                return a.order - b.order
            k = _cmp(a.key, b.key)
            if k != 0:
                return k
            x = spec_sync_code_index(a.finding.code) - spec_sync_code_index(b.finding.code)
            if x != 0:
                return x
            av = a.finding.blueprint.value
            if av is None:
                av = a.finding.detail.value
            bv = b.finding.blueprint.value
            if bv is None:
                bv = b.finding.detail.value
            return _cmp(av if av is not None else "", bv if bv is not None else "")

        self.out.sort(key=functools.cmp_to_key(compare))

    def root_seg(self, type_name: Optional[str]) -> str:
        for r in self.refl.model.roots:
            if r.type == type_name:
                return self.refl.root_segment(r)
        raise ValueError(f"no root {type_name}")

    # --- values -------------------------------------------------------------

    @staticmethod
    def reviewed(raw: str) -> str:
        """*raw* with every pending mark rejected, trimmed."""
        return apply_inline_marks_text(raw, accept=False).strip()

    @staticmethod
    def is_pending(raw: str) -> bool:
        """Whether *raw* holds pending change marks."""
        return apply_inline_marks_text(raw, accept=True) != apply_inline_marks_text(
            raw, accept=False
        )

    def item_id(self, doc: SpecDocument, item_path: str) -> str:
        """The effective section id of the list item at *item_path* in
        *doc*."""
        by_doc = self._item_ids.setdefault(id(doc), {})
        hit = by_doc.get(item_path)
        if hit is None:
            hit = self._compute_item_id(doc, item_path)
            by_doc[item_path] = hit
        return hit

    def _compute_item_id(self, doc: SpecDocument, item_path: str) -> str:
        stored = doc.item_section_id(item_path)
        if stored is not None:
            return stored
        lst = item_path[: item_path.rfind("-")]
        res = self.refl.resolve(lst)
        f = res.field if res is not None else None
        items = doc.list_items(lst)
        return effective_list_item_section_id(
            None,
            f.section_id_pattern if f is not None else None,
            (items.index(item_path) if item_path in items else -1) + 1,
            f.name if f is not None else lst.split("/")[-1],
        )

    def is_item(self, path: str) -> bool:
        """Whether *path* is a list item (complex or scalar)."""
        hit = self._items.get(path)
        if hit is None:
            # A scalar list's items are elements too, keyed by their effective
            # id like a complex list's (`LIST[ID]`).
            r = self.refl.resolve(path)
            hit = r is not None and r.kind in (
                SpecNodeKind.LIST_ITEM_COMPLEX,
                SpecNodeKind.LIST_ITEM_SCALAR,
            )
            self._items[path] = hit
        return hit

    def expand(self, doc: SpecDocument, pattern: str) -> list[str]:
        """The concrete paths a pattern (list items ``<list>-*``) stands for
        in *doc*."""
        paths = [""]
        for seg in pattern.split("/"):
            nxt: list[str] = []
            for p in paths:
                base = seg if p == "" else f"{p}/{seg}"
                if seg.endswith("-*"):
                    nxt.extend(doc.list_items(base[:-2]))
                else:
                    nxt.append(base)
            paths = nxt
        return paths

    def key(self, doc: SpecDocument, anchor: str, path: str) -> str:
        """The key of *path* below *anchor*: item segments as ``LIST[id]``."""
        if path == anchor:
            return ""
        out: list[str] = []
        at = anchor
        for seg in path[len(anchor) + 1:].split("/"):
            at = f"{at}/{seg}"
            out.append(
                f"{seg[: seg.rfind('-')]}[{self.item_id(doc, at)}]" if self.is_item(at) else seg
            )
        return "/".join(out)

    def anchor_key(self, doc: SpecDocument, path: str) -> str:
        """The key of an anchor itself among its siblings: the ids of the list
        items on its path."""
        out: list[str] = []
        at = ""
        for seg in path.split("/"):
            at = seg if at == "" else f"{at}/{seg}"
            if self.is_item(at):
                out.append(self.item_id(doc, at))
        return "/".join(out)

    def places(self, doc: SpecDocument, places: Iterable[str], anchor: str) -> _Places:
        """The paths a place resolved under *anchor* stands for in *doc*:
        whole sections (prefixes) and single form fields."""
        prefixes: list[str] = []
        fields: set[str] = set()
        headlines: set[str] = set()
        for text in places:
            try:
                r = SpecPlace.parse(text).resolve(self.refl, anchor)
            except SpecPlaceException:
                continue
            for p in self.expand(doc, r.path):
                if r.kind == SpecPlaceKind.FORM_FIELD:
                    fields.add(f"{p}#{r.field}")
                elif r.kind == SpecPlaceKind.HEADLINE:
                    headlines.add(p)
                elif r.kind == SpecPlaceKind.SECTION_ID:
                    pass
                else:
                    prefixes.append(p)
        return _Places(prefixes=prefixes, fields=fields, headlines=headlines)

    @staticmethod
    def under_any(path: str, prefixes: Iterable[str]) -> bool:
        """Whether *path* is one of *prefixes* or beneath one."""
        return _under_any(path, prefixes)

    def collect(
        self,
        name: str,
        doc: SpecDocument,
        root: str,
        anchor: str,
        pair: SpecSyncPair,
        nested: list[str],
    ) -> SpecSetSide:
        """The values beneath *anchor* in *doc*, with what the pair does not
        compare left out: ``detailOnly`` places, nested pairs, ``@SameAs``
        copies and derived places."""
        refl = self.refl
        side = SpecSetSide(name, root, anchor)
        skip = self.places(doc, pair.sync.detail_only if pair.sync is not None else [], anchor)
        bindings = self._same_as.get(root)
        if bindings is None:
            bindings = spec_same_as_bindings(refl, root)
            self._same_as[root] = bindings
        excluded: list[str] = list(skip.prefixes) + list(nested)
        for b in bindings:
            excluded.extend(self.expand(doc, b.copy_path))

        def under(p: str) -> bool:
            return p == anchor or p.startswith(f"{anchor}/")

        def outside(p: str) -> bool:
            return p != anchor and _under_any(p, excluded)

        # The values a summary row repeats are derived from its detail element
        # (`@SummaryOf` repeats): never shared, like every derived place.
        for lst in list(doc.list_paths):
            if not under(lst):
                continue
            res = refl.resolve(lst)
            s = res.field.summary_of if res is not None and res.field is not None else None
            repeats = list(s.repeats.keys()) if s is not None else []
            if len(repeats) == 0:
                continue
            for item in doc.list_items(lst):
                r = self.places(doc, repeats, item)
                excluded.extend(r.prefixes)
                skip.fields.update(r.fields)
                skip.headlines.update(r.headlines)

        side.items[""] = anchor
        for lst in list(doc.list_paths):
            if not under(lst) or outside(lst):
                continue
            res = refl.resolve(lst)
            if res is not None and res.field is not None and res.field.derived_from is not None:
                excluded.append(lst)
                continue
            for item in doc.list_items(lst):
                side.items[self.key(doc, anchor, item)] = item
        for p in list(doc.content_paths):
            if not under(p) or outside(p):
                continue
            res = refl.resolve(p)
            if res is not None and res.field is not None and res.field.derived_from is not None:
                continue
            raw = doc.content(p) or ""
            side.values[f"c:{self.key(doc, anchor, p)}"] = SpecSetValue(
                path=p,
                field=None,
                value=SpecSetCheck.reviewed(raw),
                pending=SpecSetCheck.is_pending(raw),
                spec=None,
            )
        for p in list(doc.form_paths):
            if not under(p) or outside(p):
                continue
            res = refl.resolve(p)
            specs = res.field.form_fields if res is not None and res.field is not None else []
            for fname in list(doc.form_field_names(p)):
                if f"{p}#{fname}" in skip.fields:
                    continue
                spec = next((f for f in specs if f.name == fname), None)
                if spec is not None and (
                    spec.derived_from is not None
                    or len(spec.count_of) > 0
                    or len(spec.product_of) > 0
                    or spec.rank_of is not None
                ):
                    continue
                raw = doc.form_field(p, fname) or ""
                side.values[f"f:{self.key(doc, anchor, p)}#{fname}"] = SpecSetValue(
                    path=p,
                    field=fname,
                    value=SpecSetCheck.reviewed(raw),
                    pending=SpecSetCheck.is_pending(raw),
                    spec=spec,
                )
        for p in list(doc.headline_paths):
            if not under(p) or outside(p) or p in skip.headlines:
                continue
            raw = doc.headline(p) or ""
            side.values[f"h:{self.key(doc, anchor, p)}"] = SpecSetValue(
                path=p,
                field=K_SPEC_HEADLINE_FIELD,
                value=SpecSetCheck.reviewed(raw),
                pending=SpecSetCheck.is_pending(raw),
                spec=None,
            )
        return side

    def path_on(self, side: SpecSetSide, key: str) -> str:
        """The path *key* stands for on *side*: the item paths it names as far
        as the side holds them; where it stops, the list an element would go
        in."""
        if key == "":
            return side.anchor
        path = side.anchor
        prefix = ""
        for s in key.split("/"):
            prefix = s if prefix == "" else f"{prefix}/{s}"
            bracket = s.find("[")
            if bracket > 0:
                item = side.items.get(prefix)
                if item is None:
                    return f"{path}/{s[:bracket]}"
                path = item
            else:
                path = f"{path}/{s}"
        return path

    @staticmethod
    def same_typed(a: str, b: str, spec: Optional[FormFieldSpec]) -> bool:
        """Whether *a* and *b* are the same value of the field's type."""
        t = spec.type if spec is not None else None
        if t in ("int", "double", "num"):
            x = _num_try_parse(a)
            y = _num_try_parse(b)
            if x is not None and y is not None:
                return x == y
        if t == "bool":
            return a.lower() == b.lower()
        return a == b

    @staticmethod
    def ids(value: str) -> list[str]:
        """The comma-separated ids of *value*, trimmed, empty ones dropped."""
        return [s.strip() for s in value.split(",") if s.strip() != ""]

    # --- one pair -----------------------------------------------------------

    def compare_pair(self, pair: SpecSyncPair, order: int) -> None:
        """Compares one pair, adding its findings at *order*."""
        doc_set = self.set
        bp_name = doc_set.name_of(doc_set.blueprint_root)
        dt_name = doc_set.name_of(pair.detail_root)
        if bp_name is None or dt_name is None:
            return  # not started
        bp = doc_set.get(bp_name)
        dt = doc_set.get(dt_name)
        assert bp is not None and dt is not None
        bp_root = doc_set.blueprint_root
        assert bp_root is not None

        # Nested pairs are compared on their own.
        def nested(doc: SpecDocument, blueprint_side: bool) -> list[str]:
            out: list[str] = []
            for other in doc_set.pairs:
                if other is not pair and (blueprint_side or other.detail_root == pair.detail_root):
                    out.extend(
                        self.expand(
                            doc, other.blueprint_anchor if blueprint_side else other.detail_anchor
                        )
                    )
            return out

        bp_anchors: dict[str, str] = {}
        for a in self.expand(bp, pair.blueprint_anchor):
            bp_anchors[self.anchor_key(bp, a)] = a
        dt_anchors: dict[str, str] = {}
        for a in self.expand(dt, pair.detail_anchor):
            dt_anchors[self.anchor_key(dt, a)] = a
        # A pair the Phase 3 document has not written yet is not started,
        # never findings: it is what prefill fills, and backfill must not take
        # its emptiness for removals.
        if not any(dt.has_values_under(a) for a in dt_anchors.values()):
            self.not_started_pairs.append(pair.section_id)
            return
        bp_nested: Optional[list[str]] = None
        dt_nested: Optional[list[str]] = None
        keys: dict[str, None] = dict.fromkeys(list(bp_anchors) + list(dt_anchors))
        for k in keys:
            ba = bp_anchors.get(k)
            da = dt_anchors.get(k)
            if ba is None or da is None:
                continue  # the outer list reports it
            if bp_nested is None or dt_nested is None:
                bp_nested = nested(bp, True)
                dt_nested = nested(dt, False)
            b = self.collect(
                bp_name, bp, bp_root, ba, pair, [p for p in bp_nested if p.startswith(f"{ba}/")]
            )
            d = self.collect(
                dt_name,
                dt,
                pair.detail_root,
                da,
                pair,
                [p for p in dt_nested if p.startswith(f"{da}/")],
            )
            self._compare(pair, order, b, d, bp, dt)

    def _compare(
        self,
        pair: SpecSyncPair,
        order: int,
        b: SpecSetSide,
        d: SpecSetSide,
        bp: SpecDocument,
        dt: SpecDocument,
    ) -> None:
        refl = self.refl
        sync = pair.sync
        # Relations: list key -> (relation, where); field key -> relation.
        list_rel: dict[str, tuple[str, Optional[str]]] = {}
        field_rel: dict[str, str] = {}
        relations = sync.relations if sync is not None else []
        for r in relations:
            try:
                res = SpecPlace.parse(r.place).resolve(refl, b.anchor)
            except SpecPlaceException:
                continue
            for p in self.expand(bp, res.path):
                key = self.key(bp, b.anchor, p)
                if res.kind == SpecPlaceKind.LIST:
                    list_rel[key] = (r.relation, r.where)
                elif res.kind == SpecPlaceKind.FORM_FIELD:
                    field_rel[f"{key}#{res.field}"] = r.relation

        # A relation stated for a form field is the same for every element:
        # match it by its key with item ids dropped.
        def shape(key: str) -> str:
            return _ITEM_ID_BRACKETS.sub("[]", key)

        field_rel_by_shape: dict[str, str] = {}
        for k, v in field_rel.items():
            field_rel_by_shape[shape(k)] = v
        held = self.places(bp, sync.held_here if sync is not None else [], b.anchor)

        def is_held(bp_path: str, fld: Optional[str] = None) -> bool:
            return _under_any(bp_path, held.prefixes) or (
                fld is not None and f"{bp_path}#{fld}" in held.fields
            )

        def place(
            s: SpecSetSide, key: str, fld: Optional[str], value: Optional[str]
        ) -> SpecSyncPlace:
            v = s.values.get(key)
            return SpecSyncPlace(
                document=s.name,
                root=self.root_seg(s.root),
                path=(
                    v.path
                    if v is not None
                    else self.path_on(
                        s, key[2:] if key.startswith("i:") else SpecSetCheck.strip_kind(key)
                    )
                ),
                field=fld if fld is not None else (v.field if v is not None else None),
                value=value if value is not None else (v.value if v is not None else None),
                pending_marks=v.pending if v is not None else False,
            )

        def emit(
            code: str,
            key: str,
            message: str,
            held_here: bool,
            fld: Optional[str] = None,
            b_value: Optional[str] = None,
            d_value: Optional[str] = None,
            resolution: Optional[str] = None,
        ) -> None:
            self.add(
                order,
                key,
                SpecSyncFinding(
                    code=code,
                    pair=pair.section_id,
                    blueprint=place(b, key, fld, b_value),
                    detail=place(d, key, fld, d_value),
                    holder=SpecSyncHolder.BLUEPRINT if held_here else SpecSyncHolder.DETAIL,
                    resolution=(
                        resolution
                        if resolution is not None
                        else (
                            SpecSyncResolution.AGENT
                            if held_here
                            else SpecSyncResolution.BACKFILL
                        )
                    ),
                    message=message,
                ),
                b=b,
                d=d,
            )

        # Elements.
        one_sided: list[str] = []
        item_keys = sorted(set(b.items) | set(d.items))
        for k in item_keys:
            if k == "":
                continue
            in_b = k in b.items
            in_d = k in d.items
            if in_b == in_d:
                continue
            if any(k.startswith(f"{o}/") for o in one_sided):
                continue
            one_sided.append(k)
            # `LIST[ID]` (every item key, `key`); a key without the brackets
            # names its element by its last segment.
            bracket = k.rfind("[")
            if bracket < 0:
                parent_list = k[: k.rfind("/")] if "/" in k else ""
            else:
                parent_list = k[:bracket]
            rel = list_rel.get(parent_list)
            relation = rel[0] if rel is not None else "equal"
            item_path = b.items[k] if in_b else d.items[k]
            doc = bp if in_b else dt
            if rel is not None and rel[1] is not None:
                flt = SpecPlaceFilter.try_parse(rel[1])
                if (
                    flt is not None
                    and flt.field is not None
                    and not flt.matches(self.own_values(doc, item_path, flt.field))
                ):
                    relation = "equal"
            id_ = k.split("/")[-1] if bracket < 0 else k[bracket + 1: len(k) - 1]
            held_here = is_held(item_path if in_b else self.path_on(b, k))
            key = f"i:{k}"
            if in_d:
                if relation == "subset":
                    emit(
                        SpecSyncCode.SHARED_ELEMENT_MAY_BE_ADDED,
                        key,
                        f"{id_} is only in {d.name}; under subset it may be added to {b.name}",
                        held_here,
                        d_value=id_,
                        resolution=SpecSyncResolution.INFO,
                    )
                else:
                    emit(
                        SpecSyncCode.SHARED_ELEMENT_MISSING,
                        key,
                        f"{id_} is in {d.name} and missing in {b.name}",
                        held_here,
                        d_value=id_,
                    )
            elif relation != "superset":
                emit(
                    SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT,
                    key,
                    f"{id_} is only in {b.name}; {d.name} removed it",
                    held_here,
                    b_value=id_,
                )

        def beneath_one_sided(key: str) -> bool:
            rel = SpecSetCheck.strip_kind(key)
            return any(rel == o or rel.startswith(f"{o}/") for o in one_sided)

        # Values.
        keys = sorted(set(b.values) | set(d.values))
        for k in keys:
            if beneath_one_sided(k):
                continue
            vb = b.values.get(k)
            vd = d.values.get(k)
            spec = vb.spec if vb is not None else None
            if spec is None and vd is not None:
                spec = vd.spec
            fld = vb.field if vb is not None else None
            if fld is None and vd is not None:
                fld = vd.field
            b_value = vb.value if vb is not None else ""
            d_value = vd.value if vd is not None else ""
            held_here = is_held(
                vb.path if vb is not None else self.path_on(b, SpecSetCheck.strip_kind(k)), fld
            )
            if spec is not None and spec.multiple and len(spec.refers_to) > 0:
                relation = field_rel_by_shape.get(shape(k[2:]), "equal")
                ib = SpecSetCheck.ids(b_value)
                idd = SpecSetCheck.ids(d_value)
                for x in sorted(set(x for x in idd if x not in ib)):
                    may = relation == "subset"
                    emit(
                        SpecSyncCode.SHARED_ELEMENT_MAY_BE_ADDED
                        if may
                        else SpecSyncCode.SHARED_ELEMENT_MISSING,
                        k,
                        f"{x} is named in {d.name} and not in {b.name}",
                        held_here,
                        fld=fld,
                        d_value=x,
                        b_value=None if b_value == "" else b_value,
                        resolution=SpecSyncResolution.INFO if may else None,
                    )
                if relation != "superset":
                    for x in sorted(set(x for x in ib if x not in idd)):
                        emit(
                            SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT,
                            k,
                            f"{x} is named only in {b.name}",
                            held_here,
                            fld=fld,
                            b_value=x,
                            d_value=None if d_value == "" else d_value,
                        )
                continue
            if b_value == "" and d_value == "":
                continue
            if SpecSetCheck.same_typed(b_value, d_value, spec):
                continue
            what = "the value" if fld is None else f'form field "{fld}"'
            if b_value == "":
                emit(
                    SpecSyncCode.SHARED_VALUE_MISSING,
                    k,
                    f"{what} is filled in {d.name} and empty in {b.name}",
                    held_here,
                    fld=fld,
                )
            elif d_value == "":
                emit(
                    SpecSyncCode.SHARED_VALUE_ONLY_IN_BLUEPRINT,
                    k,
                    f"{what} is filled only in {b.name}; {d.name} emptied it",
                    held_here,
                    fld=fld,
                )
            else:
                emit(
                    SpecSyncCode.SHARED_VALUE_DIFFERS,
                    k,
                    f'{what} differs: "{b_value}" in {b.name}, "{d_value}" in {d.name}'
                    + (f" (held in {b.name})" if held_here else ""),
                    held_here,
                    fld=fld,
                )

    @staticmethod
    def strip_kind(key: str) -> str:
        """A value key (``c:`` / ``f:`` / ``h:`` / ``i:``) without its kind
        and field."""
        k = key[2:] if len(key) > 2 and key[1] == ":" else key
        hash_ = k.find("#")
        return k if hash_ < 0 else k[:hash_]

    def own_values(self, doc: SpecDocument, row: str, fld: str) -> list[str]:
        """The values a row's own forms (``<row>/<member>``) hold in
        *fld*."""
        index = self._forms.get(id(doc))
        if index is None:
            index = {}
            for p in doc.form_paths:
                slash = p.rfind("/")
                if slash > 0:
                    index.setdefault(p[:slash], []).append(p)
            self._forms[id(doc)] = index
        out: list[str] = []
        for p in index.get(row, []):
            v = doc.form_field(p, fld)
            if v is not None:
                out.append(SpecSetCheck.reviewed(v))
        return out

    # --- unmarkable derived changes -----------------------------------------

    def unmarkable_scan(self, order: int) -> None:
        """Every change ``derive_fields`` would write in a document under
        review that cannot be marked exactly: left for the agent."""
        doc_set = self.set
        for name in doc_set.names:
            doc = doc_set.get(name)
            assert doc is not None
            root = self.root_seg(doc_set.root_of(name))
            derived = derive_fields(doc_set.model, doc, dry_run=True)
            for u in derived.unresolved:
                if u.code != SpecValidationCode.UNMARKABLE:
                    continue
                p = SpecSyncPlace(document=name, root=root, path=u.path)
                self.add(
                    order,
                    f"{name} {u.path}",
                    SpecSyncFinding(
                        code=SpecSyncCode.UNMARKABLE,
                        pair="",
                        blueprint=p,
                        detail=p,
                        holder=SpecSyncHolder.DETAIL,
                        resolution=SpecSyncResolution.AGENT,
                        message=f"{u.message} (in {name})",
                    ),
                )

    # --- pending marks ------------------------------------------------------

    def pending_scan(self, order: int) -> None:
        """Every value of every document that holds pending change marks."""
        doc_set = self.set
        for name in doc_set.names:
            doc = doc_set.get(name)
            assert doc is not None
            root = self.root_seg(doc_set.root_of(name))

            def flag(path: str, fld: Optional[str], raw: str) -> None:
                if not SpecSetCheck.is_pending(raw):
                    return
                p = SpecSyncPlace(
                    document=name,
                    root=root,
                    path=path,
                    field=fld,
                    value=SpecSetCheck.reviewed(raw),
                    pending_marks=True,
                )
                what = "the value" if fld is None else f'form field "{fld}"'
                self.add(
                    order,
                    f"{name} {path} {fld or ''}",
                    SpecSyncFinding(
                        code=SpecSyncCode.PENDING_REVIEW,
                        pair="",
                        blueprint=p,
                        detail=p,
                        holder=SpecSyncHolder.DETAIL,
                        resolution=SpecSyncResolution.INFO,
                        message=f"{what} at {path} in {name} holds pending change marks",
                    ),
                )

            for p in list(doc.content_paths):
                flag(p, None, doc.content(p) or "")
            for p in list(doc.form_paths):
                for f in list(doc.form_field_names(p)):
                    flag(p, f, doc.form_field(p, f) or "")
            for p in list(doc.headline_paths):
                flag(p, None, doc.headline(p) or "")

    # --- links across two documents -----------------------------------------

    def _instances(self, doc: SpecDocument, type_name: str) -> list[tuple[str, SpecClass]]:
        """Every class instance of a document of root *type_name*: path and
        class."""
        refl = self.refl
        out: list[tuple[str, SpecClass]] = []

        def walk(cls: SpecClass, path: str, on_path: set[str]) -> None:
            out.append((path, cls))
            for f in cls.fields:
                if f.has_annotation("Reference"):
                    continue
                member = f"{path}/{refl.field_segment(f)}"
                if f.kind == SpecFieldKind.LIST and f.element_is_complex:
                    el = refl.class_named(f.element_type)
                    if el is None:
                        continue
                    for item in doc.list_items(member):
                        walk(el, item, set())
                elif f.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
                    child = refl.class_named(f.type.replace("?", "") if f.type is not None else None)
                    if child is None or child.name in on_path:
                        continue
                    walk(child, member, on_path | {cls.name})

        cls = refl.class_named(type_name)
        if cls is not None:
            walk(cls, self.root_seg(type_name), set())
        return out

    def registry_document(self, section_id: Optional[str]) -> Optional[str]:
        """The document a registry class is read in: the one whose root
        details it (a populated root other than the Blueprint's that reaches
        it), else the Blueprint."""
        if section_id not in self._registry_docs:
            self._registry_docs[section_id] = self._compute_registry_document(section_id)
        return self._registry_docs[section_id]

    def _compute_registry_document(self, section_id: Optional[str]) -> Optional[str]:
        classes = {c.name for c in self.refl.model.classes.values() if c.section_id == section_id}
        blueprint: Optional[str] = None
        for name in self.set.names:
            root = self.set.root_of(name)
            assert root is not None
            reach = self._reach.get(root)
            if reach is None:
                reach = self.refl.reachable_class_names(root)
                self._reach[root] = reach
            if not any(r in classes for r in reach):
                continue
            if root == self.set.blueprint_root:
                blueprint = name
            else:
                return name
        return blueprint

    def _identity(self, doc: SpecDocument, item: str, target: str) -> Optional[str]:
        fld = target[target.find(".") + 1:]
        if fld == K_SECTION_ID_SLOT:
            return self.item_id(doc, item)
        values = self.own_values(doc, item, fld)
        return None if len(values) == 0 else values[0]

    def _entry(self, doc: SpecDocument, refers_to: list[str], id_: str) -> Optional[str]:
        """The entry of *doc* that *refers_to* names *id_* by, or ``None``."""
        by_target = self._entries.setdefault(id(doc), {})
        for t in refers_to:
            index = by_target.get(t)
            if index is None:
                index = {}
                sid = t.split(".")[0]
                for lst in sorted(doc.list_paths):
                    for item in doc.list_items(lst):
                        r = self.refl.resolve(item)
                        if r is None or r.target_class is None or r.target_class.section_id != sid:
                            continue
                        name = self._identity(doc, item, t)
                        if name is not None and name not in index:
                            index[name] = item
                by_target[t] = index
            hit = index.get(id_)
            if hit is not None:
                return hit
        return None

    def _nearest_item(self, path: str) -> Optional[str]:
        p = path
        while True:
            if self.is_item(p):
                return p
            slash = p.rfind("/")
            if slash < 0:
                return None
            p = p[:slash]

    def cross_checks(self, pairs: Optional[set[str]], order: int) -> None:
        """The links across two documents: summaries and inverses."""
        for name in self.set.names:
            doc = self.set.get(name)
            root = self.set.root_of(name)
            assert doc is not None and root is not None
            for path, cls in self._instances(doc, root):
                pair_id = cls.section_id or cls.name
                if pairs is not None and pair_id not in pairs:
                    continue
                for f in cls.fields:
                    member = f"{path}/{self.refl.field_segment(f)}"
                    s = f.summary_of
                    if s is not None and s.document is not None and f.kind == SpecFieldKind.LIST:
                        self._cross_summary_rows(order, pair_id, name, doc, member, s)
                    for ff in f.form_fields:
                        if ff.summary_of is not None and ff.summary_of.document is not None:
                            self._cross_summary_field(order, pair_id, name, doc, member, ff)
                        if ff.inverse_of is not None and not ff.inverse_of.symmetric:
                            self._cross_inverse(order, pair_id, name, doc, member, ff)

    def _cross_detail(self, s: Any) -> Optional[tuple[str, SpecDocument, dict[str, str]]]:
        """The detail elements of a cross summary: (document name, document,
        item -> id)."""
        name = self.set.name_of(s.document)
        if name is None:
            return None  # not started
        doc = self.set.get(name)
        assert doc is not None
        seg = self.root_seg(self.set.root_of(name))
        r = None
        try:
            slash = s.detail.find("/")
            if slash < 0:
                r = SpecPlace.parse(s.detail).resolve(self.refl, seg)
            else:
                head = SpecPlace.parse(s.detail[:slash]).resolve(self.refl, seg)
                scope = f"{head.path}-*" if head.kind == SpecPlaceKind.LIST else head.path
                concrete = self.expand(doc, scope)
                if len(concrete) > 0:
                    r = SpecPlace.parse(s.detail[slash + 1:]).resolve(self.refl, concrete[0])
        except SpecPlaceException:
            return None
        if r is None or r.kind != SpecPlaceKind.LIST:
            return None
        elements: dict[str, str] = {}
        for lst in self.expand(doc, r.path):
            for item in doc.list_items(lst):
                elements[item] = self.item_id(doc, item)
        return name, doc, elements

    def _place(
        self,
        name: Optional[str],
        path: str,
        fld: Optional[str] = None,
        value: Optional[str] = None,
    ) -> SpecSyncPlace:
        return SpecSyncPlace(
            document=name,
            root="" if name is None else self.root_seg(self.set.root_of(name)),
            path=path,
            field=fld,
            value=value,
        )

    def _cross(
        self,
        order: int,
        code: str,
        pair: str,
        here: SpecSyncPlace,
        there: SpecSyncPlace,
        message: str,
    ) -> None:
        self.add(
            order,
            f"{here.document} {here.path} {here.field or ''} {there.value or ''}",
            SpecSyncFinding(
                code=code,
                pair=pair,
                blueprint=here,
                detail=there,
                holder=SpecSyncHolder.DETAIL,
                resolution=SpecSyncResolution.AGENT,
                message=message,
            ),
        )

    def _cross_summary_rows(
        self, order: int, pair: str, name: str, doc: SpecDocument, lst: str, s: Any
    ) -> None:
        detail = self._cross_detail(s)
        if detail is None:
            return
        d_name, d_doc, elements = detail
        by_id: dict[str, str] = {}
        for item, id_ in elements.items():
            by_id[id_] = item
        named: dict[str, str] = {}
        for row in doc.list_items(lst):
            ids = [self.item_id(doc, row)] if s.match is None else self._match_ids(doc, s.match, row)
            for id_ in ids:
                target = by_id.get(id_)
                if target is None:
                    self._cross(
                        order,
                        SpecSyncCode.CROSS_SUMMARY_MISMATCH,
                        pair,
                        self._place(name, row, value=id_),
                        self._place(d_name, "" if lst == "" else self._list_of(elements), value=id_),
                        f"the summary row names {id_}, which is no element of {s.detail} "
                        f"in {d_name}",
                    )
                    continue
                if id_ in named:
                    self._cross(
                        order,
                        SpecSyncCode.CROSS_SUMMARY_MISMATCH,
                        pair,
                        self._place(name, row, value=id_),
                        self._place(d_name, target, value=id_),
                        f"the summary row names {id_}, which {named[id_]} names already",
                    )
                    continue
                named[id_] = row
                for mine_key, theirs_key in s.repeats.items():
                    mine = self._value_at(doc, mine_key, row)
                    theirs = self._value_at(d_doc, theirs_key, target)
                    if mine is None or theirs is None or mine[1] == "":
                        continue
                    if mine[1] != theirs[1]:
                        self._cross(
                            order,
                            SpecSyncCode.CROSS_SUMMARY_MISMATCH,
                            pair,
                            self._place(name, mine[0], fld=mine[2], value=mine[1]),
                            self._place(d_name, theirs[0], fld=theirs[2], value=theirs[1]),
                            f'{mine_key} repeats {theirs_key} of {id_} as "{mine[1]}", '
                            f'but {d_name} holds "{theirs[1]}"',
                        )
        if s.relation == "equal":
            for item, id_ in elements.items():
                if id_ in named:
                    continue
                self._cross(
                    order,
                    SpecSyncCode.CROSS_SUMMARY_MISMATCH,
                    pair,
                    self._place(name, lst),
                    self._place(d_name, item, value=id_),
                    f"the detail element {id_} of {d_name} is named by no row of {lst} "
                    "(relation: equal)",
                )

    @staticmethod
    def _list_of(elements: dict[str, str]) -> str:
        if len(elements) == 0:
            return ""
        first = next(iter(elements))
        return first[: first.rfind("-")]

    def _match_ids(self, doc: SpecDocument, place: str, row: str) -> list[str]:
        v = self._value_at(doc, place, row)
        return [] if v is None else SpecSetCheck.ids(v[1])

    def _value_at(
        self, doc: SpecDocument, place: str, anchor: str
    ) -> Optional[tuple[str, str, Optional[str]]]:
        """The value of *place* under the concrete *anchor*: (path, value,
        field)."""
        try:
            r = SpecPlace.parse(place).resolve(self.refl, anchor)
        except SpecPlaceException:
            return None
        paths = self.expand(doc, r.path)
        if len(paths) != 1:
            return None
        p = paths[0]
        raw: Optional[str]
        if r.kind == SpecPlaceKind.FORM_FIELD:
            raw = doc.form_field(p, r.field)  # type: ignore[arg-type]
        elif r.kind == SpecPlaceKind.CONTENT:
            raw = doc.content(p)
        elif r.kind == SpecPlaceKind.HEADLINE:
            raw = doc.headline(p)
        elif r.kind == SpecPlaceKind.SECTION_ID:
            raw = self.item_id(doc, p) if self.is_item(p) else None
        else:
            raw = None
        return p, SpecSetCheck.reviewed(raw or ""), r.field

    def _cross_summary_field(
        self, order: int, pair: str, name: str, doc: SpecDocument, form: str, ff: FormFieldSpec
    ) -> None:
        raw = doc.form_field(form, ff.name)
        if raw is None:
            return
        s = ff.summary_of
        detail = self._cross_detail(s)
        if detail is None:
            return
        d_name, _, elements = detail
        known = set(elements.values())
        seen: dict[str, None] = {}
        for id_ in SpecSetCheck.ids(SpecSetCheck.reviewed(raw)):
            fresh = id_ not in seen
            seen[id_] = None
            if id_ not in known or not fresh:
                self._cross(
                    order,
                    SpecSyncCode.CROSS_SUMMARY_MISMATCH,
                    pair,
                    self._place(name, form, fld=ff.name, value=id_),
                    self._place(d_name, self._list_of(elements), value=id_),
                    f'form field "{ff.name}" names {id_} twice'
                    if id_ in known
                    else f'form field "{ff.name}" names {id_}, which is no element of '
                    f"{s.detail} in {d_name}",  # type: ignore[union-attr]
                )
        if s.relation == "equal":  # type: ignore[union-attr]
            for item, id_ in elements.items():
                if id_ in seen:
                    continue
                self._cross(
                    order,
                    SpecSyncCode.CROSS_SUMMARY_MISMATCH,
                    pair,
                    self._place(name, form, fld=ff.name),
                    self._place(d_name, item, value=id_),
                    f'the detail element {id_} of {d_name} is not named in "{ff.name}" '
                    "(relation: equal)",
                )

    def _cross_inverse(
        self, order: int, pair: str, name: str, doc: SpecDocument, form: str, ff: FormFieldSpec
    ) -> None:
        raw = doc.form_field(form, ff.name)
        if raw is None:
            return
        value = SpecSetCheck.reviewed(raw)
        if value == "":
            return
        inv = ff.inverse_of
        assert inv is not None

        def sid_of(p: str) -> Optional[str]:
            res = self.refl.resolve(p)
            return res.target_class.section_id if res is not None and res.target_class is not None else None

        for b in SpecSetCheck.ids(value):
            # The document the named entry is read in.
            registries = dict.fromkeys(t.split(".")[0] for t in ff.refers_to)
            for registry in registries:
                other = self.registry_document(registry)
                if other is None or other == name:
                    continue
                o_doc = self.set.get(other)
                assert o_doc is not None
                targets = [t for t in ff.refers_to if t.split(".")[0] == registry]
                b_path = self._entry(o_doc, targets, b)
                if b_path is None:
                    continue
                for end in inv.fields:
                    try:
                        r = SpecPlace.parse(end).resolve(self.refl, b_path)
                    except SpecPlaceException:
                        continue
                    if r.form_field is None:
                        continue
                    # This field's entry, named as the other end names it, and
                    # read in its own registry document only.
                    a_classes = {t.split(".")[0] for t in r.form_field.refers_to}
                    a = self._nearest_item(form)
                    while a is not None and sid_of(a) not in a_classes:
                        slash = a.rfind("/")
                        a = None if slash < 0 else self._nearest_item(a[:slash])
                    if a is None:
                        continue
                    if self.registry_document(sid_of(a)) != name:
                        continue
                    a_id: Optional[str] = None
                    for t in r.form_field.refers_to:
                        v = self._identity(doc, a, t)
                        if v is not None:
                            a_id = v
                            break
                    if a_id is None:
                        continue
                    ends = self.expand(o_doc, r.path)
                    fld = r.field
                    names_back = any(
                        a_id
                        in SpecSetCheck.ids(
                            SpecSetCheck.reviewed(o_doc.form_field(p, fld) or "")  # type: ignore[arg-type]
                        )
                        for p in ends
                    )
                    if not names_back:
                        self._cross(
                            order,
                            SpecSyncCode.CROSS_INVERSE_MISSING,
                            pair,
                            self._place(name, form, fld=ff.name, value=b),
                            self._place(
                                other, b_path if len(ends) == 0 else ends[0], fld=r.field, value=a_id
                            ),
                            f'form field "{ff.name}" in {name} names {b}, but {b} in {other} '
                            f"does not name {a_id} back ({', '.join(inv.fields)})",
                        )


# ---------------------------------------------------------------------------
# The global rename
# ---------------------------------------------------------------------------


class SpecRenameError(Exception):
    """Why :func:`rename_id` refuses."""

    def __init__(self, documents: list[str], message: str) -> None:
        super().__init__(message)
        #: The documents already holding the new id.
        self.documents = documents
        #: The message.
        self.message = message

    def __str__(self) -> str:
        return f"SpecRenameError: {self.message}"


@dataclass(frozen=True)
class SpecRenameChange:
    """One value :func:`rename_id` changed."""

    #: The document's name.
    document: str
    #: The path: a list item (its section id) or the value's path.
    path: str
    #: ``sectionId``, ``value`` (a form field or content).
    kind: str
    #: The value before.
    old_value: str
    #: The value after.
    new_value: str
    #: The form field, or ``None``.
    field: Optional[str] = None

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form."""
        out: dict[str, Any] = {"document": self.document, "path": self.path}
        if self.field is not None:
            out["field"] = self.field
        out["kind"] = self.kind
        out["old"] = self.old_value
        out["new"] = self.new_value
        return out


def _all_items(doc: SpecDocument) -> list[str]:
    out: list[str] = []
    for lst in sorted(doc.list_paths):
        out.extend(doc.list_items(lst))
    return out


def rename_id(doc_set: SpecDocumentSet, from_: str, to: str) -> list[SpecRenameChange]:
    """Renames the section id *from_* to *to* in every document of *doc_set*
    at once (DP-part-cleanup-2): the list element carrying it, and every value
    naming it as a whole token (references, comma-separated lists, the texts
    link rows are extracted from). Refused, nothing changed, when an element
    of any document already carries *to*. Returns the changes, in document and
    path order."""
    c = SpecSetCheck(doc_set)
    holders = []
    for name in doc_set.names:
        doc = doc_set.get(name)
        assert doc is not None
        if any(c.item_id(doc, i) == to for i in _all_items(doc)):
            holders.append(name)
    if len(holders) > 0:
        raise SpecRenameError(holders, f"{to} is already an id in {', '.join(holders)}")
    token = re.compile(rf"(?<![A-Za-z0-9-]){re.escape(from_)}(?![A-Za-z0-9-])")

    def replace(v: str) -> str:
        return token.sub(lambda _m: to, v)

    changes: list[SpecRenameChange] = []
    for name in doc_set.names:
        doc = doc_set.get(name)
        assert doc is not None
        for item in _all_items(doc):
            if c.item_id(doc, item) != from_:
                continue
            doc.set_item_section_id(item, to)
            changes.append(
                SpecRenameChange(
                    document=name, path=item, kind="sectionId", old_value=from_, new_value=to
                )
            )
        for p in sorted(doc.content_paths):
            v = doc.content(p) or ""
            if not token.search(v):
                continue
            n = replace(v)
            doc.set_content(p, n)
            changes.append(
                SpecRenameChange(document=name, path=p, kind="value", old_value=v, new_value=n)
            )
        for p in sorted(doc.form_paths):
            for f in sorted(doc.form_field_names(p)):
                v = doc.form_field(p, f) or ""
                if not token.search(v):
                    continue
                n = replace(v)
                doc.set_form_field(p, f, n)
                changes.append(
                    SpecRenameChange(
                        document=name, path=p, field=f, kind="value", old_value=v, new_value=n
                    )
                )
    return changes


__all__ = [
    "SpecSyncCode",
    "spec_sync_code_index",
    "SpecSyncResolution",
    "SpecSyncHolder",
    "SpecDocumentSetRefusal",
    "SpecDocumentSetError",
    "SpecSyncPair",
    "SpecDocumentSet",
    "SpecSyncPlace",
    "SpecSyncFinding",
    "SpecSyncReport",
    "sync_report",
    "SpecSetFound",
    "SpecSetValue",
    "SpecSetSide",
    "SpecSetCheck",
    "SpecRenameError",
    "SpecRenameChange",
    "rename_id",
]
