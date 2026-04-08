/// Section 14: Delivery Scope and Acceptance [PD00-DEL].
///
/// Agreements regarding delivery scope and acceptance for the system.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 14. Delivery Scope and Acceptance [PD00-DEL].
@tomReflector
class DeliveryScopeAndAcceptance {
  final String? content;

  /// 14.1. Delivery and Service Scope [PD00-DEL-DEL].
  final DeliveryScope deliveryScope;

  /// 14.2. Acceptance Plan [PD00-DEL-ACC]. Seeds → BQP.
  final AcceptancePlan acceptancePlan;

  const DeliveryScopeAndAcceptance({
    this.content,
    this.deliveryScope = const DeliveryScope(),
    this.acceptancePlan = const AcceptancePlan(),
  });
}

/// 14.1. Delivery and Service Scope [PD00-DEL-DEL].
@tomReflector
class DeliveryScope {
  final String? content;

  /// 14.1.1. Software Deliverables [PD00-DEL-DEL-SOF].
  final SoftwareDeliverables softwareDeliverables;

  /// 14.1.2. Documentation Deliverables [PD00-DEL-DEL-DOC].
  final DocumentationDeliverables documentationDeliverables;

  /// 14.1.3. Training Deliverables [PD00-DEL-DEL-TRA].
  final TrainingDeliverables trainingDeliverables;

  /// 14.1.4. Support Deliverables [PD00-DEL-DEL-SUP].
  final SupportDeliverables supportDeliverables;

  const DeliveryScope({
    this.content,
    this.softwareDeliverables = const SoftwareDeliverables(),
    this.documentationDeliverables = const DocumentationDeliverables(),
    this.trainingDeliverables = const TrainingDeliverables(),
    this.supportDeliverables = const SupportDeliverables(),
  });
}

/// 14.1.1. Software Deliverables [PD00-DEL-DEL-SOF].
@tomReflector
class SoftwareDeliverables {
  final String? content;
  final List<DeliverableEntry> items;

  const SoftwareDeliverables({this.content, this.items = const []});
}

/// 14.1.2. Documentation Deliverables [PD00-DEL-DEL-DOC].
@tomReflector
class DocumentationDeliverables {
  final String? content;
  final List<DeliverableEntry> items;

  const DocumentationDeliverables({this.content, this.items = const []});
}

/// 14.1.3. Training Deliverables [PD00-DEL-DEL-TRA].
@tomReflector
class TrainingDeliverables {
  final String? content;
  final List<DeliverableEntry> items;

  const TrainingDeliverables({this.content, this.items = const []});
}

/// 14.1.4. Support Deliverables [PD00-DEL-DEL-SUP].
@tomReflector
class SupportDeliverables {
  final String? content;
  final List<DeliverableEntry> items;

  const SupportDeliverables({this.content, this.items = const []});
}

/// A deliverable entry (form).
@tomReflector
class DeliverableEntry {
  final String? content;
  final String? deliverableName;
  final String? description;
  final String? deliveryDate;
  final String? format;
  final String? acceptanceCriteria;

  const DeliverableEntry({
    this.content,
    this.deliverableName,
    this.description,
    this.deliveryDate,
    this.format,
    this.acceptanceCriteria,
  });
}

/// 14.2. Acceptance Plan [PD00-DEL-ACC]. Seeds → BQP.
@tomReflector
class AcceptancePlan {
  final String? content;

  /// 14.2.1. Acceptance Criteria [PD00-DEL-ACC-CRI].
  final AcceptanceCriteriaList acceptanceCriteria;

  /// 14.2.2. Acceptance Process [PD00-DEL-ACC-PRO].
  final AcceptanceProcess acceptanceProcess;

  /// 14.2.3. User Acceptance Testing [PD00-DEL-ACC-UAT].
  final UserAcceptanceTesting userAcceptanceTesting;

  /// 14.2.4. Defect Resolution [PD00-DEL-ACC-DEF].
  final String? defectResolution;

  /// 14.2.5. Sign-off Process [PD00-DEL-ACC-SIG].
  final String? signOffProcess;

  /// 14.2.6. Warranty [PD00-DEL-ACC-WAR].
  final String? warranty;

  const AcceptancePlan({
    this.content,
    this.acceptanceCriteria = const AcceptanceCriteriaList(),
    this.acceptanceProcess = const AcceptanceProcess(),
    this.userAcceptanceTesting = const UserAcceptanceTesting(),
    this.defectResolution,
    this.signOffProcess,
    this.warranty,
  });
}

/// 14.2.1. Acceptance Criteria [PD00-DEL-ACC-CRI].
@tomReflector
class AcceptanceCriteriaList {
  final String? content;
  final List<AcceptanceCriterionEntry> items;

  const AcceptanceCriteriaList({this.content, this.items = const []});
}

/// An acceptance criterion entry (form).
@tomReflector
class AcceptanceCriterionEntry {
  final String? content;
  final String? criterion;
  final String? category;
  final String? verificationMethod;
  final String? acceptanceThreshold;

  const AcceptanceCriterionEntry({
    this.content,
    this.criterion,
    this.category,
    this.verificationMethod,
    this.acceptanceThreshold,
  });
}

/// 14.2.2. Acceptance Process [PD00-DEL-ACC-PRO].
@tomReflector
class AcceptanceProcess {
  final String? content;
  final List<String> steps;
  final String? timeline;
  final String? participants;
  final String? escalationProcess;

  const AcceptanceProcess({
    this.content,
    this.steps = const [],
    this.timeline,
    this.participants,
    this.escalationProcess,
  });
}

/// 14.2.3. User Acceptance Testing [PD00-DEL-ACC-UAT].
@tomReflector
class UserAcceptanceTesting {
  final String? content;
  final String? scope;
  final String? environment;
  final String? participants;
  final String? schedule;
  final List<String> testScenarios;
  final String? exitCriteria;

  const UserAcceptanceTesting({
    this.content,
    this.scope,
    this.environment,
    this.participants,
    this.schedule,
    this.testScenarios = const [],
    this.exitCriteria,
  });
}
