#!/usr/bin/env python3
"""Unit tests for :func:`som_editability_for` — the non-throwing companion to
``check_som_model_version`` (SOM §21).

Mirrors the Dart reference (`tom_som_dart_runtime/lib/src/som_facade.dart`)
`somEditabilityFor` cases and additionally asserts the invariant that
``som_editability_for`` NEVER raises where ``check_som_model_version`` raises —
the two share one rule definition, one throws, one classifies.

Plain-script style like the sibling ``som_v0_facade_test.py``: run with
``python3 tests/som_editability_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SomEditability,
    SomVersionError,
    check_som_model_version,
    som_editability_for,
)

_GEN = "1.2"  # object model version used throughout

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def test_editable_cases() -> None:
    # None / empty stamp → editable (a brand-new document, CS4-D2 uses None).
    _check("none->editable",
           som_editability_for(_GEN, None) is SomEditability.EDITABLE)
    _check("empty->editable",
           som_editability_for(_GEN, "") is SomEditability.EDITABLE)
    # Same major, older minor → editable (upgraded on edit).
    _check("older-minor->editable",
           som_editability_for(_GEN, "1.0") is SomEditability.EDITABLE)
    _check("older-minor2->editable",
           som_editability_for(_GEN, "1.1") is SomEditability.EDITABLE)
    # Same major, equal minor → editable.
    _check("equal-minor->editable",
           som_editability_for(_GEN, "1.2") is SomEditability.EDITABLE)


def test_rejected_newer_minor() -> None:
    # Same major, newer minor → rejected (older model cannot edit newer doc).
    _check("newer-minor->rejected",
           som_editability_for(_GEN, "1.3") is SomEditability.REJECTED_NEWER_MINOR)


def test_cross_major() -> None:
    # Different major (higher or lower) → read-only cross-major.
    _check("higher-major->cross",
           som_editability_for(_GEN, "2.0") is SomEditability.READ_ONLY_CROSS_MAJOR)
    _check("lower-major->cross",
           som_editability_for(_GEN, "0.9") is SomEditability.READ_ONLY_CROSS_MAJOR)


def test_invalid_version() -> None:
    # Unparseable stamps → invalid.
    _check("not-numeric->invalid",
           som_editability_for(_GEN, "abc") is SomEditability.INVALID_VERSION)
    _check("one-part->invalid",
           som_editability_for(_GEN, "1") is SomEditability.INVALID_VERSION)
    _check("three-parts->invalid",
           som_editability_for(_GEN, "1.2.3") is SomEditability.INVALID_VERSION)
    _check("partial-numeric->invalid",
           som_editability_for(_GEN, "1.x") is SomEditability.INVALID_VERSION)


def test_never_raises_where_checker_raises() -> None:
    """The classifier must NEVER raise on inputs where the throwing checker
    raises — it returns the classification instead (the whole point of SOM §21).
    """
    rejecting = ["1.3", "2.0", "0.9", "abc", "1", "1.2.3", "1.x"]
    for stamp in rejecting:
        # 1) The throwing checker DOES reject this stamp.
        raised = False
        try:
            check_som_model_version(_GEN, stamp)
        except SomVersionError:
            raised = True
        _check(f"checker-raises[{stamp}]", raised,
               "expected check_som_model_version to raise")
        # 2) The classifier does NOT raise and returns a non-editable value.
        try:
            outcome = som_editability_for(_GEN, stamp)
            _check(f"classifier-quiet[{stamp}]",
                   outcome is not SomEditability.EDITABLE, str(outcome))
        except Exception as e:  # pragma: no cover - would be a real failure
            _check(f"classifier-quiet[{stamp}]", False, f"raised {e!r}")


def main() -> int:
    test_editable_cases()
    test_rejected_newer_minor()
    test_cross_major()
    test_invalid_version()
    test_never_raises_where_checker_raises()

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
