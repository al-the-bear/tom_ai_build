"""In-memory representation of the exported TomSpecs class graph (the
spec-model meta-data file) — a faithful port of
`tom_som_dart_runtime/lib/src/spec_model.dart`.

The model is a *class graph*, not an expanded tree: each class appears once and
field ``elementType`` / ``type`` references are followed on demand by a
traversal. This is the "reflection" surface — it describes any document's
structure, independent of the values a concrete document holds.
"""

from __future__ import annotations

import datetime as _dt
import re as _re
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Optional


class SpecFieldKind(Enum):
    """The render kind of a field, mirroring the exporter's classification."""

    LIST = "list"
    FORM = "form"
    SECTION = "section"
    CONTENT = "content"
    ENUM = "enum"
    COMPLEX = "complex"
    SCALAR = "scalar"

    @staticmethod
    def parse(raw: str) -> "SpecFieldKind":
        for kind in SpecFieldKind:
            if kind.value == raw:
                return kind
        return SpecFieldKind.SCALAR


@dataclass(frozen=True)
class SpecAnnotation:
    """A single annotation captured losslessly from the model source (spec
    SOM §5.3): its name and the resolved argument map."""

    name: str
    arguments: dict[str, Any] = field(default_factory=dict)

    def argument(self, key: str) -> Any:
        return self.arguments.get(key)

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecAnnotation":
        return SpecAnnotation(
            name=j["name"],
            arguments=dict(j.get("arguments") or {}),
        )

    @staticmethod
    def list_from_json(raw: Any) -> list["SpecAnnotation"]:
        if not isinstance(raw, list):
            return []
        return [SpecAnnotation.from_json(e) for e in raw]


@dataclass(frozen=True)
class FormFieldSpec:
    """A single form field within a ``@Form`` content section."""

    name: str
    label: str
    type: str = "String"
    hint: Optional[str] = None
    required: bool = False
    #: Enum constant names when :attr:`type` is a model enum (YRD7); empty for
    #: non-enum field types. Lets consumers validate and convert values without
    #: the analyzer.
    enum_values: list[str] = field(default_factory=list)
    #: The registry key(s) this field's value is an id drawn from, each written
    #: ``<SECTIONID>.<formFieldName>``; empty for a non-reference field. A
    #: reference field holds a free-text id that must already be declared by
    #: some entry of the named registry, so a runtime can resolve it and report
    #: a dangling id instead of generating broken code.
    refers_to: list[str] = field(default_factory=list)
    #: The entries this field's value counts (``Field.countOf``, vsctsa43),
    #: each ``<SECTIONID>`` or ``<SECTIONID>.<formField>=<value>``; empty for a
    #: field that states no count. The instance tier holds the stated number to
    #: the document (``countMismatch``).
    count_of: list[str] = field(default_factory=list)
    #: The operands this field's value is the product of (``Field.productOf``,
    #: uamtc10), each a field of the same form or ``<FORMSID>.<field>`` of a
    #: sibling form; empty for a field that states no product. The instance
    #: tier holds the stated number to it (``derivedValueMismatch``).
    product_of: list[str] = field(default_factory=list)
    #: The field of the same form whose number this field ranks, highest first
    #: (``Field.rankOf``, uamtc10); ``None`` for a field that states no rank.
    rank_of: Optional[str] = None
    #: Whether the value is code rather than prose (``Field.code``): the
    #: markdown codec writes it as an inline code span and unwraps it on import
    #: (SOM §11.4 rule 8). Omitted from the export when ``False``.
    code: bool = False
    #: Whether the field's values hold paragraphs or blocks
    #: (``Field.multiParagraph``): the markdown renderer writes them as a
    #: ``Field:`` paragraph, never as a row of the form table (SOM §11.4).
    multi_paragraph: bool = False
    #: Whether a reference field holds a comma-separated list of ids
    #: (``Field.multiple``, uamtc17); a reference field without it holds one,
    #: and the instance tier reports a list in it (``multipleReferences``).
    multiple: bool = False
    #: The derivation this field's value follows (``Field.derivedFrom``,
    #: `tom_specs_model_rules.md` §9.7), or ``None`` when it states none.
    derived_from: Optional["SpecDerivation"] = None
    #: The other ends of the link this reference field is one end of
    #: (``Field.inverseOf``), or ``None`` when it states none.
    inverse_of: Optional["SpecInverseOf"] = None
    #: The detailed list this multi-valued reference field summarises
    #: (``Field.summaryOf``), or ``None`` when it states none.
    summary_of: Optional["SpecSummaryOf"] = None

    @staticmethod
    def from_json(j: dict[str, Any]) -> "FormFieldSpec":
        return FormFieldSpec(
            name=j["name"],
            label=j.get("label") or j["name"],
            type=j.get("type") or "String",
            hint=j.get("hint"),
            required=bool(j.get("required") or False),
            enum_values=[str(e) for e in (j.get("enumValues") or [])],
            refers_to=[str(e) for e in (j.get("refersTo") or [])],
            count_of=[str(e) for e in (j.get("countOf") or [])],
            product_of=[str(e) for e in (j.get("productOf") or [])],
            rank_of=(str(j["rankOf"]) if j.get("rankOf") is not None else None),
            code=bool(j.get("code") or False),
            multi_paragraph=j.get("multiParagraph") is True,
            multiple=bool(j.get("multiple") or False),
            derived_from=(
                SpecDerivation.from_arguments(_object_map(j["derivedFrom"]))
                if isinstance(j.get("derivedFrom"), dict)
                else None
            ),
            inverse_of=(
                SpecInverseOf.from_arguments(_object_map(j["inverseOf"]))
                if isinstance(j.get("inverseOf"), dict)
                else None
            ),
            summary_of=(
                SpecSummaryOf.from_arguments(_object_map(j["summaryOf"]))
                if isinstance(j.get("summaryOf"), dict)
                else None
            ),
        )


