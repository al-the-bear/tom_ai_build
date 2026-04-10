/// Section 9: Access and Authorization Concept [PD00-ACC]. Seeds → AC.
///
/// Application security for data and functions.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 9. Access and Authorization Concept [PD00-ACC]. Seeds → AC.
@SectionId('PD00-ACC')
@Comment('Seeds → AC')
class AccessAndAuthorizationConcept {
  @Unused()
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
@SectionId('PD00-ACC-USE')
class UserManagement {
  @Unused()
  String? content;

  /// 9.1.1. User Categories [PD00-ACC-USE-CAT].
  UserCategories userCategories = UserCategories();

  /// User Lifecycle.
  TextSection userLifecycle = TextSection();

  /// 9.1.3. User Attributes [PD00-ACC-USE-ATT].
  UserAttributes userAttributes = UserAttributes();
}

/// 9.1.1. User Categories [PD00-ACC-USE-CAT].
@SectionId('PD00-ACC-USE-CAT')
class UserCategories {
  @Unused()
  String? content;

  /// Contains 0+× UserCategoryDefinition.
  @SectionIdPattern('PD00-ACC-USE-CAT-xx')
  List<UserCategoryDefinition> items = [];
}

/// A user category definition (form) [PD00-ACC-USE-CAT-nn].
class UserCategoryDefinition {
  @Form([
    Field('categoryName', String, 'Category Name', required: true),
    Field('description', String, 'Short description'),
    Field('accessLevel', String, 'Access Level'),
    Field('estimatedCount', String, 'Estimated Count'),
  ])
  String? content;
}

/// 9.1.3. User Attributes [PD00-ACC-USE-ATT].
@SectionId('PD00-ACC-USE-ATT')
class UserAttributes {
  @Unused()
  String? content;

  /// Contains 0+× UserAttribute.
  @SectionIdPattern('PD00-ACC-USE-ATT-xx')
  List<UserAttributeEntry> items = [];
}

/// A user attribute entry (form) [PD00-ACC-USE-ATT-nn].
class UserAttributeEntry {
  @Form([
    Field('attributeName', String, 'Attribute Name', required: true),
    Field('dataType', String, 'Data Type'),
    Field('source', String, 'Source'),
    Field('required', String, 'Required'),
  ])
  String? content;
}

/// 9.2. Identification and Authentication [PD00-ACC-IDE].
@SectionId('PD00-ACC-IDE')
class IdentificationAndAuthentication {
  @Unused()
  String? content;

  /// 9.2.1. Identification [PD00-ACC-IDE-IDN].
  Identification identification = Identification();

  /// 9.2.2. Authentication [PD00-ACC-IDE-AUT].
  Authentication authentication = Authentication();
}

/// 9.2.1. Identification [PD00-ACC-IDE-IDN].
@SectionId('PD00-ACC-IDE-IDN')
class Identification {
  @Unused()
  String? content;

  /// Identity Sources.
  TextSection identitySources = TextSection();

  /// Identity Verification.
  TextSection identityVerification = TextSection();

  /// Identity Providers.
  TextSection identityProviders = TextSection();

  /// Single Sign On.
  TextSection singleSignOn = TextSection();
}

/// 9.2.2. Authentication [PD00-ACC-IDE-AUT].
@SectionId('PD00-ACC-IDE-AUT')
class Authentication {
  @Unused()
  String? content;

  /// 9.2.2.1. Authentication Methods [PD00-ACC-IDE-AUT-MET].
  AuthenticationMethods authenticationMethods = AuthenticationMethods();

  /// Authentication Flow.
  TextSection authenticationFlow = TextSection();

  /// Password Policy.
  TextSection passwordPolicy = TextSection();

  /// Session Management.
  TextSection sessionManagement = TextSection();
}

/// 9.2.2.1. Authentication Methods [PD00-ACC-IDE-AUT-MET].
@SectionId('PD00-ACC-IDE-AUT-MET')
class AuthenticationMethods {
  @Unused()
  String? content;

