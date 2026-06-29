#!/usr/bin/env python3
"""Sample (c) — REFLECTION / meta-information access (plan item #14, spec §3.1).

HAND-AUTHORED — preserved across ``generate_som`` runs.

Demonstrates the value-free "reflection" surface: load the exported meta-data
(``meta/spec_model.meta.json``, the lossless class graph) into a ``SpecModel``
and query its shape with ``SpecReflection`` — enumerate roots and fields, and
resolve a concrete document *path* to the model node it lands on. No document
values are involved; this answers "what CAN the model hold?", not "what does a
given document hold?".

Run from this package:  python3 examples/c_reflection_metadata.py
"""

from __future__ import annotations

import json
import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PROJECT = os.path.dirname(_HERE)  # tom_som_python_v0


def _add_runtime_path() -> None:
    toml = os.path.join(_PROJECT, "pyproject.toml")
    rel = re.search(
        r'runtime-path\s*=\s*"([^"]+)"',
        open(toml, encoding="utf-8").read(),
    ).group(1)
    module_dir = os.path.normpath(os.path.join(_PROJECT, rel))
    sys.path.insert(0, os.path.dirname(module_dir))


_add_runtime_path()

from tom_som_runtime import SpecModel, SpecReflection  # noqa: E402


def main() -> int:
    # The meta-data shipped in this package, relative to this script, so the
    # sample runs from any working directory.
    meta_path = os.path.join(_PROJECT, "meta", "spec_model.meta.json")
    with open(meta_path, encoding="utf-8") as fh:
        model = SpecModel.from_json(json.load(fh))
    reflection = SpecReflection(model)

    print(
        f"Model version: {model.model_version} "
        f"({model.model_version_label or 'unstamped'})"
    )
    roots = list(reflection.roots)
    print(f"Roots: {len(roots)}, classes: {len(list(reflection.classes))}\n")

    # Enumerate the document roots by their addressable segment.
    print("Document roots:")
    for root in roots:
        print(f"  {reflection.root_segment(root):<4} {root.title}")

    # Inspect the fields of the D00SolutionBlueprint root class.
    pd_root = reflection.root_for_segment("SBP")
    pd_fields = reflection.fields_of(pd_root.type)
    print(f"\nFirst fields of {pd_root.type} ({len(pd_fields)} total):")
    for field in pd_fields[:6]:
        extra = ""
        if field.type is not None:
            extra += f"  type={field.type}"
        if field.element_type is not None:
            extra += f"  elem={field.element_type}"
        print(f"  {field.name:<24} kind={field.kind.value}{extra}")

    # Resolve concrete document paths to model nodes (value-free).
    print("\nPath resolution:")
    for path in (
        "SBP",
        "SBP/content",
        "SBP/currentLandscape",
        "SBP/currentLandscape/CUOPME-OPER-LST",
    ):
        res = reflection.resolve(path)
        if res is None:
            print(f"  {path}  ->  (unresolved)")
            continue
        cls = f"  class={res.target_class.name}" if res.target_class else ""
        print(
            f"  {path:<40} -> kind={res.kind.value}{cls}"
            f"  value_leaf={res.is_value_leaf}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
