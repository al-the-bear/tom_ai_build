#!/usr/bin/env python3
"""Tests for the consolidated DocSpecs parsing + validation module (SOM §14) —
a port of ``tom_som_dart_runtime/test/docspecs_validator_test.dart``: the
generic schema-free parse, schema loading (with warnings for unsupported
features), the structured violation list, and the acceptance criterion —
the markdown-codec-emitted Solution Blueprint sample validates cleanly against the
generated ``solution-blueprint`` schema.

Run with: ``python3 tests/docspecs_validator_test.py``. Exit code 0 == green.
"""

from __future__ import annotations

import json
import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
_SIBLINGS = os.path.dirname(_PKG_ROOT)  # ai_build

sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    DocSpecsDocument,
    DocSpecsSchema,
    DocSpecsValidator,
    DocSpecsViolationRule,
    SpecDocument,
    SpecModel,
    bind_docspecs_markdown,
    build_som_meta_tree,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


# ---------------------------------------------------------------------------
# Fixture schema (hand-written in the exact schema-generator output shape , SOM §13).
# ---------------------------------------------------------------------------

_SCHEMA_YAML = '''\
title-format: "# <!--[D00]--> Demo Document"
section-types:
  goal-item:
    prefix: GOAL_ITEM_
    pattern-check-id:
      pattern: "^GOAL-ITEM-[0-9]+$"
      error-message: IDs of this section must match GOAL-ITEM-xxx
  d00-ovr:
    prefix: D00_OVR
    text-required: true
  d00-hdr:
    prefix: D00_HDR
    format: header-form
  gsum:
    prefix: GSUM
  diag:
    prefix: DIAG
    format: mermaid
  goals:
    prefix: GOALS
    subsection-types:
      goal-item:
        min-count: 1
        max-count: infinite
      gsum:
        max-count: 1
form-types:
  header-form:
    fields:
      - fieldname: author
        required: true
      - fieldname: reviewer
        pattern-check:
          pattern: "^[A-Z]"
          error-message: Reviewer must start with an uppercase letter
document:
  sections:
    d00-ovr:
      section-type: d00-ovr
    d00-hdr:
      section-type: d00-hdr
      optional: true
    goals:
      section-type: goals
      optional: true
    diag:
      section-type: diag
      optional: true
'''

_VALID_DOC = '''\
<!-- docspec: demo-document/1.0 -->
# <!--[D00]--> Demo Document

Intro text.

## <!--[D00-OVR]--> Overview

Some overview text.

## <!--[D00-HDR]--> Header

Author: Alice
Reviewer: Bob

## <!--[GOALS]--> Goals

### <!--[GOAL-ITEM-1]--> Goal 1

First goal.

### <!--[GOAL-ITEM-2]--> Goal 2

Second goal.
'''


def _schema() -> DocSpecsSchema:
    return DocSpecsSchema.from_yaml_text(_SCHEMA_YAML)


def _validate(md: str):
    return DocSpecsValidator(_schema()).validate_markdown(md)


def _detail(violations) -> str:
    return "; ".join(str(v) for v in violations)


# --- DocSpecsDocument.parse (generic, schema-free) ----------------------------


def test_parse_tree() -> None:
    doc = DocSpecsDocument.parse(_VALID_DOC)
    _check("parse.declaredSchema", doc.declared_schema == "demo-document/1.0",
           str(doc.declared_schema))
    _check("parse.noViolations", not doc.violations, _detail(doc.violations))
    _check("parse.oneRoot", len(doc.sections) == 1, str(len(doc.sections)))
    root = doc.sections[0]
    _check("parse.root.id", root.id == "D00", str(root.id))
    _check("parse.root.title", root.title == "Demo Document", root.title)
    _check("parse.root.level", root.level == 1, str(root.level))
    _check("parse.root.text", root.text == "Intro text.", repr(root.text))
    _check("parse.root.children",
           [c.id for c in root.children] == ["D00-OVR", "D00-HDR", "GOALS"],
           str([c.id for c in root.children]))
    goals = root.children[-1]
    _check("parse.goals.children",
           [c.id for c in goals.children] == ["GOAL-ITEM-1", "GOAL-ITEM-2"],
           str([c.id for c in goals.children]))
    _check("parse.goal1.text", goals.children[0].text == "First goal.",
           repr(goals.children[0].text))


def test_parse_fence_shield() -> None:
    doc = DocSpecsDocument.parse(
        "# <!--[D00]--> Demo Document\n"
        "\n"
        "```md\n"
        "## <!--[NOT-A-SECTION]--> shielded\n"
        "```\n"
    )
    _check("parse.fence.noChildren", not doc.sections[0].children)
    _check("parse.fence.bodyKept", "NOT-A-SECTION" in doc.sections[0].text)


