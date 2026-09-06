# tom_specs_core — TomSpecs annotations & section base types

> **Cross-references.**
> [`tom_specs_model/doc/tom_specs_model_rules.md`](../tom_specs_model/doc/tom_specs_model_rules.md)
> owns the annotation **vocabulary and authoring rules**
> (`tom_specs_model_rules.md` §9 — when to reach for which annotation), the
> **mapping semantics** of each annotation (`tom_specs_model_rules.md` §9.2 —
> what it does to the emitted document, schema and meta-data) and the **outline
> rendering** notation (`tom_specs_model_rules.md` §11.2). This README is the
> catalogue of *what each annotation is*; that document owns *how it maps*,
> *when to use it*, and *how it renders*.

Core annotations and shared types for TomSpecs document model families.

## Where this fits

**TomSpecs** is a method for building software from structured specification
documents: a project is written up as a set of typed documents, and the code
skeleton is generated from them. The typed documents are described by a single
Dart source model — the **Specification Object Model (SOM)**, in
[`tom_specs_model`](../tom_specs_model) — from which runtimes for nine
languages are generated. `tom_specs_core` is the vocabulary that model is
written in: the annotations its classes carry and the base classes its sections
extend.

It exists so that vocabulary has a home **outside** the model package. The
tooling in [`tom_specs_clitool`](../tom_specs_clitool) scans
`tom_specs_model/lib/src` with the Dart analyzer and reflects every class it
finds into the document metadata; anything the model must *use* but is not
*part of* — `DocSpecsSection`, `TextSection`, `@SectionId` — has to sit outside
that scanned tree or it would be reflected as if it were a document section.
Without the split there is no way to say "this class is infrastructure of the
metamodel" at all.

So it sits at the bottom of the TomSpecs stack: zero dependencies, no runtime
logic, and depended on by the model, by the tooling that reads the model, and by
[`tom_code_specs`](../tom_code_specs), which reuses its
`@CodeSpecKind` link annotation on the code side.

## Overview

The package defines two things and no runtime logic:

1. **Annotations** (`lib/src/annotations/`) — 34 const classes carrying the
   metadata the model classes declare. They are read by the analyzer at
   generation time, never reflected at runtime; a released program never loads
   this package to *ask* an annotation anything.
2. **Section base types** (`lib/src/sections/`) — 11 small classes, headed by
   `DocSpecsSection`, used as typed field values instead of bare `String?`
   content fields. A content-typed leaf bakes in its `@ContentType`, so a
   field's format is fixed by its declared type rather than by an annotation
   the author has to remember.

The model is the single source of truth; every annotation defined here is read
by the analyzer-based `ModelReader` and flows through `ModelJsonExporter` into
the metadata file (`spec_model.meta.json`) that every language runtime loads.
That is the whole mechanism by which a Dart annotation reaches a Go or Rust
program: it is exported as data, not as code.

## Installation

```yaml
dependencies:
  tom_specs_core: ^0.1.0
```

or

```bash
dart pub add tom_specs_core
```

```dart
import 'package:tom_specs_core/tom_specs_core.dart';
```

The barrel re-exports every annotation (`annotations/annotations.dart`) and
every section base type (`sections/sections.dart`).

## Features

### Section base types

**`DocSpecsSection`** (YRD5) is the universal section base type of the TomSpecs
object model: it stores a section's `headline`, `id`, body `content`, and an
optional parsed **`DocSpecsForm form`** (one parsed value per `@Form` field). A
form's free text — the preamble before its first field line (SOM §11.4 rule 7) —
is the section's own `content`, the slot a non-form section's body already uses,
so body text has one home whether or not the section is a form. Every
`tom_specs_model` class extends it, and model
members formerly typed `String?` / `List<String>` are now
`DocSpecsSection?` / `List<DocSpecsSection>` — so a `*.md` document can be
parsed into the model with full headline/id fidelity. See
[`tom_specs_model_rules.md`](../tom_specs_model/doc/tom_specs_model_rules.md)
§5.2 for the mapping contract
(the exported meta tree still renders these members as `String` content nodes).

Each *content-typed* section base type below extends `DocSpecsSection` with a
class-baked `@ContentType` on `content`. Model fields use the typed section
instead of a bare content member, so the content format is fixed by the field's
declared type and the authoring guidance comes from the doc-comment on the
field that holds it.

