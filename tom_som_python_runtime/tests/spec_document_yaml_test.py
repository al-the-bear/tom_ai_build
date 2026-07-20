#!/usr/bin/env python3
"""DR5 hierarchical ``*.docspecs.yaml`` v2 codec tests — a port of
``tom_som_dart_runtime/test/spec_document_yaml_test.dart``.

The codec walks the document root's SomMetaTree: sections nest, keys are
``<section-id> <member-name>``, list items key by stored section id (or an
anonymous positional ``<member>-<n>``), body text uses the literal ``content``
key, and form fields use their bare names. Round-trip is lossless modulo
the DR1 §2.4.3 empty-line dedup; version-1 files and unmatched keys are
structured load errors.

Run with: ``python3 tests/spec_document_yaml_test.py``. Exit code 0 == green.
"""

from __future__ import annotations

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SpecDocument,
    SpecModel,
    SpecYamlFormatException,
    build_som_meta_tree,
    yaml_decode,
    yaml_encode,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def _throws_format(fn, contains: str = "") -> bool:
    try:
        fn()
        return False
    except SpecYamlFormatException as e:
        return contains in e.message
    except Exception:
        return False


def _model() -> SpecModel:
    """A model exercising every field kind: root body content, a content
    section with a nested complex section, a complex list with
    ``@SectionIdPattern``, a scalar list, a ``@Form`` with a numeric field,
    enum and int leaves."""
    return SpecModel.from_json(
        {
            "modelVersion": 1,
            "roots": [
                {"type": "Demo", "title": "Demo Document", "sectionId": "D00"},
            ],
            "classes": {
                "Demo": {
                    "name": "Demo",
                    "sectionId": "D00",
                    "fields": [
                        {
                            "name": "overview",
                            "kind": "content",
                            "sectionId": "D00-OVR",
                            "serializationOrder": 0,
                        },
                        {
                            "name": "scope",
                            "kind": "complex",
                            "sectionId": "D00-SCO",
                            "type": "Scope",
                            "serializationOrder": 1,
                        },
                        {
                            "name": "header",
                            "kind": "form",
                            "sectionId": "D00-HDR",
                            "serializationOrder": 2,
                            "formFields": [
                                {"name": "author", "label": "Author", "type": "String"},
                                {"name": "reviewer", "label": "Reviewer", "type": "String"},
                                {"name": "revision", "label": "Revision", "type": "int"},
                            ],
                        },
                        {
                            "name": "requirements",
                            "kind": "list",
                            "sectionId": "D00-REQ",
                            "sectionIdPattern": "REQ-xxx",
                            "elementType": "Requirement",
                            "elementIsComplex": True,
                            "serializationOrder": 3,
                        },
                        {
                            "name": "tags",
                            "kind": "list",
                            "sectionId": "D00-TAG",
                            "elementType": "String",
                            "elementIsComplex": False,
                            "serializationOrder": 4,
                        },
                        {
                            "name": "priority",
                            "kind": "enum",
                            "sectionId": "D00-PRI",
                            "enumType": "Priority",
                            "enumValues": ["low", "high"],
                            "serializationOrder": 5,
                        },
                        {
                            "name": "count",
                            "kind": "scalar",
                            "type": "int",
                            "serializationOrder": 6,
                        },
                        {
                            # Class-level-only @SectionId: the field carries no
                            # id, so its key resolves to the target class's id
                            # (`CTRL control:`) — the DR1 §2.2 fallback.
                            "name": "control",
                            "kind": "complex",
                            "type": "Control",
                            "serializationOrder": 7,
                        },
                    ],
                },
                "Control": {
                    "name": "Control",
                    "sectionId": "CTRL",
                    "fields": [
                        {"name": "summary", "kind": "content", "sectionId": "CTRL-SUM"},
                        {"name": "owner", "kind": "content"},
                    ],
                },
                "Scope": {
                    "name": "Scope",
                    "fields": [
                        {"name": "inScope", "kind": "content", "sectionId": "D00-INS"},
                        {"name": "outOfScope", "kind": "content"},
                    ],
                },
                "Requirement": {
                    "name": "Requirement",
                    "fields": [
                        {"name": "text", "kind": "content"},
                        {
                            "name": "notes",
                            "kind": "list",
                            "elementType": "String",
                            "elementIsComplex": False,
                        },
                    ],
                },
            },
        }
    )


_TREE = build_som_meta_tree(_model())


def _enc(d: SpecDocument, stamp=None) -> str:
    return yaml_encode(d, _TREE, model_version=stamp)


