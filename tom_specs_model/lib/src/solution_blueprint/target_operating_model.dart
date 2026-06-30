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
@StandardReferences(
  ['BABOK v3 — future-state analysis'],
  'The future-state operating concept: how the organization and its business '
  'processes will work once the solution is in place.',
)
@SectionId('TOMC')
class TargetOperatingModel {
  @Unused()
  @SerializationOrder(0)
  String? content;

  /// Target organizational structure and roles.
  @SerializationOrder(1)
  OrganizationalFramework organizationalFramework = OrganizationalFramework();

  /// Target business process model.
  @SerializationOrder(2)
  TargetBusinessProcessModel targetBusinessProcess =
      TargetBusinessProcessModel();
}
