# tom_code_specs

The **CodeSpecs framework** for TomSpecs **Phase 4** — the code home for the
`Cs*` **annotation family** and the code-side DocSpecs↔CodeSpecs link annotations.

CodeSpecs turns the Phase 3 specification documents (the DocSpecs, typed by the
**SOM** — `tom_specs_model`) into a **skeletal, compilable Dart application**
whose every element carries traceability annotations back to its source spec.

> **This is a code framework, not a document model** — and (2026-07-19 revision)
> it carries **annotations only, no base classes**. All CodeSpecs annotations use
> the `Cs*` prefix (`@CsForm`, `@CsTable`, `@CsEndpoint`, …); there is **no `Ca*`
> prefix and no `Cs*` base class**. A CodeSpec is built on an existing
> `tom_core`-family class marked by `Cs*` annotations; the concrete classes
> `tom_core` lacks live in `tom_core_codespecs`. The framework is owned by the
> **`tom_specs` quest** (the former `code_spec` quest is retired — see
> `_ai/quests/tom_specs/codespecs_mapping.md` §0/§12).

## What lives here

| Symbol | Role | Reference |
|--------|------|-----------|
| `@DocSpec([DocRef(sectionId, description), …])` | Code → doc back-trace on a CodeSpec class/member | `codespecs_mapping.md` §9.3 |
| `DocRef(sectionId, description)` | One back-trace entry | §9.3 |
| `Cs*` annotation family (no base classes) | The 21-part catalogue's annotations (added in later csm waves) | §4.1 |

## What lives in `tom_specs_core` instead

The **forward**, model-side half of the link annotates the SOM, so it lives with
the other SOM annotations in `tom_specs_core` (which `tom_specs_model` already
depends on — keeping the model → core dependency direction):

- `@CodeSpecKind(List<CodeSpecPart> kinds, {String? note})` — the type-level "this
  section type realises these CodeSpecs kind(s)" link; **list-valued** since a
  section/field may map to several kinds (§9.1).
- `CodeSpecPart` — the enum of the 21-part catalogue's kind vocabulary (§4.1).

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