def test_parse_malformed_heading() -> None:
    doc = DocSpecsDocument.parse(
        "# <!--[D00]--> Demo Document\n"
        "\n"
        "## Plain Heading\n"
    )
    _check("parse.malformed.count", len(doc.violations) == 1,
           _detail(doc.violations))
    if doc.violations:
        v = doc.violations[0]
        _check("parse.malformed.rule",
               v.rule == DocSpecsViolationRule.MALFORMED_HEADING, str(v))
        _check("parse.malformed.line", v.line == 3, str(v.line))


# --- DocSpecsSchema.from_yaml_text --------------------------------------------


def test_schema_loading() -> None:
    schema = _schema()
    _check("schema.noWarnings", not schema.warnings, str(schema.warnings))
    _check("schema.rootSectionId", schema.root_section_id == "D00",
           str(schema.root_section_id))
    _check("schema.goalItem.present",
           "goal-item" in schema.section_types_by_name)
    goal_item = schema.section_types_by_name["goal-item"]
    _check("schema.goalItem.prefix", goal_item.prefix == "GOAL_ITEM_",
           goal_item.prefix)
    _check("schema.goalItem.pattern",
           goal_item.pattern_check_id is not None
           and goal_item.pattern_check_id.pattern == r"^GOAL-ITEM-[0-9]+$",
           str(goal_item.pattern_check_id and goal_item.pattern_check_id.pattern))
    goals = schema.section_types_by_name["goals"]
    _check("schema.goals.min",
           goals.subsection_types["goal-item"].min_count == 1)
    _check("schema.goals.maxInfinite",
           goals.subsection_types["goal-item"].max_count is None)
    _check("schema.gsum.max1", goals.subsection_types["gsum"].max_count == 1)
    form = schema.form_types["header-form"]
    _check("schema.form.fields",
           [f.name for f in form.fields] == ["author", "reviewer"],
           str([f.name for f in form.fields]))
    _check("schema.form.authorRequired", form.fields[0].required)
    _check("schema.doc.ovrRequired",
           not schema.document_sections["d00-ovr"].optional)
    _check("schema.doc.hdrOptional",
           schema.document_sections["d00-hdr"].optional)


def test_schema_resolution() -> None:
    schema = _schema()

    def name_of(id: str):
        t = schema.resolve_section_type(id)
        return t.name if t is not None else None

    _check("resolve.goalItem", name_of("GOAL-ITEM-7") == "goal-item",
           str(name_of("GOAL-ITEM-7")))
    _check("resolve.goals", name_of("GOALS") == "goals", str(name_of("GOALS")))
    _check("resolve.ovr", name_of("D00-OVR") == "d00-ovr",
           str(name_of("D00-OVR")))
    _check("resolve.none", name_of("NOPE-1") is None, str(name_of("NOPE-1")))


def test_schema_warnings() -> None:
    schema = DocSpecsSchema.from_yaml_text(
        'title-format: "# <!--[D00]--> Demo"\n'
        "generators:\n"
        "  something: true\n"
        "section-types:\n"
        "  d00-ovr:\n"
        "    prefix: D00_OVR\n"
        "    database-schema:\n"
        "      table: t\n"
        "document:\n"
        "  sections:\n"
        "    d00-ovr:\n"
        "      section-type: d00-ovr\n"
        "  custom-tag: x\n"
    )
    _check("warnings.count", len(schema.warnings) == 3, str(schema.warnings))
    joined = "\n".join(schema.warnings)
    _check("warnings.generators", "generators" in joined, joined)
    _check("warnings.databaseSchema", "database-schema" in joined, joined)
    _check("warnings.customTag", "custom-tag" in joined, joined)
    # The supported parts still load.
    _check("warnings.stillLoads",
           schema.section_types_by_name.get("d00-ovr") is not None)


# --- DocSpecsValidator.validate ------------------------------------------------


def test_validate_valid() -> None:
    v = _validate(_VALID_DOC)
    _check("validate.valid.empty", not v, _detail(v))


def test_validate_missing_required_section() -> None:
    md = re.sub(
        r"## <!--\[D00-OVR\]--> Overview\n\nSome overview text\.\n\n",
        "", _VALID_DOC, count=1,
    )
    v = _validate(md)
    _check("validate.missingSection.count", len(v) == 1, _detail(v))
    if v:
        _check("validate.missingSection.rule",
               v[0].rule == DocSpecsViolationRule.MISSING_REQUIRED_SECTION,
               str(v[0]))
        _check("validate.missingSection.id", v[0].section_id == "d00-ovr",
               str(v[0].section_id))
        _check("validate.missingSection.msg", "d00-ovr" in v[0].message,
               v[0].message)


