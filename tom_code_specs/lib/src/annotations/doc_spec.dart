/// The code-side back-trace half of the DocSpecs ↔ CodeSpecs link
/// (`codespecs_mapping.md` §9.3).
///
/// `@DocSpec` is applied to a CodeSpecs `Cs*` class or member to trace it back
/// to the DocSpecs sections that shaped it. It holds a list of [DocRef] tuples —
/// each naming a section (by its SOM `@SectionId`) and describing *what* the
/// code takes from that section and *how* it was influenced.
///
/// This annotation lives in `tom_code_specs` (not `tom_specs_core`) because it
/// annotates CodeSpecs *code*, not the SOM model. Its forward counterparts —
/// the type-level `@CodeSpecKind` and the instance-level `codeSpec` member on
/// `DocSpecsSection` — annotate the model and therefore live in
/// `tom_specs_core`.
///
/// With the SOM `@SectionId` as the shared join key, `@DocSpec` answers the
/// code → doc question ("which spec sections shaped this code, and why"), while
/// `@CodeSpecKind` + `codeSpec` answer doc → code.
///
/// Example:
/// ```dart
/// @CsTable()
/// @DocSpec([
///   DocRef('IMO-014', 'Order entity fields and constraints'),
///   DocRef('RSP-042', 'total must be non-negative'),
/// ])
/// class Order { ... }
/// ```
class DocSpec {
  /// The sections this code element realises, each with a description of the
  /// influence.
  final List<DocRef> refs;

  /// Declares the annotated CodeSpecs class or member as tracing back to
  /// [refs].
  ///
  /// Positional and required: a `@DocSpec` carrying no entry claims a
  /// back-trace it does not have. Each entry is a [DocRef] rather than a bare
  /// section id because the *description* is half the trace — see [DocRef].
  ///
  /// The list is checked twice at generation time
  /// (`codespecs_derivation_contract.md` §6). Check 7 requires the section ids
  /// named here to equal the `@CodeSpec` source set of the emission unit this
  /// declaration belongs to. Check 36 requires every token named here to exist
  /// in the run's extracts — a trace to a section no area routed is stale or
  /// invented, and is the one defect a reading of the generated code alone can
  /// never expose.
  const DocSpec(this.refs);
}

/// A single (sectionId, description) back-trace entry held by [DocSpec].
///
/// [sectionId] is the SOM `@SectionId` of the originating DocSpecs section;
/// [description] explains what the code element takes from that section and how
/// it is influenced by it.
class DocRef {
  /// The SOM `@SectionId` of the originating section.
  final String sectionId;

  /// What the code takes from the section, and how it is influenced.
  final String description;

  /// Declares one back-trace entry: [sectionId] shaped this code, in the way
  /// [description] states.
  ///
  /// Both are positional and required. [sectionId] is the SOM `@SectionId`
  /// **verbatim** — it is the join key on which the doc → code and code → doc
  /// directions meet, so a re-cased or abbreviated id resolves to nothing and
  /// fails `codespecs_derivation_contract.md` §6 check 36.
  ///
  /// [description] is the one string in this package the authoring agent
  /// *composes* rather than copies: it says what the declaration takes from the
  /// section and how it was influenced. The section's own title repeated back
  /// is not a trace; "total must be non-negative" is.
  const DocRef(this.sectionId, this.description);
}
