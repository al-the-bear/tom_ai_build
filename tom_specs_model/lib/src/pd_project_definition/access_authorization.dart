/// Section 9: Access and Authorization Concept [PD00-ACC]. Seeds → AC.
///
/// Application security for data and functions.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 9. Access and Authorization Concept [PD00-ACC]. Seeds → AC.
@tomReflector
class AccessAndAuthorizationConcept {
  final String? content;

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
    this.content,
    this.userManagement = const UserManagement(),
    this.authentication = const IdentificationAndAuthentication(),
    this.resourceProtection = const ResourceProtection(),
    this.authorization = const UserAuthorization(),
    this.encryption = const SensitiveDataEncryption(),
    this.auditAndLogging = const AuditAndLogging(),
  });
}

/// 9.1. User Management [PD00-ACC-USE].
@tomReflector
class UserManagement {
  final String? content;

  /// 9.1.1. User Categories [PD00-ACC-USE-CAT].
  final UserCategories userCategories;

  /// 9.1.2. User Lifecycle [PD00-ACC-USE-LIF].
  final String? userLifecycle;

  /// 9.1.3. User Attributes [PD00-ACC-USE-ATT].
  final UserAttributes userAttributes;

  const UserManagement({
    this.content,
    this.userCategories = const UserCategories(),
    this.userLifecycle,
    this.userAttributes = const UserAttributes(),
  });
}

/// 9.1.1. User Categories [PD00-ACC-USE-CAT].
@tomReflector
class UserCategories {
  final String? content;
  final List<UserCategoryDefinition> items;

  const UserCategories({this.content, this.items = const []});
}

/// A user category definition (form).
@tomReflector
class UserCategoryDefinition {
  final String? content;
  final String? categoryName;
  final String? description;
  final String? accessLevel;
  final String? estimatedCount;

  const UserCategoryDefinition({
    this.content,
    this.categoryName,
    this.description,
    this.accessLevel,
    this.estimatedCount,
  });
}

/// 9.1.3. User Attributes [PD00-ACC-USE-ATT].
@tomReflector
class UserAttributes {
  final String? content;
  final List<UserAttributeEntry> items;

  const UserAttributes({this.content, this.items = const []});
}

/// A user attribute entry (form).
@tomReflector
class UserAttributeEntry {
  final String? content;
  final String? attributeName;
  final String? dataType;
  final String? source;
  final String? required;

  const UserAttributeEntry({
    this.content,
    this.attributeName,
    this.dataType,
    this.source,
    this.required,
  });
}

/// 9.2. Identification and Authentication [PD00-ACC-IDE].
@tomReflector
class IdentificationAndAuthentication {
  final String? content;

  /// 9.2.1. Authentication Methods [PD00-ACC-IDE-MET].
  final AuthenticationMethods authenticationMethods;

  /// 9.2.2. Authentication Flow [PD00-ACC-IDE-FLO].
  final String? authenticationFlow;

  /// 9.2.3. Password and Credential Policy [PD00-ACC-IDE-POL].
  final String? passwordPolicy;

  /// 9.2.4. Session Management [PD00-ACC-IDE-SES].
  final String? sessionManagement;

  const IdentificationAndAuthentication({
    this.content,
    this.authenticationMethods = const AuthenticationMethods(),
    this.authenticationFlow,
    this.passwordPolicy,
    this.sessionManagement,
  });
}

/// 9.2.1. Authentication Methods [PD00-ACC-IDE-MET].
@tomReflector
class AuthenticationMethods {
  final String? content;
  final List<AuthenticationMethodEntry> items;

  const AuthenticationMethods({this.content, this.items = const []});
}

/// An authentication method entry (form).
@tomReflector
class AuthenticationMethodEntry {
  final String? content;
  final String? methodName;
  final String? methodType;
  final String? applicableUserCategories;
  final String? securityLevel;
  final String? description;

  const AuthenticationMethodEntry({
    this.content,
    this.methodName,
    this.methodType,
    this.applicableUserCategories,
    this.securityLevel,
    this.description,
  });
}

/// 9.3. Resource Protection [PD00-ACC-RES].
@tomReflector
class ResourceProtection {
  final String? content;

  /// 9.3.1. Data-Level Security [PD00-ACC-RES-DAT].
  final String? dataLevelSecurity;

  /// 9.3.2. API Security [PD00-ACC-RES-API].
  final String? apiSecurity;

  /// 9.3.3. File and Storage Security [PD00-ACC-RES-FIL].
  final String? fileAndStorageSecurity;

  const ResourceProtection({
    this.content,
    this.dataLevelSecurity,
    this.apiSecurity,
    this.fileAndStorageSecurity,
  });
}

/// 9.4. User Authorization [PD00-ACC-USA].
///
/// Aligns with Tom Core authorization model: groups → roles → entitlements → resourceKeys.
@tomReflector
class UserAuthorization {
  final String? content;

  /// 9.4.1. Authorization Model [PD00-ACC-USA-MOD].
  final String? authorizationModel;

