/// Section 14: Delivery Scope and Acceptance [PD00-DEL].
///
/// Agreements regarding delivery scope and acceptance for the system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 14. Delivery Scope and Acceptance [PD00-DEL].
@SectionId('PD00-DEL')
class DeliveryScopeAndAcceptance {
  @ContentHelp('''
Chapter overview: defines agreements regarding delivery scope and acceptance
for the system. Covers two major subsections:
- 14.1. Delivery and Service Scope — what is delivered (software, documentation,
  training, support)
- 14.2. Acceptance Plan — how deliverables are accepted (criteria, process, UAT,
  defect resolution, sign-off, warranty)

Seeds the BQP (Business Quality Plan) document for full quality planning.
All deliverable and acceptance definitions should be objectively verifiable
and contractually precise.
''')
  String? content;

  /// 14.1. Delivery and Service Scope [PD00-DEL-DEL].
  DeliveryScope deliveryScope = DeliveryScope();

  /// 14.2. Acceptance Plan [PD00-DEL-ACC]. Seeds → BQP.
  @Comment('Seeds → BQP')
  AcceptancePlan acceptancePlan = AcceptancePlan();
}

/// 14.1. Delivery and Service Scope [PD00-DEL-DEL].
@SectionId('PD00-DEL-DEL')
class DeliveryScope {
  @ContentHelp('''
Defines what is delivered as part of this project across four categories:
- Software deliverables (application components, libraries, configurations)
- Documentation deliverables (user, technical, operations docs)
- Training deliverables (sessions, materials, train-the-trainer)
- Support deliverables (transition support, warranty, ongoing support)

Each deliverable entry specifies format, delivery mechanism, acceptance
criteria, and responsible party. Deliverables are contractually binding
commitments.
''')
  String? content;

  /// 14.1.1. Software Deliverables [PD00-DEL-DEL-SOF].
  SoftwareDeliverables softwareDeliverables = SoftwareDeliverables();

  /// 14.1.2. Documentation Deliverables [PD00-DEL-DEL-DOC].
  DocumentationDeliverables documentationDeliverables = DocumentationDeliverables();

  /// 14.1.3. Training Deliverables [PD00-DEL-DEL-TRA].
  TrainingDeliverables trainingDeliverables = TrainingDeliverables();

  /// 14.1.4. Support Deliverables [PD00-DEL-DEL-SUP].
  SupportDeliverables supportDeliverables = SupportDeliverables();
}

/// 14.1.1. Software Deliverables [PD00-DEL-DEL-SOF].
@SectionId('PD00-DEL-DEL-SOF')
class SoftwareDeliverables {
  @ContentHelp('''
Software deliverables: application components, libraries, tools, scripts,
configuration files, deployment artifacts. Define for each:
- Delivery format (container images, packages, installers, source code)
- Delivery mechanism (registry, artifact repository, file transfer)
- Version requirements and compatibility constraints
- Licensing terms applicable to the deliverable
- Environment-specific variants (production, staging, development)
''')
  String? content;

  /// Contains 0+× Deliverable.
  @SectionIdPattern('PD00-DEL-DEL-SOF-xx')
  List<DeliverableEntry> items = [];
}

/// 14.1.2. Documentation Deliverables [PD00-DEL-DEL-DOC].
@SectionId('PD00-DEL-DEL-DOC')
class DocumentationDeliverables {
  @ContentHelp('''
Documentation deliverables: user guides, technical documentation,
operations runbooks, API documentation, architecture decision records,
release notes Template. Define format (PDF, HTML, Markdown, wiki),
delivery channel, language(s), and maintenance responsibility post-delivery.
''')
  String? content;

  /// Contains 0+× Deliverable.
  @SectionIdPattern('PD00-DEL-DEL-DOC-xx')
  List<DeliverableEntry> items = [];
}

/// 14.1.3. Training Deliverables [PD00-DEL-DEL-TRA].
@SectionId('PD00-DEL-DEL-TRA')
class TrainingDeliverables {
  @ContentHelp('''
Training deliverables: instructor-led sessions, e-learning modules,
train-the-trainer programs, quick reference cards, video tutorials,
sandbox environments. Define target audience, duration, prerequisites,
assessment criteria, and ongoing refresh schedule.
''')
  String? content;

  /// Contains 0+× Deliverable.
  @SectionIdPattern('PD00-DEL-DEL-TRA-xx')
  List<DeliverableEntry> items = [];
}

/// 14.1.4. Support Deliverables [PD00-DEL-DEL-SUP].
@SectionId('PD00-DEL-DEL-SUP')
class SupportDeliverables {
  @ContentHelp('''
Support deliverables: transition support during go-live, warranty support
post-acceptance, knowledge transfer sessions, escalation contacts,
SLA definitions, support tooling and access. Define support hours,
response times, coverage period, and handover criteria.
''')
  String? content;

  /// Contains 0+× Deliverable.
  @SectionIdPattern('PD00-DEL-DEL-SUP-xx')
  List<DeliverableEntry> items = [];
}

