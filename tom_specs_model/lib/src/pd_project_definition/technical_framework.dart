/// Section 8: Technical Framework Concept [PD00-TEC]. Seeds → TR.
///
/// Technical framework requirements and constraints.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 8. Technical Framework Concept [PD00-TEC]. Seeds → TR.
@SectionId('PD00-TEC')
@Comment('Seeds → TR')
class TechnicalFrameworkConcept {
  @Unused()
  String? content;

  /// 8.1. Basic Technical Requirements [PD00-TEC-BAS].
  BasicTechnicalRequirements basicRequirements = BasicTechnicalRequirements();

  /// 8.2. Software Design Requirements [PD00-TEC-SOF].
  SoftwareDesignRequirements softwareDesign = SoftwareDesignRequirements();

  /// 8.3. Standard Application Software Requirements [PD00-TEC-STA].
  StandardSoftwareRequirements standardSoftware = StandardSoftwareRequirements();

  /// 8.4. Hardware Concept Requirements [PD00-TEC-HAR].
  HardwareRequirements hardware = HardwareRequirements();

  /// 8.5. Operations Requirements [PD00-TEC-OPE].
  OperationsRequirements operations = OperationsRequirements();

  /// 8.6. Communication Requirements [PD00-TEC-COM].
  CommunicationRequirements communication = CommunicationRequirements();

  /// 8.7. System Operation and Monitoring [PD00-TEC-SYS].
  SystemOperationAndMonitoring systemOperation = SystemOperationAndMonitoring();

  /// 8.8. Security Requirements [PD00-TEC-SEC].
  TechnicalSecurityRequirements security = TechnicalSecurityRequirements();
}

/// 8.1. Basic Technical Requirements [PD00-TEC-BAS].
@SectionId('PD00-TEC-BAS')
class BasicTechnicalRequirements {
  @Unused()
  String? content;

  /// 8.1.1. Platform and Language [PD00-TEC-BAS-PLA].
  PlatformAndLanguage platformAndLanguage = PlatformAndLanguage();

  /// Architecture Style.
  TextSection architectureStyle = TextSection();

  /// 8.1.3. Design Patterns and Standards [PD00-TEC-BAS-PAT] — contains 0+× DesignPattern.
  @SectionIdPattern('PD00-TEC-BAS-PAT-xx')
  List<DesignPatternEntry> designPatternsAndStandards = [];
}

// =============================================================================
// 8.1.1. Platform and Language [PD00-TEC-BAS-PLA]
// =============================================================================

/// 8.1.1. Platform and Language [PD00-TEC-BAS-PLA].
///
/// Required platforms (operating system, runtime), programming languages,
/// and framework choices with minimum versions and justification.
@SectionId('PD00-TEC-BAS-PLA')
class PlatformAndLanguage {
  @Unused()
  String? content;

  /// General platform and technology overview.
  TextSection overview = TextSection();

  /// Target platforms (operating systems, runtimes, containers).
  @SectionIdPattern('PD00-TEC-BAS-PLA-PLT-xx')
  List<TargetPlatformEntry> targetPlatforms = [];

  /// Programming language requirements.
  @SectionIdPattern('PD00-TEC-BAS-PLA-LNG-xx')
  List<ProgrammingLanguageEntry> programmingLanguages = [];

  /// Framework and library requirements.
  @SectionIdPattern('PD00-TEC-BAS-PLA-FRM-xx')
  List<FrameworkRequirementEntry> frameworks = [];

  /// Build toolchain requirements.
  @SectionIdPattern('PD00-TEC-BAS-PLA-BLD-xx')
  List<BuildToolchainEntry> buildToolchain = [];

  /// Deployment target specifications.
  @SectionIdPattern('PD00-TEC-BAS-PLA-DEP-xx')
  List<DeploymentTargetEntry> deploymentTargets = [];

  /// Dependency management requirements.
  DependencyManagement dependencyManagement = DependencyManagement();

  /// Runtime environment constraints.
  RuntimeEnvironment runtimeEnvironment = RuntimeEnvironment();
}