def _dec(yaml: str):
    return yaml_decode(yaml, _TREE)


def _round_trip(d: SpecDocument) -> SpecDocument:
    return _dec(_enc(d)).document


def _populated() -> SpecDocument:
    """A populated document touching every store and the §2.4 edge cases."""
    doc = SpecDocument()
    doc.set_content("D00", "Preamble body text.")
    doc.set_content("D00/D00-OVR", "line one\nline two\nline three")
    doc.set_content("D00/D00-SCO/D00-INS", "  indented first line\n    deeper")
    doc.set_content("D00/D00-SCO/outOfScope", "ends with newline\n")
    doc.set_content("D00/D00-PRI", "high")
    doc.set_content("D00/count", "3")
    doc.set_form_field("D00/D00-HDR", "author", "Ada Lovelace")
    doc.set_form_field("D00/D00-HDR", "reviewer", "Grace Hopper")
    doc.set_form_field("D00/D00-HDR", "revision", "7")
    a = doc.add_list_item("D00/D00-REQ", section_id="REQ-AB1")
    doc.set_content(f"{a}/text", "value: with: colons # and hash")
    n1 = doc.add_list_item(f"{a}/notes")
    doc.set_content(n1, "a nested scalar note")
    b = doc.add_list_item("D00/D00-REQ")  # anonymous item
    doc.set_content(f"{b}/text", "second requirement")
    t1 = doc.add_list_item("D00/D00-TAG")
    doc.set_content(t1, "alpha")
    return doc


def test_encode() -> None:
    # writes the v2 header, version and hierarchical structure
    yaml = _enc(_populated(), stamp="1.0")
    _check(
        "encode.header",
        yaml.startswith(
            "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n"
        ),
        yaml.split("\n")[0],
    )
    _check("encode.version", "version: 2\n" in yaml)
    _check("encode.stamp", 'modelVersion: "1.0"\n' in yaml)
    _check("encode.rootKey", "\ndocument:\n  D00 Demo:\n" in yaml)
    _check(
        "encode.nesting",
        "\n    D00-SCO scope:\n      D00-INS inScope:" in yaml,
    )
    _check(
        "encode.rootContent",
        "\n    content: |2-\n      Preamble body text.\n" in yaml,
    )
    _check(
        "encode.storedItemId",
        "\n    D00-REQ requirements:\n      REQ-AB1:\n" in yaml,
    )
    _check("encode.anonItem", "\n      requirements-2:\n" in yaml)
    _check("encode.noFlatPaths", '"D00/' not in yaml)

    # sibling order follows @SerializationOrder, sparse emission
    doc = SpecDocument()
    doc.set_content("D00/D00-PRI", "low")  # order 5
    doc.set_content("D00/D00-OVR", "first")  # order 0
    sparse = _enc(doc)
    _check(
        "encode.order",
        sparse.index("D00-OVR overview:") < sparse.index("D00-PRI priority:"),
    )
    _check("encode.sparse", "D00-SCO" not in sparse)

    # non-text values are plain scalars (§2.5)
    yaml2 = _enc(_populated())
    _check("encode.plainEnum", "\n    D00-PRI priority: high\n" in yaml2)
    _check("encode.plainInt", "\n    count: 3\n" in yaml2)
    _check("encode.plainFormInt", "\n      revision: 7\n" in yaml2)

    # YAML 1.1-special values are quoted, not plain (§2.5, DRC6). `on`/`no`
    # are 1.1-only booleans and `1:30` is a 1.1 sexagesimal int: plain strings
    # under YAML 1.2 but bool/number under YAML 1.1 (PyYAML). They must emit as
    # block scalars so every runtime reads back the exact string; an ordinary
    # token still emits plainly.
    special = SpecDocument()
    for v in ("on", "no", "1:30", "plain"):
        special.set_content(special.add_list_item("D00/D00-TAG"), v)
    yaml3 = _enc(special)
    _check("encode.yaml11.on", "\n      tags-1: |2-\n        on\n" in yaml3)
    _check("encode.yaml11.no", "\n      tags-2: |2-\n        no\n" in yaml3)
    _check("encode.yaml11.sexagesimal", "\n      tags-3: |2-\n        1:30\n" in yaml3)
    _check("encode.yaml11.plain", "\n      tags-4: plain\n" in yaml3)
    out_special = _round_trip(special)
    _check(
        "encode.yaml11.roundTrip",
        [out_special.content(t) for t in out_special.list_items("D00/D00-TAG")]
        == ["on", "no", "1:30", "plain"],
    )

    # an empty document emits `document: {}`
    _check("encode.emptyDoc", "document: {}" in _enc(SpecDocument()))

    # the model-version stamp is omitted when absent
    _check("encode.noStamp", "modelVersion:" not in _enc(SpecDocument()))

    # values the tree cannot place are a structured error
    ghost = SpecDocument()
    ghost.set_content("D00/ghost", "x")
    _check("encode.leftoverError", _throws_format(lambda: _enc(ghost)))

    # an unknown form field is a structured error
    bogus = SpecDocument()
    bogus.set_form_field("D00/D00-HDR", "bogus", "v")
    _check("encode.unknownFormField", _throws_format(lambda: _enc(bogus)))


