/// Section 14: Delivery Scope and Acceptance.
///
/// Agreements regarding delivery scope and acceptance for the system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 14. Delivery Scope and Acceptance.
@StandardReferences(
  [
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable scope, work breakdown, and handover',
    'ISO 21502:2020 — the guidance on project management defines deliverable definition, scope, dependencies, and handover',
  ],
  'Captures the delivery scope and acceptance agreements defining what is delivered and how it is accepted.',
)
@SectionId('DLVA')
class DeliveryScopeAndAcceptance extends DocSpecsSection {
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
  @override
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
@StandardReferences(
  [
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable scope, work breakdown, and handover',
    'ISO 21502:2020 — the guidance on project management defines deliverable definition, scope, dependencies, and handover',
  ],
  'Captures the overall delivery and service scope that enumerates what will be delivered and under what conditions.',
)
@SectionId('DLVSC')
class DeliveryScope extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// 14.1.1. Software Deliverables.
  @SerializationOrder(1)
  SoftwareDeliverables softwareDeliverables = SoftwareDeliverables();

  /// 14.1.2. Documentation Deliverables.
  @SerializationOrder(2)
  DocumentationDeliverables documentationDeliverables =
      DocumentationDeliverables();

  /// 14.1.3. Training Deliverables.
  @SerializationOrder(3)
  TrainingDeliverables trainingDeliverables = TrainingDeliverables();

  /// 14.1.4. Support Deliverables.
  @SerializationOrder(4)
  SupportDeliverables supportDeliverables = SupportDeliverables();
}

/// 14.1.1. Software Deliverables.
@StandardReferences(
  [
    'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines software products, delivery, and transition',
    'ISO/IEC/IEEE 15288:2023 — the system life-cycle processes standard defines the delivery, transition, and acceptance processes',
  ],
  'Captures the software deliverables covering application components, libraries, and deployment artifacts.',
)
@SectionId('SWDLV')
class SoftwareDeliverables extends DocSpecsSection {
  @ContentHelp('''
Software deliverables: application components, libraries, tools, scripts,
configuration files, deployment artifacts. Define for each:
- Delivery format (container images, packages, installers, source code)
- Delivery mechanism (registry, artifact repository, file transfer)
- Version requirements and compatibility constraints
- Licensing terms applicable to the deliverable
- Environment-specific variants (production, staging, development)
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Deliverable.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines software products, delivery, and transition',
    ],
    'Lists the individual software deliverables handed over as part of the delivery scope.',
  )
  @SectionId('SWDLV-ITEM-LST')
  @SectionIdPattern('SWDLV-ITEM-xxx')
  @ContentHelp('Add one entry per software deliverable.')
  @SerializationOrder(1)
  List<DeliverableEntry> items = [];
}

/// 14.1.2. Documentation Deliverables.
@StandardReferences(
  [
    'ISO/IEC/IEEE 15289:2019 — the standard for life-cycle information items defines the documentation and information products',
    'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines software products, delivery, and transition',
  ],
  'Captures the documentation deliverables covering user, technical, and operations documents.',
)
@SectionId('DCDLV')
class DocumentationDeliverables extends DocSpecsSection {
  @ContentHelp('''
Documentation deliverables: user guides, technical documentation,
operations runbooks, API documentation, architecture decision records,
release notes Template. Define format (PDF, HTML, Markdown, wiki),
delivery channel, language(s), and maintenance responsibility post-delivery.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Deliverable.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 15289:2019 — the standard for life-cycle information items defines the documentation and information products',
    ],
    'Lists the individual documentation deliverables handed over as part of the delivery scope.',
  )
  @SectionId('DCDLV-ITEM-LST')
  @SectionIdPattern('DCDLV-ITEM-xxx')
  @ContentHelp('Add one entry per documentation deliverable.')
  @SerializationOrder(1)
  List<DeliverableEntry> items = [];
}

/// 14.1.3. Training Deliverables.
@StandardReferences(
  [
    'ITIL 4 2019 — the service management framework defines service delivery, support, and training practices',
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable scope, work breakdown, and handover',
  ],
  'Captures the training deliverables covering sessions, materials, and train-the-trainer programs.',
)
@SectionId('TRDLV')
class TrainingDeliverables extends DocSpecsSection {
  @ContentHelp('''
Training deliverables: instructor-led sessions, e-learning modules,
train-the-trainer programs, quick reference cards, video tutorials,
sandbox environments. Define target audience, duration, prerequisites,
assessment criteria, and ongoing refresh schedule.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Deliverable.
  @StandardReferences(
    [
      'ITIL 4 2019 — the service management framework defines service delivery, support, and training practices',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable scope, work breakdown, and handover',
    ],
    'Lists the individual training deliverables handed over as part of the delivery scope.',
  )
  @SectionId('TRDLV-ITEM-LST')
  @SectionIdPattern('TRDLV-ITEM-xxx')
  @ContentHelp('Add one entry per training deliverable.')
  @SerializationOrder(1)
  List<DeliverableEntry> items = [];
}

/// 14.1.4. Support Deliverables.
@StandardReferences(
  [
    'ISO/IEC 20000-1:2018 — the IT service management standard defines service delivery, support, and warranty commitments',
    'ITIL 4 2019 — the service management framework defines service delivery, support, and training practices',
  ],
  'Captures the support deliverables covering transition support, warranty, and ongoing support commitments.',
)
@SectionId('SPDLV')
class SupportDeliverables extends DocSpecsSection {
  @ContentHelp('''
Support deliverables: transition support during go-live, warranty support
post-acceptance, knowledge transfer sessions, escalation contacts,
SLA definitions, support tooling and access. Define support hours,
response times, coverage period, and handover criteria.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× Deliverable.
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — the IT service management standard defines service delivery, support, and warranty commitments',
      'ITIL 4 2019 — the service management framework defines service delivery, support, and training practices',
    ],
    'Lists the individual support deliverables handed over as part of the delivery scope.',
  )
  @SectionId('SPDLV-ITEM-LST')
  @SectionIdPattern('SPDLV-ITEM-xxx')
  @ContentHelp('Add one entry per support deliverable.')
  @SerializationOrder(1)
  List<DeliverableEntry> items = [];
}