/// A deliverable entry (form) [PD00-DEL-DEL-nn].
///
/// Represents a single deliverable item within any deliverable category.
/// Captures identification, delivery logistics, quality requirements,
/// ownership, and acceptance linkage.
class DeliverableEntry {
  @Form([
    // --- Identification ---
    Field('deliverableId', String, 'Deliverable ID',
        hint: 'Unique identifier — e.g. DEL-SOF-001', required: true),
    Field('deliverableName', String, 'Deliverable Name',
        hint: 'Concise name — e.g. "Customer Management API"',
        required: true),
    Field('description', String, 'Description',
        hint: 'What this deliverable contains and its purpose'),
    Field('category', String, 'Category',
        hint:
            'Application / Library / Tool / Configuration / '
            'Document / Training / Support'),
    Field('priority', String, 'Priority',
        hint: 'Critical / High / Medium / Low — delivery priority'),

    // --- Delivery Logistics ---
    Field('deliveryFormat', String, 'Delivery Format',
        hint:
            'Docker Image / NPM Package / Dart Package / APK / '
            'IPA / PDF / HTML / ZIP / Source Code'),
    Field('deliveryMechanism', String, 'Delivery Mechanism',
        hint:
            'Container Registry / Artifact Repository / App Store / '
            'File Transfer / Git Repository / CDN'),
    Field('deliveryEnvironment', String, 'Target Environment',
        hint:
            'Production / Staging / All Environments — where this is deployed'),
    Field('plannedDeliveryDate', String, 'Planned Delivery Date',
        hint: 'Target date — e.g. 2026-Q3 or specific date'),
    Field('deliveryStage', String, 'Delivery Stage',
        hint: 'Stage in which this deliverable is delivered'),
    Field('deliveryFrequency', String, 'Delivery Frequency',
        hint:
            'OneTime / PerRelease / Continuous / OnDemand — '
            'how often updates are delivered'),

    // --- Version & Compatibility ---
    Field('versionRequirement', String, 'Version Requirement',
        hint: 'Minimum version or version range — e.g. >= 2.0.0'),
    Field('compatibilityConstraints', String, 'Compatibility Constraints',
        hint:
            'Platform, OS, browser, or dependency version requirements'),
    Field('backwardCompatibility', String, 'Backward Compatibility',
        hint:
            'Yes / No / Partial — whether older versions remain supported'),

    // --- Quality & Acceptance ---
    Field('qualityStandard', String, 'Quality Standard',
        hint:
            'Quality standards applied — e.g. ISO 25010, WCAG 2.1 AA'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria',
        hint:
            'Specific criteria for accepting this deliverable — '
            'functional, performance, documentation completeness'),
    Field('verificationMethod', String, 'Verification Method',
        hint:
            'Testing / Inspection / Review / Demonstration — '
            'how acceptance is verified'),
    Field('testCoverage', String, 'Required Test Coverage',
        hint: 'Minimum test coverage — e.g. 80% unit, 90% integration'),

    // --- Ownership & Responsibility ---
    Field('responsibleParty', String, 'Responsible Party',
        hint: 'Team or role responsible for creating the deliverable'),
    Field('reviewer', String, 'Reviewer',
        hint: 'Who reviews and approves before delivery'),
    Field('recipient', String, 'Recipient',
        hint: 'Who receives the deliverable — role or organization'),
    Field('maintenanceOwner', String, 'Maintenance Owner',
        hint: 'Who maintains the deliverable post-delivery'),

    // --- Dependencies ---
    Field('dependsOn', String, 'Depends On',
        hint:
            'Other deliverable IDs or external items this depends on'),
    Field('prerequisiteForDelivery', String, 'Prerequisites',
        hint:
            'Conditions that must be met before delivery — '
            'e.g. environment ready, sign-off on prior stage'),

    // --- Licensing & Legal ---
    Field('licenseType', String, 'License Type',
        hint:
            'Commercial / OpenSource / Proprietary / Mixed — '
            'licensing terms'),
    Field('intellectualProperty', String, 'IP Ownership',
        hint:
            'Who owns the IP — client, vendor, shared'),
    Field('thirdPartyComponents', String, 'Third-Party Components',
        hint:
            'Third-party libraries or data included and their licenses'),

    // --- Documentation ---
    Field('associatedDocumentation', String, 'Associated Documentation',
        hint:
            'Related documentation deliverable IDs — e.g. DEL-DOC-003'),
    Field('releaseNotes', String, 'Release Notes Required',
        hint: 'Yes / No — whether release notes accompany delivery'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or special instructions'),
  ])
  String? content;
}

/// 14.2. Acceptance Plan [PD00-DEL-ACC]. Seeds → BQP.
@SectionId('PD00-DEL-ACC')
@Comment('Seeds → BQP')
class AcceptancePlan {
  @ContentHelp('''
Acceptance plan overview: defines how the project deliverables will be
formally accepted by the client/business. Covers:
- 14.2.1. Acceptance Criteria \u2014 what must be true for acceptance
- 14.2.2. Acceptance Process \u2014 the workflow from testing to sign-off
- 14.2.3. User Acceptance Testing \u2014 detailed UAT plan
- 14.2.4. Defect Resolution \u2014 handling defects found during acceptance
- 14.2.5. Sign-off Process \u2014 formal approval workflow
- 14.2.6. Warranty \u2014 post-acceptance support terms

Seeds the BQP (Business Quality Plan) for comprehensive quality planning.
All criteria must be objectively measurable and verifiable.
''')
  String? content;

  /// 14.2.1. Acceptance Criteria [PD00-DEL-ACC-CRI].
  AcceptanceCriteriaList acceptanceCriteria = AcceptanceCriteriaList();

  /// 14.2.2. Acceptance Process [PD00-DEL-ACC-PRO].
  AcceptanceProcess acceptanceProcess = AcceptanceProcess();

  /// 14.2.3. User Acceptance Testing [PD00-DEL-ACC-UAT].
  UserAcceptanceTesting userAcceptanceTesting = UserAcceptanceTesting();

  /// 14.2.4. Defect Resolution [PD00-DEL-ACC-DEF].
  DefectResolution defectResolution = DefectResolution();

  /// 14.2.5. Sign-off Process [PD00-DEL-ACC-SIG].
  SignOffProcess signOffProcess = SignOffProcess();

  /// 14.2.6. Warranty [PD00-DEL-ACC-WAR].
  WarrantyTerms warranty = WarrantyTerms();
}

/// 14.2.1. Acceptance Criteria [PD00-DEL-ACC-CRI].
@SectionId('PD00-DEL-ACC-CRI')
class AcceptanceCriteriaList {
  @ContentHelp('''
Formal acceptance criteria that must be met for project sign-off.
Covers functional, non-functional, documentation, and training criteria.
Each criterion must be:
- Objectively verifiable (measurable or binary pass/fail)
- Traceable to a requirement or deliverable
- Assigned a verification method and responsible verifier
- Categorized by type and priority
''')
  String? content;

