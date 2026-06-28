# TomSpecs Model Redesign — Public-Standards Re-grounding

**Status:** Proposal (for review — no code changed yet)
**Date:** 2026-06-28
**Scope:** `tom_ai/ai_build/tom_specs_model` (the specification object model rooted at `ProjectDefinition`)
**Decision inputs:** Public-standard naming · full restructure (rename + reorder + merge/split + completeness additions) · proposal-doc-first.

> **Legal note:** This proposal reduces *visible and structural* resemblance to the
> former client's HBSG / Pflichtenheft method by re-grounding the model on public
> standards (ISO/IEC/IEEE 29148, BABOK, ISO/IEC 25010, ISO/IEC/IEEE 42010). It is an
> engineering distancing exercise, **not** a legal clearance. A copyright/confidentiality
> determination should be confirmed with counsel.

---

## 1. Goal

Make the model **(a)** more complete and **(b)** clearly *inspired by* — not *derived from* —
HBSG. The three levers applied together are what break the visible lineage:

1. **Reframe** the lineage onto public standards (level 0).
2. **Rename** documents, sections and subsections (levels 1–3).
3. **Reorder / regroup** so the document narrative follows a public convention, not HBSG's
   work-step order — plus merge/split and add the missing pieces.

Renaming alone is insufficient: HBSG's identifying fingerprints are the *literal* `PD00-CUR`
/ `AS11` / `AS23` code scheme, the exact 14-section "Project Definition" lineup, and the
specific section order. All three must change.

---

## 2. Public lineage to anchor on (level 0)

Organise the suite into six **layers** whose names come straight from public RE/BA practice.
Anyone reading the result maps it to ISO 29148 / BABOK, not to HBSG.

| Layer | Public basis |
| --- | --- |
| L1 Context & Governance | ISO 29148 §6 front matter; BABOK Strategy Analysis |
| L2 Business Analysis (current + target) | BABOK current-/future-state |
| L3 Requirements | ISO/IEC/IEEE 29148 (SRS/SyRS) |
| L4 Solution Design | ISO/IEC/IEEE 42010 (architecture), ISO 9241 (UX) |
| L5 Quality & Acceptance | ISO/IEC 25010, ISO/IEC 25040 |
| L6 Delivery & Transition | ISO 29148 transition requirements; PMBOK phasing |

---

## 3. Rename the document suite (level 1)

Codes deliberately avoid every HBSG phase prefix (`PD`, `AS`, `DR`, `EK`, `SB`, `VP`).

| Current class (code) | New name | New code | Layer | Public anchor |
| --- | --- | --- | --- | --- |
| `ProjectDefinition` (PD) | **Solution Blueprint** | SBP | — (umbrella) | Concept/summary doc |
| `CurrentSituation` (CS) | **Current Landscape Assessment** | CLA | L2 | BABOK current-state |
| `BusinessProcesses` (BP) | **Target Operating Model** | TOM | L2 | BABOK future-state |
| `BusinessDataModel` (BDM) | **Information Model** | IFM | L2 | DAMA-DMBOK |
| `BusinessSystemInteractions` (BSI) | **Integration & Interface Specification** | IIS | L4 | 29148 interfaces |
| `UseCases` (UC) | **Interaction Scenarios** | ISC | L3 | Cockburn use cases |
| `UiPrototype` (UP) | **Experience Design Specification** | XDS | L4 | ISO 9241 |
| `RequirementsCatalog` (RC) | **Requirements Specification** | RSP | L3 | ISO 29148 SRS |
| `TechnicalRequirementsSpec` (TR) | **Architecture & Technology Specification** | ATS | L4 | ISO 42010 |
| `BusinessQualityPlan` (BQP) | **Quality & Acceptance Plan** | QAP | L5 | ISO 25010 |
| `ProjectPhasePlan` (PPP) | **Delivery Roadmap** | DRM | L6 | PMBOK phasing |
| `SystemRollout` (SR) | **Transition & Rollout Plan** | TRP | L6 | 29148 transition |
| `AuthorizationConcept` (AC) | **Security & Access Specification** | SAS | L4 | ISO 27001 |

---

## 4. Rebuild the master document (levels 2–3)

This is the largest distancer. The HBSG order buries the overview at position 4 and leads with
current-state + project organization. The public convention leads with **purpose/scope**, puts
**glossary** up front, and consolidates governance. Proposed `SolutionBlueprint` (SBP) sections:

