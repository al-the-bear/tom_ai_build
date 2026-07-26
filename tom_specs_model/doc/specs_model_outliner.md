# Specs Model Outliner — Generator Specification

> **Scope note (2026-07-16, YRD1 consolidation).** This document specifies the
> outliner *tool* (input, notation, type expansion, output, implementation).
> The normative **model design rules** and **annotation semantics** formerly
> in §6–§7 have moved to the single mapping authority **`som_mapping.md`**
> (same folder); §6/§7 below are redirect anchors only.

## 1. Purpose

The **Specs Model Outliner** is a Dart-based generator that reads the `tom_specs_model` source files via the Dart analyzer and produces a human-readable *outline document* showing the full object-model tree. The output replaces the previous Mermaid class-diagram documentation with a compact, indented notation that is easier to scan and validate.

## 2. Input

- **Source**: All Dart files under `lib/src/` of the `tom_specs_model` package.
- **Root type**: `SolutionBlueprint` (the single top-level aggregator class). The root class name is the key parameter of the generator besides the dart project name it is in. All classes in the dependency tree of the root class are included. For large projects these could even be in other dart projects.
- **Analyzer**: Use `package:analyzer` to resolve types, enumerate fields, and inspect annotations.

## 3. Output

A single text file (e.g., `doc/solution_blueprint_outline.txt`) containing the full model tree in the outliner notation described below.

## 4. Notation

### 4.1 Indentation

Each nesting level adds **4 spaces** of indentation.

### 4.2 Singular Complex Fields (`->`)

A field whose type is a single complex object (zero-or-one / exactly-one relationship).

**Name-match rule:** If the field name matches the type name (equal except for the first character being lowercase), only the **type name** is shown — the field name would be redundant. If they do **not** match, both are shown as `fieldName:TypeName`:

```
-> ExistingSystemsLandscape
    -> content, currentArchitecture
    -> DependenciesAndIntegrations
        ...
-> header:DocumentHeader
    -> content, documentId, project, version, date, author, status
```

In the first line, the field name `existingSystemsLandscape` matches type `ExistingSystemsLandscape` → only the type is shown. In the last line, the field name `header` does not match type `DocumentHeader` → both are shown.

If the field is a `@Reference`, both field name and type name are always shown (see §4.9).

### 4.3 List Fields (`-:`) and Count Constraints

A field whose type is `List<ComplexType>` (zero-or-many relationship). Both the **field name** and the **type name** are always shown as `fieldName:TypeName`, because the field name (typically plural) differs from the type name (typically singular). The field name is structurally significant — it represents a **section level** in the target document, with each list item as a subsection.

When a list has `@Min` or `@Max` constraints, the bounds are shown as a `(min,max)` prefix before the `-:`. If there are no constraints, just `-:` is used. Omitted values mean "no constraint" (min defaults to 0, max defaults to ∞):

| Notation | Meaning |
|----------|---------|
| `-:` | Default: 0..∞ (no constraints) |
| `(1,)-:` | At least 1, no upper limit |
| `(,5)-:` | At most 5, min 0 |
| `(1,5)-:` | Between 1 and 5 items |

```
-: systems:ExistingSystemEntry
    -> content, systemName, technology, purpose
    (1,)-: knownLimitations:LimitationEntry
        -> content, limitation, impact
```

### 4.4 Leaf Fields

All scalar fields (`String?`, `String`, enum types) of a class are collected on a **single line**, comma-separated, prefixed with `->`:

```
-> content, systemName, technology, purpose
```

**Line wrapping:** If the leaf line exceeds the configured max line length (default **120 characters**, including indentation), it wraps to continuation lines indented **one level deeper** than the original:

```
-> content, systemName, technology, purpose, activeUsers,
    dataVolume, operationalSince, supportStatus
```

### 4.5 Enum Fields

Enums are shown inline with their values in parentheses:

```
-> Priority (must, should, could, wontThisTime)
```

If an enum field is among other leaf fields on the same line, it appears in-place with the field name as prefix:

```
-> content, priority: Priority (must, should, could, wontThisTime), status
```

Enum values are shown at **every occurrence** — keeps the outline self-contained.

### 4.6 Content Field

The `content: String?` field is present on nearly every class, it represents the section content of a document section, the text between the section headline and the next headline. It is shown as a regular leaf field (first in the comma list by convention) — **not** hidden or implicit. Other scalar fields will be inside this section text in the actual document. If a class has additional scalar fields, the @ContentType must be "form", which indicates this is the container for the data fields. If @ContentType is not scalar (like SQL, DDL, dart etc.) the class cannot have other scalar fields.

