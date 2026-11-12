# IR Specs — the Intermediate Representation

**Quest:** tom_specs · **Status:** normative for format `irspecs-ir`,
formatVersion 1; implemented by `tom_specs_clitool` (`lib/src/irspecs/`,
`bin/irspecs.dart`)

**Authority for: what the IR holds and how it is written.** The IR is a
CodeSpecs trio as language-neutral data: everything the trio expresses —
declarations, `Cs*` markers and their argument values, back-links, doc
comments, members, method bodies and their statements — in one YAML document
per area. A mapper per language and framework writes code from it; the Dart +
Tom mapper's output is today's trio, byte for byte. This document says what is
in a document, how it is written and what is deliberately left out. Which code
a mapper writes from it is each mapper's own document, and what the trio
itself must contain stays with
[`codespecs_derivation_contract.md`](codespecs_derivation_contract.md).

## 1. What the IR is read from

Format version 1 is read from a generated trio: the three packages
`<app>_codespec_shared`, `_client` and `_server`
([`codespecs_mapping.md`](codespecs_mapping.md) §4.2). Every `.dart` file under
each package's `lib/` is parsed as source text — no resolution, no SDK — by the
same reader `validate_codespecs` uses, and its reading is the IR's content.
Nothing a CodeSpecs trio expresses may get lost on the way; the field table in
§5 is the proof obligation, and a test holds it.

The command:

```text
irspecs from-codespecs --shared <dir> --client <dir> --server <dir>
                       --areas <codespecs_areas.json> --out <spec-root>/irspecs
```

`--areas` is the area catalogue `tom_specs_model/generated-doc/codespecs/`
ships; it decides which file belongs to which area (§2). The command writes
one document per area holding files, reports each as new, changed or
unchanged, and deletes an `*.ir.yaml` in `--out` that the trio no longer
produces — the folder is always the IR of exactly that trio.

## 2. One document per area

The documents are `<spec-root>/irspecs/<CE-CODE>.ir.yaml`, one per area that
holds at least one file, written in catalogue order, and `package.ir.yaml` for
the files no area claims. A file belongs to exactly one document; the first of
these rules that applies decides which:

1. **The folder.** [`codespecs_derivation_contract.md`](codespecs_derivation_contract.md)
   §2.1 rule N7 writes a part's files under
   `lib/src/<canonical id, snake_case>/`, so a file there belongs to that
   canonical id's area (`lib/src/data_access/` → `CE-DB`).
2. **The back-links.** Otherwise the first `@CodeSpec` id written in the file
   names its part before the dot (`serverApi.OrderDto` → `CE-API`).
3. **The markers.** Otherwise the first part marker written in the file names
   the area whose annotations include it (`@CsTable` → `CE-DB`).
4. **No area.** Otherwise the file goes into `package.ir.yaml`. In a trio that
   follows N7 that is the three barrel libraries.

Rules 2 and 3 exist because a trio written before N7 settled its folder names
(`api/`, `error/`) is still a trio, and its marker-less DTOs and result
envelope belong to their part, not to the package.

A file's collaborator (`codespecs_derivation_contract.md` §3.0.1) is a file of
its own under the owning part's folder, so it lands in the same document as
the file it serves.

## 3. The file

A document is YAML in a deliberately narrow form, so that two writes of one
trio are byte-identical and no string can be misread:

- block mappings and sequences, two spaces per level;
- **every string double-quoted and JSON-escaped** — a doc comment carries `:`,
  `#`, quotes, backslashes and leading spaces, and one rule for all strings
  leaves no string a writer could get wrong;
- integers, `true` / `false`;
- an empty list `[]`, an empty mapping `{}`;
- keys in the order this document lists them; a field whose value is absent is
  left out, a boolean or a list is always written.

The JSON Schema
[`tom_specs_clitool/tool/irspecs_ir.schema.json`](../../tom_specs_clitool/tool/irspecs_ir.schema.json)
(draft 2020-12) constrains every document; a document that does not validate
is not an IR document.

## 4. The records

### 4.1 Document

| Key | Holds |
|-----|-------|
| `format` | `"irspecs-ir"` |
| `formatVersion` | `1` |
| `area` | the area code (`"CE-DB"`) or `"package"` |
| `projects` | the trio's three packages, each `locus` (`shared` / `client` / `server`) and `package` (its name), in emission order. Every document names all three, so one document alone still says which package each locus is. A reader refuses a set whose documents disagree. |
| `files` | the area's files, ordered by locus (emission order), then by path |

### 4.2 File

