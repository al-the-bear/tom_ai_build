# Nested Lists Remodeling — Repeated Sections with Repeated Subsections

**Date:** 2026-04-21  
**Package:** `tom_specs_model`  
**Status:** Analysis / Design Decision Required

---

## 1. Background

The TomSpecs object model uses two annotations to assign section IDs to classes that appear
as list elements:

| Annotation | Target | Purpose |
|---|---|---|
| `@SectionId('PD00-XYZ')` | Class | Assigns a fixed, globally unique section ID to the class. |
| `@SectionIdPattern('PD00-XYZ-xx')` | List field | Assigns a *numbered* section ID to each element at runtime; each item becomes `PD00-XYZ-01`, `PD00-XYZ-02`, etc. The prefix (`PD00-XYZ`) must be the same as the `@SectionId` of the owning class or element-type class. |

This works well for a **single level** of repeated sections. The problem arises when an
element type in a `@SectionIdPattern`-annotated list itself contains `List<T>` fields
(nested repeated sections). The current schema and validator do not fully support this case.

---

## 2. How Nested Lists Are Currently Handled

### 2.1 Annotation Setup Today

Currently, the 24 affected classes carry a `@SectionId` on themselves and a
`@SectionIdPattern` on their own list field, for example:

```dart
// Parent container — owns a @SectionIdPattern field
class TestScenarios {
  @SectionId('PD00-DEL-ACC-UAT')
  
  @SectionIdPattern('PD00-DEL-ACC-UAT-xx')   // produces PD00-DEL-ACC-UAT-01, -02, …
  List<TestScenarioEntry> scenarios = [];
}

// Element type — also carries its own @SectionIdPattern for the sub-list
@SectionId('PD00-DEL-ACC-UAT')               // ← same value as the pattern prefix above
class TestScenarioEntry {
  @SectionIdPattern('PD00-DEL-ACC-UAT-xx-STP-xx')   // PROBLEM: 'xx' is used twice
  List<UatTestStepEntry> testSteps = [];
}
```

The inner pattern `PD00-DEL-ACC-UAT-xx-STP-xx` has **two placeholder segments** (`xx`).
With the current schema the first `xx` is meaningless at annotation-authoring time — it
would need to be resolved to the runtime index of the *outer* list element. The annotation
as written is therefore syntactically present but semantically incomplete.

### 2.2 What the Validator Currently Does

The validator (`tom_specs_clitool/lib/src/validator.dart`) runs a **BFS exemption
expansion** starting from the direct element types of `@SectionIdPattern` fields. Every
type reachable from those direct element types — including through `List<T>` field
boundaries — is added to the `patternCovered` set and therefore exempted from requiring
its own `@SectionId`.

Consequence: the nested list element types (e.g. `UatTestStepEntry`, `AlternativeStepEntry`)
currently receive a **silent exemption** even though they carry no annotation at all. The
BFS crosses the `List<T>` boundary inside the pattern-element class and pulls the inner
element types into the exempt set. This is why all 16 tests still pass despite the semantic
incompleteness.

### 2.3 The Correct Annotation Pattern (as designed by the schema)

For proper nested support the user proposed the following structure:

```
Outer container (section PD00-FGH):
  @SectionIdPattern('PD00-FGH-XXX-xx')
  List<XXXEntry> xxxEntries;

  ↓ each item becomes PD00-FGH-XXX-01, PD00-FGH-XXX-02, …

@SectionId('PD00-FGH-XXX')            // template ID = prefix of outer pattern
class XXXEntry {
  @SectionIdPattern('PD00-FGH-XXX-xx-ABC-yy')  // outer placeholder reused
  List<ABCItem> abcItems;

  ↓ each item at runtime becomes e.g. PD00-FGH-XXX-01-ABC-01, -01-ABC-02, …
}

@SectionId('PD00-FGH-XXX-xx-ABC')     // parametric: contains runtime placeholder
class ABCItem {
  …
}
```

Key observations:
- The `@SectionId` on `ABCItem` is **parametric**: it contains the outer `xx` placeholder.
  At authoring time it is a template, not a fixed string.
