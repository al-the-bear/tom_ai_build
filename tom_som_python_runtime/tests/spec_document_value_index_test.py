#!/usr/bin/env python3
"""``SpecDocument.has_values_under`` answers from a prefix index rather than a
scan of every stored key. The markdown emitter, the validator and the query
engine ask it once per model node, so a scan made rendering a large
specification quadratic.

VI-1 holds the index to the scan it replaces, across every mutator, so a
mutation that forgets to drop the index fails here. VI-2 guards the complexity
itself.

Plain-script style like the sibling tests: run with
``python3 tests/spec_document_value_index_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import json
import os
import sys
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import SpecDocument, SpecModel, SpecSectionIdCollision  # noqa: E402

_CORPUS = os.path.normpath(
    os.path.join(_PKG_ROOT, "..", "tom_som_conformance", "corpus")
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{': ' + detail if detail else ''}")


def _scan(d: SpecDocument, prefix: str) -> bool:
    """The predicate the index must reproduce: a stored key equal to
    *prefix*, or continuing it after a ``/`` or a ``-``."""
    held = d.to_json()
    for store in ("content", "forms", "lists", "headlines", "codeSpecs"):
        for key in (held.get(store) or {}):
            k = str(key)
            if k == prefix or k.startswith(f"{prefix}/") or k.startswith(f"{prefix}-"):
                return True
    return False


_PROBES = [
    "DEMO",
    "DEMO/TTL",
    "DEMO/TT",
    "DEMO/SUM",
    "DEMO/DET",
    "DEMO/items",
    "DEMO/items-1",
    "DEMO/items-1/label",
    "DEMO/items-2",
    "DEMO/items-3",
    "DEMO/REF-LST",
    "DEMO/REF",
    "DEMO/CARD-LST-1",
    "OTHER",
    "",
]


def _probes_of(d: SpecDocument) -> list[str]:
    """The fixed probes plus every stored key, each of its `/`/`-` prefixes,
    and a near miss of each (one character short, one character longer)."""
    probes = set(_PROBES)
    for store in d.to_json().values():
        for key in store:
            probes.add(key)
            probes.add(key[:-1])
            probes.add(key + "x")
            for i, c in enumerate(key):
                if c in "/-":
                    probes.add(key[:i])
                    probes.add(key[: i + 1])
    return sorted(probes)


def _expect_agrees(d: SpecDocument, when: str) -> None:
    for p in _probes_of(d):
        _check(f"VI-1 {when}: {p!r}", d.has_values_under(p) == _scan(d, p))


def test_vi1_agrees_with_scan_after_every_mutator() -> None:
    d = SpecDocument()
    _expect_agrees(d, "empty")
    d.set_content("DEMO/TTL", "Hello")
    _expect_agrees(d, "set_content")
    d.set_headline("DEMO/SUM", "Summary")
    _expect_agrees(d, "set_headline")
    d.set_code_spec("DEMO/DET", "a.b")
    _expect_agrees(d, "set_code_spec")
    d.set_form_field("DEMO/CARD-LST-1/content", "note", "x")
    _expect_agrees(d, "set_form_field")
    item = d.add_list_item("DEMO/items")
    d.set_content(f"{item}/label", "First")
    d.add_list_item("DEMO/items")
    _expect_agrees(d, "add_list_item")
    d.set_item_section_id(item, "ITEM-A")
    _expect_agrees(d, "set_item_section_id")
    d.set_content("DEMO/TTL", "")
    _expect_agrees(d, "set_content to empty")
    d.set_headline("DEMO/SUM", "")
    _expect_agrees(d, "set_headline to empty")
    d.set_code_spec("DEMO/DET", "")
    _expect_agrees(d, "set_code_spec to empty")
    d.set_form_field("DEMO/CARD-LST-1/content", "note", "")
    _expect_agrees(d, "set_form_field to empty")
    d.remove_list_item(item)
    _expect_agrees(d, "remove_list_item")
    d.set_content("DEMO/SUM/X", "y")
    _expect_agrees(d, "before remove_values_under")
    d.remove_values_under("DEMO/SUM")
    _expect_agrees(d, "remove_values_under")

    d.load_json({
        "content": {"DEMO/REF-LST-1": "spec"},
        "lists": {"DEMO/REF-LST": {"seq": 1, "items": ["DEMO/REF-LST-1"]}},
    })
    _expect_agrees(d, "load_json")


def test_vi1_agrees_with_scan_after_move_list_item() -> None:
    """``move_list_item`` re-keys every store; replayed over the corpus's
    successful move cases."""
    with open(os.path.join(_CORPUS, "model.meta.json"), encoding="utf-8") as fh:
        model = SpecModel.from_json(json.load(fh))
    with open(os.path.join(_CORPUS, "list_move_cases.json"), encoding="utf-8") as fh:
        cases = json.load(fh)["cases"]
    moved = 0
    for case in cases:
        d = SpecDocument()
        d.load_json(case["state"])
        before = _probes_of(d)
        for p in before:  # build the index before the move
            d.has_values_under(p)
        m = case["move"]
        try:
            d.move_list_item(model, m["itemPath"], m["toIndex"], to_list=m.get("toList"))
        except (ValueError, IndexError, SpecSectionIdCollision):
            continue
        moved += 1
        for p in sorted(set(before) | set(_probes_of(d))):
            _check(f"VI-1 move_list_item [{case['name']}]: {p!r}",
                   d.has_values_under(p) == _scan(d, p))
    _check("VI-1 move_list_item: at least one move ran", moved > 0)


def test_vi2_not_a_scan() -> None:
    """20,000 stored values and 20,000 queries. A per-query scan costs 4 * 10^8
    key comparisons; the index answers in milliseconds. The bound is generous,
    so only the complexity class can fail it."""
    n = 20000
    d = SpecDocument()
    for i in range(n):
        d.set_content(f"ROOT/S{i // 100}/F{i}", f"v{i}")
    start = time.perf_counter()
    hits = 0
    for i in range(n):
        if d.has_values_under(f"ROOT/S{i // 100}/F{i}"):
            hits += 1
        if d.has_values_under(f"ROOT/S{i // 100}/G{i}"):
            hits -= 1
    elapsed = time.perf_counter() - start
    _check("VI-2 hits", hits == n, str(hits))
    _check("VI-2 under 5 s", elapsed < 5.0, f"{elapsed:.2f} s")


def main() -> int:
    test_vi1_agrees_with_scan_after_every_mutator()
    test_vi1_agrees_with_scan_after_move_list_item()
    test_vi2_not_a_scan()

    total = _passed + len(_failed)
    if _failed:
        print(f"FAIL: {len(_failed)}/{total} checks failed")
        for f in _failed[:50]:
            print(f"  - {f}")
        return 1
    print(f"OK: {total} checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
