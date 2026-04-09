# Specs Model Outliner — Generator Specification

## 1. Purpose

The **Specs Model Outliner** is a Dart-based generator that reads the `tom_specs_model` source files via the Dart analyzer and produces a human-readable *outline document* showing the full object-model tree. The output replaces the previous Mermaid class-diagram documentation with a compact, indented notation that is easier to scan and validate.

## 2. Input

- **Source**: All Dart files under `lib/src/` of the `tom_specs_model` package.
- **Root type**: `ProjectDefinition` (the single top-level aggregator class). The root class name is the key parameter of the generator besides the dart project name it is in. All classes in the dependency tree of the root class are included. For large projects these could even be in other dart projects.
- **Analyzer**: Use `package:analyzer` to resolve types, enumerate fields, and inspect annotations.

## 3. Output

A single text file (e.g., `doc/pd_project_definition_outline.txt`) containing the full model tree in the outliner notation described below.

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
-> basedOnRequirement:FunctionalRequirementEntry:ProjectDefinition-SystemOverview-RequirementsOverview:functionalRequirements
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
| `@FieldType` | Yes | `@type` suffix on field |
| `@ContentType` | Yes | `@type` suffix on content |
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

## 5. Type Expansion

### 5.1 Inline Expansion

When a complex type is used, its full subtree is shown **inline at every usage point**. There is no separate "type definitions" section — duplication is intentional so the reader can see the full structure at each location without jumping around.

### 5.2 Cycle Detection

Cycles **must not exist** in the model. If a cycle is detected during tree walking, the generator **fails with a clear error message** naming the types involved in the cycle. There is no soft handling (no `[circular — see above]`). Note that @Reference-marked link are not considered cycles, as the annotation clearly indicates that the link should be shown, but not followed in traversal.

## 6. Model Design Rules

These are the rules for how model classes must be designed. The generator **validates** all of them and **fails with a clear error message** for any violation. There are no warnings — every violation is a hard error.

### 6.1 Type Constraints

| Rule | Description |
|------|-------------|
| **No `List<String>`** | All list fields must use complex types. `List<String>` or `List<basicType>` is an error. |
| **No primitive non-String scalars** | Leaf fields must be `String`, `String?`, or an enum type. No `int`, `double`, `bool`, `num`, `DateTime`. Dates and numbers are represented as `String?` and annotated with `@Type()`. |
| **`content: String?` expected** | Every model class must have a `content: String?` field. Missing = error. |

### 6.2 Class Style

| Rule | Description |
|------|-------------|
| **No constructors** | Classes must not declare constructors. A default constructor is implied. |
| **No `final` or `const`** | Fields are declared without keywords — plain mutable instance fields, like nested records. |
| **Non-nullable defaults** | Non-nullable fields are assigned a valid default value. Nullable fields are left null. |
| **No computed properties** | Only concrete instance fields are part of the model. Getters, static fields, and computed properties are excluded. |

### 6.3 Naming Convention

| Rule | Description |
|------|-------------|
| **Singular match preferred** | Singular complex field names should match their type name (lowercase first letter). E.g., `SystemOverview systemOverview`. |
| **Mismatch allowed** | If a field name does not match (e.g., `header` for type `DocumentHeader`), it is not an error — the outliner shows both names as `fieldName:TypeName`. |
| **List names always shown** | List field names (typically plural) always differ from the singular type name, so both are always shown as `fieldName:TypeName`. |

### 6.4 ContentType Constraints

| Rule | Description |
|------|-------------|
| **`@ContentType(Form)` (default)** | The content field is a form — the class's other scalar fields represent the form fields within the content. This is the usual case. |
| **Non-Form `@ContentType`** | If `content` has a non-Form `@ContentType` (e.g., `DDL`, `SQL`, `Dart`, `ER-Diagram`), the class **must not have other scalar fields**. The content occupies the full text. Subsections (complex children) are still allowed but uncommon — diagrams and code are typically leaf nodes. |

