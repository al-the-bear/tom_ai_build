# IR Specs — the Intermediate Representation

**Quest:** tom_specs · **Status:** normative for format `irspecs-ir`,
formatVersion 1; implemented by `tom_specs_clitool` (`lib/src/irspecs/`,
`bin/irspecs.dart`)

**Authority for: what the IR holds and how it is written.** The IR is a
CodeSpecs trio as language-neutral data: everything the trio expresses —
declarations, `Cs*` markers and their argument values, back-links, doc
comments, members, method bodies and their statements — in one YAML document
per area. A mapper per language and framework writes code from it; the Dart +
Tom mapper's output is today's trio, byte for byte; the TypeScript mappers
write the same skeleton as an npm workspace (§11). This document says what is
in a document, how it is written and what is deliberately left out, and what
each standard emitter writes from it (§10). Which code
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
the files no area claims — always written, files or not, because its header
names the trio's three packages even for a trio that holds no file. A file belongs to exactly one document; the first of
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
| `units` | optional: the generation units the file is written for, by unit id (§8.1); absent, every unit of its locus whose mappings hold the document's area — added for the IR (§6) |
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
| `docSpec` | the `@DocSpec` tuples, each `sectionId`, `description` and, as written, `descriptionLiteral` (§4.4); absent when the annotation is, `[]` when it is written empty |
| `docSpecLine` | where the `@DocSpec` annotation is |
| `docComment` | the `///` block above it: `lines` exactly as written (each with its `///`), `line` of the first |
| `annotations` | the annotations that are neither `Cs*` markers nor back-links (`@tomService`), each `source` as written and `line` |
| `typeParameters`, `superclass`, `interfaces`, `mixins` | a class's header as written: `<T>`, the `extends` type, the `implements` and `with` types |
| `isAbstract`, `isStatic`, `isConst`, `isFinal`, `isLate`, `hasInitialiser` | the keywords as written (`late final` is `isLate` and `isFinal`); `isConst` is written only when true |
| `declaredType` | a variable's declared type as written, when it has one |
| `initialiser` | a variable's initialiser as written, or an enum constant's argument list |
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
| `string` | `value`, `literal` | a string literal; `literal` is the literal as written — adjacent literals joined by one space — because where a long string is split is part of what was written |
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

A body is `name`, `shape`, `line`, `isAsync`, `accessor` (`get` / `set` for
an accessor), `isArrow` (an arrow body, written only when true), `parameters`
(each `name`, and when declared `type` as written, `kind` when it is not a
required positional parameter — `optionalPositional`, `requiredNamed`,
`optionalNamed` — and `default` as written), `returnType`, and for a form-3a
body (`codespecs_derivation_contract.md` §2.4) `thrownType`, `thrownMessage`
and, as written, `thrownLiteral`; then `calls` (every call site, in order) and
`statements`.

`shape` is `none` (no body), `throwOnly` (form 3a), `returnsValue` or `other`
(form 3b). A form-3b body's `statements` are its statement list as it is
today — each `kind` (`call`, `localBinding`, `controlFlow`, `returned`,
`thrown`, `other`), `source` (whitespace-collapsed), `line`, and where it has
them `keyword` (`if`, `for`, …), `hasElse` (an `if` with an `else`; `nested`
holds both branches), `call` (`receiver`, `method`, `arguments` as written,
`line`), `valueIdentifier`, `valueSource`, `boundName`, `isFinal` and `nested`
statements. A call site in `calls` has the same `receiver`, `method`,
`arguments` and `line`.

A form-3b body that reaches a collaborator also carries its **steps** (§4.7),
or `stepsRefused` saying which rule kept it from having them.

### 4.6 Construction

A `tom_core`-family construction: `type`, `holder` (the declaration it is the
value of, when there is one), `line`, `positional`, `named`.

### 4.7 Steps

A form-3b body (`codespecs_derivation_contract.md` §2.4) is a statement
sequence over its collaborator, and rules B1–B8 of the same section confine it
to three statement shapes. Those shapes are the **step language**: the body as
data, which a mapper prints in its own language instead of re-reading Dart.

