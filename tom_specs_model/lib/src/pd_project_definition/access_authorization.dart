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

  /// 9.2.2.2. Authentication Flow [PD00-ACC-IDE-FLO].
  AuthenticationFlow authenticationFlow = AuthenticationFlow();

  /// 9.2.3. Password and Credential Policy [PD00-ACC-IDE-POL].
  PasswordAndCredentialPolicy passwordAndCredentialPolicy =
      PasswordAndCredentialPolicy();

  /// 9.2.4. Session Management [PD00-ACC-IDE-SES].
  SessionManagement sessionManagement = SessionManagement();
}

/// 9.2.2.1. Authentication Methods [PD00-ACC-IDE-AUT-MET].
///
/// Comprehensive authentication methods specification aligned with
/// NIST SP 800-63B Authentication Assurance Levels (AAL1–AAL3).
/// Covers all authenticator types: passwords, MFA, SSO, certificates,
/// biometrics, API keys, and cryptographic authenticators.
@SectionId('PD00-ACC-IDE-AUT-MET')
class AuthenticationMethods {
  @Unused()
  String? content;

  /// Authentication Methods Overview (text).
  TextSection overview = TextSection();

  /// Multi-Factor Authentication Configuration.
  MfaConfiguration mfaConfiguration = MfaConfiguration();

  /// Single Sign-On Policy.
  SsoPolicy ssoPolicy = SsoPolicy();

  /// Certificate-Based Authentication Policy.
  CertificateAuthenticationPolicy certificateAuthentication =
      CertificateAuthenticationPolicy();

  /// Biometric Authentication Policy.
  BiometricAuthenticationPolicy biometricAuthentication =
      BiometricAuthenticationPolicy();

  /// API Key Management Policy.
  ApiKeyManagementPolicy apiKeyManagement = ApiKeyManagementPolicy();

  /// Contains 0+× AuthenticationMethod.
  @SectionIdPattern('PD00-ACC-IDE-AUT-MET-xx')
  List<AuthenticationMethodEntry> items = [];
}

/// Multi-Factor Authentication (MFA) configuration (form).
///
/// Defines MFA requirements aligned with NIST SP 800-63B AAL2/AAL3:
/// proof of possession and control of two distinct authentication factors.
@Form([
  Field('mfaRequired', String, 'MFA Required',
      hint: 'Yes | No | Conditional — whether MFA is mandatory'),
  Field('mfaEnforcementScope', String, 'MFA Enforcement Scope',
      hint:
          'AllUsers | AdminOnly | PrivilegedRoles | ExternalAccess | Conditional'),
  Field('defaultSecondFactor', String, 'Default Second Factor',
      hint: 'TOTP | Push | FIDO2 | SMS | Email | HardwareToken'),
  Field('allowedSecondFactors', String, 'Allowed Second Factors',
      hint:
          'Comma-separated list of permitted second-factor types'),
  Field('assuranceLevelTarget', String, 'Assurance Level Target',
      hint: 'AAL1 | AAL2 | AAL3 — target NIST authentication assurance level'),
  Field('phishingResistanceRequired', String, 'Phishing Resistance Required',
      hint:
          'Yes | No — whether phishing-resistant authenticators are required (AAL3)'),
  Field('stepUpAuthenticationEnabled', String,
      'Step-Up Authentication Enabled',
      hint:
          'Yes | No — whether sensitive operations trigger higher AAL re-authentication'),
  Field('stepUpTriggers', String, 'Step-Up Triggers',
      hint:
          'Operations that trigger step-up (payment, admin actions, data export)'),
  Field('rememberDevicePolicy', String, 'Remember Device Policy',
      hint:
          'Duration a device is remembered before MFA re-prompt (e.g., 30d, never)'),
  Field('recoveryCodePolicy', String, 'Recovery Code Policy',
      hint:
          'How many one-time recovery codes are issued and their validity'),
  Field('enrollmentGracePeriod', String, 'Enrollment Grace Period',
      hint:
          'Time allowed for users to enroll MFA after it becomes required (e.g., 14d)'),
  Field('mfaBypassPolicy', String, 'MFA Bypass Policy',
      hint: 'Conditions under which MFA can be bypassed (break-glass, service accounts)'),
])
class MfaConfiguration {
  String? content;

  /// MFA Implementation Details (text).
  TextSection mfaDetails = TextSection();
}

/// Single Sign-On (SSO) policy (form).
///
/// Defines federation and SSO configuration for centralized authentication
/// across multiple applications via identity providers.
@Form([
  Field('ssoEnabled', String, 'SSO Enabled',
      hint: 'Yes | No — whether SSO is implemented'),
  Field('ssoProtocol', String, 'SSO Protocol',
      hint: 'SAML2.0 | OIDC | OAuth2 | WS-Federation | Kerberos'),
  Field('identityProviderType', String, 'Identity Provider Type',
      hint:
          'Internal | External | Hybrid — where the IdP is hosted'),
  Field('identityProviderProduct', String, 'Identity Provider Product',
      hint:
          'Specific IdP product or service (e.g., Keycloak, Azure AD, Okta, Auth0)'),
  Field('federationProtocol', String, 'Federation Protocol',
      hint:
          'Protocol for cross-organization federation (SAML, OIDC, SCIM)'),
  Field('attributeMapping', String, 'Attribute Mapping',
      hint:
          'How IdP attributes map to application roles and permissions'),
  Field('justInTimeProvisioning', String, 'Just-In-Time Provisioning',
      hint:
          'Yes | No — whether accounts are auto-created on first SSO login'),
  Field('sessionSynchronization', String, 'Session Synchronization',
      hint:
          'Yes | No — whether logout from one app logs out all SSO-connected apps'),
  Field('singleLogoutEnabled', String, 'Single Logout Enabled',
      hint:
          'Yes | No — whether SLO (Single Logout) is implemented across services'),
  Field('ssoFallbackMethod', String, 'SSO Fallback Method',
      hint:
          'Local password | Backup IdP | None — fallback when IdP is unavailable'),
  Field('ssoScopePolicy', String, 'SSO Scope Policy',
      hint:
          'Which applications are included in SSO (all, internal only, selected)'),
  Field('externalIdpTrustPolicy', String, 'External IdP Trust Policy',
      hint:
          'Validation requirements for external identity providers'),
])
class SsoPolicy {
  String? content;

  /// SSO Implementation Details (text).
  TextSection ssoDetails = TextSection();
}

/// Certificate-based authentication policy (form).
///
/// Defines requirements for X.509 certificate authentication including
/// mTLS, PIV/CAC cards, and client certificate authentication.
@Form([
  Field('certificateAuthEnabled', String, 'Certificate Auth Enabled',
      hint: 'Yes | No — whether certificate-based authentication is supported'),
  Field('certificateTypes', String, 'Certificate Types',
      hint: 'X.509 | PIV | CAC | SmartCard — types of certificates accepted'),
  Field('certificateIssuance', String, 'Certificate Issuance',
      hint:
          'InternalCA | ExternalCA | SelfSigned — who issues the certificates'),
  Field('certificateAuthority', String, 'Certificate Authority',
      hint: 'CA product or service used for certificate issuance'),
  Field('keyStorageRequirement', String, 'Key Storage Requirement',
      hint:
          'TPM | HSM | SmartCard | SoftwareKeystore — where private keys must be stored'),
  Field('mutualTlsRequired', String, 'Mutual TLS Required',
      hint:
          'Yes | No — whether mTLS (client certificate) is required for API access'),
  Field('certificateValidation', String, 'Certificate Validation',
      hint:
          'OCSP | CRL | OCSP-Stapling — certificate revocation checking method'),
  Field('certificateLifetime', String, 'Certificate Lifetime',
      hint: 'Maximum validity period for certificates (e.g., 1y, 2y)'),
  Field('renewalProcess', String, 'Renewal Process',
      hint: 'Automatic | Manual | AdminApproval — certificate renewal method'),
  Field('revocationProcess', String, 'Revocation Process',
      hint: 'How compromised certificates are revoked and propagated'),
  Field('minimumKeyStrength', String, 'Minimum Key Strength',
      hint: 'RSA-2048 | RSA-4096 | EC-P256 | EC-P384 — minimum key requirements'),
  Field('fipsComplianceRequired', String, 'FIPS Compliance Required',
      hint: 'Yes | No — whether FIPS 140-2/3 validated modules are required'),
])
class CertificateAuthenticationPolicy {
  String? content;

  /// Certificate Authentication Details (text).
  TextSection certificateDetails = TextSection();
}

/// Biometric authentication policy (form).
///
/// Defines requirements for biometric authentication factors aligned with
/// NIST SP 800-63B Section 3.2.3: biometrics as activation factor for
/// multi-factor authenticators, not standalone authentication.
@Form([
  Field('biometricAuthEnabled', String, 'Biometric Auth Enabled',
      hint: 'Yes | No — whether biometric authentication is supported'),
  Field('biometricModalities', String, 'Biometric Modalities',
      hint:
          'Fingerprint | FacialRecognition | IrisScan | VoicePrint — supported modalities'),
  Field('biometricUsageContext', String, 'Biometric Usage Context',
      hint:
          'DeviceUnlock | TransactionApproval | MfaActivation — when biometrics are used'),
  Field('biometricAsActivationFactor', String,
      'Biometric As Activation Factor',
      hint:
          'Yes | No — whether biometric is used as MFA activation factor per NIST guidance'),
  Field('localVsCentralComparison', String, 'Local vs Central Comparison',
      hint:
          'Local | Central — where biometric comparison is performed (local preferred)'),
  Field('falseMatchRateTarget', String, 'False Match Rate Target',
      hint: 'Target FMR (e.g., 1:10000 per NIST SP 800-63B)'),
  Field('presentationAttackDetection', String,
      'Presentation Attack Detection',
      hint:
          'Yes | No — whether PAD is implemented (required for facial recognition)'),
  Field('maxConsecutiveFailures', String, 'Max Consecutive Failures',
      hint:
          'Maximum failed biometric attempts before fallback (e.g., 5 without PAD, 10 with PAD)'),
  Field('fallbackMethod', String, 'Fallback Method',
      hint:
          'PIN | Password | AlternateModality — fallback when biometric fails'),
  Field('biometricDataStorage', String, 'Biometric Data Storage',
      hint:
          'DeviceOnly | EncryptedCentral | Never — where biometric templates are stored'),
  Field('privacyConsiderations', String, 'Privacy Considerations',
      hint:
          'Consent requirements, data retention policy, right to withdraw'),
  Field('accessibilityAlternative', String, 'Accessibility Alternative',
      hint:
          'Alternative authentication for users unable to use biometric modalities'),
])
class BiometricAuthenticationPolicy {
  String? content;

  /// Biometric Implementation Details (text).
  TextSection biometricDetails = TextSection();
}

/// API key management policy (form).
///
/// Defines lifecycle management for API keys, service tokens, and
/// machine-to-machine authentication credentials.
@Form([
  Field('apiKeyAuthEnabled', String, 'API Key Auth Enabled',
      hint: 'Yes | No — whether API key authentication is supported'),
  Field('apiKeyTypes', String, 'API Key Types',
      hint:
          'Static | Rotating | Scoped | ShortLived — types of API keys supported'),
  Field('keyGenerationMethod', String, 'Key Generation Method',
      hint:
          'Cryptographic random | UUID | JWT — how API keys are generated'),
  Field('keyLength', String, 'Key Length',
      hint: 'Minimum key length or entropy (e.g., 256-bit, 32 bytes)'),
  Field('keyRotationPolicy', String, 'Key Rotation Policy',
      hint: 'Rotation frequency and method (e.g., 90d, automatic, manual)'),
  Field('keyExpirationPolicy', String, 'Key Expiration Policy',
      hint: 'Maximum key lifetime (e.g., 1y, never, custom)'),
  Field('keyScopeRestrictions', String, 'Key Scope Restrictions',
      hint:
          'Yes | No — whether API keys can be limited to specific resources/actions'),
  Field('ipAllowlisting', String, 'IP Allowlisting',
      hint:
          'Yes | No — whether API keys can be restricted to specific IP addresses'),
  Field('rateLimitingPerKey', String, 'Rate Limiting Per Key',
      hint:
          'Yes | No — whether rate limiting is enforced per API key'),
  Field('keyRevocationProcess', String, 'Key Revocation Process',
      hint: 'Immediate | Graceful — how revoked keys stop working'),
  Field('keyStorageGuidance', String, 'Key Storage Guidance',
      hint:
          'VaultService | EnvironmentVariable | SecretManager — recommended storage'),
  Field('keyAuditLogging', String, 'Key Audit Logging',
      hint:
          'Yes | No — whether API key usage is logged for audit purposes'),
  Field('serviceTokenSupport', String, 'Service Token Support',
      hint:
          'OAuth2ClientCredentials | JWT | Custom — machine-to-machine token types'),
  Field('tokenLifetime', String, 'Token Lifetime',
      hint: 'Default lifetime for service tokens (e.g., 1h, 24h)'),
])
class ApiKeyManagementPolicy {
  String? content;

  /// API Key Management Details (text).
  TextSection apiKeyDetails = TextSection();
}

/// An authentication method entry (form) [PD00-ACC-IDE-AUT-MET-nn].
///
/// Detailed per-method specification aligned with NIST SP 800-63B
/// authenticator types (password, OTP, cryptographic, out-of-band).
class AuthenticationMethodEntry {
  @Form([
    Field('methodName', String, 'Method Name', required: true,
        hint: 'Unique name identifying this authentication method'),
    Field('methodType', String, 'Method Type',
        hint:
            'Password | TOTP | HOTP | FIDO2 | WebAuthn | SmartCard | Push | SMS | Email | Biometric | APIKey | Certificate'),
    Field('authenticationFactor', String, 'Authentication Factor',
        hint:
            'Knowledge | Possession | Inherence — NIST factor category'),
    Field('assuranceLevel', String, 'Assurance Level',
        hint: 'AAL1 | AAL2 | AAL3 — NIST authentication assurance level'),
    Field('phishingResistant', String, 'Phishing Resistant',
        hint:
            'Yes | No — whether this method resists phishing per NIST SP 800-63B §3.2.5'),
    Field('replayResistant', String, 'Replay Resistant',
        hint:
            'Yes | No — whether this method resists replay attacks'),
    Field('applicableUserCategories', String, 'Applicable User Categories',
        hint:
            'InternalUsers | ExternalUsers | Admins | ServiceAccounts | All'),
    Field('primaryOrSecondary', String, 'Primary or Secondary',
        hint:
            'Primary | Secondary | Either — role in authentication flow'),
    Field('enrollmentProcess', String, 'Enrollment Process',
        hint:
            'How users enroll in this method (self-service, admin-provisioned, automated)'),
    Field('enrollmentVerification', String, 'Enrollment Verification',
        hint:
            'Verification required during enrollment (identity proofing, email confirmation)'),
    Field('activationRequirement', String, 'Activation Requirement',
        hint:
            'PIN | Password | Biometric | None — activation factor for multi-factor authenticators'),
    Field('fallbackMethod', String, 'Fallback Method',
        hint:
            'Alternative method when this one is unavailable (recovery codes, admin reset)'),
    Field('maxFailedAttempts', String, 'Max Failed Attempts',
        hint:
            'Maximum consecutive failed attempts before lockout (e.g., 5, 10, 100)'),
    Field('lockoutPolicy', String, 'Lockout Policy',
        hint:
            'TemporaryDelay | AccountLock | RequireRebinding — action after max failures'),
    Field('reauthenticationTimeout', String, 'Reauthentication Timeout',
        hint:
            'Session timeout requiring reauthentication (e.g., 15min, 12h, 30d per AAL)'),
    Field('hardwareRequirement', String, 'Hardware Requirement',
        hint:
            'None | SecurityKey | SmartCard | TPM | HSM — required hardware'),
    Field('fipsValidationLevel', String, 'FIPS Validation Level',
        hint:
            'None | Level1 | Level2 | Level3 — FIPS 140 validation level if applicable'),
    Field('securityLevel', String, 'Security Level',
        hint: 'Low | Medium | High | Critical — overall security classification'),
    Field('description', String, 'Description',
        hint: 'Detailed description of this authentication method'),
  ])
  String? content;
}