### 6.5 Reachability

Only types reachable from the root type (`ProjectDefinition`) are included in the outline. Unreachable types (e.g., common utility types not referenced by any reachable class) are silently omitted.

### 6.6 Inheritance

When a class extends another model class, all fields declared on the subclass are shown (including any re-declared fields). Inherited fields that are **not** re-declared on the subclass are shown as well — the outline represents the full document structure. In the planned two-step model split, subclasses fully re-declare their fields (replacement, not augmentation), so the outliner simply shows what each class declares.

## 7. Annotations

Annotations are defined in the `tom_specs_core` package and applied to model classes and fields. The generator reads annotations via the analyzer.

### 7.1 `@Reference(String description, Symbol field)`

Declares that a field is a **reference** to data owned elsewhere in the tree, not an ownership relationship.

- Applied to: singular or list fields.
- Effect: The field is shown with reference notation (see §4.9).
- `description`: Human-readable label for the reference.
- `field`: The target field symbol being referenced.

### 7.2 `@SectionId(String id)`

Declares the **section ID** that the annotated class has in the target specification document.

- Applied to: classes.
- Effect: The generator can emit the section ID alongside the type name if desired.
- Example: `@SectionId("PD00-CSA")` → class maps to section PD00-CSA.

### 7.3 `@SectionIdPattern(String pattern)`

Declares the **section ID pattern** for items in a `List<T>` field. The pattern uses a suffix (e.g., `-xx`) indicating that each list item gets a unique numbered section.

- Applied to: list fields.
- Effect: Implies a section level in the document — the field is a section, each list item is a subsection.
- Example: `@SectionIdPattern("PD00-CSA-SYS-xx")` → first item is `PD00-CSA-SYS-01`, second `PD00-CSA-SYS-02`, etc.

### 7.4 `@Comment(String text)`

Provides a short inline comment that appears in the outline output.

- Applied to: fields or classes.
- Effect: Shown as `← (text)` in the outline (see §4.10).
- Example: `@Comment("same type reused")`.

### 7.5 `@Type(String type)`

Annotates a `String?` field with its **semantic type** — what the string actually represents.

- Applied to: `String?` leaf fields.
- Allowed values: `int`, `double`, `date`, `time`, `datetime`.
- Effect: The generator shows the type hint in the outline: `-> operationalSince @date, activeUsers @int`.

### 7.6 `@ContentType(String type)`

Annotates the `content` field to declare the **format** of the content text.

- Applied to: `content` fields only.
- Allowed values: `Form` (default), `DDL`, `SQL`, `Dart`, `ER-Diagram`, `Mermaid`, and other format identifiers.
- Effect: `Form` means scalar fields are form fields within the content. Non-Form types prohibit other scalar fields (see §6.4).
- Shown in outline: `-> content @Form` or `-> content @DDL`.

### 7.7 `@Prefix(String prefix)`

Declares the section-type prefix used for two-stage ID matching.

- Applied to: classes.
- Effect: When the schema resolver encounters a section heading, it first matches the prefix (case-insensitive, declaration order, first match wins) to determine the section type.
- Example: `@Prefix('REQ')` → headings starting with "REQ" resolve to this section type.

### 7.8 `@PatternCheckId(String pattern, {String? errorMessage})`

Declares a regex pattern that section IDs must match after prefix resolution.

- Applied to: classes.
- Effect: Stage two of the two-stage ID matching — after `@Prefix` resolves the section type, this pattern validates the full ID format.
- Example: `@PatternCheckId(r'^REQ-\d{3}$', errorMessage: 'Must be REQ-NNN')`.

### 7.9 `@TextRequired()`

Marks that the content text of a section must not be empty.

- Applied to: classes.
- Effect: The validator ensures the section has non-empty text content.
- Shown in outline: `!` suffix on the `content` field: `-> content!`.

