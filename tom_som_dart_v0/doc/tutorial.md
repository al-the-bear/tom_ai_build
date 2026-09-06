# Dart tutorial — `tom_som_dart_v0`

Using the TomSpecs Specification Object Model from Dart, end to end:
install the package, open a document, read a section, edit it, validate it and
serialize it. One program, run start to finish.

The object model itself, the two wire formats and the validator contract are the
**subject matter** and are owned by
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md);
this guide cites it and never restates it. The generic, reflective half of the
same plane is
[`tom_som_dart_runtime/doc/generic_access.md`](../../tom_som_dart_runtime/doc/generic_access.md).

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
- [The whole tutorial](#the-whole-tutorial)
- [Reading it step by step](#reading-it-step-by-step)
- [Building and testing](#building-and-testing)
- [The API reference](#the-api-reference)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

`tom_som_dart_v0` is the **typed** access path: one generated type per document
section, so a specification is read and written through named members rather
than string paths. It is a view over a document that the hand-written
`tom_som_dart_runtime` actually holds — the runtime carries the sparse,
path-keyed store, the codecs and the validator; the facade carries only what
changes when the model changes.

Dart is the reference plane: the model, the generator and the conformance goldens are authored here, and the other eight ports are transcribed from it.

Five steps make up every non-trivial use, and the tutorial below is exactly those
five in order:

| Step | What it does |
|------|--------------|
| 1 | Open a document and wrap it in a typed root |
| 2 | Edit through named members |
| 3 | Read a value back |
| 4 | Validate the document against the model |
| 5 | Serialize to `*.docspecs.yaml`, and decode it again |

## Quick Start

```bash
dart pub add tom_som_dart_v0
```

Both halves are versioned to the TomSpecs **model version** and must move
together — `tom_som_dart_v0` and `tom_som_dart_runtime` always carry the
same version. Every other dependency route is in
[`readme_howtointegrate.md`](../readme_howtointegrate.md).

## Core Components

| Thing | Where it lives | Role |
|-------|----------------|------|
| `D00SolutionBlueprint` … | this package | The fourteen generated document roots — the typed entry points |
| `SpecDocument` | the runtime | The sparse, path-keyed store the facade is a view over |
| the metadata tree | this package | The model's shape as data; the codecs walk it |
| `validateDocument` | the runtime | The instance tier — a filled document's values checked against the model |
| the YAML codec | the runtime | `*.docspecs.yaml`, byte-stable in all nine languages |

The document roots are listed in the
[README](../README.md#document-roots); `D00SolutionBlueprint` is the master and
the other thirteen are projections over the same sections.

## The whole tutorial

Run this from the package root — it needs `meta/spec_model.meta.json`, which
ships with the package:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

void main() {
  // 1 — open a document and wrap it in a typed root.
  final doc = SpecDocument();
  final blueprint = D00SolutionBlueprint(doc);

  // 2 — edit through named members, not string paths.
  blueprint.content = 'A platform that unifies our fragmented order systems.';
  blueprint.currentLandscape.content =
      'Three legacy systems with no shared customer record.';

  // 3 — read it back.
  print(blueprint.content);

  // 4 — validate against the model.
  final model = SpecModel.fromJson(
      jsonDecode(File('meta/spec_model.meta.json').readAsStringSync())
          as Map<String, dynamic>);
  print(validateDocument(model, doc).isEmpty);

  // 5 — serialize, then read the value back out of the decoded document.
  final yaml = SpecDocumentYaml.encode(
      document: doc, tree: d00SolutionBlueprintMetaTree, modelVersion: '1.0');
  final decoded = SpecDocumentYaml.decode(yaml, d00SolutionBlueprintMetaTree);
  print(decoded.document.content('SBP/content'));
  print(decoded.modelVersion);
}
```

Output:

```
A platform that unifies our fragmented order systems.
true
A platform that unifies our fragmented order systems.
1.0
```

Run it with:

```bash
dart run tutorial.dart
```

## Reading it step by step

**Step 1 — open and wrap.** The document is the value; the typed root is a view
onto it. Constructing a root also runs the model-version check, so a document
stamped by a different model version is refused rather than silently misread.

**Step 2 — edit through members.** This is the whole point of the typed path: a
mistyped section is a compile-time or attribute error here, where on the generic
path it would be a string that resolves to nothing.

**Step 3 — read back.** The value comes from the same store the edit went into;
the facade holds no state of its own.

**Step 4 — validate.** `validateDocument` is the *instance* tier — it checks a
filled document's values against the model. It is distinct from the static tier,
which checks that the model's own annotations are well-formed and runs once at
generation time.

**Step 5 — serialize and decode.** The encoding walks the metadata tree, so
sibling order is the model's declared order and emission is sparse — only
populated subtrees appear. Decoding returns the document plus the file's
`modelVersion` stamp, which is what a reader checks before trusting the content.

## Building and testing

```bash
./run_tests.sh
```

Every SOM package carries that same script, whatever the ecosystem underneath,
and [`tom_som_conformance`](../../tom_som_conformance) aggregates all eighteen.
The per-language toolchain — what to install and how — is
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md).

## The API reference

The full generated reference lives in `doc/api/reference/` and is **not
committed** — it is output, and it regenerates:

```bash
cd ../tom_specs_clitool
./tool/regenerate_api_references.sh dart_v0
```

That renders it with `dart doc`. The reasoning behind not committing it, and
the per-language generator notes, are in
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md),
"Documentation generation".

## Error Handling

Everything that can fail throws. `SpecYamlFormatException` names the path it failed at; `validateDocument` **returns** a list instead, because a document with problems is a normal state for an editor to be in, not an exception.

Three failures are worth recognising by sight:

| Symptom | Cause |
|---------|-------|
| The version check refuses a document | Its stamp names a model version this facade was not generated from |
| The encoder reports a value it cannot place | The object tree holds something the metadata tree does not describe — nothing is silently dropped |
| The decoder rejects a file | A `version:` it does not support, a key the tree cannot place, or a malformed value shape |

The encoder's loudness is deliberate: the alternative to failing there is a file
that silently lost data.

## Best Practices

- **Pin both halves together.** The facade and the runtime carry the same
  version because they are generated from one model; mixing them is the one
  configuration that fails in confusing ways.
- **Prefer the typed path.** Reach for the generic store only when the path is
  computed rather than known — see
  [`generic_access.md`](../../tom_som_dart_runtime/doc/generic_access.md).
- **Check the decoded `modelVersion` before trusting content.** It is the stamp
  that says which model wrote the file.
- **Treat a validation result as data, not an error.** A specification under
  construction is normally invalid; that is what drafts are.
- **Never hand-edit a file carrying the `GENERATED … do not edit by hand`
  banner.** Change the model and regenerate.
- **Regenerate the API reference rather than looking for it in the repo.** It is
  deliberately not committed.

---

Back to the [documentation index](index.md).
