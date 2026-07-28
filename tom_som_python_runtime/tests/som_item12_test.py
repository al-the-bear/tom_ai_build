#!/usr/bin/env python3
"""Behavioural tests for SOM §21: :meth:`SpecModel.root_by_type` and
:meth:`SpecDocument.to_markdown`.

A faithful port of the Dart reference item-12 groups:

  * ``tom_som_dart_runtime/test/spec_model_test.dart`` →
    ``group('SpecModel.rootByType (item 12)')``;
  * ``tom_som_dart_runtime/test/spec_document_markdown_test.dart`` →
    ``group('SpecDocument.toMarkdown (item 12)')``.

Proves:

  * ``root_by_type`` returns the matching root and raises a ``ValueError``
    naming the missing type and the available ones when none matches;
  * ``to_markdown`` with an explicit ``root_type`` equals the direct
    ``SpecDocumentMarkdown(...).export_root(...)`` output;
  * ``to_markdown`` defaults to the single populated root;
  * ``to_markdown`` raises a ``RuntimeError`` when zero roots are populated;
  * ``to_markdown`` raises a ``RuntimeError`` naming the candidates when more
    than one is populated.

The CS12-D3 error-class split is asserted directly: an unknown ``root_type`` is
a bad argument (``ValueError``), whereas an ambiguous default is document state
(``RuntimeError``) — and the two classes are disjoint (``RuntimeError`` is not a
``ValueError``).

Run with ``python3 tests/som_item12_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SpecDocument,
    SpecDocumentMarkdown,
    SpecModel,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


# --- fixtures (mirroring the Dart reference) --------------------------------


def _two_root_model() -> SpecModel:
    return SpecModel.from_json(
        {
            "roots": [
                {"type": "Alpha", "title": "Alpha Doc", "sectionId": "A00"},
                {"type": "Beta", "title": "Beta Doc", "sectionId": "B00"},
            ],
            "classes": {},
        }
    )


def _sample_json() -> dict:
    """A class graph covering content, enum, form, complex and a list of complex
    items, mirroring the Dart markdown-test fixture."""
    return {
        "roots": [
            {
                "type": "DemoDoc",
                "title": "Demo Document",
                "sectionId": "D00",
                "description": "A demo document.",
            },
        ],
        "classes": {
            "DemoDoc": {
                "name": "DemoDoc",
                "sectionId": "D00",
                "fields": [
                    {"name": "overview", "kind": "content", "sectionId": "D00-OVR"},
                    {
                        "name": "status",
                        "kind": "enum",
                        "sectionId": "D00-ST",
                        "enumValues": ["draft", "final"],
                    },
                    {
                        "name": "header",
                        "kind": "form",
                        "sectionId": "D00-HDR",
                        "formFields": [
                            {"name": "author", "label": "Author", "type": "String"},
                            {"name": "reviewer", "label": "Reviewer", "type": "String"},
                        ],
                    },
                    {
                        "name": "meta",
                        "kind": "complex",
                        "type": "DemoMeta",
                        "sectionId": "D00-MET",
                    },
                    {
                        "name": "items",
                        "kind": "list",
                        "elementType": "DemoItem",
                        "elementIsComplex": True,
                        "sectionId": "D00-ITM",
                    },
                ],
            },
            "DemoMeta": {
                "name": "DemoMeta",
                "sectionId": "D00-MET",
                "fields": [
                    {"name": "note", "kind": "content", "sectionId": "D00-MET-NOTE"},
                ],
            },
            "DemoItem": {
                "name": "DemoItem",
                "fields": [
                    {"name": "label", "kind": "content", "sectionId": "D01-LBL"},
                    {"name": "body", "kind": "content", "sectionId": "D01-BODY"},
                ],
            },
        },
    }


def _model() -> SpecModel:
    return SpecModel.from_json(_sample_json())


def _populated() -> SpecDocument:
    doc = SpecDocument()
    doc.set_content("D00/D00-OVR", "An overview paragraph.\nWith two lines.")
    doc.set_content("D00/D00-ST", "final")
    doc.set_form_field("D00/D00-HDR", "author", "Ada Lovelace")
    doc.set_content("D00/D00-MET/D00-MET-NOTE", "A note.")
    item = doc.add_list_item("D00/D00-ITM")
    doc.set_content(f"{item}/D01-LBL", "First item")
    item2 = doc.add_list_item("D00/D00-ITM")
    doc.set_content(f"{item2}/D01-LBL", "Second item")
    return doc


# --- SpecModel.root_by_type (item 12) ---------------------------------------


def test_root_by_type_returns_match() -> None:
    model = _two_root_model()
    _check("root_by_type.alpha", model.root_by_type("Alpha").title == "Alpha Doc")
    _check("root_by_type.beta", model.root_by_type("Beta").section_id == "B00")


def test_root_by_type_raises_naming_types() -> None:
    model = _two_root_model()
    try:
        model.root_by_type("Gamma")
        _check("root_by_type.missing-raises", False, "no ValueError raised")
    except ValueError as e:
        msg = str(e)
        _check("root_by_type.missing.names-gamma", "Gamma" in msg, msg)
        _check("root_by_type.missing.names-alpha", "Alpha" in msg, msg)
        _check("root_by_type.missing.names-beta", "Beta" in msg, msg)


# --- SpecDocument.to_markdown (item 12) -------------------------------------


def test_to_markdown_matches_explicit_root_type() -> None:
    model = _model()
    doc = _populated()
    one_liner = doc.to_markdown(model, root_type="DemoDoc")
    explicit = SpecDocumentMarkdown(model, doc).export_root(
        model.root_by_type("DemoDoc")
    )
    _check("to_markdown.explicit-equals-direct", one_liner == explicit)


def test_to_markdown_defaults_to_single_populated() -> None:
    model = _model()
    doc = _populated()
    _check(
        "to_markdown.default-equals-explicit",
        doc.to_markdown(model) == doc.to_markdown(model, root_type="DemoDoc"),
    )


def test_to_markdown_raises_when_none_populated() -> None:
    model = _model()
    try:
        SpecDocument().to_markdown(model)
        _check("to_markdown.zero-raises", False, "no RuntimeError raised")
    except RuntimeError as e:
        _check("to_markdown.zero.message", "no populated root" in str(e), str(e))
        # CS12-D3 split: ambiguity is a state error, not an argument error.
        _check(
            "to_markdown.zero.not-value-error",
            not isinstance(e, ValueError),
            type(e).__name__,
        )


def test_to_markdown_raises_naming_candidates() -> None:
    model = SpecModel.from_json(
        {
            "roots": [
                {"type": "Alpha", "title": "Alpha Doc", "sectionId": "A00"},
                {"type": "Beta", "title": "Beta Doc", "sectionId": "B00"},
            ],
            "classes": {
                "Alpha": {
                    "name": "Alpha",
                    "sectionId": "A00",
                    "fields": [
                        {"name": "overview", "kind": "content", "sectionId": "A00-OVR"},
                    ],
                },
                "Beta": {
                    "name": "Beta",
                    "sectionId": "B00",
                    "fields": [
                        {"name": "overview", "kind": "content", "sectionId": "B00-OVR"},
                    ],
                },
            },
        }
    )
    doc = SpecDocument()
    doc.set_content("A00/A00-OVR", "a")
    doc.set_content("B00/B00-OVR", "b")
    try:
        doc.to_markdown(model)
        _check("to_markdown.multi-raises", False, "no RuntimeError raised")
    except RuntimeError as e:
        msg = str(e)
        _check("to_markdown.multi.names-alpha", "Alpha" in msg, msg)
        _check("to_markdown.multi.names-beta", "Beta" in msg, msg)
        # CS12-D3 split: ambiguity is a state error, not an argument error.
        _check(
            "to_markdown.multi.not-value-error",
            not isinstance(e, ValueError),
            type(e).__name__,
        )


def main() -> int:
    test_root_by_type_returns_match()
    test_root_by_type_raises_naming_types()
    test_to_markdown_matches_explicit_root_type()
    test_to_markdown_defaults_to_single_populated()
    test_to_markdown_raises_when_none_populated()
    test_to_markdown_raises_naming_candidates()

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
