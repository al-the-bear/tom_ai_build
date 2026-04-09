/// Section 9: Access and Authorization Concept [PD00-ACC]. Seeds → AC.
///
/// Application security for data and functions.
library;



/// 9. Access and Authorization Concept [PD00-ACC]. Seeds → AC.
class AccessAndAuthorizationConcept {
  String? content;

  /// 9.1. User Management [PD00-ACC-USE].
  UserManagement userManagement = UserManagement();

  /// 9.2. Identification and Authentication [PD00-ACC-IDE].
  IdentificationAndAuthentication authentication = IdentificationAndAuthentication();

  /// 9.3. Resource Protection [PD00-ACC-RES].
  ResourceProtection resourceProtection = ResourceProtection();

  /// 9.4. User Authorization [PD00-ACC-USA].
  UserAuthorization authorization = UserAuthorization();

  /// 9.5. Sensitive Data Encryption [PD00-ACC-SEN].
  SensitiveDataEncryption encryption = SensitiveDataEncryption();

  /// 9.6. Audit and Logging [PD00-ACC-AUD].
  AuditAndLogging auditAndLogging = AuditAndLogging();
}

/// 9.1. User Management [PD00-ACC-USE].
class UserManagement {
  String? content;

  /// 9.1.1. User Categories [PD00-ACC-USE-CAT].
  UserCategories userCategories = UserCategories();

  /// 9.1.2. User Lifecycle [PD00-ACC-USE-LIF].
  String? userLifecycle;

  /// 9.1.3. User Attributes [PD00-ACC-USE-ATT].
  UserAttributes userAttributes = UserAttributes();
}

/// 9.1.1. User Categories [PD00-ACC-USE-CAT].
class UserCategories {
  String? content;
  List<UserCategoryDefinition> items = [];
}

/// A user category definition (form).
class UserCategoryDefinition {
  String? content;
  String? categoryName;
  String? description;
  String? accessLevel;
  String? estimatedCount;
}

/// 9.1.3. User Attributes [PD00-ACC-USE-ATT].
class UserAttributes {
  String? content;
  List<UserAttributeEntry> items = [];
}

/// A user attribute entry (form).
class UserAttributeEntry {
  String? content;
  String? attributeName;
  String? dataType;
  String? source;
  String? required;
}

/// 9.2. Identification and Authentication [PD00-ACC-IDE].
class IdentificationAndAuthentication {
  String? content;

  /// 9.2.1. Authentication Methods [PD00-ACC-IDE-MET].
  AuthenticationMethods authenticationMethods = AuthenticationMethods();

  /// 9.2.2. Authentication Flow [PD00-ACC-IDE-FLO].
  String? authenticationFlow;

  /// 9.2.3. Password and Credential Policy [PD00-ACC-IDE-POL].
  String? passwordPolicy;

  /// 9.2.4. Session Management [PD00-ACC-IDE-SES].
  String? sessionManagement;
}

/// 9.2.1. Authentication Methods [PD00-ACC-IDE-MET].
class AuthenticationMethods {
  String? content;
  List<AuthenticationMethodEntry> items = [];
}

/// An authentication method entry (form).
class AuthenticationMethodEntry {
  String? content;
  String? methodName;
  String? methodType;
  String? applicableUserCategories;
  String? securityLevel;
  String? description;
}

/// 9.3. Resource Protection [PD00-ACC-RES].
class ResourceProtection {
  String? content;

  /// 9.3.1. Data-Level Security [PD00-ACC-RES-DAT].
  String? dataLevelSecurity;

  /// 9.3.2. API Security [PD00-ACC-RES-API].
  String? apiSecurity;

  /// 9.3.3. File and Storage Security [PD00-ACC-RES-FIL].
  String? fileAndStorageSecurity;
}

/// 9.4. User Authorization [PD00-ACC-USA].
///
/// Aligns with Tom Core authorization model: groups → roles → entitlements → resourceKeys.
class UserAuthorization {
  String? content;

  /// 9.4.1. Authorization Model [PD00-ACC-USA-MOD].
  String? authorizationModel;

