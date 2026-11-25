#!/usr/bin/env python3
"""The reading notation's scanner (``spec_notation.py``) beyond the shared
corpus: offsets are UTF-16 code units although Python strings index by code
point, so a character outside the Basic Multilingual Plane counts twice — the
offsets below are the ones the JavaScript and TypeScript scanners report for
the same text. ``notation_cases.json`` (run by the conformance runner) holds
the grammar itself.

Run with: ``python3 tests/spec_notation_test.py``. Exit code 0 == all green.
"""

from __future__ import annotations

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    NotationFindingCode,
    notation_severity,
    registered_notation_kinds,
    scan_notation,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


_EMOJI = "\U0001F600"  # two UTF-16 code units, one Python character
_TEXT = (
    f"{_EMOJI} [x{_EMOJI}]{{.aside}} (-> {_EMOJI}A)\n"
    "\n"
    "::: {.rejected}\n"
    f"{_EMOJI} {{++a [b]{{.trace}}++}} c\n"
    ":::\n"
    "::: {.mine}\n"
)


def test_utf16_offsets() -> None:
    scan = scan_notation(_TEXT, tom_specs=True)
    got = [
        (e.type, e.start, e.end, [(c.type, c.start, c.end) for c in e.children])
        for e in scan.elements
    ]
    want = [
        ("span", 3, 16, []),
        ("citation", 17, 25, []),
        ("div", 27, 71, [("span", 51, 62)]),
        ("div", 72, 84, []),
    ]
    _check("utf16.elements", got == want, f"{got} != {want}")
    span = scan.elements[0].to_json(_TEXT)
    _check("utf16.source", span["source"] == f"[x{_EMOJI}]{{.aside}}", span["source"])
    _check("utf16.content", span["content"] == f"x{_EMOJI}", span["content"])
    findings = [(f.code, f.offset, f.line) for f in scan.findings]
    want_findings = [
        (NotationFindingCode.REJECTED_BLOCK, 27, 3),
        (NotationFindingCode.UNCLOSED_DIV, 72, 6),
        (NotationFindingCode.UNKNOWN_KIND, 72, 6),
    ]
    _check("utf16.findings", findings == want_findings, f"{findings}")
    _check("hasErrors", scan.has_errors)
    _check("all", [e.type for e in scan.all] == ["span", "citation", "div", "span", "div"])


def test_vocabulary() -> None:
    _check("severity.unknownKind", notation_severity(NotationFindingCode.UNKNOWN_KIND) == "warning")
    _check(
        "severity.others",
        all(
            notation_severity(c) == "error"
            for c in NotationFindingCode
            if c is not NotationFindingCode.UNKNOWN_KIND
        ),
    )
    _check("kinds.linked", "linked" in registered_notation_kinds)
    _check("kinds.derived", "derived" in registered_notation_kinds)
    _check("kinds.count", len(registered_notation_kinds) == 9)
    plain = scan_notation("::: {.mine}\n:::\n")
    _check("tomSpecs.off", plain.findings == [], str([str(f) for f in plain.findings]))


def main() -> int:
    test_utf16_offsets()
    test_vocabulary()

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
