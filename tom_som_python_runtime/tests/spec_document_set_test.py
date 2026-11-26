#!/usr/bin/env python3
"""The document set (``spec_document_set.py``, `tom_specs_model_rules.md`
§9.7): ``SpecDocumentSet``, ``sync_report`` and ``rename_id``.

The shared corpus (``document_set_cases.json``) pins the canonical JSON of the
construction, the report and the rename; this test holds the Python surface it
does not: the accessors of the set (by type name and by section id, ``get`` /
``[]``, ``put`` replacing a document), the typed report (``counts_by_code``,
``counts_by_resolution``, ``is_info``), the refusals as exceptions with their
attributes, a refused rename changing nothing, and the comparison helpers of
``SpecSetCheck`` (typed sameness, ids, value keys).

Plain-script style like the sibling tests: run with
``python3 tests/spec_document_set_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    FormFieldSpec,
    SpecDocument,
    SpecDocumentSet,
    SpecDocumentSetError,
    SpecDocumentSetRefusal,
    SpecModel,
    SpecRenameError,
    SpecSetCheck,
    SpecSyncCode,
    SpecSyncHolder,
    SpecSyncResolution,
    rename_id,
    spec_sync_code_index,
    sync_report,
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


_TABLE = _read_json("document_set_cases.json")
_MODEL = SpecModel.from_json(_read_json(_TABLE.get("model") or "links.meta.json"))


def _case(group: str, prefix: str) -> dict:
    return next(c for c in _TABLE[group] if c["name"].startswith(prefix))


def _docs(case: dict) -> list:
    out = []
    for name, state in case["documents"]:
        d = SpecDocument()
        d.load_json(json.loads(json.dumps(state)))
        out.append((name, d))
    return out


def _raises(fn, kind):
    try:
        fn()
    except kind as e:  # noqa: BLE001 - the refusal under test
        return e
    return None


def test_accessors() -> None:
    base = _case("construction", "the base set")
    docs = _docs(base)
    s = SpecDocumentSet(_MODEL, docs)
    _eq("blueprint_root", s.blueprint_root, "Blueprint")
    _check("blueprint", s.blueprint is docs[0][1])
    _check("document.byType", s.document("Detail") is docs[1][1])
    _check("document.bySectionId", s.document("DET") is docs[1][1])
    _eq("name_of", s.name_of("SCR"), "screens")
    _eq("name_of.unknown", s.name_of("Nope"), None)
    _check("get", s.get("detail") is docs[1][1])
    _check("getitem", s["detail"] is docs[1][1])
    _eq("get.unknown", s.get("nope"), None)
    _eq("root_of", s.root_of("screens"), "Screens")
    _eq("pairs", [p.section_id for p in s.pairs], ["REQS", "ACC", "CRIT"])
    _eq("pair.anchors", (s.pairs[0].blueprint_anchor, s.pairs[0].detail_anchor),
        ("BLU/requirements", "DET/requirements"))
    _check("pair.sync", s.pairs[0].sync is not None)
    # A mapping is taken as well as pairs.
    _eq("mapping.names", SpecDocumentSet(_MODEL, dict(docs)).names, s.names)
    # put replaces the document of the same name.
    other = SpecDocument()
    other.load_json(docs[1][1].to_json())
    s.put("detail", other)
    _check("put.replaces", s.get("detail") is other)
    _eq("put.names", s.names, ["blueprint", "detail", "screens"])
    # An empty set knows its pairs and every Phase 3 root as missing.
    empty = SpecDocumentSet(_MODEL)
    _eq("empty.names", empty.names, [])
    _eq("empty.missing", empty.missing_roots, ["Detail", "Screens"])
    _eq("empty.pairs", len(empty.pairs), 3)


def test_refusals() -> None:
    same = _case("construction", "two documents of one root")
    e = _raises(lambda: SpecDocumentSet(_MODEL, _docs(same)), SpecDocumentSetError)
    _check("sameRoot.raised", e is not None)
    if e is not None:
        _eq("sameRoot.refusal", e.refusal, SpecDocumentSetRefusal.SAME_ROOT)
        _eq("sameRoot.json", e.to_json(), same["expect"]["refused"])
        _check("sameRoot.str", str(e).startswith("SpecDocumentSetError(sameRoot): "), str(e))
    unp = _case("construction", "a synced class whose positions")
    e = _raises(
        lambda: SpecDocumentSet(SpecModel.from_json(unp["meta"]), _docs(unp)),
        SpecDocumentSetError,
    )
    _check("unpairable.raised", e is not None)
    if e is not None:
        _eq("unpairable.refusal", e.refusal, SpecDocumentSetRefusal.UNPAIRABLE)
        _check("unpairable.className", e.class_name is not None)
    # put refuses an empty document.
    s = SpecDocumentSet(_MODEL)
    e = _raises(lambda: s.put("x", SpecDocument()), SpecDocumentSetError)
    _check("put.noRoot", e is not None and e.refusal == SpecDocumentSetRefusal.NO_ROOT)


def test_report() -> None:
    c = _case("reports", "an enum value differs")
    r = sync_report(SpecDocumentSet(_MODEL, _docs(c)))
    _eq("report.clean", r.clean, False)
    _eq("report.counts_by_code", r.counts_by_code(), {SpecSyncCode.SHARED_VALUE_DIFFERS: 1})
    _eq("report.counts_by_resolution", r.counts_by_resolution(),
        {SpecSyncResolution.BACKFILL: 1})
    f = r.findings[0]
    _eq("finding.pair", f.pair, "REQS")
    _eq("finding.holder", f.holder, SpecSyncHolder.DETAIL)
    _eq("finding.is_info", f.is_info, False)
    _eq("finding.values", (f.blueprint.value, f.detail.value), ("approved", "done"))
    _eq("finding.field", f.blueprint.field, "status")
    _eq("report.documents", list(r.document_findings), ["blueprint", "detail", "screens"])
    _eq("report.json", r.to_json(), c["expect"])
    # Scoped to another pair, the finding is left out.
    scoped = sync_report(SpecDocumentSet(_MODEL, _docs(c)), pairs=["ACC"])
    _eq("report.scoped", scoped.findings, [])
    pending = sync_report(
        SpecDocumentSet(_MODEL, _docs(_case("reports", "a value holding a pending change")))
    )
    _check("pending.clean", pending.clean)
    _check("pending.info", all(f.is_info for f in pending.findings) and len(pending.findings) > 0)


def test_rename() -> None:
    ok = _case("renames", "an id renamed")
    s = SpecDocumentSet(_MODEL, _docs(ok))
    changes = rename_id(s, ok["from"], ok["to"])
    _eq("rename.first", (changes[0].kind, changes[0].old_value, changes[0].new_value),
        ("sectionId", ok["from"], ok["to"]))
    _eq("rename.again", rename_id(s, ok["from"], "REQ-OTHER"), [])
    refused = _case("renames", "a rename onto an id")
    s = SpecDocumentSet(_MODEL, _docs(refused))
    before = [s.get(n).to_json() for n in s.names]
    e = _raises(lambda: rename_id(s, refused["from"], refused["to"]), SpecRenameError)
    _check("rename.refused", e is not None)
    if e is not None:
        _eq("rename.documents", e.documents, refused["expect"]["refused"])
        _check("rename.str", str(e).startswith("SpecRenameError: "), str(e))
    _eq("rename.unchanged", [s.get(n).to_json() for n in s.names], before)


def test_helpers() -> None:
    dbl = FormFieldSpec(name="n", label="n", type="double")
    _check("same_typed.double", SpecSetCheck.same_typed("2", "2.0", dbl))
    _check("same_typed.hex", SpecSetCheck.same_typed("0x10", "16", dbl))
    _check("same_typed.nan", not SpecSetCheck.same_typed("NaN", "NaN", dbl))
    _check("same_typed.text", not SpecSetCheck.same_typed("2", "2.0", None))
    _check("same_typed.bool", SpecSetCheck.same_typed(
        "True", "true", FormFieldSpec(name="b", label="b", type="bool")))
    _eq("ids", SpecSetCheck.ids(" A, ,B ,C"), ["A", "B", "C"])
    _eq("strip_kind.form", SpecSetCheck.strip_kind("f:LIST[X]/content#status"), "LIST[X]/content")
    _eq("strip_kind.item", SpecSetCheck.strip_kind("i:LIST[X]"), "LIST[X]")
    _eq("reviewed", SpecSetCheck.reviewed(" a {++b ++}"), "a")
    _check("is_pending", SpecSetCheck.is_pending("a {++b++}"))
    _check("is_pending.plain", not SpecSetCheck.is_pending("a b"))
    _eq("code_index.first", spec_sync_code_index(SpecSyncCode.SHARED_VALUE_DIFFERS), 0)
    _eq("code_index.last", spec_sync_code_index(SpecSyncCode.UNMARKABLE), 9)
    _eq("code_index.unknown", spec_sync_code_index("nope"), -1)


def main() -> int:
    test_accessors()
    test_refusals()
    test_report()
    test_rename()
    test_helpers()
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
