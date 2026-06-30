/// Section 15: System Rollout Concept.
///
/// Rollout-related planning that seeds the TRP (Transition & Rollout Plan)
/// Phase 3 DocSpec. Covers rollout plan, migration, user documentation,
/// training, pilot, cutover, knowledge transfer, and warranty.
///
/// This class is named `SystemRollout` so the `…Concept` suffix
/// matches the convention used by `TechnicalFrameworkConcept` and
/// `SecurityAndAccessModel`. The clean name `D12TransitionRolloutPlan` is
/// reserved for the TRP target-doc class.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 15. System Rollout Concept. Seeds → TRP.
@SectionId('ROLC')
@Comment('Seeds → TRP')
@MapsTo(D12TransitionRolloutPlan)
class SystemRollout {
  @ContentHelp('''
Executive summary of the rollout approach: from pilot through phased
rollout, migration, user enablement, cutover, knowledge transfer, and
post-go-live support. Seeds the TRP document (Phase 3) together with the
localization, translation, and documentation subtrees.
''')
  String? content;

  /// 15.1. Rollout Plan.
  RolloutPlan rolloutPlan = RolloutPlan();

  /// 15.2. Migration Plan.
  MigrationPlan migrationPlan = MigrationPlan();

  /// 15.3. User Manuals.
  ///
  /// One whole-catalog content section (mirrors the `rolloutPlan` /
  /// `migrationPlan` / `pilotPlan` siblings); collapsed from
  /// `List<UserManual>` (L34C-12 SR-57).
  UserManual userManuals = UserManual();

  /// 15.4. Training Materials.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<RolloutTrainingMaterial>` (L34C-12 SR-57).
  RolloutTrainingMaterial trainingMaterials = RolloutTrainingMaterial();

  /// 15.5. Pilot Plan.
  PilotPlan pilotPlan = PilotPlan();

  /// 15.6. Cutover Procedures.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<CutoverProcedure>` (L34C-12 SR-57).
  CutoverProcedure cutoverProcedures = CutoverProcedure();

  /// 15.7. Knowledge Transfer.
  KnowledgeTransfer knowledgeTransfer = KnowledgeTransfer();

  /// 15.8. Warranty and Support.
  WarrantyAndSupport warrantyAndSupport = WarrantyAndSupport();
}

// ---------------------------------------------------------------------------
// 15.1 Rollout Plan
// ---------------------------------------------------------------------------

/// 15.1. Rollout Plan.
///
/// Geographic and/or user-group rollout plan covering rollout-plan
/// content: the sequencing of sites, countries, business units, and user
/// cohorts across the go-live waves.
@SectionId('RLTPLN')
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-PLN')
class RolloutPlan {
  @ContentHelp('''
Rollout plan: sequencing, waves, and criteria for moving each cohort from
pre-go-live to production.

**What to capture:**
- Rollout strategy (big-bang / phased / pilot-first / hybrid)
- Wave definitions (who goes when, success criteria to advance a wave)
- Entry and exit criteria per wave
- Rollback decision authority and triggers
- Communication plan per wave
- Dependencies between waves (data migration, integration readiness)
''')
  String? content;
}

// ---------------------------------------------------------------------------
// 15.2 Migration Plan
// ---------------------------------------------------------------------------

/// 15.2. Migration Plan.
///
/// End-to-end system migration plan covering migration-plan content:
/// data, configuration, integration, and user migration from the current
/// landscape to the target.
///
/// This is the rollout/cutover *runbook* (execution). The staged-migration
/// *strategy* (phasing, sequencing, data-migration approach) is owned by
/// `DataMigrationStrategy` (`DRM`); reference it rather than restating the
/// strategy here.
@SectionId('MIGPLN')
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-MIG')
class MigrationPlan {
  @ContentHelp('''
System migration plan distinct from the per-data-entity migration
mapping. Focuses on the execution plan.

**What to capture:**
- Migration scope (systems, data domains, users, integrations)
- Migration approach (big-bang / trickle / parallel run)
- Data extract / transform / load windows
- Validation rules and reconciliation approach
- Dress-rehearsal schedule and acceptance criteria
- Fallback / rollback procedure and triggers
- Roles and responsibilities during migration
''')
  String? content;
}

// ---------------------------------------------------------------------------
// 15.3 User Manuals
// ---------------------------------------------------------------------------

/// 15.3. User Manuals.
///
/// End-user documentation deliverables covering user-manual content.
///
/// This is the *execution* side of user documentation. The documentation
/// *requirements* (deliverables, formats, platforms, versioning,
/// localization) are owned by SBP.9 `InformationForUseRequirements`
/// (`IFUR`); reference them via the shared `TRP-DOC` detail link rather
/// than restating the requirements here.
@SectionId('USRMAN')
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-DOC')
class UserManual {
  @ContentHelp('''
User manual deliverables: what documents are produced, for which user
categories, in which languages, on what delivery channel (in-app help,
PDF, wiki, print). Not the in-app contextual help itself (that lives in
the help-concept section).

**What to capture:**
- Document catalog (title, audience, scope, format)
- Production workflow and ownership
- Localization / translation path
- Review and approval process
- Distribution channels
- Versioning and maintenance approach post-go-live
''')
  String? content;
}

