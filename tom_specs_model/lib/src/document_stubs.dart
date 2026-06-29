/// Phase 3 DocSpec root-class re-exports.
///
/// This file bridges the annotation-time Type references on SBP classes
/// (`@DetailedIn(<DocName>)` / `@MapsTo(<DocName>)` /
/// `@SecondLevelSectionId(<DocName>, ...)`) to the actual target-doc root
/// classes. All 12 Phase 3 document roots now live in their own folders
/// under `lib/src/<document_name>/`; this file re-exports them so SBP
/// source files can resolve the Type references via a single import
/// (`import '../document_stubs.dart';`).
///
/// History: during Phase A the file held empty placeholder classes so
/// that SBP annotations could compile before the real document roots
/// existed. Phase B (Steps 8–19, see `doc/second_wave_documents.md` §11)
/// replaced each stub with the re-export below.
library;

// Step 8 — BSI (Business System Interactions).
export 'integration_interface_specification/integration_interface_specification.dart';

// Step 9 — CS (Current Situation).
export 'current_landscape_assessment/current_landscape_assessment.dart';

// Step 10 — RC (Requirements Catalog).
export 'requirements_specification/requirements_specification.dart';

// Step 11 — BP (Business Processes).
export 'target_operating_model/target_operating_model.dart';

// Step 12 — UC (Use Cases).
export 'interaction_scenarios/interaction_scenarios.dart';

// Step 13 — BDM (Business Data Model).
export 'information_model/information_model.dart';

// Step 14 — AC (Authorization Concept).
export 'security_access_specification/security_access_specification.dart';

// Step 15 — PPP (Project Phase Plan).
export 'delivery_roadmap/delivery_roadmap.dart';

// Step 16 — TR (Technical Requirements).
export 'architecture_technology_specification/architecture_technology_specification.dart';

// Step 17 — UP (UI Prototype).
export 'experience_design_specification/experience_design_specification.dart';

// Step 18 — SR (System Rollout).
export 'transition_rollout_plan/transition_rollout_plan.dart';

// Step 19 — BQP (Business Quality Plan).
export 'quality_acceptance_plan/quality_acceptance_plan.dart';
