# tom_specs_model — package documentation

**This folder is the package tier**: how to use `tom_specs_model`'s *code* —
authoring a model class in Dart, the container root and its fourteen entry
points, and the snapshot and serialization engine.

It sits inside a `doc/` folder that also hosts the **subject-matter tier** — the
fourteen TomSpecs authorities catalogued by [`../index.md`](../index.md). The
two are kept in separate folders so a reader can tell at a glance which tier a
file belongs to
([`tom_specs_documentation_standard.md`](../tom_specs_documentation_standard.md)
§3.1). Documents here cite those authorities rather than restating them
(`tom_specs_documentation_standard.md` §1.2).

## Guides

| Document | Covers |
|----------|--------|
| [authoring_a_section_class.md](authoring_a_section_class.md) | Writing a model class: the shape it must have, the three member kinds, adding a member, adding a class, and the stamp/regenerate/outline sequence that must follow |
| [document_roots.md](document_roots.md) | `DocSpecsProject`, the fourteen entry points, the master and its thirteen projections, the two save paths, and the connect pass |
| [snapshot_and_serialization.md](snapshot_and_serialization.md) | The per-class contract, `SpecSlot`, the two ways to supply it, copy-on-write snapshotting, the projection onto the wire format, and the generated registry |

## API reference

| Document | Covers |
|----------|--------|
| [../api/api_summary_index.md](../api/api_summary_index.md) | The index of the per-module API summaries |
| [../api/api_summary_document_roots.md](../api/api_summary_document_roots.md) | `DocSpecsProject` and the fourteen roots |
| [../api/api_summary_common.md](../api/api_summary_common.md) | `DocumentHeader`, authorization requirements, the shared enums |
| [../api/api_summary_snapshot.md](../api/api_summary_snapshot.md) | The snapshot contract and the snapshotter |
| [../api/api_summary_serialization.md](../api/api_summary_serialization.md) | `SpecProjection`, `SpecYaml`, `connectProjection` |

The ~3000 per-section classes are catalogued by the generated outlines under
[`../../generated-doc/outlines/`](../../generated-doc/outlines), not by a
hand-kept summary.

## Where to start

- **Adding or changing a section?**
  [authoring_a_section_class.md](authoring_a_section_class.md) — and note the
  three commands that must follow the edit.
- **Loading, saving or navigating a specification?**
  [document_roots.md](document_roots.md). The short version: construct one
  `DocSpecsProject` and work through it.
- **Building undo, or debugging a save?**
  [snapshot_and_serialization.md](snapshot_and_serialization.md), particularly
  the two contract must-nots — they are the two failures that are silent.

## Beyond this package

| Where | What it decides |
|-------|-----------------|
| [`../tom_specs_model_rules.md`](../tom_specs_model_rules.md) | Model layout, field shapes, section ids, annotations, and the structural invariants the validator enforces |
| [`../som_multiplatform_spec_model.md`](../som_multiplatform_spec_model.md) | How this model becomes nine language runtimes, and how every construct serializes |
| [`../index.md`](../index.md) | The catalogue of the whole subject-matter tier, and the `§` citation convention |