  /// Contains 0+× DeliveryAcceptanceCriterion.
  @SectionIdPattern('PD00-DEL-ACC-CRI-xx')
  List<DeliveryAcceptanceCriterionEntry> items = [];
}

/// An acceptance criterion entry (form) [PD00-DEL-ACC-CRI-nn].
///
/// A single criterion that must be met for formal project acceptance.
/// Aligned with IEEE 830 acceptance criteria structure and ISTQB
/// acceptance test design.
class DeliveryAcceptanceCriterionEntry {
  @Form([
    // --- Criterion Definition ---
    Field('criterionId', String, 'Criterion ID',
        hint: 'Unique identifier — e.g. AC-001', required: true),
    Field('criterion', String, 'Criterion Statement',
        hint: 'Clear, measurable statement of what must be true',
        required: true),
    Field('category', String, 'Category',
        hint:
            'Functional / Performance / Security / Usability / '
            'Documentation / Training / Operational / Compliance'),
    Field('priority', String, 'Priority',
        hint:
            'MustPass / ShouldPass / NiceToPass — relative importance'),
    Field('description', String, 'Detailed Description',
        hint:
            'Extended explanation including context and boundaries'),

    // --- Verification ---
    Field('verificationMethod', String, 'Verification Method',
        hint:
            'Testing / Demonstration / Inspection / Analysis / '
            'Review / CertificatePresentation'),
    Field('verificationProcedure', String, 'Verification Procedure',
        hint:
            'Steps to verify — brief procedure description'),
    Field('acceptanceThreshold', String, 'Acceptance Threshold',
        hint:
            'Quantitative threshold — e.g. response < 2s, uptime >= 99.9%'),
    Field('measurementTool', String, 'Measurement Tool',
        hint:
            'Tool used to measure — e.g. JMeter, Lighthouse, manual checklist'),
    Field('evidenceRequired', String, 'Evidence Required',
        hint:
            'Documentation of proof — test report, screenshot, certificate'),

    // --- Traceability ---
    Field('requirementRef', String, 'Requirement Reference',
        hint: 'Linked requirement ID(s) — e.g. REQ-042'),
    Field('deliverableRef', String, 'Deliverable Reference',
        hint: 'Linked deliverable ID — e.g. DEL-SOF-001'),
    Field('testScenarioRef', String, 'Test Scenario Reference',
        hint: 'UAT scenario ID that validates this criterion'),

    // --- Responsibility ---
    Field('verifier', String, 'Verifier',
        hint: 'Role or person who performs verification'),
    Field('approver', String, 'Approver',
        hint: 'Role or person who confirms acceptance'),

    // --- Status ---
    Field('currentStatus', String, 'Current Status',
        hint:
            'NotTested / Passed / Failed / Conditional / Deferred'),
    Field('notes', String, 'Notes',
        hint: 'Clarifications, exceptions, or conditions'),
  ])
  String? content;
}

/// 14.2.2. Acceptance Process [PD00-DEL-ACC-PRO].
///
/// Defines the formal acceptance workflow from test initiation through
/// final sign-off. Covers roles, responsibilities, timelines, escalation,
/// and decision criteria.
@SectionId('PD00-DEL-ACC-PRO')
class AcceptanceProcess {
  @Form([
    // --- Process Overview ---
    Field('processName', String, 'Process Name',
        hint: 'e.g. "Formal Acceptance Process v2"'),
    Field('processOwner', String, 'Process Owner',
        hint: 'Role responsible for managing the acceptance process'),
    Field('processDescription', String, 'Process Description',
        hint:
            'High-level workflow: initiation → testing → review → sign-off'),
    Field('acceptanceType', String, 'Acceptance Type',
        hint:
            'Formal / Informal / Staged / Conditional — type of acceptance'),

    // --- Participants & Governance ---
    Field('acceptanceBoard', String, 'Acceptance Board',
        hint:
            'Members of the acceptance board — roles or named individuals'),
    Field('technicalReviewers', String, 'Technical Reviewers',
        hint: 'Technical staff who verify technical acceptance criteria'),
    Field('businessReviewers', String, 'Business Reviewers',
        hint: 'Business stakeholders who verify business acceptance'),
    Field('participants', String, 'All Participants',
        hint: 'Complete list of roles involved in the acceptance process'),
    Field('raciMatrix', String, 'RACI Matrix',
        hint:
            'Responsible / Accountable / Consulted / Informed per activity'),

    // --- Timeline & Schedule ---
    Field('plannedDuration', String, 'Planned Duration',
        hint: 'Expected total duration of acceptance process'),
    Field('acceptanceWindowStart', String, 'Acceptance Window Start',
        hint: 'Earliest date acceptance can begin'),
    Field('acceptanceWindowEnd', String, 'Acceptance Window End',
        hint: 'Latest date acceptance must conclude'),
    Field('milestones', String, 'Key Milestones',
        hint:
            'Entry gate, mid-point review, final review, sign-off deadline'),

    // --- Decision Framework ---
    Field('decisionCriteria', String, 'Decision Criteria',
        hint:
            'How accept/reject/conditional decisions are made'),
    Field('defectThreshold', String, 'Acceptable Defect Threshold',
        hint:
            'Maximum open defects by severity to proceed — '
            'e.g. 0 Sev-1, <= 3 Sev-2, unlimited Sev-4'),
    Field('conditionalAcceptanceRules', String,
        'Conditional Acceptance Rules',
        hint:
            'Conditions under which acceptance with known issues is allowed'),
    Field('rejectionCriteria', String, 'Rejection Criteria',
        hint: 'Conditions that automatically block acceptance'),

    // --- Escalation ---
    Field('escalationProcess', String, 'Escalation Process',
        hint:
            'Escalation path for disputes, blockers, or disagreements'),
    Field('escalationLevels', String, 'Escalation Levels',
        hint:
            'L1: Project Manager, L2: Steering Committee, '
            'L3: Executive Sponsor'),
    Field('disputeResolution', String, 'Dispute Resolution',
        hint:
            'How disagreements about acceptance results are resolved'),

    // --- Documentation ---
    Field('acceptanceReportTemplate', String, 'Acceptance Report Template',
        hint: 'Template or format for the formal acceptance report'),
    Field('evidencePackageContents', String, 'Evidence Package Contents',
        hint:
            'What must be in the evidence package: test results, '
            'reports, demonstrations, certificates'),
    Field('archivalRequirements', String, 'Archival Requirements',
        hint:
            'How acceptance evidence is archived — location, retention'),
  ])
  String? content;