| # | New section (code) | Replaces / merges (old PD section) | Notes |
| --- | --- | --- | --- |
| 1 | **Document Control** `SBP.1` | `DocumentHeader` (expanded) | + revision history + approvals (**new**) |
| 2 | **Introduction & Scope** `SBP.2` | `SystemOverview` | Moved to front; add goals/non-goals + out-of-scope |
| 3 | **Glossary & Abbreviations** `SBP.3` | — | **New** (top gap from prior review) |
| 4 | **Stakeholders & Governance** `SBP.4` | `Administrative` + `ProjectOrganizationAndProcess` | + stakeholder register (**new**) |
| 5 | **Current Landscape** `SBP.5` | `CurrentStateAnalysis` | → seeds CLA |
| 6 | **Assumptions, Constraints & Dependencies** `SBP.6` | scattered fields consolidated | **New** consolidated register |
| 7 | **Target Operating Model** `SBP.7` | `TargetBusinessProcessModel` + `OrganizationalFramework` | → seeds TOM |
| 8 | **Information & Data Model** `SBP.8` | `BusinessObjectAndDataModel` | → seeds IFM |
| 9 | **Requirements** `SBP.9` | `RequirementsOverview` | Functional + NFR → seeds RSP |
| 10 | **Interaction Scenarios** `SBP.10` | (UC seed in `TargetBusinessProcessModel`) | → seeds ISC |
| 11 | **Solution Architecture & Technology** `SBP.11` | `TechnicalFrameworkConcept` + `ComponentsToUse` | → seeds ATS |
| 12 | **Security & Access Model** `SBP.12` | `AccessAndAuthorizationConcept` | → seeds SAS |
| 13 | **Experience & Interface Design** `SBP.13` | `UserInterfaceDesign` | → seeds XDS |
| 14 | **Quality & Acceptance Model** `SBP.14` | `SystemQualityGoals` + `DeliveryScopeAndAcceptance` | ISO 25010 cross-map → seeds QAP |
| 15 | **Delivery, Transition & Rollout** `SBP.15` | `SystemStagePlan` + `SystemRolloutConcept` | → seeds DRM, TRP |

Net change vs. HBSG: same order of magnitude (15 sections) but **4 merges, 5 new/expanded
sections, and a fully re-sequenced narrative**. The outline is no longer recognisable as the
HBSG Project Definition.

### Level-3 regrouping highlights

- **Stakeholders & Governance (SBP.4)** absorbs the old `Administrative` (team, distribution,
  reference docs) and `ProjectOrganizationAndProcess` (governance, steering committee, RACI),
  and adds a **Stakeholder Register** (`stakeholderId, name, role, interest, influence,
  concerns, engagementStrategy`).
- **Assumptions, Constraints & Dependencies (SBP.6)** pulls together what is today split across
  `SystemOverview.risksAndAssumptions`, `BSI.boundaryAssumptions`, and
  `…frameworkConditions` into one register.
- **Quality & Acceptance Model (SBP.14)** cross-maps the four existing quality buckets
  (user / technical / operations / documentation) onto the **eight ISO/IEC 25010** product-quality
  characteristics so compatibility and portability cannot be missed.

---

## 5. Completeness additions (close the prior-review gaps)

| Addition | Lands in | New classes (proposed) |
| --- | --- | --- |
| Glossary / acronyms | SBP.3 | `Glossary`, `GlossaryEntry(term, definition, acronym, seeAlso)` |
| Stakeholder register | SBP.4 | `StakeholderRegister`, `StakeholderEntry(...)` |
| Revision history + approvals | SBP.1 | `RevisionHistory`, `RevisionEntry(version, date, author, summary)`, `ApprovalRecord(role, name, date, status)` |
| Assumptions/constraints register | SBP.6 | `AssumptionConstraintRegister`, `AssumptionEntry`, `ConstraintEntry` |
| ISO 25010 cross-map | SBP.14 | `Iso25010Coverage(characteristic, addressedBy, targetMetric)` |

---

## 6. Replace the identifier scheme

The `@SectionId('PD00-…')` / `AS##` codes are the most literal lift and must go.

- **Document codes:** the new 3-letter codes in §3 (`CLA`, `RSP`, `ATS`, …).
- **Section codes:** dotted, derived from the *new* names — `SBP.4`, `SBP.4.1` (stakeholder
  register), etc. No `PD00-` prefix, no `AS`/`DR`/`EK` numbering.
- **Item IDs:** keep the public conventions already in use — `REQ-NNN`, add `NFR-NNN`,
  `RISK-NNN`, `STK-NNN` (stakeholder), `ASM-NNN`/`CON-NNN` (assumption/constraint).
- Update the `@SectionId` annotation literals throughout `lib/src/**`.

---

## 7. Distancing checklist (purge the paper trail)

- [ ] Remove HBSG references in code comments — e.g. `bqp_business_quality_plan.dart`
      ("Replaces HBSG AS11 + AS23 + partial AS14 coverage") and any `@Comment`/doc-comment
      mentioning `AS##` or HBSG.
