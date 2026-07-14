#!/usr/bin/env python3
"""Tests for the DocSpecs-conform Markdown codec (``spec_document_markdown.py``,
DR6 / DR1 §1) — a port of the Dart reference suite
``tom_som_dart_runtime/test/spec_document_markdown_test.dart``.

The generated ``*.md`` is a genuine DocSpecs document: line 1 is the
``<!-- docspec: <schema-id>/<version> -->`` declaration, every populated
section is a heading of the form ``## <!--[SECTION-ID]--> Title``, content
sections are normal markdown text (no fences), ``@Form`` sections use the
plain-text ``FieldName: value`` format, and list items sit as sub-headings
directly under the owner (no container heading).

Run with: ``python3 tests/spec_document_markdown_test.py``. Exit code 0 == green.
"""

from __future__ import annotations

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)

sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SpecDocument,
    SpecDocumentMarkdown,
    SpecMarkdownRejectReason,
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


def _sample_json() -> dict:
    """A class graph covering content, enum, ``@Form``, a complex sub-section
    and a list of complex items, so the round-trip exercises every store."""
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


# A d4rt-flutter body that is multi-line and embeds a run of three backticks
# mid-line — must pass through the plain-text body verbatim.
_D4RT_BODY = (
    "Column(\n"
    "  children: [\n"
    '    Text("hi"),\n'
    "  ],\n"
    ") // not a fence: ``` still inside the body"
)

# Content that exercises embedded markdown formatting: emphasis, a bullet
# list, a fenced code block containing heading-like lines, and a leading `#`
# line at column 0 (which the emitter escapes as `\#`).
_RICH_MARKDOWN = (
    "Intro with **bold** and *italic*.\n"
    "\n"
    "- first bullet\n"
    "- second bullet\n"
    "\n"
    "```dart\n"
    "# not a heading — shielded by the fence\n"
    "## also shielded\n"
    "void main() {}\n"
    "```\n"
    "\n"
    "# looks like a heading at column 0\n"
    "trailing paragraph"
)


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
    doc.set_content(f"{item}/D01-BODY", _D4RT_BODY)
    item2 = doc.add_list_item("D00/D00-ITM")
    doc.set_content(f"{item2}/D01-LBL", "Second item")
    return doc


def _export(doc: SpecDocument) -> str:
    model = _model()
    return SpecDocumentMarkdown(model, doc).export_root(model.roots[0])


def _reload(md: str):
    """Parses *md* into a fresh document via the staged-values report."""
    target = SpecDocument()
    report = SpecDocumentMarkdown(_model(), target).parse(md)
    target.load_json({
        "content": report.content,
        "forms": report.forms,
        "lists": report.lists,
    })
    return target, report


def _parse(md: str):
    return SpecDocumentMarkdown(_model(), SpecDocument()).parse(md)


def _raises(fn, exc_type, contains: str = "") -> bool:
    try:
        fn()
        return False
    except exc_type as e:
        return contains in str(e)
    except Exception:
        return False


# --- export — DocSpecs format (DR1 §1) --------------------------------------


def test_export_format() -> None:
    md = _export(_populated())
    first = md.split("\n")[0]
    _check("export.docspec.prefix",
           first.startswith("<!-- docspec: demo-document/"), first)
    _check("export.docspec.suffix", first.endswith("-->"), first)

    _check("export.heading.root", "# <!--[D00]--> Demo Document" in md)
    _check("export.heading.overview", "## <!--[D00-OVR]--> Overview" in md)
    _check("export.heading.status", "## <!--[D00-ST]--> Status" in md)
    _check("export.heading.header", "## <!--[D00-HDR]--> Header" in md)
    _check("export.heading.meta", "## <!--[D00-MET]--> Meta" in md)
    _check("export.heading.note", "### <!--[D00-MET-NOTE]--> Note" in md)

    _check("export.content.plain",
           "An overview paragraph.\nWith two lines." in md)
    _check("export.content.noFence",
           not any(l.startswith("```") for l in md.split("\n")))
    _check("export.content.noFieldAnchor", "<!-- field:" not in md)
    _check("export.content.noPathHeading", "D00/D00-OVR" not in md)

    _check("export.form.sparse.author", "Author: Ada Lovelace" in md)
    _check("export.form.sparse.noReviewer", "Reviewer" not in md)

    _check("export.item.1", "## <!--[items-1]--> Demo Item 1" in md)
    _check("export.item.2", "## <!--[items-2]--> Demo Item 2" in md)
    _check("export.item.label", "### <!--[D01-LBL]--> Label" in md)
    _check("export.item.noContainer", "<!--[D00-ITM]-->" not in md)

    _check("export.noSchemaDescription", "A demo document." not in md)