/// A deliverable entry (form).
///
/// Represents a single deliverable item within any deliverable category.
/// Captures identification, delivery logistics, quality requirements,
/// ownership, and acceptance linkage.
@StandardReferences(
  [
    'ISO 21502:2020 — the guidance on project management defines deliverable definition, scope, dependencies, and handover',
    'ISO/IEC/IEEE 15288:2023 — the system life-cycle processes standard defines the delivery, transition, and acceptance processes',
  ],
  'Represents a single deliverable item with its identification, logistics, quality, ownership, and acceptance linkage.',
)
@SectionId('DLVEN')
class DeliverableEntry extends DocSpecsSection {
  @Form([
    Field(
      'deliverableId',
      String,
      'Deliverable ID',
      hint: 'Unique identifier — e.g. DEL-SOF-001',
      required: true,
    ),
    Field(
      'deliverableName',
      String,
      'Deliverable Name',
      hint: 'Concise name — e.g. "Customer Management API"',
      required: true,
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'Critical / High / Medium / Low',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Identification details.
  @SectionId('DLVID')
  @StandardReferences([
    'ISO 21502:2020 — the guidance on project management defines deliverable definition, scope, dependencies, and handover',
    'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines software products, delivery, and transition',
  ], 'Captures the identifying description and category of a deliverable.')
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'What this deliverable contains and its purpose',
    ),
    Field(
      'category',
      String,
      'Category',
      hint: 'Application / Library / Tool / Configuration / Document',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  /// Delivery logistics.
  @SectionId('DLVLOG')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 15288:2023 — the system life-cycle processes standard defines the delivery, transition, and acceptance processes',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable scope, work breakdown, and handover',
    ],
    'Captures the delivery format, mechanism, target environment, and scheduling logistics of a deliverable.',
  )
  @Form([
    Field(
      'deliveryFormat',
      String,
      'Delivery Format',
      hint: 'Docker Image / NPM Package / Dart Package / APK / IPA',
    ),
    Field(
      'deliveryMechanism',
      String,
      'Delivery Mechanism',
      hint: 'Container Registry / Artifact Repository / App Store',
    ),
    Field(
      'deliveryEnvironment',
      String,
      'Target Environment',
      hint: 'Production / Staging / All Environments',
    ),
    Field(
      'plannedDeliveryDate',
      String,
      'Planned Delivery Date',
      hint: 'Target date — e.g. 2026-Q3',
    ),
    Field(
      'deliveryStage',
      String,
      'Delivery Stage',
      hint: 'Stage in which this deliverable is delivered',
    ),
    Field(
      'deliveryFrequency',
      String,
      'Delivery Frequency',
      hint: 'OneTime / PerRelease / Continuous / OnDemand',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? logistics;

  /// Version and compatibility.
  @SectionId('DLVVR')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines software products, delivery, and transition',
      'ISO/IEC/IEEE 15288:2023 — the system life-cycle processes standard defines the delivery, transition, and acceptance processes',
    ],
    'Captures the version requirements, compatibility constraints, and backward-compatibility posture of a deliverable.',
  )
  @Form([
    Field(
      'versionRequirement',
      String,
      'Version Requirement',
      hint: 'Minimum version or version range',
    ),
    Field(
      'compatibilityConstraints',
      String,
      'Compatibility Constraints',
      hint: 'Platform, OS, browser, or dependency version requirements',
    ),
    Field(
      'backwardCompatibility',
      String,
      'Backward Compatibility',
      hint: 'Yes / No / Partial',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? version;

  /// Quality and acceptance.
  @SectionId('DLVQL')
  @StandardReferences(
    [
      'ISO/IEC 25040:2011 — the systems and software quality evaluation standard defines the evaluation process reference model',
      'ISO/IEC/IEEE 15288:2023 — the system life-cycle processes standard defines the delivery, transition, and acceptance processes',
    ],
    'Captures the quality standards, acceptance criteria, and verification methods applied to a deliverable.',
  )
  @Form([
    Field(
      'qualityStandard',
      String,
      'Quality Standard',
      hint: 'Quality standards applied — e.g. ISO 25010, WCAG 2.1 AA',
    ),
    Field(
      'acceptanceCriteria',
      String,
      'Acceptance Criteria',
      hint: 'Specific criteria for accepting this deliverable',
    ),
    Field(
      'verificationMethod',
      String,
      'Verification Method',
      hint: 'Testing / Inspection / Review / Demonstration',
    ),
    Field(
      'testCoverage',
      String,
      'Required Test Coverage',
      hint: 'Minimum test coverage — e.g. 80% unit',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? quality;

  /// Ownership and responsibility.
  @SectionId('DLVOW')
  @StandardReferences(
    [
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable scope, work breakdown, and handover',
      'ISO 21502:2020 — the guidance on project management defines deliverable definition, scope, dependencies, and handover',
    ],
    'Captures the ownership and responsibility roles for creating, reviewing, receiving, and maintaining a deliverable.',
  )
  @Form([
    Field(
      'responsibleParty',
      String,
      'Responsible Party',
      hint: 'Team or role responsible for creating',
    ),
    Field(
      'reviewer',
      String,
      'Reviewer',
      hint: 'Who reviews and approves before delivery',
    ),
    Field(
      'recipient',
      String,
      'Recipient',
      hint: 'Who receives the deliverable',
    ),
    Field(
      'maintenanceOwner',
      String,
      'Maintenance Owner',
      hint: 'Who maintains the deliverable post-delivery',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? ownership;

  /// Dependencies.
  @StandardReferences(
    [
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable scope, work breakdown, and handover',
      'ISO 21502:2020 — the guidance on project management defines deliverable definition, scope, dependencies, and handover',
    ],
    'Lists the individual dependencies that condition the delivery of this deliverable.',
  )
  @SectionId('DLVDP-DEPE-LST')
  @SectionIdPattern('DLVDP-DEPE-xxx')
  @ContentHelp('Add one entry per delivery dependency.')
  @SerializationOrder(6)
  List<DeliverableDependencies> dependencies = [];

  /// Licensing and legal.
  @SectionId('DLVLG')
  @StandardReferences(
    [
      'ISO 21502:2020 — the guidance on project management defines deliverable definition, scope, dependencies, and handover',
      'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines software products, delivery, and transition',
    ],
    'Captures the licensing terms, intellectual-property ownership, and third-party components of a deliverable.',
  )
  @Form([
    Field(
      'licenseType',
      String,
      'License Type',
      hint: 'Commercial / OpenSource / Proprietary / Mixed',
    ),
    Field(
      'intellectualProperty',
      String,
      'IP Ownership',
      hint: 'Who owns the IP — client, vendor, shared',
    ),
    Field(
      'thirdPartyComponents',
      String,
      'Third-Party Components',
      hint: 'Third-party libraries included and their licenses',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? legal;

  /// Documentation.
  @SectionId('DLVDC')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 15289:2019 — the standard for life-cycle information items defines the documentation and information products',
      'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines software products, delivery, and transition',
    ],
    'Captures the documentation associated with a deliverable and its release-note requirements.',
  )
  @Form([
    Field(
      'associatedDocumentation',
      String,
      'Associated Documentation',
      hint: 'Related documentation deliverable IDs',
    ),
    Field(
      'releaseNotes',
      String,
      'Release Notes Required',
      hint: 'Yes / No — whether release notes accompany delivery',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional context or special instructions',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? documentation;
}

/// Dependencies for deliverable.
@StandardReferences(
  [
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable scope, work breakdown, and handover',
    'ISO 21502:2020 — the guidance on project management defines deliverable definition, scope, dependencies, and handover',
  ],
  'Captures the dependencies and prerequisites that condition when a deliverable can be delivered.',
)
@SectionId('DLVDP')
class DeliverableDependencies extends DocSpecsSection {
  @Form([
    Field(
      'dependsOn',
      String,
      'Depends On',
      hint: 'Other deliverable IDs this depends on',
    ),
    Field(
      'prerequisiteForDelivery',
      String,
      'Prerequisites',
      hint: 'Conditions that must be met before delivery',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 14.2. Acceptance Plan. Seeds → QAP.
@StandardReferences(
  [
    'ISO/IEC 25040:2011 — the systems and software quality evaluation standard defines the evaluation process reference model underpinning acceptance planning',
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable acceptance and project closure',
  ],
  'Captures the overall acceptance plan defining how project deliverables are formally accepted.',
)
@SectionId('ACPLN')
@Comment('Seeds → QAP')
@MapsTo(D10QualityAcceptancePlan)
class AcceptancePlan extends DocSpecsSection {
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
  @override
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
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines acceptance criteria and their entry and exit conditions',
    'ISO/IEC 25010:2023 — the product quality model defines the quality characteristics used as acceptance criteria',
  ],
  'Captures the formal acceptance criteria that delivered work must meet for project sign-off.',
)
@SectionId('ACRITL')
@DetailedIn(D10QualityAcceptancePlan)
class AcceptanceCriteriaList extends DocSpecsSection {
  @ContentHelp('''
Formal acceptance criteria that must be met for project sign-off.
Covers functional, non-functional, documentation, and training criteria.
Each criterion must be:
- Objectively verifiable (measurable or binary pass/fail)
- Traceable to a requirement or deliverable
- Assigned a verification method and responsible verifier
- Categorized by type and priority
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× DeliveryAcceptanceCriterion.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the acceptance-criteria and test-item structures',
      'IEEE 829-2008 — the standard for software and system test documentation defines the list of acceptance criteria in the acceptance-test plan',
    ],
    'Lists the individual acceptance criteria that delivered work must satisfy.',
  )
  @SectionId('DACEN-ITEM-LST')
  @SectionIdPattern('DACEN-ITEM-xxx')
  @ContentHelp('Add one entry per acceptance criterion.')
  @SerializationOrder(1)
  List<DeliveryAcceptanceCriterionEntry> items = [];
}

/// An acceptance criterion entry (form).
///
/// A single criterion that must be met for formal project acceptance.
/// Aligned with IEEE 830 acceptance criteria structure and ISTQB
/// acceptance test design.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the acceptance-test item and criterion structure',
    'ISO/IEC 25010:2023 — the product quality model defines the quality characteristics used to express acceptance criteria',
  ],
  'Captures a single acceptance criterion that delivered work must satisfy for formal acceptance.',
)
@SectionId('DACEN')
class DeliveryAcceptanceCriterionEntry extends DocSpecsSection {
  @Form([
    Field(
      'criterionId',
      String,
      'Criterion ID',
      hint: 'Unique identifier — e.g. AC-001',
      required: true,
    ),
    Field(
      'criterion',
      String,
      'Criterion Statement',
      hint: 'Clear, measurable statement of what must be true',
      required: true,
    ),
    Field(
      'category',
      String,
      'Category',
      hint:
          'Functional / Performance / Security / Usability / '
          'Documentation / Training / Operational / Compliance',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Priority and description.
  @SectionId('DACED')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines prioritization and description of acceptance test items',
      'ISO/IEC 25010:2023 — the product quality model defines quality characteristics that shape acceptance-criterion priority',
    ],
    'Captures the priority and detailed description that scope an acceptance criterion.',
  )
  @Form([
    Field(
      'priority',
      String,
      'Priority',
      hint: 'MustPass / ShouldPass / NiceToPass — relative importance',
    ),
    Field(
      'description',
      String,
      'Detailed Description',
      hint: 'Extended explanation including context and boundaries',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? definition;

  /// Verification method and evidence.
  @SectionId('DACEV')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines verification methods, thresholds, and evidence for acceptance criteria',
      'IEEE 829-2008 — the standard for software and system test documentation defines the procedures and evidence recorded for acceptance items',
    ],
    'Captures the verification method, thresholds, tools, and evidence required to confirm an acceptance criterion.',
  )
  @Form([
    Field(
      'verificationMethod',
      String,
      'Verification Method',
      hint:
          'Testing / Demonstration / Inspection / Analysis / '
          'Review / CertificatePresentation',
    ),
    Field(
      'verificationProcedure',
      String,
      'Verification Procedure',
      hint: 'Steps to verify — brief procedure description',
    ),
    Field(
      'acceptanceThreshold',
      String,
      'Acceptance Threshold',
      hint: 'Quantitative threshold — e.g. response < 2s, uptime >= 99.9%',
    ),
    Field(
      'measurementTool',
      String,
      'Measurement Tool',
      hint: 'Tool used to measure — e.g. JMeter, Lighthouse, manual checklist',
    ),
    Field(
      'evidenceRequired',
      String,
      'Evidence Required',
      hint: 'Documentation of proof — test report, screenshot, certificate',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? verification;

  /// Traceability links.
  @SectionId('DACET')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines traceability between test items, requirements, and acceptance criteria',
      'IEEE 829-2008 — the standard for software and system test documentation defines traceability references in acceptance-test documents',
    ],
    'Captures the requirement, deliverable, and test-scenario references that trace an acceptance criterion.',
  )
  @Form([
    Field(
      'requirementRef',
      String,
      'Requirement Reference',
      hint: 'Linked requirement ID(s) — e.g. REQ-042',
    ),
    Field(
      'deliverableRef',
      String,
      'Deliverable Reference',
      hint: 'Linked deliverable ID — e.g. DEL-SOF-001',
    ),
    Field(
      'testScenarioRef',
      String,
      'Test Scenario Reference',
      hint: 'UAT scenario ID that validates this criterion',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? traceability;

  /// Responsibility assignments.
  @SectionId('DACEOW')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the roles that verify and confirm acceptance criteria',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames responsibility assignments for deliverable acceptance',
    ],
    'Captures the verifier and approver responsible for confirming an acceptance criterion.',
  )
  @Form([
    Field(
      'verifier',
      String,
      'Verifier',
      hint: 'Role or person who performs verification',
    ),
    Field(
      'approver',
      String,
      'Approver',
      hint: 'Role or person who confirms acceptance',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? ownership;

  /// Current status and notes.
  @SectionId('DACES')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines test-item status and result reporting for acceptance criteria',
      'IEEE 829-2008 — the standard for software and system test documentation defines the test-log and status records for acceptance items',
    ],
    'Captures the current pass or fail status and notes for an acceptance criterion.',
  )
  @Form([
    Field(
      'currentStatus',
      String,
      'Current Status',
      hint: 'NotTested / Passed / Failed / Conditional / Deferred',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Clarifications, exceptions, or conditions',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? status;
}

/// 14.2.2. Acceptance Process.
///
/// Defines the formal acceptance workflow from test initiation through
/// final sign-off. Covers roles, responsibilities, timelines, escalation,
/// and decision criteria.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the acceptance-test process, its entry and exit criteria, and roles',
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames the deliverable acceptance and closure process',
  ],
  'Captures the formal acceptance-process definition covering roles, timeline, decisions, and sign-off.',
)
@SectionId('ACPR1')
@DetailedIn(D10QualityAcceptancePlan)
class AcceptanceProcess extends DocSpecsSection {
  @Form([
    Field(
      'processName',
      String,
      'Process Name',
      hint: 'e.g. "Formal Acceptance Process v2"',
    ),
    Field(
      'processOwner',
      String,
      'Process Owner',
      hint: 'Role responsible for managing the acceptance process',
    ),
    Field(
      'acceptanceType',
      String,
      'Acceptance Type',
      hint: 'Formal / Informal / Staged / Conditional',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Process overview.
  @SectionId('ACPROV')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the acceptance-test process flow from initiation to sign-off',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames the high-level deliverable acceptance workflow',
    ],
    'Captures the high-level description of the acceptance-process workflow from initiation through sign-off.',
  )
  @Form([
    Field(
      'processDescription',
      String,
      'Process Description',
      hint: 'High-level workflow: initiation → testing → review → sign-off',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Participants and governance.
  @SectionId('ACPRPA')
  @StandardReferences(
    [
      'ISO 21502:2020 — the guidance on project management defines governance roles and responsibilities for deliverable acceptance',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames stakeholder roles and RACI assignments in acceptance',
    ],
    'Captures the acceptance board, reviewers, participants, and RACI matrix that govern the acceptance process.',
  )
  @Form([
    Field(
      'acceptanceBoard',
      String,
      'Acceptance Board',
      hint: 'Members of the acceptance board',
    ),
    Field(
      'technicalReviewers',
      String,
      'Technical Reviewers',
      hint: 'Technical staff who verify technical acceptance criteria',
    ),
    Field(
      'businessReviewers',
      String,
      'Business Reviewers',
      hint: 'Business stakeholders who verify business acceptance',
    ),
    Field(
      'participants',
      String,
      'All Participants',
      hint: 'Complete list of roles involved',
    ),
    Field(
      'raciMatrix',
      String,
      'RACI Matrix',
      hint: 'Responsible / Accountable / Consulted / Informed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? participants;

  /// Timeline and schedule.
  @SectionId('ACPRTI')
  @StandardReferences(
    [
      'ISO 21502:2020 — the guidance on project management defines scheduling and milestones for deliverable acceptance and handover',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames acceptance windows and milestone timing',
    ],
    'Captures the planned duration, acceptance window, and milestones that schedule the acceptance process.',
  )
  @Form([
    Field(
      'plannedDuration',
      String,
      'Planned Duration',
      hint: 'Expected total duration of acceptance process',
    ),
    Field(
      'acceptanceWindowStart',
      String,
      'Acceptance Window Start',
      hint: 'Earliest date acceptance can begin',
    ),
    Field(
      'acceptanceWindowEnd',
      String,
      'Acceptance Window End',
      hint: 'Latest date acceptance must conclude',
    ),
    Field(
      'milestones',
      String,
      'Key Milestones',
      hint: 'Entry gate, mid-point review, final review, sign-off',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? timeline;

  /// Decision framework.
  @SectionId('ACPRDE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines exit criteria and defect thresholds governing accept and reject decisions',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable accept, reject, and conditional decisions',
    ],
    'Captures the decision criteria, defect thresholds, and conditional or rejection rules used to accept delivered work.',
  )
  @Form([
    Field(
      'decisionCriteria',
      String,
      'Decision Criteria',
      hint: 'How accept/reject/conditional decisions are made',
    ),
    Field(
      'defectThreshold',
      String,
      'Acceptable Defect Threshold',
      hint: 'Maximum open defects by severity to proceed',
    ),
    Field(
      'conditionalAcceptanceRules',
      String,
      'Conditional Acceptance Rules',
      hint: 'Conditions under which acceptance with known issues is allowed',
    ),
    Field(
      'rejectionCriteria',
      String,
      'Rejection Criteria',
      hint: 'Conditions that automatically block acceptance',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? decision;

  /// Escalation.
  @SectionId('ACPRES')
  @StandardReferences(
    [
      'ISO 21502:2020 — the guidance on project management defines escalation and dispute resolution during deliverable acceptance',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames escalation paths and issue resolution',
    ],
    'Captures the escalation process, escalation levels, and dispute-resolution approach for acceptance decisions.',
  )
  @Form([
    Field(
      'escalationProcess',
      String,
      'Escalation Process',
      hint: 'Escalation path for disputes or blockers',
    ),
    Field(
      'escalationLevels',
      String,
      'Escalation Levels',
      hint: 'L1: Project Manager, L2: Steering Committee, L3: Sponsor',
    ),
    Field(
      'disputeResolution',
      String,
      'Dispute Resolution',
      hint: 'How disagreements about acceptance are resolved',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? escalation;

  /// Documentation.
  @SectionId('ACPRDO')
  @StandardReferences(
    [
      'IEEE 829-2008 — the standard for software and system test documentation defines the acceptance-report and evidence documents',
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the test documentation retained as acceptance evidence',
    ],
    'Captures the report templates, evidence package contents, and archival requirements for acceptance documentation.',
  )
  @Form([
    Field(
      'acceptanceReportTemplate',
      String,
      'Acceptance Report Template',
      hint: 'Template for the formal acceptance report',
    ),
    Field(
      'evidencePackageContents',
      String,
      'Evidence Package Contents',
      hint: 'What must be in the evidence package',
    ),
    Field(
      'archivalRequirements',
      String,
      'Archival Requirements',
      hint: 'How acceptance evidence is archived',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? documentation;

  /// Acceptance process narrative description.
  @ContentHelp(
    'Detailed walkthrough of the acceptance process: '
    'step-by-step flow, decision points, parallel tracks, '
    'timing dependencies, and integration with project closeout.',
  )
  @SerializationOrder(7)
  TextSection processNarrative = TextSection();

  /// Contains 0+× AcceptanceStep.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the ordered steps of the acceptance-test process',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames the sequence of steps leading to deliverable acceptance',
    ],
    'Lists the individual steps that make up the formal acceptance-process workflow.',
  )
  @SectionId('ACST-STEP-LST')
  @SectionIdPattern('ACST-STEP-xxx')
  @ContentHelp('Add one entry per acceptance-process step.')
  @SerializationOrder(8)
  List<AcceptanceStepEntry> steps = [];
}

/// An acceptance step entry (form).
///
/// A single step in the formal acceptance workflow, with entry/exit
/// conditions, responsible parties, and outputs.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the acceptance-test process and its step structure',
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames the workflow steps that lead to deliverable acceptance',
  ],
  'Captures a single step in the formal acceptance workflow with its responsible role and description.',
)
@SectionId('ACST')
class AcceptanceStepEntry extends DocSpecsSection {
  @Form([
    Field(
      'stepNumber',
      String,
      'Step Number',
      hint: 'Sequential number — e.g. 1, 2, 3',
      required: true,
    ),
    Field(
      'stepName',
      String,
      'Step Name',
      hint: 'Concise action name — e.g. "Technical Review"',
      required: true,
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What happens in this step',
    ),
    Field(
      'responsibleRole',
      String,
      'Responsible Role',
      hint: 'Who performs or leads this step',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Participants and execution flow.
  @SectionId('ASEF')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines entry and exit criteria and activities for each test-process step',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames participant roles across acceptance activities',
    ],
    'Captures the participants, entry and exit criteria, and activities that make up an acceptance-process step.',
  )
  @Form([
    Field(
      'participants',
      String,
      'Participants',
      hint: 'Additional roles involved',
    ),
    Field(
      'entryCriteria',
      String,
      'Entry Criteria',
      hint: 'What must be true before this step can start',
    ),
    Field(
      'activities',
      String,
      'Activities',
      hint: 'Key activities performed in this step',
    ),
    Field(
      'exitCriteria',
      String,
      'Exit Criteria',
      hint: 'What must be true for this step to be complete',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? flow;

  /// Exit outcomes and timing.
  @SectionId('ASEO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines exit conditions and step outputs within the test process',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames step outcomes and decisions during deliverable acceptance',
    ],
    'Captures the outputs, expected duration, and decision options that conclude an acceptance-process step.',
  )
  @Form([
    Field(
      'outputs',
      String,
      'Outputs',
      hint: 'Documents, decisions, or artifacts produced',
    ),
    Field(
      'duration',
      String,
      'Expected Duration',
      hint: 'How long this step takes — e.g. 2 business days',
    ),
    Field(
      'decisionOptions',
      String,
      'Decision Options',
      hint:
          'Possible outcomes — e.g. Pass / Fail / Conditional / '
          'Escalate',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? outcome;
}

/// 14.2.3. User Acceptance Testing.
///
/// Comprehensive UAT planning covering scope, environment, test data,
/// governance, scheduling, defect management, reporting, non-functional
/// acceptance, and formal sign-off. Aligned with IEEE 829 / ISO 29119
/// test documentation structure and ISTQB best practices.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines test processes, documentation, and techniques including acceptance testing',
    'IEEE 829-2008 — the standard for software and system test documentation defines test plan, test case, test log, and acceptance-test documents',
  ],
  'Captures the full user-acceptance testing plan covering scope, environment, governance, execution, defects, reporting, and sign-off.',
)
@SectionId('USACTE')
@DetailedIn(D10QualityAcceptancePlan)
class UserAcceptanceTesting extends DocSpecsSection {
  @Form([
    Field(
      'uatObjective',
      String,
      'UAT Objective',
      hint: 'Primary goal — e.g. validate business requirements before go-live',
    ),
    Field(
      'uatApproach',
      String,
      'UAT Approach',
      hint: 'Scripted / Exploratory / Hybrid',
    ),
    Field(
      'uatLead',
      String,
      'UAT Lead',
      hint: 'Name and role of the person coordinating UAT',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Scope and objectives.
  @SectionId('UASC')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the scope, features-to-be-tested, and test types',
      'IEEE 829-2008 — the standard for software and system test documentation defines features and test types in a test plan',
    ],
    'Captures the scope summary, exclusions, and included test types for the acceptance test effort.',
  )
  @Form([
    Field(
      'scope',
      String,
      'Scope Summary',
      hint: 'Modules, features, and integrations included in UAT',
    ),
    Field(
      'outOfScope',
      String,
      'Out of Scope',
      hint: 'Explicitly excluded items',
    ),
    Field(
      'testTypes',
      String,
      'Test Types Included',
      hint: 'Functional / Regression / Usability / Accessibility / End-to-End',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Environment.
  @SectionId('UAEN')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines test-environment requirements and readiness',
      'IEEE 829-2008 — the standard for software and system test documentation defines the environmental-needs section of a test plan',
    ],
    'Captures the identity, access, configuration, refresh policy, and access control of the UAT environment.',
  )
  @Form([
    Field(
      'environmentName',
      String,
      'Environment Name',
      hint: 'Name or identifier of the UAT environment',
    ),
    Field(
      'environmentUrl',
      String,
      'Environment URL',
      hint: 'Access URL or endpoint',
    ),
    Field(
      'environmentDescription',
      String,
      'Environment Description',
      hint: 'Hardware, OS, software stack, network configuration',
    ),
    Field(
      'environmentRefreshPolicy',
      String,
      'Environment Refresh Policy',
      hint: 'How and when environment data is refreshed',
    ),
    Field(
      'environmentAccessControl',
      String,
      'Access Control',
      hint: 'Who has access, authentication method',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? environment;

  /// Test data.
  @SectionId('UATEDA')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines test-data management and requirements for test execution',
      'IEEE 829-2008 — the standard for software and system test documentation defines test-data needs in the test plan',
    ],
    'Captures the test-data strategy, preparation, privacy compliance, and refresh cadence for acceptance testing.',
  )
  @Form([
    Field(
      'testDataStrategy',
      String,
      'Test Data Strategy',
      hint: 'Synthetic / MaskedProduction / Subset',
    ),
    Field(
      'testDataPreparation',
      String,
      'Test Data Preparation',
      hint: 'Who prepares test data, lead time, and tools used',
    ),
    Field(
      'testDataPrivacy',
      String,
      'Data Privacy Compliance',
      hint: 'GDPR / HIPAA / PCI-DSS compliance',
    ),
    Field(
      'testDataRefreshCadence',
      String,
      'Test Data Refresh Cadence',
      hint: 'How often test data is refreshed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testData;

  /// Participants and governance.
  @SectionId('UAGO')
  @StandardReferences(
    [
      'ISO 21502:2020 — the guidance on project management defines governance, roles, and stakeholder responsibilities',
      'IEEE 829-2008 — the standard for software and system test documentation defines responsibilities and staffing in a test plan',
    ],
    'Captures the ownership, tester roles, support team, RACI, escalation path, and communication plan governing acceptance testing.',
  )
  @Form([
    Field(
      'businessOwner',
      String,
      'Business Owner',
      hint: 'Stakeholder accountable for UAT sign-off',
    ),
    Field(
      'testerRoles',
      String,
      'Tester Roles',
      hint: 'Business analysts, end-users, SMEs, external testers',
    ),
    Field(
      'supportTeam',
      String,
      'Support Team',
      hint: 'Dev, QA, and ops contacts available during UAT',
    ),
    Field(
      'raciSummary',
      String,
      'RACI Summary',
      hint: 'Responsible / Accountable / Consulted / Informed',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path',
      hint: 'Escalation chain for blocking defects',
    ),
    Field(
      'communicationPlan',
      String,
      'Communication Plan',
      hint: 'Status update frequency, channels, and audience',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? governance;

  /// Schedule and cycles.
  @SectionId('UASC1')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines test scheduling and milestones within the test plan',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames scheduling and milestone planning',
    ],
    'Captures the planned dates, cycle count, cycle duration, and key milestones for the acceptance test effort.',
  )
  @Form([
    Field(
      'plannedStartDate',
      String,
      'Planned Start Date',
      hint: 'Target start date for UAT execution',
    ),
    Field(
      'plannedEndDate',
      String,
      'Planned End Date',
      hint: 'Target completion date',
    ),
    Field(
      'numberOfCycles',
      String,
      'Number of Test Cycles',
      hint: 'e.g. 2 cycles — initial execution + regression',
    ),
    Field(
      'cycleDuration',
      String,
      'Cycle Duration',
      hint: 'Expected duration per cycle',
    ),
    Field(
      'milestones',
      String,
      'Key Milestones',
      hint: 'Entry gate, mid-cycle checkpoint, exit gate',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? schedule;

  /// Entry, exit, and suspension criteria.
  @SectionId('UACR')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines entry, exit, and suspension-resumption criteria for test execution',
      'IEEE 829-2008 — the standard for software and system test documentation defines suspension and resumption criteria in a test plan',
    ],
    'Captures the entry, exit, suspension, and resumption criteria that gate the acceptance test effort.',
  )
  @Form([
    Field(
      'entryCriteria',
      String,
      'Entry Criteria',
      hint: 'Prerequisites: system testing passed, environment ready',
    ),
    Field(
      'exitCriteria',
      String,
      'Exit Criteria',
      hint: 'Completion conditions: pass rate >= 95%, no Sev-1 open',
    ),
    Field(
      'suspensionCriteria',
      String,
      'Suspension Criteria',
      hint: 'Conditions that halt UAT',
    ),
    Field(
      'resumptionCriteria',
      String,
      'Resumption Criteria',
      hint: 'Conditions to restart after suspension',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? criteria;

  /// Defect management.
  @SectionId('UADEMA')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines incident and defect management within the test process',
      'IEEE 829-2008 — the standard for software and system test documentation defines the anomaly and defect report',
    ],
    'Captures the tools, severity levels, SLAs, thresholds, and triage process governing defects found during acceptance testing.',
  )
  @Form([
    Field(
      'defectTool',
      String,
      'Defect Tracking Tool',
      hint: 'Jira / Azure DevOps / ServiceNow',
    ),
    Field(
      'defectSeverityLevels',
      String,
      'Severity Levels',
      hint: 'Define Sev-1 through Sev-4 with examples',
    ),
    Field(
      'defectResolutionSla',
      String,
      'Resolution SLAs',
      hint: 'Target fix times per severity',
    ),
    Field(
      'defectThreshold',
      String,
      'Acceptable Defect Threshold',
      hint: 'Max open defects per severity to proceed',
    ),
    Field(
      'defectTriageProcess',
      String,
      'Triage Process',
      hint: 'Frequency, participants, and decision-making',
    ),
    Field(
      'retestProcess',
      String,
      'Retest Process',
      hint: 'How fixed defects are retested',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? defectManagement;

  /// Reporting.
  @SectionId('UARE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines test-status reporting and completion reports',
      'IEEE 829-2008 — the standard for software and system test documentation defines the test-summary and status reports',
    ],
    'Captures the status reporting, tracked metrics, and final-report contents for the acceptance test effort.',
  )
  @Form([
    Field(
      'dailyStatusFormat',
      String,
      'Daily Status Format',
      hint: 'Contents: executed, passed, failed, blocked',
    ),
    Field(
      'metricsTracked',
      String,
      'Metrics Tracked',
      hint: 'Pass rate, defect density, test coverage',
    ),
    Field(
      'dashboardTool',
      String,
      'Dashboard Tool',
      hint: 'Tool for real-time UAT metrics',
    ),
    Field(
      'finalReportContents',
      String,
      'Final Report Contents',
      hint: 'Summary, results matrix, open defects',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? reporting;

  /// Non-functional acceptance.
  @SectionId('UANOFU')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the product quality model defines non-functional quality characteristics used as acceptance criteria',
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines non-functional test types and techniques',
    ],
    'Captures the accessibility, performance, security, and regression acceptance conditions for the delivered system.',
  )
  @Form([
    Field(
      'accessibilityAcceptance',
      String,
      'Accessibility Acceptance',
      hint: 'WCAG level, screen-reader compatibility',
    ),
    Field(
      'performanceAcceptance',
      String,
      'Performance Acceptance',
      hint: 'Response time thresholds, concurrent users',
    ),
    Field(
      'securityAcceptance',
      String,
      'Security Acceptance',
      hint: 'Authentication, authorization, data checks',
    ),
    Field(
      'regressionApproach',
      String,
      'Regression Approach',
      hint: 'Scope and method for regression testing',
    ),
  ])
  @SerializationOrder(9)
  DocSpecsSection? nonFunctional;

  /// Sign-off.
  @SectionId('UASIOF')
  @StandardReferences(
    [
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames formal deliverable validation and acceptance sign-off',
      'ISO 21502:2020 — the guidance on project management defines deliverable acceptance and formal authorization',
    ],
    'Captures the authority, criteria, and conditional-acceptance policy governing formal UAT sign-off.',
  )
  @Form([
    Field(
      'signOffAuthority',
      String,
      'Sign-Off Authority',
      hint: 'Role(s) authorized to provide formal UAT sign-off',
    ),
    Field(
      'signOffCriteria',
      String,
      'Sign-Off Criteria',
      hint: 'Exit criteria + risk acceptance conditions',
    ),
    Field(
      'conditionalAcceptancePolicy',
      String,
      'Conditional Acceptance Policy',
      hint: 'Conditions under which UAT passes with known defects',
    ),
  ])
  @SerializationOrder(10)
  DocSpecsSection? signOff;

  /// Training and readiness.
  @SectionId('UATR')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines training and operational-readiness support activities',
      'ISO/IEC/IEEE 29119 2022 — the software testing standard frames tester readiness and preparation for test execution',
    ],
    'Captures the tester training and user-documentation readiness that prepare participants for acceptance testing.',
  )
  @Form([
    Field(
      'testerTraining',
      String,
      'Tester Training',
      hint: 'Training provided: system walkthrough, tool orientation',
    ),
    Field(
      'userDocumentation',
      String,
      'User Documentation Availability',
      hint: 'Guides, FAQs, and quick-start docs available',
    ),
  ])
  @SerializationOrder(11)
  DocSpecsSection? training;

  /// Narrative overview of the UAT approach and philosophy.
  @ContentHelp(
    'Describe the UAT philosophy, how it integrates with prior '
    'test levels, key risks, and lessons from previous projects.',
  )
  @SerializationOrder(12)
  TextSection uatOverview = TextSection();

  /// Contains 0+× UatTestCycle.
  @StandardReferences([
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the test-cycle and level-test-plan structures',
  ], 'Lists the acceptance test cycles executed during the UAT effort.')
  @SectionId('UATCY-TEST-LST')
  @SectionIdPattern('UATCY-TEST-xxx')
  @ContentHelp('Add one entry per user-acceptance test cycle.')
  @SerializationOrder(13)
  List<UatTestCycleEntry> testCycles = [];

  /// Contains 0+× TestScenario.
  @StandardReferences([
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the test-scenario and test-case structures',
  ], 'Lists the acceptance test scenarios covered by the UAT suite.')
  @SectionId('TSSC-TEST-LST')
  @SectionIdPattern('TSSC-TEST-xxx')
  @ContentHelp('Add one entry per test scenario.')
  @SerializationOrder(14)
  List<TestScenarioEntry> testScenarios = [];
}

/// A UAT test cycle entry.
///
/// Represents a distinct test execution round — e.g. Cycle 1 (initial),
/// Cycle 2 (regression/retest). Each cycle defines scope, dates, entry/exit
/// criteria, and focus areas per IEEE 829 Level Test Plan structure.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines test-cycle execution and the level test plan',
    'IEEE 829-2008 — the standard for software and system test documentation defines the level test plan structure',
  ],
  'Captures a distinct acceptance test execution round with its objective, dates, scope, and staffing.',
)
@SectionId('UATCY')
class UatTestCycleEntry extends DocSpecsSection {
  @Form([
    Field(
      'cycleName',
      String,
      'Cycle Name',
      hint: 'e.g. "Cycle 1 — Initial Execution" or "Regression Cycle"',
      required: true,
    ),
    Field(
      'cycleObjective',
      String,
      'Cycle Objective',
      hint: 'Purpose: full execution, regression, retest only, or targeted',
    ),
    Field(
      'plannedStartDate',
      String,
      'Planned Start Date',
      hint: 'Start date for this cycle',
    ),
    Field(
      'plannedEndDate',
      String,
      'Planned End Date',
      hint: 'End date for this cycle',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Scope and pass criteria for this cycle.
  @SectionId('UTCES')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines scope, entry and exit criteria for test execution',
      'IEEE 829-2008 — the standard for software and system test documentation defines features-to-be-tested and pass criteria',
    ],
    'Captures the in-scope scenarios, focus areas, entry and exit criteria, and pass criterion for an acceptance test cycle.',
  )
  @Form([
    Field(
      'scenariosInScope',
      String,
      'Scenarios in Scope',
      hint: 'Scenario IDs or categories included in this cycle',
    ),
    Field(
      'focusAreas',
      String,
      'Focus Areas',
      hint: 'Specific modules, features, or risk areas targeted',
    ),
    Field(
      'entryCriteria',
      String,
      'Cycle Entry Criteria',
      hint: 'Prerequisites specific to this cycle — e.g. prior cycle passed',
    ),
    Field(
      'exitCriteria',
      String,
      'Cycle Exit Criteria',
      hint: 'Completion conditions for this cycle',
    ),
    Field(
      'passCriterion',
      String,
      'Pass Criterion',
      hint: 'Required pass rate — e.g. >= 95% of scenarios',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Staffing and risk context.
  @SectionId('UTCEE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines staffing and risk considerations for test execution',
      'IEEE 829-2008 — the standard for software and system test documentation defines staffing and responsibilities in a test plan',
    ],
    'Captures the assigned testers and known risks for an acceptance test cycle.',
  )
  @Form([
    Field(
      'assignedTesters',
      String,
      'Assigned Testers',
      hint: 'Tester names/roles allocated for this cycle',
    ),
    Field(
      'riskNotes',
      String,
      'Risk Notes',
      hint: 'Known risks or dependencies for this cycle',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;
}

/// A test scenario entry (form).
///
/// Represents a business-level test case covering a user journey, business
/// process, or acceptance criterion. Includes full traceability, preconditions,
/// execution metadata, and pass/fail criteria per ISTQB and IEEE 829
/// Level Test Case / Level Test Procedure structures.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the test-scenario and test-case structures',
    'IEEE 829-2008 — the standard for software and system test documentation defines the level test case and level test procedure',
  ],
  'Captures a business-level acceptance test scenario covering a user journey with traceability, setup, execution, and results.',
)
@SectionId('TSSC')
class TestScenarioEntry extends DocSpecsSection {
  @Form([
    Field(
      'scenarioId',
      String,
      'Scenario ID',
      hint: 'Unique identifier — e.g. UAT-SC-001',
      required: true,
    ),
    Field(
      'scenarioName',
      String,
      'Scenario Name',
      hint: 'Concise name describing the user journey',
      required: true,
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'Critical / High / Medium / Low',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Identification.
  @SectionId('TESCID')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines identification and classification of test cases',
      'IEEE 829-2008 — the standard for software and system test documentation defines test-case identifiers and descriptions',
    ],
    'Captures the descriptive identification, complexity, and category of an acceptance test scenario.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'Detailed narrative of what is tested and why',
    ),
    Field(
      'complexity',
      String,
      'Complexity',
      hint: 'Simple / Medium / Complex',
    ),
    Field(
      'category',
      String,
      'Category',
      hint: 'Functional / Regression / Integration / End-to-End',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identification;

  /// Business context.
  @SectionId('TESCBU')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard frames business-oriented acceptance test conditions',
      'ISO 21502:2020 — the guidance on project management frames validation of business processes against deliverables',
    ],
    'Captures the business process, business rules, user role, and regulatory relevance validated by an acceptance test scenario.',
  )
  @Form([
    Field(
      'businessProcessRef',
      String,
      'Business Process Reference',
      hint: 'ID or name of the business process being validated',
    ),
    Field(
      'businessRulesValidated',
      String,
      'Business Rules Validated',
      hint: 'Business rules this scenario verifies',
    ),
    Field(
      'userRolePerforming',
      String,
      'User Role Performing Test',
      hint: 'Persona or role executing',
    ),
    Field(
      'regulatoryRelevance',
      String,
      'Regulatory Relevance',
      hint: 'Compliance requirements addressed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? business;

  /// Traceability.
  @SectionId('TESCTR')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines traceability of test cases to requirements and acceptance criteria',
      'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines the validation process linking tests to requirements',
    ],
    'Links an acceptance test scenario to its requirements, use cases, acceptance criteria, and design references.',
  )
  @Form([
    Field(
      'requirementRef',
      String,
      'Requirement Reference',
      hint: 'Requirement ID(s) — e.g. REQ-042',
    ),
    Field(
      'useCaseRef',
      String,
      'Use Case Reference',
      hint: 'Related use case ID',
    ),
    Field(
      'acceptanceCriterionRef',
      String,
      'Acceptance Criterion Reference',
      hint: 'Linked criterion ID',
    ),
    Field(
      'designRef',
      String,
      'Design / Screen Reference',
      hint: 'UI screens or mockup references',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? traceability;

  /// Preconditions and setup.
  @SectionId('TESCSE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines preconditions and test-data requirements within a test case',
      'IEEE 829-2008 — the standard for software and system test documentation defines environmental-needs and setup records',
    ],
    'Captures the preconditions, test-data requirements, and environment setup needed before an acceptance test scenario runs.',
  )
  @Form([
    Field(
      'preconditions',
      String,
      'Preconditions',
      hint: 'System state required before execution',
    ),
    Field(
      'testDataRequirements',
      String,
      'Test Data Requirements',
      hint: 'Specific data needed',
    ),
    Field(
      'environmentRequirements',
      String,
      'Environment Requirements',
      hint: 'Special environment config',
    ),
    Field(
      'dependsOnScenarios',
      String,
      'Depends on Scenarios',
      hint: 'Scenario IDs that must pass before this one',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? setup;

  /// Execution.
  @SectionId('TESCEX')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the test-execution activity and expected results',
      'IEEE 829-2008 — the standard for software and system test documentation defines the level test procedure and acceptance criteria',
    ],
    'Captures the execution summary, expected result, and acceptance criteria for an acceptance test scenario.',
  )
  @Form([
    Field(
      'testStepsSummary',
      String,
      'Test Steps Summary',
      hint: 'High-level step sequence',
    ),
    Field(
      'expectedResult',
      String,
      'Expected Result',
      hint: 'Overall expected outcome',
    ),
    Field(
      'acceptanceCriteria',
      String,
      'Acceptance Criteria',
      hint: 'Specific pass/fail conditions',
    ),
    Field(
      'estimatedDuration',
      String,
      'Estimated Duration',
      hint: 'Expected execution time',
    ),
    Field(
      'assignedTesterRole',
      String,
      'Assigned Tester Role',
      hint: 'Role or name of the person assigned',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? execution;

  /// Post-execution.
  @SectionId('TSPE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines postconditions and result evaluation within a test case',
      'IEEE 829-2008 — the standard for software and system test documentation defines the test-log and result-capture records',
    ],
    'Captures postconditions, cleanup steps, and defect thresholds evaluated after an acceptance test scenario runs.',
  )
  @Form([
    Field(
      'postconditions',
      String,
      'Postconditions',
      hint: 'Expected system state after execution',
    ),
    Field(
      'cleanupSteps',
      String,
      'Cleanup Steps',
      hint: 'Actions to reset environment',
    ),
    Field(
      'defectThreshold',
      String,
      'Defect Threshold',
      hint: 'Max defects for pass',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? postExecution;

  /// Notes.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines supplementary test-case documentation such as assumptions and risks',
    ],
    'Lists the supplementary notes captured against this acceptance test scenario.',
  )
  @SectionId('TESCNO-NOTE-LST')
  @SectionIdPattern('TESCNO-NOTE-xxx')
  @ContentHelp('Add one entry per test-scenario note.')
  @SerializationOrder(7)
  List<TestScenarioNotes> notes = [];

  /// Contains 0+× UatTestStep for this scenario.
  @StandardReferences([
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the ordered test steps that make up a test procedure',
  ], 'Lists the individual acceptance test steps that make up this scenario.')
  @SectionId('UATSST-TEST-LST')
  @SectionIdPattern('UATSST-TEST-xxx')
  @ContentHelp('Add one entry per user-acceptance test step.')
  @SerializationOrder(8)
  List<UatTestStepEntry> testSteps = [];
}

/// Notes for test scenario.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines supplementary test-case documentation such as assumptions and risks',
  ],
  'Records assumptions, risks, and clarifying notes attached to an acceptance test scenario.',
)
@SectionId('TESCNO')
class TestScenarioNotes extends DocSpecsSection {
  @Form([
    Field(
      'assumptions',
      String,
      'Assumptions',
      hint: 'Assumptions made when designing',
    ),
    Field(
      'risksAndMitigations',
      String,
      'Risks & Mitigations',
      hint: 'Known risks and mitigation strategies',
    ),
    Field('notes', String, 'Notes', hint: 'Additional context or known issues'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A UAT test step entry.
///
/// Individual step within a test scenario. Captures the action, input data,
/// expected result, and pass criteria at fine-grained level per IEEE 829
/// Level Test Procedure structure.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 2022 — the software testing standard defines the test-procedure and test-step structures',
    'IEEE 829-2008 — the standard for software and system test documentation defines the level test procedure and its steps',
  ],
  'Captures a single fine-grained test step within an acceptance test scenario, including action, input data, and pass criteria.',
)
@SectionId('UATSST')
class UatTestStepEntry extends DocSpecsSection {
  @Form([
    Field(
      'stepNumber',
      String,
      'Step Number',
      hint: 'Sequential number — e.g. 1, 2, 3',
      required: true,
    ),
    Field(
      'action',
      String,
      'Action',
      hint:
          'What the tester does — e.g. "Navigate to Invoice screen and select order"',
    ),
    Field(
      'inputData',
      String,
      'Input Data',
      hint: 'Specific data to enter — e.g. "Amount: 500.00, Currency: EUR"',
    ),
    Field(
      'expectedResult',
      String,
      'Expected Result',
      hint:
          'What should happen — e.g. "Invoice generated with correct line items"',
    ),
    Field(
      'uiScreenRef',
      String,
      'UI Screen Reference',
      hint: 'Screen or page where this step is performed',
    ),
    Field(
      'passCriteria',
      String,
      'Pass Criteria',
      hint: 'How to determine if this individual step passed',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Clarification, timing notes, or alternative paths',
    ),
  ])
  @override
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
@StandardReferences(
  [
    'IEEE 829-2008 — the standard for software and system test documentation defines test-incident and defect reporting',
    'ITIL 4 2019 — the service management framework defines defect resolution as incident and problem management',
  ],
  'Captures the defect-resolution workflow that governs how acceptance-phase defects are classified, managed, resolved, and tracked.',
)
@SectionId('DERE')
@DetailedIn(D10QualityAcceptancePlan)
class DefectResolution extends DocSpecsSection {
  @Form([
    Field(
      'severityScheme',
      String,
      'Severity Scheme',
      hint:
          'Severity levels defined — e.g. Sev-1 Critical, Sev-2 Major, '
          'Sev-3 Minor, Sev-4 Trivial',
    ),
    Field(
      'priorityScheme',
      String,
      'Priority Scheme',
      hint:
          'Priority levels — Urgent / High / Medium / Low — '
          'determines fix sequencing',
    ),
    Field(
      'classificationAuthority',
      String,
      'Classification Authority',
      hint:
          'Who decides severity/priority — UAT lead, business owner, or joint',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Classification refinement and SLA targets.
  @SectionId('DERESL')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — the IT service management standard defines service-level and problem-management targets',
      'ITIL 4 2019 — the service management framework defines defect-resolution service-level practices',
    ],
    'Captures the classification refinement and SLA targets including reclassification process and per-severity resolution times.',
  )
  @Form([
    Field(
      'reclassificationProcess',
      String,
      'Reclassification Process',
      hint:
          'How severity can be changed after initial assignment — '
          'who, when, criteria',
    ),
    Field(
      'sev1ResolutionTime',
      String,
      'Sev-1 Resolution Time',
      hint: 'Target fix time — e.g. 4 hours, next business day',
    ),
    Field(
      'sev2ResolutionTime',
      String,
      'Sev-2 Resolution Time',
      hint: 'Target fix time — e.g. 2 business days',
    ),
    Field(
      'sev3ResolutionTime',
      String,
      'Sev-3 Resolution Time',
      hint: 'Target fix time — e.g. 5 business days',
    ),
    Field(
      'sev4ResolutionTime',
      String,
      'Sev-4 Resolution Time',
      hint: 'Target fix time — e.g. next release, or backlog',
    ),
    Field(
      'slaExceptions',
      String,
      'SLA Exceptions',
      hint:
          'Conditions under which SLAs are suspended — holidays, force majeure',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? sla;

  /// Acceptance thresholds and deferral rules.
  @SectionId('DERETH')
  @StandardReferences(
    [
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames defect prioritization and deliverable acceptance thresholds',
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines acceptance criteria and test exit conditions',
    ],
    'Captures the acceptance thresholds and deferral rules including blocking thresholds, conditional-pass limits, and deferral policy.',
  )
  @Form([
    Field(
      'blockingThreshold',
      String,
      'Blocking Threshold',
      hint:
          'Max open defects that block acceptance — '
          'e.g. 0 Sev-1, 0 Sev-2 unresolved',
    ),
    Field(
      'conditionalPassThreshold',
      String,
      'Conditional Pass Threshold',
      hint:
          'Defects allowed for conditional acceptance — '
          'e.g. <= 3 Sev-3, agreed workaround for each',
    ),
    Field(
      'deferralPolicy',
      String,
      'Deferral Policy',
      hint:
          'When defects can be deferred to post-go-live — '
          'criteria and approval process',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? thresholds;

  /// Triage, retest, and escalation process.
  @SectionId('DEREPR')
  @StandardReferences(
    [
      'ITIL 4 2019 — the service management framework defines incident triage and defect-resolution practices',
      'ISO/IEC 20000-1:2018 — the IT service management standard defines problem management including triage and escalation',
    ],
    'Captures the defect triage, retest, and escalation process including tracking tools, triage cadence, and regression policy.',
  )
  @Form([
    Field(
      'defectTrackingTool',
      String,
      'Defect Tracking Tool',
      hint: 'Jira / Azure DevOps / ServiceNow — tool details',
    ),
    Field(
      'triageProcess',
      String,
      'Triage Process',
      hint:
          'Frequency, participants, and decision criteria '
          'for defect triage meetings',
    ),
    Field(
      'retestProcess',
      String,
      'Retest Process',
      hint:
          'How fixed defects are verified — who retests, '
          'environment, evidence required',
    ),
    Field(
      'regressionPolicy',
      String,
      'Regression Policy',
      hint: 'Whether fix deployment triggers regression — scope and criteria',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path',
      hint: 'Escalation for overdue defects — levels and timing',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? process;

  /// Reporting and closure rules.
  @SectionId('DERERE')
  @StandardReferences(
    [
      'IEEE 829-2008 — the standard for software and system test documentation defines test-incident and defect reporting',
      'ISO/IEC/IEEE 29119 2022 — the software testing standard defines test processes and documentation including defect reporting',
    ],
    'Captures the defect reporting and closure rules including reporting frequency, metrics tracked, and closure criteria.',
  )
  @Form([
    Field(
      'reportingFrequency',
      String,
      'Reporting Frequency',
      hint: 'Daily / Per Triage / Weekly — defect status reporting',
    ),
    Field(
      'metricsTracked',
      String,
      'Metrics Tracked',
      hint:
          'Open/closed counts, mean time to fix, aging, '
          'reopen rate, severity distribution',
    ),
    Field(
      'closureCriteria',
      String,
      'Closure Criteria',
      hint:
          'When a defect is considered closed — retest passed, '
          'evidence documented, reporter confirmed',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? reporting;

  /// Defect management narrative.
  @ContentHelp(
    'Detailed description of the defect lifecycle: '
    'from discovery through classification, assignment, fix, '
    'retest, and closure. Include workflow diagrams if applicable.',
  )
  @SerializationOrder(5)
  TextSection defectManagementNarrative = TextSection();
}

// ═══════════════════════════════════════════════════════════════════════════
// 14.2.5. Sign-off Process
// ═══════════════════════════════════════════════════════════════════════════

/// 14.2.5. Sign-off Process.
///
/// Formal sign-off process: who signs off (business acceptance board,
/// technical acceptance board), what documents are signed, legal and
/// contractual implications, and conditional acceptance handling.
@StandardReferences(
  [
    'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable acceptance, closure, and sign-off',
    'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines the acceptance-support process',
  ],
  'Captures the formal sign-off process including signatories, evidence, acceptance policies, contractual implications, and timeline.',
)
@SectionId('SIOFPR')
@DetailedIn(D10QualityAcceptancePlan)
class SignOffProcess extends DocSpecsSection {
  @Form([
    Field(
      'signOffAuthority',
      String,
      'Sign-Off Authority',
      hint:
          'Primary role/body authorized to sign — '
          'e.g. Business Acceptance Board, Project Sponsor',
      required: true,
    ),
    Field(
      'technicalSignOff',
      String,
      'Technical Sign-Off',
      hint:
          'Role for technical acceptance — '
          'e.g. Technical Lead, Solution Architect',
    ),
    Field(
      'businessSignOff',
      String,
      'Business Sign-Off',
      hint:
          'Role for business acceptance — '
          'e.g. Business Owner, Product Owner',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Signatory and quorum governance.
  @SectionId('SOPG')
  @StandardReferences(
    [
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable acceptance governance and closure',
      'ISO 21502:2020 — the guidance on project management defines deliverable acceptance and handover roles',
    ],
    'Captures the signatory and quorum governance for sign-off including operational readiness roles and quorum requirements.',
  )
  @Form([
    Field(
      'operationsSignOff',
      String,
      'Operations Sign-Off',
      hint:
          'Role for operational readiness — '
          'e.g. Operations Manager, SRE Lead',
    ),
    Field(
      'quorumRequirements',
      String,
      'Quorum Requirements',
      hint: 'Minimum signatories — e.g. all 3 boards, or 2-of-3',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? governance;

  /// Evidence and checklist requirements.
  @SectionId('SOPE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines the acceptance-support process and evidence',
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable acceptance evidence and closure',
    ],
    'Captures the evidence and checklist requirements for sign-off including document templates, required attachments, and pre-sign-off criteria.',
  )
  @Form([
    Field(
      'signOffDocumentTemplate',
      String,
      'Sign-Off Document Template',
      hint: 'Standard form/template used for formal sign-off',
    ),
    Field(
      'requiredAttachments',
      String,
      'Required Attachments',
      hint:
          'Evidence package: test reports, acceptance report, '
          'risk assessment, open defect list',
    ),
    Field(
      'signOffCriteria',
      String,
      'Sign-Off Criteria',
      hint:
          'Criteria that must be demonstrated before sign-off '
          'can proceed',
    ),
    Field(
      'preSignOffChecklistItems',
      String,
      'Pre-Sign-Off Checklist',
      hint: 'Final verification checklist — all items must be confirmed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? evidence;

  /// Conditional or partial acceptance policies.
  @SectionId('SOPA')
  @StandardReferences(
    [
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable acceptance and rejection handling',
      'ISO/IEC/IEEE 12207:2017 — the software life-cycle processes standard defines the acceptance-support and validation processes',
    ],
    'Captures the conditional and partial acceptance policies including rejection handling and outstanding-item action plans.',
  )
  @Form([
    Field(
      'conditionalAcceptancePolicy',
      String,
      'Conditional Acceptance Policy',
      hint:
          'Conditions allowing sign-off with known issues or '
          'outstanding items — action plan required',
    ),
    Field(
      'partialAcceptancePolicy',
      String,
      'Partial Acceptance Policy',
      hint:
          'Whether acceptance of individual deliverables '
          'is possible — scope and implications',
    ),
    Field(
      'rejectionProcess',
      String,
      'Rejection Process',
      hint:
          'What happens on rejection — rework, resubmission timeline, '
          'impact on project',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? acceptance;

  /// Legal and contractual consequences.
  @SectionId('SOPC')
  @StandardReferences(
    [
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable acceptance and contractual closure',
      'ISO 21502:2020 — the guidance on project management defines deliverable acceptance, handover, and closure',
    ],
    'Captures the legal and contractual consequences of sign-off including warranty activation, payment linkage, and contractual references.',
  )
  @Form([
    Field(
      'legalImplications',
      String,
      'Legal Implications',
      hint:
          'What sign-off means legally — warranties activate, '
          'payment milestones trigger, liability transfers',
    ),
    Field(
      'contractualReferences',
      String,
      'Contractual References',
      hint: 'Contract clauses governing acceptance — section numbers',
    ),
    Field(
      'paymentLinkage',
      String,
      'Payment Linkage',
      hint:
          'Payment milestones triggered by sign-off — '
          'amounts and timing',
    ),
    Field(
      'warrantyActivation',
      String,
      'Warranty Activation',
      hint:
          'When warranty period starts — from sign-off date, '
          'from go-live date',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? contractual;

  /// Review timeline.
  @SectionId('SOPT')
  @StandardReferences(
    [
      'PMBOK Guide 7th edition 2021 — the PMI project management guidance frames deliverable acceptance and closure timing',
      'ISO 21502:2020 — the guidance on project management defines deliverable acceptance and handover timelines',
    ],
    'Captures the sign-off review timeline including deadlines, review period, and silent-acceptance policy.',
  )
  @Form([
    Field(
      'signOffDeadline',
      String,
      'Sign-Off Deadline',
      hint: 'Final date by which sign-off must be obtained',
    ),
    Field(
      'reviewPeriod',
      String,
      'Review Period',
      hint:
          'Time allowed for review before sign-off — '
          'e.g. 5 business days after evidence delivery',
    ),
    Field(
      'silentAcceptancePolicy',
      String,
      'Silent Acceptance Policy',
      hint:
          'Whether non-response constitutes acceptance — '
          'Yes/No, after what period',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? timeline;

  /// Sign-off process narrative.
  @ContentHelp(
    'Detailed walkthrough of the sign-off ceremony: '
    'how the meeting is conducted, document review procedure, '
    'voting mechanism, dissent handling, and record keeping.',
  )
  @SerializationOrder(6)
  TextSection signOffNarrative = TextSection();
}

// ═══════════════════════════════════════════════════════════════════════════
// 14.2.6. Warranty
// ═══════════════════════════════════════════════════════════════════════════

/// 14.2.6. Warranty.
///
/// Post-acceptance warranty terms: duration, scope, service levels,
/// exclusions, and transition to standard support.
@StandardReferences(
  [
    'ISO/IEC 20000-1:2018 — the IT service management standard defines service warranty, support, and problem management',
    'ITIL 4 2019 — the service management framework defines warranty and support practices',
  ],
  'Captures the post-acceptance warranty terms including duration, scope, service levels, exclusions, and transition to support.',
)
@SectionId('WATE')
@DetailedIn(D10QualityAcceptancePlan)
class WarrantyTerms extends DocSpecsSection {
  @Form([
    Field(
      'warrantyDuration',
      String,
      'Warranty Duration',
      hint: 'Length of warranty period — e.g. 90 days, 6 months',
      required: true,
    ),
    Field(
      'warrantyStartTrigger',
      String,
      'Warranty Start Trigger',
      hint: 'What starts the warranty — sign-off date, go-live date',
    ),
    Field(
      'warrantyScope',
      String,
      'Warranty Scope',
      hint: 'What is covered: defect fixes, configuration issues',
      required: true,
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Duration and activation.
  @SectionId('WADU')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — the IT service management standard defines service warranty periods and commitments',
      'ISO 21502:2020 — the guidance on project management defines deliverable handover timing and closure',
    ],
    'Captures the duration and activation details of the warranty including end date and extension policy.',
  )
  @Form([
    Field(
      'warrantyEndDate',
      String,
      'Warranty End Date',
      hint: 'Calculated or fixed end date of warranty',
    ),
    Field(
      'extensionPolicy',
      String,
      'Extension Policy',
      hint: 'Conditions for warranty extension',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? duration;

  /// Scope of coverage.
  @SectionId('WACO')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — the IT service management standard defines service warranty scope and coverage boundaries',
      'ITIL 4 2019 — the service management framework defines warranty coverage and support scope',
    ],
    'Captures the scope of warranty coverage including exclusions, covered deliverables, and environments under warranty.',
  )
  @Form([
    Field(
      'exclusions',
      String,
      'Exclusions',
      hint: 'What is NOT covered: new features, user errors',
    ),
    Field(
      'coveredDeliverables',
      String,
      'Covered Deliverables',
      hint: 'Which deliverables are under warranty',
    ),
    Field(
      'environmentsCovered',
      String,
      'Environments Covered',
      hint: 'Production only, or also staging/UAT',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? coverage;

  /// Service levels.
  @StandardReferences([
    'ISO/IEC 20000-1:2018 — the IT service management standard defines service warranty and support commitments',
  ], 'Lists the warranty service elements offered during the warranty period.')
  @SectionId('WASELE-SERV-LST')
  @SectionIdPattern('WASELE-SERV-xxx')
  @ContentHelp('Add one entry per warranty service element.')
  @SerializationOrder(3)
  List<WarrantyServiceLevels> serviceLevels = [];

  /// Process for defect handling.
  @SectionId('WAPR')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — the IT service management standard defines problem and incident management for warranty defect handling',
      'ITIL 4 2019 — the service management framework defines support and defect-resolution practices during warranty',
    ],
    'Captures the process for handling warranty defects including reporting channels, fix delivery, regression testing, and communication cadence.',
  )
  @Form([
    Field(
      'defectReportingChannel',
      String,
      'Defect Reporting Channel',
      hint: 'How to report warranty defects',
    ),
    Field(
      'fixDeliveryMechanism',
      String,
      'Fix Delivery Mechanism',
      hint: 'How fixes are delivered — hotfix, patch release',
    ),
    Field(
      'regressionTestingPolicy',
      String,
      'Regression Testing Policy',
      hint: 'Who performs regression testing on warranty fixes',
    ),
    Field(
      'communicationCadence',
      String,
      'Communication Cadence',
      hint: 'Status reporting during warranty',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? process;

  /// Transition to support.
  @SectionId('WATR')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — the IT service management standard defines the transition from warranty into ongoing service support',
      'ISO 21502:2020 — the guidance on project management defines deliverable handover and closure into operations',
    ],
    'Captures how the warranty period transitions into standard ongoing support including post-warranty terms and knowledge transfer.',
  )
  @Form([
    Field(
      'transitionToSupport',
      String,
      'Transition to Standard Support',
      hint: 'How warranty transitions to ongoing support',
    ),
    Field(
      'postWarrantyTerms',
      String,
      'Post-Warranty Terms',
      hint: 'Support terms after warranty expires',
    ),
    Field(
      'knowledgeTransferPlan',
      String,
      'Knowledge Transfer Plan',
      hint: 'Activities to ensure support team can maintain system',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? transition;

  /// Financial terms.
  @SectionId('WAFI')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — the IT service management standard defines service warranty and support commitments including financial terms',
      'ISO 21502:2020 — the guidance on project management defines deliverable handover and closure including cost aspects',
    ],
    'Captures the financial terms of the warranty including cost, penalties for SLA breaches, and charging for out-of-scope work.',
  )
  @Form([
    Field(
      'warrantyCost',
      String,
      'Warranty Cost',
      hint: 'Whether warranty is included in project price',
    ),
    Field(
      'penaltyForSlaBreaches',
      String,
      'Penalty for SLA Breaches',
      hint: 'Contractual penalties for failing to meet warranty SLAs',
    ),
    Field(
      'additionalWorkCharging',
      String,
      'Additional Work Charging',
      hint: 'How out-of-scope requests during warranty are charged',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? financial;

  /// Warranty terms narrative.
  @ContentHelp(
    'Detailed warranty terms description: legal context, '
    'relationship to contract, scenarios and examples, '
    'common issues and their warranty status, '
    'handover checklist for transition to support.',
  )
  @SerializationOrder(7)
  TextSection warrantyNarrative = TextSection();
}

/// Service levels.
@StandardReferences(
  [
    'ISO/IEC 20000-1:2018 — the IT service management standard defines service warranty and support commitments including service levels',
    'ITIL 4 2019 — the service management framework defines warranty and support service-level targets',
  ],
  'Captures the warranty service-level commitments including support hours, response times, resolution times, and escalation contacts.',
)
@SectionId('WASELE')
class WarrantyServiceLevels extends DocSpecsSection {
  @Form([
    Field(
      'supportHours',
      String,
      'Support Hours',
      hint: 'Hours during which warranty support is available',
    ),
    Field(
      'responseTimeSev1',
      String,
      'Response Time Sev-1',
      hint: 'Initial response time — e.g. 1 hour',
    ),
    Field(
      'responseTimeSev2',
      String,
      'Response Time Sev-2',
      hint: 'Initial response time — e.g. 4 hours',
    ),
    Field(
      'resolutionTimeSev1',
      String,
      'Resolution Time Sev-1',
      hint: 'Target fix time — e.g. 8 hours',
    ),
    Field(
      'resolutionTimeSev2',
      String,
      'Resolution Time Sev-2',
      hint: 'Target fix time — e.g. 2 business days',
    ),
    Field(
      'escalationContacts',
      String,
      'Escalation Contacts',
      hint: 'Named contacts or roles for escalation',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
