"""The generation-unit register of a document (SOM §11.2): the units Phase 4
writes code into, each with the mapper of every area it holds.

The register is recognised by its annotations, never by class name, exactly as
validation phase 8 recognises it: a **unit** is a list item whose class carries
``@NoArtifact(generation)`` and declares the form field ``unitId``; a
**mapping** is such a list item declaring the form field ``area``, and belongs
to the nearest unit whose path is a prefix of its own.
"""

from __future__ import annotations

from dataclasses import dataclass, field as dataclass_field
from typing import Optional

from .spec_document import SpecDocument
from .spec_model import SpecModel
from .spec_paths import spec_path_join
from .spec_reflection import SpecReflection
from .spec_validator import _form_declaring


@dataclass(frozen=True)
class SpecGenerationUnitMapping:
    """One mapping of a generation unit: the area it holds and the mapper that
    writes that area's code for it."""

    #: The area code, ``CE-…``, as stored (trimmed).
    area: str
    #: The mapper id, e.g. ``dart-tom``, as stored (trimmed); empty when unset.
    mapping: str


@dataclass(frozen=True)
class SpecGenerationUnit:
    """One generation unit the document declares."""

    #: The unit's id — what a section's ``units`` names, usually the package
    #: name.
    unit_id: str
    #: ``client``, ``server``, ``shared`` or ``other``, as stored; empty when
    #: unset.
    kind: str
    #: The unit's list-item path in the document.
    path: str
    #: The unit's mappings, in stored order.
    mappings: list[SpecGenerationUnitMapping] = dataclass_field(
        default_factory=list
    )

    def maps(self, area_code: str) -> bool:
        """Whether one of the unit's mappings holds *area_code*."""
        return any(m.area == area_code for m in self.mappings)

    def mapping_for(self, area_code: str) -> Optional[str]:
        """The mapper of *area_code* — the first mapping that holds it — or
        ``None``."""
        for m in self.mappings:
            if m.area == area_code:
                return m.mapping
        return None


def spec_generation_units(
    model: SpecModel, doc: SpecDocument
) -> list[SpecGenerationUnit]:
    """The generation units *doc* declares, in register order: sorted list-path
    order, each list's items in their stored order — the order validation phase
    8 visits them in. A unit without a ``unitId`` is left out; a second unit
    with an id already seen is left out too (phase 8 reports it as
    ``duplicateUnitId``). A document without a register declares none."""
    refl = SpecReflection(model)
    # (id, kind, path) per unit; (path, area, mapping) per mapping.
    units: list[tuple[str, str, str]] = []
    mappings: list[tuple[str, str, str]] = []
    for list_path in sorted(doc.list_paths):
        for item in doc.list_items(list_path):
            res = refl.resolve(item)
            cls = res.target_class if res is not None else None
            if cls is None:
                continue
            no_artifact = cls.no_artifact
            if no_artifact is None or no_artifact.reason != "generation":
                continue
            unit_form = _form_declaring(cls, "unitId")
            if unit_form is not None:
                form_path = spec_path_join(item, refl.field_segment(unit_form))
                id = (doc.form_field(form_path, "unitId") or "").strip()
                if id:
                    kind = (doc.form_field(form_path, "kind") or "").strip()
                    units.append((id, kind, item))
            area_form = _form_declaring(cls, "area")
            if area_form is not None:
                form_path = spec_path_join(item, refl.field_segment(area_form))
                area = (doc.form_field(form_path, "area") or "").strip()
                if area:
                    mapping = doc.form_field(form_path, "mapping") or ""
                    mappings.append((item, area, mapping.strip()))

    unit_paths = [path for _, _, path in units]
    seen: set[str] = set()
    out: list[SpecGenerationUnit] = []
    for id, kind, path in units:
        if id in seen:
            continue
        seen.add(id)
        out.append(
            SpecGenerationUnit(
                unit_id=id,
                kind=kind,
                path=path,
                mappings=[
                    SpecGenerationUnitMapping(area=area, mapping=mapping)
                    for m_path, area, mapping in mappings
                    if _owner(m_path, unit_paths) == path
                ],
            )
        )
    return out


def spec_default_units(
    units: list[SpecGenerationUnit], area_code: str
) -> list[str]:
    """The units of *units* whose mappings hold *area_code*, in register order
    — the default destination of a section routed to that area (SOM §11.2)."""
    return [u.unit_id for u in units if u.maps(area_code)]


def _owner(mapping_path: str, unit_paths: list[str]) -> Optional[str]:
    """The path of the unit a mapping at *mapping_path* belongs to: the longest
    unit path that is a proper prefix of it, or ``None``."""
    best: Optional[str] = None
    for path in unit_paths:
        if mapping_path.startswith(f"{path}/") and (
            best is None or len(path) > len(best)
        ):
            best = path
    return best
