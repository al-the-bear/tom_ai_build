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
@SectionId('PD00-POP-TOO-TOO')
class Tooling {
  @Unused()
  String? content;

  /// Contains 0+× Tool.
  @SectionIdPattern('PD00-POP-TOO-TOO-xx')
  List<ToolEntry> items = [];
}

/// A tool entry (form) [PD00-POP-TOO-TOO-nn].
class ToolEntry {
  @Form([
    Field('toolName', String, 'Tool Name', required: true),
    Field('purpose', String, 'Purpose'),
    Field('version', String, 'Version'),
    Field('category', String, 'Category'),
  ])
  String? content;
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
