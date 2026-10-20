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
| `modelHash` | **Which model** the file describes: the sha256 of its own content. | Any change to the model content; never on a version bump alone. |

A reader refuses a file whose `metaSchemaVersion` is **newer** than the version
it was built for (`specModelMetaSchemaVersion`), because the structure may have
changed unreadably. `modelVersion` drives the separate document-vs-model
compatibility check (same-major newer-edits-older; older rejects newer;
cross-major read-only).

### `modelVersion` and `modelVersionLabel` are one fact in two forms

They are **not** two independent records, and neither is a revision counter for
the artifact that carries them:

- `modelVersionLabel` is the model **build** the export was generated from —
  `<version>+<buildNumber>[.<gitCommit>]`, read from
  `tom_specs_model/lib/src/version.versioner.dart`.
- `modelVersion` is the **major** of that label. Nothing else.

So `modelVersion == major(modelVersionLabel)` is an invariant of every stamped
artifact, checkable in isolation with no second artifact to compare against.
Only the derivation `ModelJsonStamp.from(ModelVersionStamp)` can produce a
consistent pair, which is why every committed artifact goes through it; a stamp
whose parts disagree describes no model that ever existed. The two mistakes the
invariant catches are a `0` (no derivation ran) and a build *number* written
into the model *major* slot.

### `modelHash` is the content's identity

`modelVersionLabel` and `generatedAt` both come from the version stamp, and a
model edit does not move the stamp until somebody bumps it. A consumer holding a
packaged copy — the VS Code extension's vendored facade, a CLI's bundled meta —
therefore sees "same version" for a model that has changed. `modelHash` is
derived from the content instead: the sha256 (lowercase hex) of the file's
canonical JSON, with map keys sorted at every depth, list order kept, and the
four build keys `generatedAt`, `modelVersion`, `modelVersionLabel` and
`modelHash` left out (`specModelContentHash`). Two metas carry the same hash
exactly when they describe the same model.

Leaving the version keys out is what separates the two failures. A bumped
version with an unchanged hash is a release with no model change; an unchanged
version with a changed hash is a model change nobody bumped, which
`generate_som` warns about (it compares the hash and version recorded in
`tom_specs_clitool/tool/model_surface.stamp.json` by the previous canonical
run). The rule it enforces: a model change comes with at least a **patch** bump
of `tom_specs_model`, published or not.

Consumers resolve the pair through `somModelVersionString(int, String?)`, which
**prefers the label** — it returns `major.minor` from the label's core, falling
back to `<modelVersion>.0` only when no label is present. The integer therefore
matters least where a label exists, which is precisely why a wrong one can sit
unnoticed; the invariant above, not a consumer, is what catches it.

An artifact's own revision history is *not* expressible here. A snapshot that is
refreshed without the model moving re-exports at the **same** `modelVersion`,
with the label recording the newer build — refreshing a copy is a re-export of
the current model, never a renumbering of it.

The document-side counterpart of `modelVersion` lives in each
`*.docspecs.yaml` under its own `modelVersion` key (beside the on-disk
`formatVersion`), recording the authoring model `major.minor` of that document.

## Refreshing the committed assets

Two copies of this export are **tracked in git**:

| Target | Path |
| --- | --- |
| `editor` | `tom_forge/tom_specs_editor/assets/spec_model.json` |
| `reviewer` | `tom_ai/ai_build/tom_specs_reviewer/assets/spec_model.json` |

Both carry the **same** stamp, derived from
`tom_specs_model/lib/src/version.versioner.dart` — they are one export of one
model, so they can only honestly claim one version, and their class graphs are
byte-identical. They differ in refresh *cadence*, not in stamp: the editor's
copy moves with the build alongside the SOM metas and the DocSpecs schemas,
while the reviewer's is refreshed periodically. Neither target carries a stamp
of its own; a per-target pin used to exist and is deliberately gone, because it
recorded the build *number* in the model *major* slot.

Refresh either one by **naming the target**, from `tom_specs_clitool`:

