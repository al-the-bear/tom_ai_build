# TomSpecs Documentation

This is the **single folder for all TomSpecs subject-matter documentation** —
the specification object model (SOM), the multi-language access API, the file
formats, the CodeSpecs mapping, the creation process and the applications built
on them. A subject belongs here when it would still be the same subject if any
one package were deleted, which is why the documentation of tools that live in
other projects (`tom_specs_clitool`, `tom_spec_engine`, `tom_som_conformance`,
…) is here too.

TomSpecs documentation is **two tiers, and this folder is one of them.** The
other is the package tier — each package's `README.md` and its `doc/` folder,
covering how to use *that package's code*: its API, its usage guides, its
samples. [tom_specs_documentation_standard.md](tom_specs_documentation_standard.md)
is the authority for that tier, and it owns the membership test that assigns a
fact to one tier or the other. The two never restate each other: a package
document cites a document in this folder, it does not paraphrase one.

**Fourteen documents plus this index.** Each holds exactly one authority and is
listed exactly once below — if two documents could answer the same question, one
of them is wrong. Read the *Authority for* column, not the title: the title says
what a document is about, the authority says what it decides.

Quest bookkeeping — progress logs, todo yamls, session trails — lives in
`_ai/quests/tom_specs/` and is deliberately **not** part of this folder. So does
campaign history: these documents state the current design only.

That applies to a document's own header as much as to its prose. A document here
opens with `**Quest:** tom_specs` and a `**Status:**` line saying what it is —
normative, implemented, planned — plus whatever `**Scope:**` / `**Audience:**` /
`**Project:**` lines its subject needs. It carries **no version field and no
revision history**, not even when it is formally sectioned with its own section
ids: git is the revision authority for a file under version control, and a
version number no reader can act on is worse than none. What a document *used to
say* is recoverable from history; what it says now is the only thing it should
be asked to carry.

**Not everything that mentions the past is history.** A formally structured
specification carries constructs that *look* like a record but are load-bearing
now, and the test is one question: **would deleting it change what the document
says about the present, or only what it says about the past?**

- A **decision register** whose ids the body cites inline —
  `tom_specs_editor_specification.md` §2, cited some fifty times as `(N12)`,
  `(Q9)`, `(IO2)` — is the referent table those citations resolve against.
  Deleting it makes the body unreadable, so it stays. It earns that by stating
  each decision in the present tense: *what the design is*, not *what was
  agreed when*.
