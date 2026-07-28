/// Marks a `@Document` root as the **CodeSpecs generation projection**.
///
/// A CodeSpecs projection is a `@Document(basedOn: [D00SolutionBlueprint])`
/// view that reaches only the isolated CodeSpecs subtrees — the concrete input
/// the Phase-4 CodeSpecs generator consumes. Unlike the D01–D12 Phase-3
/// projections, it is **`@CodeSpecKind`-driven, not `@DetailedIn`-driven**: no
/// section in the SBP tree carries `@DetailedIn(<this projection>)`, because the
/// `@DetailedIn`/`@MapsTo` pair is single-valued and already spent on the
/// Phase-3 document that shaped each section.
///
/// This marker exempts the projection from the `tom_specs_model_rules.md` §10.2 detail-count check (which
/// would otherwise warn that the `@Document` has zero `@DetailedIn` entries).
/// It does **not** relax the pure-projection invariant — the projection must
/// still reach only types present in the D00SolutionBlueprint tree.
///
/// Example:
/// ```dart
/// @Document(
///   name: 'CodeSpecs Generation Projection',
///   description: '...',
///   basedOn: [D00SolutionBlueprint],
/// )
/// @CodeSpecsProjection()
/// @SectionId('CGP')
/// class D13CodeSpecsProjection extends DocSpecsSection { ... }
/// ```
class CodeSpecsProjection {
  const CodeSpecsProjection();
}
