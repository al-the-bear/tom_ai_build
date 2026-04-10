# Comment → Annotation Mapping Rules

Rules for automatically deriving `tom_specs_core` annotations from doc-comment
conventions used in the `pd_project_definition` model code.

---

## 1. `@SectionId` — from `[PD00-XXX]` in class comment

**Pattern:** Class doc-comment contains `[PD00-XXX-YYY]`.

```dart
/// 4.1. System Description [PD00-SYO-SYD].
class SystemDescription { … }
```

**Rule:** Extract the bracket-enclosed ID → `@SectionId('PD00-SYO-SYD')`.

**Applies to:** Section classes (non-entry, non-form classes).

**Exclusion:** Entry classes with `-nn` in the ID get `@SectionIdPattern` on the
parent list field instead (see rule 2).

---

## 2. `@SectionIdPattern` — from `[PD00-XXX-nn]` in entry-class comment

**Pattern:** Entry-class doc-comment contains an ID with `-nn` suffix.

```dart
/// A team member entry [PD00-ADM-TEA-nn] (form).
class TeamMemberEntry { … }
```

**Rule:** Place `@SectionIdPattern('PD00-ADM-TEA-xx')` on the **parent list
field** that holds these entries (replace `-nn` with `-xx`).

```dart
/// 3.2. Project Team Staffing [PD00-ADM-TEA] — contains 1+× Team Member.
@SectionIdPattern('PD00-ADM-TEA-xx')
List<TeamMemberEntry> members = [];
```

**Note:** The entry class itself does NOT get `@SectionId`; the pattern lives on
the list field.

---

## 3. `@Min` / `@Max` — from `contains N+×` in field or class comment

**Pattern:** Comment says `contains 1+× Something` or `contains 0+× Something`.

```dart
/// 3.2. Project Team Staffing [PD00-ADM-TEA] — contains 1+× Team Member.
List<TeamMemberEntry> members = [];
```

**Rules:**

| Comment pattern   | Annotation     |
|-------------------|----------------|
| `contains 1+×`   | `@Min(1)`      |
| `contains 0+×`   | *(no @Min)*    |
| `contains N+×`   | `@Min(N)`      |

`@Max` is applied only when explicitly stated (none found in current model).

---

## 4. Content Type — from `(form)`, `(text)`, `(mermaid)` in comment

**Pattern:** Parenthetical suffix at end of class or field doc-comment.

Content type is now expressed through **section base types** defined in
`tom_specs_core`, not through direct `@ContentType` annotations. Each section
base type has `@ContentType` baked in at the class level. The comment suffix
determines which section type to use.

### 4.1 Section base type mapping

| Comment suffix       | Field type                   | Baked-in `@ContentType`  |
|----------------------|------------------------------|--------------------------|
| `(text)`, `(description)` | `TextSection`           | `text`                   |
| `(mermaid)`          | `DiagramSection`             | `mermaid`                |
| `(mermaid-er)`       | `ErDiagramSection`           | `mermaid-er`             |
| `(mermaid-flow)`     | `FlowDiagramSection`         | `mermaid-flow`           |
| `(mermaid-sequence)` | `SequenceDiagramSection`     | `mermaid-sequence`       |
| `(mermaid-gantt)`    | `GanttDiagramSection`        | `mermaid-gantt`          |
| `(code)`             | `CodeSection`                | `code`                   |
| `(code-dart)`        | `DartCodeSection`            | `code-dart`              |
| `(code-sql)`         | `SqlCodeSection`             | `code-sql`               |
| `(code-ddl)`         | `DdlCodeSection`             | `code-ddl`               |
| `(form)`             | *(no type change — see §4a)* | `Form` (default)         |

### 4.2 Long-text fields → `TextSection`

Fields that were `String?` with long narrative content (multi-paragraph
descriptions, explanations, overviews) become typed `TextSection` children:

```dart
// Before:
String? detailedDescription;

// After:
/// N.M.K. Detailed Description [PD00-XXX-DES].
TextSection detailedDescription = TextSection();
```

### 4.3 Diagram fields → typed diagram sections

