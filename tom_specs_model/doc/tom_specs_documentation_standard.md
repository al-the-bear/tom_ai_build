# TomSpecs documentation standard

**Quest:** tom_specs
**Status:** Normative. Every TomSpecs package is authored and reviewed against this document.
**Scope:** The 29 packages of the TomSpecs quest — their `README.md`, their `doc/` folder, their API reference and their samples.
**Audience:** Whoever writes or reviews documentation for a TomSpecs package.

This document decides **what documentation a TomSpecs package carries, where
each piece lives, and when it is finished**. It owns no subject matter of its
own: it is the rule the other documents in this folder are exempt from and the
packages are held to.

It exists because the two workspace conventions it builds on —
[`_copilot_guidelines/component_module_readme_example.md`](../../../../_copilot_guidelines/component_module_readme_example.md)
(README shape) and
[`_copilot_guidelines/documentation_guidelines.md`](../../../../_copilot_guidelines/documentation_guidelines.md)
(`doc/` folder shape) — describe a *standalone* package, and TomSpecs is not
one. It is 29 packages sharing a single body of subject matter that no package
owns. Applying the workspace conventions naively would put a copy of the
methodology in every package; applying [`index.md`](index.md) naively would
leave 28 packages with nothing but a README. §1 settles that, and everything
after it follows from the settlement.

---

## 1 The two tiers

TomSpecs documentation lives in **two tiers, and a fact belongs to exactly
one**.

| Tier | Where | Holds | Owned by |
|------|-------|-------|----------|
| **Subject matter** | [`tom_ai/ai_build/tom_specs_model/doc/`](index.md) | The methodology, the object model, the file formats, the CodeSpecs mapping and contract, the creation process, and the specifications of the applications | [`index.md`](index.md) — one authority per document |
| **Package** | `<package>/README.md` and `<package>/doc/` | How to *use this package's code*: what it is, how to install it, its API, its usage guides, its samples | The package |

### 1.1 The membership test

One question decides the tier: **would deleting this package change what the
document is about?**

- **No** → subject matter. The DocSpecs markdown format is what it is whether or
  not `tom_som_go_v0` exists; `SOM §11` stays in this folder.
- **Yes** → package documentation. "How to call `SpecDocument.load` in Go" has
  no meaning without `tom_som_go_v0`; it belongs in that package's `doc/`.

The test is deliberately about the *subject*, not about the *reader* or the
*project the code lives in*. `som_toolchains.md` documents nine packages'
toolchains and lives here, because the subject — what it takes to build a SOM
artefact — outlives any one of them. `tom_specs_editor_specification.md` lives
here for the same reason: it says what the application *must be*, which is a
methodology question, and it would still say it if the code were rewritten from
scratch in another framework.

### 1.2 Never restate — link

A package document **never restates a subject-matter document**. It links it,
in one sentence that says what the reader will find there. This is the workspace
convention's "don't duplicate — link instead" (rule 3), and here it is
load-bearing rather than stylistic: [`index.md`](index.md) enforces one
authority per document, and a package doc that paraphrases a methodology
document creates a second answer that will drift from the first.

Concretely, a package document may:

- **state** what its own code does, its API, its parameters, its errors, its
  examples;
- **cite** a subject-matter document by name and section for the *why*, the
  format, the rule or the contract — `SOM §12.3`,
  `tom_specs_model_rules.md §6.1`;
- **quote** at most a sentence, where the citation alone would leave the example
  unreadable.

It may not carry its own version of the format, the phase model, the annotation
semantics or the derivation rules. If a package doc needs a paragraph of
methodology that no subject-matter document carries, that paragraph is a gap in
this folder — add it here and link it, do not write it there.

### 1.3 What this means for `index.md`

[`index.md`](index.md) is the catalogue of the **subject-matter tier**, not of
all TomSpecs documentation. Its "Authorities outside this folder" table names
this document as the authority for the package tier, so a reader who lands in
this folder looking for "how do I use `tom_specs_clitool`" is routed out rather
than left to conclude it is undocumented.

---

## 2 The README

