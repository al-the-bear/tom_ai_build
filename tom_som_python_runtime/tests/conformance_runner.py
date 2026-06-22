#!/usr/bin/env python3
"""Shared-corpus conformance runner for the Python generic runtime.

Loads the language-agnostic conformance corpus produced from the Dart reference
(``tom_som_conformance/corpus``) and asserts the Python port reproduces every
golden byte-for-byte and matches every behavioural case:

  * model meta-data loads (root + class structure);
  * ``state.json`` loads and re-serialises identically;
  * YAML encode == ``expected.docspecs.yaml`` (byte-for-byte);
  * YAML decode → memory → encode is byte-stable + preserves the stamp;
  * Markdown export == ``expected.md`` (byte-for-byte);
  * Markdown parse → memory → export is clean + byte-stable;
  * reflection resolution cases;
  * validation cases;
  * the imperative operations script.

Run with: ``python3 tests/conformance_runner.py``. Exit code 0 == all green.
"""

from __future__ import annotations

import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
_CORPUS = os.path.normpath(
    os.path.join(_PKG_ROOT, "..", "tom_som_conformance", "corpus")
)

sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SpecDocument,
    SpecDocumentMarkdown,
    SpecModel,
    SpecNodeKind,
    SpecReflection,
    validate_document,
    yaml_decode,
    yaml_encode,
)

_MODEL_VERSION = "1.0"


class _Failure(AssertionError):
    pass


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


def _read_json(name: str):
    return json.loads(_read(name))


def _byte_diff(label: str, actual: str, expected: str) -> str:
    if actual == expected:
        return ""
    a_lines = actual.split("\n")
    e_lines = expected.split("\n")
    for idx in range(max(len(a_lines), len(e_lines))):
        a = a_lines[idx] if idx < len(a_lines) else "<EOF>"
        e = e_lines[idx] if idx < len(e_lines) else "<EOF>"
        if a != e:
            return f"{label}: first diff at line {idx + 1}: got {a!r} want {e!r}"
    return f"{label}: differ (len got {len(actual)} want {len(expected)})"


def _load_model() -> SpecModel:
    return SpecModel.from_json(_read_json("model.meta.json"))


def _document_from_state(state: dict) -> SpecDocument:
    doc = SpecDocument()
    doc.load_json(state)
    return doc


def test_model_meta(model: SpecModel) -> None:
    root = model.roots[0]
    _check("model.root.sectionId", root.section_id == "DEMO", str(root.section_id))
    _check("model.root.type", root.type == "Demo", root.type)
    _check("model.classCount", len(model.classes) == 3, str(len(model.classes)))
    demo = model.class_named("Demo")
    _check("model.Demo.found", demo is not None)
    if demo is not None:
        names = [f.name for f in demo.fields]
        _check(
            "model.Demo.fields",
            names == ["title", "summary", "priority", "count", "details", "items", "meta"],
            str(names),
        )


def test_state_round_trip() -> None:
    state = _read_json("state.json")
    doc = _document_from_state(state)
    _check("state.toJson", doc.to_json() == state, _json_mismatch(doc.to_json(), state))


def _json_mismatch(actual, expected) -> str:
    if actual == expected:
        return ""
    return f"got {json.dumps(actual, sort_keys=True)} want {json.dumps(expected, sort_keys=True)}"


def test_yaml_encode() -> None:
    doc = _document_from_state(_read_json("state.json"))
    expected = _read("expected.docspecs.yaml")
    actual = yaml_encode(doc, model_version=_MODEL_VERSION)
    _check("yaml.encode", actual == expected, _byte_diff("yaml.encode", actual, expected))


def test_yaml_decode_round_trip() -> None:
    expected = _read("expected.docspecs.yaml")
    contents = yaml_decode(expected)
    _check("yaml.decode.stamp", contents.model_version == _MODEL_VERSION,
           str(contents.model_version))
    doc = SpecDocument()
    doc.load_json(contents.document)
    actual = yaml_encode(doc, model_version=contents.model_version or _MODEL_VERSION)
    _check("yaml.decode.reencode", actual == expected,
           _byte_diff("yaml.decode.reencode", actual, expected))


def test_markdown_export(model: SpecModel) -> None:
    doc = _document_from_state(_read_json("state.json"))
    expected = _read("expected.md")
    actual = SpecDocumentMarkdown(model, doc).export_root(model.roots[0])
    _check("md.export", actual == expected, _byte_diff("md.export", actual, expected))


