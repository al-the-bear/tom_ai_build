#!/usr/bin/env python3
"""The link checks of one document (``spec_links_validator.py``,
`tom_specs_model_rules.md` §9.7), the derived numbers of the instance tier
(``spec_derived_numbers``) and the typed reading of a value under review
(``som_typed_reading``, the headline field of the review operations).

The shared corpus (``link_validation_cases.json``) pins the findings as
``{path, code}``; this test holds what it does not: the fixes ``deriveFields``
reads beside each finding, the finding order and messages, reading the
proposal (``read_proposed``), the derived numbers, and a headline refusing a
comment block.

Plain-script style like the sibling tests: run with
``python3 tests/spec_links_validator_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    K_SPEC_HEADLINE_FIELD,
    SpecDocument,
    SpecModel,
    SpecReviewAnnotationError,
    SpecReviewAnnotations,
    SpecValidationCode,
    som_is_typed_field,
    som_parse_bool,
    som_parse_enum_name,
    som_parse_int,
    som_typed_reading,
    som_typed_text_readable,
    spec_derived_numbers,
    validate_links,
)
from tom_som_runtime.spec_links_validator import (  # noqa: E402
    SpecLinkValidator,
    spec_expand_pattern,
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


def _read_json(name: str):
    with open(os.path.join(_CORPUS, name), encoding="utf-8") as fh:
        return json.load(fh)


_MODEL = SpecModel.from_json(_read_json("links.meta.json"))
_CASES = {c["name"]: c for c in _read_json("link_validation_cases.json")["cases"]}


def _doc(case_prefix: str) -> SpecDocument:
    name = next(n for n in _CASES if n.startswith(case_prefix))
    d = SpecDocument()
    d.load_json(json.loads(json.dumps(_CASES[name]["state"])))
    return d


def _fixes(doc: SpecDocument, read_proposed: bool = False) -> list:
    v = SpecLinkValidator(_MODEL, doc, read_proposed=read_proposed).run()
    return [(f.step, f.kind, f.path, f.field, f.value, f.values) for f in v.fixes]


def test_fixes() -> None:
    req1 = "BLU/requirements/REQ-ITEM-LST-1"
    # A derived value not written yet: no finding, but deriveFields writes it.
    d = _doc("a derived value not written yet")
    _eq("notYet.errors", validate_links(_MODEL, d), [])
    _eq("notYet.fixes", _fixes(d), [(
        2, "set", f"{req1}/REQAB", None,
        "Exports use the formats of REQ-IMPORT and never run with REQ-PURGE.", None)])
    # A one-way link not named back: the other end gets the id appended.
    _eq("inverse.fixes", _fixes(_doc("a one-way link not named back")), [(
        1, "append", "BLU/acceptance/criteria/CRIT-ITEM-LST-1/content",
        "relatedRequirements", "REQ-EXPORT", None)])
    # A symmetric row without its counterpart: a row is added there.
    _eq("symmetric.fixes", _fixes(_doc("a symmetric row without its counterpart")), [(
        1, "addRow", "BLU/requirements/REQ-ITEM-LST-3/LNK-ITEM-LST", None, None,
        {"LNK-REF#ref": "REQ-EXPORT", "content#linkType": "conflict"})])
    # A generated row the text no longer names: removed.
    _eq("stale.fixes", _fixes(_doc("a generated row the text no longer names")), [(
        1, "removeRow", f"{req1}/LNK-ITEM-LST-1", None, None, None)])
    # A copy edited apart from its holder: copied back whole.
    fixes = _fixes(_doc("a copy edited apart from its holder"))
    _eq("sameAs.fixes", [(f[1], f[2]) for f in fixes], [("copy", "BLU/criteriaSummary/criteria")])


def test_findings() -> None:
    errors = validate_links(_MODEL, _doc("a copy differing from its source"))
    _eq("copy.codes", [e.code for e in errors], [SpecValidationCode.DERIVED_VALUE_MISMATCH])
    _check("copy.message", "is derived (copy of" in errors[0].message, errors[0].message)
    # Sorted by path, then by code in declaration order.
    errors = validate_links(_MODEL, _doc("an id named in a generate-mode text"))
    _eq("order", [e.path for e in errors], sorted(e.path for e in errors))
    # A value holding a pending change is read with the mark rejected and
    # listed once; reading the proposal lists nothing.
    d = _doc("a source holding a pending change")
    pending = [e for e in validate_links(_MODEL, d)
               if e.code == SpecValidationCode.LINK_VALUE_PENDING]
    _eq("pending.once", len(pending), 1)
    v = SpecLinkValidator(_MODEL, d, read_proposed=True).run()
    _check("proposed.noPending",
           all(e.code != SpecValidationCode.LINK_VALUE_PENDING for e in v.errors))


def test_expand_and_ids() -> None:
    d = _doc("a clean Blueprint")
    items = spec_expand_pattern(d, "BLU/requirements/REQ-ITEM-LST-*/REQD")
    _eq("expand", items, [f"BLU/requirements/REQ-ITEM-LST-{i}/REQD" for i in (1, 2, 3)])
    _eq("expand.plain", spec_expand_pattern(d, "BLU/requirements"), ["BLU/requirements"])
    _eq("ids", SpecLinkValidator.ids(" A, ,B ,"), ["A", "B"])


def test_derived_numbers() -> None:
    base = "BLU/requirements"
    d = SpecDocument()
    for status in ("approved", "done", "draft"):
        item = d.add_list_item(f"{base}/REQ-ITEM-LST")
        d.set_form_field(f"{item}/content", "status", status)
    d.set_form_field(f"{base}/REQS-SUM", "total", "1")
    numbers = {(n.path, n.field): n.value for n in spec_derived_numbers(_MODEL, d)}
    _eq("count.total", numbers.get((f"{base}/REQS-SUM", "total")), "3")
    _eq("count.settled", numbers.get((f"{base}/REQS-SUM", "settled")), "2")
    # A count reading a pending mark: rejected by default, accepted with
    # read_proposed.
    d.set_form_field("BLU/requirements/REQ-ITEM-LST-3/content", "status", "{~~draft~>done~~}")
    rejected = {(n.path, n.field): n.value for n in spec_derived_numbers(_MODEL, d)}
    proposed = {(n.path, n.field): n.value
                for n in spec_derived_numbers(_MODEL, d, read_proposed=True)}
    _eq("count.rejected", rejected.get((f"{base}/REQS-SUM", "settled")), "2")
    _eq("count.proposed", proposed.get((f"{base}/REQS-SUM", "settled")), "3")


def test_typed_reading() -> None:
    _eq("reading.plain", som_typed_reading("30"), "30")
    _eq("reading.none", som_typed_reading(None), None)
    _eq("reading.change", som_typed_reading("{~~ 30 ~> 15 ~~}"), "30")
    _eq("reading.insertion", som_typed_reading("{++15++}"), "")
    _eq("int.marked", som_parse_int("{~~30~>15~~}"), 30)
    _eq("bool.marked", som_parse_bool("{~~true~>false~~}"), True)
    _eq("enum.marked", som_parse_enum_name("{~~high~>low~~}", ["low", "high"]), "high")
    _check("readable.marked", som_typed_text_readable("int", "{~~30~>lots~~}"))
    _check("typedField.enum", som_is_typed_field("String", ["a"]))
    _check("typedField.int", som_is_typed_field("int?", []))
    _check("typedField.string", not som_is_typed_field("String", []))


def test_headline_field() -> None:
    d = SpecDocument()
    d.set_headline("BLU/requirements", "Requirements {++and links++}")
    api = SpecReviewAnnotations(d, clock=lambda: "2026-11-07T14:05+01:00")
    marks = api.list_marks()
    _eq("headline.marks", [(m.path, m.field) for m in marks],
        [("BLU/requirements", K_SPEC_HEADLINE_FIELD)])
    try:
        api.insert_comment(path="BLU/requirements", field=K_SPEC_HEADLINE_FIELD,
                           after_paragraph=0, text="x")
        _check("headline.refusesBlock", False)
    except SpecReviewAnnotationError:
        _check("headline.refusesBlock", True)
    api.accept_all_marks()
    _eq("headline.accepted", d.headline("BLU/requirements"), "Requirements and links")


def main() -> int:
    test_fixes()
    test_findings()
    test_expand_and_ids()
    test_derived_numbers()
    test_typed_reading()
    test_headline_field()
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
