/// Section 14: Delivery Scope and Acceptance [PD00-DEL].
///
/// Agreements regarding delivery scope and acceptance for the system.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 14. Delivery Scope and Acceptance [PD00-DEL].
@SectionId('PD00-DEL')
class DeliveryScopeAndAcceptance {
  @Unused()
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
  @Unused()
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
  @Unused()
  String? content;

  /// Contains 0+× Deliverable.
  @SectionIdPattern('PD00-DEL-DEL-SOF-xx')
  List<DeliverableEntry> items = [];
}

/// 14.1.2. Documentation Deliverables [PD00-DEL-DEL-DOC].
@SectionId('PD00-DEL-DEL-DOC')
class DocumentationDeliverables {
  @Unused()
  String? content;

  /// Contains 0+× Deliverable.
  @SectionIdPattern('PD00-DEL-DEL-DOC-xx')
  List<DeliverableEntry> items = [];
}

/// 14.1.3. Training Deliverables [PD00-DEL-DEL-TRA].
@SectionId('PD00-DEL-DEL-TRA')
class TrainingDeliverables {
  @Unused()
  String? content;

  /// Contains 0+× Deliverable.
  @SectionIdPattern('PD00-DEL-DEL-TRA-xx')
  List<DeliverableEntry> items = [];
}

/// 14.1.4. Support Deliverables [PD00-DEL-DEL-SUP].
@SectionId('PD00-DEL-DEL-SUP')
class SupportDeliverables {
  @Unused()
  String? content;

  /// Contains 0+× Deliverable.
  @SectionIdPattern('PD00-DEL-DEL-SUP-xx')
  List<DeliverableEntry> items = [];
}

/// A deliverable entry (form) [PD00-DEL-DEL-nn].
class DeliverableEntry {
  @Form([
    Field('deliverableName', String, 'Deliverable Name', required: true),
    Field('description', String, 'Short description'),
    Field('deliveryDate', String, 'Delivery Date'),
    Field('format', String, 'Format'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria'),
  ])
  String? content;
}

/// 14.2. Acceptance Plan [PD00-DEL-ACC]. Seeds → BQP.
@SectionId('PD00-DEL-ACC')
@Comment('Seeds → BQP')
class AcceptancePlan {
  @Unused()
  String? content;

  /// 14.2.1. Acceptance Criteria [PD00-DEL-ACC-CRI].
  AcceptanceCriteriaList acceptanceCriteria = AcceptanceCriteriaList();

  /// 14.2.2. Acceptance Process [PD00-DEL-ACC-PRO].
  AcceptanceProcess acceptanceProcess = AcceptanceProcess();

  /// 14.2.3. User Acceptance Testing [PD00-DEL-ACC-UAT].
  UserAcceptanceTesting userAcceptanceTesting = UserAcceptanceTesting();

  /// Defect Resolution.
  TextSection defectResolution = TextSection();

  /// Sign Off Process.
  TextSection signOffProcess = TextSection();

  /// Warranty.
  TextSection warranty = TextSection();
}

/// 14.2.1. Acceptance Criteria [PD00-DEL-ACC-CRI].
@SectionId('PD00-DEL-ACC-CRI')
class AcceptanceCriteriaList {
  @Unused()
  String? content;

  /// Contains 0+× DeliveryAcceptanceCriterion.
  @SectionIdPattern('PD00-DEL-ACC-CRI-xx')
  List<DeliveryAcceptanceCriterionEntry> items = [];
}

/// An acceptance criterion entry (form) [PD00-DEL-ACC-CRI-nn].
class DeliveryAcceptanceCriterionEntry {
  @Form([
    Field('criterion', String, 'Criterion', required: true),
    Field('category', String, 'Category'),
    Field('verificationMethod', String, 'Verification Method'),
    Field('acceptanceThreshold', String, 'Acceptance Threshold'),
  ])
  String? content;
}

/// 14.2.2. Acceptance Process [PD00-DEL-ACC-PRO].
@SectionId('PD00-DEL-ACC-PRO')
class AcceptanceProcess {
  @Form([
    Field('participants', String, 'Participants'),
    Field('escalationProcess', String, 'Escalation Process'),
  ])
  String? content;

