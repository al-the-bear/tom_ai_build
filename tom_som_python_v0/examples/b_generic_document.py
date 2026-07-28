#!/usr/bin/env python3
"""Sample (b) — GENERIC in-memory document access (som_multiplatform_spec_model.md §6).

HAND-AUTHORED — preserved across ``generate_som`` runs.

Demonstrates editing the *same* document shape as sample (a) using ONLY the
generic ``tom_som_runtime`` — string paths, no generated typed classes. This is
the language-independent core: a sparse, path-keyed store plus the list and
serialization helpers. Anything the typed facade can express is expressible
here; the typed facade just makes it type-safe and discoverable.

Run from this package:  python3 examples/b_generic_document.py
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
sys.path.insert(0, _PROJECT)

from tom_som_runtime import SpecDocument, yaml_encode  # noqa: E402

# The generated metadata module: the codec walks the document against the
# root's populated metadata tree (SOM §8).
from tom_som_python_v0_meta import d00SolutionBlueprintMetaTree  # noqa: E402


def main() -> int:
    doc = SpecDocument()

    # Content leaves are addressed by their full path from the root segment.
    doc.set_content(
        "SBP/content",
        "A platform that unifies our fragmented order systems.",
    )
    doc.set_content(
        "SBP/currentLandscape/content",
        "Three legacy systems with no shared customer record.",
    )

    # A list: append items (each call returns the new item's path), then set a
    # content leaf under each. The list path mirrors the typed facade's
    # ``operationalMetrics`` accessor.
    list_path = "SBP/currentLandscape/CUOPME-OPER-LST"
    item0 = doc.add_list_item(list_path)
    doc.set_content(f"{item0}/content", "Average order turnaround: 4.2 days.")
    item1 = doc.add_list_item(list_path)
    doc.set_content(f"{item1}/content", "Manual reconciliation: ~12 hours / week.")

    # Read back generically.
    print(f"SBP/content = {doc.content('SBP/content')}")
    print(f"list item count = {doc.list_item_count(list_path)}")
    for item_path in doc.list_items(list_path):
        print(f"  {item_path}/content = {doc.content(f'{item_path}/content')}")

    # The whole document serializes losslessly to JSON …
    print("\nDocument JSON:")
    print(json.dumps(doc.to_json(), indent=2, sort_keys=True))

    # … and to the canonical hierarchical YAML wire format (walked against the
    # generated metadata tree, stamped with the model version).
    print("\nDocument YAML:")
    print(yaml_encode(doc, d00SolutionBlueprintMetaTree, model_version="1.0"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
