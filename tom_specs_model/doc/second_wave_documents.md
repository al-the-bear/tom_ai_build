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

### HBSG Reference → PD00 ID Mapping

Every section in a second-wave DocSpec must trace to a PD00-* ID. HBSG references (AS-xx, DR-xx, EK-xx) used in earlier drafts are mapped directly to PD00 IDs — either existing sections in the model, or new ones that must be added first as part of the **PD00 Completion Plan** (§7). No doc-scoped intermediate IDs remain in the outlines.

| Old HBSG ref | Final PD00 ID | Status |
| --- | --- | --- |
| AS01-CUR | `PD00-CUR-SYS` | existing |
| AS01-PAI | `PD00-CUR-PAI` | existing |
| AS07-DET | `PD00-TAR-PRO-DET` | new (§7) |
| AS07-CRO | `PD00-TAR-PRO-CRO` | new (§7) |
| AS07-EXC | `PD00-TAR-PRO-EXC` | new (§7) |
| AS08-CON / AS08-BUO / AS08-BUS | `PD00-BUS-DAT` / `PD00-BUS-BUS` | existing (duplicate rows dropped) |
| AS08-DAT | `PD00-BUS-DAT-DIC` | new (§7) |
| AS09-SOF / DR30 | `PD00-TEC-ARC` | new (§7) |
| AS10-WIR | `PD00-USE-WIR` | new (§7) |
| AS10-INF | `PD00-USE-SCR-INF` | existing (reachable via `screens` top-level) |
| AS22-AUM | `PD00-ACC-ROL` | new (§7) |
| AS23 | `PD00-SYQ-TST` | new (§7) |
| AS24 | `PD00-TAR-STP-E2E` | new (§7) |
| DR15 | `PD00-ROL-DOC` | new (§7) |
| DR17 | `PD00-ROL-TRN` | new (§7) |
| DR22 | `PD00-ROL-MIG` | new (§7) |
| DR23 | `PD00-ROL-PLN` | new (§7) |
| EK09 | `PD00-ROL-KNO` | new (§7) |
| EK10 | `PD00-ROL-WAR` | new (§7) |

### Model-Added PD00 Sections

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
├── PD00-CUR  Current State Analysis                      → CS
├── PD00-POP  Project Organization and Process            PD-only
├── PD00-ADM  Administrative                              PD-only
├── PD00-SYO  System Overview                             (dive — see §3A)
├── PD00-ORG  Organizational Framework                    PD-only
├── PD00-TAR  Target Business Process Model               (dive — see §3B)
├── PD00-BUS  Business Object and Data Model              → BDM
├── PD00-TEC  Technical Framework Concept                 → TR
├── PD00-ACC  Access and Authorization Concept            → AC
├── PD00-USE  User Interface Design and Prototype         (dive — see §3C)
├── PD00-ROL  System Rollout                              → SR   (new top-level — §7)
├── PD00-SYQ  System Quality Goals                        → BQP
├── PD00-COM  Components to Use                           → TR
├── PD00-SSP  System Stage Plan                           → PPP
└── PD00-DEL  Delivery Scope and Acceptance               (dive — see §3D)
```

`PD00-CUR` was previously listed as PD-only; the completeness rule moves it to CS (all four existing children plus three new ones flow to CS). `PD00-ROL` is a new top-level section that houses rollout/migration/handover content sourced by SR. Both changes are captured in the PD00 Completion Plan (§7).

### 3A. PD00-SYO System Overview — dive

```
PD00-SYO  System Overview
├── PD00-SYO-SYD  System Description                      PD-only
├── PD00-SYO-GOA  Goals                                   PD-only
├── PD00-SYO-REQ  Requirements Overview                   → RC
├── PD00-SYO-SYR  Systems to Replace                      → CS
├── PD00-SYO-SYB  System Boundaries                       → BSI   (subtree extended in §7)
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
- **Origin** — `existing` means a PD00 class already carries this `@SectionId`; `promote` means an existing class that needs a tag or is lifted to a top-level from a deeper position; `new` means a PD00 section that must be created (see §7).
- **Source** — the PD00 section ID of the class this field types to. Every entry has a PD00-* source; no doc-scoped IDs.
- **Track** — reference to the §7 track that covers the PD00-side work: **T1** HBSG-backed new section, **T2** promote existing class, **T3** inferred new section.

### 5.1. CS — Current Situation

**Seed nodes:** PD00-CUR (whole) + PD00-SYO-SYR (whole). `PD00-CUR` moves off the PD-only list (see §3). Detailed integration content (PD00-CUR-SYS-DEP) is accessible as a sub-section of `existingSystemsLandscape` and is not a separate top-level — promoting it would duplicate content.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `existingSystemsLandscape` | existing | PD00-CUR-SYS | — |
| 2 | `currentBusinessProcesses` | existing | PD00-CUR-PRO | — |
| 3 | `painPointsAndGaps` | existing | PD00-CUR-PAI | — |
| 4 | `currentDataLandscape` | existing | PD00-CUR-DAT | — |
| 5 | `operationalMetrics` | new | PD00-CUR-MET | T3 |
| 6 | `currentStateRisks` | new | PD00-CUR-RIS | T3 |
| 7 | `replacementInventory` | existing | PD00-SYO-SYR-INV | — |
| 8 | `migrationConsiderations` | existing | PD00-SYO-SYR-MIG | — |

**Count: 8.**

### 5.2. RC — Requirements Catalog

**Seed nodes:** PD00-SYO-REQ. The three process/prioritization/change-control items live as `@Form` fields on `RequirementsOverview` and stay at that level (not promoted).

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `functionalRequirements` | existing | PD00-SYO-REQ-FUN | — |
| 2 | `technicalRequirements` | existing | PD00-SYO-REQ-TEC | — |
| 3 | `securityRequirements` | existing | PD00-SYO-REQ-SEC | — |
| 4 | `organizationalRequirements` | existing | PD00-SYO-REQ-ORG | — |
| 5 | `traceabilityMatrix` | existing | PD00-SYO-REQ-TRC | — |
| 6 | `requirementRelationships` | new | PD00-SYO-REQ-REL | T3 |
| 7 | `requirementCoverage` | new | PD00-SYO-REQ-COV | T3 |

**Count: 7.**

### 5.3. BP — Business Processes

