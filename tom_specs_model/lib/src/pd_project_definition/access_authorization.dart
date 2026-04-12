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

  /// 9.1.2. User Lifecycle [PD00-ACC-USE-LIF].
  UserLifecycleSection userLifecycle = UserLifecycleSection();

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

/// 9.1.2. User Lifecycle [PD00-ACC-USE-LIF].
///
/// Defines the complete user account lifecycle: states, transitions between
/// states, approval requirements for each transition, and operational policies
/// for registration, activation, modification, deactivation, and deletion.
@SectionId('PD00-ACC-USE-LIF')
class UserLifecycleSection {
  @Unused()
  String? content;

  /// Overview (text).
  TextSection overview = TextSection();

  /// 9.1.2.1. Account States.
  UserAccountStatesDefinition accountStates = UserAccountStatesDefinition();

  /// 9.1.2.2. Registration Process.
  UserRegistrationProcess registration = UserRegistrationProcess();

  /// 9.1.2.3. Account Activation.
  AccountActivationPolicy activation = AccountActivationPolicy();

  /// 9.1.2.4. Account Modification.
  AccountModificationPolicy modification = AccountModificationPolicy();

  /// 9.1.2.5. Account Deactivation.
  AccountDeactivationPolicy deactivation = AccountDeactivationPolicy();

  /// 9.1.2.6. Account Deletion and Data Retention.
  AccountDeletionPolicy deletion = AccountDeletionPolicy();

  /// 9.1.2.7. Lifecycle Transitions and Approvals.
  UserLifecycleTransitions transitions = UserLifecycleTransitions();

  /// 9.1.2.8. Self-Service Account Management.
  SelfServiceAccountManagement selfService = SelfServiceAccountManagement();

  /// 9.1.2.9. Service Account Lifecycle.
  ServiceAccountLifecycle serviceAccounts = ServiceAccountLifecycle();
}

/// 9.1.2.1. Account States (form).
///
/// Defines the possible states a user account can be in throughout its
/// lifecycle, from provisional creation to permanent deletion.
@Form([
  Field('stateModel', String, 'State Model Type',
      hint:
          'Linear | Graph | Hierarchical — how states relate to each other'),
  Field('initialState', String, 'Initial State',
      hint: 'State assigned at account creation (e.g., Pending Verification)'),
  Field('activeState', String, 'Active State',
      hint: 'Fully operational account state name'),
  Field('suspendedState', String, 'Suspended State',
      hint: 'Temporarily restricted state name'),
  Field('lockedState', String, 'Locked State',
      hint: 'Account locked due to security policy (e.g., failed logins)'),
  Field('deactivatedState', String, 'Deactivated State',
      hint: 'Administratively disabled, recoverable'),
  Field('archivedState', String, 'Archived State',
      hint: 'Read-only historical state before permanent deletion'),
  Field('deletedState', String, 'Deleted State',
      hint: 'Permanently removed or anonymized'),
  Field('customStates', String, 'Custom States',
      hint:
          'Additional project-specific states (comma-separated)'),
  Field('stateVisibility', String, 'State Visibility',
      hint: 'Which states are visible to the user vs. admin-only'),
  Field('stateTransitionDiagramRef', String, 'State Transition Diagram Reference',
      hint: 'Reference to a state transition diagram (mermaid or external)'),
])
class UserAccountStatesDefinition {
  String? content;

  /// State Transition Diagram (mermaid).
  DiagramSection stateTransitionDiagram = DiagramSection();
}

