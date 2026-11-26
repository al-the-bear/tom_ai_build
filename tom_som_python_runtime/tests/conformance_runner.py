#!/usr/bin/env python3
"""Shared-corpus conformance runner for the Python generic runtime.

Loads the language-agnostic conformance corpus produced from the Dart reference
(``tom_som_conformance/corpus``) and asserts the Python port reproduces every
golden byte-for-byte and matches every behavioural case:

  * model meta-data loads (root + class structure);
  * the generation stamp decodes and reaches the shared staleness verdict;
  * the SOM §4.2/§21 editability classification and its refusal messages;
  * ``state.json`` loads and re-serialises identically;
  * YAML encode == ``expected.tomspecs.yaml`` (byte-for-byte);
  * YAML decode → memory → encode is byte-stable + preserves the stamp;
  * Markdown export == ``expected.tables.md`` (byte-for-byte);
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
    (``list_move_cases.json``);
  * the strip of one value, the readable header and the strip of a document
    (``strip_cases.json``, SOM §11.10).
  * the merge back of an edited value and of an edited readable rendition
    (``strip_merge_cases.json``, SOM §11.10);
  * the section-link readers and the place / filter grammar
    (``link_reader_cases.json``), the link checks of one document
    (``link_validation_cases.json``) and the typed values and headlines
    under review (the ``typedCases`` of ``inline_mark_cases.json`` /
    ``change_mark_cases.json``), `tom_specs_model_rules.md` §9.7;
  * the document set, its report and the global rename
    (``document_set_cases.json``), ``derive_fields`` (``derive_cases.json``),
    ``prefill`` and ``backfill`` (``prefill_cases.json``,
    ``backfill_cases.json``), `tom_specs_model_rules.md` §9.7.

Run with: ``python3 tests/conformance_runner.py``. Exit code 0 == all green.
"""

from __future__ import annotations

import datetime as _dt
import json
import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
_CORPUS = os.path.normpath(
    os.path.join(_PKG_ROOT, "..", "tom_som_conformance", "corpus")
)

sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SpecDocumentStrip,
    SpecStripMerge,
    merge_stripped_value,
    SpecReadableHeader,
    SpecReadableSource,
    SpecStripOptions,
    SpecStripUsageError,
    strip_annotations_text,
    strip_notation_text,
    SpecReviewMember,
    SpecReviewMergeError,
    SpecReviewMergeOptions,
    SpecReviewedCopy,
    merge_reviews,
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
    NotationFindingCode,
    scan_notation,
    SomEditability,
    SomList,
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
    decide_all_marks_text,
    mark_change_text,
    validate_document,
    validate_spec_document,
    rekey_review,
    stale_review_paths,
    yaml_decode,
    yaml_encode,
    K_SPEC_STANDARD_EMITTERS,
    spec_default_units,
    spec_generation_units,
    SpecImpactFolder,
    spec_impact_document_files,
    spec_impact_level,
    spec_impact_walk,
    spec_impact_walk_markdown,
    SpecPlace,
    SpecPlaceException,
    SpecPlaceFilter,
    SpecPlaceProblem,
    SpecValidationCode,
    spec_same_as_bindings,
    validate_links,
    SpecBackfillError,
    SpecDocumentSet,
    SpecDocumentSetError,
    SpecPrefillError,
    SpecRenameError,
    backfill,
    derive_fields,
    prefill,
    rename_id,
    sync_report,
)
from tom_som_runtime.spec_typed_values import (  # noqa: E402
    som_format_double,
    som_format_int,
    som_format_num,
    som_parse_bool,
    som_parse_double,
    som_parse_enum_name,
    som_parse_int,
    som_parse_num,
    som_scalar_base,
    som_typed_reading,
    som_typed_text_readable,
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
    # SOM §11.2 `units`: a section carrying codeSpec AND units (`TTL`, both
    # keys in one heading comment, the scalar-promotion mapping in yaml) and a
    # section carrying units alone (`notes`), which the extract hands down to
    # every entry beneath it. Both ids are declared by the register.
    d.set_code_spec("DEMO/TTL", "DemoTitle")
    d.set_units("DEMO/TTL", "demo_server")
    d.set_units("DEMO/notes", "demo_client,demo_server")
    # Pattern-list items store their positional ids, as `REF-2` does above.
    u1 = d.add_list_item("DEMO/DLV-LST", section_id="DLV-1")
    d.set_form_field(f"{u1}/content", "unitId", "demo_client")
    d.set_form_field(f"{u1}/content", "kind", "client")
    d.set_form_field(f"{u1}/content", "component", "ARCM-COMP-UI")
    # Both units map CE-NV, so an entry routed there with no stored units goes
    # to both by default, in register order (the extract's `units`).
    n1 = d.add_list_item(f"{u1}/DLR-LST", section_id="DLR-1")
    d.set_form_field(f"{n1}/content", "area", "CE-NV")
    d.set_form_field(f"{n1}/content", "mapping", "dart-tom")
    u2 = d.add_list_item("DEMO/DLV-LST", section_id="DLV-2")
    d.set_form_field(f"{u2}/content", "unitId", "demo_server")
    d.set_form_field(f"{u2}/content", "kind", "server")
    d.set_form_field(f"{u2}/content", "deploymentTarget", "DEPTAR-DEPL-API")
    r1 = d.add_list_item(f"{u2}/DLR-LST", section_id="DLR-1")
    d.set_form_field(f"{r1}/content", "area", "CE-DB")
    d.set_form_field(f"{r1}/content", "mapping", "dart-tom")
    r2 = d.add_list_item(f"{u2}/DLR-LST", section_id="DLR-2")
    d.set_form_field(f"{r2}/content", "area", "CE-NV")
    d.set_form_field(f"{r2}/content", "mapping", "dart-tom")
    # The server ships the OpenAPI document of its contract (irspecs_ir.md §10).
    e1 = d.add_list_item(f"{u2}/DLE-LST", section_id="DLE-1")
    d.set_form_field(f"{e1}/content", "emitter", "openapi")
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
    _check("model.classCount", len(model.classes) == 19, str(len(model.classes)))
    demo = model.class_named("Demo")
    _check("model.Demo.found", demo is not None)
    if demo is not None:
        names = [f.name for f in demo.fields]
        _check(
            "model.Demo.fields",
            names == ["title", "summary", "priority", "count", "ratio", "score", "details", "items", "refs", "cards", "meta", "control", "notes", "mixed", "registry", "deliverables"],
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
    expected = _read("expected.tomspecs.yaml")
    actual = yaml_encode(doc, tree, model_version=_MODEL_VERSION)
    _check("yaml.encode", actual == expected, _byte_diff("yaml.encode", actual, expected))


def test_yaml_decode_round_trip(tree) -> None:
    expected = _read("expected.tomspecs.yaml")
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


def _typed_review(v):
    """The typed reading of a review value in the corpus's tagged form: a map
    as ``[key, value]`` pairs sorted by key, a list in order, an int as its
    decimal text, a float as the review writer prints it, a string as
    itself."""
    from tom_som_runtime.spec_document_yaml import review_scalar
    if v is None:
        return {"type": "null"}
    if isinstance(v, bool):
        return {"type": "bool", "value": v}
    if isinstance(v, int):
        return {"type": "int", "value": str(v)}
    if isinstance(v, float):
        return {"type": "float", "value": review_scalar(v)}
    if isinstance(v, str):
        return {"type": "string", "value": v}
    if isinstance(v, list):
        return {"type": "list", "value": [_typed_review(x) for x in v]}
    return {"type": "map",
            "value": [[k, _typed_review(v[k])] for k in sorted(v)]}


def _run_yaml_review_case(model: SpecModel, tree, case: dict):
    """Runs one ``yaml_review_cases.json`` case: ``typedReview`` reports the
    typed reading of the review pass; ``roundTrip`` re-encodes the decoded file
    with its review pass; ``stale`` removes the named list items, then asks
    which review entries no longer resolve."""
    contents = yaml_decode(case["yaml"], tree)
    if case["op"] == "typedReview":
        return _typed_review(contents.review)
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


# The layout this runtime emits: `tables` (SOM §11.4, §11.5). Its export
# golden is expected.tables.md; expected.tomspecs.md, the `Field:`-line layout,
# is parsed only.
EMITTED_LAYOUT = "tables"
EXPORT_GOLDEN = f"expected.{EMITTED_LAYOUT}.md"


def _expect_for(case: dict):
    """The expectation of *case* for this runtime's layout: ``expectTables``
    when the case has one (its renditions' lines differ by layout), else
    ``expect``."""
    if EMITTED_LAYOUT == "tables" and "expectTables" in case:
        return case["expectTables"]
    return case["expect"]


def test_markdown_export(model: SpecModel) -> None:
    doc = _document_from_state(_read_json("state.json"))
    expected = _read(EXPORT_GOLDEN)
    actual = SpecDocumentMarkdown(model, doc).export_root(model.roots[0])
    _check("md.export", actual == expected,
           _byte_diff("md.export", actual, expected))


def test_markdown_round_trip(model: SpecModel) -> None:
    golden = _read(EXPORT_GOLDEN)
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
        "codeSpecs": parsed.code_specs,
        "units": parsed.units,
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
    """Markdown/YAML convergence: parsing either golden (``expected.tables.md``,
    the reading view's tables, and ``expected.tomspecs.md``, the ``Field:``
    lines) and applying it must reproduce ``state.json`` (the YAML-route
    memory) exactly, proving both formats converge on one in-memory document
    (SOM §8)."""
    canonical = _read_json("state.json")
    for label, golden in (("tables", "expected.tables.md"),
                          ("fields", "expected.tomspecs.md")):
        imported = SpecDocument.from_markdown(_read(golden), model)
        _check(f"md.land.{label}.clean", not imported.rejections,
               "; ".join(str(r) for r in imported.rejections))
        landed = imported.document
        _check(f"md.land.{label}.memory", landed.to_json() == canonical,
               _json_mismatch(landed.to_json(), canonical))


def _run_markdown_apply_case(model: SpecModel, case: dict, schema: str) -> dict:
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
    out: dict = {
        "refused": refused,
        "rejectionCount": len(parsed.rejections),
        "document": document.to_json(),
    }
    # The validator reports every kept block of an apply case as
    # ``rejectedBlock`` (DocSpecs RN-11), with the document path it stands in.
    if case.get("readingView"):
        out["rejectedBlocks"] = [
            {"line": v.line, "path": v.path}
            for v in validate_spec_document(
                model, document, DocSpecsSchema.from_yaml_text(schema), "Demo"
            )
            if v.rule == DocSpecsViolationRule.REJECTED_BLOCK
        ]
    return out


def test_markdown_apply(model: SpecModel) -> None:
    """Applying a parsed Markdown import (SOM §11.7): a full overwrite of the
    covered roots that keeps other roots, and refuses a result with rejections
    unless the caller allows them."""
    table = _read_json("markdown_apply_cases.json")
    for case in table["cases"]:
        name = f"mdApply[{case['name']}]"
        got = _run_markdown_apply_case(model, case, table["schema"])
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
        # A case naming the readable header holds it (SOM §11.1).
        if "readableHeader" in case:
            _check(f"md.reject[{name}].readableHeader",
                   parsed.readable_header == case["readableHeader"],
                   f"got {parsed.readable_header!r}")
        # A case naming heading-comment values holds them too (read trimmed).
        for key, attr in (("codeSpecs", "code_specs"), ("units", "units")):
            if key in case:
                got_values = getattr(parsed, attr)
                _check(f"md.reject[{name}].{key}", got_values == case[key],
                       _json_mismatch(got_values, case[key]))


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

    # AA1 criterion 5 through the SomList facade: add / add_content with an
    # explicit section id, generated ids for a date, and a pattern-less list
    # ignoring the id.
    list_doc = SpecDocument()
    for i, s in enumerate(cases["listAdd"]["steps"]):
        lst = SomList(list_doc, s["listPath"], lambda _d, p: p, s.get("pattern"))
        date = (_dt.date(2026, s["month"], s["day"])
                if s.get("month") is not None else None)
        section_id = s.get("sectionId")
        try:
            if s["op"] == "add":
                p = lst.add(section_id, date)
            else:
                p = lst.add_content(s["content"], section_id, date)
            got = {"path": p, "content": list_doc.content(f"{p}/content")}
        except SpecSectionIdCollision:
            got = {"error": "collision"}
        got["sectionIds"] = list_doc.list_item_section_ids(s["listPath"])
        got["items"] = list_doc.list_items(s["listPath"])
        got_json = json.dumps(got, sort_keys=True)
        want_json = json.dumps(s["expect"], sort_keys=True)
        _check(f"sectionId.listAdd[{i}].{s['op']}", got_json == want_json,
               f"{got_json} != {want_json}")


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
    # The reading notation's rules are exercised by notation_cases.json's
    # validator cases (test_notation), not by the nine-runtime table.
    for case in _read_json("notation_cases.json")["validatorCases"]:
        covered.update(v["rule"] for v in case["violations"])
    uncovered = sorted(
        r.value for r in DocSpecsViolationRule if r.value not in covered
    )
    _check("docspecs.ruleCoverage", not uncovered, f"uncovered: {uncovered}")


def test_notation() -> None:
    """The reading notation (``notation_cases.json``): each text value scanned
    with :func:`scan_notation` — its elements (UTF-16 ``start``/``end``,
    ``line``/``endLine``, ``source``/``content``, nesting) and findings — and
    the validator cases, the nine notation rules of the embedded DocSpecs
    validator (DocSpecs specification, Reading Notation RN-1 … RN-13)."""
    table = _read_json("notation_cases.json")
    codes: set[str] = set()
    for case in table["cases"]:
        name = case["name"]
        scan = scan_notation(case["text"], tom_specs=case.get("tomSpecs") is True)
        elements = [e.to_json(case["text"]) for e in scan.elements]
        findings = [f.to_json() for f in scan.findings]
        _check(
            f"notation.scan[{name}].elements",
            elements == case["elements"],
            f"{elements} != {case['elements']}",
        )
        _check(
            f"notation.scan[{name}].findings",
            findings == case["findings"],
            f"{findings} != {case['findings']}",
        )
        codes.update(f["code"] for f in case["findings"])
    uncovered = [c.value for c in NotationFindingCode if c.value not in codes]
    _check("notation.codeCoverage", not uncovered, f"uncovered: {uncovered}")
    schema = DocSpecsSchema.from_yaml_text(_read("docspecs_schema.yaml"))
    for case in table["validatorCases"]:
        got = [
            {"rule": v.rule.value, "sectionId": v.section_id, "line": v.line}
            for v in DocSpecsValidator(
                schema, tom_specs=case.get("tomSpecs") is True
            ).validate_markdown(case["markdown"])
        ]
        _check(
            f"notation.validate[{case['name']}]",
            got == case["violations"],
            f"{got} != {case['violations']}",
        )


def _strip_case_options(case: dict) -> SpecStripOptions:
    """A strip case's options, from its name lists and flags; raises
    :class:`SpecStripUsageError` for a usage error."""
    return SpecStripOptions.from_names(
        drop=case.get("drop") or [],
        unmark=case.get("unmark") or [],
        appendix=case.get("appendix") or [],
        appendix_references=case.get("appendixReferences") is True,
        heading_divs=case.get("headingDivs") is True,
    )


def _strip_unstrip(stripped: str, pieces) -> str:
    """*stripped* with every piece's removed text put back: the original
    value. The pieces' offsets count UTF-16 units, so the walk does too."""
    def units(s: str) -> bytes:
        return s.encode("utf-16-le", "surrogatepass")

    t = units(stripped)
    out = bytearray()
    at = 0
    for p in pieces:
        out += t[at * 2 : p.anchor * 2]
        out += units(p.removed)
        at = p.anchor + len(units(p.inserted)) // 2
    out += t[at * 2 :]
    return bytes(out).decode("utf-16-le", "surrogatepass")


def _strip_options_json(o: SpecStripOptions) -> dict:
    return {
        "drop": SpecStripOptions.ordered(o.drop),
        "unmark": SpecStripOptions.ordered(o.unmark),
        "appendix": SpecStripOptions.ordered(o.appendix),
        "appendixReferences": o.appendix_references,
        "headingDivs": o.heading_divs,
    }


def test_strip(model: SpecModel) -> None:
    """Stripped renditions (``strip_cases.json``, SOM §11.10): each case's
    :func:`strip_notation_text` result (text, counts, ``marksDropped``,
    appendix, pieces, refusals), its pieces restoring the original, and a
    comments-only strip agreeing with :func:`strip_annotations_text`; each
    usage case's :meth:`SpecStripOptions.from_names` options or error; each
    header case's :meth:`SpecReadableHeader.parse` (and ``format`` its
    inverse); each document case's :meth:`SpecDocumentStrip.strip` over the
    corpus model and ``docspecs_schema.yaml`` unless ``model`` is false."""
    table = _read_json("strip_cases.json")
    cases = table["cases"]
    _check("strip.cases", len(cases) > 0, "no cases")
    for case in cases:
        tag = f"strip[{case['name']}]"
        text = case["text"]
        try:
            r = strip_notation_text(text, _strip_case_options(case))
        except Exception as e:  # noqa: BLE001
            _check(tag, False, f"raised {e!r}")
            continue
        got = r.to_json()
        _check(tag, got == case["expect"], f"{got} != {case['expect']}")
        back = _strip_unstrip(r.text, r.pieces)
        _check(f"{tag}.pieces", back == text, repr(back))
        if (case.get("drop") or []) == ["comments"]:
            _check(
                f"{tag}.stripAnnotationsText",
                strip_annotations_text(text) == r.text,
                repr(r.text),
            )
    usage = table["usageCases"]
    _check("strip.usageCases", len(usage) > 0, "no usage cases")
    for case in usage:
        tag = f"strip.usage[{case['name']}]"
        try:
            got = _strip_case_options(case).to_json()
        except SpecStripUsageError as e:
            got = {"error": str(e)}
        _check(tag, got == case["expect"], f"{got} != {case['expect']}")
    headers = table["headerCases"]
    _check("strip.headerCases", len(headers) > 0, "no header cases")
    for case in headers:
        tag = f"strip.header[{case['name']}]"
        h = SpecReadableHeader.parse(case["line"])
        got = None
        if h is not None:
            got = _strip_options_json(h.options)
            if h.source is not None:
                got["source"] = {
                    "file": h.source.file,
                    "revision": h.source.revision,
                    "commit": h.source.commit,
                    "dirty": h.source.dirty,
                }
            got["format"] = h.format()
            again = SpecReadableHeader.parse(h.format())
            _check(f"{tag}.inverse",
                   again is not None and again.format() == h.format(),
                   repr(again))
        _check(tag, got == case["expect"], _json_mismatch(got, case["expect"]))
    schema = DocSpecsSchema.from_yaml_text(_read("docspecs_schema.yaml"))
    documents = table["documentCases"]
    _check("strip.documentCases", len(documents) > 0, "no document cases")
    for case in documents:
        tag = f"strip.document[{case['name']}]"
        try:
            doc = SpecDocument()
            doc.load_json(case["state"])
            with_model = case.get("model") is not False
            src = case.get("source")
            r = SpecDocumentStrip.strip(
                doc,
                _strip_case_options(case),
                model=model if with_model else None,
                schema=schema if with_model else None,
                root_type=case.get("rootType"),
                source=None if src is None else SpecReadableSource(
                    src["file"],
                    src.get("revision"),
                    src.get("commit"),
                    src.get("dirty") is True,
                ),
            )
        except Exception as e:  # noqa: BLE001
            _check(tag, False, f"raised {e!r}")
            continue
        got = {
            "document": r.document.to_json(),
            "kept": [k.ref.to_json() for k in r.kept],
            "removedItems": r.removed_items,
            "appendix": [e.to_json() for e in r.appendix],
            "dropped": r.dropped,
            "unmarked": r.unmarked,
            "appended": r.appended,
            "marksDropped": r.marks_dropped,
            "readableHeader": r.readable_header,
            "readable": r.readable,
            "findings": [f.kind for f in r.findings],
        }
        _check(tag, got == case["expect"], _json_mismatch(got, case["expect"]))


def _apply_case_edits(text: str, edits) -> str:
    """*text* with each ``[find, replace]`` applied to its one occurrence."""
    out = text
    for find, replace in edits or []:
        if find == "":
            if out != "":
                raise ValueError("an empty find needs an empty text")
            out = replace
            continue
        at = out.find(find)
        if at < 0 or out.find(find, at + 1) >= 0:
            raise ValueError(f'the edit "{find}" does not occur exactly once')
        out = out[:at] + replace + out[at + len(find):]
    return out


def _state_document(state: dict) -> SpecDocument:
    d = SpecDocument()
    d.load_json(state)
    return d


def test_strip_merge(model: SpecModel) -> None:
    """``strip_merge_cases.json`` (SOM §11.10): ``valueCases`` — a value
    stripped, its stripped text edited, and :func:`merge_stripped_value` of
    the edit onto the original; ``documentCases`` — a document stripped into
    its readable rendition, the rendition edited, and
    :meth:`SpecStripMerge.merge` of it onto the document (or onto
    ``current``, the original moved since, three ways from ``base`` or the
    header's commit in ``commits``): the exit code, staleness, the merged
    document and the report, or the usage error."""
    table = _read_json("strip_merge_cases.json")
    schema = DocSpecsSchema.from_yaml_text(_read("docspecs_schema.yaml"))
    values = table["valueCases"]
    _check("stripMerge.valueCases", len(values) > 0, "no value cases")
    for case in values:
        tag = f"stripMerge.value[{case['name']}]"
        try:
            original = case["original"]
            s = strip_notation_text(original, _strip_case_options(case))
            e = _apply_case_edits(s.text, case.get("edits"))
            got = merge_stripped_value(original, s.text, e, s.pieces).to_json()
        except Exception as ex:  # noqa: BLE001
            _check(tag, False, f"raised {ex!r}")
            continue
        _check(tag, got == case["expect"], _json_mismatch(got, case["expect"]))
    documents = table["documentCases"]
    _check("stripMerge.documentCases", len(documents) > 0, "no document cases")
    for case in documents:
        tag = f"stripMerge.document[{case['name']}]"
        try:
            state = _state_document(case["state"])
            src = case.get("source")
            readable = SpecDocumentStrip.strip(
                state,
                _strip_case_options(case),
                model=model,
                schema=schema,
                source=None if src is None else SpecReadableSource(
                    src["file"],
                    src.get("revision"),
                    src.get("commit"),
                    src.get("dirty") is True,
                ),
            ).readable
            edited = _apply_case_edits(readable, case.get("edits"))
            commits = case.get("commits") or {}

            def load_base(source, commits=commits):
                if source.commit is not None and commits.get(source.commit) is not None:
                    return _state_document(commits[source.commit])
                return None

            try:
                r = SpecStripMerge.merge(
                    state if case.get("current") is None
                    else _state_document(case["current"]),
                    edited,
                    model=model,
                    schema=schema,
                    options=None if case.get("options") is None
                    else _strip_case_options(case["options"]),
                    current_revision=case.get("currentRevision"),
                    base=None if case.get("base") is None
                    else _state_document(case["base"]),
                    load_base=load_base,
                )
                got = {
                    "exitCode": r.exit_code,
                    "stale": r.stale,
                    "document": None if r.document is None else r.document.to_json(),
                    "report": r.report,
                }
            except SpecStripUsageError as ex:
                got = {"error": str(ex)}
        except Exception as ex:  # noqa: BLE001
            _check(tag, False, f"raised {ex!r}")
            continue
        _check(tag, got == case["expect"], _json_mismatch(got, case["expect"]))


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
                       api: SpecReviewAnnotations, op: dict, team: bool = False):
    kind = op["op"]
    if kind == "list":
        return [a.to_json(team=team) for a in api.list()]
    if kind == "counts":
        return api.counts().to_json(team=team)
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
            at=op.get("at"),
        )
    if kind == "insertQuestion":
        api.insert_question(
            path=op["path"],
            field=op.get("field"),
            after_paragraph=op["afterParagraph"],
            question=SpecQuestionDraft.from_json(op["question"]),
            at=op.get("at"),
        )
        return None
    if kind == "insertQuestionAfterComment":
        api.insert_question_after_comment(
            op["commentId"], SpecQuestionDraft.from_json(op["question"]), at=op.get("at"))
        return None
    if kind == "setAnswer":
        api.set_answer(op["id"], op["answer"], author=op.get("author"), at=op.get("at"))
        return None
    if kind == "editComment":
        api.edit_comment(op["id"], op["text"], at=op.get("at"))
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
    if kind == "paragraphs":
        return [p.to_json() for p in api.paragraphs(op["path"], field=op.get("field"))]
    if kind == "listMarks":
        return [m.to_json(team=team) for m in api.list_marks(path=op.get("path"))]
    if kind == "decideMarks":
        rev = op["revision"]
        return api.decide_marks(
            {k: SpecMarkDecision(v) for k, v in op["decisions"].items()},
            revision=api.revision() if rev == "@current" else rev,
        ).to_json(team=team)
    if kind == "acceptAll":
        return api.accept_all_marks(path=op.get("path")).to_json(team=team)
    if kind == "rejectAll":
        return api.reject_all_marks(path=op.get("path")).to_json(team=team)
    if kind == "removeAll":
        return api.remove_all_annotations().to_json(team=team)
    if kind == "commentChange":
        rev = op.get("revision")
        return api.comment_change(
            op["id"],
            op["text"],
            author=op.get("author"),
            revision=api.revision() if rev == "@current" else rev,
            at=op.get("at"),
        )
    if kind == "editMarkComment":
        rev = op.get("revision")
        api.edit_mark_comment(
            op["id"],
            op["text"],
            revision=api.revision() if rev == "@current" else rev,
            at=op.get("at"),
        )
        return None
    if kind == "setMarked":
        return api.set_marked(
            op["path"], op["text"], field=op.get("field"),
            author=op.get("author"), at=op.get("at")).to_json()
    if kind == "markAgainst":
        return api.mark_against(
            op["path"], op["earlier"], field=op.get("field"),
            author=op.get("author"), at=op.get("at")).to_json()
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
    # The instance tier's findings as `{path, code}`: a marked typed value is
    # read as its old value (SOM §11.9.3).
    if kind == "validate":
        return [{"path": e.path, "code": e.code.value} for e in validate_document(model, doc)]
    # The typed reading of one value, as the typed accessors read it.
    if kind == "typedRead":
        return _typed_read(model, doc, op)
    raise ValueError(f"unknown annotation op {kind}")


