# Nested Lists Remodeling — Repeated Sections with Repeated Subsections

**Date:** 2026-04-21 (rev 2)
**Package:** `tom_specs_model`  
**Status:** Analysis / Design Decision Required

---

## 1. Background

The TomSpecs object model uses two annotations to assign section IDs:

| Annotation | Target | Meaning |
|---|---|---|
| `@SectionId('PD00-XYZ')` | Class | Fixed, globally unique section ID. |
| `@SectionIdPattern('PD00-XYZ-xx')` | List field | Per-element numbered section ID; items become `PD00-XYZ-01`, `-02`, … |

This works well for a single level of repeated sections. Problems arise when an element
type in a `@SectionIdPattern` list itself contains `List<T>` fields — **nested repeated
sections**. The current schema, validator, and outliner do not support this case.

---

## 2. How the Current Model Handles Nested Lists

### 2.1 Validator behaviour — silent exemption via BFS crossing

The validator runs a BFS (graph traversal) starting from every direct `@SectionIdPattern`
element type, building a `patternCovered` set — types that do not need their own
`@SectionId`. Critically, the BFS currently **crosses `List<T>` field boundaries**, so
any type reachable inside a pattern-covered type (even through a nested list) is also
considered exempt. This is why the 16 tests pass today: the nested element types receive
a silent free pass even though they carry no annotation.

### 2.2 The correct annotation scheme for nested lists

For a proper two-level repeated section the annotations would look like:

```dart
// Outer container
@SectionId('PD00-FGH')
class FghSection {
  @SectionIdPattern('PD00-FGH-XXX-xx')          // outer list
  List<XxxEntry> items = [];
}

// Outer element — its @SectionId equals the prefix of the outer pattern
@SectionId('PD00-FGH-XXX')                        // = prefix of 'PD00-FGH-XXX-xx'
class XxxEntry {
  @SectionIdPattern('PD00-FGH-XXX-xx-ABC-yy')    // inner list; first placeholder
                                                   // must be the outer runtime index
  List<AbcItem> abcItems = [];
}

// Inner element — its @SectionId is PARAMETRIC (contains the outer placeholder)
@SectionId('PD00-FGH-XXX-xx-ABC')                 // template, not a fixed string!
class AbcItem { … }
```

The inner `@SectionId` contains a placeholder (`xx`). This breaks the current schema in
two ways:
1. **`@SectionId` is assumed to be a fixed, globally unique string.** A parametric ID
   cannot be checked for uniqueness at model-authoring time.
2. **The outliner** would need to substitute the outer list index at render time to produce
   actual section numbers like `PD00-FGH-XXX-01-ABC`, `PD00-FGH-XXX-02-ABC`, etc.

Supporting nested repeated sections therefore requires a non-trivial schema extension.

---

## 3. Three Options for Each Case

For every affected class three remedies exist:

**Option A — Schema extension (keep nested lists)**  
Support parametric `@SectionId` values containing placeholders. Requires validator,
outliner, and DocSpecs schema changes. Only justified if the nested items genuinely need
individually addressable section IDs.

**Option B — Flatten to parent (lift the sub-list)**  
Move the nested `List<T>` field to the grandparent container section. Each sub-entry gets
a back-reference ID field (`parentId`) linking it to its parent. Converts 2-level nesting
into two independent 1-level lists at the parent scope.

```dart
// Before: Outer.innerList — nested
// After: parent container owns both lists; InnerEntry.parentId links them
@SectionIdPattern('PD00-FGH-XXX-xx')
List<XxxEntry> items = [];

@SectionIdPattern('PD00-FGH-ABC-xx')       // lifted; was inside XxxEntry
List<AbcItem> abcItems = [];               // AbcItem.xId references XxxEntry
```

The DocSpecs **for-each condition** can enforce "every XxxEntry must have ≥ 1 AbcItem".

**Option C — Replace with a TextSection (free text)**  
Instead of `@SectionIdPattern List<XxxEntry>`, the field becomes a single `TextSection`
(or a `@ContentType('text')` class). The writer fills in the sub-items as free prose or
a numbered list. No section IDs are assigned to individual sub-items.

```dart
// Before:
@SectionIdPattern('PD00-FGH-XXX-xx-STP-xx')
List<StepEntry> steps = [];

// After:
StepsText steps = StepsText();

@ContentType('text')
class StepsText {
  @ContentHelp('List the steps in sequence: 1. … 2. … 3. …')
  String? content;
}
```

