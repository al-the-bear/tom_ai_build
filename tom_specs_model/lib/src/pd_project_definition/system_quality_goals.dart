/// Section 11: System Quality Goals [PD00-SYQ]. Seeds → BQP.
///
/// Quality goals for acceptance testing, organized by quality category.
/// Comprehensive quality management framework covering user-related,
/// technical, operational, and documentation quality attributes.
/// Follows ISO/IEC 25010 (SQuaRE) quality model and enterprise QA practices.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 11. System Quality Goals [PD00-SYQ]. Seeds → BQP.
///
/// Quality goals selected from standard quality criteria and operationalized
/// for project-specific acceptance testing. Provides governing structure for
/// all quality attributes and acceptance criteria. Seeds the BQP (Business
/// Quality Plan) document where quality goals are expanded into measurable
/// targets, verification methods, and acceptance criteria.
@SectionId('SYQG')
@Comment('Seeds → BQP')
@MapsTo(BusinessQualityPlan)
class SystemQualityGoals {
  @Form([
    Field('qualityApproach', String, 'Quality Approach',
        hint: 'Overall quality philosophy: proactive, reactive, hybrid'),
    Field('qualityStandards', String, 'Applicable Quality Standards',
        hint: 'ISO 25010, ISO 9001, CMMI, industry-specific'),
    Field('qualityOwner', String, 'Quality Owner',
        hint: 'Role accountable for quality outcomes'),
  ])
  String? governanceContent;

  /// Governance board and escalation details.
  SystemQualityGoalsGovernance governance = SystemQualityGoalsGovernance();

  /// Baseline and target settings.
  SystemQualityGoalsBaseline baseline = SystemQualityGoalsBaseline();

  /// Measurement and reporting approach.
  SystemQualityGoalsMeasurement measurement = SystemQualityGoalsMeasurement();

  /// Quality resources and enablement.
  SystemQualityGoalsResources resources = SystemQualityGoalsResources();

  /// Executive summary of quality goals and approach.
  @ContentHelp('High-level overview of quality objectives, expected quality '
      'level, key quality risks, and approach summary.')
  TextSection executiveSummary = TextSection();

  /// Quality vision and principles.
  @ContentHelp('Quality vision statement, core principles guiding '
      'quality decisions, and non-negotiable quality standards.')
  TextSection qualityVision = TextSection();

  /// Quality assurance strategy.
  @ContentHelp('Overall QA strategy: shift-left testing, continuous testing, '
      'test pyramid approach, verification vs validation approach.')
  TextSection qaStrategy = TextSection();

  /// Quality attribute interdependencies.
  @ContentHelp('How quality attributes relate to and affect each other, '
      'known tensions and resolution approaches.')
  TextSection attributeInterdependencies = TextSection();

  /// Quality attribute priority radar.
  @ContentHelp('Visual showing relative importance of quality attributes.')
  DiagramSection qualityRadar = DiagramSection();

  /// 11.1. Quality Framework [PD00-SYQ-FRA].
  QualityFramework framework = QualityFramework();

  /// 11.2. User-Related Quality Criteria [PD00-SYQ-USE].
  UserQualityCriteria userQuality = UserQualityCriteria();

  /// 11.3. Technical Quality Criteria [PD00-SYQ-TEC].
  TechnicalQualityCriteria technicalQuality = TechnicalQualityCriteria();

  /// 11.4. Operations Quality Criteria [PD00-SYQ-OPE].
  OperationsQualityCriteria operationsQuality = OperationsQualityCriteria();

  /// 11.5. Documentation Quality Criteria [PD00-SYQ-DOC].
  DocumentationQualityCriteria documentationQuality =
      DocumentationQualityCriteria();

  /// 11.6. Quality Prioritization [PD00-SYQ-PRI].
  QualityPrioritization prioritization = QualityPrioritization();

  /// 11.7. Acceptance Criteria Summary [PD00-SYQ-ACC].
  AcceptanceCriteriaSummary acceptanceCriteria = AcceptanceCriteriaSummary();

  /// 11.8. Test Strategy [PD00-SYQ-TST]. Covers HBSG AS23.
  TestStrategy testStrategy = TestStrategy();
}

/// Governance board and escalation details.
@SectionId('SQGGV')
class SystemQualityGoalsGovernance {
    @Form([
        Field('qualityReviewBoard', String, 'Quality Review Board',
                hint: 'Governance body for quality decisions'),
        Field('qualityMeetingCadence', String, 'Quality Meeting Cadence',
                hint: 'Weekly, bi-weekly, sprint-aligned'),
        Field('qualityEscalationPath', String, 'Escalation Path',
                hint: 'How quality issues escalate to leadership'),
    ])
    String? content;
}

/// Baseline and target settings.
@SectionId('SQGBS')
class SystemQualityGoalsBaseline {
    @Form([
        Field('qualityBaselineDate', String, 'Quality Baseline Date',
                hint: 'When quality targets were baselined'),
        Field('qualityBaselineVersion', String, 'Baseline Version'),
        Field('overallQualityTargetLevel', String, 'Overall Quality Target Level',
                hint: 'High, production-grade, MVP-acceptable'),
        Field('qualityRiskTolerance', String, 'Quality Risk Tolerance',
                hint: 'Low (zero defects), medium, high tolerance'),
    ])
    String? content;
}

/// Measurement and reporting approach.
@SectionId('SQGMS')
class SystemQualityGoalsMeasurement {
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
    String? content;
}

/// Quality resources and enablement.
@SectionId('SQGRS')
class SystemQualityGoalsResources {
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
    String? content;
}

/// 11.1. Quality Framework [PD00-SYQ-FRA].
///
/// Overall quality approach for the project defining objectives, categories,
/// and how quality is structured and governed across the system.
@SectionId('QLFWK')
@DetailedIn(BusinessQualityPlan)
@SecondLevelSectionId(BusinessQualityPlan, 'BQP-FRA')
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
  String? frameworkContent;

  /// Quality objective structure and alignment.
  QualityFrameworkObjectives objectives = QualityFrameworkObjectives();

  /// Trade-off priorities and decision authority.
  QualityFrameworkTradeOffs tradeOffs = QualityFrameworkTradeOffs();

  /// Verification and defect handling approach.
  QualityFrameworkVerification verification =
      QualityFrameworkVerification();

  /// 11.1.1. Quality Objectives Overview [PD00-SYQ-FRA-OBJ].
  @ContentHelp('Overall quality objectives: expected quality level, '
      'how quality will be measured, acceptable trade-offs.')
  TextSection qualityObjectivesOverview = TextSection();

  /// Quality objectives breakdown by category.
  @ContentHelp('Structured breakdown of objectives for each quality '
      'category with measurable targets.')
  TextSection objectivesBreakdown = TextSection();

  /// 11.1.2. Quality Categories [PD00-SYQ-FRA-CAT] — contains 0+× QualityCategory.
  @SectionId('QCATE-QUALITYCATEGORIES-LST')
  @SectionIdPattern('QCATE-QUALITYCATEGORIES-xxx')
  List<QualityCategoryEntry> qualityCategories = [];

  /// Quality dependencies map.
  @ContentHelp('How quality categories depend on and influence each other.')
  DiagramSection categoryDependencies = DiagramSection();
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
    String? content;
}

