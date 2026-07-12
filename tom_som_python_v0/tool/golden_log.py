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

from tom_som_runtime import SpecDocument  # noqa: E402
import tom_som_python_v0 as m  # noqa: E402

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
    out.append("FORMAT\t1")
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
    out.append("SECTION\tgeneric-lists")
    for p in sorted(doc.list_paths):
        items = doc.list_items(p)
        out.append("L\t%s\t%d" % (p, len(items)))
        for item in items:
            out.append("I\t%s" % item)

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

    os.makedirs(os.path.dirname(output), exist_ok=True)
    with open(output, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(out) + "\n")
    sys.stdout.write("wrote %d lines to %s\n" % (len(out), output))


if __name__ == "__main__":
    main()
