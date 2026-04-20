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

## 2. Cut-Depth Rule (PD-side)

Splitting PD00 into per-document slices follows a single rule:

> **Dive into the PD00 tree only as deep as needed. Stop at the shallowest node whose entire subtree flows to a single target (one DocSpec, or PD00-only). That node identifies one PD-side seed for the target document.**

Applied to PD00, this yields three cases per section:

| Case | Example | Result |
|------|---------|--------|
| Whole subtree → one DocSpec | `PD00-BUS → BDM` | One seed node for the target doc |
| Whole subtree stays PD00-only | `PD00-ADM`, `PD00-ORG` | Nothing to add — lives only in PD |
| Subtree splits across targets | `PD00-SYO`, `PD00-TAR`, `PD00-USE`, `PD00-DEL` | Dive one level; recurse per child |

## 2A. Top-Level Sizing Rule (target-doc side)

Seed nodes identify *what comes in from PD00*. How that material becomes top-level entries in the new document class follows a separate rule:

> **Every target document gets 7–15 top-level sections, to give it proper structure.**
>
> - **Single-source docs** (one seed node): top-level entries are the *children* of that seed (i.e. flatten one level). If still fewer than 7, add target-specific expansion sections. If still more than 15, regroup case-by-case.
> - **Multi-source docs** (TR, UP, SR, BQP): decide one by one which seed nodes to flatten and which to keep as a single entry so the total lands in 7–15.

