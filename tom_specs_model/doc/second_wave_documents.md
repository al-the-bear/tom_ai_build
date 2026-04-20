# Second-Wave Documents: PD00 → Phase 3 DocSpec Class Mapping

**Purpose:** Plan the Dart object-model classes for the 12 Phase 3 DocSpec documents that are derived from the PD00 Project Definition. For each target document this note identifies the PD00 subtrees that become its top-level entries, at the shallowest depth at which the subtree below flows to a single target.

**Sources consulted:**
- `_ai/quests/tom_specs/hbsg_tom_resulttype_mapping.md` (v3.5 — the authoritative mapping)
- `_ai/quests/tom_specs/documentation_flow_tomspecs.md` (flow diagrams)
- `tom_specs_model/lib/src/pd_project_definition/*.dart` (current object model — the ground truth for section IDs and nesting)

**Scope:** CS, RC, BP, BDM, AC, TR, UP, SR, BQP, PPP, BSI, and UC. UC was not in the original request but is retained here because `PD00-TAR-STP` has no other downstream target; see the [UC note](#note-on-uc) before moving it in or out of the implementation batch.

---

## 1. Naming Reconciliation

Before reading the map, note a naming gap between the mapping document and the current code:

| Mapping doc uses | Current model uses | Resolution |
|------------------|-------------------|------------|
| `PD00-SYS` (System Overview) | `PD00-SYO` | This note uses `PD00-SYO` (model is authoritative) |
| `PD00-SYS-SYS-SYS` (3-level depth) | `PD00-SYO-SYR` (flattened) | Same content; mapping doc is out of date on the ID |
| `PD00-SYS-SYS-REQ` | `PD00-SYO-REQ` | Same content |
| `PD00-SYS-SYB-INT/OUT` | `PD00-SYO-SYB` (subtree) | Same content |
| `PD00-SYS-RES-TEC` | `PD00-SYO-RES-TEC` | Same content |
| `PD00-USE-DAT`, `PD00-USE-AUT` | not present as `@SectionId` classes | Replaced in the model by the untagged `dataStructureAlignment` and `authorizationCompliance` fields inside `UserInterfaceDesign` |

The model has also added these sections that the mapping does not yet list; the target documents proposed here extend the mapping accordingly:

| Added in model | Parent | Proposed target |
|----------------|--------|-----------------|
| `PD00-ACC-AUD` Audit and Logging | PD00-ACC | **AC** (stays with ACC bundle) |
| `PD00-TEC-SEC` Security Requirements | PD00-TEC | **TR** (stays with TEC bundle) |
| `PD00-USE-VIS` Design Vision | PD00-USE | **UP** |
| `PD00-USE-ACC` Accessibility | PD00-USE | **UP** |
| `PD00-USE-RES` Responsive Design | PD00-USE | **UP** |
| `PD00-USE-COM` UI Components | PD00-USE | **UP** |
| `PD00-COM-STR` Component Strategy | PD00-COM | **TR** |
| `PD00-COM-RIS` Risk Assessment | PD00-COM | **TR** |
| `PD00-SYQ-PRI` Quality Prioritization | PD00-SYQ | **BQP** |
| `PD00-SYQ-ACC` Acceptance Criteria Summary | PD00-SYQ | **BQP** |
| `PD00-SSP-STR` Staging Strategy, `PD00-SSP-FEA`, `PD00-SSP-MIG`, `PD00-SSP-GOV` | PD00-SSP | **PPP** |
| `PD00-CUR-*` four subsections | PD00-CUR | **PD00-only** (parent is PD-only) |
| `PD00-POP-*` four subsections | PD00-POP | **PD00-only** (parent is PD-only) |
| `PD00-SYO-RES-CON` Constraints and Dependencies | PD00-SYO-RES | **PD00-only** (siblings ORG/FUN are PD-only) |

---

## 2. Cut-Depth Rule

The target-document structure follows a single rule:

> **Dive into the PD00 tree only as deep as needed. Stop at the shallowest node whose entire subtree flows to a single target (one DocSpec, or PD00-only). That node becomes one top-level entry in the target document class.**

Applied to PD00, this yields three cases per section:

| Case | Example | Result |
|------|---------|--------|
| Whole subtree → one DocSpec | `PD00-BUS → BDM` | One top-level entry in the target doc |
| Whole subtree stays PD00-only | `PD00-ADM`, `PD00-ORG` | Nothing to add — lives only in PD |
| Subtree splits across targets | `PD00-SYO`, `PD00-TAR`, `PD00-USE`, `PD00-DEL` | Dive one level; recurse per child |

---

## 3. PD00 Tree with Cut Depths

PD00 top-level sections with their resolution. An **arrow (→)** marks a cut point: no need to dive further because the whole subtree below this node has a single target. **(dive)** means the node is mixed and must be split one level deeper. `PD-only` means the node and its whole subtree stay in PD00.

### Level 1 (14 sections of `ProjectDefinition`)

```
PD00 Project Definition
├── PD00-CUR  Current State Analysis                      PD-only
├── PD00-POP  Project Organization and Process            PD-only
├── PD00-ADM  Administrative                              PD-only
├── PD00-SYO  System Overview                             (dive — see §3A)
├── PD00-ORG  Organizational Framework                    PD-only
├── PD00-TAR  Target Business Process Model               (dive — see §3B)
├── PD00-BUS  Business Object and Data Model              → BDM
├── PD00-TEC  Technical Framework Concept                 → TR
├── PD00-ACC  Access and Authorization Concept            → AC
├── PD00-USE  User Interface Design and Prototype         (dive — see §3C)
├── PD00-SYQ  System Quality Goals                        → BQP
├── PD00-COM  Components to Use                           → TR
├── PD00-SSP  System Stage Plan                           → PPP
└── PD00-DEL  Delivery Scope and Acceptance               (dive — see §3D)
```

### 3A. PD00-SYO System Overview — dive

```
PD00-SYO  System Overview
├── PD00-SYO-SYD  System Description                      PD-only
├── PD00-SYO-GOA  Goals                                   PD-only
├── PD00-SYO-REQ  Requirements Overview                   → RC
├── PD00-SYO-SYR  Systems to Replace                      → CS
├── PD00-SYO-SYB  System Boundaries                       → BSI
├── PD00-SYO-RES  Framework Conditions                    (dive)
│   ├── PD00-SYO-RES-ORG  Organizational Environment      PD-only
│   ├── PD00-SYO-RES-FUN  Functional Responsibilities     PD-only
│   ├── PD00-SYO-RES-TEC  Technical Framework Conditions  → TR
│   └── PD00-SYO-RES-CON  Constraints and Dependencies    PD-only
└── PD00-SYO-RIS  Risks and Assumptions                   PD-only
```

### 3B. PD00-TAR Target Business Process Model — dive

```
PD00-TAR  Target Business Process Model
├── PD00-TAR-PRO  Business Process Descriptions           → BP
└── PD00-TAR-STP  Process Steps and Actor Interactions    → UC
```

### 3C. PD00-USE User Interface Design and Prototype — dive

```
PD00-USE  User Interface Design and Prototype
├── PD00-USE-VIS  Design Vision                           → UP
├── PD00-USE-SCR  Screen Descriptions                     → UP
├── PD00-USE-SCF  Screen Flow Structure                   → UP
├── PD00-USE-PRI  Print Layout                            → UP
├── dataStructureAlignment  (untagged field)              PD-only (bridge note to BDM)
├── authorizationCompliance (untagged field)              PD-only (bridge note to AC)
├── PD00-USE-ERR  Error Handling Concept                  → UP
├── PD00-USE-HLP  Help Concept                            → UP
├── PD00-USE-ACC  Accessibility                           → UP
├── PD00-USE-RES  Responsive Design                       → UP
├── PD00-USE-COM  UI Components                           → UP
├── PD00-USE-MUL  Multi-language and Rollout              (dive)
│   ├── PD00-USE-MUL-LOC  Localization Process            → SR
│   ├── PD00-USE-MUL-TRA  Translation Process             → SR
│   ├── PD00-USE-MUL-DOC  Documentation and Training      → SR
│   ├── PD00-USE-MUL-LCS  Language and Country Selection  → UP
│   └── PD00-USE-MUL-REQ  Translation Handling Reqs       → TR
└── PD00-USE-PRO  Prototype                               → UP
```

### 3D. PD00-DEL Delivery Scope and Acceptance — dive

```
PD00-DEL  Delivery Scope and Acceptance
├── PD00-DEL-DEL  Delivery and Service Scope              PD-only
└── PD00-DEL-ACC  Acceptance Plan                         → BQP
```

---

## 4. Summary: PD00-Only Subtrees

These stay in `ProjectDefinition` and do not appear in any Phase 3 document class:

| Section | Title | Class |
|---------|-------|-------|
| PD00-CUR | Current State Analysis | `CurrentStateAnalysis` (and all 4 children) |
| PD00-POP | Project Organization and Process | `ProjectOrganizationAndProcess` (and all 4 children) |
| PD00-ADM | Administrative | `Administrative` (and all 6 children) |
| PD00-SYO-SYD | System Description | `SystemDescription` |
| PD00-SYO-GOA | Goals | `Goals` |
| PD00-SYO-RES-ORG | Organizational Environment | `OrganizationalEnvironment` |
| PD00-SYO-RES-FUN | Functional Responsibilities | `FunctionalResponsibilities` |
| PD00-SYO-RES-CON | Constraints and Dependencies | `ConstraintsAndDependencies` |
| PD00-SYO-RIS | Risks and Assumptions | `RisksAndAssumptions` |
| PD00-ORG | Organizational Framework | `OrganizationalFramework` (and all 3 children) |
| PD00-DEL-DEL | Delivery and Service Scope | `DeliveryScope` |

---

## 5. Target-Document Class Outlines

Each new document class follows the same shape:

```dart
@Document(name: '…', description: '…', basedOn: [ProjectDefinition])
@SectionId('<DOC>00')
class <DocName> {
  String? content;                  // Executive overview
  DocumentHeader header = DocumentHeader();
  // …one field per seeded PD00 subtree (see tables below)…
  // …plus doc-specific new sections where applicable…
}
```

`DocumentHeader` is the common part (see `lib/src/common/document_header.dart`) and is the same in every document.

The "Seeded Class" column gives the PD00 class name that becomes a top-level field in the new document. "Expansion" lists sections added by the target document that are not seeded from PD00 — these are mentioned for completeness but are design work for whoever implements each document class.

### 5.1. CS — Current Situation

**Root source:** PD00-SYO-SYR (Systems to Replace)

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `systemsToReplace` | PD00-SYO-SYR | `SystemsToReplace` |

**Expansion (not seeded from PD00):** AS01-PAI Pain Points and Issues, integration points, data-flow analysis.

### 5.2. RC — Requirements Catalog

**Root source:** PD00-SYO-REQ (Requirements Overview)

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `requirementsOverview` | PD00-SYO-REQ | `RequirementsOverview` |

**Expansion:** AS02-FUN Functional Requirements, AS02-TEC Technical Requirements, AS02-SEC Security Requirements, traceability matrix.

### 5.3. BP — Business Processes

**Root source:** PD00-TAR-PRO (Business Process Descriptions)

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `businessProcessDescriptions` | PD00-TAR-PRO | `BusinessProcessDescriptions` |

**Expansion:** AS07-DET Detailed Process Descriptions, AS07-CRO Cross-Process Analysis, AS07-EXC Exception Handling.

### 5.4. UC — Use Cases

**Root source:** PD00-TAR-STP (Process Steps and Actor Interactions)

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `processStepsAndActorInteractions` | PD00-TAR-STP | `ProcessStepsAndActorInteractions` |

**Expansion:** Per-use-case actor goals, preconditions, main/alternate flows, postconditions, exceptions. HBSG frames these as end-to-end test scenarios (AS24).

<a id="note-on-uc"></a>
**Note on UC:** The current request listed 11 DocSpecs and omitted UC, but `PD00-TAR-STP` has UC as its only defined target in the mapping. If UC is not part of this batch, PD00-TAR-STP should be re-routed (e.g., merged into BP, or deferred); otherwise UC should be implemented with the others. No other option leaves PD00-TAR-STP properly mapped.

### 5.5. BDM — Business Data Model

**Root source:** PD00-BUS (whole subtree)

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `businessObjectAndDataModel` | PD00-BUS | `BusinessObjectAndDataModel` |

Single seeded entry because the entire `PD00-BUS` subtree (Data Model, Business Object Model, Function Model) targets BDM.

**Expansion:** AS08-CON Conceptual Data Model, AS08-BUO Business Object Definitions, AS08-DAT Data Dictionary, business rules, lifecycle states.

### 5.6. AC — Authorization Concept

**Root source:** PD00-ACC (whole subtree — 6 children)

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `accessAndAuthorization` | PD00-ACC | `AccessAndAuthorizationConcept` |

Single seeded entry because the entire `PD00-ACC` subtree (USE, IDE, RES, USA, SEN, AUD) targets AC.

**Expansion:** AS22-IDE/AUT/RES/AUM/DAT mappings, detailed role definitions, permission matrices, row-level security rules, audit requirements.

### 5.7. TR — Technical Requirements

**Root sources:** PD00-TEC (whole) + PD00-COM (whole) + PD00-SYO-RES-TEC + PD00-USE-MUL-REQ

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `technicalFramework` | PD00-TEC | `TechnicalFrameworkConcept` |
| `components` | PD00-COM | `ComponentsToUse` |
| `technicalFrameworkConditions` | PD00-SYO-RES-TEC | `TechnicalFrameworkConditions` |
| `translationRequirements` | PD00-USE-MUL-REQ | `TranslationRequirements` |

Four seeded top-level entries — TR is the largest aggregate document.

**Expansion:** AS09-FUN/SOF/STA/HAR/OPE/COM/SYS sub-sections, AS12-COS Component Stack Summary, AS09-FUN-INT Internationalization.

### 5.8. UP — UI Prototype

**Root source:** 11 sub-sections of PD00-USE

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `designVision` | PD00-USE-VIS | `DesignVision` |
| `screens` | PD00-USE-SCR | `ScreenDescriptions` |
| `screenFlow` | PD00-USE-SCF | `ScreenFlowStructure` |
| `printLayout` | PD00-USE-PRI | `PrintLayout` |
| `errorHandling` | PD00-USE-ERR | `ErrorHandlingConcept` |
| `helpConcept` | PD00-USE-HLP | `HelpConcept` |
| `accessibility` | PD00-USE-ACC | `Accessibility` |
| `responsiveDesign` | PD00-USE-RES | `ResponsiveDesign` |
| `uiComponents` | PD00-USE-COM | `UiComponents` |
| `languageCountrySelection` | PD00-USE-MUL-LCS | `LanguageCountrySelection` |
| `prototype` | PD00-USE-PRO | `Prototype` |

Eleven seeded top-level entries. Per the cut-depth rule each is brought in at its own level rather than bundling them under a single `PD00-USE` aggregate, because `PD00-USE-MUL` splits (LCS stays with UP, LOC/TRA/DOC go to SR, REQ goes to TR).

**Expansion:** AS10-WIR Wireframes, AS10-INF Information Architecture, AS10-INT-ERR integrated error UX, interaction patterns.

### 5.9. SR — System Rollout

**Root source:** 3 sub-sections of PD00-USE-MUL

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `localizationProcess` | PD00-USE-MUL-LOC | `LocalizationProcess` |
| `translationProcess` | PD00-USE-MUL-TRA | `TranslationProcess` |
| `documentationAndTraining` | PD00-USE-MUL-DOC | `DocumentationAndTraining` |

**Expansion:** SR-LOC-PLN Localization Planning, SR-TRA-WFL Translation Workflow, SR-DOC User Manuals, SR-TRN Training Materials; also covers HBSG DR22 Migration Plan and DR23 Rollout Plan.

### 5.10. BQP — Business Quality Plan

**Root sources:** PD00-SYQ (whole) + PD00-DEL-ACC

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `systemQualityGoals` | PD00-SYQ | `SystemQualityGoals` |
| `acceptancePlan` | PD00-DEL-ACC | `AcceptancePlan` |

**Expansion:** AS11 (already inside SYQ), AS23 Test Strategy sections (test approach, entry/exit criteria), AS14 acceptance process fragments. Note: AS14 delivery scope stays in PD00-DEL-DEL and does not flow here.

### 5.11. PPP — Project Phase Plan

**Root source:** PD00-SSP (whole)

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `systemStagePlan` | PD00-SSP | `SystemStagePlan` |

**Expansion:** PPP-UPG Upgrade Cycle Framework (new, links to `tom_system_upgrade.md`), PPP-IDV Initial Development Flow, per-phase gate criteria, resource planning.

### 5.12. BSI — Business System Interactions

**Root source:** PD00-SYO-SYB

| Top-level entry | Seeded from | Seeded Class |
|-----------------|-------------|--------------|
| `header` | common | `DocumentHeader` |
| `content` | — | executive summary |
| `systemBoundaries` | PD00-SYO-SYB | `SystemBoundaries` |

**Expansion:** BSI-LAN-INV System Inventory, per-interaction definitions, BSI-PAT Common Patterns, BSI-TST Testing Strategy, BSI-DEP Dependency Analysis, BSI-MIG Migration Interactions (optional back-reference to PD00-SYO-SYR).

---

## 6. Summary Matrix

How many seeded top-level entries each document gets:

| Doc | # Seeded tops | From PD00 subtrees |
|-----|---------------|--------------------|
| CS  | 1 | PD00-SYO-SYR |
| RC  | 1 | PD00-SYO-REQ |
| BP  | 1 | PD00-TAR-PRO |
| UC  | 1 | PD00-TAR-STP |
| BDM | 1 | PD00-BUS |
| AC  | 1 | PD00-ACC |
| TR  | 4 | PD00-TEC, PD00-COM, PD00-SYO-RES-TEC, PD00-USE-MUL-REQ |
| UP  | 11 | PD00-USE-{VIS,SCR,SCF,PRI,ERR,HLP,ACC,RES,COM,PRO} + PD00-USE-MUL-LCS |
| SR  | 3 | PD00-USE-MUL-{LOC,TRA,DOC} |
| BQP | 2 | PD00-SYQ, PD00-DEL-ACC |
| PPP | 1 | PD00-SSP |
| BSI | 1 | PD00-SYO-SYB |

Every PD00 subtree that has a Phase 3 target is covered exactly once, with no overlap between target documents.

---

## 7. Implementation Notes

- **Reuse, don't duplicate.** The seeded fields type against the existing PD00 classes (`BusinessObjectAndDataModel`, `SystemStagePlan`, etc.). The target document class imports `package:tom_specs_model/.../pd_project_definition/...` and uses the same types. Expansion-only sections are authored as new classes inside `lib/src/<doc>_<name>/`.
- **One folder per document.** Add `lib/src/cs_current_situation/`, `lib/src/rc_requirements_catalog/`, … mirroring `pd_project_definition/`. Top-level file exports the root class (e.g., `CurrentSituation`, `RequirementsCatalog`).
- **Annotate every new root.** `@Document(…, basedOn: [ProjectDefinition])` and `@SectionId('<CODE>00')` on the class, and re-export from `lib/tom_specs_model.dart`.
- **Outliner root type.** Once a document class exists, the outliner can run with `--root-type <DocName>` against `tom_specs_model` to validate that the new class tree traverses cleanly.
- **UC decision pending.** Resolve the UC question (§5.4) before starting — either implement UC in this wave or explicitly reroute PD00-TAR-STP.
- **Mapping doc out of date.** Section 1 lists the known IDs that have drifted between `hbsg_tom_resulttype_mapping.md` and the current model. Update the mapping doc after this wave lands so it stops contradicting the code.