Every TomSpecs package has a `README.md` at its root. It is the package's front
door — for a pub.dev / PyPI / crates.io visitor it is often the *only* page they
read — so it must stand alone.

### 2.1 Section order

The workspace module-README order
(`component_module_readme_example.md`, "Module / Package README") applies, with
three TomSpecs adaptations marked **[T]**:

| # | Section | Required | Content |
|---|---------|----------|---------|
| 1 | `# <package name>` | always | The package name, optionally followed by ` — <five-word gloss>`. |
| 2 | Cross-references blockquote **[T]** | always | See §2.2. |
| 3 | One-line description | always | Matches the package manifest's `description` word for word. |
| 4 | **Where this fits** **[T]** | always | See §2.3. |
| 5 | Overview | always | How the thing works *conceptually*, in prose. Enough to decide "is this what I need?". |
| 6 | Installation | published packages | The manifest snippet **and** the one-line add command. Never a path override or `pubspec_overrides.yaml`. |
| 7 | Features | when enumerable | Grouped sub-sections, each a table. |
| 8 | Quick start | always | One minimal runnable example with inline `// output` comments that are true. |
| 9 | Examples table | when `example/` exists | `Sample \| Demonstrates`, linking into `example/`. |
| 10 | Usage | always | Progressive depth, one sub-section per capability, each a short runnable block. |
| 11 | Architecture | libraries and tools | ASCII diagram plus a **key-types table** (`Type \| Responsibility`). |
| 12 | Ecosystem | always | ASCII dependency diagram placing the package among its TomSpecs siblings. |
| 13 | Further documentation | always | See §2.4. |
| 14 | Status | always | Current version and test count. |

A section that would be empty is omitted, not left as a heading with "TBD" under
it. A section marked *always* is never empty — if it looks empty, the package is
not ready to be documented.

### 2.2 The cross-references blockquote **[T]**

The workspace convention puts an **attribution blockquote** directly under the
title. TomSpecs packages are original work of this workspace, so there is
nothing to attribute, and a manufactured attribution would be a false statement
in the most prominent position on the page.

The slot is filled instead by a **cross-references blockquote** — the pattern
already established by
[`tom_specs_core/README.md`](../../tom_specs_core/README.md). It names, in two
to five lines, the subject-matter documents this package's reader will need and
what each of them decides:

```markdown
> **Cross-references.**
> [`tom_specs_model/doc/tom_specs_model_rules.md`](../tom_specs_model/doc/tom_specs_model_rules.md)
> owns the annotation **vocabulary and authoring rules** and the **mapping
> semantics** of each annotation. This README is the catalogue of *what each
> annotation is*; that document owns *how it maps* and *when to use it*.
```

The last sentence is the important one: it draws the §1.2 boundary explicitly,
at the top of the page, so a later editor knows which side of the line they are
writing on.

A package that genuinely embeds third-party work carries **both** blockquotes,
attribution first.

**Keep each file name on the same line as the `§` it qualifies.** This
blockquote is the densest concentration of citations in a README, and it is the
one place where the natural line break silently breaks one. `index.md`'s
convention lets a leading document name govern the citations that follow it, but
`check_section_citations.dart` recognises that qualifier only across `)`, a
backtick and whitespace — **not across the `>` blockquote marker**. So a name
ending one line does not reach a `§N` opening the next, and that `§N` resolves
against the README's own (nonexistent) headings and fails the gate. Rewrap so
that name and section sit together; repeating the file name on each line is
correct and costs nothing.

### 2.3 "Where this fits" **[T]**

One paragraph, three to six sentences, answering in order:

1. **What is this package?** One sentence, concrete.
2. **Why does it exist?** What would be worse without it — the gap it fills, not
   a restatement of what it does.
3. **How does it fit the TomSpecs whole?** Which phase, which tier, which
   neighbours it sits between, and what depends on it.

This paragraph is the reason the section is mandatory: a TomSpecs package
encountered alone is almost never self-explanatory —
`tom_som_rust_v0` and `tom_core_codespecs` both look like fragments until the
whole is named. Write it for a reader who has never heard of TomSpecs.

