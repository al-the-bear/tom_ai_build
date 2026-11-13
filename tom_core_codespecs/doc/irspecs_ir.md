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
write the same skeleton as an npm workspace, with a web and a mobile client
(§11), the Go server mapper the
server as a Go module (§12), the Java + Spring Boot mapper as a Gradle project
(§13), the C# + ASP.NET Core mapper as a .NET solution (§14). This document says what is
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

The forty-four checks of `codespecs_derivation_contract.md` §6 run on the IR as
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

**Keys.** An entity's keys and indexes are its `@CsTableKey` and
`@CsTableIndex` markers (`codespecs_derivation_contract.md` §3.3.11), printed
like every marker. `tom_core_server`'s repository finds an entity's primary
key through `@TomDbTable(primaryKeyFields: …)`, which the trio does not carry,
so a repository of the Dart output does not run yet; its key type `K` is the
primary key's member type as the trio writes it.

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

Four mappers write the IR as an npm workspace — TypeScript on both sides,
one shared package, a web and a mobile client:

```text
irspecs map --mapper ts-shared              --ir <spec-root>/irspecs --out <dir>
irspecs map --mapper ts-react-client        --ir <spec-root>/irspecs --out <dir>
irspecs map --mapper ts-react-native-client --ir <spec-root>/irspecs --out <dir>
irspecs map --mapper ts-hono-server         --ir <spec-root>/irspecs --out <dir>
```

Each writes the package of its locus — whatever the IR holds there — under
its package name, and the workspace root: a `package.json` naming the packages
as workspaces and one `tsconfig.json` that checks them together
(`tsc --noEmit -p .`). The root is merged with the one already in `--out`: the
workspace lists the packages it named, then the new ones. With
`--spec <document> --unit <unit id>` (§8.1) a unit whose mapping names a
TypeScript mapper is written as that one package, named after the unit, and its
own modules import one another by path. Both client mappers write the client
locus, so a project with a web and a mobile client declares two client units,
one mapping each, and maps both from the one IR into one workspace. The
client's API calls and the server's routes are generated from the OpenAPI
document of the whole IR folder (§10), whichever package is written.

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
types to the JSON Schema of §10; `irspecs_ts_native_test.dart` maps the same
IR as two client units, web and mobile (§11.2), into one workspace and
type-checks it.

**Pinned versions.** TypeScript 5.9.3, React 19.3, Hono 4.13, Drizzle ORM
0.45; for the mobile client Expo SDK 58 (`~58.0.25`) with the React 19.3.0 and
React Native 0.88.1 it pins, React Navigation 7 (`kTsDependencyVersions`). The
stack — React with plain `fetch`, Expo with React Navigation, Hono, and
Drizzle over PostgreSQL — is the first of each choice; other client stacks,
server frameworks and persistence layers are separate mappers to come.

### 11.1 What each declaration becomes

| IR declaration | TypeScript | In the Meridian trio |
|----------------|------------|--------|
| a domain enum (CE-EN) | `export const X = { a: 'a', … } as const` and `export type X` the union of its values | shared |
| a class of `static const` catalogue entries — operations (CE-API), roles (CE-AZ), error codes (CE-ER), message keys (CE-TX) | the same: a const object of the entries' strings and their union type | shared |
| a plain data class (not abstract, instance fields only) — a wire type (CE-API), the envelope (CE-ER) | `export interface X<T> { field: type; }` | shared |
| an entity (`@CsTable`, CE-DB) | a Drizzle table `export const xTable = pgTable('<table>', { … })`, a column per field from its `columnType` (`uuid`, `varchar(n)`, `numeric(p,s)`, `text`, `integer`, `bigint`, `boolean`, `date`, `jsonb`, `timestamp[tz]`; without one, from the Dart type), `.$type<Enum>()` for an enum-typed column, `.notNull()` unless nullable, and the key's generation on a single-column primary key (`uuid` → `.defaultRandom()`, `auto` → `.generatedByDefaultAsIdentity()`, `sequence` → ``.default(sql`nextval(…)`)``); a third argument `(t) => [ … ]` with the keys and indexes of §11.3; and `export type X = typeof xTable.$inferSelect` | server |
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

### 11.2 The mobile client

