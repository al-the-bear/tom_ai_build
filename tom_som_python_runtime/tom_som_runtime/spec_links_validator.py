"""The link checks of one document (`tom_specs_model_rules.md` §9.7):
:func:`validate_links` holds a document's values to the link annotations of the
model — derived values to their sources, summaries to their detail lists, each
end of a link to the other, the ids named in a text to the link rows, and a
``@SameAs`` copy to its holder. A port of
`tom_som_dart_runtime/lib/src/spec_links_validator.dart`.

Values are read in their reviewed state: a value holding pending change marks
is read with every mark rejected, and listed as ``linkValuePending``. A
``@SummaryOf`` naming another document is skipped here; the document set
checks it.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any, Optional, Union

from .spec_document import SpecDocument
from .spec_model import (
    FormFieldSpec,
    SpecClass,
    SpecDerivation,
    SpecField,
    SpecFieldKind,
    SpecInverseOf,
    SpecModel,
    SpecSummaryOf,
)
from .spec_place import (
    SpecPlace,
    SpecPlaceException,
    SpecPlaceFilter,
    SpecPlaceKind,
    SpecPlaceResolution,
    spec_same_as_bindings,
)
from .spec_reflection import SpecNodeKind, SpecReflection
from .spec_review_annotations import K_SPEC_HEADLINE_FIELD, apply_inline_marks_text
from .spec_section_id import K_SECTION_ID_SLOT, effective_list_item_section_id
from .spec_typed_values import _trimmed
from .spec_validator import (
    SpecValidationCode,
    SpecValidationError,
    spec_validation_code_index,
)


def validate_links(model: SpecModel, doc: SpecDocument) -> list[SpecValidationError]:
    """Runs the link checks of *doc* against *model*; the findings sorted by
    path, then by code (declaration order), then by message."""
    v = SpecLinkValidator(model, doc)
    v.run()
    return sorted(
        v.errors,
        key=lambda e: (e.path, spec_validation_code_index(e.code), e.message),
    )


def spec_expand_pattern(doc: SpecDocument, pattern: str) -> list[str]:
    """Every concrete path of *pattern* in *doc*: each ``<list>-*`` segment
    expanded over the document's items."""
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


def spec_resolve_place_at(
    refl: SpecReflection, place: str, anchor: str
) -> Optional[SpecPlaceResolution]:
    """*place* resolved under *anchor*, or ``None`` when it does not
    resolve."""
    try:
        return SpecPlace.parse(place).resolve(refl, anchor)
    except SpecPlaceException:
        return None


def spec_resolve_link_place(
    refl: SpecReflection,
    doc: Optional[SpecDocument],
    place: str,
    root: str,
    anchor: str,
) -> Optional[SpecPlaceResolution]:
    """*place* resolved for a link annotated at *anchor*, as the link checks
    and the rendition's ``linked`` marker (SOM §11.11) read it: a ``./`` place
    beneath the nearest list element of *anchor*; any other place inside
    *anchor*'s subtree when it is there, else anywhere beneath the document
    root *root* — a bare id wherever it is reached once, a ``/`` path from the
    section its first segment names, through the first item *doc* holds of a
    list there (no *doc*: such a path does not resolve)."""
    if place.startswith("./"):
        return spec_resolve_place_at(refl, place, anchor)
    # The grammar's own scope first: the subtree of the annotated section.
    local = None if anchor == root else spec_resolve_place_at(refl, place, anchor)
    if local is not None:
        return local
    slash = place.find("/")
    if slash < 0:
        return spec_resolve_place_at(refl, place, root)
    head = spec_resolve_place_at(refl, place[:slash], root)
    if head is None:
        return None
    scope = f"{head.path}-*" if head.kind == SpecPlaceKind.LIST else head.path
    # A pattern anchor resolves through its first concrete instance; the rest
    # of the place is relative, so the pattern is rebuilt below.
    if doc is None:
        concrete = [] if "-*" in scope else [scope]
    else:
        concrete = spec_expand_pattern(doc, scope)
    if not concrete:
        return None
    rest = spec_resolve_place_at(refl, place[slash + 1:], concrete[0])
    if rest is None:
        return None
    return SpecPlaceResolution(
        place=rest.place,
        kind=rest.kind,
        path=scope + rest.path[len(concrete[0]):],
        class_name=rest.class_name,
        section_ids=rest.section_ids,
        form_field=rest.form_field,
    )


@dataclass(frozen=True)
class SpecLinkFix:
    """What ``deriveFields`` would write for one link finding (internal to the
    runtime; collected by :class:`SpecLinkValidator` beside the finding).

    Kinds: ``set`` (the value at :attr:`path` / :attr:`field`, ``None`` field:
    content), ``append`` (add :attr:`value` to the ids of the reference
    field), ``addRow`` (add a row to the list at :attr:`path`:
    ``<member>#<field>`` → value), ``removeRow`` (the row at :attr:`path`;
    :attr:`empty`: it holds no value already), ``list`` (make the list at
    :attr:`path` hold one element per tuple), ``copy`` (write the copy at
    :attr:`path` from :attr:`holder`)."""

    step: int
    kind: str
    path: str
    field: Optional[str] = None
    value: Optional[str] = None
    values: Optional[dict[str, str]] = None
    tuples: Optional[list[dict[str, str]]] = None
    holder: Optional[str] = None
    empty: bool = False

    @staticmethod
    def set(step: int, path: str, field: Optional[str], value: str) -> "SpecLinkFix":
        """Set the value at *path* / *field* to *value*."""
        return SpecLinkFix(step=step, kind="set", path=path, field=field, value=value)

    @staticmethod
    def append(path: str, field: Optional[str], value: str) -> "SpecLinkFix":
        """Add *value* to the ids of the reference field at *path* /
        *field*."""
        return SpecLinkFix(step=1, kind="append", path=path, field=field, value=value)

    @staticmethod
    def add_row(step: int, path: str, values: dict[str, str]) -> "SpecLinkFix":
        """Add a row to the list at *path*: ``<member>#<field>`` (or
        ``<member>``, a content value) → value."""
        return SpecLinkFix(step=step, kind="addRow", path=path, values=values)

    @staticmethod
    def remove_row(path: str, empty: bool = False) -> "SpecLinkFix":
        """Remove the row at *path*; *empty*: it holds no value already."""
        return SpecLinkFix(step=1, kind="removeRow", path=path, empty=empty)

    @staticmethod
    def list(path: str, tuples: Any) -> "SpecLinkFix":
        """Make the list at *path* hold one element per tuple (target place →
        value)."""
        return SpecLinkFix(step=2, kind="list", path=path, tuples=tuples)

    @staticmethod
    def copy(path: str, holder: str) -> "SpecLinkFix":
        """Write the copy at *path* from the *holder*."""
        return SpecLinkFix(step=2, kind="copy", path=path, holder=holder)


