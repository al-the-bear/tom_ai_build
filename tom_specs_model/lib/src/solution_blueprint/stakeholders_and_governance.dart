/// SBP.4 — Stakeholders & Governance.
///
/// Consolidates the project's organizational and administrative framing:
/// governance, steering, RACI (from [ProjectOrganizationAndProcess]) and the
/// team, distribution list, change procedure, and legal/contractual
/// requirements. A [StakeholderRegister] (§5 completeness addition) was added
/// in IP-6. The former `Administrative` (`ADMN`) wrapper was dissolved in
/// L34C-5: its children now hang directly off this node, and
/// `ReferenceDocuments` was re-homed to SBP.1 `DocumentControl`.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'administrative.dart';
import 'project_organization_process.dart';

/// SBP.4 Stakeholders & Governance.
///
/// Public anchor: BABOK stakeholder analysis + PMBOK governance.
@SectionId('STKG')
class StakeholdersAndGovernance {
  @ContentHelp('''
Executive summary of the project's stakeholder and governance arrangements.
Describe the overall governance model, communication approach, and key
administrative agreements that govern this project. Highlight any deviations
from standard organizational project governance procedures.
''')
  String? content;

  /// Governance overview summary statistics (folded in from the former
  /// `AdministrativeSummary` when the `Administrative` wrapper was dissolved).
  AdministrativeSummary summary = AdministrativeSummary();

  /// Governance, steering committee, RACI, process deviations.
  ProjectOrganizationAndProcess projectOrganizationProcess =
      ProjectOrganizationAndProcess();

  /// Project organization (org structure, steering committee).
  ProjectOrganization projectOrganization = ProjectOrganization();

  /// Project team staffing — contains 1+× Team Member.
  ProjectTeamStaffing projectTeamStaffing = ProjectTeamStaffing();

  /// Distribution list and communication matrix.
  DistributionList distributionList = DistributionList();

  /// Change procedure.
  ChangeProcedure changeProcedure = ChangeProcedure();

  /// Legal and contractual requirements (IP, NDAs, compliance, audit).
  /// Renamed to `LegalAndContractualRequirements` in L34C-9.
  OtherAdministrativeRequirements legalAndContractual =
      OtherAdministrativeRequirements();

  /// Stakeholder register (§5 completeness addition).
  StakeholderRegister stakeholderRegister = StakeholderRegister();
}

/// A register of the project's stakeholders.
///
/// Public anchor: BABOK stakeholder analysis (RACI / influence-interest grid).
@SectionId('STKRG')
class StakeholderRegister {
  @Unused()
  String? content;

  /// One entry per stakeholder or stakeholder group.
  @SectionId('STKRG-STAK-LST')
  @SectionIdPattern('STKRG-STAK-xxx')
  @ContentHelp('Add one entry per stakeholder or group (STK-NNN).')
  List<StakeholderRegisterEntry> stakeholders = [];
}

/// A single stakeholder register entry (form).
///
/// Named `StakeholderRegisterEntry` to avoid collision with the pre-existing
/// `StakeholderEntry` in `introduction_and_scope.dart` (D-IP6 deviation).
@SectionId('STKRE')
class StakeholderRegisterEntry {
  @Form([
    Field('stakeholderId', String, 'Stakeholder ID (STK-NNN)', required: true),
    Field('name', String, 'Name or Group', required: true),
    Field('role', String, 'Role', required: true),
    Field('interest', String, 'Interest (what they care about)'),
    Field('influence', String, 'Influence (High, Medium, Low)'),
    Field('concerns', String, 'Concerns'),
    Field('engagementStrategy', String, 'Engagement Strategy'),
  ])
  String? content;
}