def _strip_enum_prefix(raw: str) -> str:
    """``CodeSpecPart.validation`` → ``validation``. A name already given bare
    is returned unchanged, so readers do not depend on how the exporter chose
    to spell the enum constant. Splitting on the last dot rather than a fixed
    prefix keeps this working for any code enum the model adds."""
    dot = raw.rfind(".")
    return raw if dot < 0 else raw[dot + 1 :]


@dataclass(frozen=True)
class KindLink:
    """A list-valued taxonomy annotation: a set of enum codes plus an optional
    explanatory note.

    The model states where a subtree is headed with two such annotations, which
    share this shape exactly — ``@CodeSpecKind(List<CodeSpecPart>, {note})``
    names the CodeSpecs part(s) a section type must be realised as
    (`codespecs_mapping.md` §9.1/§9.5), and
    ``@FollowUpKind(List<FollowUpProcess>, {note})`` names the downstream
    *process(es)* a non-code subtree feeds (`codespecs_mapping.md` §8.3). One
    reader serves both; which annotation a link came from is expressed by which
    accessor produced it.

    Obtaining a link at all means the annotation is present. That matters: a
    node with no link has not been classified yet, whereas a link with empty
    :attr:`kinds` is a recorded decision that the section belongs to no member
    of that taxonomy. The two are different statements, so they are different
    values rather than one nullable list."""

    #: The enum code names with their type prefix stripped — ``validation``,
    #: not ``CodeSpecPart.validation``; ``doc``, not ``FollowUpProcess.doc``.
    #:
    #: Both annotations are list-valued because one section can be realised as
    #: several parts, or feed several processes; consumers must handle all of
    #: them, not just the first.
    kinds: list[str] = field(default_factory=list)
    #: The annotation's free-text ``note``, explaining the classification.
    note: Optional[str] = None

    @staticmethod
    def from_annotation(
        annotation: SpecAnnotation, list_argument: str
    ) -> "KindLink":
        """Reads a link out of *annotation*, taking the code list from the
        argument named *list_argument* — ``kinds`` for ``@CodeSpecKind``,
        ``processes`` for ``@FollowUpKind``."""
        raw = annotation.argument(list_argument)
        return KindLink(
            kinds=(
                [_strip_enum_prefix(str(k)) for k in raw if k is not None]
                if isinstance(raw, list)
                else []
            ),
            note=annotation.argument("note"),
        )


@dataclass(frozen=True)
class NoArtifactLink:
    """The third routing verdict: ``@NoArtifact(NoArtifactReason, {note})`` —
    the section feeds neither a CodeSpecs part nor a follow-up process
    (`codespecs_mapping.md` §8.3).

    Single-valued where :class:`KindLink` is a list, and the asymmetry is the
    point: a section can feed several parts or several processes at once, but
    it is unrouted for exactly one reason. That reason is what makes the
    absence of the other two markers readable as a decision rather than an
    omission, which is what `tom_specs_model_rules.md` §10.2 invariant
    ``ROUTE-TOTAL`` checks."""

    #: The ``NoArtifactReason`` code name with its type prefix stripped —
    #: ``container``, not ``NoArtifactReason.container``. One of ``container``,
    #: ``overview``, ``view``.
    reason: str
    #: The annotation's free-text ``note``. On an ``overview`` this customarily
    #: names the routed section that states the material normatively.
    note: Optional[str] = None

    @staticmethod
    def from_annotation(annotation: SpecAnnotation) -> "NoArtifactLink":
        """Reads the verdict out of *annotation*."""
        raw = annotation.argument("reason")
        return NoArtifactLink(
            reason=_strip_enum_prefix("container" if raw is None else str(raw)),
            note=annotation.argument("note"),
        )


# ---------------------------------------------------------------------------
# The link vocabulary (`tom_specs_model_rules.md` §9.7)
# ---------------------------------------------------------------------------
#
# Typed readers of the link annotations, read from the lossless ``annotations``
# block (member and class annotations) or from the curated ``formFields[]``
# keys (the ``Field`` qualifiers). They follow :class:`KindLink`: an enum
# constant is read with its type prefix stripped (``LinkRelation.subset`` →
# ``subset``), a key the reader does not know is ignored, and an absent key
# takes the annotation's default — so a meta written before a key existed
# loads unchanged.


def _string_list(raw: Any) -> list[str]:
    """A JSON list read as strings; anything else as empty."""
    return [str(e) for e in raw if e is not None] if isinstance(raw, list) else []


