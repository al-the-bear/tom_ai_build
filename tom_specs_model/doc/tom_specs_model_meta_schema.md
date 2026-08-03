# Spec-Model Meta-Data File Schema

The **spec-model meta-data file** is the lossless, resolved class graph of the
TomSpecs object model (`tom_specs_model`). It is the successor to the editor's
bundled `spec_model.json`: a single JSON document, emitted by
`ModelJsonExporter.export()` and consumed by the generic runtime's meta-model
loader (the "reflection" path) to describe, traverse, and validate any
specification document by section path.

This document defines the **on-disk schema** (format version
`metaSchemaVersion = 1`) and the validation contract enforced by
`validateSpecModelMeta`.

## Two independent version stamps

The file carries two version numbers that must never be conflated:

| Key | Meaning | Changes when |
| --- | --- | --- |
| `metaSchemaVersion` | The **file format's** own version. | The on-disk shape of *this file* changes in a way older readers cannot parse. |
| `modelVersion` / `modelVersionLabel` | **Which model version** the meta-data was generated against (the `tom_specs_model` version stamp). | The object model changes — independent of the file format. |

A reader refuses a file whose `metaSchemaVersion` is **newer** than the version
it was built for (`specModelMetaSchemaVersion`), because the structure may have
changed unreadably. `modelVersion` drives the separate document-vs-model
compatibility check (same-major newer-edits-older; older rejects newer;
cross-major read-only).

The document-side counterpart of `modelVersion` lives in each
`*.docspecs.yaml` under its own `modelVersion` key (beside the on-disk
`formatVersion`), recording the authoring model `major.minor` of that document.

## Top-level keys

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `generatedAt` | `String` (ISO-8601 UTC) | yes | Emission timestamp. |
| `metaSchemaVersion` | `int` | yes | This file format's version. Currently `1`. |
| `modelVersion` | `int` | yes | Model-version counter the export was generated against. `0` = unstamped (manual run). |
| `modelVersionLabel` | `String` | no | Human-readable model build label (e.g. `v0.7`). Omitted when unstamped. |
| `classCount` | `int` | yes | Number of entries in `classes`. |
| `rootCount` | `int` | yes | Number of entries in `roots`. |
| `containerRoot` | `String?` | no | Name of the canonical container class (the single true tree root), or `null` for a container-less model. |
| `roots` | `List` | yes | Document entry points (each `@Document` class). |
| `classes` | `Map<String, Object?>` | yes | The class graph: each class once, keyed by name. |

`modelVersionLabel` and `containerRoot` are **not** required — the label is
optional and the container root is legitimately `null`.

### `roots[]` entry

Each root is a document navigator entry point:

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | `String` | yes | Class name. |
| `title` | `String` | yes | `@Document(name:)` or a PascalCase split of `type`. |
| `sectionId` | `String` | no | The root's `@SectionId`. |
| `description` | `String` | no | `@Document(description:)` when non-empty. |
| `doc` | `String` | no | Cleaned class doc-comment when present. |

### `classes[name]` entry

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | `String` | yes | Class name. |
| `sectionId` | `String` | no | Class-level `@SectionId`. |
| `doc` | `String` | no | Cleaned class doc-comment. |
| `help` | `String` | no | `@ContentHelp(guidance:)`. |
| `headline` | `String` | no | `@Headline(text:)` — the authored display headline, distinct from the class name a consumer keys by. |
| `mapsTo` / `detailedIn` | `String` | no | Traceability targets (`@MapsTo` / `@DetailedIn`). |
| `standardReferences` | `Map` | no | `@StandardReferences` projected as `{standards: List, connotation: String}` — the public standards the class derives from and what it means. |
| `annotations` | `List` | no | **Lossless** annotation list (`{name, arguments}` per annotation) — every annotation `ModelReader` captured, source order preserved. Omitted when empty. |
| `fields` | `List` | yes | The class's fields. |

The curated keys (`sectionId`, `mapsTo`, `detailedIn`, `help`, …) are a
redundant projection of the `annotations` block, kept for the editor tree; the
`annotations` block is the lossless source the generic runtime reads.

### `fields[]` entry

Always carries `name` and a render `kind` (`list`, `form`, `section`,
`content`, `enum`, `complex`, `scalar`), plus `serializationOrder` (the field's
0-based `@SerializationOrder` ordinal, driving on-disk member order) whenever the
model has been stamped; kind-specific keys follow (`elementType` + `elementIsComplex` and optional `min`
for lists, `formFields` for forms, `contentType` for sections/content plus
`sectionType` — the section's declared class name, `?` stripped — for sections,
`enumType`/`enumValues` for enums, `type` for complex/scalar). `elementIsComplex`
tells a consumer whether `elementType` names a model class to resolve or a scalar
to render directly, without it having to look the name up.

A field also carries its own lossless `annotations` block (omitted when empty),
plus curated `sectionId` / `sectionIdPattern` / `headline` / `help` /
`standardReferences` when present. `sectionId` and `sectionIdPattern` are
independent: a list field routinely carries both — its own id and the id pattern
its items take — so a consumer must read them as a pair rather than treating the
pattern as a fallback for a missing id. See `ModelJsonExporter` for the exact
per-kind shape.

### `formFields[]` entry

Present on `form`-kind fields only. Each entry always carries `name`, `label`
(the declared description, else the field name split on PascalCase), `type` (the
Dart type name) and `required`; `hint`, `enumValues` and `refersTo` are omitted
when empty.

`enumValues` lists the constant names when `type` is a model enum, so a runtime
can validate and convert a value without the analyzer.

`refersTo` states that the field's value is **an id drawn from another section's
registry** rather than free text. It is a list of registry keys, each written
`<SECTIONID>.<formFieldName>` — the section id of the registry *entry* class
(never its list container) plus the form field on that entry which declares the
id. The list form is a disjunction: a value is valid when it resolves in **any**
one of the listed registries, which is how a field such as
`SCTREN.outcomeReference` names both `SYERCO.errorCode` and `VMT.messageId`. A
single field value may itself name several ids, written comma-separated; each
part is resolved independently. Consumers use it for the instance-tier
dangling-reference check — a reference whose target id is not declared anywhere
in the document is reported rather than silently generating broken code.

## Validation contract

`validateSpecModelMeta(Object? meta)` returns a list of human-readable error
strings; an empty list means the file conforms and is safe to load. It checks,
in order:

1. the root is a JSON object;
2. every key in `requiredSpecModelMetaKeys` is present;
3. each required value carries its expected JSON type
   (`metaSchemaVersion`/`modelVersion`/`classCount`/`rootCount` are `int`,
   `generatedAt` is `String`, `roots` is `List`, `classes` is `Map`);
4. `metaSchemaVersion` is not **newer** than `specModelMetaSchemaVersion`.

Both `validateSpecModelMeta`, `specModelMetaSchemaVersion`, and
`requiredSpecModelMetaKeys` are exported from `package:tom_specs_clitool`.
