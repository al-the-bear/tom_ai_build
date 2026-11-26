# Generic access — `tom_som_java_runtime`

The reflective, untyped half of the Java SOM plane: the document as a
sparse path-keyed store, the model as data, and the question of when to prefer
this over the generated typed facade.

The object model, the two wire formats and the validator contract are the
**subject matter** and are owned by
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md);
this guide cites it and never restates it. The typed half is
[`tom_som_java_v0/doc/tutorial.md`](../../tom_som_java_v0/doc/tutorial.md).

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
classes**. Those belong to `tom_som_java_v0`, which is a view over exactly the
store this package provides. Both halves address the same document; the
difference is only whether a member is named at compile time or resolved from a
string at run time.

Both halves are plain Maven `jar` artifacts with no third-party dependencies, so a JDK alone builds and runs them — `build_jar.sh` produces the same artifact `mvn package` would.

## Quick Start

```bash
add the Maven dependency (group `io.github.al-the-bear`)
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
| `SpecValidator.validateLinks` | The link checks of one document (`tom_specs_model_rules.md` §9.7): derived values against their sources, summaries against their detail lists, each end of a link against the other, ids named in a text against the link rows, `@SameAs` copies against their holders |
| `SpecPlace`, `SpecPlaceFilter` | The place and filter grammar the link annotations are written in, resolved under an anchor without reading a value; the typed link readers (`syncedWith()`, `summaryOf()`, `derivedFrom()`, `extractsLinks()`, `sameAs()`, the form-field `derivedFrom` / `inverseOf` / `summaryOf`) are on the model's classes, fields and form fields |
| `SpecDeriveFields.deriveFields` | The derived places of one document written (§9.7), plain or as inline marks under review; `dryRun` answers the changes on a copy |
| `SpecDocumentSet`, `syncReport`, `renameId` | The documents of a project read side by side, one per root: the places a Phase 3 document shares with the Blueprint compared, the links across two documents checked, an id renamed in every document at once |
| `SpecPrefill.prefill`, `SpecBackfill.backfill` | The Blueprint into a new Phase 3 document, and the accepted Phase 3 end state back into the Blueprint |
| the YAML and Markdown codecs | `*.tomspecs.yaml` and DocSpecs markdown, byte-stable across all nine languages; the emitter writes the reading view's form, record and section tables and reference lines with an anchor in every heading (SOM §11.2, §11.4, §11.5), and the parser reads them as well as the older `Field:` lines; an import accepting rejections keeps each rejected block as a `rejected` div for review (SOM §11.7); the emitter writes a stripped rendition's readable header and styled-div headings on request, and the parser reads them back and stops at its appendix (SOM §11.1, §11.2) |
| `DocSpecsValidator` | The DocSpecs schema check of a rendition, in the `Field:` layout and in the reading view's tables, list bodies and styled-div headings |
| `SpecDocumentStrip.stripNotationText` | The strip of one text value (SOM §11.10): secondary prose of named kinds dropped, unmarked or moved to an appendix, with the pieces removed |
| `SpecDocumentStrip.strip` | The strip of a document (SOM §11.10): every value stripped into a copy; given a model, the emptying rule, the list items left empty removed, and the readable rendition — the readable header after the docspec line (`SpecReadableHeader`, SOM §11.1), styled-div headings below level six with `headingDivs`, the appendix *Notes* after `<!-- readable-appendix -->` — checked to read back and to add no finding |
| `SpecStripMerge.mergeStrippedValue`, `SpecStripMerge.merge` | The merge back (SOM §11.10): an edited value, or a whole edited `.readable.md`, merged onto the original with every stripped piece put back; conflicts and refused structural edits reported, a stale original merged three ways from the original at the export (`SpecStripMerge.gitShowFile`) |
| `SpecNotation.scanNotation` | The reading notation of one text value: its divs, spans and citations and the notation's findings, which the DocSpecs validator reports as rules |
| the editing-facade bases | What the generated `tom_som_java_v0` types extend |

The full catalogue is the [README](../README.md); this guide is about using
them.

## Driving a document by path

A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.

```java
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_java_v0.TomSomV0Meta;

SpecDocument doc = new SpecDocument();
doc.setContent("SBP/content",
    "A platform that unifies our fragmented order systems.");

