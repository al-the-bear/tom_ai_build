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
@SectionId('SYQG')
@Comment('Seeds → QAP')
@MapsTo(D10QualityAcceptancePlan)
class SystemQualityGoals {
  @Form([
    Field('qualityApproach', String, 'Quality Approach',
        hint: 'Overall quality philosophy: proactive, reactive, hybrid'),
    Field('qualityStandards', String, 'Applicable Quality Standards',
        hint: 'ISO 25010, ISO 9001, CMMI, industry-specific'),
    Field('qualityOwner', String, 'Quality Owner',
        hint: 'Role accountable for quality outcomes'),
  ])
  @SerializationOrder(0)
  String? governanceContent;

  /// Governance board and escalation details.
  @SerializationOrder(1)
  QualityGoalsGovernance governance = QualityGoalsGovernance();

  /// Baseline and target settings.
  @SerializationOrder(2)
  QualityGoalsBaseline baseline = QualityGoalsBaseline();

  /// Measurement and reporting approach.
  @SerializationOrder(3)
  QualityGoalsMeasurement measurement = QualityGoalsMeasurement();

  /// Quality resources and enablement.
  @SerializationOrder(4)
  QualityGoalsResources resources = QualityGoalsResources();

  /// Executive summary of quality goals and approach.
  @ContentHelp('High-level overview of quality objectives, expected quality '
      'level, key quality risks, and approach summary.')
  @SerializationOrder(5)
  TextSection executiveSummary = TextSection();

  /// Quality vision and principles.
  @ContentHelp('Quality vision statement, core principles guiding '
      'quality decisions, and non-negotiable quality standards.')
  @SerializationOrder(6)
  TextSection qualityVision = TextSection();

  /// Quality assurance strategy.
  @ContentHelp('Overall QA strategy: shift-left testing, continuous testing, '
      'test pyramid approach, verification vs validation approach.')
  @SerializationOrder(7)
  TextSection qaStrategy = TextSection();

