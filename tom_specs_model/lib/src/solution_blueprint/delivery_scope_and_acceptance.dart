/// Section 14: Delivery Scope and Acceptance.
///
/// Agreements regarding delivery scope and acceptance for the system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';



/// 14. Delivery Scope and Acceptance.
@SectionId('DLVA')
class DeliveryScopeAndAcceptance {
  @ContentHelp('''
Chapter overview: defines agreements regarding delivery scope and acceptance
for the system. Covers two major subsections:
- 14.1. Delivery and Service Scope — what is delivered (software, documentation,
  training, support)
- 14.2. Acceptance Plan — how deliverables are accepted (criteria, process, UAT,
  defect resolution, sign-off, warranty)

Seeds the QAP (Quality & Acceptance Plan) document for full quality planning.
All deliverable and acceptance definitions should be objectively verifiable
and contractually precise.
''')
  @SerializationOrder(0)
  String? content;

  /// 14.1. Delivery and Service Scope.
  @SerializationOrder(1)
  DeliveryScope deliveryScope = DeliveryScope();

  /// 14.2. Acceptance Plan. Seeds → QAP.
  @Comment('Seeds → QAP')
  @SerializationOrder(2)
  AcceptancePlan acceptancePlan = AcceptancePlan();
}

/// 14.1. Delivery and Service Scope.
@SectionId('DLVSC')
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
  @SerializationOrder(0)
  String? content;

  /// 14.1.1. Software Deliverables.
  @SerializationOrder(1)
  SoftwareDeliverables softwareDeliverables = SoftwareDeliverables();

  /// 14.1.2. Documentation Deliverables.
  @SerializationOrder(2)
  DocumentationDeliverables documentationDeliverables = DocumentationDeliverables();

  /// 14.1.3. Training Deliverables.
  @SerializationOrder(3)
  TrainingDeliverables trainingDeliverables = TrainingDeliverables();

  /// 14.1.4. Support Deliverables.
  @SerializationOrder(4)
  SupportDeliverables supportDeliverables = SupportDeliverables();
}

/// 14.1.1. Software Deliverables.
@SectionId('SWDLV')
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
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Deliverable.
  @SectionId('SWDLV-ITEM-LST')
  @SectionIdPattern('SWDLV-ITEM-xxx')
  @SerializationOrder(1)
  List<DeliverableEntry> items = [];
}