Fields that were `String?` with `(mermaid)` or diagram-related names become
typed diagram section instances:

```dart
// Before:
/// 7.1.3. ER Diagram [PD00-BUS-DAT-DIA] (mermaid).
String? erDiagram;

// After:
/// 7.1.3. ER Diagram [PD00-BUS-DAT-DIA].
ErDiagramSection erDiagram = ErDiagramSection();
```

Diagram subtypes extend `DiagramSection`; code subtypes extend `CodeSection`.

### 4.4 Form variant suffixes

Additional qualifiers on `(form)` map to `@Comment`:

| Variant                      | Additional annotation            |
|------------------------------|----------------------------------|
| `(form, singular)`           | `@Comment('singular')`           |
| `(form, repeatable)`         | `@Comment('repeatable')`         |
| `(form, per user category)`  | `@Comment('per user category')`  |

---

## 4a. `@Form` / `Field` — from form classes with scalar fields

**Pattern:** Entry/form classes that have multiple scalar `String?` fields
representing one-line values (names, IDs, categories, statuses, etc.).

All scalar form fields are collected into a single `@Form([Field(...)])`
annotation on the `content` field. The individual `String?` fields are removed.

### Before (explicit fields):
```dart
/// A data attribute entry [PD00-BUS-DAT-ENT-nn-ATT-nn] (form).
class DataAttributeEntry {
  String? content;
  String? attributeName;
  String? dataType;
  String? length;
  String? mandatory;
  String? description;
}
```

### After (`@Form` annotation):
```dart
/// A data attribute entry [PD00-BUS-DAT-ENT-nn-ATT-nn] (form).
class DataAttributeEntry {
  @Form([
    Field('attributeName', String, 'Name of the attribute'),
    Field('dataType', String, 'Data type (e.g., VARCHAR, INTEGER)'),
    Field('length', int, 'Maximum length or precision'),
    Field('mandatory', String, 'Whether the attribute is required'),
    Field('description', String, 'Short description of the attribute'),
  ])
  String? content;
}
```

### Rules:

| Original field type | `Field` type parameter | Example |
|---------------------|------------------------|---------|
| Short text (name, category, status) | `String` | `Field('name', String, 'desc')` |
| Count / number | `int` | `Field('count', int, 'desc')` |
| Rate / allocation | `double` | `Field('rate', double, 'desc')` |
| Constrained choice | enum type | `Field('priority', Priority, 'desc')` |
| Short description (1–3 sentences) | `String` | `Field('description', String, 'desc')` |

### Mixed form + text section classes:

When a class has both short form fields AND long-text children, the short
fields go into `@Form` while the long text becomes `TextSection` children:

```dart
class DataEntityEntry {
  @Form([
    Field('entityName', String, 'Name of the data entity', required: true),
    Field('category', String, 'Entity category'),
    Field('estimatedRecordCount', int, 'Estimated number of records'),
  ])
  String? content;

  /// Description.
  TextSection description = TextSection();

  /// Attributes — contains 0+× Data Attribute.
  List<DataAttributeEntry> attributes = [];
}
```

### Outline rendering:

The outliner shows `@Form` fields inline:
```
-> content @Form(attributeName, dataType, length, mandatory, description)
```

---

## 5. `@Comment` — from `Seeds → XX` cross-references

**Pattern:** Comment ends with `Seeds → XX` (or `Seeds → XX, YY`).

```dart
/// 6. Target Business Process Model [PD00-TAR]. Seeds → BP, UC.
class TargetBusinessProcessModel { … }

/// 4.3. Requirements Overview [PD00-SYO-REQ]. Seeds → RC.
class RequirementsOverview { … }
```

**Rule:** `@Comment('Seeds → BP, UC')` on the class.

This is informational metadata for downstream document generators; it cannot be
expressed by a more specific annotation.

---

## 6. `@Prefix` — from section ID structure

**Pattern:** Classes whose section IDs form a common prefix for their child
sections.

```dart
/// 9.1. User Management [PD00-ACC-USE].
class UserManagement { … }
  // children: PD00-ACC-USE-CAT, PD00-ACC-USE-LIF, PD00-ACC-USE-ATT
```