### 4.7 Nullable vs Non-Nullable

The outliner does distinguish `String?` from `String` or `Type?` from `Type`. The types (or field names) are simply suffixed with a question mark, just as they are in Dart.

### 4.8 Field Ordering

Fields are listed in **declaration order** as they appear in the source class.

### 4.9 References

Fields annotated with `@Reference` are shown with both field name and type name, plus reference information:

**Singular reference:**

```
-> fieldName:TypeName:<reference-path>
```

**List reference:**

```
-: fieldName:TypeName:<reference-path>
```

The reference path uses `-` to separate 1:1 relationships and `:` to separate 1:n (List) relationships:

```
-> basedOnRequirement:FunctionalRequirementEntry:SolutionBlueprint-SystemOverview-RequirementsOverview:functionalRequirements
```

> **Note:** The current model has no cross-references. This notation is defined for future use.

### 4.10 Inline Comments

Fields or classes annotated with `@Comment("text")` display the comment as a trailing annotation:

```
-: systems:ExistingSystemEntry          ← (text from @Comment)
```

**Comment placement:** The `← (...)` marker starts at column **50** of the line (counting from the beginning PLUS indentation), or immediately after the line content plus one space if the content is longer than 50 characters.

### 4.11 Position Markers

The default position is **relative** — subsections appear in the order they are declared in the class. When a field has a non-default `@Position` annotation, it is shown as a trailing marker in square brackets:

```
-: preamble:PreambleEntry                [first]
-: items:ItemEntry                       [any]
-: appendices:AppendixEntry              [last]
```

Position markers are aligned at column 50 (same as comments). The `[relative]` marker is never shown as it is the default.

### 4.12 ForEach Constraints

A list field annotated with `@ForEach` has a bidirectional relationship with a registry section type. This is shown with a `⟷` marker:

```
-: implementations:ImplementationEntry   ⟷ RequirementEntry.requirementId
```

This means: for every entry of type `RequirementEntry` (matched by its `requirementId` field), there must be a corresponding item in the `implementations` list, and vice versa.

### 4.13 Outline Visibility

Not all annotations appear in the outline. Annotations are categorized as **visible** (affect the outline rendering) or **schema-only** (used for schema generation and validation but not shown in the outline):

| Annotation | Visible | Outline rendering |
|------------|---------|-------------------|
| `@Min`, `@Max` | Yes | `(min,max)-:` prefix on list lines |
| `@Position` | Yes | `[first]`, `[last]`, `[any]` marker (non-default only) |
| `@ForEach` | Yes | `⟷ Type.key` marker |
| `@TextRequired` | Yes | `!` suffix on `content` field |
| `@ContentType` | Yes | `@type` suffix on content |
| `@Unused` | Yes | Marks content as unused (no section text expected) |
| `@Comment` | Yes | `← (text)` marker |
| `@Reference` | Yes | Reference path notation (see §4.9) |
| `@SectionId` | Yes | Can be shown alongside type name |
| `@SectionIdPattern` | Yes | Can be shown alongside list field |
| `@Prefix` | No | Schema constraint only |
| `@PatternCheckId` | No | Schema constraint only |
| `@PatternCheck` | No | Schema constraint only |
| `@MaxDepth` | No | Schema constraint only |
| `@AllowedTags` | No | Schema constraint only |
| `@ValidationPrompt` | No | Schema constraint only |
| `@AccessKey` | No | Schema constraint only |
| `@MinLength`, `@MaxLength` | No | Schema constraint only |
| `@SeedFor` | No | Schema constraint only (compile-time document link) |
| `@ContentHelp` | No | Schema constraint only (content authoring guidance) |
| `@Document` | No | Schema constraint only (document root metadata) |
| `@SerializationOrder` | No | Meta-data only (member emission order) |
| `@MapsTo`, `@DetailedIn` | No | Meta-data only (Solution Blueprint → Phase 3 traceability) |
| `@StandardReferences` | No | Meta-data only (standard provenance + connotation) |

### 4.14 Inline Schema Annotations (`--show-schema-annotations`)

When the `--show-schema-annotations` flag is set, schema-only annotations (those marked "No" in §4.13) are shown **inline** in the tree, directly above the line they annotate. Each annotation appears on its own line, at the same indentation as the annotated line, prefixed with `#` to distinguish it from structural lines.

