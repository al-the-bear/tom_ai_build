/// AC — Authorization Concept.
///
/// Phase 3 DocSpec root class. Aggregates 8 top-level sections from
/// PD00-ACC (single seed, flattened) per §5.6 of
/// second_wave_documents.md.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// AC00 Authorization Concept.
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
  basedOn: [SolutionBlueprint],
)
@SectionId('SAS')
class SecurityAccessSpecification {
  @ContentHelp('Executive overview of the access and authorization concept.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// User management — PD00-ACC-USE.
  UserManagement userManagement = UserManagement();

  /// Identification and authentication — PD00-ACC-IDE.
  IdentificationAndAuthentication identificationAndAuthentication =
      IdentificationAndAuthentication();

  /// Resource protection — PD00-ACC-RES.
  ResourceProtection resourceProtection = ResourceProtection();

  /// User authorization — PD00-ACC-USA.
  UserAuthorization userAuthorization = UserAuthorization();

  /// Sensitive data encryption — PD00-ACC-SEN.
  SensitiveDataEncryption sensitiveDataEncryption = SensitiveDataEncryption();

  /// Audit and logging — PD00-ACC-AUD.
  AuditAndLogging auditAndLogging = AuditAndLogging();

  /// Role matrix — PD00-ACC-ROL (covers HBSG AS22-AUM).
  RoleMatrix roleMatrix = RoleMatrix();

  /// Compliance framework — PD00-ACC-CMP.
  ComplianceFramework complianceFramework = ComplianceFramework();
}