`ts-react-native-client` writes the client locus as an Expo project in
TypeScript. It is the web client's mapper with a different package around it:
every IR declaration becomes what §11.1 says, file for file and byte for byte —
the layouts, the routes, the server calls and their collaborators, the API
client (plain `fetch` runs on React Native) and the `tom.ts` of the
constructions — and it depends on the same `ts-shared` package. What differs:

| | Web client (`ts-react-client`) | Mobile client (`ts-react-native-client`) |
|---|---|---|
| package | `react` | `expo`, `react` (the version Expo pins), `react-native`, `@react-navigation/native`, `@react-navigation/native-stack`, `react-native-screens`, `react-native-safe-area-context` |
| entry | the barrel `src/index.ts` (`exports`) | the barrel, and `"main": "src/main.ts"`, which registers the app with Expo's `registerRootComponent`; `app.json` names the Expo app |
| routes (CE-NV) | `TomRouteDefinition` constants | the same, and `src/navigation/app_navigator.ts`: `RootStackParamList` with an entry per route (its `routeId`, its parameters as `string`s), a screen component per route (`<Route>Screen`, throwing `not implemented: screen <routeId>` until Phase 6 writes it) and `AppNavigator`, a React Navigation native stack of the screens in route order |
| layouts (CE-LO) | a component `XView(): ReactElement` that throws | the same: what it renders — DOM elements or React Native views — is Phase 6's |

The navigator is written with `createElement`, so the package needs no JSX
transform and is checked by the workspace's one `tsconfig.json` beside the web
packages. A screen is a route: the IR does not say which layouts make up the
screen a route opens, so a screen's content, like a layout's, is Phase 6's.
A mobile client whose IR holds no route is refused: a navigator needs a
screen. The back-links are the web client's — the same JSDoc tags, which the
test holds file by file against the Dart trio for both clients.

### 11.3 Keys and indexes

