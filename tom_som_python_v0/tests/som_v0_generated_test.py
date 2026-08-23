#!/usr/bin/env python3
"""Behavioural test for the **actually-committed** generated Python typed model.

Unlike the runtime's ``tests/som_v0_facade_test.py`` — which loads the small
emitter *golden fixture* — this suite imports the real, full
``tom_som_python_v0`` module (3000+ classes) against the generic
``tom_som_runtime`` and proves the typed facade is a faithful editing surface
over the shared document (SOM §6):

  * the real module imports cleanly against the runtime;
  * the ``D00SolutionBlueprint`` root is anchored at the ``PD`` segment;
  * a content leaf round-trips typed -> generic and generic -> typed;
  * a nested complex section derives its path under the root;
  * the generated model-version accessor returns ``1.0``;
  * the instantiation-time version check (SOM §4.2) accepts an editable stamp and
    rejects a newer-minor / cross-major stamp;
  * the generated per-root ``editability_for`` (SOM §21) classifies every
    SOM §4.2 outcome without throwing and agrees with the throwing constructor
    gate;
  * aligned absence semantics (SOM §21): a section is ``is_empty`` until a
    value is written under it, typed ``is_empty`` agrees with generic
    ``has_values_under``, and ``has_content`` gives the generic path the typed
    ``.content`` answer;
  * one-call loading (SOM §21): ``load_yaml`` / ``load_file`` collapse the
    former decode → ``load_json`` → thread-version sequence and ``from_yaml``
    retains (or nulls) the parsed model-version stamp;
  * live-document conformance case (YRD8 / dsa8): the shared Meridian sample
    survives a decode → encode → decode round-trip byte-for-byte at the value
    level, its markdown validates cleanly against the generated schema (root
    ``SBP``, 0 warnings / 0 violations), the document validates cleanly on the
    instance tier (``validate_document``, SOM §9), and the metadata tree / nav
    / id accessors resolve to the same node — the Python parity of the Dart
    guard.

Run with ``python3 tests/som_v0_generated_test.py``; exit code 0 == all green.
The runtime is located by the ``runtime-path`` recorded in ``pyproject.toml`` so
the test is portable across checkouts.
"""

from __future__ import annotations

import json
import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PROJECT = os.path.dirname(_HERE)  # tom_som_python_v0


def _runtime_dir() -> str:
    """The generic runtime package dir, read from ``pyproject.toml``.

    The manifest records ``runtime-path`` relative to the project root and
    points at the ``tom_som_runtime`` module dir; its parent is what goes on
    ``sys.path`` so ``import tom_som_runtime`` resolves.
    """
    toml = os.path.join(_PROJECT, "pyproject.toml")
    text = open(toml, encoding="utf-8").read()
    rel = re.search(r'runtime-path\s*=\s*"([^"]+)"', text).group(1)
    module_dir = os.path.normpath(os.path.join(_PROJECT, rel))
    return os.path.dirname(module_dir)


sys.path.insert(0, _runtime_dir())
sys.path.insert(0, _PROJECT)

from tom_som_runtime import (  # noqa: E402
    SpecDocument,
    SomVersionError,
    SomEditability,
    SomMetaKind,
    DocSpecsSchema,
    DocSpecsValidator,
    SpecModel,
    validate_document,
    yaml_encode,
)
import tom_som_python_v0 as m  # noqa: E402

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def test_root_and_parity() -> None:
    doc = SpecDocument()
    pd = m.D00SolutionBlueprint(doc)

    _check("root.segment", pd.path == "SBP", pd.path)

    # Typed write -> generic read.
    pd.content = "A clear vision"
    _check("content.typed->generic", doc.content("SBP/content") == "A clear vision",
           str(doc.content("SBP/content")))

    # Generic write -> typed read.
    doc.set_content("SBP/content", "Revised vision")
    _check("content.generic->typed", pd.content == "Revised vision", pd.content)

    # Unset leaf reads as empty string.
    _check("content.unset-empty", m.D00SolutionBlueprint(SpecDocument()).content == "")

    # Nested complex section path derivation. The Python emitter preserves the
    # model's camelCase accessor names (no snake_case translation).
    _check("nested.path", pd.currentLandscape.path == "SBP/currentLandscape",
           pd.currentLandscape.path)

    # A generic value under the nested typed node is addressable via the
    # expected literal path (proves typed path == generic path).
    header_path = pd.documentControl.path
    doc.set_content(f"{header_path}/probe", "x")
    _check("nested.typed-path==generic", doc.content("SBP/documentControl/probe") == "x")


