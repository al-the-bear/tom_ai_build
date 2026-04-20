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
| AS08-DAT | `PD00-BUS-DIC` | new (§7) |
| AS09-SOF / DR30 | `PD00-TEC-ARC` | new (§7) |
| AS10-WIR | `PD00-USE-WIR` | new (§7) |
| AS10-INF | `PD00-USE-INF` | new (§7) |
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
- **Origin** — `seeded (flat)` means the entry is a direct child of the seed node promoted one level up; `seeded (whole)` means the seed node itself is used as a single entry.
- **Source** — PD00 section ID. **New** in the Source column flags a PD00 section that does not exist yet and must be added first; those additions are consolidated in §7 PD00 Completion Plan.

### 5.1. CS — Current Situation

**Seed nodes:** PD00-CUR (whole; extended with new children) + PD00-SYO-SYR (2 children). Two-source; flatten each. `PD00-CUR` was previously listed as PD-only — moving its subtree to CS is part of the completeness work in §7.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `existingSystemsLandscape` | seeded (flat) | PD00-CUR-SYS |
| 2 | `currentBusinessProcesses` | seeded (flat) | PD00-CUR-PRO |
| 3 | `painPointsAndGaps` | seeded (flat) | PD00-CUR-PAI |
| 4 | `currentDataLandscape` | seeded (flat) | PD00-CUR-DAT |
| 5 | `currentIntegrationPoints` | seeded (flat) | PD00-CUR-INT **(new)** |
| 6 | `operationalMetrics` | seeded (flat) | PD00-CUR-MET **(new)** |
| 7 | `riskAssessment` | seeded (flat) | PD00-CUR-RIS **(new)** |
| 8 | `replacementInventory` | seeded (flat) | PD00-SYO-SYR-INV |
| 9 | `migrationConsiderations` | seeded (flat) | PD00-SYO-SYR-MIG |

**Count: 9.**

### 5.2. RC — Requirements Catalog

**Seed nodes:** PD00-SYO-REQ (4 existing + 5 new children). Single-source; flatten.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `functionalRequirements` | seeded (flat) | PD00-SYO-REQ-FUN |
| 2 | `technicalRequirements` | seeded (flat) | PD00-SYO-REQ-TEC |
| 3 | `securityRequirements` | seeded (flat) | PD00-SYO-REQ-SEC |
| 4 | `organizationalRequirements` | seeded (flat) | PD00-SYO-REQ-ORG |
| 5 | `traceabilityMatrix` | seeded (flat) | PD00-SYO-REQ-TRC |
| 6 | `requirementsProcess` | seeded (flat) | PD00-SYO-REQ-PRO **(new)** |
| 7 | `prioritizationScheme` | seeded (flat) | PD00-SYO-REQ-PRI **(new)** |
| 8 | `changeControlLog` | seeded (flat) | PD00-SYO-REQ-CHA **(new)** |
| 9 | `requirementRelationships` | seeded (flat) | PD00-SYO-REQ-REL **(new)** |
| 10 | `requirementCoverage` | seeded (flat) | PD00-SYO-REQ-COV **(new)** |

**Count: 10.**

### 5.3. BP — Business Processes

**Seed nodes:** PD00-TAR-PRO (5 existing sectioned children, 1 existing flat field to be tagged, and 4 new children). Single-source; flatten.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `processVision` | seeded (flat) | PD00-TAR-PRO-VIS |
| 2 | `designPrinciples` | seeded (flat) | PD00-TAR-PRO-PRI |
| 3 | `processCatalog` | seeded (flat) | PD00-TAR-PRO-CAT |
| 4 | `processOverviewDiagram` | seeded (flat) | PD00-TAR-PRO-FLO |
| 5 | `improvementSummary` | seeded (flat) | PD00-TAR-PRO-IMP |
| 6 | `processRelationships` | seeded (flat) | PD00-TAR-PRO-REL **(promote existing untagged field)** |
| 7 | `detailedWorkflows` | seeded (flat) | PD00-TAR-PRO-DET **(new)** |
| 8 | `crossProcessAnalysis` | seeded (flat) | PD00-TAR-PRO-CRO **(new)** |
| 9 | `exceptionHandling` | seeded (flat) | PD00-TAR-PRO-EXC **(new)** |
| 10 | `processMetricsAndKpis` | seeded (flat) | PD00-TAR-PRO-MET **(new)** |

