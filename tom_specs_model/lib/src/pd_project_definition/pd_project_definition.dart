import '../common/common.dart';

import 'access_authorization.dart';
import 'administrative.dart';
import 'business_data_model.dart';
import 'components.dart';
import 'current_state_analysis.dart';
import 'delivery_acceptance.dart';
import 'organizational_framework.dart';
import 'project_organization_process.dart';
import 'system_overview.dart';
import 'system_quality_goals.dart';
import 'system_stage_plan.dart';
import 'target_business_process.dart';
import 'technical_framework.dart';
import 'user_interface_design.dart';

export 'access_authorization.dart';
export 'administrative.dart';
export 'business_data_model.dart';
export 'components.dart';
export 'current_state_analysis.dart';
export 'delivery_acceptance.dart';
export 'organizational_framework.dart';
export 'project_organization_process.dart';
export 'system_overview.dart';
export 'system_quality_goals.dart';
export 'system_stage_plan.dart';
export 'target_business_process.dart';
export 'technical_framework.dart';
export 'user_interface_design.dart';

/// PD00 Project Definition — the central TomSpecs document.
///
/// Contains 14 major sections covering all aspects of a software project
/// from current state analysis through delivery acceptance. Each section
/// maps to specific Phase 3 DocSpec documents via seed references.
class ProjectDefinition {
  /// Document header (ID, project, version, date, author, status).
  final DocumentHeader header;

  /// 1. Current State Analysis [PD00-CUR].
  final CurrentStateAnalysis currentStateAnalysis;

  /// 2. Project Organization and Process [PD00-POP].
  final ProjectOrganizationAndProcess projectOrganization;

  /// 3. Administrative [PD00-ADM].
  final Administrative administrative;

  /// 4. System Overview [PD00-SYO].
  final SystemOverview systemOverview;

  /// 5. Organizational Framework [PD00-ORG].
  final OrganizationalFramework organizationalFramework;

  /// 6. Target Business Process Model [PD00-TAR].
  final TargetBusinessProcessModel targetBusinessProcess;

  /// 7. Business Object and Data Model [PD00-BUS]. Seeds → BDM.
  final BusinessObjectAndDataModel businessDataModel;

  /// 8. Technical Framework Concept [PD00-TEC]. Seeds → TR.
  final TechnicalFrameworkConcept technicalFramework;

  /// 9. Access and Authorization Concept [PD00-ACC]. Seeds → AC.
  final AccessAndAuthorizationConcept accessAuthorization;

  /// 10. User Interface Design and Prototype [PD00-USE]. Seeds → UP, SR, TR.
  final UserInterfaceDesign userInterfaceDesign;

  /// 11. System Quality Goals [PD00-SYQ]. Seeds → BQP.
  final SystemQualityGoals systemQualityGoals;

  /// 12. Components to Use [PD00-COM]. Seeds → TR.
  final ComponentsToUse components;

  /// 13. System Stage Plan [PD00-SSP]. Seeds → PPP.
  final SystemStagePlan systemStagePlan;

  /// 14. Delivery Scope and Acceptance [PD00-DEL]. Seeds → BQP (partial).
  final DeliveryScopeAndAcceptance deliveryAcceptance;

  const ProjectDefinition({
    required this.header,
    this.currentStateAnalysis = const CurrentStateAnalysis(),
    this.projectOrganization = const ProjectOrganizationAndProcess(),
    this.administrative = const Administrative(),
    this.systemOverview = const SystemOverview(),
    this.organizationalFramework = const OrganizationalFramework(),
    this.targetBusinessProcess = const TargetBusinessProcessModel(),
    this.businessDataModel = const BusinessObjectAndDataModel(),
    this.technicalFramework = const TechnicalFrameworkConcept(),
    this.accessAuthorization = const AccessAndAuthorizationConcept(),
    this.userInterfaceDesign = const UserInterfaceDesign(),
    this.systemQualityGoals = const SystemQualityGoals(),
    this.components = const ComponentsToUse(),
    this.systemStagePlan = const SystemStagePlan(),
    this.deliveryAcceptance = const DeliveryScopeAndAcceptance(),
  });
}