- The validator and the DocSpecs schema currently treat `@SectionId` as a fixed globally-
  unique string. Parametric IDs break both the uniqueness check and any lookup-by-ID logic.
- The document outliner would need to resolve the placeholder against the runtime list
  index before rendering section numbers.

This means supporting nested repeated sections requires a non-trivial extension to:
1. The `@SectionId` annotation (allow parametric values with placeholders).
2. The uniqueness validator (treat the fixed-prefix part as the key, accept placeholders).
3. The outliner / document renderer (substitute placeholder with ordinal index at render time).

---

## 3. The 24 Affected Classes — Case-by-Case Analysis

The following 24 classes are direct element types of `@SectionIdPattern` list fields AND
themselves contain at least one `List<T>` field, creating nested repeated sections.

For each case we ask: **can the object model be remodelled to avoid nesting** (Option A),
or is the nesting semantically necessary (Option B — requires schema extension)?

---

### Case 1: `AlternativeFlowEntry` → `List<AlternativeStepEntry>`
**File:** `target_business_process.dart`  
**Context:** A process scenario has multiple alternative flows; each flow has numbered steps.

**Pattern today:**
```
@SectionIdPattern('PD00-TAR-STP-SCE-xx-AFL-xx')
List<AlternativeFlowEntry> alternativeFlows;

class AlternativeFlowEntry {
  @SectionIdPattern('PD00-TAR-STP-SCE-xx-AFL-xx-AST-xx')
  List<AlternativeStepEntry> steps;
}
```

**Remodelling option:** Pull steps to the scenario level with a `flowId` reference field.
```dart
@SectionIdPattern('PD00-TAR-STP-SCE-xx-AFL-xx-AST-xx')
List<AlternativeStepEntry> allAlternativeSteps;   // step.flowId links to the flow
```
**Feasible?** ✅ Yes, with minor loss of structural grouping. Step ordering is preserved via
`stepNumber` field; linkage via `flowId` reference. Steps are typically linear within a flow
so a flat list is readable.

---

### Case 2: `ExtensionEntry` → `List<ExtensionStepEntry>`
**File:** `target_business_process.dart`  
**Context:** A use-case interaction has extensions (alternative/exception branches); each
extension has ordered steps.

**Remodelling option:** Same approach as Case 1 — lift extension steps to the interaction
level with an `extensionId` reference field.

**Feasible?** ✅ Yes.

---

### Case 3: `AuthorizationGroupEntry` → `List<RoleReferenceEntry>`
**File:** `access_authorization.dart`  
**Context:** Authorization groups contain role references.

**Remodelling option:** Replace the nested list with a flat mapping at the parent section
level using a `groupId` reference on `RoleReferenceEntry`.
```dart
@SectionIdPattern('PD00-ACC-USA-GRP-xx-ROL-xx')
List<RoleReferenceEntry> allGroupRoles;   // role.groupId links to AuthorizationGroupEntry
```
**Feasible?** ✅ Yes. The group–role relationship is many-to-many; a flat list with
a `groupId` reference is idiomatic.

---

### Case 4: `ComponentEntry` → `List<ComponentInterfaceEntry>`
**File:** `components.dart`  
**Context:** A component has a list of interfaces (API contracts).

**Remodelling option:** Lift interfaces to the parent `ComponentList` level with a
`componentId` reference.

**Feasible?** ✅ Yes. Interfaces are naturally owned by a component; a flat list with a
`componentId` back-reference works.

---

### Case 5: `ComponentFamilyEntry` → `List<FamilyComponentRef>`
**File:** `user_interface_design.dart`  
**Context:** A UI component family groups component references.

**Remodelling option:** Lift `FamilyComponentRef` to the parent `ComponentFamilies` level
with a `familyId` reference.

**Feasible?** ✅ Yes. A component-family membership list is a natural flat structure
(family–member pairs).

---

### Case 6: `CustomDistributionGroup` → `List<DistributionRecipientEntry>`
**File:** `administrative.dart`  
**Context:** A custom distribution group lists its members.

