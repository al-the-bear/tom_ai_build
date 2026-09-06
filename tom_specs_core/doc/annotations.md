# TomSpecs Core — Annotations

The annotation library is the vocabulary a TomSpecs model class is written in.
This guide is task-oriented: it shows how to reach for the right annotation
while authoring a model class, what each one changes downstream, and which
mistakes each is there to catch. The per-annotation catalogue with every
signature and target is the [README](../README.md#annotation-catalogue); the
mechanical reference is [`api/api_summary_annotations.md`](api/api_summary_annotations.md);
and the *rules* — when a member must carry which annotation, and what the
validator enforces — belong to
[`tom_specs_model_rules.md`](../../tom_specs_model/doc/tom_specs_model_rules.md)
and are cited here, never repeated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [Annotations are plain const classes](#annotations-are-plain-const-classes)
  - [The five families](#the-five-families)
- [Giving a section an identity](#giving-a-section-an-identity)
- [Declaring what a section holds](#declaring-what-a-section-holds)
- [Constraining a value](#constraining-a-value)
- [Discriminated subsection groups](#discriminated-subsection-groups)
- [Tracing a section to its document](#tracing-a-section-to-its-document)
- [Routing a section to an artifact](#routing-a-section-to-an-artifact)
- [Pinning serialization order](#pinning-serialization-order)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

An annotation here does nothing at run time. Every one is a `const` class with
public final fields, and the whole library is consumed by *readers*: the
analyzer-based `ModelReader` in `tom_specs_clitool`, the DocSpecs schema
generator, the nine SOM emitters, and the structural validator. Applying an
annotation is therefore a statement to those readers, and the cost of getting it
wrong is paid at generation time, not at run time.

The library carries **34 annotation classes** (35 types, since `@Form` comes
with its `Field` element) and **3 closed enums**. The catalogue is a live
surface rather than a document: every class under `lib/src/annotations/` must
name a destination in `tom_specs_clitool`'s `docspecs_annotation_mapping.dart`,
and every declared schema key must actually be emitted — so an annotation added
without deciding where it lands fails a test rather than being quietly ignored.

## Quick Start

A model class is an ordinary Dart class extending `DocSpecsSection`. The
annotations say who it is, what it holds, and where it goes:

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

@SectionId('INDM')
@Headline('Information Model')
@MaxDepth(2)
class InformationModel extends DocSpecsSection {
  @SerializationOrder(0)
  @ContentHelp('Name the aggregates and the boundaries between them.')
  TextSection overview = TextSection();

  @SerializationOrder(1)
  @SectionIdPattern('INDM-ENT-xxx')
  @Min(1)
  List<EntityEntry> entities = [];
}

@Headline('Entity')
class EntityEntry extends DocSpecsSection {
  @SerializationOrder(0)
  TextSection description = TextSection();
}

void main() {
  final model = InformationModel()
    ..overview.content = 'Three aggregates: Customer, Order, Shipment.'
    ..entities.add(EntityEntry()..description.content = 'A placed order.');

  print(model.overview.content);
  print(model.entities.length);
  print(model.entities.first.description.content);
}
```

Output:

```
Three aggregates: Customer, Order, Shipment.
1
A placed order.
```

Nothing in that program observes the annotations — that is the point. They are
read by the tooling that turns this class into a schema, a metadata tree, nine
language facades and a rendered document.

## Core Components

### Annotations are plain const classes

Every annotation is constructible and its fields are readable, which is what
makes them testable and what lets tooling that already has an instance inspect
it:

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  const id = SectionId('INDM');
  const kind = CodeSpecKind([CodeSpecPart.form, CodeSpecPart.validation]);
  const field = Field('owner', String, 'Accountable team', required: true);

  print(id.id);
  print(kind.kinds.map((k) => k.name).join(', '));
  print('${field.name}: ${field.description} (required=${field.required})');
  print(identical(const SectionId('INDM'), id));
}
```

Output:

```
INDM
form, validation
owner: Accountable team (required=true)
true
```

The last line is worth noticing: because they are `const`, two identical
annotations are the same object, so annotations cost nothing to apply.

### The five families

| Family | Answers | Members |
|--------|---------|---------|
| Identity & structure | *Who is this section, and where does it sit?* | `@SectionId`, `@SectionIdPattern`, `@Document`, `@Prefix`, `@Position`, `@SerializationOrder` |
| Content & authoring | *What does it hold, and how does an author fill it?* | `@ContentType`, `@Form` / `Field`, `@ContentHelp`, `@Headline`, `@TextRequired`, `@Unused`, `@Comment` |
| Constraints | *What is a valid value?* | `@Min`, `@Max`, `@MinLength`, `@MaxLength`, `@MaxDepth`, `@AllowedTags`, `@PatternCheck`, `@PatternCheckId`, `@ValidationPrompt`, `@OneOf`, `@Case` |
| Cross-reference & traceability | *What else does it point at?* | `@Reference`, `@AccessKey`, `@ForEach`, `@MapsTo`, `@DetailedIn`, `@StandardReferences` |
| Artifact routing | *What does it produce?* | `@CodeSpecKind`, `@FollowUpKind`, `@NoArtifact`, `@CodeSpecsProjection` |

The rest of this guide is organised by the question, not by the family.

## Giving a section an identity

`@SectionId` is the globally-unique mnemonic for a section *type*. It goes on
the class. A list container field also carries one, in the
`<elemId>-<SUFFIX>-LST` shape, because the container is itself addressable.

A list's *elements* work the other way round: the element class carries no
`@SectionId`, and the containing field carries `@SectionIdPattern` instead —
the pattern from which each element's instance id is generated. Putting a
`@SectionId` on an element class would claim a single id for what is many
sections.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

@SectionId('CULA')
@Prefix('CULA')
class CurrentLandscape extends DocSpecsSection {
  @SerializationOrder(0)
  @SectionId('CULA-SYS-LST')
  @SectionIdPattern('CULA-SYS-xxx')
  List<LegacySystem> systems = [];
}

class LegacySystem extends DocSpecsSection {
  @SerializationOrder(0)
  TextSection purpose = TextSection();
}

void main() {
  final landscape = CurrentLandscape()
    ..systems.add(LegacySystem()..id = 'CULA-SYS-001')
    ..systems.add(LegacySystem()..id = 'CULA-SYS-002');

  print(landscape.systems.map((s) => s.id).join(' '));
}
```

Output:

```
CULA-SYS-001 CULA-SYS-002
```

`@Prefix` enables two-stage id resolution — a heading prefix shared by a
subtree, so ids beneath it need not repeat it in full. `@Position('first')` /
`@Position('last')` overrides declaration order for a member that must render at
one end regardless of where it is declared.

## Declaring what a section holds

The strongest declaration is the member's **type** — a `SqlCodeSection` needs no
annotation to say its body is SQL. `@ContentType` is for the case the type
cannot express: a `String? content` on a class that is not a section base type.

`@ContentHelp` is authoring guidance ("how do I fill this in?"). It is distinct
from `@StandardReferences`' `connotation`, which says what the section *means*.
Both can apply; they answer different questions and a reader needs both.

`@TextRequired` says the section's prose is the deliverable, so empty is
invalid. `@Unused` says the opposite — a container-only class whose `content` is
never expected and is ignored if present.

A `@Form` collapses a form class's scalar fields into one annotation on
`content`, one `Field` per form field:

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  const form = Form([
    Field('owner', String, 'Accountable team', required: true),
    Field('reviewCadence', String, 'How often this is revisited',
        hint: 'e.g. quarterly'),
    Field('targetCount', int, 'Planned number of instances'),
  ]);

  for (final f in form.fields) {
    print('${f.name} : ${f.type} '
        '${f.required ? "(required)" : "(optional)"}'
        '${f.hint == null ? "" : " — ${f.hint}"}');
  }
}
```

Output:

```
owner : String (required)
reviewCadence : String (optional) — e.g. quarterly
targetCount : int (optional)
```

`Field.type` is restricted to scalars — `String`, `int`, `double`, `bool` and
model enums. A field that wants structure is a subsection, not a form field.
`Field.refersTo` is the separate case where a field's *string value* is an id
pointing at another section; it never applies to the same declaration as a
structured type.

## Constraining a value

| Want | Annotation | Applies to |
|------|-----------|------------|
| At least / at most *n* list entries | `@Min(n)` / `@Max(n)` | A `List<T>` member |
| A content length floor / ceiling | `@MinLength(n)` / `@MaxLength(n)` | A content member |
| A nesting ceiling | `@MaxDepth(n)` | A class (`0` = leaf) |
| A value matching a regex | `@PatternCheck(p)` | A member |
| Children whose full section ids match a regex | `@PatternCheckId(p)` | A class |
| Only certain inline tags in prose | `@AllowedTags([...])` | A class |
| A judgement no regex can make | `@ValidationPrompt(p)` | A class or member |

The first six are mechanical: a generator turns each into a DocSpecs schema
constraint, and the instance-tier validator in each SOM runtime enforces it
against a filled document. `@ValidationPrompt` is the deliberate exception — it
carries a prompt for AI-assisted review, for the constraints that are real but
not decidable by pattern.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  const idCheck = PatternCheckId(
    r'^CULA-SYS-\d{3}$',
    errorMessage: 'Legacy system ids run CULA-SYS-001 upward.',
  );

  print(idCheck.pattern);
  print(idCheck.errorMessage);
  print(RegExp(idCheck.pattern).hasMatch('CULA-SYS-007'));
  print(RegExp(idCheck.pattern).hasMatch('CULA-SYS-7'));
}
```

Output:

```
^CULA-SYS-\d{3}$
Legacy system ids run CULA-SYS-001 upward.
true
false
```

Always give `errorMessage` a value. A failed pattern check without one reports
the regex, which tells an author what was rejected but not what was wanted.

## Discriminated subsection groups

`@OneOf` marks a container whose present subsections depend on a choice the
author made. The `discriminator` names one of the container's own `@Form` fields
whose type is a model enum; each `@Case`-annotated subsection member is bound to
one constant of that enum. A subsection with no `@Case` is *common* — present
whatever the choice.

The part worth understanding is `noCase`. It lists the discriminator constants
that deliberately bind no case at all — kinds whose entire surface is the common
subsections. Without it, "this kind has no extra attributes" and "someone forgot
this kind" look identical to the coverage check:

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  const group = OneOf(
    discriminator: 'storeKind',
    noCase: ['StoreKind.inMemory'],
    note: 'In-memory stores add nothing beyond the common subsections.',
  );

  print(group.discriminator);
  print(group.noCase);
  print(group.note);
}
```

Output:

```
storeKind
[StoreKind.inMemory]
In-memory stores add nothing beyond the common subsections.
```

A `noCase` entry that is not a constant of the discriminator enum, or that a
`@Case` *does* cover, is an error — caught statically by the validator and again
at instance level by each runtime's `validateDocument`.

## Tracing a section to its document

Three annotations record how the `D00SolutionBlueprint` master maps into the
twelve Phase 3 documents:

- **`@MapsTo(T)`** — the shallowest class whose *entire subtree* flows to one
  target document. The document's seed.
- **`@DetailedIn(T)`** — a class promoted to a top-level entry of the target.
  Requires a `@MapsTo` ancestor.
- **`@StandardReferences([...], connotation)`** — the public standard clauses
  the section derives from, plus one statement of what the section means.

The pairing matters: `@MapsTo` says *which* document, `@DetailedIn` says *at
what level it enters*. Applying `@DetailedIn` without a `@MapsTo` ancestor names
a destination nothing routes to, which the structural invariants reject.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  const refs = StandardReferences(
    ['ISO/IEC/IEEE 42010:2022 §5.4', 'TOGAF 10 ADM Phase C'],
    'The architecture views and the concerns each addresses.',
  );

  print(refs.standards.length);
  print(refs.standards.first);
  print(refs.connotation);
}
```

Output:

```
2
ISO/IEC/IEEE 42010:2022 §5.4
The architecture views and the concerns each addresses.
```

The invariants these three obey are
`tom_specs_model_rules.md` §10.2.

## Routing a section to an artifact

Every reachable section carries exactly one of three routing verdicts, and the
completeness of that is what makes "produces nothing" a recorded decision rather
than an omission:

| Verdict | Annotation | Cardinality | Means |
|---------|-----------|-------------|-------|
| Produces code | `@CodeSpecKind([...])` | List-valued | Realised as these CodeSpecs part types |
| Feeds a follow-up process | `@FollowUpKind([...])` | List-valued | Feeds these downstream processes |
| Produces nothing | `@NoArtifact(reason)` | **Single**-valued | Unrouted, for this one reason |

The first two are lists because a section can feed several parts or several
processes at once. `@NoArtifact` is single-valued because a section is unrouted
for *one* reason — `container`, `overview` or `view`.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

void main() {
  const code = CodeSpecKind([CodeSpecPart.dataAccess, CodeSpecPart.domainEnum]);
  const followUp = FollowUpKind([FollowUpProcess.doc, FollowUpProcess.trn]);
  const none = NoArtifact(NoArtifactReason.overview,
      note: 'Specified normatively by the entity sections below.');

  print(code.kinds.map((k) => k.name).toList());
  print(followUp.processes.map((p) => p.name).toList());
  print('${none.reason.name}: ${none.note}');
  print('CodeSpecPart values: ${CodeSpecPart.values.length}');
  print('FollowUpProcess values: ${FollowUpProcess.values.length}');
  print('NoArtifactReason values: ${NoArtifactReason.values.length}');
}
```

Output:

```
[dataAccess, domainEnum]
[doc, trn]
overview: Specified normatively by the entity sections below.
CodeSpecPart values: 28
FollowUpProcess values: 9
NoArtifactReason values: 3
```

The three enums are closed catalogues transcribed from
[`codespecs_mapping.md`](../../tom_specs_model/doc/codespecs_mapping.md) §4.1,
§4.3 and §8.3 — that document decides what the values mean and which parts are
active rather than deferred.

`@CodeSpecsProjection()` is a marker for one class: the `@Document` root that is
the CodeSpecs generation projection. It exempts that document from the
detail-count check *only*, and relaxes nothing else.

## Pinning serialization order

`@SerializationOrder(n)` is the member's 0-based source-declaration position
within its class. It exists so that nine language emitters serialize members in
the same order without each re-deriving it from source.

It is **stamped, not hand-written**. `tom_specs_clitool`'s
`stamp_serialization_order.dart` renumbers every member of every class from
source order, idempotently, and the SOM generator refuses to run past an
unstamped member. So the workflow is: insert the new member where it belongs in
the source, then re-stamp — never renumber by hand.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';

class TargetOrganization extends DocSpecsSection {
  @SerializationOrder(0)
  TextSection purpose = TextSection();

  @SerializationOrder(1)
  TextSection structure = TextSection();

  @SerializationOrder(2)
  TextSection roles = TextSection();
}

void main() {
  const stamps = [SerializationOrder(0), SerializationOrder(1),
      SerializationOrder(2)];
  print(stamps.map((s) => s.order).toList());
  print(TargetOrganization().purpose is TextSection);
}
```

Output:

```
[0, 1, 2]
true
```

## Error Handling

No annotation in this library throws, validates, or has a run-time effect. Every
diagnostic it can produce is raised by a *reader* of the annotation, at
generation time:

| Mistake | Caught by | Symptom |
|---------|-----------|---------|
| A new annotation class with no declared destination | `docspecs_annotation_mapping_test.dart` | Test failure naming the class |
| A declared schema key the generator never emits | The same test, from the other side | Test failure naming the key |
| `@DetailedIn` with no `@MapsTo` ancestor | `tom_specs_clitool`'s validator | A `tom_specs_model_rules.md` §10.2 structural-invariant violation |
| A section with none of the three routing verdicts | The same validator, invariant `ROUTE-TOTAL` | A violation naming the section |
| An unstamped `@SerializationOrder` | `generate_som.dart`, before emitting | A hard error; the generator refuses to run |
| A `@Case` bound to a constant the discriminator enum lacks | The validator, then `validateDocument` | A one-of violation |
| Content violating `@MinLength` / `@PatternCheck` / … | Each runtime's `validateDocument` | An instance-tier validation error |

The split is deliberate and worth keeping in mind while debugging: the
**static** tier checks that the *model's own annotations* are well-formed and
runs once, at generation; the **instance** tier checks a *filled document's
values* and runs in all nine languages.

## Best Practices

- **Let the type carry the format where it can.** Reach for `@ContentType` only
  when the member cannot be a typed section leaf.
- **Give every `@PatternCheck` and `@PatternCheckId` an `errorMessage`.** A bare
  regex tells an author what failed, not what was wanted.
- **Put `@SectionIdPattern` on the field, never `@SectionId` on the element
  class.** One id cannot name many sections.
- **Record the routing verdict deliberately.** `@NoArtifact` with a `note` is a
  decision; a missing verdict is an omission, and the two are only
  distinguishable because the first is written down.
- **Use `noCase` rather than leaving a discriminator constant uncovered.** It is
  how "this kind adds nothing" is said out loud.
- **Never renumber `@SerializationOrder` by hand.** Insert the member where it
  belongs and re-stamp.
- **Apply `@ContentHelp` and `@StandardReferences` together where both apply.**
  One says how to fill the section in, the other says what it means; neither
  substitutes for the other.

---

Back to the [documentation index](index.md).
