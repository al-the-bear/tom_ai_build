# C tutorial — `tom_som_c_v0`

Using the TomSpecs Specification Object Model from C, end to end:
install the package, open a document, read a section, edit it, validate it and
serialize it. One program, run start to finish.

The object model itself, the two wire formats and the validator contract are the
**subject matter** and are owned by
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md);
this guide cites it and never restates it. The generic, reflective half of the
same plane is
[`tom_som_c_runtime/doc/generic_access.md`](../../tom_som_c_runtime/doc/generic_access.md).

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

`tom_som_c_v0` is the **typed** access path: one generated type per document
section, so a specification is read and written through named members rather
than string paths. It is a view over a document that the hand-written
`tom_som_c_runtime` actually holds — the runtime carries the sparse,
path-keyed store, the codecs and the validator; the facade carries only what
changes when the model changes.

There is no registry: both halves build to a static and a shared library with a pkg-config `.pc` file, so `make install` and `pkg-config --cflags --libs` are the integration surface.

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
make install (then compile against pkg-config `tom_som_c_v0`)
```

Both halves are versioned to the TomSpecs **model version** and must move
together — `tom_som_c_v0` and `tom_som_c_runtime` always carry the
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

```c
#include "tom_som_c_runtime.h"
#include "tom_som_c_v0.h"
#include "tom_som_c_v0_meta.h"

#include <stdio.h>
#include <stdlib.h>

static char *slurp(const char *path) {
  FILE *f = fopen(path, "rb");
  fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
  char *b = malloc((size_t)n + 1); fread(b, 1, (size_t)n, f); b[n] = 0;
  fclose(f); return b;
}

int main(void) {
  /* 1 - open a document and wrap it in a typed root. */
  SpecDocument doc;
  spec_document_init(&doc);

  D00SolutionBlueprint bp;
  d00_solution_blueprint_new(&bp, &doc, "", NULL);

  /* 2 - edit through named accessors, not string paths. */
  d00_solution_blueprint_set_content(
      &bp, "A platform that unifies our fragmented order systems.");
  CurrentLandscape cl = d00_solution_blueprint_current_landscape(&bp);
  current_landscape_set_content(
      &cl, "Three legacy systems with no shared customer record.");

  /* 3 - read it back. The getter returns an OWNED string. */
  char *content = d00_solution_blueprint_content(&bp);
  printf("%s\n", content);
  free(content);

  /* 4 - validate against the model. */
  char *meta = slurp("meta/spec_model.meta.json");
  char *err = NULL;
  SpecModel *model = spec_model_from_json_str(meta, &err);
  SpecValidationErrors errs;
  validate_document(model, &doc, &errs);
  printf("%d\n", errs.len == 0);
  spec_validation_errors_free(&errs);

  /* 5 - serialize, then read the value back out of the decoded document.
   * `spec_document_content` returns a BORROWED pointer; the getter above
   * returned an owned one. The two conventions differ deliberately. */
  char *yerr = NULL;
  char *yaml = encode_yaml(&doc, d00_solution_blueprint_meta_tree(), "1.0", &yerr);
  SpecYamlContents decoded;
  decode_yaml(yaml, d00_solution_blueprint_meta_tree(), &decoded, &yerr);
  printf("%s\n", spec_document_content(&decoded.document, "SBP/content"));
  printf("%s\n", decoded.model_version);

  spec_yaml_contents_free(&decoded);
  free(yaml); free(meta); spec_model_free(model);
  current_landscape_free(&cl);
  d00_solution_blueprint_free(&bp);
  spec_document_free(&doc);
  return 0;
}
```

Output:

```
A platform that unifies our fragmented order systems.
1
A platform that unifies our fragmented order systems.
1.0
```

Run it with:

```bash
make && cc -Iinclude -I../tom_som_c_runtime/include tutorial.c \
      build/libtom_som_c_v0.a ../tom_som_c_runtime/build/libtom_som_c_runtime.a \
      -o tutorial && ./tutorial
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
./tool/regenerate_api_references.sh c_v0
```

That renders it with `doxygen`. The reasoning behind not committing it, and
the per-language generator notes, are in
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md),
"Documentation generation".

## Error Handling

There are no exceptions: a fallible call returns a status and writes an owned message to an `err` out-parameter. **Ownership is the thing to get right** — a typed getter returns an *owned* string the caller frees, while `spec_document_content` returns a *borrowed* pointer it must not.

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
  [`generic_access.md`](../../tom_som_c_runtime/doc/generic_access.md).
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
