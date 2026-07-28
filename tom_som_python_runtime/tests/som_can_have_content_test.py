#!/usr/bin/env python3
"""Behavioural test for the SOM §21 structural content-slot predicate
(:attr:`SomNode.can_have_content`).

Exercises the runtime base directly (no golden facade needed) against local
element facades — a content-bearing subclass that overrides the structural
default and a container-only subclass that inherits it — mirroring the runtime's
own fixture style and the Dart ``som_facade_test.dart`` ``canHaveContent`` group.
Proves:

  * the ``SomNode`` base defaults ``can_have_content`` to ``False``
    (container-only);
  * a content-bearing section overrides it to ``True``;
  * a scalar list item inherits the container-only ``False`` default;
  * it is structural, not state — independent of any stored value (mutating the
    document never changes the schema-level answer).

Run with ``python3 tests/som_can_have_content_test.py``; exit code 0 == all
green.
"""

from __future__ import annotations

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SomNode,
    SomScalar,
    SpecDocument,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


class _Metric(SomNode):
    """A content-only element facade: its only field is the standard ``content``
    leaf, matching the generated content-element shape (e.g.
    ``CurrentOperationalMetric``)."""

    @property
    def content(self) -> str:
        return self.doc.content(f"{self.path}/content") or ""

    @content.setter
    def content(self, v: str) -> None:
        self.doc.set_content(f"{self.path}/content", v)

    @property
    def can_have_content(self) -> bool:
        """A content-bearing section overrides the structural default
        (SOM §21)."""
        return True


class _Container(SomNode):
    """A container-only section facade: it holds only child sections, no
    ``content`` leaf, so it does **not** override
    :attr:`SomNode.can_have_content` and inherits the ``False`` default (mirrors
    a generated class such as ``SystemsToReplace``)."""

    @property
    def child(self) -> _Metric:
        return _Metric(self.doc, f"{self.path}/child")


def test_base_defaults_false() -> None:
    """The SomNode base defaults to False (container-only)."""
    doc = SpecDocument()
    _check("base.default-false", _Container(doc, "PD00").can_have_content is False)


def test_content_bearing_overrides_true() -> None:
    """A content-bearing section overrides it to True."""
    doc = SpecDocument()
    _check(
        "content.override-true",
        _Metric(doc, "PD00/METR-ITEM-AB1").can_have_content is True,
    )


def test_scalar_inherits_false() -> None:
    """A scalar list item inherits the container-only False default."""
    doc = SpecDocument()
    _check(
        "scalar.inherit-false",
        SomScalar(doc, "PD00/tags-1").can_have_content is False,
    )


def test_structural_not_state() -> None:
    """It is structural, not state — independent of any stored value."""
    doc = SpecDocument()
    container = _Container(doc, "PD00")
    metric = _Metric(doc, "PD00/METR-ITEM-AB1")
    # Empty vs filled makes no difference to the schema-level answer.
    _check("structural.container-empty", container.can_have_content is False)
    _check("structural.metric-empty", metric.can_have_content is True)
    metric.content = "filled"
    _check("structural.metric-filled", metric.can_have_content is True)
    _check("structural.container-still-false", container.can_have_content is False)


def main() -> int:
    test_base_defaults_false()
    test_content_bearing_overrides_true()
    test_scalar_inherits_false()
    test_structural_not_state()

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
