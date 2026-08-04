/// SBP.1 — Document Control.
///
/// Front-matter document governance: the document header plus a revision
/// history and approval record.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';

/// SBP.1 Document Control.
///
/// Holds the [DocumentHeader] (id, project, version, date, author, status)
/// together with the document's revision history ([RevisionEntry] list) and
/// the [ApprovalRecord]s that gate its release.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (document control)'],
  'Front-matter governance of the document itself: its header identity, '
  'revision history, formal approvals, and the catalogue of documents it '
  'references.',
)
@ContentHelp(
  'Fill in the document header, then maintain the revision history, '
  'approvals, and reference-document catalogue as the specification evolves. '
  'This section governs the document — not the system it describes.',
)
@FollowUpKind([FollowUpProcess.doc])
@SectionId('DOCTL')
class DocumentControl extends DocSpecsSection {
  @Unused()
  @override
  @SerializationOrder(0)
  String? content;

  /// Document header form (id, project, version, date, author, status).
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// Chronological revision history of this document.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 §6 — front matter (revision history)',
  ], 'The ordered set of published revisions of this document.')
  @SectionId('RVENT-REVS-LST')
  @SectionIdPattern('RVENT-REVS-xxx')
  @ContentHelp(
    'Add one entry per revision, newest last. Each entry captures '
    'the version, date, author, and a short summary of what changed.',
  )
  @SerializationOrder(2)
  List<RevisionEntry> revisionHistory = [];

  /// Formal approvals (sign-offs) recorded for this document.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 §6 — front matter (approvals)',
  ], 'The set of formal sign-offs required before this document is released.')
  @SectionId('APREC-APRV-LST')
  @SectionIdPattern('APREC-APRV-xxx')
  @ContentHelp(
    'Add one entry per required sign-off (e.g. sponsor, product '
    'owner, architecture board). The document is not released until every '
    'listed approval is recorded.',
  )
  @SerializationOrder(3)
  List<ApprovalRecord> approvals = [];

  /// Reference documents — the catalogue of documents this specification draws
  /// on (standards, policies, regulations, related specs). They live here
  /// because referenced documents are ISO/IEC/IEEE 29148 §6 front matter and
  /// belong with document control.
  @SerializationOrder(4)
  ReferenceDocuments referenceDocuments = ReferenceDocuments();
}