**Which bodies have steps.** Every body of shape `returnsValue` or `other` on a
top-level declaration that has a `collaborator` field — the seam of
`codespecs_derivation_contract.md` §3.0.1. A body on a declaration without one
calls a named substrate (statement kind 2 of `codespecs_derivation_contract.md`
§2.4, the query composition of `codespecs_derivation_contract.md` §3.3.4),
which is no B-rule's subject, and has no steps.

**The steps.** `steps` is a list, in order; each step has `step` (its kind),
`line` and the fields below. Nothing else is a step.

| `step` | Fields | Dart it stands for | From |
|--------|--------|--------------------|------|
| `call` | `method`, `arguments` | `await collaborator.<method>(<arguments>);` | B1 (its place in the list is document order), B2 (one contributing step, one call), B3 (every step but the last result-carrying one, and every step of a body returning `void`) |
| `return` | `method` and `arguments`, or neither | `return collaborator.<method>(<arguments>);` — or `return;` | B3 (the last step of a body returning a value carries its result), B6 (`endFlow` ends a branch block: `return;` in a `void` body, the last step's call returned otherwise) |
| `guarded` | `guard`, `arguments`, `steps` | `if (await collaborator.<guard>(<arguments>)) { <steps> }` | B4 (a stated condition is a guard method `…Applies` returning `bool` / `Future<bool>`, never a parsed expression), B5 (the block stands before the step it branches from, so its place in the list is its place in the body), B6 (the block holds its flow's own steps and ends with a `return` for `endFlow`, or simply ends for `resumeAtStep`) |

`arguments` are the call's arguments as written; B3 makes them the calling
body's own parameters, by name and in order. A `guarded` step has no `else`:
B6 states where control goes after a branch block — out of the body, or on into
the main sequence — and neither is a second branch. B7 and B8 contribute no step
kind: B7 rules repetition and multi-way choice out, and B8 sends a prose-only
body to form 3a, which has no steps.

**Refused.** A body whose statements are not steps carries `stepsRefused`
instead — `rule`, `message` and the `line` of the first statement that is not a
step:

| `rule` | The statement |
|--------|---------------|
| `B2` | calls something other than the collaborator |
| `B3` | binds a local, or returns a value that no collaborator call produced |
| `B4` | branches on a condition that is no collaborator call |
| `B6` | is an `if` with an `else` |
| `B7` | is a `for`, `while` or `switch` |
| `3b` | is none of the statements a form-3b body admits (`codespecs_derivation_contract.md` §2.4: an assignment, a throw, a literal, …) |

**Validation.** `validateIrSteps` (`tom_specs_clitool`, `lib/src/irspecs/ir_steps.dart`)
checks every step body of a document set:

| Rule | Holds | From |
|------|-------|------|
| S1 | the body reads into steps — it has `steps`, not `stepsRefused` | B1–B8 |
| S2 | the declaration's `collaborator` field names a `@CsCollaborator` class of the same project, and every method a step calls is one of its methods | B2, `codespecs_derivation_contract.md` §3.0.1 |
| S3 | a `guarded` step calls a guard method — named `…Applies`, returning `bool` or `Future<bool>` — and no other step calls one | B4 |
| S4 | the return kind is one the body allows: a body returning `void` / `Future<void>` returns no value; a body returning a value returns one wherever it returns, and ends with a `return` step | B3, B6 |
| S5 | every call passes the calling body's own parameters, by name and in order | B3 |

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
| `arguments` of a call | B3 passes a collaborator method the calling body's parameters; the steps carry them and S5 checks them. |
| `hasElse` of a statement | `nested` holds both branches of an `if`, so an `else` was invisible; no step has one. |
| `literal` of a string value, `descriptionLiteral` of a `DocRef`, `thrownLiteral` of a body | Where an author split a long string into adjacent literals is part of what was written; `dart format` never moves it and no rule re-derives it. |
| `annotations` of a declaration | An annotation that is neither a marker nor a back-link — `@tomService` — is part of the declaration. |
| `typeParameters`, `superclass`, `interfaces`, `mixins` of a class | The class header: a repository is `extends TomRepository<Customer, String>`, an envelope `Result<T>`. |
| `isConst` and `initialiser` of a variable | A catalogue member is `static const … = CsMessageKey('…')`, a route `final … = TomRouteDefinition(…)`. |
| `kind` and `default` of a parameter, `accessor` and `isArrow` of a body | A parameter list and a body form a mapper has to write as they were. |

Member order and comments needed nothing new: the reading keeps declarations
and comments in source order, and the IR writes them in that order.

All of them were found the way §8 says every such fact is found: by writing
the trio again from the IR and comparing it, byte for byte, with the trio it
was read from. A fact a future trio needs and this table lacks is added the
same way — into the reader, into CsModel, into this table — never as a special
case in a mapper.

## 7. The checks on the IR

The forty-one checks of `codespecs_derivation_contract.md` §6 run on the IR as
they run on the trio, so a specification's CodeSpecs are checked before any
code exists:

```text
validate_codespecs --ir <spec-root>/irspecs [--extracts …] [--json]
```

`--ir` stands in for `--shared`, `--client` and `--server`; every other input
is the same. The IR is read back into the CsModel the checks read from Dart
(§5), so the checks themselves do not change and the report is the trio's
report — `tom_specs_clitool/test/validate_codespecs_cli_test.dart` holds that
for both Meridian trios, with and without extracts and for a violating trio,
and `test/codespecs_validator_ir_test.dart` runs every check's fixtures through
the IR.

The one field the IR leaves out, a file's text (§5), is read by one check:
check 31 compares two generation runs. On the IR the two runs are two IR
folders (`--regenerated-ir`), and a file's text is replaced by its IR record,
so check 31 compares records: a second run that disagrees on anything the IR
holds is reported, file by file. Layout is not compared, because
`codespecs_derivation_contract.md` §2.7 leaves it to `dart format`; the two
fixtures about whitespace and the line of the first difference are the Dart
text's and are skipped through the IR with that reason.

`package.ir.yaml` is written for every trio, files or not (§2): it is what
names the three packages when no other document does.

## 8. The Dart + Tom mapper

The first mapper writes the trio CodeSpecs writes today: Dart on the `tom_core`
family, following [`codespecs_derivation_contract.md`](codespecs_derivation_contract.md).

```text
irspecs map --mapper dart-tom --ir <spec-root>/irspecs --out <dir>
```

It writes one folder per package under `--out` (`<dir>/<package>/lib/…`), every
package's folder whether or not it holds a file, and runs `dart format` over
what it wrote. Its output is defined by two promises:

1. **Byte-equal.** For a trio in the form the derivation contract requires,
   `irspecs from-codespecs` followed by `irspecs map` reproduces every
   `lib/` source of the trio byte for byte. The test
   `tom_specs_clitool/test/irspecs_dart_tom_test.dart` holds this for both
   Meridian trios and checks that the reproduced trio passes
   `validate_codespecs` with the result the original gets. A difference is a
   fact this document's records do not carry; it is fixed in the IR (§6), not
   in the mapper.
2. **Refused, not approximated.** A construct the mapper has no rule for — a
   constructor, a mixin, a top-level function, a comment that is neither the
   banner nor a doc comment, a form-3b body without steps — stops the run
   naming the file and line (exit `1`), so nothing is written that only
   resembles its input.

**What it prints from.** A form-3b body from its **steps** (§4.7), never from
its statement text: `await` before a call and a guard where the body is
`async`, `return` without `await`, the guarded steps inside the `if`. A form-3a
body from `thrownType` and the explication (`thrownLiteral`, else
`thrownMessage` quoted). Markers, `@CodeSpec` and `@DocSpec` from their values.
What is Dart by nature — a type, an initialiser, a non-`Cs*` annotation, a
class header, a string's literal — as written.

**Layout.** The mapper prints each file as an unbroken stream of tokens and
leaves line breaks, indentation and trailing commas to `dart format`, which
`codespecs_derivation_contract.md` §2.7 makes the layout of every generated
file. The two things the formatter keeps from its input are the mapper's:

- **blank lines** — after the banner, between the import groups (`dart:`,
  `package:`, relative; `export`s after the `import`s, grouped the same way),
  before every top-level declaration, between the members of a class or enum;
- **annotation order** — the doc comment first, then every annotation in the
  order of its `line`, back-links, markers and other annotations alike.

### 8.1 Units

A specification that declares generation units (SOM §11.2, the register
`GENUN-UNIT-LST`; `codespecs_mapping.md` §1.1.1 item 4) has its code written
**unit by unit**: a unit is one package of the trio's kind — shared, client or
server — and names, per area, the mapper that writes it.

```text
irspecs map --mapper dart-tom --ir <spec-root>/irspecs --out <dir> \
    --spec <specification document> --unit <unit id>
```

reads the unit from the specification's register and writes its package into
`<dir>/<unit id>/`. What the unit takes is decided by three facts and nothing
else:

1. **Its locus.** Only files whose `locus` is the unit's kind.
2. **Its areas.** Only the documents of areas the unit maps to `--mapper`, plus
   the `package` document. An area the unit maps to another mapper is that
   mapper's to write.
3. **The file's `units`.** A file without `units` goes to every unit its locus
   and area select; a file with `units` goes only to the units it names. The
   authoring agent writes `units` on a file when the extract entries it was
   written from go to some units of its locus and not others — a section
   whose `units` override narrows its area's default
   (`codespecs_derivation_contract.md` §2.9).

The unit's id is its package name: every project of the share is renamed to it,
so the mapper writes that one package. A unit of kind `other` has no locus and
is refused, as is a `--unit` the register does not declare (exit `2`). Without
`--spec` and `--unit`, `irspecs map` writes the whole trio as above. The test
`tom_specs_clitool/test/irspecs_units_test.dart` writes the Meridian trio unit
by unit from its IR and the Meridian blueprint's register, and holds each
package byte-equal to the committed one.

## 9. Versioning

`formatVersion` changes only when an older reader could not read a new
document, or a new reader an older one. A new optional key is not such a
change — `arguments`, `hasElse`, `steps` and `stepsRefused` are optional for
that reason, and a document without them reads as having none; a renamed key,
a changed value shape or a removed key is.

## 10. The standard emitters

What a standard can express is written in that standard, from the IR, so a
generator of any language can read it (CSML-3):

```text
irspecs emit --standard <openapi|jsonschema|icu|asyncapi> --ir <spec-root>/irspecs --out <dir>
```

writes one document into `--out` and lists on stdout every fact of the IR the
standard has no form for (§10.2). The emitters live in
`tom_specs_clitool/lib/src/irspecs/emitters/`. Each document is validated
against its standard's official meta-schema, vendored with its source URL and
version under `tom_specs_clitool/tool/standards/`
(`tom_specs_clitool/test/irspecs_emit_test.dart`, over the Meridian IR and a
trio with notifications and jobs). ICU MessageFormat has no meta-schema; its
catalogue is checked by a parser of the ICU MessageFormat syntax
(`icuSyntaxErrors`).

### 10.1 Which area feeds which standard

| Standard | File | Areas | What becomes what |
|----------|------|-------|-------------------|
| **OpenAPI 3.1** | `openapi.json` | CE-API, CE-SU, CE-ER; the types of CE-EN, CE-DB | Every `@CsEndpoint` operation is a `POST /<operation>` (`codespecs_mapping.md` §7): `operationId` the operation, the request body the handler's parameter type (CE-SU; without a handler, the `<Operation>Request` type), the `200` response the `Result` envelope with `value` the handler's result type, `5XX` the only other response. The description is the handler's doc comment, else the catalogue entry's. The types are `components.schemas`, built as for JSON Schema. |
| **JSON Schema 2020-12** | `schema.json` | CE-EN, CE-ER, CE-API, CE-DB (with CE-VA's `@CsValidation` rules) | `$defs`, one per type: a domain enum (CE-EN) an `enum` of its constants; the error-code catalogue (`@CsError` class) a string `enum` of its codes; every other class with fields — the envelope, the wire types, the entities — an `object` of its instance fields, a field `required` when its type is not nullable or its rules say `required`. Types: `String` string, `int` integer, `double`/`num` number, `bool` boolean, `DateTime` date-time, `Uri` uri, `Duration` duration, `List`/`Iterable` array, `Set` array of unique items, `Map<String, X>` object, a nullable type also `null`, a type of the IR a `$ref`, a class's type parameter any value, a `Cs…Ref`/`…Key`/`…Code` string. Rules (`codespecs_mapping.md` §5.19): `email` format, `minLength`, `maxLength`, `pattern`, `min` minimum, `max` maximum, `minItems`, `maxItems`. Doc comments are `description`s. |
| **ICU MessageFormat** | `messages.json` | CE-TX | One JSON object, each `@CsText` message key (its `CsMessageKey`) to its base copy as an ICU message: a `{name}` placeholder stays an argument, every other brace and every apostrophe is quoted (`icuMessageFor`), so the copy reads as written. |
| **AsyncAPI 3.0** | `asyncapi.json` | CE-NT, CE-JB | Each `@CsNotificationChannel` declaration a channel; each `@CsNotification` declaration a message under `components.messages`, its payload an object of its fields; each `@CsJob` triggered by an `event` a channel named after the event and a `receive` operation named after the job. Without either, the document is its `info` alone. |

`info.title` is the shared project's package name; `info.version` is
`unversioned`, since the IR carries no API version. The other areas — screens,
forms, layouts, actions, server calls, navigation, view state, configuration,
settings, authentication, identity, migrations, audit, reporting — have no
standard here: their code comes only from a mapper.

### 10.2 What a standard cannot express

An emitter never drops a fact silently: each one below is a line of
`IrEmission.notExpressed`, printed by `irspecs emit` under *Not expressed*.

| Standard | Not expressed | Why |
|----------|---------------|-----|
| OpenAPI, JSON Schema | an error code's severity (`@CsError(severity:)`) | an `enum` value carries no attributes |
| OpenAPI, JSON Schema | an entity's table, its columns' SQL types, lengths and sensitivity (`@CsTable`, `@CsColumn`) | storage, not wire shape |
| OpenAPI, JSON Schema | a validator outside the closed set — a registered custom name — and a rule whose argument is no number | no JSON Schema keyword |
| OpenAPI, JSON Schema | a type the IR declares no schema for (a class without fields, an unknown generic) | written as any value |
| OpenAPI | an operation's authorization (`@CsAuthorize` roles) | OpenAPI security needs a security scheme the IR does not declare |
| OpenAPI | the path prefix a server mounts the operations under | the IR names operations, not URLs |
| ICU MessageFormat | the base copy's locale, a message's doc comment, its role and category | a catalogue holds key and message only |
| AsyncAPI | the channels a notification goes out on, and its body copy key | `TomNotificationType` constructor values, not marker arguments; a message has no copy key |
| AsyncAPI | a job's retries, backoff and timeout; a cron, calendar or interval trigger | job policy and schedules, not messages |

## 11. The TypeScript mappers

Three mappers write the IR as a three-package npm workspace — TypeScript on
both sides, one shared package:

```text
irspecs map --mapper ts-shared       --ir <spec-root>/irspecs --out <dir>
irspecs map --mapper ts-react-client --ir <spec-root>/irspecs --out <dir>
irspecs map --mapper ts-hono-server  --ir <spec-root>/irspecs --out <dir>
```

Each writes the package of its locus — whatever the IR holds there — under
its package name, and the workspace root: a `package.json` naming the three as workspaces and one
`tsconfig.json` that checks them together (`tsc --noEmit -p .`). With
`--spec <document> --unit <unit id>` (§8.1) a unit whose mapping names a
TypeScript mapper is written as that one package. The client's API calls and
the server's routes are generated from the OpenAPI document of the whole IR
folder (§10), whichever package is written.

**What the output is.** A skeleton, as the Dart trio is: it type-checks and
executes nothing — a body the specification gives no steps for throws
`new Error("not implemented: <explication>")`, and a component throws until
Phase 6 writes it. It is written to run as is on Node's type stripping and on
Deno: imports carry their `.ts` extension, a type is imported with
`import type`, and the workspace compiles with `verbatimModuleSyntax` and
`erasableSyntaxOnly`, so `tsc` refuses anything that would need a transform.
The test `tom_specs_clitool/test/irspecs_ts_test.dart` maps the Meridian IR,
installs the workspace, type-checks it, loads each package under Node's type
stripping, holds the back-links of every file to the Dart trio's, and the wire
types to the JSON Schema of §10.

**Pinned versions.** TypeScript 5.9.3, React 19.3, Hono 4.13, Drizzle ORM
0.45 (`kTsDependencyVersions`). The stack — React with plain `fetch`, Hono, and
Drizzle over PostgreSQL — is the first of each choice; other client stacks,
server frameworks and persistence layers are separate mappers to come.

### 11.1 What each declaration becomes

| IR declaration | TypeScript | In the Meridian trio |
|----------------|------------|--------|
| a domain enum (CE-EN) | `export const X = { a: 'a', … } as const` and `export type X` the union of its values | shared |
| a class of `static const` catalogue entries — operations (CE-API), roles (CE-AZ), error codes (CE-ER), message keys (CE-TX) | the same: a const object of the entries' strings and their union type | shared |
| a plain data class (not abstract, instance fields only) — a wire type (CE-API), the envelope (CE-ER) | `export interface X<T> { field: type; }` | shared |
| an entity (`@CsTable`, CE-DB) | a Drizzle table `export const xTable = pgTable('<table>', { … })`, a column per field from its `columnType` (`uuid`, `varchar(n)`, `numeric(p,s)`, `text`, `integer`, `bigint`, `boolean`, `date`, `jsonb`, `timestamp[tz]`; without one, from the Dart type), `.$type<Enum>()` for an enum-typed column, `.notNull()` unless nullable; and `export type X = typeof xTable.$inferSelect` | server |
| a repository (`@CsRepository`) | `export interface XRepository extends TomRepository<X, K> {}`, `TomRepository` the method contract of `tom_core_server`'s (`tom/tom.ts`) | server |
| a service unit (`@CsServiceUnit`, CE-SU) | an `abstract class` whose handlers keep their signature and throw `not implemented`; the routes in `app.ts`: `createApp(services)` returns a Hono app with `app.post('/<operation>', …)` per handler | server |
| a collaborator (`@CsCollaborator`) | `export interface X { method(params): Promise<…>; }` | client |
| a server call (`@CsServerCall`, CE-SC) and any other class with methods | a class: `collaborator!: X` for the `late` field, each 3b body printed from its steps (§4.7) — `await this.collaborator.m(args)`, `if (await this.collaborator.guard(args)) { … }`, `return …` | client |
| a layout (`@CsLayout`, CE-LO) | the class with its layout node, and a React component `export function XView(): ReactElement` that throws until Phase 6 | client |
| a route (`@CsRoute`, CE-NV) | `export const route: TomRouteDefinition = { routeId, path, … }` | client |
| the operations (from §10's OpenAPI) | `ApiClient`: a plain-`fetch` method per operation, `POST` of the request, the Result envelope back, a 5xx status a transport error | client |
| a `tom_core` construction (`TomRouteDefinition(…)`, `TomLayoutContainerNode(…)`) | an object literal; its interface in the package's `tom/tom.ts`, derived from the IR's constructions — every named argument a property, optional unless every construction writes it, a `Tom…` enum value a string-literal union | all |

Types follow §10.1's JSON Schema mapping, so the wire types and the schemas
agree: `String`, `DateTime`, `Uri`, `Duration` → `string`; `int`, `double`,
`num` → `number`; `bool` → `boolean`; `List`/`Iterable`/`Set` → arrays;
`Map<String, X>` → `Record<string, X>`; `Future<X>` → `Promise<X>`; `X?` →
`X | null`; a `Cs…Ref`/`…Key`/`…Code` → `string`.

**Back-links and markers** become JSDoc tags on the declaration and on each
member: `@codeSpec <id> source: <section ids>`, `@docSpec <section id> —
<description>`, every `Cs*` marker as `@cs <Marker>(<arguments>)`, and any
other Dart annotation as `@dart <annotation>` — the same section ids as the
Dart trio, which the test holds file by file. A doc comment is kept as the
JSDoc text.

**Refused, not approximated** (as in §8): a declaration kind with no rule (a
mixin, a top-level function), a construction with positional arguments, an
initialiser that is neither a construction nor a single string, and a column
type with no Drizzle builder stop the mapper naming the file.
