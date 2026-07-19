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

  const DocRef(this.sectionId, this.description);
}