def test_export_stored_item_id() -> None:
    doc = SpecDocument()
    item = doc.add_list_item("D00/D00-ITM", section_id="D01-CUSTOM")
    doc.set_content(f"{item}/D01-LBL", "Custom-id item")
    md = _export(doc)
    # DRC5: md list identity is purely positional. The stored id (`D01-CUSTOM`)
    # is not surfaced in md; the anonymous positional id is emitted instead.
    _check("export.storedId.positional",
           "## <!--[items-1]--> Demo Item 1" in md, md)
    _check("export.storedId.noStored", "D01-CUSTOM" not in md, md)


def test_export_unterminated_fence_throws() -> None:
    doc = SpecDocument()
    doc.set_content("D00/D00-OVR", "before\n```dart\nnever closed")
    _check("export.untermFence.raises",
           _raises(lambda: _export(doc), ValueError, "unterminated"))


# --- SpecDocument.to_markdown (item 12) --------------------------------------


def test_to_markdown() -> None:
    model = _model()
    doc = _populated()
    one_liner = doc.to_markdown(model, root_type="DemoDoc")
    explicit = SpecDocumentMarkdown(model, doc).export_root(
        model.root_by_type("DemoDoc")
    )
    _check("toMarkdown.explicitRoot", one_liner == explicit)
    _check("toMarkdown.defaultRoot",
           doc.to_markdown(model) == doc.to_markdown(model, root_type="DemoDoc"))
    _check("toMarkdown.emptyThrows",
           _raises(lambda: SpecDocument().to_markdown(model), RuntimeError,
                   "no populated root"))

    two_model = SpecModel.from_json({
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
    })
    doc2 = SpecDocument()
    doc2.set_content("A00/A00-OVR", "a")
    doc2.set_content("B00/B00-OVR", "b")
    _check("toMarkdown.twoRootsThrows.alpha",
           _raises(lambda: doc2.to_markdown(two_model), RuntimeError, "Alpha"))
    _check("toMarkdown.twoRootsThrows.beta",
           _raises(lambda: doc2.to_markdown(two_model), RuntimeError, "Beta"))


# --- round-trip ---------------------------------------------------------------


def test_round_trip_values() -> None:
    md = _export(_populated())
    target, report = _reload(md)
    _check("roundTrip.clean", report.is_clean,
           "; ".join(str(r) for r in report.rejections))
    _check("roundTrip.overview",
           target.content("D00/D00-OVR")
           == "An overview paragraph.\nWith two lines.")
    _check("roundTrip.status", target.content("D00/D00-ST") == "final")
    _check("roundTrip.author",
           target.form_field("D00/D00-HDR", "author") == "Ada Lovelace")
    _check("roundTrip.note",
           target.content("D00/D00-MET/D00-MET-NOTE") == "A note.")
    items = target.list_items("D00/D00-ITM")
    _check("roundTrip.itemCount", len(items) == 2, str(items))
    if len(items) == 2:
        _check("roundTrip.item1.label",
               target.content(f"{items[0]}/D01-LBL") == "First item")
        # The embedded d4rt body survives verbatim, backticks and all.
        _check("roundTrip.item1.body",
               target.content(f"{items[0]}/D01-BODY") == _D4RT_BODY,
               repr(target.content(f"{items[0]}/D01-BODY")))
        _check("roundTrip.item2.label",
               target.content(f"{items[1]}/D01-LBL") == "Second item")


def test_round_trip_byte_stable() -> None:
    md1 = _export(_populated())
    reloaded, _ = _reload(md1)
    md2 = _export(reloaded)
    _check("roundTrip.byteStable", md2 == md1)


