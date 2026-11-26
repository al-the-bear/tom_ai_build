# Generic access — `tom_som_python_runtime`

The reflective, untyped half of the Python SOM plane: the document as a
sparse path-keyed store, the model as data, and the question of when to prefer
this over the generated typed facade.

The object model, the two wire formats and the validator contract are the
**subject matter** and are owned by
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md);
this guide cites it and never restates it. The typed half is
[`tom_som_python_v0/doc/tutorial.md`](../../tom_som_python_v0/doc/tutorial.md).

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
classes**. Those belong to `tom_som_python_v0`, which is a view over exactly the
store this package provides. Both halves address the same document; the
difference is only whether a member is named at compile time or resolved from a
string at run time.

The facade is a single top-level module and the runtime ships the importable `tom_som_runtime` package, so both resolve from a plain `pip install` with no build step.

## Quick Start

```bash
pip install tom_som_python_runtime
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
| `SpecValidator` / `validateDocument` | The instance tier: a filled document's values checked against the model; a typed value or reference holding inline marks is read as its old value (SOM §11.9.3) |
| `validate_links` | The link checks of one document (`tom_specs_model_rules.md` §9.7): derived values against their sources, summaries against their detail lists, each end of a link against the other, ids named in a text against the link rows, `@SameAs` copies against their holders |
| `SpecPlace`, `SpecPlaceFilter` | The place and filter grammar the link annotations are written in, resolved under an anchor without reading a value; the typed link readers (`synced_with`, `summary_of`, `derived_from`, `extracts_links`, `same_as`, the form-field `derived_from` / `inverse_of` / `summary_of`) are on the model's classes, fields and form fields |
| the YAML and Markdown codecs | `*.tomspecs.yaml` and DocSpecs markdown, byte-stable across all nine languages; the emitter writes the reading view's form, record and section tables and reference lines with an anchor in every heading (SOM §11.2, §11.4, §11.5), and the parser reads them as well as the older `Field:` lines; an import accepting rejections keeps each rejected block as a `rejected` div for review (SOM §11.7); the emitter writes a stripped rendition's readable header and styled-div headings on request, and the parser reads them back and stops at its appendix (SOM §11.1, §11.2) |
| `DocSpecsValidator` | The DocSpecs schema check of a rendition, in the `Field:` layout and in the reading view's tables, list bodies and styled-div headings |
| `scan_notation` | The reading notation of one text value: its divs, spans and citations and the notation's findings, which the DocSpecs validator reports as rules |
| `strip_notation_text` | The strip of one value (SOM §11.10): the secondary prose of named kinds dropped, unmarked or moved to an appendix, with the pieces that restore the value |
| `SpecDocumentStrip.strip` | The strip of a document (SOM §11.10): every value stripped into a copy; given a model, the emptying rule, the list items left empty removed, and the readable rendition — the readable header after the docspec line (`SpecReadableHeader`, SOM §11.1), styled-div headings below level six with `heading_divs`, the appendix *Notes* after `<!-- readable-appendix -->` — checked to read back and to add no finding |
| `merge_stripped_value`, `SpecStripMerge.merge` | The merge back (SOM §11.10): an edited value, or a whole edited `.readable.md`, merged onto the original with every stripped piece put back; conflicts and refused structural edits reported, a stale original merged three ways from the original at the export (`SpecStripMerge.git_show_file`) |
| the editing-facade bases | What the generated `tom_som_python_v0` types extend |

The full catalogue is the [README](../README.md); this guide is about using
them.

## Driving a document by path

A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.

```python
from tom_som_runtime import SpecDocument, yaml_encode
from tom_som_python_v0_meta import d00SolutionBlueprintMetaTree

doc = SpecDocument()
doc.set_content(
    "SBP/content", "A platform that unifies our fragmented order systems."
)

# A repeated section: append an item, then fill a content leaf under it.
item = doc.add_list_item("SBP/currentLandscape/CUOPME-OPER-LST")
doc.set_content(f"{item}/content", "Average order turnaround: 4.2 days.")

# The whole document serializes to the canonical wire format.
print(yaml_encode(doc, d00SolutionBlueprintMetaTree, model_version="1.0"))
```

The path grammar is the model's: a root segment, then a member per level, with
list items addressed by the path the store hands back when you append. Nothing
here needs a generated class, which is why this half of the plane is what
tooling reaches for.

## The model as data

The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).

```python
import json

from tom_som_runtime import SpecModel, SpecReflection
from tom_som_python_v0_data import spec_model_meta_path

with open(spec_model_meta_path(), encoding="utf-8") as fh:
    model = SpecModel.from_json(json.load(fh))
reflection = SpecReflection(model)

for root in reflection.roots:
    print(reflection.root_segment(root), root.title)

res = reflection.resolve("SBP/currentLandscape/content")
print(f"kind={res.kind.value}  value_leaf={res.is_value_leaf}")
```

This is the surface that makes generic editing safe rather than blind: before
writing to a path you can ask whether the model has one, what kind of node it
is, and whether it is a value leaf.

The links between places (`tom_specs_model_rules.md` §9.7) are model data too:
the readers return them typed, and a place resolves to where its value is
stored — list items below the anchor written `<list>-*` — again without a
document. `validate_links` then holds a document to them.

```python
from tom_som_runtime import SpecPlace, validate_links

sync = model.classes["AcceptanceCriteriaList"].synced_with
print(sync.document if sync else None)  # the root it is kept in sync with

r = SpecPlace.parse("FRED.description").resolve(reflection, "SBP")
print(r.kind, r.path, r.field)
# formField SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-*/FRED description

for e in validate_links(model, doc):
    print(e.code.value, e.path, e.message)
```

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

The full generated reference lives in `build/api_doc/` and is **not
committed** — it is output, and it regenerates:

```bash
cd ../tom_specs_clitool
./tool/regenerate_api_references.sh python_runtime
```

That renders it with `pdoc`. The reasoning behind not committing it, and
the per-language generator notes, are in
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md),
"Documentation generation".

## Error Handling

Failures raise. `validate_document` returns a list of errors rather than raising; a malformed `*.tomspecs.yaml` raises with the path it could not place.

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
