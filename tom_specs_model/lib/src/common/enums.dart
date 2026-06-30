/// Enums shared across TomSpecs document models.
library;


/// Section type in DocSpecs annotations.
enum SectionType { description, form, code }

/// Priority level for requirements.
enum Priority { must, should, could, wontThisTime }

/// Status of a requirement or deliverable.
enum Status { draft, proposed, approved, implemented, verified, deferred, rejected }

/// Probability level for risks.
enum Probability { veryLow, low, medium, high, veryHigh }

/// Impact level for risks.
enum Impact { negligible, minor, moderate, major, critical }

/// The eight ISO/IEC 25010:2023 product-quality characteristics.
///
/// The closed vocabulary for the [Iso25010Coverage] cross-map. The 2023
/// edition renamed *usability* → interaction capability and folded
/// *portability* into the new *flexibility* characteristic, and split
/// *compatibility* out as a first-class characteristic — this enum carries the
/// 2023 spine, matching the eight `*Characteristic` classes under
/// `SystemQualityGoals`.
enum Iso25010Characteristic {
  functionalSuitability,
  performanceEfficiency,
  compatibility,
  interactionCapability,
  reliability,
  security,
  maintainability,
  flexibility,
}