/// A quality category entry (form) [PD00-SYQ-FRA-CAT-nn].
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
  String? content;

  /// Description and priority context.
  QualityCategoryEntryDefinition definition = QualityCategoryEntryDefinition();

  /// Category relationships.
  QualityCategoryEntryRelationships relationships =
      QualityCategoryEntryRelationships();

  /// Governance ownership.
  QualityCategoryEntryGovernance governance =
      QualityCategoryEntryGovernance();

  /// Measurement targets.
  QualityCategoryEntryMetrics metrics = QualityCategoryEntryMetrics();

  /// Detailed category definition.
  @ContentHelp('Extended description of category scope, boundaries, '
      'and quality attributes included.')
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
  String? content;
}

/// 11.2. User-Related Quality Criteria [PD00-SYQ-USE].
///
/// Quality criteria that directly affect user experience, including usability,
/// functional completeness, and correctness from the end-user perspective.
@SectionId('USQCR')
@DetailedIn(BusinessQualityPlan)
@SecondLevelSectionId(BusinessQualityPlan, 'BQP-USE')
class UserQualityCriteria {
  // ─────────────────────────────────────────────────────────────────────────
  // User Quality Overview
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
  String? userQualityContent;

  /// User quality criteria overview.
  @ContentHelp('Executive summary of user-related quality goals, '
      'target user experience, and key user quality metrics.')
  TextSection overview = TextSection();

  /// 11.2.1. Usability [PD00-SYQ-USE-USA].
  UsabilityQuality usability = UsabilityQuality();

  /// 11.2.2. Functional Completeness [PD00-SYQ-USE-FUN].
  FunctionalCompletenessQuality functionalCompleteness =
      FunctionalCompletenessQuality();

  /// 11.2.3. Correctness [PD00-SYQ-USE-COR].
  CorrectnessQuality correctness = CorrectnessQuality();
}

/// 11.2.1. Usability quality [PD00-SYQ-USE-USA].
@SectionId('USAQL')
class UsabilityQuality {
  @Form([
    Field('operabilityTarget', String, 'Operability Target',
        hint: 'Ease of operation: intuitive, training-required'),
    Field('ergonomicsStandard', String, 'Ergonomics Standard',
        hint: 'ISO 9241, platform guidelines'),
    Field('learnabilityTarget', String, 'Learnability Target',
        hint: 'Time to proficiency: <1 hour, <1 day'),
  ])
  String? content;

  /// Operability verification and ergonomics goals.
  UsabilityQualityOperability operability = UsabilityQualityOperability();

  /// Learnability and onboarding expectations.
  UsabilityQualityLearnability learnability = UsabilityQualityLearnability();

  /// Clarity and complexity constraints.
  UsabilityQualityClarity clarity = UsabilityQualityClarity();

  /// Interaction control settings.
  UsabilityQualityInteraction interaction = UsabilityQualityInteraction();

  /// Perceived and measured responsiveness targets.
  UsabilityQualityPerformance performance = UsabilityQualityPerformance();

  /// Detailed usability requirements narrative.
  TextSection narrative = TextSection();
}

/// Operability verification and ergonomics goals.
@SectionId('USAOP')
class UsabilityQualityOperability {
  @Form([
    Field('operabilityMetric', String, 'Operability Metric',
        hint: 'Task completion rate, error rate'),
    Field('operabilityVerification', String, 'Operability Verification',
        hint: 'Usability testing, heuristic evaluation'),
    Field('ergonomicsTarget', String, 'Ergonomics Target',
        hint: 'Reduce cognitive load, minimize clicks'),
  ])
  String? content;
}

/// Learnability and onboarding expectations.
@SectionId('USALN')
class UsabilityQualityLearnability {
  @Form([
    Field('learnabilityVerification', String, 'Learnability Verification',
        hint: 'First-use testing, training time measurement'),
    Field('onboardingRequirement', String, 'Onboarding Requirement',
        hint: 'Self-service, guided tour, training required'),
  ])
  String? content;
}

/// Clarity and complexity constraints.
@SectionId('USACL')
class UsabilityQualityClarity {
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
  String? content;
}

/// Interaction control settings.
@SectionId('USAIN')
class UsabilityQualityInteraction {
  @Form([
    Field('undoRequirement', String, 'Undo Requirement',
        hint: 'All actions, critical actions, none'),
    Field('customizationLevel', String, 'Customization Level',
        hint: 'User preferences, layout, workflow'),
  ])
  String? content;
}

/// Perceived and measured responsiveness targets.
@SectionId('USAPR')
class UsabilityQualityPerformance {
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
  String? content;
}

/// 11.2.2. Functional completeness quality [PD00-SYQ-USE-FUN].
@SectionId('FNCOQ')
class FunctionalCompletenessQuality {
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
  String? content;

  /// Detailed functional completeness narrative.
  TextSection narrative = TextSection();
}

/// 11.2.3. Correctness quality [PD00-SYQ-USE-COR].
@SectionId('COQU')
class CorrectnessQuality {
  @Form([
    Field('defectDensityTarget', String, 'Defect Density Target',
        hint: 'Defects per KLOC, per function point'),
    Field('criticalDefectTarget', String, 'Critical Defect Target',
        hint: 'Zero critical/blocking, <N major'),
    Field('defectEscapeRate', String, 'Defect Escape Rate',
        hint: 'Defects found post-release'),
  ])
  String? content;

  /// Data integrity expectations.
  CorrectnessQualityIntegrity integrity = CorrectnessQualityIntegrity();

  /// Accuracy and auditability requirements.
  CorrectnessQualityAccuracy accuracy = CorrectnessQualityAccuracy();

  /// Verification and regression approach.
  CorrectnessQualityVerification verification =
      CorrectnessQualityVerification();

  /// Detailed correctness requirements narrative.
  TextSection narrative = TextSection();
}

/// Data integrity expectations.
@SectionId('COQUIN')
class CorrectnessQualityIntegrity {
  @Form([
    Field('dataIntegrityRequirement', String, 'Data Integrity Requirement',
        hint: 'ACID, eventual consistency'),
    Field('dataValidationCoverage', String, 'Data Validation Coverage',
        hint: 'All inputs, critical inputs'),
    Field('dataCorruptionHandling', String, 'Data Corruption Handling',
        hint: 'Detection, recovery, prevention'),
  ])
  String? content;
}

