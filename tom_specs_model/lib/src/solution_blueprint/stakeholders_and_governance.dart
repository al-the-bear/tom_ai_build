/// SBP.4 — Stakeholders & Governance.
///
/// Consolidates the project's organizational and administrative framing:
/// governance, steering, RACI (from [ProjectOrganizationAndProcess]) and the
/// team, distribution list, and reference documents (from [Administrative]).
/// A stakeholder register is added in IP-6.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'administrative.dart';
import 'project_organization_process.dart';

/// SBP.4 Stakeholders & Governance.
///
/// Public anchor: BABOK stakeholder analysis + PMBOK governance.
@SectionId('STKG')
class StakeholdersAndGovernance {
  @Unused()
  String? content;

  /// Governance, steering committee, RACI, process deviations.
  ProjectOrganizationAndProcess projectOrganizationProcess =
      ProjectOrganizationAndProcess();

  /// Team, distribution, reference documents, communication.
  Administrative administrative = Administrative();
}
