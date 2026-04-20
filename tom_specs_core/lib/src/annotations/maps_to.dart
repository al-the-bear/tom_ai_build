/// Marks a PD00 section class as the 1:1 mapping point to the named
/// Phase 3 DocSpec document.
///
/// Applied to the shallowest PD00 class whose entire subtree flows to a
/// single target DocSpec. It is the "seed node" for the target document —
/// everything beneath this class belongs to that document and nothing
/// else.
///
/// A class can carry both `@MapsTo` and `@DetailedIn` when the seed node
/// is kept whole in the target document (it is both the 1:1 mapping point
/// and the top-level entry in the target).
///
/// See `tom_specs_model/doc/second_wave_documents.md` for the full rule set.
///
/// Example:
/// ```dart
/// @MapsTo(BusinessDataModel)
/// class BusinessObjectAndDataModel { ... }
/// ```
/// declares that the entire PD00-BUS subtree is the source for the BDM document.
class MapsTo {
  /// The Phase 3 DocSpec document class that this section maps to.
  final Type documentClass;

  const MapsTo(this.documentClass);
}