/// 9.2.2.2. Authentication Flow [PD00-ACC-IDE-FLO].
///
/// Comprehensive authentication flow specification covering the complete
/// login lifecycle: credential submission, validation, multi-factor challenges,
/// token issuance, session establishment, redirect handling, and error
/// recovery. Aligned with OAuth 2.0/OIDC and NIST SP 800-63B flow patterns.
@SectionId('PD00-ACC-IDE-FLO')
class AuthenticationFlow {
  @Unused()
  String? content;

  /// Authentication Flow Overview (text).
  TextSection overview = TextSection();

  /// Authentication Flow Diagram (mermaid-sequence).
  SequenceDiagramSection authenticationFlowDiagram =
      SequenceDiagramSection();

  /// Login Flow Configuration.
  LoginFlowConfiguration loginFlow = LoginFlowConfiguration();

  /// Token Management Policy.
  TokenManagementPolicy tokenManagement = TokenManagementPolicy();

  /// Session Creation Policy.
  SessionCreationPolicy sessionCreation = SessionCreationPolicy();

  /// Redirect and Callback Handling.
  RedirectHandlingPolicy redirectHandling = RedirectHandlingPolicy();

  /// Authentication Error Handling.
  AuthenticationErrorHandling errorHandling =
      AuthenticationErrorHandling();

  /// Step-Up and Adaptive Authentication.
  StepUpAuthenticationPolicy stepUpAuthentication =
      StepUpAuthenticationPolicy();

  /// Contains 0+× Login Flow Step.
  @SectionIdPattern('PD00-ACC-IDE-FLO-xx')
  List<LoginFlowStepEntry> loginFlowSteps = [];
}

/// Login flow configuration (form).
///
/// Defines the overall login flow structure: entry points, credential
/// submission method, pre-authentication checks, and post-authentication
/// actions.
@Form([
  Field('loginEntryPoint', String, 'Login Entry Point',
      hint:
          'LoginPage | Modal | InlineWidget | ApiEndpoint — where users initiate login'),
  Field('credentialSubmissionMethod', String, 'Credential Submission Method',
      hint:
          'FormPost | Ajax | OAuth2AuthCode | OAuth2PKCE | SAMLRequest'),
  Field('preAuthenticationChecks', String, 'Pre-Authentication Checks',
      hint:
          'CAPTCHA | DeviceFingerprint | GeoIP | RiskScore | None'),
  Field('authenticationEndpoint', String, 'Authentication Endpoint',
      hint: 'URL or path of the authentication API endpoint'),
  Field('allowedAuthenticationMethods', String,
      'Allowed Authentication Methods',
      hint:
          'Comma-separated list of allowed methods for this login flow'),
  Field('mfaChallengePresentation', String, 'MFA Challenge Presentation',
      hint:
          'SamePage | SeparateStep | PushNotification — how MFA is presented'),
  Field('rememberMeEnabled', String, 'Remember Me Enabled',
      hint: 'Yes | No — whether Remember Me option is available'),
  Field('rememberMeDuration', String, 'Remember Me Duration',
      hint: 'Duration the device is remembered (e.g., 30d, 90d)'),
  Field('socialLoginEnabled', String, 'Social Login Enabled',
      hint: 'Yes | No — whether social identity providers are supported'),
  Field('socialLoginProviders', String, 'Social Login Providers',
      hint: 'Google | Apple | Microsoft | GitHub | Facebook — supported providers'),
  Field('passwordlessLoginEnabled', String, 'Passwordless Login Enabled',
      hint:
          'Yes | No — whether passwordless options (magic link, WebAuthn) are offered'),
  Field('passwordlessLoginMethods', String, 'Passwordless Login Methods',
      hint: 'MagicLink | WebAuthn | FIDO2 | Passkey — available passwordless methods'),
  Field('postAuthenticationAction', String, 'Post-Authentication Action',
      hint:
          'RedirectToOriginal | Dashboard | ConsentScreen | ProfileCompletion'),
  Field('concurrentLoginPolicy', String, 'Concurrent Login Policy',
      hint:
          'Allow | DenyNew | TerminateOldest | TerminateAll — behavior for concurrent logins'),
  Field('loginNotification', String, 'Login Notification',
      hint:
          'Yes | No — whether users are notified of successful logins'),
  Field('loginFromNewDeviceAction', String, 'Login From New Device Action',
      hint:
          'Notify | RequireMFA | Block | VerifyEmail — action for unrecognized devices'),
])
class LoginFlowConfiguration {
  String? content;

  /// Login Flow Details (text).
  TextSection loginFlowDetails = TextSection();
}

/// Token management policy (form).
///
/// Defines token issuance, refresh, storage, and revocation policies for
/// authentication tokens (JWT, opaque, refresh tokens, ID tokens).
@Form([
  Field('tokenFormat', String, 'Token Format',
      hint: 'JWT | Opaque | SAML | Custom — primary access token format'),
  Field('tokenSigningAlgorithm', String, 'Token Signing Algorithm',
      hint: 'RS256 | ES256 | HS256 | EdDSA — algorithm for signing tokens'),
  Field('accessTokenLifetime', String, 'Access Token Lifetime',
      hint: 'Duration of access token validity (e.g., 15min, 1h)'),
  Field('refreshTokenEnabled', String, 'Refresh Token Enabled',
      hint: 'Yes | No — whether refresh tokens are issued'),
  Field('refreshTokenLifetime', String, 'Refresh Token Lifetime',
      hint: 'Duration of refresh token validity (e.g., 7d, 30d)'),
  Field('refreshTokenRotation', String, 'Refresh Token Rotation',
      hint:
          'Yes | No — whether refresh tokens are rotated on each use'),
  Field('refreshTokenReuseDetection', String,
      'Refresh Token Reuse Detection',
      hint:
          'Yes | No — whether reuse of old refresh tokens triggers revocation'),
  Field('idTokenEnabled', String, 'ID Token Enabled',
      hint: 'Yes | No — whether OIDC ID tokens are issued'),
  Field('idTokenClaims', String, 'ID Token Claims',
      hint:
          'Standard claims included in ID tokens (sub, email, name, roles)'),
  Field('tokenStorageClient', String, 'Token Storage Client',
      hint:
          'HttpOnlyCookie | SessionStorage | LocalStorage | Memory — client-side storage'),
  Field('tokenStorageServer', String, 'Token Storage Server',
      hint:
          'Redis | Database | InMemory | None — server-side token store (for opaque tokens)'),
  Field('tokenRevocationEnabled', String, 'Token Revocation Enabled',
      hint: 'Yes | No — whether token revocation endpoint is available'),
  Field('tokenRevocationPropagation', String,
      'Token Revocation Propagation',
      hint:
          'Immediate | EventualConsistency | Polling — how revocation propagates'),
  Field('tokenIntrospectionEnabled', String, 'Token Introspection Enabled',
      hint:
          'Yes | No — whether RFC 7662 token introspection endpoint is available'),
  Field('audienceRestriction', String, 'Audience Restriction',
      hint:
          'Yes | No — whether tokens are audience-restricted to specific services'),
  Field('scopePolicy', String, 'Scope Policy',
      hint:
          'Minimum scope principle — how token scopes are assigned and validated'),
])
class TokenManagementPolicy {
  String? content;

  /// Token Management Details (text).
  TextSection tokenManagementDetails = TextSection();
}

/// Session creation policy (form).
///
/// Defines how authenticated sessions are established after successful
/// authentication: session binding, device binding, and session properties.
@Form([
  Field('sessionMechanism', String, 'Session Mechanism',
      hint:
          'ServerSideCookie | JwtBearer | OpaqueToken — primary session mechanism'),
  Field('sessionIdGeneration', String, 'Session ID Generation',
      hint:
          'CryptoRandom | UUID | HMAC — method for session identifier generation'),
  Field('sessionIdEntropy', String, 'Session ID Entropy',
      hint: 'Minimum entropy for session identifiers (e.g., 128-bit, 256-bit)'),
  Field('sessionBindingMethod', String, 'Session Binding Method',
      hint:
          'Cookie | Header | TokenBound — how sessions are bound to requests'),
  Field('httpOnlyCookies', String, 'HttpOnly Cookies',
      hint: 'Yes | No — whether session cookies use HttpOnly flag'),
  Field('secureCookies', String, 'Secure Cookies',
      hint: 'Yes | No — whether session cookies use Secure flag (HTTPS only)'),
  Field('sameSitePolicy', String, 'SameSite Policy',
      hint: 'Strict | Lax | None — SameSite cookie attribute policy'),
  Field('cookieDomain', String, 'Cookie Domain',
      hint: 'Domain scope for session cookies (exact domain or parent domain)'),
  Field('deviceBinding', String, 'Device Binding',
      hint:
          'None | Fingerprint | CertificateBound | DPoP — session-to-device binding'),
  Field('sessionDataStorage', String, 'Session Data Storage',
      hint:
          'ServerSide | ClientSide | Hybrid — where full session data is stored'),
  Field('sessionReplicationStrategy', String,
      'Session Replication Strategy',
      hint:
          'StickySession | Distributed | Stateless — strategy for multi-node deployments'),
  Field('csrfProtection', String, 'CSRF Protection',
      hint:
          'SynchronizerToken | DoubleSubmit | SameSite | None — CSRF mitigation method'),
  Field('postLoginRedirectValidation', String,
      'Post-Login Redirect Validation',
      hint:
          'Allowlist | SameOrigin | None — validation of post-login redirect targets'),
])
class SessionCreationPolicy {
  String? content;

  /// Session Creation Details (text).
  TextSection sessionCreationDetails = TextSection();
}

/// Redirect and callback handling policy (form).
///
/// Defines how authentication redirects, OAuth/OIDC callbacks, deep links,
/// and error redirects are managed in the authentication flow.
@Form([
  Field('oauthRedirectUriPolicy', String, 'OAuth Redirect URI Policy',
      hint:
          'ExactMatch | WildcardSubdomain | DynamicRegistration — redirect URI validation'),
  Field('allowedRedirectDomains', String, 'Allowed Redirect Domains',
      hint: 'Comma-separated list of allowed redirect domains'),
  Field('callbackUrlValidation', String, 'Callback URL Validation',
      hint:
          'StrictMatch | PathPrefix | OriginOnly — how callback URLs are validated'),
  Field('stateParameterRequired', String, 'State Parameter Required',
      hint:
          'Yes | No — whether OAuth state parameter is required for CSRF protection'),
  Field('pkceRequired', String, 'PKCE Required',
      hint:
          'Yes | No — whether PKCE (Proof Key for Code Exchange) is mandatory'),
  Field('pkceMethod', String, 'PKCE Method',
      hint: 'S256 | Plain — PKCE code challenge method (S256 recommended)'),
  Field('deepLinkHandling', String, 'Deep Link Handling',
      hint:
          'UniversalLinks | AppLinks | CustomScheme — mobile deep link strategy'),
  Field('errorRedirectBehavior', String, 'Error Redirect Behavior',
      hint:
          'RedirectWithError | ErrorPage | OriginalPage — behavior on auth errors'),
  Field('postLogoutRedirectUri', String, 'Post-Logout Redirect URI',
      hint: 'Where users are redirected after logout'),
  Field('singleLogoutRedirectChain', String,
      'Single Logout Redirect Chain',
      hint:
          'Yes | No — whether SLO propagates logouts across all connected services'),
  Field('corsPolicy', String, 'CORS Policy',
      hint:
          'AllowedOrigins for authentication endpoints (exact list or pattern)'),
  Field('iframeEmbeddingPolicy', String, 'Iframe Embedding Policy',
      hint:
          'Deny | SameOrigin | AllowSpecific — X-Frame-Options / CSP frame-ancestors'),
])
class RedirectHandlingPolicy {
  String? content;

  /// Redirect Handling Details (text).
  TextSection redirectDetails = TextSection();
}

/// Authentication error handling (form).
///
/// Defines how authentication failures, lockouts, and security events are
/// handled in the authentication flow.
@Form([
  Field('invalidCredentialResponse', String,
      'Invalid Credential Response',
      hint:
          'GenericError | SpecificError — response to invalid credentials (generic preferred)'),
  Field('accountLockoutThreshold', String, 'Account Lockout Threshold',
      hint:
          'Number of failed attempts before lockout (e.g., 5, 10, configurable)'),
  Field('lockoutDuration', String, 'Lockout Duration',
      hint:
          'Duration of lockout (e.g., 15min, 30min, progressive, permanent)'),
  Field('lockoutEscalation', String, 'Lockout Escalation',
      hint:
          'Fixed | Progressive | Exponential — whether lockout duration increases'),
  Field('bruteForceProtection', String, 'Brute Force Protection',
      hint:
          'RateLimiting | CAPTCHA | IPBlock | AccountLock — brute-force mitigation'),
  Field('credentialStuffingProtection', String,
      'Credential Stuffing Protection',
      hint:
          'BreachDatabase | DeviceFingerprint | BehaviorAnalysis | None'),
  Field('userNotificationOnFailure', String,
      'User Notification On Failure',
      hint:
          'Yes | No — whether users are notified of failed login attempts'),
  Field('adminAlertThreshold', String, 'Admin Alert Threshold',
      hint:
          'Number of failures before admin alert (e.g., 10, 50, per-minute rate)'),
  Field('failedLoginAuditLogging', String, 'Failed Login Audit Logging',
      hint:
          'Yes | No — whether failed login attempts are logged for audit'),
  Field('suspiciousActivityResponse', String,
      'Suspicious Activity Response',
      hint:
          'RequireMFA | TemporaryBlock | CAPTCHA | ManualReview — response to anomalies'),
  Field('gracefulDegradation', String, 'Graceful Degradation',
      hint:
          'Behavior when authentication service is partially unavailable (queue, fallback, deny)'),
])
class AuthenticationErrorHandling {
  String? content;

  /// Error Handling Details (text).
  TextSection errorHandlingDetails = TextSection();
}

/// Step-up and adaptive authentication policy (form).
///
/// Defines when and how authentication level is elevated for sensitive
/// operations, including risk-based and context-aware authentication.
@Form([
  Field('stepUpEnabled', String, 'Step-Up Enabled',
      hint: 'Yes | No — whether step-up authentication is implemented'),
  Field('stepUpTriggers', String, 'Step-Up Triggers',
      hint:
          'HighRiskOperation | SensitiveDataAccess | AdminAction | PaymentApproval | SettingsChange'),
  Field('stepUpTargetAal', String, 'Step-Up Target AAL',
      hint:
          'AAL2 | AAL3 — target assurance level for step-up authentication'),
  Field('stepUpTimeout', String, 'Step-Up Timeout',
      hint:
          'Duration the elevated session lasts (e.g., 5min, 15min, transaction-scoped)'),
  Field('riskBasedAuthEnabled', String, 'Risk-Based Auth Enabled',
      hint:
          'Yes | No — whether risk signals influence authentication requirements'),
  Field('riskSignals', String, 'Risk Signals',
      hint:
          'GeoLocation | IPReputation | DeviceFingerprint | BehaviorPattern | TimeOfDay'),
  Field('riskScoringMethod', String, 'Risk Scoring Method',
      hint:
          'RuleBased | MachineLearning | Hybrid — how risk scores are computed'),
  Field('lowRiskAction', String, 'Low Risk Action',
      hint: 'AllowSilently | NormalAuth — response to low-risk signals'),
  Field('mediumRiskAction', String, 'Medium Risk Action',
      hint:
          'RequireMFA | AdditionalVerification — response to medium-risk signals'),
  Field('highRiskAction', String, 'High Risk Action',
      hint:
          'Block | RequirePhishingResistant | ManualReview — response to high-risk signals'),
  Field('adaptiveAuthProvider', String, 'Adaptive Auth Provider',
      hint:
          'Built-in | Third-party service name — provider of adaptive authentication'),
  Field('continuousAuthEnabled', String, 'Continuous Auth Enabled',
      hint:
          'Yes | No — whether session is continuously monitored for risk changes'),
])
class StepUpAuthenticationPolicy {
  String? content;