/// Accuracy and auditability requirements.
@SectionId('COQUAC')
class CorrectnessQualityAccuracy {
  @Form([
    Field('calculationAccuracyTarget', String, 'Calculation Accuracy Target',
        hint: 'Decimal precision, rounding rules'),
    Field('financialAccuracyRequirement', String, 'Financial Accuracy',
        hint: 'Penny-accurate, significant figures'),
    Field('auditTrailRequirement', String, 'Audit Trail Requirement',
        hint: 'All changes, financial only'),
  ])
  String? content;
}

/// Verification and regression approach.
@SectionId('COQUVE')
class CorrectnessQualityVerification {
  @Form([
    Field('correctnessVerification', String, 'Correctness Verification',
        hint: 'Unit tests, integration tests, UAT'),
    Field('testCoverageTarget', String, 'Test Coverage Target',
        hint: 'Code coverage %, requirement coverage'),
    Field('regressionTestingApproach', String, 'Regression Testing',
        hint: 'Automated, manual, risk-based'),
  ])
  String? content;
}

/// 11.3. Technical Quality Criteria [PD00-SYQ-TEC].
///
/// Quality criteria for the technical implementation including efficiency,
/// portability, flexibility, security, maintainability, and reliability.
@SectionId('TEQUCR')
@DetailedIn(BusinessQualityPlan)
@SecondLevelSectionId(BusinessQualityPlan, 'BQP-TEC')
class TechnicalQualityCriteria {
  // ─────────────────────────────────────────────────────────────────────────
  // Technical Quality Overview
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
  String? technicalQualityContent;

  /// Technical quality overview.
  @ContentHelp('Executive summary of technical quality goals, '
      'architectural decisions, and key technical metrics.')
  TextSection overview = TextSection();

  /// 11.3.1. Efficiency [PD00-SYQ-TEC-EFF].
  EfficiencyQuality efficiency = EfficiencyQuality();

  /// 11.3.2. Portability [PD00-SYQ-TEC-POR].
  PortabilityQuality portability = PortabilityQuality();

  /// 11.3.3. Flexibility [PD00-SYQ-TEC-FLE].
  FlexibilityQuality flexibility = FlexibilityQuality();

  /// 11.3.4. Security [PD00-SYQ-TEC-SEC].
  SecurityQuality security = SecurityQuality();

  /// 11.3.5. Maintainability [PD00-SYQ-TEC-MAI].
  MaintainabilityQuality maintainability = MaintainabilityQuality();

  /// 11.3.6. Reliability [PD00-SYQ-TEC-REL].
  ReliabilityQuality reliability = ReliabilityQuality();
}

/// 11.3.1. Efficiency quality [PD00-SYQ-TEC-EFF].
@SectionId('EFQU')
class EfficiencyQuality {
  @Form([
    // Response time
    Field('responseTimeP50Target', String, 'Response Time P50',
        hint: 'Median response time (e.g., <100ms)'),
    Field('responseTimeP95Target', String, 'Response Time P95',
        hint: '95th percentile (e.g., <300ms)'),
    Field('responseTimeP99Target', String, 'Response Time P99',
        hint: '99th percentile (e.g., <1s)'),
  ])
  String? content;

  /// Throughput and scale targets.
  EfficiencyQualityThroughput throughput = EfficiencyQualityThroughput();

  /// Resource utilization constraints.
  EfficiencyQualityResources resources = EfficiencyQualityResources();

  /// Performance validation and SLA commitments.
  EfficiencyQualityVerification verification =
      EfficiencyQualityVerification();

  /// Detailed efficiency requirements narrative.
  TextSection narrative = TextSection();
}

/// Throughput and scale targets.
@SectionId('EFQUTH')
class EfficiencyQualityThroughput {
  @Form([
    Field('throughputTarget', String, 'Throughput Target',
        hint: 'Requests/second, transactions/minute'),
    Field('concurrentUsersTarget', String, 'Concurrent Users Target',
        hint: 'Peak concurrent users supported'),
    Field('scalabilityModel', String, 'Scalability Model',
        hint: 'Horizontal, vertical, auto-scaling'),
  ])
  String? content;
}

/// Resource utilization constraints.
@SectionId('EFQURE')
class EfficiencyQualityResources {
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
  String? content;
}

/// Performance validation and SLA commitments.
@SectionId('EFQUVE')
class EfficiencyQualityVerification {
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
  String? content;
}

/// 11.3.2. Portability quality [PD00-SYQ-TEC-POR].
@SectionId('POQU')
class PortabilityQuality {
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
  String? content;

  /// Detailed portability requirements narrative.
  TextSection narrative = TextSection();
}

/// 11.3.3. Flexibility quality [PD00-SYQ-TEC-FLE].
@SectionId('FLQU')
class FlexibilityQuality {
  @Form([
    Field('componentArchitecture', String, 'Component Architecture',
        hint: 'Microservices, modular monolith, plugins'),
    Field('componentGranularity', String, 'Component Granularity',
        hint: 'Fine-grained, coarse-grained'),
    Field('componentReplaceability', String, 'Component Replaceability',
        hint: 'Hot-swap, restart required'),
  ])
  String? content;

  /// Modularity and reuse goals.
  FlexibilityQualityModularity modularity = FlexibilityQualityModularity();

  /// Distribution and configurability model.
  FlexibilityQualityDeployment deployment = FlexibilityQualityDeployment();

  /// Extensibility and verification expectations.
  FlexibilityQualityExtensibility extensibility =
      FlexibilityQualityExtensibility();

  /// Detailed flexibility requirements narrative.
  TextSection narrative = TextSection();
}

/// Modularity and reuse goals.
@SectionId('FLQUMO')
class FlexibilityQualityModularity {
  @Form([
    Field('modularityLevel', String, 'Modularity Level',
        hint: 'Highly modular, moderately, monolithic'),
    Field('moduleIndependence', String, 'Module Independence',
        hint: 'Loose coupling, shared libraries'),
    Field('moduleReusability', String, 'Module Reusability',
        hint: 'Design for reuse, single-purpose'),
  ])
  String? content;
}

/// Distribution and configurability model.
@SectionId('FLQUDE')
class FlexibilityQualityDeployment {
  @Form([
    Field('distributionCapability', String, 'Distribution Capability',
        hint: 'Multi-region, single-region, on-premise'),
    Field('multiTenancy', String, 'Multi-Tenancy',
        hint: 'Shared, isolated, hybrid'),
    Field('configurabilityLevel', String, 'Configurability Level',
        hint: 'Feature flags, runtime config, deploy-time'),
  ])
  String? content;
}

/// Extensibility and verification expectations.
@SectionId('FLQUEX')
class FlexibilityQualityExtensibility {
  @Form([
    Field('extensibilityModel', String, 'Extensibility Model',
        hint: 'Plugins, APIs, webhooks'),
    Field('customizationScope', String, 'Customization Scope',
        hint: 'UI, business rules, workflows'),
    Field('flexibilityVerification', String, 'Flexibility Verification',
        hint: 'Architecture review, change impact analysis'),
  ])
  String? content;
}

