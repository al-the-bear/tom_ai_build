/// Top-level Solution Blueprint document model.
///
/// Aggregates the Solution Blueprint (SBP) sections plus the document header.
/// The section sequence follows the public-standards order (SBP.1 … SBP.15);
/// the new SBP.1/3/6/9/10 sections are added in IP-6.
library;


export 'administrative.dart';
export 'assumptions_constraints_dependencies.dart';
export 'business_process_model.dart';
export 'components.dart';
export 'current_landscape.dart';
export 'delivery_acceptance.dart';
export 'delivery_transition_and_rollout.dart';
export 'document_control.dart';
export 'experience_and_interface_design.dart';
export 'glossary_and_abbreviations.dart';
export 'information_and_data_model.dart';
export 'introduction_and_scope.dart';
export 'project_organization_process.dart';
export 'quality_and_acceptance_model.dart';
export 'requirements.dart';
export 'security_and_access_model.dart';
export 'solution_architecture_and_technology.dart';
export 'stakeholders_and_governance.dart';
export 'system_quality_goals.dart';
export 'system_rollout.dart';
export 'system_stage_plan.dart';
export 'target_operating_model.dart';
export 'target_organization.dart';
export 'technical_framework.dart';

import 'package:tom_specs_core/tom_specs_core.dart';

import 'assumptions_constraints_dependencies.dart';
import 'current_landscape.dart';
import 'delivery_transition_and_rollout.dart';
import 'document_control.dart';
import 'experience_and_interface_design.dart';
import 'glossary_and_abbreviations.dart';
import 'information_and_data_model.dart';
import 'introduction_and_scope.dart';
import 'quality_and_acceptance_model.dart';
import 'requirements.dart';
import 'security_and_access_model.dart';
import 'solution_architecture_and_technology.dart';
import 'stakeholders_and_governance.dart';
import 'target_operating_model.dart';

/// The complete Solution Blueprint (SBP) document.
///
/// Contains a [DocumentControl] header block and the SBP sections, sequenced
/// per the public-standards order (§4 of the redesign proposal).
@Document(
  name: 'Solution Blueprint',
  description: 'Comprehensive specification document covering all aspects of '
      'the system from current landscape through target operating model, '
      'information model, solution architecture, security, experience design, '
      'quality & acceptance, and delivery / transition planning.',
)
@SectionId('SBP')
class D00SolutionBlueprint {
  @Unused()
  @SerializationOrder(0)
  String? content;

  /// SBP.1 Document Control (header + revision history + approvals).
  @SerializationOrder(1)
  DocumentControl documentControl = DocumentControl();

  /// SBP.2 Introduction & Scope.
  @SerializationOrder(2)
  IntroductionAndScope introductionAndScope = IntroductionAndScope();

  /// SBP.3 Glossary & Abbreviations.
  @SerializationOrder(3)
  GlossaryAndAbbreviations glossaryAndAbbreviations =
      GlossaryAndAbbreviations();

  /// SBP.4 Stakeholders & Governance.
  @SerializationOrder(4)
  StakeholdersAndGovernance stakeholdersAndGovernance =
      StakeholdersAndGovernance();

  /// SBP.5 Current Landscape. Seeds → CLA.
  @SerializationOrder(5)
  CurrentLandscape currentLandscape = CurrentLandscape();

  /// SBP.6 Assumptions, Constraints & Dependencies.
  @SerializationOrder(6)
  AssumptionsConstraintsDependencies assumptionsConstraintsDependencies =
      AssumptionsConstraintsDependencies();

  /// SBP.7 Target Operating Model concept. Seeds → TOM.
  @SerializationOrder(7)
  TargetOperatingModel targetOperatingModelConcept =
      TargetOperatingModel();

  /// SBP.8 Information & Data Model. Seeds → IFM.
  @SerializationOrder(8)
  InformationAndDataModel informationAndDataModel = InformationAndDataModel();

  /// SBP.9 Requirements (functional + NFR sub-areas). Seeds → RSP.
  @SerializationOrder(9)
  Requirements requirements = Requirements();

  /// SBP.11 Solution Architecture & Technology. Seeds → ATS.
  @SerializationOrder(10)
  SolutionArchitectureAndTechnology solutionArchitectureAndTechnology =
      SolutionArchitectureAndTechnology();

  /// SBP.12 Security & Access Model. Seeds → SAS.
  @SerializationOrder(11)
  SecurityAndAccessModel securityAndAccessModel = SecurityAndAccessModel();

  /// SBP.13 Experience & Interface Design. Seeds → XDS.
  @SerializationOrder(12)
  ExperienceAndInterfaceDesign experienceAndInterfaceDesign =
      ExperienceAndInterfaceDesign();

  /// SBP.14 Quality & Acceptance Model. Seeds → QAP.
  @SerializationOrder(13)
  QualityAndAcceptanceModel qualityAndAcceptanceModel =
      QualityAndAcceptanceModel();

  /// SBP.15 Delivery, Transition & Rollout. Seeds → DRM, TRP.
  @SerializationOrder(14)
  DeliveryTransitionAndRollout deliveryTransitionAndRollout =
      DeliveryTransitionAndRollout();
}