  /// Contains 0+× AcceptanceStep.
  @SectionIdPattern('PD00-DEL-ACC-PRO-xx')
  List<AcceptanceStepEntry> steps = [];
}

/// An acceptance step entry (form) [PD00-DEL-ACC-PRO-nn].
class AcceptanceStepEntry {
  @Form([
    Field('stepName', String, 'Step Name', required: true),
    Field('description', String, 'Short description'),
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
    // --- Scope & Objectives ---
    Field('uatObjective', String, 'UAT Objective',
        hint:
            'Primary goal — e.g. validate business requirements before go-live'),
    Field('scope', String, 'Scope Summary',
        hint: 'Modules, features, and integrations included in UAT'),
    Field('outOfScope', String, 'Out of Scope',
        hint:
            'Explicitly excluded items — e.g. load testing, data migration validation'),
    Field('uatApproach', String, 'UAT Approach',
        hint: 'Scripted / Exploratory / Hybrid — describe the overall strategy'),
    Field('testTypes', String, 'Test Types Included',
        hint:
            'Functional / Regression / Usability / Accessibility / End-to-End'),

    // --- Environment ---
    Field('environmentName', String, 'Environment Name',
        hint: 'Name or identifier of the UAT environment'),
    Field('environmentUrl', String, 'Environment URL',
        hint: 'Access URL or endpoint'),
    Field('environmentDescription', String, 'Environment Description',
        hint:
            'Hardware, OS, software stack, network configuration summary'),
    Field('environmentRefreshPolicy', String, 'Environment Refresh Policy',
        hint:
            'How and when environment data is refreshed — e.g. nightly from staging'),
    Field('environmentAccessControl', String, 'Access Control',
        hint:
            'Who has access, authentication method, credential management'),

    // --- Test Data ---
    Field('testDataStrategy', String, 'Test Data Strategy',
        hint: 'Synthetic / MaskedProduction / Subset — describe approach'),
    Field('testDataPreparation', String, 'Test Data Preparation',
        hint: 'Who prepares test data, lead time, and tools used'),
    Field('testDataPrivacy', String, 'Data Privacy Compliance',
        hint: 'GDPR / HIPAA / PCI-DSS compliance for test data handling'),
    Field('testDataRefreshCadence', String, 'Test Data Refresh Cadence',
        hint: 'How often test data is refreshed between cycles'),

    // --- Participants & Governance ---
    Field('uatLead', String, 'UAT Lead',
        hint: 'Name and role of the person coordinating UAT'),
    Field('businessOwner', String, 'Business Owner',
        hint: 'Stakeholder accountable for UAT sign-off'),
    Field('testerRoles', String, 'Tester Roles',
        hint:
            'Business analysts, end-users, SMEs, external testers'),
    Field('supportTeam', String, 'Support Team',
        hint:
            'Dev, QA, and ops contacts available during UAT execution'),
    Field('raciSummary', String, 'RACI Summary',
        hint:
            'Responsible / Accountable / Consulted / Informed for key UAT activities'),
    Field('escalationPath', String, 'Escalation Path',
        hint:
            'Escalation chain for blocking defects or decision disputes'),
    Field('communicationPlan', String, 'Communication Plan',
        hint: 'Status update frequency, channels, and audience'),

    // --- Schedule & Cycles ---
    Field('plannedStartDate', String, 'Planned Start Date',
        hint: 'Target start date for UAT execution'),
    Field('plannedEndDate', String, 'Planned End Date',
        hint: 'Target completion date'),
    Field('numberOfCycles', String, 'Number of Test Cycles',
        hint: 'e.g. 2 cycles — initial execution + regression'),
    Field('cycleDuration', String, 'Cycle Duration',
        hint: 'Expected duration per cycle — e.g. 5 business days'),
    Field('milestones', String, 'Key Milestones',
        hint:
            'Entry gate, mid-cycle checkpoint, exit gate, sign-off deadline'),

    // --- Entry, Exit & Suspension Criteria ---
    Field('entryCriteria', String, 'Entry Criteria',
        hint:
            'Prerequisites: system testing passed, environment ready, data loaded'),
    Field('exitCriteria', String, 'Exit Criteria',
        hint:
            'Completion conditions: pass rate >= 95%, no Sev-1 open, sign-off obtained'),
    Field('suspensionCriteria', String, 'Suspension Criteria',
        hint:
            'Conditions that halt UAT — e.g. environment down, critical blocker'),
    Field('resumptionCriteria', String, 'Resumption Criteria',
        hint: 'Conditions to restart after suspension'),

    // --- Defect Management ---
    Field('defectTool', String, 'Defect Tracking Tool',
        hint:
            'Jira / Azure DevOps / ServiceNow — tool and project/board details'),
    Field('defectSeverityLevels', String, 'Severity Levels',
        hint: 'Define Sev-1 through Sev-4 with examples'),
    Field('defectResolutionSla', String, 'Resolution SLAs',
        hint:
            'Target fix times per severity — e.g. Sev-1 within 4 hours'),
    Field('defectThreshold', String, 'Acceptable Defect Threshold',
        hint: 'Max open defects per severity to proceed with sign-off'),
    Field('defectTriageProcess', String, 'Triage Process',
        hint:
            'Frequency, participants, and decision-making for defect triage'),
    Field('retestProcess', String, 'Retest Process',
        hint:
            'How fixed defects are retested and confirmed in UAT'),

    // --- Reporting ---
    Field('dailyStatusFormat', String, 'Daily Status Format',
        hint:
            'Contents: executed, passed, failed, blocked, open defects'),
    Field('metricsTracked', String, 'Metrics Tracked',
        hint:
            'Pass rate, defect density, test coverage, cycle time, burndown'),
    Field('dashboardTool', String, 'Dashboard Tool',
        hint:
            'Tool for real-time UAT metrics — e.g. Jira dashboard, Power BI'),
    Field('finalReportContents', String, 'Final Report Contents',
        hint:
            'Summary, results matrix, open defects, risk assessment, recommendation'),

    // --- Non-Functional Acceptance ---
    Field('accessibilityAcceptance', String, 'Accessibility Acceptance',
        hint:
            'WCAG level, screen-reader compatibility, keyboard navigation checks'),
    Field('performanceAcceptance', String, 'Performance Acceptance',
        hint:
            'Response time thresholds, concurrent users, load conditions during UAT'),
    Field('securityAcceptance', String, 'Security Acceptance',
        hint:
            'Authentication, authorization, data-at-rest / in-transit checks'),
    Field('regressionApproach', String, 'Regression Approach',
        hint:
            'Scope and method for regression testing during UAT cycles'),

    // --- Sign-Off ---
    Field('signOffAuthority', String, 'Sign-Off Authority',
        hint: 'Role(s) authorized to provide formal UAT sign-off'),
    Field('signOffCriteria', String, 'Sign-Off Criteria',
        hint: 'Exit criteria + risk acceptance conditions for sign-off'),
    Field('conditionalAcceptancePolicy', String,
        'Conditional Acceptance Policy',
        hint:
            'Conditions under which UAT passes with known open defects'),

    // --- Training & Readiness ---
    Field('testerTraining', String, 'Tester Training',
        hint:
            'Training provided: system walkthrough, tool orientation, test guidelines'),
    Field('userDocumentation', String, 'User Documentation Availability',
        hint: 'Guides, FAQs, and quick-start docs available to testers'),
  ])
  String? content;

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