**Count: 10.**

### 5.4. UC — Use Cases

**Seed nodes:** PD00-TAR-STP (3 existing sectioned children + 2 untagged fields to promote + 5 new children). Single-source; flatten.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `processStepsOverview` | seeded (flat) | PD00-TAR-STP-OVE **(promote existing untagged field)** |
| 2 | `actorOverview` | seeded (flat) | PD00-TAR-STP-ACT |
| 3 | `interactionCatalog` | seeded (flat) | PD00-TAR-STP-INT |
| 4 | `keyScenarios` | seeded (flat) | PD00-TAR-STP-SCE |
| 5 | `actorRelationshipDiagram` | seeded (flat) | PD00-TAR-STP-DIA **(promote existing untagged field)** |
| 6 | `useCaseCatalog` | seeded (flat) | PD00-TAR-STP-CAT **(new — fully-dressed Cockburn UCs)** |
| 7 | `alternateFlows` | seeded (flat) | PD00-TAR-STP-ALT **(new)** |
| 8 | `preconditionsAndPostconditions` | seeded (flat) | PD00-TAR-STP-PRE **(new)** |
| 9 | `endToEndTestScenarios` | seeded (flat) | PD00-TAR-STP-E2E **(new)** |
| 10 | `useCaseTraceability` | seeded (flat) | PD00-TAR-STP-TRC **(new)** |

**Count: 10.**

<a id="note-on-uc"></a>
**Note on UC:** The initial request listed 11 DocSpecs and omitted UC, but `PD00-TAR-STP` has UC as its only defined target in the mapping. If UC is dropped, PD00-TAR-STP needs re-routing (merge into BP, or defer). No other option leaves PD00-TAR-STP mapped.

### 5.5. BDM — Business Data Model

**Seed nodes:** PD00-BUS (3 existing + 8 new children). Single-source; flatten.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `dataModel` | seeded (flat) | PD00-BUS-DAT |
| 2 | `businessObjectModel` | seeded (flat) | PD00-BUS-BUS |
| 3 | `functionModel` | seeded (flat) | PD00-BUS-FUN |
| 4 | `dataDictionary` | seeded (flat) | PD00-BUS-DIC **(new)** |
| 5 | `businessRules` | seeded (flat) | PD00-BUS-RUL **(new)** |
| 6 | `validationConstraints` | seeded (flat) | PD00-BUS-VAL **(new)** |
| 7 | `lifecycleStates` | seeded (flat) | PD00-BUS-LIF **(new)** |
| 8 | `dataClassification` | seeded (flat) | PD00-BUS-CLA **(new)** |
| 9 | `relationshipModel` | seeded (flat) | PD00-BUS-REL **(new)** |
| 10 | `integrityConstraints` | seeded (flat) | PD00-BUS-CON **(new)** |
| 11 | `migrationMapping` | seeded (flat) | PD00-BUS-MIG **(new)** |

**Count: 11.**

### 5.6. AC — Authorization Concept

**Seed nodes:** PD00-ACC (6 existing + 4 new children). Single-source; flatten.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `userManagement` | seeded (flat) | PD00-ACC-USE |
| 2 | `authentication` | seeded (flat) | PD00-ACC-IDE |
| 3 | `resourceProtection` | seeded (flat) | PD00-ACC-RES |
| 4 | `authorization` | seeded (flat) | PD00-ACC-USA |
| 5 | `encryption` | seeded (flat) | PD00-ACC-SEN |
| 6 | `auditAndLogging` | seeded (flat) | PD00-ACC-AUD |
| 7 | `roleMatrix` | seeded (flat) | PD00-ACC-ROL **(new)** |
| 8 | `permissionCatalog` | seeded (flat) | PD00-ACC-PER **(new)** |
| 9 | `authorizationFlows` | seeded (flat) | PD00-ACC-FLO **(new)** |
| 10 | `complianceFramework` | seeded (flat) | PD00-ACC-CMP **(new — NIST/SOC2/ISO27001/OWASP)** |