Option C trades fine-grained referenceability for simplicity. It is appropriate when:
- Sub-items are enumerated but never individually cross-referenced elsewhere in the spec.
- The typical count is small (2–10 items) and items are homogeneous.
- The depth is already large (writer friction outweighs structure benefit).

---

## 4. Section Depth Reference

**How to read the depth columns:**

- **Total depth** = number of hyphen-separated tokens in the innermost concrete section ID
  (e.g. `PD00-TAR-STP-SCE-01-AFL-02-AST-03` has 9 tokens → depth 9).
- **List levels** = count of `-xx`/`-yy` placeholders in the innermost pattern = number of
  nested repeated-section levels.

A depth ≥ 9 strongly suggests the model has been over-dissected at that point; free text
(Option C) is almost always the better choice there.

---

## 5. Case-by-Case Analysis

---

### Case 1 — `AlternativeFlowEntry` → `List<AlternativeStepEntry>`
**File:** `target_business_process.dart`  
**Innermost pattern:** `PD00-TAR-STP-SCE-xx-AFL-xx-AST-xx`  
**Total depth:** 9 · **List levels:** 3

Each process scenario has alternative flows; each flow has ordered steps.

The steps are sequential (step 1, 2, 3 …) and each step has a few short fields (actor,
action, system response). At depth 9 with 3 list nesting levels this is over-dissected.

**Recommendation: Option C.**  
Replace `List<AlternativeStepEntry>` with a `TextSection alternativeSteps` whose
`@ContentHelp` prompts the writer to list steps as a numbered prose sequence.

---

### Case 2 — `ExtensionEntry` → `List<ExtensionStepEntry>`
**File:** `target_business_process.dart`  
**Innermost pattern:** `PD00-TAR-STP-INT-xx-EXT-xx-EST-xx`  
**Total depth:** 9 · **List levels:** 3

Same structure as Case 1 — extensions of an interaction scenario have ordered steps.

**Recommendation: Option C.** Same reasoning as Case 1.

---

### Case 3 — `AuthorizationGroupEntry` → `List<RoleReferenceEntry>`
**File:** `access_authorization.dart`  
**Innermost pattern:** `PD00-ACC-USA-GRP-xx-ROL-xx`  
**Total depth:** 7 · **List levels:** 2

A group contains role references. `RoleReferenceEntry` is just a role name (a reference,
not a content-rich object). Role names never need individual section IDs.

**Recommendation: Option C.**  
Replace with `TextSection containedRoles` with hint "List role names one per line or
comma-separated".

---

### Case 4 — `ComponentEntry` → `List<ComponentInterfaceEntry>`
**File:** `components.dart`  
**Innermost pattern:** `PD00-COM-COM-xx-INT-xx`  
**Total depth:** 6 · **List levels:** 2

Each technical component exposes interfaces (API contracts). Interfaces may need to be
individually referenced from architecture diagrams or TR documents.

**Recommendation: Option B** (flatten to `ComponentList` level with `componentId` ref).  
If interface detail is minimal, Option C is also acceptable.

---

### Case 5 — `ComponentFamilyEntry` → `List<FamilyComponentRef>`
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-COM-FAM-xx-CMP-xx`  
**Total depth:** 7 · **List levels:** 2

A component family groups component IDs. `FamilyComponentRef` is a pure reference (a
component ID pointer). No individual section ID is ever needed for a membership reference.

**Recommendation: Option C.**  
Replace with `TextSection familyMembers` listing component IDs.

---

### Case 6 — `CustomDistributionGroup` → `List<DistributionRecipientEntry>`
**File:** `administrative.dart`  
**Innermost pattern:** `PD00-ADM-DIS-CUS-xx-MEM-xx`  
**Total depth:** 7 · **List levels:** 2

Distribution group membership — names and email addresses. These are operational data,
not spec content that needs individual section IDs.

**Recommendation: Option C.**  
Replace with `TextSection members` (one name/email per line).

---

### Case 7 — `DataClassificationEntry` → `List<HandlingRequirementEntry>` + `List<AccessRestrictionEntry>`
**File:** `business_data_model.dart`  
**Innermost pattern:** `PD00-BUS-DAT-CLA-xx-HAN-xx` / `PD00-BUS-DAT-CLA-xx-ARE-xx`  
**Total depth:** 7 · **List levels:** 2

Two parallel sub-lists under a classification entry. Handling requirements and access
restrictions are compliance-governed items that may be referenced from security
architecture documents.

**Recommendation: Option B** (lift both to parent `DataClassification` section).  
Use a DocSpecs for-each condition to require ≥ 1 handling requirement per classification.

---

### Case 8 — `DataSourceEntry` → `List<DataSourceEntityEntry>` (no `@SectionIdPattern`)
**File:** `current_state_analysis.dart`  
**Innermost pattern:** *missing* (field carries no `@SectionIdPattern`)  
**Total depth:** ~7 if annotated · **List levels:** 1 → 2

The `keyEntities` field currently has no annotation at all. Entities (domain objects stored
in a data source) are typically just names with a brief description.

**Recommendation: Option C.**  
Replace with `TextSection keyEntities` listing entity names. No `@SectionIdPattern`
is needed.

---

### Case 9 — `ExportFormatEntry` → `List<ExportFieldMappingEntry>`
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-PRI-EXP-xx-FLD-xx`  
**Total depth:** 7 · **List levels:** 2

