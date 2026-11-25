#!/usr/bin/env python3
"""Rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): an import
accepting rejections keeps each rejected block as a ``rejected`` div in the
text of the section it stood in (else its parent), at its place. The kept
document re-exports and re-imports without a rejection and to the same
document, and the validator reports each div as ``rejectedBlock``. A port of
``tom_som_typescript_runtime/tests/spec_document_markdown_rejected_kept_test.ts``;
the single cases are pinned in the conformance corpus
(``markdown_apply_cases.json``).

Run with: ``python3 tests/spec_document_markdown_rejected_kept_test.py``.
Exit code 0 == green.
"""

from __future__ import annotations

import json
import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
_CORPUS = os.path.normpath(
    os.path.join(_PKG_ROOT, "..", "tom_som_conformance", "corpus")
)

sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    DocSpecsSchema,
    DocSpecsViolationRule,
    SpecDocument,
    SpecDocumentMarkdown,
    SpecMarkdownResult,
    SpecModel,
    validate_spec_document,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def _read(name: str) -> str:
    with open(os.path.join(_CORPUS, name), "r", encoding="utf-8") as fh:
        return fh.read()


_model: SpecModel
_golden: str
_variants: dict[str, str] = {}


def _sub(source: str, target: str) -> str:
    at = _golden.find(source)
    if at < 0:
        raise RuntimeError(f'the golden has no "{source}"')
    return _golden[:at] + target + _golden[at + len(source):]


def _parse(markdown: str) -> SpecMarkdownResult:
    return SpecDocumentMarkdown(_model, SpecDocument()).parse(markdown)


def _kept(markdown: str) -> SpecDocument:
    doc = SpecDocument()
    doc.apply_markdown_result(_parse(markdown), allow_rejections=True)
    return doc


def _canonical(doc: SpecDocument) -> str:
    return json.dumps(doc.to_json(), sort_keys=True)


def _fill_variants() -> None:
    _variants["unknown section"] = (
        _golden + "\n## <!--[NOPE]--> Not A Section\n\nText with no home.\n"
    )
    _variants["near-miss row"] = _sub(
        "| Owner | Bob |", "| Owner | Bob |\n| Ownr | Carol |"
    )
    _variants["row given twice"] = _sub(
        "| Estimate | 8 |", "| Estimate | 8 |\n| Owner | Carol |"
    )
    _variants["paragraph given twice"] = _sub(
        "- backup: alice@example.com\n",
        "- backup: alice@example.com\nContact: carol@example.com\n- line\n",
    )
    _variants["table without delimiter"] = _sub(
        "| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |",
        "| TomSpecField | Value |\n| Owner | Bob |",
    )
    _variants["records column"] = _sub(
        "| Id | Title | Note |", "| Id | Title | Nte |"
    )
    _variants["records row"] = _sub(
        '| <a id="CARD-2"></a>CARD-2 |  | second card |',
        '| <a id="CARD-2"></a>CARD-2 | second card |',
    )
    _variants["unclosed records fence"] = _sub(
        "| second card |\n:::\n", "| second card |\n"
    )
    _variants["section-table row"] = _sub(
        '| <a id="DLV-1/DLR-1"></a>DLR-LST / DLR-1 | Area | CE-NV |\n'
        "|  | Mapping | dart-tom |\n\n### <!--[DLV-2]",
        '| <a id="DLV-1/DLR-1"></a>DLR-LS / DLR-1 | Area | CE-NV |\n'
        "|  | Mapping | dart-tom |\n\n### <!--[DLV-2]",
    )
    _variants["orphan text"] = "Stray text.\n\n" + _golden
    _variants["child under a value leaf"] = _sub(
        "high\n\n## <!--[CNT]-->",
        "high\n\n### <!--[X]--> Child\n\nchild text\n\n## <!--[CNT]-->",
    )
    _variants["nested unknown sections"] = (
        _golden + "\n## <!--[NOPE]--> A\n\nA text\n\n### <!--[NOPE2]--> B\n\nB\n"
    )


_REJECTED_DIV = re.compile(
    r'^:{3,} \{\.rejected reason="(\w+)" line="(\d+)"', re.MULTILINE
)