/// A single document revision entry (form).
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (revision history)'],
  'A single published revision: its version, date, author, and a summary of '
  'what changed.',
)
@SectionId('RVENT')
class RevisionEntry extends DocSpecsSection {
  @Form([
    Field(
      'version',
      String,
      'Version',
      required: true,
      hint: 'Semantic version of this revision, e.g. "1.2.0".',
    ),
    Field(
      'date',
      String,
      'Date',
      required: true,
      hint: 'Date the revision was published (ISO 8601).',
    ),
    Field(
      'author',
      String,
      'Author',
      required: true,
      hint: 'Person or role who produced the revision.',
    ),
    Field(
      'summary',
      String,
      'Summary of changes',
      hint: 'One or two sentences on what changed and why.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A formal approval / sign-off record (form).
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (approvals)'],
  'A single formal sign-off gating the document\'s release: who approved, in '
  'what role, when, and with what status.',
)
@SectionId('APREC')
class ApprovalRecord extends DocSpecsSection {
  @Form([
    Field(
      'role',
      String,
      'Approver Role',
      required: true,
      hint: 'Governance role accountable for the sign-off, e.g. "Sponsor".',
    ),
    Field(
      'date',
      String,
      'Approval Date',
      hint: 'Date the approval was granted (ISO 8601).',
    ),
    Field(
      'status',
      String,
      'Status (Pending, Approved, Rejected)',
      hint: 'Current sign-off state: Pending, Approved, or Rejected.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// Reference Documents (ISO/IEC/IEEE 29148 §6 front matter).
// ---------------------------------------------------------------------------

/// Reference Documents.
///
/// Catalog of all documents referenced by this project specification,
/// including enterprise standards, technical guidelines, regulatory
/// requirements, and related project documentation.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)'],
  'The catalogue of external documents this specification draws on — '
  'standards, policies, regulations, and related specs.',
)
@ContentHelp(
  'List all documents that provide context, requirements, '
  'constraints, or guidance for this project. Include enterprise '
  'architecture documents, standards, policies, regulations, '
  'and related project specifications.',
)
@SectionId('RD')
class ReferenceDocuments extends DocSpecsSection {
  @ContentType(
    'description',
    'Overview of reference document categories and '
        'their relevance to the project.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Reference document entries — contains 0+× Reference Document.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)',
  ], 'The set of documents catalogued as references for this specification.')
  @SectionId('RFDOC-DOCU-LST')
  @SectionIdPattern('RFDOC-DOCU-xxx')
  @ContentHelp(
    'Add one entry per referenced document. Capture enough metadata '
    '(id, version, location, status) that a reader can locate and assess the '
    'referenced material.',
  )
  @SerializationOrder(1)
  List<ReferenceDocumentEntry> documents = [];
}

/// A reference document entry (form).
///
/// Detailed metadata for a single referenced document including
/// identification, classification, status, and applicability.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)'],
  'A single referenced document with its identification, classification, '
  'lifecycle, relevant sections, and relationships.',
)
@SectionId('RFDOC')
class ReferenceDocumentEntry extends DocSpecsSection {
  @Form([
    Field(
      'documentId',
      String,
      'Document ID (internal reference number)',
      hint: 'The catalogue or internal reference number this document is filed '
          'under, if any — owned outside this document',
    ),
    Field(
      'version',
      String,
      'Version',
      hint: 'Version or edition of the referenced document.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Document metadata and relevance.
  @SectionId('RDEM')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)'],
    'Identifying metadata for a referenced document: author/issuer, date, '
    'purpose, location, and type.',
  )
  @Form([
    Field(
      'author',
      String,
      'Author / Issuing Organization',
      hint: 'Who authored or issued the document, e.g. ISO, a vendor, a team.',
    ),
    Field(
      'date',
      String,
      'Publication / Effective Date',
      hint: 'Publication or effective date (ISO 8601).',
    ),
    Field(
      'purpose',
      String,
      'Purpose / Relevance to Project',
      hint: 'Why this document matters to the project.',
    ),
    Field(
      'location',
      String,
      'Location (URL, repository, or physical)',
      hint: 'Where the document can be found — URL, repo path, or location.',
    ),
    Field(
      'documentType',
      String,
      'Document Type (Standard, Policy, Regulation, Specification, etc.)',
      hint: 'Classify the document: Standard, Policy, Regulation, etc.',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? metadata;

  /// Governance and applicability information.
  @SectionId('RDEG')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)'],
    'Governance facts for a referenced document: classification, status, '
    'applicability, validity, and access restrictions.',
  )
  @Form([
    Field(
      'classification',
      String,
      'Classification (Public, Internal, Confidential, Restricted)',
      hint: 'Sensitivity level governing how the document may be shared.',
    ),
    Field(
      'status',
      String,
      'Status (Current, Draft, Under Review, Superseded, Archived)',
      hint: 'Lifecycle status of the referenced document.',
    ),
    Field(
      'applicability',
      String,
      'Applicability (which project phases or components this applies to)',
      hint: 'Which phases, components, or scope the document applies to.',
    ),
    Field(
      'validUntil',
      String,
      'Valid Until (expiration or review date)',
      hint: 'Expiry or next-review date, if the document has one.',
    ),
    Field(
      'lastReviewedDate',
      String,
      'Last Reviewed Date',
      hint: 'Date the document was last reviewed for relevance.',
    ),
    Field(
      'accessRestrictions',
      String,
      'Access Restrictions (who can access, special permissions required)',
      hint: 'Who may access the document and any permissions required.',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? governance;

  /// Lifecycle and usage details.
  @SectionId('RDEL')
  @StandardReferences(
    ['ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)'],
    'Lifecycle facts for a referenced document: supersession chain, language, '
    'format, and notes.',
  )
  @Form([
    Field(
      'supersedes',
      String,
      'Supersedes Document (if replacing older doc)',
      hint: 'Older document this one replaces, if any.',
    ),
    Field(
      'supersededBy',
      String,
      'Superseded By (if this doc is deprecated)',
      hint: 'Newer document that replaces this one, if deprecated.',
    ),
    Field(
      'language',
      String,
      'Language',
      hint: 'Primary language of the document (ISO 639 code or name).',
    ),
    Field(
      'format',
      String,
      'Format (PDF, Word, HTML, Confluence, etc.)',
      hint: 'File or publication format of the document.',
    ),
    Field(
      'notes',
      String,
      'Additional Notes',
      hint: 'Any further notes about the document\'s lifecycle or usage.',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? lifecycle;

  /// Key sections or chapters within the document relevant to this project.
  @SerializationOrder(4)
  DocumentRelevantSections relevantSections = DocumentRelevantSections();

  /// Relationship to other reference documents.
  @SerializationOrder(5)
  DocumentRelationships relationships = DocumentRelationships();
}

/// Key sections within a reference document relevant to the project.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)'],
  'The chapters or sections within a referenced document that are relevant to '
  'this project.',
)
@SectionId('DORESE')
class DocumentRelevantSections extends DocSpecsSection {
  @Form([
    Field(
      'sectionReference',
      String,
      'Section Reference (chapter, section, or page number)',
      required: true,
      hint: 'Locate the section: chapter, clause, or page number.',
    ),
    Field(
      'sectionTitle',
      String,
      'Section Title or Description',
      required: true,
      hint: 'Title or short description of the section.',
    ),
    Field(
      'relevance',
      String,
      'Relevance to Project',
      hint: 'How this section applies to the project.',
    ),
    Field(
      'extractSummary',
      String,
      'Summary / Key Extract (brief summary of applicable content)',
      hint: 'Brief summary or key extract of the applicable content.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Individual relevant section entries.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)',
  ], 'The set of relevant section entries within a referenced document.')
  @SectionId('RESEEN-SECT-LST')
  @SectionIdPattern('RESEEN-SECT-xxx')
  @ContentHelp(
    'Add one entry per chapter or section of the referenced '
    'document that the project depends on or must comply with.',
  )
  @SerializationOrder(1)
  List<RelevantSectionEntry> sections = [];
}

/// A single relevant section entry within a reference document.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)'],
  'A single relevant section within a referenced document, with its reference, '
  'relevance, extract, and compliance flag.',
)
@SectionId('RESEEN')
class RelevantSectionEntry extends DocSpecsSection {
  @Form([
    Field(
      'sectionReference',
      String,
      'Section Reference (chapter, section, or page number)',
      required: true,
      hint: 'Locate the section: chapter, clause, or page number.',
    ),
    Field(
      'relevance',
      String,
      'Relevance (how this section applies to the project)',
      hint: 'Explain how this section applies to the project.',
    ),
    Field(
      'extractSummary',
      String,
      'Summary / Key Extract (brief summary of applicable content)',
      hint: 'Brief summary or key extract of the applicable content.',
    ),
    Field(
      'complianceRequired',
      bool,
      'Compliance Required (must project comply with this section?)',
      hint: 'True if the project must comply with this section.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Relationships between reference documents.
@StandardReferences([
  'ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)',
], 'How this referenced document relates to other documents in the catalogue.')
@ContentHelp(
  'Record how this document relates to others in the catalogue '
  '(depends on, supersedes, complements, conflicts with) so readers can '
  'follow the dependency web between references.',
)
@SectionId('DORE')
class DocumentRelationships extends DocSpecsSection {
  @ContentType(
    'description',
    'Describe how this document relates to '
        'other reference documents in the catalog.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  /// Related document entries.
  @StandardReferences(
    ['ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)'],
    'The set of relationships from this document to other referenced '
    'documents.',
  )
  @SectionId('REDOEN-RELA-LST')
  @SectionIdPattern('REDOEN-RELA-xxx')
  @ContentHelp(
    'Add one entry per relationship to another referenced document, '
    'naming the related document and the kind of link.',
  )
  @SerializationOrder(1)
  List<RelatedDocumentEntry> relatedDocuments = [];
}

/// A relationship to another reference document.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — front matter (referenced documents)'],
  'A single relationship to another referenced document: the related document '
  'and the nature of the link.',
)
@SectionId('REDOEN')
class RelatedDocumentEntry extends DocSpecsSection {
  @Form([
    Field(
      'relatedDocumentId',
      String,
      'Related Document ID',
      required: true,
      hint: 'The related reference document — a reference document section id '
          '(RFDOC-DOCU-…)',
      refersTo: ['RFDOC.@sectionId'],
    ),
    Field(
      'relationshipType',
      String,
      'Relationship Type (Depends On, Referenced By, Supersedes, '
          'Complements, Conflicts With, Parent Of, Child Of)',
      hint: 'Nature of the link, e.g. Depends On, Supersedes, Complements.',
    ),
    Field(
      'relationshipDescription',
      String,
      'Relationship Description (explain the connection)',
      hint: 'Explain the connection between the two documents.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
