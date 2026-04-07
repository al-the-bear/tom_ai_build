/// Section 9: Access and Authorization Concept [PD00-ACC]. Seeds → AC.
///
/// Application security for data and functions.
class AccessAndAuthorizationConcept {
  /// 9.1. User Management [PD00-ACC-USE].
  final UserManagement userManagement;

  /// 9.2. Identification and Authentication [PD00-ACC-IDE].
  final IdentificationAndAuthentication authentication;

  /// 9.3. Resource Protection [PD00-ACC-RES].
  final ResourceProtection resourceProtection;

  /// 9.4. User Authorization [PD00-ACC-USA].
  final UserAuthorization authorization;

  /// 9.5. Sensitive Data Encryption [PD00-ACC-SEN].
  final SensitiveDataEncryption encryption;

  /// 9.6. Audit and Logging [PD00-ACC-AUD].
  final AuditAndLogging auditAndLogging;

  const AccessAndAuthorizationConcept({
    this.userManagement = const UserManagement(),
    this.authentication = const IdentificationAndAuthentication(),
    this.resourceProtection = const ResourceProtection(),
    this.authorization = const UserAuthorization(),
    this.encryption = const SensitiveDataEncryption(),
    this.auditAndLogging = const AuditAndLogging(),
  });
}

/// 9.1. User Management [PD00-ACC-USE].
class UserManagement {
  /// 9.1.1. User Categories [PD00-ACC-USE-CAT].
  final String? userCategories;

  /// 9.1.2. User Lifecycle [PD00-ACC-USE-LIF].
  final String? userLifecycle;

  /// 9.1.3. User Attributes [PD00-ACC-USE-ATT].
  final String? userAttributes;

  const UserManagement({
    this.userCategories,
    this.userLifecycle,
    this.userAttributes,
  });
}

/// 9.2. Identification and Authentication [PD00-ACC-IDE].
class IdentificationAndAuthentication {
  /// 9.2.1. Authentication Methods [PD00-ACC-IDE-MET].
  final String? authenticationMethods;

  /// 9.2.2. Authentication Flow [PD00-ACC-IDE-FLO].
  final String? authenticationFlow;

  /// 9.2.3. Password and Credential Policy [PD00-ACC-IDE-POL].
  final String? passwordPolicy;

  /// 9.2.4. Session Management [PD00-ACC-IDE-SES].
  final String? sessionManagement;

  const IdentificationAndAuthentication({
    this.authenticationMethods,
    this.authenticationFlow,
    this.passwordPolicy,
    this.sessionManagement,
  });
}

/// 9.3. Resource Protection [PD00-ACC-RES].
class ResourceProtection {
  /// 9.3.1. Data-Level Security [PD00-ACC-RES-DAT].
  final String? dataLevelSecurity;

  /// 9.3.2. API Security [PD00-ACC-RES-API].
  final String? apiSecurity;

  /// 9.3.3. File and Storage Security [PD00-ACC-RES-FIL].
  final String? fileAndStorageSecurity;

  const ResourceProtection({
    this.dataLevelSecurity,
    this.apiSecurity,
    this.fileAndStorageSecurity,
  });
}

/// 9.4. User Authorization [PD00-ACC-USA].
class UserAuthorization {
  /// 9.4.1. Authorization Model [PD00-ACC-USA-MOD].
  final String? authorizationModel;

  /// 9.4.2. Role Definitions [PD00-ACC-USA-ROL] — contains 1+× AuthorizationRole.
  final List<AuthorizationRole> roleDefinitions;

  /// 9.4.3. Role Hierarchy [PD00-ACC-USA-ROH].
  final String? roleHierarchy;

  /// 9.4.4. Tenant Isolation [PD00-ACC-USA-TEN].
  final String? tenantIsolation;

  const UserAuthorization({
    this.authorizationModel,
    this.roleDefinitions = const [],
    this.roleHierarchy,
    this.tenantIsolation,
  });
}

/// An authorization role [PD00-ACC-USA-ROL-nn].
class AuthorizationRole {
  final String roleName;
  final String description;
  final String responsibilities;
  final String permissionSet;
  final String? inheritsFrom;
  final String? mutualExclusions;
  final String? typicalHolders;

  const AuthorizationRole({
    required this.roleName,
    required this.description,
    required this.responsibilities,
    required this.permissionSet,
    this.inheritsFrom,
    this.mutualExclusions,
    this.typicalHolders,
  });
}

/// 9.5. Sensitive Data Encryption [PD00-ACC-SEN].
class SensitiveDataEncryption {
  /// 9.5.1. Encryption at Rest [PD00-ACC-SEN-RES].
  final String? encryptionAtRest;

  /// 9.5.2. Encryption in Transit [PD00-ACC-SEN-TRA].
  final String? encryptionInTransit;

  /// 9.5.3. Key Management [PD00-ACC-SEN-KEY].
  final String? keyManagement;

  const SensitiveDataEncryption({
    this.encryptionAtRest,
    this.encryptionInTransit,
    this.keyManagement,
  });
}

/// 9.6. Audit and Logging [PD00-ACC-AUD].
class AuditAndLogging {
  /// 9.6.1. Security Events [PD00-ACC-AUD-EVE].
  final String? securityEvents;

  /// 9.6.2. Audit Log Format [PD00-ACC-AUD-FMT].
  final String? auditLogFormat;

  /// 9.6.3. Compliance Reporting [PD00-ACC-AUD-COM].
  final String? complianceReporting;

  const AuditAndLogging({
    this.securityEvents,
    this.auditLogFormat,
    this.complianceReporting,
  });
}