**Seed nodes:** PD00-TAR-PRO. `PD00-TAR-PRO-REL` is already a proper `@SectionId` class ([target_business_process.dart:1032](../lib/src/pd_project_definition/target_business_process.dart#L1032)) — only the field reference in the parent needs its doc comment updated.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `processVision` | existing | PD00-TAR-PRO-VIS | — |
| 2 | `designPrinciples` | existing | PD00-TAR-PRO-PRI | — |
| 3 | `processCatalog` | existing | PD00-TAR-PRO-CAT | — |
| 4 | `processOverviewDiagram` | existing | PD00-TAR-PRO-FLO | — |
| 5 | `improvementSummary` | existing | PD00-TAR-PRO-IMP | — |
| 6 | `processRelationships` | existing | PD00-TAR-PRO-REL | — |
| 7 | `detailedWorkflows` | new | PD00-TAR-PRO-DET | T1 |
| 8 | `crossProcessAnalysis` | new | PD00-TAR-PRO-CRO | T1 |
| 9 | `exceptionHandling` | new | PD00-TAR-PRO-EXC | T1 |
| 10 | `processMetricsAndKpis` | new | PD00-TAR-PRO-MET | T3 |

**Count: 10.**

### 5.4. UC — Use Cases

**Seed nodes:** PD00-TAR-STP. Four sections I originally proposed as new (CAT / ALT / PRE / per-entry traceability) duplicate content already held at interaction-catalog-entry level and are dropped.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `processStepsOverview` | promote | PD00-TAR-STP-OVE | T2 |
| 2 | `actorOverview` | existing | PD00-TAR-STP-ACT | — |
| 3 | `interactionCatalog` | existing | PD00-TAR-STP-INT | — |
| 4 | `keyScenarios` | existing | PD00-TAR-STP-SCE | — |
| 5 | `actorRelationshipDiagram` | promote | PD00-TAR-STP-DIA | T2 |
| 6 | `endToEndTestScenarios` | new | PD00-TAR-STP-E2E | T1 |
| 7 | `useCaseTraceability` | new | PD00-TAR-STP-TRC | T3 |

**Count: 7.**

<a id="note-on-uc"></a>
**Note on UC:** The initial request listed 11 DocSpecs and omitted UC, but `PD00-TAR-STP` has UC as its only defined target in the mapping. If UC is dropped, PD00-TAR-STP needs re-routing (merge into BP, or defer). No other option leaves PD00-TAR-STP mapped.

### 5.5. BDM — Business Data Model

**Seed nodes:** PD00-BUS. Applying "go one level deeper": the existing `DAT/BUS/FUN` children are not BDM top-levels themselves — their *own* sub-sections (which are richer and already `@SectionId`'d) become BDM top-levels. This avoids the "DataClassification lives inside DataModel AND is a top-level" duplication.

PD00-BUS, PD00-BUS-DAT, PD00-BUS-BUS, PD00-BUS-FUN all carry `@MapsTo(BusinessDataModel)` but not `@DetailedIn`.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `entities` | existing | PD00-BUS-DAT-ENT (list) | — |
| 2 | `entityRelationships` | existing | PD00-BUS-DAT-REL | — |
| 3 | `erDiagram` | existing | PD00-BUS-DAT-DIA | — |
| 4 | `dataClassification` | existing | PD00-BUS-DAT-CLA | — |
| 5 | `objectCatalog` | existing | PD00-BUS-BUS-CAT (list) | — |
| 6 | `objectDiagram` | existing | PD00-BUS-BUS-DIA | — |
| 7 | `functionDecomposition` | existing | PD00-BUS-FUN-DEC (list) | — |
| 8 | `functionToDataMatrix` | existing | PD00-BUS-FUN-MAT (list) | — |
| 9 | `businessRules` | existing | PD00-BUS-FUN-RUL (list) | — |
| 10 | `dataDictionary` | new | PD00-BUS-DAT-DIC | T1 |
| 11 | `validationConstraints` | new | PD00-BUS-DAT-VAL | T3 |
| 12 | `integrityConstraints` | new | PD00-BUS-DAT-CON | T3 |

**Count: 12.** Dropped as duplicates: `lifecycleStates` (covered per-object inside PD00-BUS-BUS-CAT entries), `migrationMapping` (covered per-entity inside PD00-BUS-DAT-ENT entries).

### 5.6. AC — Authorization Concept

**Seed nodes:** PD00-ACC. `PD00-ACC-IDE-FLO` is accessible inside `identificationAndAuthentication` (PD00-ACC-IDE) and is not a separate top-level — promoting it would duplicate content.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `userManagement` | existing | PD00-ACC-USE | — |
| 2 | `identificationAndAuthentication` | existing | PD00-ACC-IDE | — |
| 3 | `resourceProtection` | existing | PD00-ACC-RES | — |
| 4 | `userAuthorization` | existing | PD00-ACC-USA | — |
| 5 | `sensitiveDataEncryption` | existing | PD00-ACC-SEN | — |
| 6 | `auditAndLogging` | existing | PD00-ACC-AUD | — |
| 7 | `roleMatrix` | new | PD00-ACC-ROL | T1 |
| 8 | `complianceFramework` | new | PD00-ACC-CMP | T3 |

**Count: 8.** Dropped as duplicate: `permissionCatalog` (covered by `PermissionGranularityPolicy` / `PermissionCompositionStrategy` deeper inside USA); `authorizationFlows` (covered by PD00-ACC-IDE subtree).

### 5.7. TR — Technical Requirements

**Seed nodes (multi-source):** PD00-TEC (flatten) + PD00-COM (whole) + PD00-SYO-RES-TEC + PD00-USE-MUL-REQ.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `basicTechnicalRequirements` | existing | PD00-TEC-BAS | — |
| 2 | `softwareDesignRequirements` | existing | PD00-TEC-SOF | — |
| 3 | `standardSoftwareRequirements` | existing | PD00-TEC-STA | — |
| 4 | `hardwareRequirements` | existing | PD00-TEC-HAR | — |
| 5 | `operationsRequirements` | existing | PD00-TEC-OPE | — |
| 6 | `communicationRequirements` | existing | PD00-TEC-COM | — |
| 7 | `systemOperationAndMonitoring` | existing | PD00-TEC-SYS | — |
| 8 | `technicalSecurityRequirements` | existing | PD00-TEC-SEC | — |
| 9 | `systemArchitecture` | new | PD00-TEC-ARC | T1 |
| 10 | `componentsToUse` | existing | PD00-COM (whole) | — |
| 11 | `technicalFrameworkConditions` | existing | PD00-SYO-RES-TEC (whole) | — |
| 12 | `translationRequirements` | existing | PD00-USE-MUL-REQ (whole) | — |

**Count: 12.** Dropped as duplicates: `infrastructureRequirements` (covered by `InfrastructureComponentEntry` inside PD00-TEC-HAR), `integrationProtocols` (covered by PD00-TEC-COM already).

### 5.8. UP — UI Prototype

**Seed nodes:** 11 existing PD00-USE children + 1 new. `PD00-USE-SCR-INF` (InformationArchitecture) is accessible inside `screens` (PD00-USE-SCR) — not a separate top-level.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `designVision` | existing | PD00-USE-VIS | — |
| 2 | `screens` | existing | PD00-USE-SCR | — |
| 3 | `screenFlow` | existing | PD00-USE-SCF | — |
| 4 | `printLayout` | existing | PD00-USE-PRI | — |
| 5 | `errorHandling` | existing | PD00-USE-ERR | — |
| 6 | `helpConcept` | existing | PD00-USE-HLP | — |
| 7 | `accessibility` | existing | PD00-USE-ACC | — |
| 8 | `responsiveDesign` | existing | PD00-USE-RES | — |
| 9 | `uiComponents` | existing | PD00-USE-COM | — |
| 10 | `languageCountrySelection` | existing | PD00-USE-MUL-LCS | — |
| 11 | `prototype` | existing | PD00-USE-PRO | — |
| 12 | `wireframesAndMockups` | new | PD00-USE-WIR | T1 |

**Count: 12.**

### 5.9. SR — System Rollout

**Seed nodes (multi-source):** PD00-USE-MUL-{LOC, TRA, DOC} + the new PD00-ROL top-level (8 children).

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `localizationProcess` | existing | PD00-USE-MUL-LOC | — |
| 2 | `translationProcess` | existing | PD00-USE-MUL-TRA | — |
| 3 | `documentationAndTraining` | existing | PD00-USE-MUL-DOC | — |
| 4 | `rolloutPlan` | new | PD00-ROL-PLN | T1 |
| 5 | `migrationPlan` | new | PD00-ROL-MIG | T1 |
| 6 | `userManuals` | new | PD00-ROL-DOC | T1 |
| 7 | `trainingMaterials` | new | PD00-ROL-TRN | T1 |
| 8 | `pilotPlan` | new | PD00-ROL-PIL | T3 |
| 9 | `cutoverProcedures` | new | PD00-ROL-CUT | T3 |
| 10 | `knowledgeTransfer` | new | PD00-ROL-KNO | T1 |
| 11 | `warrantyAndSupport` | new | PD00-ROL-WAR | T1 |

**Count: 11.**

### 5.10. BQP — Business Quality Plan

**Seed nodes (multi-source):** PD00-SYQ + PD00-DEL-ACC. Flatten both.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `qualityFramework` | existing | PD00-SYQ-FRA | — |
| 2 | `userQualityCriteria` | existing | PD00-SYQ-USE | — |
| 3 | `technicalQualityCriteria` | existing | PD00-SYQ-TEC | — |
| 4 | `operationsQualityCriteria` | existing | PD00-SYQ-OPE | — |
| 5 | `documentationQualityCriteria` | existing | PD00-SYQ-DOC | — |
| 6 | `qualityPrioritization` | existing | PD00-SYQ-PRI | — |
| 7 | `acceptanceCriteriaSummary` | existing | PD00-SYQ-ACC | — |
| 8 | `testStrategy` | new | PD00-SYQ-TST | T1 |
| 9 | `acceptanceCriteria` | existing | PD00-DEL-ACC-CRI | — |
| 10 | `acceptanceProcess` | existing | PD00-DEL-ACC-PRO | — |
| 11 | `userAcceptanceTesting` | existing | PD00-DEL-ACC-UAT | — |
| 12 | `defectResolution` | existing | PD00-DEL-ACC-DEF | — |
| 13 | `signOffProcess` | existing | PD00-DEL-ACC-SIG | — |
| 14 | `warranty` | existing | PD00-DEL-ACC-WAR | — |

**Count: 14.**

### 5.11. PPP — Project Phase Plan

**Seed nodes:** PD00-SSP. Gate criteria and decision processes already exist at `PD00-SSP-GOV-*` — promoted. Initial-development-flow and upgrade-cycle are genuinely new (anticipated in mapping).

PD00-SSP and PD00-SSP-GOV carry `@MapsTo(ProjectPhasePlan)`; GOV itself is not a top-level.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `stagingStrategy` | existing | PD00-SSP-STR | — |
| 2 | `stageOverview` | existing | PD00-SSP-STA | — |
| 3 | `stages` | existing | PD00-SSP-STG (list) | — |
| 4 | `featurePrioritization` | existing | PD00-SSP-FEA | — |
| 5 | `dataMigrationStrategy` | existing | PD00-SSP-MIG | — |
| 6 | `gateCriteria` | existing | PD00-SSP-GOV-GAT | — |
| 7 | `decisionProcesses` | existing | PD00-SSP-GOV-DEC | — |
| 8 | `initialDevelopmentFlow` | new | PD00-SSP-IDV | T1 |
| 9 | `upgradeCycleFramework` | new | PD00-SSP-UPG | T1 |

**Count: 9.** Dropped as duplicates: `phaseDefinitions` (covered by PD00-SSP-STA + stages list), `resourcePlanning` (covered by `StageOverviewResources` inside PD00-SSP-STA).

### 5.12. BSI — Business System Interactions

**Seed nodes:** PD00-SYO-SYB. All seven new additions anticipated by the mapping doc plus two inferred cross-boundary sections.

| # | Top-level entry | Origin | Source | Track |
| --- | --- | --- | --- | --- |
| 1 | `externalInterfaces` | existing | PD00-SYO-SYB-INT | — |
| 2 | `outOfScope` | existing | PD00-SYO-SYB-OUT | — |
| 3 | `boundaryAssumptions` | existing | PD00-SYO-SYB-ASS | — |
| 4 | `systemInventory` | new | PD00-SYO-SYB-INV | T1 |
| 5 | `interactionPatterns` | new | PD00-SYO-SYB-PAT | T1 |
| 6 | `testingStrategy` | new | PD00-SYO-SYB-TST | T1 |
| 7 | `dependencyAnalysis` | new | PD00-SYO-SYB-DEP | T1 |
| 8 | `migrationInteractions` | new | PD00-SYO-SYB-MIG | T1 |
| 9 | `operationalConsiderations` | new | PD00-SYO-SYB-OPE | T3 |
| 10 | `crossBoundaryErrorHandling` | new | PD00-SYO-SYB-ERR | T3 |

**Count: 10.**

---

## 6. Summary Matrix

PD-side seeds and resulting target-document top-level counts (all within 7–15):

Counts after §7 applies: "Existing" = PD00 classes already in the model; "Promote" = existing classes that just need annotation or `@SectionId`; "New" = PD00 sections §7 has to create.

| Doc | Seed nodes | Existing | Promote (T2) | New (T1+T3) | Total tops |
| --- | --- | --- | --- | --- | --- |
| CS  | PD00-CUR, PD00-SYO-SYR | 6 | 0 | 2 | 8 |
| RC  | PD00-SYO-REQ | 5 | 0 | 2 | 7 |
| BP  | PD00-TAR-PRO | 6 | 0 | 4 | 10 |
| UC  | PD00-TAR-STP | 3 | 2 | 2 | 7 |
| BDM | PD00-BUS | 9 | 0 | 3 | 12 |
| AC  | PD00-ACC | 6 | 0 | 2 | 8 |
| TR  | PD00-TEC, PD00-COM, PD00-SYO-RES-TEC, PD00-USE-MUL-REQ | 11 | 0 | 1 | 12 |
| UP  | 11× PD00-USE-* | 11 | 0 | 1 | 12 |
| SR  | PD00-USE-MUL-{LOC,TRA,DOC}, PD00-ROL | 3 | 0 | 8 | 11 |
| BQP | PD00-SYQ, PD00-DEL-ACC | 13 | 0 | 1 | 14 |
| PPP | PD00-SSP | 7 | 0 | 2 | 9 |
| BSI | PD00-SYO-SYB | 3 | 0 | 7 | 10 |

Every PD00 subtree that has a Phase 3 target is covered exactly once; no target-doc top-level duplicates a class already reachable via another top-level's subtree. Across the 12 documents §7 creates **35 new PD00 sections** (22 HBSG-backed + 13 inferred) plus **1 new top-level section** `PD00-ROL`; **2 promotions** reuse existing untagged classes. Details in §7.

---

## 7. PD00 Completion Plan — First Implementation Step

Before any Phase 3 document class is created, the PD00 object model has to carry every section that a Phase 3 document lifts to a top-level entry. If a target-document section has no PD00 home, it is because PD00 is incomplete; the fix is always to add the section to the correct PD00 parent first, not to leave a doc-scoped ID in the target.

This section is the ordered task list for that completion work, split into three tracks:

- **Track 1 — HBSG-backed new sections.** Anticipated by `hbsg_tom_resulttype_mapping.md`. Highest confidence.
- **Track 2 — Promotions of existing classes.** Classes already in the model, used directly as target-doc top-levels. No new PD00 sections, just annotations (and `@SectionId` where missing).
- **Track 3 — Inferred new sections.** My additions, checked for duplicates, for the 7–15 sizing rule.

Every `new` or `promote` row in §5 points back to one row here.

### 7.1. Track 1 — HBSG-Backed New Sections

**22 new `@SectionId` classes plus 1 new top-level section on `ProjectDefinition`.** Each new class carries `@SectionId('PD00-…')` and `@DetailedIn(TargetDoc)`. The parent class gets `@MapsTo(TargetDoc)` if its subtree maps fully.

#### New top-level on `ProjectDefinition`

| New PD00 ID | Class name | Feeds | HBSG origin |
| --- | --- | --- | --- |
| PD00-ROL | `SystemRolloutConcept` | SR | DR22/DR23/DR15/DR17/EK09/EK10 covered by SR. Separate from `PD00-USE-MUL` which stays focused on multi-language. Target-doc class for SR is `SystemRollout`; the PD00 parent uses the `…Concept` suffix (like `TechnicalFrameworkConcept`, `AccessAndAuthorizationConcept`) to avoid a name collision. |

`PD00-ROL` (class `SystemRolloutConcept`) gets `@MapsTo(SystemRollout)`; not itself a top-level (its 8 children are).

#### New sections under existing parents

| New PD00 ID | Class name | Feeds | HBSG origin |
| --- | --- | --- | --- |
| PD00-TAR-PRO-DET | `DetailedProcessWorkflows` | BP | AS07-DET |
| PD00-TAR-PRO-CRO | `CrossProcessAnalysis` | BP | AS07-CRO |
| PD00-TAR-PRO-EXC | `ProcessExceptionHandling` | BP | AS07-EXC |
| PD00-TAR-STP-E2E | `EndToEndTestScenarios` | UC | AS24 |
| PD00-BUS-DAT-DIC | `DataDictionary` | BDM | AS08-DAT Data Dictionary |
| PD00-TEC-ARC | `SystemArchitecture` | TR | AS09-SOF / DR30 |
| PD00-USE-WIR | `WireframesAndMockups` | UP | AS10-WIR |
| PD00-ACC-ROL | `RoleMatrix` | AC | AS22-AUM |
| PD00-SYQ-TST | `TestStrategy` | BQP | AS23 |
| PD00-SYO-SYB-INV | `SystemLandscapeInventory` | BSI | BSI-LAN-INV |
| PD00-SYO-SYB-PAT | `InteractionPatterns` | BSI | BSI-PAT |
| PD00-SYO-SYB-TST | `InteractionTestingStrategy` | BSI | BSI-TST |
| PD00-SYO-SYB-DEP | `InteractionDependencyAnalysis` | BSI | BSI-DEP |
| PD00-SYO-SYB-MIG | `MigrationInteractions` | BSI | BSI-MIG |
| PD00-SSP-IDV | `InitialDevelopmentFlow` | PPP | PPP-IDV (mapping "new in PPP") |
| PD00-SSP-UPG | `UpgradeCycleFramework` | PPP | PPP-UPG (mapping "new in PPP"); links `tom_system_upgrade.md` |
| PD00-ROL-PLN | `RolloutPlan` | SR | DR23 Rollout Plan |
| PD00-ROL-MIG | `MigrationPlan` | SR | DR22 Migration Plan |
| PD00-ROL-DOC | `UserManuals` | SR | DR15 User Manual |
| PD00-ROL-TRN | `TrainingMaterials` | SR | DR17 Training Materials |
| PD00-ROL-KNO | `KnowledgeTransfer` | SR | EK09 Handover Agreement |
| PD00-ROL-WAR | `WarrantyAndSupport` | SR | EK10 Post-acceptance warranty |

### 7.2. Track 2 — Promotions of Existing Classes

**2 existing untagged classes get `@SectionId` + `@DetailedIn`** and become target-doc top-levels. These are the only promotions that don't duplicate content already accessible through an existing top-level.

| Existing PD00 ID | Class name | Feeds | Action |
| --- | --- | --- | --- |
| PD00-TAR-STP-OVE | `ProcessStepsOverview` | UC | Add `@SectionId('PD00-TAR-STP-OVE')` (currently untagged) + `@DetailedIn(UseCases)`. |
| PD00-TAR-STP-DIA | `ActorRelationshipDiagram` | UC | Add `@SectionId('PD00-TAR-STP-DIA')` (currently untagged) + `@DetailedIn(UseCases)`. |

**Why only two promotions:** The earlier draft listed five, but three of the proposed promotions (`PD00-CUR-SYS-DEP`, `PD00-USE-SCR-INF`, `PD00-ACC-IDE-FLO`) each live inside a parent that is *itself* a target-doc top-level (PD00-CUR-SYS, PD00-USE-SCR, PD00-ACC-IDE respectively). Promoting them as additional top-levels would duplicate content — the classes would be reachable both via the top-level parent's subtree and directly. Per the completeness rule in §2, they stay accessible through the parent subtree; the "dropped as duplicate" list in §7.3 tracks them.

**Note on PD00-TAR-PRO-REL:** Already a properly `@SectionId`-tagged class at [target_business_process.dart:1032](../lib/src/pd_project_definition/target_business_process.dart#L1032). The only defect is the field reference in `BusinessProcessDescriptions` lacking the section number in its doc comment. Fix that one line; no promotion required.

### 7.3. Track 3 — Inferred New Sections

**13 new sections** that are not directly in HBSG but close gaps for target-doc coverage. Each is validated against the model to avoid duplicates with existing deeper classes.

| New PD00 ID | Class name | Feeds | Rationale |
| --- | --- | --- | --- |
| PD00-CUR-MET | `CurrentOperationalMetrics` | CS | Throughput / volume / uptime baselines for as-is systems. No adjacent class. |
| PD00-CUR-RIS | `CurrentStateRiskAssessment` | CS | Current-state risk register (distinct from `PD00-SYO-RIS` which is target-side). |
| PD00-SYO-REQ-REL | `RequirementRelationships` | RC | Cross-requirement dependency / conflict graph. |
| PD00-SYO-REQ-COV | `RequirementCoverage` | RC | Coverage against goals / use cases / tests. |
| PD00-SYO-SYB-OPE | `CrossBoundaryOperationalConsiderations` | BSI | SLAs / rate limits / change windows at system-boundary scope (per-interface equivalents exist inside each interface entry). |
| PD00-SYO-SYB-ERR | `CrossBoundaryErrorHandling` | BSI | Failure-propagation policy at boundary scope (not per-interface). |
| PD00-TAR-PRO-MET | `ProcessMetricsAndKpis` | BP | Process-level KPIs / SLAs / measurement strategy. |
| PD00-TAR-STP-TRC | `UseCaseTraceability` | UC | UC ↔ RC ↔ BP ↔ tests traceability matrix. |
| PD00-BUS-DAT-VAL | `ValidationConstraints` | BDM | Cross-entity validation policy (per-field validation lives in entity forms). |
| PD00-BUS-DAT-CON | `IntegrityConstraints` | BDM | Cross-entity integrity rules. |
| PD00-ACC-CMP | `ComplianceFramework` | AC | NIST / SOC 2 / ISO 27001 / OWASP alignment (currently referenced only in `@ContentHelp`). |
| PD00-ROL-PIL | `PilotPlan` | SR | Pilot scope and success criteria. |
| PD00-ROL-CUT | `CutoverProcedures` | SR | Cutover runbook. |

#### Dropped proposals (duplicates with existing content)

| Originally proposed | Reason dropped |
| --- | --- |
| PD00-CUR-INT (Integration Points) | Content lives in `PD00-CUR-SYS-DEP`, accessible via the `existingSystemsLandscape` top-level (PD00-CUR-SYS). |
| PD00-SYO-REQ-PRO / -PRI / -CHA | Already `@Form` fields on `RequirementsOverview` (`requirementsProcess`, `prioritizationMethod`, `changeControlProcess`). Kept as fields. |
| PD00-TAR-STP-CAT, -ALT, -PRE | `InteractionCatalog` (PD00-TAR-STP-INT) and `PreconditionsAndTriggers` inside each interaction entry already cover these. |
| PD00-BUS-LIF | Per-object lifecycle lives inside `PD00-BUS-BUS-CAT` entries (`LifecycleTransitionEntry`). |
| PD00-BUS-CLA, PD00-BUS-REL | Already exist as `PD00-BUS-DAT-CLA` and `PD00-BUS-DAT-REL`. BDM top-levels point at those IDs directly. |
| PD00-BUS-MIG | Per-entity migration lives inside `PD00-BUS-DAT-ENT` entries (`MigrationMappingEntry`). |
| PD00-BUS-RUL | Already `PD00-BUS-FUN-RUL` (list). BDM top-level points there. |
| PD00-TEC-INF | `InfrastructureComponentEntry` already lives inside `PD00-TEC-HAR`. |
| PD00-TEC-INT | Overlaps with `PD00-TEC-COM` (Communication Requirements). |
| PD00-ACC-FLO | Content lives in `PD00-ACC-IDE-FLO`, accessible via the `identificationAndAuthentication` top-level (PD00-ACC-IDE). |
| PD00-ACC-PER | `PermissionGranularityPolicy` / `PermissionCompositionStrategy` / `PermissionEvaluationBehavior` already live inside `PD00-ACC-USA`. |
| PD00-SSP-PHD | Covered by `PD00-SSP-STA` + stages list. |
| PD00-SSP-GAT | Already `PD00-SSP-GOV-GAT` — PPP top-level points there. |
| PD00-SSP-RES | `StageOverviewResources` already lives inside `PD00-SSP-STA`. |
| PD00-USE-INF | Content lives in `PD00-USE-SCR-INF`, accessible via the `screens` top-level (PD00-USE-SCR). |

### 7.4. Execution Order

Recommended order so the outliner stays green after each step:

1. **Track 2 promotions first** — add `@SectionId` to the two untagged classes (`ProcessStepsOverview`, `ActorRelationshipDiagram`), and add `@DetailedIn(...)` to all five promoted classes plus the `@MapsTo(...)` on their parent seeds. No structural change; outliner output must be unchanged.
2. **Reclassify `PD00-CUR`** — drop `@Unused()` on `content`, add the two Track-3 new children (`MET`, `RIS`), update §4 PD-only list. Single-concern commit.
3. **Add `PD00-ROL`** (Track 1, top-level) — new field on `ProjectDefinition` with its 8 children (6 T1 + 2 T3). Update `pd_project_definition.dart` exports.
4. **Track 1 extensions in existing sections** — BP, UC, BDM, TR, UP, AC, BQP, PPP, BSI additions are independent; parallelizable.
5. **Track 3 remaining additions** — add the remaining inferred sections per target doc.
6. **Annotate with `@MapsTo` / `@DetailedIn`** (§8) — can run concurrently with steps 3–5 per subtree.
7. **Run the outliner** with `--root-type ProjectDefinition` after every grouped addition.

Only after §7 is complete should any Phase 3 document class be introduced — at that point every target-document top-level entry has a PD00 class to point to.

---

## 8. Annotation Rules: `@MapsTo` and `@DetailedIn`

Two annotations record the PD00 → DocSpec structure directly on the PD00 class tree so the mapping is discoverable from code and mechanically verifiable by the outliner. Both live in `tom_specs_core` (see [lib/src/annotations/maps_to.dart](../../tom_specs_core/lib/src/annotations/maps_to.dart) and [lib/src/annotations/detailed_in.dart](../../tom_specs_core/lib/src/annotations/detailed_in.dart)).

### 8.1. `@MapsTo(DocumentClass)`

**Meaning.** This class is the **1:1 mapping point** between PD00 and the named DocSpec. Its entire subtree flows to that document and nothing else.

**Where it goes.** On the shallowest PD00 class whose whole subtree is the source for a single target DocSpec — that is the **seed node** identified by the cut-depth rule in §2. If a PD00 subtree splits between multiple targets, no class in the split has `@MapsTo`; instead, each child that itself maps 1:1 carries `@MapsTo` individually.

**Count.** One `@MapsTo` per entry in §6 column "Seed nodes". A multi-source target document (TR, UP, SR, BQP) has multiple seed classes, each with its own `@MapsTo(SameDocumentClass)`.

### 8.2. `@DetailedIn(DocumentClass)`

**Meaning.** This class's content is **taken over as a top-level entry** in the named DocSpec. It marks the take-off level from PD00 into the target document's top level.

**Where it goes.** On the class that appears as a direct top-level entry of the target DocSpec (per §5 tables):

- **Seed kept whole** (Origin `seeded (whole)` in §5): the seed class carries `@DetailedIn`.
- **Seed flattened one level** (Origin `seeded (flat)` in §5): each direct child of the seed that becomes a top-level entry carries `@DetailedIn`.

Children promoted by flattening do *not* carry `@MapsTo` — only the seed (their parent) does.

### 8.3. When a class carries both

A class carries both `@MapsTo` and `@DetailedIn` whenever the same class is both the 1:1 mapping point *and* a top-level entry in the target document. Two shapes produce this:

- **Shape A — Whole seed promoted.** The seed node is used directly as a top-level (`seeded (whole)` in §5). The seed class is both the mapping point and the top-level.
- **Shape B — Mixed parent; child is the mapping point.** The parent is mixed (subtree splits between target docs, or parts stay PD-only), so `@MapsTo` does not live on the parent. If one of the children (a) has its own subtree fully flowing to the target doc *and* (b) is taken over as a target-doc top-level, that child carries both `@MapsTo` and `@DetailedIn`.

Worked micro-example (illustrating Shape B with a fictional `PD00-SYO-SYS`):

> Assume `PD00-SYO-SYS` has only two children, `PD00-SYO-SYS-RE1` and `PD00-SYO-SYS-RE2`, and both flow to TR as separate top-levels.
>
> - **Parent not mixed case** — if nothing else under `PD00-SYO-SYS` goes elsewhere and `PD00-SYO-SYS` is flattened to its two children: `PD00-SYO-SYS` gets `@MapsTo(TR)` (seed), children get `@DetailedIn(TR)` only.
> - **Parent not mixed, seed kept whole** — if `PD00-SYO-SYS` is taken over whole as a single TR top-level: `PD00-SYO-SYS` gets both `@MapsTo(TR)` + `@DetailedIn(TR)`; children get nothing.
> - **Parent mixed** — if `PD00-SYO-SYS` has additional children going to another doc (or PD-only): `PD00-SYO-SYS` gets no `@MapsTo`. `RE1` and `RE2` each get both `@MapsTo(TR)` + `@DetailedIn(TR)`, because each child is itself the shallowest point whose subtree fully flows to TR *and* each is a TR top-level.

Examples from the current plan:

- `BusinessObjectAndDataModel` (PD00-BUS): `@MapsTo(BusinessDataModel)` — not `@DetailedIn`, because §5.5 flattens two levels deep into DAT/BUS/FUN children.
- `DataModel`, `BusinessObjectModel`, `FunctionModel`: `@MapsTo(BusinessDataModel)` — each fully flows to BDM. Not `@DetailedIn`, because BDM flattens another level further.
- Every PD00-BUS-{DAT,BUS,FUN}-* class used as a BDM top-level: `@DetailedIn(BusinessDataModel)` only.
- `ComponentsToUse` (PD00-COM): Shape A — both annotations, kept whole as TR top-level 10 (§5.7).
- `TechnicalFrameworkConditions` (PD00-SYO-RES-TEC): Shape B — parent `PD00-SYO-RES` is mixed (other RES-* children are PD-only), so RES-TEC gets both.
- `TranslationRequirements` (PD00-USE-MUL-REQ): Shape B — parent `PD00-USE-MUL` is mixed (LCS → UP, LOC/TRA/DOC → SR), so MUL-REQ gets both.
- Every PD00-USE-* class flowing to UP (§5.8): all 13 carry both (Shape A).
- `LocalizationProcess`, `TranslationProcess`, `DocumentationAndTraining` (§5.9): Shape B via `PD00-USE-MUL` (mixed). All three carry both.
- `CurrentStateAnalysis` (PD00-CUR): `@MapsTo(CurrentSituation)` only — flattened. Each PD00-CUR-* child: `@DetailedIn(CurrentSituation)` only.
- `SystemStagePlan` (PD00-SSP): `@MapsTo(ProjectPhasePlan)` only — flattened into PPP top-levels.
- `SystemRolloutConcept` (PD00-ROL): `@MapsTo(SystemRollout)` only — flattened into 8 SR top-levels.

### 8.4. `@SecondLevelSectionId` (document-scoped short IDs)

`@SecondLevelSectionId(DocClass, 'XXX-YYY')` (defined in [tom_specs_core/lib/src/annotations/second_level_section_id.dart](../../tom_specs_core/lib/src/annotations/second_level_section_id.dart)) is available for future use. Phase 3 documents initially inherit the global `PD00-…` section IDs as-is; the short-ID scheme can be introduced later by adding one of these annotations per target-doc participation on the relevant classes. A class may carry multiple `@SecondLevelSectionId` annotations when it is a top-level in more than one document.

Example (not applied yet):

```dart
@SectionId('PD00-BUS-DAT-CLA')
@DetailedIn(BusinessDataModel)
@SecondLevelSectionId(BusinessDataModel, 'BDM-CLA')   // optional, for future use
class DataClassification { ... }
```

### 8.5. Worked example: the BDM branch

Per §5.5 BDM flattens two levels — top-levels in BDM are at `PD00-BUS-{DAT,BUS,FUN}-*`, not at the seed's direct children.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

@SectionId('PD00-BUS')
@MapsTo(BusinessDataModel)
class BusinessObjectAndDataModel { ... }      // seed — not a top-level

@SectionId('PD00-BUS-DAT')
@MapsTo(BusinessDataModel)
class DataModel { ... }                        // maps fully to BDM, still not a top-level

@SectionId('PD00-BUS-DAT-REL')
@DetailedIn(BusinessDataModel)
class EntityRelationships { ... }              // BDM top-level

@SectionId('PD00-BUS-DAT-CLA')
@DetailedIn(BusinessDataModel)
class DataClassification { ... }               // BDM top-level

@SectionId('PD00-BUS-FUN-RUL')
@DetailedIn(BusinessDataModel)
class BusinessRuleCatalog { ... }              // BDM top-level
```

And for a whole-seed case (Shape A):

```dart
@SectionId('PD00-COM')
@MapsTo(TechnicalRequirementsSpec)
@DetailedIn(TechnicalRequirementsSpec)
class ComponentsToUse { ... }                  // seed kept whole → both annotations
```

And for a mixed-parent case (Shape B), e.g. `PD00-USE-MUL-REQ`:

```dart
// Parent PD00-USE-MUL is mixed — no @MapsTo on it.
@SectionId('PD00-USE-MUL-REQ')
@MapsTo(TechnicalRequirementsSpec)
@DetailedIn(TechnicalRequirementsSpec)
class TranslationRequirements { ... }          // both annotations on the child
```

### 8.6. Mechanical invariants (validator can enforce)

**Annotation coverage (this wave):**

- Every class that appears in any §5 "Source" column has exactly one `@DetailedIn`.
- Every seed class listed in §6 (the classes named in "Seed nodes") has exactly one `@MapsTo`.
- For each target DocSpec `D`, the count of `@DetailedIn(D)` in the PD00 tree equals `D`'s "Total tops" column in §6.
- No class carries `@DetailedIn` without either (a) also carrying `@MapsTo`, or (b) having an ancestor (not necessarily direct parent) that carries `@MapsTo` for the same target.
- `@SecondLevelSectionId(D, ...)` on a class implies `@DetailedIn(D)` on the same class.

**Section-ID coverage and uniqueness (structural, not yet enforced):**

- **Section-ID uniqueness — globally, across the PD document tree.** Every string literal used as `@SectionId('…')` anywhere in the `ProjectDefinition` reachable tree must be unique across *all* classes. `ProjectDefinition` reaches every section class in the model (verified: 284 class-level `@SectionId`s, all reachable from the PD root, no duplicates as of this commit), so uniqueness is a single global property — not scoped per Phase 3 document. Same rule applies to `@SectionIdPattern('…-xx')`: unique globally.
- **Section-ID coverage.** Every class reachable from `ProjectDefinition` is expected to carry a `@SectionId` on the class, or — for list element classes — to be reached via a field whose declaration carries a `@SectionIdPattern`. Since every Phase 3 document root types against classes already reachable from PD, this guarantees every class participating in any outline has an ID.
- **`@SecondLevelSectionId` derivation rule.** The document-scoped short ID of a class is derived mechanically, not authored free-hand: take the class's global `@SectionId`, find the nearest ancestor class (on the same target-doc path) that carries `@DetailedIn(D)`, trim the prefix up to and including that ancestor's `@SectionId`, and prefix the remainder with `<docId>-`.

  Example: with `@DetailedIn(TechnicalRequirementsSpec)` applied at the classes with `@SectionId('PD00-SE1-SX1-SS1')` and `@SectionId('PD00-SE1-SX1-SS2')`, the short IDs become `TR-SS1` and `TR-SS2` respectively. The prefix `PD00-SE1-SX1-` — shared by the `@DetailedIn`-carrying classes — is cut off and replaced with `TR-`.

  When the `@DetailedIn` class has deeper descendants (not carrying their own `@DetailedIn`), the derivation uses *that ancestor's* `@SectionId` as the cut-off prefix. So a descendant `PD00-SE1-SX1-SS1-XX1` would become `TR-SS1-XX1`.
- **`@SecondLevelSectionId` uniqueness within a document.** For each target DocSpec `D`, all derived short IDs must be unique within `D`'s reachable tree. Since the remainder after the cut-off is a suffix of a globally-unique `@SectionId`, collisions can only occur if the same suffix appears under two different `@DetailedIn(D)` cut-points — which the validator must detect.

The existing validator at [tom_specs_clitool/lib/src/validator.dart](../../tom_specs_clitool/lib/src/validator.dart) today covers §6.1 field-type rules, `@ContentType` compatibility, and cycle detection from a given root. It does **not** yet enforce any of the invariants above — adding those checks is Step 20 below.

---

## 9. Document Root Class Implementation Plan

Runs *after* §7 (PD00 completion) is done. Creates the 12 Phase 3 document classes that the §5 tables define. Each document root class is a thin aggregation over existing PD00 classes — no new section content is authored here; the content already lives in PD00.

### 9.1. Per-document deliverables

For each target document `D` in {CS, RC, BP, UC, BDM, AC, TR, UP, SR, BQP, PPP, BSI} create:

1. Folder `tom_specs_model/lib/src/<code>_<name>/` (e.g. `bdm_business_data_model/`).
2. One Dart file `bdm_business_data_model.dart` (or equivalent per document) containing the document root class. Keep it small — it is an aggregation, not new content.
3. An entry in the package's top-level export file `lib/tom_specs_model.dart`.

The document root class shape:

```dart
library;

import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/src/pd_project_definition/pd_project_definition.dart';
import 'package:tom_specs_model/src/common/document_header.dart';

@Document(
  name: 'Business Data Model',
  description: 'Complete data model specification: entities, relationships, '
      'dictionary, rules, and constraints for the target system.',
  basedOn: [ProjectDefinition],
)
@SectionId('BDM00')
class BusinessDataModel {
  @ContentHelp('Executive overview of the Business Data Model.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── Top-level entries (from §5.5) ────────────────────────────────────────
  // Each field types against the existing PD00 class — no new classes are
  // created here. Fields are listed in the order from §5.5.

  List<DataEntityEntry> entities = [];              // PD00-BUS-DAT-ENT
  EntityRelationships entityRelationships = EntityRelationships();  // PD00-BUS-DAT-REL
  ErDiagramSection erDiagram = ErDiagramSection(); // PD00-BUS-DAT-DIA
  DataClassification dataClassification = DataClassification();     // PD00-BUS-DAT-CLA
  List<BusinessObjectEntry> objectCatalog = [];    // PD00-BUS-BUS-CAT
  // …etc per §5.5…
}
```

Key points:

- `@SectionId('<CODE>00')` uses the document code and `00` suffix as the root section ID (e.g., `BDM00`, `RC00`, `TR00`). This is the global ID for the document root; it is distinct from PD00.
- Every field types against an **existing class in `pd_project_definition/`**. Initially there are no new classes inside the target-doc folder — the folder holds only the document root class. (Target-doc-specific helper types can be added later if needed.)
- Fields inherit the global `PD00-…` section IDs via the classes they type against. No document-scoped short IDs are introduced at this point.
- `@SecondLevelSectionId(…)` is available (see §8.4) but not applied in this first pass. A follow-up PR can add it per top-level entry if the short-ID scheme is adopted.

### 9.2. Order of document creation

Recommended order so each document root exercises the outliner incrementally:

1. **Smallest first** to validate the pattern: **BSI** (10 top-levels, single seed), then **CS** (9, two seeds).
2. **Medium single-source** next: **RC** (7), **UC** (7), **BP** (10), **BDM** (12), **AC** (9), **PPP** (9).
3. **Multi-source docs** last, where the aggregation is most complex: **TR** (12), **UP** (13), **SR** (11), **BQP** (14).

After each document's root class is added, run:

```sh
dart run bin/outliner.dart --package <target> --root-type <DocName>
```

against `tom_specs_model`. The outline should render the 7–15 top-levels listed in §5 for that document.

### 9.3. Package exports

Update `lib/tom_specs_model.dart` with one new export per document:

```dart
export 'src/cs_current_situation/cs_current_situation.dart';
export 'src/rc_requirements_catalog/rc_requirements_catalog.dart';
export 'src/bp_business_processes/bp_business_processes.dart';
// …one per DocSpec…
```

### 9.4. What this phase does *not* do

- **Does not introduce document-scoped short IDs.** Section IDs on every class remain the global `PD00-…` IDs. Short-ID introduction is a separate later decision (see §8.4).
- **Does not rewrite or fork PD00 classes.** Document roots reference existing classes by type; they do not copy or extend them.
- **Does not add new sections.** All new sections were added in §7. If more are needed later, they go through the three-track process.
- **Does not change the outliner.** The outliner already supports arbitrary `--root-type`; no tool changes required.

### 9.5. Exit criteria for this phase

- All 12 document root classes exist, compile, and pass `dart analyze`.
- Each runs clean through the outliner with its own `--root-type`.
- The `ProjectDefinition` outline is unchanged — the aggregation is purely additive.
- `@MapsTo` / `@DetailedIn` counts per target match §6 and §8.6 invariants.

---

## 10. Implementation Notes

- **PD00 completion is step 1.** No Phase 3 document class is created before §7 is finished — a class referencing a non-existent PD00 class would not compile and would defeat the completeness rule that motivated §7.
- **Reuse, don't duplicate.** The seeded fields type against the existing PD00 classes (`BusinessObjectAndDataModel`, `SystemStagePlan`, etc.). The target document class imports `package:tom_specs_model/.../pd_project_definition/...` and uses the same types. No expansion-only sections exist anymore — every target top-level types against a PD00 class.
- **One folder per document.** Add `lib/src/cs_current_situation/`, `lib/src/rc_requirements_catalog/`, … mirroring `pd_project_definition/`. Top-level file exports the root class (e.g., `CurrentSituation`, `RequirementsCatalog`).
- **Annotate every new root.** `@Document(…, basedOn: [ProjectDefinition])` and `@SectionId('<CODE>00')` on the class, and re-export from `lib/tom_specs_model.dart`.
- **Outliner root type.** Once a document class exists, the outliner can run with `--root-type <DocName>` against `tom_specs_model` to validate that the new class tree traverses cleanly. Also run with `--root-type ProjectDefinition` after each §7 step.
- **UC decision pending.** Resolve the UC question (§5.4) before starting — either implement UC in this wave or explicitly reroute PD00-TAR-STP.
- **Mapping doc out of date.** Section 1 lists the known IDs that have drifted between `hbsg_tom_resulttype_mapping.md` and the current model. Update the mapping doc after §7 lands so it stops contradicting the code.

---

## 11. Step-by-Step Implementation Plan

End-to-end ordered sequence across the work defined in §7, §8, and §9. Each step identifies the driving section, what needs to be done, and the exit condition. Steps run sequentially unless marked parallelizable. Commit one step per commit so regressions are bisectable; run the outliner after every step.

### Phase A — PD00 Completion (§7)

#### Step 1 — Track 2 promotions + PD00-TAR-PRO-REL fix (§7.2, §8.2)

**What:**
- Add `@SectionId('PD00-TAR-STP-OVE')` + `@DetailedIn(UseCases)` to `ProcessStepsOverview` ([target_business_process.dart:1127](../lib/src/pd_project_definition/target_business_process.dart#L1127)).
- Add `@SectionId('PD00-TAR-STP-DIA')` + `@DetailedIn(UseCases)` to `ActorRelationshipDiagram` ([target_business_process.dart:1150](../lib/src/pd_project_definition/target_business_process.dart#L1150)).
- Update the field-level doc comment on `BusinessProcessDescriptions.processRelationships` to carry the `[PD00-TAR-PRO-REL]` section ID (the class already carries `@SectionId`).

**Why first:** smallest viable change. Exercises the annotation infrastructure (imports of `tom_specs_core`, analyzer picks up annotations, `@DetailedIn(UseCases)` resolves via the Step 0 stub). Outliner output gains two newly-tagged sections; everything else unchanged.

**Exit:** `dart analyze` clean; outliner renders the two new `@SectionId`s under PD00-TAR-STP.

#### Step 2 — Reclassify PD00-CUR and add its three inferred children (§7.3, §4, §3)

**What:**
- Drop `@Unused()` on `CurrentStateAnalysis.content`.
- Add `CurrentOperationalMetrics` (`PD00-CUR-MET`) and `CurrentStateRiskAssessment` (`PD00-CUR-RIS`) child classes. (The third CUR-family item, `dependenciesAndIntegrations`, is a promotion already covered in Step 1.)
- Add `@MapsTo(CurrentSituation)` on `CurrentStateAnalysis`; `@DetailedIn(CurrentSituation)` on each of the six existing children (SYS, PRO, PAI, DAT, plus SYS-DEP promoted, plus MET, RIS).
- Remove PD00-CUR from §4's PD-only list in any version of the doc that references it.

**Why:** PD00-CUR is the only subtree that moves from PD-only into a DocSpec target. Isolating it in a single step keeps the change auditable.

**Exit:** outliner shows PD00-CUR subtree unchanged except for the two new children; CS wave (not yet created) has a complete PD-side source.

#### Step 3 — Add PD00-ROL top-level and its children (§7.1, §3)

**What:**
- Create `lib/src/pd_project_definition/system_rollout_concept.dart` with `SystemRolloutConcept` root class (`@SectionId('PD00-ROL')`, `@MapsTo(SystemRollout)`). (`SystemRollout` is reserved as the SR target-doc class name.)
- Create the 8 child classes listed in §5.9 rows 4–11 (6 T1 + 2 T3). Each gets `@SectionId('PD00-ROL-XXX')` + `@DetailedIn(SystemRollout)`.
- Add `systemRolloutConcept: SystemRolloutConcept()` field to `ProjectDefinition` (after `userInterfaceDesign`, before `systemQualityGoals`).
- Update `pd_project_definition.dart` to export the new file.

**Why:** `PD00-ROL` is the only net-new top-level on `ProjectDefinition`. Isolating it prevents accidental collateral damage on existing sections.

**Exit:** outliner shows `PD00-ROL` as a new top-level with 8 children; rest of tree unchanged.

#### Step 4 — Track 1 extensions in existing sections (§7.1)

**What:** Add the remaining 15 HBSG-backed sections to their existing parents. Parallelizable — each parent is independent:

| Parent | New children |
| --- | --- |
| PD00-TAR-PRO | DET, CRO, EXC |
| PD00-TAR-STP | E2E |
| PD00-BUS-DAT | DIC |
| PD00-TEC | ARC |
| PD00-USE | WIR |
| PD00-ACC | ROL |
| PD00-SYQ | TST |
| PD00-SSP | IDV, UPG |
| PD00-SYO-SYB | INV, PAT, TST, DEP, MIG |

Each new class: `@SectionId('PD00-X-Y...')` + `@DetailedIn(TargetDoc)`.

**Why:** these additions don't touch each other. Commit per parent for clean git history.

**Exit:** each added class reachable from its parent; outliner runs clean with `ProjectDefinition` root.

#### Step 5 — Track 3 remaining additions (§7.3)

**What:** Add the 10 inferred sections that weren't already added in Steps 2–3. Parallelizable:

| Parent | New children |
| --- | --- |
| PD00-SYO-REQ | REL, COV |
| PD00-TAR-PRO | MET |
| PD00-TAR-STP | TRC |
| PD00-BUS-DAT | VAL, CON |
| PD00-ACC | CMP |
| PD00-SYO-SYB | OPE, ERR |

**Why:** these are my inferred additions — lower confidence than Track 1. Isolating them in Step 5 makes them easy to review or roll back independently of HBSG-backed work.

**Exit:** same as Step 4.

#### Step 6 — Complete `@MapsTo` / `@DetailedIn` coverage (§8.1, §8.2, §8.3)

**What:** Sweep the PD00 tree to ensure the invariants in §8.6 hold:
- `@MapsTo(D)` on every seed class in §6 per document.
- `@DetailedIn(D)` on every class referenced in §5 "Source" columns.
- Shape-B cases (mixed parent): verify child has both annotations per §8.3.

**Why:** Steps 1–5 add individual annotations locally; Step 6 is the audit that nothing was missed. Best done by a simple grep-based checker per target doc.

**Exit:** §8.6 invariants hold mechanically. A temporary shell script (or quick extension to `tom_specs_clitool/lib/src/validator.dart` per Step 22) can assert this.

#### Step 7 — Update `_ai/quests/tom_specs/hbsg_tom_resulttype_mapping.md` (§1)

**What:** Reconcile the mapping doc with the completed PD00 model. Specifically:
- Replace `PD00-SYS` with `PD00-SYO` throughout.
- Remove `PD00-CUR` from the PD-only column; add it as a CS source.
- Add the 35 new PD00 section IDs to the leaf section mapping appendix.
- Update version header (to v3.6) and append a changelog entry.

**Why:** the mapping doc remains the authoritative external reference. Leaving it out of sync is a bigger cost than the work. Do it now while the changes are fresh.

**Exit:** mapping doc version bumped; §1's naming reconciliation table's "existing" rows no longer describe drift.

**Phase A exit criterion:** PD00 model is complete. `dart analyze` clean on tom_specs_core, tom_specs_model. Outliner runs clean on `ProjectDefinition`. §8.6 invariants hold.

### Phase B — Document Root Classes (§9)

All Phase B steps follow the template in §9.1. Order per §9.2: smallest single-source first, multi-source last. One commit per document root.

#### Step 8 — BSI root class (§5.12, §9.2)

**What:** Create `lib/src/bsi_business_system_interactions/` with `BusinessSystemInteractions` root class. 10 top-level fields typed against `PD00-SYO-SYB-*` classes. Add package export.

**Why first:** smallest single-source doc. Validates the §9.1 template end-to-end.

**Exit:** `outliner --root-type BusinessSystemInteractions` matches §5.12; `dart analyze` green.

#### Step 9 — CS root class (§5.1, §9.2)

**What:** `CurrentSituation` class with 9 top-levels from two seeds (PD00-CUR and PD00-SYO-SYR).

**Why:** CS is the simplest multi-source doc (only two seeds). Smooths the path to bigger multi-source docs later.

**Exit:** outliner renders 9 top-levels matching §5.1.

#### Steps 10–15 — RC, BP, UC, BDM, AC, PPP (§5.2, §5.3, §5.4, §5.5, §5.6, §5.11)

**What:** Create root classes one per step, in that order.

- **Step 10 RC (§5.2):** 7 top-levels under `PD00-SYO-REQ`.
- **Step 11 BP (§5.3):** 10 top-levels under `PD00-TAR-PRO`.
- **Step 12 UC (§5.4):** 7 top-levels under `PD00-TAR-STP`. Do only after the UC decision (§5.4 note) is final.
- **Step 13 BDM (§5.5):** 12 top-levels at `PD00-BUS-{DAT,BUS,FUN}-*` — the "go one level deeper" case.
- **Step 14 AC (§5.6):** 9 top-levels under `PD00-ACC` with one promoted (PD00-ACC-IDE-FLO).
- **Step 15 PPP (§5.11):** 9 top-levels under `PD00-SSP` with two promoted (PD00-SSP-GOV-GAT, -DEC).

**Why:** these are all single-source docs. Shared pattern; low risk once BSI and CS are done.

**Exit (each step):** outliner `--root-type <DocName>` matches the corresponding §5 row.

#### Steps 16–19 — Multi-source docs TR, UP, SR, BQP (§5.7, §5.8, §5.9, §5.10)

**What:** Larger aggregations. The doc root class pulls fields from multiple PD00 branches.

- **Step 16 TR (§5.7):** 12 top-levels from PD00-TEC (flatten) + PD00-COM (whole) + PD00-SYO-RES-TEC + PD00-USE-MUL-REQ.
- **Step 17 UP (§5.8):** 13 top-levels from 11 existing PD00-USE-* + PD00-USE-WIR + PD00-USE-SCR-INF (promoted).
- **Step 18 SR (§5.9):** 11 top-levels from PD00-USE-MUL-{LOC,TRA,DOC} + PD00-ROL children.
- **Step 19 BQP (§5.10):** 14 top-levels from PD00-SYQ + PD00-DEL-ACC.

**Why:** multi-source aggregation requires careful import hygiene. Saved for last once the template is proven.

**Exit (each step):** outliner matches §5; `dart analyze` green.

**Phase B exit criterion:** 12 document root classes exist and compile; each produces a valid outliner outline matching §5; `ProjectDefinition` outline is unchanged (purely additive).

### Phase C — Cross-cutting follow-ups

#### Step 20 — Validator for §8.6 invariants (§8.6, tom_specs_clitool)

**What:** Extend [tom_specs_clitool/lib/src/validator.dart](../../tom_specs_clitool/lib/src/validator.dart) — currently covers §6.1 field-type rules, `@ContentType` compatibility, and cycle detection — with the following new checks:

*Section-ID structural checks:*
- **`@SectionId` uniqueness (global).** Collect every string literal used in `@SectionId('…')` across all classes reachable from `ProjectDefinition`. Assert no duplicates. Same for `@SectionIdPattern('…-xx')` — global uniqueness required. (Current state: 284 PD-reachable class-level `@SectionId`s, zero duplicates.)
- **`@SectionId` coverage.** Every class reachable from `ProjectDefinition` is expected to carry a class-level `@SectionId`. Exception: list element classes reached via a field that carries `@SectionIdPattern`. Report any reachable class without either.
- **`@SecondLevelSectionId` derivation and uniqueness per document.** If the short-ID scheme is adopted (§8.4), either (a) compute the short ID mechanically from the class's `@SectionId` and the nearest ancestral `@DetailedIn(D)` per the rule in §8.6 and assert any authored `@SecondLevelSectionId(D, '…')` matches the derived value, or (b) if not authored explicitly, just compute the short IDs and assert uniqueness within each target DocSpec `D`'s reachable tree.

*`@MapsTo` / `@DetailedIn` checks:*
- **Detail-count check:** for each `@Document`-tagged class `D`, count `@DetailedIn(D)` occurrences; assert == §6 "Total tops" for that doc.
- **Ancestor check:** every class carrying `@DetailedIn(D)` must carry `@MapsTo(D)` on itself or an ancestor.
- **Map-uniqueness check:** no duplicate `@MapsTo` annotations per (class, doc) pair.
- **`@SecondLevelSectionId` implies `@DetailedIn`:** any class with `@SecondLevelSectionId(D, ...)` must also carry `@DetailedIn(D)`.

Wire the validator into a test in `tom_specs_clitool/test/` so CI catches regressions as PD00 and the Phase 3 roots evolve.

**Why:** mechanically enforces the invariants defined in §8.6 — both the pre-existing structural rules on `@SectionId` and the new annotation-graph rules introduced in this wave.

**Exit:** validator passes against the fully-annotated model; test runs in CI; any new class added without a `@SectionId`, or any duplicate ID, fails the check.

#### Step 21 — Decide on `@SecondLevelSectionId` adoption (§8.4, §9.4)

**What:** Decision point. Either:
- **Adopt:** go through each target-doc top-level in §5 and add one `@SecondLevelSectionId(Doc, '<CODE>-<SUFFIX>')` per entry. ~125 annotations total across 12 docs.
- **Defer:** leave as-is; global `PD00-*` IDs remain the only IDs.

**Why:** the short-ID scheme was reserved in annotation form but left unapplied on purpose (§9.4). Adopting it needs one bulk pass; it can happen any time after Phase B, so it's listed last.

**Exit:** either all §5 top-levels carry `@SecondLevelSectionId`, or this step is explicitly marked deferred in the quest notes.

#### Step 22 — Update session resume and quest overview (quest docs)

**What:** Update `_ai/quests/tom_specs/session_resume.tom_specs.md` and `overview.tom_specs.md` to describe the completed second-wave implementation (PD00 completion + 12 document root classes). Add a "Completed Work" entry; revise "What The Quest Is Working On Now" to describe what follows (e.g., content filling, template generation, first project use).

**Why:** keeps the quest docs authoritative about the state of the work; a next-session pickup should see the current state immediately.

**Exit:** quest docs reflect the second wave as complete.

### Final quality gate

After all steps:

- `dart analyze` green on tom_specs_core, tom_specs_model, tom_specs_clitool.
- Outliner runs clean with every valid `--root-type`: `ProjectDefinition` and all 12 document classes.
- Validator passes.
- `hbsg_tom_resulttype_mapping.md` in sync with the model.
- Quest docs updated.
