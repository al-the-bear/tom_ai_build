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
const IrFile(this.locus, this.file, [this.steps = const []]);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `locus` | `CsLocus` | The project the file belongs to. |
| `file` | `CsFile` | The file's CsModel reading; read back from the IR, its `source` is empty. |
| `steps` | `List<IrBodySteps>` | The steps of the file's form-3b bodies, one record per body. |

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
| `mapDartTom(List<IrDocument> documents)` | `Map<String, String>` | The Dart + Tom mapper: `<package>/<path>` → unformatted source. |
| `formatDartFiles(List<String> paths)` | `Future<void>` | Runs `dart format` over the paths. |
| `writeDartTom(List<IrDocument> documents, String outDir)` | `Future<List<String>>` | Writes and formats the trio the documents describe; returns the written paths. |
| `irspecsParser()` | `ArgParser` | The `irspecs` option set. |
| `runIrspecs(List<String> arguments, {StringSink? out, StringSink? err})` | `Future<int>` | Runs `irspecs`; returns the exit code. |