Without the flag, the outline is generated as before — schema annotations are omitted.

**Class-level annotations** appear above the class/type line:

```
        -> ExistingSystemsLandscape
            # @Prefix("CSA-SYS")
            # @PatternCheckId(r'^CSA-SYS-\d{2}$', "Must be CSA-SYS-NN")
            # @MaxDepth(2)
            -> content!, currentArchitecture
            -: systems:ExistingSystemEntry
```

**Field-level annotations** appear above the field they annotate. For leaf fields on a comma-separated `->` line, the annotation is placed above the entire leaf line:

```
            -: systems:ExistingSystemEntry
                # @MinLength(50) content
                # @PatternCheck(r'^[A-Z]\w+$') systemName
                # @AccessKey("systemName") systemName
                -> content, systemName, technology, purpose
```

**Rules:**

- Only classes/fields that **have** schema-only annotations get `#` lines — no clutter when no schema annotations exist.
- Annotation lines use `#` prefix to visually separate them from structural `->` and `-:` lines.
- Class-level annotations appear after the class type line, before the class's children.
- Field-level annotations appear before the leaf/child line they belong to, with the field name after the annotation to identify the target.
- When a class appears multiple times (inline expansion), its schema annotations are shown at **every** occurrence for self-containedness.

## 5. Type Expansion

### 5.1 Inline Expansion

When a complex type is used, its full subtree is shown **inline at every usage point**. There is no separate "type definitions" section — duplication is intentional so the reader can see the full structure at each location without jumping around.

### 5.2 Cycle Detection

Cycles **must not exist** in the model. If a cycle is detected during tree walking, the generator **fails with a clear error message** naming the types involved in the cycle. There is no soft handling (no `[circular — see above]`). Note that @Reference-marked link are not considered cycles, as the annotation clearly indicates that the link should be shown, but not followed in traversal.

## 6. Model Design Rules (moved)

> **Moved (2026-07-16, YRD1 consolidation).** The model design rules — the
> §6.1 type constraints, the §6.1a canonical field shapes, the §6.1b
> keep-a-class and §6.1c keep-a-level rules, and all related structural
> constraints — are now maintained in the single mapping authority:
> **`som_mapping.md`** (§2 object model, §12 cross-cutting requirements /
> structural invariants), in this same `doc/` folder. This section is kept
> only as an anchor for older cross-references; do not extend it.

## 7. Annotations (moved)

> **Moved (2026-07-16, YRD1 consolidation).** The annotation semantics
> (`@SectionId`, `@SectionIdPattern`, `@Document`, `@Form`, `@ContentType`,
> `@ContentHelp`, `@Comment`, `@Unused`, `@Min`/`@Max`, `@MapsTo`,
> `@DetailedIn`, `@Headline`, …) are now maintained
> in **`som_mapping.md`** §5 (annotation table) and the catalogue in
> `tom_specs_core/README.md`. This section is kept only as an anchor for
> older cross-references; do not extend it.

## 8. Output Example

The example below shows the actual `tom_specs_model` tree with all notation
features. Hypothetical annotations are included to demonstrate the notation —
they are not yet all applied to the model.