Field mappings (source column → output column, type, format) are tabular data. A report
tool or integration spec will reference specific export formats but rarely individual field
rows by section ID.

**Recommendation: Option C.**  
Replace with `TextSection fieldMappings` with hint "Table: source field | output column |
type | notes". This is tabular free text, not a document section hierarchy.

---

### Case 10 — `FeatureTourEntry` → `List<TourStepEntry>`
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-HLP-ONB-TOUR-xx-STEP-yy`  
**Total depth:** 9 · **List levels:** 2

A feature tour has ordered steps (tooltip text, target element, sequence). At depth 9 with
2 list levels, individual step section IDs serve no spec purpose — the steps are consumed
as a sequence, not individually referenced.

**Recommendation: Option C.**  
Replace with `TextSection tourSteps` listing step-by-step instructions.

---

### Case 11 — `FunctionEntry` → `List<SubFunctionEntry>`
**File:** `business_data_model.dart`  
**Innermost pattern:** `PD00-BUS-FUN-DEC-xx-SUB-xx`  
**Total depth:** 7 · **List levels:** 2

Business function decomposition. Sub-functions are often just names + brief descriptions.
The decomposition is hierarchical but typically only 1–2 levels deep in practice.

**Recommendation: Option C** (if depth ≤ 2).  
Replace with `TextSection subFunctions` listing sub-function names and one-line
descriptions. If actual deep recursion is needed, Option B (adjacency list with
`parentFunctionId`) is the fallback.

---

### Case 12 — `NavigationGroupEntry` → `List<NavigationItemEntry>`
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-SCF-NAV-HIE-xx-ITM-xx`  
**Total depth:** 8 · **List levels:** 2

Navigation items carry `targetScreenId` and permission references that may be checked
against the screen inventory. Individually addressable section IDs support cross-validation.

**Recommendation: Option B** (lift items to `NavigationHierarchy` level with `groupId`
back-reference). Items need structure for screen linkage.

---

### Case 13 — `PhaseGateReviewEntry` → `List<ReviewCriterionEntry>`
**File:** `system_stage_plan.dart`  
**Innermost pattern:** `PD00-SSP-GOV-GAT-xx-RCR-xx`  
**Total depth:** 7 · **List levels:** 2

Phase-gate review criteria are pass/fail conditions. They are typically 3–8 short
statements per gate and are consumed as a checklist, not individually referenced by ID.

**Recommendation: Option C.**  
Replace with `TextSection reviewCriteria` with hint "List each criterion on a new line
(pass/fail condition)".

---

### Case 14 — `ReportEntry` → 5 parallel `List<T>` fields
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-PRI-REP-xx-SEC-xx` (+ FLT, SCH, DST, REC variants)  
**Total depth:** 7 · **List levels:** 2

Reports have sections, filters, schedules, distributions, and recipients — five independent
sub-lists at the same level. Each list warrants its own section in the document because
report specifications are complex and each axis (layout, filtering, scheduling, recipients)
is independently reviewed.

**Recommendation: Option B** (lift all five lists to `ReportDefinitions` level).  
Five independent top-level lists with `reportId` back-references. DocSpecs for-each
conditions enforce ≥ 1 section per report.

---

### Case 15 — `ReportSectionEntry` → `List<ReportColumnEntry>` + `List<ReportChartEntry>`
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-PRI-REP-xx-SEC-xx-COL-xx` / `…-CHT-xx`  
**Total depth:** 9 · **List levels:** 3

`ReportSectionEntry` is itself nested inside `ReportEntry` (Case 14). At depth 9 with 3
list levels, individual column and chart section IDs are excessive.