### 2.4 The cross-link block

The "Further documentation" section is a **table, not prose**, in two parts:

```markdown
## Further documentation

**TomSpecs subject matter** — the authorities this package implements:

| Document | Authority for |
|----------|---------------|
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | … |

**This package** — its own guides:

| Guide | Covers |
|-------|--------|
| [doc/<name>.md](doc/<name>.md) | … |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_specs_core](../tom_specs_core) | … |
```

Rules:

- **Relative links only.** Never an absolute path and never a `file://` URL —
  the link must work on the registry page, on GitHub and in a local checkout
  alike.
- **Every subject-matter document this package's reader needs appears here**,
  and each row says what that document *decides*, not what it is about.
- **Every file in the package's own `doc/` appears here**, which is what makes
  the `doc/` folder reachable (§3.4).
- **The index is linked**: at least one row points at
  [`tom_specs_model/doc/index.md`](index.md), so a reader can reach the whole
  catalogue from any package.

### 2.5 Status

`## Status` states the current version and the test count, and nothing else.
Both are promises: a version that no longer matches the manifest, or a test
count that no longer matches a run, is worse than an absent section, because a
reader who checks one and finds it stale stops trusting the rest of the page.

**A generated README states no test count.** It cannot keep one: the file is
rewritten by a generator that does not run the suite, so any number in it would
be a number nothing updates — and the promise above is exactly what a
never-updated number breaks. In its place a generated `## Status` carries the
version, the counts the generator does hold as facts (document roots and
generated types, read back from the meta-data file it has just written), and
the command that runs the package's suite. The command is the standing answer a
fixed number was only ever standing in for. This is the one carve-out; a
hand-written README states the count.

---

## 3 The `doc/` folder

### 3.1 What goes in it

A package's `doc/` holds **its own** documentation and nothing else:

| Path | Holds |
|------|-------|
| `doc/index.md` | The folder's catalogue — one row per file, linking it, saying what it covers. Mandatory once `doc/` holds more than one file. |
| `doc/<topic>.md` | One file per module or coherent capability. |
| `doc/api/api_summary_<module>.md` | The hand-written API summary per module (`_copilot_guidelines/dart/api_summary_creation.md`). |
| `doc/api/reference/` | The **generated** API reference (§5). **Gitignored** — it is output, not source; see §5 and `som_toolchains.md`, "Documentation generation". A package is complete when the reference *regenerates*, not when it is present. |

`README.md` and `CHANGELOG.md` stay at the package root and are never moved into
`doc/`. Test artefacts never go in `doc/` — they belong in `testlog/`, which is
gitignored. Generator output other than the API reference never goes in `doc/`
— it belongs in a `generated-doc/` sibling.

**The one package whose `doc/` hosts both tiers.**
`tom_ai/ai_build/tom_specs_model/doc/` is the subject-matter tier's home (§1),
so its `doc/index.md` is already the catalogue of *that* tier and its files are
already the authorities. That package's own package-tier documentation — how to
author a model class in Dart, the generated ops registry, the projection roots
— therefore lands in **`doc/package/`**, with **`doc/package/index.md`** as its
catalogue, and its API summaries in the usual `doc/api/` (a path no
subject-matter document uses). Two catalogues, one folder, and each says which
tier it belongs to in its first paragraph. The alternative — mixing package
guides in among the fourteen authorities — would leave `index.md` catalogueing
two different things and a reader unable to tell which tier a file is in.
`doc/index.md` carries one row pointing at `doc/package/index.md`, so the
§3.4 reachability rule still closes.

### 3.2 Which packages get one

| Package kind | `doc/` | Rationale |
|--------------|--------|-----------|
| Library (`tom_specs_core`, `tom_specs_model`, `tom_code_specs`, `tom_core_codespecs`, `tom_doc_scanner`, `tom_doc_specs`) | yes | Consumed as an API; a README cannot carry the depth. |
| Tool (`tom_specs_clitool`, `tom_spec_engine`, `tom_som_conformance`) | yes | Command surfaces and scripting planes need per-capability guides. |
| SOM runtime (`tom_som_<lang>_runtime`, nine) | yes | The generic access API, per language. See §4. |
| SOM facade (`tom_som_<lang>_v0`, nine, generated) | yes | The tutorial and the API reference. See §4. |
| `tom_specs_reviewer` | yes, one file | See §6. |
| `tom_specs_editor` | no | Out of scope. See §6. |