_INT_TEXT = re.compile(r"[+-]?\d+")
_FLOAT_TEXT = re.compile(r"[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?")
_HEX_TEXT = re.compile(r"0[xX][0-9a-fA-F]+")


def _num_try_parse(text: str) -> Optional[Union[int, float]]:
    """Dart's ``num.tryParse`` (decimal forms; surrounding whitespace
    allowed)."""
    t = _trimmed(text)
    if _INT_TEXT.fullmatch(t):
        return int(t, 10)
    if _FLOAT_TEXT.fullmatch(t):
        return float(t)
    if _HEX_TEXT.fullmatch(t):
        return int(t, 16)
    if t == "NaN":
        return float("nan")
    if t in ("Infinity", "-Infinity"):
        return float("inf") if t == "Infinity" else float("-inf")
    return None


def _int_try_parse(text: str) -> Optional[int]:
    """Dart's ``int.tryParse`` (decimal, optional sign, surrounding
    whitespace)."""
    t = _trimmed(text)
    return int(t, 10) if _INT_TEXT.fullmatch(t) else None


#: An id as text names it: letters, digits and inner hyphens.
_ID_TOKEN = re.compile(r"[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]|[A-Za-z0-9]")

#: The trailing whitespace of a line (``\s+$``).
_TRAILING_SPACE = re.compile(r"\s+$")


@dataclass(frozen=True)
class _Instance:
    path: str
    cls: SpecClass
    root: str


@dataclass(frozen=True)
class _Scalar:
    path: str
    field: Optional[str]
    d: SpecDerivation
    anchor: str
    root: str
    spec: Optional[FormFieldSpec]


