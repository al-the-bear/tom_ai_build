/// Section 14: Delivery Scope and Acceptance [PD00-DEL].
///
/// Agreements regarding delivery scope and acceptance for the system.
/// Subsection 14.2 seeds → BQP (Business Quality Plan).
class DeliveryScopeAndAcceptance {
  /// 14.1. Delivery and Service Scope [PD00-DEL-DEL].
  final DeliveryScope deliveryScope;

  /// 14.2. Acceptance Plan [PD00-DEL-ACC]. Seeds → BQP.
  final AcceptancePlan acceptancePlan;

  const DeliveryScopeAndAcceptance({
    this.deliveryScope = const DeliveryScope(),
    this.acceptancePlan = const AcceptancePlan(),
  });
}

/// 14.1. Delivery and Service Scope [PD00-DEL-DEL].
class DeliveryScope {
  /// 14.1.1. Software Deliverables [PD00-DEL-DEL-SOF].
  final String? softwareDeliverables;

  /// 14.1.2. Documentation Deliverables [PD00-DEL-DEL-DOC].
  final String? documentationDeliverables;

  /// 14.1.3. Training Deliverables [PD00-DEL-DEL-TRA].
  final String? trainingDeliverables;

  /// 14.1.4. Support Deliverables [PD00-DEL-DEL-SUP].
  final String? supportDeliverables;

  const DeliveryScope({
    this.softwareDeliverables,
    this.documentationDeliverables,
    this.trainingDeliverables,
    this.supportDeliverables,
  });
}

/// 14.2. Acceptance Plan [PD00-DEL-ACC]. Seeds → BQP.
class AcceptancePlan {
  /// 14.2.1. Acceptance Criteria [PD00-DEL-ACC-CRI].
  final String? acceptanceCriteria;

  /// 14.2.2. Acceptance Process [PD00-DEL-ACC-PRO].
  final String? acceptanceProcess;

  /// 14.2.3. User Acceptance Testing [PD00-DEL-ACC-UAT].
  final String? userAcceptanceTesting;

  /// 14.2.4. Defect Resolution [PD00-DEL-ACC-DEF].
  final String? defectResolution;

  /// 14.2.5. Sign-off Process [PD00-DEL-ACC-SIG].
  final String? signOffProcess;

  /// 14.2.6. Warranty [PD00-DEL-ACC-WAR].
  final String? warranty;

  const AcceptancePlan({
    this.acceptanceCriteria,
    this.acceptanceProcess,
    this.userAcceptanceTesting,
    this.defectResolution,
    this.signOffProcess,
    this.warranty,
  });
}
