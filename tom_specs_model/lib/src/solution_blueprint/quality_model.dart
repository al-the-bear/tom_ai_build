/// Section 11: System Quality Goals. Seeds → QAP.
///
/// Quality goals for acceptance testing, organized by quality category.
/// Comprehensive quality management framework covering user-related,
/// technical, operational, and documentation quality attributes.
/// Follows ISO/IEC 25010 (SQuaRE) quality model and enterprise QA practices.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';
import 'delivery_scope_and_acceptance.dart';

/// 11. System Quality Goals. Seeds → QAP.
///
/// Quality goals selected from standard quality criteria and operationalized
/// for project-specific acceptance testing. Provides governing structure for
/// all quality attributes and acceptance criteria. Seeds the QAP (Quality &
/// Acceptance Plan) document where quality goals are expanded into measurable
/// targets, verification methods, and acceptance criteria.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the system-and-software product quality model organises product quality into eight characteristics and their sub-characteristics',
    'ISO/IEC 25000:2014 — the SQuaRE series provides a coherent framework for specifying and evaluating software product quality requirements',
  ],
  'Captures the system quality goals governing all quality attributes and acceptance criteria.',
)
@SectionId('SYQG')
@Comment('Seeds → QAP')
@MapsTo(D10QualityAcceptancePlan)
class SystemQualityGoals extends DocSpecsSection {
  @SectionId('SYQG-GOVE')
  @Form([
    Field(
      'qualityApproach',
      String,
      'Quality Approach',
      hint: 'Overall quality philosophy: proactive, reactive, hybrid',
    ),
    Field(
      'qualityStandards',
      String,
      'Applicable Quality Standards',
      hint: 'ISO 25010, ISO 9001, CMMI, industry-specific',
    ),
    Field(
      'qualityOwner',
      String,
      'Quality Owner',
      hint: 'Role accountable for quality outcomes',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? governanceContent;

  /// Governance board and escalation details.
  @SectionId('SQGGV')
  @StandardReferences([
    'ISO/IEC 25010:2023 — quality requirements are governed and maintained to ensure the product quality model is applied consistently across the system',
  ], 'Captures the governance board and escalation path for quality decisions.')
  @Form([
    Field(
      'qualityReviewBoard',
      String,
      'Quality Review Board',
      hint: 'Governance body for quality decisions',
    ),
    Field(
      'qualityMeetingCadence',
      String,
      'Quality Meeting Cadence',
      hint: 'Weekly, bi-weekly, sprint-aligned',
    ),
    Field(
      'qualityEscalationPath',
      String,
      'Escalation Path',
      hint: 'How quality issues escalate to leadership',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? governance;

  /// Baseline and target settings.
  @SectionId('SQGBS')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — a quality baseline records the current measured levels of the product quality characteristics as a reference for improvement',
    ],
    'Captures the quality baseline and target settings used as a reference for improvement.',
  )
  @Form([
    Field(
      'qualityBaselineDate',
      String,
      'Quality Baseline Date',
      hint: 'When quality targets were baselined',
    ),
    Field(
      'qualityBaselineVersion',
      String,
      'Baseline Version',
      hint: 'Version identifier of the quality baseline snapshot',
    ),
    Field(
      'overallQualityTargetLevel',
      String,
      'Overall Quality Target Level',
      hint: 'High, production-grade, MVP-acceptable',
    ),
    Field(
      'qualityRiskTolerance',
      String,
      'Quality Risk Tolerance',
      hint: 'Low (zero defects), medium, high tolerance',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? baseline;

  /// Measurement and reporting approach.
  @SectionId('SQGMS')
  @StandardReferences([
    'ISO/IEC 25023:2016 — measures are defined and applied to quantify the quality characteristics and sub-characteristics of the system and software product',
  ], 'Captures how quality is measured, reported, and tracked over time.')
  @Form([
    Field(
      'qualityMetricsFramework',
      String,
      'Metrics Framework',
      hint: 'How quality is measured: GQM, balanced scorecard',
    ),
    Field(
      'qualityReportingFrequency',
      String,
      'Reporting Frequency',
      hint: 'Daily, weekly, sprint, release',
    ),
    Field(
      'qualityDashboardTool',
      String,
      'Quality Dashboard Tool',
      hint: 'SonarQube, custom dashboard, spreadsheet',
    ),
    Field(
      'defectTrackingSystem',
      String,
      'Defect Tracking System',
      hint: 'Jira, Azure DevOps, GitHub Issues',
    ),
    Field(
      'qualityTrendAnalysis',
      String,
      'Trend Analysis Approach',
      hint: 'How quality trends are tracked over time',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? measurement;

  /// Quality resources and enablement.
  @SectionId('SQGRS')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — adequate resources and responsibilities are assigned so that specified quality requirements can be achieved and verified',
    ],
    'Captures the resources, budget, and enablement assigned to achieve quality goals.',
  )
  @Form([
    Field(
      'qualityBudget',
      String,
      'Quality Budget',
      hint: 'Budget allocated for QA activities',
    ),
    Field(
      'qaTeamSize',
      String,
      'QA Team Size',
      hint: 'Number of dedicated QA resources',
    ),
    Field(
      'testAutomationTarget',
      String,
      'Test Automation Target %',
      hint: 'Target percentage of automated tests',
    ),
    Field(
      'qualityTrainingPlan',
      String,
      'Quality Training Plan',
      hint: 'Training for team on quality practices',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? resources;

  /// Executive summary of quality goals and approach.
  @ContentHelp(
    'High-level overview of quality objectives, expected quality '
    'level, key quality risks, and approach summary.',
  )
  @SerializationOrder(5)
  TextSection executiveSummary = TextSection();

  /// Quality vision and principles.
  @ContentHelp(
    'Quality vision statement, core principles guiding '
    'quality decisions, and non-negotiable quality standards.',
  )
  @SerializationOrder(6)
  TextSection qualityVision = TextSection();

  /// Quality assurance strategy.
  @ContentHelp(
    'Overall QA strategy: shift-left testing, continuous testing, '
    'test pyramid approach, verification vs validation approach.',
  )
  @SerializationOrder(7)
  TextSection qaStrategy = TextSection();

  /// Quality attribute interdependencies.
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — improving one quality characteristic can negatively affect another, so interdependencies between attributes are recorded to manage trade-offs',
    ],
    'Lists interdependencies between quality attributes used to manage trade-offs.',
  )
  @SectionId('SYQG-ATTR-LST')
  @SectionIdPattern('SYQG-ATTR-xxx')
  @ContentHelp('Add one entry per quality attribute interdependency.')
  @SerializationOrder(8)
  List<DocSpecsSection> attributeInterdependencies = [];

  /// Quality attribute priority radar.
  @ContentHelp('Visual showing relative importance of quality attributes.')
  @SerializationOrder(9)
  DiagramSection qualityRadar = DiagramSection();

  /// 11.1. Quality Framework.
  @SerializationOrder(10)
  QualityFramework framework = QualityFramework();

  // 11.2–11.9: the eight ISO/IEC 25010:2023 product-quality characteristics.
  // The former handbook buckets (user / technical / operations) were dissolved
  // in L34C-8 and their attribute leaves re-homed under these characteristics.

  /// 11.2. Functional Suitability (ISO/IEC 25010:2023).
  @SerializationOrder(11)
  FunctionalSuitabilityCharacteristic functionalSuitability =
      FunctionalSuitabilityCharacteristic();

  /// 11.3. Performance Efficiency (ISO/IEC 25010:2023).
  @SerializationOrder(12)
  PerformanceEfficiencyCharacteristic performanceEfficiency =
      PerformanceEfficiencyCharacteristic();

  /// 11.4. Compatibility (ISO/IEC 25010:2023).
  @SerializationOrder(13)
  CompatibilityCharacteristic compatibility = CompatibilityCharacteristic();

  /// 11.5. Interaction Capability (ISO/IEC 25010:2023; formerly Usability).
  @SerializationOrder(14)
  InteractionCapabilityCharacteristic interactionCapability =
      InteractionCapabilityCharacteristic();

  /// 11.6. Reliability (ISO/IEC 25010:2023).
  @SerializationOrder(15)
  ReliabilityCharacteristic reliability = ReliabilityCharacteristic();

  /// 11.7. Security (ISO/IEC 25010:2023).
  @SerializationOrder(16)
  SecurityCharacteristic security = SecurityCharacteristic();

  /// 11.8. Maintainability (ISO/IEC 25010:2023).
  @SerializationOrder(17)
  MaintainabilityCharacteristic maintainability =
      MaintainabilityCharacteristic();

  /// 11.9. Flexibility (ISO/IEC 25010:2023; absorbs the former Portability).
  @SerializationOrder(18)
  FlexibilityCharacteristic flexibility = FlexibilityCharacteristic();

  /// 11.10. Documentation Quality (ISO/IEC 26514 documentation-deliverable
  /// annex — has no ISO/IEC 25010:2023 product-quality home; retained as a
  /// documentation-quality annex per L34C-8).
  @SerializationOrder(19)
  DocumentationQualityCriteria documentationQuality =
      DocumentationQualityCriteria();

  /// 11.6. Quality Prioritization.
  @SerializationOrder(20)
  QualityPrioritization prioritization = QualityPrioritization();

  /// 11.7. Acceptance Criteria Summary.
  @SerializationOrder(21)
  AcceptanceCriteriaSummary acceptanceCriteria = AcceptanceCriteriaSummary();

  /// 11.8. Test Strategy..
  @SerializationOrder(22)
  TestStrategy testStrategy = TestStrategy();
}

/// 11.1. Quality Framework.
///
/// Overall quality approach for the project defining objectives, categories,
/// and how quality is structured and governed across the system.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — the quality framework defines the characteristics, sub-characteristics, and measurement approach used to specify and evaluate product quality',
  ],
  'Captures the overall quality framework defining objectives, categories, and structure.',
)
@SectionId('QLFWK')
@DetailedIn(D10QualityAcceptancePlan)
class QualityFramework extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Framework Configuration
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('QLFWK-FRAM')
  @Form([
    // Framework selection
    Field(
      'qualityModel',
      String,
      'Quality Model',
      hint: 'ISO 25010, McCall, Boehm, custom',
    ),
    Field(
      'qualityModelVersion',
      String,
      'Model Version',
      hint: 'Specific version of quality model',
    ),
    Field(
      'qualityModelAdaptations',
      String,
      'Model Adaptations',
      hint: 'How standard model is adapted for this project',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? frameworkContent;

  /// Quality objective structure and alignment.
  @SectionId('QFOBJ')
  @StandardReferences([
    'ISO/IEC 25010:2023 — quality objectives express the required levels of the product quality characteristics as measurable targets',
  ], 'Captures the structure and business alignment of the quality objectives.')
  @Form([
    Field(
      'objectivesHierarchy',
      String,
      'Objectives Hierarchy',
      hint: 'How quality objectives are structured',
    ),
    Field(
      'objectivesAlignment',
      String,
      'Objectives Alignment',
      hint: 'How quality objectives align with business goals',
    ),
    Field(
      'objectivesMeasurability',
      String,
      'Measurability Requirement',
      hint: 'All objectives SMART, key objectives only',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? objectives;

  /// Trade-off priorities and decision authority.
  @SectionId('QFTRD')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — because improving one characteristic can degrade another, trade-offs between quality characteristics are made explicit and justified',
    ],
    'Captures the trade-off priorities and decision authority between quality attributes.',
  )
  @Form([
    Field(
      'primaryQualityAttribute',
      String,
      'Primary Quality Attribute',
      hint: 'Most important attribute when trade-offs required',
    ),
    Field(
      'secondaryQualityAttribute',
      String,
      'Secondary Quality Attribute',
      hint: 'Attribute yielded when the primary attribute takes precedence',
    ),
    Field(
      'tradeOffApproach',
      String,
      'Trade-off Approach',
      hint: 'How conflicts between attributes are resolved',
    ),
    Field(
      'qualityCompromiseAuthority',
      String,
      'Compromise Authority',
      hint: 'Who can authorize quality trade-offs',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? tradeOffs;

  /// Verification and defect handling approach.
  @SectionId('QFVER')
  @StandardReferences(
    [
      'ISO/IEC 25040:2011 — the quality evaluation process defines activities to plan, execute, and conclude the evaluation of software product quality',
      'ISO/IEC 25023:2016 — quality measures are applied to verify the achieved quality levels',
    ],
    'Captures how quality is verified and how defects are classified and handled.',
  )
  @Form([
    Field(
      'verificationStrategy',
      String,
      'Verification Strategy',
      hint: 'Testing, review, analysis, demonstration',
    ),
    Field(
      'verificationCoverage',
      String,
      'Verification Coverage',
      hint: 'All attributes, critical only, risk-based',
    ),
    Field(
      'defectClassification',
      String,
      'Defect Classification Scheme',
      hint: 'Critical, major, minor, trivial',
    ),
    Field(
      'defectPriorityScheme',
      String,
      'Defect Priority Scheme',
      hint: 'P1-P5, urgent/high/medium/low',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? verification;

  /// 11.1.1. Quality Objectives Overview.
  @ContentHelp(
    'Overall quality objectives: expected quality level, '
    'how quality will be measured, acceptable trade-offs.',
  )
  @SerializationOrder(4)
  TextSection qualityObjectivesOverview = TextSection();

  /// Quality objectives breakdown by category.
  @ContentHelp(
    'Structured breakdown of objectives for each quality '
    'category with measurable targets.',
  )
  @SerializationOrder(5)
  TextSection objectivesBreakdown = TextSection();

  /// 11.1.2. Quality Categories — contains 0+× QualityCategory.
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — product quality is organised into characteristics and sub-characteristics that form the categories against which quality is specified and evaluated',
    ],
    'Lists the quality categories against which requirements are specified and evaluated.',
  )
  @SectionId('QCATE-QUAL-LST')
  @SectionIdPattern('QCATE-QUAL-xxx')
  @ContentHelp('Add one entry per quality category.')
  @SerializationOrder(6)
  List<QualityCategoryEntry> qualityCategories = [];

  /// Quality dependencies map.
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — quality characteristics are interrelated, so dependencies between categories are captured to reason about trade-offs',
    ],
    'Lists dependencies between quality categories used to reason about trade-offs.',
  )
  @SectionId('QLFWK-CATE-LST')
  @SectionIdPattern('QLFWK-CATE-xxx')
  @ContentHelp('Add one entry per category dependency.')
  @SerializationOrder(7)
  List<DocSpecsSection> categoryDependencies = [];
}

/// A quality category entry (form).
///
/// Defines a quality category with its attributes, weight, and relationship
/// to other categories.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — each quality category groups related quality characteristics against which requirements are defined and evaluated',
  ],
  'Captures a single quality category with its attributes, weight, and relationships.',
)
@SectionId('QCATE')
class QualityCategoryEntry extends DocSpecsSection {
  @Form([
    Field(
      'categoryId',
      String,
      'Category ID',
      hint: 'Unique identifier (e.g., QC-USER-01)',
    ),
    Field(
      'categoryName',
      String,
      'Category Name',
      required: true,
      hint: 'User-Related, Technical, Operational, Documentation',
    ),
    Field(
      'categoryWeight',
      int,
      'Category Weight (1-100)',
      hint: 'Relative importance in overall quality',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Description and priority context.
  @SectionId('QCADF')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — each quality characteristic is defined so that the intended meaning is unambiguous and can be measured',
    ],
    'Captures the definition, scope, and priority context of this quality category.',
  )
  @Form([
    Field(
      'categoryDescription',
      String,
      'Description',
      hint: 'Purpose and scope of this category',
    ),
    Field(
      'categoryScope',
      String,
      'Scope',
      hint: 'What aspects of quality this covers',
    ),
    Field(
      'categoryPriority',
      String,
      'Priority',
      hint: 'Critical, high, medium, low',
    ),
    Field(
      'categoryRationale',
      String,
      'Priority Rationale',
      hint: 'Why this priority level',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? definition;

  /// Category relationships.
  @SectionId('QCARL')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the relevance of each quality characteristic to the system is justified against the stated needs and context of use',
    ],
    'Captures how this quality category relates to and depends on other categories.',
  )
  @Form([
    Field(
      'parentCategory',
      String,
      'Parent Category',
      hint: 'Higher-level category if hierarchical',
    ),
    Field(
      'relatedCategories',
      String,
      'Related Categories',
      hint: 'Categories that interact with this one',
    ),
    Field(
      'conflictingCategories',
      String,
      'Conflicting Categories',
      hint: 'Categories that may trade off against this',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? relationships;

  /// Governance ownership.
  @SectionId('QCAGV')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — ownership and governance of each quality category are assigned to ensure the associated requirements are maintained',
    ],
    'Captures the ownership and governance responsibilities for this quality category.',
  )
  @Form([
    Field(
      'categoryOwner',
      String,
      'Category Owner',
      hint: 'Role responsible for this quality area',
    ),
    Field(
      'reviewFrequency',
      String,
      'Review Frequency',
      hint: 'How often category metrics are reviewed',
    ),
    Field(
      'escalationThreshold',
      String,
      'Escalation Threshold',
      hint: 'When category issues escalate',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;

  /// Measurement targets.
  @SectionId('QCAMT')
  @StandardReferences(
    [
      'ISO/IEC 25023:2016 — quality measures and measurement functions are defined to quantify each quality characteristic during evaluation',
    ],
    'Captures the metrics and target values used to measure this quality category.',
  )
  @Form([
    Field(
      'primaryMetric',
      String,
      'Primary Metric',
      hint: 'Main metric for this category',
    ),
    Field(
      'secondaryMetrics',
      String,
      'Secondary Metrics',
      hint: 'Supporting metrics',
    ),
    Field(
      'targetValue',
      String,
      'Target Value',
      hint: 'Target for primary metric',
    ),
    Field(
      'currentBaseline',
      String,
      'Current Baseline',
      hint: 'Starting baseline value',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? metrics;

  /// Detailed category definition.
  @ContentHelp(
    'Extended description of category scope, boundaries, '
    'and quality attributes included.',
  )
  @SerializationOrder(5)
  TextSection categoryDetails = TextSection();
}

/// 11.2. Functional Suitability (ISO/IEC 25010:2023).
///
/// Degree to which the product provides functions that meet stated and implied
/// needs — functional completeness and correctness. Re-homes the former
/// user-bucket functional leaves under the 25010:2023 spine (L34C-8).
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — functional suitability is the degree to which a product or system provides functions that meet stated and implied needs when used under specified conditions',
  ],
  'This section captures the functional suitability characteristic of the solution.',
)
@SectionId('FNSU')
@DetailedIn(D10QualityAcceptancePlan)
class FunctionalSuitabilityCharacteristic extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Functional Suitability Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('FNSU-FUNC')
  @Form([
    Field(
      'functionalSuitabilityApproach',
      String,
      'Functional Suitability Approach',
      hint: 'How functional completeness and correctness are assured',
    ),
    Field(
      'functionalCoverageTarget',
      String,
      'Functional Coverage Target',
      hint: 'Required vs. optional feature coverage',
    ),
    Field(
      'correctnessStandard',
      String,
      'Correctness Standard',
      hint: 'Acceptable defect density, accuracy thresholds',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? functionalSuitabilityContent;

  /// Functional suitability overview.
  @ContentHelp(
    'Executive summary of functional-suitability goals, '
    'coverage targets, and correctness metrics.',
  )
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.2.1. Functional Completeness.
  @SerializationOrder(2)
  FunctionalCompleteness functionalCompleteness = FunctionalCompleteness();

  /// 11.2.2. Correctness.
  @SerializationOrder(3)
  Correctness correctness = Correctness();
}

/// 11.5. Interaction Capability (ISO/IEC 25010:2023; formerly Usability).
///
/// Degree to which the product can be interacted with effectively, efficiently
/// and satisfactorily by users. Re-homes the former user-bucket usability leaf
/// under the 25010:2023 spine (L34C-8). The dissolved user-quality overview
/// form is preserved here so no authored content is lost.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — interaction capability is the degree to which a product or system can be interacted with by specified users to exchange information through the user interface to complete specified tasks',
  ],
  'This section captures the interaction capability characteristic of the solution.',
)
@SectionId('INCP')
@DetailedIn(D10QualityAcceptancePlan)
class InteractionCapabilityCharacteristic extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Interaction Capability Overview (migrated from the former user bucket)
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('INCP-INTE')
  @Form([
    Field(
      'userQualityPhilosophy',
      String,
      'User Quality Philosophy',
      hint: 'User-first, balanced, efficiency-focused',
    ),
    Field(
      'targetUserExperience',
      String,
      'Target User Experience',
      hint: 'Delightful, efficient, adequate, minimal',
    ),
    Field(
      'userResearchBasis',
      String,
      'User Research Basis',
      hint: 'Personas, surveys, interviews, analytics',
    ),
    Field(
      'userFeedbackChannel',
      String,
      'User Feedback Channel',
      hint: 'How user quality feedback is collected',
    ),
    Field(
      'userSatisfactionTarget',
      String,
      'User Satisfaction Target',
      hint: 'NPS > 50, CSAT > 80%, etc.',
    ),
    Field(
      'accessibilityLevel',
      String,
      'Accessibility Level',
      hint: 'WCAG 2.1 AA, AAA, Section 508',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? interactionCapabilityContent;

  /// Interaction capability overview.
  @ContentHelp(
    'Executive summary of interaction-capability goals, '
    'target user experience, and key user-quality metrics.',
  )
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.5.1. Usability.
  @SerializationOrder(2)
  Usability usability = Usability();
}

/// 11.2.1. Usability quality.
@StandardReferences([
  'ISO/IEC 25010:2023 — interaction capability includes appropriateness recognizability, learnability, operability, user error protection, and user engagement',
], 'This section captures the usability quality group of the solution.')
@SectionId('USAQL')
class Usability extends DocSpecsSection {
  @Form([
    Field(
      'operabilityTarget',
      String,
      'Operability Target',
      hint: 'Ease of operation: intuitive, training-required',
    ),
    Field(
      'ergonomicsStandard',
      String,
      'Ergonomics Standard',
      hint: 'ISO 9241, platform guidelines',
    ),
    Field(
      'learnabilityTarget',
      String,
      'Learnability Target',
      hint: 'Time to proficiency: <1 hour, <1 day',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Operability verification and ergonomics goals.
  @SectionId('USAOP')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — operability is the degree to which a product or system has attributes that make it easy to operate and control',
    ],
    'This section captures operability verification and ergonomics goals for the solution.',
  )
  @Form([
    Field(
      'operabilityMetric',
      String,
      'Operability Metric',
      hint: 'Task completion rate, error rate',
    ),
    Field(
      'operabilityVerification',
      String,
      'Operability Verification',
      hint: 'Usability testing, heuristic evaluation',
    ),
    Field(
      'ergonomicsTarget',
      String,
      'Ergonomics Target',
      hint: 'Reduce cognitive load, minimize clicks',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? operability;

  /// Learnability and onboarding expectations.
  @SectionId('USALN')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — learnability is the degree to which a product or system can be used by specified users to achieve specified goals of learning to use the product with effectiveness, efficiency, freedom from risk, and satisfaction',
    ],
    'This section captures learnability and onboarding expectations for the solution.',
  )
  @Form([
    Field(
      'learnabilityVerification',
      String,
      'Learnability Verification',
      hint: 'First-use testing, training time measurement',
    ),
    Field(
      'onboardingRequirement',
      String,
      'Onboarding Requirement',
      hint: 'Self-service, guided tour, training required',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? learnability;

  /// Clarity and complexity constraints.
  @SectionId('USACL')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — self-descriptiveness is the degree to which a product presents appropriate information, where needed by the user, to make the product immediately obvious without excessive interactions with the product or other resources',
    ],
    'This section captures clarity and complexity constraints supporting self-descriptiveness.',
  )
  @Form([
    Field(
      'functionalClarityTarget',
      String,
      'Functional Clarity Target',
      hint: 'Labels, icons, workflows self-explanatory',
    ),
    Field(
      'helpSystemRequirement',
      String,
      'Help System Requirement',
      hint: 'Contextual help, tooltips, documentation',
    ),
    Field(
      'complexityLimit',
      String,
      'Complexity Limit',
      hint: 'Max steps per workflow, max form fields',
    ),
    Field(
      'cognitiveLoadTarget',
      String,
      'Cognitive Load Target',
      hint: 'Info per screen, decision points',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? clarity;

  /// Interaction control settings.
  @SectionId('USAIN')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — user engagement is the degree to which the user interface presents functions and information in an inviting and motivating manner encouraging continued interaction',
    ],
    'This section captures interaction control settings that shape user engagement.',
  )
  @Form([
    Field(
      'undoRequirement',
      String,
      'Undo Requirement',
      hint: 'All actions, critical actions, none',
    ),
    Field(
      'customizationLevel',
      String,
      'Customization Level',
      hint: 'User preferences, layout, workflow',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? interaction;

  /// Perceived and measured responsiveness targets.
  @SectionId('USAPR')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — inclusivity is the degree to which a product can be used by people with the widest range of characteristics and capabilities to achieve specified goals in a specified context of use',
    ],
    'This section captures perceived and measured responsiveness targets for usability performance.',
  )
  @Form([
    Field(
      'responseTimeP50',
      String,
      'Response Time P50',
      hint: 'Median response time target (e.g., <200ms)',
    ),
    Field(
      'responseTimeP95',
      String,
      'Response Time P95',
      hint: '95th percentile (e.g., <500ms)',
    ),
    Field(
      'responseTimeP99',
      String,
      'Response Time P99',
      hint: '99th percentile (e.g., <1s)',
    ),
    Field(
      'perceivedPerformance',
      String,
      'Perceived Performance',
      hint: 'Loading indicators, optimistic updates',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? performance;

  /// Detailed usability requirements narrative.
  @SerializationOrder(6)
  TextSection narrative = TextSection();
}

/// 11.2.2. Functional completeness quality.
@StandardReferences([
  'ISO/IEC 25010:2023 — functional completeness is the degree to which the set of functions covers all the specified tasks and intended user objectives',
], 'This section captures the functional completeness quality of the solution.')
@SectionId('FNCOQ')
class FunctionalCompleteness extends DocSpecsSection {
  @Form([
    // Coverage
    Field(
      'featureCoverageTarget',
      String,
      'Feature Coverage Target %',
      hint: 'Percentage of specified features implemented',
    ),
    Field(
      'coreWorkflowCoverage',
      String,
      'Core Workflow Coverage',
      hint: '100% of core, 80% of secondary',
    ),
    Field(
      'edgeCaseHandling',
      String,
      'Edge Case Handling',
      hint: 'Explicit handling, graceful degradation',
    ),
    // Scope management
    Field(
      'scopePrioritization',
      String,
      'Scope Prioritization',
      hint: 'MoSCoW, weighted scoring',
    ),
    Field(
      'mvpDefinition',
      String,
      'MVP Definition',
      hint: 'Minimum feature set for launch',
    ),
    Field(
      'deferredFeatureHandling',
      String,
      'Deferred Feature Handling',
      hint: 'How deferred features are communicated',
    ),
    // Verification
    Field(
      'completenessVerification',
      String,
      'Completeness Verification',
      hint: 'Traceability matrix, acceptance testing',
    ),
    Field(
      'userStoryTracking',
      String,
      'User Story Tracking',
      hint: 'How coverage is tracked to requirements',
    ),
    Field(
      'gapAnalysisFrequency',
      String,
      'Gap Analysis Frequency',
      hint: 'Sprint, release, milestone',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Detailed functional completeness narrative.
  @SerializationOrder(1)
  TextSection narrative = TextSection();
}

/// 11.2.3. Correctness quality.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — functional correctness is the degree to which a product or system provides accurate results when used by intended users',
  ],
  'This section captures the functional correctness quality group of the solution.',
)
@SectionId('COQU')
class Correctness extends DocSpecsSection {
  @Form([
    Field(
      'defectDensityTarget',
      String,
      'Defect Density Target',
      hint: 'Defects per KLOC, per function point',
    ),
    Field(
      'criticalDefectTarget',
      String,
      'Critical Defect Target',
      hint: 'Zero critical/blocking, <N major',
    ),
    Field(
      'defectEscapeRate',
      String,
      'Defect Escape Rate',
      hint: 'Defects found post-release',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data integrity expectations.
  @SectionId('COQUIN')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — functional correctness is the degree to which a product provides the correct results with the needed degree of precision',
    ],
    'This section captures data integrity expectations that support correct results.',
  )
  @Form([
    Field(
      'dataIntegrityRequirement',
      String,
      'Data Integrity Requirement',
      hint: 'ACID, eventual consistency',
    ),
    Field(
      'dataValidationCoverage',
      String,
      'Data Validation Coverage',
      hint: 'All inputs, critical inputs',
    ),
    Field(
      'dataCorruptionHandling',
      String,
      'Data Corruption Handling',
      hint: 'Detection, recovery, prevention',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? integrity;

  /// Accuracy and auditability requirements.
  @SectionId('COQUAC')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — functional correctness is the degree to which a product or system provides accurate results when used by intended users under specified conditions',
    ],
    'This section captures accuracy targets and auditability requirements for correct results.',
  )
  @Form([
    Field(
      'calculationAccuracyTarget',
      String,
      'Calculation Accuracy Target',
      hint: 'Decimal precision, rounding rules',
    ),
    Field(
      'financialAccuracyRequirement',
      String,
      'Financial Accuracy',
      hint: 'Penny-accurate, significant figures',
    ),
    Field(
      'auditTrailRequirement',
      String,
      'Audit Trail Requirement',
      hint: 'All changes, financial only',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? accuracy;

  /// Verification and regression approach.
  @SectionId('COQUVE')
  @StandardReferences(
    [
      'ISO/IEC 25023:2016 — quality measures are defined and applied to quantify the functional suitability of the system and software product',
    ],
    'This section captures how functional suitability is verified through defined quality measures.',
  )
  @Form([
    Field(
      'correctnessVerification',
      String,
      'Correctness Verification',
      hint: 'Unit tests, integration tests, UAT',
    ),
    Field(
      'testCoverageTarget',
      String,
      'Test Coverage Target',
      hint: 'Code coverage %, requirement coverage',
    ),
    Field(
      'regressionTestingApproach',
      String,
      'Regression Testing',
      hint: 'Automated, manual, risk-based',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? verification;

  /// Detailed correctness requirements narrative.
  @SerializationOrder(4)
  TextSection narrative = TextSection();
}

/// 11.3. Performance Efficiency (ISO/IEC 25010:2023).
///
/// Performance relative to the amount of resources used under stated
/// conditions. Re-homes the former technical-bucket efficiency leaf under the
/// 25010:2023 spine (L34C-8). The dissolved technical-quality overview form is
/// preserved here so no authored content is lost.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — performance efficiency is the degree to which a product performs its functions within specified time and throughput parameters and is efficient in the use of resources under stated conditions',
  ],
  'This section captures the performance efficiency characteristic of the solution.',
)
@SectionId('PEEF')
@DetailedIn(D10QualityAcceptancePlan)
class PerformanceEfficiencyCharacteristic extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Performance Efficiency Overview (migrated from the former technical bucket)
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('PEEF-PERF')
  @Form([
    Field(
      'technicalQualityPhilosophy',
      String,
      'Technical Quality Philosophy',
      hint: 'Performance-first, maintainability-first, balanced',
    ),
    Field(
      'architecturalQualityGoals',
      String,
      'Architectural Quality Goals',
      hint: 'Key architectural quality attributes',
    ),
    Field(
      'technicalDebtTolerance',
      String,
      'Technical Debt Tolerance',
      hint: 'Zero, controlled, pragmatic',
    ),
    Field(
      'codeQualityStandard',
      String,
      'Code Quality Standard',
      hint: 'Style guide, linting rules',
    ),
    Field(
      'designPrinciplesAdherence',
      String,
      'Design Principles Adherence',
      hint: 'SOLID, DRY, KISS, YAGNI',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? performanceEfficiencyContent;

  /// Performance efficiency overview.
  @ContentHelp(
    'Executive summary of performance-efficiency goals, '
    'architectural decisions, and key technical metrics.',
  )
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.3.1. Efficiency.
  @SerializationOrder(2)
  Efficiency efficiency = Efficiency();
}

/// 11.4. Compatibility (ISO/IEC 25010:2023).
///
/// Degree to which the product can exchange information with other products and
/// share the same environment and resources (co-existence + interoperability).
/// Introduced by the 25010:2023 regroup (L34C-8); modelled as an overview
/// pending project-specific compatibility leaves.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — compatibility is the degree to which a product, system, or component can exchange information with other products, systems, or components, or perform its required functions while sharing the same common environment and resources',
  ],
  'This section captures the compatibility characteristic including co-existence and interoperability.',
)
@SectionId('CMPT')
@DetailedIn(D10QualityAcceptancePlan)
class CompatibilityCharacteristic extends DocSpecsSection {
  @SectionId('CMPT-COMP')
  @Form([
    Field(
      'coExistenceRequirements',
      String,
      'Co-existence Requirements',
      hint: 'Other products sharing the environment without adverse impact',
    ),
    Field(
      'interoperabilityStandards',
      String,
      'Interoperability Standards',
      hint: 'Protocols/formats for exchanging and using information',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? compatibilityContent;

  /// Compatibility overview.
  @ContentHelp('Executive summary of co-existence and interoperability goals.')
  @SerializationOrder(1)
  TextSection overview = TextSection();
}

/// 11.9. Flexibility (ISO/IEC 25010:2023; absorbs the former Portability).
///
/// Degree to which the product can be adapted to changes in requirements,
/// contexts of use, or system environment (adaptability, scalability,
/// installability, replaceability). Re-homes the former technical-bucket
/// flexibility and portability leaves under the 25010:2023 spine (L34C-8).
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — flexibility is the degree to which a product can be adapted to changes in its requirements, contexts of use, or system environment',
  ],
  'This section captures the flexibility characteristic including adaptability and portability.',
)
@SectionId('FLXC')
@DetailedIn(D10QualityAcceptancePlan)
class FlexibilityCharacteristic extends DocSpecsSection {
  @SectionId('FLXC-FLEX')
  @Form([
    Field(
      'flexibilityApproach',
      String,
      'Flexibility Approach',
      hint: 'How adaptability, scalability and portability are achieved',
    ),
    Field(
      'portabilityTarget',
      String,
      'Portability Target',
      hint: 'Target environments/platforms the product must run on',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? flexibilityContent;

  /// Flexibility overview.
  @ContentHelp(
    'Executive summary of flexibility, adaptability and '
    'portability goals.',
  )
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.9.1. Flexibility (adaptability/scalability/extensibility).
  @SerializationOrder(2)
  Flexibility flexibility = Flexibility();

  /// 11.9.2. Portability.
  @SerializationOrder(3)
  Portability portability = Portability();
}

/// 11.7. Security (ISO/IEC 25010:2023).
///
/// Degree to which the product protects information and data. Re-homes the
/// former technical-bucket security leaf and the operations-bucket IT-security
/// operations leaf under the 25010:2023 spine (L34C-8).
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — security is the degree to which a product protects information and data so that persons or other products have the degree of data access appropriate to their types and levels of authorization',
  ],
  'This section captures the core security quality expectations of the solution.',
)
@SectionId('SECC')
@DetailedIn(D10QualityAcceptancePlan)
class SecurityCharacteristic extends DocSpecsSection {
  @SectionId('SECC-SECU')
  @Form([
    Field(
      'securityApproach',
      String,
      'Security Approach',
      hint: 'Zero-trust, defence-in-depth, least-privilege',
    ),
    Field(
      'securityComplianceTarget',
      String,
      'Security Compliance Target',
      hint: 'ISO 27001, SOC 2, GDPR, sector-specific',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? securityContent;

  /// Security overview.
  @ContentHelp(
    'Executive summary of security goals, threat model, and '
    'compliance targets.',
  )
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.7.1. Security (product security attributes).
  @SerializationOrder(2)
  Security security = Security();

  /// 11.7.2. IT Security Operations.
  @SerializationOrder(3)
  ItSecurityOperations itSecurityOperations = ItSecurityOperations();
}

/// 11.8. Maintainability (ISO/IEC 25010:2023).
///
/// Degree of effectiveness and efficiency with which the product can be
/// modified. Re-homes the former technical-bucket maintainability leaf under
/// the 25010:2023 spine (L34C-8).
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — maintainability is the degree of effectiveness and efficiency with which a product can be modified to correct, improve, extend, or adapt it',
  ],
  'This section captures the core maintainability quality expectations of the solution.',
)
@SectionId('MNTC')
@DetailedIn(D10QualityAcceptancePlan)
class MaintainabilityCharacteristic extends DocSpecsSection {
  @SectionId('MNTC-MAIN')
  @Form([
    Field(
      'maintainabilityApproach',
      String,
      'Maintainability Approach',
      hint: 'Modularity, analyzability, testability priorities',
    ),
    Field(
      'maintainabilityStandard',
      String,
      'Maintainability Standard',
      hint: 'Complexity thresholds, test-coverage targets',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? maintainabilityContent;

  /// Maintainability overview.
  @ContentHelp('Executive summary of maintainability goals and standards.')
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.8.1. Maintainability (product maintainability attributes).
  @SerializationOrder(2)
  Maintainability maintainability = Maintainability();
}

/// 11.3.1. Efficiency quality.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — performance efficiency represents the performance relative to the amount of resources used under stated conditions',
  ],
  'This section captures efficiency quality including response time, throughput, and resource targets.',
)
@SectionId('EFQU')
class Efficiency extends DocSpecsSection {
  @Form([
    // Response time
    Field(
      'responseTimeP50Target',
      String,
      'Response Time P50',
      hint: 'Median response time (e.g., <100ms)',
    ),
    Field(
      'responseTimeP95Target',
      String,
      'Response Time P95',
      hint: '95th percentile (e.g., <300ms)',
    ),
    Field(
      'responseTimeP99Target',
      String,
      'Response Time P99',
      hint: '99th percentile (e.g., <1s)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Throughput and scale targets.
  @SectionId('EFQUTH')
  @StandardReferences([
    'ISO/IEC 25010:2023 — capacity is the degree to which the maximum limits of a product or system parameter meet requirements',
    'ISO/IEC 25010:2023 — time behaviour is the degree to which response, processing times, and throughput rates meet requirements',
  ], 'This section captures throughput, capacity, and scalability targets.')
  @Form([
    Field(
      'throughputTarget',
      String,
      'Throughput Target',
      hint: 'Requests/second, transactions/minute',
    ),
    Field(
      'concurrentUsersTarget',
      String,
      'Concurrent Users Target',
      hint: 'Peak concurrent users supported',
    ),
    Field(
      'scalabilityModel',
      String,
      'Scalability Model',
      hint: 'Horizontal, vertical, auto-scaling',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? throughput;

  /// Resource utilization constraints.
  @SectionId('EFQURE')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — resource utilization is the degree to which the amounts and types of resources used by a product or system meet requirements',
    ],
    'This section captures resource utilization constraints for CPU, memory, storage, and network.',
  )
  @Form([
    Field(
      'cpuUtilizationLimit',
      String,
      'CPU Utilization Limit',
      hint: 'Max sustained CPU usage (e.g., <70%)',
    ),
    Field(
      'memoryUtilizationLimit',
      String,
      'Memory Utilization Limit',
      hint: 'Max memory usage',
    ),
    Field(
      'storageEfficiencyTarget',
      String,
      'Storage Efficiency Target',
      hint: 'Data storage per user/record',
    ),
    Field(
      'networkBandwidthLimit',
      String,
      'Network Bandwidth Limit',
      hint: 'Max bandwidth consumption',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? resources;

  /// Performance validation and SLA commitments.
  @SectionId('EFQUVE')
  @StandardReferences(
    [
      'ISO/IEC 25023:2016 — quality measures are defined and applied to quantify performance efficiency of the system and software product',
    ],
    'This section captures verification of performance efficiency through load testing and SLA commitments.',
  )
  @Form([
    Field(
      'loadTestingRequirement',
      String,
      'Load Testing Requirement',
      hint: 'Load test scenarios, thresholds',
    ),
    Field(
      'performanceProfilingApproach',
      String,
      'Performance Profiling',
      hint: 'APM tools, custom instrumentation',
    ),
    Field(
      'performanceBaselineDate',
      String,
      'Performance Baseline Date',
      hint: 'When baseline was established',
    ),
    Field(
      'performanceSlaDefinition',
      String,
      'Performance SLA Definition',
      hint: 'SLA for performance metrics',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? verification;

  /// Detailed efficiency requirements narrative.
  @SerializationOrder(4)
  TextSection narrative = TextSection();
}

/// 11.3.2. Portability quality.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — flexibility includes adaptability, installability, and replaceability, describing the degree to which a product can be transferred and adapted across environments',
  ],
  'This section captures portability quality across platforms and environments.',
)
@SectionId('POQU')
class Portability extends DocSpecsSection {
  @Form([
    // Platform support
    Field(
      'targetPlatforms',
      String,
      'Target Platforms',
      hint: 'iOS, Android, Web, Windows, macOS, Linux',
    ),
    Field(
      'browserSupport',
      String,
      'Browser Support',
      hint: 'Chrome, Firefox, Safari, Edge versions',
    ),
    Field(
      'mobileOsVersions',
      String,
      'Mobile OS Versions',
      hint: 'iOS 14+, Android 10+',
    ),
    Field(
      'desktopOsVersions',
      String,
      'Desktop OS Versions',
      hint: 'Windows 10+, macOS 11+',
    ),
    // Migration
    Field(
      'migrationEffortConstraint',
      String,
      'Migration Effort Constraint',
      hint: 'Max effort to migrate to new platform',
    ),
    Field(
      'dataPortability',
      String,
      'Data Portability',
      hint: 'Export formats, import capabilities',
    ),
    Field(
      'vendorLockInAvoidance',
      String,
      'Vendor Lock-in Avoidance',
      hint: 'Standards-based, abstraction layers',
    ),
    // Containerization
    Field(
      'containerizationRequirement',
      String,
      'Containerization',
      hint: 'Docker, Kubernetes requirements',
    ),
    Field(
      'infrastructureAsCode',
      String,
      'Infrastructure as Code',
      hint: 'Terraform, CloudFormation',
    ),
    // Verification
    Field(
      'portabilityVerification',
      String,
      'Portability Verification',
      hint: 'Cross-platform testing, compatibility matrix',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Detailed portability requirements narrative.
  @SerializationOrder(1)
  TextSection narrative = TextSection();
}

/// 11.3.3. Flexibility quality.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — flexibility is the degree to which a product can be adapted to changes in requirements, contexts of use, or system environments',
  ],
  'This section captures flexibility quality including component architecture and adaptability.',
)
@SectionId('FLQU')
class Flexibility extends DocSpecsSection {
  @Form([
    Field(
      'componentArchitecture',
      String,
      'Component Architecture',
      hint: 'Microservices, modular monolith, plugins',
    ),
    Field(
      'componentGranularity',
      String,
      'Component Granularity',
      hint: 'Fine-grained, coarse-grained',
    ),
    Field(
      'componentReplaceability',
      String,
      'Component Replaceability',
      hint: 'Hot-swap, restart required',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Modularity and reuse goals.
  @SectionId('FLQUMO')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — adaptability is the degree to which a product can effectively and efficiently be adapted for different or evolving hardware, software, or other operational or usage environments',
    ],
    'This section captures modularity and reuse goals supporting modifiability.',
  )
  @Form([
    Field(
      'modularityLevel',
      String,
      'Modularity Level',
      hint: 'Highly modular, moderately, monolithic',
    ),
    Field(
      'moduleIndependence',
      String,
      'Module Independence',
      hint: 'Loose coupling, shared libraries',
    ),
    Field(
      'moduleReusability',
      String,
      'Module Reusability',
      hint: 'Design for reuse, single-purpose',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? modularity;

  /// Distribution and configurability model.
  @SectionId('FLQUDE')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — installability is the degree of effectiveness and efficiency with which a product can be successfully installed or uninstalled in a specified environment',
    ],
    'This section captures deployment, distribution, and installability characteristics.',
  )
  @Form([
    Field(
      'distributionCapability',
      String,
      'Distribution Capability',
      hint: 'Multi-region, single-region, on-premise',
    ),
    Field(
      'multiTenancy',
      String,
      'Multi-Tenancy',
      hint: 'Shared, isolated, hybrid',
    ),
    Field(
      'configurabilityLevel',
      String,
      'Configurability Level',
      hint: 'Feature flags, runtime config, deploy-time',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? deployment;

  /// Extensibility and verification expectations.
  @SectionId('FLQUEX')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — adaptability is the degree to which a product can effectively and efficiently be adapted or extended for evolving requirements and environments',
    ],
    'This section captures extensibility expectations and how flexibility is verified.',
  )
  @Form([
    Field(
      'extensibilityModel',
      String,
      'Extensibility Model',
      hint: 'Plugins, APIs, webhooks',
    ),
    Field(
      'customizationScope',
      String,
      'Customization Scope',
      hint: 'UI, business rules, workflows',
    ),
    Field(
      'flexibilityVerification',
      String,
      'Flexibility Verification',
      hint: 'Architecture review, change impact analysis',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? extensibility;

  /// Detailed flexibility requirements narrative.
  @SerializationOrder(4)
  TextSection narrative = TextSection();
}

/// 11.3.4. Security quality.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — security is the degree to which a product or system protects information and data so that persons or other products have the degree of data access appropriate to their types and levels of authorization',
  ],
  'This section captures the core security quality expectations of the solution.',
)
@SectionId('SEQU')
class Security extends DocSpecsSection {
  @Form([
    Field(
      'encryptionAtRest',
      String,
      'Encryption at Rest',
      hint: 'AES-256, database-level, disk-level',
    ),
    Field(
      'encryptionInTransit',
      String,
      'Encryption in Transit',
      hint: 'TLS 1.2+, certificate requirements',
    ),
    Field(
      'keyManagement',
      String,
      'Key Management',
      hint: 'HSM, KMS, key rotation policy',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Authentication controls.
  @SectionId('SEQUAU')
  @StandardReferences([
    'ISO/IEC 25010:2023 — authenticity is the degree to which the identity of a subject or resource can be proved to be the one claimed',
  ], 'This section captures authentication controls and proof of identity.')
  @Form([
    Field(
      'authenticationMethod',
      String,
      'Authentication Method',
      hint: 'OAuth2, SAML, OIDC, MFA',
    ),
    Field(
      'mfaRequirement',
      String,
      'MFA Requirement',
      hint: 'All users, privileged users, optional',
    ),
    Field(
      'passwordPolicy',
      String,
      'Password Policy',
      hint: 'Complexity, rotation, history',
    ),
    Field(
      'sessionManagement',
      String,
      'Session Management',
      hint: 'Timeout, concurrent sessions',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? authentication;

  /// Authorization controls.
  @SectionId('SEQUA1')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — confidentiality is the degree to which a product ensures that data are accessible only to those authorized to have access',
    ],
    'This section captures authorization controls and confidentiality of access.',
  )
  @Form([
    Field(
      'authorizationModel',
      String,
      'Authorization Model',
      hint: 'RBAC, ABAC, ACL',
    ),
    Field(
      'authorizationCoverage',
      String,
      'Authorization Coverage',
      hint: 'All resources, sensitive resources',
    ),
    Field(
      'privilegeEscalationPrevention',
      String,
      'Privilege Escalation',
      hint: 'Controls to prevent escalation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? authorization;

  /// Vulnerability management expectations.
  @SectionId('SEQUVU')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — resistance is the degree to which the product sustains operations while under attack from a malicious actor',
    ],
    'This section captures vulnerability management and resistance expectations.',
  )
  @Form([
    Field(
      'vulnerabilityScanFrequency',
      String,
      'Vulnerability Scan Frequency',
      hint: 'Continuous, weekly, per-release',
    ),
    Field(
      'penetrationTestFrequency',
      String,
      'Penetration Test Frequency',
      hint: 'Annual, semi-annual, per-release',
    ),
    Field(
      'cveResponseTime',
      String,
      'CVE Response Time',
      hint: 'Critical: 24h, high: 7d',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? vulnerability;

  /// Compliance and verification settings.
  @SectionId('SEQUCO')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — accountability is the degree to which the actions of an entity can be traced uniquely to the entity',
      'ISO/IEC 27001:2022 — an information security management system establishes controls to meet security requirements',
    ],
    'This section captures security compliance, accountability, and verification settings.',
  )
  @Form([
    Field(
      'securityCompliance',
      String,
      'Security Compliance',
      hint: 'SOC2, ISO 27001, GDPR',
    ),
    Field(
      'securityCertifications',
      String,
      'Security Certifications',
      hint: 'Required certifications',
    ),
    Field(
      'securityAuditFrequency',
      String,
      'Security Audit Frequency',
      hint: 'Annual, continuous',
    ),
    Field(
      'securityVerification',
      String,
      'Security Verification',
      hint: 'SAST, DAST, security review',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? compliance;

  /// Detailed security requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// 11.3.5. Maintainability quality.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — maintainability is the degree of effectiveness and efficiency with which a product or system can be modified to correct, improve, extend, or adapt it',
  ],
  'This section captures the core maintainability quality expectations of the solution.',
)
@SectionId('MAQU')
class Maintainability extends DocSpecsSection {
  @Form([
    Field(
      'adaptabilityTarget',
      String,
      'Adaptability Target',
      hint: 'Change implementation time',
    ),
    Field(
      'changeImpactLimit',
      String,
      'Change Impact Limit',
      hint: 'Max components affected by change',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Analyzability requirements.
  @SectionId('MAQUAN')
  @StandardReferences([
    'ISO/IEC 25010:2023 — analysability is the degree of effectiveness and efficiency with which it is possible to assess the impact of an intended change, to diagnose deficiencies or causes of failures, or to identify parts to be modified',
  ], 'This section captures analyzability requirements for the solution.')
  @Form([
    Field(
      'codeReadabilityStandard',
      String,
      'Code Readability Standard',
      hint: 'Style guide, code review criteria',
    ),
    Field(
      'documentationRequirement',
      String,
      'Documentation Requirement',
      hint: 'Inline, API docs, architecture docs',
    ),
    Field(
      'loggingStandard',
      String,
      'Logging Standard',
      hint: 'Structured logging, log levels',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? analyzability;

  /// Changeability requirements.
  @SectionId('MAQUCH')
  @StandardReferences([
    'ISO/IEC 25010:2023 — modifiability is the degree to which a product can be effectively and efficiently modified without introducing defects or degrading existing product quality',
  ], 'This section captures changeability and modifiability requirements.')
  @Form([
    Field(
      'codeCoverageMinimum',
      String,
      'Code Coverage Minimum',
      hint: 'Unit test coverage % target',
    ),
    Field(
      'cyclomaticComplexityLimit',
      String,
      'Cyclomatic Complexity Limit',
      hint: 'Max complexity per function',
    ),
    Field(
      'methodLengthLimit',
      String,
      'Method Length Limit',
      hint: 'Max lines per method',
    ),
    Field(
      'classLengthLimit',
      String,
      'Class Length Limit',
      hint: 'Max lines per class',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? changeability;

  /// Testability requirements.
  @SectionId('MAQUTE')
  @StandardReferences([
    'ISO/IEC 25010:2023 — testability is the degree of effectiveness and efficiency with which test criteria can be established for a system and tests performed to determine whether those criteria have been met',
  ], 'This section captures testability requirements for the solution.')
  @Form([
    Field(
      'testabilityDesign',
      String,
      'Testability Design',
      hint: 'Dependency injection, mocking support',
    ),
    Field(
      'testPyramidRatio',
      String,
      'Test Pyramid Ratio',
      hint: 'Unit:Integration:E2E ratio',
    ),
    Field(
      'testDataManagement',
      String,
      'Test Data Management',
      hint: 'Fixtures, factories, production-like',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testability;

  /// Extensibility and verification requirements.
  @SectionId('MAQUGO')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — modularity is the degree to which a system is composed of discrete components such that a change to one component has minimal impact on other components',
    ],
    'This section captures maintainability governance through modularity and extensibility.',
  )
  @Form([
    Field(
      'extensibilityPattern',
      String,
      'Extensibility Pattern',
      hint: 'Plugin architecture, middleware, hooks',
    ),
    Field(
      'apiVersioningStrategy',
      String,
      'API Versioning Strategy',
      hint: 'URL path, header, query param',
    ),
    Field(
      'maintainabilityVerification',
      String,
      'Maintainability Verification',
      hint: 'Static analysis, architecture fitness functions',
    ),
    Field(
      'technicalDebtTracking',
      String,
      'Technical Debt Tracking',
      hint: 'SonarQube, manual tracking',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? governance;

  /// Detailed maintainability requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// 11.3.6. Reliability quality.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — reliability is the degree to which a system, product, or component performs specified functions under specified conditions for a specified period of time',
  ],
  'This section captures the core reliability quality expectations of the solution.',
)
@SectionId('REQU')
class Reliability extends DocSpecsSection {
  @Form([
    Field(
      'uptimeTarget',
      String,
      'Uptime Target',
      hint: '99.9%, 99.95%, 99.99%',
    ),
    Field(
      'plannedDowntimeWindow',
      String,
      'Planned Downtime Window',
      hint: 'Maintenance window schedule',
    ),
    Field(
      'degradedModeCapability',
      String,
      'Degraded Mode Capability',
      hint: 'Graceful degradation approach',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Recovery objectives.
  @SectionId('REQURE')
  @StandardReferences([
    'ISO/IEC 25010:2023 — recoverability is the degree to which, in the event of an interruption or a failure, a product can recover the data directly affected and re-establish the desired state of the system',
  ], 'This section captures recovery objectives and recoverability targets.')
  @Form([
    Field(
      'mtbfTarget',
      String,
      'MTBF Target',
      hint: 'Mean time between failures',
    ),
    Field('mttrTarget', String, 'MTTR Target', hint: 'Mean time to recovery'),
    Field('rtoTarget', String, 'RTO Target', hint: 'Recovery time objective'),
    Field('rpoTarget', String, 'RPO Target', hint: 'Recovery point objective'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? recovery;

  /// Failover requirements.
  @SectionId('REQUFA')
  @StandardReferences([
    'ISO/IEC 25010:2023 — fault tolerance is the degree to which a system, product, or component operates as intended despite the presence of hardware or software faults',
  ], 'This section captures failover and fault tolerance requirements.')
  @Form([
    Field(
      'failoverStrategy',
      String,
      'Failover Strategy',
      hint: 'Active-passive, active-active',
    ),
    Field(
      'failoverTime',
      String,
      'Failover Time',
      hint: 'Time to complete failover',
    ),
    Field(
      'failoverTesting',
      String,
      'Failover Testing',
      hint: 'Chaos engineering, DR drills',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? failover;

  /// Data durability requirements.
  @SectionId('REQUDU')
  @StandardReferences([
    'ISO/IEC 25010:2023 — faultlessness is the degree to which a system, product, or component performs specified functions without fault under normal operation',
  ], 'This section captures data durability and faultlessness expectations.')
  @Form([
    Field(
      'dataDurability',
      String,
      'Data Durability',
      hint: '99.999999999% (11 nines)',
    ),
    Field(
      'backupFrequency',
      String,
      'Backup Frequency',
      hint: 'Continuous, hourly, daily',
    ),
    Field(
      'backupRetention',
      String,
      'Backup Retention',
      hint: 'Retention period',
    ),
    Field(
      'backupVerification',
      String,
      'Backup Verification',
      hint: 'Restore testing frequency',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? durability;

  /// Verification and learning.
  @SectionId('REQUVE')
  @StandardReferences(
    [
      'ISO/IEC 25023:2016 — quality measures are defined and applied to quantify the reliability characteristics of the system and software product',
    ],
    'This section captures how reliability is verified and how learning is fed back.',
  )
  @Form([
    Field(
      'reliabilityVerification',
      String,
      'Reliability Verification',
      hint: 'Soak testing, chaos engineering',
    ),
    Field(
      'incidentPostmortem',
      String,
      'Incident Postmortem',
      hint: 'Blameless postmortem process',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? verification;

  /// Detailed reliability requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// 11.6. Reliability (ISO/IEC 25010:2023).
///
/// Degree to which the product performs specified functions under specified
/// conditions for a specified period (availability, fault tolerance,
/// recoverability, maturity). Re-homes the former technical-bucket reliability
/// leaf and the operations-bucket availability, service-level and monitoring
/// leaves under the 25010:2023 spine (L34C-8). The dissolved operations-quality
/// overview form is preserved here so no authored content is lost.
@StandardReferences([
  'ISO/IEC 25010:2023 — reliability is the degree to which a system performs specified functions under specified conditions for a specified period of time',
], 'This section describes the reliability characteristic of the solution.')
@SectionId('RELC')
@DetailedIn(D10QualityAcceptancePlan)
class ReliabilityCharacteristic extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Reliability Overview (migrated from the former operations bucket)
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('RELC-RELI')
  @Form([
    Field(
      'operationsMaturityModel',
      String,
      'Operations Maturity Model',
      hint: 'ITIL, DevOps, SRE',
    ),
    Field(
      'operationsPhilosophy',
      String,
      'Operations Philosophy',
      hint: 'Ops-driven, DevOps, NoOps',
    ),
    Field(
      'operationsResponsibility',
      String,
      'Operations Responsibility',
      hint: 'Dedicated team, shared, outsourced',
    ),
    Field(
      'incidentManagementProcess',
      String,
      'Incident Management Process',
      hint: 'PagerDuty, custom, ITIL-based',
    ),
    Field(
      'changeManagementProcess',
      String,
      'Change Management Process',
      hint: 'ITIL change management, lightweight',
    ),
    Field(
      'operationsToolchain',
      String,
      'Operations Toolchain',
      hint: 'Key ops tools and platforms',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? reliabilityContent;

  /// Reliability overview narrative.
  @ContentHelp(
    'Executive summary of reliability and operational requirements, '
    'support model, and key operational metrics.',
  )
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.6.1. Reliability (product reliability attributes).
  @SerializationOrder(2)
  Reliability reliability = Reliability();

  /// 11.6.2. Availability.
  @SerializationOrder(3)
  Availability availability = Availability();

  /// 11.6.3. Service Level Requirements.
  @SerializationOrder(4)
  ServiceLevel serviceLevelRequirements = ServiceLevel();

  /// 11.6.4. Monitoring and Prevention.
  @SerializationOrder(5)
  OperationalMonitoring monitoringAndPrevention = OperationalMonitoring();
}

/// 11.4.1. Availability quality.
@StandardReferences([
  'ISO/IEC 25010:2023 — availability is the degree to which a system is operational and accessible when required for use',
], 'This section describes the availability quality of the solution.')
@SectionId('AVQU')
class Availability extends DocSpecsSection {
  @Form([
    Field(
      'uptimeTargetPercentage',
      String,
      'Uptime Target %',
      hint: '99.9% (8.76h/year downtime)',
    ),
    Field(
      'uptimeCalculationMethod',
      String,
      'Uptime Calculation Method',
      hint: 'Excluding planned, including all',
    ),
    Field(
      'uptimeMeasurementPeriod',
      String,
      'Measurement Period',
      hint: 'Monthly, quarterly, annually',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Operating-hour expectations.
  @SectionId('AQOH')
  @StandardReferences([
    'ISO/IEC 25010:2023 — availability is specified over the operating hours during which the system must be accessible',
  ], 'This section describes the operating-hour expectations for availability.')
  @Form([
    Field(
      'operatingHours',
      String,
      'Operating Hours',
      hint: '24/7, business hours, regional',
    ),
    Field(
      'peakHoursDefinition',
      String,
      'Peak Hours Definition',
      hint: 'When peak hours apply',
    ),
    Field(
      'peakHoursAvailability',
      String,
      'Peak Hours Availability',
      hint: 'Higher availability during peaks',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? operatingHoursDetails;

  /// Maintenance window policy.
  @SectionId('AVQUMA')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — availability accounts for planned maintenance windows during which the system may be unavailable',
    ],
    'This section describes the maintenance window policy affecting availability.',
  )
  @Form([
    Field(
      'scheduledMaintenanceWindow',
      String,
      'Scheduled Maintenance Window',
      hint: 'When maintenance can occur',
    ),
    Field(
      'maintenanceNotification',
      String,
      'Maintenance Notification',
      hint: 'How users are notified',
    ),
    Field(
      'maintenanceFrequency',
      String,
      'Maintenance Frequency',
      hint: 'Weekly, monthly, quarterly',
    ),
    Field(
      'maintenanceDurationLimit',
      String,
      'Maintenance Duration Limit',
      hint: 'Max duration per window',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? maintenance;

  /// Degraded-mode behavior.
  @SectionId('AQDM')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — fault tolerance is the degree to which a system operates as intended despite the presence of faults, including in a degraded mode',
    ],
    'This section describes degraded-mode behavior when the system operates with reduced capability.',
  )
  @Form([
    Field(
      'degradedModeDefinition',
      String,
      'Degraded Mode Definition',
      hint: 'What constitutes degraded mode',
    ),
    Field(
      'degradedModeCapabilities',
      String,
      'Degraded Mode Capabilities',
      hint: 'Features available in degraded mode',
    ),
    Field(
      'degradedModeCommunication',
      String,
      'Degraded Mode Communication',
      hint: 'How users are informed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? degradedMode;

  /// Monitoring and reporting.
  @SectionId('AVQUVE')
  @StandardReferences(
    [
      'ISO/IEC 25023:2016 — quality measures quantify availability so that targets can be verified',
    ],
    'This section describes monitoring and reporting used to verify availability.',
  )
  @Form([
    Field(
      'availabilityMonitoring',
      String,
      'Availability Monitoring',
      hint: 'Synthetic monitoring, real user',
    ),
    Field(
      'availabilityReporting',
      String,
      'Availability Reporting',
      hint: 'Dashboard, reports, SLA tracking',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? verification;

  /// Detailed availability requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// 11.4.2. Service level quality.
@StandardReferences([
  'ISO/IEC 20000-1:2018 — agreed service levels define the service targets that the provider commits to deliver',
], 'This section describes the service level quality of the solution.')
@SectionId('SELEQU')
class ServiceLevel extends DocSpecsSection {
  @Form([
    Field(
      'supportTierStructure',
      String,
      'Support Tier Structure',
      hint: 'L1/L2/L3, single tier',
    ),
    Field(
      'criticalResponseTime',
      String,
      'Critical Response Time',
      hint: 'Response time for P1 issues',
    ),
    Field(
      'highResponseTime',
      String,
      'High Response Time',
      hint: 'Response time for P2 issues',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Remaining response targets.
  @SectionId('SLQR')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — response-time targets are set and monitored as part of service level management',
    ],
    'This section describes remaining response-time targets for service levels.',
  )
  @Form([
    Field(
      'mediumResponseTime',
      String,
      'Medium Response Time',
      hint: 'Response time for P3 issues',
    ),
    Field(
      'lowResponseTime',
      String,
      'Low Response Time',
      hint: 'Response time for P4 issues',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? response;

  /// Resolution targets.
  @SectionId('SLQR1')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — resolution-time targets are set and monitored for service requests and incidents',
    ],
    'This section describes resolution-time targets for service requests and incidents.',
  )
  @Form([
    Field(
      'criticalResolutionTime',
      String,
      'Critical Resolution Time',
      hint: 'Resolution target for P1',
    ),
    Field(
      'highResolutionTime',
      String,
      'High Resolution Time',
      hint: 'Resolution target for P2',
    ),
    Field(
      'mediumResolutionTime',
      String,
      'Medium Resolution Time',
      hint: 'Resolution target for P3',
    ),
    Field(
      'lowResolutionTime',
      String,
      'Low Resolution Time',
      hint: 'Resolution target for P4',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? resolution;

  /// Escalation rules.
  @SectionId('SLQE')
  @StandardReferences([
    'ISO/IEC 20000-1:2018 — escalation procedures are defined so unmet targets are raised in a timely way',
  ], 'This section describes escalation rules for service level management.')
  @Form([
    Field(
      'escalationTimeframes',
      String,
      'Escalation Timeframes',
      hint: 'When issues escalate',
    ),
    Field(
      'escalationContacts',
      String,
      'Escalation Contacts',
      hint: 'Who to escalate to',
    ),
    Field(
      'executiveEscalation',
      String,
      'Executive Escalation',
      hint: 'When executive escalation occurs',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? escalation;

  /// On-call support expectations.
  @SectionId('SLQOC')
  @StandardReferences([
    'ISO/IEC 20000-1:2018 — on-call and support-coverage arrangements underpin the agreed service levels',
  ], 'This section describes on-call and support-coverage expectations.')
  @Form([
    Field(
      'onCallCoverage',
      String,
      'On-Call Coverage',
      hint: '24/7, business hours, regional',
    ),
    Field(
      'onCallRotation',
      String,
      'On-Call Rotation',
      hint: 'Weekly, bi-weekly',
    ),
    Field(
      'onCallCompensation',
      String,
      'On-Call Compensation',
      hint: 'Compensation model',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? onCall;

  /// Restoration and communication priorities.
  @SectionId('SLQR2')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — recoverability re-establishes service and restores data after an interruption or failure',
    ],
    'This section describes restoration and communication priorities during service outages.',
  )
  @Form([
    Field(
      'serviceRestorationPriority',
      String,
      'Service Restoration Priority',
      hint: 'Order of restoration',
    ),
    Field(
      'communicationDuringOutage',
      String,
      'Communication During Outage',
      hint: 'Status page, email, SMS',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? restoration;

  /// Detailed service level requirements narrative.
  @SerializationOrder(6)
  TextSection narrative = TextSection();

  /// Service Level Agreement entries.
  @StandardReferences([
    'ISO/IEC 20000-1:2018 — service level agreements record the agreed targets between provider and customer',
  ], 'This list holds the service level agreement entries for the solution.')
  @SectionId('SLAE-SLAE-LST')
  @SectionIdPattern('SLAE-SLAE-xxx')
  @ContentHelp('Add one entry per service level agreement.')
  @SerializationOrder(7)
  List<ServiceLevelAgreementEntry> slaEntries = [];
}

/// A service level agreement entry.
@StandardReferences([
  'ISO/IEC 20000-1:2018 — each service level agreement entry records an agreed target and how it is measured',
], 'This section describes a single service level agreement entry.')
@SectionId('SLAE')
class ServiceLevelAgreementEntry extends DocSpecsSection {
  @Form([
    Field('slaId', String, 'SLA ID', hint: 'SLA-001, unique identifier'),
    Field(
      'slaName',
      String,
      'SLA Name',
      hint: 'Uptime SLA, Response Time SLA',
      required: true,
    ),
    Field(
      'slaDescription',
      String,
      'Description',
      hint: 'What this SLA covers',
    ),
    Field('slaMetric', String, 'Metric', hint: 'What is measured'),
    Field('slaTarget', String, 'Target', hint: 'Target value'),
    Field(
      'slaMeasurementMethod',
      String,
      'Measurement Method',
      hint: 'How the metric is measured',
    ),
    Field(
      'slaReportingFrequency',
      String,
      'Reporting Frequency',
      hint: 'Monthly, quarterly',
    ),
    Field('slaPenalty', String, 'Penalty', hint: 'Consequence of missing SLA'),
    Field(
      'slaExclusions',
      String,
      'Exclusions',
      hint: 'What is excluded from SLA',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 11.4.3. Monitoring quality.
@StandardReferences([
  'ISO/IEC 25010:2023 — availability and reliability in operation are sustained through monitoring of the running system',
], 'This section describes operational monitoring quality of the solution.')
@SectionId('MOQU')
class OperationalMonitoring extends DocSpecsSection {
  @Form([
    Field(
      'scalabilityMonitoringApproach',
      String,
      'Scalability Monitoring',
      hint: 'Auto-scaling triggers, capacity alerts',
    ),
    Field(
      'capacityPlanningProcess',
      String,
      'Capacity Planning Process',
      hint: 'How capacity is planned',
    ),
    Field(
      'growthProjections',
      String,
      'Growth Projections',
      hint: 'Expected growth rate',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Component monitoring coverage.
  @SectionId('MOQUCO')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — monitoring coverage is defined so the health of services and components is observed',
    ],
    'This section describes the component and infrastructure coverage of monitoring.',
  )
  @Form([
    Field(
      'infrastructureMonitoring',
      String,
      'Infrastructure Monitoring',
      hint: 'Servers, containers, network',
    ),
    Field(
      'applicationMonitoring',
      String,
      'Application Monitoring',
      hint: 'APM, logs, traces',
    ),
    Field(
      'databaseMonitoring',
      String,
      'Database Monitoring',
      hint: 'Queries, connections, storage',
    ),
    Field(
      'thirdPartyMonitoring',
      String,
      'Third-Party Monitoring',
      hint: 'External service monitoring',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? coverage;

  /// Alert automation capabilities.
  @SectionId('MOQUAU')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — monitoring is automated so conditions are detected without manual inspection',
    ],
    'This section describes alert automation and self-healing capabilities for monitoring.',
  )
  @Form([
    Field(
      'alertAutomation',
      String,
      'Alert Automation',
      hint: 'Automated response to alerts',
    ),
    Field(
      'selfHealingCapability',
      String,
      'Self-Healing Capability',
      hint: 'Auto-recovery mechanisms',
    ),
    Field(
      'runbookAutomation',
      String,
      'Runbook Automation',
      hint: 'Automated runbook execution',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? automation;

  /// Alerting strategy and channels.
  @SectionId('MOQUAL')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — alerting notifies responsible parties when monitored thresholds are breached',
    ],
    'This section describes the alerting strategy and notification channels for monitoring.',
  )
  @Form([
    Field(
      'alertingStrategy',
      String,
      'Alerting Strategy',
      hint: 'Threshold-based, anomaly detection',
    ),
    Field(
      'alertPrioritization',
      String,
      'Alert Prioritization',
      hint: 'How alerts are prioritized',
    ),
    Field(
      'alertNotificationChannels',
      String,
      'Notification Channels',
      hint: 'Slack, PagerDuty, email, SMS',
    ),
    Field(
      'alertFatiguePrevention',
      String,
      'Alert Fatigue Prevention',
      hint: 'De-duplication, correlation',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? alerting;

  /// Planning and observability settings.
  @SectionId('MOQUOP')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — operational monitoring feeds the day-to-day running and support of the service',
    ],
    'This section describes planning and observability settings for operational monitoring.',
  )
  @Form([
    Field(
      'resourcePlanningFrequency',
      String,
      'Resource Planning Frequency',
      hint: 'Quarterly, annually',
    ),
    Field(
      'proactiveMaintenanceSchedule',
      String,
      'Proactive Maintenance',
      hint: 'Scheduled maintenance activities',
    ),
    Field(
      'observabilityPillars',
      String,
      'Observability Pillars',
      hint: 'Logs, metrics, traces',
    ),
    Field(
      'distributedTracingRequirement',
      String,
      'Distributed Tracing',
      hint: 'Tracing implementation',
    ),
    Field(
      'logRetentionPeriod',
      String,
      'Log Retention Period',
      hint: 'How long logs are kept',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? operations;

  /// Detailed monitoring requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// 11.4.4. IT Security Operations quality.
@StandardReferences([
  'ISO/IEC 27001:2022 — information-security controls are operated so confidentiality, integrity, and availability are protected in production',
  'ISO/IEC 25010:2023 — the security and reliability of a product in operation depend on disciplined security operations',
], 'This section describes the IT security operations quality of the solution.')
@SectionId('ISOQ')
class ItSecurityOperations extends DocSpecsSection {
  @Form([
    Field(
      'accessControlModel',
      String,
      'Access Control Model',
      hint: 'RBAC, ABAC, zero-trust',
    ),
    Field(
      'drPlanRequired',
      bool,
      'DR Plan Required',
      hint: 'Whether a disaster recovery plan is required',
    ),
    Field(
      'incidentResponsePlan',
      String,
      'Incident Response Plan',
      hint: 'NIST, custom',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Access protection controls.
  @SectionId('ISOQA')
  @StandardReferences([
    'ISO/IEC 27001:2022 — access to information and systems is restricted so only authorised parties gain entry',
  ], 'This section defines access protection controls.')
  @Form([
    Field(
      'privilegedAccessManagement',
      String,
      'Privileged Access Management',
      hint: 'PAM solution, just-in-time',
    ),
    Field(
      'accessReviewFrequency',
      String,
      'Access Review Frequency',
      hint: 'Quarterly, annually',
    ),
    Field(
      'accessAuditLogging',
      String,
      'Access Audit Logging',
      hint: 'What access is logged',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? access;

  /// Disaster recovery planning details.
  @SectionId('ISOQR')
  @StandardReferences([
    'ISO/IEC 25010:2023 — recoverability re-establishes the desired state after a security incident or failure',
    'ISO/IEC 27031:2011 — ICT readiness supports continuity and recovery of operations after disruption',
  ], 'This section describes disaster recovery planning details.')
  @Form([
    Field(
      'drTestingFrequency',
      String,
      'DR Testing Frequency',
      hint: 'Annual, semi-annual',
    ),
    Field(
      'drRecoveryTargets',
      String,
      'DR Recovery Targets',
      hint: 'RTO/RPO for DR scenarios',
    ),
    Field(
      'drDataCenterStrategy',
      String,
      'Data Center Strategy',
      hint: 'Multi-region, hot/warm/cold',
    ),
    Field(
      'drCommunicationPlan',
      String,
      'DR Communication Plan',
      hint: 'How stakeholders are notified',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? recovery;

  /// Penetration testing and remediation.
  @SectionId('ISOQT')
  @StandardReferences([
    'ISO/IEC 27001:2022 — security controls are tested and evaluated so their effectiveness is confirmed',
  ], 'This section covers penetration testing and remediation of findings.')
  @Form([
    Field(
      'penetrationTestScope',
      String,
      'Penetration Test Scope',
      hint: 'Internal, external, both',
    ),
    Field(
      'penetrationTestFrequency',
      String,
      'Penetration Test Frequency',
      hint: 'Annual, per-release',
    ),
    Field(
      'vulnerabilitySlaResolution',
      String,
      'Vulnerability SLA',
      hint: 'Resolution timeframes by severity',
    ),
    Field(
      'bugBountyProgram',
      bool,
      'Bug Bounty Program',
      hint: 'Whether a bug bounty program is in place',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testing;

  /// Incident handling and reporting.
  @SectionId('ISOQI')
  @StandardReferences([
    'ISO/IEC 27035-1:2023 — information-security incidents are detected, reported, and responded to in a managed way',
  ], 'This section captures how security incidents are handled and reported.')
  @Form([
    Field(
      'securityIncidentClassification',
      String,
      'Incident Classification',
      hint: 'Severity levels',
    ),
    Field(
      'securityIncidentNotification',
      String,
      'Incident Notification',
      hint: 'Who is notified, when',
    ),
    Field(
      'forensicsCapability',
      String,
      'Forensics Capability',
      hint: 'Evidence preservation',
    ),
    Field(
      'regulatoryReporting',
      String,
      'Regulatory Reporting',
      hint: 'Breach notification requirements',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? incident;

  /// Detailed IT security operations narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// 11.10. Documentation Quality (ISO/IEC 26514 annex).
///
/// Documentation-deliverable quality criteria — readability, completeness,
/// correctness, and changeability of the user/technical documentation. This
/// characteristic has no home in the ISO/IEC 25010:2023 product-quality model
/// (which scopes the *product*, not its documentation), so per L34C-8 it is
/// retained as a documentation-quality annex aligned to ISO/IEC 26514
/// (systems & software engineering — design and development of information for
/// users) rather than re-homed under a 25010:2023 characteristic.
@StandardReferences(
  [
    'ISO/IEC 26514:2008 — information for users is designed and developed to defined quality criteria covering completeness, accuracy, and usability',
    'ISO/IEC/IEEE 26515:2018 — information for users is planned and produced iteratively alongside the product',
  ],
  'Captures the overall quality criteria governing user and technical documentation.',
)
@SectionId('DOQUCR')
@DetailedIn(D10QualityAcceptancePlan)
class DocumentationQualityCriteria extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Documentation Quality Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('DOQUCR-DOCU')
  @Form([
    Field(
      'documentationStrategy',
      String,
      'Documentation Strategy',
      hint: 'Comprehensive, minimal, just-in-time',
    ),
    Field(
      'documentationOwnership',
      String,
      'Documentation Ownership',
      hint: 'Technical writers, developers, shared',
    ),
    Field(
      'documentationPlatform',
      String,
      'Documentation Platform',
      hint: 'Confluence, GitBook, custom',
    ),
    Field(
      'documentationReviewProcess',
      String,
      'Review Process',
      hint: 'Peer review, editorial review',
    ),
    Field(
      'documentationVersionControl',
      String,
      'Version Control',
      hint: 'Git, CMS versioning, manual',
    ),
    Field(
      'documentationUpdateCadence',
      String,
      'Update Cadence',
      hint: 'Continuous, per-release, scheduled',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? documentationOverviewContent;

  /// Documentation quality overview narrative.
  @ContentHelp(
    'Executive summary of documentation goals, '
    'target audiences, and key documentation metrics.',
  )
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.5.1. Readability.
  @SerializationOrder(2)
  Readability readability = Readability();

  /// 11.5.2. Completeness.
  @SerializationOrder(3)
  DocCompleteness completeness = DocCompleteness();

  /// 11.5.3. Correctness.
  @SerializationOrder(4)
  DocCorrectness correctness = DocCorrectness();

  /// 11.5.4. Changeability.
  @SerializationOrder(5)
  DocChangeability changeability = DocChangeability();
}

/// 11.5.1. Readability quality.
@StandardReferences([
  'ISO/IEC 26514:2008 — information for users is written so that it can be read and understood by the intended audience',
], 'Captures readability requirements for user documentation.')
@SectionId('REQU1')
class Readability extends DocSpecsSection {
  @Form([
    Field(
      'terminologyStandard',
      String,
      'Terminology Standard',
      hint: 'Glossary, controlled vocabulary',
    ),
    Field(
      'ambiguityPrevention',
      String,
      'Ambiguity Prevention',
      hint: 'Review checklist, automated checks',
    ),
    Field(
      'jargonPolicy',
      String,
      'Jargon Policy',
      hint: 'Define all terms, minimize jargon',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Identifiability and navigation.
  @SectionId('REQUNA')
  @StandardReferences(
    [
      'ISO/IEC 26514:2008 — information is structured with navigation aids so that users can locate relevant topics',
    ],
    'Captures identifiability and navigation aids that help users locate topics.',
  )
  @Form([
    Field(
      'sectionNumbering',
      String,
      'Section Numbering',
      hint: 'Hierarchical, flat, none',
    ),
    Field(
      'crossReferenceStandard',
      String,
      'Cross-Reference Standard',
      hint: 'Section IDs, hyperlinks',
    ),
    Field(
      'searchability',
      String,
      'Searchability',
      hint: 'Full-text search, tagged',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? navigation;

  /// Comprehensibility requirements.
  @SectionId('REQUCO')
  @StandardReferences(
    [
      'ISO/IEC 26514:2008 — content is presented at a reading level and in a format appropriate to the intended user',
    ],
    'Captures reading level and format requirements for comprehensible documentation.',
  )
  @Form([
    Field(
      'readingLevelTarget',
      String,
      'Reading Level Target',
      hint: 'Grade level, technical audience',
    ),
    Field(
      'formatStandards',
      String,
      'Format Standards',
      hint: 'Headings, lists, tables usage',
    ),
    Field(
      'visualAidRequirements',
      String,
      'Visual Aid Requirements',
      hint: 'Diagrams, screenshots, examples',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? comprehensibility;

  /// Document structure rules.
  @SectionId('REQUST')
  @StandardReferences(
    [
      'ISO/IEC 26514:2008 — information is organised into a consistent structure with a defined information hierarchy',
    ],
    'Captures the structural template and information hierarchy for documentation.',
  )
  @Form([
    Field(
      'documentStructureTemplate',
      String,
      'Structure Template',
      hint: 'Standard document templates',
    ),
    Field(
      'informationHierarchy',
      String,
      'Information Hierarchy',
      hint: 'How information is organized',
    ),
    Field(
      'navigationAids',
      String,
      'Navigation Aids',
      hint: 'TOC, index, breadcrumbs',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? structure;

  /// Style guide alignment.
  @SectionId('REQUS1')
  @StandardReferences([
    'ISO/IEC 26514:2008 — a documented style guide governs terminology, writing voice, and formatting conventions',
  ], 'Captures alignment of documentation with a defined style guide.')
  @Form([
    Field(
      'styleGuideReference',
      String,
      'Style Guide Reference',
      hint: 'Google, Microsoft, custom',
    ),
    Field(
      'writingVoice',
      String,
      'Writing Voice',
      hint: 'Active, passive, imperative',
    ),
    Field(
      'formattingConventions',
      String,
      'Formatting Conventions',
      hint: 'Code, commands, UI elements',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? style;

  /// Detailed readability requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// 11.5.2. Documentation completeness quality.
@StandardReferences([
  'ISO/IEC 26514:2008 — the information covers all tasks and topics that the intended users need to use the product',
], 'Captures whether documentation covers all tasks and topics users need.')
@SectionId('DOCOQU')
class DocCompleteness extends DocSpecsSection {
  @Form([
    // Topic coverage
    Field(
      'requiredTopics',
      String,
      'Required Topics',
      hint: 'List of required documentation topics',
    ),
    Field(
      'topicCoverageTarget',
      String,
      'Topic Coverage Target %',
      hint: '100% of required, 80% of optional',
    ),
    Field(
      'audienceCoverage',
      String,
      'Audience Coverage',
      hint: 'End users, admins, developers',
    ),
    // Detail level
    Field(
      'detailLevelExpectation',
      String,
      'Detail Level Expectation',
      hint: 'Comprehensive, overview, reference',
    ),
    Field(
      'exampleRequirements',
      String,
      'Example Requirements',
      hint: 'Examples for all features, key features',
    ),
    Field(
      'screenshotRequirements',
      String,
      'Screenshot Requirements',
      hint: 'All UI, key workflows',
    ),
    // Cross-reference
    Field(
      'crossReferenceIntegrity',
      String,
      'Cross-Reference Integrity',
      hint: 'Automated link checking',
    ),
    Field(
      'relatedTopicsLinking',
      String,
      'Related Topics Linking',
      hint: 'Manual, automated suggestions',
    ),
    // Verification
    Field(
      'completenessReview',
      String,
      'Completeness Review',
      hint: 'Checklist, traceability matrix',
    ),
    Field(
      'gapIdentificationProcess',
      String,
      'Gap Identification',
      hint: 'User feedback, coverage reports',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Detailed completeness requirements narrative.
  @SerializationOrder(1)
  TextSection narrative = TextSection();
}

/// 11.5.3. Documentation correctness quality.
@StandardReferences([
  'ISO/IEC 26514:2008 — information for users is technically accurate and free of errors when verified against the product',
], 'Captures correctness of documentation as verified against the product.')
@SectionId('DOCOQ1')
class DocCorrectness extends DocSpecsSection {
  @Form([
    // Error-freedom
    Field(
      'spellingGrammarCheck',
      String,
      'Spelling/Grammar Check',
      hint: 'Automated tools, manual review',
    ),
    Field(
      'technicalAccuracyReview',
      String,
      'Technical Accuracy Review',
      hint: 'SME review, testing against product',
    ),
    Field(
      'errorToleranceLevel',
      String,
      'Error Tolerance Level',
      hint: 'Zero errors, minor allowed',
    ),
    // Consistency
    Field(
      'terminologyConsistency',
      String,
      'Terminology Consistency',
      hint: 'Glossary enforcement',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Formatting and implementation alignment.
  @SectionId('DCQA')
  @StandardReferences(
    [
      'ISO/IEC 26514:2008 — information is kept consistent across documents and aligned with the corresponding product version',
    ],
    'Captures formatting consistency and alignment of documentation with the product.',
  )
  @Form([
    Field(
      'formatConsistency',
      String,
      'Format Consistency',
      hint: 'Template adherence',
    ),
    Field(
      'crossDocumentConsistency',
      String,
      'Cross-Document Consistency',
      hint: 'Consistency across documents',
    ),
    Field(
      'documentationSyncProcess',
      String,
      'Documentation Sync Process',
      hint: 'How docs stay aligned with code',
    ),
    Field(
      'versionAlignment',
      String,
      'Version Alignment',
      hint: 'Docs versioned with product',
    ),
    Field(
      'deprecationHandling',
      String,
      'Deprecation Handling',
      hint: 'How deprecated features are handled',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? alignment;

  /// Verification and feedback handling.
  @SectionId('DCQV')
  @StandardReferences([
    'ISO/IEC 26514:2008 — information is reviewed and validated, and user feedback is incorporated into revisions',
  ], 'Captures verification of documentation and the handling of user feedback.')
  @Form([
    Field(
      'correctnessVerification',
      String,
      'Correctness Verification',
      hint: 'Testing docs against product',
    ),
    Field(
      'userFeedbackIntegration',
      String,
      'User Feedback Integration',
      hint: 'How user-reported errors are handled',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? verification;

  /// Detailed correctness requirements narrative.
  @SerializationOrder(3)
  TextSection narrative = TextSection();
}

/// 11.5.4. Documentation changeability quality.
@StandardReferences(
  [
    'ISO/IEC/IEEE 26515:2018 — information for users is maintained and updated as the product evolves through successive iterations',
  ],
  'Captures how documentation is kept current as the product changes over time.',
)
@SectionId('DOCHQU')
class DocChangeability extends DocSpecsSection {
  @Form([
    Field(
      'versioningStrategy',
      String,
      'Versioning Strategy',
      hint: 'Semantic, date-based, product-aligned',
    ),
    Field(
      'versionHistoryTracking',
      String,
      'Version History Tracking',
      hint: 'Changelog, git history',
    ),
    Field(
      'multiVersionSupport',
      String,
      'Multi-Version Support',
      hint: 'Multiple product versions documented',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Extensibility and localization readiness.
  @SectionId('DCQE')
  @StandardReferences(
    [
      'ISO/IEC 26514:2008 — information is structured to support extension and translation into other languages',
    ],
    'Captures how documentation supports extension and readiness for localization.',
  )
  @Form([
    Field(
      'extensibilityApproach',
      String,
      'Extensibility Approach',
      hint: 'Modular, template-based',
    ),
    Field(
      'newSectionGuidelines',
      String,
      'New Section Guidelines',
      hint: 'How to add new content',
    ),
    Field(
      'localizationReadiness',
      String,
      'Localization Readiness',
      hint: 'i18n considerations',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? extensibility;

  /// Sizing and structural consistency rules.
  @SectionId('DCQS')
  @StandardReferences(
    [
      'ISO/IEC 26514:2008 — information units are sized and made granular so that topics remain manageable and consistent',
    ],
    'Captures document sizing, topic granularity, and structural consistency rules.',
  )
  @Form([
    Field(
      'documentSizingGuideline',
      String,
      'Document Sizing',
      hint: 'Max pages, when to split',
    ),
    Field(
      'topicGranularity',
      String,
      'Topic Granularity',
      hint: 'One topic per page, combined',
    ),
    Field(
      'templateAdherence',
      String,
      'Template Adherence',
      hint: 'Required, recommended',
    ),
    Field(
      'structuralChangeProcess',
      String,
      'Structural Change Process',
      hint: 'How structure changes are made',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? structure;

  /// Review and retirement maintenance process.
  @SectionId('DCQM')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26515:2018 — information is reviewed on a defined cycle and retired when it is no longer accurate',
    ],
    'Captures the review cadence and retirement process for user documentation.',
  )
  @Form([
    Field(
      'reviewCycle',
      String,
      'Review Cycle',
      hint: 'Periodic review schedule',
    ),
    Field(
      'retirementProcess',
      String,
      'Retirement Process',
      hint: 'How outdated docs are retired',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? maintenance;

  /// Detailed changeability requirements narrative.
  @SerializationOrder(4)
  TextSection narrative = TextSection();
}

/// 11.6. Quality Prioritization.
///
/// Prioritization and balancing of quality attributes including weighted
/// matrices and explicit trade-off decisions.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — quality characteristics can conflict, so their relative importance is established to guide decisions',
    'ISO/IEC 25030:2019 — quality requirements are prioritised against stakeholder needs and constraints',
  ],
  'Captures how quality attributes are prioritised and balanced across weighted matrices and trade-off decisions.',
)
@SectionId('QUPR')
@DetailedIn(D10QualityAcceptancePlan)
class QualityPrioritization extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Prioritization Framework
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('QUPR-PRIO')
  @Form([
    Field(
      'prioritizationMethod',
      String,
      'Prioritization Method',
      hint: 'Weighted scoring, AHP, forced ranking',
    ),
    Field(
      'prioritizationStakeholders',
      String,
      'Prioritization Stakeholders',
      hint: 'Who participates in prioritization',
    ),
    Field(
      'prioritizationFrequency',
      String,
      'Prioritization Frequency',
      hint: 'Once, per-phase, continuous',
    ),
    Field(
      'prioritizationDocumentation',
      String,
      'Prioritization Documentation',
      hint: 'How decisions are documented',
    ),
    Field(
      'prioritizationReview',
      String,
      'Prioritization Review',
      hint: 'When priorities are reviewed',
    ),
    Field(
      'conflictResolutionAuthority',
      String,
      'Conflict Resolution Authority',
      hint: 'Who resolves priority conflicts',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? prioritizationFrameworkContent;

  /// Prioritization approach overview.
  @ContentHelp(
    'Overview of how quality attributes are prioritized, '
    'including stakeholder involvement and decision process.',
  )
  @SerializationOrder(1)
  TextSection prioritizationOverview = TextSection();

  /// 11.6.1. Weighted Quality Matrix.
  @SerializationOrder(2)
  WeightedQualityMatrix weightedQualityMatrix = WeightedQualityMatrix();

  /// 11.6.2. Trade-off Decisions.
  @SerializationOrder(3)
  TradeOffDecisions tradeOffDecisions = TradeOffDecisions();
}

/// 11.6.1. Weighted Quality Matrix.
@StandardReferences(
  [
    'ISO/IEC 25030:2019 — quality requirements are weighted to reflect their relative importance to stakeholders',
  ],
  'Captures the weighted quality matrix that reflects the relative importance of quality requirements to stakeholders.',
)
@SectionId('WEQUMA')
class WeightedQualityMatrix extends DocSpecsSection {
  @SectionId('WEQUMA-MATR')
  @Form([
    Field(
      'matrixFormat',
      String,
      'Matrix Format',
      hint: 'Spreadsheet, radar chart, heatmap',
    ),
    Field(
      'weightingScale',
      String,
      'Weighting Scale',
      hint: '1-5, 1-10, percentage',
    ),
    Field(
      'totalWeightRequirement',
      String,
      'Total Weight Requirement',
      hint: 'Sum to 100%, relative weights',
    ),
    Field(
      'weightJustificationRequired',
      bool,
      'Weight Justification Required',
      hint: 'Whether each weight needs a documented justification',
    ),
    Field(
      'matrixUpdateProcess',
      String,
      'Matrix Update Process',
      hint: 'How weights are updated',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? matrixConfigContent;

  /// Weighted quality matrix narrative.
  @ContentHelp(
    'Description of weighted quality matrix including '
    'weights assigned to each attribute and rationale.',
  )
  @SerializationOrder(1)
  TextSection matrixNarrative = TextSection();

  /// Quality attribute weight entries.
  @StandardReferences(
    [
      'ISO/IEC 25030:2019 — each weighted quality requirement is enumerated with its assigned relative weight',
    ],
    'Enumerates each weighted quality requirement with its assigned relative weight.',
  )
  @SectionId('QLWGT-WEIG-LST')
  @SectionIdPattern('QLWGT-WEIG-xxx')
  @ContentHelp('Add one entry per quality attribute weight.')
  @SerializationOrder(2)
  List<QualityWeightEntry> weights = [];

  /// Quality matrix visualization.
  @ContentHelp('Visual representation of quality attribute priorities.')
  @SerializationOrder(3)
  DiagramSection matrixVisualization = DiagramSection();
}

/// A quality weight entry.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — a relative weight expresses the importance of a quality attribute when attributes compete',
  ],
  'Captures the relative weight expressing the importance of one quality attribute when attributes compete.',
)
@SectionId('QLWGT')
class QualityWeightEntry extends DocSpecsSection {
  @Form([
    Field('qualityAttribute', String, 'Quality Attribute', required: true),
    Field(
      'qualityCategory',
      String,
      'Category',
      hint: 'User, Technical, Operations, Documentation',
    ),
    Field(
      'weight',
      int,
      'Weight (1-100)',
      hint: 'Numeric weight from 1 to 100',
    ),
    Field('priority', String, 'Priority', hint: 'Critical, high, medium, low'),
    Field('rationale', String, 'Rationale', hint: 'Why this weight'),
    Field(
      'stakeholderAgreement',
      String,
      'Stakeholder Agreement',
      hint: 'Who agreed to this weight',
    ),
    Field(
      'tradeOffImplications',
      String,
      'Trade-off Implications',
      hint: 'What this priority means for other attributes',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 11.6.2. Trade-off Decisions.
///
/// Explicit trade-off decisions between quality attributes.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — improving one quality characteristic can degrade another, so trade-off decisions are made explicit',
  ],
  'Captures explicit trade-off decisions made when improving one quality attribute degrades another.',
)
@SectionId('TROFDE')
class TradeOffDecisions extends DocSpecsSection {
  @SectionId('TROFDE-TRAD')
  @Form([
    Field(
      'tradeOffGovernance',
      String,
      'Trade-off Governance',
      hint: 'Who can make trade-off decisions',
    ),
    Field(
      'tradeOffDocumentation',
      String,
      'Trade-off Documentation',
      hint: 'How decisions are documented',
    ),
    Field(
      'tradeOffReview',
      String,
      'Trade-off Review',
      hint: 'When trade-offs are reviewed',
    ),
    Field(
      'tradeOffReversal',
      String,
      'Trade-off Reversal',
      hint: 'Process to reverse a trade-off decision',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? tradeOffGovernanceContent;

  /// Trade-off decisions overview.
  @ContentHelp(
    'Overview of major trade-off decisions and their impact '
    'on system quality and design choices.',
  )
  @SerializationOrder(1)
  TextSection tradeOffOverview = TextSection();

  /// Contains 0+× TradeOffDecision.
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — each trade-off between competing quality characteristics is enumerated as a discrete decision',
    ],
    'Enumerates each trade-off between competing quality characteristics as a discrete decision.',
  )
  @SectionId('TODE-ITEM-LST')
  @SectionIdPattern('TODE-ITEM-xxx')
  @ContentHelp('Add one entry per trade-off decision.')
  @SerializationOrder(2)
  List<TradeOffDecisionEntry> items = [];
}

/// A trade-off decision entry (form).
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — each trade-off decision is recorded with the qualities in conflict and its rationale',
  ],
  'Captures a single trade-off decision with the qualities in conflict and its rationale.',
)
@SectionId('TODE')
class TradeOffDecisionEntry extends DocSpecsSection {
  @Form([
    Field(
      'decisionId',
      String,
      'Decision ID',
      hint: 'Unique identifier (e.g., TRADEOFF-001)',
    ),
    Field('decisionTitle', String, 'Decision Title', required: true),
    Field(
      'decisionStatus',
      String,
      'Status',
      hint: 'Proposed, approved, implemented, reversed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Qualities in conflict.
  @SectionId('TODEQ')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the quality characteristics prioritised and deprioritised in a trade-off are identified',
    ],
    'Captures the quality attributes prioritised and deprioritised within a trade-off.',
  )
  @Form([
    Field(
      'prioritizedQuality',
      String,
      'Prioritized Quality',
      required: true,
      hint: 'Quality attribute given priority',
    ),
    Field(
      'deprioritizedQuality',
      String,
      'Deprioritized Quality',
      required: true,
      hint: 'Quality attribute traded off',
    ),
    Field(
      'additionalQualitiesAffected',
      String,
      'Additional Qualities Affected',
      hint: 'Other qualities impacted',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? qualities;

  /// Rationale for trade-off.
  @SectionId('TODER')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the business and technical rationale for a quality trade-off is documented',
    ],
    'Captures the business and technical rationale behind a quality trade-off decision.',
  )
  @Form([
    Field(
      'businessRationale',
      String,
      'Business Rationale',
      hint: 'Business reason for trade-off',
    ),
    Field(
      'technicalRationale',
      String,
      'Technical Rationale',
      hint: 'Technical considerations',
    ),
    Field(
      'constraintsInfluencing',
      String,
      'Constraints Influencing',
      hint: 'Constraints that drove decision',
    ),
    Field(
      'alternativesConsidered',
      String,
      'Alternatives Considered',
      hint: 'Other approaches evaluated',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? rationale;

  /// Impact assessment.
  @SectionId('TODEI')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the impact of a quality trade-off on requirements, architecture, schedule, and cost is assessed',
    ],
    'Captures the assessed impact of a quality trade-off across requirements, architecture, schedule, and cost.',
  )
  @Form([
    Field(
      'impactOnRequirements',
      String,
      'Impact on Requirements',
      hint: 'Requirements affected',
    ),
    Field(
      'impactOnArchitecture',
      String,
      'Impact on Architecture',
      hint: 'Architectural implications',
    ),
    Field(
      'impactOnSchedule',
      String,
      'Impact on Schedule',
      hint: 'Schedule implications',
    ),
    Field('impactOnCost', String, 'Impact on Cost', hint: 'Cost implications'),
    Field(
      'impactOnUserExperience',
      String,
      'Impact on User Experience',
      hint: 'UX implications',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? impact;

  /// Mitigation measures.
  @SectionId('TODEM')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — measures are defined to mitigate the effect of a deprioritised quality characteristic',
    ],
    'Captures measures that mitigate the effect of a deprioritised quality attribute.',
  )
  @Form([
    Field(
      'mitigationMeasures',
      String,
      'Mitigation Measures',
      hint: 'How deprioritized quality is mitigated',
    ),
    Field(
      'acceptanceCriteria',
      String,
      'Acceptance Criteria',
      hint: 'Minimum acceptable level',
    ),
    Field(
      'monitoringApproach',
      String,
      'Monitoring Approach',
      hint: 'How impact is monitored',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? mitigation;

  /// Approval and governance.
  @SectionId('TODEA')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — quality trade-off decisions are approved and reviewed by accountable stakeholders',
    ],
    'Captures approval and governance details for a quality trade-off decision.',
  )
  @Form([
    Field(
      'decisionDate',
      String,
      'Decision Date',
      hint: 'Date the trade-off decision was made',
    ),
    Field(
      'approvedBy',
      String,
      'Approved By',
      hint: 'Who approved the trade-off',
    ),
    Field(
      'stakeholdersConsulted',
      String,
      'Stakeholders Consulted',
      hint: 'Who was consulted',
    ),
    Field(
      'reviewDate',
      String,
      'Review Date',
      hint: 'When decision will be reviewed',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? approval;

  /// Detailed trade-off analysis.
  @ContentHelp(
    'Extended analysis of trade-off decision including '
    'quantitative impact assessment.',
  )
  @SerializationOrder(6)
  TextSection detailedAnalysis = TextSection();
}

/// 11.7. Acceptance Criteria Summary.
///
/// The acceptance *framework* and summary for the project: the acceptance
/// process/authority/scope, the must-pass criteria, and the quality-gate
/// checklist. The full enumerated, traceable acceptance criteria are NOT
/// re-declared here — they live in the canonical [AcceptanceCriteriaList]
/// (ACRITL / QAP-CRI) under the acceptance plan, which this summary references
/// explicitly via [detailedCriteria] (SR-54: one canonical spine, summary
/// referencing list).
@StandardReferences(
  [
    'ISO/IEC 25040:2011 — the product quality evaluation concludes by judging the product against defined acceptance criteria',
    'ISO/IEC/IEEE 29119 — completion of testing is assessed against a defined set of acceptance criteria',
  ],
  'Summarizes the acceptance criteria against which the product is judged and testing completion is assessed.',
)
@SectionId('ACCRSU')
@DetailedIn(D10QualityAcceptancePlan)
class AcceptanceCriteriaSummary extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Acceptance Framework
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('ACCRSU-ACCE')
  @Form([
    Field(
      'acceptanceProcess',
      String,
      'Acceptance Process',
      hint: 'Formal UAT, continuous acceptance',
    ),
    Field(
      'acceptanceAuthority',
      String,
      'Acceptance Authority',
      hint: 'Who signs off on acceptance',
    ),
    Field(
      'acceptanceScope',
      String,
      'Acceptance Scope',
      hint: 'Full system, incremental, phase-based',
    ),
    Field(
      'acceptanceEnvironment',
      String,
      'Acceptance Environment',
      hint: 'Where acceptance testing occurs',
    ),
    Field(
      'acceptanceTimeline',
      String,
      'Acceptance Timeline',
      hint: 'Duration of acceptance period',
    ),
    Field(
      'partialAcceptance',
      String,
      'Partial Acceptance',
      hint: 'Policy on accepting with defects',
    ),
    Field(
      'acceptanceRejectionCriteria',
      String,
      'Rejection Criteria',
      hint: 'What triggers rejection',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? acceptanceFrameworkContent;

  /// Acceptance criteria overview.
  @ContentHelp(
    'Overview of acceptance process, key acceptance criteria, '
    'and acceptance governance.',
  )
  @SerializationOrder(1)
  TextSection acceptanceOverview = TextSection();

  /// 11.7.1. Must-Pass Criteria.
  @SerializationOrder(2)
  MustPassCriteria mustPassCriteria = MustPassCriteria();

  /// 11.7.2. Quality Gate Checklist.
  @SerializationOrder(3)
  QualityGateChecklist qualityGateChecklist = QualityGateChecklist();

  /// Canonical, enumerated acceptance criteria (SR-54 explicit link).
  ///
  /// The single source of truth for the full set of traceable acceptance
  /// criteria; this summary references — rather than duplicates — it. The same
  /// [AcceptanceCriteriaList] is the QAP-CRI seed under the acceptance plan.
  @SerializationOrder(4)
  AcceptanceCriteriaList detailedCriteria = AcceptanceCriteriaList();

  /// Acceptance test summary.
  @ContentHelp('Summary of acceptance test plan and expected outcomes.')
  @SerializationOrder(5)
  TextSection acceptanceTestSummary = TextSection();
}

/// 11.7.1. Must-Pass Criteria.
///
/// Criteria that must be met for the system to be accepted.
@StandardReferences(
  [
    'ISO/IEC 25040:2011 — acceptance defines the criteria that must be satisfied for the product to be accepted',
  ],
  'Captures the must-pass criteria that must be satisfied for the product to be accepted.',
)
@SectionId('MUPACR')
class MustPassCriteria extends DocSpecsSection {
  @SectionId('MUPACR-MUST')
  @Form([
    Field(
      'mustPassPhilosophy',
      String,
      'Must-Pass Philosophy',
      hint: 'All must pass, weighted approach',
    ),
    Field(
      'mustPassCount',
      int,
      'Number of Must-Pass Criteria',
      hint: 'Total count of must-pass criteria',
    ),
    Field(
      'criticalityDefinition',
      String,
      'Criticality Definition',
      hint: 'What makes a criterion must-pass',
    ),
    Field(
      'waiverProcess',
      String,
      'Waiver Process',
      hint: 'Can must-pass criteria be waived',
    ),
    Field(
      'waiverAuthority',
      String,
      'Waiver Authority',
      hint: 'Who can grant waivers',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? mustPassOverviewContent;

  /// Must-pass criteria overview.
  @ContentHelp(
    'Overview of must-pass criteria approach and '
    'rationale for selection.',
  )
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× MustPassCriterion.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — each acceptance criterion is enumerated as a discrete item with a defined verification method',
    ],
    'Enumerates the must-pass criteria as discrete items, each with a defined verification method.',
  )
  @SectionId('MSTPCR-ITEM-LST')
  @SectionIdPattern('MSTPCR-ITEM-xxx')
  @ContentHelp('Add one entry per must-pass criterion.')
  @SerializationOrder(2)
  List<MustPassCriterionEntry> items = [];
}

/// A must-pass criterion entry (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — each criterion defines the condition to be met and the method used to verify it',
  ],
  'Captures a single must-pass criterion including the condition to be met and the method used to verify it.',
)
@SectionId('MSTPCR')
class MustPassCriterionEntry extends DocSpecsSection {
  @Form([
    Field(
      'criterionId',
      String,
      'Criterion ID',
      hint: 'Unique identifier (e.g., MP-001)',
    ),
    Field('criterionName', String, 'Criterion Name', required: true),
    Field(
      'verificationMethod',
      String,
      'Verification Method',
      required: true,
      hint: 'Test, demonstration, analysis, inspection',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Classification and intent of the criterion.
  @SectionId('MPCED')
  @StandardReferences(
    [
      'ISO/IEC 25030:2019 — an acceptance criterion is related to a specific quality characteristic and category',
    ],
    'Captures the classification and intent of the criterion including its quality category and attribute.',
  )
  @Form([
    Field(
      'criterionDescription',
      String,
      'Description',
      hint: 'What must be achieved',
    ),
    Field(
      'qualityCategory',
      String,
      'Quality Category',
      hint: 'User, Technical, Operations, Documentation',
    ),
    Field(
      'qualityAttribute',
      String,
      'Quality Attribute',
      hint: 'Specific attribute this relates to',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? definition;

  /// Verification and threshold details.
  @SectionId('MPCEV')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — a verification procedure and pass or fail threshold are defined for each criterion',
    ],
    'Captures the verification procedure, evidence, and pass or fail threshold for a criterion.',
  )
  @Form([
    Field(
      'verificationProcedure',
      String,
      'Verification Procedure',
      hint: 'Steps to verify',
    ),
    Field(
      'verificationEvidence',
      String,
      'Verification Evidence',
      hint: 'What evidence is required',
    ),
    Field(
      'acceptanceThreshold',
      String,
      'Acceptance Threshold',
      required: true,
      hint: 'Pass/fail criteria',
    ),
    Field(
      'measurementMethod',
      String,
      'Measurement Method',
      hint: 'How threshold is measured',
    ),
    Field(
      'toleranceAllowed',
      String,
      'Tolerance Allowed',
      hint: 'Any acceptable variance',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? verification;

  /// Responsibility and dependency information.
  @SectionId('MPCEG')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — responsibility for performing, reviewing, and approving verification is assigned',
    ],
    'Captures who is responsible for performing, reviewing, and approving verification of the criterion.',
  )
  @Form([
    Field(
      'responsibleParty',
      String,
      'Responsible Party',
      hint: 'Who is responsible for verification',
    ),
    Field(
      'reviewerParty',
      String,
      'Reviewer Party',
      hint: 'Who reviews the evidence',
    ),
    Field(
      'approverParty',
      String,
      'Approver Party',
      hint: 'Who approves the result',
    ),
    Field(
      'dependsOnCriteria',
      String,
      'Depends On',
      hint: 'Other criteria this depends on',
    ),
    Field(
      'blockedByCriteria',
      String,
      'Blocked By',
      hint: 'Criteria that block this',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;

  /// Execution status and defects.
  @SectionId('MPCES')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — the test status and associated defects are recorded against each criterion',
    ],
    'Captures the execution status, test outcome, and defects recorded for a must-pass criterion.',
  )
  @Form([
    Field(
      'criterionStatus',
      String,
      'Status',
      hint: 'Not tested, passed, failed, waived',
    ),
    Field(
      'testDate',
      String,
      'Test Date',
      hint: 'Date the criterion was tested',
    ),
    Field(
      'testResult',
      String,
      'Test Result',
      hint: 'Outcome of the test (pass or fail)',
    ),
    Field('defectIds', String, 'Defect IDs', hint: 'Defects blocking pass'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? status;

  /// Additional criterion details.
  @ContentHelp(
    'Extended description of criterion including '
    'edge cases and special considerations.',
  )
  @SerializationOrder(5)
  TextSection details = TextSection();
}

/// 11.7.2. Quality Gate Checklist.
///
/// Quality gate checklist used during acceptance.
@StandardReferences(
  [
    'ISO/IEC 25040:2011 — the product quality evaluation process includes gate reviews that assess the product against defined checks',
    'ISO/IEC/IEEE 29119 — completion of testing is judged against a defined set of checks and criteria',
  ],
  'Captures the quality gate checklist used to assess the product during acceptance.',
)
@SectionId('QUGACH')
class QualityGateChecklist extends DocSpecsSection {
  @SectionId('QUGACH-CHEC')
  @Form([
    Field(
      'checklistPurpose',
      String,
      'Checklist Purpose',
      hint: 'Gate review, final acceptance, milestone',
    ),
    Field(
      'checklistCompleteness',
      String,
      'Completeness Requirement',
      hint: 'All checks required, critical only',
    ),
    Field(
      'checklistReviewProcess',
      String,
      'Review Process',
      hint: 'Individual, committee, automated',
    ),
    Field(
      'checklistSignoff',
      String,
      'Signoff Requirement',
      hint: 'Single, multiple signoffs',
    ),
    Field(
      'checklistFrequency',
      String,
      'Checklist Frequency',
      hint: 'When checklist is used',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? checklistOverviewContent;

  /// Quality gate checklist overview.
  @ContentHelp('Overview of quality gate process and checklist usage.')
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× QualityGateCheck.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — each gate check is enumerated as a discrete item with a defined verification method',
    ],
    'Enumerates each gate check as a discrete item with its verification method.',
  )
  @SectionId('QGCHK-ITEM-LST')
  @SectionIdPattern('QGCHK-ITEM-xxx')
  @ContentHelp('Add one entry per quality gate check.')
  @SerializationOrder(2)
  List<QualityGateCheckEntry> items = [];
}

/// A quality gate check entry (form).
@StandardReferences([
  'ISO/IEC/IEEE 29119 — each check defines the item being verified and the method used to verify it',
], 'Defines the item being verified and the method used to verify it.')
@SectionId('QGCHK')
class QualityGateCheckEntry extends DocSpecsSection {
  @Form([
    Field(
      'checkId',
      String,
      'Check ID',
      hint: 'Unique identifier (e.g., QGC-001)',
    ),
    Field(
      'checkItem',
      String,
      'Check Item',
      required: true,
      hint: 'What is being checked',
    ),
    Field(
      'verificationMethod',
      String,
      'Verification Method',
      required: true,
      hint: 'How check is verified',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Check definition and categorization.
  @SectionId('QGCED')
  @StandardReferences([
    'ISO/IEC 25040:2011 — each check is categorised and related to a quality category to structure the evaluation',
  ], 'Categorises a check and relates it to a quality category.')
  @Form([
    Field(
      'checkDescription',
      String,
      'Check Description',
      hint: 'Detailed description of check',
    ),
    Field('checkCategory', String, 'Check Category', hint: 'Category of check'),
    Field(
      'qualityCategory',
      String,
      'Quality Category',
      hint: 'User, Technical, Operations, Documentation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? definition;

  /// Verification criteria and evidence.
  @SectionId('QGCEV')
  @StandardReferences([
    'ISO/IEC/IEEE 29119 — pass and fail criteria and the evidence required are defined for each check',
  ], 'Defines pass and fail criteria and the evidence required for a check.')
  @Form([
    Field(
      'verificationCriteria',
      String,
      'Verification Criteria',
      hint: 'Pass/fail criteria',
    ),
    Field(
      'evidenceRequired',
      String,
      'Evidence Required',
      hint: 'What evidence is needed',
    ),
    Field(
      'automatedCheck',
      bool,
      'Automated Check',
      hint: 'Is check automated',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? verification;

  /// Responsibility and timing.
  @SectionId('QGCEE')
  @StandardReferences([
    'ISO/IEC/IEEE 29119 — responsibility, timing, and dependencies for performing a check are assigned',
  ], 'Assigns responsibility, timing, and dependencies for performing a check.')
  @Form([
    Field(
      'responsibleParty',
      String,
      'Responsible Party',
      required: true,
      hint: 'Who performs the check',
    ),
    Field(
      'reviewerParty',
      String,
      'Reviewer Party',
      hint: 'Who reviews the result',
    ),
    Field(
      'checkTiming',
      String,
      'Check Timing',
      hint: 'When check is performed',
    ),
    Field(
      'checkDuration',
      String,
      'Check Duration',
      hint: 'Expected time to complete',
    ),
    Field(
      'checkDependencies',
      String,
      'Dependencies',
      hint: 'What must be complete first',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? execution;

  /// Status and observations.
  @SectionId('QGCES')
  @StandardReferences([
    'ISO/IEC/IEEE 29119 — the result and observations of a check are recorded as evidence of completion',
  ], 'Records the status, result, and observations for a gate check.')
  @Form([
    Field(
      'checkStatus',
      String,
      'Status',
      hint: 'Not started, in progress, passed, failed',
    ),
    Field(
      'checkDate',
      String,
      'Check Date',
      hint: 'Date the gate check was performed',
    ),
    Field(
      'checkResult',
      String,
      'Check Result',
      hint: 'Outcome of the gate check (pass or fail)',
    ),
    Field('checkNotes', String, 'Notes', hint: 'Additional observations'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? status;

  /// Blocking behavior.
  @SectionId('QGCEB')
  @StandardReferences([
    'ISO/IEC 25040:2011 — a gate check may block acceptance when the evaluated result does not meet the required level',
  ], 'Captures whether a failed check blocks acceptance and the rationale.')
  @Form([
    Field(
      'isBlocking',
      bool,
      'Is Blocking',
      hint: 'Does failure block acceptance',
    ),
    Field(
      'blockingRationale',
      String,
      'Blocking Rationale',
      hint: 'Why this check blocks',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? blocking;
}

// ---------------------------------------------------------------------------
// 11.8 Test Strategy
// ---------------------------------------------------------------------------

/// 11.8. Test Strategy.
///
/// Overall test strategy for the project..
@StandardReferences([
  'ISO/IEC/IEEE 29119 — a test strategy defines the overall approach, test levels, and coverage for verifying the system',
  'ISO/IEC/IEEE 29119 — testing spans unit, integration, system, and acceptance levels within an organised process',
], 'Defines the overall testing approach, levels, and coverage for the project.')
@SectionId('TEST')
@DetailedIn(D10QualityAcceptancePlan)
class TestStrategy extends DocSpecsSection {
  @ContentHelp('''
High-level strategy for verifying quality across the system. Distinct
from the acceptance plan and from the per-quality-attribute
criteria in the usability, technical, operational, and documentation
quality-goal sections; this section integrates them.

**What to capture:**
- Test levels (unit, integration, system, acceptance, regression)
- Test approach per level (TDD, BDD, model-based, exploratory)
- Automation strategy and coverage targets
- Test environment topology and data strategy
- Entry / exit criteria per level
- Defect management lifecycle
- Traceability from requirements to tests
- Risk-based test prioritization
''')
  @override
  @SerializationOrder(0)
  String? content;
}


