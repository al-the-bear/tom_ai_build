# Specs Model Outliner — Generator Specification

## 1. Purpose

The **Specs Model Outliner** is a Dart-based generator that reads the `tom_specs_model` source files via the Dart analyzer and produces a human-readable *outline document* showing the full object-model tree. The output replaces the previous Mermaid class-diagram documentation with a compact, indented notation that is easier to scan and validate.

## 2. Input

- **Source**: All Dart files under `lib/src/` of the `tom_specs_model` package.
- **Marker**: Only classes and enums annotated with `@tomReflector` are included.
- **Root type**: `ProjectDefinition` (the single top-level aggregator class).
- **Analyzer**: Use `package:analyzer` to resolve types, enumerate fields, and inspect annotations.

## 3. Output

A single Markdown file (e.g., `doc/pd_project_definition_outline.md`) containing the full model tree in the outliner notation described below.

## 4. Notation

### 4.1 Indentation

Each nesting level adds **4 spaces** of indentation.

### 4.2 Singular Fields (`->`)

A field whose type is a single complex object (zero-or-one / exactly-one relationship):

```
-> TypeName
    -> childField1, childField2
    -> NestedType
        ...
```

### 4.3 List Fields (`-:`)

A field whose type is `List<ComplexType>` (zero-or-many relationship):

```
-: TypeName
    -> field1, field2, field3
    -> NestedType
        ...
```

### 4.4 Leaf Fields

All scalar fields (`String?`, `String`, enum classes) are collected on a **single line**, comma-separated, prefixed with `->`:

```
-> content, systemName, technology, purpose
```

### 4.5 Enum Fields

Enums are shown inline with their values:

```
-> Priority (must, should, could, wontThisTime)
```

If an enum field is among other leaf fields on the same line, it appears in-place:

```
-> content, priority: Priority (must, should, could, wontThisTime), status
```

### 4.6 Content Field

The `content: String?` field is present on nearly every class. It is shown as a regular leaf field (first in the comma list by convention) — **not** hidden or implicit.

### 4.7 Nullable vs Non-Nullable

The outliner does **not** distinguish `String?` from `String` or `Type?` from `Type`. Nullability is an implementation detail not relevant to the document structure.

### 4.8 Field Ordering

Fields are listed in **declaration order** as they appear in the source class.

## 5. Type Expansion

### 5.1 Inline Expansion

When a complex type is used, its full subtree is shown **inline at every usage point**. There is no separate "type definitions" section — duplication is intentional so the reader can see the full structure at each location without jumping around.

### 5.2 Cross-References

In the rare case where a field refers to an instance defined elsewhere in the tree (i.e., the field's type name does **not** match the field name's expected type), it is shown as a **cross-reference** using path notation:

```
-> basedOnRequirement: ProjectDefinition-SystemOverview-RequirementsOverview:functionalRequirements
```

**Path-Separator Notation:**
- `-` for 1:1 and 1:0? relationships.
- `:` for 1:n (List<...>) relationships

**Heuristic for detection:** A cross-reference is identified when a field has a complex type but the field name does not semantically correspond to the type (e.g., `basedOnRequirement: FunctionalRequirementEntry` — the field name suggests a reference, not ownership).

> **Note:** The current model has no cross-references. This notation is defined for future use.

## 6. Type Rules (Model Constraints)

These rules define constraints that the **generator should validate** and report violations for:

| Rule | Description |
|------|-------------|
| **No `List<String>`** | All list fields must use complex types. `List<String>` or `List<basicType>` is an error. |
| **No primitive non-String scalars** | Leaf fields must be `String`, `String?`, or an enum type. No `int`, `double`, `bool`, `num`, `DateTime`. Dates and numbers are represented as `String`. |
| **`@tomReflector` required** | Only annotated classes/enums are part of the model. Any field referencing a non-annotated type is an error. |
| **`content: String?` expected** | Every model class should have a `content: String?` field. The generator should warn (not error) if missing. |
| ** Variablename matches Typename for complext types, unless reference ** | a field of type `Type` must be name `type`, unless this variable is meant to reference data of the type defined somewhere else in the object model |

## 7. Output Example