An entity's `@CsTableKey` and `@CsTableIndex` markers
(`codespecs_derivation_contract.md` §3.3.11) are the Drizzle table's third
argument, each under its name as the marker states it: the key that
identifies the row (`primary`, `composite`, `natural`, `surrogate`) as
`primaryKey({ name, columns })` — the named form for one column too, since
`.primaryKey()` on a column cannot carry the constraint's name — an
`alternate` key as `unique(name).on(…)`, a `foreign` key as
`foreignKey({ name, columns, foreignColumns })` with `.onDelete(…)` and
`.onUpdate(…)` (the target's table imported; without `referencedColumns` the
target's primary key), and an index as `index(name)` or, unique,
`uniqueIndex(name)`, `.using(<method>, …)` for its `indexType` (`bTree` →
`btree`, `hash`, `gist`, `gin`, `fullText` → `gin`, `spatial` → `gist`), a
descending column as `.desc()`, a `filterCondition` as ``.where(sql`…`)``.
Drizzle has no deferrable constraint, covering columns or clustering; the
PostgreSQL DDL the Go, Java and C# mappers write (§12) carries them.

## 12. The Go server mapper

One mapper writes the server of the IR as a Go module — the standard
library's `net/http` with the chi router, and sqlc for typed SQL over the
tables:

```text
irspecs map --mapper go-server --ir <spec-root>/irspecs --out <dir>
```

It writes the module `<dir>/<server package>/` — with `--spec <document>
--unit <unit id>` (§8.1) a server unit whose mapping names `go-server`, and
the module is then named after the unit. The module holds three packages:
`shared`, the IR's shared locus, which the server needs and Go cannot import
from another module without publishing it; `server`, the server locus of the
share; and `tom`, the part of the Tom substrate the skeleton uses. The routes
come from the OpenAPI document of the whole IR folder (§10), whichever unit is
written. A client locus is not this mapper's: a layout in what it reads is
refused.

**What the output is.** A skeleton, as the Dart trio is: `go build ./...`
and `go vet ./...` pass, `gofmt -l` lists nothing, and it executes nothing —
a handler the specification gives no steps for returns
`tom.NotImplemented("<explication>")`, which wraps `tom.ErrNotImplemented`,
and the router answers that error with a 500, the only status a transport
error has (`codespecs_mapping.md` §7). `go.mod` pins Go 1.24 and chi v5.5.0
and carries its `go.sum`, so the module builds as written. The test
`tom_specs_clitool/test/irspecs_go_test.dart` maps the Meridian IR, builds,
vets and gofmt-checks the module, runs a Go test of the router against the
unimplemented service, runs `sqlc generate` and builds again, holds the
back-links of every file to the Dart trio's and the wire types to the JSON
Schema of §10, prints a body from its steps, and builds and vets a server
unit written as its own module.

**sqlc.** `db/schema.sql` holds a `CREATE TABLE` per entity, a column per
field with its `columnType` (without one, from the Dart type: `integer`,
`double precision`, `boolean`, `timestamptz`, `text`), `NOT NULL` unless
nullable — the schema the cumulative CE-MG migrations converge on
(`codespecs_derivation_contract.md` §6, check 13); the IR carries no
migration DDL of its own. The entity's keys and indexes (`codespecs_derivation_contract.md` §3.3.11) are
PostgreSQL DDL under the names the markers state, the same text the Java
and C# mappers' migrations run:

- the key that identifies the row (`primary`, `composite`, `natural`,
  `surrogate`) as `CONSTRAINT <name> PRIMARY KEY (…)` and each `alternate`
  key as `CONSTRAINT <name> UNIQUE (…)` in the `CREATE TABLE`, `DEFERRABLE
  INITIALLY DEFERRED` when the key is deferrable;
- a single-column primary key's generation as the column's default:
  `auto` → `GENERATED BY DEFAULT AS IDENTITY`, `sequence` →
  `DEFAULT nextval('<sequenceName>')` with a `CREATE SEQUENCE` ahead of the
  tables, `uuid` → `DEFAULT gen_random_uuid()`; `ulid`, `custom` and
  `natural` are the application's;
- every `foreign` key after all the tables, as `ALTER TABLE … ADD CONSTRAINT
  <name> FOREIGN KEY (…) REFERENCES <table> (…)` with `ON DELETE` / `ON
  UPDATE` from its referential actions — without `referencedColumns`, the
  target's primary key — so a table may reference one written after it;
- every index as `CREATE [UNIQUE] INDEX <name> ON <table> [USING <method>]
  (…) [INCLUDE (…)] [WHERE …]`, the columns as written (a direction
  included), and `CLUSTER <table> USING <name>` for a clustered one.

`db/query/<table>.sql` holds the queries of the repository contract:
`Count<Entity>`, `List<Entity>Page`, `Insert<Entity>`, and by the primary
key `Find<Entity>ById` and `Delete<Entity>ById` (a composite key by all its
columns, in key order); an entity without a primary key — which
`validate_codespecs` check 44 reports — gets the first three only.
`sqlc.yaml` (written for sqlc v1.29.0) generates
package `db` beside them, a `uuid` column as a Go `string`. The mapper writes
no sqlc output: `sqlc generate` writes it.

**The wire types are written by the mapper**, in the names oapi-codegen gives
them — an exported field per property, `json:"<property>"`, a pointer and
`,omitempty` for a nullable one, which the JSON Schema leaves out of
`required`. oapi-codegen 2.5.1 cannot read §10's document: it does not
support OpenAPI 3.1, whose `anyOf` with `{type: null}` is how the document
writes a nullable reference.

### 12.1 What each declaration becomes

| IR declaration | Go | Package |
|----------------|----|---------|
| a domain enum (CE-EN) | `type X string` and a const per value, `XValue X = "value"` | shared |
| a class of `static const` catalogue entries — operations (CE-API), roles (CE-AZ), error codes (CE-ER), message keys (CE-TX) | the same: a named string type and a const per entry | shared |
| a plain data class (not abstract, instance fields only) — a wire type (CE-API), the envelope (CE-ER) | ``type X[T any] struct { Field Type `json:"field"` }`` | shared |
| an entity (`@CsTable`, CE-DB) | a struct, each field tagged `db:"<column>" json:"<field>"`, an enum-typed column typed by its enum; `const XTable = "<table>"`; its table in `db/schema.sql` and its queries in `db/query/` | server |
| a repository (`@CsRepository`) | `type XRepository interface { tom.Repository[X, K] }`, `tom.Repository` the method contract of `tom_core_server`'s repository | server |
| a service unit (`@CsServiceUnit`, CE-SU) | `type X interface` of its handlers, each `Name(ctx context.Context, request R) (Result[V], error)`, and `UnimplementedX`, whose every handler returns `tom.NotImplemented`; the routes in `router.go`: `NewRouter(services Services)` returns a chi router with `r.Post("/<operation>", …)` per handler, decoding the request and encoding the answer as JSON | server |
| a collaborator (`@CsCollaborator`) | `type X interface { Method(ctx context.Context, params) (V, error) }` | the file's |
| any other class with methods | a struct, `Collaborator X` for the `late` field, each 3b body printed from its steps (§4.7) — `if err := s.Collaborator.M(ctx, args); err != nil { return err }`, a guard as `appliesN, err := s.Collaborator.G(ctx, args)` and `if appliesN { … }`, `return s.Collaborator.M(ctx, args)`; a body without steps returns `tom.NotImplemented` | the file's |
| a top-level variable with a string initialiser | `const X = "…"` | the file's |

Types follow §10.1's JSON Schema mapping: `String`, `Uri`, `Duration` →
`string`; `DateTime` → `time.Time`; `int` → `int`; `double`, `num` →
`float64`; `bool` → `bool`; `Object`, `dynamic` → `any`; `List`, `Iterable`,
`Set` → slices; `Map<K, V>` → `map[K]V`; `X?` → `*X` (a slice, map or `any`
stays as it is, being nil-able already); a `Cs…Ref`/`…Key`/`…Code` → `string`.
Every method takes `ctx context.Context` first and returns `error` last:
`Future<X>` and `X` → `(X, error)`, `void` and `Future<void>` → `error`. A
file `lib/src/<dir>/<name>.dart` is `<dir>_<name>.go` in its package's
directory, with `_gen` added where Go would read the name as
build-constrained (`…_linux`, `…_test`).

**Back-links and markers** become comment lines of the declaration's and
each member's doc comment: `// codeSpec: <id> source: <section ids>`,
`// docSpec: <section id> — <description>`, every `Cs*` marker as
`// cs: <Marker>(<arguments>)`, any other Dart annotation as
`// dart: <annotation>` — the same section ids as the Dart trio, which the
test holds file by file. The `Unimplemented…` stubs carry no back-links of
their own: they are their interface's.

**Refused, not approximated** (as in §8): a declaration kind with no rule (a
mixin, a top-level function), a layout, a bounded type parameter, a static
field in a struct, a service unit with fields, a construction, an initialiser
that is not a single string, a type the IR does not declare, and a column
type with no SQL type stop the mapper naming the file.

**Pinned versions.** Go 1.24 (`kGoLanguageVersion`), chi v5.5.0
(`kGoDependencyVersions`), sqlc v1.29.0 (`kSqlcVersion`). net/http with chi
and sqlc are the first choice of each; other server frameworks, persistence
layers and a Go Tom substrate are separate mappers to come.

## 13. The Java + Spring Boot server mapper

One mapper writes the server of the IR as a Gradle project — Java 21,
Spring Boot 3 with Spring Web, Spring Data JPA, Flyway and Jakarta Bean
Validation:

```text
irspecs map --mapper java-spring-server --ir <spec-root>/irspecs --out <dir>
```

It writes the project `<dir>/<server package>/` — with `--spec <document>
--unit <unit id>` (§8.1) a server unit whose mapping names
`java-spring-server`, and the project is then named after the unit. Its Java
packages hang off the project's name (lower case, any other character an
underscore): `<base>.shared`, the IR's shared locus, which the server needs;
`<base>.server`, the server locus of the share; `<base>.codespec`, the three
back-link annotations; `<base>.api` and `<base>.api.model`, generated at build
time; and the `@SpringBootApplication` class `<Project>Application` in
`<base>`. A Dart file holding several declarations is a Java file per
declaration. A client locus is not this mapper's: a layout in what it reads is
refused.