  /// Step-Up Authentication Details (text).
  TextSection stepUpDetails = TextSection();
}

/// A login flow step entry (form) [PD00-ACC-IDE-FLO-nn].
///
/// Defines an individual step in the authentication flow sequence,
/// allowing detailed specification of each stage from initial request
/// to authenticated session.
class LoginFlowStepEntry {
  @Form([
    Field('stepName', String, 'Step Name', required: true,
        hint: 'Unique name for this login flow step'),
    Field('stepOrder', String, 'Step Order',
        hint: 'Numeric order in the flow sequence (1, 2, 3, ...)'),
    Field('stepType', String, 'Step Type',
        hint:
            'EntryPoint | CredentialInput | Validation | MfaChallenge | ConsentScreen | TokenIssuance | SessionCreation | Redirect | ErrorHandling'),
    Field('actor', String, 'Actor',
        hint:
            'User | Browser | AuthServer | IdP | MfaDevice | ResourceServer — who performs this step'),
    Field('inputRequired', String, 'Input Required',
        hint:
            'Username | Password | OTP | BiometricSample | ConsentApproval | None'),
    Field('validationAction', String, 'Validation Action',
        hint:
            'CredentialVerification | TokenValidation | RiskAssessment | MfaVerification | None'),
    Field('successOutcome', String, 'Success Outcome',
        hint:
            'NextStep | TokenIssued | SessionCreated | RedirectToApp — outcome on success'),
    Field('failureOutcome', String, 'Failure Outcome',
        hint:
            'RetryWithError | Lockout | RedirectToError | AbortFlow — outcome on failure'),
    Field('timeoutSeconds', String, 'Timeout Seconds',
        hint: 'Maximum time allowed for this step (e.g., 300, 600)'),
    Field('optional', String, 'Optional',
        hint: 'Yes | No — whether this step can be skipped'),
    Field('conditionalTrigger', String, 'Conditional Trigger',
        hint:
            'Condition under which this step is activated (e.g., MFA required, new device)'),
    Field('protocolMessage', String, 'Protocol Message',
        hint:
            'OAuth2 AuthZ Request | Token Request | SAML AuthnRequest | OIDC Userinfo — protocol-level message'),
    Field('description', String, 'Description',
        hint: 'Detailed description of what happens in this step'),
  ])
  String? content;
}

/// 9.2.3. Password and Credential Policy [PD00-ACC-IDE-POL].
///
/// Comprehensive password and credential policy aligned with NIST SP 800-63B
/// (Revision 4). Covers password requirements, storage, lifecycle, account
/// lockout, credential recovery, MFA enforcement per user category,
/// credential compromise detection, and service account credential management.
@SectionId('PD00-ACC-IDE-POL')
class PasswordAndCredentialPolicy {
  @Unused()
  String? content;

  /// Password and Credential Policy Overview (text).
  TextSection overview = TextSection();

  /// Password Requirements.
  PasswordRequirementsPolicy passwordRequirements =
      PasswordRequirementsPolicy();

  /// Password Storage and Verification.
  PasswordStoragePolicy passwordStorage = PasswordStoragePolicy();

  /// Password Lifecycle.
  PasswordLifecyclePolicy passwordLifecycle = PasswordLifecyclePolicy();

  /// Account Lockout and Throttling.
  AccountLockoutPolicy accountLockout = AccountLockoutPolicy();

  /// Credential Recovery.
  CredentialRecoveryPolicy credentialRecovery = CredentialRecoveryPolicy();

  /// Credential Compromise Detection.
  CredentialCompromiseDetectionPolicy compromiseDetection =
      CredentialCompromiseDetectionPolicy();

  /// Service Account and API Credential Policy.
  ServiceAccountCredentialPolicy serviceAccountCredentials =
      ServiceAccountCredentialPolicy();

  /// Contains 0+× MFA Enforcement per User Category.
  @SectionIdPattern('PD00-ACC-IDE-POL-xx')
  List<MfaCategoryRequirementEntry> mfaCategoryRequirements = [];
}

/// Password requirements policy (form).
///
/// Defines the rules for password creation, including length, complexity,
/// character set, and user guidance. Aligned with NIST SP 800-63B which
/// recommends length over complexity and prohibits composition rules.
@Form([
  Field('minimumLengthSingleFactor', String,
      'Minimum Length Single Factor',
      hint:
          'Minimum password length when used as single factor (NIST: 15 characters)'),
  Field('minimumLengthMultiFactor', String,
      'Minimum Length Multi Factor',
      hint:
          'Minimum password length when used as part of MFA (NIST: 8 characters)'),
  Field('maximumLength', String, 'Maximum Length',
      hint:
          'Maximum allowed password length (NIST: at least 64 characters)'),
  Field('allowedCharacterSets', String, 'Allowed Character Sets',
      hint:
          'ASCII | Unicode | ASCIIPlusSpace — character sets accepted in passwords'),
  Field('compositionRulesEnforced', String, 'Composition Rules Enforced',
      hint:
          'Yes | No — whether mixed-case/digit/symbol rules are enforced (NIST: No)'),
  Field('passphraseSupported', String, 'Passphrase Supported',
      hint:
          'Yes | No — whether multi-word passphrases with spaces are supported'),
  Field('unicodeNormalization', String, 'Unicode Normalization',
      hint:
          'NFC | NFD | None — Unicode normalization form applied before hashing'),
  Field('passwordBlocklistEnabled', String, 'Password Blocklist Enabled',
      hint:
          'Yes | No — whether passwords are compared against a blocklist'),
  Field('blocklistSources', String, 'Blocklist Sources',
      hint:
          'BreachCorpus | DictionaryWords | ContextSpecific | HaveIBeenPwned — sources for blocklist'),
  Field('passwordStrengthMeter', String, 'Password Strength Meter',
      hint:
          'Yes | No — whether a real-time strength indicator is displayed during creation'),
  Field('passwordHintsAllowed', String, 'Password Hints Allowed',
      hint:
          'Yes | No — whether password hints are stored (NIST: No)'),
  Field('securityQuestionsAllowed', String, 'Security Questions Allowed',
      hint:
          'Yes | No — whether KBA/security questions are used (NIST: No)'),
  Field('showPasswordOption', String, 'Show Password Option',
      hint:
          'Yes | No — whether users can toggle password visibility during entry'),
  Field('passwordManagerSupport', String, 'Password Manager Support',
      hint:
          'Yes | No — whether autofill and paste are supported for password entry'),
  Field('truncationPolicy', String, 'Truncation Policy',
      hint:
          'None | Trim — whether leading/trailing whitespace is trimmed (NIST: verify entire password)'),
  Field('typoTolerancePolicy', String, 'Typo Tolerance Policy',
      hint:
          'None | CaseFirstChar | TrimWhitespace — whether minor typo corrections are attempted'),
])
class PasswordRequirementsPolicy {
  String? content;

  /// Password Requirements Details (text).
  TextSection passwordRequirementsDetails = TextSection();
}

/// Password storage and verification policy (form).
///
/// Defines how passwords are stored, hashed, salted, and verified.
/// Aligned with NIST SP 800-63B and OWASP password storage recommendations.
@Form([
  Field('hashingAlgorithm', String, 'Hashing Algorithm',
      hint:
          'Argon2id | bcrypt | scrypt | PBKDF2 — password hashing algorithm'),
  Field('hashingCostFactor', String, 'Hashing Cost Factor',
      hint:
          'Work factor/iteration count for the hashing algorithm (e.g., bcrypt cost 12)'),
  Field('costFactorReviewSchedule', String, 'Cost Factor Review Schedule',
      hint:
          'Annual | Biannual | OnHardwareUpgrade — when cost factor is re-evaluated'),
  Field('saltLength', String, 'Salt Length',
      hint:
          'Minimum salt length in bits (NIST: at least 32 bits)'),
  Field('saltGeneration', String, 'Salt Generation',
      hint:
          'CryptoRandom | CSPRNG — method for generating salt values'),
  Field('pepperEnabled', String, 'Pepper Enabled',
      hint:
          'Yes | No — whether a server-side secret key (pepper) is used for additional hashing'),
  Field('pepperStorage', String, 'Pepper Storage',
      hint:
          'HSM | TEE | EncryptedConfig | SecretManager — where the pepper key is stored'),
  Field('hashVersioning', String, 'Hash Versioning',
      hint:
          'Yes | No — whether the hash algorithm and cost factor are stored per password for migration'),
  Field('transmissionEncryption', String, 'Transmission Encryption',
      hint:
          'TLS1.3 | TLS1.2 — encryption for password transmission'),
  Field('clientSideHashing', String, 'Client-Side Hashing',
      hint:
          'Yes | No — whether passwords are pre-hashed on the client before transmission'),
  Field('memoryHardFunction', String, 'Memory-Hard Function',
      hint:
          'Yes | No — whether the hashing function is memory-hard to resist GPU attacks'),
  Field('outputLength', String, 'Output Length',
      hint:
          'Hash output length in bits (should match underlying scheme output length)'),
])
class PasswordStoragePolicy {
  String? content;

  /// Password Storage Details (text).
  TextSection passwordStorageDetails = TextSection();
}

/// Password lifecycle policy (form).
///
/// Defines the lifecycle of passwords: creation, rotation, expiry, and
/// history. NIST SP 800-63B recommends against periodic rotation and
/// only forces changes on evidence of compromise.
@Form([
  Field('periodicRotationRequired', String, 'Periodic Rotation Required',
      hint:
          'Yes | No — whether periodic password changes are required (NIST: No)'),
  Field('rotationPeriod', String, 'Rotation Period',
      hint:
          'If rotation is required: period in days (e.g., 90, 180, 365)'),
  Field('forceChangeOnCompromise', String, 'Force Change On Compromise',
      hint:
          'Yes | No — whether password change is forced on evidence of compromise'),
  Field('passwordHistoryDepth', String, 'Password History Depth',
      hint:
          'Number of previous passwords stored to prevent reuse (e.g., 0, 5, 12, 24)'),
  Field('minimumPasswordAge', String, 'Minimum Password Age',
      hint:
          'Minimum time before a password can be changed again (e.g., 0, 1d) to prevent rapid cycling'),
  Field('initialPasswordPolicy', String, 'Initial Password Policy',
      hint:
          'SystemGenerated | UserChosen | TemporaryWithForceChange — policy for initial passwords'),
  Field('temporaryPasswordExpiry', String, 'Temporary Password Expiry',
      hint:
          'Duration before a temporary/initial password expires (e.g., 24h, 72h)'),
  Field('passwordExpiryWarning', String, 'Password Expiry Warning',
      hint:
          'Number of days before expiry that users are warned (e.g., 14, 30)'),
  Field('passwordChangeNotification', String,
      'Password Change Notification',
      hint:
          'Yes | No — whether users are notified when their password is changed'),
  Field('passwordChangeRequiresCurrent', String,
      'Password Change Requires Current',
      hint:
          'Yes | No — whether current password must be verified before setting a new one'),
  Field('administratorResetPolicy', String, 'Administrator Reset Policy',
      hint:
          'TemporaryPassword | ResetLink | MfaVerification — how admins reset user passwords'),
  Field('passwordInactivityDisable', String,
      'Password Inactivity Disable',
      hint:
          'Duration of inactivity before account is disabled (e.g., 90d, 180d, Never)'),
])
class PasswordLifecyclePolicy {
  String? content;

  /// Password Lifecycle Details (text).
  TextSection passwordLifecycleDetails = TextSection();
}

/// Account lockout and throttling policy (form).
///
/// Defines how failed authentication attempts are rate-limited and how
/// accounts are locked and unlocked. Aligned with NIST SP 800-63B
/// throttling requirements (max 100 consecutive failures).
@Form([
  Field('lockoutThreshold', String, 'Lockout Threshold',
      hint:
          'Number of consecutive failed attempts before lockout (NIST max: 100, typical: 5-10)'),
  Field('lockoutDuration', String, 'Lockout Duration',
      hint:
          'Duration of lockout (e.g., 15min, 30min, UntilAdminUnlock, Progressive)'),
  Field('lockoutEscalation', String, 'Lockout Escalation',
      hint:
          'Fixed | Progressive | Exponential — whether lockout duration increases'),
  Field('rateLimitingMethod', String, 'Rate Limiting Method',
      hint:
          'Delay | CAPTCHA | Lockout | IPBlock | Combination — rate-limiting strategy'),
  Field('delayProgression', String, 'Delay Progression',
      hint:
          'Delay schedule for progressive throttling (e.g., 30s after 3rd, 1min after 5th)'),
  Field('captchaTriggerThreshold', String, 'CAPTCHA Trigger Threshold',
      hint:
          'Number of failed attempts before CAPTCHA is required'),
  Field('ipBasedRateLimiting', String, 'IP-Based Rate Limiting',
      hint:
          'Yes | No — whether rate limiting also applies per IP address'),
  Field('distributedAttackProtection', String,
      'Distributed Attack Protection',
      hint:
          'Yes | No — whether protection against credential stuffing across IPs is implemented'),
  Field('unlockMechanism', String, 'Unlock Mechanism',
      hint:
          'TimeBasedAutoUnlock | AdminUnlock | SelfServiceWithMFA | EmailVerification'),
  Field('failedAttemptResetOnSuccess', String,
      'Failed Attempt Reset On Success',
      hint:
          'Yes | No — whether the failed attempt counter resets after successful login'),
  Field('lockoutNotification', String, 'Lockout Notification',
      hint:
          'User | Admin | Both | None — who is notified when lockout occurs'),
  Field('permanentLockoutEnabled', String, 'Permanent Lockout Enabled',
      hint:
          'Yes | No — whether accounts are permanently locked after extreme abuse'),
  Field('permanentLockoutThreshold', String,
      'Permanent Lockout Threshold',
      hint:
          'Number of lockout cycles before permanent lock (e.g., 5, 10)'),
])
class AccountLockoutPolicy {
  String? content;

  /// Account Lockout Details (text).
  TextSection accountLockoutDetails = TextSection();
}