### 7.10 `@MaxDepth(int levels)`

Limits the maximum nesting depth of subsections.

- Applied to: classes.
- Effect: 0 = no subsections allowed; 1 = direct children only; etc.
- Example: `@MaxDepth(2)` → allows two levels of nesting.

### 7.11 `@AllowedTags(List<String> tags)`

Restricts the set of tags that may be applied to sections of this type.

- Applied to: classes.
- Effect: Only the listed tag values are valid for this section type.
- Example: `@AllowedTags(['critical', 'optional', 'deferred'])`.

### 7.12 `@ValidationPrompt(String prompt)`

Provides an AI validation prompt for section content.

- Applied to: classes.
- Effect: Used by AI-assisted validators to check content quality.
- Example: `@ValidationPrompt('Each requirement must have a measurable acceptance criterion.')`.

### 7.13 `@Min(int count)`

Declares the minimum number of items required in a list field.

- Applied to: `List<T>` fields.
- Effect: `@Min(1)` means at least one item required. Default (no annotation): 0.
- Shown in outline: Part of `(min,max)-:` prefix — e.g., `(1,)-:`.

### 7.14 `@Max(int count)`

Declares the maximum number of items allowed in a list field.

- Applied to: `List<T>` fields.
- Effect: Limits the number of list items. Default (no annotation): ∞.
- Shown in outline: Part of `(min,max)-:` prefix — e.g., `(,5)-:`.

### 7.15 `@Position(String position)`

Declares the ordering position of a subsection field within its parent.

- Applied to: singular or list fields (subsection fields).
- Default (no annotation): `'relative'` — sections appear in class declaration order.
- Values: `'first'` (before all others), `'last'` (after all others), `'any'` (no ordering constraint).
- Shown in outline: `[first]`, `[last]`, `[any]` trailing marker. `[relative]` is never shown.

### 7.16 `@ForEach(String registryType, String key)`

Declares a bidirectional for-each constraint between a list and a registry.

- Applied to: `List<T>` fields.
- Effect: For every entry registered under `registryType`, there must be a corresponding item in this list (matched by `key`), and vice versa.
- Shown in outline: `⟷ RegistryType.key` trailing marker.
- Example: `@ForEach('FunctionalRequirementEntry', 'requirementId')`.

### 7.17 `@AccessKey(String key)`

Marks a field as the key used for registry access and for-each matching.

- Applied to: `String?` fields.
- Effect: Identifies which field on the target class provides the key value for matching against registry entries in `@ForEach` relationships.
- Example: `@AccessKey('requirementId')` on a `requirementId` field.

### 7.18 `@PatternCheck(String pattern, {String? errorMessage})`

Declares a regex pattern that a field value must match.

- Applied to: `String?` fields.
- Effect: Validates the field content against the pattern.
- Example: `@PatternCheck(r'^\d{4}-\d{2}-\d{2}$', errorMessage: 'Must be YYYY-MM-DD')`.

### 7.19 `@MinLength(int length)`

Declares the minimum text length for a string field.

- Applied to: `String?` or `content` fields.
- Effect: Validates that the text has at least `length` characters.

### 7.20 `@MaxLength(int length)`

Declares the maximum text length for a string field.

- Applied to: `String?` or `content` fields.
- Effect: Validates that the text does not exceed `length` characters.

## 8. Output Example

The example below shows the actual `tom_specs_model` tree with all notation
features. Hypothetical annotations are included to demonstrate the notation —
they are not yet all applied to the model.

