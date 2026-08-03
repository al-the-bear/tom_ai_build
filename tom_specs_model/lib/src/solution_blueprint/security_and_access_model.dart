/// Section 9: Security & Access Model. Seeds → SAS.
///
/// Application security for data and functions.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 9. Security & Access Model. Seeds → SAS.
@StandardReferences(
  [
    'ISO/IEC 24760 — IAM: a framework for identity management',
    'ISO/IEC 27001:2022 — control A.5.16 identity management',
    'SOC 2 — CC6.1 through CC6.3 logical access controls',
  ],
  'Provides the high-level overview of application security for protecting data and functions.',
)
@SectionId('SAAM')
@Comment('Seeds → SAS')
@MapsTo(D08SecurityAccessSpecification)
class SecurityAndAccessModel extends DocSpecsSection {
  @ContentHelp('''
Provide a high-level overview of the application's security architecture for
protecting data and functions. This section serves as the entry point for all
access and authorization concerns.

**Key topics to address:**
- Overall security philosophy (zero trust, defense in depth, least privilege)
- Applicable security frameworks (NIST, ISO 27001, SOC 2, OWASP)
- Regulatory requirements affecting access control (GDPR, HIPAA, PCI DSS)
- Integration points with enterprise identity and access management (IAM)
- Risk-based approach to authorization decisions

**Cross-references:**
- User Management → defines who accesses the system
- Authentication → proves user identity
- Authorization → controls what authenticated users can do
- Resource Protection → secures data and APIs
- Encryption → protects sensitive data
- Audit → logs security events for compliance
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.1. Access Control Model — the CE-AZ CodeSpecs subtree.
  @SerializationOrder(1)
  AccessControlModel accessControl = AccessControlModel();

  /// 9.2. Audit and Logging — the CE-LG / CE-CF CodeSpecs subtree.
  @SerializationOrder(2)
  AuditAndLogging auditAndLogging = AuditAndLogging();

  /// 9.3. Security Operations — OPS follow-up subtree.
  @SerializationOrder(3)
  SecurityOperationsFollowUp securityOperations = SecurityOperationsFollowUp();

  /// 9.4. Compliance — CMP follow-up subtree.
  @SerializationOrder(4)
  SecurityComplianceFollowUp compliance = SecurityComplianceFollowUp();
}

/// SBP.12 Security & Access — Access Control Model (CE-AZ CodeSpecs subtree).
///
/// Groups the five access-control concerns that CodeSpecs consumes as the CE-AZ
/// authorization seed (`codespecs_mapping.md` §8.3): user management,
/// authentication, resource protection, authorization, and the role matrix.
/// The container itself carries no `@CodeSpecKind` — the mapped parts live on
/// the child sections (e.g. `authentication`) — but the whole subtree is the
/// CodeSpecs-relevant portion, kept separate from the OPS/CMP follow-up
/// subtrees.
@StandardReferences(
  [
    'ISO/IEC 24760 — IAM: a framework for identity management',
    'ISO/IEC 27001:2022 — control A.5.16 identity management',
    'SOC 2 — CC6.1 through CC6.3 logical access controls',
  ],
  'The CE-AZ access-control seed: user management, authentication, resource '
  'protection, authorization, and the role matrix.',
)
@SectionId('ACCM')
class AccessControlModel extends DocSpecsSection {
  @ContentType('description', 'Summarize the access-control model: identities, '
      'authentication, resource protection, authorization, and roles.')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.1.1. User Management.
  @SerializationOrder(1)
  UserManagement userManagement = UserManagement();

  /// 9.1.2. Identification and Authentication.
  @SerializationOrder(2)
  IdentificationAndAuthentication authentication =
      IdentificationAndAuthentication();

  /// 9.1.3. Resource Protection.
  @SerializationOrder(3)
  ResourceProtection resourceProtection = ResourceProtection();

  /// 9.1.4. User Authorization.
  @SerializationOrder(4)
  UserAuthorization authorization = UserAuthorization();

  /// 9.1.5. Role Matrix.
  @SerializationOrder(5)
  RoleMatrix roleMatrix = RoleMatrix();
}

/// SBP.12 Security & Access — Security Operations (OPS follow-up subtree).
///
/// Groups the operational security concerns that are **follow-up** (key
/// management and the routines run *against* the audit log), not
/// CodeSpecs-generated behaviour (`codespecs_mapping.md` §8.3). Carries no
/// `@CodeSpecKind` — the whole subtree is generation-owned-out.
///
/// The audit log's *declarations* are not here: which events are auditable and
/// how the sink is configured are the CE-LG / CE-CF bands, which live in the
/// sibling `AuditAndLogging` CodeSpecs subtree. What remains operational is
/// `ComplianceReporting` — periodic access review, privilege-usage reporting,
/// anomaly detection and regulatory audit support are processes people run, not
/// code a generator emits.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — A.8.24 use of cryptography, A.8.15 logging',
    'NIST SP 800-57 — key management',
  ],
  'The OPS follow-up: sensitive-data encryption (key management) and the '
  'reporting / review routines run against the audit log, consumed '
  'operationally rather than generated.',
)
@FollowUpKind([FollowUpProcess.ops])
@SectionId('SCOF')
class SecurityOperationsFollowUp extends DocSpecsSection {
  @ContentType('description', 'Summarize the operational security follow-up: '
      'encryption / key management and audit review / reporting routines.')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.3.1. Sensitive Data Encryption.
  @SerializationOrder(1)
  SensitiveDataEncryption encryption = SensitiveDataEncryption();

  /// 9.3.2. Compliance Reporting.
  @SerializationOrder(2)
  ComplianceReporting complianceReporting = ComplianceReporting();
}

/// SBP.12 Security & Access — Compliance (CMP follow-up subtree).
///
/// Groups the compliance-framework concern, a **follow-up** (compliance
/// governance) rather than CodeSpecs-generated behaviour
/// (`codespecs_mapping.md` §8.3). Carries no `@CodeSpecKind` — the whole
/// subtree is generation-owned-out.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — information security management',
    'SOC 2 — trust services criteria',
  ],
  'The CMP follow-up: the compliance framework governing regulatory and audit '
  'obligations, consumed as compliance documentation rather than generated.',
)
@FollowUpKind([FollowUpProcess.cmp])
@SectionId('SCCF')
class SecurityComplianceFollowUp extends DocSpecsSection {
  @ContentType('description', 'Summarize the compliance follow-up: the '
      'regulatory and audit compliance framework.')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.3.1. Compliance Framework.
  @SerializationOrder(1)
  ComplianceFramework complianceFramework = ComplianceFramework();
}

/// 9.1. User Management.
@StandardReferences(
  [
    'ISO/IEC 24760 — IAM: a framework for identity management',
    'NIST SP 800-63A — enrollment and identity proofing',
    'SOC 2 — CC6.1 through CC6.3 logical access controls',
  ],
  'Describes how users are organized, categorized, and managed across their relationship with the system.',
)
@SectionId('USMGT')
@DetailedIn(D08SecurityAccessSpecification)
@CodeSpecKind([CodeSpecPart.identity],
    note: 'CE-ID — identity: app-declared identity-attribute extensions over '
        'the fixed principal core (users, groups, service principals).')
class UserManagement extends DocSpecsSection {
  @ContentHelp('''
Describe how users are organized, categorized, and managed throughout their
relationship with the system. This section establishes the foundation for
authentication and authorization by defining who the users are.

**Key topics to address:**
- User taxonomy (employees, customers, partners, service accounts)
- User provisioning sources (self-registration, admin-created, SCIM, HR sync)
- User directory integration (LDAP, Active Directory, cloud identity providers)
- Account lifecycle governance and oversight responsibilities
- User metadata and attribute management strategy

**Industry context:**
- NIST SP 800-63A covers identity proofing requirements
- SCIM 2.0 (RFC 7643/7644) for cross-domain user management
- SOC 2 CC6.1-CC6.3 for logical and physical access controls
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.1.1. User Categories.
  @SerializationOrder(1)
  AccessUserCategories userCategories = AccessUserCategories();

  /// 9.1.2. User Lifecycle.
  @SerializationOrder(2)
  UserLifecycle userLifecycle = UserLifecycle();

  /// 9.1.3. User Attributes.
  @SerializationOrder(3)
  UserAttributes userAttributes = UserAttributes();
}

/// 9.1.1. User Categories.
@StandardReferences(
  [
    'ISO/IEC 24760 — IAM: a framework for identity management',
    'NIST SP 800-63A — enrollment and identity proofing',
    'SOC 2 — CC6.1 through CC6.3 logical access controls',
  ],
  'Defines the distinct categories of users who interact with the system and their trust levels.',
)
@SectionId('AUSCT')
@CodeSpecKind([CodeSpecPart.identity])
class AccessUserCategories extends DocSpecsSection {
  @ContentHelp('''
Define the distinct categories of users who interact with the system. Each
category should reflect different trust levels, access patterns, and business
relationships.

**Typical user categories include:**
- **End Users / Customers** — external users with limited, self-service access
- **Internal Employees** — staff with role-based access to business functions
- **Administrators** — privileged users managing system configuration
- **Partners / B2B Users** — external parties with contractual access
- **Service Accounts** — non-human identities for automation and integrations
- **Support / Helpdesk** — staff with elevated access for user assistance
- **Auditors** — read-only access for compliance and review

**For each category, document:**
- Estimated user count and growth projections
- Authentication requirements (MFA, SSO, certificates)
- Typical access patterns and session duration
- Onboarding and offboarding processes
- Data sensitivity level accessible by this category
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× UserCategoryDefinition.
  @StandardReferences([
    'ISO/IEC 24760 — IAM: a framework for identity management',
  ], 'The catalog of user category definitions.')
  @SectionId('USCDF-ITEM-LST')
  @SectionIdPattern('USCDF-ITEM-xxx')
  @ContentHelp('Add one entry per user-category definition.')
  @SerializationOrder(1)
  List<UserCategoryDefinition> items = [];
}

/// A user category definition (form).
@StandardReferences(
  [
    'ISO/IEC 24760 — IAM: a framework for identity management',
    'NIST SP 800-63A — enrollment and identity proofing',
  ],
  'Defines a single user category together with its access level and estimated population.',
)
@SectionId('USCDF')
@CodeSpecKind([CodeSpecPart.identity])
class UserCategoryDefinition extends DocSpecsSection {
  @Form([
    Field(
      'categoryName',
      String,
      'Category Name',
      required: true,
      hint: 'Name of the user category.',
    ),
    Field(
      'description',
      String,
      'Short description',
      hint: 'Brief description of this category.',
    ),
    Field(
      'accessLevel',
      String,
      'Access Level',
      hint: 'Typical access level for this category.',
    ),
    Field(
      'estimatedCount',
      String,
      'Estimated Count',
      hint: 'Estimated number of users in this category.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 9.1.2. User Lifecycle.
///
/// Defines the complete user account lifecycle: states, transitions between
/// states, approval requirements for each transition, and operational policies
/// for registration, activation, modification, deactivation, and deletion.
@StandardReferences(
  [
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    'NIST SP 800-63A — enrollment and identity proofing',
    'ISO/IEC 27001:2022 — control A.5.18 access rights',
  ],
  'Defines the complete user account lifecycle from creation through permanent deletion.',
)
@SectionId('USLCS')
@CodeSpecKind([CodeSpecPart.identity])
class UserLifecycle extends DocSpecsSection {
  @ContentHelp('''
Document the complete lifecycle of user accounts from creation to permanent
deletion. A well-defined lifecycle ensures proper access control, auditability,
and compliance with data retention requirements.

**Lifecycle phases:**
1. **Registration** — how users request or receive accounts
2. **Activation** — approval workflows and initial credential issuance
3. **Active Usage** — ongoing access and periodic re-verification
4. **Modification** — attribute updates, role changes, transfers
5. **Suspension** — temporary disablement (leave, investigation)
6. **Deactivation** — permanent disablement (termination, contract end)
7. **Deletion** — data removal per retention policies

**Key considerations:**
- Joiner-mover-leaver (JML) process integration with HR systems
- Self-service vs. admin-driven operations
- Approval workflows and segregation of duties
- Grace periods and notification requirements
- Compliance with GDPR right to erasure and data retention laws
- Audit trail requirements for lifecycle events
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview (text).
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// 9.1.2.1. Account States.
  @SerializationOrder(2)
  UserAccountStatesDefinition accountStates = UserAccountStatesDefinition();

  /// 9.1.2.2. Registration Process.
  @SerializationOrder(3)
  UserRegistrationProcess registration = UserRegistrationProcess();

  /// 9.1.2.3. Account Activation.
  @SerializationOrder(4)
  AccountActivationPolicy activation = AccountActivationPolicy();

  /// 9.1.2.4. Account Modification.
  @SerializationOrder(5)
  AccountModificationPolicy modification = AccountModificationPolicy();

  /// 9.1.2.5. Account Deactivation.
  @SerializationOrder(6)
  AccountDeactivationPolicy deactivation = AccountDeactivationPolicy();

  /// 9.1.2.6. Account Deletion and Data Retention.
  @SerializationOrder(7)
  AccountDeletionPolicy deletion = AccountDeletionPolicy();

  /// 9.1.2.7. Lifecycle Transitions and Approvals.
  @SerializationOrder(8)
  UserLifecycleTransitions transitions = UserLifecycleTransitions();

  /// 9.1.2.8. Self-Service Account Management.
  @SerializationOrder(9)
  SelfServiceAccountManagement selfService = SelfServiceAccountManagement();

  /// 9.1.2.9. Service Account Lifecycle.
  @StandardReferences([
    'ISO/IEC 24760 — IAM: a framework for identity management',
  ], 'The catalog of service account lifecycle entries.')
  @SectionId('SACLC-SERV-LST')
  @SectionIdPattern('SACLC-SERV-xxx')
  @ContentHelp('Add one entry per service-account lifecycle entry.')
  @SerializationOrder(10)
  List<ServiceAccountLifecycle> serviceAccounts = [];
}

/// 9.1.2.1. Account States (form).
///
/// Defines the possible states a user account can be in throughout its
/// lifecycle, from provisional creation to permanent deletion.
@Form([
  Field(
    'stateModel',
    String,
    'State Model Type',
    hint: 'Linear | Graph | Hierarchical — how states relate to each other',
  ),
  Field(
    'initialState',
    String,
    'Initial State',
    hint: 'State assigned at account creation (e.g., Pending Verification)',
  ),
  Field(
    'activeState',
    String,
    'Active State',
    hint: 'Fully operational account state name',
  ),
  Field(
    'suspendedState',
    String,
    'Suspended State',
    hint: 'Temporarily restricted state name',
  ),
  Field(
    'lockedState',
    String,
    'Locked State',
    hint: 'Account locked due to security policy (e.g., failed logins)',
  ),
  Field(
    'deactivatedState',
    String,
    'Deactivated State',
    hint: 'Administratively disabled, recoverable',
  ),
  Field(
    'archivedState',
    String,
    'Archived State',
    hint: 'Read-only historical state before permanent deletion',
  ),
  Field(
    'deletedState',
    String,
    'Deleted State',
    hint: 'Permanently removed or anonymized',
  ),
  Field(
    'customStates',
    String,
    'Custom States',
    hint: 'Additional project-specific states (comma-separated)',
  ),
  Field(
    'stateVisibility',
    String,
    'State Visibility',
    hint: 'Which states are visible to the user vs. admin-only',
  ),
  Field(
    'stateTransitionDiagramRef',
    String,
    'State Transition Diagram Reference',
    hint: 'Reference to a state transition diagram (mermaid or external)',
  ),
])
@StandardReferences(
  [
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    'ISO/IEC 27001:2022 — control A.5.18 access rights',
  ],
  'Defines the possible states a user account can be in throughout its lifecycle.',
)
@SectionId('UACST')
@CodeSpecKind([CodeSpecPart.identity])
class UserAccountStatesDefinition extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// State Transition Diagram (mermaid).
  @SerializationOrder(1)
  DiagramSection stateTransitionDiagram = DiagramSection();
}

/// 9.1.2.2. Registration Process (form).
///
/// Defines how new user accounts are created — self-registration, invitation,
/// admin-provisioned, or bulk import — including identity proofing requirements.
@Form([
  Field(
    'registrationMethods',
    String,
    'Registration Methods',
    hint:
        'SelfRegistration | Invitation | AdminProvisioned | BulkImport | ExternalIdP',
  ),
  Field(
    'selfRegistrationEnabled',
    String,
    'Self-Registration Enabled',
    hint: 'Yes | No | PerCategory — whether users can self-register',
  ),
  Field(
    'identityProofingLevel',
    String,
    'Identity Proofing Level',
    hint:
        'None | Email | Phone | Document | InPerson — per NIST SP 800-63A IAL',
  ),
  Field(
    'emailVerificationRequired',
    String,
    'Email Verification Required',
    hint: 'Yes | No | Optional',
  ),
  Field(
    'phoneVerificationRequired',
    String,
    'Phone Verification Required',
    hint: 'Yes | No | Optional',
  ),
  Field(
    'captchaRequired',
    String,
    'CAPTCHA Required',
    hint: 'Yes | No — bot prevention during self-registration',
  ),
  Field(
    'invitationExpiryPeriod',
    String,
    'Invitation Expiry Period',
    hint: 'Duration before invitation link expires (e.g., 48h, 7d)',
  ),
  Field(
    'approvalRequired',
    String,
    'Approval Required',
    hint: 'Yes | No — whether registration needs manual approval',
  ),
  Field(
    'approvalWorkflow',
    String,
    'Approval Workflow',
    hint: 'Single Approver | Multi-Level | Auto-Approved — workflow type',
  ),
  Field(
    'approverRole',
    String,
    'Approver Role',
    hint: 'Role or person who approves new registrations',
  ),
  Field(
    'requiredFieldsAtRegistration',
    String,
    'Required Fields at Registration',
    hint: 'Comma-separated list of mandatory fields during signup',
  ),
  Field(
    'optionalFieldsAtRegistration',
    String,
    'Optional Fields at Registration',
    hint: 'Comma-separated list of optional fields during signup',
  ),
  Field(
    'termsAcceptanceRequired',
    String,
    'Terms Acceptance Required',
    hint: 'Yes | No — must accept terms of service / privacy policy',
  ),
  Field(
    'duplicateDetection',
    String,
    'Duplicate Detection',
    hint: 'How duplicate accounts are detected (email, phone, name matching)',
  ),
  Field(
    'welcomeNotification',
    String,
    'Welcome Notification',
    hint:
        'Email | SMS | InApp | None — notification on successful registration',
  ),
  Field(
    'initialRoleAssignment',
    String,
    'Initial Role Assignment',
    hint: 'Default role(s) assigned at registration',
  ),
  Field(
    'registrationRateLimiting',
    String,
    'Registration Rate Limiting',
    hint: 'Max registrations per IP/time window to prevent abuse',
  ),
])
@StandardReferences(
  [
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    'NIST SP 800-63A — enrollment and identity proofing',
    'ISO/IEC 27001:2022 — control A.5.18 access rights',
  ],
  'Defines how new user accounts are created, including registration methods and identity proofing requirements.',
)
@SectionId('URREG')
@CodeSpecKind([CodeSpecPart.identity])
class UserRegistrationProcess extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Registration Flow Description (text).
  @SerializationOrder(1)
  TextSection registrationFlowDescription = TextSection();

  /// Registration Flow Diagram (mermaid-sequence).
  @SerializationOrder(2)
  SequenceDiagramSection registrationFlowDiagram = SequenceDiagramSection();
}

/// 9.1.2.3. Account Activation (form).
///
/// Defines the steps required to move a newly registered account from pending
/// to active status, including verification, approval, and provisioning.
@Form([
  Field(
    'activationMethod',
    String,
    'Activation Method',
    hint:
        'EmailLink | AdminApproval | Automatic | PhoneVerification | Combined',
  ),
  Field(
    'activationLinkExpiry',
    String,
    'Activation Link Expiry',
    hint: 'Duration before activation link expires (e.g., 24h)',
  ),
  Field(
    'maxActivationAttempts',
    int,
    'Max Activation Attempts',
    hint: 'Number of times user can request re-activation',
  ),
  Field(
    'activationPrerequisites',
    String,
    'Activation Prerequisites',
    hint:
        'Conditions that must be met before activation (e.g., email verified, approved)',
  ),
  Field(
    'provisioningOnActivation',
    String,
    'Provisioning on Activation',
    hint:
        'Resources provisioned when account becomes active (workspace, storage, etc.)',
  ),
  Field(
    'activationNotification',
    String,
    'Activation Notification',
    hint: 'Channels notified on activation (email, SMS, admin alert)',
  ),
  Field(
    'activationTimeout',
    String,
    'Activation Timeout',
    hint: 'Time after which unactivated accounts are purged or flagged',
  ),
  Field(
    'activationTimeoutAction',
    String,
    'Activation Timeout Action',
    hint: 'Delete | Flag | Remind | Escalate — action on timeout',
  ),
  Field(
    'postActivationRedirect',
    String,
    'Post-Activation Redirect',
    hint:
        'Where the user is directed after activation (dashboard, onboarding wizard)',
  ),
  Field(
    'onboardingRequired',
    String,
    'Onboarding Required',
    hint: 'Yes | No — whether guided onboarding follows activation',
  ),
  Field(
    'onboardingSteps',
    String,
    'Onboarding Steps',
    hint:
        'Steps in onboarding flow (profile completion, tutorial, preference setup)',
  ),
])
@StandardReferences(
  [
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    'NIST SP 800-63A — enrollment and identity proofing',
    'ISO/IEC 27001:2022 — control A.5.18 access rights',
  ],
  'Defines the steps to move a newly registered account from pending to active status.',
)
@SectionId('ACACT')
@CodeSpecKind([CodeSpecPart.identity])
class AccountActivationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Activation Flow Description (text).
  @SerializationOrder(1)
  TextSection activationFlowDescription = TextSection();
}

/// 9.1.2.4. Account Modification (form).
///
/// Defines what user account attributes can be changed, by whom, under what
/// conditions, and what re-verification is needed after changes.
@Form([
  Field(
    'selfModifiableFields',
    String,
    'Self-Modifiable Fields',
    hint:
        'Fields the user can change themselves (display name, avatar, preferences)',
  ),
  Field(
    'adminModifiableFields',
    String,
    'Admin-Modifiable Fields',
    hint:
        'Fields only an administrator can change (role, status, organization)',
  ),
  Field(
    'systemModifiableFields',
    String,
    'System-Modifiable Fields',
    hint: 'Fields updated automatically (last login, login count, risk score)',
  ),
  Field(
    'emailChangePolicy',
    String,
    'Email Change Policy',
    hint:
        'Re-verification required | Admin approval | Confirmation to old+new email',
  ),
  Field(
    'phoneChangePolicy',
    String,
    'Phone Change Policy',
    hint: 'Verification via old number | Admin approval',
  ),
  Field(
    'nameChangePolicy',
    String,
    'Name Change Policy',
    hint: 'Self-service | RequiresVerification | AdminOnly',
  ),
  Field(
    'roleChangeApproval',
    String,
    'Role Change Approval',
    hint:
        'Who approves role changes (manager, admin, auto-approved for certain changes)',
  ),
  Field(
    'bulkModificationSupport',
    String,
    'Bulk Modification Support',
    hint: 'Yes | No — whether batch attribute updates are supported',
  ),
  Field(
    'changeAuditLogging',
    String,
    'Change Audit Logging',
    hint: 'All changes | SensitiveOnly | None — audit trail granularity',
  ),
  Field(
    'changeNotification',
    String,
    'Change Notification',
    hint: 'User | Admin | Both | None — who receives notification of changes',
  ),
  Field(
    'historicalVersioning',
    String,
    'Historical Versioning',
    hint: 'Yes | No — whether previous attribute values are preserved',
  ),
  Field(
    'reverificationTriggers',
    String,
    'Re-verification Triggers',
    hint:
        'Which changes trigger re-verification (email, password, security question)',
  ),
  Field(
    'modificationRateLimiting',
    String,
    'Modification Rate Limiting',
    hint:
        'Limits on how frequently attributes can be changed (e.g., email max 1/30d)',
  ),
  Field(
    'modificationCooldownPeriod',
    String,
    'Modification Cooldown Period',
    hint: 'Waiting period after sensitive changes before full access resumes',
  ),
])
@StandardReferences(
  [
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    'ISO/IEC 27001:2022 — control A.5.18 access rights',
  ],
  'Defines which account attributes can be changed, by whom, and what re-verification is required after changes.',
)
@SectionId('ACMOD')
@CodeSpecKind([CodeSpecPart.identity])
class AccountModificationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Modification Rules Description (text).
  @SerializationOrder(1)
  TextSection modificationRulesDescription = TextSection();
}

/// 9.1.2.5. Account Deactivation (form).
///
/// Defines temporary or permanent disabling of user accounts — reasons, effects,
/// reactivation conditions, and the difference between suspension and deactivation.
@Form([
  Field(
    'deactivationTriggers',
    String,
    'Deactivation Triggers',
    hint:
        'Manual | Inactivity | PolicyViolation | ContractEnd | SecurityIncident',
  ),
  Field(
    'inactivityThreshold',
    String,
    'Inactivity Threshold',
    hint:
        'Period of inactivity before automatic deactivation (e.g., 90d, 180d)',
  ),
  Field(
    'inactivityWarningPeriod',
    String,
    'Inactivity Warning Period',
    hint:
        'Advance notice before deactivation (e.g., warn 14d before deactivation)',
  ),
  Field(
    'deactivationApproval',
    String,
    'Deactivation Approval',
    hint: 'Who can deactivate accounts (admin, manager, system, self)',
  ),
  Field(
    'immediateDeactivationCases',
    String,
    'Immediate Deactivation Cases',
    hint:
        'Cases where deactivation is immediate without warning (security breach, termination)',
  ),
  Field(
    'deactivatedAccountAccess',
    String,
    'Deactivated Account Data Access',
    hint: 'Whether deactivated account data remains accessible to admins',
  ),
  Field(
    'deactivationEffects',
    String,
    'Deactivation Effects',
    hint: 'LoginBlocked | ApiKeysRevoked | SessionsTerminated | DataPreserved',
  ),
  Field(
    'reactivationPolicy',
    String,
    'Reactivation Policy',
    hint:
        'UserRequest | AdminOnly | AutoOnLogin | NotAllowed — how accounts are reactivated',
  ),
  Field(
    'reactivationApproval',
    String,
    'Reactivation Approval',
    hint: 'Who approves reactivation (original approver, admin, manager)',
  ),
  Field(
    'reactivationReverification',
    String,
    'Reactivation Re-verification',
    hint:
        'PasswordReset | MFA | IdentityProofing — verification at reactivation',
  ),
  Field(
    'maxDeactivationPeriod',
    String,
    'Max Deactivation Period',
    hint:
        'Maximum time an account can stay deactivated before escalation to deletion',
  ),
  Field(
    'deactivationNotification',
    String,
    'Deactivation Notification',
    hint: 'User | Admin | Manager | All — channels notified on deactivation',
  ),
  Field(
    'gracePeriodAfterDeactivation',
    String,
    'Grace Period After Deactivation',
    hint: 'Window during which deactivation is easily reversible',
  ),
  Field(
    'dataPreservationDuration',
    String,
    'Data Preservation Duration',
    hint:
        'How long deactivated account data is preserved (30d, 1y, indefinitely)',
  ),
])
@StandardReferences(
  [
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    'ISO/IEC 27001:2022 — control A.5.18 access rights',
  ],
  'Defines temporary or permanent disabling of user accounts, their effects, and reactivation conditions.',
)
@SectionId('ACDEA')
@CodeSpecKind([CodeSpecPart.identity])
class AccountDeactivationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Deactivation Process Description (text).
  @SerializationOrder(1)
  TextSection deactivationProcessDescription = TextSection();
}

/// 9.1.2.6. Account Deletion and Data Retention (form).
///
/// Defines permanent account removal, data anonymization, data retention
/// obligations, and right-to-be-forgotten compliance.
@Form([
  Field(
    'deletionTriggers',
    String,
    'Deletion Triggers',
    hint: 'UserRequest | RetentionExpiry | AdminDecision | RegulatoryOrder',
  ),
  Field(
    'deletionApproval',
    String,
    'Deletion Approval',
    hint:
        'Who approves deletion (admin, data protection officer, auto-approved)',
  ),
  Field(
    'softDeleteEnabled',
    String,
    'Soft Delete Enabled',
    hint: 'Yes | No — whether accounts are soft-deleted before hard deletion',
  ),
  Field(
    'softDeleteRetention',
    String,
    'Soft Delete Retention Period',
    hint:
        'Duration in soft-deleted state before permanent removal (e.g., 30d, 90d)',
  ),
  Field(
    'permanentDeletionProcess',
    String,
    'Permanent Deletion Process',
    hint:
        'Anonymize | Purge | Archive — what happens to data on permanent deletion',
  ),
  Field(
    'dataAnonymizationStrategy',
    String,
    'Data Anonymization Strategy',
    hint:
        'Fields anonymized, pseudonymization method, referential integrity handling',
  ),
  Field(
    'retainedDataAfterDeletion',
    String,
    'Retained Data After Deletion',
    hint: 'Data kept for legal/audit reasons (transaction logs, audit trails)',
  ),
  Field(
    'retentionPeriodAfterDeletion',
    String,
    'Retention Period After Deletion',
    hint: 'How long retained data is kept post-deletion',
  ),
  Field(
    'dataExportBeforeDeletion',
    String,
    'Data Export Before Deletion',
    hint: 'Yes | No — whether users can export their data before deletion',
  ),
  Field(
    'exportFormats',
    String,
    'Export Formats',
    hint: 'JSON | CSV | XML | PDF — formats for data export',
  ),
  Field(
    'cascadeDeletionBehavior',
    String,
    'Cascade Deletion Behavior',
    hint:
        'What happens to associated content (posts, files, records) on user deletion',
  ),
  Field(
    'deletionConfirmation',
    String,
    'Deletion Confirmation',
    hint:
        'PasswordEntry | EmailConfirmation | WaitingPeriod — confirmation method',
  ),
  Field(
    'deletionNotification',
    String,
    'Deletion Notification',
    hint: 'User | Admin | DPO | All — who is notified on deletion',
  ),
  Field(
    'rightToErasureCompliance',
    String,
    'Right to Erasure Compliance',
    hint:
        'GDPR Art.17 | CCPA | None — applicable right-to-be-forgotten regulations',
  ),
  Field(
    'erasureResponseTime',
    String,
    'Erasure Response Time',
    hint: 'Maximum time to fulfill an erasure request (e.g., 30 days per GDPR)',
  ),
  Field(
    'thirdPartyDataDeletion',
    String,
    'Third-Party Data Deletion',
    hint: 'How data shared with third parties is removed or anonymized',
  ),
])
@StandardReferences(
  [
    'GDPR — Article 17 right to erasure',
    'ISO/IEC 27555 — deletion of personally identifiable information',
  ],
  'Defines permanent account removal, data anonymization, retention obligations, and right-to-be-forgotten compliance.',
)
@SectionId('ACDEL')
@CodeSpecKind([CodeSpecPart.identity])
class AccountDeletionPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Deletion Process Description (text).
  @SerializationOrder(1)
  TextSection deletionProcessDescription = TextSection();
}

/// 9.1.2.7. Lifecycle Transitions and Approvals (form).
///
/// Defines the permissible transitions between lifecycle states, who can trigger
/// each transition, and the approval workflow required.
@Form([
  Field(
    'transitionModel',
    String,
    'Transition Model',
    hint: 'StateMachine | Workflow | Hybrid — how transitions are modeled',
  ),
  Field(
    'approvalPolicyDefault',
    String,
    'Default Approval Policy',
    hint:
        'SingleApprover | DualControl | AutoApproved — default for all transitions',
  ),
  Field(
    'escalationPolicy',
    String,
    'Escalation Policy',
    hint:
        'What happens if approval is not granted within SLA (auto-deny, escalate, remind)',
  ),
  Field(
    'escalationTimeframe',
    String,
    'Escalation Timeframe',
    hint: 'Time before pending approval is escalated (e.g., 48h)',
  ),
  Field(
    'auditTrailRequired',
    String,
    'Audit Trail Required',
    hint: 'Yes | No — whether every transition is logged',
  ),
  Field(
    'notificationOnTransition',
    String,
    'Notification on Transition',
    hint: 'User | Approver | Admin | All — who is notified on state change',
  ),
  Field(
    'bulkTransitionSupport',
    String,
    'Bulk Transition Support',
    hint: 'Yes | No — whether multiple accounts can transition at once',
  ),
  Field(
    'automatedTransitions',
    String,
    'Automated Transitions',
    hint:
        'Transitions triggered automatically (inactivity → deactivated, expiry → deleted)',
  ),
  Field(
    'transitionUndoPolicy',
    String,
    'Transition Undo Policy',
    hint: 'Which transitions are reversible and within what time window',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.18 access rights',
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
  ],
  'Defines the permissible transitions between lifecycle states and the approval workflow each transition requires.',
)
@SectionId('ULTRS')
@CodeSpecKind([CodeSpecPart.identity])
class UserLifecycleTransitions extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Transition Rules Description (text).
  @SerializationOrder(1)
  TextSection transitionRulesDescription = TextSection();

  /// Lifecycle State Transition Diagram (mermaid).
  @SerializationOrder(2)
  DiagramSection lifecycleStateDiagram = DiagramSection();

  /// Contains 0+× UserLifecycleTransitionEntry.
  @StandardReferences([
    'ISO/IEC 27001:2022 — control A.5.18 access rights',
  ], 'The catalog of user lifecycle transition entries.')
  @SectionId('ULTRE-ITEM-LST')
  @SectionIdPattern('ULTRE-ITEM-xxx')
  @ContentHelp('Add one entry per user-lifecycle transition entry.')
  @SerializationOrder(3)
  List<UserLifecycleTransitionEntry> items = [];
}

/// A lifecycle transition entry (form).
///
/// Defines a single permissible transition between two lifecycle states,
/// including trigger, approval, and side effects.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.18 access rights',
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
  ],
  'Defines a single permissible transition between two lifecycle states, including its trigger and approval.',
)
@SectionId('ULTRE')
@CodeSpecKind([CodeSpecPart.identity])
class UserLifecycleTransitionEntry extends DocSpecsSection {
  @Form([
    Field(
      'transitionName',
      String,
      'Transition Name',
      required: true,
      hint: 'Descriptive name (e.g., "Activate Account", "Suspend User")',
    ),
    Field(
      'fromState',
      String,
      'From State',
      required: true,
      hint: 'Source lifecycle state',
    ),
    Field(
      'toState',
      String,
      'To State',
      required: true,
      hint: 'Target lifecycle state',
    ),
    Field(
      'trigger',
      String,
      'Trigger',
      hint: 'UserRequest | AdminAction | SystemEvent | ScheduledJob',
    ),
    Field(
      'triggerConditions',
      String,
      'Trigger Conditions',
      hint: 'Pre-conditions that must be met for this transition',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Approval requirements.
  @SectionId('ULTAP')
  @StandardReferences(
    [
      'ISO/IEC 27001:2022 — control A.5.18 access rights',
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    ],
    'Defines the approval requirements and approver role for a lifecycle transition.',
  )
  @Form([
    Field(
      'approvalRequired',
      String,
      'Approval Required',
      hint: 'Yes | No — whether manual approval is needed',
    ),
    Field(
      'approverRole',
      String,
      'Approver Role',
      hint: 'Role that must approve (admin, manager, DPO)',
    ),
    Field(
      'approvalSla',
      String,
      'Approval SLA',
      hint: 'Maximum time allowed for approval decision',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? approval;

  /// Side effects and notifications.
  @SectionId('ULTEF')
  @StandardReferences(
    [
      'ISO/IEC 27001:2022 — control A.5.18 access rights',
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    ],
    'Defines the side effects performed and the notifications sent when a lifecycle transition occurs.',
  )
  @Form([
    Field(
      'sideEffects',
      String,
      'Side Effects',
      hint:
          'Actions performed on transition (revoke tokens, send email, deprovision)',
    ),
    Field(
      'notificationRecipients',
      String,
      'Notification Recipients',
      hint: 'Who is notified (user, admin, manager)',
    ),
    Field(
      'notificationChannels',
      String,
      'Notification Channels',
      hint: 'Email | SMS | InApp | Webhook',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? effects;

  /// Reversal and automation.
  @SectionId('ULTAU')
  @StandardReferences(
    [
      'ISO/IEC 27001:2022 — control A.5.18 access rights',
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    ],
    'Defines whether a lifecycle transition can be reversed and whether it can be automated.',
  )
  @Form([
    Field(
      'reversible',
      String,
      'Reversible',
      hint: 'Yes | No — whether this transition can be undone',
    ),
    Field(
      'reverseTransitionName',
      String,
      'Reverse Transition Name',
      hint: 'Name of the reverse transition if applicable',
    ),
    Field(
      'automationSupported',
      String,
      'Automation Supported',
      hint: 'Yes | No — whether this transition can be automated',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? automation;
}

/// 9.1.2.8. Self-Service Account Management (form).
///
/// Defines what lifecycle actions users can perform on their own accounts
/// without administrator involvement.
@Form([
  Field(
    'profileUpdateEnabled',
    String,
    'Profile Update Enabled',
    hint: 'Yes | No — users can update their own profile information',
  ),
  Field(
    'passwordChangeEnabled',
    String,
    'Password Change Enabled',
    hint: 'Yes | No — users can change their own password',
  ),
  Field(
    'passwordResetEnabled',
    String,
    'Password Reset Enabled',
    hint: 'Yes | No — users can reset forgotten passwords',
  ),
  Field(
    'passwordResetMethods',
    String,
    'Password Reset Methods',
    hint: 'Email | SMS | SecurityQuestions | AdminAssisted',
  ),
  Field(
    'mfaEnrollmentSelfService',
    String,
    'MFA Enrollment Self-Service',
    hint: 'Yes | No — users can enroll/change MFA devices',
  ),
  Field(
    'accountDeactivationSelfService',
    String,
    'Account Deactivation Self-Service',
    hint: 'Yes | No — users can deactivate their own account',
  ),
  Field(
    'accountDeletionSelfService',
    String,
    'Account Deletion Self-Service',
    hint: 'Yes | No — users can request deletion of their own account',
  ),
  Field(
    'dataExportSelfService',
    String,
    'Data Export Self-Service',
    hint: 'Yes | No — users can export their own data',
  ),
  Field(
    'sessionManagementSelfService',
    String,
    'Session Management Self-Service',
    hint: 'Yes | No — users can view and terminate their active sessions',
  ),
  Field(
    'apiKeyManagementSelfService',
    String,
    'API Key Management Self-Service',
    hint: 'Yes | No — users can create/revoke their own API keys',
  ),
  Field(
    'notificationPreferences',
    String,
    'Notification Preferences',
    hint: 'Yes | No — users can configure their notification preferences',
  ),
  Field(
    'delegationEnabled',
    String,
    'Delegation Enabled',
    hint: 'Yes | No — users can delegate account actions to another user',
  ),
  Field(
    'delegationScope',
    String,
    'Delegation Scope',
    hint: 'What actions can be delegated (read, write, approve)',
  ),
  Field(
    'accountRecoveryProcess',
    String,
    'Account Recovery Process',
    hint:
        'Steps when a user loses all credentials (identity re-proofing, admin reset)',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63A — enrollment and identity proofing',
    'ISO/IEC 24760 — IAM: a framework for identity management',
  ],
  'Defines the lifecycle actions users can perform on their own accounts without administrator involvement.',
)
@SectionId('SSACM')
@CodeSpecKind([CodeSpecPart.identity])
class SelfServiceAccountManagement extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Self-Service Capabilities Description (text).
  @SerializationOrder(1)
  TextSection selfServiceDescription = TextSection();
}

/// 9.1.2.9. Service Account Lifecycle (form).
///
/// Defines lifecycle management for non-human accounts — APIs, bots, system
/// integrations — which have different lifecycle rules than human users.
@Form([
  Field(
    'serviceAccountTypes',
    String,
    'Service Account Types',
    hint:
        'API Client | Bot | SystemIntegration | ScheduledJob | DeviceIdentity',
  ),
  Field(
    'creationProcess',
    String,
    'Creation Process',
    hint:
        'How service accounts are created (admin, DevOps pipeline, self-service)',
  ),
  Field(
    'creationApproval',
    String,
    'Creation Approval',
    hint: 'Who approves service account creation (security team, admin)',
  ),
  Field(
    'ownerAssignment',
    String,
    'Owner Assignment',
    hint: 'Yes | No — whether each service account must have a human owner',
  ),
  Field(
    'ownerReviewFrequency',
    String,
    'Owner Review Frequency',
    hint:
        'How often owners must recertify service accounts (quarterly, annually)',
  ),
  Field(
    'credentialRotationPolicy',
    String,
    'Credential Rotation Policy',
    hint: 'How often credentials (keys, secrets, certificates) must be rotated',
  ),
  Field(
    'credentialStorageMethod',
    String,
    'Credential Storage Method',
    hint: 'VaultService | EnvironmentVariable | SecretManager | HSM',
  ),
  Field(
    'scopeLimitation',
    String,
    'Scope Limitation',
    hint:
        'Principle of least privilege — minimum permissions for service accounts',
  ),
  Field(
    'ipRestriction',
    String,
    'IP Restriction',
    hint: 'Yes | No — whether service accounts are restricted to specific IPs',
  ),
  Field(
    'expirationPolicy',
    String,
    'Expiration Policy',
    hint:
        'Whether service accounts expire and after how long (e.g., 1y, never)',
  ),
  Field(
    'renewalProcess',
    String,
    'Renewal Process',
    hint: 'Steps to renew an expiring service account',
  ),
  Field(
    'decommissioningProcess',
    String,
    'Decommissioning Process',
    hint: 'How service accounts are retired (revoke, archive, delete)',
  ),
  Field(
    'monitoringRequirements',
    String,
    'Monitoring Requirements',
    hint: 'Anomaly detection, usage thresholds, alerting for service accounts',
  ),
  Field(
    'serviceAccountNamingConvention',
    String,
    'Naming Convention',
    hint: 'Naming pattern for service accounts (e.g., svc-{app}-{environment})',
  ),
  Field(
    'documentationRequirements',
    String,
    'Documentation Requirements',
    hint:
        'What must be documented for each service account (purpose, owner, scope)',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 24760 — IAM: a framework for identity management',
    'ISO/IEC 27001:2022 — control A.5.16 identity management',
  ],
  'Defines lifecycle management for non-human service accounts such as APIs, bots, and system integrations.',
)
@SectionId('SACLC')
@CodeSpecKind([CodeSpecPart.identity])
class ServiceAccountLifecycle extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Service Account Management Description (text).
  @SerializationOrder(1)
  TextSection serviceAccountDescription = TextSection();
}

/// 9.1.3. User Attributes.
@StandardReferences(
  [
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    'ISO/IEC 24760 — IAM: a framework for identity management',
  ],
  'Defines the user profile attributes captured and managed to support authentication, authorization, and compliance.',
)
@SectionId('USATT')
@CodeSpecKind([CodeSpecPart.identity])
class UserAttributes extends DocSpecsSection {
  @ContentHelp('''
Define the user profile attributes captured and managed by the system. These
attributes support authentication, authorization, personalization, and
compliance requirements.

**Core identity attributes:**
- Unique identifier (UUID, employee ID, email)
- Display name, legal name, preferred name
- Email addresses (primary, secondary)
- Phone numbers (mobile for MFA, business)
- Account status and creation timestamps

**Organizational attributes:**
- Department, division, cost center
- Job title, role, reporting hierarchy
- Office location, timezone, locale preferences

**Access control attributes:**
- User category/type (customer, employee, partner)
- Security clearance level
- Group memberships and role assignments
- Tenant/organization affiliation

**Compliance considerations:**
- PII classification per attribute (GDPR, CCPA)
- Data minimization — collect only what is necessary
- Attribute source (self-declared, HR system, IdP assertion)
- Retention and deletion policies per attribute type
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× UserAttribute.
  @StandardReferences([
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
  ], 'The catalog of user attribute entries.')
  @SectionId('USATE-ITEM-LST')
  @SectionIdPattern('USATE-ITEM-xxx')
  @ContentHelp('Add one entry per user-attribute entry.')
  @SerializationOrder(1)
  List<UserAttributeEntry> items = [];
}

/// The closed set of identity-attribute placements (CE-ID).
///
/// Where an identity-attribute extension rides on the authorization token:
/// the **public** token payload (readable by any layer, read access guardable
/// by a resource key) or the **encrypted** payload (readable only by
/// token-decrypting layers).
enum UserAttributePlacement {
  /// Rides the public token payload; read access may be guarded by a
  /// resource key.
  public,

  /// Rides the encrypted token payload; readable only by token-decrypting
  /// layers.
  encrypted,
}

/// A user attribute entry (form).
@StandardReferences(
  [
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    'ISO/IEC 24760 — IAM: a framework for identity management',
  ],
  'Defines a single user profile attribute together with its data type, source, placement, access guard, and whether it is mandatory.',
)
@SectionId('USATE')
@CodeSpecKind([CodeSpecPart.identity])
class UserAttributeEntry extends DocSpecsSection {
  @Form([
    Field(
      'attributeName',
      String,
      'Attribute Name',
      required: true,
      hint: 'Name of the user attribute.',
    ),
    Field(
      'dataType',
      String,
      'Data Type',
      hint: 'Data type of the attribute value.',
    ),
    Field(
      'placement',
      UserAttributePlacement,
      'Placement',
      hint: 'public (token public payload, resource-key guardable) or '
          'encrypted (authorization-token encrypted payload).',
    ),
    Field(
      'accessGuard',
      String,
      'Access Guard',
      hint: 'Resource key guarding read access to a public attribute; '
          'encrypted attributes are readable only by token-decrypting '
          'layers.',
    ),
    Field(
      'source',
      String,
      'Source',
      hint: 'System of record that supplies this attribute.',
    ),
    Field(
      'required',
      String,
      'Required',
      hint: 'Whether this attribute is mandatory.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 9.2. Identification and Authentication.
@StandardReferences(
  [
    'ISO/IEC 24760 — IAM: a framework for identity management',
    'NIST SP 800-63A — enrollment and identity proofing',
    'ISO/IEC 29115 — entity authentication assurance framework',
  ],
  'Describes how users are identified and how they prove that identity as the foundation of access control.',
)
@SectionId('IDAUT')
@DetailedIn(D08SecurityAccessSpecification)
@CodeSpecKind([CodeSpecPart.authentication])
class IdentificationAndAuthentication extends DocSpecsSection {
  @ContentHelp('''
Define how users prove their identity to the system. Authentication is the
foundation of access control — all authorization decisions depend on reliable
user identification.

**Key topics to address:**
- Authentication Assurance Levels (AAL) per NIST SP 800-63B:
  - AAL1: Single-factor (passwords)
  - AAL2: Two-factor (password + OTP, push notification)
  - AAL3: Hardware-bound authenticators (FIDO2, PIV)
- Authenticator types supported (what you know, have, are)
- Credential lifecycle (issuance, rotation, recovery, revocation)
- Session management and token handling

**Industry standards:**
- NIST SP 800-63B: Digital Identity Guidelines — Authentication
- FIDO2/WebAuthn: Passwordless authentication
- OAuth 2.0 / OpenID Connect: Federated authentication
- OWASP Authentication Cheat Sheet

**Business context:**
- Balance security vs. user experience
- Support for legacy systems and gradual migration
- Regulatory requirements (PCI DSS, HIPAA, SOX)
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.2.1. Identification.
  @SerializationOrder(1)
  Identification identification = Identification();

  /// 9.2.2. Authentication.
  @SerializationOrder(2)
  Authentication authentication = Authentication();
}

/// 9.2.1. Identification.
///
/// Defines the identity management model: how identities are created,
/// sourced, verified, federated, and mapped. Covers identity sources,
/// identity providers, verification/proofing, SSO, self-registration,
/// and attribute mapping between systems.
@StandardReferences(
  [
    'ISO/IEC 24760 — IAM: a framework for identity management',
    'NIST SP 800-63A — enrollment and identity proofing',
    'ISO/IEC 29115 — entity authentication assurance framework',
  ],
  'Describes how user identities are established, sourced, verified, federated, and mapped within the system.',
)
@SectionId('IDENT')
@CodeSpecKind([CodeSpecPart.authentication])
class Identification extends DocSpecsSection {
  @Form([
    Field(
      'identityModelApproach',
      String,
      'Identity Model Approach',
      hint:
          'Centralized / Federated / Decentralized / Hybrid — how identities are architecturally managed',
    ),
    Field(
      'identityNamespace',
      String,
      'Identity Namespace',
      hint:
          'Namespace/scheme for identifiers, e.g. email, UPN, employeeId, UUID',
    ),
    Field(
      'primaryIdentifierType',
      String,
      'Primary Identifier Type',
      hint:
          'Email / Username / EmployeeId / PhoneNumber / UUID / Custom — primary user-facing identifier',
    ),
    Field(
      'uniqueIdentifierStrategy',
      String,
      'Unique Identifier Generation',
      hint:
          'UUID / GUID / Sequential / HashBased / ExternallyAssigned — how internal unique IDs are generated',
    ),
    Field(
      'identifierImmutability',
      String,
      'Identifier Immutability',
      hint:
          'Immutable / MutableWithAudit / Mutable — whether the primary identifier can change after creation',
    ),
    Field(
      'identityLifecycleModel',
      String,
      'Identity Lifecycle Model',
      hint:
          'CreateActivateDeactivateDelete / ProvisionDeprovision / Custom — lifecycle state machine',
    ),
    Field(
      'identityTrustModel',
      String,
      'Identity Trust Model',
      hint:
          'ZeroTrust / TrustOnFirstUse / PreEstablished / Hierarchical — how trust is initially established',
    ),
    Field(
      'maximumIdentitiesPerPerson',
      String,
      'Max Identities Per Person',
      hint:
          '1 / Multiple / Unlimited — whether one person can have multiple separate identities',
    ),
    Field(
      'identityMergingPolicy',
      String,
      'Identity Merging Policy',
      hint:
          'Allowed / ProhibitedDuplicate / ManualReview — how duplicate identities across sources are handled',
    ),
    Field(
      'identityDataResidency',
      String,
      'Identity Data Residency',
      hint:
          'Jurisdictional requirements for identity data storage, e.g. EU-only, in-country',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Identity Sources — contains 0+× Identity Source.
  @StandardReferences(
    [
      'ISO/IEC 24760 — IAM: a framework for identity management',
      'NIST SP 800-63A — enrollment and identity proofing',
    ],
    'The catalog of identifier source entries from which identities are obtained.',
  )
  @SectionId('IDTSR-IDEN-LST')
  @SectionIdPattern('IDTSR-IDEN-xxx')
  @ContentHelp('Add one entry per identifier source.')
  @SerializationOrder(1)
  List<IdentitySourceEntry> identitySources = [];

  /// Identity Verification.
  @SerializationOrder(2)
  IdentityVerificationPolicy identityVerification =
      IdentityVerificationPolicy();

  /// Identity Providers — contains 0+× Identity Provider.
  @StandardReferences(
    [
      'NIST SP 800-63C — federation and assertions',
      'SAML 2.0 — OASIS security assertion markup language',
    ],
    'The catalog of external identity provider entries configured for the system.',
  )
  @SectionId('IDTPV-IDEN-LST')
  @SectionIdPattern('IDTPV-IDEN-xxx')
  @ContentHelp('Add one entry per identity-provider entry.')
  @SerializationOrder(3)
  List<IdentityProviderEntry> identityProviders = [];

  /// Single Sign-On.
  @SerializationOrder(4)
  SingleSignOnPolicy singleSignOn = SingleSignOnPolicy();

  /// Self-Registration.
  @SerializationOrder(5)
  SelfRegistrationPolicy selfRegistration = SelfRegistrationPolicy();

  /// Attribute Mappings — contains 0+× Identity Attribute Mapping.
  @StandardReferences(
    [
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
      'ISO/IEC 24760 — IAM: a framework for identity management',
    ],
    'The catalog of identity-attribute mappings between sources and the application.',
  )
  @SectionId('IDTAM-ATTR-LST')
  @SectionIdPattern('IDTAM-ATTR-xxx')
  @ContentHelp('Add one entry per identity-attribute mapping.')
  @SerializationOrder(6)
  List<IdentityAttributeMappingEntry> attributeMappings = [];
}

/// An identity source entry (form).
///
/// Defines one source from which identities are obtained, e.g.
/// internal directory, LDAP, external IdP, HR system, self-registration.
@StandardReferences(
  [
    'ISO/IEC 24760 — IAM: a framework for identity management',
    'NIST SP 800-63A — enrollment and identity proofing',
  ],
  'Defines a single source from which identities are obtained, such as a directory, IdP, or HR system.',
)
@SectionId('IDTSR')
@CodeSpecKind([CodeSpecPart.authentication])
class IdentitySourceEntry extends DocSpecsSection {
  @Form([
    Field(
      'sourceName',
      String,
      'Source Name',
      hint: 'Unique name for this identity source, e.g. CorporateAD',
      required: true,
    ),
    Field(
      'sourceType',
      String,
      'Source Type',
      hint:
          'InternalDirectory / LDAP / ActiveDirectory / ExternalIdP / SocialProvider / SelfRegistration / HRSystem / SCIM / Manual',
    ),
    Field(
      'sourceProduct',
      String,
      'Source Product',
      hint: 'Specific product/service, e.g. Azure AD, Okta, Google Workspace',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Connectivity and trust details.
  @SectionId('IDSOENCO')
  @StandardReferences(
    [
      'ISO/IEC 24760 — IAM: a framework for identity management',
      'NIST SP 800-63A — enrollment and identity proofing',
    ],
    'Defines the connection endpoint, protocol, precedence, and trust level for an identity source.',
  )
  @Form([
    Field(
      'sourceEndpoint',
      String,
      'Source Endpoint',
      hint: 'Connection endpoint URL or hostname',
    ),
    Field(
      'sourceProtocol',
      String,
      'Source Protocol',
      hint:
          'LDAP / LDAPS / SCIM / SAML / OIDC / REST / DatabaseDirect / Custom',
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'Primary / Secondary / Tertiary / Fallback — source precedence',
    ),
    Field(
      'trustLevel',
      String,
      'Trust Level',
      hint:
          'Full / High / Medium / Low / Untrusted — degree of trust in identities from this source',
    ),
    Field(
      'authoritative',
      String,
      'Authoritative Source',
      hint:
          'Yes / No — whether this source is the golden record for identity attributes',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? connection;

  /// Synchronization and provisioning details.
  @SectionId('ISEL')
  @StandardReferences(
    [
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
      'ISO/IEC 24760 — IAM: a framework for identity management',
    ],
    'Defines the synchronization, provisioning, and deprovisioning behavior for an identity source.',
  )
  @Form([
    Field(
      'synchronizationMode',
      String,
      'Synchronization Mode',
      hint: 'RealTime / Scheduled / OnDemand / EventDriven / Manual',
    ),
    Field(
      'synchronizationFrequency',
      String,
      'Synchronization Frequency',
      hint: 'Sync interval if scheduled, e.g. 15min, 1h, 24h, weekly',
    ),
    Field(
      'provisioningMethod',
      String,
      'Provisioning Method',
      hint: 'JustInTime / PreProvisioned / SCIM / Manual / Automated',
    ),
    Field(
      'deprovisioningMethod',
      String,
      'Deprovisioning Method',
      hint:
          'Automatic / Manual / Delayed / Cascading — how identities are removed',
    ),
    Field(
      'conflictResolution',
      String,
      'Conflict Resolution',
      hint:
          'SourceWins / TargetWins / MostRecent / ManualReview / MergeAttributes',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? lifecycle;

  /// Attribute mapping details.
  @SectionId('ISEM')
  @StandardReferences(
    [
      'ISO/IEC 24760 — IAM: a framework for identity management',
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    ],
    'Defines which attributes and groups are imported from an identity source.',
  )
  @Form([
    Field(
      'attributeFilter',
      String,
      'Attribute Filter',
      hint:
          'Which attributes are imported, e.g. all, name+email+groups, custom list',
    ),
    Field(
      'groupMappingEnabled',
      String,
      'Group Mapping Enabled',
      hint:
          'Yes / No — whether groups/roles from this source are mapped to application roles',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? mapping;

  /// Operational behavior.
  @SectionId('ISEO')
  @StandardReferences(
    [
      'ISO/IEC 24760 — IAM: a framework for identity management',
      'NIST SP 800-63A — enrollment and identity proofing',
    ],
    'Defines the operational behavior of an identity source such as failover handling and activation state.',
  )
  @Form([
    Field(
      'failoverBehavior',
      String,
      'Failover Behavior',
      hint: 'RetryWithBackoff / FallbackToCache / FailClosed / FailOpen',
    ),
    Field(
      'enabled',
      String,
      'Enabled',
      hint: 'Yes / No — whether this source is currently active',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Detailed description of this identity source and its role',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? operations;
}

/// Identity verification/proofing policy (form).
///
/// Defines how identity claims are verified: verification level, required
/// documents, automation, proofing standards (NIST IAL), and re-verification.
@StandardReferences(
  [
    'NIST SP 800-63A — enrollment and identity proofing',
    'ISO/IEC 29115 — entity authentication assurance framework',
  ],
  'Defines the identity-proofing policy including assurance level, verification mode, and re-verification.',
)
@SectionId('IDVEPO')
@CodeSpecKind([CodeSpecPart.authentication])
class IdentityVerificationPolicy extends DocSpecsSection {
  @Form([
    Field(
      'verificationLevel',
      String,
      'Verification Level',
      hint:
          'None / Basic / Enhanced / Strict — overall identity proofing rigor',
    ),
    Field(
      'nistIalTarget',
      String,
      'NIST IAL Target',
      hint:
          'IAL1 / IAL2 / IAL3 — NIST SP 800-63A Identity Assurance Level target',
    ),
    Field(
      'verificationMode',
      String,
      'Verification Mode',
      hint: 'FullyAutomated / SemiAutomated / ManualReview / Hybrid',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Required proofing artifacts.
  @SectionId('IVPD')
  @StandardReferences(
    [
      'NIST SP 800-63A — enrollment and identity proofing',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Defines the documents, verification methods, and biometrics required as identity-proofing evidence.',
  )
  @Form([
    Field(
      'requiredDocuments',
      String,
      'Required Documents',
      hint:
          'Document types required for proofing, e.g. Government ID, Passport, Utility Bill, None',
    ),
    Field(
      'documentVerificationMethod',
      String,
      'Document Verification Method',
      hint:
          'VisualInspection / OCR / NFC / DatabaseCheck / BiometricMatch / ThirdPartyService',
    ),
    Field(
      'biometricVerification',
      String,
      'Biometric Verification',
      hint: 'None / FaceMatch / Fingerprint / LivenessDetection',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? documents;

  /// Contact and provider verification.
  @SectionId('IVPM')
  @StandardReferences(
    [
      'NIST SP 800-63A — enrollment and identity proofing',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Defines email and phone verification requirements and the third-party proofing provider used.',
  )
  @Form([
    Field(
      'emailVerification',
      String,
      'Email Verification',
      hint: 'Required / Optional / NotApplicable',
    ),
    Field(
      'phoneVerification',
      String,
      'Phone Verification',
      hint: 'Required / Optional / NotApplicable',
    ),
    Field(
      'verificationServiceProvider',
      String,
      'Verification Provider',
      hint: 'Third-party provider, e.g. Jumio, Onfido, LexisNexis, Internal',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? methods;

  /// Workflow and approval settings.
  @SectionId('IVPW')
  @StandardReferences(
    [
      'NIST SP 800-63A — enrollment and identity proofing',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Defines the ordered proofing steps, approval requirements, and proofing channels for identity verification.',
  )
  @Form([
    Field(
      'verificationSteps',
      String,
      'Verification Steps',
      hint:
          'Ordered proofing steps, e.g. EmailConfirm → DocUpload → FaceMatch → AdminApproval',
    ),
    Field(
      'supervisorApprovalRequired',
      String,
      'Supervisor Approval Required',
      hint:
          'Yes / No / ForExternalOnly — whether a supervisor must approve identity proofing',
    ),
    Field(
      'proofingChannels',
      String,
      'Proofing Channels',
      hint: 'InPerson / Remote / Hybrid — where identity proofing occurs',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? workflow;

  /// Reverification and retention settings.
  @SectionId('IVPL')
  @StandardReferences(
    [
      'NIST SP 800-63A — enrollment and identity proofing',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Defines re-verification triggers, periods, and retention of identity-proofing evidence.',
  )
  @Form([
    Field(
      'reverificationTriggers',
      String,
      'Re-verification Triggers',
      hint:
          'Events triggering re-proofing, e.g. RoleChange, SuspiciousActivity, Periodic, DataBreach',
    ),
    Field(
      'reverificationPeriod',
      String,
      'Re-verification Period',
      hint:
          'How often identities must be re-verified, e.g. 1y, 2y, never, onRiskEvent',
    ),
    Field(
      'verificationRecordRetention',
      String,
      'Record Retention',
      hint:
          'How long verification evidence is retained, e.g. 5y, 7y, permanent',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? lifecycle;

  /// Failure handling rules.
  @SectionId('IVPF')
  @StandardReferences(
    [
      'NIST SP 800-63A — enrollment and identity proofing',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Defines how failed identity-proofing attempts are handled, including retry limits and escalation.',
  )
  @Form([
    Field(
      'failedVerificationPolicy',
      String,
      'Failed Verification Policy',
      hint: 'Deny / RetryLimited / ManualEscalation / AlternativeProofing',
    ),
    Field(
      'maxVerificationAttempts',
      int,
      'Max Verification Attempts',
      hint: 'Maximum proofing attempts before lockout, e.g. 3, 5',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? failure;

  /// Additional verification details (text).
  @SerializationOrder(6)
  TextSection verificationDetails = TextSection();
}

/// An identity provider entry (form).
///
/// Configuration for a single Identity Provider (IdP): protocol, endpoints,
/// attribute mapping, trust level, certificate management.
@StandardReferences(
  [
    'NIST SP 800-63C — federation and assertions',
    'SAML 2.0 — OASIS security assertion markup language',
    'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
  ],
  'Configures a single external identity provider including protocol, endpoints, mapping, and trust.',
)
@SectionId('IDTPV')
@CodeSpecKind([CodeSpecPart.authentication])
class IdentityProviderEntry extends DocSpecsSection {
  @Form([
    Field(
      'providerName',
      String,
      'Provider Name',
      hint: 'Human-readable name, e.g. Corporate Azure AD',
      required: true,
    ),
    Field(
      'providerType',
      String,
      'Provider Type',
      hint: 'SAML / OIDC / LDAP / ActiveDirectory / OAuth2',
    ),
    Field(
      'enabled',
      String,
      'Enabled',
      hint: 'Yes / No — whether this provider is currently active',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Provider details.
  @StandardReferences([
    'NIST SP 800-63C — federation and assertions',
    'SAML 2.0 — OASIS security assertion markup language',
  ], 'The catalog of provider-detail entries for this identity provider.')
  @SectionId('IDPRDE-DETA-LST')
  @SectionIdPattern('IDPRDE-DETA-xxx')
  @ContentHelp('Add one entry per provider-detail entry.')
  @SerializationOrder(1)
  List<IdentityProviderDetails> details = [];

  /// Endpoint configuration.
  @StandardReferences([
    'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
    'SAML 2.0 — OASIS security assertion markup language',
  ], 'The catalog of endpoint configurations for this identity provider.')
  @SectionId('IDPREN-ENDP-LST')
  @SectionIdPattern('IDPREN-ENDP-xxx')
  @ContentHelp('Add one entry per provider-endpoint entry.')
  @SerializationOrder(2)
  List<IdentityProviderEndpoints> endpoints = [];

  /// Attribute mapping.
  @SectionId('IDPRMA')
  @StandardReferences(
    [
      'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    ],
    'Defines how identity provider claims map to application attributes, roles, and account linking.',
  )
  @Form([
    Field(
      'attributeMapping',
      String,
      'Attribute Mapping',
      hint: 'How IdP claims/attributes map to application user attributes',
    ),
    Field(
      'groupClaimName',
      String,
      'Group Claim Name',
      hint: 'Claim/attribute containing group memberships',
    ),
    Field(
      'defaultRoles',
      String,
      'Default Roles',
      hint: 'Roles assigned by default to users from this IdP',
    ),
    Field(
      'justInTimeProvisioning',
      String,
      'Just-In-Time Provisioning',
      hint: 'Yes / No — whether accounts are auto-created on first login',
    ),
    Field(
      'accountLinkingStrategy',
      String,
      'Account Linking Strategy',
      hint: 'EmailMatch / ExternalId / ManualLink / None',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? mapping;

  /// Trust and security.
  @SectionId('IDPRTR')
  @StandardReferences(
    [
      'NIST SP 800-63C — federation and assertions',
      'SAML 2.0 — OASIS security assertion markup language',
    ],
    'Defines the trust level, federation agreement, and MFA capability governing an identity provider.',
  )
  @Form([
    Field(
      'trustLevel',
      String,
      'Trust Level',
      hint: 'Full / High / Medium / Low',
    ),
    Field(
      'federationAgreement',
      String,
      'Federation Agreement',
      hint: 'Reference to federation agreement governing this IdP',
    ),
    Field(
      'mfaCapability',
      String,
      'MFA Capability',
      hint: 'Supported / Required / NotSupported',
    ),
    Field(
      'failoverIdp',
      String,
      'Failover IdP',
      hint: 'Backup identity provider if unavailable',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? trust;

  /// Certificates and encryption.
  @SectionId('IDPRSE')
  @StandardReferences(
    [
      'SAML 2.0 — OASIS security assertion markup language',
      'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
    ],
    'Defines certificate management, token signing algorithms, and assertion encryption for an identity provider.',
  )
  @Form([
    Field(
      'certificateManagement',
      String,
      'Certificate Management',
      hint: 'How signing/encryption certificates are managed',
    ),
    Field(
      'tokenSigningAlgorithm',
      String,
      'Token Signing Algorithm',
      hint: 'RS256 / RS384 / RS512 / ES256 / EdDSA',
    ),
    Field(
      'encryptionRequired',
      String,
      'Encryption Required',
      hint: 'Yes / No — whether assertions/tokens must be encrypted',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? security;
}

/// Provider details.
@StandardReferences(
  [
    'NIST SP 800-63C — federation and assertions',
    'SAML 2.0 — OASIS security assertion markup language',
  ],
  'Captures the product, protocol version, and descriptive details of an identity provider.',
)
@SectionId('IDPRDE')
@CodeSpecKind([CodeSpecPart.authentication])
class IdentityProviderDetails extends DocSpecsSection {
  @Form([
    Field(
      'providerProduct',
      String,
      'Provider Product',
      hint: 'Specific product, e.g. Azure AD, Okta, Keycloak',
    ),
    Field(
      'protocolVersion',
      String,
      'Protocol Version',
      hint: 'Protocol version, e.g. SAML 2.0, OIDC 1.0',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Detailed description of this identity provider',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Endpoint configuration.
@StandardReferences(
  [
    'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
    'SAML 2.0 — OASIS security assertion markup language',
  ],
  'Defines the authentication endpoints, metadata URL, issuer, and client identifiers for an identity provider.',
)
@SectionId('IDPREN')
@CodeSpecKind([CodeSpecPart.authentication])
class IdentityProviderEndpoints extends DocSpecsSection {
  @Form([
    Field(
      'endpointUrl',
      String,
      'Endpoint URL',
      hint: 'Primary endpoint URL for authentication',
    ),
    Field(
      'metadataUrl',
      String,
      'Metadata URL',
      hint: 'SAML metadata URL or OIDC discovery endpoint',
    ),
    Field(
      'issuerIdentifier',
      String,
      'Issuer Identifier',
      hint: 'Issuer URI used in tokens',
    ),
    Field(
      'clientId',
      String,
      'Client ID',
      hint: 'Application/client identifier registered at this IdP',
    ),
    Field('scopes', String, 'Scopes', hint: 'OAuth2/OIDC scopes requested'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Single Sign-On policy (form).
///
/// Defines SSO scope, protocol, session propagation, federation,
/// logout propagation, and platform-specific SSO strategies.
@StandardReferences(
  [
    'NIST SP 800-63C — federation and assertions',
    'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
    'SAML 2.0 — OASIS security assertion markup language',
  ],
  'Defines the Single Sign-On policy including scope, protocol, session propagation, and federation.',
)
@SectionId('SSOP')
@CodeSpecKind([CodeSpecPart.authentication])
class SingleSignOnPolicy extends DocSpecsSection {
  @Form([
    Field(
      'ssoEnabled',
      String,
      'SSO Enabled',
      hint: 'Yes / No — whether SSO is enabled for this project',
    ),
    Field(
      'ssoScope',
      String,
      'SSO Scope',
      hint: 'EnterpriseWide / ApplicationSpecific / CrossDomain / BusinessUnit',
    ),
    Field(
      'ssoProtocol',
      String,
      'SSO Protocol',
      hint: 'SAML2.0 / OIDC / OAuth2 / WS-Federation / Kerberos / CAS',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Gateway and federation setup.
  @SectionId('SSOPF')
  @StandardReferences(
    [
      'NIST SP 800-63C — federation and assertions',
      'SAML 2.0 — OASIS security assertion markup language',
    ],
    'Defines the SSO gateway, session propagation, and cross-domain federation trust model.',
  )
  @Form([
    Field(
      'ssoGatewayProduct',
      String,
      'SSO Gateway Product',
      hint:
          'Product/service acting as SSO hub, e.g. Keycloak, PingGateway, Azure AD',
    ),
    Field(
      'sessionPropagationMethod',
      String,
      'Session Propagation Method',
      hint: 'SharedCookie / TokenRelay / BackChannel / FrontChannelRedirect',
    ),
    Field(
      'crossDomainTrustModel',
      String,
      'Cross-Domain Trust Model',
      hint: 'SharedIdP / FederatedTrust / BrokeredTrust / None',
    ),
    Field(
      'identityFederationEnabled',
      String,
      'Identity Federation Enabled',
      hint:
          'Yes / No — whether identities federate across organizational boundaries',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? federation;

  /// Session and logout behavior.
  @SectionId('SSOPS')
  @StandardReferences(
    [
      'NIST SP 800-63C — federation and assertions',
      'SAML 2.0 — OASIS security assertion markup language',
    ],
    'Defines SSO session lifetime, idle timeout, and single-logout propagation across connected applications.',
  )
  @Form([
    Field(
      'logoutPropagation',
      String,
      'Logout Propagation',
      hint:
          'SingleLogout / LocalOnly / BestEffort — how logout propagates across SSO-connected apps',
    ),
    Field(
      'logoutProtocol',
      String,
      'Logout Protocol',
      hint: 'FrontChannel / BackChannel / Both — SLO mechanism',
    ),
    Field(
      'ssoSessionLifetime',
      String,
      'SSO Session Lifetime',
      hint:
          'Maximum SSO session duration before re-authentication, e.g. 8h, 24h, 30d',
    ),
    Field(
      'ssoIdleTimeout',
      String,
      'SSO Idle Timeout',
      hint: 'Idle timeout before SSO session expires, e.g. 30min, 1h, 4h',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? session;

  /// Access and consent behavior.
  @SectionId('SSOPA')
  @StandardReferences(
    [
      'NIST SP 800-63C — federation and assertions',
      'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
    ],
    'Defines account linking, consent requirements, and SSO bypass rules for federated access.',
  )
  @Form([
    Field(
      'accountLinkingStrategy',
      String,
      'Account Linking Strategy',
      hint:
          'AutomaticByEmail / AutomaticByExternalId / UserInitiated / AdminManaged / None',
    ),
    Field(
      'consentRequirements',
      String,
      'Consent Requirements',
      hint: 'None / FirstLoginOnly / PerApplication / PerScope / Periodic',
    ),
    Field(
      'ssoPortalUrl',
      String,
      'SSO Portal URL',
      hint: 'URL for the central SSO portal or application launcher',
    ),
    Field(
      'ssoBypassRules',
      String,
      'SSO Bypass Rules',
      hint:
          'Scenarios where SSO is bypassed, e.g. ServiceAccounts, LocalAdminFallback, BreakGlass',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? access;

  /// Platform integration and monitoring.
  @SectionId('SSOPO')
  @StandardReferences(
    [
      'NIST SP 800-63C — federation and assertions',
      'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
    ],
    'Defines platform-specific SSO integration and monitoring for desktop and mobile clients.',
  )
  @Form([
    Field(
      'desktopSsoIntegration',
      String,
      'Desktop SSO Integration',
      hint:
          'Kerberos / WindowsIntegrated / None — integration with desktop/OS authentication',
    ),
    Field(
      'mobileSsoStrategy',
      String,
      'Mobile SSO Strategy',
      hint:
          'SharedKeychain / AppLinks / BrowserBased / NativeSDK — SSO approach for mobile apps',
    ),
    Field(
      'ssoMonitoring',
      String,
      'SSO Monitoring',
      hint:
          'How SSO health and usage is monitored, e.g. IdPHealthCheck, LoginSuccessRate',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? operations;

  /// Additional SSO details (text).
  @SerializationOrder(5)
  TextSection ssoDetails = TextSection();
}

/// Self-registration policy (form).
///
/// Defines self-service identity creation: registration flow, required
/// fields, verification, approval, rate limiting, and domain restrictions.
@StandardReferences(
  [
    'NIST SP 800-63A — enrollment and identity proofing',
    'ISO/IEC 24760 — IAM: a framework for identity management',
  ],
  'Defines the self-service identity creation policy covering registration flow, verification, approval, and abuse controls.',
)
@SectionId('SEREPO')
@CodeSpecKind([CodeSpecPart.authentication])
class SelfRegistrationPolicy extends DocSpecsSection {
  @Form([
    Field(
      'selfRegistrationEnabled',
      String,
      'Self-Registration Enabled',
      hint:
          'Yes / No / InviteOnly — whether users can create their own identity',
    ),
    Field(
      'registrationFlowType',
      String,
      'Registration Flow Type',
      hint: 'SingleStep / MultiStep / Wizard / SocialOneTap / InvitationBased',
    ),
    Field(
      'requiredFields',
      String,
      'Required Fields',
      hint:
          'Fields required at registration, e.g. email, fullName, password, phone',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Field configuration.
  @SectionId('SRPF')
  @StandardReferences(
    [
      'NIST SP 800-63A — enrollment and identity proofing',
      'ISO/IEC 24760 — IAM: a framework for identity management',
    ],
    'Defines which optional fields and terms acceptance are configured for the self-registration form.',
  )
  @Form([
    Field(
      'optionalFields',
      String,
      'Optional Fields',
      hint:
          'Fields available but not required, e.g. organization, jobTitle, avatar',
    ),
    Field(
      'termsAcceptanceRequired',
      String,
      'Terms Acceptance Required',
      hint: 'Yes / No — whether ToS/privacy policy acceptance is required',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? fields;

  /// Bot protection settings.
  @SectionId('SRPBP')
  @StandardReferences(
    [
      'ISO/IEC 27001:2022 — control A.8.5 secure authentication',
      'NIST SP 800-63A — enrollment and identity proofing',
    ],
    'Defines bot and automated-abuse protection such as CAPTCHA applied to self-registration.',
  )
  @Form([
    Field(
      'captchaRequired',
      String,
      'Captcha Required',
      hint: 'Yes / No / Adaptive — whether CAPTCHA/bot protection is required',
    ),
    Field(
      'captchaProvider',
      String,
      'Captcha Provider',
      hint: 'reCAPTCHAv2 / reCAPTCHAv3 / hCaptcha / Turnstile / Custom',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? botProtection;

  /// Verification requirements.
  @SectionId('SRPV')
  @StandardReferences(
    [
      'NIST SP 800-63A — enrollment and identity proofing',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Defines email and phone verification requirements applied during self-registration.',
  )
  @Form([
    Field(
      'emailVerificationRequired',
      String,
      'Email Verification Required',
      hint:
          'Yes / No — whether email must be verified before account is active',
    ),
    Field(
      'emailVerificationMethod',
      String,
      'Email Verification Method',
      hint: 'ClickLink / EnterCode / MagicLink',
    ),
    Field(
      'phoneVerificationRequired',
      String,
      'Phone Verification Required',
      hint: 'Yes / No — whether phone must be verified',
    ),
    Field(
      'phoneVerificationMethod',
      String,
      'Phone Verification Method',
      hint: 'SMS / VoiceCall / WhatsApp',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? verification;

  /// Approval workflow.
  @SectionId('SRPA')
  @StandardReferences(
    [
      'NIST SP 800-63A — enrollment and identity proofing',
      'ISO/IEC 24760 — IAM: a framework for identity management',
    ],
    'Defines the approval workflow and default role or group assigned to newly self-registered identities.',
  )
  @Form([
    Field(
      'approvalRequired',
      String,
      'Approval Required',
      hint:
          'Yes / No / Conditional — whether admin approval is needed before activation',
    ),
    Field(
      'approvalWorkflow',
      String,
      'Approval Workflow',
      hint: 'SingleApprover / DualApproval / ManagerApproval / AutoApprove',
    ),
    Field(
      'defaultRole',
      String,
      'Default Role',
      hint:
          'Role assigned to newly self-registered users, e.g. BasicUser, Viewer, Pending',
    ),
    Field(
      'defaultGroup',
      String,
      'Default Group',
      hint: 'Group assigned to newly self-registered users',
    ),
    Field(
      'accountActivationDelay',
      String,
      'Account Activation Delay',
      hint:
          'Delay between registration and account becoming usable, e.g. immediate, afterVerification, 24h',
    ),
    Field(
      'welcomeNotification',
      String,
      'Welcome Notification',
      hint:
          'Yes / No — whether a welcome email/message is sent after registration',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? approval;

  /// Security restrictions.
  @SectionId('SRPS')
  @StandardReferences(
    [
      'NIST SP 800-63A — enrollment and identity proofing',
      'ISO/IEC 27001:2022 — control A.8.5 secure authentication',
    ],
    'Defines security restrictions on self-registration such as domain allow/block lists, duplicate detection, and rate limiting.',
  )
  @Form([
    Field(
      'allowedEmailDomains',
      String,
      'Allowed Email Domains',
      hint: 'Domain restrictions for registration, e.g. *, company.com, *.edu',
    ),
    Field(
      'blockedEmailDomains',
      String,
      'Blocked Email Domains',
      hint:
          'Domains blocked from registration, e.g. tempmail.com, guerrillamail.com',
    ),
    Field(
      'duplicateDetectionMethod',
      String,
      'Duplicate Detection Method',
      hint: 'EmailUniqueness / PhoneUniqueness / NameFuzzyMatch / None',
    ),
    Field(
      'rateLimiting',
      String,
      'Rate Limiting',
      hint: 'Registration rate limits, e.g. 5/hour per IP, 10/day per domain',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? security;

  /// Additional registration details (text).
  @SerializationOrder(6)
  TextSection registrationDetails = TextSection();
}

/// An identity attribute mapping entry (form).
///
/// Defines how attributes map between identity sources and the application:
/// source/target field, data type, transformation, sync direction.
@StandardReferences(
  [
    'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
    'ISO/IEC 24760 — IAM: a framework for identity management',
  ],
  'Defines how a single attribute is mapped between an identity source and the application.',
)
@SectionId('IDTAM')
@CodeSpecKind([CodeSpecPart.authentication])
class IdentityAttributeMappingEntry extends DocSpecsSection {
  @Form([
    Field(
      'sourceAttribute',
      String,
      'Source Attribute',
      hint:
          'Attribute name in the source system, e.g. mail, sAMAccountName, sub',
      required: true,
    ),
    Field(
      'sourceSystem',
      String,
      'Source System',
      hint:
          'Identity source or IdP this mapping applies to, e.g. AzureAD, LDAP, AllSources',
    ),
    Field(
      'targetAttribute',
      String,
      'Target Attribute',
      hint:
          'Attribute name in the application, e.g. email, username, displayName',
      required: true,
    ),
    Field(
      'dataType',
      String,
      'Data Type',
      hint:
          'String / Integer / Boolean / DateTime / List / Email / Phone / URL',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Transformation and defaulting behavior.
  @SectionId('IAMET')
  @StandardReferences(
    [
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
      'ISO/IEC 24760 — IAM: a framework for identity management',
    ],
    'Describes how a mapped identity attribute is transformed and defaulted when moving between systems.',
  )
  @Form([
    Field(
      'transformationRule',
      String,
      'Transformation Rule',
      hint:
          'None / Lowercase / Uppercase / Trim / RegexExtract / Concatenate / MapValues / Custom',
    ),
    Field(
      'transformationExpression',
      String,
      'Transformation Expression',
      hint: 'Expression if Custom/RegexExtract, e.g. {firstName} {lastName}',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'Value used when source attribute is missing or null',
    ),
    Field(
      'multiValueHandling',
      String,
      'Multi-Value Handling',
      hint: 'FirstValue / AllValues / Concatenate / PrimaryOnly',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? transformation;

  /// Synchronization and conflict handling.
  @SectionId('IAMES')
  @StandardReferences(
    [
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
      'ISO/IEC 24760 — IAM: a framework for identity management',
    ],
    'Defines the synchronization direction and conflict-resolution behavior for a mapped identity attribute.',
  )
  @Form([
    Field(
      'mandatory',
      String,
      'Mandatory',
      hint:
          'Yes / No — whether this attribute must be present for identity to be valid',
    ),
    Field(
      'syncDirection',
      String,
      'Sync Direction',
      hint: 'SourceToTarget / TargetToSource / Bidirectional / OneTimeImport',
    ),
    Field(
      'conflictResolution',
      String,
      'Conflict Resolution',
      hint:
          'SourceWins / TargetWins / MostRecent / ManualReview — when source and target values differ',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? synchronization;

  /// Validation, classification, and purpose.
  @SectionId('IAMEG')
  @StandardReferences(
    [
      'SCIM 2.0 (RFC 7643/7644) — cross-domain identity provisioning',
      'ISO/IEC 24760 — IAM: a framework for identity management',
    ],
    'Governs validation, sensitivity classification, and the intended purpose of a mapped identity attribute.',
  )
  @Form([
    Field(
      'piiClassification',
      String,
      'PII Classification',
      hint:
          'None / PII / SensitivePII / SpecialCategory — data sensitivity for GDPR/compliance',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Purpose and context for this attribute mapping',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;
}

/// 9.2.2. Authentication.
@StandardReferences(
  [
    'ISO/IEC 29115 — entity authentication assurance framework',
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Describes the authentication subsystem including supported methods, credential policies, session management, and authentication flows.',
)
@SectionId('AUTHEN')
@CodeSpecKind([CodeSpecPart.authentication],
    note: 'Credential exchange / token / session — CE-AU, distinct from '
        'CE-AZ authorization; spans shared + client + server.')
class Authentication extends DocSpecsSection {
  @ContentHelp('''
Overview of the authentication subsystem: methods supported, credential
policies, session management, and authentication flows.

**This section covers:**
- Authentication methods (passwords, MFA, SSO, certificates, biometrics)
- Authentication flow (login lifecycle, token issuance, session creation)
- Password and credential policy (complexity, rotation, recovery)
- Session management (timeouts, concurrent sessions, revocation)

**Design principles:**
- Defense in depth — multiple authentication layers
- Fail-secure — authentication failures deny access
- Secure by default — strongest available method for each user category
- Transparency — clear feedback on authentication requirements

**Implementation considerations:**
- Support for both web and native application authentication
- API authentication (tokens, API keys, mutual TLS)
- Service-to-service authentication (workload identity)
- Authentication event logging for security monitoring
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.2.2.1. Authentication Methods.
  @SerializationOrder(1)
  AuthenticationMethods authenticationMethods = AuthenticationMethods();

  /// 9.2.2.2. Authentication Flow.
  @SerializationOrder(2)
  AuthenticationFlow authenticationFlow = AuthenticationFlow();

  /// 9.2.3. Password and Credential Policy.
  @SerializationOrder(3)
  PasswordAndCredentialPolicy passwordAndCredentialPolicy =
      PasswordAndCredentialPolicy();

  /// 9.2.4. Session Management.
  @SerializationOrder(4)
  SessionManagement sessionManagement = SessionManagement();
}

/// 9.2.2.1. Authentication Methods.
///
/// Comprehensive authentication methods specification aligned with
/// NIST SP 800-63B Authentication Assurance Levels (AAL1–AAL3).
/// Covers all authenticator types: passwords, MFA, SSO, certificates,
/// biometrics, API keys, and cryptographic authenticators.
@StandardReferences(
  [
    'ISO/IEC 29115 — entity authentication assurance framework',
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Describes the supported authentication methods and their assurance levels across all authenticator types.',
)
@SectionId('AUME')
@CodeSpecKind([CodeSpecPart.authentication])
class AuthenticationMethods extends DocSpecsSection {
  @ContentHelp('''
Document all authentication methods supported by the system and their
applicability to different user categories and use cases.

**Primary authentication methods:**
- **Passwords**: Traditional knowledge-based authentication
- **Multi-Factor Authentication (MFA)**:
  - Something you have: TOTP, SMS, push notifications, hardware tokens
  - Something you are: fingerprint, face recognition, voice
- **Single Sign-On (SSO)**: SAML 2.0, OpenID Connect, WS-Federation
- **Certificates**: X.509 client certificates, smart cards, PIV
- **Passwordless**: FIDO2/WebAuthn, magic links, passkeys

**Per-method considerations:**
- Required AAL level (AAL1/AAL2/AAL3)
- Supported platforms (web, mobile, desktop, API)
- User enrollment and recovery procedures
- Fallback authentication for method unavailability
- Phishing resistance and replay attack protection

**Reference:**
- NIST SP 800-63B Section 5: Authenticator and Verifier Requirements
- OWASP Authentication Cheat Sheet
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Authentication Methods Overview (text).
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Multi-Factor Authentication Configuration.
  @SerializationOrder(2)
  MfaConfiguration mfaConfiguration = MfaConfiguration();

  /// Single Sign-On Policy.
  @SerializationOrder(3)
  SsoPolicy ssoPolicy = SsoPolicy();

  /// Certificate-Based Authentication Policy.
  @SerializationOrder(4)
  CertificateAuthenticationPolicy certificateAuthentication =
      CertificateAuthenticationPolicy();

  /// Biometric Authentication Policy.
  @SerializationOrder(5)
  BiometricAuthenticationPolicy biometricAuthentication =
      BiometricAuthenticationPolicy();

  /// API Key Management Policy.
  @SerializationOrder(6)
  ApiKeyManagementPolicy apiKeyManagement = ApiKeyManagementPolicy();

  /// Contains 0+× AuthenticationMethod.
  @StandardReferences([
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'ISO/IEC 29115 — entity authentication assurance framework',
  ], 'The catalog of supported authentication method entries.')
  @SectionId('ATME-ITEM-LST')
  @SectionIdPattern('ATME-ITEM-xxx')
  @ContentHelp('Add one entry per authentication method.')
  @SerializationOrder(7)
  List<AuthenticationMethodEntry> items = [];
}

/// Multi-Factor Authentication (MFA) configuration (form).
///
/// Defines MFA requirements aligned with NIST SP 800-63B AAL2/AAL3:
/// proof of possession and control of two distinct authentication factors.
@Form([
  Field(
    'mfaRequired',
    String,
    'MFA Required',
    hint: 'Yes | No | Conditional — whether MFA is mandatory',
  ),
  Field(
    'mfaEnforcementScope',
    String,
    'MFA Enforcement Scope',
    hint:
        'AllUsers | AdminOnly | PrivilegedRoles | ExternalAccess | Conditional',
  ),
  Field(
    'defaultSecondFactor',
    String,
    'Default Second Factor',
    hint: 'TOTP | Push | FIDO2 | SMS | Email | HardwareToken',
  ),
  Field(
    'allowedSecondFactors',
    String,
    'Allowed Second Factors',
    hint: 'Comma-separated list of permitted second-factor types',
  ),
  Field(
    'assuranceLevelTarget',
    String,
    'Assurance Level Target',
    hint: 'AAL1 | AAL2 | AAL3 — target NIST authentication assurance level',
  ),
  Field(
    'phishingResistanceRequired',
    String,
    'Phishing Resistance Required',
    hint:
        'Yes | No — whether phishing-resistant authenticators are required (AAL3)',
  ),
  Field(
    'stepUpAuthenticationEnabled',
    String,
    'Step-Up Authentication Enabled',
    hint:
        'Yes | No — whether sensitive operations trigger higher AAL re-authentication',
  ),
  Field(
    'stepUpTriggers',
    String,
    'Step-Up Triggers',
    hint:
        'Operations that trigger step-up (payment, admin actions, data export)',
  ),
  Field(
    'rememberDevicePolicy',
    String,
    'Remember Device Policy',
    hint:
        'Duration a device is remembered before MFA re-prompt (e.g., 30d, never)',
  ),
  Field(
    'recoveryCodePolicy',
    String,
    'Recovery Code Policy',
    hint: 'How many one-time recovery codes are issued and their validity',
  ),
  Field(
    'enrollmentGracePeriod',
    String,
    'Enrollment Grace Period',
    hint:
        'Time allowed for users to enroll MFA after it becomes required (e.g., 14d)',
  ),
  Field(
    'mfaBypassPolicy',
    String,
    'MFA Bypass Policy',
    hint:
        'Conditions under which MFA can be bypassed (break-glass, service accounts)',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'ISO/IEC 29115 — entity authentication assurance framework',
    'FIDO2 / W3C WebAuthn — phishing-resistant authentication',
  ],
  'Defines multi-factor authentication requirements based on proof of possession and control of two distinct authentication factors.',
)
@SectionId('MC')
@CodeSpecKind([CodeSpecPart.authentication])
class MfaConfiguration extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// MFA Implementation Details (text).
  @StandardReferences([
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'FIDO2 / W3C WebAuthn — phishing-resistant authentication',
  ], 'The catalog of multi-factor authentication method definitions.')
  @SectionId('MC-MFAD-LST')
  @SectionIdPattern('MC-MFAD-xxx')
  @ContentHelp('Add one entry per MFA method definition.')
  @SerializationOrder(1)
  List<DocSpecsSection> mfaDetails = [];
}

/// Single Sign-On (SSO) policy (form).
///
/// Defines federation and SSO configuration for centralized authentication
/// across multiple applications via identity providers.
@Form([
  Field(
    'ssoEnabled',
    String,
    'SSO Enabled',
    hint: 'Yes | No — whether SSO is implemented',
  ),
  Field(
    'ssoProtocol',
    String,
    'SSO Protocol',
    hint: 'SAML2.0 | OIDC | OAuth2 | WS-Federation | Kerberos',
  ),
  Field(
    'identityProviderType',
    String,
    'Identity Provider Type',
    hint: 'Internal | External | Hybrid — where the IdP is hosted',
  ),
  Field(
    'identityProviderProduct',
    String,
    'Identity Provider Product',
    hint:
        'Specific IdP product or service (e.g., Keycloak, Azure AD, Okta, Auth0)',
  ),
  Field(
    'federationProtocol',
    String,
    'Federation Protocol',
    hint: 'Protocol for cross-organization federation (SAML, OIDC, SCIM)',
  ),
  Field(
    'attributeMapping',
    String,
    'Attribute Mapping',
    hint: 'How IdP attributes map to application roles and permissions',
  ),
  Field(
    'justInTimeProvisioning',
    String,
    'Just-In-Time Provisioning',
    hint: 'Yes | No — whether accounts are auto-created on first SSO login',
  ),
  Field(
    'sessionSynchronization',
    String,
    'Session Synchronization',
    hint:
        'Yes | No — whether logout from one app logs out all SSO-connected apps',
  ),
  Field(
    'singleLogoutEnabled',
    String,
    'Single Logout Enabled',
    hint:
        'Yes | No — whether SLO (Single Logout) is implemented across services',
  ),
  Field(
    'ssoFallbackMethod',
    String,
    'SSO Fallback Method',
    hint:
        'Local password | Backup IdP | None — fallback when IdP is unavailable',
  ),
  Field(
    'ssoScopePolicy',
    String,
    'SSO Scope Policy',
    hint:
        'Which applications are included in SSO (all, internal only, selected)',
  ),
  Field(
    'externalIdpTrustPolicy',
    String,
    'External IdP Trust Policy',
    hint: 'Validation requirements for external identity providers',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63C — federation and assertions',
    'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
    'OAuth 2.0 RFC 6749 — delegated authorization framework',
  ],
  'Defines federation and single sign-on configuration for centralized authentication across multiple applications via identity providers.',
)
@SectionId('SP')
@CodeSpecKind([CodeSpecPart.authentication])
class SsoPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// SSO Implementation Details (text).
  @SerializationOrder(1)
  TextSection ssoDetails = TextSection();
}

/// Certificate-based authentication policy (form).
///
/// Defines requirements for X.509 certificate authentication including
/// mTLS, PIV/CAC cards, and client certificate authentication.
@Form([
  Field(
    'certificateAuthEnabled',
    String,
    'Certificate Auth Enabled',
    hint: 'Yes | No — whether certificate-based authentication is supported',
  ),
  Field(
    'certificateTypes',
    String,
    'Certificate Types',
    hint: 'X.509 | PIV | CAC | SmartCard — types of certificates accepted',
  ),
  Field(
    'certificateIssuance',
    String,
    'Certificate Issuance',
    hint: 'InternalCA | ExternalCA | SelfSigned — who issues the certificates',
  ),
  Field(
    'certificateAuthority',
    String,
    'Certificate Authority',
    hint: 'CA product or service used for certificate issuance',
  ),
  Field(
    'keyStorageRequirement',
    String,
    'Key Storage Requirement',
    hint:
        'TPM | HSM | SmartCard | SoftwareKeystore — where private keys must be stored',
  ),
  Field(
    'mutualTlsRequired',
    String,
    'Mutual TLS Required',
    hint:
        'Yes | No — whether mTLS (client certificate) is required for API access',
  ),
  Field(
    'certificateValidation',
    String,
    'Certificate Validation',
    hint: 'OCSP | CRL | OCSP-Stapling — certificate revocation checking method',
  ),
  Field(
    'certificateLifetime',
    String,
    'Certificate Lifetime',
    hint: 'Maximum validity period for certificates (e.g., 1y, 2y)',
  ),
  Field(
    'renewalProcess',
    String,
    'Renewal Process',
    hint: 'Automatic | Manual | AdminApproval — certificate renewal method',
  ),
  Field(
    'revocationProcess',
    String,
    'Revocation Process',
    hint: 'How compromised certificates are revoked and propagated',
  ),
  Field(
    'minimumKeyStrength',
    String,
    'Minimum Key Strength',
    hint: 'RSA-2048 | RSA-4096 | EC-P256 | EC-P384 — minimum key requirements',
  ),
  Field(
    'fipsComplianceRequired',
    String,
    'FIPS Compliance Required',
    hint: 'Yes | No — whether FIPS 140-2/3 validated modules are required',
  ),
])
@StandardReferences(
  [
    'FIDO2 / W3C WebAuthn — phishing-resistant authentication',
    'NIST SP 800-63B — authentication and authenticator lifecycle',
  ],
  'Defines requirements for X.509 certificate authentication including mutual TLS, PIV, and smart-card credentials.',
)
@SectionId('CAP')
@CodeSpecKind([CodeSpecPart.authentication])
class CertificateAuthenticationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Certificate Authentication Details (text).
  @SerializationOrder(1)
  TextSection certificateDetails = TextSection();
}

/// Biometric authentication policy (form).
///
/// Defines requirements for biometric authentication factors aligned with
/// NIST SP 800-63B Section 3.2.3: biometrics as activation factor for
/// multi-factor authenticators, not standalone authentication.
@Form([
  Field(
    'biometricAuthEnabled',
    String,
    'Biometric Auth Enabled',
    hint: 'Yes | No — whether biometric authentication is supported',
  ),
  Field(
    'biometricModalities',
    String,
    'Biometric Modalities',
    hint:
        'Fingerprint | FacialRecognition | IrisScan | VoicePrint — supported modalities',
  ),
  Field(
    'biometricUsageContext',
    String,
    'Biometric Usage Context',
    hint:
        'DeviceUnlock | TransactionApproval | MfaActivation — when biometrics are used',
  ),
  Field(
    'biometricAsActivationFactor',
    String,
    'Biometric As Activation Factor',
    hint:
        'Yes | No — whether biometric is used as MFA activation factor per NIST guidance',
  ),
  Field(
    'localVsCentralComparison',
    String,
    'Local vs Central Comparison',
    hint:
        'Local | Central — where biometric comparison is performed (local preferred)',
  ),
  Field(
    'falseMatchRateTarget',
    String,
    'False Match Rate Target',
    hint: 'Target FMR (e.g., 1:10000 per NIST SP 800-63B)',
  ),
  Field(
    'presentationAttackDetection',
    String,
    'Presentation Attack Detection',
    hint:
        'Yes | No — whether PAD is implemented (required for facial recognition)',
  ),
  Field(
    'maxConsecutiveFailures',
    String,
    'Max Consecutive Failures',
    hint:
        'Maximum failed biometric attempts before fallback (e.g., 5 without PAD, 10 with PAD)',
  ),
  Field(
    'fallbackMethod',
    String,
    'Fallback Method',
    hint: 'PIN | Password | AlternateModality — fallback when biometric fails',
  ),
  Field(
    'biometricDataStorage',
    String,
    'Biometric Data Storage',
    hint:
        'DeviceOnly | EncryptedCentral | Never — where biometric templates are stored',
  ),
  Field(
    'privacyConsiderations',
    String,
    'Privacy Considerations',
    hint: 'Consent requirements, data retention policy, right to withdraw',
  ),
  Field(
    'accessibilityAlternative',
    String,
    'Accessibility Alternative',
    hint:
        'Alternative authentication for users unable to use biometric modalities',
  ),
])
@StandardReferences(
  [
    'FIDO2 / W3C WebAuthn — phishing-resistant authentication',
    'NIST SP 800-63B — authentication and authenticator lifecycle',
  ],
  'Defines requirements for biometric authentication factors used as activation factors for multi-factor authenticators.',
)
@SectionId('BAP')
@CodeSpecKind([CodeSpecPart.authentication])
class BiometricAuthenticationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Biometric Implementation Details (text).
  @SerializationOrder(1)
  TextSection biometricDetails = TextSection();
}

/// API key management policy (form).
///
/// Defines lifecycle management for API keys, service tokens, and
/// machine-to-machine authentication credentials.
@Form([
  Field(
    'apiKeyAuthEnabled',
    String,
    'API Key Auth Enabled',
    hint: 'Yes | No — whether API key authentication is supported',
  ),
  Field(
    'apiKeyTypes',
    String,
    'API Key Types',
    hint:
        'Static | Rotating | Scoped | ShortLived — types of API keys supported',
  ),
  Field(
    'keyGenerationMethod',
    String,
    'Key Generation Method',
    hint: 'Cryptographic random | UUID | JWT — how API keys are generated',
  ),
  Field(
    'keyLength',
    String,
    'Key Length',
    hint: 'Minimum key length or entropy (e.g., 256-bit, 32 bytes)',
  ),
  Field(
    'keyRotationPolicy',
    String,
    'Key Rotation Policy',
    hint: 'Rotation frequency and method (e.g., 90d, automatic, manual)',
  ),
  Field(
    'keyExpirationPolicy',
    String,
    'Key Expiration Policy',
    hint: 'Maximum key lifetime (e.g., 1y, never, custom)',
  ),
  Field(
    'keyScopeRestrictions',
    String,
    'Key Scope Restrictions',
    hint:
        'Yes | No — whether API keys can be limited to specific resources/actions',
  ),
  Field(
    'ipAllowlisting',
    String,
    'IP Allowlisting',
    hint:
        'Yes | No — whether API keys can be restricted to specific IP addresses',
  ),
  Field(
    'rateLimitingPerKey',
    String,
    'Rate Limiting Per Key',
    hint: 'Yes | No — whether rate limiting is enforced per API key',
  ),
  Field(
    'keyRevocationProcess',
    String,
    'Key Revocation Process',
    hint: 'Immediate | Graceful — how revoked keys stop working',
  ),
  Field(
    'keyStorageGuidance',
    String,
    'Key Storage Guidance',
    hint:
        'VaultService | EnvironmentVariable | SecretManager — recommended storage',
  ),
  Field(
    'keyAuditLogging',
    String,
    'Key Audit Logging',
    hint: 'Yes | No — whether API key usage is logged for audit purposes',
  ),
  Field(
    'serviceTokenSupport',
    String,
    'Service Token Support',
    hint:
        'OAuth2ClientCredentials | JWT | Custom — machine-to-machine token types',
  ),
  Field(
    'tokenLifetime',
    String,
    'Token Lifetime',
    hint: 'Default lifetime for service tokens (e.g., 1h, 24h)',
  ),
])
@StandardReferences(
  [
    'OAuth 2.0 RFC 6749 — delegated authorization framework',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines lifecycle management for API keys, service tokens, and machine-to-machine authentication credentials.',
)
@SectionId('AKMP')
@CodeSpecKind([CodeSpecPart.authentication])
class ApiKeyManagementPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// API Key Management Details (text).
  @SerializationOrder(1)
  TextSection apiKeyDetails = TextSection();
}

/// An authentication method entry (form).
///
/// Detailed per-method specification aligned with NIST SP 800-63B
/// authenticator types (password, OTP, cryptographic, out-of-band).
@StandardReferences(
  [
    'ISO/IEC 29115 — entity authentication assurance framework',
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Provides a detailed per-method specification for a single authentication method aligned with NIST authenticator types.',
)
@SectionId('ATME')
@CodeSpecKind([CodeSpecPart.authentication])
class AuthenticationMethodEntry extends DocSpecsSection {
  @Form([
    Field(
      'methodName',
      String,
      'Method Name',
      required: true,
      hint: 'Unique name identifying this authentication method',
    ),
    Field(
      'methodType',
      String,
      'Method Type',
      hint:
          'Password | TOTP | HOTP | FIDO2 | WebAuthn | SmartCard | Push | SMS | Email | Biometric | APIKey | Certificate',
    ),
    Field(
      'authenticationFactor',
      String,
      'Authentication Factor',
      hint: 'Knowledge | Possession | Inherence — NIST factor category',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Security posture of the authentication method.
  @SectionId('AMES')
  @StandardReferences(
    [
      'NIST SP 800-63B — authentication and authenticator lifecycle',
      'ISO/IEC 29115 — entity authentication assurance framework',
      'OWASP ASVS V2 — authentication verification requirements',
    ],
    'Describes the security posture of an authentication method including assurance level and phishing resistance.',
  )
  @Form([
    Field(
      'assuranceLevel',
      String,
      'Assurance Level',
      hint: 'AAL1 | AAL2 | AAL3 — NIST authentication assurance level',
    ),
    Field(
      'phishingResistant',
      String,
      'Phishing Resistant',
      hint:
          'Yes | No — whether this method resists phishing per NIST SP 800-63B §3.2.5',
    ),
    Field(
      'replayResistant',
      String,
      'Replay Resistant',
      hint: 'Yes | No — whether this method resists replay attacks',
    ),
    Field(
      'hardwareRequirement',
      String,
      'Hardware Requirement',
      hint: 'None | SecurityKey | SmartCard | TPM | HSM — required hardware',
    ),
    Field(
      'fipsValidationLevel',
      String,
      'FIPS Validation Level',
      hint:
          'None | Level1 | Level2 | Level3 — FIPS 140 validation level if applicable',
    ),
    Field(
      'securityLevel',
      String,
      'Security Level',
      hint: 'Low | Medium | High | Critical — overall security classification',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? security;

  /// Usage scope of the authentication method.
  @SectionId('AMEA')
  @StandardReferences(
    [
      'NIST SP 800-63B — authentication and authenticator lifecycle',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Describes the usage scope of an authentication method including applicable user categories and its role in the flow.',
  )
  @Form([
    Field(
      'applicableUserCategories',
      String,
      'Applicable User Categories',
      hint: 'InternalUsers | ExternalUsers | Admins | ServiceAccounts | All',
    ),
    Field(
      'primaryOrSecondary',
      String,
      'Primary or Secondary',
      hint: 'Primary | Secondary | Either — role in authentication flow',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? applicability;

  /// Enrollment and activation workflow.
  @SectionId('AMEE')
  @StandardReferences(
    [
      'NIST SP 800-63B — authentication and authenticator lifecycle',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Describes the enrollment and activation workflow for an authentication method.',
  )
  @Form([
    Field(
      'enrollmentProcess',
      String,
      'Enrollment Process',
      hint:
          'How users enroll in this method (self-service, admin-provisioned, automated)',
    ),
    Field(
      'enrollmentVerification',
      String,
      'Enrollment Verification',
      hint:
          'Verification required during enrollment (identity proofing, email confirmation)',
    ),
    Field(
      'activationRequirement',
      String,
      'Activation Requirement',
      hint:
          'PIN | Password | Biometric | None — activation factor for multi-factor authenticators',
    ),
    Field(
      'fallbackMethod',
      String,
      'Fallback Method',
      hint:
          'Alternative method when this one is unavailable (recovery codes, admin reset)',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? enrollment;

  /// Operational controls and lifecycle settings.
  @SectionId('AMEO')
  @StandardReferences(
    [
      'NIST SP 800-63B — authentication and authenticator lifecycle',
      'OWASP ASVS V2 — authentication verification requirements',
    ],
    'Describes the operational controls and lifecycle settings such as lockout and reauthentication timeout for an authentication method.',
  )
  @Form([
    Field(
      'maxFailedAttempts',
      String,
      'Max Failed Attempts',
      hint:
          'Maximum consecutive failed attempts before lockout (e.g., 5, 10, 100)',
    ),
    Field(
      'lockoutPolicy',
      String,
      'Lockout Policy',
      hint:
          'TemporaryDelay | AccountLock | RequireRebinding — action after max failures',
    ),
    Field(
      'reauthenticationTimeout',
      String,
      'Reauthentication Timeout',
      hint:
          'Session timeout requiring reauthentication (e.g., 15min, 12h, 30d per AAL)',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Detailed description of this authentication method',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? operations;
}

/// 9.2.2.2. Authentication Flow.
///
/// Comprehensive authentication flow specification covering the complete
/// login lifecycle: credential submission, validation, multi-factor challenges,
/// token issuance, session establishment, redirect handling, and error
/// recovery. Aligned with OAuth 2.0/OIDC and NIST SP 800-63B flow patterns.
@StandardReferences(
  [
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OAuth 2.0 RFC 6749 — delegated authorization framework',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Describes the end-to-end authentication flow from credential submission through token issuance and session establishment.',
)
@SectionId('AUFL')
@CodeSpecKind([CodeSpecPart.authentication])
class AuthenticationFlow extends DocSpecsSection {
  @ContentHelp('''
Document the end-to-end authentication flow from initial login request to
established session. Include sequence diagrams for clarity.

**Flow phases:**
1. **Initiation**: User navigates to protected resource or login page
2. **Identification**: Username/email entry, account lookup
3. **Primary Authentication**: Password or primary credential verification
4. **Step-Up Authentication**: MFA challenge if required
5. **Token Issuance**: Generate access token, refresh token, ID token
6. **Session Establishment**: Create server-side session, set cookies
7. **Redirect**: Return user to requested resource

**Error handling:**
- Invalid credentials → lockout progression, brute-force protection
- MFA failure → retry limits, fallback methods
- Session conflicts → concurrent session policy enforcement
- Token errors → silent refresh, re-authentication prompts

**Security considerations:**
- CSRF protection on login forms
- Timing-safe credential comparison
- Secure cookie attributes (HttpOnly, Secure, SameSite)
- OAuth 2.0 PKCE for public clients
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Authentication Flow Overview (text).
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Authentication Flow Diagram (mermaid-sequence).
  @SerializationOrder(2)
  SequenceDiagramSection authenticationFlowDiagram = SequenceDiagramSection();

  /// Login Flow Configuration.
  @SerializationOrder(3)
  LoginFlowConfiguration loginFlow = LoginFlowConfiguration();

  /// Token Management Policy.
  @SerializationOrder(4)
  TokenManagementPolicy tokenManagement = TokenManagementPolicy();

  /// Session Creation Policy.
  @SerializationOrder(5)
  SessionCreationPolicy sessionCreation = SessionCreationPolicy();

  /// Redirect and Callback Handling.
  @SerializationOrder(6)
  RedirectHandlingPolicy redirectHandling = RedirectHandlingPolicy();

  /// Authentication Error Handling.
  @SerializationOrder(7)
  AuthenticationErrorHandling errorHandling = AuthenticationErrorHandling();

  /// Step-Up and Adaptive Authentication.
  @SerializationOrder(8)
  StepUpAuthenticationPolicy stepUpAuthentication =
      StepUpAuthenticationPolicy();

  /// Contains 0+× Login Flow Step.
  @StandardReferences(
    [
      'NIST SP 800-63B — authentication and authenticator lifecycle',
      'OWASP ASVS V2 — authentication verification requirements',
    ],
    'The catalog of login flow step entries defining the authentication sequence.',
  )
  @SectionId('LGFLS-LOGI-LST')
  @SectionIdPattern('LGFLS-LOGI-xxx')
  @ContentHelp('Add one entry per login flow step.')
  @SerializationOrder(9)
  List<LoginFlowStepEntry> loginFlowSteps = [];
}

/// Login flow configuration (form).
///
/// Defines the overall login flow structure: entry points, credential
/// submission method, pre-authentication checks, and post-authentication
/// actions.
@Form([
  Field(
    'loginEntryPoint',
    String,
    'Login Entry Point',
    hint:
        'LoginPage | Modal | InlineWidget | ApiEndpoint — where users initiate login',
  ),
  Field(
    'credentialSubmissionMethod',
    String,
    'Credential Submission Method',
    hint: 'FormPost | Ajax | OAuth2AuthCode | OAuth2PKCE | SAMLRequest',
  ),
  Field(
    'preAuthenticationChecks',
    String,
    'Pre-Authentication Checks',
    hint: 'CAPTCHA | DeviceFingerprint | GeoIP | RiskScore | None',
  ),
  Field(
    'authenticationEndpoint',
    String,
    'Authentication Endpoint',
    hint: 'URL or path of the authentication API endpoint',
  ),
  Field(
    'allowedAuthenticationMethods',
    String,
    'Allowed Authentication Methods',
    hint: 'Comma-separated list of allowed methods for this login flow',
  ),
  Field(
    'mfaChallengePresentation',
    String,
    'MFA Challenge Presentation',
    hint: 'SamePage | SeparateStep | PushNotification — how MFA is presented',
  ),
  Field(
    'rememberMeEnabled',
    String,
    'Remember Me Enabled',
    hint: 'Yes | No — whether Remember Me option is available',
  ),
  Field(
    'rememberMeDuration',
    String,
    'Remember Me Duration',
    hint: 'Duration the device is remembered (e.g., 30d, 90d)',
  ),
  Field(
    'socialLoginEnabled',
    String,
    'Social Login Enabled',
    hint: 'Yes | No — whether social identity providers are supported',
  ),
  Field(
    'socialLoginProviders',
    String,
    'Social Login Providers',
    hint:
        'Google | Apple | Microsoft | GitHub | Facebook — supported providers',
  ),
  Field(
    'passwordlessLoginEnabled',
    String,
    'Passwordless Login Enabled',
    hint:
        'Yes | No — whether passwordless options (magic link, WebAuthn) are offered',
  ),
  Field(
    'passwordlessLoginMethods',
    String,
    'Passwordless Login Methods',
    hint:
        'MagicLink | WebAuthn | FIDO2 | Passkey — available passwordless methods',
  ),
  Field(
    'postAuthenticationAction',
    String,
    'Post-Authentication Action',
    hint: 'RedirectToOriginal | Dashboard | ConsentScreen | ProfileCompletion',
  ),
  Field(
    'concurrentLoginPolicy',
    String,
    'Concurrent Login Policy',
    hint:
        'Allow | DenyNew | TerminateOldest | TerminateAll — behavior for concurrent logins',
  ),
  Field(
    'loginNotification',
    String,
    'Login Notification',
    hint: 'Yes | No — whether users are notified of successful logins',
  ),
  Field(
    'loginFromNewDeviceAction',
    String,
    'Login From New Device Action',
    hint:
        'Notify | RequireMFA | Block | VerifyEmail — action for unrecognized devices',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OWASP ASVS V2 — authentication verification requirements',
    'ISO/IEC 27001:2022 — control A.8.5 secure authentication',
  ],
  'Defines the overall login flow structure including entry points, credential submission, and post-authentication actions.',
)
@SectionId('LFC')
@CodeSpecKind([CodeSpecPart.authentication])
class LoginFlowConfiguration extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Login Flow Details (text).
  @SerializationOrder(1)
  TextSection loginFlowDetails = TextSection();
}

/// Token management policy (form).
///
/// Defines token issuance, refresh, storage, and revocation policies for
/// authentication tokens (JWT, opaque, refresh tokens, ID tokens).
@Form([
  Field(
    'tokenFormat',
    String,
    'Token Format',
    hint: 'JWT | Opaque | SAML | Custom — primary access token format',
  ),
  Field(
    'tokenSigningAlgorithm',
    String,
    'Token Signing Algorithm',
    hint: 'RS256 | ES256 | HS256 | EdDSA — algorithm for signing tokens',
  ),
  Field(
    'accessTokenLifetime',
    String,
    'Access Token Lifetime',
    hint: 'Duration of access token validity (e.g., 15min, 1h)',
  ),
  Field(
    'refreshTokenEnabled',
    String,
    'Refresh Token Enabled',
    hint: 'Yes | No — whether refresh tokens are issued',
  ),
  Field(
    'refreshTokenLifetime',
    String,
    'Refresh Token Lifetime',
    hint: 'Duration of refresh token validity (e.g., 7d, 30d)',
  ),
  Field(
    'refreshTokenRotation',
    String,
    'Refresh Token Rotation',
    hint: 'Yes | No — whether refresh tokens are rotated on each use',
  ),
  Field(
    'refreshTokenReuseDetection',
    String,
    'Refresh Token Reuse Detection',
    hint: 'Yes | No — whether reuse of old refresh tokens triggers revocation',
  ),
  Field(
    'idTokenEnabled',
    String,
    'ID Token Enabled',
    hint: 'Yes | No — whether OIDC ID tokens are issued',
  ),
  Field(
    'idTokenClaims',
    String,
    'ID Token Claims',
    hint: 'Standard claims included in ID tokens (sub, email, name, roles)',
  ),
  Field(
    'tokenStorageClient',
    String,
    'Token Storage Client',
    hint:
        'HttpOnlyCookie | SessionStorage | LocalStorage | Memory — client-side storage',
  ),
  Field(
    'tokenStorageServer',
    String,
    'Token Storage Server',
    hint:
        'Redis | Database | InMemory | None — server-side token store (for opaque tokens)',
  ),
  Field(
    'tokenRevocationEnabled',
    String,
    'Token Revocation Enabled',
    hint: 'Yes | No — whether token revocation endpoint is available',
  ),
  Field(
    'tokenRevocationPropagation',
    String,
    'Token Revocation Propagation',
    hint:
        'Immediate | EventualConsistency | Polling — how revocation propagates',
  ),
  Field(
    'tokenIntrospectionEnabled',
    String,
    'Token Introspection Enabled',
    hint:
        'Yes | No — whether RFC 7662 token introspection endpoint is available',
  ),
  Field(
    'audienceRestriction',
    String,
    'Audience Restriction',
    hint:
        'Yes | No — whether tokens are audience-restricted to specific services',
  ),
  Field(
    'scopePolicy',
    String,
    'Scope Policy',
    hint:
        'Minimum scope principle — how token scopes are assigned and validated',
  ),
])
@StandardReferences(
  [
    'OAuth 2.0 RFC 6749 — delegated authorization framework',
    'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines token issuance, refresh, storage, and revocation policies for authentication tokens.',
)
@SectionId('TMP')
@CodeSpecKind([CodeSpecPart.authentication])
class TokenManagementPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Token Management Details (text).
  @SerializationOrder(1)
  TextSection tokenManagementDetails = TextSection();
}

/// Session creation policy (form).
///
/// Defines how authenticated sessions are established after successful
/// authentication: session binding, device binding, and session properties.
@Form([
  Field(
    'sessionMechanism',
    String,
    'Session Mechanism',
    hint:
        'ServerSideCookie | JwtBearer | OpaqueToken — primary session mechanism',
  ),
  Field(
    'sessionIdGeneration',
    String,
    'Session ID Generation',
    hint:
        'CryptoRandom | UUID | HMAC — method for session identifier generation',
  ),
  Field(
    'sessionIdEntropy',
    String,
    'Session ID Entropy',
    hint: 'Minimum entropy for session identifiers (e.g., 128-bit, 256-bit)',
  ),
  Field(
    'sessionBindingMethod',
    String,
    'Session Binding Method',
    hint: 'Cookie | Header | TokenBound — how sessions are bound to requests',
  ),
  Field(
    'httpOnlyCookies',
    String,
    'HttpOnly Cookies',
    hint: 'Yes | No — whether session cookies use HttpOnly flag',
  ),
  Field(
    'secureCookies',
    String,
    'Secure Cookies',
    hint: 'Yes | No — whether session cookies use Secure flag (HTTPS only)',
  ),
  Field(
    'sameSitePolicy',
    String,
    'SameSite Policy',
    hint: 'Strict | Lax | None — SameSite cookie attribute policy',
  ),
  Field(
    'cookieDomain',
    String,
    'Cookie Domain',
    hint: 'Domain scope for session cookies (exact domain or parent domain)',
  ),
  Field(
    'deviceBinding',
    String,
    'Device Binding',
    hint:
        'None | Fingerprint | CertificateBound | DPoP — session-to-device binding',
  ),
  Field(
    'sessionDataStorage',
    String,
    'Session Data Storage',
    hint:
        'ServerSide | ClientSide | Hybrid — where full session data is stored',
  ),
  Field(
    'sessionReplicationStrategy',
    String,
    'Session Replication Strategy',
    hint:
        'StickySession | Distributed | Stateless — strategy for multi-node deployments',
  ),
  Field(
    'csrfProtection',
    String,
    'CSRF Protection',
    hint:
        'SynchronizerToken | DoubleSubmit | SameSite | None — CSRF mitigation method',
  ),
  Field(
    'postLoginRedirectValidation',
    String,
    'Post-Login Redirect Validation',
    hint:
        'Allowlist | SameOrigin | None — validation of post-login redirect targets',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OWASP ASVS V2 — authentication verification requirements',
    'ISO/IEC 27001:2022 — control A.8.5 secure authentication',
  ],
  'Defines how authenticated sessions are established after successful authentication including session binding and device binding.',
)
@SectionId('SCP')
@CodeSpecKind([CodeSpecPart.authentication])
class SessionCreationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Session Creation Details (text).
  @SerializationOrder(1)
  TextSection sessionCreationDetails = TextSection();
}

/// Redirect and callback handling policy (form).
///
/// Defines how authentication redirects, OAuth/OIDC callbacks, deep links,
/// and error redirects are managed in the authentication flow.
@Form([
  Field(
    'oauthRedirectUriPolicy',
    String,
    'OAuth Redirect URI Policy',
    hint:
        'ExactMatch | WildcardSubdomain | DynamicRegistration — redirect URI validation',
  ),
  Field(
    'allowedRedirectDomains',
    String,
    'Allowed Redirect Domains',
    hint: 'Comma-separated list of allowed redirect domains',
  ),
  Field(
    'callbackUrlValidation',
    String,
    'Callback URL Validation',
    hint:
        'StrictMatch | PathPrefix | OriginOnly — how callback URLs are validated',
  ),
  Field(
    'stateParameterRequired',
    String,
    'State Parameter Required',
    hint:
        'Yes | No — whether OAuth state parameter is required for CSRF protection',
  ),
  Field(
    'pkceRequired',
    String,
    'PKCE Required',
    hint: 'Yes | No — whether PKCE (Proof Key for Code Exchange) is mandatory',
  ),
  Field(
    'pkceMethod',
    String,
    'PKCE Method',
    hint: 'S256 | Plain — PKCE code challenge method (S256 recommended)',
  ),
  Field(
    'deepLinkHandling',
    String,
    'Deep Link Handling',
    hint:
        'UniversalLinks | AppLinks | CustomScheme — mobile deep link strategy',
  ),
  Field(
    'errorRedirectBehavior',
    String,
    'Error Redirect Behavior',
    hint:
        'RedirectWithError | ErrorPage | OriginalPage — behavior on auth errors',
  ),
  Field(
    'postLogoutRedirectUri',
    String,
    'Post-Logout Redirect URI',
    hint: 'Where users are redirected after logout',
  ),
  Field(
    'singleLogoutRedirectChain',
    String,
    'Single Logout Redirect Chain',
    hint:
        'Yes | No — whether SLO propagates logouts across all connected services',
  ),
  Field(
    'corsPolicy',
    String,
    'CORS Policy',
    hint: 'AllowedOrigins for authentication endpoints (exact list or pattern)',
  ),
  Field(
    'iframeEmbeddingPolicy',
    String,
    'Iframe Embedding Policy',
    hint:
        'Deny | SameOrigin | AllowSpecific — X-Frame-Options / CSP frame-ancestors',
  ),
])
@StandardReferences(
  [
    'OAuth 2.0 RFC 6749 — delegated authorization framework',
    'OpenID Connect Core 1.0 — identity layer over OAuth 2.0',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines how authentication redirects, OAuth and OIDC callbacks, deep links, and error redirects are managed in the authentication flow.',
)
@SectionId('RHP')
@CodeSpecKind([CodeSpecPart.authentication])
class RedirectHandlingPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Redirect Handling Details (text).
  @SerializationOrder(1)
  TextSection redirectDetails = TextSection();
}

/// Authentication error handling (form).
///
/// Defines how authentication failures, lockouts, and security events are
/// handled in the authentication flow.
@Form([
  Field(
    'invalidCredentialResponse',
    String,
    'Invalid Credential Response',
    hint:
        'GenericError | SpecificError — response to invalid credentials (generic preferred)',
  ),
  Field(
    'accountLockoutThreshold',
    String,
    'Account Lockout Threshold',
    hint:
        'Number of failed attempts before lockout (e.g., 5, 10, configurable)',
  ),
  Field(
    'lockoutDuration',
    String,
    'Lockout Duration',
    hint: 'Duration of lockout (e.g., 15min, 30min, progressive, permanent)',
  ),
  Field(
    'lockoutEscalation',
    String,
    'Lockout Escalation',
    hint:
        'Fixed | Progressive | Exponential — whether lockout duration increases',
  ),
  Field(
    'bruteForceProtection',
    String,
    'Brute Force Protection',
    hint:
        'RateLimiting | CAPTCHA | IPBlock | AccountLock — brute-force mitigation',
  ),
  Field(
    'credentialStuffingProtection',
    String,
    'Credential Stuffing Protection',
    hint: 'BreachDatabase | DeviceFingerprint | BehaviorAnalysis | None',
  ),
  Field(
    'userNotificationOnFailure',
    String,
    'User Notification On Failure',
    hint: 'Yes | No — whether users are notified of failed login attempts',
  ),
  Field(
    'adminAlertThreshold',
    String,
    'Admin Alert Threshold',
    hint:
        'Number of failures before admin alert (e.g., 10, 50, per-minute rate)',
  ),
  Field(
    'failedLoginAuditLogging',
    String,
    'Failed Login Audit Logging',
    hint: 'Yes | No — whether failed login attempts are logged for audit',
  ),
  Field(
    'suspiciousActivityResponse',
    String,
    'Suspicious Activity Response',
    hint:
        'RequireMFA | TemporaryBlock | CAPTCHA | ManualReview — response to anomalies',
  ),
  Field(
    'gracefulDegradation',
    String,
    'Graceful Degradation',
    hint:
        'Behavior when authentication service is partially unavailable (queue, fallback, deny)',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OWASP ASVS V2 — authentication verification requirements',
    'ISO/IEC 27001:2022 — control A.8.5 secure authentication',
  ],
  'Defines how authentication failures, lockouts, and brute-force security events are handled in the authentication flow.',
)
@SectionId('AEH')
@CodeSpecKind([CodeSpecPart.authentication])
class AuthenticationErrorHandling extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Error Handling Details (text).
  @SerializationOrder(1)
  TextSection errorHandlingDetails = TextSection();
}

/// Step-up and adaptive authentication policy (form).
///
/// Defines when and how authentication level is elevated for sensitive
/// operations, including risk-based and context-aware authentication.
@Form([
  Field(
    'stepUpEnabled',
    String,
    'Step-Up Enabled',
    hint: 'Yes | No — whether step-up authentication is implemented',
  ),
  Field(
    'stepUpTriggers',
    String,
    'Step-Up Triggers',
    hint:
        'HighRiskOperation | SensitiveDataAccess | AdminAction | PaymentApproval | SettingsChange',
  ),
  Field(
    'stepUpTargetAal',
    String,
    'Step-Up Target AAL',
    hint: 'AAL2 | AAL3 — target assurance level for step-up authentication',
  ),
  Field(
    'stepUpTimeout',
    String,
    'Step-Up Timeout',
    hint:
        'Duration the elevated session lasts (e.g., 5min, 15min, transaction-scoped)',
  ),
  Field(
    'riskBasedAuthEnabled',
    String,
    'Risk-Based Auth Enabled',
    hint:
        'Yes | No — whether risk signals influence authentication requirements',
  ),
  Field(
    'riskSignals',
    String,
    'Risk Signals',
    hint:
        'GeoLocation | IPReputation | DeviceFingerprint | BehaviorPattern | TimeOfDay',
  ),
  Field(
    'riskScoringMethod',
    String,
    'Risk Scoring Method',
    hint: 'RuleBased | MachineLearning | Hybrid — how risk scores are computed',
  ),
  Field(
    'lowRiskAction',
    String,
    'Low Risk Action',
    hint: 'AllowSilently | NormalAuth — response to low-risk signals',
  ),
  Field(
    'mediumRiskAction',
    String,
    'Medium Risk Action',
    hint:
        'RequireMFA | AdditionalVerification — response to medium-risk signals',
  ),
  Field(
    'highRiskAction',
    String,
    'High Risk Action',
    hint:
        'Block | RequirePhishingResistant | ManualReview — response to high-risk signals',
  ),
  Field(
    'adaptiveAuthProvider',
    String,
    'Adaptive Auth Provider',
    hint:
        'Built-in | Third-party service name — provider of adaptive authentication',
  ),
  Field(
    'continuousAuthEnabled',
    String,
    'Continuous Auth Enabled',
    hint:
        'Yes | No — whether session is continuously monitored for risk changes',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OWASP ASVS V2 — authentication verification requirements',
    'ISO/IEC 27001:2022 — control A.8.5 secure authentication',
  ],
  'Defines when and how authentication assurance is elevated for sensitive operations including risk-based and context-aware authentication.',
)
@SectionId('SUAP')
@CodeSpecKind([CodeSpecPart.authentication])
class StepUpAuthenticationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Step-Up Authentication Details (text).
  @StandardReferences([
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OWASP ASVS V2 — authentication verification requirements',
  ], 'The catalog of step-up authentication detail entries.')
  @SectionId('SUAP-STEP-LST')
  @SectionIdPattern('SUAP-STEP-xxx')
  @ContentHelp('Add one entry per step-up authentication step.')
  @SerializationOrder(1)
  List<DocSpecsSection> stepUpDetails = [];
}

/// A login flow step entry (form).
///
/// Defines an individual step in the authentication flow sequence,
/// allowing detailed specification of each stage from initial request
/// to authenticated session.
@StandardReferences(
  [
    'NIST SP 800-63B — authentication and authenticator lifecycle',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines an individual step in the authentication flow sequence from initial request to authenticated session.',
)
@SectionId('LGFLS')
@CodeSpecKind([CodeSpecPart.authentication])
class LoginFlowStepEntry extends DocSpecsSection {
  @Form([
    Field(
      'stepName',
      String,
      'Step Name',
      required: true,
      hint: 'Unique name for this login flow step',
    ),
    Field(
      'stepOrder',
      String,
      'Step Order',
      hint: 'Numeric order in the flow sequence (1, 2, 3, ...)',
    ),
    Field(
      'stepType',
      String,
      'Step Type',
      hint:
          'EntryPoint | CredentialInput | Validation | MfaChallenge | ConsentScreen | TokenIssuance | SessionCreation | Redirect | ErrorHandling',
    ),
    Field(
      'actor',
      String,
      'Actor',
      hint:
          'User | Browser | AuthServer | IdP | MfaDevice | ResourceServer — who performs this step',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Inputs and validation behavior.
  @SectionId('LFSEV')
  @StandardReferences(
    [
      'NIST SP 800-63B — authentication and authenticator lifecycle',
      'OWASP ASVS V2 — authentication verification requirements',
    ],
    'Describes the required inputs and validation actions performed during a login flow step.',
  )
  @Form([
    Field(
      'inputRequired',
      String,
      'Input Required',
      hint:
          'Username | Password | OTP | BiometricSample | ConsentApproval | None',
    ),
    Field(
      'validationAction',
      String,
      'Validation Action',
      hint:
          'CredentialVerification | TokenValidation | RiskAssessment | MfaVerification | None',
    ),
    Field(
      'timeoutSeconds',
      String,
      'Timeout Seconds',
      hint: 'Maximum time allowed for this step (e.g., 300, 600)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? validation;

  /// Outcomes and optional execution rules.
  @SectionId('LFSEB')
  @StandardReferences(
    [
      'NIST SP 800-63B — authentication and authenticator lifecycle',
      'OWASP ASVS V2 — authentication verification requirements',
    ],
    'Describes the success and failure outcomes and conditional execution rules of a login flow step.',
  )
  @Form([
    Field(
      'successOutcome',
      String,
      'Success Outcome',
      hint:
          'NextStep | TokenIssued | SessionCreated | RedirectToApp — outcome on success',
    ),
    Field(
      'failureOutcome',
      String,
      'Failure Outcome',
      hint:
          'RetryWithError | Lockout | RedirectToError | AbortFlow — outcome on failure',
    ),
    Field(
      'optional',
      String,
      'Optional',
      hint: 'Yes | No — whether this step can be skipped',
    ),
    Field(
      'conditionalTrigger',
      String,
      'Conditional Trigger',
      hint:
          'Condition under which this step is activated (e.g., MFA required, new device)',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? behavior;

  /// Protocol-level and descriptive details.
  @SectionId('LFSEP')
  @StandardReferences(
    [
      'NIST SP 800-63B — authentication and authenticator lifecycle',
      'OWASP ASVS V2 — authentication verification requirements',
    ],
    'Captures the protocol-level message and descriptive details of a login flow step.',
  )
  @Form([
    Field(
      'protocolMessage',
      String,
      'Protocol Message',
      hint:
          'OAuth2 AuthZ Request | Token Request | SAML AuthnRequest | OIDC Userinfo — protocol-level message',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Detailed description of what happens in this step',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? protocol;
}

/// 9.2.3. Password and Credential Policy.
///
/// Comprehensive password and credential policy aligned with NIST SP 800-63B
/// (Revision 4). Covers password requirements, storage, lifecycle, account
/// lockout, credential recovery, MFA enforcement per user category,
/// credential compromise detection, and service account credential management.
@StandardReferences(
  [
    'NIST SP 800-63B — memorized secret (password) requirements',
    'OWASP ASVS V2 — authentication verification requirements',
    'ISO/IEC 27001:2022 — control A.5.17 authentication information',
  ],
  'Captures the complete password and credential policy including storage, lifecycle, lockout, recovery, and MFA enforcement.',
)
@SectionId('PACP')
@CodeSpecKind([CodeSpecPart.authentication])
class PasswordAndCredentialPolicy extends DocSpecsSection {
  @ContentHelp('''
Define the complete password and credential policy. NIST SP 800-63B (2024
revision) emphasizes length over complexity and discourages forced rotation.

**Password requirements (NIST-aligned):**
- Minimum length: 8 characters (15+ recommended for privileged accounts)
- Maximum length: at least 64 characters
- No composition rules (uppercase, digits, symbols not required)
- Block common passwords (breach databases, dictionary words)
- Allow all Unicode characters and spaces

**Password storage:**
- Use modern password hashing: Argon2id, bcrypt, or scrypt
- Never store plaintext or reversibly encrypted passwords
- Implement secure comparison to prevent timing attacks

**Credential lifecycle:**
- No periodic expiration unless compromise is suspected
- Force reset on breach detection or password in known-compromised list
- Secure credential recovery (not security questions)

**Account lockout:**
- Throttle repeated failures (exponential backoff or CAPTCHA)
- Avoid hard lockouts that enable denial-of-service
- Log and alert on brute-force patterns

**MFA per user category:**
- Define which user categories require MFA
- Specify acceptable second factors per AAL level
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Password and Credential Policy Overview (text).
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Password Requirements.
  @SerializationOrder(2)
  PasswordRequirementsPolicy passwordRequirements =
      PasswordRequirementsPolicy();

  /// Password Storage and Verification.
  @SerializationOrder(3)
  PasswordStoragePolicy passwordStorage = PasswordStoragePolicy();

  /// Password Lifecycle.
  @SerializationOrder(4)
  PasswordLifecyclePolicy passwordLifecycle = PasswordLifecyclePolicy();

  /// Account Lockout and Throttling.
  @SerializationOrder(5)
  AccountLockoutPolicy accountLockout = AccountLockoutPolicy();

  /// Credential Recovery.
  @SerializationOrder(6)
  CredentialRecoveryPolicy credentialRecovery = CredentialRecoveryPolicy();

  /// Credential Compromise Detection.
  @SerializationOrder(7)
  CredentialCompromiseDetectionPolicy compromiseDetection =
      CredentialCompromiseDetectionPolicy();

  /// Service Account and API Credential Policy.
  @SerializationOrder(8)
  ServiceAccountCredentialPolicy serviceAccountCredentials =
      ServiceAccountCredentialPolicy();

  /// Contains 0+× MFA Enforcement per User Category.
  @StandardReferences([
    'NIST SP 800-63B — authenticator and verifier requirements',
  ], 'The catalog of multi-factor credential requirements per user category.')
  @SectionId('MFACRQ-MFAC-LST')
  @SectionIdPattern('MFACRQ-MFAC-xxx')
  @ContentHelp('Add one entry per MFA credential requirement.')
  @SerializationOrder(9)
  List<MfaCategoryRequirementEntry> mfaCategoryRequirements = [];
}

/// Password requirements policy (form).
///
/// Defines the rules for password creation, including length, complexity,
/// character set, and user guidance. Aligned with NIST SP 800-63B which
/// recommends length over complexity and prohibits composition rules.
@Form([
  Field(
    'minimumLengthSingleFactor',
    String,
    'Minimum Length Single Factor',
    hint:
        'Minimum password length when used as single factor (NIST: 15 characters)',
  ),
  Field(
    'minimumLengthMultiFactor',
    String,
    'Minimum Length Multi Factor',
    hint:
        'Minimum password length when used as part of MFA (NIST: 8 characters)',
  ),
  Field(
    'maximumLength',
    String,
    'Maximum Length',
    hint: 'Maximum allowed password length (NIST: at least 64 characters)',
  ),
  Field(
    'allowedCharacterSets',
    String,
    'Allowed Character Sets',
    hint:
        'ASCII | Unicode | ASCIIPlusSpace — character sets accepted in passwords',
  ),
  Field(
    'compositionRulesEnforced',
    String,
    'Composition Rules Enforced',
    hint:
        'Yes | No — whether mixed-case/digit/symbol rules are enforced (NIST: No)',
  ),
  Field(
    'passphraseSupported',
    String,
    'Passphrase Supported',
    hint: 'Yes | No — whether multi-word passphrases with spaces are supported',
  ),
  Field(
    'unicodeNormalization',
    String,
    'Unicode Normalization',
    hint:
        'NFC | NFD | None — Unicode normalization form applied before hashing',
  ),
  Field(
    'passwordBlocklistEnabled',
    String,
    'Password Blocklist Enabled',
    hint: 'Yes | No — whether passwords are compared against a blocklist',
  ),
  Field(
    'blocklistSources',
    String,
    'Blocklist Sources',
    hint:
        'BreachCorpus | DictionaryWords | ContextSpecific | HaveIBeenPwned — sources for blocklist',
  ),
  Field(
    'passwordStrengthMeter',
    String,
    'Password Strength Meter',
    hint:
        'Yes | No — whether a real-time strength indicator is displayed during creation',
  ),
  Field(
    'passwordHintsAllowed',
    String,
    'Password Hints Allowed',
    hint: 'Yes | No — whether password hints are stored (NIST: No)',
  ),
  Field(
    'securityQuestionsAllowed',
    String,
    'Security Questions Allowed',
    hint: 'Yes | No — whether KBA/security questions are used (NIST: No)',
  ),
  Field(
    'showPasswordOption',
    String,
    'Show Password Option',
    hint:
        'Yes | No — whether users can toggle password visibility during entry',
  ),
  Field(
    'passwordManagerSupport',
    String,
    'Password Manager Support',
    hint:
        'Yes | No — whether autofill and paste are supported for password entry',
  ),
  Field(
    'truncationPolicy',
    String,
    'Truncation Policy',
    hint:
        'None | Trim — whether leading/trailing whitespace is trimmed (NIST: verify entire password)',
  ),
  Field(
    'typoTolerancePolicy',
    String,
    'Typo Tolerance Policy',
    hint:
        'None | CaseFirstChar | TrimWhitespace — whether minor typo corrections are attempted',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — memorized secret (password) requirements',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines password creation rules including length, character set, blocklists, and user guidance.',
)
@SectionId('PRP')
@CodeSpecKind([CodeSpecPart.authentication])
class PasswordRequirementsPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Password Requirements Details (text).
  @SerializationOrder(1)
  TextSection passwordRequirementsDetails = TextSection();
}

/// Password storage and verification policy (form).
///
/// Defines how passwords are stored, hashed, salted, and verified.
/// Aligned with NIST SP 800-63B and OWASP password storage recommendations.
@Form([
  Field(
    'hashingAlgorithm',
    String,
    'Hashing Algorithm',
    hint: 'Argon2id | bcrypt | scrypt | PBKDF2 — password hashing algorithm',
  ),
  Field(
    'hashingCostFactor',
    String,
    'Hashing Cost Factor',
    hint:
        'Work factor/iteration count for the hashing algorithm (e.g., bcrypt cost 12)',
  ),
  Field(
    'costFactorReviewSchedule',
    String,
    'Cost Factor Review Schedule',
    hint:
        'Annual | Biannual | OnHardwareUpgrade — when cost factor is re-evaluated',
  ),
  Field(
    'saltLength',
    String,
    'Salt Length',
    hint: 'Minimum salt length in bits (NIST: at least 32 bits)',
  ),
  Field(
    'saltGeneration',
    String,
    'Salt Generation',
    hint: 'CryptoRandom | CSPRNG — method for generating salt values',
  ),
  Field(
    'pepperEnabled',
    String,
    'Pepper Enabled',
    hint:
        'Yes | No — whether a server-side secret key (pepper) is used for additional hashing',
  ),
  Field(
    'pepperStorage',
    String,
    'Pepper Storage',
    hint:
        'HSM | TEE | EncryptedConfig | SecretManager — where the pepper key is stored',
  ),
  Field(
    'hashVersioning',
    String,
    'Hash Versioning',
    hint:
        'Yes | No — whether the hash algorithm and cost factor are stored per password for migration',
  ),
  Field(
    'transmissionEncryption',
    String,
    'Transmission Encryption',
    hint: 'TLS1.3 | TLS1.2 — encryption for password transmission',
  ),
  Field(
    'clientSideHashing',
    String,
    'Client-Side Hashing',
    hint:
        'Yes | No — whether passwords are pre-hashed on the client before transmission',
  ),
  Field(
    'memoryHardFunction',
    String,
    'Memory-Hard Function',
    hint:
        'Yes | No — whether the hashing function is memory-hard to resist GPU attacks',
  ),
  Field(
    'outputLength',
    String,
    'Output Length',
    hint:
        'Hash output length in bits (should match underlying scheme output length)',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — memorized secret (password) requirements',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines how passwords are stored, hashed, salted, and verified against timing attacks.',
)
@SectionId('PSP')
@CodeSpecKind([CodeSpecPart.authentication])
class PasswordStoragePolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Password Storage Details (text).
  @SerializationOrder(1)
  TextSection passwordStorageDetails = TextSection();
}

/// Password lifecycle policy (form).
///
/// Defines the lifecycle of passwords: creation, rotation, expiry, and
/// history. NIST SP 800-63B recommends against periodic rotation and
/// only forces changes on evidence of compromise.
@Form([
  Field(
    'periodicRotationRequired',
    String,
    'Periodic Rotation Required',
    hint:
        'Yes | No — whether periodic password changes are required (NIST: No)',
  ),
  Field(
    'rotationPeriod',
    String,
    'Rotation Period',
    hint: 'If rotation is required: period in days (e.g., 90, 180, 365)',
  ),
  Field(
    'forceChangeOnCompromise',
    String,
    'Force Change On Compromise',
    hint:
        'Yes | No — whether password change is forced on evidence of compromise',
  ),
  Field(
    'passwordHistoryDepth',
    String,
    'Password History Depth',
    hint:
        'Number of previous passwords stored to prevent reuse (e.g., 0, 5, 12, 24)',
  ),
  Field(
    'minimumPasswordAge',
    String,
    'Minimum Password Age',
    hint:
        'Minimum time before a password can be changed again (e.g., 0, 1d) to prevent rapid cycling',
  ),
  Field(
    'initialPasswordPolicy',
    String,
    'Initial Password Policy',
    hint:
        'SystemGenerated | UserChosen | TemporaryWithForceChange — policy for initial passwords',
  ),
  Field(
    'temporaryPasswordExpiry',
    String,
    'Temporary Password Expiry',
    hint:
        'Duration before a temporary/initial password expires (e.g., 24h, 72h)',
  ),
  Field(
    'passwordExpiryWarning',
    String,
    'Password Expiry Warning',
    hint: 'Number of days before expiry that users are warned (e.g., 14, 30)',
  ),
  Field(
    'passwordChangeNotification',
    String,
    'Password Change Notification',
    hint:
        'Yes | No — whether users are notified when their password is changed',
  ),
  Field(
    'passwordChangeRequiresCurrent',
    String,
    'Password Change Requires Current',
    hint:
        'Yes | No — whether current password must be verified before setting a new one',
  ),
  Field(
    'administratorResetPolicy',
    String,
    'Administrator Reset Policy',
    hint:
        'TemporaryPassword | ResetLink | MfaVerification — how admins reset user passwords',
  ),
  Field(
    'passwordInactivityDisable',
    String,
    'Password Inactivity Disable',
    hint:
        'Duration of inactivity before account is disabled (e.g., 90d, 180d, Never)',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — memorized secret (password) requirements',
    'ISO/IEC 27001:2022 — control A.5.17 authentication information',
  ],
  'Defines the password lifecycle covering creation, rotation, expiry, and history.',
)
@SectionId('PLP')
@CodeSpecKind([CodeSpecPart.authentication])
class PasswordLifecyclePolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Password Lifecycle Details (text).
  @SerializationOrder(1)
  TextSection passwordLifecycleDetails = TextSection();
}

/// Account lockout and throttling policy (form).
///
/// Defines how failed authentication attempts are rate-limited and how
/// accounts are locked and unlocked. Aligned with NIST SP 800-63B
/// throttling requirements (max 100 consecutive failures).
@Form([
  Field(
    'lockoutThreshold',
    String,
    'Lockout Threshold',
    hint:
        'Number of consecutive failed attempts before lockout (NIST max: 100, typical: 5-10)',
  ),
  Field(
    'lockoutDuration',
    String,
    'Lockout Duration',
    hint:
        'Duration of lockout (e.g., 15min, 30min, UntilAdminUnlock, Progressive)',
  ),
  Field(
    'lockoutEscalation',
    String,
    'Lockout Escalation',
    hint:
        'Fixed | Progressive | Exponential — whether lockout duration increases',
  ),
  Field(
    'rateLimitingMethod',
    String,
    'Rate Limiting Method',
    hint:
        'Delay | CAPTCHA | Lockout | IPBlock | Combination — rate-limiting strategy',
  ),
  Field(
    'delayProgression',
    String,
    'Delay Progression',
    hint:
        'Delay schedule for progressive throttling (e.g., 30s after 3rd, 1min after 5th)',
  ),
  Field(
    'captchaTriggerThreshold',
    String,
    'CAPTCHA Trigger Threshold',
    hint: 'Number of failed attempts before CAPTCHA is required',
  ),
  Field(
    'ipBasedRateLimiting',
    String,
    'IP-Based Rate Limiting',
    hint: 'Yes | No — whether rate limiting also applies per IP address',
  ),
  Field(
    'distributedAttackProtection',
    String,
    'Distributed Attack Protection',
    hint:
        'Yes | No — whether protection against credential stuffing across IPs is implemented',
  ),
  Field(
    'unlockMechanism',
    String,
    'Unlock Mechanism',
    hint:
        'TimeBasedAutoUnlock | AdminUnlock | SelfServiceWithMFA | EmailVerification',
  ),
  Field(
    'failedAttemptResetOnSuccess',
    String,
    'Failed Attempt Reset On Success',
    hint:
        'Yes | No — whether the failed attempt counter resets after successful login',
  ),
  Field(
    'lockoutNotification',
    String,
    'Lockout Notification',
    hint: 'User | Admin | Both | None — who is notified when lockout occurs',
  ),
  Field(
    'permanentLockoutEnabled',
    String,
    'Permanent Lockout Enabled',
    hint:
        'Yes | No — whether accounts are permanently locked after extreme abuse',
  ),
  Field(
    'permanentLockoutThreshold',
    String,
    'Permanent Lockout Threshold',
    hint: 'Number of lockout cycles before permanent lock (e.g., 5, 10)',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — memorized secret (password) requirements',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines how failed authentication attempts are rate-limited and how accounts are locked and unlocked.',
)
@SectionId('ALP')
@CodeSpecKind([CodeSpecPart.authentication])
class AccountLockoutPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Account Lockout Details (text).
  @SerializationOrder(1)
  TextSection accountLockoutDetails = TextSection();
}

/// Credential recovery policy (form).
///
/// Defines how users recover access when they lose credentials, including
/// password reset flows, recovery codes, and identity re-verification.
@Form([
  Field(
    'passwordResetMethod',
    String,
    'Password Reset Method',
    hint:
        'EmailLink | SMSCode | SecurityQuestions | MfaVerification | AdminAssisted — how users reset passwords',
  ),
  Field(
    'resetLinkExpiry',
    String,
    'Reset Link Expiry',
    hint:
        'Duration before a password reset link expires (e.g., 15min, 1h, 24h)',
  ),
  Field(
    'resetLinkSingleUse',
    String,
    'Reset Link Single Use',
    hint: 'Yes | No — whether reset links can only be used once',
  ),
  Field(
    'resetRateLimiting',
    String,
    'Reset Rate Limiting',
    hint: 'Requests per period allowed (e.g., 3 per hour, 5 per day)',
  ),
  Field(
    'savedRecoveryCodesEnabled',
    String,
    'Saved Recovery Codes Enabled',
    hint:
        'Yes | No — whether one-time recovery codes are provided at enrollment',
  ),
  Field(
    'recoveryCodeCount',
    String,
    'Recovery Code Count',
    hint: 'Number of recovery codes generated (e.g., 8, 10, 16)',
  ),
  Field(
    'recoveryCodeFormat',
    String,
    'Recovery Code Format',
    hint: 'AlphaNumeric | NumericOnly | Words — format of recovery codes',
  ),
  Field(
    'issuedRecoveryCodeChannels',
    String,
    'Issued Recovery Code Channels',
    hint:
        'Email | SMS | PostalMail | InPerson — channels for sending issued recovery codes',
  ),
  Field(
    'recoveryCodeExpiry',
    String,
    'Recovery Code Expiry',
    hint:
        'Duration before issued recovery codes expire (NIST: 10min SMS, 24h email)',
  ),
  Field(
    'identityReverificationRequired',
    String,
    'Identity Reverification Required',
    hint:
        'Yes | No — whether identity re-verification is required for recovery at higher AALs',
  ),
  Field(
    'recoveryContactEnabled',
    String,
    'Recovery Contact Enabled',
    hint: 'Yes | No — whether a trusted contact can initiate recovery',
  ),
  Field(
    'multipleRecoveryAddresses',
    String,
    'Multiple Recovery Addresses',
    hint:
        'Yes | No — whether subscribers can register multiple recovery addresses (NIST: at least 2)',
  ),
  Field(
    'recoveryAuditLogging',
    String,
    'Recovery Audit Logging',
    hint: 'Yes | No — whether all recovery attempts are logged for audit',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — memorized secret (password) requirements',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines how users recover access when they lose credentials through reset flows and identity re-verification.',
)
@SectionId('CRP')
@CodeSpecKind([CodeSpecPart.authentication])
class CredentialRecoveryPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Credential Recovery Details (text).
  @SerializationOrder(1)
  TextSection credentialRecoveryDetails = TextSection();
}

/// Credential compromise detection policy (form).
///
/// Defines how compromised credentials are detected and how the system
/// responds, including breach database monitoring and proactive scanning.
@Form([
  Field(
    'breachDatabaseMonitoring',
    String,
    'Breach Database Monitoring',
    hint:
        'Yes | No — whether passwords are checked against known breach databases',
  ),
  Field(
    'breachDatabaseSource',
    String,
    'Breach Database Source',
    hint:
        'HaveIBeenPwned | Internal | CommercialFeed | Multiple — source of breach data',
  ),
  Field(
    'breachCheckFrequency',
    String,
    'Breach Check Frequency',
    hint:
        'AtCreation | AtLogin | Periodic | RealTime — when breach checks are performed',
  ),
  Field(
    'compromisedCredentialAction',
    String,
    'Compromised Credential Action',
    hint:
        'ForceChange | NotifyAndRecommend | DisableAccount — action when credential is found compromised',
  ),
  Field(
    'credentialStuffingDetection',
    String,
    'Credential Stuffing Detection',
    hint:
        'Yes | No — whether automated credential stuffing attacks are detected',
  ),
  Field(
    'stuffingDetectionMethod',
    String,
    'Stuffing Detection Method',
    hint:
        'BehaviorAnalysis | IPReputation | VelocityChecks | DeviceFingerprint — detection methods',
  ),
  Field(
    'darkWebMonitoring',
    String,
    'Dark Web Monitoring',
    hint:
        'Yes | No — whether organizational credentials are monitored on dark web',
  ),
  Field(
    'userCompromiseNotification',
    String,
    'User Compromise Notification',
    hint:
        'Email | InApp | Push | SMS — how users are notified of credential compromise',
  ),
  Field(
    'adminCompromiseAlerts',
    String,
    'Admin Compromise Alerts',
    hint:
        'Yes | No — whether administrators receive alerts for mass compromise events',
  ),
  Field(
    'compromiseResponseSla',
    String,
    'Compromise Response SLA',
    hint:
        'Time to force credential change after detection (e.g., Immediate, 24h, 72h)',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — memorized secret (password) requirements',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines how compromised credentials are detected via breach monitoring and how the system responds.',
)
@SectionId('CCDP')
@CodeSpecKind([CodeSpecPart.authentication])
class CredentialCompromiseDetectionPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Compromise Detection Details (text).
  @SerializationOrder(1)
  TextSection compromiseDetectionDetails = TextSection();
}

/// Service account and API credential policy (form).
///
/// Defines credential management for non-human identities: service accounts,
/// API keys, machine-to-machine tokens, and automation credentials.
@Form([
  Field(
    'serviceAccountPasswordPolicy',
    String,
    'Service Account Password Policy',
    hint:
        'AutoGenerated | ManagedByVault | CertificateBased — how service account credentials are managed',
  ),
  Field(
    'serviceAccountRotationPeriod',
    String,
    'Service Account Rotation Period',
    hint:
        'Rotation period for service account credentials (e.g., 30d, 90d, OnDemand)',
  ),
  Field(
    'apiKeyLifetime',
    String,
    'API Key Lifetime',
    hint: 'Maximum lifetime for API keys (e.g., 90d, 365d, NoExpiry)',
  ),
  Field(
    'apiKeyRotationPolicy',
    String,
    'API Key Rotation Policy',
    hint: 'Automatic | Manual | GracePeriodOverlap — how API keys are rotated',
  ),
  Field(
    'secretsManagementTool',
    String,
    'Secrets Management Tool',
    hint:
        'HashiCorpVault | AWSSecretsManager | AzureKeyVault | GCPSecretManager | None',
  ),
  Field(
    'machineToMachineAuth',
    String,
    'Machine-to-Machine Auth',
    hint:
        'OAuth2ClientCredentials | mTLS | JWTBearer | APIKey — authentication method',
  ),
  Field(
    'serviceAccountMfaRequired',
    String,
    'Service Account MFA Required',
    hint:
        'Yes | No — whether service accounts require MFA for interactive login',
  ),
  Field(
    'sharedCredentialProhibition',
    String,
    'Shared Credential Prohibition',
    hint: 'Yes | No — whether shared/group credentials are prohibited',
  ),
  Field(
    'credentialVaultIntegration',
    String,
    'Credential Vault Integration',
    hint:
        'Yes | No — whether application credentials are injected from a secrets vault at runtime',
  ),
  Field(
    'hardcodedCredentialDetection',
    String,
    'Hardcoded Credential Detection',
    hint:
        'Yes | No — whether CI/CD scans for hardcoded credentials in source code',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.17 authentication information',
    'OWASP ASVS V2 — authentication verification requirements',
  ],
  'Defines credential management for non-human identities such as service accounts, API keys, and machine tokens.',
)
@SectionId('SACP')
@CodeSpecKind([CodeSpecPart.authentication])
class ServiceAccountCredentialPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Service Account Credential Details (text).
  @SerializationOrder(1)
  TextSection serviceAccountDetails = TextSection();
}

/// An MFA enforcement per user category entry (form).
///
/// Defines MFA requirements for a specific user category, allowing
/// different authentication assurance levels per role or access tier.
@StandardReferences(
  [
    'NIST SP 800-63B — authenticator and verifier requirements',
    'ISO/IEC 29115 — entity authentication assurance framework',
  ],
  'Defines the MFA enforcement requirements for a specific user category and target assurance level.',
)
@SectionId('MFACRQ')
@CodeSpecKind([CodeSpecPart.authentication])
class MfaCategoryRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'userCategory',
      String,
      'User Category',
      required: true,
      hint:
          'Name of the user category (e.g., Administrator, Employee, Customer, Partner, API)',
    ),
    Field(
      'mfaRequired',
      String,
      'MFA Required',
      hint:
          'Yes | No | Conditional — whether MFA is required for this category',
    ),
    Field(
      'targetAal',
      String,
      'Target AAL',
      hint: 'AAL1 | AAL2 | AAL3 — target Authentication Assurance Level',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Allowed authenticators and phishing-resistance rules.
  @SectionId('MCREA')
  @StandardReferences(
    [
      'NIST SP 800-63B — authenticator and verifier requirements',
      'FIDO2 / W3C WebAuthn — phishing-resistant authentication',
    ],
    'Captures the allowed authenticator types and phishing-resistance rules for MFA credentials.',
  )
  @Form([
    Field(
      'allowedAuthenticatorTypes',
      String,
      'Allowed Authenticator Types',
      hint:
          'TOTP | WebAuthn | FIDO2 | SMS | Push | Passkey — allowed second-factor types',
    ),
    Field(
      'phishingResistanceRequired',
      String,
      'Phishing Resistance Required',
      hint:
          'Yes | No | Recommended — whether phishing-resistant authenticators are required',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? authenticators;

  /// Enrollment and remembered-device timing.
  @SectionId('MCRET')
  @StandardReferences(
    [
      'NIST SP 800-63B — authenticator and verifier requirements',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Captures MFA enrollment deadlines, grace periods, and remembered-device timing rules.',
  )
  @Form([
    Field(
      'mfaEnrollmentDeadline',
      String,
      'MFA Enrollment Deadline',
      hint:
          'Deadline or grace period for MFA enrollment (e.g., Immediate, 30d, 90d)',
    ),
    Field(
      'mfaGracePeriod',
      String,
      'MFA Grace Period',
      hint:
          'Period after enrollment deadline during which MFA is recommended but not enforced',
    ),
    Field(
      'rememberDeviceEnabled',
      String,
      'Remember Device Enabled',
      hint:
          'Yes | No — whether trusted device remembering can skip MFA temporarily',
    ),
    Field(
      'rememberDeviceDuration',
      String,
      'Remember Device Duration',
      hint: 'Duration the device is trusted (e.g., 7d, 30d, 90d)',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? timing;

  /// Fallback, timeouts, and rationale.
  @SectionId('MCREO')
  @StandardReferences(
    [
      'NIST SP 800-63B — authenticator and verifier requirements',
      'ISO/IEC 29115 — entity authentication assurance framework',
    ],
    'Captures MFA fallback mechanisms, reauthentication timeouts, and the rationale per user category.',
  )
  @Form([
    Field(
      'fallbackMechanismIfUnavailable',
      String,
      'Fallback If Unavailable',
      hint:
          'RecoveryCode | AdminAssist | Deny — fallback when primary MFA is unavailable',
    ),
    Field(
      'reauthenticationTimeout',
      String,
      'Reauthentication Timeout',
      hint:
          'Overall session timeout requiring re-authentication (NIST: AAL1=30d, AAL2=24h, AAL3=12h)',
    ),
    Field(
      'inactivityTimeout',
      String,
      'Inactivity Timeout',
      hint: 'Session inactivity timeout (NIST: AAL2=1h, AAL3=15min)',
    ),
    Field(
      'description',
      String,
      'Description',
      hint:
          'Description of MFA requirements and rationale for this user category',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? operations;
}

/// 9.2.4. Session Management.
///
/// Comprehensive session management policy covering session timeouts,
/// concurrent session control, session revocation, remember-me functionality,
/// session security hardening, and session lifecycle monitoring.
/// Aligned with OWASP Session Management Cheat Sheet and NIST SP 800-63B
/// session requirements by Authentication Assurance Level (AAL).
@StandardReferences(
  [
    'OWASP ASVS V3 — session management verification requirements',
    'NIST SP 800-63B — session management (reauthentication and timeout)',
  ],
  'Captures the comprehensive session management policy covering timeouts, concurrency, revocation, and hardening.',
)
@SectionId('SEMA')
@CodeSpecKind([CodeSpecPart.authentication])
class SessionManagement extends DocSpecsSection {
  @ContentHelp('''
Define session management policies that balance security with user experience.

**Session timeouts:**
- Idle timeout: 15–30 min for standard apps, 2–5 min for high-value operations
- Absolute timeout: 4–24 hours maximum session lifetime
- Re-authentication for sensitive actions (step-up authentication)

**Concurrent session control:**
- Maximum simultaneous sessions per user
- Behavior on new login: terminate oldest, deny new, or allow all
- Device binding and trusted device management

**Session revocation:**
- Immediate revocation on logout, password change, or admin action
- Token blacklisting or short-lived tokens with refresh rotation
- Propagation delay for distributed systems

**Remember-me / persistent sessions:**
- Extended validity with reduced privileges
- Device fingerprinting and anomaly detection
- Explicit user opt-in with clear security implications

**Session security hardening:**
- Secure cookie attributes: HttpOnly, Secure, SameSite=Lax/Strict
- Session ID rotation after authentication
- Protection against session fixation and hijacking

**Reference:**
- OWASP Session Management Cheat Sheet
- NIST SP 800-63B Section 7: Session Management
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Session Management Overview (text).
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Session Timeout Policy.
  @SerializationOrder(2)
  SessionTimeoutPolicy sessionTimeoutPolicy = SessionTimeoutPolicy();

  /// Concurrent Session Policy.
  @SerializationOrder(3)
  ConcurrentSessionPolicy concurrentSessionPolicy = ConcurrentSessionPolicy();

  /// Session Revocation Policy.
  @SerializationOrder(4)
  SessionRevocationPolicy sessionRevocationPolicy = SessionRevocationPolicy();

  /// Remember-Me and Persistent Session Policy.
  @SerializationOrder(5)
  RememberMePolicy rememberMePolicy = RememberMePolicy();

  /// Session Security Hardening Policy.
  @SerializationOrder(6)
  SessionSecurityPolicy sessionSecurityPolicy = SessionSecurityPolicy();

  /// Session Lifecycle Monitoring.
  @SerializationOrder(7)
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
  Field(
    'idleTimeoutDefault',
    String,
    'Default Idle Timeout',
    hint:
        'Duration of inactivity before session expires (e.g., 15min, 30min, 1h)',
  ),
  Field(
    'idleTimeoutHighValue',
    String,
    'Idle Timeout — High-Value Operations',
    hint: 'Shorter idle timeout for sensitive operations (e.g., 2min, 5min)',
  ),
  Field(
    'absoluteTimeout',
    String,
    'Absolute Session Timeout',
    hint: 'Maximum session duration regardless of activity (e.g., 4h, 8h, 24h)',
  ),
  Field(
    'renewalTimeout',
    String,
    'Session ID Renewal Timeout',
    hint:
        'Interval at which the session ID is transparently rotated (e.g., 15min, 30min)',
  ),
  Field(
    'idleTimeoutAal1',
    String,
    'Idle Timeout — AAL1',
    hint: 'Idle timeout for AAL1 sessions (NIST default: 30 days)',
  ),
  Field(
    'absoluteTimeoutAal1',
    String,
    'Absolute Timeout — AAL1',
    hint: 'Maximum session duration for AAL1 (NIST default: 30 days)',
  ),
  Field(
    'idleTimeoutAal2',
    String,
    'Idle Timeout — AAL2',
    hint: 'Idle timeout for AAL2 sessions (NIST default: 1 hour)',
  ),
  Field(
    'absoluteTimeoutAal2',
    String,
    'Absolute Timeout — AAL2',
    hint: 'Maximum session duration for AAL2 (NIST default: 24 hours)',
  ),
  Field(
    'idleTimeoutAal3',
    String,
    'Idle Timeout — AAL3',
    hint: 'Idle timeout for AAL3 sessions (NIST default: 15 minutes)',
  ),
  Field(
    'absoluteTimeoutAal3',
    String,
    'Absolute Timeout — AAL3',
    hint: 'Maximum session duration for AAL3 (NIST default: 12 hours)',
  ),
  Field(
    'timeoutEnforcement',
    String,
    'Timeout Enforcement',
    hint:
        'ServerSide | ClientSide | Both — where session timeout is enforced (server-side mandatory)',
  ),
  Field(
    'timeoutWarningEnabled',
    String,
    'Timeout Warning Enabled',
    hint: 'Yes | No — whether users receive a warning before session expiry',
  ),
  Field(
    'timeoutWarningLeadTime',
    String,
    'Timeout Warning Lead Time',
    hint: 'Time before expiry to show warning (e.g., 2min, 5min)',
  ),
  Field(
    'timeoutWarningAction',
    String,
    'Timeout Warning Action',
    hint:
        'ExtendSession | SaveDraft | RedirectToLogin — action offered to user',
  ),
  Field(
    'sessionExtensionAllowed',
    String,
    'Session Extension Allowed',
    hint: 'Yes | No | Limited — whether users can extend an expiring session',
  ),
  Field(
    'maxExtensions',
    String,
    'Maximum Session Extensions',
    hint:
        'Maximum number of consecutive session extensions (e.g., 3, unlimited)',
  ),
  Field(
    'gracePeriodAfterExpiry',
    String,
    'Grace Period After Expiry',
    hint: 'Brief window after expiry for saving work (e.g., 0s, 30s, 2min)',
  ),
])
@StandardReferences(
  [
    'OWASP ASVS V3 — session management verification requirements',
    'NIST SP 800-63B — session management (reauthentication and timeout)',
  ],
  'Defines idle, absolute, and renewal timeout parameters including per-AAL differentiation.',
)
@SectionId('STP')
@CodeSpecKind([CodeSpecPart.authentication])
class SessionTimeoutPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Session Timeout Details (text).
  @SerializationOrder(1)
  TextSection sessionTimeoutDetails = TextSection();
}

/// Concurrent session policy (form).
///
/// Defines how the application handles multiple simultaneous sessions
/// from the same user account, including limits, notifications, and
/// conflict resolution strategies.
@Form([
  Field(
    'concurrentSessionsAllowed',
    String,
    'Concurrent Sessions Allowed',
    hint:
        'Yes | No | Limited — whether multiple simultaneous sessions are permitted',
  ),
  Field(
    'maxConcurrentSessions',
    String,
    'Maximum Concurrent Sessions',
    hint:
        'Maximum number of active sessions per user (e.g., 1, 3, 5, unlimited)',
  ),
  Field(
    'concurrentSessionScope',
    String,
    'Concurrent Session Scope',
    hint:
        'PerAccount | PerDeviceType | PerApplication — scope for counting sessions',
  ),
  Field(
    'conflictResolution',
    String,
    'Session Conflict Resolution',
    hint:
        'TerminateOldest | TerminateNewest | DenyNew | AskUser — action when limit exceeded',
  ),
  Field(
    'sessionListVisible',
    String,
    'Session List Visible to User',
    hint: 'Yes | No — whether users can see a list of their active sessions',
  ),
  Field(
    'remoteTerminationEnabled',
    String,
    'Remote Termination Enabled',
    hint: 'Yes | No — whether users can terminate other sessions remotely',
  ),
  Field(
    'sessionDeviceInfo',
    String,
    'Session Device Information',
    hint:
        'IPAddress | DeviceType | Browser | Location | All — info shown per session',
  ),
  Field(
    'concurrentLoginNotification',
    String,
    'Concurrent Login Notification',
    hint:
        'None | Email | Push | InApp | All — notification when new session starts',
  ),
  Field(
    'suspiciousConcurrentLoginAction',
    String,
    'Suspicious Concurrent Login Action',
    hint:
        'Notify | RequireMFA | TerminateAll | LockAccount — action for suspicious simultaneous access',
  ),
  Field(
    'privilegedAccountSessionLimit',
    String,
    'Privileged Account Session Limit',
    hint:
        'Maximum sessions for admin/privileged accounts (typically stricter, e.g., 1)',
  ),
  Field(
    'crossDeviceSessionHandling',
    String,
    'Cross-Device Session Handling',
    hint:
        'Independent | Synchronized | SingleDevice — how sessions relate across devices',
  ),
])
@StandardReferences(
  [
    'OWASP ASVS V3 — session management verification requirements',
    'ISO/IEC 27001:2022 — control A.8.5 secure authentication',
  ],
  'Defines how multiple simultaneous sessions per account are limited, notified, and resolved.',
)
@SectionId('CSP')
@CodeSpecKind([CodeSpecPart.authentication])
class ConcurrentSessionPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Concurrent Session Details (text).
  @SerializationOrder(1)
  TextSection concurrentSessionDetails = TextSection();
}

/// Session revocation policy (form).
///
/// Defines how sessions are explicitly invalidated: logout behavior,
/// administrative termination, privilege change handling, and
/// bulk revocation scenarios.
@Form([
  Field(
    'logoutMechanism',
    String,
    'Logout Mechanism',
    hint:
        'ServerSideInvalidation | TokenBlacklist | CookieClear | All — how sessions are terminated',
  ),
  Field(
    'logoutButtonPlacement',
    String,
    'Logout Button Placement',
    hint:
        'Header | Menu | Both | EveryPage — where the logout action is accessible',
  ),
  Field(
    'logoutConfirmation',
    String,
    'Logout Confirmation',
    hint:
        'Immediate | ConfirmDialog | None — whether logout requires confirmation',
  ),
  Field(
    'postLogoutRedirect',
    String,
    'Post-Logout Redirect',
    hint:
        'LoginPage | HomePage | GoodbyePage | CustomUrl — where users go after logout',
  ),
  Field(
    'postLogoutCacheClear',
    String,
    'Post-Logout Cache Clear',
    hint: 'Yes | No — whether Clear-Site-Data header is sent on logout',
  ),
  Field(
    'singleLogoutEnabled',
    String,
    'Single Logout (SLO) Enabled',
    hint:
        'Yes | No — whether logout propagates to all connected IdPs and services',
  ),
  Field(
    'singleLogoutProtocol',
    String,
    'Single Logout Protocol',
    hint: 'FrontChannel | BackChannel | Both — SLO propagation method',
  ),
  Field(
    'privilegeChangeRevocation',
    String,
    'Session Revocation on Privilege Change',
    hint:
        'Regenerate | Terminate | NoAction — session handling when user roles change',
  ),
  Field(
    'passwordChangeRevocation',
    String,
    'Session Revocation on Password Change',
    hint:
        'TerminateAll | TerminateOthers | KeepCurrent — session handling after password change',
  ),
  Field(
    'compromiseRevocation',
    String,
    'Session Revocation on Compromise Detection',
    hint:
        'TerminateAll | TerminateOthers | RequireReauth — action when account compromise suspected',
  ),
  Field(
    'adminTerminationEnabled',
    String,
    'Admin Session Termination Enabled',
    hint: 'Yes | No — whether administrators can terminate user sessions',
  ),
  Field(
    'bulkRevocationEnabled',
    String,
    'Bulk Session Revocation Enabled',
    hint:
        'Yes | No — whether mass session invalidation is supported (e.g., security incident)',
  ),
  Field(
    'revocationPropagationDelay',
    String,
    'Revocation Propagation Delay',
    hint:
        'Immediate | EventualConsistency | MaxDelay — how quickly revocation takes effect across nodes',
  ),
])
@StandardReferences(
  [
    'OWASP ASVS V3 — session management verification requirements',
    'NIST SP 800-63B — session management (reauthentication and timeout)',
  ],
  'Defines how sessions are explicitly invalidated on logout, privilege change, and bulk revocation.',
)
@SectionId('SRP')
@CodeSpecKind([CodeSpecPart.authentication])
class SessionRevocationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Session Revocation Details (text).
  @SerializationOrder(1)
  TextSection sessionRevocationDetails = TextSection();
}

/// Remember-me and persistent session policy (form).
///
/// Defines the remember-me (persistent login) functionality, device trust,
/// and long-lived session token management. Persistent sessions trade
/// security for convenience and must be carefully scoped.
@Form([
  Field(
    'rememberMeEnabled',
    String,
    'Remember-Me Enabled',
    hint: 'Yes | No — whether remember-me / keep-me-signed-in is offered',
  ),
  Field(
    'rememberMeDuration',
    String,
    'Remember-Me Duration',
    hint: 'Duration of persistent session (e.g., 7d, 30d, 90d)',
  ),
  Field(
    'rememberMeTokenType',
    String,
    'Remember-Me Token Type',
    hint:
        'PersistentCookie | DeviceToken | RefreshToken — mechanism for persistent login',
  ),
  Field(
    'rememberMeTokenStorage',
    String,
    'Remember-Me Token Storage',
    hint:
        'HttpOnlyCookie | SecureStorage | EncryptedLocalStorage — client-side storage',
  ),
  Field(
    'rememberMeTokenRotation',
    String,
    'Remember-Me Token Rotation',
    hint: 'Yes | No — whether persistent tokens are rotated on each use',
  ),
  Field(
    'rememberMeReuseDetection',
    String,
    'Remember-Me Reuse Detection',
    hint:
        'Yes | No — whether reuse of old persistent tokens triggers revocation',
  ),
  Field(
    'rememberMeDeviceBinding',
    String,
    'Remember-Me Device Binding',
    hint:
        'None | Fingerprint | CertificateBound — how persistent tokens are bound to devices',
  ),
  Field(
    'rememberMeRevocation',
    String,
    'Remember-Me Revocation',
    hint:
        'ManualOnly | OnPasswordChange | OnSecurityEvent | All — when persistent tokens are revoked',
  ),
  Field(
    'rememberMeAalReduction',
    String,
    'Remember-Me AAL Reduction',
    hint:
        'Yes | No — whether remember-me reduces effective AAL (e.g., AAL2 to AAL1)',
  ),
  Field(
    'rememberMeRestrictedOperations',
    String,
    'Restricted Operations with Remember-Me',
    hint:
        'Operations requiring full reauthentication even with active remember-me (e.g., password change, payment)',
  ),
  Field(
    'trustedDeviceManagement',
    String,
    'Trusted Device Management',
    hint:
        'Yes | No — whether users can manage a list of trusted/remembered devices',
  ),
  Field(
    'maxTrustedDevices',
    String,
    'Maximum Trusted Devices',
    hint: 'Maximum number of devices in the trusted device list (e.g., 5, 10)',
  ),
  Field(
    'trustedDeviceExpiry',
    String,
    'Trusted Device Expiry',
    hint: 'Duration a device stays trusted (e.g., 30d, 90d, indefinite)',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-63B — session management (reauthentication and timeout)',
    'OWASP ASVS V3 — session management verification requirements',
  ],
  'Defines remember-me persistent login, device trust, and long-lived session token management.',
)
@SectionId('RMP')
@CodeSpecKind([CodeSpecPart.authentication])
class RememberMePolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Remember-Me Policy Details (text).
  @SerializationOrder(1)
  TextSection rememberMeDetails = TextSection();
}

/// Session security hardening policy (form).
///
/// Defines session fixation protection, session binding to user properties,
/// session anomaly detection, and content caching policies.
/// Aligned with OWASP Session Management Cheat Sheet recommendations.
@Form([
  Field(
    'sessionFixationProtection',
    String,
    'Session Fixation Protection',
    hint:
        'RegenerateOnLogin | RegenerateOnPrivilegeChange | Both — session ID regeneration strategy',
  ),
  Field(
    'sessionIdRegenerationTriggers',
    String,
    'Session ID Regeneration Triggers',
    hint:
        'Login | PrivilegeChange | PasswordChange | MfaStep | All — events triggering session ID renewal',
  ),
  Field(
    'sessionBindingProperties',
    String,
    'Session Binding Properties',
    hint:
        'None | IPAddress | UserAgent | DeviceFingerprint | TlsCertificate — properties bound to session',
  ),
  Field(
    'bindingMismatchAction',
    String,
    'Binding Mismatch Action',
    hint:
        'Terminate | RequireReauth | LogAndContinue | StepUpAuth — action on session binding violation',
  ),
  Field(
    'sessionAnomalyDetection',
    String,
    'Session Anomaly Detection',
    hint:
        'Yes | No — whether session anomalies (IP change, user-agent change) are monitored',
  ),
  Field(
    'anomalyDetectionSignals',
    String,
    'Anomaly Detection Signals',
    hint:
        'IPChange | UserAgentChange | GeoLocationJump | ConcurrentAccess — signals monitored',
  ),
  Field(
    'sessionCachePolicy',
    String,
    'Session Cache Policy',
    hint:
        'NoStore | NoCache | Private — Cache-Control directive for pages with session data',
  ),
  Field(
    'clearSiteDataOnLogout',
    String,
    'Clear-Site-Data on Logout',
    hint:
        'Yes | No — whether Clear-Site-Data header clears cache, cookies, storage on logout',
  ),
  Field(
    'sessionTransportSecurity',
    String,
    'Session Transport Security',
    hint:
        'HttpsOnly | HstsEnabled | CertificatePinning — transport layer requirements for sessions',
  ),
  Field(
    'sessionIdInUrlPrevention',
    String,
    'Session ID in URL Prevention',
    hint:
        'Yes | No — whether session IDs in URL parameters are explicitly blocked',
  ),
  Field(
    'crossOriginSessionProtection',
    String,
    'Cross-Origin Session Protection',
    hint:
        'SameSiteCookies | CorsRestriction | Both — cross-origin session protection mechanisms',
  ),
  Field(
    'sessionDataMinimization',
    String,
    'Session Data Minimization',
    hint:
        'Yes | No — whether session stores only essential data (minimize sensitive data in session)',
  ),
])
@StandardReferences(
  [
    'OWASP ASVS V3 — session management verification requirements',
    'ISO/IEC 27001:2022 — control A.8.5 secure authentication',
  ],
  'Defines session fixation protection, session binding, anomaly detection, and transport hardening.',
)
@SectionId('SSP')
@CodeSpecKind([CodeSpecPart.authentication])
class SessionSecurityPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Session Security Details (text).
  @SerializationOrder(1)
  TextSection sessionSecurityDetails = TextSection();
}

/// Session lifecycle monitoring (form).
///
/// Defines how session events are logged, monitored, and audited
/// throughout the session lifecycle: creation, usage, renewal,
/// and destruction.
@Form([
  Field(
    'sessionCreationLogging',
    String,
    'Session Creation Logging',
    hint: 'Yes | No — whether session creation events are logged',
  ),
  Field(
    'sessionDestructionLogging',
    String,
    'Session Destruction Logging',
    hint: 'Yes | No — whether session termination events are logged',
  ),
  Field(
    'sessionRenewalLogging',
    String,
    'Session Renewal Logging',
    hint: 'Yes | No — whether session ID renewal events are logged',
  ),
  Field(
    'sessionEventDetails',
    String,
    'Session Event Details',
    hint:
        'Timestamp | SourceIP | UserAgent | GeoLocation | SessionAction — details captured per event',
  ),
  Field(
    'sessionIdInLogs',
    String,
    'Session ID in Logs',
    hint:
        'SaltedHash | Truncated | Never — how session IDs appear in logs (never in plaintext)',
  ),
  Field(
    'sessionActivityTracking',
    String,
    'Session Activity Tracking',
    hint:
        'Yes | No — whether per-session activity (page visits, actions) is tracked',
  ),
  Field(
    'sessionHistoryVisibleToUser',
    String,
    'Session History Visible to User',
    hint: 'Yes | No — whether users can view their session activity history',
  ),
  Field(
    'failedSessionAccessLogging',
    String,
    'Failed Session Access Logging',
    hint:
        'Yes | No — whether invalid/expired session access attempts are logged',
  ),
  Field(
    'sessionMetricsCollection',
    String,
    'Session Metrics Collection',
    hint:
        'Yes | No — whether session duration, count, and patterns are collected as metrics',
  ),
  Field(
    'sessionAuditRetention',
    String,
    'Session Audit Log Retention',
    hint: 'Duration session audit logs are retained (e.g., 90d, 1y, 7y)',
  ),
  Field(
    'realTimeSessionAlerts',
    String,
    'Real-Time Session Alerts',
    hint:
        'Yes | No — whether suspicious session events trigger real-time alerts',
  ),
  Field(
    'alertTriggers',
    String,
    'Session Alert Triggers',
    hint:
        'BruteForce | AnomalousAccess | MassLogout | SessionHijack — events triggering alerts',
  ),
])
@StandardReferences(
  [
    'OWASP ASVS V3 — session management verification requirements',
    'NIST SP 800-63B — session management (reauthentication and timeout)',
  ],
  'Defines how session events are logged, monitored, and audited across the full session lifecycle.',
)
@SectionId('SLM')
@CodeSpecKind([CodeSpecPart.auditLog])
class SessionLifecycleMonitoring extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Session Lifecycle Monitoring Details (text).
  @SerializationOrder(1)
  TextSection sessionLifecycleDetails = TextSection();
}

/// 9.3. Resource Protection.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
    'OWASP API Security Top 10 — 2023 edition',
    'NIST SP 800-53 — control AC-3 access enforcement',
  ],
  'Ensures authenticated and authorized users can only access the specific data, API, and file resources they are entitled to.',
)
@SectionId('RESPRO')
@DetailedIn(D08SecurityAccessSpecification)
@CodeSpecKind([CodeSpecPart.authorization])
class ResourceProtection extends DocSpecsSection {
  @ContentHelp('''
Overview of resource protection strategies covering data, APIs, and file
storage. Resource protection ensures that authenticated and authorized users
can only access the specific resources they are entitled to.

**Resource categories:**
- **Data**: Database records, tenant data, PII, business-critical information
- **APIs**: REST/GraphQL endpoints, internal services, webhooks
- **Files**: User uploads, documents, media, configuration files

**Protection layers:**
1. Network layer: firewalls, WAF, DDoS protection
2. Transport layer: TLS encryption, certificate validation
3. Application layer: authentication, authorization, input validation
4. Data layer: encryption at rest, row/column-level security, masking

**Defense in depth:**
- Multiple overlapping controls at each layer
- Fail-secure defaults (deny access on error)
- Principle of least privilege for all access
- Continuous monitoring and anomaly detection

**Compliance alignment:**
- OWASP Top 10 and API Security Top 10
- PCI DSS requirements for cardholder data
- GDPR requirements for personal data protection
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.3.1. Data-Level Security.
  @SerializationOrder(1)
  DataLevelSecurity dataLevelSecurity = DataLevelSecurity();

  /// 9.3.2. API Security.
  @SerializationOrder(2)
  ApiSecurity apiSecurity = ApiSecurity();

  /// 9.3.3. File and Storage Security.
  @SerializationOrder(3)
  FileAndStorageSecurity fileAndStorageSecurity = FileAndStorageSecurity();
}

/// 9.3.1. Data-Level Security.
///
/// Comprehensive data access protection specification covering database-level
/// security, row-level security, column-level security, tenant data isolation,
/// and data masking for production and non-production environments.
/// Aligned with OWASP Database Security Cheat Sheet and least-privilege principles.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
    'NIST SP 800-53 — control AC-3 access enforcement',
    'ISO/IEC 27001:2022 — control A.5.12 classification of information',
  ],
  'Covers data-level protection including database access, row and column-level security, tenant isolation, and masking.',
)
@SectionId('DALESE')
@CodeSpecKind([CodeSpecPart.authorization])
class DataLevelSecurity extends DocSpecsSection {
  @ContentHelp('''
Define data-level security controls that protect sensitive information
within databases and data stores.

**Database access controls:**
- Application uses dedicated service accounts with minimal privileges
- No shared credentials; secrets managed via vault or managed identities
- Separation of read and write access where appropriate

**Row-Level Security (RLS):**
- Automatic filtering of queries based on user context (tenant, ownership)
- Implemented at database level (PostgreSQL RLS, SQL Server RLS)
- Or enforced at ORM/application layer with mandatory predicates

**Column-Level Security:**
- Sensitive columns encrypted or masked at database level
- Dynamic masking for non-privileged users (shown as ****)
- Tokenization for PCI data (card numbers, CVV)

**Tenant data isolation:**
- Strict segregation for multi-tenant applications
- Separate schemas, row-level predicates, or separate databases
- Cross-tenant access explicitly denied by default

**Data masking:**
- Production data never copied to non-production unmasked
- Dynamic masking for support/debug access
- Pseudonymization for analytics and testing

**Audit logging:**
- Log all data access to sensitive tables
- Capture user identity, timestamp, query, affected rows
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Data-Level Security Overview (text).
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Database Access Policy.
  @SerializationOrder(2)
  DatabaseAccessPolicy databaseAccessPolicy = DatabaseAccessPolicy();

  /// Row-Level Security Policy.
  @SerializationOrder(3)
  RowLevelSecurityPolicy rowLevelSecurityPolicy = RowLevelSecurityPolicy();

  /// Column-Level Security Policy.
  @SerializationOrder(4)
  ColumnLevelSecurityPolicy columnLevelSecurityPolicy =
      ColumnLevelSecurityPolicy();

  /// Tenant Data Isolation Policy.
  @SerializationOrder(5)
  TenantDataIsolationPolicy tenantDataIsolationPolicy =
      TenantDataIsolationPolicy();

  /// Data Masking Policy.
  @SerializationOrder(6)
  DataMaskingPolicy dataMaskingPolicy = DataMaskingPolicy();

  /// Data Access Audit Policy.
  @SerializationOrder(7)
  DataAccessAuditPolicy dataAccessAuditPolicy = DataAccessAuditPolicy();
}

/// Database access policy (form).
///
/// Defines how application and administrative accounts access the database,
/// including connection security, credential management, and privilege
/// assignment following the principle of least privilege.
@Form([
  Field(
    'databaseConnectionSecurity',
    String,
    'Database Connection Security',
    hint:
        'TlsRequired | TlsOptional | LocalSocketOnly — transport security for DB connections',
  ),
  Field(
    'minimumTlsVersion',
    String,
    'Minimum TLS Version',
    hint: 'TLS 1.2 | TLS 1.3 — minimum TLS version for database connections',
  ),
  Field(
    'applicationAccountStrategy',
    String,
    'Application Account Strategy',
    hint:
        'PerService | PerModule | SharedPool — how application-level DB accounts are organized',
  ),
  Field(
    'applicationAccountPrivileges',
    String,
    'Application Account Privileges',
    hint:
        'SelectUpdateDelete | ReadOnly | Custom — default permissions for application accounts',
  ),
  Field(
    'schemaOwnershipSeparation',
    String,
    'Schema Ownership Separation',
    hint:
        'Yes | No — whether schema owner accounts are separate from application accounts',
  ),
  Field(
    'directTableAccess',
    String,
    'Direct Table Access',
    hint:
        'Allowed | ViewsOnly | StoredProceduresOnly — whether direct table access is permitted',
  ),
  Field(
    'databaseCredentialStorage',
    String,
    'Database Credential Storage',
    hint:
        'SecretsVault | EnvironmentVariable | EncryptedConfig — where DB credentials are stored',
  ),
  Field(
    'credentialRotationPolicy',
    String,
    'Credential Rotation Policy',
    hint:
        'Automatic | Manual | Interval — how DB credentials are rotated (e.g., every 90d)',
  ),
  Field(
    'connectionPoolSecurity',
    String,
    'Connection Pool Security',
    hint: 'PerUser | PerService | Shared — connection pool isolation level',
  ),
  Field(
    'privilegedAccessManagement',
    String,
    'Privileged Access Management',
    hint:
        'JustInTime | PermanentWithApproval | BreakGlass — how DBA access is managed',
  ),
  Field(
    'databaseFirewallRules',
    String,
    'Database Firewall Rules',
    hint:
        'AllowlistOnly | VpcInternal | SubnetRestricted — network access restrictions',
  ),
  Field(
    'sqlInjectionPrevention',
    String,
    'SQL Injection Prevention',
    hint:
        'ParameterizedQueries | OrmOnly | PreparedStatements — SQL injection mitigation strategy',
  ),
  Field(
    'queryComplexityLimits',
    String,
    'Query Complexity Limits',
    hint:
        'Yes | No — whether query complexity or execution time limits are enforced',
  ),
  Field(
    'databaseActivityMonitoring',
    String,
    'Database Activity Monitoring',
    hint:
        'DamEnabled | NativeAudit | None — database activity monitoring tool usage',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
    'NIST SP 800-53 — control AC-3 access enforcement',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
  ],
  'Defines how database accounts, credentials, and privileged access are controlled and how queries are protected from injection.',
)
@SectionId('DAP')
@CodeSpecKind([CodeSpecPart.authorization])
class DatabaseAccessPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Database Access Policy Details (text).
  @SerializationOrder(1)
  TextSection databaseAccessDetails = TextSection();
}

/// Row-level security policy (form).
///
/// Defines how data access is restricted at the row level, ensuring users
/// can only access data rows they are authorized to see. Covers tenant-based
/// filtering, user-scoped access, and hierarchical data visibility.
@Form([
  Field(
    'rowLevelSecurityEnabled',
    String,
    'Row-Level Security Enabled',
    hint: 'Yes | No — whether row-level security (RLS) is implemented',
  ),
  Field(
    'rlsImplementation',
    String,
    'RLS Implementation',
    hint:
        'DatabaseNative | ApplicationLayer | OrmFilter | Hybrid — where RLS is enforced',
  ),
  Field(
    'rlsFilteringStrategy',
    String,
    'RLS Filtering Strategy',
    hint:
        'TenantId | UserId | OrganizationId | CustomPredicate — primary filtering dimension',
  ),
  Field(
    'rlsBypassPolicy',
    String,
    'RLS Bypass Policy',
    hint:
        'NeverBypass | SuperAdminOnly | ServiceAccountOnly — who can bypass RLS',
  ),
  Field(
    'hierarchicalVisibility',
    String,
    'Hierarchical Data Visibility',
    hint:
        'Yes | No — whether managers see subordinate data (organizational hierarchy)',
  ),
  Field(
    'hierarchyDepthLimit',
    String,
    'Hierarchy Depth Limit',
    hint:
        'Unlimited | DirectReports | NLevels — how deep hierarchical visibility extends',
  ),
  Field(
    'crossTenantAccess',
    String,
    'Cross-Tenant Data Access',
    hint:
        'Denied | PlatformAdminOnly | ConsentBased — cross-tenant data access rules',
  ),
  Field(
    'dataOwnerAccess',
    String,
    'Data Owner Access',
    hint:
        'FullAccess | ReadOnly | Delegated — access level for the data owner/creator',
  ),
  Field(
    'sharedDataHandling',
    String,
    'Shared Data Handling',
    hint:
        'ExplicitGrant | GroupBased | LinkSharing — how shared records are authorized',
  ),
  Field(
    'rlsPerformanceStrategy',
    String,
    'RLS Performance Strategy',
    hint:
        'IndexedFilterColumn | PartitionedByTenant | MaterializedViews — performance optimization for RLS',
  ),
  Field(
    'rlsTestingStrategy',
    String,
    'RLS Testing Strategy',
    hint:
        'AutomatedTests | PenetrationTesting | Both — how RLS enforcement is verified',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control AC-3 access enforcement',
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
  ],
  'Defines how data access is restricted at the row level so users can only see records they are authorized to view.',
)
@SectionId('RLSP')
@CodeSpecKind([CodeSpecPart.authorization])
class RowLevelSecurityPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Row-Level Security Details (text).
  @SerializationOrder(1)
  TextSection rowLevelSecurityDetails = TextSection();
}

/// Column-level security policy (form).
///
/// Defines how access to specific data columns or fields is restricted
/// based on user roles, sensitivity classification, or regulatory requirements.
@Form([
  Field(
    'columnLevelSecurityEnabled',
    String,
    'Column-Level Security Enabled',
    hint: 'Yes | No — whether column-level access control is implemented',
  ),
  Field(
    'columnAccessImplementation',
    String,
    'Column Access Implementation',
    hint:
        'DatabaseGrants | ViewRestriction | ApplicationLayer | FieldProjection — enforcement mechanism',
  ),
  Field(
    'sensitiveColumnClassification',
    String,
    'Sensitive Column Classification',
    hint:
        'PII | Financial | Health | Confidential | Internal | Public — classification scheme for columns',
  ),
  Field(
    'piiColumnAccess',
    String,
    'PII Column Access',
    hint:
        'RestrictedByRole | MaskedByDefault | EncryptedAtRest — access policy for PII columns',
  ),
  Field(
    'financialDataColumnAccess',
    String,
    'Financial Data Column Access',
    hint:
        'RestrictedByRole | AuditedAccess | Masked — access policy for financial data columns',
  ),
  Field(
    'healthDataColumnAccess',
    String,
    'Health Data Column Access',
    hint:
        'HipaaCompliant | StrictRole | Encrypted — access policy for health/medical data',
  ),
  Field(
    'dynamicFieldVisibility',
    String,
    'Dynamic Field Visibility',
    hint:
        'Yes | No — whether field visibility varies dynamically based on user role or context',
  ),
  Field(
    'columnAccessAudit',
    String,
    'Column Access Audit',
    hint:
        'Yes | No — whether access to sensitive columns is individually audited',
  ),
  Field(
    'columnEncryptionPolicy',
    String,
    'Column Encryption Policy',
    hint:
        'None | SelectedColumns | AllSensitive | AlwaysEncrypted — column-level encryption approach',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control AC-3 access enforcement',
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
    'ISO/IEC 27001:2022 — control A.5.12 classification of information',
  ],
  'Defines how access to specific data columns or fields is restricted by role, sensitivity classification, or regulation.',
)
@SectionId('CLSP')
@CodeSpecKind([CodeSpecPart.authorization])
class ColumnLevelSecurityPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Column-Level Security Details (text).
  @SerializationOrder(1)
  TextSection columnLevelSecurityDetails = TextSection();
}

/// Tenant data isolation policy (form).
///
/// Defines the multi-tenant data separation strategy, ensuring tenant
/// data is logically or physically isolated and cannot leak between tenants.
@Form([
  Field(
    'tenantIsolationModel',
    String,
    'Tenant Isolation Model',
    hint:
        'SharedDatabase_SharedSchema | SharedDatabase_SeparateSchema | SeparateDatabase — multi-tenancy architecture',
  ),
  Field(
    'tenantIdentifierColumn',
    String,
    'Tenant Identifier Column',
    hint: 'Column name used for tenant filtering (e.g., tenant_id, org_id)',
  ),
  Field(
    'tenantContextInjection',
    String,
    'Tenant Context Injection',
    hint:
        'SessionVariable | ConnectionString | MiddlewareFilter | RowPolicy — how tenant context is set',
  ),
  Field(
    'tenantIsolationEnforcement',
    String,
    'Tenant Isolation Enforcement',
    hint:
        'DatabaseLevel | ApplicationLevel | Both — where isolation is enforced',
  ),
  Field(
    'crossTenantQueryPrevention',
    String,
    'Cross-Tenant Query Prevention',
    hint:
        'DatabaseRLS | QueryRewriting | GlobalFilter | AllLayers — how cross-tenant queries are blocked',
  ),
  Field(
    'tenantDataBackupIsolation',
    String,
    'Tenant Data Backup Isolation',
    hint:
        'SharedBackup | PerTenantBackup | EncryptedShared — tenant-specific backup strategy',
  ),
  Field(
    'tenantDataDeletion',
    String,
    'Tenant Data Deletion',
    hint:
        'SoftDelete | HardDelete | CryptoShredding — how tenant data is removed on offboarding',
  ),
  Field(
    'tenantDataExport',
    String,
    'Tenant Data Export',
    hint:
        'SelfService | AdminAssisted | ApiExport — data portability for tenants',
  ),
  Field(
    'tenantResourceQuotas',
    String,
    'Tenant Resource Quotas',
    hint: 'Yes | No — whether storage/query quotas are enforced per tenant',
  ),
  Field(
    'tenantIsolationTesting',
    String,
    'Tenant Isolation Testing',
    hint:
        'AutomatedTests | PenetrationTesting | Both — how tenant isolation is verified',
  ),
  Field(
    'sharedReferenceDataAccess',
    String,
    'Shared Reference Data Access',
    hint:
        'ReadOnly | CachedLocally | Replicated — how tenants access shared/global reference data',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
    'NIST SP 800-53 — control AC-3 access enforcement',
    'ISO/IEC 27001:2022 — control A.8.10 information deletion',
  ],
  'Defines how each tenant data is isolated, exported, and removed so that one tenant cannot access another tenant records.',
)
@SectionId('TDIP')
@CodeSpecKind([CodeSpecPart.authorization])
class TenantDataIsolationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Tenant Data Isolation Details (text).
  @SerializationOrder(1)
  TextSection tenantDataIsolationDetails = TextSection();
}

/// Data masking policy (form).
///
/// Defines how sensitive data is masked or obfuscated for non-production
/// environments, reporting, and limited-access scenarios. Covers both
/// static masking (data copies) and dynamic masking (runtime filtering).
@Form([
  Field(
    'dynamicDataMaskingEnabled',
    String,
    'Dynamic Data Masking Enabled',
    hint:
        'Yes | No — whether dynamic data masking is implemented in production',
  ),
  Field(
    'dynamicMaskingRules',
    String,
    'Dynamic Masking Rules',
    hint:
        'FullMask | PartialMask | Redact | Tokenize — available masking transformations',
  ),
  Field(
    'dynamicMaskingScope',
    String,
    'Dynamic Masking Scope',
    hint:
        'RoleBased | QueryBased | ColumnBased — how masking rules are applied',
  ),
  Field(
    'staticMaskingForNonProduction',
    String,
    'Static Masking for Non-Production',
    hint:
        'Yes | No — whether production data is statically masked before copying to test/dev',
  ),
  Field(
    'staticMaskingTool',
    String,
    'Static Masking Tool',
    hint:
        'BuiltIn | ThirdParty | CustomScript — tool used for static data masking',
  ),
  Field(
    'maskingPreservesFormat',
    String,
    'Masking Preserves Format',
    hint:
        'Yes | No — whether masked data maintains original format and referential integrity',
  ),
  Field(
    'maskingReversibility',
    String,
    'Masking Reversibility',
    hint:
        'Irreversible | Tokenized | Deterministic — whether masking can be reversed',
  ),
  Field(
    'piiMaskingPolicy',
    String,
    'PII Masking Policy',
    hint:
        'FullRedact | PartialMask | Pseudonymize — specific masking approach for PII fields',
  ),
  Field(
    'emailMaskingFormat',
    String,
    'Email Masking Format',
    hint:
        'e.g., j***@example.com or completely redacted — how email addresses are masked',
  ),
  Field(
    'phoneMaskingFormat',
    String,
    'Phone Masking Format',
    hint: 'e.g., ***-***-1234 or fully redacted — how phone numbers are masked',
  ),
  Field(
    'addressMaskingFormat',
    String,
    'Address Masking Format',
    hint: 'CityOnly | ZipCodeOnly | FullRedact — how addresses are masked',
  ),
  Field(
    'financialDataMasking',
    String,
    'Financial Data Masking',
    hint:
        'FullRedact | Last4Digits | Tokenized — how financial data (credit cards, bank accounts) is masked',
  ),
  Field(
    'maskingAuditTrail',
    String,
    'Masking Audit Trail',
    hint: 'Yes | No — whether masking/unmasking operations are audited',
  ),
  Field(
    'developmentDataStrategy',
    String,
    'Development Data Strategy',
    hint:
        'MaskedCopy | SyntheticData | SubsetExtract | SeedData — strategy for development/test environments',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.8.11 data masking',
    'NIST SP 800-53 — control SC-28 protection of information at rest',
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
  ],
  'Defines how sensitive data is masked or obfuscated for non-production, reporting, and limited-access scenarios.',
)
@SectionId('DMP')
@CodeSpecKind([CodeSpecPart.authorization])
class DataMaskingPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Data Masking Details (text).
  @SerializationOrder(1)
  TextSection dataMaskingDetails = TextSection();
}

/// Data access audit policy (form).
///
/// Defines how data access events are monitored, logged, and reviewed
/// to detect unauthorized access and support compliance requirements.
@Form([
  Field(
    'dataAccessLoggingEnabled',
    String,
    'Data Access Logging Enabled',
    hint: 'Yes | No — whether data access events are logged',
  ),
  Field(
    'dataAccessLoggingScope',
    String,
    'Data Access Logging Scope',
    hint:
        'AllTables | SensitiveTablesOnly | ByClassification — which data access is logged',
  ),
  Field(
    'loggedOperations',
    String,
    'Logged Operations',
    hint:
        'Read | Write | Delete | SchemaChange | All — which operations are captured',
  ),
  Field(
    'dataAccessLogDetail',
    String,
    'Data Access Log Detail',
    hint:
        'QueryText | AffectedRows | ColumnAccess | Minimal — what detail is recorded per event',
  ),
  Field(
    'queryTextLogging',
    String,
    'Query Text Logging',
    hint:
        'Full | Sanitized | HashOnly | Disabled — whether executed query text is logged',
  ),
  Field(
    'anomalyDetectionEnabled',
    String,
    'Anomaly Detection Enabled',
    hint: 'Yes | No — whether unusual data access patterns trigger alerts',
  ),
  Field(
    'anomalySignals',
    String,
    'Anomaly Detection Signals',
    hint:
        'BulkExport | OffHoursAccess | UnusualVolume | NewAccessPattern — signals monitored',
  ),
  Field(
    'dataBreachDetection',
    String,
    'Data Breach Detection',
    hint:
        'RealTime | BatchReview | ThirdPartyDLP — how potential data exfiltration is detected',
  ),
  Field(
    'dataAccessReviewCycle',
    String,
    'Data Access Review Cycle',
    hint:
        'Monthly | Quarterly | Annually — how often data access permissions are reviewed',
  ),
  Field(
    'privilegedQueryAlerts',
    String,
    'Privileged Query Alerts',
    hint:
        'Yes | No — whether queries by privileged accounts trigger real-time alerts',
  ),
  Field(
    'complianceReportingEnabled',
    String,
    'Compliance Reporting Enabled',
    hint:
        'Yes | No — whether automated compliance reports are generated from access logs',
  ),
  Field(
    'dataAccessRetention',
    String,
    'Data Access Log Retention',
    hint: 'Duration data access logs are retained (e.g., 90d, 1y, 7y)',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.8.15 logging',
    'NIST SP 800-53 — control AC-3 access enforcement',
    'ISO/IEC 27001:2022 — control A.8.16 monitoring activities',
  ],
  'Defines how data access events are logged, monitored, and reviewed to detect unauthorized access and support compliance.',
)
@SectionId('DAAP')
@CodeSpecKind([CodeSpecPart.auditLog])
class DataAccessAuditPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Data Access Audit Details (text).
  @SerializationOrder(1)
  TextSection dataAccessAuditDetails = TextSection();
}

// ---------------------------------------------------------------------------
// 9.3.2. API Security
// ---------------------------------------------------------------------------

/// 9.3.2. API Security.
///
/// Comprehensive API security specification covering authentication,
/// authorization, request validation, CORS policy, input sanitization,
/// abuse prevention, and security monitoring. Aligned with OWASP API
/// Security Top 10 (2023) and OWASP REST Security Cheat Sheet.
@StandardReferences(
  [
    'OWASP API Security Top 10 — 2023 edition',
    'OWASP ASVS 4.0 — V13 API and web service verification',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
  ],
  'Covers end-to-end API security including authentication, authorization, request validation, CORS, abuse prevention, and monitoring.',
)
@SectionId('APSE')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class ApiSecurity extends DocSpecsSection {
  @ContentHelp('''
Define security controls for all APIs exposed by the system, including
public-facing APIs, internal microservices, and webhooks.

**API authentication (OWASP API1:2023):**
- OAuth 2.0 with appropriate grant types (authorization code, client credentials)
- API keys for simple integrations (with rotation and rate limiting)
- Mutual TLS for service-to-service communication
- JWT validation: signature, expiration, audience, issuer

**API authorization (OWASP API5:2023):**
- Function-level access control (which endpoints user can call)
- Object-level access control (which resources user can access)
- Field-level filtering in responses

**Request validation (OWASP API8:2023):**
- Schema validation (JSON Schema, OpenAPI)
- Input sanitization against injection attacks
- Rate limiting and quota enforcement
- Request size limits

**CORS security:**
- Explicit allowed origins (no wildcard for credentialed requests)
- Allowed methods and headers explicitly listed
- Preflight caching configuration

**Abuse protection:**
- Rate limiting per user/IP/API key
- DDoS protection at edge (WAF, CDN)
- Anomaly detection for API abuse patterns

**Reference:**
- OWASP API Security Top 10 (2023)
- OWASP REST Security Cheat Sheet
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// API Security Overview (text).
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// API Authentication Policy.
  @SerializationOrder(2)
  ApiAuthenticationPolicy apiAuthenticationPolicy = ApiAuthenticationPolicy();

  /// API Authorization Policy.
  @SerializationOrder(3)
  ApiAuthorizationPolicy apiAuthorizationPolicy = ApiAuthorizationPolicy();

  /// API Request Validation Policy.
  @SerializationOrder(4)
  ApiRequestValidationPolicy apiRequestValidationPolicy =
      ApiRequestValidationPolicy();

  /// API CORS Security.
  @SerializationOrder(5)
  ApiCorsSecurity apiCorsSecurity = ApiCorsSecurity();

  /// API Abuse Protection.
  @SerializationOrder(6)
  ApiAbuseProtection apiAbuseProtection = ApiAbuseProtection();

  /// API Security Monitoring.
  @SerializationOrder(7)
  ApiSecurityMonitoring apiSecurityMonitoring = ApiSecurityMonitoring();
}

/// API authentication policy — how API consumers prove their identity.
///
/// Covers API keys, OAuth2 flows, JWT validation, mutual TLS, webhook
/// signature verification, and service-to-service authentication.
@Form([
  // Primary authentication mechanism
  Field(
    'authenticationMethod',
    String,
    'Primary Authentication Method',
    required: true,
    hint:
        'OAuth2 | APIKey | JWT | mTLS | HMAC | Basic — primary API authentication mechanism',
  ),
  Field(
    'multipleMethodsSupported',
    bool,
    'Multiple Methods Supported',
    hint:
        'Yes | No — whether the API supports multiple authentication methods simultaneously',
  ),

  // API key management
  Field(
    'apiKeyTransmission',
    String,
    'API Key Transmission',
    hint:
        'Header | QueryParam | Cookie — where API keys are transmitted (Header recommended)',
  ),
  Field(
    'apiKeyRotationPolicy',
    String,
    'API Key Rotation Policy',
    hint:
        'Automatic periodic rotation interval and overlap/grace period for old keys',
  ),
  Field(
    'apiKeyScoping',
    String,
    'API Key Scoping',
    hint:
        'Global | PerEnvironment | PerService — whether keys are scoped to specific environments or services',
  ),

  // OAuth2 / JWT
  Field(
    'jwtValidationPolicy',
    String,
    'JWT Validation Policy',
    hint:
        'iss, aud, exp, nbf — required JWT claims to validate on every request',
  ),
  Field(
    'jwtSigningAlgorithm',
    String,
    'JWT Signing Algorithm',
    hint:
        'RS256 | ES256 | EdDSA — required JWT signing algorithm (HS256 discouraged for APIs)',
  ),
  Field(
    'accessTokenLifetime',
    String,
    'Access Token Lifetime',
    hint: 'Maximum access token validity duration (e.g. 15 min, 1 hour)',
  ),
  Field(
    'refreshTokenPolicy',
    String,
    'Refresh Token Policy',
    hint: 'Rotation | Reuse | None — refresh token handling and lifetime',
  ),
  Field(
    'clientCredentialsFlow',
    bool,
    'Client Credentials Flow',
    hint:
        'Yes | No — whether OAuth2 client credentials flow is supported for service-to-service',
  ),
  Field(
    'authorizationCodeFlow',
    bool,
    'Authorization Code Flow',
    hint:
        'Yes | No — whether OAuth2 authorization code flow with PKCE is supported',
  ),
  Field(
    'tokenRevocationSupport',
    bool,
    'Token Revocation Support',
    hint:
        'Yes | No — whether explicit token revocation is supported (RFC 7009)',
  ),

  // Service-to-service and mutual TLS
  Field(
    'mutualTlsRequired',
    bool,
    'Mutual TLS Required',
    hint:
        'Yes | No — require client certificate authentication for service-to-service communication',
  ),
  Field(
    'serviceAccountPolicy',
    String,
    'Service Account Policy',
    hint:
        'How service accounts authenticate and what credential types they use',
  ),

  // Webhook and third-party
  Field(
    'webhookSignatureVerification',
    String,
    'Webhook Signature Verification',
    hint:
        'HMAC-SHA256 | RSA | EdDSA — method used to verify incoming webhook requests',
  ),
  Field(
    'thirdPartyApiConsumption',
    String,
    'Third-Party API Consumption Security',
    hint:
        'Security requirements when consuming external third-party APIs (OWASP API10)',
  ),
  Field(
    'credentialTransmission',
    String,
    'Credential Transmission',
    hint:
        'Header | Body — where credentials are transmitted (Header via Authorization recommended)',
  ),
  Field(
    'bearerTokenFormat',
    String,
    'Bearer Token Format',
    hint: 'JWT | Opaque | Reference — format used for bearer tokens',
  ),
  Field('notes', String, 'Notes', hint: 'Additional API authentication notes'),
])
@StandardReferences(
  [
    'OAuth 2.0 — RFC 6749 authorization framework',
    'OWASP API Security Top 10 — 2023 edition',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
  ],
  'Defines how API callers authenticate, including credential types, token formats, and webhook signature verification.',
)
@SectionId('AAP')
@CodeSpecKind([CodeSpecPart.authentication])
class ApiAuthenticationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// API Authentication Details (text).
  @SerializationOrder(1)
  TextSection apiAuthenticationDetails = TextSection();
}

/// API authorization policy — how API access decisions are made.
///
/// Covers object-level, function-level, and property-level authorization,
/// scope definitions, delegation controls, and protection against privilege
/// escalation. Aligned with OWASP API1/API3/API5 (Broken Authorization).
@Form([
  // Authorization granularity
  Field(
    'objectLevelAuthorization',
    String,
    'Object-Level Authorization',
    required: true,
    hint:
        'How every API endpoint verifies the caller owns or may access the requested object (OWASP API1)',
  ),
  Field(
    'functionLevelAuthorization',
    String,
    'Function-Level Authorization',
    hint:
        'How administrative vs. regular functions are separated and access-controlled (OWASP API5)',
  ),
  Field(
    'propertyLevelAuthorization',
    String,
    'Property-Level Authorization',
    hint:
        'How field-level exposure is controlled — preventing excessive data exposure and mass assignment (OWASP API3)',
  ),
  Field(
    'permissionGranularity',
    String,
    'Permission Granularity',
    hint:
        'Endpoint | Resource | Field — granularity at which permissions are evaluated',
  ),

  // Scopes and delegation
  Field(
    'scopeDefinitions',
    String,
    'OAuth2 Scope Definitions',
    hint:
        'OAuth2 scopes required for API access (e.g. read:users, write:orders)',
  ),
  Field(
    'scopeEnforcementLevel',
    String,
    'Scope Enforcement Level',
    hint: 'Gateway | Service | Both — where scope checks are enforced',
  ),
  Field(
    'delegatedAccessPolicy',
    String,
    'Delegated Access Policy',
    hint: 'How delegation or impersonation is controlled (on-behalf-of flows)',
  ),

  // Bulk and batch operations
  Field(
    'bulkOperationAuthorization',
    String,
    'Bulk Operation Authorization',
    hint:
        'How batch/bulk API operations are authorized — per-item or at collection level',
  ),
  Field(
    'contextualAuthorization',
    String,
    'Contextual Authorization',
    hint: 'IP, time-of-day, device, or geolocation-based access decisions',
  ),

  // Escalation prevention
  Field(
    'massAssignmentPrevention',
    String,
    'Mass Assignment Prevention',
    hint:
        'How mass assignment attacks are prevented — allowlisted fields, DTOs, read-only markers',
  ),
  Field(
    'horizontalPrivilegeEscalation',
    String,
    'Horizontal Privilege Escalation Prevention',
    hint:
        'Controls preventing a user from accessing another user\'s data via direct object reference',
  ),
  Field(
    'verticalPrivilegeEscalation',
    String,
    'Vertical Privilege Escalation Prevention',
    hint:
        'Controls preventing regular users from accessing administrative functions',
  ),

  // Business flow protection
  Field(
    'sensitiveBusinessFlowProtection',
    String,
    'Sensitive Business Flow Protection',
    hint:
        'How sensitive workflows (checkout, transfer) are protected from automated abuse (OWASP API6)',
  ),
  Field(
    'workflowStateValidation',
    String,
    'Workflow State Validation',
    hint:
        'How out-of-order API execution is prevented (server-side state machine enforcement)',
  ),
  Field('notes', String, 'Notes', hint: 'Additional API authorization notes'),
])
@StandardReferences(
  [
    'OWASP API Security Top 10 — 2023 edition',
    'NIST SP 800-53 — control AC-3 access enforcement',
    'OWASP ASVS 4.0 — V13 API and web service verification',
  ],
  'Defines object-level, function-level, and property-level authorization and controls against privilege escalation.',
)
@SectionId('APAUPO')
@CodeSpecKind([CodeSpecPart.authorization])
class ApiAuthorizationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// API Authorization Details (text).
  @SerializationOrder(1)
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
  Field(
    'inputValidationStrategy',
    String,
    'Input Validation Strategy',
    required: true,
    hint:
        'Allowlist | Blocklist | SchemaValidation — primary validation approach (Allowlist recommended)',
  ),
  Field(
    'schemaValidationEnforced',
    bool,
    'Schema Validation Enforced',
    hint:
        'Yes | No — whether JSON Schema or OpenAPI schema validation is enforced on all requests',
  ),
  Field(
    'schemaValidationTool',
    String,
    'Schema Validation Tool',
    hint: 'Library or framework used for request schema validation',
  ),

  // Content type
  Field(
    'contentTypeValidation',
    bool,
    'Content-Type Validation',
    hint:
        'Yes | No — whether Content-Type header is validated against expected types',
  ),
  Field(
    'acceptedContentTypes',
    String,
    'Accepted Content Types',
    hint:
        'application/json | application/xml — comma-separated list of accepted content types',
  ),
  Field(
    'rejectUnexpectedContentType',
    bool,
    'Reject Unexpected Content-Type',
    hint: 'Yes | No — respond with HTTP 415 for unsupported media types',
  ),

  // Size and depth limits
  Field(
    'requestSizeLimit',
    String,
    'Request Size Limit',
    hint: 'Maximum request body size (e.g. 1 MB, 10 MB) — reject with HTTP 413',
  ),
  Field(
    'arrayLengthLimit',
    int,
    'Array Length Limit',
    hint:
        'Maximum number of elements allowed in any JSON array in request body',
  ),
  Field(
    'nestedObjectDepthLimit',
    int,
    'Nested Object Depth Limit',
    hint:
        'Maximum nesting depth for JSON objects to prevent DoS via deep nesting',
  ),
  Field(
    'stringFieldMaxLength',
    int,
    'String Field Max Length',
    hint:
        'Default maximum character length for string fields unless overridden per field',
  ),

  // Parameter and type enforcement
  Field(
    'parameterTypeEnforcement',
    bool,
    'Parameter Type Enforcement',
    hint:
        'Yes | No — enforce strong typing (number, boolean, date) on query/path parameters',
  ),
  Field(
    'numericRangeValidation',
    bool,
    'Numeric Range Validation',
    hint: 'Yes | No — enforce min/max bounds on numeric parameters',
  ),
  Field(
    'dateFormatValidation',
    String,
    'Date Format Validation',
    hint:
        'ISO 8601 | RFC 3339 | Custom — required date/time format for all date fields',
  ),
  Field(
    'encodingValidation',
    String,
    'Encoding Validation',
    hint: 'UTF-8 | ASCII — accepted character encoding for request bodies',
  ),

  // File uploads
  Field(
    'fileUploadValidation',
    String,
    'File Upload Validation',
    hint:
        'Allowed extensions, MIME types, max file size, and content scanning requirements',
  ),
  Field('notes', String, 'Notes', hint: 'Additional request validation notes'),
])
@StandardReferences(
  [
    'OWASP ASVS 4.0 — V13 API and web service verification',
    'OWASP API Security Top 10 — 2023 edition',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
  ],
  'Defines input validation, schema enforcement, size limits, and content-type verification for all API requests.',
)
@SectionId('ARVP')
@CodeSpecKind([CodeSpecPart.validation])
class ApiRequestValidationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Request Validation Details (text).
  @SerializationOrder(1)
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
  Field(
    'corsEnabled',
    bool,
    'CORS Enabled',
    required: true,
    hint: 'Yes | No — whether CORS is enabled for the API',
  ),
  Field(
    'allowedOrigins',
    String,
    'Allowed Origins',
    hint: 'Explicit domain list or pattern — avoid wildcard * with credentials',
  ),
  Field(
    'allowedMethods',
    String,
    'Allowed HTTP Methods',
    hint: 'GET | POST | PUT | DELETE | PATCH — permitted HTTP methods',
  ),
  Field(
    'allowedHeaders',
    String,
    'Allowed Request Headers',
    hint: 'Authorization, Content-Type, X-Request-ID — allowed request headers',
  ),
  Field(
    'exposedHeaders',
    String,
    'Exposed Response Headers',
    hint:
        'X-RateLimit-Remaining, X-Request-ID — response headers visible to client JavaScript',
  ),
  Field(
    'credentialsAllowed',
    bool,
    'Credentials Allowed',
    hint:
        'Yes | No — Access-Control-Allow-Credentials (mutually exclusive with wildcard origin)',
  ),
  Field(
    'preflightCacheMaxAge',
    int,
    'Preflight Cache Max-Age',
    hint:
        'Maximum time in seconds that preflight responses can be cached (e.g. 3600)',
  ),
  Field(
    'wildcardRestriction',
    bool,
    'Wildcard Restriction',
    hint:
        'Yes | No — whether wildcard * origin is explicitly prohibited when credentials are used',
  ),

  // Security headers
  Field(
    'contentSecurityPolicy',
    String,
    'Content Security Policy',
    hint:
        'CSP directives for API responses (e.g. default-src none, frame-ancestors none)',
  ),
  Field(
    'strictTransportSecurity',
    String,
    'Strict Transport Security',
    hint: 'HSTS max-age and includeSubDomains directive for API endpoints',
  ),
  Field(
    'securityHeadersRequired',
    String,
    'Required Security Headers',
    hint:
        'X-Content-Type-Options: nosniff, X-Frame-Options: DENY, Referrer-Policy: no-referrer',
  ),
  Field(
    'privateNetworkAccess',
    String,
    'Private Network Access Policy',
    hint:
        'How CORS private network access requests are handled (Access-Control-Request-Private-Network)',
  ),
  Field('notes', String, 'Notes', hint: 'Additional CORS security notes'),
])
@StandardReferences(
  [
    'OWASP ASVS 4.0 — V13 API and web service verification',
    'OWASP API Security Top 10 — 2023 edition',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
  ],
  'Defines CORS configuration and security response headers that govern cross-origin access to the API.',
)
@SectionId('APCOSE')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class ApiCorsSecurity extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// CORS Security Details (text).
  @SerializationOrder(1)
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
  Field(
    'rateLimitingEnabled',
    bool,
    'Rate Limiting Enabled',
    required: true,
    hint: 'Yes | No — whether security-focused rate limiting is enforced',
  ),
  Field(
    'rateLimitScope',
    String,
    'Rate Limit Scope',
    hint:
        'PerClient | PerEndpoint | PerTenant | Global — at what level limits are applied',
  ),
  Field(
    'authenticationEndpointLimits',
    String,
    'Authentication Endpoint Limits',
    hint:
        'Stricter rate limits for login/token endpoints to prevent brute-force attacks',
  ),
  Field(
    'sensitiveEndpointLimits',
    String,
    'Sensitive Endpoint Limits',
    hint:
        'Additional rate limits for password reset, MFA enrolment, payment endpoints',
  ),

  // Brute force and bot protection
  Field(
    'bruteForceProtection',
    String,
    'Brute Force Protection',
    hint:
        'Account lockout, progressive delays, CAPTCHA — how brute force authentication attacks are mitigated',
  ),
  Field(
    'botDetectionPolicy',
    String,
    'Bot Detection Policy',
    hint:
        'CAPTCHA | BehavioralAnalysis | DeviceFingerprint | None — automated request detection',
  ),
  Field(
    'ipReputationFiltering',
    bool,
    'IP Reputation Filtering',
    hint:
        'Yes | No — use IP reputation databases to filter known-malicious sources',
  ),

  // Threat response
  Field(
    'automaticBlocking',
    bool,
    'Automatic Blocking',
    hint: 'Yes | No — automatically block clients exceeding abuse thresholds',
  ),
  Field(
    'blockDuration',
    String,
    'Block Duration',
    hint:
        'Temporary (minutes/hours) or permanent — duration of automatic blocks',
  ),
  Field(
    'geographicRestrictions',
    String,
    'Geographic Restrictions',
    hint: 'Region or country-based access restrictions for API endpoints',
  ),
  Field(
    'requestThrottlingOnFailure',
    String,
    'Request Throttling on Failure',
    hint:
        'Progressive delay or backoff on repeated authentication or validation failures',
  ),

  // Business flow protection
  Field(
    'businessFlowProtection',
    String,
    'Business Flow Protection',
    hint:
        'How automated abuse of business-critical flows is detected and prevented (OWASP API6)',
  ),
  Field(
    'webhookFloodProtection',
    String,
    'Webhook Flood Protection',
    hint: 'How webhook replay attacks and flood scenarios are prevented',
  ),
  Field('notes', String, 'Notes', hint: 'Additional abuse protection notes'),
])
@StandardReferences(
  [
    'OWASP API Security Top 10 — 2023 edition',
    'OWASP ASVS 4.0 — V13 API and web service verification',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
  ],
  'Defines rate limiting, bot detection, brute-force prevention, and business-flow protection against API abuse.',
)
@SectionId('APABPR')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class ApiAbuseProtection extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Abuse Protection Details (text).
  @SerializationOrder(1)
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
  Field(
    'apiAccessLogging',
    bool,
    'API Access Logging',
    required: true,
    hint:
        'Yes | No — whether all API access is logged with caller identity and action',
  ),
  Field(
    'loggedAttributes',
    String,
    'Logged Request Attributes',
    hint:
        'Timestamp, clientId, endpoint, method, statusCode, responseTime, sourceIP — attributes captured per request',
  ),
  Field(
    'sensitiveEndpointMonitoring',
    bool,
    'Sensitive Endpoint Monitoring',
    hint:
        'Yes | No — enhanced logging for authentication, payment, and admin endpoints',
  ),
  Field(
    'sensitiveDataRedaction',
    bool,
    'Sensitive Data Redaction',
    hint: 'Yes | No — redact PII, credentials, and tokens from API logs',
  ),

  // Anomaly detection
  Field(
    'anomalyDetection',
    bool,
    'Anomaly Detection',
    hint:
        'Yes | No — detect anomalous API usage patterns (unusual volume, timing, geography)',
  ),
  Field(
    'errorRateMonitoring',
    String,
    'Error Rate Monitoring',
    hint:
        'Threshold and window for error-rate alerting (e.g. >5% 4xx in 5-min window)',
  ),
  Field(
    'authenticationFailureTracking',
    bool,
    'Authentication Failure Tracking',
    hint:
        'Yes | No — track and alert on authentication failure patterns per client/IP',
  ),
  Field(
    'dataExfiltrationDetection',
    bool,
    'Data Exfiltration Detection',
    hint:
        'Yes | No — detect unusual data volume patterns that may indicate exfiltration',
  ),

  // Inventory and versioning
  Field(
    'apiVersionInventory',
    bool,
    'API Version Inventory',
    hint:
        'Yes | No — maintain a current inventory of all API versions and endpoints (OWASP API9)',
  ),
  Field(
    'deprecatedEndpointMonitoring',
    bool,
    'Deprecated Endpoint Monitoring',
    hint:
        'Yes | No — monitor and alert on usage of deprecated API endpoints or versions',
  ),

  // Alerts and response
  Field(
    'realTimeAlerts',
    bool,
    'Real-Time Alerts',
    hint: 'Yes | No — trigger real-time security alerts on threshold breaches',
  ),
  Field(
    'securityResponseAutomation',
    String,
    'Security Response Automation',
    hint:
        'Automated actions on security events — block, throttle, escalate, notify',
  ),
  Field(
    'complianceReporting',
    String,
    'Compliance Reporting',
    hint: 'Frequency and format of API security compliance reports',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional API security monitoring notes',
  ),
])
@StandardReferences(
  [
    'OWASP API Security Top 10 — 2023 edition',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
    'NIST SP 800-53 — control AC-3 access enforcement',
  ],
  'Defines API access logging, anomaly detection, inventory management, and compliance reporting for API security.',
)
@SectionId('APSEMO')
@CodeSpecKind([CodeSpecPart.auditLog])
class ApiSecurityMonitoring extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// API Security Monitoring Details (text).
  @SerializationOrder(1)
  TextSection apiSecurityMonitoringDetails = TextSection();
}

// ---------------------------------------------------------------------------
// 9.3.3. File and Storage Security
// ---------------------------------------------------------------------------

/// 9.3.3. File and Storage Security.
///
/// Comprehensive file and storage security specification covering upload
/// validation, storage encryption, access control on file resources, content
/// scanning, download protection, and storage lifecycle management.
/// Aligned with OWASP File Upload Cheat Sheet and defense-in-depth principles.
@StandardReferences(
  [
    'OWASP ASVS 4.0 — V12 file and resources verification',
    'ISO/IEC 27001:2022 — control A.8.10 information deletion',
    'NIST SP 800-53 — control SC-28 protection of information at rest',
  ],
  'Covers end-to-end file and storage security including upload validation, encryption, access control, scanning, and lifecycle.',
)
@SectionId('FASS')
@CodeSpecKind([CodeSpecPart.serverConfiguration],
    note: 'CE-CF — file/blob storage is a tom_core capability (server '
        'persistence-model storage + tom_flutter_ui file components), not a '
        'CodeSpecs part; these sections author the CE-CF configuration of '
        'that capability (operator-set storage-security policies).')
class FileAndStorageSecurity extends DocSpecsSection {
  @ContentHelp('''
Define security controls for user-uploaded files, generated documents,
and all stored media.

**File upload validation:**
- Allowlist of permitted file extensions (not blocklist)
- Content-type validation (check magic bytes, not just extension)
- Maximum file size limits per file type
- Filename sanitization (remove path traversal, special characters)
- Re-encode/re-compress files to strip malicious payloads

**Malware scanning:**
- Scan all uploads before acceptance
- Quarantine suspicious files for review
- Block known-malicious file signatures

**Storage encryption:**
- Encrypt files at rest (AES-256-GCM or equivalent)
- Server-side encryption with customer-managed keys (BYOK) option
- Secure key management via HSM or cloud KMS

**Access control:**
- Signed URLs for time-limited access to private files
- Authorization check before serving any file
- No direct filesystem access to uploaded content

**Download protection:**
- Content-Disposition header to force downloads for executable types
- X-Content-Type-Options: nosniff
- Serve user content from separate domain (sandbox)

**Storage lifecycle:**
- Automatic deletion of orphaned files
- Retention policies per file type and classification
- Secure deletion (cryptographic erasure)

**Reference:**
- OWASP File Upload Cheat Sheet
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// File and Storage Security Overview (text).
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// File Upload Validation Policy.
  @SerializationOrder(2)
  FileUploadValidationPolicy fileUploadValidationPolicy =
      FileUploadValidationPolicy();

  /// Storage Encryption Policy.
  @SerializationOrder(3)
  StorageEncryptionPolicy storageEncryptionPolicy = StorageEncryptionPolicy();

  /// File Access Control Policy.
  @SerializationOrder(4)
  FileAccessControlPolicy fileAccessControlPolicy = FileAccessControlPolicy();

  /// Content Scanning Policy.
  @SerializationOrder(5)
  ContentScanningPolicy contentScanningPolicy = ContentScanningPolicy();

  /// File Download Security Policy.
  @SerializationOrder(6)
  FileDownloadSecurityPolicy fileDownloadSecurityPolicy =
      FileDownloadSecurityPolicy();

  /// Storage Lifecycle Policy.
  @SerializationOrder(7)
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
  Field(
    'extensionValidationStrategy',
    String,
    'Extension Validation Strategy',
    required: true,
    hint:
        'Allowlist | Blocklist | Both — approach to file extension validation (Allowlist recommended)',
  ),
  Field(
    'allowedFileExtensions',
    String,
    'Allowed File Extensions',
    hint:
        'Comma-separated list of permitted extensions (e.g. jpg, png, pdf, docx)',
  ),
  Field(
    'blockedFileExtensions',
    String,
    'Blocked File Extensions',
    hint:
        'Comma-separated list of explicitly blocked extensions (e.g. exe, bat, sh, php, js)',
  ),
  Field(
    'doubleExtensionPrevention',
    bool,
    'Double Extension Prevention',
    hint: 'Yes | No — prevent bypass via double extensions like .jpg.php',
  ),

  // Content-type and signature
  Field(
    'contentTypeValidation',
    bool,
    'Content-Type Validation',
    hint:
        'Yes | No — validate MIME type from Content-Type header against allowed types',
  ),
  Field(
    'fileSignatureValidation',
    bool,
    'File Signature (Magic Byte) Validation',
    hint:
        'Yes | No — validate file magic bytes match the declared content type',
  ),
  Field(
    'signatureMismatchAction',
    String,
    'Signature Mismatch Action',
    hint:
        'Reject | Quarantine | Log — action when file signature does not match extension',
  ),

  // Filename safety
  Field(
    'filenameStrategy',
    String,
    'Filename Strategy',
    hint:
        'GenerateUUID | SanitizeOriginal | Preserve — how filenames are handled on upload',
  ),
  Field(
    'filenameMaxLength',
    int,
    'Filename Max Length',
    hint: 'Maximum allowed filename length in characters',
  ),
  Field(
    'filenameAllowedCharacters',
    String,
    'Filename Allowed Characters',
    hint:
        'Alphanumeric, hyphen, underscore, period — allowed characters in filenames',
  ),
  Field(
    'pathTraversalPrevention',
    bool,
    'Path Traversal Prevention',
    hint: 'Yes | No — strip or reject path components (../, /) in filenames',
  ),
  Field(
    'nullBytePrevention',
    bool,
    'Null Byte Prevention',
    hint: 'Yes | No — reject filenames containing null bytes (%00)',
  ),

  // Size limits
  Field(
    'maxFileSizeBytes',
    String,
    'Max File Size',
    hint: 'Maximum individual file size (e.g. 10 MB, 50 MB, 1 GB)',
  ),
  Field(
    'maxUploadBatchSize',
    String,
    'Max Upload Batch Size',
    hint: 'Maximum total size for multi-file uploads in a single request',
  ),
  Field(
    'maxConcurrentUploads',
    int,
    'Max Concurrent Uploads',
    hint: 'Maximum number of simultaneous file uploads per user',
  ),
  Field(
    'compressedFileSizeLimit',
    String,
    'Compressed File Size Limit',
    hint:
        'Maximum decompressed size for ZIP/archive files to prevent ZIP bombs',
  ),

  // Structural validation
  Field(
    'imageRewriting',
    bool,
    'Image Rewriting',
    hint:
        'Yes | No — rewrite/re-encode images to strip embedded metadata and malicious payloads',
  ),
  Field(
    'documentSanitization',
    bool,
    'Document Sanitization',
    hint:
        'Yes | No — apply Content Disarm & Reconstruct (CDR) to office documents and PDFs',
  ),
  Field(
    'metadataStripping',
    bool,
    'Metadata Stripping',
    hint:
        'Yes | No — remove EXIF, XMP, and other embedded metadata from uploaded files',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional file upload validation notes',
  ),
])
@StandardReferences(
  [
    'OWASP ASVS 4.0 — V12 file and resources verification',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
    'OWASP API Security Top 10 — 2023 edition',
  ],
  'Defines how uploaded files are validated for type, size, and content before acceptance to prevent malicious uploads.',
)
@SectionId('FUVP')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class FileUploadValidationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Upload Validation Details (text).
  @SerializationOrder(1)
  TextSection uploadValidationDetails = TextSection();
}

/// Storage encryption policy — how files and storage volumes are encrypted
/// at rest and in transit to/from storage.
///
/// Covers server-side encryption, client-side encryption, key management
/// for file storage, and encryption scope for different storage tiers.
@Form([
  // Encryption at rest
  Field(
    'encryptionAtRest',
    bool,
    'Encryption at Rest',
    required: true,
    hint: 'Yes | No — whether stored files are encrypted at rest',
  ),
  Field(
    'encryptionAlgorithm',
    String,
    'Encryption Algorithm',
    hint:
        'AES-256-GCM | AES-256-CBC | ChaCha20-Poly1305 — algorithm for file encryption',
  ),
  Field(
    'encryptionScope',
    String,
    'Encryption Scope',
    hint:
        'Volume | Bucket | PerFile | PerTenant — granularity at which encryption keys are applied',
  ),
  Field(
    'serverSideEncryption',
    String,
    'Server-Side Encryption',
    hint:
        'SSE-S3 | SSE-KMS | SSE-C | ManagedKey — server-side encryption method',
  ),
  Field(
    'clientSideEncryption',
    bool,
    'Client-Side Encryption',
    hint: 'Yes | No — whether files are encrypted before upload by the client',
  ),
  Field(
    'clientSideEncryptionMethod',
    String,
    'Client-Side Encryption Method',
    hint:
        'Envelope encryption, client-managed keys — method for client-side encryption',
  ),

  // Key management for files
  Field(
    'fileKeyRotation',
    String,
    'File Encryption Key Rotation',
    hint: 'Frequency and method of rotating file encryption keys',
  ),
  Field(
    'perTenantKeys',
    bool,
    'Per-Tenant Encryption Keys',
    hint:
        'Yes | No — whether each tenant has its own encryption key for file storage',
  ),
  Field(
    'keyDeletionOnTenantRemoval',
    bool,
    'Key Deletion on Tenant Removal',
    hint:
        'Yes | No — whether tenant file encryption keys are destroyed when tenant is deleted',
  ),

  // Transit encryption
  Field(
    'encryptionInTransit',
    bool,
    'Encryption in Transit',
    hint: 'Yes | No — TLS for file upload/download transport',
  ),
  Field(
    'minimumTlsVersion',
    String,
    'Minimum TLS Version for File Transfer',
    hint: 'TLS 1.2 | TLS 1.3 — minimum TLS version for file transfers',
  ),

  // Backup encryption
  Field(
    'backupEncryption',
    bool,
    'Backup Encryption',
    hint:
        'Yes | No — whether file storage backups are encrypted with the same or separate keys',
  ),
  Field('notes', String, 'Notes', hint: 'Additional storage encryption notes'),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-28 protection of information at rest',
    'ISO/IEC 27001:2022 — control A.5.33 protection of records',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
  ],
  'Defines how files and storage volumes are encrypted at rest and in transit, including key management scope.',
)
@SectionId('STENPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class StorageEncryptionPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Storage Encryption Details (text).
  @SerializationOrder(1)
  TextSection storageEncryptionDetails = TextSection();
}

/// File access control policy — who can access, modify, share, and delete
/// files, and how access decisions are enforced.
///
/// Covers authentication requirements, authorization model, sharing controls,
/// storage location isolation, filesystem permissions, and temporary access.
@Form([
  // Access model
  Field(
    'fileAccessModel',
    String,
    'File Access Model',
    required: true,
    hint:
        'OwnerBased | RoleBased | ACL | Capability — how file access permissions are determined',
  ),
  Field(
    'authenticationRequired',
    bool,
    'Authentication Required',
    hint: 'Yes | No — whether authentication is required for all file access',
  ),
  Field(
    'anonymousDownloadAllowed',
    bool,
    'Anonymous Download Allowed',
    hint:
        'Yes | No — whether any files can be downloaded without authentication (public files)',
  ),
  Field(
    'fileOwnershipModel',
    String,
    'File Ownership Model',
    hint:
        'User | Tenant | SharedOwnership — who owns uploaded files by default',
  ),

  // Permission granularity
  Field(
    'permissionGranularity',
    String,
    'Permission Granularity',
    hint:
        'Read | Write | Delete | Share | Admin — permission types supported on files',
  ),
  Field(
    'folderLevelPermissions',
    bool,
    'Folder-Level Permissions',
    hint:
        'Yes | No — whether permissions can be set at folder/directory level with inheritance',
  ),
  Field(
    'permissionInheritance',
    String,
    'Permission Inheritance',
    hint:
        'Inherit | Override | None — how folder permissions propagate to contained files',
  ),

  // Sharing controls
  Field(
    'sharingEnabled',
    bool,
    'Sharing Enabled',
    hint:
        'Yes | No — whether files can be shared with other users or externally',
  ),
  Field(
    'shareableLinkSupport',
    bool,
    'Shareable Link Support',
    hint:
        'Yes | No — support for time-limited or password-protected shareable URLs',
  ),
  Field(
    'shareableLinkExpiration',
    String,
    'Shareable Link Default Expiration',
    hint:
        'Default expiration time for shareable links (e.g. 24 hours, 7 days, never)',
  ),
  Field(
    'externalSharingPolicy',
    String,
    'External Sharing Policy',
    hint:
        'Allowed | RestrictedDomains | Disabled — whether files can be shared outside the tenant',
  ),

  // Storage isolation
  Field(
    'storageLocationPolicy',
    String,
    'Storage Location Policy',
    hint:
        'SeparateServer | OutsideWebroot | CloudBucket — where files are stored relative to application',
  ),
  Field(
    'tenantStorageIsolation',
    String,
    'Tenant Storage Isolation',
    hint:
        'SeparateBucket | PrefixPartition | SharedWithACL — how tenant files are isolated in storage',
  ),
  Field(
    'filesystemPermissions',
    String,
    'Filesystem Permissions',
    hint:
        'Least-privilege file permission policy (read-only for web server, write for upload service)',
  ),

  // Temporary and pre-signed access
  Field(
    'presignedUrlSupport',
    bool,
    'Pre-signed URL Support',
    hint: 'Yes | No — use pre-signed URLs for time-limited direct file access',
  ),
  Field(
    'presignedUrlMaxExpiry',
    String,
    'Pre-signed URL Max Expiry',
    hint: 'Maximum validity period for pre-signed URLs (e.g. 15 min, 1 hour)',
  ),
  Field('notes', String, 'Notes', hint: 'Additional file access control notes'),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
    'NIST SP 800-53 — control AC-3 access enforcement',
    'OWASP ASVS 4.0 — V12 file and resources verification',
  ],
  'Defines who may access stored files and how access is enforced through permissions and time-limited direct links.',
)
@SectionId('FACP')
@CodeSpecKind([CodeSpecPart.authorization])
class FileAccessControlPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// File Access Control Details (text).
  @SerializationOrder(1)
  TextSection fileAccessControlDetails = TextSection();
}

/// Content scanning policy — how uploaded and stored files are scanned for
/// malicious content, policy violations, and compliance risks.
///
/// Covers antivirus scanning, malware detection, content disarm and
/// reconstruct (CDR), data loss prevention, and content moderation.
@Form([
  // Antivirus and malware
  Field(
    'antivirusScanningEnabled',
    bool,
    'Antivirus Scanning Enabled',
    required: true,
    hint:
        'Yes | No — whether uploaded files are scanned by antivirus before acceptance',
  ),
  Field(
    'scanTiming',
    String,
    'Scan Timing',
    hint:
        'OnUpload | Asynchronous | OnAccess | Periodic — when scanning occurs',
  ),
  Field(
    'scanEngine',
    String,
    'Scan Engine',
    hint:
        'ClamAV | CloudProvider | ThirdPartyAPI | Multiple — scanning engine or service used',
  ),
  Field(
    'quarantinePolicy',
    String,
    'Quarantine Policy',
    hint:
        'Quarantine | Reject | NotifyAndQuarantine — action when malicious content is detected',
  ),
  Field(
    'quarantineRetentionDays',
    int,
    'Quarantine Retention Days',
    hint:
        'Number of days quarantined files are retained before permanent deletion',
  ),
  Field(
    'signatureUpdateFrequency',
    String,
    'Signature Update Frequency',
    hint:
        'Hourly | Daily | RealTime — how often antivirus signatures are updated',
  ),

  // Content Disarm and Reconstruct
  Field(
    'cdrEnabled',
    bool,
    'CDR (Content Disarm & Reconstruct) Enabled',
    hint:
        'Yes | No — whether CDR is applied to office documents, PDFs, and similar file types',
  ),
  Field(
    'cdrApplicableTypes',
    String,
    'CDR Applicable File Types',
    hint: 'PDF | DOCX | XLSX | Images — file types processed by CDR',
  ),

  // Data loss prevention
  Field(
    'dlpScanningEnabled',
    bool,
    'DLP Scanning Enabled',
    hint:
        'Yes | No — scan file contents for sensitive data (PII, credit cards, health records)',
  ),
  Field(
    'dlpPolicies',
    String,
    'DLP Policies',
    hint:
        'Regex patterns, trained classifiers, keyword lists — methods for detecting sensitive data in files',
  ),
  Field(
    'dlpAction',
    String,
    'DLP Action on Detection',
    hint:
        'Block | Redact | Notify | Quarantine — action when DLP detects sensitive content',
  ),

  // Content moderation
  Field(
    'contentModeration',
    bool,
    'Content Moderation',
    hint: 'Yes | No — scan for illegal, offensive, or policy-violating content',
  ),
  Field(
    'moderationMethod',
    String,
    'Moderation Method',
    hint: 'Automated | ManualReview | Hybrid — approach to content moderation',
  ),
  Field(
    'hashBasedDetection',
    bool,
    'Hash-Based Detection',
    hint:
        'Yes | No — use file hash databases (e.g. VirusTotal) to detect known-malicious files',
  ),
  Field('notes', String, 'Notes', hint: 'Additional content scanning notes'),
])
@StandardReferences(
  [
    'OWASP ASVS 4.0 — V12 file and resources verification',
    'ISO/IEC 27001:2022 — control A.8.26 application security requirements',
    'NIST SP 800-53 — control SC-28 protection of information at rest',
  ],
  'Defines how uploaded and stored files are scanned for malware, sensitive data, and policy-violating content.',
)
@SectionId('COSCPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class ContentScanningPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Content Scanning Details (text).
  @SerializationOrder(1)
  TextSection contentScanningDetails = TextSection();
}

/// File download security policy — how file downloads are protected,
/// including rate limiting, access logging, and content disposition.
///
/// Covers download authentication, bandwidth protection, content disposition
/// headers, hot-link prevention, and download audit logging.
@Form([
  // Download protection
  Field(
    'downloadAuthenticationRequired',
    bool,
    'Download Authentication Required',
    required: true,
    hint: 'Yes | No — whether authentication is required for file downloads',
  ),
  Field(
    'downloadRateLimiting',
    bool,
    'Download Rate Limiting',
    hint: 'Yes | No — rate limit file downloads per user/IP to prevent DoS',
  ),
  Field(
    'downloadRateLimit',
    String,
    'Download Rate Limit',
    hint: 'Maximum downloads per minute/hour/day per user or IP',
  ),
  Field(
    'bandwidthThrottling',
    bool,
    'Bandwidth Throttling',
    hint: 'Yes | No — throttle download bandwidth per user to prevent abuse',
  ),

  // Content disposition and delivery
  Field(
    'contentDispositionPolicy',
    String,
    'Content-Disposition Policy',
    hint:
        'Attachment | Inline | PerType — how Content-Disposition header is set (Attachment recommended for untrusted content)',
  ),
  Field(
    'cdnDelivery',
    bool,
    'CDN Delivery',
    hint:
        'Yes | No — serve files through a CDN for performance and DDoS protection',
  ),
  Field(
    'hotlinkPrevention',
    bool,
    'Hotlink Prevention',
    hint: 'Yes | No — prevent direct linking to files from external sites',
  ),
  Field(
    'cacheControlPolicy',
    String,
    'Cache-Control Policy',
    hint:
        'NoStore | Private | PublicShortTTL — cache directives for file download responses',
  ),

  // Audit and tracking
  Field(
    'downloadAuditLogging',
    bool,
    'Download Audit Logging',
    hint:
        'Yes | No — log all file download events with user, timestamp, file, and IP',
  ),
  Field(
    'downloadAlerts',
    bool,
    'Download Alerts',
    hint:
        'Yes | No — alert on unusual download patterns (bulk downloads, sensitive files)',
  ),
  Field(
    'watermarking',
    bool,
    'File Watermarking',
    hint:
        'Yes | No — apply invisible watermarks to downloaded files for traceability',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional file download security notes',
  ),
])
@StandardReferences(
  [
    'OWASP ASVS 4.0 — V12 file and resources verification',
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
    'NIST SP 800-53 — control AC-3 access enforcement',
  ],
  'Defines how file downloads are protected through authentication, rate limiting, content disposition, and audit logging.',
)
@SectionId('FDSP')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class FileDownloadSecurityPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Download Security Details (text).
  @SerializationOrder(1)
  TextSection downloadSecurityDetails = TextSection();
}

/// Storage lifecycle policy — retention, archiving, versioning, and
/// secure deletion of stored files.
///
/// Covers retention rules, archival tiers, versioning, backup schedules,
/// secure deletion methods, and compliance-driven retention requirements.
@Form([
  // Retention
  Field(
    'retentionPolicy',
    String,
    'Retention Policy',
    required: true,
    hint:
        'TimeBased | Indefinite | ComplianceDriven — default file retention strategy',
  ),
  Field(
    'defaultRetentionPeriod',
    String,
    'Default Retention Period',
    hint:
        'Default duration files are kept before eligible for deletion (e.g. 90 days, 7 years)',
  ),
  Field(
    'retentionByFileType',
    bool,
    'Retention by File Type',
    hint:
        'Yes | No — different retention periods for different file categories',
  ),
  Field(
    'legalHoldSupport',
    bool,
    'Legal Hold Support',
    hint:
        'Yes | No — ability to place legal holds preventing deletion regardless of retention policy',
  ),

  // Archiving
  Field(
    'archivingEnabled',
    bool,
    'Archiving Enabled',
    hint:
        'Yes | No — whether files are moved to low-cost archival tiers after a defined period',
  ),
  Field(
    'archivalStorageTier',
    String,
    'Archival Storage Tier',
    hint:
        'Glacier | ColdStorage | NearlineStorage — target tier for archived files',
  ),
  Field(
    'archivalTransitionDays',
    int,
    'Archival Transition Days',
    hint:
        'Number of days after last access before files move to archival storage',
  ),

  // Versioning
  Field(
    'versioningEnabled',
    bool,
    'File Versioning Enabled',
    hint:
        'Yes | No — maintain previous versions of overwritten or modified files',
  ),
  Field(
    'maxVersions',
    int,
    'Max Versions Retained',
    hint: 'Maximum number of previous versions to retain per file',
  ),
  Field(
    'versionRetentionDays',
    int,
    'Version Retention Days',
    hint: 'Number of days previous versions are retained',
  ),

  // Backup
  Field(
    'backupSchedule',
    String,
    'Backup Schedule',
    hint: 'Daily | Hourly | Continuous — frequency of file storage backups',
  ),
  Field(
    'backupRetentionDays',
    int,
    'Backup Retention Days',
    hint: 'Number of days file backups are retained',
  ),
  Field(
    'crossRegionReplication',
    bool,
    'Cross-Region Replication',
    hint:
        'Yes | No — replicate file storage to a secondary region for disaster recovery',
  ),

  // Secure deletion
  Field(
    'secureDeletionMethod',
    String,
    'Secure Deletion Method',
    hint:
        'CryptoShred | Overwrite | StandardDelete — method for permanent file deletion',
  ),
  Field(
    'deletionConfirmation',
    bool,
    'Deletion Confirmation Required',
    hint:
        'Yes | No — require explicit confirmation or approval for permanent file deletion',
  ),
  Field(
    'deletionAuditLogging',
    bool,
    'Deletion Audit Logging',
    hint:
        'Yes | No — log all file deletion events for compliance and forensics',
  ),
  Field('notes', String, 'Notes', hint: 'Additional storage lifecycle notes'),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.33 protection of records',
    'ISO/IEC 27001:2022 — control A.8.10 information deletion',
    'NIST SP 800-53 — control SC-28 protection of information at rest',
  ],
  'Defines retention, archiving, versioning, backup, and secure deletion rules across the lifecycle of stored files.',
)
@SectionId('STLIPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class StorageLifecyclePolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Storage Lifecycle Details (text).
  @SerializationOrder(1)
  TextSection storageLifecycleDetails = TextSection();
}

// ---------------------------------------------------------------------------
// 9.4.1. Authorization Model
// ---------------------------------------------------------------------------

/// 9.4.1. Authorization Model.
///
/// Describes the authorization model used by the system — RBAC, ABAC, ReBAC,
/// or hybrid. Covers access control model selection, permission granularity
/// (function-level, data-level, field-level), permission composition strategy,
/// access constraints, and evaluation behavior.
@StandardReferences(
  [
    'NIST RBAC INCITS 359-2012 — role-based access control',
    'NIST SP 800-162 — attribute-based access control',
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ],
  'Describes the authorization model used by the system such as RBAC, ABAC, ReBAC, or a hybrid.',
)
@SectionId('AUMO')
@CodeSpecKind([CodeSpecPart.authorization])
class AuthorizationModel extends DocSpecsSection {
  @ContentHelp('''
Define the authorization model that governs who can do what in the system.

**Access control models:**
- **RBAC (Role-Based)**: Permissions assigned to roles; users assigned to roles
  - Simple, auditable, good for well-defined job functions
  - Risk of role explosion in complex organizations
- **ABAC (Attribute-Based)**: Decisions based on user/resource/environment attributes
  - Flexible, dynamic, supports complex policies
  - XACML/ALFA policy languages; NIST SP 800-162
- **ReBAC (Relationship-Based)**: Permissions based on relationships (e.g., "owner of")
  - Natural for social apps, document sharing, organizational hierarchies
  - Examples: Google Zanzibar, OpenFGA, Ory Keto
- **Hybrid**: Combine models for different resource types

**Permission granularity:**
- Function-level: can user invoke this operation?
- Data-level: can user access this resource instance?
- Field-level: which fields can user read/write?

**Permission composition:**
- Additive: user gets union of all granted permissions
- Deny-overrides: explicit deny supersedes grants
- Most-specific-wins: closest match takes precedence

**Evaluation behavior:**
- Default-deny: no access unless explicitly granted
- Fail-closed: errors result in access denied
- Decision caching and invalidation strategy

**Reference:**
- NIST RBAC Model (NIST SP 800-207)
- NIST ABAC Guide (NIST SP 800-162)
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Access Control Model Selection.
  @SerializationOrder(1)
  AccessControlModelSelection accessControlModelSelection =
      AccessControlModelSelection();

  /// Permission Granularity.
  @SerializationOrder(2)
  PermissionGranularityPolicy permissionGranularity =
      PermissionGranularityPolicy();

  /// Permission Composition Strategy.
  @SerializationOrder(3)
  PermissionCompositionStrategy permissionComposition =
      PermissionCompositionStrategy();

  /// Access Constraint Policies.
  @SerializationOrder(4)
  AccessConstraintPolicies accessConstraints = AccessConstraintPolicies();

  /// Permission Evaluation Behavior.
  @SerializationOrder(5)
  PermissionEvaluationBehavior permissionEvaluation =
      PermissionEvaluationBehavior();

  /// Authorization Model Notes (text).
  @SerializationOrder(6)
  TextSection authorizationModelNotes = TextSection();
}

/// Access Control Model Selection (form).
///
/// Defines the primary access control paradigm — RBAC, ABAC, ReBAC, or a
/// combination — and the rationale for the choice.
@Form([
  Field(
    'primaryModel',
    String,
    'Primary Model',
    required: true,
    hint:
        'RBAC | ABAC | ReBAC | Hybrid-RBAC-ABAC | Hybrid-RBAC-ReBAC | '
        'Hybrid-ABAC-ReBAC | Hybrid-All — primary access control paradigm',
  ),
  Field(
    'modelRationale',
    String,
    'Model Rationale',
    hint: 'Why this model was chosen over alternatives',
  ),
  Field(
    'rbacEnabled',
    bool,
    'RBAC Enabled',
    hint:
        'Yes | No — role-based access control with permissions assigned to '
        'roles rather than directly to users',
  ),
  Field(
    'abacEnabled',
    bool,
    'ABAC Enabled',
    hint:
        'Yes | No — attribute-based access control using subject, resource, '
        'action, and environment attributes per NIST SP 800-162',
  ),
  Field(
    'rebacEnabled',
    bool,
    'ReBAC Enabled',
    hint:
        'Yes | No — relationship-based access control granting access based '
        'on relationships between resources and users (e.g. Zanzibar model)',
  ),
  Field(
    'policyLanguage',
    String,
    'Policy Language',
    hint:
        'XACML | OPA-Rego | CedarPolicy | CustomDSL | None — formal policy '
        'language for expressing access control rules',
  ),
  Field(
    'policyDecisionPoint',
    String,
    'Policy Decision Point',
    hint:
        'Embedded | ExternalPDP | Sidecar | CloudService — where access '
        'control decisions are evaluated',
  ),
  Field(
    'policyEnforcementPoint',
    String,
    'Policy Enforcement Point',
    hint:
        'APIGateway | Middleware | ServiceMesh | InApplication — where access '
        'control decisions are enforced',
  ),
  Field(
    'policyAdministrationPoint',
    String,
    'Policy Administration Point',
    hint:
        'AdminUI | ConfigFile | PolicyRepository | ExternalService — where '
        'policies are managed and maintained',
  ),
  Field(
    'policyInformationPoint',
    String,
    'Policy Information Point',
    hint:
        'UserDirectory | AttributeStore | ExternalIdP | Database — source '
        'of attributes used in access decisions',
  ),
  Field(
    'delegationModel',
    String,
    'Delegation Model',
    hint:
        'None | Administrative | UserInitiated | Hierarchical — whether and '
        'how permissions can be delegated between users',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional access control model selection notes',
  ),
])
@StandardReferences(
  [
    'NIST RBAC INCITS 359-2012 — role-based access control',
    'NIST SP 800-162 — attribute-based access control',
  ],
  'Defines the primary access control paradigm such as RBAC or ABAC and the rationale for the choice.',
)
@SectionId('ACMS')
@CodeSpecKind([CodeSpecPart.authorization])
class AccessControlModelSelection extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Access Control Model Details (text).
  @SerializationOrder(1)
  TextSection accessControlModelDetails = TextSection();
}

/// Permission Granularity Policy (form).
///
/// Defines the levels at which permissions can be specified — from coarse
/// function-level through fine-grained field-level control.
@Form([
  Field(
    'functionLevelControl',
    bool,
    'Function-Level Control',
    hint:
        'Yes | No — permissions control access to entire functions, '
        'operations, or API endpoints',
  ),
  Field(
    'dataLevelControl',
    bool,
    'Data-Level Control',
    hint:
        'Yes | No — permissions control access to specific data records, '
        'rows, or resource instances (horizontal access control)',
  ),
  Field(
    'fieldLevelControl',
    bool,
    'Field-Level Control',
    hint:
        'Yes | No — permissions control access to individual fields or '
        'attributes within a record (column-level security)',
  ),
  Field(
    'uiElementControl',
    bool,
    'UI Element Control',
    hint:
        'Yes | No — permissions control visibility or availability of '
        'UI components, menus, or actions',
  ),
  Field(
    'apiOperationControl',
    bool,
    'API Operation Control',
    hint:
        'Yes | No — permissions are specific to individual API operations '
        '(GET, POST, PUT, DELETE on specific resources)',
  ),
  Field(
    'objectLevelControl',
    bool,
    'Object-Level Control',
    hint:
        'Yes | No — permissions apply to individual business object instances '
        '(IDOR prevention through ownership checks)',
  ),
  Field(
    'tenantLevelControl',
    bool,
    'Tenant-Level Control',
    hint:
        'Yes | No — permissions provide isolation between tenants in a '
        'multi-tenant system',
  ),
  Field(
    'finestGranularity',
    String,
    'Finest Granularity',
    hint:
        'Function | Data | Field | UIElement | APIOperation | Object — the '
        'finest level of permission granularity supported',
  ),
  Field(
    'dynamicPermissions',
    bool,
    'Dynamic Permissions',
    hint:
        'Yes | No — permissions can change dynamically based on runtime '
        'context (time, location, device, risk score)',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional permission granularity notes',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.15 access control',
    'NIST SP 800-53 — control AC-6 least privilege',
  ],
  'Defines the levels at which permissions can be specified from function-level through field-level control.',
)
@SectionId('PEGRPO')
@CodeSpecKind([CodeSpecPart.authorization])
class PermissionGranularityPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Permission Granularity Details (text).
  @SerializationOrder(1)
  TextSection permissionGranularityDetails = TextSection();
}

/// Permission Composition Strategy (form).
///
/// Defines how permissions from multiple sources (roles, groups, attributes)
/// are combined to produce an effective permission set.
@Form([
  Field(
    'compositionModel',
    String,
    'Composition Model',
    required: true,
    hint:
        'Additive | Subtractive | MostRestrictive | LeastRestrictive | '
        'OrderedPrecedence | WeightedPriority — how permissions compose',
  ),
  Field(
    'defaultPolicy',
    String,
    'Default Policy',
    required: true,
    hint:
        'DenyByDefault | AllowByDefault — action when no explicit rule '
        'matches (OWASP: always deny by default)',
  ),
  Field(
    'explicitDenyOverride',
    bool,
    'Explicit Deny Override',
    hint:
        'Yes | No — whether explicit deny always overrides any allow '
        '(deny-trumps-allow semantics)',
  ),
  Field(
    'rolePermissionInheritance',
    bool,
    'Role Permission Inheritance',
    hint:
        'Yes | No — whether child roles inherit permissions from parent '
        'roles in a hierarchy',
  ),
  Field(
    'groupPermissionAggregation',
    String,
    'Group Permission Aggregation',
    hint:
        'Union | Intersection | FirstMatch — how permissions from multiple '
        'group memberships combine',
  ),
  Field(
    'conflictResolution',
    String,
    'Conflict Resolution',
    hint:
        'DenyWins | AllowWins | MostSpecificWins | ExplicitWins | '
        'PriorityBased — how conflicting permissions are resolved',
  ),
  Field(
    'permissionBoundary',
    bool,
    'Permission Boundary',
    hint:
        'Yes | No — whether a maximum permission boundary constrains '
        'effective permissions regardless of assigned roles',
  ),
  Field(
    'scopedPermissions',
    bool,
    'Scoped Permissions',
    hint:
        'Yes | No — whether permissions can be scoped to specific contexts '
        '(e.g. project, department, time window)',
  ),
  Field(
    'temporaryElevation',
    bool,
    'Temporary Elevation',
    hint:
        'Yes | No — whether time-limited permission elevation is supported '
        '(just-in-time access, break-glass procedures)',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional permission composition notes',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.15 access control',
    'NIST SP 800-53 — control AC-6 least privilege',
  ],
  'Defines how permissions from multiple sources combine into an effective permission set.',
)
@SectionId('PECOST')
@CodeSpecKind([CodeSpecPart.authorization])
class PermissionCompositionStrategy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Permission Composition Details (text).
  @SerializationOrder(1)
  TextSection permissionCompositionDetails = TextSection();
}

/// Access Constraint Policies (form).
///
/// Defines constraints that restrict access beyond basic role/attribute
/// assignments — separation of duties, temporal, environmental, and
/// risk-adaptive constraints.
@Form([
  Field(
    'separationOfDuties',
    bool,
    'Separation of Duties',
    hint:
        'Yes | No — enforce static or dynamic separation of duties to '
        'prevent conflicts of interest (e.g. creator cannot approve)',
  ),
  Field(
    'sodEnforcement',
    String,
    'SoD Enforcement',
    hint:
        'Static | Dynamic | Both — whether separation of duties is enforced '
        'at role-assignment time (static) or at runtime (dynamic)',
  ),
  Field(
    'temporalConstraints',
    bool,
    'Temporal Constraints',
    hint:
        'Yes | No — time-based access restrictions (business hours, '
        'maintenance windows, embargo periods)',
  ),
  Field(
    'locationConstraints',
    bool,
    'Location Constraints',
    hint:
        'Yes | No — geographic or network-based access restrictions '
        '(IP range, geofencing, VPN requirement)',
  ),
  Field(
    'deviceConstraints',
    bool,
    'Device Constraints',
    hint:
        'Yes | No — device-based access restrictions (managed devices, '
        'compliance status, device type)',
  ),
  Field(
    'riskAdaptiveAccess',
    bool,
    'Risk-Adaptive Access',
    hint:
        'Yes | No — access decisions consider real-time risk scores '
        '(user behavior, threat intelligence, anomaly detection)',
  ),
  Field(
    'contextualAttributes',
    String,
    'Contextual Attributes',
    hint:
        'Comma-separated list of contextual attributes used in access '
        'decisions (e.g. time, location, device, riskScore, '
        'authenticationLevel, networkZone)',
  ),
  Field(
    'maxSessionPermissions',
    bool,
    'Max Session Permissions',
    hint:
        'Yes | No — limit the maximum number of active permissions per '
        'session to reduce exposure from compromised sessions',
  ),
  Field(
    'leastPrivilegeEnforcement',
    String,
    'Least Privilege Enforcement',
    hint:
        'Manual | Automated | ContinuousReview — how least privilege '
        'principle is enforced and verified over time',
  ),
  Field(
    'privilegeCreepDetection',
    bool,
    'Privilege Creep Detection',
    hint:
        'Yes | No — automatically detect users who accumulate excessive '
        'permissions over time through role changes',
  ),
  Field('notes', String, 'Notes', hint: 'Additional access constraint notes'),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control AC-6 least privilege',
    'NIST SP 800-53 — control AC-5 separation of duties',
    'NIST SP 800-162 — attribute-based access control',
  ],
  'Defines constraints that restrict access beyond basic role or attribute assignments.',
)
@SectionId('ACCOPO')
@CodeSpecKind([CodeSpecPart.authorization])
class AccessConstraintPolicies extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Access Constraint Details (text).
  @SerializationOrder(1)
  TextSection accessConstraintDetails = TextSection();
}

/// Permission Evaluation Behavior (form).
///
/// Defines how the system evaluates and enforces access control decisions
/// at runtime — server-side checks, caching, failure handling, and testing.
@Form([
  Field(
    'evaluationLocation',
    String,
    'Evaluation Location',
    required: true,
    hint:
        'ServerSide | Gateway | ServiceMesh | Serverless — where permission '
        'checks are performed (OWASP: never client-side only)',
  ),
  Field(
    'evaluationFrequency',
    String,
    'Evaluation Frequency',
    required: true,
    hint:
        'EveryRequest | SessionStart | Cached | Lazy — how often permissions '
        'are re-evaluated (OWASP: validate on every request)',
  ),
  Field(
    'cachingStrategy',
    String,
    'Caching Strategy',
    hint:
        'None | ShortLived | SessionBound | DistributedCache — permission '
        'decision caching approach and TTL',
  ),
  Field(
    'cacheTtlSeconds',
    int,
    'Cache TTL (Seconds)',
    hint: 'Maximum time in seconds before cached permission decisions expire',
  ),
  Field(
    'failureMode',
    String,
    'Failure Mode',
    required: true,
    hint:
        'DenyOnFailure | LastKnownGood | DegradedAccess — behavior when '
        'the authorization service is unavailable (OWASP: exit safely)',
  ),
  Field(
    'authorizationLogging',
    bool,
    'Authorization Logging',
    hint:
        'Yes | No — log all access control decisions including grants and '
        'denials for audit and incident response',
  ),
  Field(
    'logDeniedRequests',
    bool,
    'Log Denied Requests',
    hint: 'Yes | No — log details of all denied access attempts',
  ),
  Field(
    'logSuccessfulAccess',
    bool,
    'Log Successful Access',
    hint:
        'Yes | No — log successful access to sensitive resources for '
        'forensic analysis',
  ),
  Field(
    'automatedTesting',
    bool,
    'Automated Testing',
    hint:
        'Yes | No — unit and integration tests verify authorization logic '
        '(OWASP: catch low-hanging security issues early)',
  ),
  Field(
    'clientSideHints',
    bool,
    'Client-Side Hints',
    hint:
        'Yes | No — provide permission hints to UI for UX purposes while '
        'enforcing all checks server-side',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional permission evaluation behavior notes',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.15 access control',
    'NIST SP 800-53 — control AC-6 least privilege',
  ],
  'Defines how the system evaluates and enforces access control decisions at runtime.',
)
@SectionId('PEEVBE')
@CodeSpecKind([CodeSpecPart.authorization])
class PermissionEvaluationBehavior extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Permission Evaluation Details (text).
  @SerializationOrder(1)
  TextSection permissionEvaluationDetails = TextSection();
}

/// 9.4. User Authorization.
///
/// Aligns with Tom Core authorization model: groups → roles → entitlements → resourceKeys.
@StandardReferences(
  [
    'NIST RBAC INCITS 359-2012 — role-based access control',
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ],
  'Defines the complete user authorization structure of groups, roles, entitlements, and resource keys.',
)
@SectionId('USAU')
@DetailedIn(D08SecurityAccessSpecification)
@CodeSpecKind([CodeSpecPart.authorization])
class UserAuthorization extends DocSpecsSection {
  @ContentHelp('''
Define the complete authorization structure that controls what users can do.
Aligned with Tom Core authorization model.

**Authorization hierarchy:**
1. **Groups**: Organizational containers for users (departments, teams, projects)
2. **Roles**: Named collections of entitlements assigned to users or groups
3. **Entitlements**: Atomic permissions representing specific actions
4. **Resource Keys**: Fine-grained identifiers for protected resources

**Key components:**
- Authorization model (RBAC, ABAC, ReBAC, or hybrid)
- Role definitions with assigned entitlements
- Role hierarchy and inheritance rules
- Tenant isolation for multi-tenant deployments

**Design principles:**
- Least privilege: users get minimum permissions needed
- Separation of duties: critical operations require multiple approvals
- Default deny: no access unless explicitly granted
- Clear ownership: every role/entitlement has an owner

**Compliance considerations:**
- SOX: segregation of duties, access recertification
- GDPR: data access controls, right to be forgotten
- PCI DSS: need-to-know for cardholder data
- SOC 2: logical access controls (CC6.1-CC6.3)
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.4.1. Authorization Model.
  @SerializationOrder(1)
  AuthorizationModel authorizationModel = AuthorizationModel();

  /// 9.4.2. Authorization Groups — contains 0+× Group.
  @StandardReferences(
    ['NIST RBAC INCITS 359-2012 — role and group membership assignment'],
    'The catalog of authorization groups that organize users for role assignment.',
  )
  @SectionId('AZGR-GROU-LST')
  @SectionIdPattern('AZGR-GROU-xxx')
  @ContentHelp('Add one entry per authorization group.')
  @SerializationOrder(2)
  List<AuthorizationGroupEntry> groups = [];

  /// 9.4.3. Role Definitions — contains 1+× Role.
  @StandardReferences(
    ['NIST RBAC INCITS 359-2012 — role-based access control'],
    'The catalog of authorization roles that bundle entitlements for assignment.',
  )
  @SectionId('AZRO-ROLE-LST')
  @SectionIdPattern('AZRO-ROLE-xxx')
  @ContentHelp('Add one entry per authorization role.')
  @Min(1)
  @SerializationOrder(3)
  List<AuthorizationRoleEntry> roleDefinitions = [];

  /// 9.4.4. Entitlements — contains 1+× Entitlement.
  @StandardReferences([
    'NIST RBAC INCITS 359-2012 — permissions assigned to roles',
  ], 'The catalog of entitlements representing atomic permissions.')
  @SectionId('ENT-ENTI-LST')
  @SectionIdPattern('ENT-ENTI-xxx')
  @ContentHelp('Add one entry per entitlement.')
  @Min(1)
  @SerializationOrder(4)
  List<EntitlementEntry> entitlements = [];

  /// 9.4.5. Resource Keys — contains 0+× Resource Key.
  @StandardReferences([
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ], 'The catalog of protected resources identified by resource keys.')
  @SectionId('RESKEY-RESO-LST')
  @SectionIdPattern('RESKEY-RESO-xxx')
  @ContentHelp('Add one entry per protected resource.')
  @SerializationOrder(5)
  List<ResourceKeyEntry> resourceKeys = [];

  /// 9.4.6. Role Hierarchy.
  @SerializationOrder(6)
  RoleHierarchy roleHierarchy = RoleHierarchy();

  /// 9.4.7. Tenant Isolation.
  @SerializationOrder(7)
  TenantIsolation tenantIsolation = TenantIsolation();
}

// ---------------------------------------------------------------------------
// 9.4.6. Role Hierarchy
// ---------------------------------------------------------------------------

/// 9.4.6. Role Hierarchy.
///
/// Defines the role hierarchy: inheritance rules, mutual exclusions,
/// role combination constraints, hierarchy depth, and role certification
/// policies. Aligns with NIST hierarchical RBAC model.
@StandardReferences(
  [
    'NIST RBAC INCITS 359-2012 — hierarchical RBAC and role inheritance',
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ],
  'Defines the role hierarchy including inheritance rules, mutual exclusions, and role certification policies.',
)
@SectionId('ROHI')
@CodeSpecKind([CodeSpecPart.authorization])
class RoleHierarchy extends DocSpecsSection {
  @ContentHelp('''
Define role inheritance and combination rules. A well-designed role hierarchy
simplifies administration and ensures consistent access control.

**Inheritance rules:**
- Senior roles inherit all permissions of junior roles
- Example: Manager inherits Employee permissions
- Maximum hierarchy depth (typically 3–5 levels)
- Circular inheritance detection and prevention

**Mutual exclusions (Separation of Duties):**
- Roles that cannot be held simultaneously
- Example: Payment Approver and Payment Initiator
- Enforce at assignment time and during role evaluation

**Role combination constraints:**
- Required role combinations (must have both A and B)
- Forbidden combinations (cannot have both X and Y)
- Cardinality limits (max N users per role)

**Role certification:**
- Periodic review of role assignments
- Manager/owner approval for sensitive roles
- Automatic revocation of uncertified access

**Implementation:**
- Pre-compute effective permissions at assignment time (fast evaluation)
- Or evaluate hierarchy at runtime (flexible but slower)
- Cache invalidation on role/hierarchy changes

**Reference:**
- NIST RBAC Model — Hierarchical RBAC (RBAC₂)
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Role Hierarchy Policy.
  @SerializationOrder(1)
  RoleHierarchyPolicy hierarchyPolicy = RoleHierarchyPolicy();

  /// Contains 0+× RoleInheritanceRule.
  @StandardReferences(
    ['NIST RBAC INCITS 359-2012 — hierarchical RBAC and role inheritance'],
    'The catalog of role inheritance relationships between parent and child roles.',
  )
  @SectionId('RLINH-INHE-LST')
  @SectionIdPattern('RLINH-INHE-xxx')
  @ContentHelp('Add one entry per role inheritance relationship.')
  @SerializationOrder(2)
  List<RoleInheritanceRuleEntry> inheritanceRules = [];

  /// Contains 0+× RoleCombinationConstraint.
  @StandardReferences(
    [
      'NIST RBAC INCITS 359-2012 — constrained RBAC and static separation of duty',
    ],
    'The catalog of role combination rules that govern which roles can coexist.',
  )
  @SectionId('RLCMB-COMB-LST')
  @SectionIdPattern('RLCMB-COMB-xxx')
  @ContentHelp('Add one entry per role combination rule.')
  @SerializationOrder(3)
  List<RoleCombinationConstraintEntry> combinationConstraints = [];

  /// Contains 0+× GlobalRoleExclusion.
  @StandardReferences([
    'NIST SP 800-53 — control AC-5 separation of duties',
  ], 'The catalog of global role exclusions enforcing separation of duties.')
  @SectionId('GBRLX-GLOB-LST')
  @SectionIdPattern('GBRLX-GLOB-xxx')
  @ContentHelp('Add one entry per global role exclusion.')
  @SerializationOrder(4)
  List<GlobalRoleExclusionEntry> globalExclusions = [];

  /// Role Certification and Review.
  @SerializationOrder(5)
  RoleCertificationPolicy roleCertification = RoleCertificationPolicy();

  /// Role Hierarchy Notes (text).
  @SerializationOrder(6)
  TextSection roleHierarchyNotes = TextSection();
}

/// Role Hierarchy Policy (form).
///
/// Global settings governing how the role hierarchy is structured and
/// how inheritance, depth, and activation constraints work.
@Form([
  Field(
    'hierarchyModel',
    String,
    'Hierarchy Model',
    required: true,
    hint:
        'Tree | DAG | Flat | Layered — structure of the role hierarchy '
        '(tree = single parent, DAG = multiple parents, flat = no '
        'inheritance, layered = tiered levels)',
  ),
  Field(
    'maxHierarchyDepth',
    int,
    'Maximum Hierarchy Depth',
    hint:
        'Maximum number of inheritance levels allowed (e.g. 5); '
        '0 = unlimited depth',
  ),
  Field(
    'inheritanceMode',
    String,
    'Inheritance Mode',
    hint:
        'Full | Selective | None — whether child roles automatically '
        'inherit all parent permissions (full), selected permissions '
        '(selective), or none',
  ),
  Field(
    'multipleInheritance',
    bool,
    'Multiple Inheritance',
    hint:
        'Yes | No — whether a role can inherit from more than one '
        'parent role (DAG model)',
  ),
  Field(
    'permissionOverride',
    bool,
    'Permission Override',
    hint:
        'Yes | No — whether child roles can override (restrict or extend) '
        'inherited permissions from parent roles',
  ),
  Field(
    'activationConstraints',
    bool,
    'Activation Constraints',
    hint:
        'Yes | No — whether role activation is subject to constraints '
        '(time-based, prerequisite roles, approval workflows)',
  ),
  Field(
    'maxActiveRolesPerUser',
    int,
    'Max Active Roles Per User',
    hint:
        'Maximum number of roles a single user can hold simultaneously; '
        '0 = unlimited',
  ),
  Field(
    'rolePriorityScheme',
    String,
    'Role Priority Scheme',
    hint:
        'HierarchyLevel | ExplicitWeight | None — how conflicts between '
        'equal-level roles are resolved',
  ),
  Field(
    'automaticInheritanceRevocation',
    bool,
    'Automatic Inheritance Revocation',
    hint:
        'Yes | No — whether removing a parent role automatically revokes '
        'inherited child-role permissions',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional role hierarchy policy notes',
  ),
])
@StandardReferences(
  [
    'NIST RBAC INCITS 359-2012 — hierarchical RBAC and role inheritance',
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ],
  'Defines the global settings governing how the role hierarchy is structured and how inheritance works.',
)
@SectionId('ROHIPO')
@CodeSpecKind([CodeSpecPart.authorization])
class RoleHierarchyPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Role Hierarchy Policy Details (text).
  @SerializationOrder(1)
  TextSection roleHierarchyPolicyDetails = TextSection();
}

/// A role inheritance rule entry (form).
///
/// Defines a specific parent-child inheritance relationship between two roles,
/// including what is inherited and any restrictions.
@StandardReferences([
  'NIST RBAC INCITS 359-2012 — hierarchical RBAC and role inheritance',
], 'Defines one parent-child inheritance relationship between two roles.')
@SectionId('RLINH')
@CodeSpecKind([CodeSpecPart.authorization])
class RoleInheritanceRuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'parentRole',
      String,
      'Parent Role',
      required: true,
      hint: 'Name of the parent role whose permissions are inherited',
    ),
    Field(
      'childRole',
      String,
      'Child Role',
      required: true,
      hint: 'Name of the child role that inherits permissions',
    ),
    Field(
      'inheritanceType',
      String,
      'Inheritance Type',
      hint:
          'Full | PermissionsOnly | ResponsibilitiesOnly | Selective — '
          'what aspects of the parent role are inherited',
    ),
    Field(
      'excludedPermissions',
      String,
      'Excluded Permissions',
      hint:
          'Comma-separated permission keys explicitly excluded from '
          'inheritance (e.g. user.delete, config.manage)',
    ),
    Field(
      'additionalConditions',
      String,
      'Additional Conditions',
      hint:
          'Conditions under which this inheritance is active '
          '(e.g. same-department, same-tenant, business-hours)',
    ),
    Field(
      'overridable',
      bool,
      'Overridable',
      hint:
          'Yes | No — whether the child role can override inherited '
          'permissions from this parent',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A role combination constraint entry (form).
///
/// Defines rules about which roles can or cannot be combined — supports
/// separation of duties, prerequisite roles, and co-requisite roles.
@StandardReferences(
  [
    'NIST RBAC INCITS 359-2012 — constrained RBAC and static separation of duty',
    'NIST SP 800-53 — control AC-5 separation of duties',
  ],
  'Defines a rule about which roles can or cannot be combined for a single user.',
)
@SectionId('RLCMB')
@CodeSpecKind([CodeSpecPart.authorization])
class RoleCombinationConstraintEntry extends DocSpecsSection {
  @Form([
    Field(
      'constraintType',
      String,
      'Constraint Type',
      required: true,
      hint:
          'MutualExclusion | Prerequisite | Corequisite | MaxCombination — '
          'type of combination constraint',
    ),
    Field(
      'roleA',
      String,
      'Role A',
      required: true,
      hint: 'First role in the constraint',
    ),
    Field(
      'roleB',
      String,
      'Role B',
      required: true,
      hint: 'Second role in the constraint',
    ),
    Field(
      'enforcement',
      String,
      'Enforcement',
      hint:
          'Static | Dynamic | Both — static = enforced at assignment, '
          'dynamic = enforced at activation/runtime',
    ),
    Field(
      'severity',
      String,
      'Severity',
      hint:
          'Hard | Soft — hard = system-enforced block, '
          'soft = warning with override requiring approval',
    ),
    Field(
      'businessReason',
      String,
      'Business Reason',
      hint:
          'Business justification for the constraint '
          '(e.g. separation of duties, four-eyes principle)',
    ),
    Field(
      'exemptionProcess',
      String,
      'Exemption Process',
      hint:
          'None | ManagerApproval | SecurityOfficerApproval | '
          'CommitteeApproval — process for granting exemptions',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A global role exclusion entry (form).
///
/// Defines system-wide mutual exclusion rules that apply across all users,
/// independent of individual role definitions.
@StandardReferences(
  [
    'NIST SP 800-53 — control AC-5 separation of duties',
    'NIST RBAC INCITS 359-2012 — constrained RBAC and mutual exclusion',
  ],
  'Defines a system-wide mutual exclusion rule that applies across all users for separation of duties.',
)
@SectionId('GBRLX')
@CodeSpecKind([CodeSpecPart.authorization])
class GlobalRoleExclusionEntry extends DocSpecsSection {
  @Form([
    Field(
      'excludedRoleA',
      String,
      'Excluded Role A',
      required: true,
      hint: 'First mutually exclusive role',
    ),
    Field(
      'excludedRoleB',
      String,
      'Excluded Role B',
      required: true,
      hint: 'Second mutually exclusive role',
    ),
    Field(
      'reason',
      String,
      'Reason',
      hint:
          'Separation of duties rationale (e.g. the same person cannot '
          'both submit and approve financial transactions)',
    ),
    Field(
      'enforcementLevel',
      String,
      'Enforcement Level',
      hint: 'Hard | Soft — whether override is possible with approval',
    ),
    Field(
      'complianceReference',
      String,
      'Compliance Reference',
      hint:
          'Regulatory or policy reference requiring this exclusion '
          '(e.g. SOX Section 404, ISO 27001 A.6.1.2)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Role Certification Policy (form).
///
/// Defines how roles and role assignments are periodically reviewed and
/// certified to prevent privilege creep and ensure continued appropriateness.
@Form([
  Field(
    'certificationRequired',
    bool,
    'Certification Required',
    hint:
        'Yes | No — whether periodic role certification (access review) '
        'is mandated',
  ),
  Field(
    'certificationFrequency',
    String,
    'Certification Frequency',
    hint:
        'Monthly | Quarterly | SemiAnnual | Annual | OnChange — '
        'how often role certifications are conducted',
  ),
  Field(
    'certifier',
    String,
    'Certifier',
    hint:
        'Manager | RoleOwner | SecurityOfficer | Automated — who performs '
        'the certification review',
  ),
  Field(
    'nonResponseAction',
    String,
    'Non-Response Action',
    hint:
        'Revoke | Escalate | Extend | NoAction — what happens if the '
        'certifier does not respond within the deadline',
  ),
  Field(
    'riskBasedScheduling',
    bool,
    'Risk-Based Scheduling',
    hint:
        'Yes | No — whether high-risk role assignments are reviewed more '
        'frequently than low-risk ones',
  ),
  Field(
    'automatedDetection',
    bool,
    'Automated Detection',
    hint:
        'Yes | No — whether the system automatically detects and flags '
        'anomalous or dormant role assignments',
  ),
  Field(
    'dormantRoleThresholdDays',
    int,
    'Dormant Role Threshold (Days)',
    hint:
        'Number of days after which an unused role assignment is flagged '
        'as dormant (e.g. 90)',
  ),
  Field(
    'certificationAuditTrail',
    bool,
    'Certification Audit Trail',
    hint:
        'Yes | No — whether certification decisions are logged for '
        'compliance and audit purposes',
  ),
  Field('notes', String, 'Notes', hint: 'Additional role certification notes'),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control AC-6 least privilege',
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ],
  'Defines how roles and role assignments are periodically reviewed and certified to prevent privilege creep.',
)
@SectionId('ROCEPO')
@CodeSpecKind([CodeSpecPart.authorization])
class RoleCertificationPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Role Certification Details (text).
  @SerializationOrder(1)
  TextSection roleCertificationDetails = TextSection();
}

// ---------------------------------------------------------------------------
// 9.4.7. Tenant Isolation
// ---------------------------------------------------------------------------

/// 9.4.7. Tenant Isolation.
///
/// Describes how multi-tenant authorization is structured: how tenant context
/// is established and propagated, how cross-tenant access is prevented or
/// controlled, how tenants can customize their authorization model, how tenant
/// onboarding/offboarding is handled from an authorization perspective, and
/// how tenant boundaries are enforced at the authorization layer.
/// Complements TenantDataIsolationPolicy which covers
/// data-level isolation; this section focuses on authorization-level isolation.
@StandardReferences(
  [
    'ISO/IEC 27017 — cloud multi-tenancy isolation controls',
    'ISO/IEC 27001:2022 — control A.5.23 cloud service use',
  ],
  'Describes how multi-tenant authorization is structured and isolated at the authorization layer.',
)
@SectionId('TEIS')
@CodeSpecKind([CodeSpecPart.authorization])
class TenantIsolation extends DocSpecsSection {
  @ContentHelp('''
Define how multi-tenant authorization is structured at the application layer.
Complements data-level tenant isolation.

**Tenant context establishment:**
- How tenant is identified (subdomain, header, token claim, path)
- Validation of tenant context (user belongs to claimed tenant)
- Propagation through request lifecycle (thread-local, context object)

**Cross-tenant access prevention:**
- Default: all access is tenant-scoped
- Authorization checks include tenant predicate
- API responses filtered to current tenant only

**Controlled cross-tenant access:**
- Super-admin/platform-admin access across tenants
- Partner/reseller access to managed tenants
- Explicit grants with audit logging

**Per-tenant customization:**
- Custom roles and entitlements within tenant
- Tenant-specific password policies
- Tenant branding and configuration

**Tenant lifecycle:**
- Onboarding: default roles, admin user, initial configuration
- Offboarding: data deletion, user deactivation, audit retention

**Boundary enforcement:**
- Mandatory tenant context on all protected endpoints
- Fail-closed if tenant context is missing or invalid
- Logging of tenant context for all operations
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Tenant Context Policy.
  @SerializationOrder(1)
  TenantContextPolicy tenantContextPolicy = TenantContextPolicy();

  /// Cross-Tenant Access Policy.
  @SerializationOrder(2)
  CrossTenantAccessPolicy crossTenantAccessPolicy = CrossTenantAccessPolicy();

  /// Contains 0+× TenantCustomization.
  @StandardReferences([
    'ISO/IEC 27017 — cloud multi-tenancy isolation controls',
  ], 'The catalog of tenant-specific authorization customizations.')
  @SectionId('TNCS-TENA-LST')
  @SectionIdPattern('TNCS-TENA-xxx')
  @ContentHelp('Add one entry per tenant.')
  @SerializationOrder(3)
  List<TenantCustomizationEntry> tenantCustomizations = [];

  /// Tenant Onboarding Policy.
  @SerializationOrder(4)
  TenantOnboardingPolicy tenantOnboardingPolicy = TenantOnboardingPolicy();

  /// Tenant Boundary Enforcement Policy.
  @SerializationOrder(5)
  TenantBoundaryEnforcementPolicy boundaryEnforcement =
      TenantBoundaryEnforcementPolicy();

  /// Tenant Isolation Notes (text).
  @SerializationOrder(6)
  TextSection tenantIsolationNotes = TextSection();
}

/// Tenant Context Policy (form).
///
/// Defines how the tenant context is established, validated, and propagated
/// throughout authorization decisions. Covers context resolution, immutability,
/// cross-service propagation, and behavior when tenant context is missing.
/// Aligns with OWASP Multi-Tenant Security: Tenant Identification & Context
/// Management.
@Form([
  Field(
    'contextResolutionMethod',
    String,
    'Context Resolution Method',
    required: true,
    hint:
        'Token | Header | Domain | Path | Session | IDP-Asserted — how '
        'tenant identity is determined from incoming requests',
  ),
  Field(
    'contextPropagation',
    String,
    'Context Propagation',
    hint:
        'ThreadLocal | RequestScoped | ServiceMesh | TokenBased — how '
        'tenant context flows through application layers during '
        'authorization evaluation',
  ),
  Field(
    'contextValidation',
    String,
    'Context Validation',
    hint:
        'SessionBinding | TokenClaim | DatabaseLookup | IDP-Asserted — '
        'how tenant context is validated against the authenticated user',
  ),
  Field(
    'contextImmutability',
    bool,
    'Context Immutability',
    hint:
        'Yes | No — whether the tenant context is immutable once '
        'established for a request (prevents mid-request tampering)',
  ),
  Field(
    'crossServicePropagation',
    String,
    'Cross-Service Propagation',
    hint:
        'JwtClaim | Header | gRPC-Metadata | ContextObject — how tenant '
        'context propagates across service boundaries in distributed '
        'architectures',
  ),
  Field(
    'missingContextBehavior',
    String,
    'Missing Context Behavior',
    hint:
        'Reject | DefaultTenant | Anonymous — what happens when tenant '
        'context cannot be determined (reject = deny access; '
        'defaultTenant = use platform default)',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional tenant context policy notes',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27017 — cloud multi-tenancy isolation controls',
    'NIST SP 800-53 — control SC-2 separation of system functions',
  ],
  'Defines how the tenant context is established, validated, and propagated through authorization decisions.',
)
@SectionId('TECOPO')
@CodeSpecKind([CodeSpecPart.authorization])
class TenantContextPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Tenant Context Policy Details (text).
  @SerializationOrder(1)
  TextSection tenantContextPolicyDetails = TextSection();
}

/// Cross-Tenant Access Policy (form).
///
/// Defines whether and how cross-tenant access is permitted, what
/// authorization mechanisms govern it, resource sharing models, and
/// audit/review requirements. Aligns with OWASP: Preventing Cross-Tenant
/// Data Access and IDOR Prevention.
@Form([
  Field(
    'crossTenantAccessAllowed',
    bool,
    'Cross-Tenant Access Allowed',
    required: true,
    hint:
        'Yes | No — whether any form of cross-tenant access is permitted '
        'in the system',
  ),
  Field(
    'crossTenantAccessModel',
    String,
    'Cross-Tenant Access Model',
    hint:
        'GlobalAdmin | ServiceAccount | ExplicitGrant | Federation | '
        'None — model governing how cross-tenant access is structured',
  ),
  Field(
    'authorizationMechanism',
    String,
    'Authorization Mechanism',
    hint:
        'SuperAdminRole | ServiceAccountToken | ExplicitGrant | '
        'FederationAgreement — how cross-tenant operations are authorized '
        'when allowed',
  ),
  Field(
    'resourceSharingModel',
    String,
    'Resource Sharing Model',
    hint:
        'None | ReferenceOnly | Copy | SharedOwnership | Linked — how '
        'resources can be shared across tenant boundaries',
  ),
  Field(
    'idorPreventionStrategy',
    String,
    'IDOR Prevention Strategy',
    hint:
        'CompositeKeys | QueryFilter | RLS | ScopedTokens — strategy to '
        'prevent insecure direct object references across tenants',
  ),
  Field(
    'crossTenantAuditRequirement',
    String,
    'Cross-Tenant Audit Requirement',
    hint:
        'All | AdminOnly | None — level of audit logging required for '
        'cross-tenant operations',
  ),
  Field(
    'accessReviewFrequency',
    String,
    'Access Review Frequency',
    hint:
        'Monthly | Quarterly | SemiAnnual | Annual | OnChange — how '
        'often cross-tenant access grants are reviewed',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional cross-tenant access policy notes',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27017 — cloud multi-tenancy isolation controls',
    'NIST SP 800-53 — control AC-6 least privilege',
  ],
  'Defines whether and how access across tenant boundaries is permitted and governed.',
)
@SectionId('CTAP')
@CodeSpecKind([CodeSpecPart.authorization])
class CrossTenantAccessPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Cross-Tenant Access Policy Details (text).
  @SerializationOrder(1)
  TextSection crossTenantAccessPolicyDetails = TextSection();
}

/// A tenant customization entry (form).
///
/// Describes a specific area where tenants can customize their authorization
/// model — custom roles, permissions, policies, or workflows. Covers scoping,
/// inheritance from global defaults, and approval requirements.
@StandardReferences(
  [
    'ISO/IEC 27017 — cloud multi-tenancy isolation controls',
    'ISO/IEC 27001:2022 — control A.5.23 cloud service use',
  ],
  'Describes one area where a tenant can customize its authorization model beyond platform defaults.',
)
@SectionId('TNCS')
@CodeSpecKind([CodeSpecPart.authorization])
class TenantCustomizationEntry extends DocSpecsSection {
  @Form([
    Field(
      'customizationType',
      String,
      'Customization Type',
      required: true,
      hint:
          'Roles | Permissions | Policies | Workflows | All — area of '
          'authorization that can be customized per tenant',
    ),
    Field(
      'scopingMechanism',
      String,
      'Scoping Mechanism',
      hint:
          'TenantConfig | TenantOverride | TenantExtension | Inheritance '
          '— how tenant-specific customizations are applied',
    ),
    Field(
      'customRolesAllowed',
      bool,
      'Custom Roles Allowed',
      hint:
          'Yes | No — whether tenants can define their own custom roles '
          'beyond the platform-provided role set',
    ),
    Field(
      'customPermissionsAllowed',
      bool,
      'Custom Permissions Allowed',
      hint:
          'Yes | No — whether tenants can define custom fine-grained '
          'permissions beyond platform defaults',
    ),
    Field(
      'customPoliciesAllowed',
      bool,
      'Custom Policies Allowed',
      hint:
          'Yes | No — whether tenants can define custom authorization '
          'policies (e.g. IP restrictions, time-based access)',
    ),
    Field(
      'inheritFromGlobal',
      bool,
      'Inherit From Global',
      hint:
          'Yes | No — whether tenant customizations inherit from and '
          'extend global/platform defaults',
    ),
    Field(
      'customizationApproval',
      String,
      'Customization Approval',
      hint:
          'None | TenantAdmin | PlatformAdmin | Both — who must approve '
          'authorization customizations for a tenant',
    ),
    Field(
      'customizationAudit',
      bool,
      'Customization Audit',
      hint:
          'Yes | No — whether all customization changes are logged for '
          'audit and compliance purposes',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional tenant customization notes',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Tenant Onboarding Policy (form).
///
/// Defines how authorization resources are provisioned when a new tenant is
/// created and how they are cleaned up when a tenant is offboarded. Covers
/// initial role templates, admin provisioning, permission sets, data retention,
/// and offboarding approval workflows.
@Form([
  Field(
    'authorizationProvisioningModel',
    String,
    'Authorization Provisioning Model',
    required: true,
    hint:
        'Template | Clone | Custom | Minimal — how authorization '
        'resources (roles, permissions, policies) are provisioned for '
        'new tenants',
  ),
  Field(
    'defaultRoleTemplate',
    String,
    'Default Role Template',
    hint:
        'Name or ID of the role template used to bootstrap initial '
        'roles for a new tenant (e.g. StandardSaaS, Enterprise, '
        'Minimal)',
  ),
  Field(
    'adminRoleProvisioning',
    String,
    'Admin Role Provisioning',
    hint:
        'AutoCreate | ManualAssign | InviteBased — how the initial '
        'tenant administrator role is set up',
  ),
  Field(
    'initialPermissionSet',
    String,
    'Initial Permission Set',
    hint:
        'Full | Minimal | Custom — what permissions are granted to a '
        'new tenant upon creation',
  ),
  Field(
    'offboardingStrategy',
    String,
    'Offboarding Strategy',
    hint:
        'SoftDelete | HardDelete | Archive | Anonymize — how tenant '
        'authorization data is handled on offboarding',
  ),
  Field(
    'resourceCleanupOnOffboarding',
    String,
    'Resource Cleanup on Offboarding',
    hint:
        'Immediate | Deferred | Manual | PolicyBased — when '
        'authorization resources are cleaned up after tenant removal',
  ),
  Field(
    'dataRetentionDays',
    int,
    'Data Retention Days',
    hint:
        'Number of days tenant authorization data (roles, assignments, '
        'audit logs) is retained after offboarding (0 = immediate)',
  ),
  Field(
    'offboardingApproval',
    String,
    'Offboarding Approval',
    hint:
        'None | PlatformAdmin | ComplianceOfficer | Both — who must '
        'approve tenant offboarding and data deletion',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional tenant onboarding/offboarding notes',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.23 cloud service use',
    'ISO/IEC 27017 — cloud multi-tenancy isolation controls',
  ],
  'Defines how authorization resources are provisioned on tenant onboarding and cleaned up on offboarding.',
)
@SectionId('TEONPO')
@CodeSpecKind([CodeSpecPart.authorization])
class TenantOnboardingPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Tenant Onboarding Policy Details (text).
  @SerializationOrder(1)
  TextSection tenantOnboardingPolicyDetails = TextSection();
}

/// Tenant Boundary Enforcement Policy (form).
///
/// Defines how authorization boundaries between tenants are enforced at
/// runtime — covering enforcement layers, filtering strategies, escalation
/// prevention, shared service authorization, multi-tenant user support,
/// and authorization caching per tenant.
@Form([
  Field(
    'enforcementLayer',
    String,
    'Enforcement Layer',
    required: true,
    hint:
        'API | Service | Database | All — at which architectural layer '
        'tenant authorization boundaries are enforced',
  ),
  Field(
    'authorizationFilterStrategy',
    String,
    'Authorization Filter Strategy',
    hint:
        'QueryFilter | TokenScope | PolicyEngine | Middleware — how '
        'tenant boundaries are applied in authorization decisions',
  ),
  Field(
    'implicitTenantFilter',
    bool,
    'Implicit Tenant Filter',
    hint:
        'Yes | No — whether all authorization queries automatically '
        'include a tenant filter (defense-in-depth)',
  ),
  Field(
    'escalationPrevention',
    String,
    'Escalation Prevention',
    hint:
        'StrictScoping | RoleSeparation | TokenIsolation | All — how '
        'privilege escalation across tenant boundaries is prevented',
  ),
  Field(
    'sharedServiceAuthorization',
    String,
    'Shared Service Authorization',
    hint:
        'ServiceAccount | PlatformRole | TenantAgnostic | ScopedProxy '
        '— how shared platform services authorize operations that span '
        'or are independent of tenants',
  ),
  Field(
    'tenantSwitchingPolicy',
    String,
    'Tenant Switching Policy',
    hint:
        'ReAuthenticate | SessionSwitch | TokenExchange | NotAllowed — '
        'how users belonging to multiple tenants switch their active '
        'tenant context',
  ),
  Field(
    'multiTenantUserSupport',
    bool,
    'Multi-Tenant User Support',
    hint:
        'Yes | No — whether a single user identity can belong to and '
        'operate within multiple tenants',
  ),
  Field(
    'authorizationCaching',
    String,
    'Authorization Caching',
    hint:
        'None | PerTenant | SharedWithValidation | InvalidateOnSwitch '
        '— how authorization decisions are cached with respect to '
        'tenant context to prevent cross-tenant cache leakage',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional tenant boundary enforcement notes',
  ),
])
@StandardReferences(
  [
    'ISO/IEC 27017 — cloud multi-tenancy isolation controls',
    'NIST SP 800-53 — control SC-2 separation of system functions',
  ],
  'Defines how authorization boundaries between tenants are enforced at runtime across the architectural layers.',
)
@SectionId('TBEP')
@CodeSpecKind([CodeSpecPart.authorization])
class TenantBoundaryEnforcementPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Tenant Boundary Enforcement Details (text).
  @SerializationOrder(1)
  TextSection boundaryEnforcementDetails = TextSection();
}

/// An authorization group entry (form).
@StandardReferences([
  'NIST RBAC INCITS 359-2012 — role and group membership assignment',
  'ISO/IEC 27001:2022 — control A.5.15 access control',
], 'Defines an authorization group that bundles roles for assignment to users.')
@SectionId('AZGR')
@CodeSpecKind([CodeSpecPart.authorization])
class AuthorizationGroupEntry extends DocSpecsSection {
  @Form([
    Field(
      'groupName',
      String,
      'Group Name',
      hint: 'Unique name of the authorization group (e.g. Finance Managers)',
      required: true,
    ),
    Field(
      'description',
      String,
      'Short description',
      hint: 'Purpose of the group and the access it confers',
    ),
    Field(
      'membershipCriteria',
      String,
      'Membership Criteria',
      hint:
          'Rule or attribute condition determining who belongs to this group '
          '(e.g. department = Finance)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× RoleReference.
  @StandardReferences([
    'NIST RBAC INCITS 359-2012 — roles assigned to groups',
  ], 'The catalog of roles contained within this authorization group.')
  @SectionId('ROLREF-CONT-LST')
  @SectionIdPattern('ROLREF-CONT-xxx')
  @ContentHelp('Add one entry per contained role.')
  @SerializationOrder(1)
  List<RoleReferenceEntry> containedRoles = [];
}

/// A role reference entry (form).
@StandardReferences([
  'NIST RBAC INCITS 359-2012 — role identification',
], 'References a single authorization role by name from a group or assignment.')
@SectionId('ROLREF')
@CodeSpecKind([CodeSpecPart.authorization])
class RoleReferenceEntry extends DocSpecsSection {
  @Form([
    Field(
      'roleName',
      String,
      'Role Name',
      hint: 'Name of an existing authorization role being referenced',
      required: true,
      refersTo: ['AZRO.roleName'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// An authorization role entry (form).
///
/// Defines a single authorization role with its category, scope, permission
/// assignments, activation rules, provisioning, and review requirements.
/// Aligns with NIST RBAC model (core + hierarchical + constrained).
@StandardReferences(
  [
    'NIST RBAC INCITS 359-2012 — core, hierarchical, and constrained RBAC',
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ],
  'Defines a single authorization role with its category, scope, permissions, and lifecycle controls.',
)
@SectionId('AZRO')
@CodeSpecKind([CodeSpecPart.authorization])
class AuthorizationRoleEntry extends DocSpecsSection {
  @Form([
    Field(
      'roleName',
      String,
      'Role Name',
      hint: 'Unique name of the authorization role (e.g. FinanceApprover)',
      required: true,
    ),
    Field(
      'description',
      String,
      'Short description',
      hint: 'Purpose of the role and the access it grants',
    ),
    Field(
      'roleCategory',
      String,
      'Role Category',
      hint:
          'Business | Technical | Administrative | System | Compliance | '
          'Custom — classification of the role by function',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Scope and inheritance metadata.
  @SectionId('ARES')
  @StandardReferences([
    'NIST RBAC INCITS 359-2012 — hierarchical RBAC and role inheritance',
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ], 'Scope and inheritance metadata for an authorization role.')
  @Form([
    Field(
      'roleScope',
      String,
      'Role Scope',
      hint:
          'Global | Tenant | Department | Project | Team | Custom — '
          'organizational scope where this role is applicable',
    ),
    Field(
      'inheritsFrom',
      String,
      'Inherits From',
      hint:
          'Parent role name or "none" for top-level roles; child roles '
          'inherit all permissions of the parent',
    ),
    Field(
      'permissionSet',
      String,
      'Permission Set',
      hint:
          'Comma-separated permission keys summarizing the role\'s access '
          '(e.g. user.manage, config.read, audit.read)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? structure;

  /// Risk and activation controls.
  @SectionId('AREG')
  @StandardReferences([
    'NIST SP 800-53 — control AC-6 least privilege',
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ], 'Risk and activation controls governing an authorization role.')
  @Form([
    Field(
      'riskLevel',
      String,
      'Risk Level',
      hint:
          'Critical | High | Medium | Low — privilege risk classification '
          'for access review prioritization',
    ),
    Field(
      'maxHolders',
      int,
      'Maximum Holders',
      hint:
          'Maximum number of users who can hold this role concurrently; '
          '0 = unlimited',
    ),
    Field(
      'activationType',
      String,
      'Activation Type',
      hint:
          'AlwaysActive | OnDemand | TimeLimited | Scheduled — whether the '
          'role is permanently active or requires activation',
    ),
    Field(
      'activationDuration',
      String,
      'Activation Duration',
      hint:
          'Maximum duration for on-demand or time-limited activation '
          '(e.g. 8h, 24h, 7d)',
    ),
    Field(
      'approvalRequired',
      bool,
      'Approval Required',
      hint: 'Yes | No — whether role assignment requires explicit approval',
    ),
    Field(
      'approver',
      String,
      'Approver',
      hint:
          'Role or person responsible for approving role assignments '
          '(e.g. Line Manager, Security Officer, System Owner)',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? governance;

  /// Provisioning and review settings.
  @SectionId('AREL')
  @StandardReferences([
    'ISO/IEC 27001:2022 — control A.5.18 access rights provisioning and review',
    'NIST SP 800-53 — control AC-2 account management',
  ], 'Provisioning and review settings for an authorization role.')
  @Form([
    Field(
      'provisioningMethod',
      String,
      'Provisioning Method',
      hint:
          'Manual | Automatic | ApprovalBased | SelfService | RuleBased — '
          'how the role is assigned to users',
    ),
    Field(
      'reviewFrequency',
      String,
      'Review Frequency',
      hint:
          'Monthly | Quarterly | SemiAnnual | Annual | OnChange | Never — '
          'how often role assignments are reviewed for appropriateness',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? lifecycle;

  /// Data access and role status flags.
  @SectionId('AUROENST')
  @StandardReferences(
    [
      'NIST RBAC INCITS 359-2012 — role-based access control',
      'ISO/IEC 27001:2022 — control A.5.15 access control',
    ],
    'Captures the data access scope and status flags of an authorization role.',
  )
  @Form([
    Field(
      'dataAccessScope',
      String,
      'Data Access Scope',
      hint:
          'AllData | TenantData | DepartmentData | TeamData | OwnData | '
          'None — breadth of data accessible through this role',
    ),
    Field(
      'isDefault',
      bool,
      'Default Role',
      hint: 'Yes | No — automatically assigned to new users upon creation',
    ),
    Field(
      'isSystem',
      bool,
      'System Role',
      hint:
          'Yes | No — system-defined role that cannot be modified or '
          'deleted by administrators',
    ),
    Field('notes', String, 'Notes', hint: 'Additional role definition notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? status;

  /// Contains 0+× ResponsibilityReference.
  @StandardReferences([
    'NIST RBAC INCITS 359-2012 — roles map to organizational responsibilities',
  ], 'The catalog of business responsibilities this role fulfils.')
  @SectionId('RSPREF-RESP-LST')
  @SectionIdPattern('RSPREF-RESP-xxx')
  @ContentHelp('Add one entry per responsibility reference.')
  @SerializationOrder(5)
  List<ResponsibilityReferenceEntry> responsibilities = [];

  /// Contains 0+× EntitlementReference.
  @StandardReferences([
    'NIST RBAC INCITS 359-2012 — permissions granted through roles',
  ], 'The catalog of entitlements granted by this role.')
  @SectionId('ENREFE-ENTI-LST')
  @SectionIdPattern('ENREFE-ENTI-xxx')
  @ContentHelp('Add one entry per entitlement reference.')
  @SerializationOrder(6)
  List<EntitlementReferenceEntry> entitlementReferences = [];

  /// Contains 0+× RolePermission.
  @StandardReferences([
    'NIST RBAC INCITS 359-2012 — permission-to-role assignment',
  ], 'The catalog of permissions assigned directly to this role.')
  @SectionId('ROLPERM-DIRE-LST')
  @SectionIdPattern('ROLPERM-DIRE-xxx')
  @ContentHelp('Add one entry per direct permission.')
  @SerializationOrder(7)
  List<RolePermissionEntry> directPermissions = [];

  /// Contains 0+× RoleDataScope.
  @StandardReferences([
    'NIST SP 800-162 — attribute-based access control constraints',
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
  ], 'The catalog of data scopes that constrain this role access.')
  @SectionId('ROLDSCP-DATA-LST')
  @SectionIdPattern('ROLDSCP-DATA-xxx')
  @ContentHelp('Add one entry per data scope.')
  @SerializationOrder(8)
  List<RoleDataScopeEntry> dataScopes = [];

  /// Contains 0+× RoleExclusion.
  @StandardReferences([
    'NIST RBAC INCITS 359-2012 — static and dynamic separation of duty',
    'NIST SP 800-53 — control AC-5 separation of duties',
  ], 'The catalog of roles that cannot be held together with this role.')
  @SectionId('ROLEXC-MUTU-LST')
  @SectionIdPattern('ROLEXC-MUTU-xxx')
  @ContentHelp('Add one entry per mutually exclusive role.')
  @SerializationOrder(9)
  List<RoleExclusionEntry> mutualExclusions = [];

  /// Contains 0+× RoleHolder.
  @StandardReferences([
    'NIST RBAC INCITS 359-2012 — user-to-role assignment',
  ], 'The catalog of user types that typically hold this role.')
  @SectionId('ROLHLD-TYPI-LST')
  @SectionIdPattern('ROLHLD-TYPI-xxx')
  @ContentHelp('Add one entry per typical role holder.')
  @SerializationOrder(10)
  List<RoleHolderEntry> typicalHolders = [];
}

/// A responsibility reference entry (form).
@StandardReferences([
  'NIST RBAC INCITS 359-2012 — role-based access control',
  'ISO/IEC 27001:2022 — control A.5.15 access control',
], 'References a responsibility associated with a role.')
@SectionId('RSPREF')
@CodeSpecKind([CodeSpecPart.authorization])
class ResponsibilityReferenceEntry extends DocSpecsSection {
  @Form([
    Field(
      'responsibility',
      String,
      'Responsibility',
      required: true,
      hint: 'Name of the responsibility.',
    ),
    Field(
      'description',
      String,
      'Short description',
      hint: 'Brief description.',
    ),
    Field(
      'scope',
      String,
      'Scope',
      hint:
          'Specific area or context where this responsibility applies '
          '(e.g. user management, data quality, incident response)',
    ),
    Field(
      'criticalityLevel',
      String,
      'Criticality Level',
      hint:
          'Critical | High | Medium | Low — importance of this '
          'responsibility for business operations',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// An entitlement reference entry (form).
@StandardReferences([
  'NIST RBAC INCITS 359-2012 — role-based access control',
  'ISO/IEC 27001:2022 — control A.5.15 access control',
], 'References an entitlement granted to a role.')
@SectionId('ENREFE')
@CodeSpecKind([CodeSpecPart.authorization])
class EntitlementReferenceEntry extends DocSpecsSection {
  @Form([
    Field(
      'entitlementName',
      String,
      'Entitlement Name',
      required: true,
      hint: 'Name of the entitlement.',
      refersTo: ['ENT.entitlementName'],
    ),
    Field(
      'grantType',
      String,
      'Grant Type',
      hint:
          'Full | ReadOnly | Conditional | TimeLimited — type of access '
          'granted through this entitlement',
    ),
    Field(
      'conditions',
      String,
      'Conditions',
      hint:
          'Conditions under which this entitlement is active '
          '(e.g. during business hours, from internal network)',
    ),
    Field(
      'scope',
      String,
      'Scope',
      hint:
          'Specific scope within the entitlement (e.g. own-department, '
          'all-tenants, specific-project)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A direct permission entry for a role (form).
///
/// Captures direct permission assignments that complement or override
/// entitlement-based access — useful when fine-grained per-role permissions
/// are needed beyond what entitlements provide.
@StandardReferences([
  'NIST RBAC INCITS 359-2012 — role-based access control',
  'ISO/IEC 27001:2022 — control A.5.15 access control',
], 'Defines a permission assigned directly to a role.')
@SectionId('ROLPERM')
@CodeSpecKind([CodeSpecPart.authorization])
class RolePermissionEntry extends DocSpecsSection {
  @Form([
    Field(
      'permissionKey',
      String,
      'Permission Key',
      required: true,
      hint:
          'Dot-notation permission identifier '
          '(e.g. user.create, config.manage, report.export)',
    ),
    Field(
      'accessType',
      String,
      'Access Type',
      hint:
          'Read | Write | Execute | Delete | Manage | All — type of access '
          'this permission grants',
    ),
    Field(
      'resourceScope',
      String,
      'Resource Scope',
      hint:
          'Specific resource or resource pattern this permission applies to '
          '(e.g. /api/users/*, tenant.settings, report.*)',
    ),
    Field(
      'conditions',
      String,
      'Conditions',
      hint:
          'Runtime conditions for this permission (e.g. business-hours-only, '
          'requires-mfa, from-internal-network)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A data scope entry for a role (form).
///
/// Specifies what data categories the role can access and at what level —
/// supports horizontal access control and data-level security.
@StandardReferences([
  'NIST RBAC INCITS 359-2012 — role-based access control',
  'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
], 'Specifies which data categories a role may access and at what level.')
@SectionId('ROLDSCP')
@CodeSpecKind([CodeSpecPart.authorization])
class RoleDataScopeEntry extends DocSpecsSection {
  @Form([
    Field(
      'dataCategory',
      String,
      'Data Category',
      required: true,
      hint:
          'Business data category (e.g. CustomerRecords, FinancialData, '
          'HRData, AuditLogs, SystemConfiguration)',
    ),
    Field(
      'accessLevel',
      String,
      'Access Level',
      hint:
          'Full | Filtered | Aggregated | Masked | ReadOnly | None — '
          'level of access to this data category',
    ),
    Field(
      'filterCriteria',
      String,
      'Filter Criteria',
      hint:
          'How data is filtered for this role (e.g. own-department, '
          'own-records, assigned-projects, tenant-boundary)',
    ),
    Field(
      'maskingRules',
      String,
      'Masking Rules',
      hint:
          'Fields masked or redacted for this role (e.g. SSN-last4, '
          'email-domain-only, salary-hidden)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A role exclusion entry (form).
@StandardReferences(
  [
    'NIST SP 800-53 — control AC-5 separation of duties',
    'NIST RBAC INCITS 359-2012 — role-based access control',
  ],
  'Declares a role that must not be held together with this one to enforce separation of duties.',
)
@SectionId('ROLEXC')
@CodeSpecKind([CodeSpecPart.authorization])
class RoleExclusionEntry extends DocSpecsSection {
  @Form([
    Field(
      'excludedRole',
      String,
      'Excluded Role',
      required: true,
      hint: 'Role that must not be held together with this one.',
    ),
    Field(
      'reason',
      String,
      'Reason',
      hint: 'Business reason for the mutual exclusion (separation of duties)',
    ),
    Field(
      'exclusionType',
      String,
      'Exclusion Type',
      hint:
          'Static | Dynamic — static = enforced at assignment time, '
          'dynamic = enforced at activation/runtime',
    ),
    Field(
      'severity',
      String,
      'Severity',
      hint:
          'Hard | Soft — hard = system-enforced block, '
          'soft = warning with override option',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A role holder entry (form).
@StandardReferences([
  'NIST RBAC INCITS 359-2012 — role-based access control',
  'ISO/IEC 27001:2022 — control A.5.15 access control',
], 'Describes the population of users expected to hold a role.')
@SectionId('ROLHLD')
@CodeSpecKind([CodeSpecPart.authorization])
class RoleHolderEntry extends DocSpecsSection {
  @Form([
    Field(
      'holderDescription',
      String,
      'Holder Description',
      required: true,
      hint: 'Description of the role holder.',
    ),
    Field(
      'department',
      String,
      'Department',
      hint: 'Department of the role holder.',
    ),
    Field(
      'organizationalUnit',
      String,
      'Organizational Unit',
      hint: 'Specific organizational unit or team',
    ),
    Field(
      'estimatedCount',
      int,
      'Estimated Count',
      hint: 'Approximate number of users expected to hold this role',
    ),
    Field(
      'assignmentBasis',
      String,
      'Assignment Basis',
      hint:
          'JobFunction | ProjectMembership | DepartmentMembership | '
          'ManualAssignment — reason for role assignment',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// An entitlement entry (form).
@StandardReferences([
  'NIST RBAC INCITS 359-2012 — role-based access control',
  'ISO/IEC 27001:2022 — control A.5.15 access control',
], 'Defines an entitlement that grants a bundle of access rights.')
@SectionId('ENT')
@CodeSpecKind([CodeSpecPart.authorization])
class EntitlementEntry extends DocSpecsSection {
  @Form([
    Field(
      'entitlementName',
      String,
      'Entitlement Name',
      required: true,
      hint: 'Name of the entitlement.',
    ),
    Field(
      'description',
      String,
      'Short description',
      hint: 'Brief description.',
    ),
    Field('accessType', String, 'Access Type', hint: 'Type of access granted.'),
    Field(
      'conditions',
      String,
      'Conditions',
      hint: 'Conditions under which the entitlement applies.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× ResourceKeyReference.
  @StandardReferences([
    'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
    'NIST RBAC INCITS 359-2012 — role-based access control',
  ], 'The catalog of resource key references for this entitlement.')
  @SectionId('RESKREF-RESO-LST')
  @SectionIdPattern('RESKREF-RESO-xxx')
  @ContentHelp('Add one entry per resource reference.')
  @SerializationOrder(1)
  List<ResourceKeyReferenceEntry> resourceKeyReferences = [];
}

/// A resource key reference entry (form).
@StandardReferences([
  'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
  'NIST RBAC INCITS 359-2012 — role-based access control',
], 'References a protected resource by its unique resource key.')
@SectionId('RESKREF')
@CodeSpecKind([CodeSpecPart.authorization])
class ResourceKeyReferenceEntry extends DocSpecsSection {
  @Form([
    Field(
      'resourceKey',
      String,
      'Resource Key',
      required: true,
      hint: 'Unique key of the referenced resource.',
      refersTo: ['RESKEY.resourceKey'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A resource key entry (form).
@StandardReferences([
  'ISO/IEC 27001:2022 — control A.8.3 information access restriction',
  'NIST RBAC INCITS 359-2012 — role-based access control',
], 'Defines a protected resource identified by a unique resource key.')
@SectionId('RESKEY')
@CodeSpecKind([CodeSpecPart.authorization])
class ResourceKeyEntry extends DocSpecsSection {
  @Form([
    Field(
      'resourceKey',
      String,
      'Resource Key',
      required: true,
      hint: 'Unique key of the resource.',
    ),
    Field(
      'resourceType',
      String,
      'Resource Type',
      hint: 'Type of the resource.',
    ),
    Field(
      'description',
      String,
      'Short description',
      hint: 'Brief description.',
    ),
    Field(
      'protectionLevel',
      String,
      'Protection Level',
      hint: 'Protection level required for the resource.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 9.5. Sensitive Data Encryption.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.8.24 use of cryptography',
    'GDPR — Article 32 security of processing',
  ],
  'This section defines encryption requirements for sensitive data both at rest and in transit, together with the cryptographic key management that underpins them.',
)
@SectionId('SEDAEN')
@DetailedIn(D08SecurityAccessSpecification)
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class SensitiveDataEncryption extends DocSpecsSection {
  @ContentHelp('''
Define encryption requirements for sensitive data both at rest and in transit.
Encryption is a critical defense-in-depth layer that protects data even when
other controls fail.

**Data classification:**
- Identify sensitive data categories (PII, PHI, financial, credentials)
- Map each category to encryption requirements
- Document regulatory drivers (GDPR, HIPAA, PCI DSS)

**Encryption scope:**
- **At Rest**: Stored data in databases, filesystems, backups
- **In Transit**: Data moving over networks (internal and external)
- **In Use**: Data in memory (future consideration for confidential computing)

**Key management:**
- Cryptographic key lifecycle (generation, storage, rotation, destruction)
- Key hierarchy (master keys, data encryption keys)
- Separation of duties (key custodians vs. data operators)

**Algorithm selection:**
- Use approved algorithms (AES-256-GCM, ChaCha20-Poly1305)
- Avoid deprecated algorithms (DES, 3DES, RC4, MD5, SHA-1)
- Plan for post-quantum cryptography migration

**Compliance alignment:**
- PCI DSS: encrypt cardholder data at rest and in transit
- HIPAA: protect PHI with appropriate safeguards
- GDPR: implement appropriate technical measures

**Reference:**
- OWASP Cryptographic Storage Cheat Sheet
- NIST SP 800-175B: Cryptographic Standards and Guidelines
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.5.1. Encryption At Rest.
  @SerializationOrder(1)
  EncryptionAtRest encryptionAtRest = EncryptionAtRest();

  /// 9.5.2. Encryption In Transit.
  @SerializationOrder(2)
  EncryptionInTransit encryptionInTransit = EncryptionInTransit();

  /// 9.5.3. Key Management.
  @SerializationOrder(3)
  KeyManagement keyManagement = KeyManagement();
}

// ---------------------------------------------------------------------------
// 9.5.1. Encryption At Rest
// ---------------------------------------------------------------------------

/// 9.5.1. Encryption At Rest.
///
/// Defines encryption requirements for stored data: algorithms, key lengths,
/// encryption layers (application, database, filesystem, hardware), field-level
/// and full-disk encryption, encrypted data categories, backup encryption,
/// and compliance requirements. Aligns with OWASP Cryptographic Storage
/// Cheat Sheet and NIST SP 800-111 (Storage Encryption).
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-28 protection of information at rest',
    'ISO/IEC 27001:2022 — control A.8.24 use of cryptography',
  ],
  'This section defines encryption requirements for stored data, covering algorithms, key lengths, encryption layers, field-level and full-disk encryption, encrypted data categories, and backup encryption.',
)
@SectionId('ENATRE')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class EncryptionAtRest extends DocSpecsSection {
  @ContentHelp('''
Define how stored data is encrypted to protect against unauthorized access,
data breaches, and physical media theft.

**Encryption layers:**
1. **Full-disk encryption (FDE)**: Protects against physical theft
2. **Database encryption (TDE)**: Transparent database-level encryption
3. **Application encryption**: Field-level encryption for sensitive data
4. **Hardware encryption**: HSM-backed encryption for highest assurance

**Algorithm requirements:**
- Symmetric: AES-256-GCM or AES-256-CBC with HMAC
- Key derivation: PBKDF2, scrypt, or Argon2 for password-derived keys
- Random IVs/nonces for each encryption operation

**Data categories to encrypt:**
- Credentials and secrets (highest priority)
- PII: names, addresses, identifiers
- Financial data: payment card numbers, bank details
- Health data: PHI under HIPAA
- Business confidential: trade secrets, contracts

**Backup encryption:**
- All backups encrypted with separate key set
- Offline key escrow for disaster recovery
- Test restoration of encrypted backups regularly

**Compliance notes:**
- PCI DSS 3.4: render PAN unreadable anywhere it is stored
- HIPAA: encryption is addressable safeguard for PHI
- GDPR: encryption as appropriate technical measure

**Reference:**
- OWASP Cryptographic Storage Cheat Sheet
- NIST SP 800-111: Guide to Storage Encryption
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Encryption At Rest Policy.
  @SerializationOrder(1)
  EncryptionAtRestPolicy encryptionPolicy = EncryptionAtRestPolicy();

  /// Contains 0+× EncryptedDataCategory.
  @StandardReferences(
    ['NIST SP 800-53 — control SC-28 protection of information at rest'],
    'The catalog of encrypted data categories, each mapping a data classification to its encryption requirements.',
  )
  @SectionId('ENDACA-ENCR-LST')
  @SectionIdPattern('ENDACA-ENCR-xxx')
  @ContentHelp('Add one entry per encrypted data category.')
  @SerializationOrder(2)
  List<EncryptedDataCategoryEntry> encryptedDataCategories = [];

  /// Database Encryption Policy.
  @SerializationOrder(3)
  DatabaseEncryptionPolicy databaseEncryption = DatabaseEncryptionPolicy();

  /// File and Storage Encryption Policy.
  @SerializationOrder(4)
  FileStorageEncryptionPolicy fileStorageEncryption =
      FileStorageEncryptionPolicy();

  /// Backup Encryption Policy.
  @SerializationOrder(5)
  BackupEncryptionPolicy backupEncryption = BackupEncryptionPolicy();

  /// Encryption At Rest Notes (text).
  @SerializationOrder(6)
  TextSection encryptionAtRestNotes = TextSection();
}

/// Encryption At Rest Policy (form).
///
/// Global settings governing how data at rest is encrypted: default algorithm,
/// key size, cipher mode, encryption layer strategy, field-level vs full-disk
/// encryption, and compliance framework alignment.
@Form([
  Field(
    'defaultAlgorithm',
    String,
    'Default Algorithm',
    required: true,
    hint:
        'AES-256 | AES-128 | ChaCha20 | 3DES | Other — symmetric '
        'encryption algorithm used as the default for data at rest '
        '(AES-256 recommended per OWASP/NIST)',
  ),
  Field(
    'defaultKeyLength',
    int,
    'Default Key Length (bits)',
    required: true,
    hint:
        '128 | 192 | 256 — minimum key length in bits for symmetric '
        'encryption (256-bit recommended for sensitive data)',
  ),
  Field(
    'cipherMode',
    String,
    'Cipher Mode',
    hint:
        'GCM | CCM | CTR | CBC | XTS — block cipher mode of operation '
        '(GCM or CCM recommended for authenticated encryption; '
        'XTS for full-disk encryption)',
  ),
  Field(
    'encryptionLayer',
    String,
    'Encryption Layer',
    hint:
        'Application | Database | Filesystem | Hardware | Multiple — '
        'at which architectural layer encryption is primarily applied '
        '(multiple = defense-in-depth across layers)',
  ),
  Field(
    'fieldLevelEncryption',
    bool,
    'Field-Level Encryption',
    hint:
        'Yes | No — whether individual sensitive fields (e.g. SSN, '
        'credit card) are encrypted at the application level beyond '
        'database/disk encryption',
  ),
  Field(
    'transparentDataEncryption',
    bool,
    'Transparent Data Encryption',
    hint:
        'Yes | No — whether TDE (Transparent Data Encryption) is used '
        'at the database engine level (e.g. SQL Server TDE, Oracle TDE, '
        'PostgreSQL pgcrypto)',
  ),
  Field(
    'fullDiskEncryption',
    bool,
    'Full-Disk Encryption',
    hint:
        'Yes | No — whether full-disk or volume-level encryption is '
        'required (e.g. LUKS, BitLocker, AWS EBS encryption)',
  ),
  Field(
    'minimizeSensitiveStorage',
    bool,
    'Minimize Sensitive Storage',
    hint:
        'Yes | No — whether the system actively minimizes storage of '
        'sensitive data (e.g. tokenization, truncation, avoiding '
        'unnecessary PII retention)',
  ),
  Field(
    'complianceFramework',
    String,
    'Compliance Framework',
    hint:
        'FIPS-140-2 | PCI-DSS | HIPAA | GDPR | SOC2 | None — '
        'regulatory or compliance framework dictating encryption '
        'requirements',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional encryption at rest policy notes',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-28 protection of information at rest',
    'ISO/IEC 27001:2022 — control A.8.24 use of cryptography',
  ],
  'This section defines global settings governing how data at rest is encrypted, covering the default algorithm, key size, cipher mode, encryption layer strategy, and compliance framework alignment.',
)
@SectionId('EARP')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class EncryptionAtRestPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Encryption At Rest Policy Details (text).
  @SerializationOrder(1)
  TextSection encryptionAtRestPolicyDetails = TextSection();
}

/// An encrypted data category entry (form).
///
/// Defines a specific category of data that requires encryption at rest,
/// including the data classification, encryption approach, algorithm override,
/// and data minimization strategy. Allows specifying different encryption
/// levels for different data sensitivity tiers.
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-28 protection of information at rest',
    'GDPR — Article 32 security of processing',
  ],
  'This section defines a specific category of data requiring encryption at rest, including its classification, encryption approach, algorithm override, and data minimization strategy.',
)
@SectionId('ENDACA')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class EncryptedDataCategoryEntry extends DocSpecsSection {
  @Form([
    Field(
      'categoryName',
      String,
      'Category Name',
      required: true,
      hint:
          'Name of the data category requiring encryption '
          '(e.g. PersonalData, FinancialRecords, HealthRecords, '
          'Credentials, APIKeys)',
    ),
    Field(
      'dataClassification',
      String,
      'Data Classification',
      required: true,
      hint:
          'Public | Internal | Confidential | Restricted | Secret — '
          'sensitivity classification of the data category',
    ),
    Field(
      'encryptionApproach',
      String,
      'Encryption Approach',
      hint:
          'FieldLevel | ColumnLevel | TableLevel | DatabaseLevel | '
          'FileLevel | VolumeLevel — at what granularity this data '
          'category is encrypted',
    ),
    Field(
      'algorithmOverride',
      String,
      'Algorithm Override',
      hint:
          'Algorithm and key length if different from the default '
          'policy (e.g. AES-256-GCM, ChaCha20-Poly1305); blank = '
          'use default',
    ),
    Field(
      'encryptedFields',
      String,
      'Encrypted Fields',
      hint:
          'Comma-separated list of specific fields or columns encrypted '
          'for this category (e.g. ssn, creditCardNumber, bankAccount, '
          'dateOfBirth)',
    ),
    Field(
      'tokenizationUsed',
      bool,
      'Tokenization Used',
      hint:
          'Yes | No — whether tokenization is used instead of or in '
          'addition to encryption for this data category',
    ),
    Field(
      'dataRetentionDays',
      int,
      'Data Retention (Days)',
      hint:
          'Maximum retention period for this encrypted data category '
          'in days; 0 = indefinite',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional notes for this encrypted data category',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Database Encryption Policy (form).
///
/// Defines how database-level encryption is implemented: TDE configuration,
/// column-level encryption, index handling for encrypted columns, search
/// strategy for encrypted data, and database engine-specific settings.
@Form([
  Field(
    'databaseEncryptionMethod',
    String,
    'Database Encryption Method',
    required: true,
    hint:
        'TDE | ColumnLevel | CellLevel | ApplicationLayer | None — '
        'method of encrypting data within the database',
  ),
  Field(
    'encryptedColumnStrategy',
    String,
    'Encrypted Column Strategy',
    hint:
        'Deterministic | Randomized | Homomorphic | Envelope — how '
        'individual columns are encrypted (deterministic allows '
        'equality search; randomized provides stronger security)',
  ),
  Field(
    'indexOnEncryptedColumns',
    bool,
    'Index on Encrypted Columns',
    hint:
        'Yes | No — whether indexes are maintained on encrypted '
        'columns (requires deterministic encryption or specialized '
        'schemes)',
  ),
  Field(
    'searchOnEncryptedData',
    String,
    'Search on Encrypted Data',
    hint:
        'None | DeterministicMatch | BlindIndex | Searchable '
        'Encryption | DecryptThenSearch — strategy for querying '
        'encrypted data without full decryption',
  ),
  Field(
    'connectionEncryption',
    bool,
    'Connection Encryption',
    hint:
        'Yes | No — whether database connections use TLS/SSL for '
        'data in transit to/from the database',
  ),
  Field(
    'databaseEngine',
    String,
    'Database Engine',
    hint:
        'PostgreSQL | MySQL | SQLServer | Oracle | MongoDB | Other — '
        'target database engine (encryption capabilities vary by '
        'engine)',
  ),
  Field('notes', String, 'Notes', hint: 'Additional database encryption notes'),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-28 protection of information at rest',
    'ISO/IEC 27001:2022 — control A.8.24 use of cryptography',
  ],
  'This section defines how database-level encryption is implemented, covering TDE configuration, column-level encryption, index handling for encrypted columns, and search strategy.',
)
@SectionId('DAENPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class DatabaseEncryptionPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Database Encryption Details (text).
  @SerializationOrder(1)
  TextSection databaseEncryptionDetails = TextSection();
}

/// File and Storage Encryption Policy (form).
///
/// Defines how files, blobs, and other non-database storage are encrypted:
/// file-level vs volume-level encryption, cloud storage encryption, signed
/// URL handling, and local device encryption requirements.
@Form([
  Field(
    'fileEncryptionMethod',
    String,
    'File Encryption Method',
    required: true,
    hint:
        'FileLevel | VolumeLevel | ObjectLevel | ClientSide | '
        'ServerSide | None — how files and blobs are encrypted at rest',
  ),
  Field(
    'cloudStorageEncryption',
    String,
    'Cloud Storage Encryption',
    hint:
        'SSE-S3 | SSE-KMS | SSE-C | AzureSSE | GCS-CMEK | None — '
        'cloud provider server-side encryption method if applicable',
  ),
  Field(
    'clientSideEncryption',
    bool,
    'Client-Side Encryption',
    hint:
        'Yes | No — whether files are encrypted before upload '
        '(client-side encryption for defense-in-depth)',
  ),
  Field(
    'encryptedFileFormats',
    String,
    'Encrypted File Formats',
    hint:
        'Comma-separated list of file types that must be encrypted '
        '(e.g. PDF, XLSX, CSV, backup dumps, log archives)',
  ),
  Field(
    'localDeviceEncryption',
    bool,
    'Local Device Encryption',
    hint:
        'Yes | No — whether local device storage (mobile, desktop) '
        'must be encrypted for cached or offline data',
  ),
  Field(
    'temporaryFileEncryption',
    bool,
    'Temporary File Encryption',
    hint:
        'Yes | No — whether temporary files and caches must be '
        'encrypted (prevents data leakage through temp files)',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional file and storage encryption notes',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-28 protection of information at rest',
    'ISO/IEC 27001:2022 — control A.8.24 use of cryptography',
  ],
  'This section defines how files, blobs, and non-database storage are encrypted at rest, covering file-level versus volume-level encryption, cloud storage encryption, and local device encryption.',
)
@SectionId('FSEP')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class FileStorageEncryptionPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// File Storage Encryption Details (text).
  @SerializationOrder(1)
  TextSection fileStorageEncryptionDetails = TextSection();
}

/// Backup Encryption Policy (form).
///
/// Defines encryption requirements for backup data: backup encryption method,
/// separate key management for backups, retention of encrypted backups,
/// and verification of backup encryption integrity.
@Form([
  Field(
    'backupEncryptionRequired',
    bool,
    'Backup Encryption Required',
    required: true,
    hint:
        'Yes | No — whether all backups (database, file, system) '
        'must be encrypted',
  ),
  Field(
    'backupEncryptionMethod',
    String,
    'Backup Encryption Method',
    hint:
        'SameAsSource | SeparateKey | EnvelopeEncryption | '
        'CloudProviderManaged — how backup data is encrypted '
        '(SameAsSource = same keys as live data)',
  ),
  Field(
    'separateBackupKeys',
    bool,
    'Separate Backup Keys',
    hint:
        'Yes | No — whether backups use separate encryption keys '
        'from production data (recommended for key rotation '
        'independence)',
  ),
  Field(
    'backupKeyRotation',
    String,
    'Backup Key Rotation',
    hint:
        'OnEveryBackup | Monthly | Quarterly | Annual | OnKeyChange — '
        'how often backup encryption keys are rotated',
  ),
  Field(
    'encryptedBackupVerification',
    bool,
    'Encrypted Backup Verification',
    hint:
        'Yes | No — whether backup integrity and encryption are '
        'periodically verified through test restores',
  ),
  Field(
    'offSiteBackupEncryption',
    bool,
    'Off-Site Backup Encryption',
    hint:
        'Yes | No — whether off-site or disaster recovery backups '
        'have additional encryption requirements',
  ),
  Field('notes', String, 'Notes', hint: 'Additional backup encryption notes'),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-28 protection of information at rest',
    'ISO/IEC 27001:2022 — control A.8.13 information backup',
  ],
  'This section defines encryption requirements for backup data, covering the backup encryption method, separate key management, retention of encrypted backups, and verification of encryption integrity.',
)
@SectionId('BAENPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class BackupEncryptionPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Backup Encryption Details (text).
  @SerializationOrder(1)
  TextSection backupEncryptionDetails = TextSection();
}

// ---------------------------------------------------------------------------
// 9.5.2. Encryption In Transit
// ---------------------------------------------------------------------------

/// 9.5.2. Encryption In Transit.
///
/// Defines encryption requirements for data in transit: TLS protocol versions,
/// cipher suites, certificate management, HSTS policy, mutual TLS, certificate
/// pinning, and internal/service-to-service communication encryption. Aligns
/// with OWASP Transport Layer Security Cheat Sheet and NIST SP 800-52.
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-8 transmission confidentiality and integrity',
    'NIST SP 800-52 Rev. 2 — TLS implementation guidelines',
  ],
  'This section defines encryption requirements for data in transit, covering TLS protocol versions, cipher suites, certificate management, HSTS, mutual TLS, and service-to-service communication.',
)
@SectionId('ENINTR')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class EncryptionInTransit extends DocSpecsSection {
  @ContentHelp('''
Define how data is protected while moving over networks, both externally
(internet) and internally (service-to-service).

**TLS configuration:**
- Minimum version: TLS 1.2 (TLS 1.3 preferred)
- Disable: SSLv2, SSLv3, TLS 1.0, TLS 1.1
- Cipher suites: AEAD ciphers only (GCM, ChaCha20-Poly1305)
- Disable: NULL, EXPORT, DES, RC4, CBC (for TLS 1.2 prefer GCM)
- Forward secrecy: require ECDHE or DHE key exchange

**Certificate management:**
- Use certificates from trusted CAs (or well-managed internal PKI)
- Minimum 2048-bit RSA or 256-bit ECDSA keys
- Automated renewal before expiration (ACME/Let's Encrypt)
- Certificate transparency logging

**HSTS (HTTP Strict Transport Security):**
- Enable with long max-age (1 year recommended)
- Include subdomains
- Consider HSTS preload list submission

**Mutual TLS (mTLS):**
- Client certificate authentication for service-to-service
- Zero-trust network architecture
- Certificate rotation automation

**Internal communication:**
- Encrypt all internal service-to-service traffic
- Service mesh (Istio, Linkerd) for automatic mTLS
- No plaintext communication even within VPC

**Reference:**
- OWASP Transport Layer Security Cheat Sheet
- NIST SP 800-52: Guidelines for TLS Implementations
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// TLS Protocol Policy.
  @SerializationOrder(1)
  TlsProtocolPolicy tlsProtocolPolicy = TlsProtocolPolicy();

  /// Certificate Management Policy.
  @SerializationOrder(2)
  CertificateManagementPolicy certificateManagement =
      CertificateManagementPolicy();

  /// Contains 0+× CommunicationChannelEncryption.
  @StandardReferences(
    [
      'NIST SP 800-53 — control SC-8 transmission confidentiality and integrity',
    ],
    'The catalog of communication channels, each with its own transport encryption requirements.',
  )
  @SectionId('COCHEN-COMM-LST')
  @SectionIdPattern('COCHEN-COMM-xxx')
  @ContentHelp('Add one entry per communication channel.')
  @SerializationOrder(3)
  List<CommunicationChannelEncryptionEntry> communicationChannels = [];

  /// Mutual TLS Policy.
  @SerializationOrder(4)
  MutualTlsPolicy mutualTlsPolicy = MutualTlsPolicy();

  /// HSTS and Transport Security Policy.
  @SerializationOrder(5)
  TransportSecurityPolicy transportSecurityPolicy = TransportSecurityPolicy();

  /// Encryption In Transit Notes (text).
  @SerializationOrder(6)
  TextSection encryptionInTransitNotes = TextSection();
}

/// TLS Protocol Policy (form).
///
/// Global settings for TLS protocol configuration: minimum and preferred
/// protocol versions, allowed cipher suites, Diffie-Hellman groups,
/// compression settings, and compliance requirements.
@Form([
  Field(
    'minimumTlsVersion',
    String,
    'Minimum TLS Version',
    required: true,
    hint:
        'TLS1.2 | TLS1.3 — minimum acceptable TLS version '
        '(TLS 1.3 recommended; TLS 1.0/1.1 are deprecated and '
        'should not be used; PCI DSS forbids TLS 1.0)',
  ),
  Field(
    'preferredTlsVersion',
    String,
    'Preferred TLS Version',
    hint:
        'TLS1.3 | TLS1.2 — preferred TLS version for new connections '
        '(TLS 1.3 provides improved security and performance)',
  ),
  Field(
    'allowedCipherSuites',
    String,
    'Allowed Cipher Suites',
    hint:
        'Comma-separated cipher suite names or categories '
        '(e.g. TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256; '
        'disable NULL, Anonymous, EXPORT, DES, RC4 ciphers)',
  ),
  Field(
    'preferAuthenticatedEncryption',
    bool,
    'Prefer Authenticated Encryption',
    hint:
        'Yes | No — whether GCM/CCM authenticated cipher modes are '
        'preferred over CBC (recommended: Yes)',
  ),
  Field(
    'dhGroups',
    String,
    'Diffie-Hellman Groups',
    hint:
        'Comma-separated DH groups for key exchange '
        '(e.g. x25519, prime256v1, ffdhe3072; per RFC 7919)',
  ),
  Field(
    'tlsCompressionDisabled',
    bool,
    'TLS Compression Disabled',
    hint:
        'Yes | No — whether TLS compression is disabled to prevent '
        'CRIME/BREACH attacks (recommended: Yes)',
  ),
  Field(
    'sessionResumption',
    String,
    'Session Resumption',
    hint:
        'Tickets | SessionID | None — TLS session resumption mechanism '
        '(tickets recommended for TLS 1.3; session IDs for TLS 1.2)',
  ),
  Field(
    'complianceFramework',
    String,
    'Compliance Framework',
    hint:
        'FIPS-140-2 | PCI-DSS | HIPAA | NIST-800-52 | None — '
        'regulatory framework dictating TLS requirements',
  ),
  Field('notes', String, 'Notes', hint: 'Additional TLS protocol policy notes'),
])
@StandardReferences(
  [
    'NIST SP 800-52 Rev. 2 — TLS implementation guidelines',
    'RFC 8446 — TLS 1.3 protocol',
  ],
  'This section defines global TLS protocol configuration, covering minimum and preferred protocol versions, allowed cipher suites, Diffie-Hellman groups, and compression settings.',
)
@SectionId('TLPRPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class TlsProtocolPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// TLS Protocol Policy Details (text).
  @SerializationOrder(1)
  TextSection tlsProtocolPolicyDetails = TextSection();
}

/// Certificate Management Policy (form).
///
/// Defines how TLS certificates are managed: certificate authority selection,
/// validation type, key strength, hashing algorithm, wildcard policy,
/// certificate lifecycle, and automated renewal.
@Form([
  Field(
    'certificateAuthority',
    String,
    'Certificate Authority',
    required: true,
    hint:
        'LetsEncrypt | DigiCert | GlobalSign | InternalCA | Other — '
        'certificate authority used for issuing TLS certificates',
  ),
  Field(
    'validationType',
    String,
    'Validation Type',
    hint:
        'DV | OV | EV — Domain Validated, Organization Validated, or '
        'Extended Validation (DV is sufficient for most applications; '
        'EV provides no additional browser security benefits)',
  ),
  Field(
    'minimumKeyLength',
    int,
    'Minimum Key Length (bits)',
    hint:
        '2048 | 3072 | 4096 — minimum RSA key length in bits for '
        'certificates (2048 minimum per NIST; 3072+ recommended)',
  ),
  Field(
    'keyType',
    String,
    'Key Type',
    hint:
        'RSA | ECDSA | Ed25519 — certificate key type '
        '(ECDSA with P-256/P-384 or Ed25519 preferred for '
        'performance; RSA for broadest compatibility)',
  ),
  Field(
    'hashingAlgorithm',
    String,
    'Hashing Algorithm',
    hint:
        'SHA-256 | SHA-384 | SHA-512 — certificate hashing algorithm '
        '(SHA-256 minimum; MD5 and SHA-1 must not be used)',
  ),
  Field(
    'wildcardCertificatePolicy',
    String,
    'Wildcard Certificate Policy',
    hint:
        'Allowed | Restricted | Prohibited — policy on wildcard '
        'certificates (* certs; use with caution per OWASP — '
        'violates least privilege principle)',
  ),
  Field(
    'certificateLifetimeDays',
    int,
    'Certificate Lifetime (Days)',
    hint:
        'Maximum certificate validity in days (e.g. 90 for '
        'LetsEncrypt auto-renewal, 365 for annual, 730 for 2-year)',
  ),
  Field(
    'automatedRenewal',
    bool,
    'Automated Renewal',
    hint:
        'Yes | No — whether certificates are automatically renewed '
        'via ACME or similar protocol before expiration',
  ),
  Field(
    'certificateTransparency',
    bool,
    'Certificate Transparency',
    hint:
        'Yes | No — whether certificates are logged in Certificate '
        'Transparency logs for public auditability',
  ),
  Field(
    'caaRecords',
    bool,
    'CAA DNS Records',
    hint:
        'Yes | No — whether CAA DNS records restrict which CAs can '
        'issue certificates for the domain',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional certificate management notes',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-52 Rev. 2 — TLS implementation guidelines',
    'NIST SP 800-53 — control SC-12 cryptographic key establishment and management',
  ],
  'This section defines how TLS certificates are managed, covering certificate authority selection, validation type, key strength, hashing algorithm, wildcard policy, lifecycle, and automated renewal.',
)
@SectionId('CEMAPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class CertificateManagementPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Certificate Management Details (text).
  @SerializationOrder(1)
  TextSection certificateManagementDetails = TextSection();
}

/// A communication channel encryption entry (form)
///.
///
/// Defines encryption requirements for a specific communication channel
/// (e.g. client-to-server HTTPS, server-to-database, inter-service,
/// WebSocket, gRPC, message queue). Allows different channels to have
/// different TLS configurations and requirements.
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-8 transmission confidentiality and integrity',
    'RFC 8446 — TLS 1.3 protocol',
  ],
  'This section defines encryption requirements for a specific communication channel, allowing different channels to have distinct TLS configurations and requirements.',
)
@SectionId('COCHEN')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class CommunicationChannelEncryptionEntry extends DocSpecsSection {
  @Form([
    Field(
      'channelName',
      String,
      'Channel Name',
      required: true,
      hint:
          'Name of the communication channel '
          '(e.g. ClientToServer, ServerToDatabase, InterService, '
          'WebSocket, gRPC, MessageQueue, EmailSMTP)',
    ),
    Field(
      'channelType',
      String,
      'Channel Type',
      hint:
          'HTTPS | gRPC | WebSocket | TCP | AMQP | MQTT | SMTP | '
          'Custom — transport protocol used by this channel',
    ),
    Field(
      'tlsRequired',
      bool,
      'TLS Required',
      required: true,
      hint:
          'Yes | No — whether TLS encryption is mandatory for this '
          'channel (should be Yes for all channels carrying '
          'sensitive data)',
    ),
    Field(
      'minimumTlsVersionOverride',
      String,
      'Minimum TLS Version Override',
      hint:
          'TLS1.2 | TLS1.3 | UseDefault — override minimum TLS '
          'version for this specific channel if different from '
          'global policy',
    ),
    Field(
      'mutualTlsRequired',
      bool,
      'Mutual TLS Required',
      hint:
          'Yes | No — whether mutual TLS (mTLS) is required for '
          'this channel (recommended for service-to-service)',
    ),
    Field(
      'certificatePinning',
      bool,
      'Certificate Pinning',
      hint:
          'Yes | No — whether certificate or public key pinning is '
          'used for this channel (useful for mobile apps, thick '
          'clients, and server-to-server communication)',
    ),
    Field(
      'pinningStrategy',
      String,
      'Pinning Strategy',
      hint:
          'PublicKey | Certificate | SPKI | None — how pinning is '
          'implemented if enabled (SPKI recommended for '
          'flexibility during key rotation)',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional notes for this communication channel',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Mutual TLS Policy (form).
///
/// Defines requirements for mutual TLS (mTLS) where both client and server
/// authenticate via certificates. Covers client certificate issuance,
/// authentication scope, revocation checking, and fallback behavior.
@Form([
  Field(
    'mtlsEnabled',
    bool,
    'mTLS Enabled',
    required: true,
    hint:
        'Yes | No — whether mutual TLS is used anywhere in the '
        'system (client certificates for authentication)',
  ),
  Field(
    'mtlsScope',
    String,
    'mTLS Scope',
    hint:
        'AllServices | InternalOnly | HighValueAPIs | '
        'SpecificEndpoints — which communication paths require mTLS',
  ),
  Field(
    'clientCertificateIssuance',
    String,
    'Client Certificate Issuance',
    hint:
        'InternalCA | ExternalCA | SelfSigned | Automated — how '
        'client certificates are issued and distributed',
  ),
  Field(
    'revocationChecking',
    String,
    'Revocation Checking',
    hint:
        'CRL | OCSP | OCSPStapling | None — how certificate '
        'revocation status is verified',
  ),
  Field(
    'fallbackOnMtlsFailure',
    String,
    'Fallback on mTLS Failure',
    hint:
        'Reject | FallbackToTLS | DegradeWithWarning — behavior '
        'when mTLS handshake fails (Reject recommended for '
        'high-security channels)',
  ),
  Field(
    'clientCertificateRotation',
    String,
    'Client Certificate Rotation',
    hint:
        'Automated | Manual | OnExpiry — how client certificates '
        'are rotated',
  ),
  Field('notes', String, 'Notes', hint: 'Additional mutual TLS policy notes'),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-8 transmission confidentiality and integrity',
    'RFC 8446 — TLS 1.3 protocol',
  ],
  'This section defines mutual TLS requirements where both client and server authenticate via certificates, covering issuance, authentication scope, revocation checking, and fallback behavior.',
)
@SectionId('MUTLPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class MutualTlsPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Mutual TLS Policy Details (text).
  @SerializationOrder(1)
  TextSection mutualTlsPolicyDetails = TextSection();
}

/// HSTS and Transport Security Policy (form).
///
/// Defines HTTP Strict Transport Security, HTTP-to-HTTPS redirect behavior,
/// secure cookie flags, mixed content prevention, and sensitive data caching
/// rules.
@Form([
  Field(
    'hstsEnabled',
    bool,
    'HSTS Enabled',
    required: true,
    hint:
        'Yes | No — whether HTTP Strict Transport Security header '
        'is sent to force browsers to use HTTPS',
  ),
  Field(
    'hstsMaxAgeDays',
    int,
    'HSTS Max-Age (Days)',
    hint:
        'HSTS max-age value in days (e.g. 365 = 1 year; 730 = '
        '2 years; must be sufficiently long to prevent downgrade)',
  ),
  Field(
    'hstsIncludeSubdomains',
    bool,
    'HSTS Include Subdomains',
    hint:
        'Yes | No — whether HSTS applies to all subdomains '
        '(recommended: Yes when all subdomains support HTTPS)',
  ),
  Field(
    'hstsPreload',
    bool,
    'HSTS Preload',
    hint:
        'Yes | No — whether the domain is submitted to the HSTS '
        'preload list (hardcoded into browsers; requires '
        'includeSubDomains and long max-age)',
  ),
  Field(
    'httpToHttpsRedirect',
    bool,
    'HTTP-to-HTTPS Redirect',
    hint:
        'Yes | No — whether HTTP requests are permanently redirected '
        '(301) to HTTPS',
  ),
  Field(
    'secureCookieFlag',
    bool,
    'Secure Cookie Flag',
    hint:
        'Yes | No — whether all cookies are marked with Secure flag '
        '(browsers only send them over HTTPS)',
  ),
  Field(
    'preventMixedContent',
    bool,
    'Prevent Mixed Content',
    hint:
        'Yes | No — whether loading of non-TLS resources from '
        'TLS pages is blocked',
  ),
  Field(
    'sensitiveDataCaching',
    String,
    'Sensitive Data Caching',
    hint:
        'NoCache | NoStore | Private | Default — cache-control '
        'headers for responses containing sensitive data '
        '(NoStore recommended per OWASP)',
  ),
  Field(
    'notes',
    String,
    'Notes',
    hint: 'Additional transport security policy notes',
  ),
])
@StandardReferences(
  [
    'NIST SP 800-53 — control SC-8 transmission confidentiality and integrity',
    'OWASP — HTTP strict transport security cheat sheet',
  ],
  'This section defines HTTP Strict Transport Security, HTTP-to-HTTPS redirect behavior, secure cookie flags, mixed content prevention, and sensitive data caching rules.',
)
@SectionId('TRSEPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class TransportSecurityPolicy extends DocSpecsSection {
  @override
  @SerializationOrder(0)
  String? content;

  /// Transport Security Policy Details (text).
  @SerializationOrder(1)
  TextSection transportSecurityPolicyDetails = TextSection();
}

// ---------------------------------------------------------------------------
// 9.5.3. Key Management
// ---------------------------------------------------------------------------

/// 9.5.3. Key Management.
///
/// Defines cryptographic key management policies covering the full key
/// lifecycle: generation, storage, rotation, escrow/backup, and compromise
/// recovery. Aligns with OWASP Key Management Cheat Sheet and
/// NIST SP 800-57 (Recommendation for Key Management).
@StandardReferences(
  [
    'NIST SP 800-57 Part 1 — recommendation for key management',
    'ISO/IEC 11770 — key management',
  ],
  'This section defines cryptographic key management policies covering the full key lifecycle: generation, storage, rotation, escrow and backup, and compromise recovery.',
)
@SectionId('KEMA')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class KeyManagement extends DocSpecsSection {
  @ContentHelp('''
Define policies for the complete lifecycle of cryptographic keys. Proper
key management is essential — poor key management can negate all encryption.

**Key hierarchy:**
- Master keys (KEKs): protect data encryption keys, stored in HSM
- Data encryption keys (DEKs): encrypt actual data, wrapped by KEKs
- Key-per-tenant: separate DEKs for tenant isolation (optional)

**Key generation:**
- Use cryptographically secure random number generators (CSPRNG)
- Generate in HSM or FIPS 140-2/140-3 validated modules for compliance
- Minimum key lengths: 256-bit symmetric, 2048-bit RSA, 256-bit ECC

**Key storage:**
- Never store keys alongside encrypted data
- HSM for production master keys (FIPS 140-2 Level 3+)
- Cloud KMS for managed key storage (AWS KMS, Azure Key Vault, GCP KMS)
- Secret managers for application secrets (HashiCorp Vault, AWS Secrets Mgr)

**Key rotation:**
- Periodic rotation (e.g., annually for DEKs, less frequent for KEKs)
- Immediate rotation on compromise or employee departure
- Re-encryption of data with rotated keys (or envelope encryption)

**Key escrow and backup:**
- Secure backup of master keys for disaster recovery
- Split key custody (M-of-N threshold schemes)
- Geographic distribution of key backups

**Compromise recovery:**
- Immediate key revocation and rotation
- Notification to affected parties
- Re-encryption of all affected data
- Forensic analysis to determine breach scope

**Reference:**
- OWASP Key Management Cheat Sheet
- NIST SP 800-57: Recommendation for Key Management
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Key Generation Policy.
  @SerializationOrder(1)
  KeyGenerationPolicy keyGenerationPolicy = KeyGenerationPolicy();

  /// Key Storage Policy.
  @SerializationOrder(2)
  KeyStoragePolicy keyStoragePolicy = KeyStoragePolicy();

  /// Key Rotation Policy.
  @SerializationOrder(3)
  KeyRotationPolicy keyRotationPolicy = KeyRotationPolicy();

  /// Key Escrow and Backup Policy.
  @SerializationOrder(4)
  KeyEscrowAndBackupPolicy keyEscrowAndBackupPolicy =
      KeyEscrowAndBackupPolicy();

  /// Key Compromise and Recovery Policy.
  @SerializationOrder(5)
  KeyCompromiseRecoveryPolicy keyCompromiseRecoveryPolicy =
      KeyCompromiseRecoveryPolicy();

  /// Additional Notes (text).
  @SerializationOrder(6)
  TextSection notes = TextSection();
}

/// Key generation policy (form).
///
/// Defines how cryptographic keys are generated: approved algorithms,
/// cryptographic module requirements (FIPS 140-2/140-3), random number
/// generation, minimum key strengths, and key-purpose separation.
@StandardReferences(
  [
    'NIST SP 800-57 Part 1 — recommendation for key management',
    'FIPS 140-3 — security requirements for cryptographic modules',
  ],
  'This section defines how cryptographic keys are generated, covering approved algorithms, cryptographic module requirements, random number generation, and minimum key strengths.',
)
@SectionId('KEGEPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class KeyGenerationPolicy extends DocSpecsSection {
  @Form([
    Field(
      'generationMethod',
      String,
      'Generation Method',
      hint:
          'Key generation method (e.g., HSM, software module, '
          'cloud KMS)',
    ),
    Field(
      'cryptographicModuleCompliance',
      String,
      'Module Compliance',
      hint:
          'Required cryptographic module compliance level '
          '(e.g., FIPS 140-2 Level 2, FIPS 140-3)',
    ),
    Field(
      'randomNumberGenerator',
      String,
      'RNG Requirements',
      hint:
          'RNG requirements (e.g., NIST SP 800-90A DRBG, '
          'hardware entropy source)',
    ),
    Field(
      'minimumKeyStrength',
      String,
      'Minimum Key Strength',
      hint:
          'Minimum key strength per algorithm type '
          '(e.g., 128-bit symmetric, 2048-bit RSA, 256-bit ECC)',
    ),
    Field(
      'approvedAlgorithms',
      String,
      'Approved Algorithms',
      hint:
          'Comma-separated list of approved algorithms '
          '(e.g., AES-256, RSA-2048, ECDSA P-256, Ed25519)',
    ),
    Field(
      'keyPurposeSeparation',
      String,
      'Key Purpose Separation',
      hint:
          'Policy for single-purpose keys '
          '(e.g., separate keys for encryption, signing, wrapping)',
    ),
    Field(
      'quantumReadinessStrategy',
      String,
      'Quantum Readiness',
      hint:
          'Post-quantum cryptography readiness '
          '(e.g., CNSA 2.0 timeline, hybrid algorithms)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Key storage policy (form).
///
/// Defines how cryptographic keys are stored: storage mechanisms (HSM,
/// vault, KMS), key-encryption-key (KEK) requirements, plaintext
/// prohibitions, integrity protection, access control, and memory
/// management considerations.
@StandardReferences(
  [
    'NIST SP 800-57 Part 1 — recommendation for key management',
    'FIPS 140-3 — security requirements for cryptographic modules',
  ],
  'This section defines how cryptographic keys are stored, covering storage mechanisms, key-encryption-key requirements, plaintext prohibitions, integrity protection, and access control.',
)
@SectionId('KESTPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class KeyStoragePolicy extends DocSpecsSection {
  @Form([
    Field(
      'storageMethod',
      String,
      'Storage Method',
      hint:
          'Primary key storage mechanism '
          '(e.g., HSM, HashiCorp Vault, AWS KMS, Azure Key Vault)',
    ),
    Field(
      'keyEncryptionKeyPolicy',
      String,
      'KEK Policy',
      hint:
          'Key-encryption-key (KEK) requirements: '
          'algorithm and minimum strength for wrapping keys',
    ),
    Field(
      'plaintextKeyProhibition',
      String,
      'Plaintext Prohibition',
      hint:
          'Controls prohibiting plaintext key storage '
          '(e.g., never stored in plaintext, encrypted at rest)',
    ),
    Field(
      'integrityProtection',
      String,
      'Integrity Protection',
      hint:
          'Integrity verification for stored keys '
          '(e.g., MAC, digital signature, authenticated encryption)',
    ),
    Field(
      'accessControl',
      String,
      'Access Control',
      hint:
          'Access control policy for key material '
          '(e.g., role-based, dual-control, split knowledge)',
    ),
    Field(
      'memoryProtection',
      String,
      'Memory Protection',
      hint:
          'In-memory key protection '
          '(e.g., key splitting, secure enclave, burn-in mitigation)',
    ),
    Field(
      'trustStorePolicy',
      String,
      'Trust Store Policy',
      hint:
          'Trust store security: injection prevention, '
          'integrity controls, export restrictions',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Key rotation policy (form).
///
/// Defines key rotation schedules, automation, triggers, grace periods,
/// versioning, and distribution of rotated keys.
@StandardReferences(
  [
    'NIST SP 800-57 Part 1 — recommendation for key management',
    'ISO/IEC 27001:2022 — control A.8.24 use of cryptography',
  ],
  'This section defines key rotation schedules, automation, triggers, grace periods, versioning, and distribution of rotated cryptographic keys.',
)
@SectionId('KEROPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class KeyRotationPolicy extends DocSpecsSection {
  @Form([
    Field(
      'rotationSchedule',
      String,
      'Rotation Schedule',
      hint:
          'Rotation frequency per key type '
          '(e.g., encryption keys every 90 days, signing keys annually)',
    ),
    Field(
      'automaticRotation',
      String,
      'Automatic Rotation',
      hint:
          'Whether rotation is automated '
          '(e.g., fully automatic via KMS, semi-automatic, manual)',
    ),
    Field(
      'rotationTriggers',
      String,
      'Rotation Triggers',
      hint:
          'Events triggering immediate rotation '
          '(e.g., suspected compromise, personnel change, '
          'algorithm deprecation)',
    ),
    Field(
      'gracePeriod',
      String,
      'Grace Period',
      hint:
          'Overlap period during which old and new keys '
          'coexist (e.g., 7 days for decryption fallback)',
    ),
    Field(
      'keyVersioning',
      String,
      'Key Versioning',
      hint:
          'Key versioning scheme '
          '(e.g., monotonic version counter, timestamp-based)',
    ),
    Field(
      'distributionMethod',
      String,
      'Distribution Method',
      hint:
          'How rotated keys are distributed '
          '(e.g., KMS push, pull-based refresh, secure channel)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Key escrow and backup policy (form).
///
/// Defines key escrow and backup procedures: whether escrow is used,
/// who holds escrowed keys, which key types are escrowed, backup
/// encryption, storage location, and backup frequency.
@StandardReferences(
  [
    'NIST SP 800-57 Part 1 — recommendation for key management',
    'ISO/IEC 11770 — key management',
  ],
  'This section defines key escrow and backup procedures, including who holds escrowed keys, which key types are backed up, and how backups are protected and stored.',
)
@SectionId('KEABP')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class KeyEscrowAndBackupPolicy extends DocSpecsSection {
  @Form([
    Field(
      'escrowEnabled',
      String,
      'Escrow Enabled',
      hint: 'Whether key escrow is used (Yes / No / Conditional)',
    ),
    Field(
      'escrowProvider',
      String,
      'Escrow Provider',
      hint:
          'Escrow provider or mechanism '
          '(e.g., Certificate Authority, KMS, internal escrow service)',
    ),
    Field(
      'escrowScope',
      String,
      'Escrow Scope',
      hint:
          'Which key types are escrowed '
          '(e.g., encryption keys only — never signing keys)',
    ),
    Field(
      'backupEncryption',
      String,
      'Backup Encryption',
      hint:
          'Backup encryption requirements '
          '(e.g., FIPS 140-2 validated module, KEK strength ≥ data key)',
    ),
    Field(
      'backupStorageLocation',
      String,
      'Backup Storage Location',
      hint:
          'Where key backups are stored '
          '(e.g., geographically separate HSM, offline vault)',
    ),
    Field(
      'backupFrequency',
      String,
      'Backup Frequency',
      hint:
          'How often key backups are performed '
          '(e.g., daily, on rotation, on creation)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Key compromise and recovery policy (form).
///
/// Defines procedures for detecting key compromise, notification,
/// re-keying, revocation, impact assessment, and the documented
/// compromise-recovery plan.
@StandardReferences(
  [
    'NIST SP 800-57 Part 1 — recommendation for key management',
    'ISO/IEC 27001:2022 — control A.8.24 use of cryptography',
  ],
  'This section defines procedures for detecting key compromise, notifying stakeholders, re-keying, revocation, and recovering from a compromised cryptographic key.',
)
@SectionId('KCRP')
@CodeSpecKind([CodeSpecPart.serverConfiguration])
class KeyCompromiseRecoveryPolicy extends DocSpecsSection {
  @Form([
    Field(
      'compromiseDetection',
      String,
      'Compromise Detection',
      hint:
          'How key compromise is detected '
          '(e.g., anomaly monitoring, audit log alerts, '
          'third-party notification)',
    ),
    Field(
      'notificationProcedure',
      String,
      'Notification Procedure',
      hint:
          'Personnel and channels notified upon compromise '
          '(e.g., security team, CISO, affected data owners)',
    ),
    Field(
      'recoveryPersonnel',
      String,
      'Recovery Personnel',
      hint: 'Roles responsible for performing recovery actions',
    ),
    Field(
      'rekeyingMethod',
      String,
      'Re-keying Method',
      hint:
          'Re-keying procedure '
          '(e.g., immediate rotation, phased re-encryption, '
          'new key generation)',
    ),
    Field(
      'revocationProcess',
      String,
      'Revocation Process',
      hint:
          'How compromised keys and certificates are revoked '
          '(e.g., CRL publication, OCSP update, KMS key disable)',
    ),
    Field(
      'keyInventoryMaintenance',
      String,
      'Key Inventory',
      hint:
          'Inventory of all keys and their use '
          '(e.g., centralized registry, certificate locations)',
    ),
    Field(
      'impactAssessment',
      String,
      'Impact Assessment',
      hint:
          'Process for identifying data and signatures '
          'affected by the compromised key',
    ),
    Field(
      'compromiseRecoveryPlanReference',
      String,
      'Recovery Plan Reference',
      hint: 'Reference to the documented compromise-recovery plan',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// 9.6. Audit and Logging.
///
/// Security audit and event logging **declarations**: which security events are
/// captured (CE-LG) and how the log sink is configured (CE-CF). Aligns with
/// OWASP Logging Cheat Sheet and NIST SP 800-92 (Guide to Computer Security Log
/// Management).
///
/// A purely-CodeSpecs subtree (`codespecs_mapping.md` §8.3) and a
/// `D13CodeSpecsProjection` root at the server locus. The operational half —
/// the review, reporting and anomaly-detection routines run against the log —
/// is the sibling `ComplianceReporting` follow-up under
/// `SecurityOperationsFollowUp`, deliberately outside this subtree so the
/// generation projection cannot reach it.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.8.15 logging',
    'NIST SP 800-92 — guide to computer security log management',
    'GDPR — Article 5(2) accountability',
  ],
  'This section covers the security audit and event logging declarations: which events are captured and how the audit log sink is structured, stored, protected and retained.',
)
@SectionId('AUANLO')
@DetailedIn(D08SecurityAccessSpecification)
@CodeSpecKind([CodeSpecPart.auditLog, CodeSpecPart.serverConfiguration],
    note: 'Two bands, both generation input, both server locus. CE-LG — the '
        'declared half of the audit trail (which invocations are auditable, '
        'whether reads count, which fields are redacted), realised as @CsAudited '
        'alongside the framework @TomAudited declaration. CE-CF — the log '
        'sink settings (format, storage, protection, retention), realised as '
        '@CsServerConfig (codespecs_mapping.md §4.3.2).')
class AuditAndLogging extends DocSpecsSection {
  @ContentHelp('''
Define security audit and logging requirements. Comprehensive logging enables
incident detection, forensic investigation, and compliance reporting.

**Logging objectives:**
- Detect security incidents in real-time or near-real-time
- Support forensic investigation after incidents
- Demonstrate compliance to auditors
- Enable trend analysis and security posture improvement

**Key event categories:**
- Authentication events (login success/failure, logout, MFA)
- Authorization events (access granted/denied, privilege changes)
- Data access events (CRUD operations on sensitive data)
- Administrative events (config changes, user management)
- Security events (input validation failures, anomalies)

**Log format:**
- Structured format (JSON) for machine parsing
- Consistent timestamp format (ISO 8601 UTC)
- Unique event IDs for correlation
- Who, what, when, where, result for each event

**Log protection:**
- Immutable logs (append-only, write-once storage)
- Integrity protection (hashing, signing)
- Access control (limited read access, no delete)

**Retention and compliance:**
- Define retention periods per log type and regulation
- PCI DSS: 1 year online, 3 months immediately available
- HIPAA: 6 years for covered entity records
- Secure deletion after retention period

**Reference:**
- OWASP Logging Cheat Sheet
- NIST SP 800-92: Guide to Computer Security Log Management
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 9.6.1. Security Events — the CE-LG declared half.
  @SerializationOrder(1)
  SecurityEventsDefinition securityEvents = SecurityEventsDefinition();

  /// 9.6.2. Audit Log Format — the CE-CF log-sink settings.
  @SerializationOrder(2)
  AuditLogFormat auditLogFormat = AuditLogFormat();
}

// ---------------------------------------------------------------------------
// 9.6.1. Security Events
// ---------------------------------------------------------------------------

/// 9.6.1. Security Events.
///
/// Defines which security events must be logged: authentication attempts,
/// authorization failures, data access, configuration changes, admin actions,
/// input validation failures, and higher-risk functionality usage.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-2 event logging',
    'NIST SP 800-53 — control AU-12 audit record generation',
    'ISO/IEC 27001:2022 — control A.8.15 logging',
  ],
  'This section defines which security-relevant events must be captured in audit logs across authentication, authorization, data, and administrative categories.',
)
@SectionId('SEEVDE')
@CodeSpecKind([CodeSpecPart.auditLog])
class SecurityEventsDefinition extends DocSpecsSection {
  @ContentHelp('''
Define which security-relevant events must be captured in audit logs.
Balance comprehensive coverage with log volume management.

**Authentication events (OWASP ASVS V7.1):**
- Login success and failure (with reason for failure)
- Logout (user-initiated and timeout)
- Password changes and resets
- MFA enrollment, verification success/failure
- Session creation, renewal, termination
- Account lockout and unlock

**Authorization events (OWASP ASVS V7.2):**
- Access denied events (who tried to access what)
- Privilege escalation (role changes, permission grants)
- Sensitive data access (who accessed what PII/PHI)
- Administrative actions (user creation, config changes)

**Data events:**
- CRUD operations on sensitive data
- Bulk data exports or downloads
- Data deletion (especially irreversible)
- Schema changes

**Security events:**
- Input validation failures (potential attack indicators)
- CSRF/XSS attempt detection
- Rate limit breaches
- Suspicious patterns (brute force, credential stuffing)

**Implementation tips:**
- Log at appropriate level (don't log sensitive data values)
- Include enough context for investigation
- Consider log sampling for high-volume, low-risk events
- Alert on high-severity events in real-time

**Reference:**
- OWASP ASVS V7: Error Handling and Logging
- OWASP Logging Cheat Sheet
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Security Event Logging Policy.
  @SerializationOrder(1)
  SecurityEventLoggingPolicy loggingPolicy = SecurityEventLoggingPolicy();

  /// Authentication Events.
  @SerializationOrder(2)
  AuthenticationEventPolicy authenticationEvents = AuthenticationEventPolicy();

  /// Authorization Events.
  @SerializationOrder(3)
  AuthorizationEventPolicy authorizationEvents = AuthorizationEventPolicy();

  /// Data Access Events.
  @SerializationOrder(4)
  DataAccessEventPolicy dataAccessEvents = DataAccessEventPolicy();

  /// Administrative Events.
  @SerializationOrder(5)
  AdministrativeEventPolicy administrativeEvents = AdministrativeEventPolicy();

  /// Custom Security Events — contains 0+× Security Event Entry.
  @StandardReferences(
    ['NIST SP 800-53 — control AU-2 event logging'],
    'The catalog of application-specific custom security events to be captured beyond the standard categories.',
  )
  @SectionId('SEVT-CUST-LST')
  @SectionIdPattern('SEVT-CUST-xxx')
  @ContentHelp('Add one entry per custom security event.')
  @SerializationOrder(6)
  List<SecurityEventEntry> customEvents = [];
}

/// Security event logging policy (form).
///
/// Overall policy for security event logging: default level, PII handling,
/// event classification scheme, and severity definitions.
@StandardReferences(
  [
    'NIST SP 800-92 — guide to computer security log management',
    'NIST SP 800-53 — control AU-2 event logging',
  ],
  'This section defines the overall policy for security event logging, including default level, PII handling, and severity classification.',
)
@SectionId('SELP')
@CodeSpecKind([CodeSpecPart.auditLog])
class SecurityEventLoggingPolicy extends DocSpecsSection {
  @Form([
    Field(
      'defaultLoggingLevel',
      String,
      'Default Logging Level',
      hint:
          'Default logging verbosity '
          '(e.g., Info, Warning, Error, Debug)',
    ),
    Field(
      'piiHandling',
      String,
      'PII Handling',
      hint:
          'How PII is handled in logs '
          '(e.g., masked, hashed, excluded, encrypted)',
    ),
    Field(
      'eventClassificationScheme',
      String,
      'Classification Scheme',
      hint:
          'Event classification scheme used '
          '(e.g., custom, CEF, LEEF, Syslog sevority)',
    ),
    Field(
      'severityLevels',
      String,
      'Severity Levels',
      hint:
          'Severity level definitions '
          '(e.g., Emergency=0, Alert=1, ... Debug=7)',
    ),
    Field(
      'timeSynchronization',
      String,
      'Time Synchronization',
      hint:
          'Time synchronization requirements '
          '(e.g., NTP with trusted source, GPS)',
    ),
    Field(
      'correlationIdentifiers',
      String,
      'Correlation Identifiers',
      hint:
          'Interaction/correlation ID strategy '
          '(e.g., request ID, trace ID, session ID)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Authentication event policy (form).
///
/// Defines which authentication-related events are logged.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-2 event logging',
    'NIST SP 800-53 — control AU-12 audit record generation',
  ],
  'This section defines which authentication events, such as logins, password changes, and MFA activity, are logged.',
)
@SectionId('AUEVPO')
@CodeSpecKind([CodeSpecPart.auditLog])
class AuthenticationEventPolicy extends DocSpecsSection {
  @Form([
    Field(
      'logSuccessfulLogins',
      String,
      'Log Successful Logins',
      hint: 'Yes / No — whether successful logins are logged',
    ),
    Field(
      'logFailedLogins',
      String,
      'Log Failed Logins',
      hint: 'Yes / No — whether failed login attempts are logged',
    ),
    Field(
      'logPasswordChanges',
      String,
      'Log Password Changes',
      hint: 'Yes / No — whether password changes are logged',
    ),
    Field(
      'logMfaEvents',
      String,
      'Log MFA Events',
      hint: 'Yes / No — whether MFA setup/verification events are logged',
    ),
    Field(
      'logSessionEvents',
      String,
      'Log Session Events',
      hint: 'Yes / No — whether session creation/termination is logged',
    ),
    Field(
      'logAccountLockouts',
      String,
      'Log Account Lockouts',
      hint: 'Yes / No — whether account lockout events are logged',
    ),
    Field(
      'logTokenEvents',
      String,
      'Log Token Events',
      hint: 'Yes / No — whether token issuance/revocation is logged',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Authorization event policy (form).
///
/// Defines which authorization-related events are logged.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-2 event logging',
    'NIST SP 800-53 — control AU-12 audit record generation',
  ],
  'This section defines which authorization events, such as access grants, denials, and privilege changes, are logged.',
)
@SectionId('AUEVP1')
@CodeSpecKind([CodeSpecPart.auditLog])
class AuthorizationEventPolicy extends DocSpecsSection {
  @Form([
    Field(
      'logAccessGranted',
      String,
      'Log Access Granted',
      hint: 'Yes / No / Sensitive-Only — whether access grants are logged',
    ),
    Field(
      'logAccessDenied',
      String,
      'Log Access Denied',
      hint: 'Yes / No — whether access denial events are logged',
    ),
    Field(
      'logPrivilegeEscalation',
      String,
      'Log Privilege Escalation',
      hint: 'Yes / No — whether privilege escalation attempts are logged',
    ),
    Field(
      'logRoleChanges',
      String,
      'Log Role Changes',
      hint: 'Yes / No — whether role assignment changes are logged',
    ),
    Field(
      'logPermissionChanges',
      String,
      'Log Permission Changes',
      hint: 'Yes / No — whether permission modifications are logged',
    ),
    Field(
      'logResourceAccessPatterns',
      String,
      'Log Resource Access Patterns',
      hint: 'Yes / No — whether resource access anomalies are logged',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Data access event policy (form).
///
/// Defines which data access events are logged.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-2 event logging',
    'GDPR — Article 30 records of processing activities',
  ],
  'This section defines which data access events, including creation, modification, deletion, and export of sensitive data, are logged.',
)
@SectionId('DAEP')
@CodeSpecKind([CodeSpecPart.auditLog])
class DataAccessEventPolicy extends DocSpecsSection {
  @Form([
    Field(
      'logDataCreation',
      String,
      'Log Data Creation',
      hint: 'Yes / No / Sensitive-Only — whether data creation is logged',
    ),
    Field(
      'logDataModification',
      String,
      'Log Data Modification',
      hint: 'Yes / No / Sensitive-Only — whether data updates are logged',
    ),
    Field(
      'logDataDeletion',
      String,
      'Log Data Deletion',
      hint: 'Yes / No — whether data deletion is logged',
    ),
    Field(
      'logDataExport',
      String,
      'Log Data Export',
      hint: 'Yes / No — whether data exports/downloads are logged',
    ),
    Field(
      'logDataImport',
      String,
      'Log Data Import',
      hint: 'Yes / No — whether data imports/uploads are logged',
    ),
    Field(
      'logBulkOperations',
      String,
      'Log Bulk Operations',
      hint: 'Yes / No — whether bulk data operations are logged',
    ),
    Field(
      'logSensitiveDataAccess',
      String,
      'Log Sensitive Data Access',
      hint: 'Yes / No — whether access to sensitive fields is logged',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Administrative event policy (form).
///
/// Defines which administrative events are logged.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-2 event logging',
    'NIST SP 800-53 — control AU-12 audit record generation',
  ],
  'This section defines which administrative events, such as configuration and user management changes, are logged.',
)
@SectionId('ADEVPO')
@CodeSpecKind([CodeSpecPart.auditLog])
class AdministrativeEventPolicy extends DocSpecsSection {
  @Form([
    Field(
      'logConfigurationChanges',
      String,
      'Log Configuration Changes',
      hint: 'Yes / No — whether system configuration changes are logged',
    ),
    Field(
      'logUserAdministration',
      String,
      'Log User Administration',
      hint: 'Yes / No — whether user account administration is logged',
    ),
    Field(
      'logSystemStartStop',
      String,
      'Log System Start/Stop',
      hint: 'Yes / No — whether application startup/shutdown is logged',
    ),
    Field(
      'logBackupRestoreOperations',
      String,
      'Log Backup/Restore',
      hint: 'Yes / No — whether backup/restore operations are logged',
    ),
    Field(
      'logSecurityPolicyChanges',
      String,
      'Log Security Policy Changes',
      hint: 'Yes / No — whether security policy modifications are logged',
    ),
    Field(
      'logAuditLogAccess',
      String,
      'Log Audit Log Access',
      hint: 'Yes / No — whether access to audit logs is logged',
    ),
    Field(
      'logBreakGlassUsage',
      String,
      'Log Break-Glass Usage',
      hint: 'Yes / No — whether emergency/break-glass access is logged',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// A custom security event entry (form).
///
/// Allows defining additional application-specific security events
/// beyond the standard categories.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-2 event logging',
    'NIST SP 800-53 — control AU-12 audit record generation',
  ],
  'This section defines a single application-specific security event beyond the standard categories, with its trigger and response.',
)
@SectionId('SEVT')
@CodeSpecKind([CodeSpecPart.auditLog])
class SecurityEventEntry extends DocSpecsSection {
  @Form([
    Field(
      'eventName',
      String,
      'Event Name',
      required: true,
      hint: 'Unique identifier for this event type',
    ),
    Field(
      'eventCategory',
      String,
      'Event Category',
      hint: 'Category (e.g., BusinessLogic, Integration, Compliance)',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What triggers this event',
    ),
    Field(
      'severity',
      String,
      'Severity',
      hint: 'Default severity level (e.g., Info, Warning, Critical)',
    ),
    Field(
      'triggerCondition',
      String,
      'Trigger Condition',
      hint: 'Specific condition that triggers logging',
    ),
    Field(
      'responseAction',
      String,
      'Response Action',
      hint: 'Automated response if any (e.g., alert, block, notify)',
    ),
    Field(
      'complianceMapping',
      String,
      'Compliance Mapping',
      hint: 'Relevant compliance requirement (e.g., PCI-DSS 10.2.5)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 9.6.2. Audit Log Format
// ---------------------------------------------------------------------------

/// 9.6.2. Audit Log Format.
///
/// Defines the audit log format: fields to capture (who, what, when, where,
/// result), log retention period, and tamper protection requirements.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-3 content of audit records',
    'NIST SP 800-92 — guide to computer security log management',
    'ISO/IEC 27001:2022 — control A.8.15 logging',
  ],
  'This section defines the structure and format of audit log entries so they are consistent, parsable, and useful for forensic investigation.',
)
@SectionId('AULOFO')
@CodeSpecKind([CodeSpecPart.serverConfiguration],
    note: 'CE-CF, not CE-LG (codespecs_mapping.md §4.3.2): the log record '
        'shape, storage, protection and retention are deployment settings on '
        'the audit sink, realised as @CsServerConfig. CE-LG owns only what is '
        'declared as auditable, in the sibling SEEVDE band.')
class AuditLogFormat extends DocSpecsSection {
  @ContentHelp('''
Define the structure and format of audit log entries for consistency,
parsability, and forensic utility.

**Essential fields (W5H):**
- **When**: ISO 8601 timestamp in UTC (e.g., 2024-01-15T14:30:00.123Z)
- **Who**: User ID, username, session ID, IP address, user agent
- **What**: Action performed, event type, target resource
- **Where**: Application, service, endpoint, server instance
- **Result**: Success/failure, HTTP status, error code, error message
- **How**: Method used (API, UI, batch), request ID for correlation

**Format requirements:**
- JSON preferred for machine parsing
- Human-readable for investigation (pretty-print option)
- Schema-validated for consistency
- Version field for format evolution

**Sensitive data handling:**
- Never log passwords, tokens, or secrets
- Mask or truncate PII (show last 4 of card numbers)
- Log references to sensitive data, not the data itself

**Log storage:**
- Centralized log aggregation (ELK, Splunk, CloudWatch)
- Separate storage from application data
- Cross-region replication for availability
- Name the storage *policy* here, never a credential to reach it. The fields in
  this band are settings the model already names, so they carry values only and
  cannot be marked secret. A remote sink's password or access key is authored as
  its own server configuration setting entry (SCSET, under System Configuration
  Management), which is the one place a secret may be declared.

**Log protection:**
- Append-only storage (no modification or deletion)
- Integrity verification (hash chains, signing)
- Encryption at rest and in transit
- Access logging for audit logs (who viewed logs)

**Retention policy:**
- Define per-event-type retention periods
- Comply with regulatory requirements (PCI: 1y, HIPAA: 6y)
- Secure deletion after retention period expires
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Event Attribute Policy.
  @SerializationOrder(1)
  EventAttributePolicy eventAttributes = EventAttributePolicy();

  /// Log Storage Policy.
  @SerializationOrder(2)
  LogStoragePolicy logStorage = LogStoragePolicy();

  /// Log Protection Policy.
  @SerializationOrder(3)
  LogProtectionPolicy logProtection = LogProtectionPolicy();

  /// Log Retention Policy.
  @SerializationOrder(4)
  LogRetentionPolicy logRetention = LogRetentionPolicy();

  /// Additional Notes (text).
  @SerializationOrder(5)
  TextSection notes = TextSection();
}

/// Event attribute policy (form).
///
/// Defines which attributes are captured for each log event:
/// when, where, who, and what information.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-3 content of audit records',
    'ISO/IEC 27001:2022 — control A.8.15 logging',
  ],
  'This section defines which attributes are captured for each log event, covering when, where, who, and what information.',
)
@SectionId('EVATPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration],
    note: 'CE-CF — the audit record\'s attribute set is a sink setting '
        '(codespecs_mapping.md §4.3.2).')
class EventAttributePolicy extends DocSpecsSection {
  @Form([
    Field(
      'timestampFormat',
      String,
      'Timestamp Format',
      hint: 'Date/time format (e.g., ISO 8601, UTC, with timezone)',
    ),
    Field(
      'applicationIdentifier',
      String,
      'Application Identifier',
      hint: 'How application is identified (e.g., name, version, instance)',
    ),
    Field(
      'sourceAddress',
      String,
      'Source Address',
      hint: 'User source info captured (e.g., IP, device ID, geolocation)',
    ),
    Field(
      'userIdentity',
      String,
      'User Identity',
      hint: 'User identity fields (e.g., user ID, username, session ID)',
    ),
    Field(
      'eventType',
      String,
      'Event Type',
      hint: 'Event type classification captured',
    ),
    Field(
      'eventSeverity',
      String,
      'Event Severity',
      hint: 'How severity is recorded (e.g., numeric 0-7, named levels)',
    ),
    Field(
      'actionAndObject',
      String,
      'Action and Object',
      hint: 'Action performed and target object (e.g., URL, resource ID)',
    ),
    Field(
      'resultStatus',
      String,
      'Result Status',
      hint: 'Outcome recorded (e.g., Success, Fail, Defer, HTTP status)',
    ),
    Field(
      'extendedDetails',
      String,
      'Extended Details',
      hint: 'Additional context captured (e.g., stack trace, request body)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Log storage policy (form).
///
/// Defines where and how log data is stored.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-11 audit record retention',
    'ISO/IEC 27001:2022 — control A.8.15 logging',
  ],
  'This section defines where and how log data is stored, including centralization, storage format, and encryption at rest.',
)
@SectionId('LOSTPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration],
    note: 'CE-CF — where the audit log is written is a deployment setting '
        '(codespecs_mapping.md §4.3.2).')
class LogStoragePolicy extends DocSpecsSection {
  @Form([
    Field(
      'primaryStorage',
      String,
      'Primary Storage',
      hint: 'Primary log storage (e.g., file system, database, cloud)',
    ),
    Field(
      'storageFormat',
      String,
      'Storage Format',
      hint: 'Log format (e.g., JSON, CEF, LEEF, Syslog, plaintext)',
    ),
    Field(
      'storageLocation',
      String,
      'Storage Location',
      hint: 'Where logs are stored (e.g., separate partition, remote SIEM)',
    ),
    Field(
      'centralizedLogging',
      String,
      'Centralized Logging',
      hint: 'Whether logs are sent to centralized system (Yes/No, system)',
    ),
    Field(
      'storageEncryption',
      String,
      'Storage Encryption',
      hint: 'Whether logs are encrypted at rest (Yes/No, method)',
    ),
    Field(
      'accessPermissions',
      String,
      'Access Permissions',
      hint: 'Access controls on log storage (e.g., read-only roles)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Log protection policy (form).
///
/// Defines tamper protection and integrity verification for logs.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-9 protection of audit information',
    'ISO/IEC 27001:2022 — control A.8.15 logging',
  ],
  'This section defines tamper protection and integrity verification for audit logs, including write protection and deletion controls.',
)
@SectionId('LOPRPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration],
    note: 'CE-CF — tamper protection of the sink is a deployment setting '
        '(codespecs_mapping.md §4.3.2).')
class LogProtectionPolicy extends DocSpecsSection {
  @Form([
    Field(
      'tamperDetection',
      String,
      'Tamper Detection',
      hint:
          'Tamper detection mechanism (e.g., cryptographic hash, MAC, '
          'digital signature, write-once media)',
    ),
    Field(
      'integrityVerification',
      String,
      'Integrity Verification',
      hint:
          'How log integrity is verified (e.g., periodic hash check, '
          'blockchain-style chaining)',
    ),
    Field(
      'writeProtection',
      String,
      'Write Protection',
      hint: 'Write protection (e.g., append-only, immutable after write)',
    ),
    Field(
      'deletionControls',
      String,
      'Deletion Controls',
      hint:
          'Controls on log deletion (e.g., dual approval, prohibited '
          'before retention period)',
    ),
    Field(
      'transmissionProtection',
      String,
      'Transmission Protection',
      hint: 'Protection during transmission (e.g., TLS, mutual TLS)',
    ),
    Field(
      'originVerification',
      String,
      'Origin Verification',
      hint: 'How log source authenticity is verified',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Log retention policy (form).
///
/// Defines how long logs are retained and disposal procedures.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-11 audit record retention',
    'ISO/IEC 27001:2022 — control A.8.15 logging',
  ],
  'This section defines log retention periods, archival, and secure disposal, including handling of legal holds.',
)
@SectionId('LOREPO')
@CodeSpecKind([CodeSpecPart.serverConfiguration],
    note: 'CE-CF — retention is the canonical §4.3.2 example of a sink '
        'setting that is not CE-LG.')
class LogRetentionPolicy extends DocSpecsSection {
  @Form([
    Field(
      'minimumRetention',
      String,
      'Minimum Retention',
      hint: 'Minimum retention period (e.g., 90 days, 1 year, 7 years)',
    ),
    Field(
      'maximumRetention',
      String,
      'Maximum Retention',
      hint: 'Maximum retention period (privacy/legal constraints)',
    ),
    Field(
      'retentionByCategory',
      String,
      'Retention by Category',
      hint: 'Different retention for different event categories',
    ),
    Field(
      'archivalPolicy',
      String,
      'Archival Policy',
      hint: 'Long-term archival approach (e.g., offline, cold storage)',
    ),
    Field(
      'disposalMethod',
      String,
      'Disposal Method',
      hint: 'Secure disposal method (e.g., cryptographic erasure, overwrite)',
    ),
    Field(
      'legalHold',
      String,
      'Legal Hold',
      hint: 'Process for legal hold on log destruction',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

// ---------------------------------------------------------------------------
// 9.6.3. Compliance Reporting
// ---------------------------------------------------------------------------

/// 9.6.3. Compliance Reporting.
///
/// Describes compliance reporting requirements: periodic access reviews,
/// privilege usage reports, anomaly detection, and regulatory audit support.
///
/// A **follow-up** subtree root (`codespecs_mapping.md` §8.3), rooted under
/// `SecurityOperationsFollowUp` rather than the sibling `AuditAndLogging`
/// CodeSpecs subtree. Everything here is a routine run *against* an existing
/// audit log — reviewing it on a cadence, reporting privileged use from it,
/// watching it for anomalies, producing evidence from it for a regulator.
/// None of it is a declaration a generator can read: the log the routines
/// consume is declared by CE-LG and configured by CE-CF next door.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.36 compliance with policies and standards',
    'SOC 2 — CC7.2 system monitoring',
    'GDPR — Article 30 records of processing activities',
  ],
  'This section describes compliance reporting requirements that satisfy regulatory audits and internal governance across access reviews and anomaly detection.',
)
@FollowUpKind([FollowUpProcess.ops, FollowUpProcess.cmp],
    note: 'OPS — periodic access review, privilege-usage reporting and anomaly '
        'detection are monitoring routines the run organisation performs. '
        'CMP — regulatory audit support is the evidence arm, delivered by the '
        'compliance process. Both, because the same four sections feed both.')
@SectionId('COMREP')
class ComplianceReporting extends DocSpecsSection {
  @ContentHelp('''
Define compliance reporting requirements to satisfy regulatory audits and
internal governance.

**Periodic access reviews:**
- Quarterly/annual user access recertification
- Manager certification of direct reports’ access
- Privileged account review (monthly or more frequent)
- Orphaned account detection and remediation
- Dormant account reporting and deactivation

**Privilege usage reports:**
- Privileged action audit reports
- Emergency access usage (break-glass)
- Elevated privilege duration and justification
- Segregation of duties violation reports

**Anomaly detection:**
- Unusual access patterns (time, location, volume)
- Impossible travel detection
- Behavioral analytics and UEBA integration
- Automated alerting for high-risk anomalies

**Regulatory audit support:**
- Pre-built compliance reports (SOC 2, PCI, HIPAA)
- Evidence collection automation
- Audit trail export capabilities
- Control attestation documentation

**Report delivery:**
- Automated scheduled reports to stakeholders
- On-demand report generation
- Dashboard views for continuous monitoring
- Secure report storage and access control

**Compliance frameworks:**
- SOC 2: CC6.1–CC6.3 (access controls), CC7.1–CC7.5 (monitoring)
- PCI DSS 10: Track and monitor access
- HIPAA §164.312: Access controls and audit
- ISO 27001: A.9 Access control, A.12 Logging
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Periodic Review Policy.
  @SerializationOrder(1)
  PeriodicReviewPolicy periodicReviews = PeriodicReviewPolicy();

  /// Privilege Usage Reporting.
  @SerializationOrder(2)
  PrivilegeUsageReporting privilegeUsageReports = PrivilegeUsageReporting();

  /// Anomaly Detection Policy.
  @SerializationOrder(3)
  AnomalyDetectionPolicy anomalyDetection = AnomalyDetectionPolicy();

  /// Regulatory Audit Support.
  @SerializationOrder(4)
  RegulatoryAuditSupport regulatoryAuditSupport = RegulatoryAuditSupport();

  /// Additional Notes (text).
  @SerializationOrder(5)
  TextSection notes = TextSection();
}

/// Periodic review policy (form).
///
/// Defines periodic reviews of access rights and security posture.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.36 compliance with policies and standards',
    'SOC 2 — CC7.2 system monitoring',
    'GDPR — Article 5(2) accountability',
  ],
  'This section defines periodic recertification of access rights and security posture, including privileged and dormant account reviews.',
)
@SectionId('PEREPO')
class PeriodicReviewPolicy extends DocSpecsSection {
  @Form([
    Field(
      'accessReviewFrequency',
      String,
      'Access Review Frequency',
      hint:
          'How often access rights are reviewed '
          '(e.g., quarterly, annually)',
    ),
    Field(
      'privilegedAccountReview',
      String,
      'Privileged Account Review',
      hint:
          'Review frequency for privileged accounts '
          '(e.g., monthly, bi-annually)',
    ),
    Field(
      'reviewers',
      String,
      'Reviewers',
      hint: 'Who performs reviews (e.g., manager, security team, CISO)',
    ),
    Field(
      'dormantAccountReview',
      String,
      'Dormant Account Review',
      hint: 'Review of inactive accounts (e.g., disable after 90 days)',
    ),
    Field(
      'segregationOfDutiesReview',
      String,
      'Segregation of Duties Review',
      hint: 'SoD violation review frequency',
    ),
    Field(
      'reviewDocumentation',
      String,
      'Review Documentation',
      hint: 'How review results are documented',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Privilege usage reporting (form).
///
/// Defines reports on privileged access and administrative actions.
@StandardReferences(
  [
    'NIST SP 800-53 — control AU-6 audit record review and analysis',
    'SOC 2 — CC7.2 system monitoring',
    'ISO/IEC 27001:2022 — control A.8.16 monitoring activities',
  ],
  'This section defines reporting on privileged and administrative activity, including escalation and break-glass usage, for oversight of high-risk access.',
)
@SectionId('PRUSRE')
class PrivilegeUsageReporting extends DocSpecsSection {
  @Form([
    Field(
      'adminActivityReports',
      String,
      'Admin Activity Reports',
      hint:
          'Reports on administrative actions '
          '(e.g., daily summary, on-demand)',
    ),
    Field(
      'privilegeEscalationReports',
      String,
      'Escalation Reports',
      hint: 'Reports on privilege escalation events',
    ),
    Field(
      'breakGlassReports',
      String,
      'Break-Glass Reports',
      hint: 'Reports on emergency access usage',
    ),
    Field(
      'accessPatternReports',
      String,
      'Access Pattern Reports',
      hint: 'Reports on unusual access patterns',
    ),
    Field(
      'reportRecipients',
      String,
      'Report Recipients',
      hint: 'Who receives privilege usage reports',
    ),
    Field(
      'reportFrequency',
      String,
      'Report Frequency',
      hint: 'How often reports are generated',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Anomaly detection policy (form).
///
/// Defines automated anomaly detection and alerting.
@StandardReferences(
  [
    'SOC 2 — CC7.2 system monitoring',
    'ISO/IEC 27001:2022 — control A.8.16 monitoring activities',
    'NIST SP 800-53 — control AU-6 audit record review and analysis',
  ],
  'This section defines automated detection of anomalous access patterns and the alerting that follows, drawing on behavior baselines and thresholds.',
)
@SectionId('ANDEPO')
class AnomalyDetectionPolicy extends DocSpecsSection {
  @Form([
    Field(
      'behaviorBaseline',
      String,
      'Behavior Baseline',
      hint: 'How normal behavior baseline is established',
    ),
    Field(
      'anomalyTypes',
      String,
      'Anomaly Types',
      hint:
          'Types of anomalies detected '
          '(e.g., unusual access time, volume, location)',
    ),
    Field(
      'detectionMechanism',
      String,
      'Detection Mechanism',
      hint:
          'How anomalies are detected '
          '(e.g., SIEM rules, ML, statistical analysis)',
    ),
    Field(
      'alertThresholds',
      String,
      'Alert Thresholds',
      hint: 'Thresholds for generating alerts',
    ),
    Field(
      'alertRecipients',
      String,
      'Alert Recipients',
      hint: 'Who receives anomaly alerts',
    ),
    Field(
      'responseActions',
      String,
      'Response Actions',
      hint: 'Automated or manual response to anomalies',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

/// Regulatory audit support (form).
///
/// Defines support for external regulatory audits.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.36 compliance with policies and standards',
    'GDPR — Article 30 records of processing activities',
    'SOC 2 — CC7.3 evaluation of security events',
  ],
  'This section defines how the system supports external regulatory audits through audit trail availability, evidence preservation, and auditor access.',
)
@SectionId('REAUSU')
class RegulatoryAuditSupport extends DocSpecsSection {
  @Form([
    Field(
      'applicableRegulations',
      String,
      'Applicable Regulations',
      hint:
          'Regulations requiring audit support '
          '(e.g., SOX, HIPAA, GDPR, PCI-DSS)',
    ),
    Field(
      'auditTrailAvailability',
      String,
      'Audit Trail Availability',
      hint: 'How audit trails are made available to auditors',
    ),
    Field(
      'reportGeneration',
      String,
      'Report Generation',
      hint: 'Standard reports available for auditors',
    ),
    Field(
      'evidencePreservation',
      String,
      'Evidence Preservation',
      hint: 'How audit evidence is preserved',
    ),
    Field(
      'auditorAccess',
      String,
      'Auditor Access',
      hint: 'How auditors are granted access (e.g., read-only role)',
    ),
    Field(
      'complianceCertifications',
      String,
      'Compliance Certifications',
      hint: 'Target certifications (e.g., SOC 2, ISO 27001)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional Notes (text).
  @SerializationOrder(1)
  TextSection notes = TextSection();
}

// ---------------------------------------------------------------------------
// 9.7 Role Matrix
// ---------------------------------------------------------------------------

/// 9.7. Role Matrix.
///
/// Role-to-permission assignment matrix covering
/// Authorization Model.
@StandardReferences(
  [
    'NIST RBAC INCITS 359-2012 — permission-to-role assignment',
    'NIST SP 800-53 — control AC-6 least privilege',
    'ISO/IEC 27001:2022 — control A.5.15 access control',
  ],
  'The authoritative role-to-permission assignment matrix for the authorization model.',
)
@SectionId('ROMA')
@DetailedIn(D08SecurityAccessSpecification)
@CodeSpecKind([CodeSpecPart.authorization])
class RoleMatrix extends DocSpecsSection {
  @ContentHelp('''
Authoritative mapping of system roles to the permissions they hold.
Complements the User Authorization section which describes the
authorization model; this section captures the concrete assignment.

**What to capture:**
- Role catalog (role name, description, owner)
- Permission catalog (object, action, scope)
- Role × permission matrix cells (granted / denied / conditional)
- Inheritance / composition relationships between roles
- Segregation-of-duties constraints (roles that must not co-assign)
- Review and re-certification cadence
- Exceptions register for elevated / time-limited access
''')
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 9.8 Compliance Framework
// ---------------------------------------------------------------------------

/// 9.8. Compliance Framework.
///
/// NIST / SOC 2 / ISO 27001 / OWASP alignment for access and
/// authorization. Pulls the compliance references currently scattered
/// across @ContentHelp strings into an explicit section.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — control A.5.36 compliance with policies rules and standards',
    'SOC 2 — Trust Services Criteria CC6 logical and physical access controls',
    'NIST SP 800-53 — security and privacy control catalog',
  ],
  'Explicit mapping of the access and authorization controls to the compliance frameworks the project must satisfy.',
)
@SectionId('CF')
@DetailedIn(D08SecurityAccessSpecification)
class ComplianceFramework extends DocSpecsSection {
  @ContentHelp('''
Explicit mapping from the access/auth controls in this concept to the
compliance frameworks the project must satisfy.

**What to capture:**
- Applicable frameworks (NIST 800-53, SOC 2 CC6.x, ISO 27001 A.9, OWASP ASVS)
- Control mapping (our control → framework requirement)
- Evidence artefacts per control (policies, logs, reports, screenshots)
- Audit cadence and ownership
- Gap analysis and remediation plan
- Certification targets and timelines
''')
  @override
  @SerializationOrder(0)
  String? content;
}