  /// 9.4.2. Authorization Groups [PD00-ACC-USA-GRP] — contains 0+× Group.
  List<AuthorizationGroupEntry> groups = [];

  /// 9.4.3. Role Definitions [PD00-ACC-USA-ROL] — contains 1+× Role.
  List<AuthorizationRoleEntry> roleDefinitions = [];

  /// 9.4.4. Entitlements [PD00-ACC-USA-ENT] — contains 1+× Entitlement.
  List<EntitlementEntry> entitlements = [];

  /// 9.4.5. Resource Keys [PD00-ACC-USA-RES] — contains 0+× Resource Key.
  List<ResourceKeyEntry> resourceKeys = [];

  /// 9.4.6. Role Hierarchy [PD00-ACC-USA-ROH].
  String? roleHierarchy;

  /// 9.4.7. Tenant Isolation [PD00-ACC-USA-TEN].
  String? tenantIsolation;
}

/// An authorization group entry [PD00-ACC-USA-GRP-nn] (form).
class AuthorizationGroupEntry {
  String? content;
  String? groupName;
  String? description;
  List<RoleReferenceEntry> containedRoles = [];
  String? membershipCriteria;
}

/// A role reference entry (form).
class RoleReferenceEntry {
  String? content;
  String? roleName;
}

/// An authorization role entry [PD00-ACC-USA-ROL-nn] (form).
class AuthorizationRoleEntry {
  String? content;
  String? roleName;
  String? description;
  List<ResponsibilityReferenceEntry> responsibilities = [];
  List<EntitlementReferenceEntry> entitlementReferences = [];
  String? inheritsFrom;
  List<RoleExclusionEntry> mutualExclusions = [];
  List<RoleHolderEntry> typicalHolders = [];
}

/// A responsibility reference entry (form).
class ResponsibilityReferenceEntry {
  String? content;
  String? responsibility;
  String? description;
}

/// An entitlement reference entry (form).
class EntitlementReferenceEntry {
  String? content;
  String? entitlementName;
}

/// A role exclusion entry (form).
class RoleExclusionEntry {
  String? content;
  String? excludedRole;
  String? reason;
}

/// A role holder entry (form).
class RoleHolderEntry {
  String? content;
  String? holderDescription;
  String? department;
}

/// An entitlement entry [PD00-ACC-USA-ENT-nn] (form).
class EntitlementEntry {
  String? content;
  String? entitlementName;
  String? description;
  List<ResourceKeyReferenceEntry> resourceKeyReferences = [];
  String? accessType;
  String? conditions;
}

/// A resource key reference entry (form).
class ResourceKeyReferenceEntry {
  String? content;
  String? resourceKey;
}

/// A resource key entry [PD00-ACC-USA-RES-nn] (form).
class ResourceKeyEntry {
  String? content;
  String? resourceKey;
  String? resourceType;
  String? description;
  String? protectionLevel;
}

/// 9.5. Sensitive Data Encryption [PD00-ACC-SEN].
class SensitiveDataEncryption {
  String? content;

  /// 9.5.1. Encryption at Rest [PD00-ACC-SEN-RES].
  String? encryptionAtRest;

  /// 9.5.2. Encryption in Transit [PD00-ACC-SEN-TRA].
  String? encryptionInTransit;

  /// 9.5.3. Key Management [PD00-ACC-SEN-KEY].
  String? keyManagement;
}

/// 9.6. Audit and Logging [PD00-ACC-AUD].
class AuditAndLogging {
  String? content;

  /// 9.6.1. Security Events [PD00-ACC-AUD-EVE].
  SecurityEvents securityEvents = SecurityEvents();

  /// 9.6.2. Audit Log Format [PD00-ACC-AUD-FMT].
  String? auditLogFormat;

  /// 9.6.3. Compliance Reporting [PD00-ACC-AUD-COM].
  String? complianceReporting;
}

/// 9.6.1. Security Events [PD00-ACC-AUD-EVE].
class SecurityEvents {
  String? content;
  List<SecurityEventEntry> items = [];
}

/// A security event entry (form).
class SecurityEventEntry {
  String? content;
  String? eventName;
  String? eventType;
  String? description;
  String? severity;
  String? responseAction;
}