def test_model_version() -> None:
    _check("version.classattr", m.D00SolutionBlueprint.model_version == "1.0",
           m.D00SolutionBlueprint.model_version)
    pd = m.D00SolutionBlueprint(SpecDocument())
    _check("version.accessor", pd.object_model_version == "1.0",
           pd.object_model_version)


def test_version_check() -> None:
    # New / equal-stamp document → accepted.
    try:
        m.D00SolutionBlueprint(SpecDocument())
        m.D00SolutionBlueprint(SpecDocument(), document_version="1.0")
        _check("version.editable", True)
    except SomVersionError as e:  # pragma: no cover
        _check("version.editable", False, str(e))

    # Newer minor → rejected.
    try:
        m.D00SolutionBlueprint(SpecDocument(), document_version="1.1")
        _check("version.newer-rejected", False, "expected SomVersionError")
    except SomVersionError:
        _check("version.newer-rejected", True)

    # Different major → rejected.
    try:
        m.D00SolutionBlueprint(SpecDocument(), document_version="2.0")
        _check("version.cross-major-rejected", False, "expected SomVersionError")
    except SomVersionError:
        _check("version.cross-major-rejected", True)


def test_editability_for() -> None:
    # The generated per-root ``editability_for`` classifies every SOM §4.2 outcome
    # without throwing (SOM §21), delegating to the runtime classifier with
    # the root's own MODEL_VERSION.
    _check("editability.none",
           m.D00SolutionBlueprint.editability_for(None) ==
           SomEditability.EDITABLE)
    _check("editability.equal",
           m.D00SolutionBlueprint.editability_for("1.0") ==
           SomEditability.EDITABLE)
    _check("editability.newer-minor",
           m.D00SolutionBlueprint.editability_for("1.1") ==
           SomEditability.REJECTED_NEWER_MINOR)
    _check("editability.cross-major",
           m.D00SolutionBlueprint.editability_for("2.0") ==
           SomEditability.READ_ONLY_CROSS_MAJOR)
    _check("editability.invalid",
           m.D00SolutionBlueprint.editability_for("nope") ==
           SomEditability.INVALID_VERSION)

    # ``editable`` iff the constructor accepts the same stamp — the non-throwing
    # classifier and the throwing SOM §4.2 gate agree on every stamp.
    for stamp in (None, "1.0", "1.1", "2.0", "nope"):
        editable = (m.D00SolutionBlueprint.editability_for(stamp) ==
                    SomEditability.EDITABLE)
        try:
            m.D00SolutionBlueprint(SpecDocument(), document_version=stamp)
            accepted = True
        except SomVersionError:
            accepted = False
        _check(f"editability.agrees[{stamp}]", editable == accepted,
               f"stamp {stamp!r}: editable={editable} accepted={accepted}")


