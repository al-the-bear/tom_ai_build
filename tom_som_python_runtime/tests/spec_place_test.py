#!/usr/bin/env python3
"""The places and filters of the link vocabulary (``spec_place.py``,
`tom_specs_model_rules.md` §9.7) and the typed link readers of the model they
are read from (``spec_model.py``): the grammar, resolution under an anchor
over the corpus's ``links.meta.json``, the filter's ``|`` alternatives, the
``@SameAs`` holders and the readers' defaults for a key a meta does not carry.

The shared corpus (``link_reader_cases.json``) pins the canonical JSON of
these; this test holds the Python surface around it — the exceptions, the
defaults, ``str()`` and the section positions.

Plain-script style like the sibling tests: run with
``python3 tests/spec_place_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SpecAnnotation,
    SpecDerivation,
    SpecExtractsLinks,
    SpecInverseOf,
    SpecModel,
    SpecPlace,
    SpecPlaceException,
    SpecPlaceFilter,
    SpecPlaceKind,
    SpecPlaceProblem,
    SpecReflection,
    SpecSameAs,
    SpecSummaryOf,
    SpecSync,
    spec_same_as_bindings,
    spec_section_positions,
)

_CORPUS = os.path.normpath(os.path.join(_PKG_ROOT, "..", "tom_som_conformance", "corpus"))

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}: {detail}" if detail else name)


def _eq(name: str, got: object, want: object) -> None:
    _check(name, got == want, f"got {got!r}, want {want!r}")


def _model() -> SpecModel:
    with open(os.path.join(_CORPUS, "links.meta.json"), encoding="utf-8") as fh:
        return SpecModel.from_json(json.load(fh))


def _problem(fn) -> object:
    try:
        fn()
    except SpecPlaceException as e:
        return e.problem
    return None


def test_place_grammar() -> None:
    p = SpecPlace.parse("./FRE/REQDEP/RQDEP.description")
    _eq("place.scoped", p.scoped, True)
    _eq("place.prefix", p.prefix, ("FRE", "REQDEP"))
    _eq("place.sectionId", p.section_id, "RQDEP")
    _eq("place.slot", p.slot, "description")
    _eq("place.str", str(p), "./FRE/REQDEP/RQDEP.description")
    _eq("place.headline", SpecPlace.parse("FRE.@headline").slot, "@headline")
    _eq("place.bare", SpecPlace.parse("FRE-REQU-LST").to_json(),
        {"scoped": False, "prefix": [], "sectionId": "FRE-REQU-LST"})
    for bad in ("", "./", "-X", "FRE.", "FRE.a-b", "FRE/.x", "FRE..x"):
        _eq(f"place.malformed[{bad}]", SpecPlace.try_parse(bad), None)
    _eq("place.parse.malformed", _problem(lambda: SpecPlace.parse("a b")),
        SpecPlaceProblem.MALFORMED)


def test_filter_grammar() -> None:
    f = SpecPlaceFilter.parse("./FRE.priority=must|should")
    _eq("filter.scoped", f.scoped, True)
    _eq("filter.field", f.field, "priority")
    _eq("filter.values", f.values, ("must", "should"))
    _check("filter.matches.second", f.matches(["could", " should "]))
    _check("filter.matches.none", not f.matches(["could"]))
    _check("filter.matches.empty", not f.matches([]))
    every = SpecPlaceFilter.parse("FRE")
    _check("filter.noField.matchesAll", every.matches([]))
    _eq("filter.place", every.place.text, "FRE")
    _eq("filter.scopedPlace", f.place.text, "./FRE")
    for bad in ("FRE.priority", "FRE.priority=", "FRE.priority=a||b", "FRE.9x=a", ".x=a"):
        _eq(f"filter.malformed[{bad}]", SpecPlaceFilter.try_parse(bad), None)


def test_resolution() -> None:
    model = _model()
    refl = SpecReflection(model)
    r = SpecPlace.parse("REQD.description").resolve(refl, "BLU/requirements/REQ-ITEM-LST-1")
    _eq("resolve.kind", r.kind, SpecPlaceKind.FORM_FIELD)
    _eq("resolve.field", r.field, "description")
    _check("resolve.formField", r.form_field is not None and r.form_field.name == "description")
    _eq("resolve.anchorUnresolved",
        _problem(lambda: SpecPlace.parse("REQD").resolve(refl, "BLU/nowhere")),
        SpecPlaceProblem.ANCHOR_UNRESOLVED)
    _eq("resolve.notScoped",
        _problem(lambda: SpecPlace.parse("./REQD").resolve(refl, "BLU")),
        SpecPlaceProblem.NOT_SCOPED)
    _eq("resolve.unresolved",
        _problem(lambda: SpecPlace.parse("NOPE").resolve(refl, "BLU")),
        SpecPlaceProblem.UNRESOLVED)
    _eq("resolve.reservedSlot",
        _problem(lambda: SpecPlace.parse("REQD.@nope").resolve(
            refl, "BLU/requirements/REQ-ITEM-LST-1")),
        SpecPlaceProblem.RESERVED_SLOT)
    _eq("resolve.noSuchField",
        _problem(lambda: SpecPlace.parse("REQD.nope").resolve(
            refl, "BLU/requirements/REQ-ITEM-LST-1")),
        SpecPlaceProblem.NO_SUCH_FIELD)
    # The filter re-raises with its own text.
    try:
        SpecPlaceFilter.parse("NOPE.x=1").resolve(refl, "BLU")
        _check("filter.resolve.raises", False)
    except SpecPlaceException as e:
        _eq("filter.resolve.text", e.text, "NOPE.x=1")
        _check("filter.resolve.str", "NOPE.x=1" in str(e))


def test_positions() -> None:
    refl = SpecReflection(_model())
    positions = spec_section_positions(refl, "Blueprint")
    _check("positions.nonEmpty", len(positions) > 0)
    _eq("positions.root", positions[0].path, "BLU")
    _check("positions.rootIsClass", not positions[0].is_member and positions[0].member is None)
    _check("positions.items", any("-*" in p.path for p in positions))
    _eq("positions.unknownRoot", spec_section_positions(refl, "Nope"), [])
    bindings = spec_same_as_bindings(refl, "Blueprint")
    _check("sameAs.bound", len(bindings) == 1 and bindings[0].holder_path is not None,
           repr(bindings))
    _eq("sameAs.unknownRoot", spec_same_as_bindings(refl, "Nope"), [])


def test_reader_defaults() -> None:
    # An absent key takes the annotation's default; an enum constant loses
    # its type prefix.
    d = SpecDerivation.from_arguments({"source": "X", "kind": "DerivationKind.rows"})
    _eq("derivation.kind", d.kind, "rows")
    _eq("derivation.json", d.to_json(), {"kind": "rows", "source": "X", "take": [], "map": {}})
    _eq("derivation.defaultKind", SpecDerivation.from_arguments({}).kind, "copy")
    s = SpecSummaryOf.from_arguments({"detail": "D-LST"})
    _eq("summary.relation", s.relation, "subset")
    _eq("summary.json", s.to_json(), {"detail": "D-LST", "relation": "subset", "repeats": {}})
    _check("inverse.symmetric", SpecInverseOf(fields=["@self"]).symmetric)
    _check("inverse.notSymmetric", not SpecInverseOf(fields=["@self", "X.y"]).symmetric)
    e = SpecExtractsLinks.from_annotation(
        SpecAnnotation(name="ExtractsLinks", arguments={"ref": "L.ref", "from": ["A.b", None]}))
    _eq("extracts.json", e.to_json(), {"from": ["A.b"], "ref": "L.ref", "set": {}, "mode": "generate"})
    sync = SpecSync.from_annotation(SpecAnnotation(
        name="SyncedWith",
        arguments={"document": "D", "relations": [{"place": "P"}, "junk"]}))
    _eq("sync.relations", [r.to_json() for r in sync.relations], [{"place": "P", "relation": "equal"}])
    _eq("sameAs.empty", SpecSameAs().to_json(), {})


def test_model_accessors() -> None:
    model = _model()
    req = model.classes["Requirement"]
    _eq("annotationsNamed", len(req.field_named("links").annotations_named("ExtractsLinks")), 2)
    _check("noSync", model.classes["Blueprint"].synced_with is None)
    _check("notProjection", not model.classes["Blueprint"].is_code_specs_projection)


def main() -> int:
    test_place_grammar()
    test_filter_grammar()
    test_resolution()
    test_positions()
    test_reader_defaults()
    test_model_accessors()
    total = _passed + len(_failed)
    if _failed:
        print(f"FAIL: {len(_failed)}/{total} checks failed")
        for f in _failed:
            print(f"  - {f}")
        return 1
    print(f"OK: {total} checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
