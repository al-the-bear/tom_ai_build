#!/usr/bin/env python3
"""``prefill`` and ``backfill`` (``spec_prefill.py``, ``spec_backfill.py``):
the Blueprint into a new Phase 3 document (BP-8), and the accepted Phase 3 end
state back into the Blueprint (DP-part-operations-2).

The shared corpus (``prefill_cases.json``, ``backfill_cases.json``) pins the
canonical JSON of each run; this test holds the Python surface it does not:
the created document joining the set under its default name, the typed
results (``filled_pairs``, ``skipped_pairs``, ``derived``, ``findings``;
``changes``, ``left``), the refusals as exceptions with their codes and
places, the revision entry's version bump and default author, and the dry run
leaving the set's Blueprint alone.

Plain-script style like the sibling tests: run with
``python3 tests/spec_prefill_backfill_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import datetime as _dt
import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SpecBackfillChange,
    SpecBackfillError,
    SpecDocument,
    SpecDocumentSet,
    SpecModel,
    SpecPrefillError,
    backfill,
    prefill,
    sync_report,
)
from tom_som_runtime.spec_backfill import _Backfill  # noqa: E402

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


_PREFILL = _read_json("prefill_cases.json")
_BACKFILL = _read_json("backfill_cases.json")
_MODEL = SpecModel.from_json(_read_json(_PREFILL.get("model") or "links.meta.json"))


def _set(table: dict, prefix: str) -> SpecDocumentSet:
    case = next(c for c in table["cases"] if c["name"].startswith(prefix))
    docs = []
    for name, state in case["documents"]:
        d = SpecDocument()
        d.load_json(json.loads(json.dumps(state)))
        docs.append((name, d))
    return SpecDocumentSet(_MODEL, docs)


def _raises(fn, kind):
    try:
        fn()
    except kind as e:  # noqa: BLE001 - the refusal under test
        return e
    return None


def test_prefill() -> None:
    s = _set(_PREFILL, "a new Screens document")
    _eq("prefill.missing", s.missing_roots, ["Screens"])
    r = prefill(s, "SCR")
    _eq("prefill.name", r.name, "Screens")
    _check("prefill.created", r.created)
    _check("prefill.joined", s.get("Screens") is r.document)
    _eq("prefill.filled", r.filled_pairs, ["ACC"])
    _eq("prefill.skipped", r.skipped_pairs, [])
    _eq("prefill.missingAfter", s.missing_roots, [])
    again = prefill(s, "Screens")
    _check("prefill.again.notCreated", not again.created)
    _eq("prefill.again.filled", again.filled_pairs, [])
    _eq("prefill.again.skipped", again.skipped_pairs, ["ACC"])
    _eq("prefill.again.derived", again.derived.changes, [])

    named = _set(_PREFILL, "a new Detail document")
    r = prefill(named, "Detail", name="detail.tomspecs.yaml")
    _eq("prefill.named", named.names, ["blueprint", "detail.tomspecs.yaml", "screens"])
    _check("prefill.derived", len(r.derived.changes) > 0)
    _check("prefill.agrees", not any(
        k.startswith("shared") for k in sync_report(named).counts_by_code()))

    e = _raises(lambda: prefill(_set(_PREFILL, "a set without the Blueprint"), "DET"),
                SpecPrefillError)
    _check("prefill.noBlueprint", e is not None and e.code == "noBlueprint")
    e = _raises(lambda: prefill(_set(_PREFILL, "the Blueprint's own root"), "BLU"),
                SpecPrefillError)
    _check("prefill.unknownRoot", e is not None and e.code == "unknownRoot")
    if e is not None:
        _check("prefill.str", str(e).startswith("SpecPrefillError(unknownRoot): "), str(e))
    e = _raises(lambda: prefill(_set(_PREFILL, "the Blueprint's own root"), "Nope"),
                SpecPrefillError)
    _check("prefill.unknownRoot.name", e is not None and e.code == "unknownRoot")


def test_backfill() -> None:
    s = _set(_BACKFILL, "a differing enum value")
    r = backfill(s, author="agent_spec_author", date="2026-11-24")
    _check("backfill.same", r.blueprint is s.blueprint)
    _eq("backfill.kinds", [c.kind for c in r.changes], ["value", "revision"])
    _eq("backfill.value", (r.changes[0].pair, r.changes[0].old_value, r.changes[0].new_value),
        ("REQS", "approved", "done"))
    rev = r.changes[1].path
    _eq("backfill.revision.version", r.changes[1].new_value, "1.1")
    bp = s.blueprint
    _eq("backfill.revision.author", bp.form_field(f"{rev}/content", "author"),
        "agent_spec_author")
    _eq("backfill.revision.summary", bp.form_field(f"{rev}/content", "summary"),
        "Backfilled from detail, screens: REQS")
    _check("backfill.clean", sync_report(s).clean)
    _eq("backfill.again", backfill(s).changes, [])

    # Default author and date.
    d = _set(_BACKFILL, "a value the Blueprint leaves empty")
    r = backfill(d)
    rev = next(c.path for c in r.changes if c.kind == "revision")
    _eq("backfill.default.author", d.blueprint.form_field(f"{rev}/content", "author"), "backfill")
    _eq("backfill.default.date", d.blueprint.form_field(f"{rev}/content", "date"),
        _dt.date.today().isoformat())

    dry = _set(_BACKFILL, "a dry run writes a copy")
    before = dry.blueprint.to_json()
    r = backfill(dry, dry_run=True)
    _check("backfill.dry.copy", r.blueprint is not dry.blueprint)
    _eq("backfill.dry.unchanged", dry.blueprint.to_json(), before)
    _check("backfill.dry.changes", len(r.changes) > 0)

    held = backfill(_set(_BACKFILL, "a heldHere value"))
    _eq("backfill.held.changes", held.changes, [])
    _eq("backfill.held.reason", [x.reason for x in held.left], ["heldHere"])
    _eq("backfill.held.code", held.left[0].finding.code, "sharedValueDiffers")

    e = _raises(lambda: backfill(_set(_BACKFILL, "a set holding an inline mark")),
                SpecBackfillError)
    _check("backfill.marks", e is not None and e.code == "setHasMarks")
    if e is not None:
        _check("backfill.marks.places", len(e.places) > 0 and e.places[0].document is not None)
        _check("backfill.marks.str", str(e).startswith("SpecBackfillError(setHasMarks): "))
    e = _raises(lambda: backfill(SpecDocumentSet(_MODEL)), SpecBackfillError)
    _check("backfill.noBlueprint", e is not None and e.code == "noBlueprint")


def test_bump_and_json() -> None:
    _eq("bump.empty", _Backfill._bump(""), "1")
    _eq("bump.minor", _Backfill._bump("1.2"), "1.3")
    _eq("bump.carry", _Backfill._bump("v1.9-rc"), "v1.10-rc")
    _eq("bump.none", _Backfill._bump("draft"), "draft.1")
    _eq(
        "change.json",
        SpecBackfillChange(pair="", kind="revision", path="B/R-1", new_value="2").to_json(),
        {"pair": "", "kind": "revision", "path": "B/R-1", "old": "", "new": "2"},
    )


def main() -> int:
    test_prefill()
    test_backfill()
    test_bump_and_json()
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