/// Credential recovery policy (form).
///
/// Defines how users recover access when they lose credentials, including
/// password reset flows, recovery codes, and identity re-verification.
@Form([
  Field('passwordResetMethod', String, 'Password Reset Method',
      hint:
          'EmailLink | SMSCode | SecurityQuestions | MfaVerification | AdminAssisted — how users reset passwords'),
  Field('resetLinkExpiry', String, 'Reset Link Expiry',
      hint:
          'Duration before a password reset link expires (e.g., 15min, 1h, 24h)'),
  Field('resetLinkSingleUse', String, 'Reset Link Single Use',
      hint: 'Yes | No — whether reset links can only be used once'),
  Field('resetRateLimiting', String, 'Reset Rate Limiting',
      hint:
          'Requests per period allowed (e.g., 3 per hour, 5 per day)'),
  Field('savedRecoveryCodesEnabled', String,
      'Saved Recovery Codes Enabled',
      hint:
          'Yes | No — whether one-time recovery codes are provided at enrollment'),
  Field('recoveryCodeCount', String, 'Recovery Code Count',
      hint:
          'Number of recovery codes generated (e.g., 8, 10, 16)'),
  Field('recoveryCodeFormat', String, 'Recovery Code Format',
      hint:
          'AlphaNumeric | NumericOnly | Words — format of recovery codes'),
  Field('issuedRecoveryCodeChannels', String,
      'Issued Recovery Code Channels',
      hint:
          'Email | SMS | PostalMail | InPerson — channels for sending issued recovery codes'),
  Field('recoveryCodeExpiry', String, 'Recovery Code Expiry',
      hint:
          'Duration before issued recovery codes expire (NIST: 10min SMS, 24h email)'),
  Field('identityReverificationRequired', String,
      'Identity Reverification Required',
      hint:
          'Yes | No — whether identity re-verification is required for recovery at higher AALs'),
  Field('recoveryContactEnabled', String, 'Recovery Contact Enabled',
      hint:
          'Yes | No — whether a trusted contact can initiate recovery'),
  Field('multipleRecoveryAddresses', String,
      'Multiple Recovery Addresses',
      hint:
          'Yes | No — whether subscribers can register multiple recovery addresses (NIST: at least 2)'),
  Field('recoveryAuditLogging', String, 'Recovery Audit Logging',
      hint:
          'Yes | No — whether all recovery attempts are logged for audit'),
])
class CredentialRecoveryPolicy {
  String? content;

  /// Credential Recovery Details (text).
  TextSection credentialRecoveryDetails = TextSection();
}

/// Credential compromise detection policy (form).
///
/// Defines how compromised credentials are detected and how the system
/// responds, including breach database monitoring and proactive scanning.
@Form([
  Field('breachDatabaseMonitoring', String, 'Breach Database Monitoring',
      hint:
          'Yes | No — whether passwords are checked against known breach databases'),
  Field('breachDatabaseSource', String, 'Breach Database Source',
      hint:
          'HaveIBeenPwned | Internal | CommercialFeed | Multiple — source of breach data'),
  Field('breachCheckFrequency', String, 'Breach Check Frequency',
      hint:
          'AtCreation | AtLogin | Periodic | RealTime — when breach checks are performed'),
  Field('compromisedCredentialAction', String,
      'Compromised Credential Action',
      hint:
          'ForceChange | NotifyAndRecommend | DisableAccount — action when credential is found compromised'),
  Field('credentialStuffingDetection', String,
      'Credential Stuffing Detection',
      hint:
          'Yes | No — whether automated credential stuffing attacks are detected'),
  Field('stuffingDetectionMethod', String, 'Stuffing Detection Method',
      hint:
          'BehaviorAnalysis | IPReputation | VelocityChecks | DeviceFingerprint — detection methods'),
  Field('darkWebMonitoring', String, 'Dark Web Monitoring',
      hint:
          'Yes | No — whether organizational credentials are monitored on dark web'),
  Field('userCompromiseNotification', String,
      'User Compromise Notification',
      hint:
          'Email | InApp | Push | SMS — how users are notified of credential compromise'),
  Field('adminCompromiseAlerts', String, 'Admin Compromise Alerts',
      hint:
          'Yes | No — whether administrators receive alerts for mass compromise events'),
  Field('compromiseResponseSla', String, 'Compromise Response SLA',
      hint:
          'Time to force credential change after detection (e.g., Immediate, 24h, 72h)'),
])
class CredentialCompromiseDetectionPolicy {
  String? content;

  /// Compromise Detection Details (text).
  TextSection compromiseDetectionDetails = TextSection();
}

/// Service account and API credential policy (form).
///
/// Defines credential management for non-human identities: service accounts,
/// API keys, machine-to-machine tokens, and automation credentials.
@Form([
  Field('serviceAccountPasswordPolicy', String,
      'Service Account Password Policy',
      hint:
          'AutoGenerated | ManagedByVault | CertificateBased — how service account credentials are managed'),
  Field('serviceAccountRotationPeriod', String,
      'Service Account Rotation Period',
      hint:
          'Rotation period for service account credentials (e.g., 30d, 90d, OnDemand)'),
  Field('apiKeyLifetime', String, 'API Key Lifetime',
      hint:
          'Maximum lifetime for API keys (e.g., 90d, 365d, NoExpiry)'),
  Field('apiKeyRotationPolicy', String, 'API Key Rotation Policy',
      hint:
          'Automatic | Manual | GracePeriodOverlap — how API keys are rotated'),
  Field('secretsManagementTool', String, 'Secrets Management Tool',
      hint:
          'HashiCorpVault | AWSSecretsManager | AzureKeyVault | GCPSecretManager | None'),
  Field('machineToMachineAuth', String, 'Machine-to-Machine Auth',
      hint:
          'OAuth2ClientCredentials | mTLS | JWTBearer | APIKey — authentication method'),
  Field('serviceAccountMfaRequired', String,
      'Service Account MFA Required',
      hint:
          'Yes | No — whether service accounts require MFA for interactive login'),
  Field('sharedCredentialProhibition', String,
      'Shared Credential Prohibition',
      hint:
          'Yes | No — whether shared/group credentials are prohibited'),
  Field('credentialVaultIntegration', String,
      'Credential Vault Integration',
      hint:
          'Yes | No — whether application credentials are injected from a secrets vault at runtime'),
  Field('hardcodedCredentialDetection', String,
      'Hardcoded Credential Detection',
      hint:
          'Yes | No — whether CI/CD scans for hardcoded credentials in source code'),
])
class ServiceAccountCredentialPolicy {
  String? content;

  /// Service Account Credential Details (text).
  TextSection serviceAccountDetails = TextSection();
}

/// An MFA enforcement per user category entry (form) [PD00-ACC-IDE-POL-nn].
///
/// Defines MFA requirements for a specific user category, allowing
/// different authentication assurance levels per role or access tier.
class MfaCategoryRequirementEntry {
  @Form([
    Field('userCategory', String, 'User Category', required: true,
        hint:
            'Name of the user category (e.g., Administrator, Employee, Customer, Partner, API)'),
    Field('mfaRequired', String, 'MFA Required',
        hint: 'Yes | No | Conditional — whether MFA is required for this category'),
    Field('targetAal', String, 'Target AAL',
        hint:
            'AAL1 | AAL2 | AAL3 — target Authentication Assurance Level'),
    Field('allowedAuthenticatorTypes', String,
        'Allowed Authenticator Types',
        hint:
            'TOTP | WebAuthn | FIDO2 | SMS | Push | Passkey — allowed second-factor types'),
    Field('phishingResistanceRequired', String,
        'Phishing Resistance Required',
        hint:
            'Yes | No | Recommended — whether phishing-resistant authenticators are required'),
    Field('mfaEnrollmentDeadline', String, 'MFA Enrollment Deadline',
        hint:
            'Deadline or grace period for MFA enrollment (e.g., Immediate, 30d, 90d)'),
    Field('mfaGracePeriod', String, 'MFA Grace Period',
        hint:
            'Period after enrollment deadline during which MFA is recommended but not enforced'),
    Field('rememberDeviceEnabled', String, 'Remember Device Enabled',
        hint:
            'Yes | No — whether trusted device remembering can skip MFA temporarily'),
    Field('rememberDeviceDuration', String, 'Remember Device Duration',
        hint:
            'Duration the device is trusted (e.g., 7d, 30d, 90d)'),
    Field('fallbackMechanismIfUnavailable', String,
        'Fallback If Unavailable',
        hint:
            'RecoveryCode | AdminAssist | Deny — fallback when primary MFA is unavailable'),
    Field('reauthenticationTimeout', String, 'Reauthentication Timeout',
        hint:
            'Overall session timeout requiring re-authentication (NIST: AAL1=30d, AAL2=24h, AAL3=12h)'),
    Field('inactivityTimeout', String, 'Inactivity Timeout',
        hint:
            'Session inactivity timeout (NIST: AAL2=1h, AAL3=15min)'),
    Field('description', String, 'Description',
        hint:
            'Description of MFA requirements and rationale for this user category'),
  ])
  String? content;
}

/// 9.2.4. Session Management [PD00-ACC-IDE-SES].
///
/// Comprehensive session management policy covering session timeouts,
/// concurrent session control, session revocation, remember-me functionality,
/// session security hardening, and session lifecycle monitoring.
/// Aligned with OWASP Session Management Cheat Sheet and NIST SP 800-63B
/// session requirements by Authentication Assurance Level (AAL).
@SectionId('PD00-ACC-IDE-SES')
class SessionManagement {
  @Unused()
  String? content;

  /// Session Management Overview (text).
  TextSection overview = TextSection();

  /// Session Timeout Policy.
  SessionTimeoutPolicy sessionTimeoutPolicy = SessionTimeoutPolicy();

  /// Concurrent Session Policy.
  ConcurrentSessionPolicy concurrentSessionPolicy = ConcurrentSessionPolicy();

  /// Session Revocation Policy.
  SessionRevocationPolicy sessionRevocationPolicy = SessionRevocationPolicy();

  /// Remember-Me and Persistent Session Policy.
  RememberMePolicy rememberMePolicy = RememberMePolicy();

  /// Session Security Hardening Policy.
  SessionSecurityPolicy sessionSecurityPolicy = SessionSecurityPolicy();

  /// Session Lifecycle Monitoring.
  SessionLifecycleMonitoring sessionLifecycleMonitoring =
      SessionLifecycleMonitoring();
}

/// Session timeout policy (form).
///
/// Defines idle timeout, absolute timeout, and renewal timeout
/// parameters including per-AAL differentiation. OWASP recommends
/// idle timeouts of 2–5 min for high-value and 15–30 min for low-risk
/// applications. Absolute timeouts limit maximum session duration.
@Form([
  Field('idleTimeoutDefault', String, 'Default Idle Timeout',
      hint:
          'Duration of inactivity before session expires (e.g., 15min, 30min, 1h)'),
  Field('idleTimeoutHighValue', String, 'Idle Timeout — High-Value Operations',
      hint:
          'Shorter idle timeout for sensitive operations (e.g., 2min, 5min)'),
  Field('absoluteTimeout', String, 'Absolute Session Timeout',
      hint:
          'Maximum session duration regardless of activity (e.g., 4h, 8h, 24h)'),
  Field('renewalTimeout', String, 'Session ID Renewal Timeout',
      hint:
          'Interval at which the session ID is transparently rotated (e.g., 15min, 30min)'),
  Field('idleTimeoutAal1', String, 'Idle Timeout — AAL1',
      hint: 'Idle timeout for AAL1 sessions (NIST default: 30 days)'),
  Field('absoluteTimeoutAal1', String, 'Absolute Timeout — AAL1',
      hint: 'Maximum session duration for AAL1 (NIST default: 30 days)'),
  Field('idleTimeoutAal2', String, 'Idle Timeout — AAL2',
      hint: 'Idle timeout for AAL2 sessions (NIST default: 1 hour)'),
  Field('absoluteTimeoutAal2', String, 'Absolute Timeout — AAL2',
      hint: 'Maximum session duration for AAL2 (NIST default: 24 hours)'),
  Field('idleTimeoutAal3', String, 'Idle Timeout — AAL3',
      hint: 'Idle timeout for AAL3 sessions (NIST default: 15 minutes)'),
  Field('absoluteTimeoutAal3', String, 'Absolute Timeout — AAL3',
      hint: 'Maximum session duration for AAL3 (NIST default: 12 hours)'),
  Field('timeoutEnforcement', String, 'Timeout Enforcement',
      hint:
          'ServerSide | ClientSide | Both — where session timeout is enforced (server-side mandatory)'),
  Field('timeoutWarningEnabled', String, 'Timeout Warning Enabled',
      hint:
          'Yes | No — whether users receive a warning before session expiry'),
  Field('timeoutWarningLeadTime', String, 'Timeout Warning Lead Time',
      hint:
          'Time before expiry to show warning (e.g., 2min, 5min)'),
  Field('timeoutWarningAction', String, 'Timeout Warning Action',
      hint:
          'ExtendSession | SaveDraft | RedirectToLogin — action offered to user'),
  Field('sessionExtensionAllowed', String, 'Session Extension Allowed',
      hint:
          'Yes | No | Limited — whether users can extend an expiring session'),
  Field('maxExtensions', String, 'Maximum Session Extensions',
      hint:
          'Maximum number of consecutive session extensions (e.g., 3, unlimited)'),
  Field('gracePeriodAfterExpiry', String, 'Grace Period After Expiry',
      hint:
          'Brief window after expiry for saving work (e.g., 0s, 30s, 2min)'),
])
class SessionTimeoutPolicy {
  String? content;

  /// Session Timeout Details (text).
  TextSection sessionTimeoutDetails = TextSection();
}

/// Concurrent session policy (form).
///
/// Defines how the application handles multiple simultaneous sessions
/// from the same user account, including limits, notifications, and
/// conflict resolution strategies.
@Form([
  Field('concurrentSessionsAllowed', String, 'Concurrent Sessions Allowed',
      hint: 'Yes | No | Limited — whether multiple simultaneous sessions are permitted'),
  Field('maxConcurrentSessions', String, 'Maximum Concurrent Sessions',
      hint:
          'Maximum number of active sessions per user (e.g., 1, 3, 5, unlimited)'),
  Field('concurrentSessionScope', String, 'Concurrent Session Scope',
      hint:
          'PerAccount | PerDeviceType | PerApplication — scope for counting sessions'),
  Field('conflictResolution', String, 'Session Conflict Resolution',
      hint:
          'TerminateOldest | TerminateNewest | DenyNew | AskUser — action when limit exceeded'),
  Field('sessionListVisible', String, 'Session List Visible to User',
      hint:
          'Yes | No — whether users can see a list of their active sessions'),
  Field('remoteTerminationEnabled', String, 'Remote Termination Enabled',
      hint:
          'Yes | No — whether users can terminate other sessions remotely'),
  Field('sessionDeviceInfo', String, 'Session Device Information',
      hint:
          'IPAddress | DeviceType | Browser | Location | All — info shown per session'),
  Field('concurrentLoginNotification', String, 'Concurrent Login Notification',
      hint:
          'None | Email | Push | InApp | All — notification when new session starts'),
  Field('suspiciousConcurrentLoginAction', String,
      'Suspicious Concurrent Login Action',
      hint:
          'Notify | RequireMFA | TerminateAll | LockAccount — action for suspicious simultaneous access'),
  Field('privilegedAccountSessionLimit', String,
      'Privileged Account Session Limit',
      hint:
          'Maximum sessions for admin/privileged accounts (typically stricter, e.g., 1)'),
  Field('crossDeviceSessionHandling', String, 'Cross-Device Session Handling',
      hint:
          'Independent | Synchronized | SingleDevice — how sessions relate across devices'),
])
class ConcurrentSessionPolicy {
  String? content;

  /// Concurrent Session Details (text).
  TextSection concurrentSessionDetails = TextSection();
}