/// 11.3.4. Security quality [PD00-SYQ-TEC-SEC].
@SectionId('SEQU')
class SecurityQuality {
  @Form([
    Field('encryptionAtRest', String, 'Encryption at Rest',
        hint: 'AES-256, database-level, disk-level'),
    Field('encryptionInTransit', String, 'Encryption in Transit',
        hint: 'TLS 1.2+, certificate requirements'),
    Field('keyManagement', String, 'Key Management',
        hint: 'HSM, KMS, key rotation policy'),
  ])
  String? content;

  /// Authentication controls.
  SecurityQualityAuthentication authentication =
      SecurityQualityAuthentication();

  /// Authorization controls.
  SecurityQualityAuthorization authorization =
      SecurityQualityAuthorization();

  /// Vulnerability management expectations.
  SecurityQualityVulnerability vulnerability =
      SecurityQualityVulnerability();

  /// Compliance and verification settings.
  SecurityQualityCompliance compliance = SecurityQualityCompliance();

  /// Detailed security requirements narrative.
  TextSection narrative = TextSection();
}

/// Authentication controls.
@SectionId('SEQUAU')
class SecurityQualityAuthentication {
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
  String? content;
}

/// Authorization controls.
@SectionId('SEQUA1')
class SecurityQualityAuthorization {
  @Form([
    Field('authorizationModel', String, 'Authorization Model',
        hint: 'RBAC, ABAC, ACL'),
    Field('authorizationCoverage', String, 'Authorization Coverage',
        hint: 'All resources, sensitive resources'),
    Field('privilegeEscalationPrevention', String, 'Privilege Escalation',
        hint: 'Controls to prevent escalation'),
  ])
  String? content;
}

/// Vulnerability management expectations.
@SectionId('SEQUVU')
class SecurityQualityVulnerability {
  @Form([
    Field('vulnerabilityScanFrequency', String, 'Vulnerability Scan Frequency',
        hint: 'Continuous, weekly, per-release'),
    Field('penetrationTestFrequency', String, 'Penetration Test Frequency',
        hint: 'Annual, semi-annual, per-release'),
    Field('cveResponseTime', String, 'CVE Response Time',
        hint: 'Critical: 24h, high: 7d'),
  ])
  String? content;
}

/// Compliance and verification settings.
@SectionId('SEQUCO')
class SecurityQualityCompliance {
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
  String? content;
}

/// 11.3.5. Maintainability quality [PD00-SYQ-TEC-MAI].
@SectionId('MAQU')
class MaintainabilityQuality {
  @Form([
    Field('adaptabilityTarget', String, 'Adaptability Target',
        hint: 'Change implementation time'),
    Field('changeImpactLimit', String, 'Change Impact Limit',
        hint: 'Max components affected by change'),
  ])
  String? content;

  /// Analyzability requirements.
  MaintainabilityQualityAnalyzability analyzability =
      MaintainabilityQualityAnalyzability();

  /// Changeability requirements.
  MaintainabilityQualityChangeability changeability =
      MaintainabilityQualityChangeability();

  /// Testability requirements.
  MaintainabilityQualityTestability testability =
      MaintainabilityQualityTestability();

  /// Extensibility and verification requirements.
  MaintainabilityQualityGovernance governance =
      MaintainabilityQualityGovernance();

  /// Detailed maintainability requirements narrative.
  TextSection narrative = TextSection();
}

/// Analyzability requirements.
@SectionId('MAQUAN')
class MaintainabilityQualityAnalyzability {
  @Form([
    Field('codeReadabilityStandard', String, 'Code Readability Standard',
        hint: 'Style guide, code review criteria'),
    Field('documentationRequirement', String, 'Documentation Requirement',
        hint: 'Inline, API docs, architecture docs'),
    Field('loggingStandard', String, 'Logging Standard',
        hint: 'Structured logging, log levels'),
  ])
  String? content;
}

/// Changeability requirements.
@SectionId('MAQUCH')
class MaintainabilityQualityChangeability {
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
  String? content;
}

/// Testability requirements.
@SectionId('MAQUTE')
class MaintainabilityQualityTestability {
  @Form([
    Field('testabilityDesign', String, 'Testability Design',
        hint: 'Dependency injection, mocking support'),
    Field('testPyramidRatio', String, 'Test Pyramid Ratio',
        hint: 'Unit:Integration:E2E ratio'),
    Field('testDataManagement', String, 'Test Data Management',
        hint: 'Fixtures, factories, production-like'),
  ])
  String? content;
}

/// Extensibility and verification requirements.
@SectionId('MAQUGO')
class MaintainabilityQualityGovernance {
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
  String? content;
}

/// 11.3.6. Reliability quality [PD00-SYQ-TEC-REL].
@SectionId('REQU')
class ReliabilityQuality {
  @Form([
    Field('uptimeTarget', String, 'Uptime Target',
        hint: '99.9%, 99.95%, 99.99%'),
    Field('plannedDowntimeWindow', String, 'Planned Downtime Window',
        hint: 'Maintenance window schedule'),
    Field('degradedModeCapability', String, 'Degraded Mode Capability',
        hint: 'Graceful degradation approach'),
  ])
  String? content;

  /// Recovery objectives.
  ReliabilityQualityRecovery recovery = ReliabilityQualityRecovery();

  /// Failover requirements.
  ReliabilityQualityFailover failover = ReliabilityQualityFailover();

  /// Data durability requirements.
  ReliabilityQualityDurability durability = ReliabilityQualityDurability();

  /// Verification and learning.
  ReliabilityQualityVerification verification =
      ReliabilityQualityVerification();

  /// Detailed reliability requirements narrative.
  TextSection narrative = TextSection();
}

/// Recovery objectives.
@SectionId('REQURE')
class ReliabilityQualityRecovery {
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
  String? content;
}

/// Failover requirements.
@SectionId('REQUFA')
class ReliabilityQualityFailover {
  @Form([
    Field('failoverStrategy', String, 'Failover Strategy',
        hint: 'Active-passive, active-active'),
    Field('failoverTime', String, 'Failover Time',
        hint: 'Time to complete failover'),
    Field('failoverTesting', String, 'Failover Testing',
        hint: 'Chaos engineering, DR drills'),
  ])
  String? content;
}

/// Data durability requirements.
@SectionId('REQUDU')
class ReliabilityQualityDurability {
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
  String? content;
}

/// Verification and learning.
@SectionId('REQUVE')
class ReliabilityQualityVerification {
  @Form([
    Field('reliabilityVerification', String, 'Reliability Verification',
        hint: 'Soak testing, chaos engineering'),
    Field('incidentPostmortem', String, 'Incident Postmortem',
        hint: 'Blameless postmortem process'),
  ])
  String? content;
}

