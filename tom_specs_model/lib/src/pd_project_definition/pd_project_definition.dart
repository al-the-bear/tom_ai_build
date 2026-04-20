/// Top-level Project Definition document model.
///
/// Aggregates all 14 PD sections plus the document header.
library;


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
export 'system_rollout_concept.dart';
export 'system_stage_plan.dart';
export 'target_business_process.dart';
export 'technical_framework.dart';
export 'user_interface_design.dart';

import 'package:tom_specs_model/src/common/document_header.dart';

import 'package:tom_specs_core/tom_specs_core.dart';

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
import 'system_rollout_concept.dart';
import 'system_stage_plan.dart';
import 'target_business_process.dart';
import 'technical_framework.dart';
import 'user_interface_design.dart';

/// The complete Project Definition (PD) document.
///
/// Contains a [DocumentHeader] and all 14 PD sections [PD00].
@Document(
  name: 'Project Definition',
  description: 'Comprehensive specification document covering all aspects of '
      'the system from current state analysis through implementation planning, '
      'organizational framework, business processes, data models, technical '
      'framework, security, and user interface design.',
)
@SectionId('PD00')
class ProjectDefinition {
  @Unused()
  String? content;

  /// Document header (form fields at top of document).
  DocumentHeader header = DocumentHeader();

  /// 1. Current State Analysis [PD00-CUR].
  CurrentStateAnalysis currentStateAnalysis = CurrentStateAnalysis();

  /// 2. Project Organization and Process [PD00-POP].
  ProjectOrganizationAndProcess projectOrganizationProcess = ProjectOrganizationAndProcess();

  /// 3. Administrative [PD00-ADM].
  Administrative administrative = Administrative();

  /// 4. System Overview [PD00-SYO].
  SystemOverview systemOverview = SystemOverview();

  /// 5. Organizational Framework [PD00-ORG].
  OrganizationalFramework organizationalFramework = OrganizationalFramework();

  /// 6. Target Business Process Model [PD00-TAR].
  TargetBusinessProcessModel targetBusinessProcess = TargetBusinessProcessModel();

  /// 7. Business Object and Data Model [PD00-BUS].
  BusinessObjectAndDataModel businessDataModel = BusinessObjectAndDataModel();

  /// 8. Technical Framework Concept [PD00-TEC].
  TechnicalFrameworkConcept technicalFramework = TechnicalFrameworkConcept();

  /// 9. Access and Authorization Concept [PD00-ACC].
  AccessAndAuthorizationConcept accessAuthorization = AccessAndAuthorizationConcept();

  /// 10. User Interface Design [PD00-USE].
  UserInterfaceDesign userInterfaceDesign = UserInterfaceDesign();

  /// 15. System Rollout Concept [PD00-ROL]. Seeds → SR.
  SystemRolloutConcept systemRolloutConcept = SystemRolloutConcept();

  /// 11. System Quality Goals [PD00-SYQ].
  SystemQualityGoals systemQualityGoals = SystemQualityGoals();

  /// 12. Components to Use [PD00-COM].
  ComponentsToUse componentsToUse = ComponentsToUse();

  /// 13. System Stage Plan [PD00-SSP].
  SystemStagePlan systemStagePlan = SystemStagePlan();

  /// 14. Delivery Scope and Acceptance [PD00-DEL].
  DeliveryScopeAndAcceptance deliveryAcceptance = DeliveryScopeAndAcceptance();
}
