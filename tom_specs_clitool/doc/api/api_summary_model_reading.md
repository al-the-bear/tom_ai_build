# TomSpecs CLI Tool API Reference: Model Reading

The analyzer-backed reader that resolves `tom_specs_model`'s source into a
class graph, and everything built directly on it: the outline writer, the
JSON exporter, the static validator, the version stamps and the freshness
fingerprint.

For task-oriented guidance see
[inspecting_the_model.md](../inspecting_the_model.md). For the rules the
validator enforces, see
[`tom_specs_model_rules.md`](../../../tom_specs_model/doc/tom_specs_model_rules.md)
§10.2.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [AnnotationData](#annotationdata)
  - [FormFieldInfo](#formfieldinfo)
  - [ModelField](#modelfield)
  - [ModelClass](#modelclass)
  - [ModelEnum](#modelenum)
  - [ModelReader](#modelreader)
  - [ModelVersionStamp](#modelversionstamp)
  - [ModelVersionStampException](#modelversionstampexception)
  - [ModelJsonStamp](#modeljsonstamp)
  - [ModelJsonExporter](#modeljsonexporter)
  - [ModelSurface](#modelsurface)
  - [LibrarySurface](#librarysurface)
  - [OutlineWriter](#outlinewriter)
  - [InvariantCitation](#invariantcitation)
  - [InvariantEntry](#invariantentry)
  - [InvariantCorrespondence](#invariantcorrespondence)
  - [SerializationStampResult](#serializationstampresult)
  - [EntrypointOption](#entrypointoption)
  - [EntrypointRow](#entrypointrow)
  - [EntrypointCorrespondence](#entrypointcorrespondence)
- [Enums](#enums)
  - [ModelJsonTarget](#modeljsontarget)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **20 classes** and **1 enums** across 11 source file(s).

| Source file | Holds |
|-------------|-------|
| `analyzer_bootstrap.dart` | Analyzer driver construction — *(no public types)* |
| `model_reader.dart` | The class-graph reader — `AnnotationData`, `FormFieldInfo`, `ModelField`, `ModelClass`, `ModelEnum`, `ModelReader` |
| `model_version_stamp.dart` | The model version stamp — `ModelVersionStamp`, `ModelVersionStampException` |
| `model_json_target.dart` | Committed-asset targets — `ModelJsonStamp`, `ModelJsonTarget` |
| `model_json_exporter.dart` | The JSON class-graph exporter — `ModelJsonExporter` |
| `model_freshness.dart` | The model-surface fingerprint — `ModelSurface`, `LibrarySurface` |
| `outline_writer.dart` | The outline renderer — `OutlineWriter` |
| `validator.dart` | The static structural validator — *(no public types)* |
| `invariant_correspondence.dart` | The `tom_specs_model_rules.md` §10.2 invariant correspondence — `InvariantCitation`, `InvariantEntry`, `InvariantCorrespondence` |
| `serialization_order.dart` | The @SerializationOrder stamper — `SerializationStampResult` |
| `entrypoint_options.dart` | The bin/ option correspondence — `EntrypointOption`, `EntrypointRow`, `EntrypointCorrespondence` |

## Class Hierarchy

```
Object
├── AnnotationData
├── FormFieldInfo
├── ModelField
├── ModelClass
├── ModelEnum
├── ModelReader
├── ModelVersionStamp
├── ModelVersionStampException  implements Exception
├── ModelJsonStamp
├── ModelJsonExporter
├── ModelSurface
├── LibrarySurface
├── OutlineWriter
├── InvariantCitation
├── InvariantEntry
├── InvariantCorrespondence
├── SerializationStampResult
├── EntrypointOption
├── EntrypointRow
└── EntrypointCorrespondence
```

## Classes

### AnnotationData

Annotation data extracted from the analyzer element model.

#### Constructors
```dart
AnnotationData(this.name, [this.arguments = const {}]);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The declared name. |
| `arguments` | `Map<String, Object?>` | The annotation arguments, keyed by parameter name. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### FormFieldInfo

A form field extracted from a `@Form([Field(...)])` annotation.

#### Constructors
```dart
FormFieldInfo({
  required this.name,
  required this.typeName,
  this.description = '',
  this.required = false,
  this.hint = '',
  this.enumValues = const [],
  this.refersTo = const [],
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The declared name. |
| `typeName` | `String` | The declared Dart type name. |
| `description` | `String` | The declared description. |
| `required` | `bool` | Whether the field is declared required. |
| `hint` | `String` | Optional hint text guiding valid values/formats for this form field. |
| `enumValues` | `List<String>` | Enum constant names when [typeName] is a model enum (YRD7); empty for non-enum field types. |
| `refersTo` | `List<String>` | The registry key(s) this field's value is an id drawn from, each `<SECTIONID>.<formFieldName>` (csrb3). |

### ModelField

A resolved field from a model class.

#### Constructors
```dart
ModelField({
  required this.name,
  required this.typeName,
  this.isList = false,
  this.isNullable = false,
  this.isEnum = false,
  this.enumValues = const [],
  this.annotations = const [],
  this.listElementTypeName,
  this.listElementIsComplex = false,
  this.isSectionType = false,
  this.isContentSection = false,
  this.listElementIsContentSection = false,
  this.sectionContentType,
  this.formFields = const [],
  this.docComment = '',
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The declared name. |
| `typeName` | `String` | The declared Dart type name. |
| `isList` | `bool` | Whether the field is a `List<T>`. |
| `isNullable` | `bool` | Whether the field's declared type is nullable. |
| `isEnum` | `bool` | Whether the field's type is a model enum. |
| `enumValues` | `List<String>` | The enum's value names when `isEnum`, otherwise empty. |
| `annotations` | `List<AnnotationData>` | The annotations on this declaration. |
| `listElementTypeName` | `String?` | For list fields, the inner type name. |
| `listElementIsComplex` | `bool` | Whether the inner type of a list is a complex (class) type. |
| `isSectionType` | `bool` | Whether this field's type is a known section type (TextSection, etc.). |
| `isContentSection` | `bool` | Whether this field's declared type is `DocSpecsSection` (YRD5): the universal simple-section base type from `tom_specs_core` that replaced the former `String` section members of the model. |
| `listElementIsContentSection` | `bool` | Whether the inner type of a list is `DocSpecsSection` (the YRD5 replacement of `List<String>` inline content lists). |
| `sectionContentType` | `String?` | The content type marker for section types (e.g., 'text', 'mermaid-er'). |
| `formFields` | `List<FormFieldInfo>` | Form fields extracted from a `@Form` annotation on this field. |
| `docComment` | `String` | The cleaned doc-comment text on the field declaration, if any. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `getAnnotation(String name)` | `AnnotationData?` | The annotation with the given name, or `null`. |

### ModelClass

A resolved model class.

#### Constructors
```dart
ModelClass({
  required this.name,
  this.fields = const [],
  this.annotations = const [],
  this.docComment = '',
  this.formFields = const [],
  this.extendsDocSpecsSection = false,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The declared name. |
| `fields` | `List<ModelField>` | The declared fields, in source order. |
| `annotations` | `List<AnnotationData>` | The annotations on this declaration. |
| `docComment` | `String` | The cleaned doc-comment text on the class declaration, if any. |
| `formFields` | `List<FormFieldInfo>` | Form fields extracted from a class-level `@Form` annotation (form section classes such as `UserRegistrationProcess`). |
| `extendsDocSpecsSection` | `bool` | Whether this class (directly or transitively) extends the `DocSpecsSection` base type from `tom_specs_core` (YRD5). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `getAnnotation(String name)` | `AnnotationData?` | The annotation with the given name, or `null`. |

### ModelEnum

A resolved enum type.

#### Constructors
```dart
ModelEnum({required this.name, required this.values});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The declared name. |
| `values` | `List<String>` | The declared values. |

### ModelReader

Reads model classes from Dart source files using the analyzer.

#### Constructors
```dart
ModelReader(this._driver);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `classes` | `Map<String, ModelClass>` | The resolved classes, keyed by name. |
| `enums` | `Map<String, ModelEnum>` | The resolved enums, keyed by name. |
| `name` | `String?` | The declared name. |
| `typeName` | `String` | The declared Dart type name. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `analyzePackage(String packageLibPath)` | `Future<void>` | Analyzes all .dart files under [packageLibPath] and collects model classes and enums. |

### ModelVersionStamp

The model version stamp generated into `tom_specs_model` by `buildkit :versioner`.

#### Constructors
```dart
const ModelVersionStamp({
  required this.version,
  required this.buildNumber,
  required this.gitCommit,
  this.buildTime = '',
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `version` | `String` | The semantic version (e.g. |
| `buildNumber` | `int` | The monotonically increasing build counter. |
| `gitCommit` | `String` | The short git commit the build ran against; empty when unavailable. |
| `buildTime` | `String` | The ISO-8601 build timestamp; empty when the stamp does not carry one. |

### ModelVersionStampException

Thrown when the version stamp is missing or unparseable.

**implements Exception**

#### Constructors
```dart
ModelVersionStampException(this.message);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | What went wrong, in one sentence. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### ModelJsonStamp

The version stamp a `spec_model.json` export is written with.

#### Constructors
```dart
const ModelJsonStamp(this.version, this.label);
ModelJsonStamp.from(ModelVersionStamp versioner)
    : version = versioner.majorVersion,
      label = versioner.label;
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `version` | `int` | The `modelVersion` counter: the model major. |
| `label` | `String?` | The `modelVersionLabel`, or `null` when the export carries no label. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### ModelJsonExporter

Serializes the resolved [ModelClass] graph into a JSON-ready map that a UI (e.g.

#### Constructors
```dart
ModelJsonExporter(
  this.classes, {
  this.modelVersion = 0,
  this.modelVersionLabel,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `classes` | `Map<String, ModelClass>` | The resolved classes, keyed by name. |
| `modelVersion` | `int` | The S2 model-version counter (counts up as the object model changes). |
| `modelVersionLabel` | `String?` | A human-readable build label for the same stamp (e.g. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `export()` | `Map<String, Object?>` | Builds the full JSON-ready map. |

### ModelSurface

The state of `tom_specs_model` at the moment the committed `tom_som_*` packages were generated from it.

#### Constructors
```dart
const ModelSurface({
  required this.fingerprint,
  required this.fileCount,
  required this.declarationCount,
  required this.packages,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `fingerprint` | `String` | Hash over the model's rendered token stream — the single value the guard compares. |
| `fileCount` | `int` | Model source files that went into the fingerprint. |
| `declarationCount` | `int` | Top-level declarations across those files, for the same reason. |
| `packages` | `List<String>` | The generated package names this fingerprint certifies, sorted. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A JSON view of this value. |
| `fromJson(Map<String, Object?> json)` | `ModelSurface` | Reads a stamp back from its committed JSON form. |

### LibrarySurface

The fingerprint of one set of Dart source files.

#### Constructors
```dart
const LibrarySurface(this.hash, this.fileCount, this.declarationCount);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `hash` | `String` | The fingerprint of the model source this stamp was taken over. |
| `fileCount` | `int` | How many source files the fingerprint covered. |
| `declarationCount` | `int` | How many declarations the fingerprint covered. |

### OutlineWriter

Generates the outline text from the model class tree.

#### Constructors
```dart
OutlineWriter({
  required this.classes,
  this.enums = const {},
  this.maxLineLength = 120,
  this.showSchemaAnnotations = false,
  this.stopAtDetailedIn = false,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `classes` | `Map<String, ModelClass>` | The resolved classes, keyed by name. |
| `enums` | `Map<String, ModelEnum>` | The resolved enums, keyed by name. |
| `maxLineLength` | `int` | Where the renderer wraps a line. |
| `showSchemaAnnotations` | `bool` | Whether schema-only annotations are rendered inline. |
| `stopAtDetailedIn` | `bool` | When true, tree traversal stops at classes annotated with `@DetailedIn`. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `generate(String rootTypeName)` | `String` | Emits this artefact and returns what it wrote. |

### InvariantCitation

A citation naming an invariant of `tom_specs_model_rules.md` §10.2, found in some source.

#### Constructors
```dart
InvariantCitation({
  required this.id,
  required this.source,
  required this.line,
  required this.text,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The invariant id the citation names, or the ordinal it wrote instead when [isOrdinal] is true. |
| `source` | `String` | A human-readable name for the file the citation was found in. |
| `line` | `int` | 1-based line number within that file. |
| `text` | `String` | The full trimmed line, for the failure message. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### InvariantEntry

One numbered entry of the invariant list in `tom_specs_model_rules.md` §10.2.

#### Constructors
```dart
InvariantEntry(this.id, this.number, this.title);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The stable invariant id — the entry's first inline-code span, and the only thing anything is allowed to cite it by. |
| `number` | `int` | The list ordinal, as written in the markdown. |
| `title` | `String` | The entry's leading text after the id, trimmed to a single readable line. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### InvariantCorrespondence

The result of comparing the two sides, plus the corpus citation scan.

#### Constructors
```dart
InvariantCorrespondence({
  required this.entries,
  required this.tags,
  required this.citations,
  required this.undocumented,
  required this.unimplemented,
  required this.malformed,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `entries` | `List<InvariantEntry>` | The `tom_specs_model_rules.md` §10.2 entries, in document order. |
| `tags` | `List<InvariantCitation>` | Every citation found in the validator source — the tags. |
| `citations` | `List<InvariantCitation>` | Every citation found anywhere in the scanned corpus, tags included. |
| `undocumented` | `List<InvariantCitation>` | Citations naming an id `tom_specs_model_rules.md` §10.2 does not define, or written as an ordinal — a pointer at nothing, or at whatever now happens to sit in that position. |
| `unimplemented` | `List<InvariantEntry>` | Ids listed in `tom_specs_model_rules.md` §10.2 that no validator tag cites — a documented rule with no check behind it, which that section's first meta-rule calls a gap, not a rule. |
| `malformed` | `List<String>` | Entries of `tom_specs_model_rules.md` §10.2 that do not open with a well-formed id, and ids defined twice — either would make a citation ambiguous or unresolvable. |
| `definedIds` | `Set<String> get` | The ids `tom_specs_model_rules.md` §10.2 defines. |

### SerializationStampResult

Outcome of a [stampSerializationOrder] run.

#### Constructors
```dart
const SerializationStampResult({
  required this.filesChanged,
  required this.membersStamped,
  required this.membersRestamped,
  required this.multiVarWarnings,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `filesChanged` | `int` | How many source files the run rewrote (0 on a fully-stamped, unchanged model — the idempotent case). |
| `membersStamped` | `int` | How many member annotations were (re)written in total. |
| `membersRestamped` | `int` | How many pre-existing `@SerializationOrder` annotations were stripped and replaced (the renumber count). |
| `multiVarWarnings` | `List<String>` | One entry per multi-variable field declaration (`int a, b;`), which shares a single ordinal. |

### EntrypointOption

One option, flag or multi-option an entrypoint's `ArgParser` declares.

#### Constructors
```dart
const EntrypointOption({
  required this.name,
  required this.isFlag,
  required this.negatable,
  required this.mandatory,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The option name, without leading dashes. |
| `isFlag` | `bool` | Whether it was declared with `addFlag` rather than `addOption` / `addMultiOption`. |
| `negatable` | `bool` | Whether `--no-<name>` is also a valid spelling — true for an `addFlag` that is not `negatable: false`. |
| `mandatory` | `bool` | Whether the declaration is `mandatory: true`. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### EntrypointRow

One row of `README.md`'s `bin/` entrypoint table.

#### Constructors
```dart
const EntrypointRow({required this.entrypoints, required this.citedFlags});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `entrypoints` | `List<String>` | The `<name>.dart` files the first cell names. |
| `citedFlags` | `Set<String>` | Every `--flag` spelling the row cites, from any of its cells. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### EntrypointCorrespondence

The outcome of one comparison.

#### Constructors
```dart
const EntrypointCorrespondence({required this.rows, required this.problems});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `rows` | `List<EntrypointRow>` | The rows the README declares, in table order. |
| `problems` | `List<String>` | Everything wrong, one line each; empty when the two agree. |

## Enums

### ModelJsonTarget

A **committed** `spec_model.json` asset.

| Value | Meaning |
|-------|---------|
| `editor` | The spec-authoring app's bundled asset. |
| `reviewer` | The object-model review app's committed snapshot, refreshed periodically. |

## Global Functions and Constants
