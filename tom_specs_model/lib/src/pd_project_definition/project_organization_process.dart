/// Section 2: Project Organization and Process [PD00-POP].
///
/// Project-specific deviations from the standard TomSpecs methodology.
/// Documents customizations to standard roles, quality gates, processes,
/// and project-specific tooling decisions.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// 2. Project Organization and Process [PD00-POP].
///
/// Project-specific deviations from the standard TomSpecs methodology.
/// This section documents any customizations to standard roles, quality gates,
/// and the creation or upgrade process for this particular project.
@SectionId('PD00-POP')
class ProjectOrganizationAndProcess {
  @ContentHelp('''
Executive summary of project-specific methodology deviations.
Explain why this project requires deviations from standard TomSpecs practices,
the overall impact on governance, and how deviations are tracked and approved.
''')
  String? content;

  /// Visual overview of methodology deviations.
  @ContentType('mermaid-flowchart', 'Diagram showing how project-specific '
      'methodology relates to standard TomSpecs, highlighting key deviations')
  String? methodologyDeviationDiagram;

  /// Summary of all methodology deviations.
  MethodologyDeviationSummary deviationSummary = MethodologyDeviationSummary();

  /// 2.1. Role Adjustments [PD00-POP-ROL].
  RoleAdjustments roleAdjustments = RoleAdjustments();

  /// 2.2. Quality Gate Adjustments [PD00-POP-QGA].
  QualityGateAdjustments qualityGateAdjustments = QualityGateAdjustments();

  /// 2.3. Process Adjustments [PD00-POP-PRC].
  ProcessAdjustments processAdjustments = ProcessAdjustments();

  /// 2.4. Tooling and Environments [PD00-POP-TOO].
  ToolingAndEnvironments toolingAndEnvironments = ToolingAndEnvironments();
}

