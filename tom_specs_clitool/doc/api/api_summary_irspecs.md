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
- [Functions](#functions)

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `kIrSpecsFormat` | `'irspecs-ir'` | The `format` of an IR document. |
| `kIrSpecsFormatVersion` | `1` | The `formatVersion` of an IR document. |
| `kIrPackageArea` | `'package'` | The area of the document holding the files no area claims. |
| `irCarriedCsModelFields` | `Map<String, Set<String>>` | Every CsModel field the IR carries, by class. |
| `irOmittedCsModelFields` | `Map<String, Map<String, String>>` | The CsModel fields the IR leaves out, each with its reason. |

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
const IrFile(this.locus, this.file);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `locus` | `CsLocus` | The project the file belongs to. |
| `file` | `CsFile` | The file's CsModel reading; read back from the IR, its `source` is empty. |

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

## Functions

| Function | Return Type | Description |
|----------|-------------|-------------|
| `irFromCsModel({required CsLocusProject shared, required CsLocusProject client, required CsLocusProject server, required IrAreaIndex areas})` | `List<IrDocument>` | The IR of a trio: one document per area holding files, in catalogue order, then `package`. |
| `csModelFromIr(List<IrDocument> documents)` | `({CsLocusProject shared, CsLocusProject client, CsLocusProject server})` | The trio a document set describes; each file's `source` is empty. |
| `irDocumentFileName(String area)` | `String` | `<CE-CODE>.ir.yaml`, or `package.ir.yaml`. |
| `snakeCase(String pascal)` | `String` | `DataAccess` → `data_access`: the N7 folder of a canonical id. |
| `irDocumentToData(IrDocument document)` | `Map<String, Object?>` | The document as plain data. |
| `irDocumentFromData(Object? data, {String source = 'IR document'})` | `IrDocument` | The document plain data describes. |
| `writeIrYaml(IrDocument document)` | `String` | The document as YAML text, every string quoted. |
| `readIrYaml(String text, {String source = 'IR document'})` | `IrDocument` | The document YAML text holds. |
| `plainYaml(Object? yaml)` | `Object?` | Parsed YAML as plain maps, lists and scalars. |
| `irspecsParser()` | `ArgParser` | The `irspecs` option set. |
| `runIrspecs(List<String> arguments, {StringSink? out, StringSink? err})` | `Future<int>` | Runs `irspecs`; returns the exit code. |