def test_validate_id_pattern_mismatch() -> None:
    md = _VALID_DOC.replace("GOAL-ITEM-2", "GOAL-ITEM-B", 1)
    v = _validate(md)
    _check("validate.idPattern.count", len(v) == 1, _detail(v))
    if v:
        _check("validate.idPattern.rule",
               v[0].rule == DocSpecsViolationRule.ID_PATTERN_MISMATCH,
               str(v[0]))
        _check("validate.idPattern.id", v[0].section_id == "GOAL-ITEM-B",
               str(v[0].section_id))
        _check("validate.idPattern.msg",
               v[0].message == "IDs of this section must match GOAL-ITEM-xxx",
               v[0].message)
        _check("validate.idPattern.line", v[0].line == 21, str(v[0].line))


def test_validate_unknown_section() -> None:
    md = _VALID_DOC.replace(
        "### <!--[GOAL-ITEM-2]--> Goal 2", "### <!--[XYZ-2]--> Goal 2", 1
    )
    v = _validate(md)
    _check("validate.unknown.count", len(v) == 1, _detail(v))
    if v:
        _check("validate.unknown.rule",
               v[0].rule == DocSpecsViolationRule.UNKNOWN_SECTION, str(v[0]))
        _check("validate.unknown.id", v[0].section_id == "XYZ-2",
               str(v[0].section_id))


def test_validate_disallowed_position() -> None:
    md = _VALID_DOC.replace(
        "### <!--[GOAL-ITEM-2]--> Goal 2", "### <!--[DIAG]--> Diagram", 1
    )
    v = _validate(md)
    _check("validate.disallowed.count", len(v) == 1, _detail(v))
    if v:
        _check("validate.disallowed.rule",
               v[0].rule == DocSpecsViolationRule.UNKNOWN_SECTION, str(v[0]))
        _check("validate.disallowed.msg",
               "not an allowed subsection" in v[0].message, v[0].message)


def test_validate_missing_required_field() -> None:
    md = _VALID_DOC.replace("Author: Alice\n", "", 1)
    v = _validate(md)
    _check("validate.missingField.count", len(v) == 1, _detail(v))
    if v:
        _check("validate.missingField.rule",
               v[0].rule == DocSpecsViolationRule.MISSING_REQUIRED_FIELD,
               str(v[0]))
        _check("validate.missingField.id", v[0].section_id == "D00-HDR",
               str(v[0].section_id))
        _check("validate.missingField.msg", "author" in v[0].message,
               v[0].message)


def test_validate_field_pattern_mismatch() -> None:
    md = _VALID_DOC.replace("Reviewer: Bob", "Reviewer: bob", 1)
    v = _validate(md)
    _check("validate.fieldPattern.count", len(v) == 1, _detail(v))
    if v:
        _check("validate.fieldPattern.rule",
               v[0].rule == DocSpecsViolationRule.FIELD_PATTERN_MISMATCH,
               str(v[0]))
        _check("validate.fieldPattern.msg",
               v[0].message == "Reviewer must start with an uppercase letter",
               v[0].message)
        _check("validate.fieldPattern.line", v[0].line == 13, str(v[0].line))


def test_validate_text_required() -> None:
    md = _VALID_DOC.replace("Some overview text.\n\n", "", 1)
    v = _validate(md)
    _check("validate.textRequired.count", len(v) == 1, _detail(v))
    if v:
        _check("validate.textRequired.rule",
               v[0].rule == DocSpecsViolationRule.TEXT_REQUIRED, str(v[0]))
        _check("validate.textRequired.id", v[0].section_id == "D00-OVR",
               str(v[0].section_id))


def test_validate_too_many_items() -> None:
    md = (
        f"{_VALID_DOC}\n"
        "### <!--[GSUM]--> Summary\n\nOne.\n\n"
        "### <!--[GSUM]--> Summary\n\nTwo.\n"
    )
    v = _validate(md)
    _check("validate.tooMany.count", len(v) == 1, _detail(v))
    if v:
        _check("validate.tooMany.rule",
               v[0].rule == DocSpecsViolationRule.TOO_MANY_ITEMS, str(v[0]))
        _check("validate.tooMany.msg", "gsum" in v[0].message, v[0].message)