**Count: 10.**

### 5.7. TR — Technical Requirements

**Seed nodes (multi-source):** PD00-TEC (8 existing + 3 new children) + PD00-COM (whole) + PD00-SYO-RES-TEC + PD00-USE-MUL-REQ. Decision: flatten PD00-TEC (the largest bundle) but keep PD00-COM as a single entry (its 6 children are tightly coupled and read as one concern).

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
| 9 | `systemArchitecture` | seeded (flat) | PD00-TEC-ARC **(new)** |
| 10 | `infrastructureRequirements` | seeded (flat) | PD00-TEC-INF **(new)** |
| 11 | `integrationProtocols` | seeded (flat) | PD00-TEC-INT **(new)** |
| 12 | `componentsToUse` | seeded (whole) | PD00-COM |
| 13 | `technicalFrameworkConditions` | seeded (whole) | PD00-SYO-RES-TEC |
| 14 | `translationRequirements` | seeded (whole) | PD00-USE-MUL-REQ |

**Count: 14.**

### 5.8. UP — UI Prototype

**Seed nodes (multi-source):** 10 existing sectioned children of PD00-USE + PD00-USE-MUL-LCS + 2 new PD00-USE children.

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
| 12 | `wireframesAndMockups` | seeded (whole) | PD00-USE-WIR **(new)** |
| 13 | `informationArchitecture` | seeded (whole) | PD00-USE-INF **(new)** |

**Count: 13.**

### 5.9. SR — System Rollout

**Seed nodes (multi-source):** PD00-USE-MUL-{LOC, TRA, DOC} + PD00-ROL (a **new top-level section** in ProjectDefinition — see §7). Decision: keep the three MUL process sections as single top-levels (internal structure is coherent) and flatten the new PD00-ROL so each rollout concern is its own top-level.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `localizationProcess` | seeded (whole) | PD00-USE-MUL-LOC |
| 2 | `translationProcess` | seeded (whole) | PD00-USE-MUL-TRA |
| 3 | `documentationAndTraining` | seeded (whole) | PD00-USE-MUL-DOC |
| 4 | `rolloutPlan` | seeded (flat) | PD00-ROL-PLN **(new)** |
| 5 | `migrationPlan` | seeded (flat) | PD00-ROL-MIG **(new)** |
| 6 | `userManuals` | seeded (flat) | PD00-ROL-DOC **(new)** |
| 7 | `trainingMaterials` | seeded (flat) | PD00-ROL-TRN **(new)** |
| 8 | `pilotPlan` | seeded (flat) | PD00-ROL-PIL **(new)** |
| 9 | `cutoverProcedures` | seeded (flat) | PD00-ROL-CUT **(new)** |
| 10 | `knowledgeTransfer` | seeded (flat) | PD00-ROL-KNO **(new)** |
| 11 | `warrantyAndSupport` | seeded (flat) | PD00-ROL-WAR **(new)** |

**Count: 11.**

### 5.10. BQP — Business Quality Plan

**Seed nodes (multi-source):** PD00-SYQ (7 existing + 1 new child) + PD00-DEL-ACC (6 existing children). Flatten both.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `qualityFramework` | seeded (flat) | PD00-SYQ-FRA |
| 2 | `userQualityCriteria` | seeded (flat) | PD00-SYQ-USE |
| 3 | `technicalQualityCriteria` | seeded (flat) | PD00-SYQ-TEC |
| 4 | `operationsQualityCriteria` | seeded (flat) | PD00-SYQ-OPE |
| 5 | `documentationQualityCriteria` | seeded (flat) | PD00-SYQ-DOC |
| 6 | `qualityPrioritization` | seeded (flat) | PD00-SYQ-PRI |
| 7 | `acceptanceCriteriaSummary` | seeded (flat) | PD00-SYQ-ACC |
| 8 | `testStrategy` | seeded (flat) | PD00-SYQ-TST **(new)** |
| 9 | `acceptanceCriteria` | seeded (flat) | PD00-DEL-ACC-CRI |
| 10 | `acceptanceProcess` | seeded (flat) | PD00-DEL-ACC-PRO |
| 11 | `userAcceptanceTesting` | seeded (flat) | PD00-DEL-ACC-UAT |
| 12 | `defectResolution` | seeded (flat) | PD00-DEL-ACC-DEF |
| 13 | `signOffProcess` | seeded (flat) | PD00-DEL-ACC-SIG |
| 14 | `warranty` | seeded (flat) | PD00-DEL-ACC-WAR |

