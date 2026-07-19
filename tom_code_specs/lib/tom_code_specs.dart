/// CodeSpecs framework for TomSpecs Phase 4.
///
/// This is the code home for CodeSpecs — the `Cs*` **annotation family** and the
/// code-side DocSpecs↔CodeSpecs link annotations (`@CodeSpec`, `@DocSpec` /
/// `DocRef`, §9.3). It is a **code framework, not a document model**: the former
/// `tom_code_specs` package that modelled Phase 4 as a DocSpec was deleted (see
/// `codespecs_mapping.md` §0/§1).
///
/// The framework carries **annotations only — no base classes and no `Ca*`
/// prefix** (2026-07-19 revision, `codespecs_mapping.md` §0). A CodeSpec is an
/// ordinary class **built on** an existing `tom_core`-family class
/// (`tom_core_kernel` / `_flutter` / `_server` / `_d4rt` / `tom_flutter_ui`) and
/// *marked* by these `Cs*` annotations ([CsForm], [CsTable], [CsEndpoint], …)
/// together with the identity/trace annotations [CodeSpec] and `@DocSpec`. The
/// framework is owned by the `tom_specs` quest (the former `code_spec` quest is
/// retired).
///
/// The *type-level* forward link (`@CodeSpecKind`) and the shared kind
/// vocabulary (`CodeSpecPart`) annotate the SOM model and therefore live in
/// `tom_specs_core`; they are re-exported here for convenience so CodeSpecs
/// authors have one import.
library;

export 'package:tom_specs_core/tom_specs_core.dart'
    show CodeSpecKind, CodeSpecPart;

export 'src/annotations/annotations.dart';
