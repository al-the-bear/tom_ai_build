#!/usr/bin/env python3
"""``derive_fields`` (``spec_derive_fields.py``, `tom_specs_model_rules.md`
§9.7): the derived places of one document, written plain or as marks.

The shared corpus (``derive_cases.json``) pins the canonical JSON of each run;
this test holds the Python surface it does not: the typed changes
(``SpecDeriveChange`` with its step, kind, field and values), the default
``marked=True`` reading a plain document as one under review, the dry run
answering a copy and leaving the given document alone, the unresolved entries
as ``SpecValidationError`` with their typed code, and the canonical JSON of a
change without a field.

Plain-script style like the sibling tests: run with
``python3 tests/spec_derive_fields_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SpecDeriveChange,
    SpecDocument,
    SpecModel,
    SpecValidationCode,
    derive_fields,
    validate_links,
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


_TABLE = _read_json("derive_cases.json")
_MODEL = SpecModel.from_json(_read_json(_TABLE.get("model") or "links.meta.json"))


def _doc(prefix: str) -> SpecDocument:
    case = next(c for c in _TABLE["cases"] if c["name"].startswith(prefix))
    d = SpecDocument()
    d.load_json(json.loads(json.dumps(case["state"])))
    return d


def test_plain_steps() -> None:
    doc = _doc("step 1: a missing symmetric row")
    r = derive_fields(_MODEL, doc, marked=False)
    _check("plain.same", r.document is doc)
    first = r.changes[0]
    _eq("plain.rowAdded", (first.step, first.kind, first.field), (1, "rowAdded", None))
    _eq("plain.steps", sorted({c.step for c in r.changes}), [1, 2])
    last = r.changes[-1]
    _eq("plain.value", (last.kind, last.field, last.old_value, last.new_value),
        ("value", "conflictsWith", "", "REQ-EXPORT"))
    _eq("plain.unresolved", r.unresolved, [])
    _eq("plain.clean", validate_links(_MODEL, doc), [])
    _eq("plain.again", derive_fields(_MODEL, doc, marked=False).changes, [])


def test_dry_run() -> None:
    doc = _doc("a dry run writes nothing")
    before = doc.to_json()
    r = derive_fields(_MODEL, doc, marked=False, dry_run=True)
    _check("dry.copy", r.document is not doc)
    _eq("dry.unchanged", doc.to_json(), before)
    _check("dry.changes", len(r.changes) > 0)
    _check("dry.written", r.document.to_json() != before)


def test_marked() -> None:
    doc = _doc("under review: every derived value")
    at = "2026-11-24T10:00+01:00"
    r = derive_fields(_MODEL, doc, author="agent_spec_author", at=at)
    values = [c for c in r.changes if c.kind == "value"]
    _check("marked.values", len(values) > 0)
    _check(
        "marked.marks",
        all("{" in c.new_value and f"@agent_spec_author {at}" in c.new_value for c in values),
    )
    _eq("marked.again", derive_fields(_MODEL, doc, author="agent_spec_author", at=at).changes, [])


def test_unresolved() -> None:
    miss = derive_fields(_MODEL, _doc("a lookup without its row"), marked=False)
    _check(
        "lookupMiss",
        any(e.code == SpecValidationCode.DERIVED_LOOKUP_MISS for e in miss.unresolved),
    )
    fenced = derive_fields(
        _MODEL, _doc("under review: a change inside fenced code"), at="2026-11-24T10:00+01:00"
    )
    codes = [e.code for e in fenced.unresolved]
    _eq("unmarkable", codes, [SpecValidationCode.UNMARKABLE])
    _eq(
        "unmarkable.json",
        fenced.to_json()["unresolved"][0]["code"],
        "unmarkable",
    )


def test_change_json() -> None:
    _eq(
        "json.noField",
        SpecDeriveChange(step=1, kind="rowRemoved", path="A/b-1").to_json(),
        {"step": 1, "kind": "rowRemoved", "path": "A/b-1", "old": "", "new": ""},
    )
    _eq(
        "json.field",
        SpecDeriveChange(step=3, kind="value", path="A/c", field="n", old_value="1",
                         new_value="2").to_json(),
        {"step": 3, "kind": "value", "path": "A/c", "field": "n", "old": "1", "new": "2"},
    )


def main() -> int:
    test_plain_steps()
    test_dry_run()
    test_marked()
    test_unresolved()
    test_change_json()
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