**Count: 14.**

### 5.11. PPP — Project Phase Plan

**Seed nodes:** PD00-SSP (6 existing + 5 new children). Single-source; flatten.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `stagingStrategy` | seeded (flat) | PD00-SSP-STR |
| 2 | `stageOverview` | seeded (flat) | PD00-SSP-STA |
| 3 | `stages` | seeded (flat) | PD00-SSP-STG (list) |
| 4 | `featurePrioritization` | seeded (flat) | PD00-SSP-FEA |
| 5 | `dataMigrationStrategy` | seeded (flat) | PD00-SSP-MIG |
| 6 | `stageGovernance` | seeded (flat) | PD00-SSP-GOV |
| 7 | `phaseDefinitions` | seeded (flat) | PD00-SSP-PHD **(new)** |
| 8 | `gateCriteria` | seeded (flat) | PD00-SSP-GAT **(new)** |
| 9 | `resourcePlanning` | seeded (flat) | PD00-SSP-RES **(new)** |
| 10 | `initialDevelopmentFlow` | seeded (flat) | PD00-SSP-IDV **(new)** |
| 11 | `upgradeCycleFramework` | seeded (flat) | PD00-SSP-UPG **(new — links to tom_system_upgrade.md)** |

**Count: 11.**

### 5.12. BSI — Business System Interactions

**Seed nodes:** PD00-SYO-SYB (3 existing + 7 new children). Single-source; flatten.

| # | Top-level entry | Origin | Source |
| --- | --- | --- | --- |
| 1 | `externalInterfaces` | seeded (flat) | PD00-SYO-SYB-INT |
| 2 | `outOfScope` | seeded (flat) | PD00-SYO-SYB-OUT |
| 3 | `boundaryAssumptions` | seeded (flat) | PD00-SYO-SYB-ASS |
| 4 | `systemInventory` | seeded (flat) | PD00-SYO-SYB-INV **(new)** |
| 5 | `interactionPatterns` | seeded (flat) | PD00-SYO-SYB-PAT **(new — sync/async/batch)** |
| 6 | `testingStrategy` | seeded (flat) | PD00-SYO-SYB-TST **(new)** |
| 7 | `dependencyAnalysis` | seeded (flat) | PD00-SYO-SYB-DEP **(new)** |
| 8 | `migrationInteractions` | seeded (flat) | PD00-SYO-SYB-MIG **(new — back-ref to PD00-SYO-SYR)** |
| 9 | `operationalConsiderations` | seeded (flat) | PD00-SYO-SYB-OPE **(new)** |
| 10 | `errorHandlingAcrossBoundaries` | seeded (flat) | PD00-SYO-SYB-ERR **(new)** |

**Count: 10.**

---

## 6. Summary Matrix

PD-side seeds and resulting target-document top-level counts (all within 7–15):

After the PD00 Completion Plan (§7) is applied, every top-level entry in every target document is sourced from PD00. The count columns below reflect the post-completion state: "Existing" counts PD00 children already in the model; "New" counts PD00 children that §7 adds.