  /// Contains 0+× AuthenticationMethod.
  @SectionIdPattern('PD00-ACC-IDE-AUT-MET-xx')
  List<AuthenticationMethodEntry> items = [];
}

/// An authentication method entry (form) [PD00-ACC-IDE-AUT-MET-nn].
class AuthenticationMethodEntry {
  @Form([
    Field('methodName', String, 'Method Name', required: true),
    Field('methodType', String, 'Method Type'),
    Field('applicableUserCategories', String, 'Applicable User Categories'),
    Field('securityLevel', String, 'Security Level'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// 9.3. Resource Protection [PD00-ACC-RES].
@SectionId('PD00-ACC-RES')
class ResourceProtection {
  @Unused()
  String? content;

  /// Data Level Security.
  TextSection dataLevelSecurity = TextSection();

  /// Api Security.
  TextSection apiSecurity = TextSection();

  /// File And Storage Security.
  TextSection fileAndStorageSecurity = TextSection();
}

/// 9.4. User Authorization [PD00-ACC-USA].
///
/// Aligns with Tom Core authorization model: groups → roles → entitlements → resourceKeys.
@SectionId('PD00-ACC-USA')
class UserAuthorization {
  @Unused()
  String? content;

  /// Authorization Model.
  TextSection authorizationModel = TextSection();

  /// 9.4.2. Authorization Groups [PD00-ACC-USA-GRP] — contains 0+× Group.
  @SectionIdPattern('PD00-ACC-USA-GRP-xx')
  List<AuthorizationGroupEntry> groups = [];

  /// 9.4.3. Role Definitions [PD00-ACC-USA-ROL] — contains 1+× Role.
  @SectionIdPattern('PD00-ACC-USA-ROL-xx')
  @Min(1)
  List<AuthorizationRoleEntry> roleDefinitions = [];

  /// 9.4.4. Entitlements [PD00-ACC-USA-ENT] — contains 1+× Entitlement.
  @SectionIdPattern('PD00-ACC-USA-ENT-xx')
  @Min(1)
  List<EntitlementEntry> entitlements = [];

  /// 9.4.5. Resource Keys [PD00-ACC-USA-RES] — contains 0+× Resource Key.
  @SectionIdPattern('PD00-ACC-USA-RES-xx')
  List<ResourceKeyEntry> resourceKeys = [];

  /// Role Hierarchy.
  TextSection roleHierarchy = TextSection();

  /// Tenant Isolation.
  TextSection tenantIsolation = TextSection();
}

/// An authorization group entry [PD00-ACC-USA-GRP-nn] (form).
class AuthorizationGroupEntry {
  @Form([
    Field('groupName', String, 'Group Name', required: true),
    Field('description', String, 'Short description'),
    Field('membershipCriteria', String, 'Membership Criteria'),
  ])
  String? content;

  /// Contains 0+× RoleReference.
  @SectionIdPattern('PD00-ACC-USA-GRP-xx-ROL-xx')
  List<RoleReferenceEntry> containedRoles = [];
}

/// A role reference entry (form) [PD00-ACC-USA-GRP-nn-ROL-nn].
class RoleReferenceEntry {
  @Form([
    Field('roleName', String, 'Role Name', required: true),
  ])
  String? content;
}

/// An authorization role entry [PD00-ACC-USA-ROL-nn] (form).
class AuthorizationRoleEntry {
  @Form([
    Field('roleName', String, 'Role Name', required: true),
    Field('description', String, 'Short description'),
    Field('inheritsFrom', String, 'Inherits From'),
  ])
  String? content;

  /// Contains 0+× ResponsibilityReference.
  @SectionIdPattern('PD00-ACC-USA-ROL-xx-RSP-xx')
  List<ResponsibilityReferenceEntry> responsibilities = [];

  /// Contains 0+× EntitlementReference.
  @SectionIdPattern('PD00-ACC-USA-ROL-xx-ENT-xx')
  List<EntitlementReferenceEntry> entitlementReferences = [];

  /// Contains 0+× RoleExclusion.
  @SectionIdPattern('PD00-ACC-USA-ROL-xx-EXC-xx')
  List<RoleExclusionEntry> mutualExclusions = [];

  /// Contains 0+× RoleHolder.
  @SectionIdPattern('PD00-ACC-USA-ROL-xx-HOL-xx')
  List<RoleHolderEntry> typicalHolders = [];
}

/// A responsibility reference entry (form) [PD00-ACC-USA-ROL-nn-RSP-nn].
class ResponsibilityReferenceEntry {
  @Form([
    Field('responsibility', String, 'Responsibility'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// An entitlement reference entry (form) [PD00-ACC-USA-ROL-nn-ENT-nn].
class EntitlementReferenceEntry {
  @Form([
    Field('entitlementName', String, 'Entitlement Name', required: true),
  ])
  String? content;
}

/// A role exclusion entry (form) [PD00-ACC-USA-ROL-nn-EXC-nn].
class RoleExclusionEntry {
  @Form([
    Field('excludedRole', String, 'Excluded Role'),
    Field('reason', String, 'Reason'),
  ])
  String? content;
}

/// A role holder entry (form) [PD00-ACC-USA-ROL-nn-HOL-nn].
class RoleHolderEntry {
  @Form([
    Field('holderDescription', String, 'Holder Description'),
    Field('department', String, 'Department'),
  ])
  String? content;
}

/// An entitlement entry [PD00-ACC-USA-ENT-nn] (form).
class EntitlementEntry {
  @Form([
    Field('entitlementName', String, 'Entitlement Name', required: true),
    Field('description', String, 'Short description'),
    Field('accessType', String, 'Access Type'),
    Field('conditions', String, 'Conditions'),
  ])
  String? content;

  /// Contains 0+× ResourceKeyReference.
  @SectionIdPattern('PD00-ACC-USA-ENT-xx-RKR-xx')
  List<ResourceKeyReferenceEntry> resourceKeyReferences = [];
}

/// A resource key reference entry (form) [PD00-ACC-USA-ENT-nn-RKR-nn].
class ResourceKeyReferenceEntry {
  @Form([
    Field('resourceKey', String, 'Resource Key', required: true),
  ])
  String? content;
}

/// A resource key entry [PD00-ACC-USA-RES-nn] (form).
class ResourceKeyEntry {
  @Form([
    Field('resourceKey', String, 'Resource Key', required: true),
    Field('resourceType', String, 'Resource Type'),
    Field('description', String, 'Short description'),
    Field('protectionLevel', String, 'Protection Level'),
  ])
  String? content;
}

/// 9.5. Sensitive Data Encryption [PD00-ACC-SEN].
@SectionId('PD00-ACC-SEN')
class SensitiveDataEncryption {
  @Unused()
  String? content;

  /// Encryption At Rest.
  TextSection encryptionAtRest = TextSection();

  /// Encryption In Transit.
  TextSection encryptionInTransit = TextSection();

  /// Key Management.
  TextSection keyManagement = TextSection();
}

/// 9.6. Audit and Logging [PD00-ACC-AUD].
@SectionId('PD00-ACC-AUD')
class AuditAndLogging {
  @Unused()
  String? content;

  /// 9.6.1. Audit [PD00-ACC-AUD-AUD].
  Audit audit = Audit();

  /// 9.6.2. Logging [PD00-ACC-AUD-LOG].
  Logging logging = Logging();
}

/// 9.6.1. Audit [PD00-ACC-AUD-AUD].
@SectionId('PD00-ACC-AUD-AUD')
class Audit {
  @Unused()
  String? content;

  /// Audit Trail.
  TextSection auditTrail = TextSection();

  /// Compliance Reporting.
  TextSection complianceReporting = TextSection();

  /// Retention Policy.
  TextSection retentionPolicy = TextSection();
}

/// 9.6.2. Logging [PD00-ACC-AUD-LOG].
@SectionId('PD00-ACC-AUD-LOG')
class Logging {
  @Unused()
  String? content;

  /// Log Format.
  TextSection logFormat = TextSection();

  /// Log Levels.
  TextSection logLevels = TextSection();

  /// 9.6.2.3. Security Events [PD00-ACC-AUD-LOG-EVE].
  SecurityEvents securityEvents = SecurityEvents();
}

/// 9.6.2.3. Security Events [PD00-ACC-AUD-LOG-EVE].
@SectionId('PD00-ACC-AUD-LOG-EVE')
class SecurityEvents {
  @Unused()
  String? content;

  /// Contains 0+× SecurityEvent.
  @SectionIdPattern('PD00-ACC-AUD-LOG-EVE-xx')
  List<SecurityEventEntry> items = [];
}

/// A security event entry (form) [PD00-ACC-AUD-LOG-EVE-nn].
class SecurityEventEntry {
  @Form([
    Field('eventName', String, 'Event Name', required: true),
    Field('eventType', String, 'Event Type'),
    Field('description', String, 'Short description'),
    Field('severity', String, 'Severity level'),
    Field('responseAction', String, 'Response Action'),
  ])
  String? content;
}
