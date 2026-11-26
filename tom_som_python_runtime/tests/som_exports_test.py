#!/usr/bin/env python3
"""The package-root exports TS ``index.ts`` has and Python once kept private
or unexported (runtime parity audit, ``runtime_parity.md`` § python): the YAML
helpers, ``SpecDocumentYaml``, ``format_conflict_block``,
``code_specs_yaml_string`` and ``som_model_version_string``; and the names of
the section automation's first part (the link readers, ``SpecPlace``,
``validate_links``, ...) and of its second part (the document set,
``sync_report``, ``rename_id``, ``derive_fields``, ``prefill``, ``backfill``).

Each expected value was produced by the TypeScript runtime for the same
input, so a check holds the Python output to TS's, not only its presence.

Plain-script style like the sibling tests: run with
``python3 tests/som_exports_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
sys.path.insert(0, _PKG_ROOT)

import tom_som_runtime  # noqa: E402
from tom_som_runtime import (  # noqa: E402
    SpecConflictAlternative,
    SpecDocumentYaml,
    code_specs_yaml_string,
    dedup_empty_lines,
    format_conflict_block,
    node_key,
    plain_key,
    rekey_review,
    som_model_version_string,
    write_header,
    write_scalar,
    yaml_key,
)

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


class _Buffer:
    """Anything with ``writeln`` / ``write`` is a buffer for the writers."""

    def __init__(self) -> None:
        self.parts: list[str] = []

    def writeln(self, text: str = "") -> None:
        self.parts.append(text + "\n")

    def write(self, text: str) -> None:
        self.parts.append(text)

    def __str__(self) -> str:
        return "".join(self.parts)


def test_exported() -> None:
    for name in (
        "node_key",
        "yaml_key",
        "plain_key",
        "dedup_empty_lines",
        "write_scalar",
        "write_header",
        "format_conflict_block",
        "som_model_version_string",
        "SpecDocumentYaml",
        "code_specs_yaml_string",
        "scan_notation",
        "NotationScan",
        "NotationElement",
        "NotationFinding",
        "NotationFindingCode",
        "notation_severity",
        "registered_notation_kinds",
        # section automation, part 1 (tom_specs_model_rules.md §9.7): the
        # link readers, places and filters, the typed reading of a value under
        # review, the derived numbers and the link checks of one document
        "SpecListRelation",
        "SpecSync",
        "SpecSummaryOf",
        "SpecDerivation",
        "SpecInverseOf",
        "SpecExtractsLinks",
        "SpecSameAs",
        "SpecPlaceKind",
        "SpecPlaceProblem",
        "SpecPlaceException",
        "SpecPlace",
        "SpecPlaceResolution",
        "SpecPlaceFilter",
        "SpecSameAsBinding",
        "spec_same_as_bindings",
        "SpecSectionPosition",
        "spec_section_positions",
        "som_typed_reading",
        "som_is_typed_field",
        "SpecDerivedNumber",
        "spec_derived_numbers",
        "validate_links",
        "SpecDeriveChange",
        "SpecDeriveResult",
        "derive_fields",
        "SpecSyncCode",
        "spec_sync_code_index",
        "SpecSyncResolution",
        "SpecSyncHolder",
        "SpecDocumentSetRefusal",
        "SpecDocumentSetError",
        "SpecSyncPair",
        "SpecDocumentSet",
        "SpecSyncPlace",
        "SpecSyncFinding",
        "SpecSyncReport",
        "sync_report",
        "SpecSetSide",
        "SpecSetCheck",
        "SpecRenameError",
        "SpecRenameChange",
        "rename_id",
        "SpecPrefillError",
        "SpecPrefillResult",
        "prefill",
        "SpecBackfillError",
        "SpecBackfillChange",
        "SpecBackfillLeft",
        "SpecBackfillResult",
        "backfill",
        "K_SPEC_HEADLINE_FIELD",
    ):
        _check(f"exported.{name}", hasattr(tom_som_runtime, name))
        _check(f"all.{name}", name in tom_som_runtime.__all__)
    _check("all.unique", len(tom_som_runtime.__all__) == len(set(tom_som_runtime.__all__)))
    _check("node_key.callable", callable(node_key))


def test_yaml_helpers() -> None:
    _eq("yaml_key", yaml_key("plain"), '"plain"')
    _eq("yaml_key.quoted", yaml_key("a: b"), '"a: b"')
    _eq("plain_key", plain_key("plain"), "plain")
    _eq("plain_key.quoted", plain_key("a: b"), '"a: b"')
    _eq("dedup_empty_lines", dedup_empty_lines("a\n\n\n\nb\n\n\nc"), "a\n\nb\n\nc")
    h = _Buffer()
    write_header(h, "1.12")
    _eq(
        "write_header",
        str(h),
        '# TomSpecs document (*.tomspecs.yaml). Hierarchical format v2.\nversion: 2\nmodelVersion: "1.12"\n',
    )
    h0 = _Buffer()
    write_header(h0)
    _eq(
        "write_header.noModel",
        str(h0),
        "# TomSpecs document (*.tomspecs.yaml). Hierarchical format v2.\nversion: 2\n",
    )
    s = _Buffer()
    write_scalar(s, 2, "title", "Line one\nLine two")
    _eq("write_scalar", str(s), '  "title": |2-\n    Line one\n    Line two\n')
    s2 = _Buffer()
    write_scalar(s2, 0, "a key", "plain")
    _eq("write_scalar.key", str(s2), '"a key": |2-\n  plain\n')


def test_spec_document_yaml_class() -> None:
    review = {"DEMO/items-2": {"note": "x"}, "DEMO/TTL": {"note": "y"}}
    renamed = {"DEMO/items-2": "DEMO/items-1"}
    _eq(
        "SpecDocumentYaml.rekey_review",
        SpecDocumentYaml.rekey_review(review, renamed),
        rekey_review(review, renamed),
    )
    _check(
        "SpecDocumentYaml.stale_review_paths",
        callable(SpecDocumentYaml.stale_review_paths),
    )


def test_strings() -> None:
    _eq(
        "code_specs_yaml_string",
        code_specs_yaml_string('He said "hi"\\\n\tx'),
        '"He said \\"hi\\"\\\\\\n\\tx"',
    )
    _eq("som_model_version_string", som_model_version_string(1, "12"), "1.0")
    _eq("som_model_version_string.noLabel", som_model_version_string(2, None), "2.0")


def test_format_conflict_block() -> None:
    lines = format_conflict_block(
        id="X-1",
        topic="Timeout",
        text="Which limit?",
        base="30 minutes",
        alternatives=[
            SpecConflictAlternative(letter="a", members=("alice",), text="15 minutes"),
            SpecConflictAlternative(
                letter="b", members=("bob", "carol"), text="60 minutes\nand a second line"
            ),
        ],
    )
    _eq(
        "format_conflict_block",
        lines,
        [
            "> ⚖️ **X-1 — Timeout:** Which limit?",
            "> - (base) 30 minutes",
            "> - (a) **alice:** 15 minutes",
            "> - (b) **bob, carol:** 60 minutes",
            ">   and a second line",
            ">",
            "> **Decision:**",
        ],
    )


def main() -> int:
    test_exported()
    test_yaml_helpers()
    test_spec_document_yaml_class()
    test_strings()
    test_format_conflict_block()
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
