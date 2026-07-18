/// CodeSpecs framework for TomSpecs Phase 4.
///
/// This is the code home for CodeSpecs — the `Cs*` base classes, the `Ca*`
/// annotations, and the code-side DocSpecs↔CodeSpecs link annotations
/// (`@DocSpec`/`DocRef`, §9.3). It is a **code framework, not a document
/// model**: the former `tom_code_specs` package that modelled Phase 4 as a
/// DocSpec was deleted (see `codespecs_mapping.md` §1). The `Cs*`/`Ca*`
/// framework itself is owned by the `code_spec` quest; this package is where
/// that framework plus the TomSpecs link annotations physically live.
///
/// The *type-level* forward link (`@CodeSpecKind`) and the shared kind
/// vocabulary (`CodeSpecPart`) annotate the SOM model and therefore live in
/// `tom_specs_core`; they are re-exported here for convenience so CodeSpecs
/// authors have one import.
library;

export 'package:tom_specs_core/tom_specs_core.dart'
    show CodeSpecKind, CodeSpecPart;

export 'src/annotations/annotations.dart';
