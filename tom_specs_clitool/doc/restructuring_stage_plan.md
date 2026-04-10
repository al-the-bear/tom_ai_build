# Model Restructuring Stage Plan

Plan for restructuring `tom_specs_model` (pd_project_definition) to use typed
section classes, `@Form` field annotations, and consistent section IDs.

**Scope:** 300 classes, ~715 scalar `String?` fields, ~146 form-type classes,
15 source files.

**Packages affected:**
- `tom_specs_core` — new section types, `@Form`/`Field` annotation, updated
  `@ContentType`
- `tom_specs_model` — all pd_project_definition files restructured
- `tom_specs_clitool` — outliner updated to handle new types and `@Form`

---

## Stage 1: Section Base Types in `tom_specs_core`

**Goal:** Introduce typed section classes and the `@Form` annotation so that
the model restructuring in stages 2–3 has a stable foundation.

### 1.1 Section base types

Add to `tom_specs_core/lib/src/sections/`:

| Class | Content type | Purpose |
|-------|-------------|---------|
| `TextSection` | `text` | Any free-text content, may include inline diagrams or references |
| `DiagramSection` | `mermaid` | A single Mermaid diagram |
| `ErDiagramSection` | `mermaid-er` | ER diagram (Mermaid subtype) |
| `FlowDiagramSection` | `mermaid-flow` | Flow chart (Mermaid subtype) |
| `SequenceDiagramSection` | `mermaid-sequence` | Sequence diagram (Mermaid subtype) |
| `GanttDiagramSection` | `mermaid-gantt` | Gantt chart (Mermaid subtype) |
| `CodeSection` | `code` | A single code block (language-agnostic) |
| `DdlCodeSection` | `code-ddl` | DDL code block |
| `SqlCodeSection` | `code-sql` | SQL code block |
| `DartCodeSection` | `code-dart` | Dart code block |

Each class has a single `String? content` field. The type is baked in via an
immutable `@ContentType` annotation on the class (not the field), so the
outliner and validators can resolve it statically.

```dart
/// A free-text section that may contain narrative, diagrams, or references.
@ContentType('text')
class TextSection {
  String? content;
}

/// A Mermaid ER diagram section.
@ContentType('mermaid-er')
class ErDiagramSection {
  String? content;
}
```

Diagram subtypes extend `DiagramSection`; code subtypes extend `CodeSection`.
This gives the outliner a simple `is DiagramSection` / `is CodeSection` check.

### 1.2 `@Form` and `Field` annotation

Add to `tom_specs_core/lib/src/annotations/`:

```dart
/// Declares the form fields for a section whose content is structured as
/// name-value pairs (one per line).
///
/// Applied to the `content` field of form section classes. Each [Field]
/// declares a named form value with its Dart type and a human-readable
/// description.
class Form {
  final List<Field> fields;
  const Form(this.fields);
}

/// A single form field declaration.
class Field {
  /// Field name as it appears in the document (camelCase → display name
  /// conversion is done by tooling).
  final String name;

  /// Dart type of the value. Use `String` for free text, `int`/`double` for
  /// numbers, an enum type for constrained choices.
  final Type type;

  /// Short description shown in outlines and documentation.
  final String description;

  /// Whether this field is required (non-empty).
  final bool required;

  const Field(this.name, this.type, this.description, {this.required = false});
}
```

### 1.3 Export and publish

- Export new sections and annotations from `tom_specs_core.dart`
- Add `tom_specs_core` as a dependency in `tom_specs_model` (if not already)
- Publish `tom_specs_core` (or use path dependency during development)

### 1.4 Deliverables

- [ ] Section base types in `tom_specs_core`
- [ ] `@Form` / `Field` annotation in `tom_specs_core`
- [ ] All exports updated
- [ ] `dart analyze` passes on `tom_specs_core`
- [ ] `dart test` passes on `tom_specs_core` (if tests exist)

---

## Stage 2: Model Restructuring — Comment Cleanup + Section Types

**Goal:** Fix all structural inconsistencies in the model: missing section IDs,
orphan `String?` diagram fields replaced with typed sections, and consistent
comment conventions.

### 2.1 Comment standardization rules

Apply these rules uniformly to every class and field:

**Section classes (containers):**
```dart
/// N.M. Section Title [PD00-XXX-YYY].
class SectionName {
```
- Every section class MUST have a section ID in brackets
- Numbering must match the hierarchy

**Entry/form classes (list items):**
```dart
/// A descriptive name [PD00-XXX-YYY-nn] (form).
class EntryName {
```
- ID pattern uses `-nn` suffix (tooling converts to `-xx`)
- Content type in parentheses: `(form)`, `(description)`, `(text)`

