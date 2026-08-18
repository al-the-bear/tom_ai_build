/// Section 6: Target business process facets.
///
/// Defines the two former children of the Target Business Process Model — now
/// re-parented by the csm-8-1 split: [BusinessProcessDescriptions] (process
/// narrative, seeds → TOM, ORG/OPS follow-up) and
/// [ProcessStepsAndActorInteractions] (actor interactions, seeds → ISC,
/// CodeSpecs CE-SU/CE-SC). The former `TargetBusinessProcessModel` grouping
/// container is dissolved: [BusinessProcessDescriptions] now sits in the SBP.7
/// ORG/OPS follow-up subtree (`OrganizationAndProcessConcept`) and
/// [ProcessStepsAndActorInteractions] is the SBP.7 CodeSpecs subtree.
/// Follows BPM best practices (BPMN 2.0, APQC PCF, BPM CBOK).
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// Where control goes when a branch flow finishes ([ExtensionEntry],
/// [AlternativeFlowEntry]).
///
/// The discriminator enum for the branch flows' `@OneOf` group. A branch
/// attaches to the flow it leaves at **two** points: where it diverges — its
/// branch point, a reference — and where it rejoins, which is this choice. The
/// two possibilities are not variants of one shape:
///
/// - [resumeAtStep] hands control back to a named step of the flow it left, so
///   it needs that step's identity and binds a case subsection holding it.
/// - [endFlow] hands control back to nobody: the branch is the end of the
///   scenario. It carries no payload at all, so it binds no case and is
///   declared `noCase`.
///
/// Before this enum both were one free-text field in which `"end"` and
/// `"resume at step 4"` were the same `String` with nothing structural to tell
/// them apart, and neither could be derived into code. The set is closed at
/// two because a branch either rejoins somewhere nameable or it terminates;
/// a third arm would be a control transfer the emitted body cannot express.
enum FlowReturnPoint {
  resumeAtStep,
  endFlow,
}

/// Which handling role of a server call a [ServerCallStepEntry] states.
///
/// A CodeSpecs server call (`codespecs_derivation_contract.md` §3.5.7) emits
/// three methods, and the three are not phases of one body: assembling the
/// request happens before the wire, applying the response after a successful
/// one, and surfacing an error after a failed one. Each therefore needs its own
/// ordered steps, and this is the field that says which set a step belongs to.
///
/// The three values are deliberately spelled as the three **fixed method
/// names** of `codespecs_derivation_contract.md` §3.5.7 point 4 —
/// `assembleRequest`, `handleResponse`, `handleError`. The routing word and the
/// emitted name are the same token, so they cannot drift apart: renaming one is
/// renaming the other.
///
/// The set is closed at three because those are the whole of a call's
/// handling. A fourth arm would have to name a moment that is neither before
/// the call nor after one of its two outcomes.
enum ServerCallRole {
  assembleRequest,
  handleResponse,
  handleError,
}

// ---------------------------------------------------------------------------
// 6.1 Business Process Descriptions
// ---------------------------------------------------------------------------

