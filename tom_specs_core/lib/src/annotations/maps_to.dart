/// Marks a Solution Blueprint section class as the 1:1 mapping point to the
/// named Phase 3 DocSpec document.
///
/// Applied to the shallowest Solution Blueprint class whose entire subtree
/// flows to a single target DocSpec. It is the "seed node" for the target
/// document — everything beneath this class belongs to that document and
/// nothing else.
///
/// A class can carry both `@MapsTo` and `@DetailedIn` when the seed node
/// is kept whole in the target document (it is both the 1:1 mapping point
/// and the top-level entry in the target).
///
/// The `tom_specs_model_rules.md` §10.2 structural invariants in
/// `tom_specs_clitool/lib/src/validator.dart` enforce the full rule set.
///
/// Example:
/// ```dart
/// @MapsTo(D03InformationModel)
/// class InformationAndDataModel { ... }
/// ```
/// declares that the entire INDM subtree is the source for the IFM document.
class MapsTo {
  /// The Phase 3 DocSpec document class that this section maps to.
  final Type documentClass;

  /// Declares the annotated class as the seed node for [documentClass].
  const MapsTo(this.documentClass);
}
