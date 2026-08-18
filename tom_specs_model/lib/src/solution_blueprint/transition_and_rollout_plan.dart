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
@StandardReferences(
  [
    'ISO/IEC/IEEE 15288:2023 — the system life-cycle processes standard defines the transition process that installs and rolls a system into operational use',
    'ITIL 4 2019 — the service management framework defines release management and deployment for service transition into live use',
  ],
  'Captures the executive rollout concept that sequences pilot, phased rollout, migration, enablement, cutover, knowledge transfer, and post-go-live support.',
)
@SectionId('ROLC')
@Comment('Seeds → TRP')
@MapsTo(D12TransitionRolloutPlan)
class SystemRollout extends DocSpecsSection {
  @ContentHelp('''
Executive summary of the rollout approach: from pilot through phased
rollout, migration, user enablement, cutover, knowledge transfer, and
post-go-live support. Seeds the TRP document (Phase 3) together with the
localization, translation, and documentation subtrees.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 15.1. Rollout Plan.
  @SerializationOrder(1)
  RolloutPlan rolloutPlan = RolloutPlan();

  /// 15.2. Migration Plan.
  @SerializationOrder(2)
  MigrationPlan migrationPlan = MigrationPlan();

  /// 15.3. User Manuals.
  ///
  /// One whole-catalog content section (mirrors the `rolloutPlan` /
  /// `migrationPlan` / `pilotPlan` siblings); collapsed from
  /// `List<UserManual>` (L34C-12 SR-57).
  @SerializationOrder(3)
  UserManual userManuals = UserManual();

  /// 15.4. Training Materials.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<RolloutTrainingMaterial>` (L34C-12 SR-57).
  @SerializationOrder(4)
  RolloutTrainingMaterial trainingMaterials = RolloutTrainingMaterial();

  /// 15.5. Pilot Plan.
  @SerializationOrder(5)
  PilotPlan pilotPlan = PilotPlan();

  /// 15.6. Cutover Procedures.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<CutoverProcedure>` (L34C-12 SR-57).
  @SerializationOrder(6)
  CutoverProcedure cutoverProcedures = CutoverProcedure();

  /// 15.7. Knowledge Transfer.
  @SerializationOrder(7)
  KnowledgeTransfer knowledgeTransfer = KnowledgeTransfer();

  /// 15.8. Warranty and Support.
  @SerializationOrder(8)
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
@StandardReferences(
  [
    'ITIL 4 2019 — the service management framework defines release management, deployment models, and phased rollout waves',
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames rollout sequencing, wave criteria, and stage gating',
  ],
  'Captures the rollout plan that sequences sites, business units, and user cohorts across go-live waves with entry and exit criteria.',
)
@SectionId('RLTPLN')
@DetailedIn(D12TransitionRolloutPlan)
@FollowUpKind(
  [FollowUpProcess.mig, FollowUpProcess.ops, FollowUpProcess.org, FollowUpProcess.l10n],
  note:
      'follow-up material under DeliveryTransitionAndRollout in the SBP; '
      'reached here directly by a detail-document path',
)
class RolloutPlan extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
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
@StandardReferences(
  [
    'DAMA-DMBOK2 2017 — the data management body of knowledge defines the data-migration execution, validation, and reconciliation practices',
    'ITIL 4 2019 — the service management framework defines change enablement and deployment for the migration cutover',
  ],
  'Captures the end-to-end migration runbook covering extract, transform, load windows, dress rehearsal, and fallback for moving data and users to the target.',
)
@SectionId('MIGPLN')
@DetailedIn(D12TransitionRolloutPlan)
@FollowUpKind(
  [FollowUpProcess.mig, FollowUpProcess.ops, FollowUpProcess.org, FollowUpProcess.l10n],
  note:
      'follow-up material under DeliveryTransitionAndRollout in the SBP; '
      'reached here directly by a detail-document path',
)
class MigrationPlan extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
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
@StandardReferences(
  [
    'ISO/IEC/IEEE 26514:2022 — the standard for designing and developing user documentation defines the user-manual deliverables',
    'ISO/IEC/IEEE 26511:2018 — the standard for managing user documentation defines the production, review, and maintenance process',
  ],
  'Captures the user-manual deliverables covering the document catalog, audiences, languages, delivery channels, and post-go-live maintenance.',
)
@SectionId('USRMAN')
@DetailedIn(D12TransitionRolloutPlan)
@FollowUpKind(
  [FollowUpProcess.mig, FollowUpProcess.ops, FollowUpProcess.org, FollowUpProcess.l10n],
  note:
      'follow-up material under DeliveryTransitionAndRollout in the SBP; '
      'reached here directly by a detail-document path',
)
class UserManual extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
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
@StandardReferences(
  [
    'ADDIE model 1975 — the instructional systems design framework defines analysis, design, development, implementation, and evaluation of training',
    'ISO 21502:2020 — the guidance on project management defines training and enablement deliverables for handover',
  ],
  'Captures the training deliverables covering the course catalog per user category, delivery mechanism, train-the-trainer approach, and certification.',
)
@SectionId('RLTTM')
@DetailedIn(D12TransitionRolloutPlan)
@FollowUpKind(
  [FollowUpProcess.mig, FollowUpProcess.ops, FollowUpProcess.org, FollowUpProcess.l10n],
  note:
      'follow-up material under DeliveryTransitionAndRollout in the SBP; '
      'reached here directly by a detail-document path',
)
class RolloutTrainingMaterial extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 15.5 Pilot Plan
// ---------------------------------------------------------------------------

/// 15.5. Pilot Plan.
///
/// Pilot scope, cohort selection, success criteria, and exit decision rules.
@StandardReferences(
  [
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames pilot scoping, success criteria, and stage-gate decisions',
    'ITIL 4 2019 — the service management framework defines piloting and early-life support ahead of full deployment',
  ],
  'Captures the pilot plan covering cohort selection, scope, success measures, feedback collection, and the exit decision that authorizes rollout.',
)
@SectionId('PLTPLN')
@DetailedIn(D12TransitionRolloutPlan)
@FollowUpKind(
  [FollowUpProcess.mig, FollowUpProcess.ops, FollowUpProcess.org, FollowUpProcess.l10n],
  note:
      'follow-up material under DeliveryTransitionAndRollout in the SBP; '
      'reached here directly by a detail-document path',
)
class PilotPlan extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 15.6 Cutover Procedures
// ---------------------------------------------------------------------------

/// 15.6. Cutover Procedures.
///
/// Detailed cutover runbook for go-live. Minute-by-minute procedure
/// covering the transition from current operation to the target system.
@StandardReferences(
  [
    'ITIL 4 2019 — the service management framework defines deployment management and change enablement for the go-live cutover',
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames go-live execution, go and no-go gates, and contingency planning',
  ],
  'Captures the cutover runbook that executes the go-live moment with a timed task checklist, communication touchpoints, gate criteria, and rollback triggers.',
)
@SectionId('CUTPRC')
@DetailedIn(D12TransitionRolloutPlan)
@FollowUpKind(
  [FollowUpProcess.mig, FollowUpProcess.ops, FollowUpProcess.org, FollowUpProcess.l10n],
  note:
      'follow-up material under DeliveryTransitionAndRollout in the SBP; '
      'reached here directly by a detail-document path',
)
class CutoverProcedure extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 15.7 Knowledge Transfer
// ---------------------------------------------------------------------------

/// 15.7. Knowledge Transfer.
///
/// Handover from delivery team to operations. Covers handover-agreement
/// content.
@StandardReferences(
  [
    'ITIL 4 2019 — the service management framework defines knowledge management and service-transition handover to operations',
    'ISO/IEC 20000-1:2018 — the IT service management standard defines the service-transition and knowledge-handover practices',
  ],
  'Captures the knowledge transfer from the delivery team to operations, covering the artifact catalog, handover sessions, readiness sign-off, and shadow period.',
)
@SectionId('KNTFR')
@DetailedIn(D12TransitionRolloutPlan)
@FollowUpKind(
  [FollowUpProcess.mig, FollowUpProcess.ops, FollowUpProcess.org, FollowUpProcess.l10n],
  note:
      'follow-up material under DeliveryTransitionAndRollout in the SBP; '
      'reached here directly by a detail-document path',
)
class KnowledgeTransfer extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 15.8 Warranty and Support
// ---------------------------------------------------------------------------

/// 15.8. Warranty and Support.
///
/// Post-acceptance warranty period terms and support arrangements. Covers
/// warranty content and feeds the TRP top-level on the same topic.
@StandardReferences(
  [
    'ISO/IEC 20000-1:2018 — the IT service management standard defines warranty, support, and incident-response commitments',
    'ITIL 4 2019 — the service management framework defines early-life support and the transition from warranty to business-as-usual',
  ],
  'Captures the post-acceptance warranty terms covering the warranty period scope, defect response times, support channels, and exit to routine operations.',
)
@SectionId('WRTSP')
@DetailedIn(D12TransitionRolloutPlan)
@FollowUpKind(
  [FollowUpProcess.mig, FollowUpProcess.ops, FollowUpProcess.org, FollowUpProcess.l10n],
  note:
      'follow-up material under DeliveryTransitionAndRollout in the SBP; '
      'reached here directly by a detail-document path',
)
class WarrantyAndSupport extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;
}
