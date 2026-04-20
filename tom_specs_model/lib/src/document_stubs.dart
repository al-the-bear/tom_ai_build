/// Phase 3 DocSpec root-class stubs and re-exports.
///
/// This file bridges the annotation-time Type references on PD00 classes
/// (`@DetailedIn(<DocName>)` / `@MapsTo(<DocName>)` / `@SecondLevelSectionId(<DocName>, ...)`)
/// to the actual target-doc root classes.
///
/// As each Phase 3 document root class is created (Phase B Steps 8–19,
/// §9 of `doc/second_wave_documents.md`), the matching stub here is
/// replaced with an `export` pointing at the real class in its own
/// folder under `lib/src/<code>_<name>/`. Classes still listed as stubs
/// below are placeholders until their Phase B step runs.
library;

// ---------------------------------------------------------------------------
// Document roots implemented in Phase B — re-exports from their folders.
// ---------------------------------------------------------------------------

// Step 8 — BSI (Business System Interactions).
export 'bsi_business_system_interactions/bsi_business_system_interactions.dart';

// Step 9 — CS (Current Situation).
export 'cs_current_situation/cs_current_situation.dart';

// Step 10 — RC (Requirements Catalog).
export 'rc_requirements_catalog/rc_requirements_catalog.dart';

// Step 11 — BP (Business Processes).
export 'bp_business_processes/bp_business_processes.dart';

// Step 12 — UC (Use Cases).
export 'uc_use_cases/uc_use_cases.dart';

// Step 13 — BDM (Business Data Model).
export 'bdm_business_data_model/bdm_business_data_model.dart';

// Step 14 — AC (Authorization Concept).
export 'ac_authorization_concept/ac_authorization_concept.dart';

// Step 15 — PPP (Project Phase Plan).
export 'ppp_project_phase_plan/ppp_project_phase_plan.dart';

// ---------------------------------------------------------------------------
// Remaining stubs (replaced as their Phase B step runs).
// ---------------------------------------------------------------------------

/// Stub for TR (Technical Requirements). Phase B Step 16.
/// Distinct from PD00-SYO-REQ-TEC class `TechnicalRequirements`.
class TechnicalRequirementsSpec {}

/// Stub for UP (UI Prototype). Phase B Step 17.
class UiPrototype {}

/// Stub for SR (System Rollout). Phase B Step 18.
/// Distinct from PD00-ROL class `SystemRolloutConcept`.
class SystemRollout {}

/// Stub for BQP (Business Quality Plan). Phase B Step 19.
class BusinessQualityPlan {}
