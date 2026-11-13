#!/usr/bin/env python3
"""SOM §11.2 ``units``: the generation units a section goes to — a port of
``tom_som_dart_runtime/test/spec_units_test.dart`` (plus the units cases of
``spec_codespecs_extract_test.dart``).

Kept exactly as ``codeSpec`` is — a sparse store by section path, the Markdown
heading key ``units="a,b"`` after ``codeSpec``, the YAML key ``units`` after
``codeSpec``, the facade's ``spec_units``, the snapshot's ``units`` map — and
checked by the instance tier's phase 8.

The Dart cases on ``captureState`` / ``restoreState`` and the path normalizer
have no counterpart here: this port has neither API.

Run with: ``python3 tests/spec_units_test.py``. Exit code 0 == green.
"""

from __future__ import annotations

import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    CodeSpecsAreaCatalog,
    CodeSpecsExtractor,
    SomNode,
    SpecDocument,
    SpecDocumentMarkdown,
    SpecModel,
    SpecYamlFormatException,
    build_som_meta_tree,
    parse_code_specs_extract_yaml,
    spec_default_units,
    spec_generation_units,
    validate_document,
    yaml_encode,
)
from tom_som_runtime.spec_review_merge import (  # noqa: E402
    SpecReviewedCopy,
    SpecReviewMember,
    SpecReviewMergeOptions,
    merge_reviews,
)