| Key | Holds |
|-----|-------|
| `locus` | the project the file belongs to |
| `path` | the package-relative path, `/`-separated (`lib/src/data_access/customer.dart`) |
| `imports` | the `import` URIs, in source order |
| `exports` | the `export` URIs, in source order — added for the IR (§6) |
| `comments` | every comment token, in source order: `text` as written (marker included), `documentation` (a `///` comment), `banner` (before the file's first token), `line` |
| `declarations` | the file's declarations in source order: each top-level declaration followed by its members. **Member order is this order.** |
| `constructions` | the `tom_core`-family constructions in the file (§4.6) |

A location is written as `line` alone (1-based) on every element: its file is
the file it is listed under.

### 4.3 Declaration

One record per emitting declaration and per member of one. A member names its
`owner`; a top-level declaration has none.

| Key | Holds |
|-----|-------|
| `name` | the declaration name |
| `owner` | the owning declaration, for a member |
| `kind` | `classType`, `enumType`, `mixinType`, `topLevelVariable`, `topLevelFunction`, `field`, `method`, `constructor` |
| `line` | where the declaration's name is |
| `markers` | the `Cs*` markers written on it, in source order (§4.4) — `@CsCollaborator` among them for a collaborator class |
| `codeSpec` | the `@CodeSpec` back-link: `id` (`<canonical id>.<identifier>`), `source` (its section ids), `line` |
| `docSpec` | the `@DocSpec` tuples, each `sectionId` and `description`; absent when the annotation is, `[]` when it is written empty |
| `docSpecLine` | where the `@DocSpec` annotation is |
| `docComment` | the `///` block above it: `lines` exactly as written (each with its `///`), `line` of the first |
| `isAbstract`, `isStatic`, `isFinal`, `isLate`, `hasInitialiser` | the keywords as written (`late final` is `isLate` and `isFinal`) |
| `declaredType` | a variable's declared type as written, when it has one |
| `bodies` | the method and accessor bodies it declares (§4.5) |

The **collaborator** of a form-3b body (`codespecs_derivation_contract.md`
§3.0.1) is not a field of its own: it is the declaration carrying
`@CsCollaborator`, and the field `collaborator` (`isLate`, `isFinal`,
`declaredType` the collaborator class) on the declaration it serves — both as
written, both here.

### 4.4 Marker and value

A marker is `name` (without `@`), `positional` (its positional arguments in
order), `named` (a list of `{name, value}` — a list because the order is part
of the source) and `line`.

A value is a mapping with a `kind`:

| `kind` | Further keys | Written for |
|--------|--------------|-------------|
| `string` | `value` | a string literal |
| `bool` | `value` | `true` / `false` |
| `int` | `value` | an integer literal |
| `null` | — | `null`, written where a per-kind slot is deliberately absent |
| `qualified` | `prefix`, `name` | an enum access (`CsTextRole.error`) or a catalogue const (`SharedOperations.login`) |
| `construction` | `type`, `positional`, `named` | a `Cs*Ref` const, a value class (`CsGradedAccess`), a substrate construction |
| `list` | `values` | a list literal |
| `unknown` | `source` | an expression the reader does not model, kept as its source text |

`unknown` is the reader's own eighth kind: it names an expression rather than
dropping it, so a value outside the seven is carried and visible, not lost.

### 4.5 Body and statement

A body is `name`, `shape`, `line`, `isAsync`, `parameters` (each `name` and,
when declared, `type`, as written), `returnType`, and for a form-3a body
(`codespecs_derivation_contract.md` §2.4) `thrownType` and `thrownMessage`;
then `calls` (every call site, in order) and `statements`.

`shape` is `none` (no body), `throwOnly` (form 3a), `returnsValue` or `other`
(form 3b). A form-3b body's `statements` are its statement list as it is
today — each `kind` (`call`, `localBinding`, `controlFlow`, `returned`,
`thrown`, `other`), `source` (whitespace-collapsed), `line`, and where it has
them `keyword` (`if`, `for`, …), `call` (`receiver`, `method`, `line`),
`valueIdentifier`, `valueSource`, `boundName`, `isFinal` and `nested`
statements.

### 4.6 Construction

A `tom_core`-family construction: `type`, `holder` (the declaration it is the
value of, when there is one), `line`, `positional`, `named`.

## 5. Every field, and the one left out

The IR's content is the CsModel reading of the trio
(`tom_specs_clitool/lib/src/codespecs/cs_model.dart`). Every field of every
CsModel class a trio's reading holds is carried, with one exception:

| Left out | Why |
|----------|-----|
| `CsFile.source`, the file's text | The text is what a mapper writes *from* the IR. Carrying it would make the byte-equal proof of the Dart + Tom mapper compare the text with itself. |

The codec names both sets (`irCarriedCsModelFields`, `irOmittedCsModelFields`
in `lib/src/irspecs/ir_codec.dart`), and the test `test/irspecs_ir_test.dart`
holds them: it reads both Meridian trios, writes their IR, reads it back, and
compares every field of every object reflectively against the original, so a
field added to CsModel is compared the moment it exists and fails until the IR
carries it or this table says why it does not.

## 6. What the IR adds to CsModel

What re-emitting a file needs and the reading had dropped is added to the
reader, and so to CsModel and to the IR:

| Added | Why |
|-------|-----|
| `exports` of a file | A project's barrel library is nothing but its exports. |

Member order and comments needed nothing new: the reading keeps declarations
and comments in source order, and the IR writes them in that order.

What a mapper needs beyond this — a class's supertypes, a field's initialiser,
a constructor's shape, an enum constant's arguments — is found by the Dart +
Tom mapper's byte-equal proof and added here, field by field, under
the same rule: into the reader, into CsModel, into this table.

## 7. Versioning

`formatVersion` changes only when an older reader could not read a new
document. A new optional key is not such a change; a renamed key, a changed
value shape or a removed key is.