| Doc | Seed nodes | Existing | New | Total tops |
| --- | --- | --- | --- | --- |
| CS  | PD00-CUR, PD00-SYO-SYR | 6 | 3 | 9 |
| RC  | PD00-SYO-REQ | 5 | 5 | 10 |
| BP  | PD00-TAR-PRO | 5 | 5 | 10 |
| UC  | PD00-TAR-STP | 3 | 7 | 10 |
| BDM | PD00-BUS | 3 | 8 | 11 |
| AC  | PD00-ACC | 6 | 4 | 10 |
| TR  | PD00-TEC, PD00-COM, PD00-SYO-RES-TEC, PD00-USE-MUL-REQ | 11 | 3 | 14 |
| UP  | 10× PD00-USE-* + PD00-USE-MUL-LCS | 11 | 2 | 13 |
| SR  | PD00-USE-MUL-{LOC,TRA,DOC}, PD00-ROL | 3 | 8 | 11 |
| BQP | PD00-SYQ, PD00-DEL-ACC | 13 | 1 | 14 |
| PPP | PD00-SSP | 6 | 5 | 11 |
| BSI | PD00-SYO-SYB | 3 | 7 | 10 |

Every PD00 subtree that has a Phase 3 target is covered exactly once, with no overlap between target documents. Total new PD00 sections required: **58** (including 7 "promote existing untagged field" conversions) plus **1 new top-level section** `PD00-ROL`. Details in §7.

---

## 7. PD00 Completion Plan — First Implementation Step

Before any Phase 3 document class is created, the PD00 object model has to carry every section that a Phase 3 document lifts to a top-level entry. If a target-document section has no PD00 home, it is because PD00 is incomplete; the fix is always to add the section to the correct PD00 parent first, not to leave a doc-scoped ID in the target.

This section is the ordered task list for that completion work. **Every `(new)` flag in §5 points back to one row here.**

### 7.1. New Top-Level PD00 Section

One new top-level section is added directly on `ProjectDefinition`:

| New PD00 ID | Class name | Purpose | Mapping |
| --- | --- | --- | --- |
| PD00-ROL | `SystemRollout` | Rollout-related planning that flows to SR (rollout plan, migration, pilot, cutover, knowledge transfer, warranty). Kept separate from `PD00-USE-MUL` — MUL stays focused on multi-language/localization. | `@MapsTo(SystemRollout)` |

### 7.2. New Children of Existing PD00 Sections

58 new subsections, grouped by parent. "Promote" means the content already exists as an untagged field on the parent class and just needs a `@SectionId`, class extraction if currently inline, and the `@DetailedIn` annotation.

#### PD00-CUR (Current State Analysis) — now flows to CS

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-CUR-INT | `CurrentIntegrationPoints` | CS | Integration touchpoints in the current system landscape |
| PD00-CUR-MET | `OperationalMetrics` | CS | Throughput, volume, uptime baselines of the as-is systems |
| PD00-CUR-RIS | `CurrentStateRiskAssessment` | CS | Risks tied to the current state and replacement |

PD00-CUR itself gains `@MapsTo(CurrentSituation)`; each of its four existing children and three new children get `@DetailedIn(CurrentSituation)`. Remove "PD00-CUR" from the PD-only list.

#### PD00-SYO-REQ (Requirements Overview) — flows to RC

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-SYO-REQ-PRO | `RequirementsProcess` | RC | Elicitation, refinement, stewardship workflow |
| PD00-SYO-REQ-PRI | `PrioritizationScheme` | RC | MoSCoW / weighted-scoring / etc. |
| PD00-SYO-REQ-CHA | `ChangeControlLog` | RC | Requirement-change audit trail |
| PD00-SYO-REQ-REL | `RequirementRelationships` | RC | Dependency / conflict graph |
| PD00-SYO-REQ-COV | `RequirementCoverage` | RC | Coverage against goals, use cases, tests |

#### PD00-SYO-SYB (System Boundaries) — flows to BSI

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-SYO-SYB-INV | `SystemLandscapeInventory` | BSI | Complete external-system inventory |
| PD00-SYO-SYB-PAT | `InteractionPatterns` | BSI | Sync / async / batch pattern catalog |
| PD00-SYO-SYB-TST | `InteractionTestingStrategy` | BSI | Contract / integration / failure testing |
| PD00-SYO-SYB-DEP | `InteractionDependencyAnalysis` | BSI | Critical path, degraded-mode behavior |
| PD00-SYO-SYB-MIG | `MigrationInteractions` | BSI | Interactions specific to migration; back-refs PD00-SYO-SYR |
| PD00-SYO-SYB-OPE | `InteractionOperationalConsiderations` | BSI | SLAs, rate limits, change windows |
| PD00-SYO-SYB-ERR | `CrossBoundaryErrorHandling` | BSI | Failure propagation across boundaries |

