/// Code-side annotations for CodeSpecs (`Cs*`) classes and members.
///
/// A CodeSpec is an ordinary class **built on** an existing `tom_core`-family
/// class and marked by these annotations — the framework carries **annotations
/// only, no base classes** (`codespecs_mapping.md` §0). This barrel exports the
/// identity/trace annotations ([CodeSpec], `@DocSpec`/`DocRef`) and the three
/// part-marker families (client/UI, server, shared).
library;

export 'code_spec.dart';
export 'contract_annotations.dart';
export 'doc_spec.dart';
export 'element_annotations.dart';
export 'service_annotations.dart';
