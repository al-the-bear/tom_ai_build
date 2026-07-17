# tom_specs_core — TomSpecs annotations & section base types

`tom_specs_core` is the annotation library shared by the whole TomSpecs Spec
Object Model (SOM) stack. It defines two things and no runtime logic:

1. **Annotations** (`lib/src/annotations/`) — the metadata the model classes in
   [`tom_specs_model`](../tom_specs_model) carry so the tooling
   ([`tom_specs_clitool`](../tom_specs_clitool)) can read, validate, outline, and
   generate the per-language `tom_som_<lang>_v0` facades.
2. **Section base types** (`lib/src/sections/`) — small reusable classes with a
   baked-in `@ContentType`, used as typed field values instead of bare
   `String?` content fields.

The model is the single source of truth; every annotation defined here is read
by the analyzer-based `ModelReader` and flows through `ModelJsonExporter` into
the meta-data file (`spec_model.meta.json`) that every language runtime loads.

> **Cross-references.** The **outline rendering** semantics of each annotation
> and the model-design rules live in
> [`tom_specs_model/doc/specs_model_outliner.md`](../tom_specs_model/doc/specs_model_outliner.md)
> §4, §6, §7. The **comment → annotation derivation** rules (how each annotation
> is inferred from a doc-comment convention) live in
> [`tom_specs_clitool/doc/comments_annotations_rules.md`](../tom_specs_clitool/doc/comments_annotations_rules.md).
> This README is the catalogue of *what each annotation is*; those documents own
> *how it renders* and *how it is derived*.

---

## Import

```dart
import 'package:tom_specs_core/tom_specs_core.dart';
```

The barrel re-exports every annotation (`annotations/annotations.dart`) and
every section base type (`sections/sections.dart`).

---

## Section base types

Each section base type is a class with a single `content` field that carries a
class-baked `@ContentType`. Model fields use the typed section instead of a bare
`String?`, so the content format is fixed by the field's declared type and the
authoring guidance comes from the doc-comment on the field that holds it.

| Class | `@ContentType` | Extends | Meaning |
| --- | --- | --- | --- |
| `TextSection` | `text` | — | Free narrative text (may embed diagrams/references). |
| `CodeSection` | `code` | — | Language-agnostic code block. |
| `DartCodeSection` | `code-dart` | `CodeSection` | Dart code block. |
| `SqlCodeSection` | `code-sql` | `CodeSection` | SQL code block. |
| `DdlCodeSection` | `code-ddl` | `CodeSection` | DDL code block. |
| `DiagramSection` | `mermaid` | — | Generic Mermaid diagram. |
| `ErDiagramSection` | `mermaid-er` | `DiagramSection` | Mermaid ER diagram. |
| `FlowDiagramSection` | `mermaid-flow` | `DiagramSection` | Mermaid flowchart. |
| `SequenceDiagramSection` | `mermaid-sequence` | `DiagramSection` | Mermaid sequence diagram. |
| `GanttDiagramSection` | `mermaid-gantt` | `DiagramSection` | Mermaid Gantt chart. |

```dart
class DataModel {
  /// Overview of the data model including all entity relationships.
  TextSection dataModelOverview = TextSection();

  /// Entity-relationship diagram of the data model.
  ErDiagramSection erDiagram = ErDiagramSection();
}
```

Subtypes `@override` the `content` field only to change the baked-in
`@ContentType`; they add no fields.

---

## Annotation catalogue

Annotations group by concern. Each row lists the constructor signature and the
target (class `C` / member `M`).

### Identity & structure

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@SectionId` | `SectionId(String id)` | C, M | The globally-unique section-type ID (a short mnemonic code, e.g. `INDM`). On a list container field it takes the `<elemId>-<SUFFIX>-LST` form. |
| `@SectionIdPattern` | `SectionIdPattern(String pattern)` | M | On a `List<T>` field: the instance-ID pattern (`<elemId>-<SUFFIX>-xxx`) for the elements. The element class carries no `@SectionId`. |
| `@Document` | `Document({String name, String description, List<Type>? basedOn})` | C | Marks a document-root class; `basedOn` names the source document(s) it derives from. |
| `@Prefix` | `Prefix(String prefix)` | C | Common section-ID prefix enabling two-stage (heading-prefix) ID resolution. |
| `@Position` | `Position(String position)` | M | Explicit field ordering (`'first'` / `'last'`); default is declaration order. |
| `@SerializationOrder` | `SerializationOrder(int order)` | M | **The member's 0-based source-declaration position within its class.** Pins on-disk emission order so every language serialises members identically. Stamped in bulk by `stamp_serialization_order.dart`. |

### Content typing & authoring

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@ContentType` | `ContentType(String type, String description)` | M | Declares the format of a `String? content` field on a non-section class. (Section base types bake this in — see above.) |
| `@Form` | `Form(List<Field> fields)` | M | Collapses a form class's scalar fields into a single annotation on `content`. |
| `Field` | `Field(String name, Type type, String description, {bool required, String? hint})` | — | One form field: its name, scalar type (`String`/`int`/`double`/enum), description, requiredness, and author hint. |
| `@ContentHelp` | `ContentHelp(String guidance)` | C, M | Actionable "how to fill this in" guidance for authors/AI. |
| `@Headline` | `Headline(String text)` | C, M | Predefined DEFAULT headline for a fixed-meaning section: editor prefill + render fallback. Precedence: stored headline > `@Headline` default > name derivation; a member-level annotation wins over the target class's. (YRD4) |
| `@TextRequired` | `TextRequired()` | C, M | The section's text content is the primary deliverable; empty is invalid. |
| `@Unused` | `Unused()` | M | The `content` field is not expected (container-only class); text is ignored. |
| `@Comment` | `Comment(String text)` | C, M | Free-form informational metadata for downstream generators (e.g. `Seeds → BP, UC`). |

