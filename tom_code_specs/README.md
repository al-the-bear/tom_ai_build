# tom_code_specs

The **CodeSpecs framework** for TomSpecs **Phase 4** — the code home for the
`Cs*` base classes, the `Ca*` annotations, and the code-side DocSpecs↔CodeSpecs
link annotations.

CodeSpecs turns the Phase 3 specification documents (the DocSpecs, typed by the
**SOM** — `tom_specs_model`) into a **skeletal, compilable Dart application**
whose every element carries traceability annotations back to its source spec.

> **This is a code framework, not a document model.** The former
> `tom_code_specs` package that modelled Phase 4 as a DocSpec was deleted (see
> `_ai/quests/tom_specs/codespecs_mapping.md` §1). The `Cs*`/`Ca*` framework
> itself is owned by the `code_spec` quest; this package is where that framework
> plus the TomSpecs link annotations physically live.

## What lives here

| Symbol | Role | Reference |
|--------|------|-----------|
| `@DocSpec([DocRef(sectionId, description), …])` | Code → doc back-trace on a `Cs*` class/member | `codespecs_mapping.md` §9.3 |
| `DocRef(sectionId, description)` | One back-trace entry | §9.3 |
| `Cs*` bases / `Ca*` annotations | The finalized parts catalogue (added in later csm waves) | §4.1 |

## What lives in `tom_specs_core` instead

The **forward**, model-side half of the link annotates the SOM, so it lives with
the other SOM annotations in `tom_specs_core` (which `tom_specs_model` already
depends on — keeping the model → core dependency direction):

- `@CodeSpecKind(CodeSpecPart.x, {String? note})` — the type-level "this section
  type realises this CodeSpecs kind" link (§9.1).
- `CodeSpecPart` — the enum of the 17-part catalogue's kind vocabulary (§4.1).

Both are re-exported from `package:tom_code_specs/tom_code_specs.dart` so a
CodeSpecs author has a single import.

## The concrete instance-level link

The concrete forward link — the `codeSpec` `List<String>` member on
`DocSpecsSection`, serialized comma-separated inside the `sectionId` HTML comment
(§9.2) — is a **model member**, not an annotation, so it lives in
`tom_specs_model` / `tom_specs_core`. It is wired separately.

## Status

Scaffold (csm3). `@DocSpec`/`DocRef` are declared; the `Cs*`/`Ca*` bases follow
in later CodeSpecs waves.