def test_absence_semantics() -> None:
    # 1) A section is_empty until any value is written under it (subtree-wide).
    doc = SpecDocument()
    sbp = m.D00SolutionBlueprint(doc)
    _check("absence.section-empty", sbp.requirements.is_empty is True)
    sbp.requirements.content = "Some requirements"
    _check("absence.section-filled", sbp.requirements.is_empty is False)
    sbp.requirements.content = ""
    _check("absence.section-empty-again", sbp.requirements.is_empty is True)

    # 2) Typed is_empty and generic has_values_under agree.
    doc = SpecDocument()
    sbp = m.D00SolutionBlueprint(doc)
    path = sbp.requirements.path
    _check("absence.typed==generic.empty",
           sbp.requirements.is_empty == (not doc.has_values_under(path)))
    doc.set_content(f"{path}/content", "x")
    _check("absence.typed==generic.filled",
           sbp.requirements.is_empty == (not doc.has_values_under(path)))
    _check("absence.filled-not-empty", sbp.requirements.is_empty is False)

    # 3) has_content gives the generic path the typed .content answer.
    doc = SpecDocument()
    sbp = m.D00SolutionBlueprint(doc)
    leaf = f"{sbp.requirements.path}/content"
    _check("absence.typed-empty", sbp.requirements.content == "")
    _check("absence.has_content-false", doc.has_content(leaf) is False)
    sbp.requirements.content = "Filled"
    _check("absence.has_content-agrees",
           (sbp.requirements.content != "") == doc.has_content(leaf))
    _check("absence.has_content-true", doc.has_content(leaf) is True)


def test_can_have_content() -> None:
    """SOM §21: the structural content-slot predicate ``can_have_content``
    answers "does this *type* declare the standard ``content`` leaf?" without
    probing the document.

    Since ``tom_specs_model_rules.md`` §10.2 requires ``content: String?`` on
    every section class, the line the predicate draws in the generated facade
    runs between a **section** (always true) and a **non-section node** — a
    scalar list item, whose value *is* its item path.
    """
    sbp = m.D00SolutionBlueprint(SpecDocument())

    # A content-bearing section (Goals declares the standard `content` leaf).
    _check("chc.content-bearing-true",
           sbp.introductionAndScope.goals.can_have_content is True)

    # A scalar list element is a SomScalar: no nested `content` leaf, so it
    # inherits the SomNode `False` default — the whole of the false side.
    item = (sbp.introductionAndScope.systemsToReplace
            .migrationConsiderations.escalationProcedures.add())
    _check("chc.scalar-item-false", item.can_have_content is False)

    # Every section class reports True, including a pure container:
    # SystemsToReplace holds two child sections and no fields of its own, yet
    # still declares `content` (its `@ContentHelp` asks the author to introduce
    # the replacement portfolio). Pins §10.2's universal-content rule at the
    # generated facade — red the day a section class without `content` returns.
    _check("chc.pure-container-true",
           sbp.introductionAndScope.systemsToReplace.can_have_content is True)

    # The document root itself declares a `content` leaf → True.
    _check("chc.root-true",
           m.D00SolutionBlueprint(SpecDocument()).can_have_content is True)

    # A section whose `content` is `@Unused()` still reports True.
    # DocumentControl is one of the ten in the model. `@Unused()` is an
    # *authoring* statement ("no prose is expected here",
    # `tom_specs_model_rules.md` §5.6), not a claim that the slot is absent, so
    # the *capability* answer stays True and the slot stays writable. Pins
    # SOM §21: `can_have_content` never consults the annotation, and no second
    # predicate exists for the authoring question — a consumer reads the
    # content node's `unused` flag in the metadata.
    control = sbp.documentControl
    _check("chc.unused-content-still-true", control.can_have_content is True)
    control.content = "Prose is possible even where it is not expected."
    _check("chc.unused-content-writable",
           control.content == "Prose is possible even where it is not expected.")
    _check("chc.unused-content-still-true-after-write",
           control.can_have_content is True)

    # Structural, not state — independent of whether content is written.
    sbp2 = m.D00SolutionBlueprint(SpecDocument())
    goals = sbp2.introductionAndScope.goals
    _check("chc.structural.empty-true", goals.can_have_content is True)
    goals.content = "Grow revenue"
    _check("chc.structural.filled-true", goals.can_have_content is True)
    item2 = (sbp2.introductionAndScope.systemsToReplace
             .migrationConsiderations.escalationProcedures.add())
    item2.value = "Escalate to the migration board"
    _check("chc.structural.filled-scalar-false",
           item2.can_have_content is False)