/// 14.1.2. Documentation Deliverables.
@SectionId('DCDLV')
class DocumentationDeliverables {
  @ContentHelp('''
Documentation deliverables: user guides, technical documentation,
operations runbooks, API documentation, architecture decision records,
release notes Template. Define format (PDF, HTML, Markdown, wiki),
delivery channel, language(s), and maintenance responsibility post-delivery.
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Deliverable.
  @SectionId('DCDLV-ITEM-LST')
  @SectionIdPattern('DCDLV-ITEM-xxx')
  @SerializationOrder(1)
  List<DeliverableEntry> items = [];
}

/// 14.1.3. Training Deliverables.
@SectionId('TRDLV')
class TrainingDeliverables {
  @ContentHelp('''
Training deliverables: instructor-led sessions, e-learning modules,
train-the-trainer programs, quick reference cards, video tutorials,
sandbox environments. Define target audience, duration, prerequisites,
assessment criteria, and ongoing refresh schedule.
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Deliverable.
  @SectionId('TRDLV-ITEM-LST')
  @SectionIdPattern('TRDLV-ITEM-xxx')
  @SerializationOrder(1)
  List<DeliverableEntry> items = [];
}

/// 14.1.4. Support Deliverables.
@SectionId('SPDLV')
class SupportDeliverables {
  @ContentHelp('''
Support deliverables: transition support during go-live, warranty support
post-acceptance, knowledge transfer sessions, escalation contacts,
SLA definitions, support tooling and access. Define support hours,
response times, coverage period, and handover criteria.
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Deliverable.
  @SectionId('SPDLV-ITEM-LST')
  @SectionIdPattern('SPDLV-ITEM-xxx')
  @SerializationOrder(1)
  List<DeliverableEntry> items = [];
}

/// A deliverable entry (form).
///
/// Represents a single deliverable item within any deliverable category.
/// Captures identification, delivery logistics, quality requirements,
/// ownership, and acceptance linkage.
@SectionId('DLVEN')
class DeliverableEntry {
  @Form([
    Field('deliverableId', String, 'Deliverable ID',
        hint: 'Unique identifier — e.g. DEL-SOF-001', required: true),
    Field('deliverableName', String, 'Deliverable Name',
        hint: 'Concise name — e.g. "Customer Management API"', required: true),
    Field('priority', String, 'Priority',
        hint: 'Critical / High / Medium / Low'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Identification details.
  @SerializationOrder(1)
  DeliverableIdentity identity = DeliverableIdentity();

  /// Delivery logistics.
  @SerializationOrder(2)
  DeliverableLogistics logistics = DeliverableLogistics();

  /// Version and compatibility.
  @SerializationOrder(3)
  DeliverableVersion version = DeliverableVersion();

  /// Quality and acceptance.
  @SerializationOrder(4)
  DeliverableQuality quality = DeliverableQuality();

  /// Ownership and responsibility.
  @SerializationOrder(5)
  DeliverableOwnership ownership = DeliverableOwnership();

  /// Dependencies.
  @SectionId('DLVDP-DEPE-LST')
  @SectionIdPattern('DLVDP-DEPE-xxx')
  @SerializationOrder(6)
  List<DeliverableDependencies> dependencies = [];

  /// Licensing and legal.
  @SerializationOrder(7)
  DeliverableLegal legal = DeliverableLegal();

  /// Documentation.
  @SerializationOrder(8)
  DeliverableDocumentation documentation = DeliverableDocumentation();
}

/// Identity for deliverable.
@SectionId('DLVID')
class DeliverableIdentity {
  @Form([
    Field('description', String, 'Description',
        hint: 'What this deliverable contains and its purpose'),
    Field('category', String, 'Category',
        hint: 'Application / Library / Tool / Configuration / Document'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Logistics for deliverable.
@SectionId('DLVLOG')
class DeliverableLogistics {
  @Form([
    Field('deliveryFormat', String, 'Delivery Format',
        hint: 'Docker Image / NPM Package / Dart Package / APK / IPA'),
    Field('deliveryMechanism', String, 'Delivery Mechanism',
        hint: 'Container Registry / Artifact Repository / App Store'),
    Field('deliveryEnvironment', String, 'Target Environment',
        hint: 'Production / Staging / All Environments'),
    Field('plannedDeliveryDate', String, 'Planned Delivery Date',
        hint: 'Target date — e.g. 2026-Q3'),
    Field('deliveryStage', String, 'Delivery Stage',
        hint: 'Stage in which this deliverable is delivered'),
    Field('deliveryFrequency', String, 'Delivery Frequency',
        hint: 'OneTime / PerRelease / Continuous / OnDemand'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Version for deliverable.
@SectionId('DLVVR')
class DeliverableVersion {
  @Form([
    Field('versionRequirement', String, 'Version Requirement',
        hint: 'Minimum version or version range'),
    Field('compatibilityConstraints', String, 'Compatibility Constraints',
        hint: 'Platform, OS, browser, or dependency version requirements'),
    Field('backwardCompatibility', String, 'Backward Compatibility',
        hint: 'Yes / No / Partial'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Quality for deliverable.
@SectionId('DLVQL')
class DeliverableQuality {
  @Form([
    Field('qualityStandard', String, 'Quality Standard',
        hint: 'Quality standards applied — e.g. ISO 25010, WCAG 2.1 AA'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria',
        hint: 'Specific criteria for accepting this deliverable'),
    Field('verificationMethod', String, 'Verification Method',
        hint: 'Testing / Inspection / Review / Demonstration'),
    Field('testCoverage', String, 'Required Test Coverage',
        hint: 'Minimum test coverage — e.g. 80% unit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ownership for deliverable.
@SectionId('DLVOW')
class DeliverableOwnership {
  @Form([
    Field('responsibleParty', String, 'Responsible Party',
        hint: 'Team or role responsible for creating'),
    Field('reviewer', String, 'Reviewer',
        hint: 'Who reviews and approves before delivery'),
    Field('recipient', String, 'Recipient',
        hint: 'Who receives the deliverable'),
    Field('maintenanceOwner', String, 'Maintenance Owner',
        hint: 'Who maintains the deliverable post-delivery'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependencies for deliverable.
@SectionId('DLVDP')
class DeliverableDependencies {
  @Form([
    Field('dependsOn', String, 'Depends On',
        hint: 'Other deliverable IDs this depends on'),
    Field('prerequisiteForDelivery', String, 'Prerequisites',
        hint: 'Conditions that must be met before delivery'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Legal for deliverable.
@SectionId('DLVLG')
class DeliverableLegal {
  @Form([
    Field('licenseType', String, 'License Type',
        hint: 'Commercial / OpenSource / Proprietary / Mixed'),
    Field('intellectualProperty', String, 'IP Ownership',
        hint: 'Who owns the IP — client, vendor, shared'),
    Field('thirdPartyComponents', String, 'Third-Party Components',
        hint: 'Third-party libraries included and their licenses'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation for deliverable.
@SectionId('DLVDC')
class DeliverableDocumentation {
  @Form([
    Field('associatedDocumentation', String, 'Associated Documentation',
        hint: 'Related documentation deliverable IDs'),
    Field('releaseNotes', String, 'Release Notes Required',
        hint: 'Yes / No — whether release notes accompany delivery'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or special instructions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 14.2. Acceptance Plan. Seeds → QAP.
@SectionId('ACPLN')
@Comment('Seeds → QAP')
@MapsTo(D10QualityAcceptancePlan)
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

Seeds the QAP (Quality & Acceptance Plan) for comprehensive quality planning.
All criteria must be objectively measurable and verifiable.
''')
  @SerializationOrder(0)
  String? content;

  /// 14.2.1. Acceptance Criteria.
  @SerializationOrder(1)
  AcceptanceCriteriaList acceptanceCriteria = AcceptanceCriteriaList();

  /// 14.2.2. Acceptance Process.
  @SerializationOrder(2)
  AcceptanceProcess acceptanceProcess = AcceptanceProcess();

  /// 14.2.3. User Acceptance Testing.
  @SerializationOrder(3)
  UserAcceptanceTesting userAcceptanceTesting = UserAcceptanceTesting();

  /// 14.2.4. Defect Resolution.
  @SerializationOrder(4)
  DefectResolution defectResolution = DefectResolution();