/// Target platform entry (operating system, runtime, container).
class TargetPlatformEntry {
  @Form([
    // Identity
    Field('platformName', String, 'Platform Name',
        required: true,
        hint: 'E.g., Linux, Windows Server, macOS, iOS, Android'),
    Field('platformCategory', String, 'Category',
        hint:
            'Operating System, Runtime Environment, Container Platform, Cloud Platform'),
    Field(
        'platformType', String, 'Type', hint: 'Server, Desktop, Mobile, IoT'),

    // Version requirements
    Field('minimumVersion', String, 'Minimum Version',
        required: true, hint: 'Earliest supported version'),
    Field('recommendedVersion', String, 'Recommended Version',
        hint: 'Preferred target version'),
    Field('maximumVersion', String, 'Maximum Version',
        hint: 'Latest tested/supported version'),

    // Architecture
    Field('supportedArchitectures', String, 'Supported Architectures',
        hint: 'E.g., x86_64, ARM64, WASM'),
    Field('bitness', String, 'Bitness', hint: '32-bit, 64-bit, Both'),

    // Requirements and constraints
    Field('minimumMemory', String, 'Minimum Memory',
        hint: 'Minimum RAM requirement'),
    Field('minimumStorage', String, 'Minimum Storage',
        hint: 'Minimum disk space'),
    Field('requiredFeatures', String, 'Required Features',
        hint: 'Specific OS features or capabilities needed'),

    // Justification
    Field('justification', String, 'Justification',
        hint: 'Reason for selecting this platform'),
    Field('supportScope', String, 'Support Scope',
        hint: 'Primary, Secondary, Limited'),
    Field('endOfLifeDate', String, 'End of Life Date',
        hint: 'Platform EOL date for planning'),

    // Compliance
    Field('certificationRequirements', String, 'Certification Requirements',
        hint: 'Required platform certifications'),
    Field('notes', String, 'Notes',
        hint: 'Additional platform-specific notes'),
  ])
  String? content;
}

/// Programming language requirement entry.
class ProgrammingLanguageEntry {
  @Form([
    // Identity
    Field('languageName', String, 'Language Name',
        required: true, hint: 'E.g., Dart, TypeScript, Python, Rust'),
    Field('languageVariant', String, 'Variant',
        hint: 'E.g., Sound null safety, Strict mode'),

    // Version requirements
    Field('minimumVersion', String, 'Minimum Version',
        required: true, hint: 'Earliest supported language version'),
    Field('recommendedVersion', String, 'Recommended Version',
        hint: 'Preferred target version'),
    Field('maximumVersion', String, 'Maximum Version',
        hint: 'Latest tested/supported version'),

    // SDK and tooling
    Field('sdkName', String, 'SDK Name', hint: 'E.g., Dart SDK, Node.js'),
    Field('sdkMinVersion', String, 'SDK Min Version',
        hint: 'Minimum SDK version'),
    Field('sdkRecommendedVersion', String, 'SDK Recommended Version',
        hint: 'Recommended SDK version'),

    // Usage context
    Field('usageContext', String, 'Usage Context',
        hint:
            'Backend, Frontend, Full-stack, Scripting, Build tools, Testing'),
    Field('codebasePercentage', String, 'Codebase %',
        hint: 'Approximate percentage of codebase'),
    Field('isPrimaryLanguage', bool, 'Primary Language',
        hint: 'Is this the main implementation language?'),

    // Features
    Field('requiredFeatures', String, 'Required Language Features',
        hint: 'Specific language features needed'),
    Field('enabledLanguageOptions', String, 'Enabled Options',
        hint: 'Compiler/interpreter options to enable'),
    Field('disabledLanguageOptions', String, 'Disabled Options',
        hint: 'Compiler/interpreter options to disable'),

    // Quality
    Field('lintingRules', String, 'Linting Rules',
        hint: 'Required linting configuration'),
    Field('staticAnalysis', String, 'Static Analysis',
        hint: 'Static analysis requirements'),
    Field('codeStyle', String, 'Code Style',
        hint: 'Code style/formatting standard'),

    // Justification
    Field('justification', String, 'Justification',
        required: true, hint: 'Reason for selecting this language'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint: 'Other languages evaluated'),
    Field('migrationPath', String, 'Migration Path',
        hint: 'Upgrade/migration strategy'),
    Field('notes', String, 'Notes', hint: 'Additional language notes'),
  ])
  String? content;
}

