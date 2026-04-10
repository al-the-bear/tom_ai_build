/// Section 14: Delivery Scope and Acceptance [PD00-DEL].
///
/// Agreements regarding delivery scope and acceptance for the system.
library;



/// 14. Delivery Scope and Acceptance [PD00-DEL].
class DeliveryScopeAndAcceptance {
  String? content;

  /// 14.1. Delivery and Service Scope [PD00-DEL-DEL].
  DeliveryScope deliveryScope = DeliveryScope();

  /// 14.2. Acceptance Plan [PD00-DEL-ACC]. Seeds → BQP.
  AcceptancePlan acceptancePlan = AcceptancePlan();
}

/// 14.1. Delivery and Service Scope [PD00-DEL-DEL].
class DeliveryScope {
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
class SoftwareDeliverables {
  String? content;
  /// Contains 0+× Deliverable.
  List<DeliverableEntry> items = [];
}

/// 14.1.2. Documentation Deliverables [PD00-DEL-DEL-DOC].
class DocumentationDeliverables {
  String? content;
  /// Contains 0+× Deliverable.
  List<DeliverableEntry> items = [];
}

/// 14.1.3. Training Deliverables [PD00-DEL-DEL-TRA].
class TrainingDeliverables {
  String? content;
  /// Contains 0+× Deliverable.
  List<DeliverableEntry> items = [];
}

/// 14.1.4. Support Deliverables [PD00-DEL-DEL-SUP].
class SupportDeliverables {
  String? content;
  /// Contains 0+× Deliverable.
  List<DeliverableEntry> items = [];
}

/// A deliverable entry (form) [PD00-DEL-DEL-nn].
class DeliverableEntry {
  String? content;
  String? deliverableName;
  String? description;
  String? deliveryDate;
  String? format;
  String? acceptanceCriteria;
}

/// 14.2. Acceptance Plan [PD00-DEL-ACC]. Seeds → BQP.
class AcceptancePlan {
  String? content;

  /// 14.2.1. Acceptance Criteria [PD00-DEL-ACC-CRI].
  AcceptanceCriteriaList acceptanceCriteria = AcceptanceCriteriaList();

  /// 14.2.2. Acceptance Process [PD00-DEL-ACC-PRO].
  AcceptanceProcess acceptanceProcess = AcceptanceProcess();

  /// 14.2.3. User Acceptance Testing [PD00-DEL-ACC-UAT].
  UserAcceptanceTesting userAcceptanceTesting = UserAcceptanceTesting();

  /// 14.2.4. Defect Resolution [PD00-DEL-ACC-DEF].
  String? defectResolution;

  /// 14.2.5. Sign-off Process [PD00-DEL-ACC-SIG].
  String? signOffProcess;

  /// 14.2.6. Warranty [PD00-DEL-ACC-WAR].
  String? warranty;
}

/// 14.2.1. Acceptance Criteria [PD00-DEL-ACC-CRI].
class AcceptanceCriteriaList {
  String? content;
  /// Contains 0+× DeliveryAcceptanceCriterion.
  List<DeliveryAcceptanceCriterionEntry> items = [];
}

/// An acceptance criterion entry (form) [PD00-DEL-ACC-CRI-nn].
class DeliveryAcceptanceCriterionEntry {
  String? content;
  String? criterion;
  String? category;
  String? verificationMethod;
  String? acceptanceThreshold;
}

/// 14.2.2. Acceptance Process [PD00-DEL-ACC-PRO].
class AcceptanceProcess {
  String? content;
  /// Contains 0+× AcceptanceStep.
  List<AcceptanceStepEntry> steps = [];
  String? timeline;
  String? participants;
  String? escalationProcess;
}

/// An acceptance step entry (form) [PD00-DEL-ACC-PRO-nn].
class AcceptanceStepEntry {
  String? content;
  String? stepName;
  String? description;
}

/// 14.2.3. User Acceptance Testing [PD00-DEL-ACC-UAT].
class UserAcceptanceTesting {
  String? content;
  String? scope;
  String? environment;
  String? participants;
  String? schedule;
  /// Contains 0+× TestScenario.
  List<TestScenarioEntry> testScenarios = [];
  String? exitCriteria;
}

/// A test scenario entry (form) [PD00-DEL-ACC-UAT-nn].
class TestScenarioEntry {
  String? content;
  String? scenarioName;
  String? description;
  String? expectedResult;
}