def _object_map(raw: Any) -> dict[str, Any]:
    """A JSON object read with string keys; anything else as empty."""
    return dict(raw) if isinstance(raw, dict) else {}


def _string_map(raw: Any) -> dict[str, str]:
    """A JSON object read as string → string; anything else as empty."""
    if not isinstance(raw, dict):
        return {}
    return {str(k): _json_text(v) for k, v in raw.items()}


def _json_text(v: Any) -> str:
    """A JSON scalar as text, the way the reference writes it (``true``, not
    ``True``)."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if v is None:
        return "null"
    return str(v)


def _opt_string(raw: Any) -> Optional[str]:
    """An optional string argument: the string, or ``None`` for anything
    else."""
    return raw if isinstance(raw, str) else None


def _str(raw: Any, fallback: str) -> str:
    """A string argument with a default when absent."""
    return fallback if raw is None else _json_text(raw)


@dataclass(frozen=True)
class SpecListRelation:
    """The relation of the elements of a list on two sides of a link, as the
    annotated side reads it (``ListRelation``, `tom_specs_model_rules.md`
    §9.7)."""

    #: The list or multi-valued reference field the relation is about.
    place: str
    #: ``equal``, ``subset`` or ``superset`` (the ``LinkRelation`` constant
    #: name).
    relation: str
    #: The filter selecting the elements the relation applies to, or ``None``
    #: for all of them (the :class:`SpecPlaceFilter` grammar).
    where: Optional[str] = None

    @staticmethod
    def from_arguments(a: dict[str, Any]) -> "SpecListRelation":
        """Reads one ``relations[]`` entry of a ``@SyncedWith``."""
        return SpecListRelation(
            place=_str(a.get("place"), ""),
            relation=_strip_enum_prefix(_str(a.get("relation"), "equal")),
            where=_opt_string(a.get("where")),
        )

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form, keys in declaration order, ``None`` left
        out."""
        out: dict[str, Any] = {"place": self.place, "relation": self.relation}
        if self.where is not None:
            out["where"] = self.where
        return out


@dataclass(frozen=True)
class SpecSync:
    """``@SyncedWith(document, {detailOnly, heldHere, relations, note})``: the
    annotated section is kept in sync with the section of the same id in
    *document* (`tom_specs_model_rules.md` §9.7)."""

    #: The other document's root class name.
    document: str
    #: The places only *document* carries.
    detail_only: list[str] = field(default_factory=list)
    #: The places whose value this document holds.
    held_here: list[str] = field(default_factory=list)
    #: The lists whose relation is not ``equal``.
    relations: list[SpecListRelation] = field(default_factory=list)
    #: The annotation's free-text note.
    note: Optional[str] = None

    @staticmethod
    def from_annotation(annotation: "SpecAnnotation") -> "SpecSync":
        """Reads the sync out of *annotation*."""
        a = annotation.arguments
        relations = a.get("relations")
        return SpecSync(
            document=_str(a.get("document"), ""),
            detail_only=_string_list(a.get("detailOnly")),
            held_here=_string_list(a.get("heldHere")),
            relations=[
                SpecListRelation.from_arguments(_object_map(r))
                for r in (relations if isinstance(relations, list) else [])
                if isinstance(r, dict)
            ],
            note=_opt_string(a.get("note")),
        )

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form, keys in declaration order, ``None`` left
        out."""
        out: dict[str, Any] = {
            "document": self.document,
            "detailOnly": list(self.detail_only),
            "heldHere": list(self.held_here),
            "relations": [r.to_json() for r in self.relations],
        }
        if self.note is not None:
            out["note"] = self.note
        return out


@dataclass(frozen=True)
class SpecSummaryOf:
    """``@SummaryOf`` on a member, or the ``summaryOf:`` qualifier of a form
    field: the annotated list or reference field summarises a detailed list
    (`tom_specs_model_rules.md` §9.7)."""

    #: The detailed list, ``<LIST-ID>`` (a ``/`` path where needed).
    detail: str
    #: The root class name of the document holding :attr:`detail`; ``None``:
    #: this one.
    document: Optional[str] = None
    #: The summary element's field naming its detail element; ``None``: the
    #: summary element carries the detail element's own section id.
    match: Optional[str] = None
    #: ``equal``, ``subset`` (the default) or ``superset``.
    relation: str = "subset"
    #: Summary place → detail place for every value the summary repeats.
    repeats: dict[str, str] = field(default_factory=dict)
    #: The annotation's free-text note.
    note: Optional[str] = None

    @staticmethod
    def from_arguments(a: dict[str, Any]) -> "SpecSummaryOf":
        """Reads the arguments of a ``SummaryOf`` (annotation or qualifier)."""
        return SpecSummaryOf(
            detail=_str(a.get("detail"), ""),
            document=_opt_string(a.get("document")),
            match=_opt_string(a.get("match")),
            relation=_strip_enum_prefix(_str(a.get("relation"), "subset")),
            repeats=_string_map(a.get("repeats")),
            note=_opt_string(a.get("note")),
        )

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form, keys in declaration order, ``None`` left
        out."""
        out: dict[str, Any] = {"detail": self.detail}
        if self.document is not None:
            out["document"] = self.document
        if self.match is not None:
            out["match"] = self.match
        out["relation"] = self.relation
        out["repeats"] = dict(self.repeats)
        if self.note is not None:
            out["note"] = self.note
        return out