**Rule:** `@Prefix('PD00-ACC-USE')` — enables two-stage ID resolution where the
heading prefix determines the section type.

**Applies to:** Section classes (not entry classes). Derived from the `@SectionId`
value when the class has child sections.

---

## 7. `@Position` — from section numbering order

**Pattern:** Hierarchical section numbering implies a fixed ordering.

```dart
/// 4.1. System Description [PD00-SYO-SYD].
SystemDescription systemDescription = SystemDescription();

/// 4.2. Goals [PD00-SYO-GOA].
Goals goals = Goals();
```

**Rule:** Fields within a class are ordered by their section numbers. Since the
default Position behaviour is declaration-order, `@Position` annotations are only
needed when a field breaks declaration order (not observed in this model) or when
a field should be explicitly `'first'` or `'last'`.

**Practical rule:** No explicit `@Position` needed when declaration order already
matches the section number order.

---

## 8. `@TextRequired` — from section nature

**Pattern:** Section classes that represent text-heavy content sections where
empty content makes no sense.

```dart
/// 4.1.1. System Purpose [PD00-SYO-SYD-PUR].
String? systemPurpose;
```

**Rule:** Apply `@TextRequired()` to classes where the content is the primary
deliverable (description sections, narrative sections). Do NOT apply to
structural sections that exist only to contain subsections.

**Heuristic:** If a class has only `content` and list fields but no other scalar
fields, and the comment says `(description)`, it needs `@TextRequired`.

---

## 9. Field Types — from field semantics in name or comment

**Pattern:** Field names or comments that imply a non-string type.

Since the restructuring, most scalar fields have moved into `@Form([Field(...)])`
annotations (see Rule 4a). The type is now expressed as the `Field` type
parameter rather than a standalone `@FieldType` annotation:

```dart
// Before (standalone @FieldType on String? fields):
String? estimatedRecordCount;   // → @FieldType('int')
String? growthRate;             // → @FieldType('double')

// After (type expressed in @Form Field):
@Form([
  Field('estimatedRecordCount', int, 'Estimated number of records'),
  Field('growthRate', double, 'Expected growth rate'),
])
String? content;
```

The `@FieldType` annotation **still applies** to standalone `String?` fields
that remain outside `@Form` (e.g., rare non-form scalar fields).

**Name → type mapping** (applies to both `Field` type parameter and
standalone `@FieldType`):

| Field name pattern              | Type / Annotation         |
|---------------------------------|---------------------------|
| `*Count`, `*Number`, `step*`    | `int` / `@FieldType('int')` |
| `*Rate`, `*Fte*`, `*Allocation` | `double` / `@FieldType('double')` |
| `*Date`                         | `date` / `@FieldType('date')` |
| `*Duration`                     | `duration` / `@FieldType('duration')` |
| `*Budget`, `*Cost`              | `currency` / `@FieldType('currency')` |

**Note:** The `*Diagram`, `*Chart` row is removed — diagram fields are now
typed section classes (see Rule 4).

---

## 10. `@AccessKey` — from entry classes with identifying fields

**Pattern:** Entry classes that have a field serving as the matching key for
`@ForEach` relationships or registry lookups.

```dart
class BusinessProcessEntry {
  String? processId;    // → @AccessKey('processId')
  String? processName;
  …
}
```

**Rule:** Fields named `*Id` or `*Name` that serve as the primary identifier
for the entry. Apply `@AccessKey('fieldName')` to the field.

**Heuristic:** If the entry class has a field ending in `Id`, prefer that as the
access key. Otherwise, prefer the field ending in `Name`.

---

## 11. `@Reference` — from cross-reference fields

**Pattern:** Fields that reference data owned by another section in the model.

References are **typed Dart fields** pointing to the referenced section class,
not strings. The field type IS the target section type. The outliner shows
references but does **NOT** follow them (no tree recursion — see outliner spec
§5.2). The schema generator uses them for cross-reference validation.

```dart
@Reference('Process this interaction belongs to')
TargetBusinessProcess? processReference;

@Reference('Source entity in this relationship')
DataEntityEntry? sourceEntity;

@Reference('Target entity in this relationship')
DataEntityEntry? targetEntity;
```

