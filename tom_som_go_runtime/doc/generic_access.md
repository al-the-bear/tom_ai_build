# Generic access — `tom_som_go_runtime`

The reflective, untyped half of the Go SOM plane: the document as a
sparse path-keyed store, the model as data, and the question of when to prefer
this over the generated typed facade.

The object model, the two wire formats and the validator contract are the
**subject matter** and are owned by
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md);
this guide cites it and never restates it. The typed half is
[`tom_som_go_v0/doc/tutorial.md`](../../tom_som_go_v0/doc/tutorial.md).

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
- [Driving a document by path](#driving-a-document-by-path)
- [The model as data](#the-model-as-data)
- [When to prefer the generic path](#when-to-prefer-the-generic-path)
- [Building and testing](#building-and-testing)
- [The API reference](#the-api-reference)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

A TomSpecs document is **sparse and path-keyed**: a value lives under the
globally-unique section-id path it belongs to, and an absent key means "no
value" rather than an empty one. This package is that store, plus everything
that is the same in every language — the codecs, the validator, the reflection
surface and the editing tiers.

It holds **no document values of its own** and contains **no generated typed
classes**. Those belong to `tom_som_go_v0`, which is a view over exactly the
store this package provides. Both halves address the same document; the
difference is only whether a member is named at compile time or resolved from a
string at run time.

Go versions live in VCS tags rather than a manifest, so each module also carries an in-source `Version` constant, and the generator writes a `require` plus a local `replace` so the module builds both standalone and in-repo.

## Quick Start

```bash
go get github.com/al-the-bear/tom_ai_build/tom_som_go_runtime@v1.1.0
```

Most consumers depend on the typed facade, which pulls this in. Depend on it
directly when you drive documents by path — tooling, migration, bulk edits, or
anything that computes the path rather than knowing it.

## Core Components

| Type | Role |
|------|------|
| `SpecDocument` | The sparse, path-keyed store of content, form and list values |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations |
| `SpecReflection` | Resolves and enumerates paths against the model **without reading values** |
| `SpecValidator` / `validateDocument` | The instance tier: a filled document's values checked against the model |
| the YAML and Markdown codecs | `*.docspecs.yaml` and DocSpecs markdown, byte-stable across all nine languages |
| the editing-facade bases | What the generated `tom_som_go_v0` types extend |

The full catalogue is the [README](../README.md); this guide is about using
them.

## Driving a document by path

A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.

```go
import (
	"fmt"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
	somv0 "github.com/al-the-bear/tom_ai_build/tom_som_go_v0"
)

doc := som.NewSpecDocument()
doc.SetContent("SBP/content",
	"A platform that unifies our fragmented order systems.")

// A repeated section: append an item, then fill a content leaf under it.
item := doc.AddListItem("SBP/currentLandscape/CUOPME-OPER-LST")
doc.SetContent(item+"/content", "Average order turnaround: 4.2 days.")

// The whole document serializes to the canonical wire format.
yaml, err := som.EncodeYaml(doc, somv0.D00SolutionBlueprintMetaTree, "1.0")
if err != nil {
	panic(err)
}
fmt.Print(yaml)
```

The path grammar is the model's: a root segment, then a member per level, with
list items addressed by the path the store hands back when you append. Nothing
here needs a generated class, which is why this half of the plane is what
tooling reaches for.

## The model as data

The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).

```go
data, err := os.ReadFile("meta/spec_model.meta.json")
if err != nil {
	panic(err)
}
model, err := som.SpecModelFromJSON(data)
if err != nil {
	panic(err)
}
reflection := som.NewSpecReflection(model)

for _, root := range reflection.Roots() {
	fmt.Println(reflection.RootSegment(root), root.Title)
}

res := reflection.Resolve("SBP/currentLandscape/content")
fmt.Printf("kind=%s  valueLeaf=%v\n", res.Kind, res.IsValueLeaf())
```

This is the surface that makes generic editing safe rather than blind: before
writing to a path you can ask whether the model has one, what kind of node it
is, and whether it is a value leaf.

## When to prefer the generic path

| Prefer the **typed facade** when | Prefer the **generic store** when |
|----------------------------------|-----------------------------------|
| The section is known at authoring time | The path is computed, or comes from data |
| You want the compiler to catch a typo | You are walking every section of a document |
| You are writing application code | You are writing tooling, a migration or a bulk edit |
| The document root is fixed | The root varies, or several are handled uniformly |

The two are not alternatives at run time — the facade *is* a view over this
store, so a program can use both on one document and see one set of values. The
choice is per call site, not per program.

## Building and testing

```bash
./run_tests.sh
```

Every SOM package carries that same script, whatever the ecosystem underneath,
and [`tom_som_conformance`](../../tom_som_conformance) aggregates all eighteen —
which is also what proves this port reads a document identically to the other
eight. The per-language toolchain is
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md).

## The API reference

The full generated reference lives in `doc/api/reference/` and is **not
committed** — it is output, and it regenerates:

```bash
cd ../tom_specs_clitool
./tool/regenerate_api_references.sh go_runtime
```

That renders it with `go doc`. The reasoning behind not committing it, and
the per-language generator notes, are in
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md),
"Documentation generation".

## Error Handling

Errors are values, never panics: every fallible call returns `(T, error)`. The generic store returns **comma-ok** (`value, ok := doc.Content(path)`) where the typed facade returns a plain string — the distinction is "is it set?" versus "give me the value".

The generic path has one failure mode the typed path does not:

| Symptom | Cause |
|---------|-------|
| A read returns nothing | The path is absent from the document — **or** it names a section the model does not have. The store cannot tell you which |
| The encoder reports a value it cannot place | The document holds a path the metadata tree does not describe |
| Validation reports an error the typed path would not have allowed | The generic store accepts any path; validation is where that is caught |

That first row is the price of the generic path, and the reason to resolve a
path against `SpecReflection` before writing to it: a typo and a genuinely empty
section are indistinguishable afterwards.

## Best Practices

- **Resolve before you write.** `SpecReflection` turns "did I spell it right?"
  into a question with an answer.
- **Treat an absent value and an absent path as different questions.** The store
  answers the first; only the model answers the second.
- **Pin the runtime and the facade together.** They carry the same version
  because they are generated from one model.
- **Use the generic path for tooling, the typed path for application code.** The
  choice is per call site.
- **Validate after a bulk edit.** The generic store accepts paths the model does
  not have; validation is the check that catches it.
- **Regenerate the API reference rather than looking for it in the repo.** It is
  deliberately not committed.

---

Back to the [documentation index](index.md).
