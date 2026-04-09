# Specs Model Outliner — Generator Specification

## 1. Purpose

The **Specs Model Outliner** is a Dart-based generator that reads the `tom_specs_model` source files via the Dart analyzer and produces a human-readable *outline document* showing the full object-model tree. The output replaces the previous Mermaid class-diagram documentation with a compact, indented notation that is easier to scan and validate.

## 2. Input

- **Source**: All Dart files under `lib/src/` of the `tom_specs_model` package.
- **Root type**: `ProjectDefinition` (the single top-level aggregator class). The root class name is the key parameter of the generator besides the dart project name it is in. All classes in the dependency tree of the root class are included. For large projects these could even be in other dart projects.
- **Analyzer**: Use `package:analyzer` to resolve types, enumerate fields, and inspect annotations.

## 3. Output

A single Markdown file (e.g., `doc/pd_project_definition_outline.md`) containing the full model tree in the outliner notation described below.

## 4. Notation

### 4.1 Indentation

Each nesting level adds **4 spaces** of indentation.

### 4.2 Singular Complex Fields (`->`)

A field whose type is a single complex object (zero-or-one / exactly-one relationship). Only the **type name** is shown because the field name must match the type name (see §6 naming rule):

```
-> ExistingSystemsLandscape
    -> content, currentArchitecture
    -> DependenciesAndIntegrations
        ...
```

If the field is a `@Reference`, both field name and type name are shown (see §4.9).

### 4.3 List Fields (`-:`)

A field whose type is `List<ComplexType>` (zero-or-many relationship). Both the **field name** and the **type name** are always shown as `fieldName:TypeName`, because the field name (typically plural) differs from the type name (typically singular). The field name is structurally significant — it represents a **section level** in the target document, with each list item as a subsection:

```
-: systems:ExistingSystemEntry
    -> content, systemName, technology, purpose
    -: knownLimitations:LimitationEntry
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

The `content: String?` field is present on nearly every class. It is shown as a regular leaf field (first in the comma list by convention) — **not** hidden or implicit.

### 4.7 Nullable vs Non-Nullable

The outliner does **not** distinguish `String?` from `String` or `Type?` from `Type`. Nullability is an implementation detail not relevant to the document structure.

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

**Comment placement:** The `← (...)` marker starts at column **50** of the line (counting from the beginning including indentation), or immediately after the line content plus one space if the content is longer than 50 characters.

## 5. Type Expansion

### 5.1 Inline Expansion

When a complex type is used, its full subtree is shown **inline at every usage point**. There is no separate "type definitions" section — duplication is intentional so the reader can see the full structure at each location without jumping around.

### 5.2 Cycle Detection

Cycles **must not exist** in the model. If a cycle is detected during tree walking, the generator **fails with a clear error message** naming the types involved in the cycle. There is no soft handling (no `[circular — see above]`).

## 6. Model Design Rules

These are the rules for how model classes must be designed. The generator **validates** all of them and **fails with a clear error message** for any violation. There are no warnings — every violation is a hard error.

### 6.1 Type Constraints

| Rule | Description |
|------|-------------|
| **No `List<String>`** | All list fields must use complex types. `List<String>` or `List<basicType>` is an error. |
| **No primitive non-String scalars** | Leaf fields must be `String`, `String?`, or an enum type. No `int`, `double`, `bool`, `num`, `DateTime`. Dates and numbers are represented as `String?` and annotated with `@Type()`. |
| **`@tomReflector` required** | Only annotated classes/enums are part of the model. Any field referencing a non-annotated type is an error. |
| **`content: String?` expected** | Every model class must have a `content: String?` field. Missing = error. |

### 6.2 Naming Constraints

| Rule | Description |
|------|-------------|
| **Singular field name = type name** | A field of type `MyType` must be named `myType` (camelCase of the type name). Mismatch = error, unless the field has `@Reference`. |
| **List field names are free** | List fields (`List<T>`) are exempt from name matching since the field name is typically a plural or a semantic label for the list's role. |

### 6.3 Class Style

| Rule | Description |
|------|-------------|
| **No constructors** | Classes must not declare constructors. A default constructor is implied. |
| **No `final` or `const`** | Fields are declared without keywords — plain mutable instance fields, like nested records. |
| **Non-nullable defaults** | Non-nullable fields are assigned a valid default value. Nullable fields are left null. |
| **No computed properties** | Only concrete instance fields are part of the model. Getters, static fields, and computed properties are excluded. |

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

Annotations are defined in the `tom_specs_model` package and applied to model classes and fields. The generator reads annotations via the analyzer.

### 7.1 `@Reference(String description, Symbol field)`

Declares that a field is a **reference** to data owned elsewhere in the tree, not an ownership relationship.

- Applied to: singular or list fields.
- Effect: The field is shown with reference notation (see §4.9). The naming rule (§6.2) is relaxed — field name need not match type name.
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

## 8. Output Example

```markdown
# Project Definition Outline