#### PD00-TAR-PRO (Business Process Descriptions) — flows to BP

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-TAR-PRO-REL | `ProcessRelationships` | BP | **Promote** — existing `processRelationships` untagged field |
| PD00-TAR-PRO-DET | `DetailedProcessWorkflows` | BP | Per-process workflow detail beyond the catalog overview |
| PD00-TAR-PRO-CRO | `CrossProcessAnalysis` | BP | Hand-offs and shared data between processes |
| PD00-TAR-PRO-EXC | `ProcessExceptionHandling` | BP | Exception flows, escalation |
| PD00-TAR-PRO-MET | `ProcessMetricsAndKpis` | BP | Process KPIs, SLAs, measurement |

#### PD00-TAR-STP (Process Steps and Actor Interactions) — flows to UC

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-TAR-STP-OVE | `ProcessStepsOverview` | UC | **Promote** — existing `overview` field |
| PD00-TAR-STP-DIA | `ActorRelationshipDiagram` | UC | **Promote** — existing `actorRelationshipDiagram` field |
| PD00-TAR-STP-CAT | `UseCaseCatalog` | UC | Fully-dressed Cockburn-style use cases |
| PD00-TAR-STP-ALT | `AlternateFlows` | UC | Alternate and exception flows per use case |
| PD00-TAR-STP-PRE | `PreconditionsAndPostconditions` | UC | Formal pre/post conditions |
| PD00-TAR-STP-E2E | `EndToEndTestScenarios` | UC | HBSG AS24 content — E2E scenarios derived from use cases |
| PD00-TAR-STP-TRC | `UseCaseTraceability` | UC | UC ↔ RC ↔ BP ↔ tests traceability |

#### PD00-BUS (Business Object and Data Model) — flows to BDM

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-BUS-DIC | `DataDictionary` | BDM | Attribute-level dictionary beyond the entity overview |
| PD00-BUS-RUL | `BusinessRules` | BDM | SBVR-style business-rule statements |
| PD00-BUS-VAL | `ValidationConstraints` | BDM | Field-level validation constraints |
| PD00-BUS-LIF | `EntityLifecycleStates` | BDM | State machines for entities with non-trivial lifecycles |
| PD00-BUS-CLA | `DataClassification` | BDM | Security classification, PII/PHI handling |
| PD00-BUS-REL | `RelationshipModel` | BDM | Entity relationships with cardinality / integrity |
| PD00-BUS-CON | `IntegrityConstraints` | BDM | Cross-entity integrity constraints |
| PD00-BUS-MIG | `DataMigrationMapping` | BDM | Legacy-to-target data mapping |

#### PD00-TEC (Technical Framework Concept) — flows to TR

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-TEC-ARC | `SystemArchitecture` | TR | Detailed internal architecture (layers, packages, patterns) |
| PD00-TEC-INF | `InfrastructureRequirements` | TR | Concrete infrastructure specs beyond HAR-level constraints |
| PD00-TEC-INT | `IntegrationProtocols` | TR | Protocols, framing, payload formats for integrations |

#### PD00-ACC (Access and Authorization Concept) — flows to AC

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-ACC-ROL | `RoleMatrix` | AC | Role-to-permission assignment matrix |
| PD00-ACC-PER | `PermissionCatalog` | AC | Enumerable permission catalog |
| PD00-ACC-FLO | `AuthorizationFlows` | AC | OAuth / SSO / step-up flows |
| PD00-ACC-CMP | `ComplianceFramework` | AC | NIST / SOC 2 / ISO 27001 / OWASP alignment |

#### PD00-USE (User Interface Design and Prototype) — flows to UP

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-USE-WIR | `WireframesAndMockups` | UP | Wireframe inventory beyond screen descriptions |
| PD00-USE-INF | `InformationArchitecture` | UP | IA taxonomy / content model |