/// Framework or library requirement entry.
class FrameworkRequirementEntry {
  @Form([
    // Identity
    Field('frameworkName', String, 'Framework/Library Name',
        required: true, hint: 'E.g., Flutter, Angular, Django, Spring Boot'),
    Field('frameworkCategory', String, 'Category',
        hint:
            'UI Framework, Backend Framework, Testing, State Management, ORM'),
    Field('publisher', String, 'Publisher', hint: 'Framework publisher/owner'),
    Field('license', String, 'License', hint: 'License type (MIT, Apache, etc.)'),

    // Version requirements
    Field('minimumVersion', String, 'Minimum Version',
        required: true, hint: 'Earliest supported version'),
    Field('recommendedVersion', String, 'Recommended Version',
        hint: 'Preferred target version'),
    Field('maximumVersion', String, 'Maximum Version',
        hint: 'Latest tested/supported version'),
    Field('versionConstraint', String, 'Version Constraint',
        hint: 'E.g., ^3.0.0, >=2.0.0 <4.0.0'),

    // Scope and purpose
    Field('purpose', String, 'Purpose',
        required: true, hint: 'What problem this framework solves'),
    Field('usageScope', String, 'Usage Scope',
        hint: 'Core, Feature-specific, Development-only, Testing-only'),
    Field('integrationPoints', String, 'Integration Points',
        hint: 'Where this framework integrates in the architecture'),

    // Requirements
    Field('requiredPlugins', String, 'Required Plugins/Extensions',
        hint: 'Mandatory plugins or extensions'),
    Field('optionalPlugins', String, 'Optional Plugins/Extensions',
        hint: 'Recommended optional plugins'),
    Field('excludedFeatures', String, 'Excluded Features',
        hint: 'Framework features that should not be used'),

    // Compatibility
    Field('compatibleWith', String, 'Compatible With',
        hint: 'Other frameworks/versions this is compatible with'),
    Field('conflictsWith', String, 'Conflicts With',
        hint: 'Known conflicts with other frameworks'),
    Field('deprecationWarnings', String, 'Deprecation Warnings',
        hint: 'Known deprecations to address'),

    // Support
    Field('supportStatus', String, 'Support Status',
        hint: 'Active, Maintenance, Deprecated'),
    Field('communitySize', String, 'Community Size',
        hint: 'Small, Medium, Large'),
    Field('documentationQuality', String, 'Documentation Quality',
        hint: 'Excellent, Good, Fair, Poor'),

    // Justification
    Field('justification', String, 'Justification',
        required: true, hint: 'Reason for selecting this framework'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint: 'Other frameworks evaluated'),
    Field('riskAssessment', String, 'Risk Assessment',
        hint: 'Vendor lock-in, maintenance, complexity risks'),
    Field('notes', String, 'Notes', hint: 'Additional framework notes'),
  ])
  String? content;
}

/// Build toolchain requirement entry.
class BuildToolchainEntry {
  @Form([
    // Identity
    Field('toolName', String, 'Tool Name',
        required: true, hint: 'E.g., Gradle, CMake, Webpack, Dart build_runner'),
    Field('toolCategory', String, 'Category',
        hint:
            'Build System, Compiler, Bundler, Code Generator, Task Runner, Package Manager'),
    Field('platform', String, 'Platform',
        hint: 'Which platform(s) this tool is used for'),

    // Version requirements
    Field('minimumVersion', String, 'Minimum Version',
        required: true, hint: 'Earliest supported version'),
    Field('recommendedVersion', String, 'Recommended Version',
        hint: 'Preferred target version'),

    // Configuration
    Field('configurationFile', String, 'Configuration File',
        hint: 'Primary configuration file name'),
    Field('requiredPlugins', String, 'Required Plugins',
        hint: 'Mandatory build plugins'),
    Field('optionalPlugins', String, 'Optional Plugins',
        hint: 'Recommended optional plugins'),

    // Build profiles
    Field('buildProfiles', String, 'Build Profiles',
        hint: 'E.g., Debug, Release, Profile, Production'),
    Field('defaultProfile', String, 'Default Profile',
        hint: 'Default build profile'),

    // Integration
    Field('cicdIntegration', String, 'CI/CD Integration',
        hint: 'Integration with CI/CD pipelines'),
    Field('ideIntegration', String, 'IDE Integration',
        hint: 'Integration with development IDEs'),

    // Outputs
    Field('outputArtifacts', String, 'Output Artifacts',
        hint: 'Types of artifacts produced'),
    Field('outputLocations', String, 'Output Locations',
        hint: 'Where build artifacts are stored'),

    // Performance
    Field('cachingStrategy', String, 'Caching Strategy',
        hint: 'Build caching approach'),
    Field('parallelization', String, 'Parallelization',
        hint: 'Parallel build capabilities'),

    // Justification
    Field('justification', String, 'Justification',
        hint: 'Reason for selecting this tool'),
    Field('notes', String, 'Notes', hint: 'Additional toolchain notes'),
  ])
  String? content;
}

