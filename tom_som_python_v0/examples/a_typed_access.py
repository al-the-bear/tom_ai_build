#!/usr/bin/env python3
"""Sample (a) — TYPED object-model access (plan item #14, spec §3.1).

HAND-AUTHORED — preserved across ``generate_som`` runs (the generator only
rewrites the module, meta/, schemas/ and pyproject.toml).

Demonstrates editing a TomSpecs document through the generated *typed* facade
``tom_som_python_v0``: named properties, nested-section navigation, and the
typed ``SomList`` collection. The typed facade is a thin editing surface over a
generic ``SpecDocument`` — every typed write lands in the same path-keyed store
the generic API (sample b) reads, which the closing lines prove.

Run from this package:  python3 examples/a_typed_access.py
"""

from __future__ import annotations

import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PROJECT = os.path.dirname(_HERE)  # tom_som_python_v0


def _add_paths() -> None:
    """Put the generic runtime (from ``pyproject.toml``) and this project on
    ``sys.path`` so ``tom_som_runtime`` and ``tom_som_python_v0`` both import."""
    toml = os.path.join(_PROJECT, "pyproject.toml")
    rel = re.search(
        r'runtime-path\s*=\s*"([^"]+)"',
        open(toml, encoding="utf-8").read(),
    ).group(1)
    module_dir = os.path.normpath(os.path.join(_PROJECT, rel))
    sys.path.insert(0, os.path.dirname(module_dir))
    sys.path.insert(0, _PROJECT)


_add_paths()

from tom_som_runtime import SpecDocument  # noqa: E402
import tom_som_python_v0 as m  # noqa: E402


def main() -> int:
    # A typed root over a fresh, empty document. The constructor also runs the
    # §2.2 instantiation-time version check (an unstamped document is editable).
    doc = SpecDocument()
    pd = m.ProjectDefinition(doc)

    print(f"Model version of this typed facade: {pd.object_model_version}")
    print(f"Root path: {pd.path}\n")

    # 1) A content leaf directly on the root.
    pd.content = "A platform that unifies our fragmented order systems."

    # 2) Navigate into a nested complex section and edit its own content leaf.
    csa = pd.currentStateAnalysis
    csa.content = "Three legacy systems with no shared customer record."

    # 3) The typed collection API: append two list items and edit each.
    metrics = csa.operationalMetrics
    metrics.add().content = "Average order turnaround: 4.2 days."
    metrics.add().content = "Manual reconciliation: ~12 hours / week."

    # Read everything back through the typed properties.
    print(f"PD.content              = {pd.content}")
    print(f"PD.currentStateAnalysis = {csa.content}")
    print(f"operationalMetrics.length = {metrics.length}")
    for i in range(metrics.length):
        print(f"  metric[{i}] = {metrics[i].content}")

    # The typed path is the generic path: the same data is addressable through
    # the generic document API (this is exactly what sample (b) uses).
    print(
        f'\nSame value via the generic path '
        f'(doc.content("{csa.path}/content")):'
    )
    print(f"  {doc.content(f'{csa.path}/content')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
