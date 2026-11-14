/// Code-side annotations for CodeSpecs (`Cs*`) classes and members.
///
/// A CodeSpec is an ordinary class **built on** an existing `tom_core`-family
/// class and marked by these annotations — the framework carries **annotations
/// only, no base classes** (`codespecs_mapping.md` §1.1 pillar (a)). This
/// barrel exports the
/// identity/trace annotations ([CodeSpec], `@DocSpec`/`DocRef`) and the four
/// part-marker families:
///
/// - `element_annotations.dart` — the client/UI markers.
/// - `service_annotations.dart` — the server-side markers.
/// - `contract_annotations.dart` — the shared markers.
/// - `client_settings_annotations.dart` — the client-application,
///   configuration/settings, identity and authentication group.
///
/// Beside them sit the two markers that are **not** parts, each in a file of
/// its own because it belongs to whichever declaration carries it rather than
/// to a locus or a slice: `cs_collaborator.dart`, whose `@CsCollaborator` marks
/// the abstract collaborator a form-3b body calls
/// (`codespecs_derivation_contract.md` §3.0), and `cs_completion.dart`, whose
/// `@CsCompletion` records a value the authoring agent completed under a rule
/// of the contract's register (`codespecs_derivation_contract.md` §2.10).
///
/// It also exports the two files of annotation *parameter* vocabulary the
/// markers are authored against — neither holds annotations of its own:
///
/// - `cross_part_refs.dart` — the `Cs*Ref` typed cross-part reference family
///   (`codespecs_mapping.md` §5.23), which makes a reference from one part to
///   another a compiler-checked const rather than a string.
/// - `vocabulary.dart` — the closed catalogues a marker's arguments select from
///   (`codespecs_derivation_contract.md` §5.3), enums rather than strings for
///   the same reason: a catalogue grows by a reviewed taxonomy edit, not by a
///   specification inventing a value in passing.
///
/// @docImport 'code_spec.dart';
library;

export 'client_settings_annotations.dart';
export 'code_spec.dart';
export 'contract_annotations.dart';
export 'cross_part_refs.dart';
export 'cs_collaborator.dart';
export 'cs_completion.dart';
export 'doc_spec.dart';
export 'element_annotations.dart';
export 'service_annotations.dart';
export 'vocabulary.dart';
