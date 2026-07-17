#!/usr/bin/env python3
"""Cross-language golden-log generator for Python (roadmap item 7b).

Mirror of ``tom_som_dart_v0/tool/golden_log.dart`` — see that file for the
canonical format definition. Loads the shared sample and emits a byte-identical
reading of essentially every section through both the generic string-path API
and the typed facade. Running it asserts the typed reads equal the generic reads
before writing, so a divergence aborts non-zero.

Usage: python3 tool/golden_log.py [samplePath] [outputPath]
"""

from __future__ import annotations

import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PROJECT = os.path.dirname(_HERE)  # tom_som_python_v0


def _runtime_dir() -> str:
    toml = os.path.join(_PROJECT, "pyproject.toml")
    text = open(toml, encoding="utf-8").read()
    rel = re.search(r'runtime-path\s*=\s*"([^"]+)"', text).group(1)
    module_dir = os.path.normpath(os.path.join(_PROJECT, rel))
    return os.path.dirname(module_dir)


sys.path.insert(0, _runtime_dir())
sys.path.insert(0, _PROJECT)

from tom_som_runtime import (  # noqa: E402
    DocSpecsSchema,
    DocSpecsValidator,
    SomMetaKind,
    SpecDocument,
)
import tom_som_python_v0 as m  # noqa: E402

_DEFAULT_SAMPLE_MD = os.path.normpath(os.path.join(
    _PROJECT, "..", "tom_som_conformance", "samples",
    "meridian_order_management.md"))
_DEFAULT_SCHEMA = os.path.join(
    _PROJECT, "schemas", "solution-blueprint",
    "solution-blueprint.1.0.docspecs-schema.yaml")

#: Map the native Python kind enum to the DART enum spelling the golden log
#: emits (portability rule 1). Values are the canonical cross-language names.
_KIND_DART_NAME = {
    SomMetaKind.LIST: "list",
    SomMetaKind.FORM: "form",
    SomMetaKind.SECTION: "section",
    SomMetaKind.CONTENT: "content",
    SomMetaKind.ENUM_VALUE: "enumValue",
    SomMetaKind.COMPLEX: "complex",
    SomMetaKind.SCALAR: "scalar",
}

_DEFAULT_SAMPLE = os.path.normpath(os.path.join(
    _PROJECT, "..", "tom_som_conformance", "samples",
    "meridian_order_management.docspecs.yaml"))
_DEFAULT_OUTPUT = os.path.normpath(os.path.join(
    _PROJECT, "..", "tom_som_conformance", "golden", "python.log"))


def esc(s: str) -> str:
    return (s.replace("\\", "\\\\")
             .replace("\n", "\\n")
             .replace("\r", "\\r")
             .replace("\t", "\\t"))