/// 11.4. Operations Quality Criteria [PD00-SYQ-OPE].
///
/// Quality criteria for system operations including availability, service
/// levels, monitoring, and IT security operations.
@SectionId('OPQUCR')
@DetailedIn(BusinessQualityPlan)
@SecondLevelSectionId(BusinessQualityPlan, 'BQP-OPE')
class OperationsQualityCriteria {
  // ─────────────────────────────────────────────────────────────────────────
  // Operations Quality Overview
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
  String? operationsOverviewContent;

  /// Operations quality overview narrative.
  @ContentHelp('Executive summary of operational requirements, '
      'support model, and key operational metrics.')
  TextSection overview = TextSection();

  /// 11.4.1. Availability [PD00-SYQ-OPE-AVA].
  AvailabilityQuality availability = AvailabilityQuality();

  /// 11.4.2. Service Level Requirements [PD00-SYQ-OPE-SER].
  ServiceLevelQuality serviceLevelRequirements = ServiceLevelQuality();

  /// 11.4.3. Monitoring and Prevention [PD00-SYQ-OPE-MON].
  MonitoringQuality monitoringAndPrevention = MonitoringQuality();

  /// 11.4.4. IT Security Operations [PD00-SYQ-OPE-ITS].
  ItSecurityOperationsQuality itSecurityOperations =
      ItSecurityOperationsQuality();
}

/// 11.4.1. Availability quality [PD00-SYQ-OPE-AVA].
@SectionId('AVQU')
class AvailabilityQuality {
  @Form([
    Field('uptimeTargetPercentage', String, 'Uptime Target %',
        hint: '99.9% (8.76h/year downtime)'),
    Field('uptimeCalculationMethod', String, 'Uptime Calculation Method',
        hint: 'Excluding planned, including all'),
    Field('uptimeMeasurementPeriod', String, 'Measurement Period',
        hint: 'Monthly, quarterly, annually'),
  ])
  String? content;

  /// Operating-hour expectations.
  AvailabilityQualityOperatingHours operatingHoursDetails =
      AvailabilityQualityOperatingHours();

  /// Maintenance window policy.
  AvailabilityQualityMaintenance maintenance =
      AvailabilityQualityMaintenance();

  /// Degraded-mode behavior.
  AvailabilityQualityDegradedMode degradedMode =
      AvailabilityQualityDegradedMode();

  /// Monitoring and reporting.
  AvailabilityQualityVerification verification =
      AvailabilityQualityVerification();

  /// Detailed availability requirements narrative.
  TextSection narrative = TextSection();
}

/// Operating-hour expectations.
@SectionId('AQOH')
class AvailabilityQualityOperatingHours {
  @Form([
    Field('operatingHours', String, 'Operating Hours',
        hint: '24/7, business hours, regional'),
    Field('peakHoursDefinition', String, 'Peak Hours Definition',
        hint: 'When peak hours apply'),
    Field('peakHoursAvailability', String, 'Peak Hours Availability',
        hint: 'Higher availability during peaks'),
  ])
  String? content;
}

/// Maintenance window policy.
@SectionId('AVQUMA')
class AvailabilityQualityMaintenance {
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
  String? content;
}

/// Degraded-mode behavior.
@SectionId('AQDM')
class AvailabilityQualityDegradedMode {
  @Form([
    Field('degradedModeDefinition', String, 'Degraded Mode Definition',
        hint: 'What constitutes degraded mode'),
    Field('degradedModeCapabilities', String, 'Degraded Mode Capabilities',
        hint: 'Features available in degraded mode'),
    Field('degradedModeCommunication', String, 'Degraded Mode Communication',
        hint: 'How users are informed'),
  ])
  String? content;
}

/// Monitoring and reporting.
@SectionId('AVQUVE')
class AvailabilityQualityVerification {
  @Form([
    Field('availabilityMonitoring', String, 'Availability Monitoring',
        hint: 'Synthetic monitoring, real user'),
    Field('availabilityReporting', String, 'Availability Reporting',
        hint: 'Dashboard, reports, SLA tracking'),
  ])
  String? content;
}

/// 11.4.2. Service level quality [PD00-SYQ-OPE-SER].
@SectionId('SELEQU')
class ServiceLevelQuality {
  @Form([
    Field('supportTierStructure', String, 'Support Tier Structure',
        hint: 'L1/L2/L3, single tier'),
    Field('criticalResponseTime', String, 'Critical Response Time',
        hint: 'Response time for P1 issues'),
    Field('highResponseTime', String, 'High Response Time',
        hint: 'Response time for P2 issues'),
  ])
  String? content;

  /// Remaining response targets.
  ServiceLevelQualityResponse response = ServiceLevelQualityResponse();

  /// Resolution targets.
  ServiceLevelQualityResolution resolution = ServiceLevelQualityResolution();

  /// Escalation rules.
  ServiceLevelQualityEscalation escalation = ServiceLevelQualityEscalation();

  /// On-call support expectations.
  ServiceLevelQualityOnCall onCall = ServiceLevelQualityOnCall();

  /// Restoration and communication priorities.
  ServiceLevelQualityRestoration restoration =
      ServiceLevelQualityRestoration();

  /// Detailed service level requirements narrative.
  TextSection narrative = TextSection();

  /// Service Level Agreement entries.
  @SectionId('SLAE-SLAENTRIES-LST')
  @SectionIdPattern('SLAE-SLAENTRIES-xxx')
  List<ServiceLevelAgreementEntry> slaEntries = [];
}

/// Remaining response targets.
@SectionId('SLQR')
class ServiceLevelQualityResponse {
    @Form([
        Field('mediumResponseTime', String, 'Medium Response Time',
                hint: 'Response time for P3 issues'),
        Field('lowResponseTime', String, 'Low Response Time',
                hint: 'Response time for P4 issues'),
    ])
    String? content;
}

/// Resolution targets.
@SectionId('SLQR1')
class ServiceLevelQualityResolution {
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
    String? content;
}

/// Escalation rules.
@SectionId('SLQE')
class ServiceLevelQualityEscalation {
    @Form([
        Field('escalationTimeframes', String, 'Escalation Timeframes',
                hint: 'When issues escalate'),
        Field('escalationContacts', String, 'Escalation Contacts',
                hint: 'Who to escalate to'),
        Field('executiveEscalation', String, 'Executive Escalation',
                hint: 'When executive escalation occurs'),
    ])
    String? content;
}

/// On-call support expectations.
@SectionId('SLQOC')
class ServiceLevelQualityOnCall {
    @Form([
        Field('onCallCoverage', String, 'On-Call Coverage',
                hint: '24/7, business hours, regional'),
        Field('onCallRotation', String, 'On-Call Rotation',
                hint: 'Weekly, bi-weekly'),
        Field('onCallCompensation', String, 'On-Call Compensation',
                hint: 'Compensation model'),
    ])
    String? content;
}

