#!/usr/bin/env python3
"""Agreement suite for the generated Python metadata module
(``tom_som_python_v0_meta``, SOM §7.2/§8) — the Python port of the Dart
facade's ``test/generated_meta_test.dart``. Two guarantees over the *real*
committed model:

  1. EXHAUSTIVE TREE AGREEMENT — for every one of the document roots the
     generated static ``SomMetaTree`` is field-for-field identical (via
     ``som_meta_node_diff``) to the tree ``build_som_meta_tree`` derives from
     the committed ``meta/spec_model.meta.json`` at runtime. Since the emitter
     writes the dot-notation / ID-tree accessor paths from the same node walk,
     this also anchors every ``.path`` the accessors can produce.
  2. SURFACE AGREEMENT — the dot-notation entry points, the ID-tree entry
     points, and the dynamic ``by_path`` lookups all resolve to the *same*
     node instances for representative positions (root, nested section,
     content leaf, list, list element, hoisted id).

The root set comes from the generated ``SOM_META_ROOTS`` registry, not a
hand-list: adding a document root cannot leave this suite behind. That does not
make the coverage check circular — ``meta/spec_model.meta.json`` is written by
the model JSON exporter, a different code path from the meta emitter, so an
emitter that drops a root still shows up as a mismatch.

Run with ``python3 tests/som_v0_meta_test.py``; exit code 0 == all green.
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

from tom_som_runtime import (  # noqa: E402
    SpecModel,
    build_som_meta_tree,
    som_meta_node_diff,
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


#: Every generated per-root static tree, keyed by its root type — read from the
#: generated ``SOM_META_ROOTS`` registry rather than hand-listed, so a new
#: document root reaches this suite by regeneration instead of by recollection.
_GENERATED_TREES = {k: e.tree for k, e in m.SOM_META_ROOTS.items()}


def _model() -> SpecModel:
    path = os.path.join(_PROJECT, "meta", "spec_model.meta.json")
    with open(path, encoding="utf-8") as f:
        return SpecModel.from_json(json.load(f))


def test_generated_trees_agree_with_bridge(model: SpecModel) -> None:
    _check(
        "trees.covers-model-roots",
        set(_GENERATED_TREES) == {r.type for r in model.roots},
        str(sorted(_GENERATED_TREES)),
    )
    for root_type, tree in _GENERATED_TREES.items():
        bridge = build_som_meta_tree(model, root_type=root_type)
        diff = som_meta_node_diff(tree.root, bridge.root)
        _check(f"trees.agree.{root_type}", diff is None, diff or "")


def test_registry_entries_are_self_consistent() -> None:
    for key, e in m.SOM_META_ROOTS.items():
        _check(f"registry.key.{key}", e.type == key)
        _check(f"registry.nav-segment.{key}", e.nav.path == e.segment)
        _check(f"registry.id-segment.{key}", e.id.path == e.segment)
        _check(f"registry.nav-meta.{key}", e.nav.meta is e.tree.root)
        _check(f"registry.id-meta.{key}", e.id.meta is e.tree.root)


def test_dot_notation_surface() -> None:
    _check("dot.root", m.d00SolutionBlueprint.path == "SBP")
    _check(
        "dot.section",
        m.d00SolutionBlueprint.introductionAndScope.path
        == "SBP/introductionAndScope",
    )
    _check(
        "dot.leaf",
        m.d00SolutionBlueprint.requirements.content.path
        == "SBP/requirements/content",
    )
    _check(
        "dot.nested-leaf",
        m.d00SolutionBlueprint.introductionAndScope.goals.content.path
        == "SBP/introductionAndScope/goals/content",
    )

    # .meta resolves to the same node by_path finds.
    via_dot = m.d00SolutionBlueprint.introductionAndScope.meta
    via_path = m.d00SolutionBlueprintMetaTree.by_path(
        "SBP/introductionAndScope"
    )
    _check("dot.meta-is-by_path", via_dot is via_path)
    _check("dot.meta-member", via_dot.member_name == "introductionAndScope")

    # List positions expose item() with element accessors.
    revs = m.d00SolutionBlueprint.documentControl.revisionHistory
    _check(
        "dot.list",
        revs.path == "SBP/documentControl/RVENT-REVS-LST",
        revs.path,
    )
    _check(
        "dot.list-item",
        revs.item(3).path
        == "SBP/documentControl/RVENT-REVS-LST-3",
        revs.item(3).path,
    )
    # The list node's metadata carries the section-id pattern.
    _check("dot.list-pattern", revs.meta.section_id_pattern is not None)

    # A second root has its own entry point and segment.
    _check("dot.second-root", m.d01CurrentLandscapeAssessment.path != "SBP")
    _check(
        "dot.second-root-meta",
        m.d01CurrentLandscapeAssessment.meta
        is m.d01CurrentLandscapeAssessmentMetaTree.root,
    )


def test_id_tree_surface() -> None:
    # The Id root shares the dot root position.
    _check("id.root-path", m.SBP.path == m.d00SolutionBlueprint.path)
    _check("id.root-meta", m.SBP.meta is m.d00SolutionBlueprint.meta)

    # A hoisted list id agrees with the dot-notation position. RVENT_REVS_LST
    # is hoisted onto the root Id class through the id-less
    # documentControl/revisionHistory members.
    revs = m.d00SolutionBlueprint.documentControl.revisionHistory
    _check("id.hoisted-path", m.SBP.RVENT_REVS_LST.path == revs.path)
    _check("id.hoisted-meta", m.SBP.RVENT_REVS_LST.meta is revs.meta)
    _check(
        "id.hoisted-item",
        m.SBP.RVENT_REVS_LST.item(0).path == revs.item(0).path,
    )

    # Every root has a distinct Id entry point at its own segment.
    id_roots = {k: e.id for k, e in m.SOM_META_ROOTS.items()}
    _check("id.roots-cover", set(id_roots) == set(_GENERATED_TREES))
    for root_type, ref in id_roots.items():
        tree = _GENERATED_TREES[root_type]
        _check(
            f"id.segment.{root_type}",
            ref.path == tree.root.section_id,
            f"{ref.path} != {tree.root.section_id}",
        )
        _check(f"id.meta.{root_type}", ref.meta is tree.root)


def main() -> int:
    model = _model()
    test_generated_trees_agree_with_bridge(model)
    test_registry_entries_are_self_consistent()
    test_dot_notation_surface()
    test_id_tree_surface()

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
