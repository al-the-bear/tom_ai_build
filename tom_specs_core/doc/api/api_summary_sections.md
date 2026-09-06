# TomSpecs Core API Reference: Sections Module

The `sections` module of `tom_specs_core` — the object-model shape every
TomSpecs document node has, and the ten content-typed leaves that fix a body's
format by its Dart type.

For task-oriented guidance see [sections.md](../sections.md). For the rules
governing which model member gets which type, see
[`tom_specs_model_rules.md`](../../../tom_specs_model/doc/tom_specs_model_rules.md)
§5.2.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [DocSpecsSection](#docspecssection)
  - [DocSpecsForm](#docspecsform)
  - [TextSection](#textsection)
  - [CodeSection](#codesection)
  - [DartCodeSection](#dartcodesection)
  - [SqlCodeSection](#sqlcodesection)
  - [DdlCodeSection](#ddlcodesection)
  - [DiagramSection](#diagramsection)
  - [ErDiagramSection](#erdiagramsection)
  - [FlowDiagramSection](#flowdiagramsection)
  - [SequenceDiagramSection](#sequencediagramsection)
  - [GanttDiagramSection](#ganttdiagramsection)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **12 classes**: the universal base `DocSpecsSection`, its
form-value holder `DocSpecsForm`, and **10 content-typed leaves**. The leaves
declare no members of their own — each exists solely to override `content` with
a different class-baked `@ContentType`, so a member's declared type *is* the
declaration of its body format.

Every class is a plain mutable data holder. None validates, parses or performs
I/O, and none throws.

## Class Hierarchy

```
Object
├── DocSpecsSection            (headline, id, content, form, codeSpec)
│   ├── TextSection            @ContentType('text')
│   ├── CodeSection            @ContentType('code')
│   │   ├── DartCodeSection    @ContentType('code-dart')
│   │   ├── SqlCodeSection     @ContentType('code-sql')
│   │   └── DdlCodeSection     @ContentType('code-ddl')
│   └── DiagramSection         @ContentType('mermaid')
│       ├── ErDiagramSection       @ContentType('mermaid-er')
│       ├── FlowDiagramSection     @ContentType('mermaid-flow')
│       ├── SequenceDiagramSection @ContentType('mermaid-sequence')
│       └── GanttDiagramSection    @ContentType('mermaid-gantt')
└── DocSpecsForm               (values)
```

`CodeSection` and `DiagramSection` are usable in their own right, for the case
where the model genuinely does not constrain the dialect.

## Classes

### DocSpecsSection

The universal section base type of the TomSpecs object model. Every
`tom_specs_model` class extends it, which is what makes the model an object
model a `*.md` document can be parsed into rather than a bag of strings.

**Extends:** `Object`

#### Constructors

```dart
DocSpecsSection({
  String? headline,
  String? id,
  String? content,
  DocSpecsForm? form,
  List<String>? codeSpec,
});
```

`codeSpec` defaults to a **fresh** empty list, never a shared constant, so two
default-constructed sections never alias each other's links.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `headline` | `String?` | The stored headline. Authoritative when set; `@Headline` on the member only supplies the default. |
| `id` | `String?` | The stored section id (the `<!--[ID]-->` marker), when present. |
| `content` | `String?` | The section's body. On a `@Form` section this is the preamble; the field values live in `form`. |
| `form` | `DocSpecsForm?` | Parsed `@Form` field values, or `null` when the section carries none. |
| `codeSpec` | `List<String>` | The instance-level forward DocSpecs→CodeSpecs link — the code locations this section maps to. Empty by default. |

### DocSpecsForm

The parsed field values of a `@Form`-annotated section. The generic, model-side
holder; the typed per-field members are what the generated SOM classes add.

**Extends:** `Object`

#### Constructors

```dart
DocSpecsForm({Map<String, Object?>? values});
```

Like `DocSpecsSection.codeSpec`, `values` defaults to a fresh empty map.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `values` | `Map<String, Object?>` | One entry per parsed form field, keyed by the `Field.name` declared in `@Form`. The reference is `final`; the map is mutable. |

### TextSection

A free-text section that may contain narrative, diagrams, or references.

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('text', …)`. |

### CodeSection

A language-agnostic code block section. Use it only where the model does not
fix the language; otherwise reach for one of its three subclasses.

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('code', …)`. |

### DartCodeSection

A Dart code block section.

**Extends:** `CodeSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('code-dart', …)`. |

### SqlCodeSection

An SQL code block section.

**Extends:** `CodeSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('code-sql', …)`. |

### DdlCodeSection

A DDL code block section.

**Extends:** `CodeSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('code-ddl', …)`. |

### DiagramSection

A generic Mermaid diagram section. Use it only where the model does not fix the
diagram kind; otherwise reach for one of its four subclasses.

**Extends:** `DocSpecsSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('mermaid', …)`. |

### ErDiagramSection

A Mermaid ER diagram section.

**Extends:** `DiagramSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('mermaid-er', …)`. |

### FlowDiagramSection

A Mermaid flow chart diagram section.

**Extends:** `DiagramSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('mermaid-flow', …)`. |

### SequenceDiagramSection

A Mermaid sequence diagram section.

**Extends:** `DiagramSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('mermaid-sequence', …)`. |

### GanttDiagramSection

A Mermaid Gantt chart diagram section.

**Extends:** `DiagramSection`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String?` | Overridden solely to carry `@ContentType('mermaid-gantt', …)`. |

## Global Functions and Constants

The module declares none. Everything it exports is one of the twelve classes
above.