@dataclass(frozen=True)
class SpecDerivation:
    """``@DerivedFrom`` on a member, or the ``derivedFrom:`` qualifier of a
    form field: the value is derived from other places
    (`tom_specs_model_rules.md` §9.7)."""

    #: ``copy``, ``rows`` or ``lookup`` (the ``DerivationKind`` constant name).
    kind: str
    #: copy: the place copied; rows / lookup: the rows read.
    source: str
    #: rows: which rows count (the :class:`SpecPlaceFilter` grammar).
    where: Optional[str] = None
    #: rows / lookup: the row places collected.
    take: list[str] = field(default_factory=list)
    #: rows / lookup: the row field compared with this element's :attr:`by`.
    key: Optional[str] = None
    #: rows / lookup: this element's field holding the key.
    by: Optional[str] = None
    #: For a list member: target element place ← row place.
    map: dict[str, str] = field(default_factory=dict)
    #: The annotation's free-text note.
    note: Optional[str] = None

    @staticmethod
    def from_arguments(a: dict[str, Any]) -> "SpecDerivation":
        """Reads the arguments of a ``DerivedFrom`` (annotation or
        qualifier)."""
        return SpecDerivation(
            kind=_strip_enum_prefix(_str(a.get("kind"), "copy")),
            source=_str(a.get("source"), ""),
            where=_opt_string(a.get("where")),
            take=_string_list(a.get("take")),
            key=_opt_string(a.get("key")),
            by=_opt_string(a.get("by")),
            map=_string_map(a.get("map")),
            note=_opt_string(a.get("note")),
        )

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form, keys in declaration order, ``None`` left
        out."""
        out: dict[str, Any] = {"kind": self.kind, "source": self.source}
        if self.where is not None:
            out["where"] = self.where
        out["take"] = list(self.take)
        if self.key is not None:
            out["key"] = self.key
        if self.by is not None:
            out["by"] = self.by
        out["map"] = dict(self.map)
        if self.note is not None:
            out["note"] = self.note
        return out


@dataclass(frozen=True)
class SpecInverseOf:
    """The ``inverseOf:`` qualifier of a reference form field: the other ends
    of the link (`tom_specs_model_rules.md` §9.7)."""

    #: The other ends, ``<FORMSECTIONID>.<field>``; ``['@self']`` for the
    #: symmetric form.
    fields: list[str] = field(default_factory=list)
    #: Only values (or rows) matching this filter have an inverse.
    where: Optional[str] = None

    @staticmethod
    def from_arguments(a: dict[str, Any]) -> "SpecInverseOf":
        """Reads the ``inverseOf`` key of a ``formFields[]`` entry."""
        return SpecInverseOf(
            fields=_string_list(a.get("fields")),
            where=_opt_string(a.get("where")),
        )

    @property
    def symmetric(self) -> bool:
        """Whether the link is stored on both entries in the same field
        (``InverseOf.symmetric``)."""
        return len(self.fields) == 1 and self.fields[0] == "@self"

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form, ``None`` left out."""
        out: dict[str, Any] = {"fields": list(self.fields)}
        if self.where is not None:
            out["where"] = self.where
        return out