**What the output is.** A skeleton, as the Dart trio is: `./gradlew
compileJava` compiles it on JDK 21, and it executes nothing — a handler or
body the specification gives no steps for throws
`UnsupportedOperationException("<explication>")`, which Spring answers with a
500. The project carries `build.gradle.kts`, `settings.gradle.kts` and
`gradle/wrapper/gradle-wrapper.properties` naming Gradle 8.14; the wrapper's
scripts and jar are a binary Gradle writes, so the mapper leaves them to one
`gradle wrapper` (any Gradle). Running the application needs what the IR does
not carry: a datasource. The test
`tom_specs_clitool/test/irspecs_java_test.dart` maps the Meridian IR, compiles
the project with `./gradlew compileJava`, checks that openapi-generator wrote
the HTTP interfaces and the envelopes and none of the project's own types,
holds the back-links of every file to the Dart trio's and the wire types to
the JSON Schema of §10, prints and compiles a body from its steps, and
compiles a server unit written as its own project.

**openapi-generator.** The project carries §10's OpenAPI document as
`src/main/resources/openapi/openapi.json`, and `compileJava` runs
openapi-generator 7.17.0 on it first: the `spring` generator, `interfaceOnly`
and `skipDefaultInterface`, Spring Boot 3 and Jakarta, Bean Validation on. It
writes one interface per operation (`<Operation>Api`, a `@RequestMapping` POST
with `@Valid @RequestBody`), which the controllers implement. Every component
schema the project declares — the wire types, the envelope, the enums, the
entities — is mapped to the project's own class (`schemaMappings` in
`build.gradle.kts`), so the generator writes none of them; what it does write
as models is what the project cannot: the per-operation instantiation of the
generic `Result<T>` envelope (`<Operation>200Response`), which OpenAPI flattens
from its `allOf` and Java cannot express as a generic. A catalogue of string
constants (the error codes) is not mapped, and the generator's own enum for it
goes unused. openapi-generator calls its OpenAPI 3.1 support beta; it reads
§10's document as written.