ProjectDefinition
    -> DocumentHeader
        -> content, documentId, project, version, date, author, status
    -> CurrentStateAnalysis
        -> content
        -> ExistingSystemsLandscape
            -> content, currentArchitecture
            -: systems:ExistingSystemEntry
                -> content, systemName, technology, purpose,
                    activeUsers, dataVolume, operationalSince,
                    supportStatus
                -: knownLimitations:LimitationEntry
                    -> content, limitation, impact
            -> DependenciesAndIntegrations
                -> content
                -: dependencies:SystemDependencyEntry
                    -> content, sourceSystem, targetSystem,
                        dependencyType, protocol, dataExchanged,
                        criticality
        -> CurrentBusinessProcesses
            -> content
            -: workflows:CurrentWorkflowEntry
                -> content, processName, trigger, output, cycleTime
                -: steps:WorkflowStepEntry
                    -> content, stepName, description
                -: actors:WorkflowActorEntry
                    -> content, actorName, role
                -: manualSteps:WorkflowStepEntry
                    -> content, stepName, description
                -: errorProneSteps:WorkflowStepEntry
                    -> content, stepName, description
        -> PainPointsAndGaps
            -> content
            -: painPoints:PainPointEntry
                -> content, area, description, impact, currentWorkaround
            -: gaps:GapEntry
                -> content, gapDescription, businessImpact, priority
        -> CurrentDataLandscape
            ...
    -> ProjectOrganizationAndProcess
        ...
    -> Administrative
        ...
    -> SystemOverview
        ...
    ...
```

## 9. Generator Implementation Notes

1. **Entry point**: A Dart CLI tool in `tom_specs_model/tool/generate_outline.dart`.
2. **Analyzer setup**: Use `AnalysisContextCollection` to resolve the package and all its source files.
3. **Annotation reading**: Read `@tomReflector`, `@Reference`, `@SectionId`, `@SectionIdPattern`, `@Comment`, `@Type`, `@ContentType` from the analyzer's element model.
4. **Tree walk**: Start from `ProjectDefinition`, recursively visit each field:
   - If `String` / `String?` → collect as leaf (include `@Type` hint if present).
   - If enum → format with values inline.
   - If `List<T>` → emit `-: fieldName:TypeName` and recurse into `T`.
   - If complex type → emit `-> TypeName` and recurse.
   - If `@Reference` → emit with reference notation.
5. **Validation pass** (before output): Run all rules from §6 — type constraints, naming, class style, content type, cycle detection. Fail on first error with clear message.
6. **Line wrapping**: Track current line length. When a leaf line exceeds the max (default 120), wrap at a comma boundary and indent the continuation one level deeper.
7. **Comment alignment**: Pad `← (...)` annotations to start at column 50, or one space after content if content exceeds 50 chars.

## 10. Implementation Plan

### Phase 1: Define Annotations

Create the annotation classes in `tom_specs_model/lib/src/annotations/`:

1. `reference.dart` — `@Reference(String description, Symbol field)`
2. `section_id.dart` — `@SectionId(String id)`
3. `section_id_pattern.dart` — `@SectionIdPattern(String pattern)`
4. `comment.dart` — `@Comment(String text)`
5. `type_hint.dart` — `@Type(String type)`
6. `content_type.dart` — `@ContentType(String type)`
7. Barrel export from `annotations.dart`.

### Phase 2: Build the Outline Generator

Create `tom_specs_model/tool/generate_outline.dart`:

1. **Analyzer bootstrap** — set up `AnalysisContextCollection` for the package.
2. **Model discovery** — find all `@tomReflector` classes and enums; locate the root `ProjectDefinition` class.
3. **Validation engine** — implement all §6 rules as a validation pass:
   - Iterate all discovered types.
   - Check type constraints (no `List<String>`, no primitive non-String, etc.).
   - Check naming constraints (singular field name = camelCase of type name, unless `@Reference`).
   - Check class style (no constructors, no `final`/`const`).
   - Check `@ContentType` constraints (non-Form ↔ no other scalars).
   - Check `content: String?` presence.
   - Cycle detection via DFS from root.
   - Collect all errors; report all at once; exit non-zero.
4. **Tree walker** — recursive visitor starting from `ProjectDefinition`:
   - Classify each field: leaf, enum, complex singular, complex list, reference.
   - Collect leaf fields into comma-separated `->` lines with wrapping.
   - Emit complex singular as `-> TypeName` and recurse.
   - Emit complex list as `-: fieldName:TypeName` and recurse.
   - Emit references with `:<reference-path>`.
   - Append `@Comment` annotations aligned to column 50.
   - Append `@Type` hints after field names.
   - Append `@ContentType` hints after `content` field.
5. **Output writer** — write the indented tree to the output Markdown file.
6. **CLI** — accept arguments: `--output` (file path), `--max-line-length` (default 120), `--root-type` (default `ProjectDefinition`).

### Phase 3: Integration

1. Add a `tool/` entry in the package for running the generator.
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