/// 9.1.2.2. Registration Process (form).
///
/// Defines how new user accounts are created — self-registration, invitation,
/// admin-provisioned, or bulk import — including identity proofing requirements.
@Form([
  Field('registrationMethods', String, 'Registration Methods',
      hint:
          'SelfRegistration | Invitation | AdminProvisioned | BulkImport | ExternalIdP'),
  Field('selfRegistrationEnabled', String, 'Self-Registration Enabled',
      hint: 'Yes | No | PerCategory — whether users can self-register'),
  Field('identityProofingLevel', String, 'Identity Proofing Level',
      hint:
          'None | Email | Phone | Document | InPerson — per NIST SP 800-63A IAL'),
  Field('emailVerificationRequired', String, 'Email Verification Required',
      hint: 'Yes | No | Optional'),
  Field('phoneVerificationRequired', String, 'Phone Verification Required',
      hint: 'Yes | No | Optional'),
  Field('captchaRequired', String, 'CAPTCHA Required',
      hint: 'Yes | No — bot prevention during self-registration'),
  Field('invitationExpiryPeriod', String, 'Invitation Expiry Period',
      hint: 'Duration before invitation link expires (e.g., 48h, 7d)'),
  Field('approvalRequired', String, 'Approval Required',
      hint: 'Yes | No — whether registration needs manual approval'),
  Field('approvalWorkflow', String, 'Approval Workflow',
      hint:
          'Single Approver | Multi-Level | Auto-Approved — workflow type'),
  Field('approverRole', String, 'Approver Role',
      hint: 'Role or person who approves new registrations'),
  Field('requiredFieldsAtRegistration', String,
      'Required Fields at Registration',
      hint: 'Comma-separated list of mandatory fields during signup'),
  Field('optionalFieldsAtRegistration', String,
      'Optional Fields at Registration',
      hint: 'Comma-separated list of optional fields during signup'),
  Field('termsAcceptanceRequired', String, 'Terms Acceptance Required',
      hint: 'Yes | No — must accept terms of service / privacy policy'),
  Field('duplicateDetection', String, 'Duplicate Detection',
      hint:
          'How duplicate accounts are detected (email, phone, name matching)'),
  Field('welcomeNotification', String, 'Welcome Notification',
      hint: 'Email | SMS | InApp | None — notification on successful registration'),
  Field('initialRoleAssignment', String, 'Initial Role Assignment',
      hint:
          'Default role(s) assigned at registration'),
  Field('registrationRateLimiting', String, 'Registration Rate Limiting',
      hint:
          'Max registrations per IP/time window to prevent abuse'),
])
class UserRegistrationProcess {
  String? content;

  /// Registration Flow Description (text).
  TextSection registrationFlowDescription = TextSection();

  /// Registration Flow Diagram (mermaid-sequence).
  SequenceDiagramSection registrationFlowDiagram = SequenceDiagramSection();
}

/// 9.1.2.3. Account Activation (form).
///
/// Defines the steps required to move a newly registered account from pending
/// to active status, including verification, approval, and provisioning.
@Form([
  Field('activationMethod', String, 'Activation Method',
      hint:
          'EmailLink | AdminApproval | Automatic | PhoneVerification | Combined'),
  Field('activationLinkExpiry', String, 'Activation Link Expiry',
      hint: 'Duration before activation link expires (e.g., 24h)'),
  Field('maxActivationAttempts', int, 'Max Activation Attempts',
      hint: 'Number of times user can request re-activation'),
  Field('activationPrerequisites', String, 'Activation Prerequisites',
      hint:
          'Conditions that must be met before activation (e.g., email verified, approved)'),
  Field('provisioningOnActivation', String, 'Provisioning on Activation',
      hint:
          'Resources provisioned when account becomes active (workspace, storage, etc.)'),
  Field('activationNotification', String, 'Activation Notification',
      hint: 'Channels notified on activation (email, SMS, admin alert)'),
  Field('activationTimeout', String, 'Activation Timeout',
      hint:
          'Time after which unactivated accounts are purged or flagged'),
  Field('activationTimeoutAction', String, 'Activation Timeout Action',
      hint: 'Delete | Flag | Remind | Escalate — action on timeout'),
  Field('postActivationRedirect', String, 'Post-Activation Redirect',
      hint:
          'Where the user is directed after activation (dashboard, onboarding wizard)'),
  Field('onboardingRequired', String, 'Onboarding Required',
      hint: 'Yes | No — whether guided onboarding follows activation'),
  Field('onboardingSteps', String, 'Onboarding Steps',
      hint:
          'Steps in onboarding flow (profile completion, tutorial, preference setup)'),
])
class AccountActivationPolicy {
  String? content;

  /// Activation Flow Description (text).
  TextSection activationFlowDescription = TextSection();
}

