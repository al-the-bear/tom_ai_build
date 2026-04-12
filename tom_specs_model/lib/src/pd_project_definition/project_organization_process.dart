/// Section 2: Project Organization and Process [PD00-POP].
///
/// Project-specific deviations from the standard TomSpecs methodology.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 2. Project Organization and Process [PD00-POP].
@SectionId('PD00-POP')
class ProjectOrganizationAndProcess {
  @Unused()
  String? content;

  /// 2.1. Role Adjustments [PD00-POP-ROL].
  RoleAdjustments roleAdjustments = RoleAdjustments();

  /// 2.2. Quality Gate Adjustments [PD00-POP-QGA].
  QualityGateAdjustments qualityGateAdjustments = QualityGateAdjustments();

  /// 2.3. Process Adjustments [PD00-POP-PRC].
  ProcessAdjustments processAdjustments = ProcessAdjustments();

  /// 2.4. Tooling and Environments [PD00-POP-TOO].
  ToolingAndEnvironments toolingAndEnvironments = ToolingAndEnvironments();
}

// ---------------------------------------------------------------------------
// 2.1 Role Adjustments
// ---------------------------------------------------------------------------

/// 2.1. Role Adjustments [PD00-POP-ROL].
@SectionId('PD00-POP-ROL')
class RoleAdjustments {
  @Unused()
  String? content;

  /// Contains 0+× RoleAdjustment.
  @SectionIdPattern('PD00-POP-ROL-xx')
  List<RoleAdjustmentEntry> items = [];
}

