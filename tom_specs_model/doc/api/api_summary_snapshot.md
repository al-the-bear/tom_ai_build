# TomSpecs Model API Reference: Snapshot Module

The per-class contract that lets a reflection-free engine snapshot, clone and
serialize ~3000 model classes, and the copy-on-write snapshotter that drives it.

For task-oriented guidance see
[snapshot_and_serialization.md](../package/snapshot_and_serialization.md).

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [SpecNode](#specnode)
  - [SpecClassOps](#specclassops)
  - [SpecRegistry](#specregistry)
  - [SpecSlot](#specslot)
  - [SpecSnapshotter](#specsnapshotter)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **one mixin, two classes and two abstract-final utilities**,
plus three module-level resolver functions.

| Declaration | Role |
|-------------|------|
| `SpecNode` (mixin) | The contract, supplied by overriding — the hand-written path |
| `SpecClassOps` | The same contract as callbacks — the generated path |
| `SpecRegistry` | Maps a concrete `Type` to its `SpecClassOps` |
| `SpecSlot` | One child relationship: a get/set pair plus its serialization key |
| `SpecSnapshotter` | Copy-on-write snapshot and independent deep restore |

Dirty state is held in a private `Expando` keyed by node identity, never in an
instance field, so it cannot leak into the model's reflected field set. A node
with no recorded state counts as **dirty**: a freshly constructed node has never
been snapshotted.

## Class Hierarchy

```
Object
├── SpecClassOps          the callback form of the contract
├── SpecSlot              one child relationship
├── SpecRegistry          abstract final — Type -> SpecClassOps
└── SpecSnapshotter       abstract final — snapshot / restore

mixin SpecNode            the override form of the contract
  └── SpecProjection      (serialization module; adds connect)
```

## Classes

### SpecNode

A model node that participates in copy-on-write snapshotting by overriding the
contract directly. The generated path uses `SpecRegistry` instead.

Implementations must declare **every** child model object in `specSlots()`. A
mutable child left out is shared between the live tree and every snapshot, and a
later in-place edit corrupts them all.

**Kind:** `mixin`

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isDirtySinceSnapshot` | `bool` | Whether this node has been mutated since the last snapshot. A new node reports `true`. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `markDirty()` | `void` | Marks this node changed, so the next snapshot clones it instead of sharing its predecessor's copy. Call it with the edit, not with the snapshot. |
| `specSlots()` | `List<SpecSlot>` | The child-node relationships, in a **stable order**. Leaves inherit the empty default. A **method**, not a getter — a getter would surface as a synthetic field in the analyzer element model. |
| `cloneShallow()` | `SpecNode` | Same scalar values, the **same** child references. Must not deep-copy: the snapshotter rewrites children afterwards. Abstract — every implementation supplies it. |
| `yamlScalar()` | `String?` | This node's own scalar payload — its packed form or intro `content` — never its descendants'. Containers inherit the `null` default. A method, for the same reason as `specSlots`. |

### SpecClassOps

The per-class contract for a model class that does **not** mix in `SpecNode` —
supplied by the spec-ops codegen and registered in `SpecRegistry`. Mirrors the
mixin one-to-one, plus the optional projection binding.

Each callback receives the live node as an `Object`; the generated body casts it
to the concrete type and closes over its public fields. This is how ~3000
generated classes adopt the contract with **no edit to their source**: Dart has
no augmentation support, so the contract cannot be mixed in from generated code,
and the classes must stay pristine for the analyzer-based `ModelReader`.

**Extends:** `Object`

#### Constructors

```dart
const SpecClassOps({
  required List<SpecSlot> Function(Object node) slots,
  required Object Function(Object node) cloneShallow,
  String? Function(Object node)? yamlScalar,
  void Function(Object node, Object source)? connect,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `slots` | `List<SpecSlot> Function(Object)` | The registry equivalent of `specSlots`. |
| `cloneShallow` | `Object Function(Object)` | The registry equivalent of `cloneShallow`. |
| `yamlScalar` | `String? Function(Object)?` | The registry equivalent of `yamlScalar`. `null` for a container. |
| `connect` | `void Function(Object, Object)?` | Projection roots only — the registry equivalent of `SpecProjection.connect`. `null` for a non-projection. |

### SpecRegistry

Holds the generated `SpecClassOps` for every model class that adopts the
contract via codegen. Keyed by concrete `Type`.

**Kind:** `abstract final class` — a namespaced set of statics, never instantiated.

#### Static Properties

| Property | Type | Description |
|----------|------|-------------|
| `isEmpty` | `bool` | Whether nothing has been registered yet. `true` until a `DocSpecsProject` is constructed. |
| `length` | `int` | How many types are registered. |

#### Static Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `register(Type type, SpecClassOps ops)` | `void` | Registers the contract for `type`. Called by the generated `registerSpecOps()`. |
| `opsFor(Type type)` | `SpecClassOps?` | The registered contract, or `null` for a type the model does not contain. |

### SpecSlot

One child relationship: a get/set pair over a member, plus enough metadata to
serialize it. Children are typed as `Object` so list-element classes that adopt
the contract via the registry fit without change — the engine never needs them
to share a base type.

**Extends:** `Object`

#### Constructors

```dart
SpecSlot.node(
  Object? Function() get,
  void Function(Object?) set, {
  String? label,
  String? sectionId,
});

SpecSlot.list(
  List<Object> Function() get,
  void Function(List<Object>) set, {
  String? label,
  String? sectionId,
});
```

`SpecSlot.list`'s `set` closure receives a `List<Object>` and is responsible for
narrowing it back to the field's concrete element type.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isList` | `bool` | Which constructor made this slot. |
| `label` | `String?` | The model member's **Dart identifier** — not the serialization key. `null` for a slot walked structurally only. |
| `sectionId` | `String?` | The child's effective section id, or `null` when neither the member nor its target class carries one. |
| `key` | `String?` | The mapping key the child is written under: `'<sectionId> <label>'`, or the bare `label` when there is no id. `null` when the slot has no `label`, which means it is never serialized. |
| `node` | `Object?` | The single child. Readable and writable; `null`-valued on a list slot. |
| `list` | `List<Object>` | The child list. Readable and writable; empty on a node slot. |

### SpecSnapshotter

Produces structurally-shared snapshots of a node tree.

**Kind:** `abstract final class`

#### Static Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `snapshot(Object live, {Object? previous})` | `Object` | Captures `live`. Every subtree unchanged since `previous` is shared **by identity**; only changed nodes and their ancestors are cloned. Clears `live`'s dirty flags, so the next call is incremental. Pass `previous: null` for the first, full snapshot. |
| `restore(Object node)` | `Object` | An independent deep copy, for restoring a snapshot into a fresh editable tree. Shares nothing with `node`. |

Snapshots never alias nodes from the live tree, so the live tree may go on being
edited in place without corrupting any snapshot.

## Global Functions and Constants

Three module-level resolvers. Each takes a node as `Object`, uses the `SpecNode`
override when the node has one, and falls back to the registered
`SpecClassOps` otherwise — so mixin-based and registry-based nodes mix freely in
one tree.

| Function | Signature | Description |
|----------|-----------|-------------|
| `specSlotsOf` | `List<SpecSlot> specSlotsOf(Object node)` | The node's child relationships, or the empty list. |
| `cloneShallowOf` | `Object cloneShallowOf(Object node)` | A shallow copy. Throws `StateError` naming the type when the node has neither the mixin nor registered ops. |
| `yamlScalarOf` | `String? yamlScalarOf(Object node)` | The node's own scalar payload, or `null`. |

The module declares no public constants.
