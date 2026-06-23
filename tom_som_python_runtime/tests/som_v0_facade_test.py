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

sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import SpecDocument, SomVersionError  # noqa: E402

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def _load_golden():
    loader = SourceFileLoader("som_python_v0_fixture", _GOLDEN)
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def test_typed_generic_parity(mod) -> None:
    doc = SpecDocument()
    pd = mod.ProjectDefinition(doc)

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


def test_model_version(mod) -> None:
    _check("version.classattr", mod.ProjectDefinition.model_version == "0.0",
           mod.ProjectDefinition.model_version)
    pd = mod.ProjectDefinition(SpecDocument())
    _check("version.accessor", pd.object_model_version == "0.0",
           pd.object_model_version)


def test_version_check(mod) -> None:
    # New / unstamped document → accepted.
    try:
        mod.ProjectDefinition(SpecDocument())
        mod.ProjectDefinition(SpecDocument(), document_version="0.0")
        _check("version.editable", True)
    except SomVersionError as e:  # pragma: no cover
        _check("version.editable", False, str(e))

    # Newer minor → rejected.
    try:
        mod.ProjectDefinition(SpecDocument(), document_version="0.1")
        _check("version.newer-rejected", False, "expected SomVersionError")
    except SomVersionError:
        _check("version.newer-rejected", True)

    # Different major → rejected.
    try:
        mod.ProjectDefinition(SpecDocument(), document_version="1.0")
        _check("version.cross-major-rejected", False, "expected SomVersionError")
    except SomVersionError:
        _check("version.cross-major-rejected", True)


def main() -> int:
    if not os.path.isfile(_GOLDEN):
        print(f"SKIP: golden facade not found at {_GOLDEN}")
        return 0
    mod = _load_golden()
    test_typed_generic_parity(mod)
    test_model_version(mod)
    test_version_check(mod)

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