/// Summary of all methodology deviations for quick reference.
@SectionId('PD00-POP-SUM')
class MethodologyDeviationSummary {
  @Form([
    Field('totalRoleAdjustments', int, 'Total Role Adjustments',
        hint: 'Number of roles with deviations from standard'),
    Field('totalQualityGateAdjustments', int, 'Total Quality Gate Adjustments',
        hint: 'Number of quality gates with deviations'),
    Field('totalProcessAdjustments', int, 'Total Process Adjustments',
        hint: 'Number of process steps with deviations'),
    Field('deviationRiskLevel', String, 'Overall Deviation Risk Level',
        hint: 'Low / Medium / High — aggregate risk from all deviations'),
    Field('deviationApprovalAuthority', String, 'Deviation Approval Authority',
        hint: 'Who approved these methodology deviations'),
    Field('deviationApprovalDate', String, 'Deviation Approval Date',
        hint: 'When deviations were formally approved'),
    Field('reviewSchedule', String, 'Deviation Review Schedule',
        hint: 'How often deviations are reviewed for continued relevance'),
    Field('nextReviewDate', String, 'Next Review Date',
        hint: 'When deviations will be next reviewed'),
    Field('standardsVersion', String, 'TomSpecs Standards Version',
        hint: 'Version of TomSpecs standards this project deviates from'),
    Field('deviationJustificationSummary', String, 'Justification Summary',
        hint: 'High-level rationale for why deviations are needed'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 2.1 Role Adjustments
// ---------------------------------------------------------------------------

/// 2.1. Role Adjustments [PD00-POP-ROL].
///
/// Documents any deviations from the standard TomSpecs roles defined in
/// tom_roles.md. Includes merged, split, omitted, or modified roles
/// and the rationale for each deviation.
@SectionId('PD00-POP-ROL')
class RoleAdjustments {
  @ContentHelp('''
Overview of role adjustments for this project. Explain why standard role
definitions don't fit, what stakeholder or organizational factors drove
the changes, and how role clarity is maintained despite deviations.
''')
  String? content;

  /// Role adjustment summary statistics.
  RoleAdjustmentSummary adjustmentSummary = RoleAdjustmentSummary();

  /// Visual comparison of standard vs adjusted roles.
  @ContentType('mermaid', 'Diagram comparing standard TomSpecs roles '
      'with project-specific role assignments')
  String? roleComparisonDiagram;

  /// Contains 0+× RoleAdjustment.
  @SectionIdPattern('PD00-POP-ROL-xx')
  List<RoleAdjustmentEntry> items = [];
}

/// Summary of role adjustments.
@SectionId('PD00-POP-ROL-SUM')
class RoleAdjustmentSummary {
  @Form([
    Field('standardRolesCount', int, 'Standard Roles Count',
        hint: 'Number of roles in standard TomSpecs methodology'),
    Field('adjustedRolesCount', int, 'Adjusted Roles Count',
        hint: 'Number of roles that deviate from standard'),
    Field('mergedRolesCount', int, 'Merged Roles Count',
        hint: 'Number of roles merged together'),
    Field('splitRolesCount', int, 'Split Roles Count',
        hint: 'Number of standard roles split into multiple'),
    Field('omittedRolesCount', int, 'Omitted Roles Count',
        hint: 'Number of standard roles not used'),
    Field('addedRolesCount', int, 'Added Roles Count',
        hint: 'Number of project-specific roles added'),
    Field('raciMatrixCompliance', String, 'RACI Matrix Compliance',
        hint: 'Whether all activities still have clear RACI coverage'),
    Field('governanceImpact', String, 'Governance Impact Assessment',
        hint: 'Low / Medium / High — impact on project governance'),
  ])
  String? content;
}

/// A role adjustment entry (form) [PD00-POP-ROL-nn].
///
/// Documents a specific deviation from standard TomSpecs role definitions,
/// including the type of adjustment, affected responsibilities, risk
/// assessment, and mitigation measures.
@SectionId('PD00-POP-ROL-ENT')
class RoleAdjustmentEntry {
  @Form([
    Field('adjustmentId', String, 'Adjustment ID',
        hint: 'Unique identifier, e.g. ROL-ADJ-001', required: true),
    Field('standardRoleName', String, 'Standard Role Name',
        hint: 'Original TomSpecs role being adjusted', required: true),
    Field('adjustmentType', String, 'Adjustment Type',
        hint: 'Merged / Split / Modified / Omitted / Added'),
  ])
  String? content;

  /// Adjustment details: name changes, affected responsibilities.
  RoleAdjustmentEntryDetails details = RoleAdjustmentEntryDetails();

  /// Rationale for the adjustment.
  RoleAdjustmentEntryRationale rationale = RoleAdjustmentEntryRationale();

  /// Coverage: assignments and RACI impact.
  RoleAdjustmentEntryCoverage coverage = RoleAdjustmentEntryCoverage();

  /// Risk assessment.
  RoleAdjustmentEntryRisk risk = RoleAdjustmentEntryRisk();

  /// Governance: approval and review.
  RoleAdjustmentEntryGovernance governance = RoleAdjustmentEntryGovernance();
}

/// Adjustment details for role.
@SectionId('PD00-POP-ROL-ENT-DET')
class RoleAdjustmentEntryDetails {
  @Form([
    Field('adjustedRoleName', String, 'Adjusted Role Name',
        hint: 'Name of the role after adjustment'),
    Field('adjustmentDescription', String, 'Adjustment Description',
        hint: 'Detailed description of what changed'),
    Field('affectedResponsibilities', String, 'Affected Responsibilities',
        hint: 'Which responsibilities are impacted by this change'),
    Field('mergedWithRoles', String, 'Merged With Roles',
        hint: 'If merged, which other roles it combines with'),
    Field('splitIntoRoles', String, 'Split Into Roles',
        hint: 'If split, names of the resulting roles'),
  ])
  String? content;
}

/// Rationale for role adjustment.
@SectionId('PD00-POP-ROL-ENT-RAT')
class RoleAdjustmentEntryRationale {
  @Form([
    Field('rationale', String, 'Rationale',
        hint: 'Business or organizational reason for the adjustment'),
    Field('drivingFactors', String, 'Driving Factors',
        hint: 'ProjectSize / TeamStructure / Skills / Regulatory / Budget'),
    Field('stakeholderAgreement', String, 'Stakeholder Agreement',
        hint: 'Who agreed to this adjustment'),
  ])
  String? content;
}

/// Coverage: assignments and RACI impact.
@SectionId('PD00-POP-ROL-ENT-COV')
class RoleAdjustmentEntryCoverage {
  @Form([
    Field('assignedTo', String, 'Assigned To',
        hint: 'Person or team fulfilling this adjusted role'),
    Field('backupAssignment', String, 'Backup Assignment',
        hint: 'Backup person or team when primary is unavailable'),
    Field('raciImpact', String, 'RACI Impact',
        hint: 'How this affects the RACI matrix for related activities'),
  ])
  String? content;
}

/// Risk assessment for role adjustment.
@SectionId('PD00-POP-ROL-ENT-RSK')
class RoleAdjustmentEntryRisk {
  @Form([
    Field('riskLevel', String, 'Risk Level',
        hint: 'Low / Medium / High — risk introduced by this deviation'),
    Field('riskDescription', String, 'Risk Description',
        hint: 'What could go wrong due to this adjustment'),
    Field('mitigationMeasures', String, 'Mitigation Measures',
        hint: 'How risks from this adjustment are mitigated'),
  ])
  String? content;
}

/// Governance: approval and review.
@SectionId('PD00-POP-ROL-ENT-GOV')
class RoleAdjustmentEntryGovernance {
  @Form([
    Field('approvalStatus', String, 'Approval Status',
        hint: 'Proposed / Approved / Conditional / Rejected'),
    Field('approvedBy', String, 'Approved By',
        hint: 'Who approved this deviation'),
    Field('approvalDate', String, 'Approval Date',
        hint: 'When the deviation was approved'),
    Field('reviewDate', String, 'Next Review Date',
        hint: 'When this adjustment will be reviewed'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or considerations'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 2.2 Quality Gate Adjustments
// ---------------------------------------------------------------------------

/// 2.2. Quality Gate Adjustments [PD00-POP-QGA].
///
/// Documents any deviations from the standard quality gates defined in
/// tom_quality_gates.md. Includes skipped, added, or modified gates
/// and the rationale for each deviation.
@SectionId('PD00-POP-QGA')
class QualityGateAdjustments {
  @ContentHelp('''
Overview of quality gate adjustments for this project. Explain why standard
gates are modified, what project characteristics drove the changes, and
how quality assurance is maintained despite deviations.
''')
  String? content;

  /// Quality gate adjustment summary.
  QualityGateAdjustmentSummary adjustmentSummary =
      QualityGateAdjustmentSummary();

  /// Visual representation of gate adjustments.
  @ContentType('mermaid', 'Diagram showing quality gate flow with '
      'adjustments highlighted')
  String? gateFlowDiagram;

  /// Contains 0+× QualityGateAdjustment.
  @SectionIdPattern('PD00-POP-QGA-xx')
  List<QualityGateAdjustmentEntry> items = [];
}

/// Summary of quality gate adjustments.
@SectionId('PD00-POP-QGA-SUM')
class QualityGateAdjustmentSummary {
  @Form([
    Field('standardGatesCount', int, 'Standard Gates Count',
        hint: 'Number of gates in standard TomSpecs methodology'),
    Field('adjustedGatesCount', int, 'Adjusted Gates Count',
        hint: 'Number of gates with deviations'),
    Field('skippedGatesCount', int, 'Skipped Gates Count',
        hint: 'Number of standard gates bypassed'),
    Field('addedGatesCount', int, 'Added Gates Count',
        hint: 'Number of project-specific gates added'),
    Field('modifiedCriteriaCount', int, 'Modified Criteria Count',
        hint: 'Number of gates with modified pass criteria'),
    Field('qualityRiskLevel', String, 'Quality Risk Level',
        hint: 'Low / Medium / High — overall quality risk from deviations'),
    Field('compensatingControls', String, 'Compensating Controls',
        hint: 'Alternative quality measures in place'),
    Field('auditImplications', String, 'Audit Implications',
        hint: 'Impact on quality audits and compliance'),
  ])
  String? content;
}

/// A quality gate adjustment entry (form) [PD00-POP-QGA-nn].
///
/// Documents a specific deviation from standard quality gate definitions,
/// including the type of change, impact on quality assurance, risk
/// assessment, and compensating controls.
@SectionId('PD00-POP-QGA-ENT')
class QualityGateAdjustmentEntry {
  @Form([
    Field('adjustmentId', String, 'Adjustment ID',
        hint: 'Unique identifier, e.g. QGA-ADJ-001', required: true),
    Field('standardGateName', String, 'Standard Gate Name',
        hint: 'Original TomSpecs quality gate being adjusted', required: true),
    Field('adjustmentType', String, 'Adjustment Type',
        hint: 'Skipped / Added / Modified / Deferred / Relaxed'),
  ])
  String? content;

  /// Gate details.
  final QualityGateAdjustmentDetails details = QualityGateAdjustmentDetails();

  /// Rationale.
  final QualityGateAdjustmentRationale rationale =
      QualityGateAdjustmentRationale();

  /// Impact assessment.
  final QualityGateAdjustmentImpact impact = QualityGateAdjustmentImpact();

  /// Governance.
  final QualityGateAdjustmentGovernance governance =
      QualityGateAdjustmentGovernance();
}

/// Gate details.
@SectionId('PD00-POP-QGA-ENT-DET')
class QualityGateAdjustmentDetails {
  @Form([
    Field('gatePhase', String, 'Gate Phase',
        hint: 'Project phase — Planning / Design / Build / Test / Deploy'),
    Field('adjustmentDescription', String, 'Adjustment Description',
        hint: 'Detailed description of what changed'),
    Field('originalCriteria', String, 'Original Criteria',
        hint: 'Standard pass/fail criteria for this gate'),
    Field('adjustedCriteria', String, 'Adjusted Criteria',
        hint: 'Modified pass/fail criteria after adjustment'),
    Field('criteriaThresholdChange', String, 'Threshold Change',
        hint: 'How thresholds were modified'),
  ])
  String? content;
}

/// Rationale.
@SectionId('PD00-POP-QGA-ENT-RAT')
class QualityGateAdjustmentRationale {
  @Form([
    Field('rationale', String, 'Rationale',
        hint: 'Business or technical reason for the adjustment'),
    Field('drivingFactors', String, 'Driving Factors',
        hint: 'Timeline / Budget / Scope / Risk / Complexity'),
    Field('temporaryOrPermanent', String, 'Temporary or Permanent',
        hint: 'Temporary / Permanent — whether deviation is time-limited'),
    Field('expirationDate', String, 'Expiration Date',
        hint: 'If temporary, when this deviation expires'),
  ])
  String? content;
}

/// Impact assessment.
@SectionId('PD00-POP-QGA-ENT-IMP')
class QualityGateAdjustmentImpact {
  @Form([
    Field('qualityImpact', String, 'Quality Impact',
        hint: 'How this adjustment affects delivered quality'),
    Field('riskLevel', String, 'Risk Level',
        hint: 'Low / Medium / High'),
    Field('riskDescription', String, 'Risk Description',
        hint: 'What quality issues could arise'),
    Field('compensatingControls', String, 'Compensating Controls',
        hint: 'Alternative quality measures to offset the deviation'),
    Field('monitoringMeasures', String, 'Monitoring Measures',
        hint: 'How quality is monitored despite the deviation'),
  ])
  String? content;
}

/// Governance.
@SectionId('PD00-POP-QGA-ENT-GOV')
class QualityGateAdjustmentGovernance {
  @Form([
    Field('approvalStatus', String, 'Approval Status',
        hint: 'Proposed / Approved / Conditional / Rejected'),
    Field('approvedBy', String, 'Approved By',
        hint: 'Who approved this deviation'),
    Field('approvalDate', String, 'Approval Date',
        hint: 'When the deviation was approved'),
    Field('reviewDate', String, 'Next Review Date',
        hint: 'When this adjustment will be reviewed'),
    Field('auditTrailReference', String, 'Audit Trail Reference',
        hint: 'Reference to approval documentation'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or considerations'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 2.3 Process Adjustments
// ---------------------------------------------------------------------------

/// 2.3. Process Adjustments [PD00-POP-PRC].
///
/// Documents any deviations from the standard tom_system_creation.md or
/// tom_system_upgrade.md process. Includes skipped, reordered, or modified
/// steps and the rationale for each deviation.
@SectionId('PD00-POP-PRC')
class ProcessAdjustments {
  @ContentHelp('''
Overview of process adjustments for this project. Explain why standard
process steps are modified, what project constraints drove the changes,
and how process integrity is maintained despite deviations.
''')
  String? content;

  /// Process adjustment summary.
  ProcessAdjustmentSummary adjustmentSummary = ProcessAdjustmentSummary();

  /// Visual representation of process adjustments.
  @ContentType('mermaid-flowchart', 'Diagram showing process flow with '
      'adjustments highlighted — skipped steps crossed out, '
      'reordered steps with arrows, added steps in different color')
  String? processFlowDiagram;

  /// Contains 0+× ProcessAdjustment.
  @SectionIdPattern('PD00-POP-PRC-xx')
  List<ProcessAdjustmentEntry> items = [];
}

/// Summary of process adjustments.
@SectionId('PD00-POP-PRC-SUM')
class ProcessAdjustmentSummary {
  @Form([
    Field('baseProcess', String, 'Base Process',
        hint: 'tom_system_creation / tom_system_upgrade'),
    Field('baseProcessVersion', String, 'Base Process Version',
        hint: 'Version of the standard process being adjusted'),
    Field('totalStepsInBase', int, 'Total Steps in Base Process',
        hint: 'Number of steps in the standard process'),
    Field('adjustedStepsCount', int, 'Adjusted Steps Count',
        hint: 'Number of steps with deviations'),
    Field('skippedStepsCount', int, 'Skipped Steps Count',
        hint: 'Number of standard steps bypassed'),
    Field('addedStepsCount', int, 'Added Steps Count',
        hint: 'Number of project-specific steps added'),
    Field('reorderedStepsCount', int, 'Reordered Steps Count',
        hint: 'Number of steps executed in different order'),
    Field('parallelizedStepsCount', int, 'Parallelized Steps Count',
        hint: 'Number of steps run in parallel instead of sequential'),
    Field('processRiskLevel', String, 'Process Risk Level',
        hint: 'Low / Medium / High — overall process risk from deviations'),
    Field('processEfficiencyImpact', String, 'Efficiency Impact',
        hint: 'Faster / Same / Slower — impact on timeline'),
  ])
  String? content;
}

/// A process adjustment entry (form) [PD00-POP-PRC-nn].
///
/// Documents a specific deviation from standard process steps, including
/// the type of modification, dependencies affected, risk assessment,
/// and implementation details.
@SectionId('PD00-POP-PRC-ENT')
class ProcessAdjustmentEntry {
  @Form([
    Field('adjustmentId', String, 'Adjustment ID',
        hint: 'Unique identifier, e.g. PRC-ADJ-001', required: true),
    Field('standardStepName', String, 'Standard Step Name',
        hint: 'Original process step being adjusted', required: true),
    Field('adjustmentType', String, 'Adjustment Type',
        hint: 'Skipped / Modified / Reordered / Parallelized / Added'),
  ])
  String? content;

  /// Identification details.
  final ProcessAdjustmentIdentity identity = ProcessAdjustmentIdentity();

  /// Adjustment details.
  final ProcessAdjustmentDetails details = ProcessAdjustmentDetails();

  /// Rationale.
  final ProcessAdjustmentRationale rationale = ProcessAdjustmentRationale();

  /// Implementation.
  final ProcessAdjustmentImplementation implementation =
      ProcessAdjustmentImplementation();

  /// Risk and impact.
  final ProcessAdjustmentRisk risk = ProcessAdjustmentRisk();

  /// Governance.
  final ProcessAdjustmentGovernance governance = ProcessAdjustmentGovernance();
}

/// Identity for process adjustment.
@SectionId('PD00-POP-PRC-ENT-IDN')
class ProcessAdjustmentIdentity {
  @Form([
    Field('stepPhase', String, 'Step Phase',
        hint: 'Phase this step belongs to — Initiation / Planning / Execution'),
    Field('originalPosition', String, 'Original Position',
        hint: 'Original position in process, e.g. Step 5 of 12'),
  ])
  String? content;
}

/// Details for process adjustment.
@SectionId('PD00-POP-PRC-ENT-DET')
class ProcessAdjustmentDetails {
  @Form([
    Field('adjustmentDescription', String, 'Adjustment Description',
        hint: 'Detailed description of what changed'),
    Field('newPosition', String, 'New Position',
        hint: 'If reordered, new position in process'),
    Field('parallelWith', String, 'Parallel With',
        hint: 'If parallelized, which other steps run concurrently'),
    Field('mergedWith', String, 'Merged With',
        hint: 'If merged, which other steps are combined'),
    Field('splitInto', String, 'Split Into',
        hint: 'If split, names of the resulting sub-steps'),
  ])
  String? content;
}

/// Rationale for process adjustment.
@SectionId('PD00-POP-PRC-ENT-RAT')
class ProcessAdjustmentRationale {
  @Form([
    Field('rationale', String, 'Rationale',
        hint: 'Business or technical reason for the adjustment'),
    Field('drivingFactors', String, 'Driving Factors',
        hint: 'Timeline / Budget / Scope / Dependencies / Resources'),
    Field('dependencyImpact', String, 'Dependency Impact',
        hint: 'How this affects step dependencies'),
    Field('predecessorChanges', String, 'Predecessor Changes',
        hint: 'Changes to prerequisite steps'),
    Field('successorChanges', String, 'Successor Changes',
        hint: 'Changes to dependent steps'),
  ])
  String? content;
}

/// Implementation for process adjustment.
@SectionId('PD00-POP-PRC-ENT-IMP')
class ProcessAdjustmentImplementation {
  @Form([
    Field('implementationApproach', String, 'Implementation Approach',
        hint: 'How the adjusted step will be executed'),
    Field('deliverableChanges', String, 'Deliverable Changes',
        hint: 'How step deliverables are affected'),
    Field('toolingChanges', String, 'Tooling Changes',
        hint: 'Any tooling changes required'),
    Field('resourceChanges', String, 'Resource Changes',
        hint: 'Any staffing or skill changes required'),
  ])
  String? content;
}

/// Risk for process adjustment.
@SectionId('PD00-POP-PRC-ENT-RSK')
class ProcessAdjustmentRisk {
  @Form([
    Field('riskLevel', String, 'Risk Level',
        hint: 'Low / Medium / High — risk introduced by this deviation'),
    Field('riskDescription', String, 'Risk Description',
        hint: 'What could go wrong due to this adjustment'),
    Field('mitigationMeasures', String, 'Mitigation Measures',
        hint: 'How risks from this adjustment are mitigated'),
    Field('timelineImpact', String, 'Timeline Impact',
        hint: 'FasterByDays / NoChange / SlowerByDays'),
    Field('budgetImpact', String, 'Budget Impact',
        hint: 'CostReduction / NoChange / CostIncrease'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or considerations'),
  ])
  String? content;
}

/// Governance for process adjustment.
@SectionId('PD00-POP-PRC-ENT-GOV')
class ProcessAdjustmentGovernance {
  @Form([
    Field('approvalStatus', String, 'Approval Status',
        hint: 'Proposed / Approved / Conditional / Rejected'),
    Field('approvedBy', String, 'Approved By',
        hint: 'Who approved this deviation'),
    Field('approvalDate', String, 'Approval Date',
        hint: 'When the deviation was approved'),
    Field('reviewDate', String, 'Next Review Date',
        hint: 'When this adjustment will be reviewed'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 2.4 Tooling and Environments
// ---------------------------------------------------------------------------

/// 2.4. Tooling and Environments [PD00-POP-TOO].
@SectionId('PD00-POP-TOO')
class ToolingAndEnvironments {
  @Unused()
  String? content;

  /// 2.4.1. Tooling [PD00-POP-TOO-TOO].
  Tooling tooling = Tooling();

  /// 2.4.2. Environments [PD00-POP-TOO-ENV].
  Environments environments = Environments();
}

/// 2.4.1. Tooling [PD00-POP-TOO-TOO].
///
/// Container for the project's tool inventory and governance policies.
/// Covers all tool categories: development, CI/CD, communication,
/// documentation, project management, testing, monitoring, security,
/// infrastructure, and operational tooling.
@SectionId('PD00-POP-TOO-TOO')
class Tooling {
  @Form([
    Field('toolStrategyOverview', String, 'Tool Strategy Overview',
        hint:
            'High-level approach to tooling — standardisation goals, '
            'preferred vendors, stack alignment'),
    Field('standardToolStackDescription', String,
        'Standard Tool Stack Description',
        hint:
            'Summary of the baseline tool stack all teams are expected '
            'to use'),
    Field('toolGovernancePolicy', String, 'Tool Governance Policy',
        hint:
            'Who decides on tool adoption, how exceptions are handled, '
            'review cadence'),
    Field('toolApprovalProcess', String, 'Tool Approval Process',
        hint:
            'Workflow for requesting, evaluating, and approving new tools'),
  ])
  String? content;

  /// Stack composition and selection policies.
  ToolingStack stack = ToolingStack();

  /// Lifecycle and governance processes.
  ToolingLifecycle lifecycle = ToolingLifecycle();

  /// Review, catalog, and notes.
  ToolingGovernance governance = ToolingGovernance();

  /// Tool strategy narrative.
  @ContentType('description',
      'Narrative overview of tool strategy, integration philosophy, '
      'and long-term tooling roadmap.')
  TextSection strategyNarrative = TextSection();

  /// Contains 0+× Tool.
  @SectionIdPattern('PD00-POP-TOO-TOO-xx')
  List<ToolEntry> items = [];
}

/// Stack composition and selection policies.
@SectionId('PD00-POP-TOO-TOO-STK')
class ToolingStack {
    @Form([
        Field('toolRationalizationGoals', String, 'Tool Rationalization Goals',
                hint:
                        'Targets for reducing overlap, consolidating redundant tools'),
        Field('mandatoryToolsOverview', String, 'Mandatory Tools Overview',
                hint:
                        'Tools that every team member must use — IDE, VCS, CI, communication'),
        Field('recommendedToolsOverview', String, 'Recommended Tools Overview',
                hint:
                        'Encouraged but optional tools — code assistants, profilers, linters'),
        Field('optionalToolsPolicy', String, 'Optional Tools Policy',
                hint:
                        'Policy for personal/team tool choices — BYO rules, security review'),
        Field('toolBudgetOverview', String, 'Tool Budget Overview',
                hint:
                        'Total annual budget for tool licenses, subscriptions, and infrastructure'),
    ])
    String? content;
}

/// Lifecycle and governance processes.
@SectionId('PD00-POP-TOO-TOO-LCY')
class ToolingLifecycle {
    @Form([
        Field('toolOnboardingProcess', String, 'Tool Onboarding Process',
                hint:
                        'Standard steps when a new team member joins — account provisioning, training'),
        Field('toolOffboardingProcess', String, 'Tool Offboarding Process',
                hint:
                        'Steps when a member leaves — license reclaim, access revocation, data export'),
    ])
    String? content;
}

/// Review, catalog, and notes.
@SectionId('PD00-POP-TOO-TOO-GOV')
class ToolingGovernance {
    @Form([
        Field('toolReviewCadence', String, 'Tool Review Cadence',
                hint:
                        'How often the tool landscape is reviewed — quarterly, biannually, annually'),
        Field('shadowItPolicy', String, 'Shadow IT Policy',
                hint:
                        'Policy for unapproved tool usage — detection, enforcement, amnesty process'),
        Field('toolCatalogUrl', String, 'Tool Catalog URL',
                hint: 'Link to the authoritative tool registry or wiki page'),
        Field('notes', String, 'Notes',
                hint: 'Additional tooling strategy notes'),
    ])
    String? content;
}

/// A tool entry (form) [PD00-POP-TOO-TOO-nn].
///
/// Comprehensive specification of a single tool covering identity,
/// licensing, versioning, access, integration, support, security,
/// usage, infrastructure, lifecycle, cost, configuration, and
/// documentation. Aligns with ITIL service catalog, PMBOK resource
/// planning, and enterprise architecture concerns.
@SectionId('PD00-POP-TOO-TOO-ENT')
class ToolEntry {
  @Form([
    Field('toolId', String, 'Tool ID',
        hint: 'Unique identifier, e.g. TOOL-IDE-001', required: true),
    Field('toolName', String, 'Tool Name',
        hint: 'Official product name, e.g. GitHub, Jira, VS Code',
        required: true),
    Field('notes', String, 'Notes',
        hint: 'Additional notes, caveats, or context'),
  ])
  String? content;

  /// Identity and classification details.
  final ToolIdentity identity = ToolIdentity();

  /// Licensing terms and compliance.
  final ToolLicensing licensing = ToolLicensing();

  /// Version management and upgrade policies.
  final ToolVersioning versioning = ToolVersioning();

  /// Access control and provisioning.
  final ToolAccess access = ToolAccess();

  /// Integration with other tools and systems.
  final ToolIntegration integration = ToolIntegration();

  /// Vendor and internal support details.
  final ToolSupport support = ToolSupport();

  /// Security and compliance requirements.
  final ToolSecurity security = ToolSecurity();

  /// Usage patterns and adoption metrics.
  final ToolUsage usage = ToolUsage();

  /// Infrastructure and hosting details.
  final ToolInfrastructure infrastructure = ToolInfrastructure();

  /// Lifecycle management and roadmap.
  final ToolLifecycle lifecycle = ToolLifecycle();

  /// Cost structure and budget.
  final ToolCost cost = ToolCost();

  /// Configuration standards and policies.
  final ToolConfiguration configuration = ToolConfiguration();

  /// Documentation resources.
  final ToolDocumentation documentation = ToolDocumentation();

  /// Approval status and ownership.
  final ToolApproval approval = ToolApproval();

  /// Integration details narrative.
  TextSection integrationNotes = TextSection();
}

/// Identity and classification for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-IDN')
class ToolIdentity {
  @Form([
    Field('vendorName', String, 'Vendor / Publisher',
        hint:
            'Company or organization, e.g. Microsoft, Atlassian, '
            'JetBrains'),
    Field('category', String, 'Category',
        hint:
            'IDE / VCS / CI-CD / ProjectManagement / Communication / '
            'Documentation / Testing / Monitoring / Security / '
            'Infrastructure / Database / Analytics / DesignPrototyping / '
            'CodeQuality / ArtifactManagement / Other'),
    Field('subcategory', String, 'Subcategory',
        hint:
            'More specific classification, e.g. StaticAnalysis, '
            'ContainerOrchestration, ChatMessaging, WikiKnowledgeBase'),
    Field('toolType', String, 'Tool Type',
        hint:
            'Commercial / OpenSource / Freemium / CustomBuilt / '
            'InternalFork / Managed'),
    Field('purpose', String, 'Purpose',
        hint: 'What this tool is used for in the project'),
    Field('businessJustification', String, 'Business Justification',
        hint:
            'Why this tool was chosen over alternatives — cost, '
            'capability, strategy'),
    Field('mandatoryLevel', String, 'Mandatory Level',
        hint: 'Mandatory / Recommended / Optional / Deprecated'),
    Field('targetAudience', String, 'Target Audience',
        hint:
            'Who uses this tool — Developers, QA, DevOps, PMs, All, '
            'Stakeholders'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint:
            'Other tools evaluated, e.g. GitLab vs GitHub, Jira vs '
            'Linear'),
    Field('selectionRationale', String, 'Selection Rationale',
        hint: 'Why this tool won over alternatives'),
  ])
  String? content;
}

/// Licensing terms and compliance for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-LIC')
class ToolLicensing {
  @Form([
    Field('licenseType', String, 'License Type',
        hint:
            'SPDX identifier or commercial name, e.g. MIT, Apache-2.0, '
            'Enterprise v3'),
    Field('licenseModel', String, 'License Model',
        hint:
            'PerSeat / PerUser / Floating / Site / Metered / FreeTier / '
            'OpenCore'),
    Field('licenseCount', String, 'License Count',
        hint: 'Number of licenses purchased or allocated'),
    Field('licenseCostPerUnit', String, 'License Cost Per Unit',
        hint: 'Cost per seat/user/instance per billing period'),
    Field('licenseBillingPeriod', String, 'License Billing Period',
        hint: 'Monthly / Annually / Perpetual / Multi-Year'),
    Field('licenseExpiryDate', String, 'License Expiry Date',
        hint: 'When the current license term ends'),
    Field('licenseRenewalDate', String, 'License Renewal Date',
        hint: 'When renewal must be initiated to avoid lapse'),
    Field('licenseOwner', String, 'License Owner',
        hint: 'Person or team managing the license relationship'),
    Field('licenseKeyLocation', String, 'License Key Location',
        hint:
            'Where the license key is stored — vault path, admin portal '
            'URL (never the key itself)'),
    Field('openSourceObligations', String, 'Open-Source Obligations',
        hint: 'Copyleft, attribution, source disclosure requirements'),
    Field('licenseComplianceStatus', String, 'License Compliance Status',
        hint: 'Compliant / UnderReview / AtRisk / NonCompliant'),
  ])
  String? content;
}

/// Version management and upgrade policies for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-VER')
class ToolVersioning {
  @Form([
    Field('currentVersion', String, 'Current Version',
        hint: 'Version currently deployed or in use'),
    Field('minimumVersion', String, 'Minimum Version',
        hint: 'Earliest acceptable version'),
    Field('targetVersion', String, 'Target Version',
        hint: 'Next planned upgrade target'),
    Field('latestAvailableVersion', String, 'Latest Available Version',
        hint: 'Most recent stable release from vendor'),
    Field('upgradeCadence', String, 'Upgrade Cadence',
        hint:
            'How often upgrades are applied — monthly, quarterly, '
            'per-release, LTS-only'),
    Field('autoUpdatePolicy', String, 'Auto-Update Policy',
        hint:
            'Enabled / Disabled / MajorManualMinorAuto / '
            'ManagedByVendor'),
    Field('upgradeApprovalProcess', String, 'Upgrade Approval Process',
        hint: 'Who approves version upgrades, testing requirements'),
    Field('versionPinningPolicy', String, 'Version Pinning Policy',
        hint:
            'Whether and how versions are pinned — lockfiles, tags, '
            'channels'),
    Field('breakingChangePolicy', String, 'Breaking Change Policy',
        hint:
            'How breaking changes from vendor are handled — testing, '
            'rollback, migration'),
    Field('releaseNotesUrl', String, 'Release Notes URL',
        hint: 'Link to vendor changelog or release announcements'),
  ])
  String? content;
}

/// Access control and provisioning for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-ACC')
class ToolAccess {
  @Form([
    Field('accessUrl', String, 'Access URL',
        hint: 'Primary URL/endpoint to access the tool'),
    Field('accessMethod', String, 'Access Method',
        hint:
            'Web / DesktopApp / CLI / IDE-Plugin / API / MobileApp / '
            'Terminal'),
    Field('ssoIntegration', String, 'SSO Integration',
        hint:
            'SSO provider and protocol — Okta SAML, Azure AD OIDC, '
            'None'),
    Field('mfaRequired', String, 'MFA Required',
        hint: 'Yes / No / ForAdminsOnly'),
    Field('provisioningMethod', String, 'Provisioning Method',
        hint:
            'Automatic-SCIM / Manual / SelfService / InviteBased / '
            'LDAP-Sync'),
    Field('deprovisioningMethod', String, 'Deprovisioning Method',
        hint: 'Automatic-SCIM / Manual / OnLeaver-Trigger / Timed-Expiry'),
    Field('accessRequestProcess', String, 'Access Request Process',
        hint:
            'How to request access — ServiceNow ticket, Slack channel, '
            'email'),
    Field('accessApprover', String, 'Access Approver',
        hint: 'Who approves access requests — manager, tool admin, auto'),
    Field('adminContact', String, 'Admin Contact',
        hint: 'Internal administrator or admin team'),
    Field('adminPortalUrl', String, 'Admin Portal URL',
        hint: 'URL for tool administration panel'),
    Field('onboardingSteps', String, 'Onboarding Steps',
        hint:
            'Steps for new users — account creation, config import, '
            'training requirement'),
    Field('serviceAccountPolicy', String, 'Service Account Policy',
        hint:
            'Rules for non-human accounts — naming, rotation, scope '
            'limits'),
  ])
  String? content;
}

/// Integration capabilities for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-INT')
class ToolIntegration {
  @Form([
    Field('integratesWithTools', String, 'Integrates With',
        hint:
            'Other project tools this integrates with, e.g. '
            'GitHub↔Jira, Slack↔PagerDuty'),
    Field('apiAvailability', String, 'API Availability',
        hint: 'REST / GraphQL / gRPC / WebSocket / SDK / CLI / None'),
    Field('apiDocumentationUrl', String, 'API Documentation URL',
        hint: 'Link to API reference or SDK docs'),
    Field('apiAuthMethod', String, 'API Auth Method',
        hint: 'OAuth2 / APIKey / PAT / ServiceAccount / mTLS'),
    Field('webhooksSupported', String, 'Webhooks Supported',
        hint: 'Yes / No — webhook event types available'),
    Field('pluginExtensionList', String, 'Plugins / Extensions',
        hint:
            'Required or recommended plugins, e.g. ESLint, Dart, '
            'GitLens'),
    Field('dataExchangeFormat', String, 'Data Exchange Format',
        hint: 'JSON / XML / CSV / Protobuf / Custom — for import/export'),
    Field('dataImportCapability', String, 'Data Import Capability',
        hint: 'Can import from other tools — formats, limitations'),
    Field('dataExportCapability', String, 'Data Export Capability',
        hint: 'Can export data — formats, completeness, scheduling'),
    Field('automationCapability', String, 'Automation Capability',
        hint:
            'CI/CD hooks, scheduled tasks, scripting, CLI automation '
            'support'),
  ])
  String? content;
}

/// Vendor and internal support for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-SUP')
class ToolSupport {
  @Form([
    Field('vendorSupportTier', String, 'Vendor Support Tier',
        hint:
            'CommunityOnly / Basic / Standard / Premium / '
            'Enterprise24x7'),
    Field('vendorSupportUrl', String, 'Vendor Support URL',
        hint: 'Link to vendor support portal or ticketing'),
    Field('vendorSla', String, 'Vendor SLA',
        hint:
            'Response/resolution SLA, e.g. P1: 1h response, 4h '
            'resolution'),
    Field('internalSupportTeam', String, 'Internal Support Team',
        hint: 'Internal team providing L1/L2 support for this tool'),
    Field('internalSupportChannel', String, 'Internal Support Channel',
        hint: 'Slack channel, email alias, or ServiceNow queue'),
    Field('escalationPath', String, 'Escalation Path',
        hint:
            'L1 Internal → L2 Internal → Vendor Support → Account '
            'Manager'),
    Field('knownIssues', String, 'Known Issues',
        hint:
            'Current known issues or limitations affecting the project'),
  ])
  String? content;
}

/// Security and compliance for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-SEC')
class ToolSecurity {
  @Form([
    Field('securityClassification', String, 'Security Classification',
        hint: 'Public / Internal / Confidential / Restricted'),
    Field('dataResidency', String, 'Data Residency',
        hint:
            'Where data is stored geographically — EU, US, '
            'vendor-managed, self-hosted'),
    Field('dataClassification', String, 'Data Classification',
        hint:
            'What data flows through this tool — PII, source code, '
            'secrets, public'),
    Field('auditLogging', String, 'Audit Logging',
        hint:
            'Yes / No / Partial — what actions are logged, retention '
            'period'),
    Field('complianceCertifications', String, 'Compliance Certifications',
        hint: 'SOC2 / ISO27001 / HIPAA / GDPR / FedRAMP / PCI-DSS'),
    Field('securityReviewDate', String, 'Last Security Review Date',
        hint: 'When the tool was last security-assessed'),
    Field('securityReviewOutcome', String, 'Security Review Outcome',
        hint: 'Approved / ConditionalApproval / Rejected / Pending'),
    Field('vulnerabilityScanPolicy', String, 'Vulnerability Scan Policy',
        hint:
            'How the tool is scanned — vendor responsibility, internal '
            'pen-test'),
    Field('encryptionAtRest', String, 'Encryption at Rest',
        hint: 'AES-256, vendor-managed keys, customer-managed keys'),
    Field('encryptionInTransit', String, 'Encryption in Transit',
        hint: 'TLS 1.2+, mTLS, certificate pinning'),
    Field('dataRetentionPolicy', String, 'Data Retention Policy',
        hint: 'How long data is retained, purge schedule, legal holds'),
    Field('gdprCompliance', String, 'GDPR Compliance',
        hint:
            'DPA signed, data subject request process, right to '
            'erasure'),
    Field('ipRestrictions', String, 'IP Restrictions',
        hint: 'IP allowlist, VPN-only access, geo-blocking'),
  ])
  String? content;
}

/// Usage patterns and adoption metrics for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-USE')
class ToolUsage {
  @Form([
    Field('userGroups', String, 'User Groups',
        hint:
            'Teams or roles using this tool — Backend, Frontend, QA, '
            'DevOps, PM, All'),
    Field('activeUserCount', String, 'Active User Count',
        hint: 'Number of active users, e.g. 45 / 50 licenses'),
    Field('usageFrequency', String, 'Usage Frequency',
        hint: 'Daily / Weekly / PerSprint / OnDemand / Continuous'),
    Field('peakUsagePeriod', String, 'Peak Usage Period',
        hint:
            'When usage spikes — release days, sprint planning, '
            'incident response'),
    Field('trainingRequired', String, 'Training Required',
        hint:
            'Yes / No — what training, how long, mandatory or optional'),
    Field('trainingMaterial', String, 'Training Material',
        hint:
            'Links to training resources — vendor courses, internal '
            'guides, videos'),
    Field('proficiencyLevels', String, 'Proficiency Levels',
        hint:
            'Beginner / Intermediate / Advanced — expected proficiency '
            'per role'),
    Field('adoptionStatus', String, 'Adoption Status',
        hint:
            'Piloting / RollingOut / FullyAdopted / Declining / '
            'Sunsetting'),
    Field('adoptionPercentage', String, 'Adoption Percentage',
        hint: 'Percentage of target users actively using the tool'),
    Field('userSatisfactionScore', String, 'User Satisfaction Score',
        hint: 'Latest survey score, e.g. 4.2/5, NPS +35'),
  ])
  String? content;
}

/// Infrastructure and hosting for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-INF')
class ToolInfrastructure {
  @Form([
    Field('hostingModel', String, 'Hosting Model',
        hint: 'SaaS / OnPremise / Hybrid / SelfHostedCloud / PaaS'),
    Field('instanceCount', String, 'Instance Count',
        hint:
            'Number of instances — 1 SaaS tenant, 3 on-prem servers, '
            'etc.'),
    Field('instanceUrls', String, 'Instance URLs',
        hint:
            'URLs for each instance, e.g. prod: tools.example.com, '
            'dev: tools-dev.example.com'),
    Field('resourceRequirements', String, 'Resource Requirements',
        hint:
            'CPU, memory, disk, network — for self-hosted deployments'),
    Field('scalabilityLimits', String, 'Scalability Limits',
        hint:
            'Known limits — max users, max repos, max artifacts, max '
            'concurrent builds'),
    Field('backupResponsibility', String, 'Backup Responsibility',
        hint:
            'Vendor / Internal / Shared — backup strategy and frequency'),
    Field('backupFrequency', String, 'Backup Frequency',
        hint: 'Daily / Hourly / Continuous / PerRelease'),
    Field('disasterRecoveryPlan', String, 'Disaster Recovery Plan',
        hint: 'Failover strategy, RTO/RPO, tested restore process'),
    Field('uptimeSla', String, 'Uptime SLA',
        hint: 'Vendor-guaranteed uptime, e.g. 99.95%'),
    Field('statusPageUrl', String, 'Status Page URL',
        hint: 'Link to vendor status page for outage tracking'),
    Field('maintenanceWindow', String, 'Maintenance Window',
        hint: 'Scheduled maintenance times, e.g. Sun 02:00-06:00 UTC'),
  ])
  String? content;
}

/// Lifecycle management for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-LCY')
class ToolLifecycle {
  @Form([
    Field('introductionDate', String, 'Introduction Date',
        hint: 'When the tool was adopted or will be introduced'),
    Field('lastEvaluationDate', String, 'Last Evaluation Date',
        hint: 'When the tool was last formally reviewed'),
    Field('nextEvaluationDate', String, 'Next Evaluation Date',
        hint: 'When the next review is scheduled'),
    Field('plannedRetirementDate', String, 'Planned Retirement Date',
        hint: 'Scheduled end-of-use date, if known'),
    Field('replacementTool', String, 'Replacement Tool',
        hint: 'Tool that will replace this one upon retirement'),
    Field('migrationPath', String, 'Migration Path',
        hint:
            'High-level migration plan — data export, re-training, '
            'parallel run'),
    Field('migrationEffort', String, 'Migration Effort',
        hint: 'Estimated effort to migrate — person-days, complexity'),
    Field('vendorRoadmapAlignment', String, 'Vendor Roadmap Alignment',
        hint:
            'How well vendor roadmap aligns with project needs — '
            'Strong / Moderate / Weak'),
    Field('endOfLifeRisk', String, 'End-of-Life Risk',
        hint:
            'Low / Medium / High — risk of vendor discontinuing the '
            'product'),
  ])
  String? content;
}

/// Cost structure and budget for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-CST')
class ToolCost {
  @Form([
    Field('initialCost', String, 'Initial Cost',
        hint: 'One-time setup, migration, and integration cost'),
    Field('recurringCost', String, 'Recurring Cost',
        hint: 'Annual or monthly ongoing cost'),
    Field('costModel', String, 'Cost Model',
        hint: 'PerUser / FlatRate / UsageBased / Tiered / Free'),
    Field('costCenter', String, 'Cost Center',
        hint: 'Cost center or billing code for chargeback'),
    Field('budgetOwner', String, 'Budget Owner',
        hint: 'Person or team responsible for the tool budget'),
    Field('costTrend', String, 'Cost Trend',
        hint:
            'Increasing / Stable / Decreasing — recent cost trajectory '
            'and drivers'),
    Field('costOptimizationNotes', String, 'Cost Optimization Notes',
        hint:
            'Ways to reduce cost — right-sizing, license consolidation, '
            'tier change'),
  ])
  String? content;
}

/// Configuration standards for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-CFG')
class ToolConfiguration {
  @Form([
    Field('standardConfiguration', String, 'Standard Configuration',
        hint:
            'Baseline settings all users must apply — e.g. '
            '.editorconfig, analysis_options'),
    Field('mandatoryPlugins', String, 'Mandatory Plugins',
        hint:
            'Plugins required for compliance — e.g. security scanner, '
            'formatter'),
    Field('recommendedPlugins', String, 'Recommended Plugins',
        hint: 'Encouraged but optional plugins'),
    Field('prohibitedFeatures', String, 'Prohibited Features',
        hint:
            'Features disabled for security/compliance — e.g. public '
            'sharing, AI code completion'),
    Field('configurationRepository', String, 'Configuration Repository',
        hint:
            'Where shared config files are stored — repo path, wiki '
            'link'),
    Field('configurationAsCode', String, 'Configuration as Code',
        hint:
            'Yes / No / Partial — whether tool config is '
            'version-controlled'),
  ])
  String? content;
}

/// Documentation resources for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-DOC')
class ToolDocumentation {
  @Form([
    Field('vendorDocumentationUrl', String, 'Vendor Documentation URL',
        hint: 'Link to official product documentation'),
    Field('internalWikiUrl', String, 'Internal Wiki / Guide URL',
        hint: 'Link to internal documentation, runbooks, or wiki'),
    Field('quickStartGuideUrl', String, 'Quick-Start Guide URL',
        hint: 'Link to internal quick-start guide for new users'),
    Field('troubleshootingGuideUrl', String, 'Troubleshooting Guide URL',
        hint: 'Link to common issues and solutions'),
    Field('architectureDiagramUrl', String, 'Architecture Diagram URL',
        hint:
            'Link to diagram showing how this tool fits in the overall '
            'toolchain'),
  ])
  String? content;
}

/// Approval status and ownership for a tool.
@SectionId('PD00-POP-TOO-TOO-ENT-APR')
class ToolApproval {
  @Form([
    Field('approvalStatus', String, 'Approval Status',
        hint:
            'Proposed / UnderReview / Approved / Rejected / Deprecated'),
    Field('approvedBy', String, 'Approved By',
        hint: 'Name or role of the person who approved this tool'),
    Field('approvalDate', String, 'Approval Date',
        hint: 'When the tool was formally approved'),
    Field('toolOwner', String, 'Tool Owner',
        hint: 'Person or team accountable for the tool lifecycle'),
    Field('toolChampion', String, 'Tool Champion',
        hint: 'Internal advocate driving adoption and best practices'),
  ])
  String? content;
}

/// 2.4.2. Environments [PD00-POP-TOO-ENV].
///
/// Operational overview of project environments and the inventory of
/// individual environment instances. Strategy-level decisions (tier
/// definitions, parity goals, ephemeral environments) live in the
/// companion EnvironmentStrategy class under the Technical Framework.
@SectionId('PD00-POP-TOO-ENV')
class Environments {
  @Form([
    Field('promotionPath', String, 'Promotion Path',
        hint: 'Deployment flow, e.g. Dev -> QA -> Staging -> Prod'),
    Field('environmentTopology', String, 'Environment Topology',
        hint:
            'High-level network/architecture topology across environments'),
    Field('namingConvention', String, 'Naming Convention',
        hint:
            'Resource naming pattern, e.g. {project}-{env}-{service}-{region}'),
    Field('environmentCount', String, 'Environment Count',
        hint: 'Total number of permanent and ephemeral environments'),
    Field('defaultRefreshPolicy', String, 'Default Refresh Policy',
        hint:
            'Standard data/infra refresh cadence applied unless overridden'),
    Field('sharedServicesOverview', String, 'Shared Services Overview',
        hint:
            'Services shared across environments, e.g. IAM, DNS, logging'),
    Field('notes', String, 'Notes',
        hint: 'Additional environment overview notes'),
  ])
  String? content;

  /// Contains 0+× Environment.
  @SectionIdPattern('PD00-POP-TOO-ENV-xx')
  List<EnvironmentEntry> items = [];
}

/// An environment entry (form) [PD00-POP-TOO-ENV-nn].
///
/// Comprehensive specification of a single project environment covering
/// identity, infrastructure, access, data management, configuration,
/// availability, connectivity, monitoring, lifecycle, ownership, cost,
/// and compliance. Aligns with PMBOK resource planning, ITIL service
/// design, and PRINCE2 technical stage planning concerns.
@SectionId('PD00-POP-TOO-ENV-ENT')
class EnvironmentEntry {
  @Form([
    Field('environmentName', String, 'Environment Name',
        hint: 'Canonical name, e.g. Production, Staging-EU, Dev-Feature',
        required: true),
    Field('environmentId', String, 'Environment ID',
        hint: 'Unique code, e.g. ENV-PROD-01'),
    Field('environmentType', String, 'Environment Type',
        hint: 'Development / Testing / QA / UAT / Staging / Production / DR'),
  ])
  String? content;

  /// Identity and classification details.
  final EnvironmentIdentity identity = EnvironmentIdentity();

  /// Infrastructure configuration.
  final EnvironmentInfrastructure infrastructure = EnvironmentInfrastructure();

  /// Access and security configuration.
  final EnvironmentSecurity security = EnvironmentSecurity();

  /// Data management policies.
  final EnvironmentDataManagement dataManagement = EnvironmentDataManagement();

  /// Configuration and versions.
  final EnvironmentConfiguration configuration = EnvironmentConfiguration();

  /// Availability and SLA targets.
  final EnvironmentAvailability availability = EnvironmentAvailability();

  /// Connectivity and network configuration.
  final EnvironmentConnectivity connectivity = EnvironmentConnectivity();

  /// Monitoring and observability.
  final EnvironmentMonitoring monitoring = EnvironmentMonitoring();

  /// Lifecycle and provisioning.
  final EnvironmentLifecycle lifecycle = EnvironmentLifecycle();

  /// Ownership and support contacts.
  final EnvironmentOwnership ownership = EnvironmentOwnership();

  /// Cost and billing.
  final EnvironmentCost cost = EnvironmentCost();

  /// Compliance and audit requirements.
  final EnvironmentCompliance compliance = EnvironmentCompliance();
}

/// Identity and classification for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-IDN')
class EnvironmentIdentity {
  @Form([
    Field('purpose', String, 'Purpose',
        hint: 'Business purpose — what this environment is used for'),
    Field('tierClassification', String, 'Tier Classification',
        hint: 'Tier 0 (Prod) / Tier 1 (Staging) / Tier 2 (QA) / Tier 3 (Dev)'),
    Field('promotionPosition', String, 'Promotion Position',
        hint: 'Position in promotion path, e.g. 3 of 4 (before Prod)'),
  ])
  String? content;
}

/// Infrastructure configuration for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-INF')
class EnvironmentInfrastructure {
  @Form([
    Field('hostingModel', String, 'Hosting Model',
        hint: 'Cloud / OnPremise / Hybrid / CoLocated'),
    Field('cloudProvider', String, 'Cloud Provider',
        hint: 'AWS / Azure / GCP / PrivateCloud / MultiCloud'),
    Field('region', String, 'Region',
        hint: 'Deployment region(s), e.g. eu-west-1, eastus2'),
    Field('availabilityZones', String, 'Availability Zones',
        hint: 'AZs used, e.g. eu-west-1a, eu-west-1b'),
    Field('computeResources', String, 'Compute Resources',
        hint: 'Instance types, vCPU, RAM, e.g. 3x m5.xlarge (4 vCPU, 16 GB)'),
    Field('storageResources', String, 'Storage Resources',
        hint: 'Disk, object storage, managed DB storage sizes'),
    Field('networkConfiguration', String, 'Network Configuration',
        hint: 'VPC/VNet, subnets, CIDR ranges'),
    Field('containerPlatform', String, 'Container Platform',
        hint: 'Kubernetes / ECS / Docker Compose / None — cluster details'),
  ])
  String? content;
}

/// Access and security for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-SEC')
class EnvironmentSecurity {
  @Form([
    Field('accessControlModel', String, 'Access Control Model',
        hint: 'RBAC / ABAC / NetworkBased / Combined'),
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'SSO, MFA, service accounts, API keys'),
    Field('authorizedRoles', String, 'Authorized Roles',
        hint: 'Roles/teams with access, e.g. DevOps, QA, Developers'),
    Field('vpnRequired', String, 'VPN Required',
        hint: 'Yes / No — whether VPN/private network access is required'),
    Field('securityClassification', String, 'Security Classification',
        hint: 'Public / Internal / Confidential / Restricted'),
    Field('encryptionAtRest', String, 'Encryption at Rest',
        hint: 'AES-256, KMS key, HSM-backed — scope'),
    Field('encryptionInTransit', String, 'Encryption in Transit',
        hint: 'TLS 1.3 / mTLS / VPN tunnel requirements'),
    Field('secretsManagement', String, 'Secrets Management',
        hint: 'Vault, AWS Secrets Manager, Azure Key Vault'),
  ])
  String? content;
}

/// Data management for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-DAT')
class EnvironmentDataManagement {
  @Form([
    Field('dataClassification', String, 'Data Classification',
        hint: 'Production / Anonymized / Synthetic / Subset / Empty'),
    Field('dataRefreshStrategy', String, 'Data Refresh Strategy',
        hint: 'How data is populated — snapshot restore, ETL, seed scripts'),
    Field('dataRefreshFrequency', String, 'Data Refresh Frequency',
        hint: 'Daily / Weekly / OnDemand / PerRelease'),
    Field('dataRetentionPolicy', String, 'Data Retention Policy',
        hint: 'How long data is kept, archival rules'),
    Field('backupStrategy', String, 'Backup Strategy',
        hint: 'Backup frequency, retention period, tested restore cadence'),
    Field('dataResidency', String, 'Data Residency',
        hint: 'Geographic/legal constraints for data storage'),
  ])
  String? content;
}

/// Configuration and versions for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-CFG')
class EnvironmentConfiguration {
  @Form([
    Field('operatingSystem', String, 'Operating System',
        hint: 'OS and version, e.g. Ubuntu 22.04 LTS'),
    Field('runtimeVersions', String, 'Runtime Versions',
        hint: 'Language/framework versions, e.g. Dart 3.5, Node 20 LTS'),
    Field('databaseVersions', String, 'Database Versions',
        hint: 'DB engine(s) and version(s), e.g. PostgreSQL 16, Redis 7'),
    Field('middleware', String, 'Middleware',
        hint: 'Message queues, caches, search engines, e.g. RabbitMQ 3.13'),
    Field('featureFlagConfig', String, 'Feature Flag Configuration',
        hint: 'Environment-specific feature flag overrides'),
    Field('configurationMethod', String, 'Configuration Method',
        hint: 'Env vars / Secrets Manager / Config files / Consul'),
  ])
  String? content;
}

/// Availability and SLA for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-AVL')
class EnvironmentAvailability {
  @Form([
    Field('uptimeRequirement', String, 'Uptime Requirement',
        hint: 'Target availability, e.g. 99.95%'),
    Field('maintenanceWindow', String, 'Maintenance Window',
        hint: 'Scheduled window, e.g. Sun 02:00-06:00 UTC'),
    Field('slaTarget', String, 'SLA Target',
        hint: 'Response/resolution times for incidents'),
    Field('rpo', String, 'Recovery Point Objective',
        hint: 'Max acceptable data loss, e.g. 1 hour'),
    Field('rto', String, 'Recovery Time Objective',
        hint: 'Max acceptable downtime, e.g. 4 hours'),
    Field('disasterRecoveryPlan', String, 'Disaster Recovery Plan',
        hint: 'DR strategy — warm standby, pilot light, active-active'),
  ])
  String? content;
}

/// Connectivity and network for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-CON')
class EnvironmentConnectivity {
  @Form([
    Field('networkZone', String, 'Network Zone',
        hint: 'DMZ / Internal / Management / Restricted'),
    Field('firewallRules', String, 'Firewall Rules',
        hint: 'Key inbound/outbound rules summary'),
    Field('integrationEndpoints', String, 'Integration Endpoints',
        hint: 'External/internal APIs this env connects to'),
    Field('dnsConfiguration', String, 'DNS Configuration',
        hint: 'DNS entries, e.g. staging.example.com -> ALB'),
    Field('loadBalancer', String, 'Load Balancer',
        hint: 'LB type and config, e.g. ALB with path-based routing'),
    Field('serviceDiscovery', String, 'Service Discovery',
        hint: 'DNS-based / Service mesh / Consul / K8s Services'),
  ])
  String? content;
}

/// Monitoring and observability for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-MON')
class EnvironmentMonitoring {
  @Form([
    Field('monitoringTools', String, 'Monitoring Tools',
        hint: 'APM and infra monitoring, e.g. Datadog, CloudWatch'),
    Field('loggingPlatform', String, 'Logging Platform',
        hint: 'Centralized logging, e.g. ELK, CloudWatch Logs, Loki'),
    Field('alertingConfiguration', String, 'Alerting Configuration',
        hint: 'Alert rules, channels, thresholds, escalation'),
    Field('dashboardUrl', String, 'Dashboard URL',
        hint: 'Monitoring/status dashboard URL'),
    Field('healthCheckEndpoints', String, 'Health Check Endpoints',
        hint: 'Health and readiness probe paths'),
  ])
  String? content;
}

/// Lifecycle and provisioning for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-LCY')
class EnvironmentLifecycle {
  @Form([
    Field('provisioningMethod', String, 'Provisioning Method',
        hint: 'Manual / Terraform / CloudFormation / Pulumi / Helm'),
    Field('iacRepository', String, 'IaC Repository',
        hint: 'Repo/path where infrastructure code lives'),
    Field('refreshCadence', String, 'Refresh Cadence',
        hint: 'How often the environment is rebuilt or refreshed'),
    Field('decommissionPlan', String, 'Decommission Plan',
        hint: 'End-of-life steps, data migration, DNS cleanup'),
    Field('creationDate', String, 'Creation Date',
        hint: 'When the environment was or will be provisioned'),
    Field('plannedRetirementDate', String, 'Planned Retirement Date',
        hint: 'Scheduled decommission date, if known'),
  ])
  String? content;
}

/// Ownership and support for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-OWN')
class EnvironmentOwnership {
  @Form([
    Field('environmentOwner', String, 'Environment Owner',
        hint: 'Team or individual responsible for this environment'),
    Field('supportContact', String, 'Support Contact',
        hint: 'Primary support contact or on-call team'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'Escalation chain, e.g. L1 -> L2 -> Platform Lead'),
    Field('changeApprovalProcess', String, 'Change Approval Process',
        hint: 'How changes are approved — CAB, PR review, auto-deploy'),
  ])
  String? content;
}

/// Cost and billing for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-CST')
class EnvironmentCost {
  @Form([
    Field('monthlyCostEstimate', String, 'Monthly Cost Estimate',
        hint: 'Estimated cost per month'),
    Field('billingModel', String, 'Billing Model',
        hint: 'PayAsYouGo / Reserved / SavingsPlan / Spot'),
    Field('costCenter', String, 'Cost Center',
        hint: 'Cost center or billing code for chargeback'),
    Field('budgetAlertThreshold', String, 'Budget Alert Threshold',
        hint: 'Spending threshold that triggers alerts'),
  ])
  String? content;
}

/// Compliance and audit for environment entry.
@SectionId('PD00-POP-TOO-ENV-ENT-CPL')
class EnvironmentCompliance {
  @Form([
    Field('complianceFrameworks', String, 'Compliance Frameworks',
        hint: 'SOC 2, HIPAA, GDPR, PCI-DSS, ISO 27001'),
    Field('auditLogging', String, 'Audit Logging',
        hint: 'Audit trail scope — access, changes, data operations'),
    Field('penetrationTestSchedule', String, 'Penetration Test Schedule',
        hint: 'Frequency and scope of security testing'),
    Field('notes', String, 'Notes',
        hint: 'Additional environment-specific notes'),
  ])
  String? content;
}
