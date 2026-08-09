#!/usr/bin/env python3
"""Shared-corpus conformance runner for the Python generic runtime.

Loads the language-agnostic conformance corpus produced from the Dart reference
(``tom_som_conformance/corpus``) and asserts the Python port reproduces every
golden byte-for-byte and matches every behavioural case:

  * model meta-data loads (root + class structure);
  * the generation stamp decodes and reaches the shared staleness verdict;
  * ``state.json`` loads and re-serialises identically;
  * YAML encode == ``expected.docspecs.yaml`` (byte-for-byte);
  * YAML decode → memory → encode is byte-stable + preserves the stamp;
  * Markdown export == ``expected.md`` (byte-for-byte);
  * Markdown parse → memory → export is clean + byte-stable;
  * reflection resolution cases;
  * validation cases;
  * the imperative operations script;
  * the YRD7 generic editor script (typed values, enum domains, structure);
  * the SOM §14 DocSpecs tier (schema load + one violation case per rule);
  * the SOM §9 portable text-pattern subset (match spans + compile rejections);
  * the spec_query surface (queries, cursor count, the flat node projection,
    and a scripted cursor session that mutates the document mid-iteration);
  * constrained node creation (the stateless gate probes and a mutation
    script).

Run with: ``python3 tests/conformance_runner.py``. Exit code 0 == all green.
"""

from __future__ import annotations

import datetime as _dt
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
    DEFAULT_MAX_SNAPSHOT_AGE,
    DocSpecsSchema,
    DocSpecsValidator,
    DocSpecsViolationRule,
    SomPatternError,
    SomTextPattern,
    SpecCreationCode,
    SpecCreationError,
    SpecDocument,
    SpecDocumentMarkdown,
    SpecEditor,
    SpecModel,
    SpecNodeCreator,
    SpecNodeKind,
    SpecQuery,
    SpecQueryEngine,
    SpecReflection,
    SpecSectionIdCollision,
    SpecSerializationOrder,
    SpecStateFilter,
    build_som_meta_tree,
    check_add_node,
    encode_two_letter_date,
    generate_list_item_section_id,
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


def _build_document() -> SpecDocument:
    """The populated fixture the SOM §9 tables were generated from — a port of
    the Dart harness's ``_buildDocument()``.

    Built through the public mutation API rather than loaded from
    ``state.json``, because the two agree as *stores* but not as *orders*: a
    reloaded document iterates each form's fields in the file's sorted key
    order, whereas the built one keeps the author's insertion order — and both
    ``SpecNodeProjection.searchable_strings`` and the snippet a text query
    reports are order-sensitive. ``test_build_document_matches_state`` pins the
    two together so this transcription cannot drift from the corpus.
    """
    d = SpecDocument()
    d.set_content("DEMO/TTL", "Hello")
    d.set_content("DEMO/SUM", "Line one\nLine two\n\nLine four")
    d.set_content("DEMO/PRI", "high")
    d.set_content("DEMO/CNT", "3")
    d.set_form_field("DEMO/DET", "owner", "Bob")
    d.set_form_field("DEMO/DET", "contact", "bob@example.com")
    # YRD7: typed form-field values in their canonical plain-text store form.
    d.set_form_field("DEMO/DET", "estimate", "8")
    d.set_form_field("DEMO/DET", "weight", "2.5")
    d.set_form_field("DEMO/DET", "active", "true")
    d.set_form_field("DEMO/DET", "priority", "high")
    i1 = d.add_list_item("DEMO/items")
    d.set_content(f"{i1}/label", "First")
    d.set_content(f"{i1}/STS", "open")
    i2 = d.add_list_item("DEMO/items")
    d.set_content(f"{i2}/label", "Second line A\nwith ```triple``` ticks")
    d.set_content(f"{i2}/STS", "done")
    # A genuine `*-LST` list (id `REF-LST`, pattern `REF-xxx`).
    for ref in ("spec §1.2", "ADR7"):
        r = d.add_list_item("DEMO/REF-LST")
        d.set_content(r, ref)
    # YRD3 fixtures: stored headlines + a stored (pattern-shaped, non-numeric)
    # item section id.
    d.set_headline("DEMO/SUM", "Executive Summary")
    d.set_headline("DEMO/DET", "Details & Contacts")
    d.set_headline("DEMO/items", "Work Items")
    d.set_item_section_id("DEMO/REF-LST-1", "REF-SPEC")
    d.set_headline("DEMO/REF-LST-1", "Reference to the Spec")
    # Card 1 gets a stored item section id and a stored headline; card 2 keeps
    # both defaults. The ordinary `note` field lands in the form store.
    c1 = d.add_list_item("DEMO/CARD-LST")
    d.set_item_section_id(c1, "CARD-ALPHA")
    d.set_headline(c1, "Alpha Card")
    d.set_form_field(f"{c1}/content", "note", "first card")
    c2 = d.add_list_item("DEMO/CARD-LST")
    d.set_form_field(f"{c2}/content", "note", "second card")
    d.set_content("DEMO/META/OWNR", "alice")
    # Scalar list exercising the YAML 1.1-special quoting rule (SOM §12.5).
    for tag in ("on", "no", "1:30", "plain"):
        t = d.add_list_item("DEMO/META/tags")
        d.set_content(t, tag)
    # A class-level-only section (`Control`, id `CTRL`).
    d.set_content("DEMO/control/CTRL-SUM", "Controlled summary")
    d.set_content("DEMO/control/owner", "ctrl-owner")
    return d