**Flyway.** `src/main/resources/db/migration/V1__ce_db_tables.sql` holds the
Go mapper's schema (§12): a `CREATE TABLE` per entity with its primary and
alternate keys, then the foreign keys and the indexes — the schema the
cumulative CE-MG migrations converge on (`codespecs_derivation_contract.md`
§6, check 13); the IR carries no migration DDL of its own.

**Keys in JPA** (`codespecs_derivation_contract.md` §3.3.11). The primary key's columns carry `@Id`; a
composite key adds `@IdClass(<Entity>Id.class)` and the class `<Entity>Id`
(the key fields, a no-argument constructor, `equals` and `hashCode`). A
single-column key's generation is `@GeneratedValue`: `uuid` →
`GenerationType.UUID`, `auto` → `IDENTITY`, `sequence` → `SEQUENCE` with its
`@SequenceGenerator(allocationSize = 1)`. An `alternate` key is a
`@UniqueConstraint` of `@Table`, an index an `@Index(name, columnList,
unique)`. A `foreign` key is a read-only association beside its columns —
`@ManyToOne(fetch = LAZY)` with `@JoinColumn(insertable = false, updatable =
false, foreignKey = @ForeignKey(name))` (`@JoinColumns` for several), a field
named after the target and its getter — so the columns stay the entity's
fields while JPA knows the relation; its referential actions, deferrability
and an index's method, covering columns, condition and clustering are the
migration's.

### 13.1 What each declaration becomes