/// Deployment target specification entry.
class DeploymentTargetEntry {
  @Form([
    // Identity
    Field('targetName', String, 'Target Name',
        required: true, hint: 'E.g., Production Web, iOS App Store, Docker Hub'),
    Field('targetCategory', String, 'Category',
        hint: 'Web, Mobile App, Desktop App, Cloud Service, Container, Embedded'),
    Field('targetEnvironment', String, 'Environment',
        hint: 'Development, Staging, Production'),

    // Platform specifics
    Field('platformTarget', String, 'Platform Target',
        hint: 'Specific platform/OS this deployment targets'),
    Field('distributionChannel', String, 'Distribution Channel',
        hint: 'App Store, Play Store, Web hosting, Container registry'),

    // Build output
    Field('artifactFormat', String, 'Artifact Format',
        hint: 'E.g., APK, AAB, IPA, EXE, Docker image, WASM'),
    Field('artifactNaming', String, 'Artifact Naming',
        hint: 'Naming convention for artifacts'),
    Field('signingRequirements', String, 'Signing Requirements',
        hint: 'Code signing requirements'),

    // Requirements
    Field('minimumOsVersion', String, 'Minimum OS Version',
        hint: 'Minimum target OS version'),
    Field('targetSdkVersion', String, 'Target SDK Version',
        hint: 'Target SDK/API level'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Platform permissions needed'),
    Field('requiredCapabilities', String, 'Required Capabilities',
        hint: 'Platform capabilities needed'),

    // Size and performance
    Field('sizeLimit', String, 'Size Limit',
        hint: 'Maximum artifact size'),
    Field('performanceTargets', String, 'Performance Targets',
        hint: 'Startup time, memory footprint targets'),

    // Deployment process
    Field('deploymentMethod', String, 'Deployment Method',
        hint: 'Manual, CI/CD, Blue-green, Rolling'),
    Field('rollbackStrategy', String, 'Rollback Strategy',
        hint: 'How to rollback failed deployments'),
    Field('featureFlagsSupport', String, 'Feature Flags Support',
        hint: 'Feature flag implementation'),

    // Compliance
    Field('complianceRequirements', String, 'Compliance Requirements',
        hint: 'Store guidelines, regulatory requirements'),
    Field('privacyRequirements', String, 'Privacy Requirements',
        hint: 'Privacy manifest, tracking transparency'),

    // Notes
    Field('priority', String, 'Priority',
        hint: 'Primary, Secondary, Future'),
    Field('targetLaunchDate', String, 'Target Launch Date',
        hint: 'Target date for this deployment'),
    Field('notes', String, 'Notes', hint: 'Additional deployment notes'),
  ])
  String? content;
}

/// Dependency management configuration.
class DependencyManagement {
  @Form([
    // Package manager
    Field('primaryPackageManager', String, 'Primary Package Manager',
        hint: 'E.g., pub.dev, npm, pip, Maven'),
    Field('secondaryPackageManagers', String, 'Secondary Package Managers',
        hint: 'Additional package managers used'),
    Field('registryUrls', String, 'Registry URLs',
        hint: 'Package registry URLs (public and private)'),

    // Version policy
    Field('versioningPolicy', String, 'Versioning Policy',
        hint: 'SemVer, CalVer, custom'),
    Field('dependencyUpdatePolicy', String, 'Update Policy',
        hint: 'How and when to update dependencies'),
    Field('lockfilePolicy', String, 'Lockfile Policy',
        hint: 'Required, Recommended, Optional'),

    // Security
    Field('securityScanning', String, 'Security Scanning',
        hint: 'Dependency vulnerability scanning requirements'),
    Field('licenseCompliance', String, 'License Compliance',
        hint: 'Allowed and prohibited licenses'),
    Field('sourceTrust', String, 'Source Trust',
        hint: 'Trusted sources and verification'),

    // Internal dependencies
    Field('internalPackages', String, 'Internal Packages',
        hint: 'Internal/private packages to use'),
    Field('monorepoStrategy', String, 'Monorepo Strategy',
        hint: 'Workspace/monorepo dependency management'),

    // Caching
    Field('cachingStrategy', String, 'Caching Strategy',
        hint: 'Dependency caching approach'),
    Field('offlineSupport', String, 'Offline Support',
        hint: 'Offline build requirements'),

    // Notes
    Field('notes', String, 'Notes',
        hint: 'Additional dependency management notes'),
  ])
  String? content;
}

/// Runtime environment constraints.
class RuntimeEnvironment {
  @Form([
    // Memory
    Field('minimumMemory', String, 'Minimum Memory',
        hint: 'Minimum RAM for runtime'),
    Field('recommendedMemory', String, 'Recommended Memory',
        hint: 'Recommended RAM for optimal performance'),
    Field('memoryLimits', String, 'Memory Limits',
        hint: 'Hard memory limits or caps'),

    // CPU
    Field('minimumCpuCores', String, 'Minimum CPU Cores',
        hint: 'Minimum CPU cores required'),
    Field('cpuArchitecture', String, 'CPU Architecture',
        hint: 'Required CPU architecture'),
    Field('gpuRequirements', String, 'GPU Requirements',
        hint: 'GPU/graphics requirements if any'),

    // Storage
    Field('minimumDiskSpace', String, 'Minimum Disk Space',
        hint: 'Minimum disk space for installation'),
    Field('temporarySpace', String, 'Temporary Space',
        hint: 'Temporary storage requirements'),
    Field('storageType', String, 'Storage Type',
        hint: 'SSD required, HDD acceptable'),

    // Network
    Field('networkRequirements', String, 'Network Requirements',
        hint: 'Connectivity requirements'),
    Field('bandwidthRequirements', String, 'Bandwidth Requirements',
        hint: 'Minimum bandwidth'),
    Field('latencyRequirements', String, 'Latency Requirements',
        hint: 'Maximum acceptable latency'),

    // Environment variables
    Field('requiredEnvVariables', String, 'Required Environment Variables',
        hint: 'Mandatory environment variables'),
    Field('optionalEnvVariables', String, 'Optional Environment Variables',
        hint: 'Optional configuration variables'),

    // Runtime dependencies
    Field('systemDependencies', String, 'System Dependencies',
        hint: 'Required system libraries or services'),
    Field('externalServices', String, 'External Services',
        hint: 'Required external services (DB, cache, etc.)'),

    // Scaling
    Field('horizontalScaling', String, 'Horizontal Scaling',
        hint: 'Horizontal scaling support'),
    Field('verticalScaling', String, 'Vertical Scaling',
        hint: 'Vertical scaling support'),
    Field('autoScalingRules', String, 'Auto-Scaling Rules',
        hint: 'Auto-scaling triggers and limits'),

    // Notes
    Field('notes', String, 'Notes',
        hint: 'Additional runtime environment notes'),
  ])
  String? content;
}

/// A design pattern or standard entry (form) [PD00-TEC-BAS-PAT-nn].
class DesignPatternEntry {
  @Form([
    Field('patternName', String, 'Pattern Name', required: true),
    Field('purpose', String, 'Purpose'),
  ])
  String? content;
}

/// 8.2. Software Design Requirements [PD00-TEC-SOF].
@SectionId('PD00-TEC-SOF')
class SoftwareDesignRequirements {
  @Unused()
  String? content;