/// Session revocation policy (form).
///
/// Defines how sessions are explicitly invalidated: logout behavior,
/// administrative termination, privilege change handling, and
/// bulk revocation scenarios.
@Form([
  Field('logoutMechanism', String, 'Logout Mechanism',
      hint:
          'ServerSideInvalidation | TokenBlacklist | CookieClear | All — how sessions are terminated'),
  Field('logoutButtonPlacement', String, 'Logout Button Placement',
      hint:
          'Header | Menu | Both | EveryPage — where the logout action is accessible'),
  Field('logoutConfirmation', String, 'Logout Confirmation',
      hint:
          'Immediate | ConfirmDialog | None — whether logout requires confirmation'),
  Field('postLogoutRedirect', String, 'Post-Logout Redirect',
      hint:
          'LoginPage | HomePage | GoodbyePage | CustomUrl — where users go after logout'),
  Field('postLogoutCacheClear', String, 'Post-Logout Cache Clear',
      hint:
          'Yes | No — whether Clear-Site-Data header is sent on logout'),
  Field('singleLogoutEnabled', String, 'Single Logout (SLO) Enabled',
      hint:
          'Yes | No — whether logout propagates to all connected IdPs and services'),
  Field('singleLogoutProtocol', String, 'Single Logout Protocol',
      hint:
          'FrontChannel | BackChannel | Both — SLO propagation method'),
  Field('privilegeChangeRevocation', String,
      'Session Revocation on Privilege Change',
      hint:
          'Regenerate | Terminate | NoAction — session handling when user roles change'),
  Field('passwordChangeRevocation', String,
      'Session Revocation on Password Change',
      hint:
          'TerminateAll | TerminateOthers | KeepCurrent — session handling after password change'),
  Field('compromiseRevocation', String,
      'Session Revocation on Compromise Detection',
      hint:
          'TerminateAll | TerminateOthers | RequireReauth — action when account compromise suspected'),
  Field('adminTerminationEnabled', String, 'Admin Session Termination Enabled',
      hint:
          'Yes | No — whether administrators can terminate user sessions'),
  Field('bulkRevocationEnabled', String, 'Bulk Session Revocation Enabled',
      hint:
          'Yes | No — whether mass session invalidation is supported (e.g., security incident)'),
  Field('revocationPropagationDelay', String,
      'Revocation Propagation Delay',
      hint:
          'Immediate | EventualConsistency | MaxDelay — how quickly revocation takes effect across nodes'),
])
class SessionRevocationPolicy {
  String? content;

  /// Session Revocation Details (text).
  TextSection sessionRevocationDetails = TextSection();
}

/// Remember-me and persistent session policy (form).
///
/// Defines the remember-me (persistent login) functionality, device trust,
/// and long-lived session token management. Persistent sessions trade
/// security for convenience and must be carefully scoped.
@Form([
  Field('rememberMeEnabled', String, 'Remember-Me Enabled',
      hint: 'Yes | No — whether remember-me / keep-me-signed-in is offered'),
  Field('rememberMeDuration', String, 'Remember-Me Duration',
      hint:
          'Duration of persistent session (e.g., 7d, 30d, 90d)'),
  Field('rememberMeTokenType', String, 'Remember-Me Token Type',
      hint:
          'PersistentCookie | DeviceToken | RefreshToken — mechanism for persistent login'),
  Field('rememberMeTokenStorage', String, 'Remember-Me Token Storage',
      hint:
          'HttpOnlyCookie | SecureStorage | EncryptedLocalStorage — client-side storage'),
  Field('rememberMeTokenRotation', String, 'Remember-Me Token Rotation',
      hint:
          'Yes | No — whether persistent tokens are rotated on each use'),
  Field('rememberMeReuseDetection', String, 'Remember-Me Reuse Detection',
      hint:
          'Yes | No — whether reuse of old persistent tokens triggers revocation'),
  Field('rememberMeDeviceBinding', String, 'Remember-Me Device Binding',
      hint:
          'None | Fingerprint | CertificateBound — how persistent tokens are bound to devices'),
  Field('rememberMeRevocation', String, 'Remember-Me Revocation',
      hint:
          'ManualOnly | OnPasswordChange | OnSecurityEvent | All — when persistent tokens are revoked'),
  Field('rememberMeAalReduction', String, 'Remember-Me AAL Reduction',
      hint:
          'Yes | No — whether remember-me reduces effective AAL (e.g., AAL2 to AAL1)'),
  Field('rememberMeRestrictedOperations', String,
      'Restricted Operations with Remember-Me',
      hint:
          'Operations requiring full reauthentication even with active remember-me (e.g., password change, payment)'),
  Field('trustedDeviceManagement', String, 'Trusted Device Management',
      hint:
          'Yes | No — whether users can manage a list of trusted/remembered devices'),
  Field('maxTrustedDevices', String, 'Maximum Trusted Devices',
      hint:
          'Maximum number of devices in the trusted device list (e.g., 5, 10)'),
  Field('trustedDeviceExpiry', String, 'Trusted Device Expiry',
      hint:
          'Duration a device stays trusted (e.g., 30d, 90d, indefinite)'),
])
class RememberMePolicy {
  String? content;

  /// Remember-Me Policy Details (text).
  TextSection rememberMeDetails = TextSection();
}

/// Session security hardening policy (form).
///
/// Defines session fixation protection, session binding to user properties,
/// session anomaly detection, and content caching policies.
/// Aligned with OWASP Session Management Cheat Sheet recommendations.
@Form([
  Field('sessionFixationProtection', String, 'Session Fixation Protection',
      hint:
          'RegenerateOnLogin | RegenerateOnPrivilegeChange | Both — session ID regeneration strategy'),
  Field('sessionIdRegenerationTriggers', String,
      'Session ID Regeneration Triggers',
      hint:
          'Login | PrivilegeChange | PasswordChange | MfaStep | All — events triggering session ID renewal'),
  Field('sessionBindingProperties', String, 'Session Binding Properties',
      hint:
          'None | IPAddress | UserAgent | DeviceFingerprint | TlsCertificate — properties bound to session'),
  Field('bindingMismatchAction', String, 'Binding Mismatch Action',
      hint:
          'Terminate | RequireReauth | LogAndContinue | StepUpAuth — action on session binding violation'),
  Field('sessionAnomalyDetection', String, 'Session Anomaly Detection',
      hint:
          'Yes | No — whether session anomalies (IP change, user-agent change) are monitored'),
  Field('anomalyDetectionSignals', String, 'Anomaly Detection Signals',
      hint:
          'IPChange | UserAgentChange | GeoLocationJump | ConcurrentAccess — signals monitored'),
  Field('sessionCachePolicy', String, 'Session Cache Policy',
      hint:
          'NoStore | NoCache | Private — Cache-Control directive for pages with session data'),
  Field('clearSiteDataOnLogout', String, 'Clear-Site-Data on Logout',
      hint:
          'Yes | No — whether Clear-Site-Data header clears cache, cookies, storage on logout'),
  Field('sessionTransportSecurity', String, 'Session Transport Security',
      hint:
          'HttpsOnly | HstsEnabled | CertificatePinning — transport layer requirements for sessions'),
  Field('sessionIdInUrlPrevention', String, 'Session ID in URL Prevention',
      hint:
          'Yes | No — whether session IDs in URL parameters are explicitly blocked'),
  Field('crossOriginSessionProtection', String,
      'Cross-Origin Session Protection',
      hint:
          'SameSiteCookies | CorsRestriction | Both — cross-origin session protection mechanisms'),
  Field('sessionDataMinimization', String, 'Session Data Minimization',
      hint:
          'Yes | No — whether session stores only essential data (minimize sensitive data in session)'),
])
class SessionSecurityPolicy {
  String? content;

  /// Session Security Details (text).
  TextSection sessionSecurityDetails = TextSection();
}

/// Session lifecycle monitoring (form).
///
/// Defines how session events are logged, monitored, and audited
/// throughout the session lifecycle: creation, usage, renewal,
/// and destruction.
@Form([
  Field('sessionCreationLogging', String, 'Session Creation Logging',
      hint:
          'Yes | No — whether session creation events are logged'),
  Field('sessionDestructionLogging', String, 'Session Destruction Logging',
      hint:
          'Yes | No — whether session termination events are logged'),
  Field('sessionRenewalLogging', String, 'Session Renewal Logging',
      hint:
          'Yes | No — whether session ID renewal events are logged'),
  Field('sessionEventDetails', String, 'Session Event Details',
      hint:
          'Timestamp | SourceIP | UserAgent | GeoLocation | SessionAction — details captured per event'),
  Field('sessionIdInLogs', String, 'Session ID in Logs',
      hint:
          'SaltedHash | Truncated | Never — how session IDs appear in logs (never in plaintext)'),
  Field('sessionActivityTracking', String, 'Session Activity Tracking',
      hint:
          'Yes | No — whether per-session activity (page visits, actions) is tracked'),
  Field('sessionHistoryVisibleToUser', String,
      'Session History Visible to User',
      hint:
          'Yes | No — whether users can view their session activity history'),
  Field('failedSessionAccessLogging', String,
      'Failed Session Access Logging',
      hint:
          'Yes | No — whether invalid/expired session access attempts are logged'),
  Field('sessionMetricsCollection', String, 'Session Metrics Collection',
      hint:
          'Yes | No — whether session duration, count, and patterns are collected as metrics'),
  Field('sessionAuditRetention', String, 'Session Audit Log Retention',
      hint:
          'Duration session audit logs are retained (e.g., 90d, 1y, 7y)'),
  Field('realTimeSessionAlerts', String, 'Real-Time Session Alerts',
      hint:
          'Yes | No — whether suspicious session events trigger real-time alerts'),
  Field('alertTriggers', String, 'Session Alert Triggers',
      hint:
          'BruteForce | AnomalousAccess | MassLogout | SessionHijack — events triggering alerts'),
])
class SessionLifecycleMonitoring {
  String? content;

  /// Session Lifecycle Monitoring Details (text).
  TextSection sessionLifecycleDetails = TextSection();
}

/// 9.3. Resource Protection [PD00-ACC-RES].
@SectionId('PD00-ACC-RES')
class ResourceProtection {
  @Unused()
  String? content;

  /// 9.3.1. Data-Level Security [PD00-ACC-RES-DAT].
  DataLevelSecurity dataLevelSecurity = DataLevelSecurity();

  /// 9.3.2. API Security [PD00-ACC-RES-API].
  ApiSecurity apiSecurity = ApiSecurity();

  /// 9.3.3. File and Storage Security [PD00-ACC-RES-FIL].
  FileAndStorageSecurity fileAndStorageSecurity = FileAndStorageSecurity();
}

/// 9.3.1. Data-Level Security [PD00-ACC-RES-DAT].
///
/// Comprehensive data access protection specification covering database-level
/// security, row-level security, column-level security, tenant data isolation,
/// and data masking for production and non-production environments.
/// Aligned with OWASP Database Security Cheat Sheet and least-privilege principles.
@SectionId('PD00-ACC-RES-DAT')
class DataLevelSecurity {
  @Unused()
  String? content;

  /// Data-Level Security Overview (text).
  TextSection overview = TextSection();

  /// Database Access Policy.
  DatabaseAccessPolicy databaseAccessPolicy = DatabaseAccessPolicy();

  /// Row-Level Security Policy.
  RowLevelSecurityPolicy rowLevelSecurityPolicy = RowLevelSecurityPolicy();

  /// Column-Level Security Policy.
  ColumnLevelSecurityPolicy columnLevelSecurityPolicy =
      ColumnLevelSecurityPolicy();

  /// Tenant Data Isolation Policy.
  TenantDataIsolationPolicy tenantDataIsolationPolicy =
      TenantDataIsolationPolicy();

  /// Data Masking Policy.
  DataMaskingPolicy dataMaskingPolicy = DataMaskingPolicy();

  /// Data Access Audit Policy.
  DataAccessAuditPolicy dataAccessAuditPolicy = DataAccessAuditPolicy();
}

/// Database access policy (form).
///
/// Defines how application and administrative accounts access the database,
/// including connection security, credential management, and privilege
/// assignment following the principle of least privilege.
@Form([
  Field('databaseConnectionSecurity', String, 'Database Connection Security',
      hint:
          'TlsRequired | TlsOptional | LocalSocketOnly — transport security for DB connections'),
  Field('minimumTlsVersion', String, 'Minimum TLS Version',
      hint: 'TLS 1.2 | TLS 1.3 — minimum TLS version for database connections'),
  Field('applicationAccountStrategy', String, 'Application Account Strategy',
      hint:
          'PerService | PerModule | SharedPool — how application-level DB accounts are organized'),
  Field('applicationAccountPrivileges', String,
      'Application Account Privileges',
      hint:
          'SelectUpdateDelete | ReadOnly | Custom — default permissions for application accounts'),
  Field('schemaOwnershipSeparation', String, 'Schema Ownership Separation',
      hint:
          'Yes | No — whether schema owner accounts are separate from application accounts'),
  Field('directTableAccess', String, 'Direct Table Access',
      hint:
          'Allowed | ViewsOnly | StoredProceduresOnly — whether direct table access is permitted'),
  Field('databaseCredentialStorage', String, 'Database Credential Storage',
      hint:
          'SecretsVault | EnvironmentVariable | EncryptedConfig — where DB credentials are stored'),
  Field('credentialRotationPolicy', String, 'Credential Rotation Policy',
      hint:
          'Automatic | Manual | Interval — how DB credentials are rotated (e.g., every 90d)'),
  Field('connectionPoolSecurity', String, 'Connection Pool Security',
      hint:
          'PerUser | PerService | Shared — connection pool isolation level'),
  Field('privilegedAccessManagement', String, 'Privileged Access Management',
      hint:
          'JustInTime | PermanentWithApproval | BreakGlass — how DBA access is managed'),
  Field('databaseFirewallRules', String, 'Database Firewall Rules',
      hint:
          'AllowlistOnly | VpcInternal | SubnetRestricted — network access restrictions'),
  Field('sqlInjectionPrevention', String, 'SQL Injection Prevention',
      hint:
          'ParameterizedQueries | OrmOnly | PreparedStatements — SQL injection mitigation strategy'),
  Field('queryComplexityLimits', String, 'Query Complexity Limits',
      hint:
          'Yes | No — whether query complexity or execution time limits are enforced'),
  Field('databaseActivityMonitoring', String, 'Database Activity Monitoring',
      hint:
          'DamEnabled | NativeAudit | None — database activity monitoring tool usage'),
])
class DatabaseAccessPolicy {
  String? content;

  /// Database Access Policy Details (text).
  TextSection databaseAccessDetails = TextSection();
}

/// Row-level security policy (form).
///
/// Defines how data access is restricted at the row level, ensuring users
/// can only access data rows they are authorized to see. Covers tenant-based
/// filtering, user-scoped access, and hierarchical data visibility.
@Form([
  Field('rowLevelSecurityEnabled', String, 'Row-Level Security Enabled',
      hint:
          'Yes | No — whether row-level security (RLS) is implemented'),
  Field('rlsImplementation', String, 'RLS Implementation',
      hint:
          'DatabaseNative | ApplicationLayer | OrmFilter | Hybrid — where RLS is enforced'),
  Field('rlsFilteringStrategy', String, 'RLS Filtering Strategy',
      hint:
          'TenantId | UserId | OrganizationId | CustomPredicate — primary filtering dimension'),
  Field('rlsBypassPolicy', String, 'RLS Bypass Policy',
      hint:
          'NeverBypass | SuperAdminOnly | ServiceAccountOnly — who can bypass RLS'),
  Field('hierarchicalVisibility', String, 'Hierarchical Data Visibility',
      hint:
          'Yes | No — whether managers see subordinate data (organizational hierarchy)'),
  Field('hierarchyDepthLimit', String, 'Hierarchy Depth Limit',
      hint:
          'Unlimited | DirectReports | NLevels — how deep hierarchical visibility extends'),
  Field('crossTenantAccess', String, 'Cross-Tenant Data Access',
      hint:
          'Denied | PlatformAdminOnly | ConsentBased — cross-tenant data access rules'),
  Field('dataOwnerAccess', String, 'Data Owner Access',
      hint:
          'FullAccess | ReadOnly | Delegated — access level for the data owner/creator'),
  Field('sharedDataHandling', String, 'Shared Data Handling',
      hint:
          'ExplicitGrant | GroupBased | LinkSharing — how shared records are authorized'),
  Field('rlsPerformanceStrategy', String, 'RLS Performance Strategy',
      hint:
          'IndexedFilterColumn | PartitionedByTenant | MaterializedViews — performance optimization for RLS'),
  Field('rlsTestingStrategy', String, 'RLS Testing Strategy',
      hint:
          'AutomatedTests | PenetrationTesting | Both — how RLS enforcement is verified'),
])
class RowLevelSecurityPolicy {
  String? content;

