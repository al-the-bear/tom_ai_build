/// Phase 3 DocSpec root-class stubs.
///
/// Placeholder empty classes defined early so that `@DetailedIn(<DocName>)`
/// and `@MapsTo(<DocName>)` type references on PD00 classes compile during
/// Phase A of the second-wave implementation plan (see
/// `doc/second_wave_documents.md` §11, Phase A).
///
/// Phase B (Steps 8–19) replaces each stub with the full document root
/// class in its own folder under `lib/src/<code>_<name>/`.
library;

/// Stub for CS (Current Situation). Phase B adds fields per §5.1.
class CurrentSituation {}

/// Stub for RC (Requirements Catalog). Phase B adds fields per §5.2.
class RequirementsCatalog {}

/// Stub for BP (Business Processes). Phase B adds fields per §5.3.
class BusinessProcesses {}

/// Stub for UC (Use Cases). Phase B adds fields per §5.4.
class UseCases {}

/// Stub for BDM (Business Data Model). Phase B adds fields per §5.5.
class BusinessDataModel {}

/// Stub for AC (Authorization Concept). Phase B adds fields per §5.6.
class AuthorizationConcept {}

/// Stub for TR (Technical Requirements). Phase B adds fields per §5.7.
/// Distinct from PD00-SYO-REQ-TEC class `TechnicalRequirements`.
class TechnicalRequirementsSpec {}

/// Stub for UP (UI Prototype). Phase B adds fields per §5.8.
class UiPrototype {}

/// Stub for SR (System Rollout). Phase B adds fields per §5.9.
/// Distinct from PD00-ROL class `SystemRolloutConcept`.
class SystemRollout {}

/// Stub for BQP (Business Quality Plan). Phase B adds fields per §5.10.
class BusinessQualityPlan {}

/// Stub for PPP (Project Phase Plan). Phase B adds fields per §5.11.
class ProjectPhasePlan {}

/// Stub for BSI (Business System Interactions). Phase B adds fields per §5.12.
class BusinessSystemInteractions {}