  /// 14.2.5. Sign-off Process.
  @SerializationOrder(5)
  SignOffProcess signOffProcess = SignOffProcess();

  /// 14.2.6. Warranty.
  @SerializationOrder(6)
  WarrantyTerms warranty = WarrantyTerms();
}

/// 14.2.1. Acceptance Criteria.
@SectionId('ACRITL')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-CRI')
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
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× DeliveryAcceptanceCriterion.
  @SectionId('DACEN-ITEM-LST')
  @SectionIdPattern('DACEN-ITEM-xxx')
  @SerializationOrder(1)
  List<DeliveryAcceptanceCriterionEntry> items = [];
}

/// An acceptance criterion entry (form).
///
/// A single criterion that must be met for formal project acceptance.
/// Aligned with IEEE 830 acceptance criteria structure and ISTQB
/// acceptance test design.
@SectionId('DACEN')
class DeliveryAcceptanceCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID',
        hint: 'Unique identifier — e.g. AC-001', required: true),
    Field('criterion', String, 'Criterion Statement',
        hint: 'Clear, measurable statement of what must be true',
        required: true),
    Field('category', String, 'Category',
        hint:
            'Functional / Performance / Security / Usability / '
            'Documentation / Training / Operational / Compliance'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Priority and description.
  @SerializationOrder(1)
  DeliveryAcceptanceCriterionEntryDefinition definition =
      DeliveryAcceptanceCriterionEntryDefinition();

  /// Verification method and evidence.
  @SerializationOrder(2)
  DeliveryAcceptanceCriterionEntryVerification verification =
      DeliveryAcceptanceCriterionEntryVerification();

  /// Traceability links.
  @SerializationOrder(3)
  DeliveryAcceptanceCriterionEntryTraceability traceability =
      DeliveryAcceptanceCriterionEntryTraceability();

  /// Responsibility assignments.
  @SerializationOrder(4)
  DeliveryAcceptanceCriterionEntryOwnership ownership =
      DeliveryAcceptanceCriterionEntryOwnership();

  /// Current status and notes.
  @SerializationOrder(5)
  DeliveryAcceptanceCriterionEntryStatus status =
      DeliveryAcceptanceCriterionEntryStatus();
}