def test_round_trip() -> None:
    # every value survives verbatim
    out = _round_trip(_populated())
    _check("rt.root", out.content("D00") == "Preamble body text.")
    _check(
        "rt.overview",
        out.content("D00/D00-OVR") == "line one\nline two\nline three",
    )
    _check(
        "rt.inScope",
        out.content("D00/D00-SCO/D00-INS")
        == "  indented first line\n    deeper",
    )
    _check(
        "rt.outOfScope",
        out.content("D00/D00-SCO/outOfScope") == "ends with newline\n",
    )
    _check("rt.priority", out.content("D00/D00-PRI") == "high")
    _check("rt.count", out.content("D00/count") == "3")
    _check(
        "rt.author", out.form_field("D00/D00-HDR", "author") == "Ada Lovelace"
    )
    _check(
        "rt.reviewer",
        out.form_field("D00/D00-HDR", "reviewer") == "Grace Hopper",
    )
    _check("rt.revision", out.form_field("D00/D00-HDR", "revision") == "7")
    _check("rt.reqCount", out.list_item_count("D00/D00-REQ") == 2)
    items = out.list_items("D00/D00-REQ")
    _check("rt.item0.id", out.item_section_id(items[0]) == "REQ-AB1")
    _check("rt.item1.id", out.item_section_id(items[1]) is None)
    _check(
        "rt.item0.text",
        out.content(f"{items[0]}/text") == "value: with: colons # and hash",
    )
    _check(
        "rt.item1.text",
        out.content(f"{items[1]}/text") == "second requirement",
    )
    notes = out.list_items(f"{items[0]}/notes")
    _check(
        "rt.notes",
        len(notes) == 1 and out.content(notes[0]) == "a nested scalar note",
    )
    tags = out.list_items("D00/D00-TAG")
    _check("rt.tags", len(tags) == 1 and out.content(tags[0]) == "alpha")

    # encode is byte-stable across decode → re-encode
    yaml1 = _enc(_populated(), stamp="1.2")
    yaml2 = yaml_encode(_dec(yaml1).document, _TREE, model_version="1.2")
    _check("rt.byteStable", yaml2 == yaml1)

    # the model-version stamp lands on the decoded document
    decoded = _dec(_enc(_populated(), stamp="2.5"))
    _check("rt.stamp.contents", decoded.model_version == "2.5")
    _check("rt.stamp.document", decoded.document.model_version == "2.5")

    # markdown edge cases survive
    cases = [
        "\nleading blank line",
        "trailing blank line kept as one\n\nend",
        "two trailing newlines\n\n",  # block cannot represent → JSON fallback
        "trailing space on a line \nnext",
        "\ttab\tpreserved",
        "- looks: like\n  yaml: [a, b]\n# comment-ish",
        "\"double\" and 'single' quotes",
        "ends with newline\n",
        "   only-indentation-sensitive\n      nested deeper\n   back",
    ]
    for i, case in enumerate(cases):
        doc = SpecDocument()
        doc.set_content("D00/D00-OVR", case)
        got = _round_trip(doc).content("D00/D00-OVR")
        _check(f"rt.edge[{i}]", got == case, f"got {got!r} want {case!r}")

    # runs of 2+ empty lines collapse to one on write (§2.4.3)
    doc = SpecDocument()
    doc.set_content("D00/D00-OVR", "a\n\n\n\nb\n\n\nc")
    _check(
        "rt.emptyLineDedup",
        _round_trip(doc).content("D00/D00-OVR") == "a\n\nb\n\nc",
    )

    # an empty complex list item round-trips as `{}`
    empty_item = SpecDocument()
    empty_item.add_list_item("D00/D00-REQ")
    yaml3 = _enc(empty_item)
    _check("rt.emptyItem.enc", "requirements-1: {}" in yaml3, yaml3)
    _check(
        "rt.emptyItem.count",
        _round_trip(empty_item).list_item_count("D00/D00-REQ") == 1,
    )