_CORPUS = os.path.normpath(
    os.path.join(_PKG_ROOT, "..", "tom_som_conformance", "corpus")
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def _read_json(name: str) -> dict:
    with open(os.path.join(_CORPUS, name), "r", encoding="utf-8") as fh:
        return json.load(fh)


def _corpus_model() -> SpecModel:
    """The shared corpus model: the demo root with the generation-unit
    register ``DEMO/DLV-LST`` (``Deliverable``, ``DeliverableRoute``)."""
    return SpecModel.from_json(_read_json("model.meta.json"))


def _register() -> SpecDocument:
    """A register declaring ``u_a`` and ``u_b``, both building something."""
    d = SpecDocument()
    a = d.add_list_item("DEMO/DLV-LST")
    d.set_form_field(f"{a}/content", "unitId", "u_a")
    d.set_form_field(f"{a}/content", "component", "ARCM-COMP-A")
    b = d.add_list_item("DEMO/DLV-LST")
    d.set_form_field(f"{b}/content", "unitId", "u_b")
    d.set_form_field(f"{b}/content", "deploymentTarget", "DEPTAR-DEPL-B")
    return d


def _throws_format(fn, contains: str = "") -> bool:
    try:
        fn()
        return False
    except SpecYamlFormatException as e:
        return contains in e.message


# --- the store ---------------------------------------------------------------


def test_store() -> None:
    d = SpecDocument()
    _check("store.absent", d.units("DEMO/TTL") is None)
    d.set_units("DEMO/TTL", "u_a,u_b")
    _check("store.get", d.units("DEMO/TTL") == "u_a,u_b")
    _check("store.paths", list(d.units_paths) == ["DEMO/TTL"])
    _check("store.notEmpty", not d.is_empty)
    _check("store.hasValuesUnder", d.has_values_under("DEMO"))
    d.set_units("DEMO/TTL", "")
    _check("store.cleared", d.units("DEMO/TTL") is None)
    _check("store.pathsCleared", list(d.units_paths) == [])
    _check("store.empty", d.is_empty)


def test_snapshot() -> None:
    d = SpecDocument()
    d.set_code_spec("DEMO/TTL", "A")
    d.set_units("DEMO/TTL", "u_b")
    d.set_units("DEMO/SUM", "u_a")
    j = d.to_json()
    _check("snapshot.keys", list(j) == ["codeSpecs", "units"], str(list(j)))
    _check("snapshot.sorted", list(j["units"]) == ["DEMO/SUM", "DEMO/TTL"])
    back = SpecDocument()
    back.load_json(json.loads(json.dumps(j)))
    _check("snapshot.roundTrip", back.to_json() == j)
    _check("snapshot.noKey", "units" not in SpecDocument().to_json())


def test_remove_values_under() -> None:
    d = SpecDocument()
    d.set_units("DEMO/notes", "u_a")
    d.set_units("DEMO/notes/NOTE-BDY", "u_b")
    d.set_units("DEMO/TTL", "u_a")
    d.remove_values_under("DEMO/notes")
    _check("purge", list(d.units_paths) == ["DEMO/TTL"], str(list(d.units_paths)))


def test_move_list_item() -> None:
    model = _corpus_model()
    d = SpecDocument()
    first = d.add_list_item("DEMO/items")
    second = d.add_list_item("DEMO/items")
    d.set_content(f"{first}/label", "one")
    d.set_content(f"{second}/label", "two")
    d.set_units(second, "u_a")
    d.move_list_item(model, second, 0)
    _check("move.moved", d.units("DEMO/items-1") == "u_a")
    _check("move.left", d.units("DEMO/items-2") is None)


def test_facade() -> None:
    d = SpecDocument()
    node = SomNode(d, "DEMO/TTL")
    _check("facade.absent", node.spec_units is None)
    node.spec_units = "u_a"
    _check("facade.writes", d.units("DEMO/TTL") == "u_a")
    _check("facade.reads", node.spec_units == "u_a")
    node.spec_units = None
    _check("facade.noneClears", node.spec_units is None)
    node.spec_units = "u_b"
    node.spec_units = ""
    _check("facade.emptyClears", list(d.units_paths) == [])


# --- Markdown ----------------------------------------------------------------


def test_markdown_emit() -> None:
    model = _corpus_model()
    d = SpecDocument()
    d.set_content("DEMO/TTL", "Hello")
    d.set_code_spec("DEMO/TTL", "DemoTitle")
    d.set_units("DEMO/TTL", "u_a,u_b")
    d.set_content("DEMO/SUM", "Sum")
    d.set_units("DEMO/SUM", "u_a")
    md = d.to_markdown(model)
    _check(
        "md.emit.both",
        '## <!--[TTL] codeSpec="DemoTitle" units="u_a,u_b"--> Document Title\n'
        in md,
        md,
    )
    _check("md.emit.alone", '## <!--[SUM] units="u_a"--> Summary\n' in md, md)


def test_markdown_parse() -> None:
    model = _corpus_model()
    md = (
        "# <!--[DEMO] units=u_root--> Demo Document\n\n"
        '## <!--[TTL] codeSpec="DemoTitle" units="u_a,u_b"--> Title\n\n'
        "Hello\n\n"
        "## <!--[SUM] units='u_c'--> Summary\n\n"
        "Sum\n\n"
        '## <!--[CNT] codeSpec="units=no"--> Count\n\n'
        "3\n"
    )
    result = SpecDocumentMarkdown(model, SpecDocument()).parse(md)
    _check("md.parse.clean", not result.rejections, str(result.rejections))
    _check(
        "md.parse.units",
        result.units
        == {"DEMO": "u_root", "DEMO/TTL": "u_a,u_b", "DEMO/SUM": "u_c"},
        str(result.units),
    )
    _check("md.parse.codeSpec", result.code_specs.get("DEMO/TTL") == "DemoTitle")
    # A `units=` inside a quoted codeSpec value is not the key.
    _check(
        "md.parse.quotedNotKey",
        result.code_specs.get("DEMO/CNT") == "units=no",
        str(result.code_specs),
    )


def test_markdown_round_trip() -> None:
    model = _corpus_model()
    d = _register()
    d.set_content("DEMO/TTL", "Hello")
    d.set_code_spec("DEMO/TTL", "DemoTitle")
    d.set_units("DEMO/TTL", "u_a")
    d.set_content("DEMO/notes/NOTE-BDY", "Body")
    d.set_units("DEMO/notes", "u_a,u_b")
    md = d.to_markdown(model)
    back = SpecDocument.from_markdown(md, model).document
    _check("md.roundTrip.ttl", back.units("DEMO/TTL") == "u_a")
    _check("md.roundTrip.notes", back.units("DEMO/notes") == "u_a,u_b")
    _check("md.roundTrip.bytes", back.to_markdown(model) == md)


def test_apply_markdown_result() -> None:
    model = _corpus_model()
    d = SpecDocument()
    d.set_units("DEMO/TTL", "stale")
    d.set_units("DEMO/SUM", "stale")
    d.set_units("OTHER/kept", "kept")
    md = (
        "# <!--[DEMO]--> Demo Document\n\n"
        '## <!--[TTL] units="u_a"--> Document Title\n\nHello\n'
    )
    d.apply_markdown_result(SpecDocumentMarkdown(model, SpecDocument()).parse(md))
    _check(
        "md.apply",
        d.to_json().get("units") == {"DEMO/TTL": "u_a", "OTHER/kept": "kept"},
        str(d.to_json().get("units")),
    )


# --- YAML --------------------------------------------------------------------


def test_yaml_scalar_promotion() -> None:
    tree = build_som_meta_tree(_corpus_model())

    def enc(d: SpecDocument) -> str:
        return yaml_encode(d, tree, model_version="1.0")

    d = SpecDocument()
    d.set_content("DEMO/TTL", "Hello")
    d.set_headline("DEMO/TTL", "Title")
    d.set_code_spec("DEMO/TTL", "DemoTitle")
    d.set_units("DEMO/TTL", "u_a")
    d.set_content("DEMO/CNT", "3")
    d.set_units("DEMO/CNT", "u_b")
    d.set_content("DEMO/notes/NOTE-BDY", "Body")
    d.set_units("DEMO/notes", "u_a,u_b")
    y = enc(d)
    _check(
        "yaml.promotion",
        "    TTL title:\n"
        "      headline: |2-\n        Title\n"
        "      codeSpec: |2-\n        DemoTitle\n"
        "      units: |2-\n        u_a\n"
        "      content: |2-\n        Hello\n" in y,
        y,
    )
    # A non-text scalar keeps its plain content inside the mapping.
    _check(
        "yaml.promotion.plain",
        "    CNT count:\n      units: |2-\n        u_b\n      content: 3\n" in y,
        y,
    )
    _check(
        "yaml.section",
        "    NOTE notes:\n      units: |2-\n        u_a,u_b\n" in y,
        y,
    )
    back = SpecDocument.from_yaml(y, tree)
    _check("yaml.decode", back.to_json() == d.to_json())
    _check("yaml.reencode", enc(back) == y)


def test_yaml_form_list_item() -> None:
    tree = build_som_meta_tree(_corpus_model())

    def enc(d: SpecDocument) -> str:
        return yaml_encode(d, tree, model_version="1.0")

    d = _register()
    d.set_form_field("DEMO/DET", "owner", "Bob")
    d.set_units("DEMO/DET", "u_a")
    d.set_units("DEMO/DLV-LST", "u_b")
    d.set_units("DEMO/DLV-LST-1", "u_a")
    tag = d.add_list_item("DEMO/META/tags")
    d.set_content(tag, "on")
    d.set_units(tag, "u_b")
    y = enc(d)
    back = SpecDocument.from_yaml(y, tree)
    _check("yaml.formList.decode", back.to_json() == d.to_json(),
           f"{back.to_json()} != {d.to_json()}")
    _check("yaml.formList.reencode", enc(back) == y)


def test_yaml_collisions() -> None:
    clash = SpecModel.from_json(
        {
            "modelVersion": 1,
            "roots": [{"type": "R", "title": "R", "sectionId": "R"}],
            "classes": {
                "R": {
                    "name": "R",
                    "sectionId": "R",
                    "fields": [
                        {"name": "units", "kind": "content"},
                        {
                            "name": "shape",
                            "kind": "form",
                            "sectionId": "SHP",
                            "formFields": [
                                {"name": "units", "label": "Units",
                                 "type": "String"},
                            ],
                        },
                    ],
                },
            },
        }
    )
    clash_tree = build_som_meta_tree(clash)

    def encode(d: SpecDocument) -> str:
        return yaml_encode(d, clash_tree, model_version="1.0")

    d1 = SpecDocument()
    d1.set_units("R", "u_a")
    _check(
        "yaml.collision.child",
        _throws_format(lambda: encode(d1), "also serializes as key `units`"),
    )
    d2 = SpecDocument()
    d2.set_form_field("R/SHP", "units", "3")
    d2.set_units("R/SHP", "u_a")
    _check(
        "yaml.collision.formField",
        _throws_format(lambda: encode(d2), "field literally named `units`"),
    )
    tree = build_som_meta_tree(_corpus_model())
    d3 = SpecDocument()
    d3.add_list_item("DEMO/DLV-LST", section_id="units")
    _check(
        "yaml.collision.itemKey",
        _throws_format(lambda: yaml_encode(d3, tree, model_version="1.0")),
    )


# --- assembly and review merge ----------------------------------------------


def test_assembly() -> None:
    a = SpecDocument()
    a.set_units("DEMO/TTL", "u_a")
    b = SpecDocument()
    b.set_units("DEMO/SUM", "u_b")
    ok = SpecDocument.assemble({"a": a, "b": b})
    _check("assembly.ok", ok.ok)
    _check("assembly.merged",
           ok.document is not None and ok.document.units("DEMO/SUM") == "u_b")
    c = SpecDocument()
    c.set_units("DEMO/TTL", "u_b")
    clash = SpecDocument.assemble({"a": a, "c": c})
    _check("assembly.refused", not clash.ok)
    _check(
        "assembly.overlap",
        len(clash.overlaps) == 1
        and clash.overlaps[0].store == "units"
        and clash.overlaps[0].path == "DEMO/TTL",
        str(clash.overlaps),
    )


def test_review_merge() -> None:
    model = _corpus_model()
    base = SpecDocument()
    first = base.add_list_item("DEMO/items")
    base.set_content(f"{first}/label", "one")
    copy = SpecDocument()
    copy.load_json(base.to_json())
    added = copy.add_list_item("DEMO/items")
    copy.set_content(f"{added}/label", "two")
    copy.set_units(added, "u_a")
    member = SpecReviewMember(member_id="alice", display_name="Alice", role="")
    result = merge_reviews(
        base,
        [SpecReviewedCopy(member_id="alice", display_name="Alice", role="",
                          document=copy)],
        SpecReviewMergeOptions(
            team=(member,), date="2026-11-12", author="alice", model=model
        ),
    )
    merged = result.merged
    items = merged.list_items("DEMO/items")
    _check("merge.items", len(items) == 2, str(items))
    _check("merge.units", merged.units(items[-1]) == "u_a")


# --- validation phase 8 -----------------------------------------------------


def _findings(d: SpecDocument) -> list[tuple[str, str, str]]:
    return [
        (e.path, e.code.value, e.message)
        for e in validate_document(_corpus_model(), d)
    ]


def test_phase8_clean() -> None:
    d = _register()
    d.set_units("DEMO/TTL", "u_a")
    d.set_units("DEMO/REG", "u_a,u_b")
    _check("phase8.clean", _findings(d) == [], str(_findings(d)))


def test_phase8_unknown_unit() -> None:
    d = _register()
    d.set_units("DEMO/TTL", "u_x, u_a ,u_y")
    want = [
        ("DEMO/TTL", "unknownUnit",
         'units names "u_x", which no generation unit declares'),
        ("DEMO/TTL", "unknownUnit",
         'units names "u_y", which no generation unit declares'),
    ]
    _check("phase8.unknownUnit", _findings(d) == want, str(_findings(d)))


def test_phase8_unrouted() -> None:
    d = _register()
    d.set_units("DEMO/META", "u_a")
    d.set_units("DEMO/META/tags", "u_a")
    d.set_units("DEMO/control", "u_a")
    d.set_units("DEMO/DLV-LST-1", "u_a")
    # Routed: a field of a routed class, a list of a routed element.
    d.set_units("DEMO/PRI", "u_a")
    d.set_units("DEMO/CARD-LST", "u_a")
    message = "units is set on a section that routes nothing to CodeSpecs"
    want = [
        ("DEMO/DLV-LST-1", "unitsUnrouted", message),
        ("DEMO/META", "unitsUnrouted", message),
        ("DEMO/META/tags", "unitsUnrouted", message),
        ("DEMO/control", "unitsUnrouted", message),
    ]
    _check("phase8.unitsUnrouted", _findings(d) == want, str(_findings(d)))


def test_phase8_register() -> None:
    d = _register()
    dup = d.add_list_item("DEMO/DLV-LST")
    d.set_form_field(f"{dup}/content", "unitId", "u_a")
    d.set_form_field(f"{dup}/content", "kind", "server")
    # An item with no value at all is absence, not a finding.
    d.add_list_item("DEMO/DLV-LST")
    for area in ("CE-DB", "ce-db", "CE-", "CE-D1"):
        route = d.add_list_item("DEMO/DLV-LST-1/DLR-LST")
        d.set_form_field(f"{route}/content", "area", area)
        d.set_form_field(f"{route}/content", "mapping", "dart-tom")
    want = [
        ("DEMO/DLV-LST-1/DLR-LST-2", "unitAreaMalformed",
         'mapping area "ce-db" is not an area code (CE-…)'),
        ("DEMO/DLV-LST-1/DLR-LST-3", "unitAreaMalformed",
         'mapping area "CE-" is not an area code (CE-…)'),
        ("DEMO/DLV-LST-1/DLR-LST-4", "unitAreaMalformed",
         'mapping area "CE-D1" is not an area code (CE-…)'),
        ("DEMO/DLV-LST-3", "duplicateUnitId",
         'generation unit "u_a" is declared twice'),
        ("DEMO/DLV-LST-3", "unitBuildsNothing",
         'generation unit "u_a" builds neither a deploymentTarget nor a '
         "component"),
    ]
    _check("phase8.register", _findings(d) == want, str(_findings(d)))


def test_phase8_order() -> None:
    d = _register()
    d.set_units("DEMO/TTL", "u_x")
    d.set_content("DEMO/SUM", "> ⬆️ **C-1** a\n\n> ⬆️ **C-1** b")
    codes = [e[1] for e in _findings(d)]
    _check("phase8.order", codes == ["unknownUnit", "duplicateAnnotationId"],
           str(codes))


# --- the CodeSpecs extract --------------------------------------------------


def _extractor(d: SpecDocument) -> CodeSpecsExtractor:
    catalog = CodeSpecsAreaCatalog.from_json(
        _read_json("codespecs_extract_cases.json")["catalog"]
    )
    return CodeSpecsExtractor(model=_corpus_model(), document=d, catalog=catalog)


def _extract_document() -> SpecDocument:
    d = SpecDocument()
    d.set_content("DEMO/TTL", "Hello")
    d.set_content("DEMO/SUM", "Sum")
    item = d.add_list_item("DEMO/items")
    d.set_content(f"{item}/label", "First")
    return d


def test_extract_units_inherited() -> None:
    d = _extract_document()
    d.set_units("DEMO", "app_client")
    d.set_units("DEMO/SUM", "app_shared")
    d.set_units("DEMO/items", "app_server, app_shared")
    by_path = {
        e.path: e for x in _extractor(d).extract_all() for e in x.entries
    }
    # Inherited from the root.
    _check("extract.inherited",
           by_path["DEMO/TTL"].units == ["app_client"],
           str(by_path["DEMO/TTL"].units))
    # The entry's own path wins over every ancestor.
    _check("extract.own", by_path["DEMO/SUM"].units == ["app_shared"])
    # Through the list item from the nearest ancestor, split and trimmed.
    _check("extract.throughItem",
           by_path["DEMO/items-1/label"].units == ["app_server", "app_shared"],
           str(by_path["DEMO/items-1/label"].units))


def test_extract_no_units() -> None:
    entries = [e for x in _extractor(_extract_document()).extract_all()
               for e in x.entries]
    _check("extract.none.nonEmpty", bool(entries))
    _check("extract.none", all(not e.units for e in entries))


def test_extract_write_read() -> None:
    d = _extract_document()
    d.set_units("DEMO/TTL", "app_client,app_server")
    extract = next(
        x for x in _extractor(d).extract_all() if x.area.code == "CE-FM"
    )
    y = extract.to_yaml()
    _check(
        "extract.yaml",
        '      units: ["app_client", "app_server"]\n'
        '      value: "Hello"\n' in y,
        y,
    )
    _check("extract.yaml.once", y.count("units:") == 1, y)
    _check("extract.md",
           "- units: `app_client`, `app_server`\n" in extract.to_markdown())
    back = parse_code_specs_extract_yaml(y)
    _check(
        "extract.read",
        next(e for e in back.entries if e.path == "DEMO/TTL").units
        == ["app_client", "app_server"],
    )
    _check("extract.read.absent",
           all(not e.units for e in back.entries if e.path != "DEMO/TTL"))
    _check("extract.read.roundTrip", back.to_yaml() == y)


# --- the register (spec_generation_units) ---------------------------------


def test_register_units() -> None:
    """Units in register order, each with its own mappings."""
    model = _corpus_model()
    d = _register()
    d.set_form_field("DEMO/DLV-LST-1/content", "kind", "client")
    for unit, area, mapping in [
        ("DEMO/DLV-LST-1", "CE-NV", "dart-tom"),
        ("DEMO/DLV-LST-1", "CE-TX", " ts-react "),
        ("DEMO/DLV-LST-2", "CE-NV", "dart-tom"),
    ]:
        r = d.add_list_item(f"{unit}/DLR-LST")
        d.set_form_field(f"{r}/content", "area", area)
        d.set_form_field(f"{r}/content", "mapping", mapping)
    units = spec_generation_units(model, d)
    ids = [u.unit_id for u in units]
    _check("register.ids", ids == ["u_a", "u_b"], str(ids))
    _check("register.kind", units[0].kind == "client", units[0].kind)
    _check("register.path", units[0].path == "DEMO/DLV-LST-1", units[0].path)
    pairs = [(m.area, m.mapping) for m in units[0].mappings]
    _check("register.mappings",
           pairs == [("CE-NV", "dart-tom"), ("CE-TX", "ts-react")],
           str(pairs))
    _check("register.mappingFor",
           units[0].mapping_for("CE-TX") == "ts-react")
    _check("register.mappingFor.none",
           units[-1].mapping_for("CE-TX") is None)
    _check("register.default.NV",
           spec_default_units(units, "CE-NV") == ["u_a", "u_b"])
    _check("register.default.TX",
           spec_default_units(units, "CE-TX") == ["u_a"])
    _check("register.default.DB", spec_default_units(units, "CE-DB") == [])


def test_register_skipped() -> None:
    """A unit without an id, and a second unit of one id, are left out."""
    d = _register()
    d.add_list_item("DEMO/DLV-LST")
    dup = d.add_list_item("DEMO/DLV-LST")
    d.set_form_field(f"{dup}/content", "unitId", "u_a")
    ids = [u.unit_id for u in spec_generation_units(_corpus_model(), d)]
    _check("register.skipped", ids == ["u_a", "u_b"], str(ids))


def test_register_none() -> None:
    """A document without a register declares none."""
    _check("register.none",
           spec_generation_units(_corpus_model(), SpecDocument()) == [])


def main() -> int:
    for t in (
        test_store,
        test_snapshot,
        test_remove_values_under,
        test_move_list_item,
        test_facade,
        test_markdown_emit,
        test_markdown_parse,
        test_markdown_round_trip,
        test_apply_markdown_result,
        test_yaml_scalar_promotion,
        test_yaml_form_list_item,
        test_yaml_collisions,
        test_assembly,
        test_review_merge,
        test_phase8_clean,
        test_phase8_unknown_unit,
        test_phase8_unrouted,
        test_phase8_register,
        test_phase8_order,
        test_extract_units_inherited,
        test_extract_no_units,
        test_extract_write_read,
        test_register_units,
        test_register_skipped,
        test_register_none,
    ):
        try:
            t()
        except Exception as e:  # noqa: BLE001 — report and keep going
            _failed.append(f"{t.__name__}: raised {type(e).__name__}: {e}")
    if _failed:
        print(f"FAIL: {len(_failed)}/{_passed + len(_failed)} checks failed")
        for f in _failed:
            print(f"  - {f}")
        return 1
    print(f"OK: {_passed} checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