  /// Layering And Module Structure.
  TextSection layeringAndModuleStructure = TextSection();

  /// Development Environment.
  TextSection developmentEnvironment = TextSection();

  /// 8.2.3. Reusable Components [PD00-TEC-SOF-REU] — contains 0+× ReusableComponent.
  @SectionIdPattern('PD00-TEC-SOF-REU-xx')
  List<ReusableComponentEntry> reusableComponents = [];
}

/// A reusable component entry (form) [PD00-TEC-SOF-REU-nn].
class ReusableComponentEntry {
  @Form([
    Field('componentName', String, 'Component Name', required: true),
    Field('source', String, 'Source'),
    Field('purpose', String, 'Purpose'),
  ])
  String? content;
}

/// 8.3. Standard Application Software Requirements [PD00-TEC-STA].
@SectionId('PD00-TEC-STA')
class StandardSoftwareRequirements {
  @Unused()
  String? content;

  /// 8.3.1. Compatibility Requirements [PD00-TEC-STA-COM] — contains 0+× CompatibilityRequirement.
  @SectionIdPattern('PD00-TEC-STA-COM-xx')
  List<CompatibilityRequirementEntry> compatibilityRequirements = [];

  /// Standards Compliance.
  TextSection standardsCompliance = TextSection();
}

/// A compatibility requirement entry (form) [PD00-TEC-STA-COM-nn].
class CompatibilityRequirementEntry {
  @Form([
    Field('requirement', String, 'Requirement'),
    Field('system', String, 'System'),
  ])
  String? content;
}

/// 8.4. Hardware Concept Requirements [PD00-TEC-HAR].
@SectionId('PD00-TEC-HAR')
class HardwareRequirements {
  @Unused()
  String? content;