```
# Solution Blueprint Outline

SolutionBlueprint
    -> header:DocumentHeader
        -> content, documentId, project, version,
            date @date, author, status
    -> CurrentStateAnalysis
        -> content
        -> ExistingSystemsLandscape
            -> content!, currentArchitecture
            -: systems:ExistingSystemEntry
                -> content, systemName, technology, purpose,
                    activeUsers @int, dataVolume,
                    operationalSince @date, supportStatus
                (1,)-: knownLimitations:LimitationEntry
                    -> content, limitation, impact
            -> DependenciesAndIntegrations
                -> content
                -: items:SystemDependencyEntry
                    -> content, sourceSystem, targetSystem,
                        dependencyType, protocol, dataExchanged,
                        criticality
        -> CurrentBusinessProcesses
            -> content
            (1,)-: workflows:CurrentWorkflowEntry
                -> content, processName, trigger, output,
                    cycleTime
                (1,)-: steps:WorkflowStepEntry
                    -> content, stepName, description
                -: actors:WorkflowActorEntry
                    -> content, actorName, role
                -: manualSteps:WorkflowStepEntry
                    -> content, stepName, description
                -: errorProneSteps:WorkflowStepEntry
                    -> content, stepName, description
            -> ProcessMetrics
                -> content
                -: items:ProcessMetricEntry
                    -> content, metricName, processReference,
                        currentValue, unit, measurementMethod,
                        frequency
        -> PainPointsAndGaps
            -> content
            -> OperationalPainPoints
                -> content
                (1,)-: items:PainPointEntry
                    -> content, painPoint, description, impact,
                        affectedProcess, severity, workaround
            -> BusinessPainPoints
                -> content
                -: items:PainPointEntry
                    -> content, painPoint, description, impact,
                        affectedProcess, severity, workaround
            -> TechnicalPainPoints
                -> content
                -: items:PainPointEntry
                    -> content, painPoint, description, impact,
                        affectedProcess, severity, workaround
        -> CurrentDataLandscape
            -> content, dataQualityAssessment
            -: dataSources:DataSourceEntry
                -> content, dataStoreName, storeType, technology,
                    dataFormat, estimatedVolume, growthRate,
                    qualityLevel, owner, retentionPolicy
    -> projectOrganizationProcess:ProjectOrganizationAndProcess
        ...
    -> Administrative
        ...
    -> SystemOverview
        -> content
        -> SystemDescription
            -> content!, systemPurpose, systemContext, taskArea
            (1,)-: userCategories:UserCategoryEntry
                -> content, categoryName, description,
                    typicalTasks, accessLevel, estimatedCount @int
            -> UserInteractionModel
                -> content, sessionModel, concurrencyModel
                -: channels:InteractionChannelEntry
                    -> content, channelName, description
                -: interactionPatterns:InteractionPatternEntry
                    -> content, patternName, description
        -> Goals
            -> content
            (1,)-: businessGoals:BusinessGoalEntry
                -> content, goalId, goalName, description,
                    measurableTarget, targetDate @date
            (1,)-: projectGoals:ProjectGoalEntry
                -> content, goalId, goalName, description,
                    successCriteria
        -> requirements:RequirementsOverview  ← (Seeds → RC)
            -> content
            (1,)-: functionalRequirements:FunctionalRequirementEntry
                -> content, requirementId, title, description,
                    priority: Priority (must, should, could, wontThisTime),
                    source, rationale, acceptanceCriteria,
                    status: Status (draft, proposed, approved,
                        implemented, verified, deferred, rejected),
                    relatedUseCase, relatedBusinessProcess,
                    affectedDataEntities
            -: nonFunctionalRequirements:NonFunctionalRequirementEntry
                -> content, requirementId, title, description,
                    priority: Priority (must, should, could, wontThisTime),
                    source, rationale, acceptanceCriteria,
                    status: Status (draft, proposed, approved,
                        implemented, verified, deferred, rejected),
                    qualityAttribute, measurableTarget
        -> systemsToReplace:SystemsToReplace  ← (Seeds → CS)
            ...
        -> SystemBoundaries
            ...
        -> FrameworkConditions
            ...
        -> RisksAndAssumptions
            ...
    -> OrganizationalFramework
        ...
    -> targetBusinessProcess:TargetBusinessProcessModel
        ...
    -> businessDataModel:BusinessObjectAndDataModel
        ...
    -> technicalFramework:TechnicalFrameworkConcept
        ...
    -> accessAuthorization:AccessAndAuthorizationConcept
        ...
    -> UserInterfaceDesign
        ...
    -> SystemQualityGoals
        ...
    -> ComponentsToUse
        ...
    -> SystemStagePlan
        ...
    -> deliveryAcceptance:DeliveryScopeAndAcceptance
        ...                                      [last]
```

**Features demonstrated:**

- **Name-match rule**: `CurrentStateAnalysis` (field matches type) vs `header:DocumentHeader` (field ≠ type).
- **`@Form` field display**: `content @Form(attributeName, dataType, length, mandatory, description)`.
- **Enum inline values**: `priority: Priority (must, should, could, wontThisTime)`.
- **`@Comment`**: `← (Seeds → RC)` on the requirements section.
- **`@Min`/`@Max` count constraints**: `(1,)-:` on lists requiring at least one item (knownLimitations, workflows, steps, businessGoals, functionalRequirements, etc.).
- **`@TextRequired`**: `content!` suffix on ExistingSystemsLandscape and SystemDescription.
- **`@Position`**: `[last]` on deliveryAcceptance (must appear after all other sibling sections).
- **Line wrapping**: Long leaf lines wrap at 120 chars, continuation indented one level deeper.
- **Inline expansion**: `PainPointEntry` is expanded identically under all three pain-point subsections.
- **List fields**: Always `fieldName:TypeName` (e.g., `-: items:SystemDependencyEntry`).
- **Mismatched section names**: `projectOrganizationProcess:ProjectOrganizationAndProcess`, `targetBusinessProcess:TargetBusinessProcessModel`, etc.

