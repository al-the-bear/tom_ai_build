/// Top-level Solution Blueprint document model.
///
/// Aggregates the Solution Blueprint (SBP) sections plus the document header.
/// The section sequence follows the public-standards order (SBP.1 … SBP.15);
/// the new SBP.1/3/6/9/10 sections are added in IP-6.
library;


export 'administrative.dart';
export 'components.dart';
export 'current_landscape.dart';
export 'delivery_acceptance.dart';
export 'delivery_transition_and_rollout.dart';
export 'experience_and_interface_design.dart';
export 'information_and_data_model.dart';
export 'introduction_and_scope.dart';
export 'organizational_framework.dart';
export 'project_organization_process.dart';
export 'quality_and_acceptance_model.dart';
export 'security_and_access_model.dart';
export 'solution_architecture_and_technology.dart';
export 'stakeholders_and_governance.dart';
export 'system_quality_goals.dart';
export 'system_rollout_concept.dart';
export 'system_stage_plan.dart';
export 'target_business_process.dart';
export 'target_operating_model_concept.dart';
export 'technical_framework.dart';

import 'package:tom_specs_model/src/common/document_header.dart';

import 'package:tom_specs_core/tom_specs_core.dart';

import 'current_landscape.dart';
import 'delivery_transition_and_rollout.dart';
import 'experience_and_interface_design.dart';
import 'information_and_data_model.dart';
import 'introduction_and_scope.dart';
import 'quality_and_acceptance_model.dart';
import 'security_and_access_model.dart';
import 'solution_architecture_and_technology.dart';
import 'stakeholders_and_governance.dart';
import 'target_operating_model_concept.dart';

/// The complete Solution Blueprint (SBP) document.
///
/// Contains a [DocumentHeader] and the SBP sections, sequenced per the
/// public-standards order (§4 of the redesign proposal).
@Document(
  name: 'Solution Blueprint',
  description: 'Comprehensive specification document covering all aspects of '
      'the system from current landscape through target operating model, '
      'information model, solution architecture, security, experience design, '
      'quality & acceptance, and delivery / transition planning.',
)
@SectionId('SBP')
class SolutionBlueprint {
  @Unused()
  String? content;

  /// SBP.1 Document Control seed (document header). Expanded in IP-6.
  DocumentHeader header = DocumentHeader();

  /// SBP.2 Introduction & Scope.
  IntroductionAndScope introductionAndScope = IntroductionAndScope();

  /// SBP.4 Stakeholders & Governance.
  StakeholdersAndGovernance stakeholdersAndGovernance =
      StakeholdersAndGovernance();

  /// SBP.5 Current Landscape. Seeds → CLA.
  CurrentLandscape currentLandscape = CurrentLandscape();

  /// SBP.7 Target Operating Model concept. Seeds → TOM.
  TargetOperatingModelConcept targetOperatingModelConcept =
      TargetOperatingModelConcept();

  /// SBP.8 Information & Data Model. Seeds → IFM.
  InformationAndDataModel informationAndDataModel = InformationAndDataModel();

  /// SBP.11 Solution Architecture & Technology. Seeds → ATS.
  SolutionArchitectureAndTechnology solutionArchitectureAndTechnology =
      SolutionArchitectureAndTechnology();

  /// SBP.12 Security & Access Model. Seeds → SAS.
  SecurityAndAccessModel securityAndAccessModel = SecurityAndAccessModel();

  /// SBP.13 Experience & Interface Design. Seeds → XDS.
  ExperienceAndInterfaceDesign experienceAndInterfaceDesign =
      ExperienceAndInterfaceDesign();

  /// SBP.14 Quality & Acceptance Model. Seeds → QAP.
  QualityAndAcceptanceModel qualityAndAcceptanceModel =
      QualityAndAcceptanceModel();

  /// SBP.15 Delivery, Transition & Rollout. Seeds → DRM, TRP.
  DeliveryTransitionAndRollout deliveryTransitionAndRollout =
      DeliveryTransitionAndRollout();
}