```markdown
# Project Definition Outline

ProjectDefinition
    -> content
    -> DocumentHeader
        -> content, documentId, project, version, date, author, status
    -> CurrentStateAnalysis
        -> content
        -> ExistingSystemsLandscape
            -> content, currentArchitecture
            -: ExistingSystemEntry
                -> content, systemName, technology, purpose, activeUsers, dataVolume, operationalSince, supportStatus
                -: LimitationEntry
                    -> content, limitation, impact
            -> DependenciesAndIntegrations
                -> content
                -: SystemDependencyEntry
                    -> content, sourceSystem, targetSystem, dependencyType, protocol, dataExchanged, criticality
        -> CurrentBusinessProcesses
            -> content
            -: CurrentWorkflowEntry
                -> content, processName, trigger, output, cycleTime
                -: WorkflowStepEntry
                    -> content, stepName, description
                -: WorkflowActorEntry
                    -> content, actorName, role
                -: WorkflowStepEntry              ← (manualSteps — same type reused)
                    -> content, stepName, description
                -: WorkflowStepEntry              ← (errorProneSteps — same type reused)
                    -> content, stepName, description
            -> ProcessMetrics
                -> content
                -: ProcessMetricEntry
                    -> content, metricName, processReference, currentValue, unit, measurementMethod, frequency
    ...
```

## 8. Generator Implementation Notes

1. **Entry point**: A Dart CLI tool in `tom_specs_model/tool/` or a build step.
2. **Analyzer setup**: Use `AnalysisContextCollection` to resolve the package.
3. **Tree walk**: Start from `ProjectDefinition`, recursively visit each field:
   - If `String` / `String?` → collect as leaf.
   - If enum → format with values.
   - If `List<T>` → emit `-:` with `T`'s subtree.
   - If complex type → emit `->` with type's subtree.
4. **Comment annotation**: After the type name on `-:` lines, optionally show the field name in a comment when the field name differs from the type name: `-: WorkflowStepEntry  ← (manualSteps)`.
5. **Cycle detection**: Maintain a visited-path stack. If a type appears in its own ancestry, emit `-> TypeName [circular — see above]` to prevent infinite recursion.

## 9. Open Questions / Clarifications / Ambiguities

### 9.1 Field-Name Annotation on Reused Types

When the same type is used for multiple fields in one class (e.g., `manualSteps: List<WorkflowStepEntry>` and `errorProneSteps: List<WorkflowStepEntry>`), the **field name** is lost in the outline since only the type is shown. Should we:
- **(a)** Always annotate with the field name as a trailing comment: `-: WorkflowStepEntry  ← (manualSteps)`?
- **(b)** Only annotate when the field name differs from the type name?
- **(c)** Show as `manualSteps -: WorkflowStepEntry`?

**Current assumption:** Option (a) — always show field name as comment when it adds clarity.

### 9.2 Top-Level Field Name vs Type Name

For singular complex fields, the outline shows the **type name** (e.g., `-> ExistingSystemsLandscape`). But the field name might differ (e.g., `existingSystemsLandscape`). Should the field name be shown when it diverges from the type? For example:

```
-> authentication: IdentificationAndAuthentication    ← field name ≠ type name
    ...
```

**Current assumption:** Show both when they differ.

### 9.3 Common Base Types (Requirement, Risk)

`Requirement` and `Risk` in `common/` are not currently used by any PD section class but are exported from the package. Should the outliner:
- **(a)** Only show what's reachable from the root type?
- **(b)** Append unreachable common types in a separate section?

**Current assumption:** Option (a) — only show the reachable tree. Unreachable types can be listed in a footer section for reference.

### 9.4 The `final` Keyword and Constructors

The generator reads **field declarations**, not constructor parameters. If a class uses getters or computed properties, should those be included?

**Current assumption:** Only concrete `final` instance fields. Computed properties and static fields are excluded.

### 9.5 Enum Fields Among Leaf Fields

When a class has both String and enum fields, they all appear on one leaf line. Should enum values always be shown inline, or only shown once (first occurrence) with subsequent uses just showing the enum name?

**Current assumption:** Show enum values inline at every occurrence — keeps the outline self-contained.

### 9.6 Classes Not Extending or Mixing In

The current model uses composition only (no inheritance between model classes). If inheritance is introduced later, should inherited fields be shown at the subclass level or suppressed?

**Current assumption:** Show all fields including inherited ones, since the outline represents the full document structure.

### 9.7 Multi-Line Leaf Threshold

Some classes may have 15+ leaf fields. Should there be a line-length limit that splits leaf fields across multiple `->` lines?

**Current assumption:** No limit. All leaf fields on one line. Readability at extreme widths is acceptable for a generated reference document.