## 9. Generator Implementation Notes

1. **Entry point**: A Dart CLI tool in `tom_specs_model/tool/generate_outline.dart`.
2. **Analyzer setup**: Use `SummaryBasedDartSdk` with an embedded SDK summary bundle (no installed SDK required). The `sdk_summary.sum` file (~3 MB) is split into ~50 base64-encoded Dart source files in `lib/src/sdk_summary/`, reassembled at runtime. Model source files are analyzed directly from disk. See `analyzer_wo_sdk.md` for full details.
3. **Annotation reading**: Read `@Reference`, `@SectionId`, `@SectionIdPattern`, `@Comment`, `@ContentType`, `@Form`, `@Unused`, `@Prefix`, `@PatternCheckId`, `@TextRequired`, `@MaxDepth`, `@AllowedTags`, `@ValidationPrompt`, `@Min`, `@Max`, `@Position`, `@ForEach`, `@AccessKey`, `@PatternCheck`, `@MinLength`, `@MaxLength`, `@SeedFor`, `@SerializationOrder`, `@MapsTo`, `@DetailedIn`, `@StandardReferences` from the analyzer's element model. All model classes in the package are scanned — no marker annotation is required. The full annotation catalogue and the section base types are documented in [`tom_specs_core/README.md`](../../tom_specs_core/README.md).
4. **Tree walk**: Start from `SolutionBlueprint`, recursively visit each field:
   - If `String` / `String?` → collect as leaf.
   - If enum → format with values inline.
   - If `List<T>` → emit `(min,max)-: fieldName:TypeName` (with constraints from `@Min`/`@Max`) and recurse into `T`.
   - If complex type → emit `-> TypeName` and recurse.
   - If `@Reference` → emit with reference notation.
5. **Validation pass** (before output): Run all rules from §6 — type constraints, naming, class style, content type, cycle detection. Fail on first error with clear message.
6. **Line wrapping**: Track current line length. When a leaf line exceeds the max (default 120), wrap at a comma boundary and indent the continuation one level deeper.
7. **Comment alignment**: Pad `← (...)` annotations to start at column 50, or one space after content if content exceeds 50 chars.
8. **Inline schema annotations**: When `--show-schema-annotations` is set, emit `# @Annotation(...)` lines inline during the tree walk — class-level after the type line, field-level before the field line (see §4.14).

## 10. Implementation Plan

### Phase 1: Define Annotations

Create the annotation classes in `tom_specs_core/lib/src/annotations/`:

1. `reference.dart` — `@Reference(String description, Symbol field)`
2. `section_id.dart` — `@SectionId(String id)`
3. `section_id_pattern.dart` — `@SectionIdPattern(String pattern)`
4. `comment.dart` — `@Comment(String text)`
5. `type_hint.dart` — `@Type(String type)`
6. `content_type.dart` — `@ContentType(String type)`
7. `seed_for.dart` — `@SeedFor(Type documentRootClass)`
8. Barrel export from `annotations.dart`.

### Phase 2: Build the Outline Generator

Create `tom_specs_clitool/bin/generate_outline.dart`:

1. **Analyzer bootstrap** — load embedded SDK summary from base64 chunks and create `AnalysisDriver` with `SummaryBasedDartSdk` (see `analyzer_wo_sdk.md`).

USER: check in tom_dart_editor/tom_dart_editor_test how instantiate the analyzer so it doesn't require an installed SDK. I want it to be instantiated this way. Write short tutorial how to do this in analyzer_wo_sdk.md

1. **Model discovery** — locate the root `SolutionBlueprint` class, collect all fields/types reachable from there.
2. **Validation engine** — implement all §6 rules as a validation pass:
   - Iterate all discovered types.
   - Check type constraints (no `List<String>`, no primitive non-String, etc.).
   - Check class style (no constructors, no `final`/`const`).
   - Check `@ContentType` constraints (non-Form ↔ no other scalars).
   - Check `content: String?` presence.
   - Cycle detection via DFS from root.
   - Collect all errors; report all at once; exit non-zero.