def test_round_trip_rich_markdown() -> None:
    doc = SpecDocument()
    doc.set_content("D00/D00-OVR", _RICH_MARKDOWN)
    md1 = _export(doc)
    # Fence-shielded heading-like lines are NOT escaped; the column-0 `#`
    # line outside the fence IS.
    _check("richMd.fenceShielded",
           "\n# not a heading — shielded by the fence\n" in md1)
    _check("richMd.escapedHeading",
           "\n\\# looks like a heading at column 0\n" in md1)

    reloaded, report = _reload(md1)
    _check("richMd.clean", report.is_clean,
           "; ".join(str(r) for r in report.rejections))
    _check("richMd.value", reloaded.content("D00/D00-OVR") == _RICH_MARKDOWN,
           repr(reloaded.content("D00/D00-OVR")))
    _check("richMd.byteStable", _export(reloaded) == md1)


def test_round_trip_stored_item_id() -> None:
    doc = SpecDocument()
    item = doc.add_list_item("D00/D00-ITM", section_id="D01-CUSTOM")
    doc.set_content(f"{item}/D01-LBL", "Custom-id item")
    md1 = _export(doc)
    # DRC5: a stored id does not round-trip through md; the item reloads anonymous.
    _check("storedId.noStored", "D01-CUSTOM" not in md1, md1)
    reloaded, report = _reload(md1)
    _check("storedId.clean", report.is_clean,
           "; ".join(str(r) for r in report.rejections))
    items = reloaded.list_items("D00/D00-ITM")
    _check("storedId.itemCount", len(items) == 1, str(items))
    if len(items) == 1:
        _check("storedId.sectionId",
               reloaded.item_section_id(items[0]) is None,
               str(reloaded.item_section_id(items[0])))
        _check("storedId.label",
               reloaded.content(f"{items[0]}/D01-LBL") == "Custom-id item")
    _check("storedId.byteStable", _export(reloaded) == md1)


def test_round_trip_label_shaped_continuation() -> None:
    doc = SpecDocument()
    doc.set_form_field(
        "D00/D00-HDR", "author",
        "Ada Lovelace\nNote: also a mathematician\nplain line",
    )
    md1 = _export(doc)
    # The label-shaped continuation is space-escaped on emit.
    _check("formCont.escaped", "\n Note: also a mathematician\n" in md1, md1)

    reloaded, report = _reload(md1)
    _check("formCont.clean", report.is_clean,
           "; ".join(str(r) for r in report.rejections))
    _check("formCont.value",
           reloaded.form_field("D00/D00-HDR", "author")
           == "Ada Lovelace\nNote: also a mathematician\nplain line",
           repr(reloaded.form_field("D00/D00-HDR", "author")))
    _check("formCont.byteStable", _export(reloaded) == md1)


# --- parse-rejection protocol (DR1 §1.7) --------------------------------------


def test_reject_unknown_section() -> None:
    # The bogus heading is nested under `meta` (which has no list children);
    # directly under the root any unresolved id would be absorbed by the
    # single-list-child fallback as a stored-id item.
    md = (
        "<!-- docspec: demo-document/1.0 -->\n"
        "# <!--[D00]--> Demo Document\n\n"
        "## <!--[D00-OVR]--> Overview\n\n"
        "kept\n\n"
        "## <!--[D00-MET]--> Meta\n\n"
        "### <!--[D00-NOPE]--> Bogus\n\n"
        "dropped\n"
    )
    report = _parse(md)
    _check("reject.unknown.dirty", not report.is_clean)
    _check("reject.unknown.reason",
           any(r.anchor == "D00-NOPE"
               and r.reason == SpecMarkdownRejectReason.UNKNOWN_SECTION
               for r in report.rejections),
           "; ".join(str(r) for r in report.rejections))
    _check("reject.unknown.siblingsKept",
           report.content.get("D00/D00-OVR") == "kept")


def test_reject_malformed_heading() -> None:
    md = (
        "<!-- docspec: demo-document/1.0 -->\n"
        "# <!--[D00]--> Demo Document\n\n"
        "## Overview without an id comment\n\n"
        "lost\n"
    )
    report = _parse(md)
    _check("reject.malformed.reason",
           any(r.reason == SpecMarkdownRejectReason.MALFORMED_HEADING
               for r in report.rejections),
           "; ".join(str(r) for r in report.rejections))
    _check("reject.malformed.noContent", not report.content,
           str(report.content))