/// Restoration and communication priorities.
@SectionId('SLQR2')
class ServiceLevelQualityRestoration {
    @Form([
        Field('serviceRestorationPriority', String, 'Service Restoration Priority',
                hint: 'Order of restoration'),
        Field('communicationDuringOutage', String, 'Communication During Outage',
                hint: 'Status page, email, SMS'),
    ])
    String? content;
}

/// A service level agreement entry [PD00-SYQ-OPE-SER-SLA-nn].
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
  String? content;
}

/// 11.4.3. Monitoring quality [PD00-SYQ-OPE-MON].
@SectionId('MOQU')
class MonitoringQuality {
  @Form([
    Field('scalabilityMonitoringApproach', String, 'Scalability Monitoring',
        hint: 'Auto-scaling triggers, capacity alerts'),
    Field('capacityPlanningProcess', String, 'Capacity Planning Process',
        hint: 'How capacity is planned'),
    Field('growthProjections', String, 'Growth Projections',
        hint: 'Expected growth rate'),
  ])
  String? content;

  /// Component monitoring coverage.
  MonitoringQualityCoverage coverage = MonitoringQualityCoverage();

  /// Alert automation capabilities.
  MonitoringQualityAutomation automation = MonitoringQualityAutomation();

  /// Alerting strategy and channels.
  MonitoringQualityAlerting alerting = MonitoringQualityAlerting();

  /// Planning and observability settings.
  MonitoringQualityOperations operations = MonitoringQualityOperations();

  /// Detailed monitoring requirements narrative.
  TextSection narrative = TextSection();
}

/// Component monitoring coverage.
@SectionId('MOQUCO')
class MonitoringQualityCoverage {
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
  String? content;
}

/// Alert automation capabilities.
@SectionId('MOQUAU')
class MonitoringQualityAutomation {
  @Form([
    Field('alertAutomation', String, 'Alert Automation',
        hint: 'Automated response to alerts'),
    Field('selfHealingCapability', String, 'Self-Healing Capability',
        hint: 'Auto-recovery mechanisms'),
    Field('runbookAutomation', String, 'Runbook Automation',
        hint: 'Automated runbook execution'),
  ])
  String? content;
}

/// Alerting strategy and channels.
@SectionId('MOQUAL')
class MonitoringQualityAlerting {
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
  String? content;
}

/// Planning and observability settings.
@SectionId('MOQUOP')
class MonitoringQualityOperations {
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
  String? content;
}

/// 11.4.4. IT Security Operations quality [PD00-SYQ-OPE-ITS].
@SectionId('ISOQ')
class ItSecurityOperationsQuality {
  @Form([
    Field('accessControlModel', String, 'Access Control Model',
        hint: 'RBAC, ABAC, zero-trust'),
    Field('drPlanRequired', bool, 'DR Plan Required'),
    Field('incidentResponsePlan', String, 'Incident Response Plan',
        hint: 'NIST, custom'),
  ])
  String? content;

  /// Access protection controls.
  ItSecurityOperationsQualityAccess access =
      ItSecurityOperationsQualityAccess();

  /// Disaster recovery planning details.
  ItSecurityOperationsQualityRecovery recovery =
      ItSecurityOperationsQualityRecovery();

  /// Penetration testing and remediation.
  ItSecurityOperationsQualityTesting testing =
      ItSecurityOperationsQualityTesting();

  /// Incident handling and reporting.
  ItSecurityOperationsQualityIncident incident =
      ItSecurityOperationsQualityIncident();

  /// Detailed IT security operations narrative.
  TextSection narrative = TextSection();
}

/// Access protection controls.
@SectionId('ISOQA')
class ItSecurityOperationsQualityAccess {
  @Form([
    Field('privilegedAccessManagement', String, 'Privileged Access Management',
        hint: 'PAM solution, just-in-time'),
    Field('accessReviewFrequency', String, 'Access Review Frequency',
        hint: 'Quarterly, annually'),
    Field('accessAuditLogging', String, 'Access Audit Logging',
        hint: 'What access is logged'),
  ])
  String? content;
}

/// Disaster recovery planning details.
@SectionId('ISOQR')
class ItSecurityOperationsQualityRecovery {
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
  String? content;
}

/// Penetration testing and remediation.
@SectionId('ISOQT')
class ItSecurityOperationsQualityTesting {
  @Form([
    Field('penetrationTestScope', String, 'Penetration Test Scope',
        hint: 'Internal, external, both'),
    Field('penetrationTestFrequency', String, 'Penetration Test Frequency',
        hint: 'Annual, per-release'),
    Field('vulnerabilitySlaResolution', String, 'Vulnerability SLA',
        hint: 'Resolution timeframes by severity'),
    Field('bugBountyProgram', bool, 'Bug Bounty Program'),
  ])
  String? content;
}

/// Incident handling and reporting.
@SectionId('ISOQI')
class ItSecurityOperationsQualityIncident {
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
  String? content;
}

/// 11.5. Documentation Quality Criteria [PD00-SYQ-DOC].
///
/// Quality criteria for project documentation including readability,
/// completeness, correctness, and changeability.
@SectionId('DOQUCR')
@DetailedIn(BusinessQualityPlan)
@SecondLevelSectionId(BusinessQualityPlan, 'BQP-DOC')
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
  String? documentationOverviewContent;

  /// Documentation quality overview narrative.
  @ContentHelp('Executive summary of documentation goals, '
      'target audiences, and key documentation metrics.')
  TextSection overview = TextSection();

  /// 11.5.1. Readability [PD00-SYQ-DOC-REA].
  ReadabilityQuality readability = ReadabilityQuality();

  /// 11.5.2. Completeness [PD00-SYQ-DOC-COM].
  DocCompletenessQuality completeness = DocCompletenessQuality();

  /// 11.5.3. Correctness [PD00-SYQ-DOC-COR].
  DocCorrectnessQuality correctness = DocCorrectnessQuality();

  /// 11.5.4. Changeability [PD00-SYQ-DOC-CHA].
  DocChangeabilityQuality changeability = DocChangeabilityQuality();
}

/// 11.5.1. Readability quality [PD00-SYQ-DOC-REA].
@SectionId('REQU1')
class ReadabilityQuality {
  @Form([
    Field('terminologyStandard', String, 'Terminology Standard',
        hint: 'Glossary, controlled vocabulary'),
    Field('ambiguityPrevention', String, 'Ambiguity Prevention',
        hint: 'Review checklist, automated checks'),
    Field('jargonPolicy', String, 'Jargon Policy',
        hint: 'Define all terms, minimize jargon'),
  ])
  String? content;

  /// Identifiability and navigation.
  ReadabilityQualityNavigation navigation = ReadabilityQualityNavigation();

  /// Comprehensibility requirements.
  ReadabilityQualityComprehensibility comprehensibility =
      ReadabilityQualityComprehensibility();