| Class | `@ContentType` | Extends | Meaning |
| --- | --- | --- | --- |
| `DocSpecsSection` | *(none)* | — | Universal base: stored headline, id, content, parsed form. |
| `TextSection` | `text` | `DocSpecsSection` | Free narrative text (may embed diagrams/references). |
| `CodeSection` | `code` | `DocSpecsSection` | Language-agnostic code block. |
| `DartCodeSection` | `code-dart` | `CodeSection` | Dart code block. |
| `SqlCodeSection` | `code-sql` | `CodeSection` | SQL code block. |
| `DdlCodeSection` | `code-ddl` | `CodeSection` | DDL code block. |
| `DiagramSection` | `mermaid` | `DocSpecsSection` | Generic Mermaid diagram. |
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

### Annotation catalogue

Annotations group by concern. Each row lists the constructor signature and the
target (class `C` / member `M`).

This catalogue is a **live surface**, and that is checked rather than asserted:
every class under `lib/src/annotations/` must name a destination in
`tom_specs_clitool`'s `docspecs_annotation_mapping.dart` — either the DocSpecs
schema key it produces or an explicit model-only reason — and every declared
schema key must actually be emitted by the schema generator. Adding an
annotation here without deciding where it lands fails a test.

#### Identity & structure

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@SectionId` | `SectionId(String id)` | C, M | The globally-unique section-type ID (a short mnemonic code, e.g. `INDM`). On a list container field it takes the `<elemId>-<SUFFIX>-LST` form. |
| `@SectionIdPattern` | `SectionIdPattern(String pattern)` | M | On a `List<T>` field: the instance-ID pattern (`<elemId>-<SUFFIX>-xxx`) for the elements. The element class carries no `@SectionId`. |
| `@Document` | `Document({String name, String description, List<Type>? basedOn})` | C | Marks a document-root class; `basedOn` names the source document(s) it derives from. |
| `@Prefix` | `Prefix(String prefix)` | C | Common section-ID prefix enabling two-stage (heading-prefix) ID resolution. |
| `@Position` | `Position(String position)` | M | Explicit field ordering (`'first'` / `'last'`); default is declaration order. |
| `@SerializationOrder` | `SerializationOrder(int order)` | M | **The member's 0-based source-declaration position within its class.** Pins on-disk emission order so every language serialises members identically. Stamped in bulk by `stamp_serialization_order.dart`. |

#### Content typing & authoring

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

#### Constraints & validation

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@Min` / `@Max` | `Min(int count)` / `Max(int count)` | M | Min/max cardinality of a `List<T>` field. |
| `@MinLength` / `@MaxLength` | `MinLength(int length)` / `MaxLength(int length)` | M | Min/max content length. |
| `@MaxDepth` | `MaxDepth(int levels)` | C | Maximum subsection nesting (`0` for leaf/entry classes). |
| `@AllowedTags` | `AllowedTags(List<String> tags)` | C | The inline tags a text section may contain. |
| `@PatternCheckId` | `PatternCheckId(String pattern, {String? errorMessage})` | C | Validates the full section-ID format of children. |
| `@PatternCheck` | `PatternCheck(String pattern, {String? errorMessage})` | M | Validates a field value against a regex. |
| `@ValidationPrompt` | `ValidationPrompt(String prompt)` | C, M | AI-assisted validation prompt. |
| `@OneOf` | `OneOf({required String discriminator, List<Object> noCase = const [], String? note})` | C | Marks a container class as a **discriminated subsection group** (`codespecs_mapping.md` §8.2). `discriminator` names a `@Form` field of the container whose type is a **model enum** (YRD7); the enum value chosen at author time selects which `@Case`-bound subsection fields are present. `noCase` lists the discriminator constants that deliberately bind no case — kinds whose whole surface is the common subsections — so the coverage check can tell an attribute-free kind from a forgotten one. A `noCase` entry that is not a constant of the discriminator enum, or that a `@Case` does cover, is an error. |
| `@Case` | `Case(Object value)` | M | Repeatable. Binds a complex subsection field to one enum constant of the enclosing `@OneOf` discriminator (`value` is the qualified `EnumType.constant`). A subsection with no `@Case` is *common* (present under any case). Enforced statically (validator.dart `tom_specs_model_rules.md` §10.2 one-of) and at instance level (runtime `validateDocument`, `oneOfCaseMismatch`). |