def test_markdown_round_trip(model: SpecModel) -> None:
    expected = _read("expected.md")
    codec = SpecDocumentMarkdown(model, SpecDocument())
    result = codec.parse(expected)
    _check("md.parse.clean", result.is_clean,
           "; ".join(str(r) for r in result.rejections))
    # Apply the staged values to a fresh document and re-export.
    applied = SpecDocument()
    applied.load_json(
        {"content": result.content, "forms": result.forms, "lists": result.lists}
    )
    actual = SpecDocumentMarkdown(model, applied).export_root(model.roots[0])
    _check("md.parse.reexport", actual == expected,
           _byte_diff("md.parse.reexport", actual, expected))


def test_reflection(model: SpecModel) -> None:
    refl = SpecReflection(model)
    for case in _read_json("reflection_cases.json"):
        path = case["path"]
        res = refl.resolve(path)
        if not case["resolves"]:
            _check(f"reflect[{path}].none", res is None, "expected no resolution")
            continue
        if res is None:
            _check(f"reflect[{path}].some", False, "expected resolution, got None")
            continue
        _check(f"reflect[{path}].kind", res.kind.value == case["kind"],
               f"{res.kind.value} != {case['kind']}")
        field_name = res.field.name if res.field is not None else None
        _check(f"reflect[{path}].field", field_name == case["field"],
               f"{field_name} != {case['field']}")
        target = res.target_class.name if res.target_class is not None else None
        _check(f"reflect[{path}].target", target == case["targetClass"],
               f"{target} != {case['targetClass']}")
        _check(f"reflect[{path}].leaf", res.is_value_leaf == case["isValueLeaf"],
               f"{res.is_value_leaf} != {case['isValueLeaf']}")


def test_validation(model: SpecModel) -> None:
    for case in _read_json("validation_cases.json"):
        name = case["name"]
        doc = _document_from_state(case["state"])
        errors = validate_document(model, doc)
        got = [(e.path, e.code.value) for e in errors]
        want = [(e["path"], e["code"]) for e in case["errors"]]
        _check(f"validate[{name}]", got == want, f"{got} != {want}")


def test_operations() -> None:
    doc = SpecDocument()
    for n, op in enumerate(_read_json("operations_cases.json")):
        kind = op["op"]
        if kind == "isEmpty":
            _check(f"op[{n}].isEmpty", doc.is_empty == op["expect"])
        elif kind == "setContent":
            doc.set_content(op["path"], op["value"])
        elif kind == "content":
            _check(f"op[{n}].content", doc.content(op["path"]) == op["expect"],
                   str(doc.content(op["path"])))
        elif kind == "setFormField":
            doc.set_form_field(op["path"], op["field"], op["value"])
        elif kind == "formField":
            _check(f"op[{n}].formField",
                   doc.form_field(op["path"], op["field"]) == op["expect"])
        elif kind == "addListItem":
            _check(f"op[{n}].addListItem",
                   doc.add_list_item(op["listPath"]) == op["expect"])
        elif kind == "listItems":
            _check(f"op[{n}].listItems",
                   doc.list_items(op["listPath"]) == op["expect"],
                   str(doc.list_items(op["listPath"])))
        elif kind == "listItemCount":
            _check(f"op[{n}].listItemCount",
                   doc.list_item_count(op["listPath"]) == op["expect"])
        elif kind == "hasValuesUnder":
            _check(f"op[{n}].hasValuesUnder",
                   doc.has_values_under(op["prefix"]) == op["expect"])
        elif kind == "removeListItem":
            _check(f"op[{n}].removeListItem",
                   doc.remove_list_item(op["itemPath"]) == op["expect"])
        else:  # pragma: no cover
            _check(f"op[{n}].unknown", False, kind)


def main() -> int:
    if not os.path.isdir(_CORPUS):
        print(f"corpus not found at {_CORPUS}", file=sys.stderr)
        return 2
    model = _load_model()
    test_model_meta(model)
    test_state_round_trip()
    test_yaml_encode()
    test_yaml_decode_round_trip()
    test_markdown_export(model)
    test_markdown_round_trip(model)
    test_reflection(model)
    test_validation(model)
    test_operations()

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