// A repeated section: append an item, then fill a content leaf under it.
String item = doc.addListItem("SBP/currentLandscape/CUOPME-OPER-LST");
doc.setContent(item + "/content", "Average order turnaround: 4.2 days.");

// The whole document serializes to the canonical wire format.
System.out.println(SpecDocumentYaml.encode(
    doc, TomSomV0Meta.D00SolutionBlueprintMetaTree, "1.0"));
```

The path grammar is the model's: a root segment, then a member per level, with
list items addressed by the path the store hands back when you append. Nothing
here needs a generated class, which is why this half of the plane is what
tooling reaches for.

## The model as data

The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).

```java
import java.nio.file.Files;
import java.nio.file.Path;

import tom_som_runtime.Json;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecReflection;
import tom_som_runtime.SpecResolution;
import tom_som_runtime.SpecRoot;

SpecModel model = SpecModel.fromJson(
    Json.parseObject(Files.readString(Path.of("meta/spec_model.meta.json"))));
SpecReflection reflection = new SpecReflection(model);

for (SpecRoot root : reflection.roots()) {
  System.out.println(reflection.rootSegment(root) + "  " + root.title);
}

SpecResolution res = reflection.resolve("SBP/currentLandscape/content");
System.out.println("kind=" + res.kind.value + "  valueLeaf=" + res.isValueLeaf());
```

This is the surface that makes generic editing safe rather than blind: before
writing to a path you can ask whether the model has one, what kind of node it
is, and whether it is a value leaf.

The links between places (`tom_specs_model_rules.md` §9.7) are model data too:
the readers return them typed, and a place resolves to where its value is
stored — list items below the anchor written `<list>-*` — again without a
document. `SpecValidator.validateLinks` then holds a document to them.

```java
import tom_som_runtime.SpecPlace;
import tom_som_runtime.SpecPlaceResolution;
import tom_som_runtime.SpecSync;
import tom_som_runtime.SpecValidationError;
import tom_som_runtime.SpecValidator;

SpecSync sync = model.classNamed("AcceptanceCriteriaList").syncedWith();
if (sync != null) {
  System.out.println(sync.document); // the root it is kept in sync with
}

SpecPlaceResolution r = SpecPlace.parse("FRED.description").resolve(reflection, "SBP");
System.out.println(r.kind.value + " " + r.path + " " + r.field());
// formField SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-*/FRED description

for (SpecValidationError e : SpecValidator.validateLinks(model, doc)) {
  System.out.println(e.code.value + " " + e.path + " " + e.message);
}
```

A place or filter that does not parse or resolve throws a `SpecPlaceException`
whose `problem` (`SpecPlaceProblem`) says why: `malformed`, `anchorUnresolved`,
`notScoped`, `unresolved`, `ambiguous`, `noSuchField`, `noContent`,
`notListElement`, `reservedSlot`.

Across documents, the set compares what a Phase 3 document shares with the
Blueprint; `deriveFields` writes a document's derived places:

```java
import java.util.List;
import java.util.Map;
import tom_som_runtime.SpecDeriveChange;
import tom_som_runtime.SpecDeriveFields;
import tom_som_runtime.SpecDeriveOptions;
import tom_som_runtime.SpecDocumentSet;
import tom_som_runtime.SpecSyncFinding;

// Throws a SpecDocumentSetError for two documents of one root, …
SpecDocumentSet set =
    new SpecDocumentSet(
        model, List.of(Map.entry("sbp.tomspecs.yaml", sbp), Map.entry("rsp.tomspecs.yaml", rsp)));
for (SpecSyncFinding f : SpecDocumentSet.syncReport(set).findings) {
  System.out.println(f.code.value + " " + f.resolution.value + " " + f.message);
}

SpecDeriveOptions options = new SpecDeriveOptions(); // marked; plain(): plain values
options.dryRun = true;
for (SpecDeriveChange c : SpecDeriveFields.deriveFields(model, rsp, options).changes) {
  System.out.println(c.step + " " + c.kind + " " + c.path + " " + c.field + " " + c.newValue);
}
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
./tool/regenerate_api_references.sh java_runtime
```

That renders it with `javadoc`. The reasoning behind not committing it, and
the per-language generator notes, are in
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md),
"Documentation generation".

## Error Handling

Failures throw. `SpecValidator.validateDocument` returns a list instead; an empty list is the pass.

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