  /// Acceptance process narrative description.
  @ContentHelp('Detailed walkthrough of the acceptance process: '
      'step-by-step flow, decision points, parallel tracks, '
      'timing dependencies, and integration with project closeout.')
  TextSection processNarrative = TextSection();

  /// Contains 0+× AcceptanceStep.
  @SectionIdPattern('PD00-DEL-ACC-PRO-xx')
  List<AcceptanceStepEntry> steps = [];
}

/// An acceptance step entry (form) [PD00-DEL-ACC-PRO-nn].
///
/// A single step in the formal acceptance workflow, with entry/exit
/// conditions, responsible parties, and outputs.
class AcceptanceStepEntry {
  @Form([
    Field('stepNumber', String, 'Step Number',
        hint: 'Sequential number — e.g. 1, 2, 3', required: true),
    Field('stepName', String, 'Step Name',
        hint: 'Concise action name — e.g. "Technical Review"',
        required: true),
    Field('description', String, 'Description',
        hint: 'What happens in this step'),
    Field('responsibleRole', String, 'Responsible Role',
        hint: 'Who performs or leads this step'),
    Field('participants', String, 'Participants',
        hint: 'Additional roles involved'),
    Field('entryCriteria', String, 'Entry Criteria',
        hint: 'What must be true before this step can start'),
    Field('activities', String, 'Activities',
        hint: 'Key activities performed in this step'),
    Field('exitCriteria', String, 'Exit Criteria',
        hint: 'What must be true for this step to be complete'),
    Field('outputs', String, 'Outputs',
        hint: 'Documents, decisions, or artifacts produced'),
    Field('duration', String, 'Expected Duration',
        hint: 'How long this step takes — e.g. 2 business days'),
    Field('decisionOptions', String, 'Decision Options',
        hint:
            'Possible outcomes — e.g. Pass / Fail / Conditional / '
            'Escalate'),
  ])
  String? content;
}

/// 14.2.3. User Acceptance Testing [PD00-DEL-ACC-UAT].
///
/// Comprehensive UAT planning covering scope, environment, test data,
/// governance, scheduling, defect management, reporting, non-functional
/// acceptance, and formal sign-off. Aligned with IEEE 829 / ISO 29119
/// test documentation structure and ISTQB best practices.
@SectionId('PD00-DEL-ACC-UAT')
class UserAcceptanceTesting {
  @Form([
    Field('uatObjective', String, 'UAT Objective',
        hint: 'Primary goal — e.g. validate business requirements before go-live'),
    Field('uatApproach', String, 'UAT Approach',
        hint: 'Scripted / Exploratory / Hybrid'),
    Field('uatLead', String, 'UAT Lead',
        hint: 'Name and role of the person coordinating UAT'),
  ])
  String? content;

  /// Scope and objectives.
  final UatScope scope = UatScope();

  /// Environment.
  final UatEnvironment environment = UatEnvironment();

  /// Test data.
  final UatTestData testData = UatTestData();

  /// Participants and governance.
  final UatGovernance governance = UatGovernance();

  /// Schedule and cycles.
  final UatSchedule schedule = UatSchedule();

  /// Entry, exit, and suspension criteria.
  final UatCriteria criteria = UatCriteria();

  /// Defect management.
  final UatDefectManagement defectManagement = UatDefectManagement();

  /// Reporting.
  final UatReporting reporting = UatReporting();

  /// Non-functional acceptance.
  final UatNonFunctional nonFunctional = UatNonFunctional();

  /// Sign-off.
  final UatSignOff signOff = UatSignOff();

  /// Training and readiness.
  final UatTraining training = UatTraining();

  /// Narrative overview of the UAT approach and philosophy.
  @ContentHelp('Describe the UAT philosophy, how it integrates with prior '
      'test levels, key risks, and lessons from previous projects.')
  TextSection uatOverview = TextSection();

  /// Contains 0+× UatTestCycle.
  @SectionIdPattern('PD00-DEL-ACC-UAT-CYC-xx')
  List<UatTestCycleEntry> testCycles = [];