**Recommendation: Option C** (after flattening Case 14 via Option B).  
Once `ReportSectionEntry` is a direct top-level list, replace its `columns` and `charts`
sub-lists with `TextSection columns` ("Column | Type | Source | Format") and `TextSection
charts` ("Chart type | Data series | X axis | Y axis").

---

### Case 16 — `ScreenSectionEntry` → `List<ScreenElementEntry>`
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-SCR-INV-xx-SEC-xx-ELE-xx`  
**Total depth:** 9 · **List levels:** 3

Screen elements (buttons, fields, labels) are the primary design artefacts in a UI spec.
Each element has `elementId` referenced from acceptance criteria, accessibility docs, and
test scenarios. Individual section IDs matter here.

**Recommendation: Option B** (flatten: screen → sections flat list → elements flat list).  
Each `ScreenElementEntry` carries `screenId` and `sectionId` back-references. This removes
one nesting level and makes each element independently addressable.

---

### Case 17 — `ScreenElementEntry` → `List<ElementValidationRuleEntry>`
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-SCR-INV-xx-SEC-xx-ELE-xx-VAL-xx`  
**Total depth:** 11 · **List levels:** 4

This is the **deepest element in the entire model** — depth 11 with 4 repeated section
levels. A validation rule for a screen element (e.g. "field must be a valid email") is
never individually referenced by section ID from anywhere else in the spec.

**Recommendation: Option C.** This case is definitively over-dissected.  
Replace `List<ElementValidationRuleEntry>` with `TextSection validationRules` on
`ScreenElementEntry` with hint "List validation rules: Required | Format: email |
Max length: 100".

---

### Case 18 — `SystemToReplaceEntry` → `List<ReplacementSystemDependencyEntry>`
**File:** `system_overview.dart`  
**Innermost pattern:** `PD00-SYO-SYR-INV-xx-DEP-xx`  
**Total depth:** 7 · **List levels:** 2

Each system to be replaced has a dependency list (other systems / integrations it relies
on). Dependencies are typically short name+type pairs that don't need individual section IDs.

**Recommendation: Option C.**  
Replace with `TextSection dependencies` listing dependent system names and integration types.

---