Expansion sections are top-level entries in the target document that are not seeded from PD00 — they cover detail that only appears at Phase 3 (e.g. full requirement catalogs in RC, interaction patterns in BSI, upgrade framework in PPP). They are listed per document in §5.

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
  // …7–15 top-level entries — see tables below…
}
```

`DocumentHeader` is the common part (see `lib/src/common/document_header.dart`) and is the same in every document. `content` and `header` do not count toward the 7–15 figure — it applies to document-specific top-level entries only.

In the tables:
- **Top-level entry** — field name proposed on the new document class.
- **Origin** — `seeded (flat)` means the entry is the children of a seeded PD00 node flattened one level up; `seeded (whole)` means the entire seeded node is used as a single entry; `expansion` means the entry is new in the target document, not present in PD00.
- **Source** — PD00 section ID (or HBSG/expansion id for new sections).

### 5.1. CS — Current Situation

**Seed nodes:** PD00-SYO-SYR (Systems to Replace — 2 children). Single-source; flatten then expand to reach the 7–15 band.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `replacementInventory` | seeded (flat) | PD00-SYO-SYR-INV |
| 2 | `migrationConsiderations` | seeded (flat) | PD00-SYO-SYR-MIG |
| 3 | `currentSystemsLandscape` | expansion | AS01-CUR |
| 4 | `painPointsAndIssues` | expansion | AS01-PAI |
| 5 | `currentDataFlows` | expansion | CS-DAT |
| 6 | `currentIntegrationPoints` | expansion | CS-INT |
| 7 | `currentArchitectureAssessment` | expansion | CS-ARC |
| 8 | `operationalMetrics` | expansion | CS-MET |
| 9 | `riskAssessment` | expansion | CS-RIS |

**Count: 9.**

### 5.2. RC — Requirements Catalog

**Seed nodes:** PD00-SYO-REQ (4 sectioned children + traceability-matrix flat field). Single-source; flatten + expand.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `functionalRequirements` | seeded (flat) | PD00-SYO-REQ-FUN |
| 2 | `technicalRequirements` | seeded (flat) | PD00-SYO-REQ-TEC |
| 3 | `securityRequirements` | seeded (flat) | PD00-SYO-REQ-SEC |
| 4 | `organizationalRequirements` | seeded (flat) | PD00-SYO-REQ-ORG |
| 5 | `traceabilityMatrix` | seeded (flat) | PD00-SYO-REQ-TRC |
| 6 | `requirementsProcess` | expansion | RC-PRO |
| 7 | `prioritizationScheme` | expansion | RC-PRI |
| 8 | `changeControlLog` | expansion | RC-CHA |
| 9 | `requirementRelationships` | expansion | RC-REL |
| 10 | `requirementCoverage` | expansion | RC-COV |

**Count: 10.**

### 5.3. BP — Business Processes

**Seed nodes:** PD00-TAR-PRO (5 sectioned children + `processRelationships` flat field). Single-source; flatten + expand.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `processVision` | seeded (flat) | PD00-TAR-PRO-VIS |
| 2 | `designPrinciples` | seeded (flat) | PD00-TAR-PRO-PRI |
| 3 | `processCatalog` | seeded (flat) | PD00-TAR-PRO-CAT |
| 4 | `processOverviewDiagram` | seeded (flat) | PD00-TAR-PRO-FLO |
| 5 | `improvementSummary` | seeded (flat) | PD00-TAR-PRO-IMP |
| 6 | `processRelationships` | seeded (flat) | (untagged field) |
| 7 | `detailedWorkflows` | expansion | AS07-DET |
| 8 | `crossProcessAnalysis` | expansion | AS07-CRO |
| 9 | `exceptionHandling` | expansion | AS07-EXC |
| 10 | `processMetricsAndKpis` | expansion | BP-MET |

**Count: 10.**

### 5.4. UC — Use Cases

**Seed nodes:** PD00-TAR-STP (overview + 3 sectioned children + `actorRelationshipDiagram`). Single-source; flatten + expand.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `processStepsOverview` | seeded (flat) | (untagged overview field) |
| 2 | `actorOverview` | seeded (flat) | PD00-TAR-STP-ACT |
| 3 | `interactionCatalog` | seeded (flat) | PD00-TAR-STP-INT |
| 4 | `keyScenarios` | seeded (flat) | PD00-TAR-STP-SCE |
| 5 | `actorRelationshipDiagram` | seeded (flat) | (untagged diagram field) |
| 6 | `useCaseCatalog` | expansion | UC-CAT (fully-dressed Cockburn UCs) |
| 7 | `alternateFlows` | expansion | UC-ALT |
| 8 | `preconditionsAndPostconditions` | expansion | UC-PRE |
| 9 | `endToEndTestScenarios` | expansion | AS24 |
| 10 | `useCaseTraceability` | expansion | UC-TRC |

**Count: 10.**

<a id="note-on-uc"></a>
**Note on UC:** The initial request listed 11 DocSpecs and omitted UC, but `PD00-TAR-STP` has UC as its only defined target in the mapping. If UC is dropped, PD00-TAR-STP needs re-routing (merge into BP, or defer). No other option leaves PD00-TAR-STP mapped.

### 5.5. BDM — Business Data Model

**Seed nodes:** PD00-BUS (3 sectioned children). Single-source; flatten + expand.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `dataModel` | seeded (flat) | PD00-BUS-DAT |
| 2 | `businessObjectModel` | seeded (flat) | PD00-BUS-BUS |
| 3 | `functionModel` | seeded (flat) | PD00-BUS-FUN |
| 4 | `conceptualDataModel` | expansion | AS08-CON |
| 5 | `entityDefinitions` | expansion | AS08-BUO |
| 6 | `businessObjectOverview` | expansion | AS08-BUS |
| 7 | `dataDictionary` | expansion | AS08-DAT |
| 8 | `businessRules` | expansion | BDM-RUL |
| 9 | `validationConstraints` | expansion | BDM-VAL |
| 10 | `lifecycleStates` | expansion | BDM-LIF |
| 11 | `dataClassification` | expansion | BDM-CLA |

**Count: 11.**

### 5.6. AC — Authorization Concept

**Seed nodes:** PD00-ACC (6 sectioned children). Single-source; flatten + expand.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `userManagement` | seeded (flat) | PD00-ACC-USE |
| 2 | `authentication` | seeded (flat) | PD00-ACC-IDE |
| 3 | `resourceProtection` | seeded (flat) | PD00-ACC-RES |
| 4 | `authorization` | seeded (flat) | PD00-ACC-USA |
| 5 | `encryption` | seeded (flat) | PD00-ACC-SEN |
| 6 | `auditAndLogging` | seeded (flat) | PD00-ACC-AUD |
| 7 | `roleMatrix` | expansion | AC-ROL (AS22-AUM permission matrix) |
| 8 | `permissionCatalog` | expansion | AC-PER |
| 9 | `authorizationFlows` | expansion | AC-FLO |
| 10 | `complianceFramework` | expansion | AC-CMP (NIST/SOC2/ISO27001/OWASP) |

**Count: 10.**

### 5.7. TR — Technical Requirements

**Seed nodes (multi-source):** PD00-TEC (8 sectioned children) + PD00-COM (whole) + PD00-SYO-RES-TEC + PD00-USE-MUL-REQ. Decision: flatten PD00-TEC (the largest bundle) but keep PD00-COM as a single entry (its 6 children are tightly coupled and read as one concern); add small expansion.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `basicTechnicalRequirements` | seeded (flat) | PD00-TEC-BAS |
| 2 | `softwareDesignRequirements` | seeded (flat) | PD00-TEC-SOF |
| 3 | `standardSoftwareRequirements` | seeded (flat) | PD00-TEC-STA |
| 4 | `hardwareRequirements` | seeded (flat) | PD00-TEC-HAR |
| 5 | `operationsRequirements` | seeded (flat) | PD00-TEC-OPE |
| 6 | `communicationRequirements` | seeded (flat) | PD00-TEC-COM |
| 7 | `systemOperationAndMonitoring` | seeded (flat) | PD00-TEC-SYS |
| 8 | `technicalSecurityRequirements` | seeded (flat) | PD00-TEC-SEC |
| 9 | `componentsToUse` | seeded (whole) | PD00-COM |
| 10 | `technicalFrameworkConditions` | seeded (whole) | PD00-SYO-RES-TEC |
| 11 | `translationRequirements` | seeded (whole) | PD00-USE-MUL-REQ |
| 12 | `systemArchitecture` | expansion | AS09-SOF (detailed) / DR30 |
| 13 | `infrastructureRequirements` | expansion | TR-INF |
| 14 | `integrationProtocols` | expansion | TR-INT |

**Count: 14.**

### 5.8. UP — UI Prototype

**Seed nodes (multi-source):** 10 sectioned children of PD00-USE + PD00-USE-MUL-LCS. Already 11 top-levels; keep flat and add 2 small expansion sections for completeness.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `designVision` | seeded (whole) | PD00-USE-VIS |
| 2 | `screens` | seeded (whole) | PD00-USE-SCR |
| 3 | `screenFlow` | seeded (whole) | PD00-USE-SCF |
| 4 | `printLayout` | seeded (whole) | PD00-USE-PRI |
| 5 | `errorHandling` | seeded (whole) | PD00-USE-ERR |
| 6 | `helpConcept` | seeded (whole) | PD00-USE-HLP |
| 7 | `accessibility` | seeded (whole) | PD00-USE-ACC |
| 8 | `responsiveDesign` | seeded (whole) | PD00-USE-RES |
| 9 | `uiComponents` | seeded (whole) | PD00-USE-COM |
| 10 | `languageCountrySelection` | seeded (whole) | PD00-USE-MUL-LCS |
| 11 | `prototype` | seeded (whole) | PD00-USE-PRO |
| 12 | `wireframesAndMockups` | expansion | AS10-WIR |
| 13 | `informationArchitecture` | expansion | AS10-INF |

**Count: 13.**

### 5.9. SR — System Rollout

**Seed nodes (multi-source):** PD00-USE-MUL-LOC + TRA + DOC. Decision: keep each of the three process sections as a single top-level (internal structure is coherent) and add SR-specific expansion for rollout, migration, user manuals, training, and handover — this is where most of SR's real content sits.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `localizationProcess` | seeded (whole) | PD00-USE-MUL-LOC |
| 2 | `translationProcess` | seeded (whole) | PD00-USE-MUL-TRA |
| 3 | `documentationAndTraining` | seeded (whole) | PD00-USE-MUL-DOC |
| 4 | `rolloutPlan` | expansion | SR-ROL / DR23 |
| 5 | `migrationPlan` | expansion | SR-MIG / DR22 |
| 6 | `userManuals` | expansion | SR-DOC / DR15 |
| 7 | `trainingMaterials` | expansion | SR-TRN / DR17 |
| 8 | `pilotPlan` | expansion | SR-PIL |
| 9 | `cutoverProcedures` | expansion | SR-CUT |
| 10 | `knowledgeTransfer` | expansion | SR-KNO / EK09 |
| 11 | `warrantyAndSupport` | expansion | SR-WAR / EK10 |

**Count: 11.**

### 5.10. BQP — Business Quality Plan

**Seed nodes (multi-source):** PD00-SYQ (7 sectioned children) + PD00-DEL-ACC (6 sectioned children). Decision: flatten both. The quality goals and the acceptance plan are the two halves of BQP and each half has its own natural sub-structure.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `qualityFramework` | seeded (flat) | PD00-SYQ-FRA |
| 2 | `userQualityCriteria` | seeded (flat) | PD00-SYQ-USE |
| 3 | `technicalQualityCriteria` | seeded (flat) | PD00-SYQ-TEC |
| 4 | `operationsQualityCriteria` | seeded (flat) | PD00-SYQ-OPE |
| 5 | `documentationQualityCriteria` | seeded (flat) | PD00-SYQ-DOC |
| 6 | `qualityPrioritization` | seeded (flat) | PD00-SYQ-PRI |
| 7 | `acceptanceCriteriaSummary` | seeded (flat) | PD00-SYQ-ACC |
| 8 | `acceptanceCriteria` | seeded (flat) | PD00-DEL-ACC-CRI |
| 9 | `acceptanceProcess` | seeded (flat) | PD00-DEL-ACC-PRO |
| 10 | `userAcceptanceTesting` | seeded (flat) | PD00-DEL-ACC-UAT |
| 11 | `defectResolution` | seeded (flat) | PD00-DEL-ACC-DEF |
| 12 | `signOffProcess` | seeded (flat) | PD00-DEL-ACC-SIG |
| 13 | `warranty` | seeded (flat) | PD00-DEL-ACC-WAR |
| 14 | `testStrategy` | expansion | AS23 |

**Count: 14.**

### 5.11. PPP — Project Phase Plan

**Seed nodes:** PD00-SSP (6 sectioned children + stages list). Single-source; flatten + expand.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `stagingStrategy` | seeded (flat) | PD00-SSP-STR |
| 2 | `stageOverview` | seeded (flat) | PD00-SSP-STA |
| 3 | `stages` | seeded (flat) | PD00-SSP-STG (list) |
| 4 | `featurePrioritization` | seeded (flat) | PD00-SSP-FEA |
| 5 | `dataMigrationStrategy` | seeded (flat) | PD00-SSP-MIG |
| 6 | `stageGovernance` | seeded (flat) | PD00-SSP-GOV |
| 7 | `phaseDefinitions` | expansion | PPP-PHD |
| 8 | `gateCriteria` | expansion | PPP-GAT |
| 9 | `resourcePlanning` | expansion | PPP-RES |
| 10 | `initialDevelopmentFlow` | expansion | PPP-IDV |
| 11 | `upgradeCycleFramework` | expansion | PPP-UPG (→ tom_system_upgrade.md) |

**Count: 11.**

### 5.12. BSI — Business System Interactions

**Seed nodes:** PD00-SYO-SYB (3 sectioned children). Single-source; flatten + expand.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `externalInterfaces` | seeded (flat) | PD00-SYO-SYB-INT |
| 2 | `outOfScope` | seeded (flat) | PD00-SYO-SYB-OUT |
| 3 | `boundaryAssumptions` | seeded (flat) | PD00-SYO-SYB-ASS |
| 4 | `systemInventory` | expansion | BSI-LAN-INV |
| 5 | `interactionPatterns` | expansion | BSI-PAT (sync/async/batch) |
| 6 | `testingStrategy` | expansion | BSI-TST |
| 7 | `dependencyAnalysis` | expansion | BSI-DEP |
| 8 | `migrationInteractions` | expansion | BSI-MIG (back-ref to PD00-SYO-SYR) |
| 9 | `operationalConsiderations` | expansion | BSI-OPE |
| 10 | `errorHandlingAcrossBoundaries` | expansion | BSI-ERR |

**Count: 10.**

---

## 6. Summary Matrix

PD-side seeds and resulting target-document top-level counts (all within 7–15):

| Doc | Seed nodes | Seeded tops | Expansion tops | Total |
| --- | --- | --- | --- | --- |
| CS  | PD00-SYO-SYR | 2 | 7 | 9 |
| RC  | PD00-SYO-REQ | 5 | 5 | 10 |
| BP  | PD00-TAR-PRO | 6 | 4 | 10 |
| UC  | PD00-TAR-STP | 5 | 5 | 10 |
| BDM | PD00-BUS | 3 | 8 | 11 |
| AC  | PD00-ACC | 6 | 4 | 10 |
| TR  | PD00-TEC, PD00-COM, PD00-SYO-RES-TEC, PD00-USE-MUL-REQ | 11 | 3 | 14 |
| UP  | 10× PD00-USE-* + PD00-USE-MUL-LCS | 11 | 2 | 13 |
| SR  | PD00-USE-MUL-{LOC,TRA,DOC} | 3 | 8 | 11 |
| BQP | PD00-SYQ, PD00-DEL-ACC | 13 | 1 | 14 |
| PPP | PD00-SSP | 6 | 5 | 11 |
| BSI | PD00-SYO-SYB | 3 | 7 | 10 |

Every PD00 subtree that has a Phase 3 target is covered exactly once, with no overlap between target documents.

---

## 7. Implementation Notes

- **Reuse, don't duplicate.** The seeded fields type against the existing PD00 classes (`BusinessObjectAndDataModel`, `SystemStagePlan`, etc.). The target document class imports `package:tom_specs_model/.../pd_project_definition/...` and uses the same types. Expansion-only sections are authored as new classes inside `lib/src/<doc>_<name>/`.
- **One folder per document.** Add `lib/src/cs_current_situation/`, `lib/src/rc_requirements_catalog/`, … mirroring `pd_project_definition/`. Top-level file exports the root class (e.g., `CurrentSituation`, `RequirementsCatalog`).
- **Annotate every new root.** `@Document(…, basedOn: [ProjectDefinition])` and `@SectionId('<CODE>00')` on the class, and re-export from `lib/tom_specs_model.dart`.
- **Outliner root type.** Once a document class exists, the outliner can run with `--root-type <DocName>` against `tom_specs_model` to validate that the new class tree traverses cleanly.
- **UC decision pending.** Resolve the UC question (§5.4) before starting — either implement UC in this wave or explicitly reroute PD00-TAR-STP.
- **Mapping doc out of date.** Section 1 lists the known IDs that have drifted between `hbsg_tom_resulttype_mapping.md` and the current model. Update the mapping doc after this wave lands so it stops contradicting the code.