  /// Contains 0+× TestScenario.
  @SectionIdPattern('PD00-DEL-ACC-UAT-xx')
  List<TestScenarioEntry> testScenarios = [];
}

/// Scope and objectives for UAT.
class UatScope {
  @Form([
    Field('scope', String, 'Scope Summary',
        hint: 'Modules, features, and integrations included in UAT'),
    Field('outOfScope', String, 'Out of Scope',
        hint: 'Explicitly excluded items'),
    Field('testTypes', String, 'Test Types Included',
        hint: 'Functional / Regression / Usability / Accessibility / End-to-End'),
  ])
  String? content;
}

/// Environment for UAT.
class UatEnvironment {
  @Form([
    Field('environmentName', String, 'Environment Name',
        hint: 'Name or identifier of the UAT environment'),
    Field('environmentUrl', String, 'Environment URL',
        hint: 'Access URL or endpoint'),
    Field('environmentDescription', String, 'Environment Description',
        hint: 'Hardware, OS, software stack, network configuration'),
    Field('environmentRefreshPolicy', String, 'Environment Refresh Policy',
        hint: 'How and when environment data is refreshed'),
    Field('environmentAccessControl', String, 'Access Control',
        hint: 'Who has access, authentication method'),
  ])
  String? content;
}

/// Test data for UAT.
class UatTestData {
  @Form([
    Field('testDataStrategy', String, 'Test Data Strategy',
        hint: 'Synthetic / MaskedProduction / Subset'),
    Field('testDataPreparation', String, 'Test Data Preparation',
        hint: 'Who prepares test data, lead time, and tools used'),
    Field('testDataPrivacy', String, 'Data Privacy Compliance',
        hint: 'GDPR / HIPAA / PCI-DSS compliance'),
    Field('testDataRefreshCadence', String, 'Test Data Refresh Cadence',
        hint: 'How often test data is refreshed'),
  ])
  String? content;
}

/// Governance for UAT.
class UatGovernance {
  @Form([
    Field('businessOwner', String, 'Business Owner',
        hint: 'Stakeholder accountable for UAT sign-off'),
    Field('testerRoles', String, 'Tester Roles',
        hint: 'Business analysts, end-users, SMEs, external testers'),
    Field('supportTeam', String, 'Support Team',
        hint: 'Dev, QA, and ops contacts available during UAT'),
    Field('raciSummary', String, 'RACI Summary',
        hint: 'Responsible / Accountable / Consulted / Informed'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'Escalation chain for blocking defects'),
    Field('communicationPlan', String, 'Communication Plan',
        hint: 'Status update frequency, channels, and audience'),
  ])
  String? content;
}

/// Schedule for UAT.
class UatSchedule {
  @Form([
    Field('plannedStartDate', String, 'Planned Start Date',
        hint: 'Target start date for UAT execution'),
    Field('plannedEndDate', String, 'Planned End Date',
        hint: 'Target completion date'),
    Field('numberOfCycles', String, 'Number of Test Cycles',
        hint: 'e.g. 2 cycles — initial execution + regression'),
    Field('cycleDuration', String, 'Cycle Duration',
        hint: 'Expected duration per cycle'),
    Field('milestones', String, 'Key Milestones',
        hint: 'Entry gate, mid-cycle checkpoint, exit gate'),
  ])
  String? content;
}

/// Criteria for UAT.
class UatCriteria {
  @Form([
    Field('entryCriteria', String, 'Entry Criteria',
        hint: 'Prerequisites: system testing passed, environment ready'),
    Field('exitCriteria', String, 'Exit Criteria',
        hint: 'Completion conditions: pass rate >= 95%, no Sev-1 open'),
    Field('suspensionCriteria', String, 'Suspension Criteria',
        hint: 'Conditions that halt UAT'),
    Field('resumptionCriteria', String, 'Resumption Criteria',
        hint: 'Conditions to restart after suspension'),
  ])
  String? content;
}

/// Defect management for UAT.
class UatDefectManagement {
  @Form([
    Field('defectTool', String, 'Defect Tracking Tool',
        hint: 'Jira / Azure DevOps / ServiceNow'),
    Field('defectSeverityLevels', String, 'Severity Levels',
        hint: 'Define Sev-1 through Sev-4 with examples'),
    Field('defectResolutionSla', String, 'Resolution SLAs',
        hint: 'Target fix times per severity'),
    Field('defectThreshold', String, 'Acceptable Defect Threshold',
        hint: 'Max open defects per severity to proceed'),
    Field('defectTriageProcess', String, 'Triage Process',
        hint: 'Frequency, participants, and decision-making'),
    Field('retestProcess', String, 'Retest Process',
        hint: 'How fixed defects are retested'),
  ])
  String? content;
}

/// Reporting for UAT.
class UatReporting {
  @Form([
    Field('dailyStatusFormat', String, 'Daily Status Format',
        hint: 'Contents: executed, passed, failed, blocked'),
    Field('metricsTracked', String, 'Metrics Tracked',
        hint: 'Pass rate, defect density, test coverage'),
    Field('dashboardTool', String, 'Dashboard Tool',
        hint: 'Tool for real-time UAT metrics'),
    Field('finalReportContents', String, 'Final Report Contents',
        hint: 'Summary, results matrix, open defects'),
  ])
  String? content;
}

/// Non-functional acceptance for UAT.
class UatNonFunctional {
  @Form([
    Field('accessibilityAcceptance', String, 'Accessibility Acceptance',
        hint: 'WCAG level, screen-reader compatibility'),
    Field('performanceAcceptance', String, 'Performance Acceptance',
        hint: 'Response time thresholds, concurrent users'),
    Field('securityAcceptance', String, 'Security Acceptance',
        hint: 'Authentication, authorization, data checks'),
    Field('regressionApproach', String, 'Regression Approach',
        hint: 'Scope and method for regression testing'),
  ])
  String? content;
}

/// Sign-off for UAT.
class UatSignOff {
  @Form([
    Field('signOffAuthority', String, 'Sign-Off Authority',
        hint: 'Role(s) authorized to provide formal UAT sign-off'),
    Field('signOffCriteria', String, 'Sign-Off Criteria',
        hint: 'Exit criteria + risk acceptance conditions'),
    Field('conditionalAcceptancePolicy', String, 'Conditional Acceptance Policy',
        hint: 'Conditions under which UAT passes with known defects'),
  ])
  String? content;
}

/// Training and readiness for UAT.
class UatTraining {
  @Form([
    Field('testerTraining', String, 'Tester Training',
        hint: 'Training provided: system walkthrough, tool orientation'),
    Field('userDocumentation', String, 'User Documentation Availability',
        hint: 'Guides, FAQs, and quick-start docs available'),
  ])
  String? content;
}

/// A UAT test cycle entry [PD00-DEL-ACC-UAT-CYC-nn].
///
/// Represents a distinct test execution round — e.g. Cycle 1 (initial),
/// Cycle 2 (regression/retest). Each cycle defines scope, dates, entry/exit
/// criteria, and focus areas per IEEE 829 Level Test Plan structure.
class UatTestCycleEntry {
  @Form([
    Field('cycleName', String, 'Cycle Name',
        hint:
            'e.g. "Cycle 1 — Initial Execution" or "Regression Cycle"',
        required: true),
    Field('cycleObjective', String, 'Cycle Objective',
        hint:
            'Purpose: full execution, regression, retest only, or targeted'),
    Field('plannedStartDate', String, 'Planned Start Date',
        hint: 'Start date for this cycle'),
    Field('plannedEndDate', String, 'Planned End Date',
        hint: 'End date for this cycle'),
    Field('scenariosInScope', String, 'Scenarios in Scope',
        hint: 'Scenario IDs or categories included in this cycle'),
    Field('focusAreas', String, 'Focus Areas',
        hint: 'Specific modules, features, or risk areas targeted'),
    Field('entryCriteria', String, 'Cycle Entry Criteria',
        hint:
            'Prerequisites specific to this cycle — e.g. prior cycle passed'),
    Field('exitCriteria', String, 'Cycle Exit Criteria',
        hint: 'Completion conditions for this cycle'),
    Field('passCriterion', String, 'Pass Criterion',
        hint: 'Required pass rate — e.g. >= 95% of scenarios'),
    Field('assignedTesters', String, 'Assigned Testers',
        hint: 'Tester names/roles allocated for this cycle'),
    Field('riskNotes', String, 'Risk Notes',
        hint: 'Known risks or dependencies for this cycle'),
  ])
  String? content;
}

/// A test scenario entry (form) [PD00-DEL-ACC-UAT-nn].
///
/// Represents a business-level test case covering a user journey, business
/// process, or acceptance criterion. Includes full traceability, preconditions,
/// execution metadata, and pass/fail criteria per ISTQB and IEEE 829
/// Level Test Case / Level Test Procedure structures.
class TestScenarioEntry {
  @Form([
    // --- Identification ---
    Field('scenarioId', String, 'Scenario ID',
        hint: 'Unique identifier — e.g. UAT-SC-001', required: true),
    Field('scenarioName', String, 'Scenario Name',
        hint:
            'Concise name describing the user journey or business process',
        required: true),
    Field('description', String, 'Description',
        hint: 'Detailed narrative of what is tested and why'),
    Field('priority', String, 'Priority',
        hint: 'Critical / High / Medium / Low — based on business impact'),
    Field('complexity', String, 'Complexity',
        hint: 'Simple / Medium / Complex — affects effort estimation'),
    Field('category', String, 'Category',
        hint:
            'Functional / Regression / Integration / End-to-End / Negative / Exploratory'),

    // --- Business Context ---
    Field('businessProcessRef', String, 'Business Process Reference',
        hint: 'ID or name of the business process being validated'),
    Field('businessRulesValidated', String, 'Business Rules Validated',
        hint:
            'Business rules this scenario verifies — comma-separated'),
    Field('userRolePerforming', String, 'User Role Performing Test',
        hint:
            'Persona or role executing — e.g. Finance Manager, Customer'),
    Field('regulatoryRelevance', String, 'Regulatory Relevance',
        hint:
            'Compliance or regulatory requirements addressed, if any'),

    // --- Traceability ---
    Field('requirementRef', String, 'Requirement Reference',
        hint: 'Requirement ID(s) — e.g. REQ-042, REQ-043'),
    Field('useCaseRef', String, 'Use Case Reference',
        hint: 'Related use case ID — e.g. UC-012'),
    Field('acceptanceCriterionRef', String, 'Acceptance Criterion Reference',
        hint: 'Linked criterion ID from 14.2.1'),
    Field('designRef', String, 'Design / Screen Reference',
        hint:
            'UI screens, wireframes, or mockup references involved'),

    // --- Preconditions & Setup ---
    Field('preconditions', String, 'Preconditions',
        hint:
            'System state, data, and configuration required before execution'),
    Field('testDataRequirements', String, 'Test Data Requirements',
        hint:
            'Specific data needed — e.g. active customer with 3+ orders'),
    Field('environmentRequirements', String, 'Environment Requirements',
        hint:
            'Special environment config if different from default UAT env'),
    Field('dependsOnScenarios', String, 'Depends on Scenarios',
        hint:
            'Scenario IDs that must pass before this one can execute'),

    // --- Execution ---
    Field('testStepsSummary', String, 'Test Steps Summary',
        hint:
            'High-level step sequence — detailed steps in sub-entries'),
    Field('expectedResult', String, 'Expected Result',
        hint: 'Overall expected outcome of the scenario'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria',
        hint: 'Specific pass/fail conditions for this scenario'),
    Field('estimatedDuration', String, 'Estimated Duration',
        hint: 'Expected execution time — e.g. 30 minutes'),
    Field('assignedTesterRole', String, 'Assigned Tester Role',
        hint: 'Role or name of the person assigned to execute'),

    // --- Post-Execution ---
    Field('postconditions', String, 'Postconditions',
        hint: 'Expected system state after successful execution'),
    Field('cleanupSteps', String, 'Cleanup Steps',
        hint:
            'Actions to reset environment or data after execution'),
    Field('defectThreshold', String, 'Defect Threshold',
        hint: 'Max defects for pass — e.g. 0 Sev-1, <= 2 Sev-3'),

    // --- Notes ---
    Field('assumptions', String, 'Assumptions',
        hint: 'Assumptions made when designing this scenario'),
    Field('risksAndMitigations', String, 'Risks & Mitigations',
        hint: 'Known risks and mitigation strategies for execution'),
    Field('notes', String, 'Notes',
        hint: 'Additional context, workarounds, or known issues'),
  ])
  String? content;

