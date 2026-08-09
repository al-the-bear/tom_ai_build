/// Marks a Solution Blueprint section class as one whose content is taken
/// over as a top-level entry in the named Phase 3 DocSpec document.
///
/// The "take-off" level is the class that is promoted to a top-level entry
/// of the target DocSpec. Two shapes are valid:
///
/// - **Whole seed promoted.** When the full seed subtree is kept as one
///   top-level entry in the target document, the seed class itself carries
///   `@DetailedIn` (alongside `@MapsTo`).
/// - **Seed flattened one level.** When the seed's direct children are
///   promoted to individual top-level entries — because the target document
///   reads better with them as peers than nested beneath one heading — each
///   child carries `@DetailedIn`; the seed keeps `@MapsTo`.
///
/// The `tom_specs_model_rules.md` §10.2 structural invariants in
/// `tom_specs_clitool/lib/src/validator.dart` enforce the full rule set.
///
/// Example:
/// ```dart
/// @DetailedIn(D06ArchitectureTechnologySpecification)
/// class BasicTechnicalRequirements { ... }
/// ```
class DetailedIn {
  /// The Phase 3 DocSpec document class that details this section.
  final Type documentClass;

  const DetailedIn(this.documentClass);
}