**List fields with items:**
```dart
/// N.M.K. Section Title [PD00-XXX-YYY] — contains 1+× Item Name.
List<ItemType> items = [];
```
- Cardinality MUST be stated: `contains 1+×` or `contains 0+×`

### 2.2 Replace diagram `String?` fields with typed sections

**8 fields to change:**

| Current field | Parent class | Replacement |
|---------------|-------------|-------------|
| `String? erDiagram` | `DataModel` | `List<ErDiagramSection> erDiagrams = []` or custom `EntityDiagram` |
| `String? objectDiagram` | `BusinessObjectModel` | `List<DiagramSection> objectDiagrams = []` or similar |
| `String? processOverviewDiagram` | `TargetBusinessProcessModel` | `FlowDiagramSection processOverviewDiagram = FlowDiagramSection()` |
| `String? timelineDiagram` | `StageOverview` | `GanttDiagramSection timelineDiagram = GanttDiagramSection()` |
| `String? screenFlowDiagram` | `ScreenFlowStructure` | `FlowDiagramSection screenFlowDiagram = FlowDiagramSection()` |
| `String? orgChartDiagram` | `OrganizationStructure` | `DiagramSection orgChartDiagram = DiagramSection()` |
| `String? overviewDiagram` | `ChangeProcess` | `FlowDiagramSection overviewDiagram = FlowDiagramSection()` |
| `String? subflowDiagram` | `ChangeStepEntry` | `FlowDiagramSection? subflowDiagram` |

For diagrams where explanation is needed alongside (like ER diagrams), use a
wrapper class:

```dart
/// An entity-relationship diagram with explanation.
class EntityDiagram {
  /// Preamble text introducing the diagram.
  String? content;
  /// The ER diagram.
  ErDiagramSection erDiagram = ErDiagramSection();
  /// Detailed explanation of the diagram.
  TextSection diagramExplanation = TextSection();
}
```

Decision per diagram: single diagram → use typed section directly. Diagram
needing explanation → use wrapper class with section ID.

### 2.3 Assign section IDs to all classes

**~130 entry/form classes are missing IDs.** For each:

1. Determine parent section ID (e.g., parent is `[PD00-BUS-DAT-ENT]`)
2. Assign a 3-letter code to the sub-entry (e.g., `ATT` for attributes)
3. Add `-nn` pattern: `[PD00-BUS-DAT-ENT-nn-ATT-nn]`

Example for the DataEntityEntry subtree:
```
DataEntityEntry         [PD00-BUS-DAT-ENT-nn]          ← already has ID
  DataAttributeEntry    [PD00-BUS-DAT-ENT-nn-ATT-nn]   ← needs ID
  KeyAttributeEntry     [PD00-BUS-DAT-ENT-nn-KEY-nn]   ← needs ID
```

**Where sub-entries are deeply nested (4+ levels), flatten IDs sensibly.**
We should assign all IDs in a single pass across all files so the ID namespace
is consistent.

### 2.4 Add cardinality to all list fields

**~100+ list fields are missing `contains N+×` comments.** Add:
- `contains 1+×` for required lists (business-critical, at least one needed)
- `contains 0+×` for optional lists

### 2.5 Classify `String?` field semantics

Categorize every non-content `String?` field (~715 total) into:

| Category | Description | This will become... in Stage 3 |
|----------|-------------|-------------------------------|
| **Form value** | One-line value: name, ID, category, status, priority, format, version, type, role, frequency, probability | `@Form` field |
| **Short text** | description, rationale, purpose — typically 1–3 sentences | `@Form` field (with `type: String`) |
| **Long text** | Detailed narrative, explanation, overview, summary, requirements, details, policy | `TextSection` child |
| **Reference** | Typed pointer to a section defined elsewhere in the model tree | `@Reference` typed field (see below) |

**References** are NOT form fields and NOT strings. A reference is a typed Dart
field pointing to the actual section class, annotated with `@Reference`:

```dart
@Reference('Process this interaction belongs to')
TargetBusinessProcess? processReference;

@Reference('Related use case')
ScenarioEntry? relatedUseCase;

@Reference('Source entity in the relationship')
DataEntityEntry? sourceEntity;
```

References are real Dart fields with the target section's type. The outliner and
structure generator **do not follow** references (no recursion into the
referenced tree). The schema generator treats them as cross-reference
validations, verifying the referenced section exists.

Current `String?` fields that are references (field names containing
`*Reference`, `*related*`, `source*`, `target*` where they point to another
entity) will be converted to typed `@Reference` fields in Stage 3.

This classification happens now (in comments or a tracking document) but the
actual migration happens in Stage 3.