def test_strict_decode() -> None:
    # version 1 files are rejected with a clear error
    _check(
        "decode.v1Rejected",
        _throws_format(
            lambda: _dec("version: 1\ndocument: {}\n"), "version 1"
        ),
    )

    # a missing version is rejected
    _check(
        "decode.missingVersion",
        _throws_format(lambda: _dec("document: {}\n")),
    )
    _check("decode.emptyText", _throws_format(lambda: _dec("")))

    # an unmatched key is a structured load error, not a silent skip
    bad = "version: 2\ndocument:\n  D00 Demo:\n    nonsense: |-\n      x\n"
    _check(
        "decode.unmatchedKey", _throws_format(lambda: _dec(bad), "nonsense")
    )

    # a wrong root key is a structured load error
    _check(
        "decode.wrongRoot",
        _throws_format(
            lambda: _dec("version: 2\ndocument:\n  WRONG Other: {}\n")
        ),
    )

    # an unknown form field on read is a structured load error
    bad_form = (
        "version: 2\ndocument:\n  D00 Demo:\n"
        "    D00-HDR header:\n      bogus: |-\n        v\n"
    )
    _check("decode.unknownFormField", _throws_format(lambda: _dec(bad_form)))

    # a missing/empty document pass decodes as an empty document
    _check("decode.noDocKey", _dec("version: 2\n").document.is_empty)
    _check(
        "decode.emptyDoc",
        _dec("version: 2\ndocument: {}\n").document.is_empty,
    )

    # the raw review pass is passed through untouched
    fixture = (
        "version: 2\n"
        "document: {}\n"
        "review:\n"
        '  "D00/a":\n'
        "    scope: global\n"
    )
    c = _dec(fixture)
    _check("decode.review", "D00/a" in {str(k) for k in c.review})


def test_class_level_only_key() -> None:
    # A section whose id is class-level renders the class id as its key
    # (DR1 §2.2 field-id-else-class-id). The `control` field carries no id;
    # its target class `Control` carries `CTRL`, so the key is `CTRL control:`.
    # The leaves keep their own content keys: `CTRL-SUM summary:` (field id)
    # and bare `owner:` (id-less content).
    doc = SpecDocument()
    doc.set_content("D00/control/CTRL-SUM", "controlled summary")
    doc.set_content("D00/control/owner", "the owner")
    yaml = _enc(doc)
    _check("clskey.section", "\n    CTRL control:\n" in yaml, yaml)
    _check("clskey.leafId", "\n      CTRL-SUM summary:" in yaml, yaml)
    _check("clskey.leafBare", "\n      owner:" in yaml, yaml)
    out = _round_trip(doc)
    _check("clskey.rt.summary", out.content("D00/control/CTRL-SUM") == "controlled summary")
    _check("clskey.rt.owner", out.content("D00/control/owner") == "the owner")


def test_code_spec_round_trip() -> None:
    # csmc8 (§9.2): a stored codeSpec survives the yaml round-trip.
    doc = _populated()
    doc.set_code_spec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository")
    yaml = _enc(doc)
    _check("codeSpec.yaml.emitted", "codeSpec:" in yaml, yaml)
    out = _round_trip(doc)
    _check(
        "codeSpec.yaml.restored",
        out.code_spec("D00/D00-OVR")
        == "CsOrder,CsOrder.total,CsOrderRepository",
        str(out.code_spec("D00/D00-OVR")),
    )
    # Sibling without codeSpec keeps no codeSpec entry.
    _check(
        "codeSpec.yaml.sibling",
        out.code_spec("D00/D00-PRI") is None,
        str(out.code_spec("D00/D00-PRI")),
    )


def test_code_spec_byte_stable() -> None:
    # csmc8 (§9.2): encode is byte-stable with codeSpec across
    # decode → re-encode.
    doc = _populated()
    doc.set_code_spec("D00/D00-OVR", "CsOrder,CsOrder.total")
    yaml1 = _enc(doc, stamp="1.2")
    yaml2 = yaml_encode(_dec(yaml1).document, _TREE, model_version="1.2")
    _check("codeSpec.yaml.byteStable", yaml2 == yaml1)


def main() -> int:
    test_encode()
    test_round_trip()
    test_strict_decode()
    test_class_level_only_key()
    test_code_spec_round_trip()
    test_code_spec_byte_stable()

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