- An **open-ends register** whose ids are cited from *shipped source*
  (`tom_specs_editor_specification.md` §22, cited as `OE-3a` and some seventy
  others from the editor's `lib/`, `test/`, `pubspec.yaml` and `buildkit.yaml`)
  is the same construct one level out: a row survives its work because the
  comment at the seam still names it. It states what an id *refers to* in the
  present tense and leaves what is still *open* about it to
  `_ai/quests/tom_specs/deferred.tom_specs.md`.
- A **`Done:` condition** on a plan step (`tom_specs_editor_specification.md`
  §20) is an **acceptance criterion**, not a claim that the step is finished.
  Which steps *are* finished is progress state and lives in
  `_ai/quests/tom_specs/progress.tom_specs.md`. A plan step that marks itself
  complete has crossed the line and gets stripped.
- A **hazard list** of API names that are easy to get wrong
  (`codespecs_mapping.md` §4.1.2) states current facts about the framework, and
  is kept. A table of *what a name used to be* states nothing current and is
  not — that is precisely what git is for.

So: keep the construct, phrase it in the present tense, and say in the document
why it is not history. An unexplained exception gets re-flagged by the next
sweep and re-argued from scratch.

## How to cite these documents

Code comments and documents cite a section of
[som_multiplatform_spec_model.md](som_multiplatform_spec_model.md) as **`SOM §N`**
— for example `SOM §11.4`, `SOM §8`. The short form exists because these
citations appear inside fixed-width comment banners in generated source across
nine languages, where a longer form would not fit. Spell the file name out in
full at least once per file where it reads naturally, then use the short form.

Every other document is cited by **file name plus section** —
`codespecs_mapping.md §9.2`, `tom_specs_model_rules.md §6.1`.

**A bare `§N` means *this* document.** Only a reference that leaves its own
document has to name one; within a document, `§N` is the section of the file you
are reading. That is how these documents have always been written — the
overwhelming majority of citations in the set are intra-document — and it is
what makes the convention decidable: resolve the number against the current
file's headings first, and reach for another document only when a document name
governs the citation.

A document name governs a citation in exactly five ways:

1. **In front of it** — `` `codespecs_mapping.md` §9.2 ``, or `SOM §11.4`. The
   name may sit on the previous line across a soft wrap, and it may be the tail
   of a markdown link — `[llm_and_d4rt_tools.md](llm_and_d4rt_tools.md) §6`.
2. **Behind it** — `§N of [\`llm_and_d4rt_tools.md\`](llm_and_d4rt_tools.md)`.
3. **By inheritance within a run** — in `` `codespecs_mapping.md` §4.1 / §4.2 /
   §4.3 ``, `(§N, §M)` or `§N–§M`, the name in front of the first citation
   governs the rest. Only separators and joining words (`and`, `or`, `to`,
   `through`) may stand between them; a sentence break ends the run.
4. **By table-row scope** — in a document-map table whose first cell holds a
   document reference *and nothing else*, that document governs every citation
   in the row. A first cell that already mixes prose with a citation does not
   scope the row.
5. **By table-column scope** — the transpose of rule 4. In a table that indexes
   a companion document section by section, the column may be headed with the
   document and a bare `§` — `` | Area | Role | `llm_and_d4rt_tools.md` § | `` —
   and every cell beneath that header carries only the number. The same "and
   nothing else" guard applies, plus one addition: the trailing `§` is what
   makes the header *say* the column holds sections rather than merely mention a
   file, so a header without it scopes nothing. The scope covers its own column
   only, and ends with the table.

Resolution is **exact**: `§N.M.K` resolves only against a heading `N.M.K`, never
against its parent `N.M` and never against a child of it. A number that names a
numbered *rule* inside a section rather than a heading is not a citation —
write "rule 6 of §N.M".

`tom_specs_clitool`'s `bin/check_section_citations.dart` implements exactly this
procedure, so any `§N` in the doc folder can be resolved without a human reading
it. That is also why the illustrations above are written with metavariables
wherever they show an *unqualified* citation: a real number there would be read
by the checker as a citation of a section of `index.md`, which has none.

Cite by **subject, not by number**. Section numbers move when a document is
restructured, so a number carried mechanically from one document to another
points at whatever heading now happens to hold that position. Confirm the target
section says what the citation claims before writing it.

**The rule is about resolution, not about `§`.** A citation of any kind that
cannot be looked up promises a referent that does not exist. The corpus carries
one other cited id family — `OE-<n>`, the open-ends ids the editor cites from its
own source — and it resolves the same way, against the register in
`tom_specs_editor_specification.md` §22, under the same kind of gate
(`bin/check_oe_citations.dart`).

---

## The object model and how it is generated

The chain runs: Dart classes in `tom_specs_model` → the SOM generator → nine
generated language runtimes and two file formats.

| Document | Authority for |
|----------|---------------|
| [tom_specs_model_rules.md](tom_specs_model_rules.md) | **Authoring a class in `tom_specs_model`.** Object-model layout and member shapes, field classification (§6.1), form decomposition (§6.2), section identity, headlines, the annotation vocabulary, traceability and the structural invariants the validator enforces (§10.2) — and the outliner that renders the result (§11). |
| [som_multiplatform_spec_model.md](som_multiplatform_spec_model.md) | **What the authored model becomes.** The nine-language generation and the `v0` facade / runtime split, the metadata tree, normative md (§11) and yaml (§12) serialization of every construct, schema generation (§13), the embedded validator, the scripting surface (§15) and per-language packaging (§17). |
| [tom_specs_model_meta_schema.md](tom_specs_model_meta_schema.md) | **The on-disk shape of `spec_model.meta.json`** — the lossless resolved class graph the reflection path loads, its two independent version stamps, and the contract `validateSpecModelMeta` enforces. |
| [som_generator_config.md](som_generator_config.md) | **The `tom-spec-object-model` config block** — which languages are generated, where each `tom_som_<slug>_<label>` project lands, the version label, and which document roots are generated. |
| [som_toolchains.md](som_toolchains.md) | **What it takes to build and run the generated artefacts** — the per-language toolchains and versions per fleet host, and the host requirement of the tools that *produce* them: running the analyzer with no installed Dart SDK. |

## CodeSpecs

| Document | Authority for |
|----------|---------------|
| [codespecs_mapping.md](codespecs_mapping.md) | **Everything CodeSpecs *except* what code comes out.** The four pillars and the `tom_core`-family basis (§1.1), the neutral vocabulary (§1.2), the parts catalogue and the three generated projects (§4), the per-part gap analysis and spec-authorable attribute surfaces (§5), the server contract (§7), the SOM→CodeSpecs derivation *map* — the four walk questions, the document map, the CodeSpecs/follow-up split, and (§8.5) the per-part walk index naming where each part's walk enters and where it is stated (§8) — the bidirectional DocSpecs↔CodeSpecs link (§9), the config/settings scope split and the `code_spec` architecture principles (§11–§12). |
| [codespecs_derivation_contract.md](codespecs_derivation_contract.md) | **What code comes out.** The per-`Cs*`-annotation derivation contract: for every active marker, which SOM class and fields feed it, the exact Dart emitted and its `tom_core`-family superclass, how each annotation argument is derived, the deterministic naming rules (N1–N10), the universal comment-derivation rule (§2.8), the locus project, the typed cross-references and the `@CodeSpec`/`@DocSpec` back-links — plus the constructor shape of every marker and the validator checks that enforce them. |
| [codespecs_prompt.md](codespecs_prompt.md) | **How a Phase-4 run starts, and when it refuses to.** The starting prompt, and the quality gate that is its first act: the mechanical tier (§4 — schema completeness *and* the instance-tier validator, routing totality, required-argument sources, carrier presence), the pre-gate extraction run and its walk root (§5), the per-area verdict with its fixed question, three outcomes and gap-naming output shape (§6), and the L0/L1/L2 instantiation that leaves the queue paused by construction (§7). |

## The creation process

| Document | Authority for |
|----------|---------------|
| [tom_specs_project_flow.md](tom_specs_project_flow.md) | **How a system is created with TomSpecs.** The eight phases from project idea to production with their inputs and outputs, the quality-gate framework, the iteration and phase-re-entry rules, the role and decision-authority model, tooling, the issue workflow and upgrade cycles. |

## The applications and their agent

| Document | Authority for |
|----------|---------------|
| [tom_specs_editor_specification.md](tom_specs_editor_specification.md) | **The spec-authoring app** (`tom_forge/tom_specs_editor`) — the three Forge applications, the four-region layout, the document/structure/agent/config modules, the two access layers, canonical paths, schema generation and the undo model. Carries the two referent registers the editor's code and body cite — decisions (§2) and open ends (§22). |
| [tom_specs_reviewer_specification.md](tom_specs_reviewer_specification.md) | **The object-model review app** (`tom_ai/ai_build/tom_specs_reviewer`) — browsing the exported class graph and recording structural observations keyed by structural path. Explicitly not an editor; the two apps share the readers *and* the annotation display semantics, and diverge only in the paint. |
| [llm_and_d4rt_tools.md](llm_and_d4rt_tools.md) | **The `tom_spec_engine` scripting plane** — the D4rt host and its `spec` / `files` / `memory` scopes, the controller-bound editing facade, grep-like search, the audited file facade, the tool surface and the two-tier memory. |
| [llm_guidelines_specification.md](llm_guidelines_specification.md) | **The agent's context prompt** — what the in-editor agent is, and how it authors D4rt scripts that process a TomSpecs document. Its worked examples are executed verbatim by `tom_spec_engine`'s test suite. |

## The packages' own documentation

| Document | Authority for |
|----------|---------------|
| [tom_specs_documentation_standard.md](tom_specs_documentation_standard.md) | **What documentation a TomSpecs package carries and when it is finished.** The two-tier split and the membership test that assigns a fact to a tier, the README template — cross-references blockquote, "Where this fits", the cross-link block — the `doc/` folder standard and its reachability and resolution rules, the nine language planes and hand-written files inside a generated package, the generated API reference and its per-package-kind coverage bars, the treatment of the two Flutter applications, the samples folder, and the acceptance checklist a documentation task is measured against. |

The documents *produced* under that standard are the packages' own
`README.md` files and `doc/` folders. They are not listed here — this catalogue
indexes the subject-matter tier, and a package's documentation is reachable from
its package, which is where its reader already is.

## Authorities outside this folder

Two subjects this folder uses but does not own:

| Where | Authority for |
|-------|---------------|
| [`_ai/quests/doc_specs/doc_specs_specification.md`](../../../../_ai/quests/doc_specs/doc_specs_specification.md) | The DocSpecs format itself — schemas, section types, validation. |
| Per-project `README.md` files and `doc/` folders | Per-project usage: [`tom_specs_core`](../../tom_specs_core/README.md) (the annotation catalogue), [`tom_specs_clitool`](../../tom_specs_clitool/README.md) (CLI usage), `tom_code_specs`, `tom_core_codespecs`, [`tom_som_conformance`](../../tom_som_conformance) (the harness), and the nine `tom_som_*_v0` / `tom_som_*_runtime` pairs. Their shape is decided by [tom_specs_documentation_standard.md](tom_specs_documentation_standard.md); their content is decided by each package. |

## Generated documentation

Generated documents live **outside this folder**, under
`tom_specs_model/generated-doc/<type>/`, so a stray generator run can never
leave a stale copy sitting among the hand-written docs.

| Folder | Contents | Regenerate with |
|--------|----------|-----------------|
| [../generated-doc/outlines/](../generated-doc/outlines/index.md) | One outline per document root (D00–D13) plus the whole-model `DocSpecsProject` outline and a compact `SolutionBlueprint` outline, rendered from the live Dart model | `tom_specs_clitool/tool/regenerate_outlines.sh` |
| `../generated-doc/codespecs/` | `codespecs_areas.json` — the 27-area CodeSpecs catalogue (26 active parts + the CE-EN `domainEnum` extract home) transcribed from `codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6, and the input all nine runtimes' `spec_codespecs_extract` reads | `tom_specs_clitool/bin/codespecs_areas.dart` |

Never edit anything under `generated-doc/` by hand — re-run the generator and
commit the diff.