def test_one_call_loading() -> None:
    from tom_som_runtime.spec_document_yaml import decode

    # The suite runs from the project root; this relative path resolves there.
    sample_path = "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml"

    # 4) load_yaml collapses decode → load_json → thread-version to one call.
    with open(sample_path, "r", encoding="utf-8") as f:
        yaml = f.read()

    decoded = decode(yaml, m.d00SolutionBlueprintMetaTree)
    manual = m.D00SolutionBlueprint(
        decoded.document, document_version=decoded.model_version)

    one_call = m.D00SolutionBlueprint.load_yaml(yaml)

    _check("load.stamp-auto", one_call.doc.model_version == decoded.model_version,
           str(one_call.doc.model_version))
    _check("load.content-parity", one_call.content == manual.content)
    _check("load.nested-parity",
           one_call.introductionAndScope.goals.content
           == manual.introductionAndScope.goals.content)
    _check("load.list-length-parity",
           one_call.currentLandscape.operationalMetrics.length
           == manual.currentLandscape.operationalMetrics.length)

    # 5) load_file reads the file then delegates to load_yaml.
    from_file = m.D00SolutionBlueprint.load_file(sample_path)
    with open(sample_path, "r", encoding="utf-8") as f:
        from_yaml = m.D00SolutionBlueprint.load_yaml(f.read())
    _check("load.file==yaml.version",
           from_file.doc.model_version == from_yaml.doc.model_version)
    _check("load.file==yaml.content", from_file.content == from_yaml.content)

    # 6) SpecDocument.from_yaml retains the parsed model version. The wire
    # format is hierarchical v2, so the fixture yaml is built via yaml_encode
    # (mirrors the Dart suite's buildV2Yaml helper).
    from tom_som_runtime import yaml_encode

    def build_v2_yaml(model_version):
        d = SpecDocument()
        d.set_content("SBP/content", "Hello")
        return yaml_encode(
            d, m.d00SolutionBlueprintMetaTree, model_version=model_version)

    stamped_yaml = build_v2_yaml("1.0")
    doc = SpecDocument.from_yaml(stamped_yaml, m.d00SolutionBlueprintMetaTree)
    _check("load.from_yaml.version", doc.model_version == "1.0",
           str(doc.model_version))
    _check("load.from_yaml.content", doc.content("SBP/content") == "Hello",
           str(doc.content("SBP/content")))

    # 7) A document with no modelVersion stamp loads with a null stamp.
    unstamped_yaml = build_v2_yaml(None)
    doc = SpecDocument.from_yaml(unstamped_yaml, m.d00SolutionBlueprintMetaTree)
    _check("load.unstamped.null", doc.model_version is None,
           str(doc.model_version))
    try:
        m.D00SolutionBlueprint.load_yaml(unstamped_yaml)
        _check("load.unstamped.accepted", True)
    except Exception as e:  # pragma: no cover
        _check("load.unstamped.accepted", False, str(e))