- [ ] Remove / relocate the literal source skeletons under
      `ztmp/step10_setup/.../quests/tom_specs/HBSG_skeletons/` and `Input/pflichtenheft_rahmen.*`
      out of the repo (they are the original method artifacts).
- [ ] Purge `_section_id_mapping.json` HBSG→model mapping or rewrite it against the new codes.
- [ ] Grep the whole workspace for `HBSG`, `Pflichtenheft`, `AS1`, `AS2`, `PD00-` and clear hits.
- [ ] Re-derive any doc examples/fixtures that quote HBSG section titles verbatim.

---

## 8. Class-level migration map (old → new)

Top-level document classes (rename class + `@SectionId` + `@Document(name:)`):

| Old class | New class |
| --- | --- |
| `ProjectDefinition` | `SolutionBlueprint` |
| `CurrentSituation` | `CurrentLandscapeAssessment` |
| `BusinessProcesses` | `TargetOperatingModel` |
| `BusinessDataModel` | `InformationModel` |
| `BusinessSystemInteractions` | `IntegrationInterfaceSpecification` |
| `UseCases` | `InteractionScenarios` |
| `UiPrototype` | `ExperienceDesignSpecification` |
| `RequirementsCatalog` | `RequirementsSpecification` |
| `TechnicalRequirementsSpec` | `ArchitectureTechnologySpecification` |
| `BusinessQualityPlan` | `QualityAcceptancePlan` |
| `ProjectPhasePlan` | `DeliveryRoadmap` |
| `SystemRollout` | `TransitionRolloutPlan` |
| `AuthorizationConcept` | `SecurityAccessSpecification` |

PD subsection classes (rename + re-home per §4):

| Old PD subsection class | New home (SBP §) | New class |
| --- | --- | --- |
| `CurrentStateAnalysis` | 5 | `CurrentLandscape` |
| `ProjectOrganizationAndProcess` + `Administrative` | 4 | `StakeholdersAndGovernance` |
| `SystemOverview` | 2 | `IntroductionAndScope` |
| `OrganizationalFramework` + `TargetBusinessProcessModel` | 7 | `TargetOperatingModelConcept` |
| `BusinessObjectAndDataModel` | 8 | `InformationAndDataModel` |
| `TechnicalFrameworkConcept` + `ComponentsToUse` | 11 | `SolutionArchitectureAndTechnology` |
| `AccessAndAuthorizationConcept` | 12 | `SecurityAndAccessModel` |
| `UserInterfaceDesign` | 13 | `ExperienceAndInterfaceDesign` |
| `SystemQualityGoals` + `DeliveryScopeAndAcceptance` | 14 | `QualityAndAcceptanceModel` |
| `SystemStagePlan` + `SystemRolloutConcept` | 15 | `DeliveryTransitionAndRollout` |
| *(none)* | 1 | `DocumentControl` |
| *(none)* | 3 | `GlossaryAndAbbreviations` |
| *(none)* | 6 | `AssumptionsConstraintsDependencies` |

Folder renames under `lib/src/`: drop the HBSG-style `xx_` prefixes
(`pd_project_definition/` → `solution_blueprint/`, `cs_current_situation/` →
`current_landscape_assessment/`, etc.).

---

## 9. Implementation plan (after approval)

1. **Branch + commit** current `tom_specs_model` state (scoped to this project only).
2. Rename folders + files under `lib/src/`; update the barrel exports in `tom_specs_model.dart`.
3. Rename classes, `@SectionId`, `@Document`, `@MapsTo`/`@DetailedIn` targets; re-sequence
   fields in `SolutionBlueprint` per §4.
4. Add the new completeness classes (§5).
5. Update `@SectionId` literals to the new scheme (§6).
6. Run the distancing checklist (§7); regenerate `spec_ops.g.dart` / any generated bridges.
7. Update `doc/*_outline.md` and `example/`, fixtures, and golden files.
8. `dart analyze` clean + `testkit :test` green (update snapshot/serialization tests).
9. Update `spec_writing_guide.md` wording conventions (modal verbs vs MoSCoW; 29148
   condition·subject·action·object·constraint form).

---

## 10. Open decisions for the user

1. **Umbrella name** — "Solution Blueprint" vs alternatives ("Solution Definition Dossier",
   "Specification Charter").
2. **Code for Delivery Roadmap** — `DRM` (proposed) is fine since it differs from HBSG's `DR`
   phase; confirm acceptable.
3. **Phase coverage** — HBSG spans VP→PD→AS→DR→EK→SB. The current model implements the
   AS/PD analysis core only. Do you want the redesign to *also* add public-standard equivalents
   for the later phases (detailed design, go-live/closure, service & operations), or keep the
   scope at analysis + requirements + high-level design as today?
