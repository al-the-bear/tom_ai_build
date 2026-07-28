#!/usr/bin/env python3
"""Behavioural test for the generated Python typed object model (`v0`).

Loads the committed golden facade emitted by ``tom_specs_clitool``'s
``SomPythonEmitter`` (the Python counterpart of the Dart ``SomDartEmitter``)
and proves, against the *real* ``tom_som_runtime`` facade base, that:

  * the generated module imports cleanly against the runtime (a stronger check
    than the emitter package's ``py_compile`` syntax gate);
  * a typed mutation is visible through the generic document path and a generic
    mutation is visible through the typed surface (§3 — one shared document);
  * every field kind round-trips (content, form, complex, scalar list, complex
    list, enum);
  * the model-version accessor returns the generated ``v0`` version (``0.0``)
    and the instantiation-time version check (§2.2) accepts an editable stamp
    and rejects a newer one.

This mirrors the sibling-corpus pattern in ``conformance_runner.py`` — the
golden lives in the emitter package and is reached by a relative path. Run with
``python3 tests/som_v0_facade_test.py``; exit code 0 == all green. If the golden
is absent (emitter package not checked out) the test skips cleanly.
"""

from __future__ import annotations

import datetime as _dt
import importlib.util
import os
import sys
from importlib.machinery import SourceFileLoader

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
_GOLDEN = os.path.normpath(
    os.path.join(
        _PKG_ROOT,
        "..",
        "tom_specs_clitool",
        "test",
        "golden",
        "som_python_v0_fixture.py.golden",
    )
)
# The facade wildcard-imports its sibling generated metadata module (SOM §8)
# by the committed name `tom_som_python_v0_meta`, so the meta golden is
# preloaded under exactly that module name before the facade executes.
_META_GOLDEN = os.path.normpath(
    os.path.join(
        _PKG_ROOT,
        "..",
        "tom_specs_clitool",
        "test",
        "golden",
        "som_python_v0_meta_fixture.py.golden",
    )
)

sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SomEditability,
    SomVersionError,
    SpecDocument,
    SpecSectionIdCollision,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def _load_module(name: str, path: str):
    loader = SourceFileLoader(name, path)
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def _load_golden():
    # Register the meta golden first — the facade's wildcard import resolves
    # `tom_som_python_v0_meta` through sys.modules.
    meta = _load_module("tom_som_python_v0_meta", _META_GOLDEN)
    sys.modules["tom_som_python_v0_meta"] = meta
    return _load_module("som_python_v0_fixture", _GOLDEN)


def test_typed_generic_parity(mod) -> None:
    doc = SpecDocument()
    pd = mod.SolutionBlueprint(doc)

    # Typed write (content) → generic read.
    pd.vision = "A clear vision"
    _check("content.typed->generic", doc.content("PD00/vision") == "A clear vision",
           str(doc.content("PD00/vision")))

    # Generic write → typed read.
    doc.set_content("PD00/vision", "Revised vision")
    _check("content.generic->typed", pd.vision == "Revised vision", pd.vision)

    # Form field round-trip.
    pd.owner.name = "Alice"
    pd.owner.role = "Sponsor"
    _check("form.typed->generic", doc.form_field("PD00/owner", "name") == "Alice")
    doc.set_form_field("PD00/owner", "role", "Lead")
    _check("form.generic->typed", pd.owner.role == "Lead", pd.owner.role)

    # Complex section.
    pd.situation.summary = "As-is"
    _check("complex.typed->generic", doc.content("PD00/situation/summary") == "As-is")

    # Scalar list.
    tag = pd.tags.add()
    tag.value = "alpha"
    _check("scalarlist.len", pd.tags.length == 1, str(pd.tags.length))
    _check("scalarlist.typed->generic",
           doc.content(doc.list_items("PD00/tags")[0]) == "alpha")
    _check("scalarlist.generic->typed", pd.tags[0].value == "alpha", pd.tags[0].value)

    # Complex list + enum element.
    risk = pd.risks.add()
    risk.title = "Schedule slip"
    risk.probability = mod.Probability.high
    item_path = doc.list_items("PD00/risks")[0]
    _check("complexlist.title.typed->generic",
           doc.content(f"{item_path}/title") == "Schedule slip")
    _check("enum.typed->generic", doc.content(f"{item_path}/prob") == "high",
           str(doc.content(f"{item_path}/prob")))
    _check("enum.generic->typed", pd.risks[0].probability == mod.Probability.high,
           str(pd.risks[0].probability))

    # Enum clear.
    risk.probability = None
    _check("enum.clear", doc.content(f"{item_path}/prob") is None,
           str(doc.content(f"{item_path}/prob")))


