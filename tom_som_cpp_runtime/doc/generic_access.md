# Generic access — `tom_som_cpp_runtime`

The reflective, untyped half of the C++ SOM plane: the document as a
sparse path-keyed store, the model as data, and the question of when to prefer
this over the generated typed facade.

The object model, the two wire formats and the validator contract are the
**subject matter** and are owned by
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md);
this guide cites it and never restates it. The typed half is
[`tom_som_cpp_v0/doc/tutorial.md`](../../tom_som_cpp_v0/doc/tutorial.md).

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
classes**. Those belong to `tom_som_cpp_v0`, which is a view over exactly the
store this package provides. Both halves address the same document; the
difference is only whether a member is named at compile time or resolved from a
string at run time.

Idiomatic C++17 with RAII throughout — the document is a value that must outlive every facade bound to it, and getters return `std::string` by value, so there is nothing to free.

## Quick Start

```bash
make install (then compile against pkg-config `tom_som_cpp_runtime`)
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
| the editing-facade bases | What the generated `tom_som_cpp_v0` types extend |

The full catalogue is the [README](../README.md); this guide is about using
them.

## Driving a document by path

A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.

```cpp
#include "tom_som_cpp_runtime.hpp"
#include "tom_som_cpp_v0_meta.hpp"

som::SpecDocument doc;
doc.setContent("SBP/content",
               "A platform that unifies our fragmented order systems.");

// A repeated section: append an item, then fill a content leaf under it.
const std::string item =
    doc.addListItem("SBP/currentLandscape/CUOPME-OPER-LST");
doc.setContent(som::joinPath(item, "content"),
               "Average order turnaround: 4.2 days.");

// The whole document serializes to the canonical wire format.
std::string err;
std::optional<std::string> yaml = som::encodeYaml(
    doc, tom_som_v0_meta::d00SolutionBlueprintMetaTree(), "1.0", &err);
std::cout << *yaml;
```

The path grammar is the model's: a root segment, then a member per level, with
list items addressed by the path the store hands back when you append. Nothing
here needs a generated class, which is why this half of the plane is what
tooling reaches for.

## The model as data

The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).

```cpp
#include "tom_som_cpp_runtime.hpp"

std::string err;
std::unique_ptr<som::SpecModel> model = som::SpecModel::fromJsonStr(data, &err);
som::SpecReflection ref(*model);

// The roots are model data; the reflection resolves paths against them.
for (const som::SpecRoot& root : model->roots) {
  std::cout << som::SpecReflection::rootSegment(root) << "  " << root.title
            << "\n";
}

std::optional<som::SpecResolution> res =
    ref.resolve("SBP/currentLandscape/content");
std::cout << "kind=" << res->kind << "  valueLeaf=" << res->isValueLeaf()
          << "\n";
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
./tool/regenerate_api_references.sh cpp_runtime
```

That renders it with `doxygen`. The reasoning behind not committing it, and
the per-language generator notes, are in
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md),
"Documentation generation".

## Error Handling

A fallible call returns `std::optional` and writes to a `std::string* err`; only the version check throws. `content()` on the generic store returns `const std::string*`, which is how "unset" is distinguished from "empty".

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
