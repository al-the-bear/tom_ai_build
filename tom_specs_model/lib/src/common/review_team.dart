/// Review teams and the reviewers a revision records.
///
/// A specification names who reviews its documents at three levels, and the
/// most specific level that names a team replaces the others entirely:
///
///  1. the [ReviewTeam] in a document's own root (`reviewTeam`);
///  2. the Solution Blueprint's [DocumentReviewTeamEntry] for that document's
///     root type;
///  3. the Solution Blueprint's default [ReviewTeam].
///
/// A team names a team only when it has at least one member; an empty team is
/// the same as none. Each revision entry of a review round lists its
/// reviewers as [ReviewerRecord]s, written out in full so that a guest
/// reviewer, who is on no team, still reads without a team list.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'enums.dart';

/// A review team: the members who review a document.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (review and approval)'],
  'The people who review a document in a review round: one entry per member, '
  'the owner marked.',
)
@FollowUpKind(
  [FollowUpProcess.doc],
  note:
      'document control — it names who reviews the document, not anything '
      'the system does. Reached as the SBP default team under '
      'StakeholdersAndGovernance and as the own team of each Phase 3 '
      'document root',
)
@SectionId('RVTEAM')
class ReviewTeam extends DocSpecsSection {
  @ContentHelp('''
Who reviews this document. The most specific team replaces the others
entirely: a document's own team, else the Solution Blueprint's team for its
document type, else the Solution Blueprint's default team. A team without
members names no team.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// The members of the team.
  @SectionId('RVMEM-MEMB-LST')
  @SectionIdPattern('RVMEM-MEMB-xxx')
  @ContentHelp(
    'Add one entry per member. Mark the specification owner with owner: true '
    'in the default team.',
  )
  @SerializationOrder(1)
  List<ReviewTeamMember> members = [];
}

/// One member of a review team (form).
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (review and approval)'],
  'A review team member: the id used in the annotation syntax and in file '
  'names, the display name, the role, and the owner flag.',
)
@SectionId('RVMEM')
class ReviewTeamMember extends DocSpecsSection {
  @Form([
    Field(
      'memberId',
      String,
      'Member Id',
      required: true,
      hint:
          'Short stable id: lowercase letters, digits and "_", e.g. "alice". '
          'Used in {@alice}, "**Answer (alice):**" and the copy file name.',
    ),
    Field('displayName', String, 'Display Name', required: true),
    Field('role', String, 'Role', required: true),
    Field(
      'stakeholder',
      String,
      'Stakeholder',
      refersTo: ['STKRE.@sectionId'],
      hint: 'The stakeholder register entry this member represents.',
    ),
    Field('email', String, 'E-Mail', hint: 'Stored only; nothing sends mail.'),
    Field(
      'owner',
      bool,
      'Owner',
      hint: 'true for the specification owner, who is always a reviewer.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// The Solution Blueprint's review team for one document type (form + members).
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (review and approval)'],
  'The review team of the documents of one root type, replacing the default '
  'team for them.',
)
@SectionId('DCRVTM')
class DocumentReviewTeamEntry extends DocSpecsSection {
  @Form([
    Field(
      'documentType',
      SpecDocumentType,
      'Document Type',
      required: true,
      hint: 'The document root type this team reviews; one entry per type.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// The members of the team.
  @SectionId('RVMEM-MEMB-LST')
  @SectionIdPattern('RVMEM-MEMB-xxx')
  @ContentHelp('Add one entry per member of this document type\'s team.')
  @SerializationOrder(1)
  List<ReviewTeamMember> members = [];
}

/// A reviewer recorded in a revision entry (form).
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (revision history)'],
  'A reviewer of one revision, written out in full so that a guest reviewer '
  'reads without a team list.',
)
@SectionId('RVWER')
class ReviewerRecord extends DocSpecsSection {
  @Form([
    Field(
      'memberId',
      String,
      'Member Id',
      required: true,
      hint: 'The member id, as in the team, or the guest\'s id.',
    ),
    Field('displayName', String, 'Display Name', required: true),
    Field('role', String, 'Role'),
    Field(
      'guest',
      bool,
      'Guest',
      hint: 'true for a reviewer who was not on the team the round used.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
