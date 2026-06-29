/// SBP.1 — Document Control.
///
/// Front-matter document governance: the document header plus a revision
/// history and approval record. Closes the prior-review completeness gap
/// (§5: "Revision history + approvals").
///
/// Public anchor: ISO/IEC/IEEE 29148 §6 front matter.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';

/// SBP.1 Document Control.
///
/// Holds the [DocumentHeader] (id, project, version, date, author, status)
/// together with the document's [RevisionHistory] and the [ApprovalRecord]s
/// that gate its release.
@SectionId('DOCTL')
class DocumentControl {
  @Unused()
  String? content;

  /// Document header form (id, project, version, date, author, status).
  DocumentHeader header = DocumentHeader();

  /// Chronological revision history of this document.
  RevisionHistory revisionHistory = RevisionHistory();

  /// Formal approvals (sign-offs) recorded for this document.
  @SectionId('DOCTL-APRV-LST')
  @SectionIdPattern('DOCTL-APRV-xxx')
  @ContentHelp('Add one entry per required sign-off (e.g. sponsor, product '
      'owner, architecture board).')
  List<ApprovalRecord> approvals = [];
}

/// Chronological revision history.
@SectionId('RVHST')
class RevisionHistory {
  @Unused()
  String? content;

  /// One entry per published revision of the document.
  @SectionId('RVHST-REVS-LST')
  @SectionIdPattern('RVHST-REVS-xxx')
  @ContentHelp('Add one entry per revision, newest last.')
  List<RevisionEntry> revisions = [];
}

/// A single document revision entry (form).
@SectionId('RVENT')
class RevisionEntry {
  @Form([
    Field('version', String, 'Version', required: true),
    Field('date', String, 'Date', required: true),
    Field('author', String, 'Author', required: true),
    Field('summary', String, 'Summary of changes'),
  ])
  String? content;
}

/// A formal approval / sign-off record (form).
@SectionId('APREC')
class ApprovalRecord {
  @Form([
    Field('role', String, 'Approver Role', required: true),
    Field('name', String, 'Approver Name', required: true),
    Field('date', String, 'Approval Date'),
    Field('status', String, 'Status (Pending, Approved, Rejected)'),
  ])
  String? content;
}