def test_reject_orphan_preamble() -> None:
    md = (
        "stray preamble text\n"
        "# <!--[D00]--> Demo Document\n\n"
        "## <!--[D00-OVR]--> Overview\n\n"
        "kept\n"
    )
    report = _parse(md)
    _check("reject.orphanPreamble.reason",
           any(r.reason == SpecMarkdownRejectReason.ORPHAN_CONTENT
               for r in report.rejections),
           "; ".join(str(r) for r in report.rejections))
    _check("reject.orphanPreamble.kept",
           report.content.get("D00/D00-OVR") == "kept")


def test_reject_orphan_form_prose() -> None:
    md = (
        "# <!--[D00]--> Demo Document\n\n"
        "## <!--[D00-HDR]--> Header\n\n"
        "prose before any field label\n"
        "Author: Ada Lovelace\n"
    )
    report = _parse(md)
    _check("reject.orphanForm.reason",
           any(r.reason == SpecMarkdownRejectReason.ORPHAN_CONTENT
               for r in report.rejections),
           "; ".join(str(r) for r in report.rejections))
    # The labelled field still parses.
    _check("reject.orphanForm.fieldParsed",
           report.forms.get("D00/D00-HDR") == {"author": "Ada Lovelace"},
           str(report.forms))


def test_reject_kind_mismatch() -> None:
    md = (
        "# <!--[D00]--> Demo Document\n\n"
        "## <!--[D00-OVR]--> Overview\n\n"
        "kept\n\n"
        "### <!--[D00-MET-NOTE]--> Note\n\n"
        "misplaced\n"
    )
    report = _parse(md)
    _check("reject.kindMismatch.reason",
           any(r.reason == SpecMarkdownRejectReason.KIND_MISMATCH
               for r in report.rejections),
           "; ".join(str(r) for r in report.rejections))
    _check("reject.kindMismatch.kept",
           report.content.get("D00/D00-OVR") == "kept")


def test_reject_missing_value() -> None:
    md = (
        "# <!--[D00]--> Demo Document\n\n"
        "## <!--[D00-OVR]--> Overview\n\n"
        "## <!--[D00-ST]--> Status\n\n"
        "final\n"
    )
    report = _parse(md)
    _check("reject.missingValue.reason",
           any(r.reason == SpecMarkdownRejectReason.MISSING_VALUE
               and r.anchor == "D00/D00-OVR"
               for r in report.rejections),
           "; ".join(str(r) for r in report.rejections))
    _check("reject.missingValue.statusKept",
           report.content.get("D00/D00-ST") == "final")


def test_case_insensitive_labels() -> None:
    md = (
        "# <!--[D00]--> Demo Document\n\n"
        "## <!--[D00-HDR]--> Header\n\n"
        "author: lower-case label\n"
    )
    report = _parse(md)
    _check("labels.caseInsensitive.clean", report.is_clean,
           "; ".join(str(r) for r in report.rejections))
    _check("labels.caseInsensitive.value",
           report.forms.get("D00/D00-HDR") == {"author": "lower-case label"},
           str(report.forms))


def test_fence_shielded_headings_stay_body() -> None:
    md = (
        "# <!--[D00]--> Demo Document\n\n"
        "## <!--[D00-OVR]--> Overview\n\n"
        "```\n"
        "## <!--[D00-ST]--> not a real heading\n"
        "```\n"
    )
    report = _parse(md)
    _check("fenceShield.clean", report.is_clean,
           "; ".join(str(r) for r in report.rejections))
    _check("fenceShield.body",
           report.content.get("D00/D00-OVR")
           == "```\n## <!--[D00-ST]--> not a real heading\n```",
           repr(report.content.get("D00/D00-OVR")))
    _check("fenceShield.noStatus", "D00/D00-ST" not in report.content)


def main() -> int:
    test_export_format()
    test_export_stored_item_id()
    test_export_unterminated_fence_throws()
    test_to_markdown()
    test_round_trip_values()
    test_round_trip_byte_stable()
    test_round_trip_rich_markdown()
    test_round_trip_stored_item_id()
    test_round_trip_label_shaped_continuation()
    test_reject_unknown_section()
    test_reject_malformed_heading()
    test_reject_orphan_preamble()
    test_reject_orphan_form_prose()
    test_reject_kind_mismatch()
    test_reject_missing_value()
    test_case_insensitive_labels()
    test_fence_shielded_headings_stay_body()

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