  /// Row-Level Security Details (text).
  TextSection rowLevelSecurityDetails = TextSection();
}

/// Column-level security policy (form).
///
/// Defines how access to specific data columns or fields is restricted
/// based on user roles, sensitivity classification, or regulatory requirements.
@Form([
  Field('columnLevelSecurityEnabled', String,
      'Column-Level Security Enabled',
      hint:
          'Yes | No — whether column-level access control is implemented'),
  Field('columnAccessImplementation', String,
      'Column Access Implementation',
      hint:
          'DatabaseGrants | ViewRestriction | ApplicationLayer | FieldProjection — enforcement mechanism'),
  Field('sensitiveColumnClassification', String,
      'Sensitive Column Classification',
      hint:
          'PII | Financial | Health | Confidential | Internal | Public — classification scheme for columns'),
  Field('piiColumnAccess', String, 'PII Column Access',
      hint:
          'RestrictedByRole | MaskedByDefault | EncryptedAtRest — access policy for PII columns'),
  Field('financialDataColumnAccess', String, 'Financial Data Column Access',
      hint:
          'RestrictedByRole | AuditedAccess | Masked — access policy for financial data columns'),
  Field('healthDataColumnAccess', String, 'Health Data Column Access',
      hint:
          'HipaaCompliant | StrictRole | Encrypted — access policy for health/medical data'),
  Field('dynamicFieldVisibility', String, 'Dynamic Field Visibility',
      hint:
          'Yes | No — whether field visibility varies dynamically based on user role or context'),
  Field('columnAccessAudit', String, 'Column Access Audit',
      hint:
          'Yes | No — whether access to sensitive columns is individually audited'),
  Field('columnEncryptionPolicy', String, 'Column Encryption Policy',
      hint:
          'None | SelectedColumns | AllSensitive | AlwaysEncrypted — column-level encryption approach'),
])
class ColumnLevelSecurityPolicy {
  String? content;

  /// Column-Level Security Details (text).
  TextSection columnLevelSecurityDetails = TextSection();
}

/// Tenant data isolation policy (form).
///
/// Defines the multi-tenant data separation strategy, ensuring tenant
/// data is logically or physically isolated and cannot leak between tenants.
@Form([
  Field('tenantIsolationModel', String, 'Tenant Isolation Model',
      hint:
          'SharedDatabase_SharedSchema | SharedDatabase_SeparateSchema | SeparateDatabase — multi-tenancy architecture'),
  Field('tenantIdentifierColumn', String, 'Tenant Identifier Column',
      hint:
          'Column name used for tenant filtering (e.g., tenant_id, org_id)'),
  Field('tenantContextInjection', String, 'Tenant Context Injection',
      hint:
          'SessionVariable | ConnectionString | MiddlewareFilter | RowPolicy — how tenant context is set'),
  Field('tenantIsolationEnforcement', String, 'Tenant Isolation Enforcement',
      hint:
          'DatabaseLevel | ApplicationLevel | Both — where isolation is enforced'),
  Field('crossTenantQueryPrevention', String, 'Cross-Tenant Query Prevention',
      hint:
          'DatabaseRLS | QueryRewriting | GlobalFilter | AllLayers — how cross-tenant queries are blocked'),
  Field('tenantDataBackupIsolation', String, 'Tenant Data Backup Isolation',
      hint:
          'SharedBackup | PerTenantBackup | EncryptedShared — tenant-specific backup strategy'),
  Field('tenantDataDeletion', String, 'Tenant Data Deletion',
      hint:
          'SoftDelete | HardDelete | CryptoShredding — how tenant data is removed on offboarding'),
  Field('tenantDataExport', String, 'Tenant Data Export',
      hint:
          'SelfService | AdminAssisted | ApiExport — data portability for tenants'),
  Field('tenantResourceQuotas', String, 'Tenant Resource Quotas',
      hint:
          'Yes | No — whether storage/query quotas are enforced per tenant'),
  Field('tenantIsolationTesting', String, 'Tenant Isolation Testing',
      hint:
          'AutomatedTests | PenetrationTesting | Both — how tenant isolation is verified'),
  Field('sharedReferenceDataAccess', String, 'Shared Reference Data Access',
      hint:
          'ReadOnly | CachedLocally | Replicated — how tenants access shared/global reference data'),
])
class TenantDataIsolationPolicy {
  String? content;

  /// Tenant Data Isolation Details (text).
  TextSection tenantDataIsolationDetails = TextSection();
}

/// Data masking policy (form).
///
/// Defines how sensitive data is masked or obfuscated for non-production
/// environments, reporting, and limited-access scenarios. Covers both
/// static masking (data copies) and dynamic masking (runtime filtering).
@Form([
  Field('dynamicDataMaskingEnabled', String, 'Dynamic Data Masking Enabled',
      hint:
          'Yes | No — whether dynamic data masking is implemented in production'),
  Field('dynamicMaskingRules', String, 'Dynamic Masking Rules',
      hint:
          'FullMask | PartialMask | Redact | Tokenize — available masking transformations'),
  Field('dynamicMaskingScope', String, 'Dynamic Masking Scope',
      hint:
          'RoleBased | QueryBased | ColumnBased — how masking rules are applied'),
  Field('staticMaskingForNonProduction', String,
      'Static Masking for Non-Production',
      hint:
          'Yes | No — whether production data is statically masked before copying to test/dev'),
  Field('staticMaskingTool', String, 'Static Masking Tool',
      hint:
          'BuiltIn | ThirdParty | CustomScript — tool used for static data masking'),
  Field('maskingPreservesFormat', String, 'Masking Preserves Format',
      hint:
          'Yes | No — whether masked data maintains original format and referential integrity'),
  Field('maskingReversibility', String, 'Masking Reversibility',
      hint:
          'Irreversible | Tokenized | Deterministic — whether masking can be reversed'),
  Field('piiMaskingPolicy', String, 'PII Masking Policy',
      hint:
          'FullRedact | PartialMask | Pseudonymize — specific masking approach for PII fields'),
  Field('emailMaskingFormat', String, 'Email Masking Format',
      hint:
          'e.g., j***@example.com or completely redacted — how email addresses are masked'),
  Field('phoneMaskingFormat', String, 'Phone Masking Format',
      hint:
          'e.g., ***-***-1234 or fully redacted — how phone numbers are masked'),
  Field('addressMaskingFormat', String, 'Address Masking Format',
      hint:
          'CityOnly | ZipCodeOnly | FullRedact — how addresses are masked'),
  Field('financialDataMasking', String, 'Financial Data Masking',
      hint:
          'FullRedact | Last4Digits | Tokenized — how financial data (credit cards, bank accounts) is masked'),
  Field('maskingAuditTrail', String, 'Masking Audit Trail',
      hint:
          'Yes | No — whether masking/unmasking operations are audited'),
  Field('developmentDataStrategy', String, 'Development Data Strategy',
      hint:
          'MaskedCopy | SyntheticData | SubsetExtract | SeedData — strategy for development/test environments'),
])
class DataMaskingPolicy {
  String? content;

  /// Data Masking Details (text).
  TextSection dataMaskingDetails = TextSection();
}

/// Data access audit policy (form).
///
/// Defines how data access events are monitored, logged, and reviewed
/// to detect unauthorized access and support compliance requirements.
@Form([
  Field('dataAccessLoggingEnabled', String, 'Data Access Logging Enabled',
      hint:
          'Yes | No — whether data access events are logged'),
  Field('dataAccessLoggingScope', String, 'Data Access Logging Scope',
      hint:
          'AllTables | SensitiveTablesOnly | ByClassification — which data access is logged'),
  Field('loggedOperations', String, 'Logged Operations',
      hint:
          'Read | Write | Delete | SchemaChange | All — which operations are captured'),
  Field('dataAccessLogDetail', String, 'Data Access Log Detail',
      hint:
          'QueryText | AffectedRows | ColumnAccess | Minimal — what detail is recorded per event'),
  Field('queryTextLogging', String, 'Query Text Logging',
      hint:
          'Full | Sanitized | HashOnly | Disabled — whether executed query text is logged'),
  Field('anomalyDetectionEnabled', String, 'Anomaly Detection Enabled',
      hint:
          'Yes | No — whether unusual data access patterns trigger alerts'),
  Field('anomalySignals', String, 'Anomaly Detection Signals',
      hint:
          'BulkExport | OffHoursAccess | UnusualVolume | NewAccessPattern — signals monitored'),
  Field('dataBreachDetection', String, 'Data Breach Detection',
      hint:
          'RealTime | BatchReview | ThirdPartyDLP — how potential data exfiltration is detected'),
  Field('dataAccessReviewCycle', String, 'Data Access Review Cycle',
      hint:
          'Monthly | Quarterly | Annually — how often data access permissions are reviewed'),
  Field('privilegedQueryAlerts', String, 'Privileged Query Alerts',
      hint:
          'Yes | No — whether queries by privileged accounts trigger real-time alerts'),
  Field('complianceReportingEnabled', String, 'Compliance Reporting Enabled',
      hint:
          'Yes | No — whether automated compliance reports are generated from access logs'),
  Field('dataAccessRetention', String, 'Data Access Log Retention',
      hint:
          'Duration data access logs are retained (e.g., 90d, 1y, 7y)'),
])
class DataAccessAuditPolicy {
  String? content;

  /// Data Access Audit Details (text).
  TextSection dataAccessAuditDetails = TextSection();
}

// ---------------------------------------------------------------------------
// 9.3.2. API Security [PD00-ACC-RES-API]
// ---------------------------------------------------------------------------

/// 9.3.2. API Security [PD00-ACC-RES-API].
///
/// Comprehensive API security specification covering authentication,
/// authorization, request validation, CORS policy, input sanitization,
/// abuse prevention, and security monitoring. Aligned with OWASP API
/// Security Top 10 (2023) and OWASP REST Security Cheat Sheet.
@SectionId('PD00-ACC-RES-API')
class ApiSecurity {
  @Unused()
  String? content;

  /// API Security Overview (text).
  TextSection overview = TextSection();

  /// API Authentication Policy.
  ApiAuthenticationPolicy apiAuthenticationPolicy =
      ApiAuthenticationPolicy();

  /// API Authorization Policy.
  ApiAuthorizationPolicy apiAuthorizationPolicy = ApiAuthorizationPolicy();

  /// API Request Validation Policy.
  ApiRequestValidationPolicy apiRequestValidationPolicy =
      ApiRequestValidationPolicy();

  /// API CORS Security.
  ApiCorsSecurity apiCorsSecurity = ApiCorsSecurity();

  /// API Abuse Protection.
  ApiAbuseProtection apiAbuseProtection = ApiAbuseProtection();

  /// API Security Monitoring.
  ApiSecurityMonitoring apiSecurityMonitoring = ApiSecurityMonitoring();
}

/// API authentication policy — how API consumers prove their identity.
///
/// Covers API keys, OAuth2 flows, JWT validation, mutual TLS, webhook
/// signature verification, and service-to-service authentication.
@Form([
  // Primary authentication mechanism
  Field('authenticationMethod', String, 'Primary Authentication Method',
      required: true,
      hint:
          'OAuth2 | APIKey | JWT | mTLS | HMAC | Basic — primary API authentication mechanism'),
  Field('multipleMethodsSupported', bool, 'Multiple Methods Supported',
      hint:
          'Yes | No — whether the API supports multiple authentication methods simultaneously'),

  // API key management
  Field('apiKeyTransmission', String, 'API Key Transmission',
      hint:
          'Header | QueryParam | Cookie — where API keys are transmitted (Header recommended)'),
  Field('apiKeyRotationPolicy', String, 'API Key Rotation Policy',
      hint:
          'Automatic periodic rotation interval and overlap/grace period for old keys'),
  Field('apiKeyScoping', String, 'API Key Scoping',
      hint:
          'Global | PerEnvironment | PerService — whether keys are scoped to specific environments or services'),

  // OAuth2 / JWT
  Field('jwtValidationPolicy', String, 'JWT Validation Policy',
      hint:
          'iss, aud, exp, nbf — required JWT claims to validate on every request'),
  Field('jwtSigningAlgorithm', String, 'JWT Signing Algorithm',
      hint:
          'RS256 | ES256 | EdDSA — required JWT signing algorithm (HS256 discouraged for APIs)'),
  Field('accessTokenLifetime', String, 'Access Token Lifetime',
      hint:
          'Maximum access token validity duration (e.g. 15 min, 1 hour)'),
  Field('refreshTokenPolicy', String, 'Refresh Token Policy',
      hint:
          'Rotation | Reuse | None — refresh token handling and lifetime'),
  Field('clientCredentialsFlow', bool, 'Client Credentials Flow',
      hint:
          'Yes | No — whether OAuth2 client credentials flow is supported for service-to-service'),
  Field('authorizationCodeFlow', bool, 'Authorization Code Flow',
      hint:
          'Yes | No — whether OAuth2 authorization code flow with PKCE is supported'),
  Field('tokenRevocationSupport', bool, 'Token Revocation Support',
      hint:
          'Yes | No — whether explicit token revocation is supported (RFC 7009)'),

  // Service-to-service and mutual TLS
  Field('mutualTlsRequired', bool, 'Mutual TLS Required',
      hint:
          'Yes | No — require client certificate authentication for service-to-service communication'),
  Field('serviceAccountPolicy', String, 'Service Account Policy',
      hint:
          'How service accounts authenticate and what credential types they use'),

  // Webhook and third-party
  Field('webhookSignatureVerification', String,
      'Webhook Signature Verification',
      hint:
          'HMAC-SHA256 | RSA | EdDSA — method used to verify incoming webhook requests'),
  Field('thirdPartyApiConsumption', String,
      'Third-Party API Consumption Security',
      hint:
          'Security requirements when consuming external third-party APIs (OWASP API10)'),
  Field('credentialTransmission', String, 'Credential Transmission',
      hint:
          'Header | Body — where credentials are transmitted (Header via Authorization recommended)'),
  Field('bearerTokenFormat', String, 'Bearer Token Format',
      hint: 'JWT | Opaque | Reference — format used for bearer tokens'),
  Field('notes', String, 'Notes',
      hint: 'Additional API authentication notes'),
])
class ApiAuthenticationPolicy {
  String? content;

  /// API Authentication Details (text).
  TextSection apiAuthenticationDetails = TextSection();
}