def _typed_read(model: SpecModel, doc: SpecDocument, op: dict):
    """The typed reading of the value at `path` / `field`: an enum by its
    name, `int`, `double`, `num` and `bool` as numbers and booleans, None when
    the text reads as nothing — with any inline mark rejected (its old
    value)."""
    p = op["path"]
    field = op.get("field")
    res = SpecReflection(model).resolve(p)
    spec = None
    if field is not None and res is not None and res.field is not None:
        spec = next((f for f in res.field.form_fields if f.name == field), None)
    raw = doc.content(p) if field is None else doc.form_field(p, field)
    res_field = res.field if res is not None else None
    type_ = som_scalar_base(
        spec.type if spec is not None else (res_field.type if res_field else None)
    )
    values = (
        spec.enum_values if spec is not None
        else (res_field.enum_values if res_field else [])
    )
    if values:
        return som_parse_enum_name(raw, values)
    if type_ == "int":
        return som_parse_int(raw)
    if type_ == "double":
        return som_parse_double(raw)
    if type_ == "num":
        return som_parse_num(raw)
    if type_ == "bool":
        return som_parse_bool(raw)
    return som_typed_reading(raw)


#: The change time every annotation write records in the conformance cases
#: (SOM §11.9.10) unless a case names its own ``now``.
_CORPUS_NOW = "2026-11-07T14:05+01:00"


def _run_annotation_case(model: SpecModel, tree, case: dict, team: bool = False) -> dict:
    """Runs one case: ``{results: [one per op], state: final state}``. An
    operation that fails answers ``{error: true}`` and changes nothing.
    *team* renders the results in the team form
    ``team_annotation_cases.json`` pins (SOM §11.9.8)."""
    doc = _document_from_state(json.loads(json.dumps(case["state"])))
    # A fixed clock, so a write's change time (SOM §11.9.10) is the same in
    # every runtime: the case's `now`, else the corpus default.
    now = case.get("now") or _CORPUS_NOW
    api = SpecReviewAnnotations(doc, qualifier=case.get("qualifier"), clock=lambda: now)
    results = []
    for op in case["ops"]:
        try:
            results.append(_run_annotation_op(model, tree, doc, api, op, team=team))
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