class SpecLinkValidator:
    """The link checker of one document (internal to the runtime:
    :func:`validate_links` runs it, ``deriveFields`` reads its :attr:`fixes`
    and value readers)."""

    def __init__(
        self, model: SpecModel, doc: SpecDocument, read_proposed: bool = False
    ) -> None:
        #: What ``deriveFields`` would write for each finding, collected beside
        #: it.
        self.fixes: list[SpecLinkFix] = []
        self.errors: list[SpecValidationError] = []
        self._reported: set[str] = set()
        self._pending: set[str] = set()
        #: Derived values computed so far (``path#field`` → value), read before
        #: the stored value so a derivation from a derived place sees its
        #: derived value.
        self._derived: dict[str, str] = {}
        #: The effective section id per list item path (writable by
        #: ``deriveFields``).
        self.item_ids: dict[str, str] = {}
        self._items: dict[str, bool] = {}
        self._forms_by_owner: Optional[dict[str, list[str]]] = None
        self._entries_cache: dict[str, dict[str, str]] = {}
        self._valued: Optional[set[str]] = None
        self.model = model
        self.doc = doc
        self.refl = SpecReflection(model)
        #: Read values with their pending marks accepted (the proposal), as
        #: ``deriveFields`` does in a document under review, instead of the
        #: reviewed state; no value is then listed as pending.
        self.read_proposed = read_proposed

    def report(self, code: SpecValidationCode, path: str, message: str) -> None:
        key = f"{code.value} {path} {message}"
        if key not in self._reported:
            self._reported.add(key)
            self.errors.append(SpecValidationError(path=path, code=code, message=message))

    # -------------------------------------------------------------------------
    # The document's instances
    # -------------------------------------------------------------------------

    def run(self) -> "SpecLinkValidator":
        instances: list[_Instance] = []
        for root in self.model.roots:
            seg = self.refl.root_segment(root)
            if not self._populated(seg):
                continue
            cls = self.refl.class_named(root.type)
            if cls is None:
                continue
            self._walk(cls, seg, seg, instances, set())
        self._check_derivations(instances)
        for i in instances:
            for f in i.cls.fields:
                self._check_summary(i, f)
                self._check_extracts(i, f)
                for ff in f.form_fields:
                    form = self._form_path(i, f)
                    if ff.inverse_of is not None:
                        self._check_inverse(form, ff)
                    if ff.summary_of is not None:
                        self._check_field_summary(i, form, ff)
        for root in self.model.roots:
            seg = self.refl.root_segment(root)
            if self._populated(seg):
                self._check_same_as(root.type)
        return self

    def _populated(self, seg: str) -> bool:
        def under(paths: Any) -> bool:
            return any(p == seg or p.startswith(f"{seg}/") for p in paths)

        return (
            under(self.doc.content_paths)
            or under(self.doc.form_paths)
            or under(self.doc.list_paths)
            or under(self.doc.headline_paths)
        )

    def _walk(
        self,
        cls: SpecClass,
        path: str,
        root: str,
        out: list[_Instance],
        on_path: set[str],
    ) -> None:
        out.append(_Instance(path=path, cls=cls, root=root))
        for f in cls.fields:
            member_path = f"{path}/{self.refl.field_segment(f)}"
            if f.has_annotation("Reference"):
                continue
            if f.kind == SpecFieldKind.LIST and f.element_is_complex:
                el = self.refl.class_named(f.element_type)
                if el is None:
                    continue
                for item in self.doc.list_items(member_path):
                    self._walk(el, item, root, out, set())
            elif f.kind in (SpecFieldKind.COMPLEX, SpecFieldKind.SECTION):
                child = self.refl.class_named(
                    f.type.replace("?", "") if f.type is not None else None
                )
                if child is None or child.name in on_path:
                    continue
                self._walk(child, member_path, root, out, on_path | {cls.name})

    def _form_path(self, i: _Instance, f: SpecField) -> str:
        return f"{i.path}/{self.refl.field_segment(f)}"

    # -------------------------------------------------------------------------
    # Reading values
    # -------------------------------------------------------------------------

    def _reviewed(self, raw: Optional[str], path: str, what: str) -> str:
        """The reviewed reading of a raw value; a value with pending marks is
        listed once."""
        if raw is None:
            return ""
        if self.read_proposed:
            return _trimmed(apply_inline_marks_text(raw, accept=True))
        rejected = apply_inline_marks_text(raw, accept=False)
        key = f"{path} {what}"
        if (
            apply_inline_marks_text(raw, accept=True) != rejected
            and key not in self._pending
        ):
            self._pending.add(key)
            self.report(
                SpecValidationCode.LINK_VALUE_PENDING,
                path,
                f"{what} holds pending change marks; it is read with every mark "
                "rejected",
            )
        return _trimmed(rejected)

    def form_value(self, path: str, field: str) -> str:
        """The value of form field *field* at *path* (derived first, then
        reviewed)."""
        key = f"{path}#{field}"
        if key in self._derived:
            return self._derived[key]
        return self._reviewed(self.doc.form_field(path, field), path, f'form field "{field}"')

    def content_value(self, path: str) -> str:
        """The content value at *path* (derived first, then reviewed)."""
        key = f"{path}#"
        if key in self._derived:
            return self._derived[key]
        return self._reviewed(self.doc.content(path), path, "the content")

    def headline_value(self, path: str) -> str:
        """The headline at *path*, reviewed."""
        return self._reviewed(self.doc.headline(path), path, "the headline")

    def item_id(self, item_path: str) -> str:
        """The effective section id of the list item at *item_path*."""
        id_ = self.item_ids.get(item_path)
        if id_ is None:
            id_ = self._compute_item_id(item_path)
            self.item_ids[item_path] = id_
        return id_

    def _compute_item_id(self, item_path: str) -> str:
        stored = self.doc.item_section_id(item_path)
        if stored is not None:
            return stored
        lst = item_path[: item_path.rfind("-")]
        items = self.doc.list_items(lst)
        res = self.refl.resolve(lst)
        f = res.field if res is not None else None
        return effective_list_item_section_id(
            stored_id=None,
            pattern=f.section_id_pattern if f is not None else None,
            position=(items.index(item_path) if item_path in items else -1) + 1,
            fallback_stem=f.name if f is not None else lst.split("/")[-1],
        )

    def is_item(self, path: str) -> bool:
        """Whether *path* is a complex list item."""
        hit = self._items.get(path)
        if hit is None:
            r = self.refl.resolve(path)
            hit = r is not None and r.kind == SpecNodeKind.LIST_ITEM_COMPLEX
            self._items[path] = hit
        return hit

    def value(self, r: SpecPlaceResolution, path: str) -> str:
        """The value a resolved place holds at its concrete *path*."""
        if r.kind == SpecPlaceKind.FORM_FIELD:
            assert r.field is not None
            return self.form_value(path, r.field)
        if r.kind == SpecPlaceKind.CONTENT:
            return self.content_value(path)
        if r.kind == SpecPlaceKind.HEADLINE:
            return self.headline_value(path)
        if r.kind == SpecPlaceKind.SECTION_ID:
            return self.item_id(path) if self.is_item(path) else ""
        return ""

    def expand(self, pattern: str) -> list[str]:
        """Every concrete path of a resolved pattern."""
        return spec_expand_pattern(self.doc, pattern)

    def at(self, place: str, anchor: str) -> Optional[SpecPlaceResolution]:
        """*place* resolved under *anchor*, or ``None`` when it does not
        resolve."""
        return spec_resolve_place_at(self.refl, place, anchor)

    def _global(self, place: str, root: str, anchor: str) -> Optional[SpecPlaceResolution]:
        """*place* resolved for a link annotated at *anchor*
        (:func:`spec_resolve_link_place`)."""
        return spec_resolve_link_place(self.refl, self.doc, place, root, anchor)

    def own_values(self, row: str, field: str) -> list[str]:
        """The values a row's own forms (``<row>/<member>``) hold in
        *field*."""
        if self._forms_by_owner is None:
            by_owner: dict[str, list[str]] = {}
            for p in self.doc.form_paths:
                slash = p.rfind("/")
                if slash > 0:
                    by_owner.setdefault(p[:slash], []).append(p)
            self._forms_by_owner = by_owner
        return [
            self.form_value(p, field)
            for p in self._forms_by_owner.get(row, [])
            if self.doc.form_field(p, field) is not None
        ]

    def _passes(self, where: Optional[str], row: str) -> bool:
        if where is None:
            return True
        f = SpecPlaceFilter.try_parse(where)
        if f is None or f.field is None:
            return True
        return f.matches(self.own_values(row, f.field))

    def nearest_item(self, path: str) -> Optional[str]:
        """The nearest list item at or above *path* (itself included)."""
        p = path
        while True:
            if self.is_item(p):
                return p
            slash = p.rfind("/")
            if slash < 0:
                return None
            p = p[:slash]

    @staticmethod
    def ids(value: str) -> list[str]:
        """The comma-separated ids of *value*, trimmed, empty ones dropped."""
        return [_trimmed(s) for s in value.split(",") if _trimmed(s) != ""]

    # -------------------------------------------------------------------------
    # @DerivedFrom and derivedFrom:
    # -------------------------------------------------------------------------

    def _check_derivations(self, instances: list[_Instance]) -> None:
        scalar: list[_Scalar] = []
        for i in instances:
            for f in i.cls.fields:
                d = f.derived_from
                member_path = self._form_path(i, f)
                if d is not None:
                    if f.kind == SpecFieldKind.LIST:
                        self._check_derived_list(i, member_path, d)
                    elif f.kind == SpecFieldKind.CONTENT:
                        scalar.append(_Scalar(member_path, None, d, i.path, i.root, None))
                for ff in f.form_fields:
                    q = ff.derived_from
                    if q is None:
                        continue
                    scalar.append(_Scalar(member_path, ff.name, q, i.path, i.root, ff))
        # Dependency order: every derivation is recomputed from the values the
        # ones before it gave, until nothing moves. DERIVE-ACYCLIC bounds the
        # rounds by the number of derivations.
        expected: dict[int, Optional[str]] = {}
        for _round in range(len(scalar) + 1):
            moved = False
            for k, t in enumerate(scalar):
                value = self._derive(t.d, t.anchor, t.root, t.spec, t.path)
                # Dart's `expected[k] != value`: an absent key reads as null.
                if expected.get(k) != value:
                    expected[k] = value
                    moved = True
                    if value is not None:
                        self._derived[f"{t.path}#{t.field if t.field is not None else ''}"] = value
            if not moved:
                break
        self._derived.clear()
        for k, t in enumerate(scalar):
            want = expected.get(k)
            if want is None:
                continue
            have = (
                self.content_value(t.path)
                if t.field is None
                else self.form_value(t.path, t.field)
            )
            if not SpecLinkValidator._same_value(have, want, t.spec):
                self.fixes.append(SpecLinkFix.set(2, t.path, t.field, want))
            if have == "":
                continue  # not derived yet: deriveFields writes it
            if not SpecLinkValidator._same_value(have, want, t.spec):
                what = "the content" if t.field is None else f'form field "{t.field}"'
                self.report(
                    SpecValidationCode.DERIVED_VALUE_MISMATCH,
                    t.path,
                    f"{what} is derived ({t.d.kind} of {t.d.source}) as "
                    f'"{want}", but holds "{have}"',
                )

    @staticmethod
    def _same_value(a: str, b: str, spec: Optional[FormFieldSpec]) -> bool:
        if spec is not None and spec.multiple and spec.refers_to:
            return set(SpecLinkValidator.ids(a)) == set(SpecLinkValidator.ids(b))
        t = spec.type if spec is not None else None
        if t in ("int", "double", "num"):
            x = _num_try_parse(a)
            y = _num_try_parse(b)
            if x is not None and y is not None:
                return x == y

        def norm(s: str) -> str:
            return _trimmed("\n".join(_TRAILING_SPACE.sub("", ln) for ln in s.split("\n")))

        return norm(a) == norm(b)

    def _rows(self, d: SpecDerivation, anchor: str, root: str) -> Optional[list[str]]:
        """The rows a ``rows`` / ``lookup`` derivation reads, in document
        order; ``None`` when the document's root does not reach the source
        (undecidable here)."""
        src = self._global(d.source, root, anchor)
        if src is None:
            return None
        key_by = d.key is not None and d.by is not None
        by_value = self.place_value(d.by, anchor) if key_by and d.by is not None else None
        return [
            row
            for row in self.expand(src.path)
            if self._passes(d.where, row)
            and (not key_by or self.place_value(d.key or "", row) == by_value)
        ]

    def place_value(self, place: str, anchor: str) -> str:
        """The value of *place* resolved under the concrete *anchor*."""
        r = self.at(place, anchor)
        if r is None:
            return ""
        paths = self.expand(r.path)
        return self.value(r, paths[0]) if len(paths) == 1 else ""

    def _derive(
        self,
        d: SpecDerivation,
        anchor: str,
        root: str,
        spec: Optional[FormFieldSpec],
        target_path: str,
    ) -> Optional[str]:
        """The value a scalar derivation gives, or ``None`` when
        undecidable."""
        if d.kind == "copy":
            src = self._global(d.source, root, anchor)
            if src is None:
                return None
            paths = self.expand(src.path)
            return self.value(src, paths[0]) if len(paths) == 1 else None
        if d.kind == "rows":
            rows = self._rows(d, anchor, root)
            if rows is None:
                return None
            if spec is not None and spec.multiple:
                out: list[str] = []
                for row in rows:
                    for t in d.take:
                        out.extend(SpecLinkValidator.ids(self.place_value(t, row)))
                return ", ".join(out)
            lines = []
            for row in rows:
                line = " — ".join(
                    v for v in (self.place_value(t, row) for t in d.take) if v != ""
                )
                if line != "":
                    lines.append(line)
            return "\n".join(lines)
        if d.kind == "lookup":
            rows = self._rows(d, anchor, root)
            if rows is None:
                return None
            key_by = d.key is not None and d.by is not None
            if key_by and len(rows) != 1:
                self.report(
                    SpecValidationCode.DERIVED_LOOKUP_MISS,
                    target_path,
                    f"the lookup in {d.source} by {d.key} = "
                    f'"{self.place_value(d.by or "", anchor)}" finds {len(rows)} '
                    "rows, not one",
                )
                return None
            if not rows:
                return ""
            row = rows[-1]
            return " — ".join(
                v for v in (self.place_value(t, row) for t in d.take) if v != ""
            )
        return None

    def _check_derived_list(self, i: _Instance, list_path: str, d: SpecDerivation) -> None:
        """A ``@DerivedFrom.rows`` with ``map`` on a list: one element per
        row."""
        map_entries = list(d.map.items())
        if d.kind != "rows" or not map_entries:
            return
        elements = self.doc.list_items(list_path)
        rows = self._rows(d, i.path, i.root)
        if rows is None:
            return  # the source is not in this document
        wanted = [{k: self.place_value(v, row) for k, v in map_entries} for row in rows]
        current = [{k: self.place_value(k, el) for k, _ in map_entries} for el in elements]

        def key(t: dict[str, str]) -> str:
            return " | ".join(t.get(k, "null") for k, _ in map_entries)

        if sorted(key(t) for t in wanted) != sorted(key(t) for t in current):
            self.fixes.append(SpecLinkFix.list(list_path, wanted))
        if not elements:
            return  # not derived yet
        want = sorted(
            " | ".join(self.place_value(v, row) for _, v in map_entries) for row in rows
        )
        have = sorted(
            " | ".join(self.place_value(k, el) for k, _ in map_entries) for el in elements
        )
        if want != have:
            self.report(
                SpecValidationCode.DERIVED_VALUE_MISMATCH,
                list_path,
                f"the list is derived (rows of {d.source}) as [{'; '.join(want)}], "
                f"but holds [{'; '.join(have)}]",
            )

    # -------------------------------------------------------------------------
    # @SummaryOf and summaryOf:
    # -------------------------------------------------------------------------

    def _detail_elements(self, s: SpecSummaryOf, root: str) -> Optional[dict[str, str]]:
        """The detail elements of a summary: item path → id."""
        r = self._global(s.detail, root, root)
        if r is None or r.kind != SpecPlaceKind.LIST:
            return None
        out: dict[str, str] = {}
        for lst in self.expand(r.path):
            for item in self.doc.list_items(lst):
                out[item] = self.item_id(item)
        return out

    def _check_summary(self, i: _Instance, f: SpecField) -> None:
        s = f.summary_of
        if s is None or s.document is not None or f.kind != SpecFieldKind.LIST:
            return
        detail = self._detail_elements(s, i.root)
        if detail is None:
            return
        by_id: dict[str, str] = {}
        for item, id_ in detail.items():
            by_id[id_] = item
        named: dict[str, str] = {}
        for el in self.doc.list_items(self._form_path(i, f)):
            ids = (
                [self.item_id(el)]
                if s.match is None
                else SpecLinkValidator.ids(self.place_value(s.match, el))
            )
            for id_ in ids:
                target = by_id.get(id_)
                if target is None:
                    self.report(
                        SpecValidationCode.SUMMARY_NOT_IN_DETAIL,
                        el,
                        f"the summary row names {id_}, which is no element of "
                        f"{s.detail}",
                    )
                    continue
                if id_ in named:
                    self.report(
                        SpecValidationCode.SUMMARY_DUPLICATE,
                        el,
                        f"the summary row names {id_}, which {named[id_]} names "
                        "already",
                    )
                    continue
                named[id_] = el
                self._check_repeats(s, el, target)
        if s.relation == "equal":
            for item, id_ in detail.items():
                if id_ not in named:
                    self.report(
                        SpecValidationCode.DETAIL_NOT_IN_SUMMARY,
                        item,
                        f"the detail element {id_} is named by no row of the "
                        f"summary {self._form_path(i, f)} (relation: equal)",
                    )

    def _check_repeats(self, s: SpecSummaryOf, row: str, detail: str) -> None:
        """The values a summary row repeats agree with its detail element's."""
        for mine_at, theirs_at in s.repeats.items():
            mine = self.at(mine_at, row)
            theirs = self.at(theirs_at, detail)
            if mine is None or theirs is None:
                continue
            mp = self.expand(mine.path)
            tp = self.expand(theirs.path)
            if len(mp) != 1 or len(tp) != 1:
                continue
            have = self.value(mine, mp[0])
            want = self.value(theirs, tp[0])
            if have != want:
                self.fixes.append(
                    SpecLinkFix.set(2, mp[0], SpecLinkValidator.field_of(mine), want)
                )
            if have == "":
                continue  # not repeated yet: deriveFields writes it
            if have != want:
                self.report(
                    SpecValidationCode.DERIVED_VALUE_MISMATCH,
                    mp[0],
                    f'{mine_at} repeats {theirs_at} of {detail} as "{have}", but '
                    f'the detail element holds "{want}"',
                )

    def _check_field_summary(self, i: _Instance, form: str, ff: FormFieldSpec) -> None:
        s = ff.summary_of
        if s is None or s.document is not None:
            return
        raw = self.doc.form_field(form, ff.name)
        if raw is None:
            return
        detail = self._detail_elements(s, i.root)
        if detail is None:
            return
        known = set(detail.values())
        seen: set[str] = set()
        for id_ in SpecLinkValidator.ids(self.form_value(form, ff.name)):
            if id_ not in known:
                self.report(
                    SpecValidationCode.SUMMARY_NOT_IN_DETAIL,
                    form,
                    f'form field "{ff.name}" names {id_}, which is no element of '
                    f"{s.detail}",
                )
            elif id_ in seen:
                self.report(
                    SpecValidationCode.SUMMARY_DUPLICATE,
                    form,
                    f'form field "{ff.name}" names {id_} twice',
                )
            else:
                seen.add(id_)
        if s.relation == "equal":
            for item, id_ in detail.items():
                if id_ not in seen:
                    self.report(
                        SpecValidationCode.DETAIL_NOT_IN_SUMMARY,
                        item,
                        f'the detail element {id_} is not named in "{ff.name}" of '
                        f"{form} (relation: equal)",
                    )

    # -------------------------------------------------------------------------
    # inverseOf:
    # -------------------------------------------------------------------------

    def entries(self, refers_to: list[str]) -> dict[str, str]:
        """The entries a reference field names, by its ``refersTo``
        registries: id → item path. An entry of ``<X>.@sectionId`` is named by
        its section id, one of ``<X>.<field>`` by the value its own forms hold
        in that field."""
        key = ",".join(refers_to)
        hit = self._entries_cache.get(key)
        if hit is None:
            hit = self._compute_entries(refers_to)
            self._entries_cache[key] = hit
        return hit

    def _compute_entries(self, refers_to: list[str]) -> dict[str, str]:
        out: dict[str, str] = {}
        for lst in sorted(self.doc.list_paths):
            for item in self.doc.list_items(lst):
                r = self.refl.resolve(item)
                id_ = (
                    r.target_class.section_id
                    if r is not None and r.target_class is not None
                    else None
                )
                if id_ is None:
                    continue
                for t in refers_to:
                    if t.split(".")[0] != id_:
                        continue
                    name = self.identity(item, t)
                    if name is not None and name != "" and name not in out:
                        out[name] = item
        return out

    def identity(self, item: str, target: str) -> Optional[str]:
        """How the registry key *target* (``<X>.@sectionId`` or
        ``<X>.<field>``) names the entry at *item*."""
        name = target[target.find(".") + 1:]
        if name == K_SECTION_ID_SLOT:
            return self.item_id(item)
        values = self.own_values(item, name)
        return values[0] if values else None

    def _owner(self, path: str, classes: set[str]) -> Optional[str]:
        """The nearest item at or above *path* whose class is one of
        *classes*."""
        p = self.nearest_item(path)
        while p is not None:
            r = self.refl.resolve(p)
            id_ = (
                r.target_class.section_id
                if r is not None and r.target_class is not None
                else None
            )
            if id_ is not None and id_ in classes:
                return p
            slash = p.rfind("/")
            if slash < 0:
                return None
            p = self.nearest_item(p[:slash])
        return None

    @staticmethod
    def _registry_classes(refers_to: list[str]) -> set[str]:
        return {t.split(".")[0] for t in refers_to}

    def _first_identity(self, owner: str, refers_to: list[str]) -> Optional[str]:
        for t in refers_to:
            id_ = self.identity(owner, t)
            if id_ is not None:
                return id_
        return None

    def _check_inverse(self, form: str, ff: FormFieldSpec) -> None:
        raw = self.doc.form_field(form, ff.name)
        if raw is None:
            return
        value = self.form_value(form, ff.name)
        if value == "":
            return
        inv = ff.inverse_of
        assert inv is not None
        entries = self.entries(ff.refers_to)
        if inv.symmetric:
            self._check_symmetric(form, ff, inv, value, entries)
            return
        # The entry this field belongs to, as the other ends name it.
        for b in SpecLinkValidator.ids(value):
            b_path = entries.get(b)
            if b_path is None:
                continue  # a registry this document does not hold
            resolved = False
            names_back = False
            a_id: Optional[str] = None
            writable: Optional[tuple[str, Optional[str]]] = None
            for end in inv.fields:
                r = self.at(end, b_path)
                if r is None or r.form_field is None:
                    continue
                owner = self._owner(
                    form, SpecLinkValidator._registry_classes(r.form_field.refers_to)
                )
                if owner is None:
                    continue
                if inv.where is not None and not self._passes(inv.where, owner):
                    return
                a_id = self._first_identity(owner, r.form_field.refers_to)
                if a_id is None:
                    continue
                resolved = True
                ends = self.expand(r.path)
                if ends and writable is None:
                    writable = (ends[0], r.field)
                for p in ends:
                    if a_id in SpecLinkValidator.ids(self.form_value(p, r.field or "")):
                        names_back = True
            if resolved and not names_back and writable is not None and a_id is not None:
                self.fixes.append(SpecLinkFix.append(writable[0], writable[1], a_id))
            if resolved and not names_back:
                self.report(
                    SpecValidationCode.INVERSE_MISSING,
                    form,
                    f'form field "{ff.name}" names {b}, but {b} does not name '
                    f"{a_id} back ({', '.join(inv.fields)})",
                )

    def _check_symmetric(
        self,
        form: str,
        ff: FormFieldSpec,
        inv: SpecInverseOf,
        value: str,
        entries: dict[str, str],
    ) -> None:
        row = self.nearest_item(form)
        if row is None or not self._passes(inv.where, row):
            return
        a = self._owner(row[: row.rfind("/")], SpecLinkValidator._registry_classes(ff.refers_to))
        if a is None:
            return
        a_id = self._first_identity(a, ff.refers_to)
        if a_id is None:
            return
        filt = None if inv.where is None else SpecPlaceFilter.try_parse(inv.where)
        filter_field = filt.field if filt is not None else None
        where_values = set() if filter_field is None else set(self.own_values(row, filter_field))

        # The same place beneath the named entry, every row of it.
        def generalise(s: str) -> str:
            dash = s.rfind("-")
            if dash > 0 and _int_try_parse(s[dash + 1:]) is not None:
                return f"{s[:dash]}-*"
            return s

        rel = "/".join(generalise(s) for s in form[len(a):].split("/"))
        for b in SpecLinkValidator.ids(value):
            b_path = entries.get(b)
            if b_path is None or b_path == a:
                continue

            def is_counterpart(p: str) -> bool:
                r = self.nearest_item(p)
                if r is None or not self._passes(inv.where, r):
                    return False
                if filter_field is not None:
                    own = set(self.own_values(r, filter_field))
                    if not where_values <= own:
                        return False
                return a_id in SpecLinkValidator.ids(self.form_value(p, ff.name))

            counterpart = any(is_counterpart(p) for p in self.expand(f"{b_path}{rel}"))
            if not counterpart:
                star = rel.find("-*")
                if star > 0:
                    lst = f"{b_path}{rel[:star]}"
                    below = rel[star + 3:]
                    values = {f"{below}#{ff.name}": a_id}
                    if filter_field is not None:
                        for p in self._own_forms(row):
                            if self.doc.form_field(p, filter_field) is not None:
                                values[f"{p[len(row) + 1:]}#{filter_field}"] = (
                                    self.form_value(p, filter_field)
                                )
                    self.fixes.append(SpecLinkFix.add_row(1, lst, values))
                self.report(
                    SpecValidationCode.INVERSE_MISSING,
                    form,
                    f"the row names {b}, but {b} holds no row naming {a_id} back"
                    f"{'' if inv.where is None else f' ({inv.where})'}",
                )

    # -------------------------------------------------------------------------
    # @ExtractsLinks and the link rows
    # -------------------------------------------------------------------------

    def _check_extracts(self, i: _Instance, f: SpecField) -> None:
        all_ = f.extracts_links
        if not all_ or f.kind != SpecFieldKind.LIST:
            return
        list_path = self._form_path(i, f)
        rows = self.doc.list_items(list_path)
        element = self.nearest_item(i.path)
        own = None if element is None else self.item_id(element)

        # A link row holding no value at all (what accepting the marked removal
        # of a row leaves) is removed.
        for row in rows:
            if not self.holds_value(row):
                self.fixes.append(SpecLinkFix.remove_row(row, True))

        # The ids each row names, and its type (the values `set` writes).
        set_keys = sorted({k for e in all_ for k in e.set})
        named: dict[str, list[str]] = {}
        seen: dict[str, str] = {}
        for row in rows:
            ids: list[str] = []
            for e in all_:
                r = self.at(e.ref, row)
                if r is None:
                    continue
                for p in self.expand(r.path):
                    ids.extend(SpecLinkValidator.ids(self.value(r, p)))
            unique = list(dict.fromkeys(ids))
            named[row] = unique
            type_ = " | ".join(self.place_value(k, row) for k in set_keys)
            for id_ in unique:
                key = f"{id_} // {type_}"
                first = seen.get(key)
                if first is not None:
                    self.report(
                        SpecValidationCode.DUPLICATE_LINK_ROW,
                        row,
                        f'the row names {id_} with the type "{type_}", as {first} '
                        "does",
                    )
                else:
                    seen[key] = row
        rowed = {id_ for ids in named.values() for id_ in ids}

        for e in all_:
            if not rows:
                ref_spec = self._ref_spec_from_model(f, e.ref)
            else:
                r = self.at(e.ref, rows[0])
                ref_spec = r.form_field if r is not None else None
            if ref_spec is None:
                continue
            registry = set(self.entries(ref_spec.refers_to))
            found: list[str] = []
            for place in e.from_:
                p = place if place.startswith("./") else f"./{place}"
                r = self.at(p, i.path)
                if r is None:
                    continue
                for path in self.expand(r.path):
                    for id_ in SpecLinkValidator._ids_in(self.value(r, path), registry):
                        if id_ != own and id_ not in found:
                            found.append(id_)
            for id_ in found:
                if id_ in rowed:
                    continue
                if e.mode == "generate":
                    values: dict[str, str] = {}
                    writes = {e.ref: id_}
                    writes.update(e.set)
                    for k, v in writes.items():
                        r = self.at(k, f"{list_path}-0")
                        if r is None or r.field is None:
                            continue
                        rel = r.path[len(f"{list_path}-0") + 1:]
                        values[f"{rel}#{r.field}"] = v
                    self.fixes.append(SpecLinkFix.add_row(1, list_path, values))
                self.report(
                    SpecValidationCode.EXTRACTED_LINK_MISSING,
                    list_path,
                    f"{id_} is named in {' / '.join(e.from_)} but has no row"
                    f"{' (warn: the agent adds it)' if e.mode == 'warn' else ''}",
                )
        # A generated row: every `set` value of a generate-mode use matches.
        for e in (x for x in all_ if x.mode == "generate"):
            mine: set[str] = set()
            for place in e.from_:
                p = place if place.startswith("./") else f"./{place}"
                r = self.at(p, i.path)
                if r is None:
                    continue
                ref_r = None if not rows else self.at(e.ref, rows[0])
                ref_spec = ref_r.form_field if ref_r is not None else None
                registry = (
                    set() if ref_spec is None else set(self.entries(ref_spec.refers_to))
                )
                for path in self.expand(r.path):
                    for id_ in SpecLinkValidator._ids_in(self.value(r, path), registry):
                        mine.add(id_)
            for row in rows:
                generated = all(self.place_value(k, row) == v for k, v in e.set.items())
                if not generated:
                    continue
                for id_ in named[row]:
                    if id_ not in mine:
                        self.fixes.append(SpecLinkFix.remove_row(row))
                        self.report(
                            SpecValidationCode.EXTRACTED_LINK_STALE,
                            row,
                            f"the generated row names {id_}, which "
                            f"{' / '.join(e.from_)} no longer names",
                        )

    def _ref_spec_from_model(self, lst: SpecField, ref: str) -> Optional[FormFieldSpec]:
        el = self.refl.class_named(lst.element_type)
        if el is None:
            return None
        dot = ref.find(".")
        if dot < 0:
            return None
        id_ = ref[:dot]
        name = ref[dot + 1:]
        for f in el.fields:
            fid = el.section_id if f.name == "content" else f.section_id
            if fid != id_:
                continue
            for ff in f.form_fields:
                if ff.name == name:
                    return ff
        return None

    @staticmethod
    def _ids_in(text: str, registry: set[str]) -> list[str]:
        """The ids of *registry* named in *text*, each matched exactly (not as
        a part of a longer id), in order of first appearance."""
        out: list[str] = []
        for m in _ID_TOKEN.finditer(text):
            id_ = m.group(0)
            if id_ in registry and id_ not in out:
                out.append(id_)
        return out

    # -------------------------------------------------------------------------
    # @SameAs
    # -------------------------------------------------------------------------

    def _check_same_as(self, root_type: str) -> None:
        for b in spec_same_as_bindings(self.refl, root_type):
            if b.holder_path is None:
                continue
            copies = self.expand(b.copy_path)
            holders = self.expand(b.holder_path)
            if len(copies) != len(holders):
                continue
            for c, h in zip(copies, holders):
                if self._compare_subtrees(c, h):
                    self.fixes.append(SpecLinkFix.copy(c, h))

    def subtree(self, root: str) -> dict[str, tuple[str, str]]:
        """Every value beneath *root* (itself included), keyed by its path
        relative to *root* with list items written by their section id, so
        two subtrees compare element by element; each ``(path, value)``."""

        def key(path: str) -> str:
            rel = "" if path == root else path[len(root) + 1:]
            if rel == "":
                return ""
            out: list[str] = []
            at = root
            for seg in rel.split("/"):
                at = f"{at}/{seg}"
                out.append(
                    f"{seg[: seg.rfind('-')]}[{self.item_id(at)}]"
                    if self.is_item(at)
                    else seg
                )
            return "/".join(out)

        def under(p: str) -> bool:
            return p == root or p.startswith(f"{root}/")

        out: dict[str, tuple[str, str]] = {}
        for p in self.doc.content_paths:
            if under(p):
                out[f"c:{key(p)}"] = (p, self.content_value(p))
        for p in self.doc.form_paths:
            if not under(p):
                continue
            for name in self.doc.form_field_names(p):
                out[f"f:{key(p)}#{name}"] = (p, self.form_value(p, name))
        for p in self.doc.headline_paths:
            if under(p):
                out[f"h:{key(p)}"] = (p, self.headline_value(p))
        for lst in self.doc.list_paths:
            if not under(lst):
                continue
            for item in self.doc.list_items(lst):
                out[f"i:{key(item)}"] = (item, self.item_id(item))
        return {k: v for k, v in out.items() if v[1] != ""}

    def _compare_subtrees(self, copy: str, holder: str) -> bool:
        """Reports every difference of *copy* from *holder*; whether there is
        one."""
        mine = self.subtree(copy)
        theirs = self.subtree(holder)
        keys = sorted(set(mine) | set(theirs))
        # An element on one side only is one finding; its values are not
        # compared.
        one_sided = [
            k[2:] for k in keys if k.startswith("i:") and ((k in mine) != (k in theirs))
        ]

        def beneath(k: str) -> bool:
            rel = k[2:].split("#")[0]
            return not k.startswith("i:") and any(
                rel == o or rel.startswith(f"{o}/") for o in one_sided
            )

        differs = False
        for k in keys:
            a = mine.get(k)
            b = theirs.get(k)
            av = a[1] if a is not None else None
            bv = b[1] if b is not None else None
            if av == bv or beneath(k):
                continue
            differs = True
            if k.startswith("i:"):
                what = f"element {(a if a is not None else b)[1]}"  # type: ignore[index]
            elif k.startswith("h:"):
                what = "the headline"
            elif k.startswith("c:"):
                what = "the content"
            else:
                what = f'form field "{k[k.find("#") + 1:]}"'
            self.report(
                SpecValidationCode.SAME_AS_MISMATCH,
                a[0] if a is not None else copy,
                f"the copy of {holder} differs in {what}: the copy holds "
                f'"{av if av is not None else ""}", the holder '
                f'"{bv if bv is not None else ""}"',
            )
        return differs

    # -------------------------------------------------------------------------
    # Helpers of the fixes
    # -------------------------------------------------------------------------

    @staticmethod
    def field_of(r: SpecPlaceResolution) -> Optional[str]:
        """The field a resolved value place names for a write: the form field,
        the headline's reserved field, or ``None`` for content."""
        if r.kind == SpecPlaceKind.FORM_FIELD:
            return r.field
        if r.kind == SpecPlaceKind.HEADLINE:
            return K_SPEC_HEADLINE_FIELD
        return None

    def _own_forms(self, row: str) -> list[str]:
        """The forms directly beneath *row* (``<row>/<member>``)."""
        return [
            p
            for p in self.doc.form_paths
            if p.startswith(f"{row}/") and "/" not in p[len(row) + 1:]
        ]

    def holds_value(self, path: str) -> bool:
        """Whether anything beneath *path* holds a value (marks included)."""
        if self._valued is None:
            valued: set[str] = set()

            def up(p: str, self_: bool = True) -> None:
                if self_:
                    cur = p
                else:
                    cur = p[: p.rfind("/")] if "/" in p else ""
                while cur != "" and cur not in valued:
                    valued.add(cur)
                    slash = cur.rfind("/")
                    cur = "" if slash < 0 else cur[:slash]

            doc = self.doc
            for p in doc.content_paths:
                if _trimmed(doc.content(p) or "") != "":
                    up(p)
            for p in doc.form_paths:
                if any(
                    _trimmed(doc.form_field(p, name) or "") != ""
                    for name in doc.form_field_names(p)
                ):
                    up(p)
            for p in doc.headline_paths:
                if (doc.headline(p) or "") != "":
                    up(p, False)
            for lst in doc.list_paths:
                if doc.list_items(lst):
                    up(lst)
            self._valued = valued
        return path in self._valued
