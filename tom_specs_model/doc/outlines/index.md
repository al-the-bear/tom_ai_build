# TomSpecs Model — Document Outlines

Generated outlines for all TomSpecs document root types.
Each outline is produced by `tom_specs_clitool/bin/outliner.dart` from the
live Dart model in `tom_specs_model/lib/src/`.

To regenerate **all** outlines at once, run the canonical batch script from
`tom_specs_clitool/` (this is the drift-proof entry point — re-run it after any
model-shape change and commit the diff):

```
./tool/regenerate_outlines.sh
```

To regenerate a single outline, run from `tom_specs_clitool/` with the document
root class (the `D<nn>…` `@Document` class name — e.g. `D04RequirementsSpecification`):

```
dart run bin/outliner.dart --package ../tom_specs_model --root-type <DnnClassName> \
  -o ../tom_specs_model/doc/outlines/<Stem>_outline.md
```

Add `--stop-at-detailed-in` (short: `-c`) to stop expansion at `@DetailedIn` boundaries and emit a compact outline:

```
dart run bin/outliner.dart --package ../tom_specs_model --root-type D00SolutionBlueprint \
  --stop-at-detailed-in \
  -o ../tom_specs_model/doc/outlines/SolutionBlueprint_compact_outline.md
```

---

## Document Outlines

| ID  | Document | Root Class | Description | Outline |
|-----|----------|------------|-------------|---------|
| SBP | Solution Blueprint | `D00SolutionBlueprint` | Comprehensive specification covering all aspects of the system from current landscape through target operating model, information model, solution architecture, security, experience design, quality & acceptance, and delivery / transition planning. Master document — all others `basedOn` SBP. | [outline](SolutionBlueprint_outline.md) |
| SBP | Solution Blueprint *(compact)* | `D00SolutionBlueprint` | Same as above but tree traversal stops at `@DetailedIn` boundaries — each such section shows a `→ DocId` marker instead of expanding its sub-tree. | [outline](SolutionBlueprint_compact_outline.md) |
| CLA | Current Landscape Assessment | `D01CurrentLandscapeAssessment` | Detailed analysis of the current systems and processes the target system will replace — landscape, pain points, metrics, risks, replacement inventory, and migration considerations. | [outline](CurrentLandscapeAssessment_outline.md) |
| TOM | Target Operating Model | `D02TargetOperatingModel` | Target business process specification — vision, design principles, catalog, diagrams, improvements, relationships, workflows, cross-process analysis, exceptions, and KPIs. | [outline](TargetOperatingModel_outline.md) |
| IFM | Information Model | `D03InformationModel` | Complete business data model — entities, relationships, data classification, business objects, functions, rules, dictionary, and validation/integrity constraints. | [outline](InformationModel_outline.md) |
| RSP | Requirements Specification | `D04RequirementsSpecification` | Complete requirements catalog — functional, technical, security, organizational — with traceability, relationships, and coverage against goals, use cases, and tests. | [outline](RequirementsSpecification_outline.md) |
| IIS | Integration & Interface Specification | `D07IntegrationInterfaceSpecification` | Complete specification of interactions between the target system and external systems — inventory, patterns, testing, dependencies, migration, operations, and error handling. | [outline](IntegrationInterfaceSpecification_outline.md) |
| ISC | Interaction Scenarios | `D05InteractionScenarios` | Use cases derived from the target process steps and actor interactions — catalog, scenarios, diagrams, end-to-end test scenarios, and traceability. | [outline](InteractionScenarios_outline.md) |
| ATS | Architecture & Technology Specification | `D06ArchitectureTechnologySpecification` | Comprehensive technical requirements — platform, software design, standard software, hardware, operations, communication, system operation, security, architecture, components, framework conditions, and translation handling. | [outline](ArchitectureTechnologySpecification_outline.md) |
| SAS | Security & Access Specification | `D08SecurityAccessSpecification` | Complete access and authorization specification — user management, authentication, resource protection, authorization, encryption, audit, role matrix, and compliance framework. | [outline](SecurityAccessSpecification_outline.md) |
| XDS | Experience Design Specification | `D09ExperienceDesignSpecification` | Full UI design and prototype specification — vision, screens, flow, print, errors, help, accessibility, responsive design, components, language selection, prototype, and wireframes/mockups. | [outline](ExperienceDesignSpecification_outline.md) |
| QAP | Quality & Acceptance Plan | `D10QualityAcceptancePlan` | Business-facing quality plan — quality framework, user / technical / operations / documentation criteria, prioritization, acceptance criteria, test strategy, and the full acceptance plan (criteria, process, UAT, defects, sign-off, warranty). | [outline](QualityAcceptancePlan_outline.md) |
| DRM | Delivery Roadmap | `D11DeliveryRoadmap` | Comprehensive project phase plan — staging strategy, stages, feature prioritization, migration, gates, decisions, initial development flow, and upgrade cycle framework. | [outline](DeliveryRoadmap_outline.md) |
| TRP | Transition & Rollout Plan | `D12TransitionRolloutPlan` | End-to-end rollout specification — localization, translation, documentation and training, rollout plan, migration plan, user manuals, training materials, pilot, cutover, knowledge transfer, and warranty/support. | [outline](TransitionRolloutPlan_outline.md) |

---

## Other Documents in This Folder

| File | Purpose |
|------|---------|
| [specs_model_outliner.md](../specs_model_outliner.md) | Design rules for the TomSpecs object model (§6–§8) — section IDs, annotations, structural invariants |
| [field_classification.md](../field_classification.md) | Field classification rules and examples |
| [form_decomposition.md](../form_decomposition.md) | Form decomposition guidelines |