def test_section_ids(mod) -> None:
    """AA1 criteria 3–6 through the typed facade: the generated `risks` list
    carries the `RISK-ITEM-xxx` pattern, so `add` auto-generates section ids,
    accepts unique overrides, and reuses freed same-day ids on last-item
    deletion while never renumbering after a middle deletion."""
    date = _dt.date(2026, 1, 2)  # month 1 → A, day 2 → B ⇒ "AB"

    # Criteria 3, 4: generate an id from the pattern + two-letter date.
    doc = SpecDocument()
    root = mod.SolutionBlueprint(doc)
    item = root.risks.add(date=date)
    _check("secid.generate", item.spec_section_id == "RISK-ITEM-AB1",
           str(item.spec_section_id))
    # Visible both ways (typed id == generic store).
    _check("secid.generate.generic",
           doc.item_section_id(item.path) == "RISK-ITEM-AB1",
           str(doc.item_section_id(item.path)))

    # Criterion 5: an override is accepted and validated unique.
    doc = SpecDocument()
    root = mod.SolutionBlueprint(doc)
    root.risks.add(section_id="RISK-ITEM-CUSTOM")
    _check("secid.override.accept", root.risks.section_ids == ["RISK-ITEM-CUSTOM"],
           str(root.risks.section_ids))
    _check("secid.override.collision",
           _raises_collision(lambda: root.risks.add(section_id="RISK-ITEM-CUSTOM")))

    # Criterion 5: override via the structural node accessor.
    doc = SpecDocument()
    root = mod.SolutionBlueprint(doc)
    item = root.risks.add(date=date)
    item.spec_section_id = "RISK-ITEM-OVR"
    _check("secid.node-override", root.risks.section_ids == ["RISK-ITEM-OVR"],
           str(root.risks.section_ids))

    # Criterion 6: delete-last then same-day add reuses the freed id.
    doc = SpecDocument()
    root = mod.SolutionBlueprint(doc)
    root.risks.add(date=date)  # AB1
    root.risks.add(date=date)  # AB2
    root.risks.remove_at(1)    # delete last
    reused = root.risks.add(date=date)
    _check("secid.reuse-last", reused.spec_section_id == "RISK-ITEM-AB2",
           str(reused.spec_section_id))

    # Criterion 6: delete-middle keeps ids, numbering stays non-consecutive.
    doc = SpecDocument()
    root = mod.SolutionBlueprint(doc)
    root.risks.add(date=date)  # AB1
    root.risks.add(date=date)  # AB2
    root.risks.add(date=date)  # AB3
    root.risks.remove_at(1)    # delete AB2
    _check("secid.delete-middle.keep",
           root.risks.section_ids == ["RISK-ITEM-AB1", "RISK-ITEM-AB3"],
           str(root.risks.section_ids))
    nxt = root.risks.add(date=date)
    _check("secid.delete-middle.next", nxt.spec_section_id == "RISK-ITEM-AB4",
           str(nxt.spec_section_id))


def _raises_collision(fn) -> bool:
    try:
        fn()
        return False
    except SpecSectionIdCollision:
        return True


def test_model_version(mod) -> None:
    _check("version.classattr", mod.SolutionBlueprint.model_version == "0.0",
           mod.SolutionBlueprint.model_version)
    pd = mod.SolutionBlueprint(SpecDocument())
    _check("version.accessor", pd.object_model_version == "0.0",
           pd.object_model_version)


def test_version_check(mod) -> None:
    # New / unstamped document → accepted.
    try:
        mod.SolutionBlueprint(SpecDocument())
        mod.SolutionBlueprint(SpecDocument(), document_version="0.0")
        _check("version.editable", True)
    except SomVersionError as e:  # pragma: no cover
        _check("version.editable", False, str(e))

    # Newer minor → rejected.
    try:
        mod.SolutionBlueprint(SpecDocument(), document_version="0.1")
        _check("version.newer-rejected", False, "expected SomVersionError")
    except SomVersionError:
        _check("version.newer-rejected", True)

    # Different major → rejected.
    try:
        mod.SolutionBlueprint(SpecDocument(), document_version="1.0")
        _check("version.cross-major-rejected", False, "expected SomVersionError")
    except SomVersionError:
        _check("version.cross-major-rejected", True)


def test_editability_for(mod) -> None:
    """The generated root's non-throwing ``editability_for`` classmethod (§ item
    8) classifies each §2.2 outcome without raising — the companion to the
    throwing constructor check exercised in :func:`test_version_check`.

    Skips cleanly if the golden predates § item 8 regeneration (the emitter
    change lands centrally; this test is authored now, verified after regen)."""
    if not hasattr(mod.SolutionBlueprint, "editability_for"):
        print("SKIP: golden predates editability_for (§ item 8 not yet regenerated)")
        return
    ef = mod.SolutionBlueprint.editability_for
    # None / empty stamp → editable.
    _check("editability.none", ef(None) is SomEditability.EDITABLE, str(ef(None)))
    _check("editability.empty", ef("") is SomEditability.EDITABLE, str(ef("")))
    # v0 is "0.0": same-major equal minor → editable.
    _check("editability.equal", ef("0.0") is SomEditability.EDITABLE, str(ef("0.0")))
    # Newer minor → rejected.
    _check("editability.newer-minor",
           ef("0.1") is SomEditability.REJECTED_NEWER_MINOR, str(ef("0.1")))
    # Different major → cross-major read-only.
    _check("editability.cross-major",
           ef("1.0") is SomEditability.READ_ONLY_CROSS_MAJOR, str(ef("1.0")))
    # Unparseable → invalid.
    _check("editability.invalid",
           ef("nope") is SomEditability.INVALID_VERSION, str(ef("nope")))


def main() -> int:
    if not os.path.isfile(_GOLDEN) or not os.path.isfile(_META_GOLDEN):
        print(f"SKIP: golden facade not found at {_GOLDEN}")
        return 0
    mod = _load_golden()
    test_typed_generic_parity(mod)
    test_section_ids(mod)
    test_model_version(mod)
    test_version_check(mod)
    test_editability_for(mod)

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
