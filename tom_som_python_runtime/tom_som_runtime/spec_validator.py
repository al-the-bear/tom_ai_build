"""Validates a concrete :class:`SpecDocument`'s values against a
:class:`SpecModel` via the :class:`SpecReflection` resolver — a faithful port of
`tom_som_dart_runtime/lib/src/spec_validator.dart`.

The check is over the values a document *holds*: every set path must resolve to a
node of a compatible kind, every form sub-key must name a real form field, and
every populated list must meet its ``@Min`` item count. Schema completeness
(mandatory-but-absent nodes) is a separate concern and is not reported here.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Optional

from .spec_document import SpecDocument
from .spec_model import SpecClass, SpecField, SpecFieldKind, SpecModel
from .spec_reflection import SpecNodeKind, SpecReflection
from .spec_section_id import K_SECTION_ID_SLOT, effective_list_item_section_id


class SpecValidationCode(Enum):
    """Why a single value in a document is invalid against the model."""

    DANGLING_PATH = "danglingPath"
    KIND_MISMATCH = "kindMismatch"
    UNKNOWN_FORM_FIELD = "unknownFormField"
    MIN_ITEMS = "minItems"
    #: A ``@OneOf`` container carries a case-bound subsection that the chosen
    #: discriminator value does not select, or more than one subsection for the
    #: chosen case (``codespecs_mapping.md`` §8.2).
    ONE_OF_CASE_MISMATCH = "oneOfCaseMismatch"
    #: A reference form field (``FormFieldSpec.refers_to``) holds an id that no
    #: entry of any of its target registries declares.
    DANGLING_REFERENCE = "danglingReference"


@dataclass(frozen=True)
class SpecValidationError:
    """One problem found while validating a document."""

    path: str
    code: SpecValidationCode
    message: str

    def __str__(self) -> str:
        return f"[{self.code.value}] {self.path}: {self.message}"


def _dangling(path: str) -> SpecValidationError:
    return SpecValidationError(
        path=path,
        code=SpecValidationCode.DANGLING_PATH,
        message="path does not resolve to any model node",
    )


def validate_document(model: SpecModel, doc: SpecDocument) -> list[SpecValidationError]:
    """Validates *doc* against *model*. Returns an empty list when the document
    is valid; otherwise one :class:`SpecValidationError` per problem, in a stable
    order (content paths, then forms, then lists; each group sorted by path)."""
    refl = SpecReflection(model)
    errors: list[SpecValidationError] = []

    # 1. Content/scalar/enum leaves.
    for path in sorted(doc.content_paths):
        res = refl.resolve(path)
        if res is None:
            errors.append(_dangling(path))
            continue
        if not res.is_value_leaf:
            errors.append(
                SpecValidationError(
                    path=path,
                    code=SpecValidationCode.KIND_MISMATCH,
                    message=(
                        "expected a value leaf but path resolves to "
                        f"{res.kind.value}"
                    ),
                )
            )

    # 2. Form sections.
    for path in sorted(doc.form_paths):
        res = refl.resolve(path)
        if res is None:
            errors.append(_dangling(path))
            continue
        if res.kind != SpecNodeKind.FORM or res.field is None:
            errors.append(
                SpecValidationError(
                    path=path,
                    code=SpecValidationCode.KIND_MISMATCH,
                    message=(
                        "expected a form section but path resolves to "
                        f"{res.kind.value}"
                    ),
                )
            )
            continue
        declared = {ff.name for ff in res.field.form_fields}
        for name in sorted(doc.form_field_names(path)):
            if name not in declared:
                errors.append(
                    SpecValidationError(
                        path=path,
                        code=SpecValidationCode.UNKNOWN_FORM_FIELD,
                        message=(
                            f'form field "{name}" is not declared on '
                            f"{res.field.name}"
                        ),
                    )
                )

    # 3. Lists (container kind + `@Min` count on populated lists).
    for path in sorted(doc.list_paths):
        res = refl.resolve(path)
        if res is None:
            errors.append(_dangling(path))
            continue
        if res.kind != SpecNodeKind.LIST or res.field is None:
            errors.append(
                SpecValidationError(
                    path=path,
                    code=SpecValidationCode.KIND_MISMATCH,
                    message=f"expected a list but path resolves to {res.kind.value}",
                )
            )
            continue
        minimum = res.field.min
        count = doc.list_item_count(path)
        if minimum is not None and count < minimum:
            errors.append(
                SpecValidationError(
                    path=path,
                    code=SpecValidationCode.MIN_ITEMS,
                    message=f"list holds {count} item(s) but requires at least {minimum}",
                )
            )

    # 4. @OneOf discriminated subsection groups (instance tier).
    #
    # A concrete `@OneOf` container must carry ONLY the subsections whose
    # `@Case` matches the chosen discriminator value (plus the common,
    # un-`@Case`d ones), and at most one case subsection for the chosen case
    # (`codespecs_mapping.md` §8.2). The static tier (validator.dart) has
    # already checked the annotations are well-formed; here we check a
    # document's *values* against them.
    errors.extend(_validate_one_of_instances(refl, doc))

    # 5. Cross-registry id references (instance tier).
    #
    # A reference form field holds an id that must already be declared by some
    # entry of a target registry. The static tier has checked the `refersTo`
    # targets are resolvable; only here can we see whether the id a document
    # actually wrote is one the document also declares.
    errors.extend(_validate_reference_instances(refl, doc))

    return errors


def _case_constant(token: str) -> str:
    """The constant part of a qualified ``EnumType.constant`` ``@Case`` token
    (or the whole string when it is not qualified)."""
    dot = token.find(".")
    return token[dot + 1:] if dot >= 0 else token


def _validate_one_of_instances(
    refl: SpecReflection, doc: SpecDocument
) -> list[SpecValidationError]:
    """Instance-tier ``@OneOf``/``@Case`` check: for every ``@OneOf`` container
    instance present in *doc*, verify the populated case subsections match the
    chosen discriminator value."""
    errors: list[SpecValidationError] = []

    # Every section-instance path present in the document: each stored value
    # path plus all of its ancestor prefixes (a container's own discriminator
    # form lives at `<container>/<form>`, so the container path is always a
    # prefix of a populated path).
    section_paths: set[str] = set()

    def add_prefixes(full: str) -> None:
        segs = full.split("/")
        buf = ""
        for i, seg in enumerate(segs):
            buf = seg if i == 0 else f"{buf}/{seg}"
            section_paths.add(buf)

    for p in doc.content_paths:
        add_prefixes(p)
    for p in doc.form_paths:
        add_prefixes(p)
    for p in doc.list_paths:
        add_prefixes(p)
    for p in doc.headline_paths:
        add_prefixes(p)

    for path in sorted(section_paths):
        res = refl.resolve(path)
        cls = res.target_class if res is not None else None
        if cls is None:
            continue
        one_of = cls.annotation("OneOf")
        if one_of is None:
            continue
        discriminator = one_of.argument("discriminator")
        if not isinstance(discriminator, str) or not discriminator:
            continue

        # Read the chosen discriminator value from the container's own @Form.
        form_holder: Optional[SpecField] = None
        for f in cls.fields:
            if f.kind == SpecFieldKind.FORM and any(
                ff.name == discriminator for ff in f.form_fields
            ):
                form_holder = f
                break
        if form_holder is None:
            continue  # static tier flagged the mismatch
        chosen = doc.form_field(
            f"{path}/{refl.field_segment(form_holder)}", discriminator
        )
        if not chosen:
            continue  # no case chosen yet

        # Inspect each case-bound subsection: present + not-selected → mismatch.
        present_for_chosen: list[str] = []
        for f in cls.fields:
            case_constants = {
                _case_constant(a.argument("value"))
                for a in f.annotations
                if a.name == "Case" and isinstance(a.argument("value"), str)
            }
            if not case_constants:
                continue  # common subsection — always allowed
            child_path = f"{path}/{refl.field_segment(f)}"
            if not doc.has_values_under(child_path):
                continue
            if chosen in case_constants:
                present_for_chosen.append(f.name)
            else:
                errors.append(
                    SpecValidationError(
                        path=child_path,
                        code=SpecValidationCode.ONE_OF_CASE_MISMATCH,
                        message=(
                            f'subsection "{f.name}" is present but the chosen '
                            f'{discriminator}="{chosen}" does not select it '
                            f"(cases: {', '.join(sorted(case_constants))})"
                        ),
                    )
                )
        if len(present_for_chosen) > 1:
            present_for_chosen.sort()
            errors.append(
                SpecValidationError(
                    path=path,
                    code=SpecValidationCode.ONE_OF_CASE_MISMATCH,
                    message=(
                        f'chosen {discriminator}="{chosen}" selects more than '
                        f"one populated subsection "
                        f"({', '.join(present_for_chosen)}) — at most one case "
                        "subsection may be present"
                    ),
                )
            )

    return errors


def _registry_section_id(target: str) -> str:
    """The section id part of a registry key written ``<SECTIONID>.<slot>``. A
    key with no dot is malformed — the static tier reports it — and is treated
    whole here so it simply fails to match any section id."""
    dot = target.find(".")
    return target if dot <= 0 else target[:dot]


def _registry_scope(refl: SpecReflection, doc: SpecDocument) -> set[str]:
    """The registry section ids that are **in scope** for *doc*: the
    ``@SectionId`` of every class reachable from a document root the document
    actually uses.

    A ``refersTo`` target names its registry by section id, and a document can
    only ever declare entries of registries its own root reaches. Anything
    outside this set is absent from the document by construction — which is
    precisely the case the dangling-reference check must not call an error.

    The roots are read off the document rather than passed in: every path begins
    with its root's segment, so the document already says which root(s) it
    belongs to and no caller has to know. A document spanning several roots (the
    whole-project container) contributes the union, which is what makes a
    project-wide validation see every sibling registry.
    """
    root_types: set[str] = set()

    def add_root_of(path: str) -> None:
        slash = path.find("/")
        segment = path if slash < 0 else path[:slash]
        root = refl.root_for_segment(segment)
        if root is not None:
            root_types.add(root.type)

    for p in doc.content_paths:
        add_root_of(p)
    for p in doc.form_paths:
        add_root_of(p)
    for p in doc.list_paths:
        add_root_of(p)
    for p in doc.headline_paths:
        add_root_of(p)

    ids: set[str] = set()
    for type_name in root_types:
        for name in refl.reachable_class_names(type_name):
            cls = refl.class_named(name)
            if cls is not None and cls.section_id:
                ids.add(cls.section_id)
    return ids


def _validate_reference_instances(
    refl: SpecReflection, doc: SpecDocument
) -> list[SpecValidationError]:
    """Instance-tier cross-registry reference check: every id written into a
    ``refersTo`` form field must be declared by some entry of one of its target
    registries *in this document*.

    The pass is two sweeps over the document's form sections, so it costs one
    extra walk rather than a resolve per reference:

    1. **Declare.** Every form instance whose class carries ``@SectionId(X)``
       and declares form field ``f`` contributes its value of ``f`` to the
       registry key ``X.f``. Every item of a list whose element class carries
       ``@SectionId(X)`` additionally contributes its *effective* section id —
       stored, else positional, see :func:`effective_list_item_section_id` — to
       the reserved key ``X.@sectionId``. That second half is what makes a
       registry keeping its id nowhere but the section id (a functional
       requirement) referenceable at all.
    2. **Resolve.** Every form instance holding a ``refersTo`` field checks its
       value against those sets. A value naming several ids writes them
       comma-separated, so each segment resolves independently.

    A value is valid when it resolves in **any** listed registry: some fields
    legitimately accept an id from more than one. An empty value is not a
    dangling reference — it means "not filled in yet".

    **Cross-document references.** A reference whose target registry the
    document's own root cannot reach is skipped rather than reported; see
    :func:`_registry_scope`.
    """
    errors: list[SpecValidationError] = []
    scope = _registry_scope(refl, doc)

    # Resolve every form path once; both sweeps read the same resolutions.
    #
    # A form resolution names the form *field*, not a class — the section id a
    # registry key is written against belongs to the class the form sits on, so
    # the owner is resolved from the parent path.
    forms: list[tuple[str, SpecClass, SpecField]] = []
    for path in sorted(doc.form_paths):
        res = refl.resolve(path)
        if res is None or res.kind != SpecNodeKind.FORM or res.field is None:
            continue
        slash = path.rfind("/")
        if slash <= 0:
            continue
        owner = refl.resolve(path[:slash])
        cls = owner.target_class if owner is not None else None
        if cls is None:
            continue
        forms.append((path, cls, res.field))

    # 1. Declare.
    declared: dict[str, set[str]] = {}
    for form_path, cls, field in forms:
        section_id = cls.section_id
        if not section_id:
            continue
        for ff in field.form_fields:
            value = doc.form_field(form_path, ff.name)
            if value is None or not value.strip():
                continue
            declared.setdefault(f"{section_id}.{ff.name}", set()).add(value.strip())

    # 1b. Declare the per-item section ids under the reserved `@sectionId` slot.
    # The key is the *element class's* section id, not the `-LST` container's:
    # a target names the entry, so `FRE.@sectionId` reads as "an id of some
    # functional-requirement entry".
    for list_path in sorted(doc.list_paths):
        list_res = refl.resolve(list_path)
        list_field = list_res.field if list_res is not None else None
        pattern = list_field.section_id_pattern if list_field is not None else None
        stem = (
            list_field.name
            if list_field is not None
            else list_path.split("/")[-1]
        )
        items = doc.list_items(list_path)
        for i, item_path in enumerate(items):
            item_res = refl.resolve(item_path)
            element_class = item_res.target_class if item_res is not None else None
            section_id = element_class.section_id if element_class is not None else None
            if not section_id:
                continue
            declared.setdefault(f"{section_id}.{K_SECTION_ID_SLOT}", set()).add(
                effective_list_item_section_id(
                    stored_id=doc.item_section_id(item_path),
                    pattern=pattern,
                    position=i + 1,
                    fallback_stem=stem,
                )
            )

    # 2. Resolve.
    for form_path, cls, field in forms:
        for ff in field.form_fields:
            if not ff.refers_to:
                continue
            value = doc.form_field(form_path, ff.name)
            if value is None or not value.strip():
                continue

            # Every target must be in scope, not merely one of them: a
            # disjunction says the id may come from any of the listed
            # registries, so one absent registry is enough to make "no registry
            # declares it" unsound.
            if not all(_registry_section_id(t) in scope for t in ff.refers_to):
                continue

            for segment in value.split(","):
                id = segment.strip()
                if not id:
                    continue
                if any(id in declared.get(target, ()) for target in ff.refers_to):
                    continue
                errors.append(
                    SpecValidationError(
                        path=form_path,
                        code=SpecValidationCode.DANGLING_REFERENCE,
                        message=(
                            f'form field "{ff.name}" references "{id}", which no '
                            "entry of "
                            f"{'registry' if len(ff.refers_to) == 1 else 'registries'} "
                            f"{', '.join(ff.refers_to)} declares"
                        ),
                    )
                )

    return errors