/// API authorization policy — how API access decisions are made.
///
/// Covers object-level, function-level, and property-level authorization,
/// scope definitions, delegation controls, and protection against privilege
/// escalation. Aligned with OWASP API1/API3/API5 (Broken Authorization).
@Form([
  // Authorization granularity
  Field('objectLevelAuthorization', String, 'Object-Level Authorization',
      required: true,
      hint:
          'How every API endpoint verifies the caller owns or may access the requested object (OWASP API1)'),
  Field('functionLevelAuthorization', String, 'Function-Level Authorization',
      hint:
          'How administrative vs. regular functions are separated and access-controlled (OWASP API5)'),
  Field(
      'propertyLevelAuthorization', String, 'Property-Level Authorization',
      hint:
          'How field-level exposure is controlled — preventing excessive data exposure and mass assignment (OWASP API3)'),
  Field('permissionGranularity', String, 'Permission Granularity',
      hint:
          'Endpoint | Resource | Field — granularity at which permissions are evaluated'),

  // Scopes and delegation
  Field('scopeDefinitions', String, 'OAuth2 Scope Definitions',
      hint:
          'OAuth2 scopes required for API access (e.g. read:users, write:orders)'),
  Field('scopeEnforcementLevel', String, 'Scope Enforcement Level',
      hint:
          'Gateway | Service | Both — where scope checks are enforced'),
  Field('delegatedAccessPolicy', String, 'Delegated Access Policy',
      hint:
          'How delegation or impersonation is controlled (on-behalf-of flows)'),

  // Bulk and batch operations
  Field(
      'bulkOperationAuthorization', String, 'Bulk Operation Authorization',
      hint:
          'How batch/bulk API operations are authorized — per-item or at collection level'),
  Field('contextualAuthorization', String, 'Contextual Authorization',
      hint:
          'IP, time-of-day, device, or geolocation-based access decisions'),

  // Escalation prevention
  Field('massAssignmentPrevention', String, 'Mass Assignment Prevention',
      hint:
          'How mass assignment attacks are prevented — allowlisted fields, DTOs, read-only markers'),
  Field('horizontalPrivilegeEscalation', String,
      'Horizontal Privilege Escalation Prevention',
      hint:
          'Controls preventing a user from accessing another user\'s data via direct object reference'),
  Field('verticalPrivilegeEscalation', String,
      'Vertical Privilege Escalation Prevention',
      hint:
          'Controls preventing regular users from accessing administrative functions'),

  // Business flow protection
  Field('sensitiveBusinessFlowProtection', String,
      'Sensitive Business Flow Protection',
      hint:
          'How sensitive workflows (checkout, transfer) are protected from automated abuse (OWASP API6)'),
  Field('workflowStateValidation', String, 'Workflow State Validation',
      hint:
          'How out-of-order API execution is prevented (server-side state machine enforcement)'),
  Field('notes', String, 'Notes',
      hint: 'Additional API authorization notes'),
])
class ApiAuthorizationPolicy {
  String? content;

  /// API Authorization Details (text).
  TextSection apiAuthorizationDetails = TextSection();
}

/// API request validation policy — input validation, schema enforcement,
/// and content type verification for all API requests.
///
/// Covers schema validation, parameter typing, size limits, content type
/// enforcement, and structured payload validation. Aligned with OWASP
/// Input Validation Cheat Sheet.
@Form([
  // Validation approach
  Field('inputValidationStrategy', String, 'Input Validation Strategy',
      required: true,
      hint:
          'Allowlist | Blocklist | SchemaValidation — primary validation approach (Allowlist recommended)'),
  Field('schemaValidationEnforced', bool, 'Schema Validation Enforced',
      hint:
          'Yes | No — whether JSON Schema or OpenAPI schema validation is enforced on all requests'),
  Field('schemaValidationTool', String, 'Schema Validation Tool',
      hint:
          'Library or framework used for request schema validation'),

  // Content type
  Field('contentTypeValidation', bool, 'Content-Type Validation',
      hint:
          'Yes | No — whether Content-Type header is validated against expected types'),
  Field('acceptedContentTypes', String, 'Accepted Content Types',
      hint:
          'application/json | application/xml — comma-separated list of accepted content types'),
  Field('rejectUnexpectedContentType', bool, 'Reject Unexpected Content-Type',
      hint:
          'Yes | No — respond with HTTP 415 for unsupported media types'),

  // Size and depth limits
  Field('requestSizeLimit', String, 'Request Size Limit',
      hint:
          'Maximum request body size (e.g. 1 MB, 10 MB) — reject with HTTP 413'),
  Field('arrayLengthLimit', int, 'Array Length Limit',
      hint:
          'Maximum number of elements allowed in any JSON array in request body'),
  Field('nestedObjectDepthLimit', int, 'Nested Object Depth Limit',
      hint:
          'Maximum nesting depth for JSON objects to prevent DoS via deep nesting'),
  Field('stringFieldMaxLength', int, 'String Field Max Length',
      hint:
          'Default maximum character length for string fields unless overridden per field'),

  // Parameter and type enforcement
  Field('parameterTypeEnforcement', bool, 'Parameter Type Enforcement',
      hint:
          'Yes | No — enforce strong typing (number, boolean, date) on query/path parameters'),
  Field('numericRangeValidation', bool, 'Numeric Range Validation',
      hint:
          'Yes | No — enforce min/max bounds on numeric parameters'),
  Field('dateFormatValidation', String, 'Date Format Validation',
      hint:
          'ISO 8601 | RFC 3339 | Custom — required date/time format for all date fields'),
  Field('encodingValidation', String, 'Encoding Validation',
      hint:
          'UTF-8 | ASCII — accepted character encoding for request bodies'),

  // File uploads
  Field('fileUploadValidation', String, 'File Upload Validation',
      hint:
          'Allowed extensions, MIME types, max file size, and content scanning requirements'),
  Field('notes', String, 'Notes',
      hint: 'Additional request validation notes'),
])
class ApiRequestValidationPolicy {
  String? content;

  /// Request Validation Details (text).
  TextSection requestValidationDetails = TextSection();
}

/// API CORS security — Cross-Origin Resource Sharing policy from a security
/// perspective.
///
/// Defines allowed origins, methods, headers, credential handling, and
/// security headers returned with API responses. Aligned with OWASP CORS
/// guidance and Content Security Policy best practices.
@Form([
  // CORS core
  Field('corsEnabled', bool, 'CORS Enabled',
      required: true,
      hint:
          'Yes | No — whether CORS is enabled for the API'),
  Field('allowedOrigins', String, 'Allowed Origins',
      hint:
          'Explicit domain list or pattern — avoid wildcard * with credentials'),
  Field('allowedMethods', String, 'Allowed HTTP Methods',
      hint:
          'GET | POST | PUT | DELETE | PATCH — permitted HTTP methods'),
  Field('allowedHeaders', String, 'Allowed Request Headers',
      hint:
          'Authorization, Content-Type, X-Request-ID — allowed request headers'),
  Field('exposedHeaders', String, 'Exposed Response Headers',
      hint:
          'X-RateLimit-Remaining, X-Request-ID — response headers visible to client JavaScript'),
  Field('credentialsAllowed', bool, 'Credentials Allowed',
      hint:
          'Yes | No — Access-Control-Allow-Credentials (mutually exclusive with wildcard origin)'),
  Field('preflightCacheMaxAge', int, 'Preflight Cache Max-Age',
      hint:
          'Maximum time in seconds that preflight responses can be cached (e.g. 3600)'),
  Field('wildcardRestriction', bool, 'Wildcard Restriction',
      hint:
          'Yes | No — whether wildcard * origin is explicitly prohibited when credentials are used'),

  // Security headers
  Field('contentSecurityPolicy', String, 'Content Security Policy',
      hint:
          'CSP directives for API responses (e.g. default-src none, frame-ancestors none)'),
  Field('strictTransportSecurity', String, 'Strict Transport Security',
      hint:
          'HSTS max-age and includeSubDomains directive for API endpoints'),
  Field('securityHeadersRequired', String, 'Required Security Headers',
      hint:
          'X-Content-Type-Options: nosniff, X-Frame-Options: DENY, Referrer-Policy: no-referrer'),
  Field('privateNetworkAccess', String, 'Private Network Access Policy',
      hint:
          'How CORS private network access requests are handled (Access-Control-Request-Private-Network)'),
  Field('notes', String, 'Notes',
      hint: 'Additional CORS security notes'),
])
class ApiCorsSecurity {
  String? content;

  /// CORS Security Details (text).
  TextSection corsSecurityDetails = TextSection();
}

/// API abuse protection — rate limiting, bot detection, brute force
/// prevention, and business flow protection from a security perspective.
///
/// Focuses on the security policy aspects of abuse prevention. Complements
/// rate-limiting configuration in the technical framework with security-
/// specific rules and threat response actions.
@Form([
  // Rate limiting security
  Field('rateLimitingEnabled', bool, 'Rate Limiting Enabled',
      required: true,
      hint:
          'Yes | No — whether security-focused rate limiting is enforced'),
  Field('rateLimitScope', String, 'Rate Limit Scope',
      hint:
          'PerClient | PerEndpoint | PerTenant | Global — at what level limits are applied'),
  Field('authenticationEndpointLimits', String,
      'Authentication Endpoint Limits',
      hint:
          'Stricter rate limits for login/token endpoints to prevent brute-force attacks'),
  Field('sensitiveEndpointLimits', String, 'Sensitive Endpoint Limits',
      hint:
          'Additional rate limits for password reset, MFA enrolment, payment endpoints'),

  // Brute force and bot protection
  Field('bruteForceProtection', String, 'Brute Force Protection',
      hint:
          'Account lockout, progressive delays, CAPTCHA — how brute force authentication attacks are mitigated'),
  Field('botDetectionPolicy', String, 'Bot Detection Policy',
      hint:
          'CAPTCHA | BehavioralAnalysis | DeviceFingerprint | None — automated request detection'),
  Field('ipReputationFiltering', bool, 'IP Reputation Filtering',
      hint:
          'Yes | No — use IP reputation databases to filter known-malicious sources'),

  // Threat response
  Field('automaticBlocking', bool, 'Automatic Blocking',
      hint:
          'Yes | No — automatically block clients exceeding abuse thresholds'),
  Field('blockDuration', String, 'Block Duration',
      hint:
          'Temporary (minutes/hours) or permanent — duration of automatic blocks'),
  Field('geographicRestrictions', String, 'Geographic Restrictions',
      hint:
          'Region or country-based access restrictions for API endpoints'),
  Field('requestThrottlingOnFailure', String,
      'Request Throttling on Failure',
      hint:
          'Progressive delay or backoff on repeated authentication or validation failures'),

  // Business flow protection
  Field('businessFlowProtection', String, 'Business Flow Protection',
      hint:
          'How automated abuse of business-critical flows is detected and prevented (OWASP API6)'),
  Field('webhookFloodProtection', String, 'Webhook Flood Protection',
      hint:
          'How webhook replay attacks and flood scenarios are prevented'),
  Field('notes', String, 'Notes',
      hint: 'Additional abuse protection notes'),
])
class ApiAbuseProtection {
  String? content;

  /// Abuse Protection Details (text).
  TextSection abuseProtectionDetails = TextSection();
}

/// API security monitoring — logging, anomaly detection, inventory
/// management, and compliance reporting for API security.
///
/// Covers API access logging, error monitoring, authentication failure
/// tracking, deprecated endpoint usage, and data exfiltration detection.
/// Aligned with OWASP API9 (Improper Inventory Management) and OWASP
/// API10 (Unsafe Consumption of APIs).
@Form([
  // Logging
  Field('apiAccessLogging', bool, 'API Access Logging',
      required: true,
      hint:
          'Yes | No — whether all API access is logged with caller identity and action'),
  Field('loggedAttributes', String, 'Logged Request Attributes',
      hint:
          'Timestamp, clientId, endpoint, method, statusCode, responseTime, sourceIP — attributes captured per request'),
  Field('sensitiveEndpointMonitoring', bool, 'Sensitive Endpoint Monitoring',
      hint:
          'Yes | No — enhanced logging for authentication, payment, and admin endpoints'),
  Field('sensitiveDataRedaction', bool, 'Sensitive Data Redaction',
      hint:
          'Yes | No — redact PII, credentials, and tokens from API logs'),

  // Anomaly detection
  Field('anomalyDetection', bool, 'Anomaly Detection',
      hint:
          'Yes | No — detect anomalous API usage patterns (unusual volume, timing, geography)'),
  Field('errorRateMonitoring', String, 'Error Rate Monitoring',
      hint:
          'Threshold and window for error-rate alerting (e.g. >5% 4xx in 5-min window)'),
  Field('authenticationFailureTracking', bool,
      'Authentication Failure Tracking',
      hint:
          'Yes | No — track and alert on authentication failure patterns per client/IP'),
  Field('dataExfiltrationDetection', bool, 'Data Exfiltration Detection',
      hint:
          'Yes | No — detect unusual data volume patterns that may indicate exfiltration'),

  // Inventory and versioning
  Field('apiVersionInventory', bool, 'API Version Inventory',
      hint:
          'Yes | No — maintain a current inventory of all API versions and endpoints (OWASP API9)'),
  Field('deprecatedEndpointMonitoring', bool,
      'Deprecated Endpoint Monitoring',
      hint:
          'Yes | No — monitor and alert on usage of deprecated API endpoints or versions'),

  // Alerts and response
  Field('realTimeAlerts', bool, 'Real-Time Alerts',
      hint:
          'Yes | No — trigger real-time security alerts on threshold breaches'),
  Field('securityResponseAutomation', String,
      'Security Response Automation',
      hint:
          'Automated actions on security events — block, throttle, escalate, notify'),
  Field('complianceReporting', String, 'Compliance Reporting',
      hint:
          'Frequency and format of API security compliance reports'),
  Field('notes', String, 'Notes',
      hint: 'Additional API security monitoring notes'),
])
class ApiSecurityMonitoring {
  String? content;

  /// API Security Monitoring Details (text).
  TextSection apiSecurityMonitoringDetails = TextSection();
}

// ---------------------------------------------------------------------------
// 9.3.3. File and Storage Security [PD00-ACC-RES-FIL]
// ---------------------------------------------------------------------------

/// 9.3.3. File and Storage Security [PD00-ACC-RES-FIL].
///
/// Comprehensive file and storage security specification covering upload
/// validation, storage encryption, access control on file resources, content
/// scanning, download protection, and storage lifecycle management.
/// Aligned with OWASP File Upload Cheat Sheet and defense-in-depth principles.
@SectionId('PD00-ACC-RES-FIL')
class FileAndStorageSecurity {
  @Unused()
  String? content;

  /// File and Storage Security Overview (text).
  TextSection overview = TextSection();

  /// File Upload Validation Policy.
  FileUploadValidationPolicy fileUploadValidationPolicy =
      FileUploadValidationPolicy();

  /// Storage Encryption Policy.
  StorageEncryptionPolicy storageEncryptionPolicy =
      StorageEncryptionPolicy();

  /// File Access Control Policy.
  FileAccessControlPolicy fileAccessControlPolicy =
      FileAccessControlPolicy();

  /// Content Scanning Policy.
  ContentScanningPolicy contentScanningPolicy = ContentScanningPolicy();

  /// File Download Security Policy.
  FileDownloadSecurityPolicy fileDownloadSecurityPolicy =
      FileDownloadSecurityPolicy();

  /// Storage Lifecycle Policy.
  StorageLifecyclePolicy storageLifecyclePolicy = StorageLifecyclePolicy();
}