| IR declaration | Java | Package |
|----------------|------|---------|
| a domain enum (CE-EN) | `public enum X { value, … }`, the values as the Dart names them, so they serialise as the JSON Schema's | shared |
| a class of `static const` catalogue entries — operations (CE-API), roles (CE-AZ), error codes (CE-ER), message keys (CE-TX) | `public final class X { public static final String entry = "…"; }` | shared |
| a plain data class (not abstract, instance fields only) — a wire type (CE-API), the envelope (CE-ER) | `public record X<T>(…)`, a component per field with its back-links and its `@CsValidation` rules as Bean Validation constraints: `required` → `@NotNull`, `email` → `@Email`, `pattern` → `@Pattern`, `minLength`/`maxLength`/`minItems`/`maxItems` → `@Size`, `min`/`max` → `@Min`/`@Max` (`@DecimalMin`/`@DecimalMax` for a decimal); the field's doc as the record's `@param` | shared |
| an entity (`@CsTable`, CE-DB) | `@Entity @Table(name = "<table>")`, a private field per column with `@Column(name, columnDefinition, nullable)`, `@Enumerated(EnumType.STRING)` for an enum-typed column, and its getter and setter; `@Id`, `@IdClass`, `@GeneratedValue`, the foreign keys' associations and `@Table`'s unique constraints and indexes from its keys and indexes (§13, Keys in JPA); its table in the Flyway migration | server |
| a repository (`@CsRepository`) | `public interface XRepository extends JpaRepository<X, K>` — Spring Data's repository in the place of `tom_core_server`'s | server |
| a service unit (`@CsServiceUnit`, CE-SU) | a `@Service` class whose handlers keep their signature and throw; a `@RestController` `<Unit>Controller` implementing the generated `<Operation>Api` of each handler, handing the request to the unit and the `Result` back as the operation's envelope | server |
| a collaborator (`@CsCollaborator`) | `public interface X { R method(params); }` | the file's |
| any other class with methods | a class with a private field per Dart field and a constructor taking them, each 3b body printed from its steps (§4.7) — `collaborator.m(args);`, `if (collaborator.g(args)) { … }`, `return collaborator.m(args);` | the file's |

Types follow §10.1's JSON Schema mapping: `String`, `Uri`, `Duration` →
`String`; `DateTime` → `java.time.OffsetDateTime`; `int` → `Integer`;
`double`, `num` → `Double`; `bool` → `Boolean` (boxed, so a `required` rule
can see a missing value); `Object`, `dynamic` → `Object`; `List`,
`Iterable`, `Set` → `List<X>`; `Map<K, V>` → `Map<K, V>`; `X?` → `X`; a
`Cs…Ref`/`…Key`/`…Code` → `String`. A method's `Future<X>` is `X` and
`Future<void>` is `void`: Spring MVC's handlers are synchronous.

**Back-links** are annotations of the project's own `codespec` package, kept
at run time: `@CodeSpec(id = "<id>", source = {"<section id>", …})` and
`@DocSpec({@DocRef(sectionId = "<section id>", description = "…"), …})` on
the declaration and on each member — field, record component, method, enum
constant — with the same section ids as the Dart trio, which the test holds
file by file. Every `Cs*` marker and other Dart annotation is a `Cs: …` /
`Dart: …` line of the Javadoc. The controllers carry no back-links of their
own: they are their service unit's.

**Transport errors** (`codespecs_mapping.md` §7): a request that does not
read or fails its constraints is answered with a 500 by `TransportErrors`, a
`@RestControllerAdvice`, until Phase 6 answers it with the envelope's error
arm — Spring would otherwise answer a 400, which §7 rules out.

**Refused, not approximated** (as in §8): a declaration kind with no rule (a
mixin, a top-level function), a top-level variable (Java has no place for
one), a layout, a bounded type parameter, a static or initialised field of a
data class, an entity or a class, a service unit with fields, a validator with
no Bean Validation constraint, a type the IR does not declare, a name declared
in both the shared and the server locus, and a column type with no SQL type
stop the mapper naming the file.

**Pinned versions** (`kJavaSpringVersions`). Java 21, Gradle 8.14, Spring Boot
3.5.16 (its dependency management pins every library), the
io.spring.dependency-management plugin 1.1.7, openapi-generator 7.17.0.
Spring Boot with Spring Data JPA is the first choice for Java; other
frameworks are separate mappers to come.

## 14. The C# + ASP.NET Core server mapper

One mapper writes the server of the IR as a .NET 8 solution — ASP.NET Core
minimal APIs, EF Core and FluentValidation:

```text
irspecs map --mapper csharp-aspnet-server --ir <spec-root>/irspecs --out <dir>
```