  /// Document structure rules.
  ReadabilityQualityStructure structure = ReadabilityQualityStructure();

  /// Style guide alignment.
  ReadabilityQualityStyle style = ReadabilityQualityStyle();

  /// Detailed readability requirements narrative.
  TextSection narrative = TextSection();
}

/// Identifiability and navigation.
@SectionId('REQUNA')
class ReadabilityQualityNavigation {
  @Form([
    Field('sectionNumbering', String, 'Section Numbering',
        hint: 'Hierarchical, flat, none'),
    Field('crossReferenceStandard', String, 'Cross-Reference Standard',
        hint: 'Section IDs, hyperlinks'),
    Field('searchability', String, 'Searchability',
        hint: 'Full-text search, tagged'),
  ])
  String? content;
}

/// Comprehensibility requirements.
@SectionId('REQUCO')
class ReadabilityQualityComprehensibility {
  @Form([
    Field('readingLevelTarget', String, 'Reading Level Target',
        hint: 'Grade level, technical audience'),
    Field('formatStandards', String, 'Format Standards',
        hint: 'Headings, lists, tables usage'),
    Field('visualAidRequirements', String, 'Visual Aid Requirements',
        hint: 'Diagrams, screenshots, examples'),
  ])
  String? content;
}

/// Document structure rules.
@SectionId('REQUST')
class ReadabilityQualityStructure {
  @Form([
    Field('documentStructureTemplate', String, 'Structure Template',
        hint: 'Standard document templates'),
    Field('informationHierarchy', String, 'Information Hierarchy',
        hint: 'How information is organized'),
    Field('navigationAids', String, 'Navigation Aids',
        hint: 'TOC, index, breadcrumbs'),
  ])
  String? content;
}

/// Style guide alignment.
@SectionId('REQUS1')
class ReadabilityQualityStyle {
  @Form([
    Field('styleGuideReference', String, 'Style Guide Reference',
        hint: 'Google, Microsoft, custom'),
    Field('writingVoice', String, 'Writing Voice',
        hint: 'Active, passive, imperative'),
    Field('formattingConventions', String, 'Formatting Conventions',
        hint: 'Code, commands, UI elements'),
  ])
  String? content;
}

/// 11.5.2. Documentation completeness quality [PD00-SYQ-DOC-COM].
@SectionId('DOCOQU')
class DocCompletenessQuality {
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
  String? content;

  /// Detailed completeness requirements narrative.
  TextSection narrative = TextSection();
}

/// 11.5.3. Documentation correctness quality [PD00-SYQ-DOC-COR].
@SectionId('DOCOQ1')
class DocCorrectnessQuality {
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
  String? content;

  /// Formatting and implementation alignment.
  DocCorrectnessQualityAlignment alignment = DocCorrectnessQualityAlignment();

  /// Verification and feedback handling.
  DocCorrectnessQualityVerification verification =
      DocCorrectnessQualityVerification();

  /// Detailed correctness requirements narrative.
  TextSection narrative = TextSection();
}

/// Formatting and implementation alignment.
@SectionId('DCQA')
class DocCorrectnessQualityAlignment {
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
    String? content;
}

/// Verification and feedback handling.
@SectionId('DCQV')
class DocCorrectnessQualityVerification {
    @Form([
        Field('correctnessVerification', String, 'Correctness Verification',
                hint: 'Testing docs against product'),
        Field('userFeedbackIntegration', String, 'User Feedback Integration',
                hint: 'How user-reported errors are handled'),
    ])
    String? content;
}

/// 11.5.4. Documentation changeability quality [PD00-SYQ-DOC-CHA].
@SectionId('DOCHQU')
class DocChangeabilityQuality {
  @Form([
    Field('versioningStrategy', String, 'Versioning Strategy',
        hint: 'Semantic, date-based, product-aligned'),
    Field('versionHistoryTracking', String, 'Version History Tracking',
        hint: 'Changelog, git history'),
    Field('multiVersionSupport', String, 'Multi-Version Support',
        hint: 'Multiple product versions documented'),
  ])
  String? content;

  /// Extensibility and localization readiness.
  DocChangeabilityQualityExtensibility extensibility =
      DocChangeabilityQualityExtensibility();

  /// Sizing and structural consistency rules.
  DocChangeabilityQualityStructure structure =
      DocChangeabilityQualityStructure();

  /// Review and retirement maintenance process.
  DocChangeabilityQualityMaintenance maintenance =
      DocChangeabilityQualityMaintenance();

  /// Detailed changeability requirements narrative.
  TextSection narrative = TextSection();
}

/// Extensibility and localization readiness.
@SectionId('DCQE')
class DocChangeabilityQualityExtensibility {
  @Form([
    Field('extensibilityApproach', String, 'Extensibility Approach',
        hint: 'Modular, template-based'),
    Field('newSectionGuidelines', String, 'New Section Guidelines',
        hint: 'How to add new content'),
    Field('localizationReadiness', String, 'Localization Readiness',
        hint: 'i18n considerations'),
  ])
  String? content;
}

/// Sizing and structural consistency rules.
@SectionId('DCQS')
class DocChangeabilityQualityStructure {
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
  String? content;
}

/// Review and retirement maintenance process.
@SectionId('DCQM')
class DocChangeabilityQualityMaintenance {
  @Form([
    Field('reviewCycle', String, 'Review Cycle',
        hint: 'Periodic review schedule'),
    Field('retirementProcess', String, 'Retirement Process',
        hint: 'How outdated docs are retired'),
  ])
  String? content;
}

/// 11.6. Quality Prioritization [PD00-SYQ-PRI].
///
/// Prioritization and balancing of quality attributes including weighted
/// matrices and explicit trade-off decisions.
@SectionId('QUPR')
@DetailedIn(BusinessQualityPlan)
@SecondLevelSectionId(BusinessQualityPlan, 'BQP-PRI')
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
  String? prioritizationFrameworkContent;

  /// Prioritization approach overview.
  @ContentHelp('Overview of how quality attributes are prioritized, '
      'including stakeholder involvement and decision process.')
  TextSection prioritizationOverview = TextSection();

  /// 11.6.1. Weighted Quality Matrix [PD00-SYQ-PRI-WEI].
  WeightedQualityMatrix weightedQualityMatrix = WeightedQualityMatrix();

  /// 11.6.2. Trade-off Decisions [PD00-SYQ-PRI-TRA].
  TradeOffDecisions tradeOffDecisions = TradeOffDecisions();
}

/// 11.6.1. Weighted Quality Matrix [PD00-SYQ-PRI-WEI].
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
  String? matrixConfigContent;

  /// Weighted quality matrix narrative.
  @ContentHelp('Description of weighted quality matrix including '
      'weights assigned to each attribute and rationale.')
  TextSection matrixNarrative = TextSection();

  /// Quality attribute weight entries.
  @SectionId('QLWGT-WEIGHTS-LST')
  @SectionIdPattern('QLWGT-WEIGHTS-xxx')
  List<QualityWeightEntry> weights = [];

  /// Quality matrix visualization.
  @ContentHelp('Visual representation of quality attribute priorities.')
  DiagramSection matrixVisualization = DiagramSection();
}