/// 9.1.2.4. Account Modification (form).
///
/// Defines what user account attributes can be changed, by whom, under what
/// conditions, and what re-verification is needed after changes.
@Form([
  Field('selfModifiableFields', String, 'Self-Modifiable Fields',
      hint:
          'Fields the user can change themselves (display name, avatar, preferences)'),
  Field('adminModifiableFields', String, 'Admin-Modifiable Fields',
      hint:
          'Fields only an administrator can change (role, status, organization)'),
  Field('systemModifiableFields', String, 'System-Modifiable Fields',
      hint:
          'Fields updated automatically (last login, login count, risk score)'),
  Field('emailChangePolicy', String, 'Email Change Policy',
      hint:
          'Re-verification required | Admin approval | Confirmation to old+new email'),
  Field('phoneChangePolicy', String, 'Phone Change Policy',
      hint: 'Verification via old number | Admin approval'),
  Field('nameChangePolicy', String, 'Name Change Policy',
      hint: 'Self-service | RequiresVerification | AdminOnly'),
  Field('roleChangeApproval', String, 'Role Change Approval',
      hint:
          'Who approves role changes (manager, admin, auto-approved for certain changes)'),
  Field('bulkModificationSupport', String, 'Bulk Modification Support',
      hint: 'Yes | No — whether batch attribute updates are supported'),
  Field('changeAuditLogging', String, 'Change Audit Logging',
      hint: 'All changes | SensitiveOnly | None — audit trail granularity'),
  Field('changeNotification', String, 'Change Notification',
      hint:
          'User | Admin | Both | None — who receives notification of changes'),
  Field('historicalVersioning', String, 'Historical Versioning',
      hint:
          'Yes | No — whether previous attribute values are preserved'),
  Field('reverificationTriggers', String, 'Re-verification Triggers',
      hint:
          'Which changes trigger re-verification (email, password, security question)'),
  Field('modificationRateLimiting', String, 'Modification Rate Limiting',
      hint:
          'Limits on how frequently attributes can be changed (e.g., email max 1/30d)'),
  Field('modificationCooldownPeriod', String, 'Modification Cooldown Period',
      hint: 'Waiting period after sensitive changes before full access resumes'),
])
class AccountModificationPolicy {
  String? content;

  /// Modification Rules Description (text).
  TextSection modificationRulesDescription = TextSection();
}

/// 9.1.2.5. Account Deactivation (form).
///
/// Defines temporary or permanent disabling of user accounts — reasons, effects,
/// reactivation conditions, and the difference between suspension and deactivation.
@Form([
  Field('deactivationTriggers', String, 'Deactivation Triggers',
      hint:
          'Manual | Inactivity | PolicyViolation | ContractEnd | SecurityIncident'),
  Field('inactivityThreshold', String, 'Inactivity Threshold',
      hint:
          'Period of inactivity before automatic deactivation (e.g., 90d, 180d)'),
  Field('inactivityWarningPeriod', String, 'Inactivity Warning Period',
      hint:
          'Advance notice before deactivation (e.g., warn 14d before deactivation)'),
  Field('deactivationApproval', String, 'Deactivation Approval',
      hint: 'Who can deactivate accounts (admin, manager, system, self)'),
  Field('immediateDeactivationCases', String, 'Immediate Deactivation Cases',
      hint:
          'Cases where deactivation is immediate without warning (security breach, termination)'),
  Field('deactivatedAccountAccess', String, 'Deactivated Account Data Access',
      hint: 'Whether deactivated account data remains accessible to admins'),
  Field('deactivationEffects', String, 'Deactivation Effects',
      hint:
          'LoginBlocked | ApiKeysRevoked | SessionsTerminated | DataPreserved'),
  Field('reactivationPolicy', String, 'Reactivation Policy',
      hint:
          'UserRequest | AdminOnly | AutoOnLogin | NotAllowed — how accounts are reactivated'),
  Field('reactivationApproval', String, 'Reactivation Approval',
      hint: 'Who approves reactivation (original approver, admin, manager)'),
  Field('reactivationReverification', String, 'Reactivation Re-verification',
      hint:
          'PasswordReset | MFA | IdentityProofing — verification at reactivation'),
  Field('maxDeactivationPeriod', String, 'Max Deactivation Period',
      hint:
          'Maximum time an account can stay deactivated before escalation to deletion'),
  Field('deactivationNotification', String, 'Deactivation Notification',
      hint:
          'User | Admin | Manager | All — channels notified on deactivation'),
  Field('gracePeriodAfterDeactivation', String,
      'Grace Period After Deactivation',
      hint:
          'Window during which deactivation is easily reversible'),
  Field('dataPreservationDuration', String, 'Data Preservation Duration',
      hint:
          'How long deactivated account data is preserved (30d, 1y, indefinitely)'),
])
class AccountDeactivationPolicy {
  String? content;

