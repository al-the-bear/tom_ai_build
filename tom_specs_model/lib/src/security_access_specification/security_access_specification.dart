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
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// User management.
  UserManagement userManagement = UserManagement();

  /// Identification and authentication.
  IdentificationAndAuthentication identificationAndAuthentication =
      IdentificationAndAuthentication();

  /// Resource protection.
  ResourceProtection resourceProtection = ResourceProtection();

  /// User authorization.
  UserAuthorization userAuthorization = UserAuthorization();

  /// Sensitive data encryption.
  SensitiveDataEncryption sensitiveDataEncryption = SensitiveDataEncryption();

  /// Audit and logging.
  AuditAndLogging auditAndLogging = AuditAndLogging();

  /// Role matrix.
  RoleMatrix roleMatrix = RoleMatrix();

  /// Compliance framework.
  ComplianceFramework complianceFramework = ComplianceFramework();
}
