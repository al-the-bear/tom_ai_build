/// D08 — Security & Access Specification.
///
/// Phase 3 DocSpec root class. Aggregates 8 top-level sections projected
/// (flattened) from the Solution Blueprint security-and-access sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
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
  description: 'Complete access and authorization specification — user '
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

  /// User management.
  @SerializationOrder(2)
  UserManagement userManagement = UserManagement();

  /// Identification and authentication.
  @SerializationOrder(3)
  IdentificationAndAuthentication identificationAndAuthentication =
      IdentificationAndAuthentication();

  /// Resource protection.
  @SerializationOrder(4)
  ResourceProtection resourceProtection = ResourceProtection();

  /// User authorization.
  @SerializationOrder(5)
  UserAuthorization userAuthorization = UserAuthorization();

  /// Sensitive data encryption.
  @SerializationOrder(6)
  SensitiveDataEncryption sensitiveDataEncryption = SensitiveDataEncryption();

  /// Audit and logging — the CE-LG / CE-CF declarations.
  @SerializationOrder(7)
  AuditAndLogging auditAndLogging = AuditAndLogging();

  /// Role matrix.
  @SerializationOrder(8)
  RoleMatrix roleMatrix = RoleMatrix();

  /// Compliance framework.
  @SerializationOrder(9)
  ComplianceFramework complianceFramework = ComplianceFramework();

  /// Compliance reporting — the review / reporting routines run against the
  /// audit log.
  ///
  /// Projected directly rather than through `AuditAndLogging`: the audit
  /// section was split so its CodeSpecs bands can be a generation-projection
  /// root, which put this follow-up subtree under `SecurityOperationsFollowUp`
  /// (`codespecs_mapping.md` §8.3). SAS still owns the content, so D08 reaches
  /// it here.
  @SerializationOrder(10)
  ComplianceReporting complianceReporting = ComplianceReporting();
}