// ---------------------------------------------------------------------------
// 15.4 Training Materials
// ---------------------------------------------------------------------------

/// 15.4. Training Materials.
///
/// Training deliverables covering training-material content.
///
/// This is the *execution* side of training. The training *requirements*
/// (audiences, competency outcomes, certification, ongoing enablement) are
/// owned by SBP.9 `TrainingEnablementRequirements` (`TREQ`); reference them
/// via the shared `TRP-TRN` detail link rather than restating the
/// requirements here.
@SectionId('RLTTM')
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-TRN')
class RolloutTrainingMaterial {
  @ContentHelp('''
Training plan and materials: courses, content packages, trainers, and
delivery mechanism. Complements the training-module catalogue which
captures the catalog of training modules.

**What to capture:**
- Training catalog per user category (course names, duration, format)
- Delivery mechanism (instructor-led, e-learning, blended)
- Train-the-trainer approach
- Hands-on environment requirements
- Certification / proficiency-check criteria
- Post-go-live refresher / onboarding approach
''')
  String? content;
}

// ---------------------------------------------------------------------------
// 15.5 Pilot Plan
// ---------------------------------------------------------------------------

/// 15.5. Pilot Plan.
///
/// Pilot scope, cohort selection, success criteria, and exit decision rules.
@SectionId('PLTPLN')
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-PIL')
class PilotPlan {
  @ContentHelp('''
Pilot definition: who participates, what is in/out of pilot scope, how
success is measured, and the decision gate that authorizes rollout.

**What to capture:**
- Pilot cohort (sites, users, transaction volume)
- Pilot scope (functional / technical / geographic subset)
- Pilot duration and schedule
- Success criteria (quantitative + qualitative)
- Feedback collection mechanism
- Exit decision rules (proceed / extend / abort)
- Risk and rollback plan
''')
  String? content;
}

// ---------------------------------------------------------------------------
// 15.6 Cutover Procedures
// ---------------------------------------------------------------------------

/// 15.6. Cutover Procedures.
///
/// Detailed cutover runbook for go-live. Minute-by-minute procedure
/// covering the transition from current operation to the target system.
@SectionId('CUTPRC')
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-CUT')
class CutoverProcedure {
  @ContentHelp('''
Cutover runbook: the operational plan that executes the go-live moment.
Deliberately more tactical than the Rollout Plan — which sets cohorts and
waves — and than the Migration Plan — which covers data execution.

**What to capture:**
- Cutover timeline (freeze, migration, verification, open)
- Task checklist with owners, start/end times, dependencies
- Communication touchpoints (internal / external, pre / during / post)
- Go / no-go criteria at each gate
- Contingency scripts (partial-failure recovery, rollback trigger)
- Command center / war-room setup
- Post-cutover verification checks
''')
  String? content;
}

// ---------------------------------------------------------------------------
// 15.7 Knowledge Transfer
// ---------------------------------------------------------------------------

/// 15.7. Knowledge Transfer.
///
/// Handover from delivery team to operations. Covers handover-agreement
/// content.
@SectionId('KNTFR')
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-KNO')
class KnowledgeTransfer {
  @ContentHelp('''
Formal handover of system knowledge to operations and support teams.

**What to capture:**
- Knowledge artifact catalog (runbooks, diagrams, configs, credentials)
- Handover sessions (audience, agenda, duration, proof-of-comprehension)
- Sign-off criteria for operations readiness
- Shadow / co-ownership period before full handover
- Reference contacts for escalation post-handover
- Artifact storage location and access model
''')
  String? content;
}

// ---------------------------------------------------------------------------
// 15.8 Warranty and Support
// ---------------------------------------------------------------------------

/// 15.8. Warranty and Support.
///
/// Post-acceptance warranty period terms and support arrangements. Covers
/// warranty content and feeds the TRP top-level on the same topic.
@SectionId('WRTSP')
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-WAR')
class WarrantyAndSupport {
  @ContentHelp('''
Terms governing the warranty window that follows acceptance. Distinct
from the long-term operations SLA (the acceptance-plan warranty section
covers acceptance-time warranty; this entry captures the execution plan).

**What to capture:**
- Warranty period length and scope (functional / non-functional / data)
- Defect classification and response-time expectations
- Support channels and escalation path during warranty
- Change-request handling during warranty
- Transition from warranty to BAU support
- Exit criteria for warranty closure
''')
  String? content;
}