def test_build_document_matches_state() -> None:
    """The locally-built fixture is the same document ``state.json`` records.

    Without this the SOM §9 tables would be replayed against a transcription
    nothing checks: a typo in :func:`_build_document` would silently move every
    expectation rather than fail.
    """
    built = _build_document().to_json()
    canonical = _read_json("state.json")
    _check("buildDocument.matchesState", built == canonical,
           _json_mismatch(built, canonical))


def test_model_meta(model: SpecModel) -> None:
    root = model.roots[0]
    _check("model.root.sectionId", root.section_id == "DEMO", str(root.section_id))
    _check("model.root.type", root.type == "Demo", root.type)
    _check("model.classCount", len(model.classes) == 11, str(len(model.classes)))
    demo = model.class_named("Demo")
    _check("model.Demo.found", demo is not None)
    if demo is not None:
        names = [f.name for f in demo.fields]
        _check(
            "model.Demo.fields",
            names == ["title", "summary", "priority", "count", "details", "items", "refs", "cards", "meta", "control", "registry"],
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


def test_yaml_encode(tree) -> None:
    doc = _document_from_state(_read_json("state.json"))
    expected = _read("expected.docspecs.yaml")
    actual = yaml_encode(doc, tree, model_version=_MODEL_VERSION)
    _check("yaml.encode", actual == expected, _byte_diff("yaml.encode", actual, expected))


def test_yaml_decode_round_trip(tree) -> None:
    expected = _read("expected.docspecs.yaml")
    contents = yaml_decode(expected, tree)
    _check("yaml.decode.stamp", contents.model_version == _MODEL_VERSION,
           str(contents.model_version))
    _check("yaml.decode.memory",
           contents.document.to_json() == _read_json("state.json"),
           _json_mismatch(contents.document.to_json(), _read_json("state.json")))
    actual = yaml_encode(contents.document, tree,
                         model_version=contents.model_version or _MODEL_VERSION)
    _check("yaml.decode.reencode", actual == expected,
           _byte_diff("yaml.decode.reencode", actual, expected))


def test_markdown_export(model: SpecModel) -> None:
    doc = _document_from_state(_read_json("state.json"))
    expected = _read("expected.md")
    actual = SpecDocumentMarkdown(model, doc).export_root(model.roots[0])
    _check("md.export", actual == expected,
           _byte_diff("md.export", actual, expected))


def test_markdown_round_trip(model: SpecModel) -> None:
    golden = _read("expected.md")
    doc = _document_from_state(_read_json("state.json"))
    parsed = SpecDocumentMarkdown(model, doc).parse(golden)
    _check("md.parse.clean", not parsed.rejections,
           "; ".join(str(r) for r in parsed.rejections))
    re_doc = SpecDocument()
    re_doc.load_json({
        "content": parsed.content,
        "forms": parsed.forms,
        "lists": parsed.lists,
        "headlines": parsed.headlines,
    })
    _check("md.parse.storedId",
           re_doc.item_section_id("DEMO/REF-LST-1") == "REF-SPEC",
           str(re_doc.item_section_id("DEMO/REF-LST-1")))
    _check("md.parse.headline",
           re_doc.headline("DEMO/REF-LST-1") == "Reference to the Spec",
           str(re_doc.headline("DEMO/REF-LST-1")))
    actual = SpecDocumentMarkdown(model, re_doc).export_root(model.roots[0])
    _check("md.parse.reexport", actual == golden,
           _byte_diff("md.parse.reexport", actual, golden))


def test_markdown_lands_in_shared_memory(model: SpecModel) -> None:
    """Markdown/YAML convergence: parsing ``expected.md`` and applying it must
    reproduce ``state.json`` (the YAML-route memory) exactly, proving both
    formats converge on one in-memory document (SOM §8)."""
    golden = _read("expected.md")
    canonical = _read_json("state.json")
    doc = _document_from_state(canonical)
    parsed = SpecDocumentMarkdown(model, doc).parse(golden)
    _check("md.land.clean", not parsed.rejections,
           "; ".join(str(r) for r in parsed.rejections))
    landed = SpecDocument()
    landed.load_json({
        "content": parsed.content,
        "forms": parsed.forms,
        "lists": parsed.lists,
        "headlines": parsed.headlines,
    })
    _check("md.land.memory", landed.to_json() == canonical,
           _json_mismatch(landed.to_json(), canonical))


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


def _expect_raises(name: str, fn) -> None:
    try:
        fn()
    except (ValueError, TypeError):
        _check(name, True)
        return
    _check(name, False, "did not raise")


def test_editor(model: SpecModel) -> None:
    """YRD7: the generic, meta-validated modification API (SpecEditor) — typed
    value/form-field round-trips through the shared boundary helpers, enum
    domain validation, and structural create/clear ops.

    Executed against the corpus model, so every language's generic editor
    replays the identical script.
    """
    doc = SpecDocument()
    ed = SpecEditor.for_model(doc, model)
    for n, s in enumerate(_read_json("editor_cases.json")):
        kind = s["op"]
        if kind == "setValue":
            ed.set_value(s["path"], s["value"])
        elif kind == "value":
            _check(f"editor[{n}].value {s['path']}",
                   ed.value(s["path"]) == s["expect"], str(ed.value(s["path"])))
        elif kind == "setValueThrows":
            _expect_raises(f"editor[{n}].setValueThrows {s['path']}",
                           lambda s=s: ed.set_value(s["path"], s["value"]))
        elif kind == "setContent":  # raw store write (bypasses the boundary)
            doc.set_content(s["path"], s["value"])
        elif kind == "rawContent":
            _check(f"editor[{n}].rawContent {s['path']}",
                   doc.content(s["path"]) == s["expect"],
                   str(doc.content(s["path"])))
        elif kind == "setFormValue":
            ed.set_form_value(s["path"], s["field"], s["value"])
        elif kind == "formValue":
            got = ed.form_value(s["path"], s["field"])
            _check(f"editor[{n}].formValue {s['path']}#{s['field']}",
                   got == s["expect"], str(got))
        elif kind == "setFormValueThrows":
            _expect_raises(
                f"editor[{n}].setFormValueThrows {s['path']}#{s['field']}",
                lambda s=s: ed.set_form_value(s["path"], s["field"], s["value"]))
        elif kind == "rawFormField":
            got = doc.form_field(s["path"], s["field"])
            _check(f"editor[{n}].rawFormField {s['path']}#{s['field']}",
                   got == s["expect"], str(got))
        elif kind == "formFieldNames":
            got = [f.name for f in ed.form_fields(s["path"])]
            _check(f"editor[{n}].formFieldNames {s['path']}",
                   got == s["expect"], str(got))
        elif kind == "formFieldNamesThrows":
            _expect_raises(f"editor[{n}].formFieldNamesThrows {s['path']}",
                           lambda s=s: ed.form_fields(s["path"]))
        elif kind == "setHeadline":
            ed.set_headline(s["path"], s["value"])
        elif kind == "headline":
            _check(f"editor[{n}].headline {s['path']}",
                   ed.headline(s["path"]) == s.get("expect"),
                   str(ed.headline(s["path"])))
        elif kind == "headlineThrows":
            _expect_raises(f"editor[{n}].headlineThrows {s['path']}",
                           lambda s=s: ed.headline(s["path"]))
        elif kind == "itemSectionId":
            _check(f"editor[{n}].itemSectionId {s['itemPath']}",
                   doc.item_section_id(s["itemPath"]) == s["expect"],
                   str(doc.item_section_id(s["itemPath"])))
        elif kind == "addListItem":
            p = ed.add_list_item(s["listPath"], month=s["month"], day=s["day"])
            _check(f"editor[{n}].addListItem {s['listPath']}",
                   p == s["expectPath"], p)
            if "expectId" in s:
                _check(f"editor[{n}].addListItem id {s['listPath']}",
                       doc.item_section_id(p) == s["expectId"],
                       str(doc.item_section_id(p)))
        elif kind == "addListItemThrows":
            _expect_raises(
                f"editor[{n}].addListItemThrows {s['listPath']}",
                lambda s=s: ed.add_list_item(
                    s["listPath"], month=s["month"], day=s["day"]))
        elif kind == "removeListItem":
            _check(f"editor[{n}].removeListItem {s['itemPath']}",
                   ed.remove_list_item(s["itemPath"]) == s["expect"])
        elif kind == "clearSection":
            ed.clear_section(s["path"])
        elif kind == "clearSectionThrows":
            _expect_raises(f"editor[{n}].clearSectionThrows {s['path']}",
                           lambda s=s: ed.clear_section(s["path"]))
        elif kind == "hasValuesUnder":
            _check(f"editor[{n}].hasValuesUnder {s['prefix']}",
                   doc.has_values_under(s["prefix"]) == s["expect"])
        else:  # pragma: no cover
            _check(f"editor[{n}].unknown", False, kind)


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
        elif kind == "setHeadline":
            doc.set_headline(op["path"], op["value"])
        elif kind == "headline":
            _check(f"op[{n}].headline",
                   doc.headline(op["path"]) == op.get("expect"),
                   str(doc.headline(op["path"])))
        else:  # pragma: no cover
            _check(f"op[{n}].unknown", False, kind)


def test_section_id() -> None:
    """AA1 criteria 3–6: two-letter-date encoding, list-item id generation
    (within-day numbering), same-day reuse on last-item deletion, and unique-id
    enforcement on override — replayed from the shared corpus so every port
    reproduces the identical id semantics."""
    cases = _read_json("section_id_cases.json")

    # Criterion 4: the two-letter day code.
    for c in cases["twoLetterDate"]:
        got = encode_two_letter_date(c["month"], c["day"])
        _check(f"sectionId.twoLetterDate[{c['month']}/{c['day']}]",
               got == c["expect"], f"{got} != {c['expect']}")

    # Criteria 3 & 6: generated id = prefix + day + (max-for-day + 1).
    for c in cases["generate"]:
        got = generate_list_item_section_id(
            c["pattern"], c["month"], c["day"], list(c["existing"])
        )
        _check(f"sectionId.generate[{c['pattern']}]",
               got == c["expect"], f"{got} != {c['expect']}")

    # Criteria 5 & 6 at the document level: override keeps ids unique, deleting
    # the last same-day item frees its number for reuse, deleting a middle one
    # never renumbers the rest.
    d = SpecDocument()
    for i, s in enumerate(cases["documentOps"]):
        op = s["op"]
        if op == "addGen":
            gen_id = generate_list_item_section_id(
                s["pattern"], s["month"], s["day"],
                d.list_item_section_ids(s["listPath"]),
            )
            _check(f"sectionId.op[{i}].addGen.id",
                   gen_id == s["expectId"], f"{gen_id} != {s['expectId']}")
            path = d.add_list_item(s["listPath"], section_id=gen_id)
            _check(f"sectionId.op[{i}].addGen.path",
                   path == s["expectPath"], f"{path} != {s['expectPath']}")
        elif op == "sectionIds":
            got = d.list_item_section_ids(s["listPath"])
            _check(f"sectionId.op[{i}].sectionIds",
                   got == s["expect"], f"{got} != {s['expect']}")
        elif op == "removeListItem":
            got = d.remove_list_item(s["itemPath"])
            _check(f"sectionId.op[{i}].removeListItem", got == s["expect"])
        elif op == "override":
            d.set_item_section_id(s["itemPath"], s["id"])
        elif op == "overrideThrows":
            _check(f"sectionId.op[{i}].overrideThrows",
                   _raises(lambda: d.set_item_section_id(s["itemPath"], s["id"])))
        elif op == "addExplicitThrows":
            _check(f"sectionId.op[{i}].addExplicitThrows",
                   _raises(lambda: d.add_list_item(s["listPath"], section_id=s["id"])))
        else:  # pragma: no cover
            _check(f"sectionId.op[{i}].unknown", False, op)


def _raises(fn) -> bool:
    """Whether *fn* raises :class:`SpecSectionIdCollision` (the criterion-5
    collision guard)."""
    try:
        fn()
        return False
    except SpecSectionIdCollision:
        return True


def test_serialization_order() -> None:
    """AA1 criterion 7: members serialize in ``@SerializationOrder``, not
    alphabetical."""
    c = _read_json("serialization_order_cases.json")
    order_model = SpecModel.from_json(c["model"])
    order = SpecSerializationOrder(order_model)
    got_paths = order.order_paths(list(c["contentPaths"]))
    _check("serialOrder.orderPaths",
           got_paths == c["expectedOrder"], f"{got_paths} != {c['expectedOrder']}")
    got_fields = order.order_form_fields(c["formPath"], list(c["formFields"]))
    _check("serialOrder.orderFormFields",
           got_fields == c["expectedFormOrder"],
           f"{got_fields} != {c['expectedFormOrder']}")


def test_stamp(model: SpecModel) -> None:
    """The generation stamp: the five keys the exporter writes, and the
    staleness verdict every runtime must reach from the same input."""
    # The shared model fixture carries the stamp, minus `containerRoot` (it is a
    # single synthetic document with no container class).
    _check(
        "stamp.meta.generatedAt",
        model.generated_at is not None
        and int(model.generated_at.timestamp()) == 1784534400,
        str(model.generated_at),
    )
    _check("stamp.meta.metaSchemaVersion", model.meta_schema_version == 1)
    _check("stamp.meta.classCount", model.class_count == len(model.classes))
    _check("stamp.meta.rootCount", model.root_count == len(model.roots))
    _check("stamp.meta.containerRoot", model.container_root is None)

    table = _read_json("stamp_cases.json")
    _check(
        "stamp.defaultMaxAgeDays",
        table["defaultMaxAgeDays"] == DEFAULT_MAX_SNAPSHOT_AGE.days,
    )
    for case in table["cases"]:
        name = case["name"]
        loaded = SpecModel.from_json(case["model"])
        want = case["expect"]
        got_epoch = (
            None
            if loaded.generated_at is None
            else int(loaded.generated_at.timestamp())
        )
        _check(
            f"stamp[{name}].generatedAt",
            got_epoch == want["generatedAtEpochSeconds"],
            f"{got_epoch} != {want['generatedAtEpochSeconds']}",
        )
        for key, got in (
            ("metaSchemaVersion", loaded.meta_schema_version),
            ("classCount", loaded.class_count),
            ("rootCount", loaded.root_count),
            ("containerRoot", loaded.container_root),
        ):
            _check(f"stamp[{name}].{key}", got == want[key], f"{got} != {want[key]}")
        _check(
            f"stamp[{name}].actualClassCount",
            len(loaded.classes) == want["actualClassCount"],
        )
        _check(
            f"stamp[{name}].actualRootCount",
            len(loaded.roots) == want["actualRootCount"],
        )

        wc = case["check"]
        check = loaded.check_stamp(
            max_age=_dt.timedelta(days=wc["maxAgeDays"]),
            now=_dt.datetime.fromtimestamp(wc["nowEpochSeconds"], _dt.timezone.utc),
        )
        age_seconds = None if check.age is None else int(check.age.total_seconds())
        _check(
            f"stamp[{name}].ageSeconds",
            age_seconds == wc["ageSeconds"],
            f"{age_seconds} != {wc['ageSeconds']}",
        )
        for key, got in (
            ("isAged", check.is_aged),
            ("classCountDisagrees", check.class_count_disagrees),
            ("rootCountDisagrees", check.root_count_disagrees),
            ("countsDisagree", check.counts_disagree),
            ("isStale", check.is_stale),
        ):
            _check(f"stamp[{name}].{key}", got == wc[key], f"{got} != {wc[key]}")
        _check(
            f"stamp[{name}].warnings",
            check.warnings == wc["warnings"],
            f"{check.warnings} != {wc['warnings']}",
        )


def test_docspecs() -> None:
    """The SOM §14 DocSpecs tier: one shared schema, one case per rule.

    The corpus carries the rule/sectionId/line triples the Dart reference
    produces; matching them is what proves this port implements each rule at
    all, rather than merely declaring its name.
    """
    schema = DocSpecsSchema.from_yaml_text(_read("docspecs_schema.yaml"))
    _check("docspecs.schemaWarnings", schema.warnings == [], str(schema.warnings))
    _check("docspecs.rootSectionId", schema.root_section_id == "D00")
    validator = DocSpecsValidator(schema)
    covered: set[str] = set()
    for case in _read_json("docspecs_cases.json"):
        name = case["name"]
        got = [
            (v.rule.value, v.section_id, v.line)
            for v in validator.validate_markdown(case["markdown"])
        ]
        want = [(v["rule"], v["sectionId"], v["line"]) for v in case["violations"]]
        _check(f"docspecs[{name}]", got == want, f"{got} != {want}")
        covered.update(v["rule"] for v in case["violations"])
    uncovered = sorted(
        r.value for r in DocSpecsViolationRule if r.value not in covered
    )
    _check("docspecs.ruleCoverage", not uncovered, f"uncovered: {uncovered}")


# ---------------------------------------------------------------------------
# spec_text_pattern / spec_query / spec_node_creation (SOM §9)
# ---------------------------------------------------------------------------


def test_pattern() -> None:
    """The portable text-pattern subset: every committed span, and every
    committed compile rejection.

    ``regex: false`` means the pattern was built with the ``literal``
    constructor (every character taken verbatim); ``error: true`` means
    :meth:`SomTextPattern.compile` must raise :class:`SomPatternError` rather
    than quietly matching nothing.
    """
    cases = _read_json("pattern_cases.json")
    for n, c in enumerate(cases):
        source = c["pattern"]
        ci = c.get("caseInsensitive", False)
        if c.get("error") is True:
            _check(
                f"pattern[{n}].rejects {source!r}",
                _raises_pattern_error(source),
                "compiled without raising SomPatternError",
            )
            continue
        p = (
            SomTextPattern.compile(source, ci)
            if c["regex"]
            else SomTextPattern.literal(source, ci)
        )
        got = [[s.start, s.end] for s in p.all_matches(c["text"])]
        _check(f"pattern[{n}].spans {source!r}", got == c["spans"],
               f"{got} != {c['spans']} over {c['text']!r}")
        _check(f"pattern[{n}].hasMatch {source!r}",
               p.has_match(c["text"]) == bool(c["spans"]))

    # A table of matches alone would let a port accept everything; a table of
    # rejections alone would let one reject everything.
    _check("pattern.tableHasRejections",
           any(c.get("error") is True for c in cases))
    _check("pattern.tableHasMatches",
           any(c.get("error") is not True for c in cases))


def _raises_pattern_error(source: str) -> bool:
    try:
        SomTextPattern.compile(source)
        return False
    except SomPatternError:
        return True


def _query_from_json(j: dict) -> SpecQuery:
    """Rebuilds a :class:`SpecQuery` from its corpus wire form.

    Every port needs this same decode, so its shape *is* part of the contract:
    an absent key means "dimension unset", never a default that happens to
    match. Kept beside the replay rather than in the package because it belongs
    to the corpus format, not to the runtime API.
    """
    kinds = j.get("kinds")
    state = j.get("state")
    return SpecQuery(
        text=j.get("text"),
        regex=j.get("regex", False),
        case_insensitive=j.get("caseInsensitive", False),
        kinds=None if kinds is None else {SpecNodeKind(k) for k in kinds},
        class_name=j.get("className"),
        section_id_exact=j.get("sectionIdExact"),
        section_id_prefix=j.get("sectionIdPrefix"),
        path_glob=j.get("pathGlob"),
        maps_to=j.get("mapsTo"),
        detailed_in=j.get("detailedIn"),
        state=None if state is None else SpecStateFilter(state),
    )


def test_query(model: SpecModel) -> None:
    """Every committed query reproduces its match list *in order*, and the
    cursor's ``count`` agrees with that list.

    The two assertions are the same fact from opposite sides: a port that
    implements ``to_list`` by draining but ``count`` by returning the raw
    candidate count passes the first and fails the second.
    """
    engine = SpecQueryEngine(model=model, document=_build_document())
    for case in _read_json("query_cases.json"):
        name = case["name"]
        cursor = engine.query(_query_from_json(case["query"]))
        got = [
            {
                "path": m.path,
                "kind": m.kind.value,
                "classId": m.class_id,
                "headline": m.headline,
                "snippet": m.snippet,
                "spans": [[s.start, s.end] for s in m.match_spans],
            }
            for m in cursor.to_list()
        ]
        _check(f"query[{name}]", got == case["matches"],
               _json_mismatch(got, case["matches"]))

        counted = engine.query(_query_from_json(case["query"])).count
        _check(f"query[{name}].count", counted == len(case["matches"]),
               f"{counted} != {len(case['matches'])}")


def test_projection(model: SpecModel) -> None:
    """The flat tier-1 projection of the whole structural closure, in document
    order — the index source that must agree with the live query on what a node
    is and what text it carries."""
    engine = SpecQueryEngine(model=model, document=_build_document())
    got = [
        {
            "path": p.path,
            "kind": p.kind.value,
            "classId": p.class_id,
            "sectionId": p.section_id,
            "mapsTo": p.maps_to,
            "detailedIn": p.detailed_in,
            "headline": p.headline,
            "searchableStrings": p.searchable_strings,
            "hasValue": p.has_value,
        }
        for p in engine.project_nodes()
    ]
    want = _read_json("projection_cases.json")
    _check("projection.walk", got == want, _json_mismatch(got, want))


def test_cursor(model: SpecModel) -> None:
    """A scripted cursor session over a freshly built document.

    ``removeListItem`` mutates the document *while a cursor is open*: the
    candidate set was captured at ``open``, so reproducing the committed
    ``toList`` proves each step re-validates its path against the live document
    instead of trusting the snapshot.
    """
    d = _build_document()
    engine = SpecQueryEngine(model=model, document=d)
    cursor = None
    for n, s in enumerate(_read_json("cursor_cases.json")):
        op = s["op"]
        if op == "open":
            cursor = engine.query(_query_from_json(s["query"]))
        elif op == "count":
            _check(f"cursor[{n}].count", cursor.count == s["expect"],
                   f"{cursor.count} != {s['expect']}")
        elif op == "take":
            got = [m.path for m in cursor.take(s["n"])]
            _check(f"cursor[{n}].take {s['n']}", got == s["expect"],
                   f"{got} != {s['expect']}")
        elif op == "next":
            m = cursor.next()
            got = None if m is None else m.path
            _check(f"cursor[{n}].next", got == s["expect"],
                   f"{got} != {s['expect']}")
        elif op == "toList":
            got = [m.path for m in cursor.to_list()]
            _check(f"cursor[{n}].toList", got == s["expect"],
                   f"{got} != {s['expect']}")
        elif op == "removeListItem":
            d.remove_list_item(s["itemPath"])
        else:  # pragma: no cover
            _check(f"cursor[{n}].unknown", False, op)


def test_node_creation(model: SpecModel) -> None:
    """The stateless gate probes: each runs against a **freshly built**
    document, so they are order-independent.

    Only the rejection *code* is pinned, never the message: the code is the
    contract, the message is prose, and pinning prose across nine languages
    would make a reword a nine-package change.
    """
    cases = _read_json("node_creation_cases.json")
    covered: set[str] = set()
    for case in cases:
        name = case["name"]
        d = _build_document()
        err = check_add_node(
            model, d, case["parentPath"], case["childSegment"],
            item_id=case.get("itemId"),
        )
        _check(f"nodeCreation[{name}].accepted",
               (err is None) == case["accepted"],
               f"{err is None} != {case['accepted']}")
        if err is not None:
            covered.add(err.code.value)
            _check(f"nodeCreation[{name}].code",
                   err.code.value == case.get("code"),
                   f"{err.code.value} != {case.get('code')}")
            _check(f"nodeCreation[{name}].parentPath",
                   err.parent_path == case["parentPath"], err.parent_path)
            _check(f"nodeCreation[{name}].childSegment",
                   err.child_segment == case["childSegment"], err.child_segment)
    uncovered = sorted(c.value for c in SpecCreationCode if c.value not in covered)
    _check("nodeCreation.codeCoverage", not uncovered, f"uncovered: {uncovered}")


def test_node_creation_script(model: SpecModel) -> None:
    """The sequential script: one document, so each step sees what the previous
    produced (fresh sequence numbers, generated ids, the accumulated state)."""
    d = _build_document()
    creator = SpecNodeCreator(model, d)
    for n, s in enumerate(_read_json("node_creation_script.json")):
        op = s["op"]
        if op == "add":
            path = creator.add(
                s["parentPath"], s["childSegment"],
                item_id=s.get("itemId"), month=s["month"], day=s["day"],
            )
            _check(f"nodeScript[{n}].path", path == s["expectPath"],
                   f"{path} != {s['expectPath']}")
            got_id = d.item_section_id(path)
            _check(f"nodeScript[{n}].id", got_id == s["expectId"],
                   f"{got_id} != {s['expectId']}")
        elif op == "addThrows":
            code = _creation_error_code(
                creator, s["parentPath"], s["childSegment"], s.get("itemId"))
            _check(f"nodeScript[{n}].throws", code == s["expectCode"],
                   f"{code} != {s['expectCode']}")
        elif op == "finalState":
            _check(f"nodeScript[{n}].finalState", d.to_json() == s["expect"],
                   _json_mismatch(d.to_json(), s["expect"]))
        else:  # pragma: no cover
            _check(f"nodeScript[{n}].unknown", False, op)


def _creation_error_code(
    creator: SpecNodeCreator,
    parent_path: str,
    child_segment: str,
    item_id,
):
    """The code of the :class:`SpecCreationError` an illegal add raises, or
    ``None`` when it wrongly succeeded. The date is the script's fixed
    2026-03-04, matching the Dart reference."""
    try:
        creator.add(parent_path, child_segment, item_id=item_id, month=3, day=4)
        return None
    except SpecCreationError as e:
        return e.code.value


def main() -> int:
    if not os.path.isdir(_CORPUS):
        print(f"corpus not found at {_CORPUS}", file=sys.stderr)
        return 2
    model = _load_model()
    tree = build_som_meta_tree(model)
    test_model_meta(model)
    test_stamp(model)
    test_state_round_trip()
    test_yaml_encode(tree)
    test_yaml_decode_round_trip(tree)
    test_markdown_export(model)
    test_markdown_round_trip(model)
    test_markdown_lands_in_shared_memory(model)
    test_reflection(model)
    test_validation(model)
    test_operations()
    test_editor(model)
    test_section_id()
    test_serialization_order()
    test_docspecs()
    test_build_document_matches_state()
    test_pattern()
    test_query(model)
    test_projection(model)
    test_cursor(model)
    test_node_creation(model)
    test_node_creation_script(model)

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