  /// Deactivation Process Description (text).
  TextSection deactivationProcessDescription = TextSection();
}

/// 9.1.2.6. Account Deletion and Data Retention (form).
///
/// Defines permanent account removal, data anonymization, data retention
/// obligations, and right-to-be-forgotten compliance.
@Form([
  Field('deletionTriggers', String, 'Deletion Triggers',
      hint:
          'UserRequest | RetentionExpiry | AdminDecision | RegulatoryOrder'),
  Field('deletionApproval', String, 'Deletion Approval',
      hint:
          'Who approves deletion (admin, data protection officer, auto-approved)'),
  Field('softDeleteEnabled', String, 'Soft Delete Enabled',
      hint: 'Yes | No — whether accounts are soft-deleted before hard deletion'),
  Field('softDeleteRetention', String, 'Soft Delete Retention Period',
      hint:
          'Duration in soft-deleted state before permanent removal (e.g., 30d, 90d)'),
  Field('permanentDeletionProcess', String, 'Permanent Deletion Process',
      hint:
          'Anonymize | Purge | Archive — what happens to data on permanent deletion'),
  Field('dataAnonymizationStrategy', String, 'Data Anonymization Strategy',
      hint:
          'Fields anonymized, pseudonymization method, referential integrity handling'),
  Field('retainedDataAfterDeletion', String, 'Retained Data After Deletion',
      hint:
          'Data kept for legal/audit reasons (transaction logs, audit trails)'),
  Field('retentionPeriodAfterDeletion', String,
      'Retention Period After Deletion',
      hint: 'How long retained data is kept post-deletion'),
  Field('dataExportBeforeDeletion', String, 'Data Export Before Deletion',
      hint: 'Yes | No — whether users can export their data before deletion'),
  Field('exportFormats', String, 'Export Formats',
      hint: 'JSON | CSV | XML | PDF — formats for data export'),
  Field('cascadeDeletionBehavior', String, 'Cascade Deletion Behavior',
      hint:
          'What happens to associated content (posts, files, records) on user deletion'),
  Field('deletionConfirmation', String, 'Deletion Confirmation',
      hint:
          'PasswordEntry | EmailConfirmation | WaitingPeriod — confirmation method'),
  Field('deletionNotification', String, 'Deletion Notification',
      hint: 'User | Admin | DPO | All — who is notified on deletion'),
  Field('rightToErasureCompliance', String, 'Right to Erasure Compliance',
      hint: 'GDPR Art.17 | CCPA | None — applicable right-to-be-forgotten regulations'),
  Field('erasureResponseTime', String, 'Erasure Response Time',
      hint: 'Maximum time to fulfill an erasure request (e.g., 30 days per GDPR)'),
  Field('thirdPartyDataDeletion', String, 'Third-Party Data Deletion',
      hint:
          'How data shared with third parties is removed or anonymized'),
])
class AccountDeletionPolicy {
  String? content;

  /// Deletion Process Description (text).
  TextSection deletionProcessDescription = TextSection();
}