**Remodelling option:** Lift members to the parent `CustomDistributionGroups` level with a
`groupId` reference. The DocSpecs for-each condition could enforce that every group has at
least one member.

**Feasible?** ✅ Yes.

---

### Case 7: `DataClassificationEntry` → `List<HandlingRequirementEntry>` + `List<AccessRestrictionEntry>`
**File:** `business_data_model.dart`  
**Context:** Each data classification carries handling requirements and access restrictions
(two parallel nested lists).

**Remodelling option:** Lift both lists to the parent `DataClassification` level with a
`classificationId` reference on each entry.

**Feasible?** ✅ Yes, and the two lists become independent top-level sections with their
own `@SectionIdPattern` — no nesting required.

---

### Case 8: `DataSourceEntry` → `List<DataSourceEntityEntry>`
**File:** `current_state_analysis.dart`  
**Context:** A data source has key entities (the main domain objects it stores).  
**Note:** The `keyEntities` field has **no** `@SectionIdPattern` annotation today.

**Remodelling option:** Lift `DataSourceEntityEntry` to the parent `DataSources` section with a
`dataSourceId` reference.

**Feasible?** ✅ Yes, and the field should receive a `@SectionIdPattern` in either case.

---

### Case 9: `ExportFormatEntry` → `List<ExportFieldMappingEntry>`
**File:** `user_interface_design.dart`  
**Context:** Each export format definition has a list of field mappings (columns / field bindings).

**Remodelling option:** Lift field mappings to the parent `ExportFormats` level with an
`exportId` reference.

**Feasible?** ✅ Yes. Field mappings are simple rows; a flat list with a back-reference is clean.

---

### Case 10: `FeatureTourEntry` → `List<TourStepEntry>`
**File:** `user_interface_design.dart`  
**Context:** An onboarding feature tour consists of ordered steps.

**Remodelling option:** Lift tour steps to the parent `FeatureTours` level with a `tourId`
reference. Step ordering is captured by a `stepOrder` field.

**Feasible?** ✅ Yes.

---

### Case 11: `FunctionEntry` → `List<SubFunctionEntry>`
**File:** `business_data_model.dart`  
**Context:** Business functions decompose into sub-functions — a **recursive hierarchy**.

**Remodelling option:** A pure flat list cannot represent the parent–child relationship
without an extra `parentFunctionId` reference field on `SubFunctionEntry`. However,
`SubFunctionEntry` can simply reference its parent function via a string ID rather than
being nested inside `FunctionEntry`. This converts the recursive nesting into a flat
function list where each entry optionally references a parent.

**Feasible?** ⚠️ Partially. Flattening is technically possible (adjacency list pattern)
but loses the guarantee that sub-functions are always enumerated under their parent. If
deep recursion is not needed (max 2 levels: function → sub-function), a flat list with a
`parentFunctionId` reference is clean.

---

### Case 12: `NavigationGroupEntry` → `List<NavigationItemEntry>`
**File:** `user_interface_design.dart`  
**Context:** A navigation group contains navigation menu items.

**Remodelling option:** Lift items to the parent `NavigationHierarchy` level with a
`groupId` reference.

**Feasible?** ✅ Yes. Navigation item ordering is preserved via an `itemOrder` field.

---

### Case 13: `PhaseGateReviewEntry` → `List<ReviewCriterionEntry>`
**File:** `system_stage_plan.dart`  
**Context:** Each phase-gate review has a list of pass/fail criteria.

**Remodelling option:** Lift criteria to the parent `PhaseGateReviews` level with a
`gateId` reference.

**Feasible?** ✅ Yes.

---

### Case 14: `ReportEntry` → 5 parallel `List<T>` fields
**File:** `user_interface_design.dart`  
**Context:** A report definition has sections, filters, schedules, distributions, and recipients —
five independent sub-lists.

**Remodelling option:** Lift all five lists to the parent `ReportDefinitions` level with a
`reportId` reference on each entry. This converts five nested lists into five parallel
top-level lists, each with its own `@SectionIdPattern`. The DocSpecs for-each condition
can enforce "every report has at least one section".

