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
@Document(
  name: 'Security & Access Specification',
  description: 'Complete access and authorization specification — user '
      'management, authentication, resource protection, authorization, '
      'encryption, audit, role matrix, and compliance framework.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('SAS')
class D08SecurityAccessSpecification {
  @ContentHelp('Executive overview of the access and authorization concept.')
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

  /// Audit and logging.
  @SerializationOrder(7)
  AuditAndLogging auditAndLogging = AuditAndLogging();

  /// Role matrix.
  @SerializationOrder(8)
  RoleMatrix roleMatrix = RoleMatrix();

  /// Compliance framework.
  @SerializationOrder(9)
  ComplianceFramework complianceFramework = ComplianceFramework();
}
