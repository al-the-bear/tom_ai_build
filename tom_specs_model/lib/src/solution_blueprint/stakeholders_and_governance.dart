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

import 'governance_administration.dart';
import 'project_process_adjustments.dart';

/// SBP.4 Stakeholders & Governance.
@StandardReferences(
  [
    'BABOK v3 — stakeholder analysis',
    'PMBOK — project governance',
  ],
  'Who has a stake in the project and how it is governed: steering, RACI, '
  'communication, change control, and legal/contractual framing.',
)
@SectionId('STKG')
class StakeholdersAndGovernance {
  @ContentHelp('''
Executive summary of the project's stakeholder and governance arrangements.
Describe the overall governance model, communication approach, and key
administrative agreements that govern this project. Highlight any deviations
from standard organizational project governance procedures.
''')
  @SerializationOrder(0)
  String? content;

  /// Governance overview summary statistics (folded in from the former
  /// `AdministrativeSummary` when the `Administrative` wrapper was dissolved).
  @SerializationOrder(1)
  AdministrativeSummary summary = AdministrativeSummary();

  /// Governance, steering committee, RACI, process deviations.
  @SerializationOrder(2)
  ProjectOrganizationAndProcess projectOrganizationProcess =
      ProjectOrganizationAndProcess();

  /// Project organization (org structure, steering committee).
  @SerializationOrder(3)
  ProjectOrganization projectOrganization = ProjectOrganization();

  /// Project team staffing — contains 1+× Team Member.
  @SerializationOrder(4)
  ProjectTeamStaffing projectTeamStaffing = ProjectTeamStaffing();

  /// Distribution list and communication matrix.
  @SerializationOrder(5)
  DistributionList distributionList = DistributionList();

  /// Change procedure.
  @SerializationOrder(6)
  ChangeProcedure changeProcedure = ChangeProcedure();

  /// Legal and contractual requirements (IP, NDAs, compliance, audit).
  /// Renamed to `LegalAndContractualRequirements` in L34C-9.
  @SerializationOrder(7)
  LegalAndContractualRequirements legalAndContractual =
      LegalAndContractualRequirements();

  /// Stakeholder register (§5 completeness addition).
  @SerializationOrder(8)
  StakeholderRegister stakeholderRegister = StakeholderRegister();
}

/// The canonical register of the project's stakeholders (L34C-6 / SR-15).
///
/// This is the single source of truth for stakeholder role, interest,
/// influence, concerns and engagement strategy. SBP.2
/// `StakeholdersAndBeneficiaries` is a scope-framing benefits lens that
/// references this register rather than restating its attributes.
@StandardReferences(
  ['BABOK v3 — stakeholder analysis (RACI / influence-interest grid)'],
  'The canonical source of truth for the role, interest, influence, concerns, '
  'and engagement strategy of each stakeholder.',
)
@SectionId('STKRG')
class StakeholderRegister {
  @Unused()
  @SerializationOrder(0)
  String? content;

  /// One entry per stakeholder or stakeholder group.
  @SectionId('STKRG-STAK-LST')
  @SectionIdPattern('STKRG-STAK-xxx')
  @ContentHelp('Add one entry per stakeholder or group (STK-NNN).')
  @SerializationOrder(1)
  List<StakeholderRegisterEntry> stakeholders = [];
}

/// A single stakeholder register entry (form).
///
/// Named `StakeholderRegisterEntry` to avoid collision with the pre-existing
/// `StakeholderEntry` in `introduction_and_scope.dart` (D-IP6 deviation).
@StandardReferences(
  ['BABOK v3 — stakeholder analysis (RACI / influence-interest grid)'],
  'A single stakeholder register entry: role, interest, influence, concerns, '
  'and engagement strategy.',
)
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
  @SerializationOrder(0)
  String? content;
}
