# TomSpecs Model — Authoring a Section Class

This guide covers writing a model class in Dart: the shape a class must have,
the member types the tooling recognises, what has to be stamped afterwards, and
the checks that will reject a class that gets it wrong. It is the **package
tier** — how to use this package's code. The *rules* it obeys — which member
must carry which annotation, the field-classification table, the seventeen
structural invariants — belong to
[`tom_specs_model_rules.md`](../tom_specs_model_rules.md) and are cited, never
repeated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [The shape of a section class](#the-shape-of-a-section-class)
  - [The three member kinds](#the-three-member-kinds)
- [Adding a member to an existing class](#adding-a-member-to-an-existing-class)
- [Adding a new class](#adding-a-new-class)
- [What runs after an edit](#what-runs-after-an-edit)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

The model is roughly 3000 flat data classes. There is no base class of its own,
no builder, no code generation in the class itself: a section class is an
ordinary Dart class extending `DocSpecsSection` from `tom_specs_core`, with
public mutable fields and initialisers.

That plainness is load-bearing. The analyzer-based `ModelReader` in
`tom_specs_clitool` reads these classes as *source*, so anything that would show
up as a synthetic element — a getter, a computed field, a mixin adding instance
state — changes what the tooling sees. The snapshot and serialization contract
is supplied from outside instead, through a generated registry, precisely so the
classes stay pristine.

A model edit therefore has two halves: the source change, and the regeneration
that carries it into the nine language runtimes, the schemas, the metadata tree
and the ops registry. The second half is not optional — a freshness stamp fails
the test run if the model moved and the packages did not.

## Quick Start

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

@SectionId('CULA')
@Headline('Current Landscape')
@MapsTo(D01CurrentLandscapeAssessment)
class CurrentLandscape extends DocSpecsSection {
  /// Narrative overview of the systems in scope.
  @SerializationOrder(0)
  @ContentHelp('Name each system and the business capability it serves.')
  TextSection overview = TextSection();

  /// The systems the target solution replaces or integrates with.
  @SerializationOrder(1)
  @SectionId('CULA-SYS-LST')
  @SectionIdPattern('CULA-SYS-xxx')
  @Min(1)
  List<LegacySystem> systems = [];
}

@Headline('Legacy System')
class LegacySystem extends DocSpecsSection {
  @SerializationOrder(0)
  TextSection purpose = TextSection();

  @SerializationOrder(1)
  ErDiagramSection dataShape = ErDiagramSection();
}

/// Stand-in for the real Phase 3 document class.
class D01CurrentLandscapeAssessment {}

void main() {
  final landscape = CurrentLandscape()
    ..overview.content = 'Three order systems with no shared customer record.'
    ..systems.add(LegacySystem()
      ..purpose.content = 'Wholesale order capture.'
      ..dataShape.content = 'erDiagram\n  CUSTOMER ||--o{ ORDER : places');

  print(landscape.overview.content);
  print(landscape.systems.length);
  print(landscape.systems.first.purpose.content);
  print(landscape.systems.first.dataShape is DiagramSection);
}
```

Output:

```
Three order systems with no shared customer record.
1
Wholesale order capture.
true
```

## Core Components

### The shape of a section class

Five properties, all of which the tooling depends on:

| Property | Why |
|----------|-----|
| Extends `DocSpecsSection` | Gives the class the stored headline, id, content and form the parser fills |
| Public mutable fields with initialisers | The editor writes them in place; the ops registry closes over them |
| No getters, no computed members | A getter surfaces as a synthetic field in the analyzer element model and pollutes what `ModelReader` sees |
| No constructor parameters | Every class must be default-constructible — the registry's `cloneShallow` and the container root both rely on it |
| No `dart:mirrors`, no reflection | The editor runs on Flutter, where reflection is unavailable |

The last two together are why `SpecClassOps` exists at all: the snapshot
contract cannot be mixed into three thousand hand-written classes from generated
code, so it is registered against them by type instead. See
[snapshot_and_serialization.md](snapshot_and_serialization.md).

### The three member kinds

| Kind | Declared as | Becomes |
|------|-------------|---------|
| A section with a body | A typed section leaf — `TextSection`, `ErDiagramSection`, … | A content node whose format the type fixes |
| A subsection | Another model class | A nested section |
| A repeated subsection | `List<T>` of a model class | A list container plus its element sections |

There is no fourth kind. A member that wants a scalar is a `@Form` field on the
containing section, not a `String` member of its own — which is what keeps a
section's text in one place.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

/// One class showing all three member kinds.
@SectionId('DEMO')
class Demo extends DocSpecsSection {
  /// A section with a body.
  @SerializationOrder(0)
  TextSection summary = TextSection();

  /// A subsection.
  @SerializationOrder(1)
  DemoDetail detail = DemoDetail();

  /// A repeated subsection.
  @SerializationOrder(2)
  @SectionIdPattern('DEMO-ITM-xxx')
  List<DemoItem> items = [];
}

class DemoDetail extends DocSpecsSection {
  @SerializationOrder(0)
  TextSection notes = TextSection();
}

class DemoItem extends DocSpecsSection {
  @SerializationOrder(0)
  TextSection label = TextSection();
}

void main() {
  final demo = Demo()
    ..summary.content = 'A worked example.'
    ..detail.notes.content = 'Nested one level down.'
    ..items.add(DemoItem()..label.content = 'First')
    ..items.add(DemoItem()..label.content = 'Second');

  print(demo.summary.content);
  print(demo.detail.notes.content);
  print(demo.items.map((i) => i.label.content).join(', '));
}
```

Output:

```
A worked example.
Nested one level down.
First, Second
```

## Adding a member to an existing class

1. **Declare it where it belongs in the source order.** Serialization order
   follows source order, so position is meaningful.
2. **Give it a doc comment.** It becomes the member's documentation in nine
   languages, and the dartdoc coverage gate counts it.
3. **Annotate it.** At minimum a `@SerializationOrder` (stamped, see below); a
   `@SectionIdPattern` if it is a list; `@ContentHelp` if an author needs
   guidance.
4. **Re-stamp**, then **regenerate**. Never hand-write the stamp number.

The one thing not to do is renumber the surrounding `@SerializationOrder`
values by hand. Insert the member in the right place and let
`stamp_serialization_order.dart` renumber every member of the class from source
order — it is idempotent, and the SOM generator refuses to run past an unstamped
member, so a forgotten stamp is a hard error rather than a silent misordering.

## Adding a new class

A new class needs, in addition to the above:

- A class-level `@SectionId` — unless it is a **list element class**, which
  carries none because the containing field's `@SectionIdPattern` names its
  instances instead.
- A routing verdict: `@CodeSpecKind`, `@FollowUpKind` or `@NoArtifact`. Every
  reachable section must carry exactly one, which is what makes "produces
  nothing" a recorded decision rather than an omission.
- Reachability from a document root. A class no root reaches is not part of the
  model, and the walk that builds the metadata tree will never see it.

## What runs after an edit

Three commands, in this order. The first two live in `tom_specs_clitool`:

```bash
# 1. Renumber @SerializationOrder from source order (idempotent).
dart run bin/stamp_serialization_order.dart

# 2. Regenerate: the nine language packages, the metadata trees, the schemas,
#    the ops registry, and the model freshness stamp.
dart run bin/generate_som.dart

# 3. Refresh the committed outlines.
./tool/regenerate_outlines.sh
```

Step 2 is the one that cannot be skipped. It writes
`tool/model_surface.stamp.json` from a fingerprint of the model **source**, and
`test/model_freshness_test.dart` recomputes that fingerprint in the default test
run — so a model edit that never reached the nine language packages fails a test
rather than shipping.

## Error Handling

A model class throws nothing; it is data. Every diagnostic comes from a reader,
and knowing which one narrows the search:

| Mistake | Reported by | When |
|---------|-------------|------|
| A member with no `@SerializationOrder` | `generate_som.dart` | Hard error; the generator refuses to run |
| A reachable section with no routing verdict | The validator, invariant `ROUTE-TOTAL` | Generation time |
| A duplicate `@SectionId` | The validator, invariant `ID-UNIQUE` | Generation time |
| A `@SectionId` on a list element class | The validator | Generation time |
| A member whose type is not one of the three kinds | The validator's `tom_specs_model_rules.md` §6.1 field-type check | Generation time |
| A section class without a `content: String?` override | The validator's `tom_specs_model_rules.md` §5.2 check | Generation time |
| A cycle in the class graph | The validator's cycle detection | Generation time |
| A model edit with no regeneration | `model_freshness_test.dart` | Default `dart test` run |
| A getter added to a model class | Silently changes the reflected model | **Not caught** — see below |

The last row is the one to be careful about. Adding a getter does not fail
anything immediately; it changes what `ModelReader` sees, and the effect appears
downstream as an unexpected member in the metadata tree. That is why the
"no getters" rule is stated as a rule rather than left to a check.

## Best Practices

- **Insert, then stamp.** Never renumber `@SerializationOrder` by hand.
- **Write the doc comment as you declare the member.** It travels into nine
  languages; a comment added later is a comment that has to be regenerated in.
- **Pick the most specific section leaf.** The declared type is how the body's
  format is declared; a general type where a specific one exists drops it.
- **Keep classes free of behaviour.** No getters, no computed members, no
  constructor parameters — the tooling reads these classes as source.
- **Record the routing verdict deliberately.** `@NoArtifact(reason, note:)` is a
  decision; a missing verdict is an omission, and only the first is legible.
- **Run the full sequence after every model edit.** Stamp, regenerate,
  re-outline — the freshness test will catch a skipped step, but at the cost of
  a failing suite rather than a clean commit.

---

Back to the [package documentation index](index.md).