It writes the solution `<dir>/<server package>/` — with `--spec <document>
--unit <unit id>` (§8.1) a server unit whose mapping names
`csharp-aspnet-server`, and the solution is then named after the unit. Its
root namespace is the package name in Pascal case
(`meridian_codespec_server` → `MeridianCodespecServer`), and it holds two
projects: `<Root>.Shared`, a class library with the IR's shared locus, the
FluentValidation validators and the back-link attributes
(`<Root>.CodeSpec`); and `<Root>.Server`, the ASP.NET Core web project with
the server locus of the share, the EF Core context and its first migration,
the repository contract and `Program.cs`. A Dart file holding several
declarations is a C# file per declaration. `Directory.Build.props` targets
`net8.0` with nullable reference types and implicit usings, and `global.json`
asks for an 8.0 SDK. A client locus is not this mapper's: a layout in what it
reads is refused.

**What the output is.** A skeleton, as the Dart trio is: `dotnet build`
builds it with no warning, and it executes nothing — a handler or body the
specification gives no steps for throws `NotImplementedException("<explication>")`.
The server does start, since the database is read only when a repository
first needs it: the test `tom_specs_clitool/test/irspecs_csharp_test.dart`
builds the Meridian solution, runs it and checks that a stub handler, a
request its validator rejects, a request missing a required member and a body
that does not read are each answered with a 500, the only status a transport
error has (`codespecs_mapping.md` §7), and any other verb with a 405. It also
holds the back-links of every file to the Dart trio's and the wire types to
the JSON Schema of §10, prints and builds a body from its steps, and builds a
server unit written as its own solution. Running a repository needs what the
IR does not carry: the connection string `ConnectionStrings:Default`.

**NSwag and Kiota.** The wire types are written by the mapper, as the Go
mapper's are (§12). Kiota generates API clients, not a server. NSwag 14.8
reads §10's document but turns each OpenAPI 3.1 nullable reference
(`anyOf [{$ref}, {type: null}]`) into an empty class of its own — `Result`'s
`value` and `error` become classes named `Value` and `Error` — writes
Newtonsoft.Json attributes where minimal APIs serialise with
System.Text.Json, and generates MVC controllers rather than minimal APIs. The
generic envelope needs no generated form in C#: `Result<T>` serialises as the
document describes it.

