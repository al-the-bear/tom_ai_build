#!/usr/bin/env python3
"""Data-file resolution suite for the generated ``tom_som_python_v0_data``
module — the wheel-data contract.

HAND-AUTHORED — preserved across ``generate_som`` runs.

The distribution ships two data trees beside the code: the lossless
object-model meta-data (``meta/spec_model.meta.json``) and the DocSpecs
schemas (``schemas/**``). Installed wheels carry them as the mapped data
packages ``tom_som_python_v0_meta_data`` / ``tom_som_python_v0_schemas``;
a checkout carries them as plain sibling directories. The generated
``tom_som_python_v0_data`` resolution module hides that difference behind
``spec_model_meta_path()`` and ``schemas_root()``. This suite holds that
contract against the real committed tree:

  1. ``spec_model_meta_path()`` resolves to an existing file that JSON-loads
     into a runtime ``SpecModel`` with roots and classes.
  2. ``schemas_root()`` resolves to an existing directory that contains at
     least one ``*.yaml`` DocSpecs schema (recursively).

Run with ``python3 tests/som_v0_data_files_test.py``; exit code 0 == green.
"""

from __future__ import annotations

import json
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

from tom_som_runtime import SpecModel  # noqa: E402
from tom_som_python_v0_data import (  # noqa: E402
    schemas_root,
    spec_model_meta_path,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def test_meta_path_resolves_and_loads() -> None:
    path = spec_model_meta_path()
    _check("meta path exists", os.path.isfile(path), path)
    _check(
        "meta path names the meta file",
        os.path.basename(path) == "spec_model.meta.json",
        path,
    )
    with open(path, encoding="utf-8") as fh:
        model = SpecModel.from_json(json.load(fh))
    _check("model has roots", len(list(model.roots)) > 0)
    _check("model has classes", len(model.classes) > 0)


def test_schemas_root_resolves_with_schemas() -> None:
    root = schemas_root()
    _check("schemas root exists", os.path.isdir(root), root)
    yaml_files = [
        os.path.join(dirpath, name)
        for dirpath, _dirs, names in os.walk(root)
        for name in names
        if name.endswith(".yaml")
    ]
    _check("schemas root holds >=1 yaml schema", len(yaml_files) > 0, root)


def main() -> int:
    test_meta_path_resolves_and_loads()
    test_schemas_root_resolves_with_schemas()
    if _failed:
        print(f"FAILED ({len(_failed)}), passed {_passed}:")
        for item in _failed:
            print(f"  - {item}")
        return 1
    print(f"OK: {_passed} checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
