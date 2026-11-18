#!/usr/bin/env python3
"""TomSpecs sample — author a Solution Blueprint end to end (Python).

The Python port of ``../bin/author_solution_blueprint.dart``: the same six
steps, the same document, the same output (``../expected_output.txt``).

Run (from this folder; see README.md for the install)::

    python3 main.py

Six steps, in the order a real authoring task takes them:

  1. open a fresh document and a typed root
  2. author a small but coherent Solution Blueprint
  3. serialise both renditions — yaml (SOM §12) and markdown (SOM §11)
  4. round-trip the yaml back through the one-call typed loader and prove
     the reload is equal to what was written
  5. validate on the instance tier
  6. break one rule deliberately and read the diagnostic

This sample is the NARRATIVE. The individual access styles each have their
own focused example in the facade package (``tom_som_python_v0/examples/``),
and this does not re-explain them.
"""

from __future__ import annotations

import os

from tom_som_runtime import SpecDocument, validate_document, yaml_encode
from tom_som_python_v0 import D00SolutionBlueprint, d00SolutionBlueprintMetaTree
from tom_som_python_v0_data import spec_model


def main() -> int:
    out_dir = "build"
    os.makedirs(out_dir, exist_ok=True)

    # -------------------------------------------------------------- step 1
    # A typed root over a fresh, empty document. Constructing the root also
    # runs the instantiation-time model-version check (SOM §4.2): an
    # unstamped document is editable, a document from a newer model is
    # refused.
    doc = SpecDocument()
    sbp = D00SolutionBlueprint(doc)

    print("1. A typed root over an empty document")
    print(f"   object model version : {sbp.object_model_version}")
    print(f"   root path            : {sbp.path}")
    print("")

    # -------------------------------------------------------------- step 2
    # Author. Every write below goes through a NAMED accessor — no string
    # paths — and lands in the same path-keyed store the generic API reads.
    print("2. Authoring, printing each section id as it is written")

    sbp.content = "Unify three legacy order systems behind one customer record."
    _wrote(sbp.path, "the blueprint itself")

    intro = sbp.introductionAndScope
    intro.content = "Replace per-region order intake with a single pipeline."
    _wrote(intro.path, "introduction and scope")

    landscape = sbp.currentLandscape
    landscape.content = (
        "Three systems, no shared customer record, manual reconciliation."
    )
    _wrote(landscape.path, "the current landscape")

    # A list section. `add()` appends an item and returns it typed.
    metrics = landscape.operationalMetrics
    metrics.add().content = "Average order turnaround: 4.2 days."
    metrics.add().content = "Manual reconciliation: about 12 hours a week."
    _wrote(metrics.list_path, f"{metrics.length} operational metrics")

    print("")

    # -------------------------------------------------------------- step 3
    # Both renditions of the same document. They are two encodings of one
    # store, not two documents — which is why step 4 can round-trip either.
    #
    # `to_markdown` and the validator both need a whole SpecModel; the
    # facade's data module reads the one it ships (SOM §10.3).
    model = spec_model()

    yaml = yaml_encode(
        doc, d00SolutionBlueprintMetaTree, model_version=model.model_version_string
    )
    markdown = doc.to_markdown(model, root_type="D00SolutionBlueprint")

    _write(os.path.join(out_dir, "blueprint.docspecs.yaml"), yaml)
    _write(os.path.join(out_dir, "blueprint.md"), markdown)

    print("3. Serialised both renditions into build/")
    print(f"   blueprint.docspecs.yaml : {_lines(yaml)} lines  (SOM §12)")
    print(f"   blueprint.md            : {_lines(markdown)} lines  (SOM §11)")
    print("")

    # -------------------------------------------------------------- step 4
    # The one-call typed loader: decode, apply the document's own authoring
    # stamp, and hand back a typed root. Re-encoding the reload and comparing
    # the two strings is the actual proof — comparing field by field would
    # only prove the fields somebody thought to compare.
    reloaded = D00SolutionBlueprint.load_file(
        os.path.join(out_dir, "blueprint.docspecs.yaml")
    )
    re_yaml = yaml_encode(
        reloaded.doc,
        d00SolutionBlueprintMetaTree,
        model_version=model.model_version_string,
    )

    print("4. Round-tripped the yaml through D00SolutionBlueprint.loadFile")
    print(f"   reload equals original  : {_bool(re_yaml == yaml)}")
    print(
        "   a value read back typed : "
        f'"{reloaded.currentLandscape.operationalMetrics[0].content}"'
    )
    print("")

    # -------------------------------------------------------------- step 5
    errors = validate_document(model, doc)
    print("5. Instance-tier validation")
    print(f"   violations              : {len(errors)}")
    print("")

    # -------------------------------------------------------------- step 6
    # What a violation looks like. Writing to a path the model does not
    # declare is the clearest break to stage: the store accepts it — it is a
    # plain path-keyed map — and the validator is what notices.
    broken = SpecDocument.from_yaml(yaml, d00SolutionBlueprintMetaTree)
    broken.set_content("SBP/noSuchSection/content", "not part of the model")

    broken_errors = validate_document(model, broken)
    print("6. The same document with one rule deliberately broken")
    print(f"   violations              : {len(broken_errors)}")
    for e in broken_errors:
        print(f"   {e.code.value}: {e.path}")
        print(f"     {e.message}")
    print("")
    print("Done. The two renditions are in build/.")
    return 0


def _wrote(path: str, what: str) -> None:
    """Prints the section id a write landed under.

    The ids are the document's addressing system — the same tokens appear in
    the yaml keys and in the markdown ``<!--[ID]-->`` comments — so the sample
    shows them rather than describing them.
    """
    print(f"   {path.ljust(46)} {what}")


def _lines(s: str) -> int:
    return len(s.rstrip().split("\n"))


def _bool(b: bool) -> str:
    """Dart prints a bool lower-case; the expected output is the Dart one."""
    return "true" if b else "false"


def _write(path: str, text: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


if __name__ == "__main__":
    raise SystemExit(main())