#### Cross-references & relationships

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@Reference` | `Reference(String description)` | M | A typed field pointing at another section class (the field type is the target). Not recursed into by the outliner; used for cross-reference validation. |
| `@AccessKey` | `AccessKey(String key)` | M | The key a section is reached by in the DocSpecs access API, overriding its section-type name; also the value a `@ForEach` on the matching registry keys against. Top-level sections only. |
| `@ForEach` | `ForEach(String registryType, String key)` | M | A list that must correspond 1:1 to entries in another registry, named by its **section id**. The registry must be reachable from the same document root. Top-level sections only. |

#### Traceability (Solution Blueprint → Phase 3 DocSpecs)

These three annotations encode how the `D00SolutionBlueprint` master model maps
into the twelve Phase 3 DocSpec documents. Their rules are enforced by the
`tom_specs_model_rules.md` §10.2 structural invariants in
[`tom_specs_clitool/lib/src/validator.dart`](../tom_specs_clitool/lib/src/validator.dart).

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@MapsTo` | `MapsTo(Type documentClass)` | C | The shallowest Solution Blueprint class whose entire subtree flows to one target DocSpec — the document's "seed node". |
| `@DetailedIn` | `DetailedIn(Type documentClass)` | C | A class promoted to a top-level entry of the target DocSpec (the "take-off" level). Either the whole seed (alongside `@MapsTo`) or each flattened child. Requires a `@MapsTo` ancestor. |
| `@StandardReferences` | `StandardReferences(List<String> standards, String connotation)` | C, M | The public standard(s) the section derives from (ID + clause in the standard's wording) plus a short statement of what the section *means* (distinct from `@ContentHelp`/`Field.hint` authoring guidance). |

#### DocSpecs ↔ CodeSpecs link (general, type-level)

The general type-level half of the bidirectional DocSpecs↔CodeSpecs link
([`codespecs_mapping.md`](../tom_specs_model/doc/codespecs_mapping.md)
§9.1/§9.5). It lives here because
it annotates SOM model classes — the concrete forward `codeSpec` member is a
`DocSpecsSection` field, and the code-side back-trace `@DocSpec`/`DocRef` lives
in [`tom_code_specs`](../tom_code_specs).

| Annotation | Signature | Target | Purpose |
| --- | --- | --- | --- |
| `@CodeSpecKind` | `CodeSpecKind(List<CodeSpecPart> kinds, {String? note})` | C | Declares which CodeSpecs part *type(s)* a section *type* (or form field) is realised as. **List-valued** since a section/field may map to several kinds; a single-kind mapping uses a one-element list. The kind enum is `CodeSpecPart` — **28 values**: the **26 active parts** (`codespecs_mapping.md` §4.1), the **member kind `domainEnum`**, and the **1 deferred candidate** (`codespecs_mapping.md` §4.3): `workflow`. `CE-TR`/Traceability is excluded — it is cross-cutting (`codespecs_mapping.md` §9), not a mappable kind. A deferred value is *mapping-only*: a SOM section may carry it now, but the part has no `Cs*` annotation, built-on `tom_core` class or generated code until promoted into `codespecs_mapping.md` §4.1. Kind values are drawn from the `codespecs_mapping.md` §4.1/§4.3 catalogues so they cannot drift. |
| `@FollowUpKind` | `FollowUpKind(List<FollowUpProcess> processes, {String? note})` | C | The follow-up counterpart of `@CodeSpecKind`: tags a SOM follow-up subtree root (the descriptive, no-`@CodeSpecKind` content isolated by the Band-F splits) with the downstream **process(es)** it feeds. **List-valued** — a subtree can feed several processes. The kind enum is `FollowUpProcess` — the extensible taxonomy from `codespecs_mapping.md` §8.3: `doc` (documentation), `trn` (training), `org` (organisation), `ops` (operations), `cap` (capacity/data volume), `cmp` (compliance), `mig` (migration), `l10n` (localization), plus `acc` (acceptance/quality, added for SBP.14). Like `@CodeSpecKind`, it annotates SOM model classes and adds no classes to the graph; exported losslessly via the generic `annotations` block. |
| `@NoArtifact` | `NoArtifact(NoArtifactReason reason, {String? note})` | C | The **third routing verdict**, completing the pair above: the section feeds neither a CodeSpecs part nor a follow-up process. Mutually exclusive with both, and — unlike them — **single-valued**, because a section feeds several parts or processes at once but is unrouted for one reason. The reason enum is `NoArtifactReason`, a closed three: `container` (a grouping node whose children carry every routable fact), `overview` (prose restating material a routed section specifies normatively; `note` names where), `view` (a derived re-presentation — a diagram, a traceability matrix, a cross-reference index — which a generator could produce but never consume). Its purpose is to make "produces nothing" a *recorded decision* rather than an omission, which is what lets `tom_specs_model_rules.md` §10.2 invariant `ROUTE-TOTAL` demand one of the three verdicts on every reachable section. |
| `@CodeSpecsProjection` | `CodeSpecsProjection()` | C | Marks a `@Document` root as the **CodeSpecs generation projection** (`D13CodeSpecsProjection`, `@SectionId('CGP')`). Such a projection is `@CodeSpecKind`-driven, not `@DetailedIn`-driven — the single-valued `@DetailedIn`/`@MapsTo` pair is already spent on each section's Phase-3 document — so this marker exempts the document from the `tom_specs_model_rules.md` §10.2 detail-count check **only**. It does *not* relax the pure-projection invariant (the projection must still reach only types present in the `D00SolutionBlueprint` tree). |

## Quick start

A model class is an ordinary Dart class extending `DocSpecsSection`, with
annotations saying what the generator should make of it.

```dart
// dart run example.dart
import 'package:tom_specs_core/tom_specs_core.dart';

@SectionId('INDM')
@Headline('Information Model')
class InformationModel extends DocSpecsSection {
  /// Overview of the data model including all entity relationships.
  @ContentHelp('Name every entity and say how it relates to its neighbours.')
  TextSection overview = TextSection();

  /// Entity-relationship diagram of the data model.
  ErDiagramSection erDiagram = ErDiagramSection();
}

void main() {
  final model = InformationModel()
    ..id = 'INDM'
    ..headline = 'Information Model'
    ..overview.content = 'Customer places Order; Order contains OrderLine.';

  print(model.id); // INDM
  print(model.overview.content); // Customer places Order; Order contains OrderLine.
  print(model.erDiagram.content); // null — no diagram authored yet
}
```

In `tom_specs_model` every member additionally carries a `@SerializationOrder`
stamp; it is applied in bulk by `tom_specs_clitool`'s
`stamp_serialization_order.dart` rather than written by hand.

## Usage

### Typing a content field

Prefer a content-typed section over `@ContentType` on a bare `String?`. The
format then travels with the field's type, and a reader of the class sees it
without reading an annotation.

```dart
class SecurityModel extends DocSpecsSection {
  /// The threat narrative.
  TextSection threats = TextSection();

  /// The schema the security tables are created from.
  DdlCodeSection tables = DdlCodeSection();
}
```

### Declaring a list of repeated entries

A repeated entry has no `@SectionId` of its own; the containing field carries
the instance-id pattern, and the container id ends in `-LST`.

```dart
class RequirementEntry extends DocSpecsSection {
  TextSection rationale = TextSection();
}

class Requirements extends DocSpecsSection {
  @SectionId('RSP-REQ-LST')
  @SectionIdPattern('RSP-REQ-xxx')
  @Min(1)
  List<RequirementEntry> requirements = [];
}
```

### Recording where a section goes

Traceability is authored as annotations, and the invariants that keep it
consistent are checked by the validator rather than by review.

```dart
@SectionId('SBP-SEC')
@MapsTo(D06SecurityAccessSpecification)
@DetailedIn(D06SecurityAccessSpecification)
@CodeSpecKind([CodeSpecPart.authorization])
class SecurityConcept extends DocSpecsSection {}
```

`@MapsTo` names the seed node, `@DetailedIn` the take-off level, and
`@CodeSpecKind` the CodeSpecs part the section is realised as. What each of
them *means* is decided by
[`tom_specs_model_rules.md`](../tom_specs_model/doc/tom_specs_model_rules.md)
and [`codespecs_mapping.md`](../tom_specs_model/doc/codespecs_mapping.md), not
here.

## Architecture

```
tom_specs_core                      (zero dependencies, no runtime logic)
├── lib/src/annotations/            34 const classes — pure metadata
│     read by the Dart analyzer at generation time, never reflected at runtime
└── lib/src/sections/               11 section base types
      DocSpecsSection + 10 content-typed leaves, instantiated by the model

   tom_specs_model ──── annotated with ────▶ tom_specs_core
          │                                        ▲
          │ scanned by                             │ read by
          ▼                                        │
   tom_specs_clitool ─────────────────────────────┘
          │ emits
          ▼
   spec_model.meta.json ──▶ nine tom_som_<lang>_runtime packages
```

| Type | Responsibility |
| --- | --- |
| `DocSpecsSection` | The universal section: stored `headline`, `id`, `content`, `codeSpec`, optional parsed `form`. Every model class extends it. |
| `DocSpecsForm` | The parsed field values of a `@Form` section, keyed by declared field name. |
| `TextSection` / `CodeSection` (+ 3 subtypes) / `DiagramSection` (+ 4 subtypes) | Content-typed leaves — a baked-in `@ContentType` and no added fields. |
| Identity & structure annotations | What a section *is*: its id, its document root, its emission order. |
| Content typing & authoring annotations | What its body holds, and how an author (human or AI) is guided to fill it. |
| Constraint annotations | What a valid instance looks like — cardinality, length, depth, patterns. |
| Traceability annotations | Where a Solution Blueprint section flows: `@MapsTo`, `@DetailedIn`, `@StandardReferences`. |
| Routing annotations | What a section produces downstream: `@CodeSpecKind`, `@FollowUpKind`, `@NoArtifact` — exactly one verdict per reachable section. |

### Where the annotations are consumed

- **`ModelReader`** ([`tom_specs_clitool`](../tom_specs_clitool)) reads every
  annotation via the Dart analyzer — no marker annotation is needed; all model
  classes are scanned.
- **`validator.dart`** enforces the `tom_specs_model_rules.md` §6
  model-design rules and the `tom_specs_model_rules.md` §10.2
  structural invariants (`@SectionId` uniqueness/coverage, `@SectionIdPattern`
  pairing, `@DetailedIn → ancestor @MapsTo`, per-`@Document` detail count,
  root-independent section-id resolution).
- **`ModelJsonExporter`** serialises the resolved graph — including the lossless
  per-class / per-field `annotations` block — into `spec_model.meta.json`, which
  every `tom_som_<lang>_runtime` loads for the reflection access path.
- **`docspecs_schema_generator.dart`** maps the schema-bound annotations onto
  DocSpecs schema keys; `docspecs_annotation_mapping.dart` declares which key
  each one produces and gates the correspondence in both directions
  (`tom_specs_model_rules.md` §9.5).
- **`outliner.dart`** renders the class tree; `tom_specs_model_rules.md`
  §11.2.13 lists which annotations are *visible* in the outline vs
  *schema-only*.

## Ecosystem

```
                      tom_specs_core          ← this package, zero dependencies
                             ▲
         ┌───────────────────┼────────────────────┐
         │                   │                    │
  tom_specs_model     tom_code_specs      tom_specs_clitool
  the SOM source      the Cs* family      generator, validator, gates
         │                                        │
         └──────────── read and generated by ─────┘
                             │
                             ▼
        nine tom_som_<lang>_v0 facades + tom_som_<lang>_runtime pairs
        (Dart, Python, Java, JavaScript, TypeScript, Go, Rust, C, C++)
```

Nothing depends on `tom_specs_core` at *application* runtime. It is a
build-time vocabulary; the generated per-language packages carry the metadata
it produced, not the package itself.

## Further documentation

**TomSpecs subject matter** — the authorities this package serves:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of the whole TomSpecs document set, and the `§` citation convention used throughout it |
| [tom_specs_model_rules.md](../tom_specs_model/doc/tom_specs_model_rules.md) | When to reach for which annotation, what each one does to the emitted document/schema/metadata, and the structural invariants the validator enforces |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | The nine-language generation, the metadata tree, and the markdown/YAML serialization of every construct |
| [codespecs_mapping.md](../tom_specs_model/doc/codespecs_mapping.md) | The CodeSpecs parts catalogue behind `CodeSpecPart`, and the routing verdicts behind `@CodeSpecKind` / `@FollowUpKind` / `@NoArtifact` |
| [tom_specs_project_flow.md](../tom_specs_model/doc/tom_specs_project_flow.md) | The TomSpecs creation process — the phases these documents are produced in |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_specs_model](../tom_specs_model) | The SOM source model written in this vocabulary |
| [tom_specs_clitool](../tom_specs_clitool) | The generator, validator, outliner and citation gates that read it |
| [tom_code_specs](../tom_code_specs) | The `Cs*` annotation family for Phase 4, which reuses `@CodeSpecKind` |
| [tom_som_dart_v0](../tom_som_dart_v0) | The generated Dart facade — what a consumer actually depends on to read a specification |

## Status

Version **0.1.0**, published on pub.dev.

The package has **no test suite of its own** — it declares const classes with
no behaviour to exercise. Its correctness is gated from outside instead: the
annotation catalogue is held against the live `lib/src/annotations/` tree by
`tom_specs_clitool`'s `test/docspecs_annotation_mapping_test.dart`, which fails
if an annotation is declared without naming a DocSpecs destination or a
model-only reason.