### 3.3 The shape of a `doc/` file

`_copilot_guidelines/documentation_guidelines.md` is the authority. Its required
order applies unchanged:

1. `# Tom <Module Name> System` (or the module's natural title)
2. A one-paragraph summary
3. **Table of Contents** — anchor links to every section, and every link resolves
4. **Overview** — component list and value proposition
5. **Quick Start**
6. **Core Components**
7. Feature sections
8. **Error Handling**
9. **Best Practices**

Optional, where the subject calls for it: Dependencies, Build Configuration,
Class Hierarchy, Serialization.

Two rules from that guideline are worth restating because they are the two most
often broken:

- **Every code example is complete and shows its expected output.** No
  fragments, no `...`, no example that cannot be pasted and run.
- **No non-deterministic values in examples** — no `DateTime.now()`, no random
  ids, no absolute paths from the author's machine. An example whose output
  cannot be reproduced is not an example.

### 3.4 Cross-linking

Two closure rules, both checkable by reading:

1. **Reachability.** Every file in `doc/` is reachable from `doc/index.md`, and
   `doc/index.md` is reachable from the README's Further-documentation table
   (§2.4). A file no path reaches is a file nobody will read.
2. **Resolution.** Every relative link resolves to a file that exists, and every
   `§` citation of a subject-matter document resolves to a real section of that
   document. The citation convention is [`index.md`](index.md)'s, including its
   bare-`§N`-means-this-document rule; package documents are inside the corpus
   that `tom_specs_clitool/bin/check_section_citations.dart` scans, so a
   dangling citation fails a gate rather than merely misleading a reader.

---

## 4 The nine language planes

Each SOM language is a **pair**: a hand-written `tom_som_<lang>_runtime` and a
generated `tom_som_<lang>_v0` facade over it. A consumer installs the facade;
the facade depends on the runtime. Both halves are documented, and the split
follows §1.1 applied one level down — the facade is the typed, normal path; the
runtime is the generic, reflective one.

| Package | Carries |
|---------|---------|
| `tom_som_<lang>_v0` | `doc/tutorial.md` — a **hand-written** tutorial showing how the SOM is used *in this language*, end to end: install, open a document, read a section, edit it, validate, serialize. Plus `doc/api/reference/` — the **generated** API reference (§5). |
| `tom_som_<lang>_runtime` | `doc/generic_access.md` — the reflective/untyped API: the meta-data tree, walking a document without typed classes, and when to prefer it over the facade. Plus its own generated API reference. |

Each links the other, and both link
[`som_multiplatform_spec_model.md`](som_multiplatform_spec_model.md) for the
format and the model. Neither restates it.

### 4.1 Hand-written files inside a generated package

The `v0` packages are generated, and their `README.md`,
`readme_howtointegrate.md`, `LICENSE`, `CHANGELOG.md`, `lib/`, `meta/`,
`schemas/` and manifest are **overwritten on every**
`tom_specs_clitool/bin/generate_som.dart` **run**. Everything else is preserved
— the generator writes files, it never wipes the output root, which is exactly
why the hand-authored `example/`, `test/` and `tool/` trees already survive
there.

`doc/` joins that preserved set. It is hand-written, it lives in a generated
package, and that is safe. The rule for anyone editing inside a `v0` package is
the one the banner already states: **if the file carries the
`GENERATED … do not edit by hand` banner, edit the template instead.**

### 4.2 The generated README must link the tutorial

Because a `v0` README is generated, it cannot be hand-edited to point at
`doc/tutorial.md`. The link is emitted from the template —
`renderFacadeReadme()` in
`tom_ai/ai_build/tom_specs_clitool/lib/src/packaging.dart` — so that all nine
carry it and none can lose it in a regeneration. A per-language sentence about
the tutorial belongs on the `PackagingDescriptor`, not in the shared template
body.

That rule generalises: **every per-language nuance of a generated README is a
descriptor field, never a branch on the language.** `renderFacadeReadme()`
emits the whole §2 template, and the three kinds of input it needs come from
three different places, each for a reason:

| Input | Source | Why there |
|-------|--------|-----------|
| Anything the same in all nine (the §2.2 blockquote, "Where this fits", the architecture and ecosystem diagrams, the cross-link block) | The shared template body | One copy, so a wording fix lands in nine files at once. |
| Anything true of one language only (`manifestDescription`, `whereThisFitsSentence`, `tutorialSentence`, `examples`, `usageSections`, `verifyCommand`) | A `PackagingDescriptor` field | Required fields, so a tenth language cannot be registered with the section silently missing. |
| Anything decided by the *model* (the document-roots table, the generated-type count) | Read back from the emitted `meta/spec_model.meta.json` | These are not per-language facts. Nine hand-kept copies would be nine things to keep current, and drift would read as a README describing a model its package no longer implements. |

The descriptor fields are held to their targets by `packaging_test.dart`, which
checks each listed example file exists and each `manifestDescription` still
occurs in the manifest it names — so a renamed sample or a reworded manifest
fails a test rather than leaving a dead link or a false claim on a registry
page.

---

## 5 The API reference

The API reference is **generated, never hand-written**, and lands in
`doc/api/reference/`.

| Language | Generator |
|----------|-----------|
| Dart | `dart doc` |
| Python | `pdoc` |
| JavaScript / TypeScript | `typedoc` |
| Go | `go doc` |
| Rust | `cargo doc` |
| Java | `javadoc` |
| C / C++ | `doxygen` |

All eight are driven by one entry point —
[`tom_specs_clitool/tool/regenerate_api_references.sh`](../../tom_specs_clitool/tool/regenerate_api_references.sh)
— which reaches all eighteen SOM packages, skips a missing toolchain **with its
reason stated**, and turns a skip into a failure under `--strict`. Its
per-language invocations, and the several non-obvious adjustments they needed,
are recorded in [`som_toolchains.md`](som_toolchains.md), "Documentation
generation".

**The rendered reference is gitignored** (`**/doc/api/**`, with
`api_summary_*.md` re-included). It is large, it is HTML, and it regenerates
from source — so holding it would trade an unreadable diff on every source edit
for nothing a reader cannot rebuild. The reasoning is recorded in full in
`som_toolchains.md`.

Because it is generated, the quality bar is on the **source comments**, not on
the reference. The bar:

| Package kind | Public-API documentation coverage |
|--------------|-----------------------------------|
| Libraries, tools, SOM runtimes | **95 %** |
| `tom_specs_reviewer` | **90 %** |
| Generated packages (`tom_som_*_v0`) | exempt — coverage is the **emitter's** responsibility and is measured on the emitter's templates, not on its output |

**Committed or not.** The hand-written `doc/api/api_summary_<module>.md` files
are source and are committed; the generated `doc/api/reference/` is output and
is not. The workspace `.gitignore`s encode exactly that, and encode it by
excluding the *contents* of `doc/api/` rather than the directory — git cannot
re-include a file whose parent directory is excluded, so a directory-level
`**/doc/api/` would silently swallow every summary written under it.

"Public API" means every exported declaration and every public member of one.
A comment that restates the identifier (`/// The name.` on `String name`) does
not count as documented — it says nothing the signature has not already said.
What earns the coverage is the *why*, the units, the invariant, the failure
mode, and the citation to the subject-matter document that decides the
behaviour.

Coverage is measured, not estimated. `tom_specs_clitool` carries the gate; the
bar above is what it enforces, and a package below its bar fails the default
test run rather than passing unnoticed.

**A Dart package that has reached the bar holds itself there with the lint.**
`public_member_api_docs` in the package's own `analysis_options.yaml` makes
`dart analyze` the ratchet, so a new public member without a doc comment fails
at edit time instead of waiting for the next coverage sweep to find it. Enable
it in the same change that closes the gap — before that it reports the whole
backlog on every run and is ignored, which is worse than not having it. It does
not replace the cross-package gate: the gate measures every package including
the ones still below their bar, and it is what a *reader* of the bar can check.
The lint is what stops a package that has passed from quietly regressing. Note
that the lint exempts `@override` members, and rightly — dartdoc inherits the
supertype's comment, so re-documenting an override duplicates a sentence that
has one home.

**Enable `comment_references` beside it.** A dartdoc `[Reference]` that does
not resolve is invisible until `dart doc` runs; with the lint on it fails at
edit time. Three causes account for nearly all of them, and only the third is
a real mistake:

1. **A pure-export barrel.** An `export` does not bring a name into the
   library's own scope, so a barrel's library comment cannot resolve the
   symbols it re-exports — 18 of them in `tom_core_codespecs`, 13 in
   `tom_spec_engine`'s `agent.dart` alone. The fix is `@docImport`, a doc-only
   import with no runtime cost, one line per file whose symbols the comment
   names, placed immediately above `library;`:

   ```dart
   /// @docImport 'src/agent/agent_context.dart';
   library;

   export 'src/agent/agent_context.dart';
   ```

   Prefer this to backticks everywhere the target is a real Dart identifier —
   backticks silently downgrade a working link to plain text. Note that
   `library;` must precede every other directive, so it goes above the imports,
   not after them.
2. **A cross-file reference within the same package.** Same fix, same reason.
3. **Prose that happens to contain brackets.** A CLI usage line
   (`docspecs scan <files...> [options]`), a regex's subject (`extract the ID
   from [id]`), a map subscript (`fields['tags']`), a `@Form` field name. These
   are not references and never were — backtick them.

**Run `dart doc` as well as the lint; they disagree.** `dart doc` is the
stricter of the two on bracketed prose — it flagged `fields['tags']` in
`tom_doc_specs` that `comment_references` passed — and it is the tool whose
output a reader actually sees. The lint catches things at edit time; `dart doc`
is the acceptance check. Neither substitutes for the other.

**The lint checks everything under `lib/`, not only the exported surface.**
Tested directly rather than inferred: a public member of a `lib/src/` library
that no barrel re-exports is still reported. So the enforced set is wider than
the "every exported declaration" wording above, and deliberately so — an
undocumented internal module is a maintenance cost whether or not a consumer
can name it, and for an application like `tom_specs_reviewer`, which has no
barrel at all, the exported surface is nearly empty and would make the bar
meaningless.

The gate measures the same set for the same reason. Read the wording above as
naming the *minimum* — what a consumer sees — and `lib/` as what is actually
held.

**This corrects an earlier claim.** Until the gate was built, this section said
the lint measured only the exported surface, on the strength of a count that
differed from a scanner's. The difference was the scanner's own defects, not a
narrower lint: twelve of them were found and fixed over the campaign, and once
they were, the two agreed. The lesson is the one this section already gives —
where two measurements disagree, read the code — and it applies to a conclusion
drawn from them just as much as to the numbers.

---

## 6 The two Flutter applications

`tom_specs_editor` and `tom_specs_reviewer` are deliberately outside the
release-1 set and are published nowhere, so the treatment is not symmetric with
the libraries.

- **`tom_specs_editor` — out of scope for this campaign.** Its behaviour is
  already specified by
  [`tom_specs_editor_specification.md`](tom_specs_editor_specification.md),
  which is the subject-matter authority a reader needs; a second, package-tier
  description of the same application would be exactly the duplication §1.2
  forbids. It carries a README that says what the app is and links that
  specification. No `doc/`, no dartdoc bar.
- **`tom_specs_reviewer` — in scope, at a deliberately modest bar.** A README
  and **one** `doc/` file, both aimed at the same question: *what is this tool,
  and what is it for?* The reviewer exists to browse the exported class graph
  and record structural observations, and a reader who has just been handed it
  needs the workflow — refresh the model snapshot, open a document root, walk
  the tree, record a flag or a comment, find the review file afterwards — not an
  architecture tour.
  [`tom_specs_reviewer_specification.md`](tom_specs_reviewer_specification.md)
  remains the authority for what the app must be; the package documentation is
  the user's path through it. Dartdoc bar: 90 %.

Neither application gains a `lib/<package>.dart` barrel. A barrel exists so a
consumer can import a package with one line; a Flutter application has no
consumer and is entered through `lib/main.dart`. Introducing one would be
ceremony that documents nothing.

---

## 7 Samples

Samples live in a **single repository folder,
`tom_ai/ai_build/tom_specs_samples/`**, with one subfolder per sample project —
not scattered through the packages' `example/` trees. A sample demonstrates
*TomSpecs*, which spans packages; a package's `example/` demonstrates *that
package*, and both continue to exist.

The workspace example conventions apply inside a sample
(`component_module_readme_example.md`, "Good library examples"): self-contained
and runnable, one concept per file, minimal imports, a header comment giving the
run command, and inline expected output. Each sample subfolder carries a README
using the example-README shape, and `tom_specs_samples/README.md` is the index
over them with a learning-path ordering.

Samples exist **per language**, mirroring §4: the Dart set is authored first and
is the reference, and each other language plane gets the same scenarios ported,
so a Go reader and a Dart reader learn the same TomSpecs from equivalent code.

---

## 8 The acceptance checklist

A `tsdoc` todo is finished when every applicable line is true. Applicability is
decided by §3.2 and §6; a line that does not apply is not silently skipped but
noted as not applicable.

**README**

- [ ] Sections present in the §2.1 order; no empty heading, no "TBD"
- [ ] Cross-references blockquote directly under the title, ending with the §1.2 boundary sentence (§2.2)
- [ ] "Where this fits" answers all three questions of §2.3, written for a reader who has never heard of TomSpecs
- [ ] One-line description matches the package manifest word for word
- [ ] Installation shows a real version constraint; no path override, no `pubspec_overrides.yaml`
- [ ] Quick start is runnable and its inline expected output is true
- [ ] Key-types table matches the actual public types
- [ ] Ecosystem diagram places the package among its real siblings
- [ ] Further-documentation table has all three parts (§2.4) and links `index.md`
- [ ] All links relative; all links resolve
- [ ] Every `§` citation resolves; `check_section_citations.dart` passes. Its default corpus is **closed over the package tier**: every TomSpecs README (`defaultCitedReadmes`), every package `doc/` folder (`defaultCitedDocFolders`) and every citing source tree (`defaultCitedSourceRoots`). A newly documented package is gated the moment its folder is added to that list, and not before
- [ ] Content the package's own tests hold is unchanged — grep `test/` for `README` before reshaping any table or list. Two are known: `tom_specs_clitool`'s `bin/` table (`entrypoint_options_test.dart`) and every public declaration of `tom_core_codespecs` (`gap_class_inventory_test.dart`); grep rather than trust the list
- [ ] `## Status` version matches the manifest and test count matches a run — or, for a generated README, carries the verify command in place of a count (§2.5)

**`doc/` folder**

- [ ] `doc/index.md` exists (once there is more than one file) and lists every file
- [ ] Every file reachable from `doc/index.md`; `doc/index.md` reachable from the README
- [ ] Each file follows the §3.3 order, with a working Table of Contents
- [ ] Every code example complete, runnable, with expected output; no non-deterministic values
- [ ] Nothing restates a subject-matter document — each such fact is a citation (§1.2)
- [ ] Every `§` citation resolves; `check_section_citations.dart` passes
- [ ] `doc/api/api_summary_<module>.md` present per module

**API reference and dartdoc**

- [ ] Public-API coverage at or above the §5 bar for the package kind
- [ ] No comment that merely restates its identifier counted toward coverage
- [ ] `doc/api/reference/` **regenerates** with the §5 tool for the language — the folder is gitignored, so what is checked is that `tom_specs_clitool/tool/regenerate_api_references.sh` produces it, not that it is committed
- [ ] Behaviour decided by a subject-matter document cites it, by name and section

**Corpus**

- [ ] `index.md`'s catalogue is consistent with what the folder holds
- [ ] The default test run is green, citation gates included