  /// Contains 0+× UatTestStep for this scenario.
  @SectionIdPattern('PD00-DEL-ACC-UAT-xx-STP-xx')
  List<UatTestStepEntry> testSteps = [];
}

/// A UAT test step entry [PD00-DEL-ACC-UAT-nn-STP-mm].
///
/// Individual step within a test scenario. Captures the action, input data,
/// expected result, and pass criteria at fine-grained level per IEEE 829
/// Level Test Procedure structure.
class UatTestStepEntry {
  @Form([
    Field('stepNumber', String, 'Step Number',
        hint: 'Sequential number — e.g. 1, 2, 3', required: true),
    Field('action', String, 'Action',
        hint:
            'What the tester does — e.g. "Navigate to Invoice screen and select order"'),
    Field('inputData', String, 'Input Data',
        hint:
            'Specific data to enter — e.g. "Amount: 500.00, Currency: EUR"'),
    Field('expectedResult', String, 'Expected Result',
        hint:
            'What should happen — e.g. "Invoice generated with correct line items"'),
    Field('uiScreenRef', String, 'UI Screen Reference',
        hint: 'Screen or page where this step is performed'),
    Field('passCriteria', String, 'Pass Criteria',
        hint: 'How to determine if this individual step passed'),
    Field('notes', String, 'Notes',
        hint: 'Clarification, timing notes, or alternative paths'),
  ])
  String? content;
}

// ═══════════════════════════════════════════════════════════════════════════
// 14.2.4. Defect Resolution
// ═══════════════════════════════════════════════════════════════════════════

/// 14.2.4. Defect Resolution [PD00-DEL-ACC-DEF].
///
/// Defines how defects found during acceptance testing are classified,
/// managed, resolved, and tracked. Covers severity classification,
/// resolution timeframes, blocking thresholds, and post-fix verification.
@SectionId('PD00-DEL-ACC-DEF')
class DefectResolution {
  @Form([
    // --- Classification ---
    Field('severityScheme', String, 'Severity Scheme',
        hint:
            'Severity levels defined — e.g. Sev-1 Critical, Sev-2 Major, '
            'Sev-3 Minor, Sev-4 Trivial'),
    Field('priorityScheme', String, 'Priority Scheme',
        hint:
            'Priority levels — Urgent / High / Medium / Low — '
            'determines fix sequencing'),
    Field('classificationAuthority', String, 'Classification Authority',
        hint:
            'Who decides severity/priority — UAT lead, business owner, or joint'),
    Field('reclassificationProcess', String, 'Reclassification Process',
        hint:
            'How severity can be changed after initial assignment — '
            'who, when, criteria'),

    // --- Resolution SLAs ---
    Field('sev1ResolutionTime', String, 'Sev-1 Resolution Time',
        hint: 'Target fix time — e.g. 4 hours, next business day'),
    Field('sev2ResolutionTime', String, 'Sev-2 Resolution Time',
        hint: 'Target fix time — e.g. 2 business days'),
    Field('sev3ResolutionTime', String, 'Sev-3 Resolution Time',
        hint: 'Target fix time — e.g. 5 business days'),
    Field('sev4ResolutionTime', String, 'Sev-4 Resolution Time',
        hint: 'Target fix time — e.g. next release, or backlog'),
    Field('slaExceptions', String, 'SLA Exceptions',
        hint: 'Conditions under which SLAs are suspended — holidays, force majeure'),

    // --- Blocking Thresholds ---
    Field('blockingThreshold', String, 'Blocking Threshold',
        hint:
            'Max open defects that block acceptance — '
            'e.g. 0 Sev-1, 0 Sev-2 unresolved'),
    Field('conditionalPassThreshold', String, 'Conditional Pass Threshold',
        hint:
            'Defects allowed for conditional acceptance — '
            'e.g. <= 3 Sev-3, agreed workaround for each'),
    Field('deferralPolicy', String, 'Deferral Policy',
        hint:
            'When defects can be deferred to post-go-live — '
            'criteria and approval process'),

    // --- Process ---
    Field('defectTrackingTool', String, 'Defect Tracking Tool',
        hint: 'Jira / Azure DevOps / ServiceNow — tool details'),
    Field('triageProcess', String, 'Triage Process',
        hint:
            'Frequency, participants, and decision criteria '
            'for defect triage meetings'),
    Field('retestProcess', String, 'Retest Process',
        hint:
            'How fixed defects are verified — who retests, '
            'environment, evidence required'),
    Field('regressionPolicy', String, 'Regression Policy',
        hint:
            'Whether fix deployment triggers regression — scope and criteria'),
    Field('escalationPath', String, 'Escalation Path',
        hint:
            'Escalation for overdue defects — levels and timing'),

    // --- Reporting ---
    Field('reportingFrequency', String, 'Reporting Frequency',
        hint: 'Daily / Per Triage / Weekly — defect status reporting'),
    Field('metricsTracked', String, 'Metrics Tracked',
        hint:
            'Open/closed counts, mean time to fix, aging, '
            'reopen rate, severity distribution'),
    Field('closureCriteria', String, 'Closure Criteria',
        hint:
            'When a defect is considered closed — retest passed, '
            'evidence documented, reporter confirmed'),
  ])
  String? content;

