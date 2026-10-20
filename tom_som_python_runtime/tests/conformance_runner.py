#!/usr/bin/env python3
"""Shared-corpus conformance runner for the Python generic runtime.

Loads the language-agnostic conformance corpus produced from the Dart reference
(``tom_som_conformance/corpus``) and asserts the Python port reproduces every
golden byte-for-byte and matches every behavioural case:

  * model meta-data loads (root + class structure);
  * the generation stamp decodes and reaches the shared staleness verdict;
  * the SOM §4.2/§21 editability classification and its refusal messages;
  * ``state.json`` loads and re-serialises identically;
  * YAML encode == ``expected.docspecs.yaml`` (byte-for-byte);
  * YAML decode → memory → encode is byte-stable + preserves the stamp;
  * Markdown export == ``expected.md`` (byte-for-byte);
  * Markdown parse → memory → export is clean + byte-stable;
  * reflection resolution cases;
  * validation cases;
  * the imperative operations script;
  * the YRD7 generic editor script (typed values, enum domains, structure);
  * the SOM §14 DocSpecs tier (schema load + one violation case per rule),
    and findings bound to their document path (``docspecs_path_cases.json``);
  * the SOM §9 portable text-pattern subset (match spans + compile rejections);
  * the spec_query surface (queries, cursor count, the flat node projection,
    and a scripted cursor session that mutates the document mid-iteration);
  * the Phase-4 CodeSpecs extract generator (routing verdicts, the YAML +
    Markdown extract goldens, the verbatim-copy guard and the ``ROUTE-TOTAL``
    error cases);
  * the Phase-4 Stage-A gate (``CodeSpecsGate``, checks A1–A5);
  * constrained node creation (the stateless gate probes and a mutation
    script);
  * assembling one document from fragments (``assembly_cases.json``);
  * moving a list item and re-keying the review pass
    (``list_move_cases.json``).

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
    CodeSpecsAreaCatalog,
    CodeSpecsExtract,
    CodeSpecsExtractError,
    CodeSpecsExtractSet,
    CodeSpecsExtractor,
    CodeSpecsGate,
    CodeSpecsGateEntry,
    CodeSpecsGateGap,
    CodeSpecsGateRecord,
    CodeSpecsGateVerdict,
    CodeSpecsRecordError,
    DocSpecsDocument,
    DocSpecsSchema,
    DocSpecsValidator,
    DocSpecsViolationRule,
    SomEditability,
    SomPatternError,
    SomTextPattern,
    SomVersionError,
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
    SpecMarkDecision,
    SpecQuestionDraft,
    SpecReviewAnnotationError,
    SpecReviewAnnotations,
    SpecAnswerRenderOptions,
    extract_answers,
    render_answers,
    SpecReflection,
    SpecSectionIdCollision,
    SpecSerializationOrder,
    SpecStateFilter,
    build_som_meta_tree,
    check_add_node,
    check_som_model_version,
    som_editability_for,
    encode_two_letter_date,
    generate_list_item_section_id,
    apply_inline_marks_text,
    mark_change_text,
    validate_document,
    validate_spec_document,
    rekey_review,
    stale_review_paths,
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
    ``state.json`` so that the store's own order is *wrong* in a detectable
    way. Form fields are emitted in model-declaration order (SOM §9,
    "Form-field order"), so the populate order below is deliberately neither
    that nor the file's sorted order: a port that iterated the store would pick
    a different snippet and fail ``projection_cases.json``, which is exactly
    what this fixture exists to catch. ``test_build_document_matches_state``
    pins the built document against the corpus store, so the transcription
    cannot drift.
    """
    d = SpecDocument()
    d.set_content("DEMO/TTL", "Hello")
    d.set_content("DEMO/SUM", "Line one\nLine two\n\nLine four")
    d.set_content("DEMO/PRI", "high")
    d.set_content("DEMO/CNT", "3")
    # Scrambled on purpose — see the docstring. Do not "tidy" into order.
    # YRD7: typed form-field values in their canonical plain-text store form.
    d.set_form_field("DEMO/DET", "priority", "high")
    d.set_form_field("DEMO/DET", "weight", "2.5")
    d.set_form_field("DEMO/DET", "owner", "Bob")
    d.set_form_field("DEMO/DET", "active", "true")
    d.set_form_field("DEMO/DET", "estimate", "8")
    # SOM §11.4 rule 8: rendered as an inline code span, so the `](` stays
    # literal instead of becoming a markdown link.
    d.set_form_field("DEMO/DET", "pattern", r"^[a-z0-9](-?[a-z0-9]){1,62}$")
    # A multi-line value ending in a markdown list (SOM §11.4 rule 2).
    d.set_form_field(
        "DEMO/DET",
        "contact",
        "bob@example.com\n- on call: weekdays\n- backup: alice@example.com",
    )
    # The form preamble (SOM §11.4 rule 7): free text in the form's own content
    # slot, beside its fields. Line 2 is label-shaped AND shadows the declared
    # `owner` field, so the rule-3 escape has to hold on emit.
    d.set_content(
        "DEMO/DET",
        "Captured during the November review.\n"
        "Owner: this line is prose, not the field.",
    )
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
    # An item of a pattern list stores its id even when it equals the
    # positional default (`REF-2`, `CARD-2` below): the Markdown heading
    # carries that id and import stores it (SOM §11.6), so the YAML and the
    # Markdown route can only land in the same memory if the fixture does too.
    # Positional items stay covered by the pattern-less `items` and `tags`.
    d.set_item_section_id("DEMO/REF-LST-2", "REF-2")
    # YRD3 fixtures: stored headlines + a stored (pattern-shaped, non-numeric)
    # item section id.
    d.set_headline("DEMO/SUM", "Executive Summary")
    d.set_headline("DEMO/DET", "Details & Contacts")
    d.set_headline("DEMO/items", "Work Items")
    d.set_item_section_id("DEMO/REF-LST-1", "REF-SPEC")
    d.set_headline("DEMO/REF-LST-1", "Reference to the Spec")
    # Card 1 gets a stored item section id and a stored headline; card 2
    # stores the default id `CARD-2` and keeps the derived item title. The
    # ordinary `note` field lands in the form store.
    c1 = d.add_list_item("DEMO/CARD-LST")
    d.set_item_section_id(c1, "CARD-ALPHA")
    d.set_headline(c1, "Alpha Card")
    d.set_form_field(f"{c1}/content", "note", "first card")
    c2 = d.add_list_item("DEMO/CARD-LST", section_id="CARD-2")
    d.set_form_field(f"{c2}/content", "note", "second card")
    d.set_content("DEMO/META/OWNR", "alice")
    # Scalar list exercising the YAML 1.1-special quoting rule (SOM §12.5).
    for tag in ("on", "no", "1:30", "plain"):
        t = d.add_list_item("DEMO/META/tags")
        d.set_content(t, tag)
    # A class-level-only section (`Control`, id `CTRL`).
    d.set_content("DEMO/control/CTRL-SUM", "Controlled summary")
    d.set_content("DEMO/control/owner", "ctrl-owner")
    # The `section`-kind member (`Notes`, class id `NOTE`, id-less field): a
    # section collapses into its target class exactly as a complex member does,
    # and keys on the target class's id when the field carries none.
    d.set_content("DEMO/notes/NOTE-BDY", "Section-kind body")
    d.set_content("DEMO/notes/remarks", "Wrapper-section text")
    # SOM §11.6 slot markers, §11.2 headline line breaks, §11.3 blank lines:
    # a two-line headline, a form preamble that is not the default target, a
    # narrative after a form field, a second content slot, a label-shaped
    # narrative line, two blank lines kept as written, and a second form whose
    # `Lead` label the first form shares.
    d.set_headline("DEMO/MIX", "Mixed\nslots")
    d.set_content("DEMO/MIX/content", "_Extrapolated._")
    d.set_form_field("DEMO/MIX/content", "lead", "Ada")
    d.set_form_field("DEMO/MIX/content", "risk", "low")
    d.set_content(
        "DEMO/MIX/narrative",
        "First narrative.\n\n\nAfter two blank lines.\nLead: label-shaped prose",
    )
    d.set_content("DEMO/MIX/tail", "Tail text.")
    d.set_form_field("DEMO/MIX/alt", "lead", "Bob")
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
    _check("model.classCount", len(model.classes) == 15, str(len(model.classes)))
    demo = model.class_named("Demo")
    _check("model.Demo.found", demo is not None)
    if demo is not None:
        names = [f.name for f in demo.fields]
        _check(
            "model.Demo.fields",
            names == ["title", "summary", "priority", "count", "ratio", "score", "details", "items", "refs", "cards", "meta", "control", "notes", "mixed", "registry"],
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


def _run_yaml_review_case(model: SpecModel, tree, case: dict):
    """Runs one ``yaml_review_cases.json`` case: ``roundTrip`` re-encodes the
    decoded file with its review pass; ``stale`` removes the named list items,
    then asks which review entries no longer resolve."""
    contents = yaml_decode(case["yaml"], tree)
    if case["op"] == "roundTrip":
        return yaml_encode(contents.document, tree,
                           model_version=contents.model_version,
                           review=contents.review)
    for item in case["removeItems"]:
        contents.document.remove_list_item(item)
    return stale_review_paths(model, contents.document, contents.review or {})


def test_yaml_review(model: SpecModel, tree) -> None:
    for case in _read_json("yaml_review_cases.json")["cases"]:
        name = f"yamlReview[{case['name']}]"
        got = _run_yaml_review_case(model, tree, case)
        if isinstance(got, str):
            _check(name, got == case["expect"], _byte_diff(name, got, case["expect"]))
        else:
            _check(name, got == case["expect"], _json_mismatch(got, case["expect"]))


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
    imported = SpecDocument.from_markdown(golden, model)
    _check("md.land.clean", not imported.rejections,
           "; ".join(str(r) for r in imported.rejections))
    landed = imported.document
    _check("md.land.memory", landed.to_json() == canonical,
           _json_mismatch(landed.to_json(), canonical))


def _run_markdown_apply_case(model: SpecModel, case: dict) -> dict:
    """Runs one ``markdown_apply_cases.json`` case and returns what it observed,
    in the shape of the case's ``expect`` (mirrors Dart's
    ``_runMarkdownApplyCase``)."""
    markdown = case["markdown"]
    if case["op"] == "fromMarkdown":
        imported = SpecDocument.from_markdown(markdown, model)
        return {
            "refused": False,
            "rejectionCount": len(imported.rejections),
            "document": imported.document.to_json(),
        }
    document = SpecDocument()
    document.load_json(case["base"])
    parsed = SpecDocumentMarkdown(model, document).parse(markdown)
    refused = False
    try:
        document.apply_markdown_result(
            parsed, allow_rejections=bool(case["allowRejections"])
        )
    except RuntimeError:
        refused = True
    return {
        "refused": refused,
        "rejectionCount": len(parsed.rejections),
        "document": document.to_json(),
    }


def test_markdown_apply(model: SpecModel) -> None:
    """Applying a parsed Markdown import (SOM §11.7): a full overwrite of the
    covered roots that keeps other roots, and refuses a result with rejections
    unless the caller allows them."""
    for case in _read_json("markdown_apply_cases.json")["cases"]:
        name = f"mdApply[{case['name']}]"
        got = _run_markdown_apply_case(model, case)
        _check(name, got == case["expect"],
               _json_mismatch(got, case["expect"]))


def test_markdown_import_rejections(model: SpecModel) -> None:
    """The SOM §11.7 rejection protocol: nothing is silently dropped.

    Each case asserts both halves together — the full ``(line, reason, anchor,
    message)`` report *and* the document that still landed. A port that drops
    an unplaceable block fails the first; one that reports it and abandons the
    rest of the parse fails the second.
    """
    for case in _read_json("markdown_import_cases.json")["cases"]:
        name = case["name"]
        parsed = SpecDocumentMarkdown(model, SpecDocument()).parse(case["markdown"])
        got = [
            {
                "line": r.line,
                "reason": r.reason.value,
                "anchor": r.anchor,
                "message": r.message,
            }
            for r in parsed.rejections
        ]
        _check(f"md.reject[{name}].report", got == case["rejections"],
               _json_mismatch(got, case["rejections"]))
        landed = SpecDocument()
        landed.load_json({
            "content": parsed.content,
            "forms": parsed.forms,
            "lists": parsed.lists,
            "headlines": parsed.headlines,
        })
        _check(f"md.reject[{name}].landed", landed.to_json() == case["document"],
               _json_mismatch(landed.to_json(), case["document"]))


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
        elif kind == "valueThrows":
            _expect_raises(f"editor[{n}].valueThrows {s['path']}",
                           lambda s=s: ed.value(s["path"]))
        elif kind == "setValueThrows":
            _expect_raises(f"editor[{n}].setValueThrows {s['path']}",
                           lambda s=s: ed.set_value(s["path"], s["value"]))
        elif kind == "setContent":  # raw store write (bypasses the boundary)
            doc.set_content(s["path"], s["value"])
        elif kind == "setRawFormField":  # raw form write (bypasses boundary)
            doc.set_form_field(s["path"], s["field"], s["value"])
        elif kind == "valueUnreadable":
            _expect_raises(f"editor[{n}].valueUnreadable {s['path']}",
                           lambda s=s: ed.value(s["path"]))
        elif kind == "formValueUnreadable":
            _expect_raises(
                f"editor[{n}].formValueUnreadable {s['path']}#{s['field']}",
                lambda s=s: ed.form_value(s["path"], s["field"]))
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
        elif kind == "formValueThrows":
            _expect_raises(
                f"editor[{n}].formValueThrows {s['path']}#{s['field']}",
                lambda s=s: ed.form_value(s["path"], s["field"]))
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


#: Corpus tokens are spelled as the Dart constant names; each port maps them to
#: its own spelling. Python's are SCREAMING_SNAKE.
_EDITABILITY = {
    "editable": SomEditability.EDITABLE,
    "readOnlyCrossMajor": SomEditability.READ_ONLY_CROSS_MAJOR,
    "rejectedNewerMinor": SomEditability.REJECTED_NEWER_MINOR,
    "invalidVersion": SomEditability.INVALID_VERSION,
}


def test_editability() -> None:
    """The SOM §4.2/§21 version contract: the classification and the refusal.

    Both halves matter. ``som_editability_for`` is the single definition of the
    rules and ``check_som_model_version`` raises from it, so a port that
    classifies differently also raises differently — and a port that classifies
    right but raises out of the *classifier* has broken the one promise §21
    makes about it.
    """
    for case in _read_json("editability_cases.json")["cases"]:
        name = case["name"]
        generated = case["generated"]
        document_version = case["documentVersion"]
        want = _EDITABILITY[case["editability"]]

        got = som_editability_for(generated, document_version)
        _check(f"editability[{name}].classification", got is want, f"{got} != {want}")

        try:
            check_som_model_version(generated, document_version)
            raised = None
        except SomVersionError as e:
            raised = e.message
        _check(
            f"editability[{name}].rejects",
            (raised is not None) == case["rejects"],
            f"raised={raised!r}",
        )
        _check(
            f"editability[{name}].message",
            raised == case["message"],
            f"{raised!r} != {case['message']!r}",
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


def test_docspecs_path(model) -> None:
    """``docspecs_path_cases.json``: the renderer's heading map and
    :func:`validate_spec_document` binding each finding to its document path
    (SOM §14)."""
    table = _read_json("docspecs_path_cases.json")
    schema = DocSpecsSchema.from_yaml_text(table["schema"])
    for case in table["cases"]:
        name = case["name"]
        d = SpecDocument()
        d.load_json(case["state"])
        root_type = case["rootType"]
        rendition = d.to_markdown_with_map(model, root_type)
        got_map = {str(k): v for k, v in rendition.heading_paths.items()}
        _check(
            f"docspecsPath[{name}].headingPaths",
            got_map == case["headingPaths"],
            f"{got_map} != {case['headingPaths']}",
        )
        got = [
            {
                "rule": v.rule.value,
                "line": v.line,
                "sectionId": v.section_id,
                "path": v.path,
            }
            for v in validate_spec_document(model, d, schema, root_type)
        ]
        _check(
            f"docspecsPath[{name}].violations",
            got == case["violations"],
            f"{got} != {case['violations']}",
        )


def test_docspecs_replace() -> None:
    """``DocSpecsDocument.replace_section_body``: one case per table row.

    An error case must raise; any other case must return the expected text
    byte-for-byte.
    """
    for case in _read_json("docspecs_replace_cases.json")["cases"]:
        name = case["name"]
        expect = case["expect"]
        try:
            text = DocSpecsDocument.replace_section_body(
                case["markdown"], case["sectionId"], case["body"]
            )
            got: dict = {"error": False, "text": text}
        except ValueError:
            got = {"error": True}
        _check(f"docspecsReplace[{name}]", got == expect, f"{got!r} != {expect!r}")


def _run_assembly_case(case: dict) -> dict:
    """One ``assembly_cases.json`` case — a port of the Dart harness's
    ``_runAssemblyCase``: load each fragment state into a fresh document,
    assemble in the given order, and report what came out."""
    fragments = [
        (name, _document_from_state(state)) for name, state in case["fragments"]
    ]
    result = SpecDocument.assemble(fragments)
    return {
        "ok": result.ok,
        "document": None if result.document is None else result.document.to_json(),
        "overlaps": [
            {
                "store": o.store,
                "path": o.path,
                "field": o.field,
                "fragments": list(o.fragments),
                "message": o.message,
            }
            for o in result.overlaps
        ],
    }


def _run_list_move_case(model: SpecModel, case: dict) -> dict:
    """One ``list_move_cases.json`` case, in the corpus's wire form: the
    result and the document after the move, or the error word of a refusal
    (``argument`` / ``range`` / ``collision``)."""
    d = SpecDocument()
    d.load_json(case["state"])
    move = case["move"]
    try:
        result = d.move_list_item(
            model, move["itemPath"], move["toIndex"], to_list=move.get("toList")
        )
    except SpecSectionIdCollision:
        return {"ok": False, "error": "collision"}
    except IndexError:
        return {"ok": False, "error": "range"}
    except ValueError:
        return {"ok": False, "error": "argument"}
    return {
        "ok": True,
        "path": result.path,
        "renamed": result.renamed,
        "pinnedIds": result.pinned_ids,
        "document": d.to_json(),
    }


def test_list_move(model: SpecModel) -> None:
    """Moving a list item (``SpecDocument.move_list_item``, vsctsa44): a path
    is a position, the section id is the identity. Plus the review-pass
    re-keying a caller applies with the move's ``renamed`` map."""
    table = _read_json("list_move_cases.json")
    for case in table["cases"]:
        got = _run_list_move_case(model, case)
        _check(f"listMove[{case['name']}]", got == case["expect"],
               _json_mismatch(got, case["expect"]))
    for case in table["reviewCases"]:
        got = rekey_review(case["review"], case["renamed"])
        _check(f"listMoveReview[{case['name']}]", got == case["expect"],
               _json_mismatch(got, case["expect"]))


def test_assembly() -> None:
    """``assembly_cases.json``: assembling a document from fragments — the
    split-and-reassemble identity, per-field form merging, and the refusing
    rule per store."""
    table = _read_json("assembly_cases.json")
    for case in table["cases"]:
        got = _run_assembly_case(case)
        _check(
            f"assembly[{case['name']}]",
            got == case["expect"],
            _json_mismatch(got, case["expect"]),
        )
    # The first case's fragments were cut from `whole`; it must come back.
    first = _run_assembly_case(table["cases"][0])
    _check(
        "assembly.whole",
        first["document"] == table["whole"],
        _json_mismatch(first["document"], table["whole"]),
    )


# ---------------------------------------------------------------------------
# annotation_cases.json — review annotations (SOM §11.9)
# ---------------------------------------------------------------------------


def _run_annotation_op(model: SpecModel, tree, doc: SpecDocument,
                       api: SpecReviewAnnotations, op: dict):
    kind = op["op"]
    if kind == "list":
        return [a.to_json() for a in api.list()]
    if kind == "counts":
        return api.counts().to_json()
    if kind == "nextId":
        return api.next_comment_id(floor=op.get("floor") or 0)
    if kind == "assignIds":
        return api.assign_comment_ids(floor=op.get("floor") or 0)
    if kind == "insertComment":
        return api.insert_comment(
            path=op["path"],
            field=op.get("field"),
            after_paragraph=op["afterParagraph"],
            text=op["text"],
            author=op.get("author"),
            id=op.get("id"),
        )
    if kind == "insertQuestion":
        api.insert_question(
            path=op["path"],
            field=op.get("field"),
            after_paragraph=op["afterParagraph"],
            question=SpecQuestionDraft.from_json(op["question"]),
        )
        return None
    if kind == "insertQuestionAfterComment":
        api.insert_question_after_comment(
            op["commentId"], SpecQuestionDraft.from_json(op["question"]))
        return None
    if kind == "setAnswer":
        api.set_answer(op["id"], op["answer"])
        return None
    if kind == "editComment":
        api.edit_comment(op["id"], op["text"])
        return None
    if kind == "resolve":
        api.resolve(op["id"])
        return None
    if kind == "applyMark":
        accept = op.get("accept")
        api.apply_mark(
            path=op["path"],
            field=op.get("field"),
            index=op["index"],
            accept=True if accept is None else accept,
        )
        return None
    if kind == "strip":
        return api.stripped().to_json()
    if kind == "revision":
        return api.revision()
    if kind == "listMarks":
        return [m.to_json() for m in api.list_marks(path=op.get("path"))]
    if kind == "decideMarks":
        rev = op["revision"]
        return api.decide_marks(
            {k: SpecMarkDecision(v) for k, v in op["decisions"].items()},
            revision=api.revision() if rev == "@current" else rev,
        ).to_json()
    if kind == "acceptAll":
        return api.accept_all_marks(path=op.get("path")).to_json()
    if kind == "rejectAll":
        return api.reject_all_marks(path=op.get("path")).to_json()
    if kind == "removeAll":
        return api.remove_all_annotations().to_json()
    if kind == "setMarked":
        return api.set_marked(op["path"], op["text"], field=op.get("field")).to_json()
    if kind == "markAgainst":
        return api.mark_against(
            op["path"], op["earlier"], field=op.get("field")).to_json()
    if kind == "roundTrip":
        yaml = yaml_encode(doc, tree, model_version=_MODEL_VERSION)
        from_yaml = yaml_decode(yaml, tree).document
        md = SpecDocumentMarkdown(model, doc).export_root(model.roots[0])
        from_md = SpecDocument.from_markdown(md, model)
        return {
            "yaml": from_yaml.to_json() == doc.to_json(),
            "markdown": not from_md.rejections
            and from_md.document.to_json() == doc.to_json(),
        }
    raise ValueError(f"unknown annotation op {kind}")


def _run_annotation_case(model: SpecModel, tree, case: dict) -> dict:
    """Runs one case: ``{results: [one per op], state: final state}``. An
    operation that fails answers ``{error: true}`` and changes nothing."""
    doc = _document_from_state(json.loads(json.dumps(case["state"])))
    api = SpecReviewAnnotations(doc, qualifier=case.get("qualifier"))
    results = []
    for op in case["ops"]:
        try:
            results.append(_run_annotation_op(model, tree, doc, api, op))
        except SpecReviewAnnotationError:
            results.append({"error": True})
    return {"results": results, "state": doc.to_json()}


def test_annotations(model: SpecModel, tree) -> None:
    """``annotation_cases.json``: listing and editing review annotations."""
    for case in _read_json("annotation_cases.json")["cases"]:
        got = _run_annotation_case(model, tree, case)
        _check(
            f"annotations[{case['name']}]",
            got == case["expect"],
            _json_mismatch(got, case["expect"]),
        )


def test_inline_marks(model: SpecModel, tree) -> None:
    """``inline_mark_cases.json``: accepting and rejecting inline marks
    (SOM §11.9.3)."""
    table = _read_json("inline_mark_cases.json")
    for c in table["textCases"]:
        for accept, key in ((True, "accept"), (False, "reject")):
            got = apply_inline_marks_text(c["text"], accept=accept)
            _check(
                f"marks text[{c['name']}].{key}",
                got == c[key],
                f"got {got!r}, want {c[key]!r}",
            )
    for case in table["cases"]:
        got = _run_annotation_case(model, tree, case)
        _check(
            f"marks[{case['name']}]",
            got == case["expect"],
            _json_mismatch(got, case["expect"]),
        )


def test_change_marks(model: SpecModel, tree) -> None:
    """``change_mark_cases.json``: writing a change as inline marks
    (SOM §11.9.3)."""
    table = _read_json("change_mark_cases.json")
    for c in table["textCases"]:
        r = mark_change_text(c["old"], c["new"])
        name = f"change text[{c['name']}]"
        _check(f"{name}.marked", r.text == c["marked"],
               f"got {r.text!r}, want {c['marked']!r}")
        _check(f"{name}.exact", r.exact == c["exact"],
               f"got {r.exact}, want {c['exact']}")
        for accept, key in ((True, "accept"), (False, "reject")):
            got = apply_inline_marks_text(r.text, accept=accept)
            _check(f"{name}.{key}", got == c[key],
                   f"got {got!r}, want {c[key]!r}")
        if r.exact:
            _check(f"{name}.exactRoundTrip",
                   c["accept"] == c["new"] and c["reject"] == c["old"])
    for case in table["cases"]:
        got = _run_annotation_case(model, tree, case)
        _check(
            f"change[{case['name']}]",
            got == case["expect"],
            _json_mismatch(got, case["expect"]),
        )


def _run_answer_case(model: SpecModel, case: dict) -> dict:
    """Runs one answer case: ``{extracts: [...], markdown}``."""
    extracts = [
        extract_answers(
            model,
            _document_from_state(json.loads(json.dumps(d["state"]))),
            label=d["label"],
            path=case.get("path"),
        )
        for d in case["documents"]
    ]
    return {
        "extracts": [x.to_json() for x in extracts],
        "markdown": render_answers(
            extracts,
            SpecAnswerRenderOptions(
                include_open=case.get("includeOpen", False),
                include_marks=case.get("includeMarks", False),
                title=case.get("title", "Answers"),
            ),
        ),
    }


def test_answers(model: SpecModel) -> None:
    """``answer_cases.json``: extracting answers for a step folder
    (SOM §11.9.7)."""
    for case in _read_json("answer_cases.json")["cases"]:
        got = _run_answer_case(model, case)
        want = case["expect"]
        _check(
            f"answers[{case['name']}].extracts",
            got["extracts"] == want["extracts"],
            _json_mismatch(got["extracts"], want["extracts"]),
        )
        _check(
            f"answers[{case['name']}].markdown",
            got["markdown"] == want["markdown"],
            f"got {got['markdown']!r}, want {want['markdown']!r}",
        )


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


def _codespecs_step_cases(catalog_json: dict) -> dict:
    """Recomputes ``stepCases`` of ``codespecs_extract_cases.json``: the steps
    as read back, the steps per area in catalogue order, and the same for the
    catalogue with its ``steps`` key removed."""
    catalog = CodeSpecsAreaCatalog.from_json(catalog_json)
    legacy = CodeSpecsAreaCatalog.from_json(
        {k: v for k, v in catalog_json.items() if k != "steps"}
    )
    return {
        "steps": [
            {
                "number": s.number,
                "title": s.title,
                "slice": s.slice,
                "placedBy": s.placed_by,
                "areaCodes": s.area_codes,
            }
            for s in catalog.steps
        ],
        "stepsByArea": {
            a.code: [s.number for s in catalog.steps_for(a)]
            for a in catalog.areas
        },
        "legacy": {
            "steps": len(legacy.steps),
            "areas": len(legacy.areas),
            "stepsByArea": {
                a.code: [s.number for s in legacy.steps_for(a)]
                for a in legacy.areas
            },
        },
    }


def test_codespecs_extract(model: SpecModel) -> None:
    """The Phase-4 extract generator: the routing diagnostic, the per-area
    YAML/Markdown goldens, and the two guards that make "verbatim" checkable
    rather than trusted.

    The third and fourth blocks are the interesting ones. Every emitted value
    must be a member of the set of strings the document *stores* — membership,
    not substring, which is what stops a port composing a value out of two
    (`codespecs_derivation_contract.md` §2.8 C1). And a ``@FollowUpKind``
    subtree must contribute nothing at all, asserted against a section that is
    populated distinctively so its absence cannot be an accident of an empty
    section.
    """
    table = _read_json("codespecs_extract_cases.json")
    catalog = CodeSpecsAreaCatalog.from_json(table["catalog"])
    extractor = CodeSpecsExtractor(
        model=model, document=_build_document(), catalog=catalog
    )

    got = [
        {
            "path": r.path,
            "className": r.class_name,
            "verdict": r.verdict.value,
            "values": r.values,
            "note": r.note,
            "declaredAt": r.declared_at,
        }
        for r in extractor.routings()
    ]
    _check("codespecs.routings", got == table["routings"],
           _json_mismatch(got, table["routings"]))

    # The §4.4.6 authoring-step table, read back from the catalogue — and from
    # the same catalogue with `steps` deleted, which must load (an older
    # catalogue) and answer every area with no steps.
    got_steps = _codespecs_step_cases(table["catalog"])
    _check("codespecs.stepCases", got_steps == table["stepCases"],
           _json_mismatch(got_steps, table["stepCases"]))

    extracts = extractor.extract_all()
    want_extracts = table["extracts"]
    _check("codespecs.extracts.count", len(extracts) == len(want_extracts),
           f"{len(extracts)} != {len(want_extracts)}")
    for x, want in zip(extracts, want_extracts):
        name = want["area"]
        shape = {
            "area": x.area.code,
            "canonicalId": x.area.canonical_id,
            "part": x.area.kind_value,
            "documentRoot": x.document_root,
            "fileStem": x.file_stem,
            "projects": x.projects,
            "citableParts": x.citable_parts,
            "entries": [
                {
                    "sectionId": e.section_id,
                    "headline": e.headline,
                    "instanceId": e.instance_id,
                    "path": e.path,
                    "className": e.class_name,
                    "fieldName": e.field_name,
                    "formField": e.form_field,
                    "routedBy": e.routed_by,
                    "routedAt": e.routed_at,
                    "routingNote": e.routing_note,
                    "value": e.value,
                }
                for e in x.entries
            ],
        }
        want_shape = {k: v for k, v in want.items() if k not in ("yaml", "markdown")}
        _check(f"codespecs.extract[{name}].shape", shape == want_shape,
               _json_mismatch(shape, want_shape))
        _check(f"codespecs.extract[{name}].yaml", x.to_yaml() == want["yaml"],
               _byte_diff("yaml", x.to_yaml(), want["yaml"]))
        _check(f"codespecs.extract[{name}].markdown",
               x.to_markdown() == want["markdown"],
               _byte_diff("markdown", x.to_markdown(), want["markdown"]))

    state = _read_json("state.json")
    stored = set(state["content"].values())
    for section in state["forms"].values():
        stored.update(section.values())
    _check("codespecs.storedNotEmpty", bool(stored))
    composed = [
        f"{x['area']} {e['path']}"
        for x in want_extracts
        for e in x["entries"]
        if e["value"] not in stored
    ]
    _check("codespecs.verbatim", not composed,
           f"not copied from the document: {composed}")

    emitted = [e["value"] for x in want_extracts for e in x["entries"]]
    for excluded in ("Controlled summary", "ctrl-owner", "alice"):
        _check(f"codespecs.excluded[{excluded}]", excluded not in emitted,
               "reached an extract")

    for case in table["errorCases"]:
        name = case["name"]
        # The error case carries its own model and state rather than mutating
        # the shared fixture: `model.meta.json` is a VALID model by construction
        # (§10.2 ROUTE-TOTAL holds over it). `state` is the ordinary state.json
        # shape, so every runtime already has the loader.
        err_doc = SpecDocument()
        err_doc.load_json(case["state"])
        err_extractor = CodeSpecsExtractor(
            model=SpecModel.from_json(case["model"]),
            document=err_doc,
            catalog=catalog,
        )
        want = case["expect"]
        try:
            err_extractor.extract_all()
            raised = None
        except CodeSpecsExtractError as e:
            raised = e
        _check(f"codespecs.error[{name}].raises", raised is not None,
               "did not raise")
        if raised is not None:
            _check(f"codespecs.error[{name}].path", raised.path == want["path"],
                   raised.path)
            _check(f"codespecs.error[{name}].className",
                   raised.class_name == want["className"], raised.class_name)
            _check(f"codespecs.error[{name}].message",
                   want["messageContains"] in raised.message, raised.message)
        # …and the diagnostic reports the same node instead of throwing.
        verdicts = [
            r.verdict.value
            for r in err_extractor.routings()
            if r.path == want["path"]
        ]
        _check(f"codespecs.error[{name}].routingVerdict",
               verdicts == [want["routingVerdict"]], str(verdicts))

    # A malformed catalogue row (a slice, area or step missing a required
    # field, or carrying a string where a number belongs) must fail naming the
    # row, never load as 0 — every runtime pins the same message fragment, so
    # the row label is part of the contract.
    for case in table["catalogErrorCases"]:
        name = case["name"]
        want = case["expect"]["messageContains"]
        try:
            CodeSpecsAreaCatalog.from_json(case["catalog"])
            raised = None
        except ValueError as e:
            raised = e
        _check(f"codespecs.catalogError[{name}].raises", raised is not None,
               "did not raise")
        if raised is not None:
            _check(f"codespecs.catalogError[{name}].message",
                   want in str(raised), str(raised))

    # Root scoping (`codespecs_prompt.md` §5): the walk starts at ONE root. The
    # models here carry two, because over a single-root model "walks the named
    # root" and "walks every root" give the same answer.
    for case in table["rootCases"]:
        name = case["name"]
        root_doc = SpecDocument()
        root_doc.load_json(case["state"])
        root_model = SpecModel.from_json(case["model"])
        want = case["expect"]

        def build() -> CodeSpecsExtractor:
            return CodeSpecsExtractor(
                model=root_model,
                document=root_doc,
                catalog=catalog,
                root_type=case.get("rootType"),
            )

        if want["fails"]:
            try:
                build()
                raised = None
            except CodeSpecsExtractError as e:
                raised = e
            _check(f"codespecs.root[{name}].raises", raised is not None,
                   "did not raise")
            if raised is not None:
                _check(f"codespecs.root[{name}].path",
                       raised.path == want["path"], raised.path)
                _check(f"codespecs.root[{name}].className",
                       raised.class_name == want["className"],
                       raised.class_name)
                _check(f"codespecs.root[{name}].message",
                       want["messageContains"] in raised.message,
                       raised.message)
            continue

        x = build()
        _check(f"codespecs.root[{name}].root", x.root.type == want["root"],
               x.root.type)
        # `routings` and `extract_all` walk the same resolved root, so the
        # verdict sequence is scoped too — that is what makes the bare
        # `@Document` root of case 2 the corpus's `documentRoot` producer.
        verdicts = [r.verdict.value for r in x.routings()]
        _check(f"codespecs.root[{name}].routingVerdicts",
               verdicts == want["routingVerdicts"], str(verdicts))
        got_extracts = x.extract_all()
        _check(f"codespecs.root[{name}].documentRoot",
               got_extracts[0].document_root == want["documentRoot"],
               got_extracts[0].document_root)
        paths = [e.path for g in got_extracts for e in g.entries]
        _check(f"codespecs.root[{name}].paths", paths == want["paths"],
               str(paths))


def _extract_summary(x) -> dict:
    return {
        "area": x.area.code,
        "canonicalId": x.area.canonical_id,
        "part": x.area.part,
        "documentRoot": x.document_root,
        "projects": list(x.projects),
        "citableParts": list(x.citable_parts),
        "entryCount": len(x.entries),
        "sectionIds": [e.section_id for e in x.entries],
        "values": [e.value for e in x.entries],
        "classNames": [e.class_name for e in x.entries],
        "headlines": [e.headline for e in x.entries],
    }


def _gate_verdict_summary(v) -> dict:
    out = {
        "area": v.area,
        "verdict": v.verdict.word,
        "resolution": v.resolution,
        "note": v.note,
    }
    # Only when present, so a gap-less entry's summary is unchanged.
    if v.gaps:
        out["gaps"] = [
            {"sectionId": g.section_id, "required": g.required, "carrier": g.carrier}
            for g in v.gaps
        ]
    return out


def _gate_summary(g) -> dict:
    return {"verdicts": [_gate_verdict_summary(v) for v in g.verdicts]}


def _scope_summary(s) -> dict:
    return {
        "inScope": [x.area.code for x in s.extracts],
        "sources": list(s.sources),
        "hasGate": s.gate is not None,
        "excluded": [
            {
                "area": e.area,
                "verdict": e.verdict.word,
                "descoped": e.descoped,
                "entryCount": e.entry_count,
                "source": e.source,
            }
            for e in s.excluded
        ],
    }


def _gate_entry(v: dict):
    return CodeSpecsGateEntry(
        area=v["area"],
        verdict=CodeSpecsGateVerdict.parse(v["verdict"]),
        resolution=v.get("resolution"),
        note=v.get("note"),
        gaps=tuple(
            CodeSpecsGateGap(
                section_id=g["sectionId"], required=g["required"], carrier=g["carrier"]
            )
            for g in v.get("gaps") or ()
        ),
    )


def _record_error(fn):
    """The :class:`CodeSpecsRecordError` *fn* raises, or ``None``."""
    try:
        fn()
    except CodeSpecsRecordError as e:
        return e
    return None


def _run_gate_case(table: dict, case: dict, meta: dict) -> dict:
    """One gate case of ``codespecs_gate_cases.json`` — a port of the Dart
    harness's ``_runGateCase``. A case key that is **present** overrides the
    table default: ``schema: null`` means no schema, ``gate: null`` a catalogue
    without gate tables, so presence is tested with ``in``, not ``get``."""
    catalog_json = dict(table["catalog"])
    gate = case["gate"] if "gate" in case else table["gate"]
    if gate is not None:
        catalog_json["gate"] = gate
    schema_yaml = case["schema"] if "schema" in case else table["schema"]
    model = SpecModel.from_json(case.get("model") or meta)
    report = CodeSpecsGate(
        model=model,
        document=_document_from_state(case["state"]),
        catalog=CodeSpecsAreaCatalog.from_json(catalog_json),
        schema=None if schema_yaml is None else DocSpecsSchema.from_yaml_text(schema_yaml),
    ).run()
    return {
        "passed": report.passed,
        "results": [
            {
                "check": r.check.label,
                "ran": r.ran,
                "notRunReason": r.not_run_reason,
                "findings": [
                    {"code": f.code, "location": f.location, "message": f.message}
                    for f in r.findings
                ],
            }
            for r in report.results
        ],
    }


def test_codespecs_gate() -> None:
    """``codespecs_gate_cases.json``: the Stage-A gate, A1–A5, one case per
    rule shape, each compared whole against the Dart reference's report."""
    table = _read_json("codespecs_gate_cases.json")
    meta = _read_json("model.meta.json")
    for case in table["cases"]:
        name = case["name"]
        got = _run_gate_case(table, case, meta)
        _check(f"codespecs_gate[{name}]", got == case["expect"],
               _json_mismatch(got, case["expect"]))


def test_codespecs_records() -> None:
    """Reading extracts and the gate record back
    (``codespecs_record_cases.json``): every extract the extractor writes reads
    back byte-stably, the gate record round-trips and checks its shape, and a
    tree of extracts is scoped by its record with the reference's exact
    errors."""
    table = _read_json("codespecs_record_cases.json")
    catalog = CodeSpecsAreaCatalog.from_json(
        _read_json("codespecs_extract_cases.json")["catalog"]
    )

    for c in table["extractReads"]:
        name = f"records.extractRead[{c['source']}]"
        x = CodeSpecsExtract.from_yaml(c["yaml"], source=c["source"])
        got = _extract_summary(x)
        _check(f"{name}.summary", got == c["expect"], _json_mismatch(got, c["expect"]))
        out = x.to_yaml()
        _check(f"{name}.roundTrip", out == c["yaml"],
               _byte_diff("toYaml", out, c["yaml"]))

    c = table["extractMinimal"]
    x = CodeSpecsExtract.from_yaml(c["yaml"], source=c["source"])
    got = _extract_summary(x)
    _check("records.extractMinimal", got == c["expect"],
           _json_mismatch(got, c["expect"]))

    for c in table["extractErrors"]:
        name = f"records.extractError[{c['name']}]"
        err = _record_error(
            lambda c=c: CodeSpecsExtract.from_yaml(c["yaml"], source=c["source"])
        )
        _check(name, err is not None and c["messageContains"] in err.message,
               "no error" if err is None else err.message)

    for c in table["gateRecords"]:
        name = f"records.gateRecord[{c['name']}]"
        g = CodeSpecsGateRecord.from_yaml(c["yaml"])
        got = _gate_summary(g)
        _check(f"{name}.summary", got == c["expect"], _json_mismatch(got, c["expect"]))
        out = g.to_yaml()
        _check(f"{name}.toYaml", out == c["yaml"], _byte_diff("toYaml", out, c["yaml"]))
        err = _record_error(lambda g=g: g.check_against(catalog))
        _check(f"{name}.checkAgainst", err is None, "" if err is None else err.message)

    for c in table["gateWrites"]:
        name = f"records.gateWrite[{c['name']}]"
        g = CodeSpecsGateRecord([_gate_entry(v) for v in c["verdicts"]])
        out = g.to_yaml()
        _check(f"{name}.yaml", out == c["yaml"], _byte_diff("toYaml", out, c["yaml"]))
        then = c.get("then")
        if then is not None:
            g = g.with_verdict(_gate_entry(then))
            out = g.to_yaml()
            _check(f"{name}.thenYaml", out == c["thenYaml"],
                   _byte_diff("toYaml", out, c["thenYaml"]))

    for c in table["gateErrors"]:
        name = f"records.gateError[{c['name']}]"

        def act(c=c) -> None:
            g = CodeSpecsGateRecord.from_yaml(c["yaml"])
            if c.get("againstCatalog") is True:
                g.check_against(catalog)

        err = _record_error(act)
        _check(name, err is not None and c["messageContains"] in err.message,
               "no error" if err is None else err.message)

    for c in table["scopeCases"]:
        name = f"records.scope[{c['name']}]"
        files = [(f[0], f[1]) for f in c["files"]]
        want = c["expect"]
        if "error" in want:
            err = _record_error(lambda files=files: CodeSpecsExtractSet.from_files(files))
            _check(name, err is not None and want["error"] in err.message,
                   "no error" if err is None else err.message)
            continue
        got = _scope_summary(CodeSpecsExtractSet.from_files(files))
        _check(name, got == want, _json_mismatch(got, want))


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
    test_editability()
    test_state_round_trip()
    test_yaml_encode(tree)
    test_yaml_decode_round_trip(tree)
    test_yaml_review(model, tree)
    test_markdown_export(model)
    test_markdown_round_trip(model)
    test_markdown_lands_in_shared_memory(model)
    test_markdown_import_rejections(model)
    test_markdown_apply(model)
    test_reflection(model)
    test_validation(model)
    test_operations()
    test_editor(model)
    test_section_id()
    test_serialization_order()
    test_docspecs()
    test_docspecs_path(model)
    test_docspecs_replace()
    test_assembly()
    test_annotations(model, tree)
    test_inline_marks(model, tree)
    test_change_marks(model, tree)
    test_answers(model)
    test_list_move(model)
    test_build_document_matches_state()
    test_pattern()
    test_query(model)
    test_projection(model)
    test_codespecs_extract(model)
    test_codespecs_records()
    test_codespecs_gate()
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