/// 9.1.2.7. Lifecycle Transitions and Approvals (form).
///
/// Defines the permissible transitions between lifecycle states, who can trigger
/// each transition, and the approval workflow required.
@Form([
  Field('transitionModel', String, 'Transition Model',
      hint:
          'StateMachine | Workflow | Hybrid — how transitions are modeled'),
  Field('approvalPolicyDefault', String, 'Default Approval Policy',
      hint: 'SingleApprover | DualControl | AutoApproved — default for all transitions'),
  Field('escalationPolicy', String, 'Escalation Policy',
      hint:
          'What happens if approval is not granted within SLA (auto-deny, escalate, remind)'),
  Field('escalationTimeframe', String, 'Escalation Timeframe',
      hint: 'Time before pending approval is escalated (e.g., 48h)'),
  Field('auditTrailRequired', String, 'Audit Trail Required',
      hint: 'Yes | No — whether every transition is logged'),
  Field('notificationOnTransition', String, 'Notification on Transition',
      hint: 'User | Approver | Admin | All — who is notified on state change'),
  Field('bulkTransitionSupport', String, 'Bulk Transition Support',
      hint: 'Yes | No — whether multiple accounts can transition at once'),
  Field('automatedTransitions', String, 'Automated Transitions',
      hint:
          'Transitions triggered automatically (inactivity → deactivated, expiry → deleted)'),
  Field('transitionUndoPolicy', String, 'Transition Undo Policy',
      hint:
          'Which transitions are reversible and within what time window'),
])
class UserLifecycleTransitions {
  String? content;

  /// Transition Rules Description (text).
  TextSection transitionRulesDescription = TextSection();

  /// Lifecycle State Transition Diagram (mermaid).
  DiagramSection lifecycleStateDiagram = DiagramSection();

  /// Contains 0+× UserLifecycleTransitionEntry.
  @SectionIdPattern('PD00-ACC-USE-LIF-xx')
  List<UserLifecycleTransitionEntry> items = [];
}

/// A lifecycle transition entry (form) [PD00-ACC-USE-LIF-nn].
///
/// Defines a single permissible transition between two lifecycle states,
/// including trigger, approval, and side effects.
class UserLifecycleTransitionEntry {
  @Form([
    Field('transitionName', String, 'Transition Name',
        required: true,
        hint: 'Descriptive name (e.g., "Activate Account", "Suspend User")'),
    Field('fromState', String, 'From State',
        required: true, hint: 'Source lifecycle state'),
    Field('toState', String, 'To State',
        required: true, hint: 'Target lifecycle state'),
    Field('trigger', String, 'Trigger',
        hint: 'UserRequest | AdminAction | SystemEvent | ScheduledJob'),
    Field('triggerConditions', String, 'Trigger Conditions',
        hint:
            'Pre-conditions that must be met for this transition'),
    Field('approvalRequired', String, 'Approval Required',
        hint: 'Yes | No — whether manual approval is needed'),
    Field('approverRole', String, 'Approver Role',
        hint: 'Role that must approve (admin, manager, DPO)'),
    Field('approvalSla', String, 'Approval SLA',
        hint: 'Maximum time allowed for approval decision'),
    Field('sideEffects', String, 'Side Effects',
        hint:
            'Actions performed on transition (revoke tokens, send email, deprovision)'),
    Field('notificationRecipients', String, 'Notification Recipients',
        hint: 'Who is notified (user, admin, manager)'),
    Field('notificationChannels', String, 'Notification Channels',
        hint: 'Email | SMS | InApp | Webhook'),
    Field('reversible', String, 'Reversible',
        hint: 'Yes | No — whether this transition can be undone'),
    Field('reverseTransitionName', String, 'Reverse Transition Name',
        hint: 'Name of the reverse transition if applicable'),
    Field('automationSupported', String, 'Automation Supported',
        hint: 'Yes | No — whether this transition can be automated'),
  ])
  String? content;
}

