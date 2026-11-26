#!/usr/bin/env python3
"""The rendition's generated parts (``spec_document_markdown_generated.py``,
SOM §11.12): the ``derived`` block helpers and placeholder, the generated
places and blocks of the real model's Requirements Specification, the option
that turns them off, and the parser removing a block — an empty value under
one is no missing value, without it it is.

The shared corpus (``link_rendition_cases.json``) pins whole renditions; this
test holds the module's own surface over the corpus's real-model case.

Plain-script style like the sibling tests: run with
``python3 tests/spec_document_markdown_generated_test.py``; exit code 0 ==
all green.
"""

from __future__ import annotations

import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import SpecDocument, SpecDocumentMarkdown, SpecModel  # noqa: E402
from tom_som_runtime.spec_document_markdown_generated import (  # noqa: E402
    K_DERIVED_PLACEHOLDER,
    Generated,
    derived_fence_close,
    opens_derived,
    resolve_derived_placeholders,
)
from tom_som_runtime.spec_document_markdown_linked import Navigation  # noqa: E402

_CORPUS = os.path.normpath(os.path.join(_PKG_ROOT, "..", "tom_som_conformance", "corpus"))
_META = os.path.join(_PKG_ROOT, "..", "tom_som_dart_v0", "meta", "spec_model.meta.json")
_TRACE_OPEN = (
    "::: {.derived label=\"Generated from each requirement's traceability; "
    'edit it there"}'
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


def test_helpers() -> None:
    _check("opens a derived block", opens_derived("::: {.derived}"))
    _check("with a label", opens_derived('::: {.derived label="x"}'))
    _check("indented up to three", opens_derived("   :::: {.derived}"))
    _check("not four spaces", not opens_derived("    ::: {.derived}"))
    _check("not another kind", not opens_derived("::: {.derivedX}"))
    _check("not records", not opens_derived("::: {.records}"))
    close = derived_fence_close(":::: {.derived}")
    _check("closes with as many colons", close.search("::::") is not None)
    _check("or more", close.search(":::::  ") is not None)
    _check("not fewer", close.search(":::") is None)
    p = K_DERIVED_PLACEHOLDER
    _eq(
        "removed with its blank line",
        resolve_derived_placeholders(f"# H\n\n{p}\n\nText.\n"),
        "# H\n\nText.\n",
    )
    _eq(
        "an empty block before a derived value",
        resolve_derived_placeholders(f"# H\n\n{p}\n\n::: {{.derived}}\nx\n:::\n"),
        "# H\n\n::: {.derived}\n:::\n\n::: {.derived}\nx\n:::\n",
    )


def test_requirements_specification() -> None:
    with open(os.path.join(_CORPUS, "link_rendition_cases.json"), encoding="utf-8") as fh:
        table = json.load(fh)
    c = next(c for c in table["cases"] if "generatedTrace" in c["intent"])
    with open(_META, encoding="utf-8") as fh:
        model = SpecModel.from_json(json.load(fh))
    doc = SpecDocument()
    doc.load_json(c["state"])
    root = next(r for r in model.roots if r.section_id == "RSP")
    codec = SpecDocumentMarkdown(model, doc, "links")
    gen = Generated(Navigation(codec, root))
    _eq(
        "the places with rows",
        sorted(gen.blocks),
        ["RSP/RERE-REQU-LST", "RSP/RSP-TRAC", "RSP/requirementCoverage"],
    )
    _check("a place", gen.is_place("RSP/RSP-TRAC"))
    _check("no place", not gen.is_place("RSP/functionalRequirements"))
    _check("forces its heading", gen.forces("RSP/RSP-TRAC"))
    _check("and its ancestors", gen.forces("RSP"))
    _check("not elsewhere", not gen.forces("RSP/functionalRequirements"))
    trace = gen.blocks["RSP/RSP-TRAC"]
    _eq("the block opens labelled", trace[0], _TRACE_OPEN)
    _eq("then the header", trace[1], "| Requirement | Use cases | Screens | Data entities | Tests |")
    _eq("and closes", trace[-1], ":::")

    md = codec.export_root(root)
    _eq("the golden rendition", md, c["expect"]["markdown"])
    plain = SpecDocumentMarkdown(model, doc, "links", generated_parts=False).export_root(root)
    _check("generated_parts=False writes none", "{.derived" not in plain)
    for text, what in ((md, "with generated parts"), (plain, "without")):
        parsed = SpecDocument.from_markdown(text, model)
        _eq(f"parsed {what}: no rejection", parsed.rejections, [])
        _eq(f"parsed {what}: the document", parsed.document.to_json(), doc.to_json())

    # Without its block the empty traceability matrix is a missing value.
    lines = md.split("\n")
    i = lines.index(_TRACE_OPEN)
    j = i
    while lines[j] != ":::":
        j += 1
    given = "\n".join(lines[:i] + lines[j + 2:])
    parsed = SpecDocument.from_markdown(given, model)
    _eq(
        "the block removed: a missing value",
        [(r.reason.value, r.anchor) for r in parsed.rejections],
        [("missingValue", "RSP/RSP-TRAC")],
    )


def main() -> int:
    test_helpers()
    test_requirements_specification()
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