**Feasible?** ✅ Yes, and the flattened structure is actually cleaner for validation.

---

### Case 15: `ReportSectionEntry` → `List<ReportColumnEntry>` + `List<ReportChartEntry>`
**File:** `user_interface_design.dart`  
**Context:** `ReportSectionEntry` is itself a direct element of `ReportEntry.sections`
(Case 14), so this is a **3-level nesting**: `ReportDefinitions → ReportEntry.sections →
ReportSectionEntry.columns / ReportSectionEntry.charts`.

**Remodelling option:** If Case 14 is flattened, this becomes a 2-level nesting:
`ReportSections (flat) → columns / charts`. Lift columns and charts to the parent with a
`reportSectionId` reference.

**Feasible?** ✅ Yes, contingent on flattening Case 14. Results in three flat lists:
`reportSections`, `reportColumns`, `reportCharts`, each with `reportId` / `sectionId`
references for linkage.

---

### Case 16: `ScreenElementEntry` → `List<ElementValidationRuleEntry>`
**File:** `user_interface_design.dart`  
**Context:** A screen UI element can have validation rules. `ScreenElementEntry` is itself
a nested element (see Case 17), making this 3-level nesting.

**Remodelling option:** Lift validation rules to the parent screen-section or screen level
with an `elementId` reference.

**Feasible?** ✅ Yes, contingent on flattening Case 17.

---

### Case 17: `ScreenSectionEntry` → `List<ScreenElementEntry>`
**File:** `user_interface_design.dart`  
**Context:** A screen has sections; each section has elements; each element can have
validation rules. **3-level nesting** (`ScreenInventory → ScreenSectionEntry.elements →
ScreenElementEntry.validationRules`).

**Remodelling option:** Lift elements to the screen level with a `sectionId` reference,
making the chain: `screens → screenSections (flat) → screenElements (flat) →
validationRules (flat)`. Each layer has a `@SectionIdPattern` with a parent-id reference.

**Feasible?** ✅ Yes, but requires 3 new parent-level list sections and corresponding
flattening of `ScreenSectionEntry`, `ScreenElementEntry`, and `ElementValidationRuleEntry`.
The UI spec structure is well-known and flat representations are standard in UI metadata
schemas (e.g. JSON Forms, OpenAPI).

---

### Case 18: `SystemToReplaceEntry` → `List<ReplacementSystemDependencyEntry>`
**File:** `system_overview.dart`  
**Context:** Each system to be replaced has a list of its dependencies.

**Remodelling option:** Lift dependencies to the parent `SystemsToReplace` level with a
`systemId` reference.

**Feasible?** ✅ Yes.

---

### Case 19: `TabBarDefinitionEntry` → `List<TabItemEntry>`
**File:** `user_interface_design.dart`  
**Context:** A tab bar has tabs. Tabs must be ordered.

**Remodelling option:** Lift tabs to the parent `TabBarDefinitions` level with a
`tabBarId` reference.

**Feasible?** ✅ Yes. Tab ordering preserved via `tabOrder` field.

---

### Case 20: `TestScenarioEntry` → `List<UatTestStepEntry>`
**File:** `delivery_acceptance.dart`  
**Context:** A UAT test scenario has ordered test steps.

**Remodelling option:** Lift steps to the parent `TestScenarios` level with a `scenarioId`
reference.

**Feasible?** ✅ Yes. Step ordering preserved via `stepNumber` field.

---

### Case 21: `UiComponentEntry` → multiple `List<T>` fields
**File:** `user_interface_design.dart`  
**Context:** From the earlier analysis, `UiComponentEntry` has 5 list fields covering
variants, states, properties, accessibility items, and platform overrides.  
**Note:** The agent output above does not show these lists — they may be in a sub-section
of the class not captured. **Requires a manual read of the class definition to confirm.**

**Remodelling option:** Same approach as Case 14 — lift each sub-list to the parent
`UiComponentLibrary` level with a `componentId` reference.