USER: double check the document for additional rules again

3. **Tree walker** — recursive visitor starting from `SolutionBlueprint`:
   - Classify each field: leaf, enum, complex singular, complex list, reference.
   - Collect leaf fields into comma-separated `->` lines with wrapping.
   - Emit complex singular as `-> TypeName` or `-> fieldName:TypeName` and recurse.
   - Emit complex list as `-: fieldName:TypeName` and recurse.
   - Emit references with `:<reference-path>`.
   - Append `@Comment` annotations aligned to column 50+indent.
   - Append `@Type` hints after field names.
   - Append `@ContentType` hints after `content` field.
4. **Output writer** — write the indented tree to the output text file.
5. **CLI** — accept arguments: `--output` (file path, default is <root-type>_outline.txt), `--max-line-length` (default 120), `--root-type` (default `SolutionBlueprint`), `--show-schema-annotations` (prepend schema annotations header, see §4.14).

### Phase 3: Integration

1. Add a `tool/` entry in the package for running the generator. USER: is this so? We have a separate project for the tool now.
2. Document the generator command in the package README.
3. Generate the initial outline document and verify it against the model.

## 11. Migration Plan

The current `tom_specs_model` codebase uses `final` fields with `const` constructors. The new model design rules (§6.3) require plain mutable fields with no constructors. This migration also includes adding annotation support.

### Step 1: Create Annotation Classes

- Define all six annotation classes (§7) in `lib/src/annotations/`.
- Export from the package barrel.
- This is a non-breaking addition — no existing code changes.

### Step 2: Remove `final`, `const`, and Constructors

For every model class (approximately 150+ classes across 15 files):

**Before:**
```dart
class ExistingSystemEntry {
  final String? content;
  final String? systemName;
  final String? technology;
  final List<LimitationEntry> knownLimitations;

  const ExistingSystemEntry({
    this.content,
    this.systemName,
    this.technology,
    this.knownLimitations = const [],
  });
}
```

**After:**
```dart
class ExistingSystemEntry {
  String? content;
  String? systemName;
  String? technology;
  List<LimitationEntry> knownLimitations = [];
}
```

**Migration rules per class:**
1. Remove `final` from all field declarations.
2. Remove `const` constructors entirely.
3. For `List<T>` fields: change `final List<T> x;` → `List<T> x = [];`.
4. For complex type fields with defaults: change `final T x;` with `this.x = const T()` → `T x = T();`. (Requires `T` to also have dropped its `const` constructor, so process leaf types first.)
5. For `String?` and nullable complex types: simply remove `final` (they default to `null`).

**Processing order:** Process files bottom-up in the dependency tree — leaf entry types first (they have no complex children), then container types, then section types, then `SolutionBlueprint` last.

### Step 3: Verify Naming Rule Compliance

Run the outliner generator's validation pass to check:
- All singular complex field names match their type names (camelCase).
- Current known violations to investigate: `header` (type `DocumentHeader`), `systemOverview` (type `SystemOverview` — OK), `componentsToUse` (type `ComponentsToUse` — OK).
- Fix any field/type name mismatches by renaming the field or the type.

### Step 4: Add Annotations to Model Classes

Incrementally add annotations as needed:
- `@SectionId` on section classes that have known document IDs.
- `@SectionIdPattern` on list fields with numbered subsections.
- `@Comment` where inline documentation is helpful.
- `@Type` on `String?` fields that represent dates, numbers, etc.
- `@ContentType` on `content` fields that are not `Form`.
- `@Reference` when cross-references are introduced.

This step is gradual — annotations can be added over time as the model matures.

### Step 5: Run Generator and Validate

1. Run `dart analyze` — must show zero issues.
2. Run the outline generator — must produce output with no validation errors.
3. Review the generated outline for correctness.
4. Commit the migrated model and generated outline together.

### Migration Risk Notes

- **Breaking change**: Removing `const` constructors breaks any external code that constructs model instances with `const`. Since this package is internal and the classes are data containers (not constructed by external consumers), the risk is low.
- **List defaults**: Changing from `const []` to `[]` means each instance gets its own mutable list. This is intentional — the model is record-like, not immutable value objects.
- **Processing order matters**: A class cannot use `T()` as a default until `T` has been migrated to have a default (no-arg) constructor. Process leaf types first.