@dataclass(frozen=True)
class SpecExtractsLinks:
    """``@ExtractsLinks`` on a list of link rows: ids named in text get rows
    (`tom_specs_model_rules.md` §9.7). A member may carry it more than
    once."""

    #: The row's ``refersTo`` field receiving a found id.
    ref: str
    #: The text places searched for ids.
    from_: list[str] = field(default_factory=list)
    #: The values every generated row gets.
    set: dict[str, str] = field(default_factory=dict)
    #: ``generate`` (the default) or ``warn`` (the ``ExtractMode`` constant
    #: name).
    mode: str = "generate"
    #: The annotation's free-text note.
    note: Optional[str] = None

    @staticmethod
    def from_annotation(annotation: "SpecAnnotation") -> "SpecExtractsLinks":
        """Reads one ``ExtractsLinks`` annotation."""
        a = annotation.arguments
        return SpecExtractsLinks(
            from_=_string_list(a.get("from")),
            ref=_str(a.get("ref"), ""),
            set=_string_map(a.get("set")),
            mode=_strip_enum_prefix(_str(a.get("mode"), "generate")),
            note=_opt_string(a.get("note")),
        )

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form, keys in declaration order, ``None`` left
        out."""
        out: dict[str, Any] = {
            "from": list(self.from_),
            "ref": self.ref,
            "set": dict(self.set),
            "mode": self.mode,
        }
        if self.note is not None:
            out["note"] = self.note
        return out


@dataclass(frozen=True)
class SpecSameAs:
    """``@SameAs({holder, note})`` on a section member: the member holds a
    copy of the section the same document holds at another position, the
    holder (`tom_specs_model_rules.md` §9.7). :func:`spec_same_as_bindings`
    finds the holder per document."""

    #: The holder's section-id path, its last ids as far as needed
    #: (``ACPLN/ACRITL``); ``None``: the one other position of the class.
    holder: Optional[str] = None
    #: The annotation's free-text note.
    note: Optional[str] = None

    @staticmethod
    def from_annotation(annotation: "SpecAnnotation") -> "SpecSameAs":
        """Reads the copy out of *annotation*."""
        return SpecSameAs(
            holder=_opt_string(annotation.argument("holder")),
            note=_opt_string(annotation.argument("note")),
        )

    def to_json(self) -> dict[str, Any]:
        """The canonical JSON form, ``None`` left out."""
        out: dict[str, Any] = {}
        if self.holder is not None:
            out["holder"] = self.holder
        if self.note is not None:
            out["note"] = self.note
        return out


class AnnotatedSpecNode:
    """Shared behaviour of the two model nodes that carry annotations —
    classes and fields. Keeps the annotation lookups defined once instead of
    per node type.

    Mixed into the two frozen dataclasses below, each of which supplies the
    ``annotations`` list this reads."""

    #: The lossless annotation list captured on this node (SOM §5.3). Supplied
    #: by the concrete node.
    annotations: list[SpecAnnotation]

    def annotation(self, name: str) -> Optional[SpecAnnotation]:
        """The annotation named *name*, or ``None`` when absent."""
        for a in self.annotations:
            if a.name == name:
                return a
        return None

    def annotations_named(self, name: str) -> list[SpecAnnotation]:
        """Every annotation named *name*, in source order — empty when absent.

        Distinct from :meth:`annotation` because some annotations are
        *repeatable*: ``@Case`` is applied once per discriminator value, so a
        single field can carry several. Reading only the first would silently
        drop the rest."""
        return [a for a in self.annotations if a.name == name]

    def has_annotation(self, name: str) -> bool:
        """Whether the annotation named *name* is present. For markers that
        carry no arguments, presence *is* the whole statement."""
        return self.annotation(name) is not None

    @property
    def code_spec_kind(self) -> Optional[KindLink]:
        """The ``@CodeSpecKind`` link, or ``None`` when this node carries no
        such annotation. See :class:`KindLink` for why absent and empty
        differ."""
        return self._link("CodeSpecKind", "kinds")

    @property
    def follow_up_kind(self) -> Optional[KindLink]:
        """The ``@FollowUpKind`` link, or ``None`` when this node carries no
        such annotation — which downstream process(es) this subtree feeds
        instead of becoming CodeSpecs code (`codespecs_mapping.md` §8.3)."""
        return self._link("FollowUpKind", "processes")

    @property
    def no_artifact(self) -> Optional[NoArtifactLink]:
        """The ``@NoArtifact`` verdict, or ``None`` when this node carries no
        such annotation — the recorded decision that the section produces
        nothing downstream (`codespecs_mapping.md` §8.3)."""
        a = self.annotation("NoArtifact")
        return None if a is None else NoArtifactLink.from_annotation(a)

    @property
    def synced_with(self) -> Optional[SpecSync]:
        """The ``@SyncedWith`` sync, or ``None`` when this node carries none —
        a ``@DetailedIn`` without one is "not declared yet", not "nothing
        shared"."""
        a = self.annotation("SyncedWith")
        return None if a is None else SpecSync.from_annotation(a)

    @property
    def summary_of(self) -> Optional[SpecSummaryOf]:
        """The ``@SummaryOf`` link of this member, or ``None`` when it carries
        none."""
        a = self.annotation("SummaryOf")
        return None if a is None else SpecSummaryOf.from_arguments(a.arguments)

    @property
    def derived_from(self) -> Optional[SpecDerivation]:
        """The ``@DerivedFrom`` derivation of this member, or ``None`` when it
        carries none."""
        a = self.annotation("DerivedFrom")
        return None if a is None else SpecDerivation.from_arguments(a.arguments)

    @property
    def extracts_links(self) -> list[SpecExtractsLinks]:
        """Every ``@ExtractsLinks`` of this member, in source order; empty
        when it carries none."""
        return [
            SpecExtractsLinks.from_annotation(a)
            for a in self.annotations_named("ExtractsLinks")
        ]

    @property
    def same_as(self) -> Optional[SpecSameAs]:
        """The ``@SameAs`` copy of this member, or ``None`` when it carries
        none."""
        a = self.annotation("SameAs")
        return None if a is None else SpecSameAs.from_annotation(a)

    def _link(self, name: str, list_argument: str) -> Optional[KindLink]:
        a = self.annotation(name)
        return None if a is None else KindLink.from_annotation(a, list_argument)


