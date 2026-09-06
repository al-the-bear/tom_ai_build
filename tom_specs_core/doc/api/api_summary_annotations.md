# TomSpecs Core API Reference: Annotations Module

The `annotations` module of `tom_specs_core` — the vocabulary a TomSpecs
model class is written in. Every declaration here is a `const` class or a
closed enum with no run-time behaviour; the readers are the analyzer-based
`ModelReader`, the DocSpecs schema generator, the nine SOM emitters and the
structural validator, all in `tom_specs_clitool`.

For task-oriented guidance see [annotations.md](../annotations.md). For when a
member *must* carry which annotation, see
[`tom_specs_model_rules.md`](../../../tom_specs_model/doc/tom_specs_model_rules.md).

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [Identity & structure](#identity--structure)
    - [SectionId](#sectionid)
    - [SectionIdPattern](#sectionidpattern)
    - [Document](#document)
    - [Prefix](#prefix)
    - [Position](#position)
    - [SerializationOrder](#serializationorder)
  - [Content & authoring](#content--authoring)
    - [ContentType](#contenttype)
    - [Form](#form)
    - [Field](#field)
    - [ContentHelp](#contenthelp)
    - [Headline](#headline)
    - [TextRequired](#textrequired)
    - [Unused](#unused)
    - [Comment](#comment)
  - [Constraints & validation](#constraints--validation)
    - [Min](#min)
    - [Max](#max)
    - [MinLength](#minlength)
    - [MaxLength](#maxlength)
    - [MaxDepth](#maxdepth)
    - [AllowedTags](#allowedtags)
    - [PatternCheck](#patterncheck)
    - [PatternCheckId](#patterncheckid)
    - [ValidationPrompt](#validationprompt)
    - [OneOf](#oneof)
    - [Case](#case)
  - [Cross-reference & traceability](#cross-reference--traceability)
    - [Reference](#reference)
    - [AccessKey](#accesskey)
    - [ForEach](#foreach)
    - [MapsTo](#mapsto)
    - [DetailedIn](#detailedin)
    - [StandardReferences](#standardreferences)
  - [Artifact routing](#artifact-routing)
    - [CodeSpecKind](#codespeckind)
    - [FollowUpKind](#followupkind)
    - [NoArtifact](#noartifact)
    - [CodeSpecsProjection](#codespecsprojection)
- [Enums](#enums)
  - [CodeSpecPart](#codespecpart)
  - [FollowUpProcess](#followupprocess)
  - [NoArtifactReason](#noartifactreason)

## Overview

The module declares **34 annotation classes** across five families, the `Field`
element of `@Form` (a value class, not an annotation), and **3 closed enums**.
Every class is `const`-constructible, so applying an annotation allocates
nothing: two identical annotations are the same object.

| Family | Annotations |
|--------|-------------|
| Identity & structure | `@SectionId`, `@SectionIdPattern`, `@Document`, `@Prefix`, `@Position`, `@SerializationOrder` |
| Content & authoring | `@ContentType`, `@Form` (+ its `Field` element), `@ContentHelp`, `@Headline`, `@TextRequired`, `@Unused`, `@Comment` |
| Constraints & validation | `@Min`, `@Max`, `@MinLength`, `@MaxLength`, `@MaxDepth`, `@AllowedTags`, `@PatternCheck`, `@PatternCheckId`, `@ValidationPrompt`, `@OneOf`, `@Case` |
| Cross-reference & traceability | `@Reference`, `@AccessKey`, `@ForEach`, `@MapsTo`, `@DetailedIn`, `@StandardReferences` |
| Artifact routing | `@CodeSpecKind`, `@FollowUpKind`, `@NoArtifact`, `@CodeSpecsProjection` |

## Class Hierarchy

```
Object
├── (annotation classes — all direct subclasses of Object, none extends another)
│   ├── Identity & structure
│   │   ├── SectionId
│   │   ├── SectionIdPattern
│   │   ├── Document
│   │   ├── Prefix
│   │   ├── Position
│   │   └── SerializationOrder
│   ├── Content & authoring
│   │   ├── ContentType
│   │   ├── Form
│   │   ├── Field  (element of @Form, not an annotation)
│   │   ├── ContentHelp
│   │   ├── Headline
│   │   ├── TextRequired
│   │   ├── Unused
│   │   └── Comment
│   ├── Constraints & validation
│   │   ├── Min
│   │   ├── Max
│   │   ├── MinLength
│   │   ├── MaxLength
│   │   ├── MaxDepth
│   │   ├── AllowedTags
│   │   ├── PatternCheck
│   │   ├── PatternCheckId
│   │   ├── ValidationPrompt
│   │   ├── OneOf
│   │   └── Case
│   ├── Cross-reference & traceability
│   │   ├── Reference
│   │   ├── AccessKey
│   │   ├── ForEach
│   │   ├── MapsTo
│   │   ├── DetailedIn
│   │   └── StandardReferences
│   └── Artifact routing
│   │   ├── CodeSpecKind
│   │   ├── FollowUpKind
│   │   ├── NoArtifact
│   │   └── CodeSpecsProjection
└── (enums)
    ├── CodeSpecPart
    ├── FollowUpProcess
    └── NoArtifactReason
```

The flat shape is deliberate: an annotation that extended another would let a
reader match the wrong one by subtype.

## Classes

### Identity & structure

#### SectionId

Declares the section ID that the annotated class has in the target specification document.

**Target:** Class, and a list-container member

##### Constructors

```dart
const SectionId(this.id);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The globally-unique section-type mnemonic (e.g. `INDM`). |

#### SectionIdPattern

Declares the section ID pattern for items in a `List<T>` field.

**Target:** Member (a `List<T>` field)

##### Constructors

```dart
const SectionIdPattern(this.pattern);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `pattern` | `String` | The instance-id pattern the list elements are numbered from (e.g. `CULA-SYS-xxx`). |

#### Document

Marks a class as a document root in the specification model.

**Target:** Class

##### Constructors

```dart
const Document({required this.name, required this.description, this.basedOn});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Display name of the document (e.g., 'Information Model'). |
| `description` | `String` | Description of the document's purpose and scope. |
| `basedOn` | `List<Type>?` | List of document types this document is derived from or based on. |

#### Prefix

Declares the section-type prefix used for two-stage ID matching.

**Target:** Class

##### Constructors

```dart
const Prefix(this.prefix);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `prefix` | `String` | The section-type prefix shared by the subtree, enabling two-stage id resolution. |

#### Position

Declares the ordering position of a subsection field within its parent.

**Target:** Member

##### Constructors

```dart
const Position(this.position);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `position` | `String` | Either `'first'` or `'last'`; anything else leaves declaration order in place. |

#### SerializationOrder

Declares the serialization ordinal of a member within its declaring class.

**Target:** Member

##### Constructors

```dart
const SerializationOrder(this.order);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `order` | `int` | The member's 0-based position in source declaration order within its class. |

### Content & authoring

#### ContentType

Annotates the `content` field to declare the format of the content text.

**Target:** Member (a `String? content` field on a non-section class)

##### Constructors

```dart
const ContentType(this.type, this.description);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | The content format token (e.g. `text`, `code-sql`, `mermaid-er`). |
| `description` | `String` | Human-readable description of the format, carried into the schema. |

#### Form

Declares the form fields for a section whose content is structured as name-value pairs (one per line).

**Target:** Member (`content`)

##### Constructors

```dart
const Form(this.fields);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `fields` | `List<Field>` | The form fields, in the order they appear in the document. |

#### Field

A single form field declaration.

**Target:** Not an annotation — an element of `@Form`

##### Constructors

```dart
const Field(
  String name,
  Type type,
  String description, {
  bool required = false,
  String? hint,
  List<String> refersTo = const [],
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Field name as it appears in the document (camelCase; display name conversion is done by tooling). |
| `type` | `Type` | Dart type of the value. |
| `description` | `String` | Short description shown in outlines and documentation. |
| `required` | `bool` | Whether this field is required (non-empty). |
| `hint` | `String?` | Optional hint text providing guidance on valid values, formats, or allowed options. |
| `refersTo` | `List<String>` | The registry key(s) this field's value is an **id drawn from**, each written `<SECTIONID>.<slot>` — e.g. |

#### ContentHelp

Provides content creation guidance for a section or field.

**Target:** Class or member

##### Constructors

```dart
const ContentHelp(this.guidance);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `guidance` | `String` | The guidance text explaining how to create or populate this content. |

#### Headline

Predefined DEFAULT headline for a section (YRD4).

**Target:** Class or member

##### Constructors

```dart
const Headline(this.text);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | The default headline text; a stored headline on the instance overrides it. |

#### TextRequired

Marks that the `content` text of a section must not be empty.

**Target:** Class or member

##### Constructors

```dart
const TextRequired();
```

#### Unused

Marks a `content` field as unused — section text is not expected and will be ignored by tooling.

**Target:** Member (`content`)

##### Constructors

```dart
const Unused();
```

#### Comment

Provides a short inline comment that appears in the outliner output.

**Target:** Class or member

##### Constructors

```dart
const Comment(this.text);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | Free-form informational metadata for downstream generators. |

### Constraints & validation

#### Min

Declares the minimum number of items required in a list field.

**Target:** Member (a `List<T>` field)

##### Constructors

```dart
const Min(this.count);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `count` | `int` | The minimum number of list entries. |

#### Max

Declares the maximum number of items allowed in a list field.

**Target:** Member (a `List<T>` field)

##### Constructors

```dart
const Max(this.count);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `count` | `int` | The maximum number of list entries. |

#### MinLength

Declares the minimum text length for a string field.

**Target:** Member

##### Constructors

```dart
const MinLength(this.length);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `length` | `int` | The minimum content length, in characters. |

#### MaxLength

Declares the maximum text length for a string field.

**Target:** Member

##### Constructors

```dart
const MaxLength(this.length);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `length` | `int` | The maximum content length, in characters. |

#### MaxDepth

Limits the maximum nesting depth of subsections within this section type.

**Target:** Class

##### Constructors

```dart
const MaxDepth(this.levels);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `levels` | `int` | The maximum subsection nesting depth; `0` marks a leaf class. |

#### AllowedTags

Restricts the set of tags that may be applied to sections of this type.

**Target:** Class

##### Constructors

```dart
const AllowedTags(this.tags);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `tags` | `List<String>` | The inline tags a text section of this type may contain. |

#### PatternCheck

Declares a regex pattern that a field value must match.

**Target:** Member

##### Constructors

```dart
const PatternCheck(this.pattern, {this.errorMessage});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `pattern` | `String` | The regular expression the field value must match. |
| `errorMessage` | `String?` | The message reported on failure. Always set it — a bare regex says what was rejected, not what was wanted. |

#### PatternCheckId

Declares a regex pattern that section IDs must match after prefix resolution.

**Target:** Class

##### Constructors

```dart
const PatternCheckId(this.pattern, {this.errorMessage});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `pattern` | `String` | The regular expression a child section id must match after prefix resolution. |
| `errorMessage` | `String?` | The message reported on failure. Always set it. |

#### ValidationPrompt

Provides an AI validation prompt for the section content.

**Target:** Class or member

##### Constructors

```dart
const ValidationPrompt(this.prompt);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `prompt` | `String` | The prompt an AI-assisted review runs against the section content. |

#### OneOf

Declares a **discriminated subsection group** (closed choice) on a container section class (`codespecs_mapping.md` §8.2, csm-7-4/csmb6).

**Target:** Class (a container)

##### Constructors

```dart
const OneOf({
  required String discriminator,
  List<Object> noCase = const [],
  String? note,
});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `discriminator` | `String` | The name of the `@Form` field (a model enum) whose value selects the active alternative. |
| `noCase` | `List<Object>` | The discriminator constants that **deliberately bind no case** — kinds whose whole surface is the common subsections, so there is no per-kind payload to promote. |
| `note` | `String?` | Optional explanation of the closed choice this group models. |

#### Case

Binds one complex-subsection field of a [OneOf] container to a discriminator value (`codespecs_mapping.md` §8.2, csm-7-4/csmb6).

**Target:** Member (repeatable)

##### Constructors

```dart
const Case(this.value);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `value` | `Object` | The discriminator enum constant this subsection is bound to. |

### Cross-reference & traceability

#### Reference

Declares a field as a reference to data owned elsewhere in the model tree.

**Target:** Member

##### Constructors

```dart
const Reference(this.description);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `description` | `String` | What the referenced data is, and why this section points at it. |

#### AccessKey

The key a section is reached by in the DocSpecs access API.

**Target:** Member (top-level sections only)

##### Constructors

```dart
const AccessKey(this.key);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | The key the section is reached by in the DocSpecs access API, overriding its section-type name. |

#### ForEach

Declares a bidirectional "for-each" constraint between a list field and a registry section type.

**Target:** Member (top-level sections only)

##### Constructors

```dart
const ForEach(this.registryType, this.key);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `registryType` | `String` | The **section id** of the registry this list must correspond to 1:1. |
| `key` | `String` | The registry entry key each list entry is matched against. |

#### MapsTo

Marks a Solution Blueprint section class as the 1:1 mapping point to the named Phase 3 DocSpec document.

**Target:** Class

##### Constructors

```dart
const MapsTo(this.documentClass);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `documentClass` | `Type` | The Phase 3 DocSpec document class that this section maps to. |

#### DetailedIn

Marks a Solution Blueprint section class as one whose content is taken over as a top-level entry in the named Phase 3 DocSpec document.

**Target:** Class

##### Constructors

```dart
const DetailedIn(this.documentClass);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `documentClass` | `Type` | The Phase 3 DocSpec document class that details this section. |

#### StandardReferences

Records the public standard(s) a section or field is derived from, plus a short statement of what the section means.

**Target:** Class or member

##### Constructors

```dart
const StandardReferences(this.standards, this.connotation);
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `standards` | `List<String>` | The public standards this section/field derives from. |
| `connotation` | `String` | What this section means (intent / ownership), distinct from the author-facing guidance in [ContentHelp] / the `@Form` field `hint:`. |

### Artifact routing

#### CodeSpecKind

The general, type-level half of the DocSpecs ↔ CodeSpecs link (`codespecs_mapping.md` §9.1).

**Target:** Class

##### Constructors

```dart
const CodeSpecKind(this.kinds, {this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `kinds` | `List<CodeSpecPart>` | The CodeSpecs part(s) this section type (or form field) must be realised as. |
| `note` | `String?` | Optional explanation of the general influence (why/how this section type shapes the named CodeSpecs part(s)). |

#### FollowUpKind

The follow-up taxonomy tag for a SOM follow-up subtree (`codespecs_mapping.md` §8.3).

**Target:** Class

##### Constructors

```dart
const FollowUpKind(this.processes, {this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `processes` | `List<FollowUpProcess>` | The downstream follow-up process(es) this subtree feeds. |
| `note` | `String?` | Optional explanation of what the subtree contributes to the named process(es). |

#### NoArtifact

The third routing verdict: this section feeds **no** downstream artifact (`codespecs_mapping.md` §8.3).

**Target:** Class

##### Constructors

```dart
const NoArtifact(this.reason, {this.note});
```

##### Properties

| Property | Type | Description |
|----------|------|-------------|
| `reason` | `NoArtifactReason` | Why the section produces no artifact. |
| `note` | `String?` | Optional explanation — for [NoArtifactReason.overview] and [NoArtifactReason.view], where the material *is* specified, a pointer to where it is specified normatively. |

#### CodeSpecsProjection

Marks a `@Document` root as the **CodeSpecs generation projection**.

**Target:** Class (a `@Document` root)

##### Constructors

```dart
const CodeSpecsProjection();
```

## Enums

### CodeSpecPart

The finalized catalogue of CodeSpecs "parts" (`codespecs_mapping.md` §4.1).

**Values (28):** `screenElement`, `form`, `layout`, `text`, `validation`, `action`, `serverCall`, `serverApi`, `serviceUnit`, `dataAccess`, `viewState`, `navigation`, `authorization`, `errorResult`, `domainEnum`, `serverConfiguration`, `clientConfiguration`, `userSettings`, `deviceSettings`, `client`, `authentication`, `identity`, `schemaMigration`, `workflow`, `notification`, `backgroundJob`, `auditLog`, `reporting`

### FollowUpProcess

The follow-up-taxonomy vocabulary (`codespecs_mapping.md` §8.3).

**Values (9):** `doc`, `trn`, `org`, `ops`, `cap`, `cmp`, `mig`, `l10n`, `acc`

### NoArtifactReason

Why a section is deliberately routed to neither CodeSpecs nor a follow-up process (`codespecs_mapping.md` §8.3).

**Values (3):** `container`, `overview`, `view`