/// 9.1.2.8. Self-Service Account Management (form).
///
/// Defines what lifecycle actions users can perform on their own accounts
/// without administrator involvement.
@Form([
  Field('profileUpdateEnabled', String, 'Profile Update Enabled',
      hint: 'Yes | No — users can update their own profile information'),
  Field('passwordChangeEnabled', String, 'Password Change Enabled',
      hint: 'Yes | No — users can change their own password'),
  Field('passwordResetEnabled', String, 'Password Reset Enabled',
      hint: 'Yes | No — users can reset forgotten passwords'),
  Field('passwordResetMethods', String, 'Password Reset Methods',
      hint: 'Email | SMS | SecurityQuestions | AdminAssisted'),
  Field('mfaEnrollmentSelfService', String, 'MFA Enrollment Self-Service',
      hint: 'Yes | No — users can enroll/change MFA devices'),
  Field('accountDeactivationSelfService', String,
      'Account Deactivation Self-Service',
      hint: 'Yes | No — users can deactivate their own account'),
  Field('accountDeletionSelfService', String,
      'Account Deletion Self-Service',
      hint: 'Yes | No — users can request deletion of their own account'),
  Field('dataExportSelfService', String, 'Data Export Self-Service',
      hint: 'Yes | No — users can export their own data'),
  Field('sessionManagementSelfService', String,
      'Session Management Self-Service',
      hint: 'Yes | No — users can view and terminate their active sessions'),
  Field('apiKeyManagementSelfService', String,
      'API Key Management Self-Service',
      hint: 'Yes | No — users can create/revoke their own API keys'),
  Field('notificationPreferences', String, 'Notification Preferences',
      hint: 'Yes | No — users can configure their notification preferences'),
  Field('delegationEnabled', String, 'Delegation Enabled',
      hint:
          'Yes | No — users can delegate account actions to another user'),
  Field('delegationScope', String, 'Delegation Scope',
      hint: 'What actions can be delegated (read, write, approve)'),
  Field('accountRecoveryProcess', String, 'Account Recovery Process',
      hint:
          'Steps when a user loses all credentials (identity re-proofing, admin reset)'),
])
class SelfServiceAccountManagement {
  String? content;

  /// Self-Service Capabilities Description (text).
  TextSection selfServiceDescription = TextSection();
}

/// 9.1.2.9. Service Account Lifecycle (form).
///
/// Defines lifecycle management for non-human accounts — APIs, bots, system
/// integrations — which have different lifecycle rules than human users.
@Form([
  Field('serviceAccountTypes', String, 'Service Account Types',
      hint:
          'API Client | Bot | SystemIntegration | ScheduledJob | DeviceIdentity'),
  Field('creationProcess', String, 'Creation Process',
      hint: 'How service accounts are created (admin, DevOps pipeline, self-service)'),
  Field('creationApproval', String, 'Creation Approval',
      hint: 'Who approves service account creation (security team, admin)'),
  Field('ownerAssignment', String, 'Owner Assignment',
      hint: 'Yes | No — whether each service account must have a human owner'),
  Field('ownerReviewFrequency', String, 'Owner Review Frequency',
      hint: 'How often owners must recertify service accounts (quarterly, annually)'),
  Field('credentialRotationPolicy', String, 'Credential Rotation Policy',
      hint:
          'How often credentials (keys, secrets, certificates) must be rotated'),
  Field('credentialStorageMethod', String, 'Credential Storage Method',
      hint: 'VaultService | EnvironmentVariable | SecretManager | HSM'),
  Field('scopeLimitation', String, 'Scope Limitation',
      hint:
          'Principle of least privilege — minimum permissions for service accounts'),
  Field('ipRestriction', String, 'IP Restriction',
      hint: 'Yes | No — whether service accounts are restricted to specific IPs'),
  Field('expirationPolicy', String, 'Expiration Policy',
      hint:
          'Whether service accounts expire and after how long (e.g., 1y, never)'),
  Field('renewalProcess', String, 'Renewal Process',
      hint: 'Steps to renew an expiring service account'),
  Field('decommissioningProcess', String, 'Decommissioning Process',
      hint:
          'How service accounts are retired (revoke, archive, delete)'),
  Field('monitoringRequirements', String, 'Monitoring Requirements',
      hint:
          'Anomaly detection, usage thresholds, alerting for service accounts'),
  Field('serviceAccountNamingConvention', String, 'Naming Convention',
      hint:
          'Naming pattern for service accounts (e.g., svc-{app}-{environment})'),
  Field('documentationRequirements', String, 'Documentation Requirements',
      hint: 'What must be documented for each service account (purpose, owner, scope)'),
])
class ServiceAccountLifecycle {
  String? content;

  /// Service Account Management Description (text).
  TextSection serviceAccountDescription = TextSection();
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
