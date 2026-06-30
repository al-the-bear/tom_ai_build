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

  /// Reference documents — the catalogue of documents this specification draws
  /// on (standards, policies, regulations, related specs). Re-homed here from
  /// the former §3 `Administrative` wrapper in L34C-5: referenced documents are
  /// ISO/IEC/IEEE 29148 §6 front matter and belong with document control.
  ReferenceDocuments referenceDocuments = ReferenceDocuments();
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

// ---------------------------------------------------------------------------
// Reference Documents (re-homed from the former §3 Administrative wrapper in
// L34C-5 — referenced documents are 29148 §6 front matter).
// ---------------------------------------------------------------------------

/// Reference Documents.
///
/// Catalog of all documents referenced by this project specification,
/// including enterprise standards, technical guidelines, regulatory
/// requirements, and related project documentation.
@ContentHelp('List all documents that provide context, requirements, '
    'constraints, or guidance for this project. Include enterprise '
    'architecture documents, standards, policies, regulations, '
    'and related project specifications.')
@SectionId('RD')
class ReferenceDocuments {
  @ContentType('description', 'Overview of reference document categories and '
      'their relevance to the project.')
  String? content;

  /// Reference document entries — contains 0+× Reference Document.
  @SectionId('RFDOC-DOCU-LST')
  @SectionIdPattern('RFDOC-DOCU-xxx')
  List<ReferenceDocumentEntry> documents = [];
}

/// A reference document entry (form).
///
/// Detailed metadata for a single referenced document including
/// identification, classification, status, and applicability.
@SectionId('RFDOC')
class ReferenceDocumentEntry {
  @Form([
    Field('documentTitle', String, 'Document Title', required: true),
    Field('documentId', String, 'Document ID (internal reference number)'),
    Field('version', String, 'Version'),
  ])
  String? content;

  /// Document metadata and relevance.
  ReferenceDocumentEntryMetadata metadata = ReferenceDocumentEntryMetadata();

  /// Governance and applicability information.
  ReferenceDocumentEntryGovernance governance =
      ReferenceDocumentEntryGovernance();

  /// Lifecycle and usage details.
  ReferenceDocumentEntryLifecycle lifecycle = ReferenceDocumentEntryLifecycle();

  /// Key sections or chapters within the document relevant to this project.
  DocumentRelevantSections relevantSections = DocumentRelevantSections();

  /// Relationship to other reference documents.
  DocumentRelationships relationships = DocumentRelationships();
}

/// Document metadata and relevance.
@SectionId('RDEM')
class ReferenceDocumentEntryMetadata {
  @Form([
    Field('author', String, 'Author / Issuing Organization'),
    Field('date', String, 'Publication / Effective Date'),
    Field('purpose', String, 'Purpose / Relevance to Project'),
    Field('location', String, 'Location (URL, repository, or physical)'),
    Field('documentType', String,
        'Document Type (Standard, Policy, Regulation, Specification, etc.)'),
  ])
  String? content;
}

/// Governance and applicability information.
@SectionId('RDEG')
class ReferenceDocumentEntryGovernance {
  @Form([
    Field('classification', String,
        'Classification (Public, Internal, Confidential, Restricted)'),
    Field('status', String,
        'Status (Current, Draft, Under Review, Superseded, Archived)'),
    Field('applicability', String,
        'Applicability (which project phases or components this applies to)'),
    Field('validUntil', String, 'Valid Until (expiration or review date)'),
    Field('lastReviewedDate', String, 'Last Reviewed Date'),
    Field('accessRestrictions', String,
        'Access Restrictions (who can access, special permissions required)'),
  ])
  String? content;
}

/// Lifecycle and usage details.
@SectionId('RDEL')
class ReferenceDocumentEntryLifecycle {
  @Form([
    Field('supersedes', String, 'Supersedes Document (if replacing older doc)'),
    Field('supersededBy', String, 'Superseded By (if this doc is deprecated)'),
    Field('language', String, 'Language'),
    Field('format', String, 'Format (PDF, Word, HTML, Confluence, etc.)'),
    Field('notes', String, 'Additional Notes'),
  ])
  String? content;
}

/// Key sections within a reference document relevant to the project.
@SectionId('DORESE')
class DocumentRelevantSections {
  @Form([
    Field('sectionReference', String,
        'Section Reference (chapter, section, or page number)', required: true),
    Field(
        'sectionTitle', String, 'Section Title or Description', required: true),
    Field('relevance', String, 'Relevance to Project'),
    Field('extractSummary', String,
        'Summary / Key Extract (brief summary of applicable content)'),
  ])
  String? content;

  /// Individual relevant section entries.
  @SectionId('RESEEN-SECT-LST')
  @SectionIdPattern('RESEEN-SECT-xxx')
  List<RelevantSectionEntry> sections = [];
}

/// A single relevant section entry within a reference document.
@SectionId('RESEEN')
class RelevantSectionEntry {
  @Form([
    Field('sectionReference', String,
        'Section Reference (chapter, section, or page number)', required: true),
    Field(
        'sectionTitle', String, 'Section Title or Description', required: true),
    Field('relevance', String,
        'Relevance (how this section applies to the project)'),
    Field('extractSummary', String,
        'Summary / Key Extract (brief summary of applicable content)'),
    Field('complianceRequired', bool,
        'Compliance Required (must project comply with this section?)'),
  ])
  String? content;
}

/// Relationships between reference documents.
@SectionId('DORE')
class DocumentRelationships {
  @ContentType('description', 'Describe how this document relates to '
      'other reference documents in the catalog.')
  String? content;

  /// Related document entries.
  @SectionId('REDOEN-RELA-LST')
  @SectionIdPattern('REDOEN-RELA-xxx')
  List<RelatedDocumentEntry> relatedDocuments = [];
}

/// A relationship to another reference document.
@SectionId('REDOEN')
class RelatedDocumentEntry {
  @Form([
    Field('relatedDocumentId', String, 'Related Document ID', required: true),
    Field('relatedDocumentTitle', String, 'Related Document Title'),
    Field('relationshipType', String,
        'Relationship Type (Depends On, Referenced By, Supersedes, '
            'Complements, Conflicts With, Parent Of, Child Of)'),
    Field('relationshipDescription', String,
        'Relationship Description (explain the connection)'),
  ])
  String? content;
}