```
# Project Definition Outline

ProjectDefinition
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
- **`@FieldType` hints**: `date @date`, `activeUsers @int`, `estimatedCount @int`.
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
2. **Analyzer setup**: Use `AnalysisContextCollection` to resolve the package and all its source files.
3. **Annotation reading**: Read `@tomReflector`, `@Reference`, `@SectionId`, `@SectionIdPattern`, `@Comment`, `@FieldType`, `@ContentType`, `@Prefix`, `@PatternCheckId`, `@TextRequired`, `@MaxDepth`, `@AllowedTags`, `@ValidationPrompt`, `@Min`, `@Max`, `@Position`, `@ForEach`, `@AccessKey`, `@PatternCheck`, `@MinLength`, `@MaxLength` from the analyzer's element model.
4. **Tree walk**: Start from `ProjectDefinition`, recursively visit each field:
   - If `String` / `String?` → collect as leaf (include `@FieldType` hint if present).
   - If enum → format with values inline.
   - If `List<T>` → emit `(min,max)-: fieldName:TypeName` (with constraints from `@Min`/`@Max`) and recurse into `T`.
   - If complex type → emit `-> TypeName` and recurse.
   - If `@Reference` → emit with reference notation.
5. **Validation pass** (before output): Run all rules from §6 — type constraints, naming, class style, content type, cycle detection. Fail on first error with clear message.
6. **Line wrapping**: Track current line length. When a leaf line exceeds the max (default 120), wrap at a comma boundary and indent the continuation one level deeper.
7. **Comment alignment**: Pad `← (...)` annotations to start at column 50, or one space after content if content exceeds 50 chars.

## 10. Implementation Plan

### Phase 1: Define Annotations

Create the annotation classes in `tom_specs_core/lib/src/annotations/`:

1. `reference.dart` — `@Reference(String description, Symbol field)`
2. `section_id.dart` — `@SectionId(String id)`
3. `section_id_pattern.dart` — `@SectionIdPattern(String pattern)`
4. `comment.dart` — `@Comment(String text)`
5. `type_hint.dart` — `@Type(String type)`
6. `content_type.dart` — `@ContentType(String type)`
7. Barrel export from `annotations.dart`.

### Phase 2: Build the Outline Generator

Create `tom_specs_clitool/bin/generate_outline.dart`:

1. **Analyzer bootstrap** — set up `AnalysisContextCollection` for the package.

USER: check in tom_dart_editor/tom_dart_editor_test how instantiate the analyzer so it doesn't require an installed SDK. I want it to be instantiated this way. Write short tutorial how to do this in tom_spec_clitool/doc/analyzer_wo_sdk.md

1. **Model discovery** — locate the root `ProjectDefinition` class, collect all fields/types reachable from there.
2. **Validation engine** — implement all §6 rules as a validation pass:
   - Iterate all discovered types.
   - Check type constraints (no `List<String>`, no primitive non-String, etc.).
   - Check class style (no constructors, no `final`/`const`).
   - Check `@ContentType` constraints (non-Form ↔ no other scalars).
   - Check `content: String?` presence.
   - Cycle detection via DFS from root.
   - Collect all errors; report all at once; exit non-zero.

USER: double check the document for additional rules again

3. **Tree walker** — recursive visitor starting from `ProjectDefinition`:
   - Classify each field: leaf, enum, complex singular, complex list, reference.
   - Collect leaf fields into comma-separated `->` lines with wrapping.
   - Emit complex singular as `-> TypeName` or `-> fieldName:TypeName` and recurse.
   - Emit complex list as `-: fieldName:TypeName` and recurse.
   - Emit references with `:<reference-path>`.
   - Append `@Comment` annotations aligned to column 50+indent.
   - Append `@Type` hints after field names.
   - Append `@ContentType` hints after `content` field.
4. **Output writer** — write the indented tree to the output text file.
5. **CLI** — accept arguments: `--output` (file path, default is <root-type>_outline.txt), `--max-line-length` (default 120), `--root-type` (default `ProjectDefinition`).

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

For every `@tomReflector` model class (approximately 150+ classes across 15 files):

**Before:**
```dart
@tomReflector
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
@tomReflector
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

**Processing order:** Process files bottom-up in the dependency tree — leaf entry types first (they have no complex children), then container types, then section types, then `ProjectDefinition` last.

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