/// Priority and description.
@SectionId('DACED')
class DeliveryAcceptanceCriterionEntryDefinition {
  @Form([
    Field('priority', String, 'Priority',
        hint:
            'MustPass / ShouldPass / NiceToPass — relative importance'),
    Field('description', String, 'Detailed Description',
        hint:
            'Extended explanation including context and boundaries'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification method and evidence.
@SectionId('DACEV')
class DeliveryAcceptanceCriterionEntryVerification {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Traceability links.
@SectionId('DACET')
class DeliveryAcceptanceCriterionEntryTraceability {
  @Form([
    Field('requirementRef', String, 'Requirement Reference',
        hint: 'Linked requirement ID(s) — e.g. REQ-042'),
    Field('deliverableRef', String, 'Deliverable Reference',
        hint: 'Linked deliverable ID — e.g. DEL-SOF-001'),
    Field('testScenarioRef', String, 'Test Scenario Reference',
        hint: 'UAT scenario ID that validates this criterion'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Responsibility assignments.
@SectionId('DACEOW')
class DeliveryAcceptanceCriterionEntryOwnership {
  @Form([
    Field('verifier', String, 'Verifier',
        hint: 'Role or person who performs verification'),
    Field('approver', String, 'Approver',
        hint: 'Role or person who confirms acceptance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Current status and notes.
@SectionId('DACES')
class DeliveryAcceptanceCriterionEntryStatus {
  @Form([
    Field('currentStatus', String, 'Current Status',
        hint:
            'NotTested / Passed / Failed / Conditional / Deferred'),
    Field('notes', String, 'Notes',
        hint: 'Clarifications, exceptions, or conditions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 14.2.2. Acceptance Process.
///
/// Defines the formal acceptance workflow from test initiation through
/// final sign-off. Covers roles, responsibilities, timelines, escalation,
/// and decision criteria.
@SectionId('ACPR1')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-PRO')
class AcceptanceProcess {
  @Form([
    Field('processName', String, 'Process Name',
        hint: 'e.g. "Formal Acceptance Process v2"'),
    Field('processOwner', String, 'Process Owner',
        hint: 'Role responsible for managing the acceptance process'),
    Field('acceptanceType', String, 'Acceptance Type',
        hint: 'Formal / Informal / Staged / Conditional'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Process overview.
  @SerializationOrder(1)
  AcceptanceProcessOverview overview = AcceptanceProcessOverview();

  /// Participants and governance.
  @SerializationOrder(2)
  AcceptanceProcessParticipants participants =
      AcceptanceProcessParticipants();

  /// Timeline and schedule.
  @SerializationOrder(3)
  AcceptanceProcessTimeline timeline = AcceptanceProcessTimeline();

  /// Decision framework.
  @SerializationOrder(4)
  AcceptanceProcessDecision decision = AcceptanceProcessDecision();

  /// Escalation.
  @SerializationOrder(5)
  AcceptanceProcessEscalation escalation =
      AcceptanceProcessEscalation();

  /// Documentation.
  @SerializationOrder(6)
  AcceptanceProcessDocumentation documentation =
      AcceptanceProcessDocumentation();

  /// Acceptance process narrative description.
  @ContentHelp('Detailed walkthrough of the acceptance process: '
      'step-by-step flow, decision points, parallel tracks, '
      'timing dependencies, and integration with project closeout.')
  @SerializationOrder(7)
  TextSection processNarrative = TextSection();

  /// Contains 0+× AcceptanceStep.
  @SectionId('ACST-STEP-LST')
  @SectionIdPattern('ACST-STEP-xxx')
  @SerializationOrder(8)
  List<AcceptanceStepEntry> steps = [];
}

/// Process overview.
@SectionId('ACPROV')
class AcceptanceProcessOverview {
  @Form([
    Field('processDescription', String, 'Process Description',
        hint: 'High-level workflow: initiation → testing → review → sign-off'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Participants and governance.
@SectionId('ACPRPA')
class AcceptanceProcessParticipants {
  @Form([
    Field('acceptanceBoard', String, 'Acceptance Board',
        hint: 'Members of the acceptance board'),
    Field('technicalReviewers', String, 'Technical Reviewers',
        hint: 'Technical staff who verify technical acceptance criteria'),
    Field('businessReviewers', String, 'Business Reviewers',
        hint: 'Business stakeholders who verify business acceptance'),
    Field('participants', String, 'All Participants',
        hint: 'Complete list of roles involved'),
    Field('raciMatrix', String, 'RACI Matrix',
        hint: 'Responsible / Accountable / Consulted / Informed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Timeline and schedule.
@SectionId('ACPRTI')
class AcceptanceProcessTimeline {
  @Form([
    Field('plannedDuration', String, 'Planned Duration',
        hint: 'Expected total duration of acceptance process'),
    Field('acceptanceWindowStart', String, 'Acceptance Window Start',
        hint: 'Earliest date acceptance can begin'),
    Field('acceptanceWindowEnd', String, 'Acceptance Window End',
        hint: 'Latest date acceptance must conclude'),
    Field('milestones', String, 'Key Milestones',
        hint: 'Entry gate, mid-point review, final review, sign-off'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Decision framework.
@SectionId('ACPRDE')
class AcceptanceProcessDecision {
  @Form([
    Field('decisionCriteria', String, 'Decision Criteria',
        hint: 'How accept/reject/conditional decisions are made'),
    Field('defectThreshold', String, 'Acceptable Defect Threshold',
        hint: 'Maximum open defects by severity to proceed'),
    Field('conditionalAcceptanceRules', String,
        'Conditional Acceptance Rules',
        hint: 'Conditions under which acceptance with known issues is allowed'),
    Field('rejectionCriteria', String, 'Rejection Criteria',
        hint: 'Conditions that automatically block acceptance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Escalation.
@SectionId('ACPRES')
class AcceptanceProcessEscalation {
  @Form([
    Field('escalationProcess', String, 'Escalation Process',
        hint: 'Escalation path for disputes or blockers'),
    Field('escalationLevels', String, 'Escalation Levels',
        hint: 'L1: Project Manager, L2: Steering Committee, L3: Sponsor'),
    Field('disputeResolution', String, 'Dispute Resolution',
        hint: 'How disagreements about acceptance are resolved'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation.
@SectionId('ACPRDO')
class AcceptanceProcessDocumentation {
  @Form([
    Field('acceptanceReportTemplate', String, 'Acceptance Report Template',
        hint: 'Template for the formal acceptance report'),
    Field('evidencePackageContents', String, 'Evidence Package Contents',
        hint: 'What must be in the evidence package'),
    Field('archivalRequirements', String, 'Archival Requirements',
        hint: 'How acceptance evidence is archived'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An acceptance step entry (form).
///
/// A single step in the formal acceptance workflow, with entry/exit
/// conditions, responsible parties, and outputs.
@SectionId('ACST')
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
  ])
  @SerializationOrder(0)
  String? content;

  /// Participants and execution flow.
  @SerializationOrder(1)
  AcceptanceStepEntryFlow flow = AcceptanceStepEntryFlow();

  /// Exit outcomes and timing.
  @SerializationOrder(2)
  AcceptanceStepEntryOutcome outcome = AcceptanceStepEntryOutcome();
}

/// Participants and execution flow.
@SectionId('ASEF')
class AcceptanceStepEntryFlow {
  @Form([
    Field('participants', String, 'Participants',
        hint: 'Additional roles involved'),
    Field('entryCriteria', String, 'Entry Criteria',
        hint: 'What must be true before this step can start'),
    Field('activities', String, 'Activities',
        hint: 'Key activities performed in this step'),
    Field('exitCriteria', String, 'Exit Criteria',
        hint: 'What must be true for this step to be complete'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Exit outcomes and timing.
@SectionId('ASEO')
class AcceptanceStepEntryOutcome {
  @Form([
    Field('outputs', String, 'Outputs',
        hint: 'Documents, decisions, or artifacts produced'),
    Field('duration', String, 'Expected Duration',
        hint: 'How long this step takes — e.g. 2 business days'),
    Field('decisionOptions', String, 'Decision Options',
        hint:
            'Possible outcomes — e.g. Pass / Fail / Conditional / '
            'Escalate'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 14.2.3. User Acceptance Testing.
///
/// Comprehensive UAT planning covering scope, environment, test data,
/// governance, scheduling, defect management, reporting, non-functional
/// acceptance, and formal sign-off. Aligned with IEEE 829 / ISO 29119
/// test documentation structure and ISTQB best practices.
@SectionId('USACTE')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-UAT')
class UserAcceptanceTesting {
  @Form([
    Field('uatObjective', String, 'UAT Objective',
        hint: 'Primary goal — e.g. validate business requirements before go-live'),
    Field('uatApproach', String, 'UAT Approach',
        hint: 'Scripted / Exploratory / Hybrid'),
    Field('uatLead', String, 'UAT Lead',
        hint: 'Name and role of the person coordinating UAT'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Scope and objectives.
  @SerializationOrder(1)
  UatScope scope = UatScope();

  /// Environment.
  @SerializationOrder(2)
  UatEnvironment environment = UatEnvironment();

  /// Test data.
  @SerializationOrder(3)
  UatTestData testData = UatTestData();

  /// Participants and governance.
  @SerializationOrder(4)
  UatGovernance governance = UatGovernance();

  /// Schedule and cycles.
  @SerializationOrder(5)
  UatSchedule schedule = UatSchedule();

  /// Entry, exit, and suspension criteria.
  @SerializationOrder(6)
  UatCriteria criteria = UatCriteria();

  /// Defect management.
  @SerializationOrder(7)
  UatDefectManagement defectManagement = UatDefectManagement();

  /// Reporting.
  @SerializationOrder(8)
  UatReporting reporting = UatReporting();

  /// Non-functional acceptance.
  @SerializationOrder(9)
  UatNonFunctional nonFunctional = UatNonFunctional();

  /// Sign-off.
  @SerializationOrder(10)
  UatSignOff signOff = UatSignOff();

  /// Training and readiness.
  @SerializationOrder(11)
  UatTraining training = UatTraining();

  /// Narrative overview of the UAT approach and philosophy.
  @ContentHelp('Describe the UAT philosophy, how it integrates with prior '
      'test levels, key risks, and lessons from previous projects.')
  @SerializationOrder(12)
  TextSection uatOverview = TextSection();

  /// Contains 0+× UatTestCycle.
  @SectionId('UATCY-TEST-LST')
  @SectionIdPattern('UATCY-TEST-xxx')
  @SerializationOrder(13)
  List<UatTestCycleEntry> testCycles = [];

  /// Contains 0+× TestScenario.
  @SectionId('TSSC-TEST-LST')
  @SectionIdPattern('TSSC-TEST-xxx')
  @SerializationOrder(14)
  List<TestScenarioEntry> testScenarios = [];
}

/// Scope and objectives for UAT.
@SectionId('UASC')
class UatScope {
  @Form([
    Field('scope', String, 'Scope Summary',
        hint: 'Modules, features, and integrations included in UAT'),
    Field('outOfScope', String, 'Out of Scope',
        hint: 'Explicitly excluded items'),
    Field('testTypes', String, 'Test Types Included',
        hint: 'Functional / Regression / Usability / Accessibility / End-to-End'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Environment for UAT.
@SectionId('UAEN')
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
  @SerializationOrder(0)
  String? content;
}

/// Test data for UAT.
@SectionId('UATEDA')
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
  @SerializationOrder(0)
  String? content;
}

/// Governance for UAT.
@SectionId('UAGO')
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
  @SerializationOrder(0)
  String? content;
}

/// Schedule for UAT.
@SectionId('UASC1')
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
  @SerializationOrder(0)
  String? content;
}

/// Criteria for UAT.
@SectionId('UACR')
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
  @SerializationOrder(0)
  String? content;
}

/// Defect management for UAT.
@SectionId('UADEMA')
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
  @SerializationOrder(0)
  String? content;
}

/// Reporting for UAT.
@SectionId('UARE')
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
  @SerializationOrder(0)
  String? content;
}

/// Non-functional acceptance for UAT.
@SectionId('UANOFU')
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
  @SerializationOrder(0)
  String? content;
}

/// Sign-off for UAT.
@SectionId('UASIOF')
class UatSignOff {
  @Form([
    Field('signOffAuthority', String, 'Sign-Off Authority',
        hint: 'Role(s) authorized to provide formal UAT sign-off'),
    Field('signOffCriteria', String, 'Sign-Off Criteria',
        hint: 'Exit criteria + risk acceptance conditions'),
    Field('conditionalAcceptancePolicy', String, 'Conditional Acceptance Policy',
        hint: 'Conditions under which UAT passes with known defects'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Training and readiness for UAT.
@SectionId('UATR')
class UatTraining {
  @Form([
    Field('testerTraining', String, 'Tester Training',
        hint: 'Training provided: system walkthrough, tool orientation'),
    Field('userDocumentation', String, 'User Documentation Availability',
        hint: 'Guides, FAQs, and quick-start docs available'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A UAT test cycle entry.
///
/// Represents a distinct test execution round — e.g. Cycle 1 (initial),
/// Cycle 2 (regression/retest). Each cycle defines scope, dates, entry/exit
/// criteria, and focus areas per IEEE 829 Level Test Plan structure.
@SectionId('UATCY')
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
  ])
  @SerializationOrder(0)
  String? content;

  /// Scope and pass criteria for this cycle.
  @SerializationOrder(1)
  UatTestCycleEntryScope scope = UatTestCycleEntryScope();

  /// Staffing and risk context.
  @SerializationOrder(2)
  UatTestCycleEntryExecution execution = UatTestCycleEntryExecution();
}

/// Scope and pass criteria for this cycle.
@SectionId('UTCES')
class UatTestCycleEntryScope {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Staffing and risk context.
@SectionId('UTCEE')
class UatTestCycleEntryExecution {
  @Form([
    Field('assignedTesters', String, 'Assigned Testers',
        hint: 'Tester names/roles allocated for this cycle'),
    Field('riskNotes', String, 'Risk Notes',
        hint: 'Known risks or dependencies for this cycle'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A test scenario entry (form).
///
/// Represents a business-level test case covering a user journey, business
/// process, or acceptance criterion. Includes full traceability, preconditions,
/// execution metadata, and pass/fail criteria per ISTQB and IEEE 829
/// Level Test Case / Level Test Procedure structures.
@SectionId('TSSC')
class TestScenarioEntry {
  @Form([
    Field('scenarioId', String, 'Scenario ID',
        hint: 'Unique identifier — e.g. UAT-SC-001', required: true),
    Field('scenarioName', String, 'Scenario Name',
        hint: 'Concise name describing the user journey', required: true),
    Field('priority', String, 'Priority',
        hint: 'Critical / High / Medium / Low'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Identification.
  @SerializationOrder(1)
  TestScenarioIdentification identification = TestScenarioIdentification();

  /// Business context.
  @SerializationOrder(2)
  TestScenarioBusiness business = TestScenarioBusiness();

  /// Traceability.
  @SerializationOrder(3)
  TestScenarioTraceability traceability = TestScenarioTraceability();

  /// Preconditions and setup.
  @SerializationOrder(4)
  TestScenarioSetup setup = TestScenarioSetup();

  /// Execution.
  @SerializationOrder(5)
  TestScenarioExecution execution = TestScenarioExecution();

  /// Post-execution.
  @SerializationOrder(6)
  TestScenarioPostExecution postExecution = TestScenarioPostExecution();

  /// Notes.
  @SectionId('TESCNO-NOTE-LST')
  @SectionIdPattern('TESCNO-NOTE-xxx')
  @SerializationOrder(7)
  List<TestScenarioNotes> notes = [];

  /// Contains 0+× UatTestStep for this scenario.
  @SectionId('UATSST-TEST-LST')
  @SectionIdPattern('UATSST-TEST-xxx')
  @SerializationOrder(8)
  List<UatTestStepEntry> testSteps = [];
}

/// Identification for test scenario.
@SectionId('TESCID')
class TestScenarioIdentification {
  @Form([
    Field('description', String, 'Description',
        hint: 'Detailed narrative of what is tested and why'),
    Field('complexity', String, 'Complexity',
        hint: 'Simple / Medium / Complex'),
    Field('category', String, 'Category',
        hint: 'Functional / Regression / Integration / End-to-End'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Business context for test scenario.
@SectionId('TESCBU')
class TestScenarioBusiness {
  @Form([
    Field('businessProcessRef', String, 'Business Process Reference',
        hint: 'ID or name of the business process being validated'),
    Field('businessRulesValidated', String, 'Business Rules Validated',
        hint: 'Business rules this scenario verifies'),
    Field('userRolePerforming', String, 'User Role Performing Test',
        hint: 'Persona or role executing'),
    Field('regulatoryRelevance', String, 'Regulatory Relevance',
        hint: 'Compliance requirements addressed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Traceability for test scenario.
@SectionId('TESCTR')
class TestScenarioTraceability {
  @Form([
    Field('requirementRef', String, 'Requirement Reference',
        hint: 'Requirement ID(s) — e.g. REQ-042'),
    Field('useCaseRef', String, 'Use Case Reference',
        hint: 'Related use case ID'),
    Field('acceptanceCriterionRef', String, 'Acceptance Criterion Reference',
        hint: 'Linked criterion ID'),
    Field('designRef', String, 'Design / Screen Reference',
        hint: 'UI screens or mockup references'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Setup for test scenario.
@SectionId('TESCSE')
class TestScenarioSetup {
  @Form([
    Field('preconditions', String, 'Preconditions',
        hint: 'System state required before execution'),
    Field('testDataRequirements', String, 'Test Data Requirements',
        hint: 'Specific data needed'),
    Field('environmentRequirements', String, 'Environment Requirements',
        hint: 'Special environment config'),
    Field('dependsOnScenarios', String, 'Depends on Scenarios',
        hint: 'Scenario IDs that must pass before this one'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Execution for test scenario.
@SectionId('TESCEX')
class TestScenarioExecution {
  @Form([
    Field('testStepsSummary', String, 'Test Steps Summary',
        hint: 'High-level step sequence'),
    Field('expectedResult', String, 'Expected Result',
        hint: 'Overall expected outcome'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria',
        hint: 'Specific pass/fail conditions'),
    Field('estimatedDuration', String, 'Estimated Duration',
        hint: 'Expected execution time'),
    Field('assignedTesterRole', String, 'Assigned Tester Role',
        hint: 'Role or name of the person assigned'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Post-execution for test scenario.
@SectionId('TSPE')
class TestScenarioPostExecution {
  @Form([
    Field('postconditions', String, 'Postconditions',
        hint: 'Expected system state after execution'),
    Field('cleanupSteps', String, 'Cleanup Steps',
        hint: 'Actions to reset environment'),
    Field('defectThreshold', String, 'Defect Threshold',
        hint: 'Max defects for pass'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Notes for test scenario.
@SectionId('TESCNO')
class TestScenarioNotes {
  @Form([
    Field('assumptions', String, 'Assumptions',
        hint: 'Assumptions made when designing'),
    Field('risksAndMitigations', String, 'Risks & Mitigations',
        hint: 'Known risks and mitigation strategies'),
    Field('notes', String, 'Notes',
        hint: 'Additional context or known issues'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A UAT test step entry.
///
/// Individual step within a test scenario. Captures the action, input data,
/// expected result, and pass criteria at fine-grained level per IEEE 829
/// Level Test Procedure structure.
@SectionId('UATSST')
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
  @SerializationOrder(0)
  String? content;
}

// ═══════════════════════════════════════════════════════════════════════════
// 14.2.4. Defect Resolution
// ═══════════════════════════════════════════════════════════════════════════

/// 14.2.4. Defect Resolution.
///
/// Defines how defects found during acceptance testing are classified,
/// managed, resolved, and tracked. Covers severity classification,
/// resolution timeframes, blocking thresholds, and post-fix verification.
@SectionId('DERE')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-DEF')
class DefectResolution {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;

  /// Classification refinement and SLA targets.
  @SerializationOrder(1)
  DefectResolutionSla sla = DefectResolutionSla();

  /// Acceptance thresholds and deferral rules.
  @SerializationOrder(2)
  DefectResolutionThresholds thresholds = DefectResolutionThresholds();

  /// Triage, retest, and escalation process.
  @SerializationOrder(3)
  DefectResolutionProcess process = DefectResolutionProcess();

  /// Reporting and closure rules.
  @SerializationOrder(4)
  DefectResolutionReporting reporting = DefectResolutionReporting();

  /// Defect management narrative.
  @ContentHelp('Detailed description of the defect lifecycle: '
      'from discovery through classification, assignment, fix, '
      'retest, and closure. Include workflow diagrams if applicable.')
  @SerializationOrder(5)
  TextSection defectManagementNarrative = TextSection();
}

/// Classification refinement and SLA targets.
@SectionId('DERESL')
class DefectResolutionSla {
  @Form([
    Field('reclassificationProcess', String, 'Reclassification Process',
        hint:
            'How severity can be changed after initial assignment — '
            'who, when, criteria'),
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Acceptance thresholds and deferral rules.
@SectionId('DERETH')
class DefectResolutionThresholds {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Triage, retest, and escalation process.
@SectionId('DEREPR')
class DefectResolutionProcess {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting and closure rules.
@SectionId('DERERE')
class DefectResolutionReporting {
  @Form([
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
  @SerializationOrder(0)
  String? content;
}

// ═══════════════════════════════════════════════════════════════════════════
// 14.2.5. Sign-off Process
// ═══════════════════════════════════════════════════════════════════════════

/// 14.2.5. Sign-off Process.
///
/// Formal sign-off process: who signs off (business acceptance board,
/// technical acceptance board), what documents are signed, legal and
/// contractual implications, and conditional acceptance handling.
@SectionId('SIOFPR')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-SIG')
class SignOffProcess {
  @Form([
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
  ])
  @SerializationOrder(0)
  String? content;

  /// Signatory and quorum governance.
  @SerializationOrder(1)
  SignOffProcessGovernance governance = SignOffProcessGovernance();

  /// Evidence and checklist requirements.
  @SerializationOrder(2)
  SignOffProcessEvidence evidence = SignOffProcessEvidence();

  /// Conditional or partial acceptance policies.
  @SerializationOrder(3)
  SignOffProcessAcceptance acceptance = SignOffProcessAcceptance();

  /// Legal and contractual consequences.
  @SerializationOrder(4)
  SignOffProcessContractual contractual = SignOffProcessContractual();

  /// Review timeline.
  @SerializationOrder(5)
  SignOffProcessTimeline timeline = SignOffProcessTimeline();

  /// Sign-off process narrative.
  @ContentHelp('Detailed walkthrough of the sign-off ceremony: '
      'how the meeting is conducted, document review procedure, '
      'voting mechanism, dissent handling, and record keeping.')
  @SerializationOrder(6)
  TextSection signOffNarrative = TextSection();
}

/// Signatory and quorum governance.
@SectionId('SOPG')
class SignOffProcessGovernance {
    @Form([
        Field('operationsSignOff', String, 'Operations Sign-Off',
                hint:
                        'Role for operational readiness — '
                        'e.g. Operations Manager, SRE Lead'),
        Field('quorumRequirements', String, 'Quorum Requirements',
                hint:
                        'Minimum signatories — e.g. all 3 boards, or 2-of-3'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Evidence and checklist requirements.
@SectionId('SOPE')
class SignOffProcessEvidence {
    @Form([
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
    ])
    @SerializationOrder(0)
    String? content;
}

/// Conditional or partial acceptance policies.
@SectionId('SOPA')
class SignOffProcessAcceptance {
    @Form([
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
    ])
    @SerializationOrder(0)
    String? content;
}

/// Legal and contractual consequences.
@SectionId('SOPC')
class SignOffProcessContractual {
    @Form([
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
    ])
    @SerializationOrder(0)
    String? content;
}

/// Review timeline.
@SectionId('SOPT')
class SignOffProcessTimeline {
    @Form([
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
    @SerializationOrder(0)
    String? content;
}

// ═══════════════════════════════════════════════════════════════════════════
// 14.2.6. Warranty
// ═══════════════════════════════════════════════════════════════════════════

/// 14.2.6. Warranty.
///
/// Post-acceptance warranty terms: duration, scope, service levels,
/// exclusions, and transition to standard support.
@SectionId('WATE')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-WAR')
class WarrantyTerms {
  @Form([
    Field('warrantyDuration', String, 'Warranty Duration',
        hint: 'Length of warranty period — e.g. 90 days, 6 months',
        required: true),
    Field('warrantyStartTrigger', String, 'Warranty Start Trigger',
        hint: 'What starts the warranty — sign-off date, go-live date'),
    Field('warrantyScope', String, 'Warranty Scope',
        hint: 'What is covered: defect fixes, configuration issues',
        required: true),
  ])
  @SerializationOrder(0)
  String? content;

  /// Duration and activation.
  @SerializationOrder(1)
  WarrantyDuration duration = WarrantyDuration();

  /// Scope of coverage.
  @SerializationOrder(2)
  WarrantyCoverage coverage = WarrantyCoverage();

  /// Service levels.
  @SectionId('WASELE-SERV-LST')
  @SectionIdPattern('WASELE-SERV-xxx')
  @SerializationOrder(3)
  List<WarrantyServiceLevels> serviceLevels = [];

  /// Process for defect handling.
  @SerializationOrder(4)
  WarrantyProcess process = WarrantyProcess();

  /// Transition to support.
  @SerializationOrder(5)
  WarrantyTransition transition = WarrantyTransition();

  /// Financial terms.
  @SerializationOrder(6)
  WarrantyFinancial financial = WarrantyFinancial();

  /// Warranty terms narrative.
  @ContentHelp('Detailed warranty terms description: legal context, '
      'relationship to contract, scenarios and examples, '
      'common issues and their warranty status, '
      'handover checklist for transition to support.')
  @SerializationOrder(7)
  TextSection warrantyNarrative = TextSection();
}

/// Duration and activation.
@SectionId('WADU')
class WarrantyDuration {
  @Form([
    Field('warrantyEndDate', String, 'Warranty End Date',
        hint: 'Calculated or fixed end date of warranty'),
    Field('extensionPolicy', String, 'Extension Policy',
        hint: 'Conditions for warranty extension'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scope of coverage.
@SectionId('WACO')
class WarrantyCoverage {
  @Form([
    Field('exclusions', String, 'Exclusions',
        hint: 'What is NOT covered: new features, user errors'),
    Field('coveredDeliverables', String, 'Covered Deliverables',
        hint: 'Which deliverables are under warranty'),
    Field('environmentsCovered', String, 'Environments Covered',
        hint: 'Production only, or also staging/UAT'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Service levels.
@SectionId('WASELE')
class WarrantyServiceLevels {
  @Form([
    Field('supportHours', String, 'Support Hours',
        hint: 'Hours during which warranty support is available'),
    Field('responseTimeSev1', String, 'Response Time Sev-1',
        hint: 'Initial response time — e.g. 1 hour'),
    Field('responseTimeSev2', String, 'Response Time Sev-2',
        hint: 'Initial response time — e.g. 4 hours'),
    Field('resolutionTimeSev1', String, 'Resolution Time Sev-1',
        hint: 'Target fix time — e.g. 8 hours'),
    Field('resolutionTimeSev2', String, 'Resolution Time Sev-2',
        hint: 'Target fix time — e.g. 2 business days'),
    Field('escalationContacts', String, 'Escalation Contacts',
        hint: 'Named contacts or roles for escalation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Process for defect handling.
@SectionId('WAPR')
class WarrantyProcess {
  @Form([
    Field('defectReportingChannel', String, 'Defect Reporting Channel',
        hint: 'How to report warranty defects'),
    Field('fixDeliveryMechanism', String, 'Fix Delivery Mechanism',
        hint: 'How fixes are delivered — hotfix, patch release'),
    Field('regressionTestingPolicy', String, 'Regression Testing Policy',
        hint: 'Who performs regression testing on warranty fixes'),
    Field('communicationCadence', String, 'Communication Cadence',
        hint: 'Status reporting during warranty'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Transition to support.
@SectionId('WATR')
class WarrantyTransition {
  @Form([
    Field('transitionToSupport', String, 'Transition to Standard Support',
        hint: 'How warranty transitions to ongoing support'),
    Field('postWarrantyTerms', String, 'Post-Warranty Terms',
        hint: 'Support terms after warranty expires'),
    Field('knowledgeTransferPlan', String, 'Knowledge Transfer Plan',
        hint: 'Activities to ensure support team can maintain system'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Financial terms.
@SectionId('WAFI')
class WarrantyFinancial {
  @Form([
    Field('warrantyCost', String, 'Warranty Cost',
        hint: 'Whether warranty is included in project price'),
    Field('penaltyForSlaBreaches', String, 'Penalty for SLA Breaches',
        hint: 'Contractual penalties for failing to meet warranty SLAs'),
    Field('additionalWorkCharging', String, 'Additional Work Charging',
        hint: 'How out-of-scope requests during warranty are charged'),
  ])
  @SerializationOrder(0)
  String? content;
}
