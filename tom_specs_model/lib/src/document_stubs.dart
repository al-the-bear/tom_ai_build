/// Phase 3 DocSpec root-class re-exports.
///
/// This file bridges the annotation-time Type references on PD00 classes
/// (`@DetailedIn(<DocName>)` / `@MapsTo(<DocName>)` /
/// `@SecondLevelSectionId(<DocName>, ...)`) to the actual target-doc root
/// classes. All 12 Phase 3 document roots now live in their own folders
/// under `lib/src/<code>_<name>/`; this file re-exports them so PD00
/// source files can resolve the Type references via a single import
/// (`import '../document_stubs.dart';`).
///
/// History: during Phase A the file held empty placeholder classes so
/// that PD00 annotations could compile before the real document roots
/// existed. Phase B (Steps 8–19, see `doc/second_wave_documents.md` §11)
/// replaced each stub with the re-export below.
library;

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

// Step 16 — TR (Technical Requirements).
export 'tr_technical_requirements/tr_technical_requirements.dart';

// Step 17 — UP (UI Prototype).
export 'up_ui_prototype/up_ui_prototype.dart';

// Step 18 — SR (System Rollout).
export 'sr_system_rollout/sr_system_rollout.dart';

// Step 19 — BQP (Business Quality Plan).
export 'bqp_business_quality_plan/bqp_business_quality_plan.dart';