  /// 9.4.2. Authorization Groups [PD00-ACC-USA-GRP] — contains 0+× Group.
  final List<AuthorizationGroupEntry> groups;

  /// 9.4.3. Role Definitions [PD00-ACC-USA-ROL] — contains 1+× Role.
  final List<AuthorizationRoleEntry> roleDefinitions;

  /// 9.4.4. Entitlements [PD00-ACC-USA-ENT] — contains 1+× Entitlement.
  final List<EntitlementEntry> entitlements;

  /// 9.4.5. Resource Keys [PD00-ACC-USA-RES] — contains 0+× Resource Key.
  final List<ResourceKeyEntry> resourceKeys;

  /// 9.4.6. Role Hierarchy [PD00-ACC-USA-ROH].
  final String? roleHierarchy;

  /// 9.4.7. Tenant Isolation [PD00-ACC-USA-TEN].
  final String? tenantIsolation;

  const UserAuthorization({
    this.content,
    this.authorizationModel,
    this.groups = const [],
    this.roleDefinitions = const [],
    this.entitlements = const [],
    this.resourceKeys = const [],
    this.roleHierarchy,
    this.tenantIsolation,
  });
}

/// An authorization group entry [PD00-ACC-USA-GRP-nn] (form).
@tomReflector
class AuthorizationGroupEntry {
  final String? content;
  final String? groupName;
  final String? description;
  final List<String> containedRoles;
  final String? membershipCriteria;

  const AuthorizationGroupEntry({
    this.content,
    this.groupName,
    this.description,
    this.containedRoles = const [],
    this.membershipCriteria,
  });
}

/// An authorization role entry [PD00-ACC-USA-ROL-nn] (form).
@tomReflector
class AuthorizationRoleEntry {
  final String? content;
  final String? roleName;
  final String? description;
  final List<String> responsibilities;
  final List<String> entitlementReferences;
  final String? inheritsFrom;
  final List<String> mutualExclusions;
  final List<String> typicalHolders;

  const AuthorizationRoleEntry({
    this.content,
    this.roleName,
    this.description,
    this.responsibilities = const [],
    this.entitlementReferences = const [],
    this.inheritsFrom,
    this.mutualExclusions = const [],
    this.typicalHolders = const [],
  });
}

/// An entitlement entry [PD00-ACC-USA-ENT-nn] (form).
@tomReflector
class EntitlementEntry {
  final String? content;
  final String? entitlementName;
  final String? description;
  final List<String> resourceKeyReferences;
  final String? accessType;
  final String? conditions;

  const EntitlementEntry({
    this.content,
    this.entitlementName,
    this.description,
    this.resourceKeyReferences = const [],
    this.accessType,
    this.conditions,
  });
}

/// A resource key entry [PD00-ACC-USA-RES-nn] (form).
@tomReflector
class ResourceKeyEntry {
  final String? content;
  final String? resourceKey;
  final String? resourceType;
  final String? description;
  final String? protectionLevel;

  const ResourceKeyEntry({
    this.content,
    this.resourceKey,
    this.resourceType,
    this.description,
    this.protectionLevel,
  });
}

/// 9.5. Sensitive Data Encryption [PD00-ACC-SEN].
@tomReflector
class SensitiveDataEncryption {
  final String? content;

  /// 9.5.1. Encryption at Rest [PD00-ACC-SEN-RES].
  final String? encryptionAtRest;

  /// 9.5.2. Encryption in Transit [PD00-ACC-SEN-TRA].
  final String? encryptionInTransit;

  /// 9.5.3. Key Management [PD00-ACC-SEN-KEY].
  final String? keyManagement;

  const SensitiveDataEncryption({
    this.content,
    this.encryptionAtRest,
    this.encryptionInTransit,
    this.keyManagement,
  });
}

/// 9.6. Audit and Logging [PD00-ACC-AUD].
@tomReflector
class AuditAndLogging {
  final String? content;

  /// 9.6.1. Security Events [PD00-ACC-AUD-EVE].
  final SecurityEvents securityEvents;

  /// 9.6.2. Audit Log Format [PD00-ACC-AUD-FMT].
  final String? auditLogFormat;

  /// 9.6.3. Compliance Reporting [PD00-ACC-AUD-COM].
  final String? complianceReporting;

  const AuditAndLogging({
    this.content,
    this.securityEvents = const SecurityEvents(),
    this.auditLogFormat,
    this.complianceReporting,
  });
}

/// 9.6.1. Security Events [PD00-ACC-AUD-EVE].
@tomReflector
class SecurityEvents {
  final String? content;
  final List<SecurityEventEntry> items;

  const SecurityEvents({this.content, this.items = const []});
}

/// A security event entry (form).
@tomReflector
class SecurityEventEntry {
  final String? content;
  final String? eventName;
  final String? eventType;
  final String? description;
  final String? severity;
  final String? responseAction;

  const SecurityEventEntry({
    this.content,
    this.eventName,
    this.eventType,
    this.description,
    this.severity,
    this.responseAction,
  });
}