  /// Server Requirements.
  TextSection serverRequirements = TextSection();

  /// Client Requirements.
  TextSection clientRequirements = TextSection();

  /// Network Requirements.
  TextSection networkRequirements = TextSection();
}

/// 8.5. Operations Requirements [PD00-TEC-OPE].
@SectionId('PD00-TEC-OPE')
class OperationsRequirements {
  @Unused()
  String? content;

  /// Backup And Recovery.
  TextSection backupAndRecovery = TextSection();

  /// Deployment Strategy.
  TextSection deploymentStrategy = TextSection();

  /// Monitoring And Alerting.
  TextSection monitoringAndAlerting = TextSection();

  /// Maintenance Windows.
  TextSection maintenanceWindows = TextSection();
}

/// 8.6. Communication Requirements [PD00-TEC-COM].
@SectionId('PD00-TEC-COM')
class CommunicationRequirements {
  @Unused()
  String? content;

  /// 8.6.1. Protocols and Standards [PD00-TEC-COM-PRO] — contains 0+× Protocol.
  @SectionIdPattern('PD00-TEC-COM-PRO-xx')
  List<ProtocolEntry> protocolsAndStandards = [];

  /// External Connectivity.
  TextSection externalConnectivity = TextSection();
}

/// A protocol or standard entry (form) [PD00-TEC-COM-PRO-nn].
class ProtocolEntry {
  @Form([
    Field('protocolName', String, 'Protocol Name', required: true),
    Field('purpose', String, 'Purpose'),
  ])
  String? content;
}

/// 8.7. System Operation and Monitoring [PD00-TEC-SYS].
@SectionId('PD00-TEC-SYS')
class SystemOperationAndMonitoring {
  @Unused()
  String? content;

  /// 8.7.1. System Operation [PD00-TEC-SYS-OPE].
  SystemOperation systemOperation = SystemOperation();

  /// 8.7.2. Monitoring [PD00-TEC-SYS-MON].
  Monitoring monitoring = Monitoring();
}

/// 8.7.1. System Operation [PD00-TEC-SYS-OPE].
@SectionId('PD00-TEC-SYS-OPE')
class SystemOperation {
  @Unused()
  String? content;

  /// Administration Requirements.
  TextSection administrationRequirements = TextSection();

  /// Maintenance Procedures.
  TextSection maintenanceProcedures = TextSection();
}

/// 8.7.2. Monitoring [PD00-TEC-SYS-MON].
@SectionId('PD00-TEC-SYS-MON')
class Monitoring {
  @Unused()
  String? content;

  /// Health Checks And Diagnostics.
  TextSection healthChecksAndDiagnostics = TextSection();

  /// Capacity Planning.
  TextSection capacityPlanning = TextSection();

  /// Alerting.
  TextSection alerting = TextSection();
}

/// 8.8. Security Requirements [PD00-TEC-SEC].
@SectionId('PD00-TEC-SEC')
class TechnicalSecurityRequirements {
  @Unused()
  String? content;

  /// 8.8.1. IT Security Standards [PD00-TEC-SEC-ITS] — contains 0+× SecurityStandard.
  @SectionIdPattern('PD00-TEC-SEC-ITS-xx')
  List<SecurityStandardEntry> itSecurityStandards = [];

  /// Data Protection And Privacy.
  TextSection dataProtectionAndPrivacy = TextSection();

  /// 8.8.3. Security Audit Requirements [PD00-TEC-SEC-AUD] — contains 0+× SecurityAudit.
  @SectionIdPattern('PD00-TEC-SEC-AUD-xx')
  List<SecurityAuditEntry> securityAuditRequirements = [];
}

/// A security standard entry (form) [PD00-TEC-SEC-ITS-nn].
class SecurityStandardEntry {
  @Form([
    Field('standardName', String, 'Standard Name', required: true),
    Field('version', String, 'Version'),
    Field('scope', String, 'Scope'),
  ])
  String? content;
}

/// A security audit requirement entry (form) [PD00-TEC-SEC-AUD-nn].
class SecurityAuditEntry {
  @Form([
    Field('requirement', String, 'Requirement'),
    Field('frequency', String, 'Frequency'),
  ])
  String? content;
}
