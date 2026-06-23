#!/usr/bin/env python3
"""Behavioural test for the **actually-committed** generated Python typed model.

Unlike the runtime's ``tests/som_v0_facade_test.py`` — which loads the small
emitter *golden fixture* — this suite imports the real, full
``tom_som_python_v0`` module (3000+ classes) against the generic
``tom_som_runtime`` and proves the typed facade is a faithful editing surface
over the shared document (spec §3):

  * the real module imports cleanly against the runtime;
  * the ``ProjectDefinition`` root is anchored at the ``PD`` segment;
  * a content leaf round-trips typed -> generic and generic -> typed;
  * a nested complex section derives its path under the root;
  * the generated model-version accessor returns ``0.0``;
  * the instantiation-time version check (§2.2) accepts an editable stamp and
    rejects a newer-minor / cross-major stamp.

Run with ``python3 tests/som_v0_generated_test.py``; exit code 0 == all green.
The runtime is located by the ``runtime-path`` recorded in ``pyproject.toml`` so
the test is portable across checkouts.
"""

from __future__ import annotations

import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PROJECT = os.path.dirname(_HERE)  # tom_som_python_v0


def _runtime_dir() -> str:
    """The generic runtime package dir, read from ``pyproject.toml``.

    The manifest records ``runtime-path`` relative to the project root and
    points at the ``tom_som_runtime`` module dir; its parent is what goes on
    ``sys.path`` so ``import tom_som_runtime`` resolves.
    """
    toml = os.path.join(_PROJECT, "pyproject.toml")
    text = open(toml, encoding="utf-8").read()
    rel = re.search(r'runtime-path\s*=\s*"([^"]+)"', text).group(1)
    module_dir = os.path.normpath(os.path.join(_PROJECT, rel))
    return os.path.dirname(module_dir)


sys.path.insert(0, _runtime_dir())
sys.path.insert(0, _PROJECT)

from tom_som_runtime import SpecDocument, SomVersionError  # noqa: E402
import tom_som_python_v0 as m  # noqa: E402

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def test_root_and_parity() -> None:
    doc = SpecDocument()
    pd = m.ProjectDefinition(doc)

    _check("root.segment", pd.path == "PD", pd.path)

    # Typed write -> generic read.
    pd.content = "A clear vision"
    _check("content.typed->generic", doc.content("PD/content") == "A clear vision",
           str(doc.content("PD/content")))

    # Generic write -> typed read.
    doc.set_content("PD/content", "Revised vision")
    _check("content.generic->typed", pd.content == "Revised vision", pd.content)

    # Unset leaf reads as empty string.
    _check("content.unset-empty", m.ProjectDefinition(SpecDocument()).content == "")

    # Nested complex section path derivation. The Python emitter preserves the
    # model's camelCase accessor names (no snake_case translation).
    _check("nested.path", pd.currentStateAnalysis.path == "PD/currentStateAnalysis",
           pd.currentStateAnalysis.path)

    # A generic value under the nested typed node is addressable via the
    # expected literal path (proves typed path == generic path).
    header_path = pd.header.path
    doc.set_content(f"{header_path}/probe", "x")
    _check("nested.typed-path==generic", doc.content("PD/header/probe") == "x")


def test_model_version() -> None:
    _check("version.classattr", m.ProjectDefinition.model_version == "0.0",
           m.ProjectDefinition.model_version)
    pd = m.ProjectDefinition(SpecDocument())
    _check("version.accessor", pd.object_model_version == "0.0",
           pd.object_model_version)


def test_version_check() -> None:
    # New / equal-stamp document → accepted.
    try:
        m.ProjectDefinition(SpecDocument())
        m.ProjectDefinition(SpecDocument(), document_version="0.0")
        _check("version.editable", True)
    except SomVersionError as e:  # pragma: no cover
        _check("version.editable", False, str(e))

    # Newer minor → rejected.
    try:
        m.ProjectDefinition(SpecDocument(), document_version="0.1")
        _check("version.newer-rejected", False, "expected SomVersionError")
    except SomVersionError:
        _check("version.newer-rejected", True)

    # Different major → rejected.
    try:
        m.ProjectDefinition(SpecDocument(), document_version="1.0")
        _check("version.cross-major-rejected", False, "expected SomVersionError")
    except SomVersionError:
        _check("version.cross-major-rejected", True)


def main() -> int:
    test_root_and_parity()
    test_model_version()
    test_version_check()

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