For this pass, scan the ~61 `description` fields and decide case-by-case
whether each is a form value (short) or a text section (long).

**Rule of thumb:** If a `description` field is in an entry/form class alongside
other short fields (name, category, etc.), it's a form field. If it's the main
body of a section, it should be a `TextSection`.

### 2.6 Deliverables

- [ ] Every class has a section ID or section ID pattern in its comment
- [ ] Every list field has `contains N+×` cardinality
- [ ] All 8 diagram fields replaced with typed section instances
- [ ] All comments follow the standardized format
- [ ] Field classification document/annotations marking form vs. text vs.
      reference for every `String?` field
- [ ] `dart analyze` passes
- [ ] Outline regenerated and reviewed

---

## Stage 3: `@Form` Migration — Replace Scalar Fields with Annotations

**Goal:** Convert form entry classes from explicit `String?` fields to
`@Form([Field(...)])` annotations on the `content` field. Move long-text fields
to `TextSection` children.

### 3.1 Form entry conversion pattern

**Before:**
```dart
/// A data attribute entry [PD00-BUS-DAT-ENT-nn-ATT-nn] (form).
class DataAttributeEntry {
  String? content;
  String? attributeName;
  String? dataType;
  String? length;
  String? format;
  String? mandatory;
  String? description;
}
```

**After:**
```dart
/// A data attribute entry [PD00-BUS-DAT-ENT-nn-ATT-nn] (form).
class DataAttributeEntry {
  @Form([
    Field('attributeName', String, 'Name of the attribute'),
    Field('dataType', String, 'Data type (e.g., VARCHAR, INTEGER)'),
    Field('length', int, 'Maximum length or precision'),
    Field('format', String, 'Display or storage format'),
    Field('mandatory', String, 'Whether the attribute is required'),
    Field('description', String, 'Short description of the attribute'),
  ])
  String? content;
}
```

**For entries with mixed form values + long text sections:**
```dart
/// A data entity entry [PD00-BUS-DAT-ENT-nn] (form).
class DataEntityEntry {
  @Form([
    Field('entityName', String, 'Name of the data entity', required: true),
    Field('category', String, 'Entity category'),
    Field('estimatedRecordCount', int, 'Estimated number of records'),
    Field('growthRate', String, 'Expected growth rate'),
  ])
  String? content;

  /// N.M.K. Description [PD00-BUS-DAT-ENT-nn-DES].
  TextSection description = TextSection();

  /// N.M.K. Retention Policy [PD00-BUS-DAT-ENT-nn-RET].
  TextSection retentionPolicyDetails = TextSection();

  /// N.M.K. Attributes [PD00-BUS-DAT-ENT-nn-ATT] — contains 0+× Data Attribute.
  List<DataAttributeEntry> attributes = [];

  /// N.M.K. Key Attributes [PD00-BUS-DAT-ENT-nn-KEY] — contains 0+× Key Attribute.
  List<KeyAttributeEntry> keyAttributes = [];
}
```

### 3.2 Decision criteria for each field

For each `String?` field in a form class, decide:

| If... | Then... |
|-------|---------|
| Field is a short value (≤ 1 line): name, id, category, status, format, version, type, role | Move to `@Form` as `Field('name', String, 'desc')` |
| Field is a short number: count, rate, score, fteCount | Move to `@Form` as `Field('name', int, 'desc')` or `Field('name', double, 'desc')` |
| Field is a constrained choice | Move to `@Form` as `Field('name', SomeEnum, 'desc')` — define enum |
| Field is a short description (1–3 sentences) in a form class | Move to `@Form` as `Field('description', String, 'desc')` |
| Field is a long narrative (multi-paragraph) | Replace with `TextSection description = TextSection()` |
| Field is a diagram | Already replaced in Stage 2 |
| Field is a reference to another section | Replace with `@Reference('desc') TargetType? fieldName` — typed pointer, not followed by outline/structure generators, validated by schema generator |

**Reference fields** are typed Dart fields pointing to the referenced section
class. They are NOT form values and NOT strings. Examples:

```dart
@Reference('Process this interaction belongs to')
TargetBusinessProcess? processReference;

@Reference('Source entity in this relationship')
DataEntityEntry? sourceEntity;

@Reference('Target entity in this relationship')
DataEntityEntry? targetEntity;
```

The outliner renders references with a special marker (e.g., `→TargetType`)
and does NOT recurse into the referenced class tree. The schema generator
uses them for cross-reference validation.

### 3.3 Processing order

Process one file at a time, in dependency order (leaf files first):