  /// Quality attribute interdependencies.
  @SectionId('ATTRI-ATTR-LST')
  @SectionIdPattern('ATTRI-ATTR-xxx')
  @SerializationOrder(8)
  List<AttributeInterdependencyEntry> attributeInterdependencies = [];

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

/// Governance board and escalation details.
@SectionId('SQGGV')
class QualityGoalsGovernance {
    @Form([
        Field('qualityReviewBoard', String, 'Quality Review Board',
                hint: 'Governance body for quality decisions'),
        Field('qualityMeetingCadence', String, 'Quality Meeting Cadence',
                hint: 'Weekly, bi-weekly, sprint-aligned'),
        Field('qualityEscalationPath', String, 'Escalation Path',
                hint: 'How quality issues escalate to leadership'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Baseline and target settings.
@SectionId('SQGBS')
class QualityGoalsBaseline {
    @Form([
        Field('qualityBaselineDate', String, 'Quality Baseline Date',
                hint: 'When quality targets were baselined'),
        Field('qualityBaselineVersion', String, 'Baseline Version'),
        Field('overallQualityTargetLevel', String, 'Overall Quality Target Level',
                hint: 'High, production-grade, MVP-acceptable'),
        Field('qualityRiskTolerance', String, 'Quality Risk Tolerance',
                hint: 'Low (zero defects), medium, high tolerance'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Measurement and reporting approach.
@SectionId('SQGMS')
class QualityGoalsMeasurement {
    @Form([
        Field('qualityMetricsFramework', String, 'Metrics Framework',
                hint: 'How quality is measured: GQM, balanced scorecard'),
        Field('qualityReportingFrequency', String, 'Reporting Frequency',
                hint: 'Daily, weekly, sprint, release'),
        Field('qualityDashboardTool', String, 'Quality Dashboard Tool',
                hint: 'SonarQube, custom dashboard, spreadsheet'),
        Field('defectTrackingSystem', String, 'Defect Tracking System',
                hint: 'Jira, Azure DevOps, GitHub Issues'),
        Field('qualityTrendAnalysis', String, 'Trend Analysis Approach',
                hint: 'How quality trends are tracked over time'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Quality resources and enablement.
@SectionId('SQGRS')
class QualityGoalsResources {
    @Form([
        Field('qualityBudget', String, 'Quality Budget',
                hint: 'Budget allocated for QA activities'),
        Field('qaTeamSize', String, 'QA Team Size',
                hint: 'Number of dedicated QA resources'),
        Field('testAutomationTarget', String, 'Test Automation Target %',
                hint: 'Target percentage of automated tests'),
        Field('qualityTrainingPlan', String, 'Quality Training Plan',
                hint: 'Training for team on quality practices'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 11.1. Quality Framework.
///
/// Overall quality approach for the project defining objectives, categories,
/// and how quality is structured and governed across the system.
@SectionId('QLFWK')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-FRA')
class QualityFramework {
  // ─────────────────────────────────────────────────────────────────────────
  // Framework Configuration
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Framework selection
    Field('qualityModel', String, 'Quality Model',
        hint: 'ISO 25010, McCall, Boehm, custom'),
    Field('qualityModelVersion', String, 'Model Version',
        hint: 'Specific version of quality model'),
    Field('qualityModelAdaptations', String, 'Model Adaptations',
        hint: 'How standard model is adapted for this project'),
  ])
  @SerializationOrder(0)
  String? frameworkContent;

  /// Quality objective structure and alignment.
  @SerializationOrder(1)
  QualityFrameworkObjectives objectives = QualityFrameworkObjectives();

  /// Trade-off priorities and decision authority.
  @SerializationOrder(2)
  QualityFrameworkTradeOffs tradeOffs = QualityFrameworkTradeOffs();

  /// Verification and defect handling approach.
  @SerializationOrder(3)
  QualityFrameworkVerification verification =
      QualityFrameworkVerification();

  /// 11.1.1. Quality Objectives Overview.
  @ContentHelp('Overall quality objectives: expected quality level, '
      'how quality will be measured, acceptable trade-offs.')
  @SerializationOrder(4)
  TextSection qualityObjectivesOverview = TextSection();

  /// Quality objectives breakdown by category.
  @ContentHelp('Structured breakdown of objectives for each quality '
      'category with measurable targets.')
  @SerializationOrder(5)
  TextSection objectivesBreakdown = TextSection();

  /// 11.1.2. Quality Categories — contains 0+× QualityCategory.
  @SectionId('QCATE-QUAL-LST')
  @SectionIdPattern('QCATE-QUAL-xxx')
  @SerializationOrder(6)
  List<QualityCategoryEntry> qualityCategories = [];

  /// Quality dependencies map.
  @SectionId('CATEG-CATE-LST')
  @SectionIdPattern('CATEG-CATE-xxx')
  @SerializationOrder(7)
  List<CategoryDependencyEntry> categoryDependencies = [];
}

/// Quality objective structure and alignment.
@SectionId('QFOBJ')
class QualityFrameworkObjectives {
    @Form([
        Field('objectivesHierarchy', String, 'Objectives Hierarchy',
                hint: 'How quality objectives are structured'),
        Field('objectivesAlignment', String, 'Objectives Alignment',
                hint: 'How quality objectives align with business goals'),
        Field('objectivesMeasurability', String, 'Measurability Requirement',
                hint: 'All objectives SMART, key objectives only'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Trade-off priorities and decision authority.
@SectionId('QFTRD')
class QualityFrameworkTradeOffs {
    @Form([
        Field('primaryQualityAttribute', String, 'Primary Quality Attribute',
                hint: 'Most important attribute when trade-offs required'),
        Field('secondaryQualityAttribute', String, 'Secondary Quality Attribute'),
        Field('tradeOffApproach', String, 'Trade-off Approach',
                hint: 'How conflicts between attributes are resolved'),
        Field('qualityCompromiseAuthority', String, 'Compromise Authority',
                hint: 'Who can authorize quality trade-offs'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Verification and defect handling approach.
@SectionId('QFVER')
class QualityFrameworkVerification {
    @Form([
        Field('verificationStrategy', String, 'Verification Strategy',
                hint: 'Testing, review, analysis, demonstration'),
        Field('verificationCoverage', String, 'Verification Coverage',
                hint: 'All attributes, critical only, risk-based'),
        Field('defectClassification', String, 'Defect Classification Scheme',
                hint: 'Critical, major, minor, trivial'),
        Field('defectPriorityScheme', String, 'Defect Priority Scheme',
                hint: 'P1-P5, urgent/high/medium/low'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A quality category entry (form).
///
/// Defines a quality category with its attributes, weight, and relationship
/// to other categories.
@SectionId('QCATE')
class QualityCategoryEntry {
  @Form([
    Field('categoryId', String, 'Category ID',
        hint: 'Unique identifier (e.g., QC-USER-01)'),
    Field('categoryName', String, 'Category Name', required: true,
        hint: 'User-Related, Technical, Operational, Documentation'),
    Field('categoryWeight', int, 'Category Weight (1-100)',
        hint: 'Relative importance in overall quality'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Description and priority context.
  @SerializationOrder(1)
  QualityCategoryEntryDefinition definition = QualityCategoryEntryDefinition();

  /// Category relationships.
  @SerializationOrder(2)
  QualityCategoryEntryRelationships relationships =
      QualityCategoryEntryRelationships();

  /// Governance ownership.
  @SerializationOrder(3)
  QualityCategoryEntryGovernance governance =
      QualityCategoryEntryGovernance();

  /// Measurement targets.
  @SerializationOrder(4)
  QualityCategoryEntryMetrics metrics = QualityCategoryEntryMetrics();

  /// Detailed category definition.
  @ContentHelp('Extended description of category scope, boundaries, '
      'and quality attributes included.')
  @SerializationOrder(5)
  TextSection categoryDetails = TextSection();
}

/// Description and priority context.
@SectionId('QCADF')
class QualityCategoryEntryDefinition {
  @Form([
    Field('categoryDescription', String, 'Description',
        hint: 'Purpose and scope of this category'),
    Field('categoryScope', String, 'Scope',
        hint: 'What aspects of quality this covers'),
    Field('categoryPriority', String, 'Priority',
        hint: 'Critical, high, medium, low'),
    Field('categoryRationale', String, 'Priority Rationale',
        hint: 'Why this priority level'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Category relationships.
@SectionId('QCARL')
class QualityCategoryEntryRelationships {
  @Form([
    Field('parentCategory', String, 'Parent Category',
        hint: 'Higher-level category if hierarchical'),
    Field('relatedCategories', String, 'Related Categories',
        hint: 'Categories that interact with this one'),
    Field('conflictingCategories', String, 'Conflicting Categories',
        hint: 'Categories that may trade off against this'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Governance ownership.
@SectionId('QCAGV')
class QualityCategoryEntryGovernance {
  @Form([
    Field('categoryOwner', String, 'Category Owner',
        hint: 'Role responsible for this quality area'),
    Field('reviewFrequency', String, 'Review Frequency',
        hint: 'How often category metrics are reviewed'),
    Field('escalationThreshold', String, 'Escalation Threshold',
        hint: 'When category issues escalate'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Measurement targets.
@SectionId('QCAMT')
class QualityCategoryEntryMetrics {
  @Form([
    Field('primaryMetric', String, 'Primary Metric',
        hint: 'Main metric for this category'),
    Field('secondaryMetrics', String, 'Secondary Metrics',
        hint: 'Supporting metrics'),
    Field('targetValue', String, 'Target Value',
        hint: 'Target for primary metric'),
    Field('currentBaseline', String, 'Current Baseline',
        hint: 'Starting baseline value'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.2. Functional Suitability (ISO/IEC 25010:2023).
///
/// Degree to which the product provides functions that meet stated and implied
/// needs — functional completeness and correctness. Re-homes the former
/// user-bucket functional leaves under the 25010:2023 spine (L34C-8).
@SectionId('FNSU')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-FSU')
class FunctionalSuitabilityCharacteristic {
  // ─────────────────────────────────────────────────────────────────────────
  // Functional Suitability Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('functionalSuitabilityApproach', String,
        'Functional Suitability Approach',
        hint: 'How functional completeness and correctness are assured'),
    Field('functionalCoverageTarget', String, 'Functional Coverage Target',
        hint: 'Required vs. optional feature coverage'),
    Field('correctnessStandard', String, 'Correctness Standard',
        hint: 'Acceptable defect density, accuracy thresholds'),
  ])
  @SerializationOrder(0)
  String? functionalSuitabilityContent;

  /// Functional suitability overview.
  @ContentHelp('Executive summary of functional-suitability goals, '
      'coverage targets, and correctness metrics.')
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.2.1. Functional Completeness.
  @SerializationOrder(2)
  FunctionalCompleteness functionalCompleteness =
      FunctionalCompleteness();

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
@SectionId('INCP')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-ICP')
class InteractionCapabilityCharacteristic {
  // ─────────────────────────────────────────────────────────────────────────
  // Interaction Capability Overview (migrated from the former user bucket)
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('userQualityPhilosophy', String, 'User Quality Philosophy',
        hint: 'User-first, balanced, efficiency-focused'),
    Field('targetUserExperience', String, 'Target User Experience',
        hint: 'Delightful, efficient, adequate, minimal'),
    Field('userResearchBasis', String, 'User Research Basis',
        hint: 'Personas, surveys, interviews, analytics'),
    Field('userFeedbackChannel', String, 'User Feedback Channel',
        hint: 'How user quality feedback is collected'),
    Field('userSatisfactionTarget', String, 'User Satisfaction Target',
        hint: 'NPS > 50, CSAT > 80%, etc.'),
    Field('accessibilityLevel', String, 'Accessibility Level',
        hint: 'WCAG 2.1 AA, AAA, Section 508'),
  ])
  @SerializationOrder(0)
  String? interactionCapabilityContent;

  /// Interaction capability overview.
  @ContentHelp('Executive summary of interaction-capability goals, '
      'target user experience, and key user-quality metrics.')
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.5.1. Usability.
  @SerializationOrder(2)
  Usability usability = Usability();
}

/// 11.2.1. Usability quality.
@SectionId('USAQL')
class Usability {
  @Form([
    Field('operabilityTarget', String, 'Operability Target',
        hint: 'Ease of operation: intuitive, training-required'),
    Field('ergonomicsStandard', String, 'Ergonomics Standard',
        hint: 'ISO 9241, platform guidelines'),
    Field('learnabilityTarget', String, 'Learnability Target',
        hint: 'Time to proficiency: <1 hour, <1 day'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Operability verification and ergonomics goals.
  @SerializationOrder(1)
  UsabilityOperability operability = UsabilityOperability();

  /// Learnability and onboarding expectations.
  @SerializationOrder(2)
  UsabilityLearnability learnability = UsabilityLearnability();

  /// Clarity and complexity constraints.
  @SerializationOrder(3)
  UsabilityClarity clarity = UsabilityClarity();

  /// Interaction control settings.
  @SerializationOrder(4)
  UsabilityInteraction interaction = UsabilityInteraction();

  /// Perceived and measured responsiveness targets.
  @SerializationOrder(5)
  UsabilityPerformance performance = UsabilityPerformance();

  /// Detailed usability requirements narrative.
  @SerializationOrder(6)
  TextSection narrative = TextSection();
}

/// Operability verification and ergonomics goals.
@SectionId('USAOP')
class UsabilityOperability {
  @Form([
    Field('operabilityMetric', String, 'Operability Metric',
        hint: 'Task completion rate, error rate'),
    Field('operabilityVerification', String, 'Operability Verification',
        hint: 'Usability testing, heuristic evaluation'),
    Field('ergonomicsTarget', String, 'Ergonomics Target',
        hint: 'Reduce cognitive load, minimize clicks'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Learnability and onboarding expectations.
@SectionId('USALN')
class UsabilityLearnability {
  @Form([
    Field('learnabilityVerification', String, 'Learnability Verification',
        hint: 'First-use testing, training time measurement'),
    Field('onboardingRequirement', String, 'Onboarding Requirement',
        hint: 'Self-service, guided tour, training required'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Clarity and complexity constraints.
@SectionId('USACL')
class UsabilityClarity {
  @Form([
    Field('functionalClarityTarget', String, 'Functional Clarity Target',
        hint: 'Labels, icons, workflows self-explanatory'),
    Field('helpSystemRequirement', String, 'Help System Requirement',
        hint: 'Contextual help, tooltips, documentation'),
    Field('complexityLimit', String, 'Complexity Limit',
        hint: 'Max steps per workflow, max form fields'),
    Field('cognitiveLoadTarget', String, 'Cognitive Load Target',
        hint: 'Info per screen, decision points'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interaction control settings.
@SectionId('USAIN')
class UsabilityInteraction {
  @Form([
    Field('undoRequirement', String, 'Undo Requirement',
        hint: 'All actions, critical actions, none'),
    Field('customizationLevel', String, 'Customization Level',
        hint: 'User preferences, layout, workflow'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Perceived and measured responsiveness targets.
@SectionId('USAPR')
class UsabilityPerformance {
  @Form([
    Field('responseTimeP50', String, 'Response Time P50',
        hint: 'Median response time target (e.g., <200ms)'),
    Field('responseTimeP95', String, 'Response Time P95',
        hint: '95th percentile (e.g., <500ms)'),
    Field('responseTimeP99', String, 'Response Time P99',
        hint: '99th percentile (e.g., <1s)'),
    Field('perceivedPerformance', String, 'Perceived Performance',
        hint: 'Loading indicators, optimistic updates'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.2.2. Functional completeness quality.
@SectionId('FNCOQ')
class FunctionalCompleteness {
  @Form([
    // Coverage
    Field('featureCoverageTarget', String, 'Feature Coverage Target %',
        hint: 'Percentage of specified features implemented'),
    Field('coreWorkflowCoverage', String, 'Core Workflow Coverage',
        hint: '100% of core, 80% of secondary'),
    Field('edgeCaseHandling', String, 'Edge Case Handling',
        hint: 'Explicit handling, graceful degradation'),
    // Scope management
    Field('scopePrioritization', String, 'Scope Prioritization',
        hint: 'MoSCoW, weighted scoring'),
    Field('mvpDefinition', String, 'MVP Definition',
        hint: 'Minimum feature set for launch'),
    Field('deferredFeatureHandling', String, 'Deferred Feature Handling',
        hint: 'How deferred features are communicated'),
    // Verification
    Field('completenessVerification', String, 'Completeness Verification',
        hint: 'Traceability matrix, acceptance testing'),
    Field('userStoryTracking', String, 'User Story Tracking',
        hint: 'How coverage is tracked to requirements'),
    Field('gapAnalysisFrequency', String, 'Gap Analysis Frequency',
        hint: 'Sprint, release, milestone'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Detailed functional completeness narrative.
  @SerializationOrder(1)
  TextSection narrative = TextSection();
}

/// 11.2.3. Correctness quality.
@SectionId('COQU')
class Correctness {
  @Form([
    Field('defectDensityTarget', String, 'Defect Density Target',
        hint: 'Defects per KLOC, per function point'),
    Field('criticalDefectTarget', String, 'Critical Defect Target',
        hint: 'Zero critical/blocking, <N major'),
    Field('defectEscapeRate', String, 'Defect Escape Rate',
        hint: 'Defects found post-release'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Data integrity expectations.
  @SerializationOrder(1)
  CorrectnessIntegrity integrity = CorrectnessIntegrity();

  /// Accuracy and auditability requirements.
  @SerializationOrder(2)
  CorrectnessAccuracy accuracy = CorrectnessAccuracy();

  /// Verification and regression approach.
  @SerializationOrder(3)
  CorrectnessVerification verification =
      CorrectnessVerification();

  /// Detailed correctness requirements narrative.
  @SerializationOrder(4)
  TextSection narrative = TextSection();
}

/// Data integrity expectations.
@SectionId('COQUIN')
class CorrectnessIntegrity {
  @Form([
    Field('dataIntegrityRequirement', String, 'Data Integrity Requirement',
        hint: 'ACID, eventual consistency'),
    Field('dataValidationCoverage', String, 'Data Validation Coverage',
        hint: 'All inputs, critical inputs'),
    Field('dataCorruptionHandling', String, 'Data Corruption Handling',
        hint: 'Detection, recovery, prevention'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Accuracy and auditability requirements.
@SectionId('COQUAC')
class CorrectnessAccuracy {
  @Form([
    Field('calculationAccuracyTarget', String, 'Calculation Accuracy Target',
        hint: 'Decimal precision, rounding rules'),
    Field('financialAccuracyRequirement', String, 'Financial Accuracy',
        hint: 'Penny-accurate, significant figures'),
    Field('auditTrailRequirement', String, 'Audit Trail Requirement',
        hint: 'All changes, financial only'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification and regression approach.
@SectionId('COQUVE')
class CorrectnessVerification {
  @Form([
    Field('correctnessVerification', String, 'Correctness Verification',
        hint: 'Unit tests, integration tests, UAT'),
    Field('testCoverageTarget', String, 'Test Coverage Target',
        hint: 'Code coverage %, requirement coverage'),
    Field('regressionTestingApproach', String, 'Regression Testing',
        hint: 'Automated, manual, risk-based'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.3. Performance Efficiency (ISO/IEC 25010:2023).
///
/// Performance relative to the amount of resources used under stated
/// conditions. Re-homes the former technical-bucket efficiency leaf under the
/// 25010:2023 spine (L34C-8). The dissolved technical-quality overview form is
/// preserved here so no authored content is lost.
@SectionId('PEEF')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-PEF')
class PerformanceEfficiencyCharacteristic {
  // ─────────────────────────────────────────────────────────────────────────
  // Performance Efficiency Overview (migrated from the former technical bucket)
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('technicalQualityPhilosophy', String, 'Technical Quality Philosophy',
        hint: 'Performance-first, maintainability-first, balanced'),
    Field('architecturalQualityGoals', String, 'Architectural Quality Goals',
        hint: 'Key architectural quality attributes'),
    Field('technicalDebtTolerance', String, 'Technical Debt Tolerance',
        hint: 'Zero, controlled, pragmatic'),
    Field('codeQualityStandard', String, 'Code Quality Standard',
        hint: 'Style guide, linting rules'),
    Field('designPrinciplesAdherence', String, 'Design Principles Adherence',
        hint: 'SOLID, DRY, KISS, YAGNI'),
  ])
  @SerializationOrder(0)
  String? performanceEfficiencyContent;

  /// Performance efficiency overview.
  @ContentHelp('Executive summary of performance-efficiency goals, '
      'architectural decisions, and key technical metrics.')
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
@SectionId('CMPT')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-CMP')
class CompatibilityCharacteristic {
  @Form([
    Field('coExistenceRequirements', String, 'Co-existence Requirements',
        hint: 'Other products sharing the environment without adverse impact'),
    Field('interoperabilityStandards', String, 'Interoperability Standards',
        hint: 'Protocols/formats for exchanging and using information'),
  ])
  @SerializationOrder(0)
  String? compatibilityContent;

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
@SectionId('FLXC')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-FLX')
class FlexibilityCharacteristic {
  @Form([
    Field('flexibilityApproach', String, 'Flexibility Approach',
        hint: 'How adaptability, scalability and portability are achieved'),
    Field('portabilityTarget', String, 'Portability Target',
        hint: 'Target environments/platforms the product must run on'),
  ])
  @SerializationOrder(0)
  String? flexibilityContent;

  /// Flexibility overview.
  @ContentHelp('Executive summary of flexibility, adaptability and '
      'portability goals.')
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
@SectionId('SECC')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-SEC')
class SecurityCharacteristic {
  @Form([
    Field('securityApproach', String, 'Security Approach',
        hint: 'Zero-trust, defence-in-depth, least-privilege'),
    Field('securityComplianceTarget', String, 'Security Compliance Target',
        hint: 'ISO 27001, SOC 2, GDPR, sector-specific'),
  ])
  @SerializationOrder(0)
  String? securityContent;

  /// Security overview.
  @ContentHelp('Executive summary of security goals, threat model, and '
      'compliance targets.')
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
@SectionId('MNTC')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-MNT')
class MaintainabilityCharacteristic {
  @Form([
    Field('maintainabilityApproach', String, 'Maintainability Approach',
        hint: 'Modularity, analyzability, testability priorities'),
    Field('maintainabilityStandard', String, 'Maintainability Standard',
        hint: 'Complexity thresholds, test-coverage targets'),
  ])
  @SerializationOrder(0)
  String? maintainabilityContent;

  /// Maintainability overview.
  @ContentHelp('Executive summary of maintainability goals and standards.')
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 11.8.1. Maintainability (product maintainability attributes).
  @SerializationOrder(2)
  Maintainability maintainability = Maintainability();
}

/// 11.3.1. Efficiency quality.
@SectionId('EFQU')
class Efficiency {
  @Form([
    // Response time
    Field('responseTimeP50Target', String, 'Response Time P50',
        hint: 'Median response time (e.g., <100ms)'),
    Field('responseTimeP95Target', String, 'Response Time P95',
        hint: '95th percentile (e.g., <300ms)'),
    Field('responseTimeP99Target', String, 'Response Time P99',
        hint: '99th percentile (e.g., <1s)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Throughput and scale targets.
  @SerializationOrder(1)
  EfficiencyThroughput throughput = EfficiencyThroughput();

  /// Resource utilization constraints.
  @SerializationOrder(2)
  EfficiencyResources resources = EfficiencyResources();

  /// Performance validation and SLA commitments.
  @SerializationOrder(3)
  EfficiencyVerification verification =
      EfficiencyVerification();

  /// Detailed efficiency requirements narrative.
  @SerializationOrder(4)
  TextSection narrative = TextSection();
}

/// Throughput and scale targets.
@SectionId('EFQUTH')
class EfficiencyThroughput {
  @Form([
    Field('throughputTarget', String, 'Throughput Target',
        hint: 'Requests/second, transactions/minute'),
    Field('concurrentUsersTarget', String, 'Concurrent Users Target',
        hint: 'Peak concurrent users supported'),
    Field('scalabilityModel', String, 'Scalability Model',
        hint: 'Horizontal, vertical, auto-scaling'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Resource utilization constraints.
@SectionId('EFQURE')
class EfficiencyResources {
  @Form([
    Field('cpuUtilizationLimit', String, 'CPU Utilization Limit',
        hint: 'Max sustained CPU usage (e.g., <70%)'),
    Field('memoryUtilizationLimit', String, 'Memory Utilization Limit',
        hint: 'Max memory usage'),
    Field('storageEfficiencyTarget', String, 'Storage Efficiency Target',
        hint: 'Data storage per user/record'),
    Field('networkBandwidthLimit', String, 'Network Bandwidth Limit',
        hint: 'Max bandwidth consumption'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance validation and SLA commitments.
@SectionId('EFQUVE')
class EfficiencyVerification {
  @Form([
    Field('loadTestingRequirement', String, 'Load Testing Requirement',
        hint: 'Load test scenarios, thresholds'),
    Field('performanceProfilingApproach', String, 'Performance Profiling',
        hint: 'APM tools, custom instrumentation'),
    Field('performanceBaselineDate', String, 'Performance Baseline Date',
        hint: 'When baseline was established'),
    Field('performanceSlaDefinition', String, 'Performance SLA Definition',
        hint: 'SLA for performance metrics'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.3.2. Portability quality.
@SectionId('POQU')
class Portability {
  @Form([
    // Platform support
    Field('targetPlatforms', String, 'Target Platforms',
        hint: 'iOS, Android, Web, Windows, macOS, Linux'),
    Field('browserSupport', String, 'Browser Support',
        hint: 'Chrome, Firefox, Safari, Edge versions'),
    Field('mobileOsVersions', String, 'Mobile OS Versions',
        hint: 'iOS 14+, Android 10+'),
    Field('desktopOsVersions', String, 'Desktop OS Versions',
        hint: 'Windows 10+, macOS 11+'),
    // Migration
    Field('migrationEffortConstraint', String, 'Migration Effort Constraint',
        hint: 'Max effort to migrate to new platform'),
    Field('dataPortability', String, 'Data Portability',
        hint: 'Export formats, import capabilities'),
    Field('vendorLockInAvoidance', String, 'Vendor Lock-in Avoidance',
        hint: 'Standards-based, abstraction layers'),
    // Containerization
    Field('containerizationRequirement', String, 'Containerization',
        hint: 'Docker, Kubernetes requirements'),
    Field('infrastructureAsCode', String, 'Infrastructure as Code',
        hint: 'Terraform, CloudFormation'),
    // Verification
    Field('portabilityVerification', String, 'Portability Verification',
        hint: 'Cross-platform testing, compatibility matrix'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Detailed portability requirements narrative.
  @SerializationOrder(1)
  TextSection narrative = TextSection();
}

/// 11.3.3. Flexibility quality.
@SectionId('FLQU')
class Flexibility {
  @Form([
    Field('componentArchitecture', String, 'Component Architecture',
        hint: 'Microservices, modular monolith, plugins'),
    Field('componentGranularity', String, 'Component Granularity',
        hint: 'Fine-grained, coarse-grained'),
    Field('componentReplaceability', String, 'Component Replaceability',
        hint: 'Hot-swap, restart required'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Modularity and reuse goals.
  @SerializationOrder(1)
  FlexibilityModularity modularity = FlexibilityModularity();

  /// Distribution and configurability model.
  @SerializationOrder(2)
  FlexibilityDeployment deployment = FlexibilityDeployment();

  /// Extensibility and verification expectations.
  @SerializationOrder(3)
  FlexibilityExtensibility extensibility =
      FlexibilityExtensibility();

  /// Detailed flexibility requirements narrative.
  @SerializationOrder(4)
  TextSection narrative = TextSection();
}

/// Modularity and reuse goals.
@SectionId('FLQUMO')
class FlexibilityModularity {
  @Form([
    Field('modularityLevel', String, 'Modularity Level',
        hint: 'Highly modular, moderately, monolithic'),
    Field('moduleIndependence', String, 'Module Independence',
        hint: 'Loose coupling, shared libraries'),
    Field('moduleReusability', String, 'Module Reusability',
        hint: 'Design for reuse, single-purpose'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Distribution and configurability model.
@SectionId('FLQUDE')
class FlexibilityDeployment {
  @Form([
    Field('distributionCapability', String, 'Distribution Capability',
        hint: 'Multi-region, single-region, on-premise'),
    Field('multiTenancy', String, 'Multi-Tenancy',
        hint: 'Shared, isolated, hybrid'),
    Field('configurabilityLevel', String, 'Configurability Level',
        hint: 'Feature flags, runtime config, deploy-time'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Extensibility and verification expectations.
@SectionId('FLQUEX')
class FlexibilityExtensibility {
  @Form([
    Field('extensibilityModel', String, 'Extensibility Model',
        hint: 'Plugins, APIs, webhooks'),
    Field('customizationScope', String, 'Customization Scope',
        hint: 'UI, business rules, workflows'),
    Field('flexibilityVerification', String, 'Flexibility Verification',
        hint: 'Architecture review, change impact analysis'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.3.4. Security quality.
@SectionId('SEQU')
class Security {
  @Form([
    Field('encryptionAtRest', String, 'Encryption at Rest',
        hint: 'AES-256, database-level, disk-level'),
    Field('encryptionInTransit', String, 'Encryption in Transit',
        hint: 'TLS 1.2+, certificate requirements'),
    Field('keyManagement', String, 'Key Management',
        hint: 'HSM, KMS, key rotation policy'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Authentication controls.
  @SerializationOrder(1)
  SecurityAuthentication authentication =
      SecurityAuthentication();

  /// Authorization controls.
  @SerializationOrder(2)
  SecurityAuthorization authorization =
      SecurityAuthorization();

  /// Vulnerability management expectations.
  @SerializationOrder(3)
  SecurityVulnerability vulnerability =
      SecurityVulnerability();

  /// Compliance and verification settings.
  @SerializationOrder(4)
  SecurityCompliance compliance = SecurityCompliance();

  /// Detailed security requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// Authentication controls.
@SectionId('SEQUAU')
class SecurityAuthentication {
  @Form([
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'OAuth2, SAML, OIDC, MFA'),
    Field('mfaRequirement', String, 'MFA Requirement',
        hint: 'All users, privileged users, optional'),
    Field('passwordPolicy', String, 'Password Policy',
        hint: 'Complexity, rotation, history'),
    Field('sessionManagement', String, 'Session Management',
        hint: 'Timeout, concurrent sessions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Authorization controls.
@SectionId('SEQUA1')
class SecurityAuthorization {
  @Form([
    Field('authorizationModel', String, 'Authorization Model',
        hint: 'RBAC, ABAC, ACL'),
    Field('authorizationCoverage', String, 'Authorization Coverage',
        hint: 'All resources, sensitive resources'),
    Field('privilegeEscalationPrevention', String, 'Privilege Escalation',
        hint: 'Controls to prevent escalation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Vulnerability management expectations.
@SectionId('SEQUVU')
class SecurityVulnerability {
  @Form([
    Field('vulnerabilityScanFrequency', String, 'Vulnerability Scan Frequency',
        hint: 'Continuous, weekly, per-release'),
    Field('penetrationTestFrequency', String, 'Penetration Test Frequency',
        hint: 'Annual, semi-annual, per-release'),
    Field('cveResponseTime', String, 'CVE Response Time',
        hint: 'Critical: 24h, high: 7d'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance and verification settings.
@SectionId('SEQUCO')
class SecurityCompliance {
  @Form([
    Field('securityCompliance', String, 'Security Compliance',
        hint: 'SOC2, ISO 27001, GDPR'),
    Field('securityCertifications', String, 'Security Certifications',
        hint: 'Required certifications'),
    Field('securityAuditFrequency', String, 'Security Audit Frequency',
        hint: 'Annual, continuous'),
    Field('securityVerification', String, 'Security Verification',
        hint: 'SAST, DAST, security review'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.3.5. Maintainability quality.
@SectionId('MAQU')
class Maintainability {
  @Form([
    Field('adaptabilityTarget', String, 'Adaptability Target',
        hint: 'Change implementation time'),
    Field('changeImpactLimit', String, 'Change Impact Limit',
        hint: 'Max components affected by change'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Analyzability requirements.
  @SerializationOrder(1)
  MaintainabilityAnalyzability analyzability =
      MaintainabilityAnalyzability();

  /// Changeability requirements.
  @SerializationOrder(2)
  MaintainabilityChangeability changeability =
      MaintainabilityChangeability();

  /// Testability requirements.
  @SerializationOrder(3)
  MaintainabilityTestability testability =
      MaintainabilityTestability();

  /// Extensibility and verification requirements.
  @SerializationOrder(4)
  MaintainabilityGovernance governance =
      MaintainabilityGovernance();

  /// Detailed maintainability requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// Analyzability requirements.
@SectionId('MAQUAN')
class MaintainabilityAnalyzability {
  @Form([
    Field('codeReadabilityStandard', String, 'Code Readability Standard',
        hint: 'Style guide, code review criteria'),
    Field('documentationRequirement', String, 'Documentation Requirement',
        hint: 'Inline, API docs, architecture docs'),
    Field('loggingStandard', String, 'Logging Standard',
        hint: 'Structured logging, log levels'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Changeability requirements.
@SectionId('MAQUCH')
class MaintainabilityChangeability {
  @Form([
    Field('codeCoverageMinimum', String, 'Code Coverage Minimum',
        hint: 'Unit test coverage % target'),
    Field('cyclomaticComplexityLimit', String, 'Cyclomatic Complexity Limit',
        hint: 'Max complexity per function'),
    Field('methodLengthLimit', String, 'Method Length Limit',
        hint: 'Max lines per method'),
    Field('classLengthLimit', String, 'Class Length Limit',
        hint: 'Max lines per class'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testability requirements.
@SectionId('MAQUTE')
class MaintainabilityTestability {
  @Form([
    Field('testabilityDesign', String, 'Testability Design',
        hint: 'Dependency injection, mocking support'),
    Field('testPyramidRatio', String, 'Test Pyramid Ratio',
        hint: 'Unit:Integration:E2E ratio'),
    Field('testDataManagement', String, 'Test Data Management',
        hint: 'Fixtures, factories, production-like'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Extensibility and verification requirements.
@SectionId('MAQUGO')
class MaintainabilityGovernance {
  @Form([
    Field('extensibilityPattern', String, 'Extensibility Pattern',
        hint: 'Plugin architecture, middleware, hooks'),
    Field('apiVersioningStrategy', String, 'API Versioning Strategy',
        hint: 'URL path, header, query param'),
    Field('maintainabilityVerification', String, 'Maintainability Verification',
        hint: 'Static analysis, architecture fitness functions'),
    Field('technicalDebtTracking', String, 'Technical Debt Tracking',
        hint: 'SonarQube, manual tracking'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.3.6. Reliability quality.
@SectionId('REQU')
class Reliability {
  @Form([
    Field('uptimeTarget', String, 'Uptime Target',
        hint: '99.9%, 99.95%, 99.99%'),
    Field('plannedDowntimeWindow', String, 'Planned Downtime Window',
        hint: 'Maintenance window schedule'),
    Field('degradedModeCapability', String, 'Degraded Mode Capability',
        hint: 'Graceful degradation approach'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Recovery objectives.
  @SerializationOrder(1)
  ReliabilityRecovery recovery = ReliabilityRecovery();

  /// Failover requirements.
  @SerializationOrder(2)
  ReliabilityFailover failover = ReliabilityFailover();

  /// Data durability requirements.
  @SerializationOrder(3)
  ReliabilityDurability durability = ReliabilityDurability();

  /// Verification and learning.
  @SerializationOrder(4)
  ReliabilityVerification verification =
      ReliabilityVerification();

  /// Detailed reliability requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// Recovery objectives.
@SectionId('REQURE')
class ReliabilityRecovery {
  @Form([
    Field('mtbfTarget', String, 'MTBF Target',
        hint: 'Mean time between failures'),
    Field('mttrTarget', String, 'MTTR Target',
        hint: 'Mean time to recovery'),
    Field('rtoTarget', String, 'RTO Target',
        hint: 'Recovery time objective'),
    Field('rpoTarget', String, 'RPO Target',
        hint: 'Recovery point objective'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Failover requirements.
@SectionId('REQUFA')
class ReliabilityFailover {
  @Form([
    Field('failoverStrategy', String, 'Failover Strategy',
        hint: 'Active-passive, active-active'),
    Field('failoverTime', String, 'Failover Time',
        hint: 'Time to complete failover'),
    Field('failoverTesting', String, 'Failover Testing',
        hint: 'Chaos engineering, DR drills'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data durability requirements.
@SectionId('REQUDU')
class ReliabilityDurability {
  @Form([
    Field('dataDurability', String, 'Data Durability',
        hint: '99.999999999% (11 nines)'),
    Field('backupFrequency', String, 'Backup Frequency',
        hint: 'Continuous, hourly, daily'),
    Field('backupRetention', String, 'Backup Retention',
        hint: 'Retention period'),
    Field('backupVerification', String, 'Backup Verification',
        hint: 'Restore testing frequency'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification and learning.
@SectionId('REQUVE')
class ReliabilityVerification {
  @Form([
    Field('reliabilityVerification', String, 'Reliability Verification',
        hint: 'Soak testing, chaos engineering'),
    Field('incidentPostmortem', String, 'Incident Postmortem',
        hint: 'Blameless postmortem process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.6. Reliability (ISO/IEC 25010:2023).
///
/// Degree to which the product performs specified functions under specified
/// conditions for a specified period (availability, fault tolerance,
/// recoverability, maturity). Re-homes the former technical-bucket reliability
/// leaf and the operations-bucket availability, service-level and monitoring
/// leaves under the 25010:2023 spine (L34C-8). The dissolved operations-quality
/// overview form is preserved here so no authored content is lost.
@SectionId('RELC')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-REL')
class ReliabilityCharacteristic {
  // ─────────────────────────────────────────────────────────────────────────
  // Reliability Overview (migrated from the former operations bucket)
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('operationsMaturityModel', String, 'Operations Maturity Model',
        hint: 'ITIL, DevOps, SRE'),
    Field('operationsPhilosophy', String, 'Operations Philosophy',
        hint: 'Ops-driven, DevOps, NoOps'),
    Field('operationsResponsibility', String, 'Operations Responsibility',
        hint: 'Dedicated team, shared, outsourced'),
    Field('incidentManagementProcess', String, 'Incident Management Process',
        hint: 'PagerDuty, custom, ITIL-based'),
    Field('changeManagementProcess', String, 'Change Management Process',
        hint: 'ITIL change management, lightweight'),
    Field('operationsToolchain', String, 'Operations Toolchain',
        hint: 'Key ops tools and platforms'),
  ])
  @SerializationOrder(0)
  String? reliabilityContent;

  /// Reliability overview narrative.
  @ContentHelp('Executive summary of reliability and operational requirements, '
      'support model, and key operational metrics.')
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
@SectionId('AVQU')
class Availability {
  @Form([
    Field('uptimeTargetPercentage', String, 'Uptime Target %',
        hint: '99.9% (8.76h/year downtime)'),
    Field('uptimeCalculationMethod', String, 'Uptime Calculation Method',
        hint: 'Excluding planned, including all'),
    Field('uptimeMeasurementPeriod', String, 'Measurement Period',
        hint: 'Monthly, quarterly, annually'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Operating-hour expectations.
  @SerializationOrder(1)
  AvailabilityOperatingHours operatingHoursDetails =
      AvailabilityOperatingHours();

  /// Maintenance window policy.
  @SerializationOrder(2)
  AvailabilityMaintenance maintenance =
      AvailabilityMaintenance();

  /// Degraded-mode behavior.
  @SerializationOrder(3)
  AvailabilityDegradedMode degradedMode =
      AvailabilityDegradedMode();

  /// Monitoring and reporting.
  @SerializationOrder(4)
  AvailabilityVerification verification =
      AvailabilityVerification();

  /// Detailed availability requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// Operating-hour expectations.
@SectionId('AQOH')
class AvailabilityOperatingHours {
  @Form([
    Field('operatingHours', String, 'Operating Hours',
        hint: '24/7, business hours, regional'),
    Field('peakHoursDefinition', String, 'Peak Hours Definition',
        hint: 'When peak hours apply'),
    Field('peakHoursAvailability', String, 'Peak Hours Availability',
        hint: 'Higher availability during peaks'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Maintenance window policy.
@SectionId('AVQUMA')
class AvailabilityMaintenance {
  @Form([
    Field('scheduledMaintenanceWindow', String, 'Scheduled Maintenance Window',
        hint: 'When maintenance can occur'),
    Field('maintenanceNotification', String, 'Maintenance Notification',
        hint: 'How users are notified'),
    Field('maintenanceFrequency', String, 'Maintenance Frequency',
        hint: 'Weekly, monthly, quarterly'),
    Field('maintenanceDurationLimit', String, 'Maintenance Duration Limit',
        hint: 'Max duration per window'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Degraded-mode behavior.
@SectionId('AQDM')
class AvailabilityDegradedMode {
  @Form([
    Field('degradedModeDefinition', String, 'Degraded Mode Definition',
        hint: 'What constitutes degraded mode'),
    Field('degradedModeCapabilities', String, 'Degraded Mode Capabilities',
        hint: 'Features available in degraded mode'),
    Field('degradedModeCommunication', String, 'Degraded Mode Communication',
        hint: 'How users are informed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Monitoring and reporting.
@SectionId('AVQUVE')
class AvailabilityVerification {
  @Form([
    Field('availabilityMonitoring', String, 'Availability Monitoring',
        hint: 'Synthetic monitoring, real user'),
    Field('availabilityReporting', String, 'Availability Reporting',
        hint: 'Dashboard, reports, SLA tracking'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.4.2. Service level quality.
@SectionId('SELEQU')
class ServiceLevel {
  @Form([
    Field('supportTierStructure', String, 'Support Tier Structure',
        hint: 'L1/L2/L3, single tier'),
    Field('criticalResponseTime', String, 'Critical Response Time',
        hint: 'Response time for P1 issues'),
    Field('highResponseTime', String, 'High Response Time',
        hint: 'Response time for P2 issues'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Remaining response targets.
  @SerializationOrder(1)
  ServiceLevelResponse response = ServiceLevelResponse();

  /// Resolution targets.
  @SerializationOrder(2)
  ServiceLevelResolution resolution = ServiceLevelResolution();

  /// Escalation rules.
  @SerializationOrder(3)
  ServiceLevelEscalation escalation = ServiceLevelEscalation();

  /// On-call support expectations.
  @SerializationOrder(4)
  ServiceLevelOnCall onCall = ServiceLevelOnCall();

  /// Restoration and communication priorities.
  @SerializationOrder(5)
  ServiceLevelRestoration restoration =
      ServiceLevelRestoration();

  /// Detailed service level requirements narrative.
  @SerializationOrder(6)
  TextSection narrative = TextSection();

  /// Service Level Agreement entries.
  @SectionId('SLAE-SLAE-LST')
  @SectionIdPattern('SLAE-SLAE-xxx')
  @SerializationOrder(7)
  List<ServiceLevelAgreementEntry> slaEntries = [];
}

/// Remaining response targets.
@SectionId('SLQR')
class ServiceLevelResponse {
    @Form([
        Field('mediumResponseTime', String, 'Medium Response Time',
                hint: 'Response time for P3 issues'),
        Field('lowResponseTime', String, 'Low Response Time',
                hint: 'Response time for P4 issues'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Resolution targets.
@SectionId('SLQR1')
class ServiceLevelResolution {
    @Form([
        Field('criticalResolutionTime', String, 'Critical Resolution Time',
                hint: 'Resolution target for P1'),
        Field('highResolutionTime', String, 'High Resolution Time',
                hint: 'Resolution target for P2'),
        Field('mediumResolutionTime', String, 'Medium Resolution Time',
                hint: 'Resolution target for P3'),
        Field('lowResolutionTime', String, 'Low Resolution Time',
                hint: 'Resolution target for P4'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Escalation rules.
@SectionId('SLQE')
class ServiceLevelEscalation {
    @Form([
        Field('escalationTimeframes', String, 'Escalation Timeframes',
                hint: 'When issues escalate'),
        Field('escalationContacts', String, 'Escalation Contacts',
                hint: 'Who to escalate to'),
        Field('executiveEscalation', String, 'Executive Escalation',
                hint: 'When executive escalation occurs'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// On-call support expectations.
@SectionId('SLQOC')
class ServiceLevelOnCall {
    @Form([
        Field('onCallCoverage', String, 'On-Call Coverage',
                hint: '24/7, business hours, regional'),
        Field('onCallRotation', String, 'On-Call Rotation',
                hint: 'Weekly, bi-weekly'),
        Field('onCallCompensation', String, 'On-Call Compensation',
                hint: 'Compensation model'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Restoration and communication priorities.
@SectionId('SLQR2')
class ServiceLevelRestoration {
    @Form([
        Field('serviceRestorationPriority', String, 'Service Restoration Priority',
                hint: 'Order of restoration'),
        Field('communicationDuringOutage', String, 'Communication During Outage',
                hint: 'Status page, email, SMS'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A service level agreement entry.
@SectionId('SLAE')
class ServiceLevelAgreementEntry {
  @Form([
    Field('slaId', String, 'SLA ID'),
    Field('slaName', String, 'SLA Name', required: true),
    Field('slaDescription', String, 'Description'),
    Field('slaMetric', String, 'Metric',
        hint: 'What is measured'),
    Field('slaTarget', String, 'Target',
        hint: 'Target value'),
    Field('slaMeasurementMethod', String, 'Measurement Method'),
    Field('slaReportingFrequency', String, 'Reporting Frequency'),
    Field('slaPenalty', String, 'Penalty',
        hint: 'Consequence of missing SLA'),
    Field('slaExclusions', String, 'Exclusions',
        hint: 'What is excluded from SLA'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.4.3. Monitoring quality.
@SectionId('MOQU')
class OperationalMonitoring {
  @Form([
    Field('scalabilityMonitoringApproach', String, 'Scalability Monitoring',
        hint: 'Auto-scaling triggers, capacity alerts'),
    Field('capacityPlanningProcess', String, 'Capacity Planning Process',
        hint: 'How capacity is planned'),
    Field('growthProjections', String, 'Growth Projections',
        hint: 'Expected growth rate'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Component monitoring coverage.
  @SerializationOrder(1)
  MonitoringCoverage coverage = MonitoringCoverage();

  /// Alert automation capabilities.
  @SerializationOrder(2)
  MonitoringAutomation automation = MonitoringAutomation();

  /// Alerting strategy and channels.
  @SerializationOrder(3)
  MonitoringAlerting alerting = MonitoringAlerting();

  /// Planning and observability settings.
  @SerializationOrder(4)
  MonitoringOperations operations = MonitoringOperations();

  /// Detailed monitoring requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// Component monitoring coverage.
@SectionId('MOQUCO')
class MonitoringCoverage {
  @Form([
    Field('infrastructureMonitoring', String, 'Infrastructure Monitoring',
        hint: 'Servers, containers, network'),
    Field('applicationMonitoring', String, 'Application Monitoring',
        hint: 'APM, logs, traces'),
    Field('databaseMonitoring', String, 'Database Monitoring',
        hint: 'Queries, connections, storage'),
    Field('thirdPartyMonitoring', String, 'Third-Party Monitoring',
        hint: 'External service monitoring'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Alert automation capabilities.
@SectionId('MOQUAU')
class MonitoringAutomation {
  @Form([
    Field('alertAutomation', String, 'Alert Automation',
        hint: 'Automated response to alerts'),
    Field('selfHealingCapability', String, 'Self-Healing Capability',
        hint: 'Auto-recovery mechanisms'),
    Field('runbookAutomation', String, 'Runbook Automation',
        hint: 'Automated runbook execution'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Alerting strategy and channels.
@SectionId('MOQUAL')
class MonitoringAlerting {
  @Form([
    Field('alertingStrategy', String, 'Alerting Strategy',
        hint: 'Threshold-based, anomaly detection'),
    Field('alertPrioritization', String, 'Alert Prioritization',
        hint: 'How alerts are prioritized'),
    Field('alertNotificationChannels', String, 'Notification Channels',
        hint: 'Slack, PagerDuty, email, SMS'),
    Field('alertFatiguePrevention', String, 'Alert Fatigue Prevention',
        hint: 'De-duplication, correlation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Planning and observability settings.
@SectionId('MOQUOP')
class MonitoringOperations {
  @Form([
    Field('resourcePlanningFrequency', String, 'Resource Planning Frequency',
        hint: 'Quarterly, annually'),
    Field('proactiveMaintenanceSchedule', String, 'Proactive Maintenance',
        hint: 'Scheduled maintenance activities'),
    Field('observabilityPillars', String, 'Observability Pillars',
        hint: 'Logs, metrics, traces'),
    Field('distributedTracingRequirement', String, 'Distributed Tracing',
        hint: 'Tracing implementation'),
    Field('logRetentionPeriod', String, 'Log Retention Period',
        hint: 'How long logs are kept'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.4.4. IT Security Operations quality.
@SectionId('ISOQ')
class ItSecurityOperations {
  @Form([
    Field('accessControlModel', String, 'Access Control Model',
        hint: 'RBAC, ABAC, zero-trust'),
    Field('drPlanRequired', bool, 'DR Plan Required'),
    Field('incidentResponsePlan', String, 'Incident Response Plan',
        hint: 'NIST, custom'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Access protection controls.
  @SerializationOrder(1)
  ItSecurityOperationsAccess access =
      ItSecurityOperationsAccess();

  /// Disaster recovery planning details.
  @SerializationOrder(2)
  ItSecurityOperationsRecovery recovery =
      ItSecurityOperationsRecovery();

  /// Penetration testing and remediation.
  @SerializationOrder(3)
  ItSecurityOperationsTesting testing =
      ItSecurityOperationsTesting();

  /// Incident handling and reporting.
  @SerializationOrder(4)
  ItSecurityOperationsIncident incident =
      ItSecurityOperationsIncident();

  /// Detailed IT security operations narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// Access protection controls.
@SectionId('ISOQA')
class ItSecurityOperationsAccess {
  @Form([
    Field('privilegedAccessManagement', String, 'Privileged Access Management',
        hint: 'PAM solution, just-in-time'),
    Field('accessReviewFrequency', String, 'Access Review Frequency',
        hint: 'Quarterly, annually'),
    Field('accessAuditLogging', String, 'Access Audit Logging',
        hint: 'What access is logged'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Disaster recovery planning details.
@SectionId('ISOQR')
class ItSecurityOperationsRecovery {
  @Form([
    Field('drTestingFrequency', String, 'DR Testing Frequency',
        hint: 'Annual, semi-annual'),
    Field('drRecoveryTargets', String, 'DR Recovery Targets',
        hint: 'RTO/RPO for DR scenarios'),
    Field('drDataCenterStrategy', String, 'Data Center Strategy',
        hint: 'Multi-region, hot/warm/cold'),
    Field('drCommunicationPlan', String, 'DR Communication Plan',
        hint: 'How stakeholders are notified'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Penetration testing and remediation.
@SectionId('ISOQT')
class ItSecurityOperationsTesting {
  @Form([
    Field('penetrationTestScope', String, 'Penetration Test Scope',
        hint: 'Internal, external, both'),
    Field('penetrationTestFrequency', String, 'Penetration Test Frequency',
        hint: 'Annual, per-release'),
    Field('vulnerabilitySlaResolution', String, 'Vulnerability SLA',
        hint: 'Resolution timeframes by severity'),
    Field('bugBountyProgram', bool, 'Bug Bounty Program'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Incident handling and reporting.
@SectionId('ISOQI')
class ItSecurityOperationsIncident {
  @Form([
    Field('securityIncidentClassification', String, 'Incident Classification',
        hint: 'Severity levels'),
    Field('securityIncidentNotification', String, 'Incident Notification',
        hint: 'Who is notified, when'),
    Field('forensicsCapability', String, 'Forensics Capability',
        hint: 'Evidence preservation'),
    Field('regulatoryReporting', String, 'Regulatory Reporting',
        hint: 'Breach notification requirements'),
  ])
  @SerializationOrder(0)
  String? content;
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
@SectionId('DOQUCR')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-DOC')
class DocumentationQualityCriteria {
  // ─────────────────────────────────────────────────────────────────────────
  // Documentation Quality Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('documentationStrategy', String, 'Documentation Strategy',
        hint: 'Comprehensive, minimal, just-in-time'),
    Field('documentationOwnership', String, 'Documentation Ownership',
        hint: 'Technical writers, developers, shared'),
    Field('documentationPlatform', String, 'Documentation Platform',
        hint: 'Confluence, GitBook, custom'),
    Field('documentationReviewProcess', String, 'Review Process',
        hint: 'Peer review, editorial review'),
    Field('documentationVersionControl', String, 'Version Control',
        hint: 'Git, CMS versioning, manual'),
    Field('documentationUpdateCadence', String, 'Update Cadence',
        hint: 'Continuous, per-release, scheduled'),
  ])
  @SerializationOrder(0)
  String? documentationOverviewContent;

  /// Documentation quality overview narrative.
  @ContentHelp('Executive summary of documentation goals, '
      'target audiences, and key documentation metrics.')
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
@SectionId('REQU1')
class Readability {
  @Form([
    Field('terminologyStandard', String, 'Terminology Standard',
        hint: 'Glossary, controlled vocabulary'),
    Field('ambiguityPrevention', String, 'Ambiguity Prevention',
        hint: 'Review checklist, automated checks'),
    Field('jargonPolicy', String, 'Jargon Policy',
        hint: 'Define all terms, minimize jargon'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Identifiability and navigation.
  @SerializationOrder(1)
  ReadabilityNavigation navigation = ReadabilityNavigation();

  /// Comprehensibility requirements.
  @SerializationOrder(2)
  ReadabilityComprehensibility comprehensibility =
      ReadabilityComprehensibility();

  /// Document structure rules.
  @SerializationOrder(3)
  ReadabilityStructure structure = ReadabilityStructure();

  /// Style guide alignment.
  @SerializationOrder(4)
  ReadabilityStyle style = ReadabilityStyle();

  /// Detailed readability requirements narrative.
  @SerializationOrder(5)
  TextSection narrative = TextSection();
}

/// Identifiability and navigation.
@SectionId('REQUNA')
class ReadabilityNavigation {
  @Form([
    Field('sectionNumbering', String, 'Section Numbering',
        hint: 'Hierarchical, flat, none'),
    Field('crossReferenceStandard', String, 'Cross-Reference Standard',
        hint: 'Section IDs, hyperlinks'),
    Field('searchability', String, 'Searchability',
        hint: 'Full-text search, tagged'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Comprehensibility requirements.
@SectionId('REQUCO')
class ReadabilityComprehensibility {
  @Form([
    Field('readingLevelTarget', String, 'Reading Level Target',
        hint: 'Grade level, technical audience'),
    Field('formatStandards', String, 'Format Standards',
        hint: 'Headings, lists, tables usage'),
    Field('visualAidRequirements', String, 'Visual Aid Requirements',
        hint: 'Diagrams, screenshots, examples'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Document structure rules.
@SectionId('REQUST')
class ReadabilityStructure {
  @Form([
    Field('documentStructureTemplate', String, 'Structure Template',
        hint: 'Standard document templates'),
    Field('informationHierarchy', String, 'Information Hierarchy',
        hint: 'How information is organized'),
    Field('navigationAids', String, 'Navigation Aids',
        hint: 'TOC, index, breadcrumbs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Style guide alignment.
@SectionId('REQUS1')
class ReadabilityStyle {
  @Form([
    Field('styleGuideReference', String, 'Style Guide Reference',
        hint: 'Google, Microsoft, custom'),
    Field('writingVoice', String, 'Writing Voice',
        hint: 'Active, passive, imperative'),
    Field('formattingConventions', String, 'Formatting Conventions',
        hint: 'Code, commands, UI elements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.5.2. Documentation completeness quality.
@SectionId('DOCOQU')
class DocCompleteness {
  @Form([
    // Topic coverage
    Field('requiredTopics', String, 'Required Topics',
        hint: 'List of required documentation topics'),
    Field('topicCoverageTarget', String, 'Topic Coverage Target %',
        hint: '100% of required, 80% of optional'),
    Field('audienceCoverage', String, 'Audience Coverage',
        hint: 'End users, admins, developers'),
    // Detail level
    Field('detailLevelExpectation', String, 'Detail Level Expectation',
        hint: 'Comprehensive, overview, reference'),
    Field('exampleRequirements', String, 'Example Requirements',
        hint: 'Examples for all features, key features'),
    Field('screenshotRequirements', String, 'Screenshot Requirements',
        hint: 'All UI, key workflows'),
    // Cross-reference
    Field('crossReferenceIntegrity', String, 'Cross-Reference Integrity',
        hint: 'Automated link checking'),
    Field('relatedTopicsLinking', String, 'Related Topics Linking',
        hint: 'Manual, automated suggestions'),
    // Verification
    Field('completenessReview', String, 'Completeness Review',
        hint: 'Checklist, traceability matrix'),
    Field('gapIdentificationProcess', String, 'Gap Identification',
        hint: 'User feedback, coverage reports'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Detailed completeness requirements narrative.
  @SerializationOrder(1)
  TextSection narrative = TextSection();
}

/// 11.5.3. Documentation correctness quality.
@SectionId('DOCOQ1')
class DocCorrectness {
  @Form([
    // Error-freedom
    Field('spellingGrammarCheck', String, 'Spelling/Grammar Check',
        hint: 'Automated tools, manual review'),
    Field('technicalAccuracyReview', String, 'Technical Accuracy Review',
        hint: 'SME review, testing against product'),
    Field('errorToleranceLevel', String, 'Error Tolerance Level',
        hint: 'Zero errors, minor allowed'),
    // Consistency
    Field('terminologyConsistency', String, 'Terminology Consistency',
        hint: 'Glossary enforcement'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Formatting and implementation alignment.
  @SerializationOrder(1)
  DocCorrectnessAlignment alignment = DocCorrectnessAlignment();

  /// Verification and feedback handling.
  @SerializationOrder(2)
  DocCorrectnessVerification verification =
      DocCorrectnessVerification();

  /// Detailed correctness requirements narrative.
  @SerializationOrder(3)
  TextSection narrative = TextSection();
}

/// Formatting and implementation alignment.
@SectionId('DCQA')
class DocCorrectnessAlignment {
    @Form([
        Field('formatConsistency', String, 'Format Consistency',
                hint: 'Template adherence'),
        Field('crossDocumentConsistency', String, 'Cross-Document Consistency',
                hint: 'Consistency across documents'),
        Field('documentationSyncProcess', String, 'Documentation Sync Process',
                hint: 'How docs stay aligned with code'),
        Field('versionAlignment', String, 'Version Alignment',
                hint: 'Docs versioned with product'),
        Field('deprecationHandling', String, 'Deprecation Handling',
                hint: 'How deprecated features are handled'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Verification and feedback handling.
@SectionId('DCQV')
class DocCorrectnessVerification {
    @Form([
        Field('correctnessVerification', String, 'Correctness Verification',
                hint: 'Testing docs against product'),
        Field('userFeedbackIntegration', String, 'User Feedback Integration',
                hint: 'How user-reported errors are handled'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 11.5.4. Documentation changeability quality.
@SectionId('DOCHQU')
class DocChangeability {
  @Form([
    Field('versioningStrategy', String, 'Versioning Strategy',
        hint: 'Semantic, date-based, product-aligned'),
    Field('versionHistoryTracking', String, 'Version History Tracking',
        hint: 'Changelog, git history'),
    Field('multiVersionSupport', String, 'Multi-Version Support',
        hint: 'Multiple product versions documented'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Extensibility and localization readiness.
  @SerializationOrder(1)
  DocChangeabilityExtensibility extensibility =
      DocChangeabilityExtensibility();

  /// Sizing and structural consistency rules.
  @SerializationOrder(2)
  DocChangeabilityStructure structure =
      DocChangeabilityStructure();

  /// Review and retirement maintenance process.
  @SerializationOrder(3)
  DocChangeabilityMaintenance maintenance =
      DocChangeabilityMaintenance();

  /// Detailed changeability requirements narrative.
  @SerializationOrder(4)
  TextSection narrative = TextSection();
}

/// Extensibility and localization readiness.
@SectionId('DCQE')
class DocChangeabilityExtensibility {
  @Form([
    Field('extensibilityApproach', String, 'Extensibility Approach',
        hint: 'Modular, template-based'),
    Field('newSectionGuidelines', String, 'New Section Guidelines',
        hint: 'How to add new content'),
    Field('localizationReadiness', String, 'Localization Readiness',
        hint: 'i18n considerations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Sizing and structural consistency rules.
@SectionId('DCQS')
class DocChangeabilityStructure {
  @Form([
    Field('documentSizingGuideline', String, 'Document Sizing',
        hint: 'Max pages, when to split'),
    Field('topicGranularity', String, 'Topic Granularity',
        hint: 'One topic per page, combined'),
    Field('templateAdherence', String, 'Template Adherence',
        hint: 'Required, recommended'),
    Field('structuralChangeProcess', String, 'Structural Change Process',
        hint: 'How structure changes are made'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Review and retirement maintenance process.
@SectionId('DCQM')
class DocChangeabilityMaintenance {
  @Form([
    Field('reviewCycle', String, 'Review Cycle',
        hint: 'Periodic review schedule'),
    Field('retirementProcess', String, 'Retirement Process',
        hint: 'How outdated docs are retired'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.6. Quality Prioritization.
///
/// Prioritization and balancing of quality attributes including weighted
/// matrices and explicit trade-off decisions.
@SectionId('QUPR')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-PRI')
class QualityPrioritization {
  // ─────────────────────────────────────────────────────────────────────────
  // Prioritization Framework
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('prioritizationMethod', String, 'Prioritization Method',
        hint: 'Weighted scoring, AHP, forced ranking'),
    Field('prioritizationStakeholders', String, 'Prioritization Stakeholders',
        hint: 'Who participates in prioritization'),
    Field('prioritizationFrequency', String, 'Prioritization Frequency',
        hint: 'Once, per-phase, continuous'),
    Field('prioritizationDocumentation', String, 'Prioritization Documentation',
        hint: 'How decisions are documented'),
    Field('prioritizationReview', String, 'Prioritization Review',
        hint: 'When priorities are reviewed'),
    Field('conflictResolutionAuthority', String, 'Conflict Resolution Authority',
        hint: 'Who resolves priority conflicts'),
  ])
  @SerializationOrder(0)
  String? prioritizationFrameworkContent;

  /// Prioritization approach overview.
  @ContentHelp('Overview of how quality attributes are prioritized, '
      'including stakeholder involvement and decision process.')
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
@SectionId('WEQUMA')
class WeightedQualityMatrix {
  @Form([
    Field('matrixFormat', String, 'Matrix Format',
        hint: 'Spreadsheet, radar chart, heatmap'),
    Field('weightingScale', String, 'Weighting Scale',
        hint: '1-5, 1-10, percentage'),
    Field('totalWeightRequirement', String, 'Total Weight Requirement',
        hint: 'Sum to 100%, relative weights'),
    Field('weightJustificationRequired', bool, 'Weight Justification Required'),
    Field('matrixUpdateProcess', String, 'Matrix Update Process',
        hint: 'How weights are updated'),
  ])
  @SerializationOrder(0)
  String? matrixConfigContent;

  /// Weighted quality matrix narrative.
  @ContentHelp('Description of weighted quality matrix including '
      'weights assigned to each attribute and rationale.')
  @SerializationOrder(1)
  TextSection matrixNarrative = TextSection();

  /// Quality attribute weight entries.
  @SectionId('QLWGT-WEIG-LST')
  @SectionIdPattern('QLWGT-WEIG-xxx')
  @SerializationOrder(2)
  List<QualityWeightEntry> weights = [];

  /// Quality matrix visualization.
  @ContentHelp('Visual representation of quality attribute priorities.')
  @SerializationOrder(3)
  DiagramSection matrixVisualization = DiagramSection();
}

/// A quality weight entry.
@SectionId('QLWGT')
class QualityWeightEntry {
  @Form([
    Field('qualityAttribute', String, 'Quality Attribute', required: true),
    Field('qualityCategory', String, 'Category',
        hint: 'User, Technical, Operations, Documentation'),
    Field('weight', int, 'Weight (1-100)'),
    Field('priority', String, 'Priority',
        hint: 'Critical, high, medium, low'),
    Field('rationale', String, 'Rationale',
        hint: 'Why this weight'),
    Field('stakeholderAgreement', String, 'Stakeholder Agreement',
        hint: 'Who agreed to this weight'),
    Field('tradeOffImplications', String, 'Trade-off Implications',
        hint: 'What this priority means for other attributes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.6.2. Trade-off Decisions.
///
/// Explicit trade-off decisions between quality attributes.
@SectionId('TROFDE')
class TradeOffDecisions {
  @Form([
    Field('tradeOffGovernance', String, 'Trade-off Governance',
        hint: 'Who can make trade-off decisions'),
    Field('tradeOffDocumentation', String, 'Trade-off Documentation',
        hint: 'How decisions are documented'),
    Field('tradeOffReview', String, 'Trade-off Review',
        hint: 'When trade-offs are reviewed'),
    Field('tradeOffReversal', String, 'Trade-off Reversal',
        hint: 'Process to reverse a trade-off decision'),
  ])
  @SerializationOrder(0)
  String? tradeOffGovernanceContent;

  /// Trade-off decisions overview.
  @ContentHelp('Overview of major trade-off decisions and their impact '
      'on system quality and design choices.')
  @SerializationOrder(1)
  TextSection tradeOffOverview = TextSection();

  /// Contains 0+× TradeOffDecision.
  @SectionId('TODE-ITEM-LST')
  @SectionIdPattern('TODE-ITEM-xxx')
  @SerializationOrder(2)
  List<TradeOffDecisionEntry> items = [];
}

/// A trade-off decision entry (form).
@SectionId('TODE')
class TradeOffDecisionEntry {
  @Form([
    Field('decisionId', String, 'Decision ID',
        hint: 'Unique identifier (e.g., TRADEOFF-001)'),
    Field('decisionTitle', String, 'Decision Title', required: true),
    Field('decisionStatus', String, 'Status',
        hint: 'Proposed, approved, implemented, reversed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Qualities in conflict.
  @SerializationOrder(1)
  TradeOffDecisionEntryQualities qualities = TradeOffDecisionEntryQualities();

  /// Rationale for trade-off.
  @SerializationOrder(2)
  TradeOffDecisionEntryRationale rationale = TradeOffDecisionEntryRationale();

  /// Impact assessment.
  @SerializationOrder(3)
  TradeOffDecisionEntryImpact impact = TradeOffDecisionEntryImpact();

  /// Mitigation measures.
  @SerializationOrder(4)
  TradeOffDecisionEntryMitigation mitigation =
      TradeOffDecisionEntryMitigation();

  /// Approval and governance.
  @SerializationOrder(5)
  TradeOffDecisionEntryApproval approval = TradeOffDecisionEntryApproval();

  /// Detailed trade-off analysis.
  @ContentHelp('Extended analysis of trade-off decision including '
      'quantitative impact assessment.')
  @SerializationOrder(6)
  TextSection detailedAnalysis = TextSection();
}

/// Qualities in conflict for trade-off decision.
@SectionId('TODEQ')
class TradeOffDecisionEntryQualities {
  @Form([
    Field('prioritizedQuality', String, 'Prioritized Quality', required: true,
        hint: 'Quality attribute given priority'),
    Field('deprioritizedQuality', String, 'Deprioritized Quality', required: true,
        hint: 'Quality attribute traded off'),
    Field('additionalQualitiesAffected', String, 'Additional Qualities Affected',
        hint: 'Other qualities impacted'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Rationale for trade-off decision.
@SectionId('TODER')
class TradeOffDecisionEntryRationale {
  @Form([
    Field('businessRationale', String, 'Business Rationale',
        hint: 'Business reason for trade-off'),
    Field('technicalRationale', String, 'Technical Rationale',
        hint: 'Technical considerations'),
    Field('constraintsInfluencing', String, 'Constraints Influencing',
        hint: 'Constraints that drove decision'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint: 'Other approaches evaluated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Impact assessment for trade-off decision.
@SectionId('TODEI')
class TradeOffDecisionEntryImpact {
  @Form([
    Field('impactOnRequirements', String, 'Impact on Requirements',
        hint: 'Requirements affected'),
    Field('impactOnArchitecture', String, 'Impact on Architecture',
        hint: 'Architectural implications'),
    Field('impactOnSchedule', String, 'Impact on Schedule',
        hint: 'Schedule implications'),
    Field('impactOnCost', String, 'Impact on Cost',
        hint: 'Cost implications'),
    Field('impactOnUserExperience', String, 'Impact on User Experience',
        hint: 'UX implications'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Mitigation measures for trade-off decision.
@SectionId('TODEM')
class TradeOffDecisionEntryMitigation {
  @Form([
    Field('mitigationMeasures', String, 'Mitigation Measures',
        hint: 'How deprioritized quality is mitigated'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria',
        hint: 'Minimum acceptable level'),
    Field('monitoringApproach', String, 'Monitoring Approach',
        hint: 'How impact is monitored'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Approval and governance for trade-off decision.
@SectionId('TODEA')
class TradeOffDecisionEntryApproval {
  @Form([
    Field('decisionDate', String, 'Decision Date'),
    Field('approvedBy', String, 'Approved By',
        hint: 'Who approved the trade-off'),
    Field('stakeholdersConsulted', String, 'Stakeholders Consulted',
        hint: 'Who was consulted'),
    Field('reviewDate', String, 'Review Date',
        hint: 'When decision will be reviewed'),
  ])
  @SerializationOrder(0)
  String? content;
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
@SectionId('ACCRSU')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-ACC')
class AcceptanceCriteriaSummary {
  // ─────────────────────────────────────────────────────────────────────────
  // Acceptance Framework
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('acceptanceProcess', String, 'Acceptance Process',
        hint: 'Formal UAT, continuous acceptance'),
    Field('acceptanceAuthority', String, 'Acceptance Authority',
        hint: 'Who signs off on acceptance'),
    Field('acceptanceScope', String, 'Acceptance Scope',
        hint: 'Full system, incremental, phase-based'),
    Field('acceptanceEnvironment', String, 'Acceptance Environment',
        hint: 'Where acceptance testing occurs'),
    Field('acceptanceTimeline', String, 'Acceptance Timeline',
        hint: 'Duration of acceptance period'),
    Field('partialAcceptance', String, 'Partial Acceptance',
        hint: 'Policy on accepting with defects'),
    Field('acceptanceRejectionCriteria', String, 'Rejection Criteria',
        hint: 'What triggers rejection'),
  ])
  @SerializationOrder(0)
  String? acceptanceFrameworkContent;

  /// Acceptance criteria overview.
  @ContentHelp('Overview of acceptance process, key acceptance criteria, '
      'and acceptance governance.')
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
@SectionId('MUPACR')
class MustPassCriteria {
  @Form([
    Field('mustPassPhilosophy', String, 'Must-Pass Philosophy',
        hint: 'All must pass, weighted approach'),
    Field('mustPassCount', int, 'Number of Must-Pass Criteria'),
    Field('criticalityDefinition', String, 'Criticality Definition',
        hint: 'What makes a criterion must-pass'),
    Field('waiverProcess', String, 'Waiver Process',
        hint: 'Can must-pass criteria be waived'),
    Field('waiverAuthority', String, 'Waiver Authority',
        hint: 'Who can grant waivers'),
  ])
  @SerializationOrder(0)
  String? mustPassOverviewContent;

  /// Must-pass criteria overview.
  @ContentHelp('Overview of must-pass criteria approach and '
      'rationale for selection.')
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× MustPassCriterion.
  @SectionId('MSTPCR-ITEM-LST')
  @SectionIdPattern('MSTPCR-ITEM-xxx')
  @SerializationOrder(2)
  List<MustPassCriterionEntry> items = [];
}

/// A must-pass criterion entry (form).
@SectionId('MSTPCR')
class MustPassCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID',
        hint: 'Unique identifier (e.g., MP-001)'),
    Field('criterionName', String, 'Criterion Name', required: true),
    Field('verificationMethod', String, 'Verification Method', required: true,
        hint: 'Test, demonstration, analysis, inspection'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Classification and intent of the criterion.
  @SerializationOrder(1)
  MustPassCriterionEntryDefinition definition =
      MustPassCriterionEntryDefinition();

  /// Verification and threshold details.
  @SerializationOrder(2)
  MustPassCriterionEntryVerification verification =
      MustPassCriterionEntryVerification();

  /// Responsibility and dependency information.
  @SerializationOrder(3)
  MustPassCriterionEntryGovernance governance =
      MustPassCriterionEntryGovernance();

  /// Execution status and defects.
  @SerializationOrder(4)
  MustPassCriterionEntryStatus status = MustPassCriterionEntryStatus();

  /// Additional criterion details.
  @ContentHelp('Extended description of criterion including '
      'edge cases and special considerations.')
  @SerializationOrder(5)
  TextSection details = TextSection();
}

/// Classification and intent of the criterion.
@SectionId('MPCED')
class MustPassCriterionEntryDefinition {
  @Form([
    Field('criterionDescription', String, 'Description',
        hint: 'What must be achieved'),
    Field('qualityCategory', String, 'Quality Category',
        hint: 'User, Technical, Operations, Documentation'),
    Field('qualityAttribute', String, 'Quality Attribute',
        hint: 'Specific attribute this relates to'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification and threshold details.
@SectionId('MPCEV')
class MustPassCriterionEntryVerification {
  @Form([
    Field('verificationProcedure', String, 'Verification Procedure',
        hint: 'Steps to verify'),
    Field('verificationEvidence', String, 'Verification Evidence',
        hint: 'What evidence is required'),
    Field('acceptanceThreshold', String, 'Acceptance Threshold', required: true,
        hint: 'Pass/fail criteria'),
    Field('measurementMethod', String, 'Measurement Method',
        hint: 'How threshold is measured'),
    Field('toleranceAllowed', String, 'Tolerance Allowed',
        hint: 'Any acceptable variance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Responsibility and dependency information.
@SectionId('MPCEG')
class MustPassCriterionEntryGovernance {
  @Form([
    Field('responsibleParty', String, 'Responsible Party',
        hint: 'Who is responsible for verification'),
    Field('reviewerParty', String, 'Reviewer Party',
        hint: 'Who reviews the evidence'),
    Field('approverParty', String, 'Approver Party',
        hint: 'Who approves the result'),
    Field('dependsOnCriteria', String, 'Depends On',
        hint: 'Other criteria this depends on'),
    Field('blockedByCriteria', String, 'Blocked By',
        hint: 'Criteria that block this'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Execution status and defects.
@SectionId('MPCES')
class MustPassCriterionEntryStatus {
  @Form([
    Field('criterionStatus', String, 'Status',
        hint: 'Not tested, passed, failed, waived'),
    Field('testDate', String, 'Test Date'),
    Field('testResult', String, 'Test Result'),
    Field('defectIds', String, 'Defect IDs',
        hint: 'Defects blocking pass'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 11.7.2. Quality Gate Checklist.
///
/// Quality gate checklist used during acceptance.
@SectionId('QUGACH')
class QualityGateChecklist {
  @Form([
    Field('checklistPurpose', String, 'Checklist Purpose',
        hint: 'Gate review, final acceptance, milestone'),
    Field('checklistCompleteness', String, 'Completeness Requirement',
        hint: 'All checks required, critical only'),
    Field('checklistReviewProcess', String, 'Review Process',
        hint: 'Individual, committee, automated'),
    Field('checklistSignoff', String, 'Signoff Requirement',
        hint: 'Single, multiple signoffs'),
    Field('checklistFrequency', String, 'Checklist Frequency',
        hint: 'When checklist is used'),
  ])
  @SerializationOrder(0)
  String? checklistOverviewContent;

  /// Quality gate checklist overview.
  @ContentHelp('Overview of quality gate process and checklist usage.')
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× QualityGateCheck.
  @SectionId('QGCHK-ITEM-LST')
  @SectionIdPattern('QGCHK-ITEM-xxx')
  @SerializationOrder(2)
  List<QualityGateCheckEntry> items = [];
}

/// A quality gate check entry (form).
@SectionId('QGCHK')
class QualityGateCheckEntry {
  @Form([
    Field('checkId', String, 'Check ID',
        hint: 'Unique identifier (e.g., QGC-001)'),
    Field('checkItem', String, 'Check Item', required: true,
        hint: 'What is being checked'),
    Field('verificationMethod', String, 'Verification Method', required: true,
        hint: 'How check is verified'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Check definition and categorization.
  @SerializationOrder(1)
  QualityGateCheckEntryDefinition definition =
      QualityGateCheckEntryDefinition();

  /// Verification criteria and evidence.
  @SerializationOrder(2)
  QualityGateCheckEntryVerification verification =
      QualityGateCheckEntryVerification();

  /// Responsibility and timing.
  @SerializationOrder(3)
  QualityGateCheckEntryExecution execution = QualityGateCheckEntryExecution();

  /// Status and observations.
  @SerializationOrder(4)
  QualityGateCheckEntryStatus status = QualityGateCheckEntryStatus();

  /// Blocking behavior.
  @SerializationOrder(5)
  QualityGateCheckEntryBlocking blocking = QualityGateCheckEntryBlocking();
}

/// Check definition and categorization.
@SectionId('QGCED')
class QualityGateCheckEntryDefinition {
  @Form([
    Field('checkDescription', String, 'Check Description',
        hint: 'Detailed description of check'),
    Field('checkCategory', String, 'Check Category',
        hint: 'Category of check'),
    Field('qualityCategory', String, 'Quality Category',
        hint: 'User, Technical, Operations, Documentation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification criteria and evidence.
@SectionId('QGCEV')
class QualityGateCheckEntryVerification {
  @Form([
    Field('verificationCriteria', String, 'Verification Criteria',
        hint: 'Pass/fail criteria'),
    Field('evidenceRequired', String, 'Evidence Required',
        hint: 'What evidence is needed'),
    Field('automatedCheck', bool, 'Automated Check',
        hint: 'Is check automated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Responsibility and timing.
@SectionId('QGCEE')
class QualityGateCheckEntryExecution {
  @Form([
    Field('responsibleParty', String, 'Responsible Party', required: true,
        hint: 'Who performs the check'),
    Field('reviewerParty', String, 'Reviewer Party',
        hint: 'Who reviews the result'),
    Field('checkTiming', String, 'Check Timing',
        hint: 'When check is performed'),
    Field('checkDuration', String, 'Check Duration',
        hint: 'Expected time to complete'),
    Field('checkDependencies', String, 'Dependencies',
        hint: 'What must be complete first'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Status and observations.
@SectionId('QGCES')
class QualityGateCheckEntryStatus {
  @Form([
    Field('checkStatus', String, 'Status',
        hint: 'Not started, in progress, passed, failed'),
    Field('checkDate', String, 'Check Date'),
    Field('checkResult', String, 'Check Result'),
    Field('checkNotes', String, 'Notes',
        hint: 'Additional observations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Blocking behavior.
@SectionId('QGCEB')
class QualityGateCheckEntryBlocking {
  @Form([
    Field('isBlocking', bool, 'Is Blocking',
        hint: 'Does failure block acceptance'),
    Field('blockingRationale', String, 'Blocking Rationale',
        hint: 'Why this check blocks'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 11.8 Test Strategy
// ---------------------------------------------------------------------------

/// 11.8. Test Strategy.
///
/// Overall test strategy for the project..
@SectionId('TEST')
@DetailedIn(D10QualityAcceptancePlan)
@SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-TST')
class TestStrategy {
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
  @SerializationOrder(0)
  String? content;
}

/// A single category dependency entry.
@SectionId('CATEG')
class CategoryDependencyEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single attribute interdependency entry.
@SectionId('ATTRI')
class AttributeInterdependencyEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}