@dataclass(frozen=True)
class SpecField(AnnotatedSpecNode):
    """A single field of a :class:`SpecClass`."""

    name: str
    kind: SpecFieldKind
    doc: Optional[str] = None
    help: Optional[str] = None
    #: The ``@Headline(text)`` default headline (YRD4), or ``None``. Render
    #: precedence: stored headline > this default > name derivation.
    headline: Optional[str] = None
    section_id: Optional[str] = None
    section_id_pattern: Optional[str] = None
    element_type: Optional[str] = None
    element_is_complex: bool = False
    min: Optional[int] = None
    content_type: Optional[str] = None
    section_type: Optional[str] = None
    enum_type: Optional[str] = None
    enum_values: list[str] = field(default_factory=list)
    type: Optional[str] = None
    serialization_order: Optional[int] = None
    form_fields: list[FormFieldSpec] = field(default_factory=list)
    annotations: list[SpecAnnotation] = field(default_factory=list)

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecField":
        raw_order = j.get("serializationOrder")
        return SpecField(
            name=j["name"],
            kind=SpecFieldKind.parse(j["kind"]),
            doc=j.get("doc"),
            help=j.get("help"),
            headline=j.get("headline"),
            section_id=j.get("sectionId"),
            section_id_pattern=j.get("sectionIdPattern"),
            element_type=j.get("elementType"),
            element_is_complex=bool(j.get("elementIsComplex") or False),
            min=j.get("min"),
            content_type=j.get("contentType"),
            section_type=j.get("sectionType"),
            enum_type=j.get("enumType"),
            enum_values=[str(e) for e in (j.get("enumValues") or [])],
            type=j.get("type"),
            serialization_order=int(raw_order) if raw_order is not None else None,
            form_fields=[
                FormFieldSpec.from_json(e) for e in (j.get("formFields") or [])
            ],
            annotations=SpecAnnotation.list_from_json(j.get("annotations")),
        )

    @property
    def is_expandable(self) -> bool:
        """Whether expanding this field reveals further tree nodes."""
        return self.kind in (SpecFieldKind.LIST, SpecFieldKind.COMPLEX)


@dataclass(frozen=True)
class SpecClass(AnnotatedSpecNode):
    """A model class with its fields."""

    name: str
    section_id: Optional[str] = None
    doc: Optional[str] = None
    help: Optional[str] = None
    #: The class-level ``@Headline(text)`` default headline (YRD4), or
    #: ``None``. A field-level ``@Headline`` on the instantiating field wins
    #: over this.
    headline: Optional[str] = None
    maps_to: Optional[str] = None
    detailed_in: Optional[str] = None
    fields: list[SpecField] = field(default_factory=list)
    annotations: list[SpecAnnotation] = field(default_factory=list)

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecClass":
        return SpecClass(
            name=j["name"],
            section_id=j.get("sectionId"),
            doc=j.get("doc"),
            help=j.get("help"),
            headline=j.get("headline"),
            maps_to=j.get("mapsTo"),
            detailed_in=j.get("detailedIn"),
            fields=[SpecField.from_json(e) for e in j["fields"]],
            annotations=SpecAnnotation.list_from_json(j.get("annotations")),
        )

    def field_named(self, name: str) -> Optional[SpecField]:
        for f in self.fields:
            if f.name == name:
                return f
        return None

    @property
    def is_code_specs_projection(self) -> bool:
        """Whether this class is the CodeSpecs projection root
        (``@CodeSpecsProjection``)."""
        return self.has_annotation("CodeSpecsProjection")


@dataclass(frozen=True)
class SpecRoot:
    """A document root (a class carrying ``@Document``)."""

    type: str
    title: str
    section_id: Optional[str] = None
    description: Optional[str] = None
    doc: Optional[str] = None

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecRoot":
        return SpecRoot(
            type=j["type"],
            title=j["title"],
            section_id=j.get("sectionId"),
            description=j.get("description"),
            doc=j.get("doc"),
        )


def som_model_version_string(major: int, label: Optional[str]) -> str:
    """The DocSpecs schema-version string for a model stamp — a faithful port
    of the Dart ``somModelVersionString``.

    When *label* carries at least two dot-separated numeric components
    (``major.minor…``, ignoring any ``+build`` metadata) those win, so a
    genuine authoring minor is preserved (``2.3.1+5`` → ``2.3``). Otherwise
    the result is ``<major>.0``."""
    if label:
        core = label.split("+")[0].strip()
        parts = core.split(".")
        if len(parts) >= 2:
            try:
                maj = int(parts[0].strip())
                minor = int(parts[1].strip())
                return f"{maj}.{minor}"
            except ValueError:
                pass
    return f"{major}.0"


#: How old a snapshot may get before :meth:`SpecModel.check_stamp` calls it
#: aged. A fortnight: long enough that a healthy working copy is never
#: nagged, short enough that structural feedback keyed to a snapshot's paths
#: is not recorded against a model that has moved past them.
DEFAULT_MAX_SNAPSHOT_AGE = _dt.timedelta(days=14)


#: The generation-stamp timestamp grammar, spelled out rather than delegated to
#: ``datetime.fromisoformat``: ``YYYY-MM-DDTHH:MM:SS``, an optional fractional
#: part, and an optional ``Z`` / ``±HH:MM`` / ``±HHMM`` offset.
#:
#: Every SOM runtime carries this same grammar. Delegating to each platform's
#: own parser would make the accepted set differ by language — several of the
#: nine have no date library at all — and a stamp that reads on one platform
#: and not another is exactly the divergence the shared corpus exists to catch.
_STAMP_PATTERN = _re.compile(
    r"^(\d{4})-(\d{2})-(\d{2})[Tt ]"
    r"(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(Z|z|[+-]\d{2}:?\d{2})?$"
)


