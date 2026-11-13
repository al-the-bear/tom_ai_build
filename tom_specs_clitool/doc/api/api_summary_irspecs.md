# TomSpecs CLI Tool API Reference: IR Specs

The IR Specs intermediate representation: a CodeSpecs trio as
language-neutral data, one document per area, its YAML file form and the
`irspecs` command that writes it.

What a document holds, how it is written and what it leaves out is
[`irspecs_ir.md`](../../../tom_core_codespecs/doc/irspecs_ir.md); the JSON
Schema is `tool/irspecs_ir.schema.json`.

## Table of Contents

- [Constants](#constants)
- [Classes](#classes)
  - [IrProject](#irproject)
  - [IrFile](#irfile)
  - [IrDocument](#irdocument)
  - [IrAreaIndex](#irareaindex)
  - [IrSpecsException](#irspecsexception)
  - [IrStep, IrCallStep, IrReturnStep, IrGuardedStep](#irstep-ircallstep-irreturnstep-irguardedstep)
  - [IrBodySteps and IrStepIssue](#irbodysteps-and-irstepissue)
  - [IrStepViolation](#irstepviolation)
  - [IrMapException](#irmapexception)
  - [IrUnit](#irunit)
  - [IrEmission](#iremission)
  - [IrIndex and IrEntry](#irindex-and-irentry)
  - [IrSchemaBuilder](#irschemabuilder)
- [Functions](#functions)

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `kIrSpecsFormat` | `'irspecs-ir'` | The `format` of an IR document. |
| `kIrSpecsFormatVersion` | `1` | The `formatVersion` of an IR document. |
| `kIrPackageArea` | `'package'` | The area of the document holding the files no area claims. |
| `irCarriedCsModelFields` | `Map<String, Set<String>>` | Every CsModel field the IR carries, by class. |
| `irOmittedCsModelFields` | `Map<String, Map<String, String>>` | The CsModel fields the IR leaves out, each with its reason. |
| `kCollaboratorField` | `'collaborator'` | The field a 3b body reaches its collaborator through. |
| `kGuardSuffix` | `'Applies'` | The fixed suffix of a guard method's name (B4). |
| `irStepRules` | `Map<String, String>` | The step validation rules `S1` … `S5`, each with what it holds. |
| `kDartTomMapper` | `'dart-tom'` | The Dart + Tom mapper's id, as `irspecs map --mapper` names it. |
| `kTsSharedMapper`, `kTsReactClientMapper`, `kTsHonoServerMapper` | `'ts-shared'`, `'ts-react-client'`, `'ts-hono-server'` | The TypeScript mappers' ids (`irspecs_ir.md` §11). |
| `kTsMappers` | `Map<String, CsLocus>` | Each TypeScript mapper and the locus it writes. |
| `kTsDependencyVersions` | `Map<String, String>` | The versions the TypeScript workspace pins. |
| `kGoServerMapper` | `'go-server'` | The Go server mapper's id (`irspecs_ir.md` §12). |
| `kGoLanguageVersion` | `'1.24'` | The `go` directive of the module's `go.mod`. |
| `kGoDependencyVersions` | `Map<String, String>` | The modules the Go server requires (chi), and their versions. |
| `kSqlcVersion` | `'v1.29.0'` | The sqlc release the module's `sqlc.yaml` is written for. |
| `kJavaSpringServerMapper` | `'java-spring-server'` | The Java + Spring Boot server mapper's id (`irspecs_ir.md` §13). |
| `kJavaSpringVersions` | `Map<String, String>` | The Java release, the Gradle and the Gradle plugins the project pins. |
| `irStandards` | `Map<String, IrEmission Function(List<IrDocument>)>` | The standards `irspecs emit --standard` writes: `openapi`, `jsonschema`, `icu`, `asyncapi`. |
| `kOpenApiVersion`, `kOpenApiFile` | `'3.1.0'`, `'openapi.json'` | The OpenAPI emitter's version and file. |
| `kJsonSchema202012`, `kJsonSchemaFile` | the 2020-12 dialect URI, `'schema.json'` | The JSON Schema emitter's dialect and file. |
| `kIcuFile` | `'messages.json'` | The ICU emitter's file. |
| `kAsyncApiVersion`, `kAsyncApiFile` | `'3.0.0'`, `'asyncapi.json'` | The AsyncAPI emitter's version and file. |
| `kResultEnvelope` | `'Result'` | The CE-ER envelope type an operation's response wraps. |
| `irValidationKeywords` | `Map<String, String>` | The closed `@CsValidation` tokens and the JSON Schema keyword each becomes. |

## Classes

### IrProject

One project of the trio, named in every document's header.

#### Constructors
```dart
const IrProject(this.locus, this.packageName);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `locus` | `CsLocus` | Which project. |
| `packageName` | `String` | Its package name. |

### IrFile

One generated file in an IR document: its project and its CsModel reading.

#### Constructors
```dart
const IrFile(
  this.locus,
  this.file, [
  this.steps = const [],
  this.units = const [],
]);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `locus` | `CsLocus` | The project the file belongs to. |
| `file` | `CsFile` | The file's CsModel reading; read back from the IR, its `source` is empty. |
| `steps` | `List<IrBodySteps>` | The steps of the file's form-3b bodies, one record per body. |
| `units` | `List<String>` | The generation units the file is written for (`irspecs_ir.md` §8.1); empty: every unit of its locus mapping the area. |

### IrDocument

One IR document: the files of one area, across the three projects.

#### Constructors
```dart
const IrDocument({
  required this.area,
  required this.projects,
  required this.files,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `area` | `String` | The area code (`CE-DB`), or `kIrPackageArea`. |
| `projects` | `List<IrProject>` | The trio's three projects, in emission order. |
| `files` | `List<IrFile>` | The area's files, by project, then by path. |
| `fileName` | `String` | The file name the document is written to. |

### IrAreaIndex

Which area a generated file belongs to: the N7 folder, then the first
`@CodeSpec` id's part, then the first part marker, else `package`.

#### Constructors
```dart
factory IrAreaIndex(CodeSpecsAreaCatalog catalog)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `areaOrder` | `List<String>` | The area codes in catalogue order. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `areaOf(CsFile file)` | `String` | The area of `file`. |

### IrSpecsException

Raised when an IR document or document set cannot be read.

#### Constructors
```dart
const IrSpecsException(this.message);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | What is wrong. |

### IrStep, IrCallStep, IrReturnStep, IrGuardedStep

One step of a 3b body (`irspecs_ir.md` §4.7): the sealed `IrStep` with its
`line`, and its three kinds.

#### Constructors
```dart
const IrCallStep(this.method, this.arguments, int line);
```

```dart
const IrReturnStep(this.method, this.arguments, int line);
```

```dart
const IrGuardedStep(this.guard, this.arguments, this.steps, int line);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `line` | `int` | The line of the statement the step was read from (all kinds). |
| `method` | `String` / `String?` | The collaborator method called; on `IrReturnStep`, `null` for a bare `return;`. |
| `guard` | `String` | The guard method of an `IrGuardedStep`. |
| `arguments` | `List<String>` | The call's arguments as written. |
| `steps` | `List<IrStep>` | The steps an `IrGuardedStep`'s condition governs. |

### IrBodySteps and IrStepIssue

The steps of one 3b body, or the B-rule that kept it from having them.

#### Constructors
```dart
const IrBodySteps.read(this.owner, this.body, List<IrStep> this.steps);
```

```dart
const IrBodySteps.refused(this.owner, this.body, IrStepIssue this.issue);
```

```dart
const IrStepIssue(this.rule, this.message, this.line);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `owner` | `String` | The top-level declaration the body belongs to. |
| `body` | `String` | The body's method name. |
| `steps` | `List<IrStep>?` | The steps; `null` when refused. |
| `issue` | `IrStepIssue?` | Why the body is not steps; `null` when it is. |
| `IrStepIssue.rule` | `String` | `B1` … `B8`, or `3b`. |
| `IrStepIssue.message` | `String` | What the statement does instead. |
| `IrStepIssue.line` | `int` | The statement's line. |

### IrStepViolation

One step that breaks a validation rule.

#### Constructors
```dart
const IrStepViolation(
  this.rule,
  this.file,
  this.body,
  this.line,
  this.message,
);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `rule` | `String` | `S1` … `S5`. |
| `file` | `String` | The file the body is in. |
| `body` | `String` | `<owner>.<method>`. |
| `line` | `int` | The step's line, or the body's. |
| `message` | `String` | What is wrong. |

### IrMapException

Raised when the IR holds something the Dart + Tom mapper has no rule to print.

#### Constructors
```dart
const IrMapException(this.message);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | What could not be printed, and where. |

### IrUnit

A generation unit as the mapper sees it (`irspecs_ir.md` §8.1).

#### Constructors
```dart
const IrUnit({
  required this.unitId,
  required this.locus,
  required this.mappings,
});
```

```dart
factory IrUnit.fromRegister(SpecGenerationUnit unit)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `unitId` | `String` | The unit's id, which is also its package name. |
| `locus` | `CsLocus` | The locus whose IR files the unit takes. |
| `mappings` | `Map<String, String>` | Area code → mapper id; the first mapping of an area wins. |

`IrUnit.fromRegister` throws `IrSpecsException` for a unit whose kind is not
shared, client or server.

### IrEmission

What a standard emitter wrote, and what it could not say (`irspecs_ir.md` §10).

| Property | Type | Description |
|----------|------|-------------|
| `files` | `Map<String, String>` | The files written, path relative to `--out` → text. |
| `notExpressed` | `List<String>` | Every fact the standard has no form for, one line each (§10.2). |

### IrIndex and IrEntry

A read-only index over an IR document set: `topLevel` (every top-level
declaration as an `IrEntry` of `area`, `file` and `declaration`),
`membersOf(entry)`, `inArea(area)` and `title` (the shared project's package
name).

### IrSchemaBuilder

Builds the JSON Schema 2020-12 schemas both the JSON Schema and the OpenAPI
emitter write (`irspecs_ir.md` §10.1).

```dart
IrSchemaBuilder(IrIndex index, {required String refBase, required List<String> notExpressed})
```

| Member | Description |
|--------|-------------|
| `build()` | Builds every schema of CE-EN, CE-ER, CE-API and CE-DB into `defs`, by declaration name; returns it. |
| `fieldSchema(String type, String where)` | The schema of one field type outside any `$defs`. |
| `refBase` | Where a reference points: `#/$defs/` or `#/components/schemas/`. |

## Functions

| Function | Return Type | Description |
|----------|-------------|-------------|
| `irFromCsModel({required CsLocusProject shared, required CsLocusProject client, required CsLocusProject server, required IrAreaIndex areas})` | `List<IrDocument>` | The IR of a trio: one document per area holding files, in catalogue order, then `package`. |
| `csModelFromIr(List<IrDocument> documents)` | `({CsLocusProject shared, CsLocusProject client, CsLocusProject server})` | The trio a document set describes; each file's `source` is empty. |
| `irDocumentFileName(String area)` | `String` | `<CE-CODE>.ir.yaml`, or `package.ir.yaml`. |
| `collaboratorOwners(CsFile file)` | `Set<String>` | The declarations of a file that have a `collaborator` field. |
| `stepBodiesOf(CsFile file)` | `List<IrBodySteps>` | Every form-3b body of a declaration with a collaborator, read into steps. |
| `readIrSteps(String owner, CsMethodBody body)` | `IrBodySteps` | One body's steps, or the rule it breaks. |
| `validateIrSteps(List<IrDocument> documents)` | `List<IrStepViolation>` | Every violation of S1–S5 in a document set. |
| `snakeCase(String pascal)` | `String` | `DataAccess` → `data_access`: the N7 folder of a canonical id. |
| `irDocumentToData(IrDocument document)` | `Map<String, Object?>` | The document as plain data. |
| `irDocumentFromData(Object? data, {String source = 'IR document'})` | `IrDocument` | The document plain data describes. |
| `writeIrYaml(IrDocument document)` | `String` | The document as YAML text, every string quoted. |
| `readIrFolder(String dir)` | `List<IrDocument>` | Every `*.ir.yaml` document in a folder, in file-name order. |
| `irFileToData(IrFile entry)` | `Map<String, Object?>` | One file entry as data — the record check 31 compares between two IR runs. |
| `csModelForChecks(List<IrDocument> documents)` | `({CsLocusProject shared, CsLocusProject client, CsLocusProject server})` | The trio for the forty-one checks: `csModelFromIr`, each file's `source` its IR record. |
| `readIrYaml(String text, {String source = 'IR document'})` | `IrDocument` | The document YAML text holds. |
| `plainYaml(Object? yaml)` | `Object?` | Parsed YAML as plain maps, lists and scalars. |
| `irDocumentsForUnit(List<IrDocument> documents, IrUnit unit, {required String mapper})` | `List<IrDocument>` | The share of the documents `mapper` writes for `unit`: its locus, its areas mapped to `mapper` and the `package` document, files that name the unit or no unit; its project renamed to the unit. |
| `mapDartTom(List<IrDocument> documents)` | `Map<String, String>` | The Dart + Tom mapper: `<package>/<path>` → unformatted source. |
| `formatDartFiles(List<String> paths)` | `Future<void>` | Runs `dart format` over the paths. |
| `writeDartTom(List<IrDocument> documents, String outDir)` | `Future<List<String>>` | Writes and formats the trio the documents describe; returns the written paths. |
| `emitOpenApi(List<IrDocument> documents)` | `IrEmission` | The OpenAPI 3.1 document, `openapi.json`. |
| `emitJsonSchema(List<IrDocument> documents)` | `IrEmission` | The JSON Schema 2020-12 document, `schema.json`. |
| `emitIcu(List<IrDocument> documents)` | `IrEmission` | The ICU MessageFormat catalogue, `messages.json`. |
| `emitAsyncApi(List<IrDocument> documents)` | `IrEmission` | The AsyncAPI 3 document, `asyncapi.json`. |
| `icuMessageFor(String baseCopy)` | `String` | A base copy as an ICU message: `{name}` kept, other braces and apostrophes quoted. |
| `icuSyntaxErrors(String message)` | `List<String>` | The ICU MessageFormat syntax errors of a message; empty when it parses. |
| `irJson(Object? data)` | `String` | JSON as the emitters write it: two-space indented, one trailing newline. |
| `irMarker`, `irString`, `irInitialiserString`, `irDocText`, `irHandlerResult` | — | The helpers the emitters read the IR with: a marker by name, a value's string, an initialiser's string argument, a doc comment's text, a handler's response type. |
| `mapTypeScript(List<IrDocument> share, String mapper, {List<IrDocument>? all})` | `Map<String, String>` | A TypeScript mapper's package and the workspace root, `<path>` → text; the API client and routes read the OpenAPI of `all`. Throws `IrMapException` on a construct it has no rule for. |
| `mapGoServer(List<IrDocument> share, {List<IrDocument>? all})` | `Map<String, String>` | The Go module of the share's server, `<module>/<path>` → text: the `shared`, `server` and `tom` packages, `router.go` from the OpenAPI of `all`, `go.mod`/`go.sum`, and the sqlc schema, queries and `sqlc.yaml`. Throws `IrMapException` on a construct it has no rule for. |
| `mapJavaSpring(List<IrDocument> share, {List<IrDocument>? all})` | `Map<String, String>` | The Gradle project of the share's server, `<project>/<path>` → text: the `shared`, `server` and `codespec` packages, the controllers on the openapi-generator interfaces, the Flyway migration, the OpenAPI document of `all` and the build files. Throws `IrMapException` on a construct it has no rule for. |
| `javaPackageName(String name)` | `String` | The Java package of a package name: lower case, every other character an underscore. |
| `irDeclarationShape(IrIndex index, IrEntry e, {required String mapper})` | `IrShape` | What a top-level IR declaration is, for every language mapper: catalogue, plain data, entity, layout, service unit, contract, class, variable. |
| `irFileIndex`, `irSplitTypeArguments`, `irTypeParameterNames`, `irSnake` | | The other helpers the language mappers share (`mappers/mapper_common.dart`). |
| `openApiOperations(Map<String, dynamic> openApi)` | `List<IrOpenApiOperation>` | The operations of a document `emitOpenApi` wrote: path, operation id, request and response schema names, whether the response is the Result envelope. What the mappers write the API client and the routes from. |
| `irspecsParser()` | `ArgParser` | The `irspecs` option set. |
| `runIrspecs(List<String> arguments, {StringSink? out, StringSink? err})` | `Future<int>` | Runs `irspecs`; returns the exit code. |