**Rule:** Fields containing `*Reference`, `*Related*`, or that clearly point to
another section become `@Reference('description') TargetType? fieldName`.

The `@Reference` annotation takes a single `String description` parameter.

**Identification heuristics:**
- Field name ends in `Reference` → definitely a reference
- Field name is `source*` / `target*` and the context is a relationship → reference
- Field name is `related*` → likely a reference
- Field value would be an ID or name that matches another section type → reference

**Outline rendering:** References are shown with `fieldName:TypeName:path`
notation (see outliner spec §4.9) and are never recursed into.

---

## 12. `@MaxDepth` — from section structure

**Pattern:** Leaf section classes that should not contain further subsections.

**Rule:** Entry classes (form classes) typically get `@MaxDepth(0)` — they are
leaf nodes. Section classes with only one level of child sections get
`@MaxDepth(1)`.

**Heuristic:** If an entry class has no `List<T>` fields holding subsection
types (only scalar fields), apply `@MaxDepth(0)`.

---

## 13. `@AllowedTags` — no current comment convention

No comment convention currently maps to `@AllowedTags`. This annotation must be
applied manually based on domain knowledge.

---

## 14. `@ForEach` — from implicit cross-references

**Pattern:** Lists that must correspond 1:1 with entries in another registry.

```dart
/// 6.6. Process Catalog [PD00-TAR-CAT] — contains 1+× Target Business Process.
List<TargetBusinessProcess> processCatalog = [];
```

**Rule:** When a list contains items that must match entries in a separate
registry (e.g., workplace descriptions per user category), apply
`@ForEach('RegistryType', 'keyField')`.

**Heuristic:** Comments saying `per user category` or `per XYZ` indicate a
for-each relationship with the corresponding registry.

---

## 15. `@ValidationPrompt` — no direct comment convention

No comment convention currently maps to `@ValidationPrompt`. This annotation
must be added by domain experts for AI-assisted validation.

---

## 16. `@PatternCheck` / `@PatternCheckId` — from ID format conventions

**Pattern:** Section IDs follow strict patterns.

**Rule:** Classes with `@SectionId` whose children follow a predictable pattern
(e.g., `PD00-XXX-nn`) should get `@PatternCheckId` to validate the full ID
format.

```dart
@PatternCheckId(r'PD00-ADM-TEA-\d{2}')
```

---

## Summary of Confidence Levels

| Rule | Annotation / Pattern | Confidence | Source signal |
|------|---------------------|------------|--------------|
| 1 | `@SectionId` | **High** | Explicit `[PD00-XXX]` in comment |
| 2 | `@SectionIdPattern` | **High** | Explicit `[PD00-XXX-nn]` in comment |
| 3 | `@Min` | **High** | Explicit `contains N+×` in comment |
| 4 | Section base types | **High** | Explicit `(text)` / `(mermaid-*)` / `(code-*)` → typed fields |
| 4a | `@Form` / `Field` | **High** | Form classes with scalar `String?` fields → `@Form` on content |
| 5 | `@Comment` (Seeds) | **High** | Explicit `Seeds → XX` text |
| 6 | `@Prefix` | **Medium** | Derived from SectionId hierarchy |
| 7 | `@Position` | **Low** | Declaration order already correct |
| 8 | `@TextRequired` | **Medium** | From `(description)` + class shape |
| 9 | Field types | **High** | Name heuristics; type in `Field()` param or standalone `@FieldType` |
| 10 | `@AccessKey` | **Medium** | `*Id` / `*Name` field patterns |
| 11 | `@Reference` | **High** | `*Reference` / `*Related*` fields → typed `@Reference` pointers |
| 12 | `@MaxDepth` | **Medium** | Class shape (no subsection lists) |
| 13 | `@AllowedTags` | **None** | No comment convention |
| 14 | `@ForEach` | **Low** | `per XYZ` heuristic |
| 15 | `@ValidationPrompt` | **None** | No comment convention |
| 16 | `@PatternCheckId` | **Medium** | ID format conventions |
