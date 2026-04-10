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
@SectionId('PD00-DEL-ACC-UAT')
class UserAcceptanceTesting {
  @Form([
    Field('scope', String, 'Scope'),
    Field('environment', String, 'Environment'),
    Field('participants', String, 'Participants'),
    Field('schedule', String, 'Schedule'),
    Field('exitCriteria', String, 'Exit Criteria'),
  ])
  String? content;

  /// Contains 0+× TestScenario.
  @SectionIdPattern('PD00-DEL-ACC-UAT-xx')
  List<TestScenarioEntry> testScenarios = [];
}

/// A test scenario entry (form) [PD00-DEL-ACC-UAT-nn].
class TestScenarioEntry {
  @Form([
    Field('scenarioName', String, 'Scenario Name', required: true),
    Field('description', String, 'Short description'),
    Field('expectedResult', String, 'Expected Result'),
  ])
  String? content;
}