def test_validate_format_mismatch() -> None:
    md = f"{_VALID_DOC}\n## <!--[DIAG]--> Diagram\n\nno fence here\n"
    v = _validate(md)
    _check("validate.format.count", len(v) == 1, _detail(v))
    if v:
        _check("validate.format.rule",
               v[0].rule == DocSpecsViolationRule.FORMAT_MISMATCH, str(v[0]))
    ok = (
        f"{_VALID_DOC}\n## <!--[DIAG]--> Diagram\n\n"
        "```mermaid\ngraph TD;\n```\n"
    )
    v_ok = _validate(ok)
    _check("validate.format.fencedOk", not v_ok, _detail(v_ok))


def test_validate_root_mismatch() -> None:
    md = _VALID_DOC.replace("# <!--[D00]-->", "# <!--[D99]-->", 1)
    v = _validate(md)
    _check("validate.rootMismatch.rule",
           any(x.rule == DocSpecsViolationRule.FORMAT_MISMATCH for x in v),
           _detail(v))


def test_validate_never_fail_fast() -> None:
    md = (
        _VALID_DOC
        .replace("Author: Alice\n", "", 1)
        .replace("Reviewer: Bob", "Reviewer: bob", 1)
        .replace("GOAL-ITEM-2", "GOAL-ITEM-B", 1)
    )
    v = _validate(md)
    got = {x.rule for x in v}
    want = {
        DocSpecsViolationRule.MISSING_REQUIRED_FIELD,
        DocSpecsViolationRule.FIELD_PATTERN_MISMATCH,
        DocSpecsViolationRule.ID_PATTERN_MISMATCH,
    }
    _check("validate.neverFailFast", got == want,
           f"{sorted(r.value for r in got)} != {sorted(r.value for r in want)}")


# --- bind_docspecs_markdown ----------------------------------------------------


def test_bind_docspecs_markdown() -> None:
    corpus = os.path.join(_SIBLINGS, "tom_som_conformance", "corpus")
    with open(os.path.join(corpus, "model.meta.json"), encoding="utf-8") as fh:
        model = SpecModel.from_json(json.load(fh))
    with open(os.path.join(corpus, "expected.md"), encoding="utf-8") as fh:
        md = fh.read()
    result = bind_docspecs_markdown(model, SpecDocument(), md)
    _check("bind.clean", result.is_clean,
           "; ".join(str(r) for r in result.rejections))
    _check("bind.appliedCount", result.applied_count > 0,
           str(result.applied_count))


# --- acceptance: emitted sample vs generated schema ----------------------------


def test_dr7_acceptance() -> None:
    """The Solution Blueprint sample emitted by the markdown codec (SOM §11) validates
    cleanly against the generated ``solution-blueprint`` schema."""
    meta_path = os.path.join(
        _SIBLINGS, "tom_som_dart_v0", "meta", "spec_model.meta.json"
    )
    with open(meta_path, encoding="utf-8") as fh:
        model = SpecModel.from_json(json.load(fh))
    # The shared sample is a hierarchical-v2 `*.docspecs.yaml` (SOM §12): decode
    # it against the metadata tree bridged from the exported model.
    sample_path = os.path.join(
        _SIBLINGS, "tom_som_conformance", "samples",
        "meridian_order_management.docspecs.yaml",
    )
    document = SpecDocument.from_file(
        sample_path,
        build_som_meta_tree(model, root_type="D00SolutionBlueprint"),
    )
    md = document.to_markdown(model)

    schema_path = os.path.join(
        _SIBLINGS, "tom_som_dart_v0", "schemas", "solution-blueprint",
        "solution-blueprint.1.0.docspecs-schema.yaml",
    )
    with open(schema_path, encoding="utf-8") as fh:
        schema = DocSpecsSchema.from_yaml_text(fh.read())
    _check("dr7.rootSectionId", schema.root_section_id == "SBP",
           str(schema.root_section_id))

    violations = DocSpecsValidator(schema).validate_markdown(md)
    _check("dr7.violationsEmpty", not violations,
           "".join(f"\n{v}" for v in violations[:20]))


def main() -> int:
    test_parse_tree()
    test_parse_fence_shield()
    test_parse_malformed_heading()
    test_schema_loading()
    test_schema_resolution()
    test_schema_warnings()
    test_validate_valid()
    test_validate_missing_required_section()
    test_validate_id_pattern_mismatch()
    test_validate_unknown_section()
    test_validate_disallowed_position()
    test_validate_missing_required_field()
    test_validate_field_pattern_mismatch()
    test_validate_text_required()
    test_validate_too_many_items()
    test_validate_format_mismatch()
    test_validate_root_mismatch()
    test_validate_never_fail_fast()
    test_bind_docspecs_markdown()
    test_dr7_acceptance()

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