def test_live_document_case() -> None:
    """Live-document conformance case durability (YRD8 / dsa8).

    The cross-language golden harness already exercises the shared Meridian
    sample end to end and asserts python.log is byte-identical to the Dart
    reference. Because golden/ is git-ignored, this committed test is the
    Python-side durability guard for the three live-document guarantees the
    golden's ``generic-*`` / ``docspecs`` / ``meta-*`` sections encode, plus a
    fourth with no golden section behind it — instance-tier cleanliness — so a
    regression fails ``python3 tests/som_v0_generated_test.py`` without needing
    a full nine-toolchain golden run.
    """
    sample = "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml"
    sample_md = "../tom_som_conformance/samples/meridian_order_management.md"
    schema_path = ("schemas/solution-blueprint/"
                   "solution-blueprint.1.0.docspecs-schema.yaml")
    tree = m.d00SolutionBlueprintMetaTree

    # 1) Round-trip: decode -> encode -> decode is a stable reading (mirrors the
    # golden's generic-content / generic-lists sections).
    original = SpecDocument.from_file(sample, tree)
    re_encoded = yaml_encode(original, tree, model_version=original.model_version)
    round_tripped = SpecDocument.from_yaml(re_encoded, tree)

    _check("live.roundtrip.version",
           round_tripped.model_version == original.model_version)
    _check("live.roundtrip.content-paths",
           sorted(round_tripped.content_paths) == sorted(original.content_paths))
    content_ok = all(
        round_tripped.content(p) == original.content(p)
        for p in original.content_paths)
    _check("live.roundtrip.content-values", content_ok)
    _check("live.roundtrip.list-paths",
           sorted(round_tripped.list_paths) == sorted(original.list_paths))
    list_ok = all(
        round_tripped.list_items(p) == original.list_items(p)
        for p in original.list_paths)
    _check("live.roundtrip.list-items", list_ok)

    # 2) Validation: sample markdown validates cleanly against the generated
    # schema (mirrors the golden's docspecs section — root SBP, 0 / 0).
    with open(schema_path, encoding="utf-8") as fh:
        schema = DocSpecsSchema.from_yaml_text(fh.read())
    with open(sample_md, encoding="utf-8") as fh:
        violations = DocSpecsValidator(schema).validate_markdown(fh.read())
    _check("live.validate.root", schema.root_section_id == "SBP",
           str(schema.root_section_id))
    _check("live.validate.no-warnings", len(schema.warnings) == 0,
           str(len(schema.warnings)))
    _check("live.validate.no-violations", len(violations) == 0,
           str(len(violations)))

    # 2b) Validation, instance tier: the sample's *values* are admissible.
    # Disjoint from the schema tier above — that asks whether every required
    # field is filled, this asks whether the values are well-formed: field
    # kinds, form keys, list minima and ``refersTo`` resolution (SOM §9). A
    # sample naming a message key, a role or a route nothing declares passes
    # the first and fails this one. Pinned here as well as in the sample's
    # builder because the sample is *committed*: a hand-edit or a merge can
    # reach it without anyone re-running the builder.
    with open("meta/spec_model.meta.json", encoding="utf-8") as fh:
        model = SpecModel.from_json(json.load(fh))
    instance_violations = validate_document(model, original)
    _check("live.validate.instance-tier", len(instance_violations) == 0,
           "; ".join(f"{v.path}: {v.code}" for v in instance_violations[:5]))

    # 3) Node operations: metadata tree / nav / id resolve to the same node
    # (mirrors the golden's meta / meta-nav / meta-id sections).
    list_by_path = tree.by_path("SBP/currentLandscape/CUOPME-OPER-LST")
    _check("live.node.by-path", list_by_path is not None)
    _check("live.node.kind-list",
           list_by_path is not None and list_by_path.kind == SomMetaKind.LIST)

    nav_ref = m.d00SolutionBlueprint.currentLandscape.operationalMetrics
    _check("live.node.nav-path",
           nav_ref.path == "SBP/currentLandscape/CUOPME-OPER-LST", nav_ref.path)
    _check("live.node.nav-identity", nav_ref.meta is list_by_path)

    id_ref = m.SBP.RVENT_REVS_LST.item(0)
    nav_item = m.d00SolutionBlueprint.documentControl.revisionHistory.item(0)
    _check("live.node.id-path", id_ref.path == nav_item.path)
    _check("live.node.id-identity", id_ref.meta is nav_item.meta)


def main() -> int:
    test_root_and_parity()
    test_model_version()
    test_version_check()
    test_editability_for()
    test_absence_semantics()
    test_can_have_content()
    test_one_call_loading()
    test_live_document_case()

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
