/// Enums shared across TomSpecs document models.
library;

/// Requirement priority (MoSCoW).
enum Priority { must, should, could, wont }

/// Document or entry lifecycle status.
enum Status { draft, review, approved, implemented, deprecated }

/// Risk probability.
enum Probability { low, medium, high }

/// Risk or change impact.
enum Impact { low, medium, high, critical }

/// Data sensitivity classification.
enum DataClassification { public, internal, confidential, restricted }

/// Data category by usage pattern.
enum DataCategory {
  masterData,
  transactionData,
  referenceData,
  configurationData,
  auditData,
}

/// System replacement strategy.
enum ReplacementStrategy { replace, migrate, decommission, retain }

/// Actor type in process interactions.
enum ActorType { humanUser, externalSystem, timer, internalService }

/// User technical proficiency level.
enum TechnicalProficiency { beginner, intermediate, advanced, expert }

/// Access channel for system interaction.
enum AccessChannel { web, mobile, api, cli, desktop }

/// Prototype reuse strategy.
enum PrototypeType { reusable, training, throwaway }

/// Staging approach for system rollout.
enum StagingApproach {
  bigBang,
  phasedByFunction,
  phasedByGeography,
  phasedByUserGroup,
}

/// Interface data direction.
enum InterfaceDirection { inbound, outbound, bidirectional }

/// Component category.
enum ComponentCategory { openSource, commercial, inHouse, cloudService }

/// MoSCoW feature classification (same values as Priority but used in
/// feature prioritization context).
enum MoscowCategory { must, should, could, wont }

/// Section type in DocSpecs annotations.
enum SectionType { description, form, code }

/// Meeting attendance requirement.
enum AttendanceRequirement { mandatory, optional, onDemand }