**Feasible?** ✅ Likely yes, subject to confirming the actual field names.

---

### Case 22: `UtilityNavigationItemEntry` → `List<UtilityMenuItemEntry>`
**File:** `user_interface_design.dart`  
**Context:** A utility navigation item (e.g. user menu, notifications) has dropdown menu items.

**Remodelling option:** Lift menu items to the parent `UtilityNavigation` level with a
`utilityId` reference.

**Feasible?** ✅ Yes.

---

### Case 23: `WorkflowActorEntry` → `List<WorkflowStepEntry>` (`@Reference`)
**File:** `current_state_analysis.dart`  
**Context:** This is annotated with `@Reference` — it is a **cross-reference** (actor
participates in steps that are defined elsewhere), not an ownership relationship. No new
sub-section IDs are created for this list; it is a navigation aid.

**Remodelling option:** No remodelling needed. The `@Reference` annotation already marks
this as non-owned. The validator and outliner both treat `@Reference` fields as exempt
from section ID requirements.

**Feasible?** ✅ Already correct — no nesting issue here.

---

### Case 24: `WorkflowStepEntry` → 5 `List<T>` fields (no `@SectionIdPattern`)
**File:** `current_state_analysis.dart`  
**Context:** Each workflow step has systems used, inputs, outputs, business rules, and
known issues — five sub-lists, all currently **without** `@SectionIdPattern` annotations.
They are silently exempt today because `WorkflowStepEntry` is itself a pattern-covered type.

Sub-lists:
- `List<WorkflowStepSystem> systemsUsed`
- `List<WorkflowInputEntry> inputs`
- `List<WorkflowOutputEntry> outputs`
- `List<WorkflowBusinessRule> businessRules`
- `List<WorkflowStepIssue> knownIssues`

**Remodelling option:** Lift all five to the parent `WorkflowSteps` (or `CurrentStateWorkflows`)
level with a `stepId` reference.

**Feasible?** ✅ Yes, and this is the most important case to resolve because these sub-lists
currently carry **zero annotations** — no `@SectionId`, no `@SectionIdPattern`. If the BFS
crossing is ever removed (Issue 2 from the validator roadmap), all five element types
(`WorkflowStepSystem`, `WorkflowInputEntry`, etc.) would immediately produce coverage warnings.

---

## 4. Summary Table

