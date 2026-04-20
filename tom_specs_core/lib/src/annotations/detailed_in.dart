/// Marks a PD00 section class as one whose content is taken over as a
/// top-level entry in the named Phase 3 DocSpec document.
///
/// The "take-off" level is the class that is promoted to a top-level entry
/// of the target DocSpec. Two shapes are valid:
///
/// - **Whole seed promoted.** When the full seed subtree is kept as one
///   top-level entry in the target document, the seed class itself carries
///   `@DetailedIn` (alongside `@MapsTo`).
/// - **Seed flattened one level.** When the seed's direct children are
///   promoted to individual top-level entries (to fit the target's 7–15
///   section budget), each child carries `@DetailedIn`; the seed keeps
///   `@MapsTo`.
///
/// See `tom_specs_model/doc/second_wave_documents.md` for the full rule set.
///
/// Example:
/// ```dart
/// @DetailedIn(TechnicalRequirements)
/// class BasicTechnicalRequirements { ... }
/// ```
class DetailedIn {
  /// The Phase 3 DocSpec document class that details this section.
  final Type documentClass;

  const DetailedIn(this.documentClass);
}
