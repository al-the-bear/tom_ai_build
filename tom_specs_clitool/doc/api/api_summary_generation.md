# TomSpecs CLI Tool API Reference: Generation

The generation machinery: the config block, the nine per-language emitter
triples, the schema generators, the ops-registry builder, the metadata tree
and the packaging renderers.

For task-oriented guidance see [generating.md](../generating.md). For what is
emitted per language, see
[`som_multiplatform_spec_model.md`](../../../tom_specs_model/doc/som_multiplatform_spec_model.md)
§5.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [SpecObjectModelConfigException](#specobjectmodelconfigexception)
  - [SomLanguageTarget](#somlanguagetarget)
  - [SpecObjectModelConfig](#specobjectmodelconfig)
  - [MetaContentType](#metacontenttype)
  - [MetaFormField](#metaformfield)
  - [MetaFormInfo](#metaforminfo)
  - [MetaDocumentInfo](#metadocumentinfo)
  - [MetaExtraAnnotation](#metaextraannotation)
  - [MetaNode](#metanode)
  - [MetaTreeBuilder](#metatreebuilder)
  - [DocSpecsSchemaGenerator](#docspecsschemagenerator)
  - [DocspecsYamlSchemaGenerator](#docspecsyamlschemagenerator)
  - [DocSpecsAnnotationBinding](#docspecsannotationbinding)
  - [AnnotationCatalogueCorrespondence](#annotationcataloguecorrespondence)
  - [SbpPath](#sbppath)
  - [SpecOpsGenerator](#specopsgenerator)
  - [SpecOpsResult](#specopsresult)
  - [PackagingRoute](#packagingroute)
  - [PackagingDescriptor](#packagingdescriptor)
  - [PackagingExample](#packagingexample)
  - [PackagingUsage](#packagingusage)
  - [FacadeDocumentRoot](#facadedocumentroot)
  - [FacadeSurface](#facadesurface)
- [Enums](#enums)
  - [SomLanguage](#somlanguage)
  - [MetaNodeKind](#metanodekind)
  - [SomStructuralMember](#somstructuralmember)
  - [ModelOnlyReason](#modelonlyreason)
  - [DocSpecsOwner](#docspecsowner)
  - [ManifestFormat](#manifestformat)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **23 classes** and **6 enums** across 10 source file(s).

| Source file | Holds |
|-------------|-------|
| `spec_object_model_config.dart` | The generator config block — `SpecObjectModelConfigException`, `SomLanguageTarget`, `SpecObjectModelConfig`, `SomLanguage` |
| `meta_tree.dart` | The language-neutral metadata tree — `MetaContentType`, `MetaFormField`, `MetaFormInfo`, `MetaDocumentInfo`, `MetaExtraAnnotation`, `MetaNode`, `MetaTreeBuilder`, `MetaNodeKind` |
| `som_structural_accessors.dart` | The structural-accessor surface — `SomStructuralMember` |
| `spec_model_meta_validator.dart` | The emitted-meta validator — *(no public types)* |
| `docspecs_schema_generator.dart` | The DocSpecs schema generator — `DocSpecsSchemaGenerator` |
| `docspecs_yaml_schema_generator.dart` | The YAML schema generator — `DocspecsYamlSchemaGenerator` |
| `docspecs_annotation_mapping.dart` | The annotation/schema correspondence — `DocSpecsAnnotationBinding`, `AnnotationCatalogueCorrespondence`, `ModelOnlyReason`, `DocSpecsOwner` |
| `spec_ops_generator.dart` | The ops-registry generator — `SbpPath`, `SpecOpsGenerator` |
| `spec_ops_build.dart` | The ops-registry build helper — `SpecOpsResult` |
| `packaging.dart` | The per-language packaging renderers — `PackagingRoute`, `PackagingDescriptor`, `PackagingExample`, `PackagingUsage`, `FacadeDocumentRoot`, `FacadeSurface`, `ManifestFormat` |

## Class Hierarchy

```
Object
├── SpecObjectModelConfigException  implements Exception
├── SomLanguageTarget
├── SpecObjectModelConfig
├── MetaContentType
├── MetaFormField
├── MetaFormInfo
├── MetaDocumentInfo
├── MetaExtraAnnotation
├── MetaNode
├── MetaTreeBuilder
├── DocSpecsSchemaGenerator
├── DocspecsYamlSchemaGenerator
├── DocSpecsAnnotationBinding
├── AnnotationCatalogueCorrespondence
├── SbpPath
├── SpecOpsGenerator
├── SpecOpsResult
├── PackagingRoute
├── PackagingDescriptor
├── PackagingExample
├── PackagingUsage
├── FacadeDocumentRoot
└── FacadeSurface
```

## Classes

### SpecObjectModelConfigException

Raised when the `tom-spec-object-model` config block is malformed — an unknown/duplicate language, an empty target set, a wrong-typed value, or a missing top-level block in a YAML document.

**implements Exception**

#### Constructors
```dart
SpecObjectModelConfigException(this.message);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | What went wrong, in one sentence. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SomLanguageTarget

One generation target: a [language] and the **output root** the generated `tom_som_<slug>_<label>` project is written into (an explicit `output:` override, or the default `<output-base>/tom_som_<slug>_<label>`).

#### Constructors
```dart
const SomLanguageTarget({required this.language, required this.outputRoot});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `language` | `SomLanguage` | The SOM language this target generates. |
| `outputRoot` | `String` | Where the generated project is written, relative to the config file. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecObjectModelConfig

The typed `tom-spec-object-model` config: which languages to generate, where each lands, the version label (`v0`), and which document roots to generate.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | What went wrong, in one sentence. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### MetaContentType

`@ContentType(type, description)` — or the implied content type of a known section type (`TextSection` → `text`, …) with an empty description.

#### Constructors
```dart
const MetaContentType(this.type, [this.description = '']);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | The declared type. |
| `description` | `String` | The declared description. |

### MetaFormField

One `Field(...)` entry of a `@Form([...])` annotation.

#### Constructors
```dart
const MetaFormField({
  required this.name,
  required this.typeName,
  this.description,
  this.required = false,
  this.hint,
  required this.order,
  this.enumValues = const [],
  this.refersTo = const [],
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The declared name. |
| `typeName` | `String` | The declared Dart type name. |
| `description` | `String?` | Human-readable display label of the field; null when absent. |
| `required` | `bool` | Whether the field is required (`Field.required`). |
| `hint` | `String?` | Optional hint text guiding valid values/formats; null when absent. |
| `order` | `int` | The field's 0-based position within the `@Form` field list. |
| `enumValues` | `List<String>` | Enum constant names when [typeName] is a model enum (YRD7); empty for non-enum field types. |
| `refersTo` | `List<String>` | The registry key(s) this field's value is an id drawn from, each written `<SECTIONID>.<formFieldName>` (csrb3). |

### MetaFormInfo

`@Form([...])` metadata for a `kind == form` node.

#### Constructors
```dart
const MetaFormInfo(this.fields);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `fields` | `List<MetaFormField>` | The declared fields, in source order. |

### MetaDocumentInfo

`@Document(name, description, basedOn)` — present on document root nodes.

#### Constructors
```dart
const MetaDocumentInfo({
  required this.name,
  required this.description,
  this.basedOn = const [],
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The declared name. |
| `description` | `String` | The declared description. |
| `basedOn` | `List<String>` | Class names of the upstream documents this one is based on. |

### MetaExtraAnnotation

A captured annotation without a dedicated slot (SOM §7.1: `extra`), kept losslessly as its name plus the analyzer-resolved constant arguments.

#### Constructors
```dart
const MetaExtraAnnotation(this.name, [this.arguments = const {}]);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The declared name. |
| `arguments` | `Map<String, Object?>` | The annotation arguments, keyed by parameter name. |

### MetaNode

One node of the canonical metadata tree (SOM §7.1).

#### Constructors
```dart
const MetaNode({
  required this.className,
  this.memberName,
  this.sectionId,
  this.sectionIdPattern,
  required this.kind,
  required this.typeName,
  this.serializationOrder,
  this.min,
  this.unused = false,
  this.contentType,
  this.contentHelp,
  this.headline,
  this.comment,
  this.docComment,
  this.classDocComment,
  this.form,
  this.document,
  this.mapsTo,
  this.detailedIn,
  this.enumValues = const [],
  this.extra = const [],
  this.recursive = false,
  this.children = const [],
  this.elementNode,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `className` | `String` | Exact model class name backing this node (`IntroductionAndScope`), or the scalar/section type name for leaves (`String`, `TextSection`). |
| `memberName` | `String?` | Exact field name in the parent class; null on the document root and on list element nodes. |
| `sectionId` | `String?` | Effective `@SectionId` (field-level wins over class-level). |
| `sectionIdPattern` | `String?` | `@SectionIdPattern` on the field (list element ids). |
| `kind` | `MetaNodeKind` | The declared kind. |
| `typeName` | `String` | Dart type name of the field/class (`String`, `GoalEntry`, `List<GoalEntry>`, …). |
| `unused` | `bool` | Whether `@Unused` is present (field- or class-level). |
| `contentType` | `MetaContentType?` | The node's declared content format, or `null` when it declares none. |
| `contentHelp` | `String?` | `@ContentHelp(guidance)`. |
| `headline` | `String?` | `@Headline(text)` — the predefined DEFAULT headline (YRD4). |
| `comment` | `String?` | `@Comment(text)`. |
| `docComment` | `String?` | Cleaned `///` doc comment; the member's wins over the class's. |
| `classDocComment` | `String?` | The class doc comment, carried additionally when it exists and differs from [docComment] (SOM §7.1 note). |
| `form` | `MetaFormInfo?` | Present for `kind == form`. |
| `document` | `MetaDocumentInfo?` | Present on document root nodes only. |
| `mapsTo` | `String?` | `@MapsTo` target class name. |
| `detailedIn` | `String?` | `@DetailedIn` target class name. |
| `enumValues` | `List<String>` | Enum constant names for `kind == enumValue`. |
| `extra` | `List<MetaExtraAnnotation>` | Annotations without a dedicated slot, kept losslessly. |
| `recursive` | `bool` | True when this class already appeared on the descent stack: the node is a reference (`kind == complex`, no [children]) breaking the cycle. |
| `children` | `List<MetaNode>` | Child nodes in `@SerializationOrder` order (declaration order fallback). |
| `elementNode` | `MetaNode?` | For `kind == list`: the element class subtree. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `walk()` | `Iterable<MetaNode>` | Depth-first pre-order walk over this node, its [children], and (for lists) the [elementNode] subtree. |
| `toJson()` | `Map<String, Object?>` | Deterministic JSON-ready projection (stable key order, sparse: absent slots are omitted). |

### MetaTreeBuilder

Builds [MetaNode] trees from the resolved [ModelClass] graph.

#### Constructors
```dart
MetaTreeBuilder(this.classes, {this.enums = const {}});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `classes` | `Map<String, ModelClass>` | The resolved classes, keyed by name. |
| `enums` | `Map<String, ModelEnum>` | The resolved enums, keyed by name. |
| `children` | `List<MetaNode>` | The child nodes, in serialization order. |
| `elementNode` | `MetaNode?` | For a list node, the element's node; `null` otherwise. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `buildAllDocumentRoots()` | `Map<String, MetaNode>` | Builds the tree for every `@Document`-annotated root class, keyed by root class name. |
| `build(String rootClassName)` | `MetaNode` | Builds the fully-expanded tree rooted at [rootClassName]. |
| `classifyField(ModelField f)` | `MetaNodeKind` | Classifies a field into its SOM §7.1 kind. |

### DocSpecsSchemaGenerator

Generates DocSpecs schemas (`*.docspecs-schema.yaml`) from the canonical The metadata tree ([MetaTreeBuilder]/[MetaNode]), applying the SOM §13 generation rules (SOM §13).

#### Constructors
```dart
DocSpecsSchemaGenerator(this.classes, {this.enums = const {}});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `classes` | `Map<String, ModelClass>` | The full resolved class graph (as produced by [ModelReader]). |
| `enums` | `Map<String, ModelEnum>` | Enum registry, forwarded to the [MetaTreeBuilder]. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toYamlString(DocSpecSchema schema)` | `String` | Serialises a schema to YAML text for writing to `.tom/docspecs-schema/`. |
| `fileNameFor(DocSpecSchema schema)` | `String` | The on-disk filename for a schema (e.g. |

### DocspecsYamlSchemaGenerator

Generates a standalone JSON Schema (Draft-07) for the on-disk `*.docspecs.yaml` **document wire format**.

#### Constructors
```dart
DocspecsYamlSchemaGenerator({int? formatVersion})
    : formatVersion = formatVersion ?? SpecDocumentYaml.formatVersion;
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `formatVersion` | `int` | The on-disk format version the schema targets. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `generate()` | `Map<String, Object?>` | Builds the Draft-07 JSON Schema as a plain JSON-encodable map. |
| `toJsonString()` | `String` | The emitted schema as pretty-printed, newline-terminated JSON text. |

### DocSpecsAnnotationBinding

One annotation's declared destination in a generated DocSpecs schema.

#### Constructors
```dart
const DocSpecsAnnotationBinding(
  this.annotation, {
  this.schemaKey,
  this.owner,
  this.modelOnly,
  required this.note,
})  : assert(
        (schemaKey == null) != (modelOnly == null),
        'A binding is either schema-bound (schemaKey) or model-only '
        '(modelOnly) — exactly one.',
      ),
      assert(
        schemaKey == null || owner != null,
        'A schema-bound binding names the schema object that owns the key.',
      );
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `annotation` | `String` | The annotation class name as declared in `tom_specs_core`. |
| `schemaKey` | `String?` | The DocSpecs YAML key this annotation feeds (e.g. |
| `owner` | `DocSpecsOwner?` | The `tom_doc_specs` schema object that owns [schemaKey] — the block a reader should look in (`section-types` entry, `document.sections` entry, …). |
| `modelOnly` | `ModelOnlyReason?` | Why the annotation has no schema counterpart; null when schema-bound. |
| `note` | `String` | How the value is derived, or what the annotation does instead. |

### AnnotationCatalogueCorrespondence

The result of diffing the declared bindings against the annotation classes `tom_specs_core` actually declares.

#### Constructors
```dart
AnnotationCatalogueCorrespondence({
  required this.declared,
  required this.bound,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `declared` | `Set<String>` | Annotation class names found in `tom_specs_core/lib/src/annotations/`. |
| `bound` | `Set<String>` | Annotation names named by [docSpecsAnnotationBindings]. |
| `undeclaredDestination` | `Set<String> get` | Declared in `tom_specs_core` but absent from the mapping table — an annotation with no decision about what it means downstream. |
| `staleBinding` | `Set<String> get` | Named by the mapping table but no longer declared — a stale binding. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `describeMismatch()` | `String?` | A human-readable failure report, or null when consistent. |

### SbpPath

One field reachable from the Solution Blueprint root by a static member chain: its dotted [path], its own [member] name (the tie-breaker when a type occurs more than once), the Dart [expr]ession that reads it from the local `b`, and whether that expression can yield null.

#### Constructors
```dart
const SbpPath(this.path, this.expr, this.nullable);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The path this binding writes to. |
| `expr` | `String` | The Dart expression that reads the value. |
| `nullable` | `bool` | Whether the read expression can yield null. |
| `member` | `String get` | The last segment of [path] — the field's own member name. |

### SpecOpsGenerator

Emits the `spec_ops.g.dart` registry that adopts the snapshot/serialization contract across every TomSpecs model class **without editing their source** (OE-2).

#### Constructors
```dart
SpecOpsGenerator(this.classes);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `classes` | `Map<String, ModelClass>` | The resolved classes, keyed by name. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `generate()` | `String` | Emits this artefact and returns what it wrote. |

### SpecOpsResult

What one [generateSpecOpsRegistry] run produced.

#### Constructors
```dart
const SpecOpsResult({
  required this.outputPath,
  required this.classCount,
  required this.changed,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `outputPath` | `String` | Where the registry was written. |
| `classCount` | `int` | Model classes the reader resolved — the registry's input size. |
| `changed` | `bool` | Whether the emitted source differs from what was already on disk. |

### PackagingRoute

One documented way to add the library as a dependency (registry, git, path, vendored, …) rendered into `readme_howtointegrate.md`.

#### Constructors
```dart
const PackagingRoute({required this.heading, required this.body});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `heading` | `String` | The route's sub-heading (e.g. |
| `body` | `String` | The route's markdown body (commands / snippet). |

### PackagingDescriptor

The per-language data the shared renderers and hooks consume.

#### Constructors
```dart
const PackagingDescriptor({
  required this.language,
  required this.displayName,
  required this.runtimePackageName,
  required this.facadePackageName,
  required this.codeFence,
  required this.installShort,
  required this.usageSnippet,
  required this.integrateRoutes,
  required this.buildFromSource,
  required this.buildArtifactIgnores,
  required this.runtimeManifestFileName,
  required this.runtimeManifestFormat,
  required this.manifestDescription,
  required this.manifestDescriptionFile,
  required this.whereThisFitsSentence,
  required this.tutorialSentence,
  required this.exampleDirName,
  required this.examples,
  required this.usageSections,
  required this.verifyCommand,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `language` | `SomLanguage` | The SOM language this describes. |
| `displayName` | `String` | Human-readable language name for prose (e.g. |
| `runtimePackageName` | `String` | The runtime package's ecosystem name (e.g. |
| `facadePackageName` | `String` | The generated facade package's ecosystem name. |
| `codeFence` | `String` | The fenced-code-block language tag for snippets (e.g. |
| `installShort` | `String` | The one-line "add the dependency" command shown in the README short block. |
| `usageSnippet` | `String` | A minimal usage snippet (loads a document, reads a section). |
| `integrateRoutes` | `List<PackagingRoute>` | The dependency routes rendered into `readme_howtointegrate.md`. |
| `buildFromSource` | `String` | The command(s) that build/pack the library from source. |
| `buildArtifactIgnores` | `List<String>` | The build-artifact globs to keep out of version control. |
| `runtimeManifestFileName` | `String` | The runtime manifest file whose version is realigned to the model version. |
| `runtimeManifestFormat` | `ManifestFormat` | The runtime manifest's format (drives [rewriteManifestVersion]). |
| `manifestDescription` | `String` | The facade manifest's own `description`, reproduced verbatim as the README's one-line description (`tom_specs_documentation_standard.md` §2.1 row 3). |
| `manifestDescriptionFile` | `String` | The file inside the facade package that carries [manifestDescription] — the package manifest for the registry languages, the pkg-config `Description:` line in the `Makefile` for C and C++, the package doc comment for Go. |
| `whereThisFitsSentence` | `String` | The language-specific closing sentence of the README's "Where this fits" paragraph (`tom_specs_documentation_standard.md` §2.3) — what this ecosystem's reader most needs to know about how the facade behaves here. |
| `tutorialSentence` | `String` | One sentence describing this language's hand-written `doc/tutorial.md`, rendered into the README's cross-link block. |
| `exampleDirName` | `String` | The examples directory's name — `example` where the ecosystem's tooling expects the singular (Dart/pub), `examples` elsewhere. |
| `examples` | `List<PackagingExample>` | The runnable samples, rendered as the README's Examples table. |
| `usageSections` | `List<PackagingUsage>` | The README's `## Usage` sub-sections, in order. |
| `verifyCommand` | `String` | The command(s) that build and verify the facade package against the shared conformance corpus — the README's `## Status` answer in place of a fixed test count a generated file could never keep true. |

### PackagingExample

One runnable sample in the facade package's hand-written examples tree, rendered as a row of the README's Examples table (`tom_specs_documentation_standard.md` §2.1 row 9).

#### Constructors
```dart
const PackagingExample({required this.file, required this.demonstrates});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `file` | `String` | The sample's path relative to the examples directory (e.g. |
| `demonstrates` | `String` | What the sample shows — the table's second column. |

### PackagingUsage

One `## Usage` sub-section: a capability, one sentence of context, and a short runnable block (`tom_specs_documentation_standard.md` §2.1 row 10).

#### Constructors
```dart
const PackagingUsage({
  required this.heading,
  required this.intro,
  required this.snippet,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `heading` | `String` | The sub-section heading (e.g. |
| `intro` | `String` | One or two sentences placing the snippet. |
| `snippet` | `String` | The runnable block, rendered in the descriptor's [PackagingDescriptor.codeFence]. |

### FacadeDocumentRoot

One `@Document` root of the generated facade, read back from the meta-data file the emitter has just written.

#### Constructors
```dart
const FacadeDocumentRoot({
  required this.type,
  required this.sectionId,
  required this.title,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | The generated root type's name (`D00SolutionBlueprint`). |
| `sectionId` | `String` | The root's section id, the first segment of every path beneath it. |
| `title` | `String` | The document's human title. |

### FacadeSurface

The generated surface a facade README reports: its document roots and its class count.

#### Constructors
```dart
const FacadeSurface({required this.roots, required this.classCount});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `roots` | `List<FacadeDocumentRoot>` | Every `@Document` root the facade generates, in model order. |
| `classCount` | `int` | The number of generated classes across all roots. |

## Enums

### SomLanguage

A language the SOM (specification object model) generator can target.

| Value | Meaning |
|-------|---------|
| `dart` | Dart (pub). |
| `java` | Java (Maven). |
| `javascript` | JavaScript (npm). |
| `typescript` | TypeScript (npm, compiled `dist/`). |
| `go` | Go (module path + VCS tag). |
| `rust` | Rust (Cargo crate). |
| `c` | C (Makefile + pkg-config). |
| `cpp` | C++ (Makefile + pkg-config). |
| `python` | Python (PEP 517). |

### MetaNodeKind

Field/section render kind (SOM §7.1: list | form | section | content | enum | complex | scalar).

| Value | Meaning |
|-------|---------|

### SomStructuralMember

A structural member of the runtime `SomNode` that every generated facade carries, independent of the model.

| Value | Meaning |
|-------|---------|
| `doc` | The bound generic document (`doc`). |
| `path` | The bound section path (`path`). |
| `sectionId` | The list-item section id (`$sectionId` / `SectionID` / `spec_section_id`). |
| `headline` | The stored headline (YRD3). |
| `codeSpec` | The CodeSpecs forward link (`codespecs_mapping.md` §9.2). |
| `isEmpty` | The "is this subtree empty *now*?" state predicate (SOM §21). |
| `canHaveContent` | The "*can* this section type hold body text?" schema predicate (SOM §21). |

### ModelOnlyReason

Why an annotation has no DocSpecs schema counterpart.

| Value | Meaning |
|-------|---------|
| `traceability` | Describes how the model maps onto other documents or onto CodeSpecs — a statement about the model, not about an instance document. |
| `generation` | Governs code generation across the nine language runtimes (member order, discriminated groups, projection markers). |
| `structural` | Consumed by the generator to *shape* the schema rather than to fill a property — the annotation's effect is structural (a section vanishes, a name is derived) and leaves no property of its own. |

### DocSpecsOwner

The schema block that owns a [DocSpecsAnnotationBinding.schemaKey].

| Value | Meaning |
|-------|---------|
| `sectionType` | A `section-types:` entry (`SectionTypeDef`). |
| `subsectionConstraint` | A `subsection-types:` entry of a section type (`SubsectionConstraint`). |
| `formField` | A `form-types:` field (`FormFieldDef`). |
| `documentSection` | A `document: sections:` entry (`SectionDef`). |
| `subsectionDeclaration` | A `subsection-declarations:` entry (`SubsectionDef`). |
| `schema` | A top-level schema property or custom tag (`DocSpecSchema`). |

### ManifestFormat

The manifest a runtime package uses to declare its own version.

| Value | Meaning |
|-------|---------|
| `pubspec` | `pubspec.yaml` — `version: X.Y.Z`. |
| `pyproject` | `pyproject.toml` — `version = "X.Y.Z"` (PEP 621 `[project]`). |
| `packageJson` | `package.json` — `"version": "X.Y.Z"`. |
| `cargoToml` | `Cargo.toml` — `version = "X.Y.Z"` in `[package]`. |
| `goVersionConst` | A Go source version constant — `Version = "vX.Y.Z"` (Go versions live in VCS tags, so the module carries an in-source constant instead). |
| `makefileVar` | A `Makefile` variable — `VERSION := X.Y.Z` (C / C++, no registry). |
| `pomXml` | A Maven `pom.xml` — the project `<version>X.Y.Z</version>` element. |

## Global Functions and Constants
