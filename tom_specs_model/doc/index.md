# TomSpecs Documentation

This is the **single folder for all TomSpecs subject-matter documentation** —
the specification object model (SOM), the multi-language access API, the file
formats, the CodeSpecs mapping, the creation process and all tooling docs.
Documentation for tools that live in other projects (`tom_specs_clitool`,
`tom_som_conformance`, …) is here too; only per-project `README.md` files stay
with their projects.

Quest bookkeeping — progress logs, todo yamls, session trails — lives in
`_ai/quests/tom_specs/` and is deliberately **not** part of this folder.

---

## Start here

| Document | Read it when you need |
|----------|-----------------------|
| [som_mapping.md](som_mapping.md) | **The mapping authority.** How a DocSpecs markdown document, the `tom_specs_model` Dart classes and the cross-language SOM relate — field shapes, section IDs, annotations, headline/id storage, md + yaml serialization, schema generation, structural invariants. |
| [tom_specs_project_flow.md](tom_specs_project_flow.md) | **The process authority.** The eight phases from project idea to production, their inputs/outputs, quality gates, roles, iteration rules and upgrade cycles. |
| [codespecs_mapping.md](codespecs_mapping.md) | **The CodeSpecs authority.** The `Cs*` annotation family, the parts catalogue, per-part attribute surfaces, the `tom_core`-family basis, and the bidirectional DocSpecs↔CodeSpecs link. |

---

## Object model & guidelines

| Document | Subject |
|----------|---------|
| [som_mapping.md](som_mapping.md) | The single mapping authority (see above) |
| [tom_specs_som_guidelines.md](tom_specs_som_guidelines.md) | Consolidated SOM authoring guidelines — DocSpecs section model, field/list naming, id suffixes, multi-language API surface |
| [field_classification.md](field_classification.md) | Field classification rules and worked examples |
| [form_decomposition.md](form_decomposition.md) | When a form section decomposes into sub-sections |
| [section_id_pattern_plan.md](section_id_pattern_plan.md) · [section_id_pattern_plan_decisions.md](section_id_pattern_plan_decisions.md) | The `@SectionIdPattern` campaign — plan and decisions log |
| [field_suffix_list_id_plan.md](field_suffix_list_id_plan.md) | Field-name-derived suffixes for list section IDs |
| [same_type_sibling_lists_analysis.md](same_type_sibling_lists_analysis.md) | Same-type sibling `List<T>` fields and section-ID collision |

## Multi-language access API

| Document | Subject |
|----------|---------|
| [multiplatform_spec_model.md](multiplatform_spec_model.md) | Why the SOM is generated into nine languages; the `v0` facade / runtime split |
| [som_language_packaging_plan.md](som_language_packaging_plan.md) · [som_language_packaging_plan_decisions.md](som_language_packaging_plan_decisions.md) | Making each language library easy to integrate downstream |
| [som_toolchains.md](som_toolchains.md) | Per-language build and verify toolchains for the nine runtimes |

## File formats

| Document | Subject |
|----------|---------|
| [som_mapping.md](som_mapping.md) | Normative md + yaml serialization of every construct |
| [som_file_mapping.md](som_file_mapping.md) | Conformance file mapping — redirect stub into `som_mapping.md` |
| [comments_annotations_rules.md](comments_annotations_rules.md) | Comment/annotation rules — redirect stub into `som_mapping.md` |
| [spec_model_meta_schema.md](spec_model_meta_schema.md) | Schema of the generated `spec_model.meta.json` |

## CodeSpecs

| Document | Subject |
|----------|---------|
| [codespecs_mapping.md](codespecs_mapping.md) | The single CodeSpecs document — pillars (§1.1), glossary (§1.2), parts catalogue (§4), per-part gap analysis and attribute surfaces (§5), server contract (§7), SOM→CodeSpecs derivation (§8), the bidirectional link (§9), open work index (§10), config/architecture (§11–§12) |

## Process, editor & agent tooling

| Document | Subject |
|----------|---------|
| [tom_specs_project_flow.md](tom_specs_project_flow.md) | The eight-phase creation process (authority) |
| [guidelines_specification.md](guidelines_specification.md) | Authoring D4rt scripts that process a TomSpecs document |
| [d4rt_and_llm_tools.md](d4rt_and_llm_tools.md) | D4rt scripting and LLM tooling for the editor |
| [tom_specs_editor_specification.md](tom_specs_editor_specification.md) · [tom_specs_editor_specification_plan.md](tom_specs_editor_specification_plan.md) | The spec-authoring app and its follow-up items |

## CLI tooling

| Document | Tool |
|----------|------|
| [specs_model_outliner.md](specs_model_outliner.md) | `tom_specs_clitool/bin/outliner.dart` — notation, type expansion, output |
| [spec_object_model_config.md](spec_object_model_config.md) | `tom_som.yaml` — the SOM generator configuration |
| [analyzer_wo_sdk.md](analyzer_wo_sdk.md) | Running the Dart analyzer without a full SDK checkout |

## Generated documentation

Generated documents live **outside this folder**, under
`tom_specs_model/generated-doc/<type>/`, so a stray generator run can never
leave a stale copy sitting among the hand-written docs.

| Folder | Contents | Regenerate with |
|--------|----------|-----------------|
| [../generated-doc/outlines/](../generated-doc/outlines/index.md) | One outline per document root (D00–D13) plus the whole-model `DocSpecsProject` outline, rendered from the live Dart model | `tom_specs_clitool/tool/regenerate_outlines.sh` |

Never edit anything under `generated-doc/` by hand — re-run the generator and
commit the diff.