def test_team_annotations(model: SpecModel, tree) -> None:
    """``team_annotation_cases.json`` (SOM §11.9.8): the scripted cases run
    like ``annotation_cases.json`` with the results in their team form; the
    ``validationCases`` run like ``validation_cases.json`` over the corpus
    model."""
    table = _read_json("team_annotation_cases.json")
    for case in table["cases"]:
        got = _run_annotation_case(model, tree, case, team=True)
        _check(
            f"teamAnnotations[{case['name']}]",
            got == case["expect"],
            _json_mismatch(got, case["expect"]),
        )
    for case in table["validationCases"]:
        got = [
            {"path": e.path, "code": e.code.value}
            for e in validate_document(model, _document_from_state(case["state"]))
        ]
        _check(
            f"teamValidate[{case['name']}]",
            got == case["errors"],
            _json_mismatch(got, case["errors"]),
        )


def _load_som_model() -> SpecModel:
    """The real model, for the review-merge cases written against it."""
    meta = os.path.join(_PKG_ROOT, "..", "tom_som_dart_v0", "meta", "spec_model.meta.json")
    with open(meta, "r", encoding="utf-8") as fh:
        return SpecModel.from_json(json.load(fh))


def _run_review_merge_case(models: dict, case: dict) -> dict:
    """One ``review_merge_cases.json`` case: the merged document (its state,
    or the Markdown text) and the report; a refused merge answers
    ``{error: true}``."""
    o = case["options"]
    options = SpecReviewMergeOptions(
        team=tuple(SpecReviewMember.from_json(m) for m in o["team"]),
        date=o["date"],
        author=o["author"],
        question_prefix=o.get("questionPrefix") or "RQ",
        model=None if case["model"] is None else models[case["model"]],
    )

    def copy(x: dict, document):
        return SpecReviewedCopy(
            member_id=x["memberId"],
            display_name=x.get("displayName") or "",
            role=x.get("role") or "",
            document=document,
        )

    def load(state) -> SpecDocument:
        return _document_from_state(json.loads(json.dumps(state)))

    try:
        if case["format"] == "markdown":
            copies = [copy(x, x["document"]) for x in case["copies"]]
            r = merge_reviews(case["base"], copies, options)
            return {"merged": r.merged, "report": r.report.to_json()}
        r = merge_reviews(
            load(case["base"]), [copy(x, load(x["document"])) for x in case["copies"]], options
        )
        return {"merged": r.merged.to_json(), "report": r.report.to_json()}
    except SpecReviewMergeError:
        return {"error": True}