1. `current_state_analysis.dart` — 9 form classes
2. `project_organization_process.dart` — 5 form classes
3. `administrative.dart` — 4 form classes
4. `organizational_framework.dart` — 6 form classes
5. `business_data_model.dart` — 12 form classes
6. `target_business_process.dart` — 7 form classes
7. `system_overview.dart` — 8+ form classes
8. `access_authorization.dart` — 10 form classes
9. `technical_framework.dart` — 6 form classes
10. `user_interface_design.dart` — 14 form classes
11. `system_quality_goals.dart` — 4 form classes
12. `components.dart` — 5 form classes
13. `system_stage_plan.dart` — 8 form classes
14. `delivery_acceptance.dart` — 4 form classes
15. `pd_project_definition.dart` — root (no form classes, just wiring)

**Per-file workflow:**
1. Read file, identify all form classes
2. For each class, classify fields (form value / text section / reference)
3. Convert to `@Form` annotation + `TextSection` children
4. Assign section IDs to new `TextSection` children
5. Run `dart analyze`
6. Regenerate outline and verify

### 3.4 Estimated scope

| Metric | Count |
|--------|-------|
| Form classes to convert | ~146 |
| `String?` fields to reclassify | ~715 |
| Fields → `@Form` entries | ~600 (estimated) |
| Fields → `TextSection` children | ~100 (estimated) |
| New section IDs to assign | ~100 (for new TextSection children) |
| Enums to potentially introduce | ~10–20 (for constrained choices) |

### 3.5 Deliverables

- [ ] All ~146 form classes converted to `@Form` pattern
- [ ] Long-text fields extracted to `TextSection` children
- [ ] New enums for constrained choices (where appropriate)
- [ ] `dart analyze` passes
- [ ] Outline regenerated — should show `@Form` fields inline

---

## Stage 4: Outliner Adaptation

**Goal:** Update the outliner to understand and render the new model structure.

### 4.1 Changes needed

**model_reader.dart** (~353 lines):

- Recognize `@Form` annotation on `content` fields
- Extract `Field(...)` entries from `@Form` and expose them as virtual leaf
  fields on the `ModelField` / `ModelClass`
- Recognize section base types (`TextSection`, `DiagramSection`, etc.)
  and mark them appropriately

**outline_writer.dart** (~383 lines):

- When a class has `@Form` on its `content` field, render the form fields as
  the leaf line: `-> content @Form(attributeName, dataType, length, ...)`
  or expand them like regular fields (design decision)
- When a field is a `TextSection`, render it with a `@text` marker
- When a field is a `DiagramSection` subtype, render with `@mermaid-er` etc.
- Existing leaf/complex field logic stays the same

### 4.2 Estimated effort

The outliner is small (736 lines total) and well-structured. The changes are:
1. Add `@Form` field extraction (~30 lines in model_reader)
2. Add section type detection (~20 lines in model_reader)
3. Modify leaf field rendering for `@Form` display (~20 lines in outline_writer)
4. Add type markers for section types (~10 lines in outline_writer)

**This can be done incrementally** — Stage 2 changes (diagrams, IDs) don't
require outliner changes. Stage 3 (`@Form`) requires the outliner update, but
only for rendering — the outliner already reads annotations.

### 4.3 Deliverables

- [ ] `model_reader.dart` updated for `@Form` and section types
- [ ] `outline_writer.dart` updated for new rendering
- [ ] Outline regenerated with final model and verified
- [ ] `dart analyze` passes

---

## Stage Sequencing and Dependencies

```
Stage 1 ─── Stage 2 ─── Stage 3 ─── Stage 4
  core       model        model       outliner
  types      cleanup      @Form       adapt
```

- **Stage 1** can be done independently (core only)
- **Stage 2** depends on Stage 1 (needs section types)
- **Stage 3** depends on Stage 1 (needs `@Form` annotation) and Stage 2
  (needs clean IDs and field classifications)
- **Stage 4** can start after Stage 1 (for section type support) and must be
  done by end of Stage 3 (for `@Form` rendering)

**Recommended interleaving:**
- Stage 1 → Stage 2 → Stage 4 (section types in outliner) → Stage 3 +
  Stage 4 (form rendering in outliner)

This lets us verify the outline after Stage 2 with the existing scalar-field
model, then switch to `@Form` in Stage 3 with the outliner already prepared.

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| ~146 form classes × manual conversion | High effort | Process file-by-file, verify after each |
| Section ID assignment conflicts | Medium | Assign all IDs in a single pass (Stage 2.3) with namespace doc |
| `@Form` annotation const limitations | Low | `Field` uses `Type` which works in Dart const constructors |
| Field classification ambiguity (short text vs. long text) | Medium | Document decision per field in Stage 2.5 |
| Outliner regression | Low | Existing outline serves as baseline for diff |