| # | Class | Nested list(s) | Depth | Remodel feasible? | Notes |
|---|---|---|---|---|---|
| 1 | `AlternativeFlowEntry` | `AlternativeStepEntry` | 2 | ✅ Lift + flowId ref | — |
| 2 | `ExtensionEntry` | `ExtensionStepEntry` | 2 | ✅ Lift + extensionId ref | — |
| 3 | `AuthorizationGroupEntry` | `RoleReferenceEntry` | 2 | ✅ Lift + groupId ref | — |
| 4 | `ComponentEntry` | `ComponentInterfaceEntry` | 2 | ✅ Lift + componentId ref | — |
| 5 | `ComponentFamilyEntry` | `FamilyComponentRef` | 2 | ✅ Lift + familyId ref | — |
| 6 | `CustomDistributionGroup` | `DistributionRecipientEntry` | 2 | ✅ Lift + groupId ref | — |
| 7 | `DataClassificationEntry` | `HandlingRequirementEntry`, `AccessRestrictionEntry` | 2 | ✅ Lift + classificationId ref | 2 parallel sub-lists |
| 8 | `DataSourceEntry` | `DataSourceEntityEntry` | 2 | ✅ Lift + dataSourceId ref | Missing `@SectionIdPattern` today |
| 9 | `ExportFormatEntry` | `ExportFieldMappingEntry` | 2 | ✅ Lift + exportId ref | — |
| 10 | `FeatureTourEntry` | `TourStepEntry` | 2 | ✅ Lift + tourId ref | — |
| 11 | `FunctionEntry` | `SubFunctionEntry` | 2 | ⚠️ Flat adjacency list | Recursive; only practical if depth ≤ 2 |
| 12 | `NavigationGroupEntry` | `NavigationItemEntry` | 2 | ✅ Lift + groupId ref | — |
| 13 | `PhaseGateReviewEntry` | `ReviewCriterionEntry` | 2 | ✅ Lift + gateId ref | — |
| 14 | `ReportEntry` | 5 sub-lists | 2 | ✅ Lift + reportId ref | 5 parallel sub-lists |
| 15 | `ReportSectionEntry` | `ReportColumnEntry`, `ReportChartEntry` | 3 | ✅ (after Case 14) | Depends on Case 14 being flat first |
| 16 | `ScreenElementEntry` | `ElementValidationRuleEntry` | 3 | ✅ (after Case 17) | Depends on Case 17 being flat first |
| 17 | `ScreenSectionEntry` | `ScreenElementEntry` | 3 | ✅ 3-level flatten | Most work; 3 new flat lists |
| 18 | `SystemToReplaceEntry` | `ReplacementSystemDependencyEntry` | 2 | ✅ Lift + systemId ref | — |
| 19 | `TabBarDefinitionEntry` | `TabItemEntry` | 2 | ✅ Lift + tabBarId ref | — |
| 20 | `TestScenarioEntry` | `UatTestStepEntry` | 2 | ✅ Lift + scenarioId ref | — |
| 21 | `UiComponentEntry` | ~5 sub-lists | 2 | ✅ Lift + componentId ref | Confirm field names first |
| 22 | `UtilityNavigationItemEntry` | `UtilityMenuItemEntry` | 2 | ✅ Lift + utilityId ref | — |
| 23 | `WorkflowActorEntry` | `WorkflowStepEntry` | — | ✅ Already `@Reference` | No nesting issue — cross-reference only |
| 24 | `WorkflowStepEntry` | 5 sub-lists (no `@SectionIdPattern`) | 2 | ✅ Lift + stepId ref | **Highest priority** — currently unannotated |

**Summary:** 22 of 24 cases are straightforwardly remodellable by lifting the nested list
to the parent container and adding a back-reference ID field. 1 case (`FunctionEntry`) is
feasible with a constraint on recursion depth. 1 case (`WorkflowActorEntry`) is already
correct via `@Reference`.

---

## 5. Recommended Remodelling Pattern

For every case listed as "✅ Lift + XxxId ref":

**Before (nested):**
```dart
@SectionId('PD00-AAA-BBB')
class OuterEntry {
  @SectionIdPattern('PD00-AAA-BBB-xx-CCC-xx')
  List<InnerEntry> items = [];
}
```

**After (flat):**
```dart
@SectionId('PD00-AAA-BBB')
class OuterEntry {
  // no List field here any more
}

// At the parent container class level:
@SectionIdPattern('PD00-AAA-BBB-xx-CCC-xx')
List<InnerEntry> allInnerEntries = [];

// InnerEntry now carries a back-reference:
@SectionId('PD00-AAA-CCC')    // or leave pattern-covered
class InnerEntry {
  @Form([Field('outerId', String, 'Outer Entry ID', required: true)])
  String? ref;    // or keep as a @Reference field
  // … other fields …
}
```

The DocSpecs **for-each condition** (parallel-list cardinality constraint) can then enforce
that every `OuterEntry` has at least one `InnerEntry` pointing to it, if needed.

---

## 6. Open Questions

1. **UiComponentEntry** — the exact list fields were not captured in the current analysis.
   Read the class to confirm before remodelling.
2. **FunctionEntry** — confirm maximum decomposition depth. If the model only needs one
   level of sub-functions, the adjacency-list pattern with `parentFunctionId` is sufficient.
3. **Ordering** — several inner lists are ordered (tour steps, test steps, process steps).
   Each flattened entry needs an explicit `stepOrder: int` or `itemOrder: int` field.
4. **Schema extension** — if nested repeated sections are retained (not flattened), the
   `@SectionId` annotation and the document outliner must be extended to support parametric
   section IDs (e.g. `PD00-FGH-XXX-xxx-ABC` where `xxx` is a runtime placeholder). This
   is a significant schema change tracked separately.