def test_every_variant() -> None:
    _check("a clean parse keeps nothing", not _parse(_golden).kept_content)
    schema = DocSpecsSchema.from_yaml_text(
        'title-format: "# <!--[DEMO]--> Demo"\n'
    )
    for name, markdown in _variants.items():
        result = _parse(markdown)
        _check(f"{name}: rejected", bool(result.rejections))
        doc = _kept(markdown)
        values = [str(v) for v in doc.to_json().get("content", {}).values()]
        divs = [
            f"{m.group(1)}@{m.group(2)}"
            for m in _REJECTED_DIV.finditer("\n".join(values))
        ]
        want = [f"{r.reason.value}@{r.line}" for r in result.rejections]
        _check(f"{name}: every rejection kept", divs == want, f"{divs} != {want}")

        rendition = doc.to_markdown(_model, "Demo")
        again = _parse(rendition)
        _check(
            f"{name}: re-imports clean",
            not again.rejections,
            "; ".join(r.message for r in again.rejections),
        )
        reloaded = SpecDocument()
        reloaded.apply_markdown_result(again, allow_rejections=True)
        _check(
            f"{name}: re-imports the same document",
            _canonical(reloaded) == _canonical(doc),
        )

        reported = sum(
            1
            for v in validate_spec_document(_model, doc, schema, "Demo")
            if v.rule == DocSpecsViolationRule.REJECTED_BLOCK
        )
        _check(
            f"{name}: reported",
            reported == len(result.rejections),
            f"{reported} != {len(result.rejections)}",
        )


def test_refused() -> None:
    doc = SpecDocument()
    content = {"DEMO/TTL": "base"}
    doc.load_json({"content": dict(content)})
    threw = False
    try:
        doc.apply_markdown_result(_parse(_variants["unknown section"]))
    except RuntimeError:
        threw = True
    _check("a refused import throws", threw)
    got = doc.to_json().get("content")
    _check(
        "a refused import never reads the kept blocks",
        got == content,
        str(got),
    )


def test_attributes() -> None:
    row = _kept(_variants["near-miss row"]).content("DEMO/DET") or ""
    _check(
        "near-miss row names the field",
        'reason="unknownField" line="31" field="owner" ' in row,
        row,
    )
    twice = _kept(_variants["row given twice"]).content("DEMO/DET") or ""
    _check(
        "a field given twice names the kept form",
        'field="owner" kept="DEMO/DET" ' in twice,
        twice,
    )
    cell = (
        _kept(_variants["section-table row"]).content("DEMO/DLV-LST-1/content")
        or ""
    )
    _check(
        "a near-miss cell names the section",
        'section="DLR-LST / DLR-1" ' in cell,
        cell,
    )
    _check(
        "the skipped continuation row is in the block",
        "|  | Mapping | dart-tom |" in cell,
    )


def test_parents() -> None:
    doc = _kept(_variants["unclosed records fence"])
    _check(
        "the list container keeps no text",
        doc.content("DEMO/CARD-LST") is None,
        str(doc.content("DEMO/CARD-LST")),
    )
    root = doc.content("DEMO") or ""
    _check("the unclosed fence is escaped", "\n\\::: {.records}\n" in root, root)
    _check("the div closes", root.rstrip().endswith("\n:::"), root)
    records = _kept(_variants["records column"]).content("DEMO") or ""
    _check(
        "a records div is kept in the parent",
        records.startswith(':::: {.rejected reason="unknownField"'),
        records,
    )
    _check("its own div stays inside", "\n::: {.records}\n" in records, records)


def test_place() -> None:
    doc = _kept(_variants["paragraph given twice"])
    _check(
        "the first value is kept",
        (doc.form_field("DEMO/DET", "contact") or "").startswith(
            "bob@example.com"
        ),
    )
    want = (
        "Captured during the November review.\n"
        "Owner: this line is prose, not the field.\n\n"
        '::: {.rejected reason="malformedBlock" line="35" field="contact" '
        "kept=\"DEMO/DET\" label=\"field 'contact' given twice\"}\n"
        "Contact: carol@example.com\n- line\n:::"
    )
    got = doc.content("DEMO/DET") or ""
    _check(
        "a paragraph given twice is kept at its place",
        got == want,
        f"\n--- got\n{got}\n--- want\n{want}",
    )
    orphan = _kept(_variants["orphan text"]).content("DEMO") or ""
    _check(
        "orphan text starts the root",
        orphan.startswith('::: {.rejected reason="orphanContent" line="1"'),
        orphan,
    )


def main() -> int:
    global _model, _golden
    _model = SpecModel.from_json(json.loads(_read("model.meta.json")))
    _golden = _read("expected.tables.md")
    _fill_variants()
    test_every_variant()
    test_refused()
    test_attributes()
    test_parents()
    test_place()

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
