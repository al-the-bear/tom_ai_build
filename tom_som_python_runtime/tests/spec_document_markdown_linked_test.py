#!/usr/bin/env python3
"""The rendition's navigation (``spec_document_markdown_linked.py``):
qualified anchors (SOM §11.2), the markable places and the ``linked``
marker's entries (SOM §11.11), the placeholder resolution, the option that
turns the marker off and the parser removing it.

The shared corpus (``link_rendition_cases.json``) pins whole renditions; this
test holds the module's own surface over the corpus's ``links.meta.json``.

Plain-script style like the sibling tests: run with
``python3 tests/spec_document_markdown_linked_test.py``; exit code 0 == all
green.
"""

from __future__ import annotations

import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import SpecDocument, SpecDocumentMarkdown, SpecModel  # noqa: E402
from tom_som_runtime.spec_document_markdown_linked import (  # noqa: E402
    ANCHOR_CONTAINER,
    ANCHOR_COPY,
    ANCHOR_ITEM,
    ANCHOR_PLAIN,
    K_LINKED_PLACEHOLDER,
    Navigation,
    cut_pattern,
    is_linked_paragraph,
    qualify_anchor,
    resolve_linked_placeholders,
)

_CORPUS = os.path.normpath(os.path.join(_PKG_ROOT, "..", "tom_som_conformance", "corpus"))

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


def _read_json(name: str):
    with open(os.path.join(_CORPUS, name), "r", encoding="utf-8") as fh:
        return json.load(fh)


def _blueprint_case() -> dict:
    table = _read_json("link_rendition_cases.json")
    return next(c for c in table["cases"] if "copyOf" in c["intent"])


def test_qualify_anchor() -> None:
    _eq("plain at the top", qualify_anchor(None, "BLU", "REQS", ANCHOR_PLAIN), ("REQS", None))
    _eq(
        "item opens a scope",
        qualify_anchor(None, "REQS", "REQ-EXPORT", ANCHOR_ITEM),
        ("REQ-EXPORT", ["REQ-EXPORT"]),
    )
    _eq(
        "plain below an item",
        qualify_anchor(["REQ-EXPORT"], "REQ-EXPORT", "REQD", ANCHOR_PLAIN),
        ("REQ-EXPORT/REQD", ["REQ-EXPORT", "REQD"]),
    )
    _eq(
        "container keeps the scope",
        qualify_anchor(["REQ-EXPORT"], "REQ-EXPORT", "LNK-ITEM-LST", ANCHOR_CONTAINER),
        ("REQ-EXPORT/LNK-ITEM-LST", ["REQ-EXPORT"]),
    )
    _eq(
        "copy starts at its section",
        qualify_anchor(None, "CSUM", "CRIT", ANCHOR_COPY),
        ("CSUM/CRIT", ["CSUM", "CRIT"]),
    )
    _eq("cut_pattern", cut_pattern("BLU/REQ-ITEM-LST-*/REQD"), "BLU/REQ-ITEM-LST")
    _eq("cut_pattern without a list", cut_pattern("BLU/REQS"), "BLU/REQS")


def test_linked_paragraph() -> None:
    _check("one span", is_linked_paragraph("[Copy of [CRIT](#CRIT), edit it there]{.linked}"))
    _check("empty span", is_linked_paragraph("[]{.linked}"))
    _check("surrounding blanks", is_linked_paragraph("  []{.linked}\n"))
    _check("another kind", not is_linked_paragraph("[x]{.aside}"))
    _check("text after", not is_linked_paragraph("[x]{.linked} and more"))
    _check("two spans", not is_linked_paragraph("[x]{.linked} [y]{.linked}"))


def test_placeholders() -> None:
    p = K_LINKED_PLACEHOLDER
    _eq(
        "removed with its blank line",
        resolve_linked_placeholders(f"# H\n\n{p}\n\nText.\n"),
        "# H\n\nText.\n",
    )
    _eq(
        "empty marker before a linked value",
        resolve_linked_placeholders(f"# H\n\n{p}\n\n[x]{{.linked}}\n"),
        "# H\n\n[]{.linked}\n\n[x]{.linked}\n",
    )
    _eq("nothing to resolve", resolve_linked_placeholders("a\nb"), "a\nb")


def test_navigation() -> None:
    model = SpecModel.from_json(_read_json("links.meta.json"))
    c = _blueprint_case()
    doc = SpecDocument()
    doc.load_json(c["state"])
    root = next(r for r in model.roots if r.section_id == "BLU")
    codec = SpecDocumentMarkdown(model, doc, "links")
    nav = Navigation(codec, root)
    item = "BLU/requirements/REQ-ITEM-LST-1"
    _eq("item anchor", nav.anchor_of(item), "REQ-EXPORT")
    _eq("below the item", nav.anchor_of(f"{item}/REQD"), "REQ-EXPORT/REQD")
    _eq("copy anchor", nav.anchor_of("BLU/criteriaSummary/criteria"), "CSUM/CRIT")
    _eq("item parts", nav.item_parts(item), ("BLU/requirements/REQ-ITEM-LST", "REQ-ITEM-LST-1"))
    _eq("no item", nav.item_parts("BLU/requirements"), None)
    _check("the copy is markable", nav.markable("BLU/criteriaSummary/criteria"))
    _check("the root is not markable", not nav.markable("BLU"))
    _eq(
        "copy entry",
        nav.entries("BLU/criteriaSummary/criteria"),
        ["Copy of [CRIT](#CRIT), edit it there"],
    )
    _eq(
        "extracted entry",
        nav.entries(f"{item}/LNK-ITEM-LST"),
        ["Extracted from [REQD](#REQ-EXPORT/REQD)"],
    )
    entries = nav.entries(item)
    _check(
        "item entries in order",
        len(entries) == 3
        and entries[0].startswith("Also in [DET REQ-EXPORT](links.det.tomspecs.md#REQ-EXPORT)")
        and entries[1] == "Summarised in [KEY-1](#KEY-1)"
        and entries[2].startswith("Derived from "),
        repr(entries),
    )
    _eq("unmarkable answers none", nav.entries("BLU"), [])

    md = codec.export_root(root)
    _eq("the golden rendition", md, c["expect"]["markdown"])
    plain = SpecDocumentMarkdown(model, doc, "links", linked_markers=False).export_root(root)
    _check("linked_markers=False writes none", "{.linked}" not in plain)
    _check("the anchors stay", '<a id="CSUM/CRIT"></a>' in plain)
    for text, what in ((md, "with markers"), (plain, "without markers")):
        parsed = SpecDocument.from_markdown(text, model)
        _eq(f"parsed {what}: no rejection", parsed.rejections, [])
        _eq(f"parsed {what}: the document", parsed.document.to_json(), doc.to_json())


def main() -> int:
    test_qualify_anchor()
    test_linked_paragraph()
    test_placeholders()
    test_navigation()
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
