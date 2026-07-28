/// Code-side annotations for CodeSpecs (`Cs*`) classes and members.
///
/// A CodeSpec is an ordinary class **built on** an existing `tom_core`-family
/// class and marked by these annotations — the framework carries **annotations
/// only, no base classes** (`codespecs_mapping.md` §0). This barrel exports the
/// identity/trace annotations ([CodeSpec], `@DocSpec`/`DocRef`) and the four
/// part-marker families:
///
/// - `element_annotations.dart` — the client/UI markers.
/// - `service_annotations.dart` — the server-side markers.
/// - `contract_annotations.dart` — the shared markers.
/// - `client_settings_annotations.dart` — the client-application,
///   configuration/settings, identity and authentication group.
library;

export 'client_settings_annotations.dart';
export 'code_spec.dart';
export 'contract_annotations.dart';
export 'doc_spec.dart';
export 'element_annotations.dart';
export 'service_annotations.dart';