/// A role adjustment entry (form) [PD00-POP-ROL-nn].
class RoleAdjustmentEntry {
  @Form([
    Field('roleName', String, 'Role Name', required: true),
    Field('adjustment', String, 'Adjustment'),
    Field('rationale', String, 'Rationale'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 2.2 Quality Gate Adjustments
// ---------------------------------------------------------------------------

/// 2.2. Quality Gate Adjustments [PD00-POP-QGA].
@SectionId('PD00-POP-QGA')
class QualityGateAdjustments {
  @Unused()
  String? content;

  /// Contains 0+× QualityGateAdjustment.
  @SectionIdPattern('PD00-POP-QGA-xx')
  List<QualityGateAdjustmentEntry> items = [];
}

/// A quality gate adjustment entry (form) [PD00-POP-QGA-nn].
class QualityGateAdjustmentEntry {
  @Form([
    Field('gateName', String, 'Gate Name', required: true),
    Field('adjustment', String, 'Adjustment'),
    Field('rationale', String, 'Rationale'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 2.3 Process Adjustments
// ---------------------------------------------------------------------------

/// 2.3. Process Adjustments [PD00-POP-PRC].
@SectionId('PD00-POP-PRC')
class ProcessAdjustments {
  @Unused()
  String? content;

  /// Contains 0+× ProcessAdjustment.
  @SectionIdPattern('PD00-POP-PRC-xx')
  List<ProcessAdjustmentEntry> items = [];
}

/// A process adjustment entry (form) [PD00-POP-PRC-nn].
class ProcessAdjustmentEntry {
  @Form([
    Field('processName', String, 'Process Name', required: true),
    Field('adjustment', String, 'Adjustment'),
    Field('rationale', String, 'Rationale'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 2.4 Tooling and Environments
// ---------------------------------------------------------------------------

/// 2.4. Tooling and Environments [PD00-POP-TOO].
@SectionId('PD00-POP-TOO')
class ToolingAndEnvironments {
  @Unused()
  String? content;

  /// 2.4.1. Tooling [PD00-POP-TOO-TOO].
  Tooling tooling = Tooling();

  /// 2.4.2. Environments [PD00-POP-TOO-ENV].
  Environments environments = Environments();
}

/// 2.4.1. Tooling [PD00-POP-TOO-TOO].
///
/// Container for the project's tool inventory and governance policies.
/// Covers all tool categories: development, CI/CD, communication,
/// documentation, project management, testing, monitoring, security,
/// infrastructure, and operational tooling.
@SectionId('PD00-POP-TOO-TOO')
class Tooling {
  @Form([
    // --- Tool Strategy & Governance ---
    Field('toolStrategyOverview', String, 'Tool Strategy Overview',
        hint:
            'High-level approach to tooling — standardisation goals, '
            'preferred vendors, stack alignment'),
    Field('standardToolStackDescription', String,
        'Standard Tool Stack Description',
        hint:
            'Summary of the baseline tool stack all teams are expected '
            'to use'),
    Field('toolGovernancePolicy', String, 'Tool Governance Policy',
        hint:
            'Who decides on tool adoption, how exceptions are handled, '
            'review cadence'),
    Field('toolApprovalProcess', String, 'Tool Approval Process',
        hint:
            'Workflow for requesting, evaluating, and approving new tools'),
    Field('toolRationalizationGoals', String, 'Tool Rationalization Goals',
        hint:
            'Targets for reducing overlap, consolidating redundant tools'),
    Field('mandatoryToolsOverview', String, 'Mandatory Tools Overview',
        hint:
            'Tools that every team member must use — IDE, VCS, CI, '
            'communication'),
    Field('recommendedToolsOverview', String, 'Recommended Tools Overview',
        hint:
            'Encouraged but optional tools — code assistants, profilers, '
            'linters'),
    Field('optionalToolsPolicy', String, 'Optional Tools Policy',
        hint:
            'Policy for personal/team tool choices — BYO rules, security '
            'review'),
    Field('toolBudgetOverview', String, 'Tool Budget Overview',
        hint:
            'Total annual budget for tool licenses, subscriptions, and '
            'infrastructure'),
    Field('toolOnboardingProcess', String, 'Tool Onboarding Process',
        hint:
            'Standard steps when a new team member joins — account '
            'provisioning, training'),
    Field('toolOffboardingProcess', String, 'Tool Offboarding Process',
        hint:
            'Steps when a member leaves — license reclaim, access '
            'revocation, data export'),
    Field('toolReviewCadence', String, 'Tool Review Cadence',
        hint:
            'How often the tool landscape is reviewed — quarterly, '
            'biannually, annually'),
    Field('shadowItPolicy', String, 'Shadow IT Policy',
        hint:
            'Policy for unapproved tool usage — detection, enforcement, '
            'amnesty process'),
    Field('toolCatalogUrl', String, 'Tool Catalog URL',
        hint: 'Link to the authoritative tool registry or wiki page'),
    Field('notes', String, 'Notes',
        hint: 'Additional tooling strategy notes'),
  ])
  String? content;

  /// Tool strategy narrative.
  @ContentType('description',
      'Narrative overview of tool strategy, integration philosophy, '
      'and long-term tooling roadmap.')
  TextSection strategyNarrative = TextSection();

  /// Contains 0+× Tool.
  @SectionIdPattern('PD00-POP-TOO-TOO-xx')
  List<ToolEntry> items = [];
}

/// A tool entry (form) [PD00-POP-TOO-TOO-nn].
///
/// Comprehensive specification of a single tool covering identity,
/// licensing, versioning, access, integration, support, security,
/// usage, infrastructure, lifecycle, cost, configuration, and
/// documentation. Aligns with ITIL service catalog, PMBOK resource
/// planning, and enterprise architecture concerns.
class ToolEntry {
  @Form([
    // --- Identity & Classification ---
    // --- Identity & Classification ---
    Field('toolName', String, 'Tool Name',
        hint: 'Official product name, e.g. GitHub, Jira, VS Code',
        required: true),
    Field('toolId', String, 'Tool ID',
        hint: 'Unique identifier, e.g. TOOL-IDE-001'),
    Field('vendorName', String, 'Vendor / Publisher',
        hint:
            'Company or organization, e.g. Microsoft, Atlassian, '
            'JetBrains'),
    Field('category', String, 'Category',
        hint:
            'IDE / VCS / CI-CD / ProjectManagement / Communication / '
            'Documentation / Testing / Monitoring / Security / '
            'Infrastructure / Database / Analytics / DesignPrototyping / '
            'CodeQuality / ArtifactManagement / Other'),
    Field('subcategory', String, 'Subcategory',
        hint:
            'More specific classification, e.g. StaticAnalysis, '
            'ContainerOrchestration, ChatMessaging, WikiKnowledgeBase'),
    Field('toolType', String, 'Tool Type',
        hint:
            'Commercial / OpenSource / Freemium / CustomBuilt / '
            'InternalFork / Managed'),
    Field('purpose', String, 'Purpose',
        hint: 'What this tool is used for in the project'),
    Field('businessJustification', String, 'Business Justification',
        hint:
            'Why this tool was chosen over alternatives — cost, '
            'capability, strategy'),
    Field('mandatoryLevel', String, 'Mandatory Level',
        hint: 'Mandatory / Recommended / Optional / Deprecated'),
    Field('targetAudience', String, 'Target Audience',
        hint:
            'Who uses this tool — Developers, QA, DevOps, PMs, All, '
            'Stakeholders'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint:
            'Other tools evaluated, e.g. GitLab vs GitHub, Jira vs '
            'Linear'),
    Field('selectionRationale', String, 'Selection Rationale',
        hint: 'Why this tool won over alternatives'),

    // --- Licensing ---
    // --- Licensing ---
    Field('licenseType', String, 'License Type',
        hint:
            'SPDX identifier or commercial name, e.g. MIT, Apache-2.0, '
            'Enterprise v3'),
    Field('licenseModel', String, 'License Model',
        hint:
            'PerSeat / PerUser / Floating / Site / Metered / FreeTier / '
            'OpenCore'),
    Field('licenseCount', String, 'License Count',
        hint: 'Number of licenses purchased or allocated'),
    Field('licenseCostPerUnit', String, 'License Cost Per Unit',
        hint: 'Cost per seat/user/instance per billing period'),
    Field('licenseBillingPeriod', String, 'License Billing Period',
        hint: 'Monthly / Annually / Perpetual / Multi-Year'),
    Field('licenseExpiryDate', String, 'License Expiry Date',
        hint: 'When the current license term ends'),
    Field('licenseRenewalDate', String, 'License Renewal Date',
        hint: 'When renewal must be initiated to avoid lapse'),
    Field('licenseOwner', String, 'License Owner',
        hint: 'Person or team managing the license relationship'),
    Field('licenseKeyLocation', String, 'License Key Location',
        hint:
            'Where the license key is stored — vault path, admin portal '
            'URL (never the key itself)'),
    Field('openSourceObligations', String, 'Open-Source Obligations',
        hint:
            'Copyleft, attribution, source disclosure requirements'),
    Field('licenseComplianceStatus', String, 'License Compliance Status',
        hint: 'Compliant / UnderReview / AtRisk / NonCompliant'),

    // --- Versioning ---
    // --- Versioning ---
    Field('currentVersion', String, 'Current Version',
        hint: 'Version currently deployed or in use'),
    Field('minimumVersion', String, 'Minimum Version',
        hint: 'Earliest acceptable version'),
    Field('targetVersion', String, 'Target Version',
        hint: 'Next planned upgrade target'),
    Field('latestAvailableVersion', String, 'Latest Available Version',
        hint: 'Most recent stable release from vendor'),
    Field('upgradeCadence', String, 'Upgrade Cadence',
        hint:
            'How often upgrades are applied — monthly, quarterly, '
            'per-release, LTS-only'),
    Field('autoUpdatePolicy', String, 'Auto-Update Policy',
        hint:
            'Enabled / Disabled / MajorManualMinorAuto / '
            'ManagedByVendor'),
    Field('upgradeApprovalProcess', String, 'Upgrade Approval Process',
        hint: 'Who approves version upgrades, testing requirements'),
    Field('versionPinningPolicy', String, 'Version Pinning Policy',
        hint:
            'Whether and how versions are pinned — lockfiles, tags, '
            'channels'),
    Field('breakingChangePolicy', String, 'Breaking Change Policy',
        hint:
            'How breaking changes from vendor are handled — testing, '
            'rollback, migration'),
    Field('releaseNotesUrl', String, 'Release Notes URL',
        hint: 'Link to vendor changelog or release announcements'),

    // --- Access & Provisioning ---
    // --- Access & Provisioning ---
    Field('accessUrl', String, 'Access URL',
        hint: 'Primary URL/endpoint to access the tool'),
    Field('accessMethod', String, 'Access Method',
        hint:
            'Web / DesktopApp / CLI / IDE-Plugin / API / MobileApp / '
            'Terminal'),
    Field('ssoIntegration', String, 'SSO Integration',
        hint:
            'SSO provider and protocol — Okta SAML, Azure AD OIDC, '
            'None'),
    Field('mfaRequired', String, 'MFA Required',
        hint: 'Yes / No / ForAdminsOnly'),
    Field('provisioningMethod', String, 'Provisioning Method',
        hint:
            'Automatic-SCIM / Manual / SelfService / InviteBased / '
            'LDAP-Sync'),
    Field('deprovisioningMethod', String, 'Deprovisioning Method',
        hint:
            'Automatic-SCIM / Manual / OnLeaver-Trigger / Timed-Expiry'),
    Field('accessRequestProcess', String, 'Access Request Process',
        hint:
            'How to request access — ServiceNow ticket, Slack channel, '
            'email'),
    Field('accessApprover', String, 'Access Approver',
        hint:
            'Who approves access requests — manager, tool admin, auto'),
    Field('adminContact', String, 'Admin Contact',
        hint: 'Internal administrator or admin team'),
    Field('adminPortalUrl', String, 'Admin Portal URL',
        hint: 'URL for tool administration panel'),
    Field('onboardingSteps', String, 'Onboarding Steps',
        hint:
            'Steps for new users — account creation, config import, '
            'training requirement'),
    Field('serviceAccountPolicy', String, 'Service Account Policy',
        hint:
            'Rules for non-human accounts — naming, rotation, scope '
            'limits'),

    // --- Integration ---
    // --- Integration ---
    Field('integratesWithTools', String, 'Integrates With',
        hint:
            'Other project tools this integrates with, e.g. '
            'GitHub↔Jira, Slack↔PagerDuty'),
    Field('apiAvailability', String, 'API Availability',
        hint: 'REST / GraphQL / gRPC / WebSocket / SDK / CLI / None'),
    Field('apiDocumentationUrl', String, 'API Documentation URL',
        hint: 'Link to API reference or SDK docs'),
    Field('apiAuthMethod', String, 'API Auth Method',
        hint: 'OAuth2 / APIKey / PAT / ServiceAccount / mTLS'),
    Field('webhooksSupported', String, 'Webhooks Supported',
        hint: 'Yes / No — webhook event types available'),
    Field('pluginExtensionList', String, 'Plugins / Extensions',
        hint:
            'Required or recommended plugins, e.g. ESLint, Dart, '
            'GitLens'),
    Field('dataExchangeFormat', String, 'Data Exchange Format',
        hint:
            'JSON / XML / CSV / Protobuf / Custom — for import/export'),
    Field('dataImportCapability', String, 'Data Import Capability',
        hint:
            'Can import from other tools — formats, limitations'),
    Field('dataExportCapability', String, 'Data Export Capability',
        hint:
            'Can export data — formats, completeness, scheduling'),
    Field('automationCapability', String, 'Automation Capability',
        hint:
            'CI/CD hooks, scheduled tasks, scripting, CLI automation '
            'support'),

    // --- Support ---
    // --- Support ---
    Field('vendorSupportTier', String, 'Vendor Support Tier',
        hint:
            'CommunityOnly / Basic / Standard / Premium / '
            'Enterprise24x7'),
    Field('vendorSupportUrl', String, 'Vendor Support URL',
        hint: 'Link to vendor support portal or ticketing'),
    Field('vendorSla', String, 'Vendor SLA',
        hint:
            'Response/resolution SLA, e.g. P1: 1h response, 4h '
            'resolution'),
    Field('internalSupportTeam', String, 'Internal Support Team',
        hint: 'Internal team providing L1/L2 support for this tool'),
    Field('internalSupportChannel', String, 'Internal Support Channel',
        hint: 'Slack channel, email alias, or ServiceNow queue'),
    Field('escalationPath', String, 'Escalation Path',
        hint:
            'L1 Internal → L2 Internal → Vendor Support → Account '
            'Manager'),
    Field('knownIssues', String, 'Known Issues',
        hint:
            'Current known issues or limitations affecting the project'),

    // --- Security & Compliance ---
    // --- Security & Compliance ---
    Field('securityClassification', String, 'Security Classification',
        hint: 'Public / Internal / Confidential / Restricted'),
    Field('dataResidency', String, 'Data Residency',
        hint:
            'Where data is stored geographically — EU, US, '
            'vendor-managed, self-hosted'),
    Field('dataClassification', String, 'Data Classification',
        hint:
            'What data flows through this tool — PII, source code, '
            'secrets, public'),
    Field('auditLogging', String, 'Audit Logging',
        hint:
            'Yes / No / Partial — what actions are logged, retention '
            'period'),
    Field('complianceCertifications', String, 'Compliance Certifications',
        hint: 'SOC2 / ISO27001 / HIPAA / GDPR / FedRAMP / PCI-DSS'),
    Field('securityReviewDate', String, 'Last Security Review Date',
        hint: 'When the tool was last security-assessed'),
    Field('securityReviewOutcome', String, 'Security Review Outcome',
        hint: 'Approved / ConditionalApproval / Rejected / Pending'),
    Field('vulnerabilityScanPolicy', String, 'Vulnerability Scan Policy',
        hint:
            'How the tool is scanned — vendor responsibility, internal '
            'pen-test'),
    Field('encryptionAtRest', String, 'Encryption at Rest',
        hint:
            'AES-256, vendor-managed keys, customer-managed keys'),
    Field('encryptionInTransit', String, 'Encryption in Transit',
        hint: 'TLS 1.2+, mTLS, certificate pinning'),
    Field('dataRetentionPolicy', String, 'Data Retention Policy',
        hint:
            'How long data is retained, purge schedule, legal holds'),
    Field('gdprCompliance', String, 'GDPR Compliance',
        hint:
            'DPA signed, data subject request process, right to '
            'erasure'),
    Field('ipRestrictions', String, 'IP Restrictions',
        hint: 'IP allowlist, VPN-only access, geo-blocking'),

    // --- Usage ---
    // --- Usage ---
    Field('userGroups', String, 'User Groups',
        hint:
            'Teams or roles using this tool — Backend, Frontend, QA, '
            'DevOps, PM, All'),
    Field('activeUserCount', String, 'Active User Count',
        hint: 'Number of active users, e.g. 45 / 50 licenses'),
    Field('usageFrequency', String, 'Usage Frequency',
        hint: 'Daily / Weekly / PerSprint / OnDemand / Continuous'),
    Field('peakUsagePeriod', String, 'Peak Usage Period',
        hint:
            'When usage spikes — release days, sprint planning, '
            'incident response'),
    Field('trainingRequired', String, 'Training Required',
        hint:
            'Yes / No — what training, how long, mandatory or optional'),
    Field('trainingMaterial', String, 'Training Material',
        hint:
            'Links to training resources — vendor courses, internal '
            'guides, videos'),
    Field('proficiencyLevels', String, 'Proficiency Levels',
        hint:
            'Beginner / Intermediate / Advanced — expected proficiency '
            'per role'),
    Field('adoptionStatus', String, 'Adoption Status',
        hint:
            'Piloting / RollingOut / FullyAdopted / Declining / '
            'Sunsetting'),
    Field('adoptionPercentage', String, 'Adoption Percentage',
        hint:
            'Percentage of target users actively using the tool'),
    Field('userSatisfactionScore', String, 'User Satisfaction Score',
        hint: 'Latest survey score, e.g. 4.2/5, NPS +35'),

    // --- Infrastructure ---
    // --- Infrastructure ---
    Field('hostingModel', String, 'Hosting Model',
        hint: 'SaaS / OnPremise / Hybrid / SelfHostedCloud / PaaS'),
    Field('instanceCount', String, 'Instance Count',
        hint:
            'Number of instances — 1 SaaS tenant, 3 on-prem servers, '
            'etc.'),
    Field('instanceUrls', String, 'Instance URLs',
        hint:
            'URLs for each instance, e.g. prod: tools.example.com, '
            'dev: tools-dev.example.com'),
    Field('resourceRequirements', String, 'Resource Requirements',
        hint:
            'CPU, memory, disk, network — for self-hosted deployments'),
    Field('scalabilityLimits', String, 'Scalability Limits',
        hint:
            'Known limits — max users, max repos, max artifacts, max '
            'concurrent builds'),
    Field('backupResponsibility', String, 'Backup Responsibility',
        hint:
            'Vendor / Internal / Shared — backup strategy and frequency'),
    Field('backupFrequency', String, 'Backup Frequency',
        hint: 'Daily / Hourly / Continuous / PerRelease'),
    Field('disasterRecoveryPlan', String, 'Disaster Recovery Plan',
        hint:
            'Failover strategy, RTO/RPO, tested restore process'),
    Field('uptimeSla', String, 'Uptime SLA',
        hint: 'Vendor-guaranteed uptime, e.g. 99.95%'),
    Field('statusPageUrl', String, 'Status Page URL',
        hint: 'Link to vendor status page for outage tracking'),
    Field('maintenanceWindow', String, 'Maintenance Window',
        hint:
            'Scheduled maintenance times, e.g. Sun 02:00-06:00 UTC'),

    // --- Lifecycle ---
    // --- Lifecycle ---
    Field('introductionDate', String, 'Introduction Date',
        hint: 'When the tool was adopted or will be introduced'),
    Field('lastEvaluationDate', String, 'Last Evaluation Date',
        hint: 'When the tool was last formally reviewed'),
    Field('nextEvaluationDate', String, 'Next Evaluation Date',
        hint: 'When the next review is scheduled'),
    Field('plannedRetirementDate', String, 'Planned Retirement Date',
        hint: 'Scheduled end-of-use date, if known'),
    Field('replacementTool', String, 'Replacement Tool',
        hint: 'Tool that will replace this one upon retirement'),
    Field('migrationPath', String, 'Migration Path',
        hint:
            'High-level migration plan — data export, re-training, '
            'parallel run'),
    Field('migrationEffort', String, 'Migration Effort',
        hint: 'Estimated effort to migrate — person-days, complexity'),
    Field('vendorRoadmapAlignment', String, 'Vendor Roadmap Alignment',
        hint:
            'How well vendor roadmap aligns with project needs — '
            'Strong / Moderate / Weak'),
    Field('endOfLifeRisk', String, 'End-of-Life Risk',
        hint:
            'Low / Medium / High — risk of vendor discontinuing the '
            'product'),

    // --- Cost ---
    // --- Cost ---
    Field('initialCost', String, 'Initial Cost',
        hint: 'One-time setup, migration, and integration cost'),
    Field('recurringCost', String, 'Recurring Cost',
        hint: 'Annual or monthly ongoing cost'),
    Field('costModel', String, 'Cost Model',
        hint: 'PerUser / FlatRate / UsageBased / Tiered / Free'),
    Field('costCenter', String, 'Cost Center',
        hint: 'Cost center or billing code for chargeback'),
    Field('budgetOwner', String, 'Budget Owner',
        hint: 'Person or team responsible for the tool budget'),
    Field('costTrend', String, 'Cost Trend',
        hint:
            'Increasing / Stable / Decreasing — recent cost trajectory '
            'and drivers'),
    Field('costOptimizationNotes', String, 'Cost Optimization Notes',
        hint:
            'Ways to reduce cost — right-sizing, license consolidation, '
            'tier change'),

    // --- Configuration ---
    // --- Configuration ---
    Field('standardConfiguration', String, 'Standard Configuration',
        hint:
            'Baseline settings all users must apply — e.g. '
            '.editorconfig, analysis_options'),
    Field('mandatoryPlugins', String, 'Mandatory Plugins',
        hint:
            'Plugins required for compliance — e.g. security scanner, '
            'formatter'),
    Field('recommendedPlugins', String, 'Recommended Plugins',
        hint: 'Encouraged but optional plugins'),
    Field('prohibitedFeatures', String, 'Prohibited Features',
        hint:
            'Features disabled for security/compliance — e.g. public '
            'sharing, AI code completion'),
    Field('configurationRepository', String, 'Configuration Repository',
        hint:
            'Where shared config files are stored — repo path, wiki '
            'link'),
    Field('configurationAsCode', String, 'Configuration as Code',
        hint:
            'Yes / No / Partial — whether tool config is '
            'version-controlled'),

    // --- Documentation ---
    // --- Documentation ---
    Field('vendorDocumentationUrl', String, 'Vendor Documentation URL',
        hint: 'Link to official product documentation'),
    Field('internalWikiUrl', String, 'Internal Wiki / Guide URL',
        hint: 'Link to internal documentation, runbooks, or wiki'),
    Field('quickStartGuideUrl', String, 'Quick-Start Guide URL',
        hint: 'Link to internal quick-start guide for new users'),
    Field('troubleshootingGuideUrl', String, 'Troubleshooting Guide URL',
        hint: 'Link to common issues and solutions'),
    Field('architectureDiagramUrl', String, 'Architecture Diagram URL',
        hint:
            'Link to diagram showing how this tool fits in the overall '
            'toolchain'),

    // --- Approval & Ownership ---
    // --- Approval & Ownership ---
    Field('approvalStatus', String, 'Approval Status',
        hint:
            'Proposed / UnderReview / Approved / Rejected / Deprecated'),
    Field('approvedBy', String, 'Approved By',
        hint: 'Name or role of the person who approved this tool'),
    Field('approvalDate', String, 'Approval Date',
        hint: 'When the tool was formally approved'),
    Field('toolOwner', String, 'Tool Owner',
        hint:
            'Person or team accountable for the tool lifecycle'),
    Field('toolChampion', String, 'Tool Champion',
        hint:
            'Internal advocate driving adoption and best practices'),

    // --- Notes ---
    // --- Notes ---
    Field('notes', String, 'Notes',
        hint: 'Additional notes, caveats, or context'),
  ])
  String? content;

  /// Integration details narrative.
  TextSection integrationNotes = TextSection();
}

/// 2.4.2. Environments [PD00-POP-TOO-ENV].
///
/// Operational overview of project environments and the inventory of
/// individual environment instances. Strategy-level decisions (tier
/// definitions, parity goals, ephemeral environments) live in the
/// companion EnvironmentStrategy class under the Technical Framework.
@SectionId('PD00-POP-TOO-ENV')
class Environments {
  @Form([
    Field('promotionPath', String, 'Promotion Path',
        hint: 'Deployment flow, e.g. Dev -> QA -> Staging -> Prod'),
    Field('environmentTopology', String, 'Environment Topology',
        hint:
            'High-level network/architecture topology across environments'),
    Field('namingConvention', String, 'Naming Convention',
        hint:
            'Resource naming pattern, e.g. {project}-{env}-{service}-{region}'),
    Field('environmentCount', String, 'Environment Count',
        hint: 'Total number of permanent and ephemeral environments'),
    Field('defaultRefreshPolicy', String, 'Default Refresh Policy',
        hint:
            'Standard data/infra refresh cadence applied unless overridden'),
    Field('sharedServicesOverview', String, 'Shared Services Overview',
        hint:
            'Services shared across environments, e.g. IAM, DNS, logging'),
    Field('notes', String, 'Notes',
        hint: 'Additional environment overview notes'),
  ])
  String? content;

  /// Contains 0+× Environment.
  @SectionIdPattern('PD00-POP-TOO-ENV-xx')
  List<EnvironmentEntry> items = [];
}

/// An environment entry (form) [PD00-POP-TOO-ENV-nn].
///
/// Comprehensive specification of a single project environment covering
/// identity, infrastructure, access, data management, configuration,
/// availability, connectivity, monitoring, lifecycle, ownership, cost,
/// and compliance. Aligns with PMBOK resource planning, ITIL service
/// design, and PRINCE2 technical stage planning concerns.
class EnvironmentEntry {
  @Form([
    // --- Identity & Classification ---
    Field('environmentName', String, 'Environment Name',
        hint: 'Canonical name, e.g. Production, Staging-EU, Dev-Feature',
        required: true),
    Field('environmentId', String, 'Environment ID',
        hint: 'Unique code, e.g. ENV-PROD-01'),
    Field('environmentType', String, 'Environment Type',
        hint:
            'Development / Testing / Integration / QA / UAT / Staging / Production / DR / Sandbox / Demo'),
    Field('purpose', String, 'Purpose',
        hint: 'Business purpose — what this environment is used for'),
    Field('tierClassification', String, 'Tier Classification',
        hint:
            'Tier 0 (Prod) / Tier 1 (Staging) / Tier 2 (QA) / Tier 3 (Dev)'),
    Field('promotionPosition', String, 'Promotion Position',
        hint: 'Position in promotion path, e.g. 3 of 4 (before Prod)'),

    // --- Infrastructure ---
    Field('hostingModel', String, 'Hosting Model',
        hint: 'Cloud / OnPremise / Hybrid / CoLocated'),
    Field('cloudProvider', String, 'Cloud Provider',
        hint: 'AWS / Azure / GCP / PrivateCloud / MultiCloud'),
    Field('region', String, 'Region',
        hint: 'Deployment region(s), e.g. eu-west-1, eastus2'),
    Field('availabilityZones', String, 'Availability Zones',
        hint: 'AZs used, e.g. eu-west-1a, eu-west-1b'),
    Field('computeResources', String, 'Compute Resources',
        hint:
            'Instance types, vCPU, RAM, e.g. 3x m5.xlarge (4 vCPU, 16 GB)'),
    Field('storageResources', String, 'Storage Resources',
        hint: 'Disk, object storage, managed DB storage sizes'),
    Field('networkConfiguration', String, 'Network Configuration',
        hint: 'VPC/VNet, subnets, CIDR ranges'),
    Field('containerPlatform', String, 'Container Platform',
        hint:
            'Kubernetes / ECS / Docker Compose / None — cluster details'),

    // --- Access & Security ---
    Field('accessControlModel', String, 'Access Control Model',
        hint: 'RBAC / ABAC / NetworkBased / Combined'),
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'SSO, MFA, service accounts, API keys'),
    Field('authorizedRoles', String, 'Authorized Roles',
        hint:
            'Roles/teams with access, e.g. DevOps, QA, Developers'),
    Field('vpnRequired', String, 'VPN Required',
        hint: 'Yes / No — whether VPN/private network access is required'),
    Field('securityClassification', String, 'Security Classification',
        hint: 'Public / Internal / Confidential / Restricted'),
    Field('encryptionAtRest', String, 'Encryption at Rest',
        hint: 'AES-256, KMS key, HSM-backed — scope'),
    Field('encryptionInTransit', String, 'Encryption in Transit',
        hint: 'TLS 1.3 / mTLS / VPN tunnel requirements'),
    Field('secretsManagement', String, 'Secrets Management',
        hint: 'Vault, AWS Secrets Manager, Azure Key Vault'),

    // --- Data Management ---
    Field('dataClassification', String, 'Data Classification',
        hint: 'Production / Anonymized / Synthetic / Subset / Empty'),
    Field('dataRefreshStrategy', String, 'Data Refresh Strategy',
        hint:
            'How data is populated — snapshot restore, ETL, seed scripts'),
    Field('dataRefreshFrequency', String, 'Data Refresh Frequency',
        hint: 'Daily / Weekly / OnDemand / PerRelease'),
    Field('dataRetentionPolicy', String, 'Data Retention Policy',
        hint: 'How long data is kept, archival rules'),
    Field('backupStrategy', String, 'Backup Strategy',
        hint:
            'Backup frequency, retention period, tested restore cadence'),
    Field('dataResidency', String, 'Data Residency',
        hint: 'Geographic/legal constraints for data storage'),

    // --- Configuration & Versions ---
    Field('operatingSystem', String, 'Operating System',
        hint: 'OS and version, e.g. Ubuntu 22.04 LTS'),
    Field('runtimeVersions', String, 'Runtime Versions',
        hint: 'Language/framework versions, e.g. Dart 3.5, Node 20 LTS'),
    Field('databaseVersions', String, 'Database Versions',
        hint: 'DB engine(s) and version(s), e.g. PostgreSQL 16, Redis 7'),
    Field('middleware', String, 'Middleware',
        hint: 'Message queues, caches, search engines, e.g. RabbitMQ 3.13'),
    Field('featureFlagConfig', String, 'Feature Flag Configuration',
        hint: 'Environment-specific feature flag overrides'),
    Field('configurationMethod', String, 'Configuration Method',
        hint: 'Env vars / Secrets Manager / Config files / Consul'),

    // --- Availability & SLA ---
    Field('uptimeRequirement', String, 'Uptime Requirement',
        hint: 'Target availability, e.g. 99.95%'),
    Field('maintenanceWindow', String, 'Maintenance Window',
        hint: 'Scheduled window, e.g. Sun 02:00-06:00 UTC'),
    Field('slaTarget', String, 'SLA Target',
        hint: 'Response/resolution times for incidents'),
    Field('rpo', String, 'Recovery Point Objective',
        hint: 'Max acceptable data loss, e.g. 1 hour'),
    Field('rto', String, 'Recovery Time Objective',
        hint: 'Max acceptable downtime, e.g. 4 hours'),
    Field('disasterRecoveryPlan', String, 'Disaster Recovery Plan',
        hint: 'DR strategy — warm standby, pilot light, active-active'),

    // --- Connectivity & Network ---
    Field('networkZone', String, 'Network Zone',
        hint: 'DMZ / Internal / Management / Restricted'),
    Field('firewallRules', String, 'Firewall Rules',
        hint: 'Key inbound/outbound rules summary'),
    Field('integrationEndpoints', String, 'Integration Endpoints',
        hint: 'External/internal APIs this env connects to'),
    Field('dnsConfiguration', String, 'DNS Configuration',
        hint: 'DNS entries, e.g. staging.example.com -> ALB'),
    Field('loadBalancer', String, 'Load Balancer',
        hint: 'LB type and config, e.g. ALB with path-based routing'),
    Field('serviceDiscovery', String, 'Service Discovery',
        hint: 'DNS-based / Service mesh / Consul / K8s Services'),

    // --- Monitoring & Observability ---
    Field('monitoringTools', String, 'Monitoring Tools',
        hint: 'APM and infra monitoring, e.g. Datadog, CloudWatch'),
    Field('loggingPlatform', String, 'Logging Platform',
        hint: 'Centralized logging, e.g. ELK, CloudWatch Logs, Loki'),
    Field('alertingConfiguration', String, 'Alerting Configuration',
        hint: 'Alert rules, channels, thresholds, escalation'),
    Field('dashboardUrl', String, 'Dashboard URL',
        hint: 'Monitoring/status dashboard URL'),
    Field('healthCheckEndpoints', String, 'Health Check Endpoints',
        hint: 'Health and readiness probe paths'),

    // --- Lifecycle & Provisioning ---
    Field('provisioningMethod', String, 'Provisioning Method',
        hint: 'Manual / Terraform / CloudFormation / Pulumi / Helm'),
    Field('iacRepository', String, 'IaC Repository',
        hint: 'Repo/path where infrastructure code lives'),
    Field('refreshCadence', String, 'Refresh Cadence',
        hint: 'How often the environment is rebuilt or refreshed'),
    Field('decommissionPlan', String, 'Decommission Plan',
        hint: 'End-of-life steps, data migration, DNS cleanup'),
    Field('creationDate', String, 'Creation Date',
        hint: 'When the environment was or will be provisioned'),
    Field('plannedRetirementDate', String, 'Planned Retirement Date',
        hint: 'Scheduled decommission date, if known'),

    // --- Ownership & Support ---
    Field('environmentOwner', String, 'Environment Owner',
        hint: 'Team or individual responsible for this environment'),
    Field('supportContact', String, 'Support Contact',
        hint: 'Primary support contact or on-call team'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'Escalation chain, e.g. L1 -> L2 -> Platform Lead'),
    Field('changeApprovalProcess', String, 'Change Approval Process',
        hint: 'How changes are approved — CAB, PR review, auto-deploy'),

    // --- Cost & Billing ---
    Field('monthlyCostEstimate', String, 'Monthly Cost Estimate',
        hint: 'Estimated cost per month'),
    Field('billingModel', String, 'Billing Model',
        hint: 'PayAsYouGo / Reserved / SavingsPlan / Spot'),
    Field('costCenter', String, 'Cost Center',
        hint: 'Cost center or billing code for chargeback'),
    Field('budgetAlertThreshold', String, 'Budget Alert Threshold',
        hint: 'Spending threshold that triggers alerts'),

    // --- Compliance & Audit ---
    Field('complianceFrameworks', String, 'Compliance Frameworks',
        hint: 'SOC 2, HIPAA, GDPR, PCI-DSS, ISO 27001'),
    Field('auditLogging', String, 'Audit Logging',
        hint: 'Audit trail scope — access, changes, data operations'),
    Field('penetrationTestSchedule', String, 'Penetration Test Schedule',
        hint: 'Frequency and scope of security testing'),

    // --- Notes ---
    Field('notes', String, 'Notes',
        hint: 'Additional environment-specific notes'),
  ])
  String? content;
}