```bash
dart run bin/model_json.dart --target editor
dart run bin/model_json.dart --target reviewer
```

The target determines both the output path and the stamp, so neither can be
given wrongly. `--output`, `--model-version` and `--model-label` are rejected
with `--target`, and an export that names one of the two committed paths via a
hand-written `--output` is refused. `ModelJsonTarget` in
`tom_specs_clitool/lib/src/model_json_target.dart` is the machine-readable form
of the table above; `test/model_json_target_test.dart` checks both assets and
the nine SOM metas on disk against it — the derived stamp, the label-agreement
invariant, and that all eleven carry one build — so a wrong-stamp or
un-regenerated artifact fails there.

`bin/build.dart` refreshes the editor's copy as step 3 by calling the same
target. It is not the reviewer's refresh path.

Ad-hoc exports to any other location stay freely stampable and default to
`modelVersion: 0`.

## Top-level keys

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `generatedAt` | `String` (ISO-8601 UTC) | yes | Emission timestamp. |
| `metaSchemaVersion` | `int` | yes | This file format's version. Currently `1`. |
| `modelVersion` | `int` | yes | The model **major** the export was generated against — by definition the major of `modelVersionLabel` when one is present. `0` means an unstamped ad-hoc export and is never valid in a committed asset — see "Refreshing the committed assets" below. |
| `modelVersionLabel` | `String` | no | The model build the export was generated from, `<version>+<buildNumber>[.<gitCommit>]` (e.g. `1.0.0+3.50e0102`). Omitted when unstamped. |
| `classCount` | `int` | yes | Number of entries in `classes`. |
| `rootCount` | `int` | yes | Number of entries in `roots`. |
| `modelHash` | `String` | no | The content hash described above. Absent only in a file written before it existed; when present it must match the content. |
| `containerRoot` | `String?` | no | Name of the canonical container class (the single true tree root), or `null` for a container-less model. |
| `roots` | `List` | yes | Document entry points (each `@Document` class). |
| `classes` | `Map<String, Object?>` | yes | The class graph: each class once, keyed by name. |

`modelVersionLabel`, `modelHash` and `containerRoot` are **not** required — the
label is optional, a file written before the hash existed has none, and the
container root is legitimately `null`. Adding `modelHash` did not change
`metaSchemaVersion`: an older reader ignores the key.

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
`enumType`/`enumValues`/`enumValueDocs` for enums, `type` for complex/scalar).
`elementIsComplex`
tells a consumer whether `elementType` names a model class to resolve or a scalar
to render directly, without it having to look the name up.

A field also carries its own lossless `annotations` block (omitted when empty),
plus curated `sectionId` / `sectionIdPattern` / `headline` / `help` /
`standardReferences` when present. `sectionId` and `sectionIdPattern` are
independent: a list field routinely carries both — its own id and the id pattern
its items take — so a consumer must read them as a pair rather than treating the
pattern as a fallback for a missing id. See `ModelJsonExporter` for the exact
per-kind shape.

**`doc` is resolved through the superclass chain, as dartdoc resolves it.** A
member that overrides a documented one without adding a comment of its own
carries the inherited text, not `null`. This is not a nicety: every section
class re-declares `content` as `@override String? content;` purely to attach its
`@Form` / `@ContentType`, so before this the meta wrote `doc: null` for 1,249 of
the model's 5,153 fields — every one of them `content`, and 810 of them with no
`help` to fall back on either — and the eight non-Dart facades rendered those
1,249 accessors each with no documentation at all, while Dart's own
emitter happened to have a fallback that hid it.

### `formFields[]` entry

