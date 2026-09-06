# TomSpecs Model — Snapshotting and Serialization

Three thousand flat data classes, no shared base, no reflection available, and
an editor that needs a cheap undo stack and a byte-stable save. This guide
covers how that is solved: the per-class contract, the two ways of supplying it,
the copy-on-write snapshotter, and the projection onto the wire format. The
`*.docspecs.yaml` format itself is `SOM §12` and is cited, not restated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [The per-class contract](#the-per-class-contract)
  - [SpecSlot — one child relationship](#specslot--one-child-relationship)
  - [The two ways to supply the contract](#the-two-ways-to-supply-the-contract)
- [Copy-on-write snapshotting](#copy-on-write-snapshotting)
- [Serialization](#serialization)
- [The generated registry](#the-generated-registry)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

The editor keeps an undo stack of document snapshots, and a snapshot must be a
**cheap full picture**: each new snapshot shares every unchanged subtree with
its predecessor *by identity*, and only the path from an edited leaf to the root
is cloned. Restoring is then trivial — a snapshot is just another independent
tree.

Doing that generically over typed fields needs either reflection or per-class
support. The editor runs on Flutter, where `dart:mirrors` is unavailable, so it
is per-class support: a tiny three-method contract that the engine drives every
node through.

The contract is deliberately *not* mixed into the model classes. Dart has no
augmentation support, so generated code cannot add a mixin to a hand-written
class — and more importantly the model classes must stay pristine, adding no
instance field and no getter, so that the analyzer-based `ModelReader` sees them
unchanged. The contract is registered against them by type instead.

## Quick Start

```dart
import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/tom_specs_model.dart';

/// A leaf that supplies the contract by mixing in [SpecNode].
class Leaf extends DocSpecsSection with SpecNode {
  @override
  String? yamlScalar() => content;

  @override
  Leaf cloneShallow() => Leaf()..content = content;
}

/// A container with one child slot.
class Root extends DocSpecsSection with SpecNode {
  Leaf? child = Leaf();

  @override
  List<SpecSlot> specSlots() => [
        SpecSlot.node(() => child, (v) => child = v as Leaf?, label: 'child'),
      ];

  @override
  Root cloneShallow() => Root()..child = child;
}

void main() {
  final live = Root()..child!.content = 'first';

  final first = SpecSnapshotter.snapshot(live) as Root;
  live.child!.content = 'second';
  live.child!.markDirty();
  final second = SpecSnapshotter.snapshot(live, previous: first) as Root;

  print(first.child!.content);
  print(second.child!.content);
  print(live.child!.content);
  print(identical(first.child, live.child));
}
```

Output:

```
first
second
second
false
```

The snapshot kept `first`'s value while the live tree moved on — the whole point
of copy-on-write.

## Core Components

### The per-class contract

Three methods, one optional fourth for projections:

| Method | Returns | Contract |
|--------|---------|----------|
| `specSlots()` | `List<SpecSlot>` | **Every** child model object, in a stable order |
| `cloneShallow()` | the same type | Same scalars, the **same** child references — never a deep copy |
| `yamlScalar()` | `String?` | This node's own scalar payload, never its descendants' |
| `connect(source)` | `void` | Projection roots only: re-point references onto the live master |

The two must-nots are worth stating plainly. **`specSlots()` must declare every
mutable child** — one left out is shared between the live tree and every
snapshot, and a later in-place edit corrupts them all. And **`cloneShallow()`
must not deep-copy** — the snapshotter rewrites the children itself afterwards,
so a deep copy there does the work twice and destroys structural sharing.

`specSlots()` and `yamlScalar()` are declared as **methods, not getters**, on
purpose: a getter would surface as a synthetic field in the analyzer element
model and pollute the reflected model.

### `SpecSlot` — one child relationship

A slot is a get/set pair over one member, plus enough metadata to serialize it.

| Constructor | For |
|-------------|-----|
| `SpecSlot.node(get, set, {label, sectionId})` | A single, possibly null child |
| `SpecSlot.list(get, set, {label, sectionId})` | A `List<T>` of children |

| Property | Meaning |
|----------|---------|
| `isList` | Which constructor made it |
| `label` | The **Dart identifier** of the member — not the serialization key |
| `sectionId` | The child's effective section id, or `null` |
| `key` | The serialization key: `'<sectionId> <label>'`, or the bare `label` when there is no id |
| `node` / `list` | The live value, readable and writable |

A slot with no `label` at all is walked **structurally only** and is never
serialized. That is a real case: a value holder beneath a section is not a
section, so it has nothing language-neutral to be named by, and inventing a name
would put a key in the file no schema and no other runtime knows.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/tom_specs_model.dart';

class Leaf extends DocSpecsSection with SpecNode {
  @override
  Leaf cloneShallow() => Leaf()..content = content;
}

void main() {
  Leaf? a = Leaf();
  List<Object> items = [];

  final keyed = SpecSlot.node(() => a, (v) => a = v as Leaf?,
      label: 'overview', sectionId: 'SEC');
  final unkeyed = SpecSlot.node(() => a, (v) => a = v as Leaf?,
      label: 'holder');
  final structural = SpecSlot.node(() => a, (v) => a = v as Leaf?);
  final list = SpecSlot.list(() => items, (v) => items = v,
      label: 'entries', sectionId: 'ENT-LST');

  print(keyed.key);
  print(unkeyed.key);
  print(structural.key);
  print('${list.key} isList=${list.isList}');
}
```

Output:

```
SEC overview
holder
null
ENT-LST entries isList=true
```

### The two ways to supply the contract

| Way | Used by | How |
|-----|---------|-----|
| Mix in `SpecNode` | Hand-written leaves (`DocumentHeader`) and tests | Override the methods directly |
| Register a `SpecClassOps` | The ~3000 generated model classes | `SpecRegistry.register(Type, ops)` |

`SpecClassOps` mirrors the mixin one-to-one — `slots` ↔ `specSlots`,
`cloneShallow` ↔ `cloneShallow`, `yamlScalar` ↔ `yamlScalar`, plus the optional
`connect`. Each callback takes the node as an `Object`; the generated body casts
and closes over the class's public fields.

The engine resolves which path a node uses per node, so the two mix freely in
one tree.

**Dirty state lives off the node**, in a private `Expando` keyed by identity,
precisely so it cannot leak into the model's reflected field set. A node with no
recorded state counts as **dirty** — a freshly constructed node has never been
snapshotted, so the first snapshot must capture it.

## Copy-on-write snapshotting

| Call | Does |
|------|------|
| `SpecSnapshotter.snapshot(live)` | A full, independent first snapshot |
| `SpecSnapshotter.snapshot(live, previous: p)` | Shares every unchanged subtree with `p` by identity; clones only what changed |
| `SpecSnapshotter.restore(node)` | An independent deep copy, for restoring into a fresh live tree |

After a snapshot walk, the live tree's dirty flags are cleared, so the next call
is incremental. Snapshots never alias nodes from the live tree, so the live tree
can go on being edited in place.

```dart
import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/tom_specs_model.dart';

class Leaf extends DocSpecsSection with SpecNode {
  @override
  Leaf cloneShallow() => Leaf()..content = content;
}

class Root extends DocSpecsSection with SpecNode {
  Leaf? left = Leaf();
  Leaf? right = Leaf();

  @override
  List<SpecSlot> specSlots() => [
        SpecSlot.node(() => left, (v) => left = v as Leaf?, label: 'left'),
        SpecSlot.node(() => right, (v) => right = v as Leaf?, label: 'right'),
      ];

  @override
  Root cloneShallow() => Root()..left = left..right = right;
}

void main() {
  final live = Root()
    ..left!.content = 'L0'
    ..right!.content = 'R0';

  final s1 = SpecSnapshotter.snapshot(live) as Root;

  // Edit only the left subtree.
  live.left!.content = 'L1';
  live.left!.markDirty();
  live.markDirty();

  final s2 = SpecSnapshotter.snapshot(live, previous: s1) as Root;

  print('${s1.left!.content} ${s1.right!.content}');
  print('${s2.left!.content} ${s2.right!.content}');
  // The untouched right subtree is SHARED between the two snapshots…
  print(identical(s1.right, s2.right));
  // …while the edited left subtree was cloned.
  print(identical(s1.left, s2.left));
}
```

Output:

```
L0 R0
L1 R0
true
false
```

That is structural sharing made visible: one edit, one clone, everything else
shared by identity.

`markDirty()` is what makes it incremental. The editor's document controller
calls it after applying any field edit; a node whose dirty flag is never set can
be shared with the previous snapshot even though its value changed, which is why
the call belongs with the edit rather than with the snapshot.

## Serialization

`SpecYaml` projects a live object tree onto a sparse `SpecDocument` keyed by the
metadata tree's paths, then hands it to the runtime encoder.

| Call | Does |
|------|------|
| `SpecYaml.toYaml(root, tree:, modelVersion:)` | The global save — project, then encode |
| `SpecYaml.toYamlForProjection(projection, master, tree:, modelVersion:)` | Connect the projection onto the master, then save it |
| `SpecYaml.toDocument(root, tree:)` | Just the projection half, so a caller can inspect, diff or edit the document before encoding |

`toDocument` being separate is the useful part: a save is a *projection* and an
*encoding*, and having the intermediate `SpecDocument` in hand is what makes a
save inspectable in a test.

`connectProjection(projection, source)` resolves the connect binding — mixin
override or registered ops — and runs it, returning `false` when the projection
has none.

## The generated registry

`registerSpecOps()`, in `lib/src/generated/spec_ops.g.dart`, registers a
`SpecClassOps` for every model class and section leaf. It is **not exported from
the barrel**, and does not need to be: it is idempotent, and
`DocSpecsProject`'s constructor calls it, so constructing the container is the
public way to arm the registry.

Two properties are worth knowing:

- **Each slot carries its section id**, so the emitted key agrees with the nine
  language runtimes rather than with the Dart field name.
- **The thirteen projection roots carry a `connect` binding** — derived from the
  model's own structure, not from the traceability annotations — so a projection
  re-points onto the live Solution Blueprint instead of serializing
  default-constructed sections.

```dart
import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  // Nothing is registered until a container is constructed.
  print(SpecRegistry.isEmpty);

  DocSpecsProject();
  print(SpecRegistry.isEmpty);
  print(SpecRegistry.opsFor(D00SolutionBlueprint) != null);

  // A type the model does not contain has no ops.
  print(SpecRegistry.opsFor(String));

  // Idempotent: constructing a second container changes nothing.
  final n = SpecRegistry.length;
  DocSpecsProject();
  print(SpecRegistry.length == n);
}
```

Output:

```
true
false
true
null
true
```

## Error Handling

| Situation | Result |
|-----------|--------|
| Snapshotting a node with no `SpecNode` mixin and no registered ops | `StateError` naming the type — the engine cannot clone what it cannot describe |
| A mutable child omitted from `specSlots()` | **No error** — the child is silently shared between live tree and snapshots, and a later edit corrupts them |
| A `cloneShallow()` that deep-copies | **No error** — structural sharing is silently lost |
| An object whose members the metadata tree does not describe (or vice versa) | `SpecYamlFormatException`, naming the path |
| A slot key that disagrees with the runtime's `nodeKey` | `SpecYamlFormatException` |
| Form field values on a section the tree does not declare as a form | `SpecYamlFormatException` |
| `connectProjection` on a projection with no binding | Returns `false`; nothing is re-pointed |

The two silent rows are the dangerous ones, and both are contract violations
rather than API misuse — which is why the contract is stated as two must-nots
above. A corrupted snapshot shows up much later, as an undo that restores the
wrong value.

`SpecYamlFormatException` is loud on purpose: failing at save time beats writing
a file that silently lost data.

## Best Practices

- **Declare every mutable child in `specSlots()`.** A missed one is a silent
  corruption, not an error.
- **Keep `cloneShallow()` shallow.** The snapshotter rewrites children itself.
- **Call `markDirty()` with the edit, not with the snapshot.** It is what makes
  the next snapshot incremental and correct.
- **Use methods, not getters,** for `specSlots` and `yamlScalar` — a getter
  pollutes the reflected model.
- **Reach for `toDocument` in tests.** Asserting on the projected `SpecDocument`
  is more legible than asserting on encoded text.
- **Never hand-edit `spec_ops.g.dart`.** Change the model and regenerate; the
  freshness stamp will catch a skipped regeneration.

---

Back to the [package documentation index](index.md).
