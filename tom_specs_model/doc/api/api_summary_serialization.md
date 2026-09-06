# TomSpecs Model API Reference: Serialization Module

The projection from a live model tree onto the sparse document the nine SOM
runtimes read, and the connect-before-write pass that makes a per-root save
reflect current content.

For task-oriented guidance see
[snapshot_and_serialization.md](../package/snapshot_and_serialization.md#serialization).
The `*.docspecs.yaml` format itself is `SOM §12`.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [SpecProjection](#specprojection)
  - [SpecYaml](#specyaml)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

A save is two steps, and the module keeps them separable:

1. **Project** the live object tree onto a sparse `SpecDocument`, keyed by the
   metadata tree's paths (`SpecYaml.toDocument`).
2. **Encode** that document to the hierarchical-v2 wire format — the runtime's
   `SpecDocumentYaml`, not this module.

Having the intermediate `SpecDocument` in hand is what makes a save inspectable:
a test can assert on the projected document rather than on encoded text.

| Declaration | Role |
|-------------|------|
| `SpecProjection` (mixin) | Adds `connect` to a hand-written projection root |
| `SpecYaml` | The three save entry points |
| `connectProjection` | Resolves and runs a connect binding, mixin or registered |

## Class Hierarchy

```
mixin SpecNode                    (snapshot module)
  └── mixin SpecProjection on SpecNode
                                  adds connect(Object source)

Object
└── SpecYaml                      abstract final — the save entry points
```

`SpecProjection` is constrained `on SpecNode`: a projection is a node first, and
`connect` is the one thing it adds.

## Classes

### SpecProjection

Mixed into a **hand-written** projection root. Generated projection roots supply
the same binding through `SpecClassOps.connect` instead.

**Kind:** `mixin`, constrained `on SpecNode`

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `connect(Object source)` | `void` | Binds this projection's references onto the live sections of `source` (the Solution Blueprint root), **in place**. Abstract. After it runs, serializing the projection reflects current master content, and any section absent from the master is left null. |

### SpecYaml

Projects live node trees onto a `SpecDocument` for the shared hierarchical-v2
encoder, and orchestrates the connect-before-write pass for projection roots.

**Kind:** `abstract final class` — a namespaced set of statics.

#### Static Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toYaml(Object solutionBlueprintRoot, {required SomMetaTree tree, String? modelVersion})` | `String` | The global `document:` save: the master alone. Because the projections are views over the same sections, the master's tree contains every section exactly once, so the output never duplicates a subtree. `tree` must be the metadata tree of that root. |
| `toYamlForProjection(Object projection, Object solutionBlueprintRoot, {required SomMetaTree tree, String? modelVersion})` | `String` | Connects `projection` onto the live master, then serializes it — the per-root write. `tree` must be the metadata tree of the **projection** root, not of the master. |
| `toDocument(Object root, {required SomMetaTree tree})` | `SpecDocument` | The projection half alone, so callers and tests can inspect, diff or edit the document before it is encoded. |

`toDocument` throws `SpecYamlFormatException` when the object tree holds a value
the format has no home for:

- an object whose members the metadata tree does not describe, or vice versa;
- a key that disagrees with the runtime's `SpecDocumentYaml.nodeKey`;
- form field values on a section the metadata tree does not declare as a form.

Failing loudly there is the point: the alternative is a file that silently lost
data. Free text on a form section is **not** such a value — it is the form's
preamble, and it binds to the node's `content` key like any other section's
body.

## Global Functions and Constants

| Function | Signature | Description |
|----------|-----------|-------------|
| `connectProjection` | `bool connectProjection(Object projection, Object source)` | Resolves `projection`'s connect binding — the `SpecProjection` override when it has one, otherwise the registered `SpecClassOps.connect` — and runs it against `source`. Returns `false` when the projection has no binding, in which case nothing is re-pointed. |

The module declares no public constants.