### Constraints & validation

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@Min` / `@Max` | `Min(int count)` / `Max(int count)` | M | Min/max cardinality of a `List<T>` field. |
| `@MinLength` / `@MaxLength` | `MinLength(int length)` / `MaxLength(int length)` | M | Min/max content length. |
| `@MaxDepth` | `MaxDepth(int levels)` | C | Maximum subsection nesting (`0` for leaf/entry classes). |
| `@AllowedTags` | `AllowedTags(List<String> tags)` | M | The inline tags a text section may contain. |
| `@PatternCheckId` | `PatternCheckId(String pattern, {String? errorMessage})` | C | Validates the full section-ID format of children. |
| `@PatternCheck` | `PatternCheck(String pattern, {String? errorMessage})` | M | Validates a field value against a regex. |
| `@ValidationPrompt` | `ValidationPrompt(String prompt)` | C, M | AI-assisted validation prompt. |

### Cross-references & relationships

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@Reference` | `Reference(String description)` | M | A typed field pointing at another section class (the field type is the target). Not recursed into by the outliner; used for cross-reference validation. |
| `@AccessKey` | `AccessKey(String key)` | M | Names the field that identifies an entry for lookups / `@ForEach` matching. |
| `@ForEach` | `ForEach(String registryType, String key)` | M | A list that must correspond 1:1 to entries in another registry. |
| `@SeedFor` | `SeedFor(Type documentRootClass)` | M | Compile-time link from a section to the single Phase 3 document it seeds. |

### Traceability (Solution Blueprint → Phase 3 DocSpecs)

These four annotations encode how the `D00SolutionBlueprint` master model
maps into the twelve Phase 3 DocSpec documents. Their rules are enforced by the
§8.6 structural invariants in
[`tom_specs_clitool/lib/src/validator.dart`](../tom_specs_clitool/lib/src/validator.dart).

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@MapsTo` | `MapsTo(Type documentClass)` | C | The shallowest Solution Blueprint class whose entire subtree flows to one target DocSpec — the document's "seed node". |
| `@DetailedIn` | `DetailedIn(Type documentClass)` | C | A class promoted to a top-level entry of the target DocSpec (the "take-off" level). Either the whole seed (alongside `@MapsTo`) or each flattened child. Requires a `@MapsTo` ancestor. |
| `@SecondLevelSectionId` | `SecondLevelSectionId(Type documentClass, String id)` | C | The document-scoped short ID a class uses as a top-level entry in a specific Phase 3 document (e.g. `QAP-FRA` for global `QLFWK`). One per target document; implies `@DetailedIn`. |
| `@StandardReferences` | `StandardReferences(List<String> standards, String connotation)` | C, M | The public standard(s) the section derives from (ID + clause in the standard's wording) plus a short statement of what the section *means* (distinct from `@ContentHelp`/`Field.hint` authoring guidance). |

---

## Where the annotations are consumed

- **`ModelReader`** (`tom_specs_clitool`) reads every annotation via the Dart
  analyzer — no marker annotation is needed; all model classes are scanned.
- **`validator.dart`** enforces the model-design rules (§6) and the §8.6
  structural invariants (`@SectionId` uniqueness/coverage, `@SectionIdPattern`
  pairing, `@DetailedIn → ancestor @MapsTo`, `@SecondLevelSectionId ⇒
  @DetailedIn`, per-`@Document` detail count).
- **`ModelJsonExporter`** serialises the resolved graph — including the lossless
  per-class / per-field `annotations` block — into `spec_model.meta.json`, which
  every `tom_som_<lang>_runtime` loads for the reflection access path.
- **`outliner.dart`** renders the class tree; §4.13 of the outliner spec lists
  which annotations are *visible* in the outline vs *schema-only*.
