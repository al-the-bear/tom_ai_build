/// SBP.4 — Stakeholders & Governance.
///
/// Consolidates the project's organizational and administrative framing:
/// governance, steering, RACI (from [ProjectOrganizationAndProcess]) and the
/// team, distribution list, change procedure, and legal/contractual
/// requirements, plus a stakeholder register ([StakeholderRegisterEntry]
/// list). `ReferenceDocuments` belongs to SBP.1 `DocumentControl`, not here.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'governance_administration.dart';
import 'project_process_adjustments.dart';

/// SBP.4 Stakeholders & Governance.
@StandardReferences(
  ['BABOK v3 — stakeholder analysis', 'PMBOK — project governance'],
  'Who has a stake in the project and how it is governed: steering, RACI, '
  'communication, change control, and legal/contractual framing.',
)
@FollowUpKind([FollowUpProcess.org])
@SectionId('STKG')
class StakeholdersAndGovernance extends DocSpecsSection {
  @ContentHelp('''
Executive summary of the project's stakeholder and governance arrangements.
Describe the overall governance model, communication approach, and key
administrative agreements that govern this project. Highlight any deviations
from standard organizational project governance procedures.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Governance overview summary statistics (folded in from the former
  /// `AdministrativeSummary` when the `Administrative` wrapper was dissolved).
  @SectionId('ADMSM')
  @StandardReferences(
    [
      'PMBOK — project governance & organizational structure',
      'ISO 21500 — project management (governance, roles & responsibilities)',
    ],
    'An at-a-glance roll-up of the project administration: team size, governance '
    'model, key decision-maker, and meeting cadence.',
  )
  @Form([
    Field(
      'totalTeamMembers',
      int,
      'Total Team Members',
      hint: 'Number of people assigned to the project',
    ),
    Field(
      'internalResources',
      int,
      'Internal Resources',
      hint: 'Number of internal staff',
    ),
    Field(
      'externalResources',
      int,
      'External Resources',
      hint: 'Number of contractors, consultants, vendors',
    ),
    Field(
      'steeringCommitteeSize',
      int,
      'Steering Committee Size',
      hint: 'Number of steering committee members',
    ),
    Field(
      'distributionListSize',
      int,
      'Distribution List Size',
      hint: 'Total recipients across all distribution lists',
    ),
    Field(
      'referenceDocumentsCount',
      int,
      'Reference Documents Count',
      hint: 'Number of referenced documents',
    ),
    Field(
      'keyDecisionMaker',
      String,
      'Key Decision Maker',
      hint: 'Primary authority for project decisions',
    ),
    Field(
      'projectManagerName',
      String,
      'Project Manager',
      hint: 'Name of the project manager',
    ),
    Field(
      'governanceModel',
      String,
      'Governance Model',
      hint: 'Type of governance structure in place',
    ),
    Field(
      'meetingCadenceOverview',
      String,
      'Meeting Cadence Overview',
      hint: 'Summary of regular meetings and frequency',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? summary;

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

  /// Stakeholder register.
  @StandardReferences(
    ['BABOK v3 — stakeholder analysis (RACI / influence-interest grid)'],
    'The canonical source of truth for the role, interest, influence, concerns, '
    'and engagement strategy of each stakeholder.',
  )
  @SectionId('STKRE-STAK-LST')
  @SectionIdPattern('STKRE-STAK-xxx')
  @ContentHelp('Add one entry per stakeholder or group (STK-NNN).')
  @SerializationOrder(8)
  List<StakeholderRegisterEntry> stakeholderRegister = [];
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
class StakeholderRegisterEntry extends DocSpecsSection {
  @Form([
    Field('role', String, 'Role', required: true),
    Field('interest', String, 'Interest (what they care about)'),
    Field('influence', String, 'Influence (High, Medium, Low)'),
    Field('concerns', String, 'Concerns'),
    Field('engagementStrategy', String, 'Engagement Strategy'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