/// File upload validation policy — how uploaded files are validated before
/// acceptance.
///
/// Covers extension validation, content-type verification, file signature
/// validation, filename safety, size limits, and structural validation.
/// Aligned with OWASP File Upload Cheat Sheet defense-in-depth approach.
@Form([
  // Extension validation
  Field('extensionValidationStrategy', String,
      'Extension Validation Strategy',
      required: true,
      hint:
          'Allowlist | Blocklist | Both — approach to file extension validation (Allowlist recommended)'),
  Field('allowedFileExtensions', String, 'Allowed File Extensions',
      hint:
          'Comma-separated list of permitted extensions (e.g. jpg, png, pdf, docx)'),
  Field('blockedFileExtensions', String, 'Blocked File Extensions',
      hint:
          'Comma-separated list of explicitly blocked extensions (e.g. exe, bat, sh, php, js)'),
  Field('doubleExtensionPrevention', bool, 'Double Extension Prevention',
      hint:
          'Yes | No — prevent bypass via double extensions like .jpg.php'),

  // Content-type and signature
  Field('contentTypeValidation', bool, 'Content-Type Validation',
      hint:
          'Yes | No — validate MIME type from Content-Type header against allowed types'),
  Field('fileSignatureValidation', bool, 'File Signature (Magic Byte) Validation',
      hint:
          'Yes | No — validate file magic bytes match the declared content type'),
  Field('signatureMismatchAction', String, 'Signature Mismatch Action',
      hint:
          'Reject | Quarantine | Log — action when file signature does not match extension'),

  // Filename safety
  Field('filenameStrategy', String, 'Filename Strategy',
      hint:
          'GenerateUUID | SanitizeOriginal | Preserve — how filenames are handled on upload'),
  Field('filenameMaxLength', int, 'Filename Max Length',
      hint:
          'Maximum allowed filename length in characters'),
  Field('filenameAllowedCharacters', String, 'Filename Allowed Characters',
      hint:
          'Alphanumeric, hyphen, underscore, period — allowed characters in filenames'),
  Field('pathTraversalPrevention', bool, 'Path Traversal Prevention',
      hint:
          'Yes | No — strip or reject path components (../, /) in filenames'),
  Field('nullBytePrevention', bool, 'Null Byte Prevention',
      hint:
          'Yes | No — reject filenames containing null bytes (%00)'),

  // Size limits
  Field('maxFileSizeBytes', String, 'Max File Size',
      hint:
          'Maximum individual file size (e.g. 10 MB, 50 MB, 1 GB)'),
  Field('maxUploadBatchSize', String, 'Max Upload Batch Size',
      hint:
          'Maximum total size for multi-file uploads in a single request'),
  Field('maxConcurrentUploads', int, 'Max Concurrent Uploads',
      hint:
          'Maximum number of simultaneous file uploads per user'),
  Field('compressedFileSizeLimit', String, 'Compressed File Size Limit',
      hint:
          'Maximum decompressed size for ZIP/archive files to prevent ZIP bombs'),

  // Structural validation
  Field('imageRewriting', bool, 'Image Rewriting',
      hint:
          'Yes | No — rewrite/re-encode images to strip embedded metadata and malicious payloads'),
  Field('documentSanitization', bool, 'Document Sanitization',
      hint:
          'Yes | No — apply Content Disarm & Reconstruct (CDR) to office documents and PDFs'),
  Field('metadataStripping', bool, 'Metadata Stripping',
      hint:
          'Yes | No — remove EXIF, XMP, and other embedded metadata from uploaded files'),
  Field('notes', String, 'Notes',
      hint: 'Additional file upload validation notes'),
])
class FileUploadValidationPolicy {
  String? content;

  /// Upload Validation Details (text).
  TextSection uploadValidationDetails = TextSection();
}

/// Storage encryption policy — how files and storage volumes are encrypted
/// at rest and in transit to/from storage.
///
/// Covers server-side encryption, client-side encryption, key management
/// for file storage, and encryption scope for different storage tiers.
@Form([
  // Encryption at rest
  Field('encryptionAtRest', bool, 'Encryption at Rest',
      required: true,
      hint:
          'Yes | No — whether stored files are encrypted at rest'),
  Field('encryptionAlgorithm', String, 'Encryption Algorithm',
      hint:
          'AES-256-GCM | AES-256-CBC | ChaCha20-Poly1305 — algorithm for file encryption'),
  Field('encryptionScope', String, 'Encryption Scope',
      hint:
          'Volume | Bucket | PerFile | PerTenant — granularity at which encryption keys are applied'),
  Field('serverSideEncryption', String, 'Server-Side Encryption',
      hint:
          'SSE-S3 | SSE-KMS | SSE-C | ManagedKey — server-side encryption method'),
  Field('clientSideEncryption', bool, 'Client-Side Encryption',
      hint:
          'Yes | No — whether files are encrypted before upload by the client'),
  Field('clientSideEncryptionMethod', String, 'Client-Side Encryption Method',
      hint:
          'Envelope encryption, client-managed keys — method for client-side encryption'),

  // Key management for files
  Field('fileKeyRotation', String, 'File Encryption Key Rotation',
      hint:
          'Frequency and method of rotating file encryption keys'),
  Field('perTenantKeys', bool, 'Per-Tenant Encryption Keys',
      hint:
          'Yes | No — whether each tenant has its own encryption key for file storage'),
  Field('keyDeletionOnTenantRemoval', bool, 'Key Deletion on Tenant Removal',
      hint:
          'Yes | No — whether tenant file encryption keys are destroyed when tenant is deleted'),

  // Transit encryption
  Field('encryptionInTransit', bool, 'Encryption in Transit',
      hint:
          'Yes | No — TLS for file upload/download transport'),
  Field('minimumTlsVersion', String, 'Minimum TLS Version for File Transfer',
      hint:
          'TLS 1.2 | TLS 1.3 — minimum TLS version for file transfers'),

  // Backup encryption
  Field('backupEncryption', bool, 'Backup Encryption',
      hint:
          'Yes | No — whether file storage backups are encrypted with the same or separate keys'),
  Field('notes', String, 'Notes',
      hint: 'Additional storage encryption notes'),
])
class StorageEncryptionPolicy {
  String? content;

  /// Storage Encryption Details (text).
  TextSection storageEncryptionDetails = TextSection();
}

/// File access control policy — who can access, modify, share, and delete
/// files, and how access decisions are enforced.
///
/// Covers authentication requirements, authorization model, sharing controls,
/// storage location isolation, filesystem permissions, and temporary access.
@Form([
  // Access model
  Field('fileAccessModel', String, 'File Access Model',
      required: true,
      hint:
          'OwnerBased | RoleBased | ACL | Capability — how file access permissions are determined'),
  Field('authenticationRequired', bool, 'Authentication Required',
      hint:
          'Yes | No — whether authentication is required for all file access'),
  Field('anonymousDownloadAllowed', bool, 'Anonymous Download Allowed',
      hint:
          'Yes | No — whether any files can be downloaded without authentication (public files)'),
  Field('fileOwnershipModel', String, 'File Ownership Model',
      hint:
          'User | Tenant | SharedOwnership — who owns uploaded files by default'),

  // Permission granularity
  Field('permissionGranularity', String, 'Permission Granularity',
      hint:
          'Read | Write | Delete | Share | Admin — permission types supported on files'),
  Field('folderLevelPermissions', bool, 'Folder-Level Permissions',
      hint:
          'Yes | No — whether permissions can be set at folder/directory level with inheritance'),
  Field('permissionInheritance', String, 'Permission Inheritance',
      hint:
          'Inherit | Override | None — how folder permissions propagate to contained files'),

  // Sharing controls
  Field('sharingEnabled', bool, 'Sharing Enabled',
      hint:
          'Yes | No — whether files can be shared with other users or externally'),
  Field('shareableLinkSupport', bool, 'Shareable Link Support',
      hint:
          'Yes | No — support for time-limited or password-protected shareable URLs'),
  Field('shareableLinkExpiration', String, 'Shareable Link Default Expiration',
      hint:
          'Default expiration time for shareable links (e.g. 24 hours, 7 days, never)'),
  Field('externalSharingPolicy', String, 'External Sharing Policy',
      hint:
          'Allowed | RestrictedDomains | Disabled — whether files can be shared outside the tenant'),

  // Storage isolation
  Field('storageLocationPolicy', String, 'Storage Location Policy',
      hint:
          'SeparateServer | OutsideWebroot | CloudBucket — where files are stored relative to application'),
  Field('tenantStorageIsolation', String, 'Tenant Storage Isolation',
      hint:
          'SeparateBucket | PrefixPartition | SharedWithACL — how tenant files are isolated in storage'),
  Field('filesystemPermissions', String, 'Filesystem Permissions',
      hint:
          'Least-privilege file permission policy (read-only for web server, write for upload service)'),

  // Temporary and pre-signed access
  Field('presignedUrlSupport', bool, 'Pre-signed URL Support',
      hint:
          'Yes | No — use pre-signed URLs for time-limited direct file access'),
  Field('presignedUrlMaxExpiry', String, 'Pre-signed URL Max Expiry',
      hint:
          'Maximum validity period for pre-signed URLs (e.g. 15 min, 1 hour)'),
  Field('notes', String, 'Notes',
      hint: 'Additional file access control notes'),
])
class FileAccessControlPolicy {
  String? content;

  /// File Access Control Details (text).
  TextSection fileAccessControlDetails = TextSection();
}

/// Content scanning policy — how uploaded and stored files are scanned for
/// malicious content, policy violations, and compliance risks.
///
/// Covers antivirus scanning, malware detection, content disarm and
/// reconstruct (CDR), data loss prevention, and content moderation.
@Form([
  // Antivirus and malware
  Field('antivirusScanningEnabled', bool, 'Antivirus Scanning Enabled',
      required: true,
      hint:
          'Yes | No — whether uploaded files are scanned by antivirus before acceptance'),
  Field('scanTiming', String, 'Scan Timing',
      hint:
          'OnUpload | Asynchronous | OnAccess | Periodic — when scanning occurs'),
  Field('scanEngine', String, 'Scan Engine',
      hint:
          'ClamAV | CloudProvider | ThirdPartyAPI | Multiple — scanning engine or service used'),
  Field('quarantinePolicy', String, 'Quarantine Policy',
      hint:
          'Quarantine | Reject | NotifyAndQuarantine — action when malicious content is detected'),
  Field('quarantineRetentionDays', int, 'Quarantine Retention Days',
      hint:
          'Number of days quarantined files are retained before permanent deletion'),
  Field('signatureUpdateFrequency', String, 'Signature Update Frequency',
      hint:
          'Hourly | Daily | RealTime — how often antivirus signatures are updated'),

  // Content Disarm and Reconstruct
  Field('cdrEnabled', bool, 'CDR (Content Disarm & Reconstruct) Enabled',
      hint:
          'Yes | No — whether CDR is applied to office documents, PDFs, and similar file types'),
  Field('cdrApplicableTypes', String, 'CDR Applicable File Types',
      hint:
          'PDF | DOCX | XLSX | Images — file types processed by CDR'),

  // Data loss prevention
  Field('dlpScanningEnabled', bool, 'DLP Scanning Enabled',
      hint:
          'Yes | No — scan file contents for sensitive data (PII, credit cards, health records)'),
  Field('dlpPolicies', String, 'DLP Policies',
      hint:
          'Regex patterns, trained classifiers, keyword lists — methods for detecting sensitive data in files'),
  Field('dlpAction', String, 'DLP Action on Detection',
      hint:
          'Block | Redact | Notify | Quarantine — action when DLP detects sensitive content'),

  // Content moderation
  Field('contentModeration', bool, 'Content Moderation',
      hint:
          'Yes | No — scan for illegal, offensive, or policy-violating content'),
  Field('moderationMethod', String, 'Moderation Method',
      hint:
          'Automated | ManualReview | Hybrid — approach to content moderation'),
  Field('hashBasedDetection', bool, 'Hash-Based Detection',
      hint:
          'Yes | No — use file hash databases (e.g. VirusTotal) to detect known-malicious files'),
  Field('notes', String, 'Notes',
      hint: 'Additional content scanning notes'),
])
class ContentScanningPolicy {
  String? content;

  /// Content Scanning Details (text).
  TextSection contentScanningDetails = TextSection();
}

/// File download security policy — how file downloads are protected,
/// including rate limiting, access logging, and content disposition.
///
/// Covers download authentication, bandwidth protection, content disposition
/// headers, hot-link prevention, and download audit logging.
@Form([
  // Download protection
  Field('downloadAuthenticationRequired', bool,
      'Download Authentication Required',
      required: true,
      hint:
          'Yes | No — whether authentication is required for file downloads'),
  Field('downloadRateLimiting', bool, 'Download Rate Limiting',
      hint:
          'Yes | No — rate limit file downloads per user/IP to prevent DoS'),
  Field('downloadRateLimit', String, 'Download Rate Limit',
      hint:
          'Maximum downloads per minute/hour/day per user or IP'),
  Field('bandwidthThrottling', bool, 'Bandwidth Throttling',
      hint:
          'Yes | No — throttle download bandwidth per user to prevent abuse'),

  // Content disposition and delivery
  Field('contentDispositionPolicy', String, 'Content-Disposition Policy',
      hint:
          'Attachment | Inline | PerType — how Content-Disposition header is set (Attachment recommended for untrusted content)'),
  Field('cdnDelivery', bool, 'CDN Delivery',
      hint:
          'Yes | No — serve files through a CDN for performance and DDoS protection'),
  Field('hotlinkPrevention', bool, 'Hotlink Prevention',
      hint:
          'Yes | No — prevent direct linking to files from external sites'),
  Field('cacheControlPolicy', String, 'Cache-Control Policy',
      hint:
          'NoStore | Private | PublicShortTTL — cache directives for file download responses'),

  // Audit and tracking
  Field('downloadAuditLogging', bool, 'Download Audit Logging',
      hint:
          'Yes | No — log all file download events with user, timestamp, file, and IP'),
  Field('downloadAlerts', bool, 'Download Alerts',
      hint:
          'Yes | No — alert on unusual download patterns (bulk downloads, sensitive files)'),
  Field('watermarking', bool, 'File Watermarking',
      hint:
          'Yes | No — apply invisible watermarks to downloaded files for traceability'),
  Field('notes', String, 'Notes',
      hint: 'Additional file download security notes'),
])
class FileDownloadSecurityPolicy {
  String? content;

  /// Download Security Details (text).
  TextSection downloadSecurityDetails = TextSection();
}

/// Storage lifecycle policy — retention, archiving, versioning, and
/// secure deletion of stored files.
///
/// Covers retention rules, archival tiers, versioning, backup schedules,
/// secure deletion methods, and compliance-driven retention requirements.
@Form([
  // Retention
  Field('retentionPolicy', String, 'Retention Policy',
      required: true,
      hint:
          'TimeBased | Indefinite | ComplianceDriven — default file retention strategy'),
  Field('defaultRetentionPeriod', String, 'Default Retention Period',
      hint:
          'Default duration files are kept before eligible for deletion (e.g. 90 days, 7 years)'),
  Field('retentionByFileType', bool, 'Retention by File Type',
      hint:
          'Yes | No — different retention periods for different file categories'),
  Field('legalHoldSupport', bool, 'Legal Hold Support',
      hint:
          'Yes | No — ability to place legal holds preventing deletion regardless of retention policy'),

  // Archiving
  Field('archivingEnabled', bool, 'Archiving Enabled',
      hint:
          'Yes | No — whether files are moved to low-cost archival tiers after a defined period'),
  Field('archivalStorageTier', String, 'Archival Storage Tier',
      hint:
          'Glacier | ColdStorage | NearlineStorage — target tier for archived files'),
  Field('archivalTransitionDays', int, 'Archival Transition Days',
      hint:
          'Number of days after last access before files move to archival storage'),

  // Versioning
  Field('versioningEnabled', bool, 'File Versioning Enabled',
      hint:
          'Yes | No — maintain previous versions of overwritten or modified files'),
  Field('maxVersions', int, 'Max Versions Retained',
      hint:
          'Maximum number of previous versions to retain per file'),
  Field('versionRetentionDays', int, 'Version Retention Days',
      hint:
          'Number of days previous versions are retained'),

  // Backup
  Field('backupSchedule', String, 'Backup Schedule',
      hint:
          'Daily | Hourly | Continuous — frequency of file storage backups'),
  Field('backupRetentionDays', int, 'Backup Retention Days',
      hint:
          'Number of days file backups are retained'),
  Field('crossRegionReplication', bool, 'Cross-Region Replication',
      hint:
          'Yes | No — replicate file storage to a secondary region for disaster recovery'),

  // Secure deletion
  Field('secureDeletionMethod', String, 'Secure Deletion Method',
      hint:
          'CryptoShred | Overwrite | StandardDelete — method for permanent file deletion'),
  Field('deletionConfirmation', bool, 'Deletion Confirmation Required',
      hint:
          'Yes | No — require explicit confirmation or approval for permanent file deletion'),
  Field('deletionAuditLogging', bool, 'Deletion Audit Logging',
      hint:
          'Yes | No — log all file deletion events for compliance and forensics'),
  Field('notes', String, 'Notes',
      hint: 'Additional storage lifecycle notes'),
])
class StorageLifecyclePolicy {
  String? content;

  /// Storage Lifecycle Details (text).
  TextSection storageLifecycleDetails = TextSection();
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
