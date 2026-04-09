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