def main() -> None:
    sample = sys.argv[1] if len(sys.argv) > 1 else _DEFAULT_SAMPLE
    output = sys.argv[2] if len(sys.argv) > 2 else _DEFAULT_OUTPUT

    doc = SpecDocument.from_file(sample, m.d00SolutionBlueprintMetaTree)
    sbp = m.D00SolutionBlueprint.load_file(sample)

    out: list[str] = []
    out.append("# TomSpecs SOM golden log — canonical cross-language reading.")
    out.append("# All nine per-language generators must emit byte-identical output.")
    out.append("FORMAT\t4")
    out.append("MODELVERSION\t" + esc(doc.model_version or ""))

    # Generic: content leaves, sorted by path.
    out.append("SECTION\tgeneric-content")
    for p in sorted(doc.content_paths):
        out.append("C\t%s\t%s" % (p, esc(doc.content(p) or "")))

    # Generic: form sections + fields, sorted by path then field.
    out.append("SECTION\tgeneric-forms")
    for p in sorted(doc.form_paths):
        for f in sorted(doc.form_field_names(p)):
            out.append("F\t%s\t%s\t%s" % (p, f, esc(doc.form_field(p, f) or "")))

    # Generic: list containers + item paths (document order).
    # FORMAT 3: each item with a *stored* section id additionally emits an
    # `ID` line (item path + stored id); items without one emit no `ID` line.
    out.append("SECTION\tgeneric-lists")
    for p in sorted(doc.list_paths):
        items = doc.list_items(p)
        out.append("L\t%s\t%d" % (p, len(items)))
        for item in items:
            out.append("I\t%s" % item)
            item_id = doc.item_section_id(item)
            if item_id is not None:
                out.append("ID\t%s\t%s" % (item, esc(item_id)))

    # Generic: every stored headline, sorted by path (FORMAT 3, YRD3).
    out.append("SECTION\tgeneric-headlines")
    for p in sorted(doc.headline_paths):
        out.append("H\t%s\t%s" % (p, esc(doc.headline(p) or "")))

    # Typed: curated traversal that must agree with the generic reads.
    out.append("SECTION\ttyped")

    def typed_content(path: str, value: str) -> None:
        leaf = path + "/content"
        generic = doc.content(leaf) or ""
        if value != generic:
            sys.stderr.write("TYPED MISMATCH at %s\n" % leaf)
            sys.exit(2)
        out.append("T\t%s\t%s" % (leaf, esc(value)))

    typed_content(sbp.path, sbp.content)
    typed_content(sbp.documentControl.path, sbp.documentControl.content)
    typed_content(sbp.introductionAndScope.path, sbp.introductionAndScope.content)
    typed_content(sbp.glossaryAndAbbreviations.path, sbp.glossaryAndAbbreviations.content)
    typed_content(sbp.stakeholdersAndGovernance.path, sbp.stakeholdersAndGovernance.content)
    typed_content(sbp.currentLandscape.path, sbp.currentLandscape.content)
    typed_content(sbp.assumptionsConstraintsDependencies.path,
                  sbp.assumptionsConstraintsDependencies.content)
    typed_content(sbp.targetOperatingModelConcept.path,
                  sbp.targetOperatingModelConcept.content)
    typed_content(sbp.informationAndDataModel.path, sbp.informationAndDataModel.content)
    typed_content(sbp.requirements.path, sbp.requirements.content)
    typed_content(sbp.solutionArchitectureAndTechnology.path,
                  sbp.solutionArchitectureAndTechnology.content)
    typed_content(sbp.securityAndAccessModel.path, sbp.securityAndAccessModel.content)
    typed_content(sbp.experienceAndInterfaceDesign.path,
                  sbp.experienceAndInterfaceDesign.content)
    typed_content(sbp.qualityAndAcceptanceModel.path, sbp.qualityAndAcceptanceModel.content)
    typed_content(sbp.deliveryTransitionAndRollout.path,
                  sbp.deliveryTransitionAndRollout.content)

    typed_content(sbp.introductionAndScope.goals.path,
                  sbp.introductionAndScope.goals.content)

    metrics = sbp.currentLandscape.operationalMetrics
    metric_item_paths = doc.list_items(metrics.list_path)
    if metrics.length != len(metric_item_paths):
        sys.stderr.write("TYPED LIST LENGTH MISMATCH at %s\n" % metrics.list_path)
        sys.exit(2)
    out.append("TL\t%s\t%d" % (metrics.list_path, metrics.length))
    for i in range(metrics.length):
        elem = metrics[i]
        leaf = elem.path + "/content"
        generic = doc.content(leaf) or ""
        if elem.content != generic:
            sys.stderr.write("TYPED LIST ITEM MISMATCH at %s\n" % leaf)
            sys.exit(2)
        out.append("TI\t%s\t%s" % (leaf, esc(elem.content)))

    # --- Meta (FORMAT 2): the generated metadata tree read three ways. ---
    meta_tree = m.d00SolutionBlueprintMetaTree

    out.append("SECTION\tmeta")

    def meta_node(path: str) -> None:
        n = meta_tree.by_path(path)
        if n is None:
            sys.stderr.write("META MISSING at %s\n" % path)
            sys.exit(3)
        out.append("M\t%s\t%s\t%s\t%s\t%s\t%s\t%s" % (
            path,
            _KIND_DART_NAME[n.kind],
            esc(n.section_id or ""),
            esc(n.content_help or ""),
            esc(n.comment or ""),
            esc(n.doc_comment or ""),
            esc(n.headline or ""),
        ))

    meta_node("SBP")
    meta_node("SBP/documentControl")
    meta_node("SBP/documentControl/RVHST-REVS-LST")
    meta_node("SBP/introductionAndScope")
    meta_node("SBP/introductionAndScope/goals")
    meta_node("SBP/introductionAndScope/goals/content")
    meta_node("SBP/currentLandscape")
    meta_node("SBP/currentLandscape/CUOPME-OPER-LST")
    meta_node("SBP/requirements")
    meta_node("SBP/requirements/content")

    out.append("SECTION\tmeta-nav")

    def meta_nav(ref, expected_path: str) -> None:
        if ref.path != expected_path:
            sys.stderr.write(
                "META NAV PATH at %s expected %s\n" % (ref.path, expected_path))
            sys.exit(3)
        by_path = meta_tree.by_path(expected_path)
        if by_path is None or ref.meta is not by_path:
            sys.stderr.write("META NAV NODE mismatch at %s\n" % expected_path)
            sys.exit(3)
        out.append("N\t%s" % expected_path)

    meta_nav(m.d00SolutionBlueprint, "SBP")
    meta_nav(m.d00SolutionBlueprint.documentControl, "SBP/documentControl")
    meta_nav(m.d00SolutionBlueprint.introductionAndScope,
             "SBP/introductionAndScope")
    meta_nav(m.d00SolutionBlueprint.introductionAndScope.goals,
             "SBP/introductionAndScope/goals")
    meta_nav(m.d00SolutionBlueprint.introductionAndScope.goals.content,
             "SBP/introductionAndScope/goals/content")
    meta_nav(m.d00SolutionBlueprint.currentLandscape, "SBP/currentLandscape")
    meta_nav(m.d00SolutionBlueprint.requirements, "SBP/requirements")
    meta_nav(m.d00SolutionBlueprint.requirements.content,
             "SBP/requirements/content")

    out.append("SECTION\tmeta-id")

    def meta_id(id_ref, nav_ref) -> None:
        if id_ref.path != nav_ref.path or id_ref.meta is not nav_ref.meta:
            sys.stderr.write(
                "META ID mismatch at %s vs %s\n" % (id_ref.path, nav_ref.path))
            sys.exit(3)
        out.append("D\t%s" % id_ref.path)

    meta_id(m.SBP, m.d00SolutionBlueprint)
    meta_id(m.SBP.RVHST_REVS_LST,
            m.d00SolutionBlueprint.documentControl.revisionHistory)
    meta_id(m.SBP.RVHST_REVS_LST.item(0),
            m.d00SolutionBlueprint.documentControl.revisionHistory.item(0))

    out.append("SECTION\tdocspecs")
    with open(_DEFAULT_SCHEMA, encoding="utf-8") as fh:
        schema = DocSpecsSchema.from_yaml_text(fh.read())
    with open(_DEFAULT_SAMPLE_MD, encoding="utf-8") as fh:
        sample_md = fh.read()
    violations = DocSpecsValidator(schema).validate_markdown(sample_md)
    out.append("DS\troot\t%s" % esc(schema.root_section_id or ""))
    out.append("DS\twarnings\t%d" % len(schema.warnings))
    out.append("DS\tviolations\t%d" % len(violations))
    for v in violations:
        out.append("DV\t%s\t%s\t%d" % (
            v.rule.value, esc(v.section_id or ""), v.line))

    os.makedirs(os.path.dirname(output), exist_ok=True)
    with open(output, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(out) + "\n")
    sys.stdout.write("wrote %d lines to %s\n" % (len(out), output))


if __name__ == "__main__":
    main()
