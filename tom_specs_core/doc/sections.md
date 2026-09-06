# TomSpecs Core — Section Types

The section types are the object-model shape every TomSpecs document node has:
a stored headline, a stored section id, a body, an optional parsed form, and a
list of CodeSpecs back-links. `DocSpecsSection` is that shape, and the ten
content-typed leaves below are the same shape with the content format fixed by
the field's declared Dart type. This guide covers constructing them, the
content/form split, and choosing a leaf type; the *rules* for when a model
member gets which type belong to
[`tom_specs_model_rules.md`](../../tom_specs_model/doc/tom_specs_model_rules.md)
§5.2 and are cited, not repeated, here.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [DocSpecsSection](#docspecssection)
  - [DocSpecsForm](#docspecsform)
- [The content-typed leaves](#the-content-typed-leaves)
- [The content/form split](#the-contentform-split)
- [CodeSpecs back-links](#codespecs-back-links)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

A TomSpecs specification is a tree of sections. Every section — whether it holds
a paragraph, a diagram, a form or nothing but children — has the same four
stored parts, so one class can carry them all:

| Part | Member | Holds |
|------|--------|-------|
| Headline | `headline` | The rendered `## …` text, as stored |
| Section id | `id` | The `<!--[ID]-->` marker, when present |
| Body | `content` | The section's free text |
| Form values | `form` | One parsed value per `@Form` field, when the section is a form |
| CodeSpecs links | `codeSpec` | The code locations this section maps to |

`DocSpecsSection` is that class. Every model class in `tom_specs_model` extends
it, which is what makes the model an *object model* a `*.md` document can be
parsed into rather than a bag of strings.

The ten leaf types add exactly one thing: a class-baked `@ContentType` on
`content`. They declare no new members. Choosing `ErDiagramSection` over
`TextSection` for a member is therefore how a model author says "this body is a
Mermaid ER diagram" — the format travels with the type instead of with a
comment.

## Quick Start

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  final overview = TextSection()
    ..headline = 'Data model overview'
    ..id = 'IFM-DM'
    ..content = 'Three aggregates: Customer, Order, Shipment.';

  print(overview.headline);
  print(overview.id);
  print(overview.content);
  print(overview is DocSpecsSection);
}
```

Output:

```
Data model overview
IFM-DM
Three aggregates: Customer, Order, Shipment.
true
```

## Core Components

### DocSpecsSection

The universal section base type. Every member is mutable, because a section is
edited in place by the editor and by the parser alike.

| Member | Type | Meaning |
|--------|------|---------|
| `headline` | `String?` | The stored headline. Authoritative when set; `@Headline` on the member only supplies the default. |
| `id` | `String?` | The stored section id, when the document carries one. |
| `content` | `String?` | The section's body. For a form section this is the preamble — see [below](#the-contentform-split). |
| `form` | `DocSpecsForm?` | Parsed form-field values, or `null` when the section carries none. |
| `codeSpec` | `List<String>` | Forward DocSpecs→CodeSpecs links. Empty by default. |

The constructor takes all five as optional named arguments and defaults
`codeSpec` to a fresh empty list, so two sections never share one:

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  final a = DocSpecsSection();
  final b = DocSpecsSection();
  a.codeSpec.add('CsOrder');

  print(a.codeSpec);
  print(b.codeSpec);
  print(identical(a.codeSpec, b.codeSpec));
}
```

Output:

```
[CsOrder]
[]
false
```

### DocSpecsForm

Holds the parsed values of a `@Form`-annotated section, keyed by the field name
declared in the `@Form([Field(...)])` annotation. Values are `Object?` — this is
the generic, model-side holder; the *typed* per-field members are what the
generated SOM classes add on top.

| Member | Type | Meaning |
|--------|------|---------|
| `values` | `Map<String, Object?>` | One entry per parsed field, keyed by `Field.name`. `final`, but the map itself is mutable. |

Like `DocSpecsSection.codeSpec`, `values` defaults to a fresh empty map rather
than a shared constant.

## The content-typed leaves

Each leaf overrides `content` for the sole purpose of changing the baked-in
`@ContentType`. None adds a member, and none adds a constructor parameter.

| Class | `@ContentType` | Extends | Body format |
|-------|----------------|---------|-------------|
| `DocSpecsSection` | *(none)* | — | Untyped: whatever the member's own annotations say |
| `TextSection` | `text` | `DocSpecsSection` | Free narrative prose |
| `CodeSection` | `code` | `DocSpecsSection` | A code block, language unspecified |
| `DartCodeSection` | `code-dart` | `CodeSection` | Dart |
| `SqlCodeSection` | `code-sql` | `CodeSection` | SQL |
| `DdlCodeSection` | `code-ddl` | `CodeSection` | DDL |
| `DiagramSection` | `mermaid` | `DocSpecsSection` | Mermaid, kind unspecified |
| `ErDiagramSection` | `mermaid-er` | `DiagramSection` | Mermaid `erDiagram` |
| `FlowDiagramSection` | `mermaid-flow` | `DiagramSection` | Mermaid `flowchart` |
| `SequenceDiagramSection` | `mermaid-sequence` | `DiagramSection` | Mermaid `sequenceDiagram` |
| `GanttDiagramSection` | `mermaid-gantt` | `DiagramSection` | Mermaid `gantt` |

The hierarchy is two levels deep on purpose. `CodeSection` and `DiagramSection`
are usable in their own right when the model genuinely does not constrain the
dialect; the specific leaves are for when it does. Picking the general type
where a specific one exists costs the reader the format and costs the tooling
the ability to check it.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

/// A model class as it would be written in `tom_specs_model`.
class DataModel extends DocSpecsSection {
  /// Overview of the data model including all entity relationships.
  TextSection dataModelOverview = TextSection();

  /// Entity-relationship diagram of the data model.
  ErDiagramSection erDiagram = ErDiagramSection();
}

void main() {
  final model = DataModel()
    ..dataModelOverview.content = 'Three aggregates.'
    ..erDiagram.content = 'erDiagram\n  CUSTOMER ||--o{ ORDER : places';

  print(model.dataModelOverview.content);
  print(model.erDiagram is DiagramSection);
  print(model.erDiagram is CodeSection);
}
```

Output:

```
Three aggregates.
true
false
```

## The content/form split

A form section has two kinds of text: free prose before the first field line,
and the field lines themselves. They land in different members, and the reason
is that a section's free text should have exactly one home whether or not the
section happens to be a form.

- **`content`** — the preamble. The same member a non-form section's body uses.
- **`form.values`** — one entry per field, keyed by the `@Form` field name.

`form` stays `null` for a section that carries no form values, so a `null` check
distinguishes "not a form" from "a form with nothing filled in" (an empty
`values` map).

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  final plain = DocSpecsSection()..content = 'Just prose.';

  final withForm = DocSpecsSection()
    ..content = 'Context for the reader.'
    ..form = DocSpecsForm(values: {'owner': 'Platform team', 'priority': 1});

  print('${plain.content} / form=${plain.form}');
  print('${withForm.content} / owner=${withForm.form!.values['owner']}');
  print(withForm.form!.values.keys.toList());
}
```

Output:

```
Just prose. / form=null
Context for the reader. / owner=Platform team
[owner, priority]
```

The DocSpecs markdown rule that puts the preamble before the first field line is
`SOM §11.4`; this package stores the result of applying it and does not restate
it.

## CodeSpecs back-links

`codeSpec` is the instance-level forward link from a specification section to
the CodeSpecs code it produced — the concrete half of the bidirectional link
whose type-level half is `@CodeSpecKind`. It holds code locations, one string
each:

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  final section = DocSpecsSection()
    ..id = 'IFM-ENT-ORDER'
    ..codeSpec = ['CsOrder', 'CsOrder.total', 'CsOrderRepository'];

  print(section.codeSpec.length);
  print(section.codeSpec.join(', '));
}
```

Output:

```
3
CsOrder, CsOrder.total, CsOrderRepository
```

It is empty by default so an untouched section stays byte-stable through a
round-trip. What the strings mean, and how they pair with the code-side
`@DocSpec` annotation, is
[`codespecs_mapping.md`](../../tom_specs_model/doc/codespecs_mapping.md) §9.2.

## Error Handling

These classes throw nothing. They are plain mutable data holders with no
validation, no parsing and no I/O — which is deliberate: validation of a
*document instance* is the runtime's `validateDocument`, and validation of the
*model's annotations* is `tom_specs_clitool`'s static tier. A section type that
rejected its own content would put a third answer in the middle.

Three consequences worth knowing:

| Situation | What happens | Where the check lives |
|-----------|--------------|-----------------------|
| `content` holds text that does not match the leaf's `@ContentType` | Accepted silently | The instance-tier validator in each SOM runtime |
| `form.values` holds a key no `@Form` field declares | Accepted silently | The instance-tier validator |
| `headline` disagrees with the member's `@Headline` default | Accepted; the stored value wins | By design — see `tom_specs_model_rules.md` §5.2 |

Reading `form!.values` on a section whose `form` is `null` throws a
`TypeError` from the null assertion, as it would for any nullable member. Check
`form != null` first, or use `section.form?.values['owner']`.

## Best Practices

- **Pick the most specific leaf type.** `SqlCodeSection` over `CodeSection` over
  `DocSpecsSection` — the type is how the format is declared, and a general type
  where a specific one exists silently drops that declaration.
- **Never subclass a leaf to add fields.** The leaves exist to carry a
  `@ContentType` and nothing else; a section with structure is a model class
  extending `DocSpecsSection` with its own members.
- **Put free text in `content`, always.** Including on a form section. A second
  home for prose is the thing the content/form split exists to prevent.
- **Do not share a `codeSpec` list or a `values` map between sections.** The
  constructors already give each instance its own; assigning one section's list
  to another reintroduces the aliasing they avoid.
- **Leave `codeSpec` empty unless a Phase-4 run filled it.** It is generated
  traceability, not authoring input.

---

Back to the [documentation index](index.md).