  /// Defect management narrative.
  @ContentHelp('Detailed description of the defect lifecycle: '
      'from discovery through classification, assignment, fix, '
      'retest, and closure. Include workflow diagrams if applicable.')
  TextSection defectManagementNarrative = TextSection();
}

// ═══════════════════════════════════════════════════════════════════════════
// 14.2.5. Sign-off Process
// ═══════════════════════════════════════════════════════════════════════════

/// 14.2.5. Sign-off Process [PD00-DEL-ACC-SIG].
///
/// Formal sign-off process: who signs off (business acceptance board,
/// technical acceptance board), what documents are signed, legal and
/// contractual implications, and conditional acceptance handling.
@SectionId('PD00-DEL-ACC-SIG')
class SignOffProcess {
  @Form([
    // --- Authority & Governance ---
    Field('signOffAuthority', String, 'Sign-Off Authority',
        hint:
            'Primary role/body authorized to sign — '
            'e.g. Business Acceptance Board, Project Sponsor',
        required: true),
    Field('technicalSignOff', String, 'Technical Sign-Off',
        hint:
            'Role for technical acceptance — '
            'e.g. Technical Lead, Solution Architect'),
    Field('businessSignOff', String, 'Business Sign-Off',
        hint:
            'Role for business acceptance — '
            'e.g. Business Owner, Product Owner'),
    Field('operationsSignOff', String, 'Operations Sign-Off',
        hint:
            'Role for operational readiness — '
            'e.g. Operations Manager, SRE Lead'),
    Field('quorumRequirements', String, 'Quorum Requirements',
        hint:
            'Minimum signatories — e.g. all 3 boards, or 2-of-3'),

    // --- Documents & Evidence ---
    Field('signOffDocumentTemplate', String, 'Sign-Off Document Template',
        hint:
            'Standard form/template used for formal sign-off'),
    Field('requiredAttachments', String, 'Required Attachments',
        hint:
            'Evidence package: test reports, acceptance report, '
            'risk assessment, open defect list'),
    Field('signOffCriteria', String, 'Sign-Off Criteria',
        hint:
            'Criteria that must be demonstrated before sign-off '
            'can proceed'),
    Field('preSignOffChecklistItems', String, 'Pre-Sign-Off Checklist',
        hint:
            'Final verification checklist — all items must be confirmed'),

    // --- Conditional & Partial ---
    Field('conditionalAcceptancePolicy', String,
        'Conditional Acceptance Policy',
        hint:
            'Conditions allowing sign-off with known issues or '
            'outstanding items — action plan required'),
    Field('partialAcceptancePolicy', String, 'Partial Acceptance Policy',
        hint:
            'Whether acceptance of individual deliverables '
            'is possible — scope and implications'),
    Field('rejectionProcess', String, 'Rejection Process',
        hint:
            'What happens on rejection — rework, resubmission timeline, '
            'impact on project'),

    // --- Legal & Contractual ---
    Field('legalImplications', String, 'Legal Implications',
        hint:
            'What sign-off means legally — warranties activate, '
            'payment milestones trigger, liability transfers'),
    Field('contractualReferences', String, 'Contractual References',
        hint:
            'Contract clauses governing acceptance — section numbers'),
    Field('paymentLinkage', String, 'Payment Linkage',
        hint:
            'Payment milestones triggered by sign-off — '
            'amounts and timing'),
    Field('warrantyActivation', String, 'Warranty Activation',
        hint:
            'When warranty period starts — from sign-off date, '
            'from go-live date'),

    // --- Timeline ---
    Field('signOffDeadline', String, 'Sign-Off Deadline',
        hint: 'Final date by which sign-off must be obtained'),
    Field('reviewPeriod', String, 'Review Period',
        hint:
            'Time allowed for review before sign-off — '
            'e.g. 5 business days after evidence delivery'),
    Field('silentAcceptancePolicy', String, 'Silent Acceptance Policy',
        hint:
            'Whether non-response constitutes acceptance — '
            'Yes/No, after what period'),
  ])
  String? content;