/// A quality weight entry [PD00-SYQ-PRI-WEI-nn].
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
  String? content;
}

/// 11.6.2. Trade-off Decisions [PD00-SYQ-PRI-TRA].
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
  String? tradeOffGovernanceContent;

  /// Trade-off decisions overview.
  @ContentHelp('Overview of major trade-off decisions and their impact '
      'on system quality and design choices.')
  TextSection tradeOffOverview = TextSection();

  /// Contains 0+× TradeOffDecision.
  @SectionId('TODE-ITEMS-LST')
  @SectionIdPattern('TODE-ITEMS-xxx')
  List<TradeOffDecisionEntry> items = [];
}

/// A trade-off decision entry (form) [PD00-SYQ-PRI-TRA-nn].
@SectionId('TODE')
class TradeOffDecisionEntry {
  @Form([
    Field('decisionId', String, 'Decision ID',
        hint: 'Unique identifier (e.g., TRADEOFF-001)'),
    Field('decisionTitle', String, 'Decision Title', required: true),
    Field('decisionStatus', String, 'Status',
        hint: 'Proposed, approved, implemented, reversed'),
  ])
  String? content;

  /// Qualities in conflict.
  TradeOffDecisionEntryQualities qualities = TradeOffDecisionEntryQualities();

  /// Rationale for trade-off.
  TradeOffDecisionEntryRationale rationale = TradeOffDecisionEntryRationale();

  /// Impact assessment.
  TradeOffDecisionEntryImpact impact = TradeOffDecisionEntryImpact();

  /// Mitigation measures.
  TradeOffDecisionEntryMitigation mitigation =
      TradeOffDecisionEntryMitigation();

  /// Approval and governance.
  TradeOffDecisionEntryApproval approval = TradeOffDecisionEntryApproval();

  /// Detailed trade-off analysis.
  @ContentHelp('Extended analysis of trade-off decision including '
      'quantitative impact assessment.')
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
  String? content;
}

/// 11.7. Acceptance Criteria Summary [PD00-SYQ-ACC].
///
/// Quality acceptance criteria for the project including must-pass criteria
/// and quality gate checklists.
@SectionId('ACCRSU')
@DetailedIn(BusinessQualityPlan)
@SecondLevelSectionId(BusinessQualityPlan, 'BQP-ACC')
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
  String? acceptanceFrameworkContent;

  /// Acceptance criteria overview.
  @ContentHelp('Overview of acceptance process, key acceptance criteria, '
      'and acceptance governance.')
  TextSection acceptanceOverview = TextSection();

  /// 11.7.1. Must-Pass Criteria [PD00-SYQ-ACC-MUS].
  MustPassCriteria mustPassCriteria = MustPassCriteria();

  /// 11.7.2. Quality Gate Checklist [PD00-SYQ-ACC-GAT].
  QualityGateChecklist qualityGateChecklist = QualityGateChecklist();

  /// Acceptance test summary.
  @ContentHelp('Summary of acceptance test plan and expected outcomes.')
  TextSection acceptanceTestSummary = TextSection();
}

/// 11.7.1. Must-Pass Criteria [PD00-SYQ-ACC-MUS].
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
  String? mustPassOverviewContent;

  /// Must-pass criteria overview.
  @ContentHelp('Overview of must-pass criteria approach and '
      'rationale for selection.')
  TextSection overview = TextSection();

  /// Contains 0+× MustPassCriterion.
  @SectionId('MSTPCR-ITEMS-LST')
  @SectionIdPattern('MSTPCR-ITEMS-xxx')
  List<MustPassCriterionEntry> items = [];
}

/// A must-pass criterion entry (form) [PD00-SYQ-ACC-MUS-nn].
@SectionId('MSTPCR')
class MustPassCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID',
        hint: 'Unique identifier (e.g., MP-001)'),
    Field('criterionName', String, 'Criterion Name', required: true),
    Field('verificationMethod', String, 'Verification Method', required: true,
        hint: 'Test, demonstration, analysis, inspection'),
  ])
  String? content;

  /// Classification and intent of the criterion.
  MustPassCriterionEntryDefinition definition =
      MustPassCriterionEntryDefinition();

  /// Verification and threshold details.
  MustPassCriterionEntryVerification verification =
      MustPassCriterionEntryVerification();

  /// Responsibility and dependency information.
  MustPassCriterionEntryGovernance governance =
      MustPassCriterionEntryGovernance();

  /// Execution status and defects.
  MustPassCriterionEntryStatus status = MustPassCriterionEntryStatus();

  /// Additional criterion details.
  @ContentHelp('Extended description of criterion including '
      'edge cases and special considerations.')
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
  String? content;
}

/// 11.7.2. Quality Gate Checklist [PD00-SYQ-ACC-GAT].
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
  String? checklistOverviewContent;

  /// Quality gate checklist overview.
  @ContentHelp('Overview of quality gate process and checklist usage.')
  TextSection overview = TextSection();

  /// Contains 0+× QualityGateCheck.
  @SectionId('QGCHK-ITEMS-LST')
  @SectionIdPattern('QGCHK-ITEMS-xxx')
  List<QualityGateCheckEntry> items = [];
}

/// A quality gate check entry (form) [PD00-SYQ-ACC-GAT-nn].
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
  String? content;

  /// Check definition and categorization.
  QualityGateCheckEntryDefinition definition =
      QualityGateCheckEntryDefinition();

  /// Verification criteria and evidence.
  QualityGateCheckEntryVerification verification =
      QualityGateCheckEntryVerification();

  /// Responsibility and timing.
  QualityGateCheckEntryExecution execution = QualityGateCheckEntryExecution();

  /// Status and observations.
  QualityGateCheckEntryStatus status = QualityGateCheckEntryStatus();

  /// Blocking behavior.
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
  String? content;
}

// ---------------------------------------------------------------------------
// 11.8 Test Strategy [PD00-SYQ-TST]
// ---------------------------------------------------------------------------

/// 11.8. Test Strategy [PD00-SYQ-TST].
///
/// Overall test strategy for the project. Covers HBSG AS23 Test Strategy.
@SectionId('TEST')
@DetailedIn(BusinessQualityPlan)
@SecondLevelSectionId(BusinessQualityPlan, 'BQP-TST')
class TestStrategy {
  @ContentHelp('''
High-level strategy for verifying quality across the system. Distinct
from the acceptance plan (PD00-DEL-ACC) and from the per-quality-attribute
criteria in PD00-SYQ-USE/TEC/OPE/DOC; this section integrates them.

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
  String? content;
}