### Case 19 — `TabBarDefinitionEntry` → `List<TabItemEntry>`
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-SCF-NAV-SEC-xx-TAB-xx`  
**Total depth:** 8 · **List levels:** 2

A tab bar has 2–8 tabs, each with a label and target screen. Tabs are a configuration
enumeration, not individually referenced artefacts.

**Recommendation: Option C.**  
Replace with `TextSection tabs` listing tab labels and target screen IDs.

---

### Case 20 — `TestScenarioEntry` → `List<UatTestStepEntry>`
**File:** `delivery_acceptance.dart`  
**Innermost pattern:** `PD00-DEL-ACC-UAT-xx-STP-xx`  
**Total depth:** 7 · **List levels:** 2

UAT test steps are the executable content of a test scenario. Each step can be
individually traced to a requirement, assigned a pass/fail outcome, and referenced in
test reports. This is one of the cases where structure genuinely adds value.

**Recommendation: Option B** (lift steps to `UserAcceptanceTesting` level with
`scenarioId` back-reference). DocSpecs for-each condition enforces ≥ 1 step per scenario.

---

### Case 21 — `UiComponentEntry` → 5 parallel `List<T>` fields
**File:** `user_interface_design.dart`  
**Patterns:** `PD00-USE-COM-SPE-xx-STA-xx`, `…-VAR-xx`, `…-ACT-xx`, `…-SLT-xx`, `…-PRP-xx`  
**Total depth:** 7 · **List levels:** 2

Five parallel sub-lists: component states, variants, actions, slots, properties.  
`ComponentStateEntry` (disabled, loading, error, etc.) and `ComponentPropertyEntry`
(configurable props) are likely referenced from Flutter implementation specs.

**Recommendation: Option B** (lift all 5 to `UiComponentSpecs` level with `componentId`
back-reference). The five lists become independent top-level lists, consistent with the
approach recommended for `ReportEntry` (Case 14).

---

### Case 22 — `UtilityNavigationItemEntry` → `List<UtilityMenuItemEntry>`
**File:** `user_interface_design.dart`  
**Innermost pattern:** `PD00-USE-SCF-NAV-UTL-xx-MEN-xx`  
**Total depth:** 8 · **List levels:** 2

Utility navigation items (user menu, notifications) have dropdown sub-items. Menu item
lists are a configuration enumeration (label, icon, action).

**Recommendation: Option C.**  
Replace with `TextSection menuItems` listing label, icon, and action for each item.

---

### Case 23 — `WorkflowActorEntry` → `List<WorkflowStepEntry>` (`@Reference`)
**File:** `current_state_analysis.dart`  
**No section pattern — `@Reference` field only.**

This is a cross-reference (actor participates in steps defined elsewhere), not an
ownership relationship. The `@Reference` annotation already marks it as exempt.

**Recommendation: No change.** This is correctly modelled.

---

### Case 24 — `WorkflowStepEntry` → 5 `List<T>` sub-lists (no `@SectionIdPattern`)
**File:** `current_state_analysis.dart`  
**Outer pattern:** `PD00-CUR-PRO-xx-WOR-xx-STP-xx` (depth 8 for the step itself)  
**Sub-lists if annotated:** depth ~10 · **List levels:** 2+

Five sub-lists with **no annotations at all**: `systemsUsed`, `inputs`, `outputs`,
`businessRules`, `knownIssues`. They are silently exempt today only because the BFS
crosses the `List<WorkflowStepEntry>` boundary. This is the **highest-priority case** —
if the BFS crossing is ever removed (Issue 2), these 5 types would immediately produce
coverage warnings.

Sub-list semantics: workflow step metadata that is read as a whole, not individually
referenced by section ID.

**Recommendation: Option C** (all five sub-lists).  
Replace each `List<T>` with a `TextSection`:
- `systemsUsed` → `TextSection systemsUsed` ("Comma-separated system names")
- `inputs` → `TextSection inputs` ("List input artefacts / data")
- `outputs` → `TextSection outputs` ("List output artefacts / data")
- `businessRules` → `TextSection businessRules` ("List applicable rules")
- `knownIssues` → `TextSection knownIssues` ("List known problems / pain points")

---

## 6. Summary Table

| # | Outer / inner type | Outer @SectionIdPattern | Total depth | List levels | Recommendation |
|---|---|---|---|---|---|
| 1 | `AlternativeFlowEntry` / `AlternativeStepEntry` | `PD00-TAR-STP-SCE-xx-AFL-xx-AST-xx` | **9** | 3 | **C** — TextSection |
| 2 | `ExtensionEntry` / `ExtensionStepEntry` | `PD00-TAR-STP-INT-xx-EXT-xx-EST-xx` | **9** | 3 | **C** — TextSection |
| 3 | `AuthorizationGroupEntry` / `RoleReferenceEntry` | `PD00-ACC-USA-GRP-xx-ROL-xx` | 7 | 2 | **C** — TextSection |
| 4 | `ComponentEntry` / `ComponentInterfaceEntry` | `PD00-COM-COM-xx-INT-xx` | 6 | 2 | **B** — flatten |
| 5 | `ComponentFamilyEntry` / `FamilyComponentRef` | `PD00-USE-COM-FAM-xx-CMP-xx` | 7 | 2 | **C** — TextSection |
| 6 | `CustomDistributionGroup` / `DistributionRecipientEntry` | `PD00-ADM-DIS-CUS-xx-MEM-xx` | 7 | 2 | **C** — TextSection |
| 7a | `DataClassificationEntry` / `HandlingRequirementEntry` | `PD00-BUS-DAT-CLA-xx-HAN-xx` | 7 | 2 | **B** — flatten |
| 7b | `DataClassificationEntry` / `AccessRestrictionEntry` | `PD00-BUS-DAT-CLA-xx-ARE-xx` | 7 | 2 | **B** — flatten |
| 8 | `DataSourceEntry` / `DataSourceEntityEntry` | *(missing)* | ~7 | 1→2 | **C** — TextSection |
| 9 | `ExportFormatEntry` / `ExportFieldMappingEntry` | `PD00-USE-PRI-EXP-xx-FLD-xx` | 7 | 2 | **C** — TextSection |
| 10 | `FeatureTourEntry` / `TourStepEntry` | `PD00-USE-HLP-ONB-TOUR-xx-STEP-yy` | **9** | 2 | **C** — TextSection |
| 11 | `FunctionEntry` / `SubFunctionEntry` | `PD00-BUS-FUN-DEC-xx-SUB-xx` | 7 | 2 | **C** — TextSection (≤ 2 levels) |
| 12 | `NavigationGroupEntry` / `NavigationItemEntry` | `PD00-USE-SCF-NAV-HIE-xx-ITM-xx` | 8 | 2 | **B** — flatten (items reference screens) |
| 13 | `PhaseGateReviewEntry` / `ReviewCriterionEntry` | `PD00-SSP-GOV-GAT-xx-RCR-xx` | 7 | 2 | **C** — TextSection |
| 14 | `ReportEntry` / 5 sub-lists | `PD00-USE-PRI-REP-xx-SEC-xx` | 7 | 2 | **B** — flatten (5 parallel lists) |
| 15 | `ReportSectionEntry` / `ReportColumnEntry`+`ReportChartEntry` | `PD00-USE-PRI-REP-xx-SEC-xx-COL-xx` | **9** | 3 | **C** after B (Case 14) |
| 16 | `ScreenSectionEntry` / `ScreenElementEntry` | `PD00-USE-SCR-INV-xx-SEC-xx-ELE-xx` | **9** | 3 | **B** — flatten (elements need IDs) |
| 17 | `ScreenElementEntry` / `ElementValidationRuleEntry` | `PD00-USE-SCR-INV-xx-SEC-xx-ELE-xx-VAL-xx` | **11** | 4 | **C** — TextSection ← *deepest* |
| 18 | `SystemToReplaceEntry` / `ReplacementSystemDependencyEntry` | `PD00-SYO-SYR-INV-xx-DEP-xx` | 7 | 2 | **C** — TextSection |
| 19 | `TabBarDefinitionEntry` / `TabItemEntry` | `PD00-USE-SCF-NAV-SEC-xx-TAB-xx` | 8 | 2 | **C** — TextSection |
| 20 | `TestScenarioEntry` / `UatTestStepEntry` | `PD00-DEL-ACC-UAT-xx-STP-xx` | 7 | 2 | **B** — flatten (test traceability) |
| 21 | `UiComponentEntry` / 5 sub-lists | `PD00-USE-COM-SPE-xx-STA-xx` … | 7 | 2 | **B** — flatten (5 parallel lists) |
| 22 | `UtilityNavigationItemEntry` / `UtilityMenuItemEntry` | `PD00-USE-SCF-NAV-UTL-xx-MEN-xx` | 8 | 2 | **C** — TextSection |
| 23 | `WorkflowActorEntry` / `WorkflowStepEntry` | *@Reference — not ownership* | — | — | **No change** |
| 24 | `WorkflowStepEntry` / 5 sub-lists (unannotated) | *missing — silent exemption today* | ~10 | 2+ | **C** — TextSection (all 5) |

**Score:**
- Option C (TextSection): **16 cases** — the model has been over-dissected in most of these
- Option B (flatten): **6 cases** — structure genuinely needed; cross-references or parallel lists
- No change: **1 case** — `@Reference`, already correct
- One case (15) is C contingent on B being done for Case 14

---

## 7. Over-Dissection Diagnosis

Several patterns indicate that a nested list is over-dissected:

| Signal | Cases |
|---|---|
| Total depth ≥ 9 | 1, 2, 10, 15, 16, 17 |
| Items are sequential steps (numbered prose is clearer) | 1, 2, 10, 20 |
| Items are reference/membership (names / IDs only) | 3, 5, 6, 19, 22 |
| Items are operational metadata, not spec content | 6, 8, 24 |
| Items never individually cross-referenced | 1, 2, 3, 5, 6, 9, 10, 11, 13, 17, 18, 19, 22, 24 |
| Sub-list has zero annotations today (silent exemption) | 8, 24 |

The worst offender is `ElementValidationRuleEntry` at depth 11 with 4 list nesting levels.
For context, a typical well-structured specification document has 3–4 section levels total.
Reaching depth 11 means the document reader would navigate 11 nested section headers to
reach a single validation rule — far past any useful granularity.

---

## 8. Implementation Order

If the remodelling is undertaken:

1. **Option C cases first** — each is a local change (replace one list field with one
   `TextSection` class). No inter-class dependencies. Can be done in any order.
2. **Case 24** (`WorkflowStepEntry` 5 sub-lists) — highest priority because these have
   zero annotations. Tackle before any Issue 2 validator fix.
3. **Case 16 + 17** (`ScreenSectionEntry` → `ScreenElementEntry` → validation rules) —
   do these together: B for Case 16, then C for Case 17.
4. **Case 14 + 15** (`ReportEntry` → `ReportSectionEntry`) — B for Case 14, then C for 15.
5. **Option B flatten cases** (4, 7a/7b, 12, 20, 21) — each requires adding a parent-level
   `@SectionIdPattern` list and a `parentId` back-reference field.
