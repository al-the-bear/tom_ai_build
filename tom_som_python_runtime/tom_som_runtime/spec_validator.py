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

from .spec_document import SpecDocument
from .spec_model import SpecModel
from .spec_reflection import SpecNodeKind, SpecReflection


class SpecValidationCode(Enum):
    """Why a single value in a document is invalid against the model."""

    DANGLING_PATH = "danglingPath"
    KIND_MISMATCH = "kindMismatch"
    UNKNOWN_FORM_FIELD = "unknownFormField"
    MIN_ITEMS = "minItems"


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

    return errors
