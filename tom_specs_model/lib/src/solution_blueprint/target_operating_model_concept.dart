/// SBP.7 — Target Operating Model (concept).
///
/// Consolidates the future-state operating concept: the target organizational
/// structure (from [OrganizationalFramework]) and the target business process
/// model (from [TargetBusinessProcessModel]). Seeds the Target Operating Model
/// (TOM) document.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'organizational_framework.dart';
import 'target_business_process.dart';

/// SBP.7 Target Operating Model concept.
///
/// Public anchor: BABOK future-state analysis.
@SectionId('TOMC')
class TargetOperatingModelConcept {
  @Unused()
  String? content;

  /// Target organizational structure and roles.
  OrganizationalFramework organizationalFramework = OrganizationalFramework();

  /// Target business process model.
  TargetBusinessProcessModel targetBusinessProcess =
      TargetBusinessProcessModel();
}