  /// Sign-off process narrative.
  @ContentHelp('Detailed walkthrough of the sign-off ceremony: '
      'how the meeting is conducted, document review procedure, '
      'voting mechanism, dissent handling, and record keeping.')
  TextSection signOffNarrative = TextSection();
}

// ═══════════════════════════════════════════════════════════════════════════
// 14.2.6. Warranty
// ═══════════════════════════════════════════════════════════════════════════

/// 14.2.6. Warranty [PD00-DEL-ACC-WAR].
///
/// Post-acceptance warranty terms: duration, scope, service levels,
/// exclusions, and transition to standard support.
@SectionId('PD00-DEL-ACC-WAR')
class WarrantyTerms {
  @Form([
    // --- Duration & Activation ---
    Field('warrantyDuration', String, 'Warranty Duration',
        hint: 'Length of warranty period — e.g. 90 days, 6 months',
        required: true),
    Field('warrantyStartTrigger', String, 'Warranty Start Trigger',
        hint:
            'What starts the warranty — sign-off date, go-live date, '
            'production deployment date'),
    Field('warrantyEndDate', String, 'Warranty End Date',
        hint: 'Calculated or fixed end date of warranty'),
    Field('extensionPolicy', String, 'Extension Policy',
        hint:
            'Conditions for warranty extension — e.g. unresolved Sev-1 '
            'extends by fix duration'),

    // --- Scope ---
    Field('warrantyScope', String, 'Warranty Scope',
        hint:
            'What is covered: defect fixes, configuration issues, '
            'performance degradation, data corruption'),
    Field('exclusions', String, 'Exclusions',
        hint:
            'What is NOT covered: new features, user errors, '
            'infrastructure failures, third-party issues'),
    Field('coveredDeliverables', String, 'Covered Deliverables',
        hint:
            'Which deliverables are under warranty — all or specific list'),
    Field('environmentsCovered', String, 'Environments Covered',
        hint:
            'Production only, or also staging/UAT environments'),

    // --- Service Levels ---
    Field('supportHours', String, 'Support Hours',
        hint:
            'Hours during which warranty support is available — '
            'e.g. 8×5 business hours, 24×7 for Sev-1'),
    Field('responseTimeSev1', String, 'Response Time Sev-1',
        hint: 'Initial response time — e.g. 1 hour'),
    Field('responseTimeSev2', String, 'Response Time Sev-2',
        hint: 'Initial response time — e.g. 4 hours'),
    Field('resolutionTimeSev1', String, 'Resolution Time Sev-1',
        hint: 'Target fix time — e.g. 8 hours'),
    Field('resolutionTimeSev2', String, 'Resolution Time Sev-2',
        hint: 'Target fix time — e.g. 2 business days'),
    Field('escalationContacts', String, 'Escalation Contacts',
        hint:
            'Named contacts or roles for escalation during warranty'),

    // --- Process ---
    Field('defectReportingChannel', String, 'Defect Reporting Channel',
        hint:
            'How to report warranty defects — ticketing system, '
            'email, phone'),
    Field('fixDeliveryMechanism', String, 'Fix Delivery Mechanism',
        hint:
            'How fixes are delivered — hotfix, patch release, '
            'scheduled release'),
    Field('regressionTestingPolicy', String, 'Regression Testing Policy',
        hint:
            'Who performs regression testing on warranty fixes'),
    Field('communicationCadence', String, 'Communication Cadence',
        hint:
            'Status reporting during warranty — weekly report, '
            'on-demand dashboard'),

    // --- Transition ---
    Field('transitionToSupport', String, 'Transition to Standard Support',
        hint:
            'How warranty transitions to ongoing support — '
            'handover activities, knowledge transfer'),
    Field('postWarrantyTerms', String, 'Post-Warranty Terms',
        hint:
            'Support terms after warranty expires — SLA, '
            'pricing, contract reference'),
    Field('knowledgeTransferPlan', String, 'Knowledge Transfer Plan',
        hint:
            'Activities to ensure support team can maintain system '
            'after warranty'),

    // --- Financial ---
    Field('warrantyCost', String, 'Warranty Cost',
        hint:
            'Whether warranty is included in project price or '
            'priced separately'),
    Field('penaltyForSlaBreaches', String, 'Penalty for SLA Breaches',
        hint:
            'Contractual penalties for failing to meet warranty SLAs'),
    Field('additionalWorkCharging', String, 'Additional Work Charging',
        hint:
            'How out-of-scope requests during warranty are charged'),
  ])
  String? content;

  /// Warranty terms narrative.
  @ContentHelp('Detailed warranty terms description: legal context, '
      'relationship to contract, scenarios and examples, '
      'common issues and their warranty status, '
      'handover checklist for transition to support.')
  TextSection warrantyNarrative = TextSection();
}