def _days_in_month(year: int, month: int) -> int:
    """The length of *month* in *year*, Gregorian. Used to reject a day that
    does not exist rather than letting it roll into the next month: some SOM
    runtimes' date types roll 31 February over to 3 March and others reject it,
    so the grammar rejects it everywhere."""
    if month != 2:
        return (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[month - 1]
    is_leap = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
    return 29 if is_leap else 28


def parse_stamp_timestamp(raw: Optional[str]) -> Optional[_dt.datetime]:
    """Parse a generation-stamp timestamp to UTC, or return ``None``.

    A timestamp carrying **no** zone is read as UTC: a staleness verdict that
    changed with the reader's local timezone would be a defect in its own
    right, and the exporter always writes ``Z`` anyway.

    Anything outside the grammar — or carrying an out-of-range field —
    degrades to ``None`` rather than raising: an unreadable stamp is not worth
    failing a whole model over, and rolling ``2026-13-01`` over into January is
    worse than admitting the stamp is unreadable.
    """
    if raw is None:
        return None
    m = _STAMP_PATTERN.match(raw.strip())
    if m is None:
        return None
    year, month, day, hour, minute, second = (int(m.group(i)) for i in range(1, 7))
    if not (1 <= month <= 12 and 1 <= day <= _days_in_month(year, month)):
        return None
    if hour > 23 or minute > 59 or second > 59:
        return None
    # Right-pad the fraction to microseconds; a longer fraction is truncated.
    micros = int((m.group(7) or "").ljust(6, "0")[:6])
    value = _dt.datetime(
        year, month, day, hour, minute, second, micros, _dt.timezone.utc
    )
    zone = m.group(8)
    if zone is not None and zone not in ("Z", "z"):
        digits = zone[1:].replace(":", "")
        offset = _dt.timedelta(hours=int(digits[:2]), minutes=int(digits[2:]))
        value = value + offset if zone[0] == "-" else value - offset
    return value


def _optional_int(raw: Any) -> Optional[int]:
    """A stamp count as an ``int``, or ``None`` when the key is absent.

    Absent must stay ``None`` rather than becoming ``0``: a snapshot predating
    the stamp keys would otherwise declare zero classes and read as corrupt."""
    if raw is None or isinstance(raw, bool):
        return None
    if isinstance(raw, (int, float)):
        return int(raw)
    return None


@dataclass(frozen=True)
class SpecModelStampCheck:
    """The outcome of checking a loaded snapshot's generation stamp against
    its own payload and against the clock — see :meth:`SpecModel.check_stamp`.

    The two findings are independent and can both hold at once: :attr:`is_aged`
    says the snapshot is probably behind the live model, while
    :attr:`counts_disagree` says the file no longer describes itself
    correctly. Only the second is a defect in the file."""

    #: How long ago the snapshot was generated, or ``None`` when it carries no
    #: ``generatedAt`` (an older export, or a hand-built model).
    age: Optional[_dt.timedelta]
    #: The threshold :attr:`age` was judged against.
    max_age: _dt.timedelta
    #: The class count the stamp declares, or ``None`` when it declares none.
    declared_class_count: Optional[int]
    #: The number of classes the payload actually carries.
    actual_class_count: int
    #: The root count the stamp declares, or ``None`` when it declares none.
    declared_root_count: Optional[int]
    #: The number of document roots the payload actually carries.
    actual_root_count: int

    @property
    def is_aged(self) -> bool:
        """Whether the snapshot is older than :attr:`max_age`. Always ``False``
        when the snapshot carries no ``generatedAt`` — an unknown age is not
        evidence of a stale one."""
        return self.age is not None and self.age > self.max_age

    @property
    def class_count_disagrees(self) -> bool:
        """Whether the declared and actual class counts differ.

        An absent declaration is not a disagreement: older snapshots predate
        the stamp keys, and reading absent as ``0`` would make every one of
        them look corrupt."""
        return (
            self.declared_class_count is not None
            and self.declared_class_count != self.actual_class_count
        )

    @property
    def root_count_disagrees(self) -> bool:
        """Whether the declared and actual root counts differ. Absent
        declarations are ignored, as for :attr:`class_count_disagrees`."""
        return (
            self.declared_root_count is not None
            and self.declared_root_count != self.actual_root_count
        )

    @property
    def counts_disagree(self) -> bool:
        """Whether either declared size disagrees with the payload.

        The exporter derives both counts *from* the payload it writes, so a
        disagreement cannot arise from a normal export — it means the file was
        edited or truncated afterwards."""
        return self.class_count_disagrees or self.root_count_disagrees

    @property
    def is_stale(self) -> bool:
        """Whether anything at all was found."""
        return self.is_aged or self.counts_disagree

    @property
    def warnings(self) -> list[str]:
        """The findings as ready-to-display sentences, empty when there are
        none. The wording is identical in all nine runtimes."""
        out: list[str] = []
        if self.is_aged:
            assert self.age is not None
            out.append(
                f"Snapshot is {self.age.days} days old (threshold "
                f"{self.max_age.days} days) — the model may have moved on "
                f"since it was exported."
            )
        if self.class_count_disagrees:
            out.append(
                f"Stamp declares {self.declared_class_count} classes but the "
                f"snapshot carries {self.actual_class_count} — it was edited "
                f"after export."
            )
        if self.root_count_disagrees:
            out.append(
                f"Stamp declares {self.declared_root_count} document roots but "
                f"the snapshot carries {self.actual_root_count} — it was "
                f"edited after export."
            )
        return out


@dataclass(frozen=True)
class SpecModel:
    """The complete exported model."""

    roots: list[SpecRoot]
    classes: dict[str, SpecClass]
    model_version: int = 0
    model_version_label: Optional[str] = None
    #: When the snapshot was exported (UTC), or ``None`` when it carries no
    #: ``generatedAt`` — an export predating the key, or a hand-built model.
    generated_at: Optional[_dt.datetime] = None
    #: The *file format's* own version, distinct from :attr:`model_version`
    #: (which model the snapshot describes). ``None`` when undeclared.
    meta_schema_version: Optional[int] = None
    #: The class count the snapshot declares, or ``None`` when undeclared.
    #:
    #: Kept separate from ``len(classes)``: the declared value is what the
    #: exporter recorded, the actual value is what survived to the reader, and
    #: comparing them is the point (:meth:`check_stamp`).
    class_count: Optional[int] = None
    #: The document-root count the snapshot declares, or ``None`` when
    #: undeclared.
    root_count: Optional[int] = None
    #: The canonical container class — the single true tree root, which is not
    #: itself a document and so does not appear in :attr:`roots`. ``None`` when
    #: the model has no container (e.g. a synthetic export).
    container_root: Optional[str] = None

    def check_stamp(
        self,
        max_age: _dt.timedelta = DEFAULT_MAX_SNAPSHOT_AGE,
        now: Optional[_dt.datetime] = None,
    ) -> "SpecModelStampCheck":
        """Check the generation stamp against the payload and the clock.

        *now* is injectable so callers (and tests) can evaluate age against a
        fixed instant instead of the wall clock."""
        moment = now or _dt.datetime.now(_dt.timezone.utc)
        if moment.tzinfo is None:
            moment = moment.replace(tzinfo=_dt.timezone.utc)
        return SpecModelStampCheck(
            age=None if self.generated_at is None else moment - self.generated_at,
            max_age=max_age,
            declared_class_count=self.class_count,
            actual_class_count=len(self.classes),
            declared_root_count=self.root_count,
            actual_root_count=len(self.roots),
        )

    @property
    def model_version_string(self) -> str:
        """The DocSpecs schema-version string of this model (the Dart
        ``modelVersionString``). Falls back to ``<model_version>.0`` for an
        unstamped model."""
        return som_model_version_string(
            self.model_version, self.model_version_label
        )

    def class_named(self, name: Optional[str]) -> Optional[SpecClass]:
        if name is None:
            return None
        return self.classes.get(name)

    def is_generation_input(self, root: SpecRoot) -> bool:
        """Whether *root* is a generation input rather than a document an
        author fills (the Dart ``isGenerationInput``).

        A generation input is an ``@Document`` root whose audience is a
        generator, not a spec author: it projects existing Solution Blueprint
        sections into the shape a downstream phase consumes.

        Derived from the class's ``@CodeSpecsProjection()`` marker, so the
        classification stays single-sourced in the model — a consumer that
        hard-coded the root's type name would silently misclassify the next
        projection to be added. A root whose class is absent from
        :attr:`classes` is *not* a generation input: an unknown class is not
        evidence."""
        cls = self.class_named(root.type)
        return cls is not None and cls.has_annotation("CodeSpecsProjection")

    def root_by_type(self, type: str) -> SpecRoot:
        """The document root whose :attr:`SpecRoot.type` equals *type*
        (SOM §21).

        Replaces the recurring ``next(r for r in roots if r.type == …)``
        boilerplate. Raises :class:`ValueError` when no root carries that type,
        with a message that names the missing type and the ones that do
        exist."""
        for r in self.roots:
            if r.type == type:
                return r
        available = ", ".join(r.type for r in self.roots)
        raise ValueError(
            f"no document root with type {type!r} (have: {available})"
        )

    @staticmethod
    def from_json(j: dict[str, Any]) -> "SpecModel":
        classes = {
            name: SpecClass.from_json(value)
            for name, value in j["classes"].items()
        }
        roots = [SpecRoot.from_json(e) for e in j["roots"]]
        label = j.get("modelVersionLabel")
        container_root = j.get("containerRoot")
        return SpecModel(
            roots=roots,
            classes=classes,
            model_version=int(j.get("modelVersion") or 0),
            model_version_label=label if label else None,
            generated_at=parse_stamp_timestamp(j.get("generatedAt")),
            meta_schema_version=_optional_int(j.get("metaSchemaVersion")),
            class_count=_optional_int(j.get("classCount")),
            root_count=_optional_int(j.get("rootCount")),
            container_root=container_root if container_root else None,
        )