#### PD00-ROL (new top-level) — flows to SR

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-ROL-PLN | `RolloutPlan` | SR | Geographic / user-group rollout plan (DR23) |
| PD00-ROL-MIG | `MigrationPlan` | SR | System migration plan (DR22) |
| PD00-ROL-DOC | `UserManuals` | SR | End-user manuals (DR15) |
| PD00-ROL-TRN | `TrainingMaterials` | SR | Training materials (DR17) |
| PD00-ROL-PIL | `PilotPlan` | SR | Pilot scope and success criteria |
| PD00-ROL-CUT | `CutoverProcedures` | SR | Cutover runbook |
| PD00-ROL-KNO | `KnowledgeTransfer` | SR | Handover to operations (EK09) |
| PD00-ROL-WAR | `WarrantyAndSupport` | SR | Warranty terms (EK10) |

#### PD00-SYQ (System Quality Goals) — flows to BQP

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-SYQ-TST | `TestStrategy` | BQP | Overall test strategy (HBSG AS23) |

#### PD00-SSP (System Stage Plan) — flows to PPP

| New PD00 ID | Class name | Feeds | Notes |
| --- | --- | --- | --- |
| PD00-SSP-PHD | `PhaseDefinitions` | PPP | Per-phase deliverable and scope definitions |
| PD00-SSP-GAT | `GateCriteria` | PPP | Phase-gate entry/exit criteria |
| PD00-SSP-RES | `ResourcePlanning` | PPP | Resource and capacity planning per phase |
| PD00-SSP-IDV | `InitialDevelopmentFlow` | PPP | Inter-phase dependencies during initial build |
| PD00-SSP-UPG | `UpgradeCycleFramework` | PPP | Upgrade-cycle entry; links `tom_system_upgrade.md` |

### 7.3. Execution Order

Recommended order for the PD00 completion work so the outliner stays green after each step:

1. **Shape-only promotions first** — give `@SectionId` and a class extraction to the existing untagged fields: `PD00-TAR-PRO-REL`, `PD00-TAR-STP-OVE`, `PD00-TAR-STP-DIA`. No new content, just structural upgrades. Outliner should emit the same structure after promotion as before.
2. **Reclassify `PD00-CUR`** — drop `@Unused()` on `content`, add the three new children (`INT`, `MET`, `RIS`), and update the PD-only list. This is the only change that moves a whole existing subtree from PD-only to a DocSpec target, so do it in isolation.
3. **Add `PD00-ROL`** — new top-level section with its 8 children. Add as a field on `ProjectDefinition`. Update `pd_project_definition.dart` exports and the root aggregation.
4. **Extend existing sections with new children** in any order — RC, BP, UC, BDM, AC, TR, UP, BQP, PPP, BSI additions are independent of each other.
5. **Annotate with `@MapsTo` / `@DetailedIn`** (§8) — can run concurrently with step 4 per subtree.
6. **Run the outliner** with `--root-type ProjectDefinition` after every grouped addition. Structure should remain valid the whole time.

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

A class has both `@MapsTo` and `@DetailedIn` when the seed node is kept whole in the target document, i.e., the seed is both the 1:1 mapping point and the top-level entry.

Examples (from §5):

- `BusinessObjectAndDataModel` (PD00-BUS): `@MapsTo(BusinessDataModel)` — but **not** `@DetailedIn`, because the seed is flattened into 3 top-levels in §5.5.
- `DataModel`, `BusinessObjectModel`, `FunctionModel`: each carries `@DetailedIn(BusinessDataModel)`; none carries `@MapsTo` (their parent does).
- `ComponentsToUse` (PD00-COM): carries **both** `@MapsTo(TechnicalRequirements)` **and** `@DetailedIn(TechnicalRequirements)` — PD00-COM is kept whole as TR's `componentsToUse` top-level (§5.7 row 12).
- `TechnicalFrameworkConditions` (PD00-SYO-RES-TEC): both (§5.7 row 13).
- `TranslationRequirements` (PD00-USE-MUL-REQ): both (§5.7 row 14).
- Every `PD00-USE-*` class flowing to UP (§5.8): all 13 carry both (11 existing + 2 added in §7).
- `LocalizationProcess`, `TranslationProcess`, `DocumentationAndTraining` (§5.9): all three carry both.
- `CurrentStateAnalysis` (PD00-CUR): `@MapsTo(CurrentSituation)` only — flattened into 7 CS top-levels (§5.1).
- Each PD00-CUR-* child: `@DetailedIn(CurrentSituation)` only.
- `SystemStagePlan` (PD00-SSP): `@MapsTo(ProjectPhasePlan)` only — flattened into 11 PPP top-levels.
- `SystemRollout` (PD00-ROL, new in §7): `@MapsTo(SystemRollout)` only — flattened into 8 SR top-levels.