/// 6.1. Business Process Descriptions.
///
/// Target business processes at a high level. Each process will be expanded
/// with detailed workflows, triggers, decision points, and exception handling
/// in the TOM (Target Operating Model) document.
@StandardReferences(
  [
    'BPMN 2.0 — business process model & notation',
    'APQC PCF — Process Classification Framework',
  ],
  'Captures the target business processes the system will support, at the level '
  'of catalog, vision and design principles.',
)
@SectionId('BPDSC')
@Comment('Seeds → TOM')
@MapsTo(D02TargetOperatingModel)
class BusinessProcessDescriptions extends DocSpecsSection {
  @ContentHelp('''
Target business processes at a high level. Each process will be expanded with
detailed workflows, triggers, decision points, and exception handling in the
TOM (Target Operating Model) document.

**Subsections:**
- Process Vision — overall transformation vision and success criteria
- Design Principles — guiding principles for process design
- Process Catalog — comprehensive process definitions (1+ required)
- Process Overview Diagram — landscape and value chain views
- Improvement Summary — expected benefits and business case

**Seeds:** TOM (Target Operating Model) document
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 6.1.1. Process Vision.
  @SerializationOrder(1)
  ProcessVision processVision = ProcessVision();

  /// 6.1.2. Design Principles.
  @SerializationOrder(2)
  ProcessDesignPrinciples designPrinciples = ProcessDesignPrinciples();

  /// 6.1.3. Process Catalog — contains 1+× Business Process.
  @SerializationOrder(3)
  ProcessCatalog processCatalog = ProcessCatalog();

  /// 6.1.4. Process Overview Diagram.
  @SerializationOrder(4)
  ProcessOverviewDiagram processOverviewDiagram = ProcessOverviewDiagram();

  /// 6.1.5. Improvement Summary.
  @SerializationOrder(5)
  ProcessImprovementSummary improvementSummary = ProcessImprovementSummary();

  /// 6.1.6. Process Relationships.
  @SerializationOrder(6)
  ProcessRelationships processRelationships = ProcessRelationships();

  /// 6.1.7. Detailed Process Workflows.
  @StandardReferences(
    ['BPMN 2.0 — process flow / activities'],
    'The set of detailed, step-level workflows expanded from each catalogued '
    'process.',
  )
  @SectionId('DEPRWO-DETA-LST')
  @SectionIdPattern('DEPRWO-DETA-xxx')
  @ContentHelp('Add one entry per detailed process workflow.')
  @SerializationOrder(7)
  List<DetailedProcessWorkflow> detailedWorkflows = [];

  /// 6.1.8. Cross-Process Analysis.
  @SerializationOrder(8)
  CrossProcessAnalysis crossProcessAnalysis = CrossProcessAnalysis();

  /// 6.1.9. Process Exception Handling.
  @SerializationOrder(9)
  ProcessExceptionHandling exceptionHandling = ProcessExceptionHandling();

  /// 6.1.10. Process Metrics and KPIs.
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency',
      'Six Sigma / Lean — process improvement',
    ],
    'The measurable KPIs and metrics used to gauge each process\'s performance '
    'and improvement.',
  )
  @SectionId('PMAK-PROC-LST')
  @SectionIdPattern('PMAK-PROC-xxx')
  @ContentHelp('Add one entry per process metric or KPI.')
  @SerializationOrder(10)
  List<ProcessMetric> processMetricsAndKpis = [];
}

/// 6.1.1. Process Vision.
///
/// The overall vision for how business processes will work with the new system.
@StandardReferences(
  [
    'BABOK v3 — future-state / process analysis',
    'BPM CBOK — business process management body of knowledge',
  ],
  'Articulates the target-state vision, narrative and success criteria that '
  'guide the process transformation.',
)
@SectionId('PRVIZ')
@DetailedIn(D02TargetOperatingModel)
@FollowUpKind(
  [FollowUpProcess.org, FollowUpProcess.ops],
  note:
      'follow-up material under OrganizationAndProcessConcept in the SBP; '
      'reached here directly by a detail-document path',
)
class ProcessVision extends DocSpecsSection {
  @ContentHelp(
    'Introduce the target-state process vision before the narrative, '
    'improvement and success-criteria subsections below. Cover what changes '
    'about how the work is done, and for whom.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Process vision overview.
  @SectionId('PVOVW')
  @StandardReferences(
    ['BABOK v3 — future-state / process analysis'],
    'Summarises the overarching process vision, strategic alignment and '
    'transformation theme in a single form.',
  )
  @Form([
    Field(
      'visionStatement',
      String,
      'Vision Statement — concise statement of process future state',
      hint: 'One or two sentences describing the future-state process',
    ),
    Field(
      'strategicAlignment',
      String,
      'Strategic Alignment — how processes support business strategy',
      hint: 'Link processes to strategic goals',
    ),
    Field(
      'transformationTheme',
      String,
      'Transformation Theme — overall transformation approach',
      hint: 'The unifying theme of the change (e.g. digital, automation)',
    ),
    Field(
      'targetMaturityLevel',
      String,
      'Target Maturity Level — CMMI or similar maturity target',
      hint: 'Desired maturity level to reach',
    ),
    Field(
      'timeHorizon',
      String,
      'Time Horizon — when full vision is realized',
      hint: 'Timeframe for achieving the vision',
    ),
    Field(
      'keyEnabler',
      String,
      'Key Enablers — technology, skills, culture changes needed',
      hint: 'What must be in place to enable the vision',
    ),
    Field(
      'changeScope',
      String,
      'Change Scope — breadth and depth of process change',
      hint: 'How wide and deep the change reaches',
    ),
    Field(
      'stakeholderImpact',
      String,
      'Stakeholder Impact — who is affected and how',
      hint: 'Groups affected and the nature of impact',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Vision narrative describing the target state.
  @SerializationOrder(2)
  TextSection visionNarrative = TextSection();

  /// Expected improvements over current state.
  @StandardReferences(
    ['Six Sigma / Lean — process improvement'],
    'The set of anticipated improvements the target processes deliver over the '
    'current state.',
  )
  @SectionId('EXIPR-EXPE-LST')
  @SectionIdPattern('EXIPR-EXPE-xxx')
  @ContentHelp('Add one entry per expected improvement.')
  @SerializationOrder(3)
  List<ExpectedImprovements> expectedImprovements = [];

  /// Success criteria for process transformation.
  @SectionId('PRSUC')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency',
      'BABOK v3 — future-state / process analysis',
    ],
    'Defines the measurable criteria that determine whether the process '
    'transformation is deemed successful.',
  )
  @Form([
    Field(
      'kpiTargets',
      String,
      'KPI Targets — measurable success indicators',
      hint: 'Concrete KPI values that signal success',
    ),
    Field(
      'timeToValue',
      String,
      'Time to Value — when benefits are realized',
      hint: 'How soon benefits should appear',
    ),
    Field(
      'adoptionTargets',
      String,
      'Adoption Targets — user adoption expectations',
      hint: 'Expected user adoption levels',
    ),
    Field(
      'qualityTargets',
      String,
      'Quality Targets — defect/error rates',
      hint: 'Target defect or error rates',
    ),
    Field(
      'performanceTargets',
      String,
      'Performance Targets — response time, throughput',
      hint: 'Target response time or throughput',
    ),
    Field(
      'userSatisfaction',
      String,
      'User Satisfaction — NPS, satisfaction scores',
      hint: 'Target satisfaction or NPS scores',
    ),
    Field(
      'businessOutcomes',
      String,
      'Business Outcomes — revenue, market share impact',
      hint: 'Expected business-level outcomes',
    ),
    Field(
      'measurementApproach',
      String,
      'Measurement Approach — how success is measured',
      hint: 'How and when success is measured',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? successCriteria;
}

/// Expected improvements from process transformation.
@StandardReferences(
  ['Six Sigma / Lean — process improvement'],
  'Details a single expected improvement across efficiency, quality, cost and '
  'experience dimensions.',
)
@SectionId('EXIPR')
class ExpectedImprovements extends DocSpecsSection {
  @Form([
    Field(
      'efficiencyGains',
      String,
      'Efficiency Gains — throughput, cycle time improvements',
      hint: 'Expected gains in speed or throughput',
    ),
    Field(
      'qualityImprovements',
      String,
      'Quality Improvements — error reduction, consistency',
      hint: 'Expected reduction in errors or defects',
    ),
    Field(
      'costReduction',
      String,
      'Cost Reduction — operating cost savings',
      hint: 'Expected operating cost savings',
    ),
    Field(
      'automationRate',
      String,
      'Automation Rate — percentage of automated steps',
      hint: 'Target share of steps automated',
    ),
    Field(
      'customerExperience',
      String,
      'Customer Experience — CX improvements',
      hint: 'Expected customer-facing benefits',
    ),
    Field(
      'employeeExperience',
      String,
      'Employee Experience — EX improvements',
      hint: 'Expected benefits for staff',
    ),
    Field(
      'complianceImprovement',
      String,
      'Compliance Improvement — regulatory/audit benefits',
      hint: 'Expected regulatory or audit benefits',
    ),
    Field(
      'visibilityGains',
      String,
      'Visibility Gains — monitoring, reporting improvements',
      hint: 'Expected monitoring or reporting gains',
    ),
    Field(
      'flexibilityGains',
      String,
      'Flexibility Gains — adaptability to change',
      hint: 'Expected improvement in adaptability',
    ),
    Field(
      'integrationBenefits',
      String,
      'Integration Benefits — data flow, system integration',
      hint: 'Expected integration or data-flow benefits',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 6.1.2. Design Principles.
///
/// Principles that guide process design decisions.
@StandardReferences(
  [
    'BPM CBOK — business process management body of knowledge',
    'ISO 9001:2015 §4.4 — process approach',
  ],
  'States the guiding principles that shape how target processes are designed '
  'and where trade-offs are resolved.',
)
@SectionId('PDPRI')
@DetailedIn(D02TargetOperatingModel)
@FollowUpKind(
  [FollowUpProcess.org, FollowUpProcess.ops],
  note:
      'follow-up material under OrganizationAndProcessConcept in the SBP; '
      'reached here directly by a detail-document path',
)
class ProcessDesignPrinciples extends DocSpecsSection {
  @ContentHelp(
    'Introduce the design principles before the individual principles '
    'below. Cover where they came from and how a conflict between two of '
    'them is resolved.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Design principles overview.
  @SectionId('DPOVW')
  @StandardReferences(
    ['BPM CBOK — business process management body of knowledge'],
    'Summarises the overall philosophy and precedence rules governing the set of '
    'process design principles.',
  )
  @Form([
    Field(
      'principlePhilosophy',
      String,
      'Principle Philosophy — overall approach to process design',
      hint: 'The guiding philosophy behind the principles',
    ),
    Field(
      'priorityOrder',
      String,
      'Priority Order — how to resolve principle conflicts',
      hint: 'How competing principles are ranked',
    ),
    Field(
      'exceptionHandling',
      String,
      'Exception Handling — how deviations are managed',
      hint: 'How deviations from principles are handled',
    ),
    Field(
      'continuousImprovement',
      String,
      'Continuous Improvement — how processes evolve',
      hint: 'How principles adapt over time',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 0+× Design Principle.
  @StandardReferences(
    ['BPM CBOK — business process management body of knowledge'],
    'The set of individual design principles governing process design '
    'decisions.',
  )
  @SectionId('PDPEN-PRIN-LST')
  @SectionIdPattern('PDPEN-PRIN-xxx')
  @ContentHelp('Add one entry per process design principle.')
  @SerializationOrder(2)
  List<ProcessDesignPrincipleEntry> principles = [];
}

/// A process design principle entry (form).
@StandardReferences(
  ['BPM CBOK — business process management body of knowledge'],
  'Defines a single process design principle with its rationale, implications '
  'and trade-offs.',
)
@SectionId('PDPEN')
class ProcessDesignPrincipleEntry extends DocSpecsSection {
  @Form([
    Field(
      'category',
      String,
      'Category — efficiency, quality, compliance, user experience',
      hint: 'The dimension this principle addresses',
    ),
    Field(
      'statement',
      String,
      'Statement — the principle statement',
      hint: 'The principle expressed as a directive',
    ),
    Field(
      'rationale',
      String,
      'Rationale — why this principle matters',
      hint: 'Why the principle is important',
    ),
    Field(
      'implications',
      String,
      'Implications — what this means for process design',
      hint: 'Design consequences of applying it',
    ),
    Field(
      'examples',
      String,
      'Examples — how this principle applies',
      hint: 'Concrete examples of the principle in use',
    ),
    Field(
      'tradeoffs',
      String,
      'Trade-offs — what is sacrificed',
      hint: 'What is given up to follow the principle',
    ),
    Field(
      'priority',
      String,
      'Priority — high, medium, low',
      hint: 'Relative importance of the principle',
    ),
    Field(
      'applicability',
      String,
      'Applicability — all processes or specific types',
      hint: 'Which processes the principle applies to',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 6.1.3. Process Catalog.
///
/// Container for business process definitions.
@StandardReferences(
  [
    'APQC PCF — Process Classification Framework',
    'BPMN 2.0 — business process model & notation',
  ],
  'Holds the complete catalog of business process definitions together with '
  'their classification scheme.',
)
@SectionId('PRCAT')
@DetailedIn(D02TargetOperatingModel)
@FollowUpKind(
  [FollowUpProcess.org, FollowUpProcess.ops],
  note:
      'follow-up material under OrganizationAndProcessConcept in the SBP; '
      'reached here directly by a detail-document path',
)
class ProcessCatalog extends DocSpecsSection {
  @ContentHelp(
    'Introduce the process catalog before the classification scheme and the '
    'process entries below. Cover the scope of the catalog and what is '
    'deliberately outside it.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Process catalog overview.
  @SectionId('PCOVW')
  @StandardReferences(
    ['APQC PCF — Process Classification Framework'],
    'Summarises the scope, conventions and governance that frame the process '
    'catalog as a whole.',
  )
  @Form([
    Field(
      'totalProcessCount',
      int,
      'Total Process Count',
      hint: 'Number of processes in the catalog',
    ),
    Field(
      'scopeStatement',
      String,
      'Scope Statement — what processes are in scope',
      hint: 'What the catalog does and does not cover',
    ),
    Field(
      'classificationFramework',
      String,
      'Classification Framework — APQC PCF, custom',
      hint: 'Framework used to classify processes',
    ),
    Field(
      'namingConvention',
      String,
      'Naming Convention — process naming standards',
      hint: 'Rules for naming processes',
    ),
    Field(
      'idConvention',
      String,
      'ID Convention — process ID standards',
      hint: 'Rules for assigning process IDs',
    ),
    Field(
      'processOwnership',
      String,
      'Process Ownership — how ownership is assigned',
      hint: 'How process owners are determined',
    ),
    Field(
      'governanceModel',
      String,
      'Governance Model — change control, approval',
      hint: 'How process changes are controlled',
    ),
    Field(
      'versioningApproach',
      String,
      'Versioning Approach — how process versions are managed',
      hint: 'How process versions are tracked',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Process classification scheme.
  @SectionId('PRCCL')
  @StandardReferences(
    [
      'APQC PCF — process hierarchy',
      'BPM CBOK — business process management body of knowledge',
    ],
    'Defines the classification hierarchy used to organise processes into '
    'categories, groups and specific processes.',
  )
  @Form([
    Field(
      'level1Categories',
      String,
      'Level 1 Categories — operating, management, support',
      hint: 'Top-level process categories',
    ),
    Field(
      'level2Breakdown',
      String,
      'Level 2 Breakdown — major process groups',
      hint: 'Major process groups within each category',
    ),
    Field(
      'level3Detail',
      String,
      'Level 3 Detail — specific processes',
      hint: 'Specific processes at the detailed level',
    ),
    Field(
      'crossFunctional',
      String,
      'Cross-Functional — which processes span functions',
      hint: 'Processes that cross organisational boundaries',
    ),
    Field(
      'customerFacing',
      String,
      'Customer-Facing — which processes touch customers',
      hint: 'Processes with direct customer contact',
    ),
    Field(
      'valueDriving',
      String,
      'Value-Driving — which are core value chain',
      hint: 'Processes central to the value chain',
    ),
    Field(
      'supportProcesses',
      String,
      'Support Processes — enabling processes',
      hint: 'Enabling or support processes',
    ),
    Field(
      'managementProcesses',
      String,
      'Management Processes — governance, strategy',
      hint: 'Governance and strategic processes',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? classification;

  /// Contains 1+× Business Process.
  @StandardReferences([
    'APQC PCF — Process Classification Framework',
  ], 'The catalogued set of business processes the system will support.')
  @SectionId('BPREN-PROC-LST')
  @SectionIdPattern('BPREN-PROC-xxx')
  @Min(1)
  @ContentHelp('Add one entry per business process.')
  @SerializationOrder(3)
  List<BusinessProcessEntry> processes = [];
}

/// A business process entry.
///
/// Comprehensive business process definition following BPMN 2.0 concepts.
@StandardReferences(
  [
    'BPMN 2.0 — business process model & notation',
    'APQC PCF — Process Classification Framework',
  ],
  'Defines a single business process end to end, covering its identity, '
  'triggers, inputs/outputs, roles, performance and controls.',
)
@SectionId('BPREN')
class BusinessProcessEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this business process — the story of how it actually '
    'runs, and anything the identification, trigger, role, performance and '
    'control facets below do not capture.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Process identification.
  @SerializationOrder(1)
  ProcessIdentification identification = ProcessIdentification();

  /// Process characteristics.
  @SerializationOrder(2)
  ProcessCharacteristics characteristics = ProcessCharacteristics();

  /// Process triggers and events.
  @SerializationOrder(3)
  ProcessTriggers triggers = ProcessTriggers();

  /// Process inputs and outputs.
  @SerializationOrder(4)
  ProcessInputsOutputs inputsOutputs = ProcessInputsOutputs();

  /// Roles and responsibilities.
  @SerializationOrder(5)
  ProcessRoles roles = ProcessRoles();

  /// Process performance.
  @SerializationOrder(6)
  ProcessPerformance performance = ProcessPerformance();

  /// Process controls and compliance.
  @SerializationOrder(7)
  ProcessControls controls = ProcessControls();

  /// Technology support.
  @SerializationOrder(8)
  ProcessTechnology technology = ProcessTechnology();

  /// Process exceptions.
  @SerializationOrder(9)
  ProcessExceptions exceptions = ProcessExceptions();

  /// Process flow preview (high-level).
  @SerializationOrder(10)
  FlowDiagramSection processFlowPreview = FlowDiagramSection();
}

/// Process identification.
@StandardReferences(
  ['APQC PCF — process hierarchy'],
  'Identifies a process by ID, name and hierarchy level, plus its '
  'classification, definition and governance metadata.',
)
@SectionId('PRIDN')
class ProcessIdentification extends DocSpecsSection {
  @Form([
    Field(
      'processLevel',
      String,
      'Process Level — L1 (category), L2 (group), L3 (process), L4 (activity)',
      hint: 'Level in the process hierarchy',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Position in the process hierarchy and taxonomy.
  @SectionId('PICLS')
  @StandardReferences([
    'APQC PCF — process hierarchy',
  ], 'Places the process within the taxonomy by parent, category and type.')
  @Form([
    Field(
      'parentProcess',
      String,
      'Parent Process — higher-level process this belongs to',
      hint: 'The higher-level process this rolls up to',
    ),
    Field(
      'processCategory',
      String,
      'Process Category — operating, management, support',
      hint: 'The category the process falls into',
    ),
    Field(
      'processType',
      String,
      'Process Type — core, enabling, strategic',
      hint: 'The functional type of the process',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Narrative description, purpose, and scope.
  @SectionId('PIDEF')
  @StandardReferences(
    ['BPM CBOK — business process management body of knowledge'],
    'Describes the process in narrative form, stating what it does, why it '
    'exists and where its boundaries lie.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description — what the process does',
      hint: 'What the process actually does',
    ),
    Field(
      'purpose',
      String,
      'Purpose — why the process exists',
      hint: 'Why the process exists',
    ),
    Field(
      'scope',
      String,
      'Scope — boundaries of the process',
      hint: 'Where the process starts and ends',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? definition;

  /// Ownership and lifecycle metadata.
  @SectionId('PIGOV')
  @StandardReferences(
    ['ISO 9001:2015 §4.4 — process approach'],
    'Records ownership and lifecycle metadata such as owner, manager, effective '
    'date, version and status.',
  )
  @Form([
    Field(
      'processOwner',
      String,
      'Process Owner — accountable role/person',
      hint: 'Role or person accountable for the process',
    ),
    Field(
      'processManager',
      String,
      'Process Manager — day-to-day responsibility',
      hint: 'Role responsible for daily operation',
    ),
    Field(
      'effectiveDate',
      String,
      'Effective Date — when process is active',
      hint: 'Date the process becomes active',
    ),
    Field(
      'version',
      String,
      'Version — process version',
      hint: 'Current version of the process',
    ),
    Field(
      'status',
      String,
      'Status — draft, approved, active, retired',
      hint: 'Lifecycle status of the process',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;
}

/// Process characteristics.
@StandardReferences(
  ['BPM CBOK — business process management body of knowledge'],
  'Profiles the process by intrinsic characteristics such as complexity, '
  'frequency, duration and variability.',
)
@SectionId('PRCHR')
class ProcessCharacteristics extends DocSpecsSection {
  @Form([
    Field(
      'complexity',
      String,
      'Complexity — low, medium, high, very high',
      hint: 'Overall complexity level of the process',
    ),
    Field(
      'frequency',
      String,
      'Frequency — how often the process runs',
      hint: 'How often the process executes',
    ),
    Field(
      'averageDuration',
      String,
      'Average Duration — typical end-to-end time',
      hint: 'Typical end-to-end duration',
    ),
    Field(
      'variability',
      String,
      'Variability — how much process varies by case',
      hint: 'How much the process differs case to case',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Operational characteristics and automation level.
  @SectionId('PCOPS')
  @StandardReferences(
    [
      'BPM CBOK — business process management body of knowledge',
      'Six Sigma / Lean — process improvement',
    ],
    'Profiles the operational side of the process, including criticality and how '
    'much of it runs automatically.',
  )
  @Form([
    Field(
      'criticality',
      String,
      'Criticality — business criticality level',
      hint: 'How business-critical the process is',
    ),
    Field(
      'automationLevel',
      String,
      'Automation Level — percentage automated',
      hint: 'Share of the process that is automated',
    ),
    Field(
      'straightThroughRate',
      String,
      'Straight-Through Rate — percentage without human intervention',
      hint: 'Share completed with no human touch',
    ),
    Field(
      'exceptionRate',
      String,
      'Exception Rate — percentage requiring manual handling',
      hint: 'Share needing manual intervention',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? operations;

  /// Demand and business value profile.
  @SectionId('PCBIZ')
  @StandardReferences(
    ['BPM CBOK — business process management body of knowledge'],
    'Profiles the demand pattern and business value the process carries, from '
    'volume to cost drivers.',
  )
  @Form([
    Field(
      'volumeEstimate',
      String,
      'Volume Estimate — cases per period',
      hint: 'Expected number of cases per period',
    ),
    Field(
      'seasonality',
      String,
      'Seasonality — peaks and troughs',
      hint: 'Seasonal demand variation',
    ),
    Field(
      'valueAdded',
      String,
      'Value Added — value contributed',
      hint: 'Value the process contributes',
    ),
    Field(
      'costDriver',
      String,
      'Cost Driver — main cost factors',
      hint: 'Main factors that drive process cost',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? business;
}

/// Process triggers and events.
@StandardReferences(
  ['BPMN 2.0 — events (start/end/intermediate)'],
  'Captures how the process starts and ends, listing its triggers (start '
  'events) and end events (outcomes).',
)
@SectionId('PRTRG')
class ProcessTriggers extends DocSpecsSection {
  @ContentHelp(
    'Introduce how this process starts and ends before the trigger and '
    'end-event lists below. Cover whether it is event-, schedule- or '
    'request-driven.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Main trigger overview.
  @SectionId('TGOVW')
  @StandardReferences(
    ['BPMN 2.0 — events (start/end/intermediate)'],
    'Summarises how the process is typically triggered, including its primary '
    'trigger, channel and frequency.',
  )
  @Form([
    Field(
      'primaryTrigger',
      String,
      'Primary Trigger — main way process starts',
      hint: 'The most common way the process starts',
    ),
    Field(
      'triggerChannel',
      String,
      'Trigger Channel — UI, API, event, schedule',
      hint: 'Channel through which triggers arrive',
    ),
    Field(
      'triggerFrequency',
      String,
      'Trigger Frequency — how often triggered',
      hint: 'How often the process is triggered',
    ),
    Field(
      'peakTriggerTime',
      String,
      'Peak Trigger Time — when most triggers occur',
      hint: 'When trigger volume peaks',
    ),
    Field(
      'preTriggerState',
      String,
      'Pre-Trigger State — system state before trigger',
      hint: 'System state expected before triggering',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 0+× process trigger.
  @StandardReferences(
    ['BPMN 2.0 — events (start/end/intermediate)'],
    'The set of trigger (start-event) definitions that can initiate the '
    'process.',
  )
  @SectionId('PTREN-TRIG-LST')
  @SectionIdPattern('PTREN-TRIG-xxx')
  @ContentHelp('Add one entry per process trigger.')
  @SerializationOrder(2)
  List<ProcessTriggerEntry> triggers = [];

  /// Process end events (outcomes).
  @StandardReferences(
    ['BPMN 2.0 — events (start/end/intermediate)'],
    'The set of end-event definitions describing the possible outcomes at which '
    'the process terminates.',
  )
  @SectionId('PEEVT-ENDE-LST')
  @SectionIdPattern('PEEVT-ENDE-xxx')
  @ContentHelp('Add one entry per process end event.')
  @SerializationOrder(3)
  List<ProcessEndEventEntry> endEvents = [];
}

/// A process trigger entry.
@StandardReferences(
  ['BPMN 2.0 — events (start/end/intermediate)'],
  'Defines a single trigger (start event) that can initiate the process, with '
  'its type, source and conditions.',
)
@SectionId('PTREN')
class ProcessTriggerEntry extends DocSpecsSection {
  @Form([
    Field(
      'triggerType',
      String,
      'Trigger Type — user action, system event, timer, message, signal',
      hint: 'BPMN start-event type of the trigger',
    ),
    Field(
      'triggerSource',
      String,
      'Trigger Source — where trigger originates',
      hint: 'Where the trigger originates',
    ),
    Field(
      'triggerCondition',
      String,
      'Trigger Condition — when trigger fires',
      hint: 'Condition under which the trigger fires',
    ),
    Field(
      'triggerData',
      String,
      'Trigger Data — data provided with trigger',
      hint: 'Data carried by the trigger',
    ),
    Field(
      'priority',
      String,
      'Priority — processing priority',
      hint: 'Processing priority of this trigger',
    ),
    Field(
      'validationRules',
      String,
      'Validation Rules — checks before process starts',
      hint: 'Checks applied before the process starts',
    ),
    Field(
      'frequency',
      String,
      'Frequency — expected occurrence rate',
      hint: 'Expected occurrence rate of the trigger',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A process end event entry.
@StandardReferences(
  ['BPMN 2.0 — events (start/end/intermediate)'],
  'Defines a single end event (outcome) at which the process terminates, with '
  'its type, post-condition and follow-on action.',
)
@SectionId('PEEVT')
class ProcessEndEventEntry extends DocSpecsSection {
  @Form([
    Field(
      'endEventType',
      String,
      'End Event Type — success, error, cancellation, timeout',
      hint: 'BPMN end-event type',
    ),
    Field(
      'outcome',
      String,
      'Outcome — what this end state means',
      hint: 'What reaching this end state means',
    ),
    Field(
      'probability',
      String,
      'Probability — how often this end occurs',
      hint: 'How often this outcome occurs',
    ),
    Field(
      'postCondition',
      String,
      'Post-Condition — system state after this end',
      hint: 'System state after this end event',
    ),
    Field(
      'notificationAction',
      String,
      'Notification Action — who/what is notified',
      hint: 'Who or what is notified at this end',
    ),
    Field(
      'followOnAction',
      String,
      'Follow-On Action — what happens next',
      hint: 'What happens after this end event',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Process inputs and outputs.
@StandardReferences(
  ['BPMN 2.0 — data objects & artifacts'],
  'Captures the data the process consumes and produces, listing its inputs and '
  'outputs as data objects.',
)
@SectionId('PRINOU')
class ProcessInputsOutputs extends DocSpecsSection {
  @ContentHelp(
    'Introduce the data this process consumes and produces before the input '
    'and output lists below. Cover where the inputs originate and who '
    'consumes the outputs.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Inputs overview.
  @SectionId('INOUOV')
  @StandardReferences(
    ['BPMN 2.0 — data objects & artifacts'],
    'Summarises the inputs, outputs and overall data flow of the process at a '
    'glance.',
  )
  @Form([
    Field(
      'inputSummary',
      String,
      'Input Summary — overview of required inputs',
      hint: 'High-level overview of required inputs',
    ),
    Field(
      'outputSummary',
      String,
      'Output Summary — overview of produced outputs',
      hint: 'High-level overview of produced outputs',
    ),
    Field(
      'dataFlowSummary',
      String,
      'Data Flow Summary — how data moves through process',
      hint: 'How data flows through the process',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 0+× process input.
  @StandardReferences([
    'BPMN 2.0 — data objects & artifacts',
  ], 'The set of data inputs the process consumes.')
  @SectionId('PCINP-INPU-LST')
  @SectionIdPattern('PCINP-INPU-xxx')
  @ContentHelp('Add one entry per process input.')
  @SerializationOrder(2)
  List<ProcessInputEntry> inputs = [];

  /// Contains 0+× process output.
  @StandardReferences([
    'BPMN 2.0 — data objects & artifacts',
  ], 'The set of data outputs the process produces.')
  @SectionId('PCOUT-OUTP-LST')
  @SectionIdPattern('PCOUT-OUTP-xxx')
  @ContentHelp('Add one entry per process output.')
  @SerializationOrder(3)
  List<ProcessOutputEntry> outputs = [];
}

/// A process input entry.
@StandardReferences(
  ['BPMN 2.0 — data objects & artifacts'],
  'Defines a single data input the process consumes, with its type, source, '
  'format and validation.',
)
@SectionId('PCINP')
class ProcessInputEntry extends DocSpecsSection {
  @Form([
    Field(
      'inputType',
      String,
      'Input Type — data, document, authorization, resource',
      hint: 'Kind of input consumed',
    ),
    Field(
      'source',
      String,
      'Source — where input comes from',
      hint: 'Where the input originates',
    ),
    Field(
      'format',
      String,
      'Format — data format, file type',
      hint: 'Data format or file type',
    ),
    Field(
      'required',
      String,
      'Required — mandatory or optional',
      hint: 'Whether the input is mandatory',
    ),
    Field(
      'validationRules',
      String,
      'Validation Rules — input quality checks',
      hint: 'Quality checks applied to the input',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value — if input not provided',
      hint: 'Value used when input is absent',
    ),
    Field(
      'exampleValue',
      String,
      'Example Value — sample input',
      hint: 'A sample value for the input',
    ),
    Field(
      'securityClassification',
      String,
      'Security Classification — sensitivity level',
      hint: 'Sensitivity level of the input',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A process output entry.
@StandardReferences(
  ['BPMN 2.0 — data objects & artifacts'],
  'Defines a single data output the process produces, with its type, '
  'destination, quality and retention.',
)
@SectionId('PCOUT')
class ProcessOutputEntry extends DocSpecsSection {
  @Form([
    Field(
      'outputType',
      String,
      'Output Type — data, document, notification, state change',
      hint: 'Kind of output produced',
    ),
    Field(
      'destination',
      String,
      'Destination — where output goes',
      hint: 'Where the output is sent',
    ),
    Field(
      'format',
      String,
      'Format — data format, file type',
      hint: 'Data format or file type',
    ),
    Field(
      'qualityStandard',
      String,
      'Quality Standard — output quality requirements',
      hint: 'Quality requirements for the output',
    ),
    Field(
      'timingRequirement',
      String,
      'Timing Requirement — when output must be available',
      hint: 'When the output must be ready',
    ),
    Field(
      'retentionPeriod',
      String,
      'Retention Period — how long output is kept',
      hint: 'How long the output is retained',
    ),
    Field(
      'securityClassification',
      String,
      'Security Classification — sensitivity level',
      hint: 'Sensitivity level of the output',
    ),
    Field(
      'dependentProcesses',
      String,
      'Dependent Processes — processes that need this output',
      hint: 'Processes that consume this output',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Process roles and responsibilities.
@StandardReferences(
  [
    'RACI — responsibility assignment',
    'BPM CBOK — business process management body of knowledge',
  ],
  'Captures the roles that participate in the process and how responsibility is '
  'assigned across them.',
)
@SectionId('PRRO')
class ProcessRoles extends DocSpecsSection {
  @ContentHelp(
    'Introduce the participants in this process before the per-role entries '
    'below. Cover how responsibility is split and where the hand-offs '
    'occur.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Roles overview.
  @SectionId('PRROOV')
  @StandardReferences(
    ['RACI — responsibility assignment'],
    'Summarises the key roles in the process and their RACI relationships at a '
    'glance.',
  )
  @Form([
    Field(
      'primaryActor',
      String,
      'Primary Actor — main role executing',
      hint: 'The main role that executes the process',
    ),
    Field(
      'processOwner',
      String,
      'Process Owner — accountable for outcomes',
      hint: 'Role accountable for process outcomes',
    ),
    Field(
      'supportRoles',
      String,
      'Support Roles — assisting roles',
      hint: 'Roles that assist the process',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path — who handles issues',
      hint: 'Who issues are escalated to',
    ),
    Field(
      'raciSummary',
      String,
      'RACI Summary — responsibility assignment overview',
      hint: 'Overview of the RACI assignments',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 0+× process role.
  @StandardReferences(
    ['RACI — responsibility assignment'],
    'The set of role definitions participating in the process and their RACI '
    'assignments.',
  )
  @SectionId('PCROL-ROLE-LST')
  @SectionIdPattern('PCROL-ROLE-xxx')
  @ContentHelp('Add one entry per process role.')
  @SerializationOrder(2)
  List<ProcessRoleEntry> roles = [];
}

/// A process role entry.
@StandardReferences(
  ['RACI — responsibility assignment'],
  'Defines a single role in the process, its RACI type and its '
  'responsibilities, execution and coordination detail.',
)
@SectionId('PCROL')
class ProcessRoleEntry extends DocSpecsSection {
  @Form([
    Field(
      'raciType',
      String,
      'RACI Type — Responsible, Accountable, Consulted, Informed',
      hint: 'The RACI assignment for this role',
    ),
    Field(
      'responsibilities',
      String,
      'Responsibilities — what this role does',
      hint: 'What this role is responsible for',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Process participation and authority.
  @SectionId('PREE')
  @StandardReferences(
    [
      'RACI — responsibility assignment',
      'BPMN 2.0 — business process model & notation',
    ],
    'Describes how a role participates in the process and what decisions it is '
    'authorised to make.',
  )
  @Form([
    Field(
      'stepsInvolved',
      String,
      'Steps Involved — which process steps',
      hint: 'List the steps this role performs',
    ),
    Field(
      'decisionAuthority',
      String,
      'Decision Authority — what decisions can be made',
      hint: 'State the decisions this role may make',
    ),
    Field(
      'skillsRequired',
      String,
      'Skills Required — competencies needed',
      hint: 'List the competencies the role needs',
    ),
    Field(
      'systemAccess',
      String,
      'System Access — required system permissions',
      hint: 'Name the system permissions required',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? execution;

  /// Access, coverage, and handoff expectations.
  @SectionId('PREC')
  @StandardReferences(
    [
      'RACI — responsibility assignment',
      'BPM CBOK — business process management body of knowledge',
    ],
    'Captures when a role must be available, who covers it, and how work is '
    'handed off to and from it.',
  )
  @Form([
    Field(
      'availability',
      String,
      'Availability — when role must be available',
      hint: 'Describe required availability windows',
    ),
    Field(
      'backupRole',
      String,
      'Backup Role — who covers absence',
      hint: 'Name the role that covers absences',
    ),
    Field(
      'handoffTo',
      String,
      'Handoff To — roles this passes work to',
      hint: 'List downstream roles receiving work',
    ),
    Field(
      'handoffFrom',
      String,
      'Handoff From — roles this receives work from',
      hint: 'List upstream roles supplying work',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? coordination;
}

/// Process performance metrics.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency', 'BPM CBOK — process performance'],
  'Groups the performance targets, KPIs, and service level agreements used to '
  'measure how well this process performs.',
)
@SectionId('PP')
class ProcessPerformance extends DocSpecsSection {
  @ContentHelp(
    'Introduce how this process is measured before the KPI and SLA lists '
    'below. Cover the measurement period and the data source behind the '
    'numbers.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Performance overview.
  @SectionId('PRPEOV')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency',
      'BPM CBOK — process performance',
    ],
    'Summarises the top-level performance targets and monitoring approach for '
    'the process.',
  )
  @Form([
    Field(
      'targetCycleTime',
      String,
      'Target Cycle Time — expected end-to-end duration',
      hint: 'Give the expected end-to-end duration',
    ),
    Field(
      'targetThroughput',
      String,
      'Target Throughput — expected cases per period',
      hint: 'Give the expected cases per period',
    ),
    Field(
      'targetQuality',
      String,
      'Target Quality — error rate, first-time-right',
      hint: 'State the target error/first-time-right rate',
    ),
    Field(
      'targetCost',
      String,
      'Target Cost — cost per transaction',
      hint: 'Give the target cost per transaction',
    ),
    Field(
      'targetCustomerSat',
      String,
      'Target Customer Satisfaction — CSAT/NPS target',
      hint: 'Give the CSAT/NPS satisfaction target',
    ),
    Field(
      'monitoringFrequency',
      String,
      'Monitoring Frequency — how often metrics reviewed',
      hint: 'State how often metrics are reviewed',
    ),
    Field(
      'dashboardLocation',
      String,
      'Dashboard Location — where metrics are visible',
      hint: 'Name where the metrics dashboard lives',
    ),
    Field(
      'improvementGoals',
      String,
      'Improvement Goals — targets for next period',
      hint: 'State improvement targets for next period',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 0+× performance metric.
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency',
  ], 'The set of KPIs tracked for this process.')
  @SectionId('PCKPI-KPIS-LST')
  @SectionIdPattern('PCKPI-KPIS-xxx')
  @ContentHelp('Add one entry per KPI tracked for this process.')
  @SerializationOrder(2)
  List<ProcessKpiEntry> kpis = [];

  /// Service Level Agreements.
  @StandardReferences([
    'ITIL 4 — service level management',
    'ISO/IEC 25010 — performance efficiency',
  ], 'The set of service level agreements committed for this process.')
  @SectionId('PCSLA-SLAS-LST')
  @SectionIdPattern('PCSLA-SLAS-xxx')
  @ContentHelp('Add one entry per service level agreement for this process.')
  @SerializationOrder(3)
  List<ProcessSlaEntry> slas = [];
}

/// A process KPI entry.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency', 'BPM CBOK — process performance'],
  'Defines a single key performance indicator used to measure how well this '
  'process meets its targets.',
)
@SectionId('PCKPI')
class ProcessKpiEntry extends DocSpecsSection {
  @Form([
    Field(
      'category',
      String,
      'Category — time, quality, cost, volume, satisfaction',
      hint: 'Classify the KPI dimension',
    ),
    Field(
      'definition',
      String,
      'Definition — how KPI is calculated',
      hint: 'Describe the calculation formula',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Measurement targets and thresholds.
  @SectionId('PKEM')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency'],
    'Specifies the unit, target value, thresholds, and data source used to '
    'measure a KPI.',
  )
  @Form([
    Field(
      'unit',
      String,
      'Unit — measurement unit',
      hint: 'State the unit of measurement',
    ),
    Field(
      'targetValue',
      String,
      'Target Value — target',
      hint: 'Give the target value to achieve',
    ),
    Field(
      'thresholds',
      String,
      'Thresholds — green/yellow/red boundaries',
      hint: 'Define the RAG threshold boundaries',
    ),
    Field(
      'dataSource',
      String,
      'Data Source — where data comes from',
      hint: 'Name the source of the data',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? measurement;

  /// Reporting ownership and improvement use.
  @SectionId('PKEO')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency',
      'RACI — responsibility assignment',
    ],
    'Captures how often a KPI is calculated and reported, who owns it, and how '
    'it can be improved.',
  )
  @Form([
    Field(
      'calculationFrequency',
      String,
      'Calculation Frequency — how often measured',
      hint: 'State how often the KPI is calculated',
    ),
    Field(
      'reportingFrequency',
      String,
      'Reporting Frequency — how often reported',
      hint: 'State how often the KPI is reported',
    ),
    Field(
      'owner',
      String,
      'Owner — who is accountable',
      hint: 'Name the accountable owner',
    ),
    Field(
      'improvementLever',
      String,
      'Improvement Lever — how to improve this KPI',
      hint: 'Describe how to move the KPI',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? operations;
}

/// A process SLA entry.
@StandardReferences(
  [
    'ITIL 4 — service level management',
    'ISO/IEC 25010 — performance efficiency',
  ],
  'Defines a single service level agreement, its target, measurement, and '
  'breach consequences for the process.',
)
@SectionId('PCSLA')
class ProcessSlaEntry extends DocSpecsSection {
  @Form([
    Field(
      'serviceDescription',
      String,
      'Service Description — what is promised',
      hint: 'Describe the promised service',
    ),
    Field(
      'targetLevel',
      String,
      'Target Level — commitment',
      hint: 'State the committed target level',
    ),
    Field(
      'measurementMethod',
      String,
      'Measurement Method — how compliance measured',
      hint: 'Describe how compliance is measured',
    ),
    Field(
      'reportingPeriod',
      String,
      'Reporting Period — measurement window',
      hint: 'Give the measurement window',
    ),
    Field(
      'penaltyClause',
      String,
      'Penalty Clause — consequence of breach',
      hint: 'State the consequence of a breach',
    ),
    Field(
      'escalationProcedure',
      String,
      'Escalation Procedure — when SLA at risk',
      hint: 'Describe escalation when at risk',
    ),
    Field(
      'exclusions',
      String,
      'Exclusions — what is not covered',
      hint: 'List what the SLA excludes',
    ),
    Field(
      'reviewFrequency',
      String,
      'Review Frequency — when SLA is reviewed',
      hint: 'State how often the SLA is reviewed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Process controls and compliance.
@StandardReferences(
  [
    'BPMN 2.0 — gateways / decision points',
    'ISO 9001:2015 §4.4 — process approach',
  ],
  'Groups the control framework and individual controls that keep the process '
  'compliant and manage its risks.',
)
@SectionId('PRCO')
class ProcessControls extends DocSpecsSection {
  @ContentHelp(
    'Introduce the control framework for this process before the individual '
    'controls below. Cover which risks the controls address and who tests '
    'them.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Controls overview.
  @SectionId('PRCOOV')
  @StandardReferences(
    [
      'BPMN 2.0 — gateways / decision points',
      'ISO 9001:2015 §4.4 — process approach',
    ],
    'Summarises the control framework, risk level, and compliance requirements '
    'governing the process.',
  )
  @Form([
    Field(
      'controlFramework',
      String,
      'Control Framework — COSO, COBIT, custom',
      hint: 'Name the governing control framework',
    ),
    Field(
      'riskLevel',
      String,
      'Risk Level — inherent risk',
      hint: 'State the inherent risk level',
    ),
    Field(
      'complianceRequirements',
      String,
      'Compliance Requirements — regulations, standards',
      hint: 'List applicable regulations/standards',
    ),
    Field(
      'auditFrequency',
      String,
      'Audit Frequency — when audited',
      hint: 'State how often the process is audited',
    ),
    Field(
      'segregationOfDuties',
      String,
      'Segregation of Duties — duty separation rules',
      hint: 'Describe duty separation rules',
    ),
    Field(
      'approvalMatrix',
      String,
      'Approval Matrix — who approves what',
      hint: 'Define who approves which actions',
    ),
    Field(
      'documentationRequirements',
      String,
      'Documentation Requirements — what must be recorded',
      hint: 'List what must be documented',
    ),
    Field(
      'retentionRequirements',
      String,
      'Retention Requirements — how long to keep records',
      hint: 'State record retention periods',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 0+× process control.
  @StandardReferences([
    'BPMN 2.0 — gateways / decision points',
  ], 'The set of controls applied to this process.')
  @SectionId('PCCTL-CONT-LST')
  @SectionIdPattern('PCCTL-CONT-xxx')
  @ContentHelp('Add one entry per control applied to this process.')
  @SerializationOrder(2)
  List<ProcessControlEntry> controls = [];
}

/// A process control entry.
@StandardReferences(
  [
    'BPMN 2.0 — gateways / decision points',
    'ISO 9001:2015 §4.4 — process approach',
  ],
  'Defines a single control point applied to the process, including its type '
  'and category.',
)
@SectionId('PCCTL')
class ProcessControlEntry extends DocSpecsSection {
  @Form([
    Field(
      'controlType',
      String,
      'Control Type — preventive, detective, corrective',
      hint: 'Classify the control type',
    ),
    Field(
      'controlCategory',
      String,
      'Control Category — authorization, validation, reconciliation',
      hint: 'Classify the control category',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Control operation and ownership.
  @SectionId('PCEO')
  @StandardReferences(
    [
      'BPMN 2.0 — gateways / decision points',
      'RACI — responsibility assignment',
    ],
    'Describes how a control operates, what risk it addresses, and who owns it.',
  )
  @Form([
    Field(
      'controlDescription',
      String,
      'Control Description — what the control does',
      hint: 'Describe what the control does',
    ),
    Field(
      'riskAddressed',
      String,
      'Risk Addressed — what risk is mitigated',
      hint: 'State the risk it mitigates',
    ),
    Field(
      'controlOwner',
      String,
      'Control Owner — who is responsible',
      hint: 'Name the responsible owner',
    ),
    Field(
      'frequency',
      String,
      'Frequency — how often control operates',
      hint: 'State how often the control runs',
    ),
    Field(
      'automation',
      String,
      'Automation — manual, semi-automated, fully automated',
      hint: 'State the automation level',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? operation;

  /// Evidence, testing, and failure handling.
  @SectionId('PCEV')
  @StandardReferences(
    [
      'BPMN 2.0 — gateways / decision points',
      'ISO 9001:2015 §4.4 — process approach',
    ],
    'Captures the evidence a control produces, how it is tested, and what '
    'happens when it fails.',
  )
  @Form([
    Field(
      'evidenceProduced',
      String,
      'Evidence Produced — what documentation is created',
      hint: 'Describe the evidence generated',
    ),
    Field(
      'testingApproach',
      String,
      'Testing Approach — how control is tested',
      hint: 'Describe how the control is tested',
    ),
    Field(
      'failureAction',
      String,
      'Failure Action — what happens if control fails',
      hint: 'State the action on control failure',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? verification;
}

/// Process technology support.
@StandardReferences(
  [
    'BPM CBOK — business process management body of knowledge',
    'BPMN 2.0 — business process model & notation',
  ],
  'Describes the systems, integrations, and automation tooling that support '
  'the execution of this process.',
)
@SectionId('PRTE')
class ProcessTechnology extends DocSpecsSection {
  @Form([
    Field(
      'primarySystem',
      String,
      'Primary System — main system supporting process',
      hint: 'Name the main supporting system',
    ),
    Field(
      'supportingSystems',
      String,
      'Supporting Systems — other systems involved',
      hint: 'List other systems involved',
    ),
    Field(
      'integrations',
      String,
      'Integrations — system integrations required',
      hint: 'List required system integrations',
    ),
    Field(
      'automationTools',
      String,
      'Automation Tools — RPA, workflow, rules engines',
      hint: 'List automation tools used',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data, reporting, and document tooling.
  @SectionId('PRTEIN')
  @StandardReferences(
    ['BPM CBOK — business process management body of knowledge'],
    'Captures the data stores, reporting, communication, and document tooling '
    'the process relies on.',
  )
  @Form([
    Field(
      'dataRepositories',
      String,
      'Data Repositories — databases, data stores',
      hint: 'List the databases and data stores',
    ),
    Field(
      'reportingTools',
      String,
      'Reporting Tools — BI, dashboards',
      hint: 'List BI and dashboard tools',
    ),
    Field(
      'communicationTools',
      String,
      'Communication Tools — email, notifications',
      hint: 'List communication/notification tools',
    ),
    Field(
      'documentManagement',
      String,
      'Document Management — document storage',
      hint: 'Name the document storage system',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? information;

  /// Access channel and analytics capabilities.
  @SectionId('PRTEEX')
  @StandardReferences(
    [
      'BPM CBOK — business process management body of knowledge',
      'ISO/IEC 25010 — performance efficiency',
    ],
    'Captures the access channels and analytics capabilities available for the '
    'process, such as mobile, offline, and process mining.',
  )
  @Form([
    Field(
      'mobileCapability',
      String,
      'Mobile Capability — mobile access needs',
      hint: 'State mobile access requirements',
    ),
    Field(
      'offlineCapability',
      String,
      'Offline Capability — offline operation needs',
      hint: 'State offline operation requirements',
    ),
    Field(
      'analyticsCapability',
      String,
      'Analytics Capability — process mining, analytics',
      hint: 'State analytics/process mining needs',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? experience;
}

/// Process exceptions and error handling.
@StandardReferences(
  [
    'BPMN 2.0 — exceptions / error events',
    'BPM CBOK — business process management body of knowledge',
  ],
  'Groups the exception-handling philosophy and the individual exception '
  'scenarios that can occur during the process.',
)
@SectionId('PREX')
class ProcessExceptions extends DocSpecsSection {
  @ContentHelp(
    'Introduce the exception-handling philosophy for this process before '
    'the individual exception scenarios below. Cover what is handled '
    'in-process and what is escalated out of it.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Exceptions overview.
  @SectionId('PREXOV')
  @StandardReferences(
    [
      'BPMN 2.0 — exceptions / error events',
      'BPM CBOK — business process management body of knowledge',
    ],
    'Summarises how exceptions are handled overall, including routing, SLAs, and '
    'root-cause practices.',
  )
  @Form([
    Field(
      'exceptionPhilosophy',
      String,
      'Exception Philosophy — how exceptions are handled',
      hint: 'State the overall exception approach',
    ),
    Field(
      'exceptionRate',
      String,
      'Exception Rate — expected percentage',
      hint: 'Give the expected exception rate',
    ),
    Field(
      'exceptionRouting',
      String,
      'Exception Routing — where exceptions go',
      hint: 'State where exceptions are routed',
    ),
    Field(
      'resolutionSla',
      String,
      'Resolution SLA — time to resolve exceptions',
      hint: 'Give the exception resolution SLA',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path — who handles escalations',
      hint: 'Name who handles escalations',
    ),
    Field(
      'rootCauseAnalysis',
      String,
      'Root Cause Analysis — how causes are identified',
      hint: 'Describe root-cause analysis approach',
    ),
    Field(
      'continuousImprovement',
      String,
      'Continuous Improvement — how exceptions drive change',
      hint: 'Describe how exceptions drive change',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 0+× exception scenario.
  @StandardReferences([
    'BPMN 2.0 — exceptions / error events',
  ], 'The set of exception scenarios handled by this process.')
  @SectionId('PCEXC-EXCE-LST')
  @SectionIdPattern('PCEXC-EXCE-xxx')
  @ContentHelp('Add one entry per exception scenario for this process.')
  @SerializationOrder(2)
  List<ProcessExceptionEntry> exceptions = [];
}

/// A process exception entry.
@StandardReferences(
  ['BPMN 2.0 — exceptions / error events'],
  'Defines a single exception scenario, its type, and the condition that '
  'triggers it.',
)
@SectionId('PCEXC')
class ProcessExceptionEntry extends DocSpecsSection {
  @Form([
    Field(
      'exceptionType',
      String,
      'Exception Type — data error, system error, business rule, timeout',
      hint: 'Classify the exception type',
    ),
    Field(
      'triggerCondition',
      String,
      'Trigger Condition — what causes this exception',
      hint: 'Describe what triggers the exception',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Likelihood, impact, and detection.
  @SectionId('PEEA')
  @StandardReferences([
    'BPMN 2.0 — exceptions / error events',
  ], 'Assesses how likely an exception is, its impact, and how it is detected.')
  @Form([
    Field(
      'probability',
      String,
      'Probability — how often this occurs',
      hint: 'State how likely the exception is',
    ),
    Field(
      'impact',
      String,
      'Impact — effect on process/business',
      hint: 'Describe the impact if it occurs',
    ),
    Field(
      'detectionMethod',
      String,
      'Detection Method — how exception is detected',
      hint: 'Describe how it is detected',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? assessment;

  /// Resolution and prevention approach.
  @SectionId('PEER')
  @StandardReferences(
    ['BPMN 2.0 — exceptions / error events'],
    'Defines how an exception is resolved and prevented, including owner, SLA, '
    'and workarounds.',
  )
  @Form([
    Field(
      'resolutionSteps',
      String,
      'Resolution Steps — how to resolve',
      hint: 'Describe the steps to resolve it',
    ),
    Field(
      'resolutionOwner',
      String,
      'Resolution Owner — who resolves',
      hint: 'Name who resolves the exception',
    ),
    Field(
      'resolutionSla',
      String,
      'Resolution SLA — time to resolve',
      hint: 'Give the resolution SLA',
    ),
    Field(
      'preventionStrategy',
      String,
      'Prevention Strategy — how to prevent',
      hint: 'Describe how to prevent recurrence',
    ),
    Field(
      'workArounds',
      String,
      'Workarounds — temporary solutions',
      hint: 'List temporary workarounds',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? response;
}

/// 6.1.4. Process Overview Diagram.
///
/// High-level process flow diagram showing main processes and relationships.
@StandardReferences(
  [
    'BPMN 2.0 — collaboration/choreography diagrams',
    'BPMN 2.0 — business process model & notation',
  ],
  'Provides the high-level diagrams that show the main processes and how they '
  'relate to one another.',
)
@SectionId('PROVDI')
@DetailedIn(D02TargetOperatingModel)
@FollowUpKind(
  [FollowUpProcess.org, FollowUpProcess.ops],
  note:
      'follow-up material under OrganizationAndProcessConcept in the SBP; '
      'reached here directly by a detail-document path',
)
class ProcessOverviewDiagram extends DocSpecsSection {
  @ContentHelp(
    'Introduce the process landscape before the landscape, hierarchy and '
    'value-chain diagrams below. Cover the reading order and the level of '
    'detail each diagram shows.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Diagram overview.
  @SectionId('PRDIOV')
  @StandardReferences(
    ['BPMN 2.0 — collaboration/choreography diagrams'],
    'Explains the purpose, scope, notation, and legend needed to read the '
    'process overview diagrams.',
  )
  @Form([
    Field(
      'diagramPurpose',
      String,
      'Diagram Purpose — what the diagram shows',
      hint: 'State what the diagram conveys',
    ),
    Field(
      'diagramScope',
      String,
      'Diagram Scope — what is included/excluded',
      hint: 'State what is in and out of scope',
    ),
    Field(
      'notation',
      String,
      'Notation — BPMN, flowchart, swimlane',
      hint: 'Name the diagram notation used',
    ),
    Field(
      'readingGuide',
      String,
      'Reading Guide — how to interpret the diagram',
      hint: 'Explain how to read the diagram',
    ),
    Field(
      'legend',
      String,
      'Legend — symbol meanings',
      hint: 'Define the symbols used',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Main process landscape diagram.
  @SerializationOrder(2)
  FlowDiagramSection landscapeDiagram = FlowDiagramSection();

  /// Process hierarchy diagram.
  @SerializationOrder(3)
  FlowDiagramSection hierarchyDiagram = FlowDiagramSection();

  /// Value chain diagram.
  @SerializationOrder(4)
  FlowDiagramSection valueChainDiagram = FlowDiagramSection();
}

/// 6.1.5. Improvement Summary.
///
/// Summary of expected improvements over current processes.
@StandardReferences(
  [
    'Six Sigma / Lean — process improvement',
    'BPM CBOK — business process management body of knowledge',
  ],
  'Summarises the expected improvements over the current processes, including '
  'the individual improvements and their business case.',
)
@SectionId('PRIMSU')
@DetailedIn(D02TargetOperatingModel)
@FollowUpKind(
  [FollowUpProcess.org, FollowUpProcess.ops],
  note:
      'follow-up material under OrganizationAndProcessConcept in the SBP; '
      'reached here directly by a detail-document path',
)
class ProcessImprovementSummary extends DocSpecsSection {
  @ContentHelp(
    'Introduce the improvements expected over the current processes before '
    'the itemized improvements and the business case below. Cover the '
    'baseline they are measured against.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Improvement overview.
  @SectionId('IMOV')
  @StandardReferences(
    ['Six Sigma / Lean — process improvement'],
    'Describes the overall improvement theme, baseline and target dates, and how '
    'benefits will be realised.',
  )
  @Form([
    Field(
      'improvementTheme',
      String,
      'Improvement Theme — overall improvement approach',
      hint: 'State the overall improvement theme',
    ),
    Field(
      'baselineDate',
      String,
      'Baseline Date — when current state measured',
      hint: 'Give the baseline measurement date',
    ),
    Field(
      'targetDate',
      String,
      'Target Date — when improvements achieved',
      hint: 'Give the target achievement date',
    ),
    Field(
      'benefitRealizationPlan',
      String,
      'Benefit Realization Plan — how benefits are tracked',
      hint: 'Describe how benefits are tracked',
    ),
    Field(
      'changeEnablers',
      String,
      'Change Enablers — what makes improvement possible',
      hint: 'List what enables the improvement',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 0+× improvement item.
  @StandardReferences([
    'Six Sigma / Lean — process improvement',
  ], 'The set of process improvements planned in this summary.')
  @SectionId('PCIMV-IMPR-LST')
  @SectionIdPattern('PCIMV-IMPR-xxx')
  @ContentHelp('Add one entry per planned process improvement.')
  @SerializationOrder(2)
  List<ProcessImprovementEntry> improvements = [];

  /// Business case summary.
  @SectionId('IMBUCA')
  @StandardReferences(
    [
      'Six Sigma / Lean — process improvement',
      'BPM CBOK — business process management body of knowledge',
    ],
    'Summarises the financial business case for the improvements, including '
    'investment, benefits, and return metrics.',
  )
  @Form([
    Field(
      'totalInvestment',
      String,
      'Total Investment — cost of transformation',
      hint: 'Give the total investment cost',
    ),
    Field(
      'annualBenefits',
      String,
      'Annual Benefits — yearly value delivered',
      hint: 'Give the yearly value delivered',
    ),
    Field(
      'paybackPeriod',
      String,
      'Payback Period — time to break even',
      hint: 'Give the time to break even',
    ),
    Field(
      'roi',
      String,
      'ROI — return on investment',
      hint: 'Give the return on investment',
    ),
    Field(
      'npv',
      String,
      'NPV — net present value',
      hint: 'Give the net present value',
    ),
    Field(
      'intangibleBenefits',
      String,
      'Intangible Benefits — non-financial value',
      hint: 'List non-financial benefits',
    ),
    Field(
      'riskAdjustment',
      String,
      'Risk Adjustment — confidence factor',
      hint: 'State the confidence/risk factor',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? businessCase;
}

/// A process improvement entry.
@StandardReferences(
  ['Six Sigma / Lean — process improvement'],
  'Defines a single planned improvement, its category, and the current-state '
  'baseline it improves upon.',
)
@SectionId('PCIMV')
class ProcessImprovementEntry extends DocSpecsSection {
  @Form([
    Field(
      'category',
      String,
      'Category — efficiency, quality, cost, experience',
      hint: 'Classify the improvement category',
    ),
    Field(
      'currentState',
      String,
      'Current State — baseline measurement',
      hint: 'Give the current-state baseline',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Target outcome and value case.
  @SectionId('PIEB')
  @StandardReferences(
    ['Six Sigma / Lean — process improvement'],
    'Captures the target state, expected gain, and monetary value of an '
    'improvement.',
  )
  @Form([
    Field(
      'targetState',
      String,
      'Target State — target measurement',
      hint: 'Give the target-state measurement',
    ),
    Field(
      'improvementPercent',
      String,
      'Improvement Percent — expected improvement',
      hint: 'Give the expected percent gain',
    ),
    Field(
      'monetaryBenefit',
      String,
      'Monetary Benefit — financial value',
      hint: 'Give the financial value',
    ),
    Field(
      'beneficiaries',
      String,
      'Beneficiaries — who benefits',
      hint: 'Name who benefits from it',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? benefits;

  /// Enablers, dependencies, and verification.
  @SectionId('PIED')
  @StandardReferences(
    ['Six Sigma / Lean — process improvement'],
    'Captures the enablers, dependencies, risks, and verification method for an '
    'improvement.',
  )
  @Form([
    Field(
      'enablers',
      String,
      'Enablers — what makes this possible',
      hint: 'List what enables the improvement',
    ),
    Field(
      'dependencies',
      String,
      'Dependencies — what must happen first',
      hint: 'List prerequisites for delivery',
    ),
    Field(
      'risks',
      String,
      'Risks — what could go wrong',
      hint: 'List delivery risks',
    ),
    Field(
      'measurementMethod',
      String,
      'Measurement Method — how improvement is verified',
      hint: 'Describe how the gain is verified',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? delivery;
}

/// Process relationships and dependencies (supplementary section).
@StandardReferences(
  ['APQC PCF — process hierarchy', 'BPMN 2.0 — process collaboration'],
  'Maps the dependencies, data flows, and sequencing between this process and '
  'other processes.',
)
@SectionId('PR')
@DetailedIn(D02TargetOperatingModel)
@FollowUpKind(
  [FollowUpProcess.org, FollowUpProcess.ops],
  note:
      'follow-up material under OrganizationAndProcessConcept in the SBP; '
      'reached here directly by a detail-document path',
)
class ProcessRelationships extends DocSpecsSection {
  @ContentHelp('''
Process relationships map dependencies, data flows, and sequencing between
processes. Understanding these relationships is critical for integration
design and identifying optimization opportunities.

**Relationship Types:**
- Triggers — one process starts another
- Feeds — output of one becomes input to another
- Depends on — must complete before another starts
- Parallel with — can run concurrently with another

**Best Practices:**
- Map all inter-process data exchanges
- Identify timing dependencies and constraints
- Document API/integration points between processes
- Highlight bottleneck relationships for optimization
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× process relationship.
  @StandardReferences([
    'APQC PCF — process hierarchy',
    'BPMN 2.0 — process collaboration',
  ], 'The set of relationships between this process and other processes.')
  @SectionId('PCRLT-RELA-LST')
  @SectionIdPattern('PCRLT-RELA-xxx')
  @ContentHelp('Add one entry per relationship to another process.')
  @SerializationOrder(1)
  List<ProcessRelationshipEntry> relationships = [];
}

/// A process relationship entry.
@StandardReferences(
  ['APQC PCF — process hierarchy', 'BPMN 2.0 — process collaboration'],
  'Defines a single relationship between two processes, including type, data '
  'exchanged, and timing dependency.',
)
@SectionId('PCRLT')
class ProcessRelationshipEntry extends DocSpecsSection {
  @Form([
    Field(
      'sourceProcess',
      String,
      'Source Process',
      hint: 'Name the source process',
    ),
    Field(
      'targetProcess',
      String,
      'Target Process',
      hint: 'Name the target process',
    ),
    Field(
      'relationshipType',
      String,
      'Relationship Type — triggers, feeds, depends on, parallel with',
      hint: 'Classify the relationship type',
    ),
    Field(
      'dataExchanged',
      String,
      'Data Exchanged — what flows between processes',
      hint: 'State what data flows between them',
    ),
    Field(
      'timingDependency',
      String,
      'Timing Dependency — must complete before, can run parallel',
      hint: 'State the timing dependency',
    ),
    Field(
      'frequencyOfInteraction',
      String,
      'Frequency of Interaction — how often they interact',
      hint: 'State how often they interact',
    ),
    Field(
      'criticality',
      String,
      'Criticality — how critical is this relationship',
      hint: 'State how critical the relationship is',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2 Process Steps and Actor Interactions
// ---------------------------------------------------------------------------

/// 6.2. Process Steps and Actor Interactions. Seeds → ISC.
///
/// Key process steps with their actor interactions. Each interaction will be
/// expanded into a full use case with alternate paths, preconditions, and
/// postconditions in the ISC document. Follows Cockburn-style use case
/// modeling.
@StandardReferences(
  [
    'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
    'Cockburn — Writing Effective Use Cases: actor goals & levels (primary/secondary/offstage)',
    'ISO/IEC/IEEE 29148 §6 — stakeholders & operational context',
  ],
  'Captures the key process steps and how actors interact with the system, '
  'seeding full use cases with actors, interaction catalog and scenarios.',
)
@SectionId('PSAAI')
@Comment('Seeds → ISC')
@MapsTo(D05InteractionScenarios)
@NoArtifact(
  NoArtifactReason.container,
  note:
      'chapter node; actors, interactions and scenarios are routed '
      'individually',
)
class ProcessStepsAndActorInteractions extends DocSpecsSection {
  @ContentHelp('''
Key process steps with their actor interactions. Each interaction will be
expanded into a full use case with alternate paths, preconditions, and
postconditions in the ISC (Interaction Scenarios) document.

**Subsections:**
- Actor Overview — comprehensive actor definitions with goals and permissions
- Interaction Catalog — use case seeds following Cockburn patterns (1+ required)
- Key Scenarios — end-to-end user journey descriptions (1+ required)

**Best Practices:**
- Follow Cockburn goal levels: +summary, !user, -subfunction
- Use active verb phrases for interaction names ("Submit Registration")
- Include MoSCoW prioritization (must/should/could/won't)
- Map interactions to processes (TOM-xxx) and requirements (REQ-xxx)

**Seeds:** ISC (Interaction Scenarios) document
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Section overview.
  @SerializationOrder(1)
  ProcessStepsOverview overview = ProcessStepsOverview();

  /// 6.2.1. Actor Overview — contains 1+× Actor.
  @SerializationOrder(2)
  ActorOverview actorOverview = ActorOverview();

  /// 6.2.2. Interaction Catalog — contains 1+× Interaction.
  @SerializationOrder(3)
  InteractionCatalog interactionCatalog = InteractionCatalog();

  /// 6.2.3. Key Scenarios — contains 1+× Scenario.
  @SerializationOrder(4)
  KeyScenarios keyScenarios = KeyScenarios();

  /// Actor relationship diagram.
  @SerializationOrder(5)
  ActorRelationshipDiagram actorRelationshipDiagram =
      ActorRelationshipDiagram();

  /// 6.2.4. End-to-End Test Scenarios..
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing (test scenarios)',
      'Cockburn — Writing Effective Use Cases: actor goals & levels (primary/secondary/offstage)',
    ],
    'The set of end-to-end test scenarios that exercise complete user journeys '
    'across processes and use cases.',
  )
  @SectionId('ETETS-ENDT-LST')
  @SectionIdPattern('ETETS-ENDT-xxx')
  @ContentHelp('Add one entry per end-to-end test scenario.')
  @SerializationOrder(6)
  List<EndToEndTestScenario> endToEndTestScenarios = [];

  /// 6.2.5. Use Case Traceability.
  @SerializationOrder(7)
  UseCaseTraceability useCaseTraceability = UseCaseTraceability();
}

/// 6.2. Process Steps Overview.
@StandardReferences(
  [
    'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
    'Cockburn — Writing Effective Use Cases: actor goals & levels (primary/secondary/offstage)',
  ],
  'Frames the scope, actor focus and notation conventions used for the process '
  'steps and actor-interaction modeling.',
)
@SectionId('PRSTOV')
@DetailedIn(D05InteractionScenarios)
@NoArtifact(
  NoArtifactReason.overview,
  note:
      'frames scope, actor focus and notation; every fact is stated by the '
      'actor and interaction entries below',
)
class ProcessStepsOverview extends DocSpecsSection {
  @Form([
    Field(
      'useCaseScope',
      String,
      'Use Case Scope — system, organization, subsystem',
      hint: 'State the design scope of the use cases',
    ),
    Field(
      'primaryActorFocus',
      String,
      'Primary Actor Focus — main user types',
      hint: 'Name the main actor types the interactions center on',
    ),
    Field(
      'interactionCoverage',
      String,
      'Interaction Coverage — scope of interactions',
      hint: 'Describe how much of the interaction space is covered',
    ),
    Field(
      'scenarioCoverage',
      String,
      'Scenario Coverage — what scenarios are included',
      hint: 'List which end-to-end scenarios are in scope',
    ),
    Field(
      'useCaseNamingConvention',
      String,
      'Use Case Naming Convention — ISC-xxx pattern',
      hint: 'State the naming/ID pattern for use cases',
    ),
    Field(
      'traceabilityApproach',
      String,
      'Traceability Approach — link to TOM, ISC documents',
      hint: 'Explain how interactions trace to TOM and ISC',
    ),
    Field(
      'detailLevel',
      String,
      'Detail Level — brief, casual, fully dressed',
      hint: 'Choose the Cockburn detail level applied',
    ),
    Field(
      'notationStandard',
      String,
      'Notation Standard — Cockburn, Fowler, RUP',
      hint: 'Name the use-case notation standard followed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 6.2. Actor Relationship Diagram.
@StandardReferences(
  [
    'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
    'BPMN 2.0 — collaboration / pools & lanes (participants)',
  ],
  'Visualises the actor hierarchy and actor-system interactions as '
  'generalization and collaboration diagrams.',
)
@SectionId('ACREDI')
@DetailedIn(D05InteractionScenarios)
@NoArtifact(
  NoArtifactReason.view,
  note:
      'a diagram over generalization and collaboration relationships already '
      'declared on the actor entries',
)
class ActorRelationshipDiagram extends DocSpecsSection {
  @ContentHelp(
    'Introduce the actor landscape before the hierarchy and actor-system '
    'diagrams below. Cover which actors are human, which are systems, and '
    'how they generalize.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Diagram overview.
  @SectionId('ACDIOV')
  @StandardReferences(
    [
      'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
      'BPMN 2.0 — collaboration / pools & lanes (participants)',
    ],
    'Explains the purpose, categories and notation of the actor relationship '
    'diagram.',
  )
  @Form([
    Field(
      'diagramPurpose',
      String,
      'Diagram Purpose — show actor relationships',
      hint: 'State what the diagram is meant to communicate',
    ),
    Field(
      'actorCategories',
      String,
      'Actor Categories — primary, secondary, supporting',
      hint: 'List the actor categories shown in the diagram',
    ),
    Field(
      'systemBoundary',
      String,
      'System Boundary — what is inside/outside',
      hint: 'Define what lies inside vs outside the system',
    ),
    Field(
      'notation',
      String,
      'Notation — UML use case, custom',
      hint: 'Name the diagram notation used',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Actor hierarchy diagram (generalization relationships).
  @SerializationOrder(2)
  FlowDiagramSection actorHierarchy = FlowDiagramSection();

  /// Actor-system interaction overview diagram.
  @SerializationOrder(3)
  FlowDiagramSection actorSystemDiagram = FlowDiagramSection();
}

// ---------------------------------------------------------------------------
// 6.1.7 Detailed Process Workflows
// ---------------------------------------------------------------------------

/// 6.1.7. Detailed Process Workflows.
///
/// Per-process workflow detail beyond the catalog overview.
///.
@StandardReferences([
  'BPMN 2.0 — process flow / activities & sequence flows',
  'APQC PCF — process hierarchy',
], 'Captures the step-by-step target workflow for a single catalogued process.')
@SectionId('DEPRWO')
@DetailedIn(D02TargetOperatingModel)
@CodeSpecKind(
  [CodeSpecPart.workflow],
  note:
      'CE-WF — multi-step process / workflow orchestration (state '
      'machines, long-running processes). Deferred PERMANENTLY (codespecs_mapping.md §4.3.1, '
      'codespecs_mapping.md §4.3.2): this section is free text, so there is no machine-readable '
      'input a generator could read. Mapping-only; the realistic cases are '
      'served by CE-JB jobs, CE-AC actions and CE-DB state.',
)
class DetailedProcessWorkflow extends DocSpecsSection {
  @ContentHelp('''
Step-level detail for each process in the catalog: activity sequence,
decision points, handoffs, swim lanes, timing, and system-actor vs human
actor responsibility.

**What to capture:**
- Activity list with inputs / outputs per step
- Decision points with branch conditions
- Handoff points between actors / systems
- Timing expectations and SLAs per step
- Error and exception branches
- BPMN-style diagram per process
''')
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.1.8 Cross-Process Analysis
// ---------------------------------------------------------------------------

/// 6.1.8. Cross-Process Analysis.
///
/// Hand-offs, shared data, and coordination patterns between processes.
///.
@StandardReferences(
  [
    'BPM CBOK — process architecture / interdependencies',
    'APQC PCF — process interactions',
  ],
  'Analyses how catalogued processes interact, share data, and coordinate across boundaries.',
)
@SectionId('CRPRAN')
@DetailedIn(D02TargetOperatingModel)
@FollowUpKind(
  [FollowUpProcess.org, FollowUpProcess.ops],
  note:
      'follow-up material under OrganizationAndProcessConcept in the SBP; '
      'reached here directly by a detail-document path',
)
class CrossProcessAnalysis extends DocSpecsSection {
  @ContentHelp('''
Cross-cutting view of how processes interact: shared entities, data
exchanged, synchronization points, and conflicts.

**What to capture:**
- Shared business entities and which processes create / read / update them
- Synchronization points (process A must complete before B)
- Conflict analysis (processes competing for the same resource)
- Event flows between processes
- Matrix view of processes x shared artifacts
''')
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.1.9 Process Exception Handling
// ---------------------------------------------------------------------------

/// 6.1.9. Process Exception Handling.
///
/// Exception flows, escalation paths, and compensation logic. Covers
///
@StandardReferences(
  [
    'BPMN 2.0 — error / exception events',
    'ISO 9001:2015 §8.7 — control of nonconforming outputs',
  ],
  'Defines how the target processes detect, escalate, and recover from exceptions that interrupt normal flow.',
)
@SectionId('PREXHA')
@DetailedIn(D02TargetOperatingModel)
@FollowUpKind(
  [FollowUpProcess.org, FollowUpProcess.ops],
  note:
      'follow-up material under OrganizationAndProcessConcept in the SBP; '
      'reached here directly by a detail-document path',
)
class ProcessExceptionHandling extends DocSpecsSection {
  @ContentHelp('''
Handling of exceptions that interrupt a normal process flow. Distinct
from UI-level error handling — this is about business
process recovery.

**What to capture:**
- Exception catalog (what can go wrong at which step)
- Escalation matrix (who is notified, who decides)
- Compensation / rollback activities
- Retry strategies and timeouts
- Manual-intervention procedures
- Audit requirements for handled exceptions
''')
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.4 End-to-End Test Scenarios
// ---------------------------------------------------------------------------

/// 6.2.4. End-to-End Test Scenarios.
///
/// Test scenarios that exercise complete user journeys across processes
/// and use cases..
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing (test scenarios)',
    'Cockburn — Writing Effective Use Cases: actor goals & levels (primary/secondary/offstage)',
  ],
  'Defines a single end-to-end test scenario exercising a complete user journey '
  'across processes and use cases.',
)
@SectionId('ETETS')
@DetailedIn(D05InteractionScenarios)
@FollowUpKind(
  [FollowUpProcess.acc],
  note:
      'feeds the quality/acceptance test strategy and the Phase 5 test '
      'derivation step',
)
class EndToEndTestScenario extends DocSpecsSection {
  @ContentHelp('''
End-to-end test scenarios derived from use cases and key user journeys.
Feeds BQP test strategy and the Phase 5 test derivation step.

**What to capture:**
- Scenario catalog (name, user journey, success criteria)
- Actor, data, and system preconditions
- Step-by-step expected behavior
- Variation matrix (happy path + key alternates)
- Exit criteria for each scenario
- Cross-reference to use cases and requirements
''')
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.1 Actor Overview
// ---------------------------------------------------------------------------

/// 6.2.1. Actor Overview.
///
/// Actors represent roles that interact with the system. Follows UML actor
/// modeling conventions with Cockburn-style goal and scope annotations.
@StandardReferences(
  [
    'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
    'Cockburn — Writing Effective Use Cases: actor goals & levels (primary/secondary/offstage)',
    'BABOK v3 — stakeholder & actor analysis',
  ],
  'Enumerates the actors (roles) that interact with the system, with their '
  'categories, goals and permissions.',
)
@SectionId('ACOV')
@DetailedIn(D05InteractionScenarios)
@NoArtifact(
  NoArtifactReason.overview,
  note:
      'introduces the actor entries below; every actor fact is in ACEN',
)
class ActorOverview extends DocSpecsSection {
  @ContentHelp('''
Actors represent roles that interact with the system. Following UML actor
modeling conventions with Cockburn-style goal and scope annotations.

**Actor Categories:**
- Primary — actors who initiate interactions to achieve goals
- Secondary — actors who support primary actors
- Offstage — stakeholders with interests but no direct interaction
- System — external systems that interact via APIs/integrations
- Timer/Scheduled — time-triggered automated actors

**For Each Actor Document:**
- Identification (ID, name, type, category, organizational unit)
- Characteristics (skills, usage patterns, accessibility needs)
- Goals (summary/user/subfunction goals, pain points, motivations)
- Permissions (security clearance, RBAC roles, approval limits)
- Technology profile (channels, devices, authentication methods)
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Actor overview narrative.
  @SectionId('ACOVNA')
  @StandardReferences(
    [
      'BABOK v3 — stakeholder & actor analysis',
      'Cockburn — Writing Effective Use Cases: actor goals & levels (primary/secondary/offstage)',
    ],
    'Summarises the actor population — counts by type and how actors were '
    'identified, prioritised and aligned to business goals.',
  )
  @Form([
    Field(
      'totalActorCount',
      int,
      'Total Actor Count',
      hint: 'Enter the total number of actors',
    ),
    Field(
      'humanActorCount',
      int,
      'Human Actor Count',
      hint: 'Enter how many actors are human users',
    ),
    Field(
      'systemActorCount',
      int,
      'System Actor Count',
      hint: 'Enter how many actors are internal systems',
    ),
    Field(
      'externalActorCount',
      int,
      'External Actor Count',
      hint: 'Enter how many actors are external systems',
    ),
    Field(
      'actorIdentificationApproach',
      String,
      'Actor Identification Approach — how actors were identified',
      hint: 'Describe the method used to discover actors',
    ),
    Field(
      'actorPrioritization',
      String,
      'Actor Prioritization — which actors are most important',
      hint: 'State which actors matter most and why',
    ),
    Field(
      'actorGoalAlignment',
      String,
      'Actor Goal Alignment — how actor goals align with business goals',
      hint: 'Explain how actor goals map to business goals',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 1+× Actor.
  @StandardReferences(
    [
      'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
      'Cockburn — Writing Effective Use Cases: actor goals & levels (primary/secondary/offstage)',
    ],
    'The set of actor entries defining the roles that interact with the system.',
  )
  @SectionId('ACEN-ACTO-LST')
  @SectionIdPattern('ACEN-ACTO-xxx')
  @Min(1)
  @ContentHelp('Add one entry per actor.')
  @SerializationOrder(2)
  List<ActorEntry> actors = [];

  /// Actor categorization summary.
  @SectionId('ACCASU')
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: actor goals & levels (primary/secondary/offstage)',
      'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
    ],
    'Groups the actors by category — primary, secondary, offstage, system and '
    'timer/scheduled.',
  )
  @Form([
    Field(
      'primaryActors',
      String,
      'Primary Actors — actors who initiate interactions',
      hint: 'List the actors that initiate interactions',
    ),
    Field(
      'secondaryActors',
      String,
      'Secondary Actors — actors who support primary actors',
      hint: 'List the actors that support primary actors',
    ),
    Field(
      'offstageActors',
      String,
      'Offstage Actors — stakeholders with interests but no direct interaction',
      hint: 'List stakeholders with interests but no direct interaction',
    ),
    Field(
      'systemActors',
      String,
      'System Actors — external systems',
      hint: 'List external systems acting as actors',
    ),
    Field(
      'timerActors',
      String,
      'Timer/Scheduled Actors — time-triggered actions',
      hint: 'List time-triggered or scheduled actors',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? categorization;
}

/// An actor entry.
///
/// Comprehensive actor definition following UML and Cockburn conventions.
@StandardReferences(
  [
    'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
    'Cockburn — Writing Effective Use Cases: actor goals & levels '
        '(primary/secondary/offstage)',
    'BABOK v3 — stakeholder & actor analysis',
  ],
  'Defines a single actor comprehensively, bundling identification, '
  'characteristics, goals, permissions, technology and interactions.',
)
@SectionId('ACEN')
@CodeSpecKind(
  [CodeSpecPart.authorization],
  note:
      'an actor is the subject of authorization: its permissions seed the '
      'role matrix',
)
class ActorEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this actor — their working context, motivation and '
    'constraints, beyond the characteristics, goals and permissions '
    'recorded below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Actor identification.
  @SectionId('ACID')
  @StandardReferences(
    [
      'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
      'BABOK v3 — stakeholder & actor analysis',
    ],
    'Uniquely identifies and classifies an actor, capturing type, category and '
    'real-world population.',
  )
  @Form([
    Field(
      'actorType',
      String,
      'Actor Type — human user, system, external system, scheduled',
      hint: 'State whether the actor is a person, system or scheduled job',
    ),
    Field(
      'category',
      String,
      'Category — primary, secondary, supporting, offstage',
      hint: 'Classify using Cockburn primary/secondary/supporting/offstage',
    ),
    Field(
      'description',
      String,
      'Description — role purpose',
      hint: 'Explain the actor’s purpose in one or two sentences',
    ),
    Field(
      'realWorldExamples',
      String,
      'Real World Examples — who fills this role',
      hint: 'Name concrete job titles or people that fill this role',
    ),
    Field(
      'organizationalUnit',
      String,
      'Organizational Unit — department or team',
      hint: 'Identify the department or team the actor belongs to',
    ),
    Field(
      'estimatedCount',
      String,
      'Estimated Count — how many users in this role',
      hint: 'Estimate the number of individuals in this role',
    ),
    Field(
      'geographicDistribution',
      String,
      'Geographic Distribution — where actors are located',
      hint: 'Note the locations or regions where actors operate',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identification;

  /// Actor characteristics.
  @SerializationOrder(2)
  ActorCharacteristics characteristics = ActorCharacteristics();

  /// Actor goals (Cockburn style).
  @StandardReferences([
    'Cockburn — Writing Effective Use Cases: actor goals & levels '
        '(primary/secondary/offstage)',
  ], 'The set of goals an actor seeks to achieve through the system.')
  @SectionId('ACGO-GOAL-LST')
  @SectionIdPattern('ACGO-GOAL-xxx')
  @ContentHelp('Add one entry per actor goal.')
  @SerializationOrder(3)
  List<ActorGoals> goals = [];

  /// Actor permissions and access.
  @StandardReferences([
    'NIST RBAC — role-based access (actor permissions)',
    'ISO/IEC 27001 A.9 — access control (actor authorization)',
  ], 'The access rights and authorization levels granted to an actor.')
  @SectionId('ACPE-PERM-LST')
  @SectionIdPattern('ACPE-PERM-xxx')
  @ContentHelp('Add one entry per actor permission set.')
  @SerializationOrder(4)
  List<ActorPermissions> permissions = [];

  /// Actor technology profile.
  @SectionId('ACTEPR')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — stakeholders & operational context',
      'BABOK v3 — stakeholder & actor analysis',
    ],
    'Describes the channels, devices, connectivity and authentication through '
    'which an actor accesses the system.',
  )
  @Form([
    Field(
      'primaryAccessChannel',
      String,
      'Primary Access Channel — web, mobile app, desktop, API',
      hint: 'Name the main channel the actor uses to access the system',
    ),
    Field(
      'secondaryAccessChannels',
      String,
      'Secondary Access Channels — alternative channels',
      hint: 'List alternative channels the actor may use',
    ),
    Field(
      'deviceTypes',
      String,
      'Device Types — desktop, laptop, tablet, smartphone',
      hint: 'List the device types the actor uses',
    ),
    Field(
      'operatingSystems',
      String,
      'Operating Systems — Windows, macOS, iOS, Android',
      hint: 'List the operating systems the actor runs',
    ),
    Field(
      'browserRequirements',
      String,
      'Browser Requirements — supported browsers',
      hint: 'Note the browsers that must be supported',
    ),
    Field(
      'networkConnectivity',
      String,
      'Network Connectivity — always online, occasionally offline',
      hint: 'Describe the actor’s typical network connectivity',
    ),
    Field(
      'bandwidthExpectations',
      String,
      'Bandwidth Expectations — high-speed, limited',
      hint: 'State the bandwidth the actor typically has available',
    ),
    Field(
      'integratedTools',
      String,
      'Integrated Tools — other tools actor uses',
      hint: 'List other tools the actor integrates with',
    ),
    Field(
      'authenticationMethod',
      String,
      'Authentication Method — password, SSO, MFA, biometric',
      hint: 'State how the actor authenticates to the system',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? technology;

  /// Actor interactions summary.
  @SectionId('ACINSU')
  @StandardReferences(
    [
      'UML 2.5.1 (ISO/IEC 19505) — use-case actors & relationships',
      'Cockburn — Writing Effective Use Cases: actor goals & levels '
          '(primary/secondary/offstage)',
    ],
    'Summarises the use-case interactions an actor participates in, their '
    'frequency, criticality and handoff points.',
  )
  @Form([
    Field(
      'primaryInteractions',
      String,
      'Primary Interactions — main use cases',
      hint: 'List the main use cases the actor initiates or drives',
    ),
    Field(
      'secondaryInteractions',
      String,
      'Secondary Interactions — supporting use cases',
      hint: 'List supporting use cases the actor takes part in',
    ),
    Field(
      'interactionFrequency',
      String,
      'Interaction Frequency — how often each type',
      hint: 'State how often each interaction type occurs',
    ),
    Field(
      'criticalInteractions',
      String,
      'Critical Interactions — most important',
      hint: 'Highlight the actor’s most important interactions',
    ),
    Field(
      'complexInteractions',
      String,
      'Complex Interactions — most challenging',
      hint: 'Note the actor’s most challenging interactions',
    ),
    Field(
      'collaborativeInteractions',
      String,
      'Collaborative Interactions — involves other actors',
      hint: 'List interactions that involve other actors',
    ),
    Field(
      'handoffPoints',
      String,
      'Handoff Points — where work passes to others',
      hint: 'Identify points where work is handed off to others',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? interactions;
}

/// Actor characteristics.
@StandardReferences(
  [
    'BABOK v3 — stakeholder & actor analysis',
    'ISO/IEC/IEEE 29148 §6 — stakeholders & operational context',
  ],
  'Captures an actor’s knowledge, skills and usage profile that shape how they '
  'engage with the system.',
)
@SectionId('ACTCHA')
@FollowUpKind(
  [FollowUpProcess.trn, FollowUpProcess.org],
  note:
      'domain knowledge, IT proficiency and usage profile drive enablement '
      'and org design, not code',
)
class ActorCharacteristics extends DocSpecsSection {
  @Form([
    Field(
      'domainKnowledge',
      String,
      'Domain Knowledge — expertise level required',
      hint: 'Describe the business/domain expertise the actor needs',
    ),
    Field(
      'technicalSkills',
      String,
      'Technical Skills — IT proficiency',
      hint: 'Rate the actor’s general IT and tooling proficiency',
    ),
    Field(
      'trainingRequired',
      String,
      'Training Required — onboarding needs',
      hint: 'List onboarding or training the actor requires',
    ),
    Field(
      'usageFrequency',
      String,
      'Usage Frequency — daily, weekly, monthly, occasional',
      hint: 'State how often the actor uses the system',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Usage patterns and decision scope.
  @SectionId('ACCHUS')
  @StandardReferences(
    [
      'BABOK v3 — stakeholder & actor analysis',
      'ISO/IEC/IEEE 29148 §6 — stakeholders & operational context',
    ],
    'Describes when and how intensively an actor uses the system and the scope '
    'of decisions they may take.',
  )
  @Form([
    Field(
      'usageDuration',
      String,
      'Usage Duration — typical session length',
      hint: 'Estimate the length of a typical working session',
    ),
    Field(
      'peakUsageTimes',
      String,
      'Peak Usage Times — when most active',
      hint: 'Note the times of day or periods of heaviest use',
    ),
    Field(
      'taskComplexity',
      String,
      'Task Complexity — simple, moderate, expert',
      hint: 'Characterise the complexity of the actor’s tasks',
    ),
    Field(
      'decisionAuthority',
      String,
      'Decision Authority — what decisions can be made',
      hint: 'State the decisions the actor is authorised to make',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? usage;

  /// Communication and accessibility profile.
  @SectionId('ACCHSU')
  @StandardReferences(
    [
      'BABOK v3 — stakeholder & actor analysis',
      'ISO/IEC/IEEE 29148 §6 — stakeholders & operational context',
    ],
    'Records how an actor is supervised and reached, and the language and '
    'accessibility accommodations they require.',
  )
  @Form([
    Field(
      'supervisionLevel',
      String,
      'Supervision Level — how closely monitored',
      hint: 'State how closely the actor’s work is supervised',
    ),
    Field(
      'communicationPreference',
      String,
      'Communication Preference — how to reach this actor',
      hint: 'Note preferred channels for reaching the actor',
    ),
    Field(
      'languageRequirements',
      String,
      'Language Requirements — languages needed',
      hint: 'List the languages the actor needs supported',
    ),
    Field(
      'accessibilityNeeds',
      String,
      'Accessibility Needs — special accommodations',
      hint: 'Describe any accessibility accommodations required',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? support;
}

/// Actor goals (Cockburn-style goal hierarchy).
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: actor goals & levels '
        '(primary/secondary/offstage)',
    'BABOK v3 — stakeholder & actor analysis',
  ],
  'Enumerates the summary, user and subfunction goals an actor pursues, plus '
  'their success measures and motivations.',
)
@SectionId('ACGO')
@FollowUpKind(
  [FollowUpProcess.org],
  note:
      'summary, user and subfunction goals with their success measures drive '
      'process design',
)
class ActorGoals extends DocSpecsSection {
  @Form([
    Field(
      'summaryGoals',
      String,
      'Summary Goals — high-level organizational goals',
      hint: 'Capture high-level organisational goals at summary level',
    ),
    Field(
      'userGoals',
      String,
      'User Goals — main goals actor wants to achieve',
      hint: 'List the actor’s main user-level goals',
    ),
    Field(
      'subfunctionGoals',
      String,
      'Subfunction Goals — supporting goals',
      hint: 'Note supporting subfunction-level goals',
    ),
    Field(
      'successMeasures',
      String,
      'Success Measures — how actor knows goals are met',
      hint: 'Define how the actor knows a goal is achieved',
    ),
    Field(
      'failureConcerns',
      String,
      'Failure Concerns — what actor wants to avoid',
      hint: 'List outcomes the actor wants to avoid',
    ),
    Field(
      'motivations',
      String,
      'Motivations — why actor uses the system',
      hint: 'Explain what motivates the actor to use the system',
    ),
    Field(
      'painPoints',
      String,
      'Pain Points — current frustrations',
      hint: 'Describe the actor’s current frustrations',
    ),
    Field(
      'desiredImprovements',
      String,
      'Desired Improvements — what actor wants better',
      hint: 'State improvements the actor would like to see',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Actor permissions and access levels.
@StandardReferences(
  [
    'NIST RBAC — role-based access (actor permissions)',
    'ISO/IEC 27001 A.9 — access control (actor authorization)',
  ],
  'Specifies an actor’s clearance, RBAC roles, data scope and approval limits '
  'along with audit requirements.',
)
@SectionId('ACPE')
@CodeSpecKind(
  [CodeSpecPart.authorization],
  note:
      'CE-AZ — actor RBAC roles, clearance and approval limits realised as authorization rules',
)
class ActorPermissions extends DocSpecsSection {
  @Form([
    Field(
      'securityClearance',
      String,
      'Security Clearance — data access level',
      hint: 'State the actor’s security clearance or data access level',
    ),
    Field(
      'roleBasedPermissions',
      String,
      'Role-Based Permissions — RBAC roles',
      hint: 'List the RBAC roles assigned to the actor',
    ),
    Field(
      'dataAccessScope',
      String,
      'Data Access Scope — own, team, department, all',
      hint: 'Define the breadth of data the actor may access',
    ),
    Field(
      'functionalPermissions',
      String,
      'Functional Permissions — what functions can access',
      hint: 'List the functions or operations the actor may perform',
    ),
    Field(
      'approvalLimits',
      String,
      'Approval Limits — transaction/decision limits',
      hint: 'State the transaction or decision limits the actor may approve',
    ),
    Field(
      'delegationRights',
      String,
      'Delegation Rights — can delegate to others',
      hint: 'Note whether the actor can delegate rights to others',
    ),
    Field(
      'temporaryElevation',
      String,
      'Temporary Elevation — can request higher access',
      hint: 'Describe any temporary privilege-elevation the actor may request',
    ),
    Field(
      'auditRequirements',
      String,
      'Audit Requirements — what actions are logged',
      hint: 'List the actor actions that must be logged for audit',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.2 Interaction Catalog
// ---------------------------------------------------------------------------

/// 6.2.2. Interaction Catalog.
///
/// Container for key interaction descriptions. Each interaction seeds a use
/// case following Cockburn's fully dressed use case template.
@StandardReferences(
  [
    'UML 2.5.1 (ISO/IEC 19505) — use cases',
    'Cockburn — Writing Effective Use Cases: fully dressed use-case template',
    'BABOK v3 — use cases & scenarios',
  ],
  'Catalogs the key actor-system interactions of the system, each seeding a '
  'fully dressed use case.',
)
@SectionId('INCA')
@DetailedIn(D05InteractionScenarios)
@CodeSpecKind(
  [CodeSpecPart.action],
  note:
      'each catalogued interaction seeds a client action',
)
class InteractionCatalog extends DocSpecsSection {
  @ContentHelp('''
Container for key interaction descriptions. Each interaction seeds a use case
following Cockburn's fully dressed use case template.

**For Each Interaction Document:**
- Identification (use case name, goal level, design scope)
- Scope & context (system boundary, assumptions, dependencies)
- Stakeholders & interests (who cares and why)
- Preconditions & triggers (what must be true, what starts it)
- Postconditions & guarantees (minimal + success guarantees)
- Main success scenario (numbered steps with actor/system actions)
- Extensions (alternative and exception flows with branch points)
- UI requirements preview (screens, forms, feedback)
- Performance & security (response time, auth, audit)
- Business rules & traceability (BR-xxx, REQ-xxx references)

**Prioritize Using MoSCoW:**
- Must Have — essential for MVP
- Should Have — important but deferrable
- Could Have — nice to have
- Won't Have — explicitly out of scope
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Interaction catalog overview.
  @SectionId('INCAOV')
  @StandardReferences(
    [
      'UML 2.5.1 (ISO/IEC 19505) — use cases',
      'BABOK v3 — use cases & scenarios',
    ],
    'Summarizes the interaction catalog — counts, coverage, identification method '
    'and traceability across all documented use cases.',
  )
  @Form([
    Field(
      'totalInteractionCount',
      int,
      'Total Interaction Count',
      hint: 'Count of all documented interactions',
    ),
    Field(
      'highPriorityCount',
      int,
      'High Priority Count',
      hint: 'Number of must-have interactions',
    ),
    Field(
      'mediumPriorityCount',
      int,
      'Medium Priority Count',
      hint: 'Number of should-have interactions',
    ),
    Field(
      'lowPriorityCount',
      int,
      'Low Priority Count',
      hint: 'Number of could-have interactions',
    ),
    Field(
      'coverageStatement',
      String,
      'Coverage Statement — what interactions are covered',
      hint: 'State which processes and goals the catalog covers',
    ),
    Field(
      'identificationMethod',
      String,
      'Identification Method — how interactions were identified',
      hint: 'e.g. actor-goal analysis, event storming, process decomposition',
    ),
    Field(
      'prioritizationCriteria',
      String,
      'Prioritization Criteria — how priority was determined',
      hint: 'e.g. MoSCoW, business value vs. effort',
    ),
    Field(
      'traceabilityToProcesses',
      String,
      'Traceability to Processes — link to BP section',
      hint: 'Reference the TOM-xxx process each interaction realizes',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 1+× Interaction.
  @StandardReferences([
    'UML 2.5.1 (ISO/IEC 19505) — use cases',
  ], 'The set of actor-system interactions (use cases) the system supports.')
  @SectionId('INEN-INTE-LST')
  @SectionIdPattern('INEN-INTE-xxx')
  @Min(1)
  @ContentHelp('Add one entry per interaction.')
  @SerializationOrder(2)
  List<InteractionEntry> interactions = [];

  /// Interaction prioritization matrix.
  @SectionId('INPR')
  @StandardReferences(
    [
      'BABOK v3 — use cases & scenarios',
      'Cockburn — Writing Effective Use Cases: use-case identity & scope',
    ],
    'Prioritizes the catalog of interactions using MoSCoW and phasing to guide '
    'delivery sequencing.',
  )
  @Form([
    Field(
      'mustHaveInteractions',
      String,
      'Must-Have Interactions — essential for MVP',
      hint: 'List interactions the MVP cannot ship without',
    ),
    Field(
      'shouldHaveInteractions',
      String,
      'Should-Have Interactions — important but deferrable',
      hint: 'Important but can slip to a later release',
    ),
    Field(
      'couldHaveInteractions',
      String,
      'Could-Have Interactions — nice to have',
      hint: 'Desirable if capacity allows',
    ),
    Field(
      'wontHaveInteractions',
      String,
      'Wont-Have Interactions — out of scope',
      hint: 'Explicitly out of scope for this effort',
    ),
    Field(
      'phaseOneInteractions',
      String,
      'Phase One Interactions',
      hint: 'Interactions targeted for the first delivery phase',
    ),
    Field(
      'phaseTwoInteractions',
      String,
      'Phase Two Interactions',
      hint: 'Interactions targeted for the second delivery phase',
    ),
    Field(
      'futureInteractions',
      String,
      'Future Interactions',
      hint: 'Interactions deferred to an unscheduled future phase',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? prioritization;
}

/// An interaction entry.
///
/// Comprehensive interaction definition following Cockburn's fully dressed
/// use case template. Seeds the ISC (Interaction Scenarios) document.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: fully dressed use-case template',
    'UML 2.5.1 (ISO/IEC 19505) — use cases',
    'ISO/IEC/IEEE 29148 §6 — operational scenarios & interface requirements',
  ],
  'Fully describes a single actor-system interaction as a fully dressed use '
  'case — identity, scope, stakeholders, pre/postconditions, flows and rules.',
)
@SectionId('INEN')
@CodeSpecKind([
  CodeSpecPart.action,
], note: 'CE-AC — a use case / interaction is a user-triggered action')
class InteractionEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this interaction — the situation it arises in and why it '
    'matters, beyond the scope, flow and rule facets recorded below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Interaction identification (use case header).
  @SectionId('INID')
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: use-case identity & scope',
      'UML 2.5.1 (ISO/IEC 19505) — use cases',
    ],
    'Identifies a use case by id, name, actors, goal level and design scope — its '
    'header attributes.',
  )
  @Form([
    Field(
      'useCaseName',
      String,
      'Use Case Name — active verb goal phrase',
      required: true,
      hint: 'Active-verb goal, e.g. "Place order"',
    ),
    Field(
      'processReference',
      String,
      'Process Reference — TOM-xxx',
      hint: 'The TOM-xxx process this use case realizes',
    ),
    Field(
      'briefDescription',
      String,
      'Brief Description — one sentence',
      hint: 'One-sentence summary of the goal',
    ),
    Field(
      'fullDescription',
      String,
      'Full Description — complete explanation',
      hint: 'Fuller narrative of what the interaction achieves',
    ),
    Field(
      'primaryActor',
      String,
      'Primary Actor — who initiates',
      hint: 'The actor with the goal who starts the interaction',
    ),
    Field(
      'supportingActors',
      String,
      'Supporting Actors — who else participates',
      hint: 'Other actors or systems that contribute',
    ),
    Field(
      'goalLevel',
      String,
      'Goal Level — summary (+), user goal (!), subfunction (-)',
      hint: 'Cockburn level: + summary, ! user goal, - subfunction',
    ),
    Field(
      'designScope',
      String,
      'Design Scope — organization, system, subsystem, component',
      hint: 'Boundary in view: organization, system, subsystem, component',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identification;

  /// Use case scope and context (Cockburn style).
  @SectionId('UCSC')
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: scope, level and context',
      'UML 2.5.1 (ISO/IEC 19505) — use cases',
    ],
    'Sets the boundary, level and surrounding context — assumptions, dependencies '
    'and related use cases — for this interaction.',
  )
  @Form([
    Field(
      'systemUnderDiscussion',
      String,
      'System Under Discussion — SuD name',
      hint: 'Name the system whose behavior is being described',
    ),
    Field(
      'systemBoundary',
      String,
      'System Boundary — what is inside/outside',
      hint: 'State what falls inside vs. outside the system',
    ),
    Field(
      'level',
      String,
      'Level — sea level/user goal, fish/subfunction',
      hint: 'Cockburn altitude: sea (user goal), fish (subfunction)',
    ),
    Field(
      'context',
      String,
      'Context — business context',
      hint: 'Business situation in which this use case occurs',
    ),
    Field(
      'assumption',
      String,
      'Assumptions — what is assumed true',
      hint: 'Facts assumed true but not verified in the flow',
    ),
    Field(
      'dependency',
      String,
      'Dependencies — what this depends on',
      hint: 'External systems or use cases this relies on',
    ),
    Field(
      'constraint',
      String,
      'Constraints — limitations',
      hint: 'Limitations bounding how the use case may work',
    ),
    Field(
      'relatedUseCases',
      String,
      'Related Use Cases — includes, extends',
      hint: 'Use cases this one includes or extends',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? scopeContext;

  /// Stakeholders and interests.
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: stakeholders and interests',
      'BABOK v3 — use cases & scenarios',
    ],
    'The stakeholders of this interaction and the interests each of them wants '
    'protected.',
  )
  @SectionId('STANIN-STAK-LST')
  @SectionIdPattern('STANIN-STAK-xxx')
  @ContentHelp('Add one entry per stakeholder interest.')
  @SerializationOrder(3)
  List<StakeholdersAndInterests> stakeholders = [];

  /// Preconditions and triggers.
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: preconditions and triggers',
      'UML 2.5.1 (ISO/IEC 19505) — use cases',
    ],
    'The conditions that must hold before this interaction and the events that '
    'trigger it.',
  )
  @SectionId('PRANTR-PREC-LST')
  @SectionIdPattern('PRANTR-PREC-xxx')
  @ContentHelp('Add one entry per precondition/trigger set.')
  @SerializationOrder(4)
  List<PreconditionsAndTriggers> preconditions = [];

  /// Postconditions and guarantees.
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: minimal and success guarantees',
      'UML 2.5.1 (ISO/IEC 19505) — use cases',
    ],
    'The minimal and success guarantees describing the system state after this '
    'interaction completes.',
  )
  @SectionId('POANGU-POST-LST')
  @SectionIdPattern('POANGU-POST-xxx')
  @ContentHelp('Add one entry per postcondition/guarantee set.')
  @SerializationOrder(5)
  List<PostconditionsAndGuarantees> postconditions = [];

  /// Main success scenario (basic flow).
  @SerializationOrder(6)
  MainSuccessScenario mainScenario = MainSuccessScenario();

  /// Extensions (alternative and exception flows).
  @SerializationOrder(7)
  UseCaseExtensions extensions = UseCaseExtensions();

  /// Technology and data variations.
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: technology & data variations',
      'ISO/IEC/IEEE 29148 §6 — operational scenarios & interface requirements',
    ],
    'The data, technology and channel variations under which this interaction '
    'may play out.',
  )
  @SectionId('TEDAVA-VARI-LST')
  @SectionIdPattern('TEDAVA-VARI-xxx')
  @ContentHelp('Add one entry per variation.')
  @SerializationOrder(8)
  List<TechnologyDataVariations> variations = [];

  /// UI requirements preview.
  @SerializationOrder(9)
  UIRequirementsPreview uiPreview = UIRequirementsPreview();

  /// Performance and frequency.
  @SectionId('INPE')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency',
      'ISO/IEC/IEEE 29148 §6 — operational scenarios & interface requirements',
    ],
    'States the performance targets for the interaction — frequency, volume, '
    'response time, throughput and availability.',
  )
  @Form([
    Field(
      'expectedFrequency',
      String,
      'Expected Frequency — times per day/week',
      hint: 'How often the interaction runs, e.g. per day',
    ),
    Field(
      'peakVolume',
      String,
      'Peak Volume — maximum concurrent',
      hint: 'Maximum concurrent load expected',
    ),
    Field(
      'responseTimeTarget',
      String,
      'Response Time Target — max acceptable',
      hint: 'Maximum acceptable response time',
    ),
    Field(
      'throughputTarget',
      String,
      'Throughput Target — transactions per second',
      hint: 'Required transactions per second',
    ),
    Field(
      'availabilityRequirement',
      String,
      'Availability Requirement — uptime needed',
      hint: 'Required uptime, e.g. 99.9%',
    ),
    Field(
      'concurrencyExpectation',
      String,
      'Concurrency Expectation — simultaneous users',
      hint: 'Expected number of simultaneous users',
    ),
    Field(
      'dataVolumeHandled',
      String,
      'Data Volume Handled — typical data size',
      hint: 'Typical data size processed per run',
    ),
  ])
  @SerializationOrder(10)
  DocSpecsSection? performance;

  /// Security and authorization.
  @SectionId('INSE')
  @StandardReferences(
    [
      'ISO/IEC 27001 A.9 — access control',
      'ISO/IEC/IEEE 29148 §6 — operational scenarios & interface requirements',
    ],
    'States the security requirements for the interaction — authentication, '
    'authorization, data protection, auditing and compliance.',
  )
  @Form([
    Field(
      'authenticationRequired',
      String,
      'Authentication Required — auth needed',
      hint: 'Whether and how the actor must authenticate',
    ),
    Field(
      'authorizationRules',
      String,
      'Authorization Rules — who can do this',
      hint: 'Which roles are permitted to perform this',
    ),
    Field(
      'dataClassification',
      String,
      'Data Classification — sensitivity level',
      hint: 'Sensitivity level of the data handled',
    ),
    Field(
      'encryptionRequirements',
      String,
      'Encryption Requirements — data protection',
      hint: 'Encryption needed in transit and at rest',
    ),
    Field(
      'auditLogging',
      String,
      'Audit Logging — what is logged',
      hint: 'Security-relevant events to log',
    ),
    Field(
      'sessionRequirements',
      String,
      'Session Requirements — timeout, renewal',
      hint: 'Session timeout and renewal rules',
    ),
    Field(
      'complianceRequirements',
      String,
      'Compliance Requirements — GDPR, HIPAA',
      hint: 'Regulations to satisfy, e.g. GDPR, HIPAA',
    ),
  ])
  @SerializationOrder(11)
  DocSpecsSection? security;

  /// Business rules triggered.
  @StandardReferences([
    'BABOK v3 — business rules',
    'Cockburn — Writing Effective Use Cases: main success scenario',
  ], 'The business rules invoked while executing this interaction.')
  @SectionId('INBURU-BUSI-LST')
  @SectionIdPattern('INBURU-BUSI-xxx')
  @ContentHelp('Add one entry per business-rule group.')
  @SerializationOrder(12)
  List<InteractionBusinessRules> businessRules = [];

  /// Related elements and traceability.
  @SectionId('INTR')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — operational scenarios & interface requirements',
      'BABOK v3 — use cases & scenarios',
    ],
    'Traces the interaction to related processes, requirements, data, business '
    'objects, rules, integrations and test cases.',
  )
  @Form([
    Field(
      'relatedProcess',
      String,
      'Related Process — TOM-xxx',
      hint: 'TOM-xxx process this interaction realizes',
    ),
    Field(
      'relatedRequirements',
      String,
      'Related Requirements',
      hint: 'Requirement ids satisfied here, comma-separated — each is a '
          'requirement section id (FRE-REQU-… / TERQ-REQU-… / SECRQ-REQU-… / '
          'ORRQ-REQU-…)',
      refersTo: [
        'FRE.@sectionId',
        'TERQ.@sectionId',
        'SECRQ.@sectionId',
        'ORRQ.@sectionId',
      ],
    ),
    Field(
      'relatedUseCase',
      String,
      'Related Use Case — ISC-xxx in ISC document',
      hint: 'ISC-xxx use case in the ISC document',
    ),
    Field(
      'relatedDataEntities',
      String,
      'Related Data Entities — entity names',
      hint: 'Data entities read or written',
    ),
    Field(
      'relatedBusinessObjects',
      String,
      'Related Business Objects — BO-xxx',
      hint: 'BO-xxx business objects involved',
    ),
    Field(
      'relatedBusinessRules',
      String,
      'Related Business Rules — BR-xxx',
      hint: 'BR-xxx business rules referenced',
    ),
    Field(
      'relatedIntegrations',
      String,
      'Related Integrations — INT-xxx',
      hint: 'INT-xxx integrations touched',
    ),
    Field(
      'relatedTestCases',
      String,
      'Related Test Cases — TC-xxx',
      hint: 'TC-xxx test cases covering this',
    ),
  ])
  @SerializationOrder(13)
  DocSpecsSection? traceability;
}

/// Stakeholders and interests.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: stakeholders and interests',
    'BABOK v3 — use cases & scenarios',
  ],
  'Records each stakeholder of the interaction and the interest they want the '
  'system to protect.',
)
@SectionId('STANIN')
@FollowUpKind(
  [FollowUpProcess.org],
  note:
      'stakeholder interests drive governance, not code',
)
class StakeholdersAndInterests extends DocSpecsSection {
  @Form([
    Field(
      'primaryActorInterest',
      String,
      'Primary Actor Interest — what they want',
      hint: 'The goal the initiating actor is pursuing',
    ),
    Field(
      'systemOwnerInterest',
      String,
      'System Owner Interest — business value',
      hint: 'The business value the owner expects',
    ),
    Field(
      'regulatorInterest',
      String,
      'Regulator Interest — compliance needs',
      hint: 'Compliance or legal interests to satisfy',
    ),
    Field(
      'operationsInterest',
      String,
      'Operations Interest — operational needs',
      hint: 'Operational concerns such as monitoring or SLAs',
    ),
    Field(
      'supportStaffInterest',
      String,
      'Support Staff Interest — support needs',
      hint: 'What support staff need to diagnose and assist',
    ),
    Field(
      'otherStakeholders',
      String,
      'Other Stakeholders — additional interested parties',
      hint: 'Any further parties and their interests',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Preconditions and triggers.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: preconditions and triggers',
    'BPMN 2.0 — collaboration / message flow (actor-system interaction)',
  ],
  'Defines what must be true before the interaction and the event that sets it '
  'in motion.',
)
@SectionId('PRANTR')
@CodeSpecKind(
  [CodeSpecPart.action, CodeSpecPart.validation],
  note:
      'CE-AC/CE-VA — interaction trigger drives the action; pre-start checks are validation rules',
)
class PreconditionsAndTriggers extends DocSpecsSection {
  @Form([
    Field(
      'precondition',
      String,
      'Preconditions — must be true before',
      hint: 'State assumed true before the interaction starts',
    ),
    Field(
      'trigger',
      String,
      'Trigger — what initiates this use case',
      hint: 'The event that starts the interaction',
    ),
    Field(
      'triggerType',
      String,
      'Trigger Type — user action, system event, timer, message',
      hint: 'Classify the trigger: user, system, timer, message',
    ),
    Field(
      'triggerSource',
      String,
      'Trigger Source — where trigger originates',
      hint: 'Actor or system emitting the trigger',
    ),
    Field(
      'triggerData',
      String,
      'Trigger Data — data available at trigger',
      hint: 'Payload carried by the trigger',
    ),
    Field(
      'frequencyOfTrigger',
      String,
      'Frequency of Trigger — how often triggered',
      hint: 'Expected trigger rate, e.g. per day/hour',
    ),
    Field(
      'validationBeforeStart',
      String,
      'Validation Before Start — checks before proceeding',
      hint: 'Guard checks performed before the main flow',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Postconditions and guarantees.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: minimal and success guarantees',
    'UML 2.5.1 (ISO/IEC 19505) — use cases',
  ],
  'Specifies the guarantees — minimal and on success — and the resulting actor, '
  'system and data state after the interaction.',
)
@SectionId('POANGU')
@CodeSpecKind(
  [CodeSpecPart.action],
  note:
      'success and minimal guarantees constrain what an action must leave '
      'true',
)
class PostconditionsAndGuarantees extends DocSpecsSection {
  @Form([
    Field(
      'minimalGuarantees',
      String,
      'Minimal Guarantees — always true after, even on failure',
      hint: 'What the system promises even when the flow fails',
    ),
    Field(
      'successGuarantees',
      String,
      'Success Guarantees — true after successful completion',
      hint: 'What holds true only after successful completion',
    ),
    Field(
      'primaryActorPostcondition',
      String,
      'Primary Actor Postcondition — actor state after',
      hint: 'The primary actor\'s state once the flow ends',
    ),
    Field(
      'systemPostcondition',
      String,
      'System Postcondition — system state after',
      hint: 'The system\'s state once the flow ends',
    ),
    Field(
      'dataPostcondition',
      String,
      'Data Postcondition — data changes',
      hint: 'Persistent data created, updated or removed',
    ),
    Field(
      'notificationsGenerated',
      String,
      'Notifications Generated — who is notified',
      hint: 'Notifications sent and their recipients',
    ),
    Field(
      'auditTrail',
      String,
      'Audit Trail — what is logged',
      hint: 'Audit records written for this interaction',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Main success scenario (basic flow).
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: main success scenario',
    'UML 2.5.1 (ISO/IEC 19505) — use cases',
  ],
  'Describes the happy-path flow — the numbered steps by which the interaction '
  'reaches its goal without deviation.',
)
@SectionId('MASUSC')
@CodeSpecKind(
  [CodeSpecPart.action, CodeSpecPart.serverCall, CodeSpecPart.navigation],
  note:
      'the happy path: user actions, the server calls they make and the '
      'navigation between screens',
)
class MainSuccessScenario extends DocSpecsSection {
  @Form([
    Field(
      'scenarioSummary',
      String,
      'Scenario Summary — overview',
      hint: 'One-paragraph overview of the happy path',
    ),
    Field(
      'estimatedDuration',
      String,
      'Estimated Duration — typical completion time',
      hint: 'Typical time to complete the whole flow',
    ),
    Field(
      'stepCount',
      int,
      'Step Count — number of steps',
      hint: 'How many numbered steps the flow has',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Main scenario steps — contains 1+× Scenario Step.
  @StandardReferences([
    'Cockburn — Writing Effective Use Cases: main success scenario',
  ], 'The ordered steps of the main success scenario.')
  @SectionId('MNSST-STEP-LST')
  @SectionIdPattern('MNSST-STEP-xxx')
  @Min(1)
  @ContentHelp('Add one entry per numbered step.')
  @SerializationOrder(1)
  List<MainScenarioStepEntry> steps = [];
}

/// A main scenario step entry.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: main success scenario',
    'BPMN 2.0 — collaboration / message flow (actor-system interaction)',
  ],
  'One numbered step of the main scenario — the actor action and the system '
  'response, with the data, rules and UI involved.',
)
@SectionId('MNSST')
@CodeSpecKind(
  [CodeSpecPart.action, CodeSpecPart.serverCall, CodeSpecPart.navigation],
  note:
      'CE-AC/CE-SC/CE-NV — each main-flow step: actor action, server-bound call, and/or screen transition',
)
class MainScenarioStepEntry extends DocSpecsSection {
  @Form([
    Field(
      'stepNumber',
      int,
      'Step Number',
      required: true,
      hint: 'Sequential step number within the flow. This is the number the '
          'step is read by, not the handle it is referred to by: a branch '
          'names the step it attaches to by section id.',
    ),
    Field(
      'actorAction',
      String,
      'Actor Action — what actor does',
      hint: 'What the actor does in this step',
    ),
    Field(
      'systemResponse',
      String,
      'System Response — what system does',
      hint: 'How the system responds to the action',
    ),
    Field(
      'serverOperation',
      String,
      'Server Operation',
      hint: 'ServerOperationEntry.operationName (SVOPR registry) this step '
          'calls. State it only where the step reaches the server: the client '
          'call is generated exactly where this is present, so a step that '
          'names nothing generates no call.',
      refersTo: ['SVOPE.operationName'],
    ),
    Field(
      'dataInvolved',
      String,
      'Data Involved — data read/written',
      hint: 'Data read or written during the step',
    ),
    Field(
      'businessRuleApplied',
      String,
      'Business Rule Applied — BR-xxx reference',
      hint: 'BR-xxx rule enforced at this step',
    ),
    Field(
      'uiElementUsed',
      String,
      'UI Element Used — screen/component',
      hint: 'Screen or component the actor interacts with',
    ),
    Field(
      'validationPerformed',
      String,
      'Validation Performed — checks done',
      hint: 'Validations run during this step',
    ),
    Field(
      'expectedDuration',
      String,
      'Expected Duration — time for this step',
      hint: 'Expected time to complete this step',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  @SectionId('SVCST-STEP-LST')
  @SectionIdPattern('SVCST-STEP-xxx')
  @ContentHelp('Fill this in only where the step reaches the server. Add one '
      'entry per thing that has to happen to assemble the request, to apply '
      'the response, or to surface an error — in the order it happens, each '
      'entry saying which of the three it belongs to.')
  @SerializationOrder(1)
  List<ServerCallStepEntry> serverCallSteps = [];
}

/// One step of a server call's handling, in one of its three roles.
///
/// A step that reaches the server states the call in one sentence — *submits
/// the order to the ordering service* — but the code that performs it is three
/// separate bodies (`codespecs_derivation_contract.md` §3.5.7): the request is
/// assembled before the wire, a successful response is applied after it, and a
/// failure is surfaced instead. This entry is where each of those is stated,
/// and [role] is the field that says which. Without it a generator would have
/// to split one sentence three ways by guessing, which
/// `codespecs_derivation_contract.md` §2.4 B8 forbids — so the three bodies
/// could only throw the same text.
///
/// The steps hang off the interaction step that issues the call (`MNSST`,
/// `SCNST`, `ALST`, `EXTST`), because the call has no identity of its own: it
/// *is* that step's reach across the boundary. Leaving the list empty leaves
/// the call's bodies as they were — an unstated role falls back to form 3a over
/// the issuing step's own behaviour text (`codespecs_derivation_contract.md`
/// §2.4).
///
/// **No step number.** The list position *is* the order
/// (`codespecs_derivation_contract.md` §2.4 B1 reads document order and never a
/// step's own order field), and each role's steps are read in document order
/// within the list.
///
/// **[condition] is a precondition, not a case label.** It becomes a guard on
/// the step's statement (`codespecs_derivation_contract.md` §2.4 B4). It is not
/// the way an error code is turned into user-visible wording: B7 forbids the
/// `switch` that would need, and the message a code maps to belongs in the
/// CE-TX message-key registry (`codespecs_mapping.md` §5.3), not in a chain of
/// conditions here.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: main success scenario',
    'RFC 9110 — HTTP semantics: request, successful response, error response',
  ],
  'One step of a server call\'s handling — which of the three handling roles it '
  'belongs to, what happens in it, and the condition it happens under.',
)
@SectionId('SVCST')
@CodeSpecKind(
  [CodeSpecPart.serverCall],
  note:
      'CE-SC — one step of one of the call\'s three method bodies. The role '
      'field routes it to assembleRequest, handleResponse or handleError, '
      'which is what makes those bodies form 3b '
      '(codespecs_derivation_contract.md §2.4): within a role, each step '
      'contributes one collaborator method and one statement in list order, '
      'and a stated condition becomes a guard method (B4). It routes to the '
      'same part as the interaction step that owns it — a step is not a '
      'declaration of its own, it is part of one call.',
)
class ServerCallStepEntry extends DocSpecsSection {
  @ContentHelp('Say which of the three handling roles this step belongs to, '
      'then what happens in it, as one action. Give the step a headline that '
      'names that action — it is what the generated method is named after. '
      'Fill in Condition only where the step is conditional; a step with no '
      'condition always runs.')
  @Form([
    Field(
      'role',
      ServerCallRole,
      'Role',
      required: true,
      hint: 'Which of the call\'s three handling roles this step belongs to: '
          'assembleRequest (before the call), handleResponse (after a '
          'successful one) or handleError (after a failed one).',
    ),
    Field(
      'systemAction',
      String,
      'System Action',
      required: true,
      hint: 'What happens in this step — one action, stated as what happens '
          'rather than how it is coded. Nothing outside the system acts here: '
          'assembling, applying and surfacing are system work throughout.',
    ),
    Field(
      'condition',
      String,
      'Condition',
      hint: 'The condition under which this step runs, if it is not '
          'unconditional (e.g. only when the customer has a stored address). '
          'Leave empty for a step that always runs.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Use case extensions (alternative and exception flows).
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: extensions',
    'UML 2.5.1 (ISO/IEC 19505) — use cases',
  ],
  'Collects the alternative and exception flows that branch from the main '
  'success scenario.',
)
@SectionId('USCAEX')
@CodeSpecKind(
  [CodeSpecPart.action],
  note:
      'alternate and exception flows seed further actions',
)
class UseCaseExtensions extends DocSpecsSection {
  @Form([
    Field(
      'extensionSummary',
      String,
      'Extension Summary — overview of variations',
      hint: 'Overview of the alternative and exception flows',
    ),
    Field(
      'extensionCount',
      int,
      'Extension Count — number of extensions',
      hint: 'How many extensions are documented',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Extension entries — contains 0+× Extension.
  @StandardReferences([
    'Cockburn — Writing Effective Use Cases: extensions',
  ], 'The alternative and exception flows that branch off the main scenario.')
  @SectionId('EXTEN-EXTE-LST')
  @SectionIdPattern('EXTEN-EXTE-xxx')
  @ContentHelp('Add one entry per extension flow.')
  @SerializationOrder(1)
  List<ExtensionEntry> extensions = [];
}

/// An extension entry.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: extensions',
    'UML 2.5.1 (ISO/IEC 19505) — use cases',
  ],
  'One extension flow — the branch point, condition, type and outcome of an '
  'alternative or exception path.',
)
@SectionId('EXTEN')
@CodeSpecKind(
  [CodeSpecPart.action],
  note:
      'CE-AC — an extension is an alternate/exception action branch of the use '
      'case. branchPoint names the main-scenario step the branch is emitted '
      'before; returnKind and its case subsection say where control goes when '
      'the branch finishes (codespecs_derivation_contract.md B5/B6).',
)
@OneOf(
  discriminator: 'returnKind',
  noCase: [FlowReturnPoint.endFlow],
  note: 'Branch return closed choice: an extension either resumes the main '
      'scenario at a named step — which needs that step, so it binds a case — '
      'or ends the use case, which needs nothing and binds none.',
)
class ExtensionEntry extends DocSpecsSection {
  @Form([
    Field(
      'branchPoint',
      String,
      'Branch Point — main-scenario step',
      required: true,
      refersTo: ['MNSST.@sectionId'],
      hint: 'The main-scenario step this branch leaves from, as that step\'s '
          'section id (MNSST-STEP-…). The branch is taken instead of that '
          'step, so name the step the condition is evaluated before — not the '
          'step before it, and not a restated step number.',
    ),
    Field(
      'condition',
      String,
      'Condition — when this extension triggers',
      hint: 'Condition under which the branch is taken',
    ),
    Field(
      'extensionType',
      String,
      'Extension Type — alternative, exception, error',
      hint: 'Classify: alternative, exception or error',
    ),
    Field(
      'description',
      String,
      'Description — what happens',
      hint: 'What happens along this extension path',
    ),
    Field(
      'outcome',
      String,
      'Outcome — how it ends',
      hint: 'Result reached when the branch completes',
    ),
    Field(
      'returnKind',
      FlowReturnPoint,
      'Return Kind — resume the scenario, or end it',
      required: true,
      hint: 'Where control goes when this branch finishes — back to a named '
          'main-scenario step, or nowhere because the use case ends here',
    ),
    Field(
      'frequency',
      String,
      'Frequency — how often this occurs',
      hint: 'How often this branch is expected to occur',
    ),
    Field(
      'severity',
      String,
      'Severity — impact level (for exceptions)',
      hint: 'Impact level for exception/error branches',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Resume point — a promoted `@OneOf` case.
  ///
  /// Present only for the `resumeAtStep` kind: the main-scenario step control
  /// returns to once the branch has run. The `endFlow` kind promotes nothing,
  /// because a branch that ends the use case has no step to name — which is
  /// the whole reason the two are a closed choice rather than one `String` in
  /// which `"end"` and a step reference were indistinguishable.
  @SectionId('EXTEN-RESU')
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: extensions',
      'UML 2.5.1 (ISO/IEC 19505) — use cases',
    ],
    'The main-scenario step this extension returns control to.',
  )
  @Case(FlowReturnPoint.resumeAtStep)
  @Form([
    Field(
      'resumeStep',
      String,
      'Resume Step',
      required: true,
      refersTo: ['MNSST.@sectionId'],
      hint: 'The main-scenario step control resumes at, as that step\'s '
          'section id (MNSST-STEP-…). That step and everything after it run '
          'again from here.',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? resumePoint;

  /// Extension steps — contains 0+× Scenario Step.
  @StandardReferences([
    'Cockburn — Writing Effective Use Cases: extensions',
  ], 'The ordered steps that make up this extension flow.')
  @SectionId('EXTST-STEP-LST')
  @SectionIdPattern('EXTST-STEP-xxx')
  @ContentHelp('Add one entry per extension step.')
  @SerializationOrder(2)
  List<ExtensionStepEntry> steps = [];
}

/// An extension step entry.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: extensions',
    'UML 2.5.1 (ISO/IEC 19505) — use cases',
  ],
  'One numbered step within an extension flow — its actor action and system '
  'response.',
)
@SectionId('EXTST')
@CodeSpecKind(
  [CodeSpecPart.action, CodeSpecPart.serverCall, CodeSpecPart.navigation],
  note:
      'CE-AC/CE-SC/CE-NV — each extension step: actor action, server call, and/or screen transition',
)
class ExtensionStepEntry extends DocSpecsSection {
  @Form([
    Field(
      'stepNumber',
      String,
      'Step Number (e.g., 3a1)',
      hint: 'Extension step id such as 3a1',
    ),
    Field(
      'action',
      String,
      'Action',
      hint: 'What the actor does in this extension step',
    ),
    Field(
      'response',
      String,
      'Response',
      hint: 'How the system responds in this step',
    ),
    Field(
      'serverOperation',
      String,
      'Server Operation',
      hint: 'ServerOperationEntry.operationName (SVOPR registry) this step '
          'calls. State it only where the step reaches the server: the client '
          'call is generated exactly where this is present, so a step that '
          'names nothing generates no call.',
      refersTo: ['SVOPE.operationName'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  @SectionId('SVCST-STEP-LST')
  @SectionIdPattern('SVCST-STEP-xxx')
  @ContentHelp('Fill this in only where the step reaches the server. Add one '
      'entry per thing that has to happen to assemble the request, to apply '
      'the response, or to surface an error — in the order it happens, each '
      'entry saying which of the three it belongs to.')
  @SerializationOrder(1)
  List<ServerCallStepEntry> serverCallSteps = [];
}

/// Technology and data variations.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: technology & data variations',
    'ISO/IEC/IEEE 29148 §6 — operational scenarios & interface requirements',
  ],
  'Records the data, technology, channel and accessibility variations under '
  'which the same interaction may run.',
)
@SectionId('TEDAVA')
@CodeSpecKind(
  [CodeSpecPart.action, CodeSpecPart.layout],
  note:
      'data, technology, channel and accessibility variations of a step',
)
class TechnologyDataVariations extends DocSpecsSection {
  @Form([
    Field(
      'dataVariations',
      String,
      'Data Variations — different data formats, sources',
      hint: 'Different data formats or sources handled',
    ),
    Field(
      'technologyVariations',
      String,
      'Technology Variations — different platforms, devices',
      hint: 'Platform or device differences to support',
    ),
    Field(
      'channelVariations',
      String,
      'Channel Variations — web, mobile, API differences',
      hint: 'Behavior differences across web, mobile, API',
    ),
    Field(
      'localizationVariations',
      String,
      'Localization Variations — language, regional',
      hint: 'Language and regional adaptations required',
    ),
    Field(
      'accessibilityVariations',
      String,
      'Accessibility Variations — screen reader, keyboard',
      hint: 'Screen-reader and keyboard-only accommodations',
    ),
    Field(
      'offlineVariations',
      String,
      'Offline Variations — handling offline state',
      hint: 'How the interaction behaves while offline',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// UI requirements preview for this interaction.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — interface requirements',
    'Cockburn — Writing Effective Use Cases: main success scenario',
  ],
  'Previews the UI needs of the interaction — screens, key fields, actions, '
  'feedback and layout — ahead of full UI design.',
)
@SectionId('UIRP')
@CodeSpecKind(
  [CodeSpecPart.navigation],
  note:
      'CE-NV — previews the screen flow / navigation path (full UI parts owned by the ExperienceDesign pass)',
)
class UIRequirementsPreview extends DocSpecsSection {
  @Form([
    Field(
      'primaryScreen',
      String,
      'Primary Screen — main UI screen',
      hint: 'The main screen where the interaction happens',
    ),
    Field(
      'screenFlow',
      String,
      'Screen Flow — navigation path',
      hint: 'Navigation path across screens',
    ),
    Field(
      'keyFormFields',
      String,
      'Key Form Fields — input fields',
      hint: 'Important input fields the user completes',
    ),
    Field(
      'keyActions',
      String,
      'Key Actions — buttons, links',
      hint: 'Primary buttons or links the user activates',
    ),
    Field(
      'keyDisplayElements',
      String,
      'Key Display Elements — data shown',
      hint: 'Important data displayed to the user',
    ),
    Field(
      'feedbackMechanisms',
      String,
      'Feedback Mechanisms — success/error messages',
      hint: 'How success and error are communicated',
    ),
    Field(
      'layoutConsiderations',
      String,
      'Layout Considerations — responsive, orientation',
      hint: 'Responsive and orientation considerations',
    ),
    Field(
      'interactionPatterns',
      String,
      'Interaction Patterns — drag-drop, swipe',
      hint: 'Gesture or interaction patterns used',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// UI mockup/wireframe reference.
  @SerializationOrder(1)
  FlowDiagramSection screenMockup = FlowDiagramSection();
}

/// Business rules triggered by this interaction.
@StandardReferences(
  ['BABOK v3 — business rules', 'ISO 9001:2015 §4.4 — process interactions'],
  'Lists the business rules — validation, calculation, authorization, workflow, '
  'notification and integration — invoked by this interaction.',
)
@SectionId('INBURU')
@CodeSpecKind(
  [CodeSpecPart.validation],
  note:
      'CE-VA — validation/authorization/workflow BR-xxx rules invoked by the interaction; realised as validation rules',
)
class InteractionBusinessRules extends DocSpecsSection {
  @Form([
    Field(
      'validationRules',
      String,
      'Validation Rules — BR-xxx for validation',
      hint: 'BR-xxx rules governing input validation',
    ),
    Field(
      'calculationRules',
      String,
      'Calculation Rules — BR-xxx for calculations',
      hint: 'BR-xxx rules governing calculations',
    ),
    Field(
      'authorizationRules',
      String,
      'Authorization Rules — BR-xxx for permissions',
      hint: 'BR-xxx rules governing permissions',
    ),
    Field(
      'workflowRules',
      String,
      'Workflow Rules — BR-xxx for flow',
      hint: 'BR-xxx rules governing flow and routing',
    ),
    Field(
      'notificationRules',
      String,
      'Notification Rules — BR-xxx for notifications',
      hint: 'BR-xxx rules governing notifications',
    ),
    Field(
      'integrationRules',
      String,
      'Integration Rules — BR-xxx for integrations',
      hint: 'BR-xxx rules governing external integrations',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.3 Key Scenarios
// ---------------------------------------------------------------------------

/// 6.2.3. Key Scenarios.
///
/// End-to-end scenario descriptions showing how users achieve business goals
/// through sequences of interactions.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: main success scenario, extensions, alternative flows',
    'ISO/IEC/IEEE 29148 §6 — operational scenarios',
    'BABOK v3 — use cases & scenarios',
  ],
  'Collects the key end-to-end scenarios that show how users achieve business goals through complete sequences of interactions.',
)
@SectionId('KESC')
@DetailedIn(D05InteractionScenarios)
@CodeSpecKind(
  [CodeSpecPart.action],
  note:
      'scenario steps seed client actions',
)
class KeyScenarios extends DocSpecsSection {
  @ContentHelp('''
End-to-end scenario descriptions showing how users achieve business goals
through sequences of interactions. Scenarios bridge the gap between individual
interactions and complete user journeys.

**Scenario Types:**
- Happy path — normal successful completion
- Alternative flow — valid variations from main path
- Exception/error — handling of failures and edge cases

**For Each Scenario Document:**
- Identification (ID, name, type, priority, complexity)
- Context (preconditions, trigger, success/failure conditions)
- Steps (numbered with actor, action, system response, UI element)
- Alternative flows (branch points, conditions, outcomes)
- Data requirements (input/output, test data, transformations)
- Timing (total duration, user time, system time, wait time)
- Validation (acceptance criteria, test scenario references)

**Example Format:**
"A new customer discovers the service, registers, completes verification,
and places their first order."
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Scenario overview.
  @SectionId('SCOV')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148 §6 — operational scenarios',
      'BABOK v3 — use cases & scenarios',
    ],
    'Summarises the overall set of key scenarios, their coverage, types, and how they map to tests.',
  )
  @Form([
    Field(
      'totalScenarioCount',
      int,
      'Total Scenario Count',
      hint: 'Number of scenarios documented',
    ),
    Field(
      'scenarioCoverage',
      String,
      'Scenario Coverage — what user journeys are covered',
      hint: 'Which end-to-end journeys the scenarios span',
    ),
    Field(
      'scenarioTypes',
      String,
      'Scenario Types — happy path, error handling, edge case',
      hint: 'Mix of happy-path, error, and edge-case scenarios',
    ),
    Field(
      'scenarioPrioritization',
      String,
      'Scenario Prioritization — which are most important',
      hint: 'How scenarios are ranked by importance',
    ),
    Field(
      'scenarioToTestMapping',
      String,
      'Scenario to Test Mapping — how scenarios map to tests',
      hint: 'How each scenario traces to TC-xxx test cases',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 1+× Scenario.
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: main success scenario & extensions',
    ],
    'The set of key end-to-end scenarios that illustrate how actors achieve '
    'their business goals through the system.',
  )
  @SectionId('SCNRY-SCEN-LST')
  @SectionIdPattern('SCNRY-SCEN-xxx')
  @Min(1)
  @ContentHelp('Add one entry per key scenario.')
  @SerializationOrder(2)
  List<ScenarioEntry> scenarios = [];
}

/// A scenario entry.
///
/// Comprehensive scenario definition for end-to-end user journey.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: main success scenario, extensions, alternative flows',
    'ISO/IEC/IEEE 29148 §6 — operational scenarios',
  ],
  'A comprehensive definition of one end-to-end scenario, bundling its identity, context, steps, alternative flows, data, timing, and validation.',
)
@SectionId('SCNRY')
@CodeSpecKind(
  [CodeSpecPart.action],
  note: 'CE-AC — an end-to-end scenario is a goal-directed sequence of actions',
)
class ScenarioEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this scenario — the end-to-end story it tells, beyond '
    'the steps, data and timing recorded below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Scenario identification.
  @SectionId('SCID')
  @StandardReferences([
    'Cockburn — Writing Effective Use Cases: scenarios & scenario identity',
    'ISO/IEC/IEEE 29148 §6 — operational scenarios',
  ], 'Captures the identifying attributes of a single key end-to-end scenario.')
  @Form([
    Field(
      'scenarioType',
      String,
      'Scenario Type — happy path, alternative, exception',
      hint: 'One of happy path, alternative, or exception',
    ),
    Field(
      'description',
      String,
      'Description — narrative summary',
      hint: 'One-paragraph narrative of the journey',
    ),
    Field(
      'businessGoal',
      String,
      'Business Goal — what is achieved',
      hint: 'The outcome the actor is trying to reach',
    ),
    Field(
      'primaryActor',
      String,
      'Primary Actor — who performs scenario',
      hint: 'The main actor driving the scenario',
    ),
    Field(
      'supportingActors',
      String,
      'Supporting Actors — who else',
      hint: 'Other actors or systems that participate',
    ),
    Field(
      'priority',
      String,
      'Priority — critical, high, medium, low',
      hint: 'Business priority of this scenario',
    ),
    Field(
      'complexity',
      String,
      'Complexity — simple, moderate, complex',
      hint: 'Relative implementation/test complexity',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identification;

  /// Scenario context.
  @SectionId('SCCO')
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: preconditions, triggers & guarantees',
      'ISO/IEC/IEEE 29148 §6 — operational scenarios',
    ],
    'Establishes the surrounding conditions of the scenario: preconditions, trigger, success/failure conditions, and scope.',
  )
  @Form([
    Field(
      'preconditions',
      String,
      'Preconditions — required initial state',
      hint: 'State that must hold before the scenario starts',
    ),
    Field(
      'trigger',
      String,
      'Trigger — what starts the scenario',
      hint: 'The event that initiates the scenario',
    ),
    Field(
      'successCondition',
      String,
      'Success Condition — how to know it worked',
      hint: 'Observable state indicating success',
    ),
    Field(
      'failureCondition',
      String,
      'Failure Condition — how to know it failed',
      hint: 'Observable state indicating failure',
    ),
    Field(
      'assumptions',
      String,
      'Assumptions — what is assumed true',
      hint: 'Assumptions taken as given for this scenario',
    ),
    Field(
      'outOfScope',
      String,
      'Out of Scope — what is not included',
      hint: 'What this scenario deliberately excludes',
    ),
    Field(
      'relatedInteractions',
      String,
      'Related Interactions — INT-xxx references',
      hint: 'INT-xxx interactions referenced by this scenario',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? context;

  /// Contains 1+× Scenario Step.
  @StandardReferences(
    [
      'BPMN 2.0 — sequence flow / activities (scenario steps)',
      'Gherkin / BDD — given-when-then scenario steps',
    ],
    'The ordered main-success steps of the scenario, each pairing an actor '
    'action with the system response.',
  )
  @SectionId('SCNST-STEP-LST')
  @SectionIdPattern('SCNST-STEP-xxx')
  @Min(1)
  @ContentHelp('Add one entry per main-flow step, in order.')
  @SerializationOrder(3)
  List<ScenarioStepEntry> steps = [];

  /// Alternative flows — contains 0+× Alternative Flow.
  @StandardReferences(
    ['Cockburn — Writing Effective Use Cases: extensions & alternative flows'],
    'The valid variations and exception branches that diverge from the main '
    'success path of the scenario.',
  )
  @SectionId('ALFL-ALTE-LST')
  @SectionIdPattern('ALFL-ALTE-xxx')
  @ContentHelp('Add one entry per alternative or exception flow.')
  @SerializationOrder(4)
  List<AlternativeFlowEntry> alternativeFlows = [];

  /// Scenario data.
  @SectionId('SCDA')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing (scenario validation)',
      'BABOK v3 — use cases & scenarios',
    ],
    'Specifies the input, output, test, and sample data the scenario consumes, produces, and transforms.',
  )
  @Form([
    Field(
      'inputData',
      String,
      'Input Data — data needed to start',
      hint: 'Data required before the scenario can run',
    ),
    Field(
      'outputData',
      String,
      'Output Data — data produced',
      hint: 'Data the scenario produces on completion',
    ),
    Field(
      'testDataRequirements',
      String,
      'Test Data Requirements — data for testing',
      hint: 'Data needed to exercise this scenario in tests',
    ),
    Field(
      'dataTransformations',
      String,
      'Data Transformations — how data changes',
      hint: 'How data is transformed through the scenario',
    ),
    Field(
      'dataValidations',
      String,
      'Data Validations — checks performed',
      hint: 'Validation checks applied to the data',
    ),
    Field(
      'sampleDataValues',
      String,
      'Sample Data Values — example input/output',
      hint: 'Concrete example values for input/output',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? scenarioData;

  /// Scenario timing.
  @SectionId('SCTI')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency',
      'ISO/IEC/IEEE 29148 §6 — operational scenarios',
    ],
    'Defines the timing expectations of the scenario: total duration, user/system time, wait time, constraints, and timeout handling.',
  )
  @Form([
    Field(
      'totalDuration',
      String,
      'Total Duration — end-to-end time',
      hint: 'Expected end-to-end elapsed time',
    ),
    Field(
      'userActiveTime',
      String,
      'User Active Time — user effort',
      hint: 'Time the user is actively engaged',
    ),
    Field(
      'systemProcessingTime',
      String,
      'System Processing Time — system work',
      hint: 'Time the system spends processing',
    ),
    Field(
      'waitTime',
      String,
      'Wait Time — delays for external factors',
      hint: 'Delays waiting on external factors',
    ),
    Field(
      'timeConstraints',
      String,
      'Time Constraints — deadlines, SLAs',
      hint: 'Deadlines or SLAs the scenario must meet',
    ),
    Field(
      'timeoutHandling',
      String,
      'Timeout Handling — what if too slow',
      hint: 'What happens if timing limits are exceeded',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? timing;

  /// Scenario validation.
  @SectionId('SCVA')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing (scenario validation)',
      'Cockburn — Writing Effective Use Cases: success guarantees',
    ],
    'Defines how the scenario is validated: acceptance criteria, test references, verification method, and expected metrics.',
  )
  @Form([
    Field(
      'acceptanceCriteria',
      String,
      'Acceptance Criteria — how success is verified',
      hint: 'Criteria that confirm the scenario succeeded',
    ),
    Field(
      'testScenarios',
      String,
      'Test Scenarios — TC-xxx references',
      hint: 'TC-xxx test cases covering this scenario',
    ),
    Field(
      'verificationMethod',
      String,
      'Verification Method — manual, automated',
      hint: 'How the scenario is verified: manual or automated',
    ),
    Field(
      'validationData',
      String,
      'Validation Data — data to check',
      hint: 'Data checked to validate the outcome',
    ),
    Field(
      'expectedMetrics',
      String,
      'Expected Metrics — performance targets',
      hint: 'Performance or quality targets to meet',
    ),
    Field(
      'knownIssues',
      String,
      'Known Issues — documented problems',
      hint: 'Documented problems or limitations',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? validation;
}

/// A scenario step entry.
@StandardReferences(
  [
    'BPMN 2.0 — sequence flow / activities (scenario steps)',
    'Gherkin / BDD — given-when-then scenario steps',
  ],
  'A single numbered step of the main flow, pairing an actor action with the resulting system response.',
)
@SectionId('SCNST')
@CodeSpecKind(
  [CodeSpecPart.action, CodeSpecPart.serverCall, CodeSpecPart.navigation],
  note:
      'CE-AC/CE-SC/CE-NV — each scenario step: actor action, server-bound call, and/or screen transition',
)
class ScenarioStepEntry extends DocSpecsSection {
  @Form([
    Field(
      'stepNumber',
      int,
      'Step Number',
      required: true,
      hint: 'Sequential position of this step. This is the number the step is '
          'read by, not the handle it is referred to by: a branch names the '
          'step it attaches to by section id.',
    ),
    Field(
      'actor',
      String,
      'Actor — who performs this step',
      hint: 'The actor performing this step',
    ),
    Field(
      'action',
      String,
      'Action — what actor does',
      hint: 'The action the actor takes',
    ),
    Field(
      'systemResponse',
      String,
      'System Response — what system does',
      hint: 'How the system responds to the action',
    ),
    Field(
      'serverOperation',
      String,
      'Server Operation',
      hint: 'ServerOperationEntry.operationName (SVOPR registry) this step '
          'calls. State it only where the step reaches the server: the client '
          'call is generated exactly where this is present, so a step that '
          'names nothing generates no call.',
      refersTo: ['SVOPE.operationName'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Expected outcome and referenced artifacts.
  @SectionId('SSEC')
  @StandardReferences(
    [
      'Gherkin / BDD — given-when-then scenario steps',
      'BPMN 2.0 — sequence flow / activities (scenario steps)',
    ],
    'Records the expected result of a scenario step and the artifacts, data, and UI elements it references.',
  )
  @Form([
    Field(
      'expectedResult',
      String,
      'Expected Result — observable outcome',
      hint: 'The observable outcome after the step',
    ),
    Field(
      'interactionReference',
      String,
      'Interaction Reference — INT-xxx if detailed',
      hint: 'INT-xxx interaction detailing this step',
    ),
    Field(
      'dataInvolved',
      String,
      'Data Involved — input/output data',
      hint: 'Data read or written during the step',
    ),
    Field(
      'uiElement',
      String,
      'UI Element — screen/component used',
      hint: 'Screen or component the actor uses',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? context;

  /// Timing and notes.
  ///
  /// Where the flow branches is stated by the `ALFL` entry that branches, not
  /// here: `ALFL.branchPoint` names this step and `ALFL.triggerCondition` says
  /// under what condition it is taken. A step states no branch of its own, so
  /// there is one place a reader and the Phase-4 generator both look.
  @SectionId('SCSTENEX')
  @StandardReferences(
    ['BPMN 2.0 — sequence flow / activities (scenario steps)'],
    'Captures the execution details of a scenario step: expected timing and clarifying notes.',
  )
  @Form([
    Field(
      'timing',
      String,
      'Timing — expected duration',
      hint: 'Expected time this step takes',
    ),
    Field(
      'notes',
      String,
      'Notes — clarifications',
      hint: 'Additional clarifications for this step',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;

  @SectionId('SVCST-STEP-LST')
  @SectionIdPattern('SVCST-STEP-xxx')
  @ContentHelp('Fill this in only where the step reaches the server. Add one '
      'entry per thing that has to happen to assemble the request, to apply '
      'the response, or to surface an error — in the order it happens, each '
      'entry saying which of the three it belongs to.')
  @SerializationOrder(3)
  List<ServerCallStepEntry> serverCallSteps = [];
}

/// An alternative flow entry.
@StandardReferences(
  [
    'Cockburn — Writing Effective Use Cases: extensions & alternative flows',
    'ISO/IEC/IEEE 29148 §6 — operational scenarios',
  ],
  'Defines a single alternative, exception, or error flow that branches from the main scenario path.',
)
@SectionId('ALFL')
@CodeSpecKind(
  [CodeSpecPart.action],
  note:
      'CE-AC — an alternative/exception flow is an action branch of the '
      'scenario. branchPoint names the main-flow step the branch is emitted '
      'before; returnKind and its case subsection say where control goes when '
      'the branch finishes (codespecs_derivation_contract.md B5/B6).',
)
@OneOf(
  discriminator: 'returnKind',
  noCase: [FlowReturnPoint.endFlow],
  note: 'Branch return closed choice: an alternative flow either resumes the '
      'main flow at a named step — which needs that step, so it binds a case '
      '— or ends the scenario, which needs nothing and binds none.',
)
class AlternativeFlowEntry extends DocSpecsSection {
  @Form([
    Field(
      'flowType',
      String,
      'Flow Type — alternative, exception, error',
      hint: 'One of alternative, exception, or error',
    ),
    Field(
      'branchPoint',
      String,
      'Branch Point — main-flow step',
      required: true,
      refersTo: ['SCNST.@sectionId'],
      hint: 'The main-flow step this branch diverges at, as that step\'s '
          'section id (SCNST-STEP-…). The branch is taken instead of that '
          'step, so name the step the trigger condition is evaluated before — '
          'not the step before it, and not a restated step number.',
    ),
    Field(
      'triggerCondition',
      String,
      'Trigger Condition — when this occurs',
      hint: 'Condition that activates this flow',
    ),
    Field(
      'description',
      String,
      'Description — what happens',
      hint: 'Narrative of what happens in this flow',
    ),
    Field(
      'outcome',
      String,
      'Outcome — how flow ends',
      hint: 'The end state this flow reaches',
    ),
    Field(
      'returnKind',
      FlowReturnPoint,
      'Return Kind — resume the main flow, or end it',
      required: true,
      hint: 'Where control goes when this flow finishes — back to a named '
          'main-flow step, or nowhere because the scenario ends here',
    ),
    Field(
      'frequency',
      String,
      'Frequency — how often this occurs',
      hint: 'How often this flow is expected to occur',
    ),
    Field(
      'businessImpact',
      String,
      'Business Impact — effect on business',
      hint: 'Business consequence of this flow',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Resume point — a promoted `@OneOf` case.
  ///
  /// Present only for the `resumeAtStep` kind: the main-flow step control
  /// returns to once this flow has run. The `endFlow` kind promotes nothing,
  /// because a flow that ends the scenario has no step to name — which is the
  /// whole reason the two are a closed choice rather than one `String` in
  /// which `"end"` and a step reference were indistinguishable.
  @SectionId('ALFL-RESU')
  @StandardReferences(
    [
      'Cockburn — Writing Effective Use Cases: extensions & alternative flows',
      'BPMN 2.0 — sequence flow / activities (scenario steps)',
    ],
    'The main-flow step this alternative flow returns control to.',
  )
  @Case(FlowReturnPoint.resumeAtStep)
  @Form([
    Field(
      'resumeStep',
      String,
      'Resume Step',
      required: true,
      refersTo: ['SCNST.@sectionId'],
      hint: 'The main-flow step control resumes at, as that step\'s section '
          'id (SCNST-STEP-…). That step and everything after it run again '
          'from here.',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? resumePoint;

  /// Contains 0+× Scenario Step.
  @StandardReferences(
    [
      'BPMN 2.0 — sequence flow / activities (scenario steps)',
      'Gherkin / BDD — given-when-then scenario steps',
    ],
    'The ordered steps that make up this alternative flow, each pairing an '
    'action with its response.',
  )
  @SectionId('ALST-STEP-LST')
  @SectionIdPattern('ALST-STEP-xxx')
  @ContentHelp('Add one entry per step of this alternative flow, in order.')
  @SerializationOrder(2)
  List<AlternativeStepEntry> steps = [];
}

/// An alternative step entry.
@StandardReferences(
  [
    'BPMN 2.0 — sequence flow / activities (scenario steps)',
    'Gherkin / BDD — given-when-then scenario steps',
  ],
  'A single step within an alternative flow, pairing an action with its system response and expected result.',
)
@SectionId('ALST')
@CodeSpecKind(
  [CodeSpecPart.action, CodeSpecPart.serverCall, CodeSpecPart.navigation],
  note:
      'CE-AC/CE-SC/CE-NV — each alternative-flow step: actor action, server call, and/or screen transition',
)
class AlternativeStepEntry extends DocSpecsSection {
  @Form([
    Field(
      'stepNumber',
      String,
      'Step Number',
      hint: 'Sequential position within the alternative flow',
    ),
    Field('action', String, 'Action', hint: 'The action taken in this step'),
    Field(
      'response',
      String,
      'Response',
      hint: 'How the system responds to the action',
    ),
    Field(
      'expectedResult',
      String,
      'Expected Result',
      hint: 'The observable outcome after the step',
    ),
    Field(
      'serverOperation',
      String,
      'Server Operation',
      hint: 'ServerOperationEntry.operationName (SVOPR registry) this step '
          'calls. State it only where the step reaches the server: the client '
          'call is generated exactly where this is present, so a step that '
          'names nothing generates no call.',
      refersTo: ['SVOPE.operationName'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  @SectionId('SVCST-STEP-LST')
  @SectionIdPattern('SVCST-STEP-xxx')
  @ContentHelp('Fill this in only where the step reaches the server. Add one '
      'entry per thing that has to happen to assemble the request, to apply '
      'the response, or to surface an error — in the order it happens, each '
      'entry saying which of the three it belongs to.')
  @SerializationOrder(1)
  List<ServerCallStepEntry> serverCallSteps = [];
}

// ---------------------------------------------------------------------------
// 6.1.10 Process Metrics and KPIs
// ---------------------------------------------------------------------------

/// 6.1.10. Process Metrics and KPIs.
///
/// Process-level KPIs, SLAs, and measurement strategy.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency',
    'Six Sigma / Lean — process metrics',
  ],
  'Defines the KPIs, SLAs, and measurement strategy used to gauge each target process in production.',
)
@SectionId('PMAK')
@DetailedIn(D02TargetOperatingModel)
@FollowUpKind(
  [FollowUpProcess.org, FollowUpProcess.ops],
  note:
      'follow-up material under OrganizationAndProcessConcept in the SBP; '
      'reached here directly by a detail-document path',
)
class ProcessMetric extends DocSpecsSection {
  @ContentHelp('''
How each business process is measured for success once in production.

**What to capture:**
- KPI catalog per process (name, formula, target, tolerance)
- Leading vs lagging indicators
- Measurement frequency and data source
- Dashboard / report ownership
- Thresholds for corrective action
- Baseline values for comparison
''')
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 6.2.5 Use Case Traceability
// ---------------------------------------------------------------------------

/// 6.2.5. Use Case Traceability.
///
/// Use case ↔ requirement ↔ process ↔ test traceability.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148 §6 — requirements traceability',
    'BABOK v3 — use cases & scenarios',
  ],
  'Provides the traceability matrix linking use cases to requirements, processes, and tests so every use case is justified and covered.',
)
@SectionId('USCATR')
@DetailedIn(D05InteractionScenarios)
@NoArtifact(
  NoArtifactReason.view,
  note:
      'a traceability matrix over use-case and requirement ids declared '
      'elsewhere',
)
class UseCaseTraceability extends DocSpecsSection {
  @ContentHelp('''
Traceability matrix linking use cases to requirements, processes, and
tests. Ensures every use case is justified and covered.

**What to capture:**
- UC × RC matrix (which requirements each use case realizes)
- UC × BP matrix (which processes each use case participates in)
- UC × test matrix (which tests cover each use case)
- Orphan detection (UCs without requirements or tests)
- Change-impact helper (navigate from a changed UC to affected artifacts)
''')
  @override
  @SerializationOrder(0)
  String? content;
}
