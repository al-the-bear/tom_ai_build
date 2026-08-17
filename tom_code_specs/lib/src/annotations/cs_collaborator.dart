/// The one `Cs*` marker that is **not a part**: `@CsCollaborator`.
///
/// Every other marker in this package realises a section of the specification
/// model as code. This one marks the **abstract collaborator** a form-3b
/// pseudo-implementation calls — the class whose methods a Phase-6 author
/// implements (`codespecs_derivation_contract.md` §2.4, §3.0.1). It therefore
/// has no `CE-*` code, no `CodeSpecPart` value and no row in the parts
/// catalogue: a part is what a SOM section is realised *as*, a collaborator is
/// what a realisation's body needs in order to compile.
///
/// It lives in a file of its own for the same reason it has no slice
/// (`codespecs_derivation_contract.md` §3.0): the other four marker files are
/// grouped by locus and concern, and a collaborator belongs to whichever
/// declaration emitted it — client or server, in any slice.
library;

/// The abstract collaborator a form-3b body calls
/// (`codespecs_derivation_contract.md` §3.0.1).
///
/// Marks an `abstract class` the generator emits **beside** the declaration
/// whose bodies call it, in the same emission unit and immediately before it, so
/// there is no forward reference. It holds one abstract method per contributing
/// step of that declaration's step list and nothing else — no field, no
/// constructor, no static, no implemented member — and each method carries on
/// its doc comment the behaviour the step states
/// (`codespecs_derivation_contract.md` §2.8 P3, fatal when absent).
/// The calling declaration reaches it through one field:
///
/// ```dart
/// late final CustomerActionControllerCollaborator collaborator;
/// ```
///
/// **Note-only**, and for the strongest of the
/// `codespecs_derivation_contract.md` §2.3 reasons: the method set *is*
/// the declaration (test **a**), and there is no substrate for test **b** to
/// reach — a collaborator is one of only two declarations in the contract built
/// on nothing, `@CsEnum` being the other. It is emitted as a marker all the same,
/// because `codespecs_derivation_contract.md` §2.7 point 4 requires a `Cs*`
/// marker on every generated top-level declaration and because the
/// `codespecs_derivation_contract.md` §6 checks have to *find* collaborators,
/// which a name suffix would turn into load-bearing convention.
class CsCollaborator {
  /// Optional note.
  final String? note;

  const CsCollaborator({this.note});
}