### 8.4. Worked example: the BDM branch

```dart
import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/src/bdm_business_data_model/business_data_model.dart';

@SectionId('PD00-BUS')
@MapsTo(BusinessDataModel)
class BusinessObjectAndDataModel {
  // …seed of BDM. Not itself a top-level of BDM — flattened one level.
  DataModel dataModel = DataModel();
  BusinessObjectModel businessObjectModel = BusinessObjectModel();
  FunctionModel functionModel = FunctionModel();
}

@SectionId('PD00-BUS-DAT')
@DetailedIn(BusinessDataModel)
class DataModel { /* top-level in BDM */ }

@SectionId('PD00-BUS-BUS')
@DetailedIn(BusinessDataModel)
class BusinessObjectModel { /* top-level in BDM */ }

@SectionId('PD00-BUS-FUN')
@DetailedIn(BusinessDataModel)
class FunctionModel { /* top-level in BDM */ }
```

And for a whole-seed case:

```dart
@SectionId('PD00-COM')
@MapsTo(TechnicalRequirements)
@DetailedIn(TechnicalRequirements)
class ComponentsToUse { /* whole subtree is TR's componentsToUse top-level */ }
```

### 8.5. Mechanical invariants (validator can enforce)

- Every class that appears in any §5 "Source" column of type `PD00-…` has exactly one `@DetailedIn`.
- Every seed node listed in §6 has exactly one `@MapsTo`.
- For each target DocSpec `D`, the count of `@DetailedIn(D)` in the PD00 tree equals `D`'s "Seeded tops" column in §6.
- No class carries `@DetailedIn` without either (a) also carrying `@MapsTo`, or (b) having a parent that carries `@MapsTo` for the same target.

These invariants are additions the outliner / validator can check once the annotations are applied.

---

## 9. Implementation Notes

- **PD00 completion is step 1.** No Phase 3 document class is created before §7 is finished — a class referencing a non-existent PD00 class would not compile and would defeat the completeness rule that motivated §7.
- **Reuse, don't duplicate.** The seeded fields type against the existing PD00 classes (`BusinessObjectAndDataModel`, `SystemStagePlan`, etc.). The target document class imports `package:tom_specs_model/.../pd_project_definition/...` and uses the same types. No expansion-only sections exist anymore — every target top-level types against a PD00 class.
- **One folder per document.** Add `lib/src/cs_current_situation/`, `lib/src/rc_requirements_catalog/`, … mirroring `pd_project_definition/`. Top-level file exports the root class (e.g., `CurrentSituation`, `RequirementsCatalog`).
- **Annotate every new root.** `@Document(…, basedOn: [ProjectDefinition])` and `@SectionId('<CODE>00')` on the class, and re-export from `lib/tom_specs_model.dart`.
- **Outliner root type.** Once a document class exists, the outliner can run with `--root-type <DocName>` against `tom_specs_model` to validate that the new class tree traverses cleanly. Also run with `--root-type ProjectDefinition` after each §7 step.
- **UC decision pending.** Resolve the UC question (§5.4) before starting — either implement UC in this wave or explicitly reroute PD00-TAR-STP.
- **Mapping doc out of date.** Section 1 lists the known IDs that have drifted between `hbsg_tom_resulttype_mapping.md` and the current model. Update the mapping doc after §7 lands so it stops contradicting the code.