def test_review_merge(model: SpecModel) -> None:
    """``review_merge_cases.json``: merging reviewed copies (SOM §11.9.9),
    SOM documents and plain Markdown."""
    models = {"demo": model, "som": _load_som_model()}
    for case in _read_json("review_merge_cases.json")["cases"]:
        got = _run_review_merge_case(models, case)
        _check(
            f"reviewMerge[{case['name']}]",
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
    for c in table["changeCommentTextCases"]:
        name = f"change comments text[{c['name']}]"
        for accept, key in ((True, "accept"), (False, "reject")):
            got = decide_all_marks_text(c["text"], accept=accept)
            _check(f"{name}.{key}", got == c[key], f"got {got!r}, want {c[key]!r}")
        got = apply_inline_marks_text(c["text"], accept=True)
        _check(f"{name}.removed", got == c["removed"],
               f"got {got!r}, want {c['removed']!r}")
    # Typed values and headlines under review (SOM §11.9.3).
    _run_typed_mark_cases("typedInlineMark", model, tree, table["typedCases"])
    for case in table["cases"]:
        got = _run_annotation_case(model, tree, case)
        _check(
            f"marks[{case['name']}]",
            got == case["expect"],
            _json_mismatch(got, case["expect"]),
        )


def _run_typed_mark_cases(label: str, model: SpecModel, tree, cases) -> None:
    for case in cases:
        name = f"{label}[{case['name']}]"
        try:
            got = _run_annotation_case(model, tree, case)
            _check(name, _deep_equal(got, case["expect"]),
                   _json_mismatch(got, case["expect"]))
        except Exception as e:  # noqa: BLE001 - reported as a failed check
            _check(name, False, f"threw {e!r}")


def _deep_equal(a, b) -> bool:
    """JSON equality: ``True`` is not ``1`` and ``1`` equals ``1.0``, as the
    reference compares decoded JSON."""
    if isinstance(a, bool) or isinstance(b, bool):
        return isinstance(a, bool) and isinstance(b, bool) and a == b
    if isinstance(a, dict) and isinstance(b, dict):
        return a.keys() == b.keys() and all(_deep_equal(a[k], b[k]) for k in a)
    if isinstance(a, (list, tuple)) and isinstance(b, (list, tuple)):
        return len(a) == len(b) and all(_deep_equal(x, y) for x, y in zip(a, b))
    return a == b


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
    # Typed values and headlines written as marks (SOM §11.9.3).
    _run_typed_mark_cases("typedChangeMark", model, tree, table["typedCases"])
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
        want = _expect_for(case)
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
                    "units": e.units,
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
        _check(f"codespecs_gate[{name}]", got == _expect_for(case),
               _json_mismatch(got, _expect_for(case)))


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


def test_generation_units(model: SpecModel) -> None:
    """``generation_unit_cases.json``: the generation-unit register (SOM
    §11.2) — ``spec_generation_units``, ``mapping_for``, ``spec_default_units``
    and a section's ``units`` override, plus ``K_SPEC_STANDARD_EMITTERS``."""
    table = _read_json("generation_unit_cases.json")
    emitters = list(K_SPEC_STANDARD_EMITTERS)
    _check(
        "generationUnits.standardEmitters",
        emitters == table["standardEmitters"],
        _json_mismatch(emitters, table["standardEmitters"]),
    )
    areas = table["areas"]
    for case in table["cases"]:
        doc = _document_from_state(case["state"])
        units = spec_generation_units(model, doc)
        got = {
            "units": [
                {
                    "unitId": u.unit_id,
                    "kind": u.kind,
                    "path": u.path,
                    "mappings": [
                        {"area": m.area, "mapping": m.mapping}
                        for m in u.mappings
                    ],
                    "emitters": list(u.emitters),
                }
                for u in units
            ],
            "mappingFor": {
                u.unit_id: {a: u.mapping_for(a) for a in areas} for u in units
            },
            "defaultUnits": {a: spec_default_units(units, a) for a in areas},
            "sectionUnits": {p: doc.units(p) for p in case["sections"]},
        }
        expect = case["expect"]
        # Dict equality ignores key order; the corpus pins order, so compare
        # the serialised forms too.
        same = got == expect and json.dumps(got) == json.dumps(expect)
        _check(
            f"generationUnits[{case['name']}]",
            same,
            _json_mismatch(got, expect),
        )


def test_typed_values() -> None:
    """The canonical typed-value reading (``typed_value_cases.json``): each
    input read as int / double / num and written back by the formatter, and
    whether the text is readable for each type. A case without a ``num`` key
    is not checked for num."""
    table = _read_json("typed_value_cases.json")

    def read(parse, fmt, text):
        value = parse(text)
        return None if value is None else fmt(value)

    for case in table["cases"]:
        text = case["input"]
        got = {
            "input": text,
            "int": read(som_parse_int, som_format_int, text),
            "double": read(som_parse_double, som_format_double, text),
            "readable": {
                "int": som_typed_text_readable("int", text),
                "double": som_typed_text_readable("double", text),
                "num": som_typed_text_readable("num?", text),
            },
        }
        if "num" in case:
            got["num"] = read(som_parse_num, som_format_num, text)
        _check(f"typedValues[{json.dumps(text)}]", got == case,
               _json_mismatch(got, case))


def test_impact_walk() -> None:
    """``impact_walk_cases.json``: the impact walk of the change mode
    (``spec_impact_walk``), the project's level (``spec_impact_level``), the
    document files of a listing (``spec_impact_document_files``) and the
    Markdown table (``spec_impact_walk_markdown``)."""
    table = _read_json("impact_walk_cases.json")

    def folders(raw):
        if raw is None:
            return None
        return [SpecImpactFolder(path=f["path"], present=f["present"]) for f in raw]

    for case in table["cases"]:
        raw_model = case["model"]
        model = SpecModel.from_json(
            _read_json(raw_model) if isinstance(raw_model, str) else raw_model
        )
        documents = {}
        for type_, state in case["documents"].items():
            documents[type_] = _document_from_state(
                _read_json(state) if isinstance(state, str) else state
            )
        walk = spec_impact_walk(model, documents)
        level = spec_impact_level(
            model, walk, case["listing"], folders(case["tests"]),
            folders(case["code"]),
        )
        got = {
            "walk": [w.to_json() for w in walk],
            "level": level.to_json(),
            "documentFiles": spec_impact_document_files(case["listing"]),
            "markdown": spec_impact_walk_markdown(walk, level),
        }
        for key in ("walk", "level", "documentFiles", "markdown"):
            expect = case["expect"][key]
            detail = (
                _byte_diff(key, got[key], expect)
                if key == "markdown"
                else _json_mismatch(got[key], expect)
            )
            _check(f"impactWalk[{case['name']}].{key}", got[key] == expect, detail)


# ---------------------------------------------------------------------------
# The section-link readers (`link_reader_cases.json` over `links.meta.json`)
# ---------------------------------------------------------------------------


def _link_read_back(model: SpecModel) -> dict:
    """What the readers return for *model*, in canonical JSON: every class
    sync, every member link, every form-field qualifier, and the ``@SameAs``
    bindings per root. Classes by name, fields and form fields in declaration
    order (the Dart test's ``linkReadBack``)."""
    names = sorted(model.classes)
    refl = SpecReflection(model)
    classes = []
    fields = []
    form_fields = []
    for n in names:
        sync = model.classes[n].synced_with
        if sync is not None:
            classes.append({"class": n, "syncedWith": sync.to_json()})
    for n in names:
        for f in model.classes[n].fields:
            sync = f.synced_with
            summary = f.summary_of
            derived = f.derived_from
            extracts = f.extracts_links
            same_as = f.same_as
            if (
                sync is None and summary is None and derived is None
                and not extracts and same_as is None
            ):
                continue
            row: dict = {"class": n, "field": f.name}
            if sync is not None:
                row["syncedWith"] = sync.to_json()
            if summary is not None:
                row["summaryOf"] = summary.to_json()
            if derived is not None:
                row["derivedFrom"] = derived.to_json()
            if extracts:
                row["extractsLinks"] = [e.to_json() for e in extracts]
            if same_as is not None:
                row["sameAs"] = same_as.to_json()
            fields.append(row)
    for n in names:
        for f in model.classes[n].fields:
            for ff in f.form_fields:
                if ff.derived_from is None and ff.inverse_of is None and ff.summary_of is None:
                    continue
                row = {"class": n, "field": f.name, "formField": ff.name}
                if ff.derived_from is not None:
                    row["derivedFrom"] = ff.derived_from.to_json()
                if ff.inverse_of is not None:
                    row["inverseOf"] = ff.inverse_of.to_json()
                if ff.summary_of is not None:
                    row["summaryOf"] = ff.summary_of.to_json()
                form_fields.append(row)
    same_as_bindings = [
        b.to_json() for r in model.roots for b in spec_same_as_bindings(refl, r.type)
    ]
    return {
        "classes": classes,
        "fields": fields,
        "formFields": form_fields,
        "sameAsBindings": same_as_bindings,
        "classCount": len(model.classes),
    }


def _place_case(refl: SpecReflection, c: dict) -> dict:
    """One place case: the text parsed, then resolved under `anchor` when
    given."""
    place = SpecPlace.try_parse(c["text"])
    if place is None:
        return {"problem": SpecPlaceProblem.MALFORMED}
    if c.get("anchor") is None:
        return {"parsed": place.to_json()}
    try:
        return {"parsed": place.to_json(), "resolved": place.resolve(refl, c["anchor"]).to_json()}
    except SpecPlaceException as e:
        return {"parsed": place.to_json(), "problem": e.problem}


def _filter_case(refl: SpecReflection, c: dict) -> dict:
    """One filter case: the text parsed, resolved under `anchor` when given,
    and matched against `stored` when given."""
    f = SpecPlaceFilter.try_parse(c["text"])
    if f is None:
        return {"problem": SpecPlaceProblem.MALFORMED}
    out: dict = {"parsed": f.to_json()}
    if isinstance(c.get("stored"), list):
        out["matches"] = f.matches([str(v) for v in c["stored"]])
    if c.get("anchor") is not None:
        try:
            out["resolved"] = f.resolve(refl, c["anchor"]).to_json()
        except SpecPlaceException as e:
            out["problem"] = e.problem
    return out


def _reader_intent_holds(token: str, e: dict):
    """Whether the reader-case intent *token* holds in the expectation *e*
    (the Dart test's ``_readerIntentHolds``); an unknown token is ``None``."""
    def field_has(key):
        return any(key in r for r in e["fields"])

    def form_has(key):
        return any(key in r for r in e["formFields"])

    if token == "syncedWith":
        return len(e["classes"]) > 0
    if token == "syncRelationWhere":
        return any(any("where" in x for x in r["syncedWith"]["relations"]) for r in e["classes"])
    if token == "summaryOf":
        return field_has("summaryOf")
    if token == "summaryOfDocument":
        return any(r.get("summaryOf") is not None and "document" in r["summaryOf"]
                   for r in e["fields"])
    if token == "derivedFrom":
        return field_has("derivedFrom")
    if token == "extractsLinksRepeated":
        return any(len(r.get("extractsLinks") or []) > 1 for r in e["fields"])
    if token == "sameAs":
        return field_has("sameAs")
    if token == "formDerivedFrom":
        return form_has("derivedFrom")
    if token == "formInverseOf":
        return form_has("inverseOf")
    if token == "formSymmetric":
        return any(r.get("inverseOf") is not None and "@self" in (r["inverseOf"].get("fields") or [])
                   for r in e["formFields"])
    if token == "formSummaryOf":
        return form_has("summaryOf")
    if token == "sameAsHolder":
        return any("holder" in r for r in e["sameAsBindings"])
    if token == "loadsUnchanged":
        return (
            e["classCount"] > 0 and not e["classes"] and not e["fields"]
            and not e["formFields"] and not e["sameAsBindings"]
        )
    return None


def _link_tokens(e) -> set:
    """Every string a text case's expectation shows: kinds, problems, and
    ``matches`` / ``noMatch`` (the Dart test's ``_tokens``)."""
    out: set = set()

    def walk(v, key):
        if isinstance(v, list):
            for x in v:
                walk(x, None)
        elif isinstance(v, dict):
            for k, x in v.items():
                walk(x, k)
        elif key == "matches" and isinstance(v, bool):
            out.add("matches" if v else "noMatch")
        elif isinstance(v, str) and key in ("kind", "problem"):
            out.add(v)

    walk(e, None)
    return out


def test_link_readers() -> None:
    """``link_reader_cases.json``: the typed readers of the link annotations,
    the ``@SameAs`` holders, an older meta loading unchanged, the place
    grammar and the filter (Dart ``section_link_conformance_test.dart``,
    LRC3 / LRC4), then the reader spot checks (LR1–LR4) and ``countOf``
    reading the filter (CO1–CO2)."""
    meta = _read_json("links.meta.json")
    table = _read_json("link_reader_cases.json")
    for c in table["cases"]:
        name = f"links.reader[{c['name']}]"
        try:
            m = meta if c.get("model") == "links.meta.json" else c["meta"]
            got = _link_read_back(SpecModel.from_json(m))
            _check(name, _deep_equal(got, c["expect"]), _json_mismatch(got, c["expect"]))
        except Exception as e:  # noqa: BLE001 - reported as a failed check
            _check(name, False, f"threw {e!r}")
        for token in c["intent"]:
            holds = _reader_intent_holds(token, c["expect"])
            _check(
                f"links.reader.intent[{c['name']}: {token}]",
                holds is True,
                "unknown intent token" if holds is None else "does not hold",
            )
    model = SpecModel.from_json(meta)
    refl = SpecReflection(model)

    def run_text(kind: str, cases, run) -> None:
        for c in cases:
            name = f"links.{kind}[{c['name']}]"
            try:
                got = run(c)
                _check(name, _deep_equal(got, c["expect"]), _json_mismatch(got, c["expect"]))
            except Exception as e:  # noqa: BLE001 - reported as a failed check
                _check(name, False, f"threw {e!r}")
            shown = _link_tokens(c["expect"])
            for token in c["intent"]:
                _check(f"links.{kind}.intent[{c['name']}: {token}]", token in shown)

    run_text("place", table["textCases"]["places"], lambda c: _place_case(refl, c))
    run_text("filter", table["textCases"]["filters"], lambda c: _filter_case(refl, c))

    # LR1: the class sync is read with its relations.
    reqs = model.classes["Requirements"].synced_with
    _check(
        "links.LR1.sync",
        reqs is not None
        and reqs.document == "Detail"
        and reqs.detail_only == ["REQX"]
        and reqs.held_here == ["REQ.owner"]
        and len(reqs.relations) == 1
        and reqs.relations[0].relation == "subset",
    )
    crit = model.classes["Criteria"].synced_with
    _check(
        "links.LR1.where",
        crit is not None
        and len(crit.relations) == 1
        and crit.relations[0].where == "CRITE.kind=functional|quality",
    )
    _check("links.LR1.none", model.classes["Blueprint"].synced_with is None)

    # LR2: member links and the repeated @ExtractsLinks.
    req = model.classes["Requirement"]
    links = req.field_named("links").extracts_links
    _check("links.LR2.modes", [x.mode for x in links] == ["generate", "warn"])
    _check("links.LR2.set", links[0].set == {"LNK.linkType": "namedInText"})
    abstract = req.field_named("abstract").derived_from
    _check("links.LR2.copy", abstract is not None and abstract.kind == "copy")
    pre = req.field_named("prerequisites").derived_from
    _check("links.LR2.map", pre is not None and pre.map == {"PRE.ref": "LNK-REF.ref"})
    _check("links.LR2.noSummary", req.field_named("links").summary_of is None)

    # LR3: the form-field qualifiers.
    def ff(cls, field, name):
        return next(
            f for f in model.classes[cls].field_named(field).form_fields if f.name == name
        )

    conflicts = ff("Requirement", "constraints", "conflictsWith").derived_from
    _check("links.LR3.where",
           conflicts is not None and conflicts.where == "LNK.linkType=conflict")
    sym = ff("Link", "ref", "ref").inverse_of
    _check("links.LR3.symmetric", sym is not None and sym.symmetric is True)
    nsym = ff("Requirement", "trace", "relatedScreens").inverse_of
    _check("links.LR3.notSymmetric", nsym is not None and nsym.symmetric is False)
    focus = ff("Blueprint", "focus", "focusScreens").summary_of
    _check("links.LR3.summaryDocument", focus is not None and focus.document == "Screens")

    # LR4: the real model — S1 has one holder in each document.
    real_refl = SpecReflection(_load_som_model())
    for root in ("D00SolutionBlueprint", "D10QualityAcceptancePlan"):
        bindings = spec_same_as_bindings(real_refl, root)
        _check(
            f"links.LR4[{root}]",
            len(bindings) == 1
            and bindings[0].class_name == "AcceptanceCriteriaList"
            and bindings[0].problem is None
            and bindings[0].copy_path.endswith("/detailedCriteria"),
            json.dumps([b.to_json() for b in bindings]),
        )

    # CO1–CO2: countOf reads the filter, `|` included.
    base = "BLU/requirements"

    def doc(settled: str, total: str = "3") -> SpecDocument:
        d = SpecDocument()
        for status in ("approved", "done", "draft"):
            item = d.add_list_item(f"{base}/REQ-ITEM-LST")
            d.set_form_field(f"{item}/content", "status", status)
        d.set_form_field(f"{base}/REQS-SUM", "total", total)
        d.set_form_field(f"{base}/REQS-SUM", "settled", settled)
        return d

    def counts(d: SpecDocument) -> list:
        return [
            e.path for e in validate_document(model, d)
            if e.code == SpecValidationCode.COUNT_MISMATCH
        ]

    def co(name: str, got, want) -> None:
        _check(name, got == want, _json_mismatch(got, want))

    co("links.CO1", counts(doc("2")), [])
    co("links.CO2.settled", counts(doc("3")), [f"{base}/REQS-SUM"])
    co("links.CO2.total", counts(doc("2", "2")), [f"{base}/REQS-SUM"])


def test_link_validation() -> None:
    """``link_validation_cases.json``: each case's state loaded, then
    ``validate_links`` (``errors``) and the instance tier
    (``instanceErrors``), every finding as ``{path, code}`` (Dart
    ``section_link_conformance_test.dart``, LVC2); every case shows its intent
    (LVC3); every link code has a provoking case (LVC4)."""
    table = _read_json("link_validation_cases.json")
    model = SpecModel.from_json(_read_json(table.get("model") or "links.meta.json"))

    def pairs(errors) -> list:
        return [{"path": e.path, "code": e.code.value} for e in errors]

    provoked: set = set()
    for c in table["cases"]:
        name = f"links.validate[{c['name']}]"
        for e in c["errors"]:
            provoked.add(e["code"])
        try:
            d = _document_from_state(json.loads(json.dumps(c["state"])))
            errors = pairs(validate_links(model, d))
            _check(f"{name}.errors", errors == c["errors"], _json_mismatch(errors, c["errors"]))
            instance = pairs(validate_document(model, d))
            _check(
                f"{name}.instanceErrors",
                instance == c["instanceErrors"],
                _json_mismatch(instance, c["instanceErrors"]),
            )
        except Exception as e:  # noqa: BLE001 - reported as a failed check
            _check(name, False, f"threw {e!r}")
        codes = {e["code"] for e in c["errors"] + c["instanceErrors"]}
        for token in c["intent"]:
            _check(
                f"links.validate.intent[{c['name']}: {token}]",
                len(codes) == 0 if token == "clean" else token in codes,
            )
    for code in (
        SpecValidationCode.DERIVED_VALUE_MISMATCH,
        SpecValidationCode.DERIVED_LOOKUP_MISS,
        SpecValidationCode.DUPLICATE_LINK_ROW,
        SpecValidationCode.INVERSE_MISSING,
        SpecValidationCode.EXTRACTED_LINK_MISSING,
        SpecValidationCode.EXTRACTED_LINK_STALE,
        SpecValidationCode.SUMMARY_NOT_IN_DETAIL,
        SpecValidationCode.DETAIL_NOT_IN_SUMMARY,
        SpecValidationCode.SUMMARY_DUPLICATE,
        SpecValidationCode.SAME_AS_MISMATCH,
        SpecValidationCode.LINK_VALUE_PENDING,
    ):
        _check(f"links.validate.provoked[{code.value}]", code.value in provoked)


# ---------------------------------------------------------------------------
# The document set (`document_set_cases.json` over `links.meta.json`)
# ---------------------------------------------------------------------------


def _set_documents(entries) -> list:
    """The documents of a case, ``[[name, state], ...]``, as stores."""
    return [(e[0], _document_from_state(json.loads(json.dumps(e[1])))) for e in entries]


def _set_construction_case(model: SpecModel, c: dict) -> dict:
    """One construction case: the set built (from fragments when
    ``fragments``), answered as its pairs and roots, or the refusal."""
    docs = _set_documents(c["documents"])
    try:
        if c.get("fragments") is True:
            s = SpecDocumentSet.from_fragments(model, docs)
        else:
            s = SpecDocumentSet(model, docs)
        return {
            "blueprintRoot": s.blueprint_root,
            "names": s.names,
            "roots": s.roots,
            "missingRoots": s.missing_roots,
            "pairs": [p.to_json() for p in s.pairs],
        }
    except SpecDocumentSetError as e:
        return {"refused": e.to_json()}


_SOM_MODEL_CACHE: list = []


def _som_model() -> SpecModel:
    """The real model, loaded once (11 MB)."""
    if not _SOM_MODEL_CACHE:
        _SOM_MODEL_CACHE.append(_load_som_model())
    return _SOM_MODEL_CACHE[0]


def _set_model_of(fixture: SpecModel, c: dict) -> SpecModel:
    """The model a case runs against: an inline one, the real one, or the
    fixture."""
    if isinstance(c.get("inline"), dict):
        return SpecModel.from_json(c["inline"])
    return _som_model() if c.get("model") == "som" else fixture


def _set_report_case(fixture: SpecModel, c: dict) -> dict:
    """One report case: ``sync_report`` over the documents, optionally
    scoped."""
    s = SpecDocumentSet(_set_model_of(fixture, c), _set_documents(c["documents"]))
    pairs = c["pairs"] if isinstance(c.get("pairs"), list) else None
    return sync_report(s, pairs=pairs).to_json()


def _set_rename_case(model: SpecModel, c: dict) -> dict:
    """One rename case: ``rename_id``, answered as its changes and the report
    after it, or the documents that refused it."""
    s = SpecDocumentSet(model, _set_documents(c["documents"]))
    try:
        changes = rename_id(s, c["from"], c["to"])
    except SpecRenameError as e:
        return {"refused": e.documents}
    after = sync_report(s)
    return {
        "changes": [x.to_json() for x in changes],
        "cleanAfter": after.clean,
        "findingsAfter": len([f for f in after.findings if not f.is_info]),
    }


def _set_tokens(e: dict) -> set:
    """Every token a document-set expectation shows (the Dart test's
    ``_setTokens``)."""
    out: set = set()
    refused = e.get("refused")
    if isinstance(refused, dict):
        out.add(refused["refusal"])
    if isinstance(refused, list):
        out.add("refused")
    if e.get("pairs") is not None and refused is None:
        out.add("built")
        if len(e["missingRoots"]) > 0:
            out.add("missingRoots")
    if e.get("findings") is not None:
        if e.get("clean") is True:
            out.add("clean")
        if len(e["notStarted"]) > 0:
            out.add("notStarted")
        if len(e["notStartedPairs"]) > 0:
            out.add("notStartedPairs")
        for f in e["findings"]:
            out.add(f["code"])
            out.add(f["resolution"])
        for d in e["documentFindings"]:
            for x in d[1]:
                out.add(x["code"])
    if e.get("changes") is not None and len(e["changes"]) > 0:
        out.add("renamed")
    return out


def test_document_set() -> None:
    """``document_set_cases.json``: construction, reports and renames
    reproduced from their inputs, compared as JSON (Dart
    ``section_link_conformance_test.dart``, group ``document set``, DSC2);
    every case shows its intent (DSC3); the real model pairs every synced
    class (DSC4)."""
    table = _read_json("document_set_cases.json")
    fixture = SpecModel.from_json(_read_json(table.get("model") or "links.meta.json"))

    def run(group: str, f) -> None:
        for c in table[group]:
            name = f"set.{group}[{c['name']}]"
            try:
                got = json.loads(json.dumps(f(c)))
                _check(name, _deep_equal(got, c["expect"]), _json_mismatch(got, c["expect"]))
            except Exception as e:  # noqa: BLE001 - reported as a failed check
                _check(name, False, f"threw {e!r}")
            shown = _set_tokens(c["expect"])
            for token in c["intent"]:
                _check(f"set.{group}.intent[{c['name']}: {token}]", token in shown)

    run(
        "construction",
        lambda c: _set_construction_case(
            fixture if c.get("meta") is None else SpecModel.from_json(c["meta"]), c
        ),
    )
    run("reports", lambda c: _set_report_case(fixture, c))
    run("renames", lambda c: _set_rename_case(fixture, c))

    # DSC4: the real model pairs every synced class.
    real = SpecDocumentSet(_som_model())
    _check(
        "set.DSC4.blueprintRoot",
        real.blueprint_root == "D00SolutionBlueprint",
        str(real.blueprint_root),
    )
    _check("set.DSC4.pairs", len(real.pairs) == 132, str(len(real.pairs)))


# ---------------------------------------------------------------------------
# derive_fields (`derive_cases.json` over `links.meta.json`)
# ---------------------------------------------------------------------------


def _derive_case(model: SpecModel, c: dict) -> dict:
    """One derive case: ``derive_fields`` run twice on the case's document
    (the second run shows idempotence), each as its result, then the findings
    of both tiers on the document after it, and the given document after both
    runs (unchanged on a dry run). The Dart test's ``deriveCase``."""
    doc = _document_from_state(json.loads(json.dumps(c["state"])))

    def run():
        return derive_fields(
            model,
            doc,
            marked=c["marked"] if c.get("marked") is not None else True,
            author=c.get("author"),
            at=c.get("at"),
            dry_run=bool(c.get("dryRun") or False),
        )

    first = run()
    second = run()

    def pairs(errors) -> list:
        return [{"path": e.path, "code": e.code.value} for e in errors]

    return {
        "first": first.to_json(),
        "second": second.to_json(),
        "findingsAfter": pairs(
            validate_links(model, second.document) + validate_document(model, second.document)
        ),
        "given": doc.to_json(),
    }


def _derive_intent_holds(token: str, c: dict):
    """Whether the derive-case intent *token* holds (the Dart test's
    ``_deriveIntentHolds``); an unknown token is ``None``."""
    e = c["expect"]
    changes = e["first"]["changes"]

    def unresolved(code: str) -> bool:
        return any(u["code"] == code for u in e["first"]["unresolved"])

    if token == "nothing":
        return len(changes) == 0
    if token in ("step1", "step2", "step3"):
        return any(x["step"] == int(token[4:]) for x in changes)
    if token in ("rowAdded", "rowRemoved"):
        return any(x["kind"] == token for x in changes)
    if token == "marked":
        return any("{" in x["new"] for x in changes)
    if token == "clean":
        return len(e["findingsAfter"]) == 0
    if token == "idempotent":
        return len(e["second"]["changes"]) == 0 and _deep_equal(
            e["second"]["document"], e["first"]["document"]
        )
    if token == "unchanged":
        return _deep_equal(e["given"], c["state"])
    if token in ("unmarkable", "derivedLookupMiss"):
        return unresolved(token)
    return None


def test_derive_fields() -> None:
    """``derive_cases.json``: every case reproduced from its inputs (Dart
    ``section_link_conformance_test.dart``, DRC2) and showing its intent
    (DRC3)."""
    table = _read_json("derive_cases.json")
    model = SpecModel.from_json(_read_json(table.get("model") or "links.meta.json"))
    for c in table["cases"]:
        name = f"derive[{c['name']}]"
        try:
            got = json.loads(json.dumps(_derive_case(model, c)))
            _check(name, _deep_equal(got, c["expect"]), _json_mismatch(got, c["expect"]))
        except Exception as e:  # noqa: BLE001 - reported as a failed check
            _check(name, False, f"threw {e!r}")
        for token in c["intent"]:
            holds = _derive_intent_holds(token, c)
            _check(
                f"derive.intent[{c['name']}: {token}]",
                holds is True,
                "unknown intent token" if holds is None else "does not hold",
            )


# ---------------------------------------------------------------------------
# prefill and backfill (`prefill_cases.json`, `backfill_cases.json`)
# ---------------------------------------------------------------------------


def _prefill_case(model: SpecModel, c: dict) -> dict:
    """One prefill case: ``prefill`` run twice for the case's root (the
    second run writes nothing), or its refusal; then the set's report after
    it. The Dart test's ``prefillCase``."""
    s = SpecDocumentSet(model, _set_documents(c["documents"]))
    pairs = c["pairs"] if isinstance(c.get("pairs"), list) else None

    def run() -> dict:
        try:
            return prefill(s, c["root"], name=c.get("name_"), pairs=pairs).to_json()
        except SpecPrefillError as e:
            return {"refused": e.code}

    first = run()
    second = run()
    after = sync_report(s)
    return {
        "first": first,
        "second": second,
        "reportAfter": {
            "countsByCode": [[k, v] for k, v in after.counts_by_code().items()],
            "notStartedPairs": after.not_started_pairs,
        },
    }


def _prefill_intent_holds(token: str, c: dict):
    """Whether the prefill-case intent *token* holds (the Dart test's
    ``_prefillIntentHolds``); an unknown token is ``None``."""
    e = c["expect"]
    first = e["first"]
    second = e["second"]
    if token == "created":
        return first.get("created") is True
    if token == "filled":
        return len(first.get("filledPairs") or []) > 0
    if token == "skipped":
        return len(first.get("skippedPairs") or []) > 0
    if token == "derived":
        return len(((first.get("derived") or {}).get("changes")) or []) > 0
    if token == "idempotent":
        return (
            len(second["filledPairs"]) == 0
            and len(second["derived"]["changes"]) == 0
            and _deep_equal(second["document"], first["document"])
        )
    if token == "agrees":
        return all(not str(x[0]).startswith("shared") for x in e["reportAfter"]["countsByCode"])
    if token in ("noBlueprint", "unknownRoot"):
        return first.get("refused") == token
    return None


def _backfill_case(fixture: SpecModel, c: dict) -> dict:
    """One backfill case: ``backfill`` run twice on the case's set (the
    second run shows idempotence), or its refusal; then the set's report
    after it, and the documents as the set holds them after both runs. The
    Dart test's ``backfillCase``."""
    s = SpecDocumentSet(_set_model_of(fixture, c), _set_documents(c["documents"]))
    pairs = c["pairs"] if isinstance(c.get("pairs"), list) else None

    def run() -> dict:
        try:
            return backfill(
                s,
                pairs=pairs,
                path=c.get("path"),
                dry_run=bool(c.get("dryRun") or False),
                author=c.get("author"),
                date=c.get("date"),
            ).to_json()
        except SpecBackfillError as e:
            return {"refused": e.to_json()}

    first = run()
    second = run()
    after = sync_report(s)
    return {
        "first": first,
        "second": second,
        "reportAfter": {
            "countsByCode": [[k, v] for k, v in after.counts_by_code().items()],
            "clean": after.clean,
        },
        "given": [[n, s.get(n).to_json()] for n in s.names],
    }


def _backfill_intent_holds(token: str, c: dict):
    """Whether the backfill-case intent *token* holds (the Dart test's
    ``_backfillIntentHolds``); an unknown token is ``None``."""
    e = c["expect"]
    first = e["first"]
    second = e["second"]
    changes = first.get("changes") or []
    left = first.get("left") or []
    if token == "nothing":
        return first.get("refused") is None and len(changes) == 0
    if token in ("value", "elementAdded", "elementRemoved", "revision", "derived"):
        return any(x["kind"] == token for x in changes)
    if token in ("heldHere", "mayBeAdded", "agent"):
        return any(x["reason"] == token for x in left)
    if token == "setHasMarks":
        refused = first.get("refused")
        return (
            isinstance(refused, dict)
            and refused.get("code") == "setHasMarks"
            and len(refused["places"]) > 0
        )
    if token == "idempotent":
        return len(second["changes"]) == 0
    if token == "unchanged":
        return _deep_equal(e["given"], c["documents"])
    if token == "cleanAfter":
        return e["reportAfter"]["clean"] is True
    return None


def test_prefill_backfill() -> None:
    """``prefill_cases.json`` and ``backfill_cases.json``: every case
    reproduced from its inputs, compared as JSON (Dart
    ``section_link_conformance_test.dart``, PFC2 / BFC2) and showing its
    intent (PFC3 / BFC3)."""
    groups = (
        ("prefill", "prefill_cases.json", _prefill_case, _prefill_intent_holds),
        ("backfill", "backfill_cases.json", _backfill_case, _backfill_intent_holds),
    )
    for label, file, kase, holds in groups:
        table = _read_json(file)
        model = SpecModel.from_json(_read_json(table.get("model") or "links.meta.json"))
        for c in table["cases"]:
            name = f"{label}[{c['name']}]"
            try:
                got = json.loads(json.dumps(kase(model, c)))
                _check(name, _deep_equal(got, c["expect"]), _json_mismatch(got, c["expect"]))
            except Exception as e:  # noqa: BLE001 - reported as a failed check
                _check(name, False, f"threw {e!r}")
            for token in c["intent"]:
                h = holds(token, c)
                _check(
                    f"{label}.intent[{c['name']}: {token}]",
                    h is True,
                    "unknown intent token" if h is None else "does not hold",
                )


# ---------------------------------------------------------------------------
# The rendition's navigation and generated parts (``link_rendition_cases.json``,
# SOM §11.2, §11.11, §11.12): each case's document rendered with file stem
# ``links``, the rendition (its markers deleted or edited where the case says)
# handed to the parser, and the rendition of what it staged.
# ---------------------------------------------------------------------------


def _rendition(
    model: SpecModel, doc: SpecDocument, markers: bool = True, generated: bool = True
) -> str:
    """*doc* rendered as its root's rendition."""
    root = next(
        (
            r
            for r in model.roots
            if doc.has_values_under(r.section_id if r.section_id is not None else r.type)
        ),
        None,
    )
    if root is None:
        raise RuntimeError("no root holds a value")
    return SpecDocumentMarkdown(
        model,
        doc,
        "links",
        linked_markers=markers,
        generated_parts=generated,
    ).export_root(root)


_MARKER_LINE = re.compile(r"^\[.*\]\{\.linked\}$")


def _without_markers(markdown: str) -> str:
    """*markdown* with its ``linked`` marker paragraphs removed."""
    lines = markdown.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        if _MARKER_LINE.search(lines[i]) is not None:
            if i + 1 < len(lines) and lines[i + 1] == "":
                i += 1
            i += 1
            continue
        out.append(lines[i])
        i += 1
    return "\n".join(out)


def _rendition_case(fixture: SpecModel, c: dict) -> dict:
    """One rendition case, as the Dart test's ``renditionCase`` computes
    it."""
    model = _set_model_of(fixture, c)
    doc = SpecDocument()
    doc.load_json(c["state"])
    markers = c.get("linkedMarkers", True) is not False
    generated = c.get("generatedParts", True) is not False
    markdown = _rendition(model, doc, markers, generated)
    given = markdown
    if c.get("dropMarkers") is True:
        given = _without_markers(given)
    for frm, to in c.get("edits") or []:
        if frm not in given:
            raise RuntimeError(f'{c["name"]}: the rendition has no "{frm}"')
        given = given.replace(frm, to, 1)
    parsed = SpecDocument.from_markdown(given, model)
    out: dict = {"markdown": markdown}
    if given != markdown:
        out["given"] = given
    out["rejections"] = [r.reason.value for r in parsed.result.rejections]
    out["parseMatches"] = json.dumps(parsed.document.to_json()) == json.dumps(
        doc.to_json()
    )
    out["reemitMatches"] = (
        _rendition(model, parsed.document, markers, generated) == markdown
    )
    return out


def _rendition_intent_holds(token: str, c: dict):
    """Whether the rendition-case intent *token* holds in case *c* (the Dart
    test's ``_renditionIntentHolds``); an unknown token is ``None``."""
    e = c["expect"]
    md = e["markdown"]
    parsed = e.get("parseMatches") is True
    reemit = e.get("reemitMatches") is True
    edited = e.get("given") is not None
    given = e["given"] if edited else ""
    if token == "alsoInHeldThere":
        return re.search(r"\[Also in \[[^\]]+\]\([^)]+\), held there", md) is not None
    if token == "alsoInHeldHere":
        return re.search(r"\[Also in \[[^\]]+\]\([^)]+\), held here", md) is not None
    if token == "heldException":
        return " except REQ.owner" in md
    if token == "summaryOf":
        return (
            "held there except REQ.owner; Summary of [REQ-EXPORT](#REQ-EXPORT)]{.linked}"
            in md
        )
    if token == "summarisedIn":
        return "Summarised in [KEY-1](#KEY-1)" in md
    if token == "derivedTwoFields":
        return (
            re.search(r"Derived from (\[[^\]]+\]\([^)]+\)(,)?)+: \w+, \w+", md, re.ASCII)
            is not None
        )
    if token == "extractedFrom":
        return "[Extracted from [REQD](#REQ-EXPORT/REQD)]{.linked}" in md
    if token == "copyOf":
        return "[Copy of [CRIT](#CRIT), edit it there]{.linked}" in md
    if token == "copiedTo":
        return "Copied to [CRIT](#CSUM/CRIT)" in md
    if token == "copyAnchors":
        return '<a id="CSUM/CRIT/CRIT-SPEED"></a>' in md
    if token == "qualifiedThree":
        return (
            re.search(
                r'^#+ <!--\[LNK-REF\]--> <a id="REQ-EXPORT/LNK-1/LNK-REF"></a> ',
                md,
                re.M,
            )
            is not None
        )
    if token == "markerRestored":
        return edited and "{.linked}" not in given and parsed and reemit
    if token == "handEditDiscarded":
        return edited and "Copy of [X]" in given and parsed and reemit
    if token == "emptyMarker":
        return "[]{.linked}\n\n[To be chosen" in md and parsed
    if token == "spanKept":
        return "{.linked}" in json.dumps(c["state"]) and parsed
    if token == "dangling":
        return (
            "[Also in [BLU REQ-PRESETS](links.blu.tomspecs.md#REQ-PRESETS), held here"
            in md
        )
    if token == "generatedTrace":
        return (
            "::: {.derived label=\"Generated from each requirement's traceability; "
            "edit it there\"}\n| Requirement | Use cases | Screens | Data entities | "
            "Tests |"
        ) in md
    if token == "generatedCoverage":
        return (
            re.search(
                r"\| Requirement \| Covered \| By \|\n\| --- \| --- \| --- \|\n"
                r"\| \[FRE-REQU-TENANT-LIFECYCLE\]\(#FRE-REQU-TENANT-LIFECYCLE\) "
                r"\| (yes|no) \|",
                md,
            )
            is not None
        )
    if token == "generatedRelationships":
        return "| Requirement | Dependency | Related requirement |" in md
    if token == "generatedFirst":
        return (
            re.search(
                r'^## <!--\[REQCOV\]--> <a id="REQCOV"></a> [^\n]*\n\n'
                r"(\[[^\n]*\]\{\.linked\}\n\n)?::: \{\.derived ",
                md,
                re.M,
            )
            is not None
        )
    if token == "generatedOverview":
        return "<!--[RO-TRAC]-->" in md and "| Requirement | Use cases | Screens |" in md
    if token == "generatedUseCases":
        return (
            "| [INEN-INTE-UC-02](#INEN-INTE-UC-02) |  | [FRE-REQU-TENANT-FEATURES]("
            in md
        )
    if token == "generatedEditDiscarded":
        return edited and "| Requirement | Covered |\n" in given and parsed and reemit
    if token == "noGenerated":
        return "{.derived" not in md
    if token == "emptyGenerated":
        return "::: {.derived}\n:::\n\n::: {.derived}\nTraced by hand.\n:::" in md
    if token == "summaryRowLink":
        return (
            '| <a id="TOP-BETA"></a>[TOP-BETA](#TOP-BETA) |' in md
            and '| <a id="TOP-BETA"></a>TOP-BETA |' in md
        )
    if token == "noMarkers":
        return "{.linked}" not in md and '<a id="REQ-EXPORT/REQD"></a>' in md
    if token == "roundTrip":
        return not edited and parsed and reemit
    if token == "clean":
        return len(e["rejections"]) == 0
    return None


def test_link_rendition() -> None:
    """``link_rendition_cases.json``: each case's rendition, what the parser
    makes of it and the rendition of that, against the expectation, and its
    intent."""
    table = _read_json("link_rendition_cases.json")
    model = SpecModel.from_json(_read_json(table.get("model") or "links.meta.json"))
    for c in table["cases"]:
        name = f"links.rendition[{c['name']}]"
        try:
            got = json.loads(json.dumps(_rendition_case(model, c)))
            for k in ("markdown", "given", "rejections", "parseMatches", "reemitMatches"):
                _check(
                    f"{name}.{k}",
                    _deep_equal(got.get(k), c["expect"].get(k)),
                    _json_mismatch(got.get(k), c["expect"].get(k)),
                )
            _check(f"{name}.keys", sorted(got) == sorted(c["expect"]))
        except Exception as e:  # noqa: BLE001 - reported as a failed check
            _check(name, False, f"threw {e!r}")
        for token in c["intent"]:
            h = _rendition_intent_holds(token, c)
            _check(
                f"links.rendition.intent[{c['name']}: {token}]",
                h is True,
                "unknown intent token" if h is None else "does not hold",
            )


def test_rendition_schema_tier() -> None:
    """The schema tier finds nothing in the markers and generated parts (the
    Dart test's RNC5, real model): each document's findings with navigation
    equal its findings without."""
    cut = _read_json("uam_requirements_cut.json")
    rsp = SpecDocument()
    rsp.load_json(cut["rsp"])
    sbp = SpecDocument()
    sbp.load_json(cut["blueprint"])
    isc = SpecDocument()
    item = isc.add_list_item("ISC/interactionCatalog/INEN-INTE-LST", "INEN-INTE-UC-01")
    isc.set_form_field(f"{item}/INTR", "relatedRequirements", "FRE-REQU-TENANT-LIFECYCLE")
    som = _som_model()
    for doc, schema_name in (
        (rsp, "requirements-specification"),
        (sbp, "solution-blueprint"),
        (isc, "interaction-scenarios"),
    ):
        name = f"links.rendition.schemaTier[{schema_name}]"
        try:
            schema_file = os.path.join(
                _PKG_ROOT,
                "..",
                "tom_som_dart_v0",
                "schemas",
                schema_name,
                f"{schema_name}.1.0.docspecs-schema.yaml",
            )
            with open(schema_file, "r", encoding="utf-8") as fh:
                schema = DocSpecsSchema.from_yaml_text(fh.read())
            root = next(
                r
                for r in som.roots
                if doc.has_values_under(r.section_id if r.section_id is not None else r.type)
            )

            def findings(navigation: bool, doc=doc, root=root, schema=schema):
                md = SpecDocumentMarkdown(
                    som,
                    doc,
                    linked_markers=navigation,
                    generated_parts=navigation,
                ).export_root(root)
                return md, sorted(
                    f"{v.rule} {v.section_id}"
                    for v in DocSpecsValidator(schema, tom_specs=True).validate_markdown(md)
                )

            md, with_nav = findings(True)
            _, without = findings(False)
            _check(f"{name}.derived", "{.derived" in md)
            _check(name, _deep_equal(with_nav, without), _json_mismatch(with_nav, without))
        except Exception as e:  # noqa: BLE001 - reported as a failed check
            _check(name, False, f"threw {e!r}")


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
    test_notation()
    test_strip(model)
    test_strip_merge(model)
    test_docspecs_path(model)
    test_docspecs_replace()
    test_assembly()
    test_annotations(model, tree)
    test_team_annotations(model, tree)
    test_review_merge(model)
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
    test_generation_units(model)
    test_typed_values()
    test_impact_walk()
    test_link_readers()
    test_link_validation()
    test_derive_fields()
    test_document_set()
    test_prefill_backfill()
    test_link_rendition()
    test_rendition_schema_tier()

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
