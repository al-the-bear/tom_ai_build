# tom_code_specs — documentation

The package documentation for `tom_code_specs`: how to use this package's code.
The CodeSpecs methodology — which specification section feeds which part, what
code comes out, and when a Phase-4 run may begin — is the **subject-matter
tier**, catalogued by
[`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md); documents
here cite it rather than restating it
([`tom_specs_documentation_standard.md`](../../tom_specs_model/doc/tom_specs_documentation_standard.md)
§1.2).

## Guides

| Document | Covers |
|----------|--------|
| [marking_code.md](marking_code.md) | Applying the markers: `@CodeSpec` identity and forward trace, the 39 part markers, `@CsCollaborator`, the note-only / argument-carrying split, the two facet value classes, and placing a marker in the generated trio |
| [cross_references.md](cross_references.md) | The 13 typed `Cs*Ref` consts, declaring an identity once, the qualifiable `CsElementRef`, what is deliberately not a ref, and the `@DocSpec` / `DocRef` back-links |
| [vocabulary.md](vocabulary.md) | The 16 closed catalogues, why they are enums declared locally, the per-kind slot rule a `const` cannot enforce, and the three settings-scope catalogues |

## API reference

| Document | Covers |
|----------|--------|
| [api/api_summary_index.md](api/api_summary_index.md) | The index of the per-module API summaries |
| [api/api_summary_annotations.md](api/api_summary_annotations.md) | Every marker, its constructor and its properties |
| [api/api_summary_cross_part_refs.md](api/api_summary_cross_part_refs.md) | Every reference type, its locus and its members |
| [api/api_summary_vocabulary.md](api/api_summary_vocabulary.md) | Every catalogue, every value, and what selects it |

## Where to start

- **Authoring CodeSpecs code?** [marking_code.md](marking_code.md) first — it
  covers the three annotations every emission unit carries.
- **Wiring one part to another?** [cross_references.md](cross_references.md).
  The short version: never write a reference id as a string.
- **Choosing a marker argument?** [vocabulary.md](vocabulary.md) lists what each
  catalogue offers and which slots a head value permits.
- **Wondering why something compiles but fails later?** See
  [vocabulary.md § Per-kind slots](vocabulary.md#per-kind-slots-and-the-exclusivity-rule)
  — Dart does not const-evaluate an annotation, so slot exclusivity is a
  generation-time check.

## Beyond this package

| Where | What it decides |
|-------|-----------------|
| [`codespecs_mapping.md`](../../tom_specs_model/doc/codespecs_mapping.md) | Which specification section feeds which part — the catalogue, the attribute surfaces, the generation slices, the trio |
| [`codespecs_derivation_contract.md`](../../tom_specs_model/doc/codespecs_derivation_contract.md) | What code comes out per marker — emitted Dart, superclass, naming rules, stub bodies, validator checks |
| [`codespecs_prompt.md`](../../tom_specs_model/doc/codespecs_prompt.md) | When a Phase-4 run may begin at all — the mechanical gate and the per-area judgment |
| [`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md) | The catalogue of the whole subject-matter tier, and the `§` citation convention |
