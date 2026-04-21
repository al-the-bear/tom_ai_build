# TomSpecs Model — Document Outlines

Generated outlines for all TomSpecs document root types.
Each outline is produced by `tom_specs_clitool/bin/outliner.dart` from the
live Dart model in `tom_specs_model/lib/src/`.

To regenerate all outlines, run from `tom_specs_clitool/`:

```
dart run bin/outliner.dart --package ../tom_specs_model --root-type <ClassName> \
  -o ../tom_specs_model/doc/<ClassName>_outline.txt
```

---

## Document Outlines

| ID  | Document | Root Class | Description | Outline |
|-----|----------|------------|-------------|---------|
| PD  | Project Definition | `ProjectDefinition` | Comprehensive specification covering all aspects of the system: current state, organizational framework, business processes, data models, technical framework, security, and UI design. Master document — all others `basedOn` PD. | [outline](ProjectDefinition_outline.txt) |
| BSI | Business System Interactions | `BusinessSystemInteractions` | Complete specification of interactions between the target system and external systems — inventory, patterns, testing, dependencies, migration, operations, and error handling. | [outline](BusinessSystemInteractions_outline.txt) |
| BP  | Business Processes | `BusinessProcesses` | Target business process specification — vision, design principles, catalog, diagrams, improvements, relationships, workflows, cross-process analysis, exceptions, and KPIs. | [outline](BusinessProcesses_outline.txt) |
| BDM | Business Data Model | `BusinessDataModel` | Complete business data model — entities, relationships, data classification, business objects, functions, rules, dictionary, and validation/integrity constraints. | [outline](BusinessDataModel_outline.txt) |
| BQP | Business Quality Plan | `BusinessQualityPlan` | Business-facing quality plan — quality framework, user/technical/operations/documentation criteria, prioritization, acceptance criteria, test strategy, and acceptance plan. | [outline](BusinessQualityPlan_outline.txt) |
| CS  | Current Situation | `CurrentSituation` | Detailed analysis of current systems and processes the target system will replace — landscape, pain points, metrics, risks, replacement inventory, and migration considerations. | [outline](CurrentSituation_outline.txt) |
| AC  | Authorization Concept | `AuthorizationConcept` | Complete access and authorization specification — user management, authentication, resource protection, authorization, encryption, audit, role matrix, and compliance framework. | [outline](AuthorizationConcept_outline.txt) |
| TR  | Technical Requirements | `TechnicalRequirementsSpec` | Comprehensive technical requirements — platform, software design, standard software, hardware, operations, communication, system operation, security, architecture, components, framework conditions, and translation handling. | [outline](TechnicalRequirementsSpec_outline.txt) |
| SR  | System Rollout | `SystemRollout` | End-to-end rollout specification — localization, translation, documentation and training, rollout plan, migration plan, user manuals, training materials, pilot, cutover, knowledge transfer, and warranty/support. | [outline](SystemRollout_outline.txt) |
| PPP | Project Phase Plan | `ProjectPhasePlan` | Comprehensive project phase plan — staging strategy, stages, feature prioritization, migration, gates, decisions, initial development flow, and upgrade cycle framework. | [outline](ProjectPhasePlan_outline.txt) |
| UC  | Use Cases | `UseCases` | Use cases derived from target process steps and actor interactions — catalog, scenarios, diagrams, end-to-end test scenarios, and traceability. | [outline](UseCases_outline.txt) |
| UP  | UI Prototype | `UiPrototype` | Full UI design and prototype specification — vision, screens, flow, print, errors, help, accessibility, responsive design, components, language selection, prototype, and wireframes/mockups. | [outline](UiPrototype_outline.txt) |
| RC  | Requirements Catalog | `RequirementsCatalog` | Complete requirements catalog — functional, technical, security, organizational — with traceability, relationships, and coverage against goals, use cases, and tests. | [outline](RequirementsCatalog_outline.txt) |

---

## Other Documents in This Folder

| File | Purpose |
|------|---------|
| [specs_model_outliner.md](specs_model_outliner.md) | Design rules for the TomSpecs object model (§6–§8) — section IDs, annotations, structural invariants |
| [field_classification.md](field_classification.md) | Field classification rules and examples |
| [form_decomposition.md](form_decomposition.md) | Form decomposition guidelines |
| [nested_lists_remodeling.md](nested_lists_remodeling.md) | Nested list remodeling patterns |
| [pd_project_definition_model.md](pd_project_definition_model.md) | Project Definition model documentation |
| [pd_template_model_update.md](pd_template_model_update.md) | PD template model update notes |
| [second_wave_documents.md](second_wave_documents.md) | Second-wave document planning |