**EF Core.** `<Root>DbContext` holds a `DbSet` per entity
(`<Entity>Set`), stores an enum-typed column as the value's name, and
configures each entity's keys and indexes (`codespecs_derivation_contract.md` §3.3.11) under their names:
`HasKey(…).HasName(…)` for the key that identifies the row (`e => new { … }`
for a composite one), its generation on a single-column key (`auto` →
`UseIdentityByDefaultColumn()`, `sequence` → `ValueGeneratedOnAdd()` with
`HasDefaultValueSql("nextval('…')")`, `uuid` → the same with
`gen_random_uuid()`, otherwise `ValueGeneratedNever()`),
`HasAlternateKey(…).HasName(…)`, a foreign key as
`HasOne<Target>().WithMany().HasForeignKey(…)` with `HasPrincipalKey(…)`
when it references other columns than the target's primary key,
`HasConstraintName(…)` and `OnDelete(…)` (`setDefault` has no
`DeleteBehavior`; the DDL carries it, as it carries `ON UPDATE` and
deferrability), and an index as `HasIndex(…, name)` with `IsUnique()`,
`IsDescending(…)`, `HasMethod(…)`, `IncludeProperties(…)` and `HasFilter(…)`
(Npgsql's). The first migration, `Migrations/00000000000000_CeDbTables.cs`,
runs the Go mapper's schema (§12) — a `CREATE TABLE` per entity with its
primary and alternate keys, then the foreign keys and the indexes — the
schema the cumulative CE-MG migrations converge on
(`codespecs_derivation_contract.md` §6, check 13); its `Down` drops each
table with `CASCADE` and the sequences. The IR carries no migration DDL of
its own. The migration has no model snapshot:
`dotnet ef migrations add` would write the whole model as its next
migration.

### 14.1 What each declaration becomes

| IR declaration | C# | Project |
|----------------|----|---------|
| a domain enum (CE-EN) | `public enum X { value, … }`, the values as the Dart names them, serialised as strings (`JsonStringEnumConverter<X>`), so they read as the JSON Schema's | Shared |
| a class of `static const` catalogue entries — operations (CE-API), roles (CE-AZ), error codes (CE-ER), message keys (CE-TX) | `public static class X { public const string entry = "…"; }` | Shared |
| a plain data class (not abstract, instance fields only) — a wire type (CE-API), the envelope (CE-ER) | `public sealed record X<T>(…)`, a parameter per field in Pascal case (System.Text.Json writes it in camel case, as the schema names it), `[property: JsonRequired]` on every non-nullable member — the schema's `required` — and the field's back-links as `[property: …]` | Shared |
| the `@CsValidation` rules of a record's fields | a FluentValidation `XValidator : AbstractValidator<X>`: `required` → `NotNull()`, `email` → `EmailAddress()`, `pattern` → `Matches(…)`, `minLength`/`maxLength` → `MinimumLength`/`MaximumLength`, `minItems`/`maxItems` → a count check, `min`/`max` → `GreaterThanOrEqualTo`/`LessThanOrEqualTo`; a `ValidationFilter<X>` runs it on the operation's request | Shared |
| an entity (`@CsTable`, CE-DB) | `[Table("<table>")] public class X`, a property per column with `[Column("<column>", TypeName = "<columnType>")]`; its keys and indexes in the context (§14, EF Core) and its table in the first migration | Server |
| a repository (`@CsRepository`) | `public interface XRepository : TomRepository<X, TKey>`, `TomRepository` the method contract of `tom_core_server`'s repository (`Tom/TomRepository.cs`) | Server |
| a service unit (`@CsServiceUnit`, CE-SU) | a class registered scoped, its handlers `public virtual` and throwing; in `Program.cs` an `app.MapPost("/<operation>", (Request request, Unit service) => service.Handler(request))` per handler | Server |
| a collaborator (`@CsCollaborator`) | `public interface X { Task<R> Method(params); }` | the file's |
| any other class with methods | a class with a private field per Dart field and a constructor taking them, each 3b body printed from its steps (§4.7) — `await collaborator.M(args);`, `if (await collaborator.G(args)) { … }`, `return await collaborator.M(args);` | the file's |

Types follow §10.1's JSON Schema mapping: `String`, `Uri`, `Duration` →
`string`; `DateTime` → `DateTimeOffset`; `int` → `int`; `double`, `num` →
`double`; `bool` → `bool`; `Object`, `dynamic` → `object`; `List`,
`Iterable`, `Set` → `List<X>`; `Map<K, V>` → `Dictionary<K, V>`; `X?` → `X?`;
a `Cs…Ref`/`…Key`/`…Code` → `string`. A method's `Future<X>` is `Task<X>`,
`Future<void>` is `Task`; member and method names are in Pascal case, enum
values and catalogue entries keep the Dart names (they are the wire's).

**Back-links** are attributes of the `Shared` project's `CodeSpec`
namespace: `[CodeSpec("<id>", "<section id>", …)]` and one
`[DocSpec("<section id>", "<description>")]` per section, on the declaration
and on each member — property, method, enum value, constant — with the same
section ids as the Dart trio, which the test holds file by file. Every `Cs*`
marker and other Dart annotation is a `Cs: …` / `Dart: …` line of the XML doc
comment (a record member's in its `<param>`).

**Transport errors** (`codespecs_mapping.md` §7): `Program.cs` sets
`ThrowOnBadRequest`, so a body that does not read is thrown rather than
answered with a 400, and an exception handler answers every exception with a
500 and its message; `ValidationFilter<T>` answers a request its validator
rejects with a 500 until Phase 6 answers it with the envelope's error arm.

**Refused, not approximated** (as in §8): a declaration kind with no rule (a
mixin, a top-level function), a top-level variable, a layout, a bounded type
parameter, a static or initialised field, a service unit with fields, a
generic record with validation rules, a validator with no FluentValidation
rule, a type the IR does not declare, a name declared in both the shared and
the server locus or one the mapper writes itself (`<Root>DbContext`,
`TomRepository`, `TomPageRequest`), and a column type with no SQL type stop
the mapper naming the file.

**Pinned versions** (`kCsharpVersions`). .NET 8 (`net8.0`, an 8.0 SDK by
`global.json`), EF Core 8.0.34 with Npgsql's provider 8.0.11, FluentValidation
12.2.0. ASP.NET Core minimal APIs with EF Core are the first choice for C#;
other frameworks are separate mappers to come.
