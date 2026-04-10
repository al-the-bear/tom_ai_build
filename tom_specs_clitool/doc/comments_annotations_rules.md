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

## 4. `@ContentType` — from `(form)`, `(description)`, `(mermaid)` in comment

**Pattern:** Parenthetical suffix at end of class doc-comment.

```dart
/// A team member entry [PD00-ADM-TEA-nn] (form).
class TeamMemberEntry { … }

/// A scenario entry (description).
class ScenarioEntry { … }

/// 7.1.3. Entity-Relationship Diagram [PD00-BUS-DAT-DIA] (mermaid).
String? erDiagram;
```

**Rules:**

| Comment suffix    | Annotation                 | Applies to     |
|-------------------|----------------------------|----------------|
| `(form)`          | `@ContentType('Form')`     | Entry classes   |
| `(description)`   | `@ContentType('Description')` | Classes / fields |
| `(mermaid)`       | `@ContentType('Mermaid')`  | `String?` fields |

**Form variant suffixes** — additional qualifiers map to `@Comment`:

| Variant                | ContentType          | Additional annotation     |
|------------------------|----------------------|---------------------------|
| `(form, singular)`     | `@ContentType('Form')` | `@Comment('singular')`  |
| `(form, repeatable)`   | `@ContentType('Form')` | `@Comment('repeatable')` |
| `(form, per user category)` | `@ContentType('Form')` | `@Comment('per user category')` |

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

## 9. `@FieldType` — from field semantics in name or comment

**Pattern:** Field names or comments that imply a non-string type.

```dart
String? estimatedRecordCount;   // → @FieldType('int')
String? growthRate;             // → @FieldType('double')
String? targetStartDate;        // → @FieldType('date')
String? estimatedDuration;      // → @FieldType('duration')
String? fteAllocation;          // → @FieldType('double')
String? fteCount;               // → @FieldType('double')
String? budget;                 // → @FieldType('currency')
String? stepNumber;             // → @FieldType('int')
```

**Rules by name suffix/keyword:**

| Field name pattern            | Annotation              |
|-------------------------------|-------------------------|
| `*Count`, `*Number`, `step*`  | `@FieldType('int')`     |
| `*Rate`, `*Fte*`, `*Allocation` | `@FieldType('double')` |
| `*Date`                       | `@FieldType('date')`    |
| `*Duration`                   | `@FieldType('duration')`|
| `*Budget`, `*Cost`            | `@FieldType('currency')`|
| `*Diagram`, `*Chart`          | `@FieldType('mermaid')` |

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
not strings. The field type IS the target section type. The outliner does NOT
follow references (no tree recursion). The schema generator uses them for
cross-reference validation.

```dart
// Before (current model — string references):
String? processReference;   // references TargetBusinessProcess
String? sourceEntity;       // references DataEntityEntry

// After (restructured — typed references):
@Reference('Process this interaction belongs to')
TargetBusinessProcess? processReference;

@Reference('Source entity in this relationship')
DataEntityEntry? sourceEntity;
```

**Rule:** Fields containing `*Reference`, `*Related*`, or that clearly point to
another section become `@Reference('description') TargetType? fieldName`.

**Identification heuristics:**
- Field name ends in `Reference` → definitely a reference
- Field name is `source*` / `target*` and the context is a relationship → reference
- Field name is `related*` → likely a reference
- Field value would be an ID or name that matches another section type → reference

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

| Rule | Annotation | Confidence | Source signal |
|------|-----------|------------|--------------|
| 1 | `@SectionId` | **High** | Explicit `[PD00-XXX]` in comment |
| 2 | `@SectionIdPattern` | **High** | Explicit `[PD00-XXX-nn]` in comment |
| 3 | `@Min` | **High** | Explicit `contains N+×` in comment |
| 4 | `@ContentType` | **High** | Explicit `(form)` / `(description)` / `(mermaid)` |
| 5 | `@Comment` (Seeds) | **High** | Explicit `Seeds → XX` text |
| 6 | `@Prefix` | **Medium** | Derived from SectionId hierarchy |
| 7 | `@Position` | **Low** | Declaration order already correct |
| 8 | `@TextRequired` | **Medium** | From `(description)` + class shape |
| 9 | `@FieldType` | **Medium** | Field name heuristics |
| 10 | `@AccessKey` | **Medium** | `*Id` / `*Name` field patterns |
| 11 | `@Reference` | **Medium** | `*Reference` / `*Related*` fields → typed section pointers |
| 12 | `@MaxDepth` | **Medium** | Class shape (no subsection lists) |
| 13 | `@AllowedTags` | **None** | No comment convention |
| 14 | `@ForEach` | **Low** | `per XYZ` heuristic |
| 15 | `@ValidationPrompt` | **None** | No comment convention |
| 16 | `@PatternCheckId` | **Medium** | ID format conventions |
