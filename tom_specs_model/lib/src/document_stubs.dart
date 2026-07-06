/// Phase 3 DocSpec root-class re-exports.
///
/// This file bridges the annotation-time Type references on SBP classes
/// (`@DetailedIn(<DocName>)` / `@MapsTo(<DocName>)` /
/// `@SecondLevelSectionId(<DocName>, ...)`) to the actual target-doc root
/// classes. All 12 Phase 3 document roots live in their own folders
/// under `lib/src/<document_name>/`; this file re-exports them so SBP
/// source files can resolve the Type references via a single import
/// (`import '../document_stubs.dart';`).
library;

// D07 — Integration & Interface Specification.
export 'integration_interface_specification/integration_interface_specification.dart';

// D01 — Current Landscape Assessment.
export 'current_landscape_assessment/current_landscape_assessment.dart';

// D04 — Requirements Specification.
export 'requirements_specification/requirements_specification.dart';

// D02 — Target Operating Model.
export 'target_operating_model/target_operating_model.dart';

// D05 — Interaction Scenarios.
export 'interaction_scenarios/interaction_scenarios.dart';

// D03 — Information Model.
export 'information_model/information_model.dart';

// D08 — Security & Access Specification.
export 'security_access_specification/security_access_specification.dart';

// D11 — Delivery Roadmap.
export 'delivery_roadmap/delivery_roadmap.dart';

// D06 — Architecture & Technology Specification.
export 'architecture_technology_specification/architecture_technology_specification.dart';

// D09 — Experience Design Specification.
export 'experience_design_specification/experience_design_specification.dart';

// D12 — Transition & Rollout Plan.
export 'transition_rollout_plan/transition_rollout_plan.dart';

// D10 — Quality & Acceptance Plan.
export 'quality_acceptance_plan/quality_acceptance_plan.dart';