Present on `form`-kind fields only. A field is `form`-kind when it carries a
field-level `@Form`, and the `content` member is `form`-kind too when its
**class** carries a class-level `@Form` and the member has none of its own
(`tom_specs_model_rules.md` §5.3: an `@Form` class's content is the form) —
the same rule the DocSpecs schema generator applies when it gives the section
an `<id>-form` format. Each entry always carries `name`, `label`
(the declared description, else the field name split on PascalCase), `type` (the
Dart type name) and `required`; `hint`, `enumValues`, `refersTo` and `countOf`
are omitted when empty, and `code` is omitted when `false`.

`enumValues` lists the constant names when `type` is a model enum, so a runtime
can validate and convert a value without the analyzer. `enumValueDocs` is its
companion — an object keyed by constant name holding each constant's doc
comment, omitted entirely when the enum documents none of them and omitting the
individual constants it has no text for.

The two answer different questions and a closed vocabulary needs both:
`enumValues` says *which* tokens are legal, `enumValueDocs` says what they mean.
The author's choice is between adjacent constants, and what separates them
exists nowhere else in the meta. It is keyed rather than positional so a length
divergence cannot silently pair a constant with its neighbour's description.

`refersTo` states that the field's value is **an id drawn from another section's
registry** rather than free text. It is a list of registry keys, each written
`<SECTIONID>.<slot>` — the section id of the registry *entry* class (never its
list container) plus the slot on that entry which declares the id. The slot is
either a **form field name**, when the entry carries an identifier the built
system owns, or the literal **`@sectionId`**, when the entry's id is its stored
section id and no form field restates it (`tom_specs_model_rules.md` §6.2 rule
6 and `tom_specs_model_rules.md` §8 rule 4). The list form is a disjunction: a
value is valid when it
resolves in **any** one of the listed registries, which is how a field such as
`SCTREN.outcomeReference` names both `SYERCO.errorCode` and `VMT.@sectionId`. A
field marked `"multiple": true` (`Field.multiple`) holds several ids, written
comma-separated, each resolved independently; a field without it holds one id,
and a list there is reported as `multipleReferences`. Consumers use it for the instance-tier
dangling-reference check — a reference whose target id is not declared anywhere
in the document is reported rather than silently generating broken code.

`countOf` states that the field's value is **a count of entries the document
holds** (`Field.countOf`). It is a list, each element either `<SECTIONID>` —
every list entry of the class carrying that section id — or
`<SECTIONID>.<formField>=<value>`, only the entries one of whose own form
members holds that value in that form field. The stated count must equal the
sum over the elements; a target written `./…` counts only the entries beneath
the section holding the form. Consumers use it for the instance-tier
`countMismatch` check (SOM §9).

`productOf` states that the field's value is the **product of other fields**
(`Field.productOf`): a list of operands, each a form field of the same form or
`<FORMSECTIONID>.<field>` of a form beside it on the same section. A numeric
operand contributes its number, an enum operand its 1-based position. `rankOf`
names the form field of the same form the value **ranks by**, highest first
(`Field.rankOf`). Both are checked by the instance tier as
`derivedValueMismatch` (SOM §9). As with `refersTo`, a target outside the document's scope is
skipped, and an empty value is not checked.

`code: true` states that the field's value is **code, not prose**
(`Field.code`). Consumers use it in the markdown codec, which writes a
single-line value as an inline code span and unwraps it on import (SOM §11.4
rule 8). It never constrains the value.

## Validation contract

`validateSpecModelMeta(Object? meta)` returns a list of human-readable error
strings; an empty list means the file conforms and is safe to load. It checks,
in order:

1. the root is a JSON object;
2. every key in `requiredSpecModelMetaKeys` is present;
3. each required value carries its expected JSON type
   (`metaSchemaVersion`/`modelVersion`/`classCount`/`rootCount` are `int`,
   `generatedAt` is `String`, `roots` is `List`, `classes` is `Map`);
4. a present `modelHash` is a `String` equal to `specModelContentHash` of the
   file, so a hand-edited or partly regenerated meta is refused;
5. `metaSchemaVersion` is not **newer** than `specModelMetaSchemaVersion`.

Both `validateSpecModelMeta`, `specModelMetaSchemaVersion`, and
`requiredSpecModelMetaKeys` are exported from `package:tom_specs_clitool`.
