/// D08 — Security & Access Specification.
///
/// Phase 3 DocSpec root class. Aggregates 8 top-level sections projected
/// (flattened) from the Solution Blueprint security-and-access sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../common/review_team.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// SAS00 Security & Access Specification.
///
/// Complete access and authorization specification — user management,
/// identification and authentication, resource protection, user
/// authorization, encryption, audit/logging, role matrix, and
/// compliance framework.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — information security management',
    'NIST RBAC (INCITS 359) — role-based access control',
  ],
  'The complete access and authorization specification covering user management, authentication, resource protection, authorization, encryption, audit, and compliance.',
)
@Document(
  name: 'Security & Access Specification',
  description:
      'Complete access and authorization specification — user '
      'management, authentication, resource protection, authorization, '
      'encryption, audit, role matrix, and compliance framework.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('SAS')
class D08SecurityAccessSpecification extends DocSpecsSection {
  @ContentHelp('Executive overview of the access and authorization concept.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// This document's own review team; when it has members it replaces the
  /// Solution Blueprint's team for this document type and its default team.
  @SerializationOrder(2)
  ReviewTeam reviewTeam = ReviewTeam();

  /// Chronological revision history of this document, with the reviewers of
  /// each revision.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 §6 — front matter (revision history)',
  ], 'The ordered set of published revisions of this document.')
  @SectionId('RVENT-REVS-LST')
  @SectionIdPattern('RVENT-REVS-xxx')
  @ContentHelp(
    'Add one entry per revision, newest last: version, date, author, a short '
    'summary, the review team the round started with and the reviewers who '
    'returned a copy.',
  )
  @SerializationOrder(3)
  List<RevisionEntry> revisionHistory = [];

  /// User management.
  @SerializationOrder(4)
  UserManagement userManagement = UserManagement();

  /// Identification and authentication.
  @SerializationOrder(5)
  IdentificationAndAuthentication identificationAndAuthentication =
      IdentificationAndAuthentication();

  /// Resource protection.
  @SerializationOrder(6)
  ResourceProtection resourceProtection = ResourceProtection();

  /// User authorization.
  @SerializationOrder(7)
  UserAuthorization userAuthorization = UserAuthorization();

  /// Sensitive data encryption.
  @SerializationOrder(8)
  SensitiveDataEncryption sensitiveDataEncryption = SensitiveDataEncryption();

  /// Audit and logging — the CE-LG / CE-CF declarations.
  @SerializationOrder(9)
  AuditAndLogging auditAndLogging = AuditAndLogging();

  /// Role matrix.
  @SerializationOrder(10)
  RoleMatrix roleMatrix = RoleMatrix();

  /// Compliance framework.
  @SerializationOrder(11)
  ComplianceFramework complianceFramework = ComplianceFramework();

  /// Compliance reporting — the review / reporting routines run against the
  /// audit log.
  ///
  /// Projected directly rather than through `AuditAndLogging`: the audit
  /// section was split so its CodeSpecs bands can be a generation-projection
  /// root, which put this follow-up subtree under `SecurityOperationsFollowUp`
  /// (`codespecs_mapping.md` §8.3). SAS still owns the content, so D08 reaches
  /// it here.
  @SerializationOrder(12)
  ComplianceReporting complianceReporting = ComplianceReporting();
}
